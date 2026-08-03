#if os(iOS)
import SwiftUI

struct CalendarView: View {
    @ObservedObject private var settings = Settings.shared

    enum DisplayMode: String {
        case events, calendar
    }

    // Persisted so the tab remembers its last mode. Kept in @State (not bound directly to @AppStorage)
    // so toggling stays animated; we just mirror the value into storage on change.
    @AppStorage("hijriCalendarDisplayMode") private var savedModeRaw = DisplayMode.events.rawValue
    @State private var mode: DisplayMode

    init() {
        let raw = UserDefaults.standard.string(forKey: "hijriCalendarDisplayMode") ?? DisplayMode.events.rawValue
        _mode = State(initialValue: DisplayMode(rawValue: raw) ?? .events)
    }
    @State private var nearestEventId = ""
    @State private var hijriYear = 1445
    @State private var hijriMonth = 1
    @State private var didAutoScrollToNearest = false
    @State private var eventRows: [HijriEventRowModel] = []
    @State private var nearestEventRow: HijriEventRowModel?

    // Hijri year currently shown in the events list. `resolvedCurrentYear` is the "today" year the
    // list opens on (rolled to next year when every event for the real year has already passed);
    // `displayedYear` is what the stepper points at and can be moved freely within the bounds below.
    @State private var displayedYear = 1445
    @State private var resolvedCurrentYear = 1445
    @State private var didInitializeYear = false

    private static let minHijriYear = 1300
    private static let maxHijriYear = 1600

    private static let monthSymbols = [
        "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
        "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"
    ]

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()

    var body: some View {
        applyToolbar(to:
            Group {
                if mode == .calendar {
                    HijriMonthCalendarView()
                } else {
                    eventsList
                }
            }
            .navigationTitle("Hijri Calendar")
            .onChange(of: mode) { newValue in
                savedModeRaw = newValue.rawValue
            }
        )
        .navigationViewStyle(.stack)
    }

