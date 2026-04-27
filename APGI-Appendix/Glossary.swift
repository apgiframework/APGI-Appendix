import Combine
import SwiftUI

@MainActor
class GlossaryManager: ObservableObject {
  static let shared = GlossaryManager()

  @Published var entries: [GlossaryEntry] = []
  @Published var isLoading = false
  @Published var lastUpdate: Date?

  private let cacheManager = ContentCacheManager.shared
  private let cacheKey = "glossary_remote"
  private var cancellables = Set<AnyCancellable>()

  private init() {
    self.loadCachedContent()
    self.setupAutoRefresh()
  }

  private func setupAutoRefresh() {
    self.cacheManager.$isOfflineMode
      .filter { !$0 }  // When coming back online
      .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in
        Task {
          await self?.refreshContent()
        }
      }
      .store(in: &self.cancellables)
  }

  private func loadCachedContent() {
    if let cachedEntries: [GlossaryEntry] = cacheManager.cachedObject(for: cacheKey) {
      self.entries = cachedEntries
      if let metadata = cacheManager.cacheMetadata(for: cacheKey),
        let timestamp = metadata["cachedAt"] as? TimeInterval {
        self.lastUpdate = Date(timeIntervalSince1970: timestamp)
      }
      logInfo(
        "Loaded \(cachedEntries.count) glossary entries from cache", context: "GlossaryManager")
    } else {
      // Fall back to local data
      self.entries = GlossaryData.entries
      logInfo("Using local glossary data (no cache available)", context: "GlossaryManager")
    }
  }

  func refreshContent() async {
    guard !self.isLoading else { return }

    self.isLoading = true
    defer { isLoading = false }

    do {
      // Try to fetch from remote source
      guard let remoteURL = URL(string: "https://api.apgi-framework.org/glossary.json") else {
        logInfo("Invalid remote URL for glossary", context: "GlossaryManager.refreshContent")
        return
      }
      let data = try await cacheManager.fetchAndCache(from: remoteURL, cacheKey: self.cacheKey)

      // Parse remote data
      let remoteEntries = try JSONDecoder().decode([RemoteGlossaryEntry].self, from: data)
        .map { GlossaryEntry(term: $0.term, definition: $0.definition) }

      // Merge with local data, preferring remote
      var mergedEntries = remoteEntries
      let remoteTerms = Set(remoteEntries.map { $0.term.lowercased() })

      // Add local entries that aren't in remote
      for localEntry in GlossaryData.entries where !remoteTerms.contains(localEntry.term.lowercased()) {
        mergedEntries.append(localEntry)
      }

      // Remove duplicates and sort
      mergedEntries = mergedEntries.removingDuplicates(by: { $0.term.lowercased() })
        .sorted { $0.term < $1.term }

      self.entries = mergedEntries
      self.lastUpdate = Date()

      logInfo(
        "Refreshed glossary with \(mergedEntries.count) entries from remote",
        context: "GlossaryManager")
    } catch {
      logWarning(
        "Failed to refresh glossary content: \(error.localizedDescription)",
        context: "GlossaryManager")
      // Keep existing cached/local data
    }
  }
}

private struct RemoteGlossaryEntry: Codable {
  let term: String
  let definition: String
}

extension Array {
  func removingDuplicates<T: Hashable>(by key: (Element) -> T) -> [Element] {
    var seen: Set<T> = []
    return filter { seen.insert(key($0)).inserted }
  }
}

struct GlossaryEntry: Identifiable, Hashable, Codable {
  let id: UUID
  let term: String
  let definition: String

  init(id: UUID = UUID(), term: String, definition: String) {
    self.id = id
    self.term = term
    self.definition = definition
  }
}

