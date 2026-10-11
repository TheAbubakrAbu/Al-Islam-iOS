import Combine
import SwiftUI

// The readers and settings that use Test Mode are iOS only; the file is in the Watch target with
// SurahView, its group sibling, and compiles to nothing there.
#if os(iOS)

// MARK: - Test Mode
//
// Abu, 2026-10-11: "Add a button for list and page mode in the play button called test mode where unless
// I select an ayah it's hidden and have an option in settings to have it hide just Arabic or everything or
// to have it where it only shows selected ayah or all ayahs before in the surah."
//
// While it is on, both readers hide the Quran's text, and an ayah shows when it is tapped (or, by default,
// when the reciter reaches it). Hidden text keeps its exact size and place: a list row draws a soft bar
// where its lines were, and a mushaf page draws the ayah in clear ink over a faint bar with its number
// ornament still showing, so the page never re-flows and there is always something to tap. The printed
// (PDF) mushaf is a picture of the page and cannot hide one ayah, so Test Mode is offered on text pages.

/// What Test Mode hides. Stored as `Settings.quranTestModeHides`.
enum QuranTestHiding: String, CaseIterable, Identifiable {
    /// The recitation: the Arabic, and its transliteration (the same words in Latin letters). The
    /// translations stay on screen, as the cue to recite from.
    case recitation = "arabic"
    /// Every line of the ayah.
    case everything

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recitation: return "Arabic Only"
        case .everything: return "Everything"
        }
    }

    var caption: String {
        switch self {
        case .recitation:
            return "Hides the Arabic and its transliteration. Translations stay, as your cue."
        case .everything:
            return "Hides every line of the ayah, translations included."
        }
    }
}

/// What a tap on an ayah shows. Stored as `Settings.quranTestModeReveals`.
enum QuranTestReveal: String, CaseIterable, Identifiable {
    /// The tapped ayah alone: tapping another ayah hides this one again.
    case selected
    /// The tapped ayah and everything before it in its surah.
    case throughSelected

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selected: return "Only the Selected Ayah"
        case .throughSelected: return "The Selected Ayah and Everything Before It"
        }
    }
}

/// What one list row hides while Test Mode is on (see `AyahRow.testVeil`).
enum QuranTestVeil: Equatable {
    /// The Arabic and the transliteration.
    case recitation
    /// Every line.
    case everything
}

extension Settings {
    var quranTestHiding: QuranTestHiding { QuranTestHiding(rawValue: quranTestModeHides) ?? .recitation }
    var quranTestReveal: QuranTestReveal { QuranTestReveal(rawValue: quranTestModeReveals) ?? .selected }
}

/// Test Mode's session: whether it is on, and which ayahs the listener has shown so far.
///
/// One shared store, like `AyahDisplayOverrides`, because both readers (and the page reader's every
/// mounted page) ask it the same question, and what was shown has to survive a row being recycled and a
/// page being turned. The tap MARK cannot carry it: a page turn clears the mark, which would hide again
/// everything "the selected ayah and everything before it" had shown.
///
/// What was shown is never saved: a test starts hidden every time Test Mode is turned on.
@MainActor
final class QuranTestMode: ObservableObject {
    static let shared = QuranTestMode()

    @Published private(set) var isOn: Bool
    /// `.selected`: the one ayah showing.
    @Published private(set) var shownAyah: HighlightedAyahRef?
    /// `.throughSelected`: per surah, the last ayah showing; every ayah before it shows too.
    @Published private(set) var shownThrough: [Int: Int] = [:]

    /// Readers on screen (`QuranTestReaderLease`), for "turn off when leaving the reader".
    private(set) var openReaders = 0
    private let settings = Settings.shared
    private var recitationSink: AnyCancellable?

