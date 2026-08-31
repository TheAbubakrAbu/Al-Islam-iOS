import SwiftUI
import UIKit

#if os(iOS)
import PDFKit
#endif

#if os(iOS)

struct MushafPage: Identifiable {
    struct Segment: Identifiable {
        let surah: Surah
        let ayahs: [Ayah]
        /// The surah's last ayah is in this segment (the paginator sets it): the segment's closing
        /// line is then the surah's own last line, never a page cut - the print-matched composer
        /// justifies it per the print instead of leaving it natural.
        var endsSurah: Bool = false

        var id: Int { surah.id }
    }

    let page: Int
    let segments: [Segment]

    var id: Int { page }

    var firstSurah: Surah? { segments.first?.surah }
    var firstAyah: Ayah? { segments.first?.ayahs.first }
    var juz: Int? { firstAyah?.juz }

    /// The surah a page is labelled with (toolbar title, pinned header, footer meter): always the **top**
    /// surah on the page - the one the page opens with. On a page holding Al-Ikhlas, Al-Falaq and An-Nas,
    /// that is Al-Ikhlas (112), not whichever happens to have the most ayahs.
    var displayedSurah: Surah? { firstSurah }

    /// Every ayah printed on this page, as (surah, ayah) refs. Used to scope the per-ayah beginner overrides
    /// to the page they affect, so a toggle anywhere else in the mushaf can't evict this page's render or
    /// discard its measured fit.
    var ayahRefs: [HighlightedAyahRef] {
        segments.flatMap { segment in
            segment.ayahs.map { HighlightedAyahRef(surahID: segment.surah.id, ayahID: $0.id) }
        }
    }
}

/// The whole mushaf as swipeable pages: each page holds every ayah printed on it - across surah boundaries - 
/// as one continuous block of Arabic, the way a printed mushaf sets them. Shown in place of the ayah list
/// when `settings.quranPageMode` is on. Swiping left/right moves through the mushaf continuously; reaching the
/// end of a surah simply carries you into the next one.
/// Mushaf pagination, kept OUTSIDE the (generic) reader: a generic type cannot hold static stored properties,
/// and the page cache must be shared across every instantiation anyway.
@MainActor
enum MushafPagination {
    /// Paginating all 6,236 ayahs is not free, so do it once per (qiraah, quran-size) and reuse. Keyed by
    /// qiraah because ayahs missing from a qiraah are dropped, which changes what lands on each page.
    /// A few entries rather than one: comparison mode flips between qiraat, and a single slot re-paginated
    /// the whole Quran on every flip. The ayah data inside a page is copy-on-write, so an entry costs
    /// pointers, not text.
    private static var pageCache: [(key: String, pages: [MushafPage])] = []
    private static let pageCacheLimit = 4

    static func pages(quran: [Surah], qiraah: String?) -> [MushafPage] {
        let key = "\(qiraah ?? "Hafs")|\(quran.count)"
        if let index = pageCache.firstIndex(where: { $0.key == key }) {
            // Refresh on use, so eviction sheds the least-recently-READ entry - plain FIFO would evict the
            // default Hafs pagination (always inserted first) the moment a fifth qiraah was compared.
            let hit = pageCache.remove(at: index)
            pageCache.append(hit)
            return hit.pages
        }

        let pages = build(quran: quran, qiraah: qiraah, pageTable: hafsPageTable(quran: quran, qiraah: qiraah))
        if pageCache.count >= pageCacheLimit { pageCache.removeFirst() }
        pageCache.append((key, pages))
        return pages
    }

    /// Whether `pages` would be a cache hit - i.e. whether page mode can open with no pagination pause.
    static func isBuilt(quran: [Surah], qiraah: String?) -> Bool {
        pageCache.contains { $0.key == "\(qiraah ?? "Hafs")|\(quran.count)" }
    }

    /// Paginate off the main actor and seed the cache - so the page-mode TOGGLE can show its brief loading
    /// state instead of freezing the tap while all ~6,236 ayahs are walked. The build reads only value-type
    /// surah data, so it is safe anywhere; only the cache write returns to the main actor.
    static func buildInBackground(quran: [Surah], qiraah: String?) async {
        let key = "\(qiraah ?? "Hafs")|\(quran.count)"
        guard !pageCache.contains(where: { $0.key == key }) else { return }
        // The ayah alignment is MainActor state, so resolve it into a plain table up front;
        // the detached pass then only reads value types.
        let pageTable = hafsPageTable(quran: quran, qiraah: qiraah)
        let pages = await Task.detached(priority: .userInitiated) {
            build(quran: quran, qiraah: qiraah, pageTable: pageTable)
        }.value
        guard !pageCache.contains(where: { $0.key == key }) else { return }
        if pageCache.count >= pageCacheLimit { pageCache.removeFirst() }
        pageCache.append((key, pages))
    }

    /// Non-Hafs riwayat paginate on the SAME Madinah page boundaries as Hafs: page N holds the
    /// riwayah text whose ayahs ALIGN with Hafs page N's ayahs (`QiraahComparison`), so page
    /// numbers, juz starts and "one page is one page" hold across every riwayah - a page just
    /// runs a line or two longer or shorter where the riwayah merges/splits ayahs or spells
    /// differently, and the fitter absorbs that. Keyed riwayah-ayah-id -> Hafs page.
    /// (Direct `ayah.page` was wrong for them: their OWN ayah numbering drifts from the Hafs
    /// rows mid-surah, which is what broke half the pages on other qiraat.)
    private static func hafsPageTable(quran: [Surah], qiraah: String?) -> [Int: [Int: Int]]? {
        guard let qiraah, !qiraah.isEmpty, qiraah != "Hafs" else { return nil }
        let tag = Settings.Riwayah.canonicalTag(qiraah)
        guard !tag.isEmpty else { return nil }
        var out: [Int: [Int: Int]] = [:]
        for surah in quran {
            guard let alignment = QiraahComparison.alignment(surahID: surah.id, tag: tag, quranData: QuranData.shared) else { continue }
            var pageByHafsID: [Int: Int] = [:]
            pageByHafsID.reserveCapacity(surah.ayahs.count)
            for ayah in surah.ayahs where ayah.page != nil {
                pageByHafsID[ayah.id] = ayah.page
            }
            var table: [Int: Int] = [:]
            for (riwayahID, span) in alignment.hafsRangeForRiwayah {
                if let page = pageByHafsID[span.lowerBound] {
                    table[riwayahID] = page
                }
            }
            if !table.isEmpty { out[surah.id] = table }
        }
        return out.isEmpty ? nil : out
    }

    /// The pagination pass itself: pure function of the inputs, no shared state.
    /// Accumulates each segment's ayahs IN PLACE and flushes at page/surah boundaries - the old pass
    /// rebuilt the trailing segment with `ayahs + [ayah]` on every ayah, a full copy of the growing
    /// array each time (O(n²) per page, ~135k array allocations across the book).
    nonisolated private static func build(quran: [Surah], qiraah: String?,
                                          pageTable: [Int: [Int: Int]]? = nil) -> [MushafPage] {
        var pages: [MushafPage] = []
        var currentPage: Int?
        var currentSegments: [MushafPage.Segment] = []
        var currentSurah: Surah?
        var currentAyahs: [Ayah] = []
        // Set once a surah's ayah loop has run out: the segment flushed next is that surah's last.
        var currentEndsSurah = false

        func flushSegment() {
            if let surah = currentSurah, !currentAyahs.isEmpty {
                currentSegments.append(MushafPage.Segment(surah: surah, ayahs: currentAyahs, endsSurah: currentEndsSurah))
            }
            currentAyahs = []
            currentEndsSurah = false
        }
        func flushPage() {
            flushSegment()
            if let page = currentPage, !currentSegments.isEmpty {
                pages.append(MushafPage(page: page, segments: currentSegments))
            }
            currentSegments = []
        }

        // Surahs and their ayahs are already in mushaf order, so a page's segments accumulate in order
        // too: extend the current run while the page and surah repeat, flush at each boundary.
        for surah in quran {
            var lastPageInSurah: Int?
            let surahPageTable = pageTable?[surah.id]
            for ayah in surah.ayahs where ayah.existsInQiraah(qiraah, surahID: surah.id) {
                // Ayahs that exist only in this riwayah's counting (a split past the Hafs range,
                // e.g. al-Ikhlas 5 in the Shami count) carry NO Hafs page - they belong on the page
                // of the ayah before them, not on no page at all. Skipping them was the page-mode
                // "missing last verse" bug.
                guard let page = surahPageTable?[ayah.id] ?? ayah.page ?? lastPageInSurah else { continue }
                lastPageInSurah = page

                if page != currentPage {
                    flushPage()
                    currentPage = page
                    currentSurah = surah
                } else if currentSurah?.id != surah.id {
                    flushSegment()
                    currentSurah = surah
                }
                currentAyahs.append(ayah)
            }
            currentEndsSurah = true
        }
        flushPage()
        return pages
    }

    /// The index of the page holding this surah's ayah - or, when the ayah isn't given or found, the surah's
    /// first page. Where every "open the mushaf at ..." lands, so the reader and the launch prewarm agree.
    static func pageIndex(surahID: Int, ayahID: Int?, in pages: [MushafPage]) -> Int? {
        if let ayahID,
           let index = pages.firstIndex(where: { page in
               page.segments.contains { $0.surah.id == surahID && $0.ayahs.contains { $0.id == ayahID } }
           }) {
            return index
        }
        return pages.firstIndex { $0.segments.contains { $0.surah.id == surahID } }
    }

    /// Memo for `juzRanges`: it sits in the page footer, which re-renders on every page turn, and walking all
    /// ~604 pages each time added a full sweep per swipe. Keyed by the qiraah, the same thing that keys the
    /// pagination itself - two qiraat could coincidentally paginate to the same page count and endpoints while
    /// laying their juz starts on different page ordinals, so a shape fingerprint isn't a safe key.
    /// The same small LRU shape as `pageCache`: a single slot re-swept all ~604 pages on EVERY footer
    /// render while comparison mode flipped between qiraat.
    private static var juzCache: [(key: String, count: Int, ranges: [Int: (start: Int, count: Int)])] = []

    /// For each juz, the ordinal of its first page and how many pages it spans, so a page can show its
    /// position within the current juz. Pages are in mushaf order, so the first occurrence is the start.
    /// Pass the same `qiraah` the pages were built with.
    static func juzRanges(_ pages: [MushafPage], qiraah: String?) -> [Int: (start: Int, count: Int)] {
        let key = "\(qiraah ?? "Hafs")"
        if let index = juzCache.firstIndex(where: { $0.key == key && $0.count == pages.count }) {
            let hit = juzCache.remove(at: index)
            juzCache.append(hit)
            return hit.ranges
        }

        var map: [Int: (start: Int, count: Int)] = [:]
        for (index, page) in pages.enumerated() {
            guard let juz = page.juz else { continue }
            if let existing = map[juz] {
                map[juz] = (existing.start, existing.count + 1)
            } else {
                map[juz] = (index, 1)
            }
        }
        if juzCache.count >= pageCacheLimit { juzCache.removeFirst() }
        juzCache.append((key, pages.count, map))
        return map
    }
}

/// One find match, carrying the page it sits on: widening the find to a whole surah means stepping through
/// matches turns pages, so the destination has to travel with the ayah.
struct MushafFindMatch {
    let pageIndex: Int
    let ref: HighlightedAyahRef
}

/// Single-slot memo for the find fold (file-scope: `SurahPageReader` is generic, and generic types can't hold
/// static stored state). One slot suffices - consecutive evaluations ask for the same (scope, page, query);
/// any change simply recomputes once.
@MainActor
private enum PageFindMemo {
    static var key = ""
    static var matches: [MushafFindMatch] = []
}

