import SwiftUI
import Combine

// Bookmark manager with persistence and feedback
@MainActor
class BookmarkManager: ObservableObject {
    @Published var bookmarks: [String] = []
    @Published var lastAction: BookmarkAction?

    private let userDefaults = UserDefaults.standard
    private let bookmarksKey = "APGIBookmarks"

    enum BookmarkAction {
        case added(String)
        case removed(String)

        var message: String {
            switch self {
            case .added(let title):
                return "Bookmark added: \(title)"
            case .removed(let title):
                return "Bookmark removed: \(title)"
            }
        }
    }

    init() {
        loadBookmarks()
    }

    func addBookmark(_ tab: Tab) {
        guard !bookmarks.contains(tab.id) else { return }

        bookmarks.append(tab.id)
        saveBookmarks()
        lastAction = .added(tab.shortTitle)

        // Clear action after delay to prevent stale feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.lastAction?.message == self.lastAction?.message {
                self.lastAction = nil
            }
        }
    }

    func removeBookmark(_ tab: Tab) {
        guard let index = bookmarks.firstIndex(of: tab.id) else { return }

        bookmarks.remove(at: index)
        saveBookmarks()
        lastAction = .removed(tab.shortTitle)

        // Clear action after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.lastAction?.message == self.lastAction?.message {
                self.lastAction = nil
            }
        }
    }

    func isBookmarked(_ tab: Tab) -> Bool {
        bookmarks.contains(tab.id)
    }

    private func loadBookmarks() {
        if let savedBookmarks = userDefaults.stringArray(forKey: bookmarksKey) {
            bookmarks = savedBookmarks
        }
    }

    private func saveBookmarks() {
        userDefaults.set(bookmarks, forKey: bookmarksKey)
    }
}
