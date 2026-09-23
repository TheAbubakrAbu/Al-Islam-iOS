import SwiftUI

// The tajweed course, which IS Tajweed Foundations: the curriculum Jamil Hammoudeh wrote for Tilawa
// (ported with his permission, see CreditsView) merged lesson by lesson with Al-Islam's own Tajweed
// Foundations pages (Abu, 2026-09-23: "go one by one and make it joint ... take the best of both
// worlds, I want all of both in one merged thing", in the course's design).
//
// One pack, TajweedLessons.json.xz, built by Scripts/build_tajweed_lessons.py from Tilawa's chapter
// files plus Scripts/tajweed_foundations.py (whose docstring maps every old Foundations topic to the
// lessons it went into), gated by Scripts/verify_tajweed_lessons.py.
//
// This file is the model, the store and the progress, compiled for the phone AND the watch.
// TajweedView.swift is the course's index (the Tajweed Foundations screen) on both;
// TajweedLessons.swift draws a lesson on the phone, and the watch draws a compact one.
//
// A lesson follows the classical four beats, one card each: the definition (what is it), the rule card
// (when: trigger, action, hold), the examples (where: real ayahs, playable) and the common mistakes
// (what learners get wrong). Letter sets, a comparison table, key points, drills, a self-check quiz and
// related lessons appear on the lessons that earn them, and so do the Foundations additions: word lists
// with their readings, videos, the makharij diagrams, the alphabet's letter families, doors into the
// app's articles, and the colour the reader paints the rule in.

// MARK: - Model

/// Quran words a lesson row shows: an ayah and a 0-based inclusive token range of this app's own
/// Hafs text. The pack stores no copy of the words (nothing the app ships carries an ayah), so the
/// row reads them out of the ayah at render time and they can never drift from the mushaf text.
struct TajweedAyahWords {
    let surahId: Int
    let ayahNumber: Int
    let span: ClosedRange<Int>

    /// A key for row ids: the same whether or not the Quran is loaded.
    var key: String { "\(surahId):\(ayahNumber):\(span.lowerBound)-\(span.upperBound)" }

    /// The pack's `[surah, ayahNumber, first, last]`.
    init?(pack raw: Any?) {
        guard let row = raw as? [Int], row.count == 4, row[2] >= 0, row[2] <= row[3] else { return nil }
        surahId = row[0]
        ayahNumber = row[1]
        span = row[2]...row[3]
    }

    /// The words at `span`, read out of the ayah's own text.
    func words(in ayahText: String) -> String { Self.cut(span, from: ayahText) }

    /// The words, read from the loaded Quran (the ayah's Hafs display text, the text the example
    /// rows show); empty until the Quran has loaded.
    func words(in quran: QuranData) -> String {
        guard let surah = quran.surah(surahId),
              let ayah = surah.ayahs.first(where: { $0.id == ayahNumber }) else { return "" }
        return words(in: ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: ""))
    }

    /// The tokens of `ayahText` at `span`, joined; empty when the span falls outside the text. A token
    /// is a run of non-whitespace, `WordTokens.tokens` (phone-only) spelled out so the watch cuts the
    /// same words.
    static func cut(_ span: ClosedRange<Int>, from ayahText: String) -> String {
        let tokens = ayahText.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard span.lowerBound >= 0, span.upperBound < tokens.count else { return "" }
        return tokens[span].joined(separator: " ")
    }
}

struct TajweedLessonExample: Identifiable {
    let surahId: Int
    let ayahNumber: Int
    /// The words inside the ayah the lesson points at, as a 0-based inclusive token range of
    /// this app's own Hafs text (the pack stores no copy of the words); nil when the lesson
    /// names the whole ayah.
    let wordSpan: ClosedRange<Int>?
    /// What to listen for in this ayah.
    let focus: String

    var id: String {
        "\(surahId):\(ayahNumber):" + (wordSpan.map { "\($0.lowerBound)-\($0.upperBound)" } ?? "")
    }

    /// The words at `wordSpan`, read out of the ayah's own text.
    func words(in ayahText: String) -> String {
        guard let wordSpan else { return "" }
        return TajweedAyahWords.cut(wordSpan, from: ayahText)
    }
}

