import SwiftUI

/// The prayer-times section. It reads as one block of color, so every tint in here is the accent's *second*
/// color (`accent2`) - the date/location/sky section above it stays on the first. For a one-color accent the
/// two are the same color and this looks exactly as it always did.
struct PrayerList: View {
    @ObservedObject private var settings = Settings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared
    @Environment(\.scenePhase) private var scenePhase
    // The HIGHLIGHT slice of the scrubber, not the scrubber itself: `ScrubHighlight` publishes only when
    // the prayer under the thumb changes (a handful of times per drag). Observing `DayScrubber` here made
    // every touch-move of the sun rebuild this whole section - list, sorts and all - ~60×/second.
    @ObservedObject private var scrubHighlight = ScrubHighlight.shared
    @Environment(\.appearance) private var appearance
    /// Light or dark as resolved for this screen (Sepia and pale custom backgrounds are light), for
    /// `tileTextAccent`.
    @Environment(\.colorScheme) private var colorScheme
    /// At the accessibility text sizes the footer's side-by-side controls stack instead of truncating
    /// ("Optiona...", and a "Showing prayers for" squeezed to one letter per line).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // The calendar day this view last considered "today". Used to detect a rollover that happened while the
    // app was suspended so a stale `selectedDate` doesn't spuriously trigger the TODAY comparison on reopen.
    @State private var lastActiveDay = Calendar.current.startOfDay(for: Date())

    @State private var expandedPrayerKey: String?
    /// Presents Adhan settings landed on the Traveling Mode screen - the footer's exit from Qasr mode.
    @State private var showTravelingModeSettings = false
    @State private var animatingBellPrayerName: String?
    @State private var bellAnimationActive = false
    @State private var selectedDate = Date()
    // Off by default: the TODAY comparison doubles the section's height, so it is opt-in per viewing
    // via the footer button rather than something every date change re-imposes.
    @State private var compareToday = false
    @State private var showOptionalPrayerToggles = false
    @State private var showRakaahGuide = false

    // New storage key (V2) so every existing user is reset to the new Tiles default, regardless of what
    // they had saved under the old "prayerDisplayMode" key.
    @AppStorage("prayerDisplayModeV2") private var prayerDisplayModeRawValue: String = PrayerDisplayMode.tiles.rawValue

