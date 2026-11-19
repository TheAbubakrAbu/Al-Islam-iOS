#if os(iOS)
import AppIntents
import SwiftUI
import WidgetKit

// The Prayer Tracker on the Home Screen and the Lock Screen (Abu, 2026-11-18). The day ring the
// Adhan tab's card leads with, the line about what is waiting, and on the Home Screen a tap that
// marks a prayer without opening the app.
//
// The tracker's records live in the app's own defaults, which a widget cannot read. So the app
// mirrors a week of them into the App Group (`TrackerWidgetState`, written by `TrackerWidgetBridge`
// in PrayerTrackerCard.swift on every tracker write), and the widgets draw from that. This file
// compiles into the app and the extension; each supplies its own `TrackerWidgetBridge.tap`.

// MARK: - The mirrored state

/// A week of the tracker as the widgets need it. Days are the tracker's own Gregorian keys.
struct TrackerWidgetState: Codable, Equatable {
    /// Day key to canonical prayer to `PrayerMark` raw value.
    var days: [String: [String: String]] = [:]
    var exemptDays: [String] = []
    /// The days of the week a pause ended on (`Settings.isTrackerResumeDay`). Optional so a state
    /// written before the field existed still decodes.
    var resumeDays: [String]?
    /// The streak as the app last counted it, and the day it counted on: a streak is only shown
    /// while it can still be true (see `TrackerWidgetModel.streak`).
    var streak = 0
    var publishedDayKey = ""
    /// Marks made on a widget while the app was not there to record them. The app takes them into
    /// its own store the next time it runs (`TrackerWidgetBridge.drainPending`).
    var pending: [Pending] = []

    struct Pending: Codable, Equatable {
        var dayKey: String
        /// The slot as the list names it ("Asr", "Dhuhr/Asr", "Jumuah").
        var prayer: String
        /// A `PrayerMark` raw value, or "" to clear.
        var mark: String
    }

    func marks(on dayKey: String) -> [String: PrayerMark] {
        (days[dayKey] ?? [:]).compactMapValues(PrayerMark.init(rawValue:))
    }

    /// The mark a slot shows: what its canonical prayers share, the weaker where they differ, nil
    /// while any of them is unanswered (`Settings.prayerMark(for:on:)`, on the mirrored week).
    func mark(for slot: String, on dayKey: String) -> PrayerMark? {
        let day = marks(on: dayKey)
        var result: PrayerMark?
        let covered = Settings.canonicalCoverage(of: slot)
        guard !covered.isEmpty else { return nil }
        for canonical in covered {
            guard let mark = day[canonical] else { return nil }
            if let current = result, current.rank <= mark.rank { continue }
            result = mark
        }
        return result
    }

    mutating func set(_ mark: PrayerMark?, for slot: String, on dayKey: String) {
        var day = days[dayKey] ?? [:]
        for canonical in Settings.canonicalCoverage(of: slot) {
            day[canonical] = mark?.rawValue
        }
        days[dayKey] = day.isEmpty ? nil : day
    }
}

enum TrackerWidgetBridge {
    static let storageKey = "trackerWidgetState"
    static let kinds = [AdhanWidgetKind.PrayerTrackerWidget.rawValue, AdhanWidgetKind.PrayerTrackerLockWidget.rawValue]

    private static let store = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

    static func load() -> TrackerWidgetState {
        guard let data = store?.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(TrackerWidgetState.self, from: data) else { return TrackerWidgetState() }
        return state
    }

    static func save(_ state: TrackerWidgetState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        store?.set(data, forKey: storageKey)
    }

    /// What a tap on a widget's slot moves to: prayed on time, then prayed late, then clear. A
    /// widget cannot ask a question, so the second tap is how "late" is said there.
    static func next(after mark: PrayerMark?) -> PrayerMark? {
        switch mark {
        case nil: return .onTime
        case .onTime: return .late
        case .late, .missed: return nil
        }
    }
}

// MARK: - The tap

