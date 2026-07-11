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
        let now = Date()
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
    // render blank when the app hasn't cached prayers yet. The real timeline still shows only real data —
    // a prayer app must never display fake prayer times as if they were the user's actual schedule.
    func placeholder(in context: Context) -> PrayersEntry { sampleEntry() }

    func getSnapshot(in ctx: Context, completion: @escaping (PrayersEntry)->Void) {
        completion(ctx.isPreview ? sampleEntry() : makeEntry())
    }

    func getTimeline(in ctx: Context, completion: @escaping (Timeline<PrayersEntry>)->Void) {
        let entry = makeEntry()
        let refresh = entry.nextPrayer?.time ?? Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func makeEntry() -> PrayersEntry {
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
