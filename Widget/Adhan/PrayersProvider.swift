import SwiftUI
import WidgetKit

enum AdhanWidgetDateFormatting {
    static let hijriCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }()

    static let mediumHijriFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()

    static let fullHijriFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()

    static func hijriDate(for entry: PrayersEntry, style: DateFormatter.Style) -> String {
        let formatter = style == .full ? fullHijriFormatter : mediumHijriFormatter
        // entry.date, never Date(): WidgetKit archives entry views when the timeline is built, so Date()
        // here is the build time - wrong for every pre-built future entry. entry.date is the moment the
        // entry is actually on screen.
        let now = entry.date
        var referenceDate = now

        if entry.switchHijriDateAtMaghrib,
           let maghrib = entry.fullPrayers.first(where: { $0.nameTransliteration == "Maghrib" })?.time,
           now >= maghrib {
            referenceDate = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        }

        guard let offsetDate = hijriCalendar.date(byAdding: .day, value: entry.hijriOffset, to: referenceDate) else {
            return formatter.string(from: referenceDate)
        }

        return formatter.string(from: offsetDate)
    }
}

struct PrayersProvider: TimelineProvider {
    private let store   = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)
    private let settings = Settings.shared

    // Placeholder (redacted skeleton) and the gallery preview show representative sample times so they never
    // render blank when the app hasn't cached prayers yet. The real timeline still shows only real data - 
    // a prayer app must never display fake prayer times as if they were the user's actual schedule.
    func placeholder(in context: Context) -> PrayersEntry { sampleEntry() }

    func getSnapshot(in ctx: Context, completion: @escaping (PrayersEntry)->Void) {
        completion(ctx.isPreview ? sampleEntry() : makeEntry())
    }

    func getTimeline(in ctx: Context, completion: @escaping (Timeline<PrayersEntry>)->Void) {
        let entries = makeTimelineEntries()
        // .atEnd also asks for a rebuild once the last pre-built entry is showing, so the chain never
        // stalls; the pre-built boundary entries below are what keep the widget exact when WidgetKit
        // defers that reload (background refresh budget, Low Power Mode).
        completion(Timeline(entries: entries, policy: entries.count > 1 ? .atEnd : .after(Date().addingTimeInterval(30 * 60))))
    }

    private func makeEntry() -> PrayersEntry {
        // The whole entry build runs on the main queue. WidgetKit calls `getTimeline` for each widget KIND on
        // its own background thread, and every provider mutates the one `Settings.shared` singleton below -
        // concurrent unsynchronized writes to shared state. Hopping the entire build to main both serializes
        // the providers and puts the mutations on the same thread the rest of Settings lives on. (The
        // extension's main thread is otherwise idle; `fetchPrayerTimes` was already hopping there anyway.)
        if Thread.isMainThread {
            return makeEntryOnMain()
        }
        return DispatchQueue.main.sync { makeEntryOnMain() }
    }

    private func makeTimelineEntries() -> [PrayersEntry] {
        if Thread.isMainThread {
            return makeTimelineEntriesOnMain()
        }
        return DispatchQueue.main.sync { makeTimelineEntriesOnMain() }
    }

    /// One entry now, plus one at every upcoming prayer boundary in the next ~30 hours with current/next
    /// re-resolved for that moment. A single-entry timeline relied on WidgetKit granting a reload exactly at
    /// the next prayer time; when the system deferred it, the widget kept naming the old current prayer.
    /// Pre-built entries flip on time with no reload at all - reloads only refresh the underlying data.
    private func makeTimelineEntriesOnMain() -> [PrayersEntry] {
        let first = makeEntryOnMain()
        guard !first.fullPrayers.isEmpty else { return [first] }

        let now = first.date
        let horizon = now.addingTimeInterval(30 * 60 * 60)
        // Same merged yesterday/today/tomorrow timeline (with optional prayers) the app resolves
        // current/next against, so the widget flips exactly when the app would.
        let boundaries = settings.prayerBoundaryTimeline(around: now)

        // The entry-flip instants: every prayer boundary, PLUS civil midnight. Nothing else spans the
        // Isha → next-Fajr gap, so without a midnight entry the on-screen entry (and the hijri/date
        // string formatted from `entry.date`) stayed on the PREVIOUS day all night for everyone with
        // the maghrib-switch off - the default.
        var flipTimes = boundaries.filter { $0.time > now && $0.time <= horizon }.map(\.time)
        var midnight = Calendar.current.startOfDay(for: now)
        while midnight <= horizon {
            if midnight > now { flipTimes.append(midnight) }
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: midnight) else { break }
            midnight = next
        }

        // Per-day prayer tables, so an entry that is on screen TOMORROW morning lists tomorrow's clock
        // times in the grid/split layouts - copying today's table drifted them by a minute or two.
        var tablesByDay: [Date: (normal: [Prayer], full: [Prayer])] = [:]
        func tables(for date: Date) -> (normal: [Prayer], full: [Prayer]) {
            let day = Calendar.current.startOfDay(for: date)
            if let cached = tablesByDay[day] { return cached }
            let result: (normal: [Prayer], full: [Prayer])
            if Calendar.current.isDate(date, inSameDayAs: now) {
                result = (first.prayers, first.fullPrayers)
            } else {
                result = settings.getPrayerTimesNormalAndFull(for: date) ?? (first.prayers, first.fullPrayers)
            }
            tablesByDay[day] = result
            return result
        }

        var entries = [first]
        for t in Set(flipTimes).sorted() {
            guard let current = boundaries.last(where: { $0.time <= t }),
                  let next = boundaries.first(where: { $0.time > t }) else { continue }
            let table = tables(for: t)
            entries.append(PrayersEntry(
                date:                       t,
                accentColor:                first.accentColor,
                currentCity:                first.currentCity,
                prayers:                    table.normal,
                fullPrayers:                table.full,
                currentPrayer:              current,
                nextPrayer:                 next,
                hijriOffset:                first.hijriOffset,
                switchHijriDateAtMaghrib:   first.switchHijriDateAtMaghrib
            ))
        }
        return entries
    }

    private func makeEntryOnMain() -> PrayersEntry {
        if let data = store?.data(forKey: "prayersData"),
           let prayers = try? Settings.decoder.decode(Prayers.self, from: data) {
            settings.prayers = prayers
        }

        if let locData = store?.data(forKey: "currentLocation"),
           let loc = try? Settings.decoder.decode(Location.self, from: locData) {
            settings.currentLocation = loc
        }

        settings.accentColor = AccentColor(rawValue: store?.string(forKey: "accentColor") ?? AppIdentifiers.mainColorString) ?? AppIdentifiers.mainColor
        settings.customAccentColorHex = store?.string(forKey: "customAccentColorHex") ?? "34C759"
        settings.travelingMode = store?.bool(forKey: "travelingMode") ?? false
        settings.hanafiMadhab = store?.bool(forKey: "hanafiMadhab") ?? false
        settings.prayerCalculation = store?.string(forKey: "prayerCalculation") ?? "Muslim World League"
        settings.hijriOffset = store?.integer(forKey: "hijriOffset") ?? 0
        settings.switchHijriDateAtMaghrib = store?.bool(forKey: "switchHijriDateAtMaghrib") ?? false

        // The user's manual offsets, mirrored from the app. Written to this process's standard
        // defaults (where @AppStorage reads) rather than assigned through the properties - each
        // offset didSet forces a full recompute, and the fetch below already runs exactly once.
        let extensionDefaults = UserDefaults.standard
        for key in Settings.prayerOffsetKeys {
            let mirrored = store?.integer(forKey: key) ?? 0
            if extensionDefaults.integer(forKey: key) != mirrored {
                extensionDefaults.set(mirrored, forKey: key)
            }
        }

        settings.fetchPrayerTimes()

        guard let obj = settings.prayers else {
            return emptyEntry(accent: settings.accentColor)
        }

        return PrayersEntry(
            date:                       Date(),
            accentColor:                settings.accentColor,
            currentCity:                settings.currentLocation?.city ?? "",
            prayers:                    obj.prayers,
            fullPrayers:                obj.fullPrayers,
            currentPrayer:              settings.currentPrayer,
            nextPrayer:                 settings.nextPrayer,
            hijriOffset:                settings.hijriOffset,
            switchHijriDateAtMaghrib:   settings.switchHijriDateAtMaghrib
        )
    }

    /// Representative sample prayer times (today, fixed clock times) for the gallery preview and loading
    /// placeholder, so those surfaces are never blank. Only ever shown in preview/placeholder contexts.
    private func sampleEntry() -> PrayersEntry {
        let accent = AccentColor(rawValue: store?.string(forKey: "accentColor") ?? AppIdentifiers.mainColorString) ?? AppIdentifiers.mainColor
        let cal = Calendar.current
        let now = Date()
        func at(_ h: Int, _ m: Int) -> Date { cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now }
        func prayer(_ ar: String, _ tr: String, _ en: String, _ img: String, _ h: Int, _ m: Int) -> Prayer {
            Prayer(nameArabic: ar, nameTransliteration: tr, nameEnglish: en, time: at(h, m),
                   image: img, rakah: "", sunnahBefore: "", sunnahAfter: "")
        }
        let prayers = [
            prayer("الفَجر", "Fajr", "Dawn", "sun.horizon", 5, 30),
            prayer("الشُرُوق", "Shurooq", "Sunrise", "sunrise", 6, 45),
            prayer("الظُهر", "Dhuhr", "Noon", "sun.max", 12, 30),
            prayer("العَصر", "Asr", "Afternoon", "sun.min", 15, 45),
            prayer("المَغرِب", "Maghrib", "Sunset", "sunset", 18, 30),
            prayer("العِشَاء", "Isha", "Night", "moon", 20, 0),
        ]
        return PrayersEntry(
            date: now,
            accentColor: accent,
            currentCity: "Mecca",
            prayers: prayers,
            fullPrayers: prayers,
            currentPrayer: prayers.last { $0.time <= now } ?? prayers.first,
            nextPrayer: prayers.first { $0.time > now } ?? prayers.first,
            hijriOffset: 0,
            switchHijriDateAtMaghrib: false
        )
    }

    private func emptyEntry(accent: AccentColor) -> PrayersEntry {
        .init(date: Date(),
              accentColor: accent,
              currentCity: "",
              prayers: [], fullPrayers: [],
              currentPrayer: nil, nextPrayer: nil,
              hijriOffset: 0,
              switchHijriDateAtMaghrib: false)
    }
}

struct PrayersEntry: TimelineEntry {
    let date: Date
    let accentColor: AccentColor
    let currentCity: String
    let prayers: [Prayer]
    let fullPrayers: [Prayer]
    let currentPrayer: Prayer?
    let nextPrayer: Prayer?
    let hijriOffset: Int
    let switchHijriDateAtMaghrib: Bool
}
