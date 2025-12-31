import Foundation
import Accelerate
import CoreML
import SwiftUI
import Charts
import Combine

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
        let interoStates = try! MLMultiArray(shape: [1, NSNumber(value: hiddenSize * numLevels)], dataType: .float32)
        let exteroStates = try! MLMultiArray(shape: [1, NSNumber(value: hiddenSize * numLevels)], dataType: .float32)
        let workspace = try! MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)
        let qMean = try! MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)
        let qVar = try! MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)
        let pMean = try! MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)
        let pVar = try! MLMultiArray(shape: [1, NSNumber(value: hiddenSize)], dataType: .float32)

        for i in 0..<(hiddenSize * numLevels) {
            interoStates[i] = 0.0
            exteroStates[i] = 0.0
        }

        for i in 0..<hiddenSize {
            workspace[i] = 0.0
            qMean[i] = 0.0
            qVar[i] = 1.0
            pMean[i] = 0.0
            pVar[i] = 1.0
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
        case .modelLoadFailed(let message):
            return "Failed to load APGI model: \(message)"
        case .inferenceError(let message):
            return "Inference error: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .stateUpdateFailed(let message):
            return "State update failed: \(message)"
        case .modelNotFound:
            return "The APGI CoreML model file was not found in the application bundle."
        case .inputConversionFailed(let field):
            return "Failed to convert input data for MLMultiArray: \(field)."
        case .inferenceFailed(let error):
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
/// - Takes absolute prediction errors to ensure positive contributions
/// - Computes mean error across all input dimensions
/// - Weights by precision to reflect reliability of sensory information
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
/// - S_extero: Precision-weighted exteroceptive (external sensory) surprise
/// - S_intero: Precision-weighted interoceptive (internal bodily) surprise, modulated by somatic marker
/// 
/// The somatic marker biases interoceptive processing based on metabolic, cognitive, and affective states
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
        let sExtero = computeSurprise(predictionError: exteroError, precision: piExtero)
        let modulatedPiIntero = piIntero * somaticMarker
        let sIntero = computeSurprise(predictionError: interoError, precision: modulatedPiIntero)
        return sExtero + sIntero
    }

/// Computes probability of conscious ignition using sigmoid function
/// 
/// Implements the threshold-based ignition decision:
/// B_t = σ(α(S_t - θ_t))
/// 
/// Where:
/// - B_t: Ignition probability (0.0 to 1.0)
/// - S_t: Accumulated surprise
/// - θ_t: Dynamic ignition threshold
/// - α: Sigmoid steepness parameter (controls decision certainty)
/// 
/// - Parameters:
///   - surprise: Current accumulated surprise value
///   - threshold: Current dynamic ignition threshold
///   - alpha: Sigmoid steepness parameter (typically 5-10)
/// - Returns: Probability of conscious ignition (0.0 to 1.0)
func computeIgnitionProbability(surprise: Float, threshold: Float, alpha: Float) -> Float {
        let x = alpha * (surprise - threshold)
        return sigmoid(x)
    }

/// Standard logistic sigmoid activation function
/// 
/// σ(x) = 1 / (1 + e^(-x))
/// 
/// Maps any real-valued input to range [0, 1], useful for probability computations
/// 
/// - Parameter x: Input value
/// - Returns: Sigmoid activation in range [0, 1]
func sigmoid(_ x: Float) -> Float {
        1.0 / (1.0 + exp(-x))
    }

/// Computes somatic marker from metabolic, cognitive, and affective components
/// 
/// The somatic marker implements Damasio's somatic marker hypothesis:
/// - Integrates current metabolic, cognitive, and affective states
/// - Weights metabolic processes most heavily (0.4), cognitive and affective equally (0.3 each)
/// - Scales result to modulate interoceptive precision (0.5 to 2.0 range)
/// 
/// This marker biases the system toward processing interoceptive information
/// during metabolic stress or high emotional arousal
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
        return clamp(scaled, min: APGISimulatorConstants.somaticBiasFactor, max: 2.0)
    }

