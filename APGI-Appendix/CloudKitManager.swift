import CloudKit
import Combine
import Foundation
import SwiftUI

// MARK: - Bookmark Model for CloudKit

struct Bookmark: Codable, Identifiable {
  let id: UUID
  let tabTitle: String
  let dateAdded: Date

  init(id: UUID = UUID(), tabTitle: String, dateAdded: Date = Date()) {
    self.id = id
    self.tabTitle = tabTitle
    self.dateAdded = dateAdded
  }

  /// CloudKit conversion
  func toCKRecord() -> CKRecord {
    let record = CKRecord(recordType: "Bookmark")
    record["id"] = self.id.uuidString
    record["tabTitle"] = self.tabTitle
    record["dateAdded"] = self.dateAdded
    return record
  }

  static func fromCKRecord(_ record: CKRecord) -> Bookmark? {
    guard let idString = record["id"] as? String,
      let id = UUID(uuidString: idString),
      let tabTitle = record["tabTitle"] as? String,
      let dateAdded = record["dateAdded"] as? Date
    else {
      return nil
    }
    return Bookmark(id: id, tabTitle: tabTitle, dateAdded: dateAdded)
  }
}

@MainActor
class CloudKitManager: ObservableObject {
  static let shared = CloudKitManager()

  private let container = CKContainer(identifier: "iCloud.com.apgi.appendix")
  private let privateDatabase: CKDatabase

  @Published var isSyncing = false
  @Published var syncStatus: String?
  @Published var lastSyncDate: Date?
  @Published var errorMessage: String?

  private init() {
    self.privateDatabase = self.container.privateCloudDatabase
    self.checkAccountStatus()
  }

  func checkAccountStatus() {
    Task { @MainActor in
      do {
        let accountStatus = try await self.container.accountStatus()
        switch accountStatus {
        case .available:
          self.isSyncing = false
          self.syncStatus = "iCloud available"
          ErrorLogger.shared.log("CloudKit account status checked: available")
        case .noAccount:
          self.isSyncing = false
          self.syncStatus = "No iCloud account"
          ErrorLogger.shared.log("CloudKit account status checked: no account")
        case .restricted:
          self.isSyncing = false
          self.syncStatus = "iCloud restricted"
          ErrorLogger.shared.log("CloudKit account status checked: restricted")
        case .temporarilyUnavailable:
          self.isSyncing = false
          self.syncStatus = "iCloud temporarily unavailable"
          ErrorLogger.shared.log("CloudKit account status checked: temporarily unavailable")
        case .couldNotDetermine:
          self.isSyncing = false
          self.syncStatus = "Could not determine iCloud status"
          ErrorLogger.shared.log("CloudKit account status checked: could not determine")
        @unknown default:
          self.isSyncing = false
          self.syncStatus = "Unknown iCloud status"
          ErrorLogger.shared.log("CloudKit account status checked: unknown")
        }
      } catch {
        self.errorMessage = "Failed to check iCloud status: \(error.localizedDescription)"
        ErrorLogger.shared.log("Failed to check iCloud status: \(error)")
      }
    }
  }

  // MARK: - Bookmark Sync

  func syncBookmarks(_ bookmarks: [Bookmark]) async {
    self.isSyncing = true
    defer { isSyncing = false }

    do {
      // Upload new/updated bookmarks
      for bookmark in bookmarks {
        let record = bookmark.toCKRecord()
        try await self.privateDatabase.save(record)
      }

      // Download bookmarks from iCloud
      let downloadedBookmarks = try await downloadBookmarks()

      await MainActor.run {
        self.lastSyncDate = Date()
        self.syncStatus = "Sync completed successfully"
        NotificationCenter.default.post(name: .bookmarksDidSync, object: downloadedBookmarks)
      }
    } catch {
      await MainActor.run {
        self.errorMessage = "Sync failed: \(error.localizedDescription)"
        self.syncStatus = "Sync failed"
      }
    }
  }

  private func downloadBookmarks() async throws -> [Bookmark] {
    let query = CKQuery(recordType: "Bookmark", predicate: NSPredicate(value: true))
    let (matchResults, _) = try await privateDatabase.records(matching: query)

    var bookmarks: [Bookmark] = []

    for (_, result) in matchResults {
      switch result {
      case .success(let record):
        if let bookmark = Bookmark.fromCKRecord(record) {
          bookmarks.append(bookmark)
        }
      case .failure(let error):
        logError(error, context: "CloudKitManager.fetchBookmarks")
      }
    }

    return bookmarks
  }

  // MARK: - Settings Sync

  func syncSettings(_ settings: [String: Any]) async {
    self.isSyncing = true
    defer { isSyncing = false }

    do {
      let record = CKRecord(recordType: "AppSettings")

      for (key, value) in settings {
        record[key] = value as? CKRecordValue
      }

      record["lastModified"] = Date()

      try await self.privateDatabase.save(record)

      await MainActor.run {
        self.lastSyncDate = Date()
        self.syncStatus = "Settings synced successfully"
      }
    } catch {
      await MainActor.run {
        self.errorMessage = "Settings sync failed: \(error.localizedDescription)"
      }
    }
  }