enum GlossaryData {
  static let entries: [GlossaryEntry] = [
    GlossaryEntry(
      term: "Active Inference",
      definition:
        "An action selection strategy that minimizes expected free energy by selecting policies that balance goal-directed (pragmatic) and information-seeking (epistemic) values. It is the primary mechanism for resolving uncertainty that cannot be handled by perception alone."
    ),
    GlossaryEntry(
      term: "Allostasis",
      definition:
        "The process of anticipatory, predictive regulation of the internal milieu to maintain physiological stability through change. It is the primary function driving the APGI Framework's somatic bias, as the brain proactively defends the body's viability, making interoceptive threats potent triggers for conscious ignition."
    ),
    GlossaryEntry(
      term: "Attention",
      definition:
        "A neuromodulatory process that selectively enhances the precision (inverse variance, reliability) of specific sensory or cognitive signals. In the APGI Framework, attention is mechanistically implemented by acetylcholine (for exteroceptive precision, Πₑ) and norepinephrine (for interoceptive precision, Πᵢ), thereby prioritizing signals for processing and potential conscious access."
    ),
    GlossaryEntry(
      term: "Bayesian Inference",
      definition:
        "A normative framework for updating beliefs (posteriors) about hidden states by combining prior knowledge with new evidence (likelihood), weighted by its precision."
    ),
    GlossaryEntry(
      term: "Conscious Access",
      definition:
        "The global availability of information for verbal report, reasoning, long-term memory encoding and flexible behavioral control. This is the primary explanatory target of the APGI Framework, formally modeled as the outcome of a precision-gated ignition process. It is considered functionally and potentially phenomenally distinct from fringe or unreportable states."
    ),
    GlossaryEntry(
      term: "Criticality",
      definition:
        "A state of a dynamical system poised at a phase transition between order and disorder, often characterized by power-law statistics and optimal computational properties. The APGI Framework proposes that the brain operates near criticality and the ignition transition shares features of a critical bifurcation."
    ),
    GlossaryEntry(
      term: "E/I Balance (Excitation/Inhibition Balance)",
      definition:
        "The dynamic equilibrium between excitatory and inhibitory neural activity, critical for stable network function. The APGI Framework specifies that ignition involves a transient, localized shift in this balance where recurrent excitation in thalamocortical loops overcomes local inhibition (e.g., from parvalbumin-positive interneurons) to enable a metastable, high-firing attractor state."
    ),
    GlossaryEntry(
      term: "Exteroception",
      definition:
        "Sensing of the external world through vision, audition, somatosensation, taste and smell. In the APGI Framework, exteroceptive signals generate prediction errors (εₑ) that are weighted by exteroceptive precision (Πₑ), typically modulated by acetylcholine."
    ),
    GlossaryEntry(
      term: "Expected Free Energy",
      definition:
        "A quantity in active inference that is minimized through policy selection. It balances the expected cost of being in a future state (pragmatic value) and the information gain expected from a future state (epistemic value)."
    ),
    GlossaryEntry(
      term: "Fading Memory",
      definition:
        "The exponential decay of information retention over time, reflecting the gradual loss of trace strength in neural representations. Timescale measured as the decay constant (τ) in behavioral or neural data, fitted to an exponential function of the form e^(-t/τ) where t is time and τ is the characteristic decay time, often estimated from delayed-match-to-sample tasks or neural adaptation paradigms."
    ),
    GlossaryEntry(
      term: "Free Energy Principle",
      definition:
        "A theoretical framework stating that self-organizing systems act to minimize an information-theoretic quantity called variational free energy which is an upper bound on surprise. The APGI Framework adopts the FEP as a guiding heuristic for understanding perception and action but remains agnostic about its strongest metaphysical claims."
    ),
    GlossaryEntry(
      term: "Generative Model",
      definition:
        "The brain's internal model of the causal structure of the world and the body. It generates predictions about sensory inputs and is updated via prediction errors. The APGI Framework posits a hierarchical generative model with segregated but interacting exteroceptive and interoceptive streams."
    ),
    GlossaryEntry(
      term: "Global Ignition",
      definition:
        "A non-linear, all-or-none transition (typically unfolding over ~300-500ms) in which a sufficiently strong, precision-weighted surprise signal (Sₜ > θₜ) triggers widespread, sustained and recurrent activation across frontoparietal and thalamocortical networks."
    ),
    GlossaryEntry(
      term: "Global Workspace",
      definition:
        "A theoretical architecture proposing a brain-wide broadcasting system that makes information globally accessible to specialized processors. The APGI Framework embeds the GNW within a predictive, metabolic and embodied architecture, providing a normative mechanism (precision-weighted surprise) for which contents gain access to the workspace."
    ),
    GlossaryEntry(
      term: "Hierarchical Predictive Coding",
      definition:
        "A neural implementation of Bayesian inference where prediction errors propagate up a cortical hierarchy to update beliefs while predictions propagate down to explain away sensory data. The APGI Framework uses this as its core computational architecture."
    ),
    GlossaryEntry(
      term: "Homeostasis",
      definition:
        "A reactive process by which biological systems maintain internal stability through negative feedback mechanisms that correct deviations after they occur (e.g., shivering when cold). Contrasted with the predictive, proactive nature of allostasis."
    ),
    GlossaryEntry(
      term: "Ignition",
      definition:
        "A rapid, nonlinear phase transition in large-scale network activity, marking the transition from local to global information broadcasting. Operationalized as the sudden increase in synchronized gamma-band oscillations (30–100 Hz) across frontoparietal networks, detectable via EEG/MEG coherence metrics or intracranial recordings during stimulus detection tasks."
    ),
    GlossaryEntry(
      term: "Ignition Threshold (θₜ)",
      definition:
        "A dynamic, metabolically-gated barrier that precision-weighted surprise (Sₜ) must exceed to trigger global ignition. It is not static but adapts based on recent conscious events (post-ignition refractory period), urgency and baseline neuromodulatory tone (e.g., lowered by NE, raised by 5-HT)."
    ),
    GlossaryEntry(
      term: "Integrated Information Theory (IIT)",
      definition:
        "A theory of consciousness that posits consciousness is identical to a system's integrated information (Φ), a measure of the irreducibility of its causal structure. The APGI Framework is potentially compatible with IIT, proposing that ignition events may be a primary generator of high-Φ states in the brain, but treats this as a correlation rather than an identity."
    ),
    GlossaryEntry(
      term: "Interoception",
      definition:
        "The sense of the internal state of the body, including visceral, cardiovascular, respiratory and metabolic signals. In the APGI Framework, interoceptive prediction errors (εᵢ) are assigned a baseline priority (somatic bias, β) and weighted by interoceptive precision (Πᵢ), typically modulated by norepinephrine, making them potent drivers of conscious access."
    ),
    GlossaryEntry(
      term: "Landauer's Principle",
      definition:
        "Fundamental limit stating that erasing one bit of information requires dissipating at least k B T ln(2) energy as heat"
    ),
    GlossaryEntry(
      term: "Markov Blanket",
      definition:
        "Statistical boundary separating internal states of a system from external states, defining an organism's interface with the environment."
    ),
    GlossaryEntry(
      term: "Metastability",
      definition:
        "A dynamic regime in which neural assemblies transiently synchronize and desynchronize, maintaining a balance between integration and segregation. This balance is essential for the global workspace's operation, as it allows the system to remain in a sub-threshold state until precision-weighted surprise pushes it across the ignition threshold into a transiently synchronized global state."
    ),
    GlossaryEntry(
      term: "Phenomenal Consciousness",
      definition:
        "The subjective, qualitative aspect of experience (qualia)—what it is like to see red, feel pain or be oneself. The APGI Framework deliberately brackets the \"hard problem\" of explaining phenomenal consciousness, focusing instead on providing a sufficient mechanism for access consciousness while acknowledging they typically co-occur."
    ),
    GlossaryEntry(
      term: "Phenomenal Unity",
      definition:
        "The property of conscious experience whereby multiple contents (sensory, emotional, cognitive) are bound into a single, coherent field of awareness."
    ),
    GlossaryEntry(
      term: "Precision (Π)",
      definition:
        "The inverse variance (1/σ²) of a probability distribution; in neural terms, it corresponds to the confidence or reliability assigned to a prediction or a prediction error signal. It is dynamically modulated by neuromodulators (ACh, NE) and implements a mechanistic, Bayesian form of attention. The degree of gain modulation applied to prediction errors, reflecting the relative weighting of sensory evidence in updating internal models. Measured as the amplitude scaling factor of prediction error units in neural responses, often quantified through electrophysiological or fMRI signal variability analysis."
    ),
    GlossaryEntry(
      term: "Prediction Error (ε)",
      definition:
        "The mismatch between a sensory input (exteroceptive or interoceptive) and the brain's top-down prediction. It is the fundamental signal that drives learning, belief updating and when sufficiently precision-weighted, can trigger conscious access. The neural response generated by a mismatch between expected and actual sensory input. Measured as the difference in firing rates, EEG/MEG signal amplitudes or BOLD signal deviations between predicted and observed stimuli, typically standardized to baseline activity levels."
    ),
    GlossaryEntry(
      term: "Precision-Weighted Surprise (Sₜ)",
      definition:
        "The key driving variable in the APGI Framework. It is the accumulated sum of exteroceptive and interoceptive prediction errors, each scaled by their respective precision (Sₜ = Πₑ·|εₑ| + β·Πᵢ·|εᵢ|). This quantity is compared against the ignition threshold (θₜ) to determine conscious access."
    ),
    GlossaryEntry(
      term: "Self-Model",
      definition:
        "The brain's dynamic, multi-layered representation of the organism as a persistent, embodied agent. In the APGI Framework, this is implemented through hierarchical generative models that track the body as an object in the world and as the source of a first-person perspective."
    ),
    GlossaryEntry(
      term: "Self-Model Coherence",
      definition:
        "The degree to which the self-model maintains temporal and structural consistency; proposed as a neural substrate for phenomenal unity."
    ),
    GlossaryEntry(
      term: "Somatic Marker",
      definition:
        "A learned association, formalized in the APGI Framework as a probability distribution (M_{c,a}), that links specific contexts and actions to anticipated interoceptive outcomes. Retrieved by the vmPFC-hippocampal system, somatic markers dynamically bias interoceptive precision (Πᵢ), making us hypersensitive to bodily signals in threatening or significant situations."
    ),
    GlossaryEntry(
      term: "Surprise",
      definition:
        "The negative log probability of an observation given a model. The brain minimizes a bound on surprise (variational free energy) through perception, learning and action."
    ),
    GlossaryEntry(
      term: "Thermodynamic Costs",
      definition:
        "The metabolic energy required for neural processes. The APGI Framework emphasizes that global ignition is metabolically expensive and involves NMDA activation, sustained firing, neuromodulator release which provides the evolutionary rationale for a dynamic ignition threshold—consciousness is deployed only when benefits outweigh costs."
    ),
    GlossaryEntry(
      term: "Threshold (θₜ)",
      definition:
        "The critical point at which a stimulus or prediction error triggers a detectable neural or behavioral response. Psychometrically measured as the stimulus intensity or signal-to-noise ratio at which performance reaches a predefined criterion (e.g., 75% detection accuracy), derived from psychometric curves or adaptive staircase procedures."
    ),
    GlossaryEntry(
      term: "Workspace Capacity",
      definition:
        "The limited amount of information that can be simultaneously maintained in the global workspace. This capacity is constrained by the winner-take-all nature of the ignition process and the post-ignition refractory period (elevated θₜ) which underlies phenomena like the attentional blink."
    )
  ]

