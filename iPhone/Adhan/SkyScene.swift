#if os(iOS)
import SwiftUI

// The skyline along the solar countdown's ground (2026-09-16): three pyramids to the west and a mosque
// with its dome and two minarets to the east, in silhouette on the ground the horizon line draws. In the
// app the ground runs between the countdown's "TIME LEFT" caption and its digits, so the whole skyline
// stands in the sky band between the prayer columns and the digits, the pyramids under CURRENT, the
// caption between them and the mosque under UPCOMING (see `SkyCard.arc`); the Solar Arc widgets draw the same paths on their own horizon,
// scaled to whatever room they have above it, so the two skylines match in shape. The sun rides the
// arc by day and sinks behind the ground at sunset; through the night a full moon takes its place on
// the path (the card and `SolarArcGraph` place it). The two structures are MIRROR IMAGES about the
// middle of the card: each spans `clusterSpan`, the mosque centred on `mosqueCentre` and the
// pyramids on its reflection, and each is a tall centre between two smaller outer
// masses - the great pyramid answering the dome, the two small ones answering the minarets, all at
// matching heights. Both keep clear of the middle, where the arc peaks and the countdown digits sit.
// The palms that once stood east of the mosque are gone. By day the silhouette is a DARKER shade of
// the sky behind it; under a night sky it is MOONLIT, paler than the sky, because a darker shade of
// Isha's navy is simply black (Abu, 2026-09-20). The turn between the two is a wash of light from the
// tops of the buildings down, never a flat crossfade: see `SkylineTint` and `tint(overSky:)`.

/// Which structures stand on the ground: the mosque and the pyramids as mirror images (the default),
/// or the same one on both sides. Stored raw in `Settings.skySceneStyle`, read back through
/// `Settings.skylineStyle` (which the widgets can also answer). "Off" is not a style: that is the
/// existing Skyline switch (`showSkyScene`), and the picker folds the two into one row.
enum SkySceneStyle: String, CaseIterable, Identifiable {
    case pyramidsMosque
    case pyramids
    case mosques

    static let storageKey = "skySceneStyle"
    static let defaultStyle: SkySceneStyle = .pyramidsMosque

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pyramidsMosque: return "Pyramids & Mosque"
        case .pyramids: return "Pyramids"
        case .mosques: return "Mosques"
        }
    }
}

enum SkyScene {
    /// The tallest point of the scene above the horizon at scale 1 (the mosque's crescent, the great
    /// pyramid's apex), in points. `draw` shrinks the scene when the room above the horizon is
    /// shorter than this.
    static let naturalHeight: CGFloat = 43

    /// Every height, multiplied by this before it is drawn (Abu, 2026-09-16: "just make them both a
    /// little smaller"; 2026-09-21: "a little smaller" again, 0.85 -> 0.75). Width shrinks with it
    /// through `clusterSpan`, by the same factor, so the two structures keep their proportions and
    /// stay each other's mirror.
    private static let heightFactor: CGFloat = 0.75

    /// How much of the card's width each of the two structures covers: the 0.30 the shapes were
    /// drawn against, shrunk with `heightFactor`. They are mirror images about the middle, each
    /// spanning this. Both `drawPyramids` and `drawMosque` derive their positions from this and
    /// `edgeInset`, so the sides cannot drift apart the way they did when each carried its own
    /// hand-written numbers.
    private static let clusterSpan: CGFloat = 0.30 * heightFactor

    /// Where the skyline's OUTERMOST ink sits, in points from the card's edges: the pyramids' first
    /// foot on the left, the mosque's far minaret ring on the right. 16, the same as the card's
    /// content padding, so the skyline starts exactly where "CURRENT" starts and ends exactly where
    /// "UPCOMING" ends (Abu, 2026-09-21: "put the ends the same place as where the text starts").
    /// The centres used to be fractions (mosque 0.828) that only happened to land near 16 pt at the
    /// card's width; pinning the edge in points holds it at every width and every `heightFactor`.
    static let edgeInset: CGFloat = 16

    /// With `SkylineSpans`, how far short of the card's middle either structure must stop, in points:
    /// the "TIME LEFT" caption stands in the sky between them at the ground line, so a long time line
    /// (a larger text size) cannot walk a structure into it.
    private static let middleClearance: CGFloat = 60

    /// The pyramids' height over half-base, the SAME for all three: a real group is built to one
    /// angle (Giza's faces are within two degrees of each other), and three different slopes are what
    /// a mountain range has (Abu, 2026-09-25: "less like a mountain and more like pyramids").
    private static let pyramidSlope: CGFloat = 1.3

    /// Where the light falls from when none is given (the widgets' standing sun, and the night): high
    /// and to the right and a little in front, the side the one "sunward face" used to be painted on.
    /// x right, y up, z toward the viewer.
    fileprivate static let defaultLight = SIMD3<Double>(0.45, 0.8, 0.4)


    /// Draws the scene into `context`. `rect` is the graph's rect, `horizonY` the ground line, `color`
    /// one flat silhouette (see `tint(overSky:at:)` for the colours that suit a sky). Every length scales
    /// with the width, and again with the room above the horizon, so a 158 pt widget and a 360 pt card
    /// show the same skyline.
    static func draw(in context: inout GraphicsContext, rect: CGRect, horizonY: CGFloat, color: Color,
                     style: SkySceneStyle = .defaultStyle) {
        draw(in: &context, rect: rect, horizonY: horizonY, tint: .flat(color), style: style)
    }

