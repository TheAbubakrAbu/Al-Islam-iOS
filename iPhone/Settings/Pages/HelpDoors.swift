#if os(iOS)
import SwiftUI

// Need a Hand? (Abu, 2026-09-27: "Add Need Help Praying in adhan view (nagging mode), need help
// reading in quran view (arabic beginner mode). add that to other cool unique settings too").
//
// Every tab keeps a short run of questions, each a thing a reader on that tab might be asking, and
// the one setting that answers it: "Need Help Praying?" opens Nagging Mode from the prayer times,
// "Need Help Reading?" answers with Arabic Beginner Mode on the Quran. The settings are the ones the
// Settings tab's spotlight cards and the settings search already reach, so a door is a shortcut and
// never a second copy of a screen. Each card reads the setting's state out in a pill ("On", "Off",
// "Paused"), so the door is also a glance at where the setting stands.
//
// 2026-09-28 (Abu: "make them look better and act better and make them collapsible (if collapsed
// remove them completely) and mention parts of it in each respective settings"):
// - The rows are clear-glass cards, the family the tabs' grid tiles and the Ask AI banner belong to,
//   in one List row (so a press-and-hold is a `GridTileMenu`, never a `.contextMenu`, which would lift
//   the whole row with every card in it).
// - The header is the app's collapsible `SectionPillHeader`: its arrow folds the cards away, and folded
//   they are REMOVED from the List, not hidden in place, so nothing is left behind but the header.
// - A door lands on its answer. It used to open the settings ROOT, which pushed the page a beat
//   later, and Beginner Mode was then the tenth control down a long page. Now a door opens either a
//   focused screen, a settings page on its own (`SettingsSearchDestinationView.page(for:)`), or the
//   one control that answers it with the page one row below (`Landing.answer`).
// - Holding a card offers its quick switch ("Turn On Arabic Beginner Mode"), collapse, and Hide on
//   This Tab.
// - Each tab's settings page names that tab's questions and carries its switch
//   (`HelpDoorsSettingsSection`); Appearance > Look and Feel switches all four at once.
//
// Each card presents its own sheet from its own state. A `.sheet` on the Section would be one Bool
// with two presenters (the sheet closed itself on first open, see `sheet-on-section-double-bridge`).
// No em dashes and no spaced hyphens in any of this text (house rule); quoted labels are the app's own.

/// The tab a run of doors belongs to.
enum HelpDoorArea: String, CaseIterable {
    case adhan, quran, hadith, islam

    /// The tab's name as its tab bar item reads.
    var tabName: String {
        switch self {
        case .adhan: return "Adhan"
        case .quran: return "Quran"
        case .hadith: return "Hadith"
        case .islam: return "Islam"
        }
    }

    /// The settings page that carries this tab's switch.
    var settingsPageName: String {
        switch self {
        case .adhan: return "Prayer Settings"
        case .quran: return "Quran Settings"
        case .hadith: return "Hadith Settings"
        case .islam: return "Islam Settings"
        }
    }

    /// Where the section sits on its tab, for the switch's caption.
    var placement: String {
        switch self {
        case .adhan: return "under the prayer tracker"
        case .quran, .hadith: return "under Your Summary"
        case .islam: return "under the Islamic resources"
        }
    }
}

struct HelpDoor: Identifiable {
    /// Where a door opens, always as the root of its own sheet.
    enum Landing {
        /// A screen of its own: Nagging Mode, Sunnah Reminders, About You, Text Size, Sky Colors.
        case screen(() -> AnyView)
        /// A settings page by itself, never behind its settings root (`page(for:)`).
        case page(SettingsSearchEntry.Destination)
        /// The one control that answers the question, first, and the pages that hold the rest one row
        /// below it. For a setting that sits deep in a long page (Beginner Mode, on Arabic Text), that
        /// is split across two (one language: Arabic Text and English Text), or that its page shows
        /// only with Advanced Settings on (the Fajr turnover).
        case answer(() -> AnyView, pages: [SettingsSearchEntry.Destination])
    }

    let id: String
    /// The question, as the card's title: "Need Help Praying?".
    let title: String
    /// What the setting does, under the title (two lines at most at the default sizes).
    let caption: String
    /// The setting the question opens, by name: "Nagging Mode". The settings page lists it beside the
    /// question, and a quick switch is named after it.
    let answerName: String
    let systemImage: String
    let tint: Color
    var secondaryTint: Color? = nil
    let landing: Landing
    /// The setting's state right now, in the card's pill: "On", "Off", "Paused", "2 on".
    var value: String? = nil
    /// The value reads as switched on, so its pill wears the accent.
    var isOn = false
    /// What the press-and-hold menu can do without opening anything.
    var actions: [HelpDoorAction] = []
}