    private init() {
        // Back on at launch only for a listener who keeps it on until they turn it off. Otherwise a
        // reader left open when the app was quit must not reopen with its text hidden.
        isOn = !settings.quranTestModeEndsOnLeave && settings.quranTestModeStoredOn
        #if DEBUG
        // `-testMode`: opens with Test Mode on, for verifying the hidden readers from `simctl`.
        if ProcessInfo.processInfo.arguments.contains("-testMode") { isOn = true }
        #endif
        ObjectPublishCounter.attach(self, label: "QuranTestMode")
        // "Reveal as It's Recited", from the player's coalesced snapshot rather than a reader's
        // `onChange`: the snapshot publishes once per advance on the main queue, and revealing in the
        // same turn folds this publish into the render that advance already costs, in both readers.
        recitationSink = QuranPlayer.shared.nowPlaying.$snapshot
            .map { RecitedAyah(surah: $0.currentSurahNumber, ayah: $0.currentAyahNumber) }
            .removeDuplicates()
            .sink { [weak self] reached in
                guard let surah = reached.surah, let ayah = reached.ayah else { return }
                MainActor.assumeIsolated { self?.recited(surah: surah, ayah: ayah) }
            }
    }

    private struct RecitedAyah: Equatable {
        let surah: Int?
        let ayah: Int?
    }

    /// Turns Test Mode on or off. Either way every ayah starts hidden again, except the one being recited
    /// when it turns on mid-recitation: it shows at once (with "Reveal as It's Recited") rather than at
    /// the next advance.
    func setOn(_ on: Bool) {
        guard on != isOn else { return }
        isOn = on
        clearShown()
        syncStoredOn()
        let playing = QuranPlayer.shared.nowPlaying.snapshot
        if on, playing.isPlaying, let surah = playing.currentSurahNumber, let ayah = playing.currentAyahNumber {
            recited(surah: surah, ayah: ayah)
        }
    }

    /// Keeps `quranTestModeStoredOn` true exactly while Test Mode is on AND kept on until turned off: the
    /// only case a launch reads it. Written only when it changes, so with "Turn Off When Leaving the
    /// Reader" on (the default) closing a reader writes no defaults at all. A defaults write republishes
    /// Settings across the app, and this one would land in the middle of the pop
    /// ([[appstorage-write-during-navigation]]). The settings switch calls this when it flips.
    func syncStoredOn() {
        let stored = isOn && !settings.quranTestModeEndsOnLeave
        if settings.quranTestModeStoredOn != stored { settings.quranTestModeStoredOn = stored }
    }

    /// Hides every ayah again without leaving Test Mode (the play menu's "Hide All Again").
    func hideAll() {
        clearShown()
    }

    var hasShownAnything: Bool { shownAyah != nil || !shownThrough.isEmpty }

    /// A tap on an ayah. It toggles, like the tap's mark does: tapping the ayah that is showing (the LAST
    /// one, under `.throughSelected`) hides it again; tapping one already showing earlier changes nothing.
    func select(surah: Int, ayah: Int) {
        guard isOn else { return }
        switch settings.quranTestReveal {
        case .selected:
            let tapped = HighlightedAyahRef(surahID: surah, ayahID: ayah)
            shownAyah = shownAyah == tapped ? nil : tapped
        case .throughSelected:
            let through = shownThrough[surah] ?? 0
            if ayah > through {
                shownThrough[surah] = ayah
            } else if ayah == through {
                shownThrough[surah] = ayah > 1 ? ayah - 1 : nil
            }
        }
    }

    /// The reciter reaching an ayah ("Reveal as It's Recited"): shows it by the same rule, never hides one.
    func recited(surah: Int, ayah: Int) {
        guard isOn, settings.quranTestModeRevealsRecited else { return }
        switch settings.quranTestReveal {
        case .selected:
            let reached = HighlightedAyahRef(surahID: surah, ayahID: ayah)
            if shownAyah != reached { shownAyah = reached }
        case .throughSelected:
            if ayah > (shownThrough[surah] ?? 0) { shownThrough[surah] = ayah }
        }
    }

    func isHidden(surah: Int, ayah: Int) -> Bool {
        guard isOn else { return false }
        switch settings.quranTestReveal {
        case .selected:
            return shownAyah?.surahID != surah || shownAyah?.ayahID != ayah
        case .throughSelected:
            return ayah > (shownThrough[surah] ?? 0)
        }
    }

