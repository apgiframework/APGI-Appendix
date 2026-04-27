import AppKit
import Combine
import SwiftUI

// MARK: - Updated Main App Entry Point

@main
struct APGIAppendixApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var themeManager = ThemeManager.shared
  @StateObject private var onboardingManager = OnboardingManager.shared
  @StateObject private var navigationManager = KeyboardNavigationManager.shared
  @StateObject private var memoryMonitor = MemoryMonitor.shared
  @StateObject private var bookmarkManager = BookmarkManager.shared
  @AppStorage("enableSpotlightIndexing") private var enableSpotlightIndexing = true
  @AppStorage("enableMemoryMonitoring") private var enableMemoryMonitoring = true

  init() {
    // StateObjects are automatically initialized by SwiftUI
    // Don't access them here to avoid creating new instances
  }

  var body: some Scene {
    WindowGroup("APGI Appendix") {
      OnboardingTourView()
        .applyTheme()
        .environmentObject(self.themeManager)
        .environmentObject(self.onboardingManager)
        .environmentObject(self.navigationManager)
        .environmentObject(self.memoryMonitor)
        .environmentObject(self.bookmarkManager)
        .onAppear {
          // Conditionally start memory monitoring based on user preferences
          if self.enableMemoryMonitoring {
            // Defer startup to reduce launch time impact
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
              self.memoryMonitor.startMonitoring(interval: 30.0)
            }
          }

          // Conditionally index content for Spotlight based on preferences
          if self.enableSpotlightIndexing {
            // Defer indexing to reduce launch time impact
            Task { @MainActor in
              try? await Task.sleep(nanoseconds: 3_000_000_000)
              SpotlightManager.shared.indexAllContent()
            }
          }
        }
    }
    .commands {
      APGICommands()

      CommandGroup(replacing: .help) {
        Button("APGI Help") {
          self.showHelp()
        }
        .keyboardShortcut("?", modifiers: [.command, .shift])

        Divider()

        Button("Take a Tour") {
          self.onboardingManager.startOnboarding()
        }

        Button("What's New") {
          self.showWhatsNew()
        }

        Button("Quick Start Guide") {
          self.showQuickStart()
        }

        Divider()

        Button("Keyboard Shortcuts") {
          self.navigationManager.showKeyboardShortcuts = true
        }
        .keyboardShortcut("/", modifiers: [.command])
      }
    }

    Window("Neural Timeline", id: "timeline") {
      IgnitionTimelineView()
        .applyTheme()
        .environmentObject(self.themeManager)
        .environmentObject(self.bookmarkManager)
    }
    .defaultSize(width: 1000, height: 800)

    Window("Glossary", id: "glossary") {
      GlossaryView()
        .applyTheme()
        .environmentObject(self.themeManager)
        .environmentObject(self.bookmarkManager)
    }
    .defaultSize(width: 1000, height: 800)
    .defaultPosition(.trailing)

    Window("APGI Simulator", id: "simulator") {
      APGISimulatorView()
        .applyTheme()
        .environmentObject(self.themeManager)
        .environmentObject(self.bookmarkManager)
    }
    .defaultSize(width: 1000, height: 800)

    Settings {
      EnhancedSettingsView()
        .applyTheme()
        .environmentObject(self.themeManager)
        .environmentObject(self.bookmarkManager)
    }
  }

  private func showHelp() {
    URLValidator.shared.openSafely("https://apgi-framework.com/help") {
      // Fallback: show local help content
      self.showLocalHelp()
    }
  }

  private func showLocalHelp() {
    let helpContent = URLValidator.shared.getLocalHelpContent()
    WindowManager.shared.showHelpWindow(content: helpContent)
  }

  private func showWhatsNew() {
    WindowManager.shared.showWhatsNewWindow()
  }

  private func showQuickStart() {
    WindowManager.shared.showQuickStartWindow()
  }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    self.setupAppearance()

    // Initialize screenshot automation if running in screenshot mode
    ScreenshotAutomationRunner.run()
  }

  func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
    return .terminateNow
  }

  func application(
    _: NSApplication, continue userActivity: NSUserActivity,
    restorationHandler _: @escaping ([NSUserActivityRestoring]) -> Void
  ) -> Bool {
    // Handle incoming Handoff activities
    guard userActivity.activityType == "com.apgi.appendix.content" else {
      return false
    }

    logInfo(
      "Received Handoff activity: \(userActivity.activityType)",
      context: "AppDelegate.continueUserActivity")

    // Post notification for MainContentView to handle
    NotificationCenter.default.post(
      name: NSNotification.Name("HandleHandoffActivity"),
      object: userActivity
    )

    return true
  }

  func application(_: NSApplication, open urls: [URL]) {
    // Handle deep-link URLs
    guard let url = urls.first else { return }

    logInfo("Received deep link URL: \(url.absoluteString)", context: "AppDelegate.openURLs")

    // Post notification for MainContentView to handle
    NotificationCenter.default.post(
      name: NSNotification.Name("HandleDeepLink"),
      object: url
    )
  }

  private func setupAppearance() {
    ThemeManager.shared.applyTheme()
  }
}

