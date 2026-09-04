#if os(iOS)
import SwiftUI

// MARK: - Solar geometry

/// The sun's height above the horizon over one day, normalized to −1…1.
///
/// Solar elevation is `sin(alt) = sinφ·sinδ + cosφ·cosδ·cos(H)` - an affine function of the cosine of the hour
/// angle. So the normalized curve is simply `cos(2π·(x − solarNoon))`, and the horizon sits at whatever height
/// that curve has at sunrise. Deriving the horizon from the app's *actual* sunrise and Maghrib times (rather
/// than assuming 6am/6pm) is what makes a long June day show more curve above the line than a short December one.
struct SolarCurve {
    /// Fraction of the day at sunrise and at sunset, in 0…1.
    let sunriseFraction: Double
    let sunsetFraction: Double

    var solarNoonFraction: Double { (sunriseFraction + sunsetFraction) / 2 }

    /// Normalized height of the horizon line, in −1…1.
    var horizon: Double { cos(.pi * (sunsetFraction - sunriseFraction)) }

    /// Normalized sun height at a given fraction of the day.
    func height(at fraction: Double) -> Double {
        cos(2 * .pi * (fraction - solarNoonFraction))
    }

    func isDaylight(at fraction: Double) -> Bool {
        fraction >= sunriseFraction && fraction <= sunsetFraction
    }

    /// Falls back to a nominal quarter-to-three-quarters day when sunrise and sunset don't bracket a sane
    /// daylight span - no prayer times yet, or a polar day/night where the library returns nothing at all.
    init(sunriseFractionOfWindow s: Double?, sunsetFractionOfWindow e: Double?) {
        if let s, let e, e > s, (0...1).contains(s), (0...1).contains(e) {
            sunriseFraction = s
            sunsetFraction = e
        } else {
            sunriseFraction = 0.25
            sunsetFraction = 0.75
        }
    }
}

/// The 24-hour span the arc draws, centred on the location's solar noon.
///
/// Anchoring on solar noon rather than on device-local midnight is what keeps the arc honest when the device's
/// time zone doesn't match the coordinates it is computing for - someone who just landed and whose phone hasn't
/// switched over, or anyone with automatic time off. Prayer times are absolute instants; midnight is not.
/// Centring on the midpoint of sunrise and sunset makes the sun's peak land at the middle of the card by
/// construction, whatever the zone.
struct SolarWindow {
    let start: Date
    let length: TimeInterval

    var end: Date { start.addingTimeInterval(length) }

    func fraction(of date: Date) -> Double {
        guard length > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / length, 0), 1)
    }

    func date(atFraction fraction: Double) -> Date {
        start.addingTimeInterval(min(max(fraction, 0), 1) * length)
    }

    /// `sunrise`/`sunset` are today's real Shurooq and Maghrib. Without them we fall back to the device's
    /// calendar day, which is DST-aware and correct whenever the zone does match the location.
    init(sunrise: Date?, sunset: Date?, fallbackDayStart: Date, fallbackDayLength: TimeInterval) {
        if let sunrise, let sunset, sunset > sunrise, sunset.timeIntervalSince(sunrise) < 86_400 {
            let solarNoon = sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) / 2)
            start = solarNoon.addingTimeInterval(-43_200)
            length = 86_400
        } else {
            start = fallbackDayStart
            length = fallbackDayLength
        }
    }
}

/// The dashed sun path. Drawn as a polyline of the normalized curve, mapped into the rect with `inset` of
/// vertical padding so the peak and trough don't touch the edges.
private struct SolarArcShape: Shape {
    let curve: SolarCurve
    let inset: CGFloat

    func yPosition(of height: Double, in rect: CGRect) -> CGFloat {
        let usable = rect.height - 2 * inset
        return rect.maxY - inset - CGFloat((height + 1) / 2) * usable
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 96
        for i in 0...steps {
            let fraction = Double(i) / Double(steps)
            let point = CGPoint(
                x: rect.minX + CGFloat(fraction) * rect.width,
                y: yPosition(of: curve.height(at: fraction), in: rect)
            )
            i == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        return path
    }
}

// MARK: - Stars

/// A field of faint, slowly twinkling stars, faded in over the night prayers.
///
/// Positions are derived from a fixed seed rather than `Math.random`, so the sky doesn't reshuffle itself on
/// every re-render - and the same star keeps the same twinkle phase across state changes.
private struct StarFieldView: View {
    @Environment(\.appearance) private var appearance

