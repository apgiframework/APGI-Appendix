# APGI Appendix — macOS Lead Architect Assessment Report

**Date:** 2026-02-24
**Assessor Role:** macOS Lead Architect
**Branch:** `claude/macos-roadmap-design-S22lR`
**Target Platform:** macOS 14.0+ (SwiftUI + AppKit Hybrid)
**Codebase Size:** ~76 Swift source files, 23 content tabs, ~8,500 LOC estimated

---

## Executive Summary

APGI Appendix is a reference and learning application for the Adaptive Predictive Gamma Integration (APGI) framework targeting macOS 14+. The app implements a three-panel `NavigationSplitView` layout, an interactive APGI Simulator, Ignition Timeline visualization, global search, onboarding tour, bookmarks, theming, Keychain-backed persistence, and remote content fetching.

The codebase demonstrates solid architectural intent: `@MainActor`-annotated managers, Swift Concurrency for search and simulation, `NSCache`-backed caching layers, App Sandbox + Privacy Manifest + CryptoKit/Keychain security, and a complete `AppError` hierarchy. However, several critical functional gaps — a no-op PDF export, a dead `SidebarView` component, broken `SectionCategory.sections` logic, duplicate command group registrations, and hardcoded surface colors that break dark mode — reduce production readiness materially.

The roadmap below prioritises fixing correctness bugs before adding new surface area, then layers in Apple-platform differentiators (StoreKit 2, Core ML, Continuity, Spotlight) and distribution strategy.

---

## KPI Scores Table

| # | KPI | Score | Rationale |
|---|-----|-------|-----------|
| 1 | **Functional Completeness** | **68 / 100** | All 23 tabs mapped; simulator/timeline functional. PDF export is a stub, update-check is a stub, SidebarView is unwired, `Tab.content` returns search-index snippets instead of full text, Settings/Help buttons in SidebarView have empty action closures. |
| 2 | **UI/UX Consistency** | **71 / 100** | HIG-compliant split-view, SF Symbols throughout, semantic foreground colors mostly correct. `surfacePrimary` is hardcoded `Color(white: 0.98)` (breaks dark mode), two competing sidebar implementations, context menus and drag-and-drop promised by onboarding but absent, toolbar placement not standardised. |
| 3 | **Responsiveness & Performance** | **73 / 100** | `NSCache` with cost/count limits, `LazyVStack`, async/await search with Task cancellation, thermal-state back-pressure, ML inference queue. Timer-based simulation on main run loop (should use `Task.sleep`), `UserDefaults.synchronize()` is deprecated no-op (used in 3 locations), search debounce timer not invalidated on view disappear. |
| 4 | **Error Handling & Resilience** | **67 / 100** | `AppError` enum with recovery suggestions, `ErrorHandler` alert presenter, network graceful degradation, Keychain → UserDefaults migration path. PDF export silently prints to console, `testConnection()` force-unwraps URL, `BookmarkManager.lastAction` reset guard is a tautology (always true), memory-warning handler is unreachable dead code. |
| 5 | **Overall Implementation Quality** | **72 / 100** | Good separation of concerns, Keychain/CryptoKit bookmark security, Privacy Manifest present, correct App Sandbox entitlements, proper `@MainActor` annotation on shared singletons. Duplicate spacing/radius enum aliases, dead `Optional.isNil` extension, two conflicting `CommandGroup(replacing: .help)` registrations, `SectionCategory.sections` logic returns wrong tab set. |

**Composite Score: 70.2 / 100**

---

## Bug Inventory

### CRITICAL

---

#### BUG-001 — `SectionCategory.sections` returns wrong tab set
**Severity:** Critical
**File:** `SectionCategory.swift:39`
**Component:** Category navigation / `NavigationSplitView` content column

**Code:**
```swift
var sections: [Tab] {
    NavigationSection.allCases.first { $0.tabs.contains(where: { $0.category == self }) }?.tabs ?? []
}
```

**Expected:** Return only the tabs whose `.category == self`.
**Actual:** Finds the first `NavigationSection` that contains *any* tab matching the category and returns *all* of that section's tabs — including tabs from other categories.

**Impact:** `NavigationSection.reference` contains `.ignitionTimeline` and `.apgiSimulator` (whose category is `.navigation`). Selecting `SectionCategory.navigation` (Demonstrations) through the `CategorySidebar` → `SectionList` path will show wrong tabs. Cross-category navigation is broken for every category that shares a `NavigationSection` with a tab from a different category.

