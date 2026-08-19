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
    @State private var showSummarize = false
    /// Smart comparison (default ON): rows are aligned through Hafs to the SAME WORDS even where a
    /// riwayah numbers this ayah differently or joins it with a neighbor. Off = each row shows that
    /// riwayah's ayah under this exact NUMBER, unaligned - useful for seeing the numbering itself.
    @AppStorage("qiraahSmartComparison") private var smartComparison = true
    /// Head-to-Head: pick exactly TWO riwayat and read them against each other - the list below
    /// steps aside while it's on. The tags persist so a reader comparing, say, Hafs vs Warsh across
    /// many ayat doesn't re-pick every time ("__unset__" = derive a sensible default).
    @AppStorage("qiraahDuelMode") private var duelMode = false
    @AppStorage("qiraahDuelATag") private var duelATagRaw = "__unset__"
    @AppStorage("qiraahDuelBTag") private var duelBTagRaw = "__unset__"
    /// Sheet-local Hide Tashkeel / Hide Dots, independent of the reader's global toggles: with the
    /// tashkeel and dots stripped, most riwayat collapse to the SAME Uthmani rasm skeleton - which
    /// is exactly what this sheet exists to show. Persisted so the exploration survives reopening.
    @AppStorage("qiraahCompareHideTashkeel") private var compareHideTashkeel = false
    @AppStorage("qiraahCompareHideDots") private var compareHideDots = false

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

    /// Comparison columns are pure TEXT - there is no facsimile fallback here - so
    /// they list `textOptions`: the beta riwayat appear only once their beta text
    /// has been accepted, never as a silent Hafs stand-in.
    private var options: [QiraahDisplay] {
        Settings.Riwayah.textOptions.map {
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
                            Toggle(isOn: $smartComparison.animation(.easeInOut)) {
                                Text("Smart Comparison")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .tint(settings.accentColor.color)
                            .onChange(of: smartComparison) { _ in settings.hapticFeedback() }
                        } footer: {
                            Text(smartComparison
                                 ? "Compare this ayah across the Arabic riwayat available in the app. Ayah numbering differs between riwayat, so rows are aligned to the SAME WORDS automatically; a note marks any riwayah that numbers this ayah differently or joins it with a neighbor. Words tinted in the accent color differ from the current riwayah's reading."
                                 : "Smart Comparison is off: each row shows that riwayah's ayah under this exact NUMBER, with no word alignment - where numbering differs, rows may show different words. Turn it on to align every row to the same words.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Section {
                            Toggle(isOn: $compareHideTashkeel.animation(.easeInOut)) {
                                Text("Hide Tashkeel and Signs")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .tint(settings.accentColor.color)
                            .onChange(of: compareHideTashkeel) { newValue in
                                settings.hapticFeedback()
                                // Dots without the tashkeel stripped is not a state the reading
                                // view offers either; keep the pair coupled the same way.
                                if !newValue { compareHideDots = false }
                            }

                            if compareHideTashkeel {
                                Toggle(isOn: $compareHideDots.animation(.easeInOut)) {
                                    Text("Hide Dots")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .tint(settings.accentColor.color)
                                .onChange(of: compareHideDots) { _ in settings.hapticFeedback() }
                            }
                        } footer: {
                            Text(rasmFooterText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Section {
                            Toggle(isOn: $duelMode.animation(.easeInOut)) {
                                Label {
                                    Text("Head-to-Head")
                                        .font(.subheadline.weight(.semibold))
                                } icon: {
                                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                                        .foregroundStyle(settings.accentColor.color)
                                }
                            }
                            .tint(settings.accentColor.color)
                            .onChange(of: duelMode) { _ in settings.hapticFeedback() }

                            if duelMode {
                                duelPickerRow

                                if let a = duelOptionA {
                                    duelCard(a, against: duelOptionB)
                                }
                                if let b = duelOptionB {
                                    duelCard(b, against: duelOptionA)
                                }
                            }
                        } footer: {
                            if duelMode {
                                Text(duelTextsIdentical
                                     ? "These two riwayat read this ayah with identical wording."
                                     : "Pick any two riwayat and read them directly against each other. Words tinted in the accent color differ between the two.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !duelMode {
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
                    }
                    .themedListRowBackground()
                }
            .applyConditionalListStyle()
            .compactListSectionSpacing()
            // The app's own bottom search bar, not `.searchable` - the same inset the reciter picker
            // (`SettingsQuranView.reciterSearchControlsInset`) and every other search in the app uses.
            // The filtering itself is untouched: `filteredOptions` still reads `searchText`.
            .adaptiveSafeArea(edge: .bottom) {
                // In Head-to-Head the list is hidden, so the search bar steps aside with it.
                if !duelMode {
                    SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: "Search riwayat")
                        .padding(.horizontal, 24)
                        .padding(.bottom, BottomBarCushion.standard)
                        .background(Color.white.opacity(0.00001))
                }
            }
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
            // On-device AI: summarize how the riwayat of this ayah compare - the current riwayah's
            // text plus every compared row's text and numbering/difference notes, as rendered.
            // Hidden when Apple Intelligence is unavailable (the Ask pattern).
            #if canImport(FoundationModels)
            .toolbar {
                // The availability check lives INSIDE the item (ViewBuilder, iOS 15-safe):
                // conditional toolbar items need the iOS 16 ToolbarContentBuilder.
                ToolbarItem(placement: .primaryAction) {
                    if OnDeviceAsk.isAvailable, !qiraahSummarizeSource.isEmpty {
                        SummarizeToolbarButton { showSummarize = true }
                    }
                }
            }
            .sheet(isPresented: $showSummarize) {
                SummarizeSheet(
                    title: "Tafsir, riwayat & translations of \(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))",
                    sourceText: "",
                    multiSource: true,
                    gatherSource: {
                        // Every ayah ask reads all three families - riwayat first here, since that is
                        // what this sheet is about. The online translations are fetched best-effort.
                        let anchor = AyahAISources.hafsAnchor(surahNumber: surahNumber, ayahNumber: ayahNumber)
                        let online = await AyahAISources.fetchOnlineTranslations(surahNumber: surahNumber, hafsAyah: anchor)
                        return OnDeviceAsk.combinedSource(
                            AyahAISources.combinedSections(
                                surahNumber: surahNumber,
                                ayahNumber: ayahNumber,
                                emphasis: .qiraah,
                                onlineTranslations: online
                            )
                        )
                    }
                )
            }
            #endif
        }
        .navigationViewStyle(.stack)
    }

    #if canImport(FoundationModels)
    /// The riwayat block of the summarize source (also the toolbar button's non-empty gate). The full
    /// gathering - tafsirs + riwayat + translations - lives in `AyahAISources`, shared by every ayah
    /// AI entry point.
    private var qiraahSummarizeSource: String {
        AyahAISources.qiraahComparisonText(surahNumber: surahNumber, ayahNumber: ayahNumber)
    }
    #endif

    /// The beta-text marker, comparison surfaces only (user rule: "say beta for the riwayah in qiraah
    /// comparison"). The riwayah pickers elsewhere stay unmarked - the riwayah itself is never beta,
    /// and outside comparison mode its text never renders.
    @ViewBuilder
    private func betaBadge(_ option: QiraahDisplay) -> some View {
        if option.beta {
            Text("BETA")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.15), in: Capsule())
        }
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

                betaBadge(option)

                Spacer()

                Text("CURRENT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // The current riwayah's own khilaf wash paints here too - same khilaf-only rule as
            // the comparison rows below (all other tajweed stays off in this sheet).
            Group {
                if text != nil, let styled = rowStyled(for: option, resolved: resolvedText(for: option)) {
                    Text(styled)
                } else {
                    Text(text ?? "This ayah is not separate in this riwayah.")
                }
            }
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

    /// The riwayah the sheet was OPENED from: the tapped ayah number is in THAT riwayah's own
    /// numbering, so every row is anchored through its Hafs equivalent.
    private var originTag: String { Settings.Riwayah.canonicalTag(settings.displayQiraah) }

    private var anchorHafsAyah: Int {
        QiraahComparison.hafsAnchor(surahID: surahNumber, ayahNumber: ayahNumber, tag: originTag, quranData: quranData)
    }

    /// The caption under the Hide Tashkeel / Hide Dots toggles. With either on it also REPORTS the
    /// result - how many riwayat now read identically to the current one - because seeing the
    /// shared Uthmani rasm emerge is the whole point of the toggles.
    private var rasmFooterText: String {
        guard compareHideTashkeel || compareHideDots else {
            return "Strip the vowel marks (and then the dots) to compare the bare letter skeletons. All qiraat descend from the dotless Uthmani rasm of the copies Uthman ibn Affan sent out, so most differences vanish at the skeleton level."
        }
        guard let reference = referenceText else { return "" }
        let others = options.filter { $0.id != currentOption?.id }
        let identical = others.filter { resolvedText(for: $0)?.text == reference }.count
        let what = compareHideDots ? "letter skeleton (rasm)" : "lettering"
        return "With these marks hidden, \(identical) of the \(others.count) other riwayat share this ayah's exact \(what) with the current riwayah. Rows tinted in the accent color still differ."
    }

    /// The sheet's Hide Tashkeel / Hide Dots, applied inside `resolvedText` - the one choke point
    /// every consumer of row text goes through (rows, diff reference, duel cards, search filter) -
    /// so the diff tint and the "identical" checks always operate on exactly what is displayed.
    private func compareTransformed(_ text: String) -> String {
        var out = text
        if compareHideTashkeel { out = out.removingArabicDiacriticsAndSigns }
        if compareHideDots { out = out.removingArabicDots }
        return out
    }

    /// The same WORDS as the tapped ayah, in this riwayah - the shared resolver, so the rows here and
    /// the AI gatherer serve identical text (see `QiraahAyahResolver`). With Smart Comparison off,
    /// the pre-resolver direct read instead: this riwayah's ayah under the tapped NUMBER, unaligned.
    /// Both paths resolve the FULL text (`clean: false`): the sheet's own toggles are the only
    /// cleanup applied here, so unchecking them restores tashkeel even when the reader's global
    /// Hide Tashkeel is on.
    private func resolvedText(for option: QiraahDisplay) -> ResolvedQiraahText? {
        let resolved: ResolvedQiraahText?
        if smartComparison {
            resolved = QiraahAyahResolver.resolve(
                surahNumber: surahNumber,
                ayahNumber: ayahNumber,
                anchorHafsAyah: anchorHafsAyah,
                optionTag: option.tag,
                clean: false
            )
        } else {
            let tag = Settings.Riwayah.canonicalTag(option.tag)
            guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber),
                  tag.isEmpty || ayah.existsInQiraah(tag, surahID: surahNumber) else { return nil }
            resolved = ResolvedQiraahText(
                text: ayah.displayArabicText(surahId: surahNumber, clean: false, qiraahOverride: tag),
                ownNumber: nil,
                mergedSpan: nil
            )
        }
        guard let resolved else { return nil }
        guard compareHideTashkeel || compareHideDots else { return resolved }
        return ResolvedQiraahText(
            text: compareTransformed(resolved.text),
            ownNumber: resolved.ownNumber,
            mergedSpan: resolved.mergedSpan
        )
    }

    private func qiraahText(for option: QiraahDisplay) -> String? {
        resolvedText(for: option)?.text
    }

    /// The current riwayah's resolved text - the reference every other row is diffed against.
    private var referenceText: String? {
        currentOption.flatMap { resolvedText(for: $0)?.text }
    }

    /// Differences from the CURRENT riwayah, tinted for `preStyledSource` - nil for the current row
    /// itself and for unavailable rows (an active search term overrides it by the snippet's rule).
    ///
    /// Always on, deliberately: comparing riwayat is the whole point of this sheet, so the diff tint
    /// is never gated on a setting. Do not reintroduce a `highlightQiraahDifferences`-style check here.
    private func diffStyled(for option: QiraahDisplay, resolved: ResolvedQiraahText?) -> AttributedString? {
        guard let resolved, option.id != currentOption?.id,
              let reference = referenceText, reference != resolved.text else { return nil }
        return QiraahComparison.diffAttributed(
            text: resolved.text,
            reference: reference,
            baseColor: .primary,
            diffColor: settings.accentColor.color
        )
    }

    private func numberNote(_ resolved: ResolvedQiraahText) -> String? {
        QiraahAyahResolver.numberNote(resolved)
    }

    /// The row's coloring: the accent diff tint (vs the current riwayah) with the print's KHILAF
    /// wash layered on top. In comparison every other tajweed rule stays off - the sheet is about
    /// what differs, so only khilaf_word/khilaf_harf paint, always on regardless of the tajweed
    /// toggle, and the khilaf magenta wins where both would color a word.
    private func rowStyled(for option: QiraahDisplay, resolved: ResolvedQiraahText?) -> AttributedString? {
        guard let resolved else { return nil }
        return khilafOverlaid(diffStyled(for: option, resolved: resolved), option: option, resolved: resolved)
    }

    /// Layers the print's KHILAF wash onto a diff-tinted base (or a plain-primary base) - shared by
    /// the current-vs-all rows and the Head-to-Head cards, so both color khilaf identically.
    private func khilafOverlaid(_ diff: AttributedString?, option: QiraahDisplay, resolved: ResolvedQiraahText) -> AttributedString? {
        let tag = Settings.Riwayah.canonicalTag(option.tag)
        guard !tag.isEmpty else { return diff }
        let ownAyah = resolved.ownNumber ?? ayahNumber
        let allRules = Set(QiraahTajweedStore.shared.legend(for: tag).map(\.key))
        let hidden = allRules.subtracting(["khilaf_word", "khilaf_harf"])
        guard let khilaf = QiraahTajweedStore.shared.attributedText(
            tag: tag, surah: surahNumber, ayah: ownAyah, displayText: resolved.text,
            hiddenRules: hidden
        ) else { return diff }

        // Overlay the khilaf runs onto the diff-tinted base (or a plain-primary base). Both strings
        // are built over `resolved.text`, so UTF-16 offsets transfer exactly.
        var merged = diff ?? {
            var plain = AttributedString(resolved.text)
            plain.foregroundColor = .primary
            return plain
        }()
        let khilafNS = NSAttributedString(khilaf)
        guard khilafNS.string == resolved.text else { return diff }
        khilafNS.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: khilafNS.length)) { value, nsRange, _ in
            guard let color = value as? UIColor, color != .label,
                  let range = Range(nsRange, in: resolved.text),
                  let start = AttributedString.Index(range.lowerBound, within: merged),
                  let end = AttributedString.Index(range.upperBound, within: merged) else { return }
            merged[start..<end].foregroundColor = Color(color)
        }
        return merged
    }

    // MARK: - Head-to-Head (compare exactly two riwayat)

    /// Side A defaults to the riwayah the reader is displaying; side B to the first other riwayah
    /// (Hafs, unless A IS Hafs). "__unset__" keeps the default alive until the reader picks.
    private var duelOptionA: QiraahDisplay? {
        if duelATagRaw != "__unset__", let picked = options.first(where: { $0.tag == duelATagRaw }) {
            return picked
        }
        return currentOption ?? options.first
    }

    private var duelOptionB: QiraahDisplay? {
        if duelBTagRaw != "__unset__", let picked = options.first(where: { $0.tag == duelBTagRaw }) {
            return picked
        }
        return options.first { $0.id != duelOptionA?.id }
    }

    private var duelTextsIdentical: Bool {
        guard let a = duelOptionA, let b = duelOptionB,
              let aText = qiraahText(for: a), let bText = qiraahText(for: b) else { return false }
        return aText == bText
    }

    private var duelPickerRow: some View {
        HStack(spacing: 10) {
            duelPicker(side: "A", selected: duelOptionA) { duelATagRaw = $0 }

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    let a = duelOptionA?.tag ?? "__unset__"
                    let b = duelOptionB?.tag ?? "__unset__"
                    duelATagRaw = b
                    duelBTagRaw = a
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                    .padding(6)
                    .background(Circle().fill(settings.accentColor.color.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Swap the two riwayat")

            duelPicker(side: "B", selected: duelOptionB) { duelBTagRaw = $0 }
        }
        .padding(.vertical, 2)
    }

    private func duelPicker(side: String, selected: QiraahDisplay?, choose: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(options) { option in
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { choose(option.tag) }
                } label: {
                    let title = "\(option.label) - \(option.teacher)\(option.beta ? " (Beta)" : "")"
                    if option.id == selected?.id {
                        Label(title, systemImage: "checkmark")
                    } else {
                        Text(title)
                    }
                }
            }
        } label: {
            VStack(spacing: 2) {
                Text(side)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text(selected?.label ?? "Choose")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(settings.accentColor.color.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    /// One side of the duel: the riwayah's aligned text, diffed against the OTHER side (not against
    /// the current riwayah), with its khilaf wash layered on top - the same styling stack as the rows.
    private func duelCard(_ option: QiraahDisplay, against other: QiraahDisplay?) -> some View {
        let resolved = resolvedText(for: option)
        let text = resolved?.text

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(option.label)
                    .font(.subheadline.weight(.semibold))

                Text(option.arabicCaption)
                    .font(.caption)
                    .foregroundColor(settings.accentColor.color)

                betaBadge(option)

                Spacer()

                if text == nil {
                    Text("Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let resolved, let note = numberNote(resolved) {
                Text(note)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
            }

            Group {
                if let resolved, let styled = duelStyled(for: option, resolved: resolved, against: other) {
                    Text(styled)
                } else {
                    Text(text ?? "This ayah is not separate in this riwayah.")
                }
            }
                .font(.custom(comparisonArabicFontName(for: option), size: arabicFontSize))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .foregroundColor(text == nil ? .secondary : .primary)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .opacity(text == nil ? 0.55 : 1)
        .textSelection(.enabled)
    }

    private func duelStyled(for option: QiraahDisplay, resolved: ResolvedQiraahText, against other: QiraahDisplay?) -> AttributedString? {
        var diff: AttributedString?
        if let other, other.id != option.id,
           let reference = qiraahText(for: other), reference != resolved.text {
            diff = QiraahComparison.diffAttributed(
                text: resolved.text,
                reference: reference,
                baseColor: .primary,
                diffColor: settings.accentColor.color
            )
        }
        return khilafOverlaid(diff, option: option, resolved: resolved)
    }

    private func comparisonArabicFontName(for option: QiraahDisplay) -> String {
        settings.quranArabicFontName(for: option.tag)
    }

    private func qiraahRow(_ option: QiraahDisplay) -> some View {
        let resolved = resolvedText(for: option)
        let text = resolved?.text

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

                    betaBadge(option)
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

            // The smart-alignment receipt: when this riwayah numbers the ayah differently (or joins
            // it with a neighbor), say so plainly - the words below are still the SAME ayah.
            if let resolved, let note = numberNote(resolved) {
                Text(note)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
            }

            HighlightedSnippet(
                source: text ?? "This ayah is not separate in this riwayah.",
                term: searchText,
                font: .custom(
                    comparisonArabicFontName(for: option),
                    size: arabicFontSize
                ),
                accent: settings.accentColor.color,
                fg: text == nil ? .secondary : .primary,
                preStyledSource: rowStyled(for: option, resolved: resolved)
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

    /// True for the errors a torn-down SwiftUI task produces - never worth showing to the reader.
    /// (Lived on the tafsir view model until tafsir moved to bundled packs and stopped fetching.)
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return (error as NSError).code == NSURLErrorCancelled
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
            if !Self.isCancellation(error) {
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
    @State private var showSummarize = false

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
            // The pinned "current translation" strip rides as a safe-area inset on the List rather
            // than a VStack above it - the exact structure (and reason) of the riwayah comparison's
            // header: with a VStack, the half-height (.medium) sheet detent laid the header out as a
            // blank gap, and the "Saheeh International / CURRENT" strip only appeared once the sheet
            // was dragged to full height.
            comparisonList
            .safeAreaInset(edge: .top, spacing: 0) {
                if let currentTranslationText {
                    VStack(spacing: 0) {
                        currentTranslationHeader(text: currentTranslationText)

                        Divider()
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            // Same rule as the riwayah comparison: the list washes itself, this covers the header.
            .accentWashedBackground()
            .task(id: loadKey) {
                await viewModel.loadIfNeeded()
            }
            // On-device AI: summarize how the translations of this ayah compare, then chat about it -
            // grounded only on the texts below. Hidden when Apple Intelligence is unavailable.
            #if canImport(FoundationModels)
            .toolbar {
                // The availability check lives INSIDE the item (ViewBuilder, iOS 15-safe):
                // conditional toolbar items need the iOS 16 ToolbarContentBuilder.
                ToolbarItem(placement: .primaryAction) {
                    if OnDeviceAsk.isAvailable, !summarizeSourceText.isEmpty {
                        SummarizeToolbarButton { showSummarize = true }
                    }
                }
            }
            .sheet(isPresented: $showSummarize) {
                SummarizeSheet(
                    title: "Tafsir, riwayat & translations of \(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))",
                    sourceText: "",
                    multiSource: true,
                    gatherSource: {
                        // Every ayah ask reads all three families - translations first here, since
                        // that is what this sheet is about. The already-loaded online editions are
                        // reused; a fetch only runs if the sheet's own load hasn't landed yet.
                        let anchor = AyahAISources.hafsAnchor(surahNumber: surahNumber, ayahNumber: ayahNumber)
                        let online = viewModel.translations.isEmpty
                            ? await AyahAISources.fetchOnlineTranslations(surahNumber: surahNumber, hafsAyah: anchor)
                            : viewModel.translations
                        return OnDeviceAsk.combinedSource(
                            AyahAISources.combinedSections(
                                surahNumber: surahNumber,
                                ayahNumber: ayahNumber,
                                emphasis: .translations,
                                onlineTranslations: online
                            )
                        )
                    }
                )
            }
            #endif
        }
        .navigationViewStyle(.stack)
    }

    /// Everything the sheet is showing, as one labeled text for the summarizer: the in-app
    /// translations plus whichever online editions have loaded.
    private var summarizeSourceText: String {
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) else { return "" }

        var lines: [String] = []
        for edition in inAppEnglishComparisonEditions {
            let text = inAppTranslationText(for: edition.id, ayah: ayah)
            if !text.isEmpty {
                lines.append("\(edition.name): \(text)")
            }
        }
        for edition in englishComparisonEditions {
            if let text = viewModel.translations[edition.id], !text.isEmpty {
                lines.append("\(edition.name): \(text)")
            }
        }
        return lines.joined(separator: "\n\n")
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

            SelectableProse(text: text, textStyle: .subheadline)
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
        // The app's own bottom search bar, not `.searchable` - see the riwayah sheet above.
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: "Search translations")
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
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

struct ResolvedQiraahText {
    let text: String
    /// The riwayah's OWN number for this ayah, when it differs from the number the sheet was
    /// opened with (riwayat count ayahs differently - the words are aligned, the number moves).
    let ownNumber: Int?
    /// The Hafs ayahs this riwayah ayah spans (more than one = it joins neighbors).
    let mergedSpan: ClosedRange<Int>?
}

/// How a given riwayah renders ayah (`surahNumber`, `ayahNumber` in the ORIGIN riwayah's numbering) -
/// anchored through Hafs so merged/shifted numbering never serves the wrong verse (the old direct read
/// did exactly that for every non-Kufi-counted riwayah). File-scope rather than view-local so the
/// comparison rows and the AI summarize gatherer (`AyahAISources`) resolve identical text.
@MainActor
enum QiraahAyahResolver {
    /// `clean` = strip tashkeel/signs via `displayArabicText`. The comparison sheet passes `false`
    /// and layers its OWN sheet-local Hide Tashkeel / Hide Dots on top (so unchecking them there
    /// restores the full text even when the reader's global setting is on); the AI gatherer passes
    /// the reader's global setting, matching what is on screen.
    static func resolve(
        surahNumber: Int,
        ayahNumber: Int,
        anchorHafsAyah: Int,
        optionTag: String,
        clean: Bool
    ) -> ResolvedQiraahText? {
        let quranData = QuranData.shared
        let tag = Settings.Riwayah.canonicalTag(optionTag)
        let anchor = anchorHafsAyah

        if tag.isEmpty {
            guard let ayah = quranData.ayah(surah: surahNumber, ayah: anchor) else { return nil }
            return ResolvedQiraahText(
                text: ayah.displayArabicText(surahId: surahNumber, clean: clean, qiraahOverride: ""),
                ownNumber: anchor == ayahNumber ? nil : anchor,
                mergedSpan: nil
            )
        }

        if let alignment = QiraahComparison.alignment(surahID: surahNumber, tag: tag, quranData: quranData),
           let ownNumber = alignment.riwayahNumberForHafs[anchor],
           let ayah = quranData.ayah(surah: surahNumber, ayah: ownNumber),
           ayah.existsInQiraah(tag, surahID: surahNumber) {
            let span = alignment.hafsRangeForRiwayah[ownNumber]
            return ResolvedQiraahText(
                text: ayah.displayArabicText(surahId: surahNumber, clean: clean, qiraahOverride: tag),
                ownNumber: ownNumber == ayahNumber ? nil : ownNumber,
                mergedSpan: (span.map { $0.count } ?? 1) > 1 ? span : nil
            )
        }

        // No alignment (this riwayah has no text for the surah): the old direct read, else
        // genuinely unavailable.
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber),
              ayah.existsInQiraah(tag, surahID: surahNumber) else { return nil }
        return ResolvedQiraahText(
            text: ayah.displayArabicText(surahId: surahNumber, clean: clean, qiraahOverride: tag),
            ownNumber: nil,
            mergedSpan: nil
        )
    }

    /// "Ayah 285 in this riwayah (spans 285\u{2013}286)" - the numbering note under a row's header.
    static func numberNote(_ resolved: ResolvedQiraahText) -> String? {
        if let own = resolved.ownNumber {
            if let span = resolved.mergedSpan {
                return "Ayah \(own) in this riwayah (spans \(span.lowerBound)\u{2013}\(span.upperBound))"
            }
            return "Ayah \(own) in this riwayah"
        }
        if let span = resolved.mergedSpan {
            return "One ayah here (spans \(span.lowerBound)\u{2013}\(span.upperBound))"
        }
        return nil
    }
}

#if canImport(FoundationModels)
/// One shared source-gatherer for every ayah "Summarize with AI" entry point. Whichever sheet the ask
/// starts from - tafsir, riwayat, or translations - the model reads ALL THREE families for the ayah
/// (all six bundled tafsirs, every riwayah's aligned reading, and the English translations), with the
/// asking sheet's own family placed first. Lives in this file because the translation edition lists
/// and their fetch shape are file-private here.
@MainActor
enum AyahAISources {
    /// The family the ask came from - its sections lead, so the summary opens on what the user was reading.
    enum Family { case tafsir, qiraah, translations }

    /// Tafsirs and translations are keyed by Hafs numbering, while a sheet opened under another display
    /// riwayah hands over THAT riwayah's own ayah number - anchor through Hafs first.
    static func hafsAnchor(surahNumber: Int, ayahNumber: Int) -> Int {
        QiraahComparison.hafsAnchor(
            surahID: surahNumber,
            ayahNumber: ayahNumber,
            tag: Settings.Riwayah.canonicalTag(Settings.shared.displayQiraah),
            quranData: QuranData.shared
        )
    }

    static func combinedSections(
        surahNumber: Int,
        ayahNumber: Int,
        emphasis: Family,
        onlineTranslations: [String: String] = [:]
    ) -> [OnDeviceAsk.SummarizeSection] {
        let anchor = hafsAnchor(surahNumber: surahNumber, ayahNumber: ayahNumber)

        // All six bundled tafsir editions - a synchronous pack read (Hafs numbering).
        let tafsirSections = TafsirAuthor.allCases.compactMap { author -> OnDeviceAsk.SummarizeSection? in
            guard let entry = TafsirStore.shared.entry(author: author, surah: surahNumber, ayah: anchor) else { return nil }
            return OnDeviceAsk.SummarizeSection(label: author.summarizeSectionLabel, text: entry.content)
        }

        let qiraahSections = [OnDeviceAsk.SummarizeSection(
            label: "Riwayat (qiraah readings) of this ayah",
            text: qiraahComparisonText(surahNumber: surahNumber, ayahNumber: ayahNumber)
        )].filter { !$0.text.isEmpty }

        let translationSections = [OnDeviceAsk.SummarizeSection(
            label: "English translations of this ayah",
            text: translationsText(surahNumber: surahNumber, hafsAyah: anchor, online: onlineTranslations)
        )].filter { !$0.text.isEmpty }

        switch emphasis {
        case .tafsir: return tafsirSections + qiraahSections + translationSections
        case .qiraah: return qiraahSections + tafsirSections + translationSections
        case .translations: return translationSections + tafsirSections + qiraahSections
        }
    }

    /// The riwayat block: the current riwayah's reading first, then every other riwayah's aligned text
    /// with the same numbering/difference notes the comparison rows render.
    static func qiraahComparisonText(surahNumber: Int, ayahNumber: Int) -> String {
        let anchor = hafsAnchor(surahNumber: surahNumber, ayahNumber: ayahNumber)
        let currentTag = Settings.normalizeLegacyRiwayahTag(Settings.shared.displayQiraah)
        let options = Settings.Riwayah.textOptions

        func resolved(_ tag: String) -> ResolvedQiraahText? {
            QiraahAyahResolver.resolve(
                surahNumber: surahNumber,
                ayahNumber: ayahNumber,
                anchorHafsAyah: anchor,
                optionTag: tag,
                clean: Settings.shared.cleanArabicText
            )
        }

        var lines: [String] = []
        let currentOption = options.first { $0.tag == currentTag }
        let referenceText = currentOption.flatMap { resolved($0.tag)?.text }

        if let currentOption, let referenceText {
            let beta = currentOption.beta ? " [beta text]" : ""
            lines.append("\(currentOption.label) (\(currentOption.teacher))\(beta) [CURRENT riwayah]: \(referenceText)")
        }

        for option in options where option.tag != currentOption?.tag {
            let res = resolved(option.tag)
            var entry = "\(option.label) (\(option.teacher))\(option.beta ? " [beta text]" : ""): "
            if let res {
                entry += res.text
                if let note = QiraahAyahResolver.numberNote(res) {
                    entry += " [\(note)]"
                }
                if let referenceText {
                    entry += referenceText == res.text
                        ? " [identical wording to the current riwayah]"
                        : " [wording differs from the current riwayah]"
                }
            } else {
                entry += "This ayah is not separate in this riwayah."
            }
            lines.append(entry)
        }

        return lines.joined(separator: "\n\n")
    }

    /// The translations block: the two bundled editions always, plus whichever online editions arrived.
    static func translationsText(surahNumber: Int, hafsAyah: Int, online: [String: String]) -> String {
        guard let ayah = QuranData.shared.ayah(surah: surahNumber, ayah: hafsAyah) else { return "" }

        var lines: [String] = []
        for edition in inAppEnglishComparisonEditions {
            let text = edition.id == "inapp.saheeh" ? ayah.textEnglishSaheeh : ayah.textEnglishMustafa
            if !text.isEmpty { lines.append("\(edition.name): \(text)") }
        }
        for edition in englishComparisonEditions {
            if let text = online[edition.id], !text.isEmpty {
                lines.append("\(edition.name): \(text)")
            }
        }
        return lines.joined(separator: "\n\n")
    }

    /// Best-effort fetch of the online translation editions, for the asks that start OUTSIDE the
    /// translation sheet (its own view model already holds them). Bounded and non-throwing: on any
    /// failure the summarize still runs with the bundled translations.
    static func fetchOnlineTranslations(surahNumber: Int, hafsAyah: Int) async -> [String: String] {
        let editions = englishComparisonEditions.map(\.id).joined(separator: ",")
        guard let url = URL(string: "https://api.alquran.cloud/v1/ayah/\(surahNumber):\(hafsAyah)/editions/\(editions)") else {
            return [:]
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        // Same torn-down-view insulation as `EnglishComparisonViewModel.load`: the wrapper keeps a
        // SwiftUI task cancellation from killing the fetch mid-flight.
        let fetchTask = Task { try await URLSession.shared.data(for: request) }
        guard let (data, response) = try? await fetchTask.value,
              (response as? HTTPURLResponse).map({ (200...299).contains($0.statusCode) }) ?? true,
              let decoded = try? JSONDecoder().decode(AyahEditionResponse.self, from: data) else {
            return [:]
        }
        return Dictionary(decoded.data.map { ($0.edition.identifier, $0.text) }, uniquingKeysWith: { first, _ in first })
    }
}
#endif

#endif
