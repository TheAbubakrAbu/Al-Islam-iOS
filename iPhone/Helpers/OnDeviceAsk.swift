import Foundation
import SwiftUI

// "Ask" - the on-device model behind the app's Ask AI chat and its summarize sheets: Apple's
// ON-DEVICE foundation model (the ~3B-parameter LLM behind Apple Intelligence). Private, offline, free.
//
// The chat (`AskAIChatView`, Helpers/AskAIChat.swift) runs the app's own retrieval for every question
// and hands the passages here as SUPPORT: the model answers from what it knows AND the passages,
// citing each one it actually uses, and never writes out verse or hadith text from memory - the app
// shows every cited passage as a real row beneath the answer. The summarize sessions are the strict
// opposite: the given source text is their whole world.
//
// Availability: iOS 26+ on an Apple Intelligence device with it enabled. Everywhere else,
// `OnDeviceAsk.isAvailable` is false and the feature simply does not exist in the UI - the word-vector
// AI Search (SemanticSearch.swift) remains the baseline everywhere.

#if os(iOS) && canImport(FoundationModels)
import FoundationModels

enum OnDeviceAsk {
    /// One retrieved passage the answer may draw from - reference exactly as the app displays it
    /// ("2:153", "Sahih al-Bukhari 6114") plus its English text.
    struct Source {
        let reference: String
        let text: String
        /// How much of `text` a chat turn carries. Retrieved ayahs and hadiths keep the default;
        /// a tafsir passage or a surah's background prose is allowed more, because it IS the answer.
        var maxCharacters: Int = OnDeviceAsk.chatPassageCharacterLimit
        /// The verse or surah the question named: labelled SUBJECT in the prompt.
        var isSubject: Bool = false
    }

