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

class StationPagesGenerator < Jekyll::Generator
  CATEGORIES = [
    { "id" => "lodging", "name" => "Hotels, inns & B&Bs", "types" => %w[HOTEL INN B_AND_B] },
    { "id" => "restaurants", "name" => "Restaurants", "types" => %w[RESTAURANT] },
    { "id" => "parks", "name" => "Parks & recreation", "types" => %w[PARK NATL_PARK] },
    { "id" => "rv-parks", "name" => "RV parks & campgrounds", "types" => %w[RV_PARK CAMPGROUND] },
    { "id" => "shopping-centers", "name" => "Shopping centers", "types" => %w[SHOPPING_CENTER] },
    { "id" => "multi-unit-dwellings", "name" => "Multi-unit dwellings", "types" => %w[MULTI_UNIT_DWELLING MULTI_FAMILY] }
  ].freeze

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

      generated_category = category.merge("count" => category_stations.length, "stations" => category_stations)
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
