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

// MARK: - The prophet bridge

/// A prophet who appears in both libraries: his story in Pillars & Beliefs, and his signs in Miracles
/// of the Prophets. Read from both ends so the two can never disagree about who has what.
struct ProphetSigns: Identifiable {
    /// The prophet page's view-type name, the id `IslamArticles` and `IslamArticleCatalog` use.
    let id: String
    /// His name as both indexes print it.
    let name: String
    let arabic: String
    /// The `ProphetMiraclesView.Entry` id whose article covers his signs.
    let miracleEntry: String
    /// One line naming the signs, for the row under his name.
    let signs: String

    @MainActor
    @ViewBuilder
    var storyDestination: some View {
        switch id {
        case "ProphetSalihView":    ProphetSalihView()
        case "ProphetIbrahimView":  ProphetIbrahimView()
        case "ProphetMusaView":     ProphetMusaView()
        case "ProphetIsaView":      ProphetIsaView()
        case "ProphetSulaymanView": ProphetSulaymanView()
        case "ProphetYunusView":    ProphetYunusView()
        case "ProphetDawudView":    ProphetDawudView()
        case "ProphetMuhammadView": ProphetMuhammadView()
        default:                    EmptyView()
        }
    }
}

enum ProphetSignsIndex {
    /// Every prophet whose signs the miracles library covers, in the library's own order.
    static let all: [ProphetSigns] = [
        .init(id: "ProphetSalihView", name: "Salih", arabic: "\u{0635}\u{064E}\u{0627}\u{0644}\u{0650}\u{062D}",
              miracleEntry: "earlier", signs: "The she-camel brought out of the rock"),
        .init(id: "ProphetIbrahimView", name: "Ibrahim", arabic: "\u{0625}\u{0650}\u{0628}\u{0631}\u{064E}\u{0627}\u{0647}\u{0650}\u{064A}\u{0645}",
              miracleEntry: "earlier", signs: "The fire that was made cool and safe"),
        .init(id: "ProphetMusaView", name: "Musa", arabic: "\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649}",
              miracleEntry: "earlier", signs: "The staff, the hand, and the parting of the sea"),
        .init(id: "ProphetDawudView", name: "Dawud", arabic: "\u{062F}\u{064E}\u{0627}\u{0648}\u{064F}\u{0648}\u{062F}",
              miracleEntry: "others", signs: "Iron softened in his hands; the mountains echoing him"),
        .init(id: "ProphetSulaymanView", name: "Sulayman", arabic: "\u{0633}\u{064F}\u{0644}\u{064E}\u{064A}\u{0645}\u{064E}\u{0627}\u{0646}",
              miracleEntry: "others", signs: "The wind, the jinn, and the speech of birds and ants"),
        .init(id: "ProphetYunusView", name: "Yunus", arabic: "\u{064A}\u{064F}\u{0648}\u{0646}\u{064F}\u{0633}",
              miracleEntry: "others", signs: "Kept alive in the belly of the whale"),
        .init(id: "ProphetIsaView", name: "Isa", arabic: "\u{0639}\u{0650}\u{064A}\u{0633}\u{064E}\u{0649}",
              miracleEntry: "earlier", signs: "Speech in the cradle, healing, and the dead raised"),
        .init(id: "ProphetMuhammadView", name: "Muhammad", arabic: "\u{0645}\u{064F}\u{062D}\u{064E}\u{0645}\u{064E}\u{0651}\u{062F}",
              miracleEntry: "quran", signs: "The Quran, the splitting of the moon, and more"),
    ]

    /// The prophets whose signs one miracles article covers.
    static func forEntry(_ entryID: String) -> [ProphetSigns] {
        all.filter { $0.miracleEntry == entryID }
    }

    /// The signs article for a prophet page, if the library covers him.
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

    private var signs: ProphetSigns? { ProphetSignsIndex.forProphet(article) }

    var body: some View {
        if let signs, let entry = ProphetMiraclesView.entries.first(where: { $0.id == signs.miracleEntry }) {
            Section(header: ArticleHeader("HIS MIRACLES")) {
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
                            Text(signs.signs)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Read it in Miracles of the Prophets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
            // The whole section is ONE row, so the door is a Button writing one state and the
            // destination hangs off the enclosing List - never a second NavigationLink in the row.
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
