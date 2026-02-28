# APGI Appendix — macOS Lead Architect Assessment Report

**Prepared by:** macOS Lead Architect (AI)
**Date:** 2026-02-28
**Codebase:** APGI-Appendix macOS Application
**Branch audited:** `claude/macos-roadmap-design-b4WWP`
**Swift files analyzed:** 77 files / 21,515 lines of Swift
**Platform target:** macOS 14.0+, SwiftUI + AppKit hybrid

---

## Executive Summary

APGI Appendix is an interactive neuroscience reference application that surfaces the Adaptive Predictive Gamma Integration (APGI) framework through a rich, document-centric macOS interface. The application demonstrates solid structural intentions—three-panel `NavigationSplitView` layout, observable-object state management, Keychain-backed secrets with CryptoKit, `os_log`-integrated error telemetry, Spotlight indexing, Handoff / Continuity support, a full-featured APGI simulator backed by `MLMultiArray`, and well-layered keyboard-first navigation. The design vocabulary (APGIColors, APGITypography, APGISpacing) is consistent and HIG-aligned.

However, the current build is **broken**: `'editMode' is unavailable in macOS` causes a compile-time error. Beyond the build stopper, auditing uncovered one critical resource-leak that regenerates live DispatchSources on every timer tick, an NSEvent monitor that is never cancelled, a hardcoded authentication secret in source control, a missing app icon, `NSHostingView` instances created outside the main thread in export paths, and an orphaned view hierarchy branch (`detailView` with the full toolbar) that is computed but never wired into the split-view tree—meaning toolbar items for network status, bookmarks, focus mode, search, and export **do not appear in the running app**.

After remediation the application is well-positioned for Mac App Store distribution. The recommendations below are sequenced so a two-engineer team can achieve a stable 1.0 in approximately four focused sprints.

---

## KPI Scores Table

| # | KPI | Score (1–100) | Rationale |
|---|-----|:-------------:|-----------|
| 1 | **Functional Completeness** | **58** | Build failure; orphaned toolbar hierarchy; no StoreKit 2; no real Core ML model; Simulator infrastructure present but ML layer is stub-only |
| 2 | **UI/UX Consistency** | **74** | Strong design tokens and HIG alignment; missing app icon; focus-mode overlay duplicated in two layers; inspector is minimal (title + category only) |
| 3 | **Responsiveness & Performance** | **66** | Good NSCache sizing and thermal-state adaptation; critical DispatchSource leak regenerates objects every 10 s; `getAvailableMemory()` computes `total − resident_size` (incorrect); NSEvent monitor leaks; 25 `DispatchQueue.main` calls without actor isolation |
| 4 | **Error Handling & Resilience** | **72** | Comprehensive `os_log` + file-backed `ErrorLogger`; log rotation works; all network paths have offline fallbacks; unreachable catch blocks in `LazyLoadingContainer`; `MLMultiArray()` fallback in `APGIState.initialize` silently returns an unusable empty array |
| 5 | **Overall Implementation Quality** | **66** | Architecture is sound; critical bugs and missing final-mile features pull the score down; security posture is strong (sandbox ✓, Keychain + AES-GCM ✓, Privacy Manifest ✓) |

**Composite Score: 67 / 100**

---

## Bug Inventory

### CRITICAL (Build-Blocking / Data Loss)

#### BUG-001 — `'editMode' is unavailable in macOS` (Build Failure)
- **Severity:** Critical
- **File:** `SettingsView.swift` line 220
- **Component:** Settings panel
- **Reproduction:** `xcodebuild -scheme APGI-Appendix build` → `** BUILD FAILED **`
- **Expected:** Clean compile targeting macOS 14+
- **Actual:** Compile error; the app cannot be run at all
- **Root cause:** SwiftUI's `.environment(\.editMode, ...)` or `@Environment(\.editMode)` is an iOS/iPadOS-only API. The `List` edit-mode pattern must be replaced with a custom `isEditing` `@State` var driving `.onDelete` / `.moveDisabled` modifiers directly, or the edit UI must be restructured using explicit buttons.
- **Fix:** Replace the `editMode` environment key reference with a local `@State var isEditing = false` and conditionally show delete controls.

---

