#if os(iOS)
import SwiftUI
import PDFKit

/// The printed mushaf as bundled PDFs - one per riwayah, from the Islamweb mushaf series.
///
/// Every one of the 20 files is exactly **604 pages**, laid out on the Madani page division: PDF page N is
/// mushaf page N, page 1 is al-Fatihah and page 604 closes with an-Nas. That makes the mapping from the app's
/// own pagination a straight `page -> page` - no lookup table, no offset.
///
/// The match is not perfect and is not meant to be: the app repaginates per riwayah from its own ayah data,
/// and the beta riwayat carry their own canonical ayah counts, so a page here and there drifts by one against
/// the printed original. The PDF is a facsimile to read, not the source of the app's page numbers.
enum MushafPDFLibrary {
    /// Riwayah tag -> file base name in `Resources/Mushaf`. Named qiraah-first (`01-asim-hafs`) so the folder
    /// sorts by the Ten Qiraat in their canonical order.
    ///
    /// Two files from the original Islamweb set are deliberately NOT bundled: a second, image-based rendering
    /// of Ibn Jammaz (identical text, heavier border, 49 MB against 4.3 MB) and Warsh via tariq al-Asbahani,
    /// which is a genuinely different transmission with no riwayah slot in the app's twenty.
    static func fileName(for tag: String) -> String? {
        switch Settings.Riwayah.canonicalTag(tag) {
        case Settings.Riwayah.hafsTag:     return "01-asim-hafs"
        case Settings.Riwayah.shubah:      return "01-asim-shubah"
        case Settings.Riwayah.warsh:       return "02-nafi-warsh"
        case Settings.Riwayah.qaloon:      return "02-nafi-qalun"
        case Settings.Riwayah.buzzi:       return "03-ibn-kathir-al-bazzi"
        case Settings.Riwayah.qunbul:      return "03-ibn-kathir-qunbul"
        case Settings.Riwayah.duri:        return "04-abu-amr-ad-duri"
        case Settings.Riwayah.susi:        return "04-abu-amr-as-susi"
        case Settings.Riwayah.hisham:      return "05-ibn-amir-hisham"
        case Settings.Riwayah.ibnDhakwan:  return "05-ibn-amir-ibn-dhakwan"
        case Settings.Riwayah.khalaf:      return "06-hamzah-khalaf"
        case Settings.Riwayah.khallad:     return "06-hamzah-khallad"
        case Settings.Riwayah.abuHarith:   return "07-al-kisai-abu-al-harith"
        case Settings.Riwayah.duriKisai:   return "07-al-kisai-ad-duri"
        case Settings.Riwayah.ibnWardan:   return "08-abu-jafar-ibn-wardan"
        case Settings.Riwayah.ibnJammaz:   return "08-abu-jafar-ibn-jammaz"
        case Settings.Riwayah.ruways:      return "09-yaqub-ruways"
        case Settings.Riwayah.rawh:        return "09-yaqub-rawh"
        case Settings.Riwayah.ishaq:       return "10-khalaf-al-ashir-ishaq"
        case Settings.Riwayah.idris:       return "10-khalaf-al-ashir-idris"
        default:                           return nil
        }
    }

    /// The PDFs ship as a **folder reference**, so they land in the bundle under `Mushaf PDFs/` rather than
    /// flat. That is deliberate: dropping another riwayah's file into `Resources/Mushaf PDFs` ships it with
    /// no Xcode project edit at all, and this lookup picks it up automatically.
    ///
    /// They ship as `.pdf.xz`, not `.pdf`: the files are pure vector with per-stream Flate, and re-doing the
    /// whole file as ONE solid xz stream is a third of the size, fully lossless (66 MB -> 22 MB across the
    /// set). A plain `.pdf` alongside still wins for that riwayah, so a quick drop-in needs no compression.
    static func bundledURL(for tag: String) -> (url: URL, isCompressed: Bool)? {
        guard let name = fileName(for: tag) else { return nil }
        if let plain = Bundle.main.url(forResource: name, withExtension: "pdf", subdirectory: "Mushaf PDFs")
            ?? Bundle.main.url(forResource: name, withExtension: "pdf", subdirectory: "Mushaf") {
            return (plain, false)
        }
        if let packed = Bundle.main.url(forResource: name, withExtension: "pdf.xz", subdirectory: "Mushaf PDFs") {
            return (packed, true)
        }
        return nil
    }

