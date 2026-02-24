import AppKit
import PDFKit
import SwiftUI

enum APGIDiagramSource: Equatable {
    case pngAsset(name: String)
    case pdfBundle(resourceName: String)
}

struct APGIConceptDiagram: View {
    let source: APGIDiagramSource
    var contentMode: ContentMode = .fit

    var body: some View {
        Group {
            switch self.source {
            case let .pngAsset(name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: self.contentMode)

            case let .pdfBundle(resourceName):
                APGIPDFDiagramView(resourceName: resourceName)
            }
        }
        .accessibilityLabel(Text("APGI Concept Diagram"))
    }
}

struct APGIPDFDiagramView: NSViewRepresentable {
    let resourceName: String

    func makeNSView(context _: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = false
        pdfView.backgroundColor = .clear
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context _: Context) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "pdf") else {
            nsView.document = nil
            return
        }
        nsView.document = PDFDocument(url: url)
    }
}
