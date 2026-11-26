import SwiftUI
import Foundation
import Compression

// The Islam tab's articles as SEARCHABLE TEXT. The Pillars, Beliefs, Aqeedah, Scholars, Answers and
// How-to screens write their prose inline in SwiftUI, which reads well and searches not at all - so
// Scripts/build_islam_corpus.py lifts it back out at build time into `IslamArticles.json.deflate`,
// and this reads it back.
//
// It exists for the Ask AI chat: without it the assistant answered questions about wudhu, the
// pillars, tawhid or the madhahib from whatever the on-device model half-remembered, while the app's
// own sourced page on exactly that subject sat one tab away. Now that page is a retrieval lane, and
// the answer cites the article, which opens.
//
// Rebuild the pack whenever the article prose changes:
//     ./Scripts/build_islam_corpus.py && ./Scripts/verify_islam_corpus.py

struct IslamArticle: Identifiable, Equatable, Sendable {
    struct Section: Equatable, Sendable {
        /// The screen's own section header ("SUMMARY", "WHAT BREAKS WUDHU"). Empty for prose that
        /// sits above the first header.
        let heading: String
        let text: String
        /// `text` lowercased with punctuation flattened, computed once at load. Searching folds the
        /// query instead of the corpus: 800 KB of prose is far too much to re-fold per question.
        let folded: String
        /// Where the page's own search bar lands for this section when it is not the heading: the
        /// key a page built at runtime puts on the row the passage begins with (`articleAnchor`).
        /// Nil for the corpus, whose sections land on their `ArticleHeader`.
        var anchor: String? = nil
        /// The Arabic of the section's quote cards (the ayahs, the hadith, the scholars' words), one
        /// card per line: SEARCH ONLY (2026-11-24, Abu: "Searching up Arabic or for verses and Hadiths
        /// in Islam shows nothing"). `text` is what the Ask AI chat reads and keeps its English; the
        /// cards' Arabic never reached the search before.
        var arabic: String = ""
        /// `arabic` through `fold`, and again with the mushaf's dagger alif written as a full alif when
        /// that differs: the fold drops the dagger, so a typed السموات finds ٱلسَّمَٰوَٰتِ, and the
        /// second lane lets the modern السماوات find it too.
        var foldedArabic: String = ""

        /// The one version of the page that shows this section, when only the full article does
        /// (ArticleLength.swift): a hit here opens the page in full. Nil for what both show.
        var only: ArticleLength? = nil

        /// What the page's search scrolls to for this section: its anchor, or its heading.
        var landing: String { anchor ?? heading }
    }

    /// The article view's type name, e.g. "WudhuView" - what `destination(for:)` reopens.
    let id: String
    /// The navigation title exactly as the screen prints it.
    let title: String
    let sections: [Section]
    let foldedTitle: String
}

enum IslamArticles {
    static let all: [IslamArticle] = load()

