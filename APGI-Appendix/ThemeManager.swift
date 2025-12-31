import SwiftUI
import AppKit
import Combine
import Foundation

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { rawValue }
    
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
    
    @Published var selectedTheme: AppTheme = .system
    @Published var highContrastMode: Bool = false
    @AppStorage("contentFontSize") public var fontSize: Double = 15.0
    @AppStorage("enableAnimations") public var enableAnimations: Bool = true
    @AppStorage("sidebarVisible") public var sidebarVisible: Bool = true
    @AppStorage("focusModeEnabled") public var focusModeEnabled: Bool = false
    @AppStorage("autoSaveBookmarks") public var autoSaveBookmarks: Bool = true
    
    var backgroundColor: Color {
        switch selectedTheme {
        case .light:
            return Color(NSColor.controlBackgroundColor)
        case .dark:
            return Color(NSColor.controlBackgroundColor)
        case .system:
            return Color.primary.opacity(0.05)
        }
    }
    
    private init() {
        loadSettings()
        setupAutoSave()
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
        switch selectedTheme {
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
           let theme = AppTheme(rawValue: themeRaw) {
            selectedTheme = theme
        }
        
        highContrastMode = UserDefaults.standard.bool(forKey: "highContrastMode")
        fontSize = UserDefaults.standard.object(forKey: "contentFontSize") as? Double ?? 15.0
        enableAnimations = UserDefaults.standard.object(forKey: "enableAnimations") as? Bool ?? true
        sidebarVisible = UserDefaults.standard.object(forKey: "sidebarVisible") as? Bool ?? true
        focusModeEnabled = UserDefaults.standard.object(forKey: "focusModeEnabled") as? Bool ?? false
        autoSaveBookmarks = UserDefaults.standard.object(forKey: "autoSaveBookmarks") as? Bool ?? true
        
        applyTheme()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        UserDefaults.standard.set(highContrastMode, forKey: "highContrastMode")
        UserDefaults.standard.set(fontSize, forKey: "contentFontSize")
        UserDefaults.standard.set(enableAnimations, forKey: "enableAnimations")
        UserDefaults.standard.set(sidebarVisible, forKey: "sidebarVisible")
        UserDefaults.standard.set(focusModeEnabled, forKey: "focusModeEnabled")
        UserDefaults.standard.set(autoSaveBookmarks, forKey: "autoSaveBookmarks")
        
        UserDefaults.standard.synchronize()
    }
    
    func resetToDefaults() {
        fontSize = 15.0
        enableAnimations = true
        sidebarVisible = true
        focusModeEnabled = false
        autoSaveBookmarks = true
        selectedTheme = .system
        highContrastMode = false
        saveSettings()
    }
}

// MARK: - Theme Extension

extension View {
    func applyTheme() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}
