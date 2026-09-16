#if os(iOS)
import SwiftUI

// The depth behind each of the 99 Names: a browsing theme (nine groups), the Arabic root, a short
// explanation with a concrete illustration, one line on what believing the name asks of a person,
// and every place the Quran names it, with the word tinted in the ayah. The authored copy is
// Tilawa's (Jamil Hammoudeh, with permission); the occurrences are located in this app's own Hafs
// text from the name's own references. Built by Scripts/build_names_details.py into
// Resources/Data/Islam/NamesDetails.json.xz.

struct NameDepth {
    struct Verse: Identifiable {
        let surah: Int
        let ayah: Int
        /// 0-based token index of the name's word in the raw Hafs text, -1 when the verse carries
        /// the attribute in another form (a verb, a plural) and nothing is tinted.
        let tokenStart: Int
        let tokenCount: Int

        var id: String { "\(surah):\(ayah)" }
        var tokens: [Int] { tokenStart >= 0 ? Array(tokenStart..<(tokenStart + tokenCount)) : [] }
    }

    let theme: String
    let root: String
    let explanation: String
    let living: String
    let verses: [Verse]
}

final class NamesDetailsStore: @unchecked Sendable {
    static let shared = NamesDetailsStore()

    struct Theme: Identifiable, Equatable {
        let id: String
        let label: String
    }

    static var packURL: URL? {
        Bundle.main.url(forResource: "NamesDetails", withExtension: "json.xz", subdirectory: "Data/Islam")
            ?? Bundle.main.url(forResource: "NamesDetails", withExtension: "json.xz", subdirectory: "Islam")
            ?? Bundle.main.url(forResource: "NamesDetails", withExtension: "json.xz")
    }

    static let isBundled: Bool = packURL != nil

    private let lock = NSLock()
    private var loaded: (themes: [Theme], names: [Int: NameDepth])?
    private var loadFailed = false
    private var loading = false

    /// Flips on the main thread when the pack has parsed: the chips row observes it, so the Names
    /// list body never parses the pack itself (Tilawa Guide, Phase 6 step 6).
    final class Readiness: ObservableObject {
        @Published fileprivate(set) var isLoaded = false
    }
    let readiness = Readiness()

    private init() {}

    /// Parses off-main, once; the Names screen kicks it as it appears.
    func prewarm() {
        guard Self.isBundled else { return }
        lock.lock()
        let already = loaded != nil
        let needed = loaded == nil && !loadFailed && !loading
        if needed { loading = true }
        lock.unlock()
        if already, !readiness.isLoaded {
            // Parsed by another path (the widget writer's detached build reads the depth directly):
            // the flag still has to flip for the observers that wait on it.
            DispatchQueue.main.async { self.readiness.isLoaded = true }
            return
        }
        guard needed else { return }
        DispatchQueue.global(qos: .utility).async {
            _ = self.library()
            self.lock.lock()
            self.loading = false
            self.lock.unlock()
            DispatchQueue.main.async { self.readiness.isLoaded = true }
        }
    }

    /// The themes when the pack is in memory, else nil (and the parse is kicked): for bodies.
    var themesIfLoaded: [Theme]? {
        lock.lock()
        let loaded = loaded
        let failed = loadFailed
        lock.unlock()
        if let loaded { return loaded.themes }
        if failed { return [] }
        prewarm()
        return nil
    }

    private func library() -> (themes: [Theme], names: [Int: NameDepth])? {
        lock.lock()
        if let loaded { lock.unlock(); return loaded }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()
        let parsed = Self.load()
        lock.lock(); defer { lock.unlock() }
        if let loaded { return loaded }
        if let parsed {
            loaded = parsed
            return parsed
        }
        loadFailed = true
        return nil
    }

    var themes: [Theme] { library()?.themes ?? [] }

    func detail(_ number: Int) -> NameDepth? { library()?.names[number] }

    func themeLabel(_ id: String) -> String {
        themes.first { $0.id == id }?.label ?? id.capitalized
    }

    private static func load() -> (themes: [Theme], names: [Int: NameDepth])? {
        PackTrace.measure("NamesDetails") { () -> (result: (themes: [Theme], names: [Int: NameDepth])?, bytes: Int) in
            guard let url = packURL, let blob = try? Data(contentsOf: url),
                  let json = SolidPack.xzDecompress(blob) else { return (nil, 0) }
            return (parse(json), json.count)
        }
    }

    private static func parse(_ json: Data) -> (themes: [Theme], names: [Int: NameDepth])? {
        guard let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
              let rows = root["names"] as? [String: [String: Any]] else { return nil }
        let themes = (root["themes"] as? [[String: Any]] ?? []).compactMap { row -> Theme? in
            guard let id = row["id"] as? String, let label = row["label"] as? String else { return nil }
            return Theme(id: id, label: label)
        }
        var names: [Int: NameDepth] = [:]
        for (key, row) in rows {
            guard let number = Int(key) else { continue }
            let verses = (row["verses"] as? [[Int]] ?? []).compactMap { parts -> NameDepth.Verse? in
                guard parts.count == 4 else { return nil }
                return NameDepth.Verse(surah: parts[0], ayah: parts[1], tokenStart: parts[2], tokenCount: parts[3])
            }
            names[number] = NameDepth(theme: row["theme"] as? String ?? "",
                                      root: row["root"] as? String ?? "",
                                      explanation: row["explanation"] as? String ?? "",
                                      living: row["living"] as? String ?? "",
                                      verses: verses)
        }
        return names.isEmpty ? nil : (themes, names)
    }
}