struct SurahPageReader<Controls: View>: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    /// The surah the reader was opened from, and the ayah within it (a bookmark, a search hit, last-read).
    /// Together they decide the starting page; after that the reader is no longer bound to this surah.
    let surah: Surah
    var initialAyah: Int?
    /// Bumped by the parent on every in-place surah navigation. The `surah.id` onChange alone can't
    /// re-seed when the picked surah EQUALS the prop (after the reader paged away from it) - the token
    /// change is what forces the jump then.
    var jumpToken: Int = 0
    /// Whether the current `jumpToken` re-seed should TURN the page (animated, like a swipe) instead of
    /// swapping the index. Playback-driven jumps ("go to what's playing") turn; a surah/search jump - which
    /// is a deliberate "take me there now" - stays instant.
    /// Fires ONLY when the visible page's top surah actually changes, so the navigation title can follow the
    /// reader across surah boundaries instead of naming the surah it was opened from forever. Page turns
    /// WITHIN one surah report nothing at all - see `reportSurah`.
    var onSurahChange: ((Surah) -> Void)?
    /// Fires with the first surah + ayah of the page on screen. That's the anchor the list reader opens at
    /// when the user switches back out of page mode.
    var onPageAnchor: ((Int, Int) -> Void)?
    /// The shared attention-highlight, so a marked ayah survives a switch to/from the list reader.
    @Binding var highlightedAyah: HighlightedAyahRef?
    /// Whether the in-page find bar is open (toggled by the search button in the parent's bottom bar).
    @Binding var searchActive: Bool
    /// The search-arrival snippet: the ayah the navigation targeted plus the term that matched it. The
    /// page colors the matched substring in accent until the reader's first touch clears it.
    var arrivalHighlight: (ref: HighlightedAyahRef, term: String)? = nil
    var onClearArrival: (() -> Void)? = nil
    /// Multi-select (parent-owned): while on, taps toggle ayahs instead of marking them. Keyed by
    /// (surah, ayah) and NOT cleared on a page turn, so a selection can be built across several pages -
    /// including across a surah boundary, which a page routinely straddles.
    var isSelecting: Bool = false
    var selectedAyahs: Set<HighlightedAyahRef> = []
    var onToggleSelection: ((Int, Int) -> Void)? = nil
    /// Fires on a real page turn (not the initial seed) - the parent clears its selections and snippet.
    var onPageTurned: (() -> Void)? = nil
    /// Opens the reciter picker (the parent owns the sheet). Page mode had no way to change reciter
    /// without leaving to list mode; the footer play menu offers it through this hook.
    var onChooseReciter: (() -> Void)? = nil
    /// Opens the Choose Surah picker (the parent owns the sheet). A tap anywhere on the footer's
    /// Surah/Juz info pill - outside the page/juz jump buttons - goes here, so the pill that names
    /// the position is also the way to jump to a different surah.
    var onChooseSurah: (() -> Void)? = nil
    /// Opens the custom-range sheet, and starts a random reciter, for the surah the footer is showing. Both
    /// are owned by the parent (the sheet, and the reciter list), and both exist so the page reader's play
    /// menu can be the list reader's play menu exactly, rather than a reduced version of it.
    var onPlayCustomRange: (() -> Void)? = nil
    var onPlayRandomReciter: ((Surah) -> Void)? = nil
    /// The optional tajweed/qiraah controls and the mini player. The reader owns the ordering: these sit
    /// ABOVE the page-navigation footer, which is applied last so it stays pinned at the very bottom.
    @ViewBuilder var bottomControls: () -> Controls

    @Environment(\.layoutDirection) private var layoutDirection

    /// Which jump-to picker is unfolded above the footer, if any.
    enum PickerTarget { case page, juz }

    @State private var pageIndex = 0
    @State private var didSetInitialPage = false
    /// The surah named by the pinned header at the top of the reader, and the ONLY thing that decides when
    /// the header (and the parent's toolbar title) re-renders. It is written by `reportSurah` and only when
    /// the top surah's id actually changes, so paging within one surah leaves it - and the header - alone.
    @State private var headerSurah: Surah?
    /// The header's own surah-info sheet. Reader-level, not page-level: the header no longer lives inside a
    /// page, so a page turn can't tear its sheet down.
    @State private var headerInfoSurah: Surah?
    /// The first (surah, ayah) of the page on screen - the reading position a repagination re-seeds to.
    @State private var currentAnchor: (surahID: Int, ayahID: Int)?
    /// Set when `pageIndex` is about to be moved PROGRAMMATICALLY (initial seed, in-place surah swap),
    /// consumed by the next `.onChange(of: pageIndex)`. The `didSetInitialPage` flag alone can't tell the
    /// seed from a real page turn - `.onAppear` finishes (flag already true) before the seed's `onChange`
    /// is delivered, so the seed used to be treated as a turn and wiped the arrival highlight (the reason
    /// opening "5:6" in page mode showed no selection).
    @State private var suppressNextPageTurnClear = false
    @State private var activePicker: PickerTarget?
    @State private var pagePickerSelection = 0
    @State private var juzPickerSelection = 1
    /// Bottom chrome folded away for a taller page (task: "collapse the bottom and bring it back").
    /// It folds the pinned surah header too - collapsed means the PAGE, nothing else.
    /// Session-scoped on purpose: reopening the reader always starts with its controls visible.
    /// (DEBUG launch arg `-mushafCollapseBars` seeds it for headless screenshot verification.)
    @State private var bottomBarsCollapsed = {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-mushafCollapseBars")
        #else
        false
        #endif
    }()
    /// The typed-number fast path: an alert with a number pad, for jumping without scrolling the wheel.
    /// An alert (not an inline field) because the whole reader ignores the keyboard inset by design - the
    /// page must never resize - so an inline field at the bottom would be covered by the keyboard it raises.
    @State private var showTypedJump = false
    @State private var typedJumpText = ""
    /// The page geometry captured as the jump picker OPENS - before its inset shrinks the live one. The
    /// wheel's predictive warms compose at THIS geometry, because it is what the page returns to the
    /// moment the picker closes and the jump lands; fits at the picker-shrunken height would all near-miss.
    @State private var pickerBaseGeometry: (width: CGFloat, height: CGFloat)?

    // In-page find: the query, and which of the current matches is active.
    @State private var pageSearchText = ""
    @State private var currentMatchIndex = 0
    @FocusState private var pageSearchFocused: Bool
    /// Non-nil when the find has been widened from THIS PAGE to a whole surah - it holds which surah, captured
    /// when the reader asked for it. Captured rather than re-read from the visible page, because widening then
    /// stepping through the matches turns pages, which would otherwise keep moving the target underfoot.
    @State private var findSurahID: Int?

    /// The ayahs matching the find query, in reading order - on the visible page, or across the whole surah
    /// once the reader has widened the find (`findSurahID`). Matching is diacritic-insensitive over Arabic +
    /// transliteration + both English translations, so it finds the ayah whatever the page is showing.
    /// Memoized by (scope, page, folded query, qiraah): the body evaluates this on EVERY re-render while the
    /// find bar is open (including each recitation tick - the reader observes the player), and `syncMatch` /
    /// `goToMatch` ask again per event. The fold runs once per scope+page+query; every repeat is a hit.
    private func matchesOnPage(_ pages: [MushafPage]) -> [MushafFindMatch] {
        let query = settings.cleanSearch(pageSearchText.removingAyahSearchOperators, whitespace: true)
            .removingArabicDiacriticsAndSigns
        guard !query.isEmpty, pages.indices.contains(pageIndex) else { return [] }
        // Vocative-joined twin ("يا نساء" → "يانساء") tried alongside the typed form - the mushaf glues
        // يا onto the word it calls, so the spaced typing alone can never substring-match.
        let joinedQuery: String? = {
            let joined = query.joiningVocativeYaForSearch
            return joined == query ? nil : joined
        }()
        // A typed hamza means it: without this, نساء and نسى fold alike and يانساء found يَنسَىٰ.
        let hamzaFilter = Settings.HamzaPrecisionFilter(query: pageSearchText)

        // The hamza-preserving fold goes in the key too: `query` has the hamza folded AWAY, so ينساء and
        // ينسا produce the same `query` while now yielding different results - one key, two answers.
        // The page index is part of the key ONLY for a page-scoped find. A surah-wide result doesn't depend
        // on which page is showing - and stepping through its matches TURNS pages, so keying on the page
        // there re-folded the entire surah (48 pages for al-Baqarah) on every single step.
        let scopeKey = findSurahID.map { "surah\($0)" } ?? "page\(pageIndex)"
        let memoKey = "\(scopeKey)|\(settings.displayQiraahForArabic ?? "")|\(query)|"
            + (hamzaFilter != nil ? settings.cleanSearchKeepingHamza(pageSearchText, whitespace: true) : "")
        if PageFindMemo.key == memoKey { return PageFindMemo.matches }

        // Widened to a surah: every page that carries any of that surah, in page order. Otherwise just the
        // page on screen - the find bar's default, and what the reader gets before asking for more.
        let scanned: [Int] = {
            guard let findSurahID else { return [pageIndex] }
            return pages.indices.filter { i in
                pages[i].segments.contains { $0.surah.id == findSurahID }
            }
        }()

        var result: [MushafFindMatch] = []
        for index in scanned {
          for segment in pages[index].segments where findSurahID == nil || segment.surah.id == findSurahID {
            for ayah in segment.ayahs {
                // RAW Arabic first: the global index folds the raw text too, so the dagger-alif lanes
                // ("يانسا" via dagger→ا, plus the dagger-dropped "ينسا"/"ابرهيم") match here exactly like
                // they do in the whole-Quran search. The clean text alone had the dagger pre-stripped,
                // which is why pasted Uthmani ("ٱسۡتَوَىٰ") and alif spellings used to miss on-page.
                let rawArabic = ayah.displayArabicText(surahId: segment.surah.id, clean: false, qiraahOverride: settings.displayQiraahForArabic)
                let sources = [
                    rawArabic,
                    rawArabic.removingDaggerAlifForSearch,
                    ayah.displayArabicText(surahId: segment.surah.id, clean: true, qiraahOverride: settings.displayQiraahForArabic),
                    ayah.textTransliteration,
                    ayah.textEnglishSaheeh,
                    ayah.textEnglishMustafa
                ]
                let matched = sources.contains { source in
                    let folded = settings.cleanSearch(source, whitespace: true).removingArabicDiacriticsAndSigns
                    if folded.contains(query) { return true }
                    if let joinedQuery, folded.contains(joinedQuery) { return true }
                    return false
                }
                guard matched else { continue }
                // A hamza the reader actually typed has to be present in the ayah, not folded away.
                if let hamzaFilter, !hamzaFilter.matches(anyOf: [rawArabic]) { continue }
                result.append(MushafFindMatch(
                    pageIndex: index,
                    ref: HighlightedAyahRef(surahID: segment.surah.id, ayahID: ayah.id)
                ))
            }
          }
        }
        PageFindMemo.key = memoKey
        PageFindMemo.matches = result
        return result
    }

    /// Where to land when the reader opens: the page holding `initialAyah` of the surah we came from, else
    /// the page holding the last-read ayah, else that surah's first page.
    private func startingPageIndex(in pages: [MushafPage]) -> Int {
        let targetAyah = initialAyah
            ?? (settings.lastReadSurah == surah.id && settings.lastReadAyah > 0 ? settings.lastReadAyah : nil)

        return MushafPagination.pageIndex(surahID: surah.id, ayahID: targetAyah, in: pages) ?? 0
    }

    var body: some View {
        let pages = MushafPagination.pages(quran: quranData.quran, qiraah: settings.displayQiraahForArabic)

        // The live find state, computed ONCE per evaluation and shared by the find bar and the pages:
        // every matching ayah on the page gets its matched substrings in accent, and the whole page drops
        // its tajweed colors while the query is live (see `MushafPageTextView.searchHighlight`).
        let findMatches: [MushafFindMatch] = searchActive ? matchesOnPage(pages) : []
        let liveSearch: (matches: [HighlightedAyahRef], term: String)? = {
            guard searchActive else { return nil }
            let term = pageSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty else { return nil }
            // Every match, whichever page it is on: a page only ever paints the refs it actually contains,
            // so a surah-wide match set lights each page's own hits and nothing else.
            return (findMatches.map(\.ref), term)
        }()

        Group {
            if pages.isEmpty {
                Text("No ayahs to display")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // A mushaf is bound on the right: page 1 sits at the far RIGHT, and you turn leftward through it.
                // This reverses the DATA rather than flipping `layoutDirection` on the TabView. The RTL environment is
                // not reliably honoured by the UIPageViewController behind `.page` style - on an English (LTR) device
                // it mirrored each page's CONTENT while still starting index 0 on the LEFT, which is exactly backwards.
                // Reversing the emission puts index 0 on the right in a plain LTR pager, and every index-based path
                // (selection, prewarm, jump-to-page) is untouched because `.tag(index)` still carries the real index.
                TabView(selection: $pageIndex) {
                    // `MushafPageContent` is a view struct, not an inline builder, so SwiftUI only evaluates
                    // a page's (expensive) Arabic body when that page is actually on screen - otherwise all
                    // ~600 pages would render up front.
                    // Iterating `indices.reversed()` (a lazy range) instead of `Array(enumerated()).reversed()`
                    // keeps this body from materializing a fresh 604-tuple array on every swipe (and on every
                    // player tick while audio runs) just so the diff can walk it.
                    ForEach(pages.indices.reversed(), id: \.self) { index in
                        Group {
                            // The facsimile swaps only the page BODY. Everything the reader wraps around it -
                            // the pinned surah header, the page/juz pickers and meters in the footer, search,
                            // the play control - is shared, so the printed mushaf behaves like the composed
                            // one everywhere except the ink.
                            if let facsimile = facsimileDocument {
                                MushafPDFPageBody(document: facsimile, mushafPage: pages[index].page)
                            } else {
                                MushafPageContent(
                                    page: pages[index],
                                    highlightedAyah: $highlightedAyah,
                                    arrivalHighlight: arrivalHighlight,
                                    onClearArrival: onClearArrival,
                                    searchHighlight: liveSearch,
                                    isSelecting: isSelecting,
                                    selectedAyahs: selectedAyahs,
                                    onToggleSelection: onToggleSelection,
                                    bottomBarsCollapsed: bottomBarsCollapsed
                                )
                            }
                        }
                            // Each page's own contents keep the app's reading direction; only the *paging* is
                            // flipped below.
                            .environment(\.layoutDirection, layoutDirection)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        // The surah header, PINNED AT THE TOP again (user rule, final position) - but tiny: caption2
        // text (`micro`), clamped dynamic type, and almost no air above or below, so the page loses as
        // little height as possible. One header for the whole pager (it only re-renders when
        // `headerSurah` names a different surah), and it folds with the collapse.
        .safeAreaInset(edge: .top, spacing: 0) {
            topSurahHeader
                .frame(height: bottomBarsCollapsed ? 0 : nil)
                .clipped()
                .opacity(bottomBarsCollapsed ? 0 : 1)
                .allowsHitTesting(!bottomBarsCollapsed)
        }
        // Collapse folds the bars via height+opacity with the views still MOUNTED - an `if` removal
        // snapshots the glass background as a hard black box on the way out (the artifact SurahView's
        // list bars hit), because Liquid Glass can't participate in a removal transition. The page then
        // re-fits to the taller band it gains (debounced, in `MushafPageContent`).
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomControls()
                .frame(height: bottomBarsCollapsed ? 0 : nil)
                .clipped()
                .opacity(bottomBarsCollapsed ? 0 : 1)
                .allowsHitTesting(!bottomBarsCollapsed)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            pageFooter(pages: pages)
                .frame(height: bottomBarsCollapsed ? 0 : nil)
                .clipped()
                .opacity(bottomBarsCollapsed ? 0 : 1)
                .allowsHitTesting(!bottomBarsCollapsed)
        }
        // The collapse/restore strip: ordinary layout, not a floating overlay - applied LAST so it sits
        // BELOW everything else at the screen's bottom edge. It is ALWAYS mounted and always visible (user
        // rule: "put collapse at the bottom rather than at the right, the same as it is when collapsed"),
        // so the control never moves - only its chevron flips direction.
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBarsToggleStrip }
        .safeAreaInset(edge: .top, spacing: 0) {
            if searchActive {
                pageFindBar(pages: pages, matches: findMatches)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // The keyboard OVERLAYS the page - it must never resize it. A mushaf page is typeset to the height it
        // is given (`MushafPageContent` measures `geo.size.height` and fits the whole page's Arabic into it),
        // so the default keyboard avoidance handed it a half-height box and it re-fit the entire page to that:
        // raising the keyboard visibly shrank the text, and dismissing it grew it back. Ignoring the keyboard
        // inset keeps the page at its real height and lets the keyboard cover the bottom of it instead.
        //
        // Safe because the only text field in page mode is in the find bar, which is a TOP inset - it stays
        // above the keyboard on its own. The bottom controls being covered while typing is the intent.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(item: $headerInfoSurah) { surah in
            SurahInfoSheet(surahName: surah.nameTransliteration, surahNumber: surah.id)
                .environmentObject(settings)
                .environmentObject(quranData)
        }
        .onAppear {
            #if DEBUG
            // Headless verification: `-mushafFindBar <query>` opens the in-page find pre-filled, the
            // only way to drive it from `simctl launch` (no tap injection in that harness).
            if let flag = ProcessInfo.processInfo.arguments.firstIndex(of: "-mushafFindBar"),
               ProcessInfo.processInfo.arguments.indices.contains(flag + 1),
               !searchActive {
                searchActive = true
                pageSearchText = ProcessInfo.processInfo.arguments[flag + 1]
            }
            #endif
            // Seed the index once. Re-deriving it on every render (font change, qiraah switch) would yank the
            // reader back to the page it was opened at.
            guard !didSetInitialPage else { return }
            didSetInitialPage = true
            let target = startingPageIndex(in: pages)
            // Only latch when the index actually changes - an unfired onChange would leave the latch
            // armed and silently swallow the first REAL page turn's clear.
            if target != pageIndex { suppressNextPageTurnClear = true }
            pageIndex = target
            reportSurah(on: pageIndex, in: pages)
            reportAnchor(on: pageIndex, in: pages)
            MushafPageRenderCache.prewarm(pages: pages, around: pageIndex, includeCenter: true)
        }
        .onChange(of: surah.id) { _ in
            // The surah was swapped in place (surah picker, next-surah, a search hit). The reader used to be
            // torn down and recreated via `.id(surah.id)` for this - a full rebuild of the 604-page pager on
            // the main thread. Re-seeding the index in the LIVE pager is the cheap equivalent.
            reseedToStartingPage(in: pages)
        }
        // The picked surah can equal the `surah` prop after the reader paged away from it - no id change,
        // no onChange above. The parent bumps the token on EVERY navigation, so this one always fires
        // (re-seeding twice in one update is a harmless no-op: the second sees target == pageIndex).
        .onChange(of: jumpToken) { _ in
            reseedToStartingPage(in: pages)
        }
        .onChange(of: pageIndex) { index in
            // Leaving a page resets its pinch zoom to the fitted view (user rule: same as the PDF) -
            // otherwise the adjacent page stays mounted zoomed-in and greets you magnified on return.
            NotificationCenter.default.post(name: PageZoomScrollView.resetZoomNotification, object: nil)
            reportSurah(on: index, in: pages)
            reportAnchor(on: index, in: pages)
            // `includeCenter` is load-bearing for far jumps (page/juz/surah picker): this onChange runs
            // BEFORE the landing page's body, so without the center the ring's 10 fits were enqueued
            // first on the serial fit queue and the landing page's own fit ran LAST behind all of them -
            // a 5-10 second wait to see the picked page. Center-first makes the landing page the first
            // fit; an ordinary swipe is unaffected (its center is already cached and skips instantly).
            MushafPageRenderCache.prewarm(pages: pages, around: index, includeCenter: true)
            // Turning the page clears every selection: the tap-mark, the multi-select set, and any
            // search-arrival snippet - a new page is a fresh start. Programmatic seeds (initial open,
            // in-place surah swap) are NOT turns - they consume the latch instead of clearing.
            if suppressNextPageTurnClear {
                suppressNextPageTurnClear = false
            } else if didSetInitialPage {
                // Only write when there is something to clear: `highlightedAyah` is the parent's state, so
                // assigning nil over nil re-runs SurahView (and re-installs its toolbar title) on every
                // single swipe.
                if highlightedAyah != nil { highlightedAyah = nil }
                onPageTurned?()
            }
            // Page-scoped matches are per-page, so turning the page re-runs the find against the new one. A
            // surah-wide find already holds every match and turning pages is how you STEP through it -
            // resyncing there would throw the position back to the first match on every step.
            if searchActive, findSurahID == nil { syncMatch(pages: pages, resetIndex: true) }
            guard pages.indices.contains(index),
                  let surah = pages[index].firstSurah,
                  let ayah = pages[index].firstAyah else { return }
            saveLastRead(surahID: surah.id, ayahID: ayah.id)
        }
        .onChange(of: pageSearchText) { _ in syncMatch(pages: pages, resetIndex: true) }
        // Follow the recitation ACROSS page boundaries - the list reader's rule (SurahView scrolls on
        // every ayah advance). Without this the accent follow-along vanished the moment recitation
        // crossed onto the next page, and the reader had to be swiped by hand.
        .onChange(of: quranPlayer.currentAyahNumber) { ayahID in
            guard didSetInitialPage,
                  let ayahID,
                  let surahID = quranPlayer.currentSurahNumber,
                  pages.indices.contains(pageIndex),
                  // Hold the page while any per-ayah sheet is up: a follow page-turn tears down the
                  // page that is PRESENTING the sheet, dismissing it mid-read. Following resumes on
                  // the first ayah advance after the sheet closes. See `AyahSheetPresence`.
                  !AyahSheetPresence.shared.anySheetOpen else { return }
            func contains(_ page: MushafPage) -> Bool {
                page.segments.contains { segment in
                    segment.surah.id == surahID && segment.ayahs.contains { $0.id == ayahID }
                }
            }
            guard !contains(pages[pageIndex]) else { return }
            guard let target = pages.firstIndex(where: contains), target != pageIndex else { return }
            // Only follow a NATURAL progression: the next/previous physical page, or a jump within a
            // surah this page already shows. Listening to some unrelated far-away surah from the mini
            // player must not yank the reader across the book.
            let showsPlayingSurah = pages[pageIndex].segments.contains { $0.surah.id == surahID }
            guard abs(target - pageIndex) == 1 || showsPlayingSurah else { return }
            // Recitation crossing a page boundary TURNS the page, it doesn't cut to it.
            turnPage(to: target, in: pages)
        }
        // Follow WHOLE-SURAH playback across surah boundaries too. Surah files carry no per-ayah
        // position (`currentAyahNumber` stays nil), so when playback rolls into the next surah the
        // handler above never fires - the reader sat on the finished surah's page. Keyed on the surah:
        // when the new surah starts on another page, turn to it, under the same natural-progression
        // guard (the next/previous physical page, or a page already showing it) so listening to some
        // far-away surah from the mini player never yanks the reader across the book.
        .onChange(of: quranPlayer.currentSurahNumber) { surahID in
            guard didSetInitialPage,
                  let surahID,
                  quranPlayer.isPlayingSurah,
                  pages.indices.contains(pageIndex),
                  !AyahSheetPresence.shared.anySheetOpen else { return }
            func containsStart(_ page: MushafPage) -> Bool {
                page.segments.contains { $0.surah.id == surahID && $0.ayahs.contains { $0.id == 1 } }
            }
            guard !pages[pageIndex].segments.contains(where: { $0.surah.id == surahID }),
                  let target = pages.firstIndex(where: containsStart),
                  target != pageIndex else { return }
            guard abs(target - pageIndex) == 1 else { return }
            turnPage(to: target, in: pages)
        }
        // A qiraah switch re-paginates the book. Keyed on the QIRAAH, not `pages.count`: dropping ayahs
        // absent from a qiraah never changes the page COUNT (page numbers are per-ayah metadata), so a
        // count-based onChange usually never fired - leaving the prewarm ring and its stored context on
        // the OLD qiraah's pages, which a later geometry change would then compose and cache under the
        // NEW qiraah's signature (wrong page content served from cache).
        .onChange(of: settings.displayQiraahForArabic) { _ in
            reseedAfterRepagination(pages)
        }
        // Kept as a safety net for any other source of a count change (an index past the new end leaves
        // the TabView with no selected tag - a blank pager).
        .onChange(of: pages.count) { count in
            guard count > 0 else { return }
            reseedAfterRepagination(pages)
        }
        .onChange(of: searchActive) { active in
            if active {
                pageSearchFocused = true
            } else {
                pageSearchText = ""
                pageSearchFocused = false
                // The find always REOPENS scoped to the page you are on - widening to the surah is a
                // deliberate per-search choice, not a mode that quietly persists into the next one.
                findSurahID = nil
            }
        }
        // Folding (or restoring) the bottom bars changes every page's height budget. No handling here:
        // the fold animates the visible page's geometry, and `lastGeometry`'s debounced settle sweep
        // re-warms the ring at the height the pages come to rest at - the same path that covers the
        // mini player mounting and every other bottom-inset change. (A fixed post-toggle delay lived
        // here before, and it raced the fold: transient-height fits started mid-animation overwrote
        // the neighbours' fallback renders, which is exactly the "page shows up uncollapsed for a
        // beat" flash it was meant to fix.)
        // Warm the wheel's CANDIDATE while the user is still scrolling it: by the time they tap the
        // checkmark, the page they settled on is usually already composed and the jump lands instantly.
        // Radius 1 keeps each detent to the candidate and its neighbours, and the generation bump inside
        // `prewarm` retires the previous detent's unstarted fits - spinning the wheel fast stays cheap.
        .onChange(of: pagePickerSelection) { candidate in
            guard activePicker == .page, pages.indices.contains(candidate) else { return }
            MushafPageRenderCache.prewarm(pages: pages, around: candidate, radius: 1, includeCenter: true,
                                          at: pickerBaseGeometry)
        }
        .onChange(of: juzPickerSelection) { candidate in
            guard activePicker == .juz,
                  let start = MushafPagination.juzRanges(pages, qiraah: settings.displayQiraahForArabic)[candidate]?.start,
                  pages.indices.contains(start) else { return }
            MushafPageRenderCache.prewarm(pages: pages, around: start, radius: 1, includeCenter: true,
                                          at: pickerBaseGeometry)
        }
        .onChange(of: activePicker) { picker in
            // Picker closed (jump or cancel): re-point the prewarm context at the page on screen.
            // Wheel-browsing moved it to the last CANDIDATE, and a later geometry change re-warms around
            // the stored context - a ring around a page the user never went to, while the real
            // neighbourhood stayed cold. Everything already composed is a cache hit, so this is ~free.
            guard picker == nil else { return }
            MushafPageRenderCache.prewarm(pages: pages, around: pageIndex, includeCenter: true)
        }
    }

    /// Move the pager to `target` the way a SWIPE does: an animated page turn, not an index teleport.
    ///
    /// The `withAnimation` is the whole mechanism, and it is not decorative. A paged `TabView` slides
    /// between pages only when the selection change carries an animation in its transaction; the identical
    /// assignment made outside one swaps the page within a single frame. (Verified frame-by-frame on an
    /// iOS 26 simulator recording: animated = ~10 intermediate frames at 30fps, bare = zero.)
    ///
    /// Used for every PLAYBACK-driven page change - following the recitation across a boundary, and
    /// starting playback on an ayah that lives on another page - so the reader turns the page and reading
    /// carries on, instead of the page being swapped out from under the reciter.
    private func turnPage(to target: Int, in pages: [MushafPage], suppressClear: Bool = true) {
        guard pages.indices.contains(target), target != pageIndex else { return }
        // Compose the destination BEFORE the turn starts, so what slides in is the page rather than its
        // loading spinner. (`.onChange(of: pageIndex)` prewarms too, but that runs as the turn begins.)
        MushafPageRenderCache.prewarm(pages: pages, around: target, radius: 1, includeCenter: true)
        // A follow/seed is not a user page turn - it must not wipe the mark or the selections. A
        // DELIBERATE jump (the page/juz pickers) passes false: there a new page is a fresh start,
        // exactly as if it had been swiped to.
        if suppressClear { suppressNextPageTurnClear = true }
        // Deferred one runloop tick, deliberately: this is called from `.onChange` handlers running
        // INSIDE the player publish's own update pass, and a selection write made there reached the
        // UIPageViewController without the animated transaction - the page SNAPPED instead of sliding
        // (verified frame-by-frame: one giant scene step, zero intermediates). Hopping to the next
        // tick puts the write in a fresh transaction whose animation the pager honors.
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) { pageIndex = target }
        }
    }

    /// Jump the live pager to this `surah`'s starting page (shared by the `surah.id` and `jumpToken`
    /// onChange handlers - an in-place surah swap from the picker, next-surah, a search hit, or "go to
    /// what's playing"). EVERY jump turns the page like a real swipe now, in whichever direction the
    /// target lies (user rule: "as if I was actually swiping, whether it goes back or forward") - the
    /// old instant landing for deliberate navigation is gone. `turnPage` keeps the arrival highlight a
    /// search hit or picker set (its suppressed page-turn clear).
    private func reseedToStartingPage(in pages: [MushafPage]) {
        let target = startingPageIndex(in: pages)
        if target != pageIndex {
            turnPage(to: target, in: pages)
            // `.onChange(of: pageIndex)` reports + prewarms + saves.
        } else {
            reportSurah(on: target, in: pages)
            reportAnchor(on: target, in: pages)
        }
    }

    /// After a repagination (qiraah switch): keep the READING POSITION - re-resolve the page holding the
    /// current anchor ayah in the NEW pages - clamp if it can't be resolved, and re-prewarm so the ring
    /// (and its stored context) is composed from the new pages under the new settings signature.
    private func reseedAfterRepagination(_ pages: [MushafPage]) {
        guard !pages.isEmpty else { return }
        if let anchor = currentAnchor,
           let target = MushafPagination.pageIndex(surahID: anchor.surahID, ayahID: anchor.ayahID, in: pages),
           pages.indices.contains(target), target != pageIndex {
            // A re-seed is not a user page turn - don't wipe the mark/selections. The pageIndex change
            // reports + prewarms via its own onChange.
            suppressNextPageTurnClear = true
            pageIndex = target
        } else {
            if pageIndex >= pages.count { pageIndex = pages.count - 1 }
            // Index unchanged (the common case - page boundaries rarely shift): still refresh the ring
            // and its context against the NEW pages. Center included: the new settings signature made the
            // VISIBLE page cold too, and without the center its refit would queue behind the whole ring.
            MushafPageRenderCache.prewarm(pages: pages, around: pageIndex, includeCenter: true)
        }
    }

    /// Recompute the current page's matches and light up the active one (via the shared highlight).
    private func syncMatch(pages: [MushafPage], resetIndex: Bool) {
        let matches = matchesOnPage(pages)
        if resetIndex { currentMatchIndex = 0 }
        guard !matches.isEmpty else {
            // A LIVE query with zero matches clears the selection outright - keeping the previous
            // keystroke's ayah lit read as "this still matches" when nothing does. An EMPTY query
            // (bar just opened, text cleared, bar closing) leaves the selection alone, so closing
            // the find bar still keeps whatever the search had landed on.
            if !pageSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, highlightedAyah != nil {
                withAnimation(.easeInOut(duration: 0.15)) { highlightedAyah = nil }
            }
            return
        }
        currentMatchIndex = min(currentMatchIndex, matches.count - 1)
        let match = matches[currentMatchIndex]
        highlightedAyah = match.ref
        // A surah-wide find can land its first match on a page other than the one on screen - take the
        // reader there, the way tapping through the matches does.
        if findSurahID != nil, match.pageIndex != pageIndex, pages.indices.contains(match.pageIndex) {
            suppressNextPageTurnClear = true
            withAnimation(.easeInOut(duration: 0.35)) { pageIndex = match.pageIndex }
        }
    }

    /// Step to the previous/next match, wrapping around, and light it up. In a surah-wide find the match may
    /// be on another page, so this turns to it - and suppresses the page-turn clear, which would otherwise
    /// wipe the very selection the step just made.
    private func goToMatch(_ delta: Int, pages: [MushafPage]) {
        let matches = matchesOnPage(pages)
        guard !matches.isEmpty else { return }
        settings.hapticFeedback()
        currentMatchIndex = (currentMatchIndex + delta + matches.count) % matches.count
        let match = matches[currentMatchIndex]
        withAnimation(.easeInOut(duration: 0.15)) {
            highlightedAyah = match.ref
        }
        if match.pageIndex != pageIndex, pages.indices.contains(match.pageIndex) {
            suppressNextPageTurnClear = true
            withAnimation(.easeInOut(duration: 0.35)) { pageIndex = match.pageIndex }
        }
    }

    /// The typed query understood as a REFERENCE rather than text - the list search's `getSurahAndAyah`
    /// lanes, brought to page mode: "2:255", "Baqarah:255", "Baqarah 255", Arabic numerals, and every
    /// English surah spelling `resolveSurahIdentifier` knows. A bare surah name resolves to the surah
    /// alone (ayah nil = its first page); a bare NUMBER offers the ayah in the surah on screen first
    /// ("255" while reading al-Baqarah) and the surah with that number second - both rows when both
    /// parse, so "2" can mean 2:2 here or Surah al-Baqarah without the reader losing either. Additive:
    /// the text matches below keep working - this only decides which "Go to" rows are offered above them.
    private func referenceJumpTargets(scope: Surah?) -> [(surah: Surah, ayahID: Int?)] {
        let raw = pageSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return [] }

        // Western AND Arabic-Indic/Eastern digits - `applyingTransform(.toLatin)` does not touch
        // digits, so the mapping is explicit (the same lane the list's `arabicToEnglishNumber` covers).
        func number(_ token: String) -> Int? {
            if let n = Int(token) { return n }
            let digitMap: [Character: Character] = [
                "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
                "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
                "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
                "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9"
            ]
            guard token.contains(where: { digitMap[$0] != nil }) else { return nil }
            return Int(String(token.map { digitMap[$0] ?? $0 }))
        }

        // "S:A" - surah by name or number before the colon, ayah number after it.
        let colonParts = raw.split(separator: ":").map { String($0).trimmingCharacters(in: .whitespaces) }
        if colonParts.count == 2 {
            guard let surah = quranData.resolveSurahIdentifier(colonParts[0]),
                  let ayah = number(colonParts[1]),
                  quranData.ayah(surah: surah.id, ayah: ayah) != nil else { return [] }
            return [(surah, ayah)]
        }
        guard colonParts.count == 1 else { return [] }

        // A bare number: this surah's ayah first, the surah with that number second.
        if let n = number(raw) {
            var targets: [(surah: Surah, ayahID: Int?)] = []
            if let scope, quranData.ayah(surah: scope.id, ayah: n) != nil {
                targets.append((scope, n))
            }
            if (1...114).contains(n), let surah = quranData.surah(n) {
                targets.append((surah, nil))
            }
            return targets
        }

        // "Baqarah 255" - the colon form with a space, since that's how it gets typed half the time.
        let words = raw.split(separator: " ").map(String.init)
        if words.count >= 2, let ayah = number(words[words.count - 1]),
           let surah = quranData.resolveSurahIdentifier(words.dropLast().joined(separator: " ")),
           quranData.ayah(surah: surah.id, ayah: ayah) != nil {
            return [(surah, ayah)]
        }

        // A bare surah name: offer the surah itself. Requiring a resolvable name keeps ordinary
        // word searches from sprouting a bogus jump row.
        if let surah = quranData.resolveSurahIdentifier(raw) { return [(surah, nil)] }
        return []
    }

    /// Take the reader to a typed reference: the same move a search hit makes - turn to the page,
    /// light the ayah (kept after the bar closes, exactly like a find selection), close the find.
    private func jumpToReference(_ target: (surah: Surah, ayahID: Int?), pages: [MushafPage]) {
        guard let index = MushafPagination.pageIndex(surahID: target.surah.id, ayahID: target.ayahID, in: pages) else { return }
        settings.hapticFeedback()
        withAnimation(.easeInOut) {
            if let ayahID = target.ayahID {
                highlightedAyah = HighlightedAyahRef(surahID: target.surah.id, ayahID: ayahID)
            }
            if index != pageIndex {
                suppressNextPageTurnClear = true
                pageIndex = index
            }
            searchActive = false
        }
    }

    /// The in-page find bar: a text field, a match counter with up/down, a close button, and - always - the
    /// two ways OUT of this page: widen the find to the whole surah (in place, stepping through it turns
    /// pages), or hand the query to the whole-Quran search. Both are offered whether or not this page has a
    /// match, which is the point: a page with nothing on it should never be a dead end.
    /// `matches` comes from the body's shared fold, so it runs once per keystroke.
    private func pageFindBar(pages: [MushafPage], matches: [MushafFindMatch]) -> some View {
        let hasQuery = !pageSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // The surah to widen INTO: the one the page on screen is showing.
        let scopeSurah = pages.indices.contains(pageIndex) ? pages[pageIndex].displayedSurah : nil
        let refTargets = hasQuery ? referenceJumpTargets(scope: scopeSurah) : []
        let searchingSurah = findSurahID != nil

        return VStack(spacing: 5) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(searchingSurah ? "Search this surah" : "Search this page", text: $pageSearchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .focused($pageSearchFocused)
                    .submitLabel(.search)

                if hasQuery {
                    Text(matches.isEmpty ? "0/0" : "\(currentMatchIndex + 1)/\(matches.count)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(matches.isEmpty ? .secondary : .primary)

                    Button { goToMatch(-1, pages: pages) } label: {
                        Image(systemName: "chevron.up").font(.body.weight(.semibold))
                    }
                    .disabled(matches.isEmpty)

                    Button { goToMatch(1, pages: pages) } label: {
                        Image(systemName: "chevron.down").font(.body.weight(.semibold))
                    }
                    .disabled(matches.isEmpty)
                }

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { searchActive = false }
                } label: {
                    Image(systemName: "xmark").font(.body.weight(.semibold))
                }
                .accessibilityLabel("Close search")
            }
            .foregroundStyle(settings.accentColor.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .conditionalGlassEffect(rectangle: true)

            // The typed-reference row: "2:255" / "Baqarah 255" / a bare surah name offers a direct jump,
            // the way the list search's SURAH / AYAH result sections answer the same queries. Above the
            // scope row because when it appears it is almost always what was meant.
            ForEach(Array(refTargets.enumerated()), id: \.offset) { _, target in
                Button {
                    jumpToReference(target, pages: pages)
                } label: {
                    scopeButtonLabel(
                        target.ayahID.map { "Go to \(target.surah.nameTransliteration) \(target.surah.id):\($0)" }
                            ?? "Go to Surah \(target.surah.nameTransliteration)",
                        systemImage: "arrow.turn.down.right",
                        color: settings.accentColor.color
                    )
                }
                .buttonStyle(.plain)
            }

            // The scope row. The first button is a TOGGLE that always names where it will take you - "Search
            // this Surah" while the find is on this page, "Search this Page" once it has been widened - so
            // the label is the action, never a status line you can't act on. The whole-Quran button beside
            // it still hands the query off to the global search.
            HStack(spacing: 6) {
                if scopeSurah != nil {
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) {
                            findSurahID = searchingSurah ? nil : scopeSurah?.id
                        }
                        syncMatch(pages: pages, resetIndex: true)
                    } label: {
                        scopeButtonLabel(
                            searchingSurah ? "Search this Page" : "Search this Surah",
                            systemImage: searchingSurah ? "doc.text.magnifyingglass" : "book.closed",
                            color: settings.accentColor.accent1
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    settings.hapticFeedback()
                    let query = pageSearchText
                    withAnimation(.easeInOut) { searchActive = false }
                    QuranSearchHandoff.shared.request(query)
                } label: {
                    scopeButtonLabel("Search the whole Quran",
                                     systemImage: "text.magnifyingglass",
                                     color: settings.accentColor.color)
                }
                .buttonStyle(.plain)
            }

            // The dead-end note, once the reader has actually come up empty on whatever they scoped to.
            // Not when a reference jump is on offer - "Go to 2:255" plus "no matches" reads as a shrug.
            if hasQuery, matches.isEmpty, refTargets.isEmpty {
                Text(searchingSurah ? "No matches in this surah." : "No matches on this page.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, settings.defaultView ? 20 : 16)
        // SYMMETRIC air (user rule, after a round each way: 2pt read as glued to the title, 10pt
        // as "too much at the top" with none below): the same cushion above the pill and below the
        // block, so the find bar floats evenly between the title and the surah strip.
        .padding(.top, 5)
        .padding(.bottom, 5)
    }

    /// The two scope buttons share a label so they read as one pair rather than two differently-sized pills.
    private func scopeButtonLabel(_ title: String, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .conditionalGlassEffect(rectangle: true)
    }

    /// The single gate on "which surah am I in". Every page turn calls this, but only a turn that lands on a
    /// page whose TOP surah is a different surah gets past the id check - so an intra-surah turn writes
    /// nothing, re-renders nothing, and notifies nobody. Doing the comparison HERE (rather than in the
    /// parent's callback) is the point: the parent's guard could only ever fire after the reader had already
    /// pushed a value at it on every single swipe.
    private func reportSurah(on index: Int, in pages: [MushafPage]) {
        guard pages.indices.contains(index), let surah = pages[index].displayedSurah else { return }
        guard headerSurah?.id != surah.id else { return }
        headerSurah = surah
        onSurahChange?(surah)
    }

    /// The reader's pinned surah header, in its smallest form: revelation symbol, ayah/page summary at
    /// caption2, favourite star - hugging the navigation bar with a hair of padding. Tap for the surah
    /// info sheet; the star keeps its own tap.
    @ViewBuilder
    private var topSurahHeader: some View {
        if let surah = headerSurah {
            SurahSectionHeader(surah: surah, compact: true, micro: true)
                .padding(.horizontal, 10)
                .padding(.vertical, 1)
                // Keep the tapped header lit while its info sheet is open; the accent tint marks the
                // surah loaded in the player.
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(headerInfoSurah?.id == surah.id
                              ? Color.secondary.opacity(0.18)
                              : quranPlayer.currentSurahNumber == surah.id
                                ? settings.accentColor.color.opacity(0.18)
                                : .clear)
                )
                .conditionalGlassEffect(rectangle: true)
                // SYMMETRIC air, and always positive: the collapse wrapper clips this inset, and
                // pre-iOS-26 the safe area starts flush at the navigation bar's bottom edge - so a
                // negative pull (or the emoji's ink overshooting its line box) was SHEARED there
                // ("top is cut off"), and 1pt read as the strip being glued to the bar. 3pt above =
                // 3pt below (user rule: "spacing between the top and bottom even"); the strip stays
                // small through its micro fonts, not by starving its margins.
                .padding(.top, 3)
                .padding(.bottom, 3)
                .padding(.horizontal, settings.defaultView ? 20 : 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    headerInfoSurah = surah
                }
                .animation(.easeInOut(duration: 0.15), value: headerInfoSurah?.id == surah.id)
                .dynamicTypeSize(.small)
        }
    }

    /// The collapse/restore strip: a full-width chevron row at the very bottom of the screen, below
    /// everything - ordinary layout, nothing floating over the page. One control for both directions, so
    /// collapsing and restoring happen in the same place (the chevron just turns over).
    private var bottomBarsToggleStrip: some View {
        // Collapsed, the tap target grows UPWARD toward the Arabic - without moving the chevron or any
        // spacing: the extra height is added INSIDE the label and cancelled by the outer negative
        // padding, so the button's frame (and its full-width contentShape) reaches ~18pt into the
        // page's bottom air while everything draws exactly where it did (user rule: keep the chevron
        // small, make the clickable height bigger). Expanded keeps the plain target - reaching up
        // there would steal taps from the footer pill's lower edge.
        let hitExtension: CGFloat = bottomBarsCollapsed ? 18 : 0

        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.25)) { bottomBarsCollapsed.toggle() }
        } label: {
            Image(systemName: bottomBarsCollapsed ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundColor(settings.accentColor.color)
                // Asymmetric on purpose: the tap target keeps its height, but almost all of it hangs BELOW
                // the glyph, so the chevron sits tight under the bar above it instead of floating in a band
                // of its own (user: "the chevron has too much spacing above it").
                .padding(.top, 1 + hitExtension)
                // Collapsed, the strip is the screen's last band - a tighter cushion gives the page the
                // difference (user: "still some more space at the bottom" when collapsed).
                .padding(.bottom, bottomBarsCollapsed ? 3 : 7)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Pulls the strip up into the padding the footer above it already leaves - but only while the footer
        // is there. Collapsed, the base -2 keeps the drawn strip where it was and the extra `hitExtension`
        // cancels the invisible tap-target growth above.
        .padding(.top, (bottomBarsCollapsed ? -2 : -8) - hitExtension)
        .accessibilityLabel(bottomBarsCollapsed ? "Show the reader controls and surah header"
                                                : "Hide the reader controls and surah header")
    }

    private func reportAnchor(on index: Int, in pages: [MushafPage]) {
        guard pages.indices.contains(index),
              let surah = pages[index].firstSurah,
              let ayah = pages[index].firstAyah else { return }
        currentAnchor = (surah.id, ayah.id)
        onPageAnchor?(surah.id, ayah.id)
    }

    private func saveLastRead(surahID: Int, ayahID: Int) {
        // Debounced: the AppStorage write + widget snapshot + reloadAllTimelines ran inline on every page
        // turn, which was the single biggest per-swipe cost in page mode. Only where the flipping STOPS
        // matters, so page turns just note the position and the write settles ~0.8s after the last one.
        settings.noteLastRead(surah: surahID, ayah: ayahID)
    }

    // MARK: - Bottom page-navigation footer (pinned below the tajweed/qiraah controls and the mini player)

    /// The bundled printed mushaf to draw instead of composing the page, or nil to compose as usual.
    ///
    /// nil unless the reader asked for the facsimile AND this riwayah has one bundled - so a riwayah without
    /// a PDF silently keeps the composed text rather than showing blank pages.
    private var facsimileDocument: PDFDocument? {
        guard settings.resolvedMushafPageLanguage.isPDF else { return nil }
        return MushafPDFLibrary.document(for: settings.displayQiraahForArabic ?? Settings.Riwayah.hafsTag)
    }

    @ViewBuilder
    private func pageFooter(pages: [MushafPage]) -> some View {
        if pages.indices.contains(pageIndex) {
            let page = pages[pageIndex]
            let ranges = MushafPagination.juzRanges(pages, qiraah: settings.displayQiraahForArabic)
            let jr = page.juz.flatMap { ranges[$0] }
            let juzPosition = jr.map { pageIndex - $0.start + 1 } ?? 0
            let juzTotal = jr?.count ?? 0

            let footerSurah = page.displayedSurah
            let surahTotal = max(footerSurah?.pageCount ?? 1, 1)
            let surahPosition = min(
                max((page.page - (footerSurah?.pageStart ?? page.page)) + 1, 1),
                surahTotal
            )

            VStack(spacing: 8) {
                if let target = activePicker {
                    inlinePicker(target: target, pages: pages)
                }

                // The collapse control moved OUT of this row to the strip at the screen's bottom edge,
                // so the pill and the play control sit at their plain 8pt apart again.
                HStack(spacing: 8) {
                    pageInfoPill(page: page, surah: footerSurah, pages: pages,
                                 surahPosition: surahPosition, surahTotal: surahTotal,
                                 juzPosition: juzPosition, juzTotal: juzTotal)

                    if let footerSurah {
                        pageFooterPlayButton(surah: footerSurah)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
        }
    }

    /// The footer row's height. The info panel and the play control both take it, so the two read as one bar
    /// rather than a tall block next to a small button. (A computed property, not a `static let`: a generic type
    /// can't hold static stored properties.)
    private var footerHeight: CGFloat { 62 }

    /// Only what the toolbar title doesn't already say. The surah's name is up top, so this is purely position:
    /// how big the surah is, how far into it and into the juz this page sits, and the two jump-to pickers.
    private func pageInfoPill(page: MushafPage, surah footerSurah: Surah?, pages: [MushafPage],
                              surahPosition: Int, surahTotal: Int,
                              juzPosition: Int, juzTotal: Int) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    // Plain "Surah", deliberately (user rule: names run too long here) - the row
                    // above names it.
                    meter(label: "Surah", position: surahPosition, total: surahTotal,
                          color: settings.accentColor.accent1)

                    if juzTotal > 0 {
                        meter(label: "Juz", position: juzPosition, total: juzTotal,
                              color: settings.accentColor.accent2)
                    }
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 4) {
                    jumpButton(
                        title: "Page \(page.page) / \(pages.count)  \(percent(page.page, of: pages.count))",
                        target: .page,
                        color: settings.accentColor.accent1,
                        seed: {
                            pagePickerSelection = pageIndex
                            pickerBaseGeometry = MushafPageRenderCache.currentGeometry
                        }
                    )

                    jumpButton(
                        title: "Juz \(page.juz ?? 1) / 30  \(percent(page.juz ?? 1, of: 30))",
                        target: .juz,
                        color: settings.accentColor.accent2,
                        seed: {
                            juzPickerSelection = page.juz ?? 1
                            pickerBaseGeometry = MushafPageRenderCache.currentGeometry
                        }
                    )
                }
            }

            // Progress through the whole mushaf. A track behind the fill is what makes it legible - the old
            // hairline had nothing to read against, so it just looked like a stray line.
            trackedBar(
                fraction: pages.count > 0 ? CGFloat(page.page) / CGFloat(pages.count) : 0,
                height: 5,
                color: settings.accentColor.accent2
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: footerHeight)
        .frame(maxWidth: .infinity)
        .conditionalGlassEffect(rectangle: true)
        // The pill itself opens Choose Surah: tapping the Surah/Juz readout is the natural "take me
        // to another surah" gesture. The jump BUTTONS are real Buttons, so they keep winning their
        // own taps; only the rest of the pill falls through to this.
        .contentShape(Rectangle())
        .onTapGesture {
            guard let onChooseSurah else { return }
            settings.hapticFeedback()
            onChooseSurah()
        }
        .accessibilityAction(named: "Choose Surah") { onChooseSurah?() }
    }

    /// "43%" - how far through the mushaf (or through the 30 juz) this page sits.
    private func percent(_ position: Int, of total: Int) -> String {
        guard total > 0 else { return "" }
        return "\(Int((Double(position) / Double(total) * 100).rounded()))%"
    }

    /// "Surah 12/48" with its own little bar - the two positions the reader actually cares about.
    ///
    /// Mirrored for the mushaf: the bar sits to the LEFT of its label and fills right-to-left, so the fill
    /// starts at the edge nearest the label and grows away from it - the exact mirror of the list-mode
    /// meter, and the same direction the page text and the page turns run in.
    private func meter(label: String, position: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            trackedBar(
                fraction: total > 0 ? CGFloat(position) / CGFloat(total) : 0,
                height: 3,
                color: color
            )
            .frame(width: 44)

            Text("\(label) \(position)/\(total)")
                .font(.system(size: 10, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    /// A fill over a visible track, so a low value still reads as "a little way in" rather than as nothing.
    /// Always right-to-left here: a mushaf is read - and paged - from right to left, so a fill that grew
    /// leftward-to-rightward was progress running backwards against everything else on the screen.
    private func trackedBar(fraction: CGFloat, height: CGFloat, color: Color) -> some View {
        TrackedBar(fraction: fraction, height: height, color: color, rightToLeft: true)
    }

    /// The page / juz readouts double as the buttons that open their picker. `seed` sets the wheel to where you
    /// currently are, so opening it and confirming without touching it is a no-op.
    private func jumpButton(title: String, target: PickerTarget, color: Color, seed: @escaping () -> Void) -> some View {
        let isOpen = activePicker == target

        return Button {
            settings.hapticFeedback()
            if !isOpen { seed() }
            withAnimation(.easeInOut) {
                activePicker = isOpen ? nil : target
            }
        } label: {
            HStack(spacing: 3) {
                Text(title)
                Image(systemName: isOpen ? "chevron.down" : "chevron.up.chevron.down")
                    .font(.system(size: 6))
            }
            .font(.system(size: 10, weight: .semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color.opacity(isOpen ? 0.22 : 0.12))
            )
            .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .accessibilityLabel("\(title). Jump to")
    }

    /// The page and juz pickers, in place rather than as a sheet - jumping somewhere shouldn't cost a modal.
    /// Both use the same chrome; only what's being picked differs.
    private func inlinePicker(target: PickerTarget, pages: [MushafPage]) -> some View {
        let ranges = MushafPagination.juzRanges(pages, qiraah: settings.displayQiraahForArabic)
        let juzList = ranges.keys.sorted()

        return VStack(spacing: 0) {
            HStack {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { activePicker = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(target == .page ? "Go to Page" : "Go to Juz")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if #available(iOS 16.0, *) {
                    Button {
                        settings.hapticFeedback()
                        typedJumpText = ""
                        showTypedJump = true
                    } label: {
                        Image(systemName: "keyboard")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(settings.accentColor.accent2)
                    }
                    .padding(.trailing, 14)
                    .accessibilityLabel(target == .page ? "Type a page number" : "Type a juz number")
                }

                Button {
                    settings.hapticFeedback()
                    switch target {
                    case .page:
                        // Clamped: the selection was seeded against the pagination it was OPENED with, and a
                        // qiraah switch mid-pick can shrink it - an out-of-range TabView selection blanks the
                        // pager. Turned, not teleported (user rule: every jump slides like a swipe); the
                        // picker jump is a fresh start, so the page-turn clear runs as usual.
                        turnPage(to: min(max(pagePickerSelection, 0), max(pages.count - 1, 0)), in: pages,
                                 suppressClear: false)
                    case .juz:
                        // A juz is picked by number, but the reader navigates by page - turn to the page the
                        // juz opens on.
                        if let start = ranges[juzPickerSelection]?.start {
                            turnPage(to: start, in: pages, suppressClear: false)
                        }
                    }
                    withAnimation(.easeInOut) { activePicker = nil }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(settings.accentColor.accent2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            Group {
                switch target {
                case .page:
                    Picker("Page", selection: $pagePickerSelection) {
                        // A plain range, not `Array(...)`: materializing a 604-element array on every
                        // picker render was pure allocation waste.
                        ForEach(0..<max(pages.count, 1), id: \.self) { i in
                            Text("Page \(pages.indices.contains(i) ? pages[i].page : i + 1)").tag(i)
                        }
                    }
                case .juz:
                    Picker("Juz", selection: $juzPickerSelection) {
                        ForEach(juzList, id: \.self) { juz in
                            Text("Juz \(juz)").tag(juz)
                        }
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            .frame(height: 110)
            .clipped()
        }
        .frame(maxWidth: .infinity)
        .conditionalGlassEffect(rectangle: true)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        // The typed-number fast path. An alert so the number pad can't cover the input (the reader
        // deliberately ignores the keyboard inset - see the note on `showTypedJump`). The TextField only
        // renders inside alerts on iOS 16+, which is why the keyboard button that raises this is gated.
        .alert(target == .page ? "Go to Page" : "Go to Juz", isPresented: $showTypedJump) {
            TextField(target == .page ? "1 – \(pages.last?.page ?? pages.count)" : "1 – 30", text: $typedJumpText)
                .keyboardType(.numberPad)
            Button("Go") { commitTypedJump(target: target, pages: pages) }
            Button("Cancel", role: .cancel) {}
        }
    }

    /// Jump from a typed number. Page numbers are what the footer displays (`pages[i].page`), not indices;
    /// out-of-range input clamps to the nearest end rather than being dropped.
    private func commitTypedJump(target: PickerTarget, pages: [MushafPage]) {
        guard let n = Int(typedJumpText.trimmingCharacters(in: .whitespaces)), !pages.isEmpty else { return }
        switch target {
        case .page:
            pageIndex = pages.firstIndex { $0.page == n } ?? min(max(n - 1, 0), pages.count - 1)
        case .juz:
            let ranges = MushafPagination.juzRanges(pages, qiraah: settings.displayQiraahForArabic)
            let clamped = min(max(n, 1), 30)
            if let start = ranges[clamped]?.start {
                pageIndex = start
            } else if let nearest = ranges.keys.sorted().min(by: { abs($0 - clamped) < abs($1 - clamped) }),
                      let start = ranges[nearest]?.start {
                pageIndex = start
            }
        }
        withAnimation(.easeInOut) { activePicker = nil }
    }

    /// The list reader's play menu, verbatim (user rule: "take the SurahView play menu exactly and put it in
    /// the mushaf one") - reciter picker on top, then Other Options (custom range, random ayah, random
    /// reciter, repeat), ayah-by-ayah, last listened, and Play Surah nearest the thumb. It acts on the surah
    /// the FOOTER is showing, which in page mode is wherever the reader has paged to.
    private func pageFooterPlayButton(surah: Surah) -> some View {
        let idle = !quranPlayer.isLoading && !quranPlayer.isPlaying && !quranPlayer.isPaused
        let canResumeLast = settings.lastListenedSurah?.surahNumber == surah.id
        let repeatCounts = [20, 15, 10, 5, 3, 2]

        return Group {
            if idle {
                Menu {
                    // Reciter picker pinned to the very top, with a divider under it - the same placement
                    // as the list reader's play menu, so all the play menus read identically.
                    if let onChooseReciter {
                        Button {
                            settings.hapticFeedback()
                            onChooseReciter()
                        } label: {
                            Label("Choose Reciter", systemImage: "headphones")
                        }

                        Divider()
                    }

                    Text("Surah Playback")
                        .foregroundStyle(.secondary)

                    // Play Surah sits at the visual BOTTOM of every play menu (user-picked order) - the
                    // primary action lands nearest the thumb, with Play Last Listened just above it.
                    // Declared order is visual order (`fixedMenuOrder`).
                    Menu {
                        Text("More Playback")
                            .foregroundStyle(.secondary)

                        if let onPlayCustomRange {
                            Button {
                                settings.hapticFeedback()
                                onPlayCustomRange()
                            } label: {
                                Label("Play Custom Range", systemImage: "slider.horizontal.3")
                            }
                        }

                        Button {
                            settings.hapticFeedback()
                            let ayahsForQiraah = surah.ayahs.filter {
                                $0.existsInQiraah(settings.displayQiraahForArabic, surahID: surah.id)
                            }
                            if let randomAyah = ayahsForQiraah.randomElement() {
                                quranPlayer.playAyah(
                                    surahNumber: surah.id,
                                    ayahNumber: randomAyah.id,
                                    continueRecitation: true
                                )
                            }
                        } label: {
                            Label("Play Random Ayah", systemImage: "shuffle.circle")
                        }

                        if let onPlayRandomReciter {
                            Button {
                                settings.hapticFeedback()
                                onPlayRandomReciter(surah)
                            } label: {
                                Label("Play Random Reciter", systemImage: "person.wave.2")
                            }
                        }

                        Menu {
                            Text("Repeat Count")
                                .foregroundStyle(.secondary)

                            ForEach(repeatCounts, id: \.self) { n in
                                Button {
                                    settings.hapticFeedback()
                                    quranPlayer.playSurah(
                                        surahNumber: surah.id,
                                        surahName: surah.nameTransliteration,
                                        repeatCount: n
                                    )
                                } label: {
                                    Label("Repeat \(n)×", systemImage: "\(n).circle")
                                }
                            }
                        } label: {
                            Label("Repeat Surah", systemImage: "repeat")
                        }
                    } label: {
                        Label("Other Options", systemImage: "ellipsis.circle")
                    }

                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: 1, continueRecitation: true)
                    } label: {
                        Label("Play Ayah by Ayah", systemImage: "list.number")
                    }

                    if canResumeLast, let last = settings.lastListenedSurah {
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playSurah(
                                surahNumber: last.surahNumber,
                                surahName: last.surahName,
                                certainReciter: true
                            )
                        } label: {
                            Label("Play Last Listened", systemImage: "play.fill")
                        }
                    }

                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                    } label: {
                        Label(canResumeLast ? "Play from Beginning" : "Play Surah", systemImage: "memories")
                    }
                } label: {
                    playControlLabel
                }
                // Without this, a menu popping UPWARD from this bottom-anchored footer renders reversed,
                // dumping Choose Reciter (declared first, wanted on top) to the bottom.
                .fixedMenuOrder()
            } else {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.stop()
                } label: {
                    playControlLabel
                }
            }
        }
        .animation(.easeInOut, value: quranPlayer.isPlaying)
        // Animate the swap into the loading spinner too (isLoading flips before isPlaying on play).
        .animation(.easeInOut, value: quranPlayer.isLoading)
    }

    private var playControlLabel: some View {
        Group {
            if quranPlayer.isLoading {
                RotatingGearView()
                    .transition(.opacity)
            } else {
                Image(systemName: quranPlayer.isPlaying || quranPlayer.isPaused ? "xmark.circle.fill" : "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(settings.accentColor.accent2)
                    .transition(.opacity)
            }
        }
        .frame(width: 22, height: 22)
        // Square, and exactly as tall as the info panel it sits beside.
        .frame(width: footerHeight, height: footerHeight)
        .contentShape(Rectangle())
        .conditionalGlassEffect(rectangle: true)
    }
}

/// One page of the mushaf. Its body is only built when the page scrolls into view.
private struct MushafPageContent: View {
    @ObservedObject private var settings = Settings.shared
    // Deliberately NOT @ObservedObject: this page only hands quranData to its secondary sheets as an
    // environment object. Observing it made every mounted page re-render on every QuranData publish.
    private let quranData = QuranData.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared
    /// Observed so toggling an ayah's beginner spacing re-evaluates this page: the composed text changes, and
    /// the render cache key (which folds in this page's overrides) has to be recomputed to pick it up.
    @ObservedObject private var beginnerOverrides = AyahBeginnerOverrides.shared

    let page: MushafPage

    /// The ayah the app is drawing attention to, shared with the list reader so a highlight survives a
    /// switch between reading modes. Tapping an ayah toggles it; opening to an ayah (last-read / search) or
    /// switching modes sets it. It stays lit until another ayah is selected or it is tapped again - a reading
    /// aid for keeping your place, deliberately sticky and NOT tied to the actions sheet.
    @Binding var highlightedAyah: HighlightedAyahRef?
    /// The search-arrival snippet (target ayah + matched term), colored in accent within the page text
    /// until the reader's first touch clears it.
    var arrivalHighlight: (ref: HighlightedAyahRef, term: String)? = nil
    var onClearArrival: (() -> Void)? = nil
    /// The in-page find, while its query is live: every matching ayah's matched substrings in accent,
    /// tajweed flattened for the whole page (see `MushafPageTextView.searchHighlight`).
    var searchHighlight: (matches: [HighlightedAyahRef], term: String)? = nil
    /// Multi-select: while on, taps toggle whichever ayah was touched - of EITHER surah the page carries -
    /// instead of marking it; selected ayahs take the accent tint.
    var isSelecting: Bool = false
    var selectedAyahs: Set<HighlightedAyahRef> = []
    var onToggleSelection: ((Int, Int) -> Void)? = nil
    /// Whether the reader's chrome is folded away - the fitted page's centering nudge applies only
    /// then (collapsed, the visible band's top edge hides navigation-bar dead space; uncollapsed,
    /// both edges are real chrome and plain centering is already visually even).
    var bottomBarsCollapsed: Bool = false

    /// Padding around the ayah block; the composer measures fit against the same text width and height.
    /// No slack constants beyond these: the fit verifies against the real TextKit layout, so the text gets
    /// every point the paddings don't take. Vertically almost nothing - the Quranic faces carry generous
    /// line-box air above the first ink and below the last (room for stacked marks), which reads as the
    /// page's visual margin on its own; real padding on top of it just shrank the font.
    /// Narrow on purpose (they were 20/6): every point of margin is paid for twice horizontally and
    /// once per page vertically, and the maximize-font rule says the text takes it instead. The faces'
    /// own line-box air keeps the page from touching the chrome even at these values.
    private static let textPadding: CGFloat = 12
    private static let verticalPadding: CGFloat = 2

    /// The ayah a long press landed on, driving the actions sheet. It is tinted while the sheet is open.
    @State private var sheetAyah: TappedAyahRef?

    /// Bumped when an async render lands so the body re-reads the cache (see `renderAsync`).
    @State private var renderTick = 0

    private struct TappedAyahRef: Identifiable {
        let surah: Surah
        let ayah: Ayah
        var id: String { "\(surah.id).\(ayah.id)" }
    }

    /// A sheet the actions sheet asked for, presented from here once the actions sheet has closed.
    @State private var secondarySheet: SecondarySheetRequest?

    /// A tapped surah heading in the page TEXT (the name/basmala where a surah begins mid-page) - drives
    /// the surah info sheet. The reader's pinned header has its own, at reader level.
    @State private var infoSurah: Surah?

    /// A double-tapped word's meaning card (Hafs: gloss + tajweed; non-Hafs: the riwayah word card) -
    /// the page-mode twin of the list rows' word tap, reached without opening the actions sheet first.
    /// Own wrappers rather than `TappedWord`/`RiwayahTappedWord`: those carry no surah/ayah (their
    /// sheets get them from the presenting context), and a page can show up to two surahs.
    private struct PageTappedWord: Identifiable {
        let surah: Surah
        let ayah: Ayah
        let index: Int
        let word: String
        let meaning: String
        let total: Int
        var id: String { "\(surah.id).\(ayah.id).\(index)" }
    }

    private struct PageTappedRiwayahWord: Identifiable {
        let surah: Surah
        let ayah: Ayah
        let index: Int
        let word: String
        let total: Int
        let tag: String
        var id: String { "\(surah.id).\(ayah.id).\(index)" }
    }

    @State private var pageTappedWord: PageTappedWord?
    @State private var pageTappedRiwayahWord: PageTappedRiwayahWord?

    private struct SecondarySheetRequest: Identifiable {
        let kind: AyahSecondarySheet
        let surah: Surah
        let ayah: Ayah
        var id: String { "\(kind.rawValue).\(surah.id).\(ayah.id)" }
    }

    private func ayahRef(surahID: Int, ayahID: Int) -> (Surah, Ayah)? {
        for segment in page.segments where segment.surah.id == surahID {
            if let ayah = segment.ayahs.first(where: { $0.id == ayahID }) {
                return (segment.surah, ayah)
            }
        }
        return nil
    }

    /// The ayah being recited right now, if it's on this page - it gets an accent-tinted background.
    private var playingAyah: (surahID: Int, ayahID: Int)? {
        guard let surahID = quranPlayer.currentSurahNumber,
              let ayahID = quranPlayer.currentAyahNumber,
              ayahRef(surahID: surahID, ayahID: ayahID) != nil else { return nil }
        return (surahID, ayahID)
    }

    /// The recited ayah, tinted in the accent. This is the follow-along, and it keeps working while an ayah is
    /// marked - the mark is a separate, quieter tint (below), so marking an ayah never costs you the ability to
    /// see where the reciter is.
    private var recitingAyah: (surahID: Int, ayahID: Int)? {
        playingAyah
    }

    /// The shared highlight (tap-marked, or opened-to / mode-switched onto), tinted grey. Suppressed while it
    /// IS the recited ayah, so the two tints can't fight over the same range.
    private var markedAyah: (surahID: Int, ayahID: Int)? {
        guard let highlightedAyah, ayahRef(surahID: highlightedAyah.surahID, ayahID: highlightedAyah.ayahID) != nil else { return nil }
        let marked = (surahID: highlightedAyah.surahID, ayahID: highlightedAyah.ayahID)
        if let playingAyah, playingAyah == marked { return nil }
        return marked
    }

    /// The long-pressed ayah, tinted while its actions sheet is open (task: keep the selection lit until the
    /// sheet is gone). Suppressed when it coincides with the reciting/marked tints.
    private var sheetAyahTint: (surahID: Int, ayahID: Int)? {
        guard let sheetAyah else { return nil }
        let ref = (surahID: sheetAyah.surah.id, ayahID: sheetAyah.ayah.id)
        if let playingAyah, playingAyah == ref { return nil }
        return ref
    }

    /// Tap an ayah to mark it, tap it again to clear it. Tapping a different ayah moves the mark. Writes the
    /// shared highlight so the mark carries over to the list reader.
    private func toggleHighlight(surahID: Int, ayahID: Int) {
        settings.hapticFeedback()
        let tapped = HighlightedAyahRef(surahID: surahID, ayahID: ayahID)
        withAnimation(.easeInOut(duration: 0.15)) {
            highlightedAyah = highlightedAyah == tapped ? nil : tapped
        }
    }

    /// A printed mushaf is a spread, and the spine rule marks the inner edge so you can tell at a glance
    /// which side of the spread you're on. The book opens right-to-left: page 1 carries its rule on the
    /// RIGHT (the edge you turn from), even pages on the left.
    private var spineIsLeading: Bool { page.page % 2 == 0 }

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width - Self.textPadding * 2, 1)
            // The page's FRAME is the region it can show - every piece of reader chrome is already subtracted
            // from it. Measured on an iPhone 16 Pro (points, screen 874 tall) with the reader open:
            //
            //   plain page mode   frame 144...697   safeAreaInsets top 44, bottom 0
            //   comparison mode   frame 144...664   safeAreaInsets top 44, bottom 0
            //
            // The pinned surah header sits ABOVE 144 and the controls/footer/tab bar BELOW the frame's bottom
            // (which moves up by exactly the riwayah bar's height when comparison mode adds it). So the bars
            // reduce the frame; they are NOT handed down as insets. The 44 is the navigation bar, which is
            // nowhere near this view - subtracting it took 44pt off every page's budget for chrome that
            // covers nothing, and because a ScrollView TOP-pins content shorter than its viewport, all 44
            // landed as dead space BELOW the page. That was the "page sits too high" bug: the block was
            // centered correctly, but inside a band 44pt shorter than the one it was drawn in.
            let visibleHeight = max(geo.size.height, 1)
            // The height the TEXT actually gets: the visible region minus its own vertical padding, nothing
            // else. The fit verifies against the real TextKit layout, so no slack is reserved on top.
            let textHeight = max(visibleHeight - Self.verticalPadding * 2, 1)
            // Cache-only: a page that hasn't been composed yet shows a spinner for the beat its fit takes on
            // the background queue, instead of freezing the swipe while ~30 compose/measure passes run on
            // the main thread. `renderTick` is the re-read signal the async render fires.
            let _ = renderTick
            if let rendered = MushafPageRenderCache.renderedIfAvailable(page: page, width: width, height: textHeight) {
                renderedPageBody(rendered: rendered, width: width, visibleHeight: visibleHeight)
            } else if let stale = MushafPageRenderCache.nearestRendered(page: page, width: width, height: textHeight) {
                // The height budget moved a few points (a bar appeared/disappeared, the mini player
                // mounted, a transition is mid-flight): keep the last good render of THIS page on screen
                // while the exact fit lands in the background - content over a loading flash. Same width
                // and settings, so the text re-wraps identically; only the fitted size can be a hair off
                // for the beat the refit takes.
                renderedPageBody(rendered: stale, width: width, visibleHeight: visibleHeight)
                    .task(id: "\(width)|\(textHeight)") {
                        // Debounced: during a chrome transition (a picker collapsing after a jump, the
                        // mini player mounting) the height SWEEPS through intermediate values frame by
                        // frame, and composing for each transient fitted the page to heights it never
                        // rests at - the first one to land showed the page briefly fitted SHORT before
                        // the settled fit grew it back (the shrink-then-grow flash on every picker
                        // jump), while churning the fit queues with throwaway work. The task id cancels
                        // this on every geometry change, so the sleep lets only a geometry that has
                        // held still for a beat reach the fit queue; the last good render of this page
                        // stays up meanwhile.
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        guard !Task.isCancelled else { return }
                        MushafPageRenderCache.renderAsync(page: page, width: width, height: textHeight) {
                            renderTick &+= 1
                        }
                    }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // `.task(id:)`, NOT `.onAppear`: if the geometry changes while the fit is in flight
                    // (rotation, a bar appearing), the finished render lands under the OLD key, the body
                    // re-checks under the NEW one and misses - and an onAppear that already fired would
                    // never request the new-geometry render, leaving the spinner up forever. The id re-runs
                    // this whenever the geometry the page needs actually changes; renderAsync dedupes by
                    // key, so repeats are free.
                    .task(id: "\(width)|\(textHeight)") {
                        // The same debounce as the stale branch above, for the same reason: a cold
                        // picker-jump lands mid-transition, and fitting every transient height not only
                        // queued the settled fit behind throwaway work - the first transient to finish
                        // became this page's "nearest" render and flashed the page fitted short. Only a
                        // geometry that holds still reaches the fit queue. (The reader's own prewarm
                        // already requested the landing page at the settled geometry in parallel, so
                        // this request is usually just the backstop.)
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        guard !Task.isCancelled else { return }
                        MushafPageRenderCache.renderAsync(page: page, width: width, height: textHeight) {
                            renderTick &+= 1
                        }
                    }
            }
        }
        .overlay(alignment: spineIsLeading ? .leading : .trailing) { spineRule }
        // No pinned surah header here: it belongs to the READER (`SurahPageReader.pinnedSurahHeader`), one
        // for the whole pager. A header per page rode INSIDE the pager, so every turn - including one
        // between two pages of the SAME surah - slid it out and slid an identical copy in.
        // A mushaf page is fixed-size: the Arabic uses absolute point sizes, and the chrome must not grow with
        // Dynamic Type either, or it would eat the space the text was fitted into.
        .dynamicTypeSize(.large)
        .sheet(item: $sheetAyah) { ref in
            AyahActionsSheet(
                surah: ref.surah,
                ayah: ref.ayah,
                onRequestSheet: { kind in requestSecondarySheet(kind, for: ref) }
            )
            .smallMediumSheetPresentation()
        }
        .sheet(item: $secondarySheet) { request in
            secondarySheetContent(request)
        }
        .sheet(item: $infoSurah) { surah in
            SurahInfoSheet(surahName: surah.nameTransliteration, surahNumber: surah.id)
                .environmentObject(settings)
                .environmentObject(quranData)
        }
        // The double-tapped word's card. `item:` so double-tapping a different word re-presents
        // with the new word - same pattern as the actions sheet's own word tap.
        .sheet(item: $pageTappedWord) { tapped in
            WordMeaningSheet(
                surah: tapped.surah,
                ayah: tapped.ayah,
                word: tapped.word,
                meaning: tapped.meaning,
                position: tapped.index + 1,
                total: tapped.total
            )
            .environmentObject(settings)
        }
        .sheet(item: $pageTappedRiwayahWord) { tapped in
            RiwayahWordSheet(
                surah: tapped.surah,
                ayah: tapped.ayah,
                tag: tapped.tag,
                word: tapped.word,
                index: tapped.index,
                total: tapped.total
            )
            .environmentObject(settings)
        }
        // Report this page's sheet state to the shared tracker so the pager's follow-the-recitation
        // page turn holds still while a sheet presented from this page is up - turning the page tears
        // this page view down, which dismissed its open sheet (see `AyahSheetPresence`).
        .onChange(of: anyPageSheetOpen) { open in
            if open {
                AyahSheetPresence.shared.sheetOpened()
            } else {
                AyahSheetPresence.shared.sheetClosed()
            }
        }
        .onDisappear {
            if anyPageSheetOpen {
                AyahSheetPresence.shared.sheetClosed()
            }
        }
    }

    /// Whether any sheet presented from THIS page (actions, secondary, surah info, word card) is up.
    private var anyPageSheetOpen: Bool {
        sheetAyah != nil || secondarySheet != nil || infoSurah != nil
            || pageTappedWord != nil || pageTappedRiwayahWord != nil
    }

    /// Double tap on a word: open its meaning card - the gloss + tajweed card on Hafs, the riwayah
    /// word card on a non-Hafs riwayah with a bundled pack (the same routing as the actions sheet's
    /// word tap). The word index arrives over the COMPOSED page's tokens; the ayah's trailing number
    /// ornament is one extra final token, dropped here by the bounds check against the display text.
    private func presentWordMeaning(surahID: Int, ayahID: Int, wordIndex: Int) {
        guard !isSelecting, let (surah, ayah) = ayahRef(surahID: surahID, ayahID: ayahID) else { return }
        let displayText = ayah.displayArabicText(
            surahId: surah.id,
            clean: settings.cleanArabicText,
            qiraahOverride: settings.displayQiraahForArabic
        )
        let tokens = WordTokens.tokens(in: displayText)
        guard tokens.indices.contains(wordIndex) else { return }

        if settings.isHafsDisplay {
            let glosses = WordByWordStore.shared.glosses(
                surah: surah.id, ayah: ayah.id,
                rawText: ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: nil),
                displayText: displayText
            ) ?? []
            settings.hapticFeedback()
            pageTappedWord = PageTappedWord(
                surah: surah,
                ayah: ayah,
                index: wordIndex,
                word: tokens[wordIndex],
                meaning: glosses.indices.contains(wordIndex) ? glosses[wordIndex] : "",
                total: glosses.isEmpty ? tokens.count : glosses.count
            )
        } else {
            let tag = Settings.Riwayah.canonicalTag(settings.displayQiraahForArabic ?? "")
            guard !tag.isEmpty, QiraahTajweedStore.shared.isAvailable(tag: tag) else { return }
            settings.hapticFeedback()
            pageTappedRiwayahWord = PageTappedRiwayahWord(
                surah: surah,
                ayah: ayah,
                index: wordIndex,
                word: tokens[wordIndex],
                total: tokens.count,
                tag: tag
            )
        }
    }

    /// Tap a surah's name/basmala in the page text to read about the surah.
    private func showSurahInfo(surahID: Int) {
        guard let surah = quranData.surah(surahID) else { return }
        settings.hapticFeedback()
        infoSurah = surah
    }

    /// The bookmarked ayahs among the ones this page shows - each gets a bookmark glyph over its number
    /// ornament.
    ///
    /// ONE walk of the bookmark list, not one per ayah: `settings.isBookmarked` is a linear scan, and this is
    /// evaluated on every body pass - which during recitation means every player tick, on all three mounted
    /// pages. Asking it per ayah made that ~45 full scans a tick.
    private var bookmarkedAyahsOnPage: [(surahID: Int, ayahID: Int, highlight: AyahHighlightColor?)] {
        let onPage = Set(page.ayahRefs)
        guard !onPage.isEmpty else { return [] }
        // The highlight rides along on the same walk - it lives on the bookmark record, so carrying it
        // costs nothing here and saves the page a second scan for the washes.
        return settings.bookmarkedAyahs.compactMap { bookmark in
            let ref = HighlightedAyahRef(surahID: bookmark.surah, ayahID: bookmark.ayah)
            guard onPage.contains(ref) else { return nil }
            return (surahID: ref.surahID, ayahID: ref.ayahID, highlight: bookmark.highlight)
        }
    }

    /// Fit-to-page typesets the WHOLE page into the band the reader can see, so there is nothing below the
    /// fold to scroll to - and a live scroll view there only lets the page be dragged off its own margins and
    /// rubber-banded back (user report: "if fit to page don't allow me to scroll up or down"). So once the
    /// page genuinely fits, the scroll container is dropped entirely. A page that still overflows keeps it:
    /// the composer refuses to shrink English pages, the system font and the opening spread (see
    /// `MushafPageComposer.fittedFontSize`), and those must remain reachable.
    @ViewBuilder
    private func renderedPageBody(rendered: MushafRenderedPage, width: CGFloat, visibleHeight: CGFloat) -> some View {
        // The 1pt tolerance absorbs layout-height ceil rounding: a page fitted flush to its budget
        // must never fall into the scroll branch over a fraction of a point (user rule: fit-to-page
        // must never scroll or rubber-band).
        if settings.mushafFitPage, rendered.height + Self.verticalPadding * 2 <= visibleHeight + 1 {
            // The fitted page zooms like the facsimile: pinch in and it stays, the fit is the floor.
            pageTextBody(rendered: rendered, width: width, visibleHeight: visibleHeight, zoomable: true)
        } else {
            ScrollView {
                pageTextBody(rendered: rendered, width: width, visibleHeight: visibleHeight, zoomable: false)
            }
        }
    }

    private func pageTextBody(rendered: MushafRenderedPage, width: CGFloat, visibleHeight: CGFloat,
                              zoomable: Bool) -> some View {
                MushafPageTextView(
                    attributed: rendered.text,
                    ranges: rendered.ranges,
                    width: width,
                    highlight: recitingAyah,
                    highlightColor: settings.accentColor.color,
                    playingSurahID: quranPlayer.currentSurahNumber,
                    mark: markedAyah ?? sheetAyahTint,
                    termHighlight: arrivalHighlight.map { (surahID: $0.ref.surahID, ayahID: $0.ref.ayahID, term: $0.term) },
                    searchHighlight: searchHighlight.map { highlight in
                        (matches: highlight.matches.map { (surahID: $0.surahID, ayahID: $0.ayahID) }, term: highlight.term)
                    },
                    selected: isSelecting ? selectedAyahs.map { (surahID: $0.surahID, ayahID: $0.ayahID) } : [],
                    bookmarked: bookmarkedAyahsOnPage,
                    baselineOffset: rendered.baselineOffset,
                    baselineBand: rendered.baselineBand,
                    zoomsLikePDF: zoomable
                ) { surahID, ayahID in
                    guard ayahRef(surahID: surahID, ayahID: ayahID) != nil else { return }
                    // Select mode: taps build the selection - ANY ayah on the page, whichever of the (up to
                    // two) surahs it belongs to - and never touch the reading mark.
                    if isSelecting {
                        settings.hapticFeedback()
                        onToggleSelection?(surahID, ayahID)
                        return
                    }
                    // A search arrival clears in ONE tap: touching the arrived ayah removes the accent
                    // snippet AND its selection together. A tap elsewhere clears the snippet and acts
                    // on the tapped ayah as usual.
                    if let arrival = arrivalHighlight {
                        settings.hapticFeedback()
                        onClearArrival?()
                        if arrival.ref.surahID == surahID, arrival.ref.ayahID == ayahID {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                highlightedAyah = nil
                            }
                            return
                        }
                    }
                    toggleHighlight(surahID: surahID, ayahID: ayahID)
                } onLongPressAyah: { surahID, ayahID in
                    guard let ref = ayahRef(surahID: surahID, ayahID: ayahID) else { return }
                    settings.hapticFeedback()
                    // A long press on a DIFFERENT ayah while one is selected moves the selection
                    // there. The tint precedence is `markedAyah ?? sheetAyahTint`, so without this
                    // the old mark stayed lit behind the new ayah's actions sheet - the "long-press
                    // doesn't move the selection" bug. No selection, or the same ayah pressed again:
                    // nothing to move, current behavior kept.
                    let pressed = HighlightedAyahRef(surahID: surahID, ayahID: ayahID)
                    if highlightedAyah != nil, highlightedAyah != pressed {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            highlightedAyah = pressed
                        }
                    }
                    sheetAyah = TappedAyahRef(surah: ref.0, ayah: ref.1)
                } onTapHeading: { surahID in
                    showSurahInfo(surahID: surahID)
                } onDoubleTapWord: { surahID, ayahID, wordIndex in
                    presentWordMeaning(surahID: surahID, ayahID: ayahID, wordIndex: wordIndex)
                }
                .frame(width: width, height: rendered.height)
                .padding(.horizontal, Self.textPadding)
                .padding(.vertical, Self.verticalPadding)
                // Fill the visible region so a page that fits sits centered in what the reader can SEE (balanced
                // top/bottom spacing); a page that overflows stays its natural height and scrolls.
                // A print-matched page sits at the TOP instead: it is sized by its widest printed line, so
                // on a phone it runs well short of the screen, and the printed page it mirrors leaves that
                // room below its last line, not above its first.
                .frame(maxWidth: .infinity, minHeight: visibleHeight,
                       alignment: rendered.printMatched ? .top : .center)
                // Evens the fitted page's visual air, PER CHROME STATE (user rule both times: make the
                // gaps above the first line and below the last look the same; fit-only - a scrolling
                // page has no centering to bias).
                // COLLAPSED -4: the band's bottom edge is real chrome (the chevron strip) but its top
                // edge hides ~7-8pt of navigation-bar dead space below the title pill, so the page rides
                // up by half that difference (measured 19pt above vs 12pt below before the nudge).
                // UNCOLLAPSED +2: both edges are real chrome (surah header strip above, legend/search
                // below), but the Uthmani line boxes leave more ink-free air below the last baseline
                // than above the first line's stacked marks - measured 12pt above vs 16pt below with
                // plain centering (and the collapsed -4 applied here read outright top-tight, the
                // "same height from top and below when not collapsed" report). +2 lands 14/14.
                .offset(y: zoomable && !rendered.printMatched ? (bottomBarsCollapsed ? -4 : 2) : 0)
    }

    /// Close the actions sheet, THEN open the one it asked for. UIKit can't present a second sheet while the
    /// first is still animating away, and stacking sheets is what we're avoiding anyway - so the new sheet is
    /// queued for just after the dismissal finishes.
    private func requestSecondarySheet(_ kind: AyahSecondarySheet, for ref: TappedAyahRef) {
        sheetAyah = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            secondarySheet = SecondarySheetRequest(kind: kind, surah: ref.surah, ayah: ref.ayah)
        }
    }

    @ViewBuilder
    private func secondarySheetContent(_ request: SecondarySheetRequest) -> some View {
        let surah = request.surah
        let ayah = request.ayah

        Group {
            switch request.kind {
            case .tafsir:
                AyahTafsirSheet(surahName: surah.nameTransliteration, surahNumber: surah.id, ayahNumber: ayah.id)

            case .qiraah:
                AyahQiraahComparisonSheet(surahNumber: surah.id, ayahNumber: ayah.id)
                    .environmentObject(settings)
                    .environmentObject(quranData)

            case .translations:
                AyahEnglishComparisonSheet(surahNumber: surah.id, ayahNumber: ayah.id)
                    .environmentObject(settings)
                    .environmentObject(quranData)

            case .customRange:
                // Seeded at the ayah you tapped - that's the whole reason you'd open a range from there.
                PlayCustomRangeSheet(
                    surah: surah,
                    initialStartAyah: ayah.id,
                    initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                        startAyah: ayah.id,
                        surah: surah,
                        displayQiraah: settings.displayQiraahForArabic
                    ),
                    onPlay: { start, end, repAyah, repSec in
                        quranPlayer.playCustomRange(
                            surahNumber: surah.id,
                            surahName: surah.nameTransliteration,
                            startAyah: start,
                            endAyah: end,
                            repeatPerAyah: repAyah,
                            repeatSection: repSec
                        )
                        secondarySheet = nil
                    },
                    onCancel: { secondarySheet = nil }
                )
                .environmentObject(settings)

            case .note:
                AyahNoteSheet(surah: surah, ayah: ayah)

            case .share:
                ShareAyahSheet(surahNumber: surah.id, ayahNumber: ayah.id)

            case .selectText:
                // The page's own text view is non-selectable by design (its gestures ARE the ayah
                // gestures), so page mode hands selection off to the list rows' select-and-copy sheet.
                SelectAyahTextSheet(surah: surah, ayah: ayah)
            }
        }
        .smallMediumSheetPresentation()
    }

    /// The spine: a hairline that fades out at both ends, drawn down the inner edge of the leaf.
    private var spineRule: some View {
        LinearGradient(
            colors: [
                settings.accentColor.color.opacity(0),
                settings.accentColor.color.opacity(0.55),
                settings.accentColor.color.opacity(0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: 2)
        .padding(.vertical, 24)
        .allowsHitTesting(false)
        .accessibilityLabel(spineIsLeading ? "Right-hand page" : "Left-hand page")
    }
}

// MARK: - Page mode: tappable text rendering + per-ayah actions

/// A single ayah's character range within the composed page text, so a tap can be mapped back to an ayah.
/// `ayahID == 0` is the surah HEADING (name/basmala) rather than an ayah - tapping it opens the surah info
/// sheet instead of marking an ayah. `ayahID == surahNameID` is the NAME subrange inside a heading (no
/// bismillah), recorded after its heading range so hit-testing never resolves to it - it exists only so
/// playback can tint the playing surah's name.
struct MushafAyahRange {
    /// Sentinel `ayahID` for a heading's name-only subrange.
    static let surahNameID = -1
    /// Sentinel `ayahID` for an ayah's number-ornament subrange (kept accent while a search flattens
    /// the rest of the page to the label color).
    static let ayahMarkerID = -2

    let range: NSRange
    let surahID: Int
    let ayahID: Int

    var isHeading: Bool { ayahID == 0 }
}

/// Everything the composer reads, captured on the main actor in one place. The composer used to read
/// `Settings.shared` live from inside every pass, which pinned all ~12 fit/measure passes per page to the
/// main thread; with the snapshot they are pure functions of their inputs, so the prewarm can run them on
/// a background queue. Only the tajweed-colored final pass still requires the main thread (TajweedStore).
/// Where one riwayah's printed mushaf (the Islamweb volume the app's PDF page mode shows) breaks
/// its lines, in the composer's own token model: for an ayah, the token offsets at which a printed
/// line STARTS (an offset equal to the ayah's word count is the ayah-number ornament itself), each
/// with whether that printed line fills the measure. Built by
/// `Resources/JSONs-Deprecated/Qiraat/_staging-riwayat/pipeline/printlines_build.py` off the same
/// PDFs, keyed on the app's ayah ids, and shipped as `Lines<Riwayah>` members of `lines.solidpack`.
/// Immutable after init, so it can ride inside the compose config across the fit queues.
final class MushafPrintLineTable: @unchecked Sendable {
    struct Start {
        let offset: Int
        /// The printed line fills the measure (justify it); false = the print's short closing line.
        let full: Bool
    }

    private let table: [Int: [Start]]
    let lineCount: Int

    init?(json: Data) {
        guard let raw = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let surahs = raw["s"] as? [String: [String: [Int]]] else { return nil }
        var out: [Int: [Start]] = [:]
        var count = 0
        for (surahKey, ayahs) in surahs {
            guard let surah = Int(surahKey) else { continue }
            for (ayahKey, packed) in ayahs {
                guard let ayah = Int(ayahKey), !packed.isEmpty else { continue }
                let starts = packed.map { Start(offset: $0 >> 1, full: $0 & 1 == 1) }
                    .sorted { $0.offset < $1.offset }
                out[surah * 1000 + ayah] = starts
                count += starts.count
            }
        }
        guard !out.isEmpty else { return nil }
        table = out
        lineCount = count
    }

    /// The printed line starts inside this ayah, by token offset - nil when no line opens in it.
    func starts(surah: Int, ayah: Int) -> [Start]? {
        table[surah * 1000 + ayah]
    }
}

/// The printed-line tables, one per riwayah, loaded once and kept (a table is a few thousand ints).
enum MushafPrintLines {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var loaded: [String: MushafPrintLineTable] = [:]
    nonisolated(unsafe) private static var missing: Set<String> = []

    /// `Lines<Riwayah>` - the same suffixes the tajweed packs use, plus Hafs.
    static func fileName(for tag: String?) -> String? {
        guard let tag, !Settings.Riwayah.canonicalTag(tag).isEmpty else { return "LinesHafs" }
        return QiraahTajweedStore.fileName(for: tag)?.replacingOccurrences(of: "Tajweed", with: "Lines")
    }

    static func table(for tag: String?) -> MushafPrintLineTable? {
        guard let name = fileName(for: tag) else { return nil }
        lock.lock()
        if let hit = loaded[name] { lock.unlock(); return hit }
        if missing.contains(name) { lock.unlock(); return nil }
        lock.unlock()
        let parsed = SolidPack.json(named: name, inPack: "lines").flatMap { MushafPrintLineTable(json: $0) }
        lock.lock(); defer { lock.unlock() }
        if let parsed {
            // A table is ~0.5 MB parsed; cycling through the riwayat must not pile up twenty of
            // them. Keep the newest few - a re-parse is ~20 ms off the prewarm queue.
            if loaded.count >= 3 { loaded.removeAll() }
            loaded[name] = parsed
        } else {
            missing.insert(name)
        }
        return parsed
    }
}

extension NSAttributedString.Key {
    /// Marks a composed line the print leaves SHORT (its closing lines): `spaceJustified` skips it.
    static let mushafNaturalLine = NSAttributedString.Key("MushafNaturalLine")
}

struct MushafComposeConfig {
    let pageLanguage: MushafPageLanguage
    let removeArabicDots: Bool
    let quranUsesSystemArabicFont: Bool
    let arabicFontName: String
    /// nil means Hafs. Threaded into `displayArabicText(qiraahOverride:)` so the compose never falls back
    /// to reading Settings off-main.
    let displayQiraah: String?
    let cleanArabicText: Bool
    let beginnerMode: Bool
    /// Individual ayahs the reader set letter-by-letter (the per-ayah toggle, or the multi-select "Beginner"
    /// bulk action), on top of the global `beginnerMode`. Captured here with the rest of the snapshot so the
    /// off-main fit passes never reach back to the main actor for it.
    let beginnerAyahs: Set<HighlightedAyahRef>
    /// Already folded: tajweed toggles AND the page being Arabic. English pages never paint tajweed.
    let showTajweed: Bool
    /// Non-nil = paint this non-Hafs riwayah's print-derived colors (tajweed on, pack bundled).
    let riwayahTajweedTag: String?
    /// Non-nil = this non-Hafs riwayah's pack is bundled, so khilaf-NUMBERED ayahs (its counting
    /// merges/splits vs Hafs) tint their number medallion magenta the way the print rings them.
    /// Independent of the tajweed toggle: numbering khilaf is a fact of the riwayah, not a color rule.
    let khilafMarkerTag: String?
    /// Rule keys the reader has hidden in the riwayah legend.
    let riwayahHiddenRules: Set<String>
    /// "Highlight Allah" - the composed page paints the divine name red, exactly like the list rows
    /// (English pages included: the list highlights "Allah" in translations too).
    let highlightAllahNames: Bool
    let fontSize: CGFloat
    let fitPage: Bool
    /// DISABLED - always nil. Non-nil would break the page's lines where this riwayah's printed
    /// mushaf does, and size the page so its widest printed line fits the measure. That is what a
    /// print-matched page cost: sized off the print's widest line, it ran well short of a phone
    /// screen (half the height on most pages), and the lines the print leaves short were set
    /// natural, so the closing ayahs dangled instead of justifying to the measure.
    ///
    /// Matching the print means matching WHICH AYAHS open and close each page - nothing else. The
    /// paginator already does exactly that: every one of the twenty prints is a standard 604-page
    /// Madani mushaf, and `hafsPageTable` maps each riwayah onto those same page boundaries through
    /// `QiraahComparison`. The print's line breaks, its measure, and its type size are the print's
    /// own business and are not reproduced. The table machinery below is left in place, inert.
    let printLines: MushafPrintLineTable?
    let accent: UIColor

    @MainActor
    static func current() -> MushafComposeConfig {
        let s = Settings.shared
        let language = s.resolvedMushafPageLanguage
        let riwayahTajweedTag: String? =
            (s.showTajweedColors && s.showArabicText && language == .arabic)
            ? s.riwayahTajweedPackTag : nil
        return MushafComposeConfig(
            pageLanguage: language,
            removeArabicDots: s.removeArabicDots,
            quranUsesSystemArabicFont: s.quranUsesSystemArabicFont,
            arabicFontName: s.quranArabicFontName(for: s.displayQiraahForArabic),
            displayQiraah: s.displayQiraahForArabic,
            cleanArabicText: s.cleanArabicText,
            beginnerMode: s.beginnerMode,
            beginnerAyahs: AyahBeginnerOverrides.shared.ayahs,
            showTajweed: s.showTajweedColors && s.showArabicText && s.isHafsDisplay && language == .arabic,
            riwayahTajweedTag: riwayahTajweedTag,
            khilafMarkerTag: s.riwayahTajweedPackTag,
            riwayahHiddenRules: s.riwayahTajweedHiddenRuleSet,
            highlightAllahNames: s.highlightAllahNames,
            fontSize: CGFloat(s.fontArabicSize),
            fitPage: s.mushafFitPage,
            printLines: nil,
            accent: UIColor(s.accentColor.color)
        )
    }
}

/// Builds the whole mushaf page as one `NSAttributedString` - honouring clean text, beginner letter-spacing,
/// the chosen Arabic font (including the Basic/system font), and tajweed colours - and measures it so the page
/// can be shrunk to fit. Rendering through UIKit (rather than a merged SwiftUI `Text`) is what lets individual
/// ayahs be tapped, and lets the fit be measured against exactly what is drawn.
///
/// With an English `pageLanguage`, the page's body is the transliteration / Clear Quran / Saheeh text instead
/// of the Arabic - same canonical page boundaries, same fit-to-page, ayah markers kept - set left-to-right in
/// the system face.
struct MushafPageComposer {
    let page: MushafPage
    let config: MushafComposeConfig

    private var isEnglish: Bool { config.pageLanguage.isEnglish }

    /// Dots-removed text renders in the chosen Quranic face: the bundled ttfs carry real dotless
    /// skeleton glyphs (ٮ ٯ ڡ ں with full joining forms - added by `Scripts/patch_dotless_glyphs.py`),
    /// so the old forced system-face fallback is gone everywhere (`AyahRow`/`SurahHeaders` match).
    private var usesSystemFont: Bool { isEnglish || config.quranUsesSystemArabicFont }
    private var arabicFontName: String { config.arabicFontName }
    private var shouldShowTajweed: Bool { config.showTajweed }

    private func arabicFont(_ size: CGFloat) -> UIFont {
        usesSystemFont ? .roundedSystemFont(ofSize: size)
                       : (UIFont(name: arabicFontName, size: size) ?? .roundedSystemFont(ofSize: size))
    }

    /// Always the Uthmani face, even when the reader picked "Basic": that font is what draws the ayah number as the
    /// circled-flower ornament, so the system fallback would print bare digits mid-page.
    private func markerFont(_ size: CGFloat) -> UIFont {
        UIFont(name: Settings.hafsUthmaniFontName, size: size) ?? .roundedSystemFont(ofSize: size)
    }

    /// Mushaf pages 1 and 2 (al-Fatihah, and the opening of al-Baqarah). They used to be set fully centered
    /// (short framed pages); now their body justifies like every other page - each line flush to both
    /// margins EXCEPT the paragraph's last (user rule) - and only the English/system-font renders (which
    /// can't justify, see `paragraph`) keep the centered setting.
    private var isOpeningSpread: Bool { page.page <= 2 }

    /// Whether this page's body can be space-justified at all: only the Arabic set in a real Quranic face.
    private var isJustifiable: Bool { !isEnglish && !usesSystemFont }

    /// Whether this page is set on the print's line breaks: a table is bundled and Fit Page is on, the
    /// page is justifiable Arabic, and no beginner letter-spacing is in play (that multiplies the
    /// tokens, so the print's word offsets no longer mean anything on it).
    var usesPrintLines: Bool {
        guard let table = config.printLines, isJustifiable, !config.beginnerMode,
              page.ayahRefs.allSatisfy({ !config.beginnerAyahs.contains($0) }) else { return false }
        // A page the table knows nothing about (a damaged pack; every page of every riwayah has
        // entries today) would compose as unbreakable "lines" and drive the fit to its floor:
        // such a page takes the ordinary fit instead.
        return page.segments.contains { segment in
            segment.ayahs.contains { table.starts(surah: segment.surah.id, ayah: $0.id) != nil }
        }
    }

    /// Justified everywhere (the opening spread exempts only its LAST line - see `spaceJustified`), so every
    /// line reaches BOTH margins - that's what makes a trailing-aligned page look set rather than ragged.
    ///
    /// NOT justified when the text is in the system face. Justifying Arabic works by elongating the glyphs
    /// (kashida), and only the Quranic faces carry the elongation forms; with the system face the layout engine
    /// has nothing to stretch, so it dumps ALL the slack into the word gaps instead - which is the "weird spaces
    /// between words" in Basic/no-dots mode. Trailing-aligned with natural spacing is the honest rendering there.
    /// Those renders also keep the opening spread centered, its old framed look.
    /// Base leading between the page's lines. With Fit Page on, the Arabic page is measured TIGHT: zero
    /// added spacing, the Quranic faces' own line box (~1.76x the point size, carrying all the air stacked
    /// marks need) is the only leading, so the size search converts what the old scaled-12pt gap reserved
    /// on every line into font instead (user rule: MAXIMIZE the font first). Whatever height the maximized
    /// size leaves over comes back as `extraLineSpacing` (see `fitMetrics`): spacing is paid out of the
    /// LEFTOVER, never out of the font. English prose and fit-off pages keep the classic scaled rule.
    func baseLineSpacing(for size: CGFloat) -> CGFloat {
        config.fitPage && !isEnglish
            ? 0
            : MushafPageFitter.lineSpacing(for: size, baseSize: config.fontSize)
    }

    /// How much of the body face's natural line box the fitted Arabic page keeps. The KFGQPC faces
    /// reserve ~1.76x the point size per line, sized for the rare full-height mark stack over a deep
    /// descender - and at natural leading that reservation is the single biggest thing still capping
    /// the font (maximize-font user rule: every line's saving compounds across ~15 lines). At 0.90,
    /// baselines sit 1.58x the point size apart - the pitch a printed mushaf runs - and the overflow
    /// splits evenly above and below (`bodyBaselineOffset`), where the neighbouring lines' own air
    /// absorbs it; nothing clips, the text view and zoom container draw outside their bounds already.
    /// Only the fitted Quranic-face page: English prose and the system face have no air to give, and
    /// fit-off pages keep their classic setting.
    private var lineBoxScale: CGFloat {
        config.fitPage && !isEnglish && !usesSystemFont ? 0.90 : 1
    }

    /// The pinned height of one body line under `lineBoxScale`.
    func lineBox(for size: CGFloat) -> CGFloat {
        let body = usesSystemFont ? UIFont.roundedSystemFont(ofSize: size) : arabicFont(size)
        return body.lineHeight * lineBoxScale
    }

    private func paragraph(_ size: CGFloat, extraLineSpacing: CGFloat = 0, centered: Bool? = nil) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        if centered ?? (isOpeningSpread && !isJustifiable) {
            p.alignment = .center
        } else {
            // English pages are set natural (left-aligned): justified Latin text without hyphenation
            // opens rivers of whitespace, the very artifact the Arabic justification below avoids.
            //
            // Arabic pages are set RIGHT-aligned here and justified afterwards by `spaceJustified`, NOT with
            // `.justified`: TextKit justifies Arabic by inserting kashida elongations, and when one lands in
            // a line's final letter, that letter's tashkeel slides off the letter body onto the end of the
            // stretched tail. Widening the word gaps ourselves reaches both margins with the marks intact.
            p.alignment = usesSystemFont ? .natural : .right
        }
        p.baseWritingDirection = isEnglish ? .leftToRight : .rightToLeft
        p.lineSpacing = baseLineSpacing(for: size) + extraLineSpacing
        // Pin every line box to the BODY font's height. The inline ayah ornaments come from the Uthmani
        // marker face, whose line metrics differ - without the pin, only the lines that happen to carry an
        // ornament grew taller, and the page read as unevenly leaded (worst in English, where the body face
        // is much shorter than the ornament's). Ornament ink taller than the box just draws into the line
        // gap - the leftover spread (or, fit off, the classic lineSpacing) leaves one, and the body face's
        // own line-box air absorbs the rest.
        let box = lineBox(for: size)
        p.minimumLineHeight = box
        p.maximumLineHeight = box
        return p
    }

    /// The English body text for an ayah under the current page language.
    private func englishText(for ayah: Ayah) -> String {
        switch config.pageLanguage {
        case .transliteration: return ayah.textTransliteration
        case .clearQuran:      return ayah.textEnglishMustafa
        case .saheeh:          return ayah.textEnglishSaheeh
        // Neither composes English body text: Arabic draws the mushaf itself, and the PDF is a page image
        // that never reaches this composer at all (`SurahView` swaps in the facsimile reader instead).
        case .arabic, .pdf:    return ""
        }
    }

    private func ayahText(_ ayah: Ayah, surah: Surah, size: CGFloat, colored: Bool,
                          extraLineSpacing: CGFloat = 0) -> NSAttributedString {
        let para = paragraph(size, extraLineSpacing: extraLineSpacing)

        if isEnglish {
            // No tajweed, no beginner letter-spacing - both are Arabic-script concepts.
            let ns = NSMutableAttributedString(
                string: englishText(for: ayah),
                attributes: [
                    .font: UIFont.roundedSystemFont(ofSize: size),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: para,
                ]
            )
            if colored { paintAllahNames(in: ns) }
            return ns
        }

        let clean = config.cleanArabicText
        // The global setting OR this one ayah's own override - so the per-ayah toggle and the multi-select
        // "Beginner" bulk action space out exactly the ayahs they were applied to, on the page as in the list.
        let beginner = config.beginnerMode
            || config.beginnerAyahs.contains(HighlightedAyahRef(surahID: surah.id, ayahID: ayah.id))
        let qiraahOverride = config.displayQiraah ?? "Hafs"
        let base = ayah.displayArabicText(surahId: surah.id, clean: clean, qiraahOverride: qiraahOverride)
        let display = beginner ? base.beginnerSpaced : base
        let font = arabicFont(size)

        if colored, shouldShowTajweed,
           let styled = TajweedStore.shared.attributedText(
               surah: surah.id,
               ayah: ayah.id,
               text: ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: qiraahOverride),
               displayText: display,
               cleanDisplayText: clean,
               beginnerSpacing: beginner
           ) {
            // The tajweed colours are already UIColor; overlay the font/paragraph without touching them.
            let ns = NSMutableAttributedString(attributedString: NSAttributedString(styled))
            ns.addAttributes([.font: font, .paragraphStyle: para], range: NSRange(location: 0, length: ns.length))
            paintAllahNames(in: ns)
            return ns
        }

        // Non-Hafs riwayat: the print-derived word colors of THAT mushaf. Beginner spacing keeps
        // its colors: the store re-tokenizes the spaced text by the 2+ space original word gaps.
        if colored, let tag = config.riwayahTajweedTag,
           let styled = QiraahTajweedStore.shared.attributedText(
               tag: tag, surah: surah.id, ayah: ayah.id, displayText: display,
               beginnerSpacing: beginner,
               hiddenRules: config.riwayahHiddenRules,
               // "Hide Tashkeel and Signs": the store paints the FULL text and projects the runs
               // onto the stripped page, so the print's coloring survives the strip here too.
               fullText: clean
                   ? (beginner
                      ? ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: qiraahOverride).beginnerSpaced
                      : ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: qiraahOverride))
                   : nil
           ) {
            let ns = NSMutableAttributedString(attributedString: NSAttributedString(styled))
            ns.addAttributes([.font: font, .paragraphStyle: para], range: NSRange(location: 0, length: ns.length))
            paintAllahNames(in: ns)
            return ns
        }

        let ns = NSMutableAttributedString(
            string: display,
            attributes: [.font: font, .foregroundColor: UIColor.label, .paragraphStyle: para]
        )
        if colored { paintAllahNames(in: ns) }
        return ns
    }

    /// "Highlight Allah" on the composed page - the list rows' red divine name, page-mode edition.
    /// Painted AFTER the tajweed/riwayah colors so the red wins on overlap, exactly like the list
    /// (`HighlightedSnippet` applies it over the pre-styled tajweed text). Arabic goes through the
    /// SAME shared scanner the list and word-by-word renderers use - one detector, and it already
    /// stops the red before a trailing stop-sign ornament; English matches "Allah" case-insensitively.
    /// A foreground color never moves a glyph, so the fitted layout is untouched.
    private func paintAllahNames(in ns: NSMutableAttributedString) {
        guard config.highlightAllahNames else { return }
        let text = ns.string
        if isEnglish {
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let match = text.range(of: "Allah", options: [.caseInsensitive, .diacriticInsensitive],
                                         range: searchStart..<text.endIndex) {
                ns.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(match, in: text))
                searchStart = match.upperBound
            }
            return
        }
        for range in HighlightedSnippet.arabicAllahRanges(in: text) {
            ns.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(range, in: text))
        }
    }

    /// The header a surah gets where it BEGINS, mid-page: a rule, then ONE line carrying the bracketed name
    /// (number included, inside the brackets) followed by the bismillah ornament, then a closing rule. Always
    /// centered, whatever the rest of the page does.
    ///
    /// The name and the bismillah shared a line's worth of height each before, which is a lot of a page to give
    /// up on a mushaf that already fits its text exactly. Al-Fatihah counts its basmala as ayah 1 and at-Tawbah
    /// has none, so both show the isti'adhah in the ornament's place instead (see `firstAyahIsBasmala`).
    /// How many box-drawing glyphs it takes to span `width` at `ruleSize`. The rule used to be a hardcoded 10
    /// glyphs, so it was a short dash floating in the middle of the column no matter how wide the page was.
    private func ruleString(width: CGFloat, ruleSize: CGFloat) -> String {
        let glyph = "\u{2500}"   // ─
        let glyphWidth = (glyph as NSString)
            .size(withAttributes: [.font: UIFont.systemFont(ofSize: ruleSize, weight: .light)])
            .width
        guard glyphWidth > 0 else { return String(repeating: glyph, count: 10) }
        return String(repeating: glyph, count: max(Int((width / glyphWidth).rounded(.down)), 8))
    }

    private func surahOpeningHeading(_ surah: Surah, size: CGFloat, width: CGFloat,
                                     extraLineSpacing: CGFloat, leadingBreak: Bool,
                                     firstAyahIsBasmala: Bool = false) -> (text: NSAttributedString, nameRange: NSRange) {
        let accent = config.accent
        let heading = NSMutableAttributedString()

        // The heading gets its OWN paragraph style, and deliberately not the page's. The page's carries the
        // fit's `extraLineSpacing` - the leftover height spread between lines - and a heading of three short
        // lines was being handed three helpings of it, which is why the rules ended up marooned so far from the
        // name. Here the spacing is a fixed hair, so the block is as tall as its content and no taller.
        //
        // Direction follows the heading's language: an English heading ("1. Al-Fatihah - The Opener") in an
        // RTL paragraph gets bidi-reordered - the leading "1." migrated to the far end and rendered as
        // "Al-Fatihah - The Opener .1".
        let tight = NSMutableParagraphStyle()
        tight.alignment = .center
        tight.baseWritingDirection = isEnglish ? .leftToRight : .rightToLeft
        tight.lineSpacing = 1

        // Full-column rules frame the heading: one above the name and one below it, so the surah opening
        // reads as a closed block - the bottom rule is also what separates the previous surah's last ayah
        // from this one's name. The fitter measures the same composed string, so the extra line box is
        // budgeted for automatically.
        let ruleSize = max(size * 0.3, 8)
        let rule = ruleString(width: width, ruleSize: ruleSize)
        let ruleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: ruleSize, weight: .light),
            .foregroundColor: accent.withAlphaComponent(0.4),
            .paragraphStyle: tight,
        ]

        heading.append(NSAttributedString(string: (leadingBreak ? "\n" : "") + rule + "\n",
                                          attributes: ruleAttributes))

        let nameSize = size * 0.8
        let arabicAttributes: [NSAttributedString.Key: Any] = [
            .font: arabicFont(nameSize),
            .foregroundColor: accent,
            .paragraphStyle: tight,
        ]

        // The name run's bounds within the heading (brackets + number + name, but NOT the bismillah) - the
        // composer records it as its own range so playback can tint just the name.
        let nameStart = heading.length

        if isEnglish {
            // English headings: number, transliterated name, and its meaning. No ornate brackets - those are
            // Arabic typography and read as debris around Latin text.
            heading.append(NSAttributedString(
                string: "\(surah.id). \(surah.nameTransliteration) - \(surah.nameEnglish)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: nameSize * 0.62, weight: .semibold),
                    .foregroundColor: accent,
                    .paragraphStyle: tight,
                ]
            ))
        } else {
            // The whole thing sits inside the ornate brackets - number and name together, not just the name.
            heading.append(NSAttributedString(string: "\u{FD3F} ", attributes: arabicAttributes))

            // The Arabic-Indic numeral in the SYSTEM face, not the Quranic one: the Quranic fonts draw their
            // digits as ayah-marker ornaments, which is the wrong thing entirely for a surah number. Light
            // weight: next to the calligraphic name a semibold numeral read far too heavy.
            heading.append(NSAttributedString(string: surah.idArabic, attributes: [
                .font: UIFont.systemFont(ofSize: nameSize * 0.8, weight: .light),
                .foregroundColor: accent,
                .paragraphStyle: tight,
            ]))

            // The gap between the numeral and the name has to be a FIXED-width space, for the same reason as
            // the bismillah gap below: an ordinary space between two Arabic runs collapses to almost nothing,
            // leaving "١٤إبراهيم" reading as one word. A full em quad (\u{2001}) overshot the other way, so
            // this is an en quad - half an em - widened by kerning to land between the two. Tune `nameGap`,
            // not the character. The brackets keep their plain spaces; those already sit clear.
            let nameGap = -nameSize * 0.125        // en quad (0.5 em) + this = 0.375 em of separation
            var gapAttributes = arabicAttributes
            gapAttributes[.kern] = nameGap
            heading.append(NSAttributedString(string: "\u{2000}", attributes: gapAttributes))

            // The name honours Hide Tashkeel / Hide Dots like every other surah-name surface (list rows,
            // toolbar title). Through the config snapshot, not Settings.shared - the composer runs off-main.
            var headingName = surah.nameArabic
            if config.cleanArabicText { headingName = headingName.removingArabicDiacriticsAndSigns }
            if config.removeArabicDots { headingName = headingName.removingArabicDots }
            heading.append(NSAttributedString(string: "\(headingName) \u{FD3E}", attributes: arabicAttributes))
        }

        let nameRange = NSRange(location: nameStart, length: heading.length - nameStart)

        // What follows the name on its line. An ordinary surah gets the basmala ornament. Al-Fatihah whose
        // first NUMBERED ayah IS the basmala (Hafs and most countings - the basmala prints right below as
        // ayah 1), and at-Tawbah (no basmala at all), get the isti'adhah instead - the same headers the
        // list reader shows. A Fatiha text whose first numbered ayah is alhamdu (its basmala unnumbered)
        // gets the basmala, again matching the list rule.
        //
        // On the SAME line as the name. Em quads (not spaces): a run of ordinary spaces between two Arabic
        // runs collapses to almost nothing, which is why the ornament was sitting right up against the name.
        heading.append(NSAttributedString(string: "\u{2001}\u{2001}\u{2001}", attributes: [
            .font: arabicFont(nameSize),
            .foregroundColor: accent,
            .paragraphStyle: tight,
        ]))
        let showsTaawwudh = surah.id == 9 || (surah.id == 1 && firstAyahIsBasmala)
        let ornament: (text: String, font: UIFont)
        if showsTaawwudh {
            // The phrase in the reader's own Arabic face (user rule: "just say audhubillahi mina... in
            // the arabic font"). Its spaces are NO-BREAK, so it can never split mid-phrase: when the
            // name's line can't hold it, it drops WHOLE onto the next centered line (the break happens
            // at the breakable em quads above) instead of leaving ٱلرَّجِيمِ orphaned below.
            ornament = (Self.taawwudhText.replacingOccurrences(of: " ", with: "\u{00A0}"),
                        arabicFont(nameSize * 0.85))
        } else {
            let bismillahFont = UIFont(name: QuranGlyphFont.commonName, size: nameSize)
            ornament = (bismillahFont != nil ? QuranGlyphFont.bismillahOrnament : Self.basmalaText,
                        bismillahFont ?? arabicFont(nameSize * 0.85))
        }
        heading.append(NSAttributedString(string: ornament.text, attributes: [
            .font: ornament.font,
            .foregroundColor: accent,
            .paragraphStyle: tight,
        ]))

        // The closing rule under the heading line.
        heading.append(NSAttributedString(string: "\n" + rule + "\n", attributes: ruleAttributes))
        return (heading, nameRange)
    }

    /// Fallback only - used if `QuranCommon` isn't installed and the ornament can't be drawn.
    private static let basmalaText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"

    /// The isti'adhah, shown in place of the basmala for al-Fatihah and at-Tawbah (the same text the list
    /// reader's header row shows).
    private static let taawwudhText = "أَعُوذُ بِٱللَّهِ مِنَ ٱلشَّيۡطَانِ ٱلرَّجِيمِ"

    /// The composed page text plus each ayah's character range for hit-testing.
    /// `width` is the column width, needed only so a surah heading's rule can span the full page. It is
    /// optional because the measurement passes don't have a meaningful one yet and don't care.
    func attributed(size: CGFloat, colored: Bool = true, extraLineSpacing: CGFloat = 0,
                    width: CGFloat = 0, spaceTracking: CGFloat = 0,
                    justified: Bool = true) -> (text: NSAttributedString, ranges: [MushafAyahRange]) {
        let result = NSMutableAttributedString()
        var ranges: [MushafAyahRange] = []
        let accent = config.accent
        let para = paragraph(size, extraLineSpacing: extraLineSpacing)
        // Each segment's full ayah-text range (headings excluded), for the balance pass: it re-breaks
        // the segment so every line - the closing one included - holds its fair share of words before
        // `spaceJustified` stretches them all to the margins.
        var fillableSegments: [NSRange] = []
        // Set on the print's breaks (see `applyPrintBreaks`): the balance pass then stands down.
        var printApplied = false

        for (i, segment) in page.segments.enumerated() {
            // A surah OPENING on this page gets the printed treatment: a full-width rule, the name line, and
            // the basmala. A surah merely *continuing* onto the page after another one ends gets just its name -
            // and the page's own opening surah is titled by the pinned header, so it gets nothing.
            if segment.ayahs.first?.id == 1 {
                let headingStart = result.length
                // Fatiha only: whether its first NUMBERED ayah is the basmala (Hafs) or alhamdu (countings
                // that leave the basmala unnumbered) decides isti'adhah vs basmala in the heading - the
                // same check the list reader makes. Raw text + sign-strip rather than `textCleanArabic`,
                // which folds dots away under "Hide Arabic Dots" and would break the بسم prefix match.
                let firstAyahIsBasmala = segment.surah.id == 1 && (segment.ayahs.first?
                    .textArabic(for: config.displayQiraah, surahID: segment.surah.id)
                    .removingArabicDiacriticsAndSigns
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .hasPrefix("بسم") ?? false)
                let heading = surahOpeningHeading(segment.surah, size: size, width: width,
                                                  extraLineSpacing: extraLineSpacing, leadingBreak: i > 0,
                                                  firstAyahIsBasmala: firstAyahIsBasmala)
                result.append(heading.text)
                // The heading (rule + name + basmala) is tappable: `ayahID: 0` marks it as a heading range so a
                // tap opens the surah info sheet instead of trying to mark an ayah.
                ranges.append(MushafAyahRange(
                    range: NSRange(location: headingStart, length: result.length - headingStart),
                    surahID: segment.surah.id,
                    ayahID: 0
                ))
                // The NAME subrange, recorded AFTER the heading range (hit-testing takes the first hit, so
                // taps keep resolving to the heading) - it lets playback tint the name and only the name.
                if heading.nameRange.length > 0 {
                    ranges.append(MushafAyahRange(
                        range: NSRange(location: headingStart + heading.nameRange.location,
                                       length: heading.nameRange.length),
                        surahID: segment.surah.id,
                        ayahID: MushafAyahRange.surahNameID
                    ))
                }
            } else if i > 0 {
                let name = isEnglish
                    ? "\n\(segment.surah.id). \(segment.surah.nameTransliteration)\n"
                    : "\n﴿ \(segment.surah.nameTransliteration) ﴾\n"
                let headingStart = result.length
                result.append(NSAttributedString(string: name, attributes: [
                    .font: UIFont.systemFont(ofSize: max(size * 0.5, 12), weight: .semibold),
                    .foregroundColor: accent,
                    .paragraphStyle: paragraph(size, extraLineSpacing: extraLineSpacing, centered: true)
                ]))
                ranges.append(MushafAyahRange(
                    range: NSRange(location: headingStart, length: result.length - headingStart),
                    surahID: segment.surah.id,
                    ayahID: 0
                ))
                // The continuing name is all name - same playback tint hook as the opening heading.
                ranges.append(MushafAyahRange(
                    range: NSRange(location: headingStart, length: result.length - headingStart),
                    surahID: segment.surah.id,
                    ayahID: MushafAyahRange.surahNameID
                ))
            }

            let segmentTextStart = result.length
            // The print's line breaks inside this segment, as (character to turn into a line
            // separator, whether the line it opens fills the measure) - see `applyPrintBreaks`.
            var printBreaks: [(position: Int, full: Bool)] = []
            // The segment's first line: full/short per the print when its first ayah opens a printed
            // line. Otherwise (resolved below) a surah's opening line counts as complete - its heading
            // precedes it, so the line is whole even where the table lacks the entry (at-Tawbah's
            // vector-art banner in six prints) - but a page that opens MID-surah on an ayah the print
            // set mid-line (the ~30 pages a riwayah where the two page tables differ by one ayah)
            // opens with the TAIL of a printed line, which is set natural: stretching its three words
            // across the measure was the page-121 first-line bug.
            var firstLineFull: Bool? = nil
            let printTable = usesPrintLines ? config.printLines : nil

            for ayah in segment.ayahs {
                let start = result.length
                result.append(ayahText(ayah, surah: segment.surah, size: size, colored: colored,
                                       extraLineSpacing: extraLineSpacing))
                let markerStart = result.length
                if let printTable, let starts = printTable.starts(surah: segment.surah.id, ayah: ayah.id) {
                    let tokenStarts = Self.tokenStarts(
                        in: result.attributedSubstring(from: NSRange(location: start, length: markerStart - start)).string as NSString)
                    for entry in starts {
                        if entry.offset == 0 {
                            // The ayah opens a printed line: break on the previous ornament's trailing
                            // space; the segment's first ayah opens its line anyway.
                            if start == segmentTextStart { firstLineFull = entry.full }
                            else { printBreaks.append((start - 1, entry.full)) }
                        } else if entry.offset < tokenStarts.count {
                            printBreaks.append((start + tokenStarts[entry.offset] - 1, entry.full))
                        } else if entry.offset == tokenStarts.count {
                            // The line opens with the ayah's number ornament: its leading space.
                            printBreaks.append((markerStart, entry.full))
                        }
                    }
                }
                // The prints ring an ayah's number medallion in magenta when its NUMBERING differs
                // from Hafs (a merge/split point of this riwayah's counting) - mirror that on the
                // composed page. Number khilaf is a fact of the riwayah's text, not a tajweed color,
                // so it shows whenever a non-Hafs riwayah with a pack is displayed (same philosophy
                // as the always-on word diff tint), independent of the tajweed toggle. Colors never
                // move a glyph, so the plain and colored composes still lay out identically.
                let markerColor: UIColor
                if let tag = config.khilafMarkerTag,
                   QiraahTajweedStore.shared.isKhilafNumbered(tag: tag, surah: segment.surah.id, ayah: ayah.id) {
                    markerColor = QiraahTajweedStore.khilafNumberColor
                } else {
                    markerColor = accent
                }
                result.append(NSAttributedString(string: " \(ayah.idArabic) ", attributes: [
                    .font: markerFont(size),
                    .foregroundColor: markerColor,
                    .paragraphStyle: para
                ]))
                ranges.append(MushafAyahRange(
                    range: NSRange(location: start, length: result.length - start),
                    surahID: segment.surah.id,
                    ayahID: ayah.id
                ))
                // The ayah-number ornament's own range, recorded AFTER the ayah range (so a tap still
                // resolves to the ayah) - it lets the search flatten keep the number accent-colored, the
                // way the list rows always show it, instead of graying it out with the rest of the ayah.
                ranges.append(MushafAyahRange(
                    range: NSRange(location: markerStart, length: result.length - markerStart),
                    surahID: segment.surah.id,
                    ayahID: MushafAyahRange.ayahMarkerID
                ))
            }

            if let printTable {
                // The segment's closing line is only a COMPLETE printed line when the surah ends in
                // it or the print also breaks right after this segment's last ayah; otherwise the
                // page cut a printed line short (the app's page boundary sits a line off the print's
                // on ~30 pages), and a truncated line is set natural rather than stretched across
                // the measure.
                var closingComplete = segment.endsSurah
                if !closingComplete, let last = segment.ayahs.last {
                    closingComplete = printTable.starts(surah: segment.surah.id, ayah: last.id + 1)?
                        .contains { $0.offset == 0 } ?? false
                }
                Self.applyPrintBreaks(to: result, breaks: printBreaks,
                                      segment: NSRange(location: segmentTextStart, length: result.length - segmentTextStart),
                                      firstLineFull: firstLineFull ?? (i > 0 || segment.ayahs.first?.id == 1),
                                      closingComplete: closingComplete)
                printApplied = true
            }
            fillableSegments.append(NSRange(location: segmentTextStart,
                                            length: result.length - segmentTextStart))
        }

        // The opening spread's LAST page line is set CENTERED - the classic framed look of the mushaf's
        // first two pages (user rule: "first two pages make the last line centered always"). Done in BOTH
        // compose paths (the justified plain compose and the `justified: false` colored one) with a swap
        // that never changes the character count, so the transplant below and the ayah hit-test ranges
        // stay index-aligned by construction.
        var centeredClosingLine = false
        if isOpeningSpread, isJustifiable, width > 0 {
            centeredClosingLine = Self.centerLastLine(of: result, width: width,
                                                      lineSpacing: baseLineSpacing(for: size) + extraLineSpacing)
        }

        // Justify the final compose in three passes: the page-wide loosening (`spaceTracking`, which DOES
        // move line breaks - it was fitted against the same budget, see `balancedSpaceTracking`), then the
        // balance pass that re-breaks each segment so EVERY line can be filled with even gaps, then the
        // per-line top-up to the exact margins, which only ever consumes slack inside a line and moves
        // nothing. Tracking attributes don't shift character indices, so the ayah hit-test ranges stay valid.
        // `justified: false` skips all of it - the render pipeline computes the justification OFF the main
        // thread on the plain compose and transplants it (see `justification(size:...)`), so the colored
        // main-thread compose must not pay for it again.
        if justified, width > 0, isJustifiable {
            let balanced = NSMutableAttributedString(attributedString: result)
            if spaceTracking > 0 { Self.addSpaceTracking(spaceTracking, to: balanced) }
            // The opening spread justifies too (user rule: its lines fill the measure like any page) but
            // classically - greedy breaks - so the balance pass, which exists to make a STRETCHED closing
            // line sane, stands down there.
            if !isOpeningSpread, !printApplied {
                Self.balanceLineBreaks(balanced, width: width, segments: fillableSegments, bodySize: size)
            }
            // Once the last line is its own centered paragraph, every remaining right-aligned line - the
            // body's new closing line included - fills to both margins like any other page; the centered
            // tail is skipped by alignment. Only if the swap didn't land does the old exemption hold.
            return (Self.spaceJustified(balanced, width: width,
                                        exemptClosingLines: isOpeningSpread && !centeredClosingLine), ranges)
        }

        return (result, ranges)
    }

    /// Opening spread only: turns the page's final soft wrap into a hard break and centers the tail.
    ///
    /// The break SPACE is REPLACED, in place, by a newline - same character count, so every ayah
    /// hit-test range and the off-main justification transplant's indices survive untouched. The new
    /// tail paragraph keeps the pinned line box and carries `paragraphSpacingBefore` equal to the line
    /// spacing the paragraph split removed (TextKit applies `lineSpacing` only WITHIN a paragraph), so
    /// the last line sits exactly where it did and the page's height doesn't move.
    /// Returns whether the swap landed - a single-line paragraph, or a last line that opens a paragraph
    /// of its own already, has no break space to absorb and keeps its natural setting.
    @discardableResult
    private static func centerLastLine(of text: NSMutableAttributedString, width: CGFloat,
                                       lineSpacing: CGFloat) -> Bool {
        // Bound as a whole: NSLayoutManager does not retain its NSTextStorage.
        let stack = layoutStack(for: text, width: width)
        let manager = stack.manager
        guard manager.numberOfGlyphs > 0 else { return false }

        var lastLineRange = NSRange()
        var glyph = 0
        while glyph < manager.numberOfGlyphs {
            var lineGlyphRange = NSRange()
            manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &lineGlyphRange)
            lastLineRange = manager.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
            glyph = NSMaxRange(lineGlyphRange)
        }

        let string = text.string as NSString
        let lineStart = lastLineRange.location
        // Only a RUNNING-TEXT last line (right-aligned body) that wrapped off a space is centered.
        guard lineStart > 0, lineStart < string.length,
              [0x20, 0x2028].contains(string.character(at: lineStart - 1)),
              let style = text.attribute(.paragraphStyle, at: lineStart, effectiveRange: nil) as? NSParagraphStyle,
              style.alignment == .right,
              let centered = style.mutableCopy() as? NSMutableParagraphStyle else { return false }

        text.replaceCharacters(in: NSRange(location: lineStart - 1, length: 1), with: "\n")

        centered.alignment = .center
        centered.paragraphSpacingBefore = lineSpacing
        text.addAttribute(.paragraphStyle, value: centered,
                          range: NSRange(location: lineStart, length: text.length - lineStart))
        return true
    }

    /// The page-wide justification - loosening, balanced re-breaks, margin top-up - computed on the PLAIN
    /// compose so it can run off the main thread, packaged as the final `.tracking` runs plus the exact
    /// laid-out height. `finalize` transplants the runs onto the tajweed-colored compose instead of
    /// re-running the pipeline on the main thread (segment layouts, break probes and verification made
    /// that a per-page main-thread stall during every prewarm ring). Valid because color attributes never
    /// move a glyph: the same invariant the whole fit pipeline already rests on - pages are FITTED plain
    /// and DRAWN colored - and tracking is keyed by character index, which the two composes share.
    func justification(size: CGFloat, extraLineSpacing: CGFloat, width: CGFloat,
                       spaceTracking: CGFloat) -> (tracking: [(range: NSRange, value: CGFloat)], height: CGFloat) {
        let text = attributed(size: size, colored: false, extraLineSpacing: extraLineSpacing,
                              width: width, spaceTracking: spaceTracking).text
        var runs: [(range: NSRange, value: CGFloat)] = []
        text.enumerateAttribute(.tracking, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            if let value = value as? CGFloat { runs.append((range, value)) }
        }
        return (runs, Self.layoutHeight(of: text, width: width))
    }

    /// The TextKit-1 stack `MushafPageTextView` renders with (`lineFragmentPadding = 0`, unbounded height),
    /// laid out and ready to query. Shared by every measurement in this type so they can't drift from each
    /// other - or from what the text view actually draws.
    static func layoutStack(
        for text: NSAttributedString,
        width: CGFloat
    ) -> (storage: NSTextStorage, manager: NSLayoutManager, container: NSTextContainer) {
        let storage = NSTextStorage(attributedString: text)
        let manager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)
        return (storage, manager, container)
    }

    /// Justifies right-aligned Arabic by distributing each line's leftover width across the word gaps (as
    /// tracking on the spaces). This is what `.justified` would do MINUS kashida glyph elongation, which
    /// TextKit is free to place inside a line's final letter - detaching that letter's tashkeel onto the
    /// stretched tail, the mushaf reader's "floating haraka at the margin" artifact. EVERY line takes the
    /// full measure - each paragraph's closing line (a surah ending mid-page, the page's own last line)
    /// included, deliberately: `balanceLineBreaks` has already re-broken each segment so the closing line
    /// holds its fair share of words, and whatever sparseness remains is stretched anyway - a mushaf page
    /// wants every line flush to both margins, never centered, never left short. Headings keep their own
    /// centering; the only line left untouched is one with no gaps at all (a single word, nothing to
    /// stretch - it sits at the right margin, where reading starts).
    /// `exemptClosingLines` (the opening spread): each right-aligned paragraph's LAST line keeps its natural
    /// setting instead of being stretched - classic justification, where only full lines reach the margin.
    private static func spaceJustified(_ source: NSAttributedString, width: CGFloat,
                                       exemptClosingLines: Bool = false) -> NSAttributedString {
        // The whole stack stays bound: NSLayoutManager does NOT retain its NSTextStorage, so discarding the
        // storage would tear the layout down under the queries below.
        let stack = layoutStack(for: source, width: width)
        let manager = stack.manager
        let string = source.string as NSString

        var spaceAdvances: [UIFont: CGFloat] = [:]
        func spaceAdvance(of font: UIFont) -> CGFloat {
            if let cached = spaceAdvances[font] { return cached }
            let advance = (" " as NSString).size(withAttributes: [.font: font]).width
            spaceAdvances[font] = advance
            return advance
        }

        /// One full justification build. `reclaimTrailing` zeroes each line's break-space and gives its
        /// width to the content - see the note inside - and also reports the source layout's line count
        /// so the caller can verify the reclaim never moved a break.
        func justify(reclaimTrailing: Bool) -> (text: NSMutableAttributedString, sourceLines: Int) {
            let justified = NSMutableAttributedString(attributedString: source)
            var sourceLines = 0
            var glyphIndex = 0
            while glyphIndex < manager.numberOfGlyphs {
                var lineGlyphRange = NSRange()
                let usedRect = manager.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: &lineGlyphRange)
                glyphIndex = NSMaxRange(lineGlyphRange)
                sourceLines += 1

                let charRange = manager.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
                guard charRange.length > 0 else { continue }

                // Only the running right-aligned Arabic participates; headings and rules are centered on purpose.
                let style = source.attribute(.paragraphStyle, at: charRange.location, effectiveRange: nil) as? NSParagraphStyle
                guard style?.alignment == .right else { continue }

                // A line the print leaves short (print-matched pages): keep it natural.
                if source.attribute(.mushafNaturalLine, at: charRange.location, effectiveRange: nil) != nil { continue }

                // Opening spread: the paragraph's closing line keeps its natural setting.
                if exemptClosingLines {
                    let para = string.paragraphRange(for: NSRange(location: charRange.location, length: 0))
                    var paraContentEnd = NSMaxRange(para)
                    while paraContentEnd > para.location,
                          let scalar = Unicode.Scalar(string.character(at: paraContentEnd - 1)),
                          CharacterSet.whitespacesAndNewlines.contains(scalar) {
                        paraContentEnd -= 1
                    }
                    if NSMaxRange(charRange) >= paraContentEnd { continue }
                }

                let lineEnd = NSMaxRange(charRange)

                // Stretch every space in the line except the trailing whitespace at the break - widening
                // that would move the break itself.
                var contentEnd = lineEnd
                while contentEnd > charRange.location,
                      let scalar = Unicode.Scalar(string.character(at: contentEnd - 1)),
                      CharacterSet.whitespacesAndNewlines.contains(scalar) {
                    contentEnd -= 1
                }
                var spaceLocations: [Int] = []
                for i in charRange.location..<contentEnd where string.character(at: i) == 0x20 {
                    spaceLocations.append(i)
                }

                // The line's used rect INCLUDES its trailing break-space, so slack measured from the used
                // width alone leaves every line short of the left margin by exactly one tracked space -
                // a phantom spacer at each line's end. Add the trailing space's advance back (its font's
                // space plus its tracking, known exactly), and let the stretched content push the invisible
                // space out past the margin instead. Only for lines the used rect reports honestly: a rect
                // sitting at the container width has been CLAMPED - the trailing space already overflowed -
                // and reclaiming there would overfill the line and cascade re-breaks; a jammed line is
                // already flush anyway.
                // In this configuration the break-space is NOT hung outside the measure: TextKit sets it
                // INSIDE the line, between the content and the left margin - a literal phantom spacer at
                // the end of every line, which is why lines used to stop one tracked space short of the
                // edge. Its width is reclaimed below: the space's advance is zeroed outright (tracking
                // adds to the advance, so minus the space's own width is exactly zero) and the content is
                // topped up into the freed room. Both edits land together, so the line still fills the
                // measure exactly and no break can move. The slack itself needs no width arithmetic: in
                // container coordinates the left margin is x = 0 and the content's left edge is its
                // leftmost glyph's origin, so that origin's x IS the slack - exact whether or not the
                // used rect was clamped. The scan covers the line's whole last word (not just its final
                // glyph) because a multi-digit ayah marker is a left-to-right run inside the
                // right-to-left line, where the logically last glyph can sit a digit's width right of
                // the block's true edge.
                var slack = width - usedRect.width
                if reclaimTrailing {
                    var lastWordStart = contentEnd - 1
                    while lastWordStart > charRange.location,
                          string.character(at: lastWordStart - 1) != 0x20,
                          string.character(at: lastWordStart - 1) != 0x2028 {
                        lastWordStart -= 1
                    }
                    var leftEdge = CGFloat.greatestFiniteMagnitude
                    for c in lastWordStart..<contentEnd {
                        let glyph = manager.glyphIndexForCharacter(at: c)
                        leftEdge = min(leftEdge, manager.location(forGlyphAt: glyph).x)
                    }
                    if leftEdge < .greatestFiniteMagnitude { slack = leftEdge }
                }

                guard !spaceLocations.isEmpty else { continue }
                guard slack > 1.5 else { continue }

                // Zero the break-space only on a line that is being topped up: the two edits are what
                // keep each other break-stable. A zeroed space on an un-stretched line would instead
                // free room the next word could jump back up into.
                if reclaimTrailing {
                    for i in contentEnd..<lineEnd where string.character(at: i) == 0x20 {
                        let font = (source.attribute(.font, at: i, effectiveRange: nil) as? UIFont)
                            ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
                        justified.addAttribute(.tracking, value: -spaceAdvance(of: font),
                                               range: NSRange(location: i, length: 1))
                    }
                }
                // Fill to a fixed 1pt short of the margin, not a percentage: a proportional factor leaves a
                // margin that shrinks with the slack (2% of a 1pt slack is nothing), and a line that lands even
                // a rounding error past the container re-breaks - which would shift every break below it and put
                // all the following lines' widened gaps on the wrong spaces. An absolute point of headroom is
                // bigger than any advance-rounding difference TextKit produces at these sizes.
                let perSpace = (slack - 1.0) / CGFloat(spaceLocations.count)

                // `.tracking`, deliberately NOT `.kern`: kern participates in glyph shaping, and an attribute
                // boundary it introduces at a space could perturb how the neighbouring cluster's marks attach -
                // the "tashkeel drifts off the letter" artifact, worst on an ayah's final letter where the marker
                // run already changes fonts. Tracking is applied after shaping, so it widens the space's advance
                // and can touch nothing else.
                for location in spaceLocations {
                    let existing = (justified.attribute(.tracking, at: location, effectiveRange: nil) as? CGFloat) ?? 0
                    justified.addAttribute(.tracking, value: existing + perSpace, range: NSRange(location: location, length: 1))
                }
            }
            return (justified, sourceLines)
        }

        // The reclaim can push a line's content to the exact margin, where a mis-read edge would mean
        // an overfilled line and cascading re-breaks - so verify with one layout: same line count out
        // as in, or fall back to the conservative used-width measure (which can only ever run short).
        let (corrected, sourceLines) = justify(reclaimTrailing: true)
        let verify = layoutStack(for: corrected, width: width)
        var correctedLines = 0
        var glyph = 0
        while glyph < verify.manager.numberOfGlyphs {
            var lineRange = NSRange()
            verify.manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &lineRange)
            glyph = NSMaxRange(lineRange)
            correctedLines += 1
        }
        return correctedLines == sourceLines ? corrected : justify(reclaimTrailing: false).text
    }

    /// Re-breaks every right-aligned paragraph of each segment so that EVERY line - the closing one
    /// included - can take the full measure with moderate, even gaps once `spaceJustified` tops it up.
    ///
    /// The problem this solves: TextKit breaks lines greedily, so a paragraph's closing line gets whatever
    /// is left over - three words, say, where the lines above hold twelve. Justifying that flings a handful
    /// of words across the whole measure, and centring it instead leaves one line neither full nor trailing.
    /// The typesetter's fix is to borrow: pull a word down from the line above, which may leave THAT line
    /// short, so the borrowing cascades upward line by line until the deficit lands where it costs nothing.
    /// The old pass ran that cascade literally - one word per step, each step an escalating ladder of probe
    /// relayouts, up to ~a hundred incremental layouts per segment - and only ever started from the closing
    /// line, so it stopped at "not ugly" rather than at "even".
    ///
    /// This pass solves the whole cascade at once. One layout measures every word's advance width (shaping
    /// never crosses a space, so a line's width is additive in its words and gaps); a dynamic program then
    /// picks, among ALL ways of breaking the same words into the SAME number of lines (the page was fitted
    /// at that count and the line boxes are pinned - a different count is a different page height), the
    /// breaks that minimize the summed squared per-gap widening. That is every line borrowing from every
    /// line above it simultaneously, with the evenest result the words allow. The chosen breaks are then
    /// FORCED: each line's gaps are widened until the line reaches just short of the measure, so TextKit's
    /// greedy pass has no choice but to break where the program chose. `spaceJustified` afterwards tops
    /// every line up to the exact margin - full and trailing, on every line.
    ///
    /// There is NO sparseness cap and no centered fallback: however few words a segment ends with, the
    /// evenest breaks win and `spaceJustified` stretches every line - the closing one included - to the
    /// full measure. The squared objective is what keeps that sane: it hates one wide-gapped line far more
    /// than many slightly-loose ones, so the sparseness a short tail forces is always spread across the
    /// whole segment rather than dumped on the last line.
    ///
    /// EFFICIENCY. A paragraph whose closing line is already nearly full skips everything after one
    /// measurement. Otherwise: one word-width sweep feeds the model (gap advances come from a per-font
    /// cache, no typesetting), the dynamic program runs in microseconds over prefix sums, and ONE
    /// relayout normally verifies the forced breaks. A line that comes back broken a word early is truly
    /// wider in-context than it measures alone (ayah markers, bidi digit runs) - it earns a doubling
    /// width surcharge and the probe repeats, converging in a couple of rounds; a paragraph that never
    /// converges reverts to its greedy breaks. Runs once per cached render, off the main thread.
    private static func balanceLineBreaks(_ text: NSMutableAttributedString, width: CGFloat,
                                          segments: [NSRange], bodySize: CGFloat) {
        guard width > 0, bodySize > 0 else { return }

        // Space advance per font, measured once per pass and shared by every gap on the page.
        var spaceAdvances: [UIFont: CGFloat] = [:]
        func spaceAdvance(of font: UIFont) -> CGFloat {
            if let cached = spaceAdvances[font] { return cached }
            let advance = (" " as NSString).size(withAttributes: [.font: font]).width
            spaceAdvances[font] = advance
            return advance
        }

        for segment in segments where segment.length > 0 {
            // The segment lays out alone: line breaking never crosses a paragraph boundary, so the
            // substring's breaks are exactly the page's, and measuring it is far cheaper.
            let sub = text.attributedSubstring(from: segment)
            let subString = sub.string as NSString
            // The whole stack stays bound: NSLayoutManager does not retain its NSTextStorage.
            let stack = layoutStack(for: sub, width: width)

            // Each right-aligned paragraph balances independently (in practice a segment is one; the
            // headings and basmala are centered paragraphs and skip).
            var cursor = 0
            while cursor < subString.length {
                let paragraph = subString.paragraphRange(for: NSRange(location: cursor, length: 0))
                cursor = max(NSMaxRange(paragraph), cursor + 1)
                guard paragraph.length > 0,
                      let style = sub.attribute(.paragraphStyle, at: paragraph.location, effectiveRange: nil) as? NSParagraphStyle,
                      style.alignment == .right else { continue }
                balanceParagraph(paragraph, segment: segment, sub: sub, subString: subString,
                                 stack: stack, pageText: text, width: width, bodySize: bodySize,
                                 spaceAdvance: spaceAdvance)
            }
        }
    }

    /// One paragraph of `balanceLineBreaks`: model the words, solve for the balanced breaks, force them,
    /// verify against a real relayout, and commit the winning tracking to the page text.
    private static func balanceParagraph(_ paragraph: NSRange, segment: NSRange,
                                         sub: NSAttributedString, subString: NSString,
                                         stack: (storage: NSTextStorage, manager: NSLayoutManager, container: NSTextContainer),
                                         pageText: NSMutableAttributedString, width: CGFloat,
                                         bodySize: CGFloat,
                                         spaceAdvance: (UIFont) -> CGFloat) {
        let manager = stack.manager

        // The paragraph terminator and any trailing whitespace hang outside the last line.
        var contentEnd = NSMaxRange(paragraph)
        while contentEnd > paragraph.location,
              let scalar = Unicode.Scalar(subString.character(at: contentEnd - 1)),
              CharacterSet.whitespacesAndNewlines.contains(scalar) {
            contentEnd -= 1
        }
        guard contentEnd > paragraph.location else { return }

        // Words (maximal space-free runs - the ayah ornaments count, lines may break around them) and
        // the gap runs between them.
        var words: [NSRange] = []
        var gaps: [NSRange] = []
        var scan = paragraph.location
        while scan < contentEnd {
            let isSpace = subString.character(at: scan) == 0x20
            var runEnd = scan + 1
            while runEnd < contentEnd, (subString.character(at: runEnd) == 0x20) == isSpace { runEnd += 1 }
            if isSpace {
                gaps.append(NSRange(location: scan, length: runEnd - scan))
            } else {
                words.append(NSRange(location: scan, length: runEnd - scan))
            }
            scan = runEnd
        }
        // Strictly interior gaps: a paragraph opening with a space (never composed, but cheap to refuse)
        // would break the word/gap pairing the model rests on.
        guard words.count >= 3, gaps.count == words.count - 1 else { return }

        /// The word index opening each laid-out line of the paragraph, or nil on a layout the model
        /// can't represent (a line starting mid-word).
        func lineStartWords() -> [Int]? {
            let content = NSRange(location: paragraph.location, length: contentEnd - paragraph.location)
            let paragraphGlyphs = manager.glyphRange(forCharacterRange: content, actualCharacterRange: nil)
            var starts: [Int] = []
            var wordCursor = 0
            var glyph = paragraphGlyphs.location
            while glyph < NSMaxRange(paragraphGlyphs) {
                var lineGlyphRange = NSRange()
                manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &lineGlyphRange)
                let charRange = manager.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
                glyph = NSMaxRange(lineGlyphRange)
                while wordCursor < words.count, words[wordCursor].location < charRange.location { wordCursor += 1 }
                guard wordCursor < words.count else { break }
                if starts.last == wordCursor { return nil }
                starts.append(wordCursor)
            }
            return starts.first == 0 ? starts : nil
        }

        guard let greedyStarts = lineStartWords(), greedyStarts.count > 1,
              words.count > greedyStarts.count else { return }
        let lineCount = greedyStarts.count


        // Already-even fast path, before any modeling: greedy fills every line but the last, so when
        // stretching the LAST line to the margin needs no more than a hair per gap, the paragraph is
        // already as even as its words allow - skip the model, the program and the probes outright.
        // One measurement decides it. (Marker-heavy lines read a little narrow standalone, which only
        // OVERSTATES the slack and falls through to the full pass - the safe direction.)
        let lastStart = greedyStarts[lineCount - 1]
        let lastContent = NSRange(location: words[lastStart].location,
                                  length: contentEnd - words[lastStart].location)
        let lastSlack = width - 1 - sub.attributedSubstring(from: lastContent).size().width
        if lastSlack / CGFloat(max(words.count - 1 - lastStart, 1)) <= 2.5 { return }

        // Measured advance width of every word: each word measured STANDALONE from its attributed
        // substring. Valid because a space breaks Arabic joining, so a word shapes identically alone
        // and in the line, and `size()` is typographic (advance-based) - the widths are additive.
        // (Measuring through the layout manager's boundingRect is NOT valid here: glyphs sit in visual
        // order inside an RTL line, so a logical word's glyph range spans most of the line's extent.)
        var wordWidths: [CGFloat] = []
        wordWidths.reserveCapacity(words.count)
        for word in words {
            let w = sub.attributedSubstring(from: word).size().width
            // A word as wide as the measure wraps mid-word - no gap model can place that; leave the
            // paragraph on its greedy breaks.
            guard w < width - 1 else { return }
            wordWidths.append(w)
        }
        // A gap's advance is its font's space plus the tracking already sitting on it (the page-wide
        // loosening) - a cache lookup and an attribute read, no typesetting. Measuring every gap in
        // context (word-gap-word pairs) came out identical to this sum on the shipped faces, so the
        // cheap model IS the accurate one; whatever in-context drift remains is the probe loop's job.
        var gapWidths: [CGFloat] = []
        gapWidths.reserveCapacity(gaps.count)
        for gap in gaps {
            var advance: CGFloat = 0
            for c in gap.location..<NSMaxRange(gap) {
                let font = (sub.attribute(.font, at: c, effectiveRange: nil) as? UIFont)
                    ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
                let tracking = (sub.attribute(.tracking, at: c, effectiveRange: nil) as? CGFloat) ?? 0
                advance += spaceAdvance(font) + tracking
            }
            gapWidths.append(advance)
        }

        // Prefix sums, so any candidate line's natural width is O(1).
        var prefixWord = [CGFloat](repeating: 0, count: words.count + 1)
        for k in 0..<words.count { prefixWord[k + 1] = prefixWord[k] + wordWidths[k] }
        var prefixGap = [CGFloat](repeating: 0, count: words.count)
        for k in 1..<words.count { prefixGap[k] = prefixGap[k - 1] + gapWidths[k - 1] }
        /// Natural (unwidened) width of a line holding words `a...b`.
        func natural(_ a: Int, _ b: Int) -> CGFloat {
            prefixWord[b + 1] - prefixWord[a] + (prefixGap[b] - prefixGap[a])
        }

        let n = words.count

        // A two-line paragraph (a surah's short tail on the page) reads best print-style, not evened
        // out: evening spreads BOTH lines' gaps wide - the same segment could read tight in one
        // riwayah and "exploded" in another whose slightly different word widths flipped the model's
        // optimum. Keep the first line as full as it fits, moving down only what the closing line
        // needs to hold something worth stretching (about a quarter measure of natural content -
        // greedy alone could strand a lone ayah marker at the margin). Longer paragraphs keep the
        // balancing model; across many lines the even spread is what makes the page look uniform.
        var overrideStarts: [Int]?
        if lineCount == 2 {
            // Fullest first line whose closing line still holds at least TWO tokens - one word plus
            // the ayah marker at minimum. That is the greedy (print-style) break in almost every
            // case; it only shifts a word down when greedy would strand the marker alone.
            var k = n - 1
            while k >= 2 {
                if natural(0, k - 1) <= width, n - k >= 2 {
                    overrideStarts = [0, k]
                    break
                }
                k -= 1
            }
            guard let printStyle = overrideStarts else { return }
            // Print-style only while the closing line still reads as a SET line. A short surah tail
            // (al-Kawthar's lone closing word plus its marker) left the closing line one word and its
            // marker, and the top-up then stretched that pair across the whole measure - a single
            // enormous gap, the exact unevenness this pass exists to remove. The limit is FONT-relative
            // (like the page-wide tracking ceiling), not measure-relative: whether a gap reads as a set
            // line depends on its size against the type, and a measure-relative cut both re-admitted
            // huge gaps on wide (iPad) measures and flipped fine print-style paragraphs to the balanced
            // model at large type on narrow ones. Roughly: more than ~1.25em of top-up per gap reads
            // as a hole, not a gap - hand the paragraph to the DP and both lines spread evenly.
            let tail = printStyle[1]
            let tailGaps = CGFloat(max(n - 1 - tail, 1))
            if max(width - 1 - natural(tail, n - 1), 0) / tailGaps > bodySize * 1.25 {
                overrideStarts = nil
            }
        }

        // The dynamic program: minimal summed squared per-gap widening over every way to set the first
        // `j` words in `k` lines. A line is admissible when it FITS (natural width within the same 1pt
        // guard the top-up keeps) - no upper cap on the widening: every line gets stretched to the
        // margin regardless, so the objective's whole job is to spread the sparseness as evenly as the
        // words allow instead of leaving it piled on the closing line.
        let balancedStarts: [Int]
        if let forced = overrideStarts {
            balancedStarts = forced
        } else {
        let columns = n + 1
        let unreachable = CGFloat.greatestFiniteMagnitude
        var cost = [CGFloat](repeating: unreachable, count: (lineCount + 1) * columns)
        var parent = [Int](repeating: 0, count: (lineCount + 1) * columns)
        cost[0] = 0
        for k in 1...lineCount {
            // Leave at least one word for every line still to come, and one for every line before.
            for j in k...(n - (lineCount - k)) {
                var a = j - 1
                while a >= k - 1 {
                    let lineNatural = natural(a, j - 1)
                    // Admit lines up to the FULL measure, not the top-up's 1pt guard: greedy lines sit
                    // flush against it, and refusing them over a sub-point model disagreement declared
                    // perfectly settable paragraphs unsolvable. The verification relayout is the
                    // arbiter of whether a chosen break truly holds.
                    if lineNatural > width { break }   // growing the line only overfills it further
                    // A line holding a single token has no gap to stretch - it can never reach
                    // the full measure, so it is not admissible (step #1: every line fills the
                    // whole space, no more, no less).
                    if j - a < 2 { a -= 1; continue }
                    if cost[(k - 1) * columns + a] < unreachable {
                        let gapCount = j - 1 - a
                        // What the top-up will widen each gap by once the line is stretched to the margin.
                        let widen = max(width - 1 - lineNatural, 0) / CGFloat(max(gapCount, 1))
                        let candidate = cost[(k - 1) * columns + a] + widen * widen
                        if candidate < cost[k * columns + j] {
                            cost[k * columns + j] = candidate
                            parent[k * columns + j] = a
                        }
                    }
                    a -= 1
                }
            }
        }
        // Unsolvable only when a single word can't fit a line (mid-word wraps) - keep the greedy
        // breaks; `spaceJustified` still stretches whatever lines have gaps.
        guard cost[lineCount * columns + n] < unreachable else { return }

        var starts = [Int](repeating: 0, count: lineCount)
        var wordEnd = n
        var lineIndex = lineCount
        while lineIndex > 0 {
            let a = parent[lineIndex * columns + wordEnd]
            starts[lineIndex - 1] = a
            wordEnd = a
            lineIndex -= 1
        }
        balancedStarts = starts
        }
        // Greedy already optimal: nothing to force, the top-up alone finishes the page.
        guard balancedStarts != greedyStarts else { return }

        // Force the chosen breaks: fill each line (except the last - that one is the top-up's) to just
        // short of the measure, so no following word can still fit on it. The headroom absorbs any
        // advance-rounding disagreement with TextKit while staying far narrower than any word; the
        // probe loop's surcharge below absorbs everything bigger.
        let baseTracking: [CGFloat] = gaps.map {
            (sub.attribute(.tracking, at: $0.location, effectiveRange: nil) as? CGFloat) ?? 0
        }
        func forcedWrites(headroom: CGFloat, surcharge: [CGFloat]) -> [(gap: Int, extra: CGFloat)] {
            var writes: [(gap: Int, extra: CGFloat)] = []
            for line in 0..<(lineCount - 1) {
                let a = balancedStarts[line]
                let b = balancedStarts[line + 1] - 1
                guard b > a else { continue }
                let extra = (width - headroom - natural(a, b) - surcharge[line]) / CGFloat(b - a)
                guard extra > 0 else { continue }   // already jammed against the measure - the break holds itself
                for g in a..<b { writes.append((gap: g, extra: extra)) }
            }
            return writes
        }
        // Absolute values (base + extra), so successive attempts overwrite instead of accumulating;
        // the extra goes on the gap run's FIRST character only - one advance bump per gap, exactly
        // what the model counted.
        func writeToStorage(_ writes: [(gap: Int, extra: CGFloat)]) {
            stack.storage.beginEditing()
            for g in gaps.indices {
                stack.storage.addAttribute(.tracking, value: baseTracking[g],
                                           range: NSRange(location: gaps[g].location, length: 1))
            }
            for write in writes {
                stack.storage.addAttribute(.tracking, value: baseTracking[write.gap] + write.extra,
                                           range: NSRange(location: gaps[write.gap].location, length: 1))
            }
            stack.storage.endEditing()
            manager.ensureLayout(for: stack.container)
        }

        // Probe with feedback. A line that comes back broken one word EARLY is truly wider in-context
        // than any standalone measurement of it (ayah markers and bidi digit runs lay out wider inside
        // a line than they measure alone), so that line earns a width surcharge - its fill backs off -
        // and the probe repeats. Backing off never costs fullness: the `spaceJustified` top-up works
        // from the line's real laid-out slack, so a backed-off line still ends flush at the margin.
        var winning: [(gap: Int, extra: CGFloat)]?
        var surcharge = [CGFloat](repeating: 0, count: max(lineCount - 1, 1))
        for _ in 0..<8 {
            let writes = forcedWrites(headroom: 2.0, surcharge: surcharge)
            writeToStorage(writes)
            guard let got = lineStartWords() else { break }
            if got == balancedStarts { winning = writes; break }
            // The first line START that diverges names the line above it as the mis-filled one.
            guard let i = (1..<min(got.count, lineCount)).first(where: { got[$0] != balancedStarts[$0] }) else { break }
            if got[i] < balancedStarts[i] {
                // Broke early: the line is wider than measured. Double the surcharge each round so a
                // large in-context divergence converges in a few probes.
                surcharge[i - 1] += max(surcharge[i - 1], 8)
            } else {
                // The next word came back UP: the line lays out NARROWER in context than its words
                // measure standalone, so its fill has to reach PAST the nominal measure - let the
                // surcharge go negative rather than give up. (Giving up here reverted the whole
                // paragraph to greedy breaks - the stranded two-word closing line stretched across
                // the full measure, the exact unevenness this pass exists to remove - and it hit
                // precisely the riwayat whose glyph metrics drift most from Hafs's.) The relayout
                // check above stays the arbiter, and the 8-round cap bounds any oscillation.
                surcharge[i - 1] -= 4
            }
        }
        guard let winning else {
            writeToStorage([])   // back to the greedy layout for any later paragraph in this segment
            return
        }

        // Commit to the page text with the same absolute values the verified layout used.
        for write in winning {
            pageText.addAttribute(.tracking, value: baseTracking[write.gap] + write.extra,
                                  range: NSRange(location: segment.location + gaps[write.gap].location, length: 1))
        }
    }

    private func height(of text: NSAttributedString, width: CGFloat) -> CGFloat {
        ceil(text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height)
    }

    /// Rendered height of the page at `size` and `width`. Colours don't affect layout, so the cheaper plain
    /// string is measured.
    func measuredHeight(size: CGFloat, width: CGFloat, extraLineSpacing: CGFloat = 0) -> CGFloat {
        height(of: attributed(size: size, colored: false, extraLineSpacing: extraLineSpacing).text, width: width)
    }

    /// The height an already-composed page actually lays out to, measured with the SAME TextKit stack the
    /// `UITextView` uses (a real `NSLayoutManager`, `lineFragmentPadding = 0`), rather than with
    /// `boundingRect`. The two disagree on justified right-to-left text that mixes fonts, and the text view
    /// clips anything past the height it was given - so this is what stops a dense page from silently losing
    /// its last line.
    static func layoutHeight(of text: NSAttributedString, width: CGFloat) -> CGFloat {
        // Bound as a whole: NSLayoutManager does not retain its NSTextStorage.
        let stack = layoutStack(for: text, width: width)
        return ceil(stack.manager.usedRect(for: stack.container).height)
    }

    /// How many lines the page wraps into at `size`. Needed to spread leftover height across the gaps between
    /// lines - see `MushafPageRenderCache`.
    func lineCount(size: CGFloat, width: CGFloat, tracking: CGFloat = 0) -> Int {
        let text = NSMutableAttributedString(attributedString: attributed(size: size, colored: false).text)
        if tracking > 0 { Self.addSpaceTracking(tracking, to: text) }
        // Bound as a whole: NSLayoutManager does not retain its NSTextStorage.
        let stack = Self.layoutStack(for: text, width: width)
        let manager = stack.manager

        var lines = 0
        var glyph = 0
        while glyph < manager.numberOfGlyphs {
            var lineRange = NSRange()
            manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &lineRange)
            glyph = NSMaxRange(lineRange)
            lines += 1
        }
        return lines
    }

    // MARK: Print-matched lines

    /// UTF-16 offsets at which each space-separated token of an ayah's composed text starts.
    static func tokenStarts(in string: NSString) -> [Int] {
        var starts: [Int] = []
        var inToken = false
        for i in 0..<string.length {
            let isSpace = string.character(at: i) == 0x20
            if !isSpace, !inToken { starts.append(i) }
            inToken = !isSpace
        }
        return starts
    }

    /// Turns each collected break character (always a word gap's space) into a LINE SEPARATOR
    /// (U+2028): TextKit breaks the line there but the segment stays ONE paragraph, so line
    /// spacing, the pinned line boxes, the forced baselines, the hit-test ranges and the
    /// justification all behave exactly as on a soft wrap - the character count never changes.
    /// Lines the print leaves short are tagged `mushafNaturalLine` so the margin top-up skips them.
    static func applyPrintBreaks(to text: NSMutableAttributedString, breaks: [(position: Int, full: Bool)],
                                 segment: NSRange, firstLineFull: Bool, closingComplete: Bool) {
        let string = text.string as NSString
        let sorted = breaks.filter { $0.position >= segment.location && $0.position < NSMaxRange(segment)
                                     && string.character(at: $0.position) == 0x20 }
                           .sorted { $0.position < $1.position }
        var lineStart = segment.location
        var lineFull = firstLineFull
        var lines: [(range: NSRange, full: Bool)] = []
        for brk in sorted {
            guard brk.position > lineStart else { continue }
            text.replaceCharacters(in: NSRange(location: brk.position, length: 1), with: "\u{2028}")
            lines.append((NSRange(location: lineStart, length: brk.position - lineStart), lineFull))
            lineStart = brk.position + 1
            lineFull = brk.full
        }
        lines.append((NSRange(location: lineStart, length: max(NSMaxRange(segment) - lineStart, 0)),
                      lineFull && closingComplete))
        for line in lines where !line.full && line.range.length > 0 {
            text.addAttribute(.mushafNaturalLine, value: true, range: line.range)
        }
    }

    /// Whether every printed line holds as ONE laid-out line: a right-aligned (body) fragment may
    /// only open at its paragraph's start or right after a line separator - anywhere else means a
    /// printed line was too wide for the measure at this size and wrapped.
    static func printLinesHold(text: NSAttributedString,
                               stack: (storage: NSTextStorage, manager: NSLayoutManager, container: NSTextContainer)) -> Bool {
        let manager = stack.manager
        let string = text.string as NSString
        var glyph = 0
        while glyph < manager.numberOfGlyphs {
            var lineGlyphRange = NSRange()
            manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &lineGlyphRange)
            let charRange = manager.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
            glyph = NSMaxRange(lineGlyphRange)
            guard charRange.length > 0, charRange.location > 0,
                  let style = text.attribute(.paragraphStyle, at: charRange.location, effectiveRange: nil) as? NSParagraphStyle,
                  style.alignment == .right else { continue }
            let before = string.character(at: charRange.location - 1)
            if before != 0x2028, before != 0x0A { return false }
        }
        return true
    }

    /// The widest printed line's natural width in a composed page, each line measured as the single run it is.
    static func widestPrintLine(in text: NSAttributedString) -> CGFloat {
        let string = text.string as NSString
        var widest: CGFloat = 0
        var cursor = 0
        while cursor < string.length {
            let paragraph = string.paragraphRange(for: NSRange(location: cursor, length: 0))
            cursor = max(NSMaxRange(paragraph), cursor + 1)
            guard paragraph.length > 0,
                  let style = text.attribute(.paragraphStyle, at: paragraph.location, effectiveRange: nil) as? NSParagraphStyle,
                  style.alignment == .right else { continue }
            var lineStart = paragraph.location
            for i in paragraph.location...NSMaxRange(paragraph) {
                let atEnd = i == NSMaxRange(paragraph)
                if atEnd || string.character(at: i) == 0x2028 {
                    var end = i
                    while end > lineStart, let scalar = Unicode.Scalar(string.character(at: end - 1)),
                          CharacterSet.whitespacesAndNewlines.contains(scalar) { end -= 1 }
                    if end > lineStart {
                        widest = max(widest, text.attributedSubstring(from: NSRange(location: lineStart, length: end - lineStart)).size().width)
                    }
                    lineStart = i + 1
                }
            }
        }
        return widest
    }

    #if DEBUG
    /// Layout passes spent by `printFittedSize`, for the audit's cost line (the fit is the prewarm's
    /// whole bill: a page composes and lays out once per pass).
    nonisolated(unsafe) static var printFitLayouts = 0
    #endif

    /// The fit for a print-matched page: the largest size at which the page's height fits the
    /// budget AND every printed line still holds as one line. Widths scale linearly with the size,
    /// so the widest line measured once at a reference size caps the search from above; the layout
    /// at that cap then either holds (the phone's usual case: done in two passes) or overflows the
    /// height, and since heights scale linearly too once every line holds, its ratio gives the
    /// height-bound size directly (the tablet's, and the 15-line prints' on a phone). Only when the
    /// real layout misses those estimates by a hair (markers and digit runs can set wider in context
    /// than they measure; headings don't scale exactly) does a search run, over the band just under
    /// the estimate - the old whole-range search paid fourteen passes on every height-bound page.
    private func printFittedSize(availableWidth: CGFloat, availableHeight: CGFloat) -> CGFloat {
        let floor: CGFloat = 9
        let reference: CGFloat = 20
        func rounded(_ size: CGFloat) -> CGFloat { (size * 100).rounded(.down) / 100 }
        func layout(_ size: CGFloat) -> (holds: Bool, height: CGFloat) {
            #if DEBUG
            Self.printFitLayouts += 1
            #endif
            let text = attributed(size: size, colored: false).text
            let stack = Self.layoutStack(for: text, width: availableWidth)
            let height = ceil(stack.manager.usedRect(for: stack.container).height)
            return (Self.printLinesHold(text: text, stack: stack), height)
        }
        func fits(_ size: CGFloat) -> Bool {
            let laid = layout(size)
            return laid.holds && laid.height <= availableHeight
        }

        var cap = fitCeiling
        let widest = Self.widestPrintLine(in: attributed(size: reference, colored: false).text)
        if widest > 0 {
            cap = min(cap, reference * (availableWidth - 2) / widest * 0.99)
        }
        cap = max(cap, floor)

        var hi = cap
        let atCap = layout(cap)
        if atCap.holds {
            if atCap.height <= availableHeight { return rounded(cap) }
            // Every line holds at the cap and only the height overflows: scale straight to it.
            hi = max(cap * availableHeight / atCap.height * 0.995, floor)
            if fits(hi) { return rounded(hi) }
        }
        // The estimate missed by a hair: search the band just under it, and the whole range only
        // if even that band's floor fails (never seen; kept so the fit can't return an overflow).
        var lo = max(hi * 0.85, floor)
        if !fits(lo) { lo = floor }
        for _ in 0..<8 {
            let mid = (lo + hi) / 2
            if fits(mid) { lo = mid } else { hi = mid }
        }
        return rounded(lo)
    }

    /// The largest size a mushaf page can be set at without overflowing.
    ///
    /// Practically UNCAPPED (user rule, restated hard: "MAXIMIZE the Arabic font, even for a 0.01pt
    /// difference - number one priority"). The old `min(fontSize * 2.5, 64)` ceiling existed so a short
    /// page wouldn't blow up; the height budget itself bounds every real page, so the only cap kept is
    /// an absurdity guard far above anything a phone page can actually fit.
    private var fitCeiling: CGFloat { 120 }

    /// The font size the page renders at. With "Fit Page to Screen" on, the page takes up as much of the height
    /// as it can WITHOUT overflowing - it grows into empty space as readily as it shrinks out of an overflow.
    /// (It used to search only *downwards* from the user's chosen size, so a page that had room to spare simply
    /// kept the small size and left the rest of the screen empty.) With the setting off, the chosen size stands.
    /// Adds `t` points of advance to every word gap in the running (right-aligned) text - headings and the
    /// centered opening spread keep their natural setting. The same targeting `spaceJustified` uses, so the
    /// two passes compose: this one loosens the whole page, that one tops each line up to the exact margin.
    static func addSpaceTracking(_ t: CGFloat, to text: NSMutableAttributedString) {
        let string = text.string as NSString
        for i in 0..<string.length where string.character(at: i) == 0x20 {
            let style = text.attribute(.paragraphStyle, at: i, effectiveRange: nil) as? NSParagraphStyle
            guard style?.alignment == .right else { continue }
            let existing = (text.attribute(.tracking, at: i, effectiveRange: nil) as? CGFloat) ?? 0
            text.addAttribute(.tracking, value: existing + t, range: NSRange(location: i, length: 1))
        }
    }

    /// Real laid-out height of the page with `tracking` on its word gaps.
    func balancedLayoutHeight(size: CGFloat, width: CGFloat, tracking: CGFloat, extraLineSpacing: CGFloat = 0) -> CGFloat {
        let text = NSMutableAttributedString(
            attributedString: attributed(size: size, colored: false, extraLineSpacing: extraLineSpacing).text
        )
        if tracking > 0 { Self.addSpaceTracking(tracking, to: text) }
        return Self.layoutHeight(of: text, width: width)
    }

    /// The page-wide word-gap loosening that fills the last line the way a real mushaf does. Fitting the font
    /// leaves the final line holding whatever words are left over - sometimes just two or three, which
    /// per-line justification could only stretch into a few enormous gaps. A typesetter fixes that by setting
    /// the WHOLE page a little looser, so each line carries one word fewer and the surplus cascades down into
    /// the last line. This finds the loosest such setting that still fits the height budget: word gaps grow
    /// uniformly, lines break earlier, the last line fills, and `spaceJustified` then tops every line up to
    /// the exact margins - moderate, even gaps everywhere instead of a sparse orphan line.
    func balancedSpaceTracking(size: CGFloat, width: CGFloat, budget: CGFloat) -> CGFloat {
        guard config.fitPage, !isEnglish, !usesSystemFont, !isOpeningSpread, !usesPrintLines else { return 0 }

        // Compose the page ONCE at this size: every probe below varies only the word-gap tracking attribute,
        // so re-composing the whole attributed page per bisection step (9 full composes per fit, times every
        // page in a prewarm ring) was the single biggest slice of the fit cost. Copy the base and re-track.
        let base = attributed(size: size, colored: false).text
        func heightWithTracking(_ tracking: CGFloat) -> CGFloat {
            let text = NSMutableAttributedString(attributedString: base)
            if tracking > 0 { Self.addSpaceTracking(tracking, to: text) }
            return Self.layoutHeight(of: text, width: width)
        }

        // A page missing less than a line and a half of fill reads best left tight: the line-spacing
        // settle and the centered band absorb the sliver. Cascading the whole page's word gaps to
        // chase a single line makes that page's setting visibly looser than its neighbours' (a hair
        // of per-riwayah text-width difference was enough to flip a page across this boundary).
        let natural = heightWithTracking(0)
        guard budget - natural >= lineBox(for: size) * 1.5 else { return 0 }

        // Loosening beyond this reads as broken setting, not justification. The old ceiling of 0.9x
        // the font size mattered on exactly the pages that hit it: non-Hafs riwayat hold the reader's
        // own size (`fitCeiling`), so any page their text leaves short by a few lines blew straight
        // past every reasonable value and landed at the ceiling - nearly a full em of extra advance
        // on EVERY word gap, the "huge word spacing" pages. At ~0.4x the gaps top out around two and
        // a half natural spaces - visibly loosened, still a set line; whatever height that can't
        // absorb stays as the quiet bottom band the centered layout and the line-spacing settle share.
        var lo: CGFloat = 0
        var hi = size * 0.4

        guard heightWithTracking(hi) > budget else { return hi }
        for _ in 0..<8 {
            let mid = (lo + hi) / 2
            if heightWithTracking(mid) <= budget {
                lo = mid
            } else {
                hi = mid
            }
        }
        return (lo * 20).rounded(.down) / 20
    }

    /// Where every line's baseline sits, measured from the top of its line fragment - the body face's own
    /// ascent, which is exactly where TextKit puts it on lines that contain only body text. Handed to the
    /// text view so ornament-carrying lines can't move it (see `MushafRenderedPage.baselineOffset`).
    /// When the line box is compressed (`lineBoxScale`), the baseline drops by half the overflow so the
    /// squeeze splits evenly between the ink above and below - each side leans into the neighbouring
    /// line's own air instead of one side taking the whole loss.
    func bodyBaselineOffset(size: CGFloat) -> CGFloat {
        let body = usesSystemFont ? UIFont.roundedSystemFont(ofSize: size) : arabicFont(size)
        let overflow = body.lineHeight - lineBox(for: size)
        return ceil(body.ascender - overflow / 2)
    }

    /// The fragment heights that count as "a running text line" - the pinned body box, alone or with the
    /// line spacing the paragraph adds, with a little tolerance for rounding. The baseline is forced only
    /// inside this band, so surah-heading lines (own smaller styles, natural heights) keep their own
    /// baselines instead of having the body's - which could sit below their whole fragment - imposed on them.
    func uniformLineFragmentBand(size: CGFloat, extraLineSpacing: CGFloat) -> ClosedRange<CGFloat> {
        let box = lineBox(for: size)
        let spacing = baseLineSpacing(for: size) + extraLineSpacing
        return (box - 2)...(box + spacing + 2)
    }

    func fittedSize(availableWidth: CGFloat, availableHeight: CGFloat) -> CGFloat {
        let base = config.fontSize
        guard config.fitPage, availableWidth > 1, availableHeight > 1 else { return base }

        let budget = availableHeight
        if usesPrintLines {
            return printFittedSize(availableWidth: availableWidth, availableHeight: budget)
        }

        // Binary-search on the fast `boundingRect` measurement, then ACCEPT on the real TextKit stack.
        // boundingRect and NSLayoutManager disagree by a few points on RTL text that mixes fonts, and every
        // point of disagreement used to be paid for twice: once as a slack constant reserved on every page
        // (shrinking pages that didn't need it - the "lost lines"), and once as clipping on the pages where
        // the constants weren't enough. Verifying the winner against the same layout the text view runs
        // makes the fit exact, so the slack constants are gone.
        let ceiling = fitCeiling
        var candidate = ceiling

        if measuredHeight(size: ceiling, width: availableWidth) > budget {
            // The floor is a legibility limit - a page that can't fit even at 9pt keeps 9pt and scrolls.
            var low: CGFloat = 9
            var high = ceiling
            // 14 iterations resolve the full 9…120 range to under 0.01pt - the user rule is that even a
            // hundredth of a point of font is worth taking.
            for _ in 0..<14 {
                let mid = (low + high) / 2
                if measuredHeight(size: mid, width: availableWidth) <= budget {
                    low = mid
                } else {
                    high = mid
                }
            }
            // Floored to a hundredth, not a half point: half a point of font across ~15 lines is a visibly
            // smaller page. Take every fraction we're entitled to.
            candidate = (low * 100).rounded(.down) / 100
        }

        // Exact acceptance: step down until the REAL layout fits. Usually zero or one step; bounded so a
        // pathological page degrades to the floor and scrolls rather than looping.
        while candidate > 9,
              Self.layoutHeight(of: attributed(size: candidate, colored: false).text, width: availableWidth) > budget {
            candidate = max(candidate - 0.5, 9)
        }

        // Then take back every fraction the coarse measurement gave away. `boundingRect` tends to
        // OVER-estimate against pinned line heights, so the search above settles small and the page wastes
        // its bottom - and stepping down can only ever shrink. Binary-search the REAL layout upward toward
        // the ceiling: the page ends at the biggest size that truly fits, down to the hundredth of a point
        // (14 iterations cover the full 9…120 range at that resolution - the maximize-font user rule).
        var lo = candidate
        var hi = ceiling
        if lo < hi {
            for _ in 0..<14 {
                let mid = (lo + hi) / 2
                if Self.layoutHeight(of: attributed(size: mid, colored: false).text, width: availableWidth) <= budget {
                    lo = mid
                } else {
                    hi = mid
                }
            }
        }
        return (lo * 100).rounded(.down) / 100
    }
}

