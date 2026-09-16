import SwiftUI

// Theme highlights: light a theme's ayahs, or a surah's passages, in the reader.
//
// Browse by Theme lists what the Quran says about a subject; this lets that list follow the reader
// home. A lit theme washes every ayah it names, in both readers, in the colour of what it speaks
// about - one of the seven meanings of Tilawa's colour legend (`ThemeColorGuide`) - faint enough to
// sit behind the text (the bookmark highlighter's grammar, deliberately fainter than Tilawa's).
// Passages joined the themes on 2026-09-16, ported from Tilawa's thematic highlighting (Jamil
// Hammoudeh, with permission): a surah's outline can be washed passage by passage, every passage
// of the Quran at once or only the ones the reader picks, each in its meaning's colour.

/// The seven washes, one per meaning: the colour legend. The case order is the legend's.
enum ThemeWashColor: String, Codable, CaseIterable, Identifiable {
    case signs, prophets, law, stories, quran, afterlife, hell

    var id: String { rawValue }

    /// The colour's plain name ("Lit in blue").
    var name: String {
        switch self {
        case .signs: return "blue"
        case .prophets: return "green"
        case .law: return "brown"
        case .stories: return "yellow"
        case .quran: return "purple"
        case .afterlife: return "orange"
        case .hell: return "red"
        }
    }

    /// What the colour stands for.
    var meaning: String {
        switch self {
        case .signs: return "Signs of Allah"
        case .prophets: return "The Prophet and the Believers"
        case .law: return "Rulings and Worship"
        case .stories: return "Stories of the Prophets"
        case .quran: return "The Quran and Human Nature"
        case .afterlife: return "The Hereafter"
        case .hell: return "Hellfire"
        }
    }

    /// The legend's line under each meaning (Tilawa's wording).
    var legendDescription: String {
        switch self {
        case .signs: return "The signs of Allah, evidence of His power and oneness, and the grace He gives to His creation."
        case .prophets: return "The traits and honors of the Prophet, the attributes of believers, their rewards, and descriptions of Paradise."
        case .law: return "Legal rulings, obligations, transactions, family matters, boundaries, and worship practice."
        case .stories: return "Stories of messengers and prophets, their biographies, miracles, and the histories of earlier nations."
        case .quran: return "The Quran and revelation, human character, denial and arrogance, false accusations, and Allah's way with creation."
        case .afterlife: return "The Day of Resurrection, its signs and warnings, death, the grave, the reckoning, and scenes of Judgment."
        case .hell: return "Hell, its descriptions, and the torment of the polytheists and disbelievers."
        }
    }

    var symbol: String {
        switch self {
        case .signs: return "sparkles"
        case .prophets: return "person.2.fill"
        case .law: return "scroll.fill"
        case .stories: return "book.closed.fill"
        case .quran: return "text.book.closed.fill"
        case .afterlife: return "hourglass"
        case .hell: return "flame.fill"
        }
    }

    /// Tilawa's hexes, so a passage wears the same colour in both apps.
    var hex: String {
        switch self {
        case .signs: return "3B5BFF"
        case .prophets: return "22C55E"
        case .law: return "A67C52"
        case .stories: return "D6D84F"
        case .quran: return "A855F7"
        case .afterlife: return "FB923C"
        case .hell: return "EF4444"
        }
    }

    var color: Color {
        switch self {
        case .signs: return Color(red: 0.23, green: 0.36, blue: 1.00)
        case .prophets: return Color(red: 0.13, green: 0.77, blue: 0.37)
        case .law: return Color(red: 0.65, green: 0.49, blue: 0.32)
        case .stories: return Color(red: 0.84, green: 0.85, blue: 0.31)
        case .quran: return Color(red: 0.66, green: 0.33, blue: 0.97)
        case .afterlife: return Color(red: 0.98, green: 0.57, blue: 0.24)
        case .hell: return Color(red: 0.94, green: 0.27, blue: 0.27)
        }
    }

    /// The row wash, in step with the bookmark highlighter's (`AyahHighlightColor.tintOpacity`), a touch
    /// stronger for the two colours that vanish at that strength: the pale yellow and the brown read as
    /// nothing at all on a white page at 0.10.
    func tintOpacity(_ scheme: ColorScheme) -> Double {
        switch self {
        case .stories: return scheme == .dark ? 0.26 : 0.30
        case .law: return scheme == .dark ? 0.20 : 0.18
        default: return scheme == .dark ? 0.16 : 0.12
        }
    }

    func tint(_ scheme: ColorScheme) -> Color {
        color.opacity(tintOpacity(scheme))
    }