#### BUG-002 — DispatchSource Created on Every Timer Tick (Resource / Memory Leak)
- **Severity:** Critical
- **File:** `PerformanceManager.swift` lines 56–72
- **Component:** `PerformanceManager.checkMemoryPressure()`
- **Reproduction:** Run the app for > 1 minute; observe leaked `DispatchSourceProtocol` objects in Instruments → Leaks
- **Expected:** A single memory-pressure source created once at init, stored for its lifetime
- **Actual:** `checkMemoryPressure()` is called by a `Timer` every 10 seconds. Each call allocates a new `DispatchSource.makeMemoryPressureSource(...)`, calls `.resume()`, and discards the reference. The source is never cancelled, so it accumulates indefinitely.
- **Fix:**
  ```swift
  // In PerformanceManager.init(), replace the timer-based call with:
  private var memoryPressureSource: DispatchSourceMemoryPressure?

  private func setupMemoryPressureMonitoring() {
      let source = DispatchSource.makeMemoryPressureSource(eventMask: .warning, queue: .main)
      source.setEventHandler { [weak self] in self?.handleMemoryWarning() }
      source.resume()
      self.memoryPressureSource = source // retains until deinit
  }
  ```
  Remove the 10-second timer that calls `checkMemoryPressure()` and the `checkMemoryPressure()` method itself.

---

#### BUG-003 — Orphaned Toolbar Hierarchy (`detailView` Never Used)
- **Severity:** Critical (invisible feature — all toolbar controls absent at runtime)
- **File:** `MainContentView.swift` lines 118–200 vs. lines 202–230
- **Component:** Main window toolbar (NetworkStatusView, BookmarkButton, FocusMode, Search, Export, FontSizeControl, Inspector toggle)
- **Reproduction:** Build and run → inspect toolbar; no network indicator, bookmark, focus, search, export, or inspector-toggle buttons are visible
- **Expected:** Toolbar populated per `detailView`'s `ToolbarItemGroup`
- **Actual:** `body` feeds `NavigationSplitView(detail: { self.detailContentView })`. The computed `detailView` property (which contains `.toolbar { … }`) is defined but **never referenced**. `detailContentView` (the inner `HStack` of content + inspector) is a separate private computed property without a toolbar modifier.
- **Fix:** Replace `detail: { self.detailContentView }` in `body` with `detail: { self.detailView }`, remove the internal `detailContentView` embedding inside the unused `detailView`, and collapse to a single detail view that hosts both the content and the toolbar modifiers.

---

### HIGH (Significant Functional Defect / Security)

#### BUG-004 — Hardcoded Authentication Token in Source
- **Severity:** High (Security)
- **File:** `ScreenshotAutomation.swift` lines ~2045–2055
- **Component:** `ProductionScreenshotRunner.authenticateUser()`
- **Reproduction:** `grep "APGI-Screenshot-2024" ScreenshotAutomation.swift`
- **Expected:** Secrets are never committed to source control
- **Actual:** `authToken == "APGI-Screenshot-2024"` is a literal comparison in committed code. Anyone with source access can trivially bypass the guard.
- **Fix:** Move the expected token to an environment-injected secret (`xcconfig` var or CI secret); compare against a cryptographic hash stored in the Info.plist, not a plaintext string. For a production guard use `LocalAuthentication` or a signed payload instead.

---

#### BUG-005 — NSEvent Local Monitor Never Cancelled (Memory Leak)
- **Severity:** High
- **File:** `KeyboardNavigation.swift` lines 290–310
- **Component:** `KeyboardNavigableMainView.setupKeyboardMonitor()`
- **Reproduction:** Navigate away from and back to any view using `KeyboardNavigableMainView`; each re-render calls `setupKeyboardMonitor()` via `.onAppear`, registering an additional monitor without removing the previous one
- **Expected:** Monitor stored and removed in `onDisappear` or equivalent
- **Actual:** `NSEvent.addLocalMonitorForEvents(matching:handler:)` returns an `Any?` token; the token is discarded, making cancellation impossible
- **Fix:**
  ```swift
  @State private var eventMonitor: Any?

  .onAppear { eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { … } }
  .onDisappear { if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil } }
  ```

---

#### BUG-006 — `getAvailableMemory()` Returns Resident Size, Not Available Memory
- **Severity:** High (incorrect threshold logic in memory-pressure alerting)
- **File:** `PerformanceManager.swift` lines 75–90 and `MemoryMonitor.swift` lines 88–100
- **Component:** Memory pressure detection
- **Reproduction:** `PerformanceManager.checkMemoryPressure()` computes `memoryUsageRatio = (total - resident) / total` — this subtracts the current process's resident size from total physical RAM, then divides — yielding roughly `(16 GB - 250 MB) / 16 GB ≈ 0.98`, which always triggers the 80% threshold regardless of actual system pressure
- **Expected:** Available memory retrieved from `vm_stat` host info or `ProcessInfo` APIs
- **Fix:**
  ```swift
  private func systemAvailableMemoryBytes() -> UInt64 {
      var vmStats = vm_statistics64()
      var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
      let result = withUnsafeMutablePointer(to: &vmStats) {
          $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
              host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
          }
      }
      guard result == KERN_SUCCESS else { return 0 }
      let pageSize = UInt64(vm_kernel_page_size)
      return (UInt64(vmStats.free_count) + UInt64(vmStats.inactive_count)) * pageSize
  }
  ```

