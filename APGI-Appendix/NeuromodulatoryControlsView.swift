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
    EnhancedContentCard(
      title: "Neuromodulatory Control System",
      content: self.controlsBody,
      category: .biological,
      hasDataTable: true
    )
    .padding()
  }
}

#Preview {
  NeuromodulatoryControlsView()
}
