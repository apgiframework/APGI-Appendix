import Foundation
import SwiftUI

struct IdentifiabilityGateTable: Decodable {
  struct Gate: Decodable {
    let id: String
    let status: String
    let description: String
    let result: String?
  }
  let version: String
  let evidenceStatus: String
  let source: String?
  let d2Decision: String?
  let gates: [Gate]

  /// True only for a table generated from the published gate-table.yaml.
  var isPublished: Bool { source == "gate-table.yaml" && evidenceStatus == "published" }

  var renderedText: String {
    let rows = gates.map { gate -> String in
      let outcome = gate.result.map { " Result: \($0)" } ?? ""
      return "\(gate.id): \(gate.status) — \(gate.description)\(outcome)"
    }.joined(separator: "\n\n")
    let d2 = d2Decision.map { "\n\nD2 decision: \($0)" } ?? ""
    let notation =
      "θₜ is the dynamic ignition threshold. θ₀ is its baseline. gamma_sig denotes sigmoid steepness."
    let caveat =
      isPublished
      ? "Outcomes above are those published in gate-table.yaml; this view does not extend them."
      : "No identifiability or recovery claim is enabled until the qualified framework contract and published gate results are available."
    return "Gate table \(version) • \(evidenceStatus)\n\n" + rows + d2 + "\n\n\(notation) \(caveat)"
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