    enum PrayerDisplayMode: String, CaseIterable, Identifiable {
        case tiles = "Prayer Tiles"
        case grid = "Prayer Grid"
        case list = "Prayer List"
        case split = "Prayer Split"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .tiles: return "TILES"
            case .grid: return "GRID"
            case .list: return "LIST"
            case .split: return "SPLIT"
            }
        }
    }

    private var prayerDisplayMode: PrayerDisplayMode {
        #if os(watchOS)
        // The watch only has room for the compact tile grid, and its display-mode picker is hidden, so
        // always render tiles regardless of the stored (iPhone-set) preference.
        return .tiles
        #else
        return PrayerDisplayMode(rawValue: prayerDisplayModeRawValue) ?? .tiles
        #endif
    }

    private static let selectedDateHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private func expansionKey(for prayer: Prayer) -> String {
        prayer.stableDisplayID
    }

    private func listDisplayName(for prayer: Prayer) -> String {
        prayer.displayName
    }

    /// The tracker's answer for a prayer on the day the list is showing, for the dot beside its name
    /// (Abu, 2026-09-25). Nil for anything the tracker does not record (Shurooq, the optional
    /// prayers), and on the watch, whose tiles have no room for it.
    private func trackerMark(for prayer: Prayer) -> PrayerMark? {
        #if os(iOS)
        guard Settings.trackablePrayerNames.contains(prayer.nameTransliteration) else { return nil }
        return settings.prayerMark(for: prayer.nameTransliteration, on: prayer.time)
        #else
        return nil
        #endif
    }

    /// Whether this platform's rows and tiles draw the notification bell.
    private static var drawsBells: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    /// The VoiceOver element for one prayer row or tile (see `PrayerAccessibility`). `name` is what the
    /// layout prints (the tiles use the short name, the list the full one).
    private func prayerAccessibility(for prayer: Prayer, name: String, isCurrent: Bool,
                                     mark: PrayerMark?, showsBell: Bool) -> PrayerAccessibility {
        let bell: Settings.PrayerNotificationMode? = showsBell ? settings.notificationMode(for: prayer) : nil
        let isExpanded = expandedPrayerKey == expansionKey(for: prayer)
        var states: [String] = []
        if isCurrent { states.append("current prayer") }
        if let mark { states.append(Self.spokenMark(mark)) }
        if let bell { states.append(bell.spokenState) }
        if isExpanded { states.append("expanded") }
        return PrayerAccessibility(
            label: "\(name), \(settings.formatDate(prayer.time))",
            value: states.joined(separator: ", "),
            isExpanded: isExpanded,
            bellMode: bell,
            toggle: { togglePrayerExpansion(for: prayer) },
            setBell: { mode in
                settings.hapticFeedback()
                settings.setNotificationMode(mode, for: prayer)
            }
        )
    }

    /// The tracker's mark in words (the dot beside the name is colour only).
    private static func spokenMark(_ mark: PrayerMark) -> String {
        switch mark {
        case .onTime: return "prayed on time"
        case .late: return "prayed late"
        case .missed: return "missed"
        }
    }

    private func togglePrayerExpansion(for prayer: Prayer, animated: Bool = true) {
        let prayerKey = expansionKey(for: prayer)
        settings.hapticFeedback()
        let update = {
            expandedPrayerKey = expandedPrayerKey == prayerKey ? nil : prayerKey
        }
        if animated {
            withAnimation {
                update()
            }
        } else {
            update()
        }
    }

    private func mergedWithOptional(_ base: [Prayer], for date: Date) -> [Prayer] {
        settings.prayersIncludingOptional(base, for: date)
    }

    /// "View Full Prayers" while traveling. Settings-backed (not view `@State`) so the COUNTDOWN and the
    /// sky card's current/next columns follow the same choice - `prayerBoundaryTimeline` reads it. Only
    /// meaningful while traveling; the guards below reset it whenever traveling mode flips.
    private var fullPrayers: Bool { settings.travelingMode && settings.travelingShowFullPrayers }

    /// True when the user has picked a day other than today. Derived from `selectedDate` so the
    /// comparison UI stays in sync without any imperative state to keep updated.
    private var isShowingDifferentDay: Bool {
        !Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }

    /// Prayer times for an arbitrary day, computed on demand. Today reuses the already-fetched
    /// `live.prayers`; any other day is generated directly (the generator is cached and fast).
    /// Computing this purely from `date` - instead of relying on `onChange` to populate published
    /// state - is what makes selecting a different day reliably refresh every display mode.
    private func prayers(for date: Date) -> [Prayer] {
        if Calendar.current.isDate(date, inSameDayAs: Date()), let prayers = live.prayers {
            let base = fullPrayers ? prayers.fullPrayers : prayers.prayers
            return mergedWithOptional(base, for: prayers.day)
        }

        let base = settings.getPrayerTimes(for: date, fullPrayers: fullPrayers) ?? []
        return mergedWithOptional(base, for: date)
    }

    private var displayedPrayers: [Prayer] {
        prayers(for: selectedDate)
    }

    private var todayPrayers: [Prayer] {
        prayers(for: Date())
    }

    var body: some View {
        let _ = RenderCounter.hit("PrayerList")
        let _ = ChangePrinter.hit(Self.self)
        if live.prayers != nil {
            prayerListSection
                #if DEBUG
                // `-expandPrayer <name>`: that prayer opened on today's list, for screenshots of the
                // expanded detail (there is no tap tooling for the simulator).
                .onAppear {
                    let args = ProcessInfo.processInfo.arguments
                    guard let i = args.firstIndex(of: "-expandPrayer"), args.indices.contains(i + 1),
                          let prayer = displayedPrayers.first(where: { $0.nameTransliteration == args[i + 1] })
                    else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        expandedPrayerKey = expansionKey(for: prayer)
                    }
                }
                #endif
        }
    }

    private var prayerListSection: some View {
        Section(header: sectionHeader) {
            prayerContentStack
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { resetToTodayIfDayChanged() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            resetToTodayIfDayChanged()
        }
    }

    /// Snaps `selectedDate` back to today when the calendar day has actually rolled over since we last saw
    /// it - e.g. the app was suspended overnight and reopened. Without this, the stale `selectedDate` (still
    /// on the previous day) makes `isShowingDifferentDay` true and the "TODAY vs that day" comparison block
    /// renders on reopen. Guarded on an actual day change, so a day the user deliberately picked earlier the
    /// same session (background → foreground within one day) is left untouched.
    private func resetToTodayIfDayChanged() {
        let currentDay = Calendar.current.startOfDay(for: Date())
        guard currentDay != lastActiveDay else { return }
        lastActiveDay = currentDay
        if isShowingDifferentDay {
            withAnimation {
                selectedDate = Date()
                compareToday = false
            }
        }
        // The stored `prayers` object still carries YESTERDAY's date (and times). `currentPrayer` heals
        // itself via the countdown's boundary timeline, but the displayed list served `live.prayers`
        // as "today" until the app was next backgrounded and reopened - an app left foregrounded past
        // midnight showed yesterday's times all night. The fetch's own `staleDate` check makes this a
        // no-op whenever the stored day is somehow already correct.
        settings.fetchPrayerTimes()
    }

    @ViewBuilder
    private var prayerContentStack: some View {
        if isShowingDifferentDay && compareToday {
            prayerGroupHeader("TODAY")
            prayerModeContent(prayers: todayPrayers, isComparisonBaseline: true)
                .opacity(0.45)

            prayerGroupHeader(selectedDateHeaderText)
        }

        // The selected day only highlights a "current" prayer when it is actually today; on any other
        // day the concept doesn't apply, so render its prayers in the neutral primary color.
        prayerModeContent(prayers: displayedPrayers, highlightsCurrent: !isShowingDifferentDay)
        travelModeFooter
        optionalPrayersFooter
        dateSelectionFooter
    }

    // MARK: - Rakaah guide

    /// One row of the rakaah guide: a mandatory prayer, its fard count, and its sunnah rakahs
    /// split by emphasis - primary (mu'akkadah) vs secondary (ghayr mu'akkadah).
    private struct RakaahGuideRow: Identifiable {
        let name: String
        let arabic: String
        let fard: String
        let primary: [String]
        let secondary: [String]

        var id: String { name }
    }

    private static let rakaahGuideRows: [RakaahGuideRow] = [
        .init(name: "Fajr",    arabic: "الفَجر",   fard: "2", primary: ["2 before"],           secondary: []),
        .init(name: "Dhuhr",   arabic: "الظُهر",   fard: "4", primary: ["4 before", "2 after"], secondary: []),
        .init(name: "Jumuah",  arabic: "الجُمُعَة",  fard: "2", primary: ["2 after"],            secondary: []),
        .init(name: "Asr",     arabic: "العَصر",   fard: "4", primary: [],                     secondary: ["4 before"]),
        .init(name: "Maghrib", arabic: "المَغرِب",  fard: "3", primary: ["2 after"],            secondary: ["2 before"]),
        .init(name: "Isha",    arabic: "العِشَاء",  fard: "4", primary: ["2 after"],            secondary: ["2 before"]),
    ]

    /// The expandable rakaah guide content: every mandatory prayer with its fard count and both
    /// kinds of sunnah. Lives inside the optional-prayers footer, disclosed by the "Rakaah Guide"
    /// pill that shares a line with "Optional Times".
    @ViewBuilder
    private var rakaahGuideContent: some View {
        VStack(spacing: 0) {
            rakaahGuideHeaderRow

            ForEach(Self.rakaahGuideRows) { row in
                Divider()
                rakaahGuideRow(row)
            }
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Primary (Sunnah Mu'akkadah): prayed consistently by the Prophet ﷺ. Secondary (Ghayr Mu'akkadah): prayed at times; rewarded, with lesser emphasis.")
            Text("Jumuah replaces Dhuhr on Fridays; pray its 2 sunnah after as 4 (2 then 2) at the masjid, or 2 at home.")
            Text("While traveling, the sunnah prayers are left except the 2 before Fajr.")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rakaahGuideHeaderRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Prayer")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Fard")
                .frame(width: 34)

            Text("Primary")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Secondary")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption2.weight(.semibold))
        .foregroundColor(settings.accentColor.accent2)
        .padding(.vertical, 6)
    }

    private func rakaahGuideRow(_ row: RakaahGuideRow) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(row.name)
                    .font(.caption.weight(.semibold))

                Text(row.arabic)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.fard)
                .font(.caption.monospacedDigit())
                .frame(width: 34)

            rakaahGuideCell(row.primary)
            rakaahGuideCell(row.secondary)
        }
        .padding(.vertical, 6)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private func rakaahGuideCell(_ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if lines.isEmpty {
                Text("None")
                    .foregroundColor(.secondary.opacity(0.5))
            } else {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                }
            }
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Lets the optional/extra prayers (Duha, Islamic Midnight, Last Third) be shown or hidden right from
    /// the prayer page, so toggling them no longer means a trip into Settings. These bind to the same
    /// persisted settings used elsewhere - this is just a more discoverable entry point.
    @ViewBuilder
    private var optionalPrayersFooter: some View {
        #if os(iOS)
        // Everything lives in one VStack so it's a single list row - no internal separators to fight with.
        // The row's own bottom separator is hidden so the button reads as a clean standalone pill.
        VStack(spacing: 18) {
            // Hand-drawn dividers top and bottom (the real list separators are hidden) so both ends match.
            // The VStack spacing gives them breathing room from the button/content, while the negative
            // outer padding pulls them close to the neighboring rows above and below.
            Divider()

            // Both disclosures share one line - two half-width pills instead of two stacked full-width ones.
            footerButtonPair {
                footerActionButton("Optional Times", isExpanded: showOptionalPrayerToggles) {
                    showOptionalPrayerToggles.toggle()
                }

                footerActionButton("Rakaah Guide", isExpanded: showRakaahGuide) {
                    showRakaahGuide.toggle()
                }
            }

            if showOptionalPrayerToggles {
                VStack(spacing: 10) {
                    optionalPrayerToggle("Duhaa", isOn: $settings.showDuha)
                    optionalPrayerToggle("Islamic Midnight", isOn: $settings.showIslamicMidnight)
                    optionalPrayerToggle("Last Third of the Night", isOn: $settings.showLastThird)
                }

                Text("These extra prayer times appear in the app only, never in widgets.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showRakaahGuide {
                rakaahGuideContent
            }

            Divider()
        }
        .padding(.vertical, -12)
        .listRowSeparator(.hidden)
        #endif
    }

    private func optionalPrayerToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn.animation(.easeInOut)) {
            Text(label)
                .font(.subheadline)
        }
        .tint(settings.accentColor.accent2)
        .padding(.vertical, 4)
        .onChange(of: isOn.wrappedValue) { _ in settings.hapticFeedback() }
    }

    private var selectedDateHeaderText: String {
        Self.selectedDateHeaderFormatter.string(from: selectedDate).uppercased()
    }

    private func prayerGroupHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sectionHeader: some View {
        HStack {
            Text("PRAYER TIMES")

            #if os(iOS)
            // The combined list labels itself, so a reader who scrolled past the banner still knows why.
            if settings.travelingMode {
                QasrHeaderBadge()
            }

            Spacer()

            Picker("", selection: $prayerDisplayModeRawValue) {
                Section {
                    ForEach(PrayerDisplayMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                } header: {
                    Text("Prayer Display")
                }
            }
            .font(.caption2)
            .pickerStyle(MenuPickerStyle())
            .padding(.vertical, -12)
            .onChange(of: prayerDisplayModeRawValue) { _ in settings.hapticFeedback() }
            #endif
        }
    }

    @ViewBuilder
    private func prayerModeContent(prayers: [Prayer], isComparisonBaseline: Bool = false, highlightsCurrent: Bool = true) -> some View {
        switch prayerDisplayMode {
        case .list:
            listContent(prayers: prayers, isComparisonBaseline: isComparisonBaseline, highlightsCurrent: highlightsCurrent)
        case .grid:
            gridContent(prayers: prayers, isComparisonBaseline: isComparisonBaseline, highlightsCurrent: highlightsCurrent)
        case .split:
            splitContent(prayers: prayers, isComparisonBaseline: isComparisonBaseline, highlightsCurrent: highlightsCurrent)
        case .tiles:
            tilesContent(prayers: prayers, isComparisonBaseline: isComparisonBaseline, highlightsCurrent: highlightsCurrent)
        }
    }

    @ViewBuilder
    private func listContent(prayers: [Prayer], isComparisonBaseline: Bool = false, highlightsCurrent: Bool = true) -> some View {
        ForEach(prayers, id: \.stableDisplayID) { prayer in
            listRow(for: prayer, in: prayers, isComparisonBaseline: isComparisonBaseline, highlightsCurrent: highlightsCurrent)
        }
        .onChange(of: settings.travelingMode) { _ in
            withAnimation {
                settings.travelingShowFullPrayers = false
            }
        }
    }

    private func listRow(for prayer: Prayer, in prayers: [Prayer], isComparisonBaseline: Bool = false, highlightsCurrent: Bool = true) -> some View {
        let prayerKey = expansionKey(for: prayer)
        let isExpanded = expandedPrayerKey == prayerKey
        let isCurrent = highlightsCurrent && !isComparisonBaseline && isCurrentPrayer(prayer)
        let listIconColor = prayer.nameTransliteration == "Shurooq" ? Color.primary : settings.accentColor.accent2

        return Group {
            PrayerListRowCard(
                prayer: prayer,
                displayName: listDisplayName(for: prayer),
                isCurrent: isCurrent,
                iconColor: listIconColor,
                highlight: settings.accentColor.accent2.opacity(0.25),
                trackerMark: isComparisonBaseline ? nil : trackerMark(for: prayer),
                trailingContent: {
                    #if os(iOS)
                    prayerBell(for: prayer, rowColor: .primary)
                    #endif
                }
            )
            .modifier(prayerAccessibility(
                for: prayer,
                name: listDisplayName(for: prayer),
                isCurrent: isCurrent,
                mark: isComparisonBaseline ? nil : trackerMark(for: prayer),
                showsBell: Self.drawsBells
            ))

            if isExpanded {
                expandedPrayerDetailContent(for: prayer, in: prayers)
                    .contentShape(Rectangle())
            }
        }
        .onTapGesture {
            togglePrayerExpansion(for: prayer)
        }
    }

    @ViewBuilder
    private func gridContent(prayers: [Prayer], isComparisonBaseline: Bool = false, highlightsCurrent: Bool = true) -> some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: prayers.count == 4 ? 2 : 3
        )
        // The same color rules as the tiles (Abu, 2026-10-01: "make adhan grid and split look better
        // like from Tilawa"): once per grid, the highlighted prayer, its index and the legible accent.
        let currentName = currentPrayerName
        let currentIndex = prayers.firstIndex { $0.nameTransliteration == live.currentPrayer?.nameTransliteration }
        let accent = settings.accentColor.accent2
        let textAccent = tileTextAccent(accent)

        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(prayers.enumerated()), id: \.element.stableDisplayID) { index, prayer in
                let color: Color = isComparisonBaseline
                    ? .secondary
                    : (highlightsCurrent ? prayerColor(at: index, currentIndex: currentIndex, accent: textAccent) : .primary)
                let isCurrent = highlightsCurrent && !isComparisonBaseline
                    && (currentName?.contains(prayer.nameTransliteration) ?? false)

                PrayerGridTile(
                    prayer: prayer,
                    color: color,
                    isCurrent: isCurrent,
                    accent: accent,
                    trackerMark: isComparisonBaseline ? nil : trackerMark(for: prayer)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePrayerExpansion(for: prayer)
                }
                .modifier(prayerAccessibility(
                    for: prayer,
                    name: prayer.compactDisplayName,
                    isCurrent: isCurrent,
                    mark: isComparisonBaseline ? nil : trackerMark(for: prayer),
                    showsBell: false
                ))
            }
        }
        .padding(.horizontal, -6)
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        expandedPrayerDetail(for: prayers)
    }

    @ViewBuilder
    private func splitContent(prayers: [Prayer], isComparisonBaseline: Bool = false, highlightsCurrent: Bool = true) -> some View {
        let midpoint = Int(floor(Double(prayers.count) / 2.0))
        let indexed = Array(prayers.enumerated())
        let currentIndex = prayers.firstIndex { $0.nameTransliteration == live.currentPrayer?.nameTransliteration }
        let textAccent = tileTextAccent(settings.accentColor.accent2)
        // Traveling's combined names ("Maghrib/Isha") do not fit beside a time in half a row: every
        // row then stacks its time under its name, so the two columns stay even.
        let stacked = prayers.contains { $0.nameTransliteration.contains("/") }

        HStack(alignment: .top, spacing: 6) {
            splitColumn(Array(indexed.prefix(midpoint)), currentIndex: currentIndex, textAccent: textAccent,
                        stacked: stacked, isComparisonBaseline: isComparisonBaseline, highlightsCurrent: highlightsCurrent)

            // A neutral hairline, not the accent: the current row's fill is the only color.
            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 0.5)
                .padding(.vertical, 6)

            splitColumn(Array(indexed.suffix(prayers.count - midpoint)), currentIndex: currentIndex, textAccent: textAccent,
                        stacked: stacked, isComparisonBaseline: isComparisonBaseline, highlightsCurrent: highlightsCurrent)
        }
        .padding(.horizontal, -8)
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        expandedPrayerDetail(for: prayers)
    }

    /// One half of the Split layout. `column` keeps each prayer's index in the FULL list, so past /
    /// current / upcoming colors match the other layouts.
    private func splitColumn(_ column: [(offset: Int, element: Prayer)], currentIndex: Int?, textAccent: Color,
                             stacked: Bool, isComparisonBaseline: Bool, highlightsCurrent: Bool) -> some View {
        let currentName = currentPrayerName
        let accent = settings.accentColor.accent2

        return VStack(spacing: 2) {
            ForEach(column, id: \.element.stableDisplayID) { index, prayer in
                let color: Color = isComparisonBaseline
                    ? .secondary
                    : (highlightsCurrent ? prayerColor(at: index, currentIndex: currentIndex, accent: textAccent) : .primary)
                let isCurrent = highlightsCurrent && !isComparisonBaseline
                    && (currentName?.contains(prayer.nameTransliteration) ?? false)

                SplitPrayerRow(
                    prayer: prayer,
                    color: color,
                    isCurrent: isCurrent,
                    accent: accent,
                    stacked: stacked,
                    trackerMark: isComparisonBaseline ? nil : trackerMark(for: prayer)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePrayerExpansion(for: prayer)
                }
                .modifier(prayerAccessibility(
                    for: prayer,
                    name: prayer.compactDisplayName,
                    isCurrent: isCurrent,
                    mark: isComparisonBaseline ? nil : trackerMark(for: prayer),
                    showsBell: false
                ))
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func tilesContent(prayers: [Prayer], isComparisonBaseline: Bool = false, highlightsCurrent: Bool = true) -> some View {
        #if os(watchOS)
        // Tighter on the watch: the icon shares the name's line instead of taking one of its own, and the
        // padding comes down - that's what lets six prayers fit a screen at a readable size.
        let columnCount = 2
        let tileSpacing: CGFloat = 5
        let tileHorizontalPadding: CGFloat = 7
        let tileVerticalPadding: CGFloat = 5
        #else
        // Keyed on what is actually RENDERED: the combined Qasr set (4 rows) reads best two-up, but
        // "View Full Prayers" restores the six - which want the normal three columns, not two rows of
        // three stretched tiles with a hole (user rule: full prayers = grid of 3).
        let columnCount = (settings.travelingMode && !fullPrayers) ? 2 : 3
        let tileSpacing: CGFloat = 8
        let tileHorizontalPadding: CGFloat = 8
        let tileVerticalPadding: CGFloat = 8
        #endif
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: tileSpacing),
            count: columnCount
        )
        // Once per grid, not per tile: the highlighted prayer, its index in this list and the accent.
        let currentName = currentPrayerName
        let currentIndex = prayers.firstIndex { $0.nameTransliteration == live.currentPrayer?.nameTransliteration }
        let accent = settings.accentColor.accent2
        // The current tile's TEXT; its tint and glow keep the plain accent.
        let textAccent = tileTextAccent(accent)

        // Not wrapped in an iOS 26 `GlassEffectContainer`: tried, and it re-rendered the tiles flatter
        // and dropped the current tile's glow. The flat pre-26 fill below is the win that matters
        // (the A11-A13 devices that stutter never run iOS 26).
        LazyVGrid(columns: columns, spacing: tileSpacing) {
            ForEach(Array(prayers.enumerated()), id: \.element.stableDisplayID) { index, prayer in
                let color: Color = isComparisonBaseline
                    ? .secondary
                    : (highlightsCurrent ? prayerColor(at: index, currentIndex: currentIndex, accent: textAccent) : .primary)
                let isCurrent = highlightsCurrent && !isComparisonBaseline
                    && (currentName?.contains(prayer.nameTransliteration) ?? false)

                VStack(alignment: .leading, spacing: 2) {
                    #if os(watchOS)
                    HStack(spacing: 3) {
                        // The 40 mm face leaves a half-width tile about 46 pt for the name beside the
                        // icon, and "Shurooq" / "Maghrib" truncated there; the icon steps aside on that
                        // face so the name keeps its size (the time line still carries the tint).
                        if !WatchScreen.isNarrow {
                            Image(systemName: prayer.image)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(color)
                        }

                        // The name owns the line: a fixed-size icon plus layoutPriority keeps a long
                        // name ("Shurooq") from being the one tile that scales to a sliver while its
                        // neighbors render full size. 0.8 is a trim, not a shrink.
                        Text(prayer.compactDisplayName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(color)
                            .minimumScaleFactor(WatchScreen.isNarrow ? 0.7 : 0.8)
                            .layoutPriority(1)
                    }

                    Text(prayer.time, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(color)
                        .minimumScaleFactor(0.8)
                    #else
                    HStack(alignment: .top) {
                        Image(systemName: prayer.image)
                            .font(.subheadline)
                            .foregroundColor(color)

                        Spacer()

                        if !isComparisonBaseline {
                            prayerBell(for: prayer, rowColor: color)
                        }
                    }

                    HStack(spacing: 5) {
                        Text(prayer.compactDisplayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(color)

                        PrayerMarkDot(mark: isComparisonBaseline ? nil : trackerMark(for: prayer))
                    }

                    Text(prayer.time, style: .time)
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(color)
                    #endif
                }
                .padding(.horizontal, tileHorizontalPadding)
                .padding(.vertical, tileVerticalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Only the CURRENT prayer's tile is tinted. The rest are clear, so the one that matters reads
                // at a glance instead of competing with five other filled boxes.
                .conditionalGlassEffect(
                    clear: !isCurrent,
                    rectangle: true,
                    useColor: isCurrent ? 0.25 : nil,
                    customTint: isCurrent ? accent : nil,
                    flat: true
                )
                // The soft accent glow lifts the current prayer's tile off the board - the tint said
                // "different", the glow says "now".
                .softShadow(color: isCurrent ? accent.opacity(0.35) : .clear,
                            radius: isCurrent ? 8 : 0, x: 0, y: 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePrayerExpansion(for: prayer)
                }
                .modifier(prayerAccessibility(
                    for: prayer,
                    name: prayer.compactDisplayName,
                    isCurrent: isCurrent,
                    mark: isComparisonBaseline ? nil : trackerMark(for: prayer),
                    showsBell: Self.drawsBells && !isComparisonBaseline
                ))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        #if os(watchOS)
        // The tiles draw their own glass; the List's default row card behind them (plus its side
        // insets) squeezed the grid and read as one chopped slab. Clear it and give the tiles the
        // full row width.
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
        #endif
        .onChange(of: settings.travelingMode) { _ in
            withAnimation { settings.travelingShowFullPrayers = false }
        }

        expandedPrayerDetail(for: prayers)
    }

    @ViewBuilder
    private func expandedPrayerDetail(for prayers: [Prayer]) -> some View {
        if let prayer = prayers.first(where: { expansionKey(for: $0) == expandedPrayerKey }) {
            expandedPrayerDetailContent(for: prayer, in: prayers)
            .id(prayer.stableDisplayID)
            .contentShape(Rectangle())
        }
    }

    private func expandedPrayerDetailContent(for prayer: Prayer, in prayers: [Prayer]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                PrayerDetailBlock(
                    prayer: prayer,
                    timeWindowText: timeWindowText(for: prayer, in: prayers),
                    referenceText: prayerReferenceText(for: prayer)
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                #if os(iOS)
                if prayerDisplayMode != .list && prayerDisplayMode != .tiles {
                    prayerBell(for: prayer, rowColor: .primary)
                }
                #endif
            }

            // Mark it from where you opened it (Abu, 2026-09-25): the same three answers the
            // tracker's Day view gives, for this prayer on the day the list is showing.
            #if os(iOS)
            if Settings.trackablePrayerNames.contains(prayer.nameTransliteration) {
                PrayerMarkChooser(prayer: prayer)
            }
            #endif
        }
    }

    @ViewBuilder
    private var travelModeFooter: some View {
        if settings.travelingMode {
            VStack {
                #if os(iOS)
                travelingModeDescription

                footerButtonPair {
                    footerActionButton(fullPrayers ? "View Qasr Prayers" : "View Full Prayers") {
                        withAnimation { settings.travelingShowFullPrayers.toggle() }
                    }

                    // The footer explains Qasr but gave no way OUT of it: turning traveling mode off meant
                    // finding the setting by hand. This lands directly on the Traveling Mode screen.
                    footerActionButton("Travel Settings") {
                        showTravelingModeSettings = true
                    }
                }
                #endif

                #if os(watchOS)
                footerActionButton(fullPrayers ? "View Qasr Prayers" : "View Full Prayers") {
                    withAnimation { settings.travelingShowFullPrayers.toggle() }
                }

                travelingModeDescription
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $showTravelingModeSettings) {
                // A stack container, so the sheet opens straight onto Traveling Mode (see
                // `SheetNavigationContainer`).
                SheetNavigationContainer {
                    SettingsAdhanView(showNotifications: false, presentedAsSheet: true, openTravelingMode: true)
                }
                .smallMediumSheetPresentation()
            }
            #endif
        }
    }

    @ViewBuilder
    private var dateSelectionFooter: some View {
        #if os(iOS)
        VStack {
            // At the accessibility sizes the stepper alone is about a row wide, and the label beside it
            // was squeezed to one letter per line: it gets its own line above the stepper there.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Showing prayers for")
                        .fixedSize(horizontal: false, vertical: true)

                    dayStepper
                        .frame(maxWidth: .infinity)
                }
                .padding(4)
            } else {
                HStack(spacing: 8) {
                    Text("Showing prayers for")

                    Spacer(minLength: 4)

                    dayStepper
                }
                .padding(4)
            }

            if isShowingDifferentDay {
                footerButtonPair {
                    footerActionButton(compareToday ? "Hide Comparison" : "Compare Today") {
                        compareToday.toggle()
                    }

                    footerActionButton("Back to Today") {
                        selectedDate = Date()
                    }
                }
            }
        }
        .onChange(of: selectedDate) { newDate in
            settings.hapticFeedback()
            // Let the sky card's moon preview the picked night's phase (nil = back to the live moon).
            let isToday = Calendar.current.isDate(newDate, inSameDayAs: Date())
            SelectedDayPreview.shared.update(isToday ? nil : newDate)
        }
        #endif
    }

    private var travelingModeDescription: some View {
        #if os(watchOS)
        // The watch has no home city and never decides traveling mode for itself, so it names
        // neither: mentioning a city it does not measure from, and cannot change, only misleads.
        // Traveling mode is set on the phone (or by hand here on a standalone watch).
        let homeSentence = "Traveling mode is set in the iPhone app."
        #else
        // Names the HOME CITY the 48-mile rule measures from, and points at the exact control that
        // changes it - "customize in settings" alone left the reader hunting (user rule).
        let homeCity = settings.homeLocation?.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let homeSentence = (homeCity?.isEmpty == false)
            ? "Your home city is \(homeCity!). You can change it by tapping Travel Settings below."
            : "You can set your home city by tapping Travel Settings below."
        #endif
        return Text("Traveling mode is on. If you are traveling more than 48 mi from home, you can pray Qasr, where you shorten and combine prayers. \(homeSentence)")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    #if os(iOS)
    /// The back chevron, the date picker and the forward chevron.
    private var dayStepper: some View {
        HStack(spacing: 8) {
            dayStepButton(systemName: "chevron.backward", byDays: -1)

            DatePicker("Showing prayers for", selection: $selectedDate.animation(.easeInOut), displayedComponents: .date)
                .datePickerStyle(DefaultDatePickerStyle())
                .labelsHidden()

            dayStepButton(systemName: "chevron.forward", byDays: 1)
        }
    }

    /// One of the two chevrons flanking the date picker: steps the shown day backward or forward.
    private func dayStepButton(systemName: String, byDays days: Int) -> some View {
        Button {
            if let stepped = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
                withAnimation(.easeInOut) {
                    selectedDate = stepped
                }
            }
        } label: {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(settings.accentColor.accent2)
                .frame(width: 32, height: 32)
                .conditionalGlassEffect()
        }
        .buttonStyle(.plain)
        // The chevron's own name ("Back", "Forward") says nothing about days.
        .accessibilityLabel(days < 0 ? "Previous Day" : "Next Day")
    }
    #endif

    /// Pass `isExpanded` for buttons that disclose content below: they get a rotating chevron, so the
    /// title can stay short ("Rakaah Guide") instead of carrying a Show/Hide prefix.
    ///
    /// A real `Button` (plain style, so it looks exactly as the tap-gesture pill did): VoiceOver hears a
    /// button, and a disclosure one also says whether it is open.
    private func footerActionButton(_ title: String, isExpanded: Bool? = nil, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                action()
            }
        } label: {
            HStack(spacing: 5) {
                Text(title)

                if let isExpanded {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundColor(settings.accentColor.accent2)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
            .conditionalGlassEffect()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded.map { $0 ? "Expanded" : "Collapsed" } ?? "")
    }

    /// Two footer pills side by side, or stacked once the text is too large for half a row each.
    @ViewBuilder
    private func footerButtonPair<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 10) { content() }
        } else {
            HStack(spacing: 10) { content() }
        }
    }

    /// While the sun is being dragged along `SkyView`'s arc, the highlight follows the dragged moment rather
    /// than the live one, so scrubbing the day walks it down the rows.
    private var currentPrayerName: String? {
        (scrubHighlight.previewPrayer ?? live.currentPrayer)?.nameTransliteration
    }

    private func isCurrentPrayer(_ prayer: Prayer) -> Bool {
        currentPrayerName?.contains(prayer.nameTransliteration) ?? false
    }

    /// A prayer already past today: dimmed, but still text people read ("when was Fajr?"). The
    /// system's `.secondary` turns vibrant on the glass tiles and measured 3.1:1 (dark) and 2.9:1
    /// (light) there; a plain primary at 60% stays clearly dimmer than the prayers to come and reads
    /// at about 5:1 on either ground.
    private static let pastPrayerColor = Color.primary.opacity(0.6)

    /// The accent as the CURRENT tile's text. The tile is tinted with that same accent (25%), so even
    /// an accent that reads on a plain row can fall short on it: the plain light green measured 2.1:1
    /// there. The shade is moved only as far as 4.5:1 against the tint it actually sits on (the
    /// `AccentContrast` arithmetic the app's accent uses): deeper on a light ground, paler on a dark
    /// one. The default green in dark mode already reads (5.7:1) and is left as it is.
    private func tileTextAccent(_ accent: Color) -> Color {
        #if os(iOS)
        let dark = colorScheme == .dark
        let shade = AccentContrast.resolved(UIColor(accent), dark: dark)
        // What the glass tile shows under its tint: white on a light ground, the measured #3B3B3D dark.
        let base = dark ? AccentContrast.RGB(r: 59 / 255, g: 59 / 255, b: 61 / 255) : AccentContrast.RGB(r: 1, g: 1, b: 1)
        let tint = AccentContrast.blend(shade, over: base, opacity: 0.25)
        // 4.6, not 4.5: the glass renders its tint a shade darker than this model (190/222/202 against
        // 191/223/203 measured), which left an exact 4.5 target reading 4.44 on screen.
        let text = AccentContrast.legible(shade, against: tint, target: AccentContrast.textRatio + 0.1)
        return text == shade ? accent : Color(AccentContrast.uiColor(text))
        #else
        return accent
        #endif
    }

    /// Past prayers dimmed, the current one in the accent, the rest primary; `currentIndex` is looked
    /// up once per layout, not per cell. `accent` is already the text shade (`tileTextAccent`).
    private func prayerColor(at index: Int, currentIndex: Int?, accent: Color) -> Color {
        guard let currentIndex else { return Self.pastPrayerColor }
        if index < currentIndex { return Self.pastPrayerColor }
        if index == currentIndex { return accent }
        return .primary
    }

    /// "Until Asr at 4:52 PM (3h 38m)" - the span from THIS prayer's time to the next one in the displayed
    /// timeline, not from now. The last entry of the day rolls over to the next day's Fajr.
    private func timeWindowText(for prayer: Prayer, in prayers: [Prayer]) -> String? {
        let sorted = prayers.sorted { $0.time < $1.time }

        var next: Prayer?
        if let index = sorted.firstIndex(where: { $0.stableDisplayID == prayer.stableDisplayID }),
           index + 1 < sorted.count {
            next = sorted[index + 1]
        } else {
            // The last entry rolls to the NEXT Fajr after this time. For post-midnight optional times
            // (Last Third ~3 AM, a late Islamic Midnight) that is the Fajr of this very civil day, an
            // hour or two later - "+1 day" unconditionally fetched the day after's Fajr and reported a
            // ~25-hour window.
            let sameDayFajr = settings.getPrayerTimes(for: prayer.time)?.first { $0.nameTransliteration == "Fajr" }
            if let sameDayFajr, sameDayFajr.time > prayer.time {
                next = sameDayFajr
            } else if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: prayer.time) {
                next = settings.getPrayerTimes(for: tomorrow)?.first { $0.nameTransliteration == "Fajr" }
            }
        }

        guard let next, next.time > prayer.time else { return nil }

        let minutes = Int(next.time.timeIntervalSince(prayer.time) / 60)
        let duration: String
        switch (minutes / 60, minutes % 60) {
        case (0, let m):        duration = "\(m)m"
        case (let h, 0):        duration = "\(h)h"
        case (let h, let m):    duration = "\(h)h \(m)m"
        }

        return "Until \(next.displayName) at \(settings.formatDate(next.time)) (\(duration))"
    }

    private func prayerReferenceText(for prayer: Prayer) -> String? {
        if prayer.nameTransliteration == "Fajr" {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Fajr prayer is from the appearance of dawn until the sun begins to rise\" (Sahih Muslim 612)."
        }

        // The two combined (qasr) rows MUST be matched before the `contains("Dhuhr")` / `contains("Maghrib")`
        // checks below, which would otherwise swallow them and show the plain Dhuhr / Maghrib hadith - never
        // once naming Asr or Isha, even though those are exactly the prayers being joined into this row.
        if prayer.nameTransliteration == "Dhuhr/Asr" {
            return """
            While traveling, Dhuhr and Asr are joined and each is shortened to 2 rak'ah (qasr). Pray Dhuhr first, then Asr immediately after it, in this one time slot.

            Anas (may Allah be pleased with him) said: "When the Prophet (peace be upon him) set out on a journey before the sun passed its zenith, he would delay Dhuhr until the time of Asr, then he would stop and join them" (Sahih al-Bukhari 1112).

            "And when you travel throughout the land, there is no blame upon you for shortening the prayer" (Quran 4:101).
            """
        }
        if prayer.nameTransliteration == "Maghrib/Isha" {
            return """
            While traveling, Maghrib and Isha are joined. Maghrib stays 3 rak'ah (it is never shortened) and Isha is shortened to 2 rak'ah. Pray Maghrib first, then Isha immediately after it, in this one time slot.

            Ibn Abbas (may Allah be pleased with him) said: "The Prophet (peace be upon him) used to join Maghrib and Isha when he was traveling" (Sahih al-Bukhari 1108).

            "And when you travel throughout the land, there is no blame upon you for shortening the prayer" (Quran 4:101).
            """
        }

        if prayer.nameTransliteration.contains("Dhuhr") {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Dhuhr is when the sun has passed its zenith and a person’s shadow is equal in length to his height, until the time for Asr begins\" (Muslim 612)."
        }
        if prayer.nameTransliteration == "Jumuah" {
            return "Prophet Muhammad (peace be upon him) said: \"The Friday prayer is obligatory upon every Muslim in the time of Dhuhr, except for a child, a woman, or an ill person\" (Abu Dawood 1067)."
        }
        if prayer.nameTransliteration == "Asr" {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Asr prayer lasts until the sun turns yellow\" (Muslim 612)."
        }
        if prayer.nameTransliteration.contains("Maghrib") {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Maghrib lasts until the twilight has faded\" (Muslim 612)."
        }
        if prayer.nameTransliteration == "Isha" {
            return """
            Prophet Muhammad (peace be upon him) said: "The time for Isha lasts until the middle of the night" (Muslim 612).

            WITR: the night prayer is sealed with Witr, prayed any time after Isha until Fajr. The Prophet (peace and blessings be upon him) said: "Make Witr the last of your prayer at night" (Sahih al-Bukhari 998).

            It is an odd number of rak'ah: one, three, five, seven, or nine. The simplest and most common are a single rak'ah, or three. How the three are prayed differs between the madhahib (three joined with one tashahhud, or two then one), and all of these are established. If you fear you will not wake, pray it before you sleep; if you expect to wake, the last third of the night is better.
            """
        }
        if prayer.nameTransliteration == "Duhaa" {
            return """
            Duhaa is a voluntary prayer prayed after the sun has risen to the height of a spear, roughly 15 minutes after sunrise, until shortly before Dhuhr. Its best time is later in the morning, when the heat of the sun becomes stronger.

            "The forenoon prayer of the penitent is when young camels can feel the heat of the sun" (Muslim 784).

            "My friend (the Prophet (ﷺ) ) advised me to observe three things: (1) to fast three days a month; (2) to pray two rak`at of Duha prayer (forenoon prayer); and (3) to pray witr before sleeping." (Bukhari 1981).
            """
        }
        if prayer.nameTransliteration == "Islamic Midnight" {
            return """
            Islamic Midnight is halfway between Maghrib and the next Fajr. It marks the end of Isha and is used for calculating parts of the night.

            Formula: Islamic Midnight = Maghrib + ((Fajr - Maghrib) / 2)

            "When you pray Isha, its time is until half of the night has passed" (Muslim 612a).
            """
        }
        if prayer.nameTransliteration == "Last Third" {
            return """
            Tahajjud is commonly prayed during the last third of the night. A voluntary night prayer offered after Isha and before Fajr, its most virtuous time is during the final third of the night.

            The final third of the night before Fajr is a blessed time for prayer, dua, and seeking forgiveness.

            Formula: Last third starts = Fajr - ((Fajr - Maghrib) / 3)

            "Allah descends every night to the lowest heaven when one-third of the first part of the night is over and says: I am the Lord; I am the Lord: who is there to supplicate Me so that I answer him? Who is there to beg of Me so that I grant him? Who is there to beg forgiveness from Me so that I forgive him? He continues like this till the day breaks" (Muslim 758b).
            """
        }
        return nil
    }

    private func triggerBellAnimation(for prayer: Prayer) {
        // A wobble is decoration on a control people tap often; Reduce Motion (and Low Power Mode)
        // gets the new glyph alone, which already says what changed.
        guard !appearance.reduceAnimations else { return }
        animatingBellPrayerName = prayer.nameTransliteration

        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) {
            bellAnimationActive = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.18)) {
                bellAnimationActive = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            if animatingBellPrayerName == prayer.nameTransliteration {
                animatingBellPrayerName = nil
            }
        }
    }

    private func bellScale(for prayer: Prayer) -> CGFloat {
        animatingBellPrayerName == prayer.nameTransliteration && bellAnimationActive ? 1.2 : 1.0
    }

    private func bellRotation(for prayer: Prayer) -> Angle {
        animatingBellPrayerName == prayer.nameTransliteration && bellAnimationActive ? .degrees(18) : .degrees(0)
    }

    @ViewBuilder
    private func prayerBell(for prayer: Prayer, rowColor: Color) -> some View {
        let mode = settings.notificationMode(for: prayer)

        Image(systemName: mode.symbolName)
            .font(.subheadline)
            .frame(width: 18, height: 18)
            .foregroundColor(mode == .off ? rowColor : settings.accentColor.accent2)
            .scaleEffect(bellScale(for: prayer))
            .rotationEffect(bellRotation(for: prayer))
            .contentShape(Rectangle())
            .padding(4)
            .conditionalGlassEffect(flat: true)
            // The glass circle is 26 pt, under the 28 pt floor and far from the 44 pt the platform asks
            // for. The TOUCH area grows to 44 without moving anything: an interaction-only shape, so the
            // hold's context-menu preview still lifts just the circle.
            .contentShape(.interaction, Rectangle().inset(by: -9))
            .onTapGesture {
                settings.hapticFeedback()
                triggerBellAnimation(for: prayer)
                settings.cycleNotificationMode(for: prayer)
            }
            // Where the bell stands alone (the grid and split details) it is its own control; inside a
            // tile or row VoiceOver reaches it through that element's actions instead.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(prayer.displayName) notifications")
            .accessibilityValue(mode.spokenState)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                settings.hapticFeedback()
                settings.cycleNotificationMode(for: prayer)
            }
            #if os(iOS)
            // Tapping cycles the three modes; long-pressing jumps straight to one. Without this the only way
            // to reach "prenotification" from off was two taps through a mode you didn't want.
            .contextMenu {
                Text("Notifications")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    settings.setNotificationMode(.preNotification, for: prayer)
                } label: {
                    Label("Prenotification", systemImage: Settings.PrayerNotificationMode.preNotification.symbolName)
                }

                Button {
                    settings.hapticFeedback()
                    settings.setNotificationMode(.atTime, for: prayer)
                } label: {
                    Label("Notification", systemImage: Settings.PrayerNotificationMode.atTime.symbolName)
                }

                Button {
                    settings.hapticFeedback()
                    settings.setNotificationMode(.off, for: prayer)
                } label: {
                    Label("No Notification", systemImage: Settings.PrayerNotificationMode.off.symbolName)
                }
            }
            #endif
            .padding(.leading, 6)
    }
}

