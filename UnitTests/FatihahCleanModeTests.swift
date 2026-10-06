import XCTest
@testable import iPhone

/// Al-Fatihah 1:1 in clean mode (Hide Tashkeel): only a ta'awwudh gives way to the basmala.
final class FatihahCleanModeTests: XCTestCase {

    // Vocalized texts, written as scalars so the file stays plain.
    /// بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ
    private let basmala = "\u{0628}\u{0650}\u{0633}\u{06E1}\u{0645}\u{0650} \u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650} \u{0671}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{06E1}\u{0645}\u{064E}\u{0670}\u{0646}\u{0650} \u{0671}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0650}\u{064A}\u{0645}\u{0650}"
    /// اِ۬لۡحَمۡدُ لِلهِ رَبِّ اِ۬لۡعَٰلَمِينَ (Warsh's 1:1)
    private let alHamd = "\u{0627}\u{0650}\u{06EC}\u{0644}\u{06E1}\u{062D}\u{064E}\u{0645}\u{06E1}\u{062F}\u{064F} \u{0644}\u{0650}\u{0644}\u{0647}\u{0650} \u{0631}\u{064E}\u{0628}\u{0651}\u{0650} \u{0627}\u{0650}\u{06EC}\u{0644}\u{06E1}\u{0639}\u{064E}\u{0670}\u{0644}\u{064E}\u{0645}\u{0650}\u{064A}\u{0646}\u{064E}"
    /// أَعُوذُ بِٱللَّهِ مِنَ ٱلشَّيۡطَٰنِ ٱلرَّجِيمِ
    private let taawwudh = "\u{0623}\u{064E}\u{0639}\u{064F}\u{0648}\u{0630}\u{064F} \u{0628}\u{0650}\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650} \u{0645}\u{0650}\u{0646}\u{064E} \u{0671}\u{0644}\u{0634}\u{0651}\u{064E}\u{064A}\u{06E1}\u{0637}\u{064E}\u{0670}\u{0646}\u{0650} \u{0671}\u{0644}\u{0631}\u{0651}\u{064E}\u{062C}\u{0650}\u{064A}\u{0645}\u{0650}"

    /// An al-Fatihah 1:1 with Hafs's basmala, Warsh's al-hamd, and a ta'awwudh standing in as Qalun's text.
    private func fatihahOne() -> Ayah {
        Ayah(id: 1, idArabic: "\u{0661}", textHafs: basmala, textTransliteration: "", textEnglishSaheeh: "",
             textEnglishMustafa: "", juz: 1, page: 1, textWarsh: alHamd, textQaloon: taawwudh,
             textDuri: nil, textBuzzi: nil, textQunbul: nil, textShubah: nil, textSusi: nil)
    }

    /// A3: the ta'awwudh test reads the raw text, with or without marks, and nothing else.
    func testOpensWithTaawwudh() {
        XCTAssertTrue(Ayah.opensWithTaawwudh(taawwudh))
        XCTAssertTrue(Ayah.opensWithTaawwudh("\u{0627}\u{0639}\u{0648}\u{0630} \u{0628}\u{0627}\u{0644}\u{0644}\u{0647}"))  // اعوذ بالله
        XCTAssertTrue(Ayah.opensWithTaawwudh("  " + taawwudh))
        XCTAssertFalse(Ayah.opensWithTaawwudh(basmala))
        XCTAssertFalse(Ayah.opensWithTaawwudh(alHamd))
        XCTAssertFalse(Ayah.opensWithTaawwudh(basmala.removingArabicDots))
        XCTAssertFalse(Ayah.opensWithTaawwudh(""))
    }

    /// A3: a riwayah whose 1:1 is al-hamd keeps it in clean mode, dots shown or hidden.
    func testAlHamdIsNotReplacedByTheBasmala() {
        let ayah = fatihahOne()
        for removeDots in [false, true] {
            let shown = ayah.displayArabicText(surahId: 1, clean: true, removeDots: removeDots, qiraahOverride: Settings.Riwayah.warsh)
            XCTAssertEqual(shown, ayah.textCleanArabic(for: Settings.Riwayah.warsh, surahID: 1, removeDots: removeDots))
            XCTAssertTrue(shown.hasPrefix("\u{0627}\u{0644}\u{062D}\u{0645}\u{062F}"), "removeDots \(removeDots): \(shown)")  // الحمد
            XCTAssertNotEqual(shown, Ayah.bismillahCleanArabic)
        }
    }

    /// A3: Hafs with dots hidden shows its own dotless basmala, not the dotted one.
    func testHafsDotlessBasmalaStaysDotless() {
        let ayah = fatihahOne()
        let shown = ayah.displayArabicText(surahId: 1, clean: true, removeDots: true, qiraahOverride: "")
        XCTAssertEqual(shown, ayah.textCleanArabic(for: nil, removeDots: true))
        XCTAssertTrue(shown.hasPrefix("\u{066E}\u{0633}\u{0645}"), shown)   // ٮسم
        XCTAssertFalse(shown.unicodeScalars.contains { $0.value == 0x0628 }, shown)
    }

