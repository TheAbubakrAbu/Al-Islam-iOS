import SwiftUI

/// The prayer-times section. It reads as one block of color, so every tint in here is the accent's *second*
/// color (`accent2`) - the date/location/sky section above it stays on the first. For a one-color accent the
/// two are the same color and this looks exactly as it always did.
struct PrayerList: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.scenePhase) private var scenePhase
    // The HIGHLIGHT slice of the scrubber, not the scrubber itself: `ScrubHighlight` publishes only when
    // the prayer under the thumb changes (a handful of times per drag). Observing `DayScrubber` here made
    // every touch-move of the sun rebuild this whole section - list, sorts and all - ~60×/second.
    @ObservedObject private var scrubHighlight = ScrubHighlight.shared

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
    /// `settings.prayers`; any other day is generated directly (the generator is cached and fast).
    /// Computing this purely from `date` - instead of relying on `onChange` to populate published
    /// state - is what makes selecting a different day reliably refresh every display mode.
    private func prayers(for date: Date) -> [Prayer] {
        if Calendar.current.isDate(date, inSameDayAs: Date()), let prayers = settings.prayers {
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
        if settings.prayers != nil {
            prayerListSection
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
        // itself via the countdown's boundary timeline, but the displayed list served `settings.prayers`
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
                Text("—")
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
            HStack(spacing: 10) {
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
            Spacer()

            Picker("", selection: $prayerDisplayModeRawValue.animation(.easeInOut)) {
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
                trailingContent: {
                    #if os(iOS)
                    prayerBell(for: prayer, rowColor: .primary)
                    #endif
                }
            )

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
            repeating: GridItem(.flexible(), spacing: 12),
            count: prayers.count == 4 ? 2 : 3
        )

        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(prayers, id: \.stableDisplayID) { prayer in
                let color: Color = isComparisonBaseline ? .secondary : (highlightsCurrent ? legacyGridPrayerColor(for: prayer, in: prayers) : .primary)

                PrayerGridTile(
                    prayer: prayer,
                    color: color,
                    trailingContent: {
                        EmptyView()
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePrayerExpansion(for: prayer)
                }
            }
        }
        .padding(.horizontal, -20)
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        expandedPrayerDetail(for: prayers)
    }

    @ViewBuilder
    private func splitContent(prayers: [Prayer], isComparisonBaseline: Bool = false, highlightsCurrent: Bool = true) -> some View {
        let midpoint = Int(floor(Double(prayers.count) / 2.0))
        let firstHalf = Array(prayers.prefix(midpoint))
        let secondHalf = Array(prayers.suffix(prayers.count - midpoint))

        HStack(spacing: 0) {
            VStack(spacing: 4) {
                ForEach(firstHalf, id: \.stableDisplayID) { prayer in
                    let color: Color = isComparisonBaseline ? .secondary : (highlightsCurrent ? prayerColor(for: prayer, in: prayers) : .primary)

                    SplitPrayerRow(
                        prayer: prayer,
                        color: color,
                        trailingContent: {
                            EmptyView()
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePrayerExpansion(for: prayer)
                    }
                }
            }

            Divider()
                .background(settings.accentColor.accent2)
                .padding(.horizontal, 8)

            VStack(spacing: 4) {
                ForEach(secondHalf, id: \.stableDisplayID) { prayer in
                    let color: Color = isComparisonBaseline ? .secondary : (highlightsCurrent ? prayerColor(for: prayer, in: prayers) : .primary)

                    SplitPrayerRow(
                        prayer: prayer,
                        color: color,
                        trailingContent: {
                            EmptyView()
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePrayerExpansion(for: prayer)
                    }
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        expandedPrayerDetail(for: prayers)
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

        LazyVGrid(columns: columns, spacing: tileSpacing) {
            ForEach(prayers, id: \.stableDisplayID) { prayer in
                let color: Color = isComparisonBaseline ? .secondary : (highlightsCurrent ? prayerColor(for: prayer, in: prayers) : .primary)
                let isCurrent = highlightsCurrent && !isComparisonBaseline && isCurrentPrayer(prayer)

                VStack(alignment: .leading, spacing: 2) {
                    #if os(watchOS)
                    HStack(spacing: 3) {
                        Image(systemName: prayer.image)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(color)

                        // The name owns the line: a fixed-size icon plus layoutPriority keeps a long
                        // name ("Shurooq") from being the one tile that scales to a sliver while its
                        // neighbors render full size. 0.8 is a trim, not a shrink.
                        Text(prayer.compactDisplayName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(color)
                            .minimumScaleFactor(0.8)
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

                    Text(prayer.compactDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(color)

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
                    customTint: isCurrent ? settings.accentColor.accent2 : nil
                )
                // The soft accent glow lifts the current prayer's tile off the board - the tint said
                // "different", the glow says "now".
                .shadow(color: isCurrent ? settings.accentColor.accent2.opacity(0.35) : .clear,
                        radius: isCurrent ? 8 : 0, x: 0, y: 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePrayerExpansion(for: prayer)
                }
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
    }

    @ViewBuilder
    private var travelModeFooter: some View {
        if settings.travelingMode {
            VStack {
                #if os(iOS)
                travelingModeDescription

                HStack(spacing: 10) {
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
                NavigationView {
                    SettingsAdhanView(showNotifications: false, presentedAsSheet: true, openTravelingMode: true)
                }
                .navigationViewStyle(.stack)
                .smallMediumSheetPresentation()
            }
            #endif
        }
    }

    @ViewBuilder
    private var dateSelectionFooter: some View {
        #if os(iOS)
        VStack {
            HStack(spacing: 8) {
                Text("Showing prayers for")

                Spacer(minLength: 4)

                dayStepButton(systemName: "chevron.backward", byDays: -1)

                DatePicker("Showing prayers for", selection: $selectedDate.animation(.easeInOut), displayedComponents: .date)
                    .datePickerStyle(DefaultDatePickerStyle())
                    .labelsHidden()

                dayStepButton(systemName: "chevron.forward", byDays: 1)
            }
            .padding(4)

            if isShowingDifferentDay {
                HStack(spacing: 10) {
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
        // Names the HOME CITY the 48-mile rule measures from, and points at the exact control that
        // changes it - "customize in settings" alone left the reader hunting (user rule).
        let homeCity = settings.homeLocation?.city.trimmingCharacters(in: .whitespacesAndNewlines)
        #if os(watchOS)
        // No Travel Settings button on the watch - the pointer would dangle.
        let homeSentence = (homeCity?.isEmpty == false)
            ? "Your home city is \(homeCity!) - you can change it in the iPhone app's Travel Settings."
            : "You can set your home city in the iPhone app's Travel Settings."
        #else
        let homeSentence = (homeCity?.isEmpty == false)
            ? "Your home city is \(homeCity!) - you can change it by tapping Travel Settings below."
            : "You can set your home city by tapping Travel Settings below."
        #endif
        return Text("Traveling mode is on. If you are traveling more than 48 mi from home, you can pray Qasr, where you shorten and combine prayers. \(homeSentence)")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    #if os(iOS)
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
    }
    #endif

    /// Pass `isExpanded` for buttons that disclose content below: they get a rotating chevron, so the
    /// title can stay short ("Rakaah Guide") instead of carrying a Show/Hide prefix.
    private func footerActionButton(_ title: String, isExpanded: Bool? = nil, action: @escaping () -> Void) -> some View {
        HStack(spacing: 5) {
            Text(title)

            if let isExpanded {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .foregroundColor(settings.accentColor.accent2)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(8)
        .conditionalGlassEffect()
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation {
                action()
            }
        }
    }

    /// While the sun is being dragged along `SkyView`'s arc, the highlight follows the dragged moment rather
    /// than the live one, so scrubbing the day walks it down the rows.
    private func isCurrentPrayer(_ prayer: Prayer) -> Bool {
        let reference = scrubHighlight.previewPrayer ?? settings.currentPrayer
        return reference?.nameTransliteration.contains(prayer.nameTransliteration) ?? false
    }

    private func prayerColor(for prayer: Prayer, in prayers: [Prayer]) -> Color {
        guard let prayerIndex = prayers.firstIndex(where: { $0.id == prayer.id }) else {
            return .secondary
        }

        guard let currentPrayerIndex = prayers.firstIndex(where: { $0.nameTransliteration == settings.currentPrayer?.nameTransliteration }) else {
            return .secondary
        }

        if prayerIndex < currentPrayerIndex {
            return .secondary
        }
        if prayerIndex == currentPrayerIndex {
            return settings.accentColor.accent2
        }
        return .primary
    }

    private func legacyGridPrayerColor(for prayer: Prayer, in prayers: [Prayer]) -> Color {
        guard let currentPrayer = settings.currentPrayer else {
            return .secondary
        }

        if currentPrayer.nameTransliteration.contains(prayer.nameTransliteration) {
            return settings.accentColor.accent2
        }

        guard let currentPrayerIndex = prayers.firstIndex(where: { $0.id == currentPrayer.id }),
              let prayerIndex = prayers.firstIndex(where: { $0.id == prayer.id }) else {
            return .secondary
        }

        return prayerIndex < currentPrayerIndex ? .secondary : .primary
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
            .conditionalGlassEffect()
            .onTapGesture {
                settings.hapticFeedback()
                triggerBellAnimation(for: prayer)
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

private struct PrayerListRowCard<TrailingContent: View>: View {
    @ObservedObject private var settings = Settings.shared

    let prayer: Prayer
    let displayName: String
    let isCurrent: Bool
    let iconColor: Color
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isCurrent ? settings.accentColor.accent2.opacity(0.25) : .clear)
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

private extension Prayer {
    var stableDisplayID: String {
        "\(nameTransliteration)-\(Int(time.timeIntervalSince1970))"
    }

    var compactDisplayName: String {
        nameTransliteration == "Islamic Midnight" ? "Midnight" : nameTransliteration
    }
}

private struct PrayerGridTile<TrailingContent: View>: View {
    let prayer: Prayer
    let color: Color
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: prayer.image)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .padding([.trailing, .bottom], -2)

                Text(prayer.compactDisplayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                trailingContent()
            }

            Text(prayer.time, style: .time)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
}

private struct SplitPrayerRow<TrailingContent: View>: View {
    let prayer: Prayer
    let color: Color
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: prayer.image)
                .font(.subheadline)
                .frame(width: 20, alignment: .center)

            Text(prayer.compactDisplayName)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            Text(prayer.time, style: .time)
                .fontWeight(.bold)

            trailingContent()
        }
        .foregroundColor(color)
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
