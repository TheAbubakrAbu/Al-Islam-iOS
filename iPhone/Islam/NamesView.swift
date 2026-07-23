import SwiftUI

struct NameOfAllah: Decodable, Identifiable, Equatable {
    let number: Int
    let id: String
    let name: String
    let transliteration: String
    let found: String
    let meaning: String
    let otherNames: [String]
    let desc: String
    let numberArabic: String
    let displayArabicName: String
    let searchTokens: [String]
    let firstFoundSurah: Int?
    let firstFoundAyah: Int?

    enum CodingKeys: String, CodingKey {
        case name, transliteration, number, found, meaning, otherNames, desc
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        number = try c.decode(Int.self, forKey: .number)
        name = try c.decode(String.self, forKey: .name)
        transliteration = try c.decode(String.self, forKey: .transliteration)
        found = try c.decode(String.self, forKey: .found)
        meaning = try c.decode(String.self, forKey: .meaning)
        otherNames = try c.decodeIfPresent([String].self, forKey: .otherNames) ?? []
        desc = try c.decode(String.self, forKey: .desc)

        id = "\(number)"
        numberArabic = arabicNumberString(from: number)
        let deacriticizedName = name.removeDiacriticsFromLastLetter()
        displayArabicName = deacriticizedName.contains(" ")
            ? deacriticizedName.split(separator: " ").joined(separator: "\n")
            : deacriticizedName
        let firstFound = Self.parseFirstFound(found)
        firstFoundSurah = firstFound?.surah
        firstFoundAyah = firstFound?.ayah

        searchTokens = [
            Self.clean(name),
            Self.clean(transliteration),
            Self.clean(meaning),
            otherNames.map(Self.clean).joined(separator: " "),
            Self.clean(desc),
            Self.clean(found),
            "\(number)",
            numberArabic
        ]
    }

    private static func clean(_ s: String) -> String {
        let unwanted: Set<Character> = ["[", "]", "(", ")", "-", "'", "\""]
        let stripped = s
            .normalizingArabicIndicDigitsToWestern
            .filter { !unwanted.contains($0) }
        return (stripped.applyingTransform(.stripDiacritics, reverse: false) ?? stripped).lowercased()
    }

    private static func parseFirstFound(_ found: String) -> (surah: Int, ayah: Int)? {
        let pattern = #"\((\d+)\s*:\s*(\d+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let fullRange = NSRange(found.startIndex..<found.endIndex, in: found)
        guard let match = regex.firstMatch(in: found, range: fullRange), match.numberOfRanges >= 3,
              let surahRange = Range(match.range(at: 1), in: found),
              let ayahRange = Range(match.range(at: 2), in: found),
              let surah = Int(found[surahRange]),
              let ayah = Int(found[ayahRange]) else {
            return nil
        }
        return (surah, ayah)
    }

    var firstFoundShort: String {
        guard let closingParen = found.firstIndex(of: ")") else { return found }
        return String(found[...closingParen])
    }

    /// Which of the three *displayed* fields (Arabic name, transliteration, meaning) actually contain the
    /// query. A name can also match on hidden fields (`desc`, `otherNames`, `found`), in which case all three
    /// are false and the collapsed row shows no highlight - correct, since the match isn't visible. When a
    /// displayed field does match, its flag drives `guaranteeMatch` so that field always shows at least one
    /// highlight even if the highlighter's normalization differs from this search's (e.g. `ḥ` vs `h`).
    /// Indices mirror `searchTokens`: [0] = Arabic name, [1] = transliteration, [2] = meaning.
    /// One-entry memo for the cleaned query: during a search, every visible row cleans the SAME raw
    /// query per keystroke - up to ~99 identical diacritic-strips per character typed. Main-thread only,
    /// like the row bodies that call it.
    private static var cleanedQueryMemo: (raw: String, cleaned: String) = ("", "")

