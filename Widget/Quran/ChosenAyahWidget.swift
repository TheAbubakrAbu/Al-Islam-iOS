import SwiftUI
import WidgetKit
import AppIntents

// The configurable Quran widget (Abu, 2026-09-28): one ayah the person picks, from the bookmarks or
// by typing a reference, on the home screen (small, medium) and the lock screen (rectangular, and
// the inline line above the clock). The configuration lives in ChosenAyahIntent.swift, shared with
// the app; the look is the shared `QuranWidgetEntryView`, so it matches the other ayah widgets.
//
// Where the text comes from, in order:
//   1. the card the APP pre-rendered for this ayah (`QuranWidgetSnapshot.chosenAyahs`): the reader's
//      font, tajweed colors and clean-text setting, written whenever the app runs
//      (`Settings.refreshChosenAyahWidgets`);
//   2. quran.qpk, read from the containing app bundle (`QuranPackLoader.url`): the plain vocalized
//      Hafs text in the reader's face, for an ayah chosen while the app was not running;
//   3. the bookmark's translation snippet alone, if even the pack is out of reach.

@available(iOS 17.0, *)
struct ChosenAyahProvider: AppIntentTimelineProvider {
    typealias Entry = QuranWidgetEntry
    typealias Intent = ChosenAyahConfigurationIntent

    /// The accent, from the App Group mirror (the same read as `QuranWidgetProvider`).
    private static let accent: AccentColor = {
        let store = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)
        return AccentColor(rawValue: store?.string(forKey: "accentColor") ?? AppIdentifiers.mainColorString) ?? AppIdentifiers.mainColor
    }()

    func placeholder(in context: Context) -> QuranWidgetEntry { Self.sample }

    func snapshot(for configuration: Intent, in context: Context) async -> QuranWidgetEntry {
        context.isPreview ? Self.sample : Self.entry(for: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<QuranWidgetEntry> {
        // Only the app (a re-rendered card, a changed bookmark) or a configuration change moves this
        // widget, and both reload the timeline; nothing here changes with the clock.
        Timeline(entries: [Self.entry(for: configuration)], policy: .never)
    }

    /// The gallery preview and the loading placeholder: representative, never blank.
    static var sample: QuranWidgetEntry {
        QuranWidgetEntry(
            date: Date(),
            kind: .chosenAyah,
            title: ChosenAyahCatalog.reference(surah: 1, ayah: 1),
            icon: QuranWidgetKind.chosenAyah.icon,
            primaryText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            secondaryText: nil,
            tertiaryText: "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
            accentColor: accent
        )
    }

    static func entry(for configuration: Intent) -> QuranWidgetEntry {
        let snapshot = QuranWidgetStore.load()
        let target = configuration.resolvedAyah(bookmarks: snapshot?.bookmarks)
        let bookmark = snapshot?.bookmarks?.first { $0.surah == target.surah && $0.ayah == target.ayah }
        let reference = ChosenAyahCatalog.reference(surah: target.surah, ayah: target.ayah)

        let card = snapshot?.chosenCard(surah: target.surah, ayah: target.ayah)
            ?? ChosenAyahText.card(surah: target.surah, ayah: target.ayah, fontName: snapshot?.arabicFontName)
        let arabic = (card?.arabic ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let english = (card?.english ?? bookmark?.english ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let note = bookmark?.note?.trimmingCharacters(in: .whitespacesAndNewlines)

        // No text from any source (no pack, no card, no bookmark): say what the app will do rather
        // than draw an empty tile. The next app launch pre-renders the card and reloads this.
        let hasArabic = !arabic.isEmpty
        let primary = hasArabic ? arabic : (english.isEmpty ? "Open \(AppIdentifiers.appName) once to load this ayah." : english)
        let translation: String? = {
            guard configuration.showTranslation, hasArabic, !english.isEmpty else { return nil }
            return snippet(english)
        }()

        return QuranWidgetEntry(
            date: Date(),
            kind: .chosenAyah,
            title: reference,
            icon: bookmark != nil ? "bookmark.fill" : "text.quote",
            primaryText: primary,
            secondaryText: (note?.isEmpty == false) ? note : nil,
            tertiaryText: translation,
            accentColor: accent,
            arabicFontName: hasArabic ? card?.fontName : nil,
            arabicColorRuns: hasArabic ? card?.colorRuns : nil,
            deepLink: QuranDeepLink.ayah(surah: target.surah, ayah: target.ayah)
        )
    }

    private static func snippet(_ text: String, maxLength: Int = 120) -> String {
        guard text.count > maxLength else { return text }
        return String(text.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}

/// The pack fallback: the ayah's text straight out of quran.qpk. The pack is memory-mapped and only
/// the block holding this ayah is inflated, so a widget refresh costs one LZMA block, not the Quran;
/// it is opened per read and released after it (a pack kept for the process held ~3 MB of the
/// widget's ~30 MB for good).
enum ChosenAyahText {
    static func card(surah: Int, ayah: Int, fontName: String?) -> QuranWidgetSnapshot.AyahCard? {
        guard let pack = QuranPackLoader.url("quran", allowContainingApp: true).flatMap({ QuranPack(url: $0) }),
              let meta = pack.surahs.first(where: { $0.id == surah }),
              (1...meta.numberOfAyahs).contains(ayah),
              let text = pack.text(row: meta.firstRow + ayah - 1) else { return nil }
        return QuranWidgetSnapshot.AyahCard(
            arabic: text.arabic,
            reference: "Surah \(surah):\(ayah) • \(meta.nameTransliteration)",
            english: text.englishSaheeh,
            // The reader's face when the app has written one; the Uthmani face (bundled with the
            // widget) until then. A face the widget does not bundle falls back to the system font.
            fontName: fontName ?? Settings.hafsUthmaniFontName,
            colorRuns: nil,
            surah: surah,
            ayah: ayah
        )
    }
}

@available(iOS 17.0, *)
struct ChosenAyahWidget: Widget {
    let kind: String = "ChosenAyahWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ChosenAyahConfigurationIntent.self, provider: ChosenAyahProvider()) { entry in
            QuranWidgetEntryView(entry: entry)
        }
        .supportedFamilies(chosenAyahWidgetFamilies())
        .configurationDisplayName("Chosen Ayah")
        .description("An ayah you choose: one of your bookmarks, or any reference you type. Hold the widget and choose Edit Widget to pick it.")
    }
}

/// The reading widgets' families plus the inline line above the lock screen clock.
func chosenAyahWidgetFamilies() -> [WidgetFamily] {
    if #available(iOS 16.0, *) {
        return [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline]
    }
    return [.systemSmall, .systemMedium]
}
