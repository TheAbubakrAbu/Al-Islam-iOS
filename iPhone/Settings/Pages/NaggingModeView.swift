import SwiftUI

// [Al-Adhan] Nagging mode's own screen. It began as one section of Prayer Notifications, three pushes
// deep (Settings, Notifications, Prayer Notifications), with a single choice to make: when to start.
// Abu, 2026-09-20: "make nagging mode more customizable and have more options", and make the app's
// unusual settings "easy to find and front and center". So it is a screen now, reached from the
// Notifications root, from the Settings tab's featured cards and from search, and every part of the
// cascade is a choice: the lead, the spacing, the last calls, a lead per prayer, a check-in after
// the adhan, the tone, a louder last call, a verse, and a pause.
//
// The scheduler that reads all of it is `Settings.naggingCascade(forCascadeBefore:)` and its
// neighbours in SettingsAdhan.swift. Every summary line on this screen is built by the SAME static
// function the scheduler calls, so the screen cannot describe a schedule the app will not build.
//
// Compiles for the watch too (its Notifications page links here), hence no iOS-only picker styles.
//
// Simple by default (Abu, 2026-09-22: "make nagging mode much simpler, only have an option to make
// it more customizable"): the switch, the pause, one start time and which prayers. Everything else
// (the spacing, the last calls, a lead per prayer, the check-in, the tones, the verse) shows only
// with Show Advanced Settings on, THIS screen's own switch at its foot. The hidden options keep their
// values; the schedule line is still built from whatever they hold.
//
// Revamped 2026-10-19 (Abu: "too complicated and ugly"): one line of caption per control at most,
// the schedule line said ONCE instead of under every prayer, the per-prayer start as a plain picker
// with no repeated read-out, the fine-tuning in one section, and the four "good to know" cards
// behind a door, so the simple screen is the switch, the pause, a start time and six prayers.

/// One nagging row: the time whose arrival closes a prayer's window, and the prayer it therefore
/// asks about. This is the SAME mapping `Settings.prayerQuestion(for:)` computes at
/// delivery, kept here as a table so the label can never disagree with the question that
/// actually gets asked (Abu, 2026-09-19).
///
/// "Before Dhuhr" is deliberately absent: it used to ask "did you pray Fajr?" a second time,
/// hours after Fajr's window had already closed at sunrise. Sunrise is the real Fajr deadline,
/// so that row was nagging about something the person could no longer put right. Anyone who had
/// it on is migrated onto the Shurooq row (`Settings.migrateNaggingDhuhrIfNeeded`).
///
/// Islamic Midnight IS here even though it is an optional TIME rather than a prayer: the
/// preferred window for Isha ends at the middle of the night ("When you pray 'Isha, its time is
/// until half of the night has passed", Sahih Muslim 612), so it is a real deadline. Duhaa and
/// Last Third are not: they are nafl, nothing is owed, and the tracker records only the five.
struct NaggingDeadline: Identifiable {
    /// Also the key of this deadline's own lead time (`Settings.nagDeadlineID(forCascadeBefore:)`).
    let id: String
    /// The obligatory prayer the notification asks about.
    let asks: String
    /// The time the reminders run up to, as the row's one-line caption.
    let caption: String
    let key: ReferenceWritableKeyPath<Settings, Bool>

    static let all: [NaggingDeadline] = [
        .init(id: "shurooq", asks: "Fajr", caption: String(localized: "Before Shurooq"), key: \Settings.naggingSunrise),
        .init(id: "asr", asks: "Dhuhr", caption: String(localized: "Before Asr"), key: \Settings.naggingAsr),
        .init(id: "maghrib", asks: "Asr", caption: String(localized: "Before Maghrib"), key: \Settings.naggingMaghrib),
        .init(id: "isha", asks: "Maghrib", caption: String(localized: "Before Isha"), key: \Settings.naggingIsha),
        .init(id: "midnight", asks: "Isha", caption: String(localized: "Before Islamic Midnight"), key: \Settings.naggingIslamicMidnight),
        .init(id: "fajr", asks: "Isha", caption: String(localized: "Before Fajr, the last call"), key: \Settings.naggingFajr),
    ]
}