**Reproduction:**
1. Launch app → select "Demonstrations" in category sidebar.
2. Observe the section list includes Reference-category tabs (Glossary, Bibliography, Epistemic Standards).

**Fix:**
```swift
var sections: [Tab] {
    Tab.allCases.filter { $0.category == self }
}
```

---

#### BUG-002 — PDF Export is a silent stub
**Severity:** Critical
**File:** `MainContentView.swift:388–392`
**Component:** Export system

**Code:**
```swift
private func exportCurrentViewToPDF(url: URL) {
    print("Exporting current view to PDF: \(url)")
}
```

**Expected:** Saves a PDF of the current section to the user-chosen URL.
**Actual:** Prints to console; no file is written; no error or feedback is shown to the user. The save panel succeeds silently.

**Reproduction:**
1. Select any section → Export menu → "Export as PDF…"
2. Choose a save location → Save.
3. No PDF is created; no alert is shown.

**Fix:** Render the content view into an `NSView`/`NSHostingView`, capture with `NSGraphicsContext`, and write to the URL using `NSPrintOperation` or PDFKit's `PDFDocument`.

---

#### BUG-003 — Duplicate `CommandGroup(replacing: .help)` conflict
**Severity:** Critical
**Files:** `APGICommands.swift:147–152`, `APGI_Appendix.swift:36–62`
**Component:** Menu bar commands

**Expected:** A single coherent Help menu registered once.
**Actual:** Both `APGICommands.body` (line 147) and `APGIAppendixApp.body` (line 36) call `CommandGroup(replacing: .help)`. SwiftUI resolves conflicts non-deterministically; one registration shadows the other, and `CommandGroup(after: .help)` (line 154 in APGICommands) adds a third APGI Help entry, resulting in duplicate or missing help menu items.

**Reproduction:**
1. Launch the app → open the Help menu.
2. Observe duplicate "APGI Help Guide" entries or missing "What's New" / "Quick Start Guide".

**Fix:** Consolidate all Help menu modifications into one location; remove the `CommandGroup(replacing: .help)` in `APGICommands` and keep only the version in `APGIAppendixApp`.

---

#### BUG-004 — `Tab.content` returns search-index snippet, not actual content
**Severity:** Critical
**File:** `TabTypes.swift:179–181`
**Component:** Export (text), Focus Mode

**Code:**
```swift
var content: String {
    self.searchIndexText
}
```

**Expected:** `content` should return the full, rich textual content of the section for export and focus-mode display.
**Actual:** Returns the same abbreviated search-index string used for keyword matching (typically 50–200 characters), so text exports and Focus Mode display skeletal keyword fragments, not readable content.

**Reproduction:**
1. Select "Methodology" → Export as Text → open the file.
2. Content is `"Methodology\nThe persistent challenges in the field…"` — a 200-char snippet.

**Fix:** Provide a separate `fullContent: String` property (or load from bundled resource files) and use that for export and focus mode.

---

### HIGH

---

#### BUG-005 — `SidebarView` is never rendered in the main window
**Severity:** High
**File:** `SidebarView.swift`, `MainContentView.swift:127–130`
**Component:** Navigation / Sidebar

`MainContentView` renders `CategorySidebar` (a private struct) as the sidebar column. The standalone `SidebarView.swift` (with expandable `NavigationSection` groups, inline search, and hover effects) is never instantiated anywhere in the app's navigation hierarchy. Its Settings and Help buttons also have empty action closures.

**Impact:** `~268 lines` of navigation UX work is dead code. The richer sidebar (expand/collapse groups, inline search, color-coded items, table indicators) is invisible to users.

**Fix:** Replace `CategorySidebar` in `MainContentView.sidebarView` with `SidebarView`, wire the Settings button to open the Settings window, and wire Help to `NSApp.showHelp(nil)` or the local help window.

---

#### BUG-006 — `BookmarkManager.lastAction` reset guard is always `true`
**Severity:** High
**File:** `BookmarkManager.swift:40–43`, `54–57`
**Component:** Bookmark feedback

