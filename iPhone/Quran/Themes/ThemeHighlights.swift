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

    // MARK: The wash

    /// The wash on a WHITE page, as OKLCH: lightness, chroma (how much colour), hue. OKLCH is a
    /// perceptual space, so equal steps in it look equal.
    ///
    /// Until 2026-10-10 a wash was `color` at a low opacity (0.095, with 0.22 for yellow and 0.14 for
    /// brown). Measured, that film was mostly grey: it darkened the page but carried almost no colour
    /// (chroma 0.010 to 0.039, brown's 0.010 practically none), so no opacity worked. Fainter, and the
    /// colours could not be told apart; stronger, and the page went heavy before they could (Abu: "if
    /// its too strong its too strong but if its too weak then i cant differentiate yellow and green").
    /// These spend the strength on colour instead: 1.2 to 2.7 times the colour, as much as sRGB holds
    /// that close to white, for a page only a shade darker (orange, red and purple, which sRGB keeps
    /// palest there, gave up the most lightness for theirs). Yellow and green have room for the most,
    /// so they are butter and mint; yellow is warmer than the legend's own (at that hue a pale wash
    /// reads lime), blue leans to sky (it sat 31 degrees from purple), and brown alone stays nearly
    /// grey and a step darker, sand beside orange's apricot. In OKLab distance yellow and green went
    /// from 0.031 apart to 0.060, and the closest pair of all from 0.013 (blue and purple) to 0.021.
    ///
    /// The opacity trip before this, light / dark: 0.10 / 0.14 (the bookmark highlighter's, 09-16),
    /// 0.065 / 0.09 (09-20, "the opacity is too strong"), 0.095 / 0.125 (09-22, "too light").
    private var lightTarget: (L: Double, C: Double, H: Double) {
        switch self {
        case .signs: return (0.950, 0.026, 242)
        case .prophets: return (0.958, 0.056, 157)
        case .law: return (0.933, 0.020, 76)
        case .stories: return (0.962, 0.062, 96)
        case .quran: return (0.943, 0.038, 314)
        case .afterlife: return (0.946, 0.035, 64)
        case .hell: return (0.943, 0.028, 16)
        }
    }

    /// The wash on a BLACK page, where the complaint began: a faint yellow on black is olive, so the old
    /// yellow was a lighter dark green beside the green itself, and lightness alone does not name a
    /// colour. Here yellow is gold (hue 92, out of olive's 110) and still the lightest of the seven, as
    /// yellow is the lightest colour; orange is a rust, brown a dull umber. Every wash is about as dark
    /// as before with 1.2 to 2 times the colour; the first cut went further, and the page read as
    /// coloured slabs. The closest pair went from 0.013 apart (brown and orange) to 0.040.
    private var darkTarget: (L: Double, C: Double, H: Double) {
        switch self {
        case .signs: return (0.185, 0.065, 260)
        case .prophets: return (0.205, 0.052, 153)
        case .law: return (0.195, 0.022, 72)
        case .stories: return (0.255, 0.051, 92)
        case .quran: return (0.190, 0.070, 314)
        case .afterlife: return (0.215, 0.058, 45)
        case .hell: return (0.185, 0.062, 20)
        }
    }

    /// The opacity every wash is laid at; its paint is solved so the wash lands on its target over the
    /// page's own colour. Half, rather than a faint film of a strong colour, because whatever is under a
    /// wash shows through it: at 0.095 the accent glow at the top of the reader was nine tenths of what
    /// the top lines wore, and pushed every wash up there toward the accent.
    static let washOpacity = 0.5

    /// What a wash multiplies its step by under Increase Contrast.
    private static let increasedContrastStep = 1.5

    private static let paintLock = NSLock()
    private static var paintCache: [String: WashRGB] = [:]

    /// The paint laid at `washOpacity`. On a light page the target is a STEP from the page's own colour
    /// (the step from white to `lightTarget`), so a light custom theme keeps all seven: Sepia turned the
    /// old fixed colours into seven shades of Sepia, and fixed new ones would have lightened it, brown
    /// vanishing into it. `ground` is that page (or row) colour, nil for white. A dark wash is built for
    /// black, and laid half over Gray or a dark row it holds up as it is.
    func washPaint(dark: Bool, ground: WashRGB? = nil, increaseContrast: Bool = false) -> WashRGB {
        let key = "\(rawValue)|\(dark)|\(increaseContrast)|\(dark ? "" : ground?.key ?? "")"
        Self.paintLock.lock()
        let cached = Self.paintCache[key]
        Self.paintLock.unlock()
        if let cached { return cached }

        let alpha = Self.washOpacity
        let step = increaseContrast ? Self.increasedContrastStep : 1
        let paint: WashRGB
        if dark {
            let target = darkTarget
            let hue = target.H * .pi / 180
            let landed = WashOKLab.clipped(L: target.L * step, a: 0, b: 0,
                                           da: target.C * step * cos(hue), db: target.C * step * sin(hue))
            paint = landed.scaled(by: 1 / alpha)
        } else {
            let page = ground ?? WashRGB(r: 1, g: 1, b: 1)
            let lab = WashOKLab.lab(page)
            let target = lightTarget
            let hue = target.H * .pi / 180
            let landed = WashOKLab.clipped(L: lab.L + (target.L - 1) * step, a: lab.a, b: lab.b,
                                           da: target.C * step * cos(hue), db: target.C * step * sin(hue))
            paint = landed.solvingPaint(over: page, opacity: alpha)
        }
        Self.paintLock.lock()
        Self.paintCache[key] = paint
        Self.paintLock.unlock()
        return paint
    }

    /// The wash as a SwiftUI colour: a list row, the legend, the passage list. `ground` is the row's own
    /// colour on a custom theme (nil on Light, Dark and System). On iOS it resolves light, dark and
    /// Increase Contrast from wherever it is drawn, like a system colour, so `scheme` only counts on
    /// the watch.
    func tint(_ scheme: ColorScheme, on ground: Color? = nil) -> Color {
        #if os(iOS)
        // The list asks once per row per render: one lookup, keyed by the SwiftUI colour itself, so a
        // custom theme's ground is converted and keyed once rather than on every pass.
        let key = TintKey(wash: self, ground: ground)
        Self.paintLock.lock()
        let cached = Self.tintCache[key]
        Self.paintLock.unlock()
        if let cached { return cached }
        let tint = Color(washUIColor(ground: ground.map { UIColor($0) }))
        Self.paintLock.lock()
        Self.tintCache[key] = tint
        Self.paintLock.unlock()
        return tint
        #else
        let paint = washPaint(dark: scheme == .dark)
        return Color(red: paint.r, green: paint.g, blue: paint.b).opacity(Self.washOpacity)
        #endif
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
    private struct TintKey: Hashable {
        let wash: ThemeWashColor
        let ground: Color?
    }

    private static var uiColorCache: [String: UIColor] = [:]
    private static var tintCache: [TintKey: Color] = [:]
    private static var inkCache: [ThemeWashColor: Color] = [:]

    /// The colour as TEXT, for the legend's names and the passage list's labels. The swatch colours are
    /// pale (the yellow is 1.5:1 on a light page), so text takes each one moved just far enough to read
    /// at 4.5:1, 7:1 under Increase Contrast, exactly as the accent is (`AccentContrast.legibleColor`).
    var ink: Color {
        Self.paintLock.lock()
        let cached = Self.inkCache[self]
        Self.paintLock.unlock()
        if let cached { return cached }
        let ink = AccentContrast.legibleColor(UIColor(color))
        Self.paintLock.lock()
        Self.inkCache[self] = ink
        Self.paintLock.unlock()
        return ink
    }

    /// The wash as ONE dynamic UIColor per colour and ground: light or dark, and Increase Contrast,
    /// resolve from the traits it is drawn with, so a theme switch repaints the page without the
    /// composed-page cache key carrying the scheme (see `AyahHighlightColor.pageWashUIColor`). The page
    /// reader paints it as the ayah's background; `ground` is the page colour on a custom theme.
    func washUIColor(ground: UIColor? = nil) -> UIColor {
        let groundRGB = ground.map { WashRGB($0) }
        let key = "\(rawValue)|\(groundRGB?.key ?? "")"
        Self.paintLock.lock()
        let cached = Self.uiColorCache[key]
        Self.paintLock.unlock()
        if let cached { return cached }
        let alpha = CGFloat(Self.washOpacity)
        let color = UIColor { traits in
            let paint = self.washPaint(dark: traits.userInterfaceStyle == .dark, ground: groundRGB,
                                       increaseContrast: traits.accessibilityContrast == .high)
            return UIColor(red: CGFloat(paint.r), green: CGFloat(paint.g), blue: CGFloat(paint.b), alpha: alpha)
        }
        Self.paintLock.lock()
        Self.uiColorCache[key] = color
        Self.paintLock.unlock()
        return color
    }
    #endif
}