  func downloadSettings() async -> [String: Any]? {
    do {
      let query = CKQuery(recordType: "AppSettings", predicate: NSPredicate(value: true))
      let (matchResults, _) = try await privateDatabase.records(matching: query)

      for (_, result) in matchResults {
        switch result {
        case .success(let record):
          var settings: [String: Any] = [:]

          for key in record.allKeys() {
            if let value = record[key] {
              settings[key] = value
            }
          }

          return settings

        case .failure(let error):
          logError(error, context: "CloudKitManager.syncSettings")
        }
      }
    } catch {
      await MainActor.run {
        self.errorMessage = "Failed to download settings: \(error.localizedDescription)"
      }
    }

    return nil
  }

  // MARK: - Subscription Management

  func enableSync() async {
    do {
      let subscriptionID = "com.apgi.appendix.sync"

      // First check if subscription already exists or delete old one
      _ = try? await privateDatabase.deleteSubscription(withID: subscriptionID)

      // Create a subscription specifically for Bookmarks
      let predicate = NSPredicate(value: true)
      let subscription = CKQuerySubscription(
        recordType: "Bookmark",
        predicate: predicate,
        subscriptionID: subscriptionID,
        options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])

      // Configure notification info for the subscription
      let notificationInfo = CKSubscription.NotificationInfo()
      notificationInfo.shouldSendContentAvailable = true  // Silent notification
      subscription.notificationInfo = notificationInfo

      try await privateDatabase.save(subscription)

      await MainActor.run {
        self.syncStatus = "Background sync active"
        ErrorLogger.shared.log("CloudKit background sync enabled successfully")
      }
    } catch {
      await MainActor.run {
        self.errorMessage = "Failed to enable background sync: \(error.localizedDescription)"
        ErrorLogger.shared.log("Failed to enable CloudKit sync: \(error)")
      }
    }
  }

  func disableSync() async {
    do {
      let subscriptionID = "com.apgi.appendix.sync"
      try await privateDatabase.deleteSubscription(withID: subscriptionID)
      await MainActor.run {
        self.syncStatus = "Sync disabled"
      }
    } catch {
      await MainActor.run {
        self.errorMessage = "Failed to disable sync: \(error.localizedDescription)"
      }
    }
  }
}

// MARK: - CloudKit Sync View

struct CloudSyncView: View {
  @StateObject private var cloudKitManager = CloudKitManager.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      Form {
        Section("Sync Status") {
          HStack {
            Text("iCloud Status")
            Spacer()
            Text(self.cloudKitManager.syncStatus ?? "Checking...")
              .foregroundColor(.secondary)
          }

          if let lastSync = cloudKitManager.lastSyncDate {
            HStack {
              Text("Last Sync")
              Spacer()
              Text(lastSync, style: .relative)
                .foregroundColor(.secondary)
            }
          }

          if self.cloudKitManager.isSyncing {
            HStack {
              ProgressView()
                .scaleEffect(0.8)
              Text("Syncing...")
                .foregroundColor(.blue)
            }
          }
        }

        Section("Sync Actions") {
          Button("Sync Bookmarks") {
            Task {
              // Get bookmarks from BookmarkManager and convert to Bookmark objects
              let bookmarkManager = BookmarkManager.shared
              let bookmarks = bookmarkManager.bookmarks.compactMap { tabId -> Bookmark? in
                // Find the Tab enum case from the string ID
                if let tab = Tab.allCases.first(where: { $0.id == tabId }) {
                  return Bookmark(tabTitle: tab.shortTitle, dateAdded: Date())
                }
                return nil
              }
              await self.cloudKitManager.syncBookmarks(bookmarks)
            }
          }
          .disabled(self.cloudKitManager.isSyncing)

          Button("Sync Settings") {
            Task {
              let settings = UserDefaults.standard.dictionaryRepresentation()
              await self.cloudKitManager.syncSettings(settings)
            }
          }
          .disabled(self.cloudKitManager.isSyncing)

          Button("Enable Background Sync") {
            Task {
              await self.cloudKitManager.enableSync()
            }
          }
          .disabled(self.cloudKitManager.isSyncing)
        }

        Section("Troubleshooting") {
          Button("Check iCloud Status") {
            self.cloudKitManager.checkAccountStatus()
          }

          Button("Force Sync") {
            Task {
              // Force a full sync
              await self.cloudKitManager.syncBookmarks([])
            }
          }
          .disabled(self.cloudKitManager.isSyncing)
        }
      }
      .navigationTitle("iCloud Sync")
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button("Done") {
            self.dismiss()
          }
        }
      }
      .alert("Sync Error", isPresented: .constant(self.cloudKitManager.errorMessage != nil)) {
        Button("OK") {
          self.cloudKitManager.errorMessage = nil
        }
      } message: {
        if let errorMessage = cloudKitManager.errorMessage {
          Text(errorMessage)
        }
      }
    }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let bookmarksDidSync = Notification.Name("bookmarksDidSync")
}
