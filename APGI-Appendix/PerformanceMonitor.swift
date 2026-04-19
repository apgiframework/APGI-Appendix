import Combine
import Foundation

// MARK: - Performance Monitor Actor

@globalActor
struct PerformanceMonitorActor {
  static let shared = PerformanceMonitor()
}

@PerformanceMonitorActor
final class PerformanceMonitor {
  static let shared = PerformanceMonitor()

  private var inferenceTimes: [TimeInterval] = []
  private var fpsHistory: [Double] = []
  private var memoryUsageHistory: [Double] = []
  private let maxHistorySize = 100

  var averageInferenceTime: TimeInterval {
    guard !self.inferenceTimes.isEmpty else { return 0.0 }
    return self.inferenceTimes.reduce(0, +) / Double(self.inferenceTimes.count)
  }

  var currentFPS: Double {
    guard !self.fpsHistory.isEmpty else { return 0.0 }
    return self.fpsHistory.reduce(0, +) / Double(self.fpsHistory.count)
  }

  var averageMemoryUsage: Double {
    guard !self.memoryUsageHistory.isEmpty else { return 0.0 }
    return self.memoryUsageHistory.reduce(0, +) / Double(self.memoryUsageHistory.count)
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

  func getStatistics() -> PerformanceStats {
    guard !self.inferenceTimes.isEmpty else {
      return PerformanceStats(meanLatency: 0.0, p50Latency: 0.0, p95Latency: 0.0, throughput: 0.0)
    }

    let mean = self.inferenceTimes.reduce(0, +) / Double(self.inferenceTimes.count)
    let sorted = self.inferenceTimes.sorted()
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

  func getPerformanceReport() -> PerformanceReport {
    let avgInference =
      self.inferenceTimes.isEmpty
      ? 0.0 : self.inferenceTimes.reduce(0, +) / Double(self.inferenceTimes.count)
    let avgFPS =
      self.fpsHistory.isEmpty ? 0.0 : self.fpsHistory.reduce(0, +) / Double(self.fpsHistory.count)
    let avgMem =
      self.memoryUsageHistory.isEmpty
      ? 0.0 : self.memoryUsageHistory.reduce(0, +) / Double(self.memoryUsageHistory.count)

    return PerformanceReport(
      averageInferenceTime: avgInference,
      currentFPS: avgFPS,
      averageMemoryUsage: avgMem,
      totalInferences: self.inferenceTimes.count,
      isPerformanceOptimal: avgInference < 0.1 && avgFPS > 30 && avgMem < 100
    )
  }

  private func isPerformanceOptimal() -> Bool {
    return self.averageInferenceTime < 0.1 && self.currentFPS > 30 && self.averageMemoryUsage < 100
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
