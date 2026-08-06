import SwiftUI
import UIKit

#if os(iOS)

struct MushafPage: Identifiable {
    struct Segment: Identifiable {
        let surah: Surah
        let ayahs: [Ayah]

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

        let pages = build(quran: quran, qiraah: qiraah)
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
        let pages = await Task.detached(priority: .userInitiated) {
            build(quran: quran, qiraah: qiraah)
        }.value
        guard !pageCache.contains(where: { $0.key == key }) else { return }
        if pageCache.count >= pageCacheLimit { pageCache.removeFirst() }
        pageCache.append((key, pages))
    }

    /// The pagination pass itself: pure function of the inputs, no shared state.
    /// Accumulates each segment's ayahs IN PLACE and flushes at page/surah boundaries - the old pass
    /// rebuilt the trailing segment with `ayahs + [ayah]` on every ayah, a full copy of the growing
    /// array each time (O(n²) per page, ~135k array allocations across the book).
    nonisolated private static func build(quran: [Surah], qiraah: String?) -> [MushafPage] {
        var pages: [MushafPage] = []
        var currentPage: Int?
        var currentSegments: [MushafPage.Segment] = []
        var currentSurah: Surah?
        var currentAyahs: [Ayah] = []

        func flushSegment() {
            if let surah = currentSurah, !currentAyahs.isEmpty {
                currentSegments.append(MushafPage.Segment(surah: surah, ayahs: currentAyahs))
            }
            currentAyahs = []
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
            for ayah in surah.ayahs where ayah.existsInQiraah(qiraah, surahID: surah.id) {
                // Ayahs that exist only in this riwayah's counting (a split past the Hafs range,
                // e.g. al-Ikhlas 5 in the Shami count) carry NO Hafs page - they belong on the page
                // of the ayah before them, not on no page at all. Skipping them was the page-mode
                // "missing last verse" bug.
                guard let page = ayah.page ?? lastPageInSurah else { continue }
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

/// Single-slot memo for the in-page find fold (file-scope: `SurahPageReader` is generic, and generic
/// types can't hold static stored state). One slot suffices - consecutive evaluations ask for the same
/// (page, query); any change simply recomputes once.
@MainActor
private enum PageFindMemo {
    static var key = ""
    static var matches: [HighlightedAyahRef] = []
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
    /// Fires whenever the visible page belongs to a different surah, so the navigation title can follow the
    /// reader across surah boundaries instead of naming the surah it was opened from forever.
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
    /// Multi-select (parent-owned): while on, taps toggle ayahs of `surah` instead of marking them.
    var isSelecting: Bool = false
    var selectedAyahIDs: Set<Int> = []
    var onToggleSelection: ((Int) -> Void)? = nil
    /// Fires on a real page turn (not the initial seed) - the parent clears its selections and snippet.
    var onPageTurned: (() -> Void)? = nil
    /// Opens the reciter picker (the parent owns the sheet). Page mode had no way to change reciter
    /// without leaving to list mode; the footer play menu offers it through this hook.
    var onChooseReciter: (() -> Void)? = nil
    /// The optional tajweed/qiraah controls and the mini player. The reader owns the ordering: these sit
    /// ABOVE the page-navigation footer, which is applied last so it stays pinned at the very bottom.
    @ViewBuilder var bottomControls: () -> Controls

    @Environment(\.layoutDirection) private var layoutDirection

    /// Which jump-to picker is unfolded above the footer, if any.
    enum PickerTarget { case page, juz }

    @State private var pageIndex = 0
    @State private var didSetInitialPage = false
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
    /// The typed-number fast path: an alert with a number pad, for jumping without scrolling the wheel.
    /// An alert (not an inline field) because the whole reader ignores the keyboard inset by design - the
    /// page must never resize - so an inline field at the bottom would be covered by the keyboard it raises.
    @State private var showTypedJump = false
    @State private var typedJumpText = ""
    /// The page geometry captured as the jump picker OPENS - before its inset shrinks the live one. The
    /// wheel's predictive warms compose at THIS geometry, because it is what the page returns to the
    /// moment the picker closes and the jump lands; fits at the picker-shrunken height would all near-miss.
    @State private var pickerBaseGeometry: (width: CGFloat, height: CGFloat)?

    // In-page find: the query, and which of the current page's matches is active.
    @State private var pageSearchText = ""
    @State private var currentMatchIndex = 0
    @FocusState private var pageSearchFocused: Bool

    /// The ayahs on the currently-visible page whose text matches the find query, in reading order. Matching
    /// is diacritic-insensitive over Arabic + transliteration + both English translations, so it finds the
    /// ayah whatever the page is showing.
    /// Memoized by (page, folded query, qiraah): the body evaluates this on EVERY re-render while the find
    /// bar is open (including each recitation tick - the reader observes the player), and `syncMatch` /
    /// `goToMatch` ask again per event. The fold now runs once per page+query; every repeat is a hit.
    private func matchesOnPage(_ pages: [MushafPage]) -> [HighlightedAyahRef] {
        let query = settings.cleanSearch(pageSearchText.removingAyahSearchOperators, whitespace: true)
            .removingArabicDiacriticsAndSigns
        guard !query.isEmpty, pages.indices.contains(pageIndex) else { return [] }

        let memoKey = "\(pageIndex)|\(settings.displayQiraahForArabic ?? "")|\(query)"
        if PageFindMemo.key == memoKey { return PageFindMemo.matches }

        var result: [HighlightedAyahRef] = []
        for segment in pages[pageIndex].segments {
            for ayah in segment.ayahs {
                let sources = [
                    ayah.displayArabicText(surahId: segment.surah.id, clean: true, qiraahOverride: settings.displayQiraahForArabic),
                    ayah.textTransliteration,
                    ayah.textEnglishSaheeh,
                    ayah.textEnglishMustafa
                ]
                let matched = sources.contains { source in
                    settings.cleanSearch(source, whitespace: true).removingArabicDiacriticsAndSigns.contains(query)
                }
                if matched {
                    result.append(HighlightedAyahRef(surahID: segment.surah.id, ayahID: ayah.id))
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
        let liveSearch: (matches: [HighlightedAyahRef], term: String)? = {
            guard searchActive else { return nil }
            let term = pageSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty else { return nil }
            return (matchesOnPage(pages), term)
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
                        MushafPageContent(
                            page: pages[index],
                            highlightedAyah: $highlightedAyah,
                            arrivalHighlight: arrivalHighlight,
                            onClearArrival: onClearArrival,
                            searchHighlight: liveSearch,
                            isSelecting: isSelecting,
                            selectionSurahID: surah.id,
                            selectedAyahIDs: selectedAyahIDs,
                            onToggleSelection: onToggleSelection
                        )
                            // Each page's own contents keep the app's reading direction; only the *paging* is
                            // flipped below.
                            .environment(\.layoutDirection, layoutDirection)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        // Order matters: the first inset applied sits closest to the content (higher), the last sits lowest.
        // So the tajweed/qiraah controls + mini player go ABOVE, and the page-navigation footer is pinned to
        // the very bottom.
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomControls() }
        .safeAreaInset(edge: .bottom, spacing: 0) { pageFooter(pages: pages) }
        .safeAreaInset(edge: .top, spacing: 0) {
            if searchActive {
                pageFindBar(pages: pages, matches: liveSearch?.matches ?? [])
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
        .onAppear {
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
                highlightedAyah = nil
                onPageTurned?()
            }
            // Matches are per-page: turning the page re-runs the find against the new page.
            if searchActive { syncMatch(pages: pages, resetIndex: true) }
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
            // A follow is not a user page turn - it must not wipe the mark/selections.
            suppressNextPageTurnClear = true
            withAnimation { pageIndex = target }
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
            }
        }
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

    /// Jump the live pager to this `surah`'s starting page (shared by the `surah.id` and `jumpToken`
    /// onChange handlers - an in-place surah swap from the picker, next-surah, or a search hit).
    private func reseedToStartingPage(in pages: [MushafPage]) {
        let target = startingPageIndex(in: pages)
        if target != pageIndex {
            // A swap that arrives WITH a target ayah (search hit, picker) sets its own highlight in
            // SurahView - the re-seed must not count as a page turn and wipe it.
            suppressNextPageTurnClear = true
            pageIndex = target
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
        guard !matches.isEmpty else { return }
        currentMatchIndex = min(currentMatchIndex, matches.count - 1)
        highlightedAyah = matches[currentMatchIndex]
    }

    /// Step to the previous/next match on this page, wrapping around, and light it up.
    private func goToMatch(_ delta: Int, pages: [MushafPage]) {
        let matches = matchesOnPage(pages)
        guard !matches.isEmpty else { return }
        settings.hapticFeedback()
        currentMatchIndex = (currentMatchIndex + delta + matches.count) % matches.count
        withAnimation(.easeInOut(duration: 0.15)) {
            highlightedAyah = matches[currentMatchIndex]
        }
    }

    /// The in-page find bar: a text field, a match counter with up/down, a close button, and - always - an
    /// escape to the whole-Quran search (offered whether or not this page has a match).
    /// `matches` comes from the body's shared `liveSearch` computation, so the fold runs once per keystroke.
    private func pageFindBar(pages: [MushafPage], matches: [HighlightedAyahRef]) -> some View {
        let hasQuery = !pageSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search this page", text: $pageSearchText)
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
            .padding(.vertical, 10)
            .conditionalGlassEffect(rectangle: true)

            // Always offer the whole-Quran search - the whole point is that a page with no match (or even one
            // with a match) can escape to searching everywhere, without bouncing back to the surah list first.
            Button {
                settings.hapticFeedback()
                let query = pageSearchText
                withAnimation(.easeInOut) { searchActive = false }
                QuranSearchHandoff.shared.request(query)
            } label: {
                Label(matches.isEmpty && hasQuery ? "No matches on this page. Search the whole Quran"
                                                  : "Search the whole Quran",
                      systemImage: "text.magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .conditionalGlassEffect(rectangle: true)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, settings.defaultView ? 20 : 16)
        .padding(.top, 4)
    }

    private func reportSurah(on index: Int, in pages: [MushafPage]) {
        guard pages.indices.contains(index), let surah = pages[index].displayedSurah else { return }
        onSurahChange?(surah)
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
            .padding(.bottom, 8)
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
                    // The ayah count and revelation place live in the pinned header now - the footer is purely
                    // where you are and where you can jump to.
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
    }

    /// "43%" - how far through the mushaf (or through the 30 juz) this page sits.
    private func percent(_ position: Int, of total: Int) -> String {
        guard total > 0 else { return "" }
        return "\(Int((Double(position) / Double(total) * 100).rounded()))%"
    }

    /// "Surah 12/48" with its own little bar - the two positions the reader actually cares about.
    private func meter(label: String, position: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(label) \(position)/\(total)")
                .font(.system(size: 10, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)

            trackedBar(
                fraction: total > 0 ? CGFloat(position) / CGFloat(total) : 0,
                height: 3,
                color: color
            )
            .frame(width: 44)
        }
    }

    /// A fill over a visible track, so a low value still reads as "a little way in" rather than as nothing.
    private func trackedBar(fraction: CGFloat, height: CGFloat, color: Color) -> some View {
        TrackedBar(fraction: fraction, height: height, color: color)
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
                        // qiraah switch mid-pick can shrink it - an out-of-range TabView selection blanks the pager.
                        pageIndex = min(max(pagePickerSelection, 0), max(pages.count - 1, 0))
                    case .juz:
                        // A juz is picked by number, but the reader navigates by page - jump to the page the
                        // juz opens on.
                        if let start = ranges[juzPickerSelection]?.start { pageIndex = start }
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

    /// The same playback menu the list reader offers - play the surah, play it ayah by ayah, repeat it, pick a
    /// reciter - rather than a lone play/stop button that could only do one of those.
    private func pageFooterPlayButton(surah: Surah) -> some View {
        let idle = !quranPlayer.isLoading && !quranPlayer.isPlaying && !quranPlayer.isPaused

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

                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
                    } label: {
                        Label("Play Surah", systemImage: "memories")
                    }

                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: 1, continueRecitation: true)
                    } label: {
                        Label("Play Ayah by Ayah", systemImage: "list.number")
                    }

                    Menu {
                        Text("Repeat Count")
                            .foregroundStyle(.secondary)

                        ForEach([20, 15, 10, 5, 3, 2], id: \.self) { n in
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
    /// Multi-select: while on, taps toggle ayahs of `selectionSurahID` (the surah the bulk actions
    /// operate on) instead of marking; selected ayahs carry the accent tint.
    var isSelecting: Bool = false
    var selectionSurahID: Int = 0
    var selectedAyahIDs: Set<Int> = []
    var onToggleSelection: ((Int) -> Void)? = nil

    /// Padding around the ayah block; the composer measures fit against the same text width and height.
    /// No slack constants beyond these: the fit verifies against the real TextKit layout, so the text gets
    /// every point the paddings don't take. Vertically almost nothing - the Quranic faces carry generous
    /// line-box air above the first ink and below the last (room for stacked marks), which reads as the
    /// page's visual margin on its own; real padding on top of it just shrank the font.
    private static let textPadding: CGFloat = 20
    private static let verticalPadding: CGFloat = 6

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

    /// A tapped surah heading (the in-page name/basmala, or the pinned header) - drives the surah info sheet.
    @State private var infoSurah: Surah?

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
            // The height the page can actually SHOW, not the height of its frame. Anything the pager hands down
            // as a safe-area inset rather than as a smaller frame - the tajweed/qiraah bar most of all, which
            // only exists in comparison mode - is covered by chrome: text fitted into it is text hidden behind
            // the bar. Budgeting against the frame is what cost a comparison-mode page its last line.
            let visibleHeight = max(geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom, 1)
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
                        MushafPageRenderCache.renderAsync(page: page, width: width, height: textHeight) {
                            renderTick &+= 1
                        }
                    }
            }
        }
        .overlay(alignment: spineIsLeading ? .leading : .trailing) { spineRule }
        // The same pinned surah header the list reader uses, so the two reading modes are titled identically:
        // revelation symbol, ayah/page summary, favourite star. It names the page's TOP surah.
        .safeAreaInset(edge: .top, spacing: 0) { topHeader }
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

    /// Whether any sheet presented from THIS page (actions, secondary, surah info) is up.
    private var anyPageSheetOpen: Bool {
        sheetAyah != nil || secondarySheet != nil || infoSurah != nil
    }

    /// Tap a surah's name/basmala (in the page text or the pinned header) to read about the surah.
    private func showSurahInfo(surahID: Int) {
        guard let surah = quranData.surah(surahID) else { return }
        settings.hapticFeedback()
        infoSurah = surah
    }

    private func renderedPageBody(rendered: MushafRenderedPage, width: CGFloat, visibleHeight: CGFloat) -> some View {
            ScrollView {
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
                    selected: isSelecting ? selectedAyahIDs.map { (surahID: selectionSurahID, ayahID: $0) } : [],
                    baselineOffset: rendered.baselineOffset,
                    baselineBand: rendered.baselineBand
                ) { surahID, ayahID in
                    guard ayahRef(surahID: surahID, ayahID: ayahID) != nil else { return }
                    // Select mode: taps build the selection (this surah only - the bulk actions
                    // operate on it) and never touch the reading mark.
                    if isSelecting {
                        if surahID == selectionSurahID {
                            settings.hapticFeedback()
                            onToggleSelection?(ayahID)
                        }
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
                }
                .frame(width: width, height: rendered.height)
                .padding(.horizontal, Self.textPadding)
                .padding(.vertical, Self.verticalPadding)
                // Fill the visible region so a page that fits sits centered in what the reader can SEE (balanced
                // top/bottom spacing); a page that overflows stays its natural height and scrolls.
                .frame(maxWidth: .infinity, minHeight: visibleHeight, alignment: .center)
        }
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
            }
        }
        .smallMediumSheetPresentation()
    }

    @ViewBuilder
    private var topHeader: some View {
        if let surah = page.firstSurah {
            SurahSectionHeader(surah: surah)
                .padding(.horizontal)
                .padding(.vertical, 4)
                // Keep the tapped header lit while its info sheet is open (task: highlight the selection until
                // the sheet is gone). While this surah is loaded in the player, the header carries the accent
                // tint instead - the page-top twin of the in-page name highlight.
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(infoSurah?.id == surah.id
                              ? Color.secondary.opacity(0.18)
                              : quranPlayer.currentSurahNumber == surah.id
                                ? settings.accentColor.color.opacity(0.18)
                                : .clear)
                )
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 0)
                .conditionalGlassEffect(rectangle: true)
                .padding(.top, 4)
                .padding(.horizontal, settings.defaultView ? 20 : 16)
                // Tap the header to read about the surah. The star/emoji keep their own tap gestures -
                // a child gesture wins over this one, so favoriting still works.
                .contentShape(Rectangle())
                .onTapGesture { showSurahInfo(surahID: surah.id) }
                .animation(.easeInOut(duration: 0.15), value: infoSurah?.id == surah.id)
        }
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
    /// Already folded: tajweed toggles AND the page being Arabic. English pages never paint tajweed.
    let showTajweed: Bool
    let fontSize: CGFloat
    let fitPage: Bool
    let accent: UIColor

    @MainActor
    static func current() -> MushafComposeConfig {
        let s = Settings.shared
        let language = s.resolvedMushafPageLanguage
        return MushafComposeConfig(
            pageLanguage: language,
            removeArabicDots: s.removeArabicDots,
            quranUsesSystemArabicFont: s.quranUsesSystemArabicFont,
            arabicFontName: s.quranArabicFontName(for: s.displayQiraahForArabic),
            displayQiraah: s.displayQiraahForArabic,
            cleanArabicText: s.cleanArabicText,
            beginnerMode: s.beginnerMode,
            showTajweed: s.showTajweedColors && s.showArabicText && s.isHafsDisplay && language == .arabic,
            fontSize: CGFloat(s.fontArabicSize),
            fitPage: s.mushafFitPage,
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

    /// Dots-removed text is built from substitution glyphs (ٮ ٯ ڡ) that the Quranic faces do not carry, so it
    /// has to fall back to the system face - the same rule `AyahRow` and `SurahHeaders` already apply. Page mode
    /// was the one reader that ignored it, which is why "Hide Arabic Dots" appeared to do nothing here.
    private var usesSystemFont: Bool { isEnglish || config.removeArabicDots || config.quranUsesSystemArabicFont }
    private var arabicFontName: String { config.arabicFontName }
    private var shouldShowTajweed: Bool { config.showTajweed }

    private func arabicFont(_ size: CGFloat) -> UIFont {
        usesSystemFont ? .roundedSystemFont(ofSize: size)
                       : (UIFont(name: arabicFontName, size: size) ?? .roundedSystemFont(ofSize: size))
    }

    /// Always the Uthmani face, even when the reader picked "Basic": that font is what draws the ayah number as the
    /// circled-flower ornament, so the system fallback would print bare digits mid-page.
    private func markerFont(_ size: CGFloat) -> UIFont {
        UIFont(name: Settings.qiraatUthmaniFontName, size: size) ?? .roundedSystemFont(ofSize: size)
    }

    /// Mushaf pages 1 and 2 (al-Fatihah, and the opening of al-Baqarah) are set centered in a printed mushaf - 
    /// they're short, framed pages, not columns of running text. Every other page is a full block.
    private var isOpeningSpread: Bool { page.page <= 2 }

    /// Justified everywhere except the opening spread, so every line reaches BOTH margins - that's what makes a
    /// trailing-aligned page look set rather than ragged.
    ///
    /// NOT justified when the text is in the system face. Justifying Arabic works by elongating the glyphs
    /// (kashida), and only the Quranic faces carry the elongation forms; with the system face the layout engine
    /// has nothing to stretch, so it dumps ALL the slack into the word gaps instead - which is the "weird spaces
    /// between words" in Basic/no-dots mode. Trailing-aligned with natural spacing is the honest rendering there.
    private func paragraph(_ size: CGFloat, extraLineSpacing: CGFloat = 0, centered: Bool? = nil) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        if centered ?? isOpeningSpread {
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
        p.lineSpacing = MushafPageFitter.lineSpacing(for: size, baseSize: config.fontSize)
            + extraLineSpacing
        // Pin every line box to the BODY font's height. The inline ayah ornaments come from the Uthmani
        // marker face, whose line metrics differ - without the pin, only the lines that happen to carry an
        // ornament grew taller, and the page read as unevenly leaded (worst in English, where the body face
        // is much shorter than the ornament's). Ornament ink taller than the box just draws into the line
        // gap, which the generous lineSpacing above exists to absorb.
        let bodyFont = usesSystemFont ? UIFont.roundedSystemFont(ofSize: size) : arabicFont(size)
        p.minimumLineHeight = bodyFont.lineHeight
        p.maximumLineHeight = bodyFont.lineHeight
        return p
    }

    /// The English body text for an ayah under the current page language.
    private func englishText(for ayah: Ayah) -> String {
        switch config.pageLanguage {
        case .transliteration: return ayah.textTransliteration
        case .clearQuran:      return ayah.textEnglishMustafa
        case .saheeh:          return ayah.textEnglishSaheeh
        case .arabic:          return ""
        }
    }

    private func ayahText(_ ayah: Ayah, surah: Surah, size: CGFloat, colored: Bool,
                          extraLineSpacing: CGFloat = 0) -> NSAttributedString {
        let para = paragraph(size, extraLineSpacing: extraLineSpacing)

        if isEnglish {
            // No tajweed, no beginner letter-spacing - both are Arabic-script concepts.
            return NSAttributedString(
                string: englishText(for: ayah),
                attributes: [
                    .font: UIFont.roundedSystemFont(ofSize: size),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: para,
                ]
            )
        }

        let clean = config.cleanArabicText
        let beginner = config.beginnerMode
        let qiraahOverride = config.displayQiraah ?? "Hafs"
        let base = ayah.displayArabicText(surahId: surah.id, clean: clean, qiraahOverride: qiraahOverride)
        let display = beginner ? base.map { String($0) }.joined(separator: " ") : base
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
            return ns
        }

        return NSAttributedString(
            string: display,
            attributes: [.font: font, .foregroundColor: UIColor.label, .paragraphStyle: para]
        )
    }

    /// The header a surah gets where it BEGINS, mid-page: a rule, then ONE line carrying the bracketed name
    /// (number included, inside the brackets) followed by the bismillah ornament, then a closing rule. Always
    /// centered, whatever the rest of the page does.
    ///
    /// The name and the bismillah shared a line's worth of height each before, which is a lot of a page to give
    /// up on a mushaf that already fits its text exactly. Al-Fatihah counts its basmala as ayah 1 and at-Tawbah
    /// has none, so neither gets the ornament.
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
                                     extraLineSpacing: CGFloat, leadingBreak: Bool) -> (text: NSAttributedString, nameRange: NSRange) {
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

            heading.append(NSAttributedString(string: " \(surah.nameArabic) \u{FD3E}", attributes: arabicAttributes))
        }

        let nameRange = NSRange(location: nameStart, length: heading.length - nameStart)

        if surah.id != 1, surah.id != 9 {
            // On the SAME line as the name. Em quads (not spaces): a run of ordinary spaces between two Arabic
            // runs collapses to almost nothing, which is why the ornament was sitting right up against the name.
            let bismillahFont = UIFont(name: QuranGlyphFont.commonName, size: nameSize)
            heading.append(NSAttributedString(
                string: "\u{2001}\u{2001}\u{2001}" + (bismillahFont != nil ? QuranGlyphFont.bismillahOrnament : Self.basmalaText),
                attributes: [
                    .font: bismillahFont ?? arabicFont(nameSize * 0.85),
                    .foregroundColor: accent,
                    .paragraphStyle: tight,
                ]
            ))
        }

        // The closing rule under the heading line.
        heading.append(NSAttributedString(string: "\n" + rule + "\n", attributes: ruleAttributes))
        return (heading, nameRange)
    }

    /// Fallback only - used if `QuranCommon` isn't installed and the ornament can't be drawn.
    private static let basmalaText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"

    /// The composed page text plus each ayah's character range for hit-testing.
    /// `width` is the column width, needed only so a surah heading's rule can span the full page. It is
    /// optional because the measurement passes don't have a meaningful one yet and don't care.
    func attributed(size: CGFloat, colored: Bool = true, extraLineSpacing: CGFloat = 0,
                    width: CGFloat = 0, spaceTracking: CGFloat = 0) -> (text: NSAttributedString, ranges: [MushafAyahRange]) {
        let result = NSMutableAttributedString()
        var ranges: [MushafAyahRange] = []
        let accent = config.accent
        let para = paragraph(size, extraLineSpacing: extraLineSpacing)
        // Character positions just past each segment's final ayah marker - a surah completing
        // mid-page and the page's own last line alike. `fillSurahClosingLines` first tries to FILL
        // a sparse closing line by loosening its segment's gaps so words cascade down into it;
        // `spaceJustified`'s sparseness cap then lets whatever stays sparse sit naturally at the
        // right margin instead of being flung across the full measure.
        var closingLineEnds: Set<Int> = []
        // The same segments' full ayah-text ranges (headings excluded), for the fill pass.
        var fillableSegments: [NSRange] = []

        for (i, segment) in page.segments.enumerated() {
            // A surah OPENING on this page gets the printed treatment: a full-width rule, the name line, and
            // the basmala. A surah merely *continuing* onto the page after another one ends gets just its name -
            // and the page's own opening surah is titled by the pinned header, so it gets nothing.
            if segment.ayahs.first?.id == 1 {
                let headingStart = result.length
                let heading = surahOpeningHeading(segment.surah, size: size, width: width,
                                                  extraLineSpacing: extraLineSpacing, leadingBreak: i > 0)
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

            for ayah in segment.ayahs {
                let start = result.length
                result.append(ayahText(ayah, surah: segment.surah, size: size, colored: colored,
                                       extraLineSpacing: extraLineSpacing))
                let markerStart = result.length
                result.append(NSAttributedString(string: " \(ayah.idArabic) ", attributes: [
                    .font: markerFont(size),
                    .foregroundColor: accent,
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

            // EVERY segment closes a paragraph whose last line deserves the treatment: a followed
            // segment has necessarily completed its surah (surahs are contiguous in mushaf order),
            // and the page's last segment - surah completed or continuing overleaf - still ends in
            // the page's own last line, which reads just as broken when it's sparse and stretched.
            closingLineEnds.insert(result.length)
            fillableSegments.append(NSRange(location: segmentTextStart,
                                            length: result.length - segmentTextStart))
        }

        // Justify the final compose: first the page-wide loosening (`spaceTracking`, which DOES move line
        // breaks - it was fitted against the same budget, see `balancedSpaceTracking`), then the per-line
        // top-up to the exact margins, which only ever consumes slack inside a line and moves nothing.
        // Tracking attributes don't shift character indices, so the ayah hit-test ranges stay valid.
        if width > 0, !isEnglish, !usesSystemFont, !isOpeningSpread {
            let balanced = NSMutableAttributedString(attributedString: result)
            if spaceTracking > 0 { Self.addSpaceTracking(spaceTracking, to: balanced) }
            Self.fillSurahClosingLines(balanced, width: width, segments: fillableSegments, bodySize: size)
            return (Self.spaceJustified(balanced, width: width, closingLineEnds: closingLineEnds, bodySize: size), ranges)
        }

        return (result, ranges)
    }

    /// The TextKit-1 stack `MushafPageTextView` renders with (`lineFragmentPadding = 0`, unbounded height),
    /// laid out and ready to query. Shared by every measurement in this type so they can't drift from each
    /// other - or from what the text view actually draws.
    private static func layoutStack(
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
    /// stretched tail, the mushaf reader's "floating haraka at the margin" artifact. Every line takes the
    /// full measure, including a paragraph's last; headings keep their own centering, and a segment's
    /// still-sparse closing line (see `closingLineEnds`) is centered on the measure instead of
    /// stretched or left trailing - the printed mushaf's treatment of a surah's short last line.
    private static func spaceJustified(_ source: NSAttributedString, width: CGFloat,
                                       closingLineEnds: Set<Int> = [], bodySize: CGFloat = 0) -> NSAttributedString {
        let justified = NSMutableAttributedString(attributedString: source)
        // The whole stack stays bound: NSLayoutManager does NOT retain its NSTextStorage, so discarding the
        // storage would tear the layout down under the queries below.
        let stack = layoutStack(for: source, width: width)
        let manager = stack.manager

        let string = source.string as NSString
        // Paragraphs whose closing line was too sparse to justify - re-aligned centered after the
        // walk, the way a printed mushaf centers a surah's short last line.
        var centeredParagraphs: [NSRange] = []
        var glyphIndex = 0
        while glyphIndex < manager.numberOfGlyphs {
            var lineGlyphRange = NSRange()
            let usedRect = manager.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: &lineGlyphRange)
            glyphIndex = NSMaxRange(lineGlyphRange)

            let charRange = manager.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
            guard charRange.length > 0 else { continue }

            // Only the running right-aligned Arabic participates; headings and rules are centered on purpose.
            let style = source.attribute(.paragraphStyle, at: charRange.location, effectiveRange: nil) as? NSParagraphStyle
            guard style?.alignment == .right else { continue }

            // Paragraph-final lines are stretched too - deliberately not what `.justified` would do. This is
            // a mushaf page: a short closing line ending flush against only one margin reads as a typesetting
            // mistake, so every line takes the full measure. The exception is a closing line the fill pass
            // could not fill (checked below): that one is CENTERED, never stretched or left trailing.
            let lineEnd = NSMaxRange(charRange)

            // Stretch every space in the line except the trailing whitespace at the break - TextKit hangs
            // that outside the margin, and widening it would move the break itself.
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

            let slack = width - usedRect.width

            // A segment's closing line - a surah ending mid-page, or the page's own last line - gets a
            // sparseness cap. The fill pass has already pulled down whatever words COULD come down; if
            // justifying what remains would still widen each gap by more than half the body size (or the
            // line is a single gapless word), a handful of words flung across the full measure reads as
            // broken setting - so the line is centered on the measure instead, the printed mushaf's
            // treatment of a surah's short last line. (A mid-line break inside a segment can never be
            // sparse enough to trip this: TextKit broke it against the full measure.)
            if slack > 1.5, closingLineEnds.contains(where: { $0 > charRange.location && $0 <= lineEnd }) {
                // The compose's own body size, not the font at the line start - a closing line can
                // begin mid-marker-run, and the marker face's size would skew the cap.
                let cap = (bodySize > 0
                    ? bodySize
                    : (source.attribute(.font, at: charRange.location, effectiveRange: nil) as? UIFont)?.pointSize ?? 20)
                let perSpaceIfJustified = spaceLocations.isEmpty
                    ? CGFloat.greatestFiniteMagnitude
                    : (slack - 1.0) / CGFloat(spaceLocations.count)
                if perSpaceIfJustified > cap * 0.5 {
                    centeredParagraphs.append(string.paragraphRange(for: charRange))
                    continue
                }
            }

            guard !spaceLocations.isEmpty else { continue }
            guard slack > 1.5 else { continue }
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

        // Re-align the too-sparse closing lines' paragraphs centered. Alignment is a paragraph-wide
        // attribute, but only the sparse line visibly moves: every other line of the paragraph was
        // topped up to the full measure above, so centering shifts it by at most the 1pt of headroom.
        // Applied after the walk so the alignment guard above kept reading the original styles.
        for paragraph in centeredParagraphs {
            guard let style = source.attribute(.paragraphStyle, at: paragraph.location, effectiveRange: nil) as? NSParagraphStyle,
                  let centered = style.mutableCopy() as? NSMutableParagraphStyle else { continue }
            centered.alignment = .center
            justified.addAttribute(.paragraphStyle, value: centered, range: paragraph)
        }
        return justified
    }

    /// Fills a segment's sparse closing line - a surah ending mid-page, or the page's own last line -
    /// by loosening THAT segment's word gaps until words cascade down into it - brought down from the
    /// lines above, instead of two words flung across the measure or a short line trailing at the
    /// right margin. The same idea as the page-wide `balancedSpaceTracking`, scoped to one segment:
    /// the loosest setting that adds NO line is used, so the fitted page height is untouched (the
    /// line boxes are pinned, so same lines = same height).
    /// `spaceJustified` then tops the now-fuller lines up to the exact margins, and its sparseness cap
    /// remains the backstop for a closing line nothing could fill.
    ///
    /// Cost: runs once per cached render (`finalize` is the only width-passing compose), and each
    /// segment is probed against ONE live TextKit stack with its gap list precomputed - a probe is a
    /// handful of absolute attribute writes plus an incremental relayout of that segment alone, not a
    /// fresh stack and a full string rescan.
    private static func fillSurahClosingLines(_ text: NSMutableAttributedString, width: CGFloat,
                                              segments: [NSRange], bodySize: CGFloat) {
        guard width > 0, bodySize > 0 else { return }

        for segment in segments where segment.length > 0 {
            // The segment lays out alone: line breaking never crosses a paragraph boundary, so the
            // substring's breaks are exactly the page's, and probing it is far cheaper.
            let sub = text.attributedSubstring(from: segment)
            let subString = sub.string as NSString

            // Preprocessed once: every stretchable gap and the tracking it already carries (the
            // page-wide loosening), so probes can SET absolute values idempotently.
            var spaceLocations: [Int] = []
            var baseTracking: [CGFloat] = []
            for i in 0..<subString.length where subString.character(at: i) == 0x20 {
                let style = sub.attribute(.paragraphStyle, at: i, effectiveRange: nil) as? NSParagraphStyle
                guard style?.alignment == .right else { continue }
                spaceLocations.append(i)
                baseTracking.append((sub.attribute(.tracking, at: i, effectiveRange: nil) as? CGFloat) ?? 0)
            }
            guard !spaceLocations.isEmpty else { continue }

            // The whole stack stays bound: NSLayoutManager does not retain its NSTextStorage.
            let stack = layoutStack(for: sub, width: width)

            func apply(_ tracking: CGFloat) {
                stack.storage.beginEditing()
                for (i, location) in spaceLocations.enumerated() {
                    stack.storage.addAttribute(.tracking, value: baseTracking[i] + tracking,
                                               range: NSRange(location: location, length: 1))
                }
                stack.storage.endEditing()
                stack.manager.ensureLayout(for: stack.container)
            }

            func measure() -> (lines: Int, lastContentLength: Int, lastUsedWidth: CGFloat, lastSpaces: Int) {
                let manager = stack.manager
                var lines = 0
                var lastUsedRect = CGRect.zero
                var lastCharRange = NSRange()
                var glyph = 0
                while glyph < manager.numberOfGlyphs {
                    var lineRange = NSRange()
                    lastUsedRect = manager.lineFragmentUsedRect(forGlyphAt: glyph, effectiveRange: &lineRange)
                    lastCharRange = manager.characterRange(forGlyphRange: lineRange, actualGlyphRange: nil)
                    glyph = NSMaxRange(lineRange)
                    lines += 1
                }

                var contentEnd = NSMaxRange(lastCharRange)
                while contentEnd > lastCharRange.location,
                      let scalar = Unicode.Scalar(subString.character(at: contentEnd - 1)),
                      CharacterSet.whitespacesAndNewlines.contains(scalar) {
                    contentEnd -= 1
                }
                let spaces = spaceLocations.reduce(into: 0) { count, i in
                    if i >= lastCharRange.location && i < contentEnd { count += 1 }
                }
                return (lines, contentEnd - lastCharRange.location, lastUsedRect.width, spaces)
            }

            let base = measure()
            // One line has nothing above to pull from; and a closing line that would justify within
            // the sparseness cap anyway is left alone - only the lines the cap would otherwise leave
            // trailing are worth rebalancing. The threshold is the cap's own formula, so the two
            // passes can never disagree about which lines are sparse.
            guard base.lines > 1 else { continue }
            let slack = width - base.lastUsedWidth
            let sparse = base.lastSpaces == 0 || (slack - 1.0) / CGFloat(base.lastSpaces) > bodySize * 0.5
            guard sparse, slack > bodySize else { continue }

            // Bisect the loosest tracking that keeps the segment's line count - the page-wide
            // balancer's search, against a line-count budget instead of a height budget.
            var lo: CGFloat = 0
            var hi = bodySize * 0.9
            apply(hi)
            if measure().lines <= base.lines {
                lo = hi
            } else {
                for _ in 0..<8 {
                    let mid = (lo + hi) / 2
                    apply(mid)
                    if measure().lines <= base.lines { lo = mid } else { hi = mid }
                }
            }
            let tracking = (lo * 20).rounded(.down) / 20
            guard tracking > 0 else { continue }

            // Apply only if words actually came down: tracking that moves nothing would just widen
            // the sparse line's own gaps - the exact look this pass exists to avoid.
            apply(tracking)
            guard measure().lastContentLength > base.lastContentLength else { continue }

            // Commit to the page text with the same absolute values the winning probe used.
            for (i, location) in spaceLocations.enumerated() {
                text.addAttribute(.tracking, value: baseTracking[i] + tracking,
                                  range: NSRange(location: segment.location + location, length: 1))
            }
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

    /// The largest size a mushaf page can be set at without overflowing. Hard ceiling so a short page (a few
    /// ayahs of a late surah) doesn't blow up to absurd glyphs just because it has the room.
    private var fitCeiling: CGFloat { min(config.fontSize * 2.5, 64) }

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
        guard config.fitPage, !isEnglish, !usesSystemFont, !isOpeningSpread else { return 0 }

        // Compose the page ONCE at this size: every probe below varies only the word-gap tracking attribute,
        // so re-composing the whole attributed page per bisection step (9 full composes per fit, times every
        // page in a prewarm ring) was the single biggest slice of the fit cost. Copy the base and re-track.
        let base = attributed(size: size, colored: false).text
        func heightWithTracking(_ tracking: CGFloat) -> CGFloat {
            let text = NSMutableAttributedString(attributedString: base)
            if tracking > 0 { Self.addSpaceTracking(tracking, to: text) }
            return Self.layoutHeight(of: text, width: width)
        }

        // Loosening beyond this would read as broken setting, not justification; the height constraint
        // usually binds far earlier.
        var lo: CGFloat = 0
        var hi = size * 0.9

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
    func bodyBaselineOffset(size: CGFloat) -> CGFloat {
        let body = usesSystemFont ? UIFont.roundedSystemFont(ofSize: size) : arabicFont(size)
        return ceil(body.ascender)
    }

    /// The fragment heights that count as "a running text line" - the pinned body box, alone or with the
    /// line spacing the paragraph adds, with a little tolerance for rounding. The baseline is forced only
    /// inside this band, so surah-heading lines (own smaller styles, natural heights) keep their own
    /// baselines instead of having the body's - which could sit below their whole fragment - imposed on them.
    func uniformLineFragmentBand(size: CGFloat, extraLineSpacing: CGFloat) -> ClosedRange<CGFloat> {
        let body = usesSystemFont ? UIFont.roundedSystemFont(ofSize: size) : arabicFont(size)
        let box = body.lineHeight
        let spacing = MushafPageFitter.lineSpacing(for: size, baseSize: config.fontSize) + extraLineSpacing
        return (box - 2)...(box + spacing + 2)
    }

    func fittedSize(availableWidth: CGFloat, availableHeight: CGFloat) -> CGFloat {
        let base = config.fontSize
        guard config.fitPage, availableWidth > 1, availableHeight > 1 else { return base }

        let budget = availableHeight

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
            // 9 iterations resolve a ~30pt range to under 0.06pt - finer than the 0.01pt rounding below.
            for _ in 0..<9 {
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
        // the ceiling: the page ends at the biggest size that truly fits, down to the hundredth of a point.
        var lo = candidate
        var hi = ceiling
        if lo < hi {
            for _ in 0..<10 {
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

    init(fontSize: CGFloat, text: NSAttributedString, ranges: [MushafAyahRange], height: CGFloat,
         baselineOffset: CGFloat, baselineBand: ClosedRange<CGFloat>) {
        self.fontSize = fontSize
        self.text = text
        self.ranges = ranges
        self.height = height
        self.baselineOffset = baselineOffset
        self.baselineBand = baselineBand
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
            // Full precision, matching the CGFloat the composer actually fits with (and the list-mode
            // signature). Truncating to Int would collide two fractional sizes onto one cache key.
            "\(s.fontArabicSize)",
            s.displayQiraahForArabic ?? "Hafs",
            s.showTajweedColors ? "t" : "-",
            // Per-category tajweed visibility. The master switch alone meant toggling a single legend
            // category kept serving already-composed pages with the old colors until cache eviction.
            s.tajweedCategoryVisibilitySignature,
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
            // Rotation / iPad split-resize: every page in the prewarm ring was fitted for the OLD
            // geometry, so the first swipe in each direction landed on a cold spinner. Re-warm the ring
            // for the new geometry (async - this setter runs during view-body evaluation). Intermediate
            // live-resize values just bump the generation; stale unstarted fits skip themselves cheaply.
            if oldValue != nil {
                DispatchQueue.main.async {
                    guard let context = lastPrewarmContext else { return }
                    // Center included: a geometry change makes the VISIBLE page cold too, and its refit
                    // must lead the ring, not trail it.
                    prewarm(pages: context.pages, around: context.index, includeCenter: true)
                }
            }
        }
    }

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

    nonisolated private static let persistedMetricsSalt: String = {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(build)|\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
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
            DispatchQueue.main.async {
                let key = keyString as NSString
                if cache.object(forKey: key) == nil {
                    let rendered = finalize(composer: composer, metrics: metrics, width: width)
                    cache.setObject(rendered, forKey: key)
                    noteLatest(page: page, width: width, budget: height, rendered: rendered)
                }
                upgradedClaims.remove(key)
                (pendingRenders.removeValue(forKey: key) ?? []).forEach { $0() }
            }
        }
    }

    private static func cacheKey(page: MushafPage, width: CGFloat, height: CGFloat, signature: String) -> NSString {
        // Geometry is rounded so a sub-point layout jitter can't miss the cache on every frame.
        "\(page.page)|\(Int(width.rounded()))|\(Int(height.rounded()))|\(signature)" as NSString
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
        // pushes a whole extra line and overflows. A printed mushaf closes the leftover by spreading the
        // lines - but only a LITTLE. The old cap (three quarters of the font size per gap!) let each page
        // pick its own rhythm, which read as every page having different line spacing. A fifth of the font
        // size is at most a subtle settle; whatever it can't absorb stays as the symmetric top/bottom band
        // the centered layout already gives. English pages skip the spread entirely: prose reads on constant
        // leading, and it was the English pages where the wandering spacing was most obvious.
        if composer.config.fitPage, !composer.config.pageLanguage.isEnglish, measured < height {
            let lines = composer.lineCount(size: size, width: width, tracking: tracking)
            if lines > 1 {
                let perGap = (height - measured) / CGFloat(lines - 1)
                extraSpacing = min(perGap, size * 0.2)
                measured = composer.balancedLayoutHeight(
                    size: size, width: width, tracking: tracking, extraLineSpacing: extraSpacing
                )
            }
        }

        return FitMetrics(size: size, extraSpacing: extraSpacing, measured: measured, spaceTracking: tracking)
    }

    /// The main-thread tail: the tajweed-colored compose (TajweedStore has main-confined state) and the
    /// drawn-string height check.
    private static func finalize(composer: MushafPageComposer, metrics: FitMetrics, width: CGFloat) -> MushafRenderedPage {
        let built = composer.attributed(size: metrics.size, extraLineSpacing: metrics.extraSpacing,
                                        width: width, spaceTracking: metrics.spaceTracking)

        // Measure the string that will ACTUALLY be drawn - colored and justified - with the same TextKit
        // configuration the text view uses. This height IS the text view's frame: measuring anything else
        // (or padding the number "to be safe") either clips the last line or shrinks every page for slack
        // it doesn't need. Exact is the only correct value.
        let laidOut = MushafPageComposer.layoutHeight(of: built.text, width: width)

        return MushafRenderedPage(
            fontSize: metrics.size,
            text: built.text,
            ranges: built.ranges,
            height: laidOut,
            baselineOffset: composer.bodyBaselineOffset(size: metrics.size),
            baselineBand: composer.uniformLineFragmentBand(size: metrics.size, extraLineSpacing: metrics.extraSpacing)
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
    /// Close-enough budgets only. The fallback exists for the small jitters (a bar mounting, the mini
    /// player appearing - ~10-15% of the page). The reader's FIRST layout pass mid-launch can report
    /// around half the final height; serving that fit as the fallback showed a visibly shrunken page
    /// squatting in half the screen until the exact refit landed. A budget that far off gets the honest
    /// spinner instead - and the refit itself is fast now (see `visibleFitQueue`).
    static func nearestRendered(page: MushafPage, width: CGFloat, height: CGFloat) -> MushafRenderedPage? {
        guard let entry = latestByPage[page.page],
              Int(entry.width.rounded()) == Int(width.rounded()),
              entry.signature == settingsSignature,
              abs(entry.budget - height) <= height * 0.3 else { return nil }
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
    /// Forced distance from each line fragment's top to its baseline - see `MushafRenderedPage.baselineOffset`.
    var baselineOffset: CGFloat = 0
    /// Fragment heights the forced baseline applies to (running text lines, not headings).
    var baselineBand: ClosedRange<CGFloat> = 0...0
    let onTapAyah: (Int, Int) -> Void
    let onLongPressAyah: (Int, Int) -> Void
    /// A tap on a surah heading (name/basmala) - passes the surah's id.
    var onTapHeading: ((Int) -> Void)? = nil

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

        guard !tints.isEmpty || termTarget != nil || searchIsActive else { return text }

        let mutable = NSMutableAttributedString(attributedString: text)
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
        let ayahText = full.substring(with: ayahRange)

        return HighlightedSnippet.matchRanges(of: term, in: ayahText).map { range in
            // `range` is into `ayahText`; convert to a UTF-16 NSRange there, then shift by the ayah's
            // offset within the whole page (both are UTF-16 offsets, so the shift is exact).
            let local = NSRange(range, in: ayahText)
            return NSRange(location: ayahRange.location + local.location, length: local.length)
        }
    }

    func makeUIView(context: Context) -> UITextView {
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

        // A tap only marks an ayah; the actions sheet is the deliberate gesture, so it takes a press. The tap
        // must not also fire when the press wins, hence the dependency.
        let press = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        tv.addGestureRecognizer(press)
        tap.require(toFail: press)

        context.coordinator.textView = tv
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.ranges = ranges
        context.coordinator.onTapAyah = onTapAyah
        context.coordinator.onLongPressAyah = onLongPressAyah
        context.coordinator.onTapHeading = onTapHeading
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
        let highlightKey = "\(key(highlight))|\(playingSurahID.map(String.init) ?? "")|\(key(mark))|\(termKey)|\(selectedKey)|\(searchKey)"
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
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, NSLayoutManagerDelegate {
        weak var textView: UITextView?
        var ranges: [MushafAyahRange] = []
        var onTapAyah: ((Int, Int) -> Void)?
        var onLongPressAyah: ((Int, Int) -> Void)?
        var onTapHeading: ((Int) -> Void)?
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

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let (surahID, ayahID) = ayah(at: gesture.location(in: textView)) else { return }
            // `<= 0` also covers the name-only subrange sentinel, should a hit ever resolve to it.
            if ayahID <= 0 {
                onTapHeading?(surahID)
            } else {
                onTapAyah?(surahID, ayahID)
            }
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

#endif
