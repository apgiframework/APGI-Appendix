import SwiftUI

struct IgnitionTimelineView: View {
    private let timelineBody = """

Ignition unfolds as a stereotyped, temporally precise cascade across thalamocortical microcircuits. Below is a canonical timeline anchored to stimulus onset (t = 0 ms), with neural events resolved in 50-ms bins. This sequence integrates laminar electrophysiology, circuit anatomy and computational function.

Time (ms)
Thalamocortical/Cortical Interactions
Event/Network Activity
Functional Interpretation
0–50
Matrix thalamus (pulvinar/MD) projects synchronously to cortical layer 1. Apical dendrites of frontoparietal L5 pyramidal neurons receive strong depolarizing drive.
Pulvinar/MD → L1 apical tufts (dlPFC, PPC, AI)
Trigger: Neuromodulatory gain (e.g., NE-mediated) disinhibits thalamus, initiating apical integration, the circuit translation of precision-weighting enabling ignition.
50–100
NMDA-receptor-mediated Ca²⁺ spikes erupt in L5 apical dendrites. Somatic bursting begins if coincident with basal dendritic input. PV⁺ interneurons provide transient feedforward inhibition which is overcome by shunting and divisive normalization.
L5 pyramidal neurons (dlPFC, PPC); PV⁺ interneurons
Amplification: Dendritic spikes amplify precision-weighted prediction errors; winner-take-all competition intensifies.
100–150
Burst output from L5 propagates to L2/3. Recurrent excitation initiates within frontoparietal microcolumns. Gamma-band (30–80 Hz) power begins to rise locally.
L2/3 pyramidal neurons; local recurrent loops
Local Stabilization: Horizontal integration begins; coalition-specific gamma synchrony emerges.
150–200
Long-range gamma phase-locking initiates between frontal, parietal and insular regions. P3a ERP peaks (~200 ms), reflecting salience detection and frontoinsular engagement.
AI–ACC–dlPFC network; frontoparietal synchrony
Salience Broadcast: Interoceptive/exteroceptive relevance is signaled to executive systems.
200–250
Sustained high-firing attractor state consolidates. TRN re-engagement begins via SOM⁺ feedback, setting up future refractoriness. Pupillary dilation peaks (LC-NE burst).
Thalamocortical loops; LC–NE system
Metastability: The Sₜ > θₜ condition is met. The network enters a self-sustaining regime; neuromodulatory urgency signal peaks.
250–300
P3b ERP peaks (~300 ms) over parietal scalp. Peak gamma synchrony between frontoparietal and temporal regions. PCI rises above 0.4 if perturbed.
PPC (P3b generator); frontotemporal gamma
Ignition Confirmation: Global availability achieved; content is reportable and memory-encodable.
300–350
Hippocampal sharp-wave ripples begin to encode ignited content. Language areas activate if verbal report is required.
Hippocampus, left perisylvian cortex
Memory & Report: Episodic encoding and linguistic formulation commence.
350–400
Threshold θₜ begins to rise due to δ·Bₜ₋₁ term (post-ignition refractoriness). SOM⁺ interneurons enforce feedback inhibition.
L5–SOM⁺ microcircuit; thalamocortical synapses
Refractory Initiation: System prepares for attentional blink and prevents simultaneous conscious contents. Active inhibition raises θₜ (formalized as δ·Bₜ₋₁), implementing post-ignition suppression.
400–450
Frontoparietal firing remains elevated but begins to decay if not actively maintained. Alpha oscillations rebound, reinstating inhibitory tone.
dlPFC, PPC; thalamocortical alpha generators
Stabilization or Decay: Content remains globally available only if rehearsed such as in working memory.
450–500
Activity returns toward baseline in non-maintained trials. Theta-phase binding may group this ignition into a 3-second “specious present” window.
Hippocampal–DMN theta; residual gamma
Temporal Integration: Ignition event is bound into ongoing conscious narrative stream.



This timeline is testable with intracranial EEG, laminar probes and concurrent pupillometry. Deviations (e.g., delayed P3b, absent L5 spiking) predict failed ignition or altered states (e.g., anesthesia, schizophrenia). The sequence reflects the transition from local surprise accumulation to global, self-sustaining attractor dynamics.



"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ignition Timeline (0–500 ms)")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text(timelineBody)
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
    IgnitionTimelineView()
}
