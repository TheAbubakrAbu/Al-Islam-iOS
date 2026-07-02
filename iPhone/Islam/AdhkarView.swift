import SwiftUI

struct CommonDhikr: Identifiable {
    let arabicText: String
    let transliteration: String
    let translation: String
    let searchBlob: String

    var id: String { transliteration }

    init(arabicText: String, transliteration: String, translation: String) {
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.searchBlob = Self.searchBlob(arabicText: arabicText, transliteration: transliteration, translation: translation)
    }

    private static func searchBlob(arabicText: String, transliteration: String, translation: String) -> String {
        [arabicText, transliteration, translation]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

let commonDhikrItems: [CommonDhikr] = [
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ", transliteration: "SubhanAllah", translation: "Glory be to Allah"),
    CommonDhikr(arabicText: "ٱلحَمدُ لِلَّهِ", transliteration: "Alhamdulillah", translation: "Praise be to Allah"),
    CommonDhikr(arabicText: "اللَّهُ أَكبَرُ", transliteration: "Allahu Akbar", translation: "Allah is the Greatest"),
    CommonDhikr(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ", transliteration: "La ilaha illallah", translation: "There is no deity worthy of worship except Allah"),
    CommonDhikr(arabicText: "أَستَغفِرُ اللَّهَ", transliteration: "Astaghfirullah", translation: "I seek forgiveness from Allah"),
    CommonDhikr(arabicText: "لَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wala quwwata illa billah", translation: "There is no power or might except with Allah"),
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ سُبحَانَ اللَّهِ العَظِيمِ", transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil Adheem", translation: "Glory be to Allah and praise be to Him; Glory be to Allah, the Most Great"),
    CommonDhikr(arabicText: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ", transliteration: "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad", translation: "O Allah, send blessings upon Muhammad and his family"),
    CommonDhikr(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحدَهُ لَا شَرِيكَ لَهُ لَهُ ٱلمُلكُ وَلَهُ ٱلحَمدُ وَهُوَ عَلَىٰ كُلِّ شَيءٍ قَدِيرٌ", transliteration: "La ilaha illallah wahdahu la sharika lah, lahul-mulk wa lahul-hamd, wa huwa 'ala kulli shayin qadir", translation: "There is no deity worthy of worship except Allah, alone, without any partner. His is the sovereignty and His is the praise, and He is capable of all things")
]

struct AdhkarRow: View {
    @EnvironmentObject var settings: Settings

    let arabicText: String
    let transliteration: String
    let translation: String
    var alignArabicTrailing: Bool = false
    var useQuranicFont: Bool = false
    var searchQuery: String = ""

    var body: some View {
        Section {
            rowContent
        }
    }

    private var rowContent: some View {
        // Guarantee a highlight only on the field(s) that actually contain the query (folded the same way the
        // dhikr search itself matches), so a match in one field doesn't force-color the other two.
        let normalizedQuery = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        func matches(_ field: String) -> Bool {
            guard !normalizedQuery.isEmpty else { return false }
            return field.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).contains(normalizedQuery)
        }
        return VStack(alignment: .leading, spacing: 10) {
            HighlightedSnippet(
                source: arabicText,
                term: searchQuery,
                font: useQuranicFont ? .custom(settings.fontArabic, size: 30) : .title2,
                accent: settings.accentColor.color,
                fg: settings.accentColor.color,
                guaranteeMatch: matches(arabicText)
            )
                .multilineTextAlignment(alignArabicTrailing ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: alignArabicTrailing ? .trailing : .leading)
                .padding(.vertical, useQuranicFont ? -8 : 0)

            HighlightedSnippet(
                source: transliteration,
                term: searchQuery,
                font: .subheadline,
                accent: settings.accentColor.color,
                fg: .primary,
                guaranteeMatch: matches(transliteration)
            )

            HighlightedSnippet(
                source: translation,
                term: searchQuery,
                font: .subheadline,
                accent: settings.accentColor.color,
                fg: .secondary,
                guaranteeMatch: matches(translation)
            )
        }
        .padding(.vertical, 4)
        #if os(iOS)
        .contextMenu {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = arabicText
            } label: {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = transliteration
            } label: {
                Label("Copy Transliteration", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = translation
            } label: {
                Label("Copy Translation", systemImage: "doc.on.doc")
            }
        }
        #endif
    }
}

struct AdhkarView: View {
    @EnvironmentObject var settings: Settings
    @State private var searchText = ""

    var body: some View {
        List {
            Group {
                introductionSection
                adhkarRows
                etymologySection
                virtuesSection
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
                    Text("Quranic Font").tag(true)
                    Text("Basic Font").tag(false)
                }
                .pickerStyle(.segmented)
                // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
                .conditionalGlassEffect(interactive: false)
                .onChange(of: settings.useFontArabic) { _ in settings.hapticFeedback() }

                SearchBar(text: $searchText.animation(.easeInOut))
                    .padding([.horizontal, .top], -8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #elseif os(watchOS)
        .searchable(text: $searchText.animation(.easeInOut))
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("Dhikr & Remembrances")
    }

    private func matchesSearch(_ dhikr: CommonDhikr) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let normalizedQuery = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return dhikr.searchBlob.contains(normalizedQuery)
    }

    @ViewBuilder
    private func filteredAdhkarRow(_ dhikr: CommonDhikr, alignArabicTrailing: Bool = false) -> some View {
        if matchesSearch(dhikr) {
            AdhkarRow(
                arabicText: dhikr.arabicText,
                transliteration: dhikr.transliteration,
                translation: dhikr.translation,
                alignArabicTrailing: alignArabicTrailing,
                useQuranicFont: settings.useFontArabic,
                searchQuery: searchText
            )
        }
    }

    private var introductionSection: some View {
        Section(header: Text("REMEMBRANCES OF ALLAH")) {
             Text("Short remembrances to keep your heart connected to Allah throughout the day.")
                 .font(.subheadline)
                 .foregroundColor(.primary)
                  
             Text("\"Unquestionably, by the remembrance of Allah hearts are assured.\" (Quran 13:28)")
                 .font(.caption)
                 .foregroundColor(.secondary)
        }
    }

    private var etymologySection: some View {
        Section(header: Text("ETYMOLOGY")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Arabic root: ذ ك ر (dh-k-r)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)

                Text("Core meaning: to remember, to mention, to be mindful")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text("Dhikr literally means remembrance or mentioning. It includes saying SubhanAllah, Alhamdulillah, Allahu Akbar, reciting the Quran, and keeping Allah always present in the heart and tongue.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.1))
            )
            .padding(-4)
        }
    }

    @ViewBuilder
    private var adhkarRows: some View {
        ForEach(commonDhikrItems) { dhikr in
            filteredAdhkarRow(dhikr)
        }
    }

    private var virtuesSection: some View {
        Section(header: Text("VIRTUES OF DHIKR")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dhikr is a continuous awareness of Allah. It revives the heart, protects the soul, and keeps a believer steady in trials.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            ReflectionCard(
                title: "Quranic Reminders",
                lines: [
                    "So remember Me; I will remember you. And be grateful to Me and do not deny Me. (Quran 2:152)",
                    "Unquestionably, by the remembrance of Allah hearts are assured. (Quran 13:28)",
                    "O you who have believed, remember Allah with much remembrance. (Quran 33:41)",
                    "Indeed, the Muslim men and Muslim women, the believing men and believing women, the obedient men and obedient women, the truthful men and truthful women, the patient men and patient women, the humble men and humble women, the charitable men and charitable women, the fasting men and fasting women, the men who guard their private parts and the women who do so, and the men who remember Allah often and the women who do so - for them Allah has prepared forgiveness and a great reward. (Quran 33:35)"
                ],
                accent: settings.accentColor.color
            )

            ReflectionCard(
                title: "Prophetic Encouragement",
                lines: [
                    "The best of deeds is the remembrance of Allah.",
                    "Two phrases are light on the tongue and heavy on the scale: SubhanAllahi wa bihamdihi, SubhanAllahil Adheem.",
                    "Keep your tongue moist with the remembrance of Allah."
                ],
                accent: settings.accentColor.color
            )

            Text("Make dhikr a daily rhythm: morning, evening, after salah, before sleep, and during ordinary moments. A heart that remembers Allah does not stay empty.")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

private struct ReflectionCard: View {
    let title: String
    let lines: [String]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(accent)

            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(-4)
    }
}

#Preview {
    AlIslamPreviewContainer {
        AdhkarView()
    }
}
