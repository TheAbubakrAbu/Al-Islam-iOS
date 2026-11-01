import SwiftUI

#if os(iOS)

// THE COLOR CODE OF EVERY RIWAYAH'S MUSHAF, on the Riwayat on the Page article (Abu, 2026-11-01: "use
// tajweed legend and the sorting of them in explaining differences for each riwayah ... put a lot more
// in riwayat in the mushaf"). Nothing here is authored: the rules, their captions and colors are the
// packs' own legend boxes (`QiraahTajweedStore`), a count is the words that print colors with the rule,
// and an example is the earliest short ayah of a riwayah's text that carries the rule, painted with that
// rule alone, the way the Legend's cards show it. The order is the Legend's (`QiraahTajweedStore.ruleOrder`).
//
// Every print is read for this (nineteen JSONs out of one solidpack), so the page's model builds once,
// off the main thread, and every card on the page reads it.

/// What the page's color-code sections show: every rule across the prints with one example each, and
/// each print's own legend.
@MainActor
final class RiwayahColorCodeModel: ObservableObject {
    struct RuleExample {
        /// The print the example comes from.
        let tag: String
        let view: TajweedRuleExample
    }

    /// One print's legend, for the cards at the foot of the page.
    struct PrintCard: Identifiable {
        let option: Settings.Riwayah.Option
        let entries: [QiraahTajweedStore.LegendEntry]
        let counts: [String: Int]
        var id: String { option.id }
    }

    @Published private(set) var rules: [QiraahTajweedStore.RuleAcrossRiwayat]?
    @Published private(set) var examples: [String: RuleExample] = [:]
    @Published private(set) var cards: [PrintCard]?
    private var loading = false

    /// Every riwayah with a print-derived pack, in the classical order of the ten imams and of each
    /// imam's two narrators (the riwayah menus' default order).
    nonisolated static let packOptions: [Settings.Riwayah.Option] = {
        let options = Settings.Riwayah.allOptions.filter { QiraahTajweedStore.fileName(for: $0.tag) != nil }
        let teacherRank = Dictionary(uniqueKeysWithValues: Settings.Riwayah.teacherOrder.enumerated().map { ($1, $0) })
        return options.sorted {
            let a = teacherRank[$0.teacher] ?? .max, b = teacherRank[$1.teacher] ?? .max
            return a == b ? $0.order < $1.order : a < b
        }
    }()

    /// Every print and Hafs: the set the narrators' short names are told apart within (the two ad-Duris).
    nonisolated static let comparedSet: Set<String> = Set(packOptions.map(\.tag) + [Settings.Riwayah.hafsTag])

    /// The narrator's short English name, "ad-Duri (Abu Amr)" where another print shares it.
    nonisolated static func shortName(_ tag: String) -> String {
        QiraatReaderNames.narratorName(tag, compared: comparedSet, display: false)
    }

    /// Reads every pack once, off the main thread; later calls (every card appears) are no-ops.
    func load() {
        guard !loading, rules == nil else { return }
        loading = true
        let options = Self.packOptions
        Task.detached(priority: .userInitiated) {
            let store = QiraahTajweedStore.shared
            let rules = store.rulesAcrossRiwayat(tags: options.map(\.tag))
            // One example per rule, from the print coloring the most words whose text may render (a
            // beta text before consent gives none).
            var examples: [String: RuleExample] = [:]
            for rule in rules {
                for use in rule.uses.sorted(by: { $0.count > $1.count }) {
                    if let view = TajweedLegendExamples.riwayah(use.entry, tag: use.tag) {
                        examples[rule.key] = RuleExample(tag: use.tag, view: view)
                        break
                    }
                }
            }
            let cards = options.map { option in
                PrintCard(option: option, entries: store.legend(for: option.tag),
                          counts: store.ruleWordCounts(for: option.tag))
            }
            await MainActor.run { [rules, examples, cards] in
                self.rules = rules
                self.examples = examples
                self.cards = cards
                self.loading = false
            }
        }
    }
}

// MARK: - A rule across the prints

