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

    /// How much of the marker on the arc is the sun rather than the moon, 0...1: a smoothed version of
    /// `isDaylight` used by whatever has to CHANGE across the horizon (the sun's glow, the moon's
    /// opacity). `isDaylight` stays a hard boolean for anything that only needs to know which side of
    /// the line it is on.
    ///
    /// Ramped on the sun's HEIGHT, not on the fraction of the day: height is what positions the marker,
    /// so tying the fade to it makes the crossing exactly as smooth as the drag that causes it, at any
    /// latitude or season (near the poles a band measured in fractions-of-a-day would be a band of
    /// hours). The band is a fixed slice of the curve's amplitude, which is always 2 (-1...1), so
    /// `bandHalfHeight` means the same thing everywhere.
    func daylightPresence(at fraction: Double) -> Double {
        let bandHalfHeight = 0.06
        let above = height(at: fraction) - horizon
        let t = (above + bandHalfHeight) / (2 * bandHalfHeight)
        let clamped = min(max(t, 0), 1)
        // Smoothstep, so the fade eases in and out of the band rather than starting and stopping
        // abruptly at its edges (which would just move the visible kink instead of removing it).
        return clamped * clamped * (3 - 2 * clamped)
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

/// Where the skyline's ground runs (see `SolarArcShape.ground`): the horizon's y, and how far under
/// it the night's path dips.
struct SkyGround {
    let y: CGFloat
    let depth: CGFloat
}

/// The dashed sun path. Drawn as a polyline of the normalized curve, mapped into the band between
/// `topInset` and `bottomInset` so the peak and trough land where the card wants them (see
/// `SkyCard.arcTopInset` for how that band is chosen). With a `ground` the mapping is pinned instead:
/// the horizon crossing sits on the ground's y whatever the season, the day's arc rises from there to
/// the peak at `topInset`, and the night's path dips `depth` under the ground (as far as the day rises,
/// so the line is a full wave: "a real solar graph going all the way down and up"). The seasons then
/// show in how wide the day's arc is (where sunrise and sunset fall), not in how the line rides the band.
private struct SolarArcShape: Shape {
    let curve: SolarCurve
    let topInset: CGFloat
    let bottomInset: CGFloat
    var ground: SkyGround? = nil

    func yPosition(of height: Double, in rect: CGRect) -> CGFloat {
        if let ground {
            let horizon = curve.horizon
            if height >= horizon {
                // 0 at the horizon, 1 at the peak.
                let up = (height - horizon) / max(1 - horizon, 0.0001)
                return ground.y - CGFloat(up) * (ground.y - (rect.minY + topInset))
            }
            // 0 at the horizon, 1 at the trough.
            let down = (horizon - height) / max(horizon + 1, 0.0001)
            return ground.y + CGFloat(down) * ground.depth
        }
        let usable = rect.height - topInset - bottomInset
        return rect.maxY - bottomInset - CGFloat((height + 1) / 2) * usable
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

    // The field itself (positions, twinkle, the night fade) lives in `SkyStars`, which the widgets draw
    // from too - the home screen's sky and this one are the same sky, down to where each star sits.

    var body: some View {
        GeometryReader { geo in
            // Paused when invisible - and in Low Power Mode, where a 6fps twinkle is pure battery.
            TimelineView(.animation(minimumInterval: 1.0 / 6.0,
                                    paused: opacity <= 0.01 || paused || appearance.reduceAnimations)) { timeline in
                Canvas { context, size in
                    SkyStars.draw(in: &context,
                                  size: size,
                                  time: timeline.date.timeIntervalSinceReferenceDate,
                                  opacity: opacity)
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
        let _ = ChangePrinter.hit(Self.self)
        let interval: TimeInterval = appearance.isReducedTier ? 300 : 60
        TimelineView(.periodic(from: clockAnchor, by: interval)) { context in
            SkyCard(now: Self.effectiveNow(context.date), isOnScreen: isOnScreen)
        }
        // The two list themes give a row different built-in margins, so the card has to make up the
        // difference itself. Grouped rows already carry the list's 20pt margin - adding any more is what
        // made this card sit inset from every other section. Plain rows carry almost none, so without this
        // the card bleeds out past the sections above and below it.
        .listRowInsets(EdgeInsets(top: 6, leading: sideInset, bottom: 6, trailing: sideInset))
        .onAppear {
            isOnScreen = true
            clockAnchor = Date()
            #if DEBUG
            // `-fakeAdhanPlaying <name>`: the footer opens on the stop button, so its cross-fade back
            // to the moon line can be verified headlessly (see `ForegroundAdhanPlayer.debugSetPlaying`).
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "-fakeAdhanPlaying"), args.indices.contains(index + 1) {
                ForegroundAdhanPlayer.shared.debugSetPlaying(args[index + 1])
            }
            #endif
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

    private static func effectiveNow(_ date: Date) -> Date {
        #if DEBUG
        if let debugNow { return debugNow }
        #endif
        return quantizedToMinute(date)
    }

    #if DEBUG
    /// "-skyNow HH:mm": the card drawn as if it were that time today (a day scene at night, the moon
    /// at noon), for screenshot runs. The prayer columns and the countdown keep the live clock; the
    /// widget gallery's entry takes the same moment.
    static let debugNow: Date? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-skyNow"), arguments.indices.contains(index + 1) else { return nil }
        let parts = arguments[index + 1].split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date())
    }()
    #endif
}

/// The sky card's drawing, for one moment `now`. See `SkyView`.
struct SkyCard: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var settings = Settings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared
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
    /// so that band can go. Trimmed twice on 2026-09-07: first the digits went 30 -> 26 pt (236 -> 224),
    /// then Abu measured the air still left above "TIME LEFT" and it went 224 -> 200. See `arcTopInset`
    /// for why the card's height is the lever that closes that gap.
    private let height: CGFloat = 200

    /// The coordinate space `PrayerCountdown` measures its digits in (see `SkyDigitsTopKey`).
    static let groundSpace = "SkyCard.ground"

    /// The arc's vertical band, as insets from the card's top and bottom edges. The card is three bands: the
    /// prayer columns end about 69 pt down, the countdown block is bottom-anchored (a flexible `Spacer`
    /// above it), and the arc lives in between: peak at 68, trough at `height - arcBottomInset`.
    ///
    /// The horizon LINE is not at the trough - it is derived from the day's length (`SolarCurve.horizon`)
    /// and rides up and down the band with the season, which is what makes the air above "TIME LEFT"
    /// vary. With the countdown block occupying about 91 pt of the card's bottom, the gap between the
    /// line and the caption works out to `arcBottomInset + f * band - 91`, where f runs from 0.75 on an
    /// 8-hour winter day to 0.25 on a 16-hour summer one. So the two ways to close that gap are a
    /// shorter card (the block rises) and a shallower band (the line stops swinging so far), and both
    /// were used on 2026-09-07: 224 -> 200 and 62 -> 44 took a measured 31.5 pt gap down to about 16.
    /// A negative padding cannot do this: the flexible spacer above simply absorbs it.
    ///
    /// `arcBottomInset` also sets the floor - the gap at f = 0 is `arcBottomInset - 91` - so it must not
    /// drop much below 88 or the line grazes the caption at Arctic midsummer. Re-derive all three numbers
    /// whenever the columns or the countdown block change height.
    ///
    /// All of that is the PLAIN card's geometry (skyline off). With the skyline on the horizon is the
    /// ground the pyramids and the mosque stand on, and it is pinned just ABOVE the whole countdown
    /// block - "TIME LEFT" and the digits together (`digitsTop`, measured through `SkyDigitsTopKey`):
    /// the sun rises out of the pyramids and sets behind the mosque, the day's arc always peaks at
    /// `arcTopInset`, and the night's path dips as far under the ground as the day rises above it,
    /// behind the caption, the digits and the bar (Abu, 2026-09-16: first "at the countdown", then,
    /// when that pinned the night to a shallow dip, "a real solar graph going all the way down and
    /// up", then "in between Time Left and the countdown"; 2026-09-18: the line went above the text
    /// and the countdown entirely, so nothing is struck through by the horizon).
    private let arcTopInset: CGFloat = 68
    private let arcBottomInset: CGFloat = 88

    /// The top of the countdown BLOCK ("TIME LEFT" and the digits under it) in the card's coordinate
    /// space, as `PrayerCountdown` reports it; nil until the first layout. The estimate stands in for
    /// that first frame so the ground does not jump: 200 less the bottom padding, the footer line, its
    /// top padding, the bar, the digits, and the caption above them.
    @State private var digitsTop: CGFloat?
    private static let estimatedDigitsTop: CGFloat = 108
    /// The ground line sits this far above the countdown block, in the air over "TIME LEFT".
    private static let groundAir: CGFloat = 4
    /// The night's trough never dips closer than this to the card's bottom edge.
    private static let troughInset: CGFloat = 8

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
        let displayed = live.prayers?.prayers ?? todaysPrayers
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
        scrubber.previewPrayer ?? live.currentPrayer
    }

    // The period this card's sky is painted from - the TRUE, full-set one, never the traveling combined
    // pairs - is `Settings.skyPeriodName(at:)`, shared with the widgets so both skies turn at the same
    // instant. The stars' night fade (`SkyStars.opacity`) is keyed on the same answer. Both are resolved
    // ONCE in `body` and passed down: this card re-renders every second while the clock ticks, and the
    // gradient and the star field used to ask the question separately.

    // MARK: Body

    var body: some View {
        let _ = RenderCounter.hit("SkyCard")
        let _ = ChangePrinter.hit(Self.self)
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

        let skyPeriod = settings.skyPeriodName(at: displayedDate)
        let starOpacity = SkyStars.opacity(forPeriod: skyPeriod)
        let skyColors = settings.skyGradientColors(forPrayer: skyPeriod)

        ZStack {
            LinearGradient(
                colors: skyColors,
                startPoint: .top,
                endPoint: .bottom
            )
            // Re-tint both when the period changes and when the user edits that prayer's colors. The
            // period's change takes a leisurely second so the first paint, and the turn at each prayer,
            // ease between the two gradients instead of snapping (Abu, 2026-09-16: "smoother").
            //
            // But a full second is wrong WHILE DRAGGING (Abu, 2026-09-19): a scrub crosses several
            // prayer boundaries in a second, so each crossing started a 1s retint that the next one
            // interrupted, and the gradient lagged visibly behind the thumb. During a scrub the retint
            // is quick enough to keep up with the finger; released, it goes back to the leisurely turn.
            .animation(.easeInOut(duration: scrubber.isScrubbing ? 0.2 : 1.0), value: skyPeriod)
            .animation(.easeInOut(duration: 0.25), value: settings.skyGradientsJSON)

            StarFieldView(opacity: starOpacity, paused: !isOnScreen)
                .animation(.easeInOut(duration: 0.6), value: starOpacity)

            arc(curve: curve, window: window, skyColors: skyColors)

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
        .coordinateSpace(name: Self.groundSpace)
        .onPreferenceChange(SkyDigitsTopKey.self) { top in
            if top != digitsTop { digitsTop = top }
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
                    displayName: live.currentPrayer?.displayName,
                    image: live.currentPrayer?.image,
                    timeText: live.currentPrayer.map { settings.formatDate($0.time) },
                    trailing: false
                )
                .equatable()
                Spacer(minLength: 0)
                SkyPrayerColumn(
                    title: "UPCOMING",
                    displayName: live.nextPrayer?.displayName,
                    image: live.nextPrayer?.image,
                    timeText: live.nextPrayer.map { settings.formatDate($0.time) },
                    trailing: true
                )
                .equatable()
            }

            Spacer(minLength: 0)

            if live.prayers != nil {
                // Equatable-gated: the countdown's real updates come from its own timer state and its own
                // Settings observation, so this card's per-minute re-render has nothing new to tell it.
                // Big and centred over the bar (Abu, 2026-09-04): the card's centrepiece.
                PrayerCountdown(presentation: .skyFooter)
                    .equatable()
            }

            // The moon on the left, the prayer the countdown runs to on the right; the adhan's stop
            // button takes the whole line while it sounds.
            footer
                .padding(.top, 8)
                // The stop button slides up and fades in as the adhan starts and out as it stops; the
                // `if` swap alone cut straight between the two (Abu, 2026-09-16).
                .animation(.easeInOut(duration: 0.35), value: adhanPlayer.playingPrayerName)
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

    /// The card's last line: the moon's phase, and which prayer the countdown runs to. While the adhan
    /// sounds in-app the stop button replaces both.
    ///
    /// BOTH branches carry a transition, and they are deliberately opposite `move` edges so the two
    /// lines cross-fade as one line changing rather than as two things swapping. Only the stop button
    /// had one before (2026-09-16), which is why stopping the adhan looked like the button simply
    /// vanishing (Abu, 2026-09-18): an `if`/`else` swaps both branches in the SAME transaction, so
    /// the un-transitioned moon row snapped in at full opacity on top of the button's fade and hid
    /// it completely. A transition on one side of a swap is never enough.
    @ViewBuilder
    private var footer: some View {
        if let playingPrayerName = adhanPlayer.playingPrayerName {
            adhanStopButton(prayerName: playingPrayerName)
                .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 6) {
                moonRow

                Spacer(minLength: 8)

                if let next = live.nextPrayer {
                    Text(PrayerCountdown.untilLabel(for: next))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    /// The moon and its phase. While the sun is being scrubbed the moon follows the drag; otherwise, when
    /// the prayer list is browsing another day, it previews THAT night's phase.
    @ViewBuilder
    private var moonRow: some View {
            // Only the moon and its phase live in the layout - the clock is *not* shown at rest (it just added
            // height for something the status bar already says). While the sun is being scrubbed, the previewed
            // moment floats in as an overlay ABOVE, so the card's height never changes.
            // While the sun is being scrubbed the moon follows the drag; otherwise, when the prayer list
            // is browsing another day, it previews THAT night's phase. Only the moon follows the picked
            // day - the sun, gradient and countdown describe the live moment.
            // Quantized to the hour: the moon's look doesn't change measurably within one, and a stable
            // date lets SwiftUI diff MoonPhaseView out (instead of re-running the ephemeris trig twice
            // per second while the card ticks).
            let moonDate = self.moonDate
            let moonPhase = MoonPhase.on(moonDate)
            HStack(spacing: 6) {
                MoonPhaseView(date: moonDate, diameter: 18)

                // The name and, after a dot, how lit it actually is - the one thing the phase NAME
                // can't tell you ("Waxing Crescent" spans a fingernail to nearly half). The glyph
                // beside it is drawn from this same number.
                Text("\(moonPhase.name) · \(moonPhase.illuminationPercent)%")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            }
    }

    /// The moment the moon is drawn for (the footer's glyph and, at night, the one on the arc): the
    /// dragged moment, else the browsed day, else now, quantized to the hour (see `moonRow`).
    private var moonDate: Date {
        let reference = scrubber.scrubbedDate ?? selectedDay.date ?? now
        return Date(timeIntervalSinceReferenceDate: (reference.timeIntervalSinceReferenceDate / 3600).rounded(.down) * 3600)
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




    private func arc(curve: SolarCurve, window: SolarWindow, skyColors: [Color]) -> some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let displayedFraction = window.fraction(of: displayedDate)
            let showsScene = settings.showSkyScene
            // The skyline pins the ground just above the countdown block - over "TIME LEFT" and the
            // digits both (see `arcTopInset`) - and the night dips as deep as the day climbs, short
            // of the card's bottom edge.
            let groundY = (digitsTop ?? Self.estimatedDigitsTop) - Self.groundAir
            let ground = showsScene
                ? SkyGround(y: groundY,
                            depth: min(groundY - (rect.minY + arcTopInset), rect.maxY - Self.troughInset - groundY))
                : nil
            let shape = SolarArcShape(curve: curve, topInset: arcTopInset, bottomInset: arcBottomInset, ground: ground)
            let horizonY = shape.yPosition(of: curve.horizon, in: rect)
            let sunHeight = curve.height(at: displayedFraction)
            let sunPoint = CGPoint(
                x: xPosition(forFraction: displayedFraction, in: rect),
                y: shape.yPosition(of: sunHeight, in: rect)
            )
            // How much of the marker is the SUN rather than the moon, 0...1, ramped across a thin band
            // either side of the horizon instead of flipped by `isUp` (Abu, 2026-09-19: dragging the sun
            // down into the night was not smooth). A boolean made the crossing a one-frame event - the
            // sun's glow went radius 12 -> 0 and the moon materialised - and no `.animation` can rescue
            // that, because a drag writes `scrubbedDate` ~60x/second and each write is its own
            // transaction fighting the last. Ramping on the sun's HEIGHT instead means the swap is
            // carried by the same number that moves the marker, so it is as smooth as the drag is.
            let dayPresence = curve.daylightPresence(at: displayedFraction)

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

                // The sun, on its path day and night. With the skyline on it sets behind the ground
                // and rises out of it (only the sky above the horizon shows it), and it is drawn UNDER
                // the skyline so it sinks behind the mosque rather than in front of it; the plain card
                // keeps the dimmed underground sun it always had.
                let sunFill = sunColor(height: sunHeight, horizon: curve.horizon)
                let sun = Circle()
                    .fill(sunFill)
                    .frame(width: 20, height: 20)
                    // The glow fades with the ramp rather than being switched off at the horizon.
                    .softShadow(color: sunFill.opacity(0.9 * dayPresence), radius: 12 * dayPresence)
                    .position(sunPoint)
                if showsScene {
                    sun.mask(alignment: .top) {
                        Rectangle().frame(height: max(horizonY - rect.minY, 0))
                    }
                } else {
                    // 1 by day, 0.45 by night, interpolated - not a two-value switch.
                    sun.opacity(0.45 + 0.55 * dayPresence)
                }

                // The skyline along the ground (SkyScene.swift): the pyramids under CURRENT and the
                // mosque under UPCOMING, in silhouette on the ground the line draws, dark over a day
                // sky and pale over the night's. Over the sun and the stars, under the dots.
                //
                // ONE layer, and an opaque one. It used to be two, a dark skyline and a pale one
                // crossfaded by opacity, because a Canvas cannot animate its colour and the flip
                // otherwise cut straight from black to white at Isha (Abu, 2026-09-16). That trick
                // needed both layers translucent, and a translucent silhouette is exactly what let the
                // solar arc show straight through the pyramids and the mosque (Abu, same day: "WE ARE
                // STILL CROSSING THE SOLAR GRAPH"), so `silhouette(day:overSky:)` now mixes the sky
                // INTO the fill and the shape is solid.
                //
                // The fade lives in the `SkylineSilhouette` MODIFIER, not in an `.animation` around a
                // Canvas: a Canvas redraws with whatever colour it is handed, so animating it directly
                // has nothing to interpolate and the tint snaps in one frame. The modifier's
                // `animatableData` carries `day` and the sky's three components, so every frame of the
                // turn resolves its own opaque colour, over the same second the gradient above takes.
                // It must be a ViewModifier: as a plain `View` conforming to `Animatable` the same
                // code compiles and is ignored (see `SkylineSilhouette`).
                if showsScene {
                    let location = horizonY / max(rect.height, 1)
                    let sky = SkyScene.skyComponents(of: skyColors, at: location)
                    // Keyed on the sky itself, which is the only thing the silhouette is derived
                    // from now. One modifier: stacking three `.animation`s would let them fight over
                    // the same transaction.
                    Color.clear
                        .skylineSilhouette(sky: sky, horizonY: horizonY)
                        // Matches the gradient's own duration, scrub included - the silhouette is mixed
                        // FROM the sky, so if the two turn at different speeds the mosque drifts out of
                        // step with the sky behind it.
                        .animation(.easeInOut(duration: scrubber.isScrubbing ? 0.2 : 1.0),
                                   value: [sky.red, sky.green, sky.blue])
                }

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

                // Through the night the moon, at its true phase, is the marker on the path: it rides
                // the night's dip of the wave exactly as the sun rides the day's, and follows a drag
                // the same way (Abu, 2026-09-16: on the graph, not parked at the top of the sky). It
                // is drawn OVER the skyline's ground band so it never fades into the ground.
                // Drawn whenever any of the night is showing (`dayPresence < 1`) and faded by the
                // ramp, so through the crossing the sun and the moon are briefly both on the path at
                // partial strength rather than one replacing the other between two frames.
                if showsScene, dayPresence < 1 {
                    // A full disc, not the night's true phase: here the moon is the MARKER, the
                    // counterpart of the sun on the day's half of the wave, and a 34% crescent reads
                    // as a sliver of a thing rather than as a position on the path. The footer's
                    // glyph is the one that shows the real phase, and it names it (Abu, 2026-09-16).
                    MoonPhaseView(date: moonDate, diameter: 20, alwaysFull: true)
                        .opacity(1 - dayPresence)
                        .position(sunPoint)
                }
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
