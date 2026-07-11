#if os(iOS)
import SwiftUI
import CoreLocation
import Adhan

/// The "At a Glance" card on the Adhan tab: everything the app already knows about *today* and *here*,
/// surfaced instead of left implicit.
///
/// Every value is derived on device from prayer times, coordinates and the calendar — nothing here needs the
/// network, and nothing here is stored. Tiles that can't be computed (no location, a polar day with no
/// sunrise) are dropped rather than shown as "Unavailable", so the card never pads itself with dead cells.
struct GlanceCard: View {
    @ObservedObject private var settings = Settings.shared

    private static let kaaba = CLLocation(latitude: 21.4225, longitude: 39.8262)

    private let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(tiles) { tile in
                GlanceTile(tile: tile)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Tiles

    private var tiles: [GlanceItem] {
        var items: [GlanceItem] = []

        items.append(.init(icon: "location.fill", title: "Current Location",
                           value: settings.currentLocation?.city ?? "Unavailable"))

        items.append(.init(icon: "function", title: "Prayer Calculation", value: calculationSummary))

        if let qibla = qiblaSummary {
            items.append(.init(icon: "location.north.line.fill", title: "Qibla", value: qibla))
        }
        if let makkah = distanceToMakkah {
            items.append(.init(icon: "building.columns.fill", title: "Distance to Makkah", value: makkah))
        }
        if let daylight = daylightSummary {
            items.append(.init(icon: "sun.max.fill", title: "Daylight", value: daylight))
        }
        if let fast = fastingWindow {
            items.append(.init(icon: "fork.knife", title: "Fasting Window", value: fast))
        }
        if let night = nightSummary {
            items.append(.init(icon: "moon.zzz.fill", title: "Night", value: night))
        }

        items.append(.init(icon: "moon.stars.fill", title: "Moon", value: moonSummary))

        if let event = nextEventSummary {
            items.append(.init(icon: "calendar", title: "Next Islamic Date", value: event))
        }
        if let home = settings.homeLocation {
            items.append(.init(icon: "house.fill", title: "Home Location", value: home.city))
            if let travel = travelSummary {
                items.append(.init(icon: "airplane", title: "Distance From Home", value: travel))
            }
        }

        items.append(.init(icon: "clock.fill", title: "Time Zone", value: timeZoneSummary))
        return items
    }

    // MARK: - Values

    private var calculationSummary: String {
        var lines = [settings.prayerCalculation]
        var qualifiers: [String] = []
        if settings.hanafiMadhab { qualifiers.append("Hanafi Asr") }
        if settings.highLatitudeRule != Settings.automaticHighLatitudeRule {
            qualifiers.append(settings.highLatitudeRule)
        }
        if !qualifiers.isEmpty { lines.append(qualifiers.joined(separator: " · ")) }
        return lines.joined(separator: "\n")
    }

    /// Close enough to the Kaaba that a bearing to it is noise rather than direction.
    private static let atKaabaRadius: CLLocationDistance = 1_000

    private var metersToKaaba: CLLocationDistance? {
        guard let coordinate = validCoordinate else { return nil }
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: Self.kaaba)
    }

    /// Bearing to the Kaaba as a true heading plus the compass point it falls in — the same number the Qibla
    /// compass rotates to, shown as a value you can read without holding the phone flat.
    ///
    /// Standing on the Kaaba itself, the great-circle bearing is meaningless (the library returns whatever
    /// the degenerate case produces — 325° at the exact coordinate), so say so instead of pointing nowhere.
    private var qiblaSummary: String? {
        guard let coordinate = validCoordinate, let meters = metersToKaaba else { return nil }
        guard meters > Self.atKaabaRadius else { return "You are here" }
        let direction = Qibla(coordinates: Coordinates(latitude: coordinate.latitude,
                                                       longitude: coordinate.longitude)).direction
        return String(format: "%.0f° %@", direction, Self.compassPoint(direction))
    }

    private var distanceToMakkah: String? {
        guard let meters = metersToKaaba else { return nil }
        guard meters > Self.atKaabaRadius else { return "At the Kaaba" }
        return Self.distanceText(meters)
    }

    /// Sunrise to sunset, and how that compares with yesterday — the number that quietly explains why Fajr
    /// keeps creeping earlier.
    private var daylightSummary: String? {
        guard let today = daylightLength(dayOffset: 0) else { return nil }
        var value = Self.durationText(today)
        if let yesterday = daylightLength(dayOffset: -1) {
            let delta = Int((today - yesterday).rounded() / 60)
            if delta != 0 {
                value += "\n\(delta > 0 ? "+" : "−")\(abs(delta)) min vs yesterday"
            } else {
                value += "\nSame as yesterday"
            }
        }
        return value
    }

    /// Fajr to Maghrib: how long a fast runs today. Uses the prayer times as configured, offsets included.
    private var fastingWindow: String? {
        guard let prayers = settings.getPrayerTimes(for: Date(), fullPrayers: true),
              let fajr = prayers.first(where: { $0.nameTransliteration == "Fajr" })?.time,
              let maghrib = prayers.first(where: { $0.nameTransliteration == "Maghrib" })?.time,
              maghrib > fajr
        else { return nil }
        return "\(Self.durationText(maghrib.timeIntervalSince(fajr)))\n"
            + "\(settings.formatDate(fajr)) – \(settings.formatDate(maghrib))"
    }

