import SwiftUI

/// The prayer-times section. It reads as one block of color, so every tint in here is the accent's *second*
/// color (`accent2`) — the date/location/sky section above it stays on the first. For a one-color accent the
/// two are the same color and this looks exactly as it always did.
struct PrayerList: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var scrubber = DayScrubber.shared

    // The calendar day this view last considered "today". Used to detect a rollover that happened while the
    // app was suspended so a stale `selectedDate` doesn't spuriously trigger the TODAY comparison on reopen.
    @State private var lastActiveDay = Calendar.current.startOfDay(for: Date())

    @State private var expandedPrayerKey: String?
    @State private var fullPrayers = false
    @State private var animatingBellPrayerName: String?
    @State private var bellAnimationActive = false
    @State private var selectedDate = Date()
    @State private var compareToday = true
    @State private var showOptionalPrayerToggles = false

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

    /// True when the user has picked a day other than today. Derived from `selectedDate` so the
    /// comparison UI stays in sync without any imperative state to keep updated.
    private var isShowingDifferentDay: Bool {
        !Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }

    /// Prayer times for an arbitrary day, computed on demand. Today reuses the already-fetched
    /// `settings.prayers`; any other day is generated directly (the generator is cached and fast).
    /// Computing this purely from `date` — instead of relying on `onChange` to populate published
    /// state — is what makes selecting a different day reliably refresh every display mode.
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
    /// it — e.g. the app was suspended overnight and reopened. Without this, the stale `selectedDate` (still
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
                compareToday = true
            }
        }
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

    /// Lets the optional/extra prayers (Duha, Islamic Midnight, Last Third) be shown or hidden right from
    /// the prayer page, so toggling them no longer means a trip into Settings. These bind to the same
    /// persisted settings used elsewhere — this is just a more discoverable entry point.
    @ViewBuilder
    private var optionalPrayersFooter: some View {
        #if os(iOS)
        // Everything lives in one VStack so it's a single list row — no internal separators to fight with.
        // The row's own bottom separator is hidden so the button reads as a clean standalone pill.
        VStack(spacing: 18) {
            // Hand-drawn dividers top and bottom (the real list separators are hidden) so both ends match.
            // The VStack spacing gives them breathing room from the button/content, while the negative
            // outer padding pulls them close to the neighboring rows above and below.
            Divider()

            footerActionButton(showOptionalPrayerToggles ? "Hide Optional Prayer Times" : "Show Optional Prayer Times") {
                showOptionalPrayerToggles.toggle()
            }

            if showOptionalPrayerToggles {
                VStack(spacing: 10) {
                    optionalPrayerToggle("Duha", isOn: $settings.showDuha)
                    optionalPrayerToggle("Islamic Midnight", isOn: $settings.showIslamicMidnight)
                    optionalPrayerToggle("Last Third of the Night", isOn: $settings.showLastThird)
                }

                Text("These extra prayer times appear in the app only, never in widgets.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                fullPrayers = false
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
                expandedPrayerDetailContent(for: prayer)
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
        // padding comes down — that's what lets six prayers fit a screen at a readable size.
        let columnCount = 2
        let tileSpacing: CGFloat = 6
        let tileHorizontalPadding: CGFloat = 7
        let tileVerticalPadding: CGFloat = 6
        #else
        let columnCount = settings.travelingMode ? 2 : 3
        let tileSpacing: CGFloat = 8
        let tileHorizontalPadding: CGFloat = 10
        let tileVerticalPadding: CGFloat = 6
        #endif
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: tileSpacing),
            count: columnCount
        )

        LazyVGrid(columns: columns, spacing: tileSpacing) {
            ForEach(prayers, id: \.stableDisplayID) { prayer in
                let color: Color = isComparisonBaseline ? .secondary : (highlightsCurrent ? prayerColor(for: prayer, in: prayers) : .primary)
                let isCurrent = highlightsCurrent && !isComparisonBaseline && isCurrentPrayer(prayer)

                VStack(alignment: .leading, spacing: 6) {
                    #if os(watchOS)
                    HStack(spacing: 4) {
                        Image(systemName: prayer.image)
                            .font(.caption2)
                            .foregroundColor(color)

                        Text(prayer.compactDisplayName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(color)
                    }

                    Text(prayer.time, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(color)
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
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePrayerExpansion(for: prayer)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .onChange(of: settings.travelingMode) { _ in
            withAnimation { fullPrayers = false }
        }

        expandedPrayerDetail(for: prayers)
    }

    @ViewBuilder
    private func expandedPrayerDetail(for prayers: [Prayer]) -> some View {
        if let prayer = prayers.first(where: { expansionKey(for: $0) == expandedPrayerKey }) {
            expandedPrayerDetailContent(for: prayer)
            .id(prayer.stableDisplayID)
            .contentShape(Rectangle())
        }
    }

    private func expandedPrayerDetailContent(for prayer: Prayer) -> some View {
        HStack(alignment: .top, spacing: 10) {
            PrayerDetailBlock(prayer: prayer, referenceText: prayerReferenceText(for: prayer))
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
                #endif

                footerActionButton(fullPrayers ? "View Qasr Prayers" : "View Full Prayers") {
                    fullPrayers.toggle()
                }

                #if os(watchOS)
                travelingModeDescription
                #endif
            }
        }
    }

    @ViewBuilder
    private var dateSelectionFooter: some View {
        #if os(iOS)
        VStack {
            DatePicker("Showing prayers for", selection: $selectedDate.animation(.easeInOut), displayedComponents: .date)
                .datePickerStyle(DefaultDatePickerStyle())
                .padding(4)

            if isShowingDifferentDay {
                footerActionButton(compareToday ? "Hide Today Comparison" : "Compare With Today") {
                    compareToday.toggle()
                }

                footerActionButton("Show prayers for today") {
                    selectedDate = Date()
                }
            }
        }
        .onChange(of: selectedDate) { _ in
            settings.hapticFeedback()
            // Re-show the today comparison by default whenever a different day is picked.
            if isShowingDifferentDay {
                compareToday = true
            }
        }
        #endif
    }

    private var travelingModeDescription: some View {
        Text("Traveling mode is on. If you are traveling more than 48 mi, then you can pray Qasr, where you combine prayers. You can customize and learn more in settings.")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func footerActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Text(title)
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
        let reference = scrubber.previewPrayer ?? settings.currentPrayer
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

    private func prayerReferenceText(for prayer: Prayer) -> String? {
        if prayer.nameTransliteration == "Fajr" {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Fajr prayer is from the appearance of dawn until the sun begins to rise\" (Sahih Muslim 612)."
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
            return "Prophet Muhammad (peace be upon him) said: \"The time for Isha lasts until the middle of the night\" (Muslim 612)."
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

            HStack {
                HStack {
                    Image(systemName: prayer.image)
                        .font(.title3)
                        .foregroundColor(iconColor)
                        .frame(width: 32, alignment: .center)
                        .padding(.trailing, 2)

                    VStack(alignment: .leading) {
                        Text(displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

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
    let referenceText: String?

    private var isOptionalPrayer: Bool {
        Settings.optionalPrayerNames.contains(prayer.nameTransliteration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isOptionalPrayer ? prayer.nameEnglish : "\(prayer.nameEnglish) - \(prayer.nameArabic)")
                .font(.title3)
                .foregroundColor(settings.accentColor.accent2)
                .lineLimit(1)

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

            // The "other" Asr: when the user follows the Standard (majority) opinion, show the later Hanafi
            // Asr; when they follow Hanafi, show the earlier Standard Asr — so both timings are visible from
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
                    .padding(.trailing, -2)

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