/// A one-tap answer in a card's press-and-hold menu.
struct HelpDoorAction: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    /// One of several choices (the hadith language, the day's turnover): the current one wears a
    /// checkmark in place of its symbol.
    var isChosen = false
    let perform: () -> Void

    /// "Turn On Arabic Beginner Mode" or "Turn Off ...", for a door that is one switch.
    static func toggle(_ name: String, isOn: Bool, systemImage: String, set: @escaping (Bool) -> Void) -> HelpDoorAction {
        HelpDoorAction(id: "toggle", title: isOn ? "Turn Off \(name)" : "Turn On \(name)",
                       systemImage: systemImage) { set(!isOn) }
    }
}

// MARK: - What each tab shows, and whether it shows it

extension Settings {
    private static func helpAreas(_ raw: String) -> Set<String> {
        Set(raw.split(separator: ",").map(String.init))
    }

    /// Stored in the tabs' own order, so the raw value is stable whichever order they were set in.
    private static func helpRaw(_ areas: Set<String>) -> String {
        HelpDoorArea.allCases.map(\.rawValue).filter(areas.contains).joined(separator: ",")
    }

    /// Whether this tab shows its Need a Hand? section at all (its settings page's switch).
    func showsHelpDoors(_ area: HelpDoorArea) -> Bool {
        !Self.helpAreas(helpDoorsHiddenRaw).contains(area.rawValue)
    }

    func setShowsHelpDoors(_ area: HelpDoorArea, _ shown: Bool) {
        var hidden = Self.helpAreas(helpDoorsHiddenRaw)
        if shown { hidden.remove(area.rawValue) } else { hidden.insert(area.rawValue) }
        let raw = Self.helpRaw(hidden)
        if raw != helpDoorsHiddenRaw { helpDoorsHiddenRaw = raw }
    }

    /// Whether this tab's cards are showing under the header, or folded away (the header's arrow).
    func helpDoorsExpanded(_ area: HelpDoorArea) -> Bool {
        !Self.helpAreas(helpDoorsCollapsedRaw).contains(area.rawValue)
    }

    func setHelpDoorsExpanded(_ area: HelpDoorArea, _ expanded: Bool) {
        var collapsed = Self.helpAreas(helpDoorsCollapsedRaw)
        if expanded { collapsed.remove(area.rawValue) } else { collapsed.insert(area.rawValue) }
        let raw = Self.helpRaw(collapsed)
        if raw != helpDoorsCollapsedRaw { helpDoorsCollapsedRaw = raw }
    }

    /// Look and Feel's one switch for all four: on while any tab still shows its questions; turning
    /// it off puts every tab's away, turning it on brings every tab's back.
    var showHelpShortcuts: Bool {
        get { HelpDoorArea.allCases.contains { showsHelpDoors($0) } }
        set {
            let raw = newValue ? "" : HelpDoorArea.allCases.map(\.rawValue).joined(separator: ",")
            if raw != helpDoorsHiddenRaw { helpDoorsHiddenRaw = raw }
        }
    }

    /// The tabs that are not showing their questions, by name, for Look and Feel's caption.
    var hiddenHelpDoorTabs: [String] {
        HelpDoorArea.allCases.filter { !showsHelpDoors($0) }.map(\.tabName)
    }
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
        let nagging = NaggingModeView.statusValue(settings)
        var travelActions: [HelpDoorAction] = []
        // With Automatic Traveling Mode on, the switch is the location's to flip, not the reader's
        // (its page disables it the same way).
        if !settings.travelAutomatic {
            travelActions.append(.toggle("Traveling Mode", isOn: settings.travelingMode, systemImage: "airplane") { on in
                settings.setTravelingModeManually(on)
            })
        }

