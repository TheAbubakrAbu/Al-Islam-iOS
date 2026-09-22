#if os(iOS)
import SwiftUI

// Two more ways through the shelf, both built on the packs the Hadith tab already carries:
//
//  * Browse by topic: 331 narrations from Bukhari, Muslim, Abu Dawud and at-Tirmidhi, each given
//    a title and filed under one of 21 subjects in seven lanes, so one subject can be read as
//    Bukhari words it, next to Muslim, next to Tirmidhi. Tilawa's curation (Jamil Hammoudeh, with
//    permission); only the citations ship (Scripts/build_hadith_topics.py -> HadithTopics.json.xz)
//    and the text is this app's own.
//  * History: what was opened, grouped by day; the daily hadith of earlier days; where each book
//    was left; and the searches worth running again.
//
// (Folders, a third shelf inside the bookmarks, were removed on 2026-09-07: bookmarks alone are
// the whole filing system now.)

// MARK: - Topic library

struct HadithTopicEntry: Identifiable {
    let id: String
    let title: String
    let topic: String
    let lane: String
    let slug: String
    let citation: String
    let tags: [String]
    let rank: Int

    /// "1923" -> (1923, nil); "35a" -> (35, "a"); "1211aa" -> (1211, "aa").
    var citationParts: (number: Int, suffix: String?) {
        HadithCitation.parts(citation)
    }
}

struct HadithTopic: Identifiable {
    let id: String
    let label: String
    let subtitle: String
    let lane: String
}

struct HadithLane: Identifiable {
    let id: String
    let label: String
    let subtitle: String
}

final class HadithTopicsStore: @unchecked Sendable {
    static let shared = HadithTopicsStore()

    static var packURL: URL? {
        Bundle.main.url(forResource: "HadithTopics", withExtension: "json.xz", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "HadithTopics", withExtension: "json.xz", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "HadithTopics", withExtension: "json.xz")
    }

    static let isBundled: Bool = packURL != nil

    private struct Library {
        let lanes: [HadithLane]
        let topics: [HadithTopic]
        let entries: [HadithTopicEntry]
    }

    private let lock = NSLock()
    private var library: Library?
    private var loadFailed = false

    private init() {}

    private func loaded() -> Library? {
        lock.lock()
        if let library { lock.unlock(); return library }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()
        let parsed = Self.load()
        lock.lock(); defer { lock.unlock() }
        if let library { return library }
        if let parsed {
            library = parsed
            return parsed
        }
        loadFailed = true
        return nil
    }

    var lanes: [HadithLane] { loaded()?.lanes ?? [] }
    var topics: [HadithTopic] { loaded()?.topics ?? [] }
    var entries: [HadithTopicEntry] { loaded()?.entries ?? [] }

    func topics(inLane lane: String) -> [HadithTopic] { topics.filter { $0.lane == lane } }

    /// The library's narration and subject counts if it is parsed, else nil (and the parse is
    /// kicked off-main): the Hadith tab's door reads this in its body, which must never parse.
    var countsIfLoaded: (entries: Int, topics: Int)? {
        lock.lock()
        let library = library
        let failed = loadFailed
        lock.unlock()
        if let library { return (library.entries.count, library.topics.count) }
        if failed { return nil }
        DispatchQueue.global(qos: .utility).async { _ = self.loaded() }
        return nil
    }
    func entries(inTopic topic: String) -> [HadithTopicEntry] {
        entries.filter { $0.topic == topic }.sorted { $0.rank < $1.rank }
    }
    func count(inTopic topic: String) -> Int { entries.filter { $0.topic == topic }.count }
    func count(inLane lane: String) -> Int { entries.filter { $0.lane == lane }.count }

    private static func load() -> Library? {
        PackTrace.measure("HadithTopics") { () -> (result: Library?, bytes: Int) in
            guard let url = packURL, let blob = try? Data(contentsOf: url),
                  let json = SolidPack.xzDecompress(blob) else { return (nil, 0) }
            return (parse(json), json.count)
        }
    }

