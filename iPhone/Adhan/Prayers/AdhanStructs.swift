import SwiftUI
import CoreLocation

struct Location: Codable, Equatable {
    var city: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// `city` as the reader should see it (`String.cityDisplay`), in the interface's digits: the
    /// coordinates fallback ("(33.684, -117.826)") is built by the app with Western digits. For DISPLAY
    /// only; `city` itself is what is stored and compared.
    var displayCity: String { city.cityDisplay.localizedDigits }
}

extension String {
    /// A stored "City, Region" label as the reader should see it. The label is DATA (compared, persisted,
    /// sent to the watch and the widgets' App Group) and is joined with a Latin ", " when it is resolved
    /// (`SettingsAdhan`'s reverse geocode). An Arabic name in a right-to-left interface takes the Arabic
    /// comma ("إيرفين، CA"); a Latin label ("Irvine, CA", the coordinates fallback) reads left to right
    /// and keeps its own, and so does every label in the English interface. For DISPLAY only.
    var cityDisplay: String {
        guard AppLanguage.isRightToLeft, contains(", "),
              unicodeScalars.contains(where: { (0x0600...0x06FF).contains($0.value) })
        else { return self }
        return replacingOccurrences(of: ", ", with: "، ")
    }
}

struct Prayers: Identifiable, Codable, Equatable {
    var id = UUID()

    let day: Date
    let city: String
    let prayers: [Prayer]
    let fullPrayers: [Prayer]

    var setNotification: Bool
}

struct Prayer: Identifiable, Codable, Equatable {
    var id = UUID()

    let nameArabic: String
    /// The canonical name. Everything that *looks a prayer up* - notification preferences, the optional-prayer
    /// set, the scrubber's highlight match, Siri's search keys - keys off this, so it is never user-editable.
    let nameTransliteration: String
    let nameEnglish: String
    let time: Date
    let image: String
    let rakah: String
    let sunnahBefore: String
    let sunnahAfter: String
    /// The user's own spelling, baked in at construction so widgets and the Watch pick it up for free when they
    /// decode the shared `prayersData`. Optional, so prayer data written by an older build still decodes.
    var nameCustom: String? = nil

    /// A caveat about this prayer's sunnah counts (today only Jumuah's masjid/home split), carried on
    /// the value so every surface that shows the counts - the tile detail, the countdown card, the
    /// Watch - explains them without hard-coding prayer names. Optional for the same decode reason.
    var sunnahNote: String? = nil

    /// What a human should read. Prefer this over `nameTransliteration` at every display site.
    var displayName: String {
        guard let custom = nameCustom else { return nameTransliteration.localizedDisplay }
        // A traveling pair renamed on one side only stores the other side's English key ("MyDhuhr/Asr"),
        // which is data (widgets, the watch, Ask AI read it): that half is translated here, for display.
        let keys = nameTransliteration.split(separator: "/").map(String.init)
        let halves = custom.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard keys.count > 1, halves.count == keys.count else { return custom }
        return zip(halves, keys).map { half, key in half == key ? key.localizedDisplay : half }.joined(separator: "/")
    }

    static func == (lhs: Prayer, rhs: Prayer) -> Bool {
        lhs.id == rhs.id
    }
}

/// The whole minute a prayer time is shown and scheduled at, from the instant the sun reaches it.
///
/// Rounding to the nearest minute (the engine's default until 2026-10-04) could show a prayer up to
/// thirty seconds before it came in. Each time now rounds to the side that is safe for what it marks:
/// a prayer's start rounds UP, so nobody is told a prayer is in before it is; a time that ENDS
/// something (sunrise, the end of Fajr; Islamic Midnight, the end of Isha's chosen time) rounds DOWN.
/// Fajr is both a prayer's start and the end of suhoor, which pull opposite ways: it rounds up like
/// every start, and the fasting countdowns stop a minute before it (`suhoorEnd(forFajr:)`).
enum PrayerMinute {
    static func rounded(_ instant: Date, endsATime: Bool) -> Date {
        // The reference date is a whole minute in UTC, and every time zone is a whole number of
        // minutes from UTC, so a whole minute here is a whole minute on every clock.
        let minutes = instant.timeIntervalSinceReferenceDate / 60
        return Date(timeIntervalSinceReferenceDate: (endsATime ? minutes.rounded(.down) : minutes.rounded(.up)) * 60)
    }

