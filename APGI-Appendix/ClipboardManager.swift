import SwiftUI
import UniformTypeIdentifiers

/// Enhanced clipboard manager for Universal Clipboard support
class ClipboardManager {
  static let shared = ClipboardManager()

  private let pasteboard = NSPasteboard.general

  private init() {
  }

  // MARK: - Universal Clipboard Support

  /// Copy text content with Universal Clipboard support
  func copyText(_ text: String, source: String = "APGI Appendix") {
    self.pasteboard.clearContents()

    // Set multiple formats for better Universal Clipboard compatibility
    self.pasteboard.setString(text, forType: .string)

    // Add rich text format for better cross-platform support
    if let rtfData = createRTFFromText(text, source: source) {
      self.pasteboard.setData(rtfData, forType: .rtf)
    }

    logInfo("Copied text to clipboard: \(text.prefix(50))...", context: "ClipboardManager.copyText")
  }

  /// Copy structured content (citation, reference) with metadata
  func copyCitation(
    title: String, authors: String? = nil, year: String = "2024", source: String = "APGI Framework"
  ) {
    let citation = self.buildCitation(title: title, authors: authors, year: year, source: source)
    self.copyText(citation, source: source)

    // Add URL for deep linking if available
    if let citationURL = createCitationURL(title: title) {
      self.pasteboard.setString(citationURL.absoluteString, forType: .URL)
    }
  }

  /// Copy content section with rich formatting
  func copyContentSection(title: String, content: String, source: String = "APGI Framework") {
    self.pasteboard.clearContents()

    // Plain text
    self.pasteboard.setString(content, forType: .string)

    // HTML format for rich text applications
    if let htmlData = createHTMLFromContent(title: title, content: content) {
      self.pasteboard.setData(htmlData, forType: .html)
    }

    // RTF format for word processors
    if let rtfData = createRTFFromContent(title: title, content: content, source: source) {
      self.pasteboard.setData(rtfData, forType: .rtf)
    }

    logInfo(
      "Copied content section to clipboard: \(title)",
      context: "ClipboardManager.copyContentSection")
  }

  /// Get available content types in clipboard
  func availableTypes() -> [NSPasteboard.PasteboardType] {
    return self.pasteboard.types ?? []
  }

  /// Check if clipboard contains text content
  func hasTextContent() -> Bool {
    return self.pasteboard.types?.contains(.string) ?? false
  }

  /// Check if clipboard contains rich content
  func hasRichContent() -> Bool {
    let types = self.pasteboard.types ?? []
    return types.contains(.rtf) || types.contains(.html) || types.contains(.rtfd)
  }

  // MARK: - Helper Methods

  private func buildCitation(title: String, authors: String?, year: String, source: String) -> String {
    if let authors = authors, !authors.isEmpty {
      return "\(authors) (\(year)). \(title). \(source)."
    } else {
      return "\(source) (\(year)). \(title)."
    }
  }

  private func createCitationURL(title: String) -> URL? {
    let sanitizedTitle =
      title
      .replacingOccurrences(of: " ", with: "-")
      .replacingOccurrences(of: "[^A-Za-z0-9-]", with: "", options: .regularExpression)
      .lowercased()

    var components = URLComponents()
    components.scheme = "https"
    components.host = "apgi-framework.com"
    components.path = "/content/\(sanitizedTitle)"
    return components.url
  }

  private func createRTFFromText(_ text: String, source _: String) -> Data? {
    let attributedString = NSAttributedString(
      string: text,
      attributes: [
        .font: NSFont.systemFont(ofSize: 12),
        .foregroundColor: NSColor.textColor
      ]
    )

    return try? attributedString.data(
      from: NSRange(location: 0, length: attributedString.length),
      documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )
  }

  private func createHTMLFromContent(title: String, content: String) -> Data? {
    let html = """
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="utf-8">
          <title>\(title)</title>
      </head>
      <body>
          <h2>\(title)</h2>
          <p>\(content.replacingOccurrences(of: "\n", with: "</p><p>"))</p>
          <footer><em>Source: APGI Framework</em></footer>
      </body>
      </html>
      """
    return html.data(using: .utf8)
  }

  private func createRTFFromContent(title: String, content: String, source: String) -> Data? {
    let fullText = "\(title)\n\n\(content)\n\n— \(source)"

    let attributedString = NSAttributedString(
      string: fullText,
      attributes: [
        .font: NSFont.systemFont(ofSize: 12),
        .foregroundColor: NSColor.textColor
      ]
    )

    // Make title bold
    let mutableAttrString = NSMutableAttributedString(attributedString: attributedString)
    if let titleRange = fullText.range(of: title) {
      let nsRange = NSRange(titleRange, in: fullText)
      mutableAttrString.addAttribute(
        .font, value: NSFont.boldSystemFont(ofSize: 14), range: nsRange)
    }

    return try? mutableAttrString.data(
      from: NSRange(location: 0, length: mutableAttrString.length),
      documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )
  }
}