/// One page, composed and measured. Reference type so it can live in an `NSCache`.
final class MushafRenderedPage {
    let fontSize: CGFloat
    let text: NSAttributedString
    let ranges: [MushafAyahRange]
    /// Exact laid-out height - this IS the text view's frame.
    let height: CGFloat
    /// Distance from a line fragment's top to its baseline, derived from the BODY font. The text view forces
    /// this on every running-text line: the paragraph style already pins the line BOX height, but TextKit
    /// still derives the baseline's position within the box from the tallest font on the line - so lines
    /// carrying an Uthmani ayah ornament (deep descender) sat their text visibly higher than their neighbours.
    let baselineOffset: CGFloat
    /// The fragment heights the forced baseline applies to - running text lines only, not headings.
    let baselineBand: ClosedRange<CGFloat>
    /// Set on the print's line breaks (`MushafPageComposer.usesPrintLines`): the page view sits such a
    /// page at the top of the screen, like the printed page it mirrors, instead of centering it.
    let printMatched: Bool

    init(fontSize: CGFloat, text: NSAttributedString, ranges: [MushafAyahRange], height: CGFloat,
         baselineOffset: CGFloat, baselineBand: ClosedRange<CGFloat>, printMatched: Bool = false) {
        self.fontSize = fontSize
        self.text = text
        self.ranges = ranges
        self.height = height
        self.baselineOffset = baselineOffset
        self.baselineBand = baselineBand
        self.printMatched = printMatched
    }
}

