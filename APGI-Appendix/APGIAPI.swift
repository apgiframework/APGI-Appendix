import Foundation
import Combine
import SwiftUI

// Public reference requests carry no bookmarks, settings, or simulation data.
enum APGIAPI {
  static let baseURL = URL(string: "https://api.apgiframework.com")!
  static let session = URLSession(configuration: .ephemeral, delegate: SameHostRedirects(), delegateQueue: nil)

  static func metadata(using session: URLSession = session) async throws -> Data {
    var request = URLRequest(url: baseURL.appendingPathComponent("v1/meta"))
    request.timeoutInterval = 20
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    let (data, response) = try await session.data(for: request)
    try validateMetadata(data, response: response)
    return data
  }

  static func validateMetadata(_ data: Data, response: URLResponse) throws {
    guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
    guard response.statusCode == 200 else { throw APIError.http(response.statusCode) }
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      ["researcher", "osf", "zenodo", "code", "web", "licences", "release_state"].allSatisfy({ object[$0] is [String: Any] })
    else { throw APIError.invalidMetadata }
  }

  enum APIError: LocalizedError {
    case http(Int), invalidMetadata
    var errorDescription: String? {
      switch self {
      case .http(let status): "APGI API returned HTTP \(status). Reference content remains available offline."
      case .invalidMetadata: "The API returned an unsupported metadata response."
      }
    }
  }
}

private final class SameHostRedirects: NSObject, URLSessionTaskDelegate, Sendable {
  nonisolated func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) {
    let url = request.url
    completionHandler(url?.scheme == "https" && url?.host == "api.apgiframework.com"
      && url?.user == nil && url?.password == nil && (url?.port == nil || url?.port == 443) ? request : nil)
  }
}

@MainActor
final class APGIConnection: ObservableObject {
  static let shared = APGIConnection()
  @Published var status = "Not checked"
  @Published var isChecking = false
  private var checkedAtLaunch = false

  func checkOnce() async {
    guard !checkedAtLaunch else { return }
    checkedAtLaunch = true
    await check()
  }

  func check() async {
    guard !isChecking else { return }
    isChecking = true
    defer { isChecking = false }
    do {
      _ = try await APGIAPI.metadata()
      status = "Connected — public metadata verified"
    } catch {
      status = error.localizedDescription
    }
  }
}

struct APGIConnectionView: View {
  @ObservedObject private var connection = APGIConnection.shared
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("APGI API").font(.headline)
      Text(APGIAPI.baseURL.absoluteString).textSelection(.enabled)
      Text(connection.status).font(.caption).foregroundStyle(.secondary)
      Button(connection.isChecking ? "Checking…" : "Check connection") {
        Task { await connection.check() }
      }.disabled(connection.isChecking)
      Text("Only public metadata is requested. Bookmarks and simulation data are not sent.")
        .font(.caption).foregroundStyle(.secondary)
    }
  }
}
