import SwiftUI

struct ApgiMappingView: View {
  private let mappingBody = """

    APGI Explicit Mapping

    Mathematical Variable | Proposed Neural Correlate & Biological Implementation

    Surprise (Sₜ)
    Population firing rate of "evidence accumulator" neurons.

    Primary Location: Supragranular layers (2/3) of the Posterior Parietal Cortex (PPC) and Intraparietal Sulcus (IPS). These regions show ramping activity proportional to accumulated evidence.

    Biological Implementation of dSₜ/dt: Ramping arises from recurrent excitation within local L2/3 microcircuits (pyramidal cells) balanced by feedback inhibition from somatostatin-positive (SOM+) interneurons. The decay term Sₜ/τ is implemented by spike-frequency adaptation in pyramidal cells (via slow K⁺ currents) and synaptic depression.

    Input f(Πₑ·εₑ, ...): Precision-weighted prediction error arrives via (1) thalamocortical input to L4/L5 and (2) corticocortical projections from sensory and insular regions.

    Ignition Threshold (θₜ)
    Effective membrane potential threshold for NMDA-spike generation in L5 pyramidal cell apical dendrites.

    Biological Implementation of dθₜ/dt:

    γ(θ₀ – θₜ) (Homeostasis): Set by tonic firing of the Thalamic Reticular Nucleus (TRN) which provides baseline GABAergic inhibition to the matrix thalamus, limiting its drive to L1—functioning as the "gatekeeper."

    δ·Bₜ₋₁ (Post-Ignition Refractoriness): Caused by (1) short-term synaptic depression in thalamocortical synapses onto L1/L5; (2) after-hyperpolarization (AHP) in L5 pyramidal cells following a burst; (3) activation of SOM+ interneurons providing delayed feedback inhibition.

    λ·dSₜ/dt (Urgency): Mediated by phasic bursts of Locus Coeruleus–Norepinephrine (LC-NE). NE, via β-adrenergic receptors, potentiates NMDA currents and hyperpolarizes the TRN, directly and rapidly lowering the effective dendritic threshold.

    Ignition Probability (Bₜ)
    Probability of a self-sustaining, metastable attractor state in the frontoparietal network.

    Biological Implementation of σ(α(Sₜ – θₜ)): The "switch" is the NMDA-receptor-mediated calcium spike in the apical tuft of L5 pyramidal cells.

    – When Sₜ > θₜ, the disinhibited matrix thalamus (pulvinar/MD) delivers sufficient coordinated drive to L1 to trigger a regenerative dendritic calcium spike.

    – This spike propagates to the soma; if coincident with perisomatic input from basal dendrites, it triggers a burst of output spikes—implementing coincidence detection as the nonlinear sigmoid.

    – Steepness α is determined by apical NMDA receptor density and the degree of thalamic input synchrony.

    Surprise Accumulation
    Sₜ = Πₑ·|εₑ| + β·Πᵢ·|εᵢ|

    Where:
    - Sₜ: Total precision-weighted surprise at time t
    - Πₑ: Exteroceptive precision (reliability of external sensory signals)
    - |εₑ|: Magnitude of exteroceptive prediction error
    - Πᵢ: Interoceptive precision (reliability of bodily signals)
    - |εᵢ|: Magnitude of interoceptive prediction error
    - β: Somatic bias factor (β ≈ 1.2-1.5 baseline, context-modulated)

    Ignition Probability
    Bₜ = σ(α(Sₜ - θₜ))

    Where:
    - Bₜ: Probability of ignition at time t (0 to 1)
    - σ: Sigmoid function σ(x) = 1 / (1 + e^(-x))
    - α: Slope parameter determining steepness of transition
    - θₜ: Dynamic ignition threshold at time t

    Ignition Decision Rule
    Ignition occurs when Sₜ > θₜ

    Temporal Dynamics of Surprise
    dSₜ/dt = −Sₜ/τ + f(Πₑ·εₑ(t), Πᵢ·εᵢ(t)) + σ·η(t)

    Where:
    - τ: Time constant for surprise decay (τ ≈ 200 ms)
    - f(·): Integration function combining exteroceptive and interoceptive contributions
    - σ·η(t): Gaussian white noise with standard deviation σ and with unit variance and σ ≈ 0.1·θ₀ captures intrinsic neural variability.
    """

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 20) {
        EnhancedContentCard(
          title: "APGI Mapping",
          content: self.mappingBody,
          category: .mathematical,
          hasDataTable: false
        )
      }
      .padding()
    }
  }
}

#Preview {
  ApgiMappingView()
}
