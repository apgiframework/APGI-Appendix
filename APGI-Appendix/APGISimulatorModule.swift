import Accelerate
import Charts
import Combine
import CoreML
import Foundation
import SwiftUI

struct APGIState {
    var interoStatesFlat: MLMultiArray
    var exteroStatesFlat: MLMultiArray
    var workspaceState: MLMultiArray

    var qMean: MLMultiArray
    var qVar: MLMultiArray
    var pMean: MLMultiArray
    var pVar: MLMultiArray

    var piIntero: Double
    var piExtero: Double
    var theta: Double

    var prevS: Double
    var prevIgnition: Double

    var energyReserves: Double
    var allostaticLoad: Double

    var refractoryTimer: Double

    var volatility: Double
    var norepinephrine: Double
    var acetylcholine: Double

    static func initialize(hiddenSize: Int = APGISimulatorConstants.defaultHiddenSize, numLevels: Int = APGISimulatorConstants.defaultNumLevels) -> APGIState {
        let interoStates = (try? MLMultiArray(shape: [1, NSNumber(value: hiddenSize * numLevels)], dataType: .float32)) ?? MLMultiArray()
        let exteroStates = (try? MLMultiArray(shape: [1, NSNumber(value: hiddenSize * numLevels)], dataType: .float32)) ?? MLMultiArray()
        let workspace = (try? MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)) ?? MLMultiArray()
        let qMean = (try? MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)) ?? MLMultiArray()
        let qVar = (try? MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)) ?? MLMultiArray()
        let pMean = (try? MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)) ?? MLMultiArray()
        let pVar = (try? MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)) ?? MLMultiArray()

        for index in 0 ..< (hiddenSize * numLevels) {
            interoStates[index] = 0.0
            exteroStates[index] = 0.0
        }

        for index in 0 ..< hiddenSize {
            workspace[index] = 0.0
            qMean[index] = 0.0
            qVar[index] = 1.0
            pMean[index] = 0.0
            pVar[index] = 1.0
        }

        return APGIState(
            interoStatesFlat: interoStates,
            exteroStatesFlat: exteroStates,
            workspaceState: workspace,
            qMean: qMean,
            qVar: qVar,
            pMean: pMean,
            pVar: pVar,
            piIntero: Double(APGISimulatorConstants.baselineInteroceptivePrecision),
            piExtero: Double(APGISimulatorConstants.baselineExteroceptivePrecision),
            theta: Double(APGISimulatorConstants.baselineThreshold),
            prevS: 0.0,
            prevIgnition: 0.0,
            energyReserves: Double(APGISimulatorConstants.defaultEnergyReserves),
            allostaticLoad: 0.0,
            refractoryTimer: 0.0,
            volatility: 0.0,
            norepinephrine: 0.0,
            acetylcholine: 0.0
        )
    }
}

struct APGIContext {
    var metabolic: Double = 0.5
    var cognitive: Double = 0.5
    var affective: Double = 0.5
    var arousal: Double = 0.5
    var attention: Double = 0.5
}

struct APGIConfiguration: Equatable {
    let inputSize: Int
    let hiddenSize: Int
    let numLevels: Int

    let dtMs: Float
    let maxWindowMs: Float

    let theta0: Float
    let gamma: Float
    let delta: Float
    let lambdaUrg: Float
    let thetaMin: Float
    let thetaMax: Float

    let betaTransition: Float
    let hysteresis: Float

    let tauMin: Float
    let tauMax: Float
    let tauInteroBaseline: Float
    let tauExteroBaseline: Float
    let precisionMin: Float
    let precisionMax: Float

    let alphaBroadcast: Float
    let betaMaintenance: Float
    let energyDepletionRate: Float
    let energyMin: Float
    let energyMax: Float

    let allostaticIncreaseRate: Float
    let allostaticDecreaseRate: Float
    let allostaticMin: Float
    let allostaticMax: Float

    let maxRefractoryMs: Float
    let historyLength: Int
    let eps: Float

    let reservoirScaling: Float
    let reservoirSparsity: Float
    let precisionHistoryMax: Int

    init(
        inputSize: Int = APGISimulatorConstants.defaultInputSize,
        hiddenSize: Int = APGISimulatorConstants.defaultHiddenSize,
        numLevels: Int = APGISimulatorConstants.defaultNumLevels,
        dtMs: Float = APGISimulatorConstants.defaultDtMs,
        maxWindowMs: Float = APGISimulatorConstants.maxWindowMs,
        theta0: Float = APGISimulatorConstants.baselineThreshold,
        gamma: Float = APGISimulatorConstants.thresholdRecoveryRate,
        delta: Float = APGISimulatorConstants.postIgnitionRefractory,
        lambdaUrg: Float = APGISimulatorConstants.urgencyGainFactor,
        thetaMin: Float = APGISimulatorConstants.minThreshold,
        thetaMax: Float = APGISimulatorConstants.maxThreshold,
        betaTransition: Float = APGISimulatorConstants.betaTransition,
        hysteresis: Float = APGISimulatorConstants.hysteresisFactor,
        tauMin: Float = APGISimulatorConstants.minPrecision,
        tauMax: Float = APGISimulatorConstants.maxPrecision,
        tauInteroBaseline: Float = APGISimulatorConstants.baselineInteroceptivePrecision,
        tauExteroBaseline: Float = APGISimulatorConstants.baselineExteroceptivePrecision,
        precisionMin: Float = APGISimulatorConstants.minPrecision,
        precisionMax: Float = APGISimulatorConstants.maxPrecision,
        alphaBroadcast: Float = APGISimulatorConstants.alphaBroadcast,
        betaMaintenance: Float = APGISimulatorConstants.betaMaintenance,
        energyDepletionRate: Float = APGISimulatorConstants.energyDepletionRate,
        energyMin: Float = APGISimulatorConstants.minEnergy,
        energyMax: Float = APGISimulatorConstants.maxEnergy,
        allostaticIncreaseRate: Float = APGISimulatorConstants.allostaticIncreaseRate,
        allostaticDecreaseRate: Float = APGISimulatorConstants.allostaticDecreaseRate,
        allostaticMin: Float = APGISimulatorConstants.minAllostaticLoad,
        allostaticMax: Float = APGISimulatorConstants.maxAllostaticLoad,
        maxRefractoryMs: Float = APGISimulatorConstants.maxRefractoryMs,
        historyLength: Int = APGISimulatorConstants.defaultHistoryLength,
        eps: Float = APGISimulatorConstants.numericalEpsilon,
        reservoirScaling: Float = APGISimulatorConstants.reservoirScaling,
        reservoirSparsity: Float = APGISimulatorConstants.reservoirSparsity,
        precisionHistoryMax: Int = APGISimulatorConstants.precisionHistoryMax
    ) {
        self.inputSize = inputSize
        self.hiddenSize = hiddenSize
        self.numLevels = numLevels
        self.dtMs = dtMs
        self.maxWindowMs = maxWindowMs
        self.theta0 = theta0
        self.gamma = gamma
        self.delta = delta
        self.lambdaUrg = lambdaUrg
        self.thetaMin = thetaMin
        self.thetaMax = thetaMax
        self.betaTransition = betaTransition
        self.hysteresis = hysteresis
        self.tauMin = tauMin
        self.tauMax = tauMax
        self.tauInteroBaseline = tauInteroBaseline
        self.tauExteroBaseline = tauExteroBaseline
        self.precisionMin = precisionMin
        self.precisionMax = precisionMax
        self.alphaBroadcast = alphaBroadcast
        self.betaMaintenance = betaMaintenance
        self.energyDepletionRate = energyDepletionRate
        self.energyMin = energyMin
        self.energyMax = energyMax
        self.allostaticIncreaseRate = allostaticIncreaseRate
        self.allostaticDecreaseRate = allostaticDecreaseRate
        self.allostaticMin = allostaticMin
        self.allostaticMax = allostaticMax
        self.maxRefractoryMs = maxRefractoryMs
        self.historyLength = historyLength
        self.eps = eps
        self.reservoirScaling = reservoirScaling
        self.reservoirSparsity = reservoirSparsity
        self.precisionHistoryMax = precisionHistoryMax
    }