    let opacity: Double
    /// True while the card is off screen (another tab is selected): TabView keeps the card alive,
    /// and the 6 fps twinkle used to keep drawing invisibly all night.
    let paused: Bool

    private struct Star {
        let x, y, radius, phase, brightness: Double
    }

    private static let stars: [Star] = {
        // A tiny linear congruential generator: deterministic, and no dependency on the Foundation RNG.
        var seed: UInt64 = 0x5EED_1517
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((seed >> 33) & 0xFFFF) / Double(0xFFFF)
        }
        return (0..<44).map { _ in
            Star(
                x: next(),
                // Bias toward the top: the lower half of the card is below the horizon.
                y: next() * 0.62,
                radius: 0.6 + next() * 1.1,
                phase: next(),
                brightness: 0.35 + next() * 0.55
            )
        }
    }()

    var body: some View {
        GeometryReader { geo in
            // Paused when invisible - and in Low Power Mode, where a 6fps twinkle is pure battery.
            TimelineView(.animation(minimumInterval: 1.0 / 6.0,
                                    paused: opacity <= 0.01 || paused || appearance.reduceAnimations)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for star in Self.stars {
                        // Each star twinkles on its own cycle, offset by its phase.
                        let twinkle = 0.55 + 0.45 * sin(2 * .pi * (t / 4.0 + star.phase))
                        let alpha = star.brightness * twinkle * opacity
                        let rect = CGRect(
                            x: star.x * size.width - star.radius,
                            y: star.y * size.height - star.radius,
                            width: star.radius * 2,
                            height: star.radius * 2
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Sky view

/// The Adhan tab's one card: the sun on today's arc, the moon at its true phase, the current and upcoming
/// prayers, and the countdown. Drag the sun to scrub the day - the gradient, the clock and the prayer list
/// below all follow.
///
/// This is the clock; `SkyCard` is the drawing. One minute-granularity tick (five minutes on the
/// reduced tier) re-evaluates the card through `TimelineView`. It used to be a 1 s `Timer.publish`
/// held in a struct `let` (recreated on every init, never disconnected, 60 inits a second during a
/// sun drag) that re-rendered the whole card every second to move the sun 0.004 pt. The card observes
/// Settings, the scrubber and the adhan player itself, so a drag or a prayer boundary still lands at
/// once; the clock only has to cover the sun's creep and the moon's hour.
struct SkyView: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.scenePhase) private var scenePhase

    @State private var isOnScreen = false
    /// Restarting the schedule from now on appear and on activation snaps the clock forward after
    /// the card was hidden or the app sat in the background.
    @State private var clockAnchor = Date()

    /// Horizontal row inset, measured off the sections around this card rather than assumed. A grouped row
    /// already carries the list's own 20pt margin, so the card adds nothing; a plain row carries none, and
    /// its neighbours (the location pill, the prayer tiles) sit at 19.33pt. On the wrapper, not the card:
    /// a list trait set inside `TimelineView`'s content would not reach the row.
    private var sideInset: CGFloat { appearance.defaultView ? 0 : 19.33 }

    var body: some View {
        let _ = RenderCounter.hit("SkyView")
        let interval: TimeInterval = appearance.isReducedTier ? 300 : 60
        TimelineView(.periodic(from: clockAnchor, by: interval)) { context in
            SkyCard(now: Self.quantizedToMinute(context.date), isOnScreen: isOnScreen)
        }
        // The two list themes give a row different built-in margins, so the card has to make up the
        // difference itself. Grouped rows already carry the list's 20pt margin - adding any more is what
        // made this card sit inset from every other section. Plain rows carry almost none, so without this
        // the card bleeds out past the sections above and below it.
        .listRowInsets(EdgeInsets(top: 6, leading: sideInset, bottom: 6, trailing: sideInset))
        .onAppear {
            isOnScreen = true
            clockAnchor = Date()
        }
        .onDisappear { isOnScreen = false }
        .onChange(of: scenePhase) { phase in
            if phase == .active { clockAnchor = Date() }
        }
    }

    /// The sun moves 0.24 pt a minute (sub-pixel), so a minute is all the resolution the card can show.
    private static func quantizedToMinute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }
}

/// The sky card's drawing, for one moment `now`. See `SkyView`.
struct SkyCard: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var scrubber = DayScrubber.shared
    // Publishes only when the picked DAY changes, so following it costs one re-render per date change.
    @ObservedObject private var selectedDay = SelectedDayPreview.shared
    @ObservedObject private var adhanPlayer = ForegroundAdhanPlayer.shared
    @Environment(\.layoutDirection) private var layoutDirection

    /// The live moment, quantized to the minute by `SkyView`.
    let now: Date
    /// False while another tab is selected; pauses the starfield.
    let isOnScreen: Bool

    /// Holds the prayer columns, the arc, the moon and the countdown. Trimmed again: the scrubbed-moment
    /// readout used to need clear air above the moon row to float into, which left a dead band between the arc
    /// and the moon. It now floats over the prayer columns at the top of the card instead (see `scrubReadout`),
    /// so that band can go.
    private let height: CGFloat = 212

    /// Vertical padding on the arc, keeping its peak and trough clear of the text bands above and below.
    /// Scaled down with the card so the curve keeps the same shape in less height.
    private let inset: CGFloat = 78

    // MARK: Derived state

    private var fallbackDayStart: Date { Calendar.current.startOfDay(for: now) }

    /// Not always 86,400 - DST transitions make a 23- or 25-hour day, and the arc must still span it.
    private var fallbackDayLength: TimeInterval {
        let calendar = Calendar.current
        guard let next = calendar.date(byAdding: .day, value: 1, to: fallbackDayStart) else { return 86_400 }
        return calendar.startOfDay(for: next).timeIntervalSince(fallbackDayStart)
    }

    /// Always the full six, because the arc needs a real Shurooq and Maghrib to place the horizon.
    private var todaysPrayers: [Prayer] {
        settings.getPrayerTimes(for: now, fullPrayers: true) ?? []
    }

    /// What the *list* is showing - traveling mode combines prayers, and `PrayerList` matches the highlight by
    /// name. Feeding the scrubber the full six would look up "Dhuhr" while the row says "Dhuhr/Asr", and the
    /// highlight would silently vanish for anyone in traveling mode.
    private var highlightTimeline: [Prayer] {
        let displayed = settings.prayers?.prayers ?? todaysPrayers
        return settings.prayersIncludingOptional(displayed, for: now)
    }

    /// The mandatory prayers marked as dots on the arc: always the FULL five (Jumuah on Friday), never the
    /// traveling combined pairs - the arc describes the day's real structure, and a traveler still wants to
    /// see where Asr and Isha fall even while the list shows "Dhuhr/Asr" (user rule). Nothing optional.
    private var dotPrayers: [Prayer] {
        todaysPrayers.filter { Settings.adhanEligiblePrayerNames.contains($0.nameTransliteration) }
    }

    /// The moment the whole card is describing: the dragged one, or now.
    private var displayedDate: Date { scrubber.scrubbedDate ?? now }

    private var displayedPrayer: Prayer? {
        scrubber.previewPrayer ?? settings.currentPrayer
    }

    /// The TRUE prayer period at `date`, resolved against the FULL prayer set - never the traveling
    /// combined pairs. This keys the sky's gradient and stars: past Isha the sky must wear Isha's colors
    /// and at Asr time Asr's, even while the list (and `displayedPrayer`'s name) says "Maghrib/Isha" or
    /// "Dhuhr/Asr" (user rule). Before today's Fajr the previous night's period still holds.
    private func colorPeriodName(at date: Date) -> String? {
        let today = settings.prayersIncludingOptional(todaysPrayers, for: now)
        if let current = today.last(where: { $0.time <= date }) { return current.nameTransliteration }
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
           let previous = settings.getPrayerTimes(for: yesterday, fullPrayers: true) {
            return settings.prayersIncludingOptional(previous, for: yesterday)
                .last(where: { $0.time <= date })?
                .nameTransliteration
        }
        return nil
    }

    /// Stars come out at night. Full through Isha and the late-night times, fading in over Maghrib and back
    /// out through Fajr, and gone once the sun is up - which also pauses the twinkle animation.
    /// Keyed on the true (full-set) period, so the stars agree with the gradient while traveling.
    private var starOpacity: Double {
        switch colorPeriodName(at: displayedDate) {
        case "Isha", "Islamic Midnight", "Last Third": return 1
        case "Fajr":                                   return 0.5
        case "Maghrib":                                return 0.3
        default:                                       return 0
        }
    }

    // MARK: Body

    var body: some View {
        let _ = RenderCounter.hit("SkyCard")
        // ONE prayer-time resolution per render. `sunrise`/`sunset`/`window`/`curve` used to be computed
        // properties re-derived at every use site (the arc shape, the horizon line, the sun's height,
        // color and fraction) - ~20-30 cached `getPrayerTimes` lookups per second while the clock ticks.
        // The solar geometry is built once here and passed down.
        let prayers = todaysPrayers
        let sunrise = prayers.first { $0.nameTransliteration == "Shurooq" }?.time
        let sunset = prayers.first { $0.nameTransliteration == "Maghrib" }?.time
        let window = SolarWindow(
            sunrise: sunrise,
            sunset: sunset,
            fallbackDayStart: fallbackDayStart,
            fallbackDayLength: fallbackDayLength
        )
        let curve = SolarCurve(
            sunriseFractionOfWindow: sunrise.map(window.fraction(of:)),
            sunsetFractionOfWindow: sunset.map(window.fraction(of:))
        )

        let skyPeriod = colorPeriodName(at: displayedDate)

        ZStack {
            LinearGradient(
                colors: settings.skyGradientColors(forPrayer: skyPeriod),
                startPoint: .top,
                endPoint: .bottom
            )
            // Re-tint both when the period changes and when the user edits that prayer's colors.
            .animation(.easeInOut(duration: 0.4), value: skyPeriod)
            .animation(.easeInOut(duration: 0.25), value: settings.skyGradientsJSON)

            StarFieldView(opacity: starOpacity, paused: !isOnScreen)
                .animation(.easeInOut(duration: 0.6), value: starOpacity)

            arc(curve: curve, window: window)

            // Legibility scrim, weighted to the two text bands. A soft gradient rather than a hard seam: it
            // reads as dusk gathering at the horizon, and it keeps white text readable over whichever two
            // colors the user picked - a pale midday cyan included.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.32), location: 0.00),
                    .init(color: .black.opacity(0.00), location: 0.26),
                    .init(color: .black.opacity(0.00), location: 0.48),
                    .init(color: .black.opacity(0.66), location: 1.00),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            content
        }
        .overlay(alignment: .top) { scrubReadout }
        .animation(.easeInOut(duration: 0.15), value: scrubber.isScrubbing)
        .frame(height: height)
        // Everything inside draws light-on-dark, whatever the phone's appearance.
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }

    /// Everything drawn over the sky: the two prayer columns, the moon and clock, and the countdown.
    private var content: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                SkyPrayerColumn(
                    title: "CURRENT",
                    displayName: settings.currentPrayer?.displayName,
                    image: settings.currentPrayer?.image,
                    timeText: settings.currentPrayer.map { settings.formatDate($0.time) },
                    trailing: false
                )
                .equatable()
                Spacer(minLength: 0)
                SkyPrayerColumn(
                    title: "UPCOMING",
                    displayName: settings.nextPrayer?.displayName,
                    image: settings.nextPrayer?.image,
                    timeText: settings.nextPrayer.map { settings.formatDate($0.time) },
                    trailing: true
                )
                .equatable()
            }

            Spacer(minLength: 0)

            // Lifted off the countdown so the moon reads as part of the sky rather than as a caption on the
            // progress bar. The `Spacer` above absorbs it, so the card doesn't grow.
            moonAndClock
                .padding(.bottom, 10)

            if settings.prayers != nil {
                // Equatable-gated: the countdown's real updates come from its own timer state and its own
                // Settings observation, so this card's per-second re-render has nothing new to tell it.
                PrayerCountdown(presentation: .skyFooter)
                    .equatable()
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // Only the stop button is interactive; the rest is decoration over the drag area.
        .allowsHitTesting(adhanPlayer.isPlaying)
    }

    /// One side of the header: the label, the prayer's symbol and name, and when it started or starts.
    /// No Arabic or English subtitle - the prayer list below carries those.
    ///
    /// An Equatable leaf rather than a computed section of `SkyCard`: the card re-runs its body every
    /// minute to move the sun, but a column's strings change only when the prayer rolls over (or the
    /// user edits the time format - which flows through `timeText`, so `==` catches it). Comparing five
    /// values lets SwiftUI skip both columns' subtrees on every tick in between. All inputs are plain
    /// values formatted by the parent - the column itself observes nothing.
    private struct SkyPrayerColumn: View, Equatable {
        let title: String
        let displayName: String?
        let image: String?
        let timeText: String?
        let trailing: Bool

        var body: some View {
            VStack(alignment: trailing ? .trailing : .leading, spacing: 3) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))

                if let displayName, let image, let timeText {
                    HStack(spacing: 6) {
                        if trailing { Text(displayName).font(.title3.weight(.semibold)) }
                        Image(systemName: image)
                        if !trailing { Text(displayName).font(.title3.weight(.semibold)) }
                    }
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                    Text("\(trailing ? "Starts at" : "Started at") \(timeText)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    /// Bottom-centre: the moment being shown and the moon's phase. While dragging, the previewed prayer's name
    /// joins them - the columns above always report the *live* prayer, so the scrub would otherwise be mute.
    @ViewBuilder
    private var moonAndClock: some View {
        if let playingPrayerName = adhanPlayer.playingPrayerName {
            adhanStopButton(prayerName: playingPrayerName)
        } else {
            // Only the moon and its phase live in the layout - the clock is *not* shown at rest (it just added
            // height for something the status bar already says). While the sun is being scrubbed, the previewed
            // moment floats in as an overlay ABOVE, so the card's height never changes.
            // While the sun is being scrubbed the moon follows the drag; otherwise, when the prayer list
            // is browsing another day, it previews THAT night's phase. Only the moon follows the picked
            // day - the sun, gradient and countdown describe the live moment.
            // Quantized to the hour: the moon's look doesn't change measurably within one, and a stable
            // date lets SwiftUI diff MoonPhaseView out (instead of re-running the ephemeris trig twice
            // per second while the card ticks).
            let moonReference = scrubber.scrubbedDate ?? selectedDay.date ?? now
            let moonDate = Date(timeIntervalSinceReferenceDate:
                (moonReference.timeIntervalSinceReferenceDate / 3600).rounded(.down) * 3600)
            let moonPhase = MoonPhase.on(moonDate)
            HStack(spacing: 6) {
                MoonPhaseView(date: moonDate, diameter: 20)

                Text(moonPhase.name)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))

                // How lit it actually is, which is the one thing the phase NAME can't tell you -
                // "Waxing Crescent" spans everything from a fingernail to nearly half. Smaller and
                // dimmer than the name so it reads as the footnote it is. The glyph beside it is
                // drawn from this same number, so the row now says in words what it already draws.
                Text("\(moonPhase.illuminationPercent)% lit")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
        }
    }

    /// The moment (and prayer) being previewed while the sun is dragged. It rides at the TOP of the card, over
    /// the two prayer columns - they report the *live* prayer, so a scrub would otherwise be mute - rather than
    /// above the moon, which forced the card to hold empty space for it at all times.
    @ViewBuilder
    private var scrubReadout: some View {
        if scrubber.isScrubbing {
            HStack(spacing: 6) {
                if let name = displayedPrayer?.displayName {
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                }

                Text(settings.formatDate(displayedDate))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white)
            }
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .padding(.top, 4)
            .transition(.opacity)
        }
    }




    private func arc(curve: SolarCurve, window: SolarWindow) -> some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let displayedFraction = window.fraction(of: displayedDate)
            let shape = SolarArcShape(curve: curve, inset: inset)
            let horizonY = shape.yPosition(of: curve.horizon, in: rect)
            let sunHeight = curve.height(at: displayedFraction)
            let sunPoint = CGPoint(
                x: xPosition(forFraction: displayedFraction, in: rect),
                y: shape.yPosition(of: sunHeight, in: rect)
            )
            let isUp = curve.isDaylight(at: displayedFraction)

            ZStack {
                shape
                    .stroke(
                        Color.white.opacity(0.30),
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 5])
                    )

