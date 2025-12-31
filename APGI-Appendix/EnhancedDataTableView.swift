import SwiftUI

struct EnhancedDataTableView: View {
    struct Column: Identifiable {
        let id = UUID()
        let header: String
        let width: CGFloat?
        let alignment: HorizontalAlignment

        init(header: String, width: CGFloat? = nil, alignment: HorizontalAlignment = .leading) {
            self.header = header
            self.width = width
            self.alignment = alignment
        }
    }

    struct Row: Identifiable {
        let id = UUID()
        let cells: [String]

        init(cells: [String]) {
            self.cells = cells
        }
    }

    let columns: [Column]
    let rows: [Row]

    @State private var sortColumn: Int = 0
    @State private var sortAscending: Bool = true
    @State private var searchText: String = ""

    private var filteredRows: [Row] {
        guard !searchText.isEmpty else { return rows }

        return rows.filter { row in
            row.cells.contains { cell in
                cell.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var sortedRows: [Row] {
        guard columns.indices.contains(sortColumn) else { return filteredRows }

        return filteredRows.sorted { lhs, rhs in
            let lhsValue = lhs.cells.indices.contains(sortColumn) ? lhs.cells[sortColumn] : ""
            let rhsValue = rhs.cells.indices.contains(sortColumn) ? rhs.cells[sortColumn] : ""

            let comparison = lhsValue.localizedStandardCompare(rhsValue)
            if sortAscending {
                return comparison == .orderedAscending
            }
            return comparison == .orderedDescending
        }
    }

    private func frameAlignment(for horizontalAlignment: HorizontalAlignment) -> Alignment {
        switch horizontalAlignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return .center
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search table...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                    Button {
                        if sortColumn == index {
                            sortAscending.toggle()
                        } else {
                            sortColumn = index
                            sortAscending = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(column.header)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)

                            if sortColumn == index {
                                Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundStyle(.primary)
                        .frame(
                            maxWidth: column.width == nil ? .infinity : column.width,
                            alignment: frameAlignment(for: column.alignment)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.quaternary)

                    if index < columns.count - 1 {
                        Divider()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(sortedRows.enumerated()), id: \.offset) { index, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.cells.enumerated()), id: \.offset) { cellIndex, cell in
                                Text(cell)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.primary)
                                    .frame(
                                        maxWidth: columns.indices.contains(cellIndex) && columns[cellIndex].width == nil ? .infinity : (columns.indices.contains(cellIndex) ? columns[cellIndex].width : nil),
                                        alignment: columns.indices.contains(cellIndex) ? frameAlignment(for: columns[cellIndex].alignment) : .leading
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)

                                if cellIndex < row.cells.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .background(index % 2 == 0 ? Color.clear : Color.primary.opacity(0.02))

                        if index < sortedRows.count - 1 {
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
}
