// Generates the Hafs mushaf facsimile: the app's KFGQPC text in the app's Uthmani face, set on the
// Madinah 15-line page layout, inside a classic teal-and-gold vector frame. Output: 604-page PDF.
import Foundation
import CoreGraphics
import CoreText

// MARK: - Design
enum D {
    static let measure: CGFloat = 340
    static let pitch: CGFloat = 38
    static let linesPerPage = 15
    static let paperMargin: CGFloat = 16
    static let outerRule: CGFloat = 0.9
    static let gap1: CGFloat = 2.6
    static let band: CGFloat = 15
    static let gap2: CGFloat = 2.6
    static let innerRule: CGFloat = 0.7
    static let innerPad: CGFloat = 9
    static let sidePad: CGFloat = 8
    static let topStrip: CGFloat = 24
    static let topGap: CGFloat = 9
    static let bottomStrip: CGFloat = 20
    static let bottomGap: CGFloat = 3
    static let textAscent: CGFloat = 26
    static let textDescent: CGFloat = 14
    static var frameThickness: CGFloat { outerRule + gap1 + band + gap2 + innerRule }
    static var contentInset: CGFloat { paperMargin + frameThickness + innerPad }
    static var contentWidth: CGFloat { measure + 2 * sidePad }
    static var textBlockHeight: CGFloat { CGFloat(linesPerPage - 1) * pitch + textAscent + textDescent }
    static var contentHeight: CGFloat { topStrip + topGap + textBlockHeight + bottomGap + bottomStrip }
    static var pageWidth: CGFloat { contentWidth + 2 * contentInset }
    static var pageHeight: CGFloat { contentHeight + 2 * contentInset }
}

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [r, g, b, 1])!
}
enum C {
    static let paper = rgb(0.995, 0.985, 0.955)
    static let ink = rgb(0.07, 0.07, 0.07)
    static let teal = rgb(0.18, 0.47, 0.45)
    static let tealDark = rgb(0.10, 0.32, 0.31)
    static let tealTint = rgb(0.90, 0.95, 0.94)
    static let gold = rgb(0.70, 0.54, 0.20)
    static let goldLight = rgb(0.87, 0.74, 0.42)
    static let cream = rgb(0.99, 0.965, 0.90)
    static let marker = rgb(0.12, 0.38, 0.36)
}

// MARK: - Data
struct Ayah { let id: Int; let tokens: [String]; let rub: Bool; let juz: Int }
struct Surah { let id: Int; let name: String; let type: String; let count: Int; let ayahs: [Ayah] }
struct Line { let type: String; let centered: Bool; let surah: Int; let words: [[Int]]; let ends: [[Int]] }

let args = CommandLine.arguments
guard args.count >= 5 else { print("usage: mushafgen quran.json layout.json fontsDir out.pdf [pages]"); exit(1) }
let quranURL = URL(fileURLWithPath: args[1]), layoutURL = URL(fileURLWithPath: args[2])
let fontsDir = URL(fileURLWithPath: args[3]), outURL = URL(fileURLWithPath: args[4])
let onlyPages: Set<Int>? = args.count > 5 ? Set(args[5].split(separator: ",").compactMap { Int($0) }) : nil

let quranJSON = try! JSONSerialization.jsonObject(with: Data(contentsOf: quranURL)) as! [[String: Any]]
var surahs: [Int: Surah] = [:]
for s in quranJSON {
    let id = s["id"] as! Int
    var ayahs: [Ayah] = []
    for a in s["ayahs"] as! [[String: Any]] {
        let text = (a["textArabic"] as! String).replacingOccurrences(of: "\u{00A0}", with: " ")
        var toks = text.split(separator: " ").map(String.init)
        var rub = false
        if toks.first == "\u{06DE}" { rub = true; toks.removeFirst() }
        ayahs.append(Ayah(id: a["id"] as! Int, tokens: toks, rub: rub, juz: a["juz"] as! Int))
    }
    surahs[id] = Surah(id: id, name: s["nameArabic"] as! String, type: s["type"] as! String,
                       count: s["numberOfAyahs"] as! Int, ayahs: ayahs)
}
let layoutJSON = try! JSONSerialization.jsonObject(with: Data(contentsOf: layoutURL)) as! [String: Any]
let pagesJSON = layoutJSON["pages"] as! [String: [[String: Any]]]
var layout: [Int: [Line]] = [:]
for (k, v) in pagesJSON {
    layout[Int(k)!] = v.map { l in
        Line(type: l["type"] as! String, centered: l["centered"] as! Bool, surah: l["surah"] as? Int ?? 0,
             words: l["words"] as! [[Int]], ends: l["ends"] as! [[Int]])
    }
}
let allPages = layout.keys.sorted()

