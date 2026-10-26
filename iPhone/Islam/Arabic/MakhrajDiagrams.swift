import SwiftUI

#if os(iOS)

// MARK: - What the pictures show

/// The part of the tongue a close-up lights up, on the view from above.
enum MakhrajTongueRegion {
    /// The very tip (noon, the nit'iyyah, lithawiyyah and asaliyyah trios).
    case tip
    /// The tip's upper surface, a step in (raa).
    case tipTop
    /// The front edge up to the tip (laam).
    case frontEdge
    /// The two sides, against the molars (daad).
    case sides
    /// The middle (jeem, sheen, yaa).
    case middle
    /// The back, where the hard palate begins (kaaf).
    case back
    /// The very back, under the soft palate (qaaf).
    case deepBack
}

/// What the lips do, on the view from the front.
enum MakhrajLipShape {
    /// Pressed shut (baa, meem).
    case closed
    /// Rounded and open (waaw).
    case rounded
    /// The upper teeth on the inside of the lower lip (faa).
    case teethOnLip
}

/// The three bands of the throat, numbered as the exits are.
enum MakhrajThroatBand: Int, CaseIterable {
    case deepest = 2
    case middle = 3
    case upper = 4
}

/// The close-up beside the side view: the organ the exit is on, seen the way a learner can copy it.
enum MakhrajDetailPicture: Equatable {
    case tongue(MakhrajTongueRegion)
    case lips(MakhrajLipShape)
    case throat(Set<MakhrajThroatBand>)
    /// The jawf: the open channel with nothing touching.
    case hollow

    var label: String {
        switch self {
        case .tongue: return String(localized: "Tongue from above")
        case .lips: return String(localized: "Lips from the front")
        case .throat: return String(localized: "The throat")
        case .hollow: return String(localized: "The hollow")
        }
    }

    /// The close-up for a whole articulation zone (the `LetterAxis.makhraj` families).
    static func forZone(_ zoneID: String) -> MakhrajDetailPicture? {
        switch zoneID {
        case "jawf": return .hollow
        case "halq": return .throat(Set(MakhrajThroatBand.allCases))
        case "aqsaLisan": return .tongue(.back)
        case "wasatLisan": return .tongue(.middle)
        case "haffatLisan": return .tongue(.sides)
        case "tarafLisan": return .tongue(.tip)
        case "shafatan": return .lips(.closed)
        default: return nil
        }
    }
}

/// How one exit is drawn on the side view: the spot the dot marks, and which parts of the tongue,
/// roof, teeth, lips or throat are marked. Fractions run along the anatomy's contours: the tongue
/// from its tip (0) to its root (1), the roof from the edge of the upper teeth (0) to the uvula (1).
struct MakhrajExitDrawing {
    var contact: CGPoint? = nil
    var tongue: ClosedRange<CGFloat>? = nil
    var roof: ClosedRange<CGFloat>? = nil
    var throatBand: MakhrajThroatBand? = nil
    var upperLip = false
    var lowerLip = false
    var upperTeeth = false
    var lowerTeeth = false
    /// The air whistling out between the teeth (the asaliyyah trio).
    var whistle = false
    var detail: MakhrajDetailPicture? = nil

    /// The exit's drawing. `letter` picks waaw's rounded lips over the closed ones baa and meem share.
    static func of(_ exitID: Int, letter: String? = nil) -> MakhrajExitDrawing {
        switch exitID {
        case 1: return MakhrajExitDrawing(contact: CGPoint(x: 46, y: 39.3), detail: .hollow)
        case 2: return MakhrajExitDrawing(contact: CGPoint(x: 64.5, y: 88), throatBand: .deepest, detail: .throat([.deepest]))
        case 3: return MakhrajExitDrawing(contact: CGPoint(x: 65, y: 70), throatBand: .middle, detail: .throat([.middle]))
        case 4: return MakhrajExitDrawing(contact: CGPoint(x: 65.5, y: 52), throatBand: .upper, detail: .throat([.upper]))
        case 5: return MakhrajExitDrawing(contact: CGPoint(x: 57.5, y: 40), tongue: 0.74...0.9, roof: 0.8...0.95, detail: .tongue(.deepBack))
        case 6: return MakhrajExitDrawing(contact: CGPoint(x: 50.5, y: 37), tongue: 0.6...0.76, roof: 0.62...0.76, detail: .tongue(.back))
        case 7: return MakhrajExitDrawing(contact: CGPoint(x: 40, y: 38.5), tongue: 0.36...0.56, roof: 0.4...0.58, detail: .tongue(.middle))
        case 8: return MakhrajExitDrawing(contact: CGPoint(x: 45, y: 41.5), tongue: 0.3...0.66, detail: .tongue(.sides))
        case 9: return MakhrajExitDrawing(contact: CGPoint(x: 29, y: 40.5), tongue: 0.0...0.2, roof: 0.16...0.3, detail: .tongue(.frontEdge))
        case 10: return MakhrajExitDrawing(contact: CGPoint(x: 25.5, y: 43.5), tongue: 0.0...0.07, roof: 0.11...0.19, detail: .tongue(.tip))
        case 11: return MakhrajExitDrawing(contact: CGPoint(x: 27, y: 42.5), tongue: 0.04...0.15, roof: 0.12...0.21, detail: .tongue(.tipTop))
        case 12: return MakhrajExitDrawing(contact: CGPoint(x: 23.5, y: 46), tongue: 0.0...0.07, roof: 0.05...0.12, detail: .tongue(.tip))
        case 13: return MakhrajExitDrawing(contact: CGPoint(x: 23, y: 54), tongue: 0.0...0.06, lowerTeeth: true, whistle: true, detail: .tongue(.tip))
        case 14: return MakhrajExitDrawing(contact: CGPoint(x: 21.5, y: 52), tongue: 0.0...0.05, upperTeeth: true, detail: .tongue(.tip))
        case 15: return MakhrajExitDrawing(contact: CGPoint(x: 18.5, y: 52.5), lowerLip: true, upperTeeth: true, detail: .lips(.teethOnLip))
        case 16: return MakhrajExitDrawing(contact: CGPoint(x: 14, y: 50.5), upperLip: true, lowerLip: true, detail: .lips(letter == "و" ? .rounded : .closed))
        case 17: return MakhrajExitDrawing(contact: CGPoint(x: 42, y: 22.5))
        default: return MakhrajExitDrawing()
        }
    }
}

// MARK: - The colours