/// Computes prediction errors between observations and predictions
/// 
/// Implements the core prediction error computation:
/// ε = observation - prediction
/// 
/// Positive errors indicate under-prediction, negative errors indicate over-prediction
/// 
/// - Parameters:
///   - observation: Actual sensory input values
///   - prediction: Predicted sensory values from generative model
/// - Returns: Array of prediction errors
func computePredictionError(observation: [Float], prediction: [Float]) -> [Float] {
        let minCount = min(observation.count, prediction.count)
        return (0..<minCount).map { observation[$0] - prediction[$0] }
    }

    func updatePredictor(current: inout [Float], observation: [Float], learningRate: Float = 0.1) {
        let minCount = min(current.count, observation.count)
        for i in 0..<minCount {
            current[i] = current[i] * (1.0 - learningRate) + observation[i] * learningRate
        }
    }

    func estimatePrecision(errorHistory: [[Float]], baseline: Float = 1.0) -> Float {
        guard errorHistory.count > 1 else { return baseline }

        var allErrors: [Float] = []
        errorHistory.forEach { allErrors.append(contentsOf: $0) }

        guard !allErrors.isEmpty else { return baseline }

        let mean = allErrors.reduce(0, +) / Float(allErrors.count)
        let variance = allErrors.map { pow($0 - mean, 2) }.reduce(0, +) / Float(allErrors.count)

        let precision = 1.0 / max(variance, config.eps)
        return clamp(precision, min: config.precisionMin, max: config.precisionMax)
    }

