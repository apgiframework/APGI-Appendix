import AppKit
import Combine
import Foundation
import Network
import SwiftUI

// MARK: - URL Validator

@MainActor
class URLValidator: ObservableObject {
    static let shared = URLValidator()

    @Published var isValidating = false
    @Published var validationResults: [String: Bool] = [:]

    private init() {
    }

    // MARK: - URL Validation

    func validateURL(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }

        // Check if URL scheme is valid
        guard url.scheme == "http" || url.scheme == "https" else { return false }

        // For now, just check basic URL structure and domain
        // In a production app, you might want to make actual HTTP requests
        return self.isValidURLStructure(urlString)
    }

    private func isValidURLStructure(_ urlString: String) -> Bool {
        let urlPattern = #"^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$"#
        let urlTest = NSPredicate(format: "SELF MATCHES %@", urlPattern)
        return urlTest.evaluate(with: urlString)
    }

    // MARK: - Safe URL Opening

    func openSafely(_ urlString: String, fallback: (() -> Void)? = nil) {
        Task {
            self.isValidating = true

            let isValid = await validateURL(urlString)

            await MainActor.run {
                self.isValidating = false
                self.validationResults[urlString] = isValid

                if isValid {
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                }
                else {
                    // Show fallback or error
                    fallback?()
                    self.showURLError(urlString)
                }
            }
        }
    }

    private func showURLError(_ urlString: String) {
        let alert = NSAlert()
        alert.messageText = "Unable to Open Link"
        alert.informativeText = "The link \"\(urlString)\" is not available or invalid. Please check your internet connection or contact support."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Local Help Content

    func getLocalHelpContent() -> String {
        return """
        # APGI Appendix Help

        ## Getting Started

        Welcome to the APGI Appendix application! This comprehensive guide provides access to the Allostatic Precision-Gated Ignition framework for consciousness research.

        ## Main Features

        ### Navigation
        - **Sidebar**: Browse all sections organized by category
        - **Search**: Use ⌘F to quickly find content
        - **Keyboard Shortcuts**: ⌘1-9 for main sections, ⌘↑/↓ to navigate

        ### Content Sections
        - **Methodology**: Introduction to the APGI framework
        - **Neural Implementations**: Detailed neural circuit models
        - **Clinical Applications**: Medical and therapeutic applications
        - **Mathematical Models**: Formal mathematical framework
        - **Glossary**: Comprehensive terminology reference
        - **Bibliography**: Complete reference list

        ### Interactive Tools
        - **APGI Simulator**: Interactive neural modeling (⌘⇧M)
        - **Ignition Timeline**: Temporal dynamics visualization (⌘⇧T)
        - **Neural Circuit Explorer**: 3D interactive visualizations

        ### Reading Features
        - **Enhanced Layout**: Hero summaries and collapsible sections
        - **Related Links**: Cross-references between topics
        - **Bookmarks**: Save important pages
        - **Export**: PDF and text export capabilities

        ### Customization
        - **Settings**: Access with ⌘,
        - **Font Size**: ⌘++/-- to adjust
        - **Dark/Light Mode**: System preference support
        - **Focus Mode**: Distraction-free reading

        ## Getting Help

        For additional support:
        - Check the built-in glossary for terminology
        - Use the search function to find specific topics
        - Explore related links at the bottom of each section
        - Try the interactive simulator for hands-on learning

        ## Keyboard Shortcuts

        | Shortcut | Action |
        |----------|--------|
        | ⌘F | Search |
        | ⌘1-9 | Jump to sections |
        | ⌘↑/↓ | Navigate sections |
        | ⌘⇧M | Open Simulator |
        | ⌘⇧T | Open Timeline |
        | ⌘, | Settings |
        | ⌘0 | Reset zoom |
        | ⌘? | Quick help |

        ## Troubleshooting

        If you encounter issues:
        1. Check your internet connection for remote content
        2. Restart the application if performance is slow
        3. Use Settings > Network to configure remote content preferences
        4. Contact support through the app's issue reporting feature

        For the most up-to-date information, check for updates regularly in Settings.
        """
    }
}

// MARK: - Safe Link View

struct SafeLink: View {
    let title: String
    let urlString: String
    let fallbackTitle: String
    let fallbackAction: () -> Void

    @StateObject private var urlValidator = URLValidator.shared

    var body: some View {
        if self.urlValidator.validationResults[self.urlString] == false {
            Button(self.fallbackTitle) {
                self.fallbackAction()
            }
            .buttonStyle(.link)
            .foregroundColor(.orange)
        }
        else {
            Link(self.title, destination: URL(string: self.urlString)!)
        }
    }
}

// MARK: - URL Validation Manager

struct URLValidationManager: ViewModifier {
    let urlString: String
    let fallback: (() -> Void)?

    @StateObject private var urlValidator = URLValidator.shared

    func body(content: Content) -> some View {
        content
            .onAppear {
                Task {
                    let isValid = await urlValidator.validateURL(self.urlString)
                    await MainActor.run {
                        self.urlValidator.validationResults[self.urlString] = isValid
                    }
                }
            }
    }
}

extension View {
    func validateURL(_ urlString: String, fallback: (() -> Void)? = nil) -> some View {
        modifier(URLValidationManager(urlString: urlString, fallback: fallback))
    }
}
