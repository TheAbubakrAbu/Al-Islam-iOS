#if os(iOS)
import SwiftUI
import CoreText

struct TajweedLegendView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.presentationMode) private var presentationMode

    var showsDismissButton = true

    /// The riwayah whose legend is being PREVIEWED, independent of what is being read (user rule: with
    /// qiraah details on, the legend can show any riwayah's tajweed). nil = follow the displayed riwayah.
    @State private var previewTag: String?
    /// The compare mode: every riwayah's printed color code, one after another.
    @State private var compareAll = false
    /// How the comparison is grouped: false = one card per riwayah under its qiraah's section,
    /// true = one section per rule listing the riwayat that mark it. Remembered across opens.
    @AppStorage("tajweedCompareGrouping") private var compareByRule = false
    /// The by-rule index, built once (off-main) the first time By Rule is opened.
    @State private var ruleSections: [CompareRuleSection]?
    /// The detailed page (quick-guide grid, detail cards, colors, signs, riwayat) instead of the compact
    /// one. Every open starts compact (Abu, 2026-10-28: "a basic tajweed view in legend by default ...
    /// look at how small and easy it is to see, especially for simple mode"); the toolbar button
    /// switches (Abu, 2026-11-17: "one screen no scrolling ... a toolbar button that allows us to
    /// change between detailed and compact").
    @State private var showsFullLegend = false
    /// The reader's legend sheet holds the switch itself and draws its button (`detailed`): its bar
    /// then stays the same on every page of its picker, and this page adds nothing to it.
    private let hostedDetailed: Binding<Bool>?
    /// The compact tile whose card is up (its popover), by rule id.
    @State private var inspectedRule: String?

    /// `opensFullLegend`: a door that leads to something only the full page has (Customize Tajweed
    /// Colors: the color pickers sit on the full page's rule cards) opens there instead of on the basic list.
    /// `detailed`: the host owns the Compact / Detailed switch and its toolbar button.
    init(showsDismissButton: Bool = true, opensFullLegend: Bool = false, detailed: Binding<Bool>? = nil) {
        self.showsDismissButton = showsDismissButton
        self.hostedDetailed = detailed
        _showsFullLegend = State(initialValue: opensFullLegend)
    }

    private var detailedBinding: Binding<Bool> { hostedDetailed ?? $showsFullLegend }
    private var isDetailed: Bool { detailedBinding.wrappedValue }

    /// Every riwayah that ships a print-derived color pack - a cheap static check (`fileName`, no pack
    /// load), so building the picker menu never parses 19 packs.
    nonisolated private static let packOptions: [Settings.Riwayah.Option] = Settings.Riwayah.allOptions.filter {
        QiraahTajweedStore.fileName(for: $0.tag) != nil
    }

    /// The legend the page leads with: the previewed riwayah when one is picked (nil = the Hafs guide),
    /// else whatever is actually displayed.
    private var effectiveLegendTag: String? {
        // The compact page explains what is being read, never a previewed riwayah.
        guard isDetailed, let previewTag else { return currentRiwayahLegendTag }
        let canonical = Settings.Riwayah.canonicalTag(previewTag)
        return canonical == Settings.Riwayah.canonicalTag(Settings.Riwayah.hafsTag) ? nil : previewTag
    }

    private func optionLabel(forTag tag: String) -> String {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        return Settings.Riwayah.allOptions
            .first { Settings.Riwayah.canonicalTag($0.tag) == canonical }?
            .displayLabel() ?? tag
    }

    private struct LegendSection: Identifiable {
        let section: TajweedLegendCategory.Section
        let items: [TajweedLegendCategory]

        var id: String { section.id }
    }

    private var sections: [LegendSection] {
        let grouped = Dictionary(grouping: TajweedLegendCategory.allCases, by: { $0.section })
        return TajweedLegendCategory.Section.allCases.compactMap { section in
            guard let items = grouped[section] else { return nil }
            return LegendSection(section: section, items: items.sorted(by: { $0.sortRank < $1.sortRank }))
        }
    }

    private var quickLegendColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10, alignment: .top),
            GridItem(.flexible(), spacing: 10, alignment: .top)
        ]
    }

    /// The displayed riwayah's tag when it is non-Hafs and ships a print-derived
    /// color pack - its own legend then leads the page.
    private var currentRiwayahLegendTag: String? { settings.riwayahTajweedPackTag }

    @ViewBuilder
    private func visibilityButton(title: String, systemImage: String, visible: Bool) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                TajweedLegendCategory.allCases.forEach {
                    settings.setTajweedCategory($0, visible: visible)
                }
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(settings.accentColor.color)
        .conditionalGlassEffect(rectangle: true)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func legendLine(_ text: String, primary: Bool = true) -> some View {
        Text(text)
            .font(primary ? .caption.weight(.semibold) : .caption)
            .foregroundStyle(primary ? .primary : .secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Show All / Hide All for the riwayah's own rules - same shape as the Hafs buttons.
    @ViewBuilder
    private func riwayahVisibilityButton(title: String, systemImage: String, visible: Bool,
                                         entries: [QiraahTajweedStore.LegendEntry]) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation {
                entries.forEach { settings.setRiwayahTajweedRule($0.key, visible: visible) }
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(settings.accentColor.color)
        .conditionalGlassEffect(rectangle: true)
        .contentShape(Rectangle())
    }

    /// The riwayah rule as a quick-guide grid card - the same layout as the Hafs cards.
    @ViewBuilder
    private func riwayahQuickCard(_ entry: QiraahTajweedStore.LegendEntry) -> some View {
        let visible = settings.isRiwayahTajweedRuleVisible(entry.key)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(entry.color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 3) {
                    legendLine(entry.english.localizedDisplay)
                    legendLine(entry.arabic, primary: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }

            if #available(iOS 16.0, *) {
                Text(entry.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(entry.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline) {
                // The words the print colors with it (the Hafs cards' count line).
                if let riwayahTag = effectiveLegendTag,
                   let count = TajweedLegendExamples.countLabel(QiraahTajweedStore.shared.ruleWordCounts(for: riwayahTag)[entry.key]) {
                    Text(count)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(visible ? entry.color : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 4)

                Label(visible ? "Hide" : "Show", systemImage: visible ? "eye.fill" : "eye.slash.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(visible ? entry.color : .secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation {
                settings.setRiwayahTajweedRule(entry.key, visible: !visible)
            }
        }
        .opacity(visible ? 1 : 0.45)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(alignment: .topLeading)
        .padding(12)
        .contentSurface(rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(entry.color.opacity(0.35), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func countBadge(_ item: TajweedLegendCategory) -> some View {
        if let count = item.countLabel {
            Text(count.localizedDigits)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(item.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(
                    Capsule(style: .continuous)
                        .fill(item.color.opacity(0.15))
                )
        }
    }

    @ViewBuilder
    private func quickItemCard(_ item: TajweedLegendCategory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(item.color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 3) {
                    legendLine(item.transliteration)
                    legendLine(item.exactEnglishTranslation, primary: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }

            countBadge(item)

            if #available(iOS 16.0, *) {
                Text(item.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2 ,reservesSpace: true)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(item.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Label(settings.isTajweedCategoryVisible(item) ? "Hide" : "Show", systemImage: settings.isTajweedCategoryVisible(item) ? "eye.fill" : "eye.slash.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(settings.isTajweedCategoryVisible(item) ? item.color : .secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation {
                settings.setTajweedCategory(item, visible: !settings.isTajweedCategoryVisible(item))
            }
        }
        .opacity(settings.isTajweedCategoryVisible(item) ? 1 : 0.45)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(alignment: .topLeading)
        .padding(12)
        .contentSurface(rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(item.color.opacity(0.35), lineWidth: 1)
        )
    }

    /// The riwayah preview row: a menu naming whose legend is on the page, plus the compare toggle.
    /// Previewing never changes the reading riwayah - it only swaps which color code is explained below.
    private var riwayahPreviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Showing")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 8)

                Menu {
                    Button {
                        settings.hapticFeedback()
                        withAnimation { previewTag = nil }
                    } label: {
                        Label("Currently Reading", systemImage: previewTag == nil ? "checkmark" : "book")
                    }

                    Divider()

                    Button {
                        settings.hapticFeedback()
                        withAnimation { previewTag = Settings.Riwayah.hafsTag }
                    } label: {
                        selectionLabel(Settings.Riwayah.option(for: Settings.Riwayah.hafsTag).displayLabel(), tag: Settings.Riwayah.hafsTag)
                    }

                    // The same nested grammar as the riwayah picker everywhere else: one submenu
                    // per qiraah, each opening its two riwayat - not a flat list of all twenty. The
                    // six beta qiraat sit behind one Beta Riwayat door (2026-10-21): twelve rows were
                    // the legend's longest menu.
                    let groups = Settings.Riwayah.groups
                    ForEach(groups.filter { !$0.isBeta }) { group in
                        teacherMenu(group)
                    }

                    let beta = groups.filter(\.isBeta)
                    if !beta.isEmpty {
                        Menu {
                            ForEach(beta) { group in
                                teacherMenu(group)
                            }
                        } label: {
                            Label("Beta Riwayat", systemImage: "testtube.2")
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(previewTag.map { optionLabel(forTag: $0) }
                             ?? String(localized: "\(optionLabel(forTag: currentRiwayahLegendTag ?? Settings.Riwayah.hafsTag)) (reading)"))
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(settings.accentColor.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .conditionalGlassEffect()
                }
                .fixedMenuOrder()
            }

            Text("Preview any riwayah's tajweed color code here without changing what you are reading.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                withAnimation { compareAll.toggle() }
            } label: {
                // The contentShape must sit INSIDE the label: with `.plain`, a shape applied outside
                // the Button never widened the hit area, so only the words themselves took the tap.
                Label(compareAll ? "Show Full Legend" : "Compare All Riwayat",
                      systemImage: compareAll ? "rectangle.stack.fill" : "rectangle.stack")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(settings.accentColor.color)
            .conditionalGlassEffect(rectangle: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentSurface(rectangle: true)
    }

    /// A menu row for one riwayah, checkmarked when it is the previewed one.
    /// One qiraah's submenu: its two riwayat, the teacher's name on the door.
    @ViewBuilder
    private func teacherMenu(_ group: Settings.Riwayah.Group) -> some View {
        Menu {
            ForEach(group.options, id: \.tag) { option in
                Button {
                    settings.hapticFeedback()
                    withAnimation { previewTag = option.tag }
                } label: {
                    selectionLabel(option.displayLabel(), tag: option.tag)
                }
            }
        } label: {
            Label(
                AppLanguage.isArabicScript ? group.teacherArabic : "\(group.teacher) - \(group.teacherArabic)",
                systemImage: group.options.contains(where: { option in
                    previewTag.map { tag in
                        Settings.Riwayah.canonicalTag(tag) == Settings.Riwayah.canonicalTag(option.tag)
                    } ?? false
                }) ? "checkmark" : "book.closed"
            )

            if let detail = Settings.Riwayah.teacherDetail(group.teacher) {
                Text(detail)
            }
        }
    }

    private func selectionLabel(_ title: String, tag: String) -> some View {
        let selected = previewTag.map {
            Settings.Riwayah.canonicalTag($0) == Settings.Riwayah.canonicalTag(tag)
        } ?? false
        return Label(title, systemImage: selected ? "checkmark" : "character.book.closed.fill.ar")
    }

    /// The compare mode: every riwayah's printed color code, groupable two ways. By qiraah (default):
    /// one compact card per riwayah under its qiraah's section header - Hafs an Asim's section always
    /// first with its engine rules on top, the other qiraat alphabetical. By rule: one section per
    /// print-derived rule in the app's rule order (`QiraahTajweedStore.ruleOrder`), listing which riwayat
    /// mark it (Hafs first where its own legend colors an equivalent, the rest alphabetical). LazyVStack, so by-qiraah cards only parse their pack when
    /// scrolled into view; the by-rule index is built once, off the main thread.
    private func compareAllSection(scroll: ScrollViewProxy?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Riwayat Compared")
                .font(.headline)

            Text("Each riwayah's mushaf prints its own color code. The same rule keeps the same meaning everywhere; what changes is which rules that riwayah marks.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Group By", selection: $compareByRule) {
                Text("By Qiraah").tag(false)
                Text("By Rule").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: compareByRule) { _ in settings.hapticFeedback() }

            if compareByRule {
                compareByRuleContent(scroll: scroll)
            } else {
                compareByQiraahContent(scroll: scroll)
            }

            Text("Tap any riwayah to see its full legend.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .task(id: compareByRule) {
            guard compareByRule, ruleSections == nil else { return }
            let sections = await Task.detached(priority: .userInitiated) {
                Self.buildRuleSections()
            }.value
            withAnimation(.easeInOut) { ruleSections = sections }
        }
    }

    private func compareByQiraahContent(scroll: ScrollViewProxy?) -> some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(Self.compareQiraahGroups) { group in
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLanguage.isArabicScript ? group.teacherArabic : "\(group.teacher.localizedUppercase) - \(group.teacherArabic)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if group.includesHafs {
                        // The Arabic interface titles the card with the Arabic name, so the corner
                        // caption (the same name again) stays empty there.
                        compareCardShell(
                            title: Settings.Riwayah.option(for: Settings.Riwayah.hafsTag).displayLabel(),
                            arabic: AppLanguage.isArabicScript ? "" : Settings.Riwayah.hafsArabic
                        ) {
                            ForEach(TajweedLegendCategory.allCases.sorted { $0.sortRank < $1.sortRank }) { item in
                                compareRuleRow(color: item.color, english: item.transliteration)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { previewRiwayah(tag: Settings.Riwayah.hafsTag, scroll: scroll) }
                    }

                    ForEach(group.options, id: \.tag) { option in
                        let counts = QiraahTajweedStore.shared.ruleWordCounts(for: option.tag)
                        compareCardShell(title: option.displayLabel(), arabic: AppLanguage.isArabicScript ? "" : option.arabic) {
                            ForEach(QiraahTajweedStore.shared.legend(for: option.tag)) { entry in
                                compareRuleRow(color: entry.color, english: entry.english.localizedDisplay,
                                               count: counts[entry.key])
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { previewRiwayah(tag: option.tag, scroll: scroll) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func compareByRuleContent(scroll: ScrollViewProxy?) -> some View {
        if let ruleSections {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(ruleSections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(section.english.localizedDisplay)
                                .font(.subheadline.weight(.semibold))

                            Spacer(minLength: 6)

                            Text(section.arabic)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }

                        if !section.description.isEmpty {
                            Text(section.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        LazyVGrid(columns: quickLegendColumns, alignment: .leading, spacing: 6) {
                            ForEach(section.rows) { row in
                                compareRuleRow(color: row.color, english: row.title, count: row.count)
                                    .contentShape(Rectangle())
                                    .onTapGesture { previewRiwayah(tag: row.tag, scroll: scroll) }
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentSurface(rectangle: true)
                }
            }
        } else {
            HStack(spacing: 8) {
                ProgressView()
                Text("Indexing all riwayah legends…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        }
    }

    /// The by-qiraah sections: Asim first (Hafs an Asim on top of it - user rule), the other
    /// qiraat alphabetically (ignoring "al-"), each holding its bundled riwayah packs.
    private struct CompareQiraahGroup: Identifiable {
        let teacher: String
        let teacherArabic: String
        let includesHafs: Bool
        let options: [Settings.Riwayah.Option]
        var id: String { teacher }
    }

    private static let compareQiraahGroups: [CompareQiraahGroup] = {
        let hafs = Settings.Riwayah.option(for: Settings.Riwayah.hafsTag)
        let byTeacher = Dictionary(grouping: packOptions, by: \.teacher)
        func alphaKey(_ teacher: String) -> String {
            let lower = teacher.lowercased()
            return lower.hasPrefix("al-") ? String(lower.dropFirst(3)) : lower
        }
        var groups: [CompareQiraahGroup] = [
            CompareQiraahGroup(
                teacher: hafs.teacher,
                teacherArabic: hafs.teacherArabic,
                includesHafs: true,
                options: (byTeacher[hafs.teacher] ?? []).sorted { $0.label < $1.label }
            )
        ]
        let rest = byTeacher.keys
            .filter { $0 != hafs.teacher }
            .sorted { alphaKey($0) < alphaKey($1) }
        for teacher in rest {
            guard let opts = byTeacher[teacher], let first = opts.first else { continue }
            groups.append(CompareQiraahGroup(
                teacher: teacher,
                teacherArabic: first.teacherArabic,
                includesHafs: false,
                options: opts.sorted { $0.label < $1.label }
            ))
        }
        return groups
    }()

    // MARK: By-rule index

    private struct CompareRuleRowItem: Identifiable {
        let id: String
        let color: Color
        let title: String
        /// The riwayah this row stands for - tapping it previews that riwayah's own legend.
        let tag: String
        /// The words this riwayah's print colors with the rule; nil for the Hafs engine rows.
        var count: Int? = nil
    }

    private struct CompareRuleSection: Identifiable {
        let key: String
        let english: String
        let arabic: String
        let description: String
        let rows: [CompareRuleRowItem]
        var id: String { key }
    }

    /// Print-derived rule keys whose equivalent the HAFS legend also colors - only these get a
    /// "Hafs an Asim" row (at the top of their section, user rule). Kept deliberately narrow:
    /// a Hafs row claims "the standard Hafs color code marks this", so rules Hafs applies but
    /// never colors (its four sakt places, the lone imalah of 11:41) stay off this list.
    nonisolated private static let hafsColoredCounterparts: [String: [TajweedLegendCategory]] = [
        "idgham": [.idghamGhunnah, .idghamBilaGhunnah],
        "madd_badal": [.maddNatural],
        "madd_leen": [.maddSukoon],
    ]

    /// Rule keys that are ONE rule printed under two captions, folded into a single section. Sixteen of
    /// the prints call the magenta "the letter differing from Hafs" and three (ad-Duri, Khalaf, Khallad)
    /// call it "the word differing from Hafs" - the same color marking the same thing. Split across two
    /// sections the index read as "only some riwayat mark what differs from Hafs" (Abu's report); every
    /// riwayah does. The per-riwayah cards still show each print's own wording. The fold itself lives in
    /// the store (`QiraahTajweedStore.ruleAliases`), shared with the riwayat page's color-code guide.
    nonisolated private static var compareRuleAliases: [String: String] { QiraahTajweedStore.ruleAliases }

    /// Titles and descriptions for a folded section, so it isn't named after whichever print sorted first.
    /// `english` is the plain English title (`QiraahTajweedStore.ruleTitleOverrides`), untranslated like
    /// the packs' captions; the section header translates it when it draws it.
    nonisolated private static let compareRuleOverrides: [String: (english: String, arabic: String, description: String)] = [
        "khilaf_harf": (
            QiraahTajweedStore.ruleTitleOverrides["khilaf_harf"]?.english ?? "Differing from Ḥafṣ",
            QiraahTajweedStore.ruleTitleOverrides["khilaf_harf"]?.arabic ?? "المُخَالِفُ لِحَفصٍ",
            String(localized: "Read differently from the Ḥafṣ an ʿĀṣim reading. Every riwayah marks this.")
        )
    ]

    /// Loads every bundled pack's legend and inverts it: rule key -> the riwayat that mark it.
    /// Hafs-only engine rules do NOT get sections of their own (user rule) - Hafs appears only
    /// inside sections other riwayat opened, via `hafsColoredCounterparts`.
    nonisolated private static func buildRuleSections() -> [CompareRuleSection] {
        struct Collected {
            var english: String
            var arabic: String
            var rows: [CompareRuleRowItem] = []
            /// The printed caption each riwayah gives this rule, in label order - only ever more than
            /// one for a folded section, and then it is worth telling the reader which print says what.
            var captions: [(english: String, labels: [String])] = []

            mutating func note(caption: String, label: String) {
                if let idx = captions.firstIndex(where: { $0.english == caption }) {
                    captions[idx].labels.append(label)
                } else {
                    captions.append((english: caption, labels: [label]))
                }
            }
        }
        var byKey: [String: Collected] = [:]

        for option in packOptions.sorted(by: { $0.label < $1.label }) {
            let counts = QiraahTajweedStore.shared.ruleWordCounts(for: option.tag)
            for entry in QiraahTajweedStore.shared.legend(for: option.tag) {
                let key = compareRuleAliases[entry.key] ?? entry.key
                var collected = byKey[key] ?? Collected(english: entry.english, arabic: entry.arabic)
                collected.rows.append(CompareRuleRowItem(
                    id: "\(key)-\(option.tag)",
                    color: entry.color,
                    title: option.displayLabel(),
                    tag: option.tag,
                    count: counts[entry.key]
                ))
                collected.note(caption: entry.english, label: option.displayLabel())
                byKey[key] = collected
            }
        }

        return byKey
            .map { key, collected -> CompareRuleSection in
                let hafsRows = (hafsColoredCounterparts[key] ?? []).map { category in
                    CompareRuleRowItem(
                        id: "\(key)-hafs-\(category.rawValue)",
                        color: category.color,
                        title: AppLanguage.isArabicScript
                            ? "\(Settings.Riwayah.option(for: Settings.Riwayah.hafsTag).displayLabel(omitsDefaultSuffix: true)) - \(category.transliteration)"
                            : "\(Settings.Riwayah.hafsLabel) - \(category.transliteration)",
                        tag: Settings.Riwayah.hafsTag
                    )
                }
                let override = compareRuleOverrides[key]
                let base = override?.description ?? QiraahTajweedStore.shortDescriptions[key] ?? ""
                return CompareRuleSection(
                    key: key,
                    english: override?.english ?? collected.english,
                    arabic: override?.arabic ?? collected.arabic,
                    description: [base, captionNote(collected.captions)]
                        .filter { !$0.isEmpty }
                        .joined(separator: " "),
                    rows: hafsRows + collected.rows
                )
            }
            // The app's one rule order (`QiraahTajweedStore.ruleOrder`): taqlil right after imalah, the
            // merges before the tilts, instead of wherever the alphabet left them (Abu, 2026-11-01).
            .sorted {
                let rankA = QiraahTajweedStore.ruleRank($0.key), rankB = QiraahTajweedStore.ruleRank($1.key)
                return rankA == rankB ? $0.english < $1.english : rankA < rankB
            }
    }

#if DEBUG
    /// "-auditTajweedLegends": the by-rule index exactly as the compare screen builds it, printed and
    /// written to Documents/legendaudit.txt. The legend page is reachable only by tapping, and taps are
    /// not scriptable in the simulator, so this is the only way to check what the index actually lists.
    nonisolated static func auditRuleSections() {
        var lines: [String] = []
        for section in buildRuleSections() {
            lines.append("\(section.key) | \(section.english) | \(section.arabic) | \(section.rows.count) rows")
            lines.append("   rows: \(section.rows.map(\.title).joined(separator: ", "))")
            if !section.description.isEmpty { lines.append("   \(section.description)") }
        }
        for line in lines { print("LEGEND AUDIT \(line)") }
        fflush(stdout)
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? lines.joined(separator: "\n").write(to: documents.appendingPathComponent("legendaudit.txt"),
                                                     atomically: true, encoding: .utf8)
        }
    }
#endif

    /// "The prints caption it differently: ..." - written only for a folded section, and only naming the
    /// riwayat whose caption is the minority one, so the sentence stays a sentence.
    nonisolated private static func captionNote(_ captions: [(english: String, labels: [String])]) -> String {
        guard captions.count > 1,
              let majority = captions.max(by: { $0.labels.count < $1.labels.count }) else { return "" }
        let others = captions
            .filter { $0.english != majority.english }
            .map { String(localized: "“\($0.english.localizedDisplay)” in \(ListFormatter.localizedString(byJoining: $0.labels))") }
        guard !others.isEmpty else { return "" }
        // Arabic separates the clauses with its own semicolon ("؛").
        let separator = AppLanguage.isArabicScript ? "؛ " : "; "
        return String(localized: "The prints caption it differently: \(others.joined(separator: separator)); “\(majority.english.localizedDisplay)” in the rest.")
    }

    private func compareCardShell<Rows: View>(title: String, arabic: String,
                                              @ViewBuilder rows: () -> Rows) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 6)

                Text(arabic)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            LazyVGrid(columns: quickLegendColumns, alignment: .leading, spacing: 6) {
                rows()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentSurface(rectangle: true)
    }

    /// Tapping any riwayah in the comparison previews ITS legend - the reason to read the comparison
    /// is to find the riwayah you want to look at properly, and the alternative was scrolling back to
    /// the picker and finding the same name in a two-level menu. Leaves the compare mode (the previewed
    /// legend is what you asked to see) and returns the page to the top, since the content underneath
    /// the finger is replaced wholesale. Never touches what is being READ.
    private func previewRiwayah(tag: String, scroll: ScrollViewProxy?) {
        settings.hapticFeedback()
        withAnimation {
            previewTag = tag
            compareAll = false
            scroll?.scrollTo(Self.legendTopAnchorID, anchor: .top)
        }
    }

    /// `count`: the words the riwayah's print colors with the rule, when known (Abu, 2026-11-01:
    /// "for comparing riwayaat mention the count of each riwayah"); the Hafs engine rows have none.
    private func compareRuleRow(color: Color, english: String, count: Int? = nil) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(english)
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let count {
                Spacer(minLength: 2)

                Text(count.formatted())
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// "More Detail", the one place a rule's color changes, and the way back to the canonical colors
    /// for the rules listed under it (shown only once one of them has been recolored).
    @ViewBuilder
    private func moreDetailHeader(colorKeys: [String]) -> some View {
        // Read through Settings so the button appears and leaves with the stored string.
        let _ = settings.tajweedCustomColors
        let customized = colorKeys.filter { TajweedColorOverrides.shared.isCustomized($0) }
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("More Detail")
                    .font(.headline)

                Spacer(minLength: 8)

                if !customized.isEmpty {
                    Button {
                        settings.hapticFeedback()
                        withAnimation { settings.resetTajweedCustomColors(forKeys: customized) }
                    } label: {
                        Label("Reset Colors", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(settings.accentColor.color)
                }
            }

            Text("Tap a card to show or hide its rule. Each rule's color can be changed from its card here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func detailItemCard(_ item: TajweedLegendCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(item.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    legendLine(item.transliteration)
                    legendLine(item.arabicTitle, primary: false)
                    legendLine(item.exactEnglishTranslation, primary: false)
                }

                Spacer(minLength: 6)

                Label(settings.isTajweedCategoryVisible(item) ? "Hide" : "Show", systemImage: settings.isTajweedCategoryVisible(item) ? "eye.fill" : "eye.slash.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.isTajweedCategoryVisible(item) ? item.color : .secondary)
            }

            countBadge(item)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let letters = item.applicableLettersDetail {
                Text(letters)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(item.englishMeaning.localizedDigits)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(item.longDescription.localizedDigits)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let example = TajweedLegendExamples.hafs(item) {
                example
            }

            TajweedRuleColorRow(
                colorKey: TajweedColorOverrides.key(for: item),
                ruleName: item.transliteration,
                current: item.color,
                customCaption: String(localized: "Your color"),
                defaultCaption: String(localized: "Default color")
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation {
                settings.setTajweedCategory(item, visible: !settings.isTajweedCategoryVisible(item))
            }
        }
        .opacity(settings.isTajweedCategoryVisible(item) ? 1 : 0.45)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(alignment: .topLeading)
        .padding(14)
        .contentSurface(rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(item.color.opacity(0.2), lineWidth: 1)
        )
    }

    /// Compare mode takes the page over: the button's whole point is to bring the comparison to
    /// the top, so while it's on nothing else renders (the always-on copy at the page's bottom is
    /// what you scroll past otherwise).
    private var compareOnlyMode: Bool { settings.showQiraahDetails && compareAll }

    /// The page header, so a riwayah tapped deep inside the comparison lands with its legend in view.
    private static let legendTopAnchorID = "tajweedLegendTop"

    var body: some View {
        Group {
            if isDetailed {
                detailedLegend
            } else {
                compactLegend
            }
        }
        // Pushed inside the Quran settings sheet as well as presented as one: its own bar either way.
        .sheetNowPlayingBar()
        .accentWashedBackground()
        // The examples of the legend on screen, painted ahead of the first card that opens.
        .task(id: effectiveLegendTag) { TajweedLegendExamples.prewarm(tag: effectiveLegendTag) }
        .navigationTitle("Legend")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDismissButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        settings.hapticFeedback()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                }
            }
            // In the reader's legend sheet the sheet draws the switch, the same on its three pages.
            if hostedDetailed == nil {
                ToolbarItem(placement: .primaryAction) {
                    legendModeButton
                }
            }
        }
        .onChange(of: isDetailed) { detailed in
            inspectedRule = nil
            if !detailed {
                previewTag = nil
                compareAll = false
            }
        }
    }

    /// The detailed page: the quick-guide cards, the long notes, custom colors, the mushaf signs and,
    /// with qiraah details on, the riwayat comparison.
    private var detailedLegend: some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tajweed Legend")
                            .font(.title3.weight(.semibold))

                        Text(compareOnlyMode
                             ? "Every riwayah's printed color code, side by side."
                             : "Use the colors as a quick guide, then read the longer notes below for what each rule is doing in recitation.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .id(Self.legendTopAnchorID)

                    if compareOnlyMode {
                        // ONLY the comparison (plus the card holding the way back): clicking Compare All
                        // Riwayat brings the riwayat to the top instead of burying them under the legend.
                        riwayahPreviewCard

                        compareAllSection(scroll: scroll)
                    } else {
                        fullLegendContent(scroll: scroll)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
        }
    }

    /// "Show Tajweed colors", the switch both the basic list and the full page lead with.
    private var masterToggleCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(
                get: { settings.showTajweedColors },
                set: { newValue in
                    settings.hapticFeedback()
                    withAnimation {
                        settings.showTajweedColors = newValue
                        // Mirror the master switch onto every category so the legend below visibly
                        // reflects on/off (all rules go gray when off).
                        TajweedLegendCategory.allCases.forEach {
                            settings.setTajweedCategory($0, visible: newValue)
                        }
                    }
                }
            )) {
                Text("Show Tajweed colors")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(settings.accentColor.color)

            // The reader's Legend button stays up with the colors off (grey dots), so this switch
            // stays one tap away; only Simple Mode folds the button while nothing is colored.
            Text(settings.hides(.legendPill) && ThemeHighlights.shared.isEmpty
                 ? "Simple Mode hides the Legend button while nothing is colored. To turn this back on, go to Quran Settings → Arabic Text"
                 : "The Legend button stays in the reader with the colors off, so you can turn this back on from there")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentSurface(rectangle: true)
    }

    // MARK: Compact legend

    /// One rule of the compact grid, for a Hafs category and a riwayah rule alike.
    private struct BasicRule: Identifiable {
        let id: String
        let color: Color
        let title: String
        let subtitle: String
        /// The rule's Arabic name for its card (a riwayah rule's subtitle already is one).
        let arabic: String?
        let count: String?
        let detail: String
        let letters: String?
        let visible: Bool
        let setVisible: (Bool) -> Void
        /// The rule's example block, built only when its card opens (the paint is not free).
        let example: () -> TajweedRuleExample?
    }

    private func basicRule(_ item: TajweedLegendCategory) -> BasicRule {
        BasicRule(
            id: item.id, color: item.color,
            title: item.transliteration, subtitle: item.exactEnglishTranslation,
            arabic: item.arabicTitle,
            count: item.countLabel?.localizedDigits, detail: item.shortDescription,
            letters: item.applicableLettersDetail,
            visible: settings.isTajweedCategoryVisible(item),
            setVisible: { settings.setTajweedCategory(item, visible: $0) },
            example: { TajweedLegendExamples.hafs(item) }
        )
    }

    private func basicRule(_ entry: QiraahTajweedStore.LegendEntry, tag: String) -> BasicRule {
        BasicRule(
            id: entry.id, color: entry.color,
            title: entry.english.localizedDisplay, subtitle: entry.arabic,
            arabic: nil,
            count: TajweedLegendExamples.countLabel(QiraahTajweedStore.shared.ruleWordCounts(for: tag)[entry.key]),
            detail: entry.shortDescription, letters: nil,
            visible: settings.isRiwayahTajweedRuleVisible(entry.key),
            setVisible: { settings.setRiwayahTajweedRule(entry.key, visible: $0) },
            example: { TajweedLegendExamples.riwayah(entry, tag: tag) }
        )
    }

    private struct CompactSection: Identifiable {
        let id: String
        let title: String?
        let rules: [BasicRule]
    }

    /// The Hafs rules under their four section names, or a riwayah's printed rules as one group.
    private var compactSections: [CompactSection] {
        if let tag = effectiveLegendTag {
            let rules = QiraahTajweedStore.shared.legend(for: tag).map { basicRule($0, tag: tag) }
            return [CompactSection(id: tag, title: nil, rules: rules)]
        }
        return sections.map { CompactSection(id: $0.id, title: $0.section.title, rules: $0.items.map(basicRule)) }
    }

    /// The default page: the switch, then every rule as a tile washed in its color, grouped by section,
    /// all of it on one screen (Abu, 2026-11-17: the expanding list "looks so chopped ... make it just
    /// be one screen no scrolling"). A tile opens a card with the rule's note, its letters, an example
    /// and show/hide; the long notes, custom colors, signs and riwayat are behind the toolbar's
    /// Detailed button. A screen too short for the grid (the medium detent, a large text size) scrolls
    /// rather than clips.
    private var compactLegend: some View {
        ViewThatFits(in: .vertical) {
            compactLegendContent
            ScrollView { compactLegendContent }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #if DEBUG
        // "-legendInspect <rule id>" opens that tile's card; "-legendDetailed" starts on the detailed
        // page. Headless screenshots only.
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-legendDetailed") { detailedBinding.wrappedValue = true }
            if let index = args.firstIndex(of: "-legendInspect"), args.indices.contains(index + 1) {
                let id = args[index + 1]
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { inspectedRule = id }
            }
        }
        #endif
    }

    private var compactLegendContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsToggle(String(localized: "Show Tajweed colors"),
                           caption: String(localized: "Tap a color to see what it means"),
                           isOn: tajweedColorsBinding)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentSurface(rectangle: true)

            if let tag = effectiveLegendTag {
                Text("The colors follow \(optionLabel(forTag: tag))'s printed mushaf: each word or letter is colored exactly where that print colors it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(compactSections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    if let title = section.title {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                            .accessibilityAddTraits(.isHeader)
                    }
                    compactGrid(section.rules)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    /// The master switch, mirrored onto every category so the tiles visibly go grey with it.
    /// `SettingsToggle` brings the haptic and the animation.
    private var tajweedColorsBinding: Binding<Bool> {
        Binding(
            get: { settings.showTajweedColors },
            set: { newValue in
                settings.showTajweedColors = newValue
                TajweedLegendCategory.allCases.forEach {
                    settings.setTajweedCategory($0, visible: newValue)
                }
            }
        )
    }

    /// Two tiles a row; a section with an odd count gives its last tile the whole row, so no row
    /// ends in a hole.
    private func compactGrid(_ rules: [BasicRule]) -> some View {
        let rows = stride(from: 0, to: rules.count, by: 2).map { Array(rules[$0 ..< min($0 + 2, rules.count)]) }
        return VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row) { compactTile($0) }
                }
                // Both tiles of a row as tall as the taller one.
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private static let compactTileShape = RoundedRectangle(cornerRadius: 14, style: .continuous)

    private func compactTile(_ rule: BasicRule) -> some View {
        let shape = Self.compactTileShape
        return Button {
            settings.hapticFeedback()
            inspectedRule = rule.id
        } label: {
            HStack(spacing: 8) {
                Group {
                    if rule.visible {
                        Circle().fill(rule.color)
                    } else {
                        Circle().strokeBorder(Color.secondary, lineWidth: 1.5)
                    }
                }
                .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 1) {
                    Text(rule.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(rule.visible ? Color.primary : Color.secondary)
                    Text(rule.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryOnGlass)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)

                Spacer(minLength: 0)

                if !rule.visible {
                    Image(systemName: "eye.slash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(shape.fill(rule.visible ? rule.color.opacity(0.14) : Color.primary.opacity(0.04)))
            .overlay(shape.strokeBorder(rule.visible ? rule.color.opacity(0.35) : Color.primary.opacity(0.1), lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(rule.visible ? "" : String(localized: "Hidden"))
        .accessibilityHint("Shows what the rule means")
        .popover(isPresented: inspectedBinding(rule.id)) {
            if #available(iOS 16.4, *) {
                compactRuleCard(rule)
                    .presentationCompactAdaptation(.popover)
            } else {
                // Pre-16.4 a popover adapts to a sheet on iPhone anyway: give it a sensible height.
                compactRuleCard(rule)
                    .smallMediumSheetPresentation()
            }
        }
    }

    private func inspectedBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { inspectedRule == id },
            set: { isPresented in
                if !isPresented, inspectedRule == id { inspectedRule = nil }
            }
        )
    }

    /// A tile's card: the rule's names, its count, what it does, the letters it takes, an example
    /// painted with only this rule, and its show/hide.
    private func compactRuleCard(_ rule: BasicRule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(rule.visible ? rule.color : Color.secondary.opacity(0.55))
                    .frame(width: 12, height: 12)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.title)
                        .font(.headline)
                    Text(rule.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let arabic = rule.arabic {
                        Text(arabic)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    // The count under the names, never beside them: beside, it squeezed the
                    // translation onto a second line.
                    if let count = rule.count {
                        Text(count)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(rule.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(rule.color.opacity(0.12)))
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.top, 4)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }

            if !rule.detail.isEmpty {
                Text(rule.detail)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let letters = rule.letters {
                Text(letters)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let example = rule.example() {
                example
            }

            Button {
                settings.hapticFeedback()
                withAnimation { rule.setVisible(!rule.visible) }
            } label: {
                Label(rule.visible ? "Hide This Color" : "Show This Color",
                      systemImage: rule.visible ? "eye.slash" : "eye")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(settings.accentColor.color)
            .conditionalGlassEffect(rectangle: true)
        }
        .padding(16)
        .frame(width: 330, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The toolbar's mode switch (`LegendModeButton`, shared with the Signs page).
    private var legendModeButton: some View {
        LegendModeButton(showsDetailed: isDetailed, toggle: detailedBinding)
    }

    /// The ordinary legend page: master toggle, preview card, the applicable legend, signs and
    /// stops - and, with qiraah details on, the full riwayat comparison always at the very bottom.
    @ViewBuilder
    private func fullLegendContent(scroll: ScrollViewProxy?) -> some View {
                masterToggleCard

                // With qiraah details on: preview ANY riwayah's color code from here, and a compare
                // mode that lays every riwayah's rules out one after another (user rule) - without
                // changing what is actually being read.
                if settings.showQiraahDetails {
                    riwayahPreviewCard
                }

                // Reading (or previewing) a non-Hafs riwayah: the ONLY legend that applies is that
                // riwayah's own printed color code - the Hafs rule guide would describe colors that
                // aren't on screen, so it stands down entirely here. Same page structure as
                // the Hafs legend: quick grid, show/hide all, then the detail cards.
                if let riwayahTag = effectiveLegendTag {
                    let entries = QiraahTajweedStore.shared.legend(for: riwayahTag)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Guide")
                            .font(.headline)

                        Text("The colors follow \(optionLabel(forTag: riwayahTag))'s printed mushaf: each word or letter is colored exactly where that print colors it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: quickLegendColumns, alignment: .leading, spacing: 10) {
                            ForEach(entries) { entry in
                                riwayahQuickCard(entry)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        riwayahVisibilityButton(title: String(localized: "Show All"), systemImage: "eye.fill",
                                                visible: true, entries: entries)
                        riwayahVisibilityButton(title: String(localized: "Hide All"), systemImage: "eye.slash.fill",
                                                visible: false, entries: entries)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        moreDetailHeader(colorKeys: entries.map(\.colorKey))

                        QiraahTajweedLegendView(tag: riwayahTag)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Guide")
                            .font(.headline)

                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section.section.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                LazyVGrid(columns: quickLegendColumns, alignment: .leading, spacing: 10) {
                                    ForEach(section.items) { item in
                                        quickItemCard(item)
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        visibilityButton(title: String(localized: "Show All"), systemImage: "eye.fill", visible: true)
                        visibilityButton(title: String(localized: "Hide All"), systemImage: "eye.slash.fill", visible: false)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        moreDetailHeader(colorKeys: TajweedLegendCategory.allCases.map { TajweedColorOverrides.key(for: $0) })

                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section.section.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                ForEach(section.items) { item in
                                    detailItemCard(item)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tip")
                            .font(.headline)

                        // The qiraat sentence only with riwayah/qiraah shown - with it hidden the
                        // legend never mentions qiraat at all (user rule).
                        Text(settings.showQiraahDetails
                             ? "This covers Tajweed rules for Hafs an Asim recitation, the most widely used qiraah. Other qiraat may apply these rules slightly differently."
                             : "This covers Tajweed rules for Hafs an Asim recitation, the most widely used way of reciting the Quran.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentSurface(rectangle: true, useColor: 0.1)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Mushaf Signs and Stops")
                        .font(.headline)

                    QuranSignsSectionContent(accentColor: settings.accentColor.color)
                }

                // The full riwayat comparison, ALWAYS at the very bottom with qiraah details on
                // (user rule) - the Compare All Riwayat button above exists to bring it to the top.
                if settings.showQiraahDetails {
                    compareAllSection(scroll: scroll)
                }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        TajweedLegendView()
    }
}
// MARK: - Legend UI

/// The legend for a riwayah's print-derived colors: the rules of the legend
/// box printed at the bottom of that mushaf, in the app's one rule order
/// (`QiraahTajweedStore.ruleOrder`) - as cards with the rule's names, a
/// one-liner, the longer note, and a show/hide toggle (mirrors the Hafs
/// legend's detail cards).
struct QiraahTajweedLegendView: View {
    private let settings = Settings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    let tag: String

    private var entries: [QiraahTajweedStore.LegendEntry] {
        QiraahTajweedStore.shared.legend(for: tag)
    }

    /// Words colored per rule (`QiraahTajweedStore.ruleWordCounts`), read once per body.
    private var counts: [String: Int] {
        QiraahTajweedStore.shared.ruleWordCounts(for: tag)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(entries) { entry in
                card(entry)
            }
        }
    }

    @ViewBuilder
    private func card(_ entry: QiraahTajweedStore.LegendEntry) -> some View {
        let visible = settings.isRiwayahTajweedRuleVisible(entry.key)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(entry.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.english.localizedDisplay)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(entry.arabic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                Label(visible ? "Hide" : "Show",
                      systemImage: visible ? "eye.fill" : "eye.slash.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(visible ? entry.color : .secondary)
            }

            // How many words the print colors with this rule, the Hafs cards' count line (Abu,
            // 2026-11-01: "mention the count of each riwayah").
            if let count = TajweedLegendExamples.countLabel(counts[entry.key]) {
                Text(count)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(entry.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Capsule(style: .continuous).fill(entry.color.opacity(0.15)))
            }

            if !entry.shortDescription.isEmpty {
                Text(entry.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !entry.longDescription.isEmpty {
                Text(entry.longDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let example = TajweedLegendExamples.riwayah(entry, tag: tag) {
                example
            }

            // A rule key means the same thing in every pack, so the pick follows the rule, not the
            // riwayah: the caption says so, because the change reaches past the legend on screen.
            TajweedRuleColorRow(
                colorKey: entry.colorKey,
                ruleName: entry.english.localizedDisplay,
                current: entry.color,
                customCaption: String(localized: "Your color, in every riwayah that marks this rule"),
                defaultCaption: String(localized: "The printed mushaf's color")
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation {
                settings.setRiwayahTajweedRule(entry.key, visible: !visible)
            }
        }
        .opacity(visible ? 1 : 0.45)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .contentSurface(rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(entry.color.opacity(0.2), lineWidth: 1)
        )
    }
}

/// The color control at the foot of a rule's long-description card: the ONLY place a tajweed rule's
/// color changes (Abu, 2026-09-20), for the Hafs categories and the riwayah rules alike.
///
/// The system picker reports every step of a drag across its spectrum. Each stored change republishes
/// Settings and sends both readers to repaint, so the pick is committed once the hand has rested
/// (`commitDelay`); the well itself follows the finger meanwhile.
struct TajweedRuleColorRow: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// `TajweedColorOverrides` key of the rule.
    let colorKey: String
    /// Names the rule for VoiceOver ("Color for Qalqalah").
    let ruleName: String
    /// The color the rule wears now, custom or canonical.
    let current: Color
    let customCaption: String
    let defaultCaption: String

    @State private var draft: Color?
    @State private var commit: Task<Void, Never>?

    private static let commitDelay: UInt64 = 250_000_000

    private var isCustom: Bool {
        // Read through Settings so the caption and Reset follow the stored string.
        let _ = settings.tajweedCustomColors
        return draft != nil || TajweedColorOverrides.shared.isCustomized(colorKey)
    }

    private var selection: Binding<Color> {
        Binding(
            get: { draft ?? current },
            set: { picked in
                draft = picked
                commit?.cancel()
                commit = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: Self.commitDelay)
                    guard !Task.isCancelled else { return }
                    settings.setTajweedCustomColor(picked.hexString, forKey: colorKey)
                    draft = nil
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Color")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(isCustom ? customCaption : defaultCaption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if isCustom {
                    Button {
                        settings.hapticFeedback()
                        commit?.cancel()
                        draft = nil
                        withAnimation { settings.setTajweedCustomColor(nil, forKey: colorKey) }
                    } label: {
                        Text("Reset")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(settings.accentColor.color)
                    .accessibilityLabel("Reset the color for \(ruleName)")
                }

                ColorPicker("Color for \(ruleName)", selection: selection, supportsOpacity: false)
                    .labelsHidden()
            }
        }
        // The card around this row toggles the rule on a tap; a near miss beside the color well must
        // not hide the rule the reader is busy recoloring.
        .contentShape(Rectangle())
        .onTapGesture {}
    }
}

// MARK: - Rule examples

/// A rule's example (Abu, 2026-11-01: "for all qiraat including hafs give an example in more detail
/// using Arabic font and everything"): one ayah in the reader's Quran face, the rule's letters in its
/// color and every other letter plain, under the ayah's reference. A Hafs rule has a fixed ayah
/// (`TajweedLegendCategory.exampleAyah`) painted by the engine with every rule visible; a riwayah rule
/// takes the earliest short ayah its print colors with it (`QiraahTajweedStore.exampleAyah`).
struct TajweedRuleExample: View {
    /// "Al-Fatihah 1:2".
    let reference: String
    let text: String
    let styled: AttributedString?
    let fontName: String
    var size: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Example: \(reference)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            HighlightedSnippet(
                source: text,
                term: "",
                font: Font.arabic(fontName, size: size),
                accent: Settings.shared.accentColor.color,
                fg: .primary,
                preStyledSource: styled,
                lineLimit: nil
            )
            .arabicFontDesign(custom: fontName != Settings.systemArabicFontName)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
            .environment(\.layoutDirection, .leftToRight)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Builds the legend's example blocks; both legends (Hafs and a riwayah's) call it.
enum TajweedLegendExamples {
    /// The surah's name and the reference, "Al-Fatihah 1:2".
    static func reference(surah: Int, ayah: Int) -> String {
        let name = QuranData.shared.surah(surah)?.displayName ?? "\(surah)"
        return "\(name) \(surah):\(ayah)".localizedDigits
    }

    /// The Hafs rule's example, in the Hafs text whatever riwayah is being read.
    static func hafs(_ item: TajweedLegendCategory) -> TajweedRuleExample? {
        let place = item.exampleAyah
        guard let ayah = QuranData.shared.ayah(surah: place.surah, ayah: place.ayah) else { return nil }
        let text = ayah.rawArabicText(surahId: place.surah, qiraahOverride: Settings.Riwayah.hafsTag)
        guard !text.isEmpty else { return nil }
        let styled = TajweedStore.legendExamples.exampleText(surah: place.surah, ayah: place.ayah, text: text, category: item)
        return TajweedRuleExample(
            reference: reference(surah: place.surah, ayah: place.ayah),
            text: text,
            styled: styled,
            fontName: Settings.shared.quranArabicFontName(for: nil)
        )
    }

    /// The riwayah rule's example: its own text, only this rule colored (every other rule of the
    /// print hidden for the paint).
    static func riwayah(_ entry: QiraahTajweedStore.LegendEntry, tag: String) -> TajweedRuleExample? {
        let store = QiraahTajweedStore.shared
        guard let example = store.exampleAyah(tag: tag, ruleKey: entry.key) else { return nil }
        let hidden = Set(store.legend(for: tag).map(\.key)).subtracting([entry.key])
        let styled = store.attributedText(tag: tag, surah: example.surah, ayah: example.ayah,
                                          displayText: example.text, hiddenRules: hidden)
        return TajweedRuleExample(
            reference: reference(surah: example.surah, ayah: example.ayah),
            text: example.text,
            styled: styled,
            fontName: Settings.shared.quranArabicFontName(for: tag)
        )
    }

    /// Paints every example of the legend on screen off the main thread, so a card or a row opens
    /// with its example ready instead of running the engine in its body. Hafs when `tag` is nil.
    static func prewarm(tag: String?) {
        Task.detached(priority: .utility) {
            if let tag {
                for entry in QiraahTajweedStore.shared.legend(for: tag) { _ = riwayah(entry, tag: tag) }
                _ = QiraahTajweedStore.shared.ruleWordCounts(for: tag)
            } else {
                for item in TajweedLegendCategory.allCases { _ = hafs(item) }
            }
        }
    }

    /// "1,544 words": how many words of the riwayah's text the print colors with the rule.
    static func countLabel(_ count: Int?) -> String? {
        guard let count else { return nil }
        return String(localized: "\(count) words").localizedDigits
    }
}

// MARK: - Stop signs

/// The legends' toolbar switch between the one-screen tiles and the detailed page: the book on the
/// tiles (open the details), the grid on the details (back to the tiles). The tajweed and the Signs
/// pages share it, so the two read as one legend.
struct LegendModeButton: View {
    let showsDetailed: Bool
    let action: () -> Void

    init(showsDetailed: Bool, action: @escaping () -> Void) {
        self.showsDetailed = showsDetailed
        self.action = action
    }

    /// The button over the page's own switch: each page drops its open card and whatever only the
    /// other form shows when the value changes, so the sheet that hosts a page can flip it too.
    init(showsDetailed: Bool, toggle: Binding<Bool>) {
        self.init(showsDetailed: showsDetailed) {
            withAnimation(.easeInOut(duration: 0.2)) { toggle.wrappedValue.toggle() }
        }
    }

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            Image(systemName: showsDetailed ? "square.grid.2x2" : "text.book.closed")
                .font(.body.weight(.semibold))
        }
        .tint(Settings.shared.accentColor.color)
        .accessibilityLabel(showsDetailed ? "Compact Legend" : "Detailed Legend")
    }
}

extension StopSignInfo {
    /// The example's words out of the app's Hafs text, whatever riwayah is being read, with the sign
    /// that text does not carry added where the example asks (`Example.addsMark`, `endsWithNumber`);
    /// nil without an example or before the Quran has loaded.
    var examplePhrase: String? {
        guard let place = example,
              let ayah = QuranData.shared.ayah(surah: place.surah, ayah: place.ayah) else { return nil }
        let tokens = WordTokens.tokens(in: ayah.rawArabicText(surahId: place.surah, qiraahOverride: Settings.Riwayah.hafsTag))
        guard tokens.indices.contains(place.words.lowerBound), tokens.indices.contains(place.words.upperBound) else { return nil }
        var words = Array(tokens[place.words])
        if let added = place.addsMark, place.words.contains(added.word), let scalar = Unicode.Scalar(added.scalar) {
            words[added.word - place.words.lowerBound].unicodeScalars.append(scalar)
        }
        if place.endsWithNumber { words.append(arabicNumberString(from: place.ayah)) }
        return words.joined(separator: " ")
    }
}

/// The reader Legend's third page (Abu, 2026-11-01: "add a third tajweed legend, stopping signs"): the
/// mushaf's stop and pause signs. Since 2026-11-17 it is built like the tajweed page (Abu: "make stop
/// signs similar too like prettier"): one screen of tiles, each opening a card with what the sign asks
/// and a place the Hafs mushaf prints it, and the toolbar's Detailed button for every card at once. The
/// signs are printed in every riwayah's text, so unlike the two color codes this page is never "off".
///
/// 2026-11-18 (Abu: "signs is way too small, we can make it way bigger and better ... give examples
/// for each"): the tiles are a grid that fills the screen, the sign large over its name, and every
/// sign has an example.
struct QuranStopSignsLegendView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared

    /// Every card at once instead of the tiles. Every open starts on the tiles, as the tajweed page does.
    @State private var showsDetailed = false
    /// The reader's legend sheet holds the switch and draws its button (see `TajweedLegendView.init`).
    private let hostedDetailed: Binding<Bool>?
    /// The tile whose card is up, by sign key.
    @State private var inspectedSign: String?

    init(detailed: Binding<Bool>? = nil) {
        hostedDetailed = detailed
    }

    private var detailedBinding: Binding<Bool> { hostedDetailed ?? $showsDetailed }
    private var isDetailed: Bool { detailedBinding.wrappedValue }

    private struct SignSection: Identifiable {
        let id: String
        let title: String
        let signs: [StopSignInfo]

        /// Two tiles a row.
        var rows: [SignRow] {
            stride(from: 0, to: signs.count, by: 2).map { SignRow(signs: Array(signs[$0 ..< min($0 + 2, signs.count)])) }
        }
    }

    private struct SignRow: Identifiable {
        let signs: [StopSignInfo]
        var id: String { signs.first?.key ?? "" }
    }

    /// Whether to stop, then the pause and the marks that are not stops (`StopSignInfo.all`'s order).
    private static let sections: [SignSection] = [
        SignSection(id: "stop", title: String(localized: "Stop or Read On"), signs: Array(StopSignInfo.all.prefix(6))),
        SignSection(id: "marks", title: String(localized: "Pauses and Other Marks"), signs: Array(StopSignInfo.all.dropFirst(6))),
    ]

    private static let tileShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    private var accent: Color { settings.accentColor.color }

    var body: some View {
        Group {
            if isDetailed {
                detailedSigns
            } else {
                compactSigns
            }
        }
        .sheetNowPlayingBar()
        .accentWashedBackground()
        .navigationTitle("Signs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // In the reader's legend sheet the sheet draws the switch, the same on its three pages.
            if hostedDetailed == nil {
                ToolbarItem(placement: .primaryAction) {
                    LegendModeButton(showsDetailed: isDetailed, toggle: detailedBinding)
                }
            }
        }
        .onChange(of: isDetailed) { _ in inspectedSign = nil }
        #if DEBUG
        // "-signsInspect <sign key>" opens that tile's card; "-signsDetailed" starts on the detailed
        // page. Headless screenshots only.
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-signsDetailed") { detailedBinding.wrappedValue = true }
            if let index = args.firstIndex(of: "-signsInspect"), args.indices.contains(index + 1) {
                let key = args[index + 1]
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { inspectedSign = key }
            }
        }
        #endif
    }

    // MARK: Tiles

    /// The default page: every sign as a tile, all on one screen, the rows sharing whatever height the
    /// screen has so the grid fills it; a screen too short for it (the medium detent, a large text
    /// size) scrolls rather than clips.
    private var compactSigns: some View {
        ViewThatFits(in: .vertical) {
            compactContent(fillsScreen: true)
            ScrollView { compactContent(fillsScreen: false) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// A tile is never shorter than its sign, name and gist need; on one screen it grows up to this.
    private static let tileMaxHeight: CGFloat = 132

    /// One flat column (lead, heading, rows, heading, rows), so the five rows share the spare height
    /// equally: grouped by section, the section of two rows would get as much of it as the one of three.
    private func compactContent(fillsScreen: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            lead

            ForEach(Self.sections) { section in
                sectionHeader(section.title)
                    .padding(.top, 6)

                ForEach(section.rows) { row in
                    HStack(spacing: 8) {
                        ForEach(row.signs) { tile($0) }
                    }
                    // On one screen a row takes its share of the height; scrolling, its own, and
                    // either way both tiles of a row are as tall as the taller.
                    .frame(maxHeight: fillsScreen ? Self.tileMaxHeight : nil)
                    .fixedSize(horizontal: false, vertical: !fillsScreen)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    /// The page's lead, in the glass card the tajweed page gives its switch: what to do here, and the
    /// door to the waqf lesson where the tajweed card has its toggle.
    private var lead: some View {
        HStack(spacing: 12) {
            leadIcon

            VStack(alignment: .leading, spacing: 2) {
                Text("Stop Signs")
                    .font(.subheadline.weight(.semibold))
                Text("Tap a sign to see what it asks")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryOnGlass)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            NavigationLink {
                TajweedWaqfView()
            } label: {
                HStack(spacing: 3) {
                    Text("Learn")
                    Image(systemName: "chevron.forward")
                        .font(.caption2.weight(.bold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(accent.opacity(0.14)))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Learn About Waqf")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentSurface(rectangle: true)
    }

    private var leadIcon: some View {
        Image(systemName: "hand.raised.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(accent)
            .frame(width: 32, height: 32)
            .background(Circle().fill(accent.opacity(0.14)))
            .accessibilityHidden(true)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
    }

    /// A grid tile: the sign large on its own plate, which takes whatever height the row has to
    /// spare, over the sign's name and what it asks in a few words.
    private func tile(_ sign: StopSignInfo) -> some View {
        let shape = Self.tileShape
        return Button {
            settings.hapticFeedback()
            inspectedSign = sign.key
        } label: {
            VStack(spacing: 5) {
                GeometryReader { plate in
                    glyph(sign, size: min(max(plate.size.height * 0.68, 24), 46), fallback: .title.weight(.semibold))
                        .frame(width: plate.size.width, height: plate.size.height)
                }
                .frame(minHeight: 40)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(accent.opacity(0.14)))

                VStack(spacing: 1) {
                    Text(sign.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(sign.gist)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryOnGlass)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 2)
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shape.fill(accent.opacity(0.08)))
            .overlay(shape.strokeBorder(accent.opacity(0.25), lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows what the sign means")
        .popover(isPresented: inspectedBinding(sign.key)) {
            if #available(iOS 16.4, *) {
                signCard(sign)
                    .presentationCompactAdaptation(.popover)
            } else {
                // Pre-16.4 a popover adapts to a sheet on iPhone anyway: give it a sensible height.
                signCard(sign)
                    .smallMediumSheetPresentation()
            }
        }
    }

    private func inspectedBinding(_ key: String) -> Binding<Bool> {
        Binding(
            get: { inspectedSign == key },
            set: { isPresented in
                if !isPresented, inspectedSign == key { inspectedSign = nil }
            }
        )
    }

    /// The Quran face draws these well under the letters' size (they sit over and between words), so
    /// beside ج and صلى they read as specks without a lift.
    private static let glyphScale: [String: CGFloat] = ["mandatory": 1.35, "stopAtOne": 1.3, "ayahEnd": 1.15, "sujood": 1.9, "hizb": 1.9]

    /// The sign in the Quran's own face (SF draws قلى as a word, not the mushaf's ligature), in the
    /// accent. At its own size whatever frame it is centered in: the Quran face's line is nearly twice
    /// its letters' height, so a sign fitted into a plate or a badge would shrink to make room for air.
    /// A fixed size, since the plate and the badge it sits on are sized by the layout, not by the text size.
    private func glyph(_ sign: StopSignInfo, size: CGFloat, fallback: Font) -> some View {
        let quranFace = settings.quranDisplayUsesCustomArabicFace
        let fontName = settings.quranDisplayFontName
        let scaled = size * (Self.glyphScale[sign.key] ?? 1)
        return Text(sign.symbol)
            .font(quranFace ? Font.custom(fontName, fixedSize: scaled) : fallback)
            .arabicFontDesign(custom: quranFace)
            .foregroundStyle(accent)
            .lineLimit(1)
            .fixedSize()
            .offset(y: quranFace ? Self.inkLift(sign.symbol, fontName: fontName) * scaled : 0)
            // The title says it; VoiceOver would spell the glyph's letters.
            .accessibilityHidden(true)
    }

    private static var inkLifts: [String: CGFloat] = [:]

    /// How far to move a line of `text` so its INK sits in the middle of its frame, per point of font
    /// size (down is positive). A centered Text centers its line box, and in the Quran face the ink
    /// is nowhere near the middle of that: ج and قلى hang off the baseline and touched the bottom of
    /// their plate while لا floated in the middle of its own.
    private static func inkLift(_ text: String, fontName: String) -> CGFloat {
        let key = fontName + "|" + text
        if let known = inkLifts[key] { return known }
        var lift: CGFloat = 0
        let reference: CGFloat = 100
        if let font = UIFont(name: fontName, size: reference) {
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
            let ink = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
            if !ink.isNull, ink.height > 0 {
                // Both measured up from the baseline: the middle of the ink, the middle of the line box.
                lift = (ink.midY - (font.ascender + font.descender) / 2) / reference
            }
        }
        inkLifts[key] = lift
        return lift
    }

    /// The sign on an accent square, for the cards.
    private func badge(_ sign: StopSignInfo, glyphSize: CGFloat, fallback: Font, side: CGFloat) -> some View {
        glyph(sign, size: glyphSize, fallback: fallback)
            .frame(width: side, height: side)
            .background(RoundedRectangle(cornerRadius: side * 0.28, style: .continuous).fill(accent.opacity(0.14)))
    }

    // MARK: Card

    /// A tile's card: the popover on the tiles, one row each on the detailed page.
    /// Scrolls where the screen has less room beside the tile than the card is tall (a long note
    /// under a two-line example, a large text size): a popover clips what does not fit, top and bottom.
    private func signCard(_ sign: StopSignInfo) -> some View {
        let card = signDetail(sign)
            .padding(16)
            .frame(width: 340, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        return ViewThatFits(in: .vertical) {
            card
            ScrollView { card }
        }
    }

    /// The sign's names, what it asks, and a place the Hafs mushaf prints it.
    private func signDetail(_ sign: StopSignInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                badge(sign, glyphSize: 36, fallback: .title.weight(.semibold), side: 68)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sign.title)
                        .font(.title3.weight(.semibold))
                    // In Arabic and Urdu the title already is the Arabic term.
                    if !AppLanguage.isArabicScript {
                        if let arabic = sign.arabicName {
                            Text(arabic)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let transliteration = sign.transliteration {
                            Text(verbatim: transliteration)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }

            Text(sign.meaning)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            if let example = example(for: sign) {
                example
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.04)))

                if let note = sign.example?.note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// The example block: the words in the Hafs face, each word carrying the sign in the accent.
    private func example(for sign: StopSignInfo) -> TajweedRuleExample? {
        guard let place = sign.example, let phrase = sign.examplePhrase else { return nil }
        // The whole word that carries the sign, not the sign alone: a mark draws in its letter's color
        // (a lone accent ۛ came out white), and the word is the place the reciter stops or reads on.
        // In the UIKit scope over a label-colored base, as the tajweed painter writes its colors.
        let painted = NSMutableAttributedString(string: phrase, attributes: [.foregroundColor: UIColor.label])
        let units = phrase as NSString
        let accentColor = UIColor(accent)
        for range in WordTokens.ranges(in: phrase) {
            let carriesSign = (range.location ..< NSMaxRange(range)).contains { sign.marks.contains(UInt32(units.character(at: $0))) }
            if carriesSign { painted.addAttribute(.foregroundColor, value: accentColor, range: range) }
        }
        let styled = (try? AttributedString(painted, including: \.uiKit)) ?? AttributedString(phrase)
        return TajweedRuleExample(
            reference: TajweedLegendExamples.reference(surah: place.surah, ayah: place.ayah),
            text: phrase,
            styled: styled,
            fontName: settings.quranArabicFontName(for: nil),
            size: 28
        )
    }

    // MARK: Detailed

    /// Every card at once, under the same two headings, for reading the whole guide through.
    private var detailedSigns: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                detailedLead

                ForEach(Self.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(section.title)
                        ForEach(section.signs) { sign in
                            signDetail(sign)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Self.tileShape.fill(accent.opacity(0.06)))
                                .overlay(Self.tileShape.strokeBorder(accent.opacity(0.18), lineWidth: 1))
                        }
                    }
                }

                learnButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
    }

    /// The detailed page's lead: what the signs are for, in the same glass card.
    private var detailedLead: some View {
        HStack(spacing: 12) {
            leadIcon

            VStack(alignment: .leading, spacing: 2) {
                Text("Stop Signs")
                    .font(.subheadline.weight(.semibold))
                Text("The small signs over the words say where a reciter may stop, must stop, or must read on.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryOnGlass)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentSurface(rectangle: true)
    }

    private var learnButton: some View {
        NavigationLink {
            TajweedWaqfView()
        } label: {
            Label("Learn About Waqf", systemImage: "text.book.closed")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(accent)
        .conditionalGlassEffect(rectangle: true)
    }
}

#endif