    /// The article a cited passage came from, as the real screen. Every id in the pack has a case
    /// here - verify_islam_corpus.py fails the build if one is missing.
    @MainActor
    static func destination(for id: String) -> AnyView? {
        switch id {
        case "GodPillarView": return AnyView(GodPillarView())
        case "IslamPillarView": return AnyView(IslamPillarView())
        case "MuslimPillarView": return AnyView(MuslimPillarView())
        case "AllahPillarView": return AnyView(AllahPillarView())
        case "NamesOfAllahPillarView": return AnyView(NamesOfAllahPillarView())
        case "QuranPillarView": return AnyView(QuranPillarView())
        case "QuranRevealedPillarView": return AnyView(QuranRevealedPillarView())
        case "MuqattaatPillarView": return AnyView(MuqattaatPillarView())
        case "QuranWordsPillarView": return AnyView(QuranWordsPillarView())
        case "ProphetPillarView": return AnyView(ProphetPillarView())
        case "SunnahPillarView": return AnyView(SunnahPillarView())
        case "HadithPillarView": return AnyView(HadithPillarView())
        case "ShahadahView": return AnyView(ShahadahView())
        case "SalahView": return AnyView(SalahView())
        case "SawmView": return AnyView(SawmView())
        case "ZakahView": return AnyView(ZakahView())
        case "HajjView": return AnyView(HajjView())
        case "GodView": return AnyView(GodView())
        case "AngelsView": return AnyView(AngelsView())
        case "BooksView": return AnyView(BooksView())
        case "ProphetsView": return AnyView(ProphetsView())
        case "ProphetAdamView": return AnyView(ProphetAdamView())
        case "ProphetIdrisView": return AnyView(ProphetIdrisView())
        case "ProphetNuhView": return AnyView(ProphetNuhView())
        case "ProphetHudView": return AnyView(ProphetHudView())
        case "ProphetSalihView": return AnyView(ProphetSalihView())
        case "ProphetIbrahimView": return AnyView(ProphetIbrahimView())
        case "ProphetLutView": return AnyView(ProphetLutView())
        case "ProphetIsmailView": return AnyView(ProphetIsmailView())
        case "ProphetIshaqView": return AnyView(ProphetIshaqView())
        case "ProphetYaqubView": return AnyView(ProphetYaqubView())
        case "ProphetYusufView": return AnyView(ProphetYusufView())
        case "ProphetAyyubView": return AnyView(ProphetAyyubView())
        case "ProphetShuaybView": return AnyView(ProphetShuaybView())
        case "ProphetMusaView": return AnyView(ProphetMusaView())
        case "ProphetHarunView": return AnyView(ProphetHarunView())
        case "ProphetDhulKiflView": return AnyView(ProphetDhulKiflView())
        case "ProphetDawudView": return AnyView(ProphetDawudView())
        case "ProphetSulaymanView": return AnyView(ProphetSulaymanView())
        case "ProphetIlyasView": return AnyView(ProphetIlyasView())
        case "ProphetAlyasaView": return AnyView(ProphetAlyasaView())
        case "ProphetYunusView": return AnyView(ProphetYunusView())
        case "ProphetZakariyaView": return AnyView(ProphetZakariyaView())
        case "ProphetYahyaView": return AnyView(ProphetYahyaView())
        case "ProphetIsaView": return AnyView(ProphetIsaView())
        case "ProphetMuhammadView": return AnyView(ProphetMuhammadView())
        case "DayView": return AnyView(DayView())
        case "QadarView": return AnyView(QadarView())
        case "RububiyyahView": return AnyView(RububiyyahView())
        case "UluhiyyahView": return AnyView(UluhiyyahView())
        case "AsmaSifatView": return AnyView(AsmaSifatView())
        case "HaramView": return AnyView(HaramView())
        case "NabawiView": return AnyView(NabawiView())
        case "AqsaView": return AnyView(AqsaView())
        case "WudhuView": return AnyView(WudhuView())
        case "GhuslView": return AnyView(GhuslView())
        case "JumuahView": return AnyView(JumuahView())
        case "AdhanOtherView": return AnyView(AdhanOtherView())
        case "IqamahView": return AnyView(IqamahView())
        case "TakbiratView": return AnyView(TakbiratView())
        case "HijriCalendarView": return AnyView(HijriCalendarView())
        case "SacredMonthsView": return AnyView(SacredMonthsView())
        case "MoonSightingView": return AnyView(MoonSightingView())
        case "CompileView": return AnyView(CompileView())
        case "TajweedView": return AnyView(TajweedView())
        case "JuzView": return AnyView(JuzView())
        case "AhrufView": return AnyView(AhrufView())
        case "QiraatView": return AnyView(QiraatView())
        case "QiraatContradictView": return AnyView(QiraatContradictView())
        case "ProvingClosingView": return AnyView(ProvingClosingView())
        case "ProvingQuestionsView": return AnyView(ProvingQuestionsView())
        case "ProvingGodView": return AnyView(ProvingGodView())
        case "ProvingJesusView": return AnyView(ProvingJesusView())
        case "ProvingEthicsView": return AnyView(ProvingEthicsView())
        case "ProvingScriptureView": return AnyView(ProvingScriptureView())
        case "ProvingBibleView": return AnyView(ProvingBibleView())
        case "ProvingSourcesView": return AnyView(ProvingSourcesView())
        case "ProvingProphecyView": return AnyView(ProvingProphecyView())
        case "ProvingScienceView": return AnyView(ProvingScienceView())
        case "ProvingIjazView": return AnyView(ProvingIjazView())
        case "ProvingPreservationView": return AnyView(ProvingPreservationView())
        case "ProvingStylometryView": return AnyView(ProvingStylometryView())
        case "ProvingContinuationView": return AnyView(ProvingContinuationView())
        case "ProvingProphetView": return AnyView(ProvingProphetView())
        case "ProvingFingerprintView": return AnyView(ProvingFingerprintView())
        case "ProvingCaseView": return AnyView(ProvingCaseView())
        case "HadithRejectorsView": return AnyView(HadithRejectorsView())
        case "HadithPreservationView": return AnyView(HadithPreservationView())
        case "HadithSciencesView": return AnyView(HadithSciencesView())
        case "RiwayatDifferencesView": return AnyView(RiwayatDifferencesView())
        case "FarewellView": return AnyView(FarewellView())
        case "SahabahView": return AnyView(SahabahView())
        case "WivesView": return AnyView(WivesView())
        case "CaliphatesView": return AnyView(CaliphatesView())
        case "MadhabView": return AnyView(MadhabView())
        case "AhlulBaytView": return AnyView(AhlulBaytView())
        case "AhlusSunnahView": return AnyView(AhlusSunnahView())
        case "SeerahView": return AnyView(SeerahView())
        case "TafsirView": return AnyView(TafsirView())
        case "FiqhAqeedahManhajView": return AnyView(FiqhAqeedahManhajView())
        case "HowToPrayView": return AnyView(HowToPrayView())
        case "HowToFastView": return AnyView(HowToFastView())
        case "HowToZakahView": return AnyView(HowToZakahView())
        case "HowToHajjView": return AnyView(HowToHajjView())
        case "HowToUmrahView": return AnyView(HowToUmrahView())
        case "AqeedahMadhabView": return AnyView(AqeedahMadhabView())
        case "TawhidView": return AnyView(TawhidView())
        case "SalafiyyahView": return AnyView(SalafiyyahView())
        case "QuranSunnahView": return AnyView(QuranSunnahView())
        case "ShirkView": return AnyView(ShirkView())
        case "KufrView": return AnyView(KufrView())
        case "BidahView": return AnyView(BidahView())
        case "MawlidView": return AnyView(MawlidView())
        case "EvilEyeView": return AnyView(EvilEyeView())
        case "SahabahScholarsView": return AnyView(SahabahScholarsView())
        // BEGIN LIBRARY CASES (gen_catalog.py)
        case "StoryProphetsView": return AnyView(StoryProphetsView())
        case "StoryIntroView": return AnyView(StoryIntroView())
        case "StoryFamilyView": return AnyView(StoryFamilyView())
        case "StoryNationsView": return AnyView(StoryNationsView())
        case "StoryAdamView": return AnyView(StoryAdamView())
        case "StoryIdrisView": return AnyView(StoryIdrisView())
        case "StoryNuhView": return AnyView(StoryNuhView())
        case "StoryHudView": return AnyView(StoryHudView())
        case "StorySalihView": return AnyView(StorySalihView())
        case "StoryShuaybView": return AnyView(StoryShuaybView())
        case "StoryIbrahimView": return AnyView(StoryIbrahimView())
        case "StoryLutView": return AnyView(StoryLutView())
        case "StoryKabahView": return AnyView(StoryKabahView())
        case "StoryIshaqView": return AnyView(StoryIshaqView())
        case "StoryYaqubView": return AnyView(StoryYaqubView())
        case "StoryYusufView": return AnyView(StoryYusufView())
        case "StoryAyyubView": return AnyView(StoryAyyubView())
        case "StoryYunusView": return AnyView(StoryYunusView())
        case "StoryMusaEarlyView": return AnyView(StoryMusaEarlyView())
        case "StoryMusaPharaohView": return AnyView(StoryMusaPharaohView())
        case "StoryHarunView": return AnyView(StoryHarunView())
        case "StoryWildernessView": return AnyView(StoryWildernessView())
        case "StoryKhidrView": return AnyView(StoryKhidrView())
        case "StoryDawudView": return AnyView(StoryDawudView())
        case "StorySulaymanView": return AnyView(StorySulaymanView())
        case "StoryIlyasView": return AnyView(StoryIlyasView())
        case "StoryAlyasaView": return AnyView(StoryAlyasaView())
        case "StoryDhulKiflView": return AnyView(StoryDhulKiflView())
        case "StoryZakariyyaView": return AnyView(StoryZakariyyaView())
        case "StoryYahyaView": return AnyView(StoryYahyaView())
        case "StoryMaryamView": return AnyView(StoryMaryamView())
        case "StoryIsaView": return AnyView(StoryIsaView())
        case "StoryMuhammadView": return AnyView(StoryMuhammadView())
        case "StoryIsraeliyyatView": return AnyView(StoryIsraeliyyatView())
        case "CompanionsIntroView": return AnyView(CompanionsIntroView())
        case "CompanionAbuBakrView": return AnyView(CompanionAbuBakrView())
        case "CompanionUmarView": return AnyView(CompanionUmarView())
        case "CompanionUthmanView": return AnyView(CompanionUthmanView())
        case "CompanionAliView": return AnyView(CompanionAliView())
        case "CompanionTenView": return AnyView(CompanionTenView())
        case "CompanionKhadijahAishahView": return AnyView(CompanionKhadijahAishahView())
        case "CompanionFatimahView": return AnyView(CompanionFatimahView())
        case "CompanionUnclesView": return AnyView(CompanionUnclesView())
        case "CompanionFirstBelieversView": return AnyView(CompanionFirstBelieversView())
        case "CompanionAbuHurayrahView": return AnyView(CompanionAbuHurayrahView())
        case "CompanionWomenView": return AnyView(CompanionWomenView())
        case "CompanionTabiunView": return AnyView(CompanionTabiunView())
        case "CompanionFourImamsView": return AnyView(CompanionFourImamsView())
        case "ReligionsMethodView": return AnyView(ReligionsMethodView())
        case "ReligionsOneView": return AnyView(ReligionsOneView())
        case "ReligionsPluralismView": return AnyView(ReligionsPluralismView())
        case "ReligionsSikhismView": return AnyView(ReligionsSikhismView())
        case "ReligionsZoroastrianismView": return AnyView(ReligionsZoroastrianismView())
        case "ReligionsEastAsiaView": return AnyView(ReligionsEastAsiaView())
        case "ReligionsSecularismView": return AnyView(ReligionsSecularismView())
        case "ReligionsNewProphetsView": return AnyView(ReligionsNewProphetsView())
        case "PreservationStagesView": return AnyView(PreservationStagesView())
        case "PreservationMemoryView": return AnyView(PreservationMemoryView())
        case "PreservationWritingView": return AnyView(PreservationWritingView())
        case "PreservationOrderView": return AnyView(PreservationOrderView())
        case "PreservationScriptView": return AnyView(PreservationScriptView())
        case "PreservationManuscriptsView": return AnyView(PreservationManuscriptsView())
        case "PreservationNaskhView": return AnyView(PreservationNaskhView())
        case "PreservationClaimsView": return AnyView(PreservationClaimsView())
        case "HadithScienceTermsView": return AnyView(HadithScienceTermsView())
        case "HadithScienceBreaksView": return AnyView(HadithScienceBreaksView())
        case "HadithScienceRijalView": return AnyView(HadithScienceRijalView())
        case "HadithScienceAhadView": return AnyView(HadithScienceAhadView())
        case "HadithScienceFabricationView": return AnyView(HadithScienceFabricationView())
        case "HadithScienceQudsiView": return AnyView(HadithScienceQudsiView())
        case "HadithScienceGradesView": return AnyView(HadithScienceGradesView())
        case "HadithScienceOrientalistsView": return AnyView(HadithScienceOrientalistsView())
        case "DominoIntroView": return AnyView(DominoIntroView())
        case "DominoRealityView": return AnyView(DominoRealityView())
        case "DominoCreatorView": return AnyView(DominoCreatorView())
        case "DominoOneView": return AnyView(DominoOneView())
        case "DominoWorldviewsView": return AnyView(DominoWorldviewsView())
        case "DominoRevelationView": return AnyView(DominoRevelationView())
        case "DominoTestView": return AnyView(DominoTestView())
        case "DominoChristianityView": return AnyView(DominoChristianityView())
        case "DominoIslamView": return AnyView(DominoIslamView())
        case "DominoDawahView": return AnyView(DominoDawahView())
        // END LIBRARY CASES
        case "SalafScholarsView": return AnyView(SalafScholarsView())
        case "TabariView": return AnyView(TabariView())
        case "IbnTaymiyyahView": return AnyView(IbnTaymiyyahView())
        case "IbnQayyimView": return AnyView(IbnQayyimView())
        case "DhahabiView": return AnyView(DhahabiView())
        case "IbnKathirView": return AnyView(IbnKathirView())
        case "LaterScholarsView": return AnyView(LaterScholarsView())
        case "SufismAnswerView": return AnyView(SufismAnswerView())
        case "ShiaAnswerView": return AnyView(ShiaAnswerView())
        case "ChristianityAnswerView": return AnyView(ChristianityAnswerView())
        case "JudaismAnswerView": return AnyView(JudaismAnswerView())
        case "HinduismAnswerView": return AnyView(HinduismAnswerView())
        case "PaganismAnswerView": return AnyView(PaganismAnswerView())
        case "BuddhismAnswerView": return AnyView(BuddhismAnswerView())
        case "AtheismAnswerView": return AnyView(AtheismAnswerView())
        case "TayammumView": return AnyView(TayammumView())
        case "AwrahView": return AnyView(AwrahView())
        case "RawatibView": return AnyView(RawatibView())
        case "WitrView": return AnyView(WitrView())
        case "TahajjudView": return AnyView(TahajjudView())
        case "DuhaView": return AnyView(DuhaView())
        case "TaraweehView": return AnyView(TaraweehView())
        case "JanazahView": return AnyView(JanazahView())
        case "IstikharahView": return AnyView(IstikharahView())
        case "KhutbahView": return AnyView(KhutbahView())
        case "TravelPrayerView": return AnyView(TravelPrayerView())
        case "CombinePrayersView": return AnyView(CombinePrayersView())
        case "PlanePrayerView": return AnyView(PlanePrayerView())
        case "SickPrayerView": return AnyView(SickPrayerView())
        case "MissedPrayerView": return AnyView(MissedPrayerView())
        case "SujudSahwView": return AnyView(SujudSahwView())
        case "VoluntaryFastsView": return AnyView(VoluntaryFastsView())
        case "ItikafView": return AnyView(ItikafView())
        case "ZakatFitrView": return AnyView(ZakatFitrView())
        case "UdhiyahView": return AnyView(UdhiyahView())
        case "BecomeMuslimView": return AnyView(BecomeMuslimView())
        case "TawbahView": return AnyView(TawbahView())
        case "MakeDuaView": return AnyView(MakeDuaView())
        case "RuqyahView": return AnyView(RuqyahView())
        case "EvilEyeGuideView": return AnyView(EvilEyeGuideView())
        // The Tajweed Foundations pages (2026-11-23; `TajweedTopic.articleID`).
        case "TajweedOverviewView": return AnyView(TajweedOverviewView())
        case "TajweedImprovingRecitationView": return AnyView(TajweedImprovingRecitationView())
        case "TajweedLipMovementView": return AnyView(TajweedLipMovementView())
        case "TajweedMakharijView": return AnyView(TajweedMakharijView())
        case "TajweedHeavyLightView": return AnyView(TajweedHeavyLightView())
        case "TajweedShamsQamarView": return AnyView(TajweedShamsQamarView())
        case "TajweedMaddView": return AnyView(TajweedMaddView())
        case "TajweedQalqalahView": return AnyView(TajweedQalqalahView())
        case "TajweedIdghamIkhfaView": return AnyView(TajweedIdghamIkhfaView())
        case "TajweedMeemSakinahView": return AnyView(TajweedMeemSakinahView())
        case "TajweedInMushafView": return AnyView(TajweedInMushafView())
        case "TajweedSukoonView": return AnyView(TajweedSukoonView())
        case "TajweedHamzatulWaslView": return AnyView(TajweedHamzatulWaslView())
        case "TajweedWaqfView": return AnyView(TajweedWaqfView())
        default: return nil
        }
    }

