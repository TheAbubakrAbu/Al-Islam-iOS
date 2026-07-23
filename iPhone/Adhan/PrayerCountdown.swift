import SwiftUI

struct PrayerCountdown: View {
    /// Where the countdown is being drawn. `.section` is the standalone list card; `.embedded` is inside
    /// `SkyView`'s gradient, which supplies its own heading and background.
    enum Presentation {
        /// The standalone list card, used when the sky is switched off.
        case section
        /// Only the progress bar and "Time Left" row, drawn inside `SkyView`, which paints the prayer columns
        /// itself. `PrayerCountdown` still owns the adaptive refresh timer that drives `progress`.
        case skyFooter
    }

    var presentation: Presentation = .section

    @ObservedObject private var settings = Settings.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var progress: Double = 0
    @State private var updateTimer: Timer?

    private let slowTimerInterval: TimeInterval = 60
    private let mediumTimerInterval: TimeInterval = 15
    private let fastTimerInterval: TimeInterval = 5
    private let urgentTimerInterval: TimeInterval = 1
    private let urgentThreshold: TimeInterval = 30
    private let fastThreshold: TimeInterval = 120
    private let mediumThreshold: TimeInterval = 600

    private var currentPrayer: Prayer? { settings.currentPrayer }
    private var nextPrayer: Prayer? { settings.nextPrayer }

    var body: some View {
        if let currentPrayer, let nextPrayer {
            countdownContent(current: currentPrayer, next: nextPrayer)
        }
    }

    private func countdownContent(current: Prayer, next: Prayer) -> some View {
        countdownSection(current: current, next: next)
            .onAppear {
                refreshProgressAndPrayerState()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: scenePhase) { phase in
                handleScenePhaseChange(phase)
            }
            .onChange(of: settings.prayers) { _ in
                refreshProgressAndPrayerState()
                startTimer()
            }
            .onChange(of: currentPrayer) { _ in
                updateProgress()
                startTimer()
            }
            .onChange(of: nextPrayer) { _ in
                updateProgress()
                startTimer()
            }
    }

    @ViewBuilder
    private func countdownSection(current: Prayer, next: Prayer) -> some View {
        switch presentation {
        case .section:
            #if os(watchOS)
            Section(header: Text("UP NEXT")) {
                watchBody(current: current, next: next)
            }
            #else
            Section(header: sectionHeader) {
                tappableBody(current: current, next: next)
            }
            #endif
        case .skyFooter:
            // No `Section` - the sky card already is one, and a nested section inside a list row breaks it.
            VStack(spacing: 2) {
                countdownProgress(next: next)
                timeLeftRow(next: next)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.25)
            // Stated outright rather than left to `.primary`. The sky card forces a dark color scheme, but a
            // `Text(_, style: .timer)` takes its color from the UIKit trait collection instead, so under a
            // light system appearance the countdown rendered black on the dark card.
            .foregroundColor(.white)
        }
    }

