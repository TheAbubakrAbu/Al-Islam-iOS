import SwiftUI

// The tags on a chapter's row and the two cards a prophet's page opens and closes with (Abu, 2026-11-24:
// "Put tags for each prophet like if Israelite if one of the 5 messengers if given a book ... Do that for
// all other sections too ... Would be fire to also put it on the label itself so I can see each prophet
// together", and "Mention every ayah and every surah that mentions the name of the prophet").
//
// A prophet's tags and his ayahs are generated (ProphetFacts.swift, Scripts/build_prophet_facts.py); every
// other chapter's tags are written here by hand (`LibraryTags.written`). The facts card is the
// `.facts("musa")` block / `ProphetFactsSection`, the list the `.mentions("musa")` block /
// `ProphetMentionsSection`; the corpus builder reads the same words for both, so search and the Ask AI
// chat find what the screen shows. This file compiles for the Watch too: the ayah numbers open the Quran
// tab on iOS and are plain text there.

// MARK: - Tags

enum LibraryTags {
    /// The tags of a catalog row: a prophet's on his FIRST story chapter and on his Pillars page, the
    /// written ones on everything else.
    static func tags(for id: String) -> [ProphetFacts.Tag] {
        if let facts = ProphetFacts.forArticle(id), facts.isPrimary(id) { return facts.tags }
        return written[id] ?? []
    }

    /// The Arabic name a prophet's primary row carries on its trailing side.
    static func arabic(for id: String) -> String? {
        guard let facts = ProphetFacts.forArticle(id), facts.isPrimary(id) else { return nil }
        return facts.arabic
    }

    private static func tag(_ kind: ProphetFacts.Tag.Kind, _ text: String) -> ProphetFacts.Tag {
        ProphetFacts.Tag(kind: kind, text: text)
    }