    @MainActor
    static let `default` = APGIConfiguration(
        inputSize: APGISimulatorConstants.defaultInputSize,
        hiddenSize: APGISimulatorConstants.defaultHiddenSize,
        numLevels: APGISimulatorConstants.defaultNumLevels,
        dtMs: APGISimulatorConstants.defaultDtMs,
        theta0: APGISimulatorConstants.baselineThreshold,
        thetaMin: APGISimulatorConstants.minThreshold,
        thetaMax: APGISimulatorConstants.maxThreshold,
        precisionMin: APGISimulatorConstants.minPrecision,
        precisionMax: APGISimulatorConstants.maxPrecision,
        energyMin: APGISimulatorConstants.minEnergy,
        energyMax: APGISimulatorConstants.maxEnergy,
        historyLength: APGISimulatorConstants.defaultHistoryLength
    )

    nonisolated static let defaultConfig = APGIConfiguration(
        inputSize: APGISimulatorConstants.defaultInputSize,
        hiddenSize: APGISimulatorConstants.defaultHiddenSize,
        numLevels: APGISimulatorConstants.defaultNumLevels,
        dtMs: APGISimulatorConstants.defaultDtMs,
        theta0: APGISimulatorConstants.baselineThreshold,
        thetaMin: APGISimulatorConstants.minThreshold,
        thetaMax: APGISimulatorConstants.maxThreshold,
        precisionMin: APGISimulatorConstants.minPrecision,
        precisionMax: APGISimulatorConstants.maxPrecision,
        energyMin: APGISimulatorConstants.minEnergy,
        energyMax: APGISimulatorConstants.maxEnergy,
        historyLength: APGISimulatorConstants.defaultHistoryLength
    )
}

enum APGIError: Error, LocalizedError {
    case modelNotLoaded
    case modelLoadFailed(String)
    case inferenceError(String)
    case invalidInput(String)
    case stateUpdateFailed(String)
    case modelNotFound
    case inputConversionFailed(String)
    case inferenceFailed(Error)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "APGI model not loaded. Call loadModel() first."
        case let .modelLoadFailed(message):
            return "Failed to load APGI model: \(message)"
        case let .inferenceError(message):
            return "Inference error: \(message)"
        case let .invalidInput(message):
            return "Invalid input: \(message)"
        case let .stateUpdateFailed(message):
            return "State update failed: \(message)"
        case .modelNotFound:
            return "The APGI CoreML model file was not found in the application bundle."
        case let .inputConversionFailed(field):
            return "Failed to convert input data for MLMultiArray: \(field)."
        case let .inferenceFailed(error):
            return "CoreML inference failed: \(error.localizedDescription)"
        }
    }
}

struct APGICore {
    let config: APGIConfiguration

    // MARK: - APGI Core Computational Functions

    /// Computes precision-weighted surprise from prediction errors
    ///
    /// This function implements the core APGI surprise accumulation mechanism:
    /// S = Π · |ε| where Π is precision and ε is prediction error
    ///
    /// Mathematical formulation:
    /// - Takes absolute prediction errors to ensure positive contributions
    /// - Computes mean error across all input dimensions: mean(|ε_i|)
    /// - Weights by precision to reflect reliability of sensory information
    ///
    /// The precision weighting implements the precision gating mechanism
    /// from predictive coding, where high precision (low uncertainty) signals
    /// have greater influence on surprise accumulation
    ///
    /// - Parameters:
    ///   - predictionError: Array of prediction errors (observation - prediction)
    ///   - precision: Precision weight (0.0 to 1.0) representing reliability
    /// - Returns: Precision-weighted surprise value
    func computeSurprise(predictionError: [Float], precision: Float) -> Float {
        guard !predictionError.isEmpty else { return 0.0 }
        let absoluteError = predictionError.map { abs($0) }
        let meanError = absoluteError.reduce(0, +) / Float(absoluteError.count)
        return precision * meanError
    }

    /// Computes total surprise by combining exteroceptive and interoceptive sources
    ///
    /// Implements the multi-modal surprise accumulation in APGI framework:
    /// S_total = S_extero + β · S_intero
    ///
    /// Where:
    /// - S_extero = Π_extero · |ε_extero|: Precision-weighted exteroceptive (external sensory) surprise
    /// - S_intero = Π_intero · |ε_intero|: Precision-weighted interoceptive (internal bodily) surprise
    /// - β: Somatic marker that modulates interoceptive processing based on internal state
    ///
    /// The somatic marker implements Damasio's somatic marker hypothesis,
    /// biasing interoceptive processing during metabolic stress, high cognitive load,
    /// or emotional arousal. This creates a context-dependent weighting of
    /// internal vs. external sensory information
    ///
    /// - Parameters:
    ///   - exteroError: Prediction errors from external sensory channels
    ///   - interoError: Prediction errors from internal bodily channels
    ///   - piExtero: Precision weight for exteroceptive information
    ///   - piIntero: Precision weight for interoceptive information
    ///   - somaticMarker: Modulation factor for interoceptive processing (typically 0.5-2.0)
    /// - Returns: Combined precision-weighted surprise
    func computeTotalSurprise(
        exteroError: [Float],
        interoError: [Float],
        piExtero: Float,
        piIntero: Float,
        somaticMarker: Float
    ) -> Float {
        let sExtero = self.computeSurprise(predictionError: exteroError, precision: piExtero)
        let modulatedPiIntero = piIntero * somaticMarker
        let sIntero = self.computeSurprise(predictionError: interoError, precision: modulatedPiIntero)
        return sExtero + sIntero
    }

