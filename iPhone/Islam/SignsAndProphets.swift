#if os(iOS)
import SwiftUI

// The plumbing shared by the three "signs" libraries - Miracles of the Quran, Miracles of the
// Prophets and Prophecies of the Prophet - plus the bridge between a prophet's miracles and his
// story.
//
// Two things live here (Abu, 2026-09-19):
//
//   1. `AboutSignsSection`, the orientation card at the foot of each library. The Hadith tab has
//      carried one for a long time ("What is the Sunnah?", "What are Hadiths?") and it is the thing
//      that turns a list of narrations into a subject you can start from. The three signs libraries
//      argue for prophethood and had no such card, so a reader who did not already know what a
//      miracle is FOR met two hundred science articles with no frame around them.
//
//   2. `ProphetSigns`, the map from a prophet to (a) his page in Pillars & Beliefs and (b) the
//      article about his signs. It is read from BOTH ends: the miracles library shows "read his
//      story", and each of the 25 prophet pages shows "see his miracles". One table, so the two
//      directions can never drift apart.
//
// Both follow the one-link-per-List-row rule: a single `@State` enum and a single `.pushDestination`
// on the List, never two NavigationLinks in one row (they all activate on any tap).

// MARK: - About card

/// A pillar article the "About" card can open. Each case names an existing screen; nothing here is
/// new prose, it is a door to the article that already answers the question.
enum SignsAboutDoor: String, Identifiable, Hashable, CaseIterable {
    case quran
    case prophet
    case prophets
    case sunnah
    case hadith
    case god
    case allah
    case islam
    case muslim
    case tawhid
    case makeDua
    case salah
    case sawm
    case zakah
    case hajj
    case tajweed
    // Added for the TOOLS (Abu, 2026-09-19: "link tools with what they are all over the app"). A
    // calculator answers "how much"; these answer "what is this and why". Only articles that already
    // exist are here - there is no halal-food or faraid article to point at, so those two tools link
    // to the nearest thing that IS written rather than to a promise.
    case howToZakah
    case hijriCalendarArticle
    case sacredMonths
    case masjidHaram
    case masjidNabawi
    case dhikrVirtue
    /// The 99 Names article in Pillars & Beliefs, the written half of the names library.
    case namesOfAllahArticle

    var id: String { rawValue }

    /// The question as the card asks it, which is also the destination's own navigation title.
    var title: String {
        switch self {
        case .quran:    return "What is the Quran?"
        case .prophet:  return "Who is Prophet Muhammad \u{FDFA}?"
        case .prophets: return "Belief in the Prophets"
        case .sunnah:   return "What is the Sunnah?"
        case .hadith:   return "What are Hadiths?"
        case .god:      return "Does God Exist?"
        case .allah:    return "Who is Allah \u{FDFB}\u{200E}?"
        case .islam:    return "What is Islam?"
        case .muslim:   return "What is a Muslim?"
        case .tawhid:   return "Tawhid: The Oneness of Allah"
        case .makeDua:  return "How to Make Dua"
        case .salah:    return "Salah (Five Daily Prayers)"
        case .sawm:     return "Sawm (Fasting in Ramadan)"
        case .zakah:    return "Zakah (Annual Charity)"
        case .hajj:     return "Hajj (Pilgrimage to Makkah)"
        case .tajweed:  return "Tajweed"
        case .howToZakah:          return "How to Give Zakah"
        case .hijriCalendarArticle: return "The Hijri Calendar"
        case .sacredMonths:        return "The Four Sacred Months"
        case .masjidHaram:         return "Al-Masjid al-Haram"
        case .masjidNabawi:        return "Al-Masjid an-Nabawi"
        case .dhikrVirtue:         return "Tasbih and Dhikr"
        case .namesOfAllahArticle: return "The 99 Names of Allah"
        }
    }

    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
        case .quran:    QuranPillarView()
        case .prophet:  ProphetPillarView()
        case .prophets: ProphetsView()
        case .sunnah:   SunnahPillarView()
        case .hadith:   HadithPillarView()
        case .god:      GodPillarView()
        case .allah:    AllahPillarView()
        case .islam:    IslamPillarView()
        case .muslim:   MuslimPillarView()
        case .tawhid:   TawhidView()
        case .makeDua:  MakeDuaView()
        case .salah:    SalahView()
        case .sawm:     SawmView()
        case .zakah:    ZakahView()
        case .hajj:     HajjView()
        case .tajweed:  TajweedView()
        case .howToZakah:           HowToZakahView()
        case .hijriCalendarArticle: HijriCalendarView()
        case .sacredMonths:         SacredMonthsView()
        case .masjidHaram:          HaramView()
        case .masjidNabawi:         NabawiView()
        // The Tasbih counter counts dhikr, and the app's article on what dhikr IS is the Adhkar
        // library's own subject; `AllahPillarView` is what the 99 Names card already points at.
        case .dhikrVirtue:          AllahPillarView()
        case .namesOfAllahArticle:  NamesOfAllahPillarView()
        }
    }
}

