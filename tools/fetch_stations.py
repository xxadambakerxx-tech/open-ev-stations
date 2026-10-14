#!/usr/bin/env python3
"""Fetch active AFDC destination chargers and write Jekyll station data."""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import socket
import sys
import time
from decimal import Decimal, InvalidOperation
from pathlib import Path
from tempfile import NamedTemporaryFile
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlparse
from urllib.request import Request, urlopen

API_URL = "https://developer.nrel.gov/api/alt-fuel-stations/v1.json"
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "_data" / "destination_chargers.json"
PAGE_SIZE = 200
MAX_RETRIES = 3
EARTH_RADIUS_MILES = 3958.7613
DNS_RESOLVE_RETRIES = 3
DNS_RESOLVE_BACKOFF = 2

STATE_CODES = (
    "AL AK AZ AR CA CO CT DE DC FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN "
    "MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA "
    "WA WV WI WY PR"
).split()

# ... keep the existing code unchanged ...

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
            underlying = getattr(error, "reason", error)
            if isinstance(underlying, socket.gaierror):
                details = f"DNS resolution failed for host {urlparse(API_URL).hostname}: {underlying}"
            else:
                details = str(underlying)

            if attempt == MAX_RETRIES - 1:
                details = details.replace(api_key, "[REDACTED]")
                raise RuntimeError(
                    f"AFDC API request failed for {state} at offset {offset} "
                    f"after {MAX_RETRIES} attempts: {details}"
                ) from error
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise RuntimeError(f"AFDC API returned invalid JSON for {state} at offset {offset}") from error
        time.sleep(2 ** attempt)

    raise RuntimeError(f"AFDC API request failed for {state} at offset {offset}")

def is_api_host_resolvable(api_url: str) -> bool:
    parsed = urlparse(api_url)
    hostname = parsed.hostname
    if not hostname:
        return False

    for attempt in range(DNS_RESOLVE_RETRIES):
        try:
            socket.getaddrinfo(hostname, None)
            return True
        except socket.gaierror as e:
            print(f"DNS resolve attempt {attempt + 1}/{DNS_RESOLVE_RETRIES} failed for {hostname}: {e}", file=sys.stderr)
            if attempt < DNS_RESOLVE_RETRIES - 1:
                time.sleep(DNS_RESOLVE_BACKOFF ** attempt)
    return False

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT_PATH, help="JSON output path")
    arguments = parser.parse_args()

    api_key = os.environ.get("AFDC_API_KEY", "").strip()
    if not api_key:
        parser.error("set the AFDC_API_KEY environment variable")

    if not is_api_host_resolvable(API_URL):
        if arguments.output.exists():
            print(
                f"Warning: Could not resolve AFDC API host ({urlparse(API_URL).hostname}).",
                file=sys.stderr,
            )
            print(f"Using existing station data at {arguments.output}; skipping fetch.")
            return 0
        parser.error(f"Could not resolve AFDC API host ({urlparse(API_URL).hostname}) and no existing data available")

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