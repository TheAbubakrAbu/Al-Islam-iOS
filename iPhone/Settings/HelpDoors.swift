#if os(iOS)
import SwiftUI

// Need a Hand? (Abu, 2026-09-27: "Add Need Help Praying in adhan view (nagging mode), need help
// reading in quran view (arabic beginner mode). add that to other cool unique settings too").
//
// Every tab keeps a short run of rows, each a question a reader on that tab might be asking and the
// one setting that answers it: "Need Help Praying?" opens Nagging Mode from the prayer times, "Need
// Help Reading?" opens Arabic Beginner Mode from the Quran. The settings are the ones the Settings
// tab's spotlight cards and the settings search already reach (`SettingsSearchEntry.Destination`),
// so a door is a shortcut, never a second copy of a screen, and a change to a setting's own page
// needs no change here. Each row reads the setting's state out at its trailing edge ("On", "Off",
// "Paused"), so the door is also a glance at where the setting stands.
//
// A door opens a SHEET, the way every settings entrance on a tab does (the gear, the glance tiles,
// the prayer list's Travel Settings): the page itself where it is a plain view (`screen`), or the
// settings root that pushes the page a beat after it mounts (the deep link the search results use)
// where the page is built inside that root.
//
// Each row presents its own sheet from its own state. A `.sheet` on the Section would be one Bool
// with two presenters (the sheet closed itself on first open, see `sheet-on-section-double-bridge`),
// and a shared host on each tab's List would spread the plumbing over four files for three rows.
//
// The rows can be put away in Appearance > Look and Feel (`Settings.showHelpShortcuts`).
// No em dashes and no spaced hyphens in any of this text (house rule); quoted labels are the app's own.

/// The tab a run of doors belongs to.
enum HelpDoorArea {
    case adhan, quran, hadith, islam
}

struct HelpDoor: Identifiable {
    let id: String
    /// The question, as the row's title: "Need Help Praying?".
    let title: String
    /// What the setting does, under the title (two lines at most at the default sizes).
    let caption: String
    let systemImage: String
    let tint: Color
    var secondaryTint: Color? = nil
    /// The setting's page: the settings root that pushes it, unless `screen` lands there directly.
    let destination: SettingsSearchEntry.Destination
    /// The page as a view of its own, presented directly instead of behind its settings root.
    var screen: (() -> AnyView)? = nil
    /// The setting is one its screen shows only with Advanced Settings on: opening it turns the
    /// switch on (`revealsAdvancedSettings`).
    var advanced = false
    /// The setting's state right now, at the row's trailing edge: "On", "Off", "Paused", "2 on".
    var value: String? = nil
}

// MARK: - The catalogue

/// Main actor: the doors are built inside a view body, and the Sunnah store they read is main-actor bound.
@MainActor
enum HelpDoorCatalog {
    static func doors(for area: HelpDoorArea, settings: Settings, sunnah: SunnahReminderStore) -> [HelpDoor] {
        switch area {
        case .adhan: return adhan(settings)
        case .quran: return quran(settings, sunnah: sunnah)
        case .hadith: return hadith(settings)
        case .islam: return islam(settings)
        }
    }

    private static func onOff(_ on: Bool) -> String { on ? "On" : "Off" }

    /// Prayer times: praying on time, praying away from home, and the sky above the times (or, with
    /// the sky off, the names the prayers go by).
    private static func adhan(_ settings: Settings) -> [HelpDoor] {
        var doors: [HelpDoor] = [
            HelpDoor(id: "adhan.nagging", title: "Need Help Praying?",
                     caption: "Asks \u{201C}Did you pray?\u{201D} until you answer.",
                     systemImage: "exclamationmark.bubble.fill", tint: SettingsTint.notifications,
                     destination: .notificationsPage(.naggingMode),
                     screen: { AnyView(NaggingModeView()) },
                     value: NaggingModeView.statusValue(settings)),
            HelpDoor(id: "adhan.travel", title: "Traveling?",
                     caption: "Shorter, combined prayers away from home.",
                     systemImage: "airplane", tint: SettingsTint.prayer,
                     destination: .prayerPage(.travelingMode),
                     value: onOff(settings.travelingMode)),
        ]
        if settings.showSkyView {
            doors.append(HelpDoor(id: "adhan.skycolors", title: "Want Your Own Sky?",
                                  caption: "Your own two colors for every prayer's sky.",
                                  systemImage: "paintpalette.fill", tint: SettingsTint.sky,
                                  destination: .prayerPage(.skyColors)))
        } else {
            doors.append(HelpDoor(id: "adhan.names", title: "Prefer Other Prayer Names?",
                                  caption: "Call the prayers what you call them.",
                                  systemImage: "character.cursor.ibeam", tint: SettingsTint.prayer,
                                  destination: .prayerPage(.customPrayerNames), advanced: true))
        }
        return doors
    }

    /// The Quran: reading the script, reading along before knowing it, and the surahs of the week.
    private static func quran(_ settings: Settings, sunnah: SunnahReminderStore) -> [HelpDoor] {
        [
            HelpDoor(id: "quran.beginner", title: "Need Help Reading?",
                     caption: "Puts a space between every Arabic letter.",
                     systemImage: "text.word.spacing", tint: SettingsTint.quran,
                     destination: .quranPage(.arabicText),
                     value: onOff(settings.beginnerMode)),
            HelpDoor(id: "quran.transliteration", title: "Want Transliteration?",
                     caption: "Latin letters beneath the Arabic.",
                     systemImage: "character.textbox", tint: SettingsTint.quran,
                     destination: .quranPage(.englishText),
                     value: onOff(settings.showTransliteration)),
            HelpDoor(id: "quran.sunnah", title: "Want Al-Kahf Every Friday?",
                     caption: "Al-Kahf on Friday, al-Mulk before sleep.",
                     systemImage: "bell.badge", tint: SettingsTint.notifications,
                     destination: .quranPage(.sunnahReminders),
                     screen: { AnyView(SunnahRemindersView()) },
                     value: sunnah.enabledCount == 0 ? "Off" : "\(sunnah.enabledCount) on"),
        ]
    }

