// iCloud Backup is Al-Islam's alone: this file compiles only where `HAS_ICLOUD_BACKUP` is defined
// (Al-Islam's project settings). The companion apps never receive it (sync-manifests).
#if HAS_ICLOUD_BACKUP
import Foundation

/// The user's things, grouped the way a person would name them, over the manifest's content keys
/// and files (Docs/Engineering/iCloud Sync Guide.md, section 13). One table, five readers: the Reset dialog says
/// what it keeps, the Erase dialog says what it deletes, the iCloud page's What's Included shows what
/// this device would back up right now (with counts and the size), a restore previews the backup
/// against this device category by category, and a profile's one-line summary is the top of the same
/// counts. Every content key and file belongs to exactly one category, checked by
/// `Scripts/check_cloud_manifest.py`, so nothing can be backed up without a name the user can read.
///
/// Counting reads the JSON (or the plain property-list value) inside each blob generically, like the
/// merge rules do: nothing here names a bookmark or a prayer-mark type, so the file compiles in the
/// sibling apps, where a category for a feature they lack simply counts nothing.
struct ContentCategory: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    /// Standard-defaults keys, all in `Settings.contentStorageKeys`.
    let keys: [String]
    /// Documents files, all in `CloudManifest.files`.
    let files: [String]
    /// Where the category ranks in a profile's one-line summary; nil keeps it out of the line.
    let summaryRank: Int?
    /// How much of it a snapshot holds.
    let measure: (CloudSnapshot) -> Measure

    struct Measure {
        let count: Int
        let singular: String
        let plural: String
        /// "212 bookmarks", "1 journal entry". Zero reads as "None yet" on a page and is left out of
        /// a summary line. One whole phrase per category from the catalog, never a number glued to a
        /// noun: Arabic agrees the noun with the count (one, two, three to ten, eleven and up).
        let phrase: String

        static func formatted(_ count: Int) -> String {
            NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
        }
    }

    // MARK: The table

    static let all: [ContentCategory] = [
        ContentCategory(
            id: "bookmarks", title: String(localized: "Bookmarks"), systemImage: "bookmark.fill",
            keys: ["bookmarkedAyahsData", "hadithBookmarks", "savedSajdahAyahIDsData", "savedBrokenLetterAyahIDsData"],
            files: [], summaryRank: 1,
            measure: { $0.counted("bookmarkedAyahsData", "hadithBookmarks", "savedSajdahAyahIDsData", "savedBrokenLetterAyahIDsData")
                .measure(String(localized: "bookmark"), String(localized: "bookmarks")) { $0 == 1 ? String(localized: "1 bookmark") : String(localized: "\($0) bookmarks") } }),
        ContentCategory(
            id: "favorites", title: String(localized: "Favorites"), systemImage: "star.fill",
            keys: ["favoriteSurahsData", "favoriteReciterIDsData", "favoriteQiraahTagsData", "favoriteEnglishTranslationIDsData",
                   "favoriteLetterData", "favoriteNameNumbersData", "favoriteIslamResources",
                   "hadithFavoriteBooks", "hadithFavoriteChapters"],
            files: [], summaryRank: 6,
            measure: { $0.counted("favoriteSurahsData", "favoriteReciterIDsData", "favoriteQiraahTagsData", "favoriteEnglishTranslationIDsData",
                                  "favoriteLetterData", "favoriteNameNumbersData", "favoriteIslamResources",
                                  "hadithFavoriteBooks", "hadithFavoriteChapters")
                .measure(String(localized: "favorite"), String(localized: "favorites")) { $0 == 1 ? String(localized: "1 favorite") : String(localized: "\($0) favorites") } }),
        ContentCategory(
            id: "khatm", title: String(localized: "Khatm and Reading Plan"), systemImage: "checkmark.circle.fill",
            keys: ["khatmCompletedAyahsData", "quranPlanData", "quranRevisionPlanData", "quranRevisionRevisedData"],
            files: [], summaryRank: 3,
            measure: { $0.counted("khatmCompletedAyahsData").measure(String(localized: "khatm ayah"), String(localized: "khatm ayahs")) { $0 == 1 ? String(localized: "1 khatm ayah") : String(localized: "\($0) khatm ayahs") } }),
        ContentCategory(
            id: "positions", title: String(localized: "Reading and Listening"), systemImage: "book.fill",
            keys: ["lastReadSurah", "lastReadAyah", "lastReadTimestamp", "lastListenedAyahData", "lastListenedSurahData",
                   "quranReadingHistoryData", "quranListeningHistoryData", "quranAyahListeningHistoryData",
                   "customRangeHistoryData", "quranSearchHistoryData", "surahOpenCountsData", "surahPlayCountsData",
                   "hadithLastReadByBook", "hadithViewedLog", "hadithSearchHistoryData", "hadithOfTheDayHistory", "hadithBookCounts"],
            files: [], summaryRank: nil,
            measure: { snapshot in
                let history = snapshot.counted("quranReadingHistoryData", "quranListeningHistoryData", "quranAyahListeningHistoryData",
                                               "customRangeHistoryData", "hadithViewedLog")
                if history > 0 { return history.measure(String(localized: "history entry"), String(localized: "history entries")) { $0 == 1 ? String(localized: "1 history entry") : String(localized: "\($0) history entries") } }
                // A position alone, on a device that has not built a history yet.
                let positions = [snapshot.defaults["lastReadSurah"], snapshot.defaults["lastListenedSurahData"], snapshot.defaults["hadithLastReadByBook"]]
                    .filter { $0 != nil }.count
                return positions.measure(String(localized: "saved position"), String(localized: "saved positions")) { $0 == 1 ? String(localized: "1 saved position") : String(localized: "\($0) saved positions") }
            }),
        ContentCategory(
            id: "themes", title: String(localized: "Highlighted Themes"), systemImage: "highlighter",
            keys: ["themeHighlightsLit", "themeHighlightsAllSections", "themeHighlightsSections"],
            files: [], summaryRank: nil,
            measure: { $0.counted("themeHighlightsLit", "themeHighlightsSections").measure(String(localized: "highlight"), String(localized: "highlights")) { $0 == 1 ? String(localized: "1 highlight") : String(localized: "\($0) highlights") } }),
        ContentCategory(
            id: "tracker", title: String(localized: "Prayer Tracker"), systemImage: "calendar",
            keys: ["prayerTrackerData", "prayerTrackerExemptDaysData", "mensesPauseActive", "mensesPauseStartStamp"],
            files: [], summaryRank: 2,
            measure: { $0.counted("prayerTrackerData").measure(String(localized: "prayer day"), String(localized: "prayer days")) { $0 == 1 ? String(localized: "1 prayer day") : String(localized: "\($0) prayer days") } }),
        ContentCategory(
            id: "tasbih", title: String(localized: "Tasbih"), systemImage: "circle.grid.3x3.fill",
            keys: ["tasbihFreeCount", "tasbihPresetCounts", "tasbihFreeLabel", "tasbihLifetimeCount", "tasbihCountsByDay"],
            files: [], summaryRank: 5,
            measure: { $0.counted("tasbihLifetimeCount").measure(String(localized: "dhikr"), String(localized: "dhikr")) { $0 == 1 ? String(localized: "1 dhikr") : String(localized: "\($0) dhikr") } }),
        ContentCategory(
            id: "journal", title: String(localized: "Journal"), systemImage: "square.and.pencil",
            keys: [], files: ["journal.json"], summaryRank: 4,
            measure: { $0.countedFiles("journal.json").measure(String(localized: "journal entry"), String(localized: "journal entries")) { $0 == 1 ? String(localized: "1 journal entry") : String(localized: "\($0) journal entries") } }),
        ContentCategory(
            id: "reflections", title: String(localized: "Saved Reflections"), systemImage: "text.quote",
            keys: [], files: ["reflections.json"], summaryRank: nil,
            measure: { $0.countedFiles("reflections.json").measure(String(localized: "saved reflection"), String(localized: "saved reflections")) { $0 == 1 ? String(localized: "1 saved reflection") : String(localized: "\($0) saved reflections") } }),
        ContentCategory(
            id: "activity", title: String(localized: "Activity and Streaks"), systemImage: "flame.fill",
            keys: [], files: ["activity-log.json", "activity-log-watch.json"], summaryRank: nil,
            measure: { $0.countedFiles("activity-log.json", "activity-log-watch.json").measure(String(localized: "active day"), String(localized: "active days")) { $0 == 1 ? String(localized: "1 active day") : String(localized: "\($0) active days") } }),
        ContentCategory(
            id: "learning", title: String(localized: "Learning Progress"), systemImage: "graduationcap.fill",
            keys: ["readingTestProgress", "readingTestPlacement", "readingTestMissed", "readingTestSpeedBest",
                   "tajweedTestProgress", "tajweedTestPlacement", "tajweedTestMissed", "tajweedTestSpeedBest",
                   "tajweedLessonsDone", "letterQuizBestStreak", "duaSessionProgressData"],
            files: [], summaryRank: 8,
            measure: { snapshot in
                let lessons = snapshot.counted("tajweedLessonsDone")
                let tiers = ["readingTestProgress", "tajweedTestProgress"].reduce(0) { sum, key in
                    sum + (CloudJSON.dictionary(snapshot.defaults[key])?.values
                        .filter { (($0 as? [String: Any])?["mastered"] as? Bool) == true }.count ?? 0)
                }
                return (lessons + tiers).measure(String(localized: "lesson passed"), String(localized: "lessons passed")) { $0 == 1 ? String(localized: "1 lesson passed") : String(localized: "\($0) lessons passed") }
            }),
        ContentCategory(
            id: "reminders", title: String(localized: "Custom Reminders"), systemImage: "bell.badge.fill",
            keys: ["customReminders"],
            files: [], summaryRank: nil,
            measure: { $0.counted("customReminders").measure(String(localized: "custom reminder"), String(localized: "custom reminders")) { $0 == 1 ? String(localized: "1 custom reminder") : String(localized: "\($0) custom reminders") } }),
        ContentCategory(
            id: "achievements", title: String(localized: "Achievements"), systemImage: "rosette",
            keys: ["achievementUnlockedAt", "achievementsSeeded"],
            files: [], summaryRank: 7,
            measure: { $0.counted("achievementUnlockedAt").measure(String(localized: "badge"), String(localized: "badges")) { $0 == 1 ? String(localized: "1 badge") : String(localized: "\($0) badges") } }),
        ContentCategory(
            id: "calculators", title: String(localized: "Zakah and Inheritance Figures"), systemImage: "function",
            keys: ["zakahCash", "zakahGold", "zakahSilver", "zakahBusiness", "zakahTradeShares", "zakahLongShares",
                   "zakahOwedToYou", "zakahDebts", "zakahMetalPrice", "zakahGoldPrice", "zakahSilverPrice", "zakahNisab",
                   "zakahFitrPeople", "zakahFitrCost",
                   "faraidEstate", "faraidDebts", "faraidFuneral", "faraidBequest", "faraidCounts"],
            files: [], summaryRank: nil,
            measure: { snapshot in
                let typed = ["zakahCash", "zakahGold", "zakahSilver", "zakahBusiness", "zakahTradeShares", "zakahLongShares",
                             "zakahOwedToYou", "zakahDebts", "zakahMetalPrice", "zakahGoldPrice", "zakahSilverPrice", "zakahNisab",
                   "zakahFitrPeople", "zakahFitrCost",
                             "faraidEstate", "faraidDebts", "faraidFuneral", "faraidBequest", "faraidCounts"]
                    .filter { key in
                        guard let value = snapshot.defaults[key] else { return false }
                        if let number = value as? NSNumber { return number.doubleValue != 0 }
                        if let text = value as? String { return !text.isEmpty }
                        return true
                    }.count
                return typed.measure(String(localized: "figure entered"), String(localized: "figures entered")) { $0 == 1 ? String(localized: "1 figure entered") : String(localized: "\($0) figures entered") }
            }),
    ]

    // MARK: Sentences for the dialogs

    /// "bookmarks, favorites, khatm and reading plan, ... and zakah and inheritance figures".
    static var listSentence: String {
        let names = all.map { $0.title.lowercased() }
        guard let last = names.last, names.count > 1 else { return names.first ?? "" }
        return names.sentenceList { String(localized: "\($0.dropLast().joined(separator: ", ")) and \(last)") }
    }

    /// What the categories never include, in the user's words, for the What's Included page and
    /// the dialogs. Location first: the permission prompt's own promise.
    static let neverIncluded: [(title: String, detail: String, systemImage: String)] = [
        (String(localized: "Your location and saved places"), String(localized: "Your home city, favorite locations and the prayer times computed from them are never backed up: your location goes no further than it has to. A restored device finds its own."), "location.slash.fill"),
        (String(localized: "Downloaded recitations"), String(localized: "Audio you downloaded can be downloaded again, so it stays out of the backup."), "arrow.down.circle"),
        (String(localized: "Notifications scheduled here"), String(localized: "Each device schedules its own adhans and reminders from your settings; the schedule itself is not copied."), "bell.slash.fill"),
        (String(localized: "Prompts you have answered"), String(localized: "Which permissions and welcome screens this device has shown. A restored device is asked again where it needs to be."), "questionmark.circle"),
        (String(localized: "Ask AI conversations"), String(localized: "They are never saved, on the device or anywhere else."), "sparkles"),
        (String(localized: "Your Apple Watch's own copy"), String(localized: "The watch keeps its settings in step with this device on its own, and its reading days are counted through this device. It is not backed up separately."), "applewatch"),
    ]
}

