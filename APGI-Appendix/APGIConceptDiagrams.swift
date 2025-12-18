import SwiftUI
import AppKit
import PDFKit

enum APGIDiagramSource: Equatable {
    case pngAsset(name: String)
    case pdfBundle(resourceName: String)
}

struct APGIConceptDiagram: View {
    let source: APGIDiagramSource
    var contentMode: ContentMode = .fit

    var body: some View {
        Group {
            switch source {
            case .pngAsset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)

            case .pdfBundle(let resourceName):
                APGIPDFDiagramView(resourceName: resourceName)
            }
        }
        .accessibilityLabel(Text("APGI Concept Diagram"))
    }
}

struct APGIPDFDiagramView: NSViewRepresentable {
    let resourceName: String

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = false
        pdfView.backgroundColor = .clear
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "pdf") else {
            nsView.document = nil
            return
        }
        nsView.document = PDFDocument(url: url)
    }
}
