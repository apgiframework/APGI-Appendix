import Combine
import Foundation

/// Memory monitoring utility for leak detection and performance tracking
@MainActor
class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()

    private var timer: Timer?
    @Published var memoryHistory: [MemoryStats] = []
    private let maxHistorySize = 100

    struct MemoryStats {
        let timestamp: Date
        let usedMemory: UInt64
        let availableMemory: UInt64
        let totalMemory: UInt64

        var memoryPressure: Double {
            return Double(self.usedMemory) / Double(self.totalMemory)
        }

        var formattedUsedMemory: String {
            return ByteCountFormatter.string(fromByteCount: Int64(self.usedMemory), countStyle: .memory)
        }

        var formattedAvailableMemory: String {
            return ByteCountFormatter.string(fromByteCount: Int64(self.availableMemory), countStyle: .memory)
        }
    }

    private init() {
    }

    /// Start monitoring memory usage
    /// - Parameter interval: Monitoring interval in seconds (default 5.0)
    func startMonitoring(interval: TimeInterval = 5.0) {
        self.stopMonitoring()

        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.recordMemoryStats()
            }
        }
        self.timer?.tolerance = 0.1

        logInfo("Memory monitoring started with \(interval)s interval", context: "MemoryMonitor.startMonitoring")
    }

    /// Stop monitoring memory usage
    func stopMonitoring() {
        self.timer?.invalidate()
        self.timer = nil
        logInfo("Memory monitoring stopped", context: "MemoryMonitor.stopMonitoring")
    }

    /// Get current memory statistics
    func currentMemoryStats() -> MemoryStats? {
        return self.memoryHistory.last
    }

    /// Get memory usage history
    func memoryHistory(count: Int? = nil) -> [MemoryStats] {
        let history = self.memoryHistory
        if let count = count, count < history.count {
            return Array(history.suffix(count))
        }
        return history
    }

    /// Check for potential memory leaks by analyzing usage trends
    func detectPotentialLeaks() -> [String] {
        guard self.memoryHistory.count >= 3 else { return [] }

        var warnings: [String] = []
        let recentStats = self.memoryHistory.suffix(10)

        // Check for consistent upward trend
        let pressures = recentStats.map { $0.memoryPressure }
        let increasing = zip(pressures, pressures.dropFirst()).allSatisfy { $0 <= $1 }

        if increasing, pressures.last ?? 0 > 0.8 {
            warnings.append("Memory pressure consistently increasing to \(String(format: "%.1f%%", (pressures.last ?? 0) * 100))")
        }

        // Check for high memory usage
        if let latest = recentStats.last, latest.memoryPressure > 0.9 {
            warnings.append("High memory pressure: \(String(format: "%.1f%%", latest.memoryPressure * 100))")
        }

        return warnings
    }

    /// Force garbage collection (for testing purposes)
    func forceGarbageCollection() {
        // This is a best-effort attempt to trigger memory cleanup
        // In a real app, you might want to use more sophisticated techniques
        autoreleasepool {
            // Force run loop to process pending releases
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        logInfo("Garbage collection triggered", context: "MemoryMonitor.forceGarbageCollection")
    }

    private func recordMemoryStats() async {
        let stats = MemoryStats(
            timestamp: Date(),
            usedMemory: getUsedMemory(),
            availableMemory: getAvailableMemory(),
            totalMemory: ProcessInfo.processInfo.physicalMemory
        )

        self.memoryHistory.append(stats)

        // Keep history size manageable
        if self.memoryHistory.count > self.maxHistorySize {
            self.memoryHistory.removeFirst()
        }

        // Log significant memory pressure changes
        if stats.memoryPressure > 0.8 {
            logWarning("High memory pressure detected: \(stats.formattedUsedMemory) used",
                       context: "MemoryMonitor.recordMemoryStats")
        }

        // Log memory stats at debug level
        logDebug("Memory: \(stats.formattedUsedMemory) used, \(stats.formattedAvailableMemory) available",
                 context: "MemoryMonitor.recordMemoryStats")
    }

    private func getUsedMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }

    private func getAvailableMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let total = ProcessInfo.processInfo.physicalMemory
            return total - info.resident_size
        }

        return 0
    }
}