// MARK: - Fonts
func loadFont(_ file: String) -> CTFont {
    let url = fontsDir.appendingPathComponent(file)
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as! [CTFontDescriptor]
    return CTFontCreateWithFontDescriptor(descs[0], 10, nil)
}
let fontQuran = loadFont("Uthmani.ttf")
let fontOrnament = loadFont("QuranCommon.ttf")
let fontLabel = loadFont("Amiri-Regular.ttf")
let fontLabelBold = loadFont("Amiri-Bold.ttf")
func sized(_ f: CTFont, _ size: CGFloat) -> CTFont { CTFontCreateCopyWithAttributes(f, size, nil, nil) }

func attributed(_ s: String, _ font: CTFont, _ color: CGColor) -> CFAttributedString {
    let attrs: [CFString: Any] = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: color]
    return CFAttributedStringCreate(nil, s as CFString, attrs as CFDictionary)
}
func lineWidth(_ line: CTLine) -> CGFloat { CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)) }
func widthAtUnitSize(_ s: String, _ font: CTFont) -> CGFloat {
    lineWidth(CTLineCreateWithAttributedString(attributed(s, sized(font, 10), C.ink))) / 10
}

let arabicDigits: [Character] = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
func arabicIndic(_ n: Int) -> String { String(String(n).map { arabicDigits[Int(String($0))!] }) }
let juzNames = ["الأول","الثاني","الثالث","الرابع","الخامس","السادس","السابع","الثامن","التاسع","العاشر",
                "الحادي عشر","الثاني عشر","الثالث عشر","الرابع عشر","الخامس عشر","السادس عشر","السابع عشر","الثامن عشر","التاسع عشر","العشرون",
                "الحادي والعشرون","الثاني والعشرون","الثالث والعشرون","الرابع والعشرون","الخامس والعشرون","السادس والعشرون","السابع والعشرون","الثامن والعشرون","التاسع والعشرون","الثلاثون"]

// MARK: - Line text
/// The words of an ayah line in reading order, with the rub' mark on its ayah's first word and each
/// ayah's number ornament right after its last word (or at the line head when the number alone wrapped).
func lineText(_ line: Line) -> String {
    var pieces: [String] = []
    let endSet = Set(line.ends.map { "\($0[0]):\($0[1])" })
    var placed = Set<String>()
    for (i, w) in line.words.enumerated() {
        let s = w[0], a = w[1], pos = w[2]
        let ayah = surahs[s]!.ayahs[a - 1]
        var tok = pos - 1 < ayah.tokens.count ? ayah.tokens[pos - 1] : ""
        if pos == 1 && ayah.rub { tok = "\u{06DE} " + tok }
        pieces.append(tok)
        let key = "\(s):\(a)"
        let last = i == line.words.count - 1 || line.words[i + 1][0] != s || line.words[i + 1][1] != a
        if last && endSet.contains(key) { pieces.append(arabicIndic(a)); placed.insert(key) }
    }
    for e in line.ends where !placed.contains("\(e[0]):\(e[1])") {
        pieces.insert(arabicIndic(e[1]), at: 0)
    }
    return pieces.joined(separator: " ")
}

