import Foundation
import CoreGraphics
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

// Renders one sticker: the source scaled so its longest side is 618 px (iMessage's cap), with
// continuous (squircle) corners cut to transparency, written as PNG. JPEG has no alpha, so every
// rounded sticker is a PNG, and the caller squeezes any file over 500 KB with pngquant.

let args = CommandLine.arguments
guard args.count >= 4, let radius = Double(args[3]) else {
    fputs("usage: mkroundsticker <source> <out.png> <corner radius px at 618>\n", stderr); exit(2)
}
let srcURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])

// ImageIO's thumbnailer downsamples a 4096 px wallpaper far more cleanly than one CGContext draw.
let options: [CFString: Any] = [
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceThumbnailMaxPixelSize: 618,
    kCGImageSourceCreateThumbnailWithTransform: true,
]
guard let source = CGImageSourceCreateWithURL(srcURL as CFURL, nil),
      let src = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
    fputs("cannot read \(srcURL.path)\n", stderr); exit(1)
}

let w = src.width, h = src.height
guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fputs("context failed\n", stderr); exit(1)
}
let rect = CGRect(x: 0, y: 0, width: w, height: h)
ctx.draw(src, in: rect)

// Erase the four corners: the even-odd fill of the frame plus the rounded rect covers only what
// lies outside the shape. A blend only touches pixels its fill covers, so a destination-in fill of
// the shape itself would leave the corners alone. The fill is antialiased, so the edge stays smooth.
let shape = RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect).cgPath
ctx.setBlendMode(.destinationOut)
ctx.addRect(rect)
ctx.addPath(shape)
ctx.setFillColor(CGColor(gray: 0, alpha: 1))
ctx.fillPath(using: .evenOdd)

guard let out = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fputs("encode failed\n", stderr); exit(1)
}
CGImageDestinationAddImage(dest, out, nil)
guard CGImageDestinationFinalize(dest) else { fputs("write failed \(outURL.path)\n", stderr); exit(1) }
fputs("\(outURL.lastPathComponent): \(w)x\(h), radius \(Int(radius))\n", stderr)