struct NaggingModeView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// The row's trailing read-out wherever this screen is linked from: "Off", "On", or "Paused".
    static func statusValue(_ settings: Settings) -> String {
        guard settings.naggingMode else { return String(localized: "Off") }
        return settings.naggingPauseEnd == nil ? String(localized: "On") : String(localized: "Paused")
    }

    // MARK: What the choices amount to

    private var enabledDeadlines: [NaggingDeadline] {
        NaggingDeadline.all.filter { settings[keyPath: $0.key] }
    }

    /// The longest lead any switched-on deadline uses: what the interval choices have to fit.
    private var longestLead: Int {
        guard settings.naggingPerDeadlineStart else { return settings.naggingStartOffset }
        return enabledDeadlines.map { settings.naggingStart(forDeadline: $0.id) }.max() ?? settings.naggingStartOffset
    }

    private var intervalChoices: [Int] {
        Settings.naggingIntervalChoices(forStart: longestLead)
    }

    private func cascade(forLead lead: Int) -> [Int] {
        Settings.naggingCascade(start: lead, interval: settings.naggingInterval, lastCalls: settings.naggingLastCalls)
            .sorted(by: >)
    }

    /// "30, 15, 10 and 5 minutes before", from the scheduler's own arithmetic.
    private func scheduleLine(forLead lead: Int) -> String {
        let minutes = cascade(forLead: lead).map { $0.formatted() }
        guard let last = minutes.last else { return String(localized: "No reminders") }
        if minutes.count == 1 { return String(localized: "\(last) minutes before") }
        // The list, then the one "minutes before" phrase: English reads as it always did, Arabic joins
        // the numbers in its own list format.
        let list = minutes.sentenceList { String(localized: "\($0.dropLast().joined(separator: ", ")) and \($0.last!)") }
        return String(localized: "\(list) minutes before")
    }

    /// Reminders in a day on which nothing gets marked: the most this schedule can ever send.
    private var remindersPerDay: Int {
        let cascades = enabledDeadlines.reduce(0) { $0 + cascade(forLead: settings.naggingStart(forDeadline: $1.id)).count }
        guard settings.naggingFollowUpMinutes > 0 else { return cascades }
        // One check-in per obligatory prayer that a switched-on deadline asks about.
        let askedPrayers = Set(enabledDeadlines.map(\.asks))
        return cascades + askedPrayers.count
    }

    private static func leadTitle(_ minutes: Int) -> String {
        switch minutes {
        case 60: return String(localized: "1 hour")
        case 90: return String(localized: "1.5 hours")
        case 120: return String(localized: "2 hours")
        default: return String(localized: "\(minutes) min")
        }
    }

    /// Keeps the spacing inside what the chosen leads allow. Called whenever a lead changes, so the
    /// picker never shows a value the scheduler would quietly widen.
    private func fitIntervalToLeads() {
        let choices = intervalChoices
        guard !choices.contains(settings.naggingInterval) else { return }
        settings.naggingInterval = choices.first { $0 >= settings.naggingInterval } ?? choices.last ?? 15
    }

    private func turnOffNaggingModeIfAllOff() {
        if NaggingDeadline.all.allSatisfy({ !settings[keyPath: $0.key] }) {
            withAnimation {
                settings.naggingMode = false
            }
        }
    }

    // MARK: Body

    var body: some View {
        List {
            Group {
                masterSection

                if settings.naggingMode {
                    if settings.naggingPauseEnd != nil { pausedSection }
                    whenSection
                    deadlinesSection
                    if settings.advanced(.naggingMode) {
                        fineTuneSection
                    }
                }

                howItWorksSection

                // Every advanced section here lives inside `if settings.naggingMode` above, so with
                // the mode off the switch would hide nothing at all.
                AdvancedSettingsSection(screen: .naggingMode,
                                        hides: String(localized: "how often the reminders repeat, the last calls, a start for each prayer, a check-in after the adhan, the tone and the verse"),
                                        applies: settings.naggingMode)
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Nagging Mode")
        .onDisappear {
            settings.fetchPrayerTimes(notification: true)
        }
    }

    // MARK: On / off

    private var masterSection: some View {
        Section(header: Text("NAGGING MODE")) {
            SettingsToggle(String(localized: "Nagging Mode"),
                           caption: String(localized: "Asks \u{201C}Did you pray?\u{201D} as a prayer's time runs out, and keeps asking until you answer."),
                           isOn: Binding(
                get: { settings.naggingMode },
                set: { newValue in
                    settings.naggingMode = newValue

                    if newValue {
                        settings.notificationFajr = true
                        settings.notificationSunrise = true
                        settings.notificationDhuhr = true
                        settings.notificationAsr = true
                        settings.notificationMaghrib = true
                        settings.notificationIsha = true

                        for deadline in NaggingDeadline.all {
                            settings[keyPath: deadline.key] = true
                        }
                    } else {
                        for deadline in NaggingDeadline.all {
                            settings[keyPath: deadline.key] = false
                        }
                        // The retired "before Dhuhr" cascade, in case an old install still
                        // has it set; otherwise it would keep firing with the mode "off".
                        settings.naggingDhuhr = false
                        settings.resumeNagging()
                    }
                }
            ))

            if settings.naggingMode, settings.naggingPauseEnd == nil {
                pauseControl
            }
        }
    }

    // MARK: Pause

    private static let pauseChoices: [(hours: Int, title: String)] = [
        (24, String(localized: "For a Day")), (72, String(localized: "For 3 Days")), (168, String(localized: "For a Week")),
    ]

    /// One row under the switch, not a section of its own: the control someone reaches for on a sick
    /// day or a long flight should be near the top, and it should not push the schedule off the
    /// screen to be there. The watch has no `Menu`, so it lists the choices as plain rows.
    @ViewBuilder
    private var pauseControl: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 4) {
            Menu {
                ForEach(Self.pauseChoices, id: \.hours) { choice in
                    Button(choice.title.localizedDigits) {
                        settings.hapticFeedback()
                        withAnimation { settings.pauseNagging(forHours: choice.hours) }
                    }
                }
            } label: {
                HStack {
                    Text("Pause the Reminders")
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "pause.circle")
                        .foregroundColor(settings.accentColor.color)
                }
                .contentShape(Rectangle())
            }

            SettingsCaption(String(localized: "For a sick day or a flight. Adhans and prayer-time notifications keep coming."))
                .padding(.vertical, 2)
        }
        #else
        ForEach(Self.pauseChoices, id: \.hours) { choice in
            Button(String(localized: "Pause \(choice.title)").localizedDigits) {
                settings.hapticFeedback()
                withAnimation { settings.pauseNagging(forHours: choice.hours) }
            }
            .font(.subheadline)
        }
        #endif
    }

    /// Shown only while a pause is running, directly under the switch, so "why is it quiet?" is
    /// answered before anything else on the screen.
    private var pausedSection: some View {
        Section(header: Text("PAUSED")) {
            if let end = settings.naggingPauseEnd {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Until \(end.formatted(date: .abbreviated, time: .shortened))")

                    SettingsCaption(String(localized: "Only the \u{201C}Did you pray?\u{201D} reminders are held. For menstruation or postpartum, pause tracking in the Prayer Tracker instead."))
                        .padding(.vertical, 2)
                }
            }

            Button {
                settings.hapticFeedback()
                withAnimation { settings.resumeNagging() }
            } label: {
                Label("Resume Now", systemImage: "play.fill")
            }
            .tint(settings.accentColor.color)
        }
    }

    // MARK: When

    /// Simple: one start time and the schedule it makes, said once. Advanced adds the spacing, the
    /// last calls and a start per prayer. A per-prayer start set while advanced is on stays in force
    /// when it is turned off; the screen then says so instead of showing a Start picker nothing reads.
    private var whenSection: some View {
        Section(header: Text("WHEN")) {
            if !settings.naggingPerDeadlineStart {
                Picker("Start", selection: $adhanSettings.naggingStartOffset) {
                    ForEach(Settings.naggingStartOptions, id: \.self) { minutes in
                        Text("\(Self.leadTitle(minutes)) before").tag(minutes)
                    }
                }
                .onChange(of: settings.naggingStartOffset) { _ in
                    settings.hapticFeedback()
                    fitIntervalToLeads()
                }

                Label(scheduleLine(forLead: settings.naggingStartOffset), systemImage: "bell.badge")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(settings.accentColor.color)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !settings.advanced(.naggingMode) {
                SettingsCaption(String(localized: "Each prayer has its own start time, under Which Prayers."))
                    .padding(.vertical, 2)
            }

            if settings.advanced(.naggingMode) {
                Picker("Repeat Every", selection: $adhanSettings.naggingInterval) {
                    ForEach(intervalChoices, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .onChange(of: settings.naggingInterval) { _ in settings.hapticFeedback() }

                Picker("Last Calls", selection: $adhanSettings.naggingLastCallsRaw) {
                    ForEach(NaggingLastCalls.allCases) { option in
                        Text(option.title.localizedDigits).tag(option.rawValue)
                    }
                }
                .onChange(of: settings.naggingLastCallsRaw) { _ in settings.hapticFeedback() }

                SettingsToggle(String(localized: "Different Start for Each Prayer"), caption: String(localized: "A short lead before Shurooq, a long one before Maghrib: set each under Which Prayers."), isOn: $adhanSettings.naggingPerDeadlineStart)
                    .onChange(of: settings.naggingPerDeadlineStart) { _ in fitIntervalToLeads() }

                SettingsCaption(budgetLine)
                    .padding(.vertical, 2)
            }
        }
    }

    /// The honest cost of the schedule. iOS keeps 64 pending notifications per app, soonest first, so
    /// a heavy cascade does not break anything: it shortens how many DAYS ahead the adhans are queued,
    /// which only matters to someone who does not open the app.
    private var budgetLine: String {
        let count = remindersPerDay
        let base = count == 1 ? String(localized: "Up to 1 reminder a day, none for a prayer once you mark it.") : String(localized: "Up to \(count) reminders a day, none for a prayer once you mark it.")
        guard count > 24 else { return base }
        return String(localized: "\(base) iOS queues 64 notifications at a time, so a schedule this busy covers fewer days ahead; opening the app every day or two keeps it topped up.")
    }

    // MARK: Which prayers

    private var deadlinesSection: some View {
        Section(header: Text("WHICH PRAYERS"),
                footer: Text("Isha has two rows because its end is read two ways, the middle of the night or Fajr. Keep either or both.")) {
            // One row per DEADLINE, each saying which prayer it asks about (Abu, 2026-09-19).
            // The cascade before a time is about the obligatory prayer whose window that time
            // CLOSES. The scheduler (`Settings.prayerQuestion(for:)`) has always worked this way;
            // the old labels ("Nagging before Dhuhr") just never said so.
            ForEach(NaggingDeadline.all) { deadline in
                SettingsToggle(String(localized: "Did you pray \(deadline.asks.localizedDisplay)?"), caption: deadline.caption, isOn: Binding(
                    get: { settings[keyPath: deadline.key] },
                    set: { newValue in
                        settings[keyPath: deadline.key] = newValue
                        turnOffNaggingModeIfAllOff()
                        fitIntervalToLeads()
                    }
                ))

                if settings.naggingPerDeadlineStart, settings[keyPath: deadline.key] {
                    if settings.advanced(.naggingMode) {
                        Picker("Start", selection: Binding(
                            get: { settings.naggingStart(forDeadline: deadline.id) },
                            set: { newValue in
                                settings.setNaggingStart(newValue, forDeadline: deadline.id)
                                settings.hapticFeedback()
                                fitIntervalToLeads()
                            }
                        )) {
                            ForEach(Settings.naggingStartOptions, id: \.self) { minutes in
                                Text("\(Self.leadTitle(minutes)) before").tag(minutes)
                            }
                        }
                        .settingsDependent()
                    } else {
                        // The lead this deadline keeps while the picker that set it is out of sight.
                        Text("Starts \(Self.leadTitle(settings.naggingStart(forDeadline: deadline.id))) before")
                            .font(.caption)
                            .foregroundColor(settings.accentColor.color)
                            .settingsDependent()
                    }
                }
            }
        }
    }

    // MARK: Fine-tune

    /// The spacing's neighbours: the check-in after the adhan, the tone, the louder last call and the
    /// verse. One section, one line each.
    private var fineTuneSection: some View {
        Section(header: Text("FINE-TUNE")) {
            VStack(alignment: .leading, spacing: 4) {
                Picker("Check In After the Adhan", selection: $adhanSettings.naggingFollowUpMinutes) {
                    ForEach(Settings.naggingFollowUpOptions, id: \.self) { minutes in
                        Text(minutes == 0 ? String(localized: "Off") : String(localized: "\(minutes) min after")).tag(minutes)
                    }
                }
                .onChange(of: settings.naggingFollowUpMinutes) { _ in settings.hapticFeedback() }

                SettingsCaption(String(localized: "One early nudge, \u{201C}Have you prayed Dhuhr yet?\u{201D}, this long after the adhan while the prayer is unmarked."))
                    .padding(.vertical, 2)
            }

            Picker("Nag Tone", selection: $adhanSettings.naggingSound) {
                Text("Same as Alert Tone").tag("")
                ForEach(Settings.supportedAlertTones) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .onChange(of: settings.naggingSound) { _ in settings.hapticFeedback() }

            SettingsToggle(String(localized: "Louder Last Call"), caption: String(localized: "The final reminder before each deadline plays Alarm, the tone that carries furthest."), isOn: $adhanSettings.naggingLoudLastCall)

            SettingsToggle(String(localized: "Add a Verse to the Last Call"), caption: String(localized: "A verse about prayer, such as \(nagAyahCitation), in Saheeh International."), isOn: $adhanSettings.naggingAyahInLastCall)
        }
    }

    /// The caption's example verse: the stored "Quran 4:103" is data, written here the way the interface
    /// writes a Quran citation, in its own digits.
    private var nagAyahCitation: String {
        let verse = Settings.nagAyat[0].reference.replacingOccurrences(of: "Quran ", with: "").localizedDigits
        return String(localized: "Quran \(verse)")
    }

    // MARK: How it works

    /// The parts of nagging mode that are not switches, behind one door so the screen stays short.
    private var howItWorksSection: some View {
        Section(header: Text("ABOUT")) {
            NavigationLink(destination: LazyDestination { NaggingHowItWorksView() }) {
                SettingsRowLabel(title: String(localized: "How Nagging Works"), systemImage: "questionmark.circle.fill",
                                 subtitle: String(localized: "Lock Screen answers, the tracker, a Focus"),
                                 tint: SettingsTint.notifications)
            }
            .tint(settings.accentColor.color)
        }
    }
}

/// The four things about nagging mode that are not switches, and that nobody finds on their own.
/// They sat at the foot of the Nagging Mode screen until 2026-10-19, a screen-height of cards under
/// the controls; a door keeps them one tap away without the length.
struct NaggingHowItWorksView: View {
    var body: some View {
        List {
            Group {
                Section(header: Text("GOOD TO KNOW")) {
                    knowRow("hand.tap.fill", String(localized: "Answer without opening the app"),
                            String(localized: "Touch and hold a reminder on the Lock Screen for \u{201C}Yes, on time\u{201D} and \u{201C}Yes, but late\u{201D}. Either one marks the prayer tracker and cancels the rest of that prayer's reminders."))
                    knowRow("checklist", String(localized: "Marking the tracker counts as your answer"),
                            String(localized: "Mark a prayer on the Adhan tab, on time, late, or missed, and its reminders stop for the day. Clear the mark and they come back."))
                    knowRow("questionmark.bubble.fill", String(localized: "Tapping any prayer notification asks too"),
                            String(localized: "Open the app from an adhan, a prenotification, or a nag, and it asks \u{201C}Did you pray it?\u{201D} about the prayer that notification was for, even days later, unless you have already answered."))
                    knowRow("moon.zzz.fill", String(localized: "They reach you in a Focus if you let them"),
                            String(localized: "Prayer notifications are marked Time Sensitive. Allow Time Sensitive notifications for \(AppIdentifiers.displayName) in your Focus and they come through Sleep and Do Not Disturb."))
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How Nagging Works")
    }

    private func knowRow(_ systemImage: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: SettingsTint.notifications)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        NaggingModeView()
    }
}