// Nominal size: the 25th percentile of each ayah line's exact-fit size, over the whole mushaf.
var fitSizes: [CGFloat] = []
var lineTextCache: [String: String] = [:]
for p in allPages {
    for (i, line) in layout[p]!.enumerated() where line.type == "ayah" && !line.words.isEmpty {
        let t = lineText(line); lineTextCache["\(p):\(i)"] = t
        let w1 = widthAtUnitSize(t, fontQuran)
        if w1 > 0 && !line.centered { fitSizes.append(D.measure / w1) }
    }
}
fitSizes.sort()
let nominal: CGFloat = fitSizes.isEmpty ? 18 : fitSizes[fitSizes.count / 4]
print(String(format: "nominal text size %.2f (fit sizes p5 %.2f median %.2f p95 %.2f), lines %d", nominal,
             fitSizes[fitSizes.count / 20], fitSizes[fitSizes.count / 2], fitSizes[fitSizes.count * 19 / 20], fitSizes.count))

// MARK: - Drawing helpers
func stroke(_ ctx: CGContext, _ path: CGPath, _ color: CGColor, _ width: CGFloat) {
    ctx.saveGState(); ctx.addPath(path); ctx.setStrokeColor(color); ctx.setLineWidth(width); ctx.strokePath(); ctx.restoreGState()
}
func fill(_ ctx: CGContext, _ path: CGPath, _ color: CGColor, evenOdd: Bool = false) {
    ctx.saveGState(); ctx.addPath(path); ctx.setFillColor(color); evenOdd ? ctx.fillPath(using: .evenOdd) : ctx.fillPath(); ctx.restoreGState()
}
func drawText(_ ctx: CGContext, _ s: String, _ font: CTFont, _ color: CGColor, centerX: CGFloat, baseline: CGFloat) -> CGFloat {
    let line = CTLineCreateWithAttributedString(attributed(s, font, color))
    let w = lineWidth(line)
    ctx.textPosition = CGPoint(x: centerX - w / 2, y: baseline)
    CTLineDraw(line, ctx)
    return w
}
func star8(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
    let p = CGMutablePath()
    for i in 0..<16 {
        let ang = CGFloat(i) * .pi / 8 - .pi / 2
        let rr = i % 2 == 0 ? r : r * 0.45
        let pt = CGPoint(x: cx + rr * cos(ang), y: cy + rr * sin(ang))
        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
    }
    p.closeSubpath(); return p
}
func rosette(_ ctx: CGContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
    fill(ctx, star8(cx, cy, r), C.gold)
    fill(ctx, CGPath(ellipseIn: CGRect(x: cx - r * 0.22, y: cy - r * 0.22, width: r * 0.44, height: r * 0.44), transform: nil), C.cream)
}

