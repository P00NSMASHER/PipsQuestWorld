import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from cloud_qa import verify_target, run

KEY = "dummy-qa-key-value-123456789"

class CloudQASafetyTests(unittest.TestCase):
    def test_live_universe_is_blocked(self):
        with self.assertRaisesRegex(ValueError, "production"):
            verify_target("10768955678", "90000001", KEY)

    def test_live_place_is_blocked(self):
        with self.assertRaisesRegex(ValueError, "production"):
            verify_target("90000002", "87245440673982", KEY)

    def test_blank_ids_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "numeric"):
            verify_target("", "90000001", KEY)

    def test_missing_key_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "absent"):
            verify_target("90000002", "90000001", "")

    def test_production_key_reuse_rejected(self):
        with patch.dict(os.environ, {"ROBLOX_API_KEY": KEY}):
            with self.assertRaisesRegex(ValueError, "production key"):
                verify_target("90000002", "90000001", KEY)

    def test_distinct_qa_target_passes(self):
        verify_target("90000002", "90000001", KEY)

    def test_invalid_place_refuses_network_write(self):
        with tempfile.TemporaryDirectory() as temp:
            place = Path(temp) / "place.rbxlx"
            script = Path(temp) / "test.luau"
            place.write_bytes(b"not a place")
            script.write_text("__QA_UNIVERSE_ID__ __QA_PLACE_ID__")
            with patch("cloud_qa.request") as mocked:
                with self.assertRaisesRegex(ValueError, "Expected an XML"):
                    run("90000002", "90000001", KEY, place, script)
                mocked.assert_not_called()

if __name__ == "__main__":
    unittest.main()