    /// The hadith books: one language or both, and the name of Allah in red.
    private static func hadith(_ settings: Settings) -> [HelpDoor] {
        let language: String
        switch (settings.showHadithArabic, settings.showHadithEnglish) {
        case (true, true): language = "Both"
        case (true, false): language = "Arabic"
        case (false, true): language = "English"
        case (false, false): language = "Neither"
        }
        return [
            HelpDoor(id: "hadith.language", title: "Reading in One Language?",
                     caption: "Read only the Arabic, or only the English.",
                     systemImage: "textformat", tint: SettingsTint.hadith,
                     destination: .hadithPage(.arabicText),
                     value: language),
            HelpDoor(id: "hadith.allah", title: "Want Allah's Name in Red?",
                     caption: "His name in red, in Arabic and English.",
                     systemImage: "paintbrush.fill", tint: SettingsTint.hadith,
                     destination: .hadithPage(.readingView),
                     value: onOff(settings.highlightAllahNamesHadith)),
        ]
    }

    /// The Islam tab: getting started (only while the Start Here guide is not already on the tab),
    /// the tab's own text size, and when its day turns over.
    private static func islam(_ settings: Settings) -> [HelpDoor] {
        var doors: [HelpDoor] = []
        if !StartHere.isShown(settings) {
            doors.append(HelpDoor(id: "islam.aboutyou", title: "Need Help Getting Started?",
                                  caption: "A Start Here guide, tailored to you.",
                                  systemImage: "sparkles", tint: SettingsTint.islam,
                                  secondaryTint: SettingsTint.islamSecondary,
                                  destination: .aboutYou,
                                  screen: { AnyView(AboutYouSettingsView()) }))
        }
        doors.append(HelpDoor(id: "islam.textsize", title: "Text Too Small?",
                              caption: "A text size just for the Al-Islam tab.",
                              systemImage: "textformat.size", tint: SettingsTint.islam,
                              secondaryTint: SettingsTint.islamSecondary,
                              destination: .islamPage(.textSize),
                              screen: { AnyView(IslamTextSizeSettingsView()) },
                              value: IslamTextSize.size(for: settings.islamTextSize) == nil ? "Device" : "Custom"))
        doors.append(HelpDoor(id: "islam.fajr", title: "When Does Your Day Begin?",
                              caption: "Daily cards turn over at Fajr, or midnight.",
                              systemImage: "sunrise.fill", tint: SettingsTint.islam,
                              secondaryTint: SettingsTint.islamSecondary,
                              destination: .islamPage(.libraries), advanced: true,
                              value: settings.dailyRolloverAtFajr ? "Fajr" : "Midnight"))
        return doors
    }
}

// MARK: - The section

/// One tab's run of doors: a Section for that tab's List, gone entirely when the reader has put the
/// rows away. Observes Settings HERE, once, and hands each row plain values, so three rows do not
/// each re-render on every Settings publish.
struct HelpDoorsSection: View {
    @ObservedObject private var settings = Settings.shared
    /// The Quran run's Sunnah Reminders count belongs to the store, not to Settings.
    @ObservedObject private var sunnah = SunnahReminderStore.shared

    let area: HelpDoorArea

    var body: some View {
        if settings.showHelpShortcuts {
            let doors = HelpDoorCatalog.doors(for: area, settings: settings, sunnah: sunnah)
            if !doors.isEmpty {
                Section(header: header) {
                    ForEach(doors) { door in
                        HelpDoorRow(door: door)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle.fill")
            Text("NEED A HAND?")
        }
    }
}

/// One door: the chip, the question with the setting's state beside it, the caption under both, and
/// a chevron, opening its sheet.
///
/// Not a `SettingsRowLabel`: that row keeps its caption to one line and lets it win the width, which
/// squeezed a trailing "Off" to "o" beside a caption of any length. Here the state shares the TITLE
/// line (a question and its answer), and the caption has the whole width and two lines under them.
private struct HelpDoorRow: View {
    let door: HelpDoor
    @State private var isOpen = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// At the accessibility sizes the question wraps to three lines and the state beside it would
    /// be a sliver, so the state goes under the caption, the way iOS Settings stacks a row there.
    private var stacks: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            isOpen = true
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: door.systemImage, tint: door.tint, secondaryTint: door.secondaryTint)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(door.title)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        if !stacks, let value = door.value {
                            Text(value)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .layoutPriority(1)
                        }
                    }

                    Text(door.caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(stacks ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)

                    if stacks, let value = door.value {
                        Text(value)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the setting")
        .sheet(isPresented: $isOpen) {
            HelpDoorSheet(door: door)
        }
    }
}

/// The sheet a door opens: a stack container (so a page can push its own sub-screens) around the
/// page itself or the settings root that pushes it, with the house X to close.
private struct HelpDoorSheet: View {
    let door: HelpDoor

    var body: some View {
        SheetNavigationContainer {
            Group {
                if let screen = door.screen {
                    screen()
                } else {
                    SettingsSearchDestinationView.view(for: door.destination)
                }
            }
            .revealsAdvancedSettings(door.advanced)
            .sheetDismissToolbar()
        }
        .smallMediumSheetPresentation()
    }
}
#endif
