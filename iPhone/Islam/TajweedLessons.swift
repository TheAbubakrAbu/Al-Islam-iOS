#if os(iOS)
import SwiftUI

// Structured tajweed lessons - a guided course from reading foundations (Qaida Noorania
// style) through makharij, sifat, and the classical rules, with curated Quranic examples
// you can hear in place.
//
// The curriculum was written by Jamil Hammoudeh for Tilawa and is ported with his
// permission (see CreditsView). Content ships as TajweedLessons.json.xz, built by
// Scripts/build_tajweed_lessons.py straight from Tilawa's chapter files and gated by
// Scripts/verify_tajweed_lessons.py - a content fix there is a rebuild away here.
//
// A lesson follows the classical four beats, one card each: the definition (what is it),
// the rule card (when: trigger, action, hold), the examples (where: real ayahs, playable)
// and the common mistakes (what learners get wrong). Letter sets, a comparison table, key
// points, drills, a self-check quiz and related lessons appear on the lessons that earn them.

// MARK: - Model

struct TajweedLessonExample: Identifiable {
    let surahId: Int
    let ayahNumber: Int
    /// The exact span inside the ayah the lesson points at (KFGQPC spelling).
    let word: String
    /// What to listen for in this ayah.
    let focus: String

    var id: String { "\(surahId):\(ayahNumber):\(word)" }
}

struct TajweedLessonDrill: Identifiable {
    /// A short isolated snippet (letter row, word, phrase) - practice text, not an ayah.
    let text: String
    let caption: String
    /// Latin reading, for a learner who cannot yet read the script.
    let translit: String

    var id: String { text + caption }
}

struct TajweedLessonFragment: Identifiable {
    let text: String
    let caption: String

    var id: String { text + caption }
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
    let arabic: String
    let choices: [String]
    let answer: Int
    let explain: String

    var id: String { prompt }
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
    }

    private let lock = NSLock()
    private var cached: Course?
    private var loadFailed = false
    /// Every lesson by id, built with the course: `lesson(id:)` scanned every chapter per call.
    private var byID: [String: TajweedLesson] = [:]

    static let isBundled: Bool = packURL() != nil

    /// The course, parsed on the calling thread if nothing has (a 467 KB parse): the index screen
    /// asks from a detached task, so a body never pays for it.
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
            byID = Dictionary(parsed.chapters.flatMap(\.lessons).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
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
    func allLessons() -> [TajweedLesson] { chapters().flatMap(\.lessons) }

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

    private static func parse(_ json: Data) -> Course? {
        guard let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
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
            let lessons = lessonRows.compactMap { lesson -> TajweedLesson? in
                guard let lid = lesson["id"] as? String,
                      let titleEn = lesson["titleEn"] as? String,
                      let body = lesson["body"] as? [String], !body.isEmpty else { return nil }
                let examples = (lesson["examples"] as? [[String: Any]] ?? []).compactMap { example -> TajweedLessonExample? in
                    guard let surah = example["surahId"] as? Int,
                          let ayah = example["ayahNumber"] as? Int else { return nil }
                    return TajweedLessonExample(surahId: surah, ayahNumber: ayah,
                                                word: example["word"] as? String ?? "",
                                                focus: example["focus"] as? String ?? "")
                }
                let drills = (lesson["drills"] as? [[String: Any]] ?? []).compactMap { drill -> TajweedLessonDrill? in
                    guard let text = drill["text"] as? String else { return nil }
                    return TajweedLessonDrill(text: text, caption: drill["caption"] as? String ?? "",
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
                        guard let text = fragment["text"] as? String else { return nil }
                        return TajweedLessonFragment(text: text, caption: fragment["caption"] as? String ?? "")
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
                                               choices: choices, answer: answer, explain: row["explain"] as? String ?? "")
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
                                     related: strings(lesson["related"]))
            }
            guard !lessons.isEmpty else { return nil }
            return TajweedLessonChapter(id: id, title: title,
                                        subtitle: chapter["subtitle"] as? String ?? "",
                                        stage: chapter["stage"] as? String ?? "",
                                        lessons: lessons)
        }
        guard !chapters.isEmpty else { return nil }
        return Course(stages: stages, chapters: chapters, ruleCounts: ruleCounts)
    }
}

/// Which lessons the reader has marked as done. Small, in UserDefaults.
final class TajweedLessonProgress: ObservableObject {
    static let shared = TajweedLessonProgress()
    private static let key = "tajweedLessonsDone"

