import Combine
import Foundation
import SwiftUI

// MARK: - Table Data Models

struct ParsedTable {
  let headers: [String]
  let rows: [[String]]
  let metadata: TableMetadata

  init(headers: [String], rows: [[String]], metadata: TableMetadata = TableMetadata()) {
    self.headers = headers
    self.rows = rows
    self.metadata = metadata
  }

  var id: String {
    return "table-\(self.headers.hashValue)-\(self.rows.hashValue)"
  }

  var columnCount: Int {
    return self.headers.count
  }

  var rowCount: Int {
    return self.rows.count
  }

  var title: String? {
    return self.metadata.title
  }
}

struct TableMetadata {
  let title: String?
  let source: String?
  let format: TableFormat
  let columnAlignments: [TextAlignment]
  let columnWidths: [CGFloat?]

  init(
    title: String? = nil, source: String? = nil, format: TableFormat = .markdown,
    columnAlignments: [TextAlignment] = [], columnWidths: [CGFloat?] = []
  ) {
    self.title = title
    self.source = source
    self.format = format
    self.columnAlignments = columnAlignments
    self.columnWidths = columnWidths
  }
}

enum TableFormat {
  case markdown
  case csv
  case tsv
  case json
  case structured
}

enum TableParseError: LocalizedError, Equatable {
  case invalidFormat(String)
  case malformedTable(String)
  case emptyContent
  case inconsistentColumnCount

  var errorDescription: String? {
    switch self {
    case .invalidFormat(let format):
      return "Unsupported table format: \(format)"
    case .malformedTable(let reason):
      return "Malformed table: \(reason)"
    case .emptyContent:
      return "No table content found"
    case .inconsistentColumnCount:
      return "Inconsistent number of columns across rows"
    }
  }
}

// MARK: - Main Table Parser

@MainActor
final class TableParser: ObservableObject {
  // MARK: - Public Interface

  /// Parse table data from various formats
  func parseTable(from content: String, format: TableFormat? = nil) throws -> ParsedTable {
    let detectedFormat: TableFormat = {
      if let format = format {
        return format
      } else {
        return self.detectFormat(content)
      }
    }()
    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedContent.isEmpty else {
      throw TableParseError.emptyContent
    }

    switch detectedFormat {
    case .markdown:
      return try self.parseMarkdownTable(trimmedContent)
    case .csv:
      return try self.parseCSVTable(trimmedContent, delimiter: ",")
    case .tsv:
      return try self.parseCSVTable(trimmedContent, delimiter: "\t")
    case .json:
      return try self.parseJSONTable(trimmedContent)
    case .structured:
      return try self.parseStructuredTable(trimmedContent)
    }
  }

  /// Parse table from a file
  func parseTableFromFile(at url: URL) throws -> ParsedTable {
    let content = try String(contentsOf: url, encoding: .utf8)
    let format = self.detectFormatFromFileExtension(url.pathExtension)
    return try self.parseTable(from: content, format: format)
  }

  /// Convert ParsedTable to EnhancedDataTableView format
  func toEnhancedDataTableView(_ table: ParsedTable) -> EnhancedDataTableView {
    let columns = table.headers.enumerated().map { index, header in
      let textAlignment =
        index < table.metadata.columnAlignments.count
        ? table.metadata.columnAlignments[index] : .leading
      let alignment = self.convertTextToHorizontalAlignment(textAlignment)
      let width =
        index < table.metadata.columnWidths.count ? table.metadata.columnWidths[index] : nil
      return EnhancedDataTableView.Column(header: header, width: width, alignment: alignment)
    }

    let rows = table.rows.map { row in
      EnhancedDataTableView.Row(cells: row)
    }

    return EnhancedDataTableView(columns: columns, rows: rows)
  }

  private func convertTextToHorizontalAlignment(_ textAlignment: TextAlignment) -> HorizontalAlignment {
    switch textAlignment {
    case .leading: return .leading
    case .center: return .center
    case .trailing: return .trailing
    }
  }

  // MARK: - Format Detection

  private func detectFormat(_ content: String) -> TableFormat {
    let lines = content.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    guard !lines.isEmpty else { return .structured }

    // Check for JSON
    if content.trimmingCharacters(in: .whitespaces).hasPrefix("{")
      || content.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
      return .json
    }

    // Check for markdown table (has | separator and --- line)
    if lines.contains(where: { $0.contains("|") }),
      lines.contains(where: { $0.contains("---") }) {
      return .markdown
    }

