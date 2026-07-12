import AVFoundation

/// Speaks Arabic aloud with the system voice.
///
/// The alphabet screens have no recorded audio, so the names of the tashkeel marks and the syllables they make
/// are synthesized instead. That is the whole point of using speech synthesis here: a mark plus a letter is a
/// combination, not a fixed asset, so there are far too many of them (24 marks × 30 letters) to record.
///
/// Speaking is best-effort. If the device has no Arabic voice installed, `speak` quietly does nothing rather than
/// falling back to an English voice, which would mispronounce every word it was given.
@MainActor
final class ArabicSpeech {
    static let shared = ArabicSpeech()

    private let synthesizer = AVSpeechSynthesizer()

    /// Arabic voices are identified by an `ar-SA` language code. Resolved once: enumerating every installed voice
    /// on each tap is needless work on a screen where taps come in bursts.
    private lazy var arabicVoice: AVSpeechSynthesisVoice? = {
        AVSpeechSynthesisVoice(language: "ar-SA")
            ?? AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("ar") }
    }()

    private init() {}

    var isAvailable: Bool { arabicVoice != nil }

    /// Speaks `text` in Arabic, cutting off whatever was already being spoken. Tapping through the marks quickly
    /// should say the mark you last tapped, not queue up a backlog of every one you passed.
    func speak(_ text: String, rate: Float = 0.35) {
        guard let arabicVoice, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        #if os(iOS)
        // .duckOthers so a recitation playing in the background dips rather than being stopped outright, and
        // .playback so this is still audible with the ringer switch flipped to silent.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = arabicVoice
        // Slower than conversational: this is being used to learn a sound, not to listen to a sentence.
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }
}
