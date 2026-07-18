import AVFoundation
import SwiftUI

/// Speaks Arabic aloud with the system voice.
///
/// The alphabet screens have no recorded audio, so the names of the tashkeel marks and the syllables they make
/// are synthesized instead. That is the whole point of using speech synthesis here: a mark plus a letter is a
/// combination, not a fixed asset, so there are far too many of them (24 marks × 30 letters) to record.
///
/// Speaking is best-effort. If the device has no Arabic voice installed, `speak` quietly does nothing rather than
/// falling back to an English voice, which would mispronounce every word it was given.
@MainActor
final class ArabicSpeech: NSObject, ObservableObject {
    static let shared = ArabicSpeech()

    private let synthesizer = AVSpeechSynthesizer()

    /// True while a "Listen All" queue is playing - drives the header pill's play/stop toggle.
    @Published private(set) var isSpeakingQueue = false

    /// The Arabic text being spoken right now (single tap or queue item), nil when silent. Rows compare
    /// their own text against this to flip Listen -> Stop and to highlight themselves; during Listen All
    /// it advances item by item as the queue moves.
    @Published private(set) var currentText: String?

    /// Arabic voices are identified by an `ar-SA` language code. Resolved once: enumerating every installed voice
    /// on each tap is needless work on a screen where taps come in bursts.
    private lazy var arabicVoice: AVSpeechSynthesisVoice? = {
        AVSpeechSynthesisVoice(language: "ar-SA")
            ?? AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("ar") }
    }()

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    var isAvailable: Bool { arabicVoice != nil }

    private func activateSession() {
        #if os(iOS)
        // .duckOthers so a recitation playing in the background dips rather than being stopped outright, and
        // .playback so this is still audible with the ringer switch flipped to silent.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func utterance(for text: String, rate: Float) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = arabicVoice
        // Slower than conversational: this is being used to learn a sound, not to listen to a sentence.
        utterance.rate = rate
        return utterance
    }

    /// Speaks `text` in Arabic, cutting off whatever was already being spoken. Tapping through the marks quickly
    /// should say the mark you last tapped, not queue up a backlog of every one you passed.
    func speak(_ text: String, rate: Float = 0.35) {
        guard arabicVoice != nil, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        stop()
        activateSession()
        currentText = text
        synthesizer.speak(utterance(for: text, rate: rate))
    }

    /// Speaks every text in order - the "Listen All" button on the adhkar and dua sections. The synthesizer
    /// queues utterances natively, so each item is its own utterance with a breath between them.
    func speakAll(_ texts: [String], rate: Float = 0.4) {
        let cleaned = texts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard arabicVoice != nil, !cleaned.isEmpty else { return }

        stop()
        activateSession()
        isSpeakingQueue = true
        currentText = cleaned.first
        for text in cleaned {
            let item = utterance(for: text, rate: rate)
            item.postUtteranceDelay = 0.7
            synthesizer.speak(item)
        }
    }

    func stop() {
        isSpeakingQueue = false
        currentText = nil
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// The delegate's cue that the queue drained on its own (stop() already clears the flags for manual stops).
    fileprivate func refreshQueueState() {
        if !synthesizer.isSpeaking {
            isSpeakingQueue = false
            currentText = nil
        }
    }

    /// The delegate's cue that the next queued utterance began - moves the highlight to it.
    fileprivate func markSpeaking(_ text: String) {
        if currentText != text {
            currentText = text
        }
    }
}

extension ArabicSpeech: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let text = utterance.speechString
        Task { @MainActor in
            ArabicSpeech.shared.markSpeaking(text)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            ArabicSpeech.shared.refreshQueueState()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            ArabicSpeech.shared.refreshQueueState()
        }
    }
}

/// The "Listen All" pill for section headers: plays every Arabic text in the section in order, and turns
/// into a Stop button while the queue is speaking. Renders nothing when the device has no Arabic voice.
struct ListenAllPill: View {
    @ObservedObject private var speech = ArabicSpeech.shared

    let texts: [String]

    var body: some View {
        if speech.isAvailable {
            HStack(spacing: 4) {
                Image(systemName: speech.isSpeakingQueue ? "stop.fill" : "play.fill")
                Text(speech.isSpeakingQueue ? "Stop" : "Listen All")
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(Settings.shared.accentColor.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .conditionalGlassEffect()
            .onTapGesture {
                Settings.shared.hapticFeedback()
                if speech.isSpeakingQueue {
                    speech.stop()
                } else {
                    speech.speakAll(texts)
                }
            }
            .accessibilityLabel(speech.isSpeakingQueue ? "Stop listening" : "Listen to every item in order")
        }
    }
}
