#if os(iOS)
import SwiftUI

// The prayer tracker on the Adhan tab: the card under the prayer times, and the pieces every
// tracker surface marks with (the chips, the press-and-hold chooser, the tap that asks). The
// history page is PrayerTrackerView.swift; the numbers are PrayerTrackerInsights.swift; the ring is
// Widget/Adhan/PrayerDayRing.swift, which the widgets draw too.

// MARK: - Shared bits

/// A canonical prayer's name as the reader spells it.
func trackerPrayerLabel(_ name: String, settings: Settings = .shared) -> String {
    settings.customPrayerName(for: name) ?? name.localizedDisplay
}

/// A tap that cannot be recorded without a question: the prayer's time has already ended, so "on
/// time" is not something the tap alone can know (Abu, 2026-11-18). Raised by `tapTrackerSlot`,
/// answered by `trackerAskDialog`.
struct TrackerAsk: Identifiable, Equatable {
    /// The slot as it is recorded ("Asr", "Dhuhr/Asr", "Jumuah").
    let prayerName: String
    let displayName: String
    let day: Date

    var id: String { "\(prayerName)|\(day.timeIntervalSinceReferenceDate)" }

    /// "Did you pray Asr?", "... yesterday?", "... on Thursday?", "... on Sep 12?": the sentences
    /// the notification question already uses (AppDelegate), so the two never read differently.
    var title: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: day), to: calendar.startOfDay(for: Date())
        ).day ?? 0
        let formatter = DateFormatter()
        switch days {
        case ...0:
            return String(localized: "Did you pray \(displayName)?")
        case 1:
            return String(localized: "Did you pray \(displayName) yesterday?")
        case 2...6:
            formatter.dateFormat = "EEEE"
        default:
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
        }
        return String(localized: "Did you pray \(displayName) on \(formatter.string(from: day))?")
    }
}

extension Settings {
    /// Records the mark and tells the review prompt what it meant (`noteReviewMoment`). Main-actor,
    /// like the review manager it calls; every caller is a view action.
    @MainActor
    func recordTrackerMark(_ mark: PrayerMark?, for prayerName: String, on date: Date) {
        setPrayerMark(prayerName, on: date, mark: mark)
        if let mark { noteReviewMoment(for: mark, on: date) }
    }

    /// What a tap on a tracker slot does. A marked slot clears. An unmarked one whose time is still
    /// running is prayed on time. One whose time has ended ASKS, because a Fajr ticked at noon may
    /// have been prayed at dawn or an hour ago, and until 2026-11-18 the tap wrote "on time" either way.
    @MainActor
    func tapTrackerSlot(_ prayerName: String, displayName: String, on day: Date, ask: (TrackerAsk) -> Void) {
        if prayerMark(for: prayerName, on: day) != nil {
            recordTrackerMark(nil, for: prayerName, on: day)
        } else if prayerWindowHasEnded(forSlot: prayerName, on: day) {
            ask(TrackerAsk(prayerName: prayerName, displayName: displayName, day: day))
        } else {
            recordTrackerMark(.onTime, for: prayerName, on: day)
        }
    }
}

extension View {
    /// The question a tap raises once a prayer's time has ended. Goes on ONE view (the card, the week
    /// grid), never on a Section: a presentation on a Section is one per row.
    func trackerAskDialog(_ asking: Binding<TrackerAsk?>) -> some View {
        confirmationDialog(
            asking.wrappedValue?.title ?? "",
            isPresented: Binding(get: { asking.wrappedValue != nil }, set: { if !$0 { asking.wrappedValue = nil } }),
            titleVisibility: .visible,
            presenting: asking.wrappedValue
        ) { ask in
            Button("Yes, on time") { Settings.shared.recordTrackerMark(.onTime, for: ask.prayerName, on: ask.day) }
            Button("Yes, but late") { Settings.shared.recordTrackerMark(.late, for: ask.prayerName, on: ask.day) }
            Button("No, I missed it") { Settings.shared.recordTrackerMark(.missed, for: ask.prayerName, on: ask.day) }
            Button("Cancel", role: .cancel) {}
        } message: { ask in
            Text("The time for \(ask.displayName) has ended.")
        }
    }
}