    /// Computes probability of conscious ignition using sigmoid function
    ///
    /// Implements the threshold-based ignition decision from APGI framework:
    /// B_t = σ(α(S_t - θ_t))
    ///
    /// Mathematical formulation:
    /// - B_t: Ignition probability (0.0 to 1.0)
    /// - S_t: Accumulated precision-weighted surprise
    /// - θ_t: Dynamic ignition threshold that adapts over time
    /// - α: Sigmoid steepness parameter (typically 5-10) controlling decision certainty
    /// - σ(x): Logistic sigmoid function 1/(1 + e^(-x))
    ///
    /// This implements a stochastic decision rule where ignition probability
    /// increases sharply when surprise exceeds threshold. The α parameter
    /// controls the "sharpness" of this transition - higher values create
    /// more binary-like behavior, lower values create more graded responses
    ///
    /// - Parameters:
    ///   - surprise: Current accumulated surprise value
    ///   - threshold: Current dynamic ignition threshold
    ///   - alpha: Sigmoid steepness parameter (typically 5-10)
    /// - Returns: Probability of conscious ignition (0.0 to 1.0)
    func computeIgnitionProbability(surprise: Float, threshold: Float, alpha: Float) -> Float {
        let scaledValue = alpha * (surprise - threshold)
        return self.sigmoid(scaledValue)
    }

    /// Standard logistic sigmoid activation function
    ///
    /// Mathematical formulation: σ(x) = 1 / (1 + e^(-x))
    ///
    /// Properties:
    /// - Maps any real-valued input to range [0, 1]
    /// - Symmetric around x=0 where σ(0) = 0.5
    /// - Monotonically increasing function
    /// - Derivative: σ'(x) = σ(x) · (1 - σ(x))
    ///
    /// Used extensively in neural networks and computational neuroscience
    /// for probability computations and smooth thresholding operations
    ///
    /// - Parameter x: Input value
    /// - Returns: Sigmoid activation in range [0, 1]
    func sigmoid(_ value: Float) -> Float {
        1.0 / (1.0 + exp(-value))
    }

    /// Computes somatic marker from metabolic, cognitive, and affective components
    ///
    /// Implements Damasio's somatic marker hypothesis for biasing interoceptive processing:
    ///
    /// Mathematical formulation:
    /// SM = scaling · (w_m · M + w_c · C + w_a · A)
    ///
    /// Where:
    /// - M, C, A: Normalized metabolic, cognitive, and affective states (0.0 to 1.0)
    /// - w_m = 0.4: Metabolic weight (highest priority for survival)
    /// - w_c = 0.3: Cognitive weight (mental load, attention, working memory)
    /// - w_a = 0.3: Affective weight (emotional arousal, valence)
    /// - scaling = 2.0: Maps to range [0.5, 2.0] for interoceptive modulation
    ///
    /// Biological rationale:
    /// - Metabolic processes weighted most heavily (energy homeostasis critical)
    /// - Cognitive and affective weighted equally (balanced top-down modulation)
    /// - Result > 1.0 enhances interoceptive processing during stress/arousal
    /// - Result < 1.0 suppresses interoceptive processing during calm states
    ///
    /// This creates adaptive precision gating where the system prioritizes
    /// internal bodily signals when they're most behaviorally relevant
    ///
    /// - Parameters:
    ///   - metabolic: Current metabolic state (0.0 to 1.0)
    ///   - cognitive: Current cognitive load/state (0.0 to 1.0)
    ///   - affective: Current affective/emotional state (0.0 to 1.0)
    /// - Returns: Somatic marker for interoceptive modulation (0.5 to 2.0)
    func computeSomaticMarker(metabolic: Float, cognitive: Float, affective: Float) -> Float {
        let marker = (metabolic * APGISimulatorConstants.metabolicWeight +
            cognitive * APGISimulatorConstants.cognitiveWeight +
            affective * APGISimulatorConstants.affectiveWeight)
        let scaled = marker * APGISimulatorConstants.somaticMarkerScaling
        return self.clamp(scaled, min: APGISimulatorConstants.somaticBiasFactor, max: 2.0)
    }

    /// Computes prediction errors between observations and predictions
    ///
    /// Implements the core prediction error computation from predictive coding:
    /// ε = observation - prediction
    ///
    /// Mathematical interpretation:
    /// - ε > 0: Under-prediction (observation exceeds prediction)
    /// - ε < 0: Over-prediction (prediction exceeds observation)
    /// - |ε|: Magnitude of prediction error (drives learning and surprise)
    ///
    /// In predictive coding frameworks:
    /// - Prediction errors drive hierarchical message passing
    /// - Minimizing prediction errors is the primary computational goal
    /// - Precision weighting determines influence on higher levels
    ///
    /// - Parameters:
    ///   - observation: Actual sensory input values
    ///   - prediction: Predicted sensory values from generative model
    /// - Returns: Array of prediction errors
    func computePredictionError(observation: [Float], prediction: [Float]) -> [Float] {
        let minCount = min(observation.count, prediction.count)
        return (0 ..< minCount).map { observation[$0] - prediction[$0] }
    }

    func updatePredictor(current: inout [Float], observation: [Float], learningRate: Float = 0.1) {
        let minCount = min(current.count, observation.count)
        for index in 0 ..< minCount {
            current[index] = current[index] * (1.0 - learningRate) + observation[index] * learningRate
        }
    }

    func estimatePrecision(errorHistory: [[Float]], baseline: Float = 1.0) -> Float {
        guard errorHistory.count > 1 else { return baseline }

        var allErrors: [Float] = []
        errorHistory.forEach { allErrors.append(contentsOf: $0) }

        guard !allErrors.isEmpty else { return baseline }

        let mean = allErrors.reduce(0, +) / Float(allErrors.count)
        let variance = allErrors.map { pow($0 - mean, 2) }.reduce(0, +) / Float(allErrors.count)

        let precision = 1.0 / max(variance, self.config.eps)
        return self.clamp(precision, min: self.config.precisionMin, max: self.config.precisionMax)
    }