    // MARK: Search

    /// The best sections for a question, most relevant first. Deliberately a keyword score and not
    /// an embedding: the lane has to answer on the FIRST question (an embedding build would not be
    /// ready yet), and article prose repeats its subject often enough that counting works. One
    /// section per article at most, so a long article cannot crowd the results.
    ///
    /// Terms are weighted by how RARE they are in the corpus. Plain counting put "what breaks the
    /// fast" on the article that says "the" most often; weighting by inverse document frequency
    /// makes "breaks" and "fast" carry the query and reduces "islam", "what" and "the" - words in
    /// nearly every article - to nothing, with no stopword list to keep in step with the prose.
    ///
    /// Cheap enough to await from a detached task, which is what the caller does: scanning the whole
    /// corpus on the main actor showed up as a hitch on the keystroke that sent the question.
    static func search(_ query: String, limit: Int) -> [(article: IslamArticle, section: IslamArticle.Section)] {
        let terms = Array(Set(fold(query).split(separator: " ").filter { $0.count > 2 }.map(String.init)))
        guard !terms.isEmpty, !all.isEmpty else { return [] }

        // Pass 1: hits per term, per section - and the document frequency that weights them.
        var documentFrequency = [Int](repeating: 0, count: terms.count)
        var counts: [[[Int]]] = []          // article -> section -> term -> hits
        for article in all {
            var perSection: [[Int]] = []
            var inArticle = [Bool](repeating: false, count: terms.count)
            for section in article.sections {
                var hits = [Int](repeating: 0, count: terms.count)
                for (index, term) in terms.enumerated() {
                    let count = section.folded.components(separatedBy: term).count - 1
                    hits[index] = count
                    if count > 0 { inArticle[index] = true }
                }
                perSection.append(hits)
            }
            for (index, present) in inArticle.enumerated() where present { documentFrequency[index] += 1 }
            counts.append(perSection)
        }
        let total = Double(all.count)
        let weights = documentFrequency.map { max(0, log(total / Double(1 + $0))) }
        guard weights.contains(where: { $0 > 0 }) else { return [] }

        // Pass 2: score. A title hit is worth far more than a body hit, so "how to make wudhu" cannot
        // lose to an article that merely mentions wudhu in passing.
        var best: [(article: IslamArticle, section: IslamArticle.Section, score: Double)] = []
        for (articleIndex, article) in all.enumerated() {
            var titleScore = 0.0
            for (index, term) in terms.enumerated() where article.foldedTitle.contains(term) {
                titleScore += 6 * weights[index]
            }
            var topSection: (IslamArticle.Section, Double)?
            for (sectionIndex, section) in article.sections.enumerated() {
                var score = 0.0
                for (index, hits) in counts[articleIndex][sectionIndex].enumerated() where hits > 0 {
                    score += weights[index] * (1 + Double(min(hits, 4)) * 0.5)
                }
                // Normalised by length, so a short on-point section beats a long rambling one.
                score /= max(1, Double(section.text.count) / 1200).squareRoot()
                if score > 0, score > (topSection?.1 ?? 0) { topSection = (section, score) }
            }
            guard let topSection, titleScore + topSection.1 > 0 else { continue }
            best.append((article, topSection.0, titleScore + topSection.1))
        }
        return best.sorted { $0.score > $1.score }.prefix(limit).map { ($0.article, $0.section) }
    }