/// One answer as a capsule: filled when chosen, tinted outline when not. The Day view's rows and a
/// prayer's expanded detail on the Adhan tab both use it, so the two can never drift apart.
struct TrackerMarkChip: View {
    let mark: PrayerMark
    let selected: Bool
    let action: () -> Void

    var body: some View {
        let tint = mark.tint

        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: mark.symbol)
                    .font(.system(size: 10, weight: .bold))

                Text(mark.shortTitle)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(selected ? .white : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(selected ? tint : tint.opacity(0.12)))
            .overlay(Capsule().strokeBorder(tint.opacity(selected ? 0 : 0.35), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mark.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// "In congregation" for one prayer, the same capsule in its own blue. It describes a prayer that
/// was prayed, so it waits, dimmed and in place, until the prayer carries a prayed mark: the line
/// it sits on is always there, and nothing above a chip moves when an answer is chosen.
struct TrackerCongregationChip: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    let prayerName: String
    let day: Date

    var body: some View {
        let prayed = settings.isPrayerMarkedPrayed(prayerName, on: day)
        let selected = prayed && settings.isPrayedInCongregation(prayerName, on: day)
        let tint = TrackerTint.congregation

        Button {
            settings.hapticFeedback()
            settings.setPrayedInCongregation(prayerName, on: day, !selected)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 10, weight: .bold))

                Text("In congregation")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(selected ? .white : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(selected ? tint : tint.opacity(0.12)))
            .overlay(Capsule().strokeBorder(tint.opacity(selected ? 0 : 0.35), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!prayed)
        .opacity(prayed ? 1 : 0.4)
        .accessibilityLabel("In congregation")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The tracker inside a prayer's expanded detail on the Adhan tab (Abu, 2026-09-25: "when i touch a
/// prayer to open it ... support the different option for prayer tracker"): the Day view's three
/// answers for that one prayer, on the day the list is showing. Re-tapping the chosen answer clears
/// it. Before the prayer begins it says so instead, and on an exempt day it says tracking is paused.
struct PrayerMarkChooser: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    let prayer: Prayer
    /// The day of the list the prayer is on. Not `prayer.time`'s day: an Isha after midnight is
    /// still the Isha of the day before, and marked under its own time it was filed a day late.
    let day: Date

    var body: some View {
        let name = prayer.nameTransliteration
        let mark = settings.prayerMark(for: name, on: day)

        VStack(alignment: .leading, spacing: 6) {
            Text("PRAYER TRACKER")
                .font(.caption2.weight(.bold))
                .tracking(AppLanguage.letterSpacing(0.6))
                .foregroundColor(.secondary)

            if settings.isTrackerExempt(on: day) {
                Text("Tracking is paused for this day.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if settings.canMarkPrayer(startingAt: prayer.time, on: day) {
                HStack(spacing: 6) {
                    ForEach(PrayerMark.allCases, id: \.self) { option in
                        TrackerMarkChip(mark: option, selected: mark == option) {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut(duration: 0.15)) {
                                settings.recordTrackerMark(mark == option ? nil : option, for: name, on: day)
                            }
                        }
                    }
                }

                if settings.trackerCongregationEnabled {
                    TrackerCongregationChip(prayerName: name, day: day)
                }
            } else {
                Text("Can be marked once \(prayer.displayName) begins.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
        .accessibilityElement(children: .contain)
    }
}

/// The tracker's answer for one prayer as a small dot beside its name in the prayer list, in the
/// answer's own colour (on time green, late orange, missed red). Nothing at all while the
/// prayer is unmarked (Abu, 2026-09-25: "leave it blank if not touched").
struct PrayerMarkDot: View {
    let mark: PrayerMark?

    var body: some View {
        if let mark {
            Circle()
                .fill(mark.tint)
                .frame(width: 7, height: 7)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 0.75))
                .accessibilityLabel(mark.title)
        }
    }
}

/// The chooser inside every press-and-hold menu: a checkmarked picker of the three marks plus
/// "Not Marked" to clear. A Picker rather than plain buttons, so the current answer shows its
/// checkmark in the menu. With congregation tracked, the menu ends with that switch.
struct TrackerMarkPicker: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    let prayerName: String
    let date: Date

    var body: some View {
        Picker("Status", selection: Binding<PrayerMark?>(
            get: { settings.prayerMark(for: prayerName, on: date) },
            set: { newValue in
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.15)) {
                    settings.recordTrackerMark(newValue, for: prayerName, on: date)
                }
            }
        )) {
            ForEach(PrayerMark.allCases, id: \.self) { mark in
                Label(mark.title, systemImage: mark.symbol).tag(Optional(mark))
            }
            Label("Not Marked", systemImage: "circle").tag(PrayerMark?.none)
        }

        if settings.trackerCongregationEnabled {
            Divider()

            // `.automatic`, or the app's padded switch style draws a double-height menu row.
            Toggle(isOn: Binding(
                get: { settings.isPrayedInCongregation(prayerName, on: date) },
                set: { newValue in
                    settings.hapticFeedback()
                    settings.setPrayedInCongregation(prayerName, on: date, newValue)
                }
            )) {
                Label("In Congregation", systemImage: "person.2.fill")
            }
            .toggleStyle(.automatic)
            .disabled(!settings.isPrayerMarkedPrayed(prayerName, on: date))
        }
    }
}

/// One prayer slot on the Adhan tab: icon in a circle that fills with the mark's color, name underneath.
/// Tap marks it prayed on time while its time is running and asks once it has ended (tap again to
/// clear); press and hold opens the full chooser - on time, late, missed, or not marked.
private struct TrackerPrayerToggle: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Observed for the time gate only: `LiveState` republishes when a prayer window rolls over, which
    /// is exactly the moment a slot becomes markable (`canMarkPrayer`). Without it the circle would
    /// stay inert until something else happened to redraw it.
    @ObservedObject private var live = LiveState.shared

