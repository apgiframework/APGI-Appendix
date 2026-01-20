import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Tab
    @State private var searchText = ""
    @State private var expandedSections: Set<NavigationSection> = [.foundations]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: APGISpacing.sm) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.largeTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.apgiPrimary, .apgiSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("APGI")
                            .font(APGITypography.titleLarge)
                            .fontWeight(.bold)

                        Text("Consciousness Framework")
                            .font(APGITypography.labelSmall)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(APGISpacing.lg)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search topics...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(APGISpacing.sm)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: APGIRadius.sm))
                .padding(.horizontal, APGISpacing.lg)
            }
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: APGISpacing.xs) {
                    ForEach(filteredSections) { (section: SidebarSection) in
                        NavigationSectionView(
                            section: section,
                            selection: $selectedTab,
                            isExpanded: isExpanded(for: section.section)
                        ) {
                            toggleSection(section.section)
                        }
                    }
                }
                .padding(APGISpacing.md)
            }

            Divider()

            HStack(spacing: APGISpacing.md) {
                Button(action: {}) {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {}) {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .buttonStyle(.plain)
            }
            .font(APGITypography.labelMedium)
            .foregroundStyle(.secondary)
            .padding(APGISpacing.lg)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 240, idealWidth: 280)
        .background(Color.surfacePrimary)
    }

    private var allSections: [SidebarSection] {
        NavigationSection.allCases.map { section in
            SidebarSection(
                section: section,
                title: section.rawValue,
                icon: section.icon,
                color: section.color,
                tabs: section.tabs
            )
        }
    }

    private var filteredSections: [SidebarSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return allSections
        }

        return allSections.compactMap { section in
            let sectionMatches = section.title.localizedCaseInsensitiveContains(query)

            let matchingTabs = section.tabs.filter { tab in
                tab.shortTitle.localizedCaseInsensitiveContains(query) ||
                tab.rawValue.localizedCaseInsensitiveContains(query) ||
                tab.searchIndexText.localizedCaseInsensitiveContains(query)
            }

            if sectionMatches {
                return section
            } else if !matchingTabs.isEmpty {
                return SidebarSection(
                    section: section.section,
                    title: section.title,
                    icon: section.icon,
                    color: section.color,
                    tabs: matchingTabs
                )
            } else {
                return nil
            }
        }
    }

    private func isExpanded(for section: NavigationSection) -> Bool {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return expandedSections.contains(section)
        } else {
            return true
        }
    }

    private func toggleSection(_ section: NavigationSection) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }
}

struct SidebarSection: Identifiable {
    let section: NavigationSection
    let title: String
    let icon: String
    let color: Color
    let tabs: [Tab]

    var id: NavigationSection { section }
}

struct NavigationSectionView: View {
    let section: SidebarSection
    @Binding var selection: Tab
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: APGISpacing.xs) {
            Button {
                onToggle()
            } label: {
                HStack {
                    Image(systemName: section.icon)
                        .font(.body)
                        .foregroundStyle(section.color)
                        .frame(width: 24)

                    Text(section.title)
                        .font(APGITypography.labelLarge)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, APGISpacing.sm)
                .padding(.horizontal, APGISpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: APGIRadius.sm)
                        .fill(.quaternary.opacity(0.3))
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(section.tabs, id: \.self) { tab in
                        NavigationItemRow(
                            item: tab,
                            isSelected: selection == tab
                        ) {
                            selection = tab
                        }
                    }
                }
                .padding(.leading, APGISpacing.xl)
            }
        }
    }
}

struct NavigationItemRow: View {
    let item: Tab
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: APGISpacing.sm) {
                Circle()
                    .fill(isSelected ? item.category.color : .secondary.opacity(0.3))
                    .frame(width: 6, height: 6)

                Text(item.shortTitle)
                    .font(APGITypography.bodyMedium)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                if item.hasTables {
                    Circle()
                        .fill(Color.apgiAccent)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, APGISpacing.sm)
            .padding(.horizontal, APGISpacing.md)
            .background {
                RoundedRectangle(cornerRadius: APGIRadius.sm)
                    .fill(
                        isSelected
                            ? item.category.color.opacity(0.15)
                            : (isHovered ? Color.secondary.opacity(0.3) : Color.clear)
                    )
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
