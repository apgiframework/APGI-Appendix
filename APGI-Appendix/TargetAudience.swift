import SwiftUI

struct AudienceView: View {
    var body: some View {
        EnhancedContentCard(
            title: "Audience",
            content: "The core demographic consists of academic researchers—Ph.D. and M.D. scientists in neuroscience, cognitive psychology, cognitive science and experimental psychology—including university professors, lab heads, postdoctoral fellows and investigators at universities and research institutes. These researchers prioritize experimental testability over theoretical elegance and require frameworks that translate directly into testable hypotheses, experimental paradigms and falsifiable predictions—ones that can be evaluated in the lab rather than merely debated in seminars. They design behavioral experiments with healthy human participants to study perception, attention, memory and decision-making. Their methodological expertise spans fMRI, EEG/MEG, electrophysiology and optogenetics and they possess deep domain knowledge of specific brain systems—such as the prefrontal cortex, thalamus, dopamine pathways, insula and anterior cingulate cortex—as well as core cognitive processes like prediction, attention and emotion. Empirical rigor and mechanistic plausibility are non-negotiable for them. These scientists are particularly drawn to theories that offer unifying explanatory power—specifically, a single principle such as precision-gated ignition—that accounts for diverse phenomena, including subliminal versus conscious perception, the attentional blink, emotion-cognition interactions and working memory capacity limits. They value computational clarity when abstract constructs like “dynamic threshold” and “precision weighting” map directly onto experimentally manipulable variables, such as stimulus contrast, emotional context and neuromodulatory state. The APGI framework strength lies in specific testability: the ability to simultaneously manipulate both exteroceptive precision (via stimulus contrast) and interoceptive precision (via emotional context) within a single experimental paradigm.",
            category: .theoretical,
            hasDataTable: false
        )
        .padding()
    }
}

#Preview {
    AudienceView()
}