    // Check for CSV/TSV
    if lines[0].contains(",") && !lines[0].contains("|") {
      return .csv
    } else if lines[0].contains("\t") && !lines[0].contains("|") {
      return .tsv
    }

    // Default to structured
    return .structured
  }

  private func detectFormatFromFileExtension(_ fileExtension: String) -> TableFormat {
    switch fileExtension.lowercased() {
    case "csv":
      return .csv
    case "tsv":
      return .tsv
    case "json":
      return .json
    case "md", "markdown":
      return .markdown
    default:
      return .structured
    }
  }

  // MARK: - Markdown Table Parser

  func parseMarkdownTable(_ content: String) throws -> ParsedTable {
    let lines = content.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty && $0.hasPrefix("|") }

    guard lines.count >= 2 else {
      throw TableParseError.malformedTable(
        "Markdown table must have at least header and separator rows")
    }

    // Parse headers
    let headerLine = lines[0].trimmingCharacters(in: CharacterSet(charactersIn: "|"))
    let headers = self.parseCSVLine(headerLine, delimiter: "|")

    // Parse alignment from separator line
    let separatorLine = lines[1].trimmingCharacters(in: CharacterSet(charactersIn: "|"))
    let alignments = self.parseMarkdownAlignments(separatorLine)

    // Parse data rows
    var rows: [[String]] = []
    for line in lines.dropFirst(2) {
      let rowLine = line.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
      let row = self.parseCSVLine(rowLine, delimiter: "|")

      // Pad row if necessary
      let paddedRow = row + Array(repeating: "", count: max(0, headers.count - row.count))
      rows.append(Array(paddedRow.prefix(headers.count)))
    }

    let metadata = TableMetadata(
      format: TableFormat.markdown,
      columnAlignments: alignments
    )

    return ParsedTable(headers: headers, rows: rows, metadata: metadata)
  }

  private func parseMarkdownAlignments(_ separatorLine: String) -> [TextAlignment] {
    let columns = separatorLine.components(separatedBy: "|")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    return columns.map { column in
      if column.hasPrefix(":"), column.hasSuffix(":") {
        return TextAlignment.center
      } else if column.hasSuffix(":") {
        return TextAlignment.trailing
      } else {
        return TextAlignment.leading
      }
    }
  }

  // MARK: - CSV/TSV Parser

  private func parseCSVTable(_ content: String, delimiter: Character) throws -> ParsedTable {
    let lines = content.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    guard !lines.isEmpty else {
      throw TableParseError.emptyContent
    }

    // Parse headers
    let headers = self.parseCSVLine(lines[0], delimiter: String(delimiter))

    // Parse data rows
    var rows: [[String]] = []
    for line in lines.dropFirst() {
      let row = self.parseCSVLine(line, delimiter: String(delimiter))

      // Validate column count
      guard row.count == headers.count || row.isEmpty else {
        throw TableParseError.inconsistentColumnCount
      }

      // Pad row if necessary
      let paddedRow = row + Array(repeating: "", count: max(0, headers.count - row.count))
      rows.append(Array(paddedRow.prefix(headers.count)))
    }

    let format: TableFormat = delimiter == "," ? TableFormat.csv : TableFormat.tsv
    let metadata = TableMetadata(format: format)

    return ParsedTable(headers: headers, rows: rows, metadata: metadata)
  }

  private func parseCSVLine(_ line: String, delimiter: String) -> [String] {
    var result: [String] = []
    var current = ""
    var inQuotes = false

    for (index, char) in line.enumerated() {
      if char == "\"" {
        // Handle escaped quotes
        if index + 1 < line.count, line[line.index(line.startIndex, offsetBy: index + 1)] == "\"" {
          current.append("\"")
          // Skip the next quote
          continue
        } else {
          inQuotes.toggle()
        }
      } else if String(char) == delimiter, !inQuotes {
        result.append(current.trimmingCharacters(in: .whitespaces))
        current = ""
      } else {
        current.append(char)
      }
    }

    result.append(current.trimmingCharacters(in: .whitespaces))
    return result
  }

  // MARK: - JSON Table Parser

  private func parseJSONTable(_ content: String) throws -> ParsedTable {
    guard let data = content.data(using: .utf8) else {
      throw TableParseError.malformedTable("Invalid UTF-8 encoding")
    }

    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

    if let array = jsonObject as? [[String: Any]] {
      // Array of objects
      guard let firstRow = array.first else {
        throw TableParseError.emptyContent
      }

      let headers = Array(firstRow.keys)
      let rows = array.map { row in
        headers.map { key in
          if let value = row[key] {
            return String(describing: value)
          } else {
            return ""
          }
        }
      }

      let metadata = TableMetadata(format: TableFormat.json)
      return ParsedTable(headers: headers, rows: rows, metadata: metadata)
    } else if let dict = jsonObject as? [String: Any] {
      // Single object or structured format
      if let headers = dict["headers"] as? [String],
        let rows = dict["rows"] as? [[String]] {
        let metadata = TableMetadata(
          title: dict["title"] as? String,
          source: dict["source"] as? String,
          format: TableFormat.json
        )
        return ParsedTable(headers: headers, rows: rows, metadata: metadata)
      } else {
        throw TableParseError.malformedTable("JSON structure not recognized")
      }
    } else {
      throw TableParseError.malformedTable("JSON must be array of objects or structured table")
    }
  }

  // MARK: - Structured Text Parser

  private func parseStructuredTable(_ content: String) throws -> ParsedTable {
    let lines = content.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    guard !lines.isEmpty else {
      throw TableParseError.emptyContent
    }

    // Try to detect structure
    if lines[0].contains(":") {
      // Key-value pairs
      let headers = ["Property", "Value"]
      var rows: [[String]] = []

      for line in lines {
        let parts = line.split(separator: ":", maxSplits: 1)
        if parts.count == 2 {
          let key = parts[0].trimmingCharacters(in: .whitespaces)
          let value = parts[1].trimmingCharacters(in: .whitespaces)
          rows.append([String(key), String(value)])
        }
      }

      let metadata = TableMetadata(format: TableFormat.structured)
      return ParsedTable(headers: headers, rows: rows, metadata: metadata)
    } else {
      // Simple tabular structure
      let headers = lines[0].components(separatedBy: .whitespaces)
        .filter { !$0.isEmpty }

      var rows: [[String]] = []
      for line in lines.dropFirst() {
        let cells = line.components(separatedBy: .whitespaces)
          .filter { !$0.isEmpty }

        if !cells.isEmpty {
          let paddedRow = cells + Array(repeating: "", count: max(0, headers.count - cells.count))
          rows.append(Array(paddedRow.prefix(headers.count)))
        }
      }

      let metadata = TableMetadata(format: TableFormat.structured)
      return ParsedTable(headers: headers, rows: rows, metadata: metadata)
    }
  }
}

