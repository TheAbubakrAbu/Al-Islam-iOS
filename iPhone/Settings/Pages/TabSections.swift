// Only where a tab has a foldable section (the Adhan and Hadith tabs today): in Al-Quran every case
// below compiles out, and an enum with no cases made each function here "will never be executed".
#if os(iOS) && (HAS_ADHAN || HAS_HADITH)
import SwiftUI

// Sections a tab can fold or put away (Abu, 2026-10-28, from a reader's 4.6.5 feedback: a way to hide
// the prayer tracker, to collapse At a Glance, and to see At a Glance in Simple Mode; "not just for
// adhan but lets start with al adhan right now").
//
// - A `TabSection` is one optional section of a tab's root List. Its header is a `TabSectionHeader`:
//   the arrow folds the rows away (folded, they are not in the List at all, as NEED A HAND? does it),
//   and a folded section's trash takes it off the tab after a confirmation.
// - Each tab's settings page carries a switch per section (`TabSectionsSettingsSection`), in Simple
//   Mode too: that switch is how a section Simple Mode leaves out comes back.
// - Two keys hold it all (Settings.swift): the reader's choice per section and the folded set. A
//   section nobody chose follows its default: shown, or Simple Mode's rule where the section has one
//   (`simpleModeHides`). A choice wins in both modes, so At a Glance turned on stays on in Simple Mode
//   and the tracker turned off stays off in Full.
// - Hiding never changes behaviour (Simple Mode's rule 1): with the tracker off, a prayer is still
//   marked from its detail and from its notification, and History & Insights stays in Prayer Settings.
//
// NEED A HAND? keeps its own pair of keys and its own switch (HelpDoors.swift), since it shipped first.
// A new section on any tab: a case here (key, area, header, name, icon, caption), a `TabSectionHeader`
// on its Section with its rows behind `tabSectionExpanded`, `showsTabSection` around the Section, and
// a `TabSectionsSettingsSection(area:)` on that tab's settings page if it has none yet.
// No em dashes and no spaced hyphens in any of this text (house rule).

/// One optional section of a tab's root, which the reader can fold or put away.
/// Each app lists only the sections of the tabs it has (HAS_ADHAN, HAS_HADITH): the sibling apps
/// share this file.
/// No raw type, so an app with none of these tabs still compiles the empty enum.
enum TabSection: CaseIterable, Identifiable {
    #if HAS_ADHAN
    /// PRAYER TRACKER, under the prayer times.
    case adhanTracker
    /// AT A GLANCE, at the foot of the Adhan tab.
    case adhanGlance
    #endif
    #if HAS_HADITH
    /// YOUR SUMMARY, the Hadith of the Day and Last Read tiles at the top of the Hadith tab.
    case hadithSummary
    /// ABOUT HADITH & THE SUNNAH, the five doors at the foot of the Hadith tab.
    case hadithAbout
    #endif

    /// The stored name, "tab.section". Never shown, never translated.
    var key: String {
        switch self {
        #if HAS_ADHAN
        case .adhanTracker: return "adhan.tracker"
        case .adhanGlance: return "adhan.glance"
        #endif
        #if HAS_HADITH
        case .hadithSummary: return "hadith.summary"
        case .hadithAbout: return "hadith.about"
        #endif
        }
    }

    var id: String { key }

    /// The tab the section sits on.
    var area: HelpDoorArea {
        switch self {
        #if HAS_ADHAN
        case .adhanTracker, .adhanGlance: return .adhan
        #endif
        #if HAS_HADITH
        case .hadithSummary, .hadithAbout: return .hadith
        #endif
        }
    }

    /// The header on the tab, in capitals like every section header there.
    var header: String {
        switch self {
        #if HAS_ADHAN
        case .adhanTracker: return String(localized: "PRAYER TRACKER")
        case .adhanGlance: return String(localized: "AT A GLANCE")
        #endif
        #if HAS_HADITH
        case .hadithSummary: return String(localized: "YOUR SUMMARY")
        case .hadithAbout: return String(localized: "ABOUT HADITH & THE SUNNAH")
        #endif
        }
    }

    /// The name on its switch and in a sentence.
    var name: String {
        switch self {
        #if HAS_ADHAN
        case .adhanTracker: return String(localized: "Prayer Tracker")
        case .adhanGlance: return String(localized: "At a Glance")
        #endif
        #if HAS_HADITH
        case .hadithSummary: return String(localized: "Your Summary")
        case .hadithAbout: return String(localized: "About Hadith & the Sunnah")
        #endif
        }
    }

    var systemImage: String {
        switch self {
        #if HAS_ADHAN
        case .adhanTracker: return "checkmark.circle.fill"
        case .adhanGlance: return "rectangle.grid.2x2.fill"
        #endif
        #if HAS_HADITH
        case .hadithSummary: return "sparkles"
        case .hadithAbout: return "text.book.closed.fill"
        #endif
        }
    }