**Code:**
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
    guard let self = self else { return }
    if self.lastAction?.message == self.lastAction?.message {  // ← always true
        self.lastAction = nil
    }
}
```

**Expected:** Reset `lastAction` only if it has not been replaced by a newer action.
**Actual:** The condition compares the property to itself and is always `true`. This is harmless (action always clears after 3 s), but the anti-race guard is entirely inoperative — a rapid add→remove sequence will clear the second action prematurely.

**Fix:**
```swift
let actionAtScheduleTime = self.lastAction
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
    guard let self = self else { return }
    if self.lastAction?.message == actionAtScheduleTime?.message {
        self.lastAction = nil
    }
}
```

---

#### BUG-007 — `MainContentView` creates duplicate `KeyboardNavigationManager` reference
**Severity:** High
**File:** `MainContentView.swift:17`
**Component:** State management

**Code:**
```swift
@StateObject private var navigationManager = KeyboardNavigationManager.shared
```

`APGIAppendixApp` injects `KeyboardNavigationManager.shared` as an `@EnvironmentObject`. `MainContentView` also creates a `@StateObject` wrapping the same singleton. SwiftUI tracks these as separate observed objects, meaning state changes to the shared instance may trigger double re-renders and the `@StateObject` wrapper holds a strong reference that bypasses the environment injection hierarchy.

**Fix:** Remove the `@StateObject` declaration and use `@EnvironmentObject private var navigationManager: KeyboardNavigationManager` consistently.

---

#### BUG-008 — `ThemeManager.backgroundColor` is identical for Light and Dark themes
**Severity:** High
**File:** `ThemeManager.swift:48–57`
**Component:** Theming / Dark Mode

**Code:**
```swift
case .light:
    return Color(NSColor.controlBackgroundColor)
case .dark:
    return Color(NSColor.controlBackgroundColor)  // ← same as light