        var doors: [HelpDoor] = [
            HelpDoor(id: "adhan.nagging", title: "Need Help Praying?",
                     caption: "Asks \u{201C}Did you pray?\u{201D} until you answer.",
                     answerName: "Nagging Mode",
                     systemImage: "exclamationmark.bubble.fill", tint: SettingsTint.notifications,
                     landing: .screen { AnyView(NaggingModeView()) },
                     value: nagging, isOn: nagging == "On"),
            HelpDoor(id: "adhan.travel", title: "Traveling?",
                     caption: "Shorter, combined prayers away from home.",
                     answerName: settings.travelAutomatic ? "Traveling Mode, set automatically" : "Traveling Mode",
                     systemImage: "airplane", tint: SettingsTint.prayer,
                     landing: .page(.prayerPage(.travelingMode)),
                     value: onOff(settings.travelingMode), isOn: settings.travelingMode,
                     actions: travelActions),
        ]
        if settings.showSkyView {
            doors.append(HelpDoor(id: "adhan.skycolors", title: "Want Your Own Sky?",
                                  caption: "Your own two colors for every prayer's sky.",
                                  answerName: "Sky Colors",
                                  systemImage: "paintpalette.fill", tint: SettingsTint.sky,
                                  landing: .screen { AnyView(SkyColorsView()) },
                                  value: settings.hasCustomSkyGradients ? "Custom" : "Default",
                                  isOn: settings.hasCustomSkyGradients))
        } else {
            let renamed = Settings.renameablePrayerNames.filter { settings.customPrayerName(for: $0) != nil }.count
            doors.append(HelpDoor(id: "adhan.names", title: "Prefer Other Prayer Names?",
                                  caption: "Call the prayers what you call them.",
                                  answerName: "Custom Prayer Names",
                                  systemImage: "character.cursor.ibeam", tint: SettingsTint.prayer,
                                  landing: .page(.prayerPage(.customPrayerNames)),
                                  value: renamed == 0 ? "Default" : "\(renamed) renamed", isOn: renamed > 0))
        }
        return doors
    }

    /// The Quran: reading the script, reading along before knowing it, and the surahs of the week.
    private static func quran(_ settings: Settings, sunnah: SunnahReminderStore) -> [HelpDoor] {
        // Beginner Mode spaces out the Arabic, so with the Arabic hidden it has nothing to do (its
        // switch goes dead on Arabic Text); transliteration is Hafs an Asim's only.
        let beginner = settings.showArabicText && settings.beginnerMode
        let transliteration = settings.isHafsDisplay && settings.showTransliteration
        var beginnerActions: [HelpDoorAction] = []
        if settings.showArabicText {
            beginnerActions.append(.toggle("Arabic Beginner Mode", isOn: settings.beginnerMode,
                                           systemImage: "text.word.spacing") { on in
                withAnimation(.easeInOut) { settings.beginnerMode = on }
            })
        }
        var transliterationActions: [HelpDoorAction] = []
        if settings.isHafsDisplay {
            transliterationActions.append(.toggle("Transliteration", isOn: settings.showTransliteration,
                                                  systemImage: "character.textbox") { on in
                withAnimation(.easeInOut) { settings.showTransliteration = on }
            })
        }

        return [
            HelpDoor(id: "quran.beginner", title: "Need Help Reading?",
                     caption: "Puts a space between every Arabic letter.",
                     answerName: "Arabic Beginner Mode",
                     systemImage: "text.word.spacing", tint: SettingsTint.quran,
                     landing: .answer({ AnyView(BeginnerModeAnswer()) }, pages: [.quranPage(.arabicText)]),
                     value: onOff(beginner), isOn: beginner, actions: beginnerActions),
            HelpDoor(id: "quran.transliteration", title: "Want Transliteration?",
                     caption: "Latin letters beneath the Arabic.",
                     answerName: "Transliteration, on English Text",
                     systemImage: "character.textbox", tint: SettingsTint.quran,
                     landing: .page(.quranPage(.englishText)),
                     value: onOff(transliteration), isOn: transliteration, actions: transliterationActions),
            HelpDoor(id: "quran.sunnah", title: "Want Al-Kahf Every Friday?",
                     caption: "Al-Kahf on Friday, al-Mulk before sleep.",
                     answerName: "Sunnah Reminders",
                     systemImage: "bell.badge", tint: SettingsTint.notifications,
                     landing: .screen { AnyView(SunnahRemindersView()) },
                     value: sunnah.enabledCount == 0 ? "Off" : "\(sunnah.enabledCount) on",
                     isOn: sunnah.enabledCount > 0),
        ]
    }

    /// The hadith books: one language or both, and the name of Allah in red.
    private static func hadith(_ settings: Settings) -> [HelpDoor] {
        let language = HadithReadingLanguage.current(settings)
        return [
            HelpDoor(id: "hadith.language", title: "Reading in One Language?",
                     caption: "Read only the Arabic, or only the English.",
                     answerName: "Arabic and English, or one of them",
                     systemImage: "textformat", tint: SettingsTint.hadith,
                     landing: .answer({ AnyView(HadithLanguageAnswer()) },
                                      pages: [.hadithPage(.arabicText), .hadithPage(.englishText)]),
                     value: language.shortTitle, isOn: language != .both,
                     actions: HadithReadingLanguage.allCases.map { choice in
                         HelpDoorAction(id: choice.rawValue, title: choice.menuTitle, systemImage: choice.systemImage,
                                        isChosen: choice == language) {
                             withAnimation(.easeInOut) { choice.apply(to: settings) }
                         }
                     }),
            HelpDoor(id: "hadith.allah", title: "Want Allah's Name in Red?",
                     caption: "His name in red, in Arabic and English.",
                     answerName: "Highlight Allah, on Reading View",
                     systemImage: "paintbrush.fill", tint: SettingsTint.hadith,
                     landing: .page(.hadithPage(.readingView)),
                     value: onOff(settings.highlightAllahNamesHadith), isOn: settings.highlightAllahNamesHadith,
                     actions: [.toggle("Highlight Allah", isOn: settings.highlightAllahNamesHadith,
                                       systemImage: "paintbrush.fill") { on in
                         withAnimation(.easeInOut) { settings.highlightAllahNamesHadith = on }
                     }]),
        ]
    }

    /// The Islam tab: getting started (only while the Start Here guide is not already on the tab),
    /// the tab's own text size, and when its day turns over.
    private static func islam(_ settings: Settings) -> [HelpDoor] {
        var doors: [HelpDoor] = []
        if !StartHere.isShown(settings) {
            doors.append(HelpDoor(id: "islam.aboutyou", title: "Need Help Getting Started?",
                                  caption: "A Start Here guide, tailored to you.",
                                  answerName: "About You",
                                  systemImage: "sparkles", tint: SettingsTint.islam,
                                  secondaryTint: SettingsTint.islamSecondary,
                                  landing: .screen { AnyView(AboutYouSettingsView()) }))
        }
        let textSize = IslamTextSize.size(for: settings.islamTextSize)
        doors.append(HelpDoor(id: "islam.textsize", title: "Text Too Small?",
                              caption: "A text size just for the Al-Islam tab.",
                              answerName: "Text Size",
                              systemImage: "textformat.size", tint: SettingsTint.islam,
                              secondaryTint: SettingsTint.islamSecondary,
                              landing: .screen { AnyView(IslamTextSizeSettingsView()) },
                              value: textSize.map(IslamTextSize.name) ?? "Device", isOn: textSize != nil))
        let atFajr = settings.dailyRolloverAtFajr
        doors.append(HelpDoor(id: "islam.fajr", title: "When Does Your Day Begin?",
                              caption: "Daily cards turn over at Fajr, or midnight.",
                              answerName: "Turn Over at Fajr",
                              systemImage: "sunrise.fill", tint: SettingsTint.islam,
                              secondaryTint: SettingsTint.islamSecondary,
                              landing: .answer({ AnyView(DayBeginsAnswer()) }, pages: [.islamPage(.libraries)]),
                              value: atFajr ? "Fajr" : "Midnight", isOn: atFajr,
                              actions: [
                                HelpDoorAction(id: "fajr", title: "At Fajr", systemImage: "sunrise",
                                               isChosen: atFajr) {
                                    withAnimation(.easeInOut) { settings.dailyRolloverAtFajr = true }
                                    settings.dailyRolloverSwitchChanged()
                                },
                                HelpDoorAction(id: "midnight", title: "At Midnight", systemImage: "moon",
                                               isChosen: !atFajr) {
                                    withAnimation(.easeInOut) { settings.dailyRolloverAtFajr = false }
                                    settings.dailyRolloverSwitchChanged()
                                },
                              ]))
        return doors
    }
}