    private static func cleanedQuery(_ raw: String) -> String {
        if cleanedQueryMemo.raw == raw { return cleanedQueryMemo.cleaned }
        let cleaned = clean(raw)
        cleanedQueryMemo = (raw, cleaned)
        return cleaned
    }

    func displayedFieldMatches(query rawQuery: String) -> (arabic: Bool, transliteration: Bool, meaning: Bool) {
        let q = Self.cleanedQuery(rawQuery)
        guard !q.isEmpty, searchTokens.count >= 3 else { return (false, false, false) }
        return (
            arabic: searchTokens[0].contains(q),
            transliteration: searchTokens[1].contains(q),
            meaning: searchTokens[2].contains(q)
        )
    }
}

final class NamesViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed
    }

    static let shared: NamesViewModel = {
        let model = NamesViewModel()
        model.startLoading()
        return model
    }()

    private static let decoder = JSONDecoder()

    @Published var namesOfAllah: [NameOfAllah] = []
    @Published private(set) var firstFoundTargetsByNameNumber: [Int: (surahID: Int, ayahID: Int)] = [:]
    @Published private(set) var loadState: LoadState = .idle
    private var filterCache = [String: [NameOfAllah]]()
    private var loadTask: Task<Void, Never>?

    private init() {}

    private func startLoading() {
        guard loadTask == nil else { return }
        loadTask = Task(priority: .utility) { [weak self] in
            await self?.loadJSON()
        }
    }

    var isReadyForUI: Bool {
        loadState == .ready
    }

    /// Wall-clock capped: this gates the LAUNCH SCREEN reveal (LaunchScreen awaits it with no cap of
    /// its own), and the uncapped loop had no escape if the load task never ran or wedged before
    /// setting `.ready`/`.failed` - a permanently stranded launch. Eight seconds is far beyond any
    /// real parse of a 100-entry JSON; past it, launching with the names still loading beats a hang.
    func waitUntilLoaded() async {
        for _ in 0..<320 {
            let state = await MainActor.run { self.loadState }
            if state == .ready || state == .failed {
                return
            }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    private func loadJSON() async {
        await MainActor.run {
            loadState = .loading
        }

        defer {
            Task { @MainActor in
                self.loadTask = nil
            }
        }

        guard let url = Bundle.main.url(forResource: "NamesOfAllah", withExtension: "json") else {
            logger.debug("❌ 99 Names JSON not found.")
            await MainActor.run {
                self.loadState = .failed
            }
            return
        }

        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let names = try Self.decoder.decode([NameOfAllah].self, from: data)
            var targets = [Int: (surahID: Int, ayahID: Int)]()
            targets.reserveCapacity(names.count)
            for name in names {
                guard let surah = name.firstFoundSurah,
                      let ayah = name.firstFoundAyah else { continue }
                targets[name.number] = (surahID: surah, ayahID: ayah)
            }
            let finalizedTargets = targets

            await MainActor.run {
                self.namesOfAllah = names
                self.firstFoundTargetsByNameNumber = finalizedTargets
                self.filterCache.removeAll(keepingCapacity: true)
                self.loadState = .ready
            }
        } catch {
            logger.debug("❌ JSON decode error: \(error)")
            await MainActor.run {
                self.loadState = .failed
            }
        }
    }

    func filteredNames(cleanedQuery: String) -> [NameOfAllah] {
        guard !cleanedQuery.isEmpty else { return namesOfAllah }

        if let cached = filterCache[cleanedQuery] {
            return cached
        }

        let matches = namesOfAllah.filter { name in
            if cleanedQuery.allSatisfy(\.isNumber), let n = Int(cleanedQuery) {
                return name.number == n
            }
            return name.searchTokens.contains { $0.contains(cleanedQuery) } || Int(cleanedQuery) == name.number
        }
        // Every distinct prefix a user ever types lands here; without a bound the cache grows for the
        // app's lifetime. Recomputing a miss is a filter over 99 names, so wholesale eviction is fine.
        if filterCache.count >= 128 {
            filterCache.removeAll(keepingCapacity: true)
        }
        filterCache[cleanedQuery] = matches
        return matches
    }
}

