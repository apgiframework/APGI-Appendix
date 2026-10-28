import AppKit
import Combine
import CoreSpotlight
import SwiftUI

struct EnhancedSettingsView: View {
  @StateObject private var themeManager = ThemeManager.shared

  var body: some View {
    SettingsView()
      .environmentObject(self.themeManager)
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

        APGIConnectionView()

        // Font Size
        VStack(alignment: .leading, spacing: 8) {
          Text("Font Size")
            .font(.headline)

          HStack {
            Slider(value: self.$themeManager.fontSize, in: 10...24, step: 1)
            Text("\(Int(self.themeManager.fontSize))pt")
              .frame(width: 40, alignment: .trailing)
          }
        }

        // Sidebar
        Toggle("Show Sidebar by Default", isOn: self.$themeManager.sidebarVisible)

        // Focus Mode
        Toggle("Enable Focus Mode", isOn: self.$themeManager.focusModeEnabled)

        // Animations
        Toggle("Enable Animations", isOn: self.$themeManager.enableAnimations)

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

          Picker("Theme", selection: self.$themeManager.selectedTheme) {
            ForEach(AppTheme.allCases) { theme in
              Text(theme.rawValue).tag(theme)
            }
          }
          .pickerStyle(.segmented)
        }

        // High Contrast
        Toggle("High Contrast Mode", isOn: self.$themeManager.highContrastMode)

        Divider()

        // Accent Color
        VStack(alignment: .leading, spacing: 8) {
          Text("Accent Color")
            .font(.headline)

          HStack(spacing: 12) {
            ForEach([Color.blue, .purple, .green, .orange, .pink], id: \.self) { color in
              Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                  Circle()
                    .stroke(Color.primary, lineWidth: 2)
                    .opacity(themeManager.selectedThemeColor == color ? 0.8 : 0)
                    .padding(-4)
                )
                .onTapGesture {
                  themeManager.selectedThemeColor = color
                }
            }
          }
        }

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

        Toggle("Auto-save Bookmarks", isOn: self.$themeManager.autoSaveBookmarks)

        Divider()

        Text("Your Bookmarks")
          .font(.headline)

        BookmarkListView()

        Spacer()
      }
      .padding()
      .tabItem {
        Label("Bookmarks", systemImage: "bookmark")
      }

      // Privacy & Data
      PrivacySettingsView()
        .tabItem {
          Label("Privacy", systemImage: "shield")
        }

      // Advanced/Diagnostics
      AdvancedSettingsView()
        .tabItem {
          Label("Advanced", systemImage: "gearshape.2")
        }

      // About
      VStack(alignment: .leading, spacing: 20) {
        Text("About APGI Appendix")
          .font(.title2.bold())
          .padding(.bottom)

        VStack(alignment: .leading, spacing: 8) {
          VersionInfoView()
          Text("Allostatic Precision-Gated Ignition")
          Text("Website: https://apgiframework.com")
          Text("API: https://api.apgiframework.com")
          Text("Source: https://github.com/apgiframework/APGI-Appendix")
            .font(.caption).textSelection(.enabled)
        }

        Divider()

        Text(
          "The Allostatic Precision-Gated Ignition (APGI) Framework provides a comprehensive computational model "
            + "of conscious access, integrating predictive coding, precision weighting, "
            + "and metabolic constraints."
        )
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
    // Clear any legacy bookmarks from UserDefaults
    UserDefaults.standard.removeObject(forKey: "bookmarkedTabs")
    UserDefaults.standard.removeObject(forKey: "APGIBookmarks")

    // Clear bookmark manager state
    NotificationCenter.default.post(name: .clearAllBookmarks, object: nil)
  }
}

struct BookmarkListView: View {
  @EnvironmentObject private var bookmarkManager: BookmarkManager

