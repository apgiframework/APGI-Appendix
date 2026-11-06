#!/usr/bin/env python3
"""Checks the validation-spec artifacts for APGI-Appendix (component A08).

Covers APGI-PRO-004 (profile), SCI-005 (default provenance), SCI-006 (expansion),
SCI-007 (claim register), REL-004 (compatibility) and the task register. These checks
keep the records consistent with the source; they do not establish scientific parity.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "APGI-Appendix"
CONTRACTS = ROOT / "contracts"
CANONICAL = "Allostatic Precision-Gated Ignition"
BAD_EXPANSIONS = (
    "Adaptive Predictive Gamma Integration",
    "Adaptive Precision-Gated Ignition",
    "Allostatic Predictive Gated Ignition",
)
A08_APPLICABLE = {
    "PRO-004", "SCI-001", "SCI-002", "SCI-003", "SCI-004", "SCI-005", "SCI-006",
    "SCI-007", "IMP-001", "IMP-002", "IMP-003", "DAT-003", "DAT-004", "API-001",
    "API-003", "INT-001", "INT-002", "INT-003", "INT-004", "REL-001", "REL-002",
    "REL-003", "REL-004", "REL-005", "CLI-001",
}
STATUSES = {"Implemented", "Partial", "Blocked", "Fail"}


def _load(name: str):
    return json.loads((CONTRACTS / name).read_text())


def constants_in_source(path: Path = APP / "APGISimulatorConstants.swift") -> dict:
    found, group = {}, None
    for line in path.read_text().splitlines():
        m = re.match(r"\s*// MARK: - (.*)", line)
        if m:
            group = m.group(1)
            continue
        m = re.match(r"\s*static let (\w+): \w+ = (.+)$", line)
        if m:
            found[m.group(1)] = (group, m.group(2).strip())
    return found


def check_provenance(reg: dict, constants: dict) -> list[str]:
    problems = []
    entries = {e["name"]: e for e in reg["entries"]}
    for name in sorted(set(constants) - set(entries)):
        problems.append(f"constant {name} has no provenance entry")
    for name in sorted(set(entries) - set(constants)):
        problems.append(f"provenance entry {name} has no constant")
    allowed = set(reg["allowed_labels"])
    for name, e in entries.items():
        if name not in constants:
            continue
        if e["value"] != constants[name][1]:
            problems.append(f"{name}: recorded value {e['value']} differs from source {constants[name][1]}")
        if e["scope"] == "scientific_default":
            if e.get("provenance") not in allowed:
                problems.append(f"{name}: provenance must be one of {sorted(allowed)}")
            if e.get("provenance") != "assumed" and not e.get("source_reference"):
                problems.append(f"{name}: derived/calibrated label requires a source_reference")
        elif e["scope"] != "ui_layout":
            problems.append(f"{name}: unknown scope {e['scope']}")
    return problems


def check_profile(profile: dict) -> list[str]:
    problems = []
    if profile.get("profile_status") != "DRAFT - not approved":
        approvers = profile.get("approvers", {})
        if any(v == "pending" for v in approvers.values()):
            problems.append("profile may not leave DRAFT while approvers are pending")
    reqs = {r["id"]: r for r in profile["requirements"]}
    applicable = {k for k, r in reqs.items() if r["applicability"] in ("R", "C")}
    if applicable != A08_APPLICABLE:
        problems.append(f"applicable set differs from matrix 5.2: {sorted(applicable ^ A08_APPLICABLE)}")
    for k, r in reqs.items():
        if r["applicability"] == "NOT_APPLICABLE":
            if not r.get("rationale") or not r.get("approver"):
                problems.append(f"{k}: NOT_APPLICABLE needs rationale and approver")
        elif r.get("status") not in STATUSES:
            problems.append(f"{k}: status must be one of {sorted(STATUSES)}")
        elif r["status"] == "Implemented" and not r.get("evidence"):
            problems.append(f"{k}: Implemented needs evidence")
    if profile.get("protocol_v1_2_definitions_implemented"):
        problems.append("Appendix may not declare Protocol v1.2 definitions without qualified support")
    return problems


def check_tasks(tasks: dict) -> list[str]:
    ids = [t["id"] for t in tasks["tasks"]]
    problems = []
    if len(ids) != 43 or len(set(ids)) != 43:
        problems.append(f"task register must hold 43 unique tasks, has {len(ids)}")
    for t in tasks["tasks"]:
        if t["class"] != "implemented" and not t.get("external_dependency") and t["class"] != "deferred":
            problems.append(f"{t['id']}: non-implemented task needs an external_dependency")
    return problems


def check_claims(reg: dict) -> list[str]:
    problems = []
    tiers = set(reg["allowed_tiers"])
    ids = [c["id"] for c in reg["claims"]]
    if len(ids) != len(set(ids)):
        problems.append("duplicate claim ids")
    for c in reg["claims"]:
        if c["tier"] not in tiers:
            problems.append(f"{c['id']}: invalid tier")
        if not (APP / c["source"]).exists():
            problems.append(f"{c['id']}: source {c['source']} missing")
        if c["tier"] != "unclassified" and not c.get("registered_claim"):
            problems.append(f"{c['id']}: classified claim must cite a registered CLM")
    return problems


def check_compat(comp: dict) -> list[str]:
    problems = []
    project = (ROOT / "APGI-Appendix.xcodeproj/project.pbxproj").read_text()
    versions = set(re.findall(r"MARKETING_VERSION = ([\d.]+);", project))
    builds = set(re.findall(r"CURRENT_PROJECT_VERSION = (\d+);", project))
    if versions != {comp["app"]["pbxproj_marketing_version"]} or comp["app"]["version"] not in versions:
        problems.append(f"app version {comp['app']['version']} != project {sorted(versions)}")
    if builds != {comp["app"]["pbxproj_build"]}:
        problems.append(f"app build != project {sorted(builds)}")
    pack = json.loads((APP / "reference-pack.json").read_text())
    if comp["reference_pack"] != pack["version"]:
        problems.append("reference_pack differs from reference-pack.json")
    gate = json.loads((APP / "gate-table.json").read_text())
    if comp["gate_table"] != gate["version"]:
        problems.append("gate_table differs from gate-table.json")
    if comp["supported_combinations"] and not comp["schemas"]["pinned_hashes"]:
        problems.append("supported combinations require pinned schema hashes")
    return problems


def check_expansion() -> list[str]:
    problems = []
    tracked = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
    for rel in tracked:
        if rel.startswith("scripts/") or not rel.endswith((".md", ".json", ".cff", ".swift", ".plist", ".yml")):
            continue
        text = (ROOT / rel).read_text(errors="ignore")
        problems += [f"{rel}: non-canonical expansion {bad!r}" for bad in BAD_EXPANSIONS if bad in text]
    cff = (ROOT / "CITATION.cff").read_text()
    if "Allostatic Precision-Gated Ignition" not in cff:
        problems.append("CITATION.cff must use the canonical expansion")
    return problems


def check_all() -> list[str]:
    return (
        check_provenance(_load("default-parameter-provenance.json"), constants_in_source())
        + check_profile(_load("application-validation-profile.json"))
        + check_tasks(_load("task-register.json"))
        + check_claims(_load("claim-register.json"))
        + check_compat(_load("release-compatibility.json"))
        + check_expansion()
    )


def main() -> int:
    problems = check_all()
    for p in problems:
        print("FAIL:", p)
    if not problems:
        print("Validation-artifact checks passed (profile, provenance, claims, compatibility, tasks, expansion).")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
