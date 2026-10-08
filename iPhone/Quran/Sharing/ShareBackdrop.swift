#if os(iOS)
import UIKit

/// The look of a shared ayah image: the ground the words sit on and the inks they take. The
/// classic black card is the app's own; the other four are Tilawa's share card designs (Jamil
/// Hammoudeh, with permission), redrawn in Core Graphics so they render inside the same one-pass
/// composer the share sheet and Copy Image already use.
///
/// Every design keeps its words on ONE known ground (2026-09-29): the frosted card's words sit on
/// a milky glass panel, the nature card's on the dark sea under a scene of fixed height, and the
/// lattice fades inside the geometric frame. `Palette.ground` is the lightest (dark cards) or
/// darkest (light cards) color that ground reaches under the text, and `ShareInk` lifts any run
/// (a tajweed color, the Allah highlight, the reader's accent) that reads below 3:1 against it.
/// Before, the frosted and nature scenery ran behind the text as the card grew, so white words and
/// gold Arabic landed on a pale sky or an orange sunset.
enum ShareBackdrop: String, CaseIterable, Identifiable {
    case classic, frosted, nature, editorial, geometric

    var id: String { rawValue }

    static let storageKey = "shareAyahBackdrop"

    /// The remembered choice (the share sheet's chips write it; Copy Image reads it).
    static var stored: ShareBackdrop {
        ShareBackdrop(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .classic
    }

    var title: String {
        switch self {
        case .classic: return "Classic"
        case .frosted: return "Frosted"
        case .nature: return "Nature"
        case .editorial: return "Editorial"
        case .geometric: return "Geometric"
        }
    }

    var symbol: String {
        switch self {
        case .classic: return "rectangle.fill"
        case .frosted: return "cloud.sun.fill"
        case .nature: return "sunset.fill"
        case .editorial: return "doc.richtext"
        case .geometric: return "square.grid.3x3.middle.filled"
        }
    }

    /// The inks. `accent` is the design's own where it has one (headers, references, the brand
    /// line); the classic card keeps the reader's accent color, resolved for a dark ground.
    struct Palette {
        let text: UIColor
        let arabic: UIColor
        let accent: UIColor?
        let caption: UIColor
        /// The Allah highlight's ink on this ground (pure red was too harsh on navy and too faint
        /// on the sunset and the cream paper).
        let allah: UIColor
        /// The worst case of the ground under the words: what every ink is measured against.
        let ground: UIColor
        /// Whether the ground is dark: dynamic colors (the accent, custom tajweed colors) resolve
        /// in the dark appearance on a dark card and in the light one on a light card.
        let isDark: Bool
        /// A soft shadow under the translation where it sits on scenery.
        let textShadow: Bool
    }

    var palette: Palette {
        switch self {
        case .classic:
            return Palette(text: .white, arabic: .white, accent: nil, caption: UIColor(white: 1, alpha: 0.62),
                           allah: Self.rgb(0xFF453A), ground: .black, isDark: true, textShadow: false)
        case .frosted:
            return Palette(text: Self.rgb(0x16252B), arabic: Self.rgb(0x0E3B3D), accent: Self.rgb(0x1D5F5B),
                           caption: Self.rgb(0x46585C), allah: Self.rgb(0x9B1B10), ground: Self.rgb(0xC4CCC8),
                           isDark: false, textShadow: false)
        case .nature:
            return Palette(text: .white, arabic: Self.rgb(0xFFE6A4), accent: Self.rgb(0xFFD98A),
                           caption: UIColor(white: 1, alpha: 0.74), allah: Self.rgb(0xFF9C85),
                           ground: Self.rgb(0x34495A), isDark: true, textShadow: true)
        case .editorial:
            return Palette(text: Self.rgb(0x161311), arabic: Self.rgb(0x1F4D42), accent: Self.rgb(0x1F4D42),
                           caption: Self.rgb(0x6B5C46), allah: Self.rgb(0xB42318), ground: Self.rgb(0xEFE6D5),
                           isDark: false, textShadow: false)
        case .geometric:
            return Palette(text: Self.rgb(0xFFF6D4), arabic: Self.rgb(0xEED28A), accent: Self.rgb(0xF1D98F),
                           caption: Self.rgb(0xC8B98D), allah: Self.rgb(0xFF7A6B), ground: Self.rgb(0x183454),
                           isDark: true, textShadow: false)
        }
    }

    /// Inset from the card edge to the text column.
    func padding(forWidth width: CGFloat) -> CGFloat {
        switch self {
        case .classic: return 20
        case .frosted: return max(36, (width * 0.08).rounded() + 18)
        case .nature: return max(24, (width * 0.07).rounded())
        case .editorial: return max(30, (width * 0.075).rounded())
        case .geometric: return max(30, (width * 0.078).rounded())
        }
    }

    /// Room kept above the text for the scenery (the sun and hills of the nature card, the sky
    /// over the frosted panel) and below it.
    func headroom(forWidth width: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        switch self {
        case .classic: return (0, 0)
        case .frosted: return ((width * 0.12).rounded(), (width * 0.10).rounded())
        case .nature: return ((width * 0.44).rounded(), 0)
        case .editorial: return (0, 0)
        case .geometric: return (0, 0)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .classic, .frosted, .nature: return 20
        case .editorial, .geometric: return 10
        }
    }

    // MARK: Painting

    /// Paints the ground and every decoration that sits UNDER the words (the frosted panel, the
    /// editorial frame and watermark, the geometric lattice). `textFrame` is where the words go;
    /// `watermark` is the editorial card's large faint Arabic.
    func paint(canvas: CGRect, textFrame: CGRect, watermark: NSAttributedString?, in cg: CGContext) {
        switch self {
        case .classic:
            cg.setFillColor(UIColor.black.cgColor)
            cg.fill(canvas)
        case .frosted:
            paintFrosted(canvas: canvas, textFrame: textFrame, in: cg)
        case .nature:
            paintNature(canvas: canvas, textFrame: textFrame, in: cg)
        case .editorial:
            paintEditorial(canvas: canvas, watermark: watermark, in: cg)
        case .geometric:
            paintGeometric(canvas: canvas, textFrame: textFrame, in: cg)
        }
    }

    private static func rgb(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }

    private static func gradient(_ stops: [(UIColor, CGFloat)]) -> CGGradient? {
        CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                   colors: stops.map { $0.0.cgColor } as CFArray,
                   locations: stops.map { $0.1 })
    }

