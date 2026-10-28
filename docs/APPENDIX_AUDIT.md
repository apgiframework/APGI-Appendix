# Appendix audit — October 27, 2026

Scope: supplied 43-row Appendix register; changes made in APGI-Appendix.
Explorer already uses the requested host and was not modified.

## Completed repository changes

- S0-IDN-11/12: retired APGI domains removed from app source, help, download links,
  clipboard URLs and update feed. Canonical expansion is Allostatic Precision-Gated
  Ignition. About renders website, API and repository identifiers.
- API: ephemeral, timeout-bounded public metadata GET at launch and in Settings;
  HTTP and malformed-response errors are visible. Redirects outside the exact
  HTTPS API host are rejected. No user data is in the request.
- S1-CMP-01.3: compatibility matrix identifies the simulator as `apgi_extended`;
  sigmoid alpha maps to `gamma_sig`; marker-weighted precision equivalence is
  explicitly unqualified. Broadcast and maintenance costs are thermodynamic.
- S1-LNG-05: removed psychiatric treatment/biomarker recommendation tables;
  numeric disorder examples are explicitly illustrative, synthetic and nonclinical.
- S1-APP-01: removed unused entitlement keys and connected the audited file to
  both build configurations. Outbound network capability is actually enabled.
  File selection and printing remain because the app uses export/print paths.
  Privacy manifest no longer declares nonexistent analytics/diagnostic collection.
- Updates: only `https://api.apgiframework.com/updates.json` is attempted; no GitHub
  fallback. HTTPS, exact download hosts, port and credential restrictions apply.
  Canonical JSON uses sorted keys. Unsupported algorithms, missing signatures,
  and unknown keys fail closed. Removed the undocumented embedded key; no
  production trust key is configured. Failed checks do not establish currentness.
- S1-APP-04: sigmoid labels use `gamma_sig`; unrelated receptor, cost, and learning
  alpha symbols retain their separate meanings.
- S1-APP-05: Xcode project and shared scheme are no longer ignored by Git; CI
  runs contract checks and macOS tests. Fixed three Swift 6 shape-isolation errors.
- S1-APP-06: bundled `reference-pack.json` versions and hashes reference sources;
  content cards and simulator display evidence labels. Diagnostic serialization
  includes `data_origin`, `evidence_status`, and `content_pack_version`.
- S1-APP-07: existing bookmark CloudKit paths use `privateCloudDatabase`; no
  bookmark path targets APGI. CloudKit provisioning was not added or verified.
- S1-APP-03 / XC-CI-09.2: gate view renders a bundled, explicitly pending table
  and fails to an unavailable state. It distinguishes dynamic θₜ from baseline θ₀.
  This provisional JSON table is not represented as a published gate-table.yaml.
- S3-PR6-07/08 / XC-CI-09.1: bundled local regression vectors exercise negative,
  zero, and positive ignition margins with an explicit tolerance. These are local
  smoke tests, not the missing qualified framework parity suite.

## Remaining dependencies — not claimed complete

1. The deployed `/v1/meta` returned HTTP 500. `/v1/version` and `/updates.json`
   returned HTTP 401 without credentials. The public OpenAPI document contains
   no Appendix signed-update, fixture, gate-table, or client-diagnostics route.
   Fix metadata service availability and publish an authenticated/anonymous
   contract appropriate to public reference clients before claiming a healthy API.
2. Supply qualified `mathematical-contracts.yaml`, `parameter-registry.yaml`,
   reference fixtures and registered tolerances. They were not found in the local
   framework checkout. Full simulator parity and precision transformation
   equivalence remain unverified (S1-APP-02 and S1-CMP-01.3.2).
3. Publish K7a/K7c outcomes and the authoritative gate table, including D2, before
   replacing provisional pending gate rows (S1-APP-03).
4. Publish the signed Appendix feed and provide an independently reviewed public
   signing key and canonicalization contract. Do not enable unsigned updates.
5. D13 and `/v1/client-diagnostics` remain undecided/unavailable. No diagnostics
   upload or usage analytics was introduced (S2-DEC-03).
6. iCloud container entitlement/provisioning and multi-device behavior require
   account configuration and a signed integration test. Current bookmarks are
   stored locally; existing optional cloud code has no APGI destination.
7. Required branch-protection checks must be configured in repository hosting.
   Adding workflow files does not configure protection or prove a hosted CI run.

## Verification

`python3 scripts/check_appendix_contracts.py` checks retired identifiers, exact
entitlements, privacy declarations, reference hashes, and private CloudKit use.
Native XCTest covers existing parser/deep links plus URL policy, fail-closed
updates, pending-gate rendering, fixture loading/sign, and metadata response errors.
Live API checks above were performed against the requested host, without credentials.
No deployment, signing, App Store release, or visual QA pass is claimed.

Final local result: **17 XCTest tests passed, zero failures**, with Xcode 27.1.
The build now consumes the app's Info.plist, with a test confirming the
`apgi-appendix` URL scheme and reference pack are present in the built bundle.
Contract checks and `git diff --check` also passed.
Result bundle: `/tmp/APGI-Appendix-verified/Logs/Test/Test-APGI-Appendix-2026.10.27_21-04-49--0400.xcresult`.