    /// Whether this riwayah has a bundled facsimile. The PDF option hides itself when it doesn't, so a
    /// partial set of files degrades to "no PDF for this riwayah" instead of a blank reader.
    static func isAvailable(for tag: String) -> Bool { bundledURL(for: tag) != nil }

    /// Per-edition content window (PDF points, origin bottom-left) holding just the Quran text: the
    /// islamweb header/logo, the legend strip, the URL footer and the decorative side borders all fall
    /// OUTSIDE it. Measured offline, per file, by rendering sample pages and walking inward from each
    /// page edge across the ink that is pixel-identical on every page (page furniture) until the first
    /// page-varying ink (real text) - the editions genuinely differ (header top vs bottom, borders or
    /// none, one- or two-row legends), so no shared inset works. Displayed crop = the page's own
    /// (text-hugging) crop box ∩ this window, so per-page tightness is kept where the file provides it.
    /// A file absent here (a new drop-in) simply shows uncropped.
    /// The sides keep 18pt of the print's own margin in front of the text (a text-hugging cut read
    /// as "no spacing" on screen - user feedback, then dialed down a touch from 24pt); top and
    /// bottom cut to just past the furniture ink.
    private static let contentWindows: [String: CGRect] = [
        "01-asim-hafs":              CGRect(x: 68.0, y: 65.0, width: 456.0, height: 696.0),
        "01-asim-shubah":            CGRect(x: 63.0, y: 127.0, width: 468.0, height: 627.0),
        "02-nafi-qalun":             CGRect(x: 67.91, y: 65.0, width: 456.4, height: 697.0),
        "02-nafi-warsh":             CGRect(x: 67.91, y: 143.0, width: 455.4, height: 602.0),
        "03-ibn-kathir-al-bazzi":    CGRect(x: 69.0, y: 112.0, width: 455.0, height: 635.0),
        "03-ibn-kathir-qunbul":      CGRect(x: 68.0, y: 108.0, width: 456.0, height: 642.0),
        "04-abu-amr-ad-duri":        CGRect(x: 67.91, y: 127.0, width: 456.4, height: 623.0),
        "04-abu-amr-as-susi":        CGRect(x: 67.91, y: 121.0, width: 455.4, height: 640.0),
        "05-ibn-amir-hisham":        CGRect(x: 68.0, y: 107.0, width: 456.0, height: 643.0),
        "05-ibn-amir-ibn-dhakwan":   CGRect(x: 68.0, y: 119.0, width: 457.0, height: 631.0),
        "06-hamzah-khalaf":          CGRect(x: 68.0, y: 125.0, width: 455.0, height: 625.0),
        "06-hamzah-khallad":         CGRect(x: 68.0, y: 120.0, width: 456.0, height: 630.0),
        "07-al-kisai-abu-al-harith": CGRect(x: 68.0, y: 128.0, width: 457.0, height: 622.0),
        "07-al-kisai-ad-duri":       CGRect(x: 58.0, y: 119.0, width: 483.0, height: 631.0),
        "08-abu-jafar-ibn-jammaz":   CGRect(x: 100.87, y: 108.0, width: 392.48, height: 637.0),
        "08-abu-jafar-ibn-wardan":   CGRect(x: 100.87, y: 108.0, width: 392.48, height: 637.0),
        "09-yaqub-rawh":             CGRect(x: 99.87, y: 109.0, width: 392.48, height: 636.0),
        "09-yaqub-ruways":           CGRect(x: 99.87, y: 111.0, width: 392.48, height: 634.0),
        "10-khalaf-al-ashir-idris":  CGRect(x: 100.0, y: 111.0, width: 393.0, height: 620.0),
        "10-khalaf-al-ashir-ishaq":  CGRect(x: 100.0, y: 111.0, width: 393.0, height: 620.0),
    ]

    /// The text-only window for a loaded document, keyed by its file base name - works for both the
    /// cache-extracted `.pdf.xz` copy and a plain bundled `.pdf`, whose names match by construction.
    static func contentWindow(for document: PDFDocument) -> CGRect? {
        guard let url = document.documentURL else { return nil }
        return contentWindows[url.deletingPathExtension().lastPathComponent]
    }

