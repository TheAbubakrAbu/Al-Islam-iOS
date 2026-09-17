import Foundation

/// Where an article's `ScriptureQuote(quran:)` gets its words: the Quran this app ships, through
/// `QuranData`, in the reader's own translation choice. (Al-Adhan, which ships no Quran text, has
/// its own `QuranQuoteSource` over a small pack derived from the same text at build time.)
enum QuranQuoteSource {
    /// The cited ayahs' Hafs text and translation, or nil while the Quran is still loading.
    static func resolve(_ reference: QuranQuoteReference) -> QuranQuoteText? {
        let data = QuranData.shared
        let settings = Settings.shared
        // The reader's translation, the same rule the Similar Ayahs sheet applies.
        let saheeh = settings.showEnglishSaheeh || !settings.showEnglishMustafa
        var arabic: [String] = []
        var english: [String] = []
        for number in reference.ayahs {
            guard let ayah = data.ayah(surah: reference.surah, ayah: number) else { return nil }
            // Hafs, whatever riwayah the reader is on: the articles quote the mushaf's Hafs text.
            arabic.append(ayah.displayArabicText(surahId: reference.surah, clean: false, qiraahOverride: ""))
            english.append(saheeh ? ayah.textEnglishSaheeh : ayah.textEnglishMustafa)
        }
        return QuranQuoteText(arabic: arabic.joined(separator: " "), english: english.joined(separator: " "))
    }

    /// Resolves once the Quran has loaded (an article opened in the first moments of a cold launch).
    static func waitUntilReady() async {
        await QuranData.shared.waitUntilLoaded()
    }
}