/// Composing a page is expensive - fitting it alone measures the whole page up to nine times - and SwiftUI
/// re-evaluates a page's body on every swipe (its own, and its two neighbours'). Doing that work on the main
/// thread mid-gesture is what made paging stutter. Keyed by page + geometry + everything that changes what is
/// drawn, so a page is composed once and every later visit is a dictionary hit.
@MainActor
enum MushafPageRenderCache {
    private static let cache: NSCache<NSString, MushafRenderedPage> = {
        let c = NSCache<NSString, MushafRenderedPage>()
        // Room for the live pages plus a radius-5 prewarm ring on both sides of them without self-eviction,
        // still cheap in memory (a rendered page is one attributed string). NSCache sheds under pressure anyway.
        c.countLimit = 48
        return c
    }()

    /// Everything that changes the rendering but isn't the page or the geometry.
    private static var settingsSignature: String {
        let s = Settings.shared
        return [
            s.fontArabic,
            // Was missing: `fontArabic` is only the reader's PICK (Uthmani/IndoPak/Basic) - which of the two
            // Uthmani faces actually draws the page is decided by the script style on top of it. Without this
            // the key never moved when Automatic -> Maghribi did, so every composed page kept its old face and
            // the setting looked dead. It appeared to work only when the riwayah changed too, because THAT
            // moved `displayQiraahForArabic` below and busted the key as a side effect.
            s.arabicScriptStyle.rawValue,
            // Full precision, matching the CGFloat the composer actually fits with (and the list-mode
            // signature). Truncating to Int would collide two fractional sizes onto one cache key.
            "\(s.fontArabicSize)",
            s.displayQiraahForArabic ?? "Hafs",
            s.showTajweedColors ? "t" : "-",
            // Per-category tajweed visibility. The master switch alone meant toggling a single legend
            // category kept serving already-composed pages with the old colors until cache eviction.
            s.tajweedCategoryVisibilitySignature,
            s.riwayahTajweedHiddenRules,
            // Toggling "Highlight Allah" repaints the composed page (red divine names), so it keys the cache.
            s.highlightAllahNames ? "h" : "-",
            s.showArabicText ? "a" : "-",
            s.cleanArabicText ? "c" : "-",
            // Was missing: toggling "Hide Arabic Dots" did not change the key, so every already-composed page
            // kept serving its dotted text until the 24-entry cache happened to evict it.
            s.removeArabicDots ? "d" : "-",
            s.beginnerMode ? "b" : "-",
            s.mushafFitPage ? "f" : "-",
            s.mushafPageLanguage,
            s.accentColor.rawValue,
            s.customAccentColorHex,
        ].joined(separator: "|")
    }