```

**Expected:** The `.dark` case should return a dark semantic color (e.g., `NSColor.windowBackgroundColor` under `.darkAqua` appearance).
**Actual:** Both cases return the same adaptive system color, so the property is meaningless for differentiating manual light/dark themes.

---

#### BUG-009 — `APGIColors.surfacePrimary` is hardcoded white — breaks Dark Mode
**Severity:** High
**File:** `APGIColors.swift:32`
**Component:** Color system / Dark Mode

```swift
static let surfacePrimary = Color(white: 0.98)
```

`surfacePrimary` is used as the background of `SidebarView`. In Dark Mode it renders as near-white, making text illegible.

**Fix:**
```swift
static let surfacePrimary = Color(NSColor.windowBackgroundColor)
```

---

#### BUG-010 — `PerformanceManager.handleMemoryWarning()` is unreachable dead code
**Severity:** High
**File:** `PerformanceManager.swift:50–59`
**Component:** Memory management

`setupSystemMonitoring()` explicitly notes "macOS doesn't have the same memory warning system as iOS" and never registers any notification or calls `handleMemoryWarning()`. The cache-eviction logic for memory pressure is completely dead.

**Fix:** Subscribe to `NSWorkspace.didWakeNotification` + `ProcessInfo.thermalStateDidChangeNotification`, or use a `DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical])` to trigger cache eviction.

---

### MEDIUM

---

#### BUG-011 — `URLSession` force-unwrap crash risk in `testConnection()`
**Severity:** Medium
**File:** `NetworkManager.swift:233`
**Component:** Network diagnostics

```swift
URLSession.shared.dataTask(with: URL(string: "https://api.apgi-framework.org")!) { ... }
```

Force-unwrapping the URL is safe *now* but will crash if the string is ever changed to a malformed value. Additionally, the `NSAlert.runModal()` calls inside an async callback block the main thread.

**Fix:** Use `guard let url = URL(string: "https://api.apgi-framework.org") else { return }` and replace `NSAlert.runModal()` with SwiftUI alert state.

---

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

---

#### BUG-013 — Search debounce `Timer` not invalidated on view disappear
**Severity:** Medium
**File:** `SearchView.swift:83–85`
**Component:** Search

`Timer.scheduledTimer` is stored in `@State private var debounceTimer`. If the view is dismissed while the timer is pending, the timer fires and attempts to call `performSearch()` on a deallocated context.

**Fix:** Add `.onDisappear { self.debounceTimer?.invalidate(); self.searchTask?.cancel() }`.

---

#### BUG-014 — `UserDefaults.standard.synchronize()` deprecated no-op called in 3 locations
**Severity:** Medium
**Files:** `ThemeManager.swift:38, 111`, `NetworkManager.swift` (implicit via AppStorage)
**Component:** Settings persistence

`UserDefaults.synchronize()` has been a no-op since macOS 10.12 and is flagged by the compiler. Remove all calls.

---

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

---

#### BUG-016 — Help and Settings buttons in `SidebarView` have empty closures
**Severity:** Medium
**File:** `SidebarView.swift:70–83`

```swift
Button(action: { }) { Label("Settings", systemImage: "gear") }
Button(action: { }) { Label("Help", systemImage: "questionmark.circle") }
```

Both bottom-bar buttons do nothing. If `SidebarView` is eventually activated (BUG-005 fix), these will be silent.

---

### LOW

---

#### BUG-017 — `APGISpacing` and `APGIRadius` have duplicate aliased constants
**Severity:** Low
**File:** `APGIColors.swift:61–92`
Both enums define `small/medium/large/extraLarge` AND `xs/sm/md/lg` pointing to identical values, creating naming confusion with no semantic distinction.

---

#### BUG-018 — `Optional.isNil` extension defined but never used
**Severity:** Low
**File:** `SettingsView.swift:4–8`
Dead code; Swift already provides `== nil` for this purpose.

---

#### BUG-019 — Onboarding promises features that do not exist
**Severity:** Low
**File:** `OnboardingTour.swift:186`
The final onboarding step states "Drag and drop to reorganize" and "Right-click for context menus". Neither feature is implemented anywhere in the current codebase.

---

#### BUG-020 — Screenshot auth token hardcoded in documentation
**Severity:** Low
**File:** `README.md:626`
```bash
export SCREENSHOT_AUTH_TOKEN=APGI-Screenshot-2024
```
Hardcoded credentials in public documentation should be replaced with a placeholder and the actual token managed via environment secrets.

---

## Missing Features Log

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
| MF-011 | **Core ML on-device AI** | Low | Framework has rich parameter space suitable for on-device recommendations (e.g., "related sections"). No Core ML model integrated. |
| MF-012 | **Continuity Camera / Universal Clipboard** | Low | Continuity features declared in onboarding conceptually but not implemented. |
| MF-013 | **VoiceOver full audit** | Low | `apgiAccessibility` modifier applied to toolbar buttons only; most list items, cards, and simulator controls have no accessibility labels. |
| MF-014 | **Keyboard focus ring in split view** | Low | No explicit `focusable()` / `FocusState` management beyond `Cmd+F` shortcut. Full keyboard-only navigation is incomplete. |
| MF-015 | **Drag-and-drop bookmark reordering** | Low | Onboarding promises this; `BookmarkManager.bookmarks: [String]` supports ordering but no drag gesture is wired. |

---

## Architecture Analysis: SwiftUI / AppKit Hybrid

### Current Pattern Inventory

| Pattern | Usage | Assessment |
|--------|-------|-----------|
| `@NSApplicationDelegateAdaptor` | `AppDelegate` | Correct |
| `NSHostingView` | Help, What's New, Quick Start auxiliary windows | Correct but windows lack `windowController` lifecycle management |
| `NavigationSplitView` | Main 3-panel layout | Correct; `columnVisibility` binding properly threaded |
| `@MainActor` on managers | `PerformanceManager`, `ErrorHandler`, `OnboardingManager`, `NetworkManager` | Correct |
| `ObservableObject` + `@StateObject` | All managers | Correct pattern; BUG-007 creates dual references |
| Combine `@Published` + `assign(to:on:)` | `PerformanceManager` power/thermal monitoring | Correct; Combine store (`cancellables`) properly held |
| `NSCache<NSString, AnyObject>` | Content + search result caching | Correct; cost limits set |
| Swift Concurrency `async/await` + `Task` | Search, simulation | Correct; cancellation checked |
| `NWPathMonitor` on private queue | `NetworkManager` | Correct; `@MainActor` class handles thread-hop via `DispatchQueue.main.async` |

### Recommended Battle-Tested Patterns

**NSViewRepresentable for custom drawing (e.g., future neural circuit canvas):**
```swift
struct NeuralCanvasRepresentable: NSViewRepresentable {
    @Binding var parameters: APGIParameters

