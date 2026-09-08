#if os(iOS)
import SwiftUI
import WidgetKit

// The Reminder of the Day: one date-stable card a day from a corpus of 180 in six kinds (a verse,
// a hadith, a Sunnah practice, a dua, a dhikr, a Name of Allah), interleaved so consecutive days
// differ in kind. It sits at the top of the Islam tab, arrives once a day as a sheet when the app
// opens (from the second day on, and only if the reader keeps that on), and any card can be kept
// in Saved Reflections. The corpus is Tilawa's (Jamil Hammoudeh, with permission); this app
// renders verse cards from its own Quran text and translation, and every hadith card carries the
// citation its narration is filed under on this app's own shelf. Built by
// Scripts/build_daily_reminders.py into Resources/Data/Islam/DailyReminders.json.xz.
//
// The day turns over with every other daily feature: see DailyRollover (Fajr by default).

// MARK: - The corpus

struct DailyReminderEntry: Identifiable, Equatable {
    enum Kind: String {
        case ayah, hadith, sunnah, dua, dhikr, name

        var label: String {
            switch self {
            case .ayah: return "Verse of the day"
            case .hadith: return "Hadith of the day"
            case .sunnah: return "Sunnah of the day"
            case .dua: return "Dua of the day"
            case .dhikr: return "Dhikr of the day"
            case .name: return "Name of Allah"
            }
        }

        var symbol: String {
            switch self {
            case .ayah: return "book.closed.fill"
            case .hadith: return "text.book.closed.fill"
            case .sunnah: return "sparkles"
            case .dua: return "hands.sparkles.fill"
            case .dhikr: return "circles.hexagonpath.fill"
            case .name: return "signature"
            }
        }
    }

    struct HadithLink: Equatable {
        let slug: String
        let citation: String

        /// "1923" -> (1923, nil); "35a" -> (35, "a").
        var parts: (number: Int, suffix: String?) {
            var digits = citation
            var suffix: String?
            if let last = digits.last, last.isLetter {
                suffix = String(last)
                digits = String(digits.dropLast())
            }
            return (Int(digits) ?? 0, suffix)
        }
    }

    let id: String
    let kind: Kind
    /// Empty for a verse: the Arabic is read from the Quran at render time.
    let arabic: String
    let transliteration: String?
    /// The memorable core (the widget's line).
    let short: String
    let english: String
    let source: String
    /// Where the card opens: "ayah:2:152", "hadith", "duas", "adhkar", "names:7".
    let target: String?
    let surah: Int?
    let ayah: Int?
    let repeatCount: Int?
    let hadith: HadithLink?

    /// Whether the Arabic is Quran (rendered in the reader's face) rather than a narration or a dua.
    var isQuranArabic: Bool { kind == .ayah }
}

/// The screen a card opens.
enum DailyReminderTarget: Equatable {
    case ayah(Int, Int)
    case hadithTab
    case duas
    case adhkar
    case names(Int?)

    init?(encoded: String?) {
        guard let encoded else { return nil }
        let parts = encoded.split(separator: ":").map(String.init)
        switch parts.first {
        case "ayah":
            guard parts.count == 3, let s = Int(parts[1]), let a = Int(parts[2]) else { return nil }
            self = .ayah(s, a)
        case "hadith": self = .hadithTab
        case "duas": self = .duas
        case "adhkar": self = .adhkar
        case "names": self = .names(parts.count > 1 ? Int(parts[1]) : nil)
        default: return nil
        }
    }

    var buttonLabel: String {
        switch self {
        case .ayah: return "Read in the Quran"
        case .hadithTab: return "Open Hadith"
        case .duas: return "Open Duas"
        case .adhkar: return "Open Dhikr"
        case .names: return "Open the 99 Names"
        }
    }

