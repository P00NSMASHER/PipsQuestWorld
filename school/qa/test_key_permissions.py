import json
import unittest
from unittest.mock import patch
from cloud_qa import verify_key_permissions

QA = "98765432101"
KEY = "example-qa-key-not-a-real-secret"

class FakeResponse:
    def __init__(self, payload):
        self.payload = payload
    def __enter__(self):
        return self
    def __exit__(self, *args):
        return False
    def read(self):
        return json.dumps(self.payload).encode("utf-8")

def payload(universe=QA, extra=None):
    scopes = [
        {"name": "universe-places", "operations": ["write"], "universeIds": [universe]},
        {"name": "luau-execution-sessions", "operations": ["write"], "universeIds": [universe]},
    ]
    if extra is not None:
        scopes.append(extra)
    return {"enabled": True, "expired": False, "scopes": scopes}

class KeyPermissionTests(unittest.TestCase):
    def check(self, body):
        with patch("cloud_qa.urllib.request.urlopen", return_value=FakeResponse(body)):
            return verify_key_permissions(QA, KEY)

    def test_real_dashboard_names_pass(self):
        self.check(payload())

    def test_documented_dotted_luau_alias_passes(self):
        body = payload()
        body["scopes"][1]["name"] = "universe.place.luau-execution-session"
        self.check(body)

    def test_wrong_universe_is_blocked(self):
        with self.assertRaisesRegex(ValueError, "exact QA universe"):
            self.check(payload(universe="12345678911"))

    def test_wildcard_is_blocked(self):
        with self.assertRaisesRegex(ValueError, "exact QA universe"):
            self.check(payload(universe="*"))

    def test_extra_scope_is_blocked(self):
        with self.assertRaisesRegex(ValueError, "excessive"):
            self.check(payload(extra={"name": "universe-datastores.objects", "operations": ["read"], "universeIds": [QA]}))

    def test_missing_permission_is_blocked(self):
        body = payload()
        body["scopes"].pop()
        with self.assertRaisesRegex(ValueError, "wrong or excessive"):
            self.check(body)

    def test_disabled_key_is_blocked(self):
        body = payload()
        body["enabled"] = False
        with self.assertRaisesRegex(ValueError, "disabled"):
            self.check(body)

if __name__ == "__main__":
    unittest.main()