/// The colours of the "5 Major Areas" picture on the Makhaarij page (`Makharij1`), so the drawn
/// pictures and that one read as one set: golden skin over cream flesh, yellow bone, the khayshum
/// brick red, the jawf green, the tongue red, the halq blue, white teeth. Fixed in both appearances,
/// as the picture is. The marks are that picture's too: black dots on black leader lines, teal labels.
enum MakhrajPalette {
    static let skin = Color(red: 0.94, green: 0.76, blue: 0.34)
    static let skinEdge = Color(red: 0.78, green: 0.58, blue: 0.18)
    static let flesh = Color(red: 0.99, green: 0.88, blue: 0.60)
    static let bone = Color(red: 0.96, green: 0.91, blue: 0.52)
    static let khayshum = Color(red: 0.85, green: 0.54, blue: 0.43)
    static let khayshumDeep = Color(red: 0.71, green: 0.33, blue: 0.25)
    static let softPalate = Color(red: 0.77, green: 0.49, blue: 0.43)
    static let jawf = Color(red: 0.22, green: 0.65, blue: 0.13)
    static let tongue = Color(red: 0.80, green: 0.34, blue: 0.24)
    static let tongueLight = Color(red: 0.89, green: 0.50, blue: 0.38)
    static let tongueDeep = Color(red: 0.62, green: 0.24, blue: 0.15)
    static let lips = Color(red: 0.85, green: 0.54, blue: 0.43)
    /// The inside of an open mouth, on the view from the front.
    static let mouth = Color(red: 0.32, green: 0.10, blue: 0.08)
    static let halq = Color(red: 0.37, green: 0.50, blue: 0.85)
    static let halqDeep = Color(red: 0.22, green: 0.33, blue: 0.66)
    static let toothEdge = Color(red: 0.66, green: 0.62, blue: 0.57)
    /// The drawing's own fine lines: seams, the edges of bone.
    static let outline = Color(red: 0.36, green: 0.23, blue: 0.12)
    static let marker = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let label = Color(red: 0.29, green: 0.94, blue: 0.80)

    /// A stretch where two parts meet: teal, edged in black so it reads on every colour under it.
    static func strokeContact(_ path: Path, in context: inout GraphicsContext, scale: CGFloat, width: CGFloat = 2.2) {
        context.stroke(path, with: .color(marker), style: StrokeStyle(lineWidth: (width + 1.4) * scale, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(label), style: StrokeStyle(lineWidth: width * scale, lineCap: .round, lineJoin: .round))
    }

    /// The way air travels: a black dashed line on a white casing, legible on the drawing and off it.
    static func strokeFlow(_ path: Path, in context: inout GraphicsContext, scale: CGFloat) {
        let dash = [2.4 * scale, 2.6 * scale]
        context.stroke(path, with: .color(Color.white.opacity(0.9)), style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round, lineJoin: .round, dash: dash))
        context.stroke(path, with: .color(marker), style: StrokeStyle(lineWidth: 1.1 * scale, lineCap: .round, lineJoin: .round, dash: dash))
    }
}

// MARK: - The anatomy

/// The side view's parts, as polylines in a 100 by 100 box with the face looking left. Every curve is
/// a Catmull-Rom spline through a few hand-placed points, sampled densely so a stretch of it (the
/// tip of the tongue, the gum behind the teeth) can be lifted out by fraction and marked.
enum MakhrajAnatomy {
    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    /// The skin, forehead to neck, the lips as two bumps on the way: control points 6 to 9 are the
    /// upper lip, 9 to 12 the lower.
    static let profileControls: [CGPoint] = [p(36, 0), p(27, 10), p(22, 20), p(20, 27), p(10, 36), p(13, 41), p(15, 43.5), p(12.5, 46.5), p(12, 49), p(13.5, 50.5), p(12, 52.5), p(12.5, 55.5), p(15, 58), p(17, 63), p(24, 69), p(29, 76), p(31, 88), p(32, 100)]
    static let profile = spline(profileControls)
    static let upperLipLine = segment(profile, 6, 9)
    static let lowerLipLine = segment(profile, 9, 12)
    /// Where the picture is cut: across the top of the head and down the back of the neck.
    static let cut = spline([p(36, 0), p(62, 0), p(77, 6), p(85.5, 22), p(87.5, 50), p(87.5, 100)])
    /// The whole head, skin and cut, as one closed shape.
    static let head: [CGPoint] = profile + [p(87.5, 100)] + cut.reversed()
    /// The inside of the lips, where they rest against the teeth, and the seam between them.
    static let lipInner = spline([p(19.5, 44), p(18.5, 48), p(18.3, 51), p(18.5, 55), p(19.5, 60)])
    static let lipSeam: [CGPoint] = [p(13.5, 50.5), p(18.3, 51)]
    /// The roof of the mouth: the edge of the upper front teeth, their roots, the gum, the hard
    /// palate, the soft palate, the uvula.
    static let roof = spline([p(22.5, 52), p(23.5, 45), p(26, 42), p(31, 38.5), p(38, 35.5), p(46, 34), p(53, 34.5), p(58, 36.5), p(62, 40.5), p(63.5, 46)])
    /// The upper surface of the tongue, tip to root.
    static let tongueTop = spline([p(26.5, 55.5), p(29, 51), p(34, 47), p(41, 44.5), p(48, 44.5), p(54, 46.5), p(58.5, 50.5), p(61, 56), p(61.5, 62), p(60.5, 68)])
    /// The underside, root back to tip.
    static let tongueBottom = spline([p(60.5, 68), p(56, 70.5), p(49, 69), p(40, 65.5), p(32, 62), p(27, 59.5), p(26.5, 55.5)])
    static let tongue: [CGPoint] = tongueTop + tongueBottom.dropFirst()
    /// The floor of the nose, back to front: the top of the palate.
    private static let nasalFloor: [CGPoint] = [p(66, 45.5), p(63.5, 41), p(60, 36.5), p(53, 32.5), p(44, 31.3), p(34, 33), p(26, 37.5), p(19, 41)]
    /// The nasal passage, nostril to the space behind the soft palate: the khayshum.
    static let nasal = spline([p(12.5, 40), p(15.5, 34), p(22, 28), p(26.5, 21), p(33, 15.5), p(43, 13.5), p(55, 14.5), p(65, 18.5), p(70.5, 25.5), p(71.5, 35), p(71.3, 45.5)] + nasalFloor, closed: true)
    /// The palate, from the roof of the mouth up to the floor of the nose: bone in front, the soft
    /// palate behind.
    static let palate: [CGPoint] = segment(roof, 1, 9) + spline(nasalFloor + [p(19.8, 44.2)])
    /// The lower jaw, under the tongue.
    static let mandible = spline([p(22.5, 62.5), p(26, 60.8), p(32, 63.2), p(40, 66.8), p(49, 70.2), p(54.5, 72.5), p(51, 76), p(41, 76.2), p(32.5, 74.5), p(28, 71), p(24, 66.5)], closed: true)
    /// The back wall of the throat.
    static let throatBack = spline([p(71.3, 40), p(71.5, 44), p(72, 56), p(72, 70), p(71.5, 84), p(71, 100)])
    /// The front wall, from the root of the tongue down past the voice box.
    static let throatFront = spline([p(60.5, 68), p(59, 74), p(58, 80), p(57.5, 86), p(57, 92), p(56.5, 100)])
    /// The air: the mouth between the tongue and the roof, then the throat down past the voice box.
    static let airway: [CGPoint] = [p(18.4, 50.6)] + roof + [p(66, 45.5), p(71.3, 45.5)] + segment(throatBack, 2, 5)
        + throatFront.reversed() + tongueTop.reversed().dropFirst() + [p(24.5, 55.6), p(22.5, 54.4), p(19.5, 53.4), p(18.4, 52)]
    /// The part of the air painted as the throat: behind the tongue, and everything below it.
    static let halqRegion: [CGRect] = [CGRect(x: 61.5, y: 0, width: 38.5, height: 100), CGRect(x: 0, y: 63, width: 100, height: 37)]
    static let upperTooth: [CGPoint] = [p(20.5, 44.5), p(24.5, 44.5), p(24, 51.5), p(22.5, 52.5), p(21, 51.5)]
    static let lowerTooth: [CGPoint] = [p(20.5, 62), p(24.5, 62), p(24, 55.5), p(22.5, 54.5), p(21, 55.5)]
    /// The open channel from the voice box out between the lips: the jawf.
    static let channel = spline([p(64.5, 94), p(65, 78), p(65, 62), p(60, 49), p(50, 40.5), p(38, 41), p(28, 46), p(20, 50), p(11, 50)])
    /// The three bands of the throat, as boxes between its walls.
    static func throatBand(_ band: MakhrajThroatBand) -> CGRect {
        switch band {
        case .upper: return CGRect(x: 59, y: 46, width: 11.5, height: 12)
        case .middle: return CGRect(x: 59, y: 63, width: 12, height: 14)
        case .deepest: return CGRect(x: 58.5, y: 82, width: 12, height: 13)
        }
    }