  var body: some View {
    if self.bookmarkManager.bookmarks.isEmpty {
      Text("No bookmarks yet")
        .foregroundStyle(.secondary)
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
    } else {
      List {
        ForEach(self.bookmarkManager.bookmarks, id: \.self) { bookmarkId in
          if let tab = Tab.allCases.first(where: { $0.id == bookmarkId }) {
            HStack {
              Image(systemName: tab.icon)
                .foregroundStyle(tab.category.color)
                .frame(width: 20, height: 20)

              VStack(alignment: .leading) {
                Text(tab.shortTitle)
                  .font(.headline)
                Text(tab.category.rawValue)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              Spacer()

              Image(systemName: "line.horizontal.3")
                .foregroundStyle(.tertiary)
                .font(.caption)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .contextMenu {
              Button("Remove Bookmark") {
                self.bookmarkManager.removeBookmark(tab)
              }
            }
          }
        }
        .onMove { indices, newOffset in
          self.bookmarkManager.bookmarks.move(fromOffsets: indices, toOffset: newOffset)
          self.bookmarkManager.saveBookmarks()
        }
      }
      .frame(height: min(CGFloat(self.bookmarkManager.bookmarks.count) * 60 + 20, 200))
      .listStyle(.plain)
    }
  }
}

// MARK: - Privacy Settings View

/// Privacy and data management settings
/// Provides granular control over data collection, retention, and privacy features
struct PrivacySettingsView: View {
  @AppStorage("enableSpotlightIndexing") var enableSpotlightIndexing = true
  @AppStorage("enableMemoryMonitoring") var enableMemoryMonitoring = true
  @AppStorage("redactSensitiveData") var redactSensitiveData = true
  @AppStorage("logRetentionDays") var logRetentionDays: Double = 30
  @State private var showingResetConfirmation = false
  @State private var showingClearConfirmation = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Privacy & Data")
        .font(.title2.bold())
        .padding(.bottom)

      // Note: Auto-update checks removed - app no longer depends on external API

      // Data Collection Controls
      VStack(alignment: .leading, spacing: 12) {
        Text("Data Collection")
          .font(.headline)

        Toggle("Enable Spotlight indexing", isOn: $enableSpotlightIndexing)
          .help("Allow content to appear in macOS Spotlight search results")

        Toggle("Enable memory monitoring", isOn: $enableMemoryMonitoring)
          .help("Track memory usage for performance diagnostics (uses minimal resources)")

        Toggle("Redact sensitive data in logs", isOn: $redactSensitiveData)
          .help("Automatically remove potentially sensitive information from error logs")

        VStack(alignment: .leading, spacing: 4) {
          Text("Log retention: \(Int(logRetentionDays)) days")
            .font(.subheadline)
          Slider(value: $logRetentionDays, in: 7...90, step: 1)
        }
      }

      Divider()

      // Data Management
      VStack(alignment: .leading, spacing: 12) {
        Text("Data Management")
          .font(.headline)

        VStack(alignment: .leading, spacing: 8) {
          Button("Clear All App Data...") {
            showingClearConfirmation = true
          }
          .foregroundColor(.red)
          .help("Remove all bookmarks, settings, and cached data")

          Text("This will reset bookmarks, appearance settings, and preferences to defaults. Log files and Spotlight index will also be cleared.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 8) {
          Button("Reset to Factory Defaults...") {
            showingResetConfirmation = true
          }
          .foregroundColor(.red)

          Text("Completely reset the app to its initial state. This action cannot be undone.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()
    }
    .padding()
    .frame(width: 500, height: 400)
    .alert("Clear All Data?", isPresented: $showingClearConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Clear", role: .destructive) {
        clearAllAppData()
      }
    } message: {
      Text("This will permanently delete all your bookmarks, settings, and log history. This action cannot be undone.")
    }
    .alert("Reset to Factory Defaults?", isPresented: $showingResetConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        resetToFactoryDefaults()
      }
    } message: {
      Text("This will completely reset the app to its initial state, removing all data and preferences. This action cannot be undone.")
    }
  }

  private func formatInterval(_ hours: Double) -> String {
    switch hours {
    case 1: return "Every hour"
    case 6: return "Every 6 hours"
    case 12: return "Every 12 hours"
    case 24: return "Every day"
    case 72: return "Every 3 days"
    case 168: return "Every week"
    default: return "Every \(Int(hours)) hours"
    }
  }

  private func clearAllAppData() {
    // Clear bookmarks
    NotificationCenter.default.post(name: .clearAllBookmarks, object: nil)

    // Clear settings
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: "contentFontSize")
    defaults.removeObject(forKey: "sidebarVisible")
    defaults.removeObject(forKey: "focusModeEnabled")
    defaults.removeObject(forKey: "highContrastMode")

    // Clear logs
    ErrorLogger.shared.clearLogs()

    // Apply log retention
    ErrorLogger.shared.applyRetentionPolicy()

    // Reset theme to defaults
    ThemeManager.shared.resetToDefaults()

    logInfo("All app data cleared by user", context: "PrivacySettingsView")
  }

  private func resetToFactoryDefaults() {
    // First clear all data
    clearAllAppData()

    // Remove all app-specific UserDefaults
    let bundleId = Bundle.main.bundleIdentifier ?? "com.apgi.appendix"
    UserDefaults.standard.removePersistentDomain(forName: bundleId)

    // Clear Spotlight index
    CSSearchableIndex.default().deleteAllSearchableItems()

    logInfo("Factory reset completed by user", context: "PrivacySettingsView")
  }
}

// MARK: - Advanced Settings View

/// Consolidated advanced/diagnostics settings for power users
/// Groups diagnostic tools, logs, and technical configuration
struct AdvancedSettingsView: View {
  @State private var selectedTab = 0

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Advanced & Diagnostics")
          .font(.title2.bold())

