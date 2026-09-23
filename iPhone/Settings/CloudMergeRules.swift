// iCloud Backup is Al-Islam's alone: this file compiles only where `HAS_ICLOUD_BACKUP` is defined
// (Al-Islam's project settings). The companion apps never receive it (sync-manifests).
#if HAS_ICLOUD_BACKUP
import Foundation

/// How a Merge restore combines a backup's content with what this device already holds
/// (docs/iCloud Sync Guide.md, section 7). One rule per content key, applied to the JSON (or the
/// plain property-list value) inside each blob, generically: nothing here names a bookmark or a
/// prayer mark type, which is what lets the file compile in the sibling apps that lack them.
///
/// The spirit of every rule: a Merge ADDS. Nothing this device holds is lost to it, and where the
/// two sides disagree about the same thing the better-informed side wins (the newer edit, the
/// larger count, the mark that says more). What a Merge cannot know is that something was deleted
/// on purpose, so a bookmark removed here and still in the backup comes back; that is what "add
/// the backup's things to this device" means, and the restore sheet says so.
///
/// A key with no rule is left alone (`keepLocal`), which is the safe reading of "not decided yet".
enum CloudMergeRules {
    enum Rule {
        /// An array of strings or numbers, as a set. Local order first, then what is new.
        case unionScalars(cap: Int?)
        /// An array of objects, matched on `identity` (dotted paths reach into nested objects). On a
        /// match the side with the later `stamp` wins and takes any field it lacks from the other
        /// (a note, a highlight); with no stamp to compare, the local one wins. `newestFirst`
        /// re-sorts the union by the stamp, for the lists the app shows newest first.
        case unionObjects(identity: [String], stamp: String?, newestFirst: Bool, cap: Int?)
        case maxNumber
        /// A dictionary of counts (nested dictionaries merge the same way): per key, the larger.
        case maxPerKey
        /// A dictionary of dates as numbers where 0 means "earned, date unknown": the earlier real
        /// date wins, and a real date beats an unknown one.
        case earliestKnownPerKey
        /// `[day: [prayer: mark]]` (or the legacy `[day: [prayer]]`): per day and prayer, the mark
        /// that ranks higher, the app's own rule for two answers about one prayer (`PrayerMark.rank`).
        case prayerMarks
        /// One object with a date field: the later one.
        case newerObject(stamp: String)
        /// A dictionary of such objects: per key, the later one.
        case newerPerKey(stamp: String)
        /// The Reading Test ladder: per tier the best score, the most attempts, mastered if either.
        case readingLadder
        case eitherTrue
        /// A comma-separated list, as a set.
        case unionCSV
        /// Taken only when this device has nothing there (absent, empty, or zero): figures typed in
        /// here are never overwritten by figures typed somewhere else.
        case fillIfMissing
        case keepLocal
    }

