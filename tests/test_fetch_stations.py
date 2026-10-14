import json
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from tools import fetch_stations


class FetchStationsTests(unittest.TestCase):
    def test_maps_api_station_to_jekyll_schema(self):
        record = {
            "id": 123,
            "station_name": "Example Hotel",
            "facility_type": "HOTEL",
            "state": "ca",
            "ev_level1_evse_num": None,
            "ev_level2_evse_num": "2",
            "ev_dc_fast_num": 0,
            "ev_connector_types": "J1772, TESLA",
            "latitude": "34.0",
            "longitude": "-118.0",
        }

        station = fetch_stations.map_station_to_target_schema(record)

        self.assertEqual(station["id"], "123")
        self.assertEqual(station["state"], "CA")
        self.assertEqual(station["slug"], "123")
        self.assertEqual(station["ev_level1_num"], 0)
        self.assertEqual(station["ev_level2_num"], 2)
        self.assertEqual(station["ev_connector_types"], ["J1772", "TESLA"])
        self.assertIsNone(station["street_address"])

    def test_ignores_non_destination_facility_types(self):
        self.assertIsNone(
            fetch_stations.map_station_to_target_schema(
                {"id": 1, "facility_type": "GAS_STATION"}
            )
        )

    def test_calculates_state_metrics_for_geocoded_records(self):
        stations = [
            {"state": "CA", "latitude": 34.0, "longitude": -118.0},
            {"state": "CA", "latitude": 34.0, "longitude": -117.0},
            {"state": "CA", "latitude": None, "longitude": None},
        ]

        fetch_stations.add_state_distance_averages(stations)

        self.assertEqual(stations[0]["state_geocoded_station_count"], 2)
        self.assertEqual(stations[0]["state_average_nearest_distance_miles"], 57.28)
        self.assertEqual(stations[2]["state_average_nearest_distance_miles"], 57.28)

    def test_single_geocoded_station_has_no_nearest_station_average(self):
        stations = [{"state": "AK", "latitude": 61.0, "longitude": -149.0}]

        fetch_stations.add_state_distance_averages(stations)

        self.assertEqual(stations[0]["state_geocoded_station_count"], 1)
        self.assertIsNone(stations[0]["state_average_nearest_distance_miles"])

    def test_fetch_state_reads_every_page(self):
        pages = [
            {"total_results": 3, "fuel_stations": [{"id": 1}, {"id": 2}]},
            {"total_results": 3, "fuel_stations": [{"id": 3}]},
        ]
        requests = []

        def fake_fetch_page(state, offset, api_key):
            requests.append((state, offset, api_key))
            return pages.pop(0)

        with patch.object(fetch_stations, "PAGE_SIZE", 2), patch.object(
            fetch_stations, "fetch_page", side_effect=fake_fetch_page
        ):
            records = fetch_stations.fetch_state("CA", "test-key")

        self.assertEqual([record["id"] for record in records], [1, 2, 3])
        self.assertEqual(requests, [("CA", 0, "test-key"), ("CA", 2, "test-key")])

    def test_writes_valid_json_to_requested_path(self):
        stations = [{"id": "1", "station_name": "Example"}]
        with TemporaryDirectory() as temporary_directory:
            output_path = Path(temporary_directory) / "_data" / "stations.json"

            fetch_stations.write_stations(stations, output_path)

            self.assertEqual(json.loads(output_path.read_text(encoding="utf-8")), stations)
            self.assertEqual(list(output_path.parent.iterdir()), [output_path])


if __name__ == "__main__":
    unittest.main()
