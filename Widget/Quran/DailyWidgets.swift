import SwiftUI
import WidgetKit

// Two daily widgets fed by the shared snapshot the app writes once a day: the Reminder of the Day
// (a verse, a hadith, a Sunnah practice, a dua, a dhikr or a Name of Allah, in a six-day rotation)
// and the Name of Allah (one of the ninety-nine, with what believing it asks of a person). Both pick
// the day's entry themselves from the whole corpus by the shared day index, so they keep telling the
// truth on a day the app was never opened, and both turn over at the same boundary as the app's own
// daily cards: Fajr, from the table the app writes, or midnight without it.

// MARK: - Entries

struct DailyReminderEntry: TimelineEntry {
    let date: Date
    let kindLabel: String
    let arabic: String
    let english: String
    let short: String
    let source: String
    let fontName: String?
    let accentColor: AccentColor
}

struct NameOfAllahEntry: TimelineEntry {
    let date: Date
    let number: Int
    let arabic: String
    let transliteration: String
    let meaning: String
    let living: String
    /// The Islam tab's Arabic face, so the name is drawn the way the app draws it; nil for the system face.
    let fontName: String?
    let accentColor: AccentColor
}

private enum DailyWidgetShared {
    static let store = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)
    static let accent: AccentColor = {
        AccentColor(rawValue: store?.string(forKey: "accentColor") ?? AppIdentifiers.mainColorString) ?? AppIdentifiers.mainColor
    }()

    static func reload(for snapshot: DailyWidgetSnapshot?) -> Date {
        DailyRollover.nextRollover(after: Date(), fajrByDay: snapshot?.fajrByDay)
    }

    /// Today's index under the boundary the app wrote (Fajr by default), or plain local days.
    static func dayIndex(for snapshot: DailyWidgetSnapshot?) -> Int {
        DailyRollover.dayIndex(for: Date(), fajrByDay: snapshot?.fajrByDay)
    }
}

// MARK: - Reminder of the Day

struct DailyReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyReminderEntry { sample() }

    func getSnapshot(in context: Context, completion: @escaping (DailyReminderEntry) -> Void) {
        completion(context.isPreview ? sample() : entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyReminderEntry>) -> Void) {
        let snapshot = DailyWidgetStore.load()
        completion(Timeline(entries: [entry(snapshot: snapshot)], policy: .after(DailyWidgetShared.reload(for: snapshot))))
    }

    private func sample() -> DailyReminderEntry {
        DailyReminderEntry(date: Date(), kindLabel: "Verse of the day",
                           arabic: "فَٱذۡكُرُونِيٓ أَذۡكُرۡكُمۡ وَٱشۡكُرُواْ لِي وَلَا تَكۡفُرُونِ",
                           english: "So remember Me; I will remember you. And be grateful to Me and do not deny Me.",
                           short: "Remember Me; I will remember you.", source: "Quran 2:152",
                           fontName: nil, accentColor: DailyWidgetShared.accent)
    }

    private func entry(snapshot: DailyWidgetSnapshot? = DailyWidgetStore.load()) -> DailyReminderEntry {
        guard let cards = snapshot?.reminders, !cards.isEmpty else { return sample() }
        let index = DailyWidgetShared.dayIndex(for: snapshot)
        let card = cards[((index % cards.count) + cards.count) % cards.count]
        return DailyReminderEntry(date: Date(), kindLabel: card.kindLabel, arabic: card.arabic,
                                  english: card.english, short: card.short, source: card.source,
                                  fontName: card.fontName, accentColor: DailyWidgetShared.accent)
    }
}