    /// Performs the navigation: the Quran tab for a verse, the Islam tab's resources otherwise.
    @MainActor
    func open() {
        switch self {
        case .ayah(let s, let a): AppNavigation.shared.open(.ayah(s, a))
        case .hadithTab: AppNavigation.shared.openIslam(.hadithTab)
        case .duas: AppNavigation.shared.openIslam(.duas)
        case .adhkar: AppNavigation.shared.openIslam(.adhkar)
        case .names(let n): AppNavigation.shared.openIslam(.names(n))
        }
    }
}

final class DailyReminderStore: ObservableObject {
    static let shared = DailyReminderStore()

    static var packURL: URL? {
        Bundle.main.url(forResource: "DailyReminders", withExtension: "json.xz", subdirectory: "Data/Islam")
            ?? Bundle.main.url(forResource: "DailyReminders", withExtension: "json.xz", subdirectory: "Islam")
            ?? Bundle.main.url(forResource: "DailyReminders", withExtension: "json.xz")
    }

    static let isBundled: Bool = packURL != nil

    private let lock = NSLock()
    private var cached: [DailyReminderEntry]?
    private var loadFailed = false
    /// True while one thread parses the pack; a second asker waits on `loadDone` instead of parsing
    /// a second copy (the old accessor dropped the lock during the parse and let both run).
    private var loading = false
    private let loadDone = DispatchGroup()

    /// Flips once, on the main thread, when the corpus has landed (or failed to). The Islam root's
    /// card section observes it, so a root built before the prewarm finished shows the card the
    /// moment the parse lands instead of parsing the pack itself.
    @Published private(set) var isLoaded = false

    /// The card the once-a-day sheet is showing, when it is.
    @Published var sheetEntry: DailyReminderEntry?

    private static let firstOpenKey = "dailyReminderFirstOpenDay"
    private static let lastShownKey = "dailyReminderSheetLastShownDay"
    private static let widgetsWrittenKey = "dailyWidgetsWrittenDay"

    private init() {
        ObjectPublishCounter.attach(self, label: "DailyReminderStore")
    }

    // MARK: Loading

    /// The corpus. Parses on the calling thread when nothing has parsed it yet, waits (never parses
    /// twice) when another thread is on it. For the widget writer and the reminder builder, which run
    /// long after `prewarm()`. Never from a view body: `entryIfLoaded` is the accessor there.
    var entries: [DailyReminderEntry] {
        lock.lock()
        if let cached { lock.unlock(); return cached }
        if loadFailed { lock.unlock(); return [] }
        if loading {
            lock.unlock()
            loadDone.wait()
            lock.lock(); defer { lock.unlock() }
            return cached ?? []
        }
        loading = true
        loadDone.enter()
        lock.unlock()
        let parsed = Self.load()
        finishLoad(parsed)
        return parsed ?? []
    }

    /// The corpus if it is in memory, else nil (kicking the off-main parse if none is running): the
    /// accessor for view bodies, which must never parse. `isLoaded` says when to ask again.
    var entriesIfLoaded: [DailyReminderEntry]? {
        lock.lock()
        let cached = cached
        let failed = loadFailed
        lock.unlock()
        if let cached { return cached }
        if failed { return [] }
        prewarm()
        return nil
    }

    /// Parses off-main, once. Kicked at app init, before the under-cover tab walk builds the Islam
    /// root that reads the corpus; safe to call again from anywhere.
    func prewarm() {
        guard Self.isBundled else { return }
        lock.lock()
        let needed = cached == nil && !loadFailed && !loading
        if needed {
            loading = true
            loadDone.enter()
        }
        lock.unlock()
        guard needed else { return }
        DispatchQueue.global(qos: .utility).async {
            let parsed = Self.load()
            self.finishLoad(parsed)
        }
    }

    /// Suspends until the corpus is in memory (or has failed), kicking the parse if nobody has.
    func waitUntilLoaded() async {
        guard Self.isBundled else { return }
        prewarm()
        for await loaded in $isLoaded.values where loaded { return }
    }

    private func finishLoad(_ parsed: [DailyReminderEntry]?) {
        lock.lock()
        if let parsed { cached = parsed } else { loadFailed = true }
        loading = false
        lock.unlock()
        loadDone.leave()
        DispatchQueue.main.async { self.isLoaded = true }
    }

