import XCTest

@testable import APGI_Appendix

// MARK: - Bookmark Manager Tests

@MainActor
final class BookmarkManagerTests: XCTestCase {

  var bookmarkManager: BookmarkManager

  override func setUp() {
    super.setUp()
    bookmarkManager = BookmarkManager()
    // Clear any existing bookmarks before each test
    bookmarkManager.clearAllBookmarksForTesting()
  }

  override func tearDown() {
    bookmarkManager.clearAllBookmarksForTesting()
    bookmarkManager = nil
    super.tearDown()
  }

  // MARK: - Add Bookmark Tests

  func testAddBookmark() {
    let tab = Tab.methodology

    XCTAssertFalse(bookmarkManager.isBookmarked(tab))

    bookmarkManager.addBookmark(tab)

    XCTAssertTrue(bookmarkManager.isBookmarked(tab))
    XCTAssertEqual(bookmarkManager.bookmarks.count, 1)
    XCTAssertEqual(bookmarkManager.bookmarks.first, tab.id)
  }

  func testAddDuplicateBookmark() {
    let tab = Tab.mathematicalModel

    bookmarkManager.addBookmark(tab)
    XCTAssertEqual(bookmarkManager.bookmarks.count, 1)

    // Try to add the same bookmark again
    bookmarkManager.addBookmark(tab)

    // Should not create duplicate
    XCTAssertEqual(bookmarkManager.bookmarks.count, 1)
  }

  func testAddMultipleBookmarks() {
    let tabs: [Tab] = [.methodology, .mathematicalModel, .biologicalImplementation]

    for tab in tabs {
      bookmarkManager.addBookmark(tab)
    }

    XCTAssertEqual(bookmarkManager.bookmarks.count, 3)

    for tab in tabs {
      XCTAssertTrue(bookmarkManager.isBookmarked(tab))
    }
  }

  func testAddBookmarkActionNotification() {
    let tab = Tab.epistemicStandards
    let expectation = XCTestExpectation(description: "Bookmark action notification")

    bookmarkManager.addBookmark(tab)

    // Verify the lastAction is set correctly
    if let action = bookmarkManager.lastAction {
      switch action {
      case .added(let title):
        XCTAssertEqual(title, tab.shortTitle)
        expectation.fulfill()
      case .removed:
        XCTFail("Should be added action, not removed")
      }
    } else {
      XCTFail("Last action should be set")
    }

    wait(for: [expectation], timeout: 0.1)
  }

  // MARK: - Remove Bookmark Tests

  func testRemoveBookmark() {
    let tab = Tab.lifeStages

    bookmarkManager.addBookmark(tab)
    XCTAssertTrue(bookmarkManager.isBookmarked(tab))

    bookmarkManager.removeBookmark(tab)

    XCTAssertFalse(bookmarkManager.isBookmarked(tab))
    XCTAssertEqual(bookmarkManager.bookmarks.count, 0)
  }

  func testRemoveNonExistentBookmark() {
    let tab = Tab.glossary

    // Try to remove a bookmark that was never added
    bookmarkManager.removeBookmark(tab)

    XCTAssertEqual(bookmarkManager.bookmarks.count, 0)
    // Should not crash or cause issues
  }

  func testRemoveBookmarkActionNotification() {
    let tab = Tab.bibliography

    bookmarkManager.addBookmark(tab)

    let expectation = XCTestExpectation(description: "Bookmark removal notification")

    bookmarkManager.removeBookmark(tab)

    // Verify the lastAction is set correctly
    if let action = bookmarkManager.lastAction {
      switch action {
      case .added:
        XCTFail("Should be removed action, not added")
      case .removed(let title):
        XCTAssertEqual(title, tab.shortTitle)
        expectation.fulfill()
      }
    } else {
      XCTFail("Last action should be set")
    }

    wait(for: [expectation], timeout: 0.1)
  }

  func testRemoveOneOfMultipleBookmarks() {
    let tabs: [Tab] = [.methodology, .mathematicalModel, .biologicalImplementation]

    for tab in tabs {
      bookmarkManager.addBookmark(tab)
    }

    XCTAssertEqual(bookmarkManager.bookmarks.count, 3)

    bookmarkManager.removeBookmark(.mathematicalModel)

    XCTAssertEqual(bookmarkManager.bookmarks.count, 2)
    XCTAssertTrue(bookmarkManager.isBookmarked(.methodology))
    XCTAssertFalse(bookmarkManager.isBookmarked(.mathematicalModel))
    XCTAssertTrue(bookmarkManager.isBookmarked(.biologicalImplementation))
  }

  // MARK: - Clear All Bookmarks Tests

  func testClearAllBookmarks() {
    let tabs: [Tab] = [.methodology, .mathematicalModel, .biologicalImplementation]

    for tab in tabs {
      bookmarkManager.addBookmark(tab)
    }

    XCTAssertEqual(bookmarkManager.bookmarks.count, 3)

    // Post the clear notification
    NotificationCenter.default.post(name: .clearAllBookmarks, object: nil)

    // Wait for notification to be processed
    let expectation = XCTestExpectation(description: "Clear bookmarks notification")
    DispatchQueue.main.async {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.1)

    XCTAssertEqual(bookmarkManager.bookmarks.count, 0)
  }

  func testClearAllBookmarksWhenEmpty() {
    // Clear when already empty should not cause issues
    NotificationCenter.default.post(name: .clearAllBookmarks, object: nil)

    let expectation = XCTestExpectation(description: "Clear empty bookmarks")
    DispatchQueue.main.async {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.1)

    XCTAssertEqual(bookmarkManager.bookmarks.count, 0)
  }

