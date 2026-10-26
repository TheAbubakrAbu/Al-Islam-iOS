import SwiftUI

#if os(iOS)

struct AyahQiraahComparisonSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    let ayahNumber: Int
    /// Pushed inside another sheet's stack (the tafsir sheet's comparison doors, Abu, 2026-10-22)
    /// rather than presented as a sheet of its own: no container of its own, no X.
    var embedded: Bool = false
    @State private var searchText = ""
    /// The Arabic size, shared with the Qiraat Explorer (the same four steps in the same options
    /// menu), so the two comparison screens read at one size.
    @AppStorage("qiraatExplorerFontSize") private var fontSize: Double = 24
    @State private var showSummarize = false
    @State private var showUnlock = false
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
    /// The rows' tajweed coloring (each print's khilaf wash). On by default, persisted, and
    /// independent of Hide Tashkeel / Hide Dots: the colors are painted over the full text and
    /// projected onto the stripped skeleton, so hiding the marks no longer hides the coloring.
    @AppStorage("qiraahCompareShowTajweed") private var compareShowTajweed = true

    #if DEBUG
    /// "-openQiraatExplorer": push the explorer as the sheet appears (its row cannot be tapped headlessly).
    @State private var debugOpenExplorer = false
    #endif

    private struct QiraahDisplay: Identifiable {
        let label: String
        let tag: String
        let arabicCaption: String
        let teacher: String
        let teacherArabic: String
        let order: Int
        let beta: Bool

        var id: String { tag.isEmpty ? "Hafs" : tag }

        /// The row's name as shown. The Arabic interface names the riwayah once, in Arabic (the
        /// caption beside it would repeat it); `label` stays English for search and the model's prompt.
        var shownLabel: String { AppLanguage.isArabicScript ? arabicCaption : label }
        var showsCaption: Bool { !AppLanguage.isArabicScript }
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

    private func favoriteOptions(from filtered: [QiraahDisplay]) -> [QiraahDisplay] {
        filtered.filter { settings.isQiraahFavorite(tag: $0.tag) }
            .sorted { $0.order < $1.order }
    }

    private func groupedOptions(from filtered: [QiraahDisplay]) -> [(teacher: String, teacherArabic: String, options: [QiraahDisplay])] {
        Settings.Riwayah.groups.compactMap { group in
            let rows = filtered
                .filter { $0.teacher == group.teacher && !settings.isQiraahFavorite(tag: $0.tag) }
                .sorted { $0.order < $1.order }
            guard !rows.isEmpty else { return nil }
            return (group.teacher, group.teacherArabic, rows)
        }
    }

    private var filteredOptions: [QiraahDisplay] {
        // Accent-blind ("Nāfiʿ" finds Nafi'), the way every other search in the app reads a query.
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).foldingLatinDiacritics
        guard !query.isEmpty else { return options }
        return options.filter { option in
            option.label.localizedStandardContains(query) ||
            option.arabicCaption.localizedStandardContains(query) ||
            option.teacher.localizedStandardContains(query) ||
            option.teacherArabic.localizedStandardContains(query) ||
            // The riwayah's own TEXT keeps its marks: a vowelled query here asks which reading carries
            // that vowel, which `localizedStandardContains` (mark-insensitive) cannot answer. The
            // Latin labels above stay accent-blind.
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
        // A NavigationStack on iOS 16+ (`SheetNavigationContainer`): the Qiraat Explorer door pushes
        // from this sheet, and `navigationDestination` needs the stack (a NavigationView drops it).
        // Embedded, the enclosing sheet's stack takes the pushes.
        if embedded {
            comparisonContent
        } else {
            SheetNavigationContainer { comparisonContent }
        }
    }

    /// The sheet's content below its container. The layout is the Qiraat Explorer's, the screen this
    /// one opens (2026-10-26, Abu: "compare qiraat looks so messy"): the options live in the toolbar
    /// menu, the mode is the Explorer's All Riwayat | Compare Two control in the pinned band, the
    /// riwayah rows come first, and the door to the explorer sits under them. Before, four
    /// single-switch sections with long footers and a font slider stood between the title and the
    /// first riwayah.
    private var comparisonContent: some View {
        List {
            Group {
                if duelMode {
                    duelSections
                } else {
                    allSections
                }

                moreSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        #if DEBUG
        .debugPushDestination(isPresented: $debugOpenExplorer) {
            QiraatExplorerView(surah: surahNumber, ayah: ayahNumber, originTag: originTag)
        }
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-openQiraatExplorer") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenExplorer = true }
        }
        #endif
        // The app's own bottom search bar, not `.searchable` - the same inset the reciter picker
        // (`SettingsQuranView.reciterSearchControlsInset`) and every other search in the app uses.
        .adaptiveSafeArea(edge: .bottom) {
            // In Compare Two the list is the two cards, so the search bar steps aside with the rows.
            if !duelMode {
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: String(localized: "Search riwayat"))
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
            }
        }
        // A safe-area inset rather than a VStack above the List: with a VStack, the half-height
        // (.medium) sheet detent laid the band out as a blank gap until the sheet was dragged up.
        .safeAreaInset(edge: .top, spacing: 0) { band }
        .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))
        .navigationBarTitleDisplayMode(.inline)
        .sheetDismissToolbarIf(!embedded)
        // The list below washes itself; this covers the band above it, so the whole sheet sits on
        // the same light.
        .accentWashedBackground()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                optionsMenu

                // On-device AI: summarize how the riwayat of this ayah compare. Hidden when Apple
                // Intelligence is unavailable (the Ask pattern); at the far end, where every ayah
                // sheet keeps it.
                #if canImport(FoundationModels)
                if OnDeviceAsk.isAvailable, AyahAISources.qiraahComparisonHasText(surahNumber: surahNumber, ayahNumber: ayahNumber) {
                    SummarizeToolbarButton { showSummarize = true }
                }
                #endif
            }
        }
        .sheet(isPresented: $showUnlock) { QiraatExplorerUnlockSheet() }
        .onChange(of: duelMode) { _ in settings.hapticFeedback() }
        .onChange(of: smartComparison) { _ in settings.hapticFeedback() }
        .onChange(of: compareShowTajweed) { _ in settings.hapticFeedback() }
        .onChange(of: compareHideTashkeel) { newValue in
            settings.hapticFeedback()
            // Dots without the tashkeel stripped is not a state the reading view offers either.
            if !newValue { compareHideDots = false }
        }
        .onChange(of: compareHideDots) { _ in settings.hapticFeedback() }
        #if canImport(FoundationModels)
        .sheet(isPresented: $showSummarize) {
            SummarizeSheet(
                title: "\(AyahAISources.combinedTitlePrefix) of \(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber, english: true))",
                displayTitle: AyahAISources.combinedDisplayTitle(of: ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber)),
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
                },
                excludedNote: AyahAISources.arabicExcludedNote
            )
        }
        #endif
    }

    // MARK: Toolbar

    /// The riwayat still locked behind the beta text notice, if any.
    private var lockedCount: Int {
        max(0, Settings.Riwayah.allOptions.count - options.count)
    }

    /// The Explorer's options menu with this sheet's own switches: what used to be four
    /// single-switch sections above the rows, and the text size that used to be a slider in the band.
    private var optionsMenu: some View {
        Menu {
            Picker("Text Size", selection: $fontSize) {
                Text("Small").tag(20.0)
                Text("Medium").tag(24.0)
                Text("Large").tag(28.0)
                Text("Extra Large").tag(34.0)
            }
            Divider()
            // `.automatic`, not the app's padded switch: inside a menu that style draws double-height
            // rows with stray checkmarks (see the memory note on menu toggles).
            Toggle(isOn: $smartComparison) {
                Label("Smart Comparison", systemImage: "wand.and.stars")
                Text("Line every row up to the same words")
            }
            .toggleStyle(.automatic)
            Toggle(isOn: $compareShowTajweed) {
                Label("Show Tajweed", systemImage: "paintpalette")
                Text("Each print's khilaf coloring")
            }
            .toggleStyle(.automatic)
            Divider()
            Toggle(isOn: $compareHideTashkeel) {
                Label("Hide Tashkeel and Signs", systemImage: "textformat")
                Text("Compare the bare lettering")
            }
            .toggleStyle(.automatic)
            Toggle(isOn: $compareHideDots) {
                Label("Hide Dots", systemImage: "circle.dotted")
                Text("Down to the Uthmani rasm")
            }
            .toggleStyle(.automatic)
            .disabled(!compareHideTashkeel)
            if lockedCount > 0 {
                Divider()
                Button {
                    showUnlock = true
                } label: {
                    Label("Compare All 20 Riwayat", systemImage: "flask")
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .fixedMenuOrder()
        .tint(settings.accentColor.color)
        .accessibilityLabel("Comparison options")
    }

    // MARK: The band

    /// The pinned band: the mode (the Explorer's All Riwayat | Compare Two), then the current
    /// riwayah's own text, the reference every row is read against, or Compare Two's two sides.
    private var band: some View {
        VStack(spacing: 10) {
            Picker("Mode", selection: $duelMode) {
                Text("All Riwayat").tag(false)
                Text("Compare Two").tag(true)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Comparison mode")

            if duelMode {
                sidesRow
            } else if let currentOption {
                currentRiwayah(currentOption)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }

    /// The riwayah the reader is displaying, pinned so every row can be compared against it without
    /// scrolling back up.
    private func currentRiwayah(_ option: QiraahDisplay) -> some View {
        let text = qiraahText(for: option)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(option.shownLabel)
                    .font(.subheadline.weight(.semibold))

                if option.showsCaption {
                    Text(option.arabicCaption)
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                }

                if option.beta { BetaBadge() }

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
                    Text(text ?? String(localized: "This ayah is not separate in this riwayah."))
                }
            }
                .font(.custom(comparisonArabicFontName(for: option), size: fontSize))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .foregroundColor(text == nil ? .secondary : .primary)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                .environment(\.layoutDirection, .leftToRight)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Compare Two's sides: the Explorer's band row, so the two screens pick their pair the same
    /// way (the app's one riwayah picker in its compact capsule, a swap between).
    private var sidesRow: some View {
        let accent = settings.accentColor.color
        return HStack(spacing: 8) {
            ArabicTextRiwayahPicker(
                selection: Binding(get: { duelOptionA?.tag ?? Settings.Riwayah.hafsTag }, set: { duelATagRaw = $0 }),
                sideLabel: "A", compactLabel: true)

            Button {
                settings.hapticFeedback()
                let a = duelOptionA?.tag ?? "__unset__"
                let b = duelOptionB?.tag ?? "__unset__"
                duelATagRaw = b
                duelBTagRaw = a
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(accent)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(accent.opacity(0.14)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Swap the two riwayat")

            ArabicTextRiwayahPicker(
                selection: Binding(get: { duelOptionB?.tag ?? Settings.Riwayah.hafsTag }, set: { duelBTagRaw = $0 }),
                sideLabel: "B", compactLabel: true)
        }
    }

    // MARK: The sections

    /// Every riwayah against the current one: the favorites first, then one section per qiraah.
    @ViewBuilder
    private var allSections: some View {
        // Derived ONCE per pass (Phase 10.8): `filteredOptions` resolves every riwayah's text while
        // a query is typed, and the lists below read it several times.
        let filtered = filteredOptions
        let favorites = favoriteOptions(from: filtered)
        let grouped = groupedOptions(from: filtered)

        if !favorites.isEmpty {
            Section(header: Text("FAVORITES")) {
                ForEach(favorites) { option in
                    qiraahRow(option)
                }
            }
        }

        ForEach(grouped, id: \.teacher) { group in
            Section(header: Text("\(group.teacher.uppercased()) - \(group.teacherArabic)")) {
                ForEach(group.options) { option in
                    qiraahRow(option)
                }
            }
        }

        if filtered.isEmpty {
            Section {
                Text("No riwayat found.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Compare Two: the pair read against each other.
    @ViewBuilder
    private var duelSections: some View {
        Section {
            if let a = duelOptionA {
                duelCard(a, against: duelOptionB)
            }
            if let b = duelOptionB {
                duelCard(b, against: duelOptionA)
            }
        } footer: {
            Text(duelFooterText)
        }
    }

    /// The door to the whole-Quran view, under the rows as the Explorer keeps its own doors: this
    /// sheet compares one ayah, the explorer finds the next one worth comparing. Its footer is the
    /// one note about what the rows show.
    private var moreSection: some View {
        Section {
            NavigationLink(destination: LazyDestination {
                QiraatExplorerView(surah: surahNumber, ayah: ayahNumber, originTag: originTag)
            }) {
                SettingsRowLabel(title: String(localized: "Qiraat Explorer"), systemImage: "arrow.left.and.right.text.vertical",
                                 subtitle: String(localized: "Every place the riwayat differ, side by side"))
            }
        } header: {
            Text("MORE")
        } footer: {
            if !comparisonNote.isEmpty {
                Text(comparisonNote)
            }
        }
    }

    /// What the rows show, said once under them: how they are aligned, what the accent tint means
    /// and, with marks hidden, how many riwayat now read alike (the receipt that makes hiding them
    /// worth it). Compare Two carries its own note under the pair.
    private var comparisonNote: String {
        guard !duelMode else { return "" }
        var parts = [smartComparison
            ? String(localized: "Rows are aligned to the same words through Hafs; a note marks a riwayah that numbers this ayah differently or joins it with a neighbor. Words in the accent color differ from the current riwayah.")
            : String(localized: "Smart Comparison is off: each row shows that riwayah's ayah under this exact number, so rows may show different words where the numbering differs.")]
        if compareHideTashkeel || compareHideDots {
            parts.append(rasmFooterText)
        }
        return parts.joined(separator: " ")
    }

    #if canImport(FoundationModels)
    /// The riwayat block of the summarize source (also the toolbar button's non-empty gate). The full
    /// gathering - tafsirs + riwayat + translations - lives in `AyahAISources`, shared by every ayah
    /// AI entry point.
    private var qiraahSummarizeSource: String {
        AyahAISources.qiraahComparisonText(surahNumber: surahNumber, ayahNumber: ayahNumber)
    }
    #endif

    /// The riwayah the sheet was OPENED from: the tapped ayah number is in THAT riwayah's own
    /// numbering, so every row is anchored through its Hafs equivalent.
    private var originTag: String { Settings.Riwayah.canonicalTag(settings.displayQiraah) }

    private var anchorHafsAyah: Int {
        QiraahComparison.hafsAnchor(surahID: surahNumber, ayahNumber: ayahNumber, tag: originTag, quranData: quranData)
    }

    /// The Hafs ayah a row's words belong to, which is what the variant clips are keyed by. The
    /// buttons were handed the sheet's own `ayahNumber`, the ORIGIN riwayah's number: opened from
    /// Warsh 2:9 (Hafs 2:10) they played Hafs 2:9 under ayah 10's words. With Smart Comparison off
    /// a row shows that riwayah's ayah under the tapped number, so its own anchor applies.
    private func audioHafsAyah(for option: QiraahDisplay) -> Int {
        smartComparison
            ? anchorHafsAyah
            : QiraahComparison.hafsAnchor(surahID: surahNumber, ayahNumber: ayahNumber, tag: option.tag, quranData: quranData)
    }

    /// The receipt for Hide Tashkeel / Hide Dots: how many riwayat now read identically to the
    /// current one, because seeing the shared Uthmani rasm emerge is the whole point of the two.
    /// Part of `comparisonNote` while either is on.
    private var rasmFooterText: String {
        guard compareHideTashkeel || compareHideDots else {
            return String(localized: "Strip the vowel marks (and then the dots) to compare the bare letter skeletons. All qiraat descend from the dotless Uthmani rasm of the copies Uthman ibn Affan sent out, so most differences vanish at the skeleton level.")
        }
        guard let reference = referenceText else { return "" }
        let others = options.filter { $0.id != currentOption?.id }
        let identical = others.filter { resolvedText(for: $0)?.text == reference }.count
        let what = compareHideDots ? String(localized: "letter skeleton (rasm)") : String(localized: "lettering")
        return String(localized: "With these marks hidden, \(identical) of the \(others.count) other riwayat share this ayah's exact \(what) with the current riwayah. Rows tinted in the accent color still differ.")
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
        guard let resolved = resolvedBase(for: option) else { return nil }
        guard compareHideTashkeel || compareHideDots else { return resolved }
        // Every field but the text carries over. The split span did not, so with a Hide toggle on
        // Warsh's two pieces of Hafs 1:7 sat under "Ayah 6 in this riwayah" (2026-10-04).
        return ResolvedQiraahText(
            text: compareTransformed(resolved.text),
            ownNumber: resolved.ownNumber,
            mergedSpan: resolved.mergedSpan,
            splitSpan: resolved.splitSpan
        )
    }

    /// The resolver's full (untransformed) text - what `resolvedText` strips its sheet toggles
    /// from, and the projection source that keeps the khilaf wash painting on stripped rows.
    private func resolvedBase(for option: QiraahDisplay) -> ResolvedQiraahText? {
        if smartComparison {
            return QiraahAyahResolver.resolve(
                surahNumber: surahNumber,
                ayahNumber: ayahNumber,
                anchorHafsAyah: anchorHafsAyah,
                optionTag: option.tag,
                clean: false
            )
        }
        let tag = Settings.Riwayah.canonicalTag(option.tag)
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber),
              tag.isEmpty || ayah.existsInQiraah(tag, surahID: surahNumber) else { return nil }
        return ResolvedQiraahText(
            text: ayah.rawArabicText(surahId: surahNumber, qiraahOverride: tag),
            ownNumber: nil,
            mergedSpan: nil
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
    /// Stands down entirely while the sheet's Show Tajweed toggle is off.
    private func khilafOverlaid(_ diff: AttributedString?, option: QiraahDisplay, resolved: ResolvedQiraahText) -> AttributedString? {
        guard compareShowTajweed else { return diff }
        let tag = Settings.Riwayah.canonicalTag(option.tag)
        guard !tag.isEmpty else { return diff }
        let ownAyah = resolved.ownNumber ?? ayahNumber
        let allRules = Set(QiraahTajweedStore.shared.legend(for: tag).map(\.key))
        let hidden = allRules.subtracting(["khilaf_word", "khilaf_harf"])
        // With the sheet's Hide Tashkeel / Hide Dots on, `resolved.text` is the stripped skeleton;
        // the full resolved text lets the store paint the real print and project the runs onto it.
        guard let khilaf = QiraahTajweedStore.shared.attributedText(
            tag: tag, surah: surahNumber, ayah: ownAyah, displayText: resolved.text,
            hiddenRules: hidden,
            fullText: (compareHideTashkeel || compareHideDots) ? resolvedBase(for: option)?.text : nil
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
        // Under the shared spelling key, not byte for byte: Hafs's text alone keeps the silent
        // letter ring (U+0652), so Hafs against a riwayah that reads the ayah alike never said so.
        return QiraahSpelling.key(aText) == QiraahSpelling.key(bText)
    }

    /// The caption under the two picked riwayat. Two riwayat agreeing on ONE ayah is ordinary and the
    /// generic line covers it; two riwayat that agree on EVERY ayah is a fact about the transmission,
    /// and saying so is the difference between the sheet looking broken and the sheet teaching
    /// something. See `QiraatProfiles.sharedTextRiwayat`.
    private var duelFooterText: String {
        if let a = duelOptionA?.tag, let b = duelOptionB?.tag,
           QiraatProfiles.shareOneText(a, b) {
            return QiraatProfiles.sharedTextExplanation
        }
        return duelTextsIdentical
            ? String(localized: "These two riwayat read this ayah with identical wording.")
            : String(localized: "Pick any two riwayat and read them directly against each other. Words tinted in the accent color differ between the two.")
    }

    /// One side of the duel: the riwayah's aligned text, diffed against the OTHER side (not against
    /// the current riwayah), with its khilaf wash layered on top - the same styling stack as the rows.
    private func duelCard(_ option: QiraahDisplay, against other: QiraahDisplay?) -> some View {
        let resolved = resolvedText(for: option)
        let text = resolved?.text

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(option.shownLabel)
                    .font(.subheadline.weight(.semibold))

                if option.showsCaption {
                    Text(option.arabicCaption)
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                }

                if option.beta { BetaBadge() }

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
                    .foregroundStyle(.secondary)
            }

            Group {
                if let resolved, let styled = duelStyled(for: option, resolved: resolved, against: other) {
                    Text(styled)
                } else {
                    Text(text ?? String(localized: "This ayah is not separate in this riwayah."))
                }
            }
                .font(.custom(comparisonArabicFontName(for: option), size: fontSize))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .foregroundColor(text == nil ? .secondary : .primary)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                .environment(\.layoutDirection, .leftToRight)
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
                        source: option.shownLabel,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    if option.showsCaption {
                        HighlightedSnippet(
                            source: option.arabicCaption,
                            term: searchText,
                            font: .caption,
                            accent: settings.accentColor.color,
                            fg: settings.accentColor.color
                        )
                    }

                    if option.beta { BetaBadge() }
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
                    .foregroundStyle(.secondary)
            }

            // Scanning the rows, one of them matches the current riwayah word for word in every
            // ayah. Name the reason on the row where it is noticed.
            if QiraatProfiles.shareOneText(option.tag, originTag) {
                Text("Same transmitted text as \(QiraatProfiles.shortName(of: originTag).localizedDisplay): al-Durrah reports no difference between the two narrators.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HighlightedSnippet(
                source: text ?? String(localized: "This ayah is not separate in this riwayah."),
                term: searchText,
                font: .custom(
                    comparisonArabicFontName(for: option),
                    size: fontSize
                ),
                accent: settings.accentColor.color,
                fg: text == nil ? .secondary : .primary,
                preStyledSource: rowStyled(for: option, resolved: resolved)
            )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                .environment(\.layoutDirection, .leftToRight)

            // Hearing the difference: the same reciter, both readings, where a pair exists.
            if text != nil, QiraatVariantAudioStore.isBundled {
                QiraatVariantAudioButtons(tag: option.tag, surah: surahNumber, ayah: audioHafsAyah(for: option))
            }
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
            // Server data: a repeated edition must not trap (the first one wins).
            translations = Dictionary(decoded.data.map { ($0.edition.identifier, $0.text) }, uniquingKeysWith: { first, _ in first })
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
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    let ayahNumber: Int
    /// Pushed inside another sheet's stack (the tafsir sheet's comparison doors, Abu, 2026-10-22)
    /// rather than presented as a sheet of its own: no container of its own, no X.
    let embedded: Bool

    @StateObject private var viewModel: EnglishComparisonViewModel
    @State private var searchText = ""
    @State private var showSummarize = false

    init(surahNumber: Int, ayahNumber: Int, embedded: Bool = false) {
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.embedded = embedded
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

        let plain = query.foldingLatinDiacritics
        return sorted.filter { edition in
            edition.name.localizedStandardContains(plain) ||
            inAppTranslationText(for: edition.id).localizedStandardContains(plain)
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

        let plain = query.foldingLatinDiacritics
        return sorted.filter { edition in
            edition.name.localizedStandardContains(plain) ||
            (viewModel.translations[edition.id]?.localizedStandardContains(plain) ?? false)
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
        let plain = query.foldingLatinDiacritics
        return "Transliteration".localizedStandardContains(plain) ||
            arabic.localizedCaseInsensitiveContains(query) ||
            ayah.textTransliteration.localizedStandardContains(plain)
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
        if embedded {
            comparisonContent
        } else {
            SheetNavigationContainer { comparisonContent }
        }
    }

    /// The sheet's content below its container (indented as the container's closure it was).
    private var comparisonContent: some View {
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
            .sheetDismissToolbarIf(!embedded)
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
                    title: "\(AyahAISources.combinedTitlePrefix) of \(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber, english: true))",
                    displayTitle: AyahAISources.combinedDisplayTitle(of: ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber)),
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
                    },
                    excludedNote: AyahAISources.arabicExcludedNote
                )
            }
            #endif
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
                .leftToRightContent()
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
                    OnlineNoticeCard(text: String(localized: "Compare this ayah across several English Qur'an translations. The online translations are fetched from alquran.cloud; the downloaded ones are built into the app."))
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
                            comparisonRow(title: String(localized: "Transliteration"), text: ayah.textTransliteration)
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
                                text: viewModel.translations[edition.id] ?? String(localized: "Unavailable"),
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
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: String(localized: "Search translations"))
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
                // An English translation or transliteration reads left to right in the Arabic interface,
                // and Arabic keeps the right edge there (`.trailing` is the left in a right-to-left layout).
                .leftToRightContent()
        }
        .padding(.vertical, 4)
        .textSelection(.enabled)
    }
}

/// The one key two printed spellings (a word, a phrase or a whole ayah) are compared under: the
/// word card's riwayat block, the explorer's Head-to-Head and this sheet's own all ask "do these
/// two read the same" through it. Marks are kept, because a vowel is a reading; what goes is what
/// is not one:
/// * U+0652, the ring the prints set on a silent letter (كَفَرُواْ). The reader strips it from every
///   riwayah's text but Hafs's (`Ayah.displayArabicText`), so an exact comparison called 3,970 Hafs
///   words different from riwayat that print them identically (Shu'bah: 565 real differences shown
///   as 4,517);
/// * the stop signs and ornaments, which belong to a print's editing, not to the reading;
/// * the tatweel and the zero-width characters, and the order the packs happen to write marks in
///   (canonical composition).
/// A sign that stood as a word of its own leaves only its spaces, so the spacing is evened out too.
enum QiraahSpelling {
    static func key(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.precomposedStringWithCanonicalMapping.unicodeScalars {
            switch scalar.value {
            case 0x0640, 0x0652, 0x200B...0x200F, 0x2060, 0xFEFF: continue
            default:
                if !TajweedRules.stopSignScalars.contains(scalar.value) { scalars.append(scalar) }
            }
        }
        return String(scalars).split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
}

struct ResolvedQiraahText {
    let text: String
    /// The riwayah's OWN number for this ayah, when it differs from the number the sheet was
    /// opened with (riwayat count ayahs differently - the words are aligned, the number moves).
    let ownNumber: Int?
    /// The Hafs ayahs this riwayah ayah spans (more than one = it joins neighbors).
    let mergedSpan: ClosedRange<Int>?
    /// The riwayah's own ayah numbers this ONE Hafs ayah is divided into there (a split - al-Fatiha's
    /// last ayah is two in the Madani count). `text` carries every piece, so the row still shows
    /// the same words; nil when the ayah is one ayah there too.
    var splitSpan: ClosedRange<Int>? = nil
}

/// How a given riwayah renders ayah (`surahNumber`, `ayahNumber` in the ORIGIN riwayah's numbering) -
/// anchored through Hafs so merged/shifted numbering never serves the wrong verse (the old direct read
/// did exactly that for every non-Kufi-counted riwayah). File-scope rather than view-local so the
/// comparison rows and the AI summarize gatherer (`AyahAISources`) resolve identical text.
// Not main-actor bound: the word card resolves riwayah text from a detached task (see
// `QiraahComparison`, and QuranData's lock-published lookups, Quality Guide C5).
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

        // `clean: false` asks for the FULL text, which is `rawArabicText`. It read
        // `displayArabicText(clean: false)`, which has followed the reader's Hide Dots since
        // 2026-09-11: with that switch on, the comparison rows came out dotless while the sheet's
        // own Hide Dots was off, and the word card compared dotless riwayat against dotted Hafs.
        func text(of ayah: Ayah, in override: String) -> String {
            clean
                ? ayah.displayArabicText(surahId: surahNumber, clean: true, qiraahOverride: override)
                : ayah.rawArabicText(surahId: surahNumber, qiraahOverride: override)
        }

        if tag.isEmpty {
            guard let ayah = quranData.ayah(surah: surahNumber, ayah: anchor) else { return nil }
            return ResolvedQiraahText(
                text: text(of: ayah, in: ""),
                ownNumber: anchor == ayahNumber ? nil : anchor,
                mergedSpan: nil
            )
        }

        if let alignment = QiraahComparison.alignment(surahID: surahNumber, tag: tag, quranData: quranData) {
            // The alignment is the authority: a Hafs ayah it maps to nothing is one this riwayah
            // does not number at all (the basmalah in the Madani count of al-Fatiha) - unavailable
            // here, never the unrelated text that happens to carry the same number.
            guard let ownNumber = alignment.riwayahNumberForHafs[anchor],
                  let ayah = quranData.ayah(surah: surahNumber, ayah: ownNumber),
                  ayah.existsInQiraah(tag, surahID: surahNumber) else { return nil }
            let span = alignment.hafsRangeForRiwayah[ownNumber]
            // A split: `ownNumber` is only the piece that STARTS this Hafs ayah. Every following
            // riwayah ayah that maps to exactly this Hafs ayah is the rest of it.
            var joined = text(of: ayah, in: tag)
            var lastPiece = ownNumber
            while alignment.hafsRangeForRiwayah[lastPiece + 1] == anchor...anchor,
                  let piece = quranData.ayah(surah: surahNumber, ayah: lastPiece + 1),
                  piece.existsInQiraah(tag, surahID: surahNumber) {
                lastPiece += 1
                joined += " " + text(of: piece, in: tag)
            }
            return ResolvedQiraahText(
                text: joined,
                ownNumber: ownNumber == ayahNumber ? nil : ownNumber,
                mergedSpan: (span.map { $0.count } ?? 1) > 1 ? span : nil,
                splitSpan: lastPiece > ownNumber ? ownNumber...lastPiece : nil
            )
        }

        // No alignment (this riwayah has no text for the surah): the old direct read, else
        // genuinely unavailable.
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber),
              ayah.existsInQiraah(tag, surahID: surahNumber) else { return nil }
        return ResolvedQiraahText(
            text: text(of: ayah, in: tag),
            ownNumber: nil,
            mergedSpan: nil
        )
    }

    /// "Ayah 285 in this riwayah (spans 285\u{2013}286)" - the numbering note under a row's header.
    /// `localized: false` keeps the English wording for the on-device model's source text.
    static func numberNote(_ resolved: ResolvedQiraahText, localized: Bool = true) -> String? {
        if let split = resolved.splitSpan {
            return localized
                ? String(localized: "Ayahs \(split.lowerBound)\u{2013}\(split.upperBound) in this riwayah (divided there)")
                : "Ayahs \(split.lowerBound)\u{2013}\(split.upperBound) in this riwayah (divided there)"
        }
        if let own = resolved.ownNumber {
            if let span = resolved.mergedSpan {
                return localized
                    ? String(localized: "Ayah \(own) in this riwayah (spans \(span.lowerBound)\u{2013}\(span.upperBound))")
                    : "Ayah \(own) in this riwayah (spans \(span.lowerBound)\u{2013}\(span.upperBound))"
            }
            return localized ? String(localized: "Ayah \(own) in this riwayah") : "Ayah \(own) in this riwayah"
        }
        if let span = resolved.mergedSpan {
            return localized
                ? String(localized: "One ayah here (spans \(span.lowerBound)\u{2013}\(span.upperBound))")
                : "One ayah here (spans \(span.lowerBound)\u{2013}\(span.upperBound))"
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

    /// What the combined ayah source covers, for the summarize sheets' titles.
    static var combinedTitlePrefix: String {
        OnDeviceAsk.supportsArabic ? "Tafsir, riwayat & translations" : "English tafsirs & translations"
    }

    /// `combinedTitlePrefix` in the reader's language, for the sheet's own title (the model keeps the English).
    static func combinedDisplayTitle(of subject: String) -> String {
        OnDeviceAsk.supportsArabic
            ? String(localized: "Tafsir, riwayat & translations of \(subject)")
            : String(localized: "English tafsirs & translations of \(subject)")
    }

    /// The note a summarize sheet shows when the Arabic sources were left out (see `combinedSections`).
    static var arabicExcludedNote: String? {
        OnDeviceAsk.supportsArabic ? nil
            : String(localized: "The Arabic tafsir editions and the riwayat readings are left out: Apple Intelligence can\u{2019}t read Arabic on this device yet.")
    }

    static func combinedSections(
        surahNumber: Int,
        ayahNumber: Int,
        emphasis: Family,
        onlineTranslations: [String: String] = [:]
    ) -> [OnDeviceAsk.SummarizeSection] {
        let anchor = hafsAnchor(surahNumber: surahNumber, ayahNumber: ayahNumber)
        // The model rejects a prompt with a substantial Arabic passage while it has no Arabic
        // (`OnDeviceAsk.supportsArabic`): the three Arabic editions and the riwayat readings (pure
        // Arabic) stay out until it does. Before this gate the six-edition prompt failed outright.
        let readsArabic = OnDeviceAsk.supportsArabic

        // All six bundled tafsir editions - a synchronous pack read (Hafs numbering).
        let tafsirSections = TafsirAuthor.allCases.compactMap { author -> OnDeviceAsk.SummarizeSection? in
            guard readsArabic || !author.isArabic,
                  let entry = TafsirStore.shared.entry(author: author, surah: surahNumber, ayah: anchor) else { return nil }
            return OnDeviceAsk.SummarizeSection(label: author.summarizeSectionLabel, text: entry.content)
        }

        let qiraahSections = readsArabic ? [OnDeviceAsk.SummarizeSection(
            label: "Riwayat (qiraah readings) of this ayah",
            text: qiraahComparisonText(surahNumber: surahNumber, ayahNumber: ayahNumber)
        )].filter { !$0.text.isEmpty } : []

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
    /// Whether `qiraahComparisonText` would be non-empty, without resolving every riwayah (Phase 10.8):
    /// the sheet's toolbar asked for the whole text on every body pass (every keystroke, every slider
    /// tick) only to test `.isEmpty`. The text is a line per option other than the current one, plus
    /// the current one's line when it resolves, so it is empty only with no options, or with a single
    /// option that is the current riwayah and does not resolve.
    static func qiraahComparisonHasText(surahNumber: Int, ayahNumber: Int) -> Bool {
        let options = Settings.Riwayah.textOptions
        guard let only = options.first else { return false }
        if options.count > 1 { return true }
        let currentTag = Settings.normalizeLegacyRiwayahTag(Settings.shared.displayQiraah)
        if only.tag != currentTag { return true }
        return QiraahAyahResolver.resolve(
            surahNumber: surahNumber, ayahNumber: ayahNumber,
            anchorHafsAyah: hafsAnchor(surahNumber: surahNumber, ayahNumber: ayahNumber),
            optionTag: only.tag, clean: Settings.shared.cleanArabicText
        ) != nil
    }

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
                if let note = QiraahAyahResolver.numberNote(res, localized: false) {
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
