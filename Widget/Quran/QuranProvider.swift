import SwiftUI
import WidgetKit
import UIKit

enum QuranWidgetKind {
    case lastReadAyah
    case lastListenedSurah
    case lastListenedAyah
    case ayahOfTheDay

    var title: String {
        switch self {
        case .lastReadAyah: return "Last Read Ayah"
        case .lastListenedSurah: return "Last Listened Surah"
        case .lastListenedAyah: return "Last Listened Ayah"
        case .ayahOfTheDay: return "Ayah of the Day"
        }
    }

    var icon: String {
        switch self {
        case .lastReadAyah: return "book.closed"
        case .lastListenedSurah: return "play.fill"
        case .lastListenedAyah: return "play.circle"
        case .ayahOfTheDay: return "sparkles"
        }
    }
}

struct QuranWidgetEntry: TimelineEntry {
    let date: Date
    let kind: QuranWidgetKind
    let title: String
    let icon: String
    let primaryText: String
    let secondaryText: String?
    let tertiaryText: String?
    let accentColor: AccentColor
    /// When set, `primaryText` is Arabic and should render with this font (e.g. the Uthmani font).
    var arabicFontName: String? = nil
    /// Tajweed color spans over `primaryText` (Arabic only).
    var arabicColorRuns: [QuranWidgetSnapshot.ColorRun]? = nil
}

struct QuranWidgetProvider: TimelineProvider {
    let kind: QuranWidgetKind

    // Placeholder (the redacted skeleton) and the widget-gallery preview must always show representative
    // content so they can never render blank — the app may not have written a snapshot yet (fresh install,
    // Quran data still loading), which previously left these surfaces empty.
    func placeholder(in context: Context) -> QuranWidgetEntry { sampleEntry() }

    func getSnapshot(in context: Context, completion: @escaping (QuranWidgetEntry) -> Void) {
        completion(context.isPreview ? sampleEntry() : makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuranWidgetEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
    }

    /// Representative fake data (Al-Fātiḥah 1:1) used wherever there is nothing real to show: the gallery
    /// preview, the loading placeholder, and a device with no snapshot written yet. Showing a real-looking
    /// ayah beats both a blank card and an "open the app" prompt. Rendered with the system font (no
    /// `arabicFontName`) so it displays even where the custom Uthmani font isn't available.
    private func sampleEntry() -> QuranWidgetEntry {
        let settings = Settings.shared
        switch kind {
        case .lastListenedSurah:
            return QuranWidgetEntry(
                date: Date(),
                kind: kind,
                title: kind.title,
                icon: kind.icon,
                primaryText: "Al-Fatihah",
                secondaryText: "Mishary Alafasy",
                tertiaryText: "00:42 / 01:30",
                accentColor: settings.accentColor
            )
        case .lastReadAyah, .lastListenedAyah, .ayahOfTheDay:
            return QuranWidgetEntry(
                date: Date(),
                kind: kind,
                title: kind.title,
                icon: kind.icon,
                primaryText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                secondaryText: "Surah 1:1 • Al-Fatihah",
                tertiaryText: "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
                accentColor: settings.accentColor
            )
        }
    }

    private func makeEntry() -> QuranWidgetEntry {
        let settings = Settings.shared
        let snapshot = QuranWidgetStore.load()

        switch kind {
        case .lastReadAyah:
            return makeAyahEntry(settings: settings, card: snapshot?.lastRead)
        case .lastListenedSurah:
            return makeLastListenedEntry(settings: settings, card: snapshot?.lastListened)
        case .lastListenedAyah:
            return makeAyahEntry(settings: settings, card: snapshot?.lastListenedAyah)
        case .ayahOfTheDay:
            return makeAyahEntry(settings: settings, card: snapshot?.ayahOfTheDay ?? ayahOfTheDayCard(from: snapshot))
        }
    }

    private func makeAyahEntry(settings: Settings, card: QuranWidgetSnapshot.AyahCard?) -> QuranWidgetEntry {
        // Treat a card whose text is empty as missing, so a partially-written/blank card falls back to the
        // sample ayah rather than rendering an empty widget body.
        guard let card,
              !card.arabic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !card.english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return sampleEntry()
        }
        return QuranWidgetEntry(
            date: Date(),
            kind: kind,
            title: kind.title,
            icon: kind.icon,
            primaryText: card.arabic,
            secondaryText: card.reference,
            tertiaryText: snippet(card.english),
            accentColor: settings.accentColor,
            arabicFontName: card.fontName,
            arabicColorRuns: card.colorRuns
        )
    }