/// The hadith books' two languages as ONE choice: the answer to "Reading in One Language?". On the
/// settings pages they are two switches on two pages that refuse to both be off; here they are the
/// three states those switches can actually be in.
enum HadithReadingLanguage: String, CaseIterable, Identifiable {
    case both, arabic, english

    var id: String { rawValue }

    static func current(_ settings: Settings) -> HadithReadingLanguage {
        switch (settings.showHadithArabic, settings.showHadithEnglish) {
        case (true, false): return .arabic
        case (false, true): return .english
        default: return .both
        }
    }

    var shortTitle: String {
        switch self {
        case .both: return "Both"
        case .arabic: return "Arabic"
        case .english: return "English"
        }
    }

    var menuTitle: String {
        switch self {
        case .both: return "Arabic and English"
        case .arabic: return "Arabic Only"
        case .english: return "English Only"
        }
    }

    var systemImage: String {
        switch self {
        case .both: return "textformat"
        case .arabic: return "textformat.ar"
        case .english: return "textformat.abc"
        }
    }

    /// Never both off: each case turns on what it reads. Not animated here: the segmented picker
    /// must receive its new value outside an animation (it slid, snapped back and slid again under
    /// one), so only the hold menu wraps this in `withAnimation`.
    func apply(to settings: Settings) {
        let arabic = self != .english
        let english = self != .arabic
        if settings.showHadithArabic != arabic { settings.showHadithArabic = arabic }
        if settings.showHadithEnglish != english { settings.showHadithEnglish = english }
    }
}