extension TableParser {
  /// Parse table from CSV string
  func parseCSV(from csv: String) throws -> ParsedTable {
    return try self.parseTable(from: csv, format: TableFormat.csv)
  }

  /// Create table from structured data
  func createTable<T>(from items: [T], columns: [(KeyPath<T, String>, String)]) -> ParsedTable {
    let headers = columns.map { $0.1 }
    let rows = items.map { item in
      columns.map { keyPath, _ in
        let value = item[keyPath: keyPath]
        return value.isEmpty ? "—" : value
      }
    }

    let metadata = TableMetadata(format: TableFormat.structured)
    return ParsedTable(headers: headers, rows: rows, metadata: metadata)
  }
}

// MARK: - SwiftUI Integration

extension ParsedTable {
  /// Convert to SwiftUI view
  func toSwiftUIView() -> EnhancedDataTableView {
    let parser = TableParser()
    return parser.toEnhancedDataTableView(self)
  }

  /// Export to markdown format
  func toMarkdown() -> String {
    var result = ""

    // Headers
    result += "| " + self.headers.joined(separator: " | ") + " |\n"

    // Separator
    result += "|" + self.headers.map { _ in " --- " }.joined(separator: "|") + "|\n"

    // Rows
    for row in self.rows {
      result += "| " + row.joined(separator: " | ") + " |\n"
    }

    return result
  }

  /// Export to CSV format
  func toCSV() -> String {
    var result = ""

    // Headers
    result += self.headers.map { self.escapeCSVField($0) }.joined(separator: ",") + "\n"

    // Rows
    for row in self.rows {
      result += row.map { self.escapeCSVField($0) }.joined(separator: ",") + "\n"
    }

    return result
  }

  private func escapeCSVField(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
      return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    return field
  }
}