    /// A3: a 1:1 that opens with the ta'awwudh is the one case that shows the basmala, dotless when dots are hidden.
    func testTaawwudhGivesWayToTheBasmala() {
        let ayah = fatihahOne()
        XCTAssertEqual(ayah.displayArabicText(surahId: 1, clean: true, removeDots: false, qiraahOverride: Settings.Riwayah.qaloon),
                       Ayah.bismillahCleanArabic)
        XCTAssertEqual(ayah.displayArabicText(surahId: 1, clean: true, removeDots: true, qiraahOverride: Settings.Riwayah.qaloon),
                       Ayah.bismillahCleanArabic.removingArabicDots)
    }

    /// A3: the swap is clean mode and al-Fatihah 1:1 only.
    func testSwapNeedsCleanModeAndFatihah() {
        let ayah = fatihahOne()
        XCTAssertEqual(ayah.displayArabicText(surahId: 1, clean: false, removeDots: false, qiraahOverride: Settings.Riwayah.qaloon),
                       taawwudh)
        XCTAssertNotEqual(ayah.displayArabicText(surahId: 2, clean: true, removeDots: false, qiraahOverride: Settings.Riwayah.qaloon),
                          Ayah.bismillahCleanArabic)
    }

    /// A3: with the shipped texts, every bundled riwayah's 1:1 in clean mode is its own ayah (or the basmala after a ta'awwudh).
    @MainActor
    func testShippedRiwayatKeepTheirFirstAyah() async throws {
        let data = QuranData.shared

        // The overlay riwayah columns are SKIPPED at load unless the user shows qiraah details or has
        // a non-Hafs display selected (`loadAttempt`'s `includeQiraat`, a launch-speed optimization).
        // Without this the test read Hafs-only ayahs: every `textWarsh`/`textQaloon`/... was nil, so
        // `numberOfAyahs(for:)` counted 0 for all seven and Warsh's 1:1 fell back to the basmala.
        //
        // It used to "pass" only because a previous run had left `displayQiraah` in the simulator's
        // defaults; clearing them (which the UnitTests run does) made it fail. The precondition is
        // the test's own job, so set it here and restore it afterwards.
        let settings = Settings.shared
        let previousShowQiraah = settings.showQiraahDetails
        settings.showQiraahDetails = true

        await data.waitUntilLoaded()

        // The first load may have finished before the flag was set, in which case it holds Hafs-only
        // ayahs. Re-merge WITH the overlays. `waitUntilLoaded()` cannot be used to wait for this one:
        // it returns at once while `loadState` is still `.ready` from the first pass, so wait on the
        // observable OUTCOME instead - Warsh's text arriving on al-Fatihah's first ayah.
        if data.surah(1)?.ayahs.first?.textWarsh == nil {
            data.reloadForQiraahAvailabilityChange()
            let deadline = Date().addingTimeInterval(20)
            while data.surah(1)?.ayahs.first?.textWarsh == nil, Date() < deadline {
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        }
        try XCTSkipIf(data.surah(1)?.ayahs.first?.textWarsh == nil,
                      "Qiraat overlays unavailable in this build; nothing to check.")

        let surah = try XCTUnwrap(data.surah(1))
        let first = try XCTUnwrap(surah.ayahs.first)
        let tags = [Settings.Riwayah.hafsTag, Settings.Riwayah.warsh, Settings.Riwayah.qaloon, Settings.Riwayah.duri,
                    Settings.Riwayah.buzzi, Settings.Riwayah.qunbul, Settings.Riwayah.shubah, Settings.Riwayah.susi]
        for tag in tags {
            let qiraah: String? = tag.isEmpty ? nil : tag
            let raw = first.textArabic(for: qiraah, surahID: 1)
            for removeDots in [false, true] {
                let shown = first.displayArabicText(surahId: 1, clean: true, removeDots: removeDots, qiraahOverride: tag)
                let expected = Ayah.opensWithTaawwudh(raw)
                    ? (removeDots ? Ayah.bismillahCleanArabic.removingArabicDots : Ayah.bismillahCleanArabic)
                    : first.textCleanArabic(for: qiraah, surahID: 1, removeDots: removeDots)
                XCTAssertEqual(shown, expected, "\(tag.isEmpty ? "Hafs" : tag) removeDots \(removeDots)")
            }
            XCTAssertEqual(surah.numberOfAyahs(for: qiraah), 7, tag.isEmpty ? "Hafs" : tag)
        }
        // Warsh counts al-hamd as 1:1; clean mode must show it, not a second basmala.
        let warsh = first.displayArabicText(surahId: 1, clean: true, removeDots: false, qiraahOverride: Settings.Riwayah.warsh)
        XCTAssertTrue(warsh.hasPrefix("\u{0627}\u{0644}\u{062D}\u{0645}\u{062F}"), warsh)

        // Put the setting back, then re-merge WITHOUT the overlays and wait for that to land, so the
        // store the next test sees is the one it would have seen had this test never run. Both halves
        // matter: leaving the flag set changes later behaviour, and leaving the reload in flight
        // republishes the whole Quran underneath whichever test is already running.
        settings.showQiraahDetails = previousShowQiraah
        if previousShowQiraah != true {
            data.reloadForQiraahAvailabilityChange()
            let settle = Date().addingTimeInterval(10)
            while data.surah(1)?.ayahs.first?.textWarsh != nil, Date() < settle {
                try await Task.sleep(nanoseconds: 20_000_000)
            }
        }
    }
}
