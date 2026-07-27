import SwiftUI
#if canImport(UIKit)
import UIKit

/// A slim capsule progress bar. Shared so the mushaf page footer and the list-mode floating header draw the
/// same indicator: both are answering "how far through this are you", and they should look identical.
struct TrackedBar: View {
    let fraction: CGFloat
    let height: CGFloat
    let color: Color

    var body: some View {
        let clamped = min(max(fraction, 0), 1)
        return GeometryReader { geo in
            Capsule()
                .fill(color.opacity(0.20))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: max(geo.size.width * clamped, clamped > 0 ? height : 0))
                }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }
}
#endif

/// An ayah singled out for attention across both reading modes (list and mushaf page). Distinct from the
/// player's own reciting tint - this is the "you opened / tapped / landed on this ayah" mark.
struct HighlightedAyahRef: Equatable {
    let surahID: Int
    let ayahID: Int
}

/// Carries the search TERM along an "open this ayah" navigation, so the destination reader renders the
/// matched snippet in accent - the same coloring the search results list shows - until the reader
/// touches it. Set right before pushing a text-search hit; consumed once by the arriving reader.
@MainActor
final class AyahArrivalTerm {
    static let shared = AyahArrivalTerm()
    private var term: String?
    private var surahID: Int?
    private var ayahID: Int?

    private init() {}

    func set(term: String, surahID: Int, ayahID: Int) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        // Reference queries ("5:3", "page 22") carry no text to highlight - only real text terms travel.
        guard !trimmed.isEmpty, trimmed.rangeOfCharacter(from: .decimalDigits) == nil else { return }
        self.term = trimmed
        self.surahID = surahID
        self.ayahID = ayahID
    }

    /// The pending term if it targets exactly this ayah - cleared on read so it can't fire twice.
    func consume(surahID: Int, ayahID: Int) -> String? {
        guard self.surahID == surahID, self.ayahID == ayahID, let term else { return nil }
        self.term = nil
        self.surahID = nil
        self.ayahID = nil
        return term
    }
}

/// Which ayahs (and boundary dividers) are on screen, held OUTSIDE SurahView's own state - the same
/// isolation HadithChapterView carries, applied to its original home. Rows report in on every
/// viewport crossing while scrolling; as `@State` sets on SurahView, each crossing re-ran the whole
/// ~3,300-line reader body just to feed a 3pt progress bar and the pinned page/juz line. The raw
/// sets are deliberately NOT published - only the derived anchor and end-of-surah flags publish,
/// and only when they actually change - and `ReaderPinnedHeader` is their only observer.
@MainActor
final class AyahVisibilityModel: ObservableObject {
    var visibleAyahIDs = Set<Int>() { didSet { syncDerived() } }
    var visibleBoundaryAyahIDs = Set<Int>() { didSet { syncDerived() } }
    /// The active qiraah's last ayah id (set by the cache rebuild), so `isLastAyahVisible` derives here.
    var lastAyahID: Int? { didSet { syncDerived() } }

    /// The top-visible ayah. The original anchor rule, verbatim: it follows the SMALLEST visible id
    /// and never clears when the sets momentarily empty mid-scroll.
    @Published private(set) var firstVisibleAyahID: Int? = nil
    @Published private(set) var isLastAyahVisible = false
    /// True while the "Go to Next Surah" footer is on screen - the ONLY thing that marks the ayah
    /// progress bar 100%. Seeing the last ayah isn't finishing; reaching the footer is.
    @Published var nextSurahButtonVisible = false

    private func syncDerived() {
        if let next = visibleAyahIDs.union(visibleBoundaryAyahIDs).min(), next != firstVisibleAyahID {
            firstVisibleAyahID = next
        }
        let lastVisible = lastAyahID.map(visibleAyahIDs.contains) ?? false
        if lastVisible != isLastAyahVisible { isLastAyahVisible = lastVisible }
    }

    /// Direct anchor writes - open-at-ayah targets and qiraah-rebuild fallbacks.
    func setAnchor(_ id: Int?) {
        if firstVisibleAyahID != id { firstVisibleAyahID = id }
    }

    func resetScrollTracking() {
        visibleAyahIDs.removeAll()
        visibleBoundaryAyahIDs.removeAll()
    }
}

/// The pinned reader header strip - the ONLY observer of `AyahVisibilityModel`, so a scroll tick
/// re-renders this small strip instead of the whole reader. The drawing itself is handed back to
/// SurahView through `content`, called with the freshly-derived anchor state.
private struct ReaderPinnedHeader<Content: View>: View {
    @ObservedObject var visibility: AyahVisibilityModel
    @ViewBuilder let content: (_ anchorAyahID: Int?, _ isLastAyahVisible: Bool, _ nextSurahButtonVisible: Bool) -> Content

    var body: some View {
        content(visibility.firstVisibleAyahID, visibility.isLastAyahVisible, visibility.nextSurahButtonVisible)
    }
}

