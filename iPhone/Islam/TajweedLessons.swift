#if os(iOS)
import SwiftUI
import Compression

// Structured tajweed lessons - a guided course from reading foundations (Qaida Noorania
// style) through makharij, sifat, and the classical rules, with curated Quranic examples
// you can hear in place.
//
// The curriculum was written by Jamil Hammoudeh for Tilawa and is ported with his
// permission (see CreditsView). Content ships as TajweedLessons.json.deflate, built by
// Scripts/build_tajweed_lessons.py straight from Tilawa's source file and gated by
// Scripts/verify_tajweed_lessons.py - a content fix there is a rebuild away here.

// MARK: - Model

struct TajweedLessonExample: Identifiable {
    let surahId: Int
    let ayahNumber: Int
    /// What to listen for in this ayah.
    let focus: String

    var id: String { "\(surahId):\(ayahNumber)" }
}

struct TajweedLessonDrill: Identifiable {
    /// A short isolated snippet (letter row, word, phrase) - practice text, not an ayah.
    let text: String
    let caption: String

    var id: String { text }
}

struct TajweedLessonFragment: Identifiable {
    let text: String
    let caption: String

    var id: String { text }
}

struct TajweedLessonCard {
    let countAr: String
    let countEn: String
    let fragments: [TajweedLessonFragment]
}

struct TajweedLesson: Identifiable {
    let id: String
    let titleEn: String
    let titleAr: String
    let summary: String
    let body: [String]
    let examples: [TajweedLessonExample]
    let drills: [TajweedLessonDrill]
    let card: TajweedLessonCard?
}

struct TajweedLessonChapter: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let lessons: [TajweedLesson]
}

// MARK: - Store

final class TajweedLessonsStore: @unchecked Sendable {
    static let shared = TajweedLessonsStore()
    private init() {}

    private let lock = NSLock()
    private var cached: [TajweedLessonChapter]?
    private var loadFailed = false

    static let isBundled: Bool = packURL() != nil

    func chapters() -> [TajweedLessonChapter] {
        lock.lock()
        if let cached { lock.unlock(); return cached }
        if loadFailed { lock.unlock(); return [] }
        lock.unlock()

        let parsed = Self.load()
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }
        if let parsed {
            cached = parsed
            return parsed
        }
        loadFailed = true
        return []
    }

    private static func packURL() -> URL? {
        Bundle.main.url(forResource: "TajweedLessons", withExtension: "json.deflate", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "TajweedLessons", withExtension: "json.deflate", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "TajweedLessons", withExtension: "json.deflate")
    }

    private static func load() -> [TajweedLessonChapter]? {
        guard let url = packURL(),
              let blob = try? Data(contentsOf: url),
              let json = inflate(blob),
              let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let rows = root["chapters"] as? [[String: Any]] else { return nil }

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
                                                focus: example["focus"] as? String ?? "")
                }
                let drills = (lesson["drills"] as? [[String: Any]] ?? []).compactMap { drill -> TajweedLessonDrill? in
                    guard let text = drill["text"] as? String else { return nil }
                    return TajweedLessonDrill(text: text, caption: drill["caption"] as? String ?? "")
                }
                var card: TajweedLessonCard?
                if let raw = lesson["mushafCard"] as? [String: Any],
                   let fragmentRows = raw["fragments"] as? [[String: Any]] {
                    let fragments = fragmentRows.compactMap { fragment -> TajweedLessonFragment? in
                        guard let text = fragment["text"] as? String else { return nil }
                        return TajweedLessonFragment(text: text, caption: fragment["caption"] as? String ?? "")
                    }
                    if !fragments.isEmpty {
                        card = TajweedLessonCard(countAr: raw["countAr"] as? String ?? "",
                                                 countEn: raw["countEn"] as? String ?? "",
                                                 fragments: fragments)
                    }
                }
                return TajweedLesson(id: lid, titleEn: titleEn,
                                     titleAr: lesson["titleAr"] as? String ?? "",
                                     summary: lesson["summary"] as? String ?? "",
                                     body: body, examples: examples, drills: drills, card: card)
            }
            guard !lessons.isEmpty else { return nil }
            return TajweedLessonChapter(id: id, title: title,
                                        subtitle: chapter["subtitle"] as? String ?? "",
                                        lessons: lessons)
        }
        return chapters.isEmpty ? nil : chapters
    }

    private static func inflate(_ data: Data) -> Data? {
        let capacity = max(data.count * 14, 1 << 20)
        var out = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        defer { buffer.deallocate() }
        let written = data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) -> Int in
            guard let base = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(buffer, capacity, base, data.count, nil, COMPRESSION_ZLIB)
        }
        guard written > 0 else { return nil }
        out.append(buffer, count: written)
        return out
    }
}