// MARK: - Theme Toggle Button

struct ThemeToggleButton: View {
  @ObservedObject private var themeManager = ThemeManager.shared

  var body: some View {
    Menu {
      ForEach(AppTheme.allCases) { theme in
        Button {
          self.themeManager.selectedTheme = theme
        } label: {
          HStack {
            Image(systemName: theme.icon)
            Text(theme.rawValue)
            if self.themeManager.selectedTheme == theme {
              Image(systemName: "checkmark")
            }
          }
        }
      }

      Divider()

      Toggle("High Contrast", isOn: self.$themeManager.highContrastMode)
    } label: {
      Image(systemName: self.themeManager.selectedTheme.icon)
    }
    .help("Appearance Settings")
  }
}

// MARK: - Updated Tab Content View with Enhanced Cards

struct EnhancedTabContentView: View {
  let tab: Tab
  @Binding var selectedTab: Tab

  var body: some View {
    Group {
      switch self.tab {
      case .methodology:
        MethodologyView()
      case .mathematicalModel:
        MathematicalModelView()
      case .apgiMapping:
        ApgiMappingView()
      case .parameterIdentifiability:
        ParameterIdentifiabilityView()
      case .biologicalImplementation:
        BiologicalImplementationView()
      case .neuromodulatorEffects:
        NeuromodulatorEffectsView()
      case .neuromodulatoryImplementation:
        NeuromodulatoryImplementationView()
      case .explicitNeuromodulator:
        ExplicitNeuromodulatorsView()
      case .mappingCognitiveToApgi:
        MappingCognitiveToApgiView()
      case .apgiToCognitive:
        ApgiToCognitiveView()
      case .psychologicalStates:
        PsychologicalStatesView()
      case .apgiToPsyState:
        ApgiToPsyStateView()
      case .ignitionTimeline:
        IgnitionTimelineView()
      case .neuromodulatoryControl:
        NeuromodulatoryControlsView()
      case .psychiatricDisorders:
        PsychiatricDisordersView()
      case .disordersConditions:
        DisordersConditionsView()
      case .apgiStatement:
        APGIStatementView()
      case .lifeStages:
        LifeStagesView()
      case .thermodynamicEfficiency:
        ThermodynamicEfficiencyView()
      case .epistemicStandards:
        EpistemicStandardsView()
      case .bibliography:
        BibliographyView()
      case .glossary:
        GlossaryView()
      case .apgiSimulator:
        APGISimulatorView()
      }
    }
  }
}

// MARK: - Preview

#Preview("Main App") {
  MainContentView()
    .environmentObject(ThemeManager.shared)
    .environmentObject(OnboardingManager.shared)
    .environmentObject(KeyboardNavigationManager.shared)
    .frame(width: 1200, height: 800)
}