    // MARK: Curves

    /// A uniform Catmull-Rom spline through the points, `samples` steps per segment.
    static func spline(_ points: [CGPoint], closed: Bool = false, samples: Int = 12) -> [CGPoint] {
        guard points.count > 2 else { return points }
        let n = points.count
        func at(_ i: Int) -> CGPoint {
            if closed { return points[((i % n) + n) % n] }
            return points[min(max(i, 0), n - 1)]
        }
        var out: [CGPoint] = []
        let segments = closed ? n : n - 1
        for i in 0..<segments {
            let p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2)
            for s in 0..<samples {
                let t = CGFloat(s) / CGFloat(samples)
                let t2 = t * t, t3 = t2 * t
                let x = 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
                let y = 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
                out.append(CGPoint(x: x, y: y))
            }
        }
        if !closed { out.append(points[n - 1]) }
        return out
    }

    /// The stretch of a spline between two of its control points (every control point is `samples`
    /// points apart in the sampled polyline).
    static func segment(_ points: [CGPoint], _ from: Int, _ to: Int, samples: Int = 12) -> [CGPoint] {
        guard !points.isEmpty else { return points }
        let low = max(0, min(points.count - 1, from * samples))
        let high = max(low, min(points.count - 1, to * samples))
        return Array(points[low...high])
    }

    /// The stretch of a polyline between two fractions of its length.
    static func slice(_ points: [CGPoint], _ range: ClosedRange<CGFloat>) -> [CGPoint] {
        guard points.count > 1 else { return points }
        var cumulative: [CGFloat] = [0]
        cumulative.reserveCapacity(points.count)
        for i in 1..<points.count {
            cumulative.append(cumulative[i - 1] + hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y))
        }
        let total = cumulative[points.count - 1]
        let low = range.lowerBound * total, high = range.upperBound * total
        var out: [CGPoint] = []
        for i in points.indices where cumulative[i] >= low && cumulative[i] <= high {
            out.append(points[i])
        }
        return out
    }

    /// A point along a polyline, and the direction of travel there, at a fraction of its length.
    static func along(_ points: [CGPoint], _ fraction: CGFloat) -> (point: CGPoint, tangent: CGPoint) {
        guard points.count > 1 else { return (points.first ?? .zero, CGPoint(x: 1, y: 0)) }
        var lengths: [CGFloat] = []
        var total: CGFloat = 0
        for i in 1..<points.count {
            let d = hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
            lengths.append(d)
            total += d
        }
        var target = max(0, min(1, fraction)) * total
        for i in 0..<lengths.count {
            if target <= lengths[i] || i == lengths.count - 1 {
                let t = lengths[i] > 0 ? target / lengths[i] : 0
                let a = points[i], b = points[i + 1]
                let point = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
                let length = max(lengths[i], 0.0001)
                return (point, CGPoint(x: (b.x - a.x) / length, y: (b.y - a.y) / length))
            }
            target -= lengths[i]
        }
        return (points[points.count - 1], CGPoint(x: 1, y: 0))
    }
}

extension Path {
    init(polyline: [CGPoint], closed: Bool = false) {
        self.init()
        guard let first = polyline.first else { return }
        move(to: first)
        for point in polyline.dropFirst() { addLine(to: point) }
        if closed { closeSubpath() }
    }
}

// MARK: - The side view

/// A cut through the head, face to the left, coloured as the Makhaarij page's picture is: nose and
/// nasal passage, lips and teeth, palate and uvula, tongue, and the throat down to the voice box. The
/// exits asked for are marked with a black dot, and the parts that meet there are drawn in teal.
struct MakhrajSideView: View {
    let exits: [Int]
    var letter: String? = nil
    /// Whether each dot carries its exit number beside it.
    var numbered = true

    private var drawings: [(id: Int, drawing: MakhrajExitDrawing)] {
        exits.map { ($0, MakhrajExitDrawing.of($0, letter: letter)) }
    }

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let scale = side / 100
            let transform = CGAffineTransform(translationX: (size.width - side) / 2, y: (size.height - side) / 2)
                .scaledBy(x: scale, y: scale)
            func path(_ points: [CGPoint], closed: Bool = false) -> Path {
                Path(polyline: points, closed: closed).applying(transform)
            }
            func point(_ p: CGPoint) -> CGPoint { p.applying(transform) }
            func line(_ width: CGFloat) -> StrokeStyle {
                StrokeStyle(lineWidth: width * scale, lineCap: .round, lineJoin: .round)
            }
            typealias C = MakhrajPalette

            let all = drawings
            let head = path(MakhrajAnatomy.head, closed: true)

            // The flesh, then the bone of both jaws, the soft palate behind the hard.
            context.fill(head, with: .color(C.flesh))
            let mandible = path(MakhrajAnatomy.mandible, closed: true)
            context.fill(mandible, with: .color(C.bone))
            context.stroke(mandible, with: .color(C.skinEdge.opacity(0.5)), style: line(0.5))
            let palate = path(MakhrajAnatomy.palate, closed: true)
            context.fill(palate, with: .color(C.bone))
            context.drawLayer { layer in
                layer.clip(to: Path(CGRect(x: 53, y: 0, width: 47, height: 100)).applying(transform))
                layer.fill(palate, with: .color(C.softPalate))
            }
            context.stroke(palate, with: .color(C.skinEdge.opacity(0.5)), style: line(0.5))

            // The air: the mouth green (the jawf), the throat blue (the halq).
            let airway = path(MakhrajAnatomy.airway, closed: true)
            context.fill(airway, with: .color(C.jawf))
            context.drawLayer { layer in
                var region = Path()
                for box in MakhrajAnatomy.halqRegion { region.addRect(box) }
                layer.clip(to: region.applying(transform))
                layer.fill(airway, with: .color(C.halq))
            }

            // The nasal passage, the khayshum, deepening toward the back.
            let nasal = path(MakhrajAnatomy.nasal, closed: true)
            context.fill(nasal, with: .linearGradient(Gradient(colors: [C.khayshum, C.khayshumDeep]),
                                                     startPoint: point(CGPoint(x: 24, y: 22)), endPoint: point(CGPoint(x: 70, y: 42))))
            context.stroke(nasal, with: .color(C.khayshumDeep), style: line(0.6))

            // The tongue: its muscle fanning up from the root, a lighter rim along the top.
            let tongue = path(MakhrajAnatomy.tongue, closed: true)
            context.fill(tongue, with: .color(C.tongue))
            context.drawLayer { layer in
                layer.clip(to: tongue)
                var fibres = Path()
                var fraction: CGFloat = 0.08
                while fraction < 0.86 {
                    fibres.move(to: point(CGPoint(x: 50, y: 67)))
                    fibres.addLine(to: point(MakhrajAnatomy.along(MakhrajAnatomy.tongueTop, fraction).point))
                    fraction += 0.055
                }
                layer.stroke(fibres, with: .color(C.tongueDeep.opacity(0.35)), style: line(0.45))
                layer.stroke(path(MakhrajAnatomy.tongueTop), with: .color(C.tongueLight), style: line(2.2))
            }
            context.stroke(tongue, with: .color(C.tongueDeep), style: line(0.8))