    let prayer: Prayer
    let date: Date
    let onAsk: (TrackerAsk) -> Void

    var body: some View {
        let name = prayer.nameTransliteration
        let mark = settings.prayerMark(for: name, on: date)
        let tint = mark?.tint ?? .secondary
        let canMark = settings.canMarkPrayer(startingAt: prayer.time, on: date)
        let inCongregation = settings.trackerCongregationEnabled && mark?.isPrayed == true
            && settings.isPrayedInCongregation(name, on: date)

        // `GridTileMenu`, for its fast hold (this slot is where that pattern was first proved).
        GridTileMenu {
            settings.hapticFeedback()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                settings.tapTrackerSlot(name, displayName: prayer.displayName, on: date, ask: onAsk)
            }
        } menu: {
            TrackerMarkPicker(prayerName: name, date: date)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if let mark = mark {
                        // The accent chip gradient, in circle form - marking a prayer should feel
                        // like a win, not a change of outline. Late and missed take their own colors.
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.95), tint.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .softShadow(color: tint.opacity(0.4), radius: 6, x: 0, y: 2)

                        Image(systemName: mark.symbol)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.08))

                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)

                        Image(systemName: prayer.image)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 40, height: 40)
                // Always laid out, so a prayer marked in congregation is the same size as one that is not.
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(TrackerTint.congregation))
                        .overlay(Circle().strokeBorder(Color(.systemBackground).opacity(0.9), lineWidth: 1.5))
                        .offset(x: 4, y: 3)
                        .opacity(inCongregation ? 1 : 0)
                        .accessibilityHidden(true)
                }

                Text(prayer.displayName)
                    .font(.caption2.weight(mark != nil ? .semibold : .regular))
                    .foregroundColor(mark != nil ? tint : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .contentShape(Rectangle())
        }
        // Dimmed rather than hidden: the five slots keep their places, so the row still reads as the
        // whole day with the rest of it still to come.
        .disabled(!canMark)
        .opacity(canMark ? 1 : 0.4)
        .accessibilityLabel(accessibilityLabel(mark: mark, canMark: canMark, inCongregation: inCongregation))
        .accessibilityHint(canMark
            ? "Tap to mark prayed. Press and hold for late or missed."
            : "Can be marked once \(prayer.displayName) begins.")
    }

    private func accessibilityLabel(mark: PrayerMark?, canMark: Bool, inCongregation: Bool) -> String {
        let state = canMark ? (mark?.spokenTitle ?? String(localized: "not marked")) : String(localized: "not yet")
        let base = "\(prayer.displayName): \(state)"
        return inCongregation ? base + ", " + String(localized: "In congregation") : base
    }
}

