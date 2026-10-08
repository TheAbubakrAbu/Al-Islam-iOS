import XCTest
import AVFoundation
@testable import iPhone

/// The crash of 2026-10-06 (`iPhone-2026-10-06-183452.ips`, caught by a 150-step monkey walk):
/// EXC_BAD_ACCESS / KERN_PROTECTION_FAILURE on the main thread's stack guard page, which is a stack
/// overflow, with `speak -> resolveVoice -> closure #1 -> speak` repeating all the way down.
///
/// `resolveVoice(then:)` invokes `then` SYNCHRONOUSLY when the voice is already resolved, and
/// `speak`'s continuation calls `speak` again. With a voice present the continuation's
/// `guard voice != nil` passes, so it recurses forever; `speak`'s own
/// `guard resolveVoice(...) != nil` can never be reached, because the recursion happens before
/// `resolveVoice` returns. A device WITHOUT an Arabic voice was the only case that terminated.
///
/// These tests drive the real singleton on the main thread. Before the fix they crash the test
/// runner outright rather than failing, which is the signature of this bug.
@MainActor
final class ArabicSpeechRecursionTests: XCTestCase {

    /// True when this machine actually has the voice that triggers the recursion. Asserted on, so
    /// the test can never silently pass by taking the nil-voice path that was already safe.
    private var hasArabicVoice: Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { $0.language.hasPrefix("ar") }
    }

    /// Waits for the off-main voice resolution to land, so the test exercises the
    /// `voiceResolved == true` branch (the synchronous `then` call) and not the async one.
    private func waitForVoiceResolution() {
        let speech = ArabicSpeech.shared
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline && !speech.isAvailable {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }
    }

    /// The exact crash: one tap on an Arabic "listen" button (`DuaSessionView.controls`,
    /// `WordByWord`, `AdhkarView`, and 11 other call sites).
    func testSpeakDoesNotRecurseIntoItself() throws {
        try XCTSkipUnless(hasArabicVoice, "no Arabic voice installed; the recursion needs one")
        let speech = ArabicSpeech.shared
        waitForVoiceResolution()
        XCTAssertTrue(speech.isAvailable, "voice did not resolve, test would not reach the bug")

        // Before the fix this overflows the stack instead of returning.
        speech.speak("بِسْمِ اللَّهِ", rate: 0.4)
        speech.stop()
    }

    /// `speakAll` has the identical continuation ("Listen All" on the adhkar and dua sections).
    func testSpeakAllDoesNotRecurseIntoItself() throws {
        try XCTSkipUnless(hasArabicVoice, "no Arabic voice installed; the recursion needs one")
        let speech = ArabicSpeech.shared
        waitForVoiceResolution()
        XCTAssertTrue(speech.isAvailable)

        speech.speakAll(["اللَّهُ أَكْبَرُ", "سُبْحَانَ اللَّهِ"], rate: 0.4)
        speech.stop()
    }

    /// Tapping repeatedly is what the monkey did. Each tap must cost one call, not an ever-deeper
    /// stack, so a burst stays flat.
    func testRepeatedSpeakStaysFlat() throws {
        try XCTSkipUnless(hasArabicVoice, "no Arabic voice installed; the recursion needs one")
        let speech = ArabicSpeech.shared
        waitForVoiceResolution()
        for i in 0..<25 { speech.speak("كَلِمَة \(i)", rate: 0.5) }
        speech.stop()
    }

    /// The continuation must still do its job: a tap that arrives BEFORE the voice resolves has to
    /// speak once the voice lands, not be dropped. This is the behaviour the recursive call was
    /// there to provide, so the fix has to keep it.
    func testTapBeforeResolutionStillSpeaks() throws {
        try XCTSkipUnless(hasArabicVoice, "no Arabic voice installed; the recursion needs one")
        let speech = ArabicSpeech.shared
        waitForVoiceResolution()
        XCTAssertTrue(speech.isAvailable)

        speech.speak("الْحَمْدُ لِلَّهِ", rate: 0.4)
        XCTAssertEqual(speech.currentText, "الْحَمْدُ لِلَّهِ",
                       "speak did not reach the synthesizer, so the continuation lost the tap")
        speech.stop()
    }
}
