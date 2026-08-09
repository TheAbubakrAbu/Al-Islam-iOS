#if os(iOS)
import SwiftUI

struct TajweedLegendView: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.presentationMode) private var presentationMode

    var showsDismissButton = true

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tajweed Legend")
                        .font(.title3.weight(.semibold))

                    Text("Use the colors as a quick guide, then read the longer notes below for what each rule is doing in recitation.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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

                // Reading a non-Hafs riwayah: the ONLY legend that applies is that riwayah's
                // own printed color code - the Hafs rule guide would describe colors that
                // aren't on screen, so it stands down entirely here. Same page structure as
                // the Hafs legend: quick grid, show/hide all, then the detail cards.
                if let riwayahTag = currentRiwayahLegendTag {
                    let entries = QiraahTajweedStore.shared.legend(for: riwayahTag)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Guide")
                            .font(.headline)

                        Text("The colors follow this riwayah's printed mushaf (\(riwayahTag)) - each word or letter is colored exactly where that print colors it.")
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
