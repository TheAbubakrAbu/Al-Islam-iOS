import Foundation

// MARK: - Quran widget shared data
//
// Lightweight, fully-rendered payloads the main app writes to the App Group so the Quran widgets can
// display instantly without loading Quran.json or the (async-loading) `QuranData` in the extension. The app
// rebuilds this whenever last-read / last-listened state changes (see `Settings.refreshQuranWidgets`).
//
// Lives in the Widget/Quran area (next to `QuranProvider`) rather than in Globals, but is a member of every
// target - the app/watch/complication write it and the widget reads it.
//
// The daily corpus (the Reminder of the Day cards and the 99 names) is NOT in here: it has its own
// blob, `DailyWidgetSnapshot` below, written once a day. It used to sit inside this one, which meant
// every settled last-read change re-encoded 180 cards it had not touched and every Quran-family
// provider decoded them on every timeline request.
struct QuranWidgetSnapshot: Codable {
    /// A tajweed color span over the Arabic text, in UTF-16 offsets, with the color as 0–1 RGB. Plain
    /// `Codable` so it survives the App Group without serializing SwiftUI/UIKit color objects.
    struct ColorRun: Codable, Equatable {
        let start: Int
        let length: Int
        let r: Double
        let g: Double
        let b: Double
    }

    struct AyahCard: Codable, Equatable {
        let arabic: String
        let reference: String
        let english: String
        /// PostScript name of the Arabic font to render `arabic` with (e.g. the Uthmani font). Optional so
        /// older snapshots still decode.
        var fontName: String?
        /// Tajweed color spans over `arabic` (empty/nil when tajweed is off). Base text stays adaptive.
        var colorRuns: [ColorRun]?
        /// Where the card is from, so a tap on the widget opens that ayah (`QuranDeepLink`). Optional:
        /// cards written before 2026-09-28 have none and open the app where it last was.
        var surah: Int?
        var ayah: Int?
    }
    /// One bookmark, as the Chosen Ayah widget's picker lists it: the reference, the note and a short
    /// translation, never the Arabic (the picker is a list of names, the widget renders the text).
    struct BookmarkCard: Codable, Equatable {
        let surah: Int
        let ayah: Int
        let note: String?
        /// The Saheeh International translation, clipped for a picker row.
        let english: String
        let createdAt: Date?
    }
    /// An ayah a placed Chosen Ayah widget asked for, rendered by the app with the reader's settings.
    struct ChosenCard: Codable, Equatable {
        let surah: Int
        let ayah: Int
        let card: AyahCard
    }
    struct ListenCard: Codable, Equatable {
        let name: String
        let reciter: String
        let current: Double
        let full: Double
    }
    var lastRead: AyahCard?
    var lastListened: ListenCard?
    /// The last individual ayah listened to (single ayah / custom range). Optional so older snapshots decode.
    var lastListenedAyah: AyahCard?
    /// Today's deterministic Ayah of the Day. Optional so older snapshots decode.
    var ayahOfTheDay: AyahCard?
    /// The day bucket `ayahOfTheDay` was built for. Without it, a card written days ago (app never opened
    /// since) shadowed the widget's daily fallback rotation and the "Ayah of the Day" never changed.
    /// Optional so older snapshots decode; nil is treated as unknown/stale by the widget.
    var ayahOfTheDayDay: Int?
    var randomPool: [AyahCard]

    /// Fajr for the coming days keyed by calendar day ("yyyy-MM-dd"), so the Ayah of the Day widget
    /// turns its day over when the app does (DailyRollover). Empty when the boundary is midnight.
    /// (A snapshot written before 2026-09-07 also carried `dailyReminders` and `nameCards`; those keys
    /// are ignored on decode and dropped by the next save.)
    var fajrByDay: [String: TimeInterval]?

    /// The bookmarks, in mushaf order, for the Chosen Ayah widget's picker (2026-09-28). nil until
    /// the app has written a snapshot on a build that knows them.
    var bookmarks: [BookmarkCard]?
    /// The ayahs the placed Chosen Ayah widgets show, pre-rendered by the app (font, tajweed, clean
    /// text) so the widget draws them exactly as the reader would.
    var chosenAyahs: [ChosenCard]?
    /// The reader's Arabic face when the snapshot was written, for an ayah the widget has to typeset
    /// itself (one chosen while the app was not running, before the app pre-renders it).
    var arabicFontName: String?

    init(
        lastRead: AyahCard? = nil,
        lastListened: ListenCard? = nil,
        lastListenedAyah: AyahCard? = nil,
        ayahOfTheDay: AyahCard? = nil,
        ayahOfTheDayDay: Int? = nil,
        randomPool: [AyahCard] = [],
        fajrByDay: [String: TimeInterval]? = nil
    ) {
        self.lastRead = lastRead
        self.lastListened = lastListened
        self.lastListenedAyah = lastListenedAyah
        self.ayahOfTheDay = ayahOfTheDay
        self.ayahOfTheDayDay = ayahOfTheDayDay
        self.randomPool = randomPool
        self.fajrByDay = fajrByDay
    }

    /// The pre-rendered card for one ayah, if a placed widget asked for it.
    func chosenCard(surah: Int, ayah: Int) -> AyahCard? {
        chosenAyahs?.first { $0.surah == surah && $0.ayah == ayah }?.card
    }

    /// Today's index under the daily boundary the app wrote (Fajr by default), or plain local days.
    static func dailyDayIndex(for date: Date = Date(), fajrByDay: [String: TimeInterval]?) -> Int {
        DailyRollover.dayIndex(for: date, fajrByDay: fajrByDay)
    }
}

