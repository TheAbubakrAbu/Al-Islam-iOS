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
        case "QuranPillarView": return AnyView(QuranPillarView())
        case "MuqattaatPillarView": return AnyView(MuqattaatPillarView())
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
        case "DayView": return AnyView(DayView())
        case "QadarView": return AnyView(QadarView())
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
        case "CompileView": return AnyView(CompileView())
        case "TajweedView": return AnyView(TajweedView())
        case "JuzView": return AnyView(JuzView())
        case "AhrufView": return AnyView(AhrufView())
        case "QiraatView": return AnyView(QiraatView())
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
        case "SahabahScholarsView": return AnyView(SahabahScholarsView())
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
        case "RawatibView": return AnyView(RawatibView())
        case "WitrView": return AnyView(WitrView())
        case "TahajjudView": return AnyView(TahajjudView())
        case "DuhaView": return AnyView(DuhaView())
        case "TaraweehView": return AnyView(TaraweehView())
        case "JanazahView": return AnyView(JanazahView())
        case "IstikharahView": return AnyView(IstikharahView())
        case "TravelPrayerView": return AnyView(TravelPrayerView())
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
    /// match "wudhu".
    static func fold(_ text: String) -> String {
        String(text.lowercased().unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        })
    }

    // MARK: Loading

    private struct Pack: Decodable {
        struct Article: Decodable {
            struct Section: Decodable { let heading: String; let text: String }
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
                         sections: article.sections.map { .init(heading: $0.heading, text: $0.text, folded: fold($0.text)) },
                         foldedTitle: fold(article.title))
        }
    }

    /// Raw deflate (no zlib header), what build_islam_corpus.py writes. Streamed through
    /// `compression_stream` into a buffer that grows by the output actually produced (the pack is
    /// ~1 MB inflated), instead of a scratch allocation sized at 24x the input (Performance Guide,
    /// Phase 6 step 9).
    private static func inflate(_ data: Data) -> Data? {
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