    /// Lowercased, everything non-alphanumeric flattened to a space, so "wudhu," and "(wudhu)" both
    /// match "wudhu"; Latin accents folded first, so "Ṣaḥīḥ" and "Jāmiʿ" match "sahih" and "jami".
    /// `HadeethEncStore.foldEnglish` is this same rule over bytes and must stay identical to it.
    ///
    /// One pass over the scalars, the shape `foldEnglish` uses over bytes: ASCII decides itself, the
    /// `LatinFold` tables drop the transliteration marks and flatten an accented letter to its plain
    /// one, and only a scalar none of that covers pays for `lowercased()` and a `CharacterSet`
    /// lookup. The old version built the folded string, then a lowercased copy, then a `[Character]`
    /// of every scalar, and asked `CharacterSet.alphanumerics` about each one; it was ~3% of all
    /// profiler samples at launch over the ~1 MB corpus (Performance Guide, Phase 11).
    /// `UnitTests/IslamArticlesFoldEquivalenceTests` pins this to the old code scalar by scalar.
    static func fold(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        out.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            appendFolded(scalar, to: &out)
        }
        return String(out)
    }

    /// `fold`, and for each folded scalar the offset (in `text.unicodeScalars`) of the scalar it came
    /// from: how a match found in the folded text is shown in the text itself (a result's snippet,
    /// 2026-11-24). An Arabic word folds shorter than it is written, so the two never line up by count.
    static func foldMapped(_ text: String) -> (folded: String, origins: [Int]) {
        var out = String.UnicodeScalarView()
        out.reserveCapacity(text.unicodeScalars.count)
        var origins: [Int] = []
        origins.reserveCapacity(text.unicodeScalars.count)
        for (offset, scalar) in text.unicodeScalars.enumerated() {
            let added = appendFolded(scalar, to: &out)
            for _ in 0..<added { origins.append(offset) }
        }
        return (String(out), origins)
    }

    /// One scalar of `fold`, appended; returns how many scalars it became (0 when it drops).
    @inline(__always) @discardableResult
    private static func appendFolded(_ scalar: Unicode.Scalar, to out: inout String.UnicodeScalarView) -> Int {
        let value = scalar.value
        if value < 0x80 {
            // a-z and 0-9 stand, A-Z lowercases, everything else is a space.
            switch value {
            case 0x41...0x5A: out.append(Unicode.Scalar(value + 32)!)
            case 0x61...0x7A, 0x30...0x39: out.append(scalar)
            default: out.append(" ")
            }
            return 1
        } else if let arabic = arabicSearchScalar(value) {
            // Arabic (2026-11-24): the marks, the tatweel and the bare hamza drop, the alif and
            // hamza seats fold, and the Arabic-Indic digits are digits. Before this a typed توحيد
            // found nothing in a page that wrote تَوحِيد, because the harakat stood between the
            // letters.
            guard arabic != 0, let folded = Unicode.Scalar(arabic) else { return 0 }
            out.append(folded)
            return 1
        } else if LatinFold.isDropped(scalar) {
            return 0
        } else if let plain = LatinFold.base(scalar) {
            // Always an ASCII letter; lowercase it the way the ASCII branch does.
            let byte = plain.value
            out.append((0x41...0x5A).contains(byte) ? Unicode.Scalar(byte + 32)! : plain)
            return 1
        } else {
            // CJK, emoji, symbols: the rare tail. One scalar can lowercase to several.
            var added = 0
            for lowered in String(scalar).lowercased().unicodeScalars {
                out.append(CharacterSet.alphanumerics.contains(lowered) ? lowered : " ")
                added += 1
            }
            return added
        }
    }

    /// The search fold's Arabic rule for one scalar: nil when the scalar is not one it touches, 0 to
    /// drop it, otherwise the scalar it becomes. The same letters the hadith search folds
    /// (`HadeethEncStore.foldArabic`), except that the dagger alif and the small waw and yaa DROP
    /// instead of becoming letters, so the mushaf's ذَٰلِكَ and بِهِۦ meet the ذلك and به people type,
    /// and the Arabic-Indic digits read as digits ("٢:٢٥٥" is "2:255").
    @inline(__always)
    static func arabicSearchScalar(_ value: UInt32) -> UInt32? {
        guard (0x0600...0x08FF).contains(value) else { return nil }
        switch value {
        // Harakat and tanween, the Quranic annotation signs and small letters, the dagger alif, the
        // tatweel, the bare hamza, and the Extended-A marks (the mushaf's open tanween).
        case 0x064B...0x065F, 0x0670, 0x06D6...0x06ED, 0x0640, 0x0621, 0x0674, 0x08D3...0x08FF:
            return 0
        case 0x0622, 0x0623, 0x0625, 0x0671, 0x0672, 0x0673, 0x0675, 0x0649:
            return 0x0627    // آ أ إ ٱ ... ى -> ا
        case 0x0624, 0x0676, 0x0677:
            return 0x0648    // ؤ -> و
        case 0x0626, 0x0678, 0x06CC:
            return 0x064A    // ئ and the Persian yaa -> ي
        case 0x06A9:
            return 0x0643    // the Persian kaf -> ك
        case 0x0629:
            return 0x0647    // ة -> ه
        case 0x0660...0x0669:
            return value - 0x0660 + 0x30
        case 0x06F0...0x06F9:
            return value - 0x06F0 + 0x30
        default:
            return nil
        }
    }

    // MARK: Loading

    private struct Pack: Decodable {
        struct Article: Decodable {
            struct Section: Decodable { let heading: String; let text: String; let arabic: String?; let only: String? }
            let id: String
            let title: String
            let sections: [Section]
        }
        let version: Int
        let articles: [Article]
    }

    private static func load() -> [IslamArticle] {
        guard let url = Bundle.main.url(forResource: "IslamArticles", withExtension: "json.deflate", subdirectory: "Data/Islam")
                ?? Bundle.main.url(forResource: "IslamArticles", withExtension: "json.deflate", subdirectory: "Islam")
                ?? Bundle.main.url(forResource: "IslamArticles", withExtension: "json.deflate"),
              let compressed = try? Data(contentsOf: url),
              let json = inflate(compressed),
              let pack = try? JSONDecoder().decode(Pack.self, from: json) else { return [] }
        return pack.articles.map { article in
            IslamArticle(id: article.id, title: article.title,
                         sections: article.sections.map { section in
                             var built = IslamArticle.Section(heading: section.heading, text: section.text, folded: fold(section.text))
                             built.only = section.only.flatMap(ArticleLength.init(rawValue:))
                             if let arabic = section.arabic, !arabic.isEmpty {
                                 built.arabic = arabic
                                 built.foldedArabic = foldedArabicLanes(arabic)
                             }
                             return built
                         },
                         foldedTitle: fold(article.title))
        }
    }

    /// `fold(arabic)`, plus the same text with the mushaf's dagger alif written as a full alif when that
    /// folds differently (see `Section.foldedArabic`).
    static func foldedArabicLanes(_ arabic: String) -> String {
        let plain = fold(arabic)
        guard arabic.unicodeScalars.contains(where: { $0.value == 0x0670 }) else { return plain }
        let alif = fold(arabic.replacingOccurrences(of: "\u{0670}", with: "\u{0627}"))
        return alif == plain ? plain : plain + "\n" + alif
    }

    /// Raw deflate (no zlib header), what build_islam_corpus.py writes. Streamed through
    /// `compression_stream` into a buffer that grows by the output actually produced (the pack is
    /// ~1 MB inflated), instead of a scratch allocation sized at 24x the input (Performance Guide,
    /// Phase 6 step 9). Shared with the Watch's hadith quotes pack (`HadithQuoteSource`), which is
    /// written the same way.
    static func inflate(_ data: Data) -> Data? {
        var stream = compression_stream(dst_ptr: UnsafeMutablePointer<UInt8>(bitPattern: 1)!, dst_size: 0,
                                        src_ptr: UnsafePointer<UInt8>(bitPattern: 1)!, src_size: 0, state: nil)
        guard compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB) == COMPRESSION_STATUS_OK else { return nil }
        defer { compression_stream_destroy(&stream) }

        let chunk = 256 << 10
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunk)
        defer { buffer.deallocate() }
        var out = Data()
        out.reserveCapacity(min(data.count * 4, 4 << 20))

        return data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Data? in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return nil }
            stream.src_ptr = base
            stream.src_size = data.count
            while true {
                stream.dst_ptr = buffer
                stream.dst_size = chunk
                let status = compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
                let produced = chunk - stream.dst_size
                if produced > 0 { out.append(buffer, count: produced) }
                switch status {
                case COMPRESSION_STATUS_OK: continue
                case COMPRESSION_STATUS_END: return out.isEmpty ? nil : out
                default: return nil
                }
            }
        }
    }
}