struct TajweedLessonDrill: Identifiable {
    /// A short isolated snippet (letter row, syllable, word) when the drill is Tilawa's own practice
    /// text; empty when the drill is Quran, which `ayah` locates instead.
    let text: String
    /// The ayah words when the drill is Quran text, read from the app's text at render time.
    let ayah: TajweedAyahWords?
    let caption: String
    /// Latin reading, for a learner who cannot yet read the script.
    let translit: String

    var id: String { (ayah?.key ?? text) + caption }

    /// The Arabic to show: the practice text, or the ayah's words from the loaded Quran.
    func arabic(in quran: QuranData) -> String { ayah?.words(in: quran) ?? text }
}

struct TajweedLessonFragment: Identifiable {
    /// The fragment as written when it is teaching Arabic; empty when `ayah` locates it.
    let text: String
    let ayah: TajweedAyahWords?
    let caption: String

    var id: String { (ayah?.key ?? text) + caption }

    /// The Arabic to show: the fragment as written, or the ayah's words from the loaded Quran.
    func arabic(in quran: QuranData) -> String { ayah?.words(in: quran) ?? text }
}

struct TajweedLessonDefinition {
    let termAr: String
    let literal: String
    let technical: String
}

struct TajweedLessonRuleCard {
    let trigger: String
    let action: String
    let hold: String
    let countEn: String
    let countAr: String
    let mnemonicArabic: String
    let mnemonicGloss: String
    let fragments: [TajweedLessonFragment]
}

struct TajweedLessonLetterSet: Identifiable {
    let label: String
    let letters: [String]
    let note: String
    let emphasis: Bool

    var id: String { label }

    /// Whole words rather than single letters (the munfasil hukmi list): drawn as wide text tiles
    /// instead of the alphabet's letter tiles, and not tappable.
    var isWords: Bool { letters.contains { $0.count > 2 } }
}

struct TajweedLessonMistake: Identifiable {
    let wrong: String
    let right: String
    let why: String

    var id: String { wrong }
}

struct TajweedLessonTable {
    let title: String
    let columns: [String]
    let rows: [[String]]
    let arabicFirstColumn: Bool
}

struct TajweedQuizQuestion: Identifiable {
    let prompt: String
    /// The Arabic the question is about, as written when it is teaching Arabic; empty when `ayah`
    /// locates it (a question about a real ayah shows the app's own text).
    let arabic: String
    let ayah: TajweedAyahWords?
    let choices: [String]
    let answer: Int
    let explain: String

    var id: String { prompt }

    /// The Arabic to show: as written, or the ayah's words from the loaded Quran.
    func arabic(in quran: QuranData) -> String { ayah?.words(in: quran) ?? arabic }
}

/// One word of a Foundations word list: the Arabic (as written, or located in an ayah when the words
/// are Quran found in exactly one place), its reading, and an optional note ("heavy, after ق").
struct TajweedLessonWord: Identifiable {
    let text: String
    let ayah: TajweedAyahWords?
    let translit: String
    let note: String

    var id: String { (ayah?.key ?? text) + translit }

    func arabic(in quran: QuranData) -> String { ayah?.words(in: quran) ?? text }
}

/// A labelled group of words ("Moon letters: the lam is read").
struct TajweedLessonWordGroup: Identifiable {
    let label: String
    let note: String
    let items: [TajweedLessonWord]

    var id: String { label }
}

struct TajweedLessonVideo: Identifiable {
    let title: String
    let url: URL
    /// Who made it ("Arabic 101"), for the row's caption.
    let channel: String

    var id: String { url.absoluteString }
}

/// An image from the asset catalog (the makharij diagrams), with its caption.
struct TajweedLessonImage: Identifiable {
    let name: String
    let caption: String

    var id: String { name }
}