// MARK: - The section on each tab

/// One tab's questions: a Section for that tab's List, gone entirely when the tab's switch is off,
/// folded to its header by the header's arrow. Observes Settings HERE, once, and hands each card plain
/// values, so the cards do not each re-render on every Settings publish.
struct HelpDoorsSection: View {
    @ObservedObject private var settings = Settings.shared
    /// The Quran run's Sunnah Reminders count belongs to the store, not to Settings.
    @ObservedObject private var sunnah = SunnahReminderStore.shared

    let area: HelpDoorArea

    /// The door whose sheet is up, as it was when opened. The section holds it, not the card: a
    /// door's own choice can take it off the catalog ("Need Help Getting Started?" leaves once About
    /// You turns the Start Here guide on), and a sheet owned by that card vanished with it on the
    /// first tap. The door stays listed, and its sheet up, until the sheet is dismissed.
    @State private var openDoor: HelpDoor?

    private var expanded: Binding<Bool> {
        Binding(
            get: { settings.helpDoorsExpanded(area) },
            set: { settings.setHelpDoorsExpanded(area, $0) }
        )
    }

    var body: some View {
        if settings.showsHelpDoors(area) {
            let listed = HelpDoorCatalog.doors(for: area, settings: settings, sunnah: sunnah)
            let doors = keepingOpenDoor(listed)
            if !doors.isEmpty {
                Section(header: SectionPillHeader(title: "NEED A HAND?", count: doors.count,
                                                  icon: "questionmark.circle.fill", isExpanded: expanded)) {
                    // Folded, the cards are not in the List at all: no empty row, no card-shaped gap.
                    if expanded.wrappedValue {
                        // One row, 8 pt between cards like the grid tiles, and 1 pt of vertical padding so
                        // the row's own inset lands the cards 17 pt from the section's edges on every side
                        // (the Islam grid's measured rule).
                        VStack(spacing: 8) {
                            ForEach(doors) { door in
                                HelpDoorCard(door: door, area: area) { openDoor = door }
                            }
                        }
                        .padding(.vertical, 1)
                        .listRowSeparator(.hidden)
                        // ONE presenter for every card, on the section's single row (never on the
                        // Section itself: that bridges one Bool to every child). The sheet reads the
                        // door's current form, so its choices show their live state.
                        .sheet(isPresented: Binding(get: { openDoor != nil }, set: { if !$0 { openDoor = nil } })) {
                            if let openDoor {
                                HelpDoorSheet(door: listed.first(where: { $0.id == openDoor.id }) ?? openDoor)
                            }
                        }
                    }
                }
            }
        }
    }

    /// The catalog's doors, plus the open one if its own choice just took it off the catalog.
    private func keepingOpenDoor(_ listed: [HelpDoor]) -> [HelpDoor] {
        guard let openDoor, !listed.contains(where: { $0.id == openDoor.id }) else { return listed }
        return listed + [openDoor]
    }
}

/// One door as a clear-glass card: the chip, the question, the caption under it, and the setting's
/// state in a pill. Tap opens the door's sheet; press and hold opens its menu (`GridTileMenu`).
private struct HelpDoorCard: View {
    let door: HelpDoor
    let area: HelpDoorArea
    /// Opens the door's sheet, which the section presents (`HelpDoorsSection.openDoor`).
    let open: () -> Void