    /// An accent title for a section that is yours (`SectionIconHeader.accentTitle`'s rule): the
    /// tracker holds your own marks and the summary your own reading; the glance tiles are facts about
    /// the day and the About doors are the app's pages.
    var accentTitle: Bool {
        switch self {
        #if HAS_ADHAN
        case .adhanTracker: return true
        case .adhanGlance: return false
        #endif
        #if HAS_HADITH
        case .hadithSummary: return true
        case .hadithAbout: return false
        #endif
        }
    }

    /// What the section is, under its switch on the settings page.
    var caption: String {
        switch self {
        #if HAS_ADHAN
        case .adhanTracker:
            return String(localized: "Today's prayers to mark and your streak, under the prayer times. Turned off, a prayer can still be marked from its detail or its notification.")
        case .adhanGlance:
            return String(localized: "Tiles at the foot of the tab: where you are, the Qibla, daylight, the fast, the moon and the next Islamic date.")
        #endif
        #if HAS_HADITH
        case .hadithSummary:
            return String(localized: "The Hadith of the Day and the hadith you last read, at the top of the tab. Turned off, History in the More menu still lists what you read.")
        case .hadithAbout:
            return String(localized: "Five pages at the foot of the tab: the Sunnah, what hadiths are, their sciences, how they were preserved and answering those who reject them. They stay on the Islam tab.")
        #endif
        }
    }

    /// Whether Simple Mode leaves the section off its tab while the reader has not chosen.
    func simpleModeHides(_ settings: Settings) -> Bool {
        switch self {
        #if HAS_ADHAN
        // Simple shows the tracker to someone who tracks: any prayer marked in the last
        // `SimpleMode.trackerWindowDays` (Docs/Product/Simple Mode Guide.md). At most fourteen lookups
        // into the cached tracker, so the countdown tick that re-renders the tab can ask.
        case .adhanTracker:
            return settings.hides(.prayerTracker, unless: settings.trackerMarkedRecently())
        // Each glance tile is a shortcut to a door the tab already has (the calendar, the compass, the
        // city pill, the sky's moon), so Simple leaves the wall out until it is turned on.
        case .adhanGlance:
            return settings.hides(.atAGlance)
        #endif
        #if HAS_HADITH
        // Simple keeps both: the summary is the two tiles a reader comes back for, and the About doors
        // are where a newcomer starts.
        case .hadithSummary, .hadithAbout:
            return false
        #endif
        }
    }

    /// The sections on one tab, in the order the tab shows them.
    static func sections(on area: HelpDoorArea) -> [TabSection] {
        allCases.filter { $0.area == area }
    }
}

extension HelpDoorArea {
    /// The header over this tab's section switches on its settings page.
    var tabSectionsHeader: String {
        switch self {
        #if HAS_ADHAN
        case .adhan: return String(localized: "ON THE ADHAN TAB")
        #endif
        #if HAS_QURAN
        case .quran: return String(localized: "ON THE QURAN TAB")
        #endif
        #if HAS_HADITH
        case .hadith: return String(localized: "ON THE HADITH TAB")
        #endif
        case .islam: return String(localized: "ON THE ISLAM TAB")
        }
    }
}

// MARK: - The two stored lists

/// The rules on plain strings, so they are tested on their own (SimpleModeTests).
enum TabSectionStore {
    /// "adhan.glance:1,adhan.tracker:0" as [key: shown]. An entry this build does not know is kept, so
    /// a section a later version adds survives a write from this one.
    static func choices(_ raw: String) -> [String: Bool] {
        var choices: [String: Bool] = [:]
        for item in raw.split(separator: ",") {
            let parts = item.split(separator: ":", maxSplits: 1)
            guard parts.count == 2, parts[1] == "0" || parts[1] == "1" else { continue }
            choices[String(parts[0])] = parts[1] == "1"
        }
        return choices
    }

    /// Sorted by key, so the same choices always store as the same string.
    static func choicesRaw(_ choices: [String: Bool]) -> String {
        choices.keys.sorted().map { "\($0):\(choices[$0] == true ? 1 : 0)" }.joined(separator: ",")
    }

    static func keys(_ raw: String) -> Set<String> {
        Set(raw.split(separator: ",").map(String.init))
    }

    static func keysRaw(_ keys: Set<String>) -> String {
        keys.sorted().joined(separator: ",")
    }

    /// The reader's choice where there is one; otherwise shown unless Simple Mode leaves it out.
    static func shows(choice: Bool?, simpleModeHides: () -> Bool) -> Bool {
        choice ?? !simpleModeHides()
    }
}

extension Settings {
    /// The reader's own choice for a section: true shown, false put away, nil never chosen.
    func tabSectionChoice(_ section: TabSection) -> Bool? {
        TabSectionStore.choices(tabSectionChoicesRaw)[section.key]
    }

