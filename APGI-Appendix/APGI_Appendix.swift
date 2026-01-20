import SwiftUI
import AppKit
import Combine

// MARK: - Updated Main App Entry Point

@main
struct APGIAppendixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var navigationManager = KeyboardNavigationManager.shared

    var body: some Scene {
        WindowGroup("APGI Framework") {
            OnboardingTourView()
            .applyTheme()
            .environmentObject(themeManager)
            .environmentObject(onboardingManager)
            .environmentObject(navigationManager)
        }
        .commands {
            APGICommands()

            CommandGroup(replacing: .help) {
                Button("APGI Help") {
                    showHelp()
                }
                .keyboardShortcut("?", modifiers: [.command, .shift])

                Divider()

                Button("Take a Tour") {
                    onboardingManager.startOnboarding()
                }

                Button("What's New") {
                    showWhatsNew()
                }

                Button("Quick Start Guide") {
                    showQuickStart()
                }

                Divider()

                Button("Keyboard Shortcuts") {
                    navigationManager.showKeyboardShortcuts = true
                }
                .keyboardShortcut("/", modifiers: [.command])
            }
        }

        Window("Neural Timeline", id: "timeline") {
            IgnitionTimelineView()
                .applyTheme()
                .environmentObject(themeManager)
        }
        .defaultSize(width: 1000, height: 800)

        Window("Glossary", id: "glossary") {
            GlossaryView()
                .applyTheme()
                .environmentObject(themeManager)
        }
        .defaultSize(width: 1000, height: 800)
        .defaultPosition(.trailing)

        Window("APGI Simulator", id: "simulator") {
            APGISimulatorView()
                .applyTheme()
                .environmentObject(themeManager)
        }
        .defaultSize(width: 1000, height: 800)

        Settings {
            EnhancedSettingsView()
                .applyTheme()
                .environmentObject(themeManager)
        }
    }

    private func showHelp() {
        URLValidator.shared.openSafely("https://apgi-framework.com/help") {
            // Fallback: show local help content
            showLocalHelp()
        }
    }
    
    private func showLocalHelp() {
        let helpContent = URLValidator.shared.getLocalHelpContent()
        
        let helpWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        helpWindow.title = "APGI Appendix Help"
        helpWindow.center()
        helpWindow.setFrameAutosaveName("HelpWindow")
        
        let helpView = ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(helpContent)
                    .font(.system(size: 14, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        helpWindow.contentView = NSHostingView(rootView: helpView)
        helpWindow.makeKeyAndOrderFront(nil)
    }

    private func showWhatsNew() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "What's New"
        window.contentView = NSHostingView(rootView: WhatsNewView())
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func showQuickStart() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Quick Start"
        window.contentView = NSHostingView(rootView: QuickStartPanel())
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupAppearance()
        
        // Initialize screenshot automation if running in screenshot mode
        #if DEBUG
        ScreenshotAutomationRunner.run()
        #endif
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
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
                    themeManager.selectedTheme = theme
                } label: {
                    HStack {
                        Image(systemName: theme.icon)
                        Text(theme.rawValue)
                        if themeManager.selectedTheme == theme {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Toggle("High Contrast", isOn: $themeManager.highContrastMode)
        } label: {
            Image(systemName: themeManager.selectedTheme.icon)
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
            switch tab {
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
