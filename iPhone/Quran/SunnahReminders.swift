import SwiftUI
@preconcurrency import UserNotifications

// MARK: - Where a reminder opens

/// Where a tap on a reminder (or its "Open" row) lands in the Quran tab. Encoded into the
/// notification's userInfo as "open", "surah:67" or "ayah:2:285".
enum QuranOpenTarget: Equatable {
    case tab
    case surah(Int)
    case ayah(Int, Int)

    var encoded: String {
        switch self {
        case .tab: return "open"
        case .surah(let surah): return "surah:\(surah)"
        case .ayah(let surah, let ayah): return "ayah:\(surah):\(ayah)"
        }
    }

    init?(encoded: String) {
        let parts = encoded.split(separator: ":").map(String.init)
        switch parts.first {
        case "open": self = .tab
        case "surah" where parts.count == 2:
            guard let surah = Int(parts[1]) else { return nil }
            self = .surah(surah)
        case "ayah" where parts.count == 3:
            guard let surah = Int(parts[1]), let ayah = Int(parts[2]) else { return nil }
            self = .ayah(surah, ayah)
        default: return nil
        }
    }
}

/// Where a Reminder of the Day card opens on the Islam (or Hadith) tab.
enum IslamOpenTarget: Equatable {
    case hadithTab
    /// The Islam tab itself, nothing pushed: where About You lands someone who is there to learn,
    /// on the Start Here guide.
    case tab
    case duas
    case adhkar
    case names(Int?)
}

/// Cross-tab navigation requests. A notification tap arrives in the AppDelegate with no view in
/// hand; it drops the target here, the tab view switches to the Quran tab on the publish, and the
/// Quran tab opens the reader (see `QuranView.openPendingQuranTarget`). `@Published` replays its
/// value to a late subscriber, so a cold launch from a notification still lands.
@MainActor
final class AppNavigation: ObservableObject {
    static let shared = AppNavigation()
    private init() {}

    @Published var pendingQuran: QuranOpenTarget?

    /// The Islam tab's pending destination: MainTabView switches tabs, IslamView pushes and clears it.
    @Published var pendingIslam: IslamOpenTarget?

    func openIslam(_ target: IslamOpenTarget) {
        pendingIslam = target
    }

    func open(_ target: QuranOpenTarget) {
        pendingQuran = target
    }
}

#if os(iOS)
// MARK: - The presets

/// A recitation the Prophet ﷺ kept, as a scheduled reminder. Every preset cites a hadith graded
/// sahih or hasan (the app's content standard); the citation opens the hadith itself when the book
/// is one of the nine bundled ones. Ported from Tilawa's reminder presets (Jamil Hammoudeh, with
/// permission), re-cited against this app's hadith packs.
struct SunnahReminderPreset: Identifiable {
    struct HadithLink: Identifiable {
        let slug: String
        /// The standard (sunnah.com) number, resolved through `HadithBookData.hadith(referenced:suffix:)`.
        let number: Int
        var suffix: String? = nil
        var id: String { "\(slug):\(number)\(suffix ?? "")" }
    }

    let id: String
    let title: String
    let subtitle: String
    /// The vocalized Arabic name, shown beside the title on the lock screen.
    let arabicTitle: String?
    let transliteration: String?
    /// The notification's body.
    let body: String
    /// "Tirmidhi 2891" and what its grader said.
    let source: String
    let grading: String
    let link: HadithLink?
    /// Default time as minutes past midnight, and the day for a weekly one (Calendar's weekday,
    /// 1 = Sunday ... 7 = Saturday); nil = every day.
    let defaultMinutes: Int
    let defaultWeekday: Int?
    let target: QuranOpenTarget
    let symbol: String

    var isWeekly: Bool { defaultWeekday != nil }

    var openLabel: String {
        switch target {
        case .tab: return "Open the Quran"
        case .surah, .ayah: return "Open in Quran"
        }
    }

