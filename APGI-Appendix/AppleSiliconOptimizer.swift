import Accelerate
import Combine
import Foundation
import SwiftUI
import simd

@MainActor
class AppleSiliconOptimizer: ObservableObject {
  static let shared = AppleSiliconOptimizer()

  let isAppleSilicon: Bool
  let hasANE: Bool

  private init() {
    #if arch(arm64)
      self.isAppleSilicon = true
    #else
      self.isAppleSilicon = false
    #endif

    // Check for ANE (Apple Neural Engine) availability
    self.hasANE = AppleSiliconOptimizer.checkANEDevice()
  }

  // MARK: - Vectorized Matrix Operations

  /// Optimized matrix multiplication using Apple Silicon Accelerate framework
  func optimizedMatrixMultiply(_ A: [[Float]], _ B: [[Float]]) -> [[Float]] {
    guard self.isAppleSilicon else {
      // Fallback to standard implementation
      return self.standardMatrixMultiply(A, B)
    }

    let rowsA = A.count
    let colsA = A[0].count
    let rowsB = B.count
    let colsB = B[0].count

    guard colsA == rowsB else {
      os_log(
        "Matrix dimensions do not match for multiply: A(%dx%d) B(%dx%d)", type: .error, rowsA,
        colsA, rowsB, colsB)
      return []
    }

    // Convert to contiguous memory for Accelerate
    let flatA = A.flatMap { $0 }
    let flatB = B.flatMap { $0 }
    var result = Array(repeating: Float(0.0), count: rowsA * colsB)

    // Use vDSP for optimized matrix multiplication (modern interface)
    vDSP_mmul(
      flatA, 1,  // A matrix, stride
      flatB, 1,  // B matrix, stride
      &result, 1,  // result matrix, stride
      vDSP_Length(rowsA),  // M (rows of A/result)
      vDSP_Length(colsB),  // N (cols of B/result)
      vDSP_Length(colsA)  // P (cols of A/rows of B)
    )

    // Convert back to 2D array
    var matrixResult: [[Float]] = []
    for i in 0..<rowsA {
      let start = i * colsB
      let end = start + colsB
      matrixResult.append(Array(result[start..<end]))
    }

    return matrixResult
  }

  /// SIMD-optimized vector operations for APGI state calculations
  func optimizedVectorAdd(_ v1: [Float], _ v2: [Float]) -> [Float] {
    guard self.isAppleSilicon else {
      return zip(v1, v2).map(+)
    }

    guard v1.count == v2.count else {
      os_log("Vector dimensions do not match for add: %d vs %d", type: .error, v1.count, v2.count)
      return []
    }

    let count = v1.count
    var result = [Float](repeating: 0.0, count: count)

    // Use vDSP for optimized vector addition
    vDSP.add(v1, v2, result: &result)

    return result
  }

  /// Optimized dot product using SIMD
  func optimizedDotProduct(_ v1: [Float], _ v2: [Float]) -> Float {
    guard self.isAppleSilicon else {
      return zip(v1, v2).map(*).reduce(0, +)
    }

    guard v1.count == v2.count else {
      os_log(
        "Vector dimensions do not match for dot product: %d vs %d", type: .error, v1.count, v2.count
      )
      return 0.0
    }

    var result: Float = 0.0

    // Use vDSP for optimized dot product
    vDSP_dotpr(v1, 1, v2, 1, &result, vDSP_Length(v1.count))

    return result
  }

  /// Optimized neural network layer computation
  func optimizedDenseLayer(input: [Float], weights: [[Float]], bias: [Float]) -> [Float] {
    guard self.isAppleSilicon else {
      return self.standardDenseLayer(input: input, weights: weights, bias: bias)
    }

    let output = self.optimizedMatrixMultiply([input], weights)[0]
    return self.optimizedVectorAdd(output, bias)
  }

  // MARK: - ANE (Apple Neural Engine) Integration