    /// `spans` pins each structure to an exact stretch of the ground (the card's time lines); without
    /// it they take the fractional layout below, which is what the widgets draw. `light` is where the
    /// sun or the moon is on the card, so the pyramids' faces are lit from it; without it they are lit
    /// from `defaultLight`.
    static func draw(in context: inout GraphicsContext, rect: CGRect, horizonY: CGFloat, tint: SkylineTint,
                     style: SkySceneStyle = .defaultStyle, spans: SkylineSpans? = nil, light: SkylineLight? = nil) {
        let width = rect.width
        let room = horizonY - rect.minY
        guard width > 40, room > 12 else { return }
        let scale = min(max(0.55, min(1.0, width / 340)), (room - 2) / naturalHeight) * heightFactor
        let lit = Color.white.opacity(0.10)
        // One fill for every building, running from the scene's tallest point down to the ground,
        // so the turn to night can arrive at the domes and apexes before it reaches the doors.
        let color = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [tint.top, tint.bottom]),
            startPoint: CGPoint(x: rect.midX, y: horizonY - naturalHeight * scale),
            endPoint: CGPoint(x: rect.midX, y: horizonY)
        )

        func point(_ x: CGFloat, _ up: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * width, y: horizonY - up * scale)
        }

        // The ground: a band that fades out under the horizon, so the skyline stands on something.
        let groundHeight = min(rect.maxY - horizonY, 40 * scale)
        if groundHeight > 1 {
            let ground = CGRect(x: rect.minX, y: horizonY, width: width, height: groundHeight)
            context.fill(Path(ground), with: .linearGradient(
                Gradient(colors: [tint.ground, tint.ground.opacity(0)]),
                startPoint: CGPoint(x: rect.midX, y: horizonY),
                endPoint: CGPoint(x: rect.midX, y: horizonY + groundHeight)
            ))
        }

        // Each structure's stretch of ground, as fractions of THIS width. Without spans, the inset
        // as a fraction: the west structure starts at it, the east one ends at it, each `clusterSpan`
        // wide. With them, each spans its own prayer column's time line (Abu, 2026-09-25: "the pyramid
        // needs to start where the text 'Starts at' begins and same thing with masjid but where it
        // ends"): the outer ends already met the lines' outer ends at 16 pt, and it was the inner ends
        // that fell short of "8:15 PM" and started right of "Starts at". Which structure stands
        // where is the style's call (Abu, 2026-09-21: "both pyramids, or both mosques, but by default
        // it's this").
        let inset = edgeInset / width
        var west = inset...(inset + clusterSpan)
        var east = (1 - inset - clusterSpan)...(1 - inset)
        if let spans {
            let innerLimit = 0.5 - middleClearance / width
            let w0 = (spans.west.lowerBound - rect.minX) / width
            let w1 = min((spans.west.upperBound - rect.minX) / width, innerLimit)
            let e0 = max((spans.east.lowerBound - rect.minX) / width, 1 - innerLimit)
            let e1 = (spans.east.upperBound - rect.minX) / width
            // A span too narrow to hold a structure is a measurement that has not settled yet.
            if w1 - w0 > 0.08 { west = w0...w1 }
            if e1 - e0 > 0.08 { east = e0...e1 }
        }
        let lightFrom = light?.direction(fromCanvas: rect) ?? { _ in defaultLight }
        func pyramids(on ground: ClosedRange<CGFloat>) {
            // The viewer stands at the card's middle, so a cluster left of it is seen from its right.
            let viewerSide: CGFloat = (ground.lowerBound + ground.upperBound) / 2 < 0.5 ? 1 : -1
            drawPyramids(in: &context, point: point, ground: ground, width: width, scale: scale,
                         viewerSide: viewerSide, color: color, tint: tint, light: lightFrom)
        }
        func mosque(on ground: ClosedRange<CGFloat>) {
            let centre = (ground.lowerBound + ground.upperBound) / 2
            drawMosque(in: &context, point: point, centre: centre, span: ground.upperBound - ground.lowerBound,
                       width: width, scale: scale, color: color, lit: lit, glow: tint.glow, light: lightFrom)
        }
        switch style {
        case .pyramidsMosque:
            pyramids(on: west)
            mosque(on: east)
        case .pyramids:
            pyramids(on: west)
            pyramids(on: east)
        case .mosques:
            mosque(on: west)
            mosque(on: east)
        }
    }

    /// The skyline's colours for a sky painted with `colors` (top to bottom), read at `location`
    /// (0 top, 1 bottom) where the ground runs.
    static func tint(overSky colors: [Color], at location: CGFloat) -> SkylineTint {
        tint(overSky: skyComponents(of: colors, at: location))
    }

    /// How much of a NIGHT sky this is: 0 by day, 1 once the sky's luminance (where the ground runs)
    /// is under `nightBelow`, smooth between. The thresholds sit between Isha (0.15...0.17, card and
    /// widgets) and Maghrib (0.25...0.30) and Fajr (0.29...0.33), so every default period rests fully
    /// on one side; a custom sky in the gap rests part-way, which `tint` draws legibly (see there).
    static func nightFactor(overSky sky: (red: Double, green: Double, blue: Double)) -> Double {
        let luminance = 0.2126 * sky.red + 0.7152 * sky.green + 0.0722 * sky.blue
        return 1 - ease((luminance - nightBelow) / (dayAbove - nightBelow))
    }

    /// The skyline's colours over a settled `sky` (the widgets, which never animate).
    static func tint(overSky sky: (red: Double, green: Double, blue: Double)) -> SkylineTint {
        tint(overSky: sky, night: nightFactor(overSky: sky))
    }

    /// The skyline's colours over `sky`, `night` of the way from its day look to its night one.
    ///
    /// By day: the sky's own colour times `shade`, the darker-than-sky shadow described there.
    /// By night: moonlit, the sky with 30% of a near-white mixed in, which over Isha's default navy
    /// is the blue-grey RGB(86, 94, 118) the card wore before its silhouette went opaque. A darker
    /// shade of that navy is RGB(10, 14, 28), which is black: "make the mosque and pyramids white or
    /// gray or maybe just less black" (Abu, 2026-09-20).
    ///
    /// Going from darker-than-sky to paler-than-sky has to cross the sky's own colour; nothing
    /// continuous avoids that, and a flat crossfade crosses it EVERYWHERE AT ONCE, which is the
    /// frame in which the buildings used to vanish (see `shade`). So the two ends of the fill do not
    /// turn together: the tops lead and the feet follow (`topMix`, `bottomMix`), and the crossing is
    /// a narrow band that travels down the buildings, light catching the dome first, with everything
    /// above it already pale and everything below it still dark. At rest both ends agree, so a
    /// settled sky shows one flat colour, day or night.
    ///
    /// `night` is a parameter, NOT read off `sky` here, and that is what makes the turn smooth.
    /// The first version derived it from the interpolated sky's luminance each frame, which looks
    /// equivalent and is not: the sky's luminance falls through the whole threshold band in about a
    /// fifth of the turn, so the wash ran in 40 ms of a 0.2 s scrub, one captured frame, a 91-point
    /// jump on the dome (measured on a recording, 2026-09-20). `SkylineSilhouette` now walks `night`
    /// itself from one period's value to the next, over the sky's own duration.
    static func tint(overSky sky: (red: Double, green: Double, blue: Double), night: Double) -> SkylineTint {
        let night = max(0, min(1, night))
        // The tops lead and the feet follow. MEASURED on a recording of a scrub from midday into the
        // night and its release back (2026-09-20, 60 fps, the dome and a pyramid sampled against the
        // sky beside them), for three staggers:
        //   1.6 / 0.6   largest single-frame step 21 RGB points, best-lit part never under 1.34x
        //   1.8 / 0.8   28 points, 1.39x
        //   2.0 / 1.0   33 points, 1.39x
        // A wider stagger buys no legibility (the floor is set by the night-to-day return, where the
        // sky brightens THROUGH the moonlit fill) and costs smoothness, so the gentlest one stays.
        // For scale: the flat crossfade this replaces went through 1.00x for the whole building, and
        // deriving `night` from the sky per frame jumped 91 points in one frame.
        let topMix = ease(night * 1.6)
        let bottomMix = ease(night * 1.6 - 0.6)

        func fill(_ mix: Double) -> Color {
            func channel(_ value: Double) -> Double {
                let dark = value * shade
                let pale = value * (1 - moonlight) + moonlight * 0.92
                return dark + (pale - dark) * mix
            }
            return Color(red: channel(sky.red), green: channel(sky.green), blue: channel(sky.blue))
        }

        // The doorway and the windows: a lighter mark on a dark body by day, lamplight by night
        // (a pale mark on a pale body would leave the mosque a blank block).
        let glow = Color(red: 1, green: 1 - 0.14 * night, blue: 1 - 0.42 * night)
            .opacity(0.10 + 0.72 * night)
        // The ground band thins at night: at the day's 0.55 a pale fill reads as a lit strip of fog.
        let ground = fill(bottomMix).opacity(0.55 - 0.30 * night)
        return SkylineTint(top: fill(topMix), bottom: fill(bottomMix), ground: ground, glow: glow,
                           haze: Color(red: sky.red, green: sky.green, blue: sky.blue), night: night)
    }

    private static let nightBelow = 0.185
    private static let dayAbove = 0.235
    /// How much near-white moonlight is mixed into a night sky's own colour.
    private static let moonlight = 0.30

    /// Smoothstep on a `Double` (the `CGFloat` one below serves `dayFactor`).
    private static func ease(_ x: Double) -> Double {
        let t = max(0, min(1, x))
        return t * t * (3 - 2 * t)
    }

    /// The silhouette colour for a sky painted with `colors` (top to bottom), read at `location`
    /// (0 top, 1 bottom) where the ground runs: a darker shade of that sky, so the pyramids and the
    /// mosque show against every period's gradient and whatever pair the user picked.
    static func silhouette(overSky colors: [Color], at location: CGFloat) -> Color {
        silhouette(overSky: skyColor(of: colors, at: location))
    }

    /// The sky's own colour where the ground runs: the gradient's endpoints mixed by `location`.
    /// The silhouette is a darker shade of exactly this, which is what keeps the two in step.
    static func skyColor(of colors: [Color], at location: CGFloat) -> Color {
        let c = skyComponents(of: colors, at: location)
        return Color(red: c.red, green: c.green, blue: c.blue)
    }

    /// The same reading as `skyColor`, as three numbers, so `SkylineSilhouette` can interpolate them.
    /// A `Color` cannot travel through `animatableData`; its components can.
    static func skyComponents(of colors: [Color], at location: CGFloat) -> (red: Double, green: Double, blue: Double) {
        guard let top = colors.first, let bottom = colors.last else { return (0, 0, 0) }
        let t = max(0, min(1, location))
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        UIColor(top).getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        UIColor(bottom).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return (Double(tr + (br - tr) * t), Double(tg + (bg - tg) * t), Double(tb + (bb - tb) * t))
    }

    /// How much of a DAY sky this is at `location`: 0 over a night sky (luminance up to 0.12), 1 over
    /// a day sky (from 0.40), smooth between. The app card crossfades the two silhouettes on it.
    static func dayFactor(overSky colors: [Color], at location: CGFloat) -> CGFloat {
        guard let top = colors.first, let bottom = colors.last else { return 1 }
        let t = max(0, min(1, location))
        let luminance = (1 - t) * Self.luminance(of: top) + t * Self.luminance(of: bottom)
        return smoothstep((luminance - 0.12) / 0.28)
    }

    /// A darker shade of the sky behind it, OPAQUE.
    ///
    /// Opaque is the whole point (Abu, 2026-09-16: "WE ARE STILL CROSSING THE SOLAR GRAPH"). The
    /// skyline has always been drawn after the arc, so it was already on top, but at 0.30...0.55 alpha
    /// the dashes read straight through the pyramids and the mosque and the arc looked like it was
    /// cutting them in half. Filling the shapes solid hides it behind them, which is what a silhouette
    /// on a horizon does, and it is the only fix that leaves the graph itself alone.
    ///
    /// Shrinking the buildings does NOT work, which cost three attempts to establish: the arc's window
    /// runs Fajr to Fajr, so the day half rises out of the ground at sunrise around x 0.01...0.07,
    /// right where the pyramid cluster starts, and therefore sweeps through EVERY height there. A
    /// shorter pyramid is crossed lower down, not spared. Measured across real prayer windows, the
    /// pyramids were crossed in 30 of 30 at full height and in 30 of 30 at 50%.
    ///
    /// Takes the sky it stands against so it can keep the LOOK the translucent version had. The old
    /// silhouette was 0.92 white at 0.30 alpha over a night sky, which composited to a blue-tinted
    /// RGB(82, 88, 113): its colour came from the sky showing through it, which is the very thing
    /// being removed. So the sky is mixed into the fill instead of behind it, and the result is the
    /// same colour, opaque. Sampling a built card before and after is the check that matters here;
    /// a first attempt at a flat opaque grey came out RGB(164, 164, 164), twice as light and with the
    /// blue gone, and looked nothing like the card it replaced.
    static func silhouette(overSky sky: Color) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(sky).getRed(&r, green: &g, blue: &b, alpha: &a)
        // The sky's own colour, darkened. One multiply, nothing else: see `shade`.
        return Color(red: Double(r) * shade, green: Double(g) * shade, blue: Double(b) * shade)
    }

    /// How much of the sky's brightness the DAY silhouette keeps: darker than its sky. It used to be
    /// the rule at every hour; since 2026-09-20 a night sky gets the moonlit fill instead (see
    /// `tint(overSky:)`), and what follows is why that turn is a travelling wash and not a fade.
    /// Worth stating plainly, because two cleverer versions of this failed in ways that only showed
    /// up mid-animation.
    ///
    /// A silhouette is a shadow. It reads as one when it is darker than what is behind it, and the
    /// day/night crossfade this used to do (pale buildings at night, dark by day) had to pass THROUGH
    /// the sky's own luminance to get from one to the other. Standing still that was only a bad
    /// colour at Maghrib, where the blend happened to land on the crossing. Moving, it was worse: at
    /// the turn from Maghrib to Isha the silhouette went from darker-than-sky to lighter-than-sky, so
    /// the fade between them ran through 1.00x contrast and the pyramids and the mosque genuinely
    /// disappeared for a few frames (Abu, 2026-09-16: "so abrupt and almost like there is nothing").
    ///
    /// Two attempted repairs are recorded here because both look reasonable and neither works:
    ///  - recomputing a contrast floor per frame keeps every FRAME legible but lets the push
    ///    direction flip when one direction runs out of headroom, which is a 113-point jump, and
    ///  - crossfading the darker and lighter candidates is smooth, 3 points a frame, but the average
    ///    of a dark and a light colour is the sky itself, so it passes through 1.01x and vanishes.
    /// One direction, always, is what removes the failure instead of relocating it.
    ///
    /// 0.38 keeps every period between 1.9x and 2.4x contrast against its own sky, the darkest being
    /// Isha's 1.93x (a night sky has the least room to go darker). Because it is a plain multiple of
    /// the sky, the silhouette moves exactly as the sky moves: across a Maghrib-to-Isha turn the
    /// biggest step is 1 RGB point and contrast never drops below 2.08x.
    private static let shade: Double = 0.38

    private static func luminance(of color: Color) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private static func smoothstep(_ x: CGFloat) -> CGFloat {
        let t = max(0, min(1, x))
        return t * t * (3 - 2 * t)
    }

    // MARK: Pyramids

    private static func drawPyramids(in context: inout GraphicsContext, point: (CGFloat, CGFloat) -> CGPoint,
                                     ground: ClosedRange<CGFloat>, width: CGFloat, scale: CGFloat,
                                     viewerSide: CGFloat, color: GraphicsContext.Shading, tint: SkylineTint,
                                     light: (CGPoint) -> SIMD3<Double>) {
        // The cluster MIRRORS the mosque's skeleton rather than merely matching its bounding box (Abu,
        // 2026-09-16, looking at the card: "look at that tiny pyramid its nothing like the minaret").
        // The mosque is a tall centre between two smaller outer masses, so this is too: a great
        // pyramid on the cluster's centre, `naturalHeight` like the crescent, with one smaller pyramid
        // at each end where the minarets stand, 30 high like them.
        //
        // What was wrong before that: three pyramids staggered 0.02/0.11/0.26 at heights 24/43/15. The
        // bounding box measured 0.30 wide and 43 tall and so passed every check, but the third was a
        // 15-high stub with nothing opposite it, and the cluster's mass sat left of its own centre
        // while the mosque's sat on its. Equal boxes, visibly unequal skylines.
        //
        // And what read as a MOUNTAIN until 2026-09-25 (Abu: "make the pyramids look less like a
        // mountain and more like pyramids maybe make them 3d"): three flat triangles at three different
        // slopes (1.35 to 1.5), bases buried a third deep in one another so the valleys between them
        // ran high, and one flat colour. So now:
        //  - one slope for all three (`pyramidSlope`), their half-bases derived from their heights, so
        //    the small ones are the great one scaled down, as built things are;
        //  - they stand side by side across the span with their bases barely overlapping, the valleys
        //    between them near the ground; only a span too narrow for that steepens them;
        //  - each is a SOLID: two faces meeting at the corner edge nearest the viewer, the face that
        //    turns toward the light lighter and the other darker, lit from wherever the sun (or, at
        //    night, the moon's soft light) actually is on the card;
        //  - the small two stand BEHIND the great one, drawn first and hazed a little toward the sky,
        //    which is what distance does, so the group has depth instead of one merged outline.
        let smallHeight: CGFloat = 30
        var greatHalf = naturalHeight * scale / pyramidSlope / width
        var smallHalf = smallHeight * scale / pyramidSlope / width
        let span = ground.upperBound - ground.lowerBound
        let needed = 2 * greatHalf + 4 * smallHalf
        if needed > span * 1.3 {
            let fit = span * 1.3 / needed
            greatHalf *= fit
            smallHalf *= fit
        }
        let middle = (ground.lowerBound + ground.upperBound) / 2
        let pyramids: [(apex: CGFloat, half: CGFloat, height: CGFloat, far: Bool)] = [
            (ground.lowerBound + smallHalf, smallHalf, smallHeight, true),
            (ground.upperBound - smallHalf, smallHalf, smallHeight, true),
            (middle, greatHalf, naturalHeight, false),
        ]
        let litMax = 0.22 * (1 - 0.3 * tint.night)
        let shadeMax = 0.30 * (1 - 0.5 * tint.night)
        for pyramid in pyramids {
            let left = pyramid.apex - pyramid.half
            let right = pyramid.apex + pyramid.half
            // The corner edge nearest the viewer. Seen from its right, a square pyramid shows its
            // front-left and front-right faces, and the edge between them lands LEFT of its apex, so
            // the face turned toward the viewer is the wider one (0.36 is tan 20 degrees).
            let arris = pyramid.apex - viewerSide * pyramid.half * 0.36
            let top = point(pyramid.apex, pyramid.height)

            var body = Path()
            body.move(to: point(left, 0))
            body.addLine(to: top)
            body.addLine(to: point(right, 0))
            body.closeSubpath()
            context.fill(body, with: color)

            // Each face's outward normal (x right, y up, z toward the viewer): leaning out to its
            // side, up, and more toward the viewer on the face that is turned to them.
            let toward = viewerSide > 0 ? (left: 0.4, right: 0.7) : (left: 0.7, right: 0.4)
            let faces: [(from: CGFloat, to: CGFloat, normal: SIMD3<Double>)] = [
                (left, arris, SIMD3(-0.62, 0.5, toward.left)),
                (arris, right, SIMD3(0.62, 0.5, toward.right)),
            ]
            let direction = light(top)
            for face in faces {
                let normal = face.normal / (face.normal * face.normal).sum().squareRoot()
                let lambert = max(0, (normal * direction).sum())
                // 0.3 of ambient, the rest from the light; the body's own colour stands for 0.6.
                let value = 0.3 + 0.7 * lambert
                var path = Path()
                path.move(to: point(face.from, 0))
                path.addLine(to: top)
                path.addLine(to: point(face.to, 0))
                path.closeSubpath()
                if value > 0.6 {
                    context.fill(path, with: .color(.white.opacity((value - 0.6) / 0.4 * litMax)))
                } else {
                    context.fill(path, with: .color(.black.opacity((0.6 - value) / 0.3 * shadeMax)))
                }
            }

            if pyramid.far, let haze = tint.haze {
                context.fill(body, with: .color(haze.opacity(0.18)))
            }
        }
    }

    // MARK: Mosque

    private static func drawMosque(in context: inout GraphicsContext, point: (CGFloat, CGFloat) -> CGPoint,
                                   centre: CGFloat, span: CGFloat, width: CGFloat, scale: CGFloat,
                                   color: GraphicsContext.Shading, lit: Color, glow: Color,
                                   light: (CGPoint) -> SIMD3<Double>) {
        // The mosque spans exactly `span` of the card ending `edgeInset` points from the right edge
        // (or exactly the UPCOMING column's time line, see `SkylineSpans`), the mirror of the pyramid
        // cluster starting `edgeInset` from the left, and its crescent
        // reaches `naturalHeight` as the great pyramid's apex does. The two stand either side of the
        // middle, which the arc's peak and the countdown digits need clear. The inset also keeps the
        // minaret clear of the rounded corner (0.98 clipped it; only a screenshot caught it).
        //
        // MEASURE THE OUTERMOST INK, not the body. Getting this wrong is what made the mosque read
        // as wider and shorter than the pyramids even though the numbers here said 0.30 and 43:
        //  - the widest thing is not the body rect but each minaret's BALCONY RING, which is
        //    `shaft * 2` wide, so it overhangs its own centre by a full `shaft` on each side. The
        //    minaret centres are therefore inset from the span's ends by that overhang, in width
        //    fractions, which holds the drawn span at 0.30 at widget size and card size alike.
        //  - the tallest thing is the crescent, which sits 7 above the finial's tip plus its own
        //    radius, and the tip is `domeRadius * 1.28` above the dome's centre. `domeLift` is
        //    solved backwards from all of that so the topmost ink lands on `naturalHeight`.
        // Both are derived here rather than written as literals, so a change of scale, shaft or dome
        // radius carries through instead of quietly unmatching the two again. Check a change against
        // a screenshot, not the build: the last mismatch compiled perfectly for weeks.
        let baseHeight: CGFloat = 9
        let domeRadius = 15 * scale
        let sideRadius = 6.5 * scale
        let minaretHeight: CGFloat = 30
        let shaftWidth = min(width * 0.014, 5 * scale)
        // Half the distance between the minaret centres: the span less each ring's overhang.
        let minaretOffset = span / 2 - shaftWidth / width
        // Lifts the dome so the crescent's topmost point is exactly `naturalHeight`.
        let domeLift = naturalHeight - baseHeight - domeRadius * 1.28 / scale - 10.05

        // Minarets first: they stand behind the body.
        for x in [centre - minaretOffset, centre + minaretOffset] {
            let shaft = shaftWidth
            let top = point(x, minaretHeight)
            let shaftRect = CGRect(x: top.x - shaft / 2, y: top.y, width: shaft, height: point(x, 0).y - top.y)
            context.fill(Path(shaftRect), with: color)
            // The balcony ring and the cap.
            let ring = CGRect(x: top.x - shaft, y: point(x, minaretHeight * 0.68).y, width: shaft * 2, height: 2.5 * scale)
            context.fill(Path(ring), with: color)
            let cap = CGRect(x: top.x - shaft * 0.9, y: top.y - shaft * 0.9, width: shaft * 1.8, height: shaft * 1.8)
            context.fill(Path(ellipseIn: cap), with: color)
            var finial = Path()
            finial.move(to: CGPoint(x: top.x, y: top.y - shaft * 0.9))
            finial.addLine(to: CGPoint(x: top.x, y: top.y - shaft * 0.9 - 3.5 * scale))
            context.stroke(finial, with: color, lineWidth: 1.2)
        }

        // The two side domes, then the great dome, all standing on the body's roof line. The side
        // domes and the windows sit at fixed shares of the span (0.095 and 0.06 of the card when the
        // span was always 0.225 of it), so a mosque stretched to its time line keeps its rhythm.
        for x in [centre - span * 0.422, centre + span * 0.422] {
            let domeCentre = point(x, baseHeight)
            let rect = CGRect(x: domeCentre.x - sideRadius, y: domeCentre.y - sideRadius, width: sideRadius * 2, height: sideRadius * 2)
            context.fill(Path(ellipseIn: rect), with: color)
        }
        let domeCentre = point(centre, baseHeight + domeLift)
        var dome = Path()
        // An onion dome: the round of a circle, drawn up to a point.
        dome.move(to: CGPoint(x: domeCentre.x - domeRadius, y: domeCentre.y))
        dome.addArc(center: domeCentre, radius: domeRadius, startAngle: .degrees(180), endAngle: .degrees(300), clockwise: false)
        dome.addQuadCurve(to: CGPoint(x: domeCentre.x, y: domeCentre.y - domeRadius * 1.28),
                          control: CGPoint(x: domeCentre.x - domeRadius * 0.18, y: domeCentre.y - domeRadius * 1.04))
        dome.addQuadCurve(to: CGPoint(x: domeCentre.x + domeRadius * 0.5, y: domeCentre.y - domeRadius * 0.866),
                          control: CGPoint(x: domeCentre.x + domeRadius * 0.18, y: domeCentre.y - domeRadius * 1.04))
        dome.addArc(center: domeCentre, radius: domeRadius, startAngle: .degrees(300), endAngle: .degrees(360), clockwise: false)
        dome.closeSubpath()
        context.fill(dome, with: color)
        // A highlight on the dome's sunward curve: centred on the light's direction (the same light
        // the pyramids' faces turn to), kept on the dome's upper half.
        let toLight = light(domeCentre)
        let lightAngle = min(max(atan2(-toLight.y, toLight.x) * 180 / .pi, -160), -20)
        var domeLit = Path()
        domeLit.addArc(center: domeCentre, radius: domeRadius * 0.82, startAngle: .degrees(lightAngle - 25),
                       endAngle: .degrees(lightAngle + 25), clockwise: false)
        context.stroke(domeLit, with: .color(lit), lineWidth: 2 * scale)

        // The finial and its crescent.
        let tip = CGPoint(x: domeCentre.x, y: domeCentre.y - domeRadius * 1.28)
        var finial = Path()
        finial.move(to: tip)
        finial.addLine(to: CGPoint(x: tip.x, y: tip.y - 4 * scale))
        context.stroke(finial, with: color, lineWidth: 1.2)
        var crescent = Path()
        crescent.addArc(center: CGPoint(x: tip.x, y: tip.y - 7 * scale), radius: 2.4 * scale,
                        startAngle: .degrees(-40), endAngle: .degrees(220), clockwise: false)
        context.stroke(crescent, with: color, lineWidth: 1.3)

        // The body, over the domes' undersides. It sits INSIDE the minarets rather than spanning the
        // whole mosque: they stand at its corners, so it reaches their centres and no further.
        let bodyRect = CGRect(x: point(centre - minaretOffset, 0).x, y: point(centre, baseHeight).y,
                              width: minaretOffset * 2 * width, height: baseHeight * scale)
        context.fill(Path(bodyRect), with: color)

        // The doorway's arch and two windows, lighter, so the body is a building and not a block.
        let doorWidth = min(width * 0.028, 9 * scale)
        let door = CGRect(x: point(centre, 0).x - doorWidth / 2, y: point(centre, 7).y, width: doorWidth, height: 7 * scale)
        var arch = Path()
        arch.move(to: CGPoint(x: door.minX, y: door.maxY))
        arch.addLine(to: CGPoint(x: door.minX, y: door.minY + doorWidth / 2))
        arch.addArc(center: CGPoint(x: door.midX, y: door.minY + doorWidth / 2), radius: doorWidth / 2,
                    startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        arch.addLine(to: CGPoint(x: door.maxX, y: door.maxY))
        arch.closeSubpath()
        context.fill(arch, with: .color(glow))
        for x in [centre - span * 0.267, centre + span * 0.267] {
            let window = CGRect(x: point(x, 0).x - 1.5 * scale, y: point(x, 6).y, width: 3 * scale, height: 4 * scale)
            context.fill(Path(roundedRect: window, cornerRadius: 1.5 * scale), with: .color(glow))
        }
    }
}

