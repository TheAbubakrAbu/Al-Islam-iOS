import SwiftUI
import WidgetKit

struct LastListenedSurahWidget: Widget {
    let kind: String = "LastListenedSurahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranWidgetProvider(kind: .lastListenedSurah)) { entry in
            LastListenedSurahEntryView(entry: entry)
        }
        .supportedFamilies(lastListenedWidgetFamilies())
        .configurationDisplayName("Last Listened Surah")
        .description("Shows the last surah you listened to, with a button that plays it on from where you stopped")
    }
}

/// The small widget gets its own card from iOS 17 (where a widget can hold a button); the lock screen's
/// rectangular one and older systems keep the shared Quran widget look.
struct LastListenedSurahEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuranWidgetEntry

    var body: some View {
        if family == .systemSmall, #available(iOSApplicationExtension 17.0, *) {
            LastListenedSurahCard(entry: entry)
        } else {
            QuranWidgetEntryView(entry: entry)
        }
    }
}

/// The surah, its reciter, how far in, and a play button that carries on from there without opening
/// the app (`ResumeListeningIntent`), after Tilawa's Continue Listening widget. It is also the one Quran
/// widget made for the CarPlay dashboard, which draws a small widget without its background, enlarged,
/// on a dark screen, and asks for large, glanceable type; StandBy draws it the same way.
@available(iOSApplicationExtension 17.0, *)
private struct LastListenedSurahCard: View {
    @Environment(\.showsWidgetContainerBackground) private var showsBackground
    let entry: QuranWidgetEntry

    /// No background (CarPlay, StandBy): the card has the screen to itself, so the type grows.
    private var roomy: Bool { !showsBackground }

    private var fraction: Double? {
        guard entry.surahSeconds > 0 else { return nil }
        return min(1, max(0, entry.listenedSeconds / entry.surahSeconds))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: entry.icon)
                    .font(.caption.weight(.semibold))
                Text(roomy ? "Continue Listening" : entry.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(entry.accentColor.color)
            .widgetAccentable()

            Spacer(minLength: 0)

            Text(entry.primaryText)
                .font(roomy ? .title2.weight(.bold) : .headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            if let reciter = entry.secondaryText {
                Text(reciter)
                    .font(roomy ? .subheadline : .caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    if let fraction {
                        ProgressView(value: fraction)
                            .tint(entry.accentColor.color)
                            .widgetAccentable()
                    }
                    if let time = entry.tertiaryText {
                        Text(time)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if entry.canResume {
                    Button(intent: ResumeListeningIntent()) {
                        Image(systemName: "play.fill")
                            .font(.system(size: roomy ? 20 : 15, weight: .bold))
                            .foregroundStyle(entry.accentColor.color)
                            .frame(width: roomy ? 46 : 36, height: roomy ? 46 : 36)
                            .background(Circle().fill(entry.accentColor.color.opacity(0.18)))
                            .widgetAccentable()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Play \(entry.primaryText) from where you stopped")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // The fallback entry is representative sample content, shown as is (see QuranWidgetEntryView).
        .unredacted()
        .widgetContainerBackground()
    }
}

/// The widget only names `ResumeListeningIntent` for its button: an audio intent always runs in the app,
/// whose `resumeListening()` (QuranShortcuts.swift) does the playing.
@available(iOSApplicationExtension 17.0, *)
extension ResumeListeningIntent {
    func resumeListening() async {}
}