// MARK: - Inventory

/// What a snapshot holds, category by category, with the settings count and the size beside it.
/// Built for this device (`ContentInventory.current()`) and for a downloaded backup, and compared
/// row by row in the restore preview.
struct ContentInventory {
    struct Row: Identifiable {
        let category: ContentCategory
        let measure: ContentCategory.Measure
        var id: String { category.id }
        var isEmpty: Bool { measure.count == 0 }
    }

    let rows: [Row]
    /// Preferences the snapshot carries: settings changed from their defaults on the source device.
    let settingsChanged: Int
    /// Compressed size of the snapshot, as it travels.
    let bytes: Int

    init(_ snapshot: CloudSnapshot, bytes: Int? = nil) {
        rows = ContentCategory.all.map { Row(category: $0, measure: $0.measure(snapshot)) }
        let preferences = CloudManifest.preferenceKeySet
        settingsChanged = snapshot.defaults.keys.filter { preferences.contains($0) }.count + snapshot.appGroup.count
        self.bytes = bytes ?? ((try? snapshot.encoded().count) ?? 0)
    }

    /// This device, right now (pending writes flushed first, like a real capture).
    @MainActor
    static func current() -> ContentInventory {
        ContentInventory(CloudSnapshot.capture(deviceID: "inventory"))
    }

