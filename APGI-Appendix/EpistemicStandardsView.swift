import SwiftUI

struct EpistemicStandardsView: View {
    @StateObject private var tableParser = TableParser()
    @State private var parsedTable: ParsedTable?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let standardsTable = """
    |Claim Type|Required Evidence|APGI Status|
    |---|---|---|
    |Level 1: "APGI is metabolically efficient"|Measured J/K during conscious vs. unconscious; comparison to alternatives|Not done|
    |Level 2: "APGI is information-efficient"|Calculate mutual information, compare to channel capacity|Plausible, incompletely validated|
    |Level 3: "APGI minimizes free energy"|Show neural dynamics implement gradient descent on F|Some support, contested|
    |Cross-Level: "Variational efficiency → thermodynamic efficiency"|Quantitative bridge calculation|Critical gap|
    |Strong Claim: "APGI is thermodynamically necessary"|Prove all alternatives violate physics or use more energy|Unsupported|
    |Moderate Claim: "APGI is thermodynamically probable"|Show convergent evolution, adaptive value, efficiency arguments|Plausible but incomplete|
    |Weak Claim: "APGI describes neural mechanisms"|Demonstrate biological implementations match computational functions|Well-supported|
    |Comparative Frameworks: GNWT, IIT, Re-entry theories|Share Level-1 thermodynamic gaps: invoke energy costs and dissipation without measured Joules/Kelvin or Landauer comparisons; APGI's explicit bridges and standards distinguish it methodologically.|Well-supported|
    """

    var body: some View {
        VStack(spacing: 16) {
            if self.isLoading {
                ProgressView("Loading Epistemic Standards...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
            else if let errorMessage = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error Loading Table")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        self.loadTable()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            else if let parsedTable = parsedTable {
                VStack(spacing: 0) {
                    Text("Epistemic Standards")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    parsedTable.toSwiftUIView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding()
            }
            else {
                // Fallback to original display if parsing fails
                EnhancedContentCard(
                    title: "Epistemic Standards",
                    content: self.standardsTable,
                    category: .theoretical,
                    hasDataTable: true
                )
                .padding()
            }
        }
        .onAppear {
            self.loadTable()
        }
    }

    private func loadTable() {
        self.isLoading = true
        self.errorMessage = nil

        Task {
            do {
                let table = try tableParser.parseMarkdownTable(self.standardsTable)
                await MainActor.run {
                    self.parsedTable = table
                    self.isLoading = false
                }
            }
            catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    EpistemicStandardsView()
}