struct NamesView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var namesData = NamesViewModel.shared

    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @State private var expandedNameNumbers = Set<Int>()
    
    /// Cached so the diacritic-stripping `clean()` only runs when the query changes - not on every `body`
    /// re-eval (expand/collapse, favorite toggles, font switches all re-run body but leave the query alone).
    @State private var cleanedSearch = ""

    private static func clean(_ s: String) -> String {
        let unwanted: Set<Character> = ["[", "]", "(", ")", "-", "'", "\""]
        let stripped = s
            .normalizingArabicIndicDigitsToWestern
            .filter { !unwanted.contains($0) }
        return (stripped.applyingTransform(.stripDiacritics, reverse: false) ?? stripped).lowercased()
    }

    private var filteredNames: [NameOfAllah] {
        namesData.filteredNames(cleanedQuery: cleanedSearch)
    }

    /// Collapse state for the favorites section, same as the Quran tab's Favorite Surahs.
    @AppStorage("showFavoriteNames") private var showFavoriteNames = true

    private func favoriteNames(in favoriteSet: Set<Int>) -> [NameOfAllah] {
        namesData.namesOfAllah
            .filter { favoriteSet.contains($0.number) }
            .sorted { $0.number < $1.number }
    }

    var body: some View {
        let hasActiveSearch = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // One pass per render: the favorite set used to be rebuilt (`Set(...)`) at every row's
        // contains-check - ~100 allocations per body pass - and the favorites list was
        // filtered+sorted three times (gate, count, ForEach).
        let favoriteSet = Set(settings.favoriteNameNumbers)
        let favorites = favoriteNames(in: favoriteSet)
        let names = filteredNames

        ScrollViewReader { proxy in
            List {
                Group {
                    descriptionSection
                    allahSection(hasActiveSearch: hasActiveSearch)
                    favoriteNamesSection(favorites, hasActiveSearch: hasActiveSearch, proxy: proxy)
                    namesHeaderSection(resultCount: names.count, hasActiveSearch: hasActiveSearch, proxy: proxy)
                    namesSections(filteredNames: names, favoriteSet: favoriteSet, hasActiveSearch: hasActiveSearch, proxy: proxy)
                    finalInvocationSection
                }
                .themedListRowBackground()
            }
        }
        #if os(watchOS)
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #else
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                // The font picker above the search bar is OFF for now (it was the row that vanished when
                // scrolling down) - uncomment to bring it back. The same three-way choice still lives in
                // the Arabic Alphabet screen and the Hadith settings sheet.
                // IslamArabicFontPicker()
                // // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
                // .conditionalGlassEffect(interactive: false)
                // // Stays mounted while minimized (height 0) - inserting/removing glass renders black boxes.
                // .collapsibleBarRow(barsCollapsed)

                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
                    .padding([.horizontal, .top], -8)
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("99 Names of Allah")
        .onChange(of: searchText) { newValue in cleanedSearch = Self.clean(newValue) }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Grid/list toggle lives in the toolbar (same as QuranView) rather than on a section header.
                Button {
                    settings.hapticFeedback()
                    withAnimation { settings.namesGridMode.toggle() }
                } label: {
                    Image(systemName: settings.namesGridMode ? "list.bullet" : "square.grid.2x2")
                }
                .accessibilityLabel(settings.namesGridMode ? "Show list" : "Show grid")
                .tint(settings.accentColor.accent2)
            }
        }
        #endif
    }

    private var descriptionSection: some View {
        Section(header: Text("DESCRIPTION")) {
            Text("Prophet Muhammad ﷺ said, “Allah has 99 names, and whoever believes in their meanings and acts accordingly, will enter Paradise” (Bukhari 6410). The count is established in Bukhari and Muslim; the enumerated list below is the one narrated in Tirmidhi 3507, which scholars note is an addition by a narrator rather than the Prophet's own listing. Names marked as coming from that list do not appear as names in the Quran.")
                .font(.caption)
                .foregroundColor(.secondary)

            // The per-row descriptions only exist in list mode, so hide the toggle in grid mode.
            if !settings.namesGridMode {
                Toggle("Show All Descriptions", isOn: showAllDescriptionsBinding)
                    .font(.caption)
                    .tint(settings.accentColor.color)
                    .onChange(of: settings.showDescription) { _ in settings.hapticFeedback() }
            }
        }
    }

    private var showAllDescriptionsBinding: Binding<Bool> {
        Binding(
            get: { settings.showDescription },
            set: { newValue in
                withAnimation(.easeInOut) {
                    settings.showDescription = newValue
                    if !newValue {
                        // User requested global OFF to force every manual expansion closed.
                        expandedNameNumbers.removeAll()
                    }
                }
            }
        )
    }

    /// The name itself, above the 99: Allah is the proper name the 99 names all describe, so it gets
    /// its own row rather than a place in the enumerated list. Hidden while searching - it is not one
    /// of the searchable names.
    @ViewBuilder
    private func allahSection(hasActiveSearch: Bool) -> some View {
        if !hasActiveSearch {
            Section(header: Text("ALLAH")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Allah")
                                .font(.subheadline.weight(.semibold))

                            Text("The One True God")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("First Found: 1:1")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer(minLength: 8)

                        Text("الله")
                            .font(settings.useFontArabic ? Font.arabic(settings.nonQuranArabicFontName, size: 30) : .title)
                            .arabicFontDesign(custom: settings.useFontArabic && settings.nonQuranArabicFontName != Settings.systemArabicFontName)
                            .foregroundColor(settings.accentColor.color)
                    }

                    Text("Allah (الله) is the proper name of the One True God - not one of the 99 names, but the name every one of them describes. Unlike other words, it has no plural and no gender, and it was never used for anything or anyone else. It appears in the Quran more than 2,600 times, beginning with the very first ayah:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("“In the name of Allah, the Entirely Merciful, the Especially Merciful.” — Quran 1:1")
                        .font(.footnote.italic())
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("View First Ayah (1:1)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .conditionalGlassEffect(useColor: 0.2)
                        .padding(.top, 2)
                        .background(
                            NavigationLink("", destination: ayahsDestination(for: (surahID: 1, ayahID: 1)))
                                .opacity(0)
                        )
                }
            }
        }
    }

    private func namesHeaderSection(resultCount: Int, hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        Section(header: SectionPillHeader(
            title: hasActiveSearch ? "NAME SEARCH RESULTS" : "NAMES OF ALLAH",
            count: resultCount,
            // Shuffle expands and scrolls to a random name - list rows only; grid tiles carry no ids.
            onShuffle: (hasActiveSearch || settings.namesGridMode) ? nil : { shuffleToRandomName(proxy: proxy) }
        )) { }
        .padding(.bottom, -12)
    }

    /// Expands a random name and scrolls it to the top - the header's shuffle button.
    private func shuffleToRandomName(proxy: ScrollViewProxy) {
        guard let name = namesData.namesOfAllah.randomElement() else { return }
        withAnimation {
            expandedNameNumbers.insert(name.number)
            proxy.scrollTo("name_\(name.number)", anchor: .top)
        }
    }

    @ViewBuilder
    private func favoriteNamesSection(_ favorites: [NameOfAllah], hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        if !hasActiveSearch && !favorites.isEmpty {
            Section(header: SectionPillHeader(
                title: "FAVORITES",
                count: favorites.count,
                icon: "star.fill",
                accentTitle: true,
                isExpanded: $showFavoriteNames
            )) {
                if !showFavoriteNames {
                    EmptyView()
                } else if settings.namesGridMode {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(favorites, id: \.id) { name in
                            NameGridTile(
                                name: name,
                                isFavorite: true,
                                accentColor: settings.accentColor,
                                useFontArabic: settings.useFontArabic,
                                fontArabic: settings.nonQuranArabicFontName
                            )
                            .equatable()
                        }
                    }
                    .padding(.horizontal, -8)
                } else {
                    ForEach(favorites, id: \.id) { name in
                        NameRow(
                            name: name,
                            firstFoundTarget: namesData.firstFoundTargetsByNameNumber[name.number],
                            showDescription: settings.showDescription,
                            isExpanded: expandedNameNumbers.contains(name.number),
                            isFavorite: true,
                            accentColor: settings.accentColor,
                            useFontArabic: settings.useFontArabic,
                            fontArabic: settings.nonQuranArabicFontName,
                            searchQuery: searchText
                        ) {
                            handleNameTap(name: name, hasActiveSearch: hasActiveSearch, proxy: proxy)
                        }
                        .equatable()
                        .id("favorite_name_\(name.number)")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func namesSections(filteredNames: [NameOfAllah], favoriteSet: Set<Int>, hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        if settings.namesGridMode {
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(filteredNames, id: \.id) { name in
                        NameGridTile(
                            name: name,
                            isFavorite: favoriteSet.contains(name.number),
                            accentColor: settings.accentColor,
                            useFontArabic: settings.useFontArabic,
                            fontArabic: settings.nonQuranArabicFontName
                        )
                        .equatable()
                    }
                }
                .padding(.horizontal, -8)
            }
        } else if filteredNames.isEmpty, hasActiveSearch {
            Section {
                Text("No names match your search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
        ForEach(filteredNames, id: \.id) { name in
            Section {
                NameRow(
                    name: name,
                    firstFoundTarget: namesData.firstFoundTargetsByNameNumber[name.number],
                    showDescription: settings.showDescription,
                    isExpanded: expandedNameNumbers.contains(name.number),
                    isFavorite: favoriteSet.contains(name.number),
                    accentColor: settings.accentColor,
                    useFontArabic: settings.useFontArabic,
                    fontArabic: settings.nonQuranArabicFontName,
                    searchQuery: searchText
                ) {
                    handleNameTap(name: name, hasActiveSearch: hasActiveSearch, proxy: proxy)
                }
                .equatable()
            }
            .id("name_\(name.number)")
        }
        }
    }

    @ViewBuilder
    private func ayahsDestination(for target: (surahID: Int, ayahID: Int)) -> some View {
        if let surah = quranData.surah(target.surahID) {
            SurahView(surah: surah, ayah: target.ayahID)
        } else {
            Text("Reference not found")
        }
    }

    private func handleNameTap(name: NameOfAllah, hasActiveSearch: Bool, proxy: ScrollViewProxy) {
        if hasActiveSearch {
            let targetID = "name_\(name.number)"
            withAnimation {
                searchText = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation {
                    proxy.scrollTo(targetID, anchor: .top)
                }
            }
        } else {
            withAnimation {
                if expandedNameNumbers.contains(name.number) {
                    expandedNameNumbers.remove(name.number)
                } else {
                    expandedNameNumbers.insert(name.number)
                }
            }
        }
    }

    private var finalInvocationSection: some View {
        Section(header: Text("MOST BEAUTIFUL NAMES")) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Call upon Allah or call upon Ar-Rahman (The Entirely Merciful). Whichever Name you call, to Him belong the Most Beautiful Names.")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Surah Al-Isra 17:110")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:21",
                contentText: "If this Quran were sent upon a mountain, it would humble and break from awe of Allah. These examples are given so people reflect."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:22",
                contentText: "He is Allah, none is worthy of worship except Him. Knower of the seen and unseen, the Most Compassionate, the Most Merciful."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:23",
                contentText: "He is Allah: the King, the Most Holy, the Source of Peace, the Granter of Security, the Guardian, the Almighty, the Compeller, the Supreme. Exalted is He above all partners."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:24",
                contentText: "He is Allah, the Creator, the Originator, the Fashioner. To Him belong the Most Beautiful Names; all in the heavens and earth glorify Him."
            )
        }
    }
}

