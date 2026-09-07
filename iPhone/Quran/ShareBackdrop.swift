#if os(iOS)
import UIKit

/// The look of a shared ayah image: the ground the words sit on and the inks they take. The
/// classic black card is the app's own; the other four are Tilawa's share card designs (Jamil
/// Hammoudeh, with permission), redrawn in Core Graphics so they render inside the same one-pass
/// composer the share sheet and Copy Image already use.
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
    /// line); the classic card keeps the reader's accent color.
    struct Palette {
        let text: UIColor
        let arabic: UIColor
        let accent: UIColor?
        let caption: UIColor
        /// A soft shadow under the translation where it sits on scenery.
        let textShadow: Bool
    }

    var palette: Palette {
        switch self {
        case .classic:
            return Palette(text: .white, arabic: .white, accent: nil, caption: .secondaryLabel, textShadow: false)
        case .frosted:
            return Palette(text: .white, arabic: .white, accent: UIColor(white: 1, alpha: 0.88),
                           caption: UIColor(white: 1, alpha: 0.72), textShadow: false)
        case .nature:
            return Palette(text: .white, arabic: Self.rgb(0xFFE6A4), accent: Self.rgb(0xFFE6A4),
                           caption: UIColor(white: 1, alpha: 0.78), textShadow: true)
        case .editorial:
            return Palette(text: Self.rgb(0x161311), arabic: Self.rgb(0x214F44), accent: Self.rgb(0x214F44),
                           caption: Self.rgb(0x7B6C55), textShadow: false)
        case .geometric:
            return Palette(text: Self.rgb(0xFFF6D4), arabic: Self.rgb(0xEED28A), accent: Self.rgb(0xF1D98F),
                           caption: Self.rgb(0xC8B98D), textShadow: false)
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
        case .frosted: return ((width * 0.10).rounded(), (width * 0.10).rounded())
        case .nature: return ((width * 0.34).rounded(), 0)
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
    /// editorial frame and watermark, the geometric grid). `textFrame` is where the words go;
    /// `watermark` is the editorial card's giant faint Arabic.
    func paint(canvas: CGRect, textFrame: CGRect, watermark: NSAttributedString?, in cg: CGContext) {
        switch self {
        case .classic:
            cg.setFillColor(UIColor.black.cgColor)
            cg.fill(canvas)
        case .frosted:
            paintFrosted(canvas: canvas, textFrame: textFrame, in: cg)
        case .nature:
            paintNature(canvas: canvas, in: cg)
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

    /// A pale sky warming to sunset over two ranges of hills, with the words on a glass panel.
    private func paintFrosted(canvas: CGRect, textFrame: CGRect, in cg: CGContext) {
        let w = canvas.width, h = canvas.height
        Self.fillVertical(canvas, stops: [(Self.rgb(0xA9D0DE), 0), (Self.rgb(0xF2C48D), 0.48), (Self.rgb(0x1D382F), 1)], in: cg)
        Self.fillDiagonal(CGRect(x: 0, y: 0, width: w, height: h * 0.44),
                          stops: [(UIColor(white: 1, alpha: 0.44), 0), (UIColor(white: 1, alpha: 0), 1)], in: cg)

        let far = UIBezierPath()
        far.move(to: CGPoint(x: 0, y: h * 0.56))
        far.addCurve(to: CGPoint(x: w * 0.45, y: h * 0.36), controlPoint1: CGPoint(x: w * 0.16, y: h * 0.43), controlPoint2: CGPoint(x: w * 0.28, y: h * 0.50))
        far.addCurve(to: CGPoint(x: w, y: h * 0.32), controlPoint1: CGPoint(x: w * 0.65, y: h * 0.20), controlPoint2: CGPoint(x: w * 0.76, y: h * 0.48))
        far.addLine(to: CGPoint(x: w, y: h))
        far.addLine(to: CGPoint(x: 0, y: h))
        far.close()
        cg.setFillColor(Self.rgb(0x203E4B, alpha: 0.76).cgColor)
        cg.addPath(far.cgPath)
        cg.fillPath()

        let near = UIBezierPath()
        near.move(to: CGPoint(x: 0, y: h * 0.68))
        near.addCurve(to: CGPoint(x: w * 0.54, y: h * 0.50), controlPoint1: CGPoint(x: w * 0.18, y: h * 0.55), controlPoint2: CGPoint(x: w * 0.36, y: h * 0.65))
        near.addCurve(to: CGPoint(x: w, y: h * 0.48), controlPoint1: CGPoint(x: w * 0.72, y: h * 0.36), controlPoint2: CGPoint(x: w * 0.84, y: h * 0.62))
        near.addLine(to: CGPoint(x: w, y: h))
        near.addLine(to: CGPoint(x: 0, y: h))
        near.close()
        cg.setFillColor(Self.rgb(0x15301F, alpha: 0.84).cgColor)
        cg.addPath(near.cgPath)
        cg.fillPath()

        cg.setFillColor(Self.rgb(0x10241A, alpha: 0.46).cgColor)
        cg.fill(CGRect(x: 0, y: h * 0.72, width: w, height: h * 0.28))
        cg.setFillColor(UIColor(red: 8 / 255, green: 18 / 255, blue: 22 / 255, alpha: 0.16).cgColor)
        cg.fill(canvas)

        // The glass panel: the text column plus its own padding, on a soft shadow.
        let inset = (w * 0.08).rounded()
        let panel = CGRect(x: inset, y: textFrame.minY - 18, width: w - 2 * inset, height: textFrame.height + 36)
        let path = UIBezierPath(roundedRect: panel, cornerRadius: (w * 0.07).rounded())
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: 12), blur: 28, color: Self.rgb(0x07120F, alpha: 0.28).cgColor)
        cg.setFillColor(UIColor(white: 1, alpha: 0.20).cgColor)
        cg.addPath(path.cgPath)
        cg.fillPath()
        cg.restoreGState()
        cg.setStrokeColor(UIColor(white: 1, alpha: 0.56).cgColor)
        cg.setLineWidth(1)
        cg.addPath(path.cgPath)
        cg.strokePath()
    }

    /// A sunset over a mountain line and a dark sea, gold wave lines catching the light.
    private func paintNature(canvas: CGRect, in cg: CGContext) {
        let w = canvas.width, h = canvas.height
        let horizon = h * 0.52
        Self.fillVertical(canvas, stops: [(Self.rgb(0x263D56), 0), (Self.rgb(0xD69866), 0.42), (Self.rgb(0x1B344A), 0.70), (Self.rgb(0x071927), 1)], in: cg)

        cg.setFillColor(Self.rgb(0xFFD37D).cgColor)
        let r = w * 0.055
        cg.fillEllipse(in: CGRect(x: w * 0.58 - r, y: horizon * 0.82 - r, width: 2 * r, height: 2 * r))

        let mountains = UIBezierPath()
        mountains.move(to: CGPoint(x: 0, y: horizon * 0.92))
        mountains.addCurve(to: CGPoint(x: w * 0.33, y: horizon * 0.64), controlPoint1: CGPoint(x: w * 0.10, y: horizon * 0.74), controlPoint2: CGPoint(x: w * 0.22, y: horizon * 0.85))
        mountains.addCurve(to: CGPoint(x: w * 0.66, y: horizon * 0.66), controlPoint1: CGPoint(x: w * 0.44, y: horizon * 0.44), controlPoint2: CGPoint(x: w * 0.55, y: horizon * 0.84))
        mountains.addCurve(to: CGPoint(x: w, y: horizon * 0.72), controlPoint1: CGPoint(x: w * 0.78, y: horizon * 0.47), controlPoint2: CGPoint(x: w * 0.88, y: horizon * 0.86))
        mountains.addLine(to: CGPoint(x: w, y: horizon))
        mountains.addLine(to: CGPoint(x: 0, y: horizon))
        mountains.close()
        cg.setFillColor(Self.rgb(0x152842).cgColor)
        cg.addPath(mountains.cgPath)
        cg.fillPath()

        Self.fillVertical(CGRect(x: 0, y: horizon, width: w, height: h - horizon),
                          stops: [(Self.rgb(0x3A5360), 0), (Self.rgb(0x071927), 1)], in: cg)

        cg.setLineWidth(1.2)
        for (index, y) in [0.58, 0.64, 0.71, 0.80].enumerated() {
            let wave = UIBezierPath()
            wave.move(to: CGPoint(x: w * 0.08, y: h * y))
            wave.addCurve(to: CGPoint(x: w * 0.62, y: h * (y - 0.008)), controlPoint1: CGPoint(x: w * 0.27, y: h * (y - 0.018)), controlPoint2: CGPoint(x: w * 0.42, y: h * (y + 0.018)))
            wave.addCurve(to: CGPoint(x: w * 0.96, y: h * (y - 0.004)), controlPoint1: CGPoint(x: w * 0.75, y: h * (y - 0.02)), controlPoint2: CGPoint(x: w * 0.88, y: h * (y + 0.01)))
            cg.setStrokeColor(Self.rgb(0xF8D38B, alpha: 0.26 - CGFloat(index) * 0.04).cgColor)
            cg.addPath(wave.cgPath)
            cg.strokePath()
        }

        Self.fillVertical(canvas, stops: [(UIColor(white: 0, alpha: 0), 0), (UIColor(white: 0, alpha: 0.68), 1)], in: cg)
        cg.setFillColor(UIColor(white: 0, alpha: 0.18).cgColor)
        cg.fill(canvas)
    }

    /// Cream paper, a hairline gold frame with heavy corners, and the ayah itself as a faint
    /// watermark behind the words.
    private func paintEditorial(canvas: CGRect, watermark: NSAttributedString?, in cg: CGContext) {
        let w = canvas.width, h = canvas.height
        cg.setFillColor(Self.rgb(0xF8F1E4).cgColor)
        cg.fill(canvas)

        if let watermark, watermark.length > 0 {
            let box = CGRect(x: w * 0.03, y: w * 0.18, width: w * 0.94, height: min(w * 0.72, max(0, h - w * 0.2)))
            cg.saveGState()
            cg.clip(to: box)
            cg.setAlpha(0.07)
            watermark.draw(with: box, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            cg.restoreGState()
        }

        let inset = (padding(forWidth: w) * 0.64).rounded()
        let frame = canvas.insetBy(dx: inset, dy: inset)
        let gold = Self.rgb(0xBFA36B)
        cg.setStrokeColor(gold.cgColor)
        cg.setLineWidth(1)
        cg.stroke(frame)
        let corner = max(18, (inset * 1.2).rounded())
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
    }

    /// Deep navy with a lattice of gold diamonds and a hairline frame around the words.
    private func paintGeometric(canvas: CGRect, textFrame: CGRect, in cg: CGContext) {
        let w = canvas.width, h = canvas.height
        Self.fillDiagonal(canvas, stops: [(Self.rgb(0x061627), 0), (Self.rgb(0x0B2440), 0.55), (Self.rgb(0x06111F), 1)], in: cg)

        let unit = max(38, w * 0.16)
        let rows = Int((h / unit).rounded(.up)) + 2
        let cols = Int((w / unit).rounded(.up)) + 2
        let gold = Self.rgb(0xD7B76C)
        cg.saveGState()
        cg.setAlpha(0.18)
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
        cg.restoreGState()

        let frame = CGRect(x: textFrame.minX - 14, y: textFrame.minY - 14, width: textFrame.width + 28, height: textFrame.height + 28)
        cg.setStrokeColor(Self.rgb(0xD7B76C, alpha: 0.5).cgColor)
        cg.setLineWidth(1)
        cg.stroke(frame)
    }
}
#endif
