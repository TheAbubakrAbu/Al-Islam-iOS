import Foundation
import SwiftUI

// "Ask" - Apple's ON-DEVICE foundation model (the ~3B-parameter LLM behind Apple Intelligence) as
// the app's summarize sheets use it, plus the availability and error helpers every AI surface shares.
// Private, offline, free.
//
// The Ask AI chat has its own engine layer now (Helpers/AskAIEngine.swift): it builds a numbered,
// provenance-marked source list and can run on the device or on Private Cloud Compute. The
// summarize sessions here are the strict opposite of a chat: the given source text is their whole
// world.
//
// Availability: iOS 26+ on an Apple Intelligence device with it enabled. Everywhere else,
// `OnDeviceAsk.isAvailable` is false and the feature simply does not exist in the UI - the word-vector
// AI Search (SemanticSearch.swift) remains the baseline everywhere.

#if os(iOS) && canImport(FoundationModels)
import FoundationModels

enum OnDeviceAsk {
    /// Whether the on-device model can run right now (device eligible + Apple Intelligence enabled +
    /// model assets ready). Checked at render time so enabling Apple Intelligence lights this up
    /// without an app restart.
    /// Cached for a few seconds: `SystemLanguageModel.default.availability` is an XPC-backed query,
    /// and the Islam root, its search, the 99 Names, Adhkar, Dua and Arabic screens each asked it
    /// several times per body (Performance Guide, Phase 6 step 12). Availability only changes on a
    /// model download or a Settings flip, so a short TTL keeps every screen honest.
    static var isAvailable: Bool {
        #if DEBUG
        // "-forceAskAIRow": list Ask AI where Apple Intelligence is missing (a simulator), so the
        // layouts that carry its row and banner can be looked at. The chat itself still cannot run.
        if ProcessInfo.processInfo.arguments.contains("-forceAskAIRow") { return true }
        #endif
        guard #available(iOS 26.0, *) else { return false }
        let now = CFAbsoluteTimeGetCurrent()
        if let cached = availabilityCache, now - cached.at < availabilityTTL { return cached.available }
        var available = false
        if case .available = SystemLanguageModel.default.availability { available = true }
        availabilityCache = (available, now)
        return available
    }

    nonisolated(unsafe) private static var availabilityCache: (available: Bool, at: CFAbsoluteTime)?
    private static let availabilityTTL: CFAbsoluteTime = 5

    /// Whether a failed generation was Apple's safety guardrail - the one failure worth one retry with
    /// the question framed as the educational request it is.
    @available(iOS 26.0, *)
    static func isGuardrail(_ error: Error) -> Bool {
        if case LanguageModelSession.GenerationError.guardrailViolation = error { return true }
        return false
    }

    /// Whether a failed generation ran out of context window - the one error worth retrying leaner.
    @available(iOS 26.0, *)
    static func isContextOverflow(_ error: Error) -> Bool {
        if case LanguageModelSession.GenerationError.exceededContextWindowSize = error { return true }
        return false
    }

    /// What to tell the reader when a generation fails for a reason they can act on. Nil for the
    /// generic case (the caller's own wording applies).
    @available(iOS 26.0, *)
    static func failureMessage(for error: Error) -> String? {
        guard let generationError = error as? LanguageModelSession.GenerationError else { return nil }
        switch generationError {
        case .guardrailViolation:
            return "Apple Intelligence declined to answer this one. Try rephrasing the question, or asking about it in a different way."
        case .unsupportedLanguageOrLocale:
            return "Apple Intelligence can\u{2019}t work in that language yet. Try asking in English."
        case .rateLimited, .concurrentRequests:
            return "Apple Intelligence is busy right now. Try again in a moment."
        case .exceededContextWindowSize:
            return "This text is longer than Apple Intelligence can read in one go on this device."
        default:
            return nil
        }
    }

    // MARK: - Summarize (tafsir / surah info / comparison sheets)

    /// The language a summary and its follow-ups are written in. English is the app's language; Arabic
    /// is offered on the Arabic tafsir editions and surah sources (Abu, 2026-09-05), only when the
    /// on-device model can write it (`supportsArabicOutput`).
    enum SummaryLanguage: String, Sendable {
        case english, arabic

        /// The instruction rule for the language.
        var rule: String {
            switch self {
            case .english:
                return "ALWAYS write in ENGLISH, even when the source text is in Arabic; keep key Arabic terms, transliterated."
            case .arabic:
                return "ALWAYS write in ARABIC (clear Modern Standard Arabic), even when the source text is in English."
            }
        }

        /// The upper-case name the task lines use ("IN ENGLISH").
        var promptName: String { self == .arabic ? "ARABIC" : "ENGLISH" }
    }