/// Updates dynamic ignition threshold based on homeostatic and urgency factors
/// 
/// Implements threshold adaptation dynamics:
/// dθ_t/dt = γ(θ₀ − θ_t) + δ·B_{t-1} − λ·|dS_t/dt|
/// 
/// Where:
/// - γ: Homeostatic recovery rate (returns threshold to baseline)
/// - θ₀: Baseline threshold value
/// - δ: Post-ignition refractory elevation
/// - B_{t-1}: Previous ignition state
/// - λ: Urgency gain factor (lowers threshold for rapidly increasing surprise)
/// - |dS_t/dt|: Absolute rate of surprise change (urgency signal)
/// 
/// - Parameters:
///   - currentTheta: Current threshold value
///   - prevIgnition: Previous ignition state (0.0 or 1.0)
///   - surpriseRate: Current rate of surprise change
///   - dt: Time step for integration
/// - Returns: Updated threshold value
func updateThreshold(
        current: Float,
        prevIgnition: Float,
        prevSurprise: Float,
        currentSurprise: Float,
        energyReserves: Float,
        allostaticLoad: Float,
        dt: Float
    ) -> Float {
        let theta0 = config.theta0
        let gamma = config.gamma
        let delta = config.delta
        let lambdaUrg = config.lambdaUrg

        let homeostasis = gamma * (theta0 - current)
        let refractoriness = -delta * prevIgnition
        let dSdt = (currentSurprise - prevSurprise) / max(dt, 0.001)
        let urgency = -lambdaUrg * max(dSdt, 0.0)
        let metabolicPenalty = (1.0 - energyReserves) * 0.2 + allostaticLoad * 0.1

        let dTheta = homeostasis + refractoriness + urgency + metabolicPenalty
        let newTheta = current + dt * dTheta

        return clamp(newTheta, min: config.thetaMin, max: config.thetaMax)
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
        config.alphaBroadcast * pow(ignitionProb, 2)
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
        config.betaMaintenance * abs(state)
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

    func forward(
        interoInput: [Float],
        exteroInput: [Float],
        state: APGIState,
        context: APGIContext
    ) -> (newState: APGIState, diagnostics: APGIDiagnostics) {
        let dt = config.dtMs / 1000.0

        let epsilonIntero = core.computePredictionError(observation: interoInput, prediction: interoPredictor)
        let epsilonExtero = core.computePredictionError(observation: exteroInput, prediction: exteroPredictor)

        interoErrorHistory.append(epsilonIntero)
        exteroErrorHistory.append(epsilonExtero)

        if interoErrorHistory.count > maxHistoryLength { interoErrorHistory.removeFirst() }
        if exteroErrorHistory.count > maxHistoryLength { exteroErrorHistory.removeFirst() }

        let piIntero = core.estimatePrecision(errorHistory: interoErrorHistory, baseline: Float(state.piIntero))
        let piExtero = core.estimatePrecision(errorHistory: exteroErrorHistory, baseline: Float(state.piExtero))

        let somaticMarker = core.computeSomaticMarker(
            metabolic: Float(context.metabolic),
            cognitive: Float(context.cognitive),
            affective: Float(context.affective)
        )

        let sTotal = core.computeTotalSurprise(
            exteroError: epsilonExtero,
            interoError: epsilonIntero,
            piExtero: piExtero,
            piIntero: piIntero,
            somaticMarker: somaticMarker
        )

        let sExtero = core.computeSurprise(predictionError: epsilonExtero, precision: piExtero)
        let sIntero = core.computeSurprise(predictionError: epsilonIntero, precision: piIntero * somaticMarker)

        let newTheta = core.updateThreshold(
            current: Float(state.theta),
            prevIgnition: Float(state.prevIgnition),
            prevSurprise: Float(state.prevS),
            currentSurprise: sTotal,
            energyReserves: Float(state.energyReserves),
            allostaticLoad: Float(state.allostaticLoad),
            dt: dt
        )

        let ignitionProb = core.computeIgnitionProbability(
            surprise: sTotal,
            threshold: newTheta,
            alpha: config.betaTransition
        )

        let broadcastCost = core.computeBroadcastCost(ignitionProb: ignitionProb)
        let maintenanceCost = core.computeMaintenanceCost(state: Float(state.energyReserves))
        let totalCost = broadcastCost + maintenanceCost

        let benefit = core.computeBenefit(surprise: sTotal, prevSurprise: previousSurprise)
        let freeEnergy = totalCost - benefit

        let energyDelta = -totalCost * config.energyDepletionRate * dt
        let newEnergy = core.clamp(
            Float(state.energyReserves) + Float(energyDelta),
            min: config.energyMin,
            max: config.energyMax
        )

        let allostaticIncrease = sTotal * config.allostaticIncreaseRate * dt
        let allostaticDecrease = ignitionProb * Float(state.allostaticLoad) * config.allostaticDecreaseRate * dt
        let newAllostatic = core.clamp(
            Float(state.allostaticLoad) + Float(allostaticIncrease) - allostaticDecrease,
            min: config.allostaticMin,
            max: config.allostaticMax
        )

        core.updatePredictor(current: &interoPredictor, observation: interoInput, learningRate: 0.1)
        core.updatePredictor(current: &exteroPredictor, observation: exteroInput, learningRate: 0.1)

        let volatility = estimateVolatility(currentPrecision: piIntero)
        let norepinephrine = core.sigmoid(volatility * 2.0 + Float(context.arousal) - 0.5)
        let acetylcholine = core.sigmoid(piIntero * 0.5 + Float(context.attention) - 0.5)

        var newState = state
        newState.piIntero = Double(piIntero)
        newState.piExtero = Double(piExtero)
        newState.theta = Double(newTheta)
        newState.prevS = Double(sTotal)
        newState.prevIgnition = Double(ignitionProb)
        newState.energyReserves = Double(newEnergy)
        newState.allostaticLoad = Double(newAllostatic)

        previousSurprise = sTotal

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
        precisionHistory.append(currentPrecision)
        if precisionHistory.count > 20 { precisionHistory.removeFirst() }
        guard precisionHistory.count > 2 else { return 0.0 }
        let mean = precisionHistory.reduce(0, +) / Float(precisionHistory.count)
        let variance = precisionHistory.map { pow($0 - mean, 2) }.reduce(0, +) / Float(precisionHistory.count)
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
        currentState
    }

    func reset(configuration: APGIConfiguration) async {
        self.currentState = APGIState.initial(configuration: configuration)
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

    private var fpsUpdateTimer: Timer?
    private var lastInferenceTime: TimeInterval = 0.0

    var configuration: APGIConfiguration { config }

    init(configuration: APGIConfiguration) {
        self.config = configuration

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
    }

    deinit {
        fpsUpdateTimer?.invalidate()
    }

    func loadModel() async throws {
        do {
            // Validate configuration before loading
            guard config.inputSize > 0 && config.hiddenSize > 0 && config.numLevels > 0 else {
                throw APGIError.invalidInput("Invalid configuration parameters")
            }
            
            self.simpleModel = SimpleAPGIModel(configuration: config)
            
            // Simulate model loading with validation
            try await Task.sleep(nanoseconds: 100_000_000)
            
            // Validate model initialization
            guard simpleModel != nil else {
                throw APGIError.modelLoadFailed("Model initialization failed")
            }
            
            isModelLoaded = true
        } catch {
            isModelLoaded = false
            simpleModel = nil
            
            if let apgiError = error as? APGIError {
                throw apgiError
            } else {
                throw APGIError.modelLoadFailed(error.localizedDescription)
            }
        }
    }

    func unloadModel() {
        simpleModel = nil
        isModelLoaded = false
    }

    func runInference(interoInput: [Float], exteroInput: [Float], context: APGIContext) async throws {
        guard let model = simpleModel else { 
            throw APGIError.modelNotLoaded 
        }
        
        // Enhanced input validation
        try validateInputs(interoInput: interoInput, exteroInput: exteroInput)
        try validateContext(context: context)

        isInferring = true
        defer { 
            isInferring = false 
        }

        let startTime = Date()

        do {
            let stateSnapshot = await stateManager.getSnapshot()

            let result = model.forward(
                interoInput: interoInput,
                exteroInput: exteroInput,
                state: stateSnapshot,
                context: context
            )

            let inferenceTime = Date().timeIntervalSince(startTime)
            lastInferenceTime = inferenceTime

            // Validate inference results
            try validateInferenceResult(result)

            performanceMonitor.recordInference(duration: inferenceTime)
            updateFPS(inferenceTime: inferenceTime)

            await stateManager.updateState(result.newState)

            currentState = result.newState
            diagnostics = result.diagnostics

            if let timer = fpsUpdateTimer, timer.isValid {
            } else {
                averageInferenceTime = performanceMonitor.averageInferenceTime
            }
        } catch {
            throw APGIError.inferenceFailed(error)
        }
    }
    
    private func validateContext(context: APGIContext) throws {
        let values = [context.metabolic, context.cognitive, context.affective, context.arousal, context.attention]
        
        for value in values {
            guard value >= 0.0 && value <= 1.0 else {
                throw APGIError.invalidInput("Context values must be between 0.0 and 1.0")
            }
            guard !value.isNaN && !value.isInfinite else {
                throw APGIError.invalidInput("Context values contain NaN or Inf")
            }
        }
    }
    
    private func validateInferenceResult(_ result: (newState: APGIState, diagnostics: APGIDiagnostics)) throws {
        // Check for valid state values
        let stateValues = [
            result.newState.piIntero, result.newState.piExtero, result.newState.theta,
            result.newState.energyReserves, result.newState.allostaticLoad
        ]
        
        for value in stateValues {
            guard !value.isNaN && !value.isInfinite else {
                throw APGIError.stateUpdateFailed("Invalid state values detected")
            }
        }
        
        // Check diagnostics validity
        guard result.diagnostics.sTotal >= 0 && result.diagnostics.ignitionProb >= 0 && result.diagnostics.ignitionProb <= 1 else {
            throw APGIError.inferenceError("Invalid diagnostic values")
        }
    }

    private func validateInputs(interoInput: [Float], exteroInput: [Float]) throws {
        if interoInput.count != config.inputSize {
            throw APGIError.invalidInput("Interoceptive input size (\(interoInput.count)) doesn't match config (\(config.inputSize))")
        }

        if exteroInput.count != config.inputSize {
            throw APGIError.invalidInput("Exteroceptive input size (\(exteroInput.count)) doesn't match config (\(config.inputSize))")
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
            currentFPS = 1.0 / inferenceTime
        }
    }

    func startFPSMonitoring() {
        fpsUpdateTimer?.invalidate()
        fpsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.averageInferenceTime = self.performanceMonitor.averageInferenceTime
            }
        }
    }

    func stopFPSMonitoring() {
        fpsUpdateTimer?.invalidate()
        fpsUpdateTimer = nil
    }

    func resetState() async {
        await stateManager.reset(configuration: config)
        let newState = await stateManager.getSnapshot()
        currentState = newState

        diagnostics = APGIDiagnostics(
            sTotal: 0.0,
            sIntero: 0.0,
            sExtero: 0.0,
            theta: Double(config.theta0),
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

        performanceMonitor.reset()
        currentFPS = 0.0
        averageInferenceTime = 0.0
    }

    func getIgnitionState() -> IgnitionState {
        IgnitionState.from(probability: diagnostics.ignitionProb)
    }

    func getPerformanceMetrics() async -> PerformanceMetrics {
        let stats = performanceMonitor.getStatistics()

        return PerformanceMetrics(
            averageInferenceTime: stats.meanLatency / 1000.0,
            medianInferenceTime: stats.p50Latency / 1000.0,
            currentFPS: currentFPS,
            lastInferenceTime: lastInferenceTime
        )
    }
}

