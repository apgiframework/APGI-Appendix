import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var selectedTheme: AppTheme = .system {
        didSet {
            // Immediately apply theme change across all windows
            self.applyTheme()
            // Save settings immediately for persistence
            UserDefaults.standard.set(self.selectedTheme.rawValue, forKey: "selectedTheme")
            UserDefaults.standard.synchronize()
        }
    }

    @Published var highContrastMode: Bool = false
    @AppStorage("contentFontSize") var fontSize: Double = 15.0
    @AppStorage("enableAnimations") var enableAnimations: Bool = true
    @AppStorage("sidebarVisible") var sidebarVisible: Bool = true
    @AppStorage("focusModeEnabled") var focusModeEnabled: Bool = false
    @AppStorage("autoSaveBookmarks") var autoSaveBookmarks: Bool = true

    var backgroundColor: Color {
        switch self.selectedTheme {
        case .light:
            return Color(NSColor.controlBackgroundColor)
        case .dark:
            return Color(NSColor.controlBackgroundColor)
        case .system:
            return Color.primary.opacity(0.05)
        }
    }

    private init() {
        self.loadSettings()
        self.setupAutoSave()
    }

    private func setupAutoSave() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveSettings()
        }
    }

    func applyTheme() {
        switch self.selectedTheme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }

    private func loadSettings() {
        if let themeRaw = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: themeRaw)
        {
            self.selectedTheme = theme
        }

        self.highContrastMode = UserDefaults.standard.bool(forKey: "highContrastMode")
        self.fontSize = UserDefaults.standard.object(forKey: "contentFontSize") as? Double ?? 15.0
        self.enableAnimations = UserDefaults.standard.object(forKey: "enableAnimations") as? Bool ?? true
        self.sidebarVisible = UserDefaults.standard.object(forKey: "sidebarVisible") as? Bool ?? true
        self.focusModeEnabled = UserDefaults.standard.object(forKey: "focusModeEnabled") as? Bool ?? false
        self.autoSaveBookmarks = UserDefaults.standard.object(forKey: "autoSaveBookmarks") as? Bool ?? true

        self.applyTheme()
    }

    func saveSettings() {
        UserDefaults.standard.set(self.selectedTheme.rawValue, forKey: "selectedTheme")
        UserDefaults.standard.set(self.highContrastMode, forKey: "highContrastMode")
        UserDefaults.standard.set(self.fontSize, forKey: "contentFontSize")
        UserDefaults.standard.set(self.enableAnimations, forKey: "enableAnimations")
        UserDefaults.standard.set(self.sidebarVisible, forKey: "sidebarVisible")
        UserDefaults.standard.set(self.focusModeEnabled, forKey: "focusModeEnabled")
        UserDefaults.standard.set(self.autoSaveBookmarks, forKey: "autoSaveBookmarks")

        UserDefaults.standard.synchronize()
    }

    func resetToDefaults() {
        self.fontSize = 15.0
        self.enableAnimations = true
        self.sidebarVisible = true
        self.focusModeEnabled = false
        self.autoSaveBookmarks = true
        self.selectedTheme = .system
        self.highContrastMode = false
        self.saveSettings()
    }
}

// MARK: - Theme Extension

extension View {
    func applyTheme() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}
