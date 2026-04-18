# APGI Appendix macOS Quality Evaluation (Static Code Audit)

Date: 2026-04-18  
Scope: Repository-level static audit of SwiftUI macOS app sources in `APGI-Appendix/` and accompanying docs (`README.md`, `TODO.md`).

## Executive Summary

The app demonstrates strong architectural ambition and broad feature surface, but it currently contains several high-impact implementation gaps and behavior mismatches between documentation and actual behavior. The most serious concerns are:

1. **Crash-prone `fatalError` paths in production code** for recoverable runtime conditions.
2. **Feature parity drift** where advertised capabilities are present in docs but incomplete/no-op in code.
3. **Settings persistence and wiring inconsistencies** (stored values not applied or not persisted predictably).
4. **Security/privacy hardening gaps** around URL validation, purchase trust model, and broad diagnostic data statements.

Overall, the app appears **functional but flawed**, with meaningful risk under stress and in edge cases.

## Health Score

**Score: 67 / 100**

Rationale:
- **-15**: Crash and robustness risk from multiple `fatalError` sites in app paths.
- **-8**: Broken command/deep-link behaviors impacting core navigation/workflow.
- **-5**: Simulated update checking and incomplete implementation of publicly surfaced capability.
- **-3**: Settings behavior inconsistencies (e.g., persistence/wiring drift).
- **-2**: Security model weaknesses (regex URL validation + local purchase trust fallback).

## Severity and Priority Rubric Used

- **Critical (P0/P1):** crashes, data loss, or exploitable vulnerabilities.
- **High (P1/P2):** broken core functionality or major reliability/UX breakage.
- **Medium (P2/P3):** non-blocking functional defects, settings/UX issues, moderate compliance gaps.
- **Low (P3/P4):** cosmetic issues, microcopy/docs drift, minor polish items.

## Prioritized Findings

### 1) Critical / P0 — Crash-prone `fatalError` in runtime paths
- `fatalError` is used for recoverable conditions (filesystem access failures, engine fallback failure, dimension mismatches). In release builds this can terminate the app instead of graceful degradation.
- Affected code includes content caching, logging setup, simulator initialization, and math utility paths.

**Impact:** Unexpected app termination and potential data loss risk for unsaved state.

### 2) High / P1 — Deep-link parsing mismatch breaks link routing
- `createDeepLinkURL(for:)` encodes query item `section=...`, but `handleDeepLink(_:)` reads `tab=...`.
- This causes valid internal deep links to fail silently.

**Impact:** Handoff/deep-link workflows are unreliable.

### 3) High / P1 — Command menu action posted but not consumed (`Toggle Inspector`)
- `.toggleInspector` notification is posted from commands but no receiver is registered in `MainContentView`.

**Impact:** Keyboard/menu control appears available but does nothing.

### 4) High / P1 — Update checking is simulated, not implemented
- `UpdateCheckView` waits 2 seconds and always reports “up to date” with comments indicating placeholder behavior.

**Impact:** Users cannot trust update status; operational risk for stale versions/security fixes.

### 5) High / P2 — Purchase entitlement trust model relies on UserDefaults persistence
- Purchased IDs are persisted in `UserDefaults` and used for entitlement checks.
- Although StoreKit verification exists for active transactions, relying on mutable local storage without periodic authoritative validation increases tampering risk.

**Impact:** Potential unauthorized premium feature unlock in compromised environments.

### 6) Medium / P2 — Settings state drift: sidebar/focus settings are not consistently wired to actual visibility behavior
- “Show Sidebar by Default” writes a setting, but visibility in `MainContentView` is primarily managed through `NavigationSplitViewVisibility` state and notifications; there is no default bootstrap from that setting.

**Impact:** User expectation mismatch and perceived “settings not working.”

### 7) Medium / P2 — High contrast persistence path is inconsistent
- `highContrastMode` uses `@Published` rather than `@AppStorage`, and persistence depends on explicit saves/events.

**Impact:** Risk of user setting not persisting as expected in all lifecycle scenarios.

