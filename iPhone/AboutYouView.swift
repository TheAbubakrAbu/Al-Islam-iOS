#if os(iOS)
import SwiftUI

// About You: the one question the app asks everyone (Abu, 2026-09-20: "add a mini onboarding tutorial
// asking if you are a born Muslim, a revert, or a beginner Muslim who is just getting on or a non
// muslim learning more (and like show quran and islam tabs if you are a new Muslim)... do it for
// every user on the app even if they already have it").
//
// Two short pages. The first asks; the second answers back with the four tabs in the order and the
// words that suit the answer, a few settings worth turning on, and, for anyone who is here to learn,
// the Start Here guide that then opens the Islam tab. It is a ROOT STAGE (`AlIslamApp.rootStage`),
// not a sheet: as a sheet it would have raced the location prompt, the traveling dialog, the review
// prompt and a tapped notification's question for the first seconds of a launch, and as a stage all
// of those simply wait (`appRevealed` stays false until it is answered or skipped).
//
// The answer never leaves the device. It is read in two places only: `StartHere` (the Islam tab's
// guide) and the About You screen in Settings, which changes it.

// MARK: - The answer

enum UserBackground: String, CaseIterable, Identifiable {
    case raised, revert, beginner, exploring

    var id: String { rawValue }

    var title: String {
        switch self {
        case .raised: return "Raised Muslim"
        case .revert: return "Revert"
        case .beginner: return "Just getting started"
        case .exploring: return "Learning about Islam"
        }
    }

    var subtitle: String {
        switch self {
        case .raised: return "I grew up with Islam."
        case .revert: return "I embraced Islam."
        case .beginner: return "I am new to practicing, or coming back to it."
        case .exploring: return "I am not Muslim, and I would like to understand it."
        }
    }

    var systemImage: String {
        switch self {
        case .raised: return "house.fill"
        case .revert: return "heart.fill"
        case .beginner: return "leaf.fill"
        case .exploring: return "book.fill"
        }
    }

    /// Everyone but someone raised in it gets the Islam tab's guide (and can put it away).
    var wantsStartHere: Bool { self != .raised }

    /// The two answers that mean "I am here to learn": the welcome ends on the Islam tab, where the
    /// guide is, instead of on the prayer times.
    var landsOnIslamTab: Bool { self == .beginner || self == .exploring }
}

extension Settings {
    var userBackground: UserBackground? {
        get { UserBackground(rawValue: userBackgroundRaw) }
        set { userBackgroundRaw = newValue?.rawValue ?? "" }
    }
}

// MARK: - Start Here

/// One step of the Islam tab's guide. `resource` is an `IslamView.IslamDestination` raw value (the
/// enum is private to that view, which resolves it); nil is the one step that leaves the tab, for
/// the Quran.
struct StartHereStep: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let resource: String?
}

enum StartHere {
    static func isShown(_ settings: Settings) -> Bool {
        !settings.startHereHidden && settings.userBackground?.wantsStartHere == true
    }

    static func steps(for background: UserBackground) -> [StartHereStep] {
        switch background {
        case .exploring:
            return [
                .init(id: "beliefs", title: "What Muslims believe", subtitle: "The Five Pillars and the Six Beliefs, with their sources",
                      systemImage: "moon.stars", resource: "pillarsAndBasics"),
                .init(id: "quran", title: "Read the Quran in English", subtitle: "Every ayah with its translation, and each surah's background",
                      systemImage: "character.book.closed.ar", resource: nil),
                .init(id: "miracles", title: "Why Muslims trust it", subtitle: "Signs in the Quran, in creation, science, and history",
                      systemImage: "sparkle.magnifyingglass", resource: "miraclesOfQuran"),
                .init(id: "prophecies", title: "What the Prophet foretold", subtitle: "His prophecies, and what history did",
                      systemImage: "checkmark.seal", resource: "propheciesOfProphet"),
                .init(id: "names", title: "Who Allah is", subtitle: "His 99 Names, each with its meaning",
                      systemImage: "signature", resource: "namesOfAllah"),
            ]
        case .raised, .revert, .beginner:
            return [
                .init(id: "beliefs", title: "The foundations", subtitle: "The Five Pillars and the Six Beliefs, with their sources",
                      systemImage: "moon.stars", resource: "pillarsAndBasics"),
                .init(id: "guides", title: "Wudu and the prayer, step by step", subtitle: "How-To Guides for wudu, salah, Jumuah, and more",
                      systemImage: "list.bullet.rectangle", resource: "howToGuides"),
                .init(id: "alphabet", title: "The Arabic letters", subtitle: "Every letter and mark, with their sounds",
                      systemImage: "textformat.size.ar", resource: "arabicAlphabet"),
                .init(id: "duas", title: "Duas for every day", subtitle: "Authenticated supplications with their sources",
                      systemImage: "text.book.closed", resource: "commonDuas"),
                .init(id: "quran", title: "Read the Quran with help", subtitle: "Translation, transliteration, and a word's meaning with two taps",
                      systemImage: "character.book.closed.ar", resource: nil),
            ]
        }
    }

