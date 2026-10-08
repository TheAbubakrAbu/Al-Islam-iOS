import SwiftUI

// [Al-Adhan] Nagging mode's own screen. It began as one section of Prayer Notifications, three pushes
// deep (Settings, Notifications, Prayer Notifications), with a single choice to make: when to start.
// Abu, 2026-09-20: "make nagging mode more customizable and have more options", and make the app's
// unusual settings "easy to find and front and center". So it is a screen now, reached from the
// Notifications root, from Prayer Notifications, from the Settings tab's featured cards and from
// search, and every part of the cascade is a choice: the lead, the spacing, the last calls, a lead
// per prayer, a check-in after the adhan, the tone, a louder last call, a verse, and a pause.
//
// The scheduler that reads all of it is `Settings.naggingCascade(forCascadeBefore:)` and its
// neighbours in SettingsAdhan.swift. Every summary line on this screen is built by the SAME static
// function the scheduler calls, so the screen cannot describe a schedule the app will not build.
//
// Compiles for the watch too (its Notifications page links here), hence no iOS-only picker styles.
//
// Simple by default (Abu, 2026-09-22: "make nagging mode much simpler, only have an option to make
// it more customizable"): the switch, the pause, one start time, which prayers, and the things to
// know. Everything else (the spacing, the last calls, a lead per prayer, the check-in, the tones,
// the verse) shows only with Show Advanced Settings on, THIS screen's own switch at its foot (one
// per screen since 2026-09-22). The hidden options keep their values; the schedule line and the deadline
// captions are still built from whatever they hold, so the screen never describes a schedule the
// scheduler will not build.

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
    let caption: String
    let key: ReferenceWritableKeyPath<Settings, Bool>

    static let all: [NaggingDeadline] = [
        .init(id: "shurooq", asks: "Fajr",
              caption: "Before Shurooq, when Fajr's time ends.",
              key: \Settings.naggingSunrise),
        .init(id: "asr", asks: "Dhuhr",
              caption: "Before Asr, when Dhuhr's time ends.",
              key: \Settings.naggingAsr),
        .init(id: "maghrib", asks: "Asr",
              caption: "Before Maghrib, when Asr's time ends.",
              key: \Settings.naggingMaghrib),
        .init(id: "isha", asks: "Maghrib",
              caption: "Before Isha, when Maghrib's time ends.",
              key: \Settings.naggingIsha),
        .init(id: "midnight", asks: "Isha",
              caption: "Before Islamic Midnight, when Isha's preferred time ends.",
              key: \Settings.naggingIslamicMidnight),
        .init(id: "fajr", asks: "Isha",
              caption: "Before Fajr, the last call before the night ends.",
              key: \Settings.naggingFajr),
    ]
}

struct NaggingModeView: View {
    @ObservedObject private var settings = Settings.shared

    /// The row's trailing read-out wherever this screen is linked from: "Off", "On", or "Paused".
    static func statusValue(_ settings: Settings) -> String {
        guard settings.naggingMode else { return "Off" }
        return settings.naggingPauseEnd == nil ? "On" : "Paused"
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
        let minutes = cascade(forLead: lead).map(String.init)
        guard let last = minutes.last else { return "No reminders" }
        if minutes.count == 1 { return "\(last) minutes before" }
        return minutes.dropLast().joined(separator: ", ") + " and \(last) minutes before"
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
        case 60: return "1 hour"
        case 90: return "1.5 hours"
        case 120: return "2 hours"
        default: return "\(minutes) min"
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
                    scheduleSection
                    deadlinesSection
                    if settings.advanced(.naggingMode) {
                        followUpSection
                        soundSection
                        wordingSection
                    }
                }

                goodToKnowSection

