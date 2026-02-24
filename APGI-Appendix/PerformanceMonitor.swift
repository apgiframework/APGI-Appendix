import Combine
import Foundation

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    private var inferenceTimes: [TimeInterval] = []
    private var fpsHistory: [Double] = []
    private var memoryUsageHistory: [Double] = []
    private let maxHistorySize = 100

    private var measurementsQueue = DispatchQueue(label: "com.apgi.performance", qos: .utility)

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
        self.measurementsQueue.async { [weak self] in
            self?.inferenceTimes.append(duration)
            if self?.inferenceTimes.count ?? 0 > self?.maxHistorySize ?? 0 {
                self?.inferenceTimes.removeFirst()
            }
        }
    }

    func recordFPS(_ fps: Double) {
        self.measurementsQueue.async { [weak self] in
            self?.fpsHistory.append(fps)
            if self?.fpsHistory.count ?? 0 > self?.maxHistorySize ?? 0 {
                self?.fpsHistory.removeFirst()
            }
        }
    }

    func recordMemoryUsage(_ usage: Double) {
        self.measurementsQueue.async { [weak self] in
            self?.memoryUsageHistory.append(usage)
            if self?.memoryUsageHistory.count ?? 0 > self?.maxHistorySize ?? 0 {
                self?.memoryUsageHistory.removeFirst()
            }
        }
    }

    func clearCaches() {
        self.measurementsQueue.async { [weak self] in
            self?.inferenceTimes.removeAll()
            self?.fpsHistory.removeAll()
            self?.memoryUsageHistory.removeAll()
        }
    }

    func reset() {
        self.clearCaches()
    }

    func getStatistics() -> PerformanceStats {
        guard !self.inferenceTimes.isEmpty else {
            return PerformanceStats(meanLatency: 0.0, p50Latency: 0.0, p95Latency: 0.0, throughput: 0.0)
        }

        let mean = self.averageInferenceTime
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
        return PerformanceReport(
            averageInferenceTime: self.averageInferenceTime,
            currentFPS: self.currentFPS,
            averageMemoryUsage: self.averageMemoryUsage,
            totalInferences: self.inferenceTimes.count,
            isPerformanceOptimal: self.isPerformanceOptimal()
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