    /// When eating has to stop for the dawn whose Fajr minute is `fajr`. That minute is dawn rounded
    /// up, so it can be up to 59 seconds after dawn; a minute before it is always before dawn.
    static func suhoorEnd(forFajr fajr: Date) -> Date {
        fajr.addingTimeInterval(-60)
    }
}

/// How a prayer was recorded in the tracker: the three answers to "did you pray it?". On time and
/// late both mean it WAS prayed (late = made up after its window passed, still an answered
/// obligation); missed records honestly that it was not, instead of leaving the slot blank. The raw
/// values are the on-disk encoding (see `Settings.decodePrayerTracker`), so they never change.
enum PrayerMark: String, CaseIterable, Codable {
    case onTime
    case late
    case missed

    /// True for the marks that mean the prayer was prayed: everything the tracker counted before
    /// the marks existed (streaks, totals, coverage) counts exactly these.
    var isPrayed: Bool { self != .missed }

    /// Ordering for conflicts and combined rows: the higher rank is the better outcome.
    var rank: Int {
        switch self {
        case .onTime: return 2
        case .late: return 1
        case .missed: return 0
        }
    }
}

struct HijriDate: Identifiable, Codable {
    var id: Date { date }

    let english: String
    let arabic: String
    let date: Date
    /// The `hijriOffset` this rendering was computed with - part of the same-day cache check in
    /// `updateDates()`. Without it, changing the Hijri adjustment did nothing until the next day:
    /// the guard saw a fresh-looking same-day cache (persisted across launches, so even a restart
    /// didn't help) and returned before applying the new offset. Optional so entries persisted
    /// before this field existed still decode - they read as "unknown offset" and recompute once.
    let offset: Int?
    /// When this rendering was made. An Arabic interface prints today's GREGORIAN date beside the Hijri
    /// one (`companionLine`), and that turns over at midnight even when the Hijri day (switched at
    /// Maghrib) does not, so `updateDates()` recomputes once the civil day has changed. Optional, like
    /// `offset`, for entries persisted before it existed.
    var computedAt: Date? = nil
}

extension HijriDate {
    /// The Hijri date where there is room for ONE line (the watch): the Arabic date in an Arabic
    /// interface, the English one otherwise.
    var interfaceLine: String {
        AppLanguage.isArabic ? arabic : english
    }

    /// The line printed beside (or above) the Arabic Hijri date. English: the English Hijri date, as
    /// always. Arabic: the Arabic date already says the Hijri day, and its English twin was a
    /// transliteration ("Jumada I 13, 1448 AH"), so the line carries today's Gregorian date instead.
    var companionLine: String {
        AppLanguage.isArabic ? Self.gregorianFormatter.string(from: Date()) : english
    }

    /// What "Copy" puts on the pasteboard for `companionLine`'s row.
    var companionCopyTitle: String {
        AppLanguage.isArabic ? String(localized: "Copy Gregorian Date") : String(localized: "Copy English Date")
    }

    /// Today in the Gregorian calendar, in the interface's language. The calendar is set explicitly: a
    /// device on the Islamic calendar would otherwise print a second Hijri date.
    private static let gregorianFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}

/// A number glued to a symbol ("18°", "±5°") for display. In a right-to-left interface the bidi algorithm
/// draws a trailing symbol on the number's far side ("°18"), so there the run is isolated left to right
/// (LRI ... PDI) and takes the locale's digits. A left-to-right interface gets exactly the text it always had.
enum SymbolNumber {
    static func isolated(_ text: String) -> String {
        AppLanguage.isRightToLeft ? "\u{2066}\(text)\u{2069}" : text
    }

