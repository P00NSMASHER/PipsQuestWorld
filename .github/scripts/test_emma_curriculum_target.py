import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "emma_curriculum_target", Path(__file__).with_name("emma_curriculum_target.py")
)
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)

class TargetTests(unittest.TestCase):
    def setUp(self):
        self.good = {"schemaVersion": 1, "activeBranch": "rebuild/emma-classroom-study-v1",
                     "contractRoot": "school/emma-classroom"}

    def test_real_consumer(self):
        self.assertEqual(adapter.resolve(self.good), self.good["activeBranch"])

    def test_new_visual_game_branch_requires_only_config_review(self):
        config = dict(self.good, activeBranch="rebuild/emma-classroom-v2")
        self.assertEqual(adapter.resolve(config), "rebuild/emma-classroom-v2")

    def test_default_and_unsafe_refs_fail_closed(self):
        for branch in ("main", "develop", "HEAD", "", "-bad", "feature/../main",
                       "refs/heads//trick", "feature/.hidden", "foo.lock", "f@{0}",
                       "bad branch", "feature\\name", "feature/trailing/", "feature/.."):
            with self.subTest(branch=branch):
                with self.assertRaises(ValueError):
                    adapter.resolve(dict(self.good, activeBranch=branch))

    def test_contract_root_cannot_follow_game_assets(self):
        for root in ("game/", "school/some-other-game", "../private"):
            with self.subTest(root=root):
                with self.assertRaises(ValueError):
                    adapter.resolve(dict(self.good, contractRoot=root))

    def test_no_extra_fields_or_sensitive_paths(self):
        with self.assertRaises(ValueError):
            adapter.resolve(dict(self.good, run="curl arbitrary script"))
        with self.assertRaises(ValueError):
            adapter.resolve(dict(self.good, schemaVersion=True))
        with self.assertRaises(ValueError):
            adapter.resolve(dict(self.good, contractRoot=None))

if __name__ == "__main__":
    unittest.main()