                // Every advanced section here lives inside `if settings.naggingMode` above, so with
                // the mode off the switch would hide nothing at all.
                AdvancedSettingsSection(screen: .naggingMode,
                                        hides: "how often the reminders repeat, the last calls, a different start for each prayer, a check-in after the adhan, a tone of their own, a louder last call and a verse in it",
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

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 2)
    }

    // MARK: On / off

    private var masterSection: some View {
        Section {
            caption("For anyone who struggles to pray on time. As a prayer's time runs out, the app asks \u{201C}Did you pray it?\u{201D} and keeps asking until you answer or the time ends. Answer once and the rest of that prayer's reminders go quiet.")

            Toggle("Turn on Nagging Mode", isOn: Binding(
                get: { settings.naggingMode },
                set: { newValue in
                    withAnimation {
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
                }
            ).animation(.easeInOut))
            .font(.subheadline)
            .tint(settings.accentColor.color)
            .onChange(of: settings.naggingMode) { _ in settings.hapticFeedback() }

            if settings.naggingMode, settings.naggingPauseEnd == nil {
                pauseControl
            }
        }
    }

    // MARK: Pause

    private static let pauseChoices: [(hours: Int, title: String)] = [
        (24, "For a Day"), (72, "For 3 Days"), (168, "For a Week"),
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
                    Button(choice.title) {
                        settings.hapticFeedback()
                        withAnimation { settings.pauseNagging(forHours: choice.hours) }
                    }
                }
            } label: {
                HStack {
                    Text("Pause the Reminders")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "pause.circle")
                        .foregroundColor(settings.accentColor.color)
                }
                .contentShape(Rectangle())
            }

            caption("For a sick day or a long flight. Only the \u{201C}Did you pray?\u{201D} reminders are held; adhans and prayer-time notifications keep coming.")
        }
        #else
        ForEach(Self.pauseChoices, id: \.hours) { choice in
            Button("Pause \(choice.title)") {
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
                        .font(.subheadline)

                    caption("The \u{201C}Did you pray?\u{201D} reminders are held until then. Adhans and prayer-time notifications keep coming. For menstruation and postpartum, use Pause tracking in the Prayer Tracker's history instead: it also keeps those days out of your streak.")
                }
            }

            Button {
                settings.hapticFeedback()
                withAnimation { settings.resumeNagging() }
            } label: {
                Label("Resume Now", systemImage: "play.fill")
                    .font(.subheadline)
            }
            .tint(settings.accentColor.color)
        }
    }

    // MARK: Schedule

    /// Simple: one start time and the schedule it makes. Advanced adds the spacing, the last calls
    /// and a start per prayer. A per-prayer start set while advanced is on stays in force when it
    /// is turned off; the screen then says so instead of showing a Start picker nothing reads.
    private var scheduleSection: some View {
        Section(header: Text("SCHEDULE")) {
            if !settings.naggingPerDeadlineStart {
                Picker("Start", selection: $settings.naggingStartOffset) {
                    ForEach(Settings.naggingStartOptions, id: \.self) { minutes in
                        Text("\(Self.leadTitle(minutes)) before").tag(minutes)
                    }
                }
                .onChange(of: settings.naggingStartOffset) { _ in
                    settings.hapticFeedback()
                    fitIntervalToLeads()
                }
            } else if !settings.advanced(.naggingMode) {
                caption("Each prayer has its own start time, shown under Which Prayers. Change them with Show Advanced Settings on.")
            }

            if settings.advanced(.naggingMode) {
                Picker("Repeat Every", selection: $settings.naggingInterval) {
                    ForEach(intervalChoices, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .onChange(of: settings.naggingInterval) { _ in settings.hapticFeedback() }

                Picker("Last Calls", selection: $settings.naggingLastCallsRaw) {
                    ForEach(NaggingLastCalls.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .onChange(of: settings.naggingLastCallsRaw) { _ in settings.hapticFeedback() }
            }

            if !settings.naggingPerDeadlineStart {
                Label(scheduleLine(forLead: settings.naggingStartOffset), systemImage: "bell.badge")
                    .font(.footnote.weight(.medium))
                    .foregroundColor(settings.accentColor.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if settings.advanced(.naggingMode) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Different Start for Each Prayer", isOn: $settings.naggingPerDeadlineStart.animation(.easeInOut))
                        .font(.subheadline)
                        .tint(settings.accentColor.color)
                        .onChange(of: settings.naggingPerDeadlineStart) { _ in
                            settings.hapticFeedback()
                            fitIntervalToLeads()
                        }

                    caption("Fajr's window is short and Dhuhr's is long. Turn this on to give each prayer its own lead below, say 20 minutes before Shurooq and an hour before Maghrib.")
                }

                caption(budgetLine)
            }
        }
    }

    /// The honest cost of the schedule. iOS keeps 64 pending notifications per app, soonest first, so
    /// a heavy cascade does not break anything: it shortens how many DAYS ahead the adhans are queued,
    /// which only matters to someone who does not open the app.
    private var budgetLine: String {
        let count = remindersPerDay
        let base = "Up to \(count) reminder\(count == 1 ? "" : "s") on a day when nothing gets marked, and none for a prayer once you mark it."
        guard count > 24 else { return base }
        return base + " iOS lets an app queue 64 notifications at a time, so a schedule this busy covers fewer days ahead. Opening the app every day or two keeps it topped up. Longer leads offer wider spacing for the same reason."
    }

    // MARK: Deadlines

    private var deadlinesSection: some View {
        Section(header: Text("WHICH PRAYERS")) {
            // One row per DEADLINE, each saying which prayer it asks about (Abu, 2026-09-19).
            // The cascade before a time is about the obligatory prayer whose window that time
            // CLOSES. The scheduler (`Settings.prayerQuestion(for:)`) has always worked this way;
            // the old labels ("Nagging before Dhuhr") just never said so.
            ForEach(NaggingDeadline.all) { deadline in
                Toggle(isOn: Binding(
                    get: { settings[keyPath: deadline.key] },
                    set: { newValue in
                        settings[keyPath: deadline.key] = newValue
                        turnOffNaggingModeIfAllOff()
                        fitIntervalToLeads()
                    }
                ).animation(.easeInOut)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Did you pray \(deadline.asks)?")
                            .font(.subheadline)

                        Text(deadline.caption)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(settings.accentColor.color)
                .onChange(of: settings[keyPath: deadline.key]) { _ in settings.hapticFeedback() }

                if settings.naggingPerDeadlineStart, settings[keyPath: deadline.key], !settings.advanced(.naggingMode) {
                    // The lead this deadline keeps while the picker that set it is out of sight.
                    Text(scheduleLine(forLead: settings.naggingStart(forDeadline: deadline.id)))
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .settingsDependent()
                }

                if settings.naggingPerDeadlineStart, settings[keyPath: deadline.key], settings.advanced(.naggingMode) {
                    VStack(alignment: .leading, spacing: 2) {
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

                        Text(scheduleLine(forLead: settings.naggingStart(forDeadline: deadline.id)))
                            .font(.caption)
                            .foregroundColor(settings.accentColor.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .settingsDependent()
                }
            }

            caption("Isha has two rows because its end is read two ways: the middle of the night (Sahih Muslim 612) and Fajr. Keep either or both. The app never rules on it, and the reminder's own answers, on time or late, record which you hold.")
        }
    }

    // MARK: After the adhan

    private var followUpSection: some View {
        Section(header: Text("AFTER THE ADHAN")) {
            Picker("Check In", selection: $settings.naggingFollowUpMinutes) {
                ForEach(Settings.naggingFollowUpOptions, id: \.self) { minutes in
                    Text(minutes == 0 ? "Off" : "\(minutes) min after").tag(minutes)
                }
            }
            .onChange(of: settings.naggingFollowUpMinutes) { _ in settings.hapticFeedback() }

            caption("The reminders above only speak up when a prayer's time is nearly over. This adds one earlier nudge, \u{201C}Have you prayed Dhuhr yet?\u{201D}, this long after the adhan while the prayer is still unmarked, for praying at the start of the time instead of the end. It follows the prayers switched on above.")
        }
    }

    // MARK: Sound

    private var soundSection: some View {
        Section(header: Text("SOUND")) {
            Picker("Nag Tone", selection: $settings.naggingSound) {
                Text("Same as Alert Tone").tag("")
                ForEach(Settings.supportedAlertTones) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .onChange(of: settings.naggingSound) { _ in settings.hapticFeedback() }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Louder Last Call", isOn: $settings.naggingLoudLastCall.animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                    .onChange(of: settings.naggingLoudLastCall) { _ in settings.hapticFeedback() }

                caption("The final reminder before each deadline plays Alarm, the tone that carries furthest, whatever the others play. Give the nags a tone of their own and you can tell \u{201C}Did you pray?\u{201D} from \u{201C}15 minutes until Asr\u{201D} without looking.")
            }
        }
    }

    // MARK: Wording

    private var wordingSection: some View {
        Section(header: Text("WORDING")) {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Add a Verse to the Last Call", isOn: $settings.naggingAyahInLastCall.animation(.easeInOut))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)
                    .onChange(of: settings.naggingAyahInLastCall) { _ in settings.hapticFeedback() }

                caption("The final reminder carries a verse about the prayer, such as \u{201C}\(Settings.nagAyat[0].text)\u{201D} (\(Settings.nagAyat[0].reference)). Saheeh International, the translation the Quran tab uses.")
            }

            caption("Show English Meanings, in Prayer Notifications, also applies here: \u{201C}Did you pray Maghrib (sunset)?\u{201D}")
        }
    }

    // MARK: Good to know

    /// The parts of nagging mode that are not switches, and that nobody finds on their own.
    private var goodToKnowSection: some View {
        Section(header: Text("GOOD TO KNOW")) {
            knowRow("hand.tap.fill", "Answer without opening the app",
                    "Touch and hold a reminder on the Lock Screen for \u{201C}Yes, on time\u{201D} and \u{201C}Yes, but late\u{201D}. Either one marks the prayer tracker and cancels the rest of that prayer's reminders.")
            knowRow("checklist", "Marking the tracker counts as your answer",
                    "Mark a prayer on the Adhan tab, on time, late, or missed, and its reminders stop for the day. Clear the mark and they come back.")
            knowRow("questionmark.bubble.fill", "Tapping any prayer notification asks too",
                    "Open the app from an adhan, a prenotification, or a nag, and it asks \u{201C}Did you pray it?\u{201D} about the prayer that notification was for, even days later, unless you have already answered.")
            knowRow("moon.zzz.fill", "They reach you in a Focus if you let them",
                    "Prayer notifications are marked Time Sensitive. Allow Time Sensitive notifications for \(AppIdentifiers.appName) in your Focus and they come through Sleep and Do Not Disturb.")
        }
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
