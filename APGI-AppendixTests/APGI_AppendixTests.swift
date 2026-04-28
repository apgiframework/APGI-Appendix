import XCTest

@testable import APGI_Appendix

@MainActor
final class APGI_AppendixTests: XCTestCase {

  func testDeepLinkCreation() throws {
    let tab = Tab.methodology
    let url = DeepLinkManager.shared.createURL(for: tab)

    XCTAssertNotNil(url)
    XCTAssertEqual(url?.scheme, "apgi-appendix")
    XCTAssertEqual(url?.host, "content")
    XCTAssertEqual(
      url?.query,
      "section=\(tab.rawValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    )
  }

  func testDeepLinkParsing() throws {
    let tab = Tab.mathematicalModel
    let urlString =
      "apgi-appendix://content?section=\(tab.rawValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    let url = URL(string: urlString)
    guard let url = url else {
      XCTFail("Failed to create URL from string: \(urlString)")
      return
    }

    let parsedTab = DeepLinkManager.shared.parseTab(from: url)
    XCTAssertEqual(parsedTab, tab)
  }

  func testInvalidDeepLinkParsing() throws {
    let invalidUrls = [
      "http://google.com",
      "apgi-appendix://wrong-host?section=Methodology",
      "wrong-scheme://content?section=Methodology",
      "apgi-appendix://content?wrong-param=Methodology",
      "apgi-appendix://content?section=NonExistentSection"
    ]

    for urlString in invalidUrls {
      guard let url = URL(string: urlString) else {
        XCTFail("Failed to create URL from string: \(urlString)")
        continue
      }
      XCTAssertNil(DeepLinkManager.shared.parseTab(from: url), "Should be nil for: \(urlString)")
    }
  }

  func testAllTabsDeepLinkRoundTrip() throws {
    for tab in Tab.allCases {
      let url = DeepLinkManager.shared.createURL(for: tab)
      XCTAssertNotNil(url)
      guard let url = url else {
        XCTFail("URL should not be nil for tab: \(tab.rawValue)")
        continue
      }
      let parsedTab = DeepLinkManager.shared.parseTab(from: url)
      XCTAssertEqual(parsedTab, tab, "Round trip failed for: \(tab.rawValue)")
    }
  }
}
