import SwiftUI

#if os(iOS)

struct AyahQiraahComparisonSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    let ayahNumber: Int
    @State private var searchText = ""
    // Comparing scripts is exactly when you want the text bigger; the slider only affects this sheet.
    @State private var arabicFontSize: Double = Double(UIFont.preferredFont(forTextStyle: .title3).pointSize)

    private struct QiraahDisplay: Identifiable {
        let label: String
        let tag: String
        let arabicCaption: String
        let teacher: String
        let teacherArabic: String
        let order: Int
        let beta: Bool

        var id: String { tag.isEmpty ? "Hafs" : tag }
    }

    /// `Settings.Riwayah.options` already omits the beta riwayat unless the user turned
    /// beta qiraat on, so comparison mode never surfaces unverified text by accident.
    private var options: [QiraahDisplay] {
        Settings.Riwayah.options.map {
            QiraahDisplay(
                label: $0.label,
                tag: $0.tag,
                arabicCaption: $0.arabic,
                teacher: $0.teacher,
                teacherArabic: $0.teacherArabic,
                order: $0.order,
                beta: $0.beta
            )
        }
    }

    private var favoriteOptions: [QiraahDisplay] {
        filteredOptions.filter { settings.isQiraahFavorite(tag: $0.tag) }
            .sorted { $0.order < $1.order }
    }

    private var groupedOptions: [(teacher: String, teacherArabic: String, options: [QiraahDisplay])] {
        Settings.Riwayah.groups.compactMap { group in
            let rows = filteredOptions
                .filter { $0.teacher == group.teacher && !settings.isQiraahFavorite(tag: $0.tag) }
                .sorted { $0.order < $1.order }
            guard !rows.isEmpty else { return nil }
            return (group.teacher, group.teacherArabic, rows)
        }
    }

    private var filteredOptions: [QiraahDisplay] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return options }
        return options.filter { option in
            option.label.localizedCaseInsensitiveContains(query) ||
            option.arabicCaption.localizedCaseInsensitiveContains(query) ||
            option.teacher.localizedCaseInsensitiveContains(query) ||
            option.teacherArabic.localizedCaseInsensitiveContains(query) ||
            (qiraahText(for: option)?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    // The riwayah the reader is currently displaying - pinned above the list so every row can be compared
    // against it without scrolling back up.
    private var currentOption: QiraahDisplay? {
        let tag = Settings.normalizeLegacyRiwayahTag(settings.displayQiraah)
        return options.first { $0.tag == tag }
    }

    var body: some View {
        NavigationView {
            // The pinned "current riwayah" strip rides as a safe-area inset on the List
            // rather than a VStack above it: with a VStack, the half-height (.medium)
            // sheet detent laid the header out as a blank gap until the sheet was
            // dragged to full height.
            List {
                    Group {
                        Section {
                            Text("Compare this ayah across the Arabic riwayat available in the app. Some riwayat merge or omit Hafs ayah numbers, so unavailable rows are dimmed. No ayah is ever missing; the same words may simply be joined or numbered differently.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if !favoriteOptions.isEmpty {
                            Section(header: Text("FAVORITES")) {
                                ForEach(favoriteOptions) { option in
                                    qiraahRow(option)
                                }
                            }
                        }

                        ForEach(groupedOptions, id: \.teacher) { group in
                            Section(header: Text("\(group.teacher.uppercased()) - \(group.teacherArabic)")) {
                                ForEach(group.options) { option in
                                    qiraahRow(option)
                                }
                            }
                        }

                        if filteredOptions.isEmpty {
                            Section {
                                Text("No riwayat found.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .themedListRowBackground()
                }
            .applyConditionalListStyle()
            .compactListSectionSpacing()
            .searchable(text: $searchText.animation(.easeInOut), prompt: "Search riwayat")
            .safeAreaInset(edge: .top, spacing: 0) {
                if let currentOption {
                    VStack(spacing: 0) {
                        currentQiraahHeader(currentOption)

                        Divider()
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            // The list below washes itself; this covers the header strip above it, so the whole
            // sheet sits on the same light.
            .accentWashedBackground()
        }
        .navigationViewStyle(.stack)
    }

    private func currentQiraahHeader(_ option: QiraahDisplay) -> some View {
        let text = qiraahText(for: option)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(option.label)
                    .font(.subheadline.weight(.semibold))

                Text(option.arabicCaption)
                    .font(.caption)
                    .foregroundColor(settings.accentColor.color)

                Spacer()

                Text("CURRENT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(text ?? "This ayah is not separate in this riwayah.")
                .font(.custom(comparisonArabicFontName(for: option), size: arabicFontSize))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .foregroundColor(text == nil ? .secondary : .primary)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)

            HStack(spacing: 12) {
                Image(systemName: "textformat.size.smaller")
                    .foregroundStyle(.secondary)

                Slider(value: $arabicFontSize, in: 15...45, step: 1)
                    .accessibilityLabel("Arabic font size")

                Image(systemName: "textformat.size.larger")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func qiraahText(for option: QiraahDisplay) -> String? {
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber),
              ayah.existsInQiraah(option.tag, surahID: surahNumber) else {
            return nil
        }
        return ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText, qiraahOverride: option.tag)
    }

    private func comparisonArabicFontName(for option: QiraahDisplay) -> String {
        settings.quranArabicFontName(for: option.tag)
    }

    private func qiraahRow(_ option: QiraahDisplay) -> some View {
        let text = qiraahText(for: option)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack {
                    HighlightedSnippet(
                        source: option.label,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    HighlightedSnippet(
                        source: option.arabicCaption,
                        term: searchText,
                        font: .caption,
                        accent: settings.accentColor.color,
                        fg: settings.accentColor.color
                    )
                }

                Spacer()

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.toggleQiraahFavorite(tag: option.tag)
                    }
                } label: {
                    Image(systemName: settings.isQiraahFavorite(tag: option.tag) ? "star.fill" : "star")
                        .foregroundStyle(settings.accentColor.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.isQiraahFavorite(tag: option.tag) ? "Unfavorite Riwayah" : "Favorite Riwayah")

                if text == nil {
                    Text("Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            HighlightedSnippet(
                source: text ?? "This ayah is not separate in this riwayah.",
                term: searchText,
                font: .custom(
                    comparisonArabicFontName(for: option),
                    size: arabicFontSize
                ),
                accent: settings.accentColor.color,
                fg: text == nil ? .secondary : .primary
            )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .opacity(text == nil ? 0.55 : 1)
        .textSelection(.enabled)
    }
}

private struct EnglishEdition: Identifiable {
    let id: String
    let name: String
}

private let inAppEnglishComparisonEditions: [EnglishEdition] = [
    EnglishEdition(id: "inapp.saheeh", name: "Saheeh International"),
    EnglishEdition(id: "inapp.mustafa", name: "Clear Quran (Mustafa Khattab)")
]

private let englishComparisonEditions: [EnglishEdition] = [
    EnglishEdition(id: "en.ahmedali", name: "Ahmed Ali"),
    EnglishEdition(id: "en.ahmedraza", name: "Ahmed Raza Khan"),
    EnglishEdition(id: "en.arberry", name: "A. J. Arberry"),
    EnglishEdition(id: "en.asad", name: "Muhammad Asad"),
    EnglishEdition(id: "en.daryabadi", name: "Abdul Majid Daryabadi"),
    EnglishEdition(id: "en.hilali", name: "Hilali & Khan"),
    EnglishEdition(id: "en.pickthall", name: "Pickthall"),
    EnglishEdition(id: "en.qaribullah", name: "Qaribullah & Darwish"),
    EnglishEdition(id: "en.sarwar", name: "Muhammad Sarwar"),
    EnglishEdition(id: "en.yusufali", name: "Yusuf Ali"),
    EnglishEdition(id: "en.maududi", name: "Abul Ala Maududi"),
    EnglishEdition(id: "en.shakir", name: "Shakir"),
    EnglishEdition(id: "en.itani", name: "Clear Quran (Talal Itani)"),
    EnglishEdition(id: "en.mubarakpuri", name: "Mubarakpuri"),
    EnglishEdition(id: "en.qarai", name: "Qarai"),
    EnglishEdition(id: "en.wahiduddin", name: "Wahiduddin Khan")
]

private struct AyahEditionResponse: Decodable {
    let data: [AyahEditionData]
}

private struct AyahEditionData: Decodable {
    let text: String
    let edition: AyahEditionMetadata
}

private struct AyahEditionMetadata: Decodable {
    let identifier: String
    let englishName: String?
}

@MainActor
private final class EnglishComparisonViewModel: ObservableObject {
    @Published private(set) var translations: [String: String] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let surah: Int
    private let ayah: Int
    private var loadedReference: String?

    init(surah: Int, ayah: Int) {
        self.surah = surah
        self.ayah = ayah
    }

    func loadIfNeeded() async {
        await load(surah: surah, ayah: ayah)
    }

    func load(surah: Int, ayah: Int) async {
        let reference = "\(surah):\(ayah)"
        guard loadedReference != reference || translations.isEmpty else { return }
        if isLoading { return }

        isLoading = true
        errorMessage = nil

        do {
            let editions = englishComparisonEditions.map(\.id).joined(separator: ",")
            guard let url = URL(string: "https://api.alquran.cloud/v1/ayah/\(reference)/editions/\(editions)") else {
                throw URLError(.badURL)
            }

            // Same insulation as the tafsir sheet: the page reader tears down its hosting view mid-flight,
            // and without the wrapper the resulting task cancellation killed the fetch with "Cancelled".
            let (data, response) = try await Task { try await URLSession.shared.data(from: url) }.value
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(AyahEditionResponse.self, from: data)
            translations = Dictionary(uniqueKeysWithValues: decoded.data.map { ($0.edition.identifier, $0.text) })
            loadedReference = reference
        } catch {
            if !AyahTafsirViewModel.isCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

struct AyahEnglishComparisonSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    let ayahNumber: Int

    @StateObject private var viewModel: EnglishComparisonViewModel
    @State private var searchText = ""

    init(surahNumber: Int, ayahNumber: Int) {
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        _viewModel = StateObject(wrappedValue: EnglishComparisonViewModel(surah: surahNumber, ayah: ayahNumber))
    }

    private var loadKey: String {
        "\(surahNumber):\(ayahNumber)"
    }

    private var filteredEditions: [EnglishEdition] {
        filteredOnlineEditions
    }

    private var filteredInAppEditions: [EnglishEdition] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = inAppEnglishComparisonEditions.sorted { lhs, rhs in
            let lhsFavorite = settings.isEnglishTranslationFavorite(id: lhs.id)
            let rhsFavorite = settings.isEnglishTranslationFavorite(id: rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        guard !query.isEmpty else { return sorted }

        return sorted.filter { edition in
            edition.name.localizedCaseInsensitiveContains(query) ||
            inAppTranslationText(for: edition.id).localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredOnlineEditions: [EnglishEdition] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = englishComparisonEditions.sorted { lhs, rhs in
            let lhsFavorite = settings.isEnglishTranslationFavorite(id: lhs.id)
            let rhsFavorite = settings.isEnglishTranslationFavorite(id: rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        guard !query.isEmpty else { return sorted }

        return sorted.filter { edition in
            edition.name.localizedCaseInsensitiveContains(query) ||
            (viewModel.translations[edition.id]?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var shouldShowQuranText: Bool {
        guard quranData.ayah(surah: surahNumber, ayah: ayahNumber) != nil else {
            return false
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) else { return false }
        let arabic = ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText)
        return "Transliteration".localizedCaseInsensitiveContains(query) ||
            arabic.localizedCaseInsensitiveContains(query) ||
            ayah.textTransliteration.localizedCaseInsensitiveContains(query)
    }

    // The translation the reader is currently displaying - pinned above the list so every row can be
    // compared against it without scrolling back up. When both in-app translations are shown in the
    // reader, Saheeh International stands in as "current".
    private var currentTranslationName: String {
        (settings.showEnglishSaheeh || !settings.showEnglishMustafa) ? "Saheeh International" : "Clear Quran (Mustafa Khattab)"
    }

    private var currentTranslationText: String? {
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) else { return nil }
        return (settings.showEnglishSaheeh || !settings.showEnglishMustafa) ? ayah.textEnglishSaheeh : ayah.textEnglishMustafa
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let currentTranslationText {
                    currentTranslationHeader(text: currentTranslationText)

                    Divider()
                }

                comparisonList
            }
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            // Same rule as the riwayah comparison: the list washes itself, this covers the header.
            .accentWashedBackground()
            .task(id: loadKey) {
                await viewModel.loadIfNeeded()
            }
        }
        .navigationViewStyle(.stack)
    }

    private func currentTranslationHeader(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(currentTranslationName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("CURRENT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var comparisonList: some View {
        List {
            Group {
                // The same prominent "online" card the tafsir sheet uses, so every online-backed sheet
                // discloses its source identically.
                Section {
                    OnlineNoticeCard(text: "Compare this ayah across several English Qur'an translations. The online translations are fetched from alquran.cloud; the downloaded ones are built into the app.")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if shouldShowQuranText,
                   let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) {
                    Section(header: Text("QURAN TEXT")) {
                        comparisonRow(
                            title: nil,
                            text: ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText),
                            isArabic: true
                        )

                        if settings.showTransliteration {
                            comparisonRow(title: "Transliteration", text: ayah.textTransliteration)
                        }
                    }
                }

                Section(header: Text("DOWNLOADED TRANSLATIONS")) {
                    if let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) {
                        ForEach(filteredInAppEditions) { edition in
                            comparisonRow(
                                title: edition.name,
                                text: inAppTranslationText(for: edition.id, ayah: ayah),
                                editionID: edition.id,
                                isDownloaded: true
                            )
                        }

                        if filteredInAppEditions.isEmpty {
                            Text("No downloaded translations found.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: Text("ONLINE TRANSLATIONS")) {
                    if viewModel.isLoading && viewModel.translations.isEmpty {
                        HStack {
                            ProgressView()
                            Text("Loading translations...")
                                .foregroundStyle(.secondary)
                        }
                    } else if let errorMessage = viewModel.errorMessage, viewModel.translations.isEmpty {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                        ForEach(filteredOnlineEditions) { edition in
                            comparisonRow(
                                title: edition.name,
                                text: viewModel.translations[edition.id] ?? "Unavailable",
                                editionID: edition.id
                            )
                            .opacity(viewModel.translations[edition.id] == nil ? 0.55 : 1)
                        }

                        if filteredOnlineEditions.isEmpty {
                            Text("No translations found.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .searchable(text: $searchText.animation(.easeInOut), prompt: "Search translations")
    }

    private func inAppTranslationText(for editionID: String, ayah: Ayah? = nil) -> String {
        let resolvedAyah = ayah ?? quranData.ayah(surah: surahNumber, ayah: ayahNumber)
        guard let resolvedAyah else { return "" }
        switch editionID {
        case "inapp.saheeh":
            return resolvedAyah.textEnglishSaheeh
        case "inapp.mustafa":
            return resolvedAyah.textEnglishMustafa
        default:
            return ""
        }
    }

    private func comparisonRow(title: String?, text: String, editionID: String? = nil, isArabic: Bool = false, isDownloaded: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title, !title.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HighlightedSnippet(
                        source: title,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    Spacer()

                    if let editionID, !isDownloaded {
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) {
                                settings.toggleEnglishTranslationFavorite(id: editionID)
                            }
                        } label: {
                            Image(systemName: settings.isEnglishTranslationFavorite(id: editionID) ? "star.fill" : "star")
                                .foregroundStyle(settings.accentColor.color)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(settings.isEnglishTranslationFavorite(id: editionID) ? "Unfavorite Translation" : "Favorite Translation")
                    }
                }
            }

            HighlightedSnippet(
                source: text,
                term: searchText,
                font: isArabic
                    ? Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize)
                    : .subheadline,
                accent: settings.accentColor.color,
                fg: .primary
            )
                .arabicFontDesign(custom: isArabic && settings.quranUsesCustomArabicFace)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(isArabic ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
        }
        .padding(.vertical, 4)
        .textSelection(.enabled)
    }
}

#endif
