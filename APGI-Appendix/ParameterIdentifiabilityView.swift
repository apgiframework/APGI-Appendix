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
        EnhancedContentCard(
            title: "Parameter Identifiability and the Reduced Model",
            content: identifiabilityBody,
            category: .mathematical,
            hasDataTable: false
        )
        .padding()
    }
}

#Preview {
    ParameterIdentifiabilityView()
}