    /// The readable PDF's location: the bundled file itself when plain, otherwise a one-time extraction
    /// of the `.pdf.xz` into Caches. Extracting (not decompressing per open) keeps `PDFDocument` on its
    /// lazy file-mapped path - RAM stays at catalog-and-xref scale, not the whole 20+ MB file - and the
    /// system may evict the cache copy under disk pressure; it just re-extracts on next open.
    private static func readableURL(for tag: String) -> URL? {
        guard let (bundled, isCompressed) = bundledURL(for: tag) else { return nil }
        guard isCompressed else { return bundled }

        let name = bundled.deletingPathExtension().lastPathComponent   // "01-asim-hafs.pdf"
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MushafPDF", isDirectory: true)
        let extracted = cacheDir.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: extracted.path) { return extracted }

        guard let compressed = try? Data(contentsOf: bundled),
              let raw = SolidPack.xzDecompress(compressed) else { return nil }
        do {
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            try raw.write(to: extracted, options: .atomic)
            return extracted
        } catch {
            return nil
        }
    }

    /// Parsed documents, most-recently-used last. Opening a 604-page PDF costs enough to be felt as a pause
    /// on the riwayah switch, and a single slot meant flipping between two riwayat re-parsed *every* time.
    /// Three is enough to make comparing a handful of readings instant while staying small - a `PDFDocument`
    /// parses lazily, so a resident entry is the catalog and xref, not 604 rendered pages.
    @MainActor private static var cache: [(tag: String, document: PDFDocument)] = []
    private static let cacheLimit = 3

    @MainActor
    static func document(for tag: String) -> PDFDocument? {
        let key = Settings.Riwayah.canonicalTag(tag)
        if let hit = cache.firstIndex(where: { $0.tag == key }) {
            // Refresh on use so eviction sheds the least-recently-READ entry, not the first one loaded.
            let entry = cache.remove(at: hit)
            cache.append(entry)
            return entry.document
        }
        guard let url = readableURL(for: tag), let document = PDFDocument(url: url) else { return nil }
        if cache.count >= cacheLimit { cache.removeFirst() }
        cache.append((key, document))
        return document
    }
}

/// A `PDFView` whose zoom floor IS the fitted page: the default view (fit to screen) is already the maximum
/// zoom-out, so pinching out never shrinks the page into a floating island (user rule: "max zoom out should
/// be the default"). Pinned on every layout pass because `scaleFactorForSizeToFit` only exists once the view
/// has a size, and changes with it (rotation, the bars folding).
private final class FitFlooredPDFView: PDFView {
    override func layoutSubviews() {
        super.layoutSubviews()
        let fit = scaleFactorForSizeToFit
        guard fit > 0 else { return }
        minScaleFactor = fit
        maxScaleFactor = max(fit * 5, 5)
        if scaleFactor < fit { scaleFactor = fit }
    }
}

/// One page of the facsimile. A `PDFView` pinned to a single page rather than PDFKit's own pager: the pager
/// is the `TabView` above, which is what lets the pages turn right-to-left like the rest of the mushaf.
/// Keeping PDFKit for the page itself is what buys crisp vector rendering at any zoom plus pinch-to-zoom.
private struct MushafPDFPageView: UIViewRepresentable {
    let page: PDFPage
    /// The edition's text-only content window (`MushafPDFLibrary.contentWindow`); nil shows the page as-is.
    let cropWindow: CGRect?

    /// Remembers which `PDFPage` is currently installed. The view holds a *copy* of the page (see `install`),
    /// so the copy can't be compared back to the source - the original reference has to be tracked here.
    final class Coordinator {
        var installed: PDFPage?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PDFView {
        let view = FitFlooredPDFView()
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.autoScales = true
        view.backgroundColor = .clear
        view.pageShadowsEnabled = false
        // No document-level paging: this view shows exactly one page and the TabView moves between them.
        view.usePageViewController(false)
        install(page, in: view, coordinator: context.coordinator)
        return view
    }

    /// Was empty, which is what made a riwayah switch look stuck: changing riwayah hands this view a page
    /// from a DIFFERENT document, but with no update the `PDFView` kept drawing the page it was built with.
    /// The facsimile only caught up once the pager tore the view down and rebuilt it - i.e. after a swipe.
    func updateUIView(_ view: PDFView, context: Context) {
        guard context.coordinator.installed !== page else { return }
        install(page, in: view, coordinator: context.coordinator)
    }

