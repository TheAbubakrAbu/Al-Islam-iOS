import AppIntents

/// A surah as an App Intents entity so Siri can resolve a spoken/typed name or number both in-phrase
/// ("play surah Al-Fatihah") and via the ask-back flow ("play surah" → "Which surah?").
@available(iOS 16.0, watchOS 9.0, *)
struct SurahEntity: AppEntity, Identifiable {
    let id: Int
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Surah" }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(id). \(name)") }
    static var defaultQuery = SurahEntityQuery()
}

@available(iOS 16.0, watchOS 9.0, *)
struct SurahEntityQuery: EntityQuery, EntityStringQuery {
    private func entity(_ surah: Surah) -> SurahEntity { SurahEntity(id: surah.id, name: surah.nameTransliteration) }

    /// Siri can invoke these on a COLD launch, before the background Quran load has populated
    /// `quran` - resolving against the empty array made the spoken surah "not found". Wait for the
    /// core load (it has its own escape hatches, and Siri's own timeout bounds the worst case).
    private func loadedSurahs() async -> [Surah] {
        await QuranData.shared.waitUntilCoreLoaded()
        return await MainActor.run { QuranData.shared.quran }
    }

    func entities(for identifiers: [Int]) async throws -> [SurahEntity] {
        await loadedSurahs().filter { identifiers.contains($0.id) }.map(entity)
    }

    func suggestedEntities() async throws -> [SurahEntity] {
        await loadedSurahs().map(entity)
    }

    /// Resolves a spoken/typed string (a name, alias, or number) to matching surahs.
    func entities(matching string: String) async throws -> [SurahEntity] {
        let normalized = string.normalizedSurahIntentQuery
        let all = await loadedSurahs()
        guard !normalized.isEmpty else { return all.map(entity) }

        if let number = Int(normalized), (1...114).contains(number) {
            return all.filter { $0.id == number }.map(entity)
        }
        return all.filter { surah in
            surah.normalizedSearchNames.contains { $0.contains(normalized) }
        }.map(entity)
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct PlaySurahAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Surah"
    static var description = IntentDescription("Play a specific surah by name or number.")
    static var openAppWhenRun = true
    static var parameterSummary: some ParameterSummary { Summary("Play \(\.$surah)") }

    @Parameter(
        title: "Surah",
        requestValueDialog: IntentDialog("Which surah would you like to play? You can say a name or a number.")
    )
    var surah: SurahEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let didStart = await QuranPlaybackRouter.play(surahID: surah.id, name: surah.name)
        return .result(dialog: didStart
            ? IntentDialog("Playing Surah \(surah.id): \(surah.name).")
            : IntentDialog("Sorry, there was a problem starting playback."))
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct PlayRandomSurahAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Random Surah"
    static var description = IntentDescription("Play a random surah.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let result = await QuranPlaybackRouter.playRandom() else {
            return .result(dialog: "Sorry, I couldn’t choose a surah right now.")
        }

        return .result(dialog: result.ok
            ? IntentDialog("Playing Surah \(result.id): \(result.name).")
            : IntentDialog("Sorry, there was a problem starting playback."))
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct PlayLastListenedSurahAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Last Listened Surah"
    static var description = IntentDescription("Play the last surah you listened to.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let result = await QuranPlaybackRouter.playLast() else {
            return .result(dialog: "Sorry, I don’t have a last listened surah yet.")
        }

        return .result(dialog: result.ok
            ? IntentDialog("Playing Surah \(result.id): \(result.name).")
            : IntentDialog("Sorry, there was a problem starting playback."))
    }
}

enum QuranPlaybackRouter {
    private static let data = QuranData.shared
    private static let player = QuranPlayer.shared
    private static let settings = Settings.shared

    @MainActor
    private static func confirmStart(
        surahID: Int,
        timeout: UInt64 = 4_000_000_000,
        interval: UInt64 = 100_000_000
    ) async -> Bool {
        if player.isPlaying, player.currentSurahNumber == surahID {
            return true
        }

        var waited: UInt64 = 0
        while waited < timeout {
            try? await Task.sleep(nanoseconds: interval)
            waited += interval

            if player.isPlaying, player.currentSurahNumber == surahID {
                return true
            }

            if (player.player?.rate ?? 0) > 0, player.currentSurahNumber == surahID {
                return true
            }
        }

        // Timed out without a PRESENTED failure: a cold launch + network stream routinely outlasts
        // this window, and Siri saying "there was a problem" while the surah starts moments later is
        // a false failure. Only an actual surfaced playback error reports as one.
        return !player.showInternetAlert
    }

    @MainActor
    static func play(surahID: Int, name: String) async -> Bool {
        player.playSurah(surahNumber: surahID, surahName: name)
        return await confirmStart(surahID: surahID)
    }

    @MainActor
    static func playLast() async -> (id: Int, name: String, ok: Bool)? {
        guard
            let last = settings.lastListenedSurah,
            let surah = data.quran.first(where: { $0.id == last.surahNumber })
        else {
            return nil
        }

        player.playSurah(
            surahNumber: surah.id,
            surahName: surah.nameTransliteration,
            certainReciter: true
        )

        let didStart = await confirmStart(surahID: surah.id)
        return (surah.id, surah.nameTransliteration, didStart)
    }

    @MainActor
    static func playRandom() async -> (id: Int, name: String, ok: Bool)? {
        guard let surah = data.quran.randomElement() else {
            return nil
        }

        player.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
        let didStart = await confirmStart(surahID: surah.id)
        return (surah.id, surah.nameTransliteration, didStart)
    }

    static func matchedSurah(for normalizedQuery: String) -> Surah? {
        if let number = Int(normalizedQuery), (1...114).contains(number) {
            return data.quran.first(where: { $0.id == number })
        }

        return data.quran.first(where: { surah in
            surah.normalizedSearchNames.contains { $0.contains(normalizedQuery) }
        })
    }
}