    private func tappableBody(current: Prayer, next: Prayer) -> some View {
        countdownBody(current: current, next: next)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                withAnimation { settings.showPrayerInfo.toggle() }
            }
    }

    private func countdownBody(current: Prayer, next: Prayer) -> some View {
        VStack {
            prayerSummary(current: current, next: next)
            countdownProgress(next: next)
            timeLeftRow(next: next)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.25)
        // Tightened: the card was carrying a lot of empty vertical space.
        .padding(.vertical, {
            if #available(iOS 26, *) { return 0 } else { return 4 }
        }())
    }

    private var sectionHeader: some View {
        HStack {
            Text("CURRENT")

            Spacer()

            Text("UPCOMING")
        }
    }

    #if os(watchOS)
    /// The watch gets its own shape. The phone's two-column "CURRENT | UPCOMING" card, with a full time under
    /// each side, is far too much text for a 40mm screen - you end up reading it rather than glancing at it.
    /// Here the time remaining is the biggest thing on the card, the next prayer names itself right above, and
    /// the prayer you're currently in is demoted to one quiet line underneath.
    private func watchBody(current: Prayer, next: Prayer) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: next.image)
                    .font(.caption2)

                Text(countdownDisplayName(for: next))
                    .font(.caption.weight(.semibold))

                Spacer(minLength: 2)

                Text(next.time, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .foregroundColor(next.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.accent2)

            Text(next.time, style: .timer)
                .font(.title2.monospacedDigit().weight(.bold))
                .frame(maxWidth: .infinity, alignment: .center)

            countdownProgress(next: next)

            HStack(spacing: 4) {
                Text("Now")
                    .foregroundStyle(.tertiary)

                Text(countdownDisplayName(for: current))
                    .foregroundColor(current.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.accent1)

                Spacer(minLength: 2)

                Text(current.time, style: .time)
                    .foregroundStyle(.secondary)
            }
            .font(.caption2)

            // A one-line sky: where the sun is between sunrise and sunset, and tonight's moon. The iPhone's
            // full SkyView has no business on a wrist, but these two facts survive the shrink.
            WatchSkyStrip()
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
    #endif

    @ViewBuilder
    private func prayerSummary(current: Prayer, next: Prayer) -> some View {
        VStack {
            summaryRow(current: current, next: next)
            
            if settings.showPrayerInfo {
                prayerInfoRow(current: current, next: next)
            }
        }
        .padding(.bottom, -2)
    }

    private func summaryRow(current: Prayer, next: Prayer) -> some View {
        HStack(alignment: .top) {
            CurrentPrayerCell(prayer: current)
            summaryDivider
            UpcomingPrayerCell(prayer: next)
        }
    }

    private var summaryDivider: some View {
        Divider()
            .background(settings.accentColor.color)
            .padding(.horizontal, 2)
    }

    private func prayerInfoRow(current: Prayer, next: Prayer) -> some View {
        VStack {
            Divider()
                .background(settings.accentColor.color)

            HStack(alignment: .top) {
                CurrentPrayerInfoView(prayer: current)
                UpcomingPrayerInfoView(prayer: next)
            }
        }
    }

    @ViewBuilder
    private func countdownProgress(next: Prayer) -> some View {
        Group {
            // A solid accent keeps the stock `ProgressView` - identical to what shipped. Only a real
            // two-color accent swaps in the custom bar, which is the only way to fill with a gradient.
            if settings.accentColor.isGradient {
                AccentGradientBar(progress: progress)
            } else {
                ProgressView(value: progress)
                    .tint(settings.accentColor.color)
            }
        }
        .conditionalGlassEffect()
        .padding(.vertical, 2)
        #if os(watchOS)
        .padding(.top, 4)
        #endif
    }

    /// Was a plain "Time Left: 00:12:34" headline - visually a relic next to the rest of the card. Now it
    /// reads as a compact meter caption: a muted label on the left, the live timer in the accent on the right.
    private func timeLeftRow(next: Prayer) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.caption2)

            Text("Time left")
                .font(.caption)

            Spacer(minLength: 4)

            Text(next.time, style: .timer)
                .font(.caption.monospacedDigit().weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        if phase == .active {
            refreshProgressAndPrayerState()
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func refreshProgressAndPrayerState() {
        settings.updateCurrentAndNextPrayer()
        // Cheap and self-guarded (early-returns unless the hijri day actually changed): keeps the
        // displayed hijri date correct across Maghrib (when "switch at Maghrib" is on) and across
        // midnight while the app stays foregrounded, without waiting for the next fetch.
        settings.updateDates()
        updateProgress()
    }

    private func updateProgress() {
        progress = progressValue()
    }

    private func progressValue() -> Double {
        guard var start = currentPrayer?.time, var end = nextPrayer?.time else { return 0 }

        let now = Date()

        // Handle the common overnight boundary where the current prayer began the previous day.
        if start > now {
            start.addTimeInterval(-86_400)
        }

        if end <= start {
            end.addTimeInterval(86_400)
        }

        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }

        let remaining = end.timeIntervalSince(now)
        return max(0, min(1, 1 - remaining / total))
    }

    private func startTimer() {
        stopTimer()
        let interval = nextRefreshInterval()
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            DispatchQueue.main.async {
                refreshProgressAndPrayerState()
                startTimer()
            }
        }
        updateTimer?.tolerance = min(interval * 0.2, 5)
    }

    private func nextRefreshInterval() -> TimeInterval {
        guard let nextPrayer else { return slowTimerInterval }

        let remaining = nextPrayer.time.timeIntervalSinceNow
        if remaining <= urgentThreshold {
            return urgentTimerInterval
        }
        if remaining <= fastThreshold {
            return fastTimerInterval
        }
        if remaining <= mediumThreshold {
            return mediumTimerInterval
        }
        return slowTimerInterval
    }

    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}

extension PrayerCountdown: Equatable {
    /// Everything this view draws comes from observed `Settings` state or its own timer-driven
    /// `progress` - both of which invalidate the view directly, bypassing this comparison. A
    /// parent-driven re-evaluation therefore never carries new information, and `presentation` is
    /// the only stored input. Gating on it matters for `.skyFooter`: `SkyView` re-runs its body
    /// every second to move the sun and would otherwise drag the whole countdown subtree with it.
    static func == (lhs: PrayerCountdown, rhs: PrayerCountdown) -> Bool {
        lhs.presentation == rhs.presentation
    }
}

private struct CurrentPrayerCell: View {
    @ObservedObject private var settings = Settings.shared

    let prayer: Prayer

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            title
            
            #if os(iOS)
            subtitle
            #endif
            
            Text("Started at \(prayer.time, style: .time)")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }

    private var title: some View {
        HStack {
            #if os(iOS)
            Image(systemName: prayer.image)
                .lineLimit(1)
                .minimumScaleFactor(1)
            #else
            if !prayer.nameTransliteration.contains("/") {
                Image(systemName: prayer.image)
            }
            #endif
            Text(countdownDisplayName(for: prayer))
        }
        .modifier(PrayerTitleStyle(prayer: prayer))
    }

    private var subtitle: some View {
        PrayerSubtitleView(prayer: prayer, alignment: .leading)
    }
}