/// One rule's card under the paragraph that explains it: the print's caption and Arabic name, what it
/// means, every print that marks it with its own color and count (most words first), and an example
/// from the print coloring the most words. `key` is a folded key (`QiraahTajweedStore.ruleAliases`):
/// "khilaf_harf" covers both captions of the magenta.
struct RiwayahRuleCard: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject var model: RiwayahColorCodeModel
    let key: String

    private static let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top),
    ]

    var body: some View {
        Group {
            if let rules = model.rules {
                if let rule = rules.first(where: { $0.key == key }) {
                    card(rule)
                }
            } else {
                RiwayahColorCodeLoadingRow()
            }
        }
        .onAppear { model.load() }
    }

    /// The color most of the prints give the rule, for the card's own dot.
    private func dominantColor(_ rule: QiraahTajweedStore.RuleAcrossRiwayat) -> Color {
        var tally: [Character: Int] = [:]
        for use in rule.uses { tally[use.entry.letter, default: 0] += 1 }
        let letter = tally.max { $0.value < $1.value }?.key ?? rule.uses.first?.entry.letter ?? "m"
        return rule.uses.first { $0.entry.letter == letter }?.entry.color ?? appearance.accent
    }

    private func description(_ rule: QiraahTajweedStore.RuleAcrossRiwayat) -> String {
        if rule.key == "khilaf_harf" {
            return "The word, or the letter, read differently from Ḥafṣ. Every print marks it; sixteen caption it “the letter differing from Ḥafṣ”, ad-Duri’s, Khalaf’s and Khallad’s “the word differing from Ḥafṣ”."
        }
        return QiraahTajweedStore.shortDescriptions[rule.key] ?? ""
    }

    private func card(_ rule: QiraahTajweedStore.RuleAcrossRiwayat) -> some View {
        let accent = appearance.accent
        let color = dominantColor(rule)
        let uses = rule.uses.sorted { $0.count == $1.count ? $0.tag < $1.tag : $0.count > $1.count }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                Text(verbatim: rule.english)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                Text(verbatim: rule.arabic)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            let description = description(rule)
            if !description.isEmpty {
                Text(verbatim: description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(verbatim: uses.count == 1 ? "MARKED BY ONE PRINT" : "MARKED BY \(uses.count) PRINTS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundColor(accent)
                .padding(.top, 2)

            LazyVGrid(columns: Self.columns, alignment: .leading, spacing: 6) {
                ForEach(uses) { use in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(use.entry.color)
                            .frame(width: 8, height: 8)
                        Text(verbatim: RiwayahColorCodeModel.shortName(use.tag))
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Spacer(minLength: 2)
                        Text(verbatim: use.count.formatted())
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundColor(use.entry.color)
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: "\(RiwayahColorCodeModel.shortName(use.tag)): \(use.count) words"))
                }
            }

            if let example = model.examples[rule.key] {
                Divider()
                Text(verbatim: "In \(RiwayahColorCodeModel.shortName(example.tag))’s text, with this rule alone colored:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                example.view
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(color.opacity(0.25), lineWidth: 1))
        )
        .padding(.vertical, 3)
    }
}

/// The row a card shows while the nineteen packs load.
struct RiwayahColorCodeLoadingRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Reading every riwayah’s legend…")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Each print's own legend

/// One compact card per print, in the classical order (the Legend's All Riwayat cards): the narrator,
/// his imam, and his print's rules in the app's order with the words each colors. Opens the narrator's
/// page. Hafs leads with a line instead of a card: his mushaf prints no khilaf, and the app colors it
/// by the tajweed code.
struct RiwayahColorCodeCards: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject var model: RiwayahColorCodeModel

    private static let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top),
    ]

    var body: some View {
        Group {
            if let cards = model.cards {
                ForEach(cards) { card in
                    if let profile = QiraatProfiles.narrator(tag: card.option.tag) {
                        NavigationLink(destination: LazyDestination { RiwayahNarratorDetailView(profile: profile) }) {
                            row(card)
                        }
                    } else {
                        row(card)
                    }
                }
            } else {
                RiwayahColorCodeLoadingRow()
            }
        }
        .onAppear { model.load() }
    }

    private func row(_ card: RiwayahColorCodeModel.PrintCard) -> some View {
        let name = RiwayahColorCodeModel.shortName(card.option.tag)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(verbatim: "from \(card.option.teacher)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer(minLength: 6)
                Text(verbatim: card.option.arabic)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            LazyVGrid(columns: Self.columns, alignment: .leading, spacing: 6) {
                ForEach(card.entries) { entry in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 8, height: 8)
                        Text(verbatim: entry.english)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        if let count = card.counts[entry.key] {
                            Spacer(minLength: 2)
                            Text(verbatim: count.formatted())
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundColor(entry.color)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(name), from \(card.option.teacher). "
            + card.entries.map { "\($0.english): \(card.counts[$0.key] ?? 0) words" }.joined(separator: ". ")))
    }
}

#endif