    private static func parse(_ json: Data) -> Library? {
        guard let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any] else { return nil }
        let lanes = (root["lanes"] as? [[String: Any]] ?? []).compactMap { row -> HadithLane? in
            guard let id = row["id"] as? String, let label = row["label"] as? String else { return nil }
            return HadithLane(id: id, label: label, subtitle: row["subtitle"] as? String ?? "")
        }
        let topics = (root["topics"] as? [[String: Any]] ?? []).compactMap { row -> HadithTopic? in
            guard let id = row["id"] as? String, let label = row["label"] as? String else { return nil }
            return HadithTopic(id: id, label: label, subtitle: row["subtitle"] as? String ?? "",
                               lane: row["lane"] as? String ?? "")
        }
        let entries = (root["entries"] as? [[String: Any]] ?? []).compactMap { row -> HadithTopicEntry? in
            guard let id = row["id"] as? String, let slug = row["slug"] as? String,
                  let citation = row["citation"] as? String else { return nil }
            return HadithTopicEntry(id: id, title: row["title"] as? String ?? "",
                                    topic: row["topic"] as? String ?? "", lane: row["lane"] as? String ?? "",
                                    slug: slug, citation: citation, tags: row["tags"] as? [String] ?? [],
                                    rank: row["rank"] as? Int ?? 0)
        }
        guard !entries.isEmpty else { return nil }
        return Library(lanes: lanes, topics: topics, entries: entries)
    }
}

/// The library's front: seven lanes, each listing its subjects with a count.
struct HadithTopicsView: View {

    private let store = HadithTopicsStore.shared

    #if DEBUG
    /// "-openHadithTopic <id>": that subject pushed as the library appears, for screenshots.
    @State private var debugOpenTopic = false
    private static var debugTopicID: String? {
        guard let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-openHadithTopic"),
              ProcessInfo.processInfo.arguments.indices.contains(idx + 1) else { return nil }
        return ProcessInfo.processInfo.arguments[idx + 1]
    }
    #endif

    var body: some View {
        let _ = RenderCounter.hit("HadithTopicsView")
        List {
            Group {
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        AccentIconChip(systemImage: "square.grid.2x2.fill", size: 34)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("The same subject across the books")
                                .font(.subheadline.weight(.semibold))
                            Text("\(store.entries.count) narrations from Bukhari, Muslim, Abu Dawud and at-Tirmidhi, each with a title, filed under \(store.topics.count) subjects. Open one to read how each collection words it.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)
                }

                ForEach(store.lanes) { lane in
                    Section(header: laneHeader(lane)) {
                        ForEach(store.topics(inLane: lane.id)) { topic in
                            NavigationLink(destination: LazyDestination { HadithTopicView(topic: topic) }) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(topic.label)
                                            .font(.subheadline.weight(.semibold))
                                        Text(topic.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 8)
                                    CountPill(count: store.count(inTopic: topic.id))
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                Section(footer:
                    Text("Curated by Jamil Hammoudeh for Tilawa and used with permission. The narrations themselves are this app's own, from the same open dataset every collection here comes from.")
                        .font(.caption2)
                ) { EmptyView() }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Browse by Topic")
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .debugPushDestination(isPresented: $debugOpenTopic) {
            if let id = Self.debugTopicID, let topic = store.topics.first(where: { $0.id == id }) {
                HadithTopicView(topic: topic)
            }
        }
        .onAppear {
            if Self.debugTopicID != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugOpenTopic = true }
            }
        }
        #endif
    }

    private func laneHeader(_ lane: HadithLane) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(lane.label.uppercased())
                Spacer()
                Text("\(store.count(inLane: lane.id))")
            }
            Text(lane.subtitle)
                .font(.caption2)
                .textCase(nil)
                .foregroundStyle(.secondary)
        }
    }
}

/// One subject: its narrations grouped by collection, in the Hadith tab's own rows, each with the
/// title the library gave it.
struct HadithTopicView: View {
    @Environment(\.appearance) private var appearance

    let topic: HadithTopic

    private struct Resolved: Identifiable {
        let entry: HadithTopicEntry
        let book: HadithCatalogBook
        let data: HadithBookData
        let hadith: HadithBookData.Hadith
        var id: String { entry.id }
    }

    @State private var resolved: [Resolved] = []
    @State private var loading = true

    private static let bookOrder = ["bukhari", "muslim", "abudawud", "tirmidhi"]

    private var groups: [(book: HadithCatalogBook, rows: [Resolved])] {
        var byBook: [String: [Resolved]] = [:]
        for row in resolved { byBook[row.book.slug, default: []].append(row) }
        return Self.bookOrder.compactMap { slug in
            guard let rows = byBook[slug], let book = rows.first?.book else { return nil }
            return (book, rows)
        }
    }