/// A braided strapwork band: two interlacing strands with a cream eye at every crossing. `rect` is the
/// band's box; the strands run along its long axis.
func braid(_ ctx: CGContext, _ rect: CGRect, horizontal: Bool, period: CGFloat = 20) {
    ctx.saveGState(); ctx.clip(to: rect)
    fill(ctx, CGPath(rect: rect, transform: nil), C.teal)
    let thick = horizontal ? rect.height : rect.width
    let length = horizontal ? rect.width : rect.height
    let amp = thick * 0.30
    let mid = horizontal ? rect.midY : rect.midX
    let start = horizontal ? rect.minX : rect.minY
    // pinstripes
    let inset: CGFloat = 1.6
    let pin = CGMutablePath()
    if horizontal {
        pin.move(to: CGPoint(x: rect.minX, y: rect.minY + inset)); pin.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + inset))
        pin.move(to: CGPoint(x: rect.minX, y: rect.maxY - inset)); pin.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - inset))
    } else {
        pin.move(to: CGPoint(x: rect.minX + inset, y: rect.minY)); pin.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        pin.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY)); pin.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
    }
    stroke(ctx, pin, C.cream, 0.55)
    // strands
    for phase in [0, 1] {
        let path = CGMutablePath()
        var t: CGFloat = start - period
        let sign: CGFloat = phase == 0 ? 1 : -1
        var first = true
        while t < start + length + period {
            let p0 = t, p1 = t + period / 2
            let y0 = mid + sign * amp, y1 = mid - sign * amp
            let c = period * 0.27
            if horizontal {
                if first { path.move(to: CGPoint(x: p0, y: y0)); first = false }
                path.addCurve(to: CGPoint(x: p1, y: y1), control1: CGPoint(x: p0 + c, y: y0), control2: CGPoint(x: p1 - c, y: y1))
                path.addCurve(to: CGPoint(x: p1 + period / 2, y: y0), control1: CGPoint(x: p1 + c, y: y1), control2: CGPoint(x: p1 + period / 2 - c, y: y0))
            } else {
                if first { path.move(to: CGPoint(x: y0, y: p0)); first = false }
                path.addCurve(to: CGPoint(x: y1, y: p1), control1: CGPoint(x: y0, y: p0 + c), control2: CGPoint(x: y1, y: p1 - c))
                path.addCurve(to: CGPoint(x: y0, y: p1 + period / 2), control1: CGPoint(x: y1, y: p1 + c), control2: CGPoint(x: y0, y: p1 + period / 2 - c))
            }
            t += period
        }
        stroke(ctx, path, C.tealDark, 2.6)
        stroke(ctx, path, C.goldLight, 1.3)
    }
    // eyes at the crossings (every half period, at the strands' midline)
    var t = start + period / 4
    var k = 0
    while t < start + length {
        let c = horizontal ? CGPoint(x: t, y: mid) : CGPoint(x: mid, y: t)
        let r: CGFloat = k % 2 == 0 ? 1.7 : 1.2
        fill(ctx, CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r), transform: nil), k % 2 == 0 ? C.cream : C.gold)
        t += period / 2; k += 1
    }
    ctx.restoreGState()
}

func cornerBlock(_ ctx: CGContext, _ rect: CGRect) {
    fill(ctx, CGPath(rect: rect, transform: nil), C.tealDark)
    stroke(ctx, CGPath(rect: rect.insetBy(dx: 1.2, dy: 1.2), transform: nil), C.goldLight, 0.5)
    rosette(ctx, rect.midX, rect.midY, rect.width * 0.36)
}

/// The full frame ring (rules, braid band, corners) around `outer` (the band's outer edge box).
func frame(_ ctx: CGContext, outerRuleRect: CGRect, band: CGFloat, gap: CGFloat, ruleW: CGFloat, innerRuleW: CGFloat, period: CGFloat) {
    stroke(ctx, CGPath(rect: outerRuleRect, transform: nil), C.gold, ruleW)
    let bandOuter = outerRuleRect.insetBy(dx: ruleW / 2 + gap, dy: ruleW / 2 + gap)
    let bandInner = bandOuter.insetBy(dx: band, dy: band)
    // sides
    braid(ctx, CGRect(x: bandInner.minX, y: bandInner.maxY, width: bandInner.width, height: band), horizontal: true, period: period)
    braid(ctx, CGRect(x: bandInner.minX, y: bandOuter.minY, width: bandInner.width, height: band), horizontal: true, period: period)
    braid(ctx, CGRect(x: bandOuter.minX, y: bandInner.minY, width: band, height: bandInner.height), horizontal: false, period: period)
    braid(ctx, CGRect(x: bandInner.maxX, y: bandInner.minY, width: band, height: bandInner.height), horizontal: false, period: period)
    for (x, y) in [(bandOuter.minX, bandOuter.minY), (bandInner.maxX, bandOuter.minY), (bandOuter.minX, bandInner.maxY), (bandInner.maxX, bandInner.maxY)] {
        cornerBlock(ctx, CGRect(x: x, y: y, width: band, height: band))
    }
    stroke(ctx, CGPath(rect: bandOuter, transform: nil), C.gold, 0.5)
    stroke(ctx, CGPath(rect: bandInner, transform: nil), C.gold, 0.5)
    let innerRule = bandInner.insetBy(dx: gap + innerRuleW / 2, dy: gap + innerRuleW / 2)
    stroke(ctx, CGPath(rect: innerRule, transform: nil), C.gold, innerRuleW)
}