// MARK: - The week strip

/// The last seven days under the card's five slots, each a small day ring. A tap puts that day on
/// the card, so yesterday's Isha or Monday's Fajr is answered right here, without the history page.
private struct TrackerWeekStrip: View {
    struct Day: Identifiable {
        let id: Int
        let date: Date
        let marks: [PrayerMark?]
        let exempt: Bool
        let prayed: Int
    }

    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    let days: [Day]
    /// The day the card is showing.
    let shown: Date
    let select: (Date) -> Void

    var body: some View {
        let accent = settings.accentColor.accent2
        let calendar = Calendar.current

        HStack(spacing: 0) {
            // Positional identity, as in the history grids: a date can never repeat here, and an
            // offset cannot.
            ForEach(days) { day in
                let isShown = calendar.isDate(day.date, inSameDayAs: shown)

                Button {
                    settings.hapticFeedback()
                    select(day.date)
                } label: {
                    VStack(spacing: 5) {
                        Text(Self.weekdayLetter.string(from: day.date))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(isShown ? accent : .secondary)

                        ZStack {
                            PrayerDayRing(marks: day.exempt ? PrayerDayRing.empty : day.marks, lineWidth: 3.5,
                                          track: Color.secondary.opacity(day.exempt ? 0.1 : 0.22))

                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.7))
                                .opacity(day.exempt ? 1 : 0)
                        }
                        .frame(width: 26, height: 26)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(accent.opacity(isShown ? 0.14 : 0))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: day))
                .accessibilityAddTraits(isShown ? .isSelected : [])
                .accessibilityHint("Shows this day on the card.")
            }
        }
    }

    private func accessibilityLabel(for day: Day) -> String {
        let date = Self.spokenDate.string(from: day.date)
        if day.exempt { return String(localized: "\(date): exempt") }
        return "\(date): " + String(localized: "\(day.prayed) of \(PrayerDayRing.prayers.count) prayed")
    }

    private static let weekdayLetter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEE")
        return formatter
    }()

    private static let spokenDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMd")
        return formatter
    }()
}

// MARK: - Sunnah prayers on the card

extension SunnahPrayer {
    /// "Before Fajr", "After Dhuhr", "Witr", "Duha", "Night Prayer": the anchor prayer as the reader
    /// spells it.
    var title: String {
        switch self {
        case .fajrBefore: return String(localized: "Before \(trackerPrayerLabel("Fajr"))")
        case .dhuhrBefore: return String(localized: "Before \(trackerPrayerLabel("Dhuhr"))")
        case .dhuhrAfter: return String(localized: "After \(trackerPrayerLabel("Dhuhr"))")
        case .maghribAfter: return String(localized: "After \(trackerPrayerLabel("Maghrib"))")
        case .ishaAfter: return String(localized: "After \(trackerPrayerLabel("Isha"))")
        case .witr: return String(localized: "Witr")
        case .duha: return String(localized: "Duha")
        case .night: return String(localized: "Night Prayer")
        }
    }

    var symbol: String {
        switch self {
        case .fajrBefore: return trackerPrayerSymbol("Fajr")
        case .dhuhrBefore, .dhuhrAfter: return "sun.max"
        case .maghribAfter: return "sunset"
        case .ishaAfter: return "moon"
        case .witr: return "moon.stars"
        case .duha: return "sun.haze"
        case .night: return "moon.zzz"
        }
    }
}

