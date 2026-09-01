#if os(iOS)
import SwiftUI

struct TajweedLegendView: View {
    @ObservedObject var settings = Settings.shared
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

    /// Every riwayah that ships a print-derived color pack - a cheap static check (`fileName`, no pack
    /// load), so building the picker menu never parses 19 packs.
    nonisolated private static let packOptions: [Settings.Riwayah.Option] = Settings.Riwayah.allOptions.filter {
        QiraahTajweedStore.fileName(for: $0.tag) != nil
    }

    /// The legend the page leads with: the previewed riwayah when one is picked (nil = the Hafs guide),
    /// else whatever is actually displayed.
    private var effectiveLegendTag: String? {
        guard let previewTag else { return currentRiwayahLegendTag }
        let canonical = Settings.Riwayah.canonicalTag(previewTag)
        return canonical == Settings.Riwayah.canonicalTag(Settings.Riwayah.hafsTag) ? nil : previewTag
    }

    private func optionLabel(forTag tag: String) -> String {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        return Settings.Riwayah.allOptions
            .first { Settings.Riwayah.canonicalTag($0.tag) == canonical }?
            .label ?? tag
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
                    legendLine(entry.english)
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

            Label(visible ? "Hide" : "Show", systemImage: visible ? "eye.fill" : "eye.slash.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(visible ? entry.color : .secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
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
        .conditionalGlassEffect(rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(entry.color.opacity(0.35), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func countBadge(_ item: TajweedLegendCategory) -> some View {
        if let count = item.countLabel {
            Text(count)
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
        .conditionalGlassEffect(rectangle: true)
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
                        selectionLabel(Settings.Riwayah.hafsLabel, tag: Settings.Riwayah.hafsTag)
                    }

                    // The same nested grammar as the riwayah picker everywhere else: one submenu
                    // per qiraah, each opening its two riwayat - not a flat list of all twenty.
                    ForEach(Settings.Riwayah.groups) { group in
                        Menu {
                            ForEach(group.options, id: \.tag) { option in
                                Button {
                                    settings.hapticFeedback()
                                    withAnimation { previewTag = option.tag }
                                } label: {
                                    selectionLabel(option.label, tag: option.tag)
                                }
                            }
                        } label: {
                            Label(
                                "\(group.teacher) - \(group.teacherArabic)",
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
                } label: {
                    HStack(spacing: 5) {
                        Text(previewTag.map { optionLabel(forTag: $0) }
                             ?? "\(optionLabel(forTag: currentRiwayahLegendTag ?? Settings.Riwayah.hafsTag)) (reading)")
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
        .conditionalGlassEffect(rectangle: true)
    }

    /// A menu row for one riwayah, checkmarked when it is the previewed one.
    private func selectionLabel(_ title: String, tag: String) -> some View {
        let selected = previewTag.map {
            Settings.Riwayah.canonicalTag($0) == Settings.Riwayah.canonicalTag(tag)
        } ?? false
        return Label(title, systemImage: selected ? "checkmark" : "character.book.closed.fill.ar")
    }

    /// The compare mode: every riwayah's printed color code, groupable two ways. By qiraah (default):
    /// one compact card per riwayah under its qiraah's section header - Hafs an Asim's section always
    /// first with its engine rules on top, the other qiraat alphabetical. By rule: one section per
    /// print-derived rule, listing which riwayat mark it (Hafs first where its own legend colors an
    /// equivalent, the rest alphabetical). LazyVStack, so by-qiraah cards only parse their pack when
    /// scrolled into view; the by-rule index is built once, off the main thread.
    private func compareAllSection(scroll: ScrollViewProxy?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Riwayat Compared")
                .font(.headline)

            Text("Each riwayah's mushaf prints its own color code. The same rule keeps the same meaning everywhere; what changes is which rules that riwayah marks.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Group By", selection: $compareByRule.animation(.easeInOut)) {
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
                    Text("\(group.teacher.uppercased()) - \(group.teacherArabic)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if group.includesHafs {
                        compareCardShell(
                            title: Settings.Riwayah.hafsLabel,
                            arabic: Settings.Riwayah.hafsArabic
                        ) {
                            ForEach(TajweedLegendCategory.allCases.sorted { $0.sortRank < $1.sortRank }) { item in
                                compareRuleRow(color: item.color, english: item.transliteration)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { previewRiwayah(tag: Settings.Riwayah.hafsTag, scroll: scroll) }
                    }

                    ForEach(group.options, id: \.tag) { option in
                        compareCardShell(title: option.label, arabic: option.arabic) {
                            ForEach(QiraahTajweedStore.shared.legend(for: option.tag)) { entry in
                                compareRuleRow(color: entry.color, english: entry.english)
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
                            Text(section.english)
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
                                compareRuleRow(color: row.color, english: row.title)
                                    .contentShape(Rectangle())
                                    .onTapGesture { previewRiwayah(tag: row.tag, scroll: scroll) }
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .conditionalGlassEffect(rectangle: true)
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
    /// riwayah does. The per-riwayah cards still show each print's own wording.
    nonisolated private static let compareRuleAliases: [String: String] = ["khilaf_word": "khilaf_harf"]

    /// Titles and descriptions for a folded section, so it isn't named after whichever print sorted first.
    nonisolated private static let compareRuleOverrides: [String: (english: String, arabic: String, description: String)] = [
        "khilaf_harf": (
            "Differing from Ḥafṣ",
            "المخالف لحفص",
            "Read differently from the Ḥafṣ an ʿĀṣim reading. Every riwayah marks this."
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
            for entry in QiraahTajweedStore.shared.legend(for: option.tag) {
                let key = compareRuleAliases[entry.key] ?? entry.key
                var collected = byKey[key] ?? Collected(english: entry.english, arabic: entry.arabic)
                collected.rows.append(CompareRuleRowItem(
                    id: "\(key)-\(option.tag)",
                    color: entry.color,
                    title: option.label,
                    tag: option.tag
                ))
                collected.note(caption: entry.english, label: option.label)
                byKey[key] = collected
            }
        }

        return byKey
            .map { key, collected -> CompareRuleSection in
                let hafsRows = (hafsColoredCounterparts[key] ?? []).map { category in
                    CompareRuleRowItem(
                        id: "\(key)-hafs-\(category.rawValue)",
                        color: category.color,
                        title: "\(Settings.Riwayah.hafsLabel) - \(category.transliteration)",
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
            .sorted { $0.english < $1.english }
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
            .map { "“\($0.english)” in \(ListFormatter.localizedString(byJoining: $0.labels))" }
        guard !others.isEmpty else { return "" }
        return "The prints caption it differently: \(others.joined(separator: "; ")); “\(majority.english)” in the rest."
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
        .conditionalGlassEffect(rectangle: true)
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

    private func compareRuleRow(color: Color, english: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(english)
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

            Text(item.englishMeaning)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(item.longDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
        .conditionalGlassEffect(rectangle: true)
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
        .accentWashedBackground()
        .navigationTitle("Legend")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if showsDismissButton {
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
        }
    }

    /// The ordinary legend page: master toggle, preview card, the applicable legend, signs and
    /// stops - and, with qiraah details on, the full riwayat comparison always at the very bottom.
    @ViewBuilder
    private func fullLegendContent(scroll: ScrollViewProxy?) -> some View {
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

                    Text("If you turn it off, go to Quran Settings → Arabic Text to turn it back on")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .conditionalGlassEffect(rectangle: true)

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

                        Text("The colors follow \(optionLabel(forTag: riwayahTag))'s printed mushaf - each word or letter is colored exactly where that print colors it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: quickLegendColumns, alignment: .leading, spacing: 10) {
                            ForEach(entries) { entry in
                                riwayahQuickCard(entry)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        riwayahVisibilityButton(title: "Show All", systemImage: "eye.fill",
                                                visible: true, entries: entries)
                        riwayahVisibilityButton(title: "Hide All", systemImage: "eye.slash.fill",
                                                visible: false, entries: entries)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("More Detail")
                            .font(.headline)

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
                        visibilityButton(title: "Show All", systemImage: "eye.fill", visible: true)
                        visibilityButton(title: "Hide All", systemImage: "eye.slash.fill", visible: false)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("More Detail")
                            .font(.headline)

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
                            .conditionalGlassEffect(rectangle: true, useColor: 0.1)
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

/// The legend for a riwayah's print-derived colors: the same rules, in the
/// same order, as the legend box printed at the bottom of that mushaf - as
/// cards with the rule's names, a one-liner, the longer note, and a
/// show/hide toggle (mirrors the Hafs legend's detail cards).
struct QiraahTajweedLegendView: View {
    @ObservedObject private var settings = Settings.shared
    let tag: String

    private var entries: [QiraahTajweedStore.LegendEntry] {
        QiraahTajweedStore.shared.legend(for: tag)
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
                    Text(entry.english)
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
        .conditionalGlassEffect(rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(entry.color.opacity(0.2), lineWidth: 1)
        )
    }
}

#endif
