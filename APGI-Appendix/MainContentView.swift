import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

struct MainContentView: View {
    typealias ContentCategory = SectionCategory
    typealias ContentSection = Tab

    @State private var selectedCategory: ContentCategory? = Tab.methodology.category
    @State private var selectedSection: ContentSection? = .methodology
    @State private var showInspector = true
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var searchPresented: Bool = false
    @AppStorage("contentFontSize") private var fontSize: Double = 15.0
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var navigationManager = KeyboardNavigationManager.shared
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        let navSplitView = NavigationSplitView(columnVisibility: $columnVisibility) {
            self.sidebarView
        } content: {
            self.contentView
        } detail: {
            self.detailView
        }

        let configuredView = navSplitView
            .frame(minWidth: 1000, minHeight: 700)
            .environmentObject(self.bookmarkManager)

        let withCategoryChanges = configuredView
            .onChange(of: self.selectedCategory) { _, newValue in
                guard let newValue = newValue else {
                    self.selectedSection = nil
                    return
                }
                if let firstSection = newValue.sections.first {
                    self.selectedSection = firstSection
                }
            }
            .onChange(of: self.selectedSection) { _, _ in
                // Update Handoff activity when section changes
                self.updateUserActivity()
            }

        let withNavigation = withCategoryChanges
            .onReceive(NotificationCenter.default.publisher(for: .navigateNext)) { _ in
                self.navigateToNext()
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigatePrevious)) { _ in
                self.navigateToPrevious()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
                self.themeManager.sidebarVisible.toggle()
            }

        let withZoom = withNavigation
            .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
                self.fontSize = min(24, self.fontSize + 2)
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
                self.fontSize = max(10, self.fontSize - 2)
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
                self.fontSize = 15.0
            }

        let withSearch = withZoom
            .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
                self.searchPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToSection)) { notification in
                if let section = notification.object as? String {
                    self.navigateToSection(section)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
                if let tab = notification.object as? Tab {
                    self.selectedSection = tab
                    self.selectedCategory = tab.category
                }
            }

        let withExport = withSearch
            .onReceive(NotificationCenter.default.publisher(for: .exportPDF)) { _ in
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.pdf]
                panel.nameFieldStringValue = "APGI-Framework-Section.pdf"
                panel.begin { response in
                    if response == .OK, let url = panel.url {
                        self.exportCurrentViewToPDF(url: url)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .exportCurrentSection)) { _ in
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.plainText]
                panel.nameFieldStringValue = "\(self.selectedSection?.rawValue ?? "section").txt"
                panel.begin { response in
                    if response == .OK, let url = panel.url {
                        do {
                            try (self.selectedSection?.content ?? "").write(to: url, atomically: true, encoding: .utf8)
                        }
                        catch {
                            print("Failed to export section: \(error)")
                        }
                    }
                }
            }

        return (withExport
            .onReceive(NotificationCenter.default.publisher(for: .openHelpGuide)) { _ in
                self.showHelpGuide()
            }
            .onReceive(NotificationCenter.default.publisher(for: .checkForUpdates)) { _ in
                self.checkForUpdates()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HandleHandoffActivity"))) { notification in
                if let userActivity = notification.object as? NSUserActivity {
                    self.handleIncomingHandoff(userActivity)
                }
            })
    }

    private var sidebarView: some View {
        CategorySidebar(selection: self.$selectedCategory)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
    }

    private var contentView: some View {
        Group {
            if let category = selectedCategory {
                SectionList(category: category, selection: self.$selectedSection)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 350, max: 450)
            }
            else {
                Text("Select a category")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detailView: some View {
        ZStack {
            self.detailContentView
            self.focusModeOverlay
            self.searchOverlay
        }
        .toolbar {
            ToolbarItemGroup {
                NetworkStatusView()

                if let section = selectedSection {
                    BookmarkButton(tab: section)
                }

                Button {
                    self.themeManager.focusModeEnabled.toggle()
                } label: {
                    Image(systemName: SFSymbols.focus)
                }
                .apgiAccessibility(
                    label: "Focus mode",
                    hint: self.themeManager.focusModeEnabled ? "Exit focus mode" : "Enter focus mode",
                    traits: .isButton
                )

                Button {
                    self.searchPresented.toggle()
                } label: {
                    Image(systemName: SFSymbols.search)
                }
                .keyboardShortcut("f", modifiers: [.command])
                .apgiAccessibility(
                    label: "Search",
                    hint: "Search all content",
                    traits: .isButton
                )

                if self.selectedSection != nil {
                    Menu {
                        Button("Export as PDF...") {
                            self.exportToPDF()
                        }
                        Button("Export as Text...") {
                            self.exportToText()
                        }
                    } label: {
                        Image(systemName: SFSymbols.share)
                    }
                    .apgiAccessibility(
                        label: "Export",
                        hint: "Export current section",
                        traits: .isButton
                    )
                }

                FontSizeControl()
            }

            ToolbarItem(placement: .automatic) {
                Button(action: { self.showInspector.toggle() }) {
                    Label("Toggle Inspector", systemImage: SFSymbols.sidebarRight)
                }
            }
        }
    }

    @ViewBuilder
    private var detailContentView: some View {
        if let section = selectedSection {
            HStack(spacing: 0) {
                DetailContentView(section: section, focusModeEnabled: self.$themeManager.focusModeEnabled)
                    .environmentObject(self.bookmarkManager)

                if self.showInspector {
                    InspectorView(section: section)
                        .frame(width: 280)
                        .background(.bar)
                }
            }
        }
        else {
            WelcomeView()
        }
    }

    @ViewBuilder
    private var focusModeOverlay: some View {
        if self.themeManager.focusModeEnabled, let section = selectedSection {
            FocusModeView(
                isEnabled: self.$themeManager.focusModeEnabled,
                content: section.content,
                title: section.rawValue
            )
        }
    }

    @ViewBuilder
    private var searchOverlay: some View {
        if self.searchPresented {
            SearchView(isPresented: self.$searchPresented) { tab in
                self.selectedCategory = tab.category
                self.selectedSection = tab
                self.setupHandoff()
            }
        }
    }

    @State var userActivity: NSUserActivity?

    // MARK: - Handoff Support

    func setupHandoff() {
        // Create user activity for current content
        self.updateUserActivity()
    }

    func updateUserActivity() {
        // End any existing activity
        self.userActivity?.invalidate()

        guard let section = selectedSection else {
            self.userActivity = nil
            return
        }

        // Create new activity for current section
        let activity = NSUserActivity(activityType: "com.apgi.appendix.content")
        activity.title = "Reading: \(section.shortTitle)"
        activity.userInfo = [
            "section": section.rawValue,
            "category": section.category.rawValue,
        ]
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = false

        // Set webpage URL for deep linking
        if let deepLinkURL = createDeepLinkURL(for: section) {
            activity.webpageURL = deepLinkURL
            activity.isEligibleForHandoff = true
        }

        activity.becomeCurrent()
        self.userActivity = activity

        logInfo("Updated Handoff activity for section: \(section.rawValue)", context: "MainContentView.updateUserActivity")
    }

    func createDeepLinkURL(for section: Tab) -> URL? {
        var components = URLComponents()
        components.scheme = "apgi-appendix"
        components.host = "content"
        components.queryItems = [
            URLQueryItem(name: "section", value: section.rawValue),
        ]
        return components.url
    }

    func handleIncomingHandoff(_ userActivity: NSUserActivity) {
        guard userActivity.activityType == "com.apgi.appendix.content",
              let userInfo = userActivity.userInfo,
              let sectionName = userInfo["section"] as? String
        else {
            return
        }

        // Navigate to the handed-off section
        self.navigateToSection(sectionName)
        logInfo("Handled incoming Handoff for section: \(sectionName)", context: "MainContentView.handleIncomingHandoff")
    }

    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let tabIdentifier = components.queryItems?.first(where: { $0.name == "tab" })?.value
        else {
            return
        }

        if let tab = Tab.allCases.first(where: { $0.rawValue == tabIdentifier }) {
            self.selectedSection = tab
            self.selectedCategory = tab.category
        }
    }

    // MARK: - Navigation Methods

    private func navigateToNext() {
        guard let currentCategory = selectedCategory,
              let currentSection = selectedSection else { return }

        let sections = currentCategory.sections
        if let currentIndex = sections.firstIndex(of: currentSection) {
            if currentIndex < sections.count - 1 {
                // Next section in current category
                self.selectedSection = sections[currentIndex + 1]
            }
            else {
                // Move to next category
                let allCategories = SectionCategory.allCases
                if let categoryIndex = allCategories.firstIndex(of: currentCategory),
                   categoryIndex < allCategories.count - 1
                {
                    let nextCategory = allCategories[categoryIndex + 1]
                    self.selectedCategory = nextCategory
                    self.selectedSection = nextCategory.sections.first
                }
            }
        }
    }

    private func navigateToPrevious() {
        guard let currentCategory = selectedCategory,
              let currentSection = selectedSection else { return }

        let sections = currentCategory.sections
        if let currentIndex = sections.firstIndex(of: currentSection) {
            if currentIndex > 0 {
                // Previous section in current category
                self.selectedSection = sections[currentIndex - 1]
            }
            else {
                // Move to previous category
                let allCategories = SectionCategory.allCases
                if let categoryIndex = allCategories.firstIndex(of: currentCategory),
                   categoryIndex > 0
                {
                    let prevCategory = allCategories[categoryIndex - 1]
                    self.selectedCategory = prevCategory
                    self.selectedSection = prevCategory.sections.last
                }
            }
        }
    }

    private func navigateToSection(_ sectionName: String) {
        if let tab = Tab.allCases.first(where: { $0.rawValue.lowercased() == sectionName.lowercased() }) {
            self.selectedCategory = tab.category
            self.selectedSection = tab
        }
    }

    // MARK: - Export Methods

    private func exportCurrentViewToPDF(url: URL) {
        // Implementation for PDF export
        // This would need to capture the current view and save as PDF
        print("Exporting current view to PDF: \(url)")
    }

    private func exportToPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(self.selectedSection?.rawValue ?? "section").pdf"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.exportCurrentViewToPDF(url: url)
            }
        }
    }

    private func exportToText() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(self.selectedSection?.rawValue ?? "section").txt"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try (self.selectedSection?.content ?? "").write(to: url, atomically: true, encoding: .utf8)
                }
                catch {
                    print("Failed to export section: \(error)")
                }
            }
        }
    }

    // MARK: - Help and Updates

    private func showHelpGuide() {
        if let url = URL(string: "https://docs.apgi-framework.org") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkForUpdates() {
        // This would integrate with UpdateManager
        print("Checking for updates...")
    }

    private struct CategorySidebar: View {
        @Binding var selection: SectionCategory?

        var body: some View {
            List(SectionCategory.allCases, id: \.self, selection: self.$selection) { category in
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
            Tab.allCases.filter { $0.category == self.category }
        }

        var body: some View {
            List(self.tabs, id: \.self, selection: self.$selection) { tab in
                HStack(spacing: 10) {
                    Image(systemName: tab.icon)
                        .foregroundStyle(self.category.color)
                    Text(tab.shortTitle)
                    Spacer()
                }
                .tag(Optional(tab))
            }
            .navigationTitle(self.category.rawValue)
        }
    }

    private struct DetailContentView: View {
        let section: Tab
        @Binding var focusModeEnabled: Bool

        var body: some View {
            ZStack {
                TabContentView(tab: self.section, selectedTab: .constant(self.section))

                if self.focusModeEnabled {
                    FocusModeView(
                        isEnabled: self.$focusModeEnabled,
                        content: self.section.content,
                        title: self.section.rawValue
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
                    Text(self.section.shortTitle)
                        .font(.subheadline.weight(.semibold))

                    Text(self.section.category.rawValue)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if self.section.hasTables {
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
}
