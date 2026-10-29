import SwiftUI

/// The Islamic date the Adhan tab leads with: the event under way today (Eid, Arafah, a night of
/// Ramadan) or the next one within the week (Abu, 2026-10-25: "when an event is coming or its an
/// event put it in adhan ... above or below prayer countdown"). The dates are the app's own list
/// (`Settings.specialEvents`), placed on the civil calendar exactly as the Hijri calendar screen
/// places them (the Umm al-Qura date, moved back by the reader's Hijri adjustment).
struct IslamicEventOccurrence: Equatable {
    enum Timing: Equatable {
        /// A one-day event, today.
        case today
        /// A night event (`Settings.nightEventTitles`), beginning at Maghrib today.
        case tonight
        /// Day `day` of a multi-day event that spans `count` days (`nights` when they are nights).
        case ongoing(day: Int, count: Int, nights: Bool)
        case tomorrow
        /// A night event beginning at Maghrib tomorrow.
        case tomorrowNight
        /// Two or more days away.
        case inDays(Int)

        var isNow: Bool {
            switch self {
            case .today, .tonight, .ongoing: return true
            case .tomorrow, .tomorrowNight, .inDays: return false
            }
        }
    }

    /// The event's English title, as `Settings.specialEvents` lists it (the key for its display title
    /// and glyph); "Ramadan" for the month under way after its first day.
    let title: String
    /// The event's one-line note, already localized by `Settings.specialEvents`.
    let subtitle: String
    /// The Hijri date the event is listed under.
    let hijri: DateComponents
    /// The civil day the event begins on (a night event's is the day whose Maghrib opens it).
    let start: Date
    let timing: Timing
}

enum IslamicEventLookup {
    /// How far ahead the banner looks, in days.
    static let horizonDays = 7

    /// The event to lead with on the civil day of `now`: an event under way (the most specific one when
    /// several overlap: Arafah over the ten days of Dhul-Hijjah, the 27th night over the last ten),
    /// else the soonest within `horizonDays`, else nil.
    ///
    /// `hijriOffset` is the reader's adjustment of the Hijri date; `hijriCalendar` is the app's Umm
    /// al-Qura calendar and `calendar` the civil one, both in the zone the days are counted in.
    ///
    /// `nightsBegun`: `now` was already moved a day forward because Maghrib has passed with the date
    /// switch on (`effectiveHijriReferenceDate`). Tonight's night then belongs to the day `now` reads,
    /// its own Hijri date, rather than to the civil day before it: anchored the usual way, the 27th
    /// night vanished at the Maghrib that opens it, and the evening before it read "Tonight".
    static func current(now: Date, hijriCalendar: Calendar, hijriOffset: Int, calendar: Calendar,
                        horizonDays: Int = horizonDays, nightsBegun: Bool = false) -> IslamicEventOccurrence? {
        let today = calendar.startOfDay(for: now)
        // The Hijri year of today as the reader sees it (offset-adjusted, like `Settings.specialEvents`).
        let adjusted = hijriCalendar.date(byAdding: .day, value: hijriOffset, to: now) ?? now
        let year = hijriCalendar.component(.year, from: adjusted)

        struct Candidate {
            let occurrence: IslamicEventOccurrence
            let span: Int
            let daysUntil: Int
            let order: Int
        }
        var candidates: [Candidate] = []
        var order = 0
        // The year before too: a span that opened late in it cannot reach today (Dhul-Hijjah 13 is the
        // last date), but the Hijri year read above and the civil placement are two calendars, and
        // this keeps the answer right whichever side of the new year a day falls on.
        for hijriYear in (year - 1)...(year + 1) {
            for event in Settings.specialEvents(inHijriYear: hijriYear) {
                order += 1
                var components = event.1
                components.year = hijriYear
                guard let unadjusted = hijriCalendar.date(from: components) else { continue }
                let placed = hijriCalendar.date(byAdding: .day, value: -hijriOffset, to: unadjusted) ?? unadjusted
                let day = calendar.startOfDay(for: placed)
                let isNight = Settings.nightEventTitles.contains(event.0)
                // A night begins at Maghrib on the civil day before the Hijri date it is listed under.
                guard let start = isNight ? calendar.date(byAdding: .day, value: -1, to: day) : day else { continue }
                // Counted from the day `now` reads it on: after that Maghrib, with `nightsBegun`, `now`
                // already reads the Hijri date's own day.
                let countedFrom = isNight && nightsBegun ? day : start
                let span = span(of: event.0, hijriYear: hijriYear, hijriCalendar: hijriCalendar)
                guard let daysUntil = calendar.dateComponents([.day], from: today, to: countedFrom).day else { continue }
                let timing: IslamicEventOccurrence.Timing
                if daysUntil <= 0, -daysUntil < span {
                    let dayNumber = 1 - daysUntil
                    // Ramadan's first day is the listed date itself, not "Day 1 of 30".
                    if span == 1 || (dayNumber == 1 && event.0 == "First Day of Ramadan") {
                        timing = isNight ? .tonight : .today
                    } else {
                        timing = .ongoing(day: dayNumber, count: span, nights: isNight)
                    }
                } else if daysUntil == 1 {
                    timing = isNight ? .tomorrowNight : .tomorrow
                } else if daysUntil > 1, daysUntil <= horizonDays {
                    timing = .inDays(daysUntil)
                } else {
                    continue
                }
                let ongoingRamadan = event.0 == "First Day of Ramadan" && span > 1 && daysUntil < 0
                let occurrence = IslamicEventOccurrence(
                    title: ongoingRamadan ? "Ramadan" : event.0,
                    subtitle: ongoingRamadan ? String(localized: "The month of fasting") : event.2,
                    hijri: components, start: start, timing: timing)
                candidates.append(Candidate(occurrence: occurrence, span: span, daysUntil: daysUntil, order: order))
            }
        }

        // The day's own date first (Arafah, Eid's first day as "Today", the 27th night), then what is
        // under way and what is tomorrow on a par (Eid tomorrow beats night 9 of the last ten, the
        // first of the last ten nights tomorrow beats Ramadan's 19th day), then the days ahead. Ties
        // go to the shortest span (the most specific date: the 27th night over the last ten, the
        // ten days over the month), then to the span that began last, then to the list's order.
        func rank(_ candidate: Candidate) -> Int {
            switch candidate.occurrence.timing {
            case .today, .tonight: return 0
            case .ongoing, .tomorrow, .tomorrowNight: return 1
            case let .inDays(days): return 1 + days
            }
        }
        return candidates.min(by: { a, b in
            let ra = rank(a), rb = rank(b)
            if ra != rb { return ra < rb }
            if a.span != b.span { return a.span < b.span }
            if a.daysUntil != b.daysUntil { return a.daysUntil > b.daysUntil }
            return a.order < b.order
        })?.occurrence
    }