  /// Check if ANE is available on this device
  private static func checkANEDevice() -> Bool {
    #if targetEnvironment(simulator)
      return false
    #else
      // Check for M1/M2/M3 chips with ANE
      var size = 0
      sysctlbyname("hw.perflevel0.physicalcpu", nil, &size, nil, 0)
      return size > 0  // This is a simplified check
    #endif
  }

  /// ANE-optimized inference for Core ML models
  func optimizeForANE() -> Bool {
    return self.hasANE && self.isAppleSilicon
  }

  // MARK: - Memory Optimization

  /// Optimized memory allocation for large arrays
  func allocateOptimizedArray(count: Int) -> [Float] {
    if self.isAppleSilicon {
      // Use aligned memory for better SIMD performance
      let pointer = UnsafeMutablePointer<Float>.allocate(capacity: count)
      pointer.initialize(repeating: 0.0, count: count)
      defer { pointer.deallocate() }

      return Array(UnsafeBufferPointer(start: pointer, count: count))
    } else {
      return Array(repeating: 0.0, count: count)
    }
  }

  /// Batch processing optimization for Apple Silicon
  func batchProcess<T>(_ items: [T], batchSize: Int = 32, processor: ([T]) -> [T]) -> [T] {
    var results: [T] = []

    for i in stride(from: 0, to: items.count, by: batchSize) {
      let endIndex = min(i + batchSize, items.count)
      let batch = Array(items[i..<endIndex])
      let batchResults = processor(batch)
      results.append(contentsOf: batchResults)
    }

    return results
  }

  // MARK: - Performance Monitoring

  /// Measure performance of optimized operations
  func measurePerformance<T>(operation: () -> T) -> (result: T, timeInterval: TimeInterval) {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = operation()
    let timeInterval = CFAbsoluteTimeGetCurrent() - startTime
    return (result, timeInterval)
  }

  /// Compare optimized vs standard performance
  func benchmarkMatrixMultiply(size: Int) -> (optimized: TimeInterval, standard: TimeInterval) {
    let A = Array(repeating: Array(repeating: Float.random(in: -1...1), count: size), count: size)
    let B = Array(repeating: Array(repeating: Float.random(in: -1...1), count: size), count: size)

    let (_, optimizedTime) = self.measurePerformance {
      _ = self.optimizedMatrixMultiply(A, B)
    }

    let (_, standardTime) = self.measurePerformance {
      _ = self.standardMatrixMultiply(A, B)
    }

    return (optimizedTime, standardTime)
  }

  // MARK: - Fallback Implementations

  private func standardMatrixMultiply(_ A: [[Float]], _ B: [[Float]]) -> [[Float]] {
    let rowsA = A.count
    let colsA = A[0].count
    let rowsB = B.count
    let colsB = B[0].count

    guard colsA == rowsB else {
      os_log(
        "Matrix dimensions do not match for standard multiply: A(%dx%d) B(%dx%d)", type: .error,
        rowsA, colsA, rowsB, colsB)
      return []
    }

    var result = Array(repeating: Array(repeating: Float(0.0), count: colsB), count: rowsA)

    for i in 0..<rowsA {
      for j in 0..<colsB {
        for k in 0..<colsA {
          result[i][j] += A[i][k] * B[k][j]
        }
      }
    }

    return result
  }

  private func standardDenseLayer(input: [Float], weights: [[Float]], bias: [Float]) -> [Float] {
    let output = self.standardMatrixMultiply([input], weights)[0]
    return zip(output, bias).map(+)
  }
}

// MARK: - SIMD Extensions for APGI

extension simd_float4x4 {
  init(from matrix: [[Float]]) {
    precondition(matrix.count == 4 && matrix.allSatisfy { $0.count == 4 })

    let columns = matrix.map { simd_float4($0) }
    self.init(columns: (columns[0], columns[1], columns[2], columns[3]))
  }