    static let all: [SunnahReminderPreset] = [
        SunnahReminderPreset(
            id: "wird",
            title: "Daily Wird",
            subtitle: "Your daily portion of the Quran",
            arabicTitle: "الوِردُ اليَومِيّ",
            transliteration: nil,
            body: "Time for your daily portion of the Quran.",
            source: "The practice of the Prophet ﷺ and his Companions",
            grading: "Established practice",
            link: nil,
            defaultMinutes: 6 * 60, defaultWeekday: nil,
            target: .tab,
            symbol: "book.closed"
        ),
        SunnahReminderPreset(
            id: "mulk",
            title: "Surat al-Mulk",
            subtitle: "Each night before sleep",
            arabicTitle: "سُورَةُ المُلك",
            transliteration: "Sūrat al-Mulk",
            body: "Thirty ayahs that intercede for their reader until he is forgiven: Tabarak alladhi biyadihil-mulk.",
            source: "Tirmidhi 2891",
            grading: "Hasan (al-Albani)",
            link: HadithLink(slug: "tirmidhi", number: 2891),
            defaultMinutes: 21 * 60 + 30, defaultWeekday: nil,
            target: .surah(67),
            symbol: "moon.stars"
        ),
        SunnahReminderPreset(
            id: "kahf",
            title: "Surat al-Kahf",
            subtitle: "Every Friday",
            arabicTitle: "سُورَةُ الكَهف",
            transliteration: "Sūrat al-Kahf",
            body: "It is Friday: Surat al-Kahf is a light between the two Fridays.",
            source: "Al-Hakim, al-Mustadrak 2/368",
            grading: "Sahih (al-Albani, Sahih al-Jami' 6470)",
            link: nil,
            defaultMinutes: 8 * 60, defaultWeekday: 6,
            target: .surah(18),
            symbol: "sun.max"
        ),
        SunnahReminderPreset(
            id: "baqarah-last-two",
            title: "Last Two Ayahs of al-Baqarah",
            subtitle: "At night",
            arabicTitle: "خَوَاتِيمُ سُورَةِ البَقَرَة",
            transliteration: "Khawātīm Sūrat al-Baqarah",
            body: "Whoever recites the last two ayahs of Surat al-Baqarah at night, they suffice him.",
            source: "Bukhari 5009, Muslim 808",
            grading: "Sahih",
            link: HadithLink(slug: "bukhari", number: 5009),
            defaultMinutes: 22 * 60, defaultWeekday: nil,
            target: .ayah(2, 285),
            symbol: "moon"
        ),
        SunnahReminderPreset(
            id: "muawwidhat-morning",
            title: "Al-Mu'awwidhat in the Morning",
            subtitle: "Al-Ikhlas, al-Falaq and an-Nas, three times each",
            arabicTitle: "المُعَوِّذَات",
            transliteration: "Al-Muʿawwidhāt",
            body: "Recite al-Ikhlas, al-Falaq and an-Nas three times each: they suffice you against everything.",
            source: "Abu Dawud 5082, Tirmidhi 3575",
            grading: "Sahih (al-Albani)",
            link: HadithLink(slug: "abudawud", number: 5082),
            defaultMinutes: 6 * 60 + 30, defaultWeekday: nil,
            target: .surah(112),
            symbol: "sunrise"
        ),
        SunnahReminderPreset(
            id: "muawwidhat-evening",
            title: "Al-Mu'awwidhat in the Evening",
            subtitle: "Al-Ikhlas, al-Falaq and an-Nas, three times each",
            arabicTitle: "المُعَوِّذَات",
            transliteration: "Al-Muʿawwidhāt",
            body: "Recite al-Ikhlas, al-Falaq and an-Nas three times each: they suffice you against everything.",
            source: "Abu Dawud 5082, Tirmidhi 3575",
            grading: "Sahih (al-Albani)",
            link: HadithLink(slug: "abudawud", number: 5082),
            defaultMinutes: 18 * 60 + 30, defaultWeekday: nil,
            target: .surah(112),
            symbol: "sunset"
        ),
        SunnahReminderPreset(
            id: "friday-fajr",
            title: "Friday Fajr Surahs",
            subtitle: "As-Sajdah and al-Insan",
            arabicTitle: "السَّجدَة وَالإِنسَان",
            transliteration: "As-Sajdah wa al-Insān",
            body: "The Prophet ﷺ recited as-Sajdah and al-Insan in the Fajr prayer of Friday.",
            source: "Bukhari 891, Muslim 879",
            grading: "Sahih",
            link: HadithLink(slug: "bukhari", number: 891),
            defaultMinutes: 5 * 60 + 30, defaultWeekday: 6,
            target: .surah(32),
            symbol: "sun.horizon"
        ),
        SunnahReminderPreset(
            id: "al-imran-night",
            title: "Last Ten Ayahs of Ali 'Imran",
            subtitle: "When you wake at night",
            arabicTitle: "خَوَاتِيمُ آلِ عِمرَان",
            transliteration: "Khawātīm Āl ʿImrān",
            body: "The Prophet ﷺ recited the last ten ayahs of Ali 'Imran when he woke at night.",
            source: "Bukhari 4569, Muslim 256",
            grading: "Sahih",
            link: HadithLink(slug: "bukhari", number: 4569),
            defaultMinutes: 3 * 60 + 30, defaultWeekday: nil,
            target: .ayah(3, 190),
            symbol: "moon.zzz"
        ),
    ]

