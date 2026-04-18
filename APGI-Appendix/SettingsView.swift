import Combine
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

        Divider()

        Button("Clear All Bookmarks") {
          self.clearAllBookmarks()
        }
        .foregroundColor(.red)

        Button("Reset to Defaults") {
          self.themeManager.resetToDefaults()
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
        Text("About APGI Appendix")
          .font(.title2.bold())
          .padding(.bottom)

        VStack(alignment: .leading, spacing: 8) {
          VersionInfoView()
        }

        Divider()

        Text(
          "The Adaptive Precision-Gated Ignition (APGI) Framework provides a comprehensive computational model "
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
    // Post notification for BookmarkManager to handle clearing
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

#Preview {
  SettingsView()
}