/// A tap on one of a tracker widget's slots. A Live Activity intent because that is the kind the
/// system runs in the APP's process (launching it in the background when it is not running), where
/// the mark can be recorded for real: the store, the streak, and the reminders still asking about
/// that prayer all change at once. Should it ever run in the extension instead, the extension's
/// `tap` keeps the mark in the App Group for the app to take in (`TrackerWidgetState.pending`).
@available(iOS 17.0, *)
struct TrackerMarkIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Mark Prayer"
    static var description = IntentDescription("Marks a prayer in the Prayer Tracker.")
    /// It needs a prayer and a day only a widget's button supplies.
    static var isDiscoverable = false

    @Parameter(title: "Prayer") var prayer: String
    @Parameter(title: "Day") var dayKey: String

    init() {}

    init(prayer: String, dayKey: String) {
        self.prayer = prayer
        self.dayKey = dayKey
    }

    func perform() async throws -> some IntentResult {
        let (prayer, dayKey) = (prayer, dayKey)
        await MainActor.run { TrackerWidgetBridge.tap(prayer: prayer, dayKey: dayKey) }
        return .result()
    }
}

// MARK: - What a widget shows

/// One entry's tracker, resolved once: the day it is about, its slots, its ring and its line.
struct TrackerWidgetModel {
    struct Slot: Identifiable {
        let name: String
        let displayName: String
        let symbol: String
        let mark: PrayerMark?
        let canMark: Bool
        var id: String { name }
    }

    let dayKey: String
    let isToday: Bool
    let slots: [Slot]
    let ring: [PrayerMark?]
    let exempt: Bool
    let prayed: Int
    let headline: TrackerDayHeadline
    /// 0 when there is none to show.
    let streak: Int

    /// The first slot begun and unanswered: what the small widget's one button marks.
    var waiting: Slot? { slots.first { $0.canMark && $0.mark == nil } }

    init(entry: PrayersEntry, state: TrackerWidgetState = TrackerWidgetBridge.load()) {
        let settings = Settings.shared
        let calendar = Calendar.current
        let list = entry.prayers
            .filter { Settings.trackablePrayerNames.contains($0.nameTransliteration) }
            .sorted { $0.time < $1.time }

        // The prayer day: yesterday until the entry's Fajr begins, as on the Adhan tab's card.
        var day = entry.date
        var today = true
        if let fajr = list.first(where: { $0.nameTransliteration == "Fajr" })?.time, entry.date < fajr,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: entry.date) {
            day = yesterday
            today = false
        }
        let key = settings.trackerDayKey(for: day)
        dayKey = key
        isToday = today
        exempt = state.exemptDays.contains(key)

        slots = list.map { prayer in
            Slot(name: prayer.nameTransliteration,
                 displayName: prayer.displayName.localizedDisplay,
                 symbol: prayer.image,
                 mark: state.mark(for: prayer.nameTransliteration, on: key),
                 // Every slot of yesterday has begun; today's wait for their time.
                 canMark: !today || prayer.time <= entry.date)
        }
        let canonical = state.marks(on: key)
        ring = PrayerDayRing.marks(from: canonical)
        prayed = canonical.values.filter(\.isPrayed).count
        let headlineSlots = zip(list, slots).map { (name: $1.displayName, time: $0.time, mark: $1.mark) }
        headline = state.resumeDays?.contains(key) == true
            ? TrackerDayHeadline.makeResumed(slots: headlineSlots, isToday: today, now: entry.date)
            : TrackerDayHeadline.make(slots: headlineSlots, isToday: today, now: entry.date)