/// The scene as a view: one still frame, in the app and the widgets alike (nothing in it moves since
/// the palms went, so the 10 fps timeline that swayed them went with them).
struct SkySceneView: View {
    let horizonY: CGFloat
    let tint: SkylineTint
    /// Defaults to the saved choice, read the way this process can (`Settings.skylineStyle`), so the
    /// widgets need no plumbing; the card passes its observed value so a change redraws at once.
    let style: SkySceneStyle
    /// The card's time lines, which the structures span; nil takes the fractional layout.
    let spans: SkylineSpans?
    /// Where the sun or the moon is, which lights the pyramids' faces; nil lights them from the
    /// standing default.
    let light: SkylineLight?

    init(horizonY: CGFloat, tint: SkylineTint, style: SkySceneStyle = Settings.shared.skylineStyle,
         spans: SkylineSpans? = nil, light: SkylineLight? = nil) {
        self.horizonY = horizonY
        self.tint = tint
        self.style = style
        self.spans = spans
        self.light = light
    }

    /// One flat colour, for a skyline that stands on no sky (the widgets' standard background).
    init(horizonY: CGFloat, color: Color, style: SkySceneStyle = Settings.shared.skylineStyle,
         light: SkylineLight? = nil) {
        self.init(horizonY: horizonY, tint: .flat(color), style: style, light: light)
    }