/// The eight Sunnah prayers as one row of the card: eight dots and a count, and the row itself is
/// the menu that ticks them. The menu stays open between ticks, so a whole day is one visit.
private struct TrackerSunnahRow: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    let day: Date

    var body: some View {
        let prayed = settings.sunnahPrayed(on: day)
        let accent = settings.accentColor.accent2

        Menu {
            TrackerSunnahMenuItems(day: day)
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: "sparkles", tint: accent, size: 26)

                Text("Sunnah Prayers")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 4)

                HStack(spacing: 3) {
                    ForEach(SunnahPrayer.allCases, id: \.self) { prayer in
                        Circle()
                            .fill(prayed.contains(prayer) ? accent : Color.secondary.opacity(0.22))
                            .frame(width: 6, height: 6)
                    }
                }
                .accessibilityHidden(true)

                Text("\(prayed.count)/\(SunnahPrayer.allCases.count)".localizedDigits)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundColor(prayed.isEmpty ? .secondary : accent)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keepsMenuOpen()
        .accessibilityLabel("Sunnah Prayers")
        .accessibilityValue("\(prayed.count) of \(SunnahPrayer.allCases.count) prayed")
    }
}

/// The eight ticks, in two groups: the twelve regular rak'at, then Witr, Duha and the night prayer.
struct TrackerSunnahMenuItems: View {
    private let settings = Settings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    let day: Date

    var body: some View {
        Section("The Regular Sunnah") {
            ForEach(SunnahPrayer.rawatib, id: \.self) { item($0) }
        }
        Section {
            ForEach(SunnahPrayer.allCases.filter { !$0.isRatibah }, id: \.self) { item($0) }
        }
    }

    private func item(_ prayer: SunnahPrayer) -> some View {
        // `.automatic`, or the app's padded switch style draws a double-height menu row.
        Toggle(isOn: Binding(
            get: { settings.sunnahPrayed(on: day).contains(prayer) },
            set: { newValue in
                settings.hapticFeedback()
                settings.setSunnahPrayed(prayer, on: day, newValue)
            }
        )) {
            Label(prayer.title, systemImage: prayer.symbol)
        }
        .toggleStyle(.automatic)
    }
}

extension View {
    /// A menu of ticks stays open while they are ticked (iOS 16.4; before it the menu closes per tap,
    /// as every menu did).
    @ViewBuilder
    func keepsMenuOpen() -> some View {
        if #available(iOS 16.4, *) {
            menuActionDismissBehavior(.disabled)
        } else {
            self
        }
    }
}

// MARK: - The tracker section (Adhan tab, underneath Prayer Times)

