import SwiftUI
import Combine

struct PsychologicalStatesView: View {
    private let psychologicalStatesIntro = """

Psychological States and APGI Parameters

This section explores how various psychological states emerge from specific configurations of APGI parameters. Each state represents a unique pattern of prediction error processing, precision weighting, threshold modulation, and somatic bias that creates its characteristic phenomenological experience.
JEALOUSY
Prediction error in attachment security (threat to exclusive bond); high precision Π_rival elevated 3-5σ on rival-related cues; interoceptive threat signals (somatic arousal) amplified via β > 1.5; threshold θₜ_threat lowered 20-35% for defensive cognition; hypervigilance for betrayal cues.
Jealousy is distinct from envy—it involves threat to an existing relationship rather than desire for something possessed by another. When attachment predictions (partner fidelity, bond exclusivity) are threatened, the system elevates precision on rival-related cues and lowers threshold for threat, creating hypervigilance. The combination of interoceptive amplification (somatic anxiety) and cognitive threat-monitoring creates jealousy's consuming quality. Jealousy motivates mate-guarding behavior, deterring rivals and maintaining pair-bonds—adaptive in evolutionary context but potentially pathological in modern relationships. Attachment style strongly predicts jealousy—anxious attachment involves constitutively elevated Π_threat and lowered θₜ for abandonment cues; secure attachment maintains more moderate parameters. Amygdala (threat), anterior cingulate (conflict), posterior cingulate (relationship representation), hypothalamus (arousal), ventral striatum (reduced when partner attention shifts). Distinguishing features vs. Envy—jealousy protects existing bonds; envy desires absent goods. vs. Suspicion—jealousy has emotional/visceral intensity beyond cognitive mistrust. When jealousy becomes delusional (morbid jealousy), precision on imagined betrayal signs becomes extreme while evidence contrary to jealous beliefs is filtered by an elevated threshold—a computational trap.
REGRET
Counterfactual prediction error (past action ≠ optimal); high precision Π_self-blame on self-caused negative outcomes (3-5σ); threshold θₜ_autobiographical lowered 15-25% for autobiographical memory, enabling recurrent ignition of "what if" scenarios; temporal focus on changeable past decisions.
Regret involves comparing actual outcomes with simulated counterfactual outcomes (what would have happened if...). The ventromedial prefrontal cortex generates counterfactual simulations; the orbitofrontal cortex evaluates outcome values. When counterfactual outcome > actual outcome, a self-directed negative prediction error emerges. High precision on self-blame ensures this error readily crosses threshold, triggering recurrent ignition of the regretted decision and its alternatives. Regret is a learning signal—the discomfort strengthens decision predictions ("avoid similar choices in future"). However, excessive regret about unchangeable past decisions is computationally wasteful. Regret scales with: (1) magnitude of outcome difference, (2) controllability of decision (higher regret for volitional choices), (3) decision proximity ("near miss" losses generate more regret). Immediate regret may be intense but fades as memory precision decays; sustained regret suggests persistent high Π_autobiographical, preventing normal forgetting. Orbitofrontal cortex (outcome evaluation), medial prefrontal (counterfactual simulation), anterior cingulate (self-monitoring), hippocampus (episodic retrieval). Maximizers (exhaustive option-searchers) experience more regret than satisficers (good-enough choosers)—higher precision on alternative options post-decision. Distinguishing features vs. Guilt—regret focuses on outcome, guilt on moral violation. Distinguishing features vs. Disappointment—regret involves self-blame, disappointment involves external factors.
PESSIMISM
High prior probability on negative outcomes (>60%); precision Π_positive suppressed 2-3σ on positive prediction errors; threshold θₜ_positive elevated 20-35% for hopeful/optimistic content, effectively filtering it from conscious access; temporal focus biased toward anticipated negative futures.
Pessimism reflects a systematic negative bias in prior distributions—expected outcomes are skewed toward worse scenarios. Unlike depression (which involves anhedonia and current low mood), pessimism is primarily anticipatory. The elevated threshold for positive content means even when positive outcomes occur, they're interpreted as flukes or temporary, failing to update the pessimistic prior. This creates resistance to positive evidence. Is mild pessimism adaptive? "Defensive pessimism" may buffer disappointment and motivate prevention-focused behavior. However, extreme pessimism becomes self-fulfilling—reduced effort due to low expected value. Distinguishing features vs. Depression: Pessimism involves future prediction bias; depression involves current anhedonia and global negative filtering. Distinguishing features vs. Realism: True calibrated pessimism (accurate negative predictions) differs from biased pessimism (overestimating negative outcomes) Reduced ventral striatum (reward expectation); elevated right dorsolateral prefrontal (negative simulation); amygdala hyperactivity to negative cues. Update prior distributions through behavioral experiments that provide disconfirming evidence (positive outcomes); reduce threshold for positive content through attention training.
OVERWHELM
Excessive concurrent high-precision inputs (Π₁, Π₂, Π₃... each 3-5σ, total >10-15 competing streams); reservoir computational capacity exceeded (saturation); threshold crossed chaotically and unpredictably, producing fragmented, incoherent ignitions; temporal integration collapses (present-moment only processing).
Overwhelm represents computational resource exhaustion. When too many inputs maintain high precision simultaneously, the liquid network (reservoir) cannot maintain distinct attractor states for each—they interfere and merge chaotically. Threshold is crossed frequently but randomly, producing rapid switches between partially-processed content without completion. The prefrontal executive system (limited capacity) fails to prioritize, allowing all inputs equal precision. "Too much at once," inability to focus, panicked fragmentation, sense of losing control. Distinct from confusion (which involves model ambiguity) by the sheer volume of clear but competing demands. Overwhelm triggers sympathetic arousal (stress response) which further elevates precision globally (NE surge), worsening the saturation—a positive feedback loop toward panic. Overwhelm is metabolically catastrophic—maximal arousal with minimal productive output. Performance collapses as nothing gets completed. Working memory capacity predicts an overwhelming threshold—higher capacity individuals can maintain more concurrent high-precision streams before saturation. Overwhelm is a common feature of PTSD (multiple trauma-related triggers simultaneously active), ADHD (deficient precision filtering), and anxiety disorders (global arousal elevating all precision).
DISSOCIATION
Interoceptive precision Π_i dramatically suppressed (approaching zero); soma-bias parameter β reduced to <0.3 (body signals weighted <1/3 normal); prediction errors fail to anchor in embodied states; threshold θₜ_embodied elevated 40-70% for body-relevant content—ignition effectively decoupled from somatic self-model; sense of unreality (derealization) or detachment from self (depersonalization).
Dissociation represents active suppression of interoceptive signals, likely mediated by prefrontal inhibition of the insula. When β drops drastically, prediction errors that normally anchor consciousness in the body fail to cross threshold—creating the "floating" or "detached" phenomenology. The computational result is conscious access dominated by exteroceptive or abstract content with minimal embodied grounding. In overwhelming threat contexts (trauma), dissociation may be protective—suppressing somatic distress signals prevents maladaptive panic. However, chronic dissociation prevents normal emotional processing and learning. Ventromedial prefrontal cortex suppresses anterior insula activity; reduced connectivity between cortex and interoceptive pathways; potential opioid system involvement (endogenous analgesic effect). Subtypes are depersonalization: detachment from self (reduced Π_self + β suppression); derealization: external world seems unreal (reduced precision on reality monitoring); dissociative amnesia: memory encoding failure during dissociation (hippocampal suppression) Can be transient (seconds-minutes during acute stress) or chronic trait (persistent low β in PTSD, dissociative disorders). Depersonalization/derealization rating scales; physiological: reduced skin conductance response to emotional stimuli (autonomic uncoupling); neural: reduced insula activation to interoceptive tasks. Trauma therapy aims to gradually restore interoceptive integration (increase β safely) while processing the trauma that triggered initial dissociation. Dissociation reveals that consciousness is not automatically anchored in the body—the β parameter actively constructs embodied selfhood by weighting somatic signals into ignition.
TRANCE
Top-down predictions dominate over sensory input (prior strength >3×posterior updating); external precision Π_ext minimized (<0.3σ); threshold θₜ_endogenous lowered 20-35% for internally-generated rhythmic patterns, enabling self-sustained ignition without sensory input; frontal-theta synchrony increased; reduced sensory gating.
Trance states (hypnotic, meditative, rhythmic engagement) occur when strong, rhythmic top-down predictions suppress attention to bottom-up sensory prediction errors. The system essentially "ignores" the world, allowing internal models to run autonomously. Lowered threshold for endogenous content means even weak internal rhythms (breathing pace, mantra repetition, rhythmic movement) can trigger sustained ignition. The result is absorption in internal experience with reduced external awareness. Hypnotic trance: external suggestions become high-precision priors, dominating sensory reality. Meditative absorption: attention to single focus (breath, mantra) suppresses all other content. Rhythmic trance (dance, drumming): motor rhythm entrains neural oscillations, creating sustained coherent state. Flow-like trance: differs from flow by reduced external engagement—more internal than task-focused. Increased frontal-midline theta (4-8 Hz)—marker of internally-directed attention; reduced alpha in sensory cortices (sensory suppression); increased connectivity in default mode network; reduced thalamic gating of sensory input. Trance may allow consolidation or rehearsal of internal models without interference from external prediction errors—a form of offline processing. Hypnotic susceptibility predicts trance depth—high-susceptibles show greater capacity to elevate prior strength over sensory evidence.
HALLUCINATION
Strong internal predictions (priors) misattributed as sensory input; precision erroneously assigned to endogenous prediction errors ε_internal (Π_internal elevated 3-6σ); threshold θₜ crossed by purely endogenous signals; reality monitoring failure—inability to distinguish internally-generated from externally-sourced content.
Hallucinations occur when the precision-weighting system malfunctions, assigning high precision to internally-generated predictions as if they were sensory prediction errors. Normally, predictions are "deweighted" (low precision) when no sensory evidence confirms them. In hallucination, this tagging fails—predictions are treated as perceptions. The medial prefrontal cortex and anterior cingulate (source monitoring systems) fail to correctly label content as internally-generated. Psychotic hallucinations: often dysregulated dopamine elevates precision on internal "signals". Charles Bonnet: sensory deafferentation causes predictions to fill the gap (predictive processing's dark side). Hypnagogic: during sleep transitions when sensory precision naturally drops, predictions cross threshold. Psychedelics alter 5-HT2A signaling, disrupting normal precision hierarchies. Excessive dopamine (schizophrenia model): elevates precision on predictions, making them indistinguishable from perceptions. Sensory deafferentation: lack of bottom-up input leaves top-down predictions unchecked. 5-HT2A agonism (psychedelics): disrupts thalamic filtering and precision calibration. Hallucinations reveal that perception is primarily prediction—sensory input normally constrains predictions, but when precision goes wrong, predictions run free and are experienced as real. Antipsychotics (D2 antagonists) reduce dopaminergic precision elevation; cognitive therapy teaches reality testing (checking predictions against sensory evidence). Reduced sensory prediction error signals in EEG (less P300 to actual stimuli); increased spontaneous activation in content-relevant cortex (e.g., auditory cortex in auditory hallucinations).
DÉJÀ VU
Temporal misalignment in reservoir state dynamics; current sensory input partially matches decaying memory trace (prior experience); familiarity signal generated despite episodic details remaining inaccessible; momentary false match triggers premature threshold crossing and sense of "pastness."
Déjà vu likely involves a timing error in temporal integration. The hippocampus may briefly reactivate a memory trace overlapping with current perception, creating a familiarity signal without retrieving the full episodic context (source amnesia). The reservoir state momentarily settles into an attractor resembling a prior state, triggering false recognition. Alternatively, a brief processing delay may cause a sensory input to be processed twice—the second processing matches the first (just-formed) memory, creating false familiarity. Uncanny sense of having experienced this exact moment before; brief (2-10 seconds); usually fades with attention to the inconsistency. Healthy individuals report occasional déjà vu; more common in younger adults; fatigue and stress may increase frequency. Very frequent déjà vu may indicate temporal lobe epilepsy (requires evaluation if occurring multiple times daily). Déjà vu exposes the temporal-binding problem—consciousness requires not just igniting content but correctly time-stamping it as past, present, or future. When this tagging fails, misdated content feels eerily familiar.
HYPNAGOGIA
Temporal integration window (memory maintenance) extended beyond normal waking bounds; precision decoupled from external input (Π_ext declining while Π_internal maintained or elevated); threshold θₜ_dream lowered 20-40% during sleep onset, allowing dream-like, non-sensory content to ignite intermittently; reality monitoring degraded (reduced source discrimination).
Hypnagogia occurs during the transition between wakefulness and sleep when sensory precision drops (reduced thalamic relay) but the cortex remains sufficiently active to sustain ignition. Without sensory constraint, predictions and memory fragments ignite spontaneously. The extended memory window means rapidly-fading thoughts don't immediately clear—they linger and blend with incoming fragments, creating the surreal, flowing imagery of hypnagogia. Unlike dreams (REM sleep), hypnagogia has partial waking awareness—meta-cognition persists intermittently, allowing some recognition of the unreality. Unlike waking hallucinations, hypnagogia is contextually normal and non-pathological. Mixed EEG pattern—alpha waves declining, theta increasing; occasional sleep spindles; thalamic gating decreasing but cortical activation not yet suppressed. More common in creative individuals and those with thin mental boundaries; some people can intentionally sustain hypnagogia (technique used by Edison and Dalí for creative inspiration). Hypnagogia may represent the reservoir's "resting creativity"—freed from sensory constraints, it explores its attractor landscape, potentially enabling novel combinations and consolidation.
EMPATHY
High precision Π_other-emotion on observed emotional prediction errors (3-5σ); interoceptive simulation actively engaged—own somatic states mirror observed states via β > 1.5; threshold θₜ_affective lowered 20-30% for affective resonance, enabling rapid ignition of other's emotional state; anterior insula-mediated somatic gating creates "shared feeling."
Empathy involves simulating another's emotional state in one's own interoceptive system. Mirror neuron systems and simulation circuitry (inferior frontal gyrus, inferior parietal lobule) generate predictions of the other's state; the anterior insula maps these predictions onto one's own body (elevated β), creating somatic resonance. When another person's distress signals cross the lowered affective threshold, one feels their emotion through embodied simulation—not merely knowing cognitively. Emotion recognition: detecting other's emotional expression (visual/auditory prediction errors). Simulation: generating internal models of other's state. Somatic mapping: activating own interoceptive pathways to match simulated state (β elevation). Self-other distinction: maintaining boundaries (when this fails → emotional contagion). Inferior frontal gyrus (action/expression simulation). Anterior insula (interoceptive simulation mapping). Anterior cingulate (affective processing). Temporoparietal junction (self-other distinction). Empathy varies widely—highly empathic individuals show stronger insula activation and higher β for others' states; alexithymia (difficulty recognizing one's own emotions) correlates with reduced empathy (need self-knowledge for simulation). Distinguishing features vs. Sympathy: empathy involves embodied resonance (feeling with); sympathy involves concern (feeling for) without somatic sharing. Distinguishing features vs. Compassion: empathy is affective sharing; compassion adds a motivational component (desire to help). Distinguishing features vs. Cognitive empathy: affective empathy (described here) differs from perspective-taking (mentalizing without feeling). Empathy enables social bonding, cooperation, altruism. However, excessive empathy can lead to burnout (healthcare workers) or empathic distress (feeling others' pain without capacity to help). Optimal empathy balances resonance with regulation.
SYMPATHY
Moderate precision Π_other-distress on other's suffering (2-3σ); concern and compassionate regard generated but somatic mirroring lower than empathy (β < 1.2); threshold θₜ_personal-distress elevated 15-25%, preventing overwhelming vicarious suffering while enabling sustained care-focused attention.
Sympathy involves caring concern for another's wellbeing without fully embodied resonance of their state. The medial prefrontal cortex generates prosocial concern; the temporoparietal junction tracks other's state; but critically, the anterior insula shows less activation than in empathy—one understands the other's suffering without intensely feeling it in their own body. The elevated threshold for personal distress allows sustained helping behavior without empathic overwhelm. Sympathy may be more sustainable than empathy for caregiving roles—maintaining concern without vicarious exhaustion. Nurses, therapists, and physicians often cultivate sympathy over empathy to prevent burnout. More dorsal medial prefrontal (cognitive evaluation of other's state) and less anterior insula (somatic simulation) compared to empathy; sustained prosocial motivation circuits (ventral tegmental area, nucleus accumbens—rewarding aspect of helping). Distinguishing features vs. Empathy: sympathy is cognitive and motivational; empathy is affective and embodied. Distinguishing features vs. Pity: sympathy maintains respect for other's agency; pity may involve condescension or superiority. Distinguishing features vs. Compassion: sympathy is affective concern; compassion emphasizes action/helping. Some cultures emphasize empathy (feel together); others emphasize sympathy (care without merging)—suggesting culturally-modulated β and threshold parameters.
BELONGING
Social inclusion predictions confirmed (group membership secure); precision Π_inclusion elevated 2-4σ on positive social signals; interoceptive safety signals amplified (β > 1.0 for relaxed autonomic states); threshold θₜ_group lowered 15-25%, enabling ready ignition of group-relevant content; oxytocin-mediated bonding sustains low threshold.
Belonging emerges when social predictions of acceptance, reciprocity, and shared identity are consistently fulfilled. The medial prefrontal cortex (self-in-social-context) shows increased activity; the ventral striatum signals reward from social connection; the amygdala shows reduced threat reactivity. The elevated β for interoceptive safety means belonging is felt in the body—relaxation, warmth, physiological calm—not merely known cognitively. Belonging reduces need for hypervigilant social monitoring—when inclusion is secure, precision on threat detection can be reduced, freeing cognitive resources. It's a homeostatic state for social animals. Belonging develops gradually (weeks-months of positive interactions) and can sustain with intermittent reinforcement; sudden loss triggers acute distress (rejection) due to large prediction error. Reduced amygdala reactivity; increased ventral striatum (reward); elevated oxytocin; sustained medial prefrontal-temporoparietal connectivity (group identity representation). Secure attachment predicts easier belonging—lower baseline social threat precision. Social anxiety involves persistently elevated Π_rejection even when belonging cues present, preventing full security.
REJECTION
Large social prediction error—exclusion violates expected inclusion; precision Π_social-threat elevated 3-5σ on negative social cues; threshold θₜ_threat lowered 20-35%, triggering rapid ignition of self-protective or withdrawal states; anterior cingulate (social pain) activation parallels physical pain processing.
Social rejection generates a prediction error in attachment/belonging models. The dorsal anterior cingulate cortex (dACC)—which processes physical pain—activates strongly, suggesting computational repurposing of pain systems for social exclusion (Eisenberger, 2012). Elevated precision on rejection cues (averted gaze, exclusion from conversation, explicit dismissal) ensures these signals readily cross threshold. The lowered threshold for threat triggers defensive responses—withdrawal, anger, or compensatory affiliation-seeking. For social species, exclusion is survival-threatening—rejection sensitivity is adaptive. However, chronic high Π_social-threat (rejection sensitivity) is maladaptive, causing false alarms and self-fulfilling isolation. Acute rejection: single event, sharp pain-like response, resolves with time or alternative social connection. Chronic rejection: repeated exclusion, generalizes to expectation (pessimistic social priors), may lead to depression. Perceived rejection: ambiguous social signals interpreted as rejection due to elevated Π_threat (social anxiety). Neural overlap with physical pain - dACC, anterior insula—suggesting rejection "hurts" computationally and phenomenologically.
TRUST
Stable, positive social priors (high expected value of cooperation); precision Π_betrayal lowered 2-3σ on betrayal-related prediction errors (reduced vigilance); threshold θₜ_threat elevated 20-30% for threat/suspicion content, effectively filtering defensive interpretations—enabling ignition of cooperative, vulnerability-accepting content; oxytocin and vasopressin mediate threshold modulation.
Trust represents a computational commitment: reducing precision on threat monitoring to enable cooperation. The ventromedial prefrontal cortex maintains positive social priors; the amygdala's threat reactivity is suppressed by prefrontal inhibition; oxytocin release (during positive interactions) lowers salience of threat cues and elevates threshold for defensive cognition. Trust isn't merely belief—it's an active filtering that deprioritizes threat signals, allowing cooperative action despite vulnerability. Trust requires accepting potential exploitation (false negatives on betrayal detection) to gain cooperation benefits. Trust is adaptive when: P(cooperation benefits) × value > P(exploitation) × cost. Trust builds gradually—repeated interactions without betrayal strengthen positive priors and raise the threat threshold. Single betrayal can drastically lower threshold (break trust) due to strong negative prediction error. Neural correlates are reduced amygdala activation; increased ventral striatum (reward from cooperation); elevated oxytocin/vasopressin; enhanced ventromedial prefrontal-amygdala connectivity (prefrontal suppression of threat). Attachment history predicts trust capacity—secure attachment maintains moderate precision balance; insecure attachment shows either excessive trust (dismissive: Π_betrayal too low, vulnerable to exploitation) or insufficient trust (anxious: Π_betrayal too high, preventive of intimacy). Distinguishing features vs. Naivety: trust involves realistic assessment with chosen vulnerability; naivety lacks threat awareness. Distinguishing features vs. Certainty: trust accepts uncertainty while committing; certainty eliminates vulnerability altogether
FOCUS/CONCENTRATION
High precision Π_task elevated 3-5σ on task-relevant prediction errors; low precision Π_distractor (<0.5σ) on irrelevant inputs (selective suppression); threshold θₜ optimized (lowered ~10-15% for target content, elevated ~10-15% for distractors)—creating high signal-to-noise ratio with selective ignition gating to task-relevant content only.
Focus represents optimal precision allocation—amplifying task-relevant channels while suppressing competing inputs. The dorsolateral prefrontal cortex maintains goal representations that modulate posterior cortex gain (precision weighting); the superior parietal cortex directs attention spatially. Norepinephrine (LC-NE system) enhances signal-to-noise ratio by increasing gain on high-precision channels while suppressing low-precision ones. The threshold adjustment creates a "tuned filter"—target content easily ignites, distractors don't. Sustained focus is metabolically expensive—maintaining high precision on a narrow channel requires continuous LC-NE activity and prefrontal maintenance. Explains fatigue after prolonged concentration. Humans can sustain maximum focus ~45-90 minutes before precision control degrades (vigilance decrement). Brief breaks allow recovery. Focus capacity correlates with working memory and attentional control (prefrontal function). ADHD involves deficient precision filtering—Π_distractor remains elevated, allowing irrelevant content to ignite frequently. Distinguishing features vs. Mindfulness: focus narrows attention; mindfulness equalizes it
CREATIVITY
High precision Π_remote elevated 2-4σ on weak, remote associations (normally subliminal); reservoir maintained near-critical state (edge of chaos)—balanced between ordered and disordered dynamics; threshold θₜ slightly lowered ~10-20% allowing novel, weak-signal combinations to ignite before strong, conventional responses dominate; reduced cognitive inhibition (lower threshold for "irrelevant" content).
Creativity involves exploring distant regions of conceptual space—detecting connections between normally-separate domains. The default mode network (spontaneous thought) and executive control network (cognitive flexibility) show unusual synchrony during creative thinking, enabling both generative exploration and evaluative selection. The reservoir near-critical dynamics maximize information processing complexity—enough order for coherence but enough disorder for flexibility. Dopamine modulation creates an inverted-U curve: moderate levels optimize creative flexibility; too low (rigidity) or too high (disorganization) impairs creativity. Divergent thinking: generating multiple solutions, measured by fluency/originality/flexibility. Insight: sudden restructuring of problem representation (Aha! moment—threshold crossed by novel attractor). Combinatorial creativity: connecting distant concepts (elevated Π_remote enables weak associations to ignite). Default mode-executive network coupling; increased α-power (relaxed attention); transient γ-bursts (insight moments); right hemisphere involvement (broader associative networks). Creativity isn't random—it's structured exploration near the edge of chaos, where novel patterns can emerge and stabilize.
DECISION FATIGUE
Precision dysregulation—competing options maintain approximately equal precision (Π₁ ≈ Π₂ ≈ Π₃ ±20%); threshold θₜ elevated 25-40% to conserve depleted cognitive resources; expected value computations become noisy (reduced orbitofrontal function); delay or blocking of ignition for decision-content—result is paralysis or default to status quo.
Decision fatigue emerges after sustained effortful choice. The orbitofrontal cortex (value computation) and dorsolateral prefrontal cortex (working memory for options) show reduced activity after prolonged decision-making. Glucose depletion in prefrontal regions impairs precision calibration and value updating. To conserve remaining resources, threshold elevates dramatically—preventing ignition of decision content and defaulting to inaction or heuristic-based choice (choose default, choose first option, or avoid choosing). Judges show increasing likelihood of default decisions (deny parole) as day progresses; consumers make poorer choices late in shopping sequences; self-control depletes after repeated effortful decisions. Decision-making requires model comparison—evaluating multiple futures and selecting the highest expected-value trajectory. This is computationally expensive. After many iterations, the system implements an energy-saving policy: stop comparing, raise threshold, reduce precision. Rest or glucose replenishment restores decision capacity—suggesting metabolic constraint is genuine, not merely motivational. Decision fatigue susceptibility varies with glucose regulation efficiency and baseline prefrontal capacity.
COGNITIVE DISSONANCE
Two or more high-precision models conflict (Π₁, Π₂ each >3σ but mutually inconsistent); reservoir state pulled toward competing attractors simultaneously; threshold θₜ becomes unstable (±20-30% fluctuation) as system oscillates between models; aversive interoceptive signal (dissonance discomfort) generated by unresolved conflict.
Cognitive dissonance emerges when holding simultaneous incompatible beliefs (e.g., "I'm health-conscious" + "I smoke"). The anterior cingulate detects conflict between models; both maintain high precision (neither can be easily dismissed), pulling the reservoir toward incompatible attractors. The instability generates aversive arousal (anterior insula activation)—a computational error signal motivating resolution. Resolution occurs via: (1) updating one model (quit smoking), (2) reducing precision on one (rationalization: "smoking isn't that unhealthy"), or (3) adding bridging model (compartmentalization: "I'm healthy in other ways"). Dissonance is a model-consistency enforcement mechanism—the discomfort motivates maintaining coherent belief systems. Without dissonance, contradictory beliefs could accumulate, impairing effective action. Dissonance is acutely uncomfortable and typically resolves quickly (minutes-hours) through one of the above strategies. Chronic unresolved dissonance suggests strong external pressures maintaining both models despite internal conflict. Some individuals tolerate ambiguity better (can sustain dissonance longer); others show rapid rationalization (quickly adjust precision to resolve conflict). Anterior cingulate (conflict monitoring), dorsal anterior cingulate (discomfort), ventromedial prefrontal (value reassessment for rationalization). Festinger's original theory (1957) proposed dissonance as drive reduction; APGI reframes it as precision-threshold instability creating aversive computational state.
HYPERFOCUS


Extreme task-relevant precision Π_task (5-8σ above baseline—nearly all available precision allocated); all non-task precision Π_other suppressed to near-zero (<0.2σ); threshold θₜ_task dramatically lowered (30-50% reduction) for target domain, enabling sustained, uninterrupted ignition; metacognitive monitoring suppressed (no self-aware "checking"); time perception distorted (hours feel like minutes).
Hyperfocus represents maximum resource concentration—nearly all available precision allocated to a single target. The dorsolateral prefrontal cortex and posterior parietal cortex maintain locked attentional state; the anterior cingulate's typical monitoring function is suppressed (no cognitive flexibility). Dopamine maintains the extreme precision asymmetry and threshold lowering. Unlike flow (which feels effortless), hyperfocus is intense but can be draining afterward due to extreme resource concentration. Complete absorption; external events (phone ringing, people speaking) fail to cross threshold; time distortion; surprise when finally disengaging ("it's been 3 hours already?"); post-hyperfocus fatigue from sustained high-gain processing. Common when intrinsically motivating task engages—suggesting dopamine-mediated precision control is intact but requires strong incentive to activate. Also may reflect different default precision allocation. Hyperfocus maximizes depth on a single task but eliminates flexibility—no monitoring for higher-priority interruptions, no strategic task-switching. Adaptive for certain contexts (solving complex problems, creative production) but maladaptive if preventing broader goal management. Distinguishing features  vs. Flow: hyperfocus is more extreme, less sustainable, more exhausting; flow has graceful exit, hyperfocus has abrupt crash. Distinguishing features vs. Focus: hyperfocus is involuntary, extreme, time-distorting; focus is moderate, effortful, controllable Distinguishing features vs. Obsession: hyperfocus is state-dependent and domain-specific; obsession is content-driven and intrusive across contexts. Breaking hyperfocus requires strong external interrupt (physical intervention) or complete task exhaustion (depletion forces disengagement).
HUNGER
Interoceptive precision Π_i elevated 2-4σ (β > 1.3 for metabolic/gastric signals); homeostatic prediction error (caloric deficit) creates persistent high-precision signal; threshold θₜ_non-essential elevated 15-30% for non-food-related cognition while θₜ_food lowered ~20% for food-relevant content; task-irrelevant prediction errors amplified, disrupting concentration.
Hunger represents a high-priority homeostatic alarm. Ghrelin (hunger hormone) and declining glucose levels signal metabolic prediction error. The hypothalamus elevates precision on interoceptive hunger signals via β parameter amplification—ensuring the deficit dominates awareness. Simultaneously, the orbitofrontal cortex lowers threshold specifically for food-related content (food cues, eating opportunities readily ignite). Cognitive resources are diverted from abstract tasks to food-seeking, impairing performance on non-survival-relevant activities. Hunger hijacking attention is adaptive—a metabolic crisis is genuinely higher priority than most cognitive tasks. The system correctly prioritizes survival-relevant processing. Hunger intensity fluctuates with ghrelin pulses and glucose fluctuations. "Hanger" (hunger-induced irritability) reflects elevated cortisol and reduced prefrontal inhibition—lowered threshold for negative affect and reduced emotional regulation capacity. Hungry individuals show: reduced working memory, impaired decision-making (risk preference shifts), decreased self-control, increased impulsive choice. These deficits reflect resource diversion and elevated threshold for complex cognition. Blood sugar regulation variability predicts hunger's cognitive impact—diabetics or those with insulin sensitivity show larger performance fluctuations. Food consumption suppresses ghrelin, restores glucose, reduces β amplification of hunger signals—cognitive function returns within 15-30 minutes.
THIRST
Similar parametric structure to hunger—interoceptive precision Π_i elevated 2-3σ (β > 1.2 for osmotic/hydration signals); homeostatic prediction error (fluid deficit) generates persistent high-precision alarm; threshold θₜ_global elevated ~15-25% for non-essential cognition except θₜ_water lowered ~15-20% for water-relevant cues; attentional capture by hydration-related content. Thirst operates through angiotensin and osmoreceptor signaling—detecting blood volume and osmolality. The subfornical organ and hypothalamus elevate precision on dehydration signals, ensuring they dominate awareness. The anterior cingulate (monitoring) and insula (interoceptive salience) show heightened activation. Similar to hunger, the threshold for abstract cognition elevates (conserving resources) while the threshold for water-related content lowers (prioritizing resolution). Dehydration (even mild, 2-3% body water loss) impairs: attention, working memory, psychomotor performance, mood (increased irritability). These effects reflect both metabolic constraints (reduced cerebral blood flow) and attentional hijacking (elevated Π_i demanding processing resources). Thirst signals intensify with dehydration severity. Chronic mild dehydration (common in modern environments with constant coffee/soda consumption) may create persistent low-level cognitive impairment. Fluid consumption rapidly suppresses thirst signals—cognitive restoration occurs within minutes as osmolality normalizes. Thirst is computationally similar to hunger but generally less cognitively disruptive (perhaps reflecting that dehydration is slower-onset and less immediately mortal than starvation in evolutionary context). However, severe thirst becomes overwhelmingly dominant—as expected for critical survival signals.



"""

