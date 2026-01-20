import SwiftUI
import AppKit
import Combine
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
            sidebarView
        } content: {
            contentView
        } detail: {
            detailView
        }

        let configuredView = navSplitView
            .frame(minWidth: 1000, minHeight: 700)
            .environmentObject(bookmarkManager)

        let withCategoryChanges = configuredView
            .onChange(of: selectedCategory) { _, newValue in
                guard let newValue = newValue else {
                    selectedSection = nil
                    return
                }
                if let firstSection = newValue.sections.first {
                    selectedSection = firstSection
                }
            }

        let withNavigation = withCategoryChanges
            .onReceive(NotificationCenter.default.publisher(for: .navigateNext)) { _ in
                navigateToNext()
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigatePrevious)) { _ in
                navigateToPrevious()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
                themeManager.sidebarVisible.toggle()
            }

        let withZoom = withNavigation
            .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
                fontSize = min(24, fontSize + 2)
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
                fontSize = max(10, fontSize - 2)
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
                fontSize = 15.0
            }

        let withSearch = withZoom
            .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
                searchPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToSection)) { notification in
                if let section = notification.object as? String {
                    navigateToSection(section)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
                if let tab = notification.object as? Tab {
                    selectedSection = tab
                    selectedCategory = tab.category
                }
            }

        let withExport = withSearch
            .onReceive(NotificationCenter.default.publisher(for: .exportPDF)) { _ in
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.pdf]
                panel.nameFieldStringValue = "APGI-Framework-Section.pdf"
                panel.begin { response in
                    if response == .OK, let url = panel.url {
                        exportCurrentViewToPDF(url: url)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .exportCurrentSection)) { _ in
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.plainText]
                panel.nameFieldStringValue = "\(selectedSection?.rawValue ?? "section").txt"
                panel.begin { response in
                    if response == .OK, let url = panel.url {
                        do {
                            try (selectedSection?.content ?? "").write(to: url, atomically: true, encoding: .utf8)
                        } catch {
                            print("Failed to export section: \(error)")
                        }
                    }
                }
            }

        return withExport
            .onReceive(NotificationCenter.default.publisher(for: .openHelpGuide)) { _ in
                showHelpGuide()
            }
            .onReceive(NotificationCenter.default.publisher(for: .checkForUpdates)) { _ in
                checkForUpdates()
            }
            .onReceive(NotificationCenter.default.publisher(for: .copyCitation)) { _ in
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString("APGI Framework (2024). \(selectedSection?.rawValue ?? "")", forType: .string)
            }
    }

    private var sidebarView: some View {
        CategorySidebar(selection: $selectedCategory)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
    }

    private var contentView: some View {
        Group {
            if let category = selectedCategory {
                SectionList(category: category, selection: $selectedSection)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 350, max: 450)
            } else {
                Text("Select a category")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detailView: some View {
        ZStack {
            detailContentView
            focusModeOverlay
            searchOverlay
        }
        .toolbar {
            ToolbarItemGroup {
                NetworkStatusView()
                
                if let section = selectedSection {
                    BookmarkButton(tab: section)
                }

                Button {
                    themeManager.focusModeEnabled.toggle()
                } label: {
                    Image(systemName: "eye")
                }
                .apgiAccessibility(
                    label: "Focus mode",
                    hint: themeManager.focusModeEnabled ? "Exit focus mode" : "Enter focus mode",
                    traits: .isButton
                )

                Button {
                    searchPresented.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .keyboardShortcut("f", modifiers: [.command])
                .apgiAccessibility(
                    label: "Search",
                    hint: "Search all content",
                    traits: .isButton
                )

                if selectedSection != nil {
                    Menu {
                        Button("Export as PDF...") {
                            exportToPDF()
                        }
                        Button("Export as Text...") {
                            exportToText()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
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
                Button(action: { showInspector.toggle() }) {
                    Label("Toggle Inspector", systemImage: "sidebar.right")
                }
            }
        }
    }

    @ViewBuilder
    private var detailContentView: some View {
        if let section = selectedSection {
            HStack(spacing: 0) {
                DetailContentView(section: section, focusModeEnabled: $themeManager.focusModeEnabled)
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
    }

    @ViewBuilder
    private var focusModeOverlay: some View {
        if themeManager.focusModeEnabled, let section = selectedSection {
            FocusModeView(
                isEnabled: $themeManager.focusModeEnabled,
                content: section.content,
                title: section.rawValue
            )
        }
    }

    @ViewBuilder
    private var searchOverlay: some View {
        if searchPresented {
            SearchView(isPresented: $searchPresented) { tab in
                selectedCategory = tab.category
                selectedSection = tab
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let tabIdentifier = components.queryItems?.first(where: { $0.name == "tab" })?.value else {
            return
        }

        if let tab = Tab.allCases.first(where: { $0.rawValue == tabIdentifier }) {
            selectedSection = tab
            selectedCategory = tab.category
        }
    }

    // MARK: - Navigation Methods

    private func navigateToSection(_ section: String) {
        guard !section.isEmpty else { return }

        // Find the matching tab
        if let tab = Tab.allCases.first(where: { $0.rawValue.lowercased() == section.lowercased() }) {
            selectedCategory = tab.category
            selectedSection = tab
        } else {
            // Fallback for legacy section names
            switch section.lowercased() {
            case "biological":
                selectedCategory = .biological
                selectedSection = .biologicalImplementation
            case "neuromodulators":
                selectedCategory = .biological
                selectedSection = .neuromodulatorEffects
            case "clinical", "psychiatric":
                selectedCategory = .applications
                selectedSection = .psychiatricDisorders
            case "mathematical":
                selectedCategory = .theoretical
                selectedSection = .mathematicalModel
            default:
                print("Unknown section: \(section)")
            }
        }
    }

    private func navigateToNext() {
        guard let current = selectedSection else { return }
        let allTabs = Tab.allCases
        if let currentIndex = allTabs.firstIndex(of: current), currentIndex < allTabs.count - 1 {
            selectedSection = allTabs[currentIndex + 1]
            selectedCategory = selectedSection?.category
        }
    }

    private func navigateToPrevious() {
        guard let current = selectedSection else { return }
        let allTabs = Tab.allCases
        if let currentIndex = allTabs.firstIndex(of: current), currentIndex > 0 {
            selectedSection = allTabs[currentIndex - 1]
            selectedCategory = selectedSection?.category
        }
    }

    private func exportCurrentViewToPDF(url: URL) {
        // Get the current window's content view
        guard let window = NSApp.keyWindow,
              let contentView = window.contentView else {
            print("Error: Could not access window content view")
            return
        }

        // Create a print info for PDF export
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        printInfo.orientation = .portrait
        printInfo.leftMargin = 0.5
        printInfo.rightMargin = 0.5
        printInfo.topMargin = 0.5
        printInfo.bottomMargin = 0.5

        // Create print operation
        let printOperation = NSPrintOperation(view: contentView, printInfo: printInfo)
        printOperation.showsPrintPanel = false
        printOperation.showsProgressPanel = true

        // Set the output to PDF
        if let printOperationView = printOperation.view {
            let pdfData = printOperationView.dataWithPDF(inside: printOperationView.bounds)

            do {
                try pdfData.write(to: url)
                print("Successfully exported PDF to: \(url.path)")

                // Show success notification
                let alert = NSAlert()
                alert.messageText = "PDF Export Successful"
                alert.informativeText = "The PDF has been saved to:\n\(url.path)"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Show in Finder")

                let response = alert.runModal()
                if response == .alertSecondButtonReturn {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                }
            } catch {
                print("Error exporting PDF: \(error)")

                // Show error notification
                let alert = NSAlert()
                alert.messageText = "PDF Export Failed"
                alert.informativeText = "There was an error exporting the PDF:\n\(error.localizedDescription)"
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        } else {
            print("Error: Could not get print operation view")

            // Show error notification
            let alert = NSAlert()
            alert.messageText = "PDF Export Failed"
            alert.informativeText = "Could not access the view for PDF export."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showHelpGuide() {
        // Show help guide in a sheet or window
        let helpView = HelpView()
        let hostingController = NSHostingController(rootView: helpView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "APGI Framework Help"
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func checkForUpdates() {
        // Show update check in a sheet
        let updateView = UpdateCheckView()
        let hostingController = NSHostingController(rootView: updateView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Check for Updates"
        window.contentViewController = hostingController
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func exportToPDF() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "\(selectedSection?.shortTitle ?? "APGI-Content").pdf"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                exportCurrentViewToPDF(url: url)
            }
        }
    }

    private func exportToText() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(selectedSection?.shortTitle ?? "APGI-Content").txt"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                guard let tab = selectedSection else { return }

                let content = """
                APGI Framework - \(tab.shortTitle)
                =====================================

                \(tab.content)

                ---
                Generated by APGI Appendix App
                """

                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Export Failed"
                    alert.informativeText = "Could not save the text file: \(error.localizedDescription)"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
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
}