private struct NameRow: View, Equatable {
    // Deliberately NOT observing Settings: every input this body reads is passed in and folded into `==`,
    // so with `.equatable()` a Settings publish (favorite toggle, accent change elsewhere) skips every
    // row whose inputs didn't change. Actions reach Settings.shared directly - they don't need observation.
    let name: NameOfAllah
    let firstFoundTarget: (surahID: Int, ayahID: Int)?
    let showDescription: Bool
    let isExpanded: Bool
    let isFavorite: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String
    let searchQuery: String
    let onTap: () -> Void

    init(
        name: NameOfAllah,
        firstFoundTarget: (surahID: Int, ayahID: Int)? = nil,
        showDescription: Bool,
        isExpanded: Bool,
        isFavorite: Bool,
        accentColor: AccentColor = Settings.shared.accentColor,
        useFontArabic: Bool = Settings.shared.useFontArabic,
        fontArabic: String = Settings.shared.nonQuranArabicFontName,
        searchQuery: String = "",
        onTap: @escaping () -> Void
    ) {
        self.name = name
        self.firstFoundTarget = firstFoundTarget
        self.showDescription = showDescription
        self.isExpanded = isExpanded
        self.isFavorite = isFavorite
        self.accentColor = accentColor
        self.useFontArabic = useFontArabic
        self.fontArabic = fontArabic
        self.searchQuery = searchQuery
        self.onTap = onTap
    }