struct PerformanceMetrics {
    let averageInferenceTime: TimeInterval
    let medianInferenceTime: TimeInterval
    let currentFPS: Double
    let lastInferenceTime: TimeInterval

    var formattedAverageTime: String { String(format: "%.2f ms", averageInferenceTime * 1000) }
    var formattedMedianTime: String { String(format: "%.2f ms", medianInferenceTime * 1000) }
    var formattedFPS: String { String(format: "%.1f FPS", currentFPS) }
}

extension APGIState {
    static func initial(configuration: APGIConfiguration) -> APGIState {
        APGIState.initialize(hiddenSize: configuration.hiddenSize, numLevels: configuration.numLevels)
    }
}

@MainActor
final class PerformanceMonitor: ObservableObject {
    @Published var averageInferenceTime: Double = 0.0
    @Published var peakMemoryUsage: Double = 0.0
    @Published var currentFPS: Double = 0.0

    private var inferenceTimes: [Double] = []
    private let maxSamples = 100

    func recordInference(duration: TimeInterval) {
        inferenceTimes.append(duration)
        if inferenceTimes.count > maxSamples { inferenceTimes.removeFirst() }

        averageInferenceTime = inferenceTimes.reduce(0, +) / Double(inferenceTimes.count)

        if averageInferenceTime > 0 {
            currentFPS = 1.0 / averageInferenceTime
        }
    }

