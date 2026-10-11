import XCTest
@testable import iPhone

/// Test Mode's rules (`QuranTestMode`): what a tap shows under each Show setting, that the recitation
/// shows and never hides, what each Hide setting veils in a list row and on a mushaf page, and when
/// Test Mode turns itself off. The store is the app's shared one, so every test starts it off and puts
/// the four settings back afterwards.
@MainActor
final class QuranTestModeTests: XCTestCase {
    private let settings = Settings.shared
    private var mode: QuranTestMode { .shared }
    private var saved: (hides: String, reveals: String, recited: Bool, endsOnLeave: Bool, storedOn: Bool)
        = ("", "", true, true, false)

    override func setUp() async throws {
        try await super.setUp()
        saved = (settings.quranTestModeHides, settings.quranTestModeReveals,
                 settings.quranTestModeRevealsRecited, settings.quranTestModeEndsOnLeave,
                 settings.quranTestModeStoredOn)
        settings.quranTestModeHides = QuranTestHiding.recitation.rawValue
        settings.quranTestModeReveals = QuranTestReveal.selected.rawValue
        settings.quranTestModeRevealsRecited = true
        settings.quranTestModeEndsOnLeave = true
        mode.setOn(false)
    }

    override func tearDown() async throws {
        mode.setOn(false)
        settings.quranTestModeHides = saved.hides
        settings.quranTestModeReveals = saved.reveals
        settings.quranTestModeRevealsRecited = saved.recited
        settings.quranTestModeEndsOnLeave = saved.endsOnLeave
        settings.quranTestModeStoredOn = saved.storedOn
        try await super.tearDown()
    }

    func testOffHidesNothing() {
        XCTAssertFalse(mode.isHidden(surah: 112, ayah: 1))
        XCTAssertNil(mode.veil(surah: 112, ayah: 1))
        mode.select(surah: 112, ayah: 1)
        XCTAssertFalse(mode.hasShownAnything, "A tap with Test Mode off records nothing")
    }

    /// "Only the Selected Ayah": the tapped ayah alone, another tap moves it, the same tap hides it.
    func testSelectedShowsOnlyTheTappedAyah() {
        mode.setOn(true)
        XCTAssertTrue(mode.isHidden(surah: 112, ayah: 1), "Everything starts hidden")

        mode.select(surah: 112, ayah: 2)
        XCTAssertFalse(mode.isHidden(surah: 112, ayah: 2))
        XCTAssertTrue(mode.isHidden(surah: 112, ayah: 1))
        XCTAssertTrue(mode.isHidden(surah: 112, ayah: 3))
        XCTAssertTrue(mode.isHidden(surah: 113, ayah: 2), "The same number in another surah stays hidden")

        mode.select(surah: 112, ayah: 3)
        XCTAssertTrue(mode.isHidden(surah: 112, ayah: 2), "Selecting another ayah hides this one again")
        XCTAssertFalse(mode.isHidden(surah: 112, ayah: 3))

        mode.select(surah: 112, ayah: 3)
        XCTAssertTrue(mode.isHidden(surah: 112, ayah: 3), "Tapping the showing ayah hides it")
    }

    /// "The Selected Ayah and Everything Before It": per surah, and only the LAST shown ayah toggles.
    func testThroughSelectedShowsEverythingBeforeIt() {
        settings.quranTestModeReveals = QuranTestReveal.throughSelected.rawValue
        mode.setOn(true)

        mode.select(surah: 2, ayah: 3)
        for ayah in 1...3 { XCTAssertFalse(mode.isHidden(surah: 2, ayah: ayah), "2:\(ayah)") }
        XCTAssertTrue(mode.isHidden(surah: 2, ayah: 4))
        XCTAssertTrue(mode.isHidden(surah: 3, ayah: 1), "Another surah keeps its own progress")

        mode.select(surah: 2, ayah: 2)
        XCTAssertFalse(mode.isHidden(surah: 2, ayah: 3), "Tapping an earlier shown ayah changes nothing")

        mode.select(surah: 2, ayah: 3)
        XCTAssertTrue(mode.isHidden(surah: 2, ayah: 3), "Tapping the last shown ayah hides it again")
        XCTAssertFalse(mode.isHidden(surah: 2, ayah: 2))

        mode.select(surah: 2, ayah: 2)
        mode.select(surah: 2, ayah: 1)
        XCTAssertTrue(mode.isHidden(surah: 2, ayah: 1), "Stepping back reaches nothing shown at all")
        XCTAssertFalse(mode.hasShownAnything)
    }