    static func preset(id: String) -> SunnahReminderPreset? {
        all.first { $0.id == id }
    }
}

// MARK: - The store and scheduler

/// Which presets are on, at what time, on which day; and the pending requests that carry them.
///
/// One repeating calendar request per enabled preset (identifier "SunnahReminder-<id>"), so a
/// reminder never expires and costs one slot of iOS's 64-request budget however long it runs. The
/// prayer scheduler lowers its own cap by `enabledCount()` (see `Settings.scheduleNotifications`)
/// so the two never push the queue over the limit, and its stale-prune only touches its own
/// prefixes, so these survive every prayer reschedule.
@MainActor
final class SunnahReminderStore: ObservableObject {
    static let shared = SunnahReminderStore()

    /// Shared with the prayer scheduler's budget math (`Settings.SunnahReminderBudget`).
    nonisolated static let defaultsKey = Settings.SunnahReminderBudget.defaultsKey
    nonisolated static let identifierPrefix = "SunnahReminder-"
    nonisolated static let previewIdentifier = "SunnahReminderPreview"
    nonisolated static let targetUserInfoKey = "sunnahTarget"
    nonisolated static let presetUserInfoKey = "sunnahPreset"
    nonisolated static let threadIdentifier = "sunnah-reminders"

    struct Config: Codable, Equatable {
        var enabled = false
        var minutes: Int? = nil
        var weekday: Int? = nil
    }

    @Published private(set) var configs: [String: Config]

