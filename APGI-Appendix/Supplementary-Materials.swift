
import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct APGI_Supplementary_MaterialsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About APGI Supplementary Materials") {
                    showAboutDialog()
                }
            }
            
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    createNewWindow()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandMenu("File") {
                Button("Open...") {
                    showOpenDialog()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("Save") {
                    saveDocument()
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Save As...") {
                    saveDocumentAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Print...") {
                    printDocument()
                }
                .keyboardShortcut("p", modifiers: .command)
                
                Divider()
                
                Button("Close") {
                    closeWindow()
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            
            CommandMenu("Edit") {
                Button("Undo") {
                    undo()
                }
                .keyboardShortcut("z", modifiers: .command)
                
                Button("Redo") {
                    redo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Cut") {
                    cut()
                }
                .keyboardShortcut("x", modifiers: .command)
                
                Button("Copy") {
                    copy()
                }
                .keyboardShortcut("c", modifiers: .command)
                
                Button("Paste") {
                    paste()
                }
                .keyboardShortcut("v", modifiers: .command)
                
                Button("Paste and Match Style") {
                    pasteAndMatchStyle()
                }
                .keyboardShortcut("v", modifiers: [.command, .option, .shift])
                
                Divider()
                
                Button("Select All") {
                    selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)
                
                Divider()
                
                Button("Find") {
                    showFind()
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button("Find and Replace...") {
                    showFindAndReplace()
                }
                .keyboardShortcut("f", modifiers: [.command, .option])
            }
            
            CommandMenu("View") {
                Button("Zoom In") {
                    zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Zoom Out") {
                    zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Actual Size") {
                    actualSize()
                }
                .keyboardShortcut("0", modifiers: .command)
                
                Divider()
                
                Button("Enter Full Screen") {
                    toggleFullScreen()
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
            }
            
            CommandMenu("Window") {
                Button("Minimize") {
                    minimizeWindow()
                }
                .keyboardShortcut("m", modifiers: .command)
                
                Button("Zoom") {
                    zoomWindow()
                }
                
                Divider()
                
                Button("Bring All to Front") {
                    bringAllToFront()
                }
                .keyboardShortcut("~", modifiers: .command)
            }
            
            CommandMenu("Help") {
                Button("APGI Supplementary Materials Help") {
                    showHelp()
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Divider()
                
                Button("Visit Website") {
                    openWebsite()
                }
                
                Button("Report an Issue") {
                    reportIssue()
                }
                
                Divider()
                
                Button("Check for Updates...") {
                    checkForUpdates()
                }
            }
            
            CommandGroup(replacing: .appTermination) {
                Button("Quit APGI Supplementary Materials") {
                    quitApp()
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
    
    // Menu action implementations
    private func showAboutDialog() {
        let alert = NSAlert()
        alert.messageText = "APGI Supplementary Materials"
        alert.informativeText = "Version 1.0\n\nA comprehensive application for exploring consciousness theories, integrating Global Neuronal Workspace Theory with predictive processing through the APGI (Awareness-Precision-Gain-Ignition) model.\n\n© 2025"
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
        newWindow.title = "APGI Supplementary Materials"
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
