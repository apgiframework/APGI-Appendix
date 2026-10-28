import SwiftUI

struct PsychiatricDisordersView: View {
  private let disordersBody = """
    Illustrative hypotheses — not established clinical mappings.

    APGI does not establish diagnostic thresholds or treatment recommendations
    for ADHD, ASD, schizophrenia, depression, anxiety, PTSD, or disorders of
    consciousness. The former treatment and biomarker tables have been withdrawn
    pending evidence review. Model parameters must not be used to infer a person's
    diagnosis, clinical state, or response to treatment.
    """

  var body: some View {
    EnhancedContentCard(
      title: "APGI for Psychiatric Disorders with Specific Precision Profiles",
      content: self.disordersBody,
      category: .applications,
      hasDataTable: true
    )
    .padding()
  }
}

#Preview {
  PsychiatricDisordersView()
}