---

#### BUG-007 — `NSHostingView` Created Off Main Thread During Export
- **Severity:** High (UIKit / AppKit thread-safety rule; causes undefined behavior / crashes)
- **File:** `MainContentView.swift` lines 408–425, lines 490–505
- **Component:** `exportCurrentViewToPDF(url:)` and `printCurrentSection()`
- **Reproduction:** Trigger Export → PDF from the menu while on a background Combine thread
- **Expected:** All `NSHostingView` / `NSView` creation must occur on the main thread
- **Actual:** Both methods allocate `NSHostingView(rootView:)` synchronously inside closures that may be invoked from background contexts
- **Fix:** Wrap both method bodies in `DispatchQueue.main.async { … }` or annotate with `@MainActor`.

---

#### BUG-008 — `MLMultiArray()` Empty-Array Fallback in `APGIState.initialize`
- **Severity:** High (silent data corruption)
- **File:** `APGISimulatorModule.swift` lines 42–65
- **Component:** APGI Simulator state initialization
- **Reproduction:** Run on a device where `MLMultiArray(shape:dataType:)` throws (e.g., invalid shape); the `?? MLMultiArray()` fallback returns a zero-count array, and all subsequent index subscript accesses (`interoStates[index] = 0.0`) are out-of-bounds
- **Expected:** A thrown error propagates and is handled with a user-facing alert
- **Fix:** Make `initialize()` `throws`; propagate the `MLMultiArray` initializer error; catch at the call site and display an error sheet.

---

### MEDIUM (Degraded Experience / Non-Blocking)

#### BUG-009 — Missing App Icon (`CFBundleIconFile` Empty)
- **Severity:** Medium
- **File:** `Info.plist` line 8
- **Component:** App bundle metadata
- **Reproduction:** Build and check Dock / Finder; app shows generic document icon
- **Fix:** Create an `AppIcon.appiconset` in `Assets.xcassets` covering all required macOS sizes (16×16 @1x/2x, 32×32, 64×64, 128×128, 256×256, 512×512, 1024×1024); set `CFBundleIconFile` to `AppIcon`.

---

#### BUG-010 — Focus Mode Overlay Applied Twice
- **Severity:** Medium (doubled SwiftUI overlay; potential layout jank)
- **File:** `MainContentView.swift` — both `detailContentView` (line 218) and the inner `DetailContentView` struct (line 248) independently apply `FocusModeView`
- **Reproduction:** Enable focus mode; content rendered twice on top of itself
- **Fix:** Remove `FocusModeView` from `detailContentView` and keep it only inside the `DetailContentView` struct's `ZStack`, or vice versa.

---

#### BUG-011 — Unreachable `catch` Blocks in `LazyLoadingContainer`
- **Severity:** Medium (Xcode warnings; indicates unreachable defensive code)
- **File:** `LazyLoadingContainer.swift` lines 59, 63
- **Component:** Lazy content loading infrastructure
- **Reproduction:** Build → warnings `'catch' block is unreachable because no errors are thrown in 'do' block`
- **Fix:** Remove the `do/catch` wrappers around the non-throwing expressions, or convert the non-throwing code to a throwing form if the intent is to handle future errors.

---