    var body: some View {
        Canvas { context, size in
            SkyScene.draw(in: &context, rect: CGRect(origin: .zero, size: size), horizonY: horizonY, tint: tint,
                          style: style, spans: spans, light: light)
        }
        .allowsHitTesting(false)
    }
}

/// What the skyline is painted with: the buildings' fill at their tops and at the ground (one colour
/// at rest, two while a day sky turns to a night one, see `SkyScene.tint(overSky:)`), the ground band
/// under them, and the light in the mosque's doorway and windows.
struct SkylineTint {
    var top: Color
    var bottom: Color
    var ground: Color
    var glow: Color
    /// The sky itself where the ground runs: the far pyramids are hazed toward it, which is what
    /// distance does. Nil on a flat tint, which stands on no sky.
    var haze: Color? = nil
    /// How far into its night look the skyline is (`SkyScene.nightFactor`): moonlight is softer, so
    /// the pyramids' faces differ less.
    var night: Double = 0

    static func flat(_ color: Color) -> SkylineTint {
        SkylineTint(top: color, bottom: color, ground: color.opacity(0.55), glow: Color.white.opacity(0.10))
    }
}

/// Where each structure stands, in the canvas's own points: the pyramids across the CURRENT
/// column's "Started at" line and the mosque across the UPCOMING column's "Starts at" line, so the
/// skyline begins and ends exactly where the text does (Abu, 2026-09-25). `SkyScene.draw` keeps both
/// clear of the middle (`middleClearance`).
struct SkylineSpans: Equatable {
    var west: ClosedRange<CGFloat>
    var east: ClosedRange<CGFloat>
}