    static func visited(_ settings: Settings) -> Set<String> {
        Set(settings.startHereVisitedRaw.split(separator: ",").map(String.init))
    }

    /// Ticks a step off. Called from the Islam tab's one door for every resource, so a step counts
    /// as opened however it was reached; a no-op once recorded, and for resources no step names.
    static func markVisited(resource: String?, settings: Settings = .shared) {
        guard isShown(settings), let background = settings.userBackground,
              let step = steps(for: background).first(where: { $0.resource == resource }) else { return }
        var seen = visited(settings)
        guard seen.insert(step.id).inserted else { return }
        settings.startHereVisitedRaw = seen.sorted().joined(separator: ",")
    }
}

// MARK: - The welcome

struct AboutYouView: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss

    /// True when Settings replays it as a sheet over the running app: finishing dismisses the sheet
    /// and never moves the reader to another tab.
    var presentedAsSheet = false
    /// True for someone who met the splash in this very launch. Only then are the suggested settings
    /// switched on ahead of time; anyone who already had the app sees their own settings as they are,
    /// and nothing changes unless they change it.
    var isNewInstall = false

    @State private var choice: UserBackground?
    @State private var page = 0

    @State private var transliteration = false
    @State private var englishMeanings = false
    @State private var prayerNotifications = true
    @State private var didSeedSuggestions = false

    private var isDarkMode: Bool { (settings.colorScheme ?? systemColorScheme) == .dark }
    private var accent: Color { settings.accentColor.color }

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    Group {
                        if page == 0 {
                            questionPage
                                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                        removal: .move(edge: .leading).combined(with: .opacity)))
                        } else {
                            tailoredPage
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                        removal: .move(edge: .trailing).combined(with: .opacity)))
                        }
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 22)
                    .padding(.top, presentedAsSheet ? 24 : 36)
                    .padding(.bottom, 16)
                }

                actions
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .onAppear(perform: applyDebugArguments)
    }

    // MARK: Page one

    private var questionPage: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(accent)
                    .padding(.bottom, 2)

                Text("Which describes you best?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(AppIdentifiers.appName) shows you where to begin based on your answer. It stays on this \(deviceName), and you can change it in Settings.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ForEach(UserBackground.allCases) { option in
                    optionCard(option)
                }
            }
        }
    }

    private var deviceName: String {
        UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
    }

    private func optionCard(_ option: UserBackground) -> some View {
        let selected = choice == option
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) { choice = option }
        } label: {
            HStack(spacing: 14) {
                AccentIconChip(systemImage: option.systemImage, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(option.subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selected ? accent : Color.secondary.opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(cardSurface(selected: selected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title). \(option.subtitle)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// A plain filled card, the Notifications permission card's grammar. Not glass: this screen
    /// stands on an opaque ground, where clear glass has nothing to bend and drew no surface at all
    /// in the light themes (seen on the iPhone 17 Pro, 2026-09-20).
    private func cardSurface(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(selected ? accent.opacity(0.16) : Color(UIColor.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? accent : Color.primary.opacity(0.08), lineWidth: selected ? 2 : 1)
            )
    }

    // MARK: Page two

    /// One tab, in the words that suit the answer.
    private struct TabIntro: Identifiable {
        let id: String
        let systemImage: String
        let tint: Color
        var secondaryTint: Color? = nil
        let title: String
        let text: String
    }

    private func intros(for background: UserBackground) -> [TabIntro] {
        let adhan = TabIntro(id: "adhan", systemImage: "safari.fill", tint: SettingsTint.prayer,
                             title: "Adhan", text: adhanText(background))
        let quran = TabIntro(id: "quran", systemImage: "character.book.closed.ar", tint: SettingsTint.quran,
                             title: "Quran", text: quranText(background))
        let hadith = TabIntro(id: "hadith", systemImage: "text.book.closed.fill", tint: SettingsTint.hadith,
                              title: "Hadith", text: hadithText(background))
        let islam = TabIntro(id: "islam", systemImage: "moon.stars.fill", tint: SettingsTint.islam,
                             secondaryTint: SettingsTint.islamSecondary,
                             title: "Islam", text: islamText(background))
        // Someone here to learn meets the two learning tabs first; everyone else, the tab bar's order.
        return background == .raised ? [adhan, quran, hadith, islam] : [islam, quran, adhan, hadith]
    }

    private func islamText(_ background: UserBackground) -> String {
        switch background {
        case .raised:
            return "Duas and dhikr, a tasbih, the 99 Names, zakah and inheritance calculators, a tajweed course, and a journal."
        case .revert, .beginner:
            return "Begin with Start Here, at the top of the Islam tab: the pillars, wudu and the prayer step by step, the Arabic letters, and the duas of every day."
        case .exploring:
            return "Begin with Start Here, at the top of the Islam tab: what Muslims believe, in plain English, with the sources for every claim."
        }
    }

    private func quranText(_ background: UserBackground) -> String {
        switch background {
        case .raised:
            return "Tajweed colors you can change, the riwayat side by side, tafsir, and a word's meaning and root with two taps."
        case .revert, .beginner:
            return "Read with a translation and a transliteration, tap a word twice for its meaning, and listen ayah by ayah."
        case .exploring:
            return "Every ayah with its English translation, tafsir to explain it, and About this Surah for each surah's background."
        }
    }

    private func adhanText(_ background: UserBackground) -> String {
        switch background {
        case .raised:
            return "Prayer times, the qibla, and a tracker for the five. Nagging Mode asks \u{201C}Did you pray?\u{201D} until you answer."
        case .revert, .beginner:
            return "The five prayer times for where you are, the direction of the qibla, and a tracker to build the habit a day at a time."
        case .exploring:
            return "The five daily prayer times for where you are: the rhythm of a Muslim's day. Their notifications can be switched off below."
        }
    }

    private func hadithText(_ background: UserBackground) -> String {
        switch background {
        case .raised:
            return "Seventeen collections with their grades, searched by reference, by word, or by meaning."
        case .revert, .beginner, .exploring:
            return "What the Prophet, peace be upon him, said and did: seventeen collections, searchable in plain English."
        }
    }

    private var tailoredPage: some View {
        let background = choice ?? .raised
        return VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text(background == .exploring ? "Welcome" : "Ahlan wa sahlan")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Four tabs, and where you might begin.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                ForEach(intros(for: background)) { intro in
                    HStack(alignment: .top, spacing: 14) {
                        AccentIconChip(systemImage: intro.systemImage, tint: intro.tint,
                                       secondaryTint: intro.secondaryTint, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(intro.title)
                                .font(.headline)

                            Text(intro.text)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardSurface(selected: false))
                }
            }

            if background != .raised {
                suggestions(for: background)
            }

            Text("Every settings page opens with Tips & Tricks, a list of what is easy to miss, and a short tour.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func suggestions(for background: UserBackground) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WORTH TURNING ON")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            suggestionToggle("Transliteration under the Arabic",
                             "The Quran in Latin letters beneath each ayah, for reading along before you know the script.",
                             isOn: $transliteration)

            suggestionToggle("What each prayer's name means",
                             "Notifications that read \u{201C}Time for Maghrib (sunset)\u{201D}.",
                             isOn: $englishMeanings)

            if background == .exploring {
                suggestionToggle("Prayer-time notifications",
                                 "Off if you are only here to read. You can bring them back in Settings.",
                                 isOn: $prayerNotifications)
            }

            // No "Open the app on the Islam tab" switch here any more (Abu, 2026-09-25): which tab
            // the app opens on is chosen in one place only, Appearance > Look and Feel. Finishing the
            // welcome as a learner still lands on the Islam tab this once (`finish`).
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardSurface(selected: false))
    }

    private func suggestionToggle(_ title: String, _ detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn.animation(.easeInOut)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))

                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(accent)
        .onChange(of: isOn.wrappedValue) { _ in settings.hapticFeedback() }
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                settings.hapticFeedback()
                if page == 0 {
                    seedSuggestions()
                    withAnimation(.easeInOut(duration: 0.3)) { page = 1 }
                } else {
                    finish(saving: true)
                }
            } label: {
                Text(primaryTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .conditionalGlassEffect(rectangle: true, useColor: 0.38, customTint: AppIdentifiers.mainColor.color)
            .disabled(choice == nil)
            .opacity(choice == nil ? 0.5 : 1)

            Button {
                settings.hapticFeedback()
                if page == 0 {
                    finish(saving: false)
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) { page = 0 }
                }
            } label: {
                Text(page == 0 ? "Not Now" : "Back")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var primaryTitle: String {
        guard page == 1 else { return "Continue" }
        if presentedAsSheet { return "Done" }
        return choice?.landsOnIslamTab == true ? "Start Learning" : "Get Started"
    }

    /// The suggestions open on the reader's OWN settings. A new install has none worth keeping, so
    /// for it (and only it) the two reading aids start switched on.
    private func seedSuggestions() {
        guard !didSeedSuggestions else { return }
        didSeedSuggestions = true
        transliteration = settings.showTransliteration || isNewInstall
        englishMeanings = settings.prayerNotificationEnglishNames || isNewInstall
        prayerNotifications = settings.notificationFajr || settings.notificationDhuhr || settings.notificationAsr
            || settings.notificationMaghrib || settings.notificationIsha
    }

    private func finish(saving: Bool) {
        if saving, let choice {
            settings.userBackground = choice
            if choice.wantsStartHere { settings.startHereHidden = false }

            if choice != .raised {
                if transliteration != settings.showTransliteration { settings.showTransliteration = transliteration }
                if englishMeanings != settings.prayerNotificationEnglishNames { settings.prayerNotificationEnglishNames = englishMeanings }
            }
            if choice == .exploring, !prayerNotifications {
                settings.notificationFajr = false
                settings.notificationSunrise = false
                settings.notificationDhuhr = false
                settings.notificationAsr = false
                settings.notificationMaghrib = false
                settings.notificationIsha = false
            }
        }

        if presentedAsSheet {
            dismiss()
            return
        }
        // Ends the root stage: `RootAppearance` sees the version and the cover fades away.
        withAnimation {
            settings.aboutYouVersionSeen = Settings.aboutYouCurrentVersion
        }
        if saving, choice?.landsOnIslamTab == true {
            AppNavigation.shared.openIslam(.tab)
        }
    }

    // MARK: Backdrop

    /// The splash's whisper of the accent at the top, over an opaque ground: this is a cover, and
    /// the tabs are mounted beneath it.
    private var backdrop: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground)

            RadialGradient(
                colors: [accent.opacity(isDarkMode ? 0.22 : 0.14), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 380
            )
            .frame(height: 420)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// "-aboutYouPick <raw>" preselects an answer and "-aboutYouPage 2" lands on the second page
    /// (DEBUG; screenshots without a tap).
    private func applyDebugArguments() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-aboutYouPick"), arguments.indices.contains(index + 1),
           let picked = UserBackground(rawValue: arguments[index + 1]) {
            choice = picked
        }
        if let index = arguments.firstIndex(of: "-aboutYouPage"), arguments.indices.contains(index + 1),
           arguments[index + 1] == "2", choice != nil {
            seedSuggestions()
            page = 1
        }
        #endif
    }
}

// MARK: - Settings: About You

/// The answer, changeable: a row of the Settings tab, under Your Progress.
struct AboutYouSettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var showWelcome = false

    var body: some View {
        List {
            Group {
                Section(header: Text("WHICH DESCRIBES YOU BEST"),
                        footer: Text("This stays on your device. It decides only what \(AppIdentifiers.appName) suggests, such as the Start Here guide on the Islam tab. Nothing in the app is locked or hidden by it.")) {
                    ForEach(UserBackground.allCases) { option in
                        choiceRow(title: option.title, subtitle: option.subtitle, systemImage: option.systemImage,
                                  selected: settings.userBackground == option) {
                            settings.userBackground = option
                            if option.wantsStartHere { settings.startHereHidden = false }
                        }
                    }

                    choiceRow(title: "Prefer not to say", subtitle: "No suggestions are tailored.", systemImage: "hand.raised.fill",
                              selected: settings.userBackground == nil) {
                        settings.userBackground = nil
                    }
                }

                if settings.userBackground?.wantsStartHere == true {
                    Section {
                        VStack(alignment: .leading) {
                            // Was "Start Here on the Islam Tab", which reads as "start the app on
                            // the Islam tab" (Abu read it that way himself, 2026-09-21). It shows a
                            // guide; the opening tab is Appearance > Look and Feel's picker, which
                            // is its only home now (Abu, 2026-09-25: "remove open the app on in
                            // about you, only keep that for the looks one").
                            Toggle("Show the Start Here Guide", isOn: Binding(
                                get: { !settings.startHereHidden },
                                set: { newValue in withAnimation(.easeInOut) { settings.startHereHidden = !newValue } }
                            ))
                            .font(.subheadline)
                            .tint(settings.accentColor.color)
                            .onChange(of: settings.startHereHidden) { _ in settings.hapticFeedback() }

                            Text("A short guided path shown at the top of the Islam tab. It ticks off each step as you open it. This does not change which tab the app opens on.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 2)
                        }
                    }
                }

                Section {
                    Button {
                        settings.hapticFeedback()
                        showWelcome = true
                    } label: {
                        Label("Replay the Welcome Tutorial", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                    }
                    .tint(settings.accentColor.color)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("About You")
        .sheet(isPresented: $showWelcome) {
            NavigationView {
                AboutYouView(presentedAsSheet: true)
                    .navigationBarTitleDisplayMode(.inline)
                    .sheetDismissToolbar()
            }
            .navigationViewStyle(.stack)
        }
    }

    private func choiceRow(title: String, subtitle: String, systemImage: String, selected: Bool,
                           select: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { select() }
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: systemImage)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if selected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The Settings tab's row for it, under Your Progress. Islam Settings carries the same row in its
/// own two colors (Abu, 2026-09-20: "allow me to change my tutorial somewhere in settings"; the
/// guide it switches on lives on the Islam tab, so that is where he looked). One screen, two doors.
struct AboutYouSettingsRow: View {
    @ObservedObject private var settings = Settings.shared

    var tint: Color? = nil
    var secondaryTint: Color? = nil

    var body: some View {
        NavigationLink(destination: LazyDestination { AboutYouSettingsView() }) {
            SettingsRowLabel(title: "About You", systemImage: "person.crop.circle.fill",
                             // Short on purpose: this column outranks the value, and a longer caption squeezed the
                             // answer beside it ("Just getting started") down to a single dot.
                             subtitle: "Start Here, welcome tutorial",
                             tint: tint, secondaryTint: secondaryTint,
                             value: settings.userBackground?.title)
        }
        .tint(settings.accentColor.color)
    }
}

extension SettingsSearchEntry {
    static let aboutYouEntries: [SettingsSearchEntry] = [
        .init(title: "About You", path: "Settings", keywords: "born raised muslim revert convert new beginner non muslim learning welcome onboarding tutorial intro change answer start here guide who are you background", destination: .aboutYou),
        .init(title: "Replay the Welcome Tutorial", path: "Settings → About You", keywords: "tutorial onboarding welcome replay again redo intro walkthrough", destination: .aboutYou),
        .init(title: "Show the Start Here Guide", path: "Settings → About You", keywords: "start here guide beginner path steps islam tab hide show learn", destination: .aboutYou),
    ]
}
#endif
