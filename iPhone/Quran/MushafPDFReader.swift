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

/// One page of the facsimile. A `PDFView` pinned to a single page rather than PDFKit's own pager: the pager
/// is the `TabView` above, which is what lets the pages turn right-to-left like the rest of the mushaf.
/// Keeping PDFKit for the page itself is what buys crisp vector rendering at any zoom plus pinch-to-zoom.
private struct MushafPDFPageView: UIViewRepresentable {
    let page: PDFPage

    /// Remembers which `PDFPage` is currently installed. The view holds a *copy* of the page (see `install`),
    /// so the copy can't be compared back to the source - the original reference has to be tracked here.
    final class Coordinator {
        var installed: PDFPage?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
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
        if let copy = page.copy() as? PDFPage { document.insert(copy, at: 0) }
        view.document = document
        coordinator.installed = page
        // `autoScales` only computes the fit-to-width scale once the view has a size, so re-assert it after
        // layout; without this the first page of a fresh reader comes up at 100% and overflows the screen.
        DispatchQueue.main.async { view.autoScales = true }
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

    var body: some View {
        Group {
            if document.pageCount > 0,
               let page = document.page(at: min(max(mushafPage - 1, 0), document.pageCount - 1)) {
                MushafPDFPageView(page: page)
            } else {
                Color.clear
            }
        }
        .nightInverted(settings.mushafPDFNightMode)
    }
}

private extension View {
    /// Hue-preserving luminance invert - the standard document night mode. A straight `colorInvert()` would
    /// swing the page's colours to their opposites; rotating the hue a half turn afterwards puts them back,
    /// leaving only the light/dark flip. Off by default, and then no filter is attached at all.
    @ViewBuilder
    func nightInverted(_ enabled: Bool) -> some View {
        if enabled {
            self.colorInvert().hueRotation(.degrees(180))
        } else {
            self
        }
    }
}
#endif
