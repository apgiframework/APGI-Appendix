import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Tab
    @State private var expandedSections: Set<SectionCategory> = [.theoretical]

    var body: some View {
        List {
            ForEach(SectionCategory.allCases, id: \.self) { category in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains(category) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedSections.insert(category)
                            } else {
                                expandedSections.remove(category)
                            }
                        }
                    )
                ) {
                    ForEach(tabs(for: category)) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            Label(tab.shortTitle, systemImage: tab.icon)
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .badge(tab.hasTables ? "📊" : nil)
                        .listRowBackground(
                            selectedTab == tab
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear
                        )
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 240, idealWidth: 280)
    }

    private func tabs(for category: SectionCategory) -> [Tab] {
        Tab.allCases.filter { $0.category == category }
    }
}
