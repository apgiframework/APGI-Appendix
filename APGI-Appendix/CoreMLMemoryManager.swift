import Foundation
import CoreML
import AppKit

class CoreMLMemoryManager {
    public static let shared = CoreMLMemoryManager()

    private var isUnderMemoryPressure = false
    private var memoryOptimizationLevel: MemoryOptimizationLevel = .normal

    public init() {
        setupMemoryMonitoring()
    }

    private func setupMemoryMonitoring() {
        // Monitor memory warnings - macOS doesn't have the same notification as iOS
        // We'll use a different approach for macOS
    }

    @objc private func handleMemoryWarning() {
        isUnderMemoryPressure = true
        memoryOptimizationLevel = .aggressive

        // Reset after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.isUnderMemoryPressure = false
            self.memoryOptimizationLevel = .normal
        }
    }

    func optimizeForMemoryPressure() {
        isUnderMemoryPressure = true
        memoryOptimizationLevel = .aggressive
    }

    func getOptimizedConfiguration(for baseConfig: APGIConfiguration) -> APGIConfiguration {
        switch memoryOptimizationLevel {
        case .normal:
            return baseConfig
        case .moderate:
            return APGIConfiguration(
                inputSize: max(baseConfig.inputSize / 2, 8),
                hiddenSize: max(baseConfig.hiddenSize / 2, 16),
                numLevels: max(baseConfig.numLevels - 1, 2),
                dtMs: baseConfig.dtMs,
                maxWindowMs: baseConfig.maxWindowMs,
                theta0: baseConfig.theta0,
                gamma: baseConfig.gamma,
                delta: baseConfig.delta,
                lambdaUrg: baseConfig.lambdaUrg,
                thetaMin: baseConfig.thetaMin,
                thetaMax: baseConfig.thetaMax,
                betaTransition: baseConfig.betaTransition,
                hysteresis: baseConfig.hysteresis,
                tauMin: baseConfig.tauMin,
                tauMax: baseConfig.tauMax,
                tauInteroBaseline: baseConfig.tauInteroBaseline,
                tauExteroBaseline: baseConfig.tauExteroBaseline,
                precisionMin: baseConfig.precisionMin,
                precisionMax: baseConfig.precisionMax,
                alphaBroadcast: baseConfig.alphaBroadcast,
                betaMaintenance: baseConfig.betaMaintenance,
                energyDepletionRate: baseConfig.energyDepletionRate,
                energyMin: baseConfig.energyMin,
                energyMax: baseConfig.energyMax,
                allostaticIncreaseRate: baseConfig.allostaticIncreaseRate,
                allostaticDecreaseRate: baseConfig.allostaticDecreaseRate,
                allostaticMin: baseConfig.allostaticMin,
                allostaticMax: baseConfig.allostaticMax,
                maxRefractoryMs: baseConfig.maxRefractoryMs,
                historyLength: max(baseConfig.historyLength / 2, 10),
                eps: baseConfig.eps,
                reservoirScaling: baseConfig.reservoirScaling,
                reservoirSparsity: baseConfig.reservoirSparsity,
                precisionHistoryMax: max(baseConfig.precisionHistoryMax / 2, 10)
            )
        case .aggressive:
            return APGIConfiguration(
                inputSize: max(baseConfig.inputSize / 4, 4),
                hiddenSize: max(baseConfig.hiddenSize / 4, 8),
                numLevels: 2,
                dtMs: baseConfig.dtMs * 2, // Slower updates
                maxWindowMs: baseConfig.maxWindowMs / 2,
                theta0: baseConfig.theta0,
                gamma: baseConfig.gamma,
                delta: baseConfig.delta,
                lambdaUrg: baseConfig.lambdaUrg,
                thetaMin: baseConfig.thetaMin,
                thetaMax: baseConfig.thetaMax,
                betaTransition: baseConfig.betaTransition,
                hysteresis: baseConfig.hysteresis,
                tauMin: baseConfig.tauMin,
                tauMax: baseConfig.tauMax,
                tauInteroBaseline: baseConfig.tauInteroBaseline,
                tauExteroBaseline: baseConfig.tauExteroBaseline,
                precisionMin: baseConfig.precisionMin,
                precisionMax: baseConfig.precisionMax,
                alphaBroadcast: baseConfig.alphaBroadcast,
                betaMaintenance: baseConfig.betaMaintenance,
                energyDepletionRate: baseConfig.energyDepletionRate,
                energyMin: baseConfig.energyMin,
                energyMax: baseConfig.energyMax,
                allostaticIncreaseRate: baseConfig.allostaticIncreaseRate,
                allostaticDecreaseRate: baseConfig.allostaticDecreaseRate,
                allostaticMin: baseConfig.allostaticMin,
                allostaticMax: baseConfig.allostaticMax,
                maxRefractoryMs: baseConfig.maxRefractoryMs,
                historyLength: 5, // Minimal history
                eps: baseConfig.eps,
                reservoirScaling: baseConfig.reservoirScaling,
                reservoirSparsity: baseConfig.reservoirSparsity,
                precisionHistoryMax: 5 // Minimal precision history
            )
        }
    }

    func shouldBatchInferences() -> Bool {
        return isUnderMemoryPressure
    }

    func getInferenceBatchSize() -> Int {
        switch memoryOptimizationLevel {
        case .normal: return 1
        case .moderate: return 2
        case .aggressive: return 4
        }
    }

    func getMemoryFootprintEstimate(for config: APGIConfiguration) -> Int64 {
        // Estimate memory usage in bytes
        let stateSize = config.hiddenSize * config.numLevels * 8 // Float64 per element
        let historySize = config.historyLength * config.inputSize * 8
        let precisionHistorySize = config.precisionHistoryMax * 8

        return Int64(stateSize + historySize + precisionHistorySize)
    }

    func shouldReduceModelComplexity() -> Bool {
        return memoryOptimizationLevel == .aggressive
    }
}

