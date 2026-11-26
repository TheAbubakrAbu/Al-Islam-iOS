#if os(iOS)
import SwiftUI
import CoreLocation

/// "How Traveling Mode Works": the one page that says where the home city came from, what the mode
/// changes in the list and in the notifications, and what stays the traveler's own call (Abu,
/// 2026-11-25: someone meeting four combined prayers for the first time had a one-line card and a
/// footer to go on, and could wait for an Asr notification that was never going to come).
///
/// Two doors lead here, both under the page's own name (`Settings.AutoChangeCard.explainerTitle`):
/// the third button of the first "Traveling Mode On" card, which raises it as a sheet that ends in
/// the card's two answers (`answersCard`), and the LEARN MORE group of the Traveling Mode settings
/// page, which pushes it. The guides it links are the Islam tab's own pages.
struct TravelingModeExplainer: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var live = LiveState.shared
    @Environment(\.dismiss) private var dismiss

    /// Raised from the "Traveling Mode On" card: a sheet with a close button, ending in the card's
    /// own two answers. Closing it any other way keeps the mode on, as dismissing the card does.
    var answersCard = false

    var body: some View {
        List {
            Group {
                homeSection
                changesSection
                choiceSection
                TravelingGuideDoors()
                if answersCard { answerSection }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(Settings.AutoChangeCard.explainerTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if answersCard {
                    Button {
                        settings.hapticFeedback()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    // MARK: - Sections

    private var homeSection: some View {
        Section(header: Text("HOME CITY")) {
            let city = settings.homeLocation?.displayCity.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if city.isEmpty {
                TravelingExplainerRow(
                    systemImage: "house.fill",
                    title: String(localized: "No home city yet"),
                    text: String(localized: "Set one on the Traveling Mode settings page, and the app can tell when you are away."))
            } else {
                TravelingExplainerRow(
                    systemImage: "house.fill",
                    title: String(localized: "Home city: \(city)"),
                    text: String(localized: "Saved from the first location the app found when you first opened it. If that is not where you live, change it on the Traveling Mode settings page."))
            }

            TravelingExplainerRow(
                systemImage: "location.fill",
                title: String(localized: "48 mi (77 km) from home"),
                text: thresholdText)
        }
    }

    /// What the 48 miles do, and where this phone stands against them right now.
    private var thresholdText: String {
        var sentences = [
            settings.travelAutomatic
                ? String(localized: "Past that distance, Automatic Traveling Mode turns Traveling Mode on. It turns off by itself once you are back.")
                : String(localized: "Past that distance, Automatic Traveling Mode would turn Traveling Mode on. It is off now, so the mode changes only when you change it."),
        ]
        if let distance = TravelingDistance.fromHome(home: settings.homeLocation, here: live.currentLocation) {
            sentences.append(String(localized: "You are \(distance) away now."))
        }
        return sentences.joined(separator: " ")
    }

    private var changesSection: some View {
        Section(header: Text("WHAT CHANGES")) {
            TravelingExplainerRow(
                systemImage: "list.bullet",
                title: String(localized: "Two pairs in the prayer list"),
                text: String(localized: "Dhuhr and Asr share one row, and so do Maghrib and Isha. A pair may be prayed together at any time from the first prayer's start until the second one ends."))

            TravelingExplainerRow(
                systemImage: "arrow.down.right.and.arrow.up.left",
                title: String(localized: "Shorter prayers"),
                text: String(localized: "Dhuhr, Asr and Isha are 2 rakahs each instead of 4. Fajr stays 2 and Maghrib stays 3."))

            TravelingExplainerRow(
                systemImage: "bell.fill",
                title: String(localized: "One notification for each pair"),
                text: String(localized: "It comes at the first prayer's time, so Asr and Isha do not ring on their own. If Traveling Mode turns on between the two, the second one still rings that one time."))
        }
    }

    private var choiceSection: some View {
        Section(header: Text("YOUR CHOICE")) {
            TravelingExplainerRow(
                systemImage: "arrow.triangle.branch",
                title: String(localized: "Shortening and combining are two things"),
                text: String(localized: "Shortening is the Sunnah of the traveler. Combining is an ease for when you need it, and each prayer may still be prayed in its own time. Show Full Prayers brings back all five times."))

            TravelingExplainerRow(
                systemImage: "person.fill.questionmark",
                title: String(localized: "You decide whether you are a traveler"),
                text: String(localized: "The app only measures distance. If you have settled where you are, or the mode does not fit, turn it off. Turning off Automatic Traveling Mode keeps it from coming back."))
        }
    }

    /// The card's two answers, for a reader who came here from it: nothing is lost by having asked
    /// first. Turn Off is the card's Turn Off (`overrideTravelingMode`), and the footer says what
    /// that button has always done without saying so.
    private var answerSection: some View {
        Section(header: Text("TRAVELING MODE"),
                footer: Text("Turn Off also turns off Automatic Traveling Mode, so it stays off until you turn it back on.")) {
            Button {
                settings.hapticFeedback()
                dismiss()
            } label: {
                Text(settings.autoChangeCard(.travelOn).confirmTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .tint(settings.accentColor.color)

            Button {
                settings.hapticFeedback()
                settings.overrideTravelingMode(keepOn: false)
                dismiss()
            } label: {
                Text(settings.autoChangeCard(.travelOn).overrideTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .tint(settings.accentColor.color)
        }
    }
}

/// One point of the explanation: a chip, what it is, and the sentence or two that say it.
private struct TravelingExplainerRow: View {
    let systemImage: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: SettingsTint.prayer)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title.localizedDigits)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                Text(text.localizedDigits)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// LEARN MORE: the Islam tab's three travel guides, as doors. On the explainer and on the Traveling
/// Mode settings page (which adds the explainer itself above them). The guides are written in
/// English, so their doors carry the titles the Islam tab shows.
struct TravelingGuideDoors: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    /// The settings page's first door: the explainer itself.
    var includesExplainer = false
    /// The fiqh of the mode in one sentence, under the doors (the settings page's).
    var footer: String? = nil

    private static let guides: [(id: String, systemImage: String)] = [
        ("TravelPrayerView", "figure.walk"),
        ("CombinePrayersView", "arrow.triangle.merge"),
        ("PlanePrayerView", "airplane"),
    ]

    var body: some View {
        Section {
            if includesExplainer {
                NavigationLink(destination: LazyDestination { TravelingModeExplainer() }) {
                    SettingsRowLabel(title: Settings.AutoChangeCard.explainerTitle, systemImage: "questionmark",
                                     tint: SettingsTint.prayer)
                }
                .tint(settings.accentColor.color)
            }

            ForEach(Self.guides, id: \.id) { guide in
                if let entry = IslamArticleCatalog.byID[guide.id] {
                    NavigationLink(destination: LazyDestination { IslamArticleCatalog.destination(id: guide.id) }) {
                        SettingsRowLabel(title: entry.title, systemImage: guide.systemImage,
                                         tint: SettingsTint.islam, secondaryTint: SettingsTint.islamSecondary,
                                         titleLineLimit: 2)
                    }
                    .tint(settings.accentColor.color)
                }
            }
        } header: {
            Text("LEARN MORE")
        } footer: {
            if let footer { Text(footer.localizedDigits) }
        }
    }
}

/// Under HOME CITY on the Traveling Mode settings page: where the city came from, and how far from
/// it this phone is now. A view of its own because the distance moves with the location, which the
/// settings page does not watch.
struct TravelingHomeCityFooter: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var live = LiveState.shared

    var body: some View {
        Text(text.localizedDigits)
    }

    private var text: String {
        guard settings.homeLocation != nil else {
            return String(localized: "Traveling Mode measures how far you are from your home city. Set it to the place you live.")
        }
        var sentences = [String(localized: "Saved from the first location the app found. Traveling Mode measures how far you are from it, so set it to the place you live.")]
        if let distance = TravelingDistance.fromHome(home: settings.homeLocation, here: live.currentLocation) {
            sentences.append(String(localized: "You are \(distance) away now."))
        }
        return sentences.joined(separator: " ")
    }
}

/// How far this phone is from the home city, as the traveling screens say it.
enum TravelingDistance {
    /// "412 mi" (or "663 km", as the locale measures), nil when either end is unknown or the two
    /// are the same place: inside the home city the number is GPS noise.
    static func fromHome(home: Location?, here: Location?) -> String? {
        guard let home, let here, here.latitude != 1000, here.longitude != 1000 else { return nil }
        let meters = CLLocation(latitude: here.latitude, longitude: here.longitude)
            .distance(from: CLLocation(latitude: home.latitude, longitude: home.longitude))
        guard meters > 1_000 else { return nil }
        return TravelingModeBanner.distanceText(meters)
    }
}
#endif
