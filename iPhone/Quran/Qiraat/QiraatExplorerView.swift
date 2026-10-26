#if os(iOS)
import SwiftUI

// The Qiraat Explorer's screen, rebuilt 2026-10-09 (Abu: "messy and hard to understand and is laggy
// and is ugly; also takes a second to load"). The data it stands on is in QiraatExplorer.swift (the
// word diff, the place index) and QiraatPlace.swift (a place worked out word by word).
//
// One question per place: which words of this ayah do the riwayat read differently, how, and who reads
// each way. The band at the top steps from place to place. Under it: the Hafs ayah with those words
// tinted; one card per word with every reading, its readers and, from the Quran.com reference, its
// meaning; the recordings; and, folded away, each riwayah's whole ayah. Compare Two puts two riwayat
// against each other in the same cards, kept to the words where the two part ways (it replaced the old
// Head-to-Head and By Surah modes, which were the same comparison twice).
//
// Speed. A place is built off the main thread with the riwayat in parallel (`QiraatPlaceBuilder`) and
// swapped in whole, without an animation, so a step costs the main thread one layout of a few short
// rows instead of an animated diff of nineteen ayah cards. The first place no longer waits for the
// place index and the packs one after another, and while it builds the screen says so rather than
// showing "read alike here".

struct QiraatExplorerView: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    enum Mode: String {
        /// Every riwayah at one place, against Hafs.
        case ayah
        /// Two chosen riwayat against each other, stepping through the places where THEY differ.
        case duel
    }

    @State private var mode: Mode
    @State private var surahID: Int
    @State private var hafsAyah: Int
    /// Opened at the constant first place (1:4), which the index confirms or corrects once it is in;
    /// Compare Two from a door looks for the first place where its two sides part ways.
    @State private var seekFirstPlace: Bool
    /// A surah picked in the place picker: Compare Two moves to its first place once that is known.
    @State private var seekInSurah = false
    /// The riwayah a narrator's page opened this walk with, until the first build writes the pair.
    @State private var pendingSurahWalk: String?
    /// Counts builds, so a superseded build's `defer` cannot put away the spinner its successor raised.
    @State private var buildGeneration = 0

    @AppStorage("qiraatExplorerFontSize") private var fontSize: Double = 24
    /// Off: step by word-level changes (another word form, added or dropped letters, other vowels).
    /// On: every change, down to one letter's dots, hamzah or vowel.
    @AppStorage("qiraatExplorerEveryDifference") private var everyDifference = false
    /// Compare Two's sides, remembered across places and openings (Hafs against Warsh until the reader
    /// picks). Either may be Hafs (the empty tag).
    @AppStorage("qiraatExplorerDuelA") private var duelARaw: String = Settings.Riwayah.hafsTag
    @AppStorage("qiraatExplorerDuelB") private var duelBRaw: String = Settings.Riwayah.warsh
    /// Which riwayat may render text, read from its key rather than by observing all of Settings.
    @AppStorage("betaQiraatEnabled") private var betaQiraatEnabled = false

    @State private var place: QiraatPlace?
    @State private var duel: QiraatDuelPlace?
    @State private var duelNavigation: DuelBand?
    @State private var indexReady = QiraatPlacesStore.shared.isIndexLoaded
    @State private var showBusy = false
    @State private var showTexts = false
    @State private var showPicker = false
    @State private var showUnlock = false
    @State private var warmTask: Task<Void, Never>?
    @State private var bandMemo = BandMemo()

    private static let topRow = "explorer-top"

    /// `ayah` in the reader's riwayah numbering (`originTag`); the explorer thinks in Hafs numbers.
    init(surah: Int, ayah: Int, originTag: String? = nil) {
        let anchor = QiraahComparison.hafsAnchor(surahID: surah, ayahNumber: ayah, tag: originTag, quranData: QuranData.shared)
        _mode = State(initialValue: .ayah)
        _surahID = State(initialValue: surah)
        _hafsAyah = State(initialValue: anchor)
        _seekFirstPlace = State(initialValue: false)
    }

    /// Opens on the first place in the Quran where a riwayah differs: al-Fatiha's مالك / ملك (1:4), the
    /// first place in every riwayah set, so it is a constant here and the index (parsed off the main
    /// thread beside the first build) only corrects it in the rare case it says otherwise.
    init() {
        self.init(mode: .ayah)
    }

    /// Opens straight into a mode (the guide's Compare Two door), at its first place.
    init(mode: Mode) {
        _mode = State(initialValue: mode)
        _surahID = State(initialValue: 1)
        _hafsAyah = State(initialValue: 4)
        _seekFirstPlace = State(initialValue: true)
    }

    /// Walks one riwayah against Hafs (a narrator's page in the Qiraat guide): Compare Two with Hafs on
    /// one side and the riwayah on the other, remembered exactly as if picked here.
    init(surahWalk tag: String) {
        self.init(mode: .duel)
        // Applied by the first build (see `rebuild`), not here: a View initializer runs again on every
        // re-render of the pushing page (any Settings publish), and writing the defaults from it
        // snapped the pair the user had since picked back to Hafs and the narrator.
        _pendingSurahWalk = State(initialValue: tag)
    }

    // MARK: Inputs

    private var accent: Color { appearance.accent }
    private var store: QiraatPlacesStore { QiraatPlacesStore.shared }

    /// Every riwayah whose text may render, Hafs excluded (it is the reference).
    private var enabledTags: [String] { store.enabledTags }

    private var duelA: String {
        let tag = Settings.Riwayah.canonicalTag(duelARaw)
        return tag.isEmpty || enabledTags.contains(tag) ? tag : Settings.Riwayah.hafsTag
    }

    /// The stored riwayah while it may render and is not side A, else the first other one.
    private var duelB: String {
        let tag = Settings.Riwayah.canonicalTag(duelBRaw)
        if (tag.isEmpty || enabledTags.contains(tag)) && tag != duelA { return tag }
        return enabledTags.first { $0 != duelA } ?? Settings.Riwayah.hafsTag
    }

    /// The riwayat a build reads: every enabled one, or Compare Two's sides other than Hafs.
    private var buildTags: [String] {
        mode == .duel ? [duelA, duelB].filter { !$0.isEmpty } : enabledTags
    }

    private var buildKey: String {
        "\(mode.rawValue)|\(surahID):\(hafsAyah)|\(everyDifference ? 1 : 0)|\(duelA)>\(duelB)|\(buildTags.joined(separator: ","))|\(betaQiraatEnabled ? 1 : 0)"
    }

    /// Changes when the content shows another place, which scrolls the list back to its top.
    private var shownKey: String {
        mode == .duel ? "duel|\(duel?.place.key ?? "")" : "all|\(place?.key ?? "")"
    }

    private var comparedSet: Set<String> {
        Set(enabledTags + [Settings.Riwayah.hafsTag])
    }

    private var lockedCount: Int {
        Settings.Riwayah.allOptions.count - enabledTags.count - 1
    }

    private func face(_ tag: String) -> String {
        Settings.shared.quranArabicFontName(for: tag)
    }

    private var customFace: Bool {
        Settings.shared.quranDisplayUsesCustomArabicFace
    }

    /// The narrator's short name as the reader sees it (the Arabic interface's own name for him).
    private func shortName(_ tag: String) -> String {
        QiraatReaderNames.narratorName(tag, compared: comparedSet, display: true)
    }

    /// "Hafs an Asim", "Warsh an Nafi": the pickers' names without Hafs's "(default)".
    private func fullName(_ tag: String) -> String {
        // The Arabic interface names it in Arabic (`displayLabel`).
        if AppLanguage.isArabicScript { return Settings.Riwayah.option(for: tag).displayLabel(omitsDefaultSuffix: true) }
        return tag.isEmpty ? "Hafs an Asim" : Settings.Riwayah.option(for: tag).label
    }

    // MARK: Body

    var body: some View {
        let _ = RenderCounter.hit("QiraatExplorerView")
        ScrollViewReader { proxy in
            List {
                Group {
                    switch mode {
                    case .ayah: allSections
                    case .duel: duelSections
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle(disableNowPlayingInset: true)
            .compactListSectionSpacing()
            .safeAreaInset(edge: .top, spacing: 0) { band }
            .onChange(of: shownKey) { _ in
                proxy.scrollTo(Self.topRow, anchor: .top)
            }
        }
        .navigationTitle("Qiraat Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { modePicker }
            ToolbarItem(placement: .primaryAction) { optionsMenu }
        }
        .openScreen(.qiraatExplorer)
        .sheet(isPresented: $showPicker) { placePicker }
        .sheet(isPresented: $showUnlock) { QiraatExplorerUnlockSheet() }
        .task(id: buildKey) { await rebuild() }
        .onChange(of: mode) { _ in Settings.shared.hapticFeedback() }
        .onChange(of: betaQiraatEnabled) { _ in store.invalidateVariantCache() }
        .onDisappear { warmTask?.cancel() }
    }

    // MARK: Toolbar

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            Text("All Riwayat").tag(Mode.ayah)
            Text("Compare Two").tag(Mode.duel)
        }
        .pickerStyle(.segmented)
        .fixedSize()
        .accessibilityLabel("Explorer mode")
    }

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
            Toggle(isOn: $everyDifference) {
                Label("Every Difference", systemImage: "textformat.abc.dottedunderline")
                Text("Count one letter's dots, hamzah or vowel too")
            }
            .toggleStyle(.automatic)
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
        .tint(accent)
        .accessibilityLabel("Explorer options")
    }

    // MARK: The band

    /// Where the step buttons go and what the caption says.
    private struct Band {
        var previous: QiraatPlaceRef?
        var next: QiraatPlaceRef?
        var caption: String
    }

    /// Compare Two's band, worked out off the main thread for one place, pair and tier.
    private struct DuelBand: Equatable {
        let key: String
        var previous: QiraatPlaceRef?
        var next: QiraatPlaceRef?
        /// Nil until the surah's list is in (the caption then counts the places).
        var placesInSurah: [Int]?
    }

    /// The All Riwayat band is cheap (cached index lookups) but walks up to 114 surahs at an end of
    /// the Quran: kept per place here rather than recomputed on every body.
    private final class BandMemo {
        var key = ""
        var band: Band?
    }

    private var duelBandKey: String {
        "\(surahID):\(hafsAyah)|\(duelA)>\(duelB)|\(everyDifference ? 1 : 0)|\(betaQiraatEnabled ? 1 : 0)"
    }

    private var band: some View {
        VStack(spacing: 8) {
            placeRow
            if mode == .duel { sidesRow }
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }

    private var currentBand: Band {
        switch mode {
        case .ayah:
            // Before the index is in, any lookup would parse it here, on the main thread.
            guard indexReady else { return Band(caption: String(localized: "Finding the places…")) }
            let key = "\(surahID):\(hafsAyah)|\(everyDifference ? 1 : 0)|\(enabledTags.joined(separator: ","))"
            if bandMemo.key == key, let band = bandMemo.band { return band }
            let tags = enabledTags
            let previous = store.step(from: surahID, ayah: hafsAyah, forward: false, tags: tags, everyDifference: everyDifference)
            let next = store.step(from: surahID, ayah: hafsAyah, forward: true, tags: tags, everyDifference: everyDifference)
            let places = store.variantAyahs(surah: surahID, tags: tags, everyDifference: everyDifference)
            let band = Band(previous: previous.map { QiraatPlaceRef(surah: $0.surah, ayah: $0.ayah) },
                            next: next.map { QiraatPlaceRef(surah: $0.surah, ayah: $0.ayah) },
                            caption: caption(places: places, alike: String(localized: "No riwayah differs in this surah")))
            bandMemo.key = key
            bandMemo.band = band
            return band
        case .duel:
            if QiraatProfiles.shareOneText(duelA, duelB) {
                return Band(caption: String(localized: "\(shortName(duelA)) and \(shortName(duelB)) carry one text"))
            }
            guard let duelNavigation, duelNavigation.key == duelBandKey else {
                return Band(caption: String(localized: "Finding where they differ…"))
            }
            let caption = duelNavigation.placesInSurah.map {
                caption(places: $0, alike: String(localized: "\(shortName(duelA)) and \(shortName(duelB)) read this surah alike"))
            } ?? (duelNavigation.next == nil && duelNavigation.previous == nil ? String(localized: "They read alike throughout") : String(localized: "Counting the places…"))
            return Band(previous: duelNavigation.previous, next: duelNavigation.next, caption: caption)
        }
    }

    private func caption(places: [Int], alike: String) -> String {
        if let index = places.firstIndex(of: hafsAyah) {
            return String(localized: "Place \(index + 1) of \(places.count) in this surah")
        }
        switch places.count {
        case 0: return alike
        case 1: return String(localized: "Read alike here · 1 place in this surah")
        default: return String(localized: "Read alike here · \(places.count) places in this surah")
        }
    }

    private var placeRow: some View {
        let band = currentBand
        return HStack(spacing: 4) {
            stepButton(forward: false, to: band.previous)

            Button {
                Settings.shared.hapticFeedback()
                showPicker = true
            } label: {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text(ayahSheetTitle(surahNumber: surahID, ayahNumber: hafsAyah))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 5) {
                        if showBusy {
                            ProgressView()
                                .controlSize(.mini)
                        }
                        Text(band.caption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Choose another place")

            stepButton(forward: true, to: band.next)
        }
    }

    /// The reader's Previous | Next grammar: the chevron in a soft accent disc, gray and dimmed when
    /// there is nowhere to go.
    private func stepButton(forward: Bool, to target: QiraatPlaceRef?) -> some View {
        let enabled = target != nil
        return Button {
            guard let target else { return }
            Settings.shared.hapticFeedback()
            surahID = target.surah
            hafsAyah = target.ayah
        } label: {
            Image(systemName: forward ? "chevron.forward" : "chevron.backward")
                .font(.subheadline.weight(.bold))
                .foregroundColor(enabled ? accent : .secondary)
                .frame(width: 36, height: 36)
                .background(Circle().fill((enabled ? accent : Color.secondary).opacity(0.16)))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
        .accessibilityLabel(forward ? "Next place" : "Previous place")
    }

    private var sidesRow: some View {
        HStack(spacing: 8) {
            ArabicTextRiwayahPicker(selection: Binding(get: { duelA }, set: { duelARaw = $0 }),
                                    sideLabel: "A", compactLabel: true)

            Button {
                Settings.shared.hapticFeedback()
                let a = duelA
                let b = duelB
                duelARaw = b
                duelBRaw = a
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(accent)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(accent.opacity(0.14)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Swap the two riwayat")

            ArabicTextRiwayahPicker(selection: Binding(get: { duelB }, set: { duelBRaw = $0 }),
                                    sideLabel: "B", compactLabel: true)
        }
    }

    // MARK: All Riwayat

    /// The place the band names, as the built places are keyed.
    private var bandPlaceKey: String { "\(surahID):\(hafsAyah)" }

    /// A built place stays up while the next one builds (a step lands in a few milliseconds), unless
    /// the build runs long enough to show the spinner: then the band's own ayah takes its place.
    private func isShowable(_ key: String) -> Bool {
        key == bandPlaceKey || !showBusy
    }

    @ViewBuilder
    private var allSections: some View {
        if let place, isShowable(place.key) {
            Section {
                ayahCard(place)
                    .id(Self.topRow)
            }

            if place.sites.isEmpty {
                Section {
                    readAlikeRow(String(localized: "No riwayah reads a word of this ayah differently"),
                                 detail: everyDifference
                                    ? String(localized: "Use the arrows to step to the nearest place where one does.")
                                    : String(localized: "Use the arrows to step to the nearest place where one does. Every Difference (in the options) counts single dots and vowels too."))
                }
            } else {
                siteSections(place.sites, label: nil)
            }

            listenSection(place.audioTags, surah: place.surah, ayah: place.hafsAyah)
            textsSection(place)
            moreSection(hasReference: place.hasReference)
        } else {
            // Nothing built for this place yet: its ayah needs no riwayah, so it is up at once.
            Section {
                pendingAyahCard
                    .id(Self.topRow)
            }
            Section {
                loadingRow
            }
        }
    }

    private func ayahCard(_ place: QiraatPlace) -> some View {
        let differing = place.differingTags.count
        let available = place.sides.count - place.unavailableTags.count
        return ayahCard(text: place.hafsText, tokens: place.hafsTokens, tinted: place.hafsTinted, english: place.english,
                        summary: differing == 0 ? String(localized: "No riwayah differs") : String(localized: "\(differing) of \(available) riwayat differ"),
                        summaryTinted: differing > 0)
    }

    private var pendingAyahCard: some View {
        let ayah = QuranData.shared.ayah(surah: surahID, ayah: hafsAyah)
        return ayahCard(text: ayah?.rawArabicText(surahId: surahID, qiraahOverride: "") ?? "", tokens: [], tinted: [],
                        english: ayah?.textEnglishSaheeh ?? "", summary: nil, summaryTinted: false)
    }

    private func ayahCard(text: String, tokens: [QiraatWordDiff.Token], tinted: Set<Int>, english: String,
                          summary: String?, summaryTinted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("HAFS AN ASIM")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                if let summary {
                    Text(summary)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(summaryTinted ? accent : .secondary)
                }
            }

            QiraatArabicText(text: text, tokens: tokens, tinted: tinted,
                             accent: accent, fontName: face(""), size: fontSize, customFace: customFace)
                .equatable()

            if !english.isEmpty {
                // The ayah's English translation keeps the left edge in the Arabic interface.
                Text(english)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .leftToRightContent()
            }
        }
        .padding(.vertical, 6)
    }

    /// One card per word read differently. `label` names each reading by its side (Compare Two) instead
    /// of by everyone who reads it.
    @ViewBuilder
    private func siteSections(_ sites: [QiraatSite], label: ((QiraatSiteReading) -> String)?) -> some View {
        ForEach(Array(sites.enumerated()), id: \.element.id) { index, site in
            let stacked = isStacked(site)
            Section {
                ForEach(site.readings) { reading in
                    readingRow(reading, in: site, label: label?(reading),
                               emphasized: label == nil ? !reading.isHafs : reading.id != site.readings.first?.id,
                               stacked: stacked)
                }
            } header: {
                Text(siteHeader(site, index: index, of: sites.count))
            } footer: {
                siteFooter(site)
            }
        }
    }

    private func siteHeader(_ site: QiraatSite, index: Int, of count: Int) -> String {
        let caption = site.caption?.uppercased()
        guard count > 1 else { return caption ?? String(localized: "READ DIFFERENTLY") }
        return caption.map { String(localized: "\(index + 1) OF \(count) · \($0)") } ?? String(localized: "\(index + 1) OF \(count)")
    }

    @ViewBuilder
    private func siteFooter(_ site: QiraatSite) -> some View {
        // The reference's renderings carry their own quotation marks.
        let shared = site.sharedEnglish.map { String(localized: "Every reading here is rendered \($0).") }
        let parts = [shared, site.note.isEmpty ? nil : site.note].compactMap { $0 }
        if !parts.isEmpty {
            Text(parts.joined(separator: " "))
                .font(.caption)
        }
    }

    /// A site whose readings run past two words, or any site at an accessibility text size, sets each
    /// reading's Arabic above its readers; otherwise the word sits beside them at its own width.
    private func isStacked(_ site: QiraatSite) -> Bool {
        dynamicTypeSize.isAccessibilitySize
            || site.readings.contains { $0.text.split(separator: " ").count > 2 }
    }

    private func readingRow(_ reading: QiraatSiteReading, in site: QiraatSite, label: String?,
                            emphasized: Bool, stacked: Bool) -> some View {
        let arabic = Text(reading.text.isEmpty ? String(localized: "(none)") : reading.text)
            .font(.custom(face(reading.fontTag), size: CGFloat(fontSize * 1.08)))
            .arabicFontDesign(custom: customFace)
            .foregroundColor(emphasized ? accent : .primary)
            .multilineTextAlignment(.trailing)
        let details = VStack(alignment: .leading, spacing: 3) {
            readersLine(reading, label: label)

            if !reading.transliteration.isEmpty {
                Text(reading.transliteration)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    // The reading's transliteration and English rendering keep their own direction in
                    // the Arabic interface; the row around them follows it.
                    .leftToRightContent()
            }
            if site.sharedEnglish == nil, !reading.english.isEmpty {
                Text(reading.english)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .leftToRightContent()
            }
        }
        return Group {
            if stacked {
                VStack(alignment: .leading, spacing: 6) {
                    arabic
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                        .environment(\.layoutDirection, .leftToRight)
                    details
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .center, spacing: 14) {
                    details
                        .frame(maxWidth: .infinity, alignment: .leading)
                    arabic
                        .fixedSize()
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func readersLine(_ reading: QiraatSiteReading, label: String?) -> some View {
        if let label {
            Text(label)
                .font(.subheadline.weight(.semibold))
        } else if reading.isHafs {
            let others = QiraatReaderNames.names(reading.tags.filter { !$0.isEmpty }, compared: comparedSet.subtracting([""]), display: true)
            Text("Hafs")
                .font(.subheadline.weight(.semibold))
            if !others.isEmpty {
                Text("also \(QiraatReaderNames.list(others))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Text(QiraatReaderNames.list(QiraatReaderNames.names(reading.tags, compared: comparedSet, display: true)))
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func listenSection(_ tags: [String], surah: Int, ayah: Int) -> some View {
        if !tags.isEmpty {
            Section(header: Text("HEAR BOTH READINGS")) {
                ForEach(tags, id: \.self) { tag in
                    QiraatClipPairRow(tag: tag, surah: surah, ayah: ayah)
                }
            }
        }
    }

    @ViewBuilder
    private func textsSection(_ place: QiraatPlace) -> some View {
        let differing = place.differingTags
        Section {
            Button {
                Settings.shared.hapticFeedback()
                showTexts.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "text.alignright")
                        .foregroundColor(accent)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text("Each Riwayah's Whole Ayah")
                        .foregroundColor(.primary)
                    Spacer(minLength: 8)
                    Text("\(place.sides.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Image(systemName: showTexts ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showTexts {
                ForEach(differing, id: \.self) { tag in
                    riwayahTextRow(tag, place: place)
                }
                if !place.alikeTags.isEmpty {
                    Text("Same words as Hafs here: \(QiraatReaderNames.list(place.alikeTags.map(shortName)))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !place.unavailableTags.isEmpty {
                    Text("Not a separate ayah in \(QiraatReaderNames.list(place.unavailableTags.map(shortName))).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func riwayahTextRow(_ tag: String, place: QiraatPlace) -> some View {
        let option = Settings.Riwayah.option(for: tag)
        let side = place.side(tag)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(fullName(tag))
                    .font(.subheadline.weight(.semibold))
                Text(option.arabic)
                    .font(.caption)
                    .foregroundColor(accent)
                if option.beta { BetaBadge() }
            }
            if let resolved = side?.resolved, let note = QiraahAyahResolver.numberNote(resolved) {
                Text(note)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if let change = side?.change {
                QiraatArabicText(text: change.riwayahText, tokens: change.diff.riwayah, tinted: place.tinted(tag),
                                 accent: accent, fontName: face(tag), size: fontSize, customFace: customFace)
                    .equatable()
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func moreSection(hasReference: Bool) -> some View {
        Section {
            // The reference is keyed by the Hafs number; the page's preview card wants the reader's own
            // row for it (see `readerAyahObject`).
            if hasReference, let surah = QuranData.shared.surah(surahID), let ayah = readerAyahObject {
                NavigationLink(destination: LazyDestination {
                    AyahQiraatVariantsView(surah: surah, ayah: ayah, hafsAyahs: hafsAyah...hafsAyah)
                }) {
                    SettingsRowLabel(title: String(localized: "All Readings and Notes"), systemImage: "text.book.closed",
                                     subtitle: String(localized: "Every reading of this ayah with its notes"))
                }
            }
            if lockedCount > 0 {
                Button {
                    Settings.shared.hapticFeedback()
                    showUnlock = true
                } label: {
                    SettingsRowLabel(title: String(localized: "Compare All 20 Riwayat"), systemImage: "flask",
                                     value: String(localized: "\(enabledTags.count + 1) of \(Settings.Riwayah.allOptions.count) now"))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("MORE")
        } footer: {
            Text("Each riwayah's words come from its printed mushaf, lined up with Hafs word by word. Meanings and transliterations are from the Quran.com qiraat reference.")
        }
    }

    /// The explorer's ayah as the READER numbers it: the readings page's preview card draws the ayah
    /// in the displayed riwayah, and under the Hafs number it drew another verse wherever the two
    /// counts have drifted apart. Nil when the displayed riwayah numbers no such ayah.
    private var readerAyahObject: Ayah? {
        let quranData = QuranData.shared
        let tag = Settings.Riwayah.canonicalTag(Settings.shared.displayQiraahForArabic ?? "")
        guard !tag.isEmpty,
              let alignment = QiraahComparison.alignment(surahID: surahID, tag: tag, quranData: quranData)
        else { return quranData.ayah(surah: surahID, ayah: hafsAyah) }
        return alignment.riwayahNumberForHafs[hafsAyah].flatMap { quranData.ayah(surah: surahID, ayah: $0) }
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Lining up the riwayat…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
    }

    private func readAlikeRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "checkmark.circle")
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    // MARK: Compare Two

    @ViewBuilder
    private var duelSections: some View {
        if let duel, isShowable(duel.place.key), (duel.a == duelA && duel.b == duelB) || !showBusy {
            Section {
                duelTextRow(duel, tag: duel.a, tinted: duel.aTinted)
                    .id(Self.topRow)
                duelTextRow(duel, tag: duel.b, tinted: duel.bTinted)
            }

            if QiraatProfiles.shareOneText(duel.a, duel.b) {
                Section {
                    Text(QiraatProfiles.sharedTextExplanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if duel.sites.isEmpty {
                Section {
                    readAlikeRow(String(localized: "\(shortName(duel.a)) and \(shortName(duel.b)) read this ayah alike"),
                                 detail: String(localized: "Use the arrows to step to the nearest place where the two part ways."))
                }
            } else {
                siteSections(duel.sites) { reading in
                    shortName(reading.tags.first ?? "")
                }
            }

            listenSection(duel.place.audioTags, surah: duel.place.surah, ayah: duel.place.hafsAyah)
            moreSection(hasReference: duel.place.hasReference)
        } else {
            Section {
                loadingRow
                    .id(Self.topRow)
            }
        }
    }

    private func duelTextRow(_ duel: QiraatDuelPlace, tag: String, tinted: Set<Int>) -> some View {
        let option = Settings.Riwayah.option(for: tag)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(fullName(tag))
                    .font(.subheadline.weight(.semibold))
                Text(option.arabic)
                    .font(.caption)
                    .foregroundColor(accent)
                if option.beta { BetaBadge() }
            }
            if let resolved = duel.resolved(tag), let note = QiraahAyahResolver.numberNote(resolved) {
                Text(note)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if duel.isAvailable(tag), let text = duel.text(tag) {
                QiraatArabicText(text: text.text, tokens: text.tokens, tinted: tinted,
                                 accent: accent, fontName: face(tag), size: fontSize, customFace: customFace)
                    .equatable()
            } else {
                Text("Not a separate ayah in this riwayah.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: The place picker

    private var placePicker: some View {
        let tags = buildTags
        let every = everyDifference
        let store = self.store
        let places: [Int]
        let count: ((Int) -> Int)?
        switch mode {
        case .ayah:
            places = indexReady ? store.variantAyahs(surah: surahID, tags: tags, everyDifference: every) : []
            count = indexReady && store.hasWholeQuranCounts
                ? { store.count(surah: $0, tags: tags, everyDifference: every) } : nil
        case .duel:
            places = duelNavigation?.key == duelBandKey ? (duelNavigation?.placesInSurah ?? []) : []
            // Against Hafs, the other side's own places are the pair's; two riwayat have no count
            // before their texts are compared.
            let hafsSided = duelA.isEmpty || duelB.isEmpty
            count = hafsSided && indexReady && store.hasWholeQuranCounts
                ? { store.count(surah: $0, tags: tags, everyDifference: every) } : nil
        }
        return QiraatPlacePickerSheet(surahID: surahID, hafsAyah: hafsAyah, places: places, tags: tags,
                                      everyDifference: every, count: count) { surah, ayah in
            if let ayah {
                surahID = surah
                hafsAyah = ayah
            } else if mode == .ayah {
                surahID = surah
                hafsAyah = store.variantAyahs(surah: surah, tags: tags, everyDifference: every).first ?? 1
            } else {
                // Seek the surah's first place only when that is a NEW build: the same surah picked
                // again leaves `buildKey` unchanged, and a flag left armed (or set outside Compare
                // Two, which alone consumes it) hijacked a later, unrelated rebuild.
                let changes = surahID != surah || hafsAyah != 1
                surahID = surah
                hafsAyah = 1
                seekInSurah = mode == .duel && changes
            }
        }
    }

    // MARK: Building

    /// The place index parses here, off the main thread, beside the first place's build.
    nonisolated private static func loadIndex(_ store: QiraatPlacesStore, needed: Bool) async {
        if needed { store.prewarmIndex() }
    }

    @MainActor
    private func rebuild() async {
        let store = self.store
        let quranData = QuranData.shared
        let tags = buildTags
        let every = everyDifference
        let surah = surahID
        let ayah = hafsAyah
        let currentMode = mode
        let a = duelA
        let b = duelB
        if let tag = pendingSurahWalk {
            // A narrator's page opened this walk: its pair is written here, on the first build. When the
            // derived pair changes, the changed key cancels this build and starts the right one; when it
            // does not (the riwayah is not enabled, so `duelB` falls back as before), this build is it.
            pendingSurahWalk = nil
            if duelARaw != Settings.Riwayah.hafsTag { duelARaw = Settings.Riwayah.hafsTag }
            if duelBRaw != tag { duelBRaw = tag }
        }
        #if DEBUG
        if RenderCounter.enabled { NSLog("EXPLORER build start %d:%d", surah, ayah) }
        #endif

        // A spinner by the caption only when a build is slow enough to see (a cold surah, a debug
        // build): a step that lands in a few milliseconds never flashes one.
        buildGeneration &+= 1
        let generation = buildGeneration
        let busy = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            if !Task.isCancelled { showBusy = true }
        }
        defer {
            busy.cancel()
            // Only the build still current puts the spinner away: a superseded build landing late
            // switched off the one its successor's timer had just raised.
            if buildGeneration == generation { showBusy = false }
        }

        async let index: Void = Self.loadIndex(store, needed: !store.isIndexLoaded)

        if currentMode == .duel, seekFirstPlace || seekInSurah {
            await index
            indexReady = true
            let from = seekInSurah ? QiraatPlaceRef(surah: surah, ayah: 0) : QiraatPlaceRef(surah: 1, ayah: 0)
            let first = await QiraatPlaceBuilder.duelStep(from: from.surah, ayah: from.ayah, forward: true, a: a, b: b,
                                                          everyDifference: every, store: store, quranData: quranData)
            guard !Task.isCancelled else { return }
            let keepSurah = seekInSurah
            seekFirstPlace = false
            seekInSurah = false
            if let first, first != QiraatPlaceRef(surah: surah, ayah: ayah), !keepSurah || first.surah == surah {
                surahID = first.surah
                hafsAyah = first.ayah
                return
            }
        }

        #if DEBUG
        let started = DispatchTime.now().uptimeNanoseconds
        #endif
        let built = await QiraatPlaceBuilder.build(surah: surah, hafsAyah: ayah, tags: tags,
                                                   everyDifference: every, quranData: quranData)
        guard !Task.isCancelled else { return }
        #if DEBUG
        if RenderCounter.enabled {
            NSLog("EXPLORER place %d:%d %d riwayat %.1f ms off main, %d sites", surah, ayah, tags.count,
                  Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000, built.sites.count)
        }
        #endif

        // The place goes up the moment it is built: only the band's arrows wait for the index.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            switch currentMode {
            case .ayah: place = built
            case .duel: duel = QiraatPlaceBuilder.duel(a: a, b: b, place: built)
            }
        }

        await index
        guard !Task.isCancelled else { return }
        indexReady = true
        if currentMode == .ayah, seekFirstPlace {
            seekFirstPlace = false
            // 1:4 opens every riwayah set; this only moves when the index says otherwise.
            if let first = store.firstPlace(tags: tags, everyDifference: every),
               first.surah != surah || first.ayah != ayah {
                surahID = first.surah
                hafsAyah = first.ayah
                return
            }
        }
        warmNextSurah(tags: tags)

        guard currentMode == .duel else { return }
        let key = duelBandKey
        guard duelNavigation?.key != key else { return }
        async let next = QiraatPlaceBuilder.duelStep(from: surah, ayah: ayah, forward: true, a: a, b: b,
                                                     everyDifference: every, store: store, quranData: quranData)
        async let previous = QiraatPlaceBuilder.duelStep(from: surah, ayah: ayah, forward: false, a: a, b: b,
                                                         everyDifference: every, store: store, quranData: quranData)
        let steps = await (previous, next)
        guard !Task.isCancelled else { return }
        duelNavigation = DuelBand(key: key, previous: steps.0, next: steps.1, placesInSurah: nil)
        let list = await QiraatPlaceBuilder.duelAyahs(surah: surah, a: a, b: b, everyDifference: every,
                                                      store: store, quranData: quranData)
        guard !Task.isCancelled, duelNavigation?.key == key else { return }
        duelNavigation?.placesInSurah = list
    }

    /// Every resolve needs its surah's alignment against Hafs, about 7 ms a riwayah (optimized): so
    /// while the reader looks at this place the NEXT surah is aligned, and the step into it finds the
    /// tables built. Off the main thread (the tables are behind `QiraahComparison`'s lock), forward
    /// only, and never on the reduced tier, which does no prebuilds at all.
    private func warmNextSurah(tags: [String]) {
        warmTask?.cancel()
        guard !AppPerformance.shouldAvoidBroadPrewarm, surahID < 114, !tags.isEmpty else { return }
        let next = surahID + 1
        let quranData = QuranData.shared
        warmTask = Task.detached(priority: .utility) {
            #if DEBUG
            let started = DispatchTime.now().uptimeNanoseconds
            #endif
            for tag in tags {
                guard !Task.isCancelled else { return }
                _ = QiraahComparison.alignment(surahID: next, tag: tag, quranData: quranData)
            }
            #if DEBUG
            if RenderCounter.enabled {
                NSLog("EXPLORER warm surah %d, %d riwayat, %.1f ms spread", next, tags.count,
                      Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)
            }
            #endif
        }
    }
}

// MARK: - Pieces

/// An ayah (or a riwayah's text of it) with chosen words tinted. Compared by value, so a parent's
/// re-render (a sheet opening, the texts folding out) leaves its layout alone.
struct QiraatArabicText: View, Equatable {
    let text: String
    let tokens: [QiraatWordDiff.Token]
    let tinted: Set<Int>
    let accent: Color
    let fontName: String
    let size: Double
    let customFace: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.text == rhs.text && lhs.tinted == rhs.tinted && lhs.accent == rhs.accent
            && lhs.fontName == rhs.fontName && lhs.size == rhs.size && lhs.customFace == rhs.customFace
    }

    var body: some View {
        Text(QiraatTint.attributed(text, tokens: tokens, words: tinted, base: .primary, tint: accent))
            .font(.custom(fontName, size: CGFloat(size)))
            .arabicFontDesign(custom: customFace)
            .multilineTextAlignment(.trailing)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .trailing)
            // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
            .environment(\.layoutDirection, .leftToRight)
            .textSelection(.enabled)
    }
}

/// One recording pair as a row: who recorded it, then the verse as Hafs and as the riwayah reads it.
/// The same keys as `QiraatVariantAudioButtons`, so the two never disagree about what is playing.
private struct QiraatClipPairRow: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var player = QiraatClipPlayer.shared

    let tag: String
    let surah: Int
    let ayah: Int

    var body: some View {
        if let pair = QiraatVariantAudioStore.shared.pair(tag: tag, surah: surah, ayah: ayah) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hafs and \(QiraatProfiles.shortName(of: tag).localizedDisplay)")
                        .font(.subheadline.weight(.semibold))
                    Text(pair.reciter)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                clipButton(String(localized: "Hafs"), key: key("hafs"), clip: pair.hafs)
                clipButton(QiraatProfiles.shortName(of: tag).localizedDisplay, key: key("riwayah"), clip: pair.riwayah)
            }
            .padding(.vertical, 2)
        }
    }

    private func key(_ side: String) -> String { "\(tag)|\(surah):\(ayah)|\(side)" }

    private func clipButton(_ label: String, key: String, clip: QiraatVariantAudioStore.Clip) -> some View {
        let playing = player.playingKey == key
        let loading = playing && player.isLoading
        return Button {
            Settings.shared.hapticFeedback()
            player.toggle(key: key, clip: clip)
        } label: {
            HStack(spacing: 5) {
                if loading {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white)
                } else {
                    Image(systemName: playing ? "stop.fill" : "play.fill")
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundColor(playing ? .white : appearance.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(playing ? appearance.accent : appearance.accent.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playing ? "Stop" : "Hear the verse as \(label) reads it")
    }
}
#endif
