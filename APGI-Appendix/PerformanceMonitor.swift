import Combine
import Foundation

// MARK: - Performance Monitor Actor

@globalActor
actor PerformanceMonitorActor {
  static let shared = PerformanceMonitor()
}

actor PerformanceMonitor {
  static let shared = PerformanceMonitor()

  private var inferenceTimes: [TimeInterval] = []
  private var fpsHistory: [Double] = []
  private var memoryUsageHistory: [Double] = []
  private let maxHistorySize = 100

  // Thread-safe computed properties using async/await pattern
  func getAverageInferenceTime() async -> TimeInterval {
    return await PerformanceMonitorActor.shared.calculateAverageInferenceTime()
  }

  func getCurrentFPS() async -> Double {
    return await PerformanceMonitorActor.shared.calculateCurrentFPS()
  }

  func getAverageMemoryUsage() async -> Double {
    return await PerformanceMonitorActor.shared.calculateAverageMemoryUsage()
  }

  // Private calculation methods
  private func calculateAverageInferenceTime() -> TimeInterval {
    guard !inferenceTimes.isEmpty else { return 0.0 }
    return inferenceTimes.reduce(0, +) / Double(inferenceTimes.count)
  }

  private func calculateCurrentFPS() -> Double {
    guard !fpsHistory.isEmpty else { return 0.0 }
    return fpsHistory.reduce(0, +) / Double(fpsHistory.count)
  }

  private func calculateAverageMemoryUsage() -> Double {
    guard !memoryUsageHistory.isEmpty else { return 0.0 }
    return memoryUsageHistory.reduce(0, +) / Double(memoryUsageHistory.count)
  }

  func recordInference(duration: TimeInterval) {
    self.inferenceTimes.append(duration)
    if self.inferenceTimes.count > self.maxHistorySize {
      self.inferenceTimes.removeFirst()
    }
  }

  func recordFPS(_ fps: Double) {
    self.fpsHistory.append(fps)
    if self.fpsHistory.count > self.maxHistorySize {
      self.fpsHistory.removeFirst()
    }
  }

  func recordMemoryUsage(_ usage: Double) {
    self.memoryUsageHistory.append(usage)
    if self.memoryUsageHistory.count > self.maxHistorySize {
      self.memoryUsageHistory.removeFirst()
    }
  }

  func clearCaches() {
    self.inferenceTimes.removeAll()
    self.fpsHistory.removeAll()
    self.memoryUsageHistory.removeAll()
  }

  func reset() {
    self.clearCaches()
  }

  func getStatistics() async -> PerformanceStats {
    let times = self.inferenceTimes

    guard !times.isEmpty else {
      return PerformanceStats(meanLatency: 0.0, p50Latency: 0.0, p95Latency: 0.0, throughput: 0.0)
    }

    let mean = times.reduce(0, +) / Double(times.count)
    let sorted = times.sorted()
    let p50 = sorted[sorted.count / 2]
    let p95Index = min(Int(Double(sorted.count) * 0.95), sorted.count - 1)
    let p95 = sorted[p95Index]
    let throughput = mean > 0 ? 1.0 / mean : 0.0

    return PerformanceStats(
      meanLatency: mean * 1000,
      p50Latency: p50 * 1000,
      p95Latency: p95 * 1000,
      throughput: throughput
    )
  }

  func getPerformanceReport() async -> PerformanceReport {
    let (inferenceTimes, fpsHistory, memoryHistory) = (self.inferenceTimes, self.fpsHistory, self.memoryUsageHistory)

    let avgInference = inferenceTimes.isEmpty
      ? 0.0 : inferenceTimes.reduce(0, +) / Double(inferenceTimes.count)
    let avgFPS = fpsHistory.isEmpty
      ? 0.0 : fpsHistory.reduce(0, +) / Double(fpsHistory.count)
    let avgMem = memoryHistory.isEmpty
      ? 0.0 : memoryHistory.reduce(0, +) / Double(memoryHistory.count)

    return PerformanceReport(
      averageInferenceTime: avgInference,
      currentFPS: avgFPS,
      averageMemoryUsage: avgMem,
      totalInferences: inferenceTimes.count,
      isPerformanceOptimal: avgInference < 0.1 && avgFPS > 30 && avgMem < 100
    )
  }

  private func isPerformanceOptimal() async -> Bool {
    let report = await getPerformanceReport()
    return report.averageInferenceTime < 0.1 && report.currentFPS > 30 && report.averageMemoryUsage < 100
  }
}

struct PerformanceReport {
  let averageInferenceTime: TimeInterval
  let currentFPS: Double
  let averageMemoryUsage: Double
  let totalInferences: Int
  let isPerformanceOptimal: Bool

  var formattedReport: String {
    return """
      Performance Report:
      • Average Inference Time: \(String(format: "%.3f", self.averageInferenceTime))s
      • Current FPS: \(String(format: "%.1f", self.currentFPS))
      • Average Memory Usage: \(String(format: "%.1f", self.averageMemoryUsage))MB
      • Total Inferences: \(self.totalInferences)
      • Status: \(self.isPerformanceOptimal ? "✅ Optimal" : "⚠️ Needs Optimization")
      """
  }
}
