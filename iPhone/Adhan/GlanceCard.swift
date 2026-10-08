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
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared

    /// Every tile is a button (Abu, 2026-09-04: "when you click on certain ones have it do a certain
    /// thing"); the card only names what was tapped and the Adhan tab decides what opens.
    var onSelect: (GlanceAction) -> Void = { _ in }

    private static let kaaba = CLLocation(latitude: 21.4225, longitude: 39.8262)

    /// Two columns, or one at the accessibility text sizes: half a row left "CURRENT..." over "San".
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
              count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        let _ = RenderCounter.hit("GlanceCard")
        let accent = settings.accentColor.color
        // One VStack of per-group blocks rather than one grid with Sections: a group with an ODD
        // number of tiles has to end in a full-width tile, and a LazyVGrid cell cannot span columns
        // (Abu, 2026-10-05: "it shouldnt be like that thats not how it is on iphone theres full
        // rows"). Each group lays its even tiles out in the grid and draws a lone last one beneath
        // it at full width, so no row is ever left half empty.
        VStack(alignment: .leading, spacing: 10) {
            ForEach(groups) { group in
                groupHeader(group)

                let paired = pairedTiles(group.tiles)
                if !paired.isEmpty {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                        ForEach(paired) { tile in
                            GlanceTile(tile: tile, accent: accent, onSelect: onSelect)
                                .equatable()
                        }
                    }
                }

                if let lone = loneTile(group.tiles) {
                    // Full width: nothing to stay level with, so the value takes the lines it needs
                    // instead of always reserving two (which left this tile visibly over-tall).
                    GlanceTile(tile: lone, accent: accent, onSelect: onSelect, fullWidth: true)
                        .equatable()
                }
            }
        }
        .padding(.vertical, 2)
        #if os(iOS)
        // A Control Center control asked for the Qibla (Abu, 2026-10-07). It lands here rather than in
        // AdhanView because the bearing and the distance are computed on THIS card for its own tiles,
        // so the control opens the very sheet the tile opens - one compass, not a second copy. Cleared
        // on arrival so re-tapping the control works a second time.
        .onReceive(AppNavigation.shared.$pendingAdhan) { target in
            guard case .qibla = target else { return }
            AppNavigation.shared.pendingAdhan = nil
            onSelect(.qibla(bearing: qiblaSummary, distance: distanceToMakkah))
        }
        #endif
    }

    /// The tiles that fill complete rows: everything but a trailing odd one.
    ///
    /// At the accessibility sizes the grid is ONE column, so every tile is already a full row and
    /// nothing is left over - the split only applies to the two-column layout.
    private func pairedTiles(_ tiles: [GlanceItem]) -> [GlanceItem] {
        guard !dynamicTypeSize.isAccessibilitySize, tiles.count % 2 == 1 else { return tiles }
        return Array(tiles.dropLast())
    }

    /// The trailing tile that would otherwise sit alone in the left column, drawn full width instead.
    private func loneTile(_ tiles: [GlanceItem]) -> GlanceItem? {
        guard !dynamicTypeSize.isAccessibilitySize, tiles.count % 2 == 1 else { return nil }
        return tiles.last
    }

    /// A group's name over its tiles: a step below the section's "AT A GLANCE", and a heading for
    /// VoiceOver's rotor. Sentence case and primary weight, so it reads as a level of its own rather
    /// than one more all-caps eyebrow among the tiles' own.
    private func groupHeader(_ group: GlanceGroup) -> some View {
        Text(group.title)
            .font(.footnote.weight(.semibold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            // The second group sits a little apart from the first one's last row.
            .padding(.top, group.id == GlanceGroup.here ? 0 : 6)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Tiles

    /// Twelve equal tiles in one wall had no order to them (the design review, 2026-09-26), so they
    /// come in two groups of pairs: where you are (the city and its clock, the Qibla and its distance,
    /// home and how far it is) and today (the sun and the fast, the night and the moon, the next date
    /// and the method the day's times come from). A tile that cannot be computed is still dropped.
    private var groups: [GlanceGroup] {
        let qibla = qiblaSummary
        let makkah = distanceToMakkah

        var here: [GlanceItem] = []
        here.append(.init(icon: "location.fill", title: "Current Location",
                          value: live.currentLocation?.city ?? "Unavailable", action: .cityPrayerTimes))
        here.append(.init(icon: "clock.fill", title: "Time Zone", value: timeZoneSummary, action: .cityPrayerTimes))
        if let qibla {
            here.append(.init(icon: "location.north.line.fill", title: "Qibla", value: qibla,
                              iconRotation: qiblaBearing, action: .qibla(bearing: qibla, distance: makkah)))
        }
        if let makkah {
            here.append(.init(icon: "building.columns.fill", title: "Distance to Makkah", value: makkah,
                              action: .qibla(bearing: qibla, distance: makkah)))
        }
        if let home = settings.homeLocation {
            here.append(.init(icon: "house.fill", title: "Home Location", value: home.city, action: .homeLocation))
            if let travel = travelSummary {
                here.append(.init(icon: "airplane", title: "Distance From Home", value: travel,
                                  action: .travelingMode))
            }
        }

        var today: [GlanceItem] = []
        if let daylight = daylightSummary {
            today.append(.init(icon: "sun.max.fill", title: "Daylight", value: daylight, action: .prayerCalendar))
        }
        if let fast = fastingWindow {
            today.append(.init(icon: "fork.knife", title: "Fasting Window", value: fast, action: .prayerCalendar))
        }
        if let night = nightSummary {
            today.append(.init(icon: "moon.zzz.fill", title: "Night", value: night, action: .prayerCalendar))
        }
        today.append(.init(icon: "moon.stars.fill", title: "Moon", value: moonSummary, showsMoonPhase: true,
                           action: .hijriCalendar))
        if let event = nextEventSummary {
            today.append(.init(icon: "calendar", title: "Next Islamic Date", value: event, action: .hijriCalendar))
        }
        today.append(.init(icon: "function", title: "Prayer Calculation", value: calculationSummary,
                           action: .prayerCalculation))

        return [
            GlanceGroup(id: GlanceGroup.here, title: "Here", tiles: here),
            GlanceGroup(id: GlanceGroup.today, title: "Today", tiles: today)
        ]
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
        // Inside the home city the distance is GPS noise ("0.0 mi (0.0 km)"): say where you are, the
        // way the Makkah tile says "At the Kaaba" inside the same radius.
        guard meters > Self.atKaabaRadius else { return "At home\n\(status)" }
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
        guard let location = live.currentLocation,
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

/// What a glance tile opens when tapped. Named by destination, not by tile, because several tiles
/// share one: the three sun tiles open the prayer calendar, the Moon and Next Islamic Date the
/// Hijri calendar, the location and time-zone tiles the City Prayer Times sheet.
enum GlanceAction: Hashable {
    /// The City Prayer Times sheet (the same one the city pill at the top opens).
    case cityPrayerTimes
    /// The Adhan settings sheet, opened straight onto Prayer Calculation.
    case prayerCalculation
    /// The big compass, with the bearing and distance the tiles showed.
    case qibla(bearing: String?, distance: String?)
    /// The prayer times calendar (Daylight, Night and the Fasting Window are read off it).
    case prayerCalendar
    /// The Hijri calendar with its events.
    case hijriCalendar
    /// The home location picker.
    case homeLocation
    /// The Adhan settings sheet, opened straight onto Traveling Mode.
    case travelingMode
}

/// One titled run of tiles in the card (see `GlanceCard.groups`).
struct GlanceGroup: Identifiable {
    static let here = "here"
    static let today = "today"

    let id: String
    let title: String
    let tiles: [GlanceItem]
}

struct GlanceItem: Identifiable, Equatable {
    let icon: String
    let title: String
    let value: String
    /// Degrees to rotate the icon (the Qibla tile points its arrow at the actual bearing).
    var iconRotation: Double? = nil
    /// The Moon tile draws the real lit-limb phase glyph instead of a symbol.
    var showsMoonPhase: Bool = false
    /// What a tap opens.
    var action: GlanceAction = .cityPrayerTimes

    var id: String { title }
}

/// An Equatable leaf: eleven of these sit in the grid, and each used to observe the whole `Settings`
/// object for the accent alone. The parent passes the accent as a plain value, so `==` folds every
/// input the body reads (the tile's strings and the accent); the glass modifier reads its own
/// environment and re-runs on a theme change by itself. The tap closure is not compared: it is the
/// parent's stable handler, and a closure has no equality anyway.
private struct GlanceTile: View, Equatable {
    let tile: GlanceItem
    let accent: Color
    let onSelect: (GlanceAction) -> Void
    /// true = this tile spans the whole row (a group's odd last one), so it has no sibling to keep a
    /// matching height with and reserves no second line.
    var fullWidth: Bool = false
    /// Read from the environment, so `==` need not fold it: a text-size change re-renders the tile
    /// through its environment, not through its inputs.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    static func == (lhs: GlanceTile, rhs: GlanceTile) -> Bool {
        lhs.tile == rhs.tile && lhs.accent == rhs.accent && lhs.fullWidth == rhs.fullWidth
    }

    var body: some View {
        let _ = RenderCounter.hit("GlanceTile")
        Button {
            Settings.shared.hapticFeedback()
            onSelect(tile.action)
        } label: {
            tileBody
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tile.title). \(tile.value.replacingOccurrences(of: "\n", with: ", "))")
        .accessibilityAddTraits(.isButton)
    }

    private var tileBody: some View {
        // The value's FIRST line is the tile's headline; anything after is context. They used to
        // render identically, which made "14h 5m" and "-1 min vs yesterday" fight for attention.
        let lines = tile.value.split(separator: "\n", maxSplits: 1).map(String.init)
        let headline = lines.first ?? tile.value
        let detail = lines.count > 1 ? lines[1] : nil

        // CENTERED (Abu, 2026-10-05: everything but ayah/hadith prose and the summary tiles).
        // A glance tile is an eyebrow over a short value, so both lines centre on the tile's middle.
        return VStack(alignment: .center, spacing: 5) {
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
                    .foregroundColor(Self.secondaryInk)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.8)
            }

            // ONE Text carrying both styles, with two lines RESERVED for every tile: a long
            // headline wraps into the second line, a detail renders as the second line, and a
            // short lone headline leaves it empty - but the tile is the same height in all three
            // cases, so the grid never staggers. At the accessibility sizes the grid is one column
            // (nothing to stagger against), so the value takes the lines it needs instead.
            Group {
                if dynamicTypeSize.isAccessibilitySize || fullWidth {
                    styledValue(headline: headline, detail: detail)
                        .fixedSize(horizontal: false, vertical: true)
                } else if #available(iOS 16.0, *) {
                    styledValue(headline: headline, detail: detail)
                        .lineLimit(2, reservesSpace: true)
                } else {
                    styledValue(headline: headline, detail: detail)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .conditionalGlassEffect(rectangle: true, useColor: 0.15, flat: true)
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
            .foregroundColor(Self.secondaryInk)
    }

    /// The eyebrow and the detail line. The system `.secondary` turns vibrant on the tinted glass and
    /// measured 3.0:1 (dark) and 3.1:1 (light) for the 12 pt detail; a plain primary at 70% keeps the
    /// same step down from the headline and reads at about 5:1 in both.
    private static let secondaryInk = Color.primary.opacity(0.7)
}
#endif
