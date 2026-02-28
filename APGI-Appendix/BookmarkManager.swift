import Combine
import SwiftUI

/// Bookmark manager with persistence and feedback
@MainActor
class BookmarkManager: ObservableObject {
    @Published var bookmarks: [String] = []
    @Published var lastAction: BookmarkAction?

    private let bookmarksKey = "APGIBookmarks"

    enum BookmarkAction {
        case added(String)
        case removed(String)

        var message: String {
            switch self {
            case let .added(title):
                return "Bookmark added: \(title)"
            case let .removed(title):
                return "Bookmark removed: \(title)"
            }
        }
    }

    init() {
        self.loadBookmarks()
    }

    func addBookmark(_ tab: Tab) {
        guard !self.bookmarks.contains(tab.id) else { return }

        self.bookmarks.append(tab.id)
        self.saveBookmarks()
        self.lastAction = .added(tab.shortTitle)

        // Clear action after delay to prevent stale feedback
        let actionAtScheduleTime = self.lastAction
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            if self.lastAction?.message == actionAtScheduleTime?.message {
                self.lastAction = nil
            }
        }
    }

    func removeBookmark(_ tab: Tab) {
        guard let index = bookmarks.firstIndex(of: tab.id) else { return }

        self.bookmarks.remove(at: index)
        self.saveBookmarks()
        self.lastAction = .removed(tab.shortTitle)

        // Clear action after delay
        let actionAtScheduleTime = self.lastAction
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            if self.lastAction?.message == actionAtScheduleTime?.message {
                self.lastAction = nil
            }
        }
    }

    func isBookmarked(_ tab: Tab) -> Bool {
        self.bookmarks.contains(tab.id)
    }

    private func loadBookmarks() {
        // Try to load from Keychain first, fallback to UserDefaults for migration
        if let savedBookmarks: [String] = KeychainHelper.shared.retrieveObject(for: bookmarksKey) {
            self.bookmarks = savedBookmarks
        }
        else if let legacyBookmarks = UserDefaults.standard.stringArray(forKey: bookmarksKey) {
            // Migrate from UserDefaults to Keychain
            self.bookmarks = legacyBookmarks
            self.saveBookmarks()
            // Optionally clear legacy data
            UserDefaults.standard.removeObject(forKey: self.bookmarksKey)
        }
    }

    func saveBookmarks() {
        let success = KeychainHelper.shared.save(object: self.bookmarks, for: self.bookmarksKey)
        if !success {
            logError(NSError(domain: "BookmarkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save bookmarks to Keychain"]), context: "saveBookmarks()", function: #function, file: #file, line: #line)
        }
    }
}