/// The light the pyramids' faces turn to: the marker on the card's arc, the sun by day. At night the
/// marker is the moon riding the path BELOW the ground, which cannot light anything standing on it, so
/// `day` hands the light over to the soft standing moonlight (`SkyScene.defaultLight`) as the sun
/// goes down, on the same ramp that swaps the two markers (`SolarCurve.daylightPresence`).
struct SkylineLight: Equatable {
    /// The marker's centre, in the canvas's points.
    var source: CGPoint
    /// 1 while the sun is up, 0 through the night, eased between.
    var day: Double

    /// The unit vector from a point on the canvas toward the light (x right, y up, z toward the viewer).
    func direction(fromCanvas rect: CGRect) -> (CGPoint) -> SIMD3<Double> {
        let source = source
        let day = min(max(day, 0), 1)
        return { point in
            let dx = Double(source.x - point.x), dy = Double(point.y - source.y)
            let length = max((dx * dx + dy * dy).squareRoot(), 0.0001)
            let sun = SIMD3(dx / length, dy / length, 0.45)
            let mixed = SkyScene.defaultLight * (1 - day) + sun * day
            return mixed / max((mixed * mixed).sum().squareRoot(), 0.0001)
        }
    }
}

/// The skyline as something that can ANIMATE its colour, which `SkySceneView` cannot: a `Canvas` just
/// redraws with whatever `Color` it is handed, so `.animation(value:)` around one has nothing to
/// interpolate and the silhouette snaps from its night shade to its day shade in a single frame.
///
/// The card used to hide that by stacking a dark skyline and a pale one and crossfading their
/// opacities, which worked but required both to be translucent, and a translucent silhouette is what
/// let the solar arc show straight through the buildings (Abu, 2026-09-16). So the fade moved here
/// instead: `day` is a plain `Double`, `animatableData` lets SwiftUI walk it frame by frame, and each
/// frame resolves the one opaque colour for that instant. Nothing is ever see-through, and the tint
/// still travels rather than jumping (Abu, same day: "the animation for when the color changes is bad").
/// Draws the skyline with a colour that TRAVELS when the sky turns over at a prayer.
///
/// It is a `ViewModifier`, and that is the load-bearing detail. SwiftUI only drives `animatableData`
/// frame by frame on a `Shape`, a `ViewModifier` and a couple of other protocols; on a plain `View`
/// conforming to `Animatable` it is quietly ignored and the body renders once with the final value.
/// A first attempt made this a `View`, which compiled, looked correct and still snapped: the sky's
/// gradient eased over its second while the silhouette jumped 56 RGB points in a single frame, so at
/// the turn from Maghrib to Isha the buildings changed colour all at once (Abu, 2026-09-16:
/// "switching from maghrib to isha the color of the mosque/pyramids is so abrupt").
///
/// FOUR numbers travel, not one. At night only 30% of the silhouette's colour comes from the
/// day/night tint and the other 70% from the sky mixed into it, so `day` alone is not enough: the
/// sky's three components have to come with it, or most of the colour still jumps.
/// Draws the skyline with a colour that TRAVELS when the sky turns over at a prayer.
///
/// It is a `ViewModifier`, and that is the load-bearing detail. SwiftUI drives `animatableData` frame
/// by frame on a `Shape`, a `ViewModifier` and a couple of other protocols; on a plain `View`
/// conforming to `Animatable` it is quietly ignored and the body renders once with the final value.
/// A first attempt made this a `View`, which compiled, looked right and still snapped.
struct SkylineSilhouette: ViewModifier, Animatable {
    var sky: (red: Double, green: Double, blue: Double)
    /// `SkyScene.nightFactor` of the sky being turned TO. It travels beside the sky's components
    /// rather than being read off them each frame; `SkyScene.tint(overSky:night:)` says why.
    var night: Double
    var horizonY: CGFloat
    var style: SkySceneStyle
    /// Neither travels: the spans move only when a time line's text changes, and the light follows
    /// the marker, which is already exactly where it should be on every frame.
    var spans: SkylineSpans?
    var light: SkylineLight?

