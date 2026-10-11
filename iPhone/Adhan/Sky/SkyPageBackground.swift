// The sky behind the whole Adhan tab (Abu, 2026-10-11: "a setting (off by default) to make the whole
// background of adhan tab sky color"). The same period gradient, stars and weather the sky card
// paints, stretched under every row of the tab, with a page scrim so the rows' white text reads
// over a midday blue. `Settings.skyFillsAdhanTab` turns it on; AdhanView applies it through
// `skyPageFill(active:paused:)`, which also turns the rows to glass (`SkyPageFill.rowColor`) and
// the list's content to the dark scheme.
#if os(iOS)
import SwiftUI

struct SkyPageBackground: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var scrubber = DayScrubber.shared
    @Environment(\.appearance) private var appearance
    #if HAS_WEATHER
    @ObservedObject private var weatherStore = SkyWeatherStore.shared
    #endif

    /// True while another tab is in front: the stars' twinkle pauses, as on the card.
    let paused: Bool

    @State private var clockAnchor = Date()

    var body: some View {
        let interval: TimeInterval = appearance.isReducedTier ? 300 : 60
        TimelineView(.periodic(from: clockAnchor, by: interval)) { context in
            frame(now: SkyView.effectiveNow(context.date))
        }
        .onAppear { clockAnchor = Date() }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func frame(now: Date) -> some View {
        // The dragged moment, like the card: scrubbing the sun recolors the whole page with it.
        let moment = scrubber.scrubbedDate ?? now
        let period = settings.skyPeriodName(at: moment)
        #if HAS_WEATHER
        let weather = weatherStore.freshWeather
        #else
        let weather: SkyWeather? = nil
        #endif
        let colors = settings.skyGradientColors(forPrayer: period, weather: weather)
        let starOpacity = SkyStars.opacity(forPeriod: period) * (weather?.look.starFactor ?? 1)
        let tintKey = "\(period ?? "")|\(weather?.look.signature ?? "")"

        return ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                .animation(.easeInOut(duration: scrubber.isScrubbing ? 0.2 : 1.0), value: tintKey)
                .animation(.easeInOut(duration: 0.25), value: settings.skyGradientsJSON)

            StarFieldView(opacity: starOpacity, paused: paused)
                .animation(.easeInOut(duration: 0.6), value: starOpacity)

            if let weather, !weather.look.isClear {
                SkyWeatherOverlay(look: weather.look, night: starOpacity > 0.4 || !weather.isDaylight,
                                  time: now.timeIntervalSinceReferenceDate)
                    .transition(.opacity)
            }

            // The page scrim: the card's own scrim is weighted to its two text bands; the page is
            // text from top to bottom, so this one simply deepens toward the foot, where the glance
            // wall's small captions sit.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.18), location: 0.0),
                    .init(color: .black.opacity(0.30), location: 0.55),
                    .init(color: .black.opacity(0.42), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

extension View {
    /// The Adhan tab's whole-tab sky: `SkyPageBackground` under the List, every row on the sky's
    /// glass and the list's content in the dark scheme, with the navigation bar's title to match.
    /// Apply it to the List BEFORE `applyConditionalListStyle()` (so the sky sits over the reading
    /// theme's ground) and keep the sheets outside it: the dark scheme is set on the list's CONTENT
    /// through `skyPageContent`, never on the List itself, or every sheet presented from the tab would
    /// inherit it.
    @ViewBuilder
    func skyPageFill(active: Bool, paused: Bool) -> some View {
        if active {
            self
                .background(SkyPageBackground(paused: paused))
                .modifier(SkyPageToolbar())
        } else {
            self
        }
    }

    /// The content half of `skyPageFill`: the rows' glass and the dark scheme, on the Group inside
    /// the List. `scheme` is the scheme the content keeps when the sky is off.
    func skyPageContent(active: Bool, scheme: ColorScheme) -> some View {
        self
            .environment(\.skyPageFill, active)
            .environment(\.colorScheme, active ? .dark : scheme)
    }
}

/// The navigation bar over the page sky: its title in white, since the bar blends into the sky.
private struct SkyPageToolbar: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            content
        }
    }
}
#endif