// MARK: - Pages built for the AI

extension IslamArticle {
    /// The id of a Tajweed Course lesson's page as the AI reads it ("TajweedLesson-sukoon").
    static let lessonPrefix = "TajweedLesson-"
    /// The id of a Hadith Encyclopedia page as the AI reads it ("HadeethEnc-5907").
    static let encyclopediaPrefix = "HadeethEnc-"

    /// A page the corpus does not carry, from its passages in order, each under its heading (empty
    /// for the opening one): what Summarize with AI and Ask AI read on a lesson or an explanation.
    /// Empty passages are left out.
    static func built(id: String, title: String, passages: [(heading: String, text: String)]) -> IslamArticle {
        let sections = passages.compactMap { passage -> Section? in
            let text = passage.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return Section(heading: passage.heading, text: text, folded: IslamArticles.fold(text))
        }
        return IslamArticle(id: id, title: title, sections: sections, foldedTitle: IslamArticles.fold(title))
    }

    /// One passage of a page as its own search bar reads it (`ArticleSearchChrome`'s `page`): the
    /// heading the page shows over it (empty for one with none), the anchor the page put where it
    /// begins (`articleAnchor`), and its words as the page shows them.
    struct PagePassage {
        let heading: String
        let anchor: String
        let text: String
    }