/// A screen of the app a lesson opens (the pack's `doors`, Scripts/tajweed_foundations.py `DOORS`).
enum TajweedLessonDoor: String, CaseIterable, Identifiable {
    case quranArticle
    case tajweedArticle
    case ahrufArticle
    case qiraatArticle
    case letterFamilies
    case soundAlikes
    case makharijShelf
    case sifaatShelf
    case tajweedLegend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quranArticle: return "What is the Quran?"
        case .tajweedArticle: return "What is Tajweed?"
        case .ahrufArticle: return "What are the 7 Ahruf?"
        case .qiraatArticle: return "What are the 10 Qiraat?"
        case .letterFamilies: return "Letter Families"
        case .soundAlikes: return "Sound-Alike Letters"
        case .makharijShelf: return "The Seventeen Exits on the Alphabet"
        case .sifaatShelf: return "Sifaat on the Alphabet"
        case .tajweedLegend: return "Tajweed Legend"
        }
    }

    var caption: String {
        switch self {
        case .quranArticle: return "Its revelation, preservation and names"
        case .tajweedArticle: return "The article, with its sources"
        case .ahrufArticle: return "The seven modes the Quran was revealed in"
        case .qiraatArticle: return "The ten readings and their riwayat"
        case .letterFamilies: return "Every letter by makhraj, sifaat and rule"
        case .soundAlikes: return "The pairs people mix up, side by side"
        case .makharijShelf: return "Every exit, with the letters made there"
        case .sifaatShelf: return "Every quality, named in Arabic and English"
        case .tajweedLegend: return "The reader's colors, rule by rule"
        }
    }

    var systemImage: String {
        switch self {
        case .quranArticle: return "book.closed"
        case .tajweedArticle: return "doc.text"
        case .ahrufArticle: return "7.circle"
        case .qiraatArticle: return "10.circle"
        case .letterFamilies: return "square.grid.3x3"
        case .soundAlikes: return "ear"
        case .makharijShelf: return "mouth"
        case .sifaatShelf: return "waveform"
        case .tajweedLegend: return "paintpalette"
        }
    }
}

/// A native block drawn inside a lesson (the pack's `extras`).
enum TajweedLessonExtra: String {
    /// The mushaf's stop signs, the grid the old Waqf page drew.
    case waqfSigns
}

struct TajweedLesson: Identifiable {
    let id: String
    let titleEn: String
    let titleAr: String
    let translit: String
    let minutes: Int
    let summary: String
    let definition: TajweedLessonDefinition?
    let ruleCard: TajweedLessonRuleCard?
    let body: [String]
    let keyPoints: [String]
    let letterSets: [TajweedLessonLetterSet]
    let table: TajweedLessonTable?
    let mistakes: [TajweedLessonMistake]
    let examples: [TajweedLessonExample]
    let drills: [TajweedLessonDrill]
    let quiz: [TajweedQuizQuestion]
    /// The ground-truth rule this lesson teaches, when it teaches one ("ikhfa", "qalqalah").
    let ruleCode: String?
    /// Other lesson ids worth reading next.
    let related: [String]
    /// The Foundations word lists: Arabic words with their readings.
    let words: [TajweedLessonWordGroup]
    let videos: [TajweedLessonVideo]
    let images: [TajweedLessonImage]
    /// LetterTraits family ids the lesson shows on top of the families whose own lesson it is.
    let familyIDs: [String]
    let doors: [TajweedLessonDoor]
    let extras: [TajweedLessonExtra]
    /// The reader's colour for the rule this lesson teaches: the lesson wears it (Tilawa's design).
    let legend: TajweedLegendCategory?

    /// The alphabet's families for this lesson: the ones it names, then every family whose own lesson
    /// it is, each once.
    var families: [LetterFamily] {
        var seen = Set<String>()
        var out: [LetterFamily] = []
        for id in familyIDs {
            if let family = LetterTraits.allFamilies.first(where: { $0.id == id }), seen.insert(id).inserted {
                out.append(family)
            }
        }
        for family in LetterTraits.allFamilies where family.lessonID == id && seen.insert(family.id).inserted {
            out.append(family)
        }
        return out
    }