    /// The geometry the visible page was last laid out at, so neighbouring pages can be composed ahead of time
    /// without a `GeometryReader` of their own. Persisted so the NEXT launch can prewarm the last-read pages
    /// before the reader has ever been on screen - geometry only actually changes on rotation or a new device,
    /// so the persisted value is almost always exactly what the first render will ask for (and when it isn't,
    /// the misses were composed off-main and simply go unused).
    private static var lastGeometry: (width: CGFloat, height: CGFloat)? {
        didSet {
            guard let g = lastGeometry, g != (oldValue ?? (0, 0)) else { return }
            UserDefaults.standard.set([Double(g.width), Double(g.height)], forKey: geometryDefaultsKey)
            // Rotation / iPad split-resize / the bottom bars folding: every page in the prewarm ring
            // was fitted for the OLD geometry, so the first swipe in each direction landed on a cold
            // spinner (or the stale fallback). Re-warm the ring - but DEBOUNCED to the value that holds
            // still. An animated chrome fold sweeps the height through transient values frame by frame,
            // and sweeping the ring per transient didn't just churn the generation counter: a transient
            // fit that had already STARTED ran to completion and overwrote `latestByPage` with a render
            // fitted to a height the page never rests at, and THAT is what `nearestRendered` served on
            // the next swipe - the "bars are collapsed but the incoming page shows up sized for
            // uncollapsed, then grows" flash. Only a geometry that has held still for a beat may sweep.
            if oldValue != nil {
                geometrySettleWork?.cancel()
                let work = DispatchWorkItem {
                    guard let context = lastPrewarmContext else { return }
                    // Center included: a geometry change makes the VISIBLE page cold too, and its refit
                    // must lead the ring, not trail it.
                    prewarm(pages: context.pages, around: context.index, includeCenter: true)
                }
                geometrySettleWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
            }
        }
    }

