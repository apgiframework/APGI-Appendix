import SwiftUI

struct NeuromodulatoryControlsView: View {
    private let controlsBody = """

Neuromodulator | Primary APGI Parameter | Mechanism | Effect

ACh | ↑ Πₑ | M1 receptors ↑ signal-to-noise | Sharper sensory detail

NE | ↓ θₜ, ↑ Πᵢ | β-receptors ↑ NMDA, ↓ TRN | Urgency gating

DA | Modulates β (reward) | D1 receptors in PFC/striatum | Biases toward reward

5-HT | Stabilizes θₜ | 5-HT1A/2A balance | Prevents erratic ignition

Orexin | Modulates β (arousal) | Coordinates LC/BF/TMN | Tunes bias by state
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Neuromodulatory Control System")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text(controlsBody)
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
    NeuromodulatoryControlsView()
}