    private init() {
        var loaded = Self.loadConfigs(from: .standard)
        #if DEBUG
        // "-sunnahSeed": three presets on, for headless screenshots of the rows and the schedule.
        // Persisted like a real change, so the prayer scheduler's budget sees them too.
        if ProcessInfo.processInfo.arguments.contains("-sunnahSeed") {
            for id in ["mulk", "kahf", "baqarah-last-two"] {
                loaded[id, default: Config()].enabled = true
            }
            if let data = try? JSONEncoder().encode(loaded) {
                UserDefaults.standard.set(data, forKey: Self.defaultsKey)
            }
        }
        #endif
        configs = loaded
        ObjectPublishCounter.attach(self, label: "SunnahReminderStore")
        #if DEBUG
        // "-sunnahScrub": thirty time-wheel ticks on Surat al-Mulk over 1.5 s, after the reveal, to
        // prove the debounce below (one "REMINDER PASS sunnah ... (change)" line, not thirty).
        if ProcessInfo.processInfo.arguments.contains("-sunnahScrub"), let mulk = SunnahReminderPreset.preset(id: "mulk") {
            Task { @MainActor in
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                for tick in 0..<30 {
                    self.setMinutes(mulk, 21 * 60 + tick)
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
            }
        }
        #endif
    }

    // MARK: Reading

    func isEnabled(_ preset: SunnahReminderPreset) -> Bool {
        configs[preset.id]?.enabled ?? false
    }

    func minutes(for preset: SunnahReminderPreset) -> Int {
        configs[preset.id]?.minutes ?? preset.defaultMinutes
    }

    func weekday(for preset: SunnahReminderPreset) -> Int? {
        guard preset.isWeekly else { return nil }
        return configs[preset.id]?.weekday ?? preset.defaultWeekday
    }

    var enabledPresets: [SunnahReminderPreset] {
        SunnahReminderPreset.all.filter { isEnabled($0) }
    }

    var enabledCount: Int { enabledPresets.count }

    // MARK: Writing

    func setEnabled(_ preset: SunnahReminderPreset, _ enabled: Bool) {
        update(preset) { $0.enabled = enabled }
    }

    func setMinutes(_ preset: SunnahReminderPreset, _ minutes: Int) {
        update(preset) { $0.minutes = max(0, min(24 * 60 - 1, minutes)) }
    }

    func setWeekday(_ preset: SunnahReminderPreset, _ weekday: Int) {
        guard (1...7).contains(weekday) else { return }
        update(preset) { $0.weekday = weekday }
    }

    private func update(_ preset: SunnahReminderPreset, _ change: (inout Config) -> Void) {
        var config = configs[preset.id] ?? Config()
        change(&config)
        configs[preset.id] = config
        save()
        scheduleReschedule()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
        Settings.SunnahReminderBudget.invalidateLiveCount()
    }

    private nonisolated static func loadConfigs(from defaults: UserDefaults) -> [String: Config] {
        guard let data = defaults.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([String: Config].self, from: data) else { return [:] }
        return decoded
    }

    // MARK: Scheduling

    private var rescheduleTask: Task<Void, Never>?

    /// A settled change re-fits the queue once: a time wheel scrub used to run the whole pass (the
    /// pending fetch, the removes, the adds and the prayer scheduler) on every minute tick.
    private func scheduleReschedule() {
        rescheduleTask?.cancel()
        rescheduleTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled, let self else { return }
            self.rescheduleTask = nil
            await self.rearm(reschedulePrayers: true, reason: "change")
        }
    }

    /// Replaces every pending Sunnah reminder with the current set, then lets the prayer scheduler
    /// re-fit its own requests under the lowered cap.
    func reschedule(reschedulePrayers: Bool = true) {
        Task { @MainActor in
            await self.rearm(reschedulePrayers: reschedulePrayers, reason: "change")
        }
    }

    /// The pass itself: the stale requests under this store's prefix removed, one repeating request
    /// per enabled preset added (a reinstall or an update drops pending requests and nothing else
    /// re-creates a repeating one, which is why the launch pass always runs it). `pendingIDs` spares
    /// a second fetch when the caller already has the list (`ReminderScheduler`).
    func rearm(pendingIDs: [String]? = nil, reschedulePrayers: Bool = false, reason: String) async {
        let center = UNUserNotificationCenter.current()
        let ids: [String]
        if let pendingIDs {
            ids = pendingIDs
        } else {
            ids = await center.pendingNotificationRequests().map(\.identifier)
        }
        let stale = ids.filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        let requests = enabledPresets.map(request(for:))
        for request in requests {
            try? await center.add(request)
        }
        #if DEBUG
        if Settings.debugPublishCounterEnabled {
            NSLog("REMINDER PASS sunnah %d requests (%@)", requests.count, reason)
        }
        #endif
        if reschedulePrayers {
            Settings.shared.scheduleNotifications(deferred: true)
        }
    }