    private static func fillVertical(_ rect: CGRect, stops: [(UIColor, CGFloat)], in cg: CGContext) {
        guard let gradient = gradient(stops) else { return }
        cg.saveGState()
        cg.clip(to: rect)
        cg.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.minY),
                              end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
        cg.restoreGState()
    }

    private static func fillDiagonal(_ rect: CGRect, stops: [(UIColor, CGFloat)], in cg: CGContext) {
        guard let gradient = gradient(stops) else { return }
        cg.saveGState()
        cg.clip(to: rect)
        cg.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.minY),
                              end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
        cg.restoreGState()
    }

    private static func fillRadial(center: CGPoint, radius: CGFloat, stops: [(UIColor, CGFloat)], in cg: CGContext) {
        guard let gradient = gradient(stops) else { return }
        cg.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius,
                              options: [.drawsAfterEndLocation])
    }

    /// A small filled diamond: the corner ornament of the editorial and geometric frames.
    private static func diamond(at point: CGPoint, size: CGFloat, color: UIColor, in cg: CGContext) {
        cg.setFillColor(color.cgColor)
        cg.move(to: CGPoint(x: point.x, y: point.y - size))
        cg.addLine(to: CGPoint(x: point.x + size, y: point.y))
        cg.addLine(to: CGPoint(x: point.x, y: point.y + size))
        cg.addLine(to: CGPoint(x: point.x - size, y: point.y))
        cg.closePath()
        cg.fillPath()
    }

    /// A pale morning sky over two ranges of hills; the words sit on a milky glass panel whose
    /// ground stays light from the top of the card to the bottom, so the ink is dark.
    private func paintFrosted(canvas: CGRect, textFrame: CGRect, in cg: CGContext) {
        let w = canvas.width, h = canvas.height
        Self.fillVertical(canvas, stops: [(Self.rgb(0x9FC7DA), 0), (Self.rgb(0xCFE0E4), 0.30),
                                          (Self.rgb(0xF3CFA0), 0.56), (Self.rgb(0x6E8F7C), 0.80), (Self.rgb(0x284536), 1)], in: cg)
        // Morning light from the upper left.
        Self.fillRadial(center: CGPoint(x: w * 0.18, y: h * 0.06), radius: w * 0.9,
                        stops: [(UIColor(white: 1, alpha: 0.55), 0), (UIColor(white: 1, alpha: 0), 1)], in: cg)

        let far = UIBezierPath()
        far.move(to: CGPoint(x: 0, y: h * 0.58))
        far.addCurve(to: CGPoint(x: w * 0.45, y: h * 0.40), controlPoint1: CGPoint(x: w * 0.16, y: h * 0.46), controlPoint2: CGPoint(x: w * 0.28, y: h * 0.52))
        far.addCurve(to: CGPoint(x: w, y: h * 0.36), controlPoint1: CGPoint(x: w * 0.65, y: h * 0.26), controlPoint2: CGPoint(x: w * 0.76, y: h * 0.50))
        far.addLine(to: CGPoint(x: w, y: h))
        far.addLine(to: CGPoint(x: 0, y: h))
        far.close()
        cg.setFillColor(Self.rgb(0x5B7F86, alpha: 0.55).cgColor)
        cg.addPath(far.cgPath)
        cg.fillPath()

        let near = UIBezierPath()
        near.move(to: CGPoint(x: 0, y: h * 0.70))
        near.addCurve(to: CGPoint(x: w * 0.54, y: h * 0.54), controlPoint1: CGPoint(x: w * 0.18, y: h * 0.58), controlPoint2: CGPoint(x: w * 0.36, y: h * 0.67))
        near.addCurve(to: CGPoint(x: w, y: h * 0.52), controlPoint1: CGPoint(x: w * 0.72, y: h * 0.42), controlPoint2: CGPoint(x: w * 0.84, y: h * 0.64))
        near.addLine(to: CGPoint(x: w, y: h))
        near.addLine(to: CGPoint(x: 0, y: h))
        near.close()
        cg.setFillColor(Self.rgb(0x2E5240, alpha: 0.80).cgColor)
        cg.addPath(near.cgPath)
        cg.fillPath()

        // The glass: milky enough that the hills behind it never pull the ground below the
        // palette's `ground`, with a lit top edge and a soft shadow.
        let inset = (w * 0.08).rounded()
        let panel = CGRect(x: inset, y: textFrame.minY - 20, width: w - 2 * inset, height: textFrame.height + 40)
        let radius = (w * 0.06).rounded()
        let path = UIBezierPath(roundedRect: panel, cornerRadius: radius)
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: 14), blur: 30, color: Self.rgb(0x0B1A14, alpha: 0.30).cgColor)
        cg.setFillColor(UIColor(white: 1, alpha: 0.76).cgColor)
        cg.addPath(path.cgPath)
        cg.fillPath()
        cg.restoreGState()
        cg.saveGState()
        cg.addPath(path.cgPath)
        cg.clip()
        Self.fillVertical(panel, stops: [(UIColor(white: 1, alpha: 0.30), 0), (UIColor(white: 1, alpha: 0), 0.35)], in: cg)
        cg.restoreGState()
        cg.setStrokeColor(UIColor(white: 1, alpha: 0.9).cgColor)
        cg.setLineWidth(1)
        cg.addPath(path.cgPath)
        cg.strokePath()
    }

    /// Dusk: a sun setting behind two mountain ranges in a band of FIXED height at the top, and the
    /// words on the dark sea below it, where the sun's path and a few swells catch the light. The
    /// scene no longer scales with the card, so a long ayah only lengthens the sea.
    private func paintNature(canvas: CGRect, textFrame: CGRect, in cg: CGContext) {
        let w = canvas.width, h = canvas.height
        // A band of open sea between the horizon and the first line holds the sun's path and the
        // swells, so neither ever runs behind a word.
        let band = max(18, (w * 0.075).rounded())
        let horizon = min(h * 0.62, textFrame.minY - band)
        let sky = CGRect(x: 0, y: 0, width: w, height: horizon)
        Self.fillVertical(sky, stops: [(Self.rgb(0x1E2F4C), 0), (Self.rgb(0x4B5B82), 0.38),
                                       (Self.rgb(0xC98A6E), 0.78), (Self.rgb(0xF2B477), 1)], in: cg)

        // The sun, setting behind the far ridge, with a warm halo.
        let sun = CGPoint(x: w * 0.66, y: horizon * 0.58)
        let r = w * 0.062
        Self.fillRadial(center: sun, radius: r * 4.2,
                        stops: [(Self.rgb(0xFFD08A, alpha: 0.55), 0), (Self.rgb(0xFFB070, alpha: 0), 1)], in: cg)
        cg.setFillColor(Self.rgb(0xFFE3A6).cgColor)
        cg.fillEllipse(in: CGRect(x: sun.x - r, y: sun.y - r, width: 2 * r, height: 2 * r))

        let far = UIBezierPath()
        far.move(to: CGPoint(x: 0, y: horizon * 0.80))
        far.addCurve(to: CGPoint(x: w * 0.36, y: horizon * 0.56), controlPoint1: CGPoint(x: w * 0.12, y: horizon * 0.62), controlPoint2: CGPoint(x: w * 0.24, y: horizon * 0.70))
        far.addCurve(to: CGPoint(x: w * 0.78, y: horizon * 0.66), controlPoint1: CGPoint(x: w * 0.50, y: horizon * 0.40), controlPoint2: CGPoint(x: w * 0.64, y: horizon * 0.78))
        far.addCurve(to: CGPoint(x: w, y: horizon * 0.58), controlPoint1: CGPoint(x: w * 0.88, y: horizon * 0.56), controlPoint2: CGPoint(x: w * 0.95, y: horizon * 0.60))
        far.addLine(to: CGPoint(x: w, y: horizon))
        far.addLine(to: CGPoint(x: 0, y: horizon))
        far.close()
        cg.setFillColor(Self.rgb(0x655A72).cgColor)
        cg.addPath(far.cgPath)
        cg.fillPath()

        let near = UIBezierPath()
        near.move(to: CGPoint(x: 0, y: horizon * 0.88))
        near.addCurve(to: CGPoint(x: w * 0.30, y: horizon * 0.74), controlPoint1: CGPoint(x: w * 0.10, y: horizon * 0.80), controlPoint2: CGPoint(x: w * 0.20, y: horizon * 0.84))
        near.addCurve(to: CGPoint(x: w * 0.62, y: horizon * 0.86), controlPoint1: CGPoint(x: w * 0.42, y: horizon * 0.62), controlPoint2: CGPoint(x: w * 0.52, y: horizon * 0.90))
        near.addCurve(to: CGPoint(x: w, y: horizon * 0.80), controlPoint1: CGPoint(x: w * 0.78, y: horizon * 0.80), controlPoint2: CGPoint(x: w * 0.90, y: horizon * 0.86))
        near.addLine(to: CGPoint(x: w, y: horizon))
        near.addLine(to: CGPoint(x: 0, y: horizon))
        near.close()
        cg.setFillColor(Self.rgb(0x243048).cgColor)
        cg.addPath(near.cgPath)
        cg.fillPath()

        // The sea: it starts at the palette's `ground` and only darkens under the words.
        let sea = CGRect(x: 0, y: horizon, width: w, height: h - horizon)
        Self.fillVertical(sea, stops: [(Self.rgb(0x34495A), 0), (Self.rgb(0x172B3D), 0.35), (Self.rgb(0x08141F), 1)], in: cg)

        // The sun's path: short glints under the sun, fading out before the first line.
        let reach = max(8, min(sea.height, textFrame.minY - horizon - 6))
        for index in 0..<7 {
            let t = CGFloat(index) / 7
            let y = horizon + 3 + t * reach
            let half = r * (1.1 - t * 0.7)
            cg.setFillColor(Self.rgb(0xFFD08A, alpha: 0.42 * (1 - t)).cgColor)
            cg.fill(CGRect(x: sun.x - half, y: y, width: 2 * half, height: 1.6))
        }
        // Swells: short strokes of different lengths, brighter near the sun's side.
        cg.setLineWidth(1)
        cg.setLineCap(.round)
        let swells: [(from: CGFloat, to: CGFloat, depth: CGFloat)] = [
            (0.08, 0.34, 0.22), (0.42, 0.58, 0.18), (0.74, 0.93, 0.28),
            (0.18, 0.47, 0.56), (0.80, 0.96, 0.62), (0.05, 0.22, 0.88), (0.36, 0.60, 0.84),
        ]
        for swell in swells {
            let y = horizon + reach * swell.depth
            let x0 = w * swell.from, x1 = w * swell.to
            let wave = UIBezierPath()
            wave.move(to: CGPoint(x: x0, y: y))
            wave.addQuadCurve(to: CGPoint(x: x1, y: y), controlPoint: CGPoint(x: (x0 + x1) / 2, y: y - 2.5))
            let nearSun = 1 - min(1, abs((x0 + x1) / 2 - sun.x) / w)
            cg.setStrokeColor(Self.rgb(0xF8D38B, alpha: 0.06 + 0.12 * nearSun * (1 - swell.depth * 0.6)).cgColor)
            cg.addPath(wave.cgPath)
            cg.strokePath()
        }
    }

    /// Cream paper with a soft edge shade, a double gold rule with heavy corners and diamond
    /// ornaments, and the ayah itself as a faint watermark centered behind the words.
    private func paintEditorial(canvas: CGRect, watermark: NSAttributedString?, in cg: CGContext) {
        let w = canvas.width, h = canvas.height
        cg.setFillColor(Self.rgb(0xF8F1E4).cgColor)
        cg.fill(canvas)
        Self.fillRadial(center: CGPoint(x: w / 2, y: h / 2), radius: max(w, h) * 0.75,
                        stops: [(Self.rgb(0xA07A3C, alpha: 0), 0.55), (Self.rgb(0xA07A3C, alpha: 0.09), 1)], in: cg)

        let inset = (padding(forWidth: w) * 0.64).rounded()
        let frame = canvas.insetBy(dx: inset, dy: inset)
        if let watermark, watermark.length > 0 {
            let box = frame.insetBy(dx: 8, dy: 8)
            let size = watermark.boundingRect(with: CGSize(width: box.width, height: .greatestFiniteMagnitude),
                                              options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
            let drawn = CGRect(x: box.minX, y: box.midY - min(size.height, box.height) / 2,
                               width: box.width, height: min(size.height, box.height))
            cg.saveGState()
            cg.clip(to: box)
            cg.setAlpha(0.055)
            watermark.draw(with: drawn, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            cg.restoreGState()
        }

        let gold = Self.rgb(0xB8995E)
        cg.setStrokeColor(gold.cgColor)
        cg.setLineWidth(1)
        cg.stroke(frame)
        cg.setStrokeColor(gold.withAlphaComponent(0.55).cgColor)
        cg.setLineWidth(0.6)
        cg.stroke(frame.insetBy(dx: 4, dy: 4))
        let corner = max(18, (inset * 1.2).rounded())
        cg.setStrokeColor(gold.cgColor)
        cg.setLineWidth(3)
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: frame.minX, y: frame.minY + corner), CGPoint(x: frame.minX, y: frame.minY), CGPoint(x: frame.minX + corner, y: frame.minY)),
            (CGPoint(x: frame.maxX - corner, y: frame.minY), CGPoint(x: frame.maxX, y: frame.minY), CGPoint(x: frame.maxX, y: frame.minY + corner)),
            (CGPoint(x: frame.maxX, y: frame.maxY - corner), CGPoint(x: frame.maxX, y: frame.maxY), CGPoint(x: frame.maxX - corner, y: frame.maxY)),
            (CGPoint(x: frame.minX + corner, y: frame.maxY), CGPoint(x: frame.minX, y: frame.maxY), CGPoint(x: frame.minX, y: frame.maxY - corner)),
        ]
        for (a, b, c) in corners {
            cg.move(to: a)
            cg.addLine(to: b)
            cg.addLine(to: c)
            cg.strokePath()
        }
        for point in [CGPoint(x: frame.midX, y: frame.minY), CGPoint(x: frame.midX, y: frame.maxY)] {
            Self.diamond(at: point, size: 4, color: gold, in: cg)
        }
    }

    /// Deep navy lit from the middle, a lattice of gold diamonds that fades to a whisper inside
    /// the hairline frame around the words, and diamond ornaments at the frame's corners.
    private func paintGeometric(canvas: CGRect, textFrame: CGRect, in cg: CGContext) {
        let w = canvas.width, h = canvas.height
        Self.fillDiagonal(canvas, stops: [(Self.rgb(0x061627), 0), (Self.rgb(0x0B2440), 0.55), (Self.rgb(0x06111F), 1)], in: cg)
        Self.fillRadial(center: CGPoint(x: w / 2, y: h * 0.42), radius: max(w, h) * 0.6,
                        stops: [(Self.rgb(0x183454, alpha: 0.85), 0), (Self.rgb(0x183454, alpha: 0), 1)], in: cg)

        let frame = CGRect(x: textFrame.minX - 14, y: textFrame.minY - 14, width: textFrame.width + 28, height: textFrame.height + 28)
        let unit = max(38, w * 0.16)
        let rows = Int((h / unit).rounded(.up)) + 2
        let cols = Int((w / unit).rounded(.up)) + 2
        let gold = Self.rgb(0xD7B76C)
        func lattice(alpha: CGFloat) {
            cg.setAlpha(alpha)
            cg.setStrokeColor(gold.cgColor)
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * unit - unit * 0.55
                    let y = CGFloat(row) * unit - unit * 0.55
                    cg.saveGState()
                    cg.translateBy(x: x + unit / 2, y: y + unit / 2)
                    cg.rotate(by: .pi / 4)
                    cg.setLineWidth(1)
                    cg.stroke(CGRect(x: -unit * 0.32, y: -unit * 0.32, width: unit * 0.64, height: unit * 0.64))
                    cg.setLineWidth(0.8)
                    cg.stroke(CGRect(x: -unit * 0.16, y: -unit * 0.16, width: unit * 0.32, height: unit * 0.32))
                    cg.restoreGState()
                }
            }
        }
        // Outside the frame at full strength (the even-odd clip leaves the frame out), inside it faint.
        cg.saveGState()
        cg.addRect(canvas)
        cg.addRect(frame)
        cg.clip(using: .evenOdd)
        lattice(alpha: 0.18)
        cg.restoreGState()
        cg.saveGState()
        cg.clip(to: frame)
        lattice(alpha: 0.05)
        cg.restoreGState()

        cg.setStrokeColor(Self.rgb(0xD7B76C, alpha: 0.55).cgColor)
        cg.setLineWidth(1)
        cg.stroke(frame)
        for point in [CGPoint(x: frame.minX, y: frame.minY), CGPoint(x: frame.maxX, y: frame.minY),
                      CGPoint(x: frame.minX, y: frame.maxY), CGPoint(x: frame.maxX, y: frame.maxY)] {
            Self.diamond(at: point, size: 3.5, color: Self.rgb(0xE3C77F), in: cg)
        }
    }
}

