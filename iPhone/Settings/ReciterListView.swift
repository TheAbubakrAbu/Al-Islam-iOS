import SwiftUI
import UIKit

private struct QiraahReciterSectionHeader: View {
    let title: String
    let arabic: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            
            Text("- \(arabic)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .padding(.vertical, 2)
            Spacer(minLength: 0)
        }
    }
}

private struct MurattalSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 2)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}

struct ReciterListView: View {
    /// When `true`, dismisses the sheet (or pops navigation) after the user picks a reciter or Random.
    /// Dismissal still waits until any confirmation dialog (qiraah change / Minshawi fallback) is resolved.
    var dismissAfterSelectingReciter = true
    /// When `false`, list opens at top without scrolling to the selected reciter.
    var autoScrollToInitialSelection = true

    @ObservedObject var settings = Settings.shared
    @Environment(\.presentationMode) private var presentationMode
    @State private var didAutoScrollToSelection = false
    @State private var searchText = ""
    @State private var pendingQiraahReciter: Reciter?
    @State private var pendingDisplayQiraahTag: String?
    @State private var pendingMinshawiReciter: Reciter?
    @State private var pendingMurattalStyleReciter: Reciter?
    @State private var pendingScrollToReciterID: String? = nil
    @State private var confirmHideQiraahDetails = false
    @AppStorage("splitMurattalRecitersByGroup") private var splitMurattalRecitersByGroup = false
    #if os(iOS)
    @StateObject private var downloadManager = ReciterDownloadManager.shared
    @State private var showDownloadedOnly = false
    #endif