    /// A page as its search bar reads it, in the language it is shown in: a Tajweed Course lesson,
    /// a hadith's explanation. Each section lands on its anchor, and its heading is searched with its
    /// words. Empty passages are left out.
    static func searchable(id: String, title: String, passages: [PagePassage]) -> IslamArticle {
        let sections = passages.compactMap { passage -> Section? in
            let text = passage.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            // The heading is searched with the words under it: "mistakes" finds the Common Mistakes card.
            return Section(heading: passage.heading, text: text, folded: IslamArticles.fold(passage.heading + "\n" + text),
                           anchor: passage.anchor)
        }
        return IslamArticle(id: id, title: title, sections: sections, foldedTitle: IslamArticles.fold(title))
    }

    /// A translated page the corpus carries in English (a Tajweed Foundations page), as its search
    /// bar reads it in the reader's language: each heading and line through the string catalog, the
    /// way the page's own `String(localized:)` shows them. A line the catalog does not carry (a word
    /// card's parts, joined by the corpus builder) stays as the corpus has it. The headings are
    /// looked up without `localizedDisplay`'s digit pass, so each is exactly the page's anchor.
    ///
    /// The corpus writes the source's ’ as ' ("Qur'an"), and the catalog keys keep the source's, so a
    /// line with an apostrophe is looked up both ways: without it "The 4 Types of Sukoon Marks in the
    /// Qur’an" found no translation. A heading no table carries (English: the app ships no English
    /// table for most keys) takes the source's ’ back all the same, because the Tajweed pages write
    /// their headings with it and the heading must be the page's anchor.
    func translatedForSearch() -> IslamArticle {
        func translated(_ key: String, heading: Bool = false) -> String {
            let missing = "\u{0}"
            let curled = key.replacingOccurrences(of: "'", with: "\u{2019}")
            for candidate in (curled == key ? [key] : [key, curled]) {
                let value = Bundle.main.localizedString(forKey: candidate, value: missing, table: nil)
                if value != missing { return value }
            }
            return heading ? curled : key
        }
        let sections = sections.map { section -> Section in
            let text = section.text.components(separatedBy: "\n").map { translated($0) }.joined(separator: "\n")
            return Section(heading: section.heading.isEmpty ? "" : translated(section.heading, heading: true), text: text,
                           folded: IslamArticles.fold(text))
        }
        return IslamArticle(id: id, title: translated(title, heading: true), sections: sections, foldedTitle: IslamArticles.fold(title))
    }
}