    /// "Reveal as It's Recited": the recited ayah shows by the same rule, and the recitation never hides.
    func testRecitationShowsAndNeverHides() {
        mode.setOn(true)
        mode.recited(surah: 112, ayah: 1)
        XCTAssertFalse(mode.isHidden(surah: 112, ayah: 1))
        mode.recited(surah: 112, ayah: 1)
        XCTAssertFalse(mode.isHidden(surah: 112, ayah: 1), "A repeated advance is not a second tap")
        mode.recited(surah: 112, ayah: 2)
        XCTAssertTrue(mode.isHidden(surah: 112, ayah: 1), "Only the Selected Ayah follows the reciter")
        XCTAssertFalse(mode.isHidden(surah: 112, ayah: 2))

        settings.quranTestModeReveals = QuranTestReveal.throughSelected.rawValue
        mode.hideAll()
        mode.recited(surah: 112, ayah: 3)
        mode.recited(surah: 112, ayah: 1)
        XCTAssertFalse(mode.isHidden(surah: 112, ayah: 3), "A recitation stepping back hides nothing")

        settings.quranTestModeRevealsRecited = false
        mode.hideAll()
        mode.recited(surah: 112, ayah: 2)
        XCTAssertTrue(mode.isHidden(surah: 112, ayah: 2), "Off, the recitation shows nothing")
    }

    /// What a list row veils, and what a mushaf page hides, under each Hide setting.
    func testHideSettingDecidesTheVeilAndThePages() {
        mode.setOn(true)
        XCTAssertEqual(mode.veil(surah: 1, ayah: 1), .recitation)
        XCTAssertTrue(mode.hides(pageLanguage: .arabic))
        XCTAssertTrue(mode.hides(pageLanguage: .transliteration), "The transliteration is the recitation")
        XCTAssertFalse(mode.hides(pageLanguage: .saheeh), "Arabic Only keeps the translations as the cue")
        XCTAssertFalse(mode.hides(pageLanguage: .clearQuran))
        XCTAssertFalse(mode.hides(pageLanguage: .pdf), "The printed page cannot hide one ayah")

        settings.quranTestModeHides = QuranTestHiding.everything.rawValue
        XCTAssertEqual(mode.veil(surah: 1, ayah: 1), .everything)
        XCTAssertTrue(mode.hides(pageLanguage: .saheeh))
        XCTAssertTrue(mode.hides(pageLanguage: .clearQuran))
        XCTAssertFalse(mode.hides(pageLanguage: .pdf))

        mode.select(surah: 1, ayah: 1)
        XCTAssertNil(mode.veil(surah: 1, ayah: 1), "A shown ayah has no veil")
    }

    func testTurningOnStartsHidden() {
        mode.setOn(true)
        mode.select(surah: 112, ayah: 1)
        mode.setOn(false)
        mode.setOn(true)
        XCTAssertTrue(mode.isHidden(surah: 112, ayah: 1))
        XCTAssertFalse(mode.hasShownAnything)
    }

    /// "Turn Off When Leaving the Reader" counts readers: it ends with the LAST one, and only when on.
    func testLeavingTheLastReaderTurnsItOff() throws {
        guard mode.openReaders == 0 else {
            throw XCTSkip("A reader is open in the host app; the count would not reach zero here")
        }
        mode.setOn(true)
        mode.readerOpened()
        mode.readerOpened()
        mode.readerClosed()
        XCTAssertTrue(mode.isOn, "A reader opened from another one closing leaves the first one's test")
        mode.readerClosed()
        XCTAssertFalse(mode.isOn)

        settings.quranTestModeEndsOnLeave = false
        mode.setOn(true)
        mode.readerOpened()
        mode.readerClosed()
        XCTAssertTrue(mode.isOn, "Kept on until it is turned off")
    }

    /// The launch-time flag is true only while Test Mode is on AND kept on, so closing a reader under the
    /// default setting writes no defaults (a defaults write republishes Settings in the middle of a pop).
    func testStoredFlagOnlyWhileKeptOn() {
        mode.setOn(true)
        XCTAssertFalse(settings.quranTestModeStoredOn, "Ends on leave: nothing for a launch to restore")

        settings.quranTestModeEndsOnLeave = false
        mode.syncStoredOn()
        XCTAssertTrue(settings.quranTestModeStoredOn, "Kept on: the next launch comes back on")

        mode.setOn(false)
        XCTAssertFalse(settings.quranTestModeStoredOn)

        mode.setOn(true)
        settings.quranTestModeEndsOnLeave = true
        mode.syncStoredOn()
        XCTAssertFalse(settings.quranTestModeStoredOn, "Switching back to ending on leave clears it")
    }
}
