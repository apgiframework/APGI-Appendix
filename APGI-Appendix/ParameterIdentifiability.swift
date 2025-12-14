import SwiftUI

struct ParameterIdentifiabilityView: View {
    private let identifiabilityBody = """

Parameter Recovery and Recoverability Tiers

Reduced, Structurally Identifiable Model

- Sₜ (precision-weighted surprise signal)
- θₜ (baseline ignition threshold)
- Πₑ⁰ (baseline exteroceptive precision)
- β·Πᵢ⁰ (baseline weighted interoceptive precision as a product term)
- α (sigmoid steepness)
- τ (surprise decay constant, fixed at 200 ms based on empirical literature)
- γ (homeostatic recovery rate)
- δ (post-ignition elevation magnitude)
- σ (noise amplitude)
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parameter Identifiability and the Reduced Model")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text(identifiabilityBody)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .textSelection(.enabled)
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.separator.opacity(0.25), lineWidth: 1)
                )
            }
            .padding()
        }
    }
}

#Preview {
    ParameterIdentifiabilityView()
}