    /// Whether the on-device model accepts Arabic at all - reading it in a prompt or writing it.
    /// Apple Intelligence's language list has no Arabic as of iOS 26.0, and the framework rejects a
    /// prompt carrying a substantial unsupported-language passage outright
    /// (`unsupportedLanguageOrLocale`, seen 2026-09-05 with a 3,000-character Arabic tafsir under
    /// 4,600 characters of English, and with the six-edition "summarize all" prompt). So while this
    /// is false every AI entry point leaves its Arabic sources out (the Arabic tafsir editions, the
    /// riwayat readings, Arabic surah-info sources) and offers no Arabic-edition or Arabic-output
    /// summarize buttons. Cached like `isAvailable`: it is read in view bodies.
    static var supportsArabic: Bool {
        guard #available(iOS 26.0, *), isAvailable else { return false }
        let now = CFAbsoluteTimeGetCurrent()
        if let cached = arabicSupportCache, now - cached.at < availabilityTTL { return cached.supported }
        let supported = SystemLanguageModel.default.supportsLocale(Locale(identifier: "ar"))
        arabicSupportCache = (supported, now)
        return supported
    }

    nonisolated(unsafe) private static var arabicSupportCache: (supported: Bool, at: CFAbsoluteTime)?

    /// The rules a SUMMARIZE session is created with: the given source text is the whole world -
    /// summarize it faithfully, answer follow-ups only from it, invent nothing, no rulings. The
    /// language rule comes last (see `SummaryLanguage`).
    private static func summarizeInstructions(_ language: SummaryLanguage) -> String {
        summarizeInstructionsBase + "\n6. " + language.rule + "\n"
    }

    private static let summarizeInstructionsBase = """
    You are a careful reading assistant inside a Quran and Hadith reading app. You will be given a \
    SOURCE TEXT (a tafsir passage, surah background prose, or a set of translations of one ayah) \
    and asked to summarize it, then possibly to answer follow-up questions about it.

    Rules, in order:
    1. Ground EVERYTHING in the given source text. Summarize faithfully: report only what the text \
    actually says, in your own words, keeping its emphasis and proportions. Never fabricate or \
    extend its content, and cite or reference nothing beyond the text itself.
    2. Never write out the text of a verse or hadith from memory. If the source quotes one, refer \
    to it briefly in your own words rather than reproducing it.
    3. Never issue religious rulings, verdicts, or fatwas. Where the text discusses what is \
    permitted or forbidden, describe only what the text says and note that a qualified scholar \
    should be consulted for personal rulings.
    4. If a question asks about something the source text does not cover, say plainly that this \
    text does not address it. Do not fill the gap from general knowledge.
    5. Write clearly and completely: short paragraphs, plain respectful language, no markdown \
    formatting.
    """

    /// The rules a MULTI-SOURCE summarize session is created with (the "all tafsirs" case): read every
    /// labeled section, Arabic included, write in the asked language, synthesize one picture, and answer
    /// follow-ups from ANY of the sources - naming which one a point comes from when relevant.
    private static func summarizeMultiInstructions(_ language: SummaryLanguage) -> String {
        """
    You are a careful reading assistant inside a Quran and Hadith reading app. You will be given \
    SOURCE TEXTS: several sections, each headed "=== ... ===" naming which tafsir (Quranic \
    commentary) or source it is. Some sections are in English and some in Arabic.

    Rules, in order:
    1. Read ALL the sections, including the Arabic ones, but \(language.rule)
    2. Ground EVERYTHING in the given sections. Synthesize one complete picture from all of them \
    together: report only what the texts actually say, in your own words, keeping their emphasis. \
    Where sources add distinct points, bring them together and name the source when that helps \
    (e.g. "al-Tabari notes..."). Never fabricate or extend their content.
    3. When answering follow-up questions, draw on ANY of the sections, not just one, and name \
    which tafsir a point comes from when relevant.
    4. Never write out the text of a verse or hadith from memory. If a source quotes one, refer to \
    it briefly in your own words rather than reproducing it.
    5. Never issue religious rulings, verdicts, or fatwas. Where the texts discuss what is \
    permitted or forbidden, describe only what they say and note that a qualified scholar should \
    be consulted for personal rulings.
    6. If a question asks about something none of the sections cover, say plainly that these texts \
    do not address it. Do not fill the gap from general knowledge.
    7. Write clearly and completely: short paragraphs, plain respectful language, no markdown \
    formatting.
    """
    }

    /// How much source text a summarize prompt carries. ~6000 characters is a sensible fit for the
    /// on-device model's small context window once instructions, transcript, and answer share it.
    static let summarizeSourceLimit = 6000

