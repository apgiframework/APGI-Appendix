import SwiftUI

struct ThermodynamicEfficiencyView: View {
    private let efficiencyBody = """

Physical Constraint | APGI Solution | Efficiency Argument | Alternative Solutions

Finite ATP budget (~10⁹ ATP/spike) | Sparse, event-driven processing via threshold (θₜ) | Only fire when prediction error exceeds threshold; saves 60-80% energy vs. continuous firing | Dense coding with lower per-spike cost? Analog computation?

Slow transmission (50-100ms delays) | Predictive processing via hierarchy | Compensate for delays by predicting future states | Reactive processing with faster signals (e.g., gap junctions, larger axons)?

Stochastic neurons (~50% synaptic reliability) | Bayesian population coding with precision-weighting (Π) | Integrate over populations, weight by confidence | Error correction codes? Redundancy without weighting?

Embodied system (survival-critical) | Interoceptive prioritization (β > 1) | Ensure body-state signals trigger fast responses | External threat prioritization? Balanced weighting?

Slow, unreliable components | Hierarchical temporal integration | Leverage multiple timescales for stability | Flat architectures with fast components?
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Thermodynamic and Evolutionary Efficiency")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text(efficiencyBody)
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
    ThermodynamicEfficiencyView()
}