                // Edge to edge, like the arc it belongs to. Inset by 12 on each side it read as a shorter,
                // unrelated line floating inside a wider graph.
                Path { path in
                    path.move(to: CGPoint(x: rect.minX, y: horizonY))
                    path.addLine(to: CGPoint(x: rect.maxX, y: horizonY))
                }
                .stroke(Color.white.opacity(0.45), lineWidth: 1)

                // A dot on the arc for each mandatory prayer (Jumuah and the traveling combined pairs
                // included), so the day's structure is readable off the curve itself - and scrubbing to a
                // dot lines the sun up with that prayer's start.
                ForEach(dotPrayers, id: \.nameTransliteration) { prayer in
                    let fraction = window.fraction(of: prayer.time)
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 5, height: 5)
                        .position(CGPoint(
                            x: xPosition(forFraction: fraction, in: rect),
                            y: shape.yPosition(of: curve.height(at: fraction), in: rect)
                        ))
                }

                // A drop-line to the horizon while dragging, so the sun's height reads as a position.
                if scrubber.isScrubbing {
                    Path { path in
                        path.move(to: sunPoint)
                        path.addLine(to: CGPoint(x: sunPoint.x, y: horizonY))
                    }
                    .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }

                let sunFill = sunColor(height: sunHeight, horizon: curve.horizon)
                Circle()
                    .fill(sunFill)
                    .frame(width: 20, height: 20)
                    .softShadow(color: sunFill.opacity(isUp ? 0.9 : 0), radius: isUp ? 12 : 0)
                    .position(sunPoint)
                    .opacity(isUp ? 1 : 0.45)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(in: rect, window: window))
        }
    }

    /// Shown only while the adhan is actually sounding in-app. The full recording runs for minutes, so there
    /// has to be a way to stop it without force-quitting.
    private func adhanStopButton(prayerName: String) -> some View {
        Button {
            settings.hapticFeedback()
            adhanPlayer.stopAdhan()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill")
                Text("\(prayerName) adhan · Tap to stop")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: Interaction

    private func dragGesture(in rect: CGRect, window: SolarWindow) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !scrubber.isScrubbing {
                    settings.hapticFeedback()
                    scrubber.begin(timeline: highlightTimeline)
                }
                let fraction = fractionOf(x: value.location.x, in: rect)
                scrubber.scrub(to: window.date(atFraction: fraction))
            }
            .onEnded { _ in
                scrubber.end()
            }
    }

    private func fractionOf(x: CGFloat, in rect: CGRect) -> Double {
        guard rect.width > 0 else { return 0 }
        let raw = Double(x / rect.width)
        let directed = layoutDirection == .rightToLeft ? 1 - raw : raw
        return min(max(directed, 0), 1)
    }

    private func xPosition(forFraction fraction: Double, in rect: CGRect) -> CGFloat {
        let directed = layoutDirection == .rightToLeft ? 1 - fraction : fraction
        return rect.minX + CGFloat(directed) * rect.width
    }

    /// Warm and huge near the horizon, small and white overhead, dim below.
    private func sunColor(height: Double, horizon: Double) -> Color {
        guard height > horizon else { return Color(white: 0.75) }
        // 0 at the horizon, 1 at solar noon.
        let elevation = (height - horizon) / max(1 - horizon, 0.0001)
        return Color(
            red: 1.0,
            green: 0.62 + 0.30 * elevation,
            blue: 0.25 + 0.60 * elevation
        )
    }
}
#endif