    /// The colour the lesson is drawn in: the rule's colour where the reader paints it in one (the
    /// grey of the silent letters reads as switched off, so those keep the app's accent).
    func accent(fallback: Color) -> Color {
        guard let legend else { return fallback }
        switch legend {
        case .lamShamsiyah, .droppedLetter, .hamzatWaslSilent, .idghamBilaGhunnah: return fallback
        default: return legend.color
        }
    }
}

struct TajweedLessonChapter: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let stage: String
    let lessons: [TajweedLesson]
}

struct TajweedCourseStage: Identifiable {
    let id: String
    let titleEn: String
    let titleAr: String
    let blurb: String
}

// MARK: - Store

final class TajweedLessonsStore: @unchecked Sendable {
    static let shared = TajweedLessonsStore()
    private init() {}

    struct Course {
        let stages: [TajweedCourseStage]
        let chapters: [TajweedLessonChapter]
        /// Rule code -> (ayahs, words) across the corpus.
        let ruleCounts: [String: (ayahs: Int, words: Int)]

        /// Every lesson, in course order.
        var lessons: [TajweedLesson] { chapters.flatMap(\.lessons) }
        var totalMinutes: Int { lessons.reduce(0) { $0 + $1.minutes } }
    }

    private let lock = NSLock()
    private var cached: Course?
    private var loadFailed = false
    /// Every lesson by id, built with the course: `lesson(id:)` scanned every chapter per call.
    private var byID: [String: TajweedLesson] = [:]
    /// Each lesson's place in the course (0-based) and the chapter that holds it.
    private var positions: [String: Int] = [:]
    private var chapterByLesson: [String: TajweedLessonChapter] = [:]
    private var ordered: [TajweedLesson] = []

    static let isBundled: Bool = packURL() != nil