struct DailyReminderWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DailyReminderEntry

    private var isAccessory: Bool {
        if #available(iOSApplicationExtension 16.0, *) { return family == .accessoryRectangular }
        return false
    }

    private var padding: CGFloat {
        if isAccessory { return 0 }
        if #available(iOSApplicationExtension 17.0, *) { return 0 }
        return 14
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isAccessory ? 2 : 5) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.semibold))
                Text(entry.kindLabel.uppercased())
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .foregroundColor(entry.accentColor.color)

            if isAccessory {
                Text(entry.short)
                    .font(.caption)
                    .lineLimit(3)
            } else {
                if !entry.arabic.isEmpty {
                    arabicText
                        .lineLimit(family == .systemSmall ? 2 : 3)
                        .minimumScaleFactor(0.6)
                }
                Text(family == .systemSmall ? entry.short : entry.english)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(family == .systemSmall ? 3 : 4)
                Text(entry.source)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(padding)
        .unredacted()
        .widgetContainerBackground(accessory: isAccessory)
    }

    @ViewBuilder
    private var arabicText: some View {
        let size: CGFloat = family == .systemSmall ? 17 : 21
        if let fontName = entry.fontName, !fontName.isEmpty {
            Text(entry.arabic)
                .font(.custom(fontName, size: size))
                .arabicFontDesign(custom: fontName != Settings.systemArabicFontName)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            Text(entry.arabic)
                .font(.system(size: size))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct DailyReminderWidget: Widget {
    let kind: String = "DailyReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyReminderProvider()) { entry in
            DailyReminderWidgetView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Reminder of the Day")
        .description("A verse, a hadith, a Sunnah, a dua, a dhikr or a Name of Allah, one each day")
    }
}

// MARK: - Name of Allah

struct NameOfAllahProvider: TimelineProvider {
    func placeholder(in context: Context) -> NameOfAllahEntry { sample() }

    func getSnapshot(in context: Context, completion: @escaping (NameOfAllahEntry) -> Void) {
        completion(context.isPreview ? sample() : entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NameOfAllahEntry>) -> Void) {
        let snapshot = DailyWidgetStore.load()
        completion(Timeline(entries: [entry(snapshot: snapshot)], policy: .after(DailyWidgetShared.reload(for: snapshot))))
    }

    private func sample() -> NameOfAllahEntry {
        NameOfAllahEntry(date: Date(), number: 1, arabic: "الرَّحمَٰن", transliteration: "Ar-Rahman",
                         meaning: "The Entirely Merciful",
                         living: "Meet people with more mercy than they have earned from you, because that is exactly how you are being dealt with.",
                         fontName: nil, accentColor: DailyWidgetShared.accent)
    }

    private func entry(snapshot: DailyWidgetSnapshot? = DailyWidgetStore.load()) -> NameOfAllahEntry {
        guard let names = snapshot?.names, !names.isEmpty else { return sample() }
        let index = DailyWidgetShared.dayIndex(for: snapshot)
        let card = names[((index % names.count) + names.count) % names.count]
        return NameOfAllahEntry(date: Date(), number: card.number, arabic: card.arabic,
                                transliteration: card.transliteration, meaning: card.meaning,
                                living: card.living, fontName: card.fontName, accentColor: DailyWidgetShared.accent)
    }
}

struct NameOfAllahWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NameOfAllahEntry

    private var isAccessory: Bool {
        if #available(iOSApplicationExtension 16.0, *) { return family == .accessoryRectangular }
        return false
    }

    private var padding: CGFloat {
        if isAccessory { return 0 }
        if #available(iOSApplicationExtension 17.0, *) { return 0 }
        return 14
    }

    var body: some View {
        Group {
            if isAccessory {
                VStack(alignment: .leading, spacing: 1) {
                    arabicText(size: 18)
                        .lineLimit(1)
                    Text(entry.transliteration)
                        .font(.caption.weight(.semibold))
                    Text(entry.meaning)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: "signature")
                            .font(.caption2.weight(.semibold))
                        Text("NAME OF ALLAH · \(entry.number) OF 99")
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(entry.accentColor.color)

                    arabicText(size: family == .systemSmall ? 30 : 34)
                        .foregroundColor(entry.accentColor.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: family == .systemSmall ? .leading : .trailing)

                    Text(entry.transliteration)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(entry.meaning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(family == .systemSmall ? 2 : 1)
                    if family != .systemSmall, !entry.living.isEmpty {
                        Text(entry.living)
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                            .lineLimit(3)
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(padding)
        .unredacted()
        .widgetContainerBackground(accessory: isAccessory)
    }

    /// The name in the Islam tab's face when the app wrote one (the reminder widget does the same for
    /// a verse), else the system face, semibold as before.
    @ViewBuilder
    private func arabicText(size: CGFloat) -> some View {
        if let fontName = entry.fontName, !fontName.isEmpty, fontName != Settings.systemArabicFontName {
            Text(entry.arabic)
                .font(.custom(fontName, size: size))
                .arabicFontDesign(custom: true)
        } else {
            Text(entry.arabic)
                .font(.system(size: size, weight: .semibold))
        }
    }
}

struct NameOfAllahWidget: Widget {
    let kind: String = "NameOfAllahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NameOfAllahProvider()) { entry in
            NameOfAllahWidgetView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Name of Allah")
        .description("One of the ninety-nine names each day, and what living by it asks")
    }
}
