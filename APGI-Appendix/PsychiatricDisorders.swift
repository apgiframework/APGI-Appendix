import SwiftUI

struct PsychiatricDisordersView: View {
    private let disordersBody = """

Disorder-Specific Precision Profiles

Disorder | APGI Dysregulation | Mechanism | Treatment Implication

Panic | ↑ Πᵢ, ↓ θₜ | Somatic priors → catastrophe | Interoceptive exposure; β-blockers

MDD | ↓ Πᵢ, ↑ θₜ | Blunted interoception; high threshold | Behavioral activation; DA modulation

Schizophrenia (+) | Aberrant Π | DA tags noise as salient | D₂ antagonists; metacognitive training

GAD | ↑ Πₑ (threat) | High-confidence threat priors | CBT; SSRIs (↑ θₜ)

PTSD | ↑ Πᵢ (trauma) | Hyper-precise somatic markers | EMDR; MDMA (↓ Πᵢ)

ASD | Inflexible Π | High Πₑ (detail), low Πₑ (social) | Sensory integration training

ADHD | Unstable Πₑ | NE dysregulation → fluctuating gain | Stimulants (stabilize NE)

Anxiety Disorders: Heterogeneous Precision Dysregulations

Disorder | Precision Profile | Mechanism | Neural Signatures | Treatment Implications

Generalized Anxiety Disorder (GAD) | • Elevated Πₑ for threat-related stimuli • Hyperactive prefrontal threat priors • Mild somatic involvement | Prefrontal cortex generates high-confidence catastrophic predictions; ambiguous stimuli confirm priors. | • Hyperactive P3b to cognitive-semantic threat words • Elevated frontal alpha asymmetry • Hyperconnectivity: dlPFC-amygdala | • CBT: Recalibrates threat priors • SSRIs: Stabilizes priors, elevates θₜ • Mindfulness: Weakens prior confidence

Panic Disorder | • Pathologically elevated Πᵢ for interoceptive signals • Maladaptive somatic priors (M_{c,a}) | Somatic markers predict catastrophe; positive feedback loop amplifies Πᵢ. | • Exaggerated P3b to bodily perturbations • Hyperconnectivity: insula-amygdala-LC • Heightened heartbeat-evoked potentials | • Interoceptive exposure: Updates M_{c,a} to predict safety • β-blockers: Break feedback loop • SSRIs: Reduce interoceptive gain

Social Anxiety Disorder | • Context-specific elevation of Πᵢ and Πₑ during social evaluation • Hypervigilance to social cues | Social contexts activate M_{social_threat}; high Πₑ for facial expressions, Πᵢ for visible symptoms. | • Context-dependent AI-LC hyperconnectivity • Enhanced P3b to social-evaluative faces • Amygdala hyperreactivity | • Exposure therapy: Updates M_{social_threat} • CBT: Reduces precision for negative interpretations • β-blockers: Reduce visible symptoms

Disorders of Consciousness: Thalamocortical Disconnection

State | Mechanism | Neural Signatures | Clinical Application

Coma | Complete thalamocortical disconnection. | Absence: P3b, gamma synchrony, PCI ≈ 0. | PCI (TMS-EEG) as diagnostic classifier.

Vegetative State | Partial thalamocortical activity; no global broadcast. | Early ERPs present; no P3b, PCI < 0.3. | P3b in auditory oddball suggests ignition capacity.

Minimally Conscious State | Fluctuating thalamocortical connectivity. | Intermittent P3b, variable gamma, PCI 0.3–0.5. | Frontoparietal connectivity predicts consciousness.

Disorder | Primary APGI Dysregulation | Consequence for Conscious Experience

GAD/Social Anxiety | ↑ Πᵢ (High Interoceptive Precision) | Constant conscious worry; bodily false alarms

Panic Disorder | ↑ Πᵢ & ↓ θₜ (Acute Collapse) | Overwhelming, sudden conscious panic

MDD | ↓ Πᵢ & ↑ θₜ (Low Precision, High Threshold) | Anhedonia, emotional numbing, lack of motivation

Bipolar I (Manic) | ↓ θₜ (Collapsed Threshold) | Racing thoughts, sensory flooding, distractibility

OCD | ↑ Precision on Maladaptive Priors | Conscious domination by obsessions; rigid compulsions

Schizophrenia | Global Precision Dysregulation | Hallucinations (internal priors dominate), Delusions

BPD | Labile Πᵢ & θₜ | Intense, unstable emotional consciousness

ASPD | ↓ Πᵢ for Empathy/Fear | Lack of conscious guilt or empathy

Gender Dysphoria | Mismatched Body Model vs. Interoception | Conscious feeling that body is "wrong"

ADHD | Unstable Πₑ | Distractibility; conscious focus flickers

Autism (ASD) | Inflexible Hierarchy; High Πₑ | Sensory overload; difficulty with social priors

Anorexia Nervosa | Distorted Body Model; ↓ Πᵢ for Hunger | Body image distortion; hunger ignored

PTSD | Hyper-precise Traumatic Somatic Markers | Intrusive, vivid flashbacks and hypervigilance

Insomnia | Failure to Raise θₜ for Sleep | Conscious awareness when unconsciousness is needed

Addiction | Substance-Induced θₜ/Π Manipulation | Consciousness dominated by craving and drug-seeking
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("APGI for Psychiatric Disorders with Specific Precision Profiles")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text(disordersBody)
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
    PsychiatricDisordersView()
}