    @AppStorage("contentFontSize") private var fontSize: Double = 15.0

    private struct StateSection: Identifiable, Hashable {
        let id: String
        let headerLine: String
        let body: String

        var displayTitle: String {
            headerLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private struct ParsedContent {
        let introTitle: String
        let introBody: String
        let sections: [StateSection]
    }

    private var parsedContent: ParsedContent {
        let lines = psychologicalStatesIntro.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        func isStateHeader(_ line: String) -> Bool {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 3 else { return false }
            guard trimmed == trimmed.uppercased() else { return false }
            guard trimmed.rangeOfCharacter(from: .letters) != nil else { return false }
            guard trimmed.rangeOfCharacter(from: .lowercaseLetters) == nil else { return false }
            return true
        }

        var headerIndices: [Int] = []
        headerIndices.reserveCapacity(32)
        for (idx, line) in lines.enumerated() {
            if isStateHeader(line) {
                headerIndices.append(idx)
            }
        }

        let introEndIndex = headerIndices.first ?? lines.count
        let introLines = Array(lines.prefix(introEndIndex))
        let trimmedIntroLines = introLines.drop { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let introTitle = trimmedIntroLines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let introBody: String = {
            guard !trimmedIntroLines.isEmpty else { return "" }
            let rest = Array(trimmedIntroLines.dropFirst())
            return rest.joined(separator: "\n")
        }()

        var sections: [StateSection] = []
        for (pos, start) in headerIndices.enumerated() {
            let end = (pos + 1 < headerIndices.count) ? headerIndices[pos + 1] : lines.count
            let headerLine = lines[start]
            let bodyLines = Array(lines[(start + 1)..<end])
            let body = bodyLines.joined(separator: "\n")
            let id = headerLine.trimmingCharacters(in: .whitespacesAndNewlines)
            sections.append(.init(id: id, headerLine: headerLine, body: body))
        }

        return ParsedContent(introTitle: introTitle, introBody: introBody, sections: sections)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: APGISpacing.sectionSpacing) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Psychological States")
                            .font(APGITypography.titleLarge)
                            .foregroundStyle(.primary)

                        if !parsedContent.introTitle.isEmpty {
                            Text(parsedContent.introTitle)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.primary)
                        }

                        if !parsedContent.introBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            LazyGlossaryHighlightedContent(text: parsedContent.introBody)
                                .font(.system(size: fontSize, design: .default))
                                .lineSpacing(6)
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(APGISpacing.cardPadding)
                    .background {
                        RoundedRectangle(cornerRadius: APGIRadius.lg, style: .continuous)
                            .fill(.background)
                            .shadow(color: Color.apgiBlue.opacity(0.08), radius: 10, y: 4)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: APGIRadius.lg, style: .continuous)
                            .strokeBorder(Color.apgiBlue.opacity(0.18), lineWidth: 1)
                    }

                    if !parsedContent.sections.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(parsedContent.sections) { section in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            proxy.scrollTo(section.id, anchor: .top)
                                        }
                                    } label: {
                                        Text(section.displayTitle)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color.apgiBlue.opacity(0.12))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().strokeBorder(Color.apgiBlue.opacity(0.22), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }

                    ForEach(parsedContent.sections) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.headerLine)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .kerning(0.6)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            LazyGlossaryHighlightedContent(text: section.body)
                                .font(.system(size: fontSize, design: .default))
                                .lineSpacing(6)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .id(section.id)
                        .padding(APGISpacing.cardPadding)
                        .background {
                            RoundedRectangle(cornerRadius: APGIRadius.lg, style: .continuous)
                                .fill(.background)
                                .shadow(color: Color.apgiPurple.opacity(0.06), radius: 10, y: 4)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: APGIRadius.lg, style: .continuous)
                                .strokeBorder(Color.apgiPurple.opacity(0.16), lineWidth: 1)
                        }
                    }
                }
                .padding(APGISpacing.screenMargin)
            }
        }
    }
}

#Preview {
    PsychologicalStatesView()
}
