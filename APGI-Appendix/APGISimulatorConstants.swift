import Foundation

// MARK: - APGI Simulator Constants

/// Default neural network architecture parameters
struct APGISimulatorConstants {
    
    // MARK: - Network Architecture
    
    /// Default hidden layer size for neural networks
    static let defaultHiddenSize: Int = 128
    
    /// Default number of hierarchical levels
    static let defaultNumLevels: Int = 3
    
    /// Default input size for the simulator
    static let defaultInputSize: Int = 64
    
    // MARK: - Time Constants (in milliseconds)
    
    /// Default time step for simulation updates
    static let defaultDtMs: Float = 10.0
    
    /// Maximum time window for temporal integration
    static let maxWindowMs: Float = 500.0
    
    /// Surprise decay time constant (~200ms based on empirical data)
    static let surpriseDecayTau: Float = 200.0
    
    /// Maximum refractory period after ignition
    static let maxRefractoryMs: Float = 200.0
    
    // MARK: - Threshold Parameters
    
    /// Baseline ignition threshold
    static let baselineThreshold: Float = 1.0
    
    /// Minimum allowed threshold value
    static let minThreshold: Float = 0.1
    
    /// Maximum allowed threshold value
    static let maxThreshold: Float = 5.0
    
    /// Threshold homeostatic recovery rate (~2 s⁻¹)
    static let thresholdRecoveryRate: Float = 2.0
    
    /// Post-ignition refractory scalar (0.3-0.5 · θ₀)
    static let postIgnitionRefractory: Float = 0.5
    
    /// Urgency gain factor (dimensionless, 0.1-0.3)
    static let urgencyGainFactor: Float = 0.2
    
    // MARK: - Precision Parameters
    
    /// Minimum precision value for sensory weighting
    static let minPrecision: Float = 0.01
    
    /// Maximum precision value for sensory weighting
    static let maxPrecision: Float = 10.0
    
    /// Baseline interoceptive precision
    static let baselineInteroceptivePrecision: Float = 0.1
    
    /// Baseline exteroceptive precision
    static let baselineExteroceptivePrecision: Float = 0.05
    
    // MARK: - Energy Parameters
    
    /// Minimum energy reserves
    static let minEnergy: Float = 0.0
    
    /// Maximum energy reserves
    static let maxEnergy: Float = 1.0
    
    /// Default initial energy reserves
    static let defaultEnergyReserves: Float = 0.8
    
    /// Energy depletion rate per time step
    static let energyDepletionRate: Float = 0.001
    
    // MARK: - Allostatic Load Parameters
    
    /// Minimum allostatic load
    static let minAllostaticLoad: Float = 0.0
    
    /// Maximum allostatic load
    static let maxAllostaticLoad: Float = 2.0
    
    /// Allostatic load increase rate
    static let allostaticIncreaseRate: Float = 0.01
    
    /// Allostatic load decrease rate
    static let allostaticDecreaseRate: Float = 0.5
    
    // MARK: - Mathematical Model Parameters
    
    /// Sigmoid steepness for ignition probability (5-10)
    static let sigmoidSteepness: Float = 10.0
    
    /// Beta transition parameter for hysteresis
    static let betaTransition: Float = 10.0
    
    /// Hysteresis factor for threshold adaptation
    static let hysteresisFactor: Float = 0.2
    
    /// Somatic bias factor (1.2-1.5 for neutral context)
    static let somaticBiasFactor: Float = 1.3
    
    // MARK: - Somatic Marker Computation Weights
    
    /// Weight for metabolic component in somatic marker
    static let metabolicWeight: Float = 0.4
    
    /// Weight for cognitive component in somatic marker
    static let cognitiveWeight: Float = 0.3
    
    /// Weight for affective component in somatic marker
    static let affectiveWeight: Float = 0.3
    
    /// Scaling factor for somatic marker
    static let somaticMarkerScaling: Float = 2.0
    
    // MARK: - Cost-Benefit Parameters
    
    /// Alpha broadcast cost coefficient
    static let alphaBroadcast: Float = 1.0
    
    /// Beta maintenance cost coefficient
    static let betaMaintenance: Float = 0.5
    
    /// Benefit computation scaling factor
    static let benefitScaling: Float = 0.5
    
    // MARK: - History and Memory
    
    /// Default history length for state tracking
    static let defaultHistoryLength: Int = 100
    
    /// Maximum precision history length
    static let precisionHistoryMax: Int = 1000
    
    // MARK: - Numerical Stability
    
    /// Small epsilon value for numerical stability
    static let numericalEpsilon: Float = 1e-8
    
    // MARK: - Reservoir Parameters
    
    /// Reservoir scaling factor
    static let reservoirScaling: Float = 1.0
    
    /// Reservoir sparsity factor
    static let reservoirSparsity: Float = 0.1
    
    // MARK: - UI Constants
    
    /// Default zoom factor for UI scaling
    static let defaultZoomFactor: CGFloat = 1.2
    
    /// Animation duration for transitions
    static let animationDuration: Double = 0.3
    
    /// Standard padding for UI elements
    static let standardPadding: CGFloat = 12
    
    /// Standard vertical padding for UI elements
    static let standardVerticalPadding: CGFloat = 10
}

// MARK: - Empirical Constraints Documentation

/*
 These constants are based on empirical constraints from neuroscience literature:
 
 • τ ≈ 200 ms: Time constant for surprise decay (NMDA receptor decay, synaptic facilitation)
 • α ≈ 5–10: Controls the steepness of the ignition sigmoid switch (Neural population gain)
 • γ ≈ 2 s⁻¹: Rate of homeostatic recovery for the threshold (Adaptive currents in thalamocortical circuits)
 • δ ≈ 0.3–0.5·θ₀: Post-ignition refractory scalar (Short-term depression in thalamocortical loops)
 • λ ≈ 0.1–0.3: Urgency gain factor (Phasic LC-NE response to surprise rate-of-change)
 • β ≈ 1.2–1.5: Somatic bias factor (Ratio of LC-NE innervation density)
 */