    /// FOUR numbers travel: the sky's three components, and how far into the night look the
    /// skyline is. It is NOT the silhouette's own colour that is interpolated: that is what made the
    /// turn from Maghrib to Isha pass through 1.00x contrast, because the two ends sat on opposite
    /// sides of the sky's luminance and the straight line between them ran through the sky itself.
    /// Interpolating the sky and re-deriving the fill from it keeps the relationship at every step.
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, AnimatablePair<Double, Double>>> {
        get { .init(night, .init(sky.red, .init(sky.green, sky.blue))) }
        set {
            night = newValue.first
            sky = (newValue.second.first, newValue.second.second.first, newValue.second.second.second)
        }
    }

    func body(content: Content) -> some View {
        SkySceneView(horizonY: horizonY, tint: SkyScene.tint(overSky: sky, night: night), style: style,
                     spans: spans, light: light)
    }
}

extension View {
    /// Replaces this view with the skyline, drawn for `sky` (its day or night look decided by that
    /// sky's own luminance), animating the turn from whatever it was drawn for before.
    func skylineSilhouette(sky: (red: Double, green: Double, blue: Double),
                           horizonY: CGFloat, style: SkySceneStyle,
                           spans: SkylineSpans? = nil, light: SkylineLight? = nil) -> some View {
        modifier(SkylineSilhouette(sky: sky, night: SkyScene.nightFactor(overSky: sky), horizonY: horizonY, style: style,
                                   spans: spans, light: light))
    }
}

extension Settings {
    private static let skySceneSharedSuite = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

    /// Whether the skyline is drawn, as THIS process can see it: the app reads its own setting, the
    /// widget extension the app-group mirror (`showSkyScene`'s didSet writes it), defaulting to on.
    var showsSkyline: Bool {
        if Self.isAppProcess { return showSkyScene }
        guard let stored = Self.skySceneSharedSuite?.object(forKey: "showSkyScene") as? Bool else { return true }
        return stored
    }

    /// Which structures the skyline draws, the same way: the app reads its own `skySceneStyle`, the
    /// widget extension the app-group mirror, defaulting to the mosque-and-pyramids pair.
    var skylineStyle: SkySceneStyle {
        let raw = Self.isAppProcess
            ? skySceneStyle
            : (Self.skySceneSharedSuite?.string(forKey: SkySceneStyle.storageKey) ?? "")
        return SkySceneStyle(rawValue: raw) ?? .defaultStyle
    }
}
#endif