    func makeNSView(context: Context) -> NeuralCanvasView {
        let view = NeuralCanvasView()
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NeuralCanvasView, context: Context) {
        nsView.updateParameters(parameters)          // diff, don't recreate
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NeuralCanvasDelegate {
        var parent: NeuralCanvasRepresentable
        init(_ parent: NeuralCanvasRepresentable) { self.parent = parent }
    }
}
```

**NSHostingView auxiliary window (memory-safe pattern):**
```swift
// Retain window controller — bare NSWindow will be deallocated
private var helpWindowController: NSWindowController?

private func showLocalHelp() {
    if helpWindowController == nil {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered, defer: false)
        window.contentView = NSHostingView(rootView: HelpContentView())
        window.setFrameAutosaveName("HelpWindow")
        helpWindowController = NSWindowController(window: window)
    }
    helpWindowController?.showWindow(nil)
    helpWindowController?.window?.center()
}
```

> **Current issue:** `APGI_Appendix.swift` creates raw `NSWindow` instances in `showLocalHelp()`, `showWhatsNew()`, `showQuickStart()` without retaining them in a `NSWindowController`. These windows will be immediately deallocated on macOS 14 under ARC. Always use `NSWindowController` or SwiftUI `Window` scene to manage auxiliary windows.

---

## Performance-First Roadmap

### P0 — Immediate (Correctness Blockers)

| Task | File(s) | Est. Effort |
|------|---------|------------|
| Fix `SectionCategory.sections` (BUG-001) | `SectionCategory.swift` | 30 min |
| Implement real PDF export via `NSPrintOperation` | `MainContentView.swift` | 1 day |
| Fix duplicate `CommandGroup(replacing: .help)` (BUG-003) | `APGICommands.swift`, `APGI_Appendix.swift` | 1 hr |
| Provide real `Tab.fullContent` (BUG-004) | `TabTypes.swift` + bundle resources | 3 days |
| Register `apgi-appendix` URL scheme in Info.plist (MF-005) | `Info.plist` | 30 min |
| Fix `BookmarkManager.lastAction` tautology (BUG-006) | `BookmarkManager.swift` | 15 min |
| Replace bare `NSWindow` with `NSWindowController` | `APGI_Appendix.swift` | 2 hrs |

### P1 — Short-term (Performance & Resilience)

**Replace Timer-based simulation with structured concurrency:**
```swift
// Instead of Timer.scheduledTimer(withTimeInterval: 0.1, ...)
private var simulationTask: Task<Void, Never>?

func startSimulation() {
    simulationTask = Task(priority: .userInitiated) {
        while !Task.isCancelled {
            await updateSimulationState()
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}

func stopSimulation() {
    simulationTask?.cancel()
}
```

**GCD QoS tiers for background work:**
```swift
// Search indexing — background QoS
Task.detached(priority: .background) {
    await buildSearchIndex()
}

// User-initiated content load — userInitiated QoS
Task(priority: .userInitiated) {
    await loadSectionContent(for: selectedSection)
}
```

**Instruments validation checklist:**
- [ ] Time Profiler: confirm no main-thread stalls >16 ms during section switch
- [ ] Allocations: verify `NSCache` eviction path (fix BUG-010 first)
- [ ] Leaks: audit `NotificationCenter.addObserver` usages for `[weak self]`
- [ ] SwiftUI View Body: use `_printChanges()` in debug to find excessive re-renders caused by BUG-007

**os_log structured logging (replace `print()` calls):**
```swift
import OSLog

private let logger = Logger(subsystem: "com.apgi.appendix", category: "Export")

// Replace: print("Exporting current view to PDF: \(url)")
// With:
logger.info("Exporting PDF to \(url.lastPathComponent, privacy: .public)")
logger.error("PDF export failed: \(error.localizedDescription, privacy: .public)")
```

> There are currently **14 bare `print()` calls** across the codebase (including the PDF export stub and update-check stub). All should be replaced with `os_log`/`Logger` at appropriate levels.

### P2 — Medium-term (Apple Platform Differentiators)

**StoreKit 2 integration scaffold:**
```swift
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    @Published var purchasedProductIDs: Set<String> = []

    private let productIDs = ["com.apgi.appendix.pro", "com.apgi.appendix.educator"]

    func loadProducts() async throws -> [Product] {
        try await Product.products(for: productIDs)
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            await transaction.finish()
            purchasedProductIDs.insert(transaction.productID)
        case .userCancelled, .pending: break
        @unknown default: break
        }
    }
}
```

**CoreSpotlight indexing for section discoverability:**
```swift
import CoreSpotlight

