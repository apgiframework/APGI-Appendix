import SwiftUI

struct LifeStagesView: View {
    private let lifeStagesIntro = """
 
 APGI Parameters Across Life Stages
 """
 
    private let tableColumns = [
        "Life Stage",
        "Threshold (θ)", 
        "Precision Weighting (Π)",
        "Ignition Frequency",
        "Working Memory Capacity",
        "Neuromodulator Levels"
    ]
    
    private let tableRows = [
        [
            "Infancy (0–12 months)",
            "Exceptionally high (8-9/10)",
            "Undifferentiated, minimal calibration",
            "10-15 events/minute (vs. 40-60 in adults)",
            "1 item maximum",
            "Acetylcholine and norepinephrine developing; dopamine immature"
        ],
        [
            "Early Childhood (1–4 years)",
            "Very low (2-3/10)",
            "Rapidly calibrating, high learning rate",
            "60-80 events/minute",
            "1-2 items",
            "Acetylcholine elevated (learning mode); norepinephrine high (novelty detection)"
        ],
        [
            "Primary School Age (5–11 years)",
            "Rising gradually (4-6/10, individual variation increases)",
            "Increasingly calibrated, distinguishing signal from noise",
            "40-50 events/minute",
            "3-4 items",
            "Acetylcholine moderating; dopamine reward circuits maturing"
        ],
        [
            "Adolescence (12–20 years)",
            "Highly unstable (fluctuating 3-9/10 hour to hour)",
            "Social/emotional signals dramatically overweighted; long-term planning underweighted",
            "Highly variable (20-70 events/minute)",
            "4-5 items (when threshold stable)",
            "Dopamine remodeling (reward sensitivity ×2-3); serotonin reorganizing; prefrontal norepinephrine inconsistent"
        ],
        [
            "Adulthood (20–65 years)",
            "Stable at individual set-point (typically 5-7/10, varying by person)",
            "Well-calibrated through experience",
            "30-50 events/minute (task-dependent)",
            "4±1 items",
            "Stable baselines; acetylcholine responsive to learning demands; dopamine reflects individual variation; norepinephrine modulates with stress"
        ],
        [
            "Aging (65+ years)",
            "Rising gradually, continues increasing with age",
            "Well-calibrated in familiar domains; less adaptive to novelty",
            "Declining (15-30 events/minute)",
            "3-4 items → 2-3 items (individual variation)",
            "Acetylcholine declining (-30-50%); dopamine declining (-40-60%); norepinephrine variable"
        ]
    ]
    
    private let columnWidths: [CGFloat] = [190, 150, 230, 190, 220, .infinity]
 
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                EnhancedContentCard(
                    title: "Life Stages",
                    content: lifeStagesIntro,
                    category: .applications,
                    hasDataTable: true
                )
 
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 0) {
                        ForEach(Array(tableColumns.enumerated()), id: \.offset) { index, column in
                            Text(column)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                                .frame(
                                    maxWidth: index < columnWidths.count ? columnWidths[index] : .infinity,
                                    alignment: .leading
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(.quaternary)

                            if index < tableColumns.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(tableRows.enumerated()), id: \.offset) { index, row in
                                HStack(spacing: 0) {
                                    ForEach(Array(row.enumerated()), id: \.offset) { cellIndex, cell in
                                        Text(cell)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.primary)
                                            .frame(
                                                maxWidth: cellIndex < columnWidths.count ? columnWidths[cellIndex] : .infinity,
                                                alignment: .leading
                                            )
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)

                                        if cellIndex < row.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .background(index % 2 == 0 ? Color.clear : Color.primary.opacity(0.02))

                                if index < tableRows.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 600)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 1)
                    )
                }
            }
            .padding()
        }
    }
}

#Preview {
    LifeStagesView()
}