/// The orientation card at the foot of a signs library: the questions behind the library, as doors to
/// the articles that answer them. The twin of the Hadith tab's "About Hadith & the Sunnah" card, down
/// to the glass chips and the closing pointer, so the four libraries read as one family.
///
/// The doors are Buttons writing one `@State`, not NavigationLinks: every chip here sits in the SAME
/// List row (this whole card is one row), and two links in one row both fire on any tap.
struct AboutSignsSection: View {
    @ObservedObject private var settings = Settings.shared

    /// The card's own heading, e.g. "About Miracles & Prophethood".
    let heading: String
    let systemImage: String
    /// Which pillar articles to offer, in order.
    let doors: [SignsAboutDoor]
    /// Written by the parent, which owns the single `.pushDestination` on its List.
    @Binding var openDoor: SignsAboutDoor?

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.subheadline)
                        .foregroundColor(settings.accentColor.color)

                    Text(heading)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }

                ForEach(doors) { door in
                    Button {
                        settings.hapticFeedback()
                        openDoor = door
                    } label: {
                        HStack {
                            Text(door.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .conditionalGlassEffect(clear: true, rectangle: true)
                        .contentShape(Rectangle())
                        .padding(.horizontal, -2)
                    }
                    .buttonStyle(.plain)
                }

                Text("Learn more under Al-Islam \u{2192} Pillars and Beliefs.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
            #if DEBUG
            .id("aboutSigns")
            #endif
        }
    }
}

extension View {
    /// The ONE destination a library's About card shares, attached to the List (a lazy row's own
    /// destination never fires - `PushDestination`'s rule).
    func aboutSignsDestination(_ openDoor: Binding<SignsAboutDoor?>) -> some View {
        pushDestination(isPresented: Binding(
            get: { openDoor.wrappedValue != nil },
            set: { if !$0 { openDoor.wrappedValue = nil } }
        )) {
            if let door = openDoor.wrappedValue { door.destination }
        }
    }
}

// MARK: - Article content

/// One paragraph or quote of a Prophecies or Miracles of the Prophets article. The two libraries
/// hold about 130 articles between them, so an article is data rendered by `SignArticleSections`
/// rather than a hand-built view per article (Abu, 2026-09-25: "there's barely any in there").
///
/// A hadith is a reference into the bundled shelf, token ranges and all, exactly as
/// `ScriptureQuote(hadith:)` takes it; `Scripts/verify_prophecies.py` reads every `.hadith(` here
/// back out of the packs, refuses a weak grade and a range outside the row, and prints the quote.
enum SignBlock {
    case text(String)
    /// "7:73" or "19:29-30", rendered from the app's own mushaf.
    case quran(String)
    case hadith(String, cite: String, arabic: ClosedRange<Int>, english: ClosedRange<Int>)
}

struct SignSection {
    let heading: String
    let blocks: [SignBlock]

    init(_ heading: String, _ blocks: [SignBlock]) {
        self.heading = heading
        self.blocks = blocks
    }
}

/// An article's sections, in order, each under its `ArticleHeader`.
struct SignArticleSections: View {
    let sections: [SignSection]

    var body: some View {
        ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
            Section(header: ArticleHeader(section.heading)) {
                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .text(let text):
                        Text(verbatim: text)
                            .font(.body)
                    case .quran(let reference):
                        ScriptureQuote(quran: reference)
                    case let .hadith(link, cite, arabic, english):
                        ScriptureQuote(hadith: link, cite: cite, arabic: arabic, english: english)
                    }
                }
            }
        }
    }
}

// MARK: - Strongest

/// The STRONGEST section each signs library leads with: the first three, then a "Show more" row for
/// the rest (Abu, 2026-09-25: "show like 3 and have a show more button to see all"). The pick is the
/// app's own in all three libraries, which the footer says.
struct StrongestSection<Item: Identifiable, Row: View>: View {
    @Environment(\.appearance) private var appearance

    let items: [Item]
    let footer: String
    @ViewBuilder let row: (Item) -> Row

    @State private var showAll = false

    /// Enough to show what the pick is like without pushing the library's own browse off screen.
    static var collapsedCount: Int { 3 }