/// The prayer tracker as its own section: the day ring and what is waiting, the five tap-to-mark
/// slots, the last seven days, and the doorway into the full history. Standalone struct on purpose -
/// a new Adhan-tab section must never be an inline closure of an already-deep view tree.
struct PrayerTrackerSection: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    /// The folded state lives with the other tab-section keys (TabSections.swift).
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared

    /// A day of the week strip put on the card in place of today. Nil is today, and so is any day
    /// that has since left the strip (the date rolled over while the tab stayed open).
    @State private var chosenDay: Date?
    @State private var asking: TrackerAsk?

    /// The prayer day the card tracks: YESTERDAY until today's Fajr begins. At 00:30 the card showed
    /// the new day, so tapping Isha marked tonight's, last night's stayed unmarked and the streak
    /// reset; where Isha itself starts after midnight it could never be marked at all. The countdown,
    /// the scrubber and the "Did you pray X?" question already file a prayer by its own day (P4).
    private var trackerDay: Date {
        let now = Date()
        let calendar = Calendar.current
        let fajr: Date? = {
            if let today = live.prayers, calendar.isDate(today.day, inSameDayAs: now) {
                return today.prayers.first { $0.nameTransliteration == "Fajr" }?.time
            }
            return settings.getPrayerTimes(for: calendar.startOfDay(for: now))?
                .first { $0.nameTransliteration == "Fajr" }?.time
        }()
        if let fajr, now < fajr, let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
            return yesterday
        }
        return now
    }

    var body: some View {
        let _ = RenderCounter.hit("PrayerTrackerSection")
        if live.prayers != nil {
            let today = trackerDay
            let week = weekDays(endingAt: today)
            // A chosen day counts only while it is one of the seven on the strip.
            let shown = chosenDay.flatMap { chosen in
                week.first { Calendar.current.isDate($0.date, inSameDayAs: chosen) }?.date
            } ?? today
            let showsToday = Calendar.current.isDate(shown, inSameDayAs: today)

            Section(header: header) {
                // Folded from the header's arrow, the rows are not in the List at all: the header and
                // its streak stay, and Prayer Settings' Prayer Tracker row still opens the history.
                if settings.tabSectionExpanded(.adhanTracker) {
                    // One view whichever arm draws (`OneRow`): the row is a card or a notice, never
                    // a bare branch.
                    OneRow {
                        if showsToday, settings.isTrackerExempt(on: today) {
                            exemptCard(day: today, week: week)
                        } else {
                            trackerCard(day: shown, today: today, week: week)
                        }
                    }
                    .trackerAskDialog($asking)

                    if settings.trackerSunnahEnabled, !settings.isTrackerExempt(on: shown) {
                        TrackerSunnahRow(day: shown)
                    }

                    NavigationLink {
                        LazyDestination {
                            PrayerTrackerView()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            AccentIconChip(systemImage: "chart.bar.xaxis", tint: settings.accentColor.accent2, size: 26)

                            Text("History & Insights")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    /// The tab-section header (TabSections.swift): the fold arrow, the trash while folded, and the
    /// streak as the section's read-out, which stays in sight while the rows are folded away.
    private var header: some View {
        TabSectionHeader(.adhanTracker) {
            let streak = settings.trackerStats.currentStreak
            if streak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                    Text(streak == 1 ? String(localized: "\(streak) day") : String(localized: "\(streak) days"))
                        .monospacedDigit()
                }
                .font(.caption2.weight(.semibold))
                .foregroundColor(settings.accentColor.accent2)
            }
        }
    }

    // MARK: The seven days

    /// Memo for `weekDays`: the strip is rebuilt only when a mark is written or the day it ends on
    /// changes, not on every pass of a tab that redraws with the countdown.
    private static var weekMemo: (generation: Int, end: Date, days: [TrackerWeekStrip.Day])?

    private func weekDays(endingAt end: Date) -> [TrackerWeekStrip.Day] {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: end)
        let generation = settings.trackerGeneration
        if let memo = Self.weekMemo, memo.generation == generation, memo.end == endDay { return memo.days }

        var days: [TrackerWeekStrip.Day] = []
        for back in stride(from: 6, through: 0, by: -1) {
            guard let stepped = calendar.date(byAdding: .day, value: -back, to: endDay) else { continue }
            // Midday, so the day's key is the same on a night the clocks change.
            let date = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: stepped) ?? stepped
            let canonical = settings.canonicalMarks(forDayKey: settings.trackerDayKey(for: date))
            days.append(TrackerWeekStrip.Day(
                id: days.count,
                date: date,
                marks: PrayerDayRing.marks(from: canonical),
                exempt: settings.isTrackerExempt(on: date),
                prayed: canonical.values.filter(\.isPrayed).count
            ))
        }
        Self.weekMemo = (generation, endDay, days)
        return days
    }

    // MARK: The card

    private func trackerCard(day: Date, today: Date, week: [TrackerWeekStrip.Day]) -> some View {
        let calendar = Calendar.current
        let slots = settings.trackableSlots(for: day)
        let isTrackerDay = calendar.isDate(day, inSameDayAs: today)
        let isCivilToday = calendar.isDateInToday(day)
        let exempt = settings.isTrackerExempt(on: day)
        let canonical = settings.canonicalMarks(forDayKey: settings.trackerDayKey(for: day))
        let now = Date()
        let headlineSlots = slots.map { (name: $0.displayName, time: $0.time, mark: settings.prayerMark(for: $0.nameTransliteration, on: day)) }
        // The day a pause ended: nothing is asked of a prayer whose time is over.
        let headline = settings.isTrackerResumeDay(on: day)
            ? TrackerDayHeadline.makeResumed(slots: headlineSlots, isToday: isCivilToday, now: now) { index in
                settings.prayerWindowHasEnded(forSlot: slots[index].nameTransliteration, on: day, at: now)
            }
            : TrackerDayHeadline.make(slots: headlineSlots, isToday: isCivilToday, now: now)

        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                TrackerRingBadge(marks: exempt ? PrayerDayRing.empty : PrayerDayRing.marks(from: canonical),
                                 exempt: exempt)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title(for: headline, day: day, isTrackerDay: isTrackerDay, isCivilToday: isCivilToday))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // Two lines held whatever it says, so the slots beneath never move while they
                    // are being tapped.
                    Text(exempt ? String(localized: "Exempt day. It does not count against your streaks.")
                                : headline.line(firstUse: settings.trackerStats.trackingSince == nil))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2, reservesSpace: true)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                Button("Today") {
                    settings.hapticFeedback()
                    chosenDay = nil
                }
                .buttonStyle(.accentChip(tint: settings.accentColor.accent2))
                // In place and inert while today is showing, so choosing a day never re-wraps the lines.
                .opacity(isTrackerDay ? 0 : 1)
                .disabled(isTrackerDay)
                .accessibilityHidden(isTrackerDay)
            }

            // Spacers BETWEEN the slots only, so the first circle starts at the row's left edge and
            // the last ends at its right - the equal-columns layout left both floating inset.
            HStack(spacing: 0) {
                ForEach(Array(slots.enumerated()), id: \.element.nameTransliteration) { index, prayer in
                    if index > 0 { Spacer(minLength: 6) }
                    TrackerPrayerToggle(prayer: prayer, date: day) { asking = $0 }
                }
            }
            // An exempt day keeps the slots' height and shows none of them.
            .opacity(exempt ? 0 : 1)
            .disabled(exempt)
            .accessibilityHidden(exempt)

            TrackerWeekStrip(days: week, shown: day) { picked in
                // Plain write: the card redraws for another day, its row stays the one row.
                chosenDay = Calendar.current.isDate(picked, inSameDayAs: today) ? nil : picked
            }
        }
        .padding(.vertical, 8)
    }

    private func title(for headline: TrackerDayHeadline, day: Date, isTrackerDay: Bool, isCivilToday: Bool) -> String {
        if isTrackerDay {
            switch headline {
            case .perfect, .complete: return String(localized: "All prayers completed")
            default: return isCivilToday ? String(localized: "Today") : String(localized: "Yesterday, until Fajr")
            }
        }
        return Self.dayTitle.string(from: day)
    }

    private static let dayTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMd")
        return formatter
    }()

    /// The card while today is exempt. With the pause on it says so and where to end it. With the
    /// pause off the day was recorded exempt by hand in the Day view (or by a build before
    /// 2026-11-18, which left the last day of a pause exempt), and Track Today undoes that here.
    /// Ending a pause never leads here now: it brings the tracker back at once (`Settings.pauseEnd`).
    private func exemptCard(day: Date, week: [TrackerWeekStrip.Day]) -> some View {
        let paused = settings.mensesPauseActive
        let isToday = Calendar.current.isDateInToday(day)
        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundColor(settings.accentColor.accent2)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(settings.accentColor.accent2.opacity(0.15)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(paused ? "Tracking paused" : (isToday ? "Today is exempt" : "Yesterday is exempt"))
                        .font(.subheadline.weight(.semibold))

                    Text(paused
                         ? "Exempt days never count against your streaks. Resume any time in History & Insights."
                         : "It won't count against your streaks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if !paused, settings.canEditExemption(on: day) {
                    Button(isToday ? "Track Today" : "Track Yesterday") {
                        settings.hapticFeedback()
                        // Plain write, as the Day view's exempt switch: the card swaps for the tracker,
                        // and that structural change must not animate. Tracking resumes partway
                        // through the day, so it is kept from counting against a streak.
                        settings.markTrackerResumeDay(day)
                        settings.setTrackerExempt(false, on: day)
                    }
                    .buttonStyle(.accentChip(tint: settings.accentColor.accent2))
                }
            }

            // The earlier days stay reachable through a pause: one of them may still want an answer.
            TrackerWeekStrip(days: week, shown: day) { picked in
                chosenDay = Calendar.current.isDate(picked, inSameDayAs: day) ? nil : picked
            }
        }
        .padding(.vertical, 8)
    }
}