            // The uvula's bulb.
            let uvula = CGRect(x: 62.2, y: 45.2, width: 2.8, height: 2.8).applying(transform)
            context.fill(Path(ellipseIn: uvula), with: .color(C.softPalate))
            context.stroke(Path(ellipseIn: uvula), with: .color(C.tongueDeep.opacity(0.7)), style: line(0.5))

            // The throat's walls, the epiglottis over the voice box, and the vocal cords.
            context.stroke(path(MakhrajAnatomy.throatBack), with: .color(C.halqDeep), style: line(0.8))
            context.stroke(path(MakhrajAnatomy.throatFront), with: .color(C.halqDeep), style: line(0.8))
            var epiglottis = Path()
            epiglottis.move(to: point(CGPoint(x: 60.4, y: 70)))
            epiglottis.addQuadCurve(to: point(CGPoint(x: 64, y: 62.5)), control: point(CGPoint(x: 64.2, y: 68)))
            context.stroke(epiglottis, with: .color(Color.white.opacity(0.85)), style: line(1.3))
            var cords = Path()
            cords.move(to: point(CGPoint(x: 57.5, y: 90)))
            cords.addLine(to: point(CGPoint(x: 63.5, y: 89.5)))
            context.stroke(cords, with: .color(C.halqDeep), style: line(1.4))

            // The teeth: white in either appearance, teal when they are one of the parts that meet.
            for (outline, lit) in [(MakhrajAnatomy.upperTooth, all.contains { $0.drawing.upperTeeth }),
                                   (MakhrajAnatomy.lowerTooth, all.contains { $0.drawing.lowerTeeth })] {
                let tooth = path(outline, closed: true)
                context.fill(tooth, with: .color(lit ? C.label : Color.white))
                context.stroke(tooth, with: .color(lit ? C.marker : C.toothEdge), style: line(lit ? 0.8 : 0.6))
            }

            // The skin: a golden band inside the profile, the lips' seam, the outline over everything.
            context.drawLayer { layer in
                layer.clip(to: head)
                layer.stroke(path(MakhrajAnatomy.profile), with: .color(C.skin), style: line(5))
            }
            context.stroke(path(MakhrajAnatomy.lipInner), with: .color(C.outline.opacity(0.35)), style: line(0.6))
            context.stroke(path(MakhrajAnatomy.lipSeam), with: .color(C.outline.opacity(0.6)), style: line(0.7))
            context.stroke(path(MakhrajAnatomy.profile), with: .color(C.skinEdge), style: line(0.9))
            context.stroke(path(MakhrajAnatomy.cut), with: .color(C.skinEdge.opacity(0.55)), style: line(0.7))

            // The parts that meet: lips, tongue, roof, throat band.
            if all.contains(where: { $0.drawing.upperLip }) {
                C.strokeContact(path(MakhrajAnatomy.upperLipLine), in: &context, scale: scale)
            }
            if all.contains(where: { $0.drawing.lowerLip }) {
                C.strokeContact(path(MakhrajAnatomy.lowerLipLine), in: &context, scale: scale)
            }
            for (_, drawing) in all {
                if let range = drawing.tongue {
                    C.strokeContact(path(MakhrajAnatomy.slice(MakhrajAnatomy.tongueTop, range)), in: &context, scale: scale)
                }
                if let range = drawing.roof {
                    C.strokeContact(path(MakhrajAnatomy.slice(MakhrajAnatomy.roof, range)), in: &context, scale: scale)
                }
                if let band = drawing.throatBand {
                    let box = MakhrajAnatomy.throatBand(band).applying(transform)
                    let shape = Path(roundedRect: box, cornerRadius: 3.5 * scale, style: .continuous)
                    context.fill(shape, with: .color(C.label.opacity(0.55)))
                    context.stroke(shape, with: .color(C.marker), style: StrokeStyle(lineWidth: 0.8 * scale, dash: [2.6 * scale, 2 * scale]))
                }
            }

            // The air on its way: out between the teeth (the whistle), out through the nose (the
            // ghunnah), and through the whole open channel (the jawf).
            for (id, drawing) in all {
                if drawing.whistle {
                    var air = Path()
                    air.move(to: point(CGPoint(x: 20.5, y: 53.5)))
                    air.addLine(to: point(CGPoint(x: 6, y: 51.5)))
                    C.strokeFlow(air, in: &context, scale: scale)
                    Self.drawArrowhead(at: CGPoint(x: 6, y: 51.5), direction: CGPoint(x: -1, y: -0.14), in: &context, transform: transform, scale: scale)
                }
                if id == 17 {
                    var air = Path()
                    air.move(to: point(CGPoint(x: 30, y: 26)))
                    air.addQuadCurve(to: point(CGPoint(x: 8.5, y: 42.5)), control: point(CGPoint(x: 15, y: 30)))
                    C.strokeFlow(air, in: &context, scale: scale)
                    Self.drawArrowhead(at: CGPoint(x: 8.5, y: 42.5), direction: CGPoint(x: -0.6, y: 0.8), in: &context, transform: transform, scale: scale)
                }
                if id == 1 {
                    Self.drawArrow(along: MakhrajAnatomy.channel, in: &context, transform: transform, scale: scale)
                }
            }

            // The dots, last, on top of everything: each numbered one on a leader line to a teal
            // label, as the Makhaarij page's picture labels its areas.
            let marked = all.compactMap { entry in entry.drawing.contact.map { (id: entry.id, spot: $0) } }
            func badgeCenter(_ id: Int, _ spot: CGPoint) -> CGPoint {
                let offset = Self.badgeOffset(for: id)
                return point(CGPoint(x: spot.x + offset.x, y: spot.y + offset.y))
            }
            if numbered {
                for (id, spot) in marked {
                    var leader = Path()
                    leader.move(to: point(spot))
                    leader.addLine(to: badgeCenter(id, spot))
                    context.stroke(leader, with: .color(Color.white.opacity(0.9)), style: line(1.9))
                    context.stroke(leader, with: .color(C.marker), style: line(0.8))
                }
            }
            for (_, spot) in marked {
                let center = point(spot)
                // Several unnumbered dots (a zone's page) sit a few units apart: smaller, so they read as
                // a cluster of exits rather than one blob.
                let dot = (numbered ? 3.1 : 2.2) * scale, ring = dot + 0.9 * scale
                context.fill(Path(ellipseIn: CGRect(x: center.x - ring, y: center.y - ring, width: ring * 2, height: ring * 2)), with: .color(Color.white))
                context.fill(Path(ellipseIn: CGRect(x: center.x - dot, y: center.y - dot, width: dot * 2, height: dot * 2)), with: .color(C.marker))
            }
            if numbered {
                for (id, spot) in marked {
                    let at = badgeCenter(id, spot)
                    let radius = 4.6 * scale
                    let badge = Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2))
                    context.fill(badge, with: .color(C.label))
                    context.stroke(badge, with: .color(C.marker), style: line(0.7))
                    context.draw(
                        Text(verbatim: "\(id)".localizedDigits)
                            .font(.system(size: 6.4 * scale, weight: .bold, design: .rounded))
                            .foregroundColor(C.marker),
                        at: at,
                        anchor: .center
                    )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Where an exit's label sits, at the end of its leader line, clear of the other parts.
    private static func badgeOffset(for id: Int) -> CGPoint {
        switch id {
        case 1: return CGPoint(x: 0, y: -12)
        case 2, 3, 4: return CGPoint(x: 12.5, y: 0)
        case 5: return CGPoint(x: 9, y: -8)
        case 6: return CGPoint(x: 0, y: -11)
        case 7: return CGPoint(x: 0, y: -11)
        case 8: return CGPoint(x: 10, y: 9)
        case 9: return CGPoint(x: 6, y: -10)
        case 10, 11, 12, 13, 14: return CGPoint(x: 11, y: 7.5)
        case 15, 16: return CGPoint(x: -8, y: 10)
        case 17: return CGPoint(x: 13, y: -5)
        default: return CGPoint(x: 11, y: 0)
        }
    }

