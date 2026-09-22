#if os(iOS)
import SwiftUI
@preconcurrency import UserNotifications

// The reminders beyond the Sunnah presets: the reader's own (any surah or ayah, daily or on one
// weekday), duas from the Sunnah pushed at random times through the day, a nudge to pick up where
// the reading stopped, and a nudge to keep the streak. Same store shape and budget discipline as
// SunnahReminderStore: every request carries one of this file's identifier prefixes, the prayer
// scheduler lowers its own cap by `Settings.SunnahReminderBudget.enabledCount()` (which counts
// these too), and one-shot look-aheads are short because the app re-arms them on every open.
// Modelled on Tilawa's reminders (Jamil Hammoudeh).

struct CustomReminder: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var label: String = ""
    var minutes: Int = 20 * 60
    /// Calendar weekday (1 = Sunday); nil = every day.
    var weekday: Int? = nil
    var surah: Int? = nil
    var ayah: Int? = nil
    var enabled: Bool = true

    var target: QuranOpenTarget {
        if let surah {
            if let ayah { return .ayah(surah, ayah) }
            return .surah(surah)
        }
        return .tab
    }
}

struct ExtraReminderConfig: Codable, Equatable {
    var duaEnabled = false
    /// 1, 2, 3, 4 or 6 duas a day, between 9 AM and 9 PM.
    var duaPerDay = 1
    var lastReadEnabled = false
    var lastReadMinutes = 20 * 60
    var streakEnabled = false
    var streakMinutes = 21 * 60
}

@MainActor
final class ExtraRemindersStore: ObservableObject {
    static let shared = ExtraRemindersStore()

    nonisolated static let customKey = Settings.SunnahReminderBudget.customKey
    nonisolated static let configKey = Settings.SunnahReminderBudget.extraKey
    nonisolated static let customPrefix = "CustomReminder-"
    nonisolated static let duaPrefix = "DuaReminder-"
    nonisolated static let lastReadPrefix = "LastReadNudge-"
    nonisolated static let streakPrefix = "StreakNudge-"
    nonisolated static let prefixes = [customPrefix, duaPrefix, lastReadPrefix, streakPrefix]
    nonisolated static let threadIdentifier = "sunnah-reminders"

    /// Look-ahead for the one-shot kinds. Short on purpose: each fire is a pending slot, and the
    /// app re-arms the queue every time it opens.
    nonisolated static let nudgeDays = Settings.SunnahReminderBudget.nudgeDays
    nonisolated static let duaCap = Settings.SunnahReminderBudget.duaCap

    @Published private(set) var custom: [CustomReminder]
    @Published private(set) var config: ExtraReminderConfig

    private var lastArmed: Date?

    private init() {
        var loadedCustom = Self.loadCustom(from: .standard)
        var loadedConfig = Self.loadConfig(from: .standard)
        #if DEBUG
        // "-extraSeed": one custom reminder plus the dua and both nudge kinds on, persisted like a
        // real change so the prayer scheduler's budget sees them ("Prayer schedule: N/M" in the log).
        if ProcessInfo.processInfo.arguments.contains("-extraSeed") {
            if loadedCustom.isEmpty {
                loadedCustom = [CustomReminder(label: "", minutes: 20 * 60 + 15, weekday: nil, surah: 36, ayah: nil, enabled: true)]
            }
            loadedConfig.duaEnabled = true
            loadedConfig.duaPerDay = 2
            loadedConfig.lastReadEnabled = true
            loadedConfig.streakEnabled = true
            if let data = try? JSONEncoder().encode(loadedCustom) { UserDefaults.standard.set(data, forKey: Self.customKey) }
            if let data = try? JSONEncoder().encode(loadedConfig) { UserDefaults.standard.set(data, forKey: Self.configKey) }
        }
        #endif
        custom = loadedCustom
        config = loadedConfig
        ObjectPublishCounter.attach(self, label: "ExtraRemindersStore")
        storageObserver = StoredContentObserver(reload: { ExtraRemindersStore.shared.reloadFromStorage() })
    }

    private var storageObserver: StoredContentObserver?