// MARK: - Course index

struct TajweedLessonsView: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        List {
            ForEach(TajweedLessonsStore.shared.chapters()) { chapter in
                Section(header:
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chapter.title.uppercased())
                        if !chapter.subtitle.isEmpty {
                            Text(chapter.subtitle)
                                .font(.caption2)
                                .textCase(nil)
                                .foregroundColor(.secondary)
                        }
                    }
                ) {
                    ForEach(chapter.lessons) { lesson in
                        NavigationLink(destination: LazyDestination { TajweedLessonDetailView(lesson: lesson) }) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(lesson.titleEn)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(lesson.titleAr)
                                        .font(.subheadline)
                                        .foregroundColor(settings.accentColor.color)
                                }
                                if !lesson.summary.isEmpty {
                                    Text(lesson.summary)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }

            Section(footer:
                Text("Curriculum written by Jamil Hammoudeh for Tilawa, ported with permission. Example recitations: the app's current reciter.")
                    .font(.caption2)
            ) { EmptyView() }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .navigationTitle("Tajweed Lessons")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Lesson detail

struct TajweedLessonDetailView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let lesson: TajweedLesson

    var body: some View {
        List {
            if !lesson.summary.isEmpty {
                Section {
                    Text(lesson.summary)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }

            if let card = lesson.card {
                Section(header: Text("AT A GLANCE")) {
                    if !card.countEn.isEmpty || !card.countAr.isEmpty {
                        HStack {
                            if !card.countEn.isEmpty { Text(card.countEn).font(.caption) }
                            Spacer()
                            if !card.countAr.isEmpty {
                                Text(card.countAr)
                                    .font(.caption)
                                    .foregroundColor(settings.accentColor.color)
                            }
                        }
                    }
                    ForEach(card.fragments) { fragment in
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(fragment.text)
                                .font(.custom(Settings.hafsUthmaniFontName, size: CGFloat(settings.fontArabicSize)))
                                .arabicFontDesign(custom: true)
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

            Section(header: Text("LESSON")) {
                ForEach(Array(lesson.body.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.body)
                        .padding(.vertical, 2)
                }
            }

            if !lesson.drills.isEmpty {
                Section(header: Text("PRACTICE DRILLS")) {
                    ForEach(lesson.drills) { drill in
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(drill.text)
                                .font(.custom(Settings.hafsUthmaniFontName, size: CGFloat(settings.fontArabicSize)))
                                .arabicFontDesign(custom: true)
                                .frame(maxWidth: .infinity, alignment: .trailing)
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

            if !lesson.examples.isEmpty {
                Section(header: Text("HEAR IT IN THE QURAN")) {
                    ForEach(lesson.examples) { example in
                        exampleRow(example)
                    }
                }
            }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .navigationTitle(lesson.titleEn)
        .navigationBarTitleDisplayMode(.inline)
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
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Button {
                        settings.hapticFeedback()
                        QuranPlayer.shared.playAyah(surahNumber: example.surahId, ayahNumber: example.ayahNumber)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .buttonStyle(.plain)
                }

                // The rule's colors are the whole point here, so the example paints its tajweed
                // regardless of the reader's own toggle.
                if let styled = TajweedStore.shared.attributedText(surah: example.surahId, ayah: example.ayahNumber, text: text) {
                    Text(styled)
                        .font(.custom(settings.quranArabicFontName(for: nil), size: CGFloat(settings.fontArabicSize)))
                        .arabicFontDesign(custom: true)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text(text)
                        .font(.custom(settings.quranArabicFontName(for: nil), size: CGFloat(settings.fontArabicSize)))
                        .arabicFontDesign(custom: true)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
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
#endif
