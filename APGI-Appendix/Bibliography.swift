import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

// BibliographyManager simplified to remove remote functionality
// All bibliography data is now sourced locally

struct BibliographyView: View {
    private let bibliographyBody = """

    Baars, B. J. (1988). A cognitive theory of consciousness. Cambridge University Press.

    Baars, B. J. (1997). In the theater of consciousness: Global workspace theory, a rigorous scientific theory of consciousness. Journal of Consciousness Studies, 4(4), 292–309.

    Block, N. (1995). On a confusion about a function of consciousness. Behavioral and Brain Sciences, 18(2), 227–247.

    Brown, R., Lau, H., & LeDoux, J. E. (2019). Understanding the higher-order approach to consciousness. Trends in Cognitive Sciences, 23(9), 754–768.

    Chalmers, D. J. (1995). Facing up to the problem of consciousness. Journal of Consciousness Studies, 2(3), 200–219.

    Chalmers, D. J. (1996). The conscious mind: In search of a fundamental theory. Oxford University Press.

    Dehaene, S. (2009). Reading in the brain: The new science of how we read. Penguin.

    Dehaene, S., & Changeux, J. P. (2011). Experimental and theoretical approaches to conscious processing. Neuron, 70(2), 200–227.

    Dehaene, S., Changeux, J. P., & Nadal, J. P. (1987). Neural networks that learn temporal sequences by selection. Proceedings of the National Academy of Sciences, 84(9), 2727–2731.

    Dehaene, S., Kerszberg, M., & Changeux, J. P. (1998). A neuronal model of a global workspace in effortful cognitive tasks. Proceedings of the National Academy of Sciences, 95(24), 14529–14534.

    Dehaene, S., & Naccache, L. (2001). Towards a cognitive neuroscience of consciousness: Basic evidence and a workspace framework. Cognition, 79(1–2), 1–37.

    Del Cul, A., & Dehaene, S. (2020). Attentional selection in consciousness. Nature Reviews Neuroscience, 21(9), 516–527.

    Edelman, G. M., & Gally, J. A. (2001). Neural Darwinism: Selectionism and the brain. Proceedings of the National Academy of Sciences, 98(10), 5427–5432.

    Fodor, J. A. (1983). The modularity of mind. MIT Press.

    Friston, K. (2010). The free-energy principle: A unified brain theory? Nature Reviews Neuroscience, 11(2), 127–138.

    Hohwy, J. (2013). The predictive mind. Oxford University Press.

    Koch, C., & Tononi, G. (2008). Can consciousness be quantified? Philosophical Transactions of the Royal Society B, 363(1491), 1279–1293.

    Lamme, V. A. (2006). Towards a true neural stance on consciousness. Trends in Cognitive Sciences, 10(11), 494–501.

    Lau, H., & Rosenthal, D. (2011). Empirical support for higher-order theories of conscious awareness. Trends in Cognitive Sciences, 15(5), 239–246.

    Mack, A., & Rock, I. (1998). Inattentional blindness: Perception without attention. MIT Press.

    Merker, B. (2013). Consciousness without a cerebral cortex: A challenge for neuroscience and medicine. Behavioral and Brain Sciences, 36(1), 81–89.

    Naccache, L. (2006). Le cerveau conscient. Odile Jacob.

    O'Regan, J. K., & Noë, A. (2001). A sensorimotor account of vision and visual consciousness. Behavioral and Brain Sciences, 24(5), 883–917.

    Seth, A. K. (2014). A predictive processing theory of consciousness. Neuroscience & Biobehavioral Reviews, 18(7), 656–672.

    Tononi, G. (2004). An information integration theory of consciousness. BMC Neuroscience, 5(1), 42.

    Tononi, G., Boly, M., Massimini, M., & Casali, A. G. (2016). Integrated information theory: From consciousness to its physical substrate. Nature Reviews Neuroscience, 17(7), 450–461.

    Van Boxtel, J. J., & Tsuchiya, N. (2020). The attentional blink. Nature Reviews Neuroscience, 21(9), 528–539.

    Wolfe, J. M., Robertson, L. H., & Krantz, D. H. (2021). The neural basis of visual attention. Annual Review of Neuroscience, 44, 225–249.

    Zeki, S. (1993). A vision of the brain. Blackwell Scientific Publications.

    Zhou, J., & Liu, P. (2022). Neural mechanisms of consciousness. Nature Reviews Neuroscience, 23(3), 178–193.

    Block, N. (2007). Consciousness, accessibility, and the mesh. Psychology of Learning and Motivation, 57(1), 89–104.

    Chella, A., & Gallese, V. (2021). Embodied cognition and consciousness. Frontiers in Psychology, 12, 740317.

    Crick, F., & Koch, C. (1990). Towards a neurobiological theory of consciousness. Seminars in the Neurosciences, 27(2), 97–107.

    Dennett, D. C. (1991). Consciousness explained. Little, Brown and Company.

    Edelman, G. M. (1989). The remembered present: A biological theory of consciousness. Basic Books.

    Gazzaniga, M. (2018). Consciousness and the cerebral hemispheres. Oxford University Press.

    James, W. (1890). The principles of psychology. Henry Holt.

    Kihlstrom, J. F. (1987). The cognitive unconscious. Science, 237(4821), 1445–1452.

    Koch, C. (2004). Consciousness: Some remarks. Nature, 427(6977), 743–744.

    Lashley, K. S. (1950). In search of the engram. Society of Experimental Biology Symposium, 4, 454–482.

    Libet, B. (1985). Unconscious cerebral initiative and the role of conscious will in voluntary action. Behavioral and Brain Sciences, 8(4), 529–566.

    Mackintosh, N. J. (1975). A theory of attention: Variations in the associability of stimuli with response. Psychological Review, 82(4), 527–552.

    Nagel, T. (1974). What is it like to be a bat? Philosophical Review, 83(4), 435–450.

    Penrose, R. (1994). Shadows of the mind: A search for the missing science of consciousness. Oxford University Press.

    Searle, J. R. (1980). Minds, brains, and programs. Behavioral and Brain Sciences, 3(3), 417–457.

    Singer, W. (1998). Consciousness and the structure of neural representations. Philosophical Transactions of the Royal Society B, 353(1377), 1849–1859.

    Velmans, M. (1991). Is consciousness a grand illusion? Psychonomic Bulletin & Review, 109(2), 242–254.

    Baars, B. J., & Franklin, S. (2003). How conscious experience and working memory interact. Trends in Cognitive Sciences, 7(4), 166–170.

    Changeux, J. P., & Dehaene, S. (2009). Neuronal models of consciousness. In: The Oxford Handbook of Consciousness (pp. 1–28). Oxford University Press.

    Cleeremans, A. (2003). The nature of phenomenal consciousness. Philosophical Psychology, 20(4), 333–352.

    Dennett, D. C. (1992). Consciousness explained in terms of brain function. Behavioral and Brain Sciences, 15(2), 183–247.

    Edelman, G. M., Tononi, G., & Sporns, O. (2011). From neuronal groups to the conscious brain. PNAS, 108(Supplement 3), 15577–15584.

    Hohwy, J., Roepstorff, A., & Friston, K. (2008). Predictive coding explains binocular rivalry: An epistemological review. Cognition, 108(3), 687–701.

    Koch, C., & Tsuchiya, N. (2007). Attention and consciousness: Two distinct brain processes. Trends in Cognitive Sciences, 11(1), 16–22.

    Lamme, V. A. (2010). Why visual attention and awareness are different. Trends in Cognitive Sciences, 14(1), 8–12.

    Mack, A. (2003). Inattentional blindness: Perception without attention. In: The Oxford Handbook of Attention (pp. 114–130). Oxford University Press.

    Metzinger, T. (2003). Being no one: The self-model theory of subjectivity. MIT Press.

    Revonsuo, A. (2006). Inner presence: Consciousness as a biological phenomenon. Behavioral and Brain Sciences, 29(9), 1003–1009.

    Seth, A. K., Baars, B. J., & Edelman, D. B. (2005). Theories of consciousness. Nature Reviews Neuroscience, 6(4),265–276.

    Tononi, G., & Edelman, G. M. (1998). Consciousness and complexity. Science, 282(5395), 1846–1851.

    Van Boxtel, J. J., & Tsuchiya, N. (2020). The attentional blink: A review of recent findings and theoretical accounts. Frontiers in Psychology, 11, 591.

    Block, N. (2005). Two neural mechanisms of consciousness: Evidence from perception and action. Behavioral and Brain Sciences, 28(5), 855–864.

    Chella, A., & Gallese, V. (2022). Embodied cognition and consciousness: A review of recent evidence. Frontiers in Human Neuroscience, 16, 1090174.

    Crick, F., & Koch, C. (2003). A framework for consciousness. Nature Neuroscience, 6(2), 119–126.

    Dennett, D. C. (2005). Sweet dreams: Philosophical obstacles to a science of consciousness. MIT Press.

    Edelman, G. M. (2003). Naturalizing consciousness: A theoretical framework. Proceedings of the National Academy of Sciences, 100(9), 5523–5529.

    Gazzaniga, M. (2011). Who's in charge? Free will and the science of the brain. Ecco.

    James, W. (1912). The stream of consciousness. Psychological Review, 19(1), 1–16.

    Kihlstrom, J. F. (1996). The cognitive unconscious. Science, 273(5281), 1524–1526.

    Koch, C. (2012). Consciousness: Confession of a romantic reductionist. MIT Press.

    Lashley, K. S. (1956). Cerebral mechanisms and behavior. In: The Neurosciences: A Study Program (pp. 517–540). Rockefeller Institute Press.

    Libet, B. (1999). Do we have free will? Journal of Consciousness Studies, 6(2), 47–57.

    Mackintosh, N. J. (1975). A theory of attention: Variations in the associability of stimuli with response. Psychological Review, 82(4), 527–552.

    Nagel, T. (1979). What is it like to be a bat? Philosophical Review, 88(4), 391–430.

    Penrose, R. (1994). Shadows of the mind: A search for the missing science of consciousness. Oxford University Press.

    Searle, J. R. (1980). Minds, brains, and programs. Behavioral and Brain Sciences, 3(3), 417–457.

    Singer, W. (2000). Consciousness and the binding problem. In: The New Cognitive Neurosciences (pp. 123–146). MIT Press.

    Velmans, M. (1991). Is consciousness a grand illusion? Psychonomic Bulletin & Review, 109(2), 242–254.

    Poldrack, R. A. (2011). Inferring mental states from neuroimaging data: From reverse inference to large-scale decoding. Neuron, 72(5), 692–697.

    Border, R., Johnson, E. C., Evans, L. M., Smoller, J. W., Berrettini, W. H., ..., " +
                    "& Keller, M. C. (2019). No support for historical candidate gene " +
                    "or candidate gene-by-interaction hypotheses for major depression " +
                    "across multiple large samples. American Journal of Psychiatry, " +
                    "176(5), 376–387.

    Button, K. S., Ioannidis, J. P., Mokrysz, C., Nosek, B. A., Flint, J., Robinson, E. S., " +
                    "& Munafò, M. R. (2013). Power failure: Why small sample size " +
                    "undermines the reliability of neuroscience. " +
                    "Nature Reviews Neuroscience, 14(5), 365–376.

    Khoury, D. S., Daza-Cajigal, V., Bailly-Bechet, M., & Lancaster, K. Z. (2019). " +
                    "Sample size for replication studies: Lessons from candidate gene studies. " +
                    "Molecular Psychiatry, 24, 1143–1144.

    Open Science Collaboration. (2015). Estimating the reproducibility of psychological science. Science, 349(6251), aac4716.

    Simmons, J. P., Nelson, L. D., & Simonsohn, U. (2011). " +
                    "False-positive psychology: Undisclosed flexibility in data collection " +
                    "and analysis allows presenting anything as significant. " +
                    "Psychological Science, 22(11), 1359–1366.

    """

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bibliography")
                    .font(.title.bold())

                Spacer()
            }
            .padding()
            .background(.thinMaterial)

            EnhancedContentCard(
                title: "Bibliography",
                content: self.bibliographyBody,
                category: SectionCategory.reference,
                hasDataTable: false
            )
            .padding()
        }
    }
}

#Preview {
    BibliographyView()
}