    /// What a list row hides, nil when it shows.
    func veil(surah: Int, ayah: Int) -> QuranTestVeil? {
        guard isHidden(surah: surah, ayah: ayah) else { return nil }
        return settings.quranTestHiding == .everything ? .everything : .recitation
    }

    /// Whether a mushaf page in `language` has text Test Mode hides: the Arabic and the transliteration
    /// always, a translation only under "Everything", and the printed facsimile never (it is a picture).
    func hides(pageLanguage language: MushafPageLanguage) -> Bool {
        switch language {
        case .arabic, .transliteration: return true
        case .clearQuran, .saheeh: return settings.quranTestHiding == .everything
        case .pdf: return false
        }
    }

    func readerOpened() {
        openReaders += 1
    }

    func readerClosed() {
        openReaders = max(0, openReaders - 1)
        if openReaders == 0, settings.quranTestModeEndsOnLeave {
            setOn(false)
        }
    }

    private func clearShown() {
        if shownAyah != nil { shownAyah = nil }
        if !shownThrough.isEmpty { shownThrough = [:] }
    }
}

/// Held by every reader as a `@StateObject`, which lives exactly as long as the reader is in its
/// navigation stack: a screen pushed over the reader, a sheet or a tab switch keep it, and popping the
/// reader lets it go. That is "leaving the reader" for `quranTestModeEndsOnLeave`, which an
/// `onDisappear` cannot tell apart from a push. Counted, so a reader opened from inside another one
/// does not end the test for the reader underneath when it closes.
@MainActor
final class QuranTestReaderLease: ObservableObject {
    init() {
        QuranTestMode.shared.readerOpened()
    }

    deinit {
        Task { @MainActor in QuranTestMode.shared.readerClosed() }
    }
}

/// Test Mode's rows in the readers' play menus, the list's and the page's alike, and in the playing bar's
/// long-press menu while a recitation plays: the switch, and while it is on, "Hide All Again".
/// `available` is false on the printed (PDF) page, which cannot hide one ayah: there it can only be
/// turned OFF.
///
/// No `withAnimation`: it would animate every observer's re-render, the reader's whole List included,
/// and each veil and the badge animate themselves.
@MainActor
@ViewBuilder
func quranTestModeMenuItems(settings: Settings, testMode: QuranTestMode, available: Bool) -> some View {
    Toggle(isOn: Binding(
        get: { testMode.isOn },
        set: { on in
            settings.hapticFeedback()
            testMode.setOn(on)
        }
    )) {
        Label(available || testMode.isOn ? "Test Mode" : "Test Mode (Text Pages Only)", systemImage: "eye.slash")
    }
    // The app root styles every Toggle as a padded switch, which draws a menu row as a label plus an
    // empty second line; the automatic style hands the row back to the menu (`ayahDisplayMenuItems`).
    .toggleStyle(.automatic)
    .disabled(!available && !testMode.isOn)

    if testMode.isOn, testMode.hasShownAnything {
        Button {
            settings.hapticFeedback()
            testMode.hideAll()
        } label: {
            Label("Hide All Again", systemImage: "arrow.counterclockwise")
        }
    }
}

/// The play menus' Test Mode rows as a view that observes the store itself, so the page reader can host
/// them without observing it: that reader is too heavy to re-run on every reveal, and an open menu has
/// to show the switch as it is now.
struct QuranTestModeMenuSection: View {
    let settings: Settings
    let available: Bool
    @ObservedObject private var testMode = QuranTestMode.shared

    var body: some View {
        quranTestModeMenuItems(settings: settings, testMode: testMode, available: available)
    }
}

/// `QuranTestModeBadge` while Test Mode is on, observing the store itself for the same reason as
/// `QuranTestModeMenuSection`. Nudged out to the button's corner.
struct QuranTestModeBadgeSlot: View {
    let accent: Color
    @ObservedObject private var testMode = QuranTestMode.shared

