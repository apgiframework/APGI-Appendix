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

  // MARK: - Trusted Domains
  private let trustedDomains = [
    "apgi-framework.org",
    "docs.apgi-framework.org",
    "apple.com",
    "github.com",
  ]

  private let trustedPathPrefixes = [
    "github.com": ["/apgi/"]
  ]

  func validateURL(_ urlString: String) async -> Bool {
    guard let url = URL(string: urlString) else { return false }

    // Enforce HTTPS for safety
    guard url.scheme == "https" else {
      logError(
        NSError(
          domain: "URLValidator", code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Insecure URL scheme: \(url.scheme ?? "unknown")"]),
        context: "URLValidator.validateURL")
      return false
    }

    // Check if the host is in the allow-list
    guard let host = url.host else { return false }

    let isTrustedHost = self.trustedDomains.contains { domain in
      host == domain || host.hasSuffix("." + domain)
    }

    if !isTrustedHost {
      logError(
        NSError(
          domain: "URLValidator", code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Untrusted domain blocked: \(host)"]),
        context: "URLValidator.validateURL")
      return false
    }

    // Check path-based trust if applicable
    if let prefixes = self.trustedPathPrefixes[host] {
      let urlPath = url.path.lowercased()
      let isTrustedPath = prefixes.contains { prefix in
        urlPath.hasPrefix(prefix.lowercased())
      }

      if !isTrustedPath {
        logError(
          NSError(
            domain: "URLValidator", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Untrusted path on trusted host: \(urlPath)"]),
          context: "URLValidator.validateURL")
        return false
      }
    }

    return true
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
        } else {
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
    alert.informativeText =
      "The link \"\(urlString)\" is not available or invalid. Please check your internet connection or contact support."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  // MARK: - Local Help Content

  func getLocalHelpContent() -> String {
    return HelpContentManager.shared.canonicalHelpMarkdown
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
    } else if let url = URL(string: self.urlString) {
      Link(self.title, destination: url)
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