    var body: some View {
        if !items.isEmpty {
            Section(
                header: SectionPillHeader(title: "STRONGEST", count: items.count, icon: "star.fill", accentTitle: true),
                footer: Text(footer)
            ) {
                ForEach(showAll ? items : Array(items.prefix(Self.collapsedCount))) { item in
                    row(item)
                }

                if items.count > Self.collapsedCount {
                    Button {
                        Settings.shared.hapticFeedback()
                        withAnimation(.easeInOut) { showAll.toggle() }
                    } label: {
                        HStack {
                            Text(showAll ? "Show fewer" : "Show \(items.count - Self.collapsedCount) more")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Image(systemName: showAll ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundColor(appearance.accent)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - The prophet bridge

/// A prophet who appears in both libraries: his story in Pillars & Beliefs, and his signs in Miracles
/// of the Prophets. Read from both ends so the two can never disagree about who has what.
struct ProphetSigns: Identifiable {
    /// The prophet page's view-type name, the id `IslamArticles` and `IslamArticleCatalog` use.
    let id: String
    /// His name as both indexes print it.
    let name: String
    let arabic: String
    /// The `ProphetMiraclesView.Entry` ids whose articles cover his signs, in the library's order.
    /// Musa has five; most prophets have one.
    let miracleEntries: [String]
    /// One line naming the signs, for the row under his name.
    let signs: String

    @MainActor
    @ViewBuilder
    var storyDestination: some View {
        switch id {
        case "ProphetNuhView":      ProphetNuhView()
        case "ProphetHudView":      ProphetHudView()
        case "ProphetSalihView":    ProphetSalihView()
        case "ProphetIbrahimView":  ProphetIbrahimView()
        case "ProphetLutView":      ProphetLutView()
        case "ProphetIsmailView":   ProphetIsmailView()
        case "ProphetYaqubView":    ProphetYaqubView()
        case "ProphetYusufView":    ProphetYusufView()
        case "ProphetAyyubView":    ProphetAyyubView()
        case "ProphetMusaView":     ProphetMusaView()
        case "ProphetHarunView":    ProphetHarunView()
        case "ProphetDawudView":    ProphetDawudView()
        case "ProphetSulaymanView": ProphetSulaymanView()
        case "ProphetYunusView":    ProphetYunusView()
        case "ProphetZakariyaView": ProphetZakariyaView()
        case "ProphetYahyaView":    ProphetYahyaView()
        case "ProphetIsaView":      ProphetIsaView()
        case "ProphetMuhammadView": ProphetMuhammadView()
        default:                    EmptyView()
        }
    }
}

enum ProphetSignsIndex {
    /// Every prophet whose signs the miracles library covers, in the order the Quran's history runs.
    static let all: [ProphetSigns] = [
        .init(id: "ProphetNuhView", name: "Nuh", arabic: "\u{0646}\u{064F}\u{0648}\u{062D}",
              miracleEntries: ["nuh-ark"], signs: "The ark, and the flood that was left as a sign"),
        .init(id: "ProphetHudView", name: "Hud", arabic: "\u{0647}\u{064F}\u{0648}\u{062F}",
              miracleEntries: ["hud-wind"], signs: "One man a whole nation could not touch, then the wind"),
        .init(id: "ProphetSalihView", name: "Salih", arabic: "\u{0635}\u{064E}\u{0627}\u{0644}\u{0650}\u{062D}",
              miracleEntries: ["salih-camel"], signs: "The she-camel, and the water shared with her"),
        .init(id: "ProphetIbrahimView", name: "Ibrahim", arabic: "\u{0625}\u{0650}\u{0628}\u{0631}\u{064E}\u{0627}\u{0647}\u{0650}\u{064A}\u{0645}",
              miracleEntries: ["ibrahim-fire", "ibrahim-birds"], signs: "The fire made cool, and the four birds"),
        .init(id: "ProphetLutView", name: "Lut", arabic: "\u{0644}\u{064F}\u{0648}\u{0637}",
              miracleEntries: ["lut-city"], signs: "The angels at his door, and the city overturned"),
        .init(id: "ProphetIsmailView", name: "Isma'il", arabic: "\u{0625}\u{0650}\u{0633}\u{0645}\u{064E}\u{0627}\u{0639}\u{0650}\u{064A}\u{0644}",
              miracleEntries: ["zamzam"], signs: "The spring of Zamzam, opened for him and his mother"),
        .init(id: "ProphetYaqubView", name: "Ya'qub", arabic: "\u{064A}\u{064E}\u{0639}\u{0642}\u{064F}\u{0648}\u{0628}",
              miracleEntries: ["yusuf-dream-shirt"], signs: "His sight returned by his son's shirt"),
        .init(id: "ProphetYusufView", name: "Yusuf", arabic: "\u{064A}\u{064F}\u{0648}\u{0633}\u{064F}\u{0641}",
              miracleEntries: ["yusuf-dream-shirt"], signs: "The dream fulfilled, and the shirt that healed"),
        .init(id: "ProphetAyyubView", name: "Ayyub", arabic: "\u{0623}\u{064E}\u{064A}\u{064F}\u{0651}\u{0648}\u{0628}",
              miracleEntries: ["ayyub-spring"], signs: "The spring that healed him, and his family restored"),
        .init(id: "ProphetMusaView", name: "Musa", arabic: "\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649}",
              miracleEntries: ["musa-staff-hand", "musa-nine-signs", "musa-sea", "musa-desert", "musa-cow"],
              signs: "The staff and the hand, the nine signs, the sea, the springs"),
        .init(id: "ProphetHarunView", name: "Harun", arabic: "\u{0647}\u{064E}\u{0627}\u{0631}\u{064F}\u{0648}\u{0646}",
              miracleEntries: ["musa-staff-hand", "musa-sea"], signs: "Beside his brother before Pharaoh and at the sea"),
        .init(id: "ProphetDawudView", name: "Dawud", arabic: "\u{062F}\u{064E}\u{0627}\u{0648}\u{064F}\u{0648}\u{062F}",
              miracleEntries: ["dawud-iron"], signs: "Iron softened in his hands; the mountains echoing him"),
        .init(id: "ProphetSulaymanView", name: "Sulayman", arabic: "\u{0633}\u{064F}\u{0644}\u{064E}\u{064A}\u{0645}\u{064E}\u{0627}\u{0646}",
              miracleEntries: ["sulayman-wind-jinn", "sulayman-ant-hoopoe", "sheba-throne"],
              signs: "The wind, the jinn, the speech of birds and ants, the throne of Sheba"),
        .init(id: "ProphetYunusView", name: "Yunus", arabic: "\u{064A}\u{064F}\u{0648}\u{0646}\u{064F}\u{0633}",
              miracleEntries: ["yunus-whale"], signs: "Kept alive in the belly of the whale"),
        .init(id: "ProphetZakariyaView", name: "Zakariya", arabic: "\u{0632}\u{064E}\u{0643}\u{064E}\u{0631}\u{0650}\u{064A}\u{064E}\u{0651}\u{0627}",
              miracleEntries: ["zakariya-yahya"], signs: "A son in old age, and three nights without speech"),
        .init(id: "ProphetYahyaView", name: "Yahya", arabic: "\u{064A}\u{064E}\u{062D}\u{064A}\u{064E}\u{0649}",
              miracleEntries: ["zakariya-yahya"], signs: "Born to a barren mother and an old father"),
        .init(id: "ProphetIsaView", name: "'Isa", arabic: "\u{0639}\u{0650}\u{064A}\u{0633}\u{064E}\u{0649}",
              miracleEntries: ["isa-birth-cradle", "isa-signs", "table-spread"],
              signs: "Speech in the cradle, healing, the dead raised, the table"),
        .init(id: "ProphetMuhammadView", name: "Muhammad", arabic: "\u{0645}\u{064F}\u{062D}\u{064E}\u{0645}\u{064E}\u{0651}\u{062F}",
              miracleEntries: ["quran", "moon", "isra"], signs: "The Quran, the splitting of the moon, and more"),
    ]

    /// The prophets whose signs one miracles article covers.
    static func forEntry(_ entryID: String) -> [ProphetSigns] {
        all.filter { $0.miracleEntries.contains(entryID) }
    }

    /// The signs articles for a prophet page, if the library covers him.
    static func forProphet(_ viewID: String) -> ProphetSigns? {
        all.first { $0.id == viewID }
    }
}

// MARK: - Prophet page -> his miracles

/// The section a prophet's page in Pillars & Beliefs shows when the miracles library covers him: one
/// door to the article about his signs. `ProphetViews` has 25 pages and this is added by id, so a
/// prophet with no entry in `ProphetSignsIndex` renders nothing at all.
struct ProphetMiraclesLink: View {
    @ObservedObject private var settings = Settings.shared

    /// The prophet page's own view-type name, e.g. "ProphetMusaView".
    let article: String

    @State private var openEntry: ProphetMiraclesView.Entry?

    private var entries: [ProphetMiraclesView.Entry] {
        guard let signs = ProphetSignsIndex.forProphet(article) else { return [] }
        return signs.miracleEntries.compactMap { id in ProphetMiraclesView.entries.first { $0.id == id } }
    }

    var body: some View {
        let entries = entries
        if !entries.isEmpty {
            Section(header: ArticleHeader("HIS MIRACLES"),
                    footer: Text("In Miracles of the Prophets, under Al-Islam.")) {
                ForEach(entries) { entry in
                    Button {
                        settings.hapticFeedback()
                        openEntry = entry
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "staroflife")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(settings.accentColor.color)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(entry.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            // Each door is a Button writing one state and the destination hangs off the enclosing
            // List, never a NavigationLink per row inside a lazily built section.
            .pushDestination(isPresented: Binding(
                get: { openEntry != nil },
                set: { if !$0 { openEntry = nil } }
            )) {
                if let openEntry { ProphetMiracleArticleView(entry: openEntry) }
            }
        }
    }
}
#endif