/// A leaf that observes nothing: the highlight colour comes in as a value from the list, which
/// already observes `Settings`.
private struct PrayerListRowCard<TrailingContent: View>: View {
    let prayer: Prayer
    let displayName: String
    let isCurrent: Bool
    let iconColor: Color
    let highlight: Color
    /// The tracker's answer, drawn as a dot beside the name (nil = unmarked or untracked).
    var trackerMark: PrayerMark? = nil
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isCurrent ? highlight : .clear)
                #if os(iOS)
                .padding(.vertical, backgroundVerticalPadding)
                .padding(.horizontal, -12)
                #else
                .padding(.horizontal, -10)
                #endif

            // Spacings are explicit. Nested stacks each contributed their own ~8pt default, which stacked into a
            // wide gap between the icon and the name, while the row itself had no vertical padding at all.
            HStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: prayer.image)
                        .font(.title3)
                        .foregroundColor(iconColor)
                        .frame(width: 28, alignment: .center)

                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    #if os(iOS)
                    PrayerMarkDot(mark: trackerMark)
                    #endif

                    Spacer(minLength: 8)

                    Text(prayer.time, style: .time)
                        #if os(iOS)
                        .font(.subheadline)
                        #else
                        .font(.caption)
                        #endif
                        .foregroundColor(.primary)
                }
                .contentShape(Rectangle())
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                trailingContent()
            }
            .padding(.vertical, 4)
        }
    }

    #if os(iOS)
    private var backgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -10
        }
        return -4
    }
    #endif
}

