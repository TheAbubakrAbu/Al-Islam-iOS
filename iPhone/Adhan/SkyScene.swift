#if os(iOS)
import SwiftUI

// The skyline along the solar countdown's ground (2026-09-16): three pyramids to the west and a mosque
// with its dome and two minarets to the east, in silhouette on the ground the horizon line draws. In the
// app the ground runs between the countdown's "TIME LEFT" caption and its digits, so the whole skyline
// stands in the sky band between the prayer columns and the digits, the pyramids under CURRENT, the
// caption between them and the mosque under UPCOMING (see `SkyCard.arc`); the Solar Arc widgets draw the same paths on their own horizon,
// scaled to whatever room they have above it, so the two skylines match in shape. The sun rides the
// arc by day and sinks behind the ground at sunset; through the night the moon, at its true phase,
// takes its place on the path (the card and `SolarArcGraph` place it). The pyramids and the mosque are
// the same height, the mosque back at the size it first had (Abu, 2026-09-16: "the mosque before
// looked better, make it take as much height as it needs"), and the palms that once stood east of it
// are gone. Over a dark sky the silhouette turns pale (`silhouette(overSky:at:)`), or the skyline
// vanished at Isha.

enum SkyScene {
    /// The tallest point of the scene above the horizon at scale 1 (the mosque's crescent), in points.
    /// `draw` shrinks the scene when the room above the horizon is shorter than this.
    static let naturalHeight: CGFloat = 43

    /// Draws the scene into `context`. `rect` is the graph's rect, `horizonY` the ground line, `color`
    /// the silhouette (see `silhouette(overSky:at:)` for one that suits the sky). Every length scales
    /// with the width, and again with the room above the horizon, so a 158 pt widget and a 360 pt card
    /// show the same skyline.
    static func draw(in context: inout GraphicsContext, rect: CGRect, horizonY: CGFloat, color: Color) {
        let width = rect.width
        let room = horizonY - rect.minY
        guard width > 40, room > 12 else { return }
        let scale = min(max(0.55, min(1.0, width / 340)), (room - 2) / naturalHeight)
        let lit = Color.white.opacity(0.10)

        func point(_ x: CGFloat, _ up: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * width, y: horizonY - up * scale)
        }

        // The ground: a band that fades out under the horizon, so the skyline stands on something.
        let groundHeight = min(rect.maxY - horizonY, 40 * scale)
        if groundHeight > 1 {
            let ground = CGRect(x: rect.minX, y: horizonY, width: width, height: groundHeight)
            context.fill(Path(ground), with: .linearGradient(
                Gradient(colors: [color.opacity(0.55), color.opacity(0)]),
                startPoint: CGPoint(x: rect.midX, y: horizonY),
                endPoint: CGPoint(x: rect.midX, y: horizonY + groundHeight)
            ))
        }