/// The day ring with its count inside: "3/5", or a check once all five are prayed (green when all
/// five were on time, the accent when one was late). On an exempt day the moon sits in an empty ring.
struct TrackerRingBadge: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    let marks: [PrayerMark?]
    var exempt = false
    var size: CGFloat = 52

    var body: some View {
        let prayed = marks.filter { $0?.isPrayed == true }.count
        let total = PrayerDayRing.prayers.count

        ZStack {
            PrayerDayRing(marks: marks, lineWidth: size * 0.115)

            if exempt {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: size * 0.3))
                    .foregroundColor(.secondary)
            } else if prayed == total {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundColor(marks.allSatisfy { $0 == .onTime } ? PrayerMark.onTime.tint : settings.accentColor.accent2)
            } else {
                Text("\(prayed)/\(total)".localizedDigits)
                    .font(.system(size: size * 0.27, weight: .semibold).monospacedDigit())
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(exempt ? String(localized: "exempt") : String(localized: "\(prayed) of \(total) prayed"))
    }
}

// MARK: - The widgets' mirror (the app's side)

/// The app's half of `TrackerWidgetBridge` (Widget/Adhan/PrayerTrackerWidget.swift): it writes the
/// week the tracker widgets draw from, takes in the marks a widget made while the app was away, and
/// answers a widget's tap for real.
extension TrackerWidgetBridge {
    /// Once, at launch: from here on every tracker write reaches the widgets.
    static func install() {
        guard Settings.isAppProcess else { return }
        Settings.onTrackerChange = { schedulePublish() }
        schedulePublish()
    }