  static let termToDefinition: [String: String] = {
    var result: [String: String] = [:]
    for entry in entries where !entry.term.isEmpty {
      result[entry.term.lowercased()] = entry.definition
    }
    return result
  }()

  static let terms: [String] = entries.map { $0.term }

  static func definition(for term: String) -> String? {
    self.termToDefinition[term.lowercased()]
  }
}

struct GlossaryView: View {
  @StateObject private var glossaryManager = GlossaryManager.shared

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Glossary")
          .font(.title.bold())

        Spacer()

        if self.glossaryManager.isLoading {
          ProgressView()
            .controlSize(.small)
        }

        Button {
          Task {
            await self.glossaryManager.refreshContent()
          }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
        .disabled(self.glossaryManager.isLoading)
        .help("Refresh glossary content")

        if let lastUpdate = glossaryManager.lastUpdate {
          Text("Updated \(lastUpdate.formatted(.relative(presentation: .named)))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
      .background(.thinMaterial)

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          let entries = self.glossaryManager.entries

          if entries.isEmpty {
            HStack {
              Spacer()
              if self.glossaryManager.isLoading {
                ProgressView("Loading glossary...")
              } else {
                Text("No glossary entries available")
                  .foregroundStyle(.secondary)
              }
              Spacer()
            }
            .padding()
          } else {
            ForEach(entries) { entry in
              GlossaryTermView(term: entry.term, definition: entry.definition)
            }
          }
        }
        .padding()
      }
    }
    .task {
      // Auto-refresh on first load if we have network
      if !ContentCacheManager.shared.isOfflineMode {
        await self.glossaryManager.refreshContent()
      }
    }
  }
}