    var body: some View {
        #if os(iOS)
        content
            .swipeActions(edge: .leading) {
                Button {
                    Settings.shared.hapticFeedback()
                    withAnimation(.easeInOut) {
                        Settings.shared.toggleNameFavorite(number: name.number)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(accentColor.color)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    Settings.shared.hapticFeedback()
                    withAnimation(.easeInOut) {
                        Settings.shared.toggleNameFavorite(number: name.number)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(accentColor.color)
            }
        #else
        content
        #endif
    }

    private var content: some View {
        let fieldMatches = name.displayedFieldMatches(query: searchQuery)
        return Group {
            HStack(alignment: .center, spacing: 12) {
                numberPill

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        HighlightedSnippet(
                            source: name.transliteration,
                            term: searchQuery,
                            font: .subheadline.weight(.semibold),
                            accent: accentColor.color,
                            fg: .primary,
                            guaranteeMatch: fieldMatches.transliteration
                        )
                            .lineLimit(1)

                        HighlightedSnippet(
                            source: name.meaning,
                            term: searchQuery,
                            font: .caption,
                            accent: accentColor.color,
                            fg: .secondary,
                            guaranteeMatch: fieldMatches.meaning
                        )
                            .fixedSize(horizontal: false, vertical: true)

                        Text("First Found: \(name.firstFoundShort)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    HStack {
                        HighlightedSnippet(
                            source: displayArabicName,
                            term: searchQuery,
                            font: useFontArabic ? Font.arabic(fontArabic, size: 24) : .title3,
                            accent: accentColor.color,
                            fg: .primary,
                            guaranteeMatch: fieldMatches.arabic
                        )
                            .arabicFontDesign(custom: useFontArabic && fontArabic != Settings.systemArabicFontName)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)

                        // Always the Uthmani face: it renders the number as the circled-flower ornament.
                        Text(name.numberArabic)
                            .font(.custom(Settings.qiraatUthmaniFontName, size: 28))
                            .arabicFontDesign(custom: true)
                            .foregroundColor(accentColor.color)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !showDescription {
                        Settings.shared.hapticFeedback()
                        onTap()
                    }
                }
            }
            
            if showDescription || isExpanded {
                NameRowDetails(
                    name: name,
                    firstFoundTarget: firstFoundTarget,
                    showDescription: showDescription,
                    isExpanded: isExpanded
                )
            }
        }
    }

    private var displayArabicName: String {
        name.displayArabicName
    }

    @ViewBuilder
    private var numberPill: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(name.number)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(accentColor.color)
                .frame(minWidth: 40)
                .frame(maxHeight: .infinity)
                .conditionalGlassEffect(
                    useColor: isFavorite ? 0.3 : nil,
                    customTint: isFavorite ? accentColor.color : nil
                )

            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(accentColor.color)
                    .padding(4)
                    .offset(x: 8, y: -6)
            }
        }
        .onTapGesture {
            Settings.shared.hapticFeedback()
            Settings.shared.toggleNameFavorite(number: name.number)
        }
        .padding(.vertical, {
            if #available(iOS 26, *) { 0 } else { 8 }
        }())
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name &&
        lhs.firstFoundTarget?.surahID == rhs.firstFoundTarget?.surahID &&
        lhs.firstFoundTarget?.ayahID == rhs.firstFoundTarget?.ayahID &&
        lhs.showDescription == rhs.showDescription &&
        lhs.isExpanded == rhs.isExpanded &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic &&
        lhs.searchQuery == rhs.searchQuery
    }
}

