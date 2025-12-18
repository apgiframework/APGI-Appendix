import SwiftUI

struct APGICommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open Glossary") {
                openGlossaryWindow()
            }
            .keyboardShortcut("g", modifiers: [.command])
            
            Button("Search Framework") {
                focusSearch()
            }
            .keyboardShortcut("f", modifiers: [.command])
        }

        CommandMenu("Demonstrations") {
            Button("APGI Simulator") {
                navigateToTab(.apgiSimulator)
            }

            Button("Ignition Timeline") {
                navigateToTab(.ignitionTimeline)
            }

            Button("Visualizations") {
                navigateToTab(.interactiveVisualizations)
            }

            Divider()

            Button("Open Timeline Window") {
                openTimelineWindow()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Button("Open Simulator Window") {
                openSimulatorWindow()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        }
        
        CommandMenu("Navigate") {
            Button("Biological Implementation") { 
                navigateToBiological()
            }
            .keyboardShortcut("1", modifiers: [.command])
            Button("Neuromodulators") { 
                navigateToNeuromodulators()
            }
            .keyboardShortcut("2", modifiers: [.command])
            Button("Clinical Translations") { 
                navigateToClinical()
            }
            .keyboardShortcut("3", modifiers: [.command])
            Divider()
            Button("Next Section") { 
                navigateToNext()
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command])
            Button("Previous Section") { 
                navigateToPrevious()
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command])
        }
        
        CommandMenu("View") {
            Button("Toggle Sidebar") { 
                toggleSidebar()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
            Button("Toggle Inspector") { 
                toggleInspector()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
            Divider()
            Button("Zoom In") { 
                zoomIn()
            }
            .keyboardShortcut("+", modifiers: [.command])
            Button("Zoom Out") { 
                zoomOut()
            }
            .keyboardShortcut("-", modifiers: [.command])
        }
        
        CommandMenu("Export") {
            Button("Export as PDF") { 
                exportPDF()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            Button("Export Current Section") { 
                exportCurrentSection()
            }
            Button("Copy Citation") { 
                copyCitation()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }
        
        CommandGroup(after: .help) {
            Button("APGI Framework Guide") { 
                openHelpGuide()
            }
            .keyboardShortcut("?", modifiers: [.command])
        }
    }
    
    // MARK: - Window Management Actions
    
    private func openTimelineWindow() {
        openWindow(id: "timeline")
    }

    private func openGlossaryWindow() {
        openWindow(id: "glossary")
    }
    
    private func openSimulatorWindow() {
        openWindow(id: "simulator")
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
    static let exportPDF = Notification.Name("exportPDF")
    static let exportCurrentSection = Notification.Name("exportCurrentSection")
    static let copyCitation = Notification.Name("copyCitation")
    static let openHelpGuide = Notification.Name("openHelpGuide")
}
