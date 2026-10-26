import AppIntents

@available(iOS 16.0, watchOS 9.0, *)
/// The phrases below are the English ones. Every other language's phrases are their translations in
/// Resources/<language>.lproj/AppShortcuts.strings, one per English phrase (`${applicationName}`, `${surah}`
/// and `${prayer}` stand for the app's name and the spoken parameter): an Arabic phrase written here would
/// only be one more ENGLISH phrase to Siri. A .strings file because AppShortcuts.xcstrings needs iOS 17.
struct AppShortcutsRoot: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        #if HAS_QURAN
        AppShortcut(
            intent: PlaySurahAppIntent(),
            phrases: [
                // In-phrase surah ("play surah Al-Fatihah in <app>")
                "Play surah \(\.$surah) in \(.applicationName)",
                "Recite surah \(\.$surah) in \(.applicationName)",
                "Play \(\.$surah) in \(.applicationName)",
                "\(.applicationName), play surah \(\.$surah)",
                "\(.applicationName), recite surah \(\.$surah)",
                "\(.applicationName), play \(\.$surah)",
                // Ask-back ("play surah" → Siri asks which one)
                "Play a surah in \(.applicationName)",
                "Recite a surah in \(.applicationName)",
                "Play surah in \(.applicationName)",
                "Recite surah in \(.applicationName)",
                "\(.applicationName), play a surah",
                "\(.applicationName), recite a surah",
                "\(.applicationName), play surah",
                "\(.applicationName), recite surah",
            ],
            shortTitle: "Play Surah",
            systemImageName: "book"
        )

        #if os(iOS)
        AppShortcut(
            intent: OpenSurahAppIntent(),
            phrases: [
                // In-phrase surah ("open surah Al-Mulk in <app>")
                "Open surah \(\.$surah) in \(.applicationName)",
                "Read surah \(\.$surah) in \(.applicationName)",
                "Open \(\.$surah) in \(.applicationName)",
                "Show surah \(\.$surah) in \(.applicationName)",
                "\(.applicationName), open surah \(\.$surah)",
                "\(.applicationName), read surah \(\.$surah)",
                "\(.applicationName), open \(\.$surah)",
                // Ask-back ("open surah" → Siri asks which one)
                "Open a surah in \(.applicationName)",
                "Read a surah in \(.applicationName)",
                "Open surah in \(.applicationName)",
                "\(.applicationName), open a surah",
                "\(.applicationName), open surah",
            ],
            shortTitle: "Open Surah",
            systemImageName: "text.book.closed"
        )

        AppShortcut(
            intent: OpenSurahInListModeAppIntent(),
            phrases: [
                "Open surah \(\.$surah) in list mode in \(.applicationName)",
                "Read surah \(\.$surah) in list mode in \(.applicationName)",
                "\(.applicationName), open surah \(\.$surah) in list mode",
                "\(.applicationName), read surah \(\.$surah) in list mode"
            ],
            shortTitle: "Open Surah in List Mode",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: OpenSurahInPageModeAppIntent(),
            phrases: [
                "Open surah \(\.$surah) in page mode in \(.applicationName)",
                "Read surah \(\.$surah) in page mode in \(.applicationName)",
                "\(.applicationName), open surah \(\.$surah) in page mode",
                "\(.applicationName), read surah \(\.$surah) in page mode"
            ],
            shortTitle: "Open Surah in Page Mode",
            systemImageName: "book.fill"
        )
        #endif

        AppShortcut(
            intent: PlayRandomSurahAppIntent(),
            phrases: [
                "Play random surah in \(.applicationName)",
                "Recite random surah in \(.applicationName)",
                "Play random in \(.applicationName)",
                "Recite random in \(.applicationName)",
                "\(.applicationName), play a random surah",
                "\(.applicationName), recite a random surah",
                "\(.applicationName), play random surah",
                "\(.applicationName), recite random surah",
                "\(.applicationName), play random",
                "\(.applicationName), recite random",
            ],
            shortTitle: "Random Surah",
            systemImageName: "shuffle"
        )

        AppShortcut(
            intent: PlayLastListenedSurahAppIntent(),
            phrases: [
                "Play last listened surah in \(.applicationName)",
                "Recite last listened surah in \(.applicationName)",
                "Play last listened in \(.applicationName)",
                "Recite last listened in \(.applicationName)",
                "Play last in \(.applicationName)",
                "Recite last in \(.applicationName)",
                "Play last surah in \(.applicationName)",
                "Recite last surah in \(.applicationName)",
                "Play where I last left off in \(.applicationName)",
                "Recite where I last left off in \(.applicationName)",
                "\(.applicationName), play last listened surah",
                "\(.applicationName), recite last listened surah",
                "\(.applicationName), play last listened",
                "\(.applicationName), recite last listened",
                "\(.applicationName), play last",
                "\(.applicationName), recite last",
                "\(.applicationName), play last surah",
                "\(.applicationName), recite last surah",
                "\(.applicationName), play where I last left off",
                "\(.applicationName), recite where I last left off",
            ],
            shortTitle: "Last Listened Surah",
            systemImageName: "gobackward"
        )
        #endif

        #if HAS_ADHAN
        AppShortcut(
            intent: WhenIsPrayerIntent(),
            phrases: [
                "When is \(\.$prayer) in \(.applicationName)",
                "When is \(\.$prayer) prayer in \(.applicationName)",
                "What time is \(\.$prayer) in \(.applicationName)",
                "What time is \(\.$prayer) prayer in \(.applicationName)",
                "What is the time for \(\.$prayer) in \(.applicationName)",
                "What is the time for \(\.$prayer) prayer in \(.applicationName)",
                "When does \(\.$prayer) start in \(.applicationName)",
                "When does \(\.$prayer) prayer start in \(.applicationName)",
                "Time for \(\.$prayer) in \(.applicationName)",
                "Time for \(\.$prayer) prayer in \(.applicationName)",
                "Prayer time for \(\.$prayer) in \(.applicationName)",
                "Prayer time for \(\.$prayer) prayer in \(.applicationName)",
            ],
            shortTitle: "When is Prayer",
            systemImageName: "clock"
        )

        AppShortcut(
            intent: CurrentPrayerIntent(),
            phrases: [
                "What is the current prayer in \(.applicationName)",
                "Current prayer in \(.applicationName)",
                "What prayer is it now in \(.applicationName)",
                "Which prayer is now in \(.applicationName)",
                "What prayer time is it in \(.applicationName)",
            ],
            shortTitle: "Current Prayer",
            systemImageName: "clock.badge.checkmark"
        )

        AppShortcut(
            intent: NextPrayerIntent(),
            phrases: [
                "What is the next prayer in \(.applicationName)",
                "When is the next prayer in \(.applicationName)",
                "What is the next prayer time in \(.applicationName)",
                "When is the next prayer time in \(.applicationName)",
                "Next prayer in \(.applicationName)",
                "Next prayer time in \(.applicationName)",
                "Time of the next prayer in \(.applicationName)",
                "Which prayer is next in \(.applicationName)",
            ],
            shortTitle: "Next Prayer",
            systemImageName: "forward.end"
        )
        #endif
    }
}
