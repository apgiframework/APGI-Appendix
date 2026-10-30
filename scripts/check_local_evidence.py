#!/usr/bin/env python3
"""Checks for the *local* evidence bundled with the app.

These checks keep the local regression vectors and the gate table honest. They do not
establish framework parity: that needs the qualified fixtures and registered tolerances
described in docs/CONTRACT_DEPENDENCIES.md.
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "APGI-Appendix"
LOCAL_LABELS = {"data_origin": "synthetic", "evidence_status": "illustrative"}


def _sigmoid(x: float) -> float:
    return 1.0 / (1.0 + math.exp(-x))


def check_fixtures(path: Path = APP / "ignition-fixtures.json") -> list[str]:
    """Return a list of problems with the local ignition fixtures (empty when sound)."""
    doc = json.loads(path.read_text())
    problems = []
    for key, want in LOCAL_LABELS.items():
        if doc.get(key) != want:
            problems.append(f"{key} must be {want!r} for local vectors")
    if "not qualified" not in doc.get("provenance", ""):
        problems.append("provenance must state the vectors are not qualified")
    tol = doc.get("tolerance")
    if not isinstance(tol, (int, float)) or not 0 < tol < 1e-3:
        problems.append("tolerance must be a number in (0, 1e-3)")
    vectors = doc.get("vectors", [])
    signs = set()
    for i, v in enumerate(vectors):
        nums = [v.get(k) for k in ("surprise", "threshold", "gamma_sig", "expected")]
        if not all(isinstance(n, (int, float)) and math.isfinite(n) for n in nums):
            problems.append(f"vector {i}: all fields must be finite numbers")
            continue
        margin = v["surprise"] - v["threshold"]
        signs.add((margin > 0) - (margin < 0))
        if not 0.0 <= v["expected"] <= 1.0:
            problems.append(f"vector {i}: expected must be a probability")
        if isinstance(tol, (int, float)) and abs(_sigmoid(v["gamma_sig"] * margin) - v["expected"]) > tol:
            problems.append(f"vector {i}: expected disagrees with sigmoid(gamma_sig*(S-theta))")
    if signs != {-1, 0, 1}:
        problems.append("vectors must cover negative, zero and positive ignition margins")
    return problems


def check_gate_table(path: Path = APP / "gate-table.json") -> list[str]:
    """Pending rows are allowed; published rows must carry provenance and a D2 decision."""
    doc = json.loads(path.read_text())
    problems = []
    gates = {g.get("id"): g for g in doc.get("gates", [])}
    if set(gates) != {"K7a", "K7c"}:
        problems.append("gate table must contain exactly K7a and K7c")
    published = doc.get("source") == "gate-table.yaml"
    if published and doc.get("evidenceStatus") != "published":
        problems.append("published table must be labelled evidenceStatus=published")
    for gid, g in gates.items():
        if g.get("status") == "PENDING":
            if published:
                problems.append(f"{gid}: published table must not contain PENDING rows")
        elif not published:
            problems.append(f"{gid}: non-pending status requires the gate-table.yaml source")
    if published:
        for field in ("sourceSha256", "d2Decision"):
            if not doc.get(field):
                problems.append(f"published table missing {field}")
    elif doc.get("evidenceStatus") != "illustrative":
        problems.append("provisional table must be labelled illustrative")
    return problems


def main() -> int:
    problems = check_fixtures() + check_gate_table()
    for p in problems:
        print("FAIL:", p)
    if not problems:
        print("Local evidence checks passed (local regression only; parity not established).")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