    /// Whether the on-device model can run right now (device eligible + Apple Intelligence enabled +
    /// model assets ready). Checked at render time so enabling Apple Intelligence lights this up
    /// without an app restart.
    /// Cached for a few seconds: `SystemLanguageModel.default.availability` is an XPC-backed query,
    /// and the Islam root, its search, the 99 Names, Adhkar, Dua and Arabic screens each asked it
    /// several times per body (Performance Guide, Phase 6 step 12). Availability only changes on a
    /// model download or a Settings flip, so a short TTL keeps every screen honest.
    static var isAvailable: Bool {
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

    /// The rules a CHAT session is created with: answer like a knowledgeable assistant, use the
    /// retrieved passages as support and cite the ones used, never recreate scripture from memory,
    /// no rulings, keep the conversation's thread.
    private static let chatInstructions = """
    You are a knowledgeable, warm assistant inside a Quran and Hadith reading app. People ask you \
    about the Quran, the hadith, Islamic history and practice, and you answer the way a well-read \
    friend would: directly, completely, and in plain language.

    You may be given PASSAGES the app retrieved for the question (ayahs, hadiths, tafsir excerpts, \
    a surah's background, a section of one of the app's own articles, or today's prayer times for \
    the user's own location, each with its reference) and the CONVERSATION so far. Rules, in order:
    1. Answer the question fully, from your general knowledge of Islam AND the passages. When the \
    question names a verse or a surah and a passage carries that exact reference, that passage IS \
    the subject: explain it, and do not describe some other verse instead. Other passages are \
    support, not a fence: build on the relevant ones and ignore the rest silently.
    2. Cite a passage you use inline in parentheses exactly as its reference is written, for \
    example (2:153) or (Sahih al-Bukhari 6114). Cite ONLY references that appear in PASSAGES. \
    Never add a reference, a verse number, or a hadith number from memory: if you draw on general \
    knowledge, say so in words ("the Quran teaches", "it is reported that") with no number.
    3. Never write out the wording of a verse or a hadith, and never put anything in quotation \
    marks as if it were scripture. Describe and paraphrase in your own words. The app shows every \
    passage you cite right beneath your answer. This does NOT apply to a "Prayer times today" \
    passage: those times, and the rakah counts beside them, are the user's own schedule, so give \
    them exactly as written rather than paraphrasing them away.
    4. Be honest about uncertainty and scholarly disagreement: say when something is debated, and \
    when you are not sure.
    5. Never issue a religious ruling, verdict, or fatwa. For "is X halal/haram/allowed" questions, \
    explain the considerations and the views that exist, then note that a qualified scholar should \
    be consulted for a personal ruling.
    6. Keep the conversation's thread: a follow-up refers to what was discussed before.
    7. Write in English even when the question is in another language, keeping key Arabic terms. \
    PLAIN TEXT ONLY: no asterisks, underscores, pound signs, or other markdown; short paragraphs; \
    a numbered list only when it genuinely helps.
    8. Begin directly with the answer: no preamble ("Sure!", "Great question"), no labels such as \
    "Q:" or "A:", and never repeat the question back. Do not add a "References" list at the end.
    """

    /// How many retrieved passages a chat turn carries, and how much of each: 8 passages of 500
    /// characters is ~1k tokens against the on-device model's ~4k window, leaving room for the
    /// instructions, the recent conversation, the question, and a full answer.
    static let chatPassageLimit = 8
    static let chatPassageCharacterLimit = 500

    /// Stream a chat answer: the question, the retrieved passages (support, cited when used), and the
    /// recent conversation (the last few completed turns, clipped). Snapshots, like `streamSummary`:
    /// each yielded value is the full text so far. Throws when the model declines or errors.
    @available(iOS 26.0, *)
    static func streamChatAnswer(question: String, sources: [Source],
                                 transcript: [SummarizeTurn]) -> AsyncThrowingStream<String, Error> {
        let passages = sources.prefix(chatPassageLimit).map { source in
            "\(source.isSubject ? "SUBJECT OF THE QUESTION " : "")[\(source.reference)] \(String(source.text.prefix(source.maxCharacters)))"
        }.joined(separator: "\n")
        let recent = transcript.suffix(3).map { turn in
            "Earlier question: \(String(turn.question.prefix(300)))\nEarlier answer: \(String(turn.answer.prefix(500)))"
        }.joined(separator: "\n")

        var prompt = ""
        if !passages.isEmpty {
            prompt += "PASSAGES the app retrieved for this question (a passage marked SUBJECT OF THE QUESTION is the verse or surah the question is about: base the answer on it; cite the passages you use, ignore the rest):\n\(passages)\n\n"
        }
        if !recent.isEmpty {
            prompt += "CONVERSATION SO FAR:\n\(recent)\n\n"
        }
        prompt += "QUESTION: \(question)"
        // Measured on the shipping model: 0.7 drifted from the passages, 0.3 fell into paragraph
        // loops; 0.5 keeps citations put without looping. The token ceiling stops a runaway turn (an
        // unbounded one once produced a 90-item list), and the caller cuts a loop the moment a
        // paragraph repeats (`AskAIAnswerText.isLooping`).
        let options = GenerationOptions(temperature: 0.5, maximumResponseTokens: 900)
        return streamSummarizeTask(instructions: chatInstructions, prompt: prompt, options: options)
    }

    /// Loads the model ahead of the first question (the chat screen calls this on appear), so the
    /// first answer does not also pay the model's cold start. Once per process.
    nonisolated(unsafe) private static var didPrewarmChat = false
    @available(iOS 26.0, *)
    static func prewarmChatModel() {
        guard !didPrewarmChat, isAvailable else { return }
        didPrewarmChat = true
        LanguageModelSession(instructions: chatInstructions).prewarm()
    }

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
        default:
            return nil
        }
    }

    // MARK: - Summarize (tafsir / surah info / comparison sheets)

    /// The rules a SUMMARIZE session is created with: the given source text is the whole world -
    /// summarize it faithfully, answer follow-ups only from it, invent nothing, no rulings.
    private static let summarizeInstructions = """
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
    text does not address it - do not fill the gap from general knowledge.
    5. Write clearly and completely: short paragraphs, plain respectful language, no markdown \
    formatting.
    """

    /// The rules a MULTI-SOURCE summarize session is created with (the "all tafsirs" case): read every
    /// labeled section, Arabic included, always write in English, synthesize one picture, and answer
    /// follow-ups from ANY of the sources - naming which one a point comes from when relevant.
    private static let summarizeMultiInstructions = """
    You are a careful reading assistant inside a Quran and Hadith reading app. You will be given \
    SOURCE TEXTS: several sections, each headed "=== ... ===" naming which tafsir (Quranic \
    commentary) or source it is. Some sections are in English and some in Arabic.

    Rules, in order:
    1. Read ALL the sections, including the Arabic ones, but ALWAYS write in ENGLISH.
    2. Ground EVERYTHING in the given sections. Synthesize one complete picture from all of them \
    together: report only what the texts actually say, in your own words, keeping their emphasis. \
    Where sources add distinct points, bring them together and name the source when that helps \
    (e.g. "al-Tabari notes..."). Never fabricate or extend their content.
    3. When answering follow-up questions, draw on ANY of the sections - not just one - and name \
    which tafsir a point comes from when relevant.
    4. Never write out the text of a verse or hadith from memory. If a source quotes one, refer to \
    it briefly in your own words rather than reproducing it.
    5. Never issue religious rulings, verdicts, or fatwas. Where the texts discuss what is \
    permitted or forbidden, describe only what they say and note that a qualified scholar should \
    be consulted for personal rulings.
    6. If a question asks about something none of the sections cover, say plainly that these texts \
    do not address it - do not fill the gap from general knowledge.
    7. Write clearly and completely: short paragraphs, plain respectful language, no markdown \
    formatting.
    """

    /// How much source text a summarize prompt carries. ~6000 characters is a sensible fit for the
    /// on-device model's small context window once instructions, transcript, and answer share it.
    static let summarizeSourceLimit = 6000

    /// The cap for the MULTI-SOURCE case (all tafsirs of an ayah at once): higher, because the whole
    /// point is breadth, but still leaving the small context window room for instructions, the
    /// transcript, and the answer. Each section is truncated proportionally against this.
    static let summarizeMultiSourceLimit = 12000

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
    /// pre-combined via `combinedSource` with `multiSource: true`). Snapshots, like `streamChatAnswer`:
    /// each yielded value is the full text so far.
    @available(iOS 26.0, *)
    static func streamSummary(title: String, source: String,
                              multiSource: Bool = false) -> AsyncThrowingStream<String, Error> {
        if multiSource {
            return streamSummarizeTask(instructions: summarizeMultiInstructions, prompt: """
            SOURCE TEXTS ("\(title)"):
            \(source)

            TASK: Read every section above, including the Arabic ones, and write ONE synthesized \
            summary IN ENGLISH: the complete picture these sources give together, in a few short \
            paragraphs, naming a specific source where it adds a distinct point. Nothing added.
            """)
        }
        return streamSummarizeTask(instructions: summarizeInstructions, prompt: """
        SOURCE TEXT ("\(title)"):
        \(source)

        TASK: Summarize this source text faithfully in a few short paragraphs: its main points, \
        in its own emphasis, nothing added.
        """)
    }

    /// Stream the answer to a follow-up question, re-grounded on the SAME source text plus the
    /// running transcript. Older turns are dropped and long answers clipped so the source text
    /// always keeps its full share of the context window.
    @available(iOS 26.0, *)
    static func streamFollowUp(title: String, source: String, transcript: [SummarizeTurn],
                               question: String, multiSource: Bool = false) -> AsyncThrowingStream<String, Error> {
        let recent = transcript.suffix(6).map { turn in
            "Q: \(String(turn.question.prefix(300)))\nA: \(String(turn.answer.prefix(600)))"
        }.joined(separator: "\n")

        let conversation = recent.isEmpty ? "" : """

        CONVERSATION SO FAR:
        \(recent)
        """

        let sourceHeading = multiSource ? "SOURCE TEXTS" : "SOURCE TEXT"
        let closing = multiSource
            ? "Answer IN ENGLISH, only from the source texts above - any of the sections may " +
              "supply the answer; name which source a point comes from when relevant."
            : "Answer only from the source text above."

        return streamSummarizeTask(
            instructions: multiSource ? summarizeMultiInstructions : summarizeInstructions,
            prompt: """
            \(sourceHeading) ("\(title)"):
            \(source)
            \(conversation)

            QUESTION: \(question)

            \(closing)
            """)
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
    struct Source {
        let reference: String
        let text: String
        var maxCharacters: Int = 500
        var isSubject: Bool = false
    }

    struct SummarizeTurn: Sendable {
        let question: String
        let answer: String
    }

    static var isAvailable: Bool { false }
    static let chatPassageLimit = 8
}

#endif