#### BUG-012 — `DispatchQueue.main` Calls Instead of `@MainActor` Isolation (25 sites)
- **Severity:** Medium (Swift Concurrency best-practice violation; potential data races under strict concurrency)
- **Files:** Multiple — `PerformanceManager.swift`, `MemoryMonitor.swift`, `ContentCacheManager.swift`, `NetworkManager.swift` etc.
- **Reproduction:** Enable strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`) → compiler warnings
- **Fix:** Annotate the relevant `@MainActor` classes/functions and replace `DispatchQueue.main.async { … }` with `await MainActor.run { … }` or direct actor-isolated calls.

---

#### BUG-013 — `KeyboardNavigableMainView` Is Unreachable Dead Code
- **Severity:** Medium (confusing duplication; risk of future divergence)
- **File:** `KeyboardNavigation.swift` lines 252–320
- **Component:** Navigation architecture
- **Root cause:** The app's scene graph uses `OnboardingTourView → MainContentView`. `KeyboardNavigableMainView` is a parallel root-level view with its own sidebar, search, and glossary panel that is never embedded anywhere.
- **Fix:** Remove `KeyboardNavigableMainView`, `EnhancedSidebarView`, and the duplicate glossary panel, consolidating all functionality into `MainContentView`.

---

### LOW (Polish / Minor)

#### BUG-014 — Inspector Panel Shows Minimal Metadata
- **Severity:** Low
- **File:** `MainContentView.swift` — `InspectorView`
- **Details:** Inspector shows section title, category, and "Includes tables" boolean. The README promises cross-references, content-type indicators, related links, and metadata. These are all absent.

---

#### BUG-015 — Hardcoded `https://docs.apgi-framework.org` Link (Unverified Domain)
- **Severity:** Low (broken external link)
- **Files:** `SidebarView.swift`, `MainContentView.swift`, `APGICommands.swift`
- **Details:** `NSWorkspace.shared.open(URL("https://docs.apgi-framework.org"))` — domain appears to be a placeholder. `URLValidator.openSafely` is used for the Help menu but not for the sidebar "Help" button.

---

#### BUG-016 — Log File Opened with `FileHandle(forWritingTo:)` Without Error Handling
- **Severity:** Low
- **File:** `ErrorLogger.swift` lines 218–225
- **Details:** If `FileHandle` init fails (permissions, sandbox), the write silently drops. Wrap in `do/try/catch` with a fallback `os_log` entry.

---

#### BUG-017 — `MemoryMonitor` Not `@MainActor`-Isolated, but Updates `@Published` Vars from Timer
- **Severity:** Low
- **File:** `MemoryMonitor.swift`
- **Details:** `recordMemoryStats()` is called on the Timer callback thread (RunLoop.main, but not actor-enforced). With strict concurrency the mutation of `memoryHistory` would be flagged. Annotate the class `@MainActor`.

---

#### BUG-018 — `createDeepLinkURL(for:)` Defined but Never Called
- **Severity:** Low (dead code)
- **File:** `MainContentView.swift` lines 302–310
- **Details:** `handleDeepLink(_:)` uses a different query-param key (`tab`) than the Handoff activity handler (`section`). The URL scheme registration is correct in `Info.plist`, but `onOpenURL` is never attached to the scene.

---

## Missing Features Log

| ID | Feature | Scope Reference | Priority | Status |
|----|---------|-----------------|----------|--------|
| MF-001 | **App Icon** | README §2.2, App Store requirement | P0 | Missing |
| MF-002 | **StoreKit 2 Integration** | Requested in brief; monetization / IAP | P1 | Not started |
| MF-003 | **Actual Core ML Model** | `CoreMLMemoryManager` exists as infrastructure; no `.mlmodel` shipped | P1 | Stub only |
| MF-004 | **Deep-Link URL Handling** (`onOpenURL`) | Info.plist defines `apgi-appendix://` scheme | P1 | Partially wired (no scene handler) |
| MF-005 | **Inspector Panel — Rich Metadata** | README §3.1: cross-references, related links | P2 | Minimal stub |
| MF-006 | **iCloud / CloudKit Sync for Bookmarks** | Multi-device scenario implied by Handoff support | P2 | Not started |
| MF-007 | **VoiceOver / Accessibility Audit** | HIG requirement; `apgiAccessibility()` modifier present but not validated | P2 | Not validated |
| MF-008 | **Window State Restoration** | HIG macOS guideline; manually created `NSWindow` panels don't restore | P2 | Partial |
| MF-009 | **Apple Silicon Explicit Vectorization** | Brief requirement: Apple Silicon optimizations | P2 | Accelerate imported but unused |
| MF-010 | **Quick Look Preview Extension** | macOS distribution best-practice for document types | P3 | Not started |
| MF-011 | **Widget / Notification Center Extension** | Continuity / future-proofing | P3 | Not started |
| MF-012 | **Continuity Camera / AirPlay** | Brief: Continuity features | P3 | Not started |
| MF-013 | **In-App Purchase Receipt Validation** | Required for any paid content / non-consumable | P3 | Not started |
| MF-014 | **`onOpenURL` Scene Handler** | Completing custom URL scheme support | P1 | Partially wired |
| MF-015 | **Spotlight Search Result → App Navigation** | `CSSearchableIndex` indexing is done; `NSUserActivity` restoration not wired to `onContinueUserActivity` in scene | P2 | Partial |

---

## Security Vulnerability Assessment