// MARK: - Summarize

extension IslamArticle {
    /// The whole page as one text for "Summarize with AI" (`ArticleAskAI`, ViewExtensions.swift): every
    /// section under its heading, in the page's order. A page longer than `limit` keeps EVERY section,
    /// each cut to its share of the budget (at a sentence end where one is near), so the summary covers
    /// the whole page rather than its first few screens; `truncated` says it was cut.
    ///
    /// `keepArabic` false leaves the Arabic script out: Apple's on-device model refuses a prompt that
    /// carries much Arabic (`OnDeviceAsk.supportsArabic`), and a tajweed page is full of example words.
    /// The English around them stays, and says what each one shows.
    func summarySource(limit: Int, keepArabic: Bool = true) -> (text: String, truncated: Bool) {
        let parts: [(heading: String, text: String)] = sections.compactMap { section in
            let text = (keepArabic ? section.text : Self.withoutArabic(section.text))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : (section.heading, text)
        }
        func block(_ heading: String, _ text: String) -> String {
            heading.isEmpty ? text : heading + "\n" + text
        }
        let whole = parts.map { block($0.heading, $0.text) }.joined(separator: "\n\n")
        guard whole.count > limit else { return (whole, false) }

        // The headings and the blank lines between sections come off the top; the rest is shared out
        // by length, with a floor so a short section is never starved to nothing.
        let overhead = parts.reduce(0) { $0 + $1.heading.count + 3 }
        let budget = max(limit / 2, limit - overhead)
        let total = max(1, parts.reduce(0) { $0 + $1.text.count })
        let floor = min(160, budget / max(1, parts.count))
        var text = parts.map { part in
            block(part.heading, Self.clipped(part.text, to: max(floor, budget * part.text.count / total)))
        }.joined(separator: "\n\n")
        if text.count > limit { text = String(text.prefix(limit)) + "\u{2026}" }
        return (text, true)
    }