    private func request(for preset: SunnahReminderPreset) -> UNNotificationRequest {
        let minutes = minutes(for: preset)
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        if let weekday = weekday(for: preset) {
            components.weekday = weekday
        }
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return UNNotificationRequest(identifier: Self.identifierPrefix + preset.id,
                                     content: Self.content(for: preset), trigger: trigger)
    }

    /// One copy of the reminder, five seconds from now: what it will look like on the lock screen.
    func preview(_ preset: SunnahReminderPreset) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: Self.previewIdentifier,
                                            content: Self.content(for: preset), trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Bilingual title ("Surat al-Mulk · سُورَةُ الْمُلْك"), the virtue in the body with the
    /// transliteration under it, and the target the tap opens.
    static func content(for preset: SunnahReminderPreset) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = preset.arabicTitle.map { "\(preset.title) · \($0)" } ?? preset.title
        content.body = preset.transliteration.map { "\(preset.body)\n\($0)" } ?? preset.body
        content.sound = .default
        content.threadIdentifier = threadIdentifier
        content.userInfo = [
            targetUserInfoKey: preset.target.encoded,
            presetUserInfoKey: preset.id,
        ]
        return content
    }

    /// "Every day at 9:30 PM", "Every Friday at 8:00 AM".
    func scheduleLine(for preset: SunnahReminderPreset) -> String {
        let minutes = minutes(for: preset)
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let time = Calendar.current.date(from: components).map { Self.timeFormatter.string(from: $0) } ?? ""
        if let weekday = weekday(for: preset) {
            return "Every \(Self.weekdayName(weekday)) at \(time)"
        }
        return "Every day at \(time)"
    }

    static func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        guard (1...symbols.count).contains(weekday) else { return "" }
        return symbols[weekday - 1]
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

// MARK: - The screen

/// Settings › Notifications › Sunnah Reminders (also under Quran Settings): the eight presets in
/// two cadences, each with its time, its hadith, and a door to what it is about.
struct SunnahRemindersView: View {
    @ObservedObject private var store = SunnahReminderStore.shared

    @State private var permissionDenied = false
    @State private var hadithLink: SunnahReminderPreset.HadithLink?

    private var daily: [SunnahReminderPreset] { SunnahReminderPreset.all.filter { !$0.isWeekly } }
    private var weekly: [SunnahReminderPreset] { SunnahReminderPreset.all.filter { $0.isWeekly } }

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    AccentIconChip(systemImage: "bell.and.waves.left.and.right", size: 34)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recitations the Prophet ﷺ kept")
                            .font(.subheadline.weight(.semibold))
                        Text("Each reminder carries the hadith it is rooted in. Choose the time that suits you; tapping a reminder opens the surah or ayahs it is about.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)

                if permissionDenied {
                    Label("Notifications are off for Al-Islam in iPhone Settings, so these reminders cannot arrive.", systemImage: "bell.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section(header: Text("EVERY DAY")) {
                ForEach(daily) { preset in
                    SunnahReminderRow(preset: preset) { hadithLink = $0 }
                }
            }

            Section(header: Text("ONCE A WEEK")) {
                ForEach(weekly) { preset in
                    SunnahReminderRow(preset: preset) { hadithLink = $0 }
                }
            }

            ExtraReminderSections()

            Section(footer:
                Text("Reminders repeat on their own, even when the app has not been opened for a while. The Quran Planner on the Quran tab has its own daily reminder for a paced reading plan.")
                    .font(.caption2)
            ) { EmptyView() }
        }
        .applyConditionalListStyle()
        .navigationTitle("Sunnah Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $hadithLink) { link in
            SunnahHadithSheet(link: link)
        }
        .task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            permissionDenied = status == .denied
        }
    }
}

