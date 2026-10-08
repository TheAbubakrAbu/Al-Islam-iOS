import AppIntents

@available(iOS 16.0, watchOS 9.0, *)
enum PrayerKind: String, AppEnum, CaseIterable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Prayer")

    static var caseDisplayRepresentations: [PrayerKind: DisplayRepresentation] = [
        .fajr: "Fajr",
        .sunrise: "Sunrise",
        .dhuhr: "Dhuhr",
        .asr: "Asr",
        .maghrib: "Maghrib",
        .isha: "Isha"
    ]

    var searchKeys: [String] {
        switch self {
        case .fajr:
            return ["Fajr", "Fajer", "Dawn"]
        case .sunrise:
            return ["Shurooq", "Sunrise"]
        case .dhuhr:
            return ["Dhuhr", "Thuhr", "Dhuhur", "Thuhur", "Jumuah", "Noon"]
        case .asr:
            return ["Asr", "Aser", "Afternoon"]
        case .maghrib:
            return ["Maghrib", "Magrib", "Maghreb", "Magreb", "Sunset"]
        case .isha:
            return ["Isha", "Ishaa", "Esha", "Eshaa", "Night"]
        }
    }
}

@available(iOS 16.0, watchOS 9.0, *)
private extension Settings {
    func todayFullPrayerList() -> [Prayer]? {
        getPrayerTimes(for: Date(), fullPrayers: true)
    }

    func spokenPrayerName(for prayer: Prayer) -> String {
        prayer.nameTransliteration == "Jumuah" ? "Jumuah (Dhuhr)" : prayer.nameTransliteration
    }

    func prayerTimeMessage(prefix: String, prayer: Prayer) -> String {
        "\(prefix): \(spokenPrayerName(for: prayer)) at \(formatDate(prayer.time))."
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct WhenIsPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "When is Prayer"
    static var description = IntentDescription("Ask for today's time of a specific prayer.")
    static var openAppWhenRun: Bool = false
    static var parameterSummary: some ParameterSummary { Summary("When is \(\.$prayer)") }

    @Parameter(title: "Prayer") var prayer: PrayerKind

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let settings = Settings.shared

        guard let prayers = settings.todayFullPrayerList(), !prayers.isEmpty else {
            let message = "Prayer times aren’t available yet. Open \(AppIdentifiers.appName) to refresh."
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }

        if let prayer = prayers.first(where: matchesRequestedPrayer) {
            let message = "\(settings.spokenPrayerName(for: prayer)) is at \(settings.formatDate(prayer.time))."
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }

        let message = "Couldn’t find today’s time for \(prayer.rawValue)."
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }

    private func matchesRequestedPrayer(_ prayerTime: Prayer) -> Bool {
        prayer.searchKeys.contains(prayerTime.nameTransliteration) || prayer.searchKeys.contains(prayerTime.nameEnglish)
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct CurrentPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Current Prayer"
    static var description = IntentDescription("Tell me the current prayer (name and time).")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let settings = Settings.shared
        settings.fetchPrayerTimes()

        if let currentPrayer = settings.currentPrayer {
            let message = "Current prayer: \(settings.spokenPrayerName(for: currentPrayer)) (\(settings.formatDate(currentPrayer.time)))."
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }

        if let prayers = settings.todayFullPrayerList(),
           let prayer = prayers.last(where: { $0.time <= Date() }) {
            let message = settings.prayerTimeMessage(prefix: "Current prayer", prayer: prayer)
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }

        let message = "No current prayer determined yet. Open \(AppIdentifiers.appName) to refresh prayer times."
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct NextPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Prayer"
    static var description = IntentDescription("Tell me the next prayer (name and time).")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let settings = Settings.shared
        settings.fetchPrayerTimes()

        if let nextPrayer = settings.nextPrayer {
            let message = settings.prayerTimeMessage(prefix: "Next prayer", prayer: nextPrayer)
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }

        if let prayers = settings.todayFullPrayerList(),
           let prayer = prayers.first(where: { $0.time > Date() }) {
            let message = settings.prayerTimeMessage(prefix: "Next prayer", prayer: prayer)
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }

        let message = "No upcoming prayer found. Open \(AppIdentifiers.appName) to refresh prayer times."
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}