    /// Parameters for threshold update calculation
    struct ThresholdUpdateParams {
        let current: Float
        let prevIgnition: Float
        let prevSurprise: Float
        let currentSurprise: Float
        let energyReserves: Float
        let allostaticLoad: Float
        let deltaTime: Float
    }

    /// Computes updated ignition threshold based on system state
    ///
    /// Implements adaptive threshold model with homeostatic recovery,
    /// post-ignition refractoriness, and metabolic urgency signaling
    ///
    /// - Parameter params: Threshold update parameters
    /// - Returns: Updated threshold value
    func updateThreshold(params: ThresholdUpdateParams) -> Float {
        let theta0 = self.config.theta0
        let gamma = self.config.gamma
        let delta = self.config.delta
        let lambdaUrg = self.config.lambdaUrg

        let homeostasis = gamma * (theta0 - params.current)
        let refractoriness = -delta * params.prevIgnition
        let dSdt = (params.currentSurprise - params.prevSurprise) / max(params.deltaTime, 0.001)
        let urgency = -lambdaUrg * max(dSdt, 0.0)
        let metabolicPenalty = (1.0 - params.energyReserves) * 0.2 + params.allostaticLoad * 0.1

        let dTheta = homeostasis + refractoriness + urgency + metabolicPenalty
        let newTheta = params.current + params.deltaTime * dTheta

        return self.clamp(newTheta, min: self.config.thetaMin, max: self.config.thetaMax)
    }

    /// Computes metabolic cost of broadcasting ignition signal
    ///
    /// Implements quadratic cost model for global broadcasting:
    /// Cost = α × B_t²
    ///
    /// Where:
    /// - α: Broadcast cost coefficient
    /// - B_t: Ignition probability
    ///
    /// Quadratic scaling reflects the metabolic expense of widespread
    /// neural activation across multiple brain regions
    ///
    /// - Parameter ignitionProb: Probability of ignition (0.0 to 1.0)
    /// - Returns: Metabolic cost of broadcasting
    func computeBroadcastCost(ignitionProb: Float) -> Float {
        self.config.alphaBroadcast * pow(ignitionProb, 2)
    }

    /// Computes metabolic cost of maintaining current neural state
    ///
    /// Implements linear maintenance cost model:
    /// Cost = β × |state|
    ///
    /// Where:
    /// - β: Maintenance cost coefficient
    /// - state: Current neural activation level
    ///
    /// Reflects ongoing ATP consumption for maintaining membrane potentials
    /// and neural firing patterns
    ///
    /// - Parameter state: Current neural state activation level
    /// - Returns: Metabolic maintenance cost
    func computeMaintenanceCost(state: Float) -> Float {
        self.config.betaMaintenance * abs(state)
    }

    /// Computes functional benefit from surprise reduction
    ///
    /// Implements benefit model based on prediction error minimization:
    /// Benefit = λ × max(S_{t-1} - S_t, 0)
    ///
    /// Where:
    /// - λ: Benefit scaling factor
    /// - S_{t-1}: Previous surprise level
    /// - S_t: Current surprise level
    ///
    /// Benefit only accrues when surprise is actually reduced,
    /// reflecting improved predictive accuracy
    ///
    /// - Parameters:
    ///   - surprise: Current surprise level
    ///   - prevSurprise: Previous surprise level
    /// - Returns: Functional benefit from prediction improvement
    func computeBenefit(surprise: Float, prevSurprise: Float) -> Float {
        let reduction = max(prevSurprise - surprise, 0.0)
        return reduction * APGISimulatorConstants.benefitScaling
    }

    /// Utility function to clamp values within specified range
    ///
    /// - Parameters:
    ///   - value: Value to clamp
    ///   - minValue: Minimum allowed value
    ///   - maxValue: Maximum allowed value
    /// - Returns: Clamped value within [minValue, maxValue]
    func clamp(_ value: Float, min minValue: Float, max maxValue: Float) -> Float {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}

final class SimpleAPGIModel {
    let core: APGICore
    let config: APGIConfiguration

    var interoPredictor: [Float]
    var exteroPredictor: [Float]

    var interoErrorHistory: [[Float]] = []
    var exteroErrorHistory: [[Float]] = []
    let maxHistoryLength: Int

    var previousSurprise: Float = 0.0

    init(configuration: APGIConfiguration) {
        self.config = configuration
        self.core = APGICore(config: configuration)
        self.interoPredictor = Array(repeating: 0.0, count: configuration.inputSize)
        self.exteroPredictor = Array(repeating: 0.0, count: configuration.inputSize)
        self.maxHistoryLength = configuration.precisionHistoryMax
    }