private struct SunnahReminderRow: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var store = SunnahReminderStore.shared

    let preset: SunnahReminderPreset
    var onShowHadith: (SunnahReminderPreset.HadithLink) -> Void

    @State private var previewArmed = false

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { store.isEnabled(preset) },
            set: { enabled in
                Settings.shared.hapticFeedback()
                if enabled {
                    Task { @MainActor in
                        _ = await Settings.shared.requestNotificationAuthorization()
                        store.setEnabled(preset, true)
                    }
                } else {
                    store.setEnabled(preset, false)
                }
            }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                let minutes = store.minutes(for: preset)
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = minutes / 60
                components.minute = minutes % 60
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.setMinutes(preset, (components.hour ?? 0) * 60 + (components.minute ?? 0))
            }
        )
    }

    private var weekdayBinding: Binding<Int> {
        Binding(
            get: { store.weekday(for: preset) ?? preset.defaultWeekday ?? 6 },
            set: { store.setWeekday(preset, $0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: preset.symbol, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.title)
                        .font(.subheadline.weight(.semibold))
                    Text(preset.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: enabledBinding)
                    .labelsHidden()
                    .accessibilityLabel(preset.title)
            }

            if store.isEnabled(preset) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Time")
                            .font(.subheadline)
                        Spacer()
                        DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    if preset.isWeekly {
                        HStack {
                            Text("Day")
                                .font(.subheadline)
                            Spacer()
                            Picker("Day", selection: weekdayBinding) {
                                ForEach(1...7, id: \.self) { weekday in
                                    Text(SunnahReminderStore.weekdayName(weekday)).tag(weekday)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(appearance.accent)
                        }
                    }

                    Text(store.scheduleLine(for: preset))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let link = preset.link {
                        Button {
                            Settings.shared.hapticFeedback()
                            onShowHadith(link)
                        } label: {
                            Label("\(preset.source) · \(preset.grading)", systemImage: "text.book.closed")
                                .font(.caption)
                                .foregroundColor(appearance.accent)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Label("\(preset.source) · \(preset.grading)", systemImage: "text.book.closed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 18) {
                        Button {
                            Settings.shared.hapticFeedback()
                            AppNavigation.shared.open(preset.target)
                        } label: {
                            Label(preset.openLabel, systemImage: "book")
                        }
                        .buttonStyle(.plain)

                        Button {
                            Settings.shared.hapticFeedback()
                            store.preview(preset)
                            previewArmed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { previewArmed = false }
                        } label: {
                            Label(previewArmed ? "Arriving in 5 s" : "Preview", systemImage: "bell")
                        }
                        .buttonStyle(.plain)
                        .disabled(previewArmed)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .padding(.top, 2)
                }
                .settingsDependent()
            }
        }
        .padding(.vertical, 4)
    }
}

/// The cited hadith, in the hadith row the Hadith tab uses, so the reader sees the grading and can
/// bookmark or share it from here.
private struct SunnahHadithSheet: View {
    let link: SunnahReminderPreset.HadithLink

    @State private var book: HadithCatalogBook?
    @State private var hadith: HadithBookData.Hadith?
    @State private var failed = false

    var body: some View {
        SheetNavigationContainer {
            List {
                if let book, let hadith {
                    Section {
                        HadithRow(book: book, hadith: hadith)
                    }
                } else if failed {
                    Text("This hadith could not be opened.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
            .applyConditionalListStyle()
            .navigationTitle(book?.englishTitle ?? "Hadith")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .smallMediumSheetPresentation(startLarge: true)
        .task {
            guard let found = HadithCatalogBook.all.first(where: { $0.slug == link.slug }) else {
                failed = true
                return
            }
            book = found
            guard let data = await HadithStore.shared.openOffMain(found),
                  let resolved = data.hadith(referenced: link.number, suffix: link.suffix) else {
                failed = true
                return
            }
            hadith = resolved
        }
    }
}
#endif
