#!/usr/bin/env python3
"""Fetch active AFDC destination chargers and write Jekyll station data."""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
import time
import socket
from decimal import Decimal, InvalidOperation
from pathlib import Path
from tempfile import NamedTemporaryFile
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlparse
from urllib.request import Request, urlopen

API_URL = "https://developer.nrel.gov/api/alt-fuel-stations/v1.json"
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "_data" / "destination_chargers.json"
PAGE_SIZE = 200
MAX_RETRIES = 5
EARTH_RADIUS_MILES = 3958.7613

STATE_CODES = (
    "AL"
).split()

DESTINATION_FACILITY_TYPES = {
    "HOTEL",
    "INN",
    "B_AND_B",
    "RESTAURANT",
    "PARK",
    "NATL_PARK",
    "RV_PARK",
    "CAMPGROUND",
    "SHOPPING_CENTER",
    "MULTI_UNIT_DWELLING",
}

TEXT_FIELDS = (
    "street_address",
    "station_phone",
    "city",
    "state",
    "zip",
    "access_days_time",
    "ev_pricing",
)


def normalize_count(value: object, field: str, station_id: str) -> int:
    if value is None or value == "":
        return 0
    try:
        number = Decimal(str(value))
    except InvalidOperation as error:
        raise ValueError(f"Station {station_id}: {field} must be a non-negative whole number") from error
    if not number.is_finite() or number < 0 or number != number.to_integral_value():
        raise ValueError(f"Station {station_id}: {field} must be a non-negative whole number")
    return int(number)


def normalize_coordinate(value: object, field: str, station_id: str) -> float | None:
    if value is None or value == "":
        return None
    try:
        coordinate = float(value)
    except (TypeError, ValueError) as error:
        raise ValueError(f"Station {station_id}: invalid {field}") from error
    bounds = (-90, 90) if field == "latitude" else (-180, 180)
    if not math.isfinite(coordinate) or not bounds[0] <= coordinate <= bounds[1]:
        raise ValueError(f"Station {station_id}: {field} is outside its valid range")
    return coordinate


def normalize_connectors(value: object) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        values = re.split(r"[,\s;|]+", value)
    elif isinstance(value, list):
        values = value
    else:
        raise ValueError("Station connector types must be a string or list")

    connectors = []
    for connector in values:
        text = str(connector).strip()
        if text and text not in connectors:
            connectors.append(text)
    return connectors


def map_station_to_target_schema(record: dict[str, object]) -> dict[str, object] | None:
    facility_type = str(record.get("facility_type") or "").strip().upper()
    if facility_type not in DESTINATION_FACILITY_TYPES:
        return None

    raw_id = record.get("id")
    station_id = "" if raw_id is None else str(raw_id).strip()
    station_name = str(record.get("station_name") or "").strip()
    state = str(record.get("state") or "").strip().upper()
    if not station_id or not station_name:
        raise ValueError("Each destination station must have an ID and name")
    if not re.fullmatch(r"[A-Z]{2}", state):
        raise ValueError(f"Station {station_id}: state must be a two-letter code")

    slug = re.sub(r"[^a-z0-9_-]+", "-", station_id.lower()).strip("-_")
    if not slug:
        raise ValueError(f"Station {station_id}: ID cannot be used to create a page URL")

    station: dict[str, object] = {
        "id": station_id,
        "station_name": station_name,
        "facility_type": facility_type,
    }
    for field in TEXT_FIELDS:
        value = record.get(field)
        station[field] = str(value).strip() if value is not None and str(value).strip() else None
    station["state"] = state
    station["ev_level1_num"] = normalize_count(record.get("ev_level1_evse_num"), "ev_level1_num", station_id)
    station["ev_level2_num"] = normalize_count(record.get("ev_level2_evse_num"), "ev_level2_num", station_id)
    station["ev_dc_fast_num"] = normalize_count(record.get("ev_dc_fast_num"), "ev_dc_fast_num", station_id)
    station["ev_connector_types"] = normalize_connectors(record.get("ev_connector_types"))
    station["latitude"] = normalize_coordinate(record.get("latitude"), "latitude", station_id)
    station["longitude"] = normalize_coordinate(record.get("longitude"), "longitude", station_id)
    station["slug"] = slug
    return station


def distance_miles(first: dict[str, object], second: dict[str, object]) -> float:
    latitude_1 = math.radians(float(first["latitude"]))
    latitude_2 = math.radians(float(second["latitude"]))
    latitude_delta = latitude_2 - latitude_1
    longitude_delta = math.radians(float(second["longitude"]) - float(first["longitude"]))
    haversine = (
        math.sin(latitude_delta / 2) ** 2
        + math.cos(latitude_1)
        * math.cos(latitude_2)
        * math.sin(longitude_delta / 2) ** 2
    )
    return 2 * EARTH_RADIUS_MILES * math.asin(min(1, math.sqrt(haversine)))


def add_state_distance_averages(stations: list[dict[str, object]]) -> None:
    states: dict[str, list[dict[str, object]]] = {}
    for station in stations:
        state = str(station["state"])
        states.setdefault(state, []).append(station)

    for state, state_stations in states.items():
        geocoded = [
            station
            for station in state_stations
            if station["latitude"] is not None and station["longitude"] is not None
        ]
        nearest_distances = []
        for index, station in enumerate(geocoded):
            nearest = min(
                distance_miles(station, other)
                for other_index, other in enumerate(geocoded)
                if index != other_index
            ) if len(geocoded) > 1 else None
            if nearest is not None:
                nearest_distances.append(round(nearest, 2))

        average = round(sum(nearest_distances) / len(nearest_distances), 2) if nearest_distances else None
        for station in state_stations:
            station["state_average_nearest_distance_miles"] = average
            station["state_geocoded_station_count"] = len(geocoded)


