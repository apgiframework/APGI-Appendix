import SwiftUI

struct BibliographyCardView: View {
  private let bibliographyBody: String

  init(bibliographyBody: String = "") {
    self.bibliographyBody = bibliographyBody
  }

  var body: some View {
    EnhancedContentCard(
      title: "Bibliography",
      content: self.bibliographyBody,
      category: SectionCategory.reference,
      hasDataTable: false
    )
    .padding()
  }
}

#Preview {
  BibliographyCardView()
}