    func getStatistics() -> PerformanceStats {
        guard !inferenceTimes.isEmpty else {
            return PerformanceStats(meanLatency: 0.0, p50Latency: 0.0, p95Latency: 0.0, throughput: 0.0)
        }

        let mean = inferenceTimes.reduce(0, +) / Double(inferenceTimes.count)
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

    func reset() {
        inferenceTimes.removeAll()
        averageInferenceTime = 0.0
        peakMemoryUsage = 0.0
        currentFPS = 0.0
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
        } else if probability >= 0.5 {
            return .moderate
        } else if probability >= 0.2 {
            return .low
        } else {
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

    var ignitionState: IgnitionState { IgnitionState.from(probability: ignitionProb) }
    var isIgnited: Bool { ignitionProb > 0.5 }
    var surpriseAboveThreshold: Bool { sTotal > theta }

    var metabolicEfficiency: Double {
        guard broadcastCost > 0 else { return 1.0 }
        return (1.0 - freeEnergy) / broadcastCost
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
                if history.isEmpty {
                    Text("Awaiting diagnostic data...")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                } else {
                    Chart(history) { snapshot in
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
            .onChange(of: engine.diagnostics) { _, newDiag in
                history.append(newDiag)
                if history.count > engine.configuration.historyLength {
                    history.removeFirst()
                }
            }
        } else {
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
            headerView
            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        loadingView
                    } else if let error = loadError {
                        errorView(error)
                    } else {
                        statusSection
                        dynamicsChartSection
                        controlsSection
                        diagnosticsSection
                    }
                }
                .padding()
            }
        }
        .task {
            await loadModel()
        }
        .environmentObject(engine)
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
                Text(String(format: "%.1f FPS", engine.currentFPS))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Text(isSimulating ? "Running" : "Stopped")
                    .font(.caption)
                    .foregroundColor(isSimulating ? .green : .orange)
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
                    await loadModel()
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
                    ignitionBadge
                }