    private var calendarModeButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = (mode == .calendar) ? .events : .calendar
            }
        } label: {
            Image(systemName: mode == .calendar ? "list.bullet" : "calendar")
        }
        .accessibilityLabel(mode == .calendar ? "Show Islamic dates list" : "Show Hijri calendar")
    }

    private var hijriInfoButton: some View {
        NavigationLink {
            HijriCalendarView()
        } label: {
            Image(systemName: "info.circle")
        }
        .accessibilityLabel("Learn about the Hijri Calendar")
    }

    @ViewBuilder
    private func applyToolbar(to base: some View) -> some View {
        base.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                hijriInfoButton
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                calendarModeButton
            }
        }
    }

    private static let ummAlQuraEN: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "en")
        return calendar
    }()

    /// Which Hijri month it is right now, so the list can mark it. Reads the same Umm al-Qura calendar the rest of
    /// the screen does, and honours the user's Hijri offset.
    private var currentHijriMonthNumber: Int {
        let calendar = Self.ummAlQuraEN
        let adjusted = calendar.date(byAdding: .day, value: settings.hijriOffset, to: Date()) ?? Date()
        return calendar.component(.month, from: adjusted)
    }

    private var eventsList: some View {
        // Once per render, not per row: `currentHijriMonthNumber` was re-deriving the hijri month inside
        // each of the 12 month rows, and `nextEventID` re-filtered every event row from within every event
        // row (O(n²)). Same values either way - just computed once.
        let currentMonthNumber = currentHijriMonthNumber
        let todayStart = Calendar.current.startOfDay(for: Date())
        let nextID = eventRows
            .filter { $0.date >= todayStart }
            .min(by: { $0.date < $1.date })?
            .id

        return ScrollViewReader { proxy in
            List {
                Group {
                    Section(header: Text("WHAT IS HIJRI?")) {
                        Text("The Hijri calendar is the Islamic lunar calendar. It tracks months by moon cycles, so dates shift through the solar year and are primarily used for Islamic worship and sacred days.")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Text("Islamic events are calculated using the Umm al-Qura Hijri method selected in app settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                mode = .calendar
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                Text("Open Hijri Calendar")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                        }

                        NavigationLink {
                            HijriCalendarView()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "book.pages")
                                Text("Learn About the Hijri Calendar")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                        }

                        NavigationLink {
                            DateView()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                Text("Open Hijri Date Converter")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                        }
                    }

                    Section(header: Text("THE TWELVE ISLAMIC AND HIJRI MONTHS")) {
                        ForEach(hijriMonths) { month in
                            HijriMonthRow(month: month, isCurrent: month.number == currentMonthNumber)
                                .equatable()
                        }
                    }

                    Section(header: Text("IMPORTANT ISLAMIC DATES")) {
                        yearStepperRow
                            .listRowSeparator(.hidden)

                        ForEach(eventRows, id: \.id) { row in
                            HijriEventRow(
                                row: row,
                                isPast: row.date < todayStart,
                                isNext: row.id == nextID
                            )
                            .id(row.id)
                        }

                        yearStepperRow
                            .listRowSeparator(.hidden)
                    }
                }
                .themedListRowBackground()
            }
            .onAppear {
                updateInformation()
                guard !didAutoScrollToNearest else { return }
                nearestEventId = nearestEventRow?.id ?? ""
                didAutoScrollToNearest = true

                if !nearestEventId.isEmpty {
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(nearestEventId, anchor: .top)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                dateOverlayHeader
            }
            .applyConditionalListStyle()
        }
    }

    private func buildEventRows(forHijriYear year: Int) -> [HijriEventRowModel] {
        settings.specialEvents.map { event in
            var components = event.1
            components.year = year
            let date = settings.hijriCalendar.date(from: components) ?? Date()
            let monthName = Self.monthSymbols[(components.month ?? 1) - 1]

            return HijriEventRowModel(
                id: event.0,
                title: event.0,
                subtitle: event.2,
                description: event.3,
                hijriDateText: "\(components.day ?? 1) \(monthName), \(String(year)) AH",
                gregorianDateText: Self.formatter.string(from: date),
                date: date
            )
        }
    }

    /// The Islamic year runs Muharram → Dhul Hijjah. Once every event for `currentYear` has already
    /// passed (e.g. late Dhul Hijjah), the list should open on the next Hijri year so it leads with
    /// the upcoming Islamic New Year instead of being entirely grayed out.
    private func resolvedDisplayYear(forCurrentYear currentYear: Int) -> Int {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let allPast = settings.specialEvents.allSatisfy { event in
            var components = event.1
            components.year = currentYear
            guard let date = settings.hijriCalendar.date(from: components) else { return true }
            return date < todayStart
        }
        return currentYear + (allPast ? 1 : 0)
    }

    private func reloadEventRows() {
        eventRows = buildEventRows(forHijriYear: displayedYear)
        nearestEventRow = nearestEventRow(in: eventRows)
    }

    private func changeYear(by delta: Int) {
        let target = displayedYear + delta
        guard (Self.minHijriYear...Self.maxHijriYear).contains(target) else { return }
        displayedYear = target
        reloadEventRows()
    }

    private func goToCurrentYear() {
        guard displayedYear != resolvedCurrentYear else { return }
        displayedYear = resolvedCurrentYear
        reloadEventRows()
    }

    /// Approximate Gregorian span the displayed Hijri year covers, derived from the event dates.
    private var gregorianSpanText: String? {
        let dates = eventRows.map(\.date)
        guard let first = dates.min(), let last = dates.max() else { return nil }
        let gregorian = Calendar(identifier: .gregorian)
        let startYear = gregorian.component(.year, from: first)
        let endYear = gregorian.component(.year, from: last)
        return startYear == endYear ? "≈ \(startYear) CE" : "≈ \(startYear)–\(endYear) CE"
    }

    @ViewBuilder
    private var yearStepperRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                yearArrow("chevron.left", enabled: displayedYear > Self.minHijriYear) {
                    changeYear(by: -1)
                }

                VStack(spacing: 2) {
                    Text("\(String(displayedYear)) AH")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    if let gregorianSpanText {
                        Text(gregorianSpanText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                yearArrow("chevron.right", enabled: displayedYear < Self.maxHijriYear) {
                    changeYear(by: 1)
                }
            }

            if displayedYear != resolvedCurrentYear {
                Button {
                    settings.hapticFeedback()
                    withAnimation { goToCurrentYear() }
                } label: {
                    Label("Go to This Year", systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(settings.accentColor.color.opacity(0.12))
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func yearArrow(_ systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            settings.hapticFeedback()
            withAnimation { action() }
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundColor(enabled ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                .frame(width: 44, height: 44)
                .background((enabled ? settings.accentColor.color : Color(UIColor.tertiaryLabel)).opacity(0.12))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func nearestEventRow(in rows: [HijriEventRowModel]) -> HijriEventRowModel? {
        let now = Date()
        return rows.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(now)) < abs(rhs.date.timeIntervalSince(now))
        }
    }

    @ViewBuilder
    private var dateOverlayHeader: some View {
        if let hijriDate = settings.hijriDate {
            VStack(spacing: 2) {
                Text(hijriDate.english)
                    .foregroundColor(settings.accentColor.color)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(hijriDate.arabic)
                    .foregroundColor(settings.accentColor.color)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .conditionalGlassEffect()
            .padding(.horizontal, 22)
            .padding(.top, 2)
        }
    }

    private func updateInformation() {
        let currentDate = settings.effectiveHijriReferenceDate()
        let components = settings.hijriCalendar.dateComponents([.year, .month], from: currentDate)
        hijriYear = components.year ?? 1445
        hijriMonth = components.month ?? 1
        resolvedCurrentYear = resolvedDisplayYear(forCurrentYear: hijriYear)
        if !didInitializeYear {
            displayedYear = resolvedCurrentYear
            didInitializeYear = true
        }
        reloadEventRows()
        settings.updateDates()
    }
}

private struct HijriEventRowModel {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let hijriDateText: String
    let gregorianDateText: String
    let date: Date
}

/// An Islamic date as a card rather than a wall of stacked text: the Hijri day in a badge on the left (the
/// thing you actually scan for), the event and its meaning in the middle, and how far away it is on the right.
/// Past events grey out; the next one coming up is called out, since that's the only row anyone is looking for.
private struct HijriEventRow: View {
    @ObservedObject private var settings = Settings.shared

    let row: HijriEventRowModel
    let isPast: Bool
    /// True for the soonest upcoming event - exactly one row in the list.
    var isNext: Bool = false

    /// "in 12 days" / "today" / "in 3 months". Nil once the event has passed.
    private var countdownText: String? {
        guard !isPast else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()),
                                                   to: Calendar.current.startOfDay(for: row.date)).day ?? 0
        switch days {
        case ..<0:  return nil
        case 0:     return "Today"
        case 1:     return "Tomorrow"
        case 2...30: return "in \(days) days"
        default:
            let months = max(days / 30, 1)
            return months == 1 ? "in 1 month" : "in \(months) months"
        }
    }

    /// The Hijri day and month, split out of "10 Muharram, 1448 AH" so the badge can stack the number over the
    /// month name. The year is dropped - the whole list is one year, and the section header already says which.
    private var hijriParts: (day: String, month: String) {
        let parts = row.hijriDateText.split(separator: " ", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return (row.hijriDateText, "") }
        let month = parts[1].split(separator: ",").first.map(String.init) ?? parts[1]
        return (parts[0], month.trimmingCharacters(in: .whitespaces))
    }

    private var accent: Color { settings.accentColor.color }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            dateBadge

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(row.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isPast ? .primary.opacity(0.6) : .primary)

                    if isNext, let countdownText {
                        Text(countdownText.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accent.opacity(0.18)))
                    }
                }

                Text(row.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isPast ? accent.opacity(0.5) : accent)

                Text(row.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(row.gregorianDateText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if !isNext, let countdownText {
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Text(countdownText)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .opacity(isPast ? 0.5 : 1)
        .contextMenu {
            Text("Event Actions")
                .foregroundStyle(.secondary)

            copyButton("Copy Event Name", value: row.title)
            copyButton("Copy Event Subtitle", value: row.subtitle)
            copyButton("Copy Event Description", value: row.description)
            copyButton("Copy Hijri Date", value: row.hijriDateText)
            copyButton("Copy Gregorian Date", value: row.gregorianDateText)
        }
    }

    /// The Hijri day, large, over its month - a calendar tile, so the eye can run down the column.
    private var dateBadge: some View {
        VStack(spacing: 0) {
            Text(hijriParts.day)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(isNext ? Color.white : accent)

            Text(hijriParts.month)
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(isNext ? Color.white.opacity(0.9) : Color.secondary)
                .padding(.horizontal, 2)
        }
        .frame(width: 52, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isNext ? accent : accent.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isNext ? Color.clear : accent.opacity(0.2), lineWidth: 1)
        )
    }

    private func copyButton(_ title: String, value: String) -> some View {
        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = value
        } label: {
            Label(title, systemImage: "doc.on.doc")
        }
    }
}

// MARK: - Hijri Month Calendar (grid)

struct HijriMonthCalendarView: View {
    @ObservedObject private var settings = Settings.shared

    @State private var displayedYear = 1445
    @State private var displayedMonth = 1
    @State private var selectedDay: Int?
    @State private var didInitialize = false

    private static let minHijriYear = 1300
    private static let maxHijriYear = 1600

    private static let monthSymbols = [
        "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
        "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"
    ]

    private static let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private static let gregFullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f
    }()

    private static let gregMonthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "MMM yyyy"
        return f
    }()

    private var hijriCalendar: Calendar { settings.hijriCalendar }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                yearHeader
                monthHeader
                weekdayHeader
                daysGrid
                selectedDayCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .onAppear {
            settings.updateDates()
            guard !didInitialize else { return }
            didInitialize = true
            let today = todayHijriComponents()
            displayedYear = today.year ?? displayedYear
            displayedMonth = today.month ?? displayedMonth
        }
        // The events list beside this mode washes itself through `applyConditionalListStyle`; the
        // calendar grid is a plain ScrollView and needs the same light explicitly.
        .accentWashedBackground()
    }

    // MARK: Header

    /// Year stepper shown above the month stepper for quick year jumps.
    private var yearHeader: some View {
        HStack(spacing: 12) {
            yearArrow(systemName: "chevron.left", enabled: displayedYear > Self.minHijriYear) {
                changeYear(by: -1)
            }

            Text("\(String(displayedYear)) AH")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            yearArrow(systemName: "chevron.right", enabled: displayedYear < Self.maxHijriYear) {
                changeYear(by: 1)
            }
        }
    }

    private var monthHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                monthArrow(systemName: "chevron.left") { changeMonth(by: -1) }

                VStack(spacing: 3) {
                    Text(Self.monthSymbols[displayedMonth - 1])
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    if let gregorianRange = gregorianRangeText {
                        Text(gregorianRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                monthArrow(systemName: "chevron.right") { changeMonth(by: 1) }
            }

            if !isViewingTodayMonth {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        goToToday()
                    }
                } label: {
                    Label("Go to Today", systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(settings.accentColor.color.opacity(0.12))
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                }
            }
        }
    }

    private var isViewingTodayMonth: Bool {
        let t = todayHijriComponents()
        return t.year == displayedYear && t.month == displayedMonth
    }

    private func yearArrow(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            settings.hapticFeedback()
            withAnimation {
                action()
            }
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundColor(enabled ? settings.accentColor.color : Color(UIColor.tertiaryLabel))
                .frame(width: 44, height: 44)
                .background((enabled ? settings.accentColor.color : Color(UIColor.tertiaryLabel)).opacity(0.12))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .disabled(!enabled)
    }

    private func monthArrow(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                action()
            }
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
                .frame(width: 44, height: 44)
                .background(settings.accentColor.color.opacity(0.12))
                .clipShape(Circle())
                .contentShape(Circle())
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 6) {
            ForEach(Self.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Grid

    private var daysGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, day in
                if let day = day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 46)
                }
            }
        }
    }

    private func dayCell(_ day: Int) -> some View {
        let today = isToday(day)
        let selected = selectedDay == day
        let hasEvent = event(forDay: day) != nil

        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDay = selected ? nil : day
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.subheadline.weight(today ? .bold : .medium))
                    .foregroundColor(today ? .white : .primary)

                if let g = gregorianDay(forDay: day) {
                    Text("\(g)")
                        .font(.system(size: 9))
                        .foregroundColor(today ? .white.opacity(0.85) : .secondary)
                }

                Circle()
                    .fill(hasEvent ? (today ? Color.white : settings.accentColor.color) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(today ? settings.accentColor.color : (selected ? settings.accentColor.color.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected && !today ? settings.accentColor.color : Color.clear, lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Selected day detail

    @ViewBuilder
    private var selectedDayCard: some View {
        let day = selectedDay ?? todayDayIfVisible
        if let day = day, let gregorian = gregorianDate(forDay: day) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(day) \(Self.monthSymbols[displayedMonth - 1]) \(String(displayedYear)) AH")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    if isToday(day) {
                        Text("Today")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(settings.accentColor.color)
                            .clipShape(Capsule())
                    }
                }

                Text(Self.gregFullFormatter.string(from: gregorian))
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let event = event(forDay: day) {
                    Divider()
                    Text(event.0)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(event.1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: Data helpers

    /// Cells for the displayed month: leading `nil`s for the first weekday offset, then day numbers.
    private var monthCells: [Int?] {
        guard let first = hijriCalendar.date(from: DateComponents(year: displayedYear, month: displayedMonth, day: 1)),
              let range = hijriCalendar.range(of: .day, in: .month, for: first) else { return [] }
        let leading = hijriCalendar.component(.weekday, from: first) - 1
        var cells: [Int?] = Array(repeating: nil, count: leading)
        cells.append(contentsOf: range.map { Optional($0) })
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    /// Hijri components for "today", applying the same Maghrib switch and manual offset the rest of the app uses.
    private func todayHijriComponents() -> DateComponents {
        let effective = settings.effectiveHijriReferenceDate()
        let base = hijriCalendar.date(byAdding: .day, value: settings.hijriOffset, to: effective) ?? effective
        return hijriCalendar.dateComponents([.year, .month, .day], from: base)
    }

    private func isToday(_ day: Int) -> Bool {
        let t = todayHijriComponents()
        return t.year == displayedYear && t.month == displayedMonth && t.day == day
    }

    private var todayDayIfVisible: Int? {
        let t = todayHijriComponents()
        guard t.year == displayedYear, t.month == displayedMonth else { return nil }
        return t.day
    }

    /// Gregorian date for a Hijri day in the displayed month, reversing the app's manual offset.
    private func gregorianDate(forDay day: Int) -> Date? {
        guard let d = hijriCalendar.date(from: DateComponents(year: displayedYear, month: displayedMonth, day: day)) else { return nil }
        return hijriCalendar.date(byAdding: .day, value: -settings.hijriOffset, to: d)
    }

    private func gregorianDay(forDay day: Int) -> Int? {
        guard let g = gregorianDate(forDay: day) else { return nil }
        return Calendar(identifier: .gregorian).component(.day, from: g)
    }

    /// Title/subtitle of an important Islamic event on the given Hijri day, if any.
    /// Matches on month + day so these recurring annual events appear in every displayed year.
    private func event(forDay day: Int) -> (String, String)? {
        for e in settings.specialEvents {
            let c = e.1
            if c.month == displayedMonth, c.day == day {
                return (e.0, e.2)
            }
        }
        return nil
    }

    private var gregorianRangeText: String? {
        guard let firstDay = gregorianDate(forDay: 1),
              let first = hijriCalendar.date(from: DateComponents(year: displayedYear, month: displayedMonth, day: 1)),
              let range = hijriCalendar.range(of: .day, in: .month, for: first),
              let lastDay = gregorianDate(forDay: range.count) else { return nil }
        let start = Self.gregMonthYearFormatter.string(from: firstDay)
        let end = Self.gregMonthYearFormatter.string(from: lastDay)
        return start == end ? start : "\(start) – \(end)"
    }

    // MARK: Actions

    private func changeMonth(by delta: Int) {
        var month = displayedMonth + delta
        var year = displayedYear
        if month < 1 { month = 12; year -= 1 }
        if month > 12 { month = 1; year += 1 }
        guard (Self.minHijriYear...Self.maxHijriYear).contains(year) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = month
            displayedYear = year
            selectedDay = nil
        }
    }

    private func changeYear(by delta: Int) {
        let year = displayedYear + delta
        guard (Self.minHijriYear...Self.maxHijriYear).contains(year) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedYear = year
            selectedDay = nil
        }
    }

    private func goToToday() {
        let today = todayHijriComponents()
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedYear = today.year ?? displayedYear
            displayedMonth = today.month ?? displayedMonth
            selectedDay = today.day
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        CalendarView()
    }
}

#Preview("Hijri Month Grid") {
    AlIslamPreviewContainer(embedInNavigation: true) {
        HijriMonthCalendarView()
    }
}

/// One month of the Hijri year: its number, its name in English and Arabic, whether it is one of the four sacred
/// months, and what it is known for. The month you are currently in is tinted so the list orients you at a glance.
struct HijriMonthRow: View, Equatable {
    @ObservedObject private var settings = Settings.shared

    let month: HijriMonth
    let isCurrent: Bool
    // Appearance snapshotted as stored inputs so `==` compares everything the row draws with; the parent
    // observes Settings and re-inits rows with fresh values whenever these change.
    var accentColor: AccentColor = Settings.shared.accentColor
    var usesCustomArabicFace: Bool = Settings.shared.islamUsesCustomArabicFace
    var fontArabic: String = Settings.shared.nonQuranArabicFontName

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.month.number == rhs.month.number &&
        lhs.isCurrent == rhs.isCurrent &&
        lhs.accentColor == rhs.accentColor &&
        lhs.usesCustomArabicFace == rhs.usesCustomArabicFace &&
        lhs.fontArabic == rhs.fontArabic
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(month.number)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundColor(isCurrent ? .white : accentColor.color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isCurrent ? accentColor.color : accentColor.color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(month.english)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    if month.isSacred {
                        Text("SACRED")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(accentColor.color)
                    }

                    Spacer(minLength: 4)

                    // Hijri month names in the calendar always use the basic face - dates and their
                    // labels stay in the system font; the Quranic faces are for scripture.
                    Text(month.arabic)
                        .font(.subheadline)
                        .arabicFontDesign(custom: false)
                        .foregroundColor(accentColor.color)
                }

                Text(month.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}
#endif