    /// Main forward pass through the APGI computational model
    ///
    /// Implements the complete APGI algorithm pipeline:
    /// 1. Compute prediction errors from observations vs predictions
    /// 2. Estimate precision from error history (adaptive precision weighting)
    /// 3. Compute somatic marker for interoceptive modulation
    /// 4. Calculate precision-weighted surprise from both modalities
    /// 5. Update dynamic ignition threshold based on system state
    /// 6. Compute ignition probability using sigmoid decision rule
    /// 7. Calculate metabolic costs and functional benefits
    /// 8. Update energy reserves and allostatic load
    /// 9. Estimate neuromodulatory states (NE, ACh)
    /// 10. Update predictive models with new observations
    ///
    /// This implements the core APGI computational cycle where prediction errors
    /// drive precision-weighted surprise accumulation, which competes against
    /// adaptive thresholds to determine conscious access probability
    ///
    /// - Parameters:
    ///   - interoInput: Current interoceptive (internal bodily) sensory input
    ///   - exteroInput: Current exteroceptive (external sensory) input
    ///   - state: Current APGI system state containing all dynamic variables
    ///   - context: Current context including metabolic, cognitive, and affective states
    /// - Returns: Tuple containing updated system state and diagnostic information
    func forward(
        interoInput: [Float],
        exteroInput: [Float],
        state: APGIState,
        context: APGIContext
    ) -> (newState: APGIState, diagnostics: APGIDiagnostics) {
        // Convert time step from milliseconds to seconds for differential equations
        let deltaTime = self.config.dtMs / 1000.0

        // Step 1: Compute prediction errors between observations and predictions
        // ε = observation - prediction (core predictive coding computation)
        let epsilonIntero = self.core.computePredictionError(observation: interoInput, prediction: self.interoPredictor)
        let epsilonExtero = self.core.computePredictionError(observation: exteroInput, prediction: self.exteroPredictor)

        // Step 2: Update error history for precision estimation
        // Maintains sliding window of recent prediction errors
        self.interoErrorHistory.append(epsilonIntero)
        self.exteroErrorHistory.append(epsilonExtero)

        // Maintain fixed-length history window (FIFO buffer)
        if self.interoErrorHistory.count > self.maxHistoryLength { self.interoErrorHistory.removeFirst() }
        if self.exteroErrorHistory.count > self.maxHistoryLength { self.exteroErrorHistory.removeFirst() }

        // Step 3: Estimate precision from error history (inverse of variance)
        // High precision = low prediction error variance = reliable information
        let piIntero = self.core.estimatePrecision(errorHistory: self.interoErrorHistory, baseline: Float(state.piIntero))
        let piExtero = self.core.estimatePrecision(errorHistory: self.exteroErrorHistory, baseline: Float(state.piExtero))

        // Step 4: Compute somatic marker for interoceptive modulation
        // Implements Damasio's somatic marker hypothesis
        let somaticMarker = self.core.computeSomaticMarker(
            metabolic: Float(context.metabolic),
            cognitive: Float(context.cognitive),
            affective: Float(context.affective)
        )

        // Step 5: Calculate total precision-weighted surprise
        // S_total = S_extero + β·S_intero (multi-modal integration)
        let sTotal = self.core.computeTotalSurprise(
            exteroError: epsilonExtero,
            interoError: epsilonIntero,
            piExtero: piExtero,
            piIntero: piIntero,
            somaticMarker: somaticMarker
        )

        // Calculate individual surprise components for diagnostics
        let sExtero = self.core.computeSurprise(predictionError: epsilonExtero, precision: piExtero)
        let sIntero = self.core.computeSurprise(predictionError: epsilonIntero, precision: piIntero * somaticMarker)

        // Step 6: Update dynamic ignition threshold
        // θ_t evolves based on homeostatic recovery, post-ignition refractory, and urgency
        let params = APGICore.ThresholdUpdateParams(
            current: Float(state.theta),
            prevIgnition: Float(state.prevIgnition),
            prevSurprise: Float(state.prevS),
            currentSurprise: sTotal,
            energyReserves: Float(state.energyReserves),
            allostaticLoad: Float(state.allostaticLoad),
            deltaTime: deltaTime
        )
        let newTheta = self.core.updateThreshold(params: params)

        // Step 7: Compute ignition probability using sigmoid decision rule
        // B_t = σ(α(S_t - θ_t)) - threshold-based stochastic ignition
        let ignitionProb = self.core.computeIgnitionProbability(
            surprise: sTotal,
            threshold: newTheta,
            alpha: self.config.betaTransition
        )

        // Step 8: Calculate metabolic costs and functional benefits
        // Cost-benefit analysis for energy allocation
        let broadcastCost = self.core.computeBroadcastCost(ignitionProb: ignitionProb)
        let maintenanceCost = self.core.computeMaintenanceCost(state: Float(state.energyReserves))
        let totalCost = broadcastCost + maintenanceCost

        // Benefit accrues from prediction error reduction (improved model accuracy)
        let benefit = self.core.computeBenefit(surprise: sTotal, prevSurprise: self.previousSurprise)
        let freeEnergy = totalCost - benefit

        // Step 9: Update energy reserves based on metabolic costs
        // Energy depletion proportional to total computational cost
        let energyDelta = -totalCost * self.config.energyDepletionRate * deltaTime
        let newEnergy = self.core.clamp(
            Float(state.energyReserves) + Float(energyDelta),
            min: self.config.energyMin,
            max: self.config.energyMax
        )

        // Step 10: Update allostatic load (stress accumulation)
        // Increases with surprise, decreases with successful ignition (stress relief)
        let allostaticIncrease = sTotal * self.config.allostaticIncreaseRate * deltaTime
        let allostaticDecrease = ignitionProb * Float(state.allostaticLoad) * self.config.allostaticDecreaseRate * deltaTime
        let newAllostatic = self.core.clamp(
            Float(state.allostaticLoad) + Float(allostaticIncrease) - allostaticDecrease,
            min: self.config.allostaticMin,
            max: self.config.allostaticMax
        )

        // Step 11: Update predictive models with new observations (learning)
        // Exponential moving average: prediction_new = (1-α)·prediction_old + α·observation
        self.core.updatePredictor(current: &self.interoPredictor, observation: interoInput, learningRate: APGISimulatorConstants.defaultLearningRate)
        self.core.updatePredictor(current: &self.exteroPredictor, observation: exteroInput, learningRate: APGISimulatorConstants.defaultLearningRate)

        // Step 12: Estimate neuromodulatory states from system variables
        // Volatility drives norepinephrine (arousal/attention)
        let volatility = self.estimateVolatility(currentPrecision: piIntero)
        let norepinephrine = self.core.sigmoid(volatility * APGISimulatorConstants.norepinephrineVolatilityScaling + Float(context.arousal) - APGISimulatorConstants.neuromodulatoryBaselineOffset)
        // Precision drives acetylcholine (attention/learning)
        let acetylcholine = self.core.sigmoid(piIntero * APGISimulatorConstants.acetylcholinePrecisionScaling + Float(context.attention) - APGISimulatorConstants.neuromodulatoryBaselineOffset)

        var newState = state
        newState.piIntero = Double(piIntero)
        newState.piExtero = Double(piExtero)
        newState.theta = Double(newTheta)
        newState.prevS = Double(sTotal)
        newState.prevIgnition = Double(ignitionProb)
        newState.energyReserves = Double(newEnergy)
        newState.allostaticLoad = Double(newAllostatic)

        self.previousSurprise = sTotal

        let diagnostics = APGIDiagnostics(
            sTotal: Double(sTotal),
            sIntero: Double(sIntero),
            sExtero: Double(sExtero),
            theta: Double(newTheta),
            ignitionProb: Double(ignitionProb),
            piIntero: Double(piIntero),
            piExtero: Double(piExtero),
            broadcastCost: Double(broadcastCost),
            freeEnergy: Double(freeEnergy),
            energyReserves: Double(newEnergy),
            allostaticLoad: Double(newAllostatic),
            volatility: Double(volatility),
            norepinephrine: Double(norepinephrine),
            acetylcholine: Double(acetylcholine),
            refractoryTimer: 0.0
        )

        return (newState, diagnostics)
    }