                let diag = engine.diagnostics
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
                            .foregroundColor(ignitionColor(diag.ignitionProb))
                    }
                }
            }
            .padding()
        } label: {
            Label("Status", systemImage: "brain.head.profile")
        }
    }

    private var ignitionBadge: some View {
        let diag = engine.diagnostics
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
                Button(action: toggleSimulation) {
                    Label(isSimulating ? "Stop Simulation" : "Start Simulation", systemImage: isSimulating ? "stop.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isSimulating ? .red : .green)

                Divider()

                VStack(spacing: 15) {
                    sliderControl("Metabolic", value: $context.metabolic, color: .red)
                    sliderControl("Cognitive", value: $context.cognitive, color: .blue)
                    sliderControl("Affective", value: $context.affective, color: .purple)
                    sliderControl("Arousal", value: $context.arousal, color: .orange)
                    sliderControl("Attention", value: $context.attention, color: .green)
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

            Slider(value: value, in: 0...1)
                .tint(color)
        }
    }

    private var diagnosticsSection: some View {
        GroupBox {
            let diag = engine.diagnostics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                diagnosticCell("Π Intero", value: diag.piIntero, format: "%.3f")
                diagnosticCell("Π Extero", value: diag.piExtero, format: "%.3f")
                diagnosticCell("Cost", value: diag.broadcastCost, format: "%.4f")
                diagnosticCell("Free Energy", value: diag.freeEnergy, format: "%.4f")
                diagnosticCell("Energy", value: diag.energyReserves, format: "%.2f")
                diagnosticCell("Load", value: diag.allostaticLoad, format: "%.3f")
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
        isLoading = true
        loadError = nil

        do {
            try await engine.loadModel()
            isLoading = false
        } catch {
            isLoading = false
            loadError = error.localizedDescription
        }
    }

    private func toggleSimulation() {
        isSimulating.toggle()

        if isSimulating {
            startSimulation()
        } else {
            stopSimulation()
        }
    }

    private func startSimulation() {
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                await runSimulationStep()
            }
        }
    }

    private func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    private func runSimulationStep() async {
        let interoInput = (0..<64).map { _ in Float.random(in: -1...1) }
        let exteroInput = (0..<64).map { _ in Float.random(in: -1...1) }

        do {
            try await engine.runInference(interoInput: interoInput, exteroInput: exteroInput, context: context)
        } catch {
            await MainActor.run {
                stopSimulation()
            }
        }
    }

    private func ignitionColor(_ prob: Double) -> Color {
        if prob > 0.8 {
            return .green
        } else if prob > 0.3 {
            return .orange
        } else {
            return .red
        }
    }
}