    /// Today's card: the corpus walked one entry per daily-rollover day.
    func entry(for date: Date = Date()) -> DailyReminderEntry? {
        Self.card(in: entries, for: date)
    }

    /// `entry(for:)` for view bodies: nil until the parse has landed.
    func entryIfLoaded(for date: Date = Date()) -> DailyReminderEntry? {
        guard let all = entriesIfLoaded else { return nil }
        return Self.card(in: all, for: date)
    }

    func entry(id: String) -> DailyReminderEntry? {
        entries.first { $0.id == id }
    }

    private static func card(in all: [DailyReminderEntry], for date: Date) -> DailyReminderEntry? {
        guard !all.isEmpty else { return nil }
        let index = Settings.shared.dailyDayIndex(for: date)
        return all[((index % all.count) + all.count) % all.count]
    }

    /// The Arabic and English a card shows: a verse from the Quran itself (an O(1) lookup, in the
    /// Hafs text every face carries), everything else as written.
    func texts(for entry: DailyReminderEntry) -> (arabic: String, english: String) {
        if entry.kind == .ayah, let s = entry.surah, let a = entry.ayah,
           let ayah = QuranData.shared.ayah(surah: s, ayah: a) {
            return (ayah.displayArabicText(surahId: s, clean: false, qiraahOverride: ""), ayah.textEnglishSaheeh)
        }
        return (entry.arabic, entry.english)
    }

    // MARK: The once-a-day sheet

    /// Shows today's card if it has not been shown today. Day one (the first open ever) is left
    /// alone, so a new reader meets the app before the app starts talking. Refuses while the launch
    /// cover is up (MainTabView's post-reveal task is the launch-time presenter), while the prayer
    /// nag is pending (its dismissal asks again) and while a notification or deep-link destination
    /// is; the day is stamped only when the sheet actually presents.
    @MainActor
    func presentSheetIfDue(force: Bool = false) {
        guard Self.isBundled else { return }
        let defaults = UserDefaults.standard
        let today = Settings.shared.dailyDayKey()
        if !force {
            guard Settings.shared.showDailyReminderSheet else { return }
            if defaults.string(forKey: Self.firstOpenKey) == nil {
                defaults.set(today, forKey: Self.firstOpenKey)
                return
            }
            guard defaults.string(forKey: Self.firstOpenKey) != today,
                  defaults.string(forKey: Self.lastShownKey) != today else { return }
            guard AppReveal.revealed, sheetEntry == nil,
                  Settings.shared.pendingNagQuestion == nil,
                  AppNavigation.shared.pendingQuran == nil, AppNavigation.shared.pendingIslam == nil else { return }
        }
        guard let entry = entry() else { return }
        defaults.set(today, forKey: Self.lastShownKey)
        sheetEntry = entry
    }

    /// A launch that arrived through a notification or a deep link keeps its own destination: the
    /// sheet is skipped for the day.
    @MainActor
    func skipSheetToday() {
        UserDefaults.standard.set(Settings.shared.dailyDayKey(), forKey: Self.lastShownKey)
    }

    // MARK: Widgets

    static let widgetKinds = ["DailyReminderWidget", "NameOfAllahWidget"]
    private var widgetWriteInFlight = false

    /// What the detached build needs of a name, read on the main thread.
    private struct NameInput {
        let number: Int
        let arabic: String
        let transliteration: String
        let meaning: String
    }