def fetch_page(state: str, offset: int, api_key: str) -> dict[str, object]:
    parameters = urlencode(
        {
            "api_key": api_key,
            "fuel_type": "ELEC",
            "status": "E",
            "state": state,
            "limit": PAGE_SIZE,
            "offset": offset,
        }
    )
    request = Request(
        f"{API_URL}?{parameters}",
        headers={"Accept": "application/json", "User-Agent": "open-ev-stations-data-import/1.0"},
    )

    for attempt in range(MAX_RETRIES):
        try:
            with urlopen(request, timeout=30) as response:
                payload = json.loads(response.read().decode("utf-8"))
            if not isinstance(payload, dict):
                raise ValueError(f"AFDC API returned an invalid response for {state}")
            return payload
        except HTTPError as error:
            retryable = error.code == 429 or 500 <= error.code <= 599
            if not retryable or attempt == MAX_RETRIES - 1:
                raise RuntimeError(
                    f"AFDC API returned HTTP {error.code} for {state} at offset {offset}"
                ) from None
        except (URLError, TimeoutError, OSError) as error:
            # Provide more explicit diagnostic information for DNS errors
            underlying = getattr(error, 'reason', error)
            if isinstance(underlying, socket.gaierror):
                details = f"DNS resolution failed for host {urlparse(API_URL).hostname}: {underlying}"
            else:
                details = str(underlying)

            if attempt == MAX_RETRIES - 1:
                # redact API key if it somehow appears in the message
                details = details.replace(api_key, "[REDACTED]")
                raise RuntimeError(
                    f"AFDC API request failed for {state} at offset {offset} "
                    f"after {MAX_RETRIES} attempts: {details}"
                ) from error
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise RuntimeError(f"AFDC API returned invalid JSON for {state} at offset {offset}") from error
        time.sleep(2 ** attempt)

    raise RuntimeError(f"AFDC API request failed for {state} at offset {offset}")


def fetch_state(state: str, api_key: str) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    offset = 0
    total_results: int | None = None

    while total_results is None or offset < total_results:
        payload = fetch_page(state, offset, api_key)
        page_records = payload.get("fuel_stations")
        raw_total = payload.get("total_results")
        if not isinstance(page_records, list):
            raise RuntimeError(f"AFDC API response for {state} is missing its station list")
        if isinstance(raw_total, bool):
            raise RuntimeError(f"AFDC API response for {state} has an invalid total_results value")
        try:
            page_total = int(raw_total)
        except (TypeError, ValueError):
            raise RuntimeError(f"AFDC API response for {state} has an invalid total_results value") from None
        if page_total < 0 or (total_results is not None and page_total != total_results):
            raise RuntimeError(f"AFDC API returned inconsistent result totals for {state}")
        total_results = page_total
        if not page_records and offset < total_results:
            raise RuntimeError(f"AFDC API returned an incomplete page for {state} at offset {offset}")
        if any(not isinstance(record, dict) for record in page_records):
            raise RuntimeError(f"AFDC API returned an invalid station record for {state}")

        records.extend(page_records)
        offset += len(page_records)
        if len(page_records) > PAGE_SIZE:
            raise RuntimeError(f"AFDC API returned more than {PAGE_SIZE} records for {state}")

    if len(records) != total_results:
        raise RuntimeError(f"AFDC API returned {len(records)} of {total_results} records for {state}")
    return records


def fetch_all_stations(api_key: str) -> list[dict[str, object]]:
    stations: list[dict[str, object]] = []
    seen_ids: set[str] = set()
    seen_slugs: set[str] = set()

    for state in STATE_CODES:
        print(f"Fetching active EV stations for {state}...", flush=True)
        for record in fetch_state(state, api_key):
            station = map_station_to_target_schema(record)
            if station is None:
                continue
            if station["state"] != state:
                raise ValueError(f"Station {station['id']} was returned for the wrong state")
            station_id = str(station["id"])
            slug = str(station["slug"])
            if station_id in seen_ids:
                raise ValueError(f"Duplicate station ID returned by AFDC: {station_id}")
            if slug in seen_slugs:
                raise ValueError(f"Station IDs produce a duplicate page slug: {slug}")
            seen_ids.add(station_id)
            seen_slugs.add(slug)
            stations.append(station)

    if not stations:
        raise ValueError("The AFDC API returned no destination stations; refusing to write empty data")
    add_state_distance_averages(stations)
    return stations


def write_stations(stations: list[dict[str, object]], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=output_path.parent,
            prefix=f"{output_path.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary_file:
            temporary_path = Path(temporary_file.name)
            json.dump(stations, temporary_file, ensure_ascii=False, indent=2)
            temporary_file.write("\n")
        os.replace(temporary_path, output_path)
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT_PATH, help="JSON output path")
    arguments = parser.parse_args()
    api_key = os.environ.get("AFDC_API_KEY", "").strip()
    if not api_key:
        parser.error("set the AFDC_API_KEY environment variable")

    try:
        stations = fetch_all_stations(api_key)
        write_stations(stations, arguments.output)
    except (RuntimeError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"Wrote {len(stations)} destination stations to {arguments.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
