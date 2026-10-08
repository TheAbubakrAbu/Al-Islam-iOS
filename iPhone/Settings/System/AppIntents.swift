import AppIntents

@available(iOS 16.0, watchOS 9.0, *)
struct AppShortcutsRoot: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
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
                "شغّل سورة \(\.$surah) في \(.applicationName)",
                "اقرأ سورة \(\.$surah) في \(.applicationName)",
                // Ask-back ("play surah" → Siri asks which one)
                "Play a surah in \(.applicationName)",
                "Recite a surah in \(.applicationName)",
                "Play surah in \(.applicationName)",
                "Recite surah in \(.applicationName)",
                "\(.applicationName), play a surah",
                "\(.applicationName), recite a surah",
                "\(.applicationName), play surah",
                "\(.applicationName), recite surah",
                "شغّل سورة في \(.applicationName)",
                "اقرأ سورة في \(.applicationName)",
            ],
            shortTitle: "Play Surah",
            systemImageName: "book"
        )

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
                "شغّل سورة عشوائية في \(.applicationName)",
                "اقرأ سورة عشوائية في \(.applicationName)",
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
                "شغّل آخر سورة تم الاستماع إليها في \(.applicationName)",
                "اقرأ آخر سورة تم الاستماع إليها في \(.applicationName)",
            ],
            shortTitle: "Last Listened Surah",
            systemImageName: "gobackward"
        )

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
                "وقت \(\.$prayer) في \(.applicationName)",
                "متى \(\.$prayer) في \(.applicationName)",
                "ما وقت \(\.$prayer) في \(.applicationName)",
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
                "ما هي الصلاة الحالية في \(.applicationName)",
                "ما هي الصلاة الآن في \(.applicationName)",
                "ما الصلاة الآن في \(.applicationName)",
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
                "ما هي الصلاة القادمة في \(.applicationName)",
                "متى الصلاة القادمة في \(.applicationName)",
                "ما وقت الصلاة القادمة في \(.applicationName)",
                "وقت الصلاة القادمة في \(.applicationName)",
            ],
            shortTitle: "Next Prayer",
            systemImageName: "forward.end"
        )
    }
}