    var body: some View {
        ZStack {
            if testMode.isOn {
                QuranTestModeBadge(accent: accent)
                    .offset(x: 3, y: -3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: testMode.isOn)
    }
}

/// The small eye-slash on a reader's play button while Test Mode is on, so hidden text always has a
/// visible reason (and the button that turns it off is the one wearing it).
struct QuranTestModeBadge: View {
    let accent: Color

    var body: some View {
        Image(systemName: "eye.slash.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(4)
            .background(Circle().fill(accent))
            .accessibilityLabel("Test Mode is on")
    }
}

extension View {
    /// A list row's line while Test Mode hides it: laid out exactly as it would be (so the list never
    /// moves when it shows), its ink taken away, and a soft bar where it was.
    func quranTestVeiled(_ hidden: Bool) -> some View {
        modifier(QuranTestVeilModifier(hidden: hidden))
    }
}

private struct QuranTestVeilModifier: ViewModifier {
    let hidden: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hidden ? 0 : 1)
            .overlay {
                if hidden {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.07))
                        .transition(.opacity)
                }
            }
            .accessibilityHidden(hidden)
            .animation(.easeInOut(duration: 0.2), value: hidden)
    }
}

/// Settings → Al-Quran → Test Mode (Abu: "make it a whole navigation link for test mode").
struct QuranTestModeSettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var testMode = QuranTestMode.shared

    var body: some View {
        List {
            Group {
                Section {
                    VStack(alignment: .leading) {
                        Toggle("Test Mode", isOn: Binding(
                            get: { testMode.isOn },
                            set: { on in
                                settings.hapticFeedback()
                                testMode.setOn(on)
                            }
                        ))
                        .font(.subheadline)

                        Text("Hides the Quran's text in the list and page readers until you tap an ayah, so you can recite from memory and check yourself. In the reader, the play button's menu turns it on and off, and the button wears a small eye while it is on. While a recitation plays, hold the playing bar for the same switch. The printed mushaf (PDF) can't hide single ayahs, so it works on text pages.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }
                }

                Section(header: Text("WHAT IT HIDES")) {
                    Picker("What It Hides", selection: $settings.quranTestModeHides) {
                        ForEach(QuranTestHiding.allCases) { hiding in
                            Text(hiding.title).tag(hiding.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: settings.quranTestModeHides) { _ in settings.hapticFeedback() }

                    Text(settings.quranTestHiding.caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(header: Text("WHAT A TAP SHOWS")) {
                    Picker("What a Tap Shows", selection: $settings.quranTestModeReveals) {
                        ForEach(QuranTestReveal.allCases) { reveal in
                            Text(reveal.title).tag(reveal.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: settings.quranTestModeReveals) { _ in
                        settings.hapticFeedback()
                        // The two remember different things, so a switch starts the test over.
                        testMode.hideAll()
                    }

                    Text("Tap the ayah that is showing to hide it again. \"Hide All Again\" in the play menu starts over.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    VStack(alignment: .leading) {
                        Toggle("Reveal as It's Recited", isOn: $settings.quranTestModeRevealsRecited.animation(.easeInOut))
                            .font(.subheadline)
                            .onChange(of: settings.quranTestModeRevealsRecited) { _ in settings.hapticFeedback() }

                        Text("While an ayah plays, it shows the way a tap would show it. Off, the highlight moves across the hidden text so you can follow the reciter without seeing the words.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }

                    VStack(alignment: .leading) {
                        Toggle("Turn Off When Leaving the Reader", isOn: $settings.quranTestModeEndsOnLeave.animation(.easeInOut))
                            .font(.subheadline)
                            .onChange(of: settings.quranTestModeEndsOnLeave) { _ in
                                settings.hapticFeedback()
                                testMode.syncStoredOn()
                            }

                        Text("On, closing the surah you are reading turns Test Mode off, so the Quran never opens with its text hidden. Off, it stays on, across launches too, until you turn it off.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Test Mode")
    }
}
#endif
