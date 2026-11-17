import SwiftUI

// How often each tajweed rule comes (Tajweed Foundations' QUICK REFERENCE, iPhone): every colored
// stretch the reader paints on the Hafs text, counted by rule. The pair of Quran Words (Abu,
// 2026-11-16: "do something about this in tajweed and arabic"): a few words carry most of the Quran,
// and a few rules carry most of its tajweed. Counted by Scripts/build_quran_vocabulary.py from the
// engine's Hafs annotations, into QuranVocabulary.json.xz.

struct TajweedRuleFrequencyView: View {
    @Environment(\.appearance) private var appearance

    @State private var vocabulary: QuranVocabulary? = QuranVocabularyStore.shared.ifLoaded

    var body: some View {
        List {
            Group {
                if let vocabulary, !vocabulary.tajweed.isEmpty {
                    heroSection(vocabulary)
                    rulesSection(vocabulary)
                    wordsSection
                } else {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How Often Each Rule Comes")
        .navigationBarTitleDisplayMode(.inline)
        .openScreen(.tajweedRuleFrequency)
        .task {
            if vocabulary == nil { vocabulary = await QuranVocabularyStore.shared.loaded() }
        }
    }

    /// How many of the most common rules it takes to make up most of the marks.
    private func topShare(_ vocabulary: QuranVocabulary, count: Int) -> Double {
        vocabulary.tajweed.prefix(count).reduce(0) { $0 + vocabulary.share(of: $1) }
    }

    private func heroSection(_ vocabulary: QuranVocabulary) -> some View {
        let top = topShare(vocabulary, count: 5)
        return ResourceHeroSection(ResourceHero(
            eyebrow: String(localized: "TAJWEED IN NUMBERS"),
            systemImage: "chart.bar.fill",
            headline: String(localized: "Five rules are \(QuranWordsFormat.percent(top)) of all the tajweed colors"),
            message: String(localized: "The reader colors \(vocabulary.totals.tajweedMarks.formatted()) stretches of letters across the Quran in Hafs. Most of them are a handful of rules you meet on every line, so learning those first pays back on every page you recite."),
            stats: [
                ResourceHeroStat("\(vocabulary.tajweed.count)", String(localized: "rules colored")),
                ResourceHeroStat(vocabulary.totals.tajweedMarks.formatted(), String(localized: "colored stretches")),
                ResourceHeroStat(QuranWordsFormat.percent(top), String(localized: "from the top five")),
            ]
        ))
    }

    private func rulesSection(_ vocabulary: QuranVocabulary) -> some View {
        let largest = vocabulary.tajweed.map { vocabulary.share(of: $0) }.max() ?? 100
        return Section {
            ForEach(Array(vocabulary.tajweed.enumerated()), id: \.element.id) { index, rule in
                NavigationLink(destination: LazyDestination { Self.topic(for: rule.category).destination }) {
                    TajweedRuleFrequencyRow(rank: index + 1, rule: rule, share: vocabulary.share(of: rule), largest: largest)
                }
            }
        } header: {
            Text("BY RULE")
        } footer: {
            Text("Counted from the colors this app paints on the Hafs text. One mark is one colored stretch: a lengthened letter, a heavy letter, a merged noon. Tap a rule for its page in Tajweed Foundations.")
        }
    }

    private var wordsSection: some View {
        Section(header: Text("THE SAME IN WORDS")) {
            OpenScreenLink(screen: .quranWords) {
                QuranWordsView()
            } label: {
                TajweedLinkLabel(systemImage: "character.book.closed.fill", title: String(localized: "Quran Words"),
                                 caption: String(localized: "The 500 most common words make up four in five of the words you recite"))
            }
        }
    }

    /// The Foundations page that teaches a color's rule.
    static func topic(for category: TajweedLegendCategory) -> TajweedTopic {
        switch category {
        case .lamShamsiyah: return .shamsQamar
        case .droppedLetter: return .mushafHints
        case .hamzatWaslSilent: return .hamzatulWasl
        case .idghamBilaGhunnah, .idghamGhunnah, .generalGhunnah, .ikhfaaLight, .ikhfaaHeavy, .iqlaab: return .noonSakinah
        case .qalqalah: return .qalqalah
        case .tafkhim: return .heavyLight
        case .maddNatural, .maddNaturalMiniature, .maddSukoon, .maddSeparated, .maddConnected, .maddNecessary: return .madd
        }
    }
}

/// One rule: its color, its name in English and Arabic, its share as a bar and a figure.
private struct TajweedRuleFrequencyRow: View {
    @Environment(\.appearance) private var appearance

    let rank: Int
    let rule: QuranVocabulary.RuleCount
    let share: Double
    let largest: Double

    var body: some View {
        let color = rule.category.color
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(rule.category.englishTitle)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(QuranWordsFormat.percent(share))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(color)
            }
            ProgressView(value: share, total: max(largest, 0.1))
                .tint(color)
            HStack {
                Text(rule.category.arabicTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text("\(rule.count.formatted()) marks")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