    var sizeLine: String { ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file) }

    var settingsLine: String {
        settingsChanged == 0 ? String(localized: "No settings changed from their defaults") : (settingsChanged == 1 ? String(localized: "1 setting changed from the default") : String(localized: "\(settingsChanged) settings changed from the default"))
    }

    /// The profile picker's one line: the top-ranked non-empty categories, four at most. DISPLAY,
    /// in this device's language; the iCloud record stores `storedSummaryLine`.
    var summaryLine: String {
        let phrases = summaryRows.map { $0.measure.phrase }
        // Joined through the catalog, so Arabic reads its own comma ("،").
        return phrases.isEmpty ? String(localized: "Settings only")
            : phrases.dropFirst().reduce(phrases[0]) { String(localized: "\($0), \($1)") }
    }

    /// The same line in English, whatever this device's language: it is saved on the iCloud record
    /// (`Field.summary`) and read by every other device, and by app versions that predate the Arabic
    /// interface, so it is data and reads exactly as it always has ("212 bookmarks, 30 prayer days").
    var storedSummaryLine: String {
        let phrases = summaryRows.map { row -> String in
            guard let nouns = Self.englishNouns[row.category.id] else { return row.measure.phrase }
            let count = row.measure.count
            let number = Self.englishNumber.string(from: NSNumber(value: count)) ?? String(count)
            return "\(number) \(count == 1 ? nouns.singular : nouns.plural)"
        }
        return phrases.isEmpty ? "Settings only" : phrases.joined(separator: ", ")
    }

    private var summaryRows: ArraySlice<Row> {
        rows.filter { !$0.isEmpty && $0.category.summaryRank != nil }
            .sorted { ($0.category.summaryRank ?? 0) < ($1.category.summaryRank ?? 0) }
            .prefix(4)
    }

    /// The English nouns of every category with a `summaryRank`, by id: the table's own nouns are
    /// translated for display. A ranked category added later needs its pair here too.
    private static let englishNouns: [String: (singular: String, plural: String)] = [
        "bookmarks": ("bookmark", "bookmarks"),
        "tracker": ("prayer day", "prayer days"),
        "khatm": ("khatm ayah", "khatm ayahs"),
        "journal": ("journal entry", "journal entries"),
        "tasbih": ("dhikr", "dhikr"),
        "favorites": ("favorite", "favorites"),
        "achievements": ("badge", "badges"),
        "learning": ("lesson passed", "lessons passed"),
    ]

    /// Counts in the stored line as English writes them ("1,132"), not in this device's digits.
    private static let englishNumber: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        return formatter
    }()
}

