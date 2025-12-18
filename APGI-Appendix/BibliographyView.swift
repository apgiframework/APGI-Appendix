import SwiftUI

struct BibliographyView: View {
    private let bibliographyBody: String

    init(bibliographyBody: String = "") {
        self.bibliographyBody = bibliographyBody
    }

    var body: some View {
        EnhancedContentCard(
            title: "Bibliography",
            content: bibliographyBody,
            category: SectionCategory.reference,
            hasDataTable: false
        )
        .padding()
    }
}

#Preview {
    BibliographyView()
}