    /// The course, parsed on the calling thread if nothing has (a 500 KB parse): screens ask from a
    /// detached task, so a body never pays for it.
    func course() -> Course? {
        lock.lock()
        if let cached { lock.unlock(); return cached }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()

        let parsed = Self.load()
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }
        if let parsed {
            cached = parsed
            ordered = parsed.lessons
            byID = Dictionary(ordered.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            positions = Dictionary(ordered.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
            for chapter in parsed.chapters {
                for lesson in chapter.lessons where chapterByLesson[lesson.id] == nil {
                    chapterByLesson[lesson.id] = chapter
                }
            }
            return parsed
        }
        loadFailed = true
        return nil
    }

    /// The course if it is already parsed, else nil: for bodies.
    var courseIfLoaded: Course? {
        lock.lock(); defer { lock.unlock() }
        return cached
    }

    func chapters() -> [TajweedLessonChapter] { course()?.chapters ?? [] }

    func lesson(id: String) -> TajweedLesson? {
        guard course() != nil else { return nil }
        lock.lock(); defer { lock.unlock() }
        return byID[id]
    }

    /// Every lesson in course order, for prev/next.
    func allLessons() -> [TajweedLesson] {
        guard course() != nil else { return [] }
        lock.lock(); defer { lock.unlock() }
        return ordered
    }

    /// "Lesson n of N": the lesson's 1-based place in the whole course, and the course's length.
    func position(of id: String) -> (number: Int, total: Int)? {
        guard course() != nil else { return nil }
        lock.lock(); defer { lock.unlock() }
        guard let index = positions[id] else { return nil }
        return (index + 1, ordered.count)
    }

    /// The lessons either side of this one, in course order.
    func neighbors(of id: String) -> (previous: TajweedLesson?, next: TajweedLesson?) {
        guard course() != nil else { return (nil, nil) }
        lock.lock(); defer { lock.unlock() }
        guard let index = positions[id] else { return (nil, nil) }
        return (index > 0 ? ordered[index - 1] : nil, index + 1 < ordered.count ? ordered[index + 1] : nil)
    }

    /// The chapter a lesson sits in.
    func chapter(of id: String) -> TajweedLessonChapter? {
        guard course() != nil else { return nil }
        lock.lock(); defer { lock.unlock() }
        return chapterByLesson[id]
    }

    private static func packURL() -> URL? {
        Bundle.main.url(forResource: "TajweedLessons", withExtension: "json.xz", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "TajweedLessons", withExtension: "json.xz", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "TajweedLessons", withExtension: "json.xz")
    }

    private static func strings(_ raw: Any?) -> [String] {
        (raw as? [String]) ?? []
    }

    private static func load() -> Course? {
        PackTrace.measure("TajweedLessons") { () -> (result: Course?, bytes: Int) in
            guard let url = packURL(),
                  let blob = try? Data(contentsOf: url),
                  let json = SolidPack.xzDecompress(blob) else { return (nil, 0) }
            return (parse(json), json.count)
        }
    }

    /// The pack version this parser reads. Version 5 is the course merged with Tajweed Foundations
    /// (words, videos, images, families, doors, extras, legend on top of version 4's references).
    /// A pack built for another version is refused rather than half-read (the Reminder of the Day
    /// went blank once when a builder moved on and a parser did not).
    static let packVersion = 5

    private static func parse(_ json: Data) -> Course? {
        guard let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
              root["version"] as? Int == packVersion,
              let rows = root["chapters"] as? [[String: Any]] else { return nil }

        let stages = (root["stages"] as? [[String: Any]] ?? []).compactMap { row -> TajweedCourseStage? in
            guard let id = row["id"] as? String else { return nil }
            return TajweedCourseStage(id: id, titleEn: row["titleEn"] as? String ?? id.capitalized,
                                      titleAr: row["titleAr"] as? String ?? "", blurb: row["blurb"] as? String ?? "")
        }
        var ruleCounts: [String: (ayahs: Int, words: Int)] = [:]
        for (code, value) in root["ruleCounts"] as? [String: [String: Any]] ?? [:] {
            ruleCounts[code] = (value["ayahs"] as? Int ?? 0, value["words"] as? Int ?? 0)
        }

        let chapters = rows.compactMap { chapter -> TajweedLessonChapter? in
            guard let id = chapter["id"] as? String,
                  let title = chapter["title"] as? String,
                  let lessonRows = chapter["lessons"] as? [[String: Any]] else { return nil }
            let lessons = lessonRows.compactMap(parseLesson)
            guard !lessons.isEmpty else { return nil }
            return TajweedLessonChapter(id: id, title: title,
                                        subtitle: chapter["subtitle"] as? String ?? "",
                                        stage: chapter["stage"] as? String ?? "",
                                        lessons: lessons)
        }
        guard !chapters.isEmpty else { return nil }
        return Course(stages: stages, chapters: chapters, ruleCounts: ruleCounts)
    }

    private static func parseLesson(_ lesson: [String: Any]) -> TajweedLesson? {
        guard let lid = lesson["id"] as? String,
              let titleEn = lesson["titleEn"] as? String,
              let body = lesson["body"] as? [String], !body.isEmpty else { return nil }
        let examples = (lesson["examples"] as? [[String: Any]] ?? []).compactMap { example -> TajweedLessonExample? in
            guard let surah = example["surahId"] as? Int,
                  let ayah = example["ayahNumber"] as? Int else { return nil }
            let span = (example["wordSpan"] as? [Int]).flatMap { pair -> ClosedRange<Int>? in
                guard pair.count == 2, pair[0] <= pair[1] else { return nil }
                return pair[0]...pair[1]
            }
            return TajweedLessonExample(surahId: surah, ayahNumber: ayah, wordSpan: span,
                                        focus: example["focus"] as? String ?? "")
        }
        let drills = (lesson["drills"] as? [[String: Any]] ?? []).compactMap { drill -> TajweedLessonDrill? in
            let ayah = TajweedAyahWords(pack: drill["ayah"])
            guard ayah != nil || drill["text"] is String else { return nil }
            return TajweedLessonDrill(text: drill["text"] as? String ?? "", ayah: ayah,
                                      caption: drill["caption"] as? String ?? "",
                                      translit: drill["translit"] as? String ?? "")
        }
        var definition: TajweedLessonDefinition?
        if let raw = lesson["definition"] as? [String: Any], let term = raw["termAr"] as? String {
            definition = TajweedLessonDefinition(termAr: term, literal: raw["literal"] as? String ?? "",
                                                 technical: raw["technical"] as? String ?? "")
        }
        var ruleCard: TajweedLessonRuleCard?
        if let raw = lesson["ruleCard"] as? [String: Any] {
            let fragments = (raw["fragments"] as? [[String: Any]] ?? []).compactMap { fragment -> TajweedLessonFragment? in
                let ayah = TajweedAyahWords(pack: fragment["ayah"])
                guard ayah != nil || fragment["text"] is String else { return nil }
                return TajweedLessonFragment(text: fragment["text"] as? String ?? "", ayah: ayah,
                                             caption: fragment["caption"] as? String ?? "")
            }
            let mnemonic = raw["mnemonic"] as? [String: Any]
            ruleCard = TajweedLessonRuleCard(
                trigger: raw["trigger"] as? String ?? "", action: raw["action"] as? String ?? "",
                hold: raw["hold"] as? String ?? "", countEn: raw["countEn"] as? String ?? "",
                countAr: raw["countAr"] as? String ?? "",
                mnemonicArabic: mnemonic?["arabic"] as? String ?? "",
                mnemonicGloss: mnemonic?["gloss"] as? String ?? "",
                fragments: fragments)
        }
        let letterSets = (lesson["letterSets"] as? [[String: Any]] ?? []).compactMap { set -> TajweedLessonLetterSet? in
            guard let label = set["label"] as? String, let letters = set["letters"] as? [String] else { return nil }
            return TajweedLessonLetterSet(label: label, letters: letters, note: set["note"] as? String ?? "",
                                          emphasis: set["emphasis"] as? Bool ?? false)
        }
        var table: TajweedLessonTable?
        if let raw = lesson["table"] as? [String: Any], let columns = raw["columns"] as? [String],
           let tableRows = raw["rows"] as? [[String]] {
            table = TajweedLessonTable(title: raw["title"] as? String ?? "", columns: columns, rows: tableRows,
                                       arabicFirstColumn: raw["arabicFirstColumn"] as? Bool ?? false)
        }
        let mistakes = (lesson["mistakes"] as? [[String: Any]] ?? []).compactMap { row -> TajweedLessonMistake? in
            guard let wrong = row["wrong"] as? String, let right = row["right"] as? String else { return nil }
            return TajweedLessonMistake(wrong: wrong, right: right, why: row["why"] as? String ?? "")
        }
        let quiz = (lesson["quiz"] as? [[String: Any]] ?? []).compactMap { row -> TajweedQuizQuestion? in
            guard let prompt = row["prompt"] as? String, let choices = row["choices"] as? [String],
                  let answer = row["answer"] as? Int, choices.indices.contains(answer) else { return nil }
            return TajweedQuizQuestion(prompt: prompt, arabic: row["arabic"] as? String ?? "",
                                       ayah: TajweedAyahWords(pack: row["ayah"]),
                                       choices: choices, answer: answer, explain: row["explain"] as? String ?? "")
        }
        let words = (lesson["words"] as? [[String: Any]] ?? []).compactMap { group -> TajweedLessonWordGroup? in
            guard let label = group["label"] as? String else { return nil }
            let items = (group["items"] as? [[String: Any]] ?? []).compactMap { item -> TajweedLessonWord? in
                let ayah = TajweedAyahWords(pack: item["ayah"])
                guard ayah != nil || item["text"] is String else { return nil }
                return TajweedLessonWord(text: item["text"] as? String ?? "", ayah: ayah,
                                         translit: item["translit"] as? String ?? "",
                                         note: item["note"] as? String ?? "")
            }
            guard !items.isEmpty else { return nil }
            return TajweedLessonWordGroup(label: label, note: group["note"] as? String ?? "", items: items)
        }
        let videos = (lesson["videos"] as? [[String: Any]] ?? []).compactMap { row -> TajweedLessonVideo? in
            guard let title = row["title"] as? String, let raw = row["url"] as? String,
                  let url = URL(string: raw) else { return nil }
            return TajweedLessonVideo(title: title, url: url, channel: row["channel"] as? String ?? "")
        }
        let images = (lesson["images"] as? [[String: Any]] ?? []).compactMap { row -> TajweedLessonImage? in
            guard let name = row["name"] as? String else { return nil }
            return TajweedLessonImage(name: name, caption: row["caption"] as? String ?? "")
        }
        return TajweedLesson(id: lid, titleEn: titleEn,
                             titleAr: lesson["titleAr"] as? String ?? "",
                             translit: lesson["translit"] as? String ?? "",
                             minutes: lesson["minutes"] as? Int ?? 0,
                             summary: lesson["summary"] as? String ?? "",
                             definition: definition, ruleCard: ruleCard,
                             body: body, keyPoints: strings(lesson["keyPoints"]),
                             letterSets: letterSets, table: table, mistakes: mistakes,
                             examples: examples, drills: drills, quiz: quiz,
                             ruleCode: lesson["ruleCode"] as? String,
                             related: strings(lesson["related"]),
                             words: words, videos: videos, images: images,
                             familyIDs: strings(lesson["families"]),
                             doors: strings(lesson["doors"]).compactMap(TajweedLessonDoor.init(rawValue:)),
                             extras: strings(lesson["extras"]).compactMap(TajweedLessonExtra.init(rawValue:)),
                             legend: (lesson["legend"] as? String).flatMap(TajweedLegendCategory.init(rawValue:)))
    }
}

/// Which lessons the reader has marked as done. Small, in UserDefaults (and in the iCloud backup).
final class TajweedLessonProgress: ObservableObject {
    static let shared = TajweedLessonProgress()
    private static let key = "tajweedLessonsDone"