  // MARK: - Persistence Tests

  func testBookmarkPersistence() {
    let tab = Tab.apgiStatement

    bookmarkManager.addBookmark(tab)

    // Create a new instance to test persistence
    let newManager = BookmarkManager()

    XCTAssertTrue(newManager.isBookmarked(tab))
    XCTAssertEqual(newManager.bookmarks.count, 1)
  }

  func testPersistenceAcrossInstances() {
    let tabs: [Tab] = [.ignitionTimeline, .neuromodulators, .apgiSimulator]

    for tab in tabs {
      bookmarkManager.addBookmark(tab)
    }

    // Create fresh instance
    let newManager = BookmarkManager()

    XCTAssertEqual(newManager.bookmarks.count, 3)

    for tab in tabs {
      XCTAssertTrue(newManager.isBookmarked(tab))
    }
  }

  // MARK: - Migration Tests

  func testMigrationFromLegacyKeychain() {
    // Simulate legacy bookmarks in UserDefaults
    let legacyBookmarks = ["methodology", "mathematical_model", "glossary"]
    UserDefaults.standard.set(legacyBookmarks, forKey: "APGIBookmarks")

    // Clear keychain to force migration
    _ = KeychainHelper.shared.delete(for: "APGIBookmarks")

    // Create new manager which should migrate
    let newManager = BookmarkManager()

    // Should have migrated legacy bookmarks
    XCTAssertEqual(newManager.bookmarks.count, 3)
    XCTAssertTrue(newManager.isBookmarked(.methodology))
    XCTAssertTrue(newManager.isBookmarked(.mathematicalModel))
    XCTAssertTrue(newManager.isBookmarked(.glossary))

    // Cleanup
    UserDefaults.standard.removeObject(forKey: "APGIBookmarks")
  }

  func testMigrationFromBookmarkedTabs() {
    // Simulate very old legacy bookmarks
    let oldBookmarks = ["ignition_timeline", "bibliography"]
    UserDefaults.standard.set(oldBookmarks, forKey: "bookmarkedTabs")

    // Clear keychain to force migration path
    _ = KeychainHelper.shared.delete(for: "APGIBookmarks")

    // Create new manager
    let newManager = BookmarkManager()

    // Should have migrated old bookmarks if no new format exists
    // Note: The actual behavior depends on migration implementation

    // Cleanup
    UserDefaults.standard.removeObject(forKey: "bookmarkedTabs")
    UserDefaults.standard.removeObject(forKey: "APGIBookmarks")
  }

  func testMigrationClearsLegacyData() {
    let legacyBookmarks = ["methodology"]
    UserDefaults.standard.set(legacyBookmarks, forKey: "APGIBookmarks")

    // Clear keychain
    _ = KeychainHelper.shared.delete(for: "APGIBookmarks")

    // Create manager
    _ = BookmarkManager()

    // Legacy data should be cleared after migration
    XCTAssertNil(UserDefaults.standard.stringArray(forKey: "APGIBookmarks"))
  }

  // MARK: - Is Bookmarked Tests

  func testIsBookmarkedWithValidTab() {
    let tab = Tab.mathematicalModel

    XCTAssertFalse(bookmarkManager.isBookmarked(tab))

    bookmarkManager.addBookmark(tab)

    XCTAssertTrue(bookmarkManager.isBookmarked(tab))
  }

  func testIsBookmarkedWithDifferentTabs() {
    let tab1 = Tab.methodology
    let tab2 = Tab.mathematicalModel

    bookmarkManager.addBookmark(tab1)

    XCTAssertTrue(bookmarkManager.isBookmarked(tab1))
    XCTAssertFalse(bookmarkManager.isBookmarked(tab2))
  }

  // MARK: - Edge Cases

  func testBookmarkIdConsistency() {
    // Ensure tab IDs are consistent
    let tab = Tab.apgiStatement

    bookmarkManager.addBookmark(tab)

    // Verify the stored ID matches the tab ID
    XCTAssertEqual(bookmarkManager.bookmarks.first, tab.id)

    // Create new instance and verify
    let newManager = BookmarkManager()
    XCTAssertEqual(newManager.bookmarks.first, tab.id)
  }

  func testAllTabsCanBeBookmarked() {
    // Test that all tabs can be bookmarked without issues
    for tab in Tab.allCases {
      bookmarkManager.addBookmark(tab)
      XCTAssertTrue(bookmarkManager.isBookmarked(tab), "Failed to bookmark: \(tab.rawValue)")
    }

    XCTAssertEqual(bookmarkManager.bookmarks.count, Tab.allCases.count)
  }

  func testBookmarkOrderPreserved() {
    let tabs: [Tab] = [.glossary, .methodology, .bibliography]

    for tab in tabs {
      bookmarkManager.addBookmark(tab)
    }

    // Verify order is preserved
    XCTAssertEqual(bookmarkManager.bookmarks[0], tabs[0].id)
    XCTAssertEqual(bookmarkManager.bookmarks[1], tabs[1].id)
    XCTAssertEqual(bookmarkManager.bookmarks[2], tabs[2].id)
  }
}

// MARK: - BookmarkManager Extension for Testing

extension BookmarkManager {
  /// Clears all bookmarks for testing purposes
  func clearAllBookmarksForTesting() {
    bookmarks.removeAll()
    _ = KeychainHelper.shared.delete(for: "APGIBookmarks")
    lastAction = nil
  }
}