    /// The way air travels along a polyline, with an arrowhead at its end.
    static func drawArrow(along points: [CGPoint], in context: inout GraphicsContext, transform: CGAffineTransform, scale: CGFloat) {
        MakhrajPalette.strokeFlow(Path(polyline: points).applying(transform), in: &context, scale: scale)
        let end = MakhrajAnatomy.along(points, 1)
        drawArrowhead(at: end.point, direction: end.tangent, in: &context, transform: transform, scale: scale)
    }

    static func drawArrowhead(at tip: CGPoint, direction: CGPoint, in context: inout GraphicsContext, transform: CGAffineTransform, scale: CGFloat) {
        let length = hypot(direction.x, direction.y)
        guard length > 0 else { return }
        let d = CGPoint(x: direction.x / length, y: direction.y / length)
        let n = CGPoint(x: -d.y, y: d.x)
        let size: CGFloat = 3.6
        var head = Path()
        head.move(to: tip.applying(transform))
        head.addLine(to: CGPoint(x: tip.x - d.x * size + n.x * size * 0.6, y: tip.y - d.y * size + n.y * size * 0.6).applying(transform))
        head.addLine(to: CGPoint(x: tip.x - d.x * size - n.x * size * 0.6, y: tip.y - d.y * size - n.y * size * 0.6).applying(transform))
        head.closeSubpath()
        context.stroke(head, with: .color(Color.white.opacity(0.9)), style: StrokeStyle(lineWidth: 1.3 * scale, lineJoin: .round))
        context.fill(head, with: .color(MakhrajPalette.marker))
    }
}

// MARK: - The close-ups