| ID | Vulnerability | Severity | Location | Remediation |
|----|--------------|----------|----------|-------------|
| SEC-001 | Hardcoded auth token `"APGI-Screenshot-2024"` | High | `ScreenshotAutomation.swift` | Move to CI environment secret; use hash comparison |
| SEC-002 | `com.apple.security.files.downloads.read-write` entitlement broader than needed | Medium | `APGI-Appendix.entitlements` | Scope to `com.apple.security.files.user-selected.read-write` only; remove downloads entitlement unless explicitly needed |
| SEC-003 | Network help URL opened via `NSWorkspace` without domain allowlist | Low | `SidebarView.swift`, `MainContentView.swift` | Route all `NSWorkspace.open()` calls through `URLValidator.openSafely()` |
| SEC-004 | `userInfo` dict in `NSUserActivity` (Handoff) not sanitized | Low | `MainContentView.updateUserActivity()` | Ensure only opaque identifiers (section raw value) are placed in `userInfo`, never user-generated content |
| SEC-005 | Log file written to `ApplicationSupportDirectory` without data-protection class | Low | `ErrorLogger.swift` | Set file attributes `NSFileProtectionKey: NSFileProtectionComplete` after creation |

**Positive security posture (no action needed):**
- App Sandbox enabled (`com.apple.security.app-sandbox = true`)
- Keychain + AES-GCM-256 encryption for sensitive strings (`KeychainHelper` + CryptoKit)
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for encryption key
- No user-tracking (`NSPrivacyTracking = false`)
- Privacy Manifest (`PrivacyInfo.xcprivacy`) present with five API categories declared
- No location, camera, microphone, address book, calendar, or photo library permissions requested

---

## Architecture Deep-Dive

### Hybrid SwiftUI / AppKit Patterns

The codebase uses four interaction points between AppKit and SwiftUI:

1. **`NSHostingView` for auxiliary windows** (`WhatsNewView`, `QuickStartPanel`, help content, PDF export host) — correct pattern; the weakness is off-main-thread construction in export paths (BUG-007).

2. **`NSViewRepresentable` for SceneKit (`BrainRegionsSceneView`) and PDFKit (`APGIPDFDiagramView`)** — correct pattern; `makeNSView` / `updateNSView` lifecycle is properly implemented.

3. **`@NSApplicationDelegateAdaptor(AppDelegate.self)`** — correct for receiving `NSApplicationDelegate` callbacks; `AppDelegate` is lightweight, which is appropriate.

4. **`NSWindow` for modal panels** — creates windows outside SwiftUI's scene management (no automatic state restoration, no `@Environment(\.dismiss)` integration). Prefer `WindowGroup` with a unique `id` and `openWindow` for proper integration.

**Recommended `NSViewRepresentable` pattern for custom drawing:**
```swift
struct NeuralNetworkCanvasView: NSViewRepresentable {
    let model: NeuralModel

    func makeNSView(context: Context) -> CustomNSView {
        let view = CustomNSView()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateNSView(_ nsView: CustomNSView, context: Context) {
        nsView.model = model          // push data, never state
        nsView.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: NeuralNetworkCanvasView
        init(_ p: NeuralNetworkCanvasView) { self.parent = p }
    }
}
```

**State integrity rules (currently partially violated):**
- `@StateObject` used correctly for owned objects (`PerformanceManager`, `BookmarkManager`)
- `@ObservedObject` used correctly for injected shared singletons
- Risk: multiple `@StateObject private var onboardingManager = OnboardingManager.shared` instances across different view hierarchies could diverge; prefer environment injection from a single root, which is done in `APGIAppendixApp.body` but not in all preview providers

### Swift Concurrency Assessment

```
async/await usages:        92 sites
@MainActor annotations:    22 types/methods
[weak self] captures:      16 sites
DispatchQueue.main calls:  25 sites (should be 0 with @MainActor)
```

**Recommended migration path:**
```swift
// BEFORE (current pattern in several managers)
DispatchQueue.main.async {
    self.somePublishedProperty = newValue
}

// AFTER (Swift Concurrency)
@MainActor
final class SomeManager: ObservableObject {
    @Published var somePublishedProperty: String = ""

    func updateAsync() async {
        let value = await expensiveComputation()
        somePublishedProperty = value  // already on MainActor
    }
}
```

**GCD QoS tier map for this app:**
| Work Type | Recommended QoS |
|-----------|----------------|
| Search index build | `.userInitiated` |
| Remote content fetch | `.utility` |
| Log file rotation | `.background` |
| Simulator computation tick | `.userInteractive` (frame-driven) |
| Spotlight indexing | `.background` |

### Memory Management