    @Published private(set) var done: Set<String>

    private init() {
        done = Set(UserDefaults.standard.stringArray(forKey: Self.key) ?? [])
        ObjectPublishCounter.attach(self, label: "TajweedLessonProgress")
    }

    func isDone(_ id: String) -> Bool { done.contains(id) }

    func toggle(_ id: String) {
        if done.contains(id) { done.remove(id) } else { done.insert(id) }
        UserDefaults.standard.set(Array(done).sorted(), forKey: Self.key)
    }
}

// MARK: - Course index

struct TajweedLessonsView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = TajweedLessonProgress.shared

    #if DEBUG
    /// `-openTajweedLesson <id>`: the lesson pushed as the index appears, for screenshots.
    @State private var debugOpenLesson = false
    private static var debugLessonID: String? {
        guard let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-openTajweedLesson"),
              ProcessInfo.processInfo.arguments.indices.contains(idx + 1) else { return nil }
        return ProcessInfo.processInfo.arguments[idx + 1]
    }
    #endif

    private var accent: Color { appearance.accent }

    /// The course, parsed off the main thread in the task below (the body used to parse the 467 KB
    /// pack on first open); a spinner section stands in until it lands.
    @State private var course: TajweedLessonsStore.Course? = TajweedLessonsStore.shared.courseIfLoaded

    var body: some View {
        let _ = RenderCounter.hit("TajweedLessonsView")
        let chapters = course?.chapters ?? []
        let all = chapters.flatMap(\.lessons)
        let doneCount = all.filter { progress.isDone($0.id) }.count
        let minutes = all.reduce(0) { $0 + $1.minutes }

        List {
            Group {
                if course == nil, TajweedLessonsStore.isBundled {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            AccentIconChip(systemImage: "graduationcap.fill", size: 34)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("A course in four steps")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(all.count) lessons, about \(minutes) minutes in all, from reading the letters to reading the mushaf. Each lesson defines its term, states the rule, shows it in real ayahs you can play, and ends with a self-check.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if doneCount > 0 {
                            ProgressView(value: Double(doneCount), total: Double(max(1, all.count)))
                                .tint(accent)
                            Text("\(doneCount) of \(all.count) lessons done")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(accent)
                        }
                    }
                    .padding(.vertical, 4)
                }

                ForEach(course?.stages ?? []) { stage in
                    let stageChapters = chapters.filter { $0.stage == stage.id }
                    if !stageChapters.isEmpty {
                        Section(header: stageHeader(stage)) {
                            ForEach(stageChapters) { chapter in
                                chapterRows(chapter)
                            }
                        }
                    }
                }

                // Chapters whose stage the pack does not name (an older pack) still list.
                let orphans = chapters.filter { chapter in !(course?.stages ?? []).contains { $0.id == chapter.stage } }
                ForEach(orphans) { chapter in
                    Section(header: Text(chapter.title.uppercased())) {
                        chapterRows(chapter)
                    }
                }

                Section(footer:
                    Text("Example recitations play in the app's current reciter. Curriculum by Jamil Hammoudeh for Tilawa, used with permission.")
                        .font(.caption2)
                ) { EmptyView() }
            }
            .themedListRowBackground()
        }
        .selectableArticleList(disableNowPlayingInset: true)
        .navigationTitle("Tajweed Lessons")
        .task {
            guard course == nil, TajweedLessonsStore.isBundled else { return }
            course = await Task.detached(priority: .userInitiated) { TajweedLessonsStore.shared.course() }.value
        }
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .debugPushDestination(isPresented: $debugOpenLesson) {
            if let id = Self.debugLessonID, let lesson = TajweedLessonsStore.shared.lesson(id: id) {
                TajweedLessonDetailView(lesson: lesson)
            }
        }
        .onAppear {
            if Self.debugLessonID != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { debugOpenLesson = true }
            }
        }
        #endif
    }

    private func stageHeader(_ stage: TajweedCourseStage) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(stage.titleEn.uppercased())
                Spacer()
                Text(stage.titleAr)
                    .textCase(nil)
                    .foregroundColor(accent)
            }
            if !stage.blurb.isEmpty {
                Text(stage.blurb)
                    .font(.caption2)
                    .textCase(nil)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func chapterRows(_ chapter: TajweedLessonChapter) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(chapter.title)
                .font(.subheadline.weight(.bold))
            if !chapter.subtitle.isEmpty {
                Text(chapter.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)

        ForEach(chapter.lessons) { lesson in
            NavigationLink(destination: LazyDestination { TajweedLessonDetailView(lesson: lesson) }) {
                HStack(spacing: 10) {
                    Image(systemName: progress.isDone(lesson.id) ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline)
                        .foregroundColor(progress.isDone(lesson.id) ? accent : Color.secondary.opacity(0.5))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(lesson.titleEn)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(lesson.titleAr)
                                .font(.subheadline)
                                .foregroundColor(accent)
                        }
                        if !lesson.summary.isEmpty {
                            Text(lesson.summary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        if lesson.minutes > 0 {
                            Text("\(lesson.minutes) min" + (lesson.quiz.isEmpty ? "" : " · \(lesson.quiz.count) questions"))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Lesson detail

struct TajweedLessonDetailView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var progress = TajweedLessonProgress.shared

    let lesson: TajweedLesson

    private var accent: Color { appearance.accent }
    private var arabicFont: Font {
        Font.arabic(appearance.quranDisplayFace, size: CGFloat(appearance.fontArabicSize))
    }

    var body: some View {
        let _ = RenderCounter.hit("TajweedLessonDetailView")
        List {
            Group {
                if !lesson.summary.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            if !lesson.translit.isEmpty {
                                Text(lesson.translit)
                                    .font(.caption.italic())
                                    .foregroundStyle(.secondary)
                            }
                            Text(lesson.summary)
                                .font(.body)
                                .fontWeight(.medium)
                                .fixedSize(horizontal: false, vertical: true)
                            if lesson.minutes > 0 {
                                Label("About \(lesson.minutes) minutes", systemImage: "clock")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                if let definition = lesson.definition {
                    Section(header: Text("WHAT IT IS")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(definition.termAr)
                                .font(arabicFont)
                                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                .foregroundColor(accent)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            labeled("Literally", definition.literal)
                            labeled("In tajweed", definition.technical)
                        }
                        .padding(.vertical, 2)
                    }
                }

                if let card = lesson.ruleCard {
                    ruleCardSection(card)
                }

                Section(header: Text("LESSON")) {
                    ForEach(Array(lesson.body.enumerated()), id: \.offset) { _, paragraph in
                        SelectableProse(text: paragraph)
                            .padding(.vertical, 2)
                    }
                }

                if !lesson.keyPoints.isEmpty {
                    Section(header: Text("KEY POINTS")) {
                        ForEach(Array(lesson.keyPoints.enumerated()), id: \.offset) { _, point in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(accent)
                                Text(point)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                ForEach(lesson.letterSets) { set in
                    Section(header: Text(set.label.uppercased())) {
                        VStack(alignment: .leading, spacing: 8) {
                            FlowLayoutView(spacing: 6) {
                                ForEach(Array(set.letters.enumerated()), id: \.offset) { _, letter in
                                    Text(letter)
                                        .font(Font.arabic(appearance.quranDisplayFace, size: 26))
                                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                        .foregroundColor(set.emphasis ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(set.emphasis ? accent : accent.opacity(0.1)))
                                }
                            }
                            if !set.note.isEmpty {
                                Text(set.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if let table = lesson.table {
                    tableSection(table)
                }

                if !lesson.examples.isEmpty {
                    Section(header: Text("HEAR IT IN THE QURAN")) {
                        ForEach(lesson.examples) { example in
                            exampleRow(example)
                        }
                    }
                }

                if !lesson.mistakes.isEmpty {
                    Section(header: Text("COMMON MISTAKES")) {
                        ForEach(lesson.mistakes) { mistake in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                    Text(mistake.wrong)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(accent)
                                    Text(mistake.right)
                                        .font(.subheadline.weight(.medium))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if !mistake.why.isEmpty {
                                    Text(mistake.why)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.leading, 22)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !lesson.drills.isEmpty {
                    Section(header: Text("PRACTICE DRILLS")) {
                        ForEach(lesson.drills) { drill in
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(drill.text)
                                    .font(arabicFont)
                                    .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                if !drill.translit.isEmpty {
                                    Text(drill.translit)
                                        .font(.caption.italic())
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                if !drill.caption.isEmpty {
                                    Text(drill.caption)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if !lesson.quiz.isEmpty {
                    Section(header: Text("CHECK YOURSELF")) {
                        TajweedQuizView(questions: lesson.quiz)
                    }
                }

                relatedSection

                Section {
                    Button {
                        Settings.shared.hapticFeedback()
                        progress.toggle(lesson.id)
                    } label: {
                        HStack {
                            Spacer()
                            Label(progress.isDone(lesson.id) ? "Marked as done" : "Mark as done",
                                  systemImage: progress.isDone(lesson.id) ? "checkmark.circle.fill" : "circle")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                    .foregroundColor(accent)
                }
            }
            .themedListRowBackground()
        }
        .selectableArticleList(disableNowPlayingInset: true)
        .navigationTitle(lesson.titleEn)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func labeled(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func ruleCardSection(_ card: TajweedLessonRuleCard) -> some View {
        Section(header: HStack {
            Text("THE RULE")
            Spacer()
            if !card.countEn.isEmpty {
                Text(card.countEn)
                    .textCase(nil)
                    .foregroundColor(accent)
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                if !card.trigger.isEmpty { ruleLine("When", card.trigger, systemImage: "bolt.fill") }
                if !card.action.isEmpty { ruleLine("Do", card.action, systemImage: "mouth.fill") }
                if !card.hold.isEmpty { ruleLine("Hold", card.hold, systemImage: "timer") }
                if !card.mnemonicArabic.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.mnemonicArabic)
                            .font(arabicFont)
                            .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                            .foregroundColor(accent)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        if !card.mnemonicGloss.isEmpty {
                            Text(card.mnemonicGloss)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 4)

            ForEach(card.fragments) { fragment in
                VStack(alignment: .trailing, spacing: 4) {
                    Text(fragment.text)
                        .font(arabicFont)
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    if !fragment.caption.isEmpty {
                        Text(fragment.caption)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func ruleLine(_ label: String, _ text: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundColor(accent)
                .frame(width: 18)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func tableSection(_ table: TajweedLessonTable) -> some View {
        Section(header: Text(table.title.isEmpty ? "AT A GLANCE" : table.title.uppercased())) {
            VStack(alignment: .leading, spacing: 0) {
                tableRow(table.columns, header: true, arabicFirst: false)
                ForEach(Array(table.rows.enumerated()), id: \.offset) { index, row in
                    Divider()
                    tableRow(row, header: false, arabicFirst: table.arabicFirstColumn)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func tableRow(_ cells: [String], header: Bool, arabicFirst: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                let isArabic = arabicFirst && index == 0 || cell.containsArabicScript
                Text(cell)
                    .font(header ? .caption2.weight(.bold) : (isArabic ? Font.arabic(appearance.quranDisplayFace, size: 18) : .caption))
                    .arabicFontDesign(custom: isArabic && appearance.quranUsesCustomArabicFace)
                    .foregroundStyle(header ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                    .multilineTextAlignment(isArabic ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var relatedSection: some View {
        let related = lesson.related.compactMap { TajweedLessonsStore.shared.lesson(id: $0) }
        let count = lesson.ruleCode.flatMap { TajweedLessonsStore.shared.course()?.ruleCounts[$0] }
        if !related.isEmpty || count != nil {
            Section(header: Text("GO ON TO")) {
                if let count, count.ayahs > 0 {
                    Label("This rule appears in \(count.ayahs) ayahs, on \(count.words) words.", systemImage: "text.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(related) { other in
                    NavigationLink(destination: LazyDestination { TajweedLessonDetailView(lesson: other) }) {
                        HStack {
                            Text(other.titleEn)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(other.titleAr)
                                .font(.caption)
                                .foregroundColor(accent)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func exampleRow(_ example: TajweedLessonExample) -> some View {
        if let surah = quranData.surah(example.surahId),
           let ayah = surah.ayahs.first(where: { $0.id == example.ayahNumber }) {
            let text = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: "")
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("\(surah.nameTransliteration) \(example.surahId):\(example.ayahNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(accent)
                    Spacer()
                    Button {
                        Settings.shared.hapticFeedback()
                        QuranPlayer.shared.playAyah(surahNumber: example.surahId, ayahNumber: example.ayahNumber)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(accent)
                    }
                    .buttonStyle(.plain)
                }

                // The rule's colors are the whole point here, so the example paints its tajweed
                // regardless of the reader's own toggle: off the main thread, plain for a frame.
                TajweedExampleText(surah: example.surahId, ayah: example.ayahNumber, text: text,
                                   fontName: appearance.quranDisplayFace, size: CGFloat(appearance.fontArabicSize))

                if !example.word.isEmpty {
                    HStack(spacing: 6) {
                        Text("Listen at")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(example.word)
                            .font(Font.arabic(appearance.quranDisplayFace, size: 18))
                            .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                            .foregroundColor(accent)
                    }
                }

                if !example.focus.isEmpty {
                    Label(example.focus, systemImage: "ear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Quiz

/// The lesson's self-check: one question at a time, the reason shown whether the answer was
/// right or wrong, and a score at the end.
/// One example ayah of a lesson, its tajweed painted on a detached task (the paint is pure and its
/// caches are `NSCache`s, the readers' `paintOffMain` rule): the row renders plain for a frame and
/// coloured on the next, instead of running the cluster analysis in its body on the main thread.
private struct TajweedExampleText: View {
    let surah: Int
    let ayah: Int
    let text: String
    let fontName: String
    let size: CGFloat

    @State private var styled: AttributedString?

    var body: some View {
        Group {
            if let styled {
                Text(styled)
            } else {
                Text(text)
            }
        }
        .font(.custom(fontName, size: size))
        .arabicFontDesign(custom: true)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .task(id: "\(surah):\(ayah)") {
            let surah = surah, ayah = ayah, text = text
            styled = await Task.detached(priority: .userInitiated) {
                TajweedStore.shared.attributedText(surah: surah, ayah: ayah, text: text)
            }.value
        }
    }
}

struct TajweedQuizView: View {
    @Environment(\.appearance) private var appearance

    let questions: [TajweedQuizQuestion]

    @State private var index = 0
    @State private var chosen: Int?
    @State private var correct = 0
    @State private var finished = false

    private var accent: Color { appearance.accent }

    var body: some View {
        if finished {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(correct) of \(questions.count) right")
                    .font(.title3.weight(.bold))
                    .foregroundColor(accent)
                Text(correct == questions.count ? "Every one. On to the next lesson."
                     : correct * 2 >= questions.count ? "Most of it is there. Read the rule card once more, then try again."
                     : "Worth another pass through the lesson before moving on.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Settings.shared.hapticFeedback()
                    index = 0
                    chosen = nil
                    correct = 0
                    finished = false
                } label: {
                    Label("Try again", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        } else {
            let question = questions[index]
            VStack(alignment: .leading, spacing: 10) {
                Text("Question \(index + 1) of \(questions.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(question.prompt)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                if !question.arabic.isEmpty {
                    Text(question.arabic)
                        .font(Font.arabic(appearance.quranDisplayFace, size: CGFloat(appearance.fontArabicSize)))
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                ForEach(Array(question.choices.enumerated()), id: \.offset) { choiceIndex, choice in
                    Button {
                        guard chosen == nil else { return }
                        Settings.shared.hapticFeedback()
                        chosen = choiceIndex
                        if choiceIndex == question.answer { correct += 1 }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: icon(for: choiceIndex, answer: question.answer))
                                .font(.subheadline)
                                .foregroundColor(tint(for: choiceIndex, answer: question.answer))
                            Text(choice)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(tint(for: choiceIndex, answer: question.answer).opacity(chosen == nil ? 0.08 : 0.14)))
                    }
                    .buttonStyle(.plain)
                }
                if let chosen {
                    Text(question.explain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                    Button {
                        Settings.shared.hapticFeedback()
                        if index + 1 < questions.count {
                            index += 1
                            self.chosen = nil
                        } else {
                            finished = true
                        }
                    } label: {
                        Label(index + 1 < questions.count ? "Next question" : "See the score",
                              systemImage: "arrow.right.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(chosen == question.answer ? "Correct" : "Incorrect")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func icon(for choice: Int, answer: Int) -> String {
        guard let chosen else { return "circle" }
        if choice == answer { return "checkmark.circle.fill" }
        if choice == chosen { return "xmark.circle.fill" }
        return "circle"
    }

    private func tint(for choice: Int, answer: Int) -> Color {
        guard let chosen else { return accent }
        if choice == answer { return accent }
        if choice == chosen { return .red.opacity(0.8) }
        return Color.secondary.opacity(0.5)
    }
}
#endif
