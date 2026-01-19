import SwiftUI

struct DisordersConditionsView: View {
    private let disordersConditionsContent = """

APGI Parameter Table — Disorders & Conditions

| Disorder | Prediction Error ε (σ) | Precision π (dominant channels) | Threshold θₜ (%) | Somatic Bias β |
|---|---|---|---|---|
| Childhood-Onset Fluency Disorder | Speech-motor +2–4 | Motor-speech ↑ | −15 to −25 | 1.2–1.5 |
| Language Disorder | Linguistic +2–4 | Language ↓ | +10–25 | 1.0 |
| Social (Pragmatic) Comm. Disorder | Social inference +3–5 | Social ↓ | +10–20 | 0.9–1.1 |
| Speech Sound Disorder | Phonological +2–4 | Motor-speech ↑ | −10–20 | 1.1–1.4 |
| Intellectual Disability | Global −2 to −4 | All ↓ | +20–40 | 1.0 |
| Global Dev. Delay | Global −2–3 | All ↓ | +20–40 | 1.0 |
| Developmental Coordination Disorder | Motor +3–5 | Motor ↑ | −15–25 | 1.3–1.7 |
| Stereotypic Movement Disorder | Motor loop +2–4 | Motor ↑↑ | −30–50 | 1.5–2.5 |
| Tic Disorders (all types) | Motor urge +3–6 | Motor ↑ | −25–45 | 1.8–3.0 |
| ADHD | Task inconsistency +2–4 | Executive ↓ | −20–40 (unstable) | 0.8–1.2 |
| Autism Spectrum Disorder | Social +3–6 | Sensory ↑, Social ↓ | +15–35 | 0.7–1.1 |
| Specific Learning Disorder | Domain-specific +3–5 | Domain ↓ | +10–25 | 1.0 |
| Brief Psychotic Disorder | Delusional +4–7 | Aberrant ↑ | −40–60 | 1.2–2.0 |
| Delusional Disorder | Fixed belief +3–5 | Belief ↑↑ | −30–45 | 1.0–1.4 |
| Schizophrenia | Internal +4–8 | Sensory ↓ / Internal ↑ | −50–70 | 0.8–1.3 |
| Schizoaffective Disorder | Mood + Psychotic | Alternating | −40–60 | 1.0–2.0 |
| Schizotypal PD | Magical ideation +3–5 | Associative ↑ | −20–35 | 0.8–1.2 |
| Bipolar I | Mania: −2σ error | Reward ↑↑ | −40–60 | 0.7–1.1 |
| Bipolar II | Hypomanic oscillation | Reward ↑ | −25–40 | 0.8–1.2 |
| Cyclothymia | Chronic oscillation | Reward unstable | ±20–30 | 1.0 |
| Major Depressive Disorder | Reward −3–5 | Positive ↓ | +30–50 | 0.7–0.9 |
| Persistent Depressive Disorder | Reward −2–4 | Positive ↓ | +25–40 | 0.8–1.0 |
| PMDD | Hormonal +2–4 | Threat ↑ | −15–30 (cyclic) | 1.4–2.0 |
| Generalized Anxiety Disorder | Threat +3–6 | Threat ↑↑ | −25–40 | 1.8–3.0 |
| Panic Disorder | Interoceptive +4–7 | Body ↑↑ | −40–60 | 2.5–4.0 |
| Social Anxiety Disorder | Social threat +3–5 | Social ↑ | −25–40 | 1.5–2.5 |
| Specific Phobia | Object threat +4–6 | Threat ↑ | −40–60 | 2.0–3.5 |
| Obsessive-Compulsive Disorder | Intrusive +3–5 | Error-monitoring ↑ | −30–45 | 1.5–2.5 |
| Hoarding Disorder | Loss prediction +3–5 | Value ↑ | −25–40 | 1.2–1.6 |
| Body Dysmorphic Disorder | Appearance +4–6 | Visual-self ↑ | −30–45 | 1.8–3.0 |
| Trichotillomania | Urge +3–5 | Motor ↑ | −30–45 | 2.0–3.0 |
| PTSD | Threat memory +4–7 | Threat ↑↑ | −40–60 | 2.0–3.5 |
| Acute Stress Disorder | Threat +3–6 | Threat ↑ | −30–50 | 1.8–3.0 |
| Dissociative Identity Disorder | Self-model split | Internal ↑ | +40–70 | <0.3 |
| Depersonalization Disorder | Body error ↓ | Interoceptive ↓ | +40–60 | <0.4 |
| Dissociative Amnesia | Memory access ↓ | Autobiog ↓ | +30–50 | 0.5–0.8 |
| Somatic Symptom Disorder | Body +3–5 | Interoceptive ↑ | −20–35 | 2.0–3.0 |
| Illness Anxiety Disorder | Health threat +3–5 | Threat ↑ | −25–40 | 2.0–3.0 |
| Conversion Disorder | Motor/sensory mismatch | Motor ↑ | −30–50 | 1.5–2.5 |
| Anorexia Nervosa | Body-weight +4–6 | Control ↑↑ | −30–50 | 0.6–0.9 |
| Bulimia Nervosa | Control oscillation | Reward ↑ | ±25–40 | 1.5–2.5 |
| Binge-Eating Disorder | Reward +3–5 | Reward ↑ | −25–40 | 1.8–2.8 |
| ARFID | Food threat +3–5 | Threat ↑ | −25–40 | 1.5–2.5 |
| Insomnia Disorder | Sleep prediction error | Arousal ↑ | +25–40 | 1.5–2.5 |
| Hypersomnolence | Wake drive ↓ | Arousal ↓ | +30–50 | 0.8–1.1 |
| Narcolepsy | State-boundary error | State ↓ | −20–40 | 1.0 |
| Nightmare Disorder | Threat replay | Threat ↑ | −30–50 | 2.0–3.0 |
| Sexual Dysfunctions (general) | Performance +2–4 | Self-monitor ↑ | +20–35 | 1.2–2.0 |
| Gender Dysphoria | Self-body mismatch +3–5 | Self-model ↑ | −15–30 | 1.5–2.5 |
| Antisocial Personality Disorder | Punishment −3–5 | Threat ↓ | −20–35 | 0.6–0.9 |
| Borderline PD | Attachment +4–6 | Social ↑ | −40–60 | 2.0–3.5 |
| Avoidant PD | Social threat +3–5 | Social ↑ | +20–35 | 1.8–3.0 |
| Narcissistic PD | Ego threat +3–5 | Self ↑ | −20–35 | 0.8–1.2 |
| Obsessive-Compulsive PD | Order violation +2–4 | Control ↑ | −15–30 | 1.2–1.6 |
| Substance Use Disorders (all) | Drug cue +4–7 | Reward ↑↑ | −40–60 | 1.5–3.0 |
| Gambling Disorder | Uncertainty reward +4–6 | Reward ↑ | −35–55 | 1.2–2.0 |
| Delirium | Global +5–8 | Precision collapse | Variable | 0.7–1.3 |
| Major Neurocognitive Disorder | Global −4–6 | All ↓ | +30–60 | 1.0 |
| Mild Neurocognitive Disorder | Global −2–3 | Executive ↓ | +15–30 | 1.0 |
"""

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                EnhancedContentCard(
                    title: "Disorders and Conditions",
                    content: disordersConditionsContent,
                    category: .applications,
                    hasDataTable: true
                )
            }
            .padding()
        }
    }
}

#Preview {
    DisordersConditionsView()
}