    static let rules: [String: Rule] = [
        // Quran
        "favoriteSurahsData": .unionScalars(cap: nil),
        "bookmarkedAyahsData": .unionObjects(identity: ["surah", "ayah"], stamp: "createdAt", newestFirst: false, cap: nil),
        "khatmCompletedAyahsData": .unionScalars(cap: nil),
        "quranPlanData": .fillIfMissing,
        "favoriteReciterIDsData": .unionScalars(cap: nil),
        "favoriteQiraahTagsData": .unionScalars(cap: nil),
        "favoriteEnglishTranslationIDsData": .unionScalars(cap: nil),
        "savedSajdahAyahIDsData": .unionScalars(cap: nil),
        "savedBrokenLetterAyahIDsData": .unionScalars(cap: nil),
        "lastListenedAyahData": .newerObject(stamp: "savedAt"),
        "lastListenedSurahData": .newerObject(stamp: "savedAt"),
        "quranSearchHistoryData": .unionScalars(cap: 10),
        "quranListeningHistoryData": .unionObjects(identity: ["surahNumber", "reciter.name"], stamp: "timestamp", newestFirst: true, cap: 10),
        "quranReadingHistoryData": .unionObjects(identity: ["surahNumber", "ayahNumber"], stamp: "timestamp", newestFirst: true, cap: 10),
        "quranAyahListeningHistoryData": .unionObjects(identity: ["surahNumber", "ayahNumber", "reciter.name"], stamp: "timestamp", newestFirst: true, cap: 10),
        "themeHighlightsLit": .unionObjects(identity: ["id"], stamp: nil, newestFirst: false, cap: 7),
        "themeHighlightsAllSections": .eitherTrue,
        "themeHighlightsSections": .unionScalars(cap: nil),
        "surahOpenCountsData": .maxPerKey,
        "surahPlayCountsData": .maxPerKey,
        // Prayer tracker. The menses pause and the last-read position are groups of keys that only
        // make sense together; `merged(local:incoming:)` moves each as one.
        "prayerTrackerData": .prayerMarks,
        "prayerTrackerExemptDaysData": .unionScalars(cap: nil),
        // Hadith
        "hadithFavoriteBooks": .unionScalars(cap: nil),
        "hadithFavoriteChapters": .unionScalars(cap: nil),
        "hadithBookmarks": .unionObjects(identity: ["slug", "idInBook"], stamp: "createdAt", newestFirst: false, cap: nil),
        "hadithLastReadByBook": .newerPerKey(stamp: "timestamp"),
        "hadithSearchHistoryData": .unionScalars(cap: 10),
        "hadithOfTheDayHistory": .unionObjects(identity: ["dayKey"], stamp: "date", newestFirst: true, cap: 5),
        "hadithViewedLog": .unionObjects(identity: ["slug", "idInBook", "viewedAt"], stamp: "viewedAt", newestFirst: true, cap: 200),
        // A book's chapter and hadith counts are read off the bundled pack; nothing to merge.
        "hadithBookCounts": .keepLocal,
        // Tasbih. The lifetime total takes the larger side, not the sum: a device restored from
        // this very backup last month would otherwise count every dhikr twice.
        "tasbihFreeCount": .maxNumber,
        "tasbihPresetCounts": .maxPerKey,
        "tasbihLifetimeCount": .maxNumber,
        "tasbihCountsByDay": .maxPerKey,
        "tasbihFreeLabel": .fillIfMissing,
        // Islam tab
        "favoriteLetterData": .unionObjects(identity: ["id"], stamp: nil, newestFirst: false, cap: nil),
        "favoriteNameNumbersData": .unionScalars(cap: nil),
        "favoriteIslamResources": .unionCSV,
        "readingTestProgress": .readingLadder,
        "readingTestPlacement": .fillIfMissing,
        "tajweedLessonsDone": .unionScalars(cap: nil),
        "letterQuizBestStreak": .maxNumber,
        "duaSessionProgressData": .maxPerKey,
        "customReminders": .unionObjects(identity: ["id"], stamp: nil, newestFirst: false, cap: nil),
        "achievementUnlockedAt": .earliestKnownPerKey,
        "achievementsSeeded": .eitherTrue,
        // Calculators
        "zakahCash": .fillIfMissing, "zakahGold": .fillIfMissing, "zakahSilver": .fillIfMissing,
        "zakahBusiness": .fillIfMissing, "zakahTradeShares": .fillIfMissing, "zakahLongShares": .fillIfMissing,
        "zakahOwedToYou": .fillIfMissing, "zakahDebts": .fillIfMissing, "zakahMetalPrice": .fillIfMissing,
        "zakahNisab": .fillIfMissing, "zakahFitrPeople": .fillIfMissing, "zakahFitrCost": .fillIfMissing,
        "faraidEstate": .fillIfMissing, "faraidDebts": .fillIfMissing, "faraidFuneral": .fillIfMissing,
        "faraidBequest": .fillIfMissing, "faraidCounts": .fillIfMissing,
    ]

    static let fileRules: [String: Rule] = [
        "journal.json": .unionObjects(identity: ["id"], stamp: "updatedAt", newestFirst: false, cap: nil),
        "reflections.json": .unionObjects(identity: ["key"], stamp: "savedAt", newestFirst: true, cap: nil),
        "activity-log.json": .maxPerKey,
        "activity-log-watch.json": .maxPerKey,
    ]

    /// Keys that travel as a group, moved by `merged(local:incoming:)` and skipped by the per-key pass.
    private static let lastReadKeys = ["lastReadSurah", "lastReadAyah", "lastReadTimestamp"]
    private static let mensesKeys = ["mensesPauseActive", "mensesPauseStartStamp"]

    // MARK: Entry points

    /// The content keys whose value changes under a Merge, with the value to write. A key missing
    /// from the result stays exactly as it is (its bytes untouched).
    static func merged(local: [String: Any], incoming: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]

        // The last-read position is three keys and one fact: the later stamp takes all three.
        let localStamp = (local["lastReadTimestamp"] as? NSNumber)?.doubleValue ?? 0
        let incomingStamp = (incoming["lastReadTimestamp"] as? NSNumber)?.doubleValue ?? 0
        let localHasPosition = ((local["lastReadSurah"] as? NSNumber)?.intValue ?? 0) > 0
        if incoming["lastReadSurah"] != nil, incomingStamp > localStamp || !localHasPosition {
            for key in lastReadKeys { if let value = incoming[key] { result[key] = value } }
        }

