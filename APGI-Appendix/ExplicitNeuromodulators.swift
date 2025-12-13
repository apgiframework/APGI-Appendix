import SwiftUI

struct ExplicitNeuromodulatorsView: View {
    var body: some View {
        ScrollView {
            Text("""

Explicit Neuromodulator Mapping

Concept | Definition | Primary Location | Biological Implementation | Inputs

Surprise (Sₜ) | Population firing rate of "evidence accumulator" neurons. | Supragranular layers (2/3) of the Posterior Parietal Cortex (PPC) and Intraparietal Sulcus (IPS). | Ramping activity from recurrent excitation in local L2/3 microcircuits (pyramidal cells) balanced by feedback inhibition from SOM+ interneurons. Decay term (-Sₜ/τ) implemented by spike-frequency adaptation in pyramidal cells (slow K⁺ currents) and synaptic depression. | Precision-weighted prediction error via (1) thalamocortical input to L4/L5 and (2) corticocortical projections from sensory and insular regions.

Ignition Threshold (θₜ) | Effective membrane potential threshold for NMDA-spike generation in L5 pyramidal cell apical dendrites. | Not explicitly stated as a primary location, but mechanisms involve Thalamic Reticular Nucleus (TRN), matrix thalamus, L1 and L5 pyramidal cells. | Homeostasis (-γ(θ₀ – θₜ)): Set by tonic firing of TRN, providing baseline GABAergic inhibition to the matrix thalamus, limiting its drive to L1. Post-Ignition Refractoriness (δ·Bₜ₋₁): Caused by (1) short-term synaptic depression in thalamocortical synapses onto L1/L5; (2) after-hyperpolarization (AHP) in L5 pyramidal cells; (3) activation of SOM+ interneurons. Urgency (-λ·dSₜ/dt): Mediated by phasic bursts of Locus Coeruleus–Norepinephrine (LC-NE). NE potentiates NMDA currents and hyperpolarizes the TRN. | Not explicitly stated as direct inputs for the threshold itself, but rather factors influencing its change.

Ignition Probability (Bₜ) | Probability of a self-sustaining, metastable attractor state in the frontoparietal network. | Apical tuft of L5 pyramidal cells (for the "switch"). | The "switch" is the NMDA-receptor-mediated calcium spike in the apical tuft of L5 pyramidal cells. When Sₜ > θₜ, the disinhibited matrix thalamus delivers sufficient coordinated drive to L1 to trigger a regenerative dendritic calcium spike. This spike propagates to the soma and, if coincident with perisomatic input, triggers a burst of output spikes (coincidence detection). Steepness α is determined by apical NMDA receptor density and thalamic input synchrony. | Disinhibited matrix thalamus (pulvinar/MD) providing coordinated drive to L1; perisomatic input from basal dendrites.
""")
            .font(.body)
            .padding()
        }
        .padding()
    }
}

#Preview {
    ExplicitNeuromodulatorsView()
}