    /// The pending settled-geometry ring sweep; every geometry change supersedes the last.
    private static var geometrySettleWork: DispatchWorkItem?

    /// What the most recent prewarm sweep covered, so a geometry change can re-run it unprompted.
    private static var lastPrewarmContext: (pages: [MushafPage], index: Int)?

    /// The geometry the next render will ask for. Callers composing PREDICTIVE fits snapshot this before
    /// transient chrome (the jump picker) shrinks the live geometry - the fits must match the height the
    /// page returns to once that chrome closes, or every predictive warm lands one refit short.
    static var currentGeometry: (width: CGFloat, height: CGFloat)? { lastGeometry }
    private static let geometryDefaultsKey = "mushaf.lastPageGeometry"

    private static var persistedGeometry: (width: CGFloat, height: CGFloat)? {
        guard let stored = UserDefaults.standard.array(forKey: geometryDefaultsKey) as? [Double],
              stored.count == 2, stored[0] > 1, stored[1] > 1 else { return nil }
        return (CGFloat(stored[0]), CGFloat(stored[1]))
    }

    /// The fit numbers for a page - everything the heavy passes produce. Computing these is ~12 full
    /// compose+layout passes and is PURE given a `MushafComposeConfig`, so the prewarm runs it off-main.
    private struct FitMetrics {
        let size: CGFloat
        let extraSpacing: CGFloat
        let measured: CGFloat
        /// Page-wide word-gap loosening that fills the last line - see `balancedSpaceTracking`.
        let spaceTracking: CGFloat
    }

    // MARK: Persistent fit metrics
    //
    // The fit numbers are a PURE function of (page, geometry, settings signature) - ~25-30 compose/measure
    // passes whose entire output is four floats - so a result computed on ANY previous launch is exactly
    // the result this launch would recompute. Persisting them turns every previously-fitted page's cold
    // path into just its final colored compose: cross-launch, the whole binary-search cost is paid once
    // per (page, geometry, settings) EVER instead of once per session.
    //
    // Keys are the render cache's own keys (they already encode all three inputs); the file additionally
    // carries a salt of app build + OS version, because a font, fitter-code, or TextKit change across
    // either could legitimately move the numbers - a stale file then misses wholesale instead of
    // mis-fitting pages. Lives in Caches (purgeable: losing it only costs recompute). Both fit lanes read
    // and record, so state is lock-guarded; saves are debounced onto a utility queue, one per burst.

    nonisolated(unsafe) private static var persistedMetricsEntries: [String: [Double]] = [:]
    nonisolated(unsafe) private static var persistedMetricsLoaded = false
    nonisolated(unsafe) private static var persistedMetricsDirty = false
    // `nonisolated` on the constants: the file builds under default MainActor isolation, and these are
    // read from the fit lanes - immutable Sendable values, so plain nonisolated (no `unsafe`) is exact.
    nonisolated private static let persistedMetricsLock = NSLock()
    nonisolated private static let persistedMetricsSaveQueue = DispatchQueue(label: "mushaf.fitmetrics.save", qos: .utility)
    /// Well past 604 pages × a handful of live signatures. A store this full is mostly dead signatures
    /// (old font sizes, old geometries); entries are so cheap to remake that starting over beats
    /// bookkeeping an eviction order.
    nonisolated private static let persistedMetricsLimit = 6000

