class StationPage < Jekyll::PageWithoutAFile
  def initialize(site, station, category, nearby_stations)
    permalink = station.fetch("page_url")
    super(site, site.source, permalink.delete_prefix("/").delete_suffix("/"), "index.html")
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

    location = [station["city"], station["state"]].reject { |value| value.to_s.strip.empty? }.join(", ")
    charger_details = []
    charger_details << "#{station['ev_level2_num']} Level 2" if station.fetch("ev_level2_num", 0).positive?
    charger_details << "#{station['ev_dc_fast_num']} DC fast" if station.fetch("ev_dc_fast_num", 0).positive?
    connector_types = station.fetch("ev_connector_types", [])
    title_details = charger_details.map { |detail| detail.sub(/\A\d+\s+/, "") }
    title_details.concat(connector_types)
    title = "#{station.fetch('station_name')} EV Charging"
    title += " in #{location}" unless location.empty?
    title += " | #{title_details.uniq.join(', ')}" unless title_details.empty?

    description = ["Find EV charging at #{station.fetch('station_name')}#{location.empty? ? '' : " in #{location}"}."]
    description << "Features #{charger_details.join(' and ')} chargers." unless charger_details.empty?
    description << "Connectors: #{connector_types.join(', ')}." unless connector_types.empty?
    description << "Access: #{station['access_days_time']}." unless station["access_days_time"].to_s.strip.empty?

    address = [station["street_address"], station["city"], station["state"], station["zip"]]
              .reject { |value| value.to_s.strip.empty? }
              .join(", ")
    charging_summary = [
      "#{station.fetch('ev_level1_num', 0)} Level 1",
      "#{station.fetch('ev_level2_num', 0)} Level 2",
      "#{station.fetch('ev_dc_fast_num', 0)} DC fast"
    ].join(", ")
    access_details = station["access_days_time"].to_s.strip
    pricing_details = station["ev_pricing"].to_s.strip

    self.data = station.merge(
      "layout" => "station",
      "title" => title,
      "description" => description.join(" "),
      "state_name" => StationPagesGenerator::STATE_NAMES.fetch(station.fetch("state").to_s.upcase, station.fetch("state")),
      "state_slug" => station.fetch("state").downcase,
      "category_id" => category.fetch("id"),
      "category_name" => category.fetch("name"),
      "nearby_stations" => nearby_stations,
      "faqs" => [
        {
          "question" => "Where is #{station.fetch('station_name')} located?",
          "answer" => address.empty? ? "A street address is not currently listed for this station." : "The listed address is #{address}."
        },
        {
          "question" => "What EV charger types are available at #{station.fetch('station_name')}?",
          "answer" => "The directory lists #{charging_summary} charging ports. Connector types listed: #{connector_types.empty? ? 'not specified' : connector_types.join(', ')}."
        },
        {
          "question" => "When can drivers access the chargers at #{station.fetch('station_name')}?",
          "answer" => access_details.empty? ? "Access hours and restrictions are not currently listed. Contact the location before visiting." : "The listed access information is: #{access_details}. Confirm current hours and restrictions with the location before visiting."
        },
        {
          "question" => "How much does EV charging cost at #{station.fetch('station_name')}?",
          "answer" => pricing_details.empty? ? "Pricing is not currently listed. Contact the location or charging network to confirm fees before visiting." : "The directory lists this pricing: #{pricing_details}. Rates and parking fees can change, so confirm the total cost before visiting."
        }
      ],
      "permalink" => permalink
    )
  end
end

class StationCategoryPage < Jekyll::PageWithoutAFile
  def initialize(site, category)
    slug = category.fetch("id")
    super(site, site.source, "category/#{slug}", "index.html")
    self.data = {
      "layout" => "category",
      "title" => category.fetch("name"),
      "description" => "#{category.fetch('count')} EV charging locations in #{category.fetch('name')}.",
      "permalink" => "/category/#{slug}/",
      "category" => category,
      "faqs" => [
        {
          "question" => "What types of places are included in #{category.fetch('name')}?",
          "answer" => "This directory category groups destination charging locations classified as #{category.fetch('name')}. Listings are based on the facility type in the station data."
        },
        {
          "question" => "How many #{category.fetch('name')} charging locations are listed?",
          "answer" => "There are #{category.fetch('count')} locations across #{category.fetch('states').length} states and territories in this category."
        },
        {
          "question" => "How can I find #{category.fetch('name')} chargers in a specific state?",
          "answer" => "Choose a state from the list on this page to see the matching locations and their station details."
        },
        {
          "question" => "Does every listing guarantee public access or free charging?",
          "answer" => "No. Access rules and pricing vary by location. Review each station's details and confirm access and fees with the location or charging network before visiting."
        }
      ]
    }
  end
end

class StationStatePage < Jekyll::PageWithoutAFile
  def initialize(site, state, categories)
    state_slug = state.fetch("slug")
    super(site, site.source, "state/#{state_slug}", "index.html")
    self.data = {
      "layout" => "state",
      "title" => "EV charging categories in #{state.fetch('name')}",
      "description" => "Browse EV charging station categories in #{state.fetch('name')}.",
      "permalink" => "/state/#{state_slug}/",
      "state" => state,
      "categories" => categories,
      "faqs" => [
        {
          "question" => "How many destination charging locations are listed in #{state.fetch('name')}?",
          "answer" => "The directory lists #{state.fetch('count')} destination charging locations in #{state.fetch('name')}."
        },
        {
          "question" => "What types of EV charging locations can I browse in #{state.fetch('name')}?",
          "answer" => "Available categories include #{categories.map { |category| "#{category.fetch('name')} (#{category.fetch('count')})" }.join(', ')}."
        },
        {
          "question" => "How do I find a specific type of charging stop in #{state.fetch('name')}?",
          "answer" => "Select a destination category on this page to see matching station listings, charger details, connector types, and location information."
        },
        {
          "question" => "How far apart are charging stations in #{state.fetch('name')}?",
          "answer" => state.fetch("average_nearest_distance_miles") ? "The average nearest-station distance is #{state.fetch('average_nearest_distance_miles')} miles in a straight line, calculated from #{state.fetch('geocoded_station_count')} locations with coordinates. This is not a driving distance." : "There is not enough location data to calculate an average nearest-station distance for this state."
        },
        {
          "question" => "Are station details and charger availability guaranteed to be current?",
          "answer" => "Station information can change. Confirm current access, connector availability, and fees with the location or charging network before traveling."
        }
      ]
    }
  end
end

class StateCategoryPage < Jekyll::PageWithoutAFile
  def initialize(site, category, state)
    category_slug = category.fetch("id")
    state_slug = state.fetch("slug")
    super(site, site.source, "state/#{state_slug}/category/#{category_slug}", "index.html")
    self.data = {
      "layout" => "state_category",
      "title" => "#{category.fetch('name')} in #{state.fetch('name')}",
      "description" => "#{state.fetch('count')} #{category.fetch('name')} charging locations in #{state.fetch('name')}.",
      "permalink" => "/state/#{state_slug}/category/#{category_slug}/",
      "category" => category,
      "state" => state,
      "stations" => state.fetch("stations"),
      "faqs" => [
        {
          "question" => "How many #{category.fetch('name')} charging locations are listed in #{state.fetch('name')}?",
          "answer" => "There are #{state.fetch('count')} #{category.fetch('name')} charging #{state.fetch('count') == 1 ? 'location' : 'locations'} listed in #{state.fetch('name')}."
        },
        {
          "question" => "What kinds of locations are included in #{category.fetch('name')}?",
          "answer" => "This page lists stations classified in the #{category.fetch('name')} directory category for #{state.fetch('name')}."
        },
        {
          "question" => "What information can I find for each station?",
          "answer" => "Listings may include the station address, charger counts, connector types, access details, pricing, and map availability, depending on the information provided for that location."
        },
        {
          "question" => "How can I check access rules or fees for a station?",
          "answer" => "Open a station listing to review its available access and pricing details. Confirm current restrictions and fees with the location or charging network before visiting."
        }
      ]
    }
  end
end

class BlogArchivePage < Jekyll::PageWithoutAFile
  def initialize(site, page_number, posts, total_pages)
    page_path = page_number == 1 ? "blog" : "blog/page/#{page_number}"
    super(site, site.source, page_path, "index.html")
    self.data = {
      "layout" => "blog_archive",
      "title" => "EV road-trip guides",
      "description" => "Charging explainers and practical electric road-trip guides.",
      "permalink" => page_number == 1 ? "/blog/" : "/#{page_path}/",
      "posts" => posts,
      "current_page" => page_number,
      "total_pages" => total_pages,
      "previous_page_url" => page_number > 1 ? (page_number == 2 ? "/blog/" : "/blog/page/#{page_number - 1}/") : nil,
      "next_page_url" => page_number < total_pages ? "/blog/page/#{page_number + 1}/" : nil
    }
  end
end

class StationPagesGenerator < Jekyll::Generator
  BLOG_PAGE_SIZE = 6

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

  def self.url_slug(value)
    value.to_s.downcase.strip.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
  end

  def self.station_permalink(station, category)
    state_slug = url_slug(station.fetch("state"))
    city_slug = url_slug(station.fetch("city"))
    category_slug = url_slug(category.fetch("id"))
    name_slug = url_slug(station.fetch("station_name"))
    raise ArgumentError, "Station #{station.fetch('id')} is missing a route component" if [state_slug, city_slug, category_slug, name_slug].any?(&:empty?)

    "/state/#{state_slug}/city/#{city_slug}/category/#{category_slug}/#{name_slug}/"
  end

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
    categories_by_type = CATEGORIES.each_with_object({}) do |category, result|
      category.fetch("types").each { |type| result[type] = category }
    end
    station_categories = stations.to_h do |station|
      [station.fetch("id"), categories_by_type.fetch(station.fetch("facility_type"))]
    end
    stations.each do |station|
      station["page_url"] = self.class.station_permalink(station, station_categories.fetch(station.fetch("id")))
    end
    duplicate_urls = stations.group_by { |station| station.fetch("page_url") }
                             .select { |_url, matching_stations| matching_stations.length > 1 }
    duplicate_urls.each_value do |matching_stations|
      matching_stations.each do |station|
        station["page_url"] = station.fetch("page_url").sub(%r{/\z}, "-#{station.fetch('slug').downcase}/")
      end
    end
    unique_urls = stations.map { |station| station.fetch("page_url") }
    unless unique_urls.uniq.length == unique_urls.length
      raise ArgumentError, "Station names and IDs must produce unique station page URLs"
    end

    stations_by_zip = Hash.new { |groups, key| groups[key] = [] }
    stations_by_city = Hash.new { |groups, key| groups[key] = [] }
    stations.each do |station|
      state_code = station["state"].to_s.upcase
      zip = station["zip"].to_s.strip
      city = station["city"].to_s.strip.downcase
      stations_by_zip[[state_code, zip]] << station unless zip.empty?
      stations_by_city[[state_code, city]] << station unless city.empty?
    end
    [stations_by_zip, stations_by_city].each do |groups|
      groups.each_value { |group| group.sort_by! { |station| station.fetch("station_name") } }
    end

    stations.each do |station|
      raise ArgumentError, "Each station record must be an object" unless station.is_a?(Hash)

      slug = station["slug"].to_s
      name = station["station_name"].to_s
      raise ArgumentError, "Each station needs a slug and station_name" if slug.empty? || name.empty?
      raise ArgumentError, "Invalid station page slug: #{slug}" unless slug.match?(/\A[a-zA-Z0-9_-]+\z/)
      raise ArgumentError, "Duplicate station page slug: #{slug}" if slugs.key?(slug)

      slugs[slug] = true
      category = station_categories.fetch(station.fetch("id"))
      state_code = station["state"].to_s.upcase
      same_zip = stations_by_zip[[state_code, station["zip"].to_s.strip]]
      nearby_stations = same_zip.reject { |candidate| candidate["id"] == station["id"] }
      if nearby_stations.empty? && !station["city"].to_s.strip.empty?
        same_city = stations_by_city[[state_code, station["city"].strip.downcase]]
        nearby_stations = same_city.reject { |candidate| candidate["id"] == station["id"] }
      end
      nearby_stations = nearby_stations.first(5)
      site.pages << StationPage.new(site, station, category, nearby_stations)
    end

    state_groups = stations.group_by do |station|
      state_code = station["state"].to_s.strip.upcase
      unless state_code.match?(/\A[A-Z]{2}\z/)
        raise ArgumentError, "Station #{station['id']} must have a two-letter state or territory code"
      end

      state_code
    end
    state_groups.each do |state_code, state_stations|
      state = {
        "code" => state_code,
        "name" => STATE_NAMES.fetch(state_code, state_code),
        "slug" => state_code.downcase,
        "count" => state_stations.length,
        "average_nearest_distance_miles" => state_stations.first.fetch("state_average_nearest_distance_miles"),
        "geocoded_station_count" => state_stations.first.fetch("state_geocoded_station_count")
      }
      state_categories = categories.filter_map do |category|
        category_state = category.fetch("states").find { |entry| entry.fetch("code") == state_code }
        next unless category_state

        category.merge("count" => category_state.fetch("count"))
      end
      site.pages << StationStatePage.new(site, state, state_categories)
    end

    posts = site.posts.docs.sort_by(&:date).reverse
    total_pages = [(posts.length.to_f / BLOG_PAGE_SIZE).ceil, 1].max
    total_pages.times do |index|
      page_number = index + 1
      page_posts = posts.slice(index * BLOG_PAGE_SIZE, BLOG_PAGE_SIZE) || []
      site.pages << BlogArchivePage.new(site, page_number, page_posts, total_pages)
    end
  end
end