        Spacer()
      }
      .padding(.bottom, 4)

      // Sub-tab picker for advanced sections
      Picker("Section", selection: self.$selectedTab) {
        Text("Logs").tag(0)
        Text("Validation").tag(1)
        Text("Diagnostics").tag(2)
      }
      .pickerStyle(.segmented)
      .padding(.bottom, 12)

      // Content based on selected tab
      TabContent(selectedTab: self.selectedTab)

      Spacer()
    }
    .padding()
    .frame(width: 500, height: 360)
  }
}

// MARK: - Advanced Tab Content

private struct TabContent: View {
  let selectedTab: Int

  var body: some View {
    switch selectedTab {
    case 0:
      ErrorLoggerView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case 1:
      UserDefaultsValidationView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case 2:
      DiagnosticsView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    default:
      EmptyView()
    }
  }
}

// MARK: - Diagnostics View

/// Additional diagnostic tools for troubleshooting
struct DiagnosticsView: View {
  @State private var systemInfo = ""
  @State private var isGatheringInfo = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("System Diagnostics")
        .font(.headline)

      Text("Gather system information for troubleshooting and support requests.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      if !systemInfo.isEmpty {
        ScrollView {
          Text(systemInfo)
            .font(.system(size: 11, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
        }
        .frame(maxHeight: 150)

        HStack {
          Button("Copy to Clipboard") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(systemInfo, forType: .string)
          }
          .buttonStyle(.link)

          Spacer()

          Button("Clear") {
            systemInfo = ""
          }
          .buttonStyle(.link)
        }
      } else {
        VStack(spacing: 12) {
          Image(systemName: "stethoscope")
            .font(.system(size: 32))
            .foregroundStyle(.secondary)

          Text("No diagnostics gathered")
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 120)
      }

      Spacer()

      Button {
        gatherSystemInfo()
      } label: {
        if isGatheringInfo {
          ProgressView()
            .scaleEffect(0.8)
            .frame(width: 16, height: 16)
        } else {
          Text("Gather System Info")
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(isGatheringInfo)
      .frame(maxWidth: .infinity)
    }
  }

  private func gatherSystemInfo() {
    isGatheringInfo = true

    Task {
      var info: [String] = []

      // App info
      info.append("APGI Appendix Diagnostics")
      info.append(
        "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))"
      )
      info.append("")

      // Version info
      info.append("App Version: \(Bundle.main.appVersion)")
      let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
      info.append("Build: \(buildNumber)")
      info.append("")

      // System info
      let processInfo = ProcessInfo.processInfo
      info.append("macOS Version: \(processInfo.operatingSystemVersionString)")
      info.append("Processor: \(processInfo.processorCount) cores")
      info.append("Physical Memory: \(processInfo.physicalMemory / 1024 / 1024) MB")
      info.append("")

      // Performance metrics
      let perfReport = await PerformanceMonitor.shared.getPerformanceReport()
      info.append("Performance Metrics:")
      info.append(
        "  Average Inference: \(String(format: "%.3f", perfReport.averageInferenceTime))s")
      info.append("  Current FPS: \(String(format: "%.1f", perfReport.currentFPS))")
      info.append("  Memory Usage: \(String(format: "%.1f", perfReport.averageMemoryUsage))MB")
      info.append("")

      // User defaults summary
      info.append("Settings Summary:")
      info.append("  Theme: \(ThemeManager.shared.selectedTheme.rawValue)")
      info.append("  Font Size: \(Int(ThemeManager.shared.fontSize))pt")
      info.append("  Sidebar: \(ThemeManager.shared.sidebarVisible ? "Visible" : "Hidden")")
      info.append("")

      // Network status
      info.append("Network: \(NetworkManager.shared.isConnected ? "Connected" : "Disconnected")")
      if NetworkManager.shared.isConnected {
        let connectionType =
          NetworkManager.shared.connectionType.map { String(describing: $0) } ?? "Unknown"
        info.append("  Connection Type: \(connectionType)")
      }

      await MainActor.run {
        systemInfo = info.joined(separator: "\n")
        isGatheringInfo = false
      }
    }
  }
}

#Preview {
  SettingsView()
}