    private var precisionHistory: [Float] = []

    private func estimateVolatility(currentPrecision: Float) -> Float {
        self.precisionHistory.append(currentPrecision)
        if self.precisionHistory.count > 20 { self.precisionHistory.removeFirst() }
        guard self.precisionHistory.count > 2 else { return 0.0 }
        let mean = self.precisionHistory.reduce(0, +) / Float(self.precisionHistory.count)
        let variance = self.precisionHistory.map { pow($0 - mean, 2) }.reduce(0, +) / Float(self.precisionHistory.count)
        return sqrt(variance)
    }
}

actor StateManager {
    private var currentState: APGIState

    init(initialState: APGIState) {
        self.currentState = initialState
    }

    func updateState(_ newState: APGIState) {
        self.currentState = newState
    }

    func getSnapshot() -> APGIState {
        self.currentState
    }

    func reset(configuration: APGIConfiguration) async {
        self.currentState = await APGIState.initial(configuration: configuration)
    }
}

@MainActor
final class APGIInferenceEngine: ObservableObject {
    @Published private(set) var isModelLoaded = false
    @Published private(set) var isInferring = false
    @Published private(set) var currentFPS: Double = 0.0
    @Published private(set) var averageInferenceTime: TimeInterval = 0.0

    @Published var currentState: APGIState
    @Published var diagnostics: APGIDiagnostics

    private let config: APGIConfiguration
    private var simpleModel: SimpleAPGIModel?
    private let stateManager: StateManager
    private let performanceMonitor = PerformanceMonitor()
    private let memoryManager = CoreMLMemoryManager()

    private var fpsUpdateTimer: Timer?
    private var lastInferenceTime: TimeInterval = 0.0
    private var inferenceQueue: DispatchQueue
    private var memoryPressureObserver: NSObjectProtocol?

    var configuration: APGIConfiguration {
        self.config
    }

    init(configuration: APGIConfiguration) {
        self.config = configuration
        self.inferenceQueue = DispatchQueue(label: "com.apgi.inference", qos: .userInitiated, attributes: .concurrent)

        let initialState = APGIState.initialize(hiddenSize: configuration.hiddenSize, numLevels: configuration.numLevels)
        self.currentState = initialState
        self.stateManager = StateManager(initialState: initialState)

        self.diagnostics = APGIDiagnostics(
            sTotal: 0.0,
            sIntero: 0.0,
            sExtero: 0.0,
            theta: Double(configuration.theta0),
            ignitionProb: 0.0,
            piIntero: 1.0,
            piExtero: 1.0,
            broadcastCost: 0.0,
            freeEnergy: 0.0,
            energyReserves: 1.0,
            allostaticLoad: 0.0,
            volatility: 0.0,
            norepinephrine: 0.0,
            acetylcholine: 0.0,
            refractoryTimer: 0.0
        )

        self.setupMemoryPressureObserver()
    }

    deinit {
        fpsUpdateTimer?.invalidate()
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupMemoryPressureObserver() {
        // macOS doesn't have the same memory warning notification as iOS
        // We'll use a different approach or manual triggering
    }

    private func handleMemoryPressure() {
        // Reduce model complexity under memory pressure
        self.memoryManager.optimizeForMemoryPressure()

        // Clear non-essential caches
        self.performanceMonitor.clearCaches()

        // Reduce inference frequency
        if self.isInferring {
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            }
        }
    }

    func loadModel() async throws {
        do {
            // Validate configuration before loading
            guard self.config.inputSize > 0, self.config.hiddenSize > 0, self.config.numLevels > 0 else {
                throw APGIError.invalidInput("Invalid configuration parameters")
            }

            self.simpleModel = SimpleAPGIModel(configuration: self.config)

            // Simulate model loading with validation
            try await Task.sleep(nanoseconds: 100_000_000)

            // Validate model initialization
            guard self.simpleModel != nil else {
                throw APGIError.modelLoadFailed("Model initialization failed")
            }

            self.isModelLoaded = true
        }
        catch {
            self.isModelLoaded = false
            self.simpleModel = nil

            if let apgiError = error as? APGIError {
                throw apgiError
            }
            else {
                throw APGIError.modelLoadFailed(error.localizedDescription)
            }
        }
    }

    func unloadModel() {
        self.simpleModel = nil
        self.isModelLoaded = false
    }

    func runInference(interoInput: [Float], exteroInput: [Float], context: APGIContext) async throws {
        guard let model = simpleModel else {
            throw APGIError.modelNotLoaded
        }

        // Enhanced input validation
        try self.validateInputs(interoInput: interoInput, exteroInput: exteroInput)
        try self.validateContext(context: context)

        self.isInferring = true
        defer {
            isInferring = false
        }

        let startTime = Date()

        do {
            // Use memory-optimized configuration if under pressure
            _ = self.memoryManager.getOptimizedConfiguration(for: self.config)

            let stateSnapshot = await stateManager.getSnapshot()

            let result = model.forward(
                interoInput: interoInput,
                exteroInput: exteroInput,
                state: stateSnapshot,
                context: context
            )

            let inferenceTime = Date().timeIntervalSince(startTime)
            self.lastInferenceTime = inferenceTime

            // Validate inference results
            try self.validateInferenceResult(result)

            self.performanceMonitor.recordInference(duration: inferenceTime)
            self.updateFPS(inferenceTime: inferenceTime)

            await self.stateManager.updateState(result.newState)

            self.currentState = result.newState
            self.diagnostics = result.diagnostics

            if let timer = fpsUpdateTimer, timer.isValid {
            }
            else {
                self.averageInferenceTime = self.performanceMonitor.averageInferenceTime
            }

            // Memory cleanup after inference
            if self.memoryManager.shouldBatchInferences() {
                await self.performMemoryCleanup()
            }
        }
        catch {
            throw APGIError.inferenceFailed(error)
        }
    }

    private func performMemoryCleanup() async {
        // Clear temporary arrays and perform garbage collection
        MLMultiArrayPool.shared.clearPool()

        // Force a brief pause to allow memory to be reclaimed
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }

    private func validateContext(context: APGIContext) throws {
        let values = [context.metabolic, context.cognitive, context.affective, context.arousal, context.attention]

        for value in values {
            guard value >= 0.0, value <= 1.0 else {
                throw APGIError.invalidInput("Context values must be between 0.0 and 1.0")
            }
            guard !value.isNaN, !value.isInfinite else {
                throw APGIError.invalidInput("Context values contain NaN or Inf")
            }
        }
    }

