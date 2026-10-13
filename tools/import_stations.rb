require "csv"
require "fileutils"
require "json"

module ImportStations
  OUTPUT_PATH = File.expand_path("../_data/destination_chargers.json", __dir__)
  EARTH_RADIUS_MILES = 3958.7613

  HEADER_ALIASES = {
    "id" => "id",
    "station_id" => "id",
    "station_name" => "station_name",
    "street_address" => "street_address",
    "city" => "city",
    "state" => "state",
    "zip" => "zip",
    "facility_type" => "facility_type",
    "access_days_time" => "access_days_time",
    "ev_pricing" => "ev_pricing",
    "ev_level1_evse_num" => "ev_level1_num",
    "ev_level1_num" => "ev_level1_num",
    "ev_level2_evse_num" => "ev_level2_num",
    "ev_level2_num" => "ev_level2_num",
    "ev_dc_fast_count" => "ev_dc_fast_num",
    "ev_dc_fast_num" => "ev_dc_fast_num",
    "ev_connector_types" => "ev_connector_types",
    "latitude" => "latitude",
    "longitude" => "longitude"
  }.freeze

  DESTINATION_FACILITY_TYPES = %w[
    HOTEL INN B_AND_B RESTAURANT PARK NATL_PARK RV_PARK CAMPGROUND
    SHOPPING_CENTER MULTI_FAMILY MULTI_UNIT_DWELLING
  ].freeze

  TEXT_FIELDS = %w[
    street_address city state zip facility_type access_days_time ev_pricing
  ].freeze

  def self.normalize_header(header)
    header.to_s.downcase.strip.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
  end

  def self.normalize_id(value, row_number)
    id = value.to_s.strip
    raise ArgumentError, "Row #{row_number}: station id is required" if id.empty?

    id
  end

  def self.normalize_count(value, field, row_number)
    return 0 if value.nil? || value.strip.empty?

    number = Float(value)
    unless number.finite? && number >= 0 && number == number.to_i
      raise ArgumentError, "Row #{row_number}: #{field} must be a non-negative whole number"
    end

    number.to_i
  rescue ArgumentError, TypeError
    raise ArgumentError, "Row #{row_number}: #{field} must be a non-negative whole number"
  end

  def self.normalize_coordinate(value, field, row_number)
    return nil if value.nil? || value.strip.empty?

    number = Float(value)
    range = field == "latitude" ? (-90..90) : (-180..180)
    raise ArgumentError, "Row #{row_number}: #{field} is outside its valid range" unless number.finite? && range.cover?(number)

    number
  rescue ArgumentError, TypeError
    raise ArgumentError, "Row #{row_number}: #{field} must be a valid coordinate"
  end

  def self.distance_miles(first, second)
    latitude_1 = first["latitude"] * Math::PI / 180
    latitude_2 = second["latitude"] * Math::PI / 180
    latitude_delta = latitude_2 - latitude_1
    longitude_delta = (second["longitude"] - first["longitude"]) * Math::PI / 180
    haversine = Math.sin(latitude_delta / 2)**2 +
                Math.cos(latitude_1) * Math.cos(latitude_2) * Math.sin(longitude_delta / 2)**2

    EARTH_RADIUS_MILES * 2 * Math.asin([1, Math.sqrt(haversine)].min)
  end

  def self.add_state_distance_averages(stations)
    stations.group_by { |station| station["state"].to_s.strip.upcase }.each do |state, state_stations|
      raise ArgumentError, "Station state is required to calculate state distance averages" if state.empty?

      geocoded_stations = state_stations.select do |station|
        !station["latitude"].nil? && !station["longitude"].nil?
      end
      average_nearest_distance = if geocoded_stations.length < 2
                                   nil
                                 else
                                   nearest_distances = geocoded_stations.each_with_index.map do |station, index|
                                     nearest_distance = nil
                                     geocoded_stations.each_with_index do |other, other_index|
                                       next if index == other_index

                                       distance = distance_miles(station, other)
                                       nearest_distance = distance if nearest_distance.nil? || distance < nearest_distance
                                     end
                                     nearest_distance
                                   end
                                   (nearest_distances.sum / nearest_distances.length).round(2)
                                 end

      state_stations.each do |station|
        station["state_average_nearest_distance_miles"] = average_nearest_distance
        station["state_geocoded_station_count"] = geocoded_stations.length
      end
    end
  end

  def self.column_map(headers)
    columns = headers.each_with_object({}) do |header, result|
      field = HEADER_ALIASES[normalize_header(header)]
      next unless field
      raise ArgumentError, "Row 1: more than one column maps to #{field}" if result.key?(field)

      result[field] = header
    end

    %w[id station_name facility_type].each do |field|
      raise ArgumentError, "Row 1: required column '#{field}' is missing" unless columns.key?(field)
    end

    columns
  end

  def self.station_from_row(row, columns, row_number)
    values = columns.to_h { |field, header| [field, row[header]] }
    facility_type = values["facility_type"].to_s.strip.upcase
    return unless DESTINATION_FACILITY_TYPES.include?(facility_type)

    id = normalize_id(values["id"], row_number)
    station_name = values["station_name"].to_s.strip
    raise ArgumentError, "Row #{row_number}: station name is required" if station_name.empty?

    station = {
      "id" => id,
      "station_name" => station_name,
      "facility_type" => facility_type
    }
    TEXT_FIELDS.reject { |field| field == "facility_type" }.each do |field|
      value = values[field]
      station[field] = value.nil? || value.strip.empty? ? nil : value.strip
    end

    station["ev_level1_num"] = normalize_count(values["ev_level1_num"], "ev_level1_num", row_number)
    station["ev_level2_num"] = normalize_count(values["ev_level2_num"], "ev_level2_num", row_number)
    station["ev_dc_fast_num"] = normalize_count(values["ev_dc_fast_num"], "ev_dc_fast_num", row_number)
    station["ev_connector_types"] = values["ev_connector_types"].to_s.split(/[,\s;|]+/).reject(&:empty?).uniq
    station["latitude"] = normalize_coordinate(values["latitude"], "latitude", row_number)
    station["longitude"] = normalize_coordinate(values["longitude"], "longitude", row_number)
    station["slug"] = id.downcase.gsub(/[^a-z0-9_-]+/, "-").gsub(/\A[-_]+|[-_]+\z/, "")
    raise ArgumentError, "Row #{row_number}: station id cannot be used to create a page URL" if station["slug"].empty?

    station
  end

  def self.import(source_path, output_path: OUTPUT_PATH)
    raise ArgumentError, "CSV file not found: #{source_path}" unless File.file?(source_path)

    stations = []
    seen_slugs = {}

    CSV.open(source_path, headers: true, encoding: "bom|utf-8") do |csv|
      first_row = csv.shift
      raise ArgumentError, "CSV file must contain a header row" unless first_row

      columns = column_map(first_row.headers)
      add_station = lambda do |row, row_number|
        next if row.fields.all? { |value| value.nil? || value.strip.empty? }

        station = station_from_row(row, columns, row_number)
        next unless station

        if seen_slugs.key?(station["slug"])
          raise ArgumentError, "Rows #{seen_slugs[station['slug']]} and #{row_number} produce the same station URL"
        end

        seen_slugs[station["slug"]] = row_number
        stations << station
      end
      add_station.call(first_row, 2)
      csv.each.with_index(3) { |row, row_number| add_station.call(row, row_number) }
    end

    add_state_distance_averages(stations)

    FileUtils.mkdir_p(File.dirname(output_path))
    temporary_path = "#{output_path}.tmp"
    File.write(temporary_path, "#{JSON.pretty_generate(stations)}\n", encoding: "utf-8")
    File.rename(temporary_path, output_path)
    puts "Imported #{stations.length} destination stations from #{source_path} to #{output_path}"
  ensure
    File.delete(temporary_path) if defined?(temporary_path) && temporary_path && File.exist?(temporary_path)
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.length != 1
    warn "Usage: bundle exec ruby tools/import_stations.rb <stations.csv>"
    exit 2
  end

  begin
    ImportStations.import(File.expand_path(ARGV.fetch(0)))
  rescue StandardError => error
    warn "Station import failed: #{error.message}"
    exit 1
  end
end