    /// How many civil days an event covers: Ramadan its whole month, its last ten nights until the
    /// month ends, the first ten days of Dhul-Hijjah, the four days of Eid al-Adha (10 to 13); every
    /// other listed date is one day.
    static func span(of title: String, hijriYear: Int, hijriCalendar: Calendar) -> Int {
        switch title {
        case "First Day of Ramadan":
            return daysInRamadan(hijriYear, hijriCalendar: hijriCalendar)
        case "Last 10 Nights of Ramadan":
            return max(daysInRamadan(hijriYear, hijriCalendar: hijriCalendar) - 20, 1)
        case "First 10 Days of Dhul-Hijjah":
            return 10
        case "Eid Al-Adha":
            return 4
        default:
            return 1
        }
    }

    private static func daysInRamadan(_ hijriYear: Int, hijriCalendar: Calendar) -> Int {
        guard let first = hijriCalendar.date(from: DateComponents(year: hijriYear, month: 9, day: 1)),
              let range = hijriCalendar.range(of: .day, in: .month, for: first) else { return 30 }
        return range.count
    }

    /// The glyph for an event: the crescent for Ramadan, sparkles for its nights of Qadr, the popper
    /// for the two Eids, the pillars for the Hajj days, the haze of a fasting morning for the fasts.
    static func symbolName(for title: String) -> String {
        switch title {
        case "Ramadan", "First Day of Ramadan": return "moon.stars.fill"
        case "Last 10 Nights of Ramadan", "27th Night of Ramadan": return "sparkles"
        case "Eid Al-Fitr", "Eid Al-Adha", "End of Eid Al-Adha": return "party.popper.fill"
        case "First 10 Days of Dhul-Hijjah", "Beginning of Hajj": return "building.columns.fill"
        case "Day of Arafah", "Day of Ashura", "Day Before Ashura": return "sun.haze.fill"
        default: return "calendar"
        }
    }

    /// The event's title as the reader sees it.
    static func displayTitle(for title: String) -> String {
        title == "Ramadan" ? String(localized: "Ramadan") : Settings.specialEventDisplayTitle(title)
    }
}

