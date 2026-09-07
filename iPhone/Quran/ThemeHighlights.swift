import SwiftUI

// Theme highlights: light a theme's ayahs in the reader.
//
// Browse by Theme lists what the Quran says about a subject; this lets that list follow the reader
// home. A lit theme washes every ayah it names, in both readers, in its own faint color (the same
// 0.14 / 0.10 wash the bookmark highlighter uses, deliberately fainter than Tilawa's), so a reader
// walking al-Baqarah sees where "Patience" or "The Hereafter" surface without leaving the page.
// Up to seven themes at once, one color each. Ported from Tilawa's thematic highlighting (Jamil
// Hammoudeh, with permission).

/// The seven washes a lit theme can wear.
enum ThemeWashColor: String, Codable, CaseIterable, Identifiable {
    case amber, teal, violet, rose, sky, lime, coral

    var id: String { rawValue }

    var name: String {
        switch self {
        case .amber: return "Amber"
        case .teal: return "Teal"
        case .violet: return "Violet"
        case .rose: return "Rose"
        case .sky: return "Sky"
        case .lime: return "Lime"
        case .coral: return "Coral"
        }
    }

    var color: Color {
        switch self {
        case .amber: return Color(red: 1.00, green: 0.72, blue: 0.16)
        case .teal: return Color(red: 0.16, green: 0.72, blue: 0.68)
        case .violet: return Color(red: 0.62, green: 0.42, blue: 0.96)
        case .rose: return Color(red: 0.98, green: 0.36, blue: 0.56)
        case .sky: return Color(red: 0.24, green: 0.60, blue: 0.98)
        case .lime: return Color(red: 0.56, green: 0.80, blue: 0.22)
        case .coral: return Color(red: 0.98, green: 0.50, blue: 0.32)
        }
    }

    /// The row wash, in step with the bookmark highlighter's (`AyahHighlightColor.tintOpacity`).
    func tint(_ scheme: ColorScheme) -> Color {
        color.opacity(scheme == .dark ? 0.14 : 0.10)
    }

    #if os(iOS)
    private static var pageWashCache: [ThemeWashColor: UIColor] = [:]

    /// The page reader's wash for this color, built once per color (see `AyahHighlightColor.pageWashUIColor`).
    var pageWashUIColor: UIColor {
        if let cached = Self.pageWashCache[self] { return cached }
        let base = UIColor(color)
        let wash = UIColor { traits in
            base.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.14 : 0.10)
        }
        Self.pageWashCache[self] = wash
        return wash
    }
    #endif
}

#if os(iOS)
/// Which themes are lit in the reader, and which ayah wears which color.
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

    static let limit = ThemeWashColor.allCases.count
    private static let storageKey = "themeHighlightsLit"

    @Published private(set) var lit: [LitTheme] = []
    /// ayah key -> the wash it wears (the earliest-lit theme wins where two overlap).
    private var lookup: [String: ThemeWashColor] = [:]

    private init() {
        load()
        #if DEBUG && os(iOS)
        // "-litTheme <topic id>": light a theme at launch (the readers' wash cannot be toggled
        // headlessly), e.g. "-litTheme patience".
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-litTheme"), arguments.indices.contains(index + 1),
           let topic = ThematicTopicsStore.shared.topics().first(where: { $0.id == arguments[index + 1] }),
           !isLit(topic.id) {
            toggle(topic)
        }
        #endif
    }

    var isEmpty: Bool { lit.isEmpty }

    func isLit(_ topicID: String) -> Bool {
        lit.contains { $0.id == topicID }
    }

    func color(for topicID: String) -> ThemeWashColor? {
        lit.first { $0.id == topicID }?.color
    }

    /// The color the next lit theme would take.
    var nextColor: ThemeWashColor {
        let used = Set(lit.map(\.color))
        return ThemeWashColor.allCases.first { !used.contains($0) } ?? lit.first?.color ?? .amber
    }

    /// Lights the theme, or puts it out if it is lit. At the limit, the oldest lit theme makes room.
    func toggle(_ topic: ThemeTopic) {
        if isLit(topic.id) {
            remove(topic.id)
            return
        }
        var next = lit
        if next.count >= Self.limit { next.removeFirst() }
        let color = ThemeWashColor.allCases.first { color in !next.contains { $0.color == color } } ?? .amber
        next.append(LitTheme(id: topic.id, name: topic.name, color: color, ayahs: topic.ayahs))
        lit = next
        rebuild()
        save()
    }

    func remove(_ topicID: String) {
        lit.removeAll { $0.id == topicID }
        rebuild()
        save()
    }

    func clear() {
        lit = []
        rebuild()
        save()
    }

    /// The wash this ayah wears, if any lit theme names it.
    func wash(surah: Int, ayah: Int) -> ThemeWashColor? {
        lookup.isEmpty ? nil : lookup["\(surah):\(ayah)"]
    }

    private func rebuild() {
        var table: [String: ThemeWashColor] = [:]
        for theme in lit {
            for key in theme.ayahs where table[key] == nil { table[key] = theme.color }
        }
        lookup = table
    }

    private func save() {
        if lit.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        } else if let data = try? JSONEncoder().encode(lit) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let saved = try? JSONDecoder().decode([LitTheme].self, from: data) else { return }
        lit = Array(saved.prefix(Self.limit))
        rebuild()
    }
}
#endif
