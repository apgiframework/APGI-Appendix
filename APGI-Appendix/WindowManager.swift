import AppKit
import SwiftUI

// MARK: - Window Manager

/// Centralized manager for auxiliary window lifecycle
/// Prevents duplicate windows and provides consistent window management
@MainActor
final class WindowManager {
  static let shared = WindowManager()

  private var helpWindow: NSWindow?
  private var quickStartWindow: NSWindow?
  private var whatsNewWindow: NSWindow?

  private init() {}

  // MARK: - Help Window

  func showHelpWindow(content: String) {
    if let existingWindow = helpWindow {
      existingWindow.makeKeyAndOrderFront(nil)
      return
    }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )

    window.title = "APGI Appendix Help"
    window.center()
    window.setFrameAutosaveName("HelpWindow")

    let helpView = ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(content)
          .font(.system(size: 14, design: .monospaced))
          .textSelection(.enabled)
          .padding()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }

    window.contentView = NSHostingView(rootView: helpView)
    window.delegate = self
    helpWindow = window

    window.makeKeyAndOrderFront(nil)
  }

  func closeHelpWindow() {
    helpWindow?.close()
    helpWindow = nil
  }

  // MARK: - Quick Start Window

  func showQuickStartWindow() {
    if let existingWindow = quickStartWindow {
      existingWindow.makeKeyAndOrderFront(nil)
      return
    }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )

    window.title = "Quick Start"
    window.contentView = NSHostingView(rootView: QuickStartPanel())
    window.center()
    window.delegate = self
    quickStartWindow = window

    window.makeKeyAndOrderFront(nil)
  }

  func closeQuickStartWindow() {
    quickStartWindow?.close()
    quickStartWindow = nil
  }

  // MARK: - What's New Window

  func showWhatsNewWindow() {
    if let existingWindow = whatsNewWindow {
      existingWindow.makeKeyAndOrderFront(nil)
      return
    }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )

    window.title = "What's New"
    window.contentView = NSHostingView(rootView: WhatsNewView())
    window.center()
    window.delegate = self
    whatsNewWindow = window

    window.makeKeyAndOrderFront(nil)
  }

  func closeWhatsNewWindow() {
    whatsNewWindow?.close()
    whatsNewWindow = nil
  }

  // MARK: - Window State Queries

  var isHelpWindowOpen: Bool { helpWindow != nil }
  var isQuickStartWindowOpen: Bool { quickStartWindow != nil }
  var isWhatsNewWindowOpen: Bool { whatsNewWindow != nil }

  // MARK: - Cleanup

  func closeAllAuxiliaryWindows() {
    closeHelpWindow()
    closeQuickStartWindow()
    closeWhatsNewWindow()
  }
}

// MARK: - NSWindowDelegate

extension WindowManager: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    guard let window = notification.object as? NSWindow else { return }

    if window === helpWindow {
      helpWindow = nil
    } else if window === quickStartWindow {
      quickStartWindow = nil
    } else if window === whatsNewWindow {
      whatsNewWindow = nil
    }
  }
}