    /// `text` cut to about `length` characters: at the last sentence end in its second half, else at
    /// the last space, with an ellipsis.
    static func clipped(_ text: String, to length: Int) -> String {
        guard text.count > length, length > 0 else { return text }
        let head = String(text.prefix(length))
        let half = head.index(head.startIndex, offsetBy: length / 2)
        if let end = head[half...].lastIndex(where: { $0 == "." || $0 == "?" || $0 == "!" }) {
            return String(head[...end]) + " \u{2026}"
        }
        if let space = head.lastIndex(of: " ") {
            return String(head[..<space]) + "\u{2026}"
        }
        return head + "\u{2026}"
    }

    /// `text` with every run of Arabic script taken out, and the empty brackets and doubled spaces that
    /// leaves behind tidied away.
    static func withoutArabic(_ text: String) -> String {
        var out = text.replacingOccurrences(
            of: "[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF\\uFB50-\\uFDFF\\uFE70-\\uFEFF\\u200E\\u200F]+",
            with: "", options: .regularExpression)
        out = out.replacingOccurrences(of: "\\(\\s*[,/:;]?\\s*\\)", with: "", options: .regularExpression)
        out = out.replacingOccurrences(of: "[ \\t]{2,}", with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: " ([,.;:!?])", with: "$1", options: .regularExpression)
        return out
    }
}
