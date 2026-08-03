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
                        Text("Turn Tajweed colors on or off")
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)

                    Text("Go to Quran Settings → Arabic Text to turn it back on")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .conditionalGlassEffect(rectangle: true)

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
#endif