    nonisolated private static var persistedMetricsURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("mushaf-fit-metrics.plist")
    }

    /// Bumped whenever the fit ALGORITHM itself changes (ceilings, tracking caps, balance rules):
    /// the persisted numbers are pure over (page, geometry, settings) only for a FIXED fitter, and
    /// the build number alone can't see a code change on a dev install that reuses its version.
    /// v3: uncapped fit ceiling (maximize-font user rule), 0.01pt search resolution, uncapped
    /// line-spacing spread (full vertical fill).
    // 6: Uthmani.ttf keeps ONLY the حۡمَٰنِ (Rahmaani) ligature removed - the other five dagger-alif
    // word bakes were restored (user: the non-ligated forms "look awful"), so those words' glyph
    // advances changed back and fits computed under v5 must recompute.
    // 9: fit measures Arabic pages with ZERO base line spacing (the leftover spread supplies the gaps
    // afterwards), the page margins tightened 20/6 -> 12/2, and the fitted Quranic-face line box
    // compressed to 0.90x natural (`lineBoxScale`), so every persisted size moves up.
    // 10: print-matched lines withdrawn (`MushafComposeConfig.printLines` is always nil). Every
    // page composes and fits the ordinary way again, so every fit persisted by a print-matched
    // build measured a page that no longer exists - those pages stood at half height.
    nonisolated private static let fitterVersion = 10

    nonisolated private static let persistedMetricsSalt: String = {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        // The bundled faces and text packs move the fit numbers WITHOUT a build bump (dev installs
        // patch fonts/packs in place under one CFBundleVersion) - and a stale store then serves fits
        // measured against outlines that no longer exist, pages standing short or overflowing until
        // eviction ("the page doesn't take full height"). Fingerprint their byte sizes so any font or
        // pack change misses the whole store instead. Sizes, not mtimes: reinstalls re-stamp every
        // file's date, and salting on that would discard the store on each dev build for nothing.
        let fm = FileManager.default
        // Solidpacks and loose deflates too, not just fonts and qpk: the beta qiraah TEXTS and the
        // riwayah page tables ship in those, and both move the fit (different words on a page, and
        // different ayahs on it). They were the one unfingerprinted input - a pack rebuild under an
        // unchanged CFBundleVersion kept serving fits measured against the old text.
        let fingerprint = ((Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
                           + (Bundle.main.urls(forResourcesWithExtension: "qpk", subdirectory: nil) ?? [])
                           + (Bundle.main.urls(forResourcesWithExtension: "solidpack", subdirectory: nil) ?? [])
                           + (Bundle.main.urls(forResourcesWithExtension: "deflate", subdirectory: nil) ?? [])
                           + (Bundle.main.urls(forResourcesWithExtension: "xz", subdirectory: nil) ?? []))
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url -> String? in
                guard let size = (try? fm.attributesOfItem(atPath: url.path))?[.size] as? NSNumber else { return nil }
                return "\(url.lastPathComponent):\(size.int64Value)"
            }
            .joined(separator: ",")
        return "f\(fitterVersion)|\(build)|\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)|\(fingerprint)"
    }()

    /// Callers hold `persistedMetricsLock`.
    nonisolated private static func loadPersistedMetricsIfNeeded_locked() {
        guard !persistedMetricsLoaded else { return }
        persistedMetricsLoaded = true
        guard let url = persistedMetricsURL,
              let data = try? Data(contentsOf: url),
              let raw = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any],
              raw["salt"] as? String == persistedMetricsSalt,
              let stored = raw["entries"] as? [String: [Double]] else { return }
        persistedMetricsEntries = stored
    }

    nonisolated private static func persistedMetrics(for key: String) -> FitMetrics? {
        persistedMetricsLock.lock()
        defer { persistedMetricsLock.unlock() }
        loadPersistedMetricsIfNeeded_locked()
        guard let v = persistedMetricsEntries[key], v.count == 4 else { return nil }
        return FitMetrics(size: CGFloat(v[0]), extraSpacing: CGFloat(v[1]),
                          measured: CGFloat(v[2]), spaceTracking: CGFloat(v[3]))
    }

    nonisolated private static func recordPersistedMetrics(_ metrics: FitMetrics, for key: String) {
        persistedMetricsLock.lock()
        loadPersistedMetricsIfNeeded_locked()
        if persistedMetricsEntries.count >= persistedMetricsLimit {
            persistedMetricsEntries.removeAll(keepingCapacity: false)
        }
        persistedMetricsEntries[key] = [Double(metrics.size), Double(metrics.extraSpacing),
                                        Double(metrics.measured), Double(metrics.spaceTracking)]
        let firstInBurst = !persistedMetricsDirty
        persistedMetricsDirty = true
        persistedMetricsLock.unlock()
        guard firstInBurst else { return }
        persistedMetricsSaveQueue.asyncAfter(deadline: .now() + 2) { savePersistedMetrics() }
    }

    nonisolated private static func savePersistedMetrics() {
        persistedMetricsLock.lock()
        persistedMetricsDirty = false
        let snapshot = persistedMetricsEntries
        persistedMetricsLock.unlock()
        guard let url = persistedMetricsURL,
              let data = try? PropertyListSerialization.data(
                fromPropertyList: ["salt": persistedMetricsSalt, "entries": snapshot],
                format: .binary, options: 0
              ) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// The persisted-metrics key: geometry plus ONLY the config that moves layout. Deliberately NOT the
    /// render cache key: that one also carries the colors (accent, tajweed painting), which repaint glyphs
    /// without moving them - the fit already banks on that, searching sizes on the UNCOLORED compose and
    /// rendering colored - so keying metrics per tint would discard every persisted fit on a retheme and
    /// fill the store with duplicate entries holding identical numbers. Complete by construction: the
    /// composer reads nothing but (page, config), so every layout input is a field here.
    /// Built from the immutable config snapshot, never Settings, so it is safe on the fit lanes.
    nonisolated private static func metricsKey(
        page: MushafPage, width: CGFloat, height: CGFloat, config: MushafComposeConfig
    ) -> String {
        [
            "\(page.page)", "\(Int(width.rounded()))", "\(Int(height.rounded()))",
            String(describing: config.pageLanguage),
            config.removeArabicDots ? "d" : "-",
            config.quranUsesSystemArabicFont ? "s" : "-",
            config.arabicFontName,
            config.displayQiraah ?? "Hafs",
            config.cleanArabicText ? "c" : "-",
            config.beginnerMode ? "b" : "-",
            // Per-ayah beginner overrides change the composed text, so they change the fit. Scoped to THIS
            // page's ayahs: a toggle elsewhere in the mushaf must not throw away this page's measured fit.
            AyahBeginnerOverrides.signature(config.beginnerAyahs, limitedTo: page.ayahRefs),
            "\(config.fontSize)",
            config.fitPage ? "f" : "-",
        ].joined(separator: "|")
    }

    /// The fit for this (page, geometry, config): the persisted numbers when any previous launch (or this
    /// one) already searched them out, else the full search - recorded so no launch pays for it again.
    nonisolated private static func fitMetricsUsingStore(
        composer: MushafPageComposer, width: CGFloat, height: CGFloat
    ) -> FitMetrics {
        let key = metricsKey(page: composer.page, width: width, height: height, config: composer.config)
        if let stored = persistedMetrics(for: key) { return stored }
        let metrics = fitMetrics(composer: composer, width: width, height: height)
        recordPersistedMetrics(metrics, for: key)
        return metrics
    }

    /// The serial queue the prewarm fits pages on. Serial on purpose: TextKit objects are safe off the main
    /// thread only when confined to one thread at a time, and a single lane keeps the background CPU cost
    /// bounded no matter how fast the user flips.
    private static let prewarmQueue = DispatchQueue(label: "mushaf.page.prewarm", qos: .userInitiated)

    /// The lane for the page the user is LOOKING AT. Its fit must never wait behind the ring: a cold jump,
    /// or a geometry settle right after the reader opens, used to enqueue the visible page's must-run fit
    /// LAST behind up to ten same-generation ring fits on the single serial queue - a many-second wait to
    /// see the page you're on (the "opens at half size, fixes itself ten seconds later" bug). Safe as a
    /// second lane: every fit builds its own TextKit stack inside its own block (nothing is shared between
    /// lanes), and `pendingRenders` - main-confined - already guarantees one fit per key ever runs.
    private static let visibleFitQueue = DispatchQueue(label: "mushaf.page.visiblefit", qos: .userInitiated)

    /// Compose the pages on either side of `index` before they're swiped to, so a page turn is a cache hit
    /// even the first time you reach it.
    ///
    /// The expensive part - fitting the font size, ~12 full compose+measure passes - runs on a background
    /// queue with a settings snapshot; only the final tajweed-colored compose (TajweedStore is main-thread
    /// state) and the cache insert hop back to main, one short block per page. The previous design ran the
    /// ENTIRE fit on the main thread (one page per runloop hop), and swiping faster than it drained meant
    /// the swipe itself paid for a cold page - the page-turn lag.
    private static var prewarmGeneration = 0

    /// Warm the last-read pages at app launch, before the reader has ever rendered - using the geometry
    /// persisted from the previous session. Includes the center page itself: nothing has rendered it yet,
    /// and it is precisely the page the reader will open on, the one cold fit the user actually feels.
    /// A tighter ring than the in-reader prewarm: at launch the win is the landing page and its immediate
    /// neighbours, not a deep flip run.
    static func prewarmAtLaunch(pages: [MushafPage], around index: Int) {
        if lastGeometry == nil { lastGeometry = persistedGeometry }
        prewarm(pages: pages, around: index, radius: 3, includeCenter: true)
    }

    /// Queue-confined mirror of `prewarmGeneration`: published onto the fit queue when a sweep starts, and
    /// read only there - so a queued ring fit can notice the user has swiped on BEFORE paying ~30 passes,
    /// without a cross-thread race on the main-thread counter. `nonisolated(unsafe)` because the safety
    /// invariant is the QUEUE (every touch happens on `prewarmQueue`), which the compiler can't see.
    nonisolated(unsafe) private static var queueGeneration = 0

    static func prewarm(pages: [MushafPage], around index: Int, radius: Int = 5, includeCenter: Bool = false,
                        at geometryOverride: (width: CGFloat, height: CGFloat)? = nil) {
        // `(1...radius)` below traps on a non-positive radius - guard it rather than trusting every caller.
        guard let geometry = geometryOverride ?? lastGeometry, !pages.isEmpty, radius >= 1,
              !isDegenerate(width: geometry.width, height: geometry.height) else { return }
        lastPrewarmContext = (pages, index)
        // The background fit is nearly free for the main thread, but each warmed page still costs a colored
        // compose on main - in Low Power Mode keep that to the immediate neighbours.
        let radius = AppPerformance.isLowPowerMode ? min(radius, 1) : radius

        prewarmGeneration &+= 1
        let generation = prewarmGeneration
        prewarmQueue.async { queueGeneration = generation }
        let config = MushafComposeConfig.current()
        let signature = settingsSignature

        // Nearest neighbours first (the pages a swipe reaches next), then the outer ring.
        let ordered = ((includeCenter ? [index] : []) + (1...radius).flatMap { [index + $0, index - $0] })
            .filter { pages.indices.contains($0) && (includeCenter || $0 != index) }

        for i in ordered {
            let page = pages[i]
            let key = cacheKey(page: page, width: geometry.width, height: geometry.height, signature: signature)
            // One fit per key, EVER in flight: overlapping rings used to re-enqueue duplicate fits for the
            // same pages because this check couldn't see queued work - the `pendingRenders` claim can.
            guard cache.object(forKey: key) == nil, pendingRenders[key] == nil else { continue }
            pendingRenders[key] = []
            enqueueFit(page: page, width: geometry.width, height: geometry.height,
                       key: key, config: config, generation: generation)
        }
    }

    /// The single fit executor shared by the prewarm ring and the visible page's `renderAsync`. Whoever asks
    /// first claims the key in `pendingRenders`; later askers attach a completion instead of re-fitting.
    ///
    /// Two rules fixed the page-flip churn that made swiping "lag like hell":
    /// 1. A COMPLETED fit is always cached. The key encodes page + geometry + settings, so a finished result
    ///    can never be wrong - the old code discarded any fit whose ring had been superseded by a newer
    ///    swipe, which during a flip run meant nothing ever landed and the queue refit the same pages
    ///    forever.
    /// 2. Staleness only skips fits that HAVEN'T STARTED (and only when no visible page is waiting on them):
    ///    a cheap early-exit, not thrown-away work.
    private static func enqueueFit(
        page: MushafPage,
        width: CGFloat,
        height: CGFloat,
        key: NSString,
        config: MushafComposeConfig,
        generation: Int?
    ) {
        // NSString isn't Sendable; the String bridge is - it crosses the queue hops and is re-wrapped
        // into an NSString cache key on the other side.
        let keyString = key as String
        // Must-run fits (generation nil - the user is looking at this page, or a waiter upgraded it) take
        // the visible lane; ring fits keep the prewarm lane. The generation-skip branch below only runs
        // for ring fits, so `queueGeneration`'s prewarm-queue confinement is preserved.
        let lane = generation == nil ? visibleFitQueue : prewarmQueue
        lane.async {
            // A ring fit from an abandoned sweep skips the expensive fit - unless the user has since landed
            // on this very page (a waiter attached), which upgrades it to must-run.
            if let generation, queueGeneration != generation {
                DispatchQueue.main.async {
                    let key = keyString as NSString
                    guard let waiters = pendingRenders[key] else { return }
                    if waiters.isEmpty {
                        pendingRenders.removeValue(forKey: key)
                        upgradedClaims.remove(key)
                    } else {
                        enqueueFit(page: page, width: width, height: height, key: key, config: config, generation: nil)
                    }
                }
                return
            }

            let composer = MushafPageComposer(page: page, config: config)
            let metrics = fitMetricsUsingStore(composer: composer, width: width, height: height)
            // The justification (segment layouts, break probes, margin top-ups) is the expensive half of
            // the final compose and depends on metrics only, never on colors - compute it HERE on the fit
            // lane so the main-thread tail is just the colored compose plus attribute transplants.
            let justification = composer.justification(size: metrics.size, extraLineSpacing: metrics.extraSpacing,
                                                       width: width, spaceTracking: metrics.spaceTracking)
            DispatchQueue.main.async {
                let key = keyString as NSString
                if cache.object(forKey: key) == nil {
                    let rendered = finalize(composer: composer, metrics: metrics, width: width,
                                            justification: justification)
                    cache.setObject(rendered, forKey: key)
                    noteLatest(page: page, width: width, budget: height, rendered: rendered)
                }
                upgradedClaims.remove(key)
                (pendingRenders.removeValue(forKey: key) ?? []).forEach { $0() }
            }
        }
    }

    #if DEBUG
    /// "-auditPrintLines": fit and compose every page on the current settings (print-matched lines
    /// expected on) at the last rendered geometry, and report each page whose printed lines don't
    /// all hold, whose break count differs from its table entries, or that overflows - plus the
    /// fitted size range, which is the number that decides whether the mode is readable on a phone.
    static func auditPrintLines(pages: [MushafPage]) {
        let geometry = currentGeometry ?? persistedGeometry ?? (width: 370, height: 700)
        let config = MushafComposeConfig.current()
        guard let table = config.printLines else {
            print("PRINT LINES AUDIT: no table for \(config.displayQiraah ?? "Hafs") (setting off, or pack missing)")
            return
        }
        print("PRINT LINES AUDIT: \(config.displayQiraah ?? "Hafs"), \(pages.count) pages, table \(table.lineCount) line starts, geometry \(Int(geometry.width))x\(Int(geometry.height))")
        var sizes: [CGFloat] = []
        var failures: [String] = []
        var breaksTotal = 0
        MushafPageComposer.printFitLayouts = 0
        for page in pages {
            let composer = MushafPageComposer(page: page, config: config)
            let metrics = fitMetrics(composer: composer, width: geometry.width, height: geometry.height)
            let text = composer.attributed(size: metrics.size, colored: false, extraLineSpacing: metrics.extraSpacing,
                                           width: geometry.width, spaceTracking: metrics.spaceTracking).text
            let stack = MushafPageComposer.layoutStack(for: text, width: geometry.width)
            let holds = MushafPageComposer.printLinesHold(text: text, stack: stack)
            let height = ceil(stack.manager.usedRect(for: stack.container).height)
            let string = text.string as NSString
            var breaks = 0
            for i in 0..<string.length where string.character(at: i) == 0x2028 { breaks += 1 }
            // Expected: every table start inside the page's ayahs, minus the one that opens each segment.
            var expected = 0
            for segment in page.segments {
                for (index, ayah) in segment.ayahs.enumerated() {
                    for start in table.starts(surah: segment.surah.id, ayah: ayah.id) ?? [] {
                        if start.offset == 0, index == 0 { continue }
                        expected += 1
                    }
                }
            }
            breaksTotal += breaks
            sizes.append(metrics.size)
            // The opening spread turns its last separator into a centered paragraph, so one break
            // less is exactly right there.
            let breaksMatch = breaks == expected || (page.page <= 2 && breaks == expected - 1)
            if !holds || !breaksMatch || height > geometry.height + 0.5 {
                failures.append("  page \(page.page): holds=\(holds) breaks=\(breaks)/\(expected) height=\(Int(height))/\(Int(geometry.height)) size=\(metrics.size)")
            }
        }
        let sorted = sizes.sorted()
        if !sorted.isEmpty {
            print(String(format: "PRINT LINES AUDIT: size min %.2f median %.2f max %.2f", sorted[0], sorted[sorted.count / 2], sorted[sorted.count - 1]))
        }
        print("PRINT LINES AUDIT: \(breaksTotal) breaks applied, \(failures.count) pages failing, \(MushafPageComposer.printFitLayouts) fit layout passes")
        failures.forEach { print($0) }
        print("PRINT LINES AUDIT: done")
        fflush(stdout)
    }
    #endif

    private static func cacheKey(page: MushafPage, width: CGFloat, height: CGFloat, signature: String) -> NSString {
        // Geometry is rounded so a sub-point layout jitter can't miss the cache on every frame.
        // The per-ayah beginner overrides join in PER PAGE rather than through `settingsSignature`: they
        // change the composed text, but toggling one ayah must only evict the page that ayah is on.
        let beginner = AyahBeginnerOverrides.signature(AyahBeginnerOverrides.shared.ayahs, limitedTo: page.ayahRefs)
        return "\(page.page)|\(Int(width.rounded()))|\(Int(height.rounded()))|\(signature)|\(beginner)" as NSString
    }

    /// The pure, heavy part: fit the size, spread the leftover height, measure. Runs on the prewarm queue
    /// for neighbours and inline on main for the visible page. `nonisolated`: it touches nothing of the
    /// main actor - the composer carries its own settings snapshot.
    private nonisolated static func fitMetrics(composer: MushafPageComposer, width: CGFloat, height: CGFloat) -> FitMetrics {
        let size = composer.fittedSize(availableWidth: width, availableHeight: height)

        // With the size fixed, loosen the whole page's word gaps until the leftover words cascade down and
        // fill the last line (mushaf behavior; see `balancedSpaceTracking`). All later measurements carry it,
        // because it moves the line breaks.
        let tracking = composer.balancedSpaceTracking(size: size, width: width, budget: height)

        // Real layout, not boundingRect: this number becomes the text view's frame, so it must be the height
        // the text view actually lays out to.
        var extraSpacing: CGFloat = 0
        var measured = composer.balancedLayoutHeight(size: size, width: width, tracking: tracking)

        // Sizing alone can never fill the page exactly: line wrapping is quantized, so one point more font
        // pushes a whole extra line and overflows. The leftover is spread across the line gaps so the text
        // SPANS THE FULL HEIGHT (user rule: after maximizing the font, take the whole vertical space - a
        // per-page rhythm difference is accepted for it; the old 0.2×size cap left a dead band instead).
        // English pages skip the spread entirely: prose reads on constant leading, and it was the English
        // pages where wandering spacing was most obvious.
        if composer.config.fitPage, !composer.config.pageLanguage.isEnglish, measured < height {
            let lines = composer.lineCount(size: size, width: width, tracking: tracking)
            if lines > 1 {
                // One point of the budget is deliberately left on the table: filling it EXACTLY, with
                // ceil-rounded layout heights on top, could land the final measure a fraction past the
                // budget - which flips the page into the scroll container and lets a fitted page be
                // dragged and rubber-banded (user rule: fit-to-page must never scroll).
                extraSpacing = max((height - measured - 1) / CGFloat(lines - 1), 0)
                // A print-matched page is sized by its widest printed LINE, so on a phone it is far
                // shorter than the screen; spreading all of that into the line gaps would float ten
                // lines across the height. Cap the pitch at the print's own (about 2.6x the size)
                // and leave the rest below, the way the printed page does.
                if composer.usesPrintLines {
                    extraSpacing = min(extraSpacing, max(2.6 * size - composer.lineBox(for: size), 0))
                }
                measured = composer.balancedLayoutHeight(
                    size: size, width: width, tracking: tracking, extraLineSpacing: extraSpacing
                )
            }
        }

        return FitMetrics(size: size, extraSpacing: extraSpacing, measured: measured, spaceTracking: tracking)
    }

    /// The main-thread tail: the tajweed-colored compose (TajweedStore has main-confined state), with the
    /// off-main justification transplanted onto it. The height comes from the justified plain compose,
    /// which lays out identically to the colored one (colors never move a glyph - the invariant the whole
    /// fit pipeline rests on): this number IS the text view's frame, and measuring anything else (or
    /// padding it "to be safe") either clips the last line or shrinks every page for slack it doesn't need.
    private static func finalize(composer: MushafPageComposer, metrics: FitMetrics, width: CGFloat,
                                 justification: (tracking: [(range: NSRange, value: CGFloat)], height: CGFloat)) -> MushafRenderedPage {
        let built = composer.attributed(size: metrics.size, extraLineSpacing: metrics.extraSpacing,
                                        width: width, justified: false)
        let text = NSMutableAttributedString(attributedString: built.text)
        for run in justification.tracking {
            text.addAttribute(.tracking, value: run.value, range: run.range)
        }

        return MushafRenderedPage(
            fontSize: metrics.size,
            text: text,
            ranges: built.ranges,
            height: justification.height,
            baselineOffset: composer.bodyBaselineOffset(size: metrics.size),
            baselineBand: composer.uniformLineFragmentBand(size: metrics.size, extraLineSpacing: metrics.extraSpacing),
            printMatched: composer.usesPrintLines
        )
    }

    /// Cache-only lookup for the render path: never fits inline. The old behavior - a cache miss running the
    /// full fit synchronously in `body` - was the swipe lurch: outrun the prewarm ring and the swipe itself
    /// paid ~30 compose/measure passes on the main thread. A miss now returns nil and the page shows its
    /// last-known render (or, truly cold, a brief spinner) while `renderAsync` fits on the prewarm queue.
    static func renderedIfAvailable(page: MushafPage, width: CGFloat, height: CGFloat) -> MushafRenderedPage? {
        // Never let a mid-transition collapsed frame become the prewarm seed: a ring swept at degenerate
        // geometry is 10+ wasted (or wedging) fits on the serial lane.
        if !isDegenerate(width: width, height: height) { lastGeometry = (width, height) }
        // One signature build per call: this runs per mounted page per body pass (and the pager re-evals
        // on every playback tick), and it used to be rebuilt again inside noteLatest.
        let signature = settingsSignature
        let hit = cache.object(forKey: cacheKey(page: page, width: width, height: height, signature: signature))
        if let hit { noteLatest(page: page, width: width, budget: height, rendered: hit, signature: signature) }
        return hit
    }

    /// The most recent render each page produced or served, by page number. The HEIGHT budget jitters
    /// constantly (a bar appears, the mini player mounts, a transition mid-flight), and every jitter is
    /// a new cache key; without this map each jitter flashed the loading spinner over a page that was
    /// JUST on screen. Held STRONGLY but tightly bounded at 12 - the mounted pages plus their immediate
    /// ring, which is all the fallback exists for. (Weak references were tried and reverted: NSCache
    /// count-limit churn during an ordinary flip run evicted a mounted page's older-height render while
    /// it was still the only fallback for the next jitter - the spinner came back. Twelve attributed
    /// pages is small; the old bound of 64 was what undercut memory-pressure eviction.)
    private static var latestByPage: [Int: (width: CGFloat, budget: CGFloat, signature: String, rendered: MushafRenderedPage)] = [:]
    /// Insertion order for eviction, oldest first.
    private static var latestOrder: [Int] = []
    private static let latestLimit = 12

    private static func noteLatest(page: MushafPage, width: CGFloat, budget: CGFloat, rendered: MushafRenderedPage, signature: String? = nil) {
        let signature = signature ?? settingsSignature
        if latestByPage[page.page] != nil {
            latestOrder.removeAll { $0 == page.page }
        }
        latestByPage[page.page] = (width, budget, signature, rendered)
        latestOrder.append(page.page)
        while latestOrder.count > latestLimit {
            let evicted = latestOrder.removeFirst()
            latestByPage.removeValue(forKey: evicted)
        }
    }

    /// A same-page render fitted for a DIFFERENT height budget - shown in place of the spinner while the
    /// exact fit runs. Same width and same settings only: the text re-wraps identically at the same width
    /// (so nothing clips), while a different width or changed settings would show genuinely wrong content.
    ///
    /// Close-enough budgets only. The fallback exists for height jitters (a bar mounting, the mini
    /// player appearing) AND the bottom-chrome collapse, whose band is up to ~40% of the page - the
    /// old 30%-of-new-height bound refused the collapse jump, so toggling the chevron flashed the
    /// spinner over a page that was JUST on screen (user report). The reader's FIRST layout pass
    /// mid-launch can still report around half the final height, and serving that fit showed a
    /// visibly shrunken page squatting in half the screen - so the bound stays, measured against the
    /// LARGER of the two budgets (collapse: ~38%, accepted; mid-launch: ~50%, still refused) and only
    /// a budget that far off gets the honest spinner. The refit itself is fast (see `visibleFitQueue`).
    static func nearestRendered(page: MushafPage, width: CGFloat, height: CGFloat) -> MushafRenderedPage? {
        guard let entry = latestByPage[page.page],
              Int(entry.width.rounded()) == Int(width.rounded()),
              entry.signature == settingsSignature,
              abs(entry.budget - height) <= max(entry.budget, height) * 0.45 else { return nil }
        return entry.rendered
    }

    /// In-flight async renders, keyed like the cache, each holding the completions to run when it lands -
    /// re-evaluations of a waiting page's body pile onto the same render instead of starting another.
    private static var pendingRenders: [NSString: [() -> Void]] = [:]
    /// Claims that already got their one visible-lane duplicate (see `renderAsync`).
    private static var upgradedClaims: Set<NSString> = []

    /// Fit + compose off-main, store, then tell every waiting page to re-read the cache. If the prewarm ring
    /// already queued this page's fit, the completion just attaches to it - one fit per key, ever.
    /// Geometry a real reader can never have. Mid-navigation (a pop, a search-result push) SwiftUI can
    /// report a collapsed frame for a beat; fitting a page into it is at best wasted ~30 passes and at
    /// worst a degenerate fit that wedges the serial fit lane - after which every later page waits behind
    /// it forever (the "spins forever after going back / tapping a search result" hang). The `.task(id:)`
    /// on the spinner re-fires when the geometry becomes real, so refusing here loses nothing.
    private static func isDegenerate(width: CGFloat, height: CGFloat) -> Bool {
        width < 80 || height < 160
    }

    static func renderAsync(page: MushafPage, width: CGFloat, height: CGFloat, onReady: @escaping () -> Void) {
        guard !isDegenerate(width: width, height: height) else { return }
        let key = cacheKey(page: page, width: width, height: height, signature: settingsSignature)
        if cache.object(forKey: key) != nil { onReady(); return }

        if pendingRenders[key] != nil {
            pendingRenders[key]?.append(onReady)
            // The claim may belong to a ring fit queued deep in the serial prewarm lane (or behind a
            // wedged one). The user is LOOKING at this page: enqueue ONE must-run duplicate on the
            // visible lane rather than waiting our turn. Safe: the completion path stores only if the
            // cache is still empty and flushing waiters removes the key once - the loser's main-hop is
            // a no-op. `upgradedClaims` bounds it to one duplicate per claim, not one per body pass.
            if upgradedClaims.insert(key).inserted {
                enqueueFit(page: page, width: width, height: height,
                           key: key, config: MushafComposeConfig.current(), generation: nil)
            }
            return
        }
        pendingRenders[key] = [onReady]

        // generation nil = must-run: the user is looking at this page.
        enqueueFit(page: page, width: width, height: height,
                   key: key, config: MushafComposeConfig.current(), generation: nil)
    }

    // (The old synchronous `rendered(page:width:height:)` - a cold visible page paying the full fit inline
    // on the main thread - is gone: every render path now goes through `renderedIfAvailable`/`renderAsync`,
    // and keeping an unused main-thread full-fit entry point around invites exactly the freeze it caused.)
}

/// The composed page in a non-scrolling `UITextView`. A merged SwiftUI `Text` can't hit-test an individual
/// run, so the mushaf page uses UIKit and maps a tap to the ayah whose range contains the tapped character.
extension AyahHighlightColor {
    /// The page wash as a DYNAMIC UIColor. The alpha has to differ between light and dark (the same hue is
    /// invisible on the dark page at the light theme's weight), and a dynamic color lets TextKit resolve it
    /// against the text view's own traits - so a theme switch repaints the page for free, without the
    /// composed-page cache key having to carry the color scheme.
    /// Built once per color, not once per wash: `updateUIView` resolves this for every highlighted ayah
    /// on the page, on every page update, and a dynamic UIColor allocates a closure box each time.
    private static var pageWashCache: [AyahHighlightColor: UIColor] = [:]

    var pageWashUIColor: UIColor {
        if let cached = Self.pageWashCache[self] { return cached }
        let base = UIColor(color)
        // Kept in step with `tintOpacity` (the list rows' wash): the highlight is a standing margin
        // note, deliberately faint (user rule: "make highlighting opacity wayyy less").
        let wash = UIColor { traits in
            base.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.14 : 0.10)
        }
        Self.pageWashCache[self] = wash
        return wash
    }
}

/// The scroll view hosting a composed mushaf page. UIScrollView never lays out its content on its own, so
/// this keeps the text view pinned to the box SwiftUI gives the page - and resets the zoom whenever that
/// box changes size (a rotation, a bars-fold): the page refits to the new box anyway, so a held-over
/// magnification would be anchored to a layout that no longer exists.
final class PageZoomScrollView: UIScrollView {
    weak var pageView: UIView?
    private var lastSize: CGSize = .zero

    /// Posted by the reader on every page turn: a zoomed-in page resets to its fitted view the
    /// moment you leave it, exactly as the facsimile does - coming back always lands on the fit.
    static let resetZoomNotification = Notification.Name("MushafPageResetZoom")

    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(resetZoomToFit),
                                               name: Self.resetZoomNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(resetZoomToFit),
                                               name: Self.resetZoomNotification, object: nil)
    }

    @objc private func resetZoomToFit() {
        guard zoomScale != 1 else { return }
        setZoomScale(1, animated: false)
        setContentOffset(.zero, animated: false)
        bounces = false
        clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let pageView, bounds.size != lastSize else { return }
        lastSize = bounds.size
        if zoomScale != 1 {
            setZoomScale(1, animated: false)
            bounces = false
            clipsToBounds = false
        }
        pageView.frame = CGRect(origin: .zero, size: bounds.size)
        contentSize = bounds.size
    }
}

struct MushafPageTextView: UIViewRepresentable {
    let attributed: NSAttributedString
    let ranges: [MushafAyahRange]
    /// The wrap width. A non-scrolling `UITextView` whose text container isn't pinned to a width lays the
    /// whole page out on ONE infinitely-wide line (SwiftUI then sizes it from that intrinsic width), so the
    /// container width must be set explicitly - this is what makes the page wrap into lines at all.
    let width: CGFloat
    /// The ayah currently being recited, if it is on this page.
    /// The ayah being recited, if it is on this page - tinted in the accent.
    var highlight: (surahID: Int, ayahID: Int)?
    var highlightColor: Color = .accentColor
    /// The surah currently loaded in the player, if any: its heading NAME (not the bismillah) carries the
    /// accent tint while it plays, so the page shows which surah the recitation belongs to.
    var playingSurahID: Int? = nil
    /// The ayah the reader marked by tapping it - tinted grey, and independent of the recitation highlight so
    /// both can be on screen at once.
    var mark: (surahID: Int, ayahID: Int)?
    /// A search-arrival term: the matched substrings WITHIN the given ayah render in the accent color -
    /// the page-mode equivalent of the list's HighlightedSnippet coloring.
    var termHighlight: (surahID: Int, ayahID: Int, term: String)? = nil
    /// The in-page find, while its query is live: EVERY matching ayah gets its matched substrings in the
    /// accent, and the WHOLE page drops its tajweed colors so the matches are the only color on it - the
    /// page-mode twin of how matched list rows render (accent snippet, tajweed off).
    var searchHighlight: (matches: [(surahID: Int, ayahID: Int)], term: String)? = nil
    /// Multi-select: every listed ayah carries the accent selection tint.
    var selected: [(surahID: Int, ayahID: Int)] = []
    /// Bookmarked ayahs on this page: each gets a small bookmark glyph drawn just ABOVE its number ornament,
    /// so page mode shows the same "this one is saved" mark the list rows do (user rule). Drawn as an overlay
    /// subview rather than as text: the fit/justification pipeline composes the page PLAIN and transplants
    /// its tracking runs onto the colored compose BY CHARACTER INDEX, so inserting so much as one glyph into
    /// the colored pass would slide every index after it out of alignment.
    /// `highlight` is the highlighter's color when the bookmark carries one: it paints the badge AND washes
    /// the ayah's range on the page, so the mark you left in the list reader is the same mark you see here.
    var bookmarked: [(surahID: Int, ayahID: Int, highlight: AyahHighlightColor?)] = []
    /// Forced distance from each line fragment's top to its baseline - see `MushafRenderedPage.baselineOffset`.
    var baselineOffset: CGFloat = 0
    /// Fragment heights the forced baseline applies to (running text lines, not headings).
    var baselineBand: ClosedRange<CGFloat> = 0...0
    /// PDF-style zoom (user rule: "text page zoom in and out should be the same as PDF"): pinch zooms the
    /// page in and it STAYS zoomed, pan moves around it, and pinching back out stops at the fitted page -
    /// the fit is the maximum zoom-out, exactly like the facsimile. On only for the fitted page; a page
    /// that overflows into a scroll container keeps the old transient magnifier instead (a persistent
    /// zoom inside a vertical scroller fights its pan).
    var zoomsLikePDF: Bool = false
    let onTapAyah: (Int, Int) -> Void
    let onLongPressAyah: (Int, Int) -> Void
    /// A tap on a surah heading (name/basmala) - passes the surah's id.
    var onTapHeading: ((Int) -> Void)? = nil
    /// A DOUBLE tap on a word: (surahID, ayahID, word index over whitespace-split tokens of the
    /// ayah's composed text - the same splitting `WordTokens.tokens` uses). The single-tap
    /// recognizer deliberately does NOT wait for this one to fail: a double tap toggles the ayah
    /// mark twice (a visual no-op) and then opens the word card, which keeps single taps instant.
    var onDoubleTapWord: ((Int, Int, Int) -> Void)? = nil

