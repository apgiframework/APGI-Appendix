import SwiftUI
import Combine

@MainActor
final class NetworkSettingsManager: ObservableObject {
    @Published var enableRemoteContent = true
    @Published var useCellularData = true

    private let enableRemoteContentKey = "enableRemoteContent"
    private let useCellularDataKey = "useCellularData"

    init() {
        loadSettings()
    }

    private func loadSettings() {
        enableRemoteContent = UserDefaults.standard.bool(forKey: enableRemoteContentKey)
        if !UserDefaults.standard.object(forKey: enableRemoteContentKey).isNil {
            enableRemoteContent = true // Default to true for first launch
        }

        useCellularData = UserDefaults.standard.bool(forKey: useCellularDataKey)
        if !UserDefaults.standard.object(forKey: useCellularDataKey).isNil {
            useCellularData = true // Default to true
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(enableRemoteContent, forKey: enableRemoteContentKey)
        UserDefaults.standard.set(useCellularData, forKey: useCellularDataKey)
    }
}

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
    @StateObject private var networkSettings = NetworkSettingsManager()

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
            VStack(alignment: .leading, spacing: 20) {
                Text("Network")
                    .font(.title2.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Remote Content")
                        .font(.headline)

                    Toggle("Enable Remote Content", isOn: $networkSettings.enableRemoteContent)
                        .onChange(of: networkSettings.enableRemoteContent) { _, _ in
                            networkSettings.saveSettings()
                        }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Usage")
                        .font(.headline)

                    Toggle("Use Cellular Data", isOn: $networkSettings.useCellularData)
                        .onChange(of: networkSettings.useCellularData) { _, _ in
                            networkSettings.saveSettings()
                        }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Network Status")
                        .font(.headline)

                    HStack {
                        Image(systemName: NetworkManager.shared.isConnected ? "wifi" : "wifi.slash")
                            .foregroundStyle(NetworkManager.shared.isConnected ? .green : .red)
                        Text(NetworkManager.shared.isConnected ? "Connected" : "Offline")
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("App Updates")
                        .font(.headline)

                    UpdateCheckView()
                }

                Spacer()
            }
            .padding()
            .tabItem {
                Label("Network", systemImage: "network")
            }

            // About
            VStack(alignment: .leading, spacing: 20) {
                Text("About APGI Framework")
                    .font(.title2.bold())
                    .padding(.bottom)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Version: 1.0.0")
                    Text("Build: 2024.1")
                    Text("© 2024 APGI Research Team")
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