struct SurahView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    @Environment(\.scenePhase) private var scenePhase

    @State private var searchText = ""
    /// Scroll-visibility tracking, deliberately NOT observed by this view - see `AyahVisibilityModel`.
    @State private var visibility = AyahVisibilityModel()
    /// The ayah the app is drawing attention to, shared by BOTH readers so a highlight survives a switch
    /// between list and page mode. Set when opening to an ayah (last-read / search hit), when switching
    /// reading modes, and when tapping an ayah; cleared by tapping it again or highlighting another.
    @State private var highlightedAyah: HighlightedAyahRef? = nil
    /// Whether the in-page find bar (page mode only) is open. Owned here because the search button lives in
    /// this view's bottom bar; the search itself runs inside `SurahPageReader`, which owns the pages.
    @State private var pageSearchActive = false
    /// Apple Music-style bar minimization for the LIST reader: true while scrolling down. Page mode is
    /// deliberately exempt - its bottom inset height feeds the page-fit geometry, and a shrinking bar there
    /// would re-fit every cached page mid-scroll.
    @State private var barsCollapsed = false

    // Multi-select mode (list reader): pick several ayahs, then act on all of them at once.
    @State private var isSelectingAyahs = false
    @State private var selectedAyahIDs: Set<Int> = []
    /// Ayahs the bulk "Beginner" action is showing letter-by-letter (survives scroll; per-session).
    @State private var beginnerAyahIDs: Set<Int> = []
    @State private var showBulkNoteSheet = false
    @State private var bulkNoteDraft = ""
    @State private var showBulkRespectAlert = false
    @State private var confirmBulkUnbookmark = false
    @State private var cachedAyahsForQiraah: [Ayah] = []
    @State private var cachedAyahByID: [Int: Ayah] = [:]
    @State private var cachedSearchBlobByAyahID: [Int: String] = [:]
    @State private var searchBlobPrewarmKey: String? = nil
    @State private var overlayDividerByAyahID: [Int: BoundaryDividerModel] = [:]
    @State private var cacheQiraahKey: String = ""
    @State private var qiraahCacheSurahID: Int? = nil
    @State private var scrollDown: Int? = nil
    @State private var pendingScrollAfterSearchClear: Int? = nil
    @State private var didScrollDown = false
    /// The search term that travelled with this navigation (a tapped text-search hit): the target ayah
    /// renders its matched snippet in ACCENT - no background tint - until the reader touches it.
    @State private var arrivalTerm: String? = nil
    @State private var arrivalAyahID: Int? = nil
    @State private var showingSettingsSheet = false
    @State private var showAlert = false
    @State private var showCustomRangeSheet = false
    /// In page mode the reader crosses surah boundaries, so the toolbar must follow the page rather than the
    /// surah this view was opened with. `nil` in list mode, where `surah` never changes.
    @State private var pageSurah: Surah?
    private var displayedSurah: Surah { pageSurah ?? surah }
    /// Bumped on every in-place surah navigation so the page reader re-seeds even when the target
    /// EQUALS the `surah` prop (whose `.onChange` then never fires) - the page-mode "Choose Surah" fix.
    @State private var pageJumpToken = 0

    @State private var showSurahInfoSheet = false
    @State private var showReciterPickerSheet = false
    @State private var showSurahPickerSheet = false
    @State private var confirmConvertQiraahToHafs = false
    @State private var isAyahSearchFocused = false
    @State private var selectedSurahNavigation: Int? = nil
    @State private var dividerInfo: DividerInfo? = nil
    @State private var surahInfoDialog: SurahInfoDialog? = nil
    /// Drives the title-tap chooser (Surah Picker / Surah Info / Revelation Info / page ↔ list).
    @State private var showTitleMenu = false
    /// Counts one "surah opened" per view instance (re-appearing after a pushed sub-view doesn't re-count).
    @State private var didRecordOpen = false
    @State private var khatmOverviewPercent: Int = 0
    @State private var khatmOverviewLastSignature: Int = 0
    /// The surah this view was opened with. `surah` below may differ once the user moves to another surah.
    let initialSurah: Surah
    let initialAyah: Int?
    var onSelectSurah: ((Int) -> Void)? = nil

    /// Set when the user goes to the previous/next surah or picks one - the view swaps the surah **in place**
    /// instead of pushing another `SurahView` onto the stack. `onChange(of: surah.id)` already rebuilds the
    /// caches and resets the scroll, so everything downstream refreshes for free.
    /// (Only ever used in stack navigation; the column-navigation path goes through `onSelectSurah`, which
    /// lets the parent swap the detail, so the two never fight.)
    @State private var swappedSurah: Surah?

    /// Where to land after flipping between list and page mode: the ayah that was at the top of the screen
    /// (list → page) or the first ayah of the page you were on (page → list). Set by `toggleReadingMode()` and
    /// consumed by whichever reader mounts next, so the switch keeps your place instead of jumping to the top
    /// of the surah. Cleared on a surah swap, which has its own target.
    @State private var modeSwitchAyah: Int?

    /// The first surah + ayah of the mushaf page currently on screen, reported by `SurahPageReader`. This is
    /// what "top of the page" means when leaving page mode.
    @State private var pageAnchor: (surahID: Int, ayahID: Int)?

    var surah: Surah { swappedSurah ?? initialSurah }
    /// The requested ayah only applies to the surah we were opened with - after a swap we open at the top - 
    /// unless a mode switch just named an ayah to land on, which wins over both.
    var ayah: Int? { modeSwitchAyah ?? (swappedSurah == nil ? initialAyah : nil) }

    init(surah: Surah, ayah: Int? = nil, onSelectSurah: ((Int) -> Void)? = nil) {
        self.initialSurah = surah
        self.initialAyah = ayah
        self.onSelectSurah = onSelectSurah
    }

    private final class PreparedSurahCache {
        let ayahs: [Ayah]
        let ayahByID: [Int: Ayah]
        let overlayDividerByAyahID: [Int: BoundaryDividerModel]

        init(
            ayahs: [Ayah],
            ayahByID: [Int: Ayah],
            overlayDividerByAyahID: [Int: BoundaryDividerModel]
        ) {
            self.ayahs = ayahs
            self.ayahByID = ayahByID
            self.overlayDividerByAyahID = overlayDividerByAyahID
        }
    }

    private final class PreparedSurahSearchCache {
        let searchBlobByAyahID: [Int: String]

        init(searchBlobByAyahID: [Int: String]) {
            self.searchBlobByAyahID = searchBlobByAyahID
        }
    }

    private static let preparedSurahCache: NSCache<NSString, PreparedSurahCache> = {
        let cache = NSCache<NSString, PreparedSurahCache>()
        cache.countLimit = AppPerformance.preparedSurahCacheLimit
        return cache
    }()

    private static let preparedSurahSearchCache: NSCache<NSString, PreparedSurahSearchCache> = {
        let cache = NSCache<NSString, PreparedSurahSearchCache>()
        cache.countLimit = AppPerformance.preparedSurahCacheLimit
        return cache
    }()

    @MainActor private static var visibleAyahMemoryByRoute: [String: Int] = [:]

    private struct DividerInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private struct SurahInfoDialog: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private static let arFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ar")
        return f
    }()

    private func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        SurahView.arFormatter.number(from: arabicNumber)?.intValue
    }

    private var isSearchingAyahs: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var ayahRowRenderSettingsSignature: String {
        settings.ayahRenderSettingsSignature
    }

    private func markKhatmViewedIfNeeded(_ ayahID: Int) {
        guard settings.quranSortMode == .khatm,
              settings.automaticKhatmCompletion,
              !isSearchingAyahs else { return }
        settings.markKhatmAyahComplete(surah: surah.id, ayah: ayahID)
    }

    private var shouldShowKhatmProgress: Bool {
        settings.quranSortMode == .khatm && !isSearchingAyahs
    }

    private var khatmCompletedAyahCount: Int {
        settings.khatmCompletedCount(for: surah)
    }

    private var khatmCompletionPercent: Int {
        guard surah.numberOfAyahs > 0 else { return 0 }
        return Int((Double(khatmCompletedAyahCount) / Double(surah.numberOfAyahs) * 100).rounded())
    }

    private struct PageJuzQuery {
        let page: Int?
        let juz: Int?
    }

    private enum DividerKeywordMode {
        case page
        case juz
    }

    private func boundaryDividerStyleEquals(_ lhs: BoundaryDividerStyle, _ rhs: BoundaryDividerStyle) -> Bool {
        switch (lhs, rhs) {
        case (.allGreen, .allGreen),
             (.allSecondary, .allSecondary),
             (.pageAccentJuzSecondary, .pageAccentJuzSecondary),
             (.allAccent, .allAccent):
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func listBoundaryDivider(model: BoundaryDividerModel, nextAyahID: Int? = nil, showAyahPreview: Bool = false, showAyahLabel: Bool = true) -> some View {
        if settings.defaultView {
            boundaryDivider(model: model, nextAyahID: nextAyahID, showAyahPreview: showAyahPreview, showAyahLabel: showAyahLabel)
        } else {
            VStack {
                boundaryDivider(model: model, nextAyahID: nextAyahID, showAyahPreview: showAyahPreview, showAyahLabel: showAyahLabel)

                Divider()
                    .padding(.top, 7)
            }
            #if os(iOS)
            .listRowSeparator(.hidden)
            #endif
        }
    }
    private func boundaryDividerEquals(_ lhs: BoundaryDividerModel?, _ rhs: BoundaryDividerModel?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (l?, r?):
            return l.text == r.text &&
                l.pageSegment == r.pageSegment &&
                l.juzSegment == r.juzSegment &&
                boundaryDividerStyleEquals(l.style, r.style)
        default:
            return false
        }
    }

    private func boundaryDividerID(_ model: BoundaryDividerModel) -> String {
        let juz = model.juzSegment ?? ""
        let style: String
        switch model.style {
        case .allGreen: style = "allGreen"
        case .allSecondary: style = "allSecondary"
        case .pageAccentJuzSecondary: style = "pageAccentJuzSecondary"
        case .allAccent: style = "allAccent"
        }
        return "\(model.text)|\(model.pageSegment)|\(juz)|\(style)"
    }

    private func boundaryDividerInfo(for model: BoundaryDividerModel) -> DividerInfo {
        let title: String
        var message: String

        switch model.style {
        case .allGreen:
            title = "Highlighted divider"
            message = "\(model.text)\n\nThis divider is highlighted because it marks a surah start or end. It is mostly a visual marker, not a page or juz change."
        case .allSecondary:
            title = "Surah boundary"
            message = "\(model.text)\n\nGray means the page and juz do not change here. It is mainly showing a surah start or end."
        case .pageAccentJuzSecondary:
            title = "Page boundary"
            message = "\(model.text)\n\nThe color change means the page changes here. The juz stays the same."
        case .allAccent:
            title = "Page and juz boundary"
            message = "\(model.text)\n\nThe color change means both the page and the juz change here."
        }

        // Same-surah page dividers annotate the absolute page with its position within this surah,
        // e.g. "Page 102 (3)". Translate the bare "(N)" into its plain meaning: the Nth page of this surah.
        if let relative = pageWithinSurah(fromSegment: model.pageSegment) {
            message += "\n\n(\(relative)) means you're on the \(ordinal(relative)) page of this surah."
        }

        return DividerInfo(title: title, message: message)
    }

    /// Pull the "(N)" position-within-surah value out of a page segment like "Page 102 (3)".
    private func pageWithinSurah(fromSegment segment: String) -> Int? {
        guard let open = segment.firstIndex(of: "("),
              let close = segment.firstIndex(of: ")"),
              open < close else { return nil }
        let inner = segment[segment.index(after: open)..<close].trimmingCharacters(in: .whitespaces)
        return Int(inner)
    }

    /// "1st", "2nd", "3rd", "5th"… for short, human divider text.
    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)th"
    }

    private func surahInfoDialog(for surah: Surah) -> SurahInfoDialog {
        let revelationOrderText = surah.revelationOrder.map(String.init) ?? "Unknown"
        var message = "Revelation order: #\(revelationOrderText)"

        if let exceptions = surah.revelationExceptions?.trimmingCharacters(in: .whitespacesAndNewlines), !exceptions.isEmpty {
            message += "\n\nExceptions: \(exceptions)"
        }

        return SurahInfoDialog(title: "Revelation Info", message: message)
    }

    /// Ayah row id to scroll to after clearing search (first ayah following this boundary).
    private func scrollTargetAyahID(
        forDivider model: BoundaryDividerModel,
        boundaryModel: SurahBoundaryModel,
        ayahsForQiraah: [Ayah]
    ) -> Int? {
        if let start = boundaryModel.startDivider, boundaryDividerEquals(start, model) {
            return ayahsForQiraah.first?.id
        }
        for ayah in ayahsForQiraah {
            if let d = boundaryModel.dividerBeforeAyah[ayah.id], boundaryDividerEquals(d, model) {
                return ayah.id
            }
        }
        if let end = boundaryModel.endOfSurahDivider, boundaryDividerEquals(end, model) {
            return ayahsForQiraah.last?.id
        }
        if let end = boundaryModel.endDivider, boundaryDividerEquals(end, model) {
            return ayahsForQiraah.last?.id
        }
        return nil
    }

    private func boundaryText(for ayah: Ayah) -> String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "\(mushafPageLabel(forAbsolutePage: page, in: surah)) • Juz \(juz)"
        }
        if let page = ayah.page {
            return mushafPageLabel(forAbsolutePage: page, in: surah)
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func parsePageJuzQuery(from raw: String) -> PageJuzQuery {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return PageJuzQuery(page: nil, juz: nil) }

        let lowered = trimmed.lowercased()

        if lowered.hasPrefix("page ") {
            let valueText = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            let n = Int(valueText) ?? arabicToEnglishNumber(valueText)
            // Derived from the data like QuranView's `totalMushafPages`, not the old hardcoded 630:
            // "page 620" silently matched nothing, and a hardcoded bound drifts if the mushaf changes.
            let lastPage = quranData.surah(114)?.pageEnd ?? 604
            if let n, (1...lastPage).contains(n) { return PageJuzQuery(page: n, juz: nil) }
            return PageJuzQuery(page: nil, juz: nil)
        }

        if lowered.hasPrefix("juz ") {
            let valueText = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            // Accept a juz name (Arabic or transliteration) as well as a number, matching QuranView.
            let n = quranData.resolveJuzIdentifier(valueText) ?? Int(valueText) ?? arabicToEnglishNumber(valueText)
            if let n, (1...30).contains(n) { return PageJuzQuery(page: nil, juz: n) }
            return PageJuzQuery(page: nil, juz: nil)
        }

        return PageJuzQuery(page: nil, juz: nil)
    }

    private func parseAyahNumberQuery(from raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lowered = trimmed.lowercased()
        let prefixes = ["ayah ", "ayahs ", "aayah ", "aayahs ", "verse ", "verses "]
        for prefix in prefixes where lowered.hasPrefix(prefix) {
            let valueText = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = Int(valueText) ?? arabicToEnglishNumber(valueText), n >= 1 {
                return n
            }
        }

        return nil
    }

    private func booleanAyahSearchGroups(from rawQuery: String) -> [[BooleanAyahTerm]]? {
        let normalized = rawQuery
            .replacingOccurrences(of: "&&", with: "&")
            .replacingOccurrences(of: "||", with: "|")

        guard normalized.contains("&") || normalized.contains("|") || normalized.contains("!") || normalized.contains("#") || normalized.contains("^") || normalized.contains("%") || normalized.contains("$") || normalized.contains("=") else {
            return nil
        }

        return normalized
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { part in
                part
                    .split(separator: "&", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .compactMap(booleanAyahSearchTerm(from:))
            }
            .filter { !$0.isEmpty }
    }

    private struct BooleanAyahTerm {
        enum MatchMode {
            case contains
            case startsWith
            case endsWith
            case exact
            case wholeWord   // `=` - matches whole words / a series of whole words (not substrings)
        }

        let value: String
        let isNegated: Bool
        let matchMode: MatchMode
        let requiresTashkeelMatch: Bool
        let tashkeelPattern: String
        let requiresExactEnglishMatch: Bool
        let exactEnglishPhrase: String
    }

    private static let arabicTashkeelCharacterSet: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "\u{0610}"..."\u{061A}")
        set.insert(charactersIn: "\u{064B}"..."\u{065F}")
        set.insert(charactersIn: "\u{0670}"..."\u{0670}")
        set.insert(charactersIn: "\u{06D6}"..."\u{06ED}")
        return set
    }()

    private func arabicTashkeelBlob(_ text: String) -> String {
        String(text.unicodeScalars.filter { Self.arabicTashkeelCharacterSet.contains($0) })
    }

    private func exactPhraseBlob(_ text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func booleanAyahSearchTerm(from rawTerm: String) -> BooleanAyahTerm? {
        var term = rawTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return nil }

        var isNegated = false
        while term.hasPrefix("!") {
            isNegated.toggle()
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var requiresTashkeelMatch = false
        while term.hasPrefix("#") {
            requiresTashkeelMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var wholeWordMatch = false
        while term.hasPrefix("=") {
            wholeWordMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var startsWithMatch = false
        if term.hasPrefix("^") {
            startsWithMatch = true
            term.removeFirst()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var endsWithMatch = false
        if term.hasSuffix("%") || term.hasSuffix("$") {
            endsWithMatch = true
            term.removeLast()
            term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !term.isEmpty else { return nil }
        let cleaned = settings.cleanSearch(term, whitespace: true)
        guard !cleaned.isEmpty else { return nil }

        let matchMode: BooleanAyahTerm.MatchMode
        if wholeWordMatch {
            matchMode = .wholeWord
        } else if startsWithMatch && endsWithMatch {
            matchMode = .exact
        } else if startsWithMatch {
            matchMode = .startsWith
        } else if endsWithMatch {
            matchMode = .endsWith
        } else {
            matchMode = .contains
        }

        return BooleanAyahTerm(
            value: cleaned,
            isNegated: isNegated,
            matchMode: matchMode,
            requiresTashkeelMatch: requiresTashkeelMatch && term.containsArabicLetters,
            tashkeelPattern: arabicTashkeelBlob(term),
            requiresExactEnglishMatch: requiresTashkeelMatch && !term.containsArabicLetters,
            exactEnglishPhrase: exactPhraseBlob(term)
        )
    }

    private func searchTokens(from cleanedText: String) -> [String] {
        cleanedText.split(separator: " ").map(String.init).filter { !$0.isEmpty }
    }

    private func ayahTermMatch(haystack: String, tokens: [String], term: String, mode: BooleanAyahTerm.MatchMode) -> Bool {
        switch mode {
        case .contains:
            return haystack.contains(term)
        case .startsWith:
            return haystack.hasPrefix(term) || tokens.contains(where: { $0.hasPrefix(term) })
        case .endsWith:
            return haystack.hasSuffix(term) || tokens.contains(where: { $0.hasSuffix(term) })
        case .exact:
            return haystack == term || tokens.contains(term)
        case .wholeWord:
            // The query's words must appear as a consecutive run of whole words (a full word, or a full
            // series of words) - e.g. "=رب" matches the word رب but not "ربهم".
            return consecutiveTokenMatch(tokens, query: searchTokens(from: term), lastMustBeExact: true)
        }
    }

    /// True if `query`'s tokens appear as a consecutive run of whole words in `haystack`.
    private func consecutiveTokenMatch(_ haystack: [String], query: [String], lastMustBeExact: Bool) -> Bool {
        guard !query.isEmpty, haystack.count >= query.count else { return false }
        for start in 0...(haystack.count - query.count) {
            var matched = true
            for offset in query.indices {
                let word = haystack[start + offset]
                let term = query[offset]
                if offset == query.count - 1 && !lastMustBeExact {
                    if !word.hasPrefix(term) { matched = false; break }
                } else if word != term {
                    matched = false
                    break
                }
            }
            if matched { return true }
        }
        return false
    }

    private func matchesBooleanAyahSearch(ayah: Ayah, haystack: String, groups: [[BooleanAyahTerm]]) -> Bool {
        let haystackTokens = searchTokens(from: haystack)
        return groups.contains { andTerms in
            andTerms.allSatisfy { term in
                let containsTerm: Bool
                if term.requiresTashkeelMatch {
                    let lettersMatch = ayahTermMatch(haystack: haystack, tokens: haystackTokens, term: term.value, mode: term.matchMode)
                    let tashkeelHaystack = arabicTashkeelBlob(ayah.textArabic(for: settings.displayQiraahForArabic))
                    let tashkeelMatch = term.tashkeelPattern.isEmpty || tashkeelHaystack.contains(term.tashkeelPattern)
                    containsTerm = lettersMatch && tashkeelMatch
                } else if term.requiresExactEnglishMatch {
                    let englishExactHaystack = exactPhraseBlob([
                        ayah.textTransliteration,
                        ayah.textEnglishSaheeh,
                        ayah.textEnglishMustafa
                    ].joined(separator: " "))
                    containsTerm = !term.exactEnglishPhrase.isEmpty && ayahTermMatch(
                        haystack: englishExactHaystack,
                        tokens: searchTokens(from: englishExactHaystack),
                        term: term.exactEnglishPhrase,
                        mode: term.matchMode
                    )
                } else {
                    containsTerm = ayahTermMatch(haystack: haystack, tokens: haystackTokens, term: term.value, mode: term.matchMode)
                }
                return term.isNegated ? !containsTerm : containsTerm
            }
        }
    }

    static func prewarm(surah: Surah, settings: Settings, includeSearchBlobs: Bool = false) {
        _ = preparedCache(for: surah, settings: settings)
        AyahRow.prewarmArabicDisplay(
            surah: surah,
            settings: settings,
            limit: AppPerformance.prewarmArabicAyahLimit
        )
        prewarmTajweed(surah: surah, settings: settings, limit: 12)

        // Priority surahs also warm their SEARCH blobs: the first search keystroke in a surah otherwise
        // pays the whole per-ayah normalization synchronously in body - the one-time build that made the
        // first keystroke stutter in long surahs. Off-main, into the same static cache body reads.
        if includeSearchBlobs {
            let qiraah = settings.displayQiraahForArabic
            let cacheKey = "\(surah.id)|\(qiraah ?? "")|s1" as NSString
            if preparedSurahSearchCache.object(forKey: cacheKey) == nil {
                let ayahs = preparedCache(for: surah, settings: settings).ayahs
                Task.detached(priority: .utility) {
                    let map = buildSearchBlobMap(ayahs: ayahs, displayQiraah: qiraah)
                    await MainActor.run {
                        preparedSurahSearchCache.setObject(PreparedSurahSearchCache(searchBlobByAyahID: map), forKey: cacheKey)
                    }
                }
            }
        }
    }

    /// Tajweed attributed text was the one thing the list prewarm never warmed: with tajweed colors on, each
    /// row's FIRST render paid the full per-ayah cluster analysis synchronously on the main thread, mid-
    /// scroll - the first-scroll hitch for tajweed users. Warm the first screenful here instead, one ayah per
    /// runloop hop so the warm itself can never hitch. (TajweedStore keeps main-confined state, so this runs
    /// on main - spread out, at idle, instead of bunched under the user's finger.)
    private static func prewarmTajweed(surah: Surah, settings: Settings, limit: Int) {
        guard settings.showTajweedColors, settings.showArabicText, settings.isHafsDisplay else { return }
        let ayahs = Array(surah.ayahs.prefix(limit))
        guard !ayahs.isEmpty else { return }

        func warm(_ index: Int) {
            guard index < ayahs.count else { return }
            let ayah = ayahs[index]
            // Mirror exactly what AyahRow will ask for, so these warms fill the same cache entries.
            let raw = ayah.displayArabicText(surahId: surah.id, clean: false)
            let displayBase = settings.cleanArabicText ? ayah.displayArabicText(surahId: surah.id, clean: true) : raw
            let display = settings.beginnerMode ? displayBase.map { String($0) }.joined(separator: " ") : displayBase
            _ = TajweedStore.shared.attributedText(
                surah: surah.id,
                ayah: ayah.id,
                text: raw,
                displayText: display,
                cleanDisplayText: settings.cleanArabicText,
                beginnerSpacing: settings.beginnerMode
            )
            DispatchQueue.main.async { warm(index + 1) }
        }
        DispatchQueue.main.async { warm(0) }
    }

    private static func preparedCache(for surah: Surah, settings: Settings) -> PreparedSurahCache {
        let qiraahKey = settings.displayQiraahForArabic ?? ""
        let cacheKey = "\(surah.id)|\(qiraahKey)" as NSString
        if let cached = preparedSurahCache.object(forKey: cacheKey) {
            return cached
        }

        let ayahs = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
        let ayahByID = Dictionary(uniqueKeysWithValues: ayahs.map { ($0.id, $0) })
        let shouldBuildFullOverlayMap = surah.pageOrJuzChangesWithinSurah

        var overlayMap: [Int: BoundaryDividerModel] = [:]

        if shouldBuildFullOverlayMap {
            overlayMap.reserveCapacity(ayahs.count)
        }

        for (index, ayah) in ayahs.enumerated() {
            if shouldBuildFullOverlayMap || index == 0 {
                let pageSegment: String
                if let page = ayah.page {
                    pageSegment = mushafPageLabel(forAbsolutePage: page, in: surah)
                } else if let juz = ayah.juz {
                    pageSegment = "Juz \(juz)"
                } else {
                    continue
                }

                let juzSegment = (ayah.page != nil) ? ayah.juz.map { "Juz \($0)" } : nil
                let pageInSurah = ayah.page.flatMap { surah.pageWithinSurah($0) }
                overlayMap[ayah.id] = BoundaryDividerModel(
                    text: boundaryText(for: ayah, in: surah) ?? pageSegment,
                    pageSegment: pageSegment,
                    juzSegment: juzSegment,
                    style: .allAccent,
                    pageInSurah: pageInSurah,
                    surahPageCount: pageInSurah.map { max(surah.pageCount, $0) }
                )
            }
        }

        let prepared = PreparedSurahCache(
            ayahs: ayahs,
            ayahByID: ayahByID,
            overlayDividerByAyahID: overlayMap
        )
        preparedSurahCache.setObject(prepared, forKey: cacheKey)
        return prepared
    }

    private static func preparedSearchCache(
        for surah: Surah,
        settings: Settings,
        ayahs: [Ayah]
    ) -> PreparedSurahSearchCache {
        let qiraahKey = settings.displayQiraahForArabic ?? ""
        let cacheKey = "\(surah.id)|\(qiraahKey)|s1" as NSString
        if let cached = preparedSurahSearchCache.object(forKey: cacheKey) {
            return cached
        }

        let searchBlobMap = buildSearchBlobMap(ayahs: ayahs, displayQiraah: settings.displayQiraahForArabic)
        let prepared = PreparedSurahSearchCache(searchBlobByAyahID: searchBlobMap)
        preparedSurahSearchCache.setObject(prepared, forKey: cacheKey)
        return prepared
    }

    private static func boundaryText(for ayah: Ayah, in surah: Surah) -> String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "\(mushafPageLabel(forAbsolutePage: page, in: surah)) • Juz \(juz)"
        }
        if let page = ayah.page {
            return mushafPageLabel(forAbsolutePage: page, in: surah)
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func rebuildQiraahCaches() {
        let key = settings.displayQiraahForArabic ?? ""
        if qiraahCacheSurahID == surah.id, key == cacheQiraahKey, !cachedAyahsForQiraah.isEmpty {
            return
        }

        let prepared = Self.preparedCache(for: surah, settings: settings)
        let ayahs = prepared.ayahs

        cachedAyahsForQiraah = ayahs
        cachedAyahByID = prepared.ayahByID
        overlayDividerByAyahID = prepared.overlayDividerByAyahID
        cachedSearchBlobByAyahID = [:]
        searchBlobPrewarmKey = nil
        cacheQiraahKey = key
        qiraahCacheSurahID = surah.id

        let fallbackID = ayahs.first?.id
        visibility.lastAyahID = ayahs.last?.id
        if let anchor = visibility.firstVisibleAyahID {
            if cachedAyahByID[anchor] == nil {
                visibility.setAnchor(fallbackID)
            }
        } else {
            visibility.setAnchor(fallbackID)
        }

        prewarmSearchBlobs()
    }

    /// Builds the per-ayah search blobs for the active surah/qiraah on a background queue and
    /// publishes them to `cachedSearchBlobByAyahID`. This moves the expensive normalization work
    /// (thousands of `cleanSearch` calls) off the main thread so the first ayah-search keystroke
    /// never has to build the blob map synchronously while the user is typing.
    private func prewarmSearchBlobs() {
        let qiraahKey = settings.displayQiraahForArabic ?? ""
        let key = "\(surah.id)|\(qiraahKey)|s1"
        if searchBlobPrewarmKey == key, !cachedSearchBlobByAyahID.isEmpty { return }

        let surah = self.surah
        let settings = self.settings
        let displayQiraah = settings.displayQiraahForArabic
        let ayahs = cachedAyahsForQiraah.isEmpty
            ? Self.preparedCache(for: surah, settings: settings).ayahs
            : cachedAyahsForQiraah

        Task.detached(priority: .utility) {
            let blobMap = Self.buildSearchBlobMap(ayahs: ayahs, displayQiraah: displayQiraah)
            await MainActor.run {
                // Discard if the user moved to another surah/qiraah mid-build.
                let currentKey = "\(self.surah.id)|\(self.settings.displayQiraahForArabic ?? "")|s1"
                guard currentKey == key else { return }
                self.cachedSearchBlobByAyahID = blobMap
                self.searchBlobPrewarmKey = key
            }
        }
    }

    /// Pure, actor-agnostic builder for the per-ayah search-blob map. Marked `nonisolated` so it can run
    /// on a background task without hopping back to the main actor (SurahView, being a `View`, is otherwise
    /// `@MainActor`-isolated). It only touches `Settings.shared` config and immutable ayah text.
    nonisolated private static func buildSearchBlobMap(ayahs: [Ayah], displayQiraah: String?) -> [Int: String] {
        let settings = Settings.shared
        var searchBlobMap: [Int: String] = [:]
        searchBlobMap.reserveCapacity(ayahs.count)
        for ayah in ayahs {
            var parts = [
                ayah.textArabic(for: displayQiraah),
                ayah.textCleanArabic(for: displayQiraah),
                ayah.textTransliteration,
                ayah.textEnglishSaheeh,
                ayah.textEnglishMustafa,
                String(ayah.id),
                ayah.idArabic
            ]
            .map { settings.cleanSearch($0) }

            // Mirror QuranView's silent-letter search: also index the silent-letter-stripped Arabic so a
            // query that omits silent letters still matches. Always on - the fold is strictly additive
            // (the "s1" in the cache keys is the fossil of the old toggle).
            parts.append(settings.cleanSearchIgnoringSilentArabicLetters(ayah.textArabic(for: displayQiraah)))
            parts.append(settings.cleanSearchIgnoringSilentArabicLetters(ayah.textCleanArabic(for: displayQiraah)))

            searchBlobMap[ayah.id] = parts.joined(separator: " ")
        }
        return searchBlobMap
    }

    private var visibleAyahMemoryRouteKey: String {
        "\(surah.id)|\(ayah ?? 0)|\(settings.displayQiraahForArabic ?? "")"
    }

    @MainActor
    private func rememberVisibleAyahID(_ ayahID: Int) {
        Self.visibleAyahMemoryByRoute[visibleAyahMemoryRouteKey] = ayahID
    }

    /// Clamps a requested ayah to the nearest verse that actually exists in the active qiraah. Bookmarks /
    /// deep links are stored in Hafs numbering, but qiraat merge/omit some ayahs (e.g. Baqarah ends at 285
    /// in Warsh, 286 in Hafs), so a target may not exist - land on the closest one instead of the top.
    private func nearestExistingAyahID(_ requested: Int, in ids: [Int]) -> Int? {
        ids.min(by: { abs($0 - requested) < abs($1 - requested) })
    }

    /// Stable ids for the rows ABOVE the first ayah, so a Previous/Next swap can land at the list's
    /// literal top instead of at ayah 1 with everything above it (nav buttons, bismillah, khatm bar)
    /// already scrolled out of view.
    static let khatmTopAnchorID = "surah-list-khatm-top"
    static let qiraahTopAnchorID = "surah-list-qiraah-top"
    static let navTopAnchorID = "surah-list-nav-top"
    static let headerRowAnchorID = "surah-list-header-row"

    /// The topmost row the list is currently rendering - the conditions mirror, in order, the sections
    /// laid out at the top of `ayahListScreen`.
    private var surahListTopTargetID: String {
        if shouldShowKhatmProgress { return Self.khatmTopAnchorID }
        if !settings.isHafsDisplay { return Self.qiraahTopAnchorID }
        #if !os(watchOS)
        if neighboringSurah(before: surah.id) != nil || neighboringSurah(after: surah.id) != nil {
            return Self.navTopAnchorID
        }
        #endif
        return Self.headerRowAnchorID
    }

    /// Scrolls the reading list to its very top (same retry discipline as `scrollToAyah`).
    private func scrollToListTop(proxy: ScrollViewProxy) {
        let targetID = surahListTopTargetID
        func attempt(_ remaining: Int) {
            proxy.scrollTo(targetID, anchor: .top)
            guard remaining > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                attempt(remaining - 1)
            }
        }
        DispatchQueue.main.async { attempt(2) }
    }

    private func scrollToAyah(_ ayahID: Int, proxy: ScrollViewProxy, animated: Bool = false) {
        // Lazy list cells for the target may not exist on the first pass (especially right after the view
        // appears or is reconfigured), so a single scrollTo can silently miss and leave the old position.
        // Retry across a few runloop ticks so the target reliably lands.
        func attempt(_ remaining: Int) {
            if animated {
                withAnimation { proxy.scrollTo(ayahID, anchor: .top) }
            } else {
                proxy.scrollTo(ayahID, anchor: .top)
            }
            guard remaining > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                attempt(remaining - 1)
            }
        }
        DispatchQueue.main.async { attempt(2) }
    }

    /// True when the shared attention-highlight lands on this surah's given ayah.
    private func isAyahHighlighted(_ ayahID: Int) -> Bool {
        highlightedAyah?.surahID == surah.id && highlightedAyah?.ayahID == ayahID
    }

    /// Tap an ayah in the list to mark it (task: highlight it); tap the marked ayah again to clear it. Writes
    /// the shared highlight so the mark carries over to the page reader.
    private func toggleListHighlight(_ ayahID: Int) {
        // ONE touch on a row still showing its search-arrival state clears BOTH the accent snippet
        // and the selection together.
        if arrivalTerm != nil, arrivalAyahID == ayahID {
            withAnimation(.easeInOut(duration: 0.15)) {
                arrivalTerm = nil
                arrivalAyahID = nil
                highlightedAyah = nil
            }
            return
        }
        let tapped = HighlightedAyahRef(surahID: surah.id, ayahID: ayahID)
        withAnimation(.easeInOut(duration: 0.15)) {
            highlightedAyah = highlightedAyah == tapped ? nil : tapped
        }
    }

    /// The page label as shown on a divider. The persistent floating OVERLAY keeps the full "(relative/total)"
    /// - it's the reader's "where am I in this surah." The quieter in-list dividers show just the relative
    /// page number, "Page 102 (3)", since the total is redundant once the overlay carries it.
    private func displayPageSegment(_ segment: String, isOverlay: Bool) -> String {
        guard !isOverlay,
              let open = segment.lastIndex(of: "("),
              let slash = segment[open...].firstIndex(of: "/"),
              let close = segment[slash...].firstIndex(of: ")") else { return segment }
        return String(segment[..<slash]) + ")" + String(segment[segment.index(after: close)...])
    }

    private func boundaryDivider(model: BoundaryDividerModel, isOverlay: Bool = false, nextAyahID: Int? = nil, showAyahPreview: Bool = false, showAyahLabel: Bool = true) -> some View {
        let accent = settings.accentColor.color

        let dividerColor: Color = {
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()
        let pageColor: Color = {
            if isOverlay { return accent }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()
        let juzColor: Color = {
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary: return .secondary
            case .allAccent: return accent
            }
        }()
        let separatorColor: Color = {
            if isOverlay { return settings.accentColor.color }
            switch model.style {
            case .allGreen: return settings.accentColor.color
            case .allSecondary: return .secondary
            case .pageAccentJuzSecondary, .allAccent: return accent
            }
        }()

        let dividerContent = HStack(spacing: isOverlay ? 8 : 10) {
            #if os(iOS)
            Group {
                if isOverlay {
                    Rectangle()
                        .fill(dividerColor.opacity(0.55))
                        .frame(maxHeight: 1)
                } else {
                    Rectangle()
                        .fill(dividerColor.opacity(0.45))
                        .frame(maxHeight: 1)
                }
            }
            #else
            Spacer()
            #endif

            (
                Text(displayPageSegment(model.pageSegment, isOverlay: isOverlay))
                    .foregroundColor(pageColor)
                +
                (model.juzSegment.map {
                    Text(" • ").foregroundColor(separatorColor)
                    + Text($0).foregroundColor(juzColor)
                } ?? Text(""))
            )
            // The overlay is the reader's one persistent "where am I" - it earns a real footnote size; the
            // in-list dividers stay quieter so they don't compete with the ayahs around them.
            .font((isOverlay ? Font.footnote : Font.caption).weight(.semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(isOverlay ? 0.5 : 0.6)
            .allowsTightening(!isOverlay)
            .layoutPriority(2)
            .fixedSize(horizontal: isOverlay, vertical: true)

            #if os(iOS)
            Group {
                if isOverlay {
                    Rectangle()
                        .fill(dividerColor.opacity(0.55))
                        .frame(maxHeight: 1)
                } else {
                    Rectangle()
                        .fill(dividerColor.opacity(0.45))
                        .frame(maxHeight: 1)
                }
            }
            #else
            Spacer()
            #endif
        }
        .padding(.vertical, isOverlay ? 4 : 6)
        .padding(.horizontal, 0)
        .frame(maxWidth: isOverlay ? .infinity : nil)
        .contentShape(Rectangle())

        #if os(iOS)
        // While searching, dividers double as jump targets: a tap navigates to the ayah and the info
        // dialog is reserved for a long-press. When not searching there is nothing to jump to, so a plain
        // tap opens the info dialog and there is no long-press.
        if !searchText.isEmpty {
            if let ayahID = nextAyahID {
                let labeledContent = VStack(spacing: 2) {
                    dividerContent
                    if showAyahLabel {
                        Text("Ayah \(ayahID)")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    // For a bare "page"/"juz" keyword search we only list dividers (no ayah rows), so show a
                    // small Arabic preview of the start of the divider's first ayah. Rendered with the same
                    // pipeline as a real ayah row (font, tajweed, beginner mode, Allah highlight), just smaller
                    // and single-line so only the beginning of the ayah shows.
                    if showAyahPreview, settings.showArabicText,
                       let previewAyah = surah.ayahs.first(where: { $0.id == ayahID }) {
                        AyahArabicSnippet(surah: surah, ayah: previewAyah, scale: 0.7, lineLimit: 1)
                            .equatable()
                    }
                }
                return AnyView(
                    labeledContent
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.hapticFeedback()
                            scrollDown = ayahID
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.45)
                                .onEnded { _ in
                                    settings.hapticFeedback()
                                    dividerInfo = boundaryDividerInfo(for: model)
                                }
                        )
                )
            }

            return AnyView(
                dividerContent
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.45)
                            .onEnded { _ in
                                settings.hapticFeedback()
                                dividerInfo = boundaryDividerInfo(for: model)
                            }
                    )
            )
        }

        return AnyView(
            dividerContent
                .onTapGesture {
                    settings.hapticFeedback()
                    dividerInfo = boundaryDividerInfo(for: model)
                }
        )
        #else
        return AnyView(
            dividerContent
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.45)
                        .onEnded { _ in
                            settings.hapticFeedback()
                            dividerInfo = boundaryDividerInfo(for: model)
                        }
                )
        )
        #endif
    }

    // Extracted from `body` so the large modifier chain stays under the Swift type-checker limit.
    private var surahCoreBody: some View {
        ScrollViewReader { proxy in
            ayahListScreen(proxy: proxy)
        }
        .environmentObject(quranPlayer)
        .onDisappear(perform: saveLastRead)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .inactive:
                // Pulling Control Center / Notification Center down briefly flips the scene to `.inactive`.
                // Only remember the current spot in memory here - writing `settings.lastRead*` (@AppStorage)
                // republishes the view tree and can reconstruct this screen mid-scroll, jumping the user
                // away from where they were. The in-memory anchor is enough to restore on re-appear.
                rememberCurrentVisibleAyah()
            case .background:
                saveLastRead()
            default:
                break
            }
        }
    }

    /// Page mode swaps the ayah list for the swipeable mushaf pages; everything wrapped around it (toolbar,
    /// sheets, dialogs) is shared by both.
    @ViewBuilder
    private var surahReadingBody: some View {
        #if os(iOS)
        if settings.quranPageMode {
            // The reader owns the bottom stack: these controls sit ABOVE its page-navigation footer, which
            // stays pinned at the very bottom.
            SurahPageReader(
                surah: surah,
                initialAyah: ayah,
                jumpToken: pageJumpToken,
                onSurahChange: { pageSurah = $0 },
                onPageAnchor: { surahID, ayahID in pageAnchor = (surahID, ayahID) },
                highlightedAyah: $highlightedAyah,
                searchActive: $pageSearchActive,
                arrivalHighlight: {
                    guard let term = arrivalTerm, let target = arrivalAyahID else { return nil }
                    return (ref: HighlightedAyahRef(surahID: surah.id, ayahID: target), term: term)
                }(),
                onClearArrival: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        arrivalTerm = nil
                        arrivalAyahID = nil
                    }
                },
                isSelecting: isSelectingAyahs,
                selectedAyahIDs: selectedAyahIDs,
                onToggleSelection: { ayahID in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        if selectedAyahIDs.contains(ayahID) {
                            selectedAyahIDs.remove(ayahID)
                        } else {
                            selectedAyahIDs.insert(ayahID)
                        }
                    }
                },
                onPageTurned: {
                    selectedAyahIDs = []
                    arrivalTerm = nil
                    arrivalAyahID = nil
                },
                onChooseReciter: {
                    showReciterPickerSheet = true
                }
            ) {
                let active = quranPlayer.isPlaying || quranPlayer.isPaused
                VStack(spacing: 0) {
                    // Select mode swaps the search cluster for the bulk-action bar, exactly like the list.
                    if isSelectingAyahs {
                        selectionActionBar
                    } else {
                    // Always present in page mode: search sits dead center, with the tajweed legend and the
                    // riwayah picker flanking it when they apply (an English page shows neither, so the bar
                    // is just the search).
                    pageBottomControlsBar
                    }

                    if active {
                        NowPlayingView(quranView: false)
                            .padding(.horizontal, 24)
                            .padding(.top, SafeAreaInsetVStackSpacing.standard)
                            .transition(.opacity)
                    }
                }
                // Same breathing room the list reader gives this bar - and here the bottom padding is
                // also what separates it from the page-navigation footer pinned underneath.
                .padding(.top, SafeAreaInsetVStackSpacing.standard)
                .padding(.bottom, SafeAreaInsetVStackSpacing.standard)
                .background(Color.white.opacity(0.00001))
                .animation(.easeInOut, value: active)
            }
            // No `.id(surah.id)` here, deliberately: identity-swapping the reader tore down and rebuilt the
            // ~604-page UIPageViewController - the single heaviest view realization in the app (~900ms) -
            // on EVERY surah jump. The reader now re-seeds its own page index when `surah.id` changes
            // (see its `.onChange`), keeping the pager alive.
        } else {
            surahCoreBody
                // Back in list mode the title is fixed to this view's own surah again.
                .onAppear { pageSurah = nil }
        }
        #else
        surahCoreBody
        #endif
    }

    var body: some View {
        #if os(iOS)
        // The centered title is now a Menu (Surah List / Surah Info / Revelation Info), so the toolbar
        // only carries the principal title and the trailing settings gear.
        applySurahToolbar(to: surahReadingBody)
        .onAppear {
            quranPlayer.recordReadingHistory(surahNumber: surah.id, surahName: surah.nameTransliteration, ayahNumber: ayah ?? 1)
            if !didRecordOpen {
                didRecordOpen = true
                settings.recordSurahOpened(surah.id)
            }
            // A text-search hit travels with its query: the target ayah shows the matched snippet in
            // accent (list and page alike) until the reader touches it.
            if let target = ayah, let term = AyahArrivalTerm.shared.consume(surahID: surah.id, ayahID: target) {
                arrivalTerm = term
                arrivalAyahID = target
            }
            // Opening to a specific ayah SELECTS it, in page AND list mode alike - a bookmark, a
            // "5:6"-style search, or a widget can land mid-surah, and the selection is what shows you
            // where you landed. It stays until tapped.
            if let target = ayah {
                highlightedAyah = HighlightedAyahRef(surahID: surah.id, ayahID: target)
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            settingsSheet
                .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showSurahInfoSheet) {
            SurahInfoSheet(surahName: displayedSurah.nameTransliteration, surahNumber: displayedSurah.id)
                .environmentObject(settings)
                .environmentObject(quranData)
        }
        .sheet(isPresented: $showBulkNoteSheet) {
            // One note, applied to every selected ayah (each becomes a bookmarked ayah carrying it).
            NoteEditorSheet(
                title: "Note for \(selectedAyahIDs.count) Ayahs",
                text: $bulkNoteDraft,
                onAttemptSave: { text in
                    if textContainsProfanity(text) {
                        showBulkRespectAlert = true
                        return false
                    }
                    withAnimation(.easeInOut) {
                        for id in selectedAyahIDs {
                            settings.setBookmarkNote(surah: surah.id, ayah: id, note: text)
                        }
                    }
                    return true
                },
                onCancel: {},
                onSave: {}
            )
            .smallMediumSheetPresentation()
        }
        .confirmationDialog("Remove \(selectedAyahIDs.count) bookmarks?", isPresented: $confirmBulkUnbookmark, titleVisibility: .visible) {
            Button("Remove (notes will be deleted)", role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    for id in selectedAyahIDs { settings.toggleBookmark(surah: surah.id, ayah: id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Some of the selected ayahs have notes attached to their bookmarks; removing the bookmarks deletes those notes.")
        }
        .confirmationDialog("Note not saved", isPresented: $showBulkRespectAlert, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text("Please keep notes Islamic and respectful.")
        }
        .sheet(isPresented: $showSurahPickerSheet) {
            // `displayedSurah`, not `surah`: in page mode the reader roams freely, so the surah on
            // SCREEN (pageSurah) is the one the picker must treat as current - comparing against the
            // surah the reader was merely opened from made "Choose Surah" a silent no-op whenever the
            // pick matched it (most commonly: paging away and picking the starting surah to go back).
            SurahPickerSheet(currentSurahID: displayedSurah.id) { selectedSurah in
                settings.hapticFeedback()
                showSurahPickerSheet = false

                guard selectedSurah.id != displayedSurah.id else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    navigateToSurah(selectedSurah)
                }
            }
            .environmentObject(settings)
            .environmentObject(quranData)
            .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showCustomRangeSheet) {
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: 1,
                initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                    startAyah: 1,
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
                },
                onCancel: { showCustomRangeSheet = false }
            )
            .environmentObject(settings)
            .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showReciterPickerSheet) {
            NavigationView {
                ReciterListView(dismissAfterSelectingReciter: true, autoScrollToInitialSelection: false)
                    .environmentObject(settings)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                settings.hapticFeedback()
                                showReciterPickerSheet = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body.weight(.semibold))
                            }
                            .tint(settings.accentColor.color)
                        }
                    }
            }
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
        .confirmationDialog(
            dividerInfo?.title ?? "Boundary",
            isPresented: Binding(
                get: { dividerInfo != nil },
                set: { if !$0 { dividerInfo = nil } }
            ),
            presenting: dividerInfo
        ) { _ in
            Button("OK") {
                dividerInfo = nil
            }
        } message: { info in
            Text(info.message)
        }
        .confirmationDialog(
            surahInfoDialog?.title ?? "Surah Info",
            isPresented: Binding(
                get: { surahInfoDialog != nil },
                set: { if !$0 { surahInfoDialog = nil } }
            ),
            presenting: surahInfoDialog
        ) { _ in
            Button("OK") {
                surahInfoDialog = nil
            }
        } message: { info in
            Text(info.message)
        }
        .onChange(of: quranPlayer.showInternetAlert) { if $0 { showAlert = true; quranPlayer.showInternetAlert = false } }
        .confirmationDialog(quranPlayer.playbackAlertTitle, isPresented: $showAlert, titleVisibility: .visible) {
            if let offer = quranPlayer.offlineReciterSwitch {
                Button("Play \(offer.suggested.name)") { quranPlayer.acceptOfflineReciterSwitch() }
            }
            Button("OK") { quranPlayer.offlineReciterSwitch = nil }
        } message: {
            Text(quranPlayer.playbackAlertMessage)
        }
        .background(
            NavigationLink(
                destination: selectedSurahNavigationDestination,
                isActive: Binding(
                    get: { selectedSurahNavigation != nil },
                    set: { isActive in
                        if !isActive {
                            selectedSurahNavigation = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        #else
        surahCoreBody
            .navigationTitle("\(surah.id) - \(surah.nameTransliteration)")
        #endif
    }

    private func ayahListScreen(proxy: ScrollViewProxy) -> some View {
        let cleanQuery = settings.cleanSearch(searchText, whitespace: true)
        // Mirror QuranView: an Arabic query also matches the silent-letter stripped form (the matching
        // silent forms are folded into the search blob above). Always on - the fold is strictly additive.
        let silentQuery: String? = searchText.containsArabicLetters
            ? settings.cleanSearchIgnoringSilentArabicLetters(searchText, whitespace: true)
            : nil
        let booleanGroups = booleanAyahSearchGroups(from: searchText)
        let pageJuzQuery = parsePageJuzQuery(from: searchText)
        let ayahNumberQuery = parseAyahNumberQuery(from: searchText)
        let trimmedLowerSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let dividerKeywordMode: DividerKeywordMode? = {
            if trimmedLowerSearch == "page" || trimmedLowerSearch == "pages" { return .page }
            if trimmedLowerSearch == "juz" { return .juz }
            return nil
        }()
        let isDividerKeywordSearch = dividerKeywordMode != nil
        let isPageOrJuzSearch = pageJuzQuery.page != nil || pageJuzQuery.juz != nil
        // During a page/juz search the divider IS the context (it tells you which page/juz you're looking
        // at), so always show it then - regardless of the user's normal show-page/juz-dividers preference,
        // which only governs reading (searchText empty).
        let showBoundaryDividers = isPageOrJuzSearch || isDividerKeywordSearch || (settings.showPageJuzDividers && searchText.isEmpty)
        let prepared = cachedAyahsForQiraah.isEmpty ? Self.preparedCache(for: surah, settings: settings) : nil
        let ayahsForQiraah = cachedAyahsForQiraah.isEmpty
            ? (prepared?.ayahs ?? [])
            : cachedAyahsForQiraah
        let ayahByID = cachedAyahByID.isEmpty
            ? (prepared?.ayahByID ?? [:])
            : cachedAyahByID
        let shouldUseTextSearchBlobs = !cleanQuery.isEmpty
            && !isDividerKeywordSearch
            && !isPageOrJuzSearch
            && ayahNumberQuery == nil
        let searchBlobByAyahID = shouldUseTextSearchBlobs
            ? (cachedSearchBlobByAyahID.isEmpty
                ? Self.preparedSearchCache(for: surah, settings: settings, ayahs: ayahsForQiraah).searchBlobByAyahID
                : cachedSearchBlobByAyahID)
            : [:]
        let filteredAyahs: [Ayah] = {
            guard !cleanQuery.isEmpty else { return ayahsForQiraah }
            if isDividerKeywordSearch { return [] }

            return ayahsForQiraah.filter { a in
                if isPageOrJuzSearch {
                    let pageMatch = pageJuzQuery.page != nil && a.page == pageJuzQuery.page
                    let juzMatch = pageJuzQuery.juz != nil && a.juz == pageJuzQuery.juz
                    return pageMatch || juzMatch
                }

                if let ayahNumberQuery {
                    return a.id == ayahNumberQuery
                }

                if let blob = searchBlobByAyahID[a.id] {
                    if let booleanGroups {
                        if booleanGroups.isEmpty { return false }
                        return matchesBooleanAyahSearch(ayah: a, haystack: blob, groups: booleanGroups)
                    }
                    if blob.contains(cleanQuery) { return true }
                    return silentQuery.map { !$0.isEmpty && blob.contains($0) } ?? false
                }

                var fallbackParts = [
                    settings.cleanSearch(a.textArabic),
                    settings.cleanSearch(a.textCleanArabic),
                    settings.cleanSearch(a.textTransliteration),
                    settings.cleanSearch(a.textEnglishSaheeh),
                    settings.cleanSearch(a.textEnglishMustafa),
                    settings.cleanSearch(String(a.id)),
                    settings.cleanSearch(a.idArabic)
                ]
                if silentQuery != nil {
                    fallbackParts.append(settings.cleanSearchIgnoringSilentArabicLetters(a.textArabic))
                    fallbackParts.append(settings.cleanSearchIgnoringSilentArabicLetters(a.textCleanArabic))
                }
                let fallbackBlob = fallbackParts.joined(separator: " ")

                if let booleanGroups {
                    if booleanGroups.isEmpty { return false }
                    return matchesBooleanAyahSearch(ayah: a, haystack: fallbackBlob, groups: booleanGroups)
                }

                if fallbackBlob.contains(cleanQuery) { return true }
                return silentQuery.map { !$0.isEmpty && fallbackBlob.contains($0) } ?? false
            }
        }()
        let boundaryModel = showBoundaryDividers ? quranData.boundaryModel(forSurah: surah.id) : nil
        let trailingSearchBoundaryDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, isPageOrJuzSearch, !isDividerKeywordSearch else { return nil }
            guard let boundaryModel else { return nil }
            guard let lastFilteredAyahID = filteredAyahs.last?.id else { return nil }

            if let idx = ayahsForQiraah.firstIndex(where: { $0.id == lastFilteredAyahID }) {
                let nextIndex = ayahsForQiraah.index(after: idx)
                if nextIndex < ayahsForQiraah.endIndex {
                    let nextAyah = ayahsForQiraah[nextIndex]
                    return boundaryModel.dividerBeforeAyah[nextAyah.id]
                }
            }

            return boundaryModel.endDivider
        }()
        let trailingSearchBoundaryScrollTarget: Int? = {
            guard showBoundaryDividers, isPageOrJuzSearch, !isDividerKeywordSearch else { return nil }
            guard let boundaryModel else { return nil }
            guard let lastFilteredAyahID = filteredAyahs.last?.id else { return nil }

            if let idx = ayahsForQiraah.firstIndex(where: { $0.id == lastFilteredAyahID }) {
                let nextIndex = ayahsForQiraah.index(after: idx)
                if nextIndex < ayahsForQiraah.endIndex {
                    let nextAyah = ayahsForQiraah[nextIndex]
                    if boundaryModel.dividerBeforeAyah[nextAyah.id] != nil {
                        return nextAyah.id
                    }
                }
            }
            if boundaryModel.endDivider != nil {
                return ayahsForQiraah.last?.id
            }
            return nil
        }()
        let startOfSurahDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers else { return nil }
            if searchText.isEmpty { return boundaryModel?.startDivider }
            // Page/juz search: the surah's first ayah has no `dividerBeforeAyah` entry, so when the searched
            // page/juz is the one the surah begins on (first ayah is in the results), surface the start
            // divider too - otherwise the "Page X • Juz Y" header is missing for that first page.
            if isPageOrJuzSearch,
               let firstID = ayahsForQiraah.first?.id,
               filteredAyahs.contains(where: { $0.id == firstID }) {
                return boundaryModel?.startDivider
            }
            return nil
        }()
        let endOfSurahDivider: BoundaryDividerModel? = {
            guard showBoundaryDividers, searchText.isEmpty else { return nil }
            return boundaryModel?.endOfSurahDivider
        }()
        let previousSurah = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? neighboringSurah(before: surah.id) : nil
        let nextSurah = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? neighboringSurah(after: surah.id) : nil
        // The floating page/juz overlay is always shown when boundary dividers exist; there is no
        // separate opt-in setting for it anymore.
        let shouldShowFloatingPageJuzOverlay = showBoundaryDividers && searchText.isEmpty
        let shouldUpdateFloatingPageJuzOverlay = shouldShowFloatingPageJuzOverlay && surah.pageOrJuzChangesWithinSurah
        // (The floating page/juz model and the ayah progress fraction are derived INSIDE the pinned
        // header's `ReaderPinnedHeader` closure now - they read the scroll anchor, and deriving them
        // here would re-run this whole body on every scroll tick.)
        let keywordDividerModels: [BoundaryDividerModel] = {
            guard let mode = dividerKeywordMode else { return [] }
            guard let boundaryModel else { return [] }

            var allDividerModels: [BoundaryDividerModel] = []

            if let start = boundaryModel.startDivider {
                allDividerModels.append(start)
            }

            for ayah in ayahsForQiraah {
                if let model = boundaryModel.dividerBeforeAyah[ayah.id] {
                    allDividerModels.append(model)
                }
            }

            if let end = boundaryModel.endDivider {
                allDividerModels.append(end)
            }

            var seen = Set<String>()
            return allDividerModels.filter { model in
                let matches: Bool
                let dedupeKey: String
                switch mode {
                case .page:
                    matches = model.text.localizedCaseInsensitiveContains("Page")
                    dedupeKey = model.text
                case .juz:
                    matches = model.text.localizedCaseInsensitiveContains("Juz")
                    dedupeKey = model.juzSegment
                        ?? (model.pageSegment.localizedCaseInsensitiveContains("Juz") ? model.pageSegment : model.text)
                }
                guard matches else { return false }
                return seen.insert(dedupeKey).inserted
            }
        }()
        let searchCount = isDividerKeywordSearch ? keywordDividerModels.count : filteredAyahs.count
        // (Anchor syncing lives in AyahVisibilityModel.syncDerived now - a set mutation derives and
        // publishes it there, without touching this view's state.)

        return
            List {
                Group {
                khatmProgressSection()
                qiraahNoticeSection()

                Section {
                    /*SurahRow(surah: surah, hideInfo: true).equatable()
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 0.45) {
                            settings.hapticFeedback()
                            surahInfoDialog = surahInfoDialog(for: surah)
                        }*/
                } header: {
                    // The surah header now lives in the always-pinned top safeAreaInset, so this section
                    // header only carries the search results-count pill (trailing, visible while searching).
                    // watchOS has no safeAreaInset header, so it keeps the header here - its removal in
                    // 4.5.0 (when the header moved into the iOS-only inset) was a regression.
                    #if os(watchOS)
                    if searchText.isEmpty {
                        SurahSectionHeader(surah: surah)
                    }
                    #endif
                    if !searchText.isEmpty {
                        HStack {
                            Spacer()

                            Text(String(searchCount))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .conditionalGlassEffect()
                        }
                        .animation(.easeInOut, value: searchText)
                        .transition(.opacity)
                        .padding(.vertical, -12)
                    }
                }

                #if !os(watchOS)
                if previousSurah != nil || nextSurah != nil {
                    Section {
                        surahNavigationButtonPair(previous: previousSurah, next: nextSurah)
                    }
                    .id(Self.navTopAnchorID)
                }
                #endif

                Section {
                    VStack {
                        let firstAyahClean = ayahsForQiraah.first?.textCleanArabic.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let showTaawwudh = (surah.id == 9) || (surah.id == 1 && firstAyahClean.hasPrefix("بسم"))
                        if showTaawwudh {
                            HeaderRow(
                                arabicText: "أَعُوذُ بِٱللَّهِ مِنَ ٱلشَّيۡطَانِ ٱلرَّجِيمِ",
                                englishTransliteration: "Audhu billahi minashaitanir rajeem",
                                englishTranslation: "I seek refuge in Allah from the accursed Satan."
                            )
                        } else {
                            HeaderRow(
                                arabicText: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِِ",
                                englishTransliteration: "Bismi Allahi alrrahmani alrraheemi",
                                englishTranslation: "In the name of Allah, the Compassionate, the Merciful."
                            )
                        }
                    }
                }
                .id(Self.headerRowAnchorID)

                if isDividerKeywordSearch {
                    ForEach(Array(keywordDividerModels.enumerated()), id: \.offset) { _, dividerModel in
                        Section {
                            if let bm = boundaryModel {
                                listBoundaryDivider(
                                    model: dividerModel,
                                    nextAyahID: scrollTargetAyahID(
                                        forDivider: dividerModel,
                                        boundaryModel: bm,
                                        ayahsForQiraah: ayahsForQiraah
                                    ),
                                    showAyahPreview: true
                                )
                            } else {
                                listBoundaryDivider(model: dividerModel, nextAyahID: nil)
                            }
                        }
                    }
                } else {
                    if let startOfSurahDivider {
                        Section {
                            listBoundaryDivider(model: startOfSurahDivider, nextAyahID: ayahsForQiraah.first?.id, showAyahLabel: false)
                        }
                        .onAppear {
                            if shouldUpdateFloatingPageJuzOverlay, let nextID = filteredAyahs.first?.id {
                                visibility.visibleBoundaryAyahIDs.insert(nextID)
                            }
                        }
                        .onDisappear {
                            if shouldUpdateFloatingPageJuzOverlay, let nextID = filteredAyahs.first?.id {
                                visibility.visibleBoundaryAyahIDs.remove(nextID)
                            }
                        }
                    }

                    ForEach(filteredAyahs, id: \.id) { ayah in
                        let dividerBefore = showBoundaryDividers ? boundaryModel?.dividerBeforeAyah[ayah.id] : nil

                        if let dividerBefore {
                            Section {
                                listBoundaryDivider(model: dividerBefore, nextAyahID: ayah.id, showAyahLabel: false)
                            }
                            .onAppear {
                                if shouldUpdateFloatingPageJuzOverlay {
                                    visibility.visibleBoundaryAyahIDs.insert(ayah.id)
                                }
                            }
                            .onDisappear {
                                if shouldUpdateFloatingPageJuzOverlay {
                                    visibility.visibleBoundaryAyahIDs.remove(ayah.id)
                                }
                            }
                        }

                        Group {
                            #if os(iOS)
                            Section {
                                AyahRow(
                                    surah: surah,
                                    ayah: ayah,
                                    renderSettingsSignature: ayahRowRenderSettingsSignature,
                                    scrollDown: $scrollDown,
                                    searchText: $searchText,
                                    arrivalTerm: arrivalAyahID == ayah.id ? (arrivalTerm ?? "") : "",
                                    isHighlighted: isAyahHighlighted(ayah.id),
                                    onToggleHighlight: { toggleListHighlight(ayah.id) },
                                    isSelecting: isSelectingAyahs,
                                    isSelected: selectedAyahIDs.contains(ayah.id),
                                    forceBeginner: beginnerAyahIDs.contains(ayah.id),
                                    onToggleSelection: {
                                        if selectedAyahIDs.contains(ayah.id) {
                                            selectedAyahIDs.remove(ayah.id)
                                        } else {
                                            selectedAyahIDs.insert(ayah.id)
                                        }
                                    },
                                    onAyahTextAppear: {
                                        visibility.visibleAyahIDs.insert(ayah.id)
                                        markKhatmViewedIfNeeded(ayah.id)
                                    },
                                    onAyahTextDisappear: {
                                        visibility.visibleAyahIDs.remove(ayah.id)
                                    },
                                    isPlayingThis: quranPlayer.currentSurahNumber == surah.id
                                        && quranPlayer.currentAyahNumber == ayah.id
                                )
                                .equatable()
                            }
                            #else
                            AyahRow(
                                surah: surah,
                                ayah: ayah,
                                renderSettingsSignature: ayahRowRenderSettingsSignature,
                                scrollDown: $scrollDown,
                                searchText: $searchText,
                                isHighlighted: isAyahHighlighted(ayah.id),
                                onToggleHighlight: { toggleListHighlight(ayah.id) },
                                onAyahTextAppear: {
                                    visibility.visibleAyahIDs.insert(ayah.id)
                                    markKhatmViewedIfNeeded(ayah.id)
                                },
                                onAyahTextDisappear: {
                                    visibility.visibleAyahIDs.remove(ayah.id)
                                },
                                isPlayingThis: quranPlayer.currentSurahNumber == surah.id
                                    && quranPlayer.currentAyahNumber == ayah.id
                            )
                            .equatable()
                            #endif
                        }
                        .id(ayah.id)
                        #if os(watchOS)
                        .padding(.vertical)
                        #endif
                    }

                    if let endOfSurahDivider {
                        Section {
                            listBoundaryDivider(model: endOfSurahDivider, nextAyahID: nil)
                        }
                    }

                    #if !os(watchOS)
                    if previousSurah != nil || nextSurah != nil {
                        Section {
                            surahNavigationButtonPair(previous: previousSurah, next: nextSurah)
                                // Only the BOTTOM pair marks "reached the end" - it sits below the last
                                // ayah, so its appearance is what fills the progress bar.
                                .onAppear { visibility.nextSurahButtonVisible = true }
                                .onDisappear { visibility.nextSurahButtonVisible = false }
                        }
                    }
                    #endif

                    if let trailingSearchBoundaryDivider {
                        Section {
                            listBoundaryDivider(
                                model: trailingSearchBoundaryDivider,
                                nextAyahID: trailingSearchBoundaryScrollTarget,
                                showAyahLabel: false
                            )
                        }
                    }
                }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle(disableNowPlayingInset: true, topContentMargin: 11)
            // Apple Music-style: the bottom bars minimize while scrolling down, restore on scroll-up.
            .collapseBarsOnScroll($barsCollapsed)
            .compactListSectionSpacing()
            #if os(iOS)
            .onChange(of: scrollDown) { value in
                guard let target = value else { return }
                // A tap on a matched row (from search): keep the row easy to spot once the search clears.
                // A TEXT query keeps its accent-colored snippet on the row (until touched); a reference
                // query ("5:3", "page 12") has nothing to color, so it gets the grey tint as before.
                let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let isTextQuery = !trimmedQuery.isEmpty && trimmedQuery.rangeOfCharacter(from: .decimalDigits) == nil
                if isTextQuery {
                    arrivalTerm = trimmedQuery
                    arrivalAyahID = target
                }
                // Reference queries ("5:3") get the selection tint too - the landing alone is easy to
                // lose once the list settles, so mark it like any other search arrival.
                highlightedAyah = HighlightedAyahRef(surahID: surah.id, ayahID: target)
                if !searchText.isEmpty {
                    settings.hapticFeedback()
                    pendingScrollAfterSearchClear = target
                    withAnimation {
                        searchText = ""
                        self.endEditing()
                    }
                } else {
                    DispatchQueue.main.async {
                        withAnimation { proxy.scrollTo(target, anchor: .top) }
                    }
                }
                scrollDown = nil
            }
            .onChange(of: searchText) { newValue in
                guard newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let target = pendingScrollAfterSearchClear else { return }
                pendingScrollAfterSearchClear = nil
                DispatchQueue.main.async {
                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                }
            }
            #endif
            .onAppear {
                rebuildQiraahCaches()
                // Always open at the requested ayah (or the top for a whole-surah open). Navigating to a
                // surah/ayah should refresh to that target rather than restoring wherever the user last
                // scrolled on a previous visit.
                let target = ayah.flatMap { nearestExistingAyahID($0, in: ayahsForQiraah.map { $0.id }) }
                if let target {
                    visibility.setAnchor(target)
                    if !didScrollDown {
                        didScrollDown = true
                        scrollToAyah(target, proxy: proxy)
                        // Any targeted arrival selects its ayah - for a text search the accent snippet
                        // shows the match and the selection shows the landing; a "5:6" reference has only
                        // the selection. One tap clears it.
                        highlightedAyah = HighlightedAyahRef(surahID: surah.id, ayahID: target)
                    }
                } else if visibility.firstVisibleAyahID == nil {
                    visibility.setAnchor(ayahsForQiraah.first?.id)
                }
            }
            .onChange(of: quranPlayer.currentAyahNumber) { newVal in
                if let id = newVal, surah.id == quranPlayer.currentSurahNumber {
                    withAnimation { proxy.scrollTo(id, anchor: .top) }
                }
            }
            .onChange(of: settings.displayQiraah) { _ in
                cacheQiraahKey = ""
                qiraahCacheSurahID = nil
                rebuildQiraahCaches()
                visibility.resetScrollTracking()
            }
            .onChange(of: surah.id) { _ in
                rebuildQiraahCaches()
                visibility.resetScrollTracking()
                didScrollDown = false
                visibility.nextSurahButtonVisible = false
                let prepared = Self.preparedCache(for: surah, settings: settings)
                if let sel = ayah, let target = nearestExistingAyahID(sel, in: prepared.ayahs.map { $0.id }) {
                    visibility.setAnchor(target)
                    scrollToAyah(target, proxy: proxy)
                } else if let top = prepared.ayahs.first?.id {
                    visibility.setAnchor(top)
                    // Previous/Next lands at the LITERAL top - nav buttons and surah header included -
                    // not at ayah 1 with everything above it hidden.
                    scrollToListTop(proxy: proxy)
                }
            }
            .onChange(of: ayah) { newValue in
                guard let newValue,
                      let target = nearestExistingAyahID(newValue, in: cachedAyahsForQiraah.map { $0.id }) else { return }
                visibility.setAnchor(target)
                didScrollDown = true
                scrollToAyah(target, proxy: proxy)
                if let term = AyahArrivalTerm.shared.consume(surahID: surah.id, ayahID: newValue) {
                    arrivalTerm = term
                    arrivalAyahID = target
                }
                // A route re-target (another search hit while this surah is open) selects its ayah; a
                // list ↔ page mode switch does not - that would mark an ayah the user never chose.
                if modeSwitchAyah == nil {
                    highlightedAyah = HighlightedAyahRef(surahID: surah.id, ayahID: target)
                }
            }
            #if os(iOS)
            // Always-pinned header (safeAreaInset, not overlay): it reserves space so list content - and
            // the search results-count pill - sits below it rather than being hidden behind it.
            .safeAreaInset(edge: .top, spacing: 0) {
                // The ONLY observer of the scroll-visibility model: a viewport crossing re-renders
                // this strip, never the reader body. The captured locals (ayah caches, divider maps,
                // neighbors) refresh whenever the reader body legitimately re-runs.
                ReaderPinnedHeader(visibility: visibility) { anchorID, lastAyahVisible, footerVisible in
                    VStack(spacing: 0) {
                        // The ayah progress bar is attached full-width directly beneath the toolbar - not
                        // part of the floating pill - so it reads as the screen's own progress indicator.
                        // It fills by AYAH (not page), so it shows for every surah, including single-page
                        // ones. Full ONLY once the "Go to Next Surah" footer scrolls into view - the last
                        // ayah merely being visible isn't the end of the surah, the footer is. Surah 114
                        // has no next-surah button, so there the last ayah on screen is the finish line.
                        let barFraction: CGFloat? = {
                            guard searchText.isEmpty,
                                  let firstID = ayahsForQiraah.first?.id,
                                  let lastID = ayahsForQiraah.last?.id,
                                  lastID > firstID else { return nil }
                            if footerVisible { return 1 }
                            if nextSurah == nil, lastAyahVisible { return 1 }
                            let currentID = anchorID.flatMap { ayahByID[$0] }?.id ?? firstID
                            // Never quite full while scrolling: 100% is reserved for the footer.
                            return min(CGFloat(currentID - firstID) / CGFloat(lastID - firstID), 0.97)
                        }()
                        if let barFraction {
                            TrackedBar(
                                fraction: barFraction,
                                height: 3,
                                color: settings.accentColor.color
                            )
                            .transition(.opacity)
                        }

                        // The page/juz line is ALWAYS part of the pinned header (when dividers are on). It
                        // used to hide while the surah's first inline divider was on screen - but on short
                        // surahs that divider never leaves the screen, so the overlay never appeared at all.
                        let currentFloatingAyah = shouldUpdateFloatingPageJuzOverlay
                            ? (anchorID.flatMap { ayahByID[$0] } ?? ayahsForQiraah.first)
                            : ayahsForQiraah.first
                        let floatingDividerModel: BoundaryDividerModel? = {
                            guard shouldShowFloatingPageJuzOverlay else { return nil }
                            guard let currentFloatingAyah else { return nil }
                            return overlayDividerByAyahID[currentFloatingAyah.id]
                                ?? ayahsForQiraah.first.flatMap { overlayDividerByAyahID[$0.id] }
                        }()
                        floatingHeaderOverlay(
                            floatingDividerModel: floatingDividerModel,
                            floatingDividerAnimationKey: floatingDividerModel.map(boundaryDividerID) ?? "none"
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                let active = quranPlayer.isPlaying || quranPlayer.isPaused
                // Insert/remove the bar on isPlaying||isPaused with `.animation` so SwiftUI animates BOTH the
                // fade (the bar's `.transition`) and the height collapse natively. The bar keeps its content
                // while fading out via `retainedContext`, and "Stop Playing" defers `stop()`, so closing works.
                // Scroll-collapse is OFF: the legend/global/riwayah row stays put while scrolling.
                // (Was: `!barsCollapsed || isAyahSearchFocused` - restore to fold it away again.)
                let controlsVisible = true
                VStack(spacing: 0) {
                    // Apple Music-style: the secondary legend/global/riwayah row folds away while scrolling
                    // down. The row STAYS MOUNTED and collapses via height+opacity - an `if` removal
                    // snapshots the glass background as a hard black box on the way out (the same artifact
                    // the now-playing bar once had), because Liquid Glass can't participate in a removal
                    // transition.
                    qiraatAndTajweedControls
                        .frame(height: controlsVisible ? nil : 0)
                        .clipped()
                        .opacity(controlsVisible ? 1 : 0)
                        .allowsHitTesting(controlsVisible)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: controlsVisible)

                    if active {
                        nowPlayingInset(proxy: proxy)
                            .padding(.horizontal, 24)
                            .padding(.top, SafeAreaInsetVStackSpacing.standard)
                            .transition(.opacity)
                            // The mini player minimizes with the rest of the bars.
                            .minimizedBarStyle(barsCollapsed && !isAyahSearchFocused)
                    }
                }
                .padding(.bottom, 7)
                .background(Color.white.opacity(0.00001))
                .animation(.easeInOut, value: active)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            }
            .adaptiveSafeArea(edge: .bottom) {
                bottomInsetContent(proxy: proxy)
                    // Apple Music-style: the search/play row shrinks toward the bottom edge while scrolling
                    // down; typing in it always restores full size.
                    .minimizedBarStyle(barsCollapsed && !isAyahSearchFocused)
            }
            .confirmationDialog("Convert Qiraah to Hafs an Asim?", isPresented: $confirmConvertQiraahToHafs, titleVisibility: .visible) {
                Button("Yes") {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.displayQiraah = Settings.Riwayah.hafsTag
                    }
                }

                Button("No") {
                    settings.hapticFeedback()
                }
            } message: {
                Text("Are you sure? This will convert the qiraah back to Hafs an Asim.")
            }
            #else
            .confirmationDialog("Convert Qiraah to Hafs an Asim?", isPresented: $confirmConvertQiraahToHafs, titleVisibility: .visible) {
                Button("Yes") {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.displayQiraah = Settings.Riwayah.hafsTag
                    }
                }

                Button("No") {
                    settings.hapticFeedback()
                }
            } message: {
                Text("Are you sure? This will convert the qiraah back to Hafs an Asim.")
            }
            #endif
    }

    @ViewBuilder
    private func khatmProgressSection() -> some View {
        if shouldShowKhatmProgress {
            Section {
                if settings.isHafsDisplay {
                    VStack(alignment: .leading, spacing: 10) {
                        Color.clear.frame(height: 0).onAppear { computeKhatmOverviewIfNeeded(force: false) }

                        HStack(alignment: .firstTextBaseline) {
                            Label("\(khatmCompletedAyahCount)/\(surah.numberOfAyahs) ayahs", systemImage: khatmCompletedAyahCount >= surah.numberOfAyahs ? "checkmark.circle.fill" : "circle.dashed")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color.opacity(khatmCompletedAyahCount > 0 ? 1 : 0.65))

                            Spacer()

                            Text("\(khatmCompletionPercent)%")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: Double(khatmCompletedAyahCount), total: Double(max(surah.numberOfAyahs, 1)))
                            .tint(settings.accentColor.color)

                        HStack {
                            Text("Overall: \(khatmOverviewPercent)% completed")
                                .font(.subheadline)
                                .foregroundStyle(settings.accentColor.color)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    // Khatm tracking is Hafs-only (see `markKhatmAyahComplete` / `isKhatmAyahComplete`, both
                    // guarded by `isHafsDisplay`). On any other riwayah the bar would just sit at 0, so say
                    // why instead of showing a dead progress bar. The riwayah notice below has the switch button.
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(settings.accentColor.color)

                        Text("Khatm progress is only tracked on Hafs an Asim. Switch back to the default riwayah below to track this reading.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("KHATM PROGRESS")
            }
            .onReceive(settings.objectWillChange) { _ in computeKhatmOverviewIfNeeded(force: false) }
            .id(Self.khatmTopAnchorID)
        }
    }

    @ViewBuilder
    private func qiraahNoticeSection() -> some View {
        if !settings.isHafsDisplay {
            let option = Settings.Riwayah.option(for: settings.displayQiraah)
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "character.book.closed.fill.ar")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .frame(width: 34, height: 34)
                            .background(settings.accentColor.color.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Current Riwayah")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack {
                                Text(option.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text(option.arabic)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                        }

                        Spacer(minLength: 0)
                    }

                    Button {
                        settings.hapticFeedback()
                        confirmConvertQiraahToHafs = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Use Default Hafs an Asim")
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(settings.accentColor.color.opacity(0.11), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }
            .id(Self.qiraahTopAnchorID)
        }
    }

    private func computeKhatmOverviewIfNeeded(force: Bool = false) {
        let totalCompleted = settings.khatmTotalCompleted(in: quranData.quran)
        guard force || totalCompleted != khatmOverviewLastSignature else { return }
        khatmOverviewLastSignature = totalCompleted

        let totalAyahs = quranData.quran.reduce(0) { $0 + $1.numberOfAyahs }
        khatmOverviewPercent = totalAyahs > 0 ? Int((Double(totalCompleted) / Double(totalAyahs) * 100).rounded()) : 0
    }


    private func floatingHeaderOverlay(
        floatingDividerModel: BoundaryDividerModel?,
        floatingDividerAnimationKey: String
    ) -> some View {
        VStack(spacing: 2) {
            SurahSectionHeader(surah: surah)

            if let floatingDividerModel {
                boundaryDivider(model: floatingDividerModel, isOverlay: true)
                    .id(boundaryDividerID(floatingDividerModel))
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .animation(.easeInOut(duration: 0.18), value: floatingDividerAnimationKey)
            }
        }
        // Animate the page/juz line appearing/disappearing (it shows once the first divider scrolls off,
        // and updates as you move between pages) using the transition above.
        .animation(.easeInOut(duration: 0.2), value: floatingDividerModel != nil)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 0)
        // When both the surah header and the page/juz divider are stacked, use a rounded rectangle;
        // a lone header reads better as a capsule.
        .conditionalGlassEffect(rectangle: true)
        .padding(.top, 4)
        .padding(.horizontal, settings.defaultView ? 20 : 16)
        .zIndex(1)
    }

    #if os(iOS)
    @ViewBuilder
    private func bottomInsetContent(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            if isSelectingAyahs {
                selectionActionBar
            } else {
                playbackAndSearchControls(proxy: proxy)
            }
        }
    }

    // MARK: - Multi-select bulk actions

    private var selectedAyahsSorted: [Ayah] {
        cachedAyahsForQiraah.filter { selectedAyahIDs.contains($0.id) }
    }

    private var allSelectedBookmarked: Bool {
        !selectedAyahIDs.isEmpty && selectedAyahIDs.allSatisfy { settings.isBookmarked(surah: surah.id, ayah: $0) }
    }

    private var allSelectedBeginner: Bool {
        !selectedAyahIDs.isEmpty && selectedAyahIDs.allSatisfy { beginnerAyahIDs.contains($0) }
    }

    private var selectionActionBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(selectedAyahIDs.count) selected")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()

                Spacer()

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        if selectedAyahIDs.count == cachedAyahsForQiraah.count {
                            selectedAyahIDs = []
                        } else {
                            selectedAyahIDs = Set(cachedAyahsForQiraah.map { $0.id })
                        }
                    }
                } label: {
                    Text(selectedAyahIDs.count == cachedAyahsForQiraah.count ? "Deselect All" : "Select All")
                        .font(.caption.weight(.semibold))
                        .contentShape(Rectangle())
                }

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        isSelectingAyahs = false
                        selectedAyahIDs = []
                    }
                } label: {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .contentShape(Rectangle())
                }
            }
            .foregroundColor(settings.accentColor.color)

            HStack(spacing: 0) {
                bulkActionButton("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = bulkSelectionText()
                }
                bulkActionButton("Share", systemImage: "square.and.arrow.up") {
                    presentSystemShareSheet(items: [bulkSelectionText()])
                }
                bulkActionButton(allSelectedBookmarked ? "Unbookmark" : "Bookmark",
                                 systemImage: allSelectedBookmarked ? "bookmark.fill" : "bookmark") {
                    bulkToggleBookmarks()
                }
                bulkActionButton("Note", systemImage: "square.and.pencil") {
                    bulkNoteDraft = ""
                    showBulkNoteSheet = true
                }
                bulkActionButton("Beginner", systemImage: allSelectedBeginner ? "textformat.size.larger" : "textformat.size") {
                    withAnimation(.easeInOut) {
                        if allSelectedBeginner {
                            beginnerAyahIDs.subtract(selectedAyahIDs)
                        } else {
                            beginnerAyahIDs.formUnion(selectedAyahIDs)
                        }
                    }
                }
            }
            .disabled(selectedAyahIDs.isEmpty)
            .opacity(selectedAyahIDs.isEmpty ? 0.45 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func bulkActionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))

                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity)
            // The whole equal-width slot is tappable, not just the glyph's own ink.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The combined text of every selected ayah: reference, Arabic, and whichever translations the reader
    /// has enabled - the bulk counterpart of copying a single ayah.
    private func bulkSelectionText() -> String {
        selectedAyahsSorted.map { ayah in
            var parts: [String] = ["[\(surah.nameTransliteration) \(surah.id):\(ayah.id)]"]
            parts.append(ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
            if settings.isHafsDisplay {
                if settings.showTransliteration, !ayah.textTransliteration.isEmpty {
                    parts.append(ayah.textTransliteration)
                }
                if settings.showEnglishSaheeh, !ayah.textEnglishSaheeh.isEmpty {
                    parts.append(ayah.textEnglishSaheeh)
                }
                if settings.showEnglishMustafa, !ayah.textEnglishMustafa.isEmpty {
                    parts.append(ayah.textEnglishMustafa)
                }
            }
            return parts.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    /// Bookmark semantics for a mixed selection: anything unbookmarked -> bookmark everything; all already
    /// bookmarked -> remove them (behind a confirmation when any would lose its note).
    private func bulkToggleBookmarks() {
        if allSelectedBookmarked {
            let anyNotes = selectedAyahIDs.contains { settings.bookmarkHasNote(surah: surah.id, ayah: $0) }
            if anyNotes {
                confirmBulkUnbookmark = true
            } else {
                withAnimation(.easeInOut) {
                    for id in selectedAyahIDs { settings.toggleBookmark(surah: surah.id, ayah: id) }
                }
            }
        } else {
            withAnimation(.easeInOut) {
                for id in selectedAyahIDs { settings.ensureBookmarkExists(surah: surah.id, ayah: id) }
            }
        }
    }

    /// The page reader's bottom bar: whole-Quran search always dead center, the tajweed legend and riwayah
    /// picker flanking it when they apply. English page text renders neither tajweed nor qiraat, so those
    /// two hide - the ZStack keeps the search centered whatever survives around it.
    private var pageBottomControlsBar: some View {
        let arabicPage = !settings.resolvedMushafPageLanguage.isEnglish
        let tajweedCanRenderNow = arabicPage
            && settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay
        let comparisonVisible = arabicPage && settings.qiraatComparisonMode

        // The search button only appears alongside the tajweed legend or the riwayah picker - with
        // neither enabled the bar shows nothing at all. It stretches to fill whatever width the flanking
        // controls leave, at their exact height (caption text + 8pt vertical padding).
        return Group {
            if tajweedCanRenderNow || comparisonVisible {
                HStack(alignment: .bottom, spacing: 4) {
                    // The legend and the riwayah picker take exactly the space THEY need (layoutPriority +
                    // fixed-size labels); the search stretches into whatever is left over - and when there
                    // isn't enough, it is the one that shrinks, scaling its label down first.
                    if tajweedCanRenderNow {
                        TajweedLegendMenu()
                            .layoutPriority(1)
                    }

                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { pageSearchActive = true }
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(settings.accentColor.accent1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity)
                            .conditionalGlassEffect()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Search this page")

                    if comparisonVisible {
                        ArabicTextRiwayahPicker(selection: $settings.displayQiraah.animation(.easeInOut))
                            .layoutPriority(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private var qiraatAndTajweedControls: some View {
        let tajweedCanRenderNow = settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay

        // Same shape as the page reader's bar: the global search only appears alongside the tajweed
        // legend or the riwayah picker, stretches between them, and matches their height. Labeled
        // "Global" because this reader has its own search bar right below, and this button is the "take
        // what I typed THERE" escape to the whole Quran.
        if tajweedCanRenderNow || settings.qiraatComparisonMode {
            HStack(alignment: .bottom, spacing: 4) {
                // Same rule as the page bar: the flanking controls take the space they need, the search
                // fills the leftover and is the first to shrink when the row runs tight.
                if tajweedCanRenderNow {
                    TajweedLegendMenu()
                        .layoutPriority(1)
                }

                Button {
                    settings.hapticFeedback()
                    QuranSearchHandoff.shared.request(searchText)
                } label: {
                    Label("Global", systemImage: "magnifyingglass")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.accent1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .conditionalGlassEffect()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search the whole Quran for what is typed in the search bar")

                if settings.qiraatComparisonMode {
                    ArabicTextRiwayahPicker(selection: $settings.displayQiraah.animation(.easeInOut))
                        .layoutPriority(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 24)
        }
    }

    private func playbackAndSearchControls(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            HStack(spacing: 0) {
                SearchBar(
                    // Animated again - results sliding in/out is part of the reader's feel. Low Power
                    // Mode keeps the plain binding (under its CPU throttle the whole-list animated diff
                    // stalled long enough to read as a crash), and Reduce Motion joins it via the shared
                    // gate. The actual hard crash was elsewhere - duplicate result ids in the global
                    // search's animated apply, fixed in QuranView.
                    text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                    onFocusChanged: { focused in
                        withAnimation {
                            isAyahSearchFocused = focused
                        }
                    }
                )

                // While the search field is focused, the play menu slides away so the field takes the whole
                // width - you're searching, not reaching for playback.
                if !isAyahSearchFocused {
                    playButton(proxy: proxy)
                        .padding(.bottom, 2)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding([.leading, .top], -8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.00001))
        .animation(.easeInOut, value: quranPlayer.isPlaying)
        // Also animate the swap INTO the loading spinner: tapping play flips isLoading before isPlaying, so
        // without this the play icon jumped to the spinner with no transition.
        .animation(.easeInOut, value: quranPlayer.isLoading)
    }
    #endif

    @ViewBuilder
    private func nowPlayingInset(proxy: ScrollViewProxy) -> some View {
        NowPlayingView(quranView: false)
            .onTapGesture {
                guard
                    let curSurah = quranPlayer.currentSurahNumber,
                    let curAyah = quranPlayer.currentAyahNumber,
                    curSurah == surah.id
                else { return }

                settings.hapticFeedback()

                if !searchText.isEmpty {
                    withAnimation {
                        searchText = ""
                        self.endEditing()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation { proxy.scrollTo(curAyah, anchor: .top) }
                    }
                } else {
                    withAnimation { proxy.scrollTo(curAyah, anchor: .top) }
                }
            }
    }

    #if os(iOS)
    @ViewBuilder
    private func playButton(proxy: ScrollViewProxy) -> some View {
        let playerIdle = !quranPlayer.isLoading && !quranPlayer.isPlaying && !quranPlayer.isPaused
        let canResumeLast = settings.lastListenedSurah?.surahNumber == surah.id
        let repeatCounts  = [20, 15, 10, 5, 3, 2]

        if playerIdle {
            Menu {
                // Reciter picker pinned to the very top, with a divider under it - the page-mode play
                // menu's placement, mirrored here so the reciter is the first thing the menu offers.
                Button {
                    settings.hapticFeedback()
                    showReciterPickerSheet = true
                } label: {
                    Label("Choose Reciter", systemImage: "headphones")
                }

                Divider()

                Text("Surah Playback")
                    .foregroundStyle(.secondary)

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
                    quranPlayer.playSurah(
                        surahNumber: surah.id,
                        surahName: surah.nameTransliteration
                    )
                } label: {
                    Label(canResumeLast ? "Play from Beginning" : "Play Surah", systemImage: "memories")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(
                        surahNumber: surah.id,
                        ayahNumber: 1,
                        continueRecitation: true
                    )
                } label: {
                    Label("Play Ayah by Ayah", systemImage: "list.number")
                }
                // (Choose Reciter now lives at the TOP of this menu.)

                Menu {
                    Text("More Playback")
                        .foregroundStyle(.secondary)

                    Button {
                        settings.hapticFeedback()
                        showCustomRangeSheet = true
                    } label: {
                        Label("Play Custom Range", systemImage: "slider.horizontal.3")
                    }

                    Button {
                        settings.hapticFeedback()
                        let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
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

                    Button {
                        settings.hapticFeedback()
                        playRandomReciterForCurrentSurah()
                    } label: {
                        Label("Play Random Reciter", systemImage: "person.wave.2")
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
            } label: {
                playbackMenuControlLabel {
                    playIcon()
                }
            }
            // Without this, a menu popping UPWARD from this bottom-anchored button renders reversed,
            // dumping Choose Reciter (declared first, wanted on top) to the bottom.
            .fixedMenuOrder()
        } else {
            Button {
                settings.hapticFeedback()
                // A tap while loading OR playing fully stops playback. Previously a loading tap only paused
                // the in-flight load, which could resume once the item became ready (so it "did nothing").
                quranPlayer.stop()
            } label: {
                playbackMenuControlLabel {
                    playIcon()
                }
            }
        }
    }

    private func playbackMenuControlLabel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(width: 27, height: 27)
            .padding()
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .conditionalGlassEffect()
    }

    private func playRandomReciterForCurrentSurah() {
        guard let randomReciter = reciters.randomElement() else { return }
        settings.setSelectedReciter(randomReciter)
        quranPlayer.playSurah(
            surahNumber: surah.id,
            surahName: surah.nameTransliteration
        )
    }

    @ViewBuilder
    private func playIcon() -> some View {
        if quranPlayer.isLoading {
            RotatingGearView().transition(.opacity)
        } else if quranPlayer.isPlaying || quranPlayer.isPaused {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.accentColor.color)
                .transition(.opacity)
        } else {
            Image(systemName: "play.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.accentColor.color)
                .transition(.opacity)
        }
    }

    /// The title is a `Menu`. Note that a Menu sizes its label to the label's *intrinsic* width, so
    /// `surahTitleLabel` must stay intrinsically sized - an expanding `Spacer()` in there collapses to nothing
    /// and squeezes the whole title into a pill.
    private var surahTitlePickerButton: some View {
        Menu {
            Button {
                settings.hapticFeedback()
                showSurahPickerSheet = true
            } label: {
                Label("Choose Surah", systemImage: "list.bullet")
            }

            Button {
                settings.hapticFeedback()
                showSurahInfoSheet = true
            } label: {
                Label("Surah Info", systemImage: "info.circle")
            }

            Button {
                settings.hapticFeedback()
                surahInfoDialog = surahInfoDialog(for: displayedSurah)
            } label: {
                Label("Revelation Info", systemImage: "book.closed")
            }

            Divider()

            // Multi-select: pick several ayahs, then share/copy/bookmark/annotate them all at once.
            // Works in both readers - on the page, taps toggle ayahs of this surah while the mode is on.
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    if cachedAyahsForQiraah.isEmpty { rebuildQiraahCaches() }
                    isSelectingAyahs = true
                    selectedAyahIDs = []
                }
            } label: {
                Label("Select Ayahs", systemImage: "checkmark.circle")
            }

            // Playback lives on the play control in the footer, not up here.
            Button {
                toggleReadingMode()
            } label: {
                Label(settings.quranPageMode ? "Read as List" : "Read as Pages",
                      systemImage: settings.quranPageMode ? "list.bullet.rectangle" : "book")
            }

            // Page mode only: what the page's BODY text is. Arabic is the mushaf itself; the English options
            // replace the page wholesale (same page boundaries, same fit-to-page) for a reader following
            // along in Latin script. Headings follow the page's language automatically.
            if settings.quranPageMode {
                Menu {
                    Picker("Page Text", selection: $settings.mushafPageLanguage) {
                        ForEach(MushafPageLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                } label: {
                    Label("Page Text: \(settings.resolvedMushafPageLanguage.displayName)",
                          systemImage: "character.book.closed")
                }
            }
        } label: {
            surahTitleLabel
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private var surahTitleLabel: some View {
        let surah = displayedSurah
        return Group {
            VStack(spacing: 0) {
                // A fixed gap, NOT a `Spacer()`: the Menu wrapping this label sizes it to its intrinsic width,
                // and an expanding Spacer collapses to zero there - which is what shrank the title to a pill.
                HStack(spacing: 10) {
                    HStack {
                        // The Latin side never shrinks - a scaled-down transliteration next to full-size
                        // Arabic reads as a mistake. It truncates instead.
                        Text("\(surah.id)")
                            .font(.subheadline.bold())
                            .foregroundColor(settings.accentColor.color)
                            .lineLimit(1)

                        Text(surah.nameTransliteration)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                    }

                    HStack {
                        // Arabic scales down rather than truncating: a clipped Arabic name is unreadable,
                        // where a smaller one is not.
                        Text(settings.cleanedQuranArabic(surah.nameArabic))
                            .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 2))
                            .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                            .lineLimit(1)

                        Text(surah.idArabic)
                            .font(.custom(Settings.hafsUthmaniFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 3))
                            .arabicFontDesign(custom: true)
                            .foregroundColor(settings.accentColor.color)
                            .lineLimit(1)
                    }
                }

                Text(surah.nameEnglish)
                    .font(.caption2)
                    .lineLimit(1)
                    .padding(.top, -8)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.primary)
            .contentShape(Rectangle())
            .padding(.horizontal)
            .padding(.bottom, 6)
            .conditionalGlassEffect()
        }
    }

    private var navBarTitle: some View {
        Button {
            settings.hapticFeedback()
            showingSettingsSheet = true
        } label: {
            Image(systemName: "gear")
        }
        .tint(settings.accentColor.accent2)
    }

    /// Hands the search off to the Quran tab, which owns the whole-Quran search (see `QuranSearchHandoff`).
    ///
    /// This is the mushaf's ONLY search - it has no search bar of its own and there is nowhere sensible to put
    /// one on a fixed-size page. In the list reader it sits alongside the in-surah search bar and answers the
    /// other question: "not in this surah - find it anywhere." Either way the hit rows navigate straight back
    /// into the reading mode the user is already in.
    @ViewBuilder
    private func applySurahToolbar(to base: some View) -> some View {
        base.toolbar {
            ToolbarItem(placement: .principal) {
                surahTitlePickerButton
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                navBarTitle
            }
        }
    }

    @ViewBuilder
    private var selectedSurahNavigationDestination: some View {
        if let targetID = selectedSurahNavigation,
           let targetSurah = quranData.surah(targetID) {
            SurahView(surah: targetSurah)
        } else {
            EmptyView()
        }
    }

    private var settingsSheet: some View {
        NavigationView { SettingsQuranView(presentedAsSheet: true) }
    }
    #endif

    /// The ayah currently anchored at the top of the screen (falling back through the last known anchor).
    private func currentReadingAyahID() -> Int? {
        visibility.visibleAyahIDs.min()
            ?? visibility.firstVisibleAyahID
            ?? ayah
            ?? cachedAyahsForQiraah.first?.id
    }

    /// Cheap, in-memory only: records where the user is so a re-appear (e.g. after Control Center) can
    /// restore the spot without the expensive `settings` write that `saveLastRead()` performs.
    private func rememberCurrentVisibleAyah() {
        guard let targetAyah = currentReadingAyahID() else { return }
        rememberVisibleAyahID(targetAyah)
    }

    private func saveLastRead() {
        guard let targetAyah = currentReadingAyahID() else { return }
        rememberVisibleAyahID(targetAyah)

        guard settings.saveLastReadAyah else { return }

        if settings.lastReadSurah == surah.id, settings.lastReadAyah == targetAyah {
            return
        }

        settings.lastReadSurah = surah.id
        settings.lastReadAyah = targetAyah
        settings.refreshQuranWidgets()
    }

    private func neighboringSurah(before currentSurahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == currentSurahID }), index > 0 else { return nil }
        return quranData.quran[index - 1]
    }

    private func neighboringSurah(after currentSurahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == currentSurahID }), index + 1 < quranData.quran.count else { return nil }
        return quranData.quran[index + 1]
    }

    /// Flips between the ayah list and the mushaf, landing on the same place in the text rather than at the
    /// top of the surah:
    ///
    /// * list → page: opens the page that holds the ayah currently at the top of the screen. Reading ayah 40
    ///   of a surah that starts on page 95 opens page 100, not 95.
    /// * page → list: opens at the first ayah of the page you were on - and swaps the surah in place when that
    ///   page belongs to a different one (mushaf pages run across surah boundaries).
    private func toggleReadingMode() {
        settings.hapticFeedback()

        // Multi-select is a list-mode feature; leaving the list ends it.
        isSelectingAyahs = false
        selectedAyahIDs = []

        if settings.quranPageMode {
            if let anchor = pageAnchor {
                if anchor.surahID != surah.id, let anchorSurah = quranData.surah(anchor.surahID) {
                    searchText = ""
                    pendingScrollAfterSearchClear = nil
                    scrollDown = nil
                    visibility.resetScrollTracking()
                    settings.recordSurahOpened(anchorSurah.id)
                    swappedSurah = anchorSurah
                }
                // An ayah SELECTED on the page wins over the page's top ayah: switching to the list
                // scrolls to the ayah the reader marked, not merely to wherever the page began.
                let landing: Int = {
                    if let selected = highlightedAyah, selected.surahID == anchor.surahID {
                        return selected.ayahID
                    }
                    return anchor.ayahID
                }()
                visibility.setAnchor(landing)
                modeSwitchAyah = landing
                // The list reader only performs its opening scroll once per surah; this is a fresh open.
                didScrollDown = false
                // Carry the highlight onto the ayah the list lands on.
                highlightedAyah = HighlightedAyahRef(surahID: anchor.surahID, ayahID: landing)
            }
            pageSurah = nil
        } else {
            let top = currentReadingAyahID()
            modeSwitchAyah = top
            // Highlight the ayah that was at the top of the list (the would-be last-read ayah) so it's easy to
            // find on the page you land on.
            if let top {
                highlightedAyah = HighlightedAyahRef(surahID: surah.id, ayahID: top)
            }
        }

        withAnimation { settings.quranPageMode.toggle() }
    }

    private func navigateToSurah(_ targetSurah: Surah) {
        // Compare against what's on SCREEN (in page mode the reader may be pages away from `surah`),
        // not the surah this view was opened from - see the picker-sheet note.
        guard targetSurah.id != displayedSurah.id else { return }
        settings.hapticFeedback()

        // Reset the per-surah reading state either way.
        isSelectingAyahs = false
        selectedAyahIDs = []
        searchText = ""
        pendingScrollAfterSearchClear = nil
        scrollDown = nil
        visibility.resetScrollTracking()
        visibility.setAnchor(nil)
        // A surah swap opens at its own target (the top), so a stale mode-switch anchor must not win.
        modeSwitchAyah = nil

        if let onSelectSurah {
            // Column navigation: the parent owns the detail, so let it swap the surah.
            onSelectSurah(targetSurah.id)
        } else {
            // Stack navigation: swap the surah in place rather than pushing a whole new SurahView.
            pageSurah = nil
            settings.recordSurahOpened(targetSurah.id)
            withAnimation(.easeInOut) {
                swappedSurah = targetSurah
            }
            // The page reader re-seeds on `surah.id` changes - but after paging away, the picked surah
            // can EQUAL the prop (picking the surah the reader was opened from), so the id never
            // changes and no re-seed fires. The token forces one on every navigation.
            pageJumpToken += 1
        }
    }

    /// Previous | Next surah, side by side - shown at both the top and the bottom of the reader. Each
    /// swaps the surah in place (`navigateToSurah`) rather than pushing a new view.
    @ViewBuilder
    private func surahNavigationButtonPair(previous: Surah?, next: Surah?) -> some View {
        HStack(spacing: 10) {
            if let previous {
                surahNavigationButton(title: "Previous", surah: previous, systemImage: "chevron.left", trailing: false)
            }
            if let next {
                surahNavigationButton(title: "Next", surah: next, systemImage: "chevron.right", trailing: true)
            }
        }
    }

    private func surahNavigationButton(title: String, surah targetSurah: Surah, systemImage: String, trailing: Bool) -> some View {
        Button {
            navigateToSurah(targetSurah)
        } label: {
            HStack(spacing: 8) {
                if !trailing {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }

                VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text("\(targetSurah.id) - \(targetSurah.nameTransliteration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)

                if trailing {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct RotatingGearView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "gear")
            #if os(iOS)
            .font(.title3)
            #else
            .font(.subheadline)
            #endif
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                // Decorative spinner: skipped in Low Power Mode (renders as a static glyph).
                guard !AppPerformance.shouldReduceAnimations else { return }
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#if os(iOS)
private struct SurahPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    @State private var searchText = ""
    let currentSurahID: Int
    let onSelect: (Surah) -> Void

    private var filteredSurahs: [Surah] {
        let query = normalized(searchText)
        guard !query.isEmpty else { return quranData.quran }

        return quranData.quran.filter { surah in
            let tokens = [
                "\(surah.id)",
                normalized(surah.nameEnglish),
                normalized(surah.nameTransliteration),
                normalized(surah.nameArabic)
            ]
            return tokens.contains { $0.contains(query) }
        }
    }

    private func adjacentSurah(before surahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == surahID }), index > 0 else { return nil }
        return quranData.quran[index - 1]
    }

    private func adjacentSurah(after surahID: Int) -> Surah? {
        guard let index = quranData.quran.firstIndex(where: { $0.id == surahID }), index + 1 < quranData.quran.count else { return nil }
        return quranData.quran[index + 1]
    }

    private func select(_ surah: Surah) {
        onSelect(surah)
        dismiss()
    }

    private func scrollToCurrentSurah(_ proxy: ScrollViewProxy) {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard filteredSurahs.contains(where: { $0.id == currentSurahID }) else { return }

        let requestScroll = {
            withAnimation(.easeInOut) {
                proxy.scrollTo(currentSurahID, anchor: .center)
            }
        }

        DispatchQueue.main.async {
            requestScroll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                requestScroll()
            }
        }
    }

    private var ayahHighlightBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, watchOS 26.0, *) {
            return -11
        }
        return -2
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                List {
                    Group {
                        ForEach(filteredSurahs, id: \.id) { surah in
                            Section {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(
                                            surah.id == currentSurahID
                                            ? settings.accentColor.color.opacity(0.15)
                                            : .clear
                                        )
                                        .padding(.horizontal, -12)
                                        .padding(.vertical, ayahHighlightBackgroundVerticalPadding)

                                    Button {
                                        settings.hapticFeedback()
                                        withAnimation {
                                            select(surah)
                                        }
                                    } label: {
                                        SurahRow(surah: surah, hideInfo: settings.showSurahInformation)
                                            .contentShape(Rectangle())
                                    }
                                    .id(surah.id)
                                }
                            }
                        }
                    }
                    .themedListRowBackground()
                }
                .applyConditionalListStyle()
                .compactListSectionSpacing()
                .searchable(text: $searchText.animation(.easeInOut), prompt: "Search surah")
                .navigationTitle("Choose Surah")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            settings.hapticFeedback()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                        }
                        .tint(settings.accentColor.color)
                    }
                }
                .onAppear {
                    scrollToCurrentSurah(proxy)
                }
                .onChange(of: searchText) { _ in
                    guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    scrollToCurrentSurah(proxy)
                }
                .onChange(of: filteredSurahs.count) { _ in scrollToCurrentSurah(proxy) }
            }
        }
    }

    private func normalized(_ text: String) -> String {
        settings.cleanSearch(text, whitespace: true)
    }
}
#endif

struct ArabicTextRiwayahPicker: View {
    @ObservedObject private var settings = Settings.shared

    @Binding var selection: String
    var useSimpleIOSPicker: Bool = false

    private static let options: [Settings.Riwayah.Option] = Settings.Riwayah.options

    private var currentLabel: String {
        let tag = Settings.normalizeLegacyRiwayahTag(selection)
        return Self.options.first(where: { $0.tag == tag })?.label ?? "Arabic Riwayah"
    }

    var body: some View {
        #if os(iOS)
        if useSimpleIOSPicker {
            Picker("Arabic Riwayah", selection: $selection.animation(.easeInOut)) {
                ForEach(Settings.Riwayah.groups) { group in
                    Section {
                        ForEach(group.options, id: \.tag) { option in
                            Text(option.label).tag(option.tag)
                        }
                    } header: {
                        Text("\(group.teacher) - \(group.teacherArabic)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: selection) { _ in settings.hapticFeedback() }
        } else {
            Menu {
                ForEach(Settings.Riwayah.groups) { group in
                    ForEach(group.options, id: \.tag) { option in
                        qiraahButton(option)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(currentLabel)
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)
                        .fixedSize()

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(settings.accentColor.color.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 0)
                .conditionalGlassEffect()
            }
        }
        #else
        Picker("Arabic Riwayah", selection: $selection.animation(.easeInOut)) {
            ForEach(Settings.Riwayah.groups) { group in
                Section {
                    ForEach(group.options, id: \.tag) { option in
                        Text(option.label).tag(option.tag)
                    }
                } header: {
                    Text("\(group.teacher) - \(group.teacherArabic)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: selection) { _ in settings.hapticFeedback() }
        #endif
    }

    @ViewBuilder
    private func qiraahButton(_ option: Settings.Riwayah.Option) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                selection = option.tag
            }
        } label: {
            HStack {
                if option.tag == Settings.normalizeLegacyRiwayahTag(selection) {
                    Image(systemName: "checkmark")
                }

                Text(option.label)
            }
            .font(.caption)
        }
    }
}

#if os(iOS)
private struct TajweedLegendMenu: View {
    @ObservedObject private var settings = Settings.shared

    @State private var showingSheet = false

    var expandsToFillRow: Bool = false

    var body: some View {
        Button {
            settings.hapticFeedback()
            showingSheet = true
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach([Color.red, .orange, .yellow, .green, .blue], id: \.self) { item in
                        Circle()
                            .fill(item)
                            .frame(width: 5, height: 5)
                    }
                }

                Text("Legend")
                    .font(.caption)
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .shadow(color: .primary.opacity(0.25), radius: 2, x: 0, y: 0)
            .conditionalGlassEffect()
        }
        .sheet(isPresented: $showingSheet) {
            NavigationView {
                TajweedLegendView()
            }
            .smallMediumSheetPresentation()
        }
    }
}

// MARK: - Page mode

/// A mushaf page: every ayah printed on absolute page `page`, grouped into runs by surah so a page that
/// straddles a surah boundary can draw a divider where the surah changes.
#endif

#Preview {
    AlIslamPreviewContainer {
        SurahView(surah: AlIslamPreviewData.surah)
    }
}