    /// Every other chapter's tags: what a reader scanning the list wants to know before opening it.
    static let written: [String: [ProphetFacts.Tag]] = [
        // Stories of the Prophets: the chapters that are not one prophet's first.
        "StoryProphetsView": [tag(.count, "25 named in the Quran"), tag(.rank, "Five of firm resolve"), tag(.known, "Nabi and rasul")],
        "StoryIntroView": [tag(.surah, "12:111"), tag(.known, "Lessons, not legends")],
        "StoryFamilyView": [tag(.count, "Twelve tribes"), tag(.people, "Prophets who were kin"), tag(.known, "Adam to Muhammad")],
        "StoryNationsView": [tag(.place, "‘Ad, Thamud, Madyan, Egypt"), tag(.known, "Their sin and their end")],
        "StoryIsraeliyyatView": [tag(.people, "Yusha’, Danyal, ‘Uzayr"), tag(.known, "Named only outside the Quran")],
        "StoryMusaPharaohView": [tag(.place, "Egypt"), tag(.known, "Nine signs; the sea parted")],
        "StoryWildernessView": [tag(.place, "Sinai"), tag(.known, "The calf, the cow, forty years")],
        "StoryKhidrView": [tag(.surah, "Al-Kahf 18:60-82"), tag(.known, "The boat, the boy, the wall")],

        // Sahabah, Ahlul Bayt & Salaf.
        "CompanionsIntroView": [tag(.people, "The best generation"), tag(.known, "All of them upright")],
        "CompanionAbuBakrView": [tag(.rank, "First caliph"), tag(.people, "Quraysh, Banu Taym"), tag(.date, "Caliph 11–13 AH"), tag(.known, "As-Siddiq")],
        "CompanionUmarView": [tag(.rank, "Second caliph"), tag(.people, "Quraysh, Banu ‘Adi"), tag(.date, "Caliph 13–23 AH"), tag(.known, "Al-Faruq")],
        "CompanionUthmanView": [tag(.rank, "Third caliph"), tag(.people, "Quraysh, Banu Umayyah"), tag(.date, "Caliph 23–35 AH"), tag(.known, "Dhun-Nurayn; the mushaf")],
        "CompanionAliView": [tag(.rank, "Fourth caliph"), tag(.people, "Quraysh, Banu Hashim"), tag(.date, "Caliph 35–40 AH"), tag(.known, "Husband of Fatimah")],
        "CompanionTenView": [tag(.count, "Ten named together"), tag(.known, "Promised Paradise")],
        "CompanionKhadijahAishahView": [tag(.people, "Mothers of the Believers"), tag(.known, "The first believer; the most learned")],
        "CompanionFatimahView": [tag(.people, "Ahlul Bayt"), tag(.known, "Leader of the women of Paradise")],
        "CompanionUnclesView": [tag(.people, "Banu Hashim"), tag(.known, "The lion of Allah; the two wings")],
        "CompanionFirstBelieversView": [tag(.place, "Makkah"), tag(.known, "The first believers and martyrs")],
        "CompanionAbuHurayrahView": [tag(.rank, "Most prolific narrator"), tag(.known, "Ibn Umar, Anas, A’ishah")],
        "CompanionWomenView": [tag(.people, "Women Companions"), tag(.known, "Narrators, scholars, fighters")],
        "CompanionTabiunView": [tag(.people, "The second generation"), tag(.known, "Students of the Companions")],
        "CompanionFourImamsView": [tag(.count, "Four schools"), tag(.date, "80–241 AH"), tag(.known, "One creed")],

        // Refuting Religions, the chapters of its own and the answers it lists.
        "ReligionsMethodView": [tag(.surah, "16:125"), tag(.known, "Wisdom and the best argument")],
        "ReligionsOneView": [tag(.known, "Islam from Adam to Muhammad")],
        "ReligionsPluralismView": [tag(.known, "Are all paths true?")],
        "ReligionsSikhismView": [tag(.date, "From c. 1500 CE"), tag(.place, "Punjab"), tag(.book, "Guru Granth Sahib")],
        "ReligionsZoroastrianismView": [tag(.place, "Ancient Persia"), tag(.book, "Avesta"), tag(.known, "Two powers")],
        "ReligionsEastAsiaView": [tag(.place, "China and Japan"), tag(.book, "Analects, Tao Te Ching"), tag(.known, "Ancestors and spirits")],
        "ReligionsSecularismView": [tag(.date, "From the 18th century"), tag(.known, "Man as the measure")],
        "ReligionsNewProphetsView": [tag(.date, "1863, 1889, 1930"), tag(.known, "Prophets after the last")],
        "ChristianityAnswerView": [tag(.book, "The Bible"), tag(.known, "The Trinity and the cross")],
        "JudaismAnswerView": [tag(.book, "Tanakh and Talmud"), tag(.known, "The covenant")],
        "HinduismAnswerView": [tag(.book, "The Vedas"), tag(.known, "Rebirth and many gods")],
        "BuddhismAnswerView": [tag(.book, "The Pali Canon"), tag(.known, "Suffering and release")],

        // Preservation of the Quran.
        "PreservationStagesView": [tag(.date, "610–632 CE"), tag(.count, "Over 23 years")],
        "PreservationMemoryView": [tag(.known, "Memorised in every generation")],
        "PreservationWritingView": [tag(.date, "In his lifetime"), tag(.known, "The scribes of revelation")],
        "PreservationOrderView": [tag(.count, "114 surahs"), tag(.known, "Set by the Prophet")],
        "PreservationScriptView": [tag(.date, "First century AH"), tag(.known, "Dots and vowel marks")],
        "PreservationManuscriptsView": [tag(.place, "Birmingham, Sana’a, Topkapi"), tag(.date, "First century AH")],
        "PreservationNaskhView": [tag(.known, "Abrogation, and its limits")],
        "PreservationClaimsView": [tag(.surah, "15:9"), tag(.known, "Claims of corruption answered")],

        // Science of Hadith.
        "HadithScienceTermsView": [tag(.known, "Sahih, hasan, da‘if")],
        "HadithScienceBreaksView": [tag(.known, "Mursal, munqati‘, mu‘dal")],
        "HadithScienceRijalView": [tag(.known, "Jarh wa ta‘dil")],
        "HadithScienceAhadView": [tag(.known, "Ahad is proof in creed")],
        "HadithScienceFabricationView": [tag(.known, "Mawdu‘: how forgeries were caught")],
        "HadithScienceQudsiView": [tag(.known, "Allah’s words, the Prophet’s wording")],
        "HadithScienceGradesView": [tag(.known, "Reading a grade line")],
        "HadithScienceOrientalistsView": [tag(.people, "Goldziher, Schacht"), tag(.known, "The Western critics answered")],

        // The Domino Process.
        "DominoIntroView": [tag(.count, "Seven dominoes"), tag(.count, "Three sessions")],
        "DominoRealityView": [tag(.rank, "Dominoes 1 and 2"), tag(.known, "Something is necessary")],
        "DominoCreatorView": [tag(.rank, "Domino 3"), tag(.known, "An intelligent Creator")],
        "DominoOneView": [tag(.rank, "Domino 4"), tag(.known, "Only one")],
        "DominoWorldviewsView": [tag(.known, "Atheism, agnosticism, deism")],
        "DominoRevelationView": [tag(.rank, "Domino 5"), tag(.known, "Has the Creator spoken?")],
        "DominoTestView": [tag(.rank, "Domino 6"), tag(.known, "Testing every claim")],
        "DominoChristianityView": [tag(.known, "Christianity tested")],
        "DominoIslamView": [tag(.rank, "Domino 7"), tag(.known, "Islam")],
        "DominoDawahView": [tag(.known, "Say this, not that")],
    ]
}