struct GlossaryTermView: View {
  let term: String
  let definition: String
  @State private var isExpanded: Bool = true

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button {
        if ThemeManager.shared.enableAnimations {
          withAnimation(.spring(response: 0.3)) {
            self.isExpanded.toggle()
          }
        } else {
          self.isExpanded.toggle()
        }
      } label: {
        HStack {
          Text(self.term)
            .font(.headline)
            .foregroundStyle(.primary)

          Spacer()

          Image(systemName: self.isExpanded ? "chevron.up" : "chevron.down")
            .foregroundStyle(.secondary)
            .font(.caption.bold())
        }
        .padding()
        .background(.quaternary.opacity(0.5))
      }
      .buttonStyle(.plain)
      .apgiAccessibility(
        label: self.term,
        hint: self.isExpanded ? "Collapse definition" : "Expand definition",
        traits: .isButton
      )

      if self.isExpanded {
        Text(self.definition)
          .font(.body)
          .foregroundStyle(.secondary)
          .padding()
          .background(.background)
          .textSelection(.enabled)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .strokeBorder(.separator, lineWidth: 1)
    )
  }
}

struct GlossaryPopover: View {
  let term: String
  let definition: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(self.term)
        .font(.headline)

      Text(self.definition)
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(maxWidth: 300)
    .background(.thinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .shadow(radius: 10)
  }
}