    /// The reminders on disk changed underneath this object (a restore, a reset): take them, and
    /// rebuild the pending queue from them (see `SunnahReminderStore.reloadFromStorage`).
    private func reloadFromStorage() {
        let storedCustom = Self.loadCustom(from: .standard)
        let storedConfig = Self.loadConfig(from: .standard)
        guard storedCustom != custom || storedConfig != config else { return }
        custom = storedCustom
        config = storedConfig
        Settings.SunnahReminderBudget.invalidateLiveCount()
        scheduleReschedule()
    }

    private nonisolated static func loadCustom(from defaults: UserDefaults) -> [CustomReminder] {
        guard let data = defaults.data(forKey: customKey),
              let decoded = try? JSONDecoder().decode([CustomReminder].self, from: data) else { return [] }
        return decoded
    }

    private nonisolated static func loadConfig(from defaults: UserDefaults) -> ExtraReminderConfig {
        guard let data = defaults.data(forKey: configKey),
              let decoded = try? JSONDecoder().decode(ExtraReminderConfig.self, from: data) else { return ExtraReminderConfig() }
        return decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(custom) { UserDefaults.standard.set(data, forKey: Self.customKey) }
        if let data = try? JSONEncoder().encode(config) { UserDefaults.standard.set(data, forKey: Self.configKey) }
        Settings.SunnahReminderBudget.invalidateLiveCount()
    }

    var anythingOn: Bool {
        custom.contains { $0.enabled } || config.duaEnabled || config.lastReadEnabled || config.streakEnabled
    }

    // MARK: Writing

    func add(_ reminder: CustomReminder) {
        custom.append(reminder)
        save()
        scheduleReschedule()
    }

    func update(_ reminder: CustomReminder) {
        guard let index = custom.firstIndex(where: { $0.id == reminder.id }) else { return }
        custom[index] = reminder
        save()
        scheduleReschedule()
    }

    func remove(_ id: String) {
        custom.removeAll { $0.id == id }
        save()
        scheduleReschedule()
    }

    func updateConfig(_ change: (inout ExtraReminderConfig) -> Void) {
        change(&config)
        config.duaPerDay = [1, 2, 3, 4, 6].contains(config.duaPerDay) ? config.duaPerDay : 1
        save()
        scheduleReschedule()
    }

    // MARK: Scheduling

    /// Everything a pass reads, taken on the main actor (Settings, QuranData, the activity log, the
    /// dua corpus) so the requests can be built and added off it.
    struct BuildInputs {
        struct SurahName {
            let transliteration: String
            let arabic: String
        }
        struct DuaCard {
            let arabic: String
            let transliteration: String?
            let english: String
            let source: String
            let isDhikr: Bool
        }
        let custom: [CustomReminder]
        let config: ExtraReminderConfig
        /// The reader's last-read position with its surah name, nil when there is none.
        let lastRead: (surah: Int, ayah: Int, name: String)?
        /// A khatm mark OR a last-read write landed today (the daily anchor), so the nudge stays quiet
        /// for a page-mode reader without the khatm auto-mark too.
        let readToday: Bool
        let streak: ActivityLog.Streak
        let corpus: [DuaCard]
        let surahNames: [Int: SurahName]
        let dayKey: String
        let now: Date
    }

    /// Reads the inputs of a pass, on the main actor.
    func buildInputs() -> BuildInputs {
        let settings = Settings.shared
        let data = QuranData.shared
        var lastRead: (surah: Int, ayah: Int, name: String)?
        if settings.lastReadSurah > 0, let surah = data.surah(settings.lastReadSurah) {
            lastRead = (settings.lastReadSurah, settings.lastReadAyah, surah.nameTransliteration)
        }
        let anchor = settings.dailyAnchor()
        let dayKey = Settings.dayKey(anchor)
        let log = ActivityLog.shared
        log.refreshSummaryIfDayChanged()
        let readToday = log.count(.read, on: dayKey) > 0
            || (settings.lastReadDate.map { settings.dailyAnchor(for: $0) == anchor } ?? false)
        var names: [Int: BuildInputs.SurahName] = [:]
        for reminder in custom where reminder.enabled {
            if let id = reminder.surah, names[id] == nil, let surah = data.surah(id) {
                names[id] = BuildInputs.SurahName(transliteration: surah.nameTransliteration, arabic: surah.nameArabic)
            }
        }
        // The corpus is parsed at app init (Phase 1), so this is a cached read by the time any pass runs.
        let corpus: [BuildInputs.DuaCard] = config.duaEnabled
            ? DailyReminderStore.shared.entries
                .filter { $0.kind == .dua || $0.kind == .dhikr }
                .map { BuildInputs.DuaCard(arabic: $0.arabic, transliteration: $0.transliteration, english: $0.english,
                                           source: $0.source, isDhikr: $0.kind == .dhikr) }
            : []
        return BuildInputs(custom: custom, config: config, lastRead: lastRead, readToday: readToday,
                           streak: config.streakEnabled ? log.summary.streak : ActivityLog.Streak(),
                           corpus: corpus, surahNames: names, dayKey: dayKey, now: Date())
    }

