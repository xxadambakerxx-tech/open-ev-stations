class StationPage < Jekyll::PageWithoutAFile
  def initialize(site, station)
    slug = station.fetch("slug")
    super(site, site.source, "chargers/#{slug}", "index.html")
    latitude = station["latitude"]
    longitude = station["longitude"]
    if !latitude.nil? && !longitude.nil?
      unless latitude.is_a?(Numeric) && latitude.between?(-90, 90)
        raise ArgumentError, "Station #{station.fetch('id')} has an invalid latitude"
      end
      unless longitude.is_a?(Numeric) && longitude.between?(-180, 180)
        raise ArgumentError, "Station #{station.fetch('id')} has an invalid longitude"
      end
    end

    self.data = station.merge(
      "layout" => "station",
      "title" => station.fetch("station_name"),
      "description" => "Charging details for #{station.fetch('station_name')}.",
      "permalink" => "/chargers/#{slug}/"
    )
  end
end

class StationCategoryPage < Jekyll::PageWithoutAFile
  def initialize(site, category)
    slug = category.fetch("id")
    super(site, site.source, "categories/#{slug}", "index.html")
    self.data = {
      "layout" => "category",
      "title" => category.fetch("name"),
      "description" => "#{category.fetch('count')} EV charging locations in #{category.fetch('name')}.",
      "permalink" => "/categories/#{slug}/",
      "category" => category
    }
  end
end

class StateCategoryPage < Jekyll::PageWithoutAFile
  def initialize(site, category, state)
    category_slug = category.fetch("id")
    state_slug = state.fetch("slug")
    super(site, site.source, "categories/#{category_slug}/#{state_slug}", "index.html")
    self.data = {
      "layout" => "state_category",
      "title" => "#{category.fetch('name')} in #{state.fetch('name')}",
      "description" => "#{state.fetch('count')} #{category.fetch('name')} charging locations in #{state.fetch('name')}.",
      "permalink" => "/categories/#{category_slug}/#{state_slug}/",
      "category" => category,
      "state" => state,
      "stations" => state.fetch("stations")
    }
  end
end

class StationPagesGenerator < Jekyll::Generator
  CATEGORIES = [
    { "id" => "lodging", "name" => "Hotels, inns & B&Bs", "types" => %w[HOTEL INN B_AND_B] },
    { "id" => "restaurants", "name" => "Restaurants", "types" => %w[RESTAURANT] },
    { "id" => "parks", "name" => "Parks & recreation", "types" => %w[PARK NATL_PARK] },
    { "id" => "rv-parks", "name" => "RV parks & campgrounds", "types" => %w[RV_PARK CAMPGROUND] },
    { "id" => "shopping-centers", "name" => "Shopping centers", "types" => %w[SHOPPING_CENTER] },
    { "id" => "multi-unit-dwellings", "name" => "Multi-unit dwellings", "types" => %w[MULTI_UNIT_DWELLING MULTI_FAMILY] }
  ].freeze

  STATE_NAMES = {
    "AK" => "Alaska", "AL" => "Alabama", "AR" => "Arkansas", "AZ" => "Arizona",
    "CA" => "California", "CO" => "Colorado", "CT" => "Connecticut", "DC" => "District of Columbia",
    "DE" => "Delaware", "FL" => "Florida", "GA" => "Georgia", "HI" => "Hawaii",
    "IA" => "Iowa", "ID" => "Idaho", "IL" => "Illinois", "IN" => "Indiana",
    "KS" => "Kansas", "KY" => "Kentucky", "LA" => "Louisiana", "MA" => "Massachusetts",
    "MD" => "Maryland", "ME" => "Maine", "MI" => "Michigan", "MN" => "Minnesota",
    "MO" => "Missouri", "MS" => "Mississippi", "MT" => "Montana", "NC" => "North Carolina",
    "ND" => "North Dakota", "NE" => "Nebraska", "NH" => "New Hampshire", "NJ" => "New Jersey",
    "NM" => "New Mexico", "NV" => "Nevada", "NY" => "New York", "OH" => "Ohio",
    "OK" => "Oklahoma", "OR" => "Oregon", "PA" => "Pennsylvania", "PR" => "Puerto Rico",
    "RI" => "Rhode Island", "SC" => "South Carolina", "SD" => "South Dakota", "TN" => "Tennessee",
    "TX" => "Texas", "UT" => "Utah", "VA" => "Virginia", "VT" => "Vermont",
    "WA" => "Washington", "WI" => "Wisconsin", "WV" => "West Virginia", "WY" => "Wyoming"
  }.freeze

  safe true
  priority :normal

  def generate(site)
    stations = site.data["destination_chargers"]
    return if stations.nil?

    raise ArgumentError, "_data/destination_chargers.json must contain an array" unless stations.is_a?(Array)

    categorized_ids = {}
    categories = CATEGORIES.filter_map do |category|
      category_stations = stations.select do |station|
        category["types"].include?(station["facility_type"])
      end
      next if category_stations.empty?

      category_stations.each do |station|
        if categorized_ids.key?(station["id"])
          raise ArgumentError, "Station #{station['id']} belongs to multiple directory categories"
        end
        categorized_ids[station["id"]] = true
      end

      state_groups = category_stations.group_by do |station|
        state_code = station["state"].to_s.strip.upcase
        unless state_code.match?(/\A[A-Z]{2}\z/)
          raise ArgumentError, "Station #{station['id']} must have a two-letter state or territory code"
        end

        state_code
      end
      states = state_groups.map do |state_code, state_stations|
        state = {
          "code" => state_code,
          "name" => STATE_NAMES.fetch(state_code, state_code),
          "slug" => state_code.downcase,
          "count" => state_stations.length,
          "stations" => state_stations
        }
        site.pages << StateCategoryPage.new(site, category, state)
        state.reject { |key, _value| key == "stations" }
      end.sort_by { |state| state.fetch("name") }

      generated_category = category.merge(
        "count" => category_stations.length,
        "states" => states
      )
      site.pages << StationCategoryPage.new(site, generated_category)
      generated_category
    end
    uncategorized = stations.reject { |station| categorized_ids.key?(station["id"]) }
    unless uncategorized.empty?
      types = uncategorized.map { |station| station["facility_type"] }.uniq.sort.join(", ")
      raise ArgumentError, "Stations have facility types that are not assigned to a homepage category: #{types}"
    end
    site.data["station_categories"] = categories

    slugs = {}
    stations.each do |station|
      raise ArgumentError, "Each station record must be an object" unless station.is_a?(Hash)

      slug = station["slug"].to_s
      name = station["station_name"].to_s
      raise ArgumentError, "Each station needs a slug and station_name" if slug.empty? || name.empty?
      raise ArgumentError, "Invalid station page slug: #{slug}" unless slug.match?(/\A[a-zA-Z0-9_-]+\z/)
      raise ArgumentError, "Duplicate station page slug: #{slug}" if slugs.key?(slug)

      slugs[slug] = true
      site.pages << StationPage.new(site, station)
    end
  end
end
