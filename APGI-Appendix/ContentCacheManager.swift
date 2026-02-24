import Combine
import Foundation
import SwiftUI

/// Manages offline caching of remote content
@MainActor
class ContentCacheManager: ObservableObject {
    static let shared = ContentCacheManager()

    @Published var isOfflineMode = false

    private let cacheDirectory: URL
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Create cache directory in application support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.cacheDirectory = appSupport.appendingPathComponent("APGI-Appendix", isDirectory: true).appendingPathComponent("Cache", isDirectory: true)

        try? FileManager.default.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)

        self.setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        self.networkManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOfflineMode = !isConnected
                if isConnected {
                    logInfo("Network restored - exiting offline mode", context: "ContentCacheManager")
                }
                else {
                    logInfo("Network lost - entering offline mode", context: "ContentCacheManager")
                }
            }
            .store(in: &self.cancellables)
    }

    /// Cache content with metadata
    func cacheContent(_ content: Data, for key: String, metadata: [String: Any]? = nil) {
        let cacheURL = self.cacheDirectory.appendingPathComponent(key)

        do {
            try content.write(to: cacheURL)

            // Cache metadata if provided
            if let metadata = metadata {
                let metadataURL = cacheURL.appendingPathExtension("metadata")
                let metadataData = try JSONSerialization.data(withJSONObject: metadata)
                try metadataData.write(to: metadataURL)
            }

            logInfo("Cached content for key: \(key)", context: "ContentCacheManager.cacheContent")
        }
        catch {
            logError(error, context: "ContentCacheManager.cacheContent", function: #function, file: #file, line: #line)
        }
    }

    /// Retrieve cached content
    func cachedContent(for key: String) -> Data? {
        let cacheURL = self.cacheDirectory.appendingPathComponent(key)

        do {
            let data = try Data(contentsOf: cacheURL)
            logInfo("Retrieved cached content for key: \(key)", context: "ContentCacheManager.cachedContent")
            return data
        }
        catch {
            logDebug("No cached content found for key: \(key)", context: "ContentCacheManager.cachedContent")
            return nil
        }
    }

    /// Check if content is cached
    func isCached(_ key: String) -> Bool {
        let cacheURL = self.cacheDirectory.appendingPathComponent(key)
        return FileManager.default.fileExists(atPath: cacheURL.path)
    }

    /// Get cache metadata
    func cacheMetadata(for key: String) -> [String: Any]? {
        let metadataURL = self.cacheDirectory.appendingPathComponent(key).appendingPathExtension("metadata")

        do {
            let data = try Data(contentsOf: metadataURL)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
        catch {
            return nil
        }
    }

    /// Clear specific cached content
    func clearCache(for key: String) {
        let cacheURL = self.cacheDirectory.appendingPathComponent(key)
        let metadataURL = cacheURL.appendingPathExtension("metadata")

        try? FileManager.default.removeItem(at: cacheURL)
        try? FileManager.default.removeItem(at: metadataURL)

        logInfo("Cleared cache for key: \(key)", context: "ContentCacheManager.clearCache")
    }

    /// Clear all cached content
    func clearAllCache() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try FileManager.default.removeItem(at: url)
            }
            logInfo("Cleared all cached content", context: "ContentCacheManager.clearAllCache")
        }
        catch {
            logError(error, context: "ContentCacheManager.clearAllCache", function: #function, file: #file, line: #line)
        }
    }

    /// Get cache size in bytes
    func cacheSize() -> UInt64 {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            return contents.reduce(0) { size, url in
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                    return size + UInt64(resourceValues.fileSize ?? 0)
                }
                catch {
                    return size
                }
            }
        }
        catch {
            return 0
        }
    }

    /// Cache remote content with fallback to cached version
    func fetchAndCache(from url: URL, cacheKey: String) async throws -> Data {
        // Try to fetch fresh content if online
        if self.networkManager.isConnected {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Cache the fresh content
                    let metadata: [String: Any] = [
                        "cachedAt": Date().timeIntervalSince1970,
                        "sourceURL": url.absoluteString,
                        "contentType": httpResponse.mimeType ?? "unknown",
                    ]
                    self.cacheContent(data, for: cacheKey, metadata: metadata)

                    logInfo("Fetched and cached fresh content for: \(url)", context: "ContentCacheManager.fetchAndCache")
                    return data
                }
            }
            catch {
                logWarning("Failed to fetch fresh content from \(url): \(error.localizedDescription)", context: "ContentCacheManager.fetchAndCache")
            }
        }

        // Fall back to cached content
        if let cachedData = cachedContent(for: cacheKey) {
            logInfo("Serving cached content for: \(url)", context: "ContentCacheManager.fetchAndCache")
            return cachedData
        }

        // No cached content available
        throw NSError(domain: "ContentCacheManager", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "No content available (offline and not cached)"])
    }

    /// Cache string content
    func cacheString(_ string: String, for key: String, encoding: String.Encoding = .utf8, metadata: [String: Any]? = nil) {
        guard let data = string.data(using: encoding) else { return }
        self.cacheContent(data, for: key, metadata: metadata)
    }

    /// Retrieve cached string
    func cachedString(for key: String, encoding: String.Encoding = .utf8) -> String? {
        guard let data = cachedContent(for: key) else { return nil }
        return String(data: data, encoding: encoding)
    }

    /// Cache Codable objects
    func cacheObject<T: Codable>(_ object: T, for key: String, metadata: [String: Any]? = nil) {
        do {
            let data = try JSONEncoder().encode(object)
            self.cacheContent(data, for: key, metadata: metadata)
        }
        catch {
            logError(error, context: "ContentCacheManager.cacheObject", function: #function, file: #file, line: #line)
        }
    }

    /// Retrieve cached Codable object
    func cachedObject<T: Codable>(for key: String) -> T? {
        guard let data = cachedContent(for: key) else { return nil }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        }
        catch {
            logError(error, context: "ContentCacheManager.cachedObject", function: #function, file: #file, line: #line)
            return nil
        }
    }
}
