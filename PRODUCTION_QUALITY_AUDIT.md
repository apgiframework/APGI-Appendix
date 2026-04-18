# APGI Appendix macOS App Audit

## Bugs

1. **Build/test pipeline currently blocked by toolchain mismatch**  
   - `swift test` fails due to `.swift-version` requiring 5.0 while matching toolchain is unavailable in the environment. This prevents CI confidence and regression detection.  
   - Impact: No reliable verification gate before release.

2. **“Clear All Bookmarks” uses wrong persistence key and ineffective signaling**  
   - Settings clears `bookmarkedTabs`, but bookmark persistence uses `APGIBookmarks`. The clear action does not target the active storage key.  
   - A `clearAllBookmarks` notification is posted, but there is no observer implementing actual clearing.
   - Impact: user expects destructive action to work; data appears to “come back” or not clear.

3. **Command menu actions are published but not consumed (unimplemented behavior)**  
   - `copyCitation`, `toggleAllSections`, and `scrollToTables` notifications are emitted but no handlers are registered in app views.  
   - Impact: menu/context actions appear available yet do nothing.

4. **Help shortcut documentation mismatch**  
   - In-app help text advertises `⌘B` bookmark and `⌘1-9` tab navigation, but command registrations differ and no bookmark shortcut is implemented in commands.  
   - Impact: keyboard-centric users encounter broken discoverability and perceived defects.

5. **Bookmark state ownership is fragmented**  
   - Multiple independent `BookmarkManager` instances are created (`shared`, local `@StateObject`, local settings list object), increasing desync risk for list updates and UI state.

6. **Network monitor lifecycle may become non-recoverable after cancel**  
   - `NWPathMonitor` is canceled in `stopMonitoring` but reused later; in Apple APIs, canceled monitors are generally not restartable.  
   - Impact: diagnostics/status refresh reliability issues.

7. **Window/help creation patterns risk unmanaged windows and duplicated windows**  
   - Multiple ad-hoc `NSWindow` allocations for Help/What’s New/Quick Start without centralized lifecycle management.

8. **Hardcoded version defaults in update UI before bundle injection**  
   - `currentVersion` starts as `1.0.0` and is later overwritten; can lead to transient display inaccuracies.

9. **Settings information architecture is crowded and non-standard for macOS**  
   - Large multi-tab settings with mixed diagnostics and user options in one hierarchy increases cognitive load.  
   - “Validation” and “Logs” in the main settings tabs are power-user features better grouped under advanced/diagnostics.

10. **Help delivery is inconsistent (web-first fallback) and not integrated into in-app Help view**  

- App commands open remote help URL first; local help exists but feels fallback-only and disconnected from dedicated `HelpView` structure.

1. **Potential accessibility over-constraining**  

- `enhancedAccessibility` forces `.dynamicTypeSize(.accessibility5)` broadly, which can break layouts and does not reflect user-selected size behavior.

1. **Context menu affordances expose actions with no result**  

- “Expand/Collapse All” and “Go to Tables” are visible in sidebar context menus but may not execute due to missing listeners.

1. **Visual consistency risks in custom control styling**  

- Several custom components mix bespoke styling with native controls; verify against macOS HIG for spacing/focus rings/contrast in dark mode.

1. **No reproducible automated performance regression checks**  

- Monitoring utilities exist, but no benchmark/test suite is wired to gate performance regressions.

1. **Performance monitor data races are possible**  

- Metrics arrays are mutated on background queue but read from computed properties without synchronization.

1. **Memory monitor approximates “available memory” from process resident size**  

- This is process-centric and may be misleading as a system-memory indicator.

1. **Heavy/long-running managers auto-started on app launch**  

- Spotlight indexing + memory monitoring starts on appear; should be profiled for launch-time impact.

1. **No explicit “Reset all app data/preferences” and granular data management**  
   - Current reset focuses on theme/bookmark behavior but lacks holistic privacy/data reset flows.

2. **No explicit preference for automatic update checks cadence and opt-out granularity**