private struct NameRowDetails: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    
    let name: NameOfAllah
    let firstFoundTarget: (surahID: Int, ayahID: Int)?
    let showDescription: Bool
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if showDescription || isExpanded {
                if !name.otherNames.isEmpty {
                    // Baseline-aligned and free to wrap: a name with many alternates used to clip to
                    // whatever fit on the label's line.
                    HStack(alignment: .firstTextBaseline) {
                        Text("Other Names:")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)

                        Text(name.otherNames.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.opacity)
                }

                Text(name.desc)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                    .padding(.top, 2)

                if showDescription || isExpanded, let target = firstFoundTarget {
                    Text("View First Found")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .conditionalGlassEffect(useColor: 0.2)
                        .padding(.top, 6)
                        .background(
                            NavigationLink("", destination: ayahsDestination(for: target))
                                .opacity(0)
                        )
                }
            }
        }
    }

    @ViewBuilder
    private func ayahsDestination(for target: (surahID: Int, ayahID: Int)) -> some View {
        if let surah = quranData.surah(target.surahID) {
            SurahView(surah: surah, ayah: target.ayahID)
        } else {
            Text("Reference not found")
        }
    }
}

private struct VerseReflectionCard: View {
    @ObservedObject var settings = Settings.shared
    
    let title: String
    let contentText: String

