"""Unit tests for the counter service."""

import unittest

from app import app


class CounterServiceTest(unittest.TestCase):
    """Exercise the public HTTP API."""

    def setUp(self):
        self.client = app.test_client()

    def test_index_returns_service_metadata(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertEqual(payload["status"], "OK")
        self.assertEqual(payload["service"], "counter-service")

    def test_health_returns_ok(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "OK"})

    def test_counter_can_be_incremented_and_reset(self):
        self.client.delete("/count")

        first = self.client.post("/count").get_json()
        second = self.client.post("/count").get_json()
        self.assertEqual(first["count"], 1)
        self.assertEqual(second["count"], 2)

        current = self.client.get("/count").get_json()
        self.assertEqual(current["count"], 2)

        reset = self.client.delete("/count").get_json()
        self.assertEqual(reset["count"], 0)


if __name__ == "__main__":
    unittest.main()