/// Contrast for the share card's inks, by the WCAG definition (relative luminance of sRGB).
enum ShareInk {
    static func luminance(_ color: UIColor) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return 0 }
        func channel(_ c: CGFloat) -> CGFloat {
            let c = min(1, max(0, c))
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    /// The ink as it lands on `ground` (its alpha composited), against `ground`.
    static func contrast(_ ink: UIColor, on ground: UIColor) -> CGFloat {
        let landed = composite(ink, over: ground)
        let a = luminance(landed), b = luminance(ground)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    private static func composite(_ ink: UIColor, over ground: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var gr: CGFloat = 0, gg: CGFloat = 0, gb: CGFloat = 0, ga: CGFloat = 0
        guard ink.getRed(&r, green: &g, blue: &b, alpha: &a), ground.getRed(&gr, green: &gg, blue: &gb, alpha: &ga) else { return ink }
        return UIColor(red: r * a + gr * (1 - a), green: g * a + gg * (1 - a), blue: b * a + gb * (1 - a), alpha: 1)
    }

    /// `color` resolved for the card's appearance and, when it reads below `minimum` on `ground`,
    /// moved toward white (dark ground) or black (light ground) in small steps until it does. The
    /// hue stays, so a lifted tajweed color is still its rule's color.
    static func readable(_ color: UIColor, on ground: UIColor, dark: Bool, minimum: CGFloat) -> UIColor {
        let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light))
        guard contrast(resolved, on: ground) < minimum else { return resolved }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else { return resolved }
        let opaque = a < 1 ? 1 : a
        for step in 1...20 {
            let t = CGFloat(step) / 20
            let moved = dark
                ? UIColor(red: r + (1 - r) * t, green: g + (1 - g) * t, blue: b + (1 - b) * t, alpha: opaque)
                : UIColor(red: r * (1 - t), green: g * (1 - t), blue: b * (1 - t), alpha: opaque)
            if contrast(moved, on: ground) >= minimum { return moved }
        }
        return dark ? .white : .black
    }

    /// Every foreground run of `text` made `readable` on the palette's ground.
    static func enforce(_ text: NSMutableAttributedString, palette: ShareBackdrop.Palette, minimum: CGFloat) {
        text.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            guard let color = value as? UIColor else { return }
            let fixed = readable(color, on: palette.ground, dark: palette.isDark, minimum: minimum)
            if fixed != color { text.addAttribute(.foregroundColor, value: fixed, range: range) }
        }
    }
}
#endif