    private struct MurattalReciterGroup: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let reciters: [Reciter]
    }

    #if os(iOS)
    @State private var showReciterTypeLegendInfo = false

    /// The colored legend that replaced the per-row explanatory captions: one dot per reciter type,
    /// with the full explanation one tap away.
    private var reciterTypeLegend: some View {
        // The dialog is attached to the compact dots cluster - not a full-width row - so on iPad it
        // pops from the legend itself.
        HStack {
            Spacer(minLength: 0)

            Button {
                settings.hapticFeedback()
                showReciterTypeLegendInfo = true
            } label: {
                HStack(spacing: 10) {
                    reciterTypeLegendItem(.blue, "Full offline")
                    reciterTypeLegendItem(.green, "Own voice")
                    reciterTypeLegendItem(.orange, "Murattal")
                    reciterTypeLegendItem(.red, "Surahs only")
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .confirmationDialog("Reciter Types", isPresented: $showReciterTypeLegendInfo, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text("Blue: the highest tier - surahs and individual ayahs play in this reciter's own voice, and downloaded surahs also play ayah-by-ayah fully offline. Green: individual ayahs play in this reciter's own voice when streaming. Orange: streamed ayahs play in a Murattal style; download the surah to hear ayahs in this reciter's own voice. Red: full surahs only - individual ayahs default to Minshawi (Murattal).")
        }

            Spacer(minLength: 0)
        }
    }

    private func reciterTypeLegendItem(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
    #endif

    private var qiraahChangeDialogTitle: String {
        pendingRequestedQiraahIsUnsupported ? "Qiraah Text Not Supported" : "Change Quran Text?"
    }

    private var qiraahChangeDialogMessage: String {
        if pendingRequestedQiraahIsUnsupported {
            let qiraahName = pendingQiraahReciter?.qiraah?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let qiraahName, !qiraahName.isEmpty {
                return "This reciter uses \(qiraahName). This qiraah text form is not supported right now. Keep your current Quran text and continue?"
            }
            return "This reciter's qiraah text form is not supported right now. Keep your current Quran text and continue?"
        }

        if pendingDisplayQiraahTag == nil {
            return "This reciter uses Hafs an Asim (default). Would you like to switch the Quran text to match it?"
        }

        guard let pendingQiraahReciter,
              let qiraah = pendingQiraahReciter.qiraah,
              !qiraah.isEmpty else {
            return "This reciter uses a different riwayah. Would you like to switch the Quran text to match it?"
        }

        return "This reciter uses \(qiraah). Would you like to switch the Quran text to match it?"
    }

    private func resolvedQiraahTag(for reciter: Reciter) -> String? {
        if let qiraah = reciter.qiraah, !qiraah.isEmpty {
            return qiraah
        }

        // Hafs reciters are represented by nil/empty qiraah in these primary sections.
        return nil
    }

    private func isSupportedQiraahForText(_ qiraahTag: String?) -> Bool {
        guard let qiraahTag, !qiraahTag.isEmpty else { return true }
        return Settings.Riwayah.menuOptions.contains(where: { $0.tag == qiraahTag })
    }

    private var pendingRequestedQiraahIsUnsupported: Bool {
        !isSupportedQiraahForText(pendingDisplayQiraahTag)
    }

    private struct ReciterSectionGroup: Identifiable {
        let id: String
        let title: String
        let arabic: String?
        let reciters: [Reciter]
        let isQiraah: Bool

        func withReciters(_ reciters: [Reciter]) -> ReciterSectionGroup {
            ReciterSectionGroup(id: id, title: title, arabic: arabic, reciters: reciters, isQiraah: isQiraah)
        }
    }

    private static let qiraahSearchKeywords = [
        "qiraah",
        "qiraat",
        "riwayah",
        "riwayaat",
        "recitation",
        "recitations"
    ]

    private static let hafsSearchKeywords = [
        "hafs",
        "asim",
        "aasim",
        "asim",
        "حفص",
        "عاصم"
    ]

    private func isSelectedReciter(_ reciter: Reciter) -> Bool {
        guard settings.reciter != Settings.randomReciterName else { return false }
        if !settings.reciterId.isEmpty {
            return settings.reciterId == reciter.id
        }
        return false
    }

    private var orderedUniqueReciters: [Reciter] {
        var seen = Set<String>()
        return allReciterSections
            .flatMap(\.reciters)
            .filter { seen.insert($0.id).inserted }
    }

    private var favoriteReciters: [Reciter] {
        orderedUniqueReciters.filter { settings.isReciterFavorite(reciterID: $0.id) }
    }

    /// Matches row `.id(...)` for `ScrollViewReader.scrollTo`.
    private var reciterListScrollTargetID: String {
        if settings.reciter == Settings.randomReciterName {
            return Settings.randomReciterName
        }
        if !settings.reciterId.isEmpty {
            return settings.reciterId
        }
        return settings.resolvedSelectedReciterIgnoringRandom()?.id ?? settings.reciter
    }

    private var normalizedSearchText: String {
        normalized(searchText)
    }

    private var isSearchingReciters: Bool {
        !normalizedSearchText.isEmpty
    }

    private var primaryReciterSections: [ReciterSectionGroup] {
        [
            ReciterSectionGroup(
                id: "minshawi",
                title: "MUHAMMAD SIDDIQ AL-MINSHAWI",
                arabic: nil,
                reciters: filteredReciters(recitersMinshawi),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "mujawwad",
                title: "SLOW & MELODIC (MUJAWWAD)",
                arabic: nil,
                reciters: filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "muallim",
                title: "TEACHING (MUALLIM)",
                arabic: nil,
                reciters: filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            ),
            ReciterSectionGroup(
                id: "murattal",
                title: "NORMAL (MURATTAL)",
                arabic: nil,
                reciters: filteredReciters(recitersMurattal, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries),
                isQiraah: false
            )
        ]
    }

    private var qiraahReciterSections: [ReciterSectionGroup] {
        let sections = [
            ReciterSectionGroup(
                id: "khalaf",
                title: Settings.Riwayah.khalaf.uppercased(),
                arabic: Settings.Riwayah.khalafArabic,
                reciters: filteredReciters(recitersKhalaf),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "warsh",
                title: Settings.Riwayah.warsh.uppercased(),
                arabic: Settings.Riwayah.warshArabic,
                reciters: filteredReciters(recitersWarsh),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "qaloon",
                title: Settings.Riwayah.qaloon.uppercased(),
                arabic: Settings.Riwayah.qaloonArabic,
                reciters: filteredReciters(recitersQaloon),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "buzzi",
                title: Settings.Riwayah.buzzi.uppercased(),
                arabic: Settings.Riwayah.buzziArabic,
                reciters: filteredReciters(recitersBuzzi),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "qunbul",
                title: Settings.Riwayah.qunbul.uppercased(),
                arabic: Settings.Riwayah.qunbulArabic,
                reciters: filteredReciters(recitersQunbul),
                isQiraah: true
            ),
            ReciterSectionGroup(
                id: "duri",
                title: Settings.Riwayah.duri.uppercased(),
                arabic: Settings.Riwayah.duriArabic,
                reciters: filteredReciters(recitersDuri),
                isQiraah: true
            )
        ]

        if let uncategorizedReciterSection {
            return sections + [uncategorizedReciterSection]
        }

        return sections
    }

    private var categorizedReciterIDs: Set<String> {
        Set((
            recitersMinshawi +
            recitersMurattal +
            recitersMujawwad +
            recitersMuallim +
            recitersKhalaf +
            recitersWarsh +
            recitersQaloon +
            recitersBuzzi +
            recitersQunbul +
            recitersDuri
        ).map(\.id))
    }

    private var uncategorizedReciterSection: ReciterSectionGroup? {
        let unmatched = filteredReciters(reciters)
            .filter { !categorizedReciterIDs.contains($0.id) }

        guard !unmatched.isEmpty else { return nil }
        return ReciterSectionGroup(
            id: "other-uncategorized",
            title: "OTHER GROUP",
            arabic: nil,
            reciters: unmatched,
            isQiraah: false
        )
    }

    private var allReciterSections: [ReciterSectionGroup] {
        primaryReciterSections + murattalGroupedSections.map { section in
            ReciterSectionGroup(id: section.id, title: section.title, arabic: nil, reciters: section.reciters, isQiraah: false)
        } + qiraahReciterSections
    }

    private var availableQiraahSections: [ReciterSectionGroup] {
        settings.showQiraahDetails ? qiraahReciterSections : []
    }

    private var searchResultTitle: String {
        isSearchingReciters ? "SEARCH RESULTS" : ""
    }

    private var searchableReciterSections: [ReciterSectionGroup] {
        var sections = primaryReciterSections.filter { $0.id != "murattal" }

        sections += murattalGroupedSections.map { group in
            ReciterSectionGroup(id: group.id, title: group.title, arabic: nil, reciters: group.reciters, isQiraah: false)
        }

        sections.append(primaryReciterSections.first { $0.id == "murattal" } ?? ReciterSectionGroup(id: "murattal", title: "NORMAL (MURATTAL)", arabic: nil, reciters: [], isQiraah: false))
        sections += availableQiraahSections
        return sections.filter { !$0.reciters.isEmpty }
    }

    private var searchResultSections: [ReciterSectionGroup] {
        guard isSearchingReciters else { return [] }

        return searchableReciterSections.compactMap { section in
            let sectionMatchesTitle = matchesSectionTitle(section, query: normalizedSearchText)
            let reciters = sectionMatchesTitle
                ? section.reciters
                : section.reciters.filter { reciterMatchesSearch($0, query: normalizedSearchText) }

            guard !reciters.isEmpty else { return nil }
            return section.withReciters(reciters)
        }
    }

    private var searchResultCount: Int {
        searchResultSections.reduce(0) { $0 + $1.reciters.count }
    }

    private func requestScrollToReciter(_ reciter: Reciter) {
        withAnimation {
            searchText = ""
            pendingScrollToReciterID = reciter.id
            endEditing()
        }
    }

    private var murattalRecitersFiltered: [Reciter] {
        filteredReciters(recitersMurattal, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries)
    }

    private var murattalGroupedSections: [MurattalReciterGroup] {
        var groups: [MurattalReciterGroup] = []

        let all = murattalRecitersFiltered

        func matches(_ reciter: Reciter, containsAny values: [String]) -> Bool {
            let n = normalized(reciter.name)
            return values.contains { n.contains($0) }
        }

        func group(id: String, title: String, subtitle: String, containsAny values: [String]) -> [Reciter] {
            all.filter { reciter in matches(reciter, containsAny: values) }
        }

        let haramain = group(
            id: "haramain",
            title: "HARAMAIN (MAKKAH & MADINAH)",
            subtitle: "Most recognized globally",
            containsAny: [
                "abdul rahman al-sudais",
                "saud al-shuraim",
                "maher al-muaiqly",
                "abdullah al-juhany",
                "bandar baleela",
                "yasser al-dosari",
                "badr al-turki"
            ]
        )

        let classicalEgyptian = group(
            id: "classical-egypt",
            title: "CLASSICAL EGYPTIAN SCHOOL",
            subtitle: "Deep tajweed and slower murattal",
            containsAny: [
                "abdul basit",
                "mahmoud al-hussary",
                "muhammad al-minshawi",
                "mustafa ismail",
                "mahmoud ali al-banna"
            ]
        )

        let contemporary = group(
            id: "contemporary",
            title: "FAMOUS CONTEMPORARY RECITERS",
            subtitle: "Well-known and widely listened to",
            containsAny: [
                "mishary alafasy",
                "ahmad al-ajmy",
                "saad al-ghamdi",
                "hani al-rifai",
                "abu bakr al-shatri",
                "muhammad al-luhaidan",
                "hazza al-balushi",
                "ahmad al-nufais",
            ]
        )

        let classicHaramain = group(
            id: "classic-haramain",
            title: "CLASSIC HARAMAIN & OLDER IMAMS",
            subtitle: "Older but iconic voices",
            containsAny: [
                "ali jaber",
                "muhammad ayyub"
            ]
        )

        let usedIDs = Set((haramain + classicalEgyptian + contemporary + classicHaramain).map(\.id))
        let other = all.filter { !usedIDs.contains($0.id) }

        if !haramain.isEmpty {
            groups.append(.init(id: "haramain", title: "HARAMAIN (MAKKAH & MADINAH)", subtitle: "Most recognized globally", reciters: haramain))
        }
        if !classicalEgyptian.isEmpty {
            groups.append(.init(id: "classical-egypt", title: "CLASSICAL EGYPTIAN SCHOOL", subtitle: "Deep tajweed and slower murattal", reciters: classicalEgyptian))
        }
        if !contemporary.isEmpty {
            groups.append(.init(id: "contemporary", title: "FAMOUS CONTEMPORARY RECITERS", subtitle: "Well-known and widely listened to", reciters: contemporary))
        }
        if !classicHaramain.isEmpty {
            groups.append(.init(id: "classic-haramain", title: "CLASSIC HARAMAIN & OLDER IMAMS", subtitle: "Older but iconic voices", reciters: classicHaramain))
        }
        if !other.isEmpty {
            groups.append(.init(id: "other", title: "OTHER RECITERS", subtitle: "Less mainstream or distinct styles", reciters: other))
        }

        return groups
    }

    private var searchableQiraahSections: [ReciterSectionGroup] {
        qiraahReciterSections.filter { !$0.reciters.isEmpty }
    }

    private func searchResultsBanner() -> some View {
        HStack(spacing: 10) {
            Text(searchResultTitle)

            Spacer()

            Text("\(searchResultCount)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private var noSearchResultsView: some View {
        Text("No reciters matched your search.")
            .foregroundStyle(.secondary)
    }

    private var reciterSearchControlsInset: some View {
        #if os(iOS)
        SearchBar(text: $searchText.animation(.easeInOut))
        .padding([.leading, .top], -8)
        #else
        EmptyView()
        #endif
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isGeneralQiraahSearch(_ query: String) -> Bool {
        Self.qiraahSearchKeywords.contains { query.contains($0) }
    }

    private func isGeneralHafsSearch(_ query: String) -> Bool {
        Self.hafsSearchKeywords.contains { query.contains($0) }
    }

    private func matchesSectionTitle(_ section: ReciterSectionGroup, query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return normalized(section.title).contains(query)
            || normalized(section.arabic ?? "").contains(query)
    }

    private func reciterMatchesSearch(_ reciter: Reciter, query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return normalized(reciter.name).contains(query)
    }

    /// Entry point for a reciter tap. Reciters with no ayah feed (they fall back to Minshawi for ayahs)
    /// first get a confirmation dialog; everything else applies immediately.
    private func handleReciterTap(_ reciter: Reciter) {
        if reciter.defaultToMinshawi {
            pendingMinshawiReciter = reciter
        } else if reciter.ayahMurattalStyleNote != nil {
            // Mujawwad/Muallim variant with no true per-ayah recording in that style - confirm the ayah
            // audio will be this reciter's own Murattal.
            pendingMurattalStyleReciter = reciter
        } else {
            applyReciterSelection(reciter)
        }
    }

    private func applyReciterSelection(_ reciter: Reciter) {
        withAnimation {
            let selectedImmediately = selectReciter(reciter)
            if selectedImmediately && dismissAfterSelectingReciter {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @discardableResult
    private func selectReciter(_ reciter: Reciter) -> Bool {
        settings.setSelectedReciter(reciter)

        let targetQiraahTag = resolvedQiraahTag(for: reciter)
        if !isSupportedQiraahForText(targetQiraahTag) {
            pendingQiraahReciter = reciter
            pendingDisplayQiraahTag = targetQiraahTag
            return false
        }

        if settings.displayQiraahForArabic != targetQiraahTag {
            pendingQiraahReciter = reciter
            pendingDisplayQiraahTag = targetQiraahTag
            return false
        }

        pendingQiraahReciter = nil
        pendingDisplayQiraahTag = nil
        return true
    }

    private func confirmPendingQiraahSelection() {
        guard pendingQiraahReciter != nil else { return }

        if pendingRequestedQiraahIsUnsupported {
            self.pendingQiraahReciter = nil
            self.pendingDisplayQiraahTag = nil

            if dismissAfterSelectingReciter {
                presentationMode.wrappedValue.dismiss()
            }
            return
        }

        settings.displayQiraah = pendingDisplayQiraahTag ?? Settings.Riwayah.hafsTag
        self.pendingQiraahReciter = nil
        self.pendingDisplayQiraahTag = nil

        if dismissAfterSelectingReciter {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func declinePendingQiraahSelection() {
        pendingQiraahReciter = nil
        pendingDisplayQiraahTag = nil

        if dismissAfterSelectingReciter {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func hideQiraahDetails() {
        if settings.isHafsDisplay {
            withAnimation(.easeInOut) {
                settings.showQiraahDetails = false
            }
        } else {
            settings.showQiraahDetails = true
            confirmHideQiraahDetails = true
        }
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                Group {
                #if os(iOS)
                Section {
                    reciterTypeLegend
                }
                #endif
                if isSearchingReciters {
                    searchResultsBanner()

                    if searchResultSections.isEmpty {
                        noSearchResultsView
                    } else {
                        ForEach(searchResultSections) { section in
                            reciterSection(section)
                        }
                    }
                } else {
                    if !favoriteReciters.isEmpty {
                        Section(header: Text("FAVORITES")) {
                            reciterButtons(favoriteReciters)
                        }
                    }

                    Section {
                        randomReciterButton
                    }

                    #if os(iOS)
                    Section(header: Text("DOWNLOADED SURAHS")) {
                        Picker("Reciter Filter", selection: $showDownloadedOnly.animation(.easeInOut)) {
                            Text("All Reciters").tag(false)
                            Text("Downloaded Only").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: showDownloadedOnly) { _ in settings.hapticFeedback() }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Downloads are full-reciter packages (all 114 surahs).")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(.vertical, 2)

                            Text("Ayah download is not supported, only surah download.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        }

                        let downloadedCount = uniqueDownloadedReciterCount
                        Text("Downloaded reciters: \(downloadedCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)

                        if downloadedCount > 0 {
                            Button(role: .destructive) {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    downloadManager.deleteAllDownloads()
                                }
                            } label: {
                                Label("Delete All Downloads", systemImage: "trash.fill")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.red)
                                    .tint(.red)
                            }
                            .buttonStyle(.borderless)
                            .font(.caption.weight(.semibold))
                        }
                    }
                    #endif

                    if !filteredReciters(recitersMinshawi).isEmpty {
                        Section(header: Text("MUHAMMAD SIDDIQ AL-MINSHAWI")) {
                            // Prefixed ids: these same reciters also appear in their style sections below, so
                            // the featured copies must carry distinct view identities.
                            reciterButtons(filteredReciters(recitersMinshawi), idPrefix: "featured-minshawi")
                        }
                    }
                    
                    if !filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries).isEmpty {
                        Section(header: Text("SLOW & MELODIC (MUJAWWAD)")) {
                            reciterButtons(filteredReciters(recitersMujawwad, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries))
                        }
                    }

                    if !filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries).isEmpty {
                        Section(header: Text("TEACHING (MUALLIM)")) {
                            reciterButtons(filteredReciters(recitersMuallim, excludingFeaturedMinshawi: shouldHideDuplicateMinshawiEntries))
                        }
                    }

                    if !murattalRecitersFiltered.isEmpty {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                withAnimation {
                                    splitMurattalRecitersByGroup.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(splitMurattalRecitersByGroup ? "Show Murattal as One Section" : "Group Murattal Reciters")

                                    Spacer()

                                    Image(systemName: splitMurattalRecitersByGroup ? "rectangle.grid.1x2" : "square.grid.2x2")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }

                        if splitMurattalRecitersByGroup {
                            ForEach(murattalGroupedSections) { group in
                                Section(header: MurattalSectionHeader(title: group.title, subtitle: group.subtitle)) {
                                    reciterButtons(group.reciters)
                                }
                            }
                        } else {
                            Section(header: Text("NORMAL (MURATTAL)")) {
                                reciterButtons(murattalRecitersFiltered)
                            }
                        }
                    }
                    
                    #if os(iOS)
                    if !showDownloadedOnly {
                        if settings.showQiraahDetails {
                            Section {
                                Button {
                                    settings.hapticFeedback()
                                    hideQiraahDetails()
                                } label: {
                                    HStack {
                                        Label("Hide Other Qiraat Reciters", systemImage: "character.book.closed.fill.ar")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up")
                                    }
                                    .foregroundColor(settings.accentColor.color)
                                }
                            }
                            
                            Section(header: Text("ABOUT QIRAAT"), footer: Text("Play Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")) {
                                Text("""
                                The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the Muslims. From these, the 10 Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

                                The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

                                To learn more about the 7 Ahruf and the 10 Qiraat, see below and in Al-Islam View > Islamic Pillars and Basics.
                                """)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                                NavigationLink(destination: AhrufView()) {
                                    Text("The 7 Ahruf (Modes)")
                                }
                                .font(.subheadline)

                                NavigationLink(destination: QiraatView()) {
                                    Text("The 10 Qiraat (Recitations)")
                                }
                                .font(.subheadline)

                                Text("**All recitations above are *Hafs an Asim*, the most common and widespread Qiraah in the world today.**")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .padding(.top, 4)
                                
                                Text("All reciters below are available only for full surahs. Play Ayahs is unsupported for other qiraat.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            ForEach(searchableQiraahSections) { section in
                                reciterSection(section)
                            }
                        } else {
                            Section {
                                Button {
                                    settings.hapticFeedback()
                                    withAnimation(.easeInOut) {
                                        settings.showQiraahDetails = true
                                    }
                                } label: {
                                    HStack {
                                        Label("Show Other Qiraat Reciters", systemImage: "character.book.closed.fill.ar")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                    }
                                    .foregroundColor(settings.accentColor.color)
                                }
                            }
                        }
                    }
                    #else
                    if settings.showQiraahDetails {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                hideQiraahDetails()
                            } label: {
                                HStack {
                                    Label("Hide Other Qiraat Reciters", systemImage: "character.book.closed.fill.ar")
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }
                        
                        Section(header: Text("ABOUT QIRAAT"), footer: Text("Play Ayahs is unsupported for other qiraat. For full surahs, you can choose reciters by riwayah. If you play a surah while viewing a different qiraah on screen, the reciter may be in another riwayah, so the audio may not match the text you see. For beginners, staying with Hafs an Asim for both reading and listening is recommended.")) {
                            Text("""
                            The Quran was revealed by Allah in seven Ahruf (modes) to make recitation easy for the Muslims. From these, the 10 Qiraat (recitations) were preserved, where they are all mass-transmitted and authentically traced back to the Prophet ﷺ through unbroken chains of narration.

                            The Qiraat are not different Qurans; they are different prophetic ways of reciting the same Quran, letter for letter, word for word, all preserving the same meaning and message.

                            To learn more about the 7 Ahruf and the 10 Qiraat, see below and in Al-Islam View > Islamic Pillars and Basics.
                            """)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                            NavigationLink(destination: AhrufView()) {
                                Text("The 7 Ahruf (Modes)")
                            }
                            .font(.subheadline)

                            NavigationLink(destination: QiraatView()) {
                                Text("The 10 Qiraat (Recitations)")
                            }
                            .font(.subheadline)

                            Text("**All recitations above are *Hafs an Asim*, the most common and widespread Qiraah in the world today.**")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.top, 4)

                            Text("All reciters below are available only for full surahs. Play Ayahs is unsupported for other qiraat.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                        ForEach(searchableQiraahSections) { section in
                            reciterSection(section)
                        }
                    } else {
                        Section {
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    settings.showQiraahDetails = true
                                }
                            } label: {
                                HStack {
                                    Label("Show Other Qiraat Reciters", systemImage: "character.book.closed.fill.ar")
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                }
                                .foregroundColor(settings.accentColor.color)
                            }
                        }
                    }
            #endif
                }
            }
            .themedListRowBackground()
        }
            .navigationTitle("Select Reciter")
            #if os(iOS)
            .adaptiveSafeArea(edge: .bottom) {
                reciterSearchControlsInset
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .background(Color.white.opacity(0.00001))
            }
            #elseif os(watchOS)
            .searchable(text: $searchText.animation(.easeInOut))
            #endif
            .applyConditionalListStyle()
            .confirmationDialog(qiraahChangeDialogTitle, isPresented: Binding(
                get: { pendingQiraahReciter != nil },
                set: {
                    if !$0 {
                        pendingQiraahReciter = nil
                        pendingDisplayQiraahTag = nil
                    }
                }
            ), titleVisibility: .visible) {
                Button(pendingRequestedQiraahIsUnsupported ? "Yes, Keep Current Quran Text" : "Confirm and Change") {
                    settings.hapticFeedback()
                    confirmPendingQiraahSelection()
                }

                Button(pendingRequestedQiraahIsUnsupported ? "Cancel Selection" : "No, Don't Change Qiraah") {
                    settings.hapticFeedback()
                    declinePendingQiraahSelection()
                }
            } message: {
                Text(qiraahChangeDialogMessage)
            }
            .confirmationDialog("Ayahs Will Use Minshawi (Murattal)", isPresented: Binding(
                get: { pendingMinshawiReciter != nil },
                set: { if !$0 { pendingMinshawiReciter = nil } }
            ), titleVisibility: .visible) {
                Button("Select This Reciter") {
                    settings.hapticFeedback()
                    if let reciter = pendingMinshawiReciter {
                        pendingMinshawiReciter = nil
                        applyReciterSelection(reciter)
                    }
                }

                Button("Cancel") {
                    pendingMinshawiReciter = nil
                }
            } message: {
                Text("\(pendingMinshawiReciter?.name ?? "This reciter") only has full-surah recitation. Individual ayahs and custom ranges will play in \(Reciter.minshawiAyahFallbackName).")
            }
            .confirmationDialog("Ayahs Play in Murattal", isPresented: Binding(
                get: { pendingMurattalStyleReciter != nil },
                set: { if !$0 { pendingMurattalStyleReciter = nil } }
            ), titleVisibility: .visible) {
                Button("Select This Reciter") {
                    settings.hapticFeedback()
                    if let reciter = pendingMurattalStyleReciter {
                        pendingMurattalStyleReciter = nil
                        applyReciterSelection(reciter)
                    }
                }

                Button("Cancel") {
                    pendingMurattalStyleReciter = nil
                }
            } message: {
                Text("\(pendingMurattalStyleReciter?.name ?? "This reciter") has no separate ayah-by-ayah recording in this style, so individual ayahs and custom ranges will play in \(pendingMurattalStyleReciter?.ayahMurattalStyleNote ?? "Murattal"). Full-surah playback is unaffected.")
            }
            .confirmationDialog("Convert Qiraah to Hafs an Asim?", isPresented: $confirmHideQiraahDetails, titleVisibility: .visible) {
                Button("Yes") {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.displayQiraah = Settings.Riwayah.hafsTag
                        settings.showQiraahDetails = false
                    }
                }

                Button("No") {
                    settings.hapticFeedback()
                    settings.showQiraahDetails = true
                }
            } message: {
                Text("Are you sure? This will convert the qiraah back to Hafs an Asim.")
            }
            .onChange(of: pendingScrollToReciterID) { id in
                guard let id else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo(id, anchor: .top)
                        pendingScrollToReciterID = nil
                    }
                }
            }
            .onAppear {
                settings.migrateLegacyReciterIdIfNeeded()

                if settings.reciter.isEmpty
                    || (settings.reciter != Settings.randomReciterName && settings.resolvedSelectedReciterIgnoringRandom() == nil) {
                    withAnimation {
                        settings.applyDefaultReciterSelection()
                    }
                }

                #if os(iOS)
                reciters.forEach { downloadManager.ensureStateLoaded(for: $0) }
                downloadManager.purgeIncompleteReciterDownloads()
                #endif

                if autoScrollToInitialSelection && !didAutoScrollToSelection {
                    let target = reciterListScrollTargetID
                    didAutoScrollToSelection = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            scrollProxy.scrollTo(target, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private func filteredReciters(_ list: [Reciter], excludingFeaturedMinshawi: Bool = false) -> [Reciter] {
        let baseList = excludingFeaturedMinshawi
            ? list.filter { !recitersMinshawi.contains($0) }
            : list

        #if os(iOS)
        guard showDownloadedOnly else { return baseList }
        return baseList.filter { downloadManager.stateSnapshot(for: $0).completedSurahs > 0 }
        #else
        return baseList
        #endif
    }

    #if os(iOS)
    private var uniqueDownloadedReciterCount: Int {
        var seen = Set<String>()
        return reciters.reduce(into: 0) { count, reciter in
            guard downloadManager.stateSnapshot(for: reciter).completedSurahs > 0 else { return }
            guard seen.insert(reciter.id).inserted else { return }
            count += 1
        }
    }

    private var shouldHideDuplicateMinshawiEntries: Bool {
        // Minshawi is shown BOTH in his own featured section AND in the Mujawwad/Muallim/Murattal style
        // section his variant belongs to (each variant naturally lives in exactly one style section). The
        // featured section's rows carry a section-prefixed view id (see `reciterButtons(idPrefix:)`) so the
        // two copies never collide in the List; selection/favorites stay keyed on the bare reciter id, so
        // toggling either instance lights up both.
        false
    }
    #else
    private var shouldHideDuplicateMinshawiEntries: Bool {
        false
    }
    #endif

    /// A reciter tagged with a section-scoped view id. Minshawi appears in his own featured section AND in
    /// his style section, so the two copies must carry distinct SwiftUI identities (`idPrefix`) even though
    /// they wrap the same `Reciter` (selection/favorites stay keyed on the bare `reciter.id`).
    private struct KeyedReciterRow: Identifiable {
        let id: String
        let reciter: Reciter
    }

    @ViewBuilder
    private func reciterButtons(_ list: [Reciter], qiraah: Bool = false, idPrefix: String = "") -> some View {
        ForEach(list.map { KeyedReciterRow(id: idPrefix.isEmpty ? $0.id : "\(idPrefix)|\($0.id)", reciter: $0) }) { item in
            reciterRow(item.reciter, qiraah: qiraah)
                .id(item.id)
        }
    }

    @ViewBuilder
    private func reciterSection(_ section: ReciterSectionGroup) -> some View {
        if section.isQiraah {
            Section(header: QiraahReciterSectionHeader(title: section.title, arabic: section.arabic ?? "")) {
                reciterButtons(section.reciters, qiraah: true)
            }
            .id("search-qiraah-\(section.id)")
        } else {
            Section(header: Text(section.title)) {
                // The featured Minshawi section's rows are prefixed so they never collide with the same
                // reciters shown in their style sections.
                reciterButtons(section.reciters, idPrefix: section.id == "minshawi" ? "featured-minshawi" : "")
            }
        }
    }

    private var randomReciterButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                settings.setRandomReciterMode()
            }
            #if os(watchOS)
            presentationMode.wrappedValue.dismiss()
            #elseif os(iOS)
            if dismissAfterSelectingReciter {
                presentationMode.wrappedValue.dismiss()
            }
            #endif
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Label(Settings.randomReciterName, systemImage: "shuffle")
                        .foregroundColor(settings.reciter == Settings.randomReciterName ? settings.accentColor.color : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(settings.accentColor.color)
                        .opacity(settings.reciter == Settings.randomReciterName ? 1 : 0)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
                
                Text("A new reciter is chosen at random for every session.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }
        .id(Settings.randomReciterName)
    }

    @ViewBuilder
    private func reciterRow(_ reciter: Reciter, qiraah: Bool) -> some View {
        #if os(iOS)
        ReciterRow(
            reciter: reciter,
            qiraah: qiraah,
            isFavorite: settings.isReciterFavorite(reciterID: reciter.id),
            isSelected: isSelectedReciter(reciter),
            downloadState: downloadManager.stateSnapshot(for: reciter),
            accentColor: settings.accentColor,
            searchQuery: searchText,
            onSelect: {
                settings.hapticFeedback()
                handleReciterTap(reciter)
            },
            onScrollToReciter: {
                settings.hapticFeedback()
                requestScrollToReciter(reciter)
            }
        )
        .environmentObject(downloadManager)
        #else
        WatchReciterRow(
            reciter: reciter,
            qiraah: qiraah,
            isSelected: isSelectedReciter(reciter),
            accentColor: settings.accentColor,
            onSelect: {
                settings.hapticFeedback()
                withAnimation {
                    let selectedImmediately = selectReciter(reciter)
                    if selectedImmediately {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            },
            onToggleFavorite: {
                settings.hapticFeedback()
                settings.toggleReciterFavorite(reciterID: reciter.id)
            }
        )
        #endif
    }
}

#if os(iOS)
private struct ReciterRow: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var downloadManager = ReciterDownloadManager.shared

    let reciter: Reciter
    let qiraah: Bool
    let isFavorite: Bool
    let isSelected: Bool
    let downloadState: ReciterDownloadManager.DownloadState
    let accentColor: AccentColor
    let searchQuery: String
    let onSelect: () -> Void
    let onScrollToReciter: () -> Void

    @State private var confirmDownload = false

    var body: some View {
        let hasDownloads = downloadState.completedSurahs > 0
        let isDownloading = downloadState.isDownloading
        let overallProgress = min(
            max((Double(downloadState.completedSurahs) + downloadState.currentSurahProgress) / Double(max(downloadState.totalSurahs, 1)), 0),
            1
        )

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.body.weight(.semibold))
                    .foregroundColor(accentColor.color)
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.toggleReciterFavorite(reciterID: reciter.id)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        // The type dot the top-of-list legend explains - it replaced the caption note
                        // each row used to carry.
                        if !qiraah {
                            Circle()
                                .fill(reciterTypeDotColor)
                                .frame(width: 8, height: 8)
                        }

                        HighlightedSnippet(
                            source: reciter.name,
                            term: searchQuery,
                            font: .subheadline,
                            accent: accentColor.color,
                            fg: isSelected ? accentColor.color : .primary
                        )
                            .multilineTextAlignment(.leading)
                    }

                    if isDownloading {
                        ProgressView(value: overallProgress)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

                VStack(alignment: .trailing, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(accentColor.color)
                            .opacity(isSelected ? 1 : 0)

                        if isDownloading {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        downloadManager.cancelDownload(for: reciter)
                                        downloadManager.deleteDownloads(for: reciter)
                                    }
                                }
                        } else if hasDownloads {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.red)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    withAnimation {
                                        downloadManager.deleteDownloads(for: reciter)
                                    }
                                }
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.secondary)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    confirmDownload = true
                                }
                        }
                    }
                }
                .padding(.top, 4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            .swipeActions(edge: .trailing) {
                Button {
                    onScrollToReciter()
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
            .contextMenu {
                Text("Reciter Actions")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = reciter.displayNameWithEnglishQiraah
                } label: {
                    Label("Copy Name", systemImage: "doc.on.doc")
                }

                Button {
                    onScrollToReciter()
                } label: {
                    Label("Scroll to Reciter", systemImage: "arrow.down.circle")
                }
            }

            if isDownloading {
                Text("Downloading surah \(downloadState.currentSurahNumber ?? max(downloadState.completedSurahs + 1, 1)) of \(downloadState.totalSurahs) (\(Int(overallProgress * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            if hasDownloads {
                Text("Storage used: \(downloadManager.storageText(bytes: downloadState.totalBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }

            if let errorMessage = downloadState.errorMessage, !errorMessage.isEmpty {
                Text("Download error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 2)
            }
        }
        .confirmationDialog("Download \(reciter.name)?", isPresented: $confirmDownload, titleVisibility: .visible) {
            Button("Download All 114 Surahs") {
                settings.hapticFeedback()
                withAnimation {
                    downloadManager.beginDownloadAll(for: reciter)
                }
            }

            Button("Cancel") {}
        } message: {
            Text(reciter.supportsAyahSegments
                ? "This downloads all 114 full-surah recitations for offline playback. This reciter also supports ayah segments, so individual ayahs and custom ranges then play offline too, cut from the downloaded surah. It runs in the background and may use significant data and storage."
                : "This downloads all 114 full-surah recitations for offline playback - it does not download ayah-by-ayah audio. It runs in the background and may use significant data and storage.")
        }
        .onAppear {
            downloadManager.ensureStateLoaded(for: reciter)
        }
    }

    /// The legend color for this reciter's ayah-playback type: blue = the highest tier (surahs AND
    /// own-voice ayahs AND offline ayah segments once downloaded), green = own-voice streamed ayahs,
    /// orange = ayahs substitute a Murattal style, red = surahs only (ayahs default to Minshawi).
    private var reciterTypeDotColor: Color {
        if reciter.defaultToMinshawi { return .red }
        if reciter.ayahMurattalStyleNote != nil { return .orange }
        if reciter.supportsAyahSegments { return .blue }
        return .green
    }

    /// The one-line caption under the reciter name explaining how it plays INDIVIDUAL ayahs (segments vs.
    /// a substitute Murattal). Ordered most-specific first. (Replaced in the row by the legend dot;
    /// kept for reference.)
    @ViewBuilder
    private var reciterAyahSupportNote: some View {
        if reciter.defaultToMinshawi {
            reciterNoteText("This reciter supports surahs only. Ayahs default to Minshawi (Murattal).")
        } else if let style = reciter.ayahMurattalStyleNote {
            if reciter.supportsAyahSegments {
                // Segments, but no own streamed ayahs: the whole surah must be downloaded to hear an ayah
                // in this reciter's own voice.
                reciterNoteText("Streamed ayahs play in \(style). Download the surah to hear ayahs in this reciter's own voice, cut as offline ayah segments.")
            } else {
                reciterNoteText("Individual ayahs and custom ranges play in \(style).")
            }
        } else if reciter.supportsAyahSegments {
            // Own per-ayah stream AND offline segments.
            reciterNoteText("Downloaded surahs also play ayah-by-ayah offline, cut as precise ayah segments.")
        }
    }

    private func reciterNoteText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 2)
    }

}
#else
private struct WatchReciterRow: View {
    @ObservedObject private var settings = Settings.shared

    let reciter: Reciter
    let qiraah: Bool
    let isSelected: Bool
    let accentColor: AccentColor
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Button {
                        settings.hapticFeedback()
                        onToggleFavorite()
                    } label: {
                        Image(systemName: settings.isReciterFavorite(reciterID: reciter.id) ? "star.fill" : "star")
                            .foregroundColor(settings.isReciterFavorite(reciterID: reciter.id) ? .yellow : accentColor.color)
                    }
                    .buttonStyle(.plain)

                    Text(reciter.name)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? accentColor.color : .primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor.color)
                        .opacity(isSelected ? 1 : 0)
                }

                if !qiraah && reciter.defaultToMinshawi {
                    Text("This reciter supports surahs only. Ayahs default to Minshawi (Murattal).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

}
#endif