    /// Maghrib to the next dawn. Computed against *tomorrow's* Fajr, since tonight's night ends tomorrow.
    private var nightSummary: String? {
        guard let today = settings.getPrayerTimes(for: Date(), fullPrayers: true),
              let maghrib = today.first(where: { $0.nameTransliteration == "Maghrib" })?.time,
              let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
              let next = settings.getPrayerTimes(for: tomorrow, fullPrayers: true),
              let fajr = next.first(where: { $0.nameTransliteration == "Fajr" })?.time,
              fajr > maghrib
        else { return nil }
        // The actual clock times, like the fasting window above — "Maghrib to Fajr" only restated the names of
        // the two prayers, which the list already shows.
        return "\(Self.durationText(fajr.timeIntervalSince(maghrib)))\n"
            + "\(settings.formatDate(maghrib)) – \(settings.formatDate(fajr))"
    }

    private var moonSummary: String {
        let phase = MoonPhase.on(Date())
        return "\(phase.name)\n\(phase.illuminationPercent)% illuminated"
    }

    /// The soonest upcoming entry from the app's Islamic-date list, rolled into next Hijri year if this
    /// year's occurrence has already passed.
    private var nextEventSummary: String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let hijri = settings.hijriCalendar

        var best: (name: String, date: Date)?
        for (name, components, _, _) in settings.specialEvents {
            var components = components
            for _ in 0...1 {
                guard let date = hijri.date(from: components) else { break }
                let day = calendar.startOfDay(for: date)
                if day >= today {
                    if best == nil || day < best!.date { best = (name, day) }
                    break
                }
                components.year = (components.year ?? hijri.component(.year, from: today)) + 1
            }
        }

        guard let best else { return nil }
        let days = calendar.dateComponents([.day], from: today, to: best.date).day ?? 0
        let when = days == 0 ? "Today" : (days == 1 ? "Tomorrow" : "in \(days) days")
        return "\(best.name)\n\(when)"
    }

    private var travelSummary: String? {
        guard let coordinate = validCoordinate, let home = settings.homeLocation else { return nil }
        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let there = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let meters = here.distance(from: there)
        let status = settings.travelingMode
            ? "Traveling mode on"
            : (meters >= Settings.travelThresholdM ? "Past 48 mi" : "Within 48 mi")
        return "\(Self.distanceText(meters))\n\(status)"
    }

    private var timeZoneSummary: String {
        let zone = TimeZone.current
        let offset = zone.secondsFromGMT()
        let hours = offset / 3600
        let minutes = abs(offset % 3600) / 60
        let sign = offset < 0 ? "−" : "+"
        let utc = minutes == 0
            ? "UTC\(sign)\(abs(hours))"
            : String(format: "UTC%@%d:%02d", sign, abs(hours), minutes)
        let name = zone.abbreviation() ?? zone.identifier
        return "\(name)\n\(utc)"
    }

    // MARK: - Helpers

    private var validCoordinate: CLLocationCoordinate2D? {
        guard let location = settings.currentLocation,
              location.latitude != 1000, location.longitude != 1000
        else { return nil }
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }

    private func daylightLength(dayOffset: Int) -> TimeInterval? {
        guard let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()),
              let prayers = settings.getPrayerTimes(for: day, fullPrayers: true),
              let sunrise = prayers.first(where: { $0.nameTransliteration == "Shurooq" })?.time,
              let sunset = prayers.first(where: { $0.nameTransliteration == "Maghrib" })?.time,
              sunset > sunrise
        else { return nil }
        return sunset.timeIntervalSince(sunrise)
    }

    private static func durationText(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return "\(total / 3600)h \((total % 3600) / 60)m"
    }

    private static let distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static func distanceText(_ meters: CLLocationDistance) -> String {
        let miles = meters / 1609.34
        let kilometers = meters / 1000
        guard miles >= 10 else { return String(format: "%.1f mi (%.1f km)", miles, kilometers) }
        let mi = distanceFormatter.string(from: NSNumber(value: miles)) ?? "\(Int(miles))"
        let km = distanceFormatter.string(from: NSNumber(value: kilometers)) ?? "\(Int(kilometers))"
        return "\(mi) mi (\(km) km)"
    }

    /// 16-point compass, so a bearing reads as a direction rather than a number to decode.
    private static func compassPoint(_ degrees: Double) -> String {
        let points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        return points[Int((positive / 22.5).rounded()) % 16]
    }
}

struct GlanceItem: Identifiable {
    let icon: String
    let title: String
    let value: String

    var id: String { title }
}

private struct GlanceTile: View {
    @ObservedObject private var settings = Settings.shared

    let tile: GlanceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: tile.icon)
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)

                Text(tile.title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            // Two lines, reserved: every tile keeps the same height whether or not it has a second line, so
            // the grid doesn't stagger.
            Group {
                if #available(iOS 16.0, *) {
                    Text(tile.value).lineLimit(2, reservesSpace: true)
                } else {
                    Text(tile.value).lineLimit(2)
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .conditionalGlassEffect(rectangle: true, useColor: 0.15)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tile.title). \(tile.value.replacingOccurrences(of: "\n", with: ", "))")
    }
}
#endif
