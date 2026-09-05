#if DEBUG
import SwiftUI
import WidgetKit

/// Every Adhan widget layout drawn INSIDE the app at its real widget size, for screenshot runs.
///
/// WidgetKit can't be driven from simctl (nothing places a widget on the simulator's home or lock screen
/// headlessly), so this is how a layout change gets looked at before it ships: `-widgetGallery <page>`
/// opens a page after the reveal (pages: glance, solar, day, grid, large, largesky, small, lock, dates)
/// and `-widgetCity "<name>"` swaps in a city, since long names are what break footers. The layouts are
/// the widget files' own entry views (the Widget/Adhan sources compile into the app for this), fed an
/// entry built from the app's live prayers the way the provider builds one.
///
/// What a screenshot proves: the SwiftUI layout at the family's size inside WidgetKit's 16pt content
/// margins, on the standard background or the sky gradient, in either appearance (`simctl ui <udid>
/// appearance dark`). What it can't: WidgetKit's own rendering. The lock screen's vibrant treatment is
/// stood in for by white on black, timers tick here but are archived stills in a real widget, and the
/// family comes from `previewWidgetFamily` because WidgetKit's environment value is read-only.
///
/// iOS 16+, for the lock-screen families; the app itself deploys to 15.
@available(iOS 16.0, *)
struct WidgetGalleryView: View {
    let page: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private let entry: PrayersEntry
    private let sizes: WidgetSizes