        // The app counted the streak on `publishedDayKey`. It still stands if that was this entry's
        // civil day, or if the day before this one closed complete (or exempt, or was the day a
        // pause ended, which ends no streak): otherwise a day has gone by unanswered since, and the
        // number would be a streak that has ended.
        let entryKey = settings.trackerDayKey(for: entry.date)
        let dayBefore = calendar.date(byAdding: .day, value: -1, to: entry.date).map(settings.trackerDayKey(for:)) ?? ""
        let closed = state.marks(on: dayBefore).values.filter(\.isPrayed).count == PrayerDayRing.prayers.count
            || state.exemptDays.contains(dayBefore)
            || state.resumeDays?.contains(dayBefore) == true
        streak = (state.publishedDayKey == entryKey || closed) ? state.streak : 0
    }

    var title: String {
        if exempt { return String(localized: "Exempt day") }
        switch headline {
        case .perfect, .complete: return String(localized: "All prayers completed")
        default: return isToday ? String(localized: "Today") : String(localized: "Yesterday, until Fajr")
        }
    }

    var line: String {
        if exempt { return String(localized: "It won't count against your streaks.") }
        return headline.line()
    }
}

/// The day ring with its count inside, for a widget: "3/5", a check when all five are prayed, the
/// moon on an exempt day.
private struct TrackerWidgetRing: View {
    let model: TrackerWidgetModel
    var size: CGFloat
    var monochrome = false

    var body: some View {
        let total = PrayerDayRing.prayers.count

        ZStack {
            PrayerDayRing(marks: model.exempt ? PrayerDayRing.empty : model.ring, lineWidth: size * 0.12,
                          monochrome: monochrome)

            if model.exempt {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: size * 0.3))
                    .foregroundStyle(.secondary)
            } else if model.prayed == total {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundStyle(monochrome ? AnyShapeStyle(.primary) : AnyShapeStyle(PrayerMark.onTime.tint))
            } else {
                Text("\(model.prayed)/\(total)".localizedDigits)
                    .font(.system(size: size * 0.27, weight: .semibold).monospacedDigit())
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.exempt ? String(localized: "exempt") : String(localized: "\(model.prayed) of \(total) prayed"))
    }
}

private struct TrackerWidgetStreak: View {
    let streak: Int
    let tint: Color

    var body: some View {
        if streak > 0 {
            HStack(spacing: 2) {
                Image(systemName: "flame.fill")
                Text("\(streak)".localizedDigits)
                    .monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "\(streak)-day streak"))
        }
    }
}

/// A view that runs the tap where buttons in widgets exist (iOS 17), and is plain where they do not:
/// there a tap anywhere opens the app, as every widget's does.
private struct TrackerWidgetButton<Label: View>: View {
    let prayer: String
    let dayKey: String
    var enabled = true
    @ViewBuilder var label: () -> Label

    var body: some View {
        if #available(iOS 17.0, *), enabled {
            Button(intent: TrackerMarkIntent(prayer: prayer, dayKey: dayKey)) {
                label()
            }
            .buttonStyle(.plain)
        } else {
            label()
        }
    }
}

// MARK: - Home screen, small