extension ProphetFacts {
    /// Whether this id is his first story chapter or his Pillars page: the rows that carry his tags.
    func isPrimary(_ id: String) -> Bool { stories.first == id || pillars == id }
}

extension ProphetFacts.Tag {
    var symbol: String {
        switch kind {
        case .rank:
            switch text {
            case "Ulul ‘Azm": return "crown.fill"
            case "Messenger": return "envelope.fill"
            case "Prophet": return "sparkle"
            default: return "star.fill"
            }
        case .people: return "person.2.fill"
        case .book: return "book.closed.fill"
        case .surah: return "text.book.closed"
        case .count: return "number"
        case .sent: return "arrow.up.forward.circle"
        case .known: return "star"
        case .date: return "calendar"
        case .place: return "mappin.and.ellipse"
        }
    }

    var label: String {
        switch kind {
        case .rank: return "Rank"
        case .people: return "Lineage"
        case .book: return "Book"
        case .surah: return "Surah"
        case .count: return "In the Quran"
        case .sent: return "Sent to"
        case .known: return "Known for"
        case .date: return "When"
        case .place: return "Where"
        }
    }
}

/// One tag: a small capsule, its symbol and its words. The rank leads in the accent.
struct LibraryTagView: View {
    @Environment(\.appearance) private var appearance
    let tag: ProphetFacts.Tag

