import SwiftUI

struct MappingCognitiveToApgiView: View {
    var body: some View {
        ScrollView {
            Text("""

Mapping Cognitive Constructs → APGI

Control Parameters encompass neuromodulator-regulated factors, including the ignition threshold (θ₀), exteroceptive precision (Πₑ), interoceptive precision (Πᵢ) and urgency (gain modulation). These parameters set the foundational conditions for cognitive processing. Neural Representations involve latent hypotheses—whether perceptual, interoceptive or mnemonic—that compete for global ignition and are driven by precision-weighted prediction error minimization, a process that determines which hypotheses gain prominence in conscious experience. Output Behaviors refer to the observable outcomes of integrated conscious content, manifesting as decisions, reports or actions and reflect the culmination of the cognitive processes.

COGNITIVE CONSTRUCT | APGI CONSTRUCT | ONTOLOGICAL LEVEL | MECHANISTIC INTERPRETATION & NEUROMODULATORY BASIS

Attention | Salience-triggered ignition | Output Behavior | Result of anterior insula–ACC detecting high-precision prediction errors (Π·δ); ignition gates access to frontoparietal global workspace.

Salience | Precision-weighted prediction error (Π·δ) | Neural Representation | Magnitude of Π·δ; encoded in salience network (AI/ACC); determines competitive eligibility for ignition.

Cognitive Load | θ₀ modulation (Ignition Threshold) | Control Parameter | Elevated load → increased θ₀ (e.g., via reduced tonic DA or elevated adenosine); reflects resource depletion in frontoparietal circuits.

Bias Sensitivity | Prior strength in predictive coding | Neural Representation | Reflects over-weighted high-level priors (e.g., via 5-HT₁ₐ receptors); resists updating even with high Π·δ.

Sensory Precision (Πₑ) | Πₑ | Control Parameter | Direct APGI parameter; set by ACh via nicotinic/muscarinic receptors in sensory cortices (layers 2/3).

Predictive Coding Efficiency | Prediction error minimization fidelity | Neural Representation | Overall fidelity of hierarchical inference; depends on optimal Πᵢ allocation and recurrent circuit integrity (thalamocortical loops).

Prediction Error Minimization | Core inference objective | Neural Representation | The computational goal of the system; drives representation competition and updates.

Learning Rate | Πᵢ-modulated plasticity | Control Parameter | Scales with Πₑ (ACh) and Πᵢ (NE); determines how strongly δ updates priors (NMDA/cAMP-dependent plasticity).

Feedback Integration | Integration-phase updating | Output Behavior | Post-ignition incorporation of outcome into memory; mediated by phasic DA (PE) and NE (β-receptor plasticity).

Expectancy | Top-down prior | Neural Representation | High-level prediction; stabilized by 5-HT₁ₐ and suppressed during 5-HT₂ₐ activation (REBUS/psychedelics).

Flexibility | θ₀ and Πᵢ adaptability | Control Parameter | Reflects dynamic range of θ₀ (DA/NE) and Πᵢ (ACh/NE); low in rigid states (e.g., high 5-HT₁ₐ tone).

[Additional mappings continue in the full table...]
""")
            .font(.body)
            .padding()
        }
        .padding()
    }
}

#Preview {
    MappingCognitiveToApgiView()
}