        // A menses pause is a switch and the day it began: taken whole, and only onto a device
        // that has never recorded one.
        if local["mensesPauseStartStamp"] == nil, local["mensesPauseActive"] == nil {
            for key in mensesKeys { if let value = incoming[key] { result[key] = value } }
        }

        let grouped = Set(lastReadKeys + mensesKeys)
        for key in CloudManifest.contentKeys where !grouped.contains(key) {
            guard let theirs = incoming[key] else { continue }
            let rule = rules[key] ?? .keepLocal
            if case .keepLocal = rule { continue }
            guard let ours = local[key] else {
                result[key] = theirs
                continue
            }
            if let value = merge(ours, theirs, rule) { result[key] = value }
        }
        return result
    }

    /// The merged bytes of a Documents file, or nil when the local file already says everything.
    static func mergedFile(_ name: String, local: Data?, incoming: Data) -> Data? {
        guard let local, !local.isEmpty else { return incoming }
        guard let rule = fileRules[name] else { return nil }
        return merge(local, incoming, rule) as? Data
    }

    // MARK: The engine

    /// A stored value is either JSON inside `Data` or a plain property-list value; the rules work on
    /// the object either way, and the result goes back into the container it came out of.
    private static func merge(_ ours: Any, _ theirs: Any, _ rule: Rule) -> Any? {
        let oursIsJSON = ours is Data
        guard let oursObject = unwrapped(ours), let theirsObject = unwrapped(theirs),
              let merged = mergeObjects(oursObject, theirsObject, rule) else { return nil }
        // Unchanged in meaning: leave the local bytes alone rather than rewriting them in a new key order.
        if let object = merged as? NSObject, object.isEqual(oursObject) { return nil }
        if oursIsJSON { return CloudJSON.data(merged) }
        return merged
    }

    /// The JSON inside a blob, or the property-list value as it is.
    private static func unwrapped(_ value: Any) -> Any? {
        if value is Data { return CloudJSON.object(value) }
        return value
    }

    private static func mergeObjects(_ ours: Any, _ theirs: Any, _ rule: Rule) -> Any? {
        switch rule {
        case .keepLocal:
            return nil

        case .unionScalars(let cap):
            guard let ours = ours as? [Any], let theirs = theirs as? [Any] else { return nil }
            var seen = Set(ours.compactMap { $0 as? AnyHashable })
            var out = ours
            for element in theirs {
                guard let hashable = element as? AnyHashable, seen.insert(hashable).inserted else { continue }
                out.append(element)
            }
            return cap.map { Array(out.prefix($0)) } ?? out

        case .unionObjects(let identity, let stamp, let newestFirst, let cap):
            guard let ours = ours as? [[String: Any]], let theirs = theirs as? [[String: Any]] else { return nil }
            var out = ours
            var indexByID: [String: Int] = [:]
            for (index, object) in ours.enumerated() { indexByID[id(of: object, identity)] = index }
            for object in theirs {
                let key = id(of: object, identity)
                guard let index = indexByID[key] else {
                    indexByID[key] = out.count
                    out.append(object)
                    continue
                }
                let mine = out[index]
                let theirsIsNewer = stamp.map { number(object[$0]) > number(mine[$0]) } ?? false
                let winner = theirsIsNewer ? object : mine
                let other = theirsIsNewer ? mine : object
                // What the winner does not carry at all (a note, a highlight) comes from the other.
                out[index] = winner.merging(other) { kept, _ in kept }
            }
            if newestFirst, let stamp {
                out = out.enumerated().sorted { a, b in
                    let (x, y) = (number(a.element[stamp]), number(b.element[stamp]))
                    return x == y ? a.offset < b.offset : x > y
                }.map(\.element)
            }
            return cap.map { Array(out.prefix($0)) } ?? out

        case .maxNumber:
            guard let ours = ours as? NSNumber, let theirs = theirs as? NSNumber else { return nil }
            return theirs.doubleValue > ours.doubleValue ? theirs : ours

        case .maxPerKey:
            guard let ours = ours as? [String: Any], let theirs = theirs as? [String: Any] else { return nil }
            return maxPerKey(ours, theirs)

        case .earliestKnownPerKey:
            guard let ours = ours as? [String: Any], let theirs = theirs as? [String: Any] else { return nil }
            var out = ours
            for (key, value) in theirs {
                let (mine, other) = (number(out[key]), number(value))
                guard out[key] != nil else { out[key] = value; continue }
                if mine <= 0, other > 0 { out[key] = value }
                else if mine > 0, other > 0, other < mine { out[key] = value }
            }
            return out

        case .prayerMarks:
            guard let ours = ours as? [String: Any], let theirs = theirs as? [String: Any] else { return nil }
            var out: [String: Any] = [:]
            for day in Set(ours.keys).union(theirs.keys) {
                var marks = prayerDay(ours[day])
                for (prayer, mark) in prayerDay(theirs[day]) {
                    if let mine = marks[prayer], prayerRank(mine) >= prayerRank(mark) { continue }
                    marks[prayer] = mark
                }
                out[day] = marks
            }
            return out

        case .newerObject(let stamp):
            guard let ours = ours as? [String: Any], let theirs = theirs as? [String: Any] else { return nil }
            return number(theirs[stamp]) > number(ours[stamp]) ? theirs : ours

        case .newerPerKey(let stamp):
            guard let ours = ours as? [String: Any], let theirs = theirs as? [String: Any] else { return nil }
            var out = ours
            for (key, value) in theirs {
                guard let mine = out[key] as? [String: Any] else { out[key] = value; continue }
                if let other = value as? [String: Any], number(other[stamp]) > number(mine[stamp]) { out[key] = other }
            }
            return out

        case .readingLadder:
            guard let ours = ours as? [String: Any], let theirs = theirs as? [String: Any] else { return nil }
            var out = ours
            for (tier, value) in theirs {
                guard let other = value as? [String: Any] else { continue }
                guard var mine = out[tier] as? [String: Any] else { out[tier] = other; continue }
                for field in ["best", "attempts", "lastPlayed"] where number(other[field]) > number(mine[field]) {
                    mine[field] = other[field]
                }
                if (other["mastered"] as? Bool) == true { mine["mastered"] = true }
                out[tier] = mine
            }
            return out

        case .eitherTrue:
            guard let ours = ours as? Bool, let theirs = theirs as? Bool else { return nil }
            return ours || theirs

        case .unionCSV:
            guard let ours = ours as? String, let theirs = theirs as? String else { return nil }
            var seen = Set<String>()
            let items = (ours.split(separator: ",") + theirs.split(separator: ","))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && seen.insert($0).inserted }
            return items.joined(separator: ",")

        case .fillIfMissing:
            if let text = ours as? String { return text.isEmpty ? theirs : nil }
            if let data = ours as? Data { return data.isEmpty ? theirs : nil }
            // A number, but not a switch: every NSNumber 0 also casts to `Bool`, so ask the type itself.
            if let value = ours as? NSNumber, CFGetTypeID(value) != CFBooleanGetTypeID() {
                return value.doubleValue == 0 ? theirs : nil
            }
            return nil
        }
    }

    // MARK: Pieces

    private static func maxPerKey(_ ours: [String: Any], _ theirs: [String: Any]) -> [String: Any] {
        var out = ours
        for (key, value) in theirs {
            guard let mine = out[key] else { out[key] = value; continue }
            if let mine = mine as? [String: Any], let other = value as? [String: Any] {
                out[key] = maxPerKey(mine, other)
            } else if number(value) > number(mine) {
                out[key] = value
            }
        }
        return out
    }

    /// One tracker day in the current shape, whichever shape it was stored in.
    private static func prayerDay(_ value: Any?) -> [String: String] {
        if let marks = value as? [String: String] { return marks }
        if let names = value as? [String] {
            return names.reduce(into: [String: String]()) { $0[$1] = "onTime" }
        }
        return [:]
    }

    /// `PrayerMark.rank`, by raw value. A mark this build does not know still says the prayer was
    /// recorded, and reads as prayed (`Settings.decodePrayerTracker` makes the same call).
    private static func prayerRank(_ mark: String) -> Int {
        switch mark {
        case "missed": return 0
        case "late": return 1
        default: return 2
        }
    }

    private static func number(_ value: Any?) -> Double {
        (value as? NSNumber)?.doubleValue ?? -.greatestFiniteMagnitude
    }

    private static func id(of object: [String: Any], _ identity: [String]) -> String {
        identity.map { path -> String in
            var current: Any? = object
            for part in path.split(separator: ".") {
                current = (current as? [String: Any])?[String(part)]
            }
            return current.map { "\($0)" } ?? ""
        }.joined(separator: "\u{1F}")
    }
}
#endif
