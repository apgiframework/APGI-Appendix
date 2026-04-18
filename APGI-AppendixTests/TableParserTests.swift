import XCTest

@testable import APGI_Appendix

@MainActor
final class TableParserTests: XCTestCase {

  var parser: TableParser!

  override func setUp() {
    super.setUp()
    parser = TableParser()
  }

  func testMarkdownTableParsing() throws {
    let markdown = """
      | Header 1 | Header 2 | Header 3 |
      | :--- | :---: | ---: |
      | Cell 1.1 | Cell 1.2 | Cell 1.3 |
      | Cell 2.1 | Cell 2.2 | Cell 2.3 |
      """

    let table = try parser.parseTable(from: markdown)

    XCTAssertEqual(table.headers, ["Header 1", "Header 2", "Header 3"])
    XCTAssertEqual(table.rows.count, 2)
    XCTAssertEqual(table.rows[0], ["Cell 1.1", "Cell 1.2", "Cell 1.3"])
    XCTAssertEqual(table.metadata.format, .markdown)
    XCTAssertEqual(table.metadata.columnAlignments, [.leading, .center, .trailing])
  }

  func testCSVTableParsing() throws {
    let csv = """
      ID,Name,Value
      1,"Test, Name",100
      2,Simple Name,200
      """

    let table = try parser.parseTable(from: csv, format: .csv)

    XCTAssertEqual(table.headers, ["ID", "Name", "Value"])
    XCTAssertEqual(table.rows.count, 2)
    XCTAssertEqual(table.rows[0], ["1", "Test, Name", "100"])
    XCTAssertEqual(table.rows[1][1], "Simple Name")
  }

  func testJSONTableParsing() throws {
    let json = """
      [
          {"ID": "1", "Name": "System A", "Status": "Active"},
          {"ID": "2", "Name": "System B", "Status": "Inactive"}
      ]
      """

    let table = try parser.parseTable(from: json, format: .json)

    // Note: Headers order may vary in JSON dictionary keys,
    // but here we check for inclusion and count
    XCTAssertEqual(table.headers.count, 3)
    XCTAssertTrue(table.headers.contains("ID"))
    XCTAssertTrue(table.headers.contains("Name"))
    XCTAssertTrue(table.headers.contains("Status"))
    XCTAssertEqual(table.rows.count, 2)
  }

  func testStructuredTableParsing() throws {
    let structured = """
      Property: Value
      Precision: 0.85
      Threshold: 0.60
      """

    let table = try parser.parseTable(from: structured)

    XCTAssertEqual(table.headers, ["Property", "Value"])
    XCTAssertEqual(table.rows.count, 3)
    XCTAssertEqual(table.rows[1], ["Precision", "0.85"])
    XCTAssertEqual(table.metadata.format, .structured)
  }

  func testMalformedMarkdownTable() {
    let malformed = "| Header only |"
    XCTAssertThrowsError(try parser.parseTable(from: malformed, format: .markdown)) { error in
      XCTAssertTrue(error is TableParseError)
    }
  }

  func testEmptyTable() {
    let empty = ""
    XCTAssertThrowsError(try parser.parseTable(from: empty)) { error in
      XCTAssertEqual(error as? TableParseError, TableParseError.emptyContent)
    }
  }

  func testInconsistentCSV() {
    let inconsistent = """
      H1,H2
      R1C1,R1C2
      R2C1
      """
    XCTAssertThrowsError(try parser.parseTable(from: inconsistent, format: .csv)) { error in
      XCTAssertEqual(error as? TableParseError, TableParseError.inconsistentColumnCount)
    }
  }
}
