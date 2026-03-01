import AppKit
import Combine
import Foundation
import SwiftUI

class WindowStateRestorationManager: ObservableObject {
    static let shared = WindowStateRestorationManager()

    private let userDefaults = UserDefaults.standard
    private let windowStateKey = "WindowStateRestoration"

    @Published var restoredWindows: [NSWindow] = []

    private init() {
        self.setupRestoration()
    }

    // MARK: - Window State Management

    func saveWindowState(_ window: NSWindow) {
        let state = WindowState(
            frame: window.frame,
            isMinimized: window.isMiniaturized,
            isVisible: window.isVisible,
            title: window.title,
            identifier: window.identifier?.rawValue ?? UUID().uuidString
        )

        var savedStates = self.loadWindowStates()
        savedStates[state.identifier] = state

        if let data = try? JSONEncoder().encode(savedStates) {
            self.userDefaults.set(data, forKey: self.windowStateKey)
        }
    }

    func restoreWindowStates() {
        guard let data = userDefaults.data(forKey: windowStateKey),
              let states = try? JSONDecoder().decode([String: WindowState].self, from: data)
        else {
            return
        }

        for (_, state) in states {
            self.restoreWindow(state: state)
        }
    }

    private func restoreWindow(state: WindowState) {
        let window = NSWindow(
            contentRect: state.frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = state.title
        window.identifier = NSUserInterfaceItemIdentifier(state.identifier)
        window.setFrame(state.frame, display: true)

        if state.isMinimized {
            window.miniaturize(nil)
        }
        else if state.isVisible {
            window.makeKeyAndOrderFront(nil)
        }

        self.restoredWindows.append(window)
    }

    private func loadWindowStates() -> [String: WindowState] {
        guard let data = userDefaults.data(forKey: windowStateKey),
              let states = try? JSONDecoder().decode([String: WindowState].self, from: data)
        else {
            return [:]
        }
        return states
    }

    // MARK: - Setup and Lifecycle

    private func setupRestoration() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.windowDidMove(_:)),
            name: NSWindow.didMoveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.windowDidResize(_:)),
            name: NSWindow.didResizeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.windowDidMiniaturize(_:)),
            name: NSWindow.didMiniaturizeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.windowDidDeminiaturize(_:)),
            name: NSWindow.didDeminiaturizeNotification,
            object: nil
        )
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        self.saveWindowState(window)
    }

    @objc private func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        self.saveWindowState(window)
    }

    @objc private func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        self.saveWindowState(window)
    }

    @objc private func windowDidMiniaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        self.saveWindowState(window)
    }

    @objc private func windowDidDeminiaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        self.saveWindowState(window)
    }

    // MARK: - Cleanup

    func clearSavedStates() {
        self.userDefaults.removeObject(forKey: self.windowStateKey)
        self.restoredWindows.removeAll()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Window State Model

struct WindowState: Codable {
    let frame: NSRect
    let isMinimized: Bool
    let isVisible: Bool
    let title: String
    let identifier: String

    enum CodingKeys: String, CodingKey {
        case frameX, frameY, frameWidth, frameHeight
        case isMinimized, isVisible, title, identifier
    }

    init(frame: NSRect, isMinimized: Bool, isVisible: Bool, title: String, identifier: String) {
        self.frame = frame
        self.isMinimized = isMinimized
        self.isVisible = isVisible
        self.title = title
        self.identifier = identifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let frameX = try container.decode(CGFloat.self, forKey: .frameX)
        let frameY = try container.decode(CGFloat.self, forKey: .frameY)
        let frameWidth = try container.decode(CGFloat.self, forKey: .frameWidth)
        let frameHeight = try container.decode(CGFloat.self, forKey: .frameHeight)

        self.frame = NSRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)
        self.isMinimized = try container.decode(Bool.self, forKey: .isMinimized)
        self.isVisible = try container.decode(Bool.self, forKey: .isVisible)
        self.title = try container.decode(String.self, forKey: .title)
        self.identifier = try container.decode(String.self, forKey: .identifier)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.frame.origin.x, forKey: .frameX)
        try container.encode(self.frame.origin.y, forKey: .frameY)
        try container.encode(self.frame.size.width, forKey: .frameWidth)
        try container.encode(self.frame.size.height, forKey: .frameHeight)
        try container.encode(self.isMinimized, forKey: .isMinimized)
        try container.encode(self.isVisible, forKey: .isVisible)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.identifier, forKey: .identifier)
    }
}

// MARK: - NSWindow Extension for Restoration

extension NSWindow {
    func enableRestoration() {
        WindowStateRestorationManager.shared.saveWindowState(self)
    }

    func restoreFromSavedState() {
        // This would be called when creating a new window that should restore its state
        WindowStateRestorationManager.shared.restoreWindowStates()
    }
}

// MARK: - SwiftUI Integration

struct RestorableWindow<Content: View>: View {
    let content: Content
    let windowTitle: String
    let windowIdentifier: String

    @StateObject private var restorationManager = WindowStateRestorationManager.shared

    init(title: String, identifier: String, @ViewBuilder content: () -> Content) {
        self.windowTitle = title
        self.windowIdentifier = identifier
        self.content = content()
    }

    var body: some View {
        self.content
            .frame(minWidth: 800, minHeight: 600)
            .background(
                WindowAccessor(
                    title: self.windowTitle,
                    identifier: self.windowIdentifier,
                    onWindowCreated: { window in
                        window.enableRestoration()
                    }
                )
            )
    }
}

struct WindowAccessor: NSViewRepresentable {
    let title: String
    let identifier: String
    let onWindowCreated: (NSWindow) -> Void

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            if let window = view.window {
                window.title = self.title
                window.identifier = NSUserInterfaceItemIdentifier(self.identifier)
                self.onWindowCreated(window)
            }
        }

        return view
    }

    func updateNSView(_: NSView, context _: Context) {
    }
}

// MARK: - App Delegate Integration

class RestorableAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        // Restore window states after app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WindowStateRestorationManager.shared.restoreWindowStates()
        }
    }

    func applicationWillTerminate(_: Notification) {
        // Save all window states before termination
        for window in NSApplication.shared.windows {
            WindowStateRestorationManager.shared.saveWindowState(window)
        }
    }
}