    var body: some View {
        let _ = RenderCounter.hit("HadithTopicView")
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.label)
                            .font(.title3.weight(.bold))
                        Text(topic.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }

                if loading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else {
                    ForEach(groups, id: \.book.slug) { group in
                        Section(header: SectionPillHeader(title: group.book.englishTitle.uppercased(), count: group.rows.count)) {
                            ForEach(group.rows) { row in
                                // Lazy: an eager destination built a `HadithChapterView` per visible
                                // row, whose init slices the chapter and checks its text blocks.
                                NavigationLink(destination: LazyDestination { destination(for: row) }) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(row.entry.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(appearance.accent)
                                        HadithRow(book: row.book, hadith: row.hadith, compact: true).equatable()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(topic.label)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await resolve()
        }
    }

    /// The narration in its chapter (scrolled to it), or by reference when the chapter is unknown.
    @ViewBuilder
    private func destination(for row: Resolved) -> some View {
        if let chapter = row.data.chapters.first(where: { $0.id == row.hadith.chapterId }) {
            HadithChapterView(book: row.book, bookData: row.data, chapter: chapter, scrollToHadithId: row.hadith.idInBook)
        } else {
            HadithReferenceView(book: row.book, chapter: nil, hadith: row.entry.citationParts.number, suffix: row.entry.citationParts.suffix)
        }
    }

    private func resolve() async {
        let entries = HadithTopicsStore.shared.entries(inTopic: topic.id)
        var books: [String: (HadithCatalogBook, HadithBookData)] = [:]
        var rows: [Resolved] = []
        for entry in entries {
            if books[entry.slug] == nil,
               let book = HadithCatalogBook.all.first(where: { $0.slug == entry.slug }),
               let data = await HadithStore.shared.openOffMain(book) {
                books[entry.slug] = (book, data)
            }
            guard let (book, data) = books[entry.slug] else { continue }
            let parts = entry.citationParts
            guard let hadith = data.hadith(referenced: parts.number, suffix: parts.suffix) else { continue }
            rows.append(Resolved(entry: entry, book: book, data: data, hadith: hadith))
        }
        // The first two screens' text blocks, inflated off the main actor before the rows show, so
        // no row body decodes one on the main thread ("HADITH BLOCK ... MAIN").
        let warm = Array(rows.prefix(20))
        await withTaskGroup(of: Void.self) { group in
            for row in warm where row.hadith.row >= 0 {
                let data = row.data
                let index = row.hadith.row
                group.addTask(priority: .userInitiated) { data.prewarmText(rows: index..<(index + 1)) }
            }
        }
        resolved = rows
        loading = false
    }
}

// MARK: - History

/// A recent search tapped in History: the term travels back to the tab root, which searches it
/// after the pop (the Quran tab's history chips sit on the root itself and need no relay).
@MainActor
final class HadithSearchHandoff: ObservableObject {
    static let shared = HadithSearchHandoff()
    private init() {}

    @Published var pendingTerm: String?
}

/// Everything the reader has been through in the Hadith section, on one page. The groups are
/// derived once per change of the viewed log or the last-read table (a formatter per entry per
/// body before), and the rows push lazily.
struct HadithHistoryView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var viewedLog = HadithStore.shared.viewedLog
    @Environment(\.dismiss) private var dismiss

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private struct DayGroup: Equatable {
        let day: String
        let rows: [HadithStore.ViewedEntry]
    }

    private struct Derived: Equatable {
        var viewedByDay: [DayGroup] = []
        var daily: [HadithStore.DailyHadithEntry] = []
        var leftOff: [HadithLastRead] = []
        var isEmpty: Bool { viewedByDay.isEmpty && daily.isEmpty && leftOff.isEmpty }
    }
    /// Derived once at construction (the log and the last-read table are in memory by then) and
    /// again only when either publishes a different value: one body per open.
    @State private var derived: Derived

    init() {
        HadithStore.shared.viewedLog.loadIfNeeded()
        _derived = State(initialValue: Self.derive(entries: HadithStore.shared.viewedLog.entries))
    }

    private func refresh() {
        let next = Self.derive(entries: viewedLog.entries)
        if next != derived { derived = next }
    }

    private static func derive(entries: [HadithStore.ViewedEntry]) -> Derived {
        var next = Derived()
        let calendar = Calendar.current
        var groups: [Date: [HadithStore.ViewedEntry]] = [:]
        var order: [Date] = []
        for entry in entries {
            let day = calendar.startOfDay(for: entry.viewedAt)
            if groups[day] == nil { order.append(day) }
            groups[day, default: []].append(entry)
        }
        next.viewedByDay = order.map { DayGroup(day: dayFormatter.string(from: $0), rows: groups[$0] ?? []) }
        next.daily = HadithStore.loadDailyHistory()
        next.leftOff = HadithStore.shared.lastReadByBook.values.sorted { $0.timestamp > $1.timestamp }
        return next
    }

    var body: some View {
        let _ = RenderCounter.hit("HadithHistoryView")
        let daily = derived.daily
        let leftOff = derived.leftOff
        let searches = settings.hadithSearchHistory

        List {
            Group {
                // What the screen is, said here rather than as a caption on the door that opens it
                // (Abu, 2026-09-07).
                Section {
                    Text("Everything this tab remembers: the hadiths you opened, the daily hadith of earlier days, where you left each book, and your recent searches. Tap any of them to open it. It never leaves this device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if derived.isEmpty, searches.isEmpty {
                    Section {
                        Text("Nothing yet. Open a hadith, leave a book part-read or run a search, and it collects here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(derived.viewedByDay, id: \.day) { group in
                    Section(header: Text("OPENED · " + group.day.uppercased())) {
                        ForEach(group.rows) { entry in
                            historyRow(slug: entry.slug, idInBook: entry.idInBook, reference: entry.reference,
                                       arabic: entry.arabicPreview, english: entry.englishPreview, chapterId: entry.chapterId)
                        }
                    }
                }

                if !leftOff.isEmpty {
                    Section(header: Text("WHERE YOU LEFT OFF")) {
                        ForEach(leftOff, id: \.slug) { entry in
                            historyRow(slug: entry.slug, idInBook: entry.idInBook, reference: entry.reference,
                                       arabic: entry.arabicPreview, english: entry.englishPreview, chapterId: entry.chapterId)
                        }
                    }
                }

                if !daily.isEmpty {
                    Section(header: Text("HADITH OF THE DAY, EARLIER")) {
                        ForEach(Array(daily.reversed().prefix(30)), id: \.dayKey) { entry in
                            historyRow(slug: entry.slug, idInBook: entry.idInBook, reference: entry.reference + " · " + entry.dayKey,
                                       arabic: entry.arabicPreview, english: entry.englishPreview, chapterId: nil)
                        }
                    }
                }

                if !searches.isEmpty {
                    Section(header: Text("RECENT SEARCHES")) {
                        ForEach(searches, id: \.self) { term in
                            Button {
                                settings.hapticFeedback()
                                HadithSearchHandoff.shared.pendingTerm = term
                                dismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(term)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer(minLength: 0)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewedLog.$entries) { _ in refresh() }
        .onReceive(HadithStore.shared.$lastReadByBook) { _ in refresh() }
    }

    @ViewBuilder
    private func historyRow(slug: String, idInBook: Int, reference: String, arabic: String, english: String, chapterId: Int?) -> some View {
        if let book = HadithCatalogBook.all.first(where: { $0.slug == slug }) {
            NavigationLink(destination: LazyDestination {
                HadithHistoryDestination(book: book, idInBook: idInBook, chapterId: chapterId)
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reference)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                    if settings.showHadithArabic, !arabic.isEmpty {
                        Text(arabic)
                            .font(settings.useFontArabic ? Font.arabic(settings.nonQuranArabicFontName, size: 17) : .body)
                            .arabicFontDesign(custom: settings.useFontArabic && settings.nonQuranArabicFontName != Settings.systemArabicFontName)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    if settings.showHadithEnglish, !english.isEmpty {
                        Text(english)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

/// Lands in the chapter scrolled to the hadith once the book is open; the reference view until then.
private struct HadithHistoryDestination: View {
    let book: HadithCatalogBook
    let idInBook: Int
    let chapterId: Int?

    @State private var data: HadithBookData?

    var body: some View {
        Group {
            if let data, let hadith = data.hadith(numbered: idInBook),
               let chapter = data.chapters.first(where: { $0.id == (chapterId ?? hadith.chapterId) }) {
                HadithChapterView(book: book, bookData: data, chapter: chapter, scrollToHadithId: idInBook)
            } else if data != nil {
                HadithReferenceView(book: book, chapter: nil, hadith: idInBook, suffix: nil)
            } else {
                ProgressView()
            }
        }
        .task {
            data = await HadithStore.shared.openOffMain(book)
        }
    }
}
#endif
