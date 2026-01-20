import SwiftUI
import Combine

extension Optional {
    var isNil: Bool {
        self == nil
    }
}

struct EnhancedSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        SettingsView()
            .environmentObject(themeManager)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView {
            // General Settings
            VStack(alignment: .leading, spacing: 20) {
                Text("General")
                    .font(.title2.bold())
                    .padding(.bottom)

                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size")
                        .font(.headline)

                    HStack {
                        Slider(value: $themeManager.fontSize, in: 10...24, step: 1)
                        Text("\(Int(themeManager.fontSize))pt")
                            .frame(width: 40, alignment: .trailing)
                    }
                }

                // Sidebar
                Toggle("Show Sidebar by Default", isOn: $themeManager.sidebarVisible)

                // Focus Mode
                Toggle("Enable Focus Mode", isOn: $themeManager.focusModeEnabled)

                // Animations
                Toggle("Enable Animations", isOn: $themeManager.enableAnimations)

                Spacer()
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gear")
            }

            // Appearance
            VStack(alignment: .leading, spacing: 20) {
                Text("Appearance")
                    .font(.title2.bold())
                    .padding(.bottom)

                // Theme Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.headline)

                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // High Contrast
                Toggle("High Contrast Mode", isOn: $themeManager.highContrastMode)

                Spacer()
            }
            .padding()
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }

            // Bookmarks
            VStack(alignment: .leading, spacing: 20) {
                Text("Bookmarks")
                    .font(.title2.bold())
                    .padding(.bottom)

                Toggle("Auto-save Bookmarks", isOn: $themeManager.autoSaveBookmarks)

                Button("Clear All Bookmarks") {
                    clearAllBookmarks()
                }
                .foregroundColor(.red)

                Divider()

                Button("Reset to Defaults") {
                    themeManager.resetToDefaults()
                }
                .foregroundColor(.orange)

                Spacer()
            }
            .padding()
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark")
            }

            // Network
            NetworkSettingsView()
                .tabItem {
                    Label("Network", systemImage: "wifi")
                }

            // Error Logs
            ErrorLoggerView()
                .tabItem {
                    Label("Logs", systemImage: "doc.text")
                }

            // Validation
            UserDefaultsValidationView()
                .tabItem {
                    Label("Validation", systemImage: "checkmark.shield")
                }

            // About
            VStack(alignment: .leading, spacing: 20) {
                Text("About APGI Framework")
                    .font(.title2.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 8) {
                    VersionInfoView()
                }

                Divider()

                Text("The Adaptive Precision-Gated Ignition (APGI) Framework provides a comprehensive computational model " +
                     "of conscious access, integrating predictive coding, precision weighting, " +
                     "and metabolic constraints.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 500, height: 400)
    }

    private func clearAllBookmarks() {
        // Clear bookmarks from UserDefaults
        UserDefaults.standard.removeObject(forKey: "bookmarkedTabs")

        // Clear bookmark manager state if available
        NotificationCenter.default.post(name: .clearAllBookmarks, object: nil)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let clearAllBookmarks = Notification.Name("clearAllBookmarks")
}

#Preview {
    SettingsView()
}