    /// `value` to `places` decimals, then a degree sign: `String(format: "%.Nf°")` left to right.
    static func degrees(_ value: Double, places: Int) -> String {
        guard AppLanguage.isRightToLeft else { return String(format: "%.\(places)f°", value) }
        return isolated(value.formatted(.number.precision(.fractionLength(places)).grouping(.never)) + "°")
    }

    /// A line built from isolated parts, read right to left in a right-to-left interface. A paragraph takes
    /// its direction from its first strong letter OUTSIDE any isolate, so a line that opens on one of the
    /// runs above (or on a `String(localized:)` argument, which is isolated too) and has no Arabic letter
    /// of its own between them was laid out left to right, its parts swapped ("٣٣٫٦٨° ش، ١١٧٫٨٢° غ" drew
    /// longitude first). A leading RIGHT-TO-LEFT MARK sets the direction; English gets its text untouched.
    static func rightToLeftLine(_ text: String) -> String {
        guard AppLanguage.isRightToLeft, !text.hasPrefix("\u{200F}") else { return text }
        return "\u{200F}" + text
    }
}

extension Text {
    /// `SymbolNumber.rightToLeftLine` for a line that cannot be a `String` (it carries a live timer or a
    /// styled date): the mark is its own leading run, outside every argument's isolate.
    func rightToLeftLine() -> Text {
        AppLanguage.isRightToLeft ? Text(verbatim: "\u{200F}") + self : self
    }
}

/// Separators for text joined in CODE rather than through a catalog key, in the interface's punctuation:
/// the catalog writes the middle dot as a bullet in Arabic, and a line built outside it should match.
enum JoinSeparator {
    /// " · ", or " • " in Arabic.
    static var dot: String { AppLanguage.isArabic ? " • " : " · " }
}

/// A count and its unit as ONE localized phrase ("**12** days"), for a tile that draws the number large and
/// the unit small beside it. Arabic makes the noun agree with the number (١ يوم، يومان، ٣ أيام، ١١ يومًا),
/// so a unit cannot be a key of its own: the phrase is a key with an integer argument, which a catalog can
/// give plural variations, and its bold run marks where the count sits. This keeps the unit text on either
/// side of it; the caller still prints the number itself, formatted as before.
struct CountPhrase {
    /// The unit text before and after the count, in reading order; "" when there is none.
    let before: String
    let after: String

    init(_ phrase: AttributedString) {
        var before = "", after = "", sawCount = false
        for run in phrase.runs {
            let text = String(phrase[run.range].characters)
            if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                sawCount = true
            } else if sawCount {
                after += text
            } else {
                before += text
            }
        }
        if !sawCount {
            // A translation that lost its ** markers: drop its digits, so the count is not printed twice.
            before = ""
            after = String(phrase.characters).filter { !$0.isNumber }
        }
        self.before = Self.trimmed(before)
        self.after = Self.trimmed(after)
    }

    private static let edges = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet(charactersIn: "\u{200E}\u{200F}\u{061C}\u{2066}\u{2067}\u{2068}\u{2069}"))

    private static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: edges)
    }
}

extension Date {
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    func addingMinutes(_ minutes: Int) -> Date {
        addingTimeInterval(TimeInterval(minutes * 60))
    }
}

extension Character {
    var asciiDigitValue: UInt32? {
        guard let value = unicodeScalars.first?.value, (48...57).contains(value) else { return nil }
        return value - 48
    }
}

extension DateFormatter {
    private static func configuredTimeFormatter(localeIdentifier: String? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        // Auto-updating: `.current` froze the zone of first use into every time string (P1).
        formatter.timeZone = .autoupdatingCurrent

        if let localeIdentifier {
            formatter.locale = Locale(identifier: localeIdentifier)
        }

        return formatter
    }

    static let timeAR = configuredTimeFormatter(localeIdentifier: "ar")
    static let timeEN = configuredTimeFormatter()
}

extension Double {
    var stringRepresentation: String {
        String(format: "%.3f", self)
    }
}

extension CLLocationCoordinate2D {
    var stringRepresentation: String {
        let latitudeText = String(format: "%.3f", latitude)
        let longitudeText = String(format: "%.3f", longitude)
        return "(\(latitudeText), \(longitudeText))"
    }
}
