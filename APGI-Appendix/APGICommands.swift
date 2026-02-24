import SwiftUI

struct APGICommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open Glossary") {
                self.openGlossaryWindow()
            }
            .keyboardShortcut("g", modifiers: [.command])

            Button("Search Framework") {
                self.focusSearch()
            }
            .keyboardShortcut("f", modifiers: [.command])
        }

        CommandMenu("Demonstrations") {
            Button("APGI Simulator") {
                self.navigateToTab(.apgiSimulator)
            }

            Button("Ignition Timeline") {
                self.navigateToTab(.ignitionTimeline)
            }

            Divider()

            Button("Open Timeline Window") {
                self.openTimelineWindow()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Button("Open Simulator Window") {
                self.openSimulatorWindow()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        }

        CommandMenu("Navigate") {
            Button("Biological Implementation") {
                self.navigateToBiological()
            }
            .keyboardShortcut("1", modifiers: [.command])
            Button("Neuromodulators") {
                self.navigateToNeuromodulators()
            }
            .keyboardShortcut("2", modifiers: [.command])
            Button("Clinical Translations") {
                NotificationCenter.default.post(name: .navigateToSection, object: "clinical")
            }
            .keyboardShortcut("3", modifiers: [.command])
            Button("Mathematical Framework") {
                NotificationCenter.default.post(name: .navigateToSection, object: "mathematical")
            }
            .keyboardShortcut("4", modifiers: [.command])
            Button("Psychiatric Disorders") {
                NotificationCenter.default.post(name: .navigateToSection, object: "psychiatric")
            }
            .keyboardShortcut("5", modifiers: [.command])

            Divider()

            Button("Next Section") {
                NotificationCenter.default.post(name: .navigateNext, object: nil)
            }
            .keyboardShortcut("]", modifiers: [.command])

            Button("Previous Section") {
                NotificationCenter.default.post(name: .navigatePrevious, object: nil)
            }
            .keyboardShortcut("[", modifiers: [.command])
        }

        CommandMenu("View") {
            Button("Toggle Sidebar") {
                self.toggleSidebar()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])

            Button("Toggle Inspector") {
                self.toggleInspector()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])

            Divider()

            Button("Zoom In") {
                self.zoomIn()
            }
            .keyboardShortcut("+", modifiers: [.command])

            Button("Zoom Out") {
                self.zoomOut()
            }
            .keyboardShortcut("-", modifiers: [.command])

            Button("Reset Zoom") {
                self.zoomReset()
            }
            .keyboardShortcut("0", modifiers: [.command])
        }

        CommandMenu("Export") {
            Button("Export as PDF") {
                self.exportPDF()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])

            Button("Export Current Section") {
                self.exportCurrentSection()
            }
            .keyboardShortcut("e", modifiers: [.command])

            Divider()

            Button("Copy Citation") {
                self.copyCitation()
            }
            .keyboardShortcut("c", modifiers: [.command, .option])
        }

        CommandMenu("Help") {
            Button("APGI Help Guide") {
                self.openHelpGuide()
            }
            .keyboardShortcut("?", modifiers: [.command])

            Button("Online Documentation") {
                self.openOnlineHelp()
            }

            Divider()

            Button("Check for Updates") {
                self.checkForUpdates()
            }

            Divider()

            Button("Report Issue") {
                self.reportIssue()
            }
        }

        CommandGroup(after: .help) {
            Button("Online Documentation") {
                self.openOnlineHelp()
            }

            Divider()

            Button("Report Issue") {
                self.reportIssue()
            }
        }
    }

    // MARK: - Window Management Actions

    private func openTimelineWindow() {
        self.openWindow(id: "timeline")
    }

    private func openGlossaryWindow() {
        self.openWindow(id: "glossary")
    }

    private func openSimulatorWindow() {
        self.openWindow(id: "simulator")
    }

    private func focusSearch() {
        NotificationCenter.default.post(name: .focusSearch, object: nil)
    }

    private func navigateToTab(_ tab: Tab) {
        NotificationCenter.default.post(name: .navigateToTab, object: tab)
    }

    // MARK: - Navigation Actions

    private func navigateToBiological() {
        NotificationCenter.default.post(name: .navigateToSection, object: "biological")
    }

    private func navigateToNeuromodulators() {
        NotificationCenter.default.post(name: .navigateToSection, object: "neuromodulators")
    }

    private func navigateToClinical() {
        NotificationCenter.default.post(name: .navigateToSection, object: "clinical")
    }

    private func navigateToNext() {
        NotificationCenter.default.post(name: .navigateNext, object: nil)
    }

    private func navigateToPrevious() {
        NotificationCenter.default.post(name: .navigatePrevious, object: nil)
    }

    // MARK: - View Actions

    private func toggleSidebar() {
        NotificationCenter.default.post(name: .toggleSidebar, object: nil)
    }

    private func toggleInspector() {
        NotificationCenter.default.post(name: .toggleInspector, object: nil)
    }

    private func zoomIn() {
        NotificationCenter.default.post(name: .zoomIn, object: nil)
    }

    private func zoomOut() {
        NotificationCenter.default.post(name: .zoomOut, object: nil)
    }

    private func zoomReset() {
        NotificationCenter.default.post(name: .zoomReset, object: nil)
    }

    // MARK: - Export Actions

    private func exportPDF() {
        NotificationCenter.default.post(name: .exportPDF, object: nil)
    }

    private func exportCurrentSection() {
        NotificationCenter.default.post(name: .exportCurrentSection, object: nil)
    }

    private func copyCitation() {
        NotificationCenter.default.post(name: .copyCitation, object: nil)
    }

    // MARK: - Help Actions

    private func openHelpGuide() {
        NotificationCenter.default.post(name: .openHelpGuide, object: nil)
    }

    private func openOnlineHelp() {
        if let url = URL(string: "https://docs.apgi-framework.org") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkForUpdates() {
        NotificationCenter.default.post(name: .checkForUpdates, object: nil)
    }

    private func reportIssue() {
        if let url = URL(string: "https://github.com/apgi/framework/issues") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let focusSearch = Notification.Name("focusSearch")
    static let navigateToSection = Notification.Name("navigateToSection")
    static let navigateToTab = Notification.Name("navigateToTab")
    static let navigateNext = Notification.Name("navigateNext")
    static let navigatePrevious = Notification.Name("navigatePrevious")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let toggleInspector = Notification.Name("toggleInspector")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let zoomReset = Notification.Name("zoomReset")
    static let exportPDF = Notification.Name("exportPDF")
    static let exportCurrentSection = Notification.Name("exportCurrentSection")
    static let copyCitation = Notification.Name("copyCitation")
    static let openHelpGuide = Notification.Name("openHelpGuide")
    static let checkForUpdates = Notification.Name("checkForUpdates")
}