        drawPyramids(in: &context, point: point, color: color, lit: lit)
        drawMosque(in: &context, point: point, width: width, scale: scale, color: color, lit: lit)
    }

    /// The silhouette colour for a sky painted with `colors` (top to bottom), read at `location`
    /// (0 top, 1 bottom) where the ground runs: a dark shade over a daytime sky, a pale one over the
    /// night's, blended in between, so the pyramids and the mosque show against every period's
    /// gradient and whatever pair the user picked (Abu, 2026-09-16: at night they were hard to see).
    static func silhouette(overSky colors: [Color], at location: CGFloat) -> Color {
        silhouette(day: dayFactor(overSky: colors, at: location))
    }

    /// How much of a DAY sky this is at `location`: 0 over a night sky (luminance up to 0.12), 1 over
    /// a day sky (from 0.40), smooth between. The app card crossfades the two silhouettes on it.
    static func dayFactor(overSky colors: [Color], at location: CGFloat) -> CGFloat {
        guard let top = colors.first, let bottom = colors.last else { return 1 }
        let t = max(0, min(1, location))
        let luminance = (1 - t) * Self.luminance(of: top) + t * Self.luminance(of: bottom)
        return smoothstep((luminance - 0.12) / 0.28)
    }

    /// The silhouette for a given day factor: 0.55 black by day, a pale 0.30 white by night.
    static func silhouette(day: CGFloat) -> Color {
        let day = max(0, min(1, day))
        return Color(white: 0.92 * (1 - day), opacity: 0.30 + 0.25 * day)
    }

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

    private static func drawPyramids(in context: inout GraphicsContext, point: (CGFloat, CGFloat) -> CGPoint, color: Color, lit: Color) {
        // (left, apex x, right, height): the great one in the middle of the cluster, a low one half off
        // the edge, a small one toward the middle. The great one stands 30 high, the mosque's dome
        // about the same (its crescent a little higher): "the pyramids the same size as the mosque".
        let pyramids: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-0.02, 0.06, 0.14, 17),
            (0.08, 0.19, 0.30, 30),
            (0.27, 0.32, 0.37, 11),
        ]
        for (left, apex, right, height) in pyramids {
            var body = Path()
            body.move(to: point(left, 0))
            body.addLine(to: point(apex, height))
            body.addLine(to: point(right, 0))
            body.closeSubpath()
            context.fill(body, with: .color(color))

            // The sunward face, a shade lighter, so the shape reads as a solid and not a triangle.
            var face = Path()
            face.move(to: point(apex, height))
            face.addLine(to: point(right, 0))
            face.addLine(to: point((apex + right) / 2 + 0.01, 0))
            face.closeSubpath()
            context.fill(face, with: .color(lit))
        }
    }

    // MARK: Mosque

    private static func drawMosque(in context: inout GraphicsContext, point: (CGFloat, CGFloat) -> CGPoint,
                                   width: CGFloat, scale: CGFloat, color: Color, lit: Color) {
        // Centred at 0.82 of the width, the body spanning 0.69...0.95 and the minarets at its edges.
        // The dome's apex lands at about 30 (the great pyramid's height), its crescent at 43
        // (`naturalHeight`), the minarets' finials at about 38. The dome is sized in points, not in
        // the width, and the whole stands clear of the UPCOMING column's last line (about 69 pt down
        // the card; the ground is about 121).
        let centre: CGFloat = 0.82
        let baseHeight: CGFloat = 9
        let domeRadius = 15 * scale
        let sideRadius = 6.5 * scale
        let minaretHeight: CGFloat = 30

        // Minarets first: they stand behind the body.
        for x in [centre - 0.115, centre + 0.115] {
            let shaft = min(width * 0.014, 5 * scale)
            let top = point(x, minaretHeight)
            let shaftRect = CGRect(x: top.x - shaft / 2, y: top.y, width: shaft, height: point(x, 0).y - top.y)
            context.fill(Path(shaftRect), with: .color(color))
            // The balcony ring and the cap.
            let ring = CGRect(x: top.x - shaft, y: point(x, minaretHeight * 0.68).y, width: shaft * 2, height: 2.5 * scale)
            context.fill(Path(ring), with: .color(color))
            let cap = CGRect(x: top.x - shaft * 0.9, y: top.y - shaft * 0.9, width: shaft * 1.8, height: shaft * 1.8)
            context.fill(Path(ellipseIn: cap), with: .color(color))
            var finial = Path()
            finial.move(to: CGPoint(x: top.x, y: top.y - shaft * 0.9))
            finial.addLine(to: CGPoint(x: top.x, y: top.y - shaft * 0.9 - 3.5 * scale))
            context.stroke(finial, with: .color(color), lineWidth: 1.2)
        }

        // The two side domes, then the great dome, all standing on the body's roof line.
        for x in [centre - 0.075, centre + 0.075] {
            let domeCentre = point(x, baseHeight)
            let rect = CGRect(x: domeCentre.x - sideRadius, y: domeCentre.y - sideRadius, width: sideRadius * 2, height: sideRadius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
        let domeCentre = point(centre, baseHeight + 2)
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
        context.fill(dome, with: .color(color))
        // A highlight on the dome's sunward curve.
        var domeLit = Path()
        domeLit.addArc(center: domeCentre, radius: domeRadius * 0.82, startAngle: .degrees(300), endAngle: .degrees(350), clockwise: false)
        context.stroke(domeLit, with: .color(lit), lineWidth: 2 * scale)

        // The finial and its crescent.
        let tip = CGPoint(x: domeCentre.x, y: domeCentre.y - domeRadius * 1.28)
        var finial = Path()
        finial.move(to: tip)
        finial.addLine(to: CGPoint(x: tip.x, y: tip.y - 4 * scale))
        context.stroke(finial, with: .color(color), lineWidth: 1.2)
        var crescent = Path()
        crescent.addArc(center: CGPoint(x: tip.x, y: tip.y - 7 * scale), radius: 2.4 * scale,
                        startAngle: .degrees(-40), endAngle: .degrees(220), clockwise: false)
        context.stroke(crescent, with: .color(color), lineWidth: 1.3)

        // The body, over the domes' undersides.
        let bodyRect = CGRect(x: point(centre - 0.13, 0).x, y: point(centre, baseHeight).y, width: width * 0.26, height: baseHeight * scale)
        context.fill(Path(bodyRect), with: .color(color))

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
        context.fill(arch, with: .color(lit))
        for x in [centre - 0.06, centre + 0.06] {
            let window = CGRect(x: point(x, 0).x - 1.5 * scale, y: point(x, 6).y, width: 3 * scale, height: 4 * scale)
            context.fill(Path(roundedRect: window, cornerRadius: 1.5 * scale), with: .color(lit))
        }
    }
}

/// The scene as a view: one still frame, in the app and the widgets alike (nothing in it moves since
/// the palms went, so the 10 fps timeline that swayed them went with them).
struct SkySceneView: View {
    let horizonY: CGFloat
    let color: Color

    var body: some View {
        Canvas { context, size in
            SkyScene.draw(in: &context, rect: CGRect(origin: .zero, size: size), horizonY: horizonY, color: color)
        }
        .allowsHitTesting(false)
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
}
#endif