// MARK: - Counting, generically

extension CloudSnapshot {
    /// The number of things under these keys: array elements, dictionary entries, the value of a
    /// plain count, the items of a comma-separated list. Sums across keys.
    func counted(_ keys: String...) -> Int {
        keys.reduce(0) { $0 + CloudJSON.count(defaults[$1]) }
    }

    func countedFiles(_ names: String...) -> Int {
        names.reduce(0) { $0 + CloudJSON.count(files[$1]) }
    }

    /// `summaryLine` in English, for the iCloud record (`ContentInventory.storedSummaryLine`).
    var storedSummaryLine: String { ContentInventory(self, bytes: 0).storedSummaryLine }
}

extension Int {
    /// `phrase` builds the whole counted phrase ("212 bookmarks") from the count.
    fileprivate func measure(_ singular: String, _ plural: String, _ phrase: (Int) -> String) -> ContentCategory.Measure {
        ContentCategory.Measure(count: self, singular: singular, plural: plural, phrase: phrase(self))
    }
}

extension CloudJSON {
    /// How many things a stored value holds; 0 for nothing there.
    static func count(_ value: Any?) -> Int {
        guard let value else { return 0 }
        let object: Any = (value is Data) ? (CloudJSON.object(value) ?? value) : value
        switch object {
        case let array as [Any]: return array.count
        case let dictionary as [String: Any]: return dictionary.count
        case let number as NSNumber:
            // A Bool ("all sections lit") counts as one thing when true.
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue ? 1 : 0 }
            return max(0, number.intValue)
        case let text as String:
            return text.split(separator: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        case let data as Data:
            return data.isEmpty ? 0 : 1
        default: return 0
        }
    }
}
#endif