| Pattern | Current Status | Risk |
|---------|---------------|------|
| `NSCache` with `countLimit` + `totalCostLimit` | Correct | Low |
| `[weak self]` in Combine closures | Mostly correct | Low |
| DispatchSource leak in `checkMemoryPressure` | Bug (BUG-002) | Critical |
| NSEvent monitor token not retained | Bug (BUG-005) | High |
| `autoreleasepool` in `forceGarbageCollection` | Correct but cosmetic | Low |
| `MLMultiArrayPool` object pool | Good pattern; not yet integrated into simulator hot path | Medium |

---

## Performance Roadmap

### Launch Time Optimization

```swift
// 1. Defer SpotlightManager.indexAllContent() — runs synchronously at launch
//    Move to .task modifier with .background QoS:
.task(priority: .background) {
    await Task.detached(priority: .background) {
        SpotlightManager.shared.indexAllContent()
    }.value
}

// 2. Defer MemoryMonitor.startMonitoring — not needed at cold launch
//    Start after first contentful paint (after onAppear of MainContentView)

// 3. ScreenshotAutomationRunner.run() in applicationDidFinishLaunching
//    Gate behind #if DEBUG to zero cold-launch cost in Release
#if DEBUG
ScreenshotAutomationRunner.run()
#endif
```

### Simulator Performance (Core ML / Accelerate)

The `APGIState` uses `MLMultiArray` as a general-purpose array, which has high per-element access overhead due to `NSNumber` boxing. For a tight simulation inner loop, replace with `vDSP` / `Accelerate`:

```swift
import Accelerate

// BEFORE: per-element MLMultiArray indexing (O(n) NSNumber allocations)
for index in 0..<hiddenSize {
    interoStates[index] = 0.0
}

// AFTER: zero-copy vDSP fill
var zeros = [Float](repeating: 0, count: hiddenSize * numLevels)
zeros.withUnsafeMutableBufferPointer { buffer in
    interoStates.withUnsafeMutableBytes { raw in
        memcpy(raw.baseAddress!, buffer.baseAddress!, buffer.count * MemoryLayout<Float>.stride)
    }
}
// Or use vDSP_vclr for float vectors:
var dst = [Float](repeating: 0, count: hiddenSize)
vDSP_vclr(&dst, 1, vDSP_Length(hiddenSize))
```

### Apple Silicon Explicit Optimization

```swift
// Use vDSP BLAS-accelerated dot products for precision-weighted surprise calculation
func precisionWeightedSurprise(error: [Float], precision: [Float]) -> Float {
    var result: Float = 0
    vDSP_dotpr(error, 1, precision, 1, &result, vDSP_Length(error.count))
    return result
}

// Use BNNS graph API for repeated inference patterns on M-series
// ANE activation happens automatically when model is .mlpackage + fp16 weights
```

---

## UX / HIG Compliance

### SF Symbols Usage
- `SFSymbols.swift` defines a well-organized enum with 60+ named constants — excellent practice
- All interactive image-only buttons have `.accessibilityLabel()` — compliant
- `brain.head.profile` used for multiple distinct concepts (methodology AND psychological states) — differentiate

### Semantic Coloring & Dark Mode
- `APGIColors.swift` wraps `NSColor.windowBackgroundColor` in `Color.surfacePrimary` — adaptive ✓
- Hardcoded `Color(red:green:blue:)` literal colors in `apgiPrimary`, `apgiSecondary` etc. are **not** adaptive — they look identical in light and dark mode by design, but verify contrast ratios against WCAG 2.1 AA (4.5:1 minimum for normal text)
- Recommended: Define adaptive colors using `Color(light:dark:)` extension or named color assets in the asset catalog

```swift
// Recommended adaptive color pattern
extension Color {
    static let apgiPrimary = Color(NSColor(name: "APGIPrimary") {
        $0.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0.55, green: 0.65, blue: 1.0, alpha: 1)  // brightened for dark
            : NSColor(red: 0.45, green: 0.55, blue: 0.95, alpha: 1)
    })
}
```

### Keyboard-First Navigation
- `APGICommands` provides a full `CommandMenu` hierarchy — HIG-compliant ✓
- `KeyboardShortcutsView` overlay is well-designed ✓
- `⌘1`–`⌘5` in `APGICommands` navigate to categories, but the advertised `⌘1`–`⌘9` in `KeyboardShortcutsView` (jump to sections 1–9) is not implemented — documentation mismatch
- `⌘B` (Toggle bookmarks) is listed in shortcuts view but not bound in `APGICommands`
- `Tab` / `Shift+Tab` cycle between sidebar and detail implemented via `FocusState` — ✓

---

## Distribution Analysis