    /// What a pass depends on, as one string: the day, the reader's own reminders, the config, the
    /// last-read position, whether today counts as read, and the streak. Equal signatures mean an
    /// identical queue, so a foreground re-arm and a relaunch the same day leave the pending requests,
    /// and the dua times the reader may already have seen, where they are.
    nonisolated static func signature(of inputs: BuildInputs) -> String {
        let custom = inputs.custom
            .map { "\($0.id):\($0.enabled ? 1 : 0):\($0.minutes):\($0.weekday ?? 0):\($0.surah ?? 0):\($0.ayah ?? 0)" }
            .joined(separator: ",")
        let config = inputs.config
        let configPart = "\(config.duaEnabled ? 1 : 0):\(config.duaPerDay):\(config.lastReadEnabled ? 1 : 0):\(config.lastReadMinutes):\(config.streakEnabled ? 1 : 0):\(config.streakMinutes)"
        let readPart = "\(inputs.lastRead?.surah ?? 0):\(inputs.lastRead?.ayah ?? 0):\(inputs.readToday ? 1 : 0)"
        let streakPart = "\(inputs.streak.current):\(inputs.streak.activeToday ? 1 : 0)"
        return [inputs.dayKey, custom, configPart, readPart, streakPart].joined(separator: "|")
    }

    private static let signatureKey = "extraRemindersArmedSignature"

    /// The signature of the queue this device last armed, on disk so a relaunch the same day keeps it.
    var persistedSignature: String? {
        get { UserDefaults.standard.string(forKey: Self.signatureKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.signatureKey) }
    }

    /// On every foreground: the one-shot kinds depend on today's reading and the current streak, so
    /// the queue is rebuilt when an input changed since the last arm (the day, the position, the
    /// config, the streak) and left alone otherwise. Under the launch cover the launch pass
    /// (`ReminderScheduler.rearmAfterLaunch`) owns it.
    func rearmIfNeeded() {
        guard anythingOn, AppReveal.revealed else { return }
        let inputs = buildInputs()
        guard Self.signature(of: inputs) != persistedSignature else { return }
        Task { @MainActor in
            await self.rebuild(inputs: inputs, reschedulePrayers: false, reason: "foreground")
        }
    }

    private var rescheduleTask: Task<Void, Never>?