    /// Writes the corpus, the 99 names and the Fajr table into the daily blob the Reminder of the Day
    /// and Name of Allah widgets read (`DailyWidgetSnapshot`). Once per daily-rollover day unless
    /// forced. The inputs are read on the main thread once the Quran, the names and the corpus have
    /// loaded; the 180 cards and 99 names are built and encoded off it; only the two kinds reload,
    /// and only if they are placed.
    func refreshWidgets(force: Bool = false) {
        guard Self.isBundled, Settings.isAppProcess else { return }
        #if DEBUG
        // "-dailyWidgetsForce": rewrite the blob on this launch whatever the stamp says (verification).
        let force = force || ProcessInfo.processInfo.arguments.contains("-dailyWidgetsForce")
        #endif
        Task { @MainActor in
            guard !self.widgetWriteInFlight else { return }
            self.widgetWriteInFlight = true
            defer { self.widgetWriteInFlight = false }
            // The first foreground of a launch arrives before any of the three has loaded, so the
            // write waits rather than skipping the day.
            await QuranData.shared.waitUntilLoaded()
            await NamesViewModel.shared.waitUntilLoaded()
            await self.waitUntilLoaded()

            let settings = Settings.shared
            let entries = self.entries
            let today = settings.dailyDayKey()
            let stamp = today + "|" + String(entries.count)
            guard force || UserDefaults.standard.string(forKey: Self.widgetsWrittenKey) != stamp else { return }
            guard !QuranData.shared.quran.isEmpty, !entries.isEmpty else { return }

            // The verse cards' text (thirty O(1) lookups), the faces, the names and the Fajr table
            // are read here, on the main thread; everything after is a pure function of them.
            var verseTexts: [String: (arabic: String, english: String)] = [:]
            for entry in entries where entry.kind == .ayah {
                verseTexts[entry.id] = self.texts(for: entry)
            }
            let quranFace = settings.fontArabic
            let islamFace = settings.islamUsesCustomArabicFace ? settings.nonQuranArabicFontName : nil
            let names = NamesViewModel.shared.namesOfAllah.map {
                NameInput(number: $0.number, arabic: $0.displayArabicName.replacingOccurrences(of: "\n", with: " "),
                          transliteration: $0.transliteration, meaning: $0.meaning)
            }
            let fajrByDay = settings.fajrTable()

            await Task.detached(priority: .utility) {
                let cards = entries.map { entry -> DailyWidgetSnapshot.ReminderCard in
                    let texts = verseTexts[entry.id] ?? (arabic: entry.arabic, english: entry.english)
                    return DailyWidgetSnapshot.ReminderCard(
                        id: entry.id, kind: entry.kind.rawValue, kindLabel: entry.kind.label,
                        arabic: texts.arabic, english: texts.english, short: entry.short,
                        source: entry.source, fontName: entry.kind == .ayah ? quranFace : nil)
                }
                // The names' depth (a 16 KB pack) parses here, off-main, if nothing has parsed it yet.
                let details = NamesDetailsStore.shared
                var nameCards = names.map { name in
                    DailyWidgetSnapshot.NameCard(
                        number: name.number, arabic: name.arabic, transliteration: name.transliteration,
                        meaning: name.meaning, living: details.detail(name.number)?.living ?? "",
                        fontName: islamFace)
                }
                if nameCards.isEmpty, let previous = DailyWidgetStore.load()?.names { nameCards = previous }
                DailyWidgetStore.save(DailyWidgetSnapshot(reminders: cards, names: nameCards, fajrByDay: fajrByDay, writtenDay: today))
            }.value

            UserDefaults.standard.set(stamp, forKey: Self.widgetsWrittenKey)
            Settings.reloadWidgetKinds(Self.widgetKinds)
        }
    }

    // MARK: Parsing

    private static func load() -> [DailyReminderEntry]? {
        PackTrace.measure("DailyReminders") { () -> (result: [DailyReminderEntry]?, bytes: Int) in
            guard let url = packURL, let blob = try? Data(contentsOf: url),
                  let json = SolidPack.xzDecompress(blob) else { return (nil, 0) }
            return (parse(json), json.count)
        }
    }