### Mac App Store vs. Direct Distribution

| Criterion | Mac App Store | Direct (Notarized DMG) |
|-----------|:------------:|:--------------------:|
| Sandbox required | Yes ✓ (already enabled) | No (but recommended) |
| Notarization required | Automatic | Manual via `notarytool` |
| Updates | Automatic | Must implement `Sparkle` or check manually |
| Pricing flexibility | 30% cut; limited regions | Full control |
| Enterprise / MDM | Not ideal | Supported via MDG profile |
| TestFlight | Yes | No |
| IAP (StoreKit 2) | Required for paid features | Optional |
| Discovery | App Store search | None built-in |
| **Recommendation** | **Preferred** | Supplement for enterprise |

Given the educational / neuroscience audience and the existing sandbox + Privacy Manifest, **Mac App Store is the recommended primary channel**. The existing `com.apple.security.network.client` entitlement plus the educational `LSApplicationCategoryType` are already correct.

### StoreKit 2 Integration Skeleton

```swift
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    @Published var purchasedProductIDs: Set<String> = []

    static let simulatorProID = "com.apgi.appendix.simulator_pro"
    static let fullContentID  = "com.apgi.appendix.full_content"

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return }
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }
}
```

### Core ML On-Device AI Recommendation

The `CoreMLMemoryManager` infrastructure is ready. The logical next Core ML integration is a **semantic search model** to improve search relevance:

```swift
// Recommended: embed a lightweight sentence-encoder .mlpackage
// (e.g., distilbert-base-uncased quantized to int8, ~25 MB)
// Use Core ML's NaturalLanguage embedding pipeline:

import CoreML
import NaturalLanguage

class SemanticSearchEngine {
    private let embedding = NLEmbedding.wordEmbedding(for: .english)

    func similarity(query: String, candidate: String) -> Double {
        guard let qVec = embedding?.vector(for: query),
              let cVec = embedding?.vector(for: candidate) else { return 0 }
        // cosine similarity via Accelerate vDSP
        return cosineSimilarity(qVec, cVec)
    }
}
```

---

## Professional Debugging Integration

### LLDB Customization (`.lldbinit`)
```
# Print SwiftUI view hierarchy
command script import ~/lldbinit_helpers/swiftui_debug.py
command alias swiftui_tree expression -l swift -O -- UIWindow.key?.rootViewController
```

### `os_log` Subsystem Structure (Already Partially Implemented)
```swift
// Extend the existing OSLog subsystem with signposts for Instruments:
import os

let apgiLog = Logger(subsystem: "com.apgi.appendix", category: "performance")

func measureSimulatorTick() {
    let signposter = OSSignposter(logger: apgiLog)
    let state = signposter.beginInterval("SimulatorTick")
    defer { signposter.endInterval("SimulatorTick", state) }
    // … tick logic
}
```

### Instruments Validation Checklist
- [ ] Time Profiler: cold launch < 400 ms; warm navigation < 16 ms/frame
- [ ] Allocations: confirm no leak of `DispatchSourceMemoryPressure` objects (BUG-002)
- [ ] Leaks: confirm `NSEvent` monitor tokens retained (BUG-005)
- [ ] SwiftUI: confirm no forced-layout loops in `SidebarView`'s `LazyVStack`
- [ ] Energy Log: confirm `Timer.publish(every: 10)` for memory and `Timer.publish(every: 5)` for thermal are coalesced or replaced by system-driven signals

---

## Actionable Remediation Plan (Sprint Breakdown)

### Sprint 1 — Stabilize & Ship (P0/P1 Bugs, 1 week)

| Task | Owner | Effort |
|------|-------|--------|
| Fix BUG-001: replace `editMode` with `@State var isEditing` | iOS/macOS Dev | 2h |
| Fix BUG-002: move DispatchSource creation to `init()` | iOS/macOS Dev | 1h |
| Fix BUG-003: wire `detailView` into `NavigationSplitView` | iOS/macOS Dev | 3h |
| Fix BUG-004: remove hardcoded token; use CI secret | Security | 1h |
| Fix BUG-005: retain/cancel NSEvent monitor token | iOS/macOS Dev | 1h |
| Fix BUG-007: `@MainActor` for export/print methods | iOS/macOS Dev | 1h |
| Fix BUG-008: make `APGIState.initialize` throwing | iOS/macOS Dev | 2h |
| Add app icon (all required sizes) | Designer | 4h |
| Attach `onOpenURL` to `WindowGroup` scene | iOS/macOS Dev | 2h |
| Gate `ScreenshotAutomationRunner` behind `#if DEBUG` | iOS/macOS Dev | 30m |