/// The ring, the streak, the line about the day, and one button: the prayer that is waiting.
struct PrayerTrackerSmallView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        let tint = entry.accentColor.color
        let model = TrackerWidgetModel(entry: entry)

        if model.slots.isEmpty {
            PrayerWidgetEmptyState(tint: tint, skyStyle: false)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    TrackerWidgetRing(model: model, size: 50)

                    Spacer(minLength: 4)

                    TrackerWidgetStreak(streak: model.streak, tint: tint)
                }

                Spacer(minLength: 4)

                Text(model.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let waiting = model.waiting, !model.exempt {
                    Text(waiting.displayName)
                        .font(.headline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.bottom, 6)

                    TrackerWidgetButton(prayer: waiting.name, dayKey: model.dayKey) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Prayed")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(tint)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Capsule().fill(tint.opacity(0.16)))
                        .contentShape(Capsule())
                    }
                    .accessibilityLabel(String(localized: "Mark \(waiting.displayName) prayed"))
                } else {
                    Text(model.line)
                        .font(.caption.weight(.medium))
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - Home screen, medium

/// The ring and the streak beside the day's five slots, each a button: a tap is prayed on time, a
/// second is late, a third clears.
struct PrayerTrackerMediumView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        let tint = entry.accentColor.color
        let model = TrackerWidgetModel(entry: entry)

        if model.slots.isEmpty {
            PrayerWidgetEmptyState(tint: tint, skyStyle: false)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    TrackerWidgetRing(model: model, size: 46)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(model.line)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 4)

                    TrackerWidgetStreak(streak: model.streak, tint: tint)
                }

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    ForEach(Array(model.slots.enumerated()), id: \.element.id) { index, slot in
                        if index > 0 { Spacer(minLength: 4) }
                        slotButton(slot, model: model)
                    }
                }
                .opacity(model.exempt ? 0.35 : 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func slotButton(_ slot: TrackerWidgetModel.Slot, model: TrackerWidgetModel) -> some View {
        let tint = slot.mark?.tint ?? Color.secondary

        return TrackerWidgetButton(prayer: slot.name, dayKey: model.dayKey, enabled: slot.canMark && !model.exempt) {
            VStack(spacing: 4) {
                ZStack {
                    if let mark = slot.mark {
                        Circle()
                            .fill(tint)

                        Image(systemName: mark.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.1))

                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)

                        Image(systemName: slot.symbol)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 36, height: 36)

                Text(slot.displayName)
                    .font(.caption2.weight(slot.mark != nil ? .semibold : .regular))
                    .foregroundStyle(slot.mark != nil ? tint : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .contentShape(Rectangle())
        }
        .opacity(slot.canMark ? 1 : 0.4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(slot.displayName): \(slot.canMark ? (slot.mark?.spokenTitle ?? String(localized: "not marked")) : String(localized: "not yet"))")
    }
}

// MARK: - Lock screen

/// Circular: the ring alone, with its count. Rectangular: the ring beside the day's line.
struct PrayerTrackerLockView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.previewWidgetFamily) private var previewFamily
    var entry: PrayersProvider.Entry

    var body: some View {
        let model = TrackerWidgetModel(entry: entry)

        if model.slots.isEmpty {
            Text("Open app to get prayer times")
                .font(.caption)
        } else if (previewFamily ?? widgetFamily) == .accessoryCircular {
            TrackerWidgetRing(model: model, size: 54, monochrome: true)
        } else {
            HStack(spacing: 10) {
                TrackerWidgetRing(model: model, size: 52, monochrome: true)

                VStack(alignment: .leading, spacing: 0) {
                    Text(model.exempt ? String(localized: "Exempt day")
                                      : String(localized: "\(model.prayed) of \(PrayerDayRing.prayers.count) prayed"))
                        .font(.headline.bold())

                    Text(model.line)
                        .font(.subheadline)
                        .lineLimit(2)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - The widgets

@available(iOS 16.0, *)
struct PrayerTrackerWidget: Widget {
    let kind: String = AdhanWidgetKind.PrayerTrackerWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerTrackerHomeView(entry: entry)
                .widgetContainerBackground(legacyPadding: true)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Prayer Tracker")
        .description("Today's five prayers as a ring, and a tap to mark one prayed")
    }
}

/// Small or medium, by the family the widget was placed at.
struct PrayerTrackerHomeView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.previewWidgetFamily) private var previewFamily
    var entry: PrayersProvider.Entry

    var body: some View {
        if (previewFamily ?? widgetFamily) == .systemMedium {
            PrayerTrackerMediumView(entry: entry)
        } else {
            PrayerTrackerSmallView(entry: entry)
        }
    }
}

@available(iOS 16.1, *)
struct PrayerTrackerLockWidget: Widget {
    let kind: String = AdhanWidgetKind.PrayerTrackerLockWidget.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayerTrackerLockView(entry: entry)
                .widgetContainerBackground(accessory: true)
        }
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
        .configurationDisplayName("Prayer Tracker")
        .description("Today's five prayers as a ring: which are prayed, and which is next")
    }
}
#endif
