import SwiftUI
import CoreLocation

struct Location: Codable, Equatable {
    var city: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
    var displayName: String { nameCustom ?? nameTransliteration }

    static func == (lhs: Prayer, rhs: Prayer) -> Bool {
        lhs.id == rhs.id
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
        formatter.timeZone = .current

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