    private func makeLastListenedEntry(settings: Settings, card: QuranWidgetSnapshot.ListenCard?) -> QuranWidgetEntry {
        guard let card, !card.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return sampleEntry()
        }
        return QuranWidgetEntry(
            date: Date(),
            kind: .lastListenedSurah,
            title: kind.title,
            icon: kind.icon,
            primaryText: card.name,
            secondaryText: card.reciter,
            tertiaryText: "\(formatDurationMMSS(card.current)) / \(formatDurationMMSS(card.full))",
            accentColor: settings.accentColor
        )
    }

    /// Fallback when the app hasn't written today's `ayahOfTheDay` card yet: pick deterministically from the
    /// app-provided pool by day, so the widget still shows one stable ayah per day.
    private func ayahOfTheDayCard(from snapshot: QuranWidgetSnapshot?) -> QuranWidgetSnapshot.AyahCard? {
        guard let pool = snapshot?.randomPool, !pool.isEmpty else { return nil }
        let bucket = Int(Date().timeIntervalSince1970 / 86_400)
        return pool[((bucket % pool.count) + pool.count) % pool.count]
    }

    private func snippet(_ text: String, maxLength: Int = 90) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return String(trimmed[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private func formatDurationMMSS(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct QuranWidgetEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: QuranWidgetEntry

    private var isAccessoryRectangularFamily: Bool {
        #if os(iOS)
        if #available(iOSApplicationExtension 16.0, *) {
            return widgetFamily == .accessoryRectangular
        }
        #endif
        return false
    }

    /// On iOS 17+ the system applies default content margins (like the Adhan widgets), so we add no extra
    /// padding; on older iOS we pad manually.
    private var contentPadding: CGFloat {
        if isAccessoryRectangularFamily { return 0 }
        if #available(iOSApplicationExtension 17.0, *) { return 0 }
        return 14
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header

            if isAccessoryRectangularFamily {
                accessoryBody
            } else {
                regularBody
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(contentPadding)
        // The placeholder entry is already representative sample content, so show it as-is. Left redacted,
        // WidgetKit blurs it into the grey smudge that reads as "this widget is broken".
        .unredacted()
        .widgetContainerBackground(accessory: isAccessoryRectangularFamily)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.icon)
                .font(.caption.weight(.semibold))
            Text(entry.title)
                .font(isAccessoryRectangularFamily ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundColor(entry.accentColor.color)
    }

    /// Renders `primaryText`: as Arabic in the supplied font (with tajweed colors) when present, otherwise
    /// as a plain title.
    @ViewBuilder
    private func primaryText(arabicSize: CGFloat, lineLimit: Int) -> some View {
        if let fontName = entry.arabicFontName, !fontName.isEmpty {
            Text(Self.arabicAttributed(entry.primaryText, runs: entry.arabicColorRuns))
                .font(.custom(fontName, size: arabicSize))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(lineLimit)
                .minimumScaleFactor(0.5)
        } else {
            Text(entry.primaryText)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    /// Applies tajweed color spans to the Arabic; un-colored characters keep the view's primary color.
    private static func arabicAttributed(_ text: String, runs: [QuranWidgetSnapshot.ColorRun]?) -> AttributedString {
        guard let runs, !runs.isEmpty else { return AttributedString(text) }
        let ns = NSMutableAttributedString(string: text)
        for run in runs {
            let range = NSRange(location: run.start, length: run.length)
            guard run.start >= 0, NSMaxRange(range) <= ns.length else { continue }
            ns.addAttribute(.foregroundColor,
                            value: UIColor(red: CGFloat(run.r), green: CGFloat(run.g), blue: CGFloat(run.b), alpha: 1),
                            range: range)
        }
        return AttributedString(ns)
    }

    private var accessoryBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            primaryText(arabicSize: 16, lineLimit: 2)
            if let secondary = entry.secondaryText {
                Text(secondary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var regularBody: some View {
        VStack(alignment: .leading, spacing: 5) {
            primaryText(arabicSize: 22, lineLimit: 3)

            if let secondary = entry.secondaryText {
                Text(secondary)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if let tertiary = entry.tertiaryText {
                Text(tertiary)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(2)
            }
        }
    }
}

func quranWidgetFamilies() -> [WidgetFamily] {
    #if os(iOS)
    if #available(iOS 16.0, *) {
        return [.systemSmall, .systemMedium, .accessoryRectangular]
    }
    #endif
    return [.systemSmall, .systemMedium]
}

/// Last Listened keeps the small home-screen size plus the lock-screen rectangular accessory (no medium).
func lastListenedWidgetFamilies() -> [WidgetFamily] {
    #if os(iOS)
    if #available(iOS 16.0, *) {
        return [.systemSmall, .accessoryRectangular]
    }
    #endif
    return [.systemSmall]
}