    var body: some View {
        content
    }
    
    var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(settings.accentColor.color)

            Text(contentText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(-4)
    }
}

private struct NameGridTile: View, Equatable {
    @ObservedObject private var settings = Settings.shared

    let name: NameOfAllah
    let isFavorite: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String

    /// Every appearance input is a stored value, so equality of the values means the drawn tile is identical.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(name.displayArabicName)
                .font(useFontArabic ? Font.arabic(fontArabic, size: 20) : .title3)
                .arabicFontDesign(custom: useFontArabic && fontArabic != Settings.systemArabicFontName)
                .foregroundColor(accentColor.color)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(name.transliteration)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("\(name.number)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        // Only a favorite is tinted; every other tile is clear. A grid where all 99 boxes are filled is just a
        // wall of color, and the favorites disappear into it.
        .conditionalGlassEffect(
            clear: !isFavorite,
            rectangle: true,
            useColor: isFavorite ? 0.25 : nil,
            customTint: isFavorite ? accentColor.color : nil
        )
        .gridFavoriteStar(
            isFavorite: isFavorite,
            accent: accentColor.color,
            accessibilityName: name.transliteration
        ) {
            settings.toggleNameFavorite(number: name.number)
        }
        .onTapGesture {
            settings.hapticFeedback()
            settings.toggleNameFavorite(number: name.number)
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        NamesView()
    }
}
