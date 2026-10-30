import CryptoKit
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

  // Vector produced by apgi-api's app/services/update_feed.py with a fixed TEST-ONLY key.
  private static let feedKeyId = "test-only"
  private static let feedPublicKeyX963 =
    "BKLE3L6waQmznUZpFqMlz2eXvgzyaIQOLxE6+xLlwbcR150umF1txkQmD6t7SiwY2jR6rW/MjIx70JEfWbxRJHk="
  private static let feedSignature =
    "Eut+pOkdJVxlWVlCj4WBF0pd8zGJVkOBxEXYqJQdsbrG476cNoOW0lTOKXhWCoM59eXjq5gLx+XIxfke0KHmyA=="

  private func signedFeed(version: String = "2.1.0", keyId: String = feedKeyId,
    algorithm: String = "P256-ECDSA", signature: String? = feedSignature,
    downloadURL: String = "https://apgiframework.com/downloads/APGI-Appendix-2.1.0.zip"
  ) -> UpdateResponse {
    UpdateResponse(latestVersion: version, minimumVersion: "2.0.0",
      releaseNotes: "Signed test release", downloadURL: downloadURL,
      releaseDate: "2026-11-01", isCritical: false, signature: signature, keyId: keyId,
      algorithm: algorithm)
  }

  private func testVerifier() throws -> UpdateSignatureVerifier {
    let raw = try XCTUnwrap(Data(base64Encoded: Self.feedPublicKeyX963))
    let key = try P256.Signing.PublicKey(x963Representation: raw)
    return UpdateSignatureVerifier(trustedPublicKeys: [Self.feedKeyId: key])
  }

  func testServerSignedFeedVerifiesEndToEnd() async throws {
    let verifier = try testVerifier()
    let result = await verifier.validateUpdate(signedFeed(), signature: Self.feedSignature,
      keyId: Self.feedKeyId)
    XCTAssertTrue(result.isValid, result.errorReason ?? "")
  }

  func testTamperedUnknownKeyAndAlgorithmAreRejected() async throws {
    let verifier = try testVerifier()
    let tampered = await verifier.validateUpdate(signedFeed(version: "9.9.9"),
      signature: Self.feedSignature, keyId: Self.feedKeyId)
    XCTAssertFalse(tampered.isValid)
    let unknownKey = await verifier.validateUpdate(signedFeed(keyId: "other"),
      signature: Self.feedSignature, keyId: "other")
    XCTAssertFalse(unknownKey.isValid)
    let badAlgorithm = await verifier.validateUpdate(signedFeed(algorithm: "Ed25519"),
      signature: Self.feedSignature, keyId: Self.feedKeyId)
    XCTAssertFalse(badAlgorithm.isValid)
    let badDownload = await verifier.validateUpdate(
      signedFeed(downloadURL: "https://evil.example/downloads/app.zip"),
      signature: Self.feedSignature, keyId: Self.feedKeyId)
    XCTAssertFalse(badDownload.isValid)
  }

  func testProductionVerifierTrustsNoKeysUntilReviewed() async {
    let result = await UpdateSignatureVerifier.shared.validateUpdate(signedFeed(),
      signature: Self.feedSignature, keyId: Self.feedKeyId)
    XCTAssertFalse(result.isValid)
  }

  func testGateTableRendersPendingResults() throws {
    let table = try IdentifiabilityGateTable.load()
    XCTAssertEqual(table.gates.map(\.id), ["K7a", "K7c"])
    XCTAssertTrue(table.gates.allSatisfy { $0.status == "PENDING" })
    XCTAssertTrue(table.renderedText.contains("dynamic ignition threshold"))
    XCTAssertFalse(table.renderedText.contains("Structurally Identifiable Model"))
  }

  func testPublishedGateTableRendersResultsAndD2() throws {
    let json = #"""
      {"version":"2027.1","evidenceStatus":"published","source":"gate-table.yaml",
       "d2Decision":"D2: framework repository","gates":[
       {"id":"K7a","status":"PASS","description":"Structural identifiability","result":"rank 7/7"},
       {"id":"K7c","status":"FAIL","description":"Parameter recovery","result":"r below 0.8"}]}
      """#
    let table = try JSONDecoder().decode(IdentifiabilityGateTable.self, from: Data(json.utf8))
    XCTAssertTrue(table.isPublished)
    XCTAssertTrue(table.renderedText.contains("K7c: FAIL"))
    XCTAssertTrue(table.renderedText.contains("D2 decision: D2: framework repository"))
    XCTAssertTrue(table.renderedText.contains("θₜ is the dynamic ignition threshold. θ₀ is its baseline."))
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