func donateToSpotlight(tab: Tab) {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
    attributeSet.title = tab.shortTitle
    attributeSet.contentDescription = tab.searchIndexText
    attributeSet.keywords = [tab.category.rawValue, "APGI", "neuroscience"]

    let item = CSSearchableItem(
        uniqueIdentifier: tab.rawValue,
        domainIdentifier: "com.apgi.appendix.content",
        attributeSet: attributeSet
    )
    CSSearchableIndex.default().indexSearchableItems([item]) { _ in }
}
```

**Core ML on-device related-section recommendation:**
```swift
// Embed section content vectors at build time using CreateML text embedding
// Runtime inference:
func findRelatedSections(to tab: Tab, model: APGISectionEmbedding) -> [Tab] {
    guard let embedding = try? model.prediction(text: tab.searchIndexText) else { return [] }
    return Tab.allCases
        .filter { $0 != tab }
        .sorted { cosineDistance($0, embedding, model) < cosineDistance($1, embedding, model) }
        .prefix(3)
        .map { $0 }
}
```

**Apple Silicon (arm64) optimisations:**
```swift
// Simulator matrix ops — use Accelerate BLAS/vDSP directly
import Accelerate

// Replace manual loop in APGISimulatorModule with:
func applyWeightMatrix(_ weights: [Float], input: [Float]) -> [Float] {
    var result = [Float](repeating: 0, count: weights.count / input.count)
    cblas_sgemv(CblasRowMajor, CblasNoTrans,
                Int32(result.count), Int32(input.count),
                1.0, weights, Int32(input.count),
                input, 1, 0.0, &result, 1)
    return result
}
```

### P3 — Long-term (Distribution & Continuity)

**Mac App Store vs. Direct Distribution:**

| Factor | Mac App Store | Direct (Notarised DMG) |
|--------|--------------|----------------------|
| Sandbox | Required (already enabled ✓) | Optional |
| StoreKit | Native | Sparkle + manual licensing |
| Update delivery | Automatic | Sparkle / manual |
| Reach | Global discovery | Manual marketing required |
| Review lag | 1–5 days | None |
| Custom entitlements | Limited | Full flexibility |
| Universal Purchase (iOS/iPadOS) | Supported | N/A |

**Recommendation:** Target the Mac App Store as primary channel given the sandbox is already correctly configured, privacy manifest is present, and entitlements are minimal. Use Sparkle only for an optional beta channel.

**Continuity Handoff (already scaffolded — needs URL scheme fix):**
```swift
// In Info.plist — add CFBundleURLTypes:
// <key>CFBundleURLSchemes</key><array><string>apgi-appendix</string></array>

// In AppDelegate — handle incoming URL:
func application(_ app: NSApplication, open urls: [URL]) {
    urls.forEach { url in
        NotificationCenter.default.post(
            name: .handleDeepLink, object: url)
    }
}
```

---

## Security & Privacy Summary

| Control | Status | Notes |
|---------|--------|-------|
| App Sandbox | ✅ Enabled | `com.apple.security.app-sandbox = true` |
| Network client | ✅ Scoped | Server entitlement is `false` |
| Keychain + CryptoKit AES-256-GCM | ✅ Implemented | Bookmark persistence encrypted at rest |
| Privacy Manifest (`PrivacyInfo.xcprivacy`) | ✅ Present | UserDefaults, FileTimestamp, DiskSpace, BootTime, ActiveKeyboards declared |
| Privacy tracking | ✅ `false` | No tracking domains |
| Hardcoded credential in docs | ⚠️ Low Risk | `SCREENSHOT_AUTH_TOKEN` in README — move to env var |
| Force-unwrap URL in production path | ⚠️ Medium Risk | `NetworkManager.swift:233` |
| Screen recording entitlement | ⚠️ Review | `ScreenshotAutomation.swift` requests `CGRequestScreenCaptureAccess()` — ensure this is conditionally compiled out of production builds |

---

## LLDB Debugging Cheatsheet (Project-Specific)

```lldb
# Break when SectionCategory.sections returns empty (BUG-001 validation)
(lldb) b SectionCategory.swift:39
(lldb) po self

