# Open EV Stations

A Jekyll site styled with Tailwind CSS for discovering EV destination chargers, RV-friendly hookups, and trailer-friendly charging stops.

## Requirements

- Ruby and Bundler
- Node.js and npm
- Python 3.10 or later (for fetching station data)

## Get started

Install the Ruby and JavaScript dependencies:

```sh
bundle install
npm install
```

Start the local development server with Tailwind CSS watching for changes:

```sh
npm run dev
```

Build the optimized stylesheet and Jekyll site into `_site`:

```sh
npm run build
```

The Tailwind source stylesheet is `assets/css/tailwind.input.css`; the compiled stylesheet is generated at `assets/css/tailwind.css`.

Jekyll uses Kramdown's GitHub Flavored Markdown parser, `jekyll-seo-tag` for page metadata, `jekyll-sitemap` for the sitemap, and `jekyll-last-modified-at` to report source-file update dates from Git history (or file modification times when Git is unavailable). The public origin is configured as `url` in `_config.yml`; update it if the deployment hostname changes so canonical URLs and sitemap entries stay correct. The root `robots.txt` points crawlers to the sitemap. Keep non-content pages such as 404, admin, or confirmation pages out of the sitemap by setting `sitemap: false` in their front matter. Rendered images receive lazy loading automatically unless they already specify a `loading` attribute.

## Project status

The responsive directory includes an interactive U.S. state map, state and category hubs, and individual station pages with interactive maps. Station pages use location- and equipment-specific titles and descriptions, place structured data, breadcrumbs, and cross-links to nearby stations when shared ZIP-code or city data is available. Station, state, state/category, and category pages include visible FAQs generated from available directory data. The site is intentionally read-only and does not provide trip planning.

## Importing AFDC station data from CSV

The importer reads the AFDC CSV export and writes destination-station records to `_data/destination_chargers.json`. Jekyll generates station pages at `/state/<state-code>/city/<city>/category/<category-short-name>/<station-friendly-name>/`. State hubs use `/state/<state-code>/`, category hubs use `/category/<category-short-name>/`, and state/category listings use `/state/<state-code>/category/<category-short-name>/`. Blog posts use `/blog/<blog-post-slug>/`, with the archive at `/blog/`. Station names that would otherwise produce duplicate URLs receive a station-ID suffix.

Import the source file in `external_data`:

```sh
npm run import:stations -- "external_data/alt_fuel_stations (Oct 12 2026).csv"
```

To keep the detail directory focused on destination charging, the importer selects hotels, inns, B&Bs, restaurants, parks, campgrounds/RV parks, shopping centers, and multi-unit dwellings for station pages. It maps the export's actual AFDC headings (such as `EV Level2 EVSE Num` and `EV DC Fast Count`) to the station fields.

After importing, build the site:

```sh
npm run build
```

The importer requires the CSV columns `ID`, `Station Name`, and `Facility Type`; it also extracts `Street Address`, `Station Phone`, `City`, `State`, `ZIP`, `Access Days Time`, `EV Pricing`, `EV Connector Types`, `EV Level1 EVSE Num`, `EV Level2 EVSE Num`, `EV DC Fast Count`, `Latitude`, and `Longitude` when available. During import, it calculates each state's average nearest-station distance in straight-line miles using the Haversine formula and stores the rounded average and geocoded station count on each station record in `_data/destination_chargers.json`. State pages display this metric. The homepage map links to state pages showing available station categories and counts; selecting a category opens a state/category page listing matching stations. Category pages also list states and territories that have matching stations. Station detail pages display available phone numbers and link to each record. Valid coordinates are passed into each station page and rendered on a Leaflet map using OpenStreetMap tiles. Stations without both coordinates show a location-unavailable message instead. Missing charger counts display as zero and other missing details are labeled unavailable. Station structured data uses Schema.org `Place` with the available address, coordinates, charger counts, and connector types; the directory does not claim amenities that are absent from its source data.

The raw CSV is excluded from the published site and ignored by Git to avoid committing the 28 MB source export. Commit the generated destination data to include station pages in a deployment. Station detail maps use Leaflet with OpenStreetMap tiles; follow the [OpenStreetMap tile usage policy](https://operations.osmfoundation.org/policies/tiles/).

## Fetching station data from the AFDC API

The API importer in `tools/fetch_stations.py` fetches active electric stations from the Alternative Fuels Data Center API, keeps destination facility types supported by the directory, calculates the state nearest-station metrics, and writes `_data/destination_chargers.json` for Jekyll. It uses Python's standard library and requires an API key:

```sh
# PowerShell
$env:AFDC_API_KEY = "your-api-key"
python tools/fetch_stations.py

# macOS/Linux
AFDC_API_KEY="your-api-key" python3 tools/fetch_stations.py
```

The `Update station data` GitHub Actions workflow runs weekly and can also be started manually with **Actions → Update station data → Run workflow**. Add an Actions repository secret named `AFDC_API_KEY` containing an API key from the [NREL developer network](https://developer.nrel.gov/). The workflow runs `tools/fetch_stations.py` to create or update `_data/destination_chargers.json`, opens a pull request against `main` when the file changes, and immediately merges it without waiting for approval. If the data has not changed, no pull request is created. API failures or invalid/incomplete responses fail the workflow without replacing the existing data. The workflow's `GITHUB_TOKEN` needs permission to write contents and pull requests, and repository rules must allow it to merge without review.

The homepage state map is sourced from [Simplemaps' free U.S. SVG map](https://simplemaps.com/resources/svg-us) and used under its [SVG map license](https://simplemaps.com/resources/svg-license). Map attribution and usage details are published on the site's `/disclaimer/` page, linked from the footer.

The homepage's "For the glove box" feed shows the three most recent Jekyll posts from `_posts`. Its "All guides" link opens `/blog/`, a paginated archive showing up to six posts per page. Add dated Markdown posts there with `layout: post`, a title, and an excerpt to publish charging and road-trip guides.