    private static func parse(_ json: Data) -> [DailyReminderEntry]? {
        guard let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let rows = root["entries"] as? [[String: Any]] else { return nil }
        let entries = rows.compactMap { row -> DailyReminderEntry? in
            guard let id = row["id"] as? String, let rawKind = row["type"] as? String,
                  let kind = DailyReminderEntry.Kind(rawValue: rawKind) else { return nil }
            var link: DailyReminderEntry.HadithLink?
            if let raw = row["hadith"] as? String {
                let parts = raw.split(separator: ":").map(String.init)
                if parts.count == 2 { link = DailyReminderEntry.HadithLink(slug: parts[0], citation: parts[1]) }
            }
            return DailyReminderEntry(
                id: id, kind: kind,
                arabic: row["ar"] as? String ?? "",
                transliteration: row["tr"] as? String,
                short: row["short"] as? String ?? "",
                english: row["en"] as? String ?? "",
                source: row["source"] as? String ?? "",
                target: row["target"] as? String,
                surah: row["s"] as? Int, ayah: row["a"] as? Int,
                repeatCount: row["repeat"] as? Int,
                hadith: link)
        }
        return entries.isEmpty ? nil : entries
    }
}

// MARK: - Saved reflections

/// A daily card the reader chose to keep: the text as it read that day, with where it came from.
struct SavedReflection: Codable, Identifiable, Equatable {
    let id: String
    /// "<kind>:<source id>", so a card is kept at most once.
    let key: String
    let kind: String
    let arabic: String
    let english: String
    var transliteration: String? = nil
    let source: String
    var target: String? = nil
    var surah: Int? = nil
    var ayah: Int? = nil
    /// The narration a hadith card cites (its book slug and citation), so the kept copy still opens
    /// it. Absent on rows kept before 2026-09-07, which decode without it.
    var hadithSlug: String? = nil
    var hadithCitation: String? = nil
    let savedAt: Date

    static func key(kind: String, sourceID: String) -> String { "\(kind):\(sourceID)" }

    var hadithLink: DailyReminderEntry.HadithLink? {
        guard let hadithSlug, let hadithCitation else { return nil }
        return DailyReminderEntry.HadithLink(slug: hadithSlug, citation: hadithCitation)
    }

    var kindLabel: String {
        DailyReminderEntry.Kind(rawValue: kind)?.label ?? kind.capitalized
    }
}

final class SavedReflectionsStore: ObservableObject {
    static let shared = SavedReflectionsStore()

    @Published private(set) var items: [SavedReflection] = []
    private var keys: Set<String> = []
    private static let fileName = "reflections.json"

    private init() {
        ObjectPublishCounter.attach(self, label: "SavedReflectionsStore")
        guard let url = Self.fileURL, let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([SavedReflection].self, from: data) else { return }
        items = decoded
        keys = Set(decoded.map(\.key))
    }

    func has(_ key: String) -> Bool { keys.contains(key) }

    /// Keeps the draft, or drops the kept copy when it is already there. Returns whether it is now kept.
    @discardableResult
    func toggle(_ draft: SavedReflection) -> Bool {
        if keys.contains(draft.key) {
            items.removeAll { $0.key == draft.key }
            keys.remove(draft.key)
            save()
            return false
        }
        items.insert(draft, at: 0)
        keys.insert(draft.key)
        save()
        return true
    }

    func remove(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        keys.remove(items[index].key)
        items.remove(at: index)
        save()
    }

    private static var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName, isDirectory: false)
    }

    private func save() {
        guard let url = Self.fileURL else { return }
        let snapshot = items
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}

extension DailyReminderEntry {
    var reflectionKey: String { SavedReflection.key(kind: kind.rawValue, sourceID: id) }

    func reflectionDraft(arabic: String, english: String) -> SavedReflection {
        SavedReflection(id: UUID().uuidString, key: reflectionKey, kind: kind.rawValue,
                        arabic: arabic, english: english, transliteration: transliteration,
                        source: source, target: target, surah: surah, ayah: ayah,
                        hadithSlug: hadith?.slug, hadithCitation: hadith?.citation, savedAt: Date())
    }
}

// MARK: - The card

