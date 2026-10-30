#!/usr/bin/env python3
"""Generate APGI-Appendix/gate-table.json from the authoritative gate-table.yaml.

Usage: generate_gate_table.py PATH/TO/gate-table.yaml [--check]

Expected YAML (the published framework table; see docs/CONTRACT_DEPENDENCIES.md):

    version: "<table version>"
    d2_decision: "<D2 model-home decision, as published>"
    gates:
      - {id: K7a, status: PASS|FAIL|INCONCLUSIVE, description: "...", result: "..."}
      - {id: K7c, status: ..., description: "...", result: "..."}

Pending rows are rejected: the bundled table is only replaced by published outcomes.
Refuses to run without the file; nothing is invented. With --check the output is
compared with the committed JSON instead of written.
"""
import hashlib
import json
import sys
from pathlib import Path

import yaml

OUT = Path(__file__).resolve().parents[1] / "APGI-Appendix" / "gate-table.json"
PUBLISHED_STATUSES = {"PASS", "FAIL", "INCONCLUSIVE"}


def convert(raw: bytes) -> dict:
    doc = yaml.safe_load(raw)
    gates = {g["id"]: g for g in doc.get("gates", [])}
    if set(gates) != {"K7a", "K7c"}:
        raise ValueError("gate-table.yaml must define exactly K7a and K7c")
    for gid, g in gates.items():
        if g.get("status") not in PUBLISHED_STATUSES:
            raise ValueError(f"{gid}: status must be one of {sorted(PUBLISHED_STATUSES)}")
        for field in ("description", "result"):
            if not str(g.get(field, "")).strip():
                raise ValueError(f"{gid}: missing {field}")
    if not str(doc.get("d2_decision", "")).strip():
        raise ValueError("gate-table.yaml must record the D2 decision")
    return {
        "version": str(doc["version"]),
        "evidenceStatus": "published",
        "source": "gate-table.yaml",
        "sourceSha256": hashlib.sha256(raw).hexdigest(),
        "d2Decision": str(doc["d2_decision"]).strip(),
        "gates": [
            {k: str(gates[i][k]).strip() for k in ("id", "status", "description", "result")}
            for i in ("K7a", "K7c")
        ],
    }


def main(argv: list) -> int:
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 1:
        print(__doc__)
        return 2
    table = convert(Path(args[0]).read_bytes())
    text = json.dumps(table, indent=2, ensure_ascii=False) + "\n"
    if "--check" in argv:
        if OUT.read_text() != text:
            print("gate-table.json drifted from gate-table.yaml")
            return 1
        return 0
    OUT.write_text(text)
    print(f"wrote {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