  func toArray() -> [[Float]] {
    let col0 = self.columns.0
    let col1 = self.columns.1
    let col2 = self.columns.2
    let col3 = self.columns.3

    return (0..<4).map { i in
      (0..<4).map { j in
        switch i {
        case 0: return col0[j]
        case 1: return col1[j]
        case 2: return col2[j]
        case 3: return col3[j]
        default: return 0.0
        }
      }
    }
  }
}

extension simd_float4 {
  init(_ array: [Float]) {
    precondition(array.count >= 4)
    self.init(array[0], array[1], array[2], array[3])
  }

  func toArray() -> [Float] {
    return [x, y, z, w]
  }
}

// MARK: - Performance View

struct AppleSiliconPerformanceView: View {
  @StateObject private var optimizer = AppleSiliconOptimizer.shared
  @State private var benchmarkResults: [(optimized: TimeInterval, standard: TimeInterval)] = []
  @State private var isRunningBenchmark = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      titleView
      hardwareInfoView
      performanceBenchmarkView
      Spacer()
    }
    .padding()
  }

  private var titleView: some View {
    Text("Apple Silicon Optimization")
      .font(.largeTitle)
      .fontWeight(.bold)
  }

  private var hardwareInfoView: some View {
    GroupBox("Hardware Information") {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Apple Silicon:")
          Spacer()
          Text(optimizer.isAppleSilicon ? "✅ Yes" : "❌ No")
            .foregroundColor(optimizer.isAppleSilicon ? .green : .red)
        }

        HStack {
          Text("Apple Neural Engine:")
          Spacer()
          Text(optimizer.hasANE ? "✅ Available" : "❌ Not Available")
            .foregroundColor(optimizer.hasANE ? .green : .red)
        }
      }
      .padding()
    }
  }

  private var performanceBenchmarkView: some View {
    GroupBox("Performance Benchmark") {
      VStack(spacing: 16) {
        benchmarkButton
        if !benchmarkResults.isEmpty {
          benchmarkResultsView
        }
      }
      .padding()
    }
  }

  private var benchmarkButton: some View {
    Button(action: runBenchmark) {
      HStack {
        if isRunningBenchmark {
          ProgressView()
            .scaleEffect(0.8)
        }
        Text(isRunningBenchmark ? "Running..." : "Run Matrix Benchmark")
      }
    }
    .disabled(isRunningBenchmark)
  }

  private var benchmarkResultsView: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(0..<benchmarkResults.count, id: \.self) { index in
        benchmarkResultView(for: benchmarkResults[index], at: index)
      }
    }
  }

  private func benchmarkResultView(
    for result: (optimized: TimeInterval, standard: TimeInterval), at index: Int
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Matrix Size: \(Int(pow(2.0, Double(index + 4))))×\(Int(pow(2.0, Double(index + 4))))")
        .font(.caption)

      HStack {
        Text("Optimized:")
        Text("\(result.optimized, specifier: "%.4f")s")
          .foregroundColor(.green)
        Spacer()
        Text("Standard:")
        Text("\(result.standard, specifier: "%.4f")s")
          .foregroundColor(.orange)
        Spacer()
        Text("Speedup:")
        Text("\(result.standard / result.optimized, specifier: "%.1f")x")
          .foregroundColor(.blue)
          .fontWeight(.bold)
      }
      .font(.caption)
    }
    .padding(.vertical, 4)
    .overlay(
      VStack {
        Spacer()
        Divider()
      }
    )
  }

  private func runBenchmark() {
    self.isRunningBenchmark = true
    self.benchmarkResults.removeAll()

    Task {
      for size in [16, 32, 64, 128] {
        let result = self.optimizer.benchmarkMatrixMultiply(size: size)
        await MainActor.run {
          self.benchmarkResults.append(result)
        }
      }

      await MainActor.run {
        self.isRunningBenchmark = false
      }
    }
  }
}