    /// The cap for the MULTI-SOURCE case (all tafsirs of an ayah at once): higher, because the whole
    /// point is breadth, but still leaving the small context window room for instructions, the
    /// transcript, and the answer. Each section is truncated proportionally against this.
    /// Was 12,000: three English tafsirs plus the translations at that size came to 4,304 tokens
    /// against the model's 4,096 (measured 2026-09-05; tafsir prose tokenizes at ~3 characters a
    /// token). 9,000 leaves ~1,000 tokens for the instructions and the answer, and the sheet retries
    /// leaner once should a dense text still overflow (`isContextOverflow`).
    static let summarizeMultiSourceLimit = 9000

    /// The source text a summarize session is grounded on: trimmed, clipped to the model's sensible
    /// context, with a flag so the UI can disclose the truncation.
    static func clippedSource(_ text: String) -> (text: String, truncated: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > summarizeSourceLimit else { return (trimmed, false) }
        return (String(trimmed.prefix(summarizeSourceLimit)) + "…", true)
    }

    /// One labeled section of a multi-source summarize (e.g. "Tafsir Ibn Kathir (English)" + its text).
    struct SummarizeSection {
        let label: String
        let text: String
    }

    /// Combine labeled sections into ONE source text under `limit`, each section headed
    /// "=== label ===". When the total is over budget every section keeps its PROPORTIONAL share
    /// (floored at 400 characters so a short tafsir is never starved to nothing), and a truncated
    /// section says so inline - the model, and the reader via the returned flag, both know.
    static func combinedSource(_ sections: [SummarizeSection],
                               limit: Int = summarizeMultiSourceLimit) -> (text: String, truncated: Bool) {
        let trimmed = sections
            .map { (label: $0.label, text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.text.isEmpty }
        guard !trimmed.isEmpty else { return ("", false) }

        // Reserve room for the headers, joiners, and truncation notes before sharing out the rest.
        let overheadPerSection = 80
        let budget = max(1000, limit - trimmed.count * overheadPerSection)
        let total = trimmed.reduce(0) { $0 + $1.text.count }

        var truncatedAny = false
        let parts = trimmed.map { section -> String in
            var text = section.text
            var note = ""
            if total > budget {
                let share = max(400, budget * section.text.count / total)
                if text.count > share {
                    text = String(text.prefix(share)) + "…"
                    note = "\n[This section was shortened to fit.]"
                    truncatedAny = true
                }
            }
            return "=== \(section.label) ===\n\(text)\(note)"
        }
        return (parts.joined(separator: "\n\n"), truncatedAny)
    }

    /// One completed follow-up exchange, re-sent with every turn so each answer is grounded on the
    /// same source text plus the running conversation.
    struct SummarizeTurn: Sendable {
        let question: String
        let answer: String
    }

    /// Stream a faithful summary of `source` (pass it pre-clipped via `clippedSource`, or
    /// pre-combined via `combinedSource` with `multiSource: true`). Snapshots, like the chat engine:
    /// each yielded value is the full text so far.
    /// `focus`: a multi-source summary of ONE section only (its "=== label ==="); the other sections
    /// are context the model may read but must not summarize. How an Arabic tafsir edition gets an
    /// English summary at all: the model rejects a prompt that is mostly Arabic
    /// (`unsupportedLanguageOrLocale`), so the edition travels with the ayah's English translations
    /// and an English commentary, which the detector reads as an English prompt.
    @available(iOS 26.0, *)
    static func streamSummary(title: String, source: String,
                              multiSource: Bool = false,
                              language: SummaryLanguage = .english,
                              focus: String? = nil) -> AsyncThrowingStream<String, Error> {
        if multiSource {
            let task = focus.map { focusTask($0, language: language) } ?? """
            TASK: Read every section above, including the Arabic ones, and write ONE synthesized \
            summary IN \(language.promptName): the complete picture these sources give together, in a few short \
            paragraphs, naming a specific source where it adds a distinct point. Nothing added.
            """
            return streamSummarizeTask(instructions: summarizeMultiInstructions(language), prompt: """
            SOURCE TEXTS ("\(title)"):
            \(source)

            \(task)
            """)
        }
        return streamSummarizeTask(instructions: summarizeInstructions(language), prompt: """
        SOURCE TEXT ("\(title)"):
        \(source)

        TASK: Summarize this source text faithfully IN \(language.promptName), in a few short paragraphs: \
        its main points, in its own emphasis, nothing added.
        """)
    }

    /// Stream the answer to a follow-up question, re-grounded on the SAME source text plus the
    /// running transcript. Older turns are dropped and long answers clipped so the source text
    /// always keeps its full share of the context window.
    /// The task line of a focused multi-source summary (see `streamSummary(focus:)`).
    private static func focusTask(_ focus: String, language: SummaryLanguage) -> String {
        """
        TASK: Summarize ONLY the section headed "=== \(focus) ===", IN \(language.promptName), in a few \
        short paragraphs: its main points, in its own emphasis, nothing added. The OTHER sections are \
        context to help you read it (the same ayah's English translations and an English commentary): \
        do not summarize them, and do not attribute their points to "\(focus)" unless it makes them \
        too. If you cannot read the focused section well enough to summarize it faithfully, say so \
        plainly instead of guessing.
        """
    }

    @available(iOS 26.0, *)
    static func streamFollowUp(title: String, source: String, transcript: [SummarizeTurn],
                               question: String, multiSource: Bool = false,
                               language: SummaryLanguage = .english,
                               focus: String? = nil) -> AsyncThrowingStream<String, Error> {
        let recent = transcript.suffix(6).map { turn in
            "Q: \(String(turn.question.prefix(300)))\nA: \(String(turn.answer.prefix(600)))"
        }.joined(separator: "\n")

        let conversation = recent.isEmpty ? "" : """

        CONVERSATION SO FAR:
        \(recent)
        """

        let sourceHeading = multiSource ? "SOURCE TEXTS" : "SOURCE TEXT"
        let closing: String
        if let focus {
            closing = "Answer IN \(language.promptName), from the section headed \"=== \(focus) ===\" first; " +
                "the other sections are context, so name them when a point comes from one of them instead."
        } else if multiSource {
            closing = "Answer IN \(language.promptName), only from the source texts above. Any of the sections may " +
              "supply the answer; name which source a point comes from when relevant."
        } else {
            closing = "Answer IN \(language.promptName), only from the source text above."
        }

        return streamSummarizeTask(
            instructions: multiSource ? summarizeMultiInstructions(language) : summarizeInstructions(language),
            prompt: """
            \(sourceHeading) ("\(title)"):
            \(source)
            \(conversation)

            QUESTION: \(question)

            \(closing)
            """)
    }

    /// The on-device model occasionally falls into a loop and repeats one sentence (or a pair of
    /// them) until its token budget runs out: "what breaks wudu" on 2026-09-06 filled the whole chat
    /// with the same line. Three identical consecutive sentences (or sentence pairs) at the tail of a
    /// snapshot mean it is looping; the text is cut at the start of the second copy and the stream
    /// ends there, so the answer keeps everything the model said before it stalled.
    static func repetitionCutoff(in text: String) -> String.Index? {
        let terminators: Set<Character> = [".", "!", "?", "\n", "\u{61F}", "\u{6D4}"]
        var sentences: [(start: String.Index, key: String)] = []
        var start = text.startIndex
        var index = text.startIndex
        while index < text.endIndex {
            if terminators.contains(text[index]) {
                let end = text.index(after: index)
                let key = text[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
                if !key.isEmpty { sentences.append((start, key)) }
                start = end
            }
            index = text.index(after: index)
        }
        for window in 1...2 {
            let needed = window * 3
            guard sentences.count >= needed else { continue }
            let tail = Array(sentences.suffix(needed))
            let groups = stride(from: 0, to: needed, by: window).map { offset in
                tail[offset..<offset + window].map(\.key).joined(separator: " ")
            }
            guard let first = groups.first, first.count >= 24,
                  groups.allSatisfy({ $0 == first }) else { continue }
            return tail[window].start
        }
        return nil
    }

    @available(iOS 26.0, *)
    private static func streamSummarizeTask(instructions: String, prompt: String,
                                            options: GenerationOptions = GenerationOptions()) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let session = LanguageModelSession(instructions: instructions)
                    let stream = session.streamResponse(to: prompt, options: options)
                    for try await partial in stream {
                        if Task.isCancelled { break }
                        if let cut = repetitionCutoff(in: partial.content) {
                            let kept = String(partial.content[..<cut]).trimmingCharacters(in: .whitespacesAndNewlines)
                            continuation.yield(kept)
                            break
                        }
                        continuation.yield(partial.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

#else

/// Non-iOS or SDK-without-FoundationModels: the feature does not exist. `isAvailable` is false, so the
/// surfaces that reference this (the Islam tab's resource list, `AskAIChat.swift` on an SDK without
/// FoundationModels) compile and simply never show it.
enum OnDeviceAsk {
    struct SummarizeTurn: Sendable {
        let question: String
        let answer: String
    }

    static var isAvailable: Bool { false }
}

#endif
