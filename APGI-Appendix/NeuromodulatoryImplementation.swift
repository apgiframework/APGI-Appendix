import SwiftUI

struct NeuromodulatoryImplementationView: View {
    var body: some View {
        ScrollView {
            Text("""

Neuromodulatory Implementation of APGI Control Parameters

Neuromodulator | Primary Source | Key Receptors | Effect on Πₑ | Effect on Πᵢ | Effect on θₜ | Key Computational Role

Norepinephrine (NE) | Locus Coeruleus | α₁/β (Cortex) | Minor Increase | Major Increase | Lowers (Phasic) | Urgency, Soma-Bias, Threat Response

Acetylcholine (ACh) | Basal Forebrain | M1, nAChR | Major Increase | Minor/Contextual | Lowers (Modest) | Expected Uncertainty, Sensory Learning

Serotonin (5-HT) | Raphe Nuclei | 5-HT₁ₐ | Decreases | Decreases | Raises (Tonic) | Stabilizes Priors, Enforces Stability

5-HT | Raphe Nuclei | 5-HT₂ₐ | Increases | Increases | Lowers | Relaxes Priors, Promotes Plasticity

Dopamine (DA) | VTA/SNc | D1 (PFC) | Increases (Salient) | Increases (Salient) | Lowers (Phasic) | Signals Salience, Reward PE

Dopamine (DA) | VTA/SNc | D2 (Interneurons) | - | - | Raises (Tonic) | Resource Conservation, Focus

Integration with APGI Framework

Threshold modulation is expressed as:
θ₀ = θ_base ⋅ exp(−κ_NE [NE] − κ_ACh [ACh]) ⋅ exp(+κ_5-HT [5-HT] + κ_DA [DA])

This equation captures how the baseline threshold (θ₀) is dynamically adjusted by the concentrations of norepinephrine (NE), acetylcholine (ACh), serotonin (5-HT) and dopamine (DA), with κ representing their respective modulation strengths. The exponential form for threshold modulation captures the multiplicative nature of neuromodulatory gain control while linear precision scaling approximates receptor occupancy effects.

Precision modulation is formalized for internal (Πᵢ) and external (Πₑ) precision terms:
Πᵢ = Πᵢ_base ⋅ (1 + η_NE [NE])
Πₑ = Πₑ_base ⋅ (1 + η_ACh [ACh])

Where η_NE and η_ACh act as gain-scaling factors, constrained by receptor pharmacology, to reflect how NE and ACh influence the weighting of internal and external prediction errors.

Somatic bias (β) is represented as a time-dependent parameter:
β(t) = β₀ + η_DA·[DA] + η_NE·[NE]

This linear approximation captures first-order effects; higher-order interactions likely exist in specific contexts.
""")
            .font(.body)
            .padding()
        }
        .padding()
    }
}

#Preview {
    NeuromodulatoryImplementationView()
}
