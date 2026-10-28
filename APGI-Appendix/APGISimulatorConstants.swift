import Foundation

// MARK: - APGI Simulator Constants

enum APGISimulatorConstants {
  // MARK: - Network Architecture

  static let defaultHiddenSize: Int = 128

  static let defaultNumLevels: Int = 3

  static let defaultInputSize: Int = 64

  // MARK: - Time Constants (in milliseconds)

  static let defaultDtMs: Float = 10.0

  static let maxWindowMs: Float = 500.0

  static let surpriseDecayTau: Float = 200.0

  static let maxRefractoryMs: Float = 200.0

  // MARK: - Threshold Parameters

  static let baselineThreshold: Float = 1.0

  static let minThreshold: Float = 0.1

  static let maxThreshold: Float = 5.0

  static let thresholdRecoveryRate: Float = 2.0

  static let postIgnitionRefractory: Float = 0.5

  static let urgencyGainFactor: Float = 0.2

  // MARK: - Precision Parameters

  static let minPrecision: Float = 0.01

  static let maxPrecision: Float = 10.0

  static let baselineInteroceptivePrecision: Float = 0.1

  static let baselineExteroceptivePrecision: Float = 0.05

  // MARK: - Energy Parameters

  static let minEnergy: Float = 0.0

  static let maxEnergy: Float = 1.0

  static let defaultEnergyReserves: Float = 0.8

  static let energyDepletionRate: Float = 0.001

  // MARK: - Allostatic Load Parameters

  static let minAllostaticLoad: Float = 0.0

  static let maxAllostaticLoad: Float = 2.0

  static let allostaticIncreaseRate: Float = 0.01

  static let allostaticDecreaseRate: Float = 0.5

  // MARK: - Mathematical Model Parameters

  static let sigmoidSteepness: Float = 10.0

  static let betaTransition: Float = 10.0

  static let hysteresisFactor: Float = 0.2

  static let somaticBiasFactor: Float = 1.3

  // MARK: - Somatic Marker Computation Weights

  static let metabolicWeight: Float = 0.4

  static let cognitiveWeight: Float = 0.3

  static let affectiveWeight: Float = 0.3

  static let somaticMarkerScaling: Float = 2.0

  // MARK: - Cost-Benefit Parameters

  static let alphaBroadcast: Float = 1.0

  static let betaMaintenance: Float = 0.5

  static let benefitScaling: Float = 0.5

  // MARK: - History and Memory

  static let defaultHistoryLength: Int = 100

  static let precisionHistoryMax: Int = 1000

  // MARK: - Numerical Stability

  static let numericalEpsilon: Float = 1e-8

  // MARK: - Reservoir Parameters

  static let reservoirScaling: Float = 1.0

  static let reservoirSparsity: Float = 0.1

  // MARK: - UI Constants

  static let defaultZoomFactor: CGFloat = 1.2

  static let animationDuration: Double = 0.3

  static let transitionScale: CGFloat = 0.95

  static let standardPadding: CGFloat = 12

  static let standardVerticalPadding: CGFloat = 10

  static let standardVStackSpacing: CGFloat = 12

  static let largeVStackSpacing: CGFloat = 20

  static let smallVStackSpacing: CGFloat = 8

  static let defaultLearningRate: Float = 0.1

  static let norepinephrineVolatilityScaling: Float = 2.0

  static let acetylcholinePrecisionScaling: Float = 0.5

  static let neuromodulatoryBaselineOffset: Float = 0.5

  static let standardHStackSpacing: CGFloat = 16
}

/*
 These constants are based on empirical constraints from neuroscience literature:

 • τ ≈ 200 ms: Time constant for surprise decay (NMDA receptor decay, synaptic facilitation)
 • gamma_sig ≈ 5–10: Controls the steepness of the ignition sigmoid switch (Neural population gain)
 • γ ≈ 2 s⁻¹: Rate of homeostatic recovery for the threshold (Adaptive currents in thalamocortical circuits)
 • δ ≈ 0.3–0.5·θ₀: Post-ignition refractory scalar (Short-term depression in thalamocortical loops)
 • λ ≈ 0.1–0.3: Urgency gain factor (Phasic LC-NE response to surprise rate-of-change)
 • β ≈ 1.2–1.5: Somatic bias factor (Ratio of LC-NE innervation density)
 */
