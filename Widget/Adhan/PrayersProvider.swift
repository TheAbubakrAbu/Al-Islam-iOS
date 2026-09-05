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

    /// "Rabiʻ I 24, 1448 AH": the full style minus its weekday, which `hijriDate(for:style:)` adds itself.
    static let longHijriFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()

    /// The moment the Hijri WEEKDAY is read for: `entry.date`, pushed a day forward once Maghrib has
    /// passed when the switch-at-Maghrib setting is on (the Islamic day begins at sunset, and so does
    /// its weekday name: after Maghrib on Saturday it is the night of Sunday).
    static func hijriWeekdayDate(for entry: PrayersEntry) -> Date {
        // entry.date, never Date(): WidgetKit archives entry views when the timeline is built, so Date()
        // here is the build time - wrong for every pre-built future entry. entry.date is the moment the
        // entry is actually on screen.
        let now = entry.date
        guard entry.switchHijriDateAtMaghrib,
              let maghrib = entry.fullPrayers.first(where: { $0.nameTransliteration == "Maghrib" })?.time,
              now >= maghrib else { return now }
        return Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
    }

    /// The Hijri day the entry is showing, as a date: the weekday date plus the user's day adjustment.
    /// The adjustment moves the day of the MONTH (the sighting was a day off from Umm al-Qura), never
    /// the day of the week, which is why the weekday is read from the date above and everything else
    /// from this one. Every Hijri string the widgets show comes from these two, so a caption on a
    /// home-screen widget and the lock-screen date widgets can never disagree on the day.
    static func hijriReferenceDate(for entry: PrayersEntry) -> Date {
        let date = hijriWeekdayDate(for: entry)
        return hijriCalendar.date(byAdding: .day, value: entry.hijriOffset, to: date) ?? date
    }

    /// `.medium`: "Rab. I 24, 1448 AH". `.full`: "Sunday, Rabiʻ I 24, 1448 AH", composed rather than
    /// formatted in one go, so the weekday is the weekday date's and the rest the adjusted date's (a
    /// single formatter printed the adjusted date's weekday, a day off under any adjustment).
    static func hijriDate(for entry: PrayersEntry, style: DateFormatter.Style) -> String {
        let date = hijriReferenceDate(for: entry)
        guard style == .full else { return mediumHijriFormatter.string(from: date) }
        let weekday = englishWeekdayFormatter.string(from: hijriWeekdayDate(for: entry))
        return "\(weekday), \(longHijriFormatter.string(from: date))"
    }

    // MARK: The lock-screen date widgets' pieces

    /// The language a date widget writes in. Arabic is a widget of its own per layout rather than a
    /// setting: a lock-screen widget can't be configured without an App Intent, and separate kinds put
    /// both in the gallery at once.
    enum Language {
        case english
        case arabic
    }

    /// One Hijri date broken into the pieces the lock-screen date widgets set separately: a circular
    /// shows the day number under the month, a rectangular stacks weekday, day-and-month and year.
    ///
    /// The English month names are the app's own (`hijriMonths`: "Rabi al-Awwal"), the spelling the Hijri
    /// Calendar page uses, not CLDR's "Rabiʻ I". The Arabic ones are the formatter's plain unvowelled
    /// names ("ربيع الأول"), as the Adhan tab's Hijri row shows them: the shared table's vowelled forms
    /// blur at lock-screen sizes. Digits are Arabic-Indic in Arabic, and the year carries its era mark
    /// ("1448 AH" / "١٤٤٨ هـ").
    struct HijriDateParts {
        let language: Language
        let weekday: String
        let day: String
        let month: String
        let year: String

        /// "23 Rabi al-Awwal" / "٢٣ ربيع الأول"
        var dayMonth: String { "\(day) \(month)" }
        /// "23 Rabi al-Awwal 1448 AH" / "٢٣ ربيع الأول ١٤٤٨ هـ"
        var dayMonthYear: String { "\(dayMonth) \(year)" }
        /// "Saturday, 23 Rabi al-Awwal" / "السبت، ٢٣ ربيع الأول": the inline family's text, which
        /// replaces the lock screen's own date line and so mirrors its shape (weekday, day, month).
        var weekdayDayMonth: String {
            language == .arabic ? "\(weekday)، \(dayMonth)" : "\(weekday), \(dayMonth)"
        }
    }

    private static func hijriFormatter(locale: String, format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.locale = Locale(identifier: locale)
        formatter.dateFormat = format
        return formatter
    }

    private static let englishWeekdayFormatter = hijriFormatter(locale: "en", format: "EEEE")
    private static let arabicWeekdayFormatter = hijriFormatter(locale: "ar", format: "EEEE")
    private static let arabicMonthFormatter = hijriFormatter(locale: "ar", format: "MMMM")

    static func hijriParts(for entry: PrayersEntry, language: Language) -> HijriDateParts {
        let date = hijriReferenceDate(for: entry)
        let weekdayDate = hijriWeekdayDate(for: entry)
        let components = hijriCalendar.dateComponents([.day, .month, .year], from: date)
        let day = components.day ?? 1
        let month = components.month ?? 1
        let year = components.year ?? 1

        switch language {
        case .english:
            return HijriDateParts(
                language: .english,
                weekday: englishWeekdayFormatter.string(from: weekdayDate),
                day: String(day),
                month: hijriMonths.first { $0.number == month }?.english ?? "",
                year: "\(year) AH"
            )
        case .arabic:
            return HijriDateParts(
                language: .arabic,
                weekday: arabicWeekdayFormatter.string(from: weekdayDate),
                day: arabicNumberString(from: day),
                month: arabicMonthFormatter.string(from: date),
                year: "\(arabicNumberString(from: year)) هـ"
            )
        }
    }

    // MARK: Gregorian dates and clock times, in the device's own locale (as the app shows them)

    /// "Saturday": the weekday the clock is on. Always from `entry.date`, the civil date - the Hijri day
    /// may already have turned at Maghrib, the clock's has not.
    static let gregorianWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter
    }()

    /// "September 5, 2026" (the weekday sits on the line above it).
    static let gregorianLongFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    /// "Sep 5", for the inline family.
    static let gregorianShortDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter
    }()

    /// "3:45 PM" (or 15:45 under a 24-hour clock).
    static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct PrayersProvider: TimelineProvider {
    private static let store = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)
    private var store: UserDefaults? { Self.store }
    private let settings = Settings.shared

    // MARK: Per-process memo
    //
    // Every Adhan kind (37 on iOS, 2 on the watch) has its own provider, and after a reload WidgetKit
    // asks each placed one for a timeline in one burst - each of which re-seeded Settings from the App
    // Group, re-ran the prayer computation and rebuilt the boundary timeline. The inputs are the same
    // for all of them, so the first build is cached and the rest return it. Keyed on every App Group
    // value the build reads, plus a short validity window so an extension process that outlives one
    // burst rebuilds against the current time.
    private struct Inputs: Hashable {
        var prayersData: Data?
        var location: Data?
        var accent: String?
        var customHex: String?
        var travelingMode: Bool
        var hanafiMadhab: Bool
        var prayerCalculation: String?
        var hijriOffset: Int
        var switchHijriDateAtMaghrib: Bool
        var offsets: [Int]
        var customAngles: [Double?]
        var skyGradients: String?
    }
    private static var memo: (inputs: Inputs, builtAt: Date, entries: [PrayersEntry])?
    private static let memoMaxAge: TimeInterval = 5 * 60

    private func currentInputs() -> Inputs {
        Inputs(
            prayersData: store?.data(forKey: "prayersData"),
            location: store?.data(forKey: "currentLocation"),
            accent: store?.string(forKey: "accentColor"),
            customHex: store?.string(forKey: "customAccentColorHex"),
            travelingMode: store?.bool(forKey: "travelingMode") ?? false,
            hanafiMadhab: store?.bool(forKey: "hanafiMadhab") ?? false,
            prayerCalculation: store?.string(forKey: "prayerCalculation"),
            hijriOffset: store?.integer(forKey: "hijriOffset") ?? 0,
            switchHijriDateAtMaghrib: store?.bool(forKey: "switchHijriDateAtMaghrib") ?? false,
            offsets: Settings.prayerOffsetKeys.map { store?.integer(forKey: $0) ?? 0 },
            customAngles: ["customFajrAngle", "customIshaAngle"].map { store?.object(forKey: $0) as? Double },
            skyGradients: store?.string(forKey: "skyGradients")
        )
    }

    /// How long before the next prayer the countdown complication's bar goes red ("not much time
    /// left to pray"): 30 minutes, or half the window when the window itself is short, so a short
    /// interval (Maghrib to Isha) isn't red for most of its life. Lives here because the timeline
    /// must flip an entry at exactly this instant for the recolor to render on time - the view and
    /// the provider have to agree on the number.
    static func lowTimeWarningWindow(_ total: TimeInterval) -> TimeInterval {
        min(30 * 60, total / 2)
    }

    // Placeholder (redacted skeleton) and the gallery preview show representative sample times so they never
    // render blank when the app hasn't cached prayers yet. The real timeline still shows only real data - 
    // a prayer app must never display fake prayer times as if they were the user's actual schedule.
    func placeholder(in context: Context) -> PrayersEntry { sampleEntry() }

    func getSnapshot(in ctx: Context, completion: @escaping (PrayersEntry)->Void) {
        if ctx.isPreview {
            completion(sampleEntry())
            return
        }
        // The entry that is current NOW out of the shared timeline, so a snapshot costs nothing after
        // the first kind has built it.
        let entries = makeTimelineEntries()
        let now = Date()
        completion(entries.last { $0.date <= now } ?? entries[0])
    }

    func getTimeline(in ctx: Context, completion: @escaping (Timeline<PrayersEntry>)->Void) {
        let entries = makeTimelineEntries()
        // .atEnd also asks for a rebuild once the last pre-built entry is showing, so the chain never
        // stalls; the pre-built boundary entries below are what keep the widget exact when WidgetKit
        // defers that reload (background refresh budget, Low Power Mode).
        completion(Timeline(entries: entries, policy: entries.count > 1 ? .atEnd : .after(Date().addingTimeInterval(30 * 60))))
    }

    /// The memoized timeline (see `Inputs`). The whole build runs on the main queue: WidgetKit calls
    /// `getTimeline` for each widget KIND on its own background thread, and the build mutates the one
    /// `Settings.shared` singleton - concurrent unsynchronized writes to shared state. Hopping to main
    /// both serializes the providers and puts the mutations on the same thread the rest of Settings lives
    /// on, and it is what makes the memo safe without a lock.
    private func makeTimelineEntries() -> [PrayersEntry] {
        if Thread.isMainThread {
            return memoizedTimelineEntriesOnMain()
        }
        return DispatchQueue.main.sync { memoizedTimelineEntriesOnMain() }
    }

    private func memoizedTimelineEntriesOnMain() -> [PrayersEntry] {
        let inputs = currentInputs()
        if let memo = Self.memo, memo.inputs == inputs, Date().timeIntervalSince(memo.builtAt) < Self.memoMaxAge {
            return memo.entries
        }
        let entries = makeTimelineEntriesOnMain()
        Self.memo = (inputs, Date(), entries)
        return entries
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
        #if os(watchOS)
        // ...plus one entry shortly BEFORE each boundary, where the countdown complication's bar
        // turns red (`lowTimeWarningWindow`). Watch only: nothing on iOS reads it (every iOS
        // countdown is a self-updating `Text(style: .timer)`), and each of these doubled the number
        // of views WidgetKit archived per iOS widget for an identical render.
        let boundaryTimes = boundaries.map(\.time).sorted()
        for (start, end) in zip(boundaryTimes, boundaryTimes.dropFirst()) {
            let warning = end.addingTimeInterval(-Self.lowTimeWarningWindow(end.timeIntervalSince(start)))
            if warning > now, warning <= horizon { flipTimes.append(warning) }
        }
        #endif

        // The sky gradient per current prayer, resolved once here rather than by every archived entry
        // view (`Settings.skyGradientColors` decodes the palette overrides behind a memo, but the
        // gradient widget and the complication each called it once per entry per kind).
        var skyColorsByKey: [String: [Color]] = [:]
        func skyColors(for prayer: Prayer?) -> [Color] {
            let key = SkyPalette.editableKey(for: prayer?.nameTransliteration)
            if let cached = skyColorsByKey[key] { return cached }
            let colors = settings.skyGradientColors(forPrayer: prayer?.nameTransliteration)
            skyColorsByKey[key] = colors
            return colors
        }
        skyColorsByKey[SkyPalette.editableKey(for: first.currentPrayer?.nameTransliteration)] = first.skyColors

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
                switchHijriDateAtMaghrib:   first.switchHijriDateAtMaghrib,
                skyColors:                  skyColors(for: current)
            ))
        }
        return entries
    }

    private func makeEntryOnMain() -> PrayersEntry {
        // The raw bytes, not a decoded `Prayers`: assigning `settings.prayers` re-encoded what was just
        // decoded (its setter persists through `prayersData`). `prayers` decodes lazily on first read.
        if let data = store?.data(forKey: "prayersData"), !data.isEmpty, settings.prayersData != data {
            settings.prayersData = data
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
        // The "Custom Angles" method's angles, same mirror: the method LABEL arrives via
        // `prayerCalculation` above, but without the angles behind it this process computed custom
        // times with the 18/17 defaults. Absent key = user never touched them; leave the defaults.
        for key in ["customFajrAngle", "customIshaAngle"] {
            if let mirrored = store?.object(forKey: key) as? Double,
               extensionDefaults.object(forKey: key) as? Double != mirrored {
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
            switchHijriDateAtMaghrib:   settings.switchHijriDateAtMaghrib,
            skyColors:                  settings.skyGradientColors(forPrayer: settings.currentPrayer?.nameTransliteration)
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
        let current = prayers.last { $0.time <= now } ?? prayers.first
        return PrayersEntry(
            date: now,
            accentColor: accent,
            currentCity: "Mecca",
            prayers: prayers,
            fullPrayers: prayers,
            currentPrayer: current,
            nextPrayer: prayers.first { $0.time > now } ?? prayers.first,
            hijriOffset: 0,
            switchHijriDateAtMaghrib: false,
            skyColors: settings.skyGradientColors(forPrayer: current?.nameTransliteration)
        )
    }

    private func emptyEntry(accent: AccentColor) -> PrayersEntry {
        .init(date: Date(),
              accentColor: accent,
              currentCity: "",
              prayers: [], fullPrayers: [],
              currentPrayer: nil, nextPrayer: nil,
              hijriOffset: 0,
              switchHijriDateAtMaghrib: false,
              skyColors: settings.skyGradientColors(forPrayer: nil))
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
    /// The sky gradient for `currentPrayer`, resolved by the provider (see `makeTimelineEntriesOnMain`).
    let skyColors: [Color]
}
