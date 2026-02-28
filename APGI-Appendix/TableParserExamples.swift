import SwiftUI
import UniformTypeIdentifiers

// MARK: - TableParser Examples & Usage

struct TableParserExamples: View {
    private let tableParser = TableParser()
    @State private var selectedExample: ExampleType = .markdown
    @State private var parsedTable: ParsedTable?
    @State private var parseError: String?

    enum ExampleType: String, CaseIterable {
        case markdown = "Markdown Table"
        case csv = "CSV Data"
        case tsv = "TSV Data"
        case json = "JSON Array"
        case structured = "Structured Text"
        case keyValue = "Key-Value Pairs"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Example Selector
            Picker("Table Format", selection: self.$selectedExample) {
                ForEach(ExampleType.allCases, id: \.self) { example in
                    Text(example.rawValue).tag(example)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Parsed Table Display
            if let table = parsedTable {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Parsed Table (\(String(describing: table.metadata.format)))")
                        .font(.headline)

                    if let title = table.metadata.title {
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    table.toSwiftUIView()
                }
            }
            else if let error = parseError {
                VStack {
                    Text("Parse Error")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            else {
                ProgressView("Parsing table...")
                    .padding()
            }
        }
        .onChange(of: self.selectedExample) { _, _ in
            self.parseExample()
        }
        .onAppear {
            self.parseExample()
        }
    }

    private func parseExample() {
        let content = self.getContentForExample(self.selectedExample)

        do {
            switch self.selectedExample {
            case .markdown:
                self.parsedTable = try self.tableParser.parseMarkdownTable(content)
            case .csv:
                self.parsedTable = try self.tableParser.parseTable(from: content, format: TableFormat.csv)
            case .tsv:
                self.parsedTable = try self.tableParser.parseTable(from: content, format: TableFormat.tsv)
            case .json:
                self.parsedTable = try self.tableParser.parseTable(from: content, format: TableFormat.json)
            case .structured:
                self.parsedTable = try self.tableParser.parseTable(from: content, format: TableFormat.structured)
            case .keyValue:
                self.parsedTable = try self.tableParser.parseTable(from: content, format: TableFormat.structured)
            }
            self.parseError = nil
        }
        catch {
            self.parseError = error.localizedDescription
            self.parsedTable = nil
        }
    }

    private func getContentForExample(_ example: ExampleType) -> String {
        switch example {
        case .markdown:
            return """
            | Parameter | Symbol | Range | Function |
            |-----------|--------|-------|----------|
            | Threshold | θ | 0-10 | Ignition trigger level |
            | Precision | Π | 0-1 | Signal weighting factor |
            | Surprise | S | Variable | Prediction error magnitude |
            | Gain | G | 0.1-10.0 | Amplification factor |
            """

        case .csv:
            return """
            "Neuromodulator","Primary Function","Typical Level","Effect on θ"
            "Acetylcholine","Attention/ Learning","High during focus","Lowers threshold"
            "Norepinephrine","Arousal/ Vigilance","High during stress","Modulates precision"
            "Dopamine","Reward/ Motivation","Variable","Influences gain"
            "Serotonin","Mood/ Stability","Baseline","Stabilizes system"
            """

        case .tsv:
            return """
            Life Stage	Threshold (θ)	Precision Weighting (Π)	Working Memory
            Infancy	8-9/10	Undifferentiated	1 item
            Childhood	4-6/10	Rapidly calibrating	2-3 items
            Adolescence	3-9/10	Socially biased	4-5 items
            Adulthood	5-7/10	Well-calibrated	4±1 items
            Aging	6-8/10	Conservative	3-4 items
            """

        case .json:
            return """
            [
              {
                "disorder": "ADHD",
                "threshold": "Low (3-4/10)",
                "precision": "High variability",
                "primary_neuromodulator": "Dopamine"
              },
              {
                "disorder": "Depression",
                "threshold": "High (7-8/10)",
                "precision": "Reduced",
                "primary_neuromodulator": "Serotonin"
              },
              {
                "disorder": "Anxiety",
                "threshold": "Low (2-3/10)",
                "precision": "Elevated for threats",
                "primary_neuromodulator": "Norepinephrine"
              }
            ]
            """

        case .structured:
            return """
            Parameter  Value  Unit    Description
            θ          5.2    --      Current threshold
            Πₑ         0.8    --      Exteroceptive precision
            Πᵢ         0.9    --      Interoceptive precision
            β          1.2    --      Somatic bias factor
            τ          2.5    s       Time constant
            """

        case .keyValue:
            return """
            Model: APGI Framework v2.0
            Version: 1.0.0
            Author: Research Team
            Last Updated: 2024-01-15
            Status: Production
            License: MIT
            """
        }
    }
}

// MARK: - Advanced Table Usage

struct AdvancedTableUsage: View {
    private let tableParser = TableParser()
    @State private var tables: [ParsedTable] = []
    @State private var selectedTableIndex = 0

    var body: some View {
        VStack(spacing: 20) {
            // Table Selector
            if !self.tables.isEmpty {
                Picker("Select Table", selection: self.$selectedTableIndex) {
                    ForEach(Array(self.tables.enumerated()), id: \.offset) { index, table in
                        Text(table.metadata.title ?? "Table \(index + 1)")
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .padding()

                // Export Options
                HStack {
                    Button("Export as Markdown") {
                        self.exportTableAsMarkdown()
                    }

                    Button("Export as CSV") {
                        self.exportTableAsCSV()
                    }

                    Button("Export as JSON") {
                        self.exportTableAsJSON()
                    }
                }
                .padding()
            }

            // Table Display
            if self.selectedTableIndex < self.tables.count {
                let table = self.tables[self.selectedTableIndex]
                VStack(alignment: .leading, spacing: 12) {
                    if let title = table.metadata.title {
                        Text(title)
                            .font(.headline)
                    }

                    if let source = table.metadata.source {
                        Text("Source: \(source)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    table.toSwiftUIView()
                }
            }
            else {
                ProgressView("Loading tables...")
                    .padding()
            }
        }
        .onAppear {
            self.loadMultipleTables()
        }
    }

    private func loadMultipleTables() {
        let markdownContent = """
        | Region | Function | APGI Parameter |
        |--------|----------|----------------|
        | Prefrontal Cortex | Executive Control | Threshold modulation |
        | Thalamus | Relay | Signal routing |
        | Hippocampus | Memory | Precision weighting |
        """

        let csvContent = """
        "Metric","Value","Unit","Status"
        "Accuracy","0.92","--","Good"
        "Precision","0.88","--","Acceptable"
        "Recall","0.91","--","Good"
        "F1-Score","0.89","--","Good"
        """

        do {
            let markdownTable = try tableParser.parseMarkdownTable(markdownContent)
            let csvTable = try tableParser.parseTable(from: csvContent, format: TableFormat.csv)

            self.tables = [
                markdownTable,
                csvTable,
            ]
        }
        catch {
            logError(error, context: "TableParserExamples.loadTables", function: #function, file: #file, line: #line)
        }
    }

    private func exportTableAsMarkdown() {
        guard self.selectedTableIndex < self.tables.count else { return }
        let table = self.tables[self.selectedTableIndex]
        let markdown = table.toMarkdown()

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markdown, forType: .string)
    }

    private func exportTableAsCSV() {
        guard self.selectedTableIndex < self.tables.count else { return }
        let table = self.tables[self.selectedTableIndex]
        let csv = table.toCSV()

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(csv, forType: .string)
    }

    private func exportTableAsJSON() {
        guard self.selectedTableIndex < self.tables.count else { return }
        let table = self.tables[self.selectedTableIndex]

        let jsonDict: [String: Any] = [
            "title": table.metadata.title ?? "",
            "format": String(describing: table.metadata.format),
            "headers": table.headers,
            "rows": table.rows,
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(jsonString, forType: .string)
            }
        }
        catch {
            logError(error, context: "TableParserExamples.exportTableAsJSON", function: #function, file: #file, line: #line)
        }
    }
}

// MARK: - File-based Table Loading

struct FileBasedTableLoader: View {
    private let tableParser = TableParser()
    @State private var selectedFileURL: URL?
    @State private var parsedTable: ParsedTable?
    @State private var parseError: String?
    @State private var isFileImporterPresented = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Load Table File") {
                self.isFileImporterPresented = true
            }
            .buttonStyle(.borderedProminent)

            if let url = selectedFileURL {
                Text("Loaded: \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let table = parsedTable {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Table from \(self.selectedFileURL?.lastPathComponent ?? "file")")
                        .font(.headline)

                    Text("Format: \(String(describing: table.metadata.format))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Rows: \(table.rows.count), Columns: \(table.headers.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    table.toSwiftUIView()
                }
            }
            else if let error = parseError {
                VStack {
                    Text("File Parse Error")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .fileImporter(
            isPresented: self.$isFileImporterPresented,
            allowedContentTypes: [.plainText, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let url = urls.first {
                    self.selectedFileURL = url
                    self.loadTableFromFile(url)
                }
            case let .failure(error):
                self.parseError = "File selection failed: \(error.localizedDescription)"
            }
        }
    }

    private func loadTableFromFile(_ url: URL) {
        do {
            self.parsedTable = try self.tableParser.parseTableFromFile(at: url)
            self.parseError = nil
        }
        catch {
            self.parseError = error.localizedDescription
            self.parsedTable = nil
        }
    }
}

#Preview {
    TabView {
        TableParserExamples()
            .tabItem {
                Label("Examples", systemImage: "doc.text")
            }

        AdvancedTableUsage()
            .tabItem {
                Label("Advanced", systemImage: "tablecells")
            }

        FileBasedTableLoader()
            .tabItem {
                Label("File Loader", systemImage: "folder")
            }
    }
    .frame(width: 800, height: 600)
}