    /// A one-page document rather than the whole mushaf: with the full document installed, `PDFView` would
    /// happily scroll on to its neighbours and fight the `TabView` that owns paging.
    private func install(_ page: PDFPage, in view: PDFView, coordinator: Coordinator) {
        let document = PDFDocument()
        if let copy = page.copy() as? PDFPage {
            // Trim the page furniture (islamweb header, legend strip, side borders) off the display:
            // the edition window cuts it away. Applied to the COPY - the source document's pages stay
            // untouched. The size guard keeps a malformed intersection (odd drop-in file) from
            // collapsing the page to a sliver.
            if let window = cropWindow {
                let trimmed = copy.bounds(for: .cropBox).intersection(window)
                if !trimmed.isNull, trimmed.width > 100, trimmed.height > 100 {
                    copy.setBounds(Self.inkCenteredCrop(trimmed, for: page), for: .cropBox)
                }
            }
            document.insert(copy, at: 0)
        }
        view.document = document
        coordinator.installed = page
        // `autoScales` only computes the fit-to-width scale once the view has a size, so re-assert it after
        // layout; without this the first page of a fresh reader comes up at 100% and overflows the screen.
        DispatchQueue.main.async { view.autoScales = true }
    }

    /// Measured ink-hugging crops, keyed by (file, page, window) - one small thumbnail render each,
    /// paid once per page ever per session.
    @MainActor private static var inkCenteredCrops: [String: CGRect] = [:]

    /// The window cut down vertically to the page's INK plus a small, symmetric cushion - so the text
    /// block sits with EQUAL air above and below, whatever the print left around it.
    ///
    /// The editions' own page crop boxes turned out NOT to hug the text vertically (Duri keeps ~200pt of
    /// blank paper under the last line on ordinary full pages), so the window-trimmed page showed its ink
    /// pushed to the top with a dead band below - glaring in night mode, where the blank paper is black
    /// ("too much space above, not equal to the bottom" - user report). The blank varies by edition AND
    /// by page (openers, surah ends), so no fixed window fixes it: measure the ink per page and cut to it.
    /// Cut, not slid: sliding the fixed-height window up to center the ink runs past the page's own crop
    /// box into the header furniture it had already excluded (verified on Duri - the shifted window
    /// re-admitted the islamweb header). The cushion is clamped to the furniture-free region and kept
    /// symmetric, so balance survives the clamp.
    @MainActor
    private static func inkCenteredCrop(_ trimmed: CGRect, for page: PDFPage) -> CGRect {
        let key = "\(page.document?.documentURL?.lastPathComponent ?? "")|\(page.label ?? "")|\(Int(trimmed.minY))|\(Int(trimmed.height))"
        if let hit = inkCenteredCrops[key] { return hit }

        var result = trimmed
        if let ink = inkSpan(of: page, in: trimmed), ink.top - ink.bottom > 60 {
            let pad = min(20, trimmed.maxY - ink.top, ink.bottom - trimmed.minY)
            result = CGRect(
                x: trimmed.minX,
                y: ink.bottom - pad,
                width: trimmed.width,
                height: (ink.top - ink.bottom) + pad * 2
            )
        }
        // A rebuild-scale bound, far above 604 pages x 3 resident editions; entries are tiny.
        if inkCenteredCrops.count > 4000 { inkCenteredCrops.removeAll(keepingCapacity: false) }
        inkCenteredCrops[key] = result
        return result
    }