    private func range(of ayah: (surahID: Int, ayahID: Int)?) -> NSRange? {
        guard let ayah else { return nil }
        return ranges.first { $0.surahID == ayah.surahID && $0.ayahID == ayah.ayahID }?.range
    }

    /// The tints are painted on top of the cached, composed page rather than recomposing it - a background
    /// attribute doesn't change layout, so nothing has to be re-measured as playback moves down the page.
    private func highlighted(_ text: NSAttributedString) -> NSAttributedString {
        var tints: [(NSRange, Color)] = [
            (range(of: mark), Color.secondary),
            (range(of: highlight), highlightColor),
        ].compactMap { r, color in r.map { ($0, color) } }

        // Multi-select: every selected ayah carries the accent tint.
        for ayah in selected {
            if let r = range(of: ayah) {
                tints.append((r, highlightColor))
            }
        }

        // The playing surah's heading NAME (never the bismillah - the composer records the name as its own
        // subrange) lights up while that surah is loaded in the player.
        if let playingSurahID, let nameRange = range(of: (playingSurahID, MushafAyahRange.surahNameID)) {
            tints.append((nameRange, highlightColor))
        }

        // The search-arrival snippet: the matched substrings inside the target ayah, in accent FOREGROUND -
        // the page-mode twin of the list's HighlightedSnippet coloring. ONLY a substring that is actually
        // present in the text THIS page shows gets colored. When the term matched through something the
        // page isn't showing (an English query that hit the translation while the page shows Arabic, or a
        // DIFFERENT English translation than the one on the page), there is nothing here to color - so we
        // color nothing. Painting the whole ayah in that case was the "it highlights the whole ayah instead
        // of just the word" bug; the arrival already grey-marks the ayah, so the reader still sees where
        // they landed.
        let termTarget: (ayahRange: NSRange, matches: [NSRange])? = {
            guard let termHighlight,
                  let ayahRange = range(of: (termHighlight.surahID, termHighlight.ayahID)) else { return nil }
            let exact = Self.matchRanges(of: termHighlight.term, in: text.string, within: ayahRange)
            guard !exact.isEmpty else { return nil }
            return (ayahRange, exact)
        }()

        // The in-page find: the matched substrings for every matching ayah whose match is ON this page.
        // Same rule as the arrival term - an ayah that matched through a script/translation the page isn't
        // showing has no substring here, so it is dropped rather than washed whole (its current-match
        // position is grey-marked separately via `highlightedAyah`).
        let searchTerm = searchHighlight?.term.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let searchIsActive = searchHighlight != nil && !searchTerm.isEmpty
        let searchTargets: [(ayahRange: NSRange, matches: [NSRange])] = {
            guard searchIsActive, let searchHighlight else { return [] }
            return searchHighlight.matches.compactMap { match in
                guard let ayahRange = range(of: (match.surahID, match.ayahID)) else { return nil }
                let exact = Self.matchRanges(of: searchTerm, in: text.string, within: ayahRange)
                guard !exact.isEmpty else { return nil }
                return (ayahRange, exact)
            }
        }()

        // The highlighter's standing washes, resolved before the momentary tints so those paint OVER them:
        // the reciting/marked/selected tint has to win on the ayah it is on, exactly as it does in the list
        // reader, and the highlight comes back when it moves away.
        let highlightWashes: [(NSRange, UIColor)] = bookmarked.compactMap { ref in
            guard let color = ref.highlight,
                  let range = range(of: (ref.surahID, ref.ayahID)) else { return nil }
            return (range, color.pageWashUIColor)
        }

        guard !tints.isEmpty || !highlightWashes.isEmpty || termTarget != nil || searchIsActive else { return text }

        let mutable = NSMutableAttributedString(attributedString: text)
        for (range, color) in highlightWashes {
            mutable.addAttribute(.backgroundColor, value: color, range: range)
        }
        for (range, color) in tints {
            mutable.addAttribute(.backgroundColor, value: UIColor(color).withAlphaComponent(0.22), range: range)
        }
        // Only when at least one match is actually located ON this page: flatten the page's tajweed to the
        // label color (headings keep their own styling; `> 0` skips the name-only subranges so the heading
        // accent survives) so the accent matches are the only color, exactly like the list's matched rows.
        // If nothing on this page matches (the query hit a script/translation the page isn't showing), the
        // page is left untouched rather than flattened to a plain grey slab with nothing lit.
        if searchIsActive, !searchTargets.isEmpty {
            for entry in ranges where entry.ayahID > 0 && NSMaxRange(entry.range) <= mutable.length {
                mutable.addAttribute(.foregroundColor, value: UIColor.label, range: entry.range)
            }
            for target in searchTargets {
                for range in target.matches {
                    mutable.addAttribute(.foregroundColor, value: UIColor(highlightColor), range: range)
                }
            }
        }
        if let termTarget {
            // The matched ayah drops its tajweed colors while the match is lit - exactly like the list's
            // matched rows - otherwise the accent snippet disappears into the rainbow of rule colors.
            // `termTarget` only exists when a substring was actually located, so this never fires on a
            // cross-translation miss.
            mutable.addAttribute(.foregroundColor, value: UIColor.label, range: termTarget.ayahRange)
            for range in termTarget.matches {
                mutable.addAttribute(.foregroundColor, value: UIColor(highlightColor), range: range)
            }
        }
        // Whatever a flatten just grayed out, the ayah-number ornaments stay accent - the list rows always
        // show them colored. `UIColor(highlightColor)` is the exact color the composer painted them
        // (`config.accent`), so this restores, not recolors; it's a no-op for markers never flattened.
        if (searchIsActive && !searchTargets.isEmpty) || termTarget != nil {
            for entry in ranges where entry.ayahID == MushafAyahRange.ayahMarkerID
                && NSMaxRange(entry.range) <= mutable.length {
                mutable.addAttribute(.foregroundColor, value: UIColor(highlightColor), range: entry.range)
            }
        }
        return mutable
    }

    /// Where `term` matches inside `ayahRange` of the page's plain text - using the EXACT SAME range ladder
    /// the list snippet uses (`HighlightedSnippet.matchRanges`: exact normalized substring → Arabic
    /// alef-insensitive skeleton → phrase-prefix), so a real match colors its word in page mode exactly as
    /// it does in the list. `guaranteeMatch` is deliberately OFF: a term that genuinely isn't on the text
    /// this page shows (an English query while the page shows Arabic, or a different translation) yields
    /// no ranges - the caller then leaves the ayah un-painted (just the arrival mark), instead of the old
    /// whole-ayah wash.
    static func matchRanges(of term: String, in fullText: String, within ayahRange: NSRange) -> [NSRange] {
        let full = fullText as NSString
        guard ayahRange.location >= 0, ayahRange.location + ayahRange.length <= full.length else { return [] }
        // A print-matched page carries its line breaks as U+2028 in place of word spaces; fold them
        // back so a phrase that straddles a printed line still matches. Same UTF-16 length, so the
        // ranges below stay exact.
        let ayahText = full.substring(with: ayahRange).replacingOccurrences(of: "\u{2028}", with: " ")

        return HighlightedSnippet.matchRanges(of: term, in: ayahText).map { range in
            // `range` is into `ayahText`; convert to a UTF-16 NSRange there, then shift by the ayah's
            // offset within the whole page (both are UTF-16 offsets, so the shift is exact).
            let local = NSRange(range, in: ayahText)
            return NSRange(location: ayahRange.location + local.location, length: local.length)
        }
    }

    func makeUIView(context: Context) -> UIScrollView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.isScrollEnabled = false
        // Never scrolls (above), so it doesn't need to clip - and it must not: a justified line ends flush
        // at the margin, and the tashkeel ink of a line's last letter routinely overhangs its glyph advance.
        // Clipping sheared those marks at the container edge; letting them draw a few points into the page's
        // horizontal padding is exactly what the padding is for.
        tv.clipsToBounds = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.adjustsFontForContentSizeCategory = false
        tv.textContainer.widthTracksTextView = false
        tv.textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
        // Don't let the text view's (single-line) intrinsic width fight the SwiftUI frame.
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Touch the TextKit-1 layout manager so hit-testing is consistent on iOS 16+ (which defaults to TextKit 2).
        // The delegate is what holds every line's baseline at the body font's position - without it, a line
        // carrying an Uthmani ayah ornament derives its baseline from the ornament font's deeper metrics and
        // its text rides visibly higher than the lines around it.
        tv.layoutManager.delegate = context.coordinator

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tv.addGestureRecognizer(tap)

        // Double tap on a word opens its meaning card (user rule: page mode should offer the word
        // check too). No `tap.require(toFail:)` on purpose - see `onDoubleTapWord`.
        if onDoubleTapWord != nil {
            let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                                   action: #selector(Coordinator.handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            tv.addGestureRecognizer(doubleTap)
        }

        // A tap only marks an ayah; the actions sheet is the deliberate gesture, so it takes a press. The tap
        // must not also fire when the press wins, hence the dependency.
        let press = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        tv.addGestureRecognizer(press)
        tap.require(toFail: press)

        // A pointer's secondary (right / two-finger) click - on a Mac running the app as Designed for iPad,
        // or an iPad trackpad - is the natural "act on this ayah" gesture, so it opens the same actions
        // sheet as the long press without the hold. Touches never carry the secondary button, so this
        // recognizer is inert on iPhone/iPad touch input (the plain tap above stays primary-only).
        let secondaryClick = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSecondaryClick(_:))
        )
        secondaryClick.buttonMaskRequired = .secondary
        // Pointer input ONLY: without this, direct touches can satisfy the recognizer too (the
        // button mask alone does not exclude them on every OS), so a plain fingertip tap opened
        // the actions sheet alongside its selection. Finger taps must select; only a real
        // right/two-finger CLICK (Mac, iPad trackpad) opens the sheet without a hold.
        secondaryClick.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        tv.addGestureRecognizer(secondaryClick)

        if !zoomsLikePDF {
            // The overflowing page keeps the old transient magnifier: the text scales around the fingers
            // and springs back when they lift. A persistent zoom would fight the surrounding vertical
            // scroll container's pan, so it is reserved for the fitted page below.
            let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                                 action: #selector(Coordinator.handlePinch(_:)))
            tv.addGestureRecognizer(pinch)
        }

        // The page always ships inside a scroll view; on the fitted page it IS the zoomer (PDF-style
        // persistent pinch zoom), on an overflowing page it is inert (no scroll, no zoom) and just holds
        // the text view for the SwiftUI scroll container around it.
        let scroll = PageZoomScrollView()
        scroll.pageView = tv
        scroll.backgroundColor = .clear
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.delegate = context.coordinator
        scroll.clipsToBounds = false
        scroll.minimumZoomScale = 1
        if zoomsLikePDF {
            scroll.maximumZoomScale = 5
            scroll.bouncesZoom = true
            // No give at rest: the fitted page must never rubber-band (user rule). Panning while
            // zoomed re-enables the bounce, and clipping turns on only while zoomed too (at rest the
            // page's overhanging tashkeel ink must keep drawing into the horizontal padding - see
            // `tv.clipsToBounds` above) - both in `scrollViewDidZoom`.
            scroll.bounces = false
        } else {
            scroll.maximumZoomScale = 1
            scroll.isScrollEnabled = false
        }
        scroll.addSubview(tv)

        context.coordinator.textView = tv
        context.coordinator.scrollView = scroll
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        guard let tv = context.coordinator.textView else { return }
        context.coordinator.ranges = ranges
        context.coordinator.onTapAyah = onTapAyah
        context.coordinator.onLongPressAyah = onLongPressAyah
        context.coordinator.onTapHeading = onTapHeading
        context.coordinator.onDoubleTapWord = onDoubleTapWord
        // Before any text assignment below, so the relayout it triggers already sees the new values.
        context.coordinator.forcedBaselineOffset = baselineOffset
        context.coordinator.baselineBand = baselineBand

        // Reassigning `attributedText` forces a full TextKit relayout of the page. This view's parent observes
        // the player, so during recitation EVERY tick re-runs this update for every mounted page - three page
        // relayouts per tick, competing with swipe gestures for the main thread. The composed page is a cached
        // immutable instance and the highlight is a value pair, so "did anything actually change" is an
        // identity + equality check; skip the relayout when nothing did.
        let key: ((surahID: Int, ayahID: Int)?) -> String = { $0.map { "\($0.surahID):\($0.ayahID)" } ?? "" }
        let termKey = termHighlight.map { "\($0.surahID):\($0.ayahID):\($0.term)" } ?? ""
        let selectedKey = selected.map { "\($0.surahID):\($0.ayahID)" }.sorted().joined(separator: ",")
        let searchKey = searchHighlight.map { "\($0.term)#\($0.matches.map { "\($0.surahID):\($0.ayahID)" }.joined(separator: ","))" } ?? ""
        // The color is part of the key: recoloring a highlight changes the page's wash and its badge while
        // the bookmark set itself is unchanged, and without the color that repaint would be skipped.
        let bookmarkKey = bookmarked
            .map { "\($0.surahID):\($0.ayahID):\($0.highlight?.rawValue ?? "")" }
            .sorted()
            .joined(separator: ",")
        let highlightKey = "\(key(highlight))|\(playingSurahID.map(String.init) ?? "")|\(key(mark))|\(termKey)|\(selectedKey)|\(searchKey)|\(bookmarkKey)"
        if context.coordinator.lastAssignedText === attributed,
           context.coordinator.lastHighlightKey == highlightKey,
           context.coordinator.lastWidth == width {
            return
        }
        context.coordinator.lastAssignedText = attributed
        context.coordinator.lastHighlightKey = highlightKey
        context.coordinator.lastWidth = width

        // Re-pin on every real update: the width changes on rotation / size-class changes.
        tv.textContainer.widthTracksTextView = false
        tv.textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
        tv.attributedText = highlighted(attributed)
        context.coordinator.updateBookmarkBadges(bookmarked, color: UIColor(highlightColor))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, NSLayoutManagerDelegate, UIScrollViewDelegate {
        weak var textView: UITextView?
        weak var scrollView: UIScrollView?
        var ranges: [MushafAyahRange] = []

        // MARK: PDF-style zoom (fitted page only - the host enables zooming there)

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { textView }

        /// Bounce and clipping only exist while actually zoomed in: panning a magnified page should feel
        /// like the facsimile's PDFView (and must not slide over the reader's chrome, hence the clip),
        /// but at rest (scale 1) the fitted page stays perfectly still - no rubber-banding (user rule:
        /// fit-to-page never scrolls) - and its overhanging tashkeel ink keeps drawing into the page's
        /// horizontal padding unclipped.
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let zoomed = scrollView.zoomScale > 1.001
            scrollView.bounces = zoomed
            scrollView.clipsToBounds = zoomed

            // Keep the page CENTERED whenever it is smaller than the viewport - the below-floor
            // rubber-band included. UIScrollView pins an undersized zoom view to the content origin
            // (top-leading), which is what made pinching out anchor to the far left; PDFView centers
            // its document view itself, and this is the same behavior for the text page.
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
        }
        var onTapAyah: ((Int, Int) -> Void)?
        var onLongPressAyah: ((Int, Int) -> Void)?
        var onTapHeading: ((Int) -> Void)?
        var onDoubleTapWord: ((Int, Int, Int) -> Void)?
        var forcedBaselineOffset: CGFloat = 0
        var baselineBand: ClosedRange<CGFloat> = 0...0

        /// Uniform baselines: the paragraph style pins every running-text line BOX to the body font's height,
        /// and this pins where the baseline sits inside that box. TextKit otherwise derives it per line from
        /// the tallest font present, so the Uthmani ornament's deep descender lifted its line's text. Lines
        /// outside the band (surah headings, with their own smaller styles) keep their natural baselines.
        func layoutManager(
            _ layoutManager: NSLayoutManager,
            shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>,
            lineFragmentUsedRect: UnsafeMutablePointer<CGRect>,
            baselineOffset: UnsafeMutablePointer<CGFloat>,
            in textContainer: NSTextContainer,
            forGlyphRange glyphRange: NSRange
        ) -> Bool {
            guard forcedBaselineOffset > 0, baselineBand.contains(lineFragmentRect.pointee.height) else {
                return false
            }
            baselineOffset.pointee = forcedBaselineOffset
            return true
        }

        // What the text view currently displays, so `updateUIView` can skip the full TextKit relayout when
        // nothing visible changed (see the note there).
        var lastAssignedText: NSAttributedString?
        var lastHighlightKey = ""
        var lastWidth: CGFloat = 0

        /// The bookmark glyphs currently drawn over the page, so each update can clear the previous set.
        private var bookmarkBadges: [UIImageView] = []

        /// Draws a small bookmark just above each bookmarked ayah's number ornament.
        ///
        /// The ornament's own character range is already recorded by the composer (`ayahMarkerID`), but ALL
        /// of a page's markers share that sentinel id - so a marker is matched to its ayah by the fact that it
        /// is the tail of that ayah's range (the composer appends the number last, then records both ranges).
        /// The badge is a plain non-interactive subview: it must not intercept the taps and presses that
        /// select the ayah underneath it.
        /// `color` is the fallback for a plain bookmark; a highlighted one paints in its own color instead.
        func updateBookmarkBadges(_ refs: [(surahID: Int, ayahID: Int, highlight: AyahHighlightColor?)],
                                  color: UIColor) {
            for badge in bookmarkBadges { badge.removeFromSuperview() }
            bookmarkBadges.removeAll()

            guard let tv = textView, !refs.isEmpty, tv.textStorage.length > 0 else { return }
            let markerRanges = ranges.filter { $0.ayahID == MushafAyahRange.ayahMarkerID }
            guard !markerRanges.isEmpty else { return }
            tv.layoutManager.ensureLayout(for: tv.textContainer)

            for ref in refs {
                guard let ayahRange = ranges.first(where: {
                    $0.surahID == ref.surahID && $0.ayahID == ref.ayahID
                })?.range else { continue }
                // The marker that ENDS where this ayah ends is this ayah's number.
                guard let marker = markerRanges.first(where: {
                    NSMaxRange($0.range) == NSMaxRange(ayahRange) && $0.surahID == ref.surahID
                })?.range, NSMaxRange(marker) <= tv.textStorage.length else { continue }

                // The ornament ITSELF, not the composer's " ٢ " with its padding spaces - the badge points at
                // the number.
                let ornament = marker.length > 2
                    ? NSRange(location: marker.location + 1, length: marker.length - 2)
                    : marker
                let glyphs = tv.layoutManager.glyphRange(forCharacterRange: ornament, actualCharacterRange: nil)
                guard glyphs.length > 0 else { continue }
                // `enumerateEnclosingRects`, NOT `boundingRect`: the page is right-to-left with LTR number
                // runs inside it, and `boundingRect` returns the UNION over the bidi runs - which on a mushaf
                // line came out as the whole ayah's extent, so every badge sat centred over its ayah instead
                // of over its number. The enclosing rects follow the real visual runs (this is how selection
                // highlights are drawn), and the first one is the ornament's own box.
                var found: CGRect?
                tv.layoutManager.enumerateEnclosingRects(
                    forGlyphRange: glyphs,
                    withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
                    in: tv.textContainer
                ) { candidate, stop in
                    found = candidate
                    stop.pointee = true
                }
                guard var rect = found, rect.height > 0, rect.width > 0 else { continue }
                rect.origin.x += tv.textContainerInset.left
                rect.origin.y += tv.textContainerInset.top

                // Deliberately TINY - a hint, not a second ornament. Sized off the line box so it still
                // scales with the page's fitted font, but kept well under the ayah number's own size (user
                // rule: "keep it small, like a very small thing above it") and tucked close in above it.
                let side = min(max(rect.height * 0.15, 4), 7)
                let image = UIImage(systemName: "bookmark.fill")?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: side, weight: .semibold))
                guard let image else { continue }

                let badge = UIImageView(image: image)
                badge.tintColor = ref.highlight.map { UIColor($0.color) } ?? color
                badge.contentMode = .scaleAspectFit
                badge.isUserInteractionEnabled = false
                // `rect` is the LINE BOX, whose top sits well above the ornament's ink (the composer leads
                // its lines generously to make room for stacked marks). Sitting the badge fully above that
                // top left it marooned nearer the line above than the number it belongs to, so it is nudged
                // down into the leading instead - close over the ornament, still clear of it.
                badge.frame = CGRect(
                    x: rect.midX - side / 2,
                    y: rect.minY - side * 0.25,
                    width: side,
                    height: side
                )
                tv.addSubview(badge)
                bookmarkBadges.append(badge)
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let (surahID, ayahID) = ayah(at: gesture.location(in: textView)) else { return }
            // `<= 0` also covers the name-only subrange sentinel, should a hit ever resolve to it.
            if ayahID <= 0 {
                onTapHeading?(surahID)
            } else {
                onTapAyah?(surahID, ayahID)
            }
        }

        /// Double tap on a word: resolves which whitespace-split token of the ayah's composed text
        /// sits under the fingers and hands (surah, ayah, word index) up. The index is over the SAME
        /// splitting `WordTokens.tokens` uses, so the presenter's tokens/glosses line up; the ayah's
        /// trailing number ornament is one extra final token, which the presenter's bounds check drops.
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, let tv = textView, tv.textStorage.length > 0 else { return }
            let point = gesture.location(in: tv)
            let location = CGPoint(x: point.x - tv.textContainerInset.left, y: point.y - tv.textContainerInset.top)
            var fraction: CGFloat = 0
            let index = tv.layoutManager.characterIndex(
                for: location,
                in: tv.textContainer,
                fractionOfDistanceBetweenInsertionPoints: &fraction
            )
            guard index >= 0, index < tv.textStorage.length else { return }
            guard let entry = ranges.first(where: { NSLocationInRange(index, $0.range) }),
                  entry.ayahID > 0 else { return }
            let storage = tv.textStorage.string as NSString
            // A double tap on the space between words picks nothing - same rule as the list's word tap.
            let tappedChar = storage.substring(with: storage.rangeOfComposedCharacterSequence(at: index))
            guard tappedChar.rangeOfCharacter(from: .whitespacesAndNewlines.inverted) != nil else { return }
            // The word's index = tokens in the ayah's text up to and including the tapped character, minus one.
            let upToTap = storage.substring(
                with: NSRange(location: entry.range.location, length: index - entry.range.location + 1)
            )
            let wordIndex = upToTap.split(whereSeparator: { $0.isWhitespace }).count - 1
            guard wordIndex >= 0 else { return }
            onDoubleTapWord?(entry.surahID, entry.ayahID, wordIndex)
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            // Fire once, when the press is recognized - not on every move that follows.
            guard gesture.state == .began else { return }
            guard let (surahID, ayahID) = ayah(at: gesture.location(in: textView)) else { return }
            // A press on a heading behaves like a tap on it - there are no per-ayah actions to offer there.
            if ayahID <= 0 {
                onTapHeading?(surahID)
            } else {
                onLongPressAyah?(surahID, ayahID)
            }
        }

        /// A pointer's secondary (right / two-finger) click: the Mac-and-trackpad twin of the long press,
        /// routed to the exact same per-ayah actions sheet.
        @objc func handleSecondaryClick(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else { return }
            guard let (surahID, ayahID) = ayah(at: gesture.location(in: textView)) else { return }
            if ayahID <= 0 {
                onTapHeading?(surahID)
            } else {
                onLongPressAyah?(surahID, ayahID)
            }
        }

        /// Pinch-to-magnify (composed pages only - the PDF facsimile zooms through PDFKit). The transform
        /// anchors at the pinch centre and follows it as the fingers move, so the reader can pan while
        /// zoomed by dragging the pinch; lifting the fingers springs the page back to rest. Transient by
        /// design: a persistent zoom would fight the pager's swipe, the tap targets, and the fit-to-page
        /// layout all at once.
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let tv = textView else { return }
            switch gesture.state {
            case .began, .changed:
                // Zoom out is meaningless on a page fitted to its box - clamp to [1, 5].
                let currentScale = tv.transform.a
                var factor = gesture.scale
                if currentScale * factor < 1 { factor = 1 / currentScale }
                if currentScale * factor > 5 { factor = 5 / currentScale }
                // `location(in:)` converts through the current transform, so the anchor stays under the
                // fingers across updates. Draw the zoomed page over its neighbours' chrome, not under it.
                let center = gesture.location(in: tv)
                let anchor = CGPoint(x: center.x - tv.bounds.midX, y: center.y - tv.bounds.midY)
                tv.transform = tv.transform
                    .translatedBy(x: anchor.x, y: anchor.y)
                    .scaledBy(x: factor, y: factor)
                    .translatedBy(x: -anchor.x, y: -anchor.y)
                gesture.scale = 1
                tv.layer.zPosition = 1
            case .ended, .cancelled, .failed:
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85,
                               initialSpringVelocity: 0, options: [.allowUserInteraction]) {
                    tv.transform = .identity
                } completion: { _ in
                    tv.layer.zPosition = 0
                }
            default:
                break
            }
        }

        /// The ayah whose glyphs sit under `point`, in the text view's coordinates.
        private func ayah(at point: CGPoint) -> (surahID: Int, ayahID: Int)? {
            guard let tv = textView, tv.textStorage.length > 0 else { return nil }
            let location = CGPoint(x: point.x - tv.textContainerInset.left, y: point.y - tv.textContainerInset.top)
            var fraction: CGFloat = 0
            let index = tv.layoutManager.characterIndex(
                for: location,
                in: tv.textContainer,
                fractionOfDistanceBetweenInsertionPoints: &fraction
            )
            guard index >= 0, index < tv.textStorage.length else { return nil }
            for entry in ranges where NSLocationInRange(index, entry.range) {
                return (entry.surahID, entry.ayahID)
            }
            return nil
        }
    }
}

/// A sheet the actions sheet hands OFF to its parent rather than presenting itself - see `AyahActionsSheet`.

/// The one-time broad Quran warm the app kicks under the launch cover. Moved out of the app entry file so
/// the warming lives with the Quran module (Al-Quran's entry can call it too) - it lives here because it
/// warms the mushaf render caches, which are defined in this file's iOS-only section.
enum QuranLaunchWarmup {
    /// Warms the most-likely-first surahs (reading position, a bookmark, a favorite, al-Fatihah/al-Baqarah)
    /// before the rest, composes the last-read mushaf pages when page mode is on, then fills in every
    /// remaining surah - yielding + sleeping between each so the Adhan tab stays responsive. Runs on the
    /// main actor (it reads `settings`) and once per session (the shared `didBroadPrewarm` flag).
    @MainActor
    static func prewarmAll() async {
        let quranData = QuranData.shared
        let settings = Settings.shared

        await quranData.waitUntilCoreLoaded()
        if Task.isCancelled || QuranData.didBroadPrewarm { return }

        // Warm the most-likely-first surahs (reading position, a bookmark, a favorite, al-Fatihah/al-Baqarah)
        // before the rest, so the surah a user is most likely to open is ready first.
        let priority = [
            settings.lastReadSurah > 0 ? settings.lastReadSurah : 1,
            settings.bookmarkedAyahs.first?.surah,
            settings.favoriteSurahs.first,
            1, 2
        ].compactMap { $0 }

        var seen = Set<Int>()
        for id in priority where seen.insert(id).inserted {
            if Task.isCancelled { return }
            if let surah = quranData.surah(id) {
                // Priority surahs (the ones a user actually opens first) also warm their search blobs,
                // so the first in-surah search keystroke never pays the one-time build.
                SurahView.prewarm(surah: surah, settings: settings, includeSearchBlobs: true)
                await Task.yield()
            }
        }

        // Skip the broad warms on memory-constrained devices (same gate the Quran tab uses) - priority
        // warming above still ran. This gates the mushaf prewarm below too: composing a ring of pages is
        // exactly the class of work this device can't afford at launch.
        guard !AppPerformance.shouldAvoidBroadPrewarm else { return }

        // Page mode means the Quran tab opens straight into the mushaf, so also compose the last-read pages
        // now - with the geometry persisted from the last session - instead of making the reveal pay for the
        // first page's ~12 fit passes. The fits run on the prewarm queue; the pagination itself is the only
        // main-actor piece, so give the runloop a turn first and keep it off the current transaction.
        if settings.quranPageMode, settings.lastReadSurah > 0 {
            await Task.yield()
            // Compose OFF the main actor (the same path QuranView's own .task uses; the builder is
            // idempotent), then read the cached result. The old direct `pages(...)` call ran the
            // full 6,236-ayah pagination ON the main actor, squarely inside the under-cover tab
            // walk - on older hardware that contention stretched the launch far past the settles.
            await MushafPagination.buildInBackground(quran: quranData.quran, qiraah: settings.displayQiraahForArabic)
            if Task.isCancelled { return }
            let pages = MushafPagination.pages(quran: quranData.quran, qiraah: settings.displayQiraahForArabic)
            if let index = MushafPagination.pageIndex(
                surahID: settings.lastReadSurah,
                ayahID: settings.lastReadAyah > 0 ? settings.lastReadAyah : nil,
                in: pages
            ) {
                MushafPageRenderCache.prewarmAtLaunch(pages: pages, around: index)
            }
            await Task.yield()
        }

        // The broad all-surah sweep is POST-reveal work: warming every surah makes later pushes
        // instant, but under the cover it competed with the tab walk for the main actor - on older
        // hardware that contention (not the fixed settles) is what stretched the launch. The reveal
        // flag flips as the cover starts dissolving; the extra beat clears the finale + dissolve so
        // they run on a free CPU.
        await AppReveal.waitUntilRevealed()
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        if Task.isCancelled { return }

        for surah in quranData.quran where seen.insert(surah.id).inserted {
            if Task.isCancelled { return }
            SurahView.prewarm(surah: surah, settings: settings)
            await Task.yield()
            try? await Task.sleep(nanoseconds: 12_000_000)   // throttle: keep the Adhan tab responsive
        }
        QuranData.didBroadPrewarm = true
    }
}

#if DEBUG
extension MushafPagination {
    /// "-dumpPrintTokens": every riwayah's pages, ayah by ayah, with the number of space-separated
    /// tokens the composer will set for that ayah (its words; the ayah-number ornament is one more
    /// token, added by the composer). Written to Documents/printtokens.json. This is the ground truth
    /// the printed-line tables are built against (pipeline/printlines_build.py), so the tables index
    /// the app's OWN tokens and ayah ids - never a re-derivation of either from the raw texts.
    static func dumpPrintTokens(quranData: QuranData) {
        var out: [String: [[Any]]] = [:]
        for option in Settings.Riwayah.allOptions {
            let tag = Settings.Riwayah.canonicalTag(option.tag)
            let key = tag.isEmpty
                ? "Hafs"
                : (QiraahTajweedStore.fileName(for: tag)?.replacingOccurrences(of: "Tajweed", with: "") ?? tag)
            let qiraah: String? = tag.isEmpty ? nil : tag
            var pageList: [[Any]] = []
            for page in pages(quran: quranData.quran, qiraah: qiraah) {
                var ayahs: [[Int]] = []
                for segment in page.segments {
                    for ayah in segment.ayahs {
                        let text = ayah.displayArabicText(surahId: segment.surah.id, clean: false,
                                                          qiraahOverride: qiraah ?? "Hafs")
                        let tokens = text.split(separator: " ", omittingEmptySubsequences: true).count
                        ayahs.append([segment.surah.id, ayah.id, tokens])
                    }
                }
                pageList.append([page.page, ayahs])
            }
            out[key] = pageList
            print("PRINT TOKENS: \(key) \(pageList.count) pages")
        }
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let data = try? JSONSerialization.data(withJSONObject: out) else {
            print("PRINT TOKENS: write failed")
            return
        }
        let url = documents.appendingPathComponent("printtokens.json")
        try? data.write(to: url)
        print("PRINT TOKENS: wrote \(url.path) (\(data.count) bytes)")
        fflush(stdout)
    }
}
#endif

#endif