#if DEBUG
/// "-adhanToday YYYY-MM-DD": the Adhan tab's date-bound rows (the Islamic event banner, the clock
/// change notice) drawn as if it were noon on that day, for screenshot runs. Prayer times and the
/// countdown keep the live clock.
enum AdhanDebugClock {
    static let today: Date? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-adhanToday"), arguments.indices.contains(index + 1) else { return nil }
        let parts = arguments[index + 1].split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }()
}
#endif

#if os(iOS)
/// The event row under the countdown: the glyph on an accent disc, the event's name and its note,
/// and a pill saying when ("Today", "Tonight", "Day 2 of 4", "Tomorrow", "in 5 days"). Opens the
/// Hijri calendar, where the whole year's dates are. Glass like the glance tiles, so it reads as part
/// of the tab rather than as a second traveling card.
struct IslamicEventBanner: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let occurrence: IslamicEventOccurrence
    /// Pushes the Hijri calendar.
    let openCalendar: () -> Void

    var body: some View {
        let accent = settings.accentColor.color
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        Button {
            settings.hapticFeedback()
            openCalendar()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: IslamicEventLookup.symbolName(for: occurrence.title))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(accent.opacity(0.16)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(IslamicEventLookup.displayTitle(for: occurrence.title))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)
                    Text(occurrence.subtitle.localizedDisplay)
                        .font(.caption)
                        .foregroundColor(Self.secondaryInk)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                timingPill(accent: accent)

                // Forward, not right: the disclosure points the way the row reads (left in Arabic).
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Self.secondaryInk)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(shape)
            .conditionalGlassEffect(rectangle: true, useColor: 0.15, flat: true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(IslamicEventLookup.displayTitle(for: occurrence.title)), \(timingText). \(occurrence.subtitle.localizedDisplay)")
        .accessibilityHint("Opens the Hijri calendar")
        .accessibilityAddTraits(.isButton)
    }

    /// "Today" on a solid accent (white on the shade white reads on), the countdown on a tint.
    private func timingPill(accent: Color) -> some View {
        let now = occurrence.timing.isNow
        return Text(timingText)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .foregroundColor(now ? .white : accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(now ? TravelingModeBanner.fill(for: accent, dark: colorScheme == .dark) : accent.opacity(0.14)))
            .fixedSize()
    }

    private var timingText: String {
        switch occurrence.timing {
        case .today: return String(localized: "Today")
        case .tonight: return String(localized: "Tonight")
        case let .ongoing(day, count, nights):
            return (nights ? String(localized: "Night \(day) of \(count)") : String(localized: "Day \(day) of \(count)")).localizedDigits
        case .tomorrow: return String(localized: "Tomorrow")
        case .tomorrowNight: return String(localized: "Tomorrow night")
        case let .inDays(days): return String(localized: "in \(days) days").localizedDigits
        }
    }

    /// The note and the chevron: the system `.secondary` turns vibrant on the tinted glass (see
    /// `GlanceTile.secondaryInk`); primary at 70% keeps its step down from the title and reads at ~5:1.
    private static let secondaryInk = Color.primary.opacity(0.7)

    // MARK: - Today's occurrence

    /// The event to show now, resolved once per civil day, Hijri adjustment and Maghrib switch:
    /// walking the list costs an Umm al-Qura conversion per event (24 a year, three years), and the
    /// tab's body re-runs on every Settings publish. `nightsBegun` is part of the key: the evening
    /// before a day and the morning of it read the same reference day, with different nights.
    private static var cache: (day: Date, offset: Int, nightsBegun: Bool, occurrence: IslamicEventOccurrence?)?

    /// The occurrence the banner shows at `now`, or nil when nothing is near. `now` is the Hijri
    /// reference moment: after Maghrib with the date switch on it is already tomorrow, as the date row
    /// above the banner says, and `nightsBegun` says so (see `IslamicEventLookup.current`).
    static func occurrence(now: Date, nightsBegun: Bool, settings: Settings) -> IslamicEventOccurrence? {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: now)
        let offset = settings.hijriOffset
        if let cache, cache.day == day, cache.offset == offset, cache.nightsBegun == nightsBegun { return cache.occurrence }
        let found = IslamicEventLookup.current(now: now, hijriCalendar: settings.hijriCalendar,
                                               hijriOffset: offset, calendar: calendar, nightsBegun: nightsBegun)
        cache = (day, offset, nightsBegun, found)
        return found
    }
}
#endif
