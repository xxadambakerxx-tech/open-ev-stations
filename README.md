# Open EV Stations

A Jekyll site styled with Tailwind CSS for discovering EV destination chargers, RV-friendly hookups, and trailer-friendly charging stops.

## Requirements

- Ruby and Bundler
- Node.js and npm

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

## Project status

The current milestone establishes the responsive directory landing page and its visual direction. Its map graphic is illustrative only; the site is intentionally read-only and does not provide trip planning.

## Importing AFDC station data from CSV

The importer reads the AFDC CSV export and writes destination-station records to `_data/destination_chargers.json`. Jekyll then generates a page at `/chargers/<station-id>/` for each imported station, using `_layouts/station.html`.

Import the source file in `external_data`:

```sh
npm run import:stations -- "external_data/alt_fuel_stations (Oct 12 2026).csv"
```

The source export contains more than 82,000 EV stations. To keep this initial directory focused on destination charging, the importer selects hotels, inns, B&Bs, restaurants, parks, campgrounds/RV parks, shopping centers, and multi-unit dwellings. It maps the export's actual AFDC headings (such as `EV Level2 EVSE Num` and `EV DC Fast Count`) to the station fields.

After importing, build the site:

```sh
npm run build
```

The importer requires the CSV columns `ID`, `Station Name`, and `Facility Type`; it also extracts `Street Address`, `City`, `State`, `ZIP`, `Access Days Time`, `EV Pricing`, `EV Connector Types`, `EV Level2 EVSE Num`, `EV DC Fast Count`, `Latitude`, and `Longitude` when available. Jekyll generates category landing pages from the imported facility types and links to each station detail page. Valid coordinates are passed into each station page and rendered on a Leaflet map using OpenStreetMap tiles. Stations without both coordinates show a location-unavailable message instead. Missing charger counts display as zero and other missing details are labeled unavailable.

The raw CSV is excluded from the published site and ignored by Git to avoid committing the 28 MB source export. The generated JSON is the versioned Jekyll data source, so commit it when you want imported station pages included in a deployment.