private struct UpcomingPrayerCell: View {
    @ObservedObject private var settings = Settings.shared

    let prayer: Prayer

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            title
            
            #if os(iOS)
            subtitle
            #endif
            
            Text("Starts at \(prayer.time, style: .time)")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
    }

    private var title: some View {
        HStack {
            Text(countdownDisplayName(for: prayer))
            
            #if os(iOS)
            Image(systemName: prayer.image)
                .lineLimit(1)
                .minimumScaleFactor(1)
            #else
            if !prayer.nameTransliteration.contains("/") {
                Image(systemName: prayer.image)
            }
            #endif
        }
        .modifier(PrayerTitleStyle(prayer: prayer))
    }

    private var subtitle: some View {
        PrayerSubtitleView(prayer: prayer, alignment: .trailing)
    }
}

private func countdownDisplayName(for prayer: Prayer) -> String {
    prayer.nameTransliteration == "Islamic Midnight" ? "Midnight" : prayer.displayName
}

private struct PrayerTitleStyle: ViewModifier {
    @ObservedObject private var settings = Settings.shared

    let prayer: Prayer

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .font(.title3)
            #else
            .font(.subheadline)
            #endif
            .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
    }
}

private struct PrayerSubtitleView: View {
    @ObservedObject private var settings = Settings.shared

    let prayer: Prayer
    let alignment: TextAlignment

    private var isCombinedTravelPrayer: Bool {
        prayer.nameTransliteration.contains("/")
    }

    private var subtitleText: String {
        if Settings.optionalPrayerNames.contains(prayer.nameTransliteration) {
            if prayer.nameTransliteration == "Islamic Midnight" {
                return "Middle of Night"
            }
            return prayer.nameEnglish
        }
        if isCombinedTravelPrayer {
            return prayer.nameArabic
        }
        return "\(prayer.nameEnglish) / \(prayer.nameArabic)"
    }

    private var subtitleColor: Color {
        prayer.nameTransliteration == "Shurooq" ? .primary.opacity(0.7) : settings.accentColor.color.opacity(0.7)
    }

    var body: some View {
        Text(subtitleText)
            .font(.title3)
            .foregroundColor(subtitleColor)
            .multilineTextAlignment(alignment)
    }
}

private struct CurrentPrayerInfoView: View {
    let prayer: Prayer

    var body: some View {
        PrayerInfoColumn(prayer: prayer, alignment: .leading)
    }
}

private struct UpcomingPrayerInfoView: View {
    let prayer: Prayer

    var body: some View {
        PrayerInfoColumn(prayer: prayer, alignment: .trailing)
    }
}

private struct PrayerInfoColumn: View {
    let prayer: Prayer
    let alignment: Alignment

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 5) {
            PrayerRakahInfoView(prayer: prayer, captionFont: .caption, alignment: alignment)
            PrayerSunnahInfoView(prayer: prayer, alignment: alignment)
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .multilineTextAlignment(textAlignment)
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return .center
        }
    }

    private var textAlignment: TextAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return .center
        }
    }
}

private struct PrayerRakahInfoView: View {
    let prayer: Prayer
    let captionFont: Font
    let alignment: Alignment

    private var isOptionalPrayer: Bool {
        Settings.optionalPrayerNames.contains(prayer.nameTransliteration)
    }

    var body: some View {
        Group {
            if prayer.rakah != "0" {
                Text("Prayer Rakahs: \(prayer.rakah)")
                    #if os(iOS)
                    .font(captionFont)
                    #else
                    .font(.caption2)
                    #endif
                    .foregroundColor(.primary)
            } else if prayer.nameTransliteration == "Islamic Midnight" {
                Text("Midnight is not a prayer, but marks the end of Isha")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else if isOptionalPrayer {
                Text(prayer.nameEnglish)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text("Shurooq is not a prayer, but marks the end of Fajr")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
    }
}

private struct PrayerSunnahInfoView: View {
    let prayer: Prayer
    let alignment: Alignment

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 5) {
            if prayer.sunnahBefore != "0" {
                Text("Sunnah Rakahs Before: \(prayer.sunnahBefore)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if prayer.sunnahAfter != "0" {
                Text("Sunnah Rakahs After: \(prayer.sunnahAfter)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return .center
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        List {
            PrayerCountdown()
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
    }
}

/// A linear progress bar filled with the accent gradient. `ProgressView` only accepts a flat `tint`, so a
/// two-color accent needs its own bar. Matches the stock bar's 4pt height and capsule ends.
struct AccentGradientBar: View {
    @ObservedObject private var settings = Settings.shared

    /// 0…1. Clamped, because a stale progress value crossing a prayer boundary can briefly fall outside it.
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            let fraction = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.18))

                Capsule()
                    .fill(settings.accentColor.gradient(from: .leading, to: .trailing))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 4)
    }
}
