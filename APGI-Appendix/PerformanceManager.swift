import Foundation
import SwiftUI
import Combine
import AppKit

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
        setupCacheConfiguration()
        setupSystemMonitoring()
    }
    
    private func setupCacheConfiguration() {
        contentCache.countLimit = 50
        contentCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        searchCache.countLimit = 100
        searchCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    private func setupSystemMonitoring() {
        // Monitor power state
        ProcessInfo.processInfo.publisher(for: \.isLowPowerModeEnabled)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLowPowerModeEnabled, on: self)
            .store(in: &cancellables)
        
        // Monitor thermal state
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.thermalState = ProcessInfo.processInfo.thermalState
            }
            .store(in: &cancellables)
        
        // Register for memory warnings - macOS doesn't have the same memory warning system as iOS
        // For macOS, we'll monitor memory pressure through other means
    }
    
    private func handleMemoryWarning() {
        memoryWarningReceived = true
        contentCache.removeAllObjects()
        searchCache.removeAllObjects()
        
        // Reset after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.memoryWarningReceived = false
        }
    }
    
    // MARK: - Content Caching
    
    func getCachedContent(for key: String) -> CachedContent? {
        return contentCache.object(forKey: NSString(string: key))
    }
    
    func setCachedContent(_ content: CachedContent, for key: String) {
        contentCache.setObject(content, forKey: NSString(string: key))
    }
    
    // MARK: - Search Caching
    
    func getCachedSearchResults(for query: String) -> CachedSearchResults? {
        return searchCache.object(forKey: NSString(string: query))
    }
    
    func setCachedSearchResults(_ results: CachedSearchResults, for query: String) {
        searchCache.setObject(results, forKey: NSString(string: query))
    }
    
    // MARK: - Performance Optimization
    
    var shouldReduceAnimations: Bool {
        isLowPowerModeEnabled || thermalState == .fair || thermalState == .serious
    }
    
    var shouldLimitConcurrentOperations: Bool {
        memoryWarningReceived || thermalState == .serious || thermalState == .critical
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
        
        if isLowPowerModeEnabled {
            return baseDelay * 1.5
        }
        
        if thermalState == .serious || thermalState == .critical {
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