### 8) Medium / P2 — URL validation is permissive regex-based and not trust-based
- URL opening safety is primarily regex format validation rather than domain allow-listing, TLS policy checks, or active trust evaluation.

**Impact:** Increased phishing/open-redirect style exposure if URL sources become dynamic.

### 9) Medium / P3 — Settings panel breadth is narrower than documented capability claims
- README advertises broad settings (e.g., color customization, richer network controls/diagnostics patterns), while implementation offers a subset and several controls are shallow/no back-end effect.

**Impact:** Feature completeness gap; user trust erosion.

### 10) Medium / P3 — Help/documentation duplication and inconsistency
- Multiple embedded help content sources exist (`URLValidator` local help + `HelpView` local help + README), with inconsistent shortcut lists and phrasing.

**Impact:** Users receive conflicting guidance; maintenance overhead.

### 11) Medium / P3 — Cloud sync controls are partially implemented and weakly surfaced
- `enableSync()` only sets UI status text; subscription mechanism is noted as unimplemented.

**Impact:** Users may believe sync is active when underlying behavior is incomplete.

### 12) Low / P4 — UI copy and discoverability inconsistencies
- Mixed terminology (“APGI”, “APGI Framework”, “APGI Appendix”), overlapping help entry points, and some menu duplication can reduce clarity.

**Impact:** Minor friction and polish deficit.

## Six-Dimension Assessment

### A) Functional Bugs
- **Major issues present** (crash paths, deep-link mismatch, dead command actions, simulated update checks).
- Severity distribution: 1 Critical, 4 High, 4 Medium.

### B) UI/UX Issues
- Good baseline SwiftUI composition, but several controls/commands are non-functional or partially wired.
- Help/shortcut guidance is fragmented and inconsistent.

### C) Performance & Stability
- Presence of hard crash triggers and several fallback comments indicates incomplete resilience strategy.
- No benchmark evidence or stress-test artifacts found in repo.

### D) Missing Settings & Features
- Documented features exceed implemented robustness in update, sync, and certain settings behaviors.
- `TODO.md` confirms non-started platform extensions and receipt validation.

### E) Security & Privacy
- Positive: keychain encryption helper exists.
- Gaps: permissive URL validation approach, local entitlement trust fallback, and privacy declarations should be continuously aligned with actual data flows.

### F) Documentation & Help
- Extensive README exists, but in-app help sources are duplicated and diverge over time.
- Missing a single source-of-truth pipeline for help/shortcuts.

## Recommendations to Reach 90–100

1. **Eliminate production `fatalError` from user-facing runtime paths (P0).** Replace with recoverable error states, user-facing alerts, telemetry, and retry paths.
2. **Fix deep-link contract mismatch immediately (P1).** Standardize query schema and add unit tests for routing.
3. **Wire every command to a verified receiver (P1).** Add integration checks for command notifications.
4. **Implement real update service (P1).** Signed endpoint, semantic version compare, release notes, retry/backoff, and offline messaging.
5. **Harden entitlement model (P1).** Validate active entitlements via StoreKit transaction history and minimize trust in mutable local stores.
6. **Normalize settings architecture (P2).** Prefer `@AppStorage` + deterministic app startup application of settings (sidebar, contrast, focus).
7. **Harden URL safety (P2).** Add allow-list + HTTPS-only external destinations and user confirmation for unknown domains.
8. **Consolidate help docs (P2).** Generate in-app help from one canonical markdown source; verify shortcuts via automated checks.
9. **Close explicit TODO platform gaps (P3).** Prioritize receipt validation first from the TODO list.
10. **Add QA automation (P2).** UI smoke tests for: launch, settings persistence, search, export, deep-link, command handling, update check, and cloud sync status.

## Suggested Remediation Sequence (30/60/90 day)

- **0–30 days:** Fix Critical/High issues (#1–#5), ship hotfix.
- **31–60 days:** Settings/UX consistency + help consolidation + URL hardening.
- **61–90 days:** Platform extensions and non-blocking roadmap features from TODO.

