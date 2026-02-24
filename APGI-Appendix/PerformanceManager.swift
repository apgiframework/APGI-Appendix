import AppKit
import Combine
import Darwin
import Foundation
import SwiftUI

@MainActor
final class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()

    @Published var isLowPowerModeEnabled = false
    @Published var memoryWarningReceived = false
    @Published var thermalState = ProcessInfo.ThermalState.nominal

    private var cancellables = Set<AnyCancellable>()
    private let contentCache = NSCache<NSString, CachedContent>()
    private let searchCache = NSCache<NSString, CachedSearchResults>()

    private init() {
        self.setupCacheConfiguration()
        self.setupSystemMonitoring()
    }

    private func setupCacheConfiguration() {
        self.contentCache.countLimit = 50
        self.contentCache.totalCostLimit = 100 * 1024 * 1024 // 100MB

        self.searchCache.countLimit = 100
        self.searchCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    private func setupSystemMonitoring() {
        // Monitor power state
        ProcessInfo.processInfo.publisher(for: \.isLowPowerModeEnabled)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLowPowerModeEnabled, on: self)
            .store(in: &self.cancellables)

        // Monitor thermal state
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.thermalState = ProcessInfo.processInfo.thermalState
            }
            .store(in: &self.cancellables)

        // Monitor memory pressure on macOS
        Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkMemoryPressure()
            }
            .store(in: &self.cancellables)
    }

    private func checkMemoryPressure() {
        // Check if system is under memory pressure
        let source = DispatchSource.makeMemoryPressureSource(eventMask: .warning, queue: .main)
        source.setEventHandler { [weak self] in
            self?.handleMemoryWarning()
        }
        source.resume()

        // Also check available memory as a fallback
        let availableMemory = self.getAvailableMemory()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryUsageRatio = Double(totalMemory - availableMemory) / Double(totalMemory)

        // Trigger memory warning if usage exceeds 80%
        if memoryUsageRatio > 0.8 {
            self.handleMemoryWarning()
        }
    }

    private func getAvailableMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        return kerr == KERN_SUCCESS ? UInt64(info.resident_size) : 0
    }

    private func handleMemoryWarning() {
        self.memoryWarningReceived = true
        self.contentCache.removeAllObjects()
        self.searchCache.removeAllObjects()

        // Reset after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.memoryWarningReceived = false
        }
    }

    // MARK: - Content Caching

    func getCachedContent(for key: String) -> CachedContent? {
        return self.contentCache.object(forKey: NSString(string: key))
    }

    func setCachedContent(_ content: CachedContent, for key: String) {
        self.contentCache.setObject(content, forKey: NSString(string: key))
    }

    // MARK: - Search Caching

    func getCachedSearchResults(for query: String) -> CachedSearchResults? {
        return self.searchCache.object(forKey: NSString(string: query))
    }

    func setCachedSearchResults(_ results: CachedSearchResults, for query: String) {
        self.searchCache.setObject(results, forKey: NSString(string: query))
    }

    // MARK: - Performance Optimization

    var shouldReduceAnimations: Bool {
        self.isLowPowerModeEnabled || self.thermalState == .fair || self.thermalState == .serious
    }

    var shouldLimitConcurrentOperations: Bool {
        self.memoryWarningReceived || self.thermalState == .serious || self.thermalState == .critical
    }

    func getOptimizedLoadingDelay(for contentType: ContentType) -> TimeInterval {
        let baseDelay: TimeInterval

        switch contentType {
        case .light:
            baseDelay = 0.05
        case .medium:
            baseDelay = 0.1
        case .heavy:
            baseDelay = 0.2
        case .critical:
            baseDelay = 0.3
        }

        if self.isLowPowerModeEnabled {
            return baseDelay * 1.5
        }

        if self.thermalState == .serious || self.thermalState == .critical {
            return baseDelay * 2.0
        }

        return baseDelay
    }
}

enum ContentType {
    case light
    case medium
    case heavy
    case critical
}

class CachedContent: NSObject {
    let content: String
    let timestamp: Date
    let cost: Int

    init(content: String, cost: Int = 1) {
        self.content = content
        self.timestamp = Date()
        self.cost = cost
        super.init()
    }
}

class CachedSearchResults: NSObject {
    let results: [SearchView.SearchResult]
    let timestamp: Date
    let cost: Int

    init(results: [SearchView.SearchResult], cost: Int = 1) {
        self.results = results
        self.timestamp = Date()
        self.cost = cost
        super.init()
    }
}