/// The app's URL scheme, as the Quran widgets use it: a tap on an ayah widget opens that ayah
/// (`MainTabView.onOpenURL` routes it through `AppNavigation`). Registered in Info-Main.plist.
enum QuranDeepLink {
    static let scheme = "alislam"

    /// `alislam://ayah/2/255`
    static func ayah(surah: Int, ayah: Int) -> URL? {
        URL(string: "\(scheme)://ayah/\(surah)/\(ayah)")
    }

    /// The surah and ayah of an `ayah` link, or nil for any other URL.
    static func parseAyah(_ url: URL) -> (surah: Int, ayah: Int)? {
        guard url.scheme?.lowercased() == scheme, url.host?.lowercased() == "ayah" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2, let surah = Int(parts[0]), let ayah = Int(parts[1]) else { return nil }
        return (surah, ayah)
    }
}

enum QuranWidgetStore {
    private static let key = "quranWidgetSnapshot"
    /// One suite per process: `UserDefaults(suiteName:)` builds a fresh object (and its cfprefsd
    /// connection) on every call, and this used to be a computed property hit on every load and save.
    static let defaults: UserDefaults? = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

    /// Decoded once per distinct blob (Phase 10.9): a reload burst decodes the same App Group bytes
    /// from every Quran-family provider, twice for Ayah of the Day. Thread-safe (the app saves from a
    /// detached build and the extension reads from its timeline queue).
    private static let decoder = JSONDecoder()
    private static let memoLock = NSLock()
    nonisolated(unsafe) private static var memo: (data: Data, snapshot: QuranWidgetSnapshot?)?

    static func load() -> QuranWidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        memoLock.lock()
        if let memo, memo.data == data { memoLock.unlock(); return memo.snapshot }
        memoLock.unlock()
        let snapshot = try? decoder.decode(QuranWidgetSnapshot.self, from: data)
        memoLock.lock(); memo = (data, snapshot); memoLock.unlock()
        return snapshot
    }

    static func save(_ snapshot: QuranWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: key)
        #if DEBUG
        if Settings.debugPublishCounterEnabled { NSLog("SNAPSHOT quran %d bytes", data.count) }
        #endif
    }
}

// MARK: - The daily widgets' shared data

/// What the Reminder of the Day and Name of Allah widgets read: the whole corpus of both, fully
/// rendered, plus the Fajr table that decides which day it is. The app writes it once a day
/// (`DailyReminderStore.refreshWidgets`), off the main thread, and the widgets pick the day's entry
/// themselves by the shared day index, so they keep telling the truth on a day the app never opened.
struct DailyWidgetSnapshot: Codable {
    /// One Reminder of the Day card.
    struct ReminderCard: Codable {
        let id: String
        let kind: String
        let kindLabel: String
        let arabic: String
        let english: String
        let short: String
        let source: String
        /// PostScript name of the face for a Quran verse; nil for a narration or a dua.
        var fontName: String?
    }

    /// One of the 99 Names.
    struct NameCard: Codable {
        let number: Int
        let arabic: String
        let transliteration: String
        let meaning: String
        let living: String
        /// PostScript name of the Islam tab's Arabic face, so the widget draws the name the way the app
        /// does; nil for the system face. Optional so the first daily blobs still decode.
        var fontName: String?
    }

    /// The Reminder of the Day corpus in order.
    var reminders: [ReminderCard]
    /// The 99 names in order.
    var names: [NameCard]
    /// Fajr keyed by calendar day ("yyyy-MM-dd"); empty when the boundary is midnight.
    var fajrByDay: [String: TimeInterval]?
    /// The daily-rollover day key the blob was written on.
    var writtenDay: String?
    /// The app's own pick for `resolvedDayIndex` (the Ayah / Hadith / Dua / Name of the Day the
    /// in-app card shows that day, see `DailyReminderResolver`): the widget shows it on that day
    /// only and walks the corpus on every other. Optional so older blobs decode.
    var resolved: ReminderCard?
    var resolvedDayIndex: Int?

    init(reminders: [ReminderCard] = [], names: [NameCard] = [], fajrByDay: [String: TimeInterval]? = nil, writtenDay: String? = nil) {
        self.reminders = reminders
        self.names = names
        self.fajrByDay = fajrByDay
        self.writtenDay = writtenDay
    }
}

enum DailyWidgetStore {
    private static let key = "dailyWidgetSnapshot"

    private static let decoder = JSONDecoder()
    private static let memoLock = NSLock()
    nonisolated(unsafe) private static var memo: (data: Data, snapshot: DailyWidgetSnapshot?)?

    static func load() -> DailyWidgetSnapshot? {
        guard let data = QuranWidgetStore.defaults?.data(forKey: key) else { return nil }
        memoLock.lock()
        if let memo, memo.data == data { memoLock.unlock(); return memo.snapshot }
        memoLock.unlock()
        let snapshot = try? decoder.decode(DailyWidgetSnapshot.self, from: data)
        memoLock.lock(); memo = (data, snapshot); memoLock.unlock()
        return snapshot
    }

    /// Thread-safe (UserDefaults is); the app calls it from the detached build.
    static func save(_ snapshot: DailyWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        QuranWidgetStore.defaults?.set(data, forKey: key)
        #if DEBUG
        if Settings.debugPublishCounterEnabled { NSLog("SNAPSHOT daily %d bytes", data.count) }
        #endif
    }
}
