#!/usr/bin/env python3
"""Tests for the local-evidence and gate-table scripts (run: python3 -m unittest scripts/test_local_evidence.py)."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import check_local_evidence as ev  # noqa: E402
import generate_gate_table as gen  # noqa: E402

FIX = json.loads((ev.APP / "ignition-fixtures.json").read_text())
YAML = b"""version: "2027.1"
d2_decision: "D2: model home is the framework repository"
gates:
  - {id: K7a, status: PASS, description: "Structural identifiability", result: "rank 7/7"}
  - {id: K7c, status: FAIL, description: "Parameter recovery", result: "r < 0.8"}
"""


def run_fixtures(doc):
    with tempfile.TemporaryDirectory() as d:
        p = Path(d) / "f.json"
        p.write_text(json.dumps(doc))
        return ev.check_fixtures(p)


class FixtureChecks(unittest.TestCase):
    def test_bundled_fixtures_pass(self):
        self.assertEqual(ev.check_fixtures(), [])

    def test_missing_sign_coverage_fails(self):
        doc = copy.deepcopy(FIX)
        doc["vectors"] = [v for v in doc["vectors"] if v["surprise"] >= v["threshold"]]
        self.assertTrue(any("negative, zero and positive" in p for p in run_fixtures(doc)))

    def test_non_finite_and_wrong_expected_fail(self):
        doc = copy.deepcopy(FIX)
        doc["vectors"][0]["surprise"] = float("inf")
        doc["vectors"][1]["expected"] = 0.9
        problems = run_fixtures(doc)
        self.assertTrue(any("finite" in p for p in problems))
        self.assertTrue(any("disagrees" in p for p in problems))

    def test_qualified_labels_not_allowed_locally(self):
        doc = copy.deepcopy(FIX)
        doc["evidence_status"] = "qualified"
        self.assertTrue(any("evidence_status" in p for p in run_fixtures(doc)))


class GateTable(unittest.TestCase):
    def test_bundled_gate_table_passes(self):
        self.assertEqual(ev.check_gate_table(), [])

    def test_generator_output_passes_checks(self):
        table = gen.convert(YAML)
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "g.json"
            p.write_text(json.dumps(table))
            self.assertEqual(ev.check_gate_table(p), [])
        self.assertEqual([g["id"] for g in table["gates"]], ["K7a", "K7c"])
        self.assertEqual(table["evidenceStatus"], "published")

    def test_generator_rejects_pending_and_missing_d2(self):
        with self.assertRaises(ValueError):
            gen.convert(YAML.replace(b"status: PASS", b"status: PENDING"))
        with self.assertRaises(ValueError):
            gen.convert(YAML.replace(b"d2_decision", b"other"))


if __name__ == "__main__":
    unittest.main()