    private func validateInferenceResult(_ result: (newState: APGIState, diagnostics: APGIDiagnostics)) throws {
        // Check for valid state values
        let stateValues = [
            result.newState.piIntero, result.newState.piExtero, result.newState.theta,
            result.newState.energyReserves, result.newState.allostaticLoad,
        ]

        for value in stateValues {
            guard !value.isNaN, !value.isInfinite else {
                throw APGIError.stateUpdateFailed("Invalid state values detected")
            }
        }

        // Check diagnostics validity
        guard result.diagnostics.sTotal >= 0, result.diagnostics.ignitionProb >= 0, result.diagnostics.ignitionProb <= 1 else {
            throw APGIError.inferenceError("Invalid diagnostic values")
        }
    }

    private func validateInputs(interoInput: [Float], exteroInput: [Float]) throws {
        if interoInput.count != self.config.inputSize {
            throw APGIError.invalidInput("Interoceptive input size (\(interoInput.count)) doesn't match config (\(self.config.inputSize))")
        }

        if exteroInput.count != self.config.inputSize {
            throw APGIError.invalidInput("Exteroceptive input size (\(exteroInput.count)) doesn't match config (\(self.config.inputSize))")
        }

        if interoInput.contains(where: { $0.isNaN || $0.isInfinite }) {
            throw APGIError.invalidInput("Interoceptive input contains NaN or Inf")
        }

        if exteroInput.contains(where: { $0.isNaN || $0.isInfinite }) {
            throw APGIError.invalidInput("Exteroceptive input contains NaN or Inf")
        }
    }

    private func updateFPS(inferenceTime: TimeInterval) {
        if inferenceTime > 0 {
            self.currentFPS = 1.0 / inferenceTime
        }
    }

    func startFPSMonitoring() {
        self.fpsUpdateTimer?.invalidate()
        self.fpsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.averageInferenceTime = self.performanceMonitor.averageInferenceTime
            }
        }
    }

    func stopFPSMonitoring() {
        self.fpsUpdateTimer?.invalidate()
        self.fpsUpdateTimer = nil
    }

    func resetState() async {
        await self.stateManager.reset(configuration: self.config)
        let newState = await stateManager.getSnapshot()
        self.currentState = newState

        self.diagnostics = APGIDiagnostics(
            sTotal: 0.0,
            sIntero: 0.0,
            sExtero: 0.0,
            theta: Double(self.config.theta0),
            ignitionProb: 0.0,
            piIntero: 1.0,
            piExtero: 1.0,
            broadcastCost: 0.0,
            freeEnergy: 0.0,
            energyReserves: 1.0,
            allostaticLoad: 0.0,
            volatility: 0.0,
            norepinephrine: 0.0,
            acetylcholine: 0.0,
            refractoryTimer: 0.0
        )

        self.performanceMonitor.reset()
        self.currentFPS = 0.0
        self.averageInferenceTime = 0.0
    }

    func getIgnitionState() -> IgnitionState {
        IgnitionState.from(probability: self.diagnostics.ignitionProb)
    }

    func getPerformanceMetrics() async -> PerformanceMetrics {
        let stats = self.performanceMonitor.getStatistics()

        return PerformanceMetrics(
            averageInferenceTime: stats.meanLatency / 1000.0,
            medianInferenceTime: stats.p50Latency / 1000.0,
            currentFPS: self.currentFPS,
            lastInferenceTime: self.lastInferenceTime
        )
    }
}

struct PerformanceMetrics {
    let averageInferenceTime: TimeInterval
    let medianInferenceTime: TimeInterval
    let currentFPS: Double
    let lastInferenceTime: TimeInterval

    var formattedAverageTime: String {
        String(format: "%.2f ms", self.averageInferenceTime * 1000)
    }

    var formattedMedianTime: String {
        String(format: "%.2f ms", self.medianInferenceTime * 1000)
    }

    var formattedFPS: String {
        String(format: "%.1f FPS", self.currentFPS)
    }
}

extension APGIState {
    static func initial(configuration: APGIConfiguration) -> APGIState {
        APGIState.initialize(hiddenSize: configuration.hiddenSize, numLevels: configuration.numLevels)
    }
}

struct PerformanceStats: Sendable {
    let meanLatency: Double
    let p50Latency: Double
    let p95Latency: Double
    let throughput: Double
}

enum IgnitionState: String, Codable {
    case high = "CONSCIOUS"
    case moderate = "PRE-IGNITION"
    case low = "SUBLIMINAL"
    case refractory = "REFRACTORY"

    var color: Color {
        switch self {
        case .high: return .green
        case .moderate: return .orange
        case .low: return .red
        case .refractory: return .blue
        }
    }

    static func from(probability: Double) -> IgnitionState {
        if probability >= 0.8 {
            return .high
        }
        else if probability >= 0.5 {
            return .moderate
        }
        else if probability >= 0.2 {
            return .low
        }
        else {
            return .refractory
        }
    }
}

struct APGIDiagnostics: Identifiable, Codable, Equatable {
    var id = UUID()
    var timestamp = Date()

    let sTotal: Double
    let sIntero: Double
    let sExtero: Double
    let theta: Double
    let ignitionProb: Double

    let piIntero: Double
    let piExtero: Double
    let broadcastCost: Double
    let freeEnergy: Double
    let energyReserves: Double
    let allostaticLoad: Double

    let volatility: Double
    let norepinephrine: Double
    let acetylcholine: Double
    let refractoryTimer: Double

    var ignitionState: IgnitionState {
        IgnitionState.from(probability: self.ignitionProb)
    }

    var isIgnited: Bool {
        self.ignitionProb > 0.5
    }

    var surpriseAboveThreshold: Bool {
        self.sTotal > self.theta
    }

    var metabolicEfficiency: Double {
        guard self.broadcastCost > 0 else { return 1.0 }
        return (1.0 - self.freeEnergy) / self.broadcastCost
    }

    static func == (lhs: APGIDiagnostics, rhs: APGIDiagnostics) -> Bool {
        lhs.id == rhs.id
    }
}

struct APGITimeSeriesView: View {
    @EnvironmentObject var engine: APGIInferenceEngine
    @State private var history: [APGIDiagnostics] = []