    /// Lenient decode: the seven arbitrary slots lit themes wore before the legend (amber, teal, ...)
    /// resolve to a meaning so an old install's lit themes still decode; `load()` re-colours them
    /// from the topic itself anyway.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if let known = ThemeWashColor(rawValue: raw) {
            self = known
            return
        }
        switch raw {
        case "amber", "coral": self = .afterlife
        case "teal", "sky": self = .signs
        case "violet": self = .quran
        case "rose": self = .hell
        case "lime": self = .prophets
        default: self = .signs
        }
    }

    #if os(iOS)
    private static var pageWashCache: [ThemeWashColor: UIColor] = [:]

    /// The page reader's wash for this colour, built once per colour (see `AyahHighlightColor.pageWashUIColor`).
    var pageWashUIColor: UIColor {
        if let cached = Self.pageWashCache[self] { return cached }
        let base = UIColor(color)
        let light = tintOpacity(.light)
        let dark = tintOpacity(.dark)
        let wash = UIColor { traits in
            base.withAlphaComponent(traits.userInterfaceStyle == .dark ? dark : light)
        }
        Self.pageWashCache[self] = wash
        return wash
    }
    #endif
}

#if os(iOS)
/// Which themes and passages are lit in the reader, and which ayah wears which colour.
@MainActor
final class ThemeHighlights: ObservableObject {
    static let shared = ThemeHighlights()

    struct LitTheme: Codable, Identifiable, Equatable {
        /// The topic id (`ThemeTopic.id`).
        let id: String
        let name: String
        let color: ThemeWashColor
        /// "surah:ayah" keys, so the wash needs no store at render time.
        let ayahs: [String]

        var count: Int { ayahs.count }
    }

    /// How many themes can be lit at once. Passages have no limit: the whole Quran is 741 of them.
    static let limit = 7
    private static let storageKey = "themeHighlightsLit"
    private static let allSectionsKey = "themeHighlightsAllSections"
    private static let sectionsKey = "themeHighlightsSections"

    @Published private(set) var lit: [LitTheme] = []
    /// Every passage of every surah washed in its meaning's colour: Tilawa's "Thematic Highlighting" switch.
    @Published private(set) var allSectionsLit = false
    /// The passages lit one by one (`SurahSection.id`), when the whole Quran is not.
    @Published private(set) var litSectionIDs: Set<String> = []

    /// ayah key -> the wash it wears (the earliest-lit theme wins where two overlap).
    private var lookup: [Int: ThemeWashColor] = [:]
    /// ayah key -> the passage wash, from `allSectionsLit` or the lit passages. A lit theme wins over
    /// a passage on the ayahs both name: the theme was chosen for that ayah, the passage for a span.
    private var sectionLookup: [Int: ThemeWashColor] = [:]

    private init() {
        ObjectPublishCounter.attach(self, label: "ThemeHighlights")
        load()
        #if DEBUG && os(iOS)
        // "-litTheme <topic id>": light a theme at launch (the readers' wash cannot be toggled
        // headlessly), e.g. "-litTheme patience". "-litAllSections" washes every passage;
        // "-litSection <surah>:<order>" lights one passage (the ids `SurahSection.id` uses).
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-litTheme"), arguments.indices.contains(index + 1),
           let topic = ThematicTopicsStore.shared.topics().first(where: { $0.id == arguments[index + 1] }),
           !isLit(topic.id) {
            toggle(topic)
        }
        if arguments.contains("-litAllSections"), !allSectionsLit {
            setAllSectionsLit(true)
        }
        if let index = arguments.firstIndex(of: "-litSection"), arguments.indices.contains(index + 1),
           let section = SurahSectionsStore.shared.section(id: arguments[index + 1]), !isLit(section: section) {
            toggle(section: section)
        }
        #endif
    }

    /// Nothing lit at all: the readers skip their per-ayah lookups.
    var isEmpty: Bool { lit.isEmpty && !allSectionsLit && litSectionIDs.isEmpty }

    /// Whether any passage wash is on, for the settings row's value.
    var hasPassages: Bool { allSectionsLit || !litSectionIDs.isEmpty }

    /// One line for a settings row: "Off", "All passages", "3 passages · 1 theme".
    var summary: String {
        if allSectionsLit { return lit.isEmpty ? "All passages" : "All passages · \(lit.count) theme\(lit.count == 1 ? "" : "s")" }
        var parts: [String] = []
        if !litSectionIDs.isEmpty { parts.append("\(litSectionIDs.count) passage\(litSectionIDs.count == 1 ? "" : "s")") }
        if !lit.isEmpty { parts.append("\(lit.count) theme\(lit.count == 1 ? "" : "s")") }
        return parts.isEmpty ? "Off" : parts.joined(separator: " · ")
    }

    // MARK: Themes

    func isLit(_ topicID: String) -> Bool {
        lit.contains { $0.id == topicID }
    }

    func color(for topicID: String) -> ThemeWashColor? {
        lit.first { $0.id == topicID }?.color
    }

