import SwiftUI

struct LifeStagesView: View {
    var body: some View {
        ScrollView {
            Text("""
LifeStages

APGI Parameters Across Life Stages

Life Stage
Threshold (θ)
Precision Weighting (Π)
Ignition Frequency
Working Memory Capacity
Neuromodulator Levels
Infancy (0–12 months)
Exceptionally high (8-9/10)
Undifferentiated, minimal calibration
10-15 events/minute (vs. 40-60 in adults)
1 item maximum
Acetylcholine and norepinephrine developing; dopamine immature
Early Childhood (1–4 years)
Very low (2-3/10)
Rapidly calibrating, high learning rate
60-80 events/minute
1-2 items
Acetylcholine elevated (learning mode); norepinephrine high (novelty detection)
Primary School Age (5–11 years)
Rising gradually (4-6/10, individual variation increases)
Increasingly calibrated, distinguishing signal from noise
40-50 events/minute
3-4 items
Acetylcholine moderating; dopamine reward circuits maturing
Adolescence (12–20 years)
Highly unstable (fluctuating 3-9/10 hour to hour)
Social/emotional signals dramatically overweighted; long-term planning underweighted
Highly variable (20-70 events/minute)
4-5 items (when threshold stable)
Dopamine remodeling (reward sensitivity ×2-3); serotonin reorganizing; prefrontal norepinephrine inconsistent
Adulthood (20–65 years)
Stable at individual set-point (typically 5-7/10, varying by person)
Well-calibrated through experience
30-50 events/minute (task-dependent)
4±1 items
Stable baselines; acetylcholine responsive to learning demands; dopamine reflects individual variation; norepinephrine modulates with stress
Aging (65+ years)
Rising gradually, continues increasing with age
Well-calibrated in familiar domains; less adaptive to novelty
Declining (15-30 events/minute)
3-4 items → 2-3 items (individual variation)
Acetylcholine declining (-30-50%); dopamine declining (-40-60%); norepinephrine variable



""")
            .font(.body)
            .padding()
        }
        .padding()
    }
}

#Preview {
    LifeStagesView()
}