private struct PrayerDetailBlock: View {
    @ObservedObject private var settings = Settings.shared

    let prayer: Prayer
    let timeWindowText: String?
    let referenceText: String?

    private var isOptionalPrayer: Bool {
        Settings.optionalPrayerNames.contains(prayer.nameTransliteration)
    }

    /// The two prayers a combined (traveling) row actually stands for, with the time each one would have had
    /// on its own. The combined row carries only the FIRST prayer's time - Asr and Isha are dropped when the
    /// list is filtered for qasr - so their times are recovered from the uncombined list for the same day.
    private var combinedComponents: [(name: String, arabic: String, time: Date)] {
        let members: [String]
        switch prayer.nameTransliteration {
        case "Dhuhr/Asr": members = ["Dhuhr", "Asr"]
        case "Maghrib/Isha": members = ["Maghrib", "Isha"]
        default: return []
        }

        let full = settings.getPrayerTimes(for: prayer.time, fullPrayers: true) ?? []
        return members.compactMap { name in
            guard let match = full.first(where: { $0.nameTransliteration == name }) else { return nil }
            return (name: match.displayName, arabic: match.nameArabic, time: match.time)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                AccentIconChip(systemImage: prayer.image, tint: settings.accentColor.accent2, size: 26)

                Text(isOptionalPrayer ? prayer.nameEnglish : "\(prayer.nameEnglish) - \(prayer.nameArabic)")
                    .font(.title3)
                    .foregroundColor(settings.accentColor.accent2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // The window this time slot spans - from this prayer's own start to the next one, so it reads
            // the same whether the row is expanded before, during or after the prayer.
            if let timeWindowText {
                Text(timeWindowText)
                    .foregroundColor(.primary)
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // A combined row is titled "Daytime" / "Nighttime" and never names the two prayers it stands for,
            // so tapping it left you with no idea when Asr (or Isha) actually falls. Name them, with their
            // own times.
            let components = combinedComponents
            if !components.isEmpty {
                ForEach(components, id: \.name) { component in
                    (
                        Text("\(component.name) (\(component.arabic)): ")
                            + Text(component.time, style: .time)
                    )
                    .foregroundColor(.primary)
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                Text("Both are prayed together in this one slot, starting at the first prayer's time.")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)
            }

            if prayer.nameTransliteration == "Shurooq" {
                Text("Shurooq is not a prayer, but marks the end of Fajr.")
                    .foregroundColor(.primary)
                    .font(.footnote)
            } else if prayer.nameTransliteration == "Islamic Midnight" {
                Text("Midnight is not a prayer, but marks the end of Isha.")
                    .foregroundColor(.primary)
                    .font(.footnote)
            } else {
                if prayer.rakah != "0" {
                    Text("Prayer Rakahs: \(prayer.rakah)")
                        .foregroundColor(.primary)
                        .font(.body)
                }

                if prayer.sunnahBefore != "0" {
                    Text("Sunnah Rakahs Before: \(prayer.sunnahBefore)")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }

                if prayer.sunnahAfter != "0" {
                    Text("Sunnah Rakahs After: \(prayer.sunnahAfter)")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
            }

            // The sunnah caveat rides on the Prayer value (today only Jumuah's masjid/home split), so
            // this block needs no per-prayer name compare and new caveats need no view change.
            if let sunnahNote = prayer.sunnahNote {
                Text(sunnahNote)
                    .foregroundColor(.secondary)
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // The "other" Asr: when the user follows the Standard (majority) opinion, show the later Hanafi
            // Asr; when they follow Hanafi, show the earlier Standard Asr - so both timings are visible from
            // the Asr detail regardless of the madhab setting.
            if prayer.nameTransliteration == "Asr",
               let otherAsr = settings.otherMadhabAsrTime(onSameDayAs: prayer.time) {
                (
                    Text(settings.hanafiMadhab ? "Standard Asr: " : "Hanafi Asr: ")
                        + Text(otherAsr, style: .time)
                )
                .foregroundColor(.primary)
                .font(.footnote)
                .padding(.top, 2)

                Text(settings.hanafiMadhab
                     ? "The majority (Shāfiʿī/Mālikī/Ḥanbalī) time, when an object’s shadow equals its length."
                     : "The Ḥanafī time, when an object’s shadow reaches twice its length.")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let referenceText {
                Text(referenceText)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }
}

/// One VoiceOver element per prayer, in every layout. The rows and tiles are tap-gesture stacks, so
/// without this VoiceOver read the symbol, the name and the time as three unrelated items (none of them
/// a button), and the bell, an image with a tap gesture, could not be reached at all. The label is what
/// the tile says in words; the value is what it says by colour and glyph (current, the tracker's mark,
/// the bell); double tap opens the details, and the bell's three modes are actions, the same three its
/// context menu offers.
private struct PrayerAccessibility: ViewModifier {
    let label: String
    let value: String
    let isExpanded: Bool
    /// Nil where the layout draws no bell (the dimmed TODAY comparison rows, the watch).
    let bellMode: Settings.PrayerNotificationMode?
    let toggle: () -> Void
    let setBell: (Settings.PrayerNotificationMode) -> Void

    func body(content: Content) -> some View {
        let element = content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(isExpanded ? "Hides the details" : "Shows the details")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { toggle() }

        if bellMode != nil {
            element
                .accessibilityAction(named: "Prenotification") { setBell(.preNotification) }
                .accessibilityAction(named: "Notification") { setBell(.atTime) }
                .accessibilityAction(named: "No Notification") { setBell(.off) }
        } else {
            element
        }
    }
}

private extension Settings.PrayerNotificationMode {
    /// The bell in words, for VoiceOver (the glyph alone was the only carrier).
    var spokenState: String {
        switch self {
        case .off: return "notifications off"
        case .atTime: return "notification on"
        case .preNotification: return "prenotification on"
        }
    }
}

private extension Prayer {
    var stableDisplayID: String {
        "\(nameTransliteration)-\(Int(time.timeIntervalSince1970))"
    }

    var compactDisplayName: String {
        nameTransliteration == "Islamic Midnight" ? "Midnight" : nameTransliteration
    }
}

/// One cell of the Grid layout: icon over name over time, centred, in a rounded well. The current
/// prayer's well takes the accent (fill, hairline, glow); the rest are a faint neutral well so the
/// board reads as a grid instead of floating text (the Tilawa grid, 2026-10-01).
private struct PrayerGridTile: View {
    let prayer: Prayer
    let color: Color
    let isCurrent: Bool
    let accent: Color
    var trackerMark: PrayerMark? = nil

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: prayer.image)
                .font(.body.weight(.semibold))
                .foregroundColor(color)
                .accessibilityHidden(true)

            HStack(spacing: 4) {
                Text(prayer.compactDisplayName)
                    .font(.subheadline.weight(isCurrent ? .heavy : .bold))
                    .foregroundColor(color)

                #if os(iOS)
                PrayerMarkDot(mark: trackerMark)
                #endif
            }

            Text(prayer.time, style: .time)
                .font(.footnote.weight(.semibold).monospacedDigit())
                .foregroundColor(color)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(PrayerCellWell(isCurrent: isCurrent, accent: accent, cornerRadius: 14))
    }
}

/// One row of the Split layout: icon, name, time, on a rounded pill that fills with the accent
/// for the current prayer. `stacked` puts the time under the name (traveling's combined names).
private struct SplitPrayerRow: View {
    let prayer: Prayer
    let color: Color
    let isCurrent: Bool
    let accent: Color
    var stacked: Bool = false
    var trackerMark: PrayerMark? = nil

    var body: some View {
        // Footnote type, not subheadline: half a row is narrow. The time keeps its size; the name
        // trims last.
        HStack(spacing: 6) {
            Image(systemName: prayer.image)
                .font(.footnote.weight(.semibold))
                .frame(width: 18, alignment: .center)
                .accessibilityHidden(true)

            if stacked {
                VStack(alignment: .leading, spacing: 1) {
                    nameLine
                    time
                }
                Spacer(minLength: 0)
            } else {
                nameLine
                Spacer(minLength: 2)
                time
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, stacked ? 8 : 10)
        .background(PrayerCellWell(isCurrent: isCurrent, accent: accent, cornerRadius: 12, neutralOpacity: 0))
    }

    private var nameLine: some View {
        HStack(spacing: 5) {
            Text(prayer.compactDisplayName)
                .font(.footnote.weight(isCurrent ? .heavy : .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)

            #if os(iOS)
            PrayerMarkDot(mark: trackerMark)
            #endif
        }
    }

    private var time: some View {
        Text(prayer.time, style: .time)
            .font(.footnote.weight(.semibold).monospacedDigit())
            .fixedSize()
    }
}

/// The rounded ground under a grid cell or split row: the accent at 20% with a hairline and a soft
/// glow for the current prayer, a faint neutral well (or nothing) for the rest.
private struct PrayerCellWell: View {
    let isCurrent: Bool
    let accent: Color
    let cornerRadius: CGFloat
    var neutralOpacity: Double = 0.05

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(isCurrent ? accent.opacity(0.2) : Color.primary.opacity(neutralOpacity))
            .overlay(shape.strokeBorder(isCurrent ? accent.opacity(0.45) : .clear, lineWidth: 1))
            .softShadow(color: isCurrent ? accent.opacity(0.3) : .clear, radius: isCurrent ? 6 : 0, x: 0, y: 2)
    }
}

#Preview {
    AlIslamPreviewContainer {
        List {
            PrayerList()
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
    }
}
