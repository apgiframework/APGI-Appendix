import SwiftUI

struct BiologicalImplementationView: View {
    private let implementationBody = """

Variable | Neural Correlate & Mechanism

Sₜ | Ramping activity in PPC/IPS L2/3; recurrent excitation + SOM+ feedback

θₜ | NMDA-spike threshold in L5 apical dendrites; modulated by TRN (homeostasis), AHP/synaptic depression (refractoriness), LC-NE (urgency)

Bₜ | Metastable frontoparietal attractor; NMDA Ca²⁺ spike as sigmoid switch; α set by NMDA density + thalamic synchrony

Πₑ, Πᵢ | ACh ↑ Πₑ; NE ↑ Πᵢ; DA modulates reward salience

β | Insula-ACC connectivity strength; tuned by orexin for arousal state

Neuromodulator | APGI Parameter | LNN Mechanism | Receptor | Effect on τᵢ | Effect on θₜ | Effect on β | Conscious Experience | Clinical Example

ACh | ↑ Πₑ | Shorten τᵢᵉˣᵗᵉʳᵒ | M1 (Gq) | 200→100ms (extero) | —— | —— | Sensory clarity | AD: ↓ACh → cognitive fog

NE | ↓ θₜ, ↑ Πᵢ | Lower readout threshold; shorten τᵢⁱⁿᵗᵉʳᵒ | β, α1 | 150→60ms (intero) | 0.7→0.5 | — | Urgency, threat | Panic: ↑NE → overwhelming alarm

DA | Modulate β (reward) | Amplify reward channel gain; adjust β | D1, D2 | 200→80ms (reward) | — | 1.3→0.9 (pursuit) | Motivation, salience | Addiction: DA surge → cue dominance

5-HT | Stabilize θₜ, Π | Increase γ (homeostasis); narrow Π variance | 5-HT1A, 2A | Stabilize across channels | Stabilize at 0.7 | — | Emotional stability | OCD: ↓5-HT → rigid Π hierarchy

Histamine (TMN) | Set baseline θ₀ | Global excitability scaling | H1, H2 | Global: τᵢ/2 (awake) | θ₀: 0.95→0.70 | — | Wakefulness capacity | Narcolepsy: ↓histamine → θ₀=0.85

Orexin | Coordinate β, others | Context-dependent β; meta-modulation | OX1R, OX2R | Via coordinating others | Via coordinating NE, histamine | 1.3→0.8 (hunger) 1.3→1.7 (satiety) | Energy-state awareness | Narcolepsy-1: No orexin → β uncoordinated
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Biological Implementation: Explicit Neural Mapping")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text(implementationBody)
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
    BiologicalImplementationView()
}
