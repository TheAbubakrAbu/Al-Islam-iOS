import SwiftUI

// The Quran search's row of filter buttons and its All Filters sheet. The model they edit, and the
// account of what each filter does, is QuranSearchFilterModel.swift.

#if os(iOS)
// MARK: - The filter bar

/// The row of buttons over the search results: every filter one tap away, several at once.
struct QuranSearchFilterBar: View {
    @Environment(\.appearance) private var appearance
    @Binding var filters: QuranSearchFilters
    let surahs: [Surah]
    /// Inside one surah or page (the reader's search, page mode's find bar) only the filters that
    /// shape the words apply: Match, Words, Without and Search In.
    var inReader = false
    let onOpenSheet: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allFiltersChip

                if filters.hasSessionFilters {
                    chipButton(title: "Reset", systemImage: "xmark", isOn: false) {
                        filters.resetSession()
                    }
                }

                divider
                matchMenu
                combineMenu
                // Always offered: the symbols that used to say "without" can no longer be typed.
                chipButton(title: filters.excludedWords.isEmpty ? "Without" : "Without: " + filters.excludedWords.joined(separator: ", "),
                           systemImage: "minus.circle", isOn: !filters.excludedWords.isEmpty, action: onOpenSheet)

                if inReader {
                    laneMenu
                } else {
                    scopeAndLayoutChips
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private var scopeAndLayoutChips: some View {
        divider
        ForEach(QuranSearchFilters.Revelation.allCases) { place in
            chipButton(title: place.title, systemImage: nil, isOn: filters.revelation == place) {
                filters.revelation = filters.revelation == place ? nil : place
            }
        }
        juzMenu
        surahChip
        laneMenu

        divider
        sortMenu
        goToMenu

        divider
        ForEach(QuranSearchFilters.Kind.allCases) { kind in
            chipButton(title: kind.title, systemImage: kind.systemImage, isOn: filters.shows(kind)) {
                if filters.hiddenKinds.contains(kind) {
                    filters.hiddenKinds.remove(kind)
                } else if filters.hiddenKinds.count < QuranSearchFilters.Kind.allCases.count - 1 {
                    // Never the last one: a search that shows nothing reads as broken.
                    filters.hiddenKinds.insert(kind)
                }
            }
        }
    }

    private var divider: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 1, height: 18)
    }

    private var allFiltersChip: some View {
        Button {
            Settings.shared.hapticFeedback()
            onOpenSheet()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.3")
                if filters.activeCount > 0 {
                    Text("\(filters.activeCount)")
                        .monospacedDigit()
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(filters.activeCount > 0 ? Color.white : appearance.accent)
            .background(filters.activeCount > 0 ? Capsule().fill(appearance.accent) : nil)
            .conditionalGlassEffect(useColor: filters.activeCount > 0 ? nil : 0.25, themeTint: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("All search filters")
    }

    private var matchMenu: some View {
        Menu {
            Picker("Match", selection: $filters.match) {
                ForEach(QuranSearchFilters.Match.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(title: filters.match == .contains ? "Match" : filters.match.title,
                      systemImage: "character.cursor.ibeam", isOn: filters.match != .contains, isMenu: true)
        }
    }

    private var combineMenu: some View {
        Menu {
            Picker("Words", selection: $filters.combine) {
                ForEach(QuranSearchFilters.Combine.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(title: filters.combine == .phrase ? "Words" : filters.combine.title,
                      systemImage: "text.word.spacing", isOn: filters.combine != .phrase, isMenu: true)
        }
    }

    private var laneMenu: some View {
        Menu {
            Picker("Search In", selection: $filters.lane) {
                ForEach(QuranSearchFilters.Lane.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(title: filters.lane == .all ? "Search In" : filters.lane.title,
                      systemImage: "character.book.closed", isOn: filters.lane != .all, isMenu: true)
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Order", selection: $filters.sort) {
                ForEach(QuranSearchFilters.Sort.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            chipLabel(title: filters.sort.title, systemImage: "arrow.up.arrow.down",
                      isOn: filters.sort != .mushaf, isMenu: true)
        }
    }

    private var goToMenu: some View {
        Menu {
            Picker("Go To", selection: $filters.goTo) {
                Text("Off").tag(QuranSearchFilters.GoTo?.none)
                ForEach(QuranSearchFilters.GoTo.allCases) { place in
                    Text(place.title).tag(QuranSearchFilters.GoTo?.some(place))
                }
            }
        } label: {
            chipLabel(title: filters.goTo.map { "Go to " + $0.title } ?? "Go To",
                      systemImage: "arrow.turn.down.right", isOn: filters.goTo != nil, isMenu: true)
        }
    }

    private var juzMenu: some View {
        Menu {
            if !filters.juzs.isEmpty {
                Button("Any Juz") { filters.juzs = [] }
            }
            ForEach(QuranData.juzList) { juz in
                Toggle("Juz \(juz.id) · \(juz.nameTransliteration)", isOn: Binding(
                    get: { filters.juzs.contains(juz.id) },
                    set: { isOn in
                        if isOn { filters.juzs.insert(juz.id) } else { filters.juzs.remove(juz.id) }
                    }
                ))
                // The root PaddedSwitchToggleStyle draws double-height menu rows on iOS 26.
                .toggleStyle(.automatic)
            }
        } label: {
            chipLabel(title: Self.summary(of: filters.juzs, noun: "Juz"), systemImage: "square.stack.3d.up",
                      isOn: !filters.juzs.isEmpty, isMenu: true)
        }
        .keepingMenuOpen()
    }

    /// 114 rows are a list, not a menu: the chip opens the sheet, where the surahs are searchable.
    private var surahChip: some View {
        chipButton(title: Self.summary(of: filters.surahs, noun: "Surah"), systemImage: "book.closed",
                   isOn: !filters.surahs.isEmpty, action: onOpenSheet)
    }

    static func summary(of ids: Set<Int>, noun: String) -> String {
        switch ids.count {
        case 0: return noun
        case 1...3: return noun + " " + ids.sorted().map(String.init).joined(separator: ", ")
        default: return "\(ids.count) \(noun == "Juz" ? "Juz" : "Surahs")"
        }
    }

    private func chipButton(title: String, systemImage: String?, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            chipLabel(title: title, systemImage: systemImage, isOn: isOn, isMenu: false)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func chipLabel(title: String, systemImage: String?, isOn: Bool, isMenu: Bool) -> some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .lineLimit(1)
            if isMenu {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .opacity(0.7)
            }
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(isOn ? Color.white : appearance.accent)
        .background(isOn ? Capsule().fill(appearance.accent) : nil)
        .conditionalGlassEffect(useColor: isOn ? nil : 0.25, themeTint: false)
        .contentShape(Capsule())
    }
}

private extension View {
    /// A multi-select menu stays open between taps where the system allows it (iOS 16.4).
    @ViewBuilder
    func keepingMenuOpen() -> some View {
        if #available(iOS 16.4, *) {
            menuActionDismissBehavior(.disabled)
        } else {
            self
        }
    }
}

// MARK: - The filter sheet

/// Every filter on one page, each with a line saying what it does.
struct QuranSearchFilterSheet: View {
    @Environment(\.appearance) private var appearance
    @Binding var filters: QuranSearchFilters
    let surahs: [Surah]
    var inReader = false

    @State private var surahQuery = ""
    @State private var showAllSurahs = false

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    if !inReader {
                        showSection
                        orderSection
                    }
                    matchSection
                    combineSection
                    withoutSection
                    laneSection
                    if !inReader {
                        revelationSection
                        juzSection
                        surahSection
                        goToSection
                    }
                    resetSection
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .tint(appearance.accent)
    }

    private func header(_ text: String) -> some View {
        Text(text).foregroundStyle(appearance.accent)
    }

    private func optionRow(title: String, detail: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? appearance.accent : Color.secondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var showSection: some View {
        Section {
            ForEach(QuranSearchFilters.Kind.allCases) { kind in
                optionRow(title: kind.title, detail: kind.detail, isOn: filters.shows(kind)) {
                    if filters.hiddenKinds.contains(kind) {
                        filters.hiddenKinds.remove(kind)
                    } else if filters.hiddenKinds.count < QuranSearchFilters.Kind.allCases.count - 1 {
                        filters.hiddenKinds.insert(kind)
                    }
                }
            }
        } header: {
            header("SHOW")
        } footer: {
            Text("Which kinds of result a search lists. Remembered between searches.")
        }
    }

    private var orderSection: some View {
        Section {
            ForEach(QuranSearchFilters.Sort.allCases) { sort in
                optionRow(title: sort.title, detail: sort.detail, isOn: filters.sort == sort) {
                    filters.sort = sort
                }
            }
        } header: {
            header("AYAH ORDER")
        } footer: {
            Text("Remembered between searches.")
        }
    }

    private var matchSection: some View {
        Section {
            ForEach(QuranSearchFilters.Match.allCases) { match in
                optionRow(title: match.title, detail: match.detail, isOn: filters.match == match) {
                    filters.match = match
                }
            }
        } header: {
            header("MATCH")
        }
    }

    private var combineSection: some View {
        Section {
            ForEach(QuranSearchFilters.Combine.allCases) { combine in
                optionRow(title: combine.title, detail: combine.detail, isOn: filters.combine == combine) {
                    filters.combine = combine
                }
            }
        } header: {
            header("SEVERAL WORDS")
        }
    }

    private var withoutSection: some View {
        Section {
            TextField("Words to leave out", text: $filters.excluded)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
        } header: {
            header("WITHOUT")
        } footer: {
            Text("No result carries any of these words. Separate several with spaces.")
        }
    }

    private var laneSection: some View {
        Section {
            ForEach(QuranSearchFilters.Lane.allCases) { lane in
                optionRow(title: lane.title, detail: lane.detail, isOn: filters.lane == lane) {
                    filters.lane = lane
                }
            }
        } header: {
            header("SEARCH IN")
        } footer: {
            Text("For searches typed in Latin letters. Arabic script always searches the Arabic.")
        }
    }

    private var revelationSection: some View {
        Section {
            optionRow(title: "Makki and Madani", detail: "Every surah", isOn: filters.revelation == nil) {
                filters.revelation = nil
            }
            optionRow(title: "Makki", detail: "The 86 surahs revealed before the Hijrah. Typed: makki",
                      isOn: filters.revelation == .makkan) {
                filters.revelation = .makkan
            }
            optionRow(title: "Madani", detail: "The 28 surahs revealed after the Hijrah. Typed: madani",
                      isOn: filters.revelation == .madinan) {
                filters.revelation = .madinan
            }
        } header: {
            header("REVELATION")
        }
    }

    private var juzSection: some View {
        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(QuranData.juzList) { juz in
                    let isOn = filters.juzs.contains(juz.id)
                    Button {
                        Settings.shared.hapticFeedback()
                        if isOn { filters.juzs.remove(juz.id) } else { filters.juzs.insert(juz.id) }
                    } label: {
                        Text("\(juz.id)")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .foregroundStyle(isOn ? Color.white : appearance.accent)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isOn ? appearance.accent : appearance.accent.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Juz \(juz.id)")
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        } header: {
            header("WITHIN JUZ")
        } footer: {
            Text(filters.juzs.isEmpty ? "Tap any number of juz to search inside them only."
                                      : "Searching inside \(QuranSearchFilterBar.summary(of: filters.juzs, noun: "Juz")).")
        }
    }

    private var matchingSurahs: [Surah] {
        let query = surahQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return surahs }
        let found = QuranData.shared.filteredSurahs(for: query, countQuery: nil)
        return found
    }

    private var surahSection: some View {
        Section {
            if !filters.surahs.isEmpty {
                Button("Clear \(filters.surahs.count) Chosen") {
                    Settings.shared.hapticFeedback()
                    filters.surahs = []
                }
            }
            TextField("Find a surah", text: $surahQuery)
                .autocorrectionDisabled(true)
            let list = matchingSurahs
            let visible = (showAllSurahs || !surahQuery.isEmpty) ? list : list.filter { filters.surahs.contains($0.id) }
            ForEach(visible, id: \.id) { surah in
                optionRow(title: "\(surah.id). \(surah.nameTransliteration)", detail: surah.nameEnglish,
                          isOn: filters.surahs.contains(surah.id)) {
                    if filters.surahs.contains(surah.id) {
                        filters.surahs.remove(surah.id)
                    } else {
                        filters.surahs.insert(surah.id)
                    }
                }
            }
            if surahQuery.isEmpty {
                Button(showAllSurahs ? "Show Chosen Only" : "Show All 114 Surahs") {
                    showAllSurahs.toggle()
                }
            }
        } header: {
            header("WITHIN SURAHS")
        } footer: {
            Text("Ayah results come from the chosen surahs only.")
        }
    }

    private var goToSection: some View {
        Section {
            optionRow(title: "Off", detail: "A number offers its surah, page and juz together",
                      isOn: filters.goTo == nil) {
                filters.goTo = nil
            }
            ForEach(QuranSearchFilters.GoTo.allCases) { place in
                optionRow(title: place.title, detail: place.placeholder + ". Typed: \(place.rawValue) 5",
                          isOn: filters.goTo == place) {
                    filters.goTo = place
                }
            }
        } header: {
            header("GO TO")
        } footer: {
            Text("Reads what you type as one kind of place. Counting from the end works everywhere: -1 is the last.")
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                Settings.shared.hapticFeedback()
                filters = QuranSearchFilters()
            } label: {
                Text("Reset All Filters")
                    .frame(maxWidth: .infinity)
            }
            .disabled(filters.activeCount == 0)
        }
    }
}
#endif
