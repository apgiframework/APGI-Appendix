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

  func testURLPolicy() async {
    let allowed = await URLValidator.shared.validateURL("https://api.apgiframework.com/v1/meta")
    XCTAssertTrue(allowed)
    for url in ["http://api.apgiframework.com", "https://api.apgiframework.com.evil.example", "https://user@api.apgiframework.com", "https://github.com/untrusted/repo", "https://api.apgiframework.com:8080"] {
      let allowed = await URLValidator.shared.validateURL(url)
      XCTAssertFalse(allowed, url)
    }
  }

  func testUpdateVerificationFailsClosed() async {
    let update = UpdateResponse(latestVersion: "99.0", minimumVersion: nil,
      releaseNotes: "untrusted", downloadURL: "https://apgiframework.com/downloads/app.zip",
      releaseDate: nil, isCritical: false, signature: nil, keyId: nil, algorithm: "P256-ECDSA")
    let result = await UpdateSignatureVerifier.shared.validateUpdate(update, signature: nil, keyId: nil)
    XCTAssertFalse(result.isValid)
    let insecure = await UpdateSignatureVerifier.shared.validateDownloadURL("http://apgiframework.com/downloads/app.zip")
    XCTAssertFalse(insecure)
  }

  func testGateTableRendersPendingResults() throws {
    let table = try IdentifiabilityGateTable.load()
    XCTAssertEqual(table.gates.map(\.id), ["K7a", "K7c"])
    XCTAssertTrue(table.gates.allSatisfy { $0.status == "PENDING" })
    XCTAssertTrue(table.renderedText.contains("dynamic ignition threshold"))
    XCTAssertFalse(table.renderedText.contains("Structurally Identifiable Model"))
  }

  func testIgnitionSignFixtures() throws {
    let url = try XCTUnwrap(Bundle.main.url(forResource: "ignition-fixtures", withExtension: "json"))
    let fixtures = try JSONDecoder().decode(IgnitionFixtures.self, from: Data(contentsOf: url))
    let core = APGICore(config: APGIConfiguration())
    for v in fixtures.vectors {
      XCTAssertEqual(core.computeIgnitionProbability(surprise: v.surprise, threshold: v.threshold,
        alpha: v.gamma_sig), v.expected, accuracy: fixtures.tolerance)
    }
  }

  func testMetadataContractAndServerErrors() throws {
    let url = APGIAPI.baseURL.appendingPathComponent("v1/meta")
    let ok = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
    let failed = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil))
    let data = Data(#"{"researcher":{},"osf":{},"zenodo":{},"code":{},"web":{},"licences":{},"release_state":{}}"#.utf8)
    XCTAssertNoThrow(try APGIAPI.validateMetadata(data, response: ok))
    XCTAssertThrowsError(try APGIAPI.validateMetadata(data, response: failed))
    XCTAssertThrowsError(try APGIAPI.validateMetadata(Data("{}".utf8), response: ok))
    XCTAssertThrowsError(try APGIAPI.validateMetadata(Data("not JSON".utf8), response: ok))
  }
  func testBuiltAppRegistersDeepLinksAndReferencePack() throws {
    let types = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])
    XCTAssertTrue(types.contains { ($0["CFBundleURLSchemes"] as? [String])?.contains("apgi-appendix") == true })
    XCTAssertNotNil(Bundle.main.url(forResource: "reference-pack", withExtension: "json"))
  }
}

private struct IgnitionFixtures: Decodable {
  struct Vector: Decodable {
    let surprise: Float
    let threshold: Float
    let gamma_sig: Float
    let expected: Float
  }
  let tolerance: Float
  let vectors: [Vector]
}