    /// Records a choice (nil forgets it, back to the default). A section brought back comes back open:
    /// the reader turning it on wants to see it, not its folded header.
    func setTabSectionChoice(_ section: TabSection, _ shown: Bool?) {
        var choices = TabSectionStore.choices(tabSectionChoicesRaw)
        choices[section.key] = shown
        let raw = TabSectionStore.choicesRaw(choices)
        if raw != tabSectionChoicesRaw { tabSectionChoicesRaw = raw }
        if shown == true, !tabSectionExpanded(section) { setTabSectionExpanded(section, true) }
    }

    /// Whether the section is on its tab at all.
    func showsTabSection(_ section: TabSection) -> Bool {
        TabSectionStore.shows(choice: tabSectionChoice(section)) { section.simpleModeHides(self) }
    }

    /// Whether the section's rows are showing under its header, or folded away (the header's arrow).
    func tabSectionExpanded(_ section: TabSection) -> Bool {
        !TabSectionStore.keys(tabSectionsCollapsedRaw).contains(section.key)
    }

    func setTabSectionExpanded(_ section: TabSection, _ expanded: Bool) {
        var collapsed = TabSectionStore.keys(tabSectionsCollapsedRaw)
        if expanded { collapsed.remove(section.key) } else { collapsed.insert(section.key) }
        let raw = TabSectionStore.keysRaw(collapsed)
        if raw != tabSectionsCollapsedRaw { tabSectionsCollapsedRaw = raw }
    }
}

// MARK: - The header on the tab

/// A foldable section's header: its title, the section's own read-out (the tracker's streak, the
/// summary's Today pill), then the trash while folded and the fold arrow (`SectionFoldControls`). The
/// trash asks first; the tab's settings page brings the section back. The dialog hangs off the
/// header, the one view of the section that is on screen while it is folded.
struct TabSectionHeader<Readout: View>: View {
    private let settings = Settings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared

    let section: TabSection
    /// `SectionHeaderLine.forceStacked`: a read-out as wide as the Today pill drops under the title at
    /// the accessibility text sizes.
    private let forceStacked: Bool
    private let readout: () -> Readout

    @State private var confirmingRemove = false

    init(_ section: TabSection, forceStacked: Bool = false, @ViewBuilder readout: @escaping () -> Readout) {
        self.section = section
        self.forceStacked = forceStacked
        self.readout = readout
    }

    private var expanded: Binding<Bool> {
        Binding(
            get: { settings.tabSectionExpanded(section) },
            set: { settings.setTabSectionExpanded(section, $0) }
        )
    }

    var body: some View {
        SectionHeaderLine(section.header, icon: section.systemImage, accentTitle: section.accentTitle,
                          forceStacked: forceStacked) {
            readout()
            SectionFoldControls(title: section.header, isExpanded: expanded, onRemove: { confirmingRemove = true })
        }
        .confirmationDialog(String(localized: "Remove \(section.name)?"), isPresented: $confirmingRemove, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) { settings.setTabSectionChoice(section, false) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It leaves the \(section.area.tabName) tab. You can bring it back in \(section.area.settingsPageName).")
        }
    }
}

extension TabSectionHeader where Readout == EmptyView {
    init(_ section: TabSection) {
        self.init(section) { EmptyView() }
    }
}

// MARK: - The switches on the settings page

/// A tab's foldable sections on that tab's own settings page, a switch each. Shown in Simple Mode too:
/// the switch is how a section Simple Mode leaves out comes back. Each switch reads what the tab shows
/// right now, so in Simple Mode At a Glance reads off until it is turned on.
struct TabSectionsSettingsSection: View {
    private let settings = Settings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared

    let area: HelpDoorArea

    var body: some View {
        let sections = TabSection.sections(on: area)
        if !sections.isEmpty {
            Section(header: Text(area.tabSectionsHeader), footer: Text(footer(sections))) {
                ForEach(sections) { section in
                    SettingsToggle(section.name, caption: section.caption, isOn: shown(section))
                }
            }
        }
    }

    private func shown(_ section: TabSection) -> Binding<Bool> {
        Binding(
            get: { settings.showsTabSection(section) },
            set: { settings.setTabSectionChoice(section, $0) }
        )
    }

    /// How the tab's own controls work, and, while Simple Mode is leaving any of these out, which.
    private func footer(_ sections: [TabSection]) -> String {
        let howTo = String(localized: "On the tab, the arrow beside a section's title folds it. A folded section's trash removes it until it is turned on here.")
        let leftOut = sections
            .filter { settings.tabSectionChoice($0) == nil && $0.simpleModeHides(settings) }
            .map(\.name)
        guard let first = leftOut.first else { return howTo }
        if leftOut.count == 1 {
            return howTo + " " + String(localized: "Simple Mode leaves out \(first) until it is turned on here.")
        }
        let names = leftOut.sentenceList { String(localized: "\($0.dropLast().joined(separator: ", ")) and \($0.last!)") }
        return howTo + " " + String(localized: "Simple Mode leaves out \(names) until they are turned on here.")
    }
}
#endif
