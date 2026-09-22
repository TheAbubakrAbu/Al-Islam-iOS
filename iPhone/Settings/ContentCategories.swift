import Foundation

/// The user's things, grouped the way a person would name them, over the manifest's content keys
/// and files (docs/iCloud Sync Guide.md, section 13). One table, five readers: the Reset dialog says
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
        /// a summary line.
        var phrase: String { "\(Self.formatted(count)) \(count == 1 ? singular : plural)" }

        static func formatted(_ count: Int) -> String {
            NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
        }
    }

    // MARK: The table

    static let all: [ContentCategory] = [
        ContentCategory(
            id: "bookmarks", title: "Bookmarks", systemImage: "bookmark.fill",
            keys: ["bookmarkedAyahsData", "hadithBookmarks", "savedSajdahAyahIDsData", "savedBrokenLetterAyahIDsData"],
            files: [], summaryRank: 1,
            measure: { $0.counted("bookmarkedAyahsData", "hadithBookmarks", "savedSajdahAyahIDsData", "savedBrokenLetterAyahIDsData")
                .measure("bookmark", "bookmarks") }),
        ContentCategory(
            id: "favorites", title: "Favorites", systemImage: "star.fill",
            keys: ["favoriteSurahsData", "favoriteReciterIDsData", "favoriteQiraahTagsData", "favoriteEnglishTranslationIDsData",
                   "favoriteLetterData", "favoriteNameNumbersData", "favoriteIslamResources",
                   "hadithFavoriteBooks", "hadithFavoriteChapters"],
            files: [], summaryRank: 6,
            measure: { $0.counted("favoriteSurahsData", "favoriteReciterIDsData", "favoriteQiraahTagsData", "favoriteEnglishTranslationIDsData",
                                  "favoriteLetterData", "favoriteNameNumbersData", "favoriteIslamResources",
                                  "hadithFavoriteBooks", "hadithFavoriteChapters")
                .measure("favorite", "favorites") }),
        ContentCategory(
            id: "khatm", title: "Khatm and Reading Plan", systemImage: "checkmark.circle.fill",
            keys: ["khatmCompletedAyahsData", "quranPlanData"],
            files: [], summaryRank: 3,
            measure: { $0.counted("khatmCompletedAyahsData").measure("khatm ayah", "khatm ayahs") }),
        ContentCategory(
            id: "positions", title: "Reading and Listening", systemImage: "book.fill",
            keys: ["lastReadSurah", "lastReadAyah", "lastReadTimestamp", "lastListenedAyahData", "lastListenedSurahData",
                   "quranReadingHistoryData", "quranListeningHistoryData", "quranAyahListeningHistoryData",
                   "quranSearchHistoryData", "surahOpenCountsData", "surahPlayCountsData",
                   "hadithLastReadByBook", "hadithViewedLog", "hadithSearchHistoryData", "hadithOfTheDayHistory", "hadithBookCounts"],
            files: [], summaryRank: nil,
            measure: { snapshot in
                let history = snapshot.counted("quranReadingHistoryData", "quranListeningHistoryData", "quranAyahListeningHistoryData", "hadithViewedLog")
                if history > 0 { return history.measure("history entry", "history entries") }
                // A position alone, on a device that has not built a history yet.
                let positions = [snapshot.defaults["lastReadSurah"], snapshot.defaults["lastListenedSurahData"], snapshot.defaults["hadithLastReadByBook"]]
                    .filter { $0 != nil }.count
                return positions.measure("saved position", "saved positions")
            }),
        ContentCategory(
            id: "themes", title: "Highlighted Themes", systemImage: "highlighter",
            keys: ["themeHighlightsLit", "themeHighlightsAllSections", "themeHighlightsSections"],
            files: [], summaryRank: nil,
            measure: { $0.counted("themeHighlightsLit", "themeHighlightsSections").measure("highlight", "highlights") }),
        ContentCategory(
            id: "tracker", title: "Prayer Tracker", systemImage: "calendar",
            keys: ["prayerTrackerData", "prayerTrackerExemptDaysData", "mensesPauseActive", "mensesPauseStartStamp"],
            files: [], summaryRank: 2,
            measure: { $0.counted("prayerTrackerData").measure("prayer day", "prayer days") }),
        ContentCategory(
            id: "tasbih", title: "Tasbih", systemImage: "circle.grid.3x3.fill",
            keys: ["tasbihFreeCount", "tasbihPresetCounts", "tasbihFreeLabel", "tasbihLifetimeCount", "tasbihCountsByDay"],
            files: [], summaryRank: 5,
            measure: { $0.counted("tasbihLifetimeCount").measure("dhikr", "dhikr") }),
        ContentCategory(
            id: "journal", title: "Journal", systemImage: "square.and.pencil",
            keys: [], files: ["journal.json"], summaryRank: 4,
            measure: { $0.countedFiles("journal.json").measure("journal entry", "journal entries") }),
        ContentCategory(
            id: "reflections", title: "Saved Reflections", systemImage: "text.quote",
            keys: [], files: ["reflections.json"], summaryRank: nil,
            measure: { $0.countedFiles("reflections.json").measure("saved reflection", "saved reflections") }),
        ContentCategory(
            id: "activity", title: "Activity and Streaks", systemImage: "flame.fill",
            keys: [], files: ["activity-log.json", "activity-log-watch.json"], summaryRank: nil,
            measure: { $0.countedFiles("activity-log.json", "activity-log-watch.json").measure("active day", "active days") }),
        ContentCategory(
            id: "learning", title: "Learning Progress", systemImage: "graduationcap.fill",
            keys: ["readingTestProgress", "readingTestPlacement", "tajweedLessonsDone", "letterQuizBestStreak", "duaSessionProgressData"],
            files: [], summaryRank: 8,
            measure: { snapshot in
                let lessons = snapshot.counted("tajweedLessonsDone")
                let tiers = CloudJSON.dictionary(snapshot.defaults["readingTestProgress"])?.values
                    .filter { (($0 as? [String: Any])?["mastered"] as? Bool) == true }.count ?? 0
                return (lessons + tiers).measure("lesson passed", "lessons passed")
            }),
        ContentCategory(
            id: "reminders", title: "Custom Reminders", systemImage: "bell.badge.fill",
            keys: ["customReminders"],
            files: [], summaryRank: nil,
            measure: { $0.counted("customReminders").measure("custom reminder", "custom reminders") }),
        ContentCategory(
            id: "achievements", title: "Achievements", systemImage: "rosette",
            keys: ["achievementUnlockedAt", "achievementsSeeded"],
            files: [], summaryRank: 7,
            measure: { $0.counted("achievementUnlockedAt").measure("badge", "badges") }),
        ContentCategory(
            id: "calculators", title: "Zakah and Inheritance Figures", systemImage: "function",
            keys: ["zakahCash", "zakahGold", "zakahSilver", "zakahBusiness", "zakahTradeShares", "zakahLongShares",
                   "zakahOwedToYou", "zakahDebts", "zakahMetalPrice", "zakahNisab", "zakahFitrPeople", "zakahFitrCost",
                   "faraidEstate", "faraidDebts", "faraidFuneral", "faraidBequest", "faraidCounts"],
            files: [], summaryRank: nil,
            measure: { snapshot in
                let typed = ["zakahCash", "zakahGold", "zakahSilver", "zakahBusiness", "zakahTradeShares", "zakahLongShares",
                             "zakahOwedToYou", "zakahDebts", "zakahMetalPrice", "zakahNisab", "zakahFitrPeople", "zakahFitrCost",
                             "faraidEstate", "faraidDebts", "faraidFuneral", "faraidBequest", "faraidCounts"]
                    .filter { key in
                        guard let value = snapshot.defaults[key] else { return false }
                        if let number = value as? NSNumber { return number.doubleValue != 0 }
                        if let text = value as? String { return !text.isEmpty }
                        return true
                    }.count
                return typed.measure("figure entered", "figures entered")
            }),
    ]

    // MARK: Sentences for the dialogs

    /// "bookmarks, favorites, khatm and reading plan, ... and zakah and inheritance figures".
    static var listSentence: String {
        let names = all.map { $0.title.lowercased() }
        guard let last = names.last, names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " and " + last
    }

    /// What the categories never include, in the user's words, for the What's Included page and
    /// the dialogs. Location first: the permission prompt's own promise.
    static let neverIncluded: [(title: String, detail: String, systemImage: String)] = [
        ("Your location and saved places", "The app promises that your location stays on your device, so your home city, favorite locations and the prayer times computed from them are never backed up. A restored device finds its own.", "location.slash.fill"),
        ("Downloaded recitations", "Audio you downloaded can be downloaded again, so it stays out of the backup.", "arrow.down.circle"),
        ("Notifications scheduled here", "Each device schedules its own adhans and reminders from your settings; the schedule itself is not copied.", "bell.slash.fill"),
        ("Prompts you have answered", "Which permissions and welcome screens this device has shown. A restored device is asked again where it needs to be.", "questionmark.circle"),
        ("Ask AI conversations", "They are never saved, on the device or anywhere else.", "sparkles"),
        ("Your Apple Watch's own copy", "The watch keeps its settings in step with this device on its own, and its reading days are counted through this device. It is not backed up separately.", "applewatch"),
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
        settingsChanged == 0 ? "No settings changed from their defaults" : "\(settingsChanged) setting\(settingsChanged == 1 ? "" : "s") changed from the default"
    }

    /// The profile picker's one line: the top-ranked non-empty categories, four at most.
    var summaryLine: String {
        let ranked = rows.filter { !$0.isEmpty && $0.category.summaryRank != nil }
            .sorted { ($0.category.summaryRank ?? 0) < ($1.category.summaryRank ?? 0) }
        let phrases = ranked.prefix(4).map { $0.measure.phrase }
        return phrases.isEmpty ? "Settings only" : phrases.joined(separator: ", ")
    }
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
}

extension Int {
    fileprivate func measure(_ singular: String, _ plural: String) -> ContentCategory.Measure {
        ContentCategory.Measure(count: self, singular: singular, plural: plural)
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
