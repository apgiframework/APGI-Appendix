import SwiftUI
import AppKit
import Combine

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
        // Load saved theme preferences
        if let themeRaw = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: themeRaw) {
            selectedTheme = theme
        }
        
        highContrastMode = UserDefaults.standard.bool(forKey: "highContrastMode")
        applyTheme()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        UserDefaults.standard.set(highContrastMode, forKey: "highContrastMode")
    }
}

// MARK: - Theme Extension

extension View {
    func applyTheme() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}
