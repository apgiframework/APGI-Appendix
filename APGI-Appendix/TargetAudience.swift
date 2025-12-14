import SwiftUI

struct AudienceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Audience")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text("The core demographic consists of academic researchers—Ph.D. and M.D. scientists in neuroscience, cognitive psychology, cognitive science and experimental psychology—including university professors, lab heads, postdoctoral fellows and investigators at universities and research institutes. These researchers prioritize experimental testability over theoretical elegance and require frameworks that translate directly into testable hypotheses, experimental paradigms and falsifiable predictions—ones that can be evaluated in the lab rather than merely debated in seminars. They design behavioral experiments with healthy human participants to study perception, attention, memory and decision-making. Their methodological expertise spans fMRI, EEG/MEG, electrophysiology and optogenetics and they possess deep domain knowledge of specific brain systems—such as the prefrontal cortex, thalamus, dopamine pathways, insula and anterior cingulate cortex—as well as core cognitive processes like prediction, attention and emotion. Empirical rigor and mechanistic plausibility are non-negotiable for them. These scientists are particularly drawn to theories that offer unifying explanatory power—specifically, a single principle such as precision-gated ignition—that accounts for diverse phenomena, including subliminal versus conscious perception, the attentional blink, emotion-cognition interactions and working memory capacity limits. They value computational clarity when abstract constructs like “dynamic threshold” and “precision weighting” map directly onto experimentally manipulable variables, such as stimulus contrast, emotional context and neuromodulatory state. The APGI framework strength lies in specific testability: the ability to simultaneously manipulate both exteroceptive precision (via stimulus contrast) and interoceptive precision (via emotional context) within a single experimental paradigm. Mechanistic specificity further enhances APGI framework appeal—linking “precision” to defined neuromodulatory systems (acetylcholine for sensory precision, norepinephrine for threshold modulation) and mapping framework variables onto established neural signatures, such as P3b amplitude, gamma-band synchrony and thalamocortical dynamics. For these researchers, the critical question is always: “What experiment could I run tomorrow to test this?” They evaluate theoretical proposals by demanding clear, testable predictions, explicit falsification criteria and integration with established neural data—including ERP components, oscillatory signatures and large-scale network dynamics. They also insist on anatomical and physiological accuracy in proposed circuits and require alignment with known functions of the salience and executive control networks. Common concerns include theories that appear overly “top-down,” rely on abstract “box-and-arrow” architectures, oversimplify the brain’s distributed and recurrent computations or lack sufficient microcircuit detail. What persuades them are concrete experimental designs—ready-to-implement paradigms such as breaking continuous flash suppression to probe dynamic thresholds or dual-task protocols to assess metabolic constraints. They also respond favorably to formal modeling that provides explicit mechanistic accounts of classic effects like the attentional blink, Stroop interference and working memory capacity limits, as well as microcircuit specifications that detail layer-specific thalamocortical interactions, competitive winner-take-all dynamics and biologically plausible implementations of precision via gain modulation. Novel, precise behavioral predictions testable through psychophysical methods further solidify a theory’s credibility.")
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
    AudienceView()
}