    private static var pendingPublish: DispatchWorkItem?

    /// A trailing debounce: a whole-day fill is five writes and should be one mirror and one reload.
    static func schedulePublish() {
        guard Settings.isAppProcess else { return }
        DispatchQueue.main.async {
            pendingPublish?.cancel()
            let work = DispatchWorkItem { publishNow() }
            pendingPublish = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
        }
    }

    /// Takes in what the widgets left, then writes the last eight days (and tomorrow, for a pause
    /// that covers it) and reloads the tracker widgets, only when something they show has changed.
    static func publishNow() {
        guard Settings.isAppProcess else { return }
        let settings = Settings.shared
        drainPending()

        var state = TrackerWidgetState()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for offset in -7...1 {
            guard let stepped = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let day = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: stepped) ?? stepped
            let key = settings.trackerDayKey(for: day)
            let marks = settings.canonicalMarks(forDayKey: key)
            if !marks.isEmpty { state.days[key] = marks.mapValues(\.rawValue) }
            if settings.isTrackerExempt(on: day) { state.exemptDays.append(key) }
            if settings.isTrackerResumeDay(on: day) { state.resumeDays = (state.resumeDays ?? []) + [key] }
        }
        state.streak = settings.trackerStats.currentStreak
        state.publishedDayKey = settings.trackerDayKey(for: Date())

        guard state != load() else { return }
        save(state)
        Settings.reloadWidgetKinds(kinds)
    }

    /// Records the marks a widget kept in the App Group. The queue is emptied BEFORE they are
    /// applied: each one is a tracker write, which schedules a mirror, which drains.
    static func drainPending() {
        var state = load()
        guard !state.pending.isEmpty else { return }
        let pending = state.pending
        state.pending = []
        save(state)
        let settings = Settings.shared
        for item in pending {
            guard let day = settings.trackerDate(forDayKey: item.dayKey) else { continue }
            settings.setPrayerMark(item.prayer, on: day, mark: PrayerMark(rawValue: item.mark))
        }
    }

    /// A widget's tap, in the app: the next answer in the widget's cycle, recorded like any other
    /// mark, and mirrored before the intent returns so the timeline the system reloads reads it.
    @MainActor
    static func tap(prayer: String, dayKey: String) {
        let settings = Settings.shared
        guard let day = settings.trackerDate(forDayKey: dayKey) else { return }
        settings.recordTrackerMark(next(after: settings.prayerMark(for: prayer, on: day)), for: prayer, on: day)
        pendingPublish?.cancel()
        publishNow()
    }
}
#endif
