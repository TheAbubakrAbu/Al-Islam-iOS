import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Renders the iMessage App Icon set from the square 1024 app icon.
// Non-square slots letterbox the square art on a field sampled from the icon's own corner,
// so nothing is cropped and the pad blends into the artwork.

let args = CommandLine.arguments
guard args.count >= 3 else { fputs("usage: mkstickericon <source.png> <outDir>\n", stderr); exit(2) }
let srcURL = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])

guard let srcProvider = CGDataProvider(url: srcURL as CFURL),
      let src = CGImage(pngDataProviderSource: srcProvider, decode: nil,
                        shouldInterpolate: true, intent: .defaultIntent) else {
    fputs("cannot read \(srcURL.path)\n", stderr); exit(1)
}

// Sample the corner pixel for the pad color.
let cs = CGColorSpaceCreateDeviceRGB()
var px: [UInt8] = [0, 0, 0, 0]
if let c = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                     space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
    // Draw the image scaled so its top-left pixel lands in our 1x1 buffer.
    c.draw(src, in: CGRect(x: 0, y: 1 - CGFloat(src.height), width: CGFloat(src.width), height: CGFloat(src.height)))
}
let pad = (r: CGFloat(px[0]) / 255, g: CGFloat(px[1]) / 255, b: CGFloat(px[2]) / 255)
fputs(String(format: "pad color: #%02X%02X%02X\n", px[0], px[1], px[2]), stderr)

// (filename, width, height) — the 13 slots Xcode's stickersiconset template requires.
let slots: [(String, Int, Int)] = [
    ("icon-29@2x.png",           58,   58),
    ("icon-29@3x.png",           87,   87),
    ("icon-60x45@2x.png",       120,   90),
    ("icon-60x45@3x.png",       180,  135),
    ("icon-ipad-29@2x.png",      58,   58),
    ("icon-ipad-67x50@2x.png",  134,  100),
    ("icon-ipad-74x55@2x.png",  148,  110),
    ("icon-27x20@2x.png",        54,   40),
    ("icon-27x20@3x.png",        81,   60),
    ("icon-32x24@2x.png",        64,   48),
    ("icon-32x24@3x.png",        96,   72),
    ("icon-marketing.png",     1024,  768),
]

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for (name, w, h) in slots {
    guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                              space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fputs("context failed for \(name)\n", stderr); exit(1)
    }
    ctx.interpolationQuality = .high
    ctx.setFillColor(red: pad.r, green: pad.g, blue: pad.b, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

    // Aspect-fit the square source, centered.
    let scale = min(CGFloat(w) / CGFloat(src.width), CGFloat(h) / CGFloat(src.height))
    let dw = CGFloat(src.width) * scale, dh = CGFloat(src.height) * scale
    let box = CGRect(x: (CGFloat(w) - dw) / 2, y: (CGFloat(h) - dh) / 2, width: dw, height: dh)

    // Letterbox bars: stretch the source's own edge column/row outward instead of a flat fill.
    // The app icon's background is a left-to-right orange->green gradient, so a single pad color
    // matches one side and clashes with the other; extending each edge continues the gradient.
    let edge = max(1, src.width / 256)
    if box.minX > 0, let l = src.cropping(to: CGRect(x: 0, y: 0, width: edge, height: src.height)) {
        ctx.draw(l, in: CGRect(x: 0, y: box.minY, width: box.minX, height: box.height))
    }
    if box.maxX < CGFloat(w),
       let r = src.cropping(to: CGRect(x: src.width - edge, y: 0, width: edge, height: src.height)) {
        ctx.draw(r, in: CGRect(x: box.maxX, y: box.minY, width: CGFloat(w) - box.maxX, height: box.height))
    }
    // CGImage crop origin is top-left; CGContext draws bottom-up, so "top" row = y 0 in the source.
    if box.maxY < CGFloat(h), let t = src.cropping(to: CGRect(x: 0, y: 0, width: src.width, height: edge)) {
        ctx.draw(t, in: CGRect(x: 0, y: box.maxY, width: CGFloat(w), height: CGFloat(h) - box.maxY))
    }
    if box.minY > 0,
       let b = src.cropping(to: CGRect(x: 0, y: src.height - edge, width: src.width, height: edge)) {
        ctx.draw(b, in: CGRect(x: 0, y: 0, width: CGFloat(w), height: box.minY))
    }

    ctx.draw(src, in: box)

    guard let img = ctx.makeImage() else { fputs("render failed \(name)\n", stderr); exit(1) }
    let url = outDir.appendingPathComponent(name)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fputs("dest failed \(name)\n", stderr); exit(1)
    }
    CGImageDestinationAddImage(dest, img, nil)
    if !CGImageDestinationFinalize(dest) { fputs("write failed \(name)\n", stderr); exit(1) }
    print("\(name) \(w)x\(h)")
}
