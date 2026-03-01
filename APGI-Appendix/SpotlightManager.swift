import CoreSpotlight
import Foundation

// MARK: - Spotlight Manager

class SpotlightManager {
    static let shared = SpotlightManager()

    private init() {
    }

    func indexAllContent() {
        var searchableItems: [CSSearchableItem] = []

        for tab in Tab.allCases {
            let item = self.createSearchableItem(for: tab)
            searchableItems.append(item)
        }

        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                logError(error, context: "SpotlightManager.indexAllContent", function: #function, file: #file, line: #line)
            }
            else {
                logInfo("Successfully indexed \(searchableItems.count) items", context: "SpotlightManager.indexAllContent", function: #function, file: #file, line: #line)
            }
        }
    }

    func updateIndex(for tab: Tab) {
        let item = self.createSearchableItem(for: tab)
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                logError(error, context: "SpotlightManager.updateIndex", function: #function, file: #file, line: #line)
            }
        }
    }

    func removeFromIndex(_ tab: Tab) {
        let identifier = "com.apgi-framework.appendix.\(tab.rawValue)"
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier]) { error in
            if let error = error {
                logError(error, context: "SpotlightManager.removeFromIndex", function: #function, file: #file, line: #line)
            }
        }
    }

    private func createSearchableItem(for tab: Tab) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = tab.rawValue
        attributeSet.contentDescription = tab.shortTitle
        attributeSet.keywords = [tab.category.rawValue, "APGI", "consciousness", "framework"]
        attributeSet.displayName = tab.rawValue

        // Add more detailed content for better search results
        let fullContent = tab.fullContent
        attributeSet.contentDescription = fullContent.prefix(200) + (fullContent.count > 200 ? "..." : "")

        let identifier = "com.apgi-framework.appendix.\(tab.rawValue)"

        return CSSearchableItem(uniqueIdentifier: identifier,
                                domainIdentifier: "com.apgi-framework.appendix.content",
                                attributeSet: attributeSet)
    }
}
