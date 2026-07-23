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

    /// The BEST Arabic voice installed right now - premium beats enhanced beats the compact default,
    /// and within a tier ar-SA (the register closest to recitation) beats other Arabic locales.
    /// `AVSpeechSynthesisVoice(language: "ar-SA")` returned whatever quality the system defaulted to -
    /// the robotic compact voice - even when the user had downloaded a vastly better Enhanced/Premium
    /// voice. Cached per resolution, re-resolved on each queue START (not per phrase): the user can
    /// download a better voice in Settings mid-session, and the next tap should get it.
    private var arabicVoice: AVSpeechSynthesisVoice?

    private static func bestArabicVoice() -> AVSpeechSynthesisVoice? {
        let arabic = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("ar") }
        guard !arabic.isEmpty else { return nil }

        func qualityRank(_ voice: AVSpeechSynthesisVoice) -> Int {
            if #available(iOS 16.0, watchOS 9.0, *), voice.quality == .premium { return 2 }
            return voice.quality == .enhanced ? 1 : 0
        }
        func localeRank(_ voice: AVSpeechSynthesisVoice) -> Int {
            voice.language == "ar-SA" ? 1 : 0
        }
        return arabic.max { a, b in
            (qualityRank(a), localeRank(a)) < (qualityRank(b), localeRank(b))
        }
    }

    @discardableResult
    private func resolveVoice() -> AVSpeechSynthesisVoice? {
        arabicVoice = Self.bestArabicVoice()
        return arabicVoice
    }

    override private init() {
        super.init()
        synthesizer.delegate = self
        arabicVoice = Self.bestArabicVoice()
    }

    var isAvailable: Bool { arabicVoice != nil }

    /// True when the only installed Arabic voice is the compact default - drives the one-line
    /// "download a better voice" hint on the dua/adhkar screens. Enhanced/Premium voices are a
    /// dramatic quality jump and most users don't know they exist.
    var onlyCompactVoiceAvailable: Bool {
        guard let arabicVoice else { return false }
        if #available(iOS 16.0, watchOS 9.0, *), arabicVoice.quality == .premium { return false }
        return arabicVoice.quality != .enhanced
    }

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

    /// Which full row text each queued phrase-utterance belongs to. Long texts are split into
    /// breath-sized phrases (below), but the row highlight compares against the ROW's full text - the
    /// delegate resolves a phrase back to its owner through this. Cleared on stop and on queue drain
    /// (queued utterances removed by `stopSpeaking` fire no delegate callback).
    private var utteranceOwners: [AVSpeechUtterance: String] = [:]

    // MARK: TTS pronunciation normalization

    /// The system voice reads DISPLAY orthography, and a few Quranic writing conventions defeat it.
    /// This is applied to the SPOKEN string only - the display text and the row-highlight owner keep
    /// the original.
    /// - NFC canonical ordering: sources author shaddah/vowel marks in varying orders, and
    ///   non-canonical sequences are what made shaddahs sound wrong.
    /// - Alef wasla (`ٱ` U+0671, hamzatul wasl): the engine doesn't know the dedicated character -
    ///   a plain alef reads correctly.
    /// - Dagger alif (U+0670): ignored by the engine (رَحمَٰن read short) - spell the long vowel out
    ///   as a real alef, which IS its pronunciation.
    /// - Tatweel: decorative, occasionally spelled out loud.
    /// - Targeted respellings for words the voice mis-stresses even when well-formed.
    nonisolated private static func normalizedForSpeech(_ text: String) -> String {
        var s = text.precomposedStringWithCanonicalMapping
        s = s.replacingOccurrences(of: "\u{0671}", with: "\u{0627}")   // ٱ → ا
        s = s.replacingOccurrences(of: "\u{0670}", with: "\u{0627}")   // dagger alif → full alef
        s = s.replacingOccurrences(of: "\u{0640}", with: "")           // tatweel
        for (written, spoken) in Self.pronunciationFixes {
            s = s.replacingOccurrences(of: written.precomposedStringWithCanonicalMapping, with: spoken)
        }
        return s
    }

    /// Words the voice mangles even in canonical form, replaced with phonetic respellings that make it
    /// say them right. Matched AFTER the wasla/dagger folds above, so one plain-alef key covers every
    /// written variant. Tune here as more offenders are reported.
    nonisolated private static let pronunciationFixes: [(written: String, spoken: String)] = [
        // The vocative lafz al-jalalah: the compressed spelling's implicit long vowel gets dropped or
        // mis-stressed ("alla-huma"). The explicit long-alif respelling reads "Allaahumma".
        ("اللَّهُمَّ", "اَللَّاهُمَّ"),
    ]

    /// Breath-sized phrases, split on Arabic/Latin phrase punctuation. One giant utterance is most of
    /// why long duas sounded bad: the synthesizer flattens prosody across it and never pauses. Phrase
    /// utterances with a short post-utterance breath read far more naturally - and the diacritized
    /// Arabic the app already ships gives the voice its best shot at each one.
    private static let phraseSeparators = CharacterSet(charactersIn: "،؛.…!؟?\n·")

    private static func phrases(of text: String) -> [String] {
        let parts = text.components(separatedBy: phraseSeparators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? [text] : parts
    }

    /// Enqueues one full text as its phrase utterances, all owned by `text` for highlight purposes.
    /// `trailingDelay` is the breath after the LAST phrase (the between-items gap in Listen All).
    /// The SPOKEN string is pronunciation-normalized; `text` (the display original) stays the owner.
    private func enqueue(_ text: String, rate: Float, trailingDelay: TimeInterval) {
        let phrases = Self.phrases(of: Self.normalizedForSpeech(text))
        for (index, phrase) in phrases.enumerated() {
            let item = utterance(for: phrase, rate: rate)
            item.postUtteranceDelay = index == phrases.count - 1 ? trailingDelay : 0.25
            utteranceOwners[item] = text
            synthesizer.speak(item)
        }
    }

    /// Speaks `text` in Arabic, cutting off whatever was already being spoken. Tapping through the marks quickly
    /// should say the mark you last tapped, not queue up a backlog of every one you passed.
    func speak(_ text: String, rate: Float = 0.35) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard resolveVoice() != nil else { return }

        stop()
        activateSession()
        currentText = text
        enqueue(text, rate: rate, trailingDelay: 0)
    }

    /// Speaks every text in order - the "Listen All" button on the adhkar and dua sections. The synthesizer
    /// queues utterances natively, so each item is its own phrase run with a longer breath between items.
    func speakAll(_ texts: [String], rate: Float = 0.4) {
        let cleaned = texts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !cleaned.isEmpty, resolveVoice() != nil else { return }

        stop()
        activateSession()
        isSpeakingQueue = true
        currentText = cleaned.first
        for text in cleaned {
            enqueue(text, rate: rate, trailingDelay: 0.7)
        }
    }

    func stop() {
        isSpeakingQueue = false
        currentText = nil
        utteranceOwners.removeAll()
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// The delegate's cue that the queue drained on its own (stop() already clears the flags for manual
    /// stops - its stopSpeaking lands here too, via didCancel, so the session release below covers both).
    fileprivate func refreshQueueState() {
        if !synthesizer.isSpeaking {
            isSpeakingQueue = false
            currentText = nil
            utteranceOwners.removeAll()
            releaseSessionIfIdle()
        }
    }

    /// Resolves a finished/started phrase back to the full row text it belongs to.
    fileprivate func ownerText(of utterance: AVSpeechUtterance) -> String {
        utteranceOwners[utterance] ?? utterance.speechString
    }

    fileprivate func forgetUtterance(_ utterance: AVSpeechUtterance) {
        utteranceOwners.removeValue(forKey: utterance)
    }

    /// App-installed probe: does long-form playback (the Quran player) still own the shared audio
    /// session when speech goes idle? A HOOK rather than a direct `QuranPlayer` reference so this file
    /// compiles in sibling apps without the Quran module (Al-Adhan, Al-Hadith). `QuranPlayer.init`
    /// installs it; nil (no player in this app, or player never started) means nobody owns the session
    /// and it simply deactivates. Installed once at player startup, read on the main thread.
    nonisolated(unsafe) static var recitationOwnsSession: (() -> Bool)? = nil

    /// Hands the ONE shared audio session back when speech ends. Without this, the `.duckOthers`
    /// activation outlived the speech: a single letter tap left every other app's audio ducked
    /// indefinitely, and the category stayed `.spokenAudio` underneath the Quran player's long-form
    /// playback session.
    private func releaseSessionIfIdle() {
        #if os(iOS)
        guard !synthesizer.isSpeaking else { return }
        if Self.recitationOwnsSession?() == true {
            // This app's recitation still owns audio - restore its category rather than deactivating
            // the session out from under it.
            try? AVAudioSession.sharedInstance().setCategory(.playback)
        } else {
            // Deactivation can block briefly; keep it off the main thread (QuranPlayer.stop's rule).
            DispatchQueue.global(qos: .utility).async {
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
        }
        #endif
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
        Task { @MainActor in
            // The OWNER text, not the phrase: rows highlight by comparing their full text.
            ArabicSpeech.shared.markSpeaking(ArabicSpeech.shared.ownerText(of: utterance))
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            ArabicSpeech.shared.forgetUtterance(utterance)
            ArabicSpeech.shared.refreshQueueState()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            ArabicSpeech.shared.forgetUtterance(utterance)
            ArabicSpeech.shared.refreshQueueState()
        }
    }
}

/// One-line hint shown on the dua/adhkar screens when only the compact (robotic) Arabic voice is
/// installed: the Enhanced/Premium voices are a dramatic quality jump, and almost nobody knows the
/// download exists. Renders nothing once a better voice is installed - or when no Arabic voice exists
/// at all (the Listen buttons are hidden then anyway).
struct SpeechQualityHint: View {
    @ObservedObject private var speech = ArabicSpeech.shared

    var body: some View {
        if speech.isAvailable, speech.onlyCompactVoiceAvailable {
            Label {
                Text("For a much better voice, download an Enhanced Arabic voice in Settings → Accessibility → Spoken Content → Voices → Arabic.")
            } icon: {
                Image(systemName: "waveform.badge.plus")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
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