/// A colour as encoded sRGB components, 0...1: the space Core Graphics blends a wash in.
struct WashRGB: Equatable {
    var r: Double
    var g: Double
    var b: Double

    #if os(iOS)
    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(_ color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b))
    }
    #endif

    /// Two hex digits a channel, for cache keys.
    var key: String {
        String(format: "%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }

    func scaled(by factor: Double) -> WashRGB {
        WashRGB(r: min(1, r * factor), g: min(1, g * factor), b: min(1, b * factor))
    }

    /// The paint that, laid over `ground` at `opacity`, lands on this colour.
    func solvingPaint(over ground: WashRGB, opacity: Double) -> WashRGB {
        func solve(_ target: Double, _ under: Double) -> Double {
            min(1, max(0, (target - (1 - opacity) * under) / opacity))
        }
        return WashRGB(r: solve(r, ground.r), g: solve(g, ground.g), b: solve(b, ground.b))
    }
}

/// OKLab (Björn Ottosson, 2020): lightness and two colour axes, perceptually even. The washes are set
/// in it so they can be specified by how light and how colourful they look.
enum WashOKLab {
    static func lab(_ c: WashRGB) -> (L: Double, a: Double, b: Double) {
        func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        let (r, g, b) = (linear(c.r), linear(c.g), linear(c.b))
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)
    }

    /// The colour in encoded sRGB, or nil when it lies outside sRGB.
    static func rgb(L: Double, a: Double, b: Double) -> WashRGB? {
        func cube(_ v: Double) -> Double { v * v * v }
        let l = cube(L + 0.3963377774 * a + 0.2158037573 * b)
        let m = cube(L - 0.1055613458 * a - 0.0638541728 * b)
        let s = cube(L - 0.0894841775 * a - 1.2914855480 * b)
        let linear = [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                      -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s]
        guard linear.allSatisfy({ $0 >= -0.0005 && $0 <= 1.0005 }) else { return nil }
        func encoded(_ v: Double) -> Double {
            let v = min(1, max(0, v))
            return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - 0.055
        }
        return WashRGB(r: encoded(linear[0]), g: encoded(linear[1]), b: encoded(linear[2]))
    }

    /// Lightness `L` at (a, b) plus as much of the colour step (da, db) as sRGB holds: the lightness is
    /// kept exactly and the colour gives way, so a step past the gamut's edge lands on the edge.
    static func clipped(L: Double, a: Double, b: Double, da: Double, db: Double) -> WashRGB {
        if let full = rgb(L: L, a: a + da, b: b + db) { return full }
        var low = 0.0, high = 1.0
        for _ in 0..<18 {
            let mid = (low + high) / 2
            if rgb(L: L, a: a + da * mid, b: b + db * mid) != nil { low = mid } else { high = mid }
        }
        return rgb(L: L, a: a + da * low, b: b + db * low)
            ?? rgb(L: min(1, max(0, L)), a: 0, b: 0)
            ?? WashRGB(r: 0, g: 0, b: 0)
    }
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

    /// How many themes can be lit at once. Passages have no limit: the whole Quran is 744 of them.
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

    private var storageObserver: StoredContentObserver?

    private init() {
        ObjectPublishCounter.attach(self, label: "ThemeHighlights")
        load()
        storageObserver = StoredContentObserver(reload: { ThemeHighlights.shared.reloadFromStorage() })
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
           let saved = UserDataRescue.decodeList(LitTheme.self, from: data, key: Self.storageKey) {
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

    /// The lit themes on disk changed underneath this object (a restore, an erase). `load()` only
    /// ever ADDS what it finds, so the themes and their lookup are emptied first: an erase leaves
    /// no key at all, and the wash must go with it.
    private func reloadFromStorage() {
        lit = []
        lookup = [:]
        load()
    }
}
#endif