3. **Update download URL is opened without strict domain allow-list validation at decision point**  
   - Update metadata can supply arbitrary `downloadURL`; app opens it directly if present.
   - Impact: phishing / malicious redirection risk if endpoint compromised.

4. **URL trust model likely misconfigured for GitHub namespace**  
   - Trusted domains include `github.com/apgi` as a host entry, but host matching compares hostnames, not path namespaces. This can unintentionally reject valid URLs or create policy confusion.

5. **Some network calls use permissive runtime behavior without certificate pinning or signature verification for update metadata**

6. **Error logging may include sensitive operational details**  
   - Logging strategy is broad; ensure redaction policies and user-facing consent/retention settings are explicit.

7. **Server receipt validation flow still includes legacy shared-secret style approach**  
   - Should be reviewed for current StoreKit 2 best-practice alignment and secret management hardening.

8. **User documentation over-promises currently wired behavior**  
   - Several shortcuts and interactions described in help/README are not fully mapped to executable handlers.

9. **In-app help discoverability and consistency need consolidation**  
   - Multiple help paths (command override, URL validator fallback, local markdown) increase inconsistency.

10. **Limited inline guidance for advanced settings and diagnostics**  

- Logs/validation/network diagnostics require clearer “why/when to use” tooltips and consequences.

1. **No visible release-quality “Known Issues” / troubleshooting matrix**

## Prioritized defect list (Severity + Priority)

1. **[Critical | P0] Harden update download trust path**: validate `downloadURL` against strict allow-list and signed metadata before opening.  
2. **[Critical | P0] Restore executable verification pipeline**: align Swift toolchain and ensure tests/build run in CI.  
3. **[High | P1] Fix bookmark clearing bug**: unify storage key usage and implement actual clear observer/state updates.  
4. **[High | P1] Implement missing notification handlers**: `copyCitation`, `toggleAllSections`, `scrollToTables`.  
5. **[High | P1] Reconcile documented shortcuts with implemented command map**.  
6. **[High | P1] Add settings for updates/sync/logging privacy controls**.  
7. **[Medium | P2] Remove forced `.accessibility5` and honor user dynamic type settings**.  
8. **[Medium | P2] Make performance metrics thread-safe and add repeatable perf tests**.  
9. **[Medium | P2] Improve window lifecycle management for auxiliary windows**.  
10. **[Low | P3] Refine docs/help clarity, tooltips, and known-issues content**.

- Enforce domain allow-list + signature verification for update metadata and artifact URLs.
- Add rollback-safe update policy (critical update handling, blocked unknown channels).
- Add security tests for URL validation and malicious update payload simulation.
- Fix bookmark clear flow (`APGIBookmarks`), unify bookmark state to one source of truth.
- Implement missing notification consumers or remove unavailable menu items.
- Add integration tests for every command menu action.

### C. UX/HIG alignment pass

- Reorganize Settings: General, Appearance, Data & Privacy, Advanced/Diagnostics.
- Unify Help entry points to one canonical in-app help center with offline-first rendering and optional external links.
- Run accessibility audit with VoiceOver keyboard traversal and table semantics validation.

### D. Performance/stability hardening

- Make metrics storage actor-based or lock-protected.
- Add launch-time profiling budgets and memory stress tests.
- Introduce CI job for unit tests + smoke tests + lightweight perf assertions.

### E. Documentation and release readiness

- Reconcile README/help with actual shipped behaviors (shortcuts, features, limits).
- Add user-visible changelog and troubleshooting section with exact error recovery steps.
- Add QA release checklist with sign-off gates for security, accessibility, and regression tests.

---

## Final assessment

The project has a solid base and thoughtful architecture, but **production readiness requires a focused hardening cycle** around command wiring, settings coherence, update security, and verification automation. Addressing the P0/P1 items above would likely raise the app into the **80s** quickly; completing the UX/accessibility/performance/docs pass should bring it into the **90+ exceptional range**.