# Inspect NavigationManager notification delivery
(lldb) b MainContentView.swift:49
(lldb) po notification.name

# Watch BookmarkManager for premature lastAction clear (BUG-006)
(lldb) watchpoint set variable self->_lastAction

# Verify @MainActor enforcement on PerformanceManager
(lldb) thread info
```

---

## Actionable Remediation Checklist

### Sprint 1 — Critical Bugs (Week 1–2)
- [ ] `SectionCategory.sections` — use `Tab.allCases.filter { $0.category == self }` (BUG-001)
- [ ] `Tab.fullContent` — bundle per-tab `.md` or `.txt` resources; update `content` and `FocusModeView` (BUG-004)
- [ ] PDF export — implement `NSPrintOperation` or `PDFDocument` rendering (BUG-002)
- [ ] Deduplicate `CommandGroup(replacing: .help)` (BUG-003)
- [ ] Register `apgi-appendix://` URL scheme in `Info.plist` (MF-005)
- [ ] Replace bare `NSWindow` instances with `NSWindowController` in `APGI_Appendix.swift`
- [ ] Fix `BookmarkManager.lastAction` tautology guard (BUG-006)

### Sprint 2 — High Severity & Performance (Week 3–4)
- [ ] Activate `SidebarView` as primary sidebar; wire Settings/Help buttons (BUG-005)
- [ ] Replace `@StateObject navigationManager` with `@EnvironmentObject` in `MainContentView` (BUG-007)
- [ ] Fix `ThemeManager.backgroundColor` dark case; replace `surfacePrimary` with `NSColor.windowBackgroundColor` (BUG-008/009)
- [ ] Implement memory pressure handler via `DispatchSource.makeMemoryPressureSource` (BUG-010)
- [ ] Convert Timer-based simulation loop to `Task` + `Task.sleep`
- [ ] Remove all `UserDefaults.synchronize()` calls (BUG-014)
- [ ] Add `.onDisappear` timer/task cancellation in `SearchView` (BUG-013)
- [ ] Replace all 14 `print()` calls with `os_log` / `Logger`

### Sprint 3 — Missing Features & Platform Integration (Week 5–8)
- [ ] CoreSpotlight donation for all 23 tabs (MF-006)
- [ ] Context menus on section list rows, bookmark list, search results (MF-007)
- [ ] `NSPrintOperation` print menu item (MF-008)
- [ ] `@ScaledMetric` / Dynamic Type for font sizes (MF-010)
- [ ] StoreKit 2 purchase flow scaffold (MF-003)
- [ ] Full VoiceOver audit and `accessibilityLabel` pass on all interactive elements (MF-013)
- [ ] `FocusState` keyboard navigation in split view columns (MF-014)

### Sprint 4 — Distribution Hardening (Week 9–10)
- [ ] Instruments Leaks + Time Profiler sign-off
- [ ] App Store Connect submission checklist (privacy nutrition label, screenshots, metadata)
- [ ] Sparkle beta channel for direct distribution
- [ ] Remove screenshot automation from production target (conditional compilation guard)
- [ ] Core ML section embedding model (MF-011) — stretch goal

---

## Appendix: File-to-Bug Cross-Reference

| File | Bugs / Issues |
|------|--------------|
| `TabTypes.swift` | BUG-004, BUG-012 |
| `SectionCategory.swift` | BUG-001 |
| `MainContentView.swift` | BUG-007, BUG-011 (URL), MF-005 |
| `APGI_Appendix.swift` | BUG-003, bare NSWindow issue |
| `APGICommands.swift` | BUG-003, BUG-016 (indirectly) |
| `SidebarView.swift` | BUG-005, BUG-016 |
| `BookmarkManager.swift` | BUG-006 |
| `PerformanceManager.swift` | BUG-010, BUG-014 |
| `NetworkManager.swift` | BUG-011, BUG-014 |
| `ThemeManager.swift` | BUG-008, BUG-014 |
| `APGIColors.swift` | BUG-009, BUG-017 |
| `ErrorHandler.swift` | BUG-002 (no consumer of handler in export path) |
| `SettingsView.swift` | BUG-018 |
| `OnboardingTour.swift` | BUG-019 |
| `README.md` | BUG-020 |

---

*Report generated by macOS Lead Architect review — APGI Appendix v1.x — 2026-02-24*
