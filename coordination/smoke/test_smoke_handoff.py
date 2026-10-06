"""Guard the release handoff against stale heads and draft-only acceptance."""

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


class SmokeHandoffTests(unittest.TestCase):
    def setUp(self):
        self.wip = read("coordination/state/WIP.json")
        self.manifest = read(self.wip["p2ActivationManifest"]["artifact"])
        self.plan = read(self.wip["smokeExecutionPlan"]["artifact"])
        self.package = read(self.wip["packageResult"]["preflight"])

    def test_final_acceptance_is_bound_to_canonical_and_evidence(self):
        validation = self.plan["acceptanceValidation"]
        argv = validation["argv"]
        self.assertEqual(argv[:2], ["python3", "coordination/smoke/validate_runtime_capture_contract.py"])
        self.assertIn("--require-pass", argv)
        self.assertNotIn("--self-test", argv)
        self.assertEqual(argv[argv.index("--expected-canonical") + 1], self.plan["exactCanonicalSha"])
        self.assertEqual(argv[argv.index("--evidence-root") + 1], self.plan["evidenceRoot"])
        self.assertEqual(argv[2], self.plan["evidenceRoot"] + "/capture-receipt.json")
        self.assertEqual(validation["requiredOutput"], "SMOKE_RUNTIME_CAPTURE_PASS_OK")
        self.assertNotEqual(validation["requiredOutput"], validation["draftOutput"])
        self.assertIs(validation["draftCanAuthorizeRelease"], False)

    def test_downstream_consumers_require_strict_acceptance_and_build(self):
        marker = self.plan["acceptanceValidation"]["requiredOutput"]
        self.assertIn(marker, " ".join(self.manifest["activationConditions"]))
        self.assertIn(marker, self.package["packageGate"]["unlockCondition"])
        self.assertIn(marker, " ".join(self.package["postUnlockActions"]))
        pipeline = self.manifest["pipelineAfterProducer"]
        for requirement in (pipeline[0], pipeline[3]):
            for gate in ("Mapped Build", "Foundation", "Class/Education", "Progression"):
                self.assertIn(gate, requirement)
            self.assertIn("exact", requirement)

    def test_current_producer_reservations_agree(self):
        self.assertEqual(self.wip["nextProducerReservation"], self.wip["wip"]["nextProducerReservation"])
        pointer = self.wip["p2ActivationManifest"]
        self.assertEqual(pointer["expectedBaseSha"], self.manifest["expectedBase"]["sha"])
        self.assertEqual(pointer["proposedProducerBranch"], self.manifest["futureProducer"]["proposedBranch"])
        self.assertEqual(self.plan["exactCanonicalSha"], self.package["canonical"]["sha"])
        canonical = self.wip["canonical"]["sha"]
        for recorded in (
            self.plan["exactCanonicalSha"],
            self.package["canonical"]["sha"],
            self.manifest["expectedBase"]["sha"],
            self.wip["wip"]["nextProducerReservation"]["inputSha"],
        ):
            self.assertEqual(recorded, canonical)


if __name__ == "__main__":
    unittest.main()