    /// Lights the theme in its meaning's colour, or puts it out if it is lit. At the limit, the oldest
    /// lit theme makes room.
    func toggle(_ topic: ThemeTopic) {
        if isLit(topic.id) {
            remove(topic.id)
            return
        }
        var next = lit
        if next.count >= Self.limit { next.removeFirst() }
        next.append(LitTheme(id: topic.id, name: topic.name, color: ThemeColorGuide.color(for: topic), ayahs: topic.ayahs))
        lit = next
        rebuild()
        save()
    }

    func remove(_ topicID: String) {
        lit.removeAll { $0.id == topicID }
        rebuild()
        save()
    }

    /// Puts out every lit theme (the passages keep their state; `clearSections` is theirs).
    func clear() {
        lit = []
        rebuild()
        save()
    }

    // MARK: Passages

    func isLit(section: SurahSection) -> Bool {
        allSectionsLit || litSectionIDs.contains(section.id)
    }

    /// Lights one passage, or puts it out. Turning a passage off while every passage is lit leaves the
    /// switch on: the whole Quran is the mode, one passage is not an exception to it.
    func toggle(section: SurahSection) {
        guard !allSectionsLit else { return }
        if litSectionIDs.contains(section.id) {
            litSectionIDs.remove(section.id)
        } else {
            litSectionIDs.insert(section.id)
        }
        rebuildSections()
        saveSections()
    }

    /// The whole Quran, passage by passage. Turning it on keeps the hand-picked passages for when it
    /// is turned off again.
    func setAllSectionsLit(_ on: Bool) {
        guard allSectionsLit != on else { return }
        allSectionsLit = on
        rebuildSections()
        saveSections()
    }

    func clearSections() {
        allSectionsLit = false
        litSectionIDs = []
        rebuildSections()
        saveSections()
    }

    /// How many of this surah's passages are lit.
    func litSectionCount(inSurah surah: Int) -> Int {
        let sections = SurahSectionsStore.shared.sections(surah: surah)
        if allSectionsLit { return sections.count }
        return sections.filter { litSectionIDs.contains($0.id) }.count
    }

    // MARK: Lookup

    /// The wash this ayah wears, if a lit theme or passage names it. An integer key: the readers ask
    /// per row per body, and the "s:a" string this built per call was the cost, not the lookup.
    func wash(surah: Int, ayah: Int) -> ThemeWashColor? {
        let key = surah * 1000 + ayah
        if !lookup.isEmpty, let color = lookup[key] { return color }
        if !sectionLookup.isEmpty { return sectionLookup[key] }
        return nil
    }

    private func rebuild() {
        var table: [Int: ThemeWashColor] = [:]
        for theme in lit {
            for key in theme.ayahs {
                let parts = key.split(separator: ":")
                guard parts.count == 2, let surah = Int(parts[0]), let ayah = Int(parts[1]) else { continue }
                let slot = surah * 1000 + ayah
                if table[slot] == nil { table[slot] = theme.color }
            }
        }
        lookup = table
    }

    private func rebuildSections() {
        guard allSectionsLit || !litSectionIDs.isEmpty else {
            sectionLookup = [:]
            return
        }
        let store = SurahSectionsStore.shared
        let chosen = allSectionsLit ? store.allSections() : litSectionIDs.compactMap { store.section(id: $0) }
        var table: [Int: ThemeWashColor] = [:]
        // Widest first, so a narrower passage nested inside it paints over it: where the outline has a
        // passage within a passage, the more specific one is the one to read.
        for section in chosen.sorted(by: { $0.ayahCount > $1.ayahCount }) {
            let color = store.color(for: section)
            for ayah in section.ayahStart...section.ayahEnd {
                table[section.surahID * 1000 + ayah] = color
            }
        }
        sectionLookup = table
    }

    // MARK: Persistence

    private func save() {
        if lit.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        } else if let data = try? JSONEncoder().encode(lit) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func saveSections() {
        UserDefaults.standard.set(allSectionsLit, forKey: Self.allSectionsKey)
        if litSectionIDs.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.sectionsKey)
        } else {
            UserDefaults.standard.set(Array(litSectionIDs).sorted(), forKey: Self.sectionsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([LitTheme].self, from: data) {
            // Re-coloured by meaning: a theme lit before the legend wore whichever slot was free.
            lit = Array(saved.prefix(Self.limit)).map { theme in
                LitTheme(id: theme.id, name: theme.name,
                         color: ThemeColorGuide.color(forTopicNamed: theme.name, id: theme.id),
                         ayahs: theme.ayahs)
            }
            rebuild()
        }
        allSectionsLit = UserDefaults.standard.bool(forKey: Self.allSectionsKey)
        litSectionIDs = Set(UserDefaults.standard.stringArray(forKey: Self.sectionsKey) ?? [])
        rebuildSections()
    }
}
#endif