/// The Reminder of the Day card at the top of the Islam tab: the kind as an eyebrow, the text, the
/// source, and the two things to do with it (open where it lives, keep it). It is mounted in the
/// Islam root from launch, so it reads its accent and faces from the appearance snapshot and
/// observes only the reflections store (a publish per Save): observing `Settings` re-rendered it on
/// every publish (a location tick, a countdown), and observing `QuranData` on every load step.
struct ReminderOfTheDayCard: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var reflections = SavedReflectionsStore.shared

    let entry: DailyReminderEntry
    /// Whether the card is drawn as a List row (the Islam tab) or inside the daily sheet.
    var inSheet = false
    var onDismiss: (() -> Void)? = nil

    @State private var hadithLink: DailyReminderEntry.HadithLink?

    private var accent: Color { appearance.accent }

    var body: some View {
        let _ = RenderCounter.hit("ReminderOfTheDayCard")
        let texts = DailyReminderStore.shared.texts(for: entry)
        let target = DailyReminderTarget(encoded: entry.target)
        let kept = reflections.has(entry.reflectionKey)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                AccentIconChip(systemImage: entry.kind.symbol, size: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(inSheet ? "TODAY'S REMINDER" : "REMINDER OF THE DAY")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(entry.kind.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(accent)
                }
                Spacer(minLength: 8)
                if !inSheet, !reflections.items.isEmpty {
                    NavigationLink(destination: LazyDestination { SavedReflectionsView() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark.fill")
                            Text("\(reflections.items.count)")
                                .monospacedDigit()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(accent.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }

            if !texts.arabic.isEmpty {
                DailyReminderArabicText(text: texts.arabic, isQuran: entry.isQuranArabic, size: inSheet ? 30 : 24)
            }

            if let transliteration = entry.transliteration, !transliteration.isEmpty {
                Text(transliteration)
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !texts.english.isEmpty {
                Text(texts.english)
                    .font(inSheet ? .body : .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let repeatCount = entry.repeatCount, repeatCount > 1 {
                    Text("\(repeatCount)×")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(accent.opacity(0.12)))
                }
                Text(entry.source)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 16) {
                if let link = entry.hadith {
                    Button {
                        Settings.shared.hapticFeedback()
                        hadithLink = link
                    } label: {
                        Label("Read the hadith", systemImage: "text.book.closed")
                    }
                    .buttonStyle(.plain)
                } else if let target {
                    Button {
                        Settings.shared.hapticFeedback()
                        onDismiss?()
                        target.open()
                    } label: {
                        Label(target.buttonLabel, systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Settings.shared.hapticFeedback()
                    reflections.toggle(entry.reflectionDraft(arabic: texts.arabic, english: texts.english))
                } label: {
                    Label(kept ? "Saved" : "Save", systemImage: kept ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(accent)
            .padding(.top, 2)
        }
        .padding(.vertical, 6)
        .sheet(item: $hadithLink) { link in
            ReminderHadithSheet(link: link)
        }
    }
}

extension DailyReminderEntry.HadithLink: Identifiable {
    var id: String { "\(slug):\(citation)" }
}

/// Arabic in the face the text deserves: the reader's Quran face for a verse, the Islam tab's face
/// for a narration or a dua, both from the appearance snapshot (`Font.arabic` maps the system face
/// name to the rounded system font, as the old `useFontArabic` branch did).
struct DailyReminderArabicText: View {
    @Environment(\.appearance) private var appearance

    let text: String
    let isQuran: Bool
    var size: CGFloat = 24

    var body: some View {
        Group {
            if isQuran {
                Text(text)
                    .font(Font.arabic(appearance.quranArabicFontName, size: size))
                    .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
            } else {
                Text(text)
                    .font(Font.arabic(appearance.islamArabicFontName, size: size))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
            }
        }
        .multilineTextAlignment(.trailing)
        .lineSpacing(6)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - The once-a-day sheet

/// Today's reminder as a moment of its own: presented once per day as the app opens.
struct DailyReminderSheet: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.dismiss) private var dismiss

    let entry: DailyReminderEntry

    var body: some View {
        SheetNavigationContainer {
            List {
                Section {
                    ReminderOfTheDayCard(entry: entry, inSheet: true) { dismiss() }
                }
                .themedListRowBackground()

                Section(footer:
                    Text("A reminder arrives here once a day, the first time the app opens. Turn it off under Settings › Quran › Daily Cards; the card itself stays on the Islam tab.")
                        .font(.caption2)
                ) {
                    Button {
                        Settings.shared.hapticFeedback()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sami'na wa ata'na · We hear and we obey")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                    .foregroundColor(appearance.accent)
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("Reminder of the Day")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
    }
}

// MARK: - Saved reflections screen

struct SavedReflectionsView: View {
    @ObservedObject private var reflections = SavedReflectionsStore.shared
    /// The one sheet host for the rows' "Read the hadith" doors (one host per List, the app's rule).
    @State private var hadithLink: DailyReminderEntry.HadithLink?

    var body: some View {
        let _ = RenderCounter.hit("SavedReflectionsView")
        List {
            if reflections.items.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Nothing kept yet", systemImage: "bookmark")
                            .font(.subheadline.weight(.semibold))
                        Text("Tap Save on a Reminder of the Day to keep it here, with its source.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
                .themedListRowBackground()
            } else {
                Section(header: SectionPillHeader(title: "SAVED REFLECTIONS", count: reflections.items.count)) {
                    ForEach(reflections.items) { item in
                        SavedReflectionRow(item: item) { link in hadithLink = link }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    reflections.remove(id: item.id)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
                .themedListRowBackground()
            }
        }
        .applyConditionalListStyle()
        .navigationTitle("Saved Reflections")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $hadithLink) { link in
            ReminderHadithSheet(link: link)
        }
    }
}

private struct SavedReflectionRow: View {
    @Environment(\.appearance) private var appearance
    let item: SavedReflection
    /// Opens the narration a kept hadith card cites, in the List's sheet host.
    let onOpenHadith: (DailyReminderEntry.HadithLink) -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        let target = DailyReminderTarget(encoded: item.target)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.kindLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appearance.accent)
                Spacer()
                Text(Self.dateFormatter.string(from: item.savedAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !item.arabic.isEmpty {
                DailyReminderArabicText(text: item.arabic, isQuran: item.kind == "ayah", size: 22)
            }
            if let transliteration = item.transliteration, !transliteration.isEmpty {
                Text(transliteration)
                    .font(.caption.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !item.english.isEmpty {
                Text(item.english)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(item.source)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let link = item.hadithLink {
                Button {
                    Settings.shared.hapticFeedback()
                    onOpenHadith(link)
                } label: {
                    Label("Read the hadith", systemImage: "text.book.closed")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(appearance.accent)
                }
                .buttonStyle(.plain)
            } else if let target, item.kind != "hadith" {
                Button {
                    Settings.shared.hapticFeedback()
                    target.open()
                } label: {
                    Label(target.buttonLabel, systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(appearance.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - The hadith behind a card

/// The narration a hadith card cites, in the Hadith tab's own row, so the reader sees the grading
/// and can bookmark or share it from here.
struct ReminderHadithSheet: View {
    let link: DailyReminderEntry.HadithLink

    @State private var book: HadithCatalogBook?
    @State private var hadith: HadithBookData.Hadith?
    @State private var failed = false

    var body: some View {
        SheetNavigationContainer {
            List {
                if let book, let hadith {
                    Section {
                        HadithRow(book: book, hadith: hadith)
                    }
                } else if failed {
                    Text("This hadith could not be opened.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
            .applyConditionalListStyle()
            .navigationTitle(book?.englishTitle ?? "Hadith")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .smallMediumSheetPresentation(startLarge: true)
        .task {
            guard let found = HadithCatalogBook.all.first(where: { $0.slug == link.slug }) else {
                failed = true
                return
            }
            book = found
            let parts = link.parts
            guard let data = await HadithStore.shared.openOffMain(found),
                  let resolved = data.hadith(referenced: parts.number, suffix: parts.suffix) else {
                failed = true
                return
            }
            hadith = resolved
        }
    }
}
#endif
