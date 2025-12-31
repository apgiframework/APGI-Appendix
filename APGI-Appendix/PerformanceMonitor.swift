import Foundation
import Combine

class PerformanceMonitor {
    public static let shared = PerformanceMonitor()
    private var inferenceTimes: [TimeInterval] = []
    private var fpsHistory: [Double] = []
    private var memoryUsageHistory: [Double] = []
    private let maxHistorySize = 100
    
    private var measurementsQueue = DispatchQueue(label: "com.apgi.performance", qos: .utility)
    
    var averageInferenceTime: TimeInterval {
        guard !inferenceTimes.isEmpty else { return 0.0 }
        return inferenceTimes.reduce(0, +) / Double(inferenceTimes.count)
    }
    
    var currentFPS: Double {
        guard !fpsHistory.isEmpty else { return 0.0 }
        return fpsHistory.reduce(0, +) / Double(fpsHistory.count)
    }
    
    var averageMemoryUsage: Double {
        guard !memoryUsageHistory.isEmpty else { return 0.0 }
        return memoryUsageHistory.reduce(0, +) / Double(memoryUsageHistory.count)
    }
    
    func recordInference(duration: TimeInterval) {
        measurementsQueue.async { [weak self] in
            self?.inferenceTimes.append(duration)
            if self?.inferenceTimes.count ?? 0 > self?.maxHistorySize ?? 0 {
                self?.inferenceTimes.removeFirst()
            }
        }
    }
    
    func recordFPS(_ fps: Double) {
        measurementsQueue.async { [weak self] in
            self?.fpsHistory.append(fps)
            if self?.fpsHistory.count ?? 0 > self?.maxHistorySize ?? 0 {
                self?.fpsHistory.removeFirst()
            }
        }
    }
    
    func recordMemoryUsage(_ usage: Double) {
        measurementsQueue.async { [weak self] in
            self?.memoryUsageHistory.append(usage)
            if self?.memoryUsageHistory.count ?? 0 > self?.maxHistorySize ?? 0 {
                self?.memoryUsageHistory.removeFirst()
            }
        }
    }
    
    func clearCaches() {
        measurementsQueue.async { [weak self] in
            self?.inferenceTimes.removeAll()
            self?.fpsHistory.removeAll()
            self?.memoryUsageHistory.removeAll()
        }
    }
    
    func reset() {
        clearCaches()
    }
    
    func getStatistics() -> PerformanceStats {
        guard !inferenceTimes.isEmpty else {
            return PerformanceStats(meanLatency: 0.0, p50Latency: 0.0, p95Latency: 0.0, throughput: 0.0)
        }

        let mean = averageInferenceTime
        let sorted = inferenceTimes.sorted()
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
            averageInferenceTime: averageInferenceTime,
            currentFPS: currentFPS,
            averageMemoryUsage: averageMemoryUsage,
            totalInferences: inferenceTimes.count,
            isPerformanceOptimal: isPerformanceOptimal()
        )
    }
    
    private func isPerformanceOptimal() -> Bool {
        return averageInferenceTime < 0.1 && currentFPS > 30 && averageMemoryUsage < 100
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
        • Average Inference Time: \(String(format: "%.3f", averageInferenceTime))s
        • Current FPS: \(String(format: "%.1f", currentFPS))
        • Average Memory Usage: \(String(format: "%.1f", averageMemoryUsage))MB
        • Total Inferences: \(totalInferences)
        • Status: \(isPerformanceOptimal ? "✅ Optimal" : "⚠️ Needs Optimization")
        """
    }
}