struct GlossaryHighlightedText: View {
  let text: String
  var terms: [String] = GlossaryData.terms

  @AppStorage("contentFontSize") private var fontSize: Double = 15.0
  @State private var selected: GlossaryEntry?

  var body: some View {
    Text(self.attributedText)
      .onOpenURL { url in
        guard url.scheme == "glossary" else { return }
        guard let term = url.host(percentEncoded: false) else { return }
        guard let definition = GlossaryData.definition(for: term) else { return }
        self.selected = GlossaryEntry(term: term, definition: definition)
      }
      .popover(item: self.$selected) { entry in
        GlossaryPopover(term: entry.term, definition: entry.definition)
      }
  }

  private var attributedText: AttributedString {
    GlossaryAttributedStringBuilder.build(
      from: self.text,
      terms: self.terms,
      baseFont: .custom("Inter-Regular", size: CGFloat(self.fontSize)),
      highlightColor: .thresholdBlue
    )
  }
}

struct LazyGlossaryHighlightedContent: View {
  let text: String

  private var paragraphs: [String] {
    self.text
      .components(separatedBy: "\n\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  var body: some View {
    LazyVStack(alignment: .leading, spacing: 12) {
      ForEach(Array(self.paragraphs.enumerated()), id: \.offset) { _, paragraph in
        GlossaryHighlightedText(text: paragraph)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

private enum GlossaryAttributedStringBuilder {
  static func build(from text: String, terms: [String], baseFont: Font, highlightColor: Color) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.font = baseFont
    attributed.foregroundColor = .primary

    let fullText = text
    let lower = fullText.lowercased()
    var occupied = IndexSet()

    let sortedTerms =
      terms
      .filter { !$0.isEmpty }
      .sorted { $0.count > $1.count }

    for term in sortedTerms {
      let termLower = term.lowercased()
      var searchStart = lower.startIndex

      while searchStart < lower.endIndex {
        guard let found = lower.range(of: termLower, options: [], range: searchStart..<lower.endIndex) else { break }

        let nsRange = NSRange(found, in: lower)
        if !occupied.intersects(integersIn: nsRange.location..<(nsRange.location + nsRange.length)) {
          if let attrRange = Range(nsRange, in: attributed) {
            attributed[attrRange].foregroundColor = highlightColor
            attributed[attrRange].underlineStyle = .single
            attributed[attrRange].link = URL(
              string:
                "glossary://\(term.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? term)"
            )
            occupied.insert(integersIn: nsRange.location..<(nsRange.location + nsRange.length))
          }
        }

        searchStart = found.upperBound
      }
    }

    return attributed
  }
}

#Preview {
  GlossaryView()
}
