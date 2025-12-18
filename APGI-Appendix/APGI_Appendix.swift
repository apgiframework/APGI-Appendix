import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct APGI_AppendixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("APGI Framework") {
            MainContentView()
        }
        .commands {
            APGICommands()
        }

        Window("Neural Timeline", id: "timeline") {
            IgnitionTimelineView()
        }
        .defaultSize(width: 1200, height: 800)

        Window("Glossary", id: "glossary") {
            GlossaryView()
        }
        .defaultSize(width: 600, height: 800)
        .defaultPosition(.trailing)

        Settings {
            SettingsView()
        }
    }
    
    // Menu action implementations
    private func showAboutDialog() {
        let alert = NSAlert()
        alert.messageText = "APGI Appendix"
        alert.informativeText = "Version 1.0\n\nA comprehensive application for exploring consciousness theories, integrating Global Neuronal Workspace Theory with predictive processing through APGI (Awareness-Precision-Gain-Ignition) model.\n\n© 2025"
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    private func createNewWindow() {
        // Create a new window with ContentView
        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "APGI Appendix"
        newWindow.contentView = NSHostingView(rootView: ContentView())
        newWindow.makeKeyAndOrderFront(nil)
    }
    
    private func showOpenDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            print("File selected: \(panel.url?.path ?? "")")
        }
    }
    
    private func saveDocument() {
        print("Save document")
    }
    
    private func saveDocumentAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText, .pdf]
        if panel.runModal() == .OK {
            print("Save to: \(panel.url?.path ?? "")")
        }
    }
    
    private func printDocument() {
        print("Print document")
    }
    
    private func closeWindow() {
        if let window = NSApplication.shared.keyWindow {
            window.close()
        }
    }
    
    private func undo() {
        if let responder = NSApplication.shared.keyWindow?.firstResponder as? NSTextView {
            responder.undoManager?.undo()
        }
    }
    
    private func redo() {
        if let responder = NSApplication.shared.keyWindow?.firstResponder as? NSTextView {
            responder.undoManager?.redo()
        }
    }
    
    private func cut() {
        NSPasteboard.general.clearContents()
        if let responder = NSApplication.shared.keyWindow?.firstResponder as? NSTextView {
            responder.cut(nil)
        }
    }
    
    private func copy() {
        NSPasteboard.general.clearContents()
        if let responder = NSApplication.shared.keyWindow?.firstResponder as? NSTextView {
            responder.copy(nil)
        }
    }
    
    private func paste() {
        if let responder = NSApplication.shared.keyWindow?.firstResponder as? NSTextView {
            responder.paste(nil)
        }
    }
    
    private func pasteAndMatchStyle() {
        if let responder = NSApplication.shared.keyWindow?.firstResponder as? NSTextView {
            responder.pasteAsPlainText(nil)
        }
    }
    
    private func selectAll() {
        if let responder = NSApplication.shared.keyWindow?.firstResponder as? NSTextView {
            responder.selectAll(nil)
        }
    }
    
    private func showFind() {
        print("Show find")
    }
    
    private func showFindAndReplace() {
        print("Show find and replace")
    }
    
    private func zoomIn() {
        print("Zoom in")
    }
    
    private func zoomOut() {
        print("Zoom out")
    }
    
    private func actualSize() {
        print("Actual size")
    }
    
    private func toggleFullScreen() {
        if let window = NSApplication.shared.keyWindow {
            window.toggleFullScreen(nil)
        }
    }
    
    private func minimizeWindow() {
        if let window = NSApplication.shared.keyWindow {
            window.miniaturize(nil)
        }
    }
    
    private func zoomWindow() {
        if let window = NSApplication.shared.keyWindow {
            window.zoom(nil)
        }
    }
    
    private func bringAllToFront() {
        NSApplication.shared.arrangeInFront(nil)
    }
    
    private func showHelp() {
        print("Show help")
    }
    
    private func openWebsite() {
        if let url = URL(string: "https://example.com") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func reportIssue() {
        if let url = URL(string: "https://github.com/example/issues") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func checkForUpdates() {
        print("Check for updates")
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Additional setup if needed
    }
}
