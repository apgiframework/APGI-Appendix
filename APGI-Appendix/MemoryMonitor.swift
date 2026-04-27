import Combine
import Foundation
import Darwin
import MachO

/// Memory monitoring utility for leak detection and performance tracking
/// Uses system-level APIs for accurate memory statistics
@MainActor
class MemoryMonitor: ObservableObject {
  static let shared = MemoryMonitor()

  private var timer: Timer?
  @Published var memoryHistory: [MemoryStats] = []
  private let maxHistorySize = 100

  struct MemoryStats {
    let timestamp: Date
    let usedMemory: UInt64      // Process resident size
    let availableMemory: UInt64 // System free memory
    let totalMemory: UInt64     // System total physical memory
    let systemUsedMemory: UInt64 // System-wide used memory

    var memoryPressure: Double {
      return Double(systemUsedMemory) / Double(totalMemory)
    }

    var formattedUsedMemory: String {
      return ByteCountFormatter.string(fromByteCount: Int64(usedMemory), countStyle: .memory)
    }

    var formattedAvailableMemory: String {
      return ByteCountFormatter.string(
        fromByteCount: Int64(availableMemory), countStyle: .memory)
    }

    var formattedSystemUsed: String {
      return ByteCountFormatter.string(fromByteCount: Int64(systemUsedMemory), countStyle: .memory)
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

    logInfo(
      "Memory monitoring started with \(interval)s interval",
      context: "MemoryMonitor.startMonitoring")
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
      warnings.append(
        "Memory pressure consistently increasing to \(String(format: "%.1f%%", (pressures.last ?? 0) * 100))"
      )
    }

    // Check for high memory usage
    if let latest = recentStats.last, latest.memoryPressure > 0.9 {
      warnings.append(
        "High memory pressure: \(String(format: "%.1f%%", latest.memoryPressure * 100))")
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
    let processUsed = getProcessUsedMemory()
    let (systemUsed, systemFree) = getSystemMemoryStats()
    let total = ProcessInfo.processInfo.physicalMemory

    let stats = MemoryStats(
      timestamp: Date(),
      usedMemory: processUsed,
      availableMemory: systemFree,
      totalMemory: total,
      systemUsedMemory: systemUsed
    )

    self.memoryHistory.append(stats)

    // Keep history size manageable
    if self.memoryHistory.count > self.maxHistorySize {
      self.memoryHistory.removeFirst()
    }

    // Log significant memory pressure changes
    if stats.memoryPressure > 0.8 {
      logWarning(
        "High system memory pressure: \(stats.formattedSystemUsed) / \(ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory))",
        context: "MemoryMonitor.recordMemoryStats")
    }

    // Log memory stats at debug level
    logDebug(
      "Process: \(stats.formattedUsedMemory), System Free: \(stats.formattedAvailableMemory), System Used: \(stats.formattedSystemUsed)",
      context: "MemoryMonitor.recordMemoryStats")
  }

  /// Get process-specific memory usage (resident size)
  private func getProcessUsedMemory() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let kerr = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }

    return kerr == KERN_SUCCESS ? info.resident_size : 0
  }

  /// Get system-wide memory statistics using vm_statistics64
  private func getSystemMemoryStats() -> (used: UInt64, free: UInt64) {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

    let result = withUnsafeMutablePointer(to: &stats) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
      }
    }

    guard result == KERN_SUCCESS else {
      // Fallback to process-centric calculation if system call fails
      _ = ProcessInfo.processInfo.physicalMemory
      let pageSize = UInt64(getpagesize())
      let used = UInt64(stats.active_count + stats.inactive_count + stats.wire_count) * pageSize
      let free = UInt64(stats.free_count) * pageSize
      return (used, free)
    }

    let pageSize = UInt64(getpagesize())

    // Calculate system memory usage
    // Used = active + inactive + wired + compressor
    let usedPages = stats.active_count + stats.inactive_count + stats.wire_count + stats.compressor_page_count
    let freePages = stats.free_count

    let usedBytes = UInt64(usedPages) * pageSize
    let freeBytes = UInt64(freePages) * pageSize

    return (usedBytes, freeBytes)
  }
}
