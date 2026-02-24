#### BUG-011 — `URLSession` force-unwrap crash risk in `testConnection()`
**Severity:** Medium
**File:** `NetworkManager.swift:233`
**Component:** Network diagnostics

```swift
URLSession.shared.dataTask(with: URL(string: "https://api.apgi-framework.org")!) { ... }
```

Force-unwrapping the URL is safe *now* but will crash if the string is ever changed to a malformed value. Additionally, the `NSAlert.runModal()` calls inside an async callback block the main thread.

**Fix:** Use `guard let url = URL(string: "https://api.apgi-framework.org") else { return }` and replace `NSAlert.runModal()` with SwiftUI alert state.


#### BUG-012 — `NavigationSection.reference` contains `.navigation`-category tabs
**Severity:** Medium
**File:** `TabTypes.swift:209–213`
**Component:** Navigation data model

```swift
case .reference:
    return [.glossary, .bibliography, .epistemicStandards,
            .thermodynamicEfficiency, .ignitionTimeline, .apgiSimulator]
```

`.ignitionTimeline` and `.apgiSimulator` have `category == .navigation` (Demonstrations), yet they are listed under the Reference navigation section. Combined with BUG-001, this produces cascading wrong tab lists.


#### BUG-013 — Search debounce `Timer` not invalidated on view disappear
**Severity:** Medium
**File:** `SearchView.swift:83–85`
**Component:** Search

`Timer.scheduledTimer` is stored in `@State private var debounceTimer`. If the view is dismissed while the timer is pending, the timer fires and attempts to call `performSearch()` on a deallocated context.

**Fix:** Add `.onDisappear { self.debounceTimer?.invalidate(); self.searchTask?.cancel() }`.


#### BUG-014 — `UserDefaults.standard.synchronize()` deprecated no-op called in 3 locations
**Severity:** Medium
**Files:** `ThemeManager.swift:38, 111`, `NetworkManager.swift` (implicit via AppStorage)
**Component:** Settings persistence

`UserDefaults.synchronize()` has been a no-op since macOS 10.12 and is flagged by the compiler. Remove all calls.


#### BUG-015 — `checkForUpdates()` is an empty stub
**Severity:** Medium
**File:** `MainContentView.swift:429–431`
**Component:** Update management

```swift
private func checkForUpdates() {
    print("Checking for updates...")
}
```

No update check mechanism is implemented despite the command being exposed in the Help menu. Users receive no feedback.


#### BUG-016 — Help and Settings buttons in `SidebarView` have empty closures
**Severity:** Medium
**File:** `SidebarView.swift:70–83`

```swift
Button(action: { }) { Label("Settings", systemImage: "gear") }
Button(action: { }) { Label("Help", systemImage: "questionmark.circle") }
```

Both bottom-bar buttons do nothing. If `SidebarView` is eventually activated (BUG-005 fix), these will be silent.


### LOW


#### BUG-017 — `APGISpacing` and `APGIRadius` have duplicate aliased constants
**Severity:** Low
**File:** `APGIColors.swift:61–92`
Both enums define `small/medium/large/extraLarge` AND `xs/sm/md/lg` pointing to identical values, creating naming confusion with no semantic distinction.


#### BUG-018 — `Optional.isNil` extension defined but never used
**Severity:** Low
**File:** `SettingsView.swift:4–8`
Dead code; Swift already provides `== nil` for this purpose.


#### BUG-019 — Onboarding promises features that do not exist
**Severity:** Low
**File:** `OnboardingTour.swift:186`
The final onboarding step states "Drag and drop to reorganize" and "Right-click for context menus". Neither feature is implemented anywhere in the current codebase.


#### BUG-020 — Screenshot auth token hardcoded in documentation
**Severity:** Low
**File:** `README.md:626`
```bash
export SCREENSHOT_AUTH_TOKEN=APGI-Screenshot-2024
```
Hardcoded credentials in public documentation should be replaced with a placeholder and the actual token managed via environment secrets.







## Missing Features

| ID | Feature | Priority | Notes |
|----|---------|----------|-------|
| MF-001 | **Full section content** | Critical | `Tab.content` returns search snippets. Actual rich text/markdown content must be bundled or fetched for each of the 23 tabs. |
| MF-002 | **Functional PDF export** | Critical | `exportCurrentViewToPDF` is a stub. Required for academic/clinical use. |
| MF-003 | **StoreKit 2 integration** | High | No in-app purchase, subscription, or one-time-purchase flow. Required for App Store monetisation. |
| MF-004 | **Update mechanism** | High | `checkForUpdates()` prints to console. Needs Sparkle (direct) or MAS version checking. |
| MF-005 | **Deep link URL scheme registration** | High | `apgi-appendix://` is constructed in code (`createDeepLinkURL`) but `CFBundleURLTypes` is absent from Info.plist. Deep links and Handoff webpage URLs will silently fail. |
| MF-006 | **Spotlight / CoreSpotlight indexing** | High | No `CSSearchableItem` donation. Content is not discoverable via macOS Spotlight. |
| MF-007 | **Context menus** | Medium | Promised in onboarding; absent throughout. Sections and bookmarks should expose contextual actions. |
| MF-008 | **Print support** | Medium | `com.apple.security.print` entitlement present but no `NSPrintOperation` or print menu item implemented. |
| MF-009 | **iCloud / CloudKit sync** | Medium | Settings and bookmarks persist only locally via UserDefaults/Keychain. No cross-device sync. |
| MF-010 | **Dynamic Type / `@ScaledMetric`** | Medium | Font sizes are fixed points. App should honour system accessibility text-size preferences using `@ScaledMetric` or `Font.custom(_:relativeTo:)`. |
| MF-012 | **Continuity Camera / Universal Clipboard** | Low | Continuity features declared in onboarding conceptually but not implemented. |
| MF-013 | **VoiceOver full audit** | Low | `apgiAccessibility` modifier applied to toolbar buttons only; most list items, cards, and simulator controls have no accessibility labels. |
| MF-014 | **Keyboard focus ring in split view** | Low | No explicit `focusable()` / `FocusState` management beyond `Cmd+F` shortcut. Full keyboard-only navigation is incomplete. |
| MF-015 | **Drag-and-drop bookmark reordering** | Low | Onboarding promises this; `BookmarkManager.bookmarks: [String]` supports ordering but no drag gesture is wired. |