// MARK: - Theme chips

/// The nine ways to browse the 99: a row of capsules over the list, one lit at a time.
struct NameThemeChips: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var readiness = NamesDetailsStore.shared.readiness
    @Binding var active: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", id: nil)
                // Nil until the pack has parsed off-main; `readiness` re-evaluates this row then.
                ForEach(NamesDetailsStore.shared.themesIfLoaded ?? []) { theme in
                    chip(theme.label, id: theme.id)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(_ label: String, id: String?) -> some View {
        let lit = active == id
        return Button {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) { active = id }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(lit ? .white : appearance.accent)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(Capsule().fill(lit ? appearance.accent : appearance.accent.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The name's page

/// One name in full: the hero, its theme and root, what it means, what living by it asks, the
/// other names it goes by, and every verse that names it, the word tinted.
struct NameDetailView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var quranData = QuranData.shared

    let name: NameOfAllah

    private var accent: Color { appearance.accent }
    private var depth: NameDepth? { NamesDetailsStore.shared.detail(name.number) }

    var body: some View {
        let _ = RenderCounter.hit("NameDetailView")
        List {
            Group {
                heroSection

                if let depth {
                    if !depth.explanation.isEmpty {
                        Section(header: Text("WHAT IT MEANS")) {
                            SelectableProse(text: depth.explanation)
                                .padding(.vertical, 2)
                        }
                    }
                    if !depth.living.isEmpty {
                        Section(header: Text("LIVING BY IT")) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "figure.walk")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(accent)
                                    .padding(.top, 2)
                                Text(depth.living)
                                    .font(.subheadline.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !name.desc.isEmpty || !name.otherNames.isEmpty {
                    Section(header: Text("ALSO KNOWN AS")) {
                        VStack(alignment: .leading, spacing: 8) {
                            if !name.desc.isEmpty {
                                Text(name.desc)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if !name.otherNames.isEmpty {
                                FlowLayoutView(spacing: 6) {
                                    ForEach(name.otherNames, id: \.self) { other in
                                        Text(other)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(accent)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(accent.opacity(0.12)))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                versesSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(name.transliteration)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroSection: some View {
        Section {
            VStack(spacing: 8) {
                Text("\(name.number) of 99")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(name.displayArabicName)
                    .font(appearance.useFontArabic ? Font.arabic(appearance.islamArabicFontName, size: 48) : .system(size: 42, weight: .semibold))
                    .arabicFontDesign(custom: appearance.useFontArabic && appearance.islamArabicFontName != Settings.systemArabicFontName)
                    .foregroundColor(accent)
                    .multilineTextAlignment(.center)
                    .softShadow(color: accent.opacity(0.22), radius: 12)
                    .padding(.top, 4)

                Text(name.transliteration)
                    .font(.title3.weight(.bold))

                Text(name.meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let depth {
                    HStack(spacing: 8) {
                        chip(NamesDetailsStore.shared.themeLabel(depth.theme), systemImage: "square.grid.2x2")
                        if !depth.root.isEmpty {
                            chip("Root " + depth.root, systemImage: nil)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [accent.opacity(0.16), accent.opacity(0.05)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .padding(.vertical, 2)
        }
    }

    private func chip(_ text: String, systemImage: String?) -> some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(accent)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(accent.opacity(0.12)))
    }

    @ViewBuilder
    private var versesSection: some View {
        let verses = depth?.verses ?? []
        Section(header: SectionPillHeader(title: "IN THE QURAN", count: verses.count)) {
            if verses.isEmpty {
                Text("The Quran carries this attribute in other wordings rather than in this exact name.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(verses) { verse in
                    if let surah = quranData.surah(verse.surah),
                       let ayah = quranData.ayah(surah: verse.surah, ayah: verse.ayah) {
                        NavigationLink(destination: LazyDestination { SurahView(surah: surah, ayah: verse.ayah) }) {
                            WordOccurrenceRow(surah: surah, ayah: ayah, tokens: verse.tokens,
                                              caption: verse.tokens.isEmpty ? "Named in another form here" : nil)
                                .equatable()
                        }
                    }
                }
            }
        }
    }
}

/// The door from a name's row into its page.
struct NameDetailLink: View {
    @Environment(\.appearance) private var appearance
    let name: NameOfAllah

    var body: some View {
        NavigationLink(destination: LazyDestination { NameDetailView(name: name) }) {
            HStack(spacing: 6) {
                Image(systemName: "text.book.closed")
                    .font(.caption.weight(.semibold))
                Text("More about this name")
                    .font(.caption.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundColor(appearance.accent)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .conditionalGlassEffect(useColor: 0.2)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }
}
#endif
