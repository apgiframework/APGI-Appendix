import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_validation_artifacts as v


class ValidationArtifactTests(unittest.TestCase):
    def test_repository_artifacts_are_consistent(self):
        self.assertEqual(v.check_all(), [])

    def test_new_constant_without_provenance_fails(self):
        consts = v.constants_in_source()
        consts["invented"] = ("Threshold Parameters", "1.0")
        problems = v.check_provenance(v._load("default-parameter-provenance.json"), consts)
        self.assertTrue(any("invented" in p for p in problems))

    def test_derived_label_needs_source(self):
        reg = copy.deepcopy(v._load("default-parameter-provenance.json"))
        entry = next(e for e in reg["entries"] if e["scope"] == "scientific_default")
        entry["provenance"] = "analytically_derived"
        problems = v.check_provenance(reg, v.constants_in_source())
        self.assertTrue(any("source_reference" in p for p in problems))

    def test_changed_value_is_detected(self):
        reg = copy.deepcopy(v._load("default-parameter-provenance.json"))
        reg["entries"][0]["value"] = "999"
        self.assertTrue(v.check_provenance(reg, v.constants_in_source()))

    def test_profile_rejects_protocol_claims_and_missing_rationale(self):
        p = copy.deepcopy(v._load("application-validation-profile.json"))
        p["protocol_v1_2_definitions_implemented"] = ["protocol_1"]
        next(r for r in p["requirements"] if r["applicability"] == "NOT_APPLICABLE").pop("rationale")
        problems = v.check_profile(p)
        self.assertEqual(len(problems), 2)

    def test_implemented_status_needs_evidence(self):
        p = copy.deepcopy(v._load("application-validation-profile.json"))
        r = next(r for r in p["requirements"] if r["applicability"] == "R")
        r["status"], r["evidence"] = "Implemented", ""
        self.assertTrue(v.check_profile(p))

    def test_classified_claim_requires_registered_clm(self):
        reg = copy.deepcopy(v._load("claim-register.json"))
        reg["claims"][0]["tier"] = "established"
        self.assertTrue(v.check_claims(reg))

    def test_supported_combination_requires_schema_hashes(self):
        comp = copy.deepcopy(v._load("release-compatibility.json"))
        comp["supported_combinations"] = [{"app": "1.0"}]
        self.assertTrue(v.check_compat(comp))

    def test_version_drift_is_detected(self):
        comp = copy.deepcopy(v._load("release-compatibility.json"))
        comp["app"]["version"] = "2.0"
        self.assertTrue(v.check_compat(comp))


if __name__ == "__main__":
    unittest.main()
