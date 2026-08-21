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

    /// Every riwayah that ships a print-derived color pack - a cheap static check (`fileName`, no pack
    /// load), so building the picker menu never parses 19 packs.
    private static let packOptions: [Settings.Riwayah.Option] = Settings.Riwayah.allOptions.filter {
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
                Label(compareAll ? "Show Full Legend" : "Compare All Riwayat",
                      systemImage: compareAll ? "rectangle.stack.fill" : "rectangle.stack")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(settings.accentColor.color)
            .conditionalGlassEffect(rectangle: true)
            .contentShape(Rectangle())
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

    /// The compare mode: every riwayah's printed color code, one compact card each - Hafs's engine rules
    /// first, then the 19 print-derived packs. LazyVStack, so a pack is only parsed when its card scrolls
    /// into view rather than all 19 up front.
    private var compareAllSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Riwayat Compared")
                .font(.headline)

            Text("Each riwayah's mushaf prints its own color code. The same rule keeps the same meaning everywhere; what changes is which rules that riwayah marks.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVStack(alignment: .leading, spacing: 10) {
                compareCardShell(
                    title: Settings.Riwayah.hafsLabel,
                    arabic: Settings.Riwayah.hafsArabic
                ) {
                    ForEach(TajweedLegendCategory.allCases.sorted { $0.sortRank < $1.sortRank }) { item in
                        compareRuleRow(color: item.color, english: item.transliteration)
                    }
                }

                ForEach(Self.packOptions, id: \.tag) { option in
                    compareCardShell(title: option.label, arabic: option.arabic) {
                        ForEach(QiraahTajweedStore.shared.legend(for: option.tag)) { entry in
                            compareRuleRow(color: entry.color, english: entry.english)
                        }
                    }
                }
            }
        }
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

    var body: some View {
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

                if compareOnlyMode {
                    // ONLY the comparison (plus the card holding the way back): clicking Compare All
                    // Riwayat brings the riwayat to the top instead of burying them under the legend.
                    riwayahPreviewCard

                    compareAllSection
                } else {
                    fullLegendContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 28)
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
    private var fullLegendContent: some View {
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

                        Text("This covers Tajweed rules for Hafs an Asim recitation, the most widely used qiraah. Other qiraat may apply these rules slightly differently.")
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
                    compareAllSection
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