    /// A settled change re-fits the queue once (see `SunnahReminderStore.scheduleReschedule`).
    private func scheduleReschedule() {
        rescheduleTask?.cancel()
        rescheduleTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled, let self else { return }
            self.rescheduleTask = nil
            await self.reschedule()
        }
    }

    /// Rebuilds the queue from the current inputs (a settled user change), then lets the prayer
    /// scheduler re-fit its own requests under the changed budget.
    func reschedule() async {
        await rebuild(inputs: buildInputs(), reschedulePrayers: true, reason: "change")
    }

    /// The pass: every pending request under this file's prefixes removed and a fresh set built and
    /// added, all off the main actor (the request objects, the removal and the up-to-20 `center.add`
    /// calls); `pendingIDs` spares a second fetch when the caller already has the list. Notes the
    /// signature when done.
    func rebuild(inputs: BuildInputs, pendingIDs: [String]? = nil, reschedulePrayers: Bool, reason: String) async {
        let prefixes = Self.prefixes
        await Task.detached(priority: .utility) {
            let center = UNUserNotificationCenter.current()
            let ids: [String]
            if let pendingIDs {
                ids = pendingIDs
            } else {
                ids = await center.pendingNotificationRequests().map(\.identifier)
            }
            let stale = ids.filter { id in prefixes.contains { id.hasPrefix($0) } }
            center.removePendingNotificationRequests(withIdentifiers: stale)
            let requests = Self.buildRequests(inputs)
            for request in requests {
                try? await center.add(request)
            }
            #if DEBUG
            if Settings.debugPublishCounterEnabled {
                let after = await center.pendingNotificationRequests().filter { r in prefixes.contains { r.identifier.hasPrefix($0) } }.count
                NSLog("REMINDER PASS extra %d requests, pending %d (%@)", requests.count, after, reason)
            }
            #endif
        }.value
        persistedSignature = Self.signature(of: inputs)
        if reschedulePrayers {
            Settings.shared.scheduleNotifications(deferred: true)
        }
    }

    /// Pure: the requests for a set of inputs. Runs off the main actor.
    nonisolated static func buildRequests(_ inputs: BuildInputs) -> [UNNotificationRequest] {
        var requests: [UNNotificationRequest] = []
        let config = inputs.config

        for reminder in inputs.custom where reminder.enabled {
            var components = DateComponents()
            components.hour = reminder.minutes / 60
            components.minute = reminder.minutes % 60
            if let weekday = reminder.weekday { components.weekday = weekday }
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let surah = reminder.surah.flatMap { inputs.surahNames[$0] }
            requests.append(UNNotificationRequest(identifier: customPrefix + reminder.id,
                                                  content: content(for: reminder, surah: surah), trigger: trigger))
        }

        let now = inputs.now
        let calendar = Calendar.current

        if config.lastReadEnabled, let lastRead = inputs.lastRead {
            for offset in 0..<nudgeDays {
                if offset == 0, inputs.readToday { continue }
                guard let fireAt = fireDate(dayOffset: offset, minutes: config.lastReadMinutes, now: now, calendar: calendar),
                      fireAt > now.addingTimeInterval(30) else { continue }
                let content = UNMutableNotificationContent()
                content.title = "Pick up where you left off"
                content.body = "You stopped at \(lastRead.name) \(lastRead.surah):\(lastRead.ayah). A few ayahs?"
                content.sound = .default
                content.threadIdentifier = threadIdentifier
                content.userInfo = [SunnahReminderStore.targetUserInfoKey: QuranOpenTarget.ayah(lastRead.surah, max(1, lastRead.ayah)).encoded]
                let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt), repeats: false)
                requests.append(UNNotificationRequest(identifier: lastReadPrefix + Settings.dayKey(fireAt), content: content, trigger: trigger))
            }
        }

        if config.streakEnabled {
            let streak = inputs.streak
            if streak.current > 0 {
                for offset in 0..<nudgeDays {
                    if offset == 0, streak.activeToday { continue }
                    guard let fireAt = fireDate(dayOffset: offset, minutes: config.streakMinutes, now: now, calendar: calendar),
                          fireAt > now.addingTimeInterval(30) else { continue }
                    let projected = streak.current + offset
                    let content = UNMutableNotificationContent()
                    content.title = "Keep the chain going"
                    content.body = projected >= 30
                        ? "Day \(projected) of your streak. Do not let it break tonight."
                        : projected >= 7
                            ? "Day \(projected) of your streak. Read one ayah to keep it alive."
                            : "Streak day \(projected). Keep the chain going."
                    content.sound = .default
                    content.threadIdentifier = threadIdentifier
                    content.userInfo = [SunnahReminderStore.targetUserInfoKey: QuranOpenTarget.tab.encoded]
                    let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt), repeats: false)
                    requests.append(UNNotificationRequest(identifier: streakPrefix + Settings.dayKey(fireAt), content: content, trigger: trigger))
                }
            }
        }

        if config.duaEnabled {
            requests.append(contentsOf: duaRequests(inputs: inputs, calendar: calendar))
        }
        return requests
    }

    /// One-shot dua notifications: `duaPerDay` slots between 9 AM and 9 PM, each jittered by up to
    /// three quarters of an hour so they never feel metronomic, until the cap is spent. The body is
    /// composed per slot, which is why these cannot be repeating triggers. The jitter and the pick
    /// are drawn from a generator seeded by the slot's own calendar day and index (decision D of the
    /// Tilawa Guide, 2026-09-07): every pass, on any day, rebuilds the same time and the same dua for
    /// a slot, so a re-arm after a page turn or a relaunch never moves a time the reader has seen.
    nonisolated private static func duaRequests(inputs: BuildInputs, calendar: Calendar) -> [UNNotificationRequest] {
        let corpus = inputs.corpus
        guard !corpus.isEmpty else { return [] }
        let now = inputs.now
        let perDay = max(1, min(6, inputs.config.duaPerDay))
        let slotMinutes = Double(12 * 60) / Double(perDay)
        var requests: [UNNotificationRequest] = []
        var dayOffset = 0
        while requests.count < duaCap, dayOffset < 14 {
            let dayKey = fireDayKey(dayOffset: dayOffset, now: now, calendar: calendar)
            for slot in 0..<perDay where requests.count < duaCap {
                var generator = SlotGenerator(dayKey: dayKey, slot: slot, perDay: perDay)
                let center = 9 * 60 + slotMinutes * (Double(slot) + 0.5)
                let jitter = Double.random(in: -45...45, using: &generator)
                guard let fireAt = fireDate(dayOffset: dayOffset, minutes: Int(center + jitter), now: now, calendar: calendar),
                      fireAt > now.addingTimeInterval(60) else { continue }
                guard let dua = corpus.randomElement(using: &generator) else { continue }
                let content = UNMutableNotificationContent()
                content.title = dua.isDhikr ? "A dhikr from the Sunnah" : "A dua from the Sunnah"
                var lines = [dua.arabic]
                if let transliteration = dua.transliteration, !transliteration.isEmpty { lines.append(transliteration) }
                if !dua.english.isEmpty { lines.append(dua.english) }
                if !dua.source.isEmpty { lines.append(dua.source) }
                content.body = lines.joined(separator: "\n")
                content.sound = .default
                content.threadIdentifier = threadIdentifier
                let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt), repeats: false)
                requests.append(UNNotificationRequest(identifier: duaPrefix + "\(dayOffset)-\(slot)", content: content, trigger: trigger))
            }
            dayOffset += 1
        }
        return requests
    }

    #if DEBUG
    /// "-duaSlotProbe" (pair with "-extraSeed"): the dua slots this device would arm, printed twice
    /// in the one run. Two runs on the same day print the same times and the same duas, which is
    /// what decision D bought: a re-arm after a page turn never moves a time the reader has seen.
    static func logDuaSlotProbe() {
        let inputs = ExtraRemindersStore.shared.buildInputs()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM-dd HH:mm"
        for pass in 1...2 {
            let rows = duaRequests(inputs: inputs, calendar: calendar).map { request -> String in
                let fire = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                let opening = request.content.body.split(separator: "\n").first.map(String.init) ?? ""
                return "\(request.identifier)@\(fire.map(formatter.string(from:)) ?? "?")|\(opening.prefix(10))"
            }
            print("DUA SLOTS pass \(pass) \(rows.count): \(rows.joined(separator: " "))")
        }
    }
    #endif

    nonisolated private static func fireDate(dayOffset: Int, minutes: Int, now: Date, calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: now)
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
        return calendar.date(byAdding: .minute, value: max(0, min(24 * 60 - 1, minutes)), to: day)
    }

    /// "2026-09-08" for the calendar day `dayOffset` days from now: the seed of that day's slots,
    /// so tomorrow's pass (where the same day sits at offset 0) draws the same times.
    nonisolated private static func fireDayKey(dayOffset: Int, now: Date, calendar: Calendar) -> String {
        let today = calendar.startOfDay(for: now)
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return "\(dayOffset)" }
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// A small deterministic generator (SplitMix64 over an FNV-1a seed) for one dua slot: the same
    /// day, slot and slots-per-day always draw the same jitter and the same dua, on every device.
    private struct SlotGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(dayKey: String, slot: Int, perDay: Int) {
            var hash: UInt64 = 0xcbf2_9ce4_8422_2325
            for byte in "\(dayKey)#\(perDay)#\(slot)".utf8 {
                hash ^= UInt64(byte)
                hash = hash &* 0x0000_0100_0000_01B3
            }
            state = hash
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    /// "Surat al-Mulk · سُورَةُ الْمُلْك" when a surah is named and the reader wrote no label of
    /// their own; a written label wins as given.
    nonisolated static func content(for reminder: CustomReminder, surah: BuildInputs.SurahName?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let label = reminder.label.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = reminder.surah, let surah {
            let name = surah.transliteration
            content.title = label.isEmpty ? "Surat \(name) · \(surah.arabic)" : label
            if let ayah = reminder.ayah {
                content.body = label.isEmpty ? "Time to recite \(name) \(id):\(ayah)." : "\(name) \(id):\(ayah)"
            } else {
                content.body = label.isEmpty ? "Time to recite Surat \(name)." : "Surat \(name)"
            }
        } else {
            content.title = label.isEmpty ? "Reminder" : label
            content.body = label.isEmpty ? "Time for your Quran reminder." : "Open the Quran."
        }
        content.sound = .default
        content.threadIdentifier = threadIdentifier
        content.userInfo = [SunnahReminderStore.targetUserInfoKey: reminder.target.encoded]
        return content
    }

    /// One copy of a custom reminder, five seconds from now.
    func preview(_ reminder: CustomReminder) {
        let surah = reminder.surah.flatMap { QuranData.shared.surah($0) }
            .map { BuildInputs.SurahName(transliteration: $0.nameTransliteration, arabic: $0.nameArabic) }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: SunnahReminderStore.previewIdentifier,
                                            content: Self.content(for: reminder, surah: surah), trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleLine(minutes: Int, weekday: Int?) -> String {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let time = Calendar.current.date(from: components).map { Self.timeFormatter.string(from: $0) } ?? ""
        if let weekday { return "Every \(SunnahReminderStore.weekdayName(weekday)) at \(time)" }
        return "Every day at \(time)"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

// MARK: - The launch pass

/// One notification pass per launch for every reminder kind, from the post-reveal schedule (+1.5 s)
/// instead of two passes inside the AppDelegate's reveal wait: one pending fetch, the Sunnah presets
/// re-added (a reinstall or an update drops pending requests and nothing else re-creates a repeating
/// one), and the extra kinds rebuilt only when their inputs changed since the last arm or the queue
/// lost them, so a relaunch the same day keeps the dua times the reader may have seen.
@MainActor
enum ReminderScheduler {
    static func rearmAfterLaunch() async {
        let sunnah = SunnahReminderStore.shared
        let extra = ExtraRemindersStore.shared
        guard sunnah.enabledCount > 0 || extra.anythingOn else { return }
        let center = UNUserNotificationCenter.current()
        let pendingIDs = await center.pendingNotificationRequests().map(\.identifier)
        if sunnah.enabledCount > 0 {
            await sunnah.rearm(pendingIDs: pendingIDs, reason: "launch")
        }
        let extraPending = pendingIDs.filter { id in ExtraRemindersStore.prefixes.contains { id.hasPrefix($0) } }
        guard extra.anythingOn else {
            // Nothing on: leftovers of the extra kinds from an earlier configuration go.
            if !extraPending.isEmpty { center.removePendingNotificationRequests(withIdentifiers: extraPending) }
            return
        }
        let inputs = extra.buildInputs()
        if !extraPending.isEmpty, ExtraRemindersStore.signature(of: inputs) == extra.persistedSignature {
            #if DEBUG
            if Settings.debugPublishCounterEnabled {
                NSLog("REMINDER PASS extra kept, pending %d (launch, unchanged)", extraPending.count)
            }
            #endif
            return
        }
        await extra.rebuild(inputs: inputs, pendingIDs: pendingIDs, reschedulePrayers: false, reason: "launch")
    }
}

// MARK: - The sections (appended to the Sunnah Reminders screen)

struct ExtraReminderSections: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var store = ExtraRemindersStore.shared

    @State private var editing: CustomReminder?
    @State private var adding = false

    private var accent: Color { appearance.accent }

    var body: some View {
        Section(header: Text("YOUR OWN REMINDERS"), footer:
            Text("Any surah or ayah, every day or on one weekday. Tapping the reminder opens it in the Quran.")
                .font(.caption2)
        ) {
            ForEach(store.custom) { reminder in
                CustomReminderRow(reminder: reminder) { editing = reminder }
            }
            Button {
                Settings.shared.hapticFeedback()
                Task { @MainActor in
                    _ = await Settings.shared.requestNotificationAuthorization()
                    adding = true
                }
            } label: {
                Label("Add a reminder", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(accent)
            }
        }

        Section(header: Text("DUAS THROUGH THE DAY"), footer:
            Text("Authentic duas and adhkar from the Sunnah, with transliteration, meaning and source, at random times between 9 AM and 9 PM.")
                .font(.caption2)
        ) {
            Toggle(isOn: Binding(
                get: { store.config.duaEnabled },
                set: { on in
                    Settings.shared.hapticFeedback()
                    if on {
                        Task { @MainActor in
                            _ = await Settings.shared.requestNotificationAuthorization()
                            store.updateConfig { $0.duaEnabled = true }
                        }
                    } else {
                        store.updateConfig { $0.duaEnabled = false }
                    }
                }
            )) {
                Label("Random duas", systemImage: "hands.sparkles.fill")
            }
            if store.config.duaEnabled {
                Picker("Each day", selection: Binding(
                    get: { store.config.duaPerDay },
                    set: { n in store.updateConfig { $0.duaPerDay = n } }
                )) {
                    ForEach([1, 2, 3, 4, 6], id: \.self) { n in
                        Text(n == 1 ? "Once" : "\(n) times").tag(n)
                    }
                }
                .pickerStyle(.menu)
                .tint(accent)
            }
        }

        Section(header: Text("NUDGES"), footer:
            Text("Pick Up Where You Left Off stays quiet on a day you have already read. Keep Your Streak only speaks while there is a streak to keep.")
                .font(.caption2)
        ) {
            nudgeRow(title: "Pick up where you left off", symbol: "bookmark.fill",
                     enabled: store.config.lastReadEnabled, minutes: store.config.lastReadMinutes,
                     setEnabled: { on in store.updateConfig { $0.lastReadEnabled = on } },
                     setMinutes: { m in store.updateConfig { $0.lastReadMinutes = m } })
            nudgeRow(title: "Keep your streak", symbol: "flame.fill",
                     enabled: store.config.streakEnabled, minutes: store.config.streakMinutes,
                     setEnabled: { on in store.updateConfig { $0.streakEnabled = on } },
                     setMinutes: { m in store.updateConfig { $0.streakMinutes = m } })
        }
        .sheet(isPresented: $adding) {
            CustomReminderEditor(reminder: CustomReminder()) { store.add($0) }
        }
        .sheet(item: $editing) { reminder in
            CustomReminderEditor(reminder: reminder) { store.update($0) }
        }
    }

    private func nudgeRow(title: String, symbol: String, enabled: Bool, minutes: Int,
                          setEnabled: @escaping (Bool) -> Void, setMinutes: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { enabled },
                set: { on in
                    Settings.shared.hapticFeedback()
                    if on {
                        Task { @MainActor in
                            _ = await Settings.shared.requestNotificationAuthorization()
                            setEnabled(true)
                        }
                    } else {
                        setEnabled(false)
                    }
                }
            )) {
                Label(title, systemImage: symbol)
            }
            if enabled {
                HStack {
                    Text("Time")
                        .font(.subheadline)
                    Spacer()
                    DatePicker("Time", selection: Binding(
                        get: { Self.date(minutes: minutes) },
                        set: { setMinutes(Self.minutes(of: $0)) }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                }
                .settingsDependent()
            }
        }
        .padding(.vertical, 2)
    }

    static func date(minutes: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    static func minutes(of date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

private struct CustomReminderRow: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var store = ExtraRemindersStore.shared
    @ObservedObject private var quranData = QuranData.shared

    let reminder: CustomReminder
    var onEdit: () -> Void

    @State private var previewArmed = false

    private var title: String {
        let label = reminder.label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !label.isEmpty { return label }
        if let id = reminder.surah, let surah = quranData.surah(id) {
            if let ayah = reminder.ayah { return "\(surah.nameTransliteration) \(id):\(ayah)" }
            return "Surat \(surah.nameTransliteration)"
        }
        return "Reminder"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: reminder.surah == nil ? "bell" : "book.closed", size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(store.scheduleLine(minutes: reminder.minutes, weekday: reminder.weekday))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: Binding(
                    get: { reminder.enabled },
                    set: { on in
                        Settings.shared.hapticFeedback()
                        var copy = reminder
                        copy.enabled = on
                        store.update(copy)
                    }
                ))
                .labelsHidden()
            }

            HStack(spacing: 18) {
                Button {
                    Settings.shared.hapticFeedback()
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.plain)

                Button {
                    Settings.shared.hapticFeedback()
                    store.preview(reminder)
                    previewArmed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) { previewArmed = false }
                } label: {
                    Label(previewArmed ? "Arriving in 5 s" : "Preview", systemImage: "bell")
                }
                .buttonStyle(.plain)
                .disabled(previewArmed)

                Button(role: .destructive) {
                    Settings.shared.hapticFeedback()
                    store.remove(reminder.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.plain)
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(appearance.accent)
        }
        .padding(.vertical, 4)
    }
}

/// A reminder of the reader's own: a name, a surah (or none), an ayah, the time, the day.
private struct CustomReminderEditor: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    @State private var draft: CustomReminder
    let onSave: (CustomReminder) -> Void

    init(reminder: CustomReminder, onSave: @escaping (CustomReminder) -> Void) {
        _draft = State(initialValue: reminder)
        self.onSave = onSave
    }

    private var ayahCount: Int {
        guard let id = draft.surah, let surah = quranData.surah(id) else { return 0 }
        return surah.numberOfAyahs
    }

    var body: some View {
        SheetNavigationContainer {
            List {
                Section(header: Text("NAME"), footer: Text("Optional. Without one the reminder is named after its surah.").font(.caption2)) {
                    TextField("What to call it", text: $draft.label)
                }

                Section(header: Text("WHAT TO OPEN")) {
                    Picker("Surah", selection: Binding(
                        get: { draft.surah ?? 0 },
                        set: { id in
                            draft.surah = id == 0 ? nil : id
                            draft.ayah = nil
                        }
                    )) {
                        Text("The Quran tab").tag(0)
                        ForEach(quranData.quran, id: \.id) { surah in
                            Text("\(surah.id). \(surah.nameTransliteration)").tag(surah.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(appearance.accent)

                    if draft.surah != nil, ayahCount > 0 {
                        Stepper(value: Binding(
                            get: { draft.ayah ?? 0 },
                            set: { draft.ayah = $0 == 0 ? nil : $0 }
                        ), in: 0...ayahCount) {
                            Text(draft.ayah.map { "Ayah \($0)" } ?? "Whole surah")
                                .font(.subheadline)
                        }
                    }
                }

                Section(header: Text("WHEN")) {
                    DatePicker("Time", selection: Binding(
                        get: { ExtraReminderSections.date(minutes: draft.minutes) },
                        set: { draft.minutes = ExtraReminderSections.minutes(of: $0) }
                    ), displayedComponents: .hourAndMinute)

                    Picker("Repeat", selection: Binding(
                        get: { draft.weekday ?? 0 },
                        set: { draft.weekday = $0 == 0 ? nil : $0 }
                    )) {
                        Text("Every day").tag(0)
                        ForEach(1...7, id: \.self) { weekday in
                            Text("Every \(SunnahReminderStore.weekdayName(weekday))").tag(weekday)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(appearance.accent)
                }

                Section {
                    Button {
                        Settings.shared.hapticFeedback()
                        draft.enabled = true
                        onSave(draft)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Reminder")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                    .foregroundColor(appearance.accent)
                }
            }
            .applyConditionalListStyle()
            .navigationTitle("Your Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .smallMediumSheetPresentation(startLarge: true)
    }
}
#endif