/// The organ on its own, drawn large in the same colours: the tongue from above with its region in
/// teal, the lips from the front doing what the letter needs, or the throat as a tube with its three
/// bands.
struct MakhrajDetailView: View {
    let picture: MakhrajDetailPicture

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let scale = side / 100
            let transform = CGAffineTransform(translationX: (size.width - side) / 2, y: (size.height - side) / 2)
                .scaledBy(x: scale, y: scale)
            switch picture {
            case .tongue(let region):
                Self.drawTongue(region, in: &context, transform: transform, scale: scale)
            case .lips(let shape):
                Self.drawLips(shape, in: &context, transform: transform, scale: scale)
            case .throat(let bands):
                Self.drawThroat(bands, in: &context, transform: transform, scale: scale)
            case .hollow:
                Self.drawHollow(in: &context, transform: transform, scale: scale)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static func line(_ scale: CGFloat, _ width: CGFloat = 1.1) -> StrokeStyle {
        StrokeStyle(lineWidth: max(1, width * scale * 0.75), lineCap: .round, lineJoin: .round)
    }

    // MARK: Tongue from above

    /// The tongue, tip at the top, inside the arch of the upper teeth.
    private static let tongueOutline = MakhrajAnatomy.spline([p(50, 14), p(60, 15.5), p(70, 22), p(76, 34), p(78, 48), p(77, 62), p(76, 76), p(75, 92), p(25, 92), p(24, 76), p(23, 62), p(22, 48), p(24, 34), p(30, 22), p(40, 15.5)], closed: true)
    private static let dentalArch = MakhrajAnatomy.spline([p(9, 96), p(8.5, 70), p(10, 48), p(16, 30), p(26, 16), p(38, 8), p(50, 6), p(62, 8), p(74, 16), p(84, 30), p(90, 48), p(91.5, 70), p(91, 96)])

    private static func drawTongue(_ region: MakhrajTongueRegion, in context: inout GraphicsContext, transform: CGAffineTransform, scale: CGFloat) {
        typealias C = MakhrajPalette
        // The gums, then the teeth along them, a fine line between each.
        let arch = Path(polyline: dentalArch).applying(transform)
        context.stroke(arch, with: .color(C.softPalate), style: StrokeStyle(lineWidth: 9 * scale, lineCap: .round, lineJoin: .round))
        context.stroke(arch, with: .color(Color.white), style: StrokeStyle(lineWidth: 5.6 * scale, lineCap: .butt, lineJoin: .round))
        var ticks = Path()
        var fraction: CGFloat = 0.045
        while fraction < 0.98 {
            let (point, tangent) = MakhrajAnatomy.along(dentalArch, fraction)
            let normal = CGPoint(x: -tangent.y, y: tangent.x)
            ticks.move(to: CGPoint(x: point.x + normal.x * 2.8, y: point.y + normal.y * 2.8).applying(transform))
            ticks.addLine(to: CGPoint(x: point.x - normal.x * 2.8, y: point.y - normal.y * 2.8).applying(transform))
            fraction += 0.072
        }
        context.stroke(ticks, with: .color(C.toothEdge), style: line(scale, 0.8))

        let tongue = Path(polyline: tongueOutline, closed: true).applying(transform)
        context.fill(tongue, with: .color(C.tongue))
        var groove = Path()
        groove.move(to: p(50, 22).applying(transform))
        groove.addLine(to: p(50, 86).applying(transform))
        context.stroke(groove, with: .color(C.tongueDeep.opacity(0.6)), style: line(scale, 1))

        // The region, in teal and edged in black, clipped to the tongue.
        context.drawLayer { layer in
            layer.clip(to: tongue)
            let fill = GraphicsContext.Shading.color(C.label)
            let edge = GraphicsContext.Shading.color(C.marker)
            func area(_ shape: Path) {
                layer.fill(shape, with: fill)
                layer.stroke(shape, with: edge, style: StrokeStyle(lineWidth: 1.2 * scale))
            }
            func rim(_ width: CGFloat) {
                layer.stroke(tongue, with: edge, style: StrokeStyle(lineWidth: (width + 2.4) * scale, lineCap: .round, lineJoin: .round))
                layer.stroke(tongue, with: fill, style: StrokeStyle(lineWidth: width * scale, lineCap: .round, lineJoin: .round))
            }
            switch region {
            case .tip:
                area(Path(CGRect(x: 0, y: 0, width: 100, height: 25).applying(transform)))
            case .tipTop:
                area(Path(ellipseIn: CGRect(x: 37, y: 17, width: 26, height: 15).applying(transform)))
            case .frontEdge:
                layer.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 50).applying(transform)))
                rim(9)
            case .sides:
                layer.clip(to: Path(CGRect(x: 0, y: 28, width: 100, height: 54).applying(transform)))
                rim(10)
            case .middle:
                area(Path(ellipseIn: CGRect(x: 31, y: 37, width: 38, height: 30).applying(transform)))
            case .back:
                area(Path(CGRect(x: 0, y: 63, width: 100, height: 17).applying(transform)))
            case .deepBack:
                area(Path(CGRect(x: 0, y: 79, width: 100, height: 21).applying(transform)))
            }
        }

        context.stroke(tongue, with: .color(C.tongueDeep), style: line(scale, 1.3))
    }

    // MARK: Lips from the front

    private static let upperLipClosed = MakhrajAnatomy.spline([p(10, 50), p(22, 43), p(36, 38.5), p(46, 40), p(50, 42), p(54, 40), p(64, 38.5), p(78, 43), p(90, 50), p(72, 51.5), p(50, 52.5), p(28, 51.5)], closed: true)
    private static let lowerLipClosed = MakhrajAnatomy.spline([p(10, 50), p(28, 51.5), p(50, 52.5), p(72, 51.5), p(90, 50), p(78, 58), p(64, 64.5), p(50, 66), p(36, 64.5), p(22, 58)], closed: true)
    private static let seam = MakhrajAnatomy.spline([p(10, 50), p(28, 51.5), p(50, 52.5), p(72, 51.5), p(90, 50)])
    private static let upperLipRaised = MakhrajAnatomy.spline([p(10, 46), p(22, 38), p(36, 33.5), p(46, 35), p(50, 37), p(54, 35), p(64, 33.5), p(78, 38), p(90, 46), p(72, 44.5), p(50, 43.5), p(28, 44.5)], closed: true)
    private static let lowerLipUnderTeeth = MakhrajAnatomy.spline([p(10, 53), p(28, 51.5), p(50, 51), p(72, 51.5), p(90, 53), p(78, 60), p(64, 66), p(50, 67.5), p(36, 66), p(22, 60)], closed: true)
    private static let lowerLipEdge = MakhrajAnatomy.spline([p(10, 53), p(28, 51.5), p(50, 51), p(72, 51.5), p(90, 53)])

    private static func drawLips(_ shape: MakhrajLipShape, in context: inout GraphicsContext, transform: CGAffineTransform, scale: CGFloat) {
        typealias C = MakhrajPalette
        // The skin around the mouth, in the side view's golden edge.
        let face = Path(roundedRect: CGRect(x: 3, y: 20, width: 94, height: 62).applying(transform), cornerRadius: 24 * scale, style: .continuous)
        context.fill(face, with: .color(C.flesh))
        context.stroke(face, with: .color(C.skin), style: StrokeStyle(lineWidth: 2.4 * scale))
        func lip(_ outline: [CGPoint]) {
            let shape = Path(polyline: outline, closed: true).applying(transform)
            context.fill(shape, with: .color(C.lips))
            context.stroke(shape, with: .color(C.tongueDeep.opacity(0.75)), style: line(scale, 1.2))
        }
        switch shape {
        case .closed:
            lip(upperLipClosed)
            lip(lowerLipClosed)
            C.strokeContact(Path(polyline: seam).applying(transform), in: &context, scale: scale, width: 1.8)
        case .rounded:
            let outer = Path(ellipseIn: CGRect(x: 22, y: 25, width: 56, height: 50).applying(transform))
            let inner = Path(ellipseIn: CGRect(x: 39, y: 40, width: 22, height: 20).applying(transform))
            context.fill(outer, with: .color(C.lips))
            context.stroke(outer, with: .color(C.tongueDeep.opacity(0.75)), style: line(scale, 1.2))
            context.fill(inner, with: .color(C.mouth))
            // The pucker: a few creases around the opening.
            var creases = Path()
            for i in 0..<8 {
                let angle = CGFloat(i) / 8 * .pi * 2 + .pi / 8
                let from = p(50 + cos(angle) * 14.5, 50 + sin(angle) * 13.5)
                let to = p(50 + cos(angle) * 20, 50 + sin(angle) * 18.5)
                creases.move(to: from.applying(transform))
                creases.addLine(to: to.applying(transform))
            }
            context.stroke(creases, with: .color(C.tongueDeep.opacity(0.5)), style: line(scale, 0.9))
            C.strokeContact(inner, in: &context, scale: scale, width: 1.8)
        case .teethOnLip:
            context.fill(Path(ellipseIn: CGRect(x: 14, y: 41, width: 72, height: 14).applying(transform)), with: .color(C.mouth))
            lip(upperLipRaised)
            // The upper front teeth, resting on the inside of the lower lip.
            var x: CGFloat = 29
            for i in 0..<6 {
                let width: CGFloat = i == 2 || i == 3 ? 8 : 6.5
                let tooth = Path(roundedRect: CGRect(x: x, y: 43, width: width, height: i == 2 || i == 3 ? 11.5 : 10).applying(transform), cornerRadius: 1.6 * scale, style: .continuous)
                // Teeth are white in either appearance; the system background made them black at night.
                context.fill(tooth, with: .color(Color.white))
                context.stroke(tooth, with: .color(C.toothEdge), style: line(scale, 1))
                x += width + 0.8
            }
            lip(lowerLipUnderTeeth)
            C.strokeContact(Path(polyline: lowerLipEdge).applying(transform), in: &context, scale: scale, width: 1.8)
        }
    }

    // MARK: The throat

    private static func drawThroat(_ bands: Set<MakhrajThroatBand>, in context: inout GraphicsContext, transform: CGAffineTransform, scale: CGFloat) {
        typealias C = MakhrajPalette
        // The neck around the tube, then the tube, flaring at the top where the mouth begins.
        let neck = Path(roundedRect: CGRect(x: 12, y: 2, width: 52, height: 96).applying(transform), cornerRadius: 9 * scale, style: .continuous)
        context.fill(neck, with: .color(C.flesh))
        context.stroke(neck, with: .color(C.skin), style: StrokeStyle(lineWidth: 2 * scale))
        let left = MakhrajAnatomy.spline([p(17, 4), p(22.5, 12), p(25, 24), p(25.5, 50), p(25, 76), p(24.5, 96)])
        let right = MakhrajAnatomy.spline([p(59, 4), p(53.5, 12), p(51, 24), p(50.5, 50), p(51, 76), p(51.5, 96)])
        let tube = Path(polyline: left + right.reversed(), closed: true).applying(transform)
        context.fill(tube, with: .color(C.halq))
        context.stroke(Path(polyline: left).applying(transform), with: .color(C.halqDeep), style: line(scale, 1.6))
        context.stroke(Path(polyline: right).applying(transform), with: .color(C.halqDeep), style: line(scale, 1.6))

        let boxes: [(MakhrajThroatBand, CGRect, String)] = [
            (.upper, CGRect(x: 28, y: 22, width: 20, height: 20), String(localized: "Upper")),
            (.middle, CGRect(x: 28, y: 46, width: 20, height: 20), String(localized: "Middle")),
            (.deepest, CGRect(x: 28, y: 70, width: 20, height: 20), String(localized: "Deepest")),
        ]
        for (band, box, name) in boxes {
            let lit = bands.contains(band)
            let shape = Path(roundedRect: box.applying(transform), cornerRadius: 4 * scale, style: .continuous)
            context.fill(shape, with: .color(lit ? C.label : Color.white.opacity(0.18)))
            context.stroke(shape, with: .color(lit ? C.marker : Color.white.opacity(0.6)), style: line(scale, lit ? 1.6 : 1))
            context.draw(
                Text(verbatim: "\(band.rawValue)".localizedDigits)
                    .font(.system(size: 9 * scale, weight: .bold, design: .rounded))
                    .foregroundColor(lit ? C.marker : Color.white.opacity(0.9)),
                at: CGPoint(x: box.midX, y: box.midY).applying(transform),
                anchor: .center
            )
            // The names sit on the card, off the drawing, so they take the appearance's own text colours.
            context.draw(
                Text(verbatim: name)
                    .font(.system(size: 6.8 * scale, weight: lit ? .semibold : .regular))
                    .foregroundColor(lit ? .primary : .secondary),
                at: p(68, box.midY).applying(transform),
                anchor: .leading
            )
        }
        // The vocal cords at the bottom.
        var cords = Path()
        cords.move(to: p(25, 94).applying(transform))
        cords.addLine(to: p(51, 94).applying(transform))
        context.stroke(cords, with: .color(C.halqDeep), style: line(scale, 1.8))
    }

    // MARK: The hollow

    private static func drawHollow(in context: inout GraphicsContext, transform: CGAffineTransform, scale: CGFloat) {
        typealias C = MakhrajPalette
        // The channel as the side view paints it: green air inside cream flesh with a golden edge.
        let centre = MakhrajAnatomy.spline([p(44, 96), p(44, 72), p(42, 52), p(34, 38), p(20, 30), p(4, 30)])
        let channel = Path(polyline: centre).applying(transform)
        context.stroke(channel, with: .color(C.skin), style: StrokeStyle(lineWidth: 29 * scale, lineCap: .butt, lineJoin: .round))
        context.stroke(channel, with: .color(C.flesh), style: StrokeStyle(lineWidth: 26 * scale, lineCap: .butt, lineJoin: .round))
        context.stroke(channel, with: .color(C.jawf), style: StrokeStyle(lineWidth: 18 * scale, lineCap: .butt, lineJoin: .round))
        MakhrajSideView.drawArrow(along: centre, in: &context, transform: transform, scale: scale)
        var cords = Path()
        cords.move(to: p(33, 93).applying(transform))
        cords.addLine(to: p(55, 93).applying(transform))
        context.stroke(cords, with: .color(C.halqDeep), style: line(scale, 1.8))
        // Two short lines on the card, off the drawing: one long one ran off the card's edge.
        // One phrase for the translator, a line break where the card wraps it.
        let lines = String(localized: "nothing\ntouches", comment: "Two short lines on the jawf diagram: keep the line break.")
        for (index, word) in lines.components(separatedBy: "\n").enumerated() {
            context.draw(
                Text(verbatim: word)
                    .font(.system(size: 6.8 * scale, weight: .semibold))
                    .foregroundColor(.primary),
                at: p(79, 66 + CGFloat(index) * 8.5).applying(transform),
                anchor: .center
            )
        }
    }
}

