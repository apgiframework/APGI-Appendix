#!/usr/bin/env python3
"""Release checks for identifier, privacy, and evidence boundaries."""
import hashlib
import json
import plistlib
from pathlib import Path

root = Path(__file__).resolve().parents[1]
app = root / 'APGI-Appendix'
for path in app.glob('*.swift'):
    source = path.read_text()
    for retired in ('api.apgi-framework.org', 'docs.apgi-framework.org',
                    'apgi-framework.com', 'raw.githubusercontent.com/apgi/framework',
                    'Adaptive Predictive Gamma Integration', 'Adaptive Precision-Gated Ignition'):
        assert retired not in source, (path.name, retired)
entitlements = plistlib.loads((app / 'APGI-Appendix.entitlements').read_bytes())
assert set(entitlements) == {
    'com.apple.security.app-sandbox', 'com.apple.security.network.client',
    'com.apple.security.files.user-selected.read-write', 'com.apple.security.print'
}
assert all(entitlements.values())
privacy = plistlib.loads((app / 'PrivacyInfo.xcprivacy').read_bytes())
assert privacy['NSPrivacyTracking'] is False
assert privacy['NSPrivacyCollectedDataTypes'] == []
assert 'privateCloudDatabase' in (app / 'CloudKitManager.swift').read_text()
assert 'publicCloudDatabase' not in (app / 'CloudKitManager.swift').read_text()
project = (root / 'APGI-Appendix.xcodeproj/project.pbxproj').read_text()
assert 'CODE_SIGN_ENTITLEMENTS = "APGI-Appendix/APGI-Appendix.entitlements";' in project
assert 'ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES;' in project
matrix = json.loads((root / 'contracts/model-compatibility.json').read_text())
assert matrix['model_family'] == 'apgi_extended'
assert matrix['data_origin'] == 'synthetic'
import sys
sys.path.insert(0, str(root / 'scripts'))
import check_local_evidence
evidence_problems = check_local_evidence.check_fixtures() + check_local_evidence.check_gate_table()
assert not evidence_problems, evidence_problems
assert 'Treatment Implication' not in (app / 'PsychiatricDisordersView.swift').read_text()
print('Appendix identifier, entitlement, privacy, and evidence checks passed.')

pack = json.loads((app / "reference-pack.json").read_text())
assert pack["evidence_status"] == "illustrative"
for filename, digest in pack["sources"].items():
    assert hashlib.sha256((app / filename).read_bytes()).hexdigest() == digest, filename
print("Versioned reference pack hashes passed.")