    init(page: String) {
        self.page = page
        entry = Self.makeEntry()
        sizes = WidgetSizes.forScreen(width: Self.screenWidth)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if items.isEmpty {
                        Text("No page named \"\(page)\". Pages: glance, solar, day, grid, large, largesky, small, lock, dates.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(row) { card($0) }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Widgets: \(page)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: The entry

    /// The same entry the provider would build, from the app's live state (`-widgetCity` overrides the city).
    private static func makeEntry() -> PrayersEntry {
        let settings = Settings.shared
        let arguments = ProcessInfo.processInfo.arguments
        var city = settings.currentLocation?.city ?? ""
        if let index = arguments.firstIndex(of: "-widgetCity"), arguments.indices.contains(index + 1) {
            city = arguments[index + 1]
        }
        let prayers = settings.prayers
        return PrayersEntry(
            date: Date(),
            accentColor: settings.accentColor,
            currentCity: city,
            prayers: prayers?.prayers ?? [],
            fullPrayers: prayers?.fullPrayers ?? [],
            currentPrayer: settings.currentPrayer,
            nextPrayer: settings.nextPrayer,
            hijriOffset: settings.hijriOffset,
            switchHijriDateAtMaghrib: settings.switchHijriDateAtMaghrib,
            skyColors: settings.skyGradientColors(forPrayer: settings.currentPrayer?.nameTransliteration)
        )
    }

    private static var screenWidth: CGFloat {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.screen.bounds.width ?? 393
    }

    // MARK: Sizes

    /// Apple's published widget dimensions by screen width: the 390-402pt class is the 15, 16 and 17 Pro,
    /// the 428+ class the Max and Plus phones, 375 the SE-style widths. Accessory sizes are the lock
    /// screen's; the inline one is only a width to check truncation against.
    private struct WidgetSizes {
        let small: CGSize
        let medium: CGSize
        let large: CGSize
        let circular: CGSize
        let rectangular: CGSize
        let inline: CGSize

        static func forScreen(width: CGFloat) -> WidgetSizes {
            if width >= 428 {
                return WidgetSizes(small: CGSize(width: 170, height: 170), medium: CGSize(width: 364, height: 170),
                                   large: CGSize(width: 364, height: 382), circular: CGSize(width: 76, height: 76),
                                   rectangular: CGSize(width: 172, height: 76), inline: CGSize(width: 257, height: 26))
            }
            if width >= 390 {
                return WidgetSizes(small: CGSize(width: 158, height: 158), medium: CGSize(width: 338, height: 158),
                                   large: CGSize(width: 338, height: 354), circular: CGSize(width: 76, height: 76),
                                   rectangular: CGSize(width: 172, height: 76), inline: CGSize(width: 257, height: 26))
            }
            if width >= 375 {
                return WidgetSizes(small: CGSize(width: 155, height: 155), medium: CGSize(width: 329, height: 155),
                                   large: CGSize(width: 329, height: 345), circular: CGSize(width: 72, height: 72),
                                   rectangular: CGSize(width: 160, height: 72), inline: CGSize(width: 234, height: 26))
            }
            return WidgetSizes(small: CGSize(width: 141, height: 141), medium: CGSize(width: 292, height: 141),
                               large: CGSize(width: 292, height: 311), circular: CGSize(width: 72, height: 72),
                               rectangular: CGSize(width: 157, height: 72), inline: CGSize(width: 200, height: 26))
        }

        func size(for family: WidgetFamily) -> CGSize {
            switch family {
            case .systemSmall: return small
            case .systemMedium: return medium
            case .accessoryCircular: return circular
            case .accessoryRectangular: return rectangular
            case .accessoryInline: return inline
            default: return large
            }
        }
    }

    // MARK: Items

    private struct Item: Identifiable {
        let id: String
        let title: String
        let family: WidgetFamily
        let sky: Bool
        let content: AnyView

        init<V: View>(_ title: String, _ family: WidgetFamily, sky: Bool = false, @ViewBuilder content: () -> V) {
            id = "\(title)|\(family)|\(sky)"
            self.title = title
            self.family = family
            self.sky = sky
            self.content = AnyView(content())
        }
    }

    private var isAccessory: (WidgetFamily) -> Bool {
        { [.accessoryCircular, .accessoryRectangular, .accessoryInline].contains($0) }
    }

    private var items: [Item] {
        let entry = entry
        switch page {
        case "glance":
            return [
                Item("Prayer Glance, medium", .systemMedium) { PrayerGradientEntryView(entry: entry, showsSky: false) },
                Item("Prayer Glance Sky, medium", .systemMedium, sky: true) { PrayerGradientEntryView(entry: entry) },
                Item("Current Prayer, medium", .systemMedium) { NextPrayerBoardView(entry: entry) },
                Item("Current Prayer Sky, medium", .systemMedium, sky: true) { NextPrayerBoardView(entry: entry, skyStyle: true).modifier(PrayerSkyChrome(entry: entry)) },
            ]
        case "solar":
            return [
                Item("Solar Arc, medium", .systemMedium) { SolarArcEntryView(entry: entry) },
                Item("Solar Arc Sky, medium", .systemMedium, sky: true) { SolarArcEntryView(entry: entry, skyStyle: true).modifier(PrayerSkyChrome(entry: entry)) },
                Item("Moon Phase, medium", .systemMedium) { MoonEntryView(entry: entry) },
                Item("Moon Phase Sky, medium", .systemMedium, sky: true) { MoonEntryView(entry: entry, skyStyle: true).modifier(PrayerSkyChrome(entry: entry)) },
            ]
        case "day":
            return [
                Item("Prayer Day, medium", .systemMedium) { PrayerDayView(entry: entry) },
                Item("Prayer Day Sky, medium", .systemMedium, sky: true) { PrayerDayView(entry: entry, skyStyle: true).modifier(PrayerSkyChrome(entry: entry)) },
                Item("Prayer Split, medium", .systemMedium) { Prayers2EntryView(entry: entry) },
                Item("Prayer Split Sky, medium", .systemMedium, sky: true) { Prayers2EntryView(entry: entry, skyStyle: true).modifier(PrayerSkyChrome(entry: entry)) },
            ]
        case "grid":
            return [
                Item("Prayer Grid, medium", .systemMedium) { PrayersEntryView(entry: entry) },
                Item("Prayer Grid Sky, medium", .systemMedium, sky: true) { PrayersEntryView(entry: entry, skyStyle: true).modifier(PrayerSkyChrome(entry: entry)) },
                Item("Prayer Countdown, medium", .systemMedium) { CountdownEntryView(entry: entry) },
                Item("Fasting Countdown, medium", .systemMedium) { FastingCountdownView(entry: entry) },
            ]
        case "large":
            return [
                Item("Prayer Grid, large", .systemLarge) { PrayersEntryView(entry: entry) },
                Item("Day & Night, large", .systemLarge) { SolarMoonBoardEntryView(entry: entry) },
            ]
        case "largesky":
            return [
                Item("Prayer Grid Sky, large", .systemLarge, sky: true) { PrayersEntryView(entry: entry, skyStyle: true).modifier(PrayerSkyChrome(entry: entry)) },
                Item("Day & Night Sky, large", .systemLarge, sky: true) { SolarMoonBoardEntryView(entry: entry, skyStyle: true).modifier(PrayerSkyChrome(entry: entry)) },
            ]
        case "small":
            return [
                Item("Prayer Glance", .systemSmall) { PrayerGradientEntryView(entry: entry, showsSky: false) },
                Item("Prayer Glance Sky", .systemSmall, sky: true) { PrayerGradientEntryView(entry: entry) },
                Item("Prayer Countdown", .systemSmall) { CountdownEntryView(entry: entry) },
                Item("Simple Countdown", .systemSmall) { SimpleEntryView(entry: entry) },
                Item("Prayer List", .systemSmall) { PrayerListSmallView(entry: entry) },
                Item("Moon Phase", .systemSmall) { MoonEntryView(entry: entry) },
            ]
        case "lock":
            return [
                Item("Current & Next Prayer", .accessoryRectangular) { LockScreen2EntryView(entry: entry) },
                Item("Current Prayer Progress", .accessoryRectangular) { NextPrayerProgressView(entry: entry) },
                Item("Prayer Wave", .accessoryRectangular) { PrayerWaveView(entry: entry) },
                Item("Prayer Row", .accessoryRectangular) { PrayerRowLockView(entry: entry) },
                Item("First 3 Prayer Times", .accessoryRectangular) { LockScreen3EntryView(entry: entry) },
                Item("Last 3 Prayer Times", .accessoryRectangular) { LockScreen4EntryView(entry: entry) },
                Item("Current Prayer Time", .accessoryCircular) { LockScreen1EntryView(entry: entry) },
                Item("Prayer Progress Ring", .accessoryCircular) { PrayerProgressRingView(entry: entry) },
                Item("Current Prayer Countdown", .accessoryCircular) { PrayerCountdownCircularView(entry: entry) },
            ]
        case "dates":
            return [
                Item("Hijri Date, rectangular", .accessoryRectangular) { HijriDateLockView(entry: entry, language: .english) },
                Item("Hijri Date (Arabic), rectangular", .accessoryRectangular) { HijriDateLockView(entry: entry, language: .arabic) },
                Item("Hijri Date, circular", .accessoryCircular) { HijriDateLockView(entry: entry, language: .english) },
                Item("Hijri Date (Arabic), circular", .accessoryCircular) { HijriDateLockView(entry: entry, language: .arabic) },
                Item("Hijri Date, inline", .accessoryInline) { HijriDateLockView(entry: entry, language: .english) },
                Item("Hijri Date (Arabic), inline", .accessoryInline) { HijriDateLockView(entry: entry, language: .arabic) },
                Item("Hijri & Gregorian, rectangular", .accessoryRectangular) { DualCalendarLockView(entry: entry) },
                Item("Next Prayer & Date, rectangular", .accessoryRectangular) { NextPrayerDateLockView(entry: entry) },
                Item("Hijri & Gregorian, inline", .accessoryInline) { DualCalendarLockView(entry: entry) },
                Item("Next Prayer & Date, inline", .accessoryInline) { NextPrayerDateLockView(entry: entry) },
            ]
        default:
            return []
        }
    }

    /// Items packed into rows by their widths, so the small and lock-screen tiles sit side by side.
    private var rows: [[Item]] {
        let available = Self.screenWidth - 32
        var rows: [[Item]] = []
        var row: [Item] = []
        var used: CGFloat = 0
        for item in items {
            let width = sizes.size(for: item.family).width
            if !row.isEmpty, used + 12 + width > available {
                rows.append(row)
                row = []
                used = 0
            }
            used += row.isEmpty ? width : 12 + width
            row.append(item)
        }
        if !row.isEmpty { rows.append(row) }
        return rows
    }

    // MARK: Cards

    private func card(_ item: Item) -> some View {
        let size = sizes.size(for: item.family)
        let accessory = isAccessory(item.family)
        return VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: size.width, alignment: .leading)

            item.content
                .environment(\.previewWidgetFamily, item.family)
                .appFontDesign()
                .padding(padding(for: item.family))
                .frame(width: size.width, height: size.height)
                // The lock screen draws its widgets white on the wallpaper; a dark scheme on a black
                // card is the nearest still stand-in for that vibrant treatment.
                .environment(\.colorScheme, accessory ? .dark : colorScheme)
                .background(background(for: item))
                .clipShape(shape(for: item.family))
        }
    }

    private func padding(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .accessoryInline: return 0
        case .accessoryCircular, .accessoryRectangular: return 6
        default: return 16
        }
    }

    @ViewBuilder
    private func background(for item: Item) -> some View {
        if isAccessory(item.family) {
            Color.black
        } else if item.sky {
            PrayerSkyBackground.fill(colors: entry.skyColors)
        } else {
            Color(uiColor: .secondarySystemGroupedBackground)
        }
    }

    private func shape(for family: WidgetFamily) -> RoundedRectangle {
        switch family {
        case .accessoryCircular: return RoundedRectangle(cornerRadius: 38, style: .continuous)
        case .accessoryRectangular, .accessoryInline: return RoundedRectangle(cornerRadius: 13, style: .continuous)
        default: return RoundedRectangle(cornerRadius: 22, style: .continuous)
        }
    }
}
#endif
