# Contract dependencies and release status

What the repository can and cannot claim today. "Done in repo" means source, checks and
tests exist; "Blocked" means an input outside this repository is required. Nothing here
claims scientific parity, signed distribution or release readiness.

| Item | Rows | State | Needed to close |
|---|---|---|---|
| Simulator parity | S1-APP-02/.1/.2, S3-PR6-07/08, XC-CI-09.1 | Blocked | Qualified `mathematical-contracts.yaml`, `parameter-registry.yaml`, framework fixtures and registered tolerances. None exist in any `apgiframework` repository searched (framework, implementation, validation, system, research, api). `APGISimulatorConstants.swift` stays local; the three sigmoid vectors are local regression only. |
| Model mapping | S1-CMP-01.3/.3.2 | Done as far as possible | `contracts/model-compatibility.json` keeps `apgi_extended`. Re-map to `pi_i_rel_eff` only after the marker-weighted Πᵢ transformation is qualified against the registry. |
| Gate table | S1-APP-03, XC-CI-09.2 | Tooling done; data blocked | Published `gate-table.yaml` (K7a/K7c outcomes, D2 decision; dependencies S1-REG-04, S1-K7-06, S1-K7-12, S1-DEC-02). Then run `python3 scripts/generate_gate_table.py path/to/gate-table.yaml`, refresh `reference-pack.json` hashes, commit. The view already renders results, the D2 decision, and keeps dynamic θₜ distinct from baseline θ₀. |
| Signed updates | S1-APP-01.3 | Contract done; key blocked | See [UPDATE_FEED_CONTRACT.md](UPDATE_FEED_CONTRACT.md). Needs a reviewed production public key in `UpdateSignatureVerifier.productionPublicKeys`, the private key in the API's secret store, and a published release. |
| iCloud | S1-APP-07 | Blocked | iCloud container, entitlements and provisioning on a signed build, then bookmark sync verified across two signed devices. The entitlement check deliberately forbids iCloud keys until then. |
| Hosted gate enforcement | XC-CI-09 | Blocked (settings) | Protected-branch settings, below. |
| Documentation | — | Done | README states macOS-only, macOS 26.3, local bookmarks. |
| Release validation | — | Blocked | Signed/notarised distribution, provisioning and visual QA. Not claimed. |
| Explorer research mode | — | API side exists | `apgi-api` serves the pinned item bank, four consent purposes, idempotent journal acknowledgements and the upload endpoint (`/v1/explorer/*`, `/v1/instruments/apgi-explorer-35`). Client behaviour belongs to APGI-Explorer, not this Appendix. |

## Required checks on `main`

Repository settings cannot be changed by a commit. A repository admin should run:

```sh
gh api -X PUT repos/apgiframework/APGI-Appendix/branches/main/protection --input - <<'JSON'
{"required_status_checks":{"strict":true,"contexts":["contracts","macos-tests"]},
 "enforce_admins":true,"required_pull_request_reviews":{"required_approving_review_count":1},
 "restrictions":null}
JSON
```

then confirm with `gh api repos/apgiframework/APGI-Appendix/branches/main/protection`.
Replace the smoke-level parity step with the qualified suite once those fixtures land.