func cartouche(_ rect: CGRect) -> CGPath {
    let r = rect.height / 2
    return CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)
}

// MARK: - Page
let W = D.pageWidth, H = D.pageHeight
let contentLeft = D.contentInset, contentRight = W - D.contentInset
let contentTop = H - D.contentInset, contentBottom = D.contentInset
let textLeft = contentLeft + D.sidePad, textRight = contentRight - D.sidePad
let textCenterX = (textLeft + textRight) / 2
let textTop = contentTop - D.topStrip - D.topGap          // top of the text block
let firstBaseline = textTop - D.textAscent

func drawPage(_ ctx: CGContext, _ p: Int) {
    let lines = layout[p]!
    fill(ctx, CGPath(rect: CGRect(x: 0, y: 0, width: W, height: H), transform: nil), C.paper)
    let pm = D.paperMargin
    frame(ctx, outerRuleRect: CGRect(x: pm + D.outerRule / 2, y: pm + D.outerRule / 2, width: W - 2 * pm - D.outerRule, height: H - 2 * pm - D.outerRule),
          band: D.band, gap: D.gap1, ruleW: D.outerRule, innerRuleW: D.innerRule, period: 20)

    // header strip: surah names (right) and juz (left) in a teal cartouche
    var pageSurahs: [Int] = []; var juz = 0
    for l in lines {
        if l.type == "surah", !pageSurahs.contains(l.surah) { pageSurahs.append(l.surah) }
        for w in l.words {
            if !pageSurahs.contains(w[0]) { pageSurahs.append(w[0]) }
            juz = max(juz, surahs[w[0]]!.ayahs[w[1] - 1].juz)
        }
    }
    pageSurahs.sort()
    let strip = CGRect(x: contentLeft, y: contentTop - D.topStrip + 1, width: contentRight - contentLeft, height: D.topStrip - 2)
    fill(ctx, cartouche(strip), C.teal)
    stroke(ctx, cartouche(strip), C.gold, 0.8)
    stroke(ctx, cartouche(strip.insetBy(dx: 2.2, dy: 2.2)), C.goldLight, 0.45)
    let labelFont = sized(fontLabelBold, 10.5)
    let labelBase = strip.midY - 3.6
    let surahLabel = pageSurahs.map { "سورة " + surahs[$0]!.name }.joined(separator: "   ")
    let sl = CTLineCreateWithAttributedString(attributed(surahLabel, labelFont, C.cream))
    ctx.textPosition = CGPoint(x: strip.maxX - 16 - lineWidth(sl), y: labelBase); CTLineDraw(sl, ctx)
    if juz > 0 {
        let jl = CTLineCreateWithAttributedString(attributed("الجزء " + juzNames[juz - 1], labelFont, C.cream))
        ctx.textPosition = CGPoint(x: strip.minX + 16, y: labelBase); CTLineDraw(jl, ctx)
    }
    rosette(ctx, strip.midX, strip.midY, 5.2)

    // page number medallion
    let medY = contentBottom + D.bottomStrip / 2
    let medR: CGFloat = 8.6
    fill(ctx, CGPath(ellipseIn: CGRect(x: textCenterX - medR, y: medY - medR, width: 2 * medR, height: 2 * medR), transform: nil), C.cream)
    stroke(ctx, CGPath(ellipseIn: CGRect(x: textCenterX - medR, y: medY - medR, width: 2 * medR, height: 2 * medR), transform: nil), C.gold, 0.9)
    stroke(ctx, CGPath(ellipseIn: CGRect(x: textCenterX - medR + 1.8, y: medY - medR + 1.8, width: 2 * medR - 3.6, height: 2 * medR - 3.6), transform: nil), C.goldLight, 0.4)
    _ = drawText(ctx, arabicIndic(p), sized(fontLabelBold, 9.2), C.tealDark, centerX: textCenterX, baseline: medY - 3.2)
    for dx: CGFloat in [-1, 1] {
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: textCenterX + dx * (medR + 8), y: medY)); hair.addLine(to: CGPoint(x: textCenterX + dx * (medR + 44), y: medY))
        stroke(ctx, hair, C.goldLight, 0.6)
        fill(ctx, star8(textCenterX + dx * (medR + 50), medY, 2.6), C.gold)
    }

    // opening spread: the used lines sit centered in an illuminated inner panel
    let used = lines.indices.filter { lines[$0].type != "empty" }
    let shift: CGFloat = p <= 2 ? CGFloat(D.linesPerPage - used.count) * D.pitch / 2 : 0
    if p <= 2, let lo = used.first, let hi = used.last {
        let top = firstBaseline - CGFloat(lo) * D.pitch - shift + D.textAscent * 0.85
        let bottom = firstBaseline - CGFloat(hi) * D.pitch - shift - D.textDescent * 0.9
        let panel = CGRect(x: textLeft - 4, y: bottom - 10, width: textRight - textLeft + 8, height: top - bottom + 20)
        let field = CGRect(x: contentLeft, y: contentBottom + D.bottomStrip + 4, width: contentRight - contentLeft, height: textTop - contentBottom - D.bottomStrip - 4)
        fill(ctx, CGPath(rect: field, transform: nil), C.tealTint)
        // lattice on the field
        ctx.saveGState(); ctx.clip(to: field)
        let lat = CGMutablePath()
        var x = field.minX - field.height
        while x < field.maxX + field.height {
            lat.move(to: CGPoint(x: x, y: field.minY)); lat.addLine(to: CGPoint(x: x + field.height, y: field.maxY))
            lat.move(to: CGPoint(x: x + field.height, y: field.minY)); lat.addLine(to: CGPoint(x: x, y: field.maxY))
            x += 14
        }
        stroke(ctx, lat, rgb(0.82, 0.91, 0.90), 0.4)
        ctx.restoreGState()
        stroke(ctx, CGPath(rect: field, transform: nil), C.gold, 0.6)
        fill(ctx, CGPath(rect: panel.insetBy(dx: -16, dy: -16), transform: nil), C.paper)
        frame(ctx, outerRuleRect: panel.insetBy(dx: -15, dy: -15), band: 9, gap: 1.8, ruleW: 0.7, innerRuleW: 0.5, period: 14)
        for (cx, cy) in [(field.minX + 14, field.minY + 14), (field.maxX - 14, field.minY + 14), (field.minX + 14, field.maxY - 14), (field.maxX - 14, field.maxY - 14)] {
            rosette(ctx, cx, cy, 7)
        }
    }

    for (i, line) in lines.enumerated() {
        let baseline = firstBaseline - CGFloat(i) * D.pitch - shift
        switch line.type {
        case "surah":
            let name = "سُورَةُ " + surahs[line.surah]!.name
            let h = D.pitch * 0.78
            let box = CGRect(x: textLeft, y: baseline - h * 0.36, width: textRight - textLeft, height: h)
            fill(ctx, cartouche(box), C.teal)
            stroke(ctx, cartouche(box), C.gold, 0.9)
            stroke(ctx, cartouche(box.insetBy(dx: 2.4, dy: 2.4)), C.goldLight, 0.5)
            let f = sized(fontQuran, nominal * 0.92)
            let w = drawText(ctx, name, f, C.cream, centerX: box.midX, baseline: box.midY - nominal * 0.30)
            let side = (box.width - w) / 2
            if side > 78 {
                let small = sized(fontLabel, 7.6)
                let s = surahs[line.surah]!
                let kind = s.type == "makkan" ? "مَكِّيَّة" : "مَدَنِيَّة"
                let cnt = "آيَاتُهَا " + arabicIndic(s.count)
                let kl = CTLineCreateWithAttributedString(attributed(kind, small, C.cream))
                ctx.textPosition = CGPoint(x: box.maxX - 16 - lineWidth(kl), y: box.midY - 2.6); CTLineDraw(kl, ctx)
                let cl = CTLineCreateWithAttributedString(attributed(cnt, small, C.cream))
                ctx.textPosition = CGPoint(x: box.minX + 16, y: box.midY - 2.6); CTLineDraw(cl, ctx)
                rosette(ctx, box.midX + w / 2 + 11, box.midY, 3.2); rosette(ctx, box.midX - w / 2 - 11, box.midY, 3.2)
            }
        case "basmalah":
            let w1 = widthAtUnitSize("\u{FDFD}", fontOrnament)
            let size = D.measure * 0.52 / w1
            _ = drawText(ctx, "\u{FDFD}", sized(fontOrnament, size), C.ink, centerX: textCenterX, baseline: baseline - size * 0.02)
        case "ayah":
            guard !line.words.isEmpty || !line.ends.isEmpty else { continue }
            let t = lineTextCache["\(p):\(i)"] ?? lineText(line)
            let w1 = widthAtUnitSize(t, fontQuran)
            let exact = D.measure / w1
            var size: CGFloat
            if line.centered {
                size = min(nominal, exact)
            } else {
                size = min(max(exact, nominal * 0.92), nominal * 1.10)
                if size * w1 > D.measure + 0.01 { size = exact }
            }
            // the ornament digits in the marker color, the words in ink
            let attr = CFAttributedStringCreateMutable(nil, 0)!
            CFAttributedStringReplaceString(attr, CFRange(location: 0, length: 0), t as CFString)
            let f = sized(fontQuran, size)
            CFAttributedStringSetAttribute(attr, CFRange(location: 0, length: CFAttributedStringGetLength(attr)), kCTFontAttributeName, f)
            CFAttributedStringSetAttribute(attr, CFRange(location: 0, length: CFAttributedStringGetLength(attr)), kCTForegroundColorAttributeName, C.ink)
            let ns = t as NSString
            var scan = 0
            while scan < ns.length {
                let ch = ns.character(at: scan)
                if ch >= 0x0660 && ch <= 0x0669 {
                    var end = scan
                    while end < ns.length, ns.character(at: end) >= 0x0660, ns.character(at: end) <= 0x0669 { end += 1 }
                    CFAttributedStringSetAttribute(attr, CFRange(location: scan, length: end - scan), kCTForegroundColorAttributeName, C.marker)
                    scan = end
                } else { scan += 1 }
            }
            let line0 = CTLineCreateWithAttributedString(attr)
            let natural = lineWidth(line0)
            if line.centered || natural >= D.measure - 0.5 {
                ctx.textPosition = CGPoint(x: textCenterX - natural / 2, y: baseline)
                CTLineDraw(line0, ctx)
            } else {
                let just = CTLineCreateJustifiedLine(line0, 1.0, Double(D.measure)) ?? line0
                ctx.textPosition = CGPoint(x: textLeft, y: baseline)
                CTLineDraw(just, ctx)
            }
        default:
            break
        }
    }
}

// MARK: - Output
var mediaBox = CGRect(x: 0, y: 0, width: W, height: H)
let info: [CFString: Any] = [kCGPDFContextTitle: "المصحف الشريف برواية حفص عن عاصم", kCGPDFContextAuthor: "Al-Islam"]
let ctx = CGContext(outURL as CFURL, mediaBox: &mediaBox, info as CFDictionary)!
let pagesToDraw = onlyPages.map { s in allPages.filter { s.contains($0) } } ?? allPages
for p in pagesToDraw {
    ctx.beginPDFPage(nil)
    drawPage(ctx, p)
    ctx.endPDFPage()
}
ctx.closePDF()
print(String(format: "wrote %@: %d pages, %.1f x %.1f pt (ratio %.2f)", outURL.path, pagesToDraw.count, W, H, H / W))
