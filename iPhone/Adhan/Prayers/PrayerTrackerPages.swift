#if os(iOS)
import SwiftUI

// The sections of the Prayer Tracker page that are not the history itself (PrayerTrackerView.swift):
// INSIGHTS, the missed prayers and their make-up list, the two opt-in extras (congregation and the
// Sunnah prayers), and the help page. Each is its own struct, so the page's body stays a list of
// sections and each one redraws on its own.

// MARK: - Small shared pieces

extension TrackerRange {
    var title: String {
        switch self {
        case .week: return String(localized: "7 Days")
        case .month: return String(localized: "30 Days")
        case .year: return String(localized: "Year")
        case .all: return String(localized: "All")
        }
    }
}

/// "84%" in the reader's digits, with the Arabic percent sign beside Arabic-Indic digits: the
/// translated sentences on the same card write "٧٨٪", and a Latin "%" after "٨٤" read as a slip.
func trackerPercentText(_ percent: Int) -> String {
    let plain = "\(percent)"
    let digits = plain.localizedDigits
    return digits + (digits == plain ? "%" : "٪")
}

/// The symbol the prayer list gives each of the five (`Settings.prayerProtos`). Fajr's is an iOS 17
/// symbol, and where it does not exist a row drawn here would lead with a blank.
func trackerPrayerSymbol(_ name: String) -> String {
    switch name {
    case "Fajr":
        if #available(iOS 17.0, *) { return "sun.horizon" }
        return "sunrise"
    case "Dhuhr": return "sun.max"
    case "Asr": return "sun.min"
    case "Maghrib": return "sunset"
    default: return "moon"
    }
}

/// One bar cut into coloured runs, over a faint track for whatever is left of `total`.
struct TrackerStackedBar: View {
    let parts: [(color: Color, count: Int)]
    let total: Int
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let shown = parts.filter { $0.count > 0 }
            let gaps = CGFloat(max(shown.count - 1, 0)) * 2
            let width = max(geo.size.width - gaps, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.14))

                HStack(spacing: 2) {
                    // By position: two runs can share a colour, a place in the bar cannot repeat.
                    ForEach(Array(shown.enumerated()), id: \.offset) { _, part in
                        Capsule()
                            .fill(part.color)
                            .frame(width: max(3, width * CGFloat(part.count) / CGFloat(max(total, 1))))
                    }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A card's caption line: the small accent chip and the small-caps title the stat tiles use.
private struct TrackerCardTitle<Trailing: View>: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    let title: String
    let symbol: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 6) {
            AccentIconChip(systemImage: symbol, tint: settings.accentColor.accent2, size: 20)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            trailing()
        }
    }
}

extension TrackerCardTitle where Trailing == EmptyView {
    init(title: String, symbol: String) {
        self.init(title: title, symbol: symbol) { EmptyView() }
    }
}

// MARK: - Insights