// MARK: - The row

/// One picture card: the drawing, square, with its caption under it.
struct MakhrajPictureCard<Picture: View>: View {
    let label: String
    @ViewBuilder let picture: () -> Picture

    var body: some View {
        VStack(spacing: 6) {
            picture()
                .frame(maxWidth: .infinity)
                .padding(4)

            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }
}

/// The pictures for one or more exits: the side view with the exits marked, and the close-up of
/// the organ beside it. A letter's page shows its exit; an exit's family page shows the same pair;
/// a zone's page marks every exit in the zone on one side view, unnumbered, next to the zone's organ.
struct MakhrajPicturesRow: View {
    let exits: [LetterMakhraj]
    var letter: String? = nil
    /// The close-up; nil picks the first exit's own. The khayshum has none and shows the side view alone.
    var detail: MakhrajDetailPicture? = nil
    var numbered = true

    private var closeUp: MakhrajDetailPicture? {
        detail ?? exits.first.flatMap { MakhrajExitDrawing.of($0.id, letter: letter).detail }
    }

    private var summary: String {
        exits.map { String(localized: "exit \($0.id), \($0.place.lowercased())") }
            .joined(separator: AppLanguage.isArabicScript ? "\u{061B} " : "; ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MakhrajPictureCard(label: String(localized: "Side view")) {
                MakhrajSideView(exits: exits.map(\.id), letter: letter, numbered: numbered)
            }
            // Alone (the khayshum), the side view is held to a card's width rather than the whole row.
            .frame(maxWidth: closeUp == nil ? 230 : .infinity)

            if let closeUp {
                MakhrajPictureCard(label: closeUp.label) {
                    MakhrajDetailView(picture: closeUp)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Where it is made: \(summary)")
    }
}

// MARK: - The Makhaarij page's pictures

/// The two pictures at the top of the Makhaarij page, with letters picked out on them: on the first,
/// the letter's area (its black dot, its teal name, the letter in the box beside it); on the second,
/// the letter itself, written where it is made. The boxes are in each JPG's own pixels, measured off
/// the pictures, and keyed by exit as well as letter, so a page about one exit lights that exit only
/// (waaw's jawf line on the jawf page, its lips on the lips page).
enum MakhrajChart: CaseIterable {
    /// `Makharij1`, "Definition of 5 Major Areas".
    case areas
    /// `Makharij2`, the grey head with every letter written at its place.
    case places

    var assetName: String { self == .areas ? "Makharij1" : "Makharij2" }
    var label: String { self == .areas ? String(localized: "The five areas") : String(localized: "Every letter's place") }
    private var pixelSize: CGSize { self == .areas ? CGSize(width: 1024, height: 561) : CGSize(width: 1600, height: 1257) }
    var aspectRatio: CGFloat { pixelSize.width / pixelSize.height }

    /// The marks for these letters at these exits, as fractions of the picture. Empty when the picture
    /// does not show them: the second writes no madd letters, so alif is not on it.
    func marks(letters: [String], exits: Set<Int>) -> [CGRect] {
        var boxes: [CGRect] = []
        func add(_ box: CGRect) { if !boxes.contains(box) { boxes.append(box) } }
        for letter in letters {
            switch self {
            case .areas:
                for (area, glyphs) in Self.areaTable[letter] ?? [] where !area.exits.isDisjoint(with: exits) {
                    area.boxes.forEach(add)
                    glyphs.forEach(add)
                }
            case .places:
                for (exit, box) in Self.placeTable[letter] ?? [] where exits.contains(exit) {
                    add(box)
                }
            }
        }
        return boxes.map {
            CGRect(x: $0.minX / pixelSize.width, y: $0.minY / pixelSize.height,
                   width: $0.width / pixelSize.width, height: $0.height / pixelSize.height)
        }
    }

    /// The exits a letter's page marks: its own, and the ghunnah for noon and meem, which the first
    /// picture writes doubled (نّ مّ) in the khayshum's box.
    static func exits(of letter: String) -> Set<Int> {
        var exits = Set(LetterTraits.makharij(of: letter).map(\.id))
        if letter == "ن" || letter == "م" { exits.insert(17) }
        return exits
    }

    private static func box(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGRect {
        CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    /// The first picture's five areas, each a black dot on the drawing wired to a teal name.
    private enum Area {
        case khayshum, jawf, halq, lisan, shafatan

        var exits: Set<Int> {
            switch self {
            case .khayshum: return [17]
            case .jawf: return [1]
            case .halq: return [2, 3, 4]
            case .lisan: return Set(5...14)
            case .shafatan: return [15, 16]
            }
        }

        /// The dot, then the name.
        var boxes: [CGRect] {
            switch self {
            case .khayshum: return [MakhrajChart.box(400, 155, 430, 185), MakhrajChart.box(690, 127, 852, 213)]
            case .jawf: return [MakhrajChart.box(500, 258, 530, 288), MakhrajChart.box(702, 229, 852, 317)]
            case .halq: return [MakhrajChart.box(631, 425, 661, 455), MakhrajChart.box(727, 396, 852, 485)]
            case .lisan: return [MakhrajChart.box(480, 339, 510, 369), MakhrajChart.box(171, 420, 321, 506)]
            case .shafatan: return [MakhrajChart.box(360, 286, 384, 335), MakhrajChart.box(171, 267, 321, 354)]
            }
        }
    }

    /// Where each letter sits on the first picture: its area, and the letter in the box beside it.
    private static let areaTable: [String: [(Area, [CGRect])]] = [
        "ا": [(.jawf, [box(894, 247, 938, 272)])],
        "و": [(.jawf, [box(894, 290, 938, 314)]), (.shafatan, [box(195, 200, 290, 231)])],
        // Yaa's consonant is boxed with its "not madd" line under it.
        "ي": [(.jawf, [box(894, 327, 941, 351)]), (.lisan, [box(111, 360, 130, 397), box(48, 397, 129, 427)])],
        "ء": [(.halq, [box(932, 500, 947, 518)])],
        "ه": [(.halq, [box(898, 498, 925, 525)])],
        "ع": [(.halq, [box(930, 453, 954, 484)])],
        "ح": [(.halq, [box(898, 457, 925, 488)])],
        "غ": [(.halq, [box(930, 393, 954, 441)])],
        "خ": [(.halq, [box(898, 403, 925, 441)])],
        "ق": [(.lisan, [box(63, 438, 87, 478)])],
        "ك": [(.lisan, [box(86, 438, 107, 478)])],
        "ج": [(.lisan, [box(43, 360, 65, 397)])],
        "ش": [(.lisan, [box(70, 360, 107, 397)])],
        "ض": [(.lisan, [box(80, 318, 120, 352)])],
        "ل": [(.lisan, [box(56, 318, 81, 352)])],
        "ن": [(.lisan, [box(66, 206, 88, 234)]), (.khayshum, [box(941, 137, 964, 177)])],
        "ر": [(.lisan, [box(96, 206, 113, 234)])],
        "ط": [(.lisan, [box(101, 240, 125, 268)])],
        "د": [(.lisan, [box(86, 240, 102, 268)])],
        "ت": [(.lisan, [box(53, 240, 84, 268)])],
        // The tongue's box leaves the whistling letters out: their area alone.
        "ص": [(.lisan, [])],
        "س": [(.lisan, [])],
        "ز": [(.lisan, [])],
        "ظ": [(.lisan, [box(101, 278, 125, 307)])],
        "ذ": [(.lisan, [box(85, 278, 102, 307)])],
        "ث": [(.lisan, [box(53, 278, 84, 307)])],
        "ف": [(.shafatan, [box(196, 165, 219, 198)])],
        "ب": [(.shafatan, [box(239, 165, 266, 198)])],
        "م": [(.shafatan, [box(225, 165, 236, 199)]), (.khayshum, [box(902, 137, 926, 182)])],
    ]

    /// The second picture's "غنّة", at the nose.
    private static let ghunnah = box(293, 80, 406, 155)

    /// Where each letter is written on the second picture, by the exit it is written for.
    private static let placeTable: [String: [(Int, CGRect)]] = [
        "و": [(16, box(163, 483, 195, 521))],
        "ي": [(7, box(733, 583, 772, 624))],
        "ء": [(2, box(1315, 974, 1345, 1068))],
        "ه": [(2, box(1248, 1033, 1317, 1085))],
        "ع": [(3, box(1254, 858, 1301, 927))],
        "ح": [(3, box(1312, 855, 1365, 927))],
        "غ": [(4, box(1218, 719, 1253, 782))],
        "خ": [(4, box(1276, 713, 1340, 782))],
        "ق": [(5, box(1115, 655, 1165, 699))],
        "ك": [(6, box(1051, 633, 1092, 677))],
        "ج": [(7, box(828, 578, 877, 626))],
        "ش": [(7, box(776, 566, 824, 614))],
        "ض": [(8, box(791, 668, 879, 739))],
        "ل": [(9, box(493, 408, 527, 454))],
        "ن": [(10, box(603, 433, 639, 469)), (17, ghunnah)],
        "ر": [(11, box(707, 446, 744, 482))],
        "ط": [(12, box(433, 426, 474, 466))],
        "د": [(12, box(411, 456, 436, 486))],
        "ت": [(12, box(371, 471, 406, 506))],
        "ص": [(13, box(436, 643, 486, 679))],
        "س": [(13, box(378, 586, 426, 616))],
        "ز": [(13, box(411, 611, 441, 651))],
        "ظ": [(14, box(326, 513, 364, 559))],
        "ذ": [(14, box(301, 531, 329, 569))],
        "ث": [(14, box(261, 546, 296, 584))],
        "ف": [(15, box(206, 611, 249, 674))],
        "ب": [(16, box(113, 483, 144, 511))],
        "م": [(16, box(76, 486, 99, 536)), (17, ghunnah)],
    ]
}

/// The Makhaarij page's two pictures, the letters picked out on each. A tap opens one full screen,
/// marks and all, to zoom into.
struct MakhrajChartsRow: View {
    let letters: [String]
    let exits: Set<Int>
    /// Who the marks are for, under the title full screen ("Where Qaaf is made").
    let subject: String

    private var charts: [(chart: MakhrajChart, marks: [CGRect])] {
        MakhrajChart.allCases
            .map { (chart: $0, marks: $0.marks(letters: letters, exits: exits)) }
            .filter { !$0.marks.isEmpty }
    }

    var body: some View {
        let charts = charts
        if !charts.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("ON THE MAKHAARIJ CHARTS")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)

                    Spacer(minLength: 8)

                    Text("Tap to enlarge")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // One above the other at the row's full width: side by side they were too small to read
                // a letter on without opening them.
                VStack(spacing: 10) {
                    ForEach(charts, id: \.chart) { entry in
                        MakhrajPictureCard(label: entry.chart.label) {
                            Image(entry.chart.assetName)
                                .resizable()
                                .aspectRatio(entry.chart.aspectRatio, contentMode: .fit)
                                .overlay(ImageMarksOverlay(marks: entry.marks))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .focusableImage(entry.chart.assetName, title: String(localized: "Makharij al-Huruf"), subtitle: subject, marks: entry.marks)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            #if DEBUG
            // "-openMakhrajChart areas|places": what a tap on that picture does, headlessly, so the
            // full-screen marks can be screenshot (pair it with "-scrollToMakhrajCharts").
            .onAppear {
                let arguments = ProcessInfo.processInfo.arguments
                guard let index = arguments.firstIndex(of: "-openMakhrajChart"), arguments.indices.contains(index + 1),
                      let entry = charts.first(where: { ($0.chart == .areas ? "areas" : "places") == arguments[index + 1] }) else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    FocusOverlayPresenter.shared.present(.image(entry.chart.assetName, title: "Makharij al-Huruf", subtitle: subject, marks: entry.marks))
                }
            }
            #endif
        }
    }
}

#endif
