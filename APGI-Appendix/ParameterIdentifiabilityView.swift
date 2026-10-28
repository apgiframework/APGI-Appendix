import Foundation
import SwiftUI

struct IdentifiabilityGateTable: Decodable {
  struct Gate: Decodable {
    let id: String
    let status: String
    let description: String
  }
  let version: String
  let evidenceStatus: String
  let gates: [Gate]

  var renderedText: String {
    "Gate table \(version) • \(evidenceStatus)\n\n" + gates.map {
      "\($0.id): \($0.status) — \($0.description)"
    }.joined(separator: "\n\n") + "\n\nθₜ is the dynamic ignition threshold. θ₀ is its baseline. gamma_sig denotes sigmoid steepness. No identifiability or recovery claim is enabled until the qualified framework contract and published gate results are available."
  }

  static func load() throws -> Self {
    guard let url = Bundle.main.url(forResource: "gate-table", withExtension: "json") else {
      throw CocoaError(.fileNoSuchFile)
    }
    return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
  }
}

struct ParameterIdentifiabilityView: View {
  var body: some View {
    EnhancedContentCard(
      title: "Parameter Identifiability and the Reduced Model",
      content: (try? IdentifiabilityGateTable.load().renderedText)
        ?? "Gate results unavailable. Identifiability and parameter recovery are not established.",
      category: .mathematical,
      hasDataTable: false
    ).padding()
  }
}