    var body: some View {
        if #available(macOS 13, *) {
            VStack(alignment: .leading, spacing: 10) {
                if self.history.isEmpty {
                    Text("Awaiting diagnostic data...")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                }
                else {
                    Chart(self.history) { snapshot in
                        LineMark(x: .value("Time", snapshot.timestamp), y: .value("Surprise", snapshot.sTotal))
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2))

                        LineMark(x: .value("Time", snapshot.timestamp), y: .value("Threshold", snapshot.theta))
                            .foregroundStyle(.orange)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                        LineMark(x: .value("Time", snapshot.timestamp), y: .value("P(I=1)", snapshot.ignitionProb))
                            .foregroundStyle(.green.opacity(0.7))
                            .interpolationMethod(.monotone)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    .frame(height: 200)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .chartXAxis(.hidden)
                    .chartLegend(position: .bottom, alignment: .center)
                }
            }
            .padding()
            .onChange(of: self.engine.diagnostics) { _, newDiag in
                self.history.append(newDiag)
                if self.history.count > self.engine.configuration.historyLength {
                    self.history.removeFirst()
                }
            }
        }
        else {
            Text("Charts visualization requires macOS 13.0 or later.")
                .foregroundColor(.red)
                .padding()
        }
    }
}

struct APGISimulatorView: View {
    @StateObject private var engine = APGIInferenceEngine(configuration: .default)
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var context = APGIContext()
    @State private var isSimulating = false
    @State private var simulationTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            self.headerView
            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    if self.isLoading {
                        self.loadingView
                    }
                    else if let error = loadError {
                        self.errorView(error)
                    }
                    else {
                        self.statusSection
                        self.dynamicsChartSection
                        self.controlsSection
                        self.diagnosticsSection
                    }
                }
                .padding()
            }
        }
        .task {
            await self.loadModel()
        }
        .environmentObject(self.engine)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("APGI Consciousness Model")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Allostatic Precision-Gated Ignition")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(String(format: "%.1f FPS", self.engine.currentFPS))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Text(self.isSimulating ? "Running" : "Stopped")
                    .font(.caption)
                    .foregroundColor(self.isSimulating ? .green : .orange)
            }
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading APGI Model...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(100)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Error Loading Model")
                .font(.title2)
                .fontWeight(.bold)

            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Button("Retry") {
                Task {
                    await self.loadModel()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(100)
    }

    private var statusSection: some View {
        GroupBox {
            VStack(spacing: 15) {
                HStack {
                    Text("Ignition State")
                        .font(.headline)
                    Spacer()
                    self.ignitionBadge
                }

                let diag = self.engine.diagnostics
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Surprise (S)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.3f", diag.sTotal))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Threshold (θ)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.3f", diag.theta))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Ignition Prob")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", diag.ignitionProb * 100))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(self.ignitionColor(diag.ignitionProb))
                    }
                }
            }
            .padding()
        } label: {
            Label("Status", systemImage: "brain.head.profile")
        }
    }

    private var ignitionBadge: some View {
        let diag = self.engine.diagnostics
        let state = IgnitionState.from(probability: diag.ignitionProb)
        return Text(state.rawValue)
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(state.color.opacity(0.2))
            .foregroundColor(state.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var dynamicsChartSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text("Temporal Dynamics: Surprise, Threshold, & Ignition")
                    .font(.headline)

                APGITimeSeriesView()
                    .frame(height: 250)
            }
        } label: {
            Label("Temporal Dynamics", systemImage: "waveform.path.ecg")
        }
    }

    private var controlsSection: some View {
        GroupBox {
            VStack(spacing: 20) {
                Button(action: self.toggleSimulation) {
                    Label(self.isSimulating ? "Stop Simulation" : "Start Simulation", systemImage: self.isSimulating ? "stop.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(self.isSimulating ? .red : .green)

                Divider()

                VStack(spacing: 15) {
                    self.sliderControl("Metabolic", value: self.$context.metabolic, color: .red)
                    self.sliderControl("Cognitive", value: self.$context.cognitive, color: .blue)
                    self.sliderControl("Affective", value: self.$context.affective, color: .purple)
                    self.sliderControl("Arousal", value: self.$context.arousal, color: .orange)
                    self.sliderControl("Attention", value: self.$context.attention, color: .green)
                }
            }
            .padding()
        } label: {
            Label("Control Panel", systemImage: "slider.horizontal.3")
        }
    }

    private func sliderControl(_ label: String, value: Binding<Double>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            Slider(value: value, in: 0 ... 1)
                .tint(color)
        }
    }

    private var diagnosticsSection: some View {
        GroupBox {
            let diag = self.engine.diagnostics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                self.diagnosticCell("Π Intero", value: diag.piIntero, format: "%.3f")
                self.diagnosticCell("Π Extero", value: diag.piExtero, format: "%.3f")
                self.diagnosticCell("Cost", value: diag.broadcastCost, format: "%.4f")
                self.diagnosticCell("Free Energy", value: diag.freeEnergy, format: "%.4f")
                self.diagnosticCell("Energy", value: diag.energyReserves, format: "%.2f")
                self.diagnosticCell("Load", value: diag.allostaticLoad, format: "%.3f")
            }
            .padding()
        } label: {
            Label("Diagnostics", systemImage: "chart.bar.doc.horizontal")
        }
    }

    private func diagnosticCell(_ label: String, value: Double, format: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: format, value))
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadModel() async {
        self.isLoading = true
        self.loadError = nil

        do {
            try await self.engine.loadModel()
            self.isLoading = false
        }
        catch {
            self.isLoading = false
            self.loadError = error.localizedDescription
        }
    }

    private func toggleSimulation() {
        self.isSimulating.toggle()

        if self.isSimulating {
            self.startSimulation()
        }
        else {
            self.stopSimulation()
        }
    }

    private func startSimulation() {
        self.simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                await self.runSimulationStep()
            }
        }
    }

    private func stopSimulation() {
        self.simulationTimer?.invalidate()
        self.simulationTimer = nil
    }

    private func runSimulationStep() async {
        let interoInput = (0 ..< 64).map { _ in Float.random(in: -1 ... 1) }
        let exteroInput = (0 ..< 64).map { _ in Float.random(in: -1 ... 1) }

        do {
            try await self.engine.runInference(interoInput: interoInput, exteroInput: exteroInput, context: self.context)
        }
        catch {
            await MainActor.run {
                self.stopSimulation()
            }
        }
    }

    private func ignitionColor(_ prob: Double) -> Color {
        if prob > 0.8 {
            return .green
        }
        else if prob > 0.3 {
            return .orange
        }
        else {
            return .red
        }
    }
}