    var body: some View {
        let emphasized = tag.kind == .rank
        HStack(spacing: 3) {
            Image(systemName: tag.symbol)
                .font(.system(size: 8.5, weight: .semibold))
            Text(tag.text)
                .font(.caption2.weight(emphasized ? .bold : .medium))
                .lineLimit(1)
        }
        .foregroundColor(emphasized ? appearance.accent : .secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(Capsule().fill(emphasized ? appearance.accent.opacity(0.15) : Color.secondary.opacity(0.13)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tag.label): \(tag.text)")
    }
}

/// A row's tags, wrapped onto as many lines as they need.
struct LibraryTagFlow: View {
    let tags: [ProphetFacts.Tag]

    var body: some View {
        if #available(iOS 16.0, watchOS 9.0, *) {
            LeadingChipFlow(spacing: 4) {
                ForEach(tags, id: \.self) { LibraryTagView(tag: $0) }
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(tags, id: \.self) { LibraryTagView(tag: $0) }
            }
        }
    }
}

// MARK: - The facts card

/// The card under a prophet's SUMMARY: his name in Arabic and English, and every tag. One List row.
struct ProphetFactsCard: View {
    @Environment(\.appearance) private var appearance
    let facts: ProphetFacts

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(facts.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if !facts.english.isEmpty {
                        Text(facts.english)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Text(facts.arabic)
                    .font(.title2)
                    .foregroundColor(appearance.accent)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            LibraryTagFlow(tags: facts.tags)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// `ProphetFactsCard` as a page section of its own, for the view-based Pillars pages.
struct ProphetFactsSection: View {
    let prophet: String

    var body: some View {
        if let facts = ProphetFacts.named(prophet) {
            Section(header: ArticleHeader("AT A GLANCE")) {
                ProphetFactsCard(facts: facts)
            }
        }
    }
}

// MARK: - Named in the Quran

/// Every surah and ayah that names him, from the preprocessed table: the count first, then a line per
/// surah, each ayah number opening it in the Quran tab. A long list shows its first surahs and a button for
/// the rest. One List row: each number is its own borderless Button, so a tap opens that ayah only.
struct ProphetMentionsCard: View {
    @Environment(\.appearance) private var appearance
    let facts: ProphetFacts
    @State private var showsAll = false

    private static let shortList = 8

    var body: some View {
        let surahs = showsAll || facts.surahs.count <= Self.shortList + 2 ? facts.surahs : Array(facts.surahs.prefix(Self.shortList))
        VStack(alignment: .leading, spacing: 12) {
            ArticleStatGrid([
                ArticleStat("\(facts.times)", facts.times == 1 ? "time named" : "times named"),
                ArticleStat("\(facts.ayahCount)", facts.ayahCount == 1 ? "ayah" : "ayahs"),
                ArticleStat("\(facts.surahs.count)", facts.surahs.count == 1 ? "surah" : "surahs"),
            ])

            ForEach(surahs, id: \.self) { surah in
                surahLine(surah)
            }

            if facts.surahs.count > surahs.count {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showsAll = true }
                } label: {
                    Label("Show all \(facts.surahs.count) surahs", systemImage: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(appearance.accent)
                }
                .buttonStyle(.borderless)
            }

            ForEach(facts.also, id: \.self) { also in
                VStack(alignment: .leading, spacing: 6) {
                    Text("Also \(also.label), \(also.times) \(also.times == 1 ? "time" : "times")")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.primary)
                    ForEach(also.surahs, id: \.self) { surah in
                        surahLine(surah)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }

    private func surahLine(_ surah: ProphetFacts.Surah) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(surah.name) · \(surah.number)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            if #available(iOS 16.0, watchOS 9.0, *) {
                LeadingChipFlow(spacing: 5) {
                    ForEach(surah.ayahs, id: \.self) { ayah in ayahChip(surah.number, ayah) }
                }
            } else {
                Text(surah.ayahs.map { "\(surah.number):\($0)" }.joined(separator: ", "))
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func ayahChip(_ surah: Int, _ ayah: Int) -> some View {
        let label = Text("\(surah):\(ayah)")
            .font(.caption.monospacedDigit().weight(.medium))
            .foregroundColor(appearance.accent)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(appearance.accent.opacity(0.12)))
        #if os(iOS)
        Button {
            Settings.shared.hapticFeedback()
            AppLinkRouter.open(.ayah(surah: surah, ayah: ayah))
        } label: { label }
        .buttonStyle(.borderless)
        .accessibilityLabel("Open \(surah):\(ayah)")
        #else
        label
        #endif
    }
}

/// `ProphetMentionsCard` as a page section of its own, for the view-based Pillars pages.
struct ProphetMentionsSection: View {
    let prophet: String

    var body: some View {
        if let facts = ProphetFacts.named(prophet) {
            Section(header: ArticleHeader("NAMED IN THE QURAN")) {
                ProphetMentionsCard(facts: facts)
            }
        }
    }
}
