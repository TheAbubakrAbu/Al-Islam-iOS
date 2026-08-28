// Render Arabic strings with CoreText (the same shaping engine iOS uses) into a PNG, one font
// file per run, and print which font each run actually used - a system-font name in that list
// means the face lacked a codepoint and CoreText fell back mid-word. No simulator needed.
//   swiftc -O -o /tmp/render Scripts/render_arabic.swift
//   /tmp/render Resources/Fonts/Warsh.ttf AUTO 64 out.png "ٱلۡحَمۡدُ لِلَّهِ" "لَٱنفَضُّواْ"
// usage: render <font.ttf> <ignored> <size> <out.png> <text> [<text>...]
import Foundation
import CoreText
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 6 else { fputs("usage: render font.ttf name size out.png text...\n", stderr); exit(1) }
let fontURL = URL(fileURLWithPath: args[1])
var err: Unmanaged<CFError>?
guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &err) else {
    fputs("register failed: \(String(describing: err?.takeRetainedValue()))\n", stderr); exit(2)
}
let descs = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as! [CTFontDescriptor]
let size = CGFloat(Double(args[3]) ?? 40)
let font = CTFontCreateWithFontDescriptor(descs[0], size, nil)
let psName = CTFontCopyPostScriptName(font) as String
let texts = Array(args[5...])
let lineHeight = size * 2.2
let width = 1400
let height = Int(lineHeight * CGFloat(texts.count)) + 20
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
ctx.textMatrix = .identity
var y = CGFloat(height) - lineHeight * 0.75
for text in texts {
    let attrs: [NSAttributedString.Key: Any] = [kCTFontAttributeName as NSAttributedString.Key: font, kCTForegroundColorAttributeName as NSAttributedString.Key: CGColor(red: 0, green: 0, blue: 0, alpha: 1)]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    let w = CTLineGetTypographicBounds(line, nil, nil, nil)
    ctx.textPosition = CGPoint(x: CGFloat(width) - 20 - CGFloat(w), y: y)
    CTLineDraw(line, ctx)
    // report which font each run actually used (fallback detection)
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    var used = Set<String>()
    for run in runs {
        let a = CTRunGetAttributes(run) as NSDictionary
        if let f = a[kCTFontAttributeName] { used.insert(CTFontCopyPostScriptName(f as! CTFont) as String) }
    }
    print("\(psName) | runs=\(runs.count) fonts=\(used.sorted()) | \(text)")
    y -= lineHeight
}
let img = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[4]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