    @Environment(\.appearance) private var appearance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// At the accessibility sizes the question wraps to several lines and a pill beside it would be a
    /// sliver, so the pill goes under the caption.
    private var stacks: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        GridTileMenu {
            Settings.shared.hapticFeedback()
            open()
        } menu: {
            menuItems
        } label: {
            card
        }
    }

    private var card: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: door.systemImage, tint: door.tint, secondaryTint: door.secondaryTint, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(door.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(door.caption)
                    .font(.caption)
                    .foregroundColor(.secondaryOnGlass)
                    .lineLimit(stacks ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)

                if stacks, let value = door.value {
                    statePill(value)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !stacks, let value = door.value {
                statePill(value)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // Clear glass, the tiles' own surface; nothing is tinted, so the pill alone says what is on.
        .conditionalGlassEffect(clear: true, rectangle: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(door.title)
        .accessibilityValue(door.value ?? "")
        .accessibilityHint(door.caption)
    }

    /// The state, accent while the setting is on and quiet while it is not. A capsule fill rather than
    /// a second layer of glass: glass on glass reads as a smudge.
    private func statePill(_ value: String) -> some View {
        Text(value)
            .font(.caption.weight(.semibold))
            .foregroundStyle(door.isOn ? appearance.accent : Color.secondaryOnGlass)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(door.isOn ? appearance.accent.opacity(0.16) : Color.primary.opacity(0.08))
            )
            .fixedSize()
    }

    @ViewBuilder
    private var menuItems: some View {
        ForEach(door.actions) { action in
            Button {
                Settings.shared.hapticFeedback()
                action.perform()
            } label: {
                Label(action.title, systemImage: action.isChosen ? "checkmark" : action.systemImage)
            }
        }

        if !door.actions.isEmpty {
            Divider()
        }

        Button {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { Settings.shared.setHelpDoorsExpanded(area, false) }
        } label: {
            Label("Collapse These Questions", systemImage: "chevron.up.circle")
        }

        // The whole section, header and all; the tab's settings page (and Look and Feel) bring it back.
        Button {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { Settings.shared.setShowsHelpDoors(area, false) }
        } label: {
            Label("Hide on This Tab", systemImage: "eye.slash")
        }
    }
}

/// The sheet a door opens: a stack container (so a page can push its own sub-screens) around the
/// door's landing, with the house X to close.
private struct HelpDoorSheet: View {
    let door: HelpDoor

    var body: some View {
        SheetNavigationContainer {
            landing
                .sheetDismissToolbar()
        }
        .smallMediumSheetPresentation()
    }

    @ViewBuilder
    private var landing: some View {
        switch door.landing {
        case .screen(let screen):
            screen()
        case .page(let destination):
            SettingsSearchDestinationView.page(for: destination)
        case .answer(let answer, let pages):
            HelpDoorAnswerPage(door: door, answer: answer, pages: pages)
        }
    }
}

/// The question answered on one screen: the control that answers it, then the pages that hold the
/// rest of that setting's options.
private struct HelpDoorAnswerPage: View {
    let door: HelpDoor
    let answer: () -> AnyView
    let pages: [SettingsSearchEntry.Destination]

    var body: some View {
        List {
            Group {
                Section {
                    answer()
                }

                Section(header: Text("MORE OPTIONS")) {
                    ForEach(pages.indices, id: \.self) { index in
                        NavigationLink(destination: LazyDestination {
                            SettingsSearchDestinationView.page(for: pages[index])
                        }) {
                            HelpDoorPageLabel(destination: pages[index], tint: door.tint,
                                              secondaryTint: door.secondaryTint)
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(door.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A settings page as the row the settings roots draw for it: its icon, its title, its caption.
private struct HelpDoorPageLabel: View {
    @ObservedObject private var settings = Settings.shared

    let destination: SettingsSearchEntry.Destination
    let tint: Color
    var secondaryTint: Color? = nil

    var body: some View {
        let page = Self.describe(destination)
        SettingsRowLabel(title: page.title, systemImage: page.systemImage, subtitle: page.caption,
                         tint: tint, secondaryTint: secondaryTint)
            .tint(settings.accentColor.color)
    }

    private static func describe(_ destination: SettingsSearchEntry.Destination) -> (title: String, systemImage: String, caption: String?) {
        switch destination {
        case .quranPage(let page): return (page.title, page.systemImage, page.caption)
        case .hadithPage(let page): return (page.title, page.systemImage, page.caption)
        case .islamPage(let page): return (page.title, page.systemImage, page.caption)
        case .prayerPage(let page): return (page.title, page.systemImage, page.caption)
        case .notificationsPage(let page): return (page.title, page.systemImage, page.caption)
        default: return ("More Settings", destination.icon, nil)
        }
    }
}

// MARK: - The answers

/// "Need Help Reading?": Arabic Beginner Mode, the switch Arabic Text keeps below its fonts and sizes.
private struct BeginnerModeAnswer: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Enable Arabic Beginner Mode", isOn: $settings.beginnerMode.animation(.easeInOut))
                .font(.subheadline)
                .disabled(!settings.showArabicText)
                .onChange(of: settings.beginnerMode) { _ in settings.hapticFeedback() }

            Text(settings.showArabicText
                 ? "Puts a space between each Arabic letter to make it easier for beginners to read the Quran."
                 : "The Arabic is hidden, so there is nothing to space out. Arabic Text, below, shows it again.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
    }
}

/// "Reading in One Language?": the hadith's Arabic and English as one three-way choice.
private struct HadithLanguageAnswer: View {
    @ObservedObject private var settings = Settings.shared

    /// Plain, never animated: an animated selection binding makes the segmented indicator slide, snap
    /// back and slide again. The change itself animates inside `apply`.
    private var selection: Binding<HadithReadingLanguage> {
        Binding(
            get: { HadithReadingLanguage.current(settings) },
            set: { choice in
                guard choice != HadithReadingLanguage.current(settings) else { return }
                settings.hapticFeedback()
                choice.apply(to: settings)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Read Each Hadith In")
                .font(.subheadline)

            Picker("Read Each Hadith In", selection: selection) {
                ForEach(HadithReadingLanguage.allCases) { choice in
                    Text(choice.shortTitle).tag(choice)
                }
            }
            .pickerStyle(.segmented)

            Text("Arabic hides the translation and its narrator line; English hides the Arabic. Both stays the way the books are printed here.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
    }
}

/// "When Does Your Day Begin?": the daily cards' turnover, which Libraries shows only with Advanced
/// Settings on. Answered here, so opening the question does not have to turn that switch on.
private struct DayBeginsAnswer: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Turn Over at Fajr", isOn: $settings.dailyRolloverAtFajr.animation(.easeInOut))
                .font(.subheadline)
                .onChange(of: settings.dailyRolloverAtFajr) { _ in
                    settings.hapticFeedback()
                    settings.dailyRolloverSwitchChanged()
                }

            Text("Every daily feature changes at Fajr rather than at midnight, so the day begins with the prayer. Without a location set, the boundary is midnight.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
    }
}

// MARK: - On each tab's settings page

/// A tab's questions, named on that tab's own settings page, with the switch that shows or hides them
/// there (Abu, 2026-09-28: "mention parts of it in each respective settings"). Look and Feel keeps one
/// switch for all four.
struct HelpDoorsSettingsSection: View {
    @ObservedObject private var settings = Settings.shared

    let area: HelpDoorArea

    private var shown: Binding<Bool> {
        Binding(
            get: { settings.showsHelpDoors(area) },
            set: { newValue in
                settings.hapticFeedback()
                settings.setShowsHelpDoors(area, newValue)
            }
        )
    }

    var body: some View {
        // Only the titles are read here, so the Sunnah store is not observed.
        let doors = HelpDoorCatalog.doors(for: area, settings: settings, sunnah: SunnahReminderStore.shared)
        Section(header: Text("NEED A HAND?")) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading) {
                    Toggle("Show on the \(area.tabName) Tab", isOn: shown.animation(.easeInOut))
                        .font(.subheadline)

                    Text("A few questions \(area.placement), each opening the setting that answers it. The arrow beside NEED A HAND? on the tab folds them away.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(doors) { door in
                        HStack(spacing: 10) {
                            AccentIconChip(systemImage: door.systemImage, tint: door.tint,
                                           secondaryTint: door.secondaryTint, size: 22)

                            VStack(alignment: .leading, spacing: 0) {
                                Text(door.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.primary)

                                Text(door.answerName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .opacity(settings.showsHelpDoors(area) ? 1 : 0.5)
                .padding(.bottom, 2)
            }
        }
    }
}
#endif
