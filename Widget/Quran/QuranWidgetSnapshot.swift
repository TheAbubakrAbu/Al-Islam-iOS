import Foundation

// MARK: - Quran widget shared data
//
// Lightweight, fully-rendered payloads the main app writes to the App Group so the Quran widgets can
// display instantly without loading Quran.json or the (async-loading) `QuranData` in the extension. The app
// rebuilds this whenever last-read / last-listened state changes (see `Settings.refreshQuranWidgets`).
//
// Lives in the Widget/Quran area (next to `QuranProvider`) rather than in Globals, but is a member of every
// target - the app/watch/complication write it and the widget reads it.
struct QuranWidgetSnapshot: Codable {
    /// A tajweed color span over the Arabic text, in UTF-16 offsets, with the color as 0–1 RGB. Plain
    /// `Codable` so it survives the App Group without serializing SwiftUI/UIKit color objects.
    struct ColorRun: Codable {
        let start: Int
        let length: Int
        let r: Double
        let g: Double
        let b: Double
    }

    struct AyahCard: Codable {
        let arabic: String
        let reference: String
        let english: String
        /// PostScript name of the Arabic font to render `arabic` with (e.g. the Uthmani font). Optional so
        /// older snapshots still decode.
        var fontName: String?
        /// Tajweed color spans over `arabic` (empty/nil when tajweed is off). Base text stays adaptive.
        var colorRuns: [ColorRun]?
    }
    struct ListenCard: Codable {
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

    /// The shared day bucket the app and the widget both key the Ayah of the Day on. UTC-based on purpose:
    /// it only has to be *consistent* between the writer and the reader, and match `ayahOfTheDayReference`.
    static func dayBucket(for date: Date = Date()) -> Int {
        Int(date.timeIntervalSince1970 / 86_400)
    }

    init(
        lastRead: AyahCard? = nil,
        lastListened: ListenCard? = nil,
        lastListenedAyah: AyahCard? = nil,
        ayahOfTheDay: AyahCard? = nil,
        ayahOfTheDayDay: Int? = nil,
        randomPool: [AyahCard] = []
    ) {
        self.lastRead = lastRead
        self.lastListened = lastListened
        self.lastListenedAyah = lastListenedAyah
        self.ayahOfTheDay = ayahOfTheDay
        self.ayahOfTheDayDay = ayahOfTheDayDay
        self.randomPool = randomPool
    }
}

enum QuranWidgetStore {
    private static let key = "quranWidgetSnapshot"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName) }

    static func load() -> QuranWidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(QuranWidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: QuranWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: key)
    }
}
