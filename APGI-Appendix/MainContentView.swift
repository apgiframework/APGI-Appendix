import SwiftUI

struct MainContentView: View {
    typealias ContentCategory = SectionCategory
    typealias ContentSection = Tab

    @State private var selectedCategory: ContentCategory? = Tab.methodology.category
    @State private var selectedSection: ContentSection? = .methodology
    @State private var showInspector = true
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var searchPresented: Bool = false
    @State private var focusModeEnabled: Bool = false
    @StateObject private var bookmarkManager = BookmarkManager()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            CategorySidebar(selection: $selectedCategory)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            if let category = selectedCategory {
                SectionList(category: category, selection: $selectedSection)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 350, max: 450)
            } else {
                Text("Select a category")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            ZStack {
                if let section = selectedSection {
                    HStack(spacing: 0) {
                        DetailContentView(section: section, focusModeEnabled: $focusModeEnabled)
                            .environmentObject(bookmarkManager)

                        if showInspector {
                            InspectorView(section: section)
                                .frame(width: 280)
                                .background(.bar)
                        }
                    }
                } else {
                    WelcomeView()
                }

                if searchPresented {
                    SearchView(isPresented: $searchPresented) { tab in
                        selectedCategory = tab.category
                        selectedSection = tab
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
            }

            ToolbarItem(placement: .automatic) {
                Button(action: { showInspector.toggle() }) {
                    Label("Toggle Inspector", systemImage: "sidebar.right")
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .environmentObject(bookmarkManager)
        .onChange(of: selectedCategory) { _, newValue in
            guard let newValue else {
                selectedSection = nil
                return
            }

            if let selectedSection, selectedSection.category == newValue {
                return
            }

            selectedSection = Tab.allCases.first(where: { $0.category == newValue })
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            searchPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSection)) { notification in
            if let section = notification.object as? String {
                navigateToSection(section)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateNext)) { _ in
            navigateToNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigatePrevious)) { _ in
            navigateToPrevious()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            toggleSidebarVisibility()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleInspector)) { _ in
            showInspector.toggle()
        }
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
            #selector(NSSplitViewController.toggleSidebar(_:)),
            with: nil
        )
    }

    private func toggleSidebarVisibility() {
        switch columnVisibility {
        case .all:
            columnVisibility = .detailOnly
        default:
            columnVisibility = .all
        }
    }

    private func navigateToSection(_ section: String) {
        switch section.lowercased() {
        case "biological":
            selectedCategory = .biological
            selectedSection = .biologicalImplementation
        case "neuromodulators":
            selectedCategory = .biological
            selectedSection = .neuromodulatorEffects
        case "clinical":
            selectedCategory = .applications
            selectedSection = .psychiatricDisorders
        default:
            break
        }
    }

    private func navigateToNext() {
        guard let selectedSection,
              let currentIndex = Tab.allCases.firstIndex(of: selectedSection),
              currentIndex < Tab.allCases.count - 1 else { return }

        let next = Tab.allCases[currentIndex + 1]
        self.selectedCategory = next.category
        self.selectedSection = next
    }

    private func navigateToPrevious() {
        guard let selectedSection,
              let currentIndex = Tab.allCases.firstIndex(of: selectedSection),
              currentIndex > 0 else { return }

        let previous = Tab.allCases[currentIndex - 1]
        self.selectedCategory = previous.category
        self.selectedSection = previous
    }
}

private struct CategorySidebar: View {
    @Binding var selection: SectionCategory?

    var body: some View {
        List(SectionCategory.allCases, id: \.self, selection: $selection) { category in
            Label(category.rawValue, systemImage: category.icon)
                .foregroundStyle(category.color)
                .tag(Optional(category))
        }
        .navigationTitle("Categories")
    }
}

private struct SectionList: View {
    let category: SectionCategory
    @Binding var selection: Tab?

    private var tabs: [Tab] {
        Tab.allCases.filter { $0.category == category }
    }

    var body: some View {
        List(tabs, id: \.self, selection: $selection) { tab in
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .foregroundStyle(category.color)
                Text(tab.shortTitle)
                Spacer()
            }
            .tag(Optional(tab))
        }
        .navigationTitle(category.rawValue)
    }
}

private struct DetailContentView: View {
    let section: Tab
    @Binding var focusModeEnabled: Bool

    var body: some View {
        ZStack {
            TabContentView(tab: section, selectedTab: .constant(section))

            if focusModeEnabled {
                FocusModeView(
                    isEnabled: $focusModeEnabled,
                    content: section.content,
                    title: section.rawValue
                )
            }
        }
    }
}

private struct InspectorView: View {
    let section: Tab

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspector")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text(section.shortTitle)
                    .font(.subheadline.weight(.semibold))

                Text(section.category.rawValue)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if section.hasTables {
                    Text("Includes tables")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }
}

private struct WelcomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APGI Framework")
                .font(.largeTitle.weight(.bold))
            Text("Select a category and section to begin.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