/// Where the prayers stand over a chosen span: the on-time share and how it moved, each of the five
/// on its own bar, the week by weekday, and what stands out, in a sentence each.
struct TrackerInsightsSection: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    @Binding var range: TrackerRange

    var body: some View {
        let insights = settings.trackerInsights(for: range)

        Section(header: Text("INSIGHTS")) {
            // A plain binding: an animated one makes the segmented indicator slide, snap back and slide.
            Picker("", selection: $range) {
                ForEach(TrackerRange.allCases) { range in
                    Text(range.title.localizedDigits).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            .onChange(of: range) { _ in settings.hapticFeedback() }
            .id("insights")

            if insights.hasMarks {
                summaryCard(insights)
                    .listRowSeparator(.hidden)

                prayersCard(insights)
                    .listRowSeparator(.hidden)

                if range != .week, insights.countedDays >= 14 {
                    weekdayCard(insights)
                        .listRowSeparator(.hidden)
                }

                if !notes(insights).isEmpty {
                    notesRow(notes(insights))
                        .listRowSeparator(.hidden)
                }

                if settings.trackerCongregationEnabled {
                    congregationCard(insights)
                        .listRowSeparator(.hidden)
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.subheadline)
                        .foregroundColor(settings.accentColor.accent2)
                        .frame(width: 22)

                    Text("Nothing is marked in this span yet. Mark a few prayers and their pattern shows here.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 6)
                .listRowSeparator(.hidden)
            }

            if settings.trackerSunnahEnabled, insights.countedDays > 0 {
                sunnahCard(insights)
                    .listRowSeparator(.hidden)
            }
        }
        .themedListRowBackground()
    }

    // MARK: On time, and against the span before

    private func summaryCard(_ insights: PrayerTrackerInsights) -> some View {
        let percent = PrayerTrackerInsights.percent(insights.onTimeShare)
        let parts: [(mark: PrayerMark, count: Int)] = [
            (.onTime, insights.onTime), (.late, insights.late), (.missed, insights.missed)
        ]

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("ON TIME")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)

                    Text(trackerPercentText(percent))
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(PrayerMark.onTime.tint)
                }

                Spacer(minLength: 8)

                if let change = insights.changeInPoints {
                    trendChip(change)
                }
            }

            TrackerStackedBar(parts: parts.map { ($0.mark.tint, $0.count) }, total: insights.due, height: 10)

            HStack(spacing: 12) {
                ForEach(parts.filter { $0.count > 0 }, id: \.mark) { part in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(part.mark.tint)
                            .frame(width: 7, height: 7)

                        // Led right to left in Arabic: the key is two arguments and a space, so nothing
                        // outside their isolates set the line's direction, and the count drew after the word.
                        Text(SymbolNumber.rightToLeftLine(String(localized: "\(part.count) \(part.mark.shortTitle.lowercased())")))
                    }
                }

                Spacer(minLength: 0)
            }
            .font(.caption2.monospacedDigit())
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            if let previous = insights.previousOnTimeShare {
                Text(previousLine(PrayerTrackerInsights.percent(previous)).localizedDigits)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .contentSurface(rectangle: true)
    }

    /// Whole sentences, one per span, so a translation can order them its own way.
    private func previousLine(_ percent: Int) -> String {
        switch range {
        case .week: return String(localized: "\(percent)% on time in the 7 days before")
        case .month: return String(localized: "\(percent)% on time in the 30 days before")
        case .year, .all: return String(localized: "\(percent)% on time in the year before")
        }
    }

    /// The move against the span before: up in the on-time green, down in the late orange (never
    /// the missed red: a slower month is not a failure), level in gray.
    private func trendChip(_ change: Int) -> some View {
        let tint: Color = change > 0 ? PrayerMark.onTime.tint : (change < 0 ? PrayerMark.late.tint : .secondary)
        let symbol = change > 0 ? "arrow.up.right" : (change < 0 ? "arrow.down.right" : "equal")

        return HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))

            Text(trackerPercentText(abs(change)))
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .foregroundColor(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(tint.opacity(0.14)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(change > 0 ? String(localized: "Up by \(change)")
                            : (change < 0 ? String(localized: "Down by \(-change)") : String(localized: "No change")))
    }

    // MARK: Each of the five

    private func prayersCard(_ insights: PrayerTrackerInsights) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TrackerCardTitle(title: String(localized: "ON TIME, BY PRAYER"), symbol: "chart.bar.fill")

            VStack(spacing: 9) {
                ForEach(insights.prayers) { line in
                    let percent = PrayerTrackerInsights.percent(line.onTimeShare)

                    HStack(spacing: 10) {
                        Text(trackerPrayerLabel(line.name, settings: settings))
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(width: 60, alignment: .leading)

                        TrackerStackedBar(
                            parts: [(PrayerMark.onTime.tint, line.onTime), (PrayerMark.late.tint, line.late),
                                    (PrayerMark.missed.tint, line.missed)],
                            total: line.due
                        )

                        Text(trackerPercentText(percent))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundColor(line.due > 0 ? .primary : .secondary)
                            .frame(width: 42, alignment: .trailing)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(trackerPrayerLabel(line.name, settings: settings)): \(percent)% \(PrayerMark.onTime.shortTitle)")
                }
            }
        }
        .padding(12)
        .contentSurface(rectangle: true)
    }

    // MARK: The week

    private func weekdayCard(_ insights: PrayerTrackerInsights) -> some View {
        let calendar = Calendar.current
        let accent = settings.accentColor.accent2
        let weakest = insights.weakestWeekday?.weekday
        // In the week's own order: Sunday first in one region, Monday or Saturday in another.
        let ordered = (0..<7).map { insights.weekdays[(calendar.firstWeekday - 1 + $0) % 7] }
        let letters = calendar.veryShortStandaloneWeekdaySymbols

        return VStack(alignment: .leading, spacing: 10) {
            TrackerCardTitle(title: String(localized: "ON TIME, BY WEEKDAY"), symbol: "calendar")

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(ordered) { day in
                    let percent = PrayerTrackerInsights.percent(day.onTimeShare)
                    let tint = day.weekday == weakest ? PrayerMark.late.tint : accent

                    VStack(spacing: 4) {
                        Text(day.due > 0 ? "\(percent)".localizedDigits : "")
                            .font(.system(size: 9, weight: .semibold).monospacedDigit())
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.secondary.opacity(0.12))

                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(tint)
                                .frame(height: max(day.due > 0 ? 3 : 0, 44 * CGFloat(day.onTimeShare)))
                        }
                        .frame(height: 44)

                        Text(letters.indices.contains(day.weekday - 1) ? letters[day.weekday - 1] : "")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(day.weekday == weakest ? tint : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(weekdayName(day.weekday)): \(percent)% \(PrayerMark.onTime.shortTitle)")
                }
            }
        }
        .padding(12)
        .contentSurface(rectangle: true)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let names = Calendar.current.standaloneWeekdaySymbols
        return names.indices.contains(weekday - 1) ? names[weekday - 1] : ""
    }

    // MARK: What stands out

    private struct Note: Identifiable {
        let id: Int
        let symbol: String
        let text: String
    }

    private func notes(_ insights: PrayerTrackerInsights) -> [Note] {
        var lines: [(String, String)] = []
        if insights.due > 0, insights.onTime == insights.due {
            lines.append(("checkmark.seal.fill", String(localized: "Every prayer on time in this span. Alhamdulillah.")))
        }
        if let strongest = insights.strongest {
            let percent = PrayerTrackerInsights.percent(strongest.onTimeShare)
            lines.append(("star.fill", String(localized: "\(trackerPrayerLabel(strongest.name, settings: settings)) is your strongest prayer, on time \(percent)% of the time.")))
        }
        if let weakest = insights.weakest {
            let percent = PrayerTrackerInsights.percent(weakest.onTimeShare)
            lines.append(("target", String(localized: "\(trackerPrayerLabel(weakest.name, settings: settings)) is the one to guard, on time \(percent)% of the time.")))
        }
        if let day = insights.weakestWeekday {
            let percent = PrayerTrackerInsights.percent(day.onTimeShare)
            lines.append(("calendar", String(localized: "\(weekdayName(day.weekday)) is your hardest day, on time \(percent)% of the time.")))
        }
        return lines.enumerated().map { Note(id: $0.offset, symbol: $0.element.0, text: $0.element.1) }
    }

    private func notesRow(_ notes: [Note]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(notes) { note in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: note.symbol)
                        .font(.footnote)
                        .foregroundColor(settings.accentColor.accent2)
                        .frame(width: 20)
                        .padding(.top, 1)

                    Text(note.text.localizedDigits)
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: In congregation

    private func congregationCard(_ insights: PrayerTrackerInsights) -> some View {
        let share = insights.prayed > 0 ? Double(insights.congregation) / Double(insights.prayed) : 0

        return VStack(alignment: .leading, spacing: 10) {
            TrackerCardTitle(title: String(localized: "IN CONGREGATION"), symbol: "person.2.fill") {
                Text(trackerPercentText(PrayerTrackerInsights.percent(share)))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundColor(TrackerTint.congregation)
            }

            HStack(spacing: 4) {
                ForEach(insights.prayers) { line in
                    VStack(spacing: 2) {
                        Text("\(line.congregation)".localizedDigits)
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundColor(line.congregation > 0 ? .primary : .secondary)

                        Text(trackerPrayerLabel(line.name, settings: settings))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text(String(localized: "\(insights.congregation) of \(insights.prayed) prayers in congregation").localizedDigits)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .contentSurface(rectangle: true)
    }

    // MARK: Sunnah prayers

    private func sunnahCard(_ insights: PrayerTrackerInsights) -> some View {
        let accent = settings.accentColor.accent2
        let days = insights.countedDays

        return VStack(alignment: .leading, spacing: 10) {
            TrackerCardTitle(title: String(localized: "SUNNAH PRAYERS"), symbol: "sparkles")

            VStack(spacing: 8) {
                ForEach(SunnahPrayer.allCases, id: \.self) { prayer in
                    let count = insights.sunnah[prayer] ?? 0

                    HStack(spacing: 10) {
                        Text(prayer.title)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(width: 96, alignment: .leading)

                        TrackerStackedBar(parts: [(accent, count)], total: days, height: 6)

                        Text("\(count)/\(days)".localizedDigits)
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundColor(count > 0 ? .primary : .secondary)
                            .frame(width: 50, alignment: .trailing)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(prayer.title): \(count) / \(days)")
                }
            }

            Text((insights.fullRawatibDays == 1
                  ? String(localized: "All twelve regular rak'at on \(insights.fullRawatibDays) day")
                  : String(localized: "All twelve regular rak'at on \(insights.fullRawatibDays) days")).localizedDigits)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .contentSurface(rectangle: true)
    }
}

// MARK: - Missed prayers and the make-up list

extension Settings {
    private static var missedPrayersMemo: (generation: Int, list: [MissedPrayer])?

    /// `missedPrayers()` behind the tracker's write counter: the page asks on every pass, and the
    /// answer is a walk over the whole history.
    var missedPrayersNow: [MissedPrayer] {
        let generation = trackerGeneration
        if let memo = Self.missedPrayersMemo, memo.generation == generation { return memo.list }
        let list = missedPrayers()
        Self.missedPrayersMemo = (generation, list)
        return list
    }
}

/// The doorway to the make-up list, on the page only while something is on it. The missed marks
/// were scattered red dots across months of history; here they are counted and one tap away.
struct TrackerMissedSection: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared

    var body: some View {
        let count = settings.missedPrayersNow.count
        if count > 0 {
            Section(
                header: Text("TO MAKE UP"),
                footer: Text(String(localized: "Missed a prayer? Pray it as soon as you remember. The Prophet ﷺ said: \"Whoever forgets a prayer, let him pray it when he remembers it\" (Bukhari 597). Then mark it here as prayed late.").localizedDigits)
            ) {
                NavigationLink {
                    LazyDestination {
                        MissedPrayersView()
                    }
                } label: {
                    HStack(spacing: 12) {
                        AccentIconChip(systemImage: "clock.arrow.circlepath", tint: settings.accentColor.accent2, size: 26)

                        Text("Missed Prayers")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        Spacer(minLength: 4)

                        Text("\(count)".localizedDigits)
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(PrayerMark.missed.tint))
                    }
                    .padding(.vertical, 2)
                }
                .id("missed")
            }
            .themedListRowBackground()
        }
    }
}

/// Every prayer marked missed, newest first, a month to a section. "Prayed It Later" records the
/// prayer as prayed late and takes it off the list; a swipe clears a mark that was a mistake.
struct MissedPrayersView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared

    private struct Month: Identifiable {
        /// "2026-11".
        let id: String
        let title: String
        let prayers: [Settings.MissedPrayer]
    }

    /// The list in month sections, in the order it already has (newest day first).
    private var months: [Month] {
        var result: [Month] = []
        for prayer in settings.missedPrayersNow {
            let key = String(prayer.dayKey.prefix(7))
            if let last = result.last, last.id == key {
                result[result.count - 1] = Month(id: key, title: last.title, prayers: last.prayers + [prayer])
            } else {
                result.append(Month(id: key, title: Self.monthTitle.string(from: prayer.date), prayers: [prayer]))
            }
        }
        return result
    }

    /// Plain writes throughout: an answered row leaves the list, and a row set that changes must
    /// not animate on this stack (the rule PrayerTrackerView states on its body).
    var body: some View {
        let months = months

        List {
            if months.isEmpty {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundColor(PrayerMark.onTime.tint)
                            .frame(width: 22)

                        Text("Nothing to make up. Alhamdulillah.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
                .themedListRowBackground()
            } else {
                ForEach(months) { month in
                    Section(header: Text(month.title.localizedDigits)) {
                        ForEach(month.prayers) { prayer in
                            row(prayer)
                        }
                    }
                    .themedListRowBackground()
                }
            }
        }
        .applyConditionalListStyle()
        .navigationTitle("Missed Prayers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ prayer: Settings.MissedPrayer) -> some View {
        let name = trackerPrayerLabel(prayer.prayerName, settings: settings)

        return HStack(spacing: 12) {
            Image(systemName: trackerPrayerSymbol(prayer.prayerName))
                .font(.subheadline)
                .foregroundColor(PrayerMark.missed.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Text(Self.dayTitle.string(from: prayer.date).localizedDigits)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            Button("Prayed It Later") {
                settings.hapticFeedback()
                settings.recordTrackerMark(.late, for: prayer.prayerName, on: prayer.date)
            }
            .buttonStyle(.accentChip(tint: settings.accentColor.accent2))
        }
        // A whole number of points at the standard text size. The two lines measure 38.33, and a
        // list of rows a third of a point off the pixel grid drew a one-pixel gap between two of
        // its cells (the page's black showing through, read off a screenshot).
        .frame(minHeight: 50)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Not Missed") {
                settings.recordTrackerMark(nil, for: prayer.prayerName, on: prayer.date)
            }
            .tint(.gray)
        }
        .accessibilityElement(children: .combine)
    }

    // The tracker's days are Gregorian keys, whatever calendar the phone is set to.
    private static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    private static let monthTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = gregorian
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()

    private static let dayTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = gregorian
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMd")
        return formatter
    }()
}

// MARK: - A whole day at once

/// The whole-day choices, wherever a menu offers them (the Day view's row, a month day's hold menu).
/// A fill takes the prayers still unanswered and leaves every answer already given.
struct TrackerWholeDayMenuItems: View {
    private let settings = Settings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    let day: Date

    var body: some View {
        let slots = settings.trackableSlots(for: day)
        let marked = slots.filter { settings.prayerMark(for: $0.nameTransliteration, on: day) != nil }.count
        let open = slots.filter {
            settings.prayerMark(for: $0.nameTransliteration, on: day) == nil
                && settings.canMarkPrayer(startingAt: $0.time, on: day)
        }.count

        Section {
            ForEach(PrayerMark.allCases, id: \.self) { mark in
                Button {
                    settings.hapticFeedback()
                    settings.setWholeDay(mark, on: day)
                } label: {
                    Label(title(mark, rest: marked > 0), systemImage: mark.symbol)
                }
                .disabled(open == 0)
            }
        }

        Section {
            Button(role: .destructive) {
                settings.hapticFeedback()
                settings.setWholeDay(nil, on: day)
            } label: {
                Label("Clear the Day", systemImage: "arrow.uturn.backward")
            }
            .disabled(marked == 0)
        }
    }

    private func title(_ mark: PrayerMark, rest: Bool) -> String {
        switch (mark, rest) {
        case (.onTime, false): return String(localized: "Mark All On Time")
        case (.late, false): return String(localized: "Mark All Late")
        case (.missed, false): return String(localized: "Mark All Missed")
        case (.onTime, true): return String(localized: "Mark the Rest On Time")
        case (.late, true): return String(localized: "Mark the Rest Late")
        case (.missed, true): return String(localized: "Mark the Rest Missed")
        }
    }
}

// MARK: - Sunnah prayers in the Day view

/// The day's Sunnah prayers as one row of the Day view: eight chips, two across. A chip is ticked or
/// not; there is nothing to be late for and nothing to miss.
struct TrackerSunnahDayBlock: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    let day: Date

    var body: some View {
        let prayed = settings.sunnahPrayed(on: day)
        let all = SunnahPrayer.allCases
        let accent = settings.accentColor.accent2

        VStack(alignment: .leading, spacing: 8) {
            TrackerCardTitle(title: String(localized: "SUNNAH PRAYERS"), symbol: "sparkles") {
                Text("\(prayed.count)/\(all.count)".localizedDigits)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundColor(prayed.isEmpty ? .secondary : accent)
            }

            VStack(spacing: 6) {
                // Rows of two, by position.
                ForEach(0..<(all.count + 1) / 2, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<2, id: \.self) { column in
                            let index = row * 2 + column
                            if all.indices.contains(index) {
                                chip(all[index], selected: prayed.contains(all[index]), tint: accent)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func chip(_ prayer: SunnahPrayer, selected: Bool, tint: Color) -> some View {
        Button {
            settings.hapticFeedback()
            settings.setSunnahPrayed(prayer, on: day, !selected)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: selected ? "checkmark" : prayer.symbol)
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 14)

                Text(prayer.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(selected ? .white : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(selected ? tint : tint.opacity(0.12)))
            .overlay(Capsule().strokeBorder(tint.opacity(selected ? 0 : 0.35), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(prayer.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Also Track

/// The tracker's two opt-in extras. Off by default: the tracker a reader has always had is the five
/// prayers and nothing more, and one reader had asked for less on the tab, not more.
struct TrackerAlsoTrackSection: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared

    var body: some View {
        Section(
            header: Text("ALSO TRACK"),
            footer: Text(String(localized: "Both are optional. A Sunnah prayer is ticked or left: leaving one is never counted as missed and never touches a streak. The regular Sunnah prayers are twelve rak'at a day: four before Dhuhr and two after it, two after Maghrib, two after Isha and two before Fajr. Whoever keeps twelve is promised a house in Paradise (Sahih Muslim 728).").localizedDigits)
        ) {
            // Plain writes: each switch adds rows to the Day view and the Insights (see the page's body).
            toggle(String(localized: "In Congregation"),
                   caption: String(localized: "A prayed prayer can also be marked as prayed in congregation."),
                   isOn: Binding(get: { settings.trackerCongregationEnabled },
                                 set: { settings.hapticFeedback(); settings.trackerCongregationEnabled = $0 }))
                .id("more")

            toggle(String(localized: "Sunnah Prayers"),
                   caption: String(localized: "The twelve regular rak'at, Witr, Duha and the night prayer, ticked beside the five."),
                   isOn: Binding(get: { settings.trackerSunnahEnabled },
                                 set: { settings.hapticFeedback(); settings.trackerSunnahEnabled = $0 }))
        }
        .themedListRowBackground()
    }

    private func toggle(_ title: String, caption: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)

                Text(caption)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(settings.accentColor.accent2)
        .padding(.vertical, 2)
    }
}

// MARK: - Help

/// The page's last section: how the tracker works (its own page now: six paragraphs sat here at the
/// bottom of every visit), and the door to the reminders that change what the tracker records.
struct TrackerHelpSection: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    var body: some View {
        Section(header: Text("GOOD TO KNOW")) {
            NavigationLink {
                LazyDestination {
                    TrackerHelpView()
                }
            } label: {
                HStack(spacing: 12) {
                    AccentIconChip(systemImage: "questionmark", tint: settings.accentColor.accent2, size: 26)

                    Text("How the Tracker Works")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 2)
            }
            .id("help")

            // The tracker records what happened; notifications are what change it. Someone looking
            // at a row of missed prayers is exactly the person nagging mode was built for, so the
            // setting is named and reachable from here rather than only from Settings.
            NavigationLink(destination: LazyDestination { MoreNotificationView() }) {
                HStack(alignment: .top, spacing: 12) {
                    AccentIconChip(systemImage: "bell.badge.fill", tint: settings.accentColor.accent2, size: 26)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Struggling to pray on time?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(naggingBlurb.localizedDigits)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 2)
            }
            .tint(settings.accentColor.color)
        }
        .themedListRowBackground()
    }

    /// Says what the reminders would do, or what they are already doing: a reader who has nagging
    /// mode on should not be told to turn it on.
    private var naggingBlurb: String {
        if settings.naggingMode {
            return String(localized: "Nagging mode is on: you are reminded before each prayer, then every 15 minutes, with final nudges at 10 and 5 minutes left. Adjust which prayers nag, and when they start, here.")
        }
        return String(localized: "Turn on prayer notifications, or nagging mode, to be reminded before each prayer and again every 15 minutes until you have prayed.")
    }
}

/// How the tracker works, a line per rule.
struct TrackerHelpView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    var body: some View {
        List {
            Section(header: Text("THE RING")) {
                HStack(spacing: 14) {
                    PrayerDayRing(marks: [.onTime, .onTime, .late, .missed, nil], lineWidth: 6)
                        .frame(width: 52, height: 52)

                    Text("The ring is one day: five arcs, Fajr at the top and on round the clock to Isha. Green is prayed on time, orange is prayed late, red is missed, and gray is not answered yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 6)
            }
            .themedListRowBackground()

            Section(header: Text("MARKING")) {
                VStack(alignment: .leading, spacing: 12) {
                    row("hand.tap", String(localized: "Tap a prayer to mark it prayed on time, and tap again to clear it. Press and hold to record it as prayed late or missed; the Day view offers all three directly."))

                    row("questionmark.bubble", String(localized: "Once a prayer's time has ended, a tap asks whether it was on time or late, so a prayer ticked hours afterward is recorded as it was."))

                    row("lock", String(localized: "A prayer can be marked only once its time has come in, so today's row shows what is still left to pray. Past days can always be filled in here."))

                    row("calendar", String(localized: "The seven rings under the card are the past week. Tap one to put that day on the card and answer it there."))

                    row("checklist", String(localized: "Mark the Whole Day, in the Day view or by holding a day of the month, answers every prayer still open at once and leaves the answers already given."))
                }
                .padding(.vertical, 8)
            }
            .themedListRowBackground()

            Section(header: Text("WHAT COUNTS")) {
                VStack(alignment: .leading, spacing: 12) {
                    row("person.3", String(localized: "Jumuah (Friday prayer) counts as Dhuhr; marking either one covers that day's noon prayer."))

                    row("airplane", String(localized: "While traveling, the combined Dhuhr/Asr and Maghrib/Isha each count as both of their prayers."))

                    row("clock.arrow.circlepath", String(localized: "Missed a prayer? Pray it as soon as you remember. The Prophet ﷺ said: \"Whoever forgets a prayer, let him pray it when he remembers it\" (Bukhari 597). Then mark it here as prayed late."))

                    row("flame", String(localized: "A streak is a day where all five prayers were prayed, on time or late. A perfect day is all five on time. Exempt days never break a streak; it continues right through them."))
                }
                .padding(.vertical, 8)
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How the Tracker Works")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.footnote)
                .foregroundColor(settings.accentColor.accent2)
                .frame(width: 20)
                .padding(.top, 1)

            Text(text.localizedDigits)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
