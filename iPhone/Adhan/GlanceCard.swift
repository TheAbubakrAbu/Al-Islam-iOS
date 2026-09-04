#if os(iOS)
import SwiftUI
import CoreLocation
import Adhan

/// The "At a Glance" card on the Adhan tab: everything the app already knows about *today* and *here*,
/// surfaced instead of left implicit.
///
/// Every value is derived on device from prayer times, coordinates and the calendar - nothing here needs the
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
        let _ = RenderCounter.hit("GlanceCard")
        let accent = settings.accentColor.color
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(tiles) { tile in
                GlanceTile(tile: tile, accent: accent)
                    .equatable()
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
            items.append(.init(icon: "location.north.line.fill", title: "Qibla", value: qibla,
                               iconRotation: qiblaBearing))
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

        items.append(.init(icon: "moon.stars.fill", title: "Moon", value: moonSummary, showsMoonPhase: true))

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

    /// Bearing to the Kaaba as a true heading plus the compass point it falls in - the same number the Qibla
    /// compass rotates to, shown as a value you can read without holding the phone flat.
    ///
    /// Standing on the Kaaba itself, the great-circle bearing is meaningless (the library returns whatever
    /// the degenerate case produces - 325° at the exact coordinate), so say so instead of pointing nowhere.
    /// The raw bearing for the tile's rotating arrow - same math as `qiblaSummary`.
    private var qiblaBearing: Double? {
        guard let coordinate = validCoordinate, let meters = metersToKaaba, meters > Self.atKaabaRadius else { return nil }
        return Qibla(coordinates: Coordinates(latitude: coordinate.latitude,
                                              longitude: coordinate.longitude)).direction
    }

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

    /// Sunrise to sunset, and how that compares with yesterday - the number that quietly explains why Fajr
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
        // The actual clock times, like the fasting window above - "Maghrib to Fajr" only restated the names of
        // the two prayers, which the list already shows.
        return "\(Self.durationText(fajr.timeIntervalSince(maghrib)))\n"
            + "\(settings.formatDate(maghrib)) – \(settings.formatDate(fajr))"
    }

    private var moonSummary: String {
        // The hour-quantized phase shares the sky card's memo entry instead of evicting it.
        let phase = MoonPhase.onCurrentHour()
        return "\(phase.name)\n\(phase.illuminationPercent)% illuminated"
    }

    /// The winning (event, date) pair, resolved once per civil day + hijri year. Walking
    /// `specialEvents` costs an Umm-al-Qura `date(from:)` conversion per event (~24 with the year
    /// roll-over retries), and this card rebuilds on every Settings publish - the answer only changes
    /// when the day (or the hijri reference year, at Maghrib near a year boundary) does.
    private static var nextEventCache: (day: Date, hijriYear: Int, best: (name: String, date: Date)?)?

    /// The soonest upcoming entry from the app's Islamic-date list, rolled into next Hijri year if this
    /// year's occurrence has already passed.
    private var nextEventSummary: String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let hijri = settings.hijriCalendar
        let hijriYear = hijri.component(.year, from: settings.effectiveHijriReferenceDate())

        let best: (name: String, date: Date)?
        if let cached = Self.nextEventCache, cached.day == today, cached.hijriYear == hijriYear {
            best = cached.best
        } else {
            var found: (name: String, date: Date)?
            for (name, components, _, _) in settings.specialEvents {
                var components = components
                for _ in 0...1 {
                    guard let date = hijri.date(from: components) else { break }
                    let day = calendar.startOfDay(for: date)
                    if day >= today {
                        if found == nil || day < found!.date { found = (name, day) }
                        break
                    }
                    components.year = (components.year ?? hijriYear) + 1
                }
            }
            Self.nextEventCache = (today, hijriYear, found)
            best = found
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

struct GlanceItem: Identifiable, Equatable {
    let icon: String
    let title: String
    let value: String
    /// Degrees to rotate the icon (the Qibla tile points its arrow at the actual bearing).
    var iconRotation: Double? = nil
    /// The Moon tile draws the real lit-limb phase glyph instead of a symbol.
    var showsMoonPhase: Bool = false

    var id: String { title }
}

/// An Equatable leaf: eleven of these sit in the grid, and each used to observe the whole `Settings`
/// object for the accent alone. The parent passes the accent as a plain value, so `==` folds every
/// input the body reads (the tile's strings and the accent); the glass modifier reads its own
/// environment and re-runs on a theme change by itself.
private struct GlanceTile: View, Equatable {
    let tile: GlanceItem
    let accent: Color

    var body: some View {
        let _ = RenderCounter.hit("GlanceTile")
        // The value's FIRST line is the tile's headline; anything after is context. They used to
        // render identically, which made "14h 5m" and "-1 min vs yesterday" fight for attention.
        let lines = tile.value.split(separator: "\n", maxSplits: 1).map(String.init)
        let headline = lines.first ?? tile.value
        let detail = lines.count > 1 ? lines[1] : nil

        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Group {
                    if tile.showsMoonPhase {
                        // The REAL moon, exactly as lit tonight - the same glyph the sky card draws.
                        let phase = MoonPhase.onCurrentHour()
                        MoonPhaseGlyph(illumination: phase.illumination, isWaxing: phase.isWaxing)
                            .foregroundColor(accent)
                            .frame(width: 13, height: 13)
                    } else {
                        Image(systemName: tile.icon)
                            .font(.caption2)
                            .foregroundStyle(accent)
                            // The Qibla arrow points at the actual bearing.
                            .rotationEffect(.degrees(tile.iconRotation ?? 0))
                    }
                }

                Text(tile.title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            // ONE Text carrying both styles, with two lines RESERVED for every tile: a long
            // headline wraps into the second line, a detail renders as the second line, and a
            // short lone headline leaves it empty - but the tile is the same height in all three
            // cases, so the grid never staggers.
            Group {
                if #available(iOS 16.0, *) {
                    styledValue(headline: headline, detail: detail)
                        .lineLimit(2, reservesSpace: true)
                } else {
                    styledValue(headline: headline, detail: detail)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.leading)
            .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .conditionalGlassEffect(rectangle: true, useColor: 0.15, flat: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tile.title). \(tile.value.replacingOccurrences(of: "\n", with: ", "))")
    }

    /// The headline in semibold primary; the detail (when present) as a caption-secondary second
    /// line of the SAME Text, so the two-line reservation above covers both shapes.
    private func styledValue(headline: String, detail: String?) -> Text {
        let headlineText = Text(headline)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.primary)
        guard let detail else { return headlineText }
        return headlineText + Text("\n" + detail)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
#endif
