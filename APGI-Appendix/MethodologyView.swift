import SwiftUI

struct MethodologyView: View {
    private let methodologyBody = """
    The persistent challenges in the field are the pitfalls of vague assertions, implicit assumptions
    and unfalsifiable claims that have long hindered progress. Theoretical frameworks of consciousness
    must meet stringent standards to move beyond correlation and establish causation, ensure
    falsifiability and enable comparative analysis. To advance consciousness science, we propose
    seven criteria for theoretical frameworks, each ensuring that theories remain empirically grounded,
    logically rigorous and scientifically testable.

    Standard 1: Level Transparency
    Every theoretical claim must be explicitly tagged by its analytical level, preventing implicit
    cross-level inferences and clarifying which evidence supports which claims. Level 1
    (Thermodynamic) focuses on energy, entropy and physical costs, requiring measurements in
    joules or kelvin. Level 2 (Information-Theoretic) addresses bits, mutual information and
    channel capacity, necessitating information-theoretic calculations. Level 3 (Computational)
    examines algorithms and neural mechanisms, demanding circuit- or molecular-level evidence.

    Standard 2: Bridge Principles Required
    Cross-level claims must specify the mathematical or physical principles that connect them, making
    inferential leaps explicit and identifying where theories rely on unproven assumptions.
    For example, moving from Level 3 to Level 2 requires showing that variational inference
    maximizes information through formal proof. Linking Level 2 (information operations) to
    Level 1 (energy costs) necessitates quantitative calculations via Landauer's principle.
    Demonstrating that Level 3 computational mechanisms minimize energy therefore requires
    integrating the proofs and calculations of both \\(3 \\to 2\\) and \\(2 \\to 1\\) connections.

    Standard 3: Quantitative Benchmarks
    Claims of efficiency or optimality must provide specific, measurable metrics, preventing vague
    assertions and enabling rigorous comparative analysis. "Thermodynamically efficient" demands
    comparing energy expenditure per event (e.g., in joules) to alternative models.
    "Information-optimal" requires calculating mutual information relative to channel capacity.
    "Computationally fast" necessitates measuring reaction times against competing explanations.

    Standard 4: Falsification Conditions
    Theories must state clear, explicit conditions under which they would be falsified, protecting
    against unfalsifiable theories and guiding critical experiments. At the level-specific stage,
    this means defining the evidence that would falsify thermodynamic, information-theoretic or
    computational claims. At the framework level, theories must specify evidence that would
    falsify the entire theory, with no ambiguous accommodations for surprising results.

    Standard 5: Alternative Comparison
    Theories must compare their predictions to at least two alternative frameworks, preventing
    self-confirming evidence and driving critical experimental design. The theory must specify
    how each alternative explains the same phenomena, identify predictions that differentiate
    among the frameworks and design experiments capable of distinguishing them.

    Standard 6: Evolutionary Plausibility
    Theories must address why evolution would select the proposed mechanisms through
    constraint-driven analysis, identifying the physical or biological constraints that shaped
    the mechanism. The theory must explain the adaptive value and fitness advantage it provides,
    determine if independent lineages evolved similar solutions (convergence) and justify why
    simpler alternatives were not selected. Mechanisms requiring unlikely mutations or offering
    no adaptive advantage are implausible, even if empirically supported.

    Standard 7: Causal Roadmap
    Since most consciousness evidence remains correlational, theories must outline an experimental
    path from correlation to causation in five explicit stages. First, correlation establishes
    that \\text{X} and consciousness co-occur. Second, Manipulation shows that altering \\text{X}
    changes consciousness. Third, Mechanism defines the pathway from \\text{X} to consciousness.
    Fourth, Necessity demonstrates that blocking the pathway abolishes \\text{X}'s effect.
    Fifth, Sufficiency proves that \\text{X} alone can produce consciousness which is the most
    stringent test. This ensures causal claims are explicitly tested rather than merely assumed.
"""

    var body: some View {
        EnhancedSectionView(section: enhancedSection)
    }

    private var enhancedSection: EnhancedSection {
        EnhancedSection(
            id: "methodology",
            title: "Methodology",
            summary: "Seven criteria to keep consciousness theories empirically grounded, logically explicit, and falsifiable—while providing a practical roadmap from correlation to causation.",
            icon: Tab.methodology.icon,
            estimatedReadingTime: "~8 min",
            conceptDiagram: nil,
            subsections: [
                EnhancedSection.Subsection(
                    id: "level-transparency",
                    title: "Level Transparency",
                    content: extractParagraphs(prefix: "Standard 1:", from: methodologyBody),
                    category: .theoretical,
                    hasDataTable: false
                ),
                EnhancedSection.Subsection(
                    id: "bridge-principles",
                    title: "Bridge Principles Required",
                    content: extractParagraphs(prefix: "Standard 2:", from: methodologyBody),
                    category: .theoretical,
                    hasDataTable: false
                ),
                EnhancedSection.Subsection(
                    id: "quantitative-benchmarks",
                    title: "Quantitative Benchmarks",
                    content: extractParagraphs(prefix: "Standard 3:", from: methodologyBody),
                    category: .theoretical,
                    hasDataTable: false
                ),
                EnhancedSection.Subsection(
                    id: "falsification",
                    title: "Falsification Conditions",
                    content: extractParagraphs(prefix: "Standard 4:", from: methodologyBody),
                    category: .theoretical,
                    hasDataTable: false
                ),
                EnhancedSection.Subsection(
                    id: "alternative-comparison",
                    title: "Alternative Comparison",
                    content: extractParagraphs(prefix: "Standard 5:", from: methodologyBody),
                    category: .theoretical,
                    hasDataTable: false
                ),
                EnhancedSection.Subsection(
                    id: "evolutionary-plausibility",
                    title: "Evolutionary Plausibility",
                    content: extractParagraphs(prefix: "Standard 6:", from: methodologyBody),
                    category: .theoretical,
                    hasDataTable: false
                ),
                EnhancedSection.Subsection(
                    id: "causal-roadmap",
                    title: "Causal Roadmap",
                    content: extractParagraphs(prefix: "Standard 7:", from: methodologyBody),
                    category: .theoretical,
                    hasDataTable: false
                )
            ],
            relatedSections: [.apgiStatement, .epistemicStandards, .mathematicalModel]
        )
    }

    private func extractParagraphs(prefix: String, from text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        guard let startIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix(prefix) }) else {
            return text
        }

        var collected: [String] = [lines[startIndex]]
        var index = startIndex + 1
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Standard ") {
                break
            }
            collected.append(lines[index])
            index += 1
        }

        return collected.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    MethodologyView()
}