### Sprint 2 — Performance & Correctness (P1/P2, 1 week)

| Task | Owner | Effort |
|------|-------|--------|
| Fix BUG-006: correct `getAvailableMemory()` via `vm_statistics64` | iOS/macOS Dev | 3h |
| Fix BUG-010: remove duplicate focus-mode overlay | iOS/macOS Dev | 1h |
| Fix BUG-011: remove unreachable catch blocks | iOS/macOS Dev | 30m |
| Fix BUG-012: migrate 25 `DispatchQueue.main` callsites to `@MainActor` | iOS/macOS Dev | 4h |
| Remove `KeyboardNavigableMainView` dead code (BUG-013) | iOS/macOS Dev | 2h |
| Fix `MemoryMonitor` `@MainActor` isolation (BUG-017) | iOS/macOS Dev | 1h |
| Implement `onContinueUserActivity` for Spotlight result navigation | iOS/macOS Dev | 3h |
| Enrich `InspectorView` with cross-references and related links | iOS/macOS Dev | 4h |

### Sprint 3 — Features & Polish (P2/P3, 2 weeks)

| Task | Owner | Effort |
|------|-------|--------|
| StoreKit 2: define products, implement `PurchaseManager`, add paywall UI | iOS/macOS Dev | 8h |
| Adaptive color system (asset catalog or `NSColor` dynamic provider) | Designer + Dev | 4h |
| VoiceOver / Accessibility audit with Accessibility Inspector | QA | 4h |
| Bind missing keyboard shortcuts (`⌘B` bookmarks, `⌘1–9` sections) | iOS/macOS Dev | 2h |
| Window state restoration for auxiliary NSWindow panels | iOS/macOS Dev | 3h |
| Simulator: replace `MLMultiArray` per-element access with Accelerate vDSP | iOS/macOS Dev | 6h |
| Fix SEC-002: narrow entitlements to user-selected only | Security | 30m |
| Fix SEC-005: set `NSFileProtectionComplete` on log file | iOS/macOS Dev | 1h |

### Sprint 4 — Distribution Readiness (1 week)

| Task | Owner | Effort |
|------|-------|--------|
| App Store Connect submission setup (screenshots, metadata, review notes) | PM + Designer | 8h |
| Notarization + stapling pipeline in CI | DevOps | 4h |
| StoreKit sandbox testing (restore purchases, receipt validation) | QA | 4h |
| Instruments baseline capture (Time Profiler, Allocations, Energy Log) | iOS/macOS Dev | 4h |
| Core ML semantic search model integration (optional for v1) | ML Eng | 10h |
| Final Privacy Manifest review against App Store submission requirements | Security | 2h |

---

## Appendix A — File-Level Quality Notes

| File | Lines | Notes |
|------|------:|-------|
| `ScreenshotAutomation.swift` | 2,415 | Largest file; hardcoded secret; should be moved to a separate `DebugTools` target |
| `APGISimulatorModule.swift` | 1,563 | Complex; good structure; `MLMultiArray` hot-path needs Accelerate replacement |
| `EnhancedContentCard.swift` | 998 | Large; consider splitting into `ContentCard`, `CardHeader`, `CardBody` sub-views |
| `NeuralCircuitDiagrams.swift` | 868 | Pure SwiftUI drawing; good pattern |
| `EnhancedInteractiveTimeline.swift` | 859 | Good use of `Canvas` API |
| `KeyboardNavigation.swift` | 572 | Contains dead `KeyboardNavigableMainView`; prune to ~250 lines after cleanup |
| `ErrorLogger.swift` | 457 | Production-quality; robust log rotation |
| `UserDefaultsValidator.swift` | 471 | Useful diagnostics tool |
| `KeychainHelper.swift` | ~200 | Excellent; AES-GCM with device-bound key |

---

## Appendix B — SwiftLint Configuration Gaps

The `.swiftlint.yml` disables `file_length`, `function_body_length`, `type_body_length`, `cyclomatic_complexity`, and `identifier_name`. While pragmatic for a rapid build, these should be re-enabled post-refactor with the following thresholds to prevent regression:

```yaml
file_length:
  warning: 400
  error: 800
  ignore_comment_only_lines: true

function_body_length:
  warning: 60
  error: 100

cyclomatic_complexity:
  warning: 10
  error: 15
```

The custom `no_print` rule is correctly defined and enforced. All log calls correctly go through `logInfo/logWarning/logError` wrappers.

---

*End of Report — APGI Appendix macOS Lead Architect Assessment*
*All code snippets are Swift 6 compatible unless otherwise noted.*