    /// The vertical extent of the ink inside `rect`, in PDF coordinates (origin bottom-left), from a
    /// small grayscale rasterization: ~200pt tall, so the measure costs a few milliseconds of vector
    /// render once per page. Grayscale luminance keeps the colored prints honest - the red imaalah
    /// letters and pink tajweed ink all read dark, only paper reads light. Nil when the page has no
    /// ink at all (a malformed or blank drop-in), which keeps the original window.
    @MainActor
    private static func inkSpan(of page: PDFPage, in rect: CGRect) -> (top: CGFloat, bottom: CGFloat)? {
        guard let copy = page.copy() as? PDFPage else { return nil }
        copy.setBounds(rect, for: .cropBox)

        let height = 200
        let width = max(Int(rect.width / rect.height * CGFloat(height)), 40)
        let image = copy.thumbnail(of: CGSize(width: width, height: height), for: .cropBox)
        guard let cg = image.cgImage else { return nil }

        var pixels = [UInt8](repeating: 255, count: width * height)
        guard let ctx = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        // White under the page first: the thumbnail can carry transparent margins, which would
        // otherwise decode as 0 (ink-black) and defeat the whole measurement.
        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Buffer row 0 is the TOP scanline of the drawn page (verified empirically - a CGImage drawn
        // into a bitmap context lands with its top row first in memory). Mark the rows with real ink.
        var firstInkRow = -1, lastInkRow = -1
        for row in 0..<height {
            var count = 0
            for col in stride(from: 0, to: width, by: 2) where pixels[row * width + col] < 216 {
                count += 1
                if count > 4 { break }
            }
            if count > 4 {
                if firstInkRow < 0 { firstInkRow = row }
                lastInkRow = row
            }
        }
        guard firstInkRow >= 0 else { return nil }

        let scale = rect.height / CGFloat(height)
        let top = rect.maxY - CGFloat(firstInkRow) * scale
        let bottom = rect.maxY - CGFloat(lastInkRow + 1) * scale
        return (top, bottom)
    }
}

/// One mushaf page drawn from the facsimile, sized and positioned exactly like the composed page it replaces.
///
/// This is a **page body**, not a reader. It slots into `SurahPageReader`'s pager in place of
/// `MushafPageContent`, which is what lets the facsimile inherit the whole reader for free: the pinned surah
/// header, the page and juz pickers, the progress meters, search, and the play control. A parallel PDF reader
/// would have had to reimplement every one of those and would drift from the text reader over time.
///
/// `mushafPage` is the app's own 1-based page number, and the PDFs are cut on the same 604-page Madani
/// division, so the PDF index is simply `mushafPage - 1`.
struct MushafPDFPageBody: View {
    let document: PDFDocument
    let mushafPage: Int

    @EnvironmentObject private var settings: Settings
    @Environment(\.colorScheme) private var colorScheme

    private var appearance: MushafPDFAppearance {
        MushafPDFAppearance(rawValue: settings.mushafPDFAppearance) ?? .auto
    }

    private var isNight: Bool {
        appearance.isNight(inDarkScheme: colorScheme == .dark)
    }

    /// The reading theme's paper color (Sepia / Gray / Custom), honored on Auto only - an explicit
    /// Light or Night pick in the page menu keeps the plain white/black page it always meant.
    private var paperTint: Color? {
        guard appearance == .auto, settings.hasCustomThemeColors else { return nil }
        return settings.themeBackgroundColor
    }

    var body: some View {
        Group {
            if document.pageCount > 0,
               let page = document.page(at: min(max(mushafPage - 1, 0), document.pageCount - 1)) {
                MushafPDFPageView(page: page, cropWindow: MushafPDFLibrary.contentWindow(for: document))
            } else {
                Color.clear
            }
        }
        .nightInverted(isNight)
        .paperTinted(paperTint, night: isNight)
    }
}

private extension View {
    /// Hue-preserving luminance invert - the standard document night mode. A straight `colorInvert()` would
    /// swing the page's colours to their opposites; rotating the hue a half turn afterwards puts them back,
    /// leaving only the light/dark flip. When off, no filter is attached at all.
    @ViewBuilder
    func nightInverted(_ enabled: Bool) -> some View {
        if enabled {
            self.colorInvert().hueRotation(.degrees(180))
        } else {
            self
        }
    }

    /// Recolors the page "paper" to the reading theme. Multiply maps white paper onto the theme color
    /// while dark ink stays dark; over an already-inverted (night) page, screen lifts the black paper to
    /// the theme color while the light ink stays light. The leading `compositingGroup` flattens the
    /// PDFView so the blend sees the rendered page; the trailing one stops the blend from reaching
    /// whatever sits behind the reader.
    @ViewBuilder
    func paperTinted(_ color: Color?, night: Bool) -> some View {
        if let color {
            self
                .compositingGroup()
                .overlay(
                    Rectangle()
                        .fill(color)
                        .blendMode(night ? .screen : .multiply)
                        .allowsHitTesting(false)
                )
                .compositingGroup()
        } else {
            self
        }
    }
}
#endif