    @Published private(set) var done: Set<String>

    private var storageObserver: StoredContentObserver?

    private init() {
        done = Set(UserDefaults.standard.stringArray(forKey: Self.key) ?? [])
        ObjectPublishCounter.attach(self, label: "TajweedLessonProgress")
        storageObserver = StoredContentObserver(reload: {
            let stored = Set(UserDefaults.standard.stringArray(forKey: TajweedLessonProgress.key) ?? [])
            if stored != TajweedLessonProgress.shared.done { TajweedLessonProgress.shared.done = stored }
        })
    }

    func isDone(_ id: String) -> Bool { done.contains(id) }

    func toggle(_ id: String) {
        if done.contains(id) { done.remove(id) } else { done.insert(id) }
        UserDefaults.standard.set(Array(done).sorted(), forKey: Self.key)
    }
}

// MARK: - Opening a lesson by id

/// A lesson opened from outside the course (a letter's page, a letter family, a rule's link): the pack
/// is parsed off the main thread (it is 500 KB), so the page shows a spinner for the moment that takes
/// on a cold open. The phone draws the full lesson, the watch its compact one.
struct TajweedLessonScreen: View {
    let lessonID: String

    @State private var lesson: TajweedLesson?
    @State private var missing = false

    var body: some View {
        Group {
            if let lesson {
                #if os(iOS)
                TajweedLessonDetailView(lesson: lesson)
                #else
                TajweedLessonWatchView(lesson: lesson)
                #endif
            } else if missing {
                Text("This lesson could not be loaded.")
                    .foregroundColor(.secondary)
            } else {
                ProgressView()
            }
        }
        .task {
            guard lesson == nil else { return }
            let id = lessonID
            let found = await Task.detached(priority: .userInitiated) {
                TajweedLessonsStore.shared.lesson(id: id)
            }.value
            lesson = found
            missing = found == nil
        }
    }
}

/// A row that opens one lesson of the course, or sits greyed out when that lesson is already open
/// further up the stack (a lesson's letter tiles open letter pages, and a letter's page links back to
/// the lesson that explains its rule: without this the pair is a corridor).
struct TajweedLessonLink<Label: View>: View {
    let lessonID: String
    @ViewBuilder let label: () -> Label

    var body: some View {
        GuardedScreenLink(screen: .tajweedLesson, id: lessonID, alreadyHere: "You came here from this lesson") {
            TajweedLessonScreen(lessonID: lessonID)
        } label: {
            label()
        }
    }
}