enum MemoryOptimizationLevel {
    case normal
    case moderate
    case aggressive
}

// MARK: - Memory-Efficient MLMultiArray Extensions

extension MLMultiArray {
    func createOptimizedCopy() throws -> MLMultiArray {
        let optimizedShape = self.shape.map { NSNumber(value: Int(truncating: $0) / 2) }
        return try MLMultiArray(shape: optimizedShape, dataType: self.dataType)
    }

    func reducePrecision() throws -> MLMultiArray {
        // Convert from Float64 to Float32 to save memory
        guard self.dataType == .double else { return self }

        let newArray = try MLMultiArray(shape: self.shape, dataType: .float32)

        for index in 0..<self.count {
            let value = self[index].doubleValue
            newArray[index] = NSNumber(value: Float(value))
        }

        return newArray
    }
}

// MARK: - Memory Pool for Reusable Arrays

class MLMultiArrayPool {
    static let shared = MLMultiArrayPool()
    private var availableArrays: [String: [MLMultiArray]] = [:]
    private let maxPoolSize = 10

    private init() {}

    func getArray(shape: [NSNumber], dataType: MLMultiArrayDataType) -> MLMultiArray {
        let key = arrayKey(shape: shape, dataType: dataType)

        if var pool = availableArrays[key], !pool.isEmpty {
            let array = pool.removeLast()
            availableArrays[key] = pool
            return array
        }

        return (try? MLMultiArray(shape: shape, dataType: dataType)) ?? MLMultiArray()
    }

    func returnArray(_ array: MLMultiArray) {
        let key = arrayKey(shape: array.shape, dataType: array.dataType)

        if var pool = availableArrays[key] {
            if pool.count < maxPoolSize {
                pool.append(array)
                availableArrays[key] = pool
            }
        } else {
            availableArrays[key] = [array]
        }
    }

    private func arrayKey(shape: [NSNumber], dataType: MLMultiArrayDataType) -> String {
        let shapeString = shape.map { "\($0)" }.joined(separator: "x")
        return "\(shapeString)_\(dataType.rawValue)"
    }

    func clearPool() {
        availableArrays.removeAll()
    }
}
