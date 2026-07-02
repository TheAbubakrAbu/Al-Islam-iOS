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
    /// are false and the collapsed row shows no highlight — correct, since the match isn't visible. When a
    /// displayed field does match, its flag drives `guaranteeMatch` so that field always shows at least one
    /// highlight even if the highlighter's normalization differs from this search's (e.g. `ḥ` vs `h`).
    /// Indices mirror `searchTokens`: [0] = Arabic name, [1] = transliteration, [2] = meaning.
    func displayedFieldMatches(query rawQuery: String) -> (arabic: Bool, transliteration: Bool, meaning: Bool) {
        let q = Self.clean(rawQuery)
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

    func waitUntilLoaded() async {
        while true {
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
        filterCache[cleanedQuery] = matches
        return matches
    }
}

struct NamesView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var namesData: NamesViewModel

    @State private var searchText = ""
    @State private var expandedNameNumbers = Set<Int>()
    @AppStorage("namesDisplayMode") private var namesDisplayMode: String = "list"

    /// Cached so the diacritic-stripping `clean()` only runs when the query changes — not on every `body`
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

    private var favoriteNameNumberSet: Set<Int> {
        Set(settings.favoriteNameNumbers)
    }

    private var favoriteNames: [NameOfAllah] {
        namesData.namesOfAllah
            .filter { favoriteNameNumberSet.contains($0.number) }
            .sorted { $0.number < $1.number }
    }

    var body: some View {
        let hasActiveSearch = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        ScrollViewReader { proxy in
            List {
                Group {
                    descriptionSection
                    favoriteNamesSection(hasActiveSearch: hasActiveSearch, proxy: proxy)
                    namesHeaderSection(resultCount: filteredNames.count, hasActiveSearch: hasActiveSearch)
                    namesSections(filteredNames: filteredNames, hasActiveSearch: hasActiveSearch, proxy: proxy)
                    finalInvocationSection
                }
                .themedListRowBackground()
            }
        }
        #if os(watchOS)
        .searchable(text: $searchText.animation(.easeInOut))
        #else
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
                    Text("Quranic Font").tag(true)
                    Text("Basic Font").tag(false)
                }
                .pickerStyle(.segmented)
                // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
                .conditionalGlassEffect(interactive: false)
                .onChange(of: settings.useFontArabic) { _ in settings.hapticFeedback() }
                
                SearchBar(text: $searchText.animation(.easeInOut))
                    .padding([.horizontal, .top], -8)
            }
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
                    withAnimation { namesDisplayMode = namesDisplayMode == "grid" ? "list" : "grid" }
                } label: {
                    Image(systemName: namesDisplayMode == "grid" ? "list.bullet" : "square.grid.2x2")
                }
                .accessibilityLabel(namesDisplayMode == "grid" ? "Show list" : "Show grid")
            }
        }
        #endif
    }

    private var descriptionSection: some View {
        Section(header: Text("DESCRIPTION")) {
            Text("Prophet Muhammad ﷺ said, “Allah has 99 names, and whoever believes in their meanings and acts accordingly, will enter Paradise” (Bukhari 6410).")
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle("Show All Descriptions", isOn: showAllDescriptionsBinding)
                .font(.caption)
                .tint(settings.accentColor.color)
                .onChange(of: settings.showDescription) { _ in settings.hapticFeedback() }
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

    private func namesHeaderSection(resultCount: Int, hasActiveSearch: Bool) -> some View {
        Section(header: namesHeader(resultCount: resultCount, hasActiveSearch: hasActiveSearch)) { }
        .padding(.bottom, -12)
    }

    private func namesHeader(resultCount: Int, hasActiveSearch: Bool) -> some View {
        HStack {
            Text(hasActiveSearch ? "NAME SEARCH RESULTS" : "NAMES OF ALLAH")

            Spacer()

            if hasActiveSearch {
                Text(String(resultCount))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(settings.accentColor.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .conditionalGlassEffect()
            }
        }
    }

    @ViewBuilder
    private func favoriteNamesSection(hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        if !hasActiveSearch && !favoriteNames.isEmpty {
            Section(header: Text("FAVORITE NAMES")) {
                if namesDisplayMode == "grid" {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(favoriteNames, id: \.id) { name in
                            NameGridTile(
                                name: name,
                                isFavorite: true,
                                accentColor: settings.accentColor,
                                useFontArabic: settings.useFontArabic,
                                fontArabic: settings.fontArabic
                            )
                        }
                    }
                    .padding(.horizontal, -8)
                } else {
                    ForEach(favoriteNames, id: \.id) { name in
                        NameRow(
                            name: name,
                            firstFoundTarget: namesData.firstFoundTargetsByNameNumber[name.number],
                            showDescription: settings.showDescription,
                            isExpanded: expandedNameNumbers.contains(name.number),
                            isFavorite: true,
                            accentColor: settings.accentColor,
                            useFontArabic: settings.useFontArabic,
                            fontArabic: settings.fontArabic,
                            searchQuery: searchText
                        ) {
                            handleNameTap(name: name, hasActiveSearch: hasActiveSearch, proxy: proxy)
                        }
                        .id("favorite_name_\(name.number)")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func namesSections(filteredNames: [NameOfAllah], hasActiveSearch: Bool, proxy: ScrollViewProxy) -> some View {
        if namesDisplayMode == "grid" {
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(filteredNames, id: \.id) { name in
                        NameGridTile(
                            name: name,
                            isFavorite: favoriteNameNumberSet.contains(name.number),
                            accentColor: settings.accentColor,
                            useFontArabic: settings.useFontArabic,
                            fontArabic: settings.fontArabic
                        )
                    }
                }
                .padding(.horizontal, -8)
            }
        } else {
        ForEach(filteredNames, id: \.id) { name in
            Section {
                NameRow(
                    name: name,
                    firstFoundTarget: namesData.firstFoundTargetsByNameNumber[name.number],
                    showDescription: settings.showDescription,
                    isExpanded: expandedNameNumbers.contains(name.number),
                    isFavorite: favoriteNameNumberSet.contains(name.number),
                    accentColor: settings.accentColor,
                    useFontArabic: settings.useFontArabic,
                    fontArabic: settings.fontArabic,
                    searchQuery: searchText
                ) {
                    handleNameTap(name: name, hasActiveSearch: hasActiveSearch, proxy: proxy)
                }
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
                contentText: "He is Allah: the King, the Most Holy, the Source of Peace, the Guardian, the Almighty, the Compeller, the Supreme. Exalted is He above all partners."
            )

            VerseReflectionCard(
                title: "Surah Al-Hashr 59:24",
                contentText: "He is Allah, the Creator, the Originator, the Fashioner. To Him belong the Most Beautiful Names; all in the heavens and earth glorify Him."
            )
        }
    }
}

private struct NameRow: View, Equatable {
    @EnvironmentObject var settings: Settings
    
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
        fontArabic: String = Settings.shared.fontArabic,
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
            .contextMenu {
                Text("Name Actions")
                    .foregroundStyle(.secondary)

                favoriteMenuItem
                Divider()
                copyMenu
            }
            .swipeActions(edge: .leading) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.toggleNameFavorite(number: name.number)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(settings.accentColor.color)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.toggleNameFavorite(number: name.number)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(settings.accentColor.color)
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
                            .lineLimit(1)

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
                            font: useFontArabic ? .custom(fontArabic, size: 24) : .title3,
                            accent: accentColor.color,
                            fg: .primary,
                            guaranteeMatch: fieldMatches.arabic
                        )
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(name.numberArabic)
                            .font(.custom("KFGQPCQUMBULUthmanicScript-Regu", size: 28))
                            .foregroundColor(accentColor.color)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !showDescription {
                        settings.hapticFeedback()
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
    private var favoriteMenuItem: some View {
        Button(role: isFavorite ? .destructive : nil) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleNameFavorite(number: name.number)
            }
        } label: {
            Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "star.fill" : "star")
        }
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
            settings.hapticFeedback()
            settings.toggleNameFavorite(number: name.number)
        }
        .padding(.vertical, {
            if #available(iOS 26, *) { 0 } else { 8 }
        }())
    }

    #if os(iOS)
    private var copyMenu: some View {
        Group {
            menuItem("Copy All", text: """
            Arabic: \(name.name.removeDiacriticsFromLastLetter())
            Transliteration: \(name.transliteration)
            Translation: \(name.meaning)
            First Found: \(name.firstFoundShort)
            Description: \(name.desc)
            """)
            menuItem("Copy Arabic", text: name.name.removeDiacriticsFromLastLetter())
            menuItem("Copy Transliteration", text: name.transliteration)
            menuItem("Copy Translation", text: name.meaning)
            menuItem("Copy First Found", text: name.firstFoundShort)
            menuItem("Copy Description", text: name.desc)
        }
    }

    private func menuItem(_ label: String, text: String) -> some View {
        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = text
        } label: {
            Label(label, systemImage: "doc.on.doc")
        }
    }
    #endif

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
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    
    let name: NameOfAllah
    let firstFoundTarget: (surahID: Int, ayahID: Int)?
    let showDescription: Bool
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if showDescription || isExpanded {
                if !name.otherNames.isEmpty {
                    HStack {
                        Text("Other Names:")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)

                        Text(name.otherNames.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.primary)
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
    @EnvironmentObject var settings: Settings
    
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

private struct NameGridTile: View {
    @EnvironmentObject private var settings: Settings

    let name: NameOfAllah
    let isFavorite: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String

    var body: some View {
        VStack(spacing: 6) {
            Text(name.displayArabicName)
                .font(useFontArabic ? .custom(fontArabic, size: 20) : .title3)
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
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .conditionalGlassEffect(
            rectangle: true,
            useColor: isFavorite ? 0.25 : 0.12,
            customTint: isFavorite ? accentColor.color : nil
        )
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
