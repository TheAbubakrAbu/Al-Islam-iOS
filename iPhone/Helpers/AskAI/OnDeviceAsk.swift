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
        #if DEBUG
        // `-askAILog`: why Apple Intelligence is missing, in the console (a per-app language the
        // model does not support reads as unavailable, not as an unsupported-language error).
        if !available, ProcessInfo.processInfo.arguments.contains("-askAILog") {
            print("askai: availability \(SystemLanguageModel.default.availability) languages \(Locale.preferredLanguages) supportsLocale(ar) \(SystemLanguageModel.default.supportsLocale(Locale(identifier: "ar")))")
        }
        #endif
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
        // Through the chat's classifier: iOS 27 reports it as `LanguageModelError.contextSizeExceeded`,
        // which the iOS 26 case alone missed (no leaner retry, and the generic failure line).
        if case .contextOverflow = AskAIEngine.classify(error) { return true }
        return false
    }

    /// What to tell the reader when a generation fails for a reason they can act on. Nil for the
    /// generic case (the caller's own wording applies).
    @available(iOS 26.0, *)
    static func failureMessage(for error: Error) -> String? {
        // The chat's classifier reads both error families (iOS 26's `GenerationError`, iOS 27's
        // `LanguageModelError`); the wording here is the summary's own.
        let failure = AskAIEngine.classify(error)
        switch failure {
        case .guardrail, .refusal:
            return String(localized: "Apple Intelligence declined to answer this one. Try rephrasing the question, or asking about it in a different way.")
        case .unsupportedLanguage:
            return String(localized: "Apple Intelligence can\u{2019}t work in that language yet. Try asking in English.")
        case .busy:
            return String(localized: "Apple Intelligence is busy right now. Try again in a moment.")
        case .contextOverflow:
            return String(localized: "This text is longer than Apple Intelligence can read in one go on this device.")
        case .modelUnavailable:
            return AskAIEngine.message(for: failure)
        case .cloudUnavailable, .other:
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

    /// The cap for the MULTI-SOURCE case (all tafsirs of an ayah at once): higher, because the whole
    /// point is breadth, but still leaving the small context window room for instructions, the
    /// transcript, and the answer. Each section is truncated proportionally against this.
    /// Was 12,000: three English tafsirs plus the translations at that size came to 4,304 tokens
    /// against the model's 4,096 (measured 2026-09-05; tafsir prose tokenizes at ~3 characters a
    /// token). 9,000 leaves ~1,000 tokens for the instructions and the answer, and the sheet retries
    /// leaner once should a dense text still overflow (`isContextOverflow`).
    static let summarizeMultiSourceLimit = 9000

    // MARK: - Reading a long text whole
    //
    // The model's window is 4,096 tokens, and until 2026-11-25 a summary read the first 6,000
    // characters of its text and nothing after them (Abu: "why only first 6k characters"). A longer
    // text is now read to its end, in parts: each part is one request that fits the window, its
    // paragraph joins the summary as it is written, and a question afterwards is answered from the
    // passages of the whole text that bear on it (`passages(of:for:limit:)`).
    //
    // Measured on the simulator, 2026-11-25, Ibn Kathir on 2:255 (13,809 characters): the wait for
    // the first word is the model reading the prompt, about a millisecond a token on top of half a
    // second (1,500 characters 0.95 s, 6,000 2.1 s, 10,500 4.2 s), and 2.9 s more when the model
    // has to be loaded first. So the first part is short (the first words come in about a second),
    // the model starts loading as the sheet rises (`prewarmSummaries`), and the parts after it are
    // read while the reader is on the paragraphs before them. The text runs 3.6 characters a token where it is
    // plain prose and 2.6 where it is names and transliteration, so a part is sized for the dense
    // case and, where the tokenizer can be asked (iOS 26.4), measured before it is sent.

    /// A text up to this long is summarized in one request, as it always was.
    static let singlePassCharacters = 7_000
    /// The first part of a longer text: short, because the reader is waiting on it.
    static let firstPartCharacters = 3_200
    /// What a part after the first aims for, and the most it may be.
    static let partCharacters = 6_500
    static let partCharactersCeiling = 8_000
    /// The parts one summary reads: about 75,000 characters. A text past that is summarized up to
    /// there, and the sheet says how far it read.
    static let maximumParts = 10

    /// The most of a text a summary reads (`maximumParts` full parts).
    static var summarizeReach: Int { firstPartCharacters + (maximumParts - 1) * partCharactersCeiling }

    /// The tokens a summary's answer may take: one request's few paragraphs, one part's paragraph,
    /// the answer to a question about the text.
    private static let summaryResponseTokens = 700
    private static let partResponseTokens = 260
    private static let followUpResponseTokens = 500
    /// The instructions (323 tokens measured, the Arabic rule a little more), the prompt's heading
    /// and task line, and a margin.
    private static let frameTokens = 520

    /// The tokens the text of one request may take beside an answer of `responseTokens`.
    @available(iOS 26.0, *)
    private static func textTokens(beside responseTokens: Int) -> Int {
        max(1_024, AskAIEngine.onDeviceModel.contextSize) - frameTokens - responseTokens
    }

    /// The opening of `text`, at most `limit` characters long: cut after a paragraph where one ends
    /// in its last two fifths, else after a line, else after a sentence, else at a space.
    static func head(of text: Substring, limit: Int) -> Substring {
        guard limit > 0, let hard = text.index(text.startIndex, offsetBy: limit, limitedBy: text.endIndex),
              hard < text.endIndex else { return text }
        let floor = text.index(text.startIndex, offsetBy: limit * 3 / 5)
        let tail = text[floor..<hard]
        if let paragraph = tail.range(of: "\n\n", options: .backwards) { return text[..<paragraph.upperBound] }
        if let line = tail.lastIndex(where: \.isNewline) { return text[...line] }
        var index = tail.endIndex
        while index > tail.startIndex {
            let next = index
            index = tail.index(before: index)
            if ".!?\u{06D4}".contains(tail[index]), next == tail.endIndex || tail[next].isWhitespace {
                return text[...index]
            }
        }
        if let space = tail.lastIndex(where: \.isWhitespace) { return text[..<space] }
        return text[..<hard]
    }

    /// `text` cut back, at a paragraph or a sentence end, until the model's own tokenizer counts it
    /// within `tokens`. Unchanged where it already fits, and where the tokenizer cannot be asked
    /// (iOS 26.0 to 26.3: the character sizes above are set for that case, and a request that still
    /// overflows is retried shorter).
    @available(iOS 26.0, *)
    static func fitting(_ text: Substring, tokens budget: Int) async -> Substring {
        guard #available(iOS 26.4, *) else { return text }
        // Asked only for a text long enough to overflow: the densest prose measured runs 2.6
        // characters a token, and the first count of a launch takes up to a second, which the
        // short opening part (the one the reader is waiting on) must not pay.
        guard Double(text.count) > Double(budget) * 2.2 else { return text }
        var kept = text
        for _ in 0..<3 {
            guard let count = try? await AskAIEngine.onDeviceModel.tokenCount(for: String(kept)), count > budget else { break }
            let limit = Int(Double(kept.count) * Double(budget) / Double(count) * 0.96)
            kept = head(of: kept, limit: max(400, limit))
        }
        return kept
    }

    /// A part's paragraph as it joins the summary: trimmed, and when the answer ran into its token
    /// ceiling mid-sentence, cut back to its last whole sentence (the next part's paragraph follows
    /// straight on, and half a sentence before it reads as a fault).
    static func wholeSentences(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = trimmed.last, !".!?\u{201D}\")\u{06D4}".contains(last) else { return trimmed }
        guard let end = trimmed.lastIndex(where: { ".!?".contains($0) }),
              trimmed.distance(from: trimmed.startIndex, to: end) > trimmed.count / 2 else { return trimmed }
        return String(trimmed[...end])
    }

    /// What a summary has read and written so far.
    struct SummaryProgress: Sendable {
        /// The summary so far: the paragraph of every part already read, then the one being written.
        var text: String
        /// How many characters of the text are summarized, and how long the text is.
        var read: Int
        var total: Int
        /// The next part is being read: nothing new to show until its first words arrive.
        var isReading = false
        /// The summary ended before the text did (longer than `summarizeReach`, or a part the model
        /// could not read): `read` says how far it got.
        var stoppedShort = false

        /// Whether the text is being read in parts at all.
        var isInParts: Bool { total > OnDeviceAsk.singlePassCharacters }
    }

    /// Stream a faithful summary of ONE text, whatever its length: a text of `singlePassCharacters`
    /// or less in one request, a longer one part by part to its end. Each yielded value holds the
    /// whole summary so far.
    @available(iOS 26.0, *)
    static func streamTextSummary(title: String, text: String,
                                  language: SummaryLanguage = .english) -> AsyncThrowingStream<SummaryProgress, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let whole = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let total = whole.count
                let instructions = summarizeInstructions(language)
                do {
                    guard total > singlePassCharacters else {
                        let source = await fitting(Substring(whole), tokens: textTokens(beside: summaryResponseTokens))
                        let read = source.count
                        let prompt = """
                        SOURCE TEXT ("\(title)"):
                        \(source)

                        TASK: Summarize this source text faithfully IN \(language.promptName), in a few short paragraphs: \
                        its main points, in its own emphasis, nothing added.
                        """
                        let options = GenerationOptions(maximumResponseTokens: summaryResponseTokens)
                        for try await snapshot in streamSummarizeTask(instructions: instructions, prompt: prompt, options: options) {
                            continuation.yield(SummaryProgress(text: snapshot, read: read, total: total, stoppedShort: read < total))
                        }
                        continuation.finish()
                        return
                    }

                    var rest = Substring(whole)
                    var paragraphs: [String] = []
                    var part = 0
                    var partSize = partCharacters
                    var failedPart = false
                    // A part counts as read once its first words arrive (the model has been through
                    // it by then), so the bar moves with the reading and not a paragraph behind it.
                    func progress(writing: String? = nil, isReading: Bool = false, reading: Int = 0) -> SummaryProgress {
                        SummaryProgress(text: (paragraphs + (writing.map { [$0] } ?? [])).joined(separator: "\n\n"),
                                        read: total - rest.count + reading, total: total, isReading: isReading)
                    }
                    while !rest.isEmpty, part < maximumParts, !failedPart {
                        try Task.checkCancellation()
                        if part > 0 { continuation.yield(progress(isReading: true)) }
                        let target = part == 0 ? firstPartCharacters : partSize
                        // A short remainder is read with this part, never left as a scrap of its own.
                        var piece = rest.count <= target + target / 4 ? rest : head(of: rest, limit: target)
                        piece = await fitting(piece, tokens: textTokens(beside: partResponseTokens))
                        var paragraph = ""
                        var retriedShorter = false
                        while true {
                            let place = part == 0 ? "the opening passage" : piece.endIndex == rest.endIndex ? "the closing passage" : "a later passage"
                            let prompt = """
                            SOURCE TEXT ("\(title)", \(place) of a long text that is being read in order):
                            \(piece)

                            TASK: Summarize this passage faithfully IN \(language.promptName), in one short paragraph: its main \
                            points, in its own emphasis and in your own words, saying who said or did each thing. Quote \
                            nothing at length. Nothing added, no introduction, no conclusion, no remark on what the \
                            text leaves out, and do not call it a passage or a part.
                            """
                            do {
                                let options = GenerationOptions(maximumResponseTokens: partResponseTokens)
                                for try await snapshot in streamSummarizeTask(instructions: instructions, prompt: prompt, options: options) {
                                    paragraph = snapshot
                                    continuation.yield(progress(writing: snapshot, reading: piece.count))
                                }
                            } catch {
                                // Denser than the sizes allow for: once, three fifths of the part.
                                if !retriedShorter, paragraph.isEmpty, isContextOverflow(error) {
                                    retriedShorter = true
                                    piece = head(of: piece, limit: piece.count * 3 / 5)
                                    continue
                                }
                                // Nothing written at all is the summary's failure; a later part that
                                // cannot be read ends the summary where the reading stopped.
                                if paragraphs.isEmpty, paragraph.isEmpty { throw error }
                                failedPart = true
                            }
                            break
                        }
                        let written = wholeSentences(paragraph)
                        if !written.isEmpty { paragraphs.append(written) }
                        if failedPart, written.isEmpty { break }
                        rest = rest[piece.endIndex...].drop(while: \.isWhitespace)
                        part += 1
                        if part == 1 {
                            // What is left, shared evenly over the parts it takes.
                            let parts = max(1, min(maximumParts - 1, (rest.count + partCharacters - 1) / partCharacters))
                            partSize = min(partCharactersCeiling, rest.count / parts + 200)
                        }
                        continuation.yield(progress())
                    }
                    var last = progress()
                    last.stoppedShort = !rest.isEmpty
                    continuation.yield(last)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The passages of `text` a question is answered from when the whole of it is longer than
    /// `limit` characters: the ones that share the most of the question's own words, in the text's
    /// order, with "[...]" where text between them is left out. The opening of the text when the
    /// question names nothing in it ("what is the main point?").
    static func passages(of text: String, for question: String, limit: Int) -> String {
        let whole = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard whole.count > limit else { return whole }
        let opening = String(head(of: Substring(whole), limit: limit))
        let terms = Set(AskAILexicon.fold(question).split(separator: " ").map(String.init)
            .filter { $0.count >= 3 && !AskAILexicon.stopWords.contains($0) })
        guard !terms.isEmpty else { return opening }
        // A word counts when the passage has it, or a word that begins as it does ("fasting", "fasts").
        let stems = terms.map { $0.count > 5 ? String($0.prefix($0.count - 2)) : $0 }

        var blocks: [(text: Substring, score: Int)] = []
        var rest = Substring(whole)
        while !rest.isEmpty {
            let block = head(of: rest, limit: 900)
            let words = AskAILexicon.fold(String(block)).split(separator: " ")
            let score = stems.reduce(0) { total, stem in total + (words.contains { $0.hasPrefix(stem) } ? 1 : 0) }
            blocks.append((block, score))
            rest = rest[block.endIndex...]
        }
        guard blocks.contains(where: { $0.score > 0 }) else { return opening }

        // The best passages first, each with the one after it (an answer often runs on), until the
        // room is used; then put back in the text's order.
        var chosen = Set<Int>()
        var used = 0
        for index in blocks.indices.sorted(by: { (blocks[$0].score, -$0) > (blocks[$1].score, -$1) }) where blocks[index].score > 0 {
            for candidate in [index, index + 1] where blocks.indices.contains(candidate) && !chosen.contains(candidate) {
                guard used + blocks[candidate].text.count <= limit else { continue }
                chosen.insert(candidate)
                used += blocks[candidate].text.count
            }
        }
        guard !chosen.isEmpty else { return opening }
        var out = ""
        var previous: Int?
        for index in chosen.sorted() {
            if let previous, index != previous + 1 { out += "\n[...]\n" } else if previous == nil, index > 0 { out += "[...]\n" }
            out += blocks[index].text
            previous = index
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Stream the answer to a question about ONE text of any length (the twin of `streamTextSummary`):
    /// grounded on the whole text when it fits beside the conversation, else on the passages of it
    /// that bear on the question, with the summary written earlier for orientation.
    @available(iOS 26.0, *)
    static func streamTextFollowUp(title: String, text: String, summary: String, transcript: [SummarizeTurn],
                                   question: String, language: SummaryLanguage = .english) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                // The last few turns, clipped: the text is what an answer comes from.
                let recent = transcript.suffix(4).map { turn in
                    "Q: \(String(turn.question.prefix(300)))\nA: \(String(turn.answer.prefix(500)))"
                }.joined(separator: "\n")
                let conversation = recent.isEmpty ? "" : "\nCONVERSATION SO FAR:\n\(recent)\n"
                let asked = String(question.prefix(600))
                let whole = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let overview = String(head(of: Substring(summary.trimmingCharacters(in: .whitespacesAndNewlines)), limit: 1_200))

                func prompt(sourceLimit: Int) -> String {
                    let source = passages(of: whole, for: asked, limit: sourceLimit)
                    guard source.count < whole.count else {
                        return """
                        SOURCE TEXT ("\(title)"):
                        \(source)
                        \(conversation)
                        QUESTION: \(asked)

                        Answer IN \(language.promptName), only from the source text above.
                        """
                    }
                    return """
                    SOURCE TEXT ("\(title)": the passages of a long text that bear on the question, with [...] where \
                    text between them is left out):
                    \(source)

                    A SUMMARY OF THE WHOLE TEXT, written earlier (for orientation only):
                    \(overview)
                    \(conversation)
                    QUESTION: \(asked)

                    Answer IN \(language.promptName), only from the passages above and the summary. If they do not \
                    cover what is asked, say that the part of the text you were given does not address it.
                    """
                }

                // Sized in characters for the dense case, then measured where the tokenizer can be
                // asked: the passages give way, never the question or the conversation.
                let tokens = textTokens(beside: followUpResponseTokens)
                let fixed = conversation.count + asked.count + overview.count
                var limit = max(1_500, Int(Double(tokens) * 2.7) - fixed)
                var request = prompt(sourceLimit: limit)
                if #available(iOS 26.4, *) {
                    for _ in 0..<2 {
                        guard let count = try? await AskAIEngine.onDeviceModel.tokenCount(for: request), count > tokens else { break }
                        limit = max(1_000, Int(Double(limit) * Double(tokens) / Double(count) * 0.92))
                        request = prompt(sourceLimit: limit)
                    }
                }
                do {
                    let options = GenerationOptions(maximumResponseTokens: followUpResponseTokens)
                    for try await snapshot in streamSummarizeTask(instructions: summarizeInstructions(language), prompt: request, options: options) {
                        continuation.yield(snapshot)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Loading the model ahead

    /// Loads the model as the Summarize sheet rises, so it comes into memory while the sheet opens
    /// (and, for a gatherer, while the texts are fetched). Cheap when it is already there; at most
    /// once every 45 seconds either way.
    ///
    /// Only there. For a day (2026-11-25) the model was also loaded when a tafsir or a surah's
    /// background opened, for a reader who had summarized lately, which took the first word of a
    /// launch's first summary from 4 seconds to 1.3. Taken out the same day: Abu's complaint was the
    /// phone lagging while the model works, and a model that starts working on a screen where nobody
    /// asked for it is that, for the sake of a wait he had not complained about.
    @available(iOS 26.0, *)
    static func prewarmSummaries() {
        guard isAvailable else { return }
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastSummaryPrewarm > 45 else { return }
        lastSummaryPrewarm = now
        LanguageModelSession(model: AskAIEngine.onDeviceModel, instructions: summarizeInstructions(.english)).prewarm()
    }

    nonisolated(unsafe) private static var lastSummaryPrewarm: CFAbsoluteTime = 0

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
                    // The Ask AI chat's model, with the permissive guardrail setting Apple gives for
                    // transforming text the app hands it (2026-11-23): the default setting declines
                    // ordinary religious passages (see `AskAIEngine.onDeviceModel`), and its safety
                    // model failing to load failed every summary outright (ModelManagerError 1001,
                    // met on the iOS 26.5 simulator while Ask AI, already permissive, answered).
                    let session = LanguageModelSession(model: AskAIEngine.onDeviceModel, instructions: instructions)
                    #if DEBUG
                    let began = CFAbsoluteTimeGetCurrent()
                    var firstWord: CFAbsoluteTime?
                    var written = 0
                    #endif
                    let stream = session.streamResponse(to: prompt, options: options)
                    for try await partial in stream {
                        if Task.isCancelled { break }
                        #if DEBUG
                        if firstWord == nil { firstWord = CFAbsoluteTimeGetCurrent() }
                        written = partial.content.count
                        #endif
                        if let cut = repetitionCutoff(in: partial.content) {
                            let kept = String(partial.content[..<cut]).trimmingCharacters(in: .whitespacesAndNewlines)
                            continuation.yield(kept)
                            break
                        }
                        continuation.yield(partial.content)
                    }
                    #if DEBUG
                    // `-summaryProbe`: one line per request, with what the prompt really cost against
                    // the model's window (counted after the answer, so it adds nothing to the wait).
                    if ProcessInfo.processInfo.arguments.contains("-summaryProbe") {
                        let now = CFAbsoluteTimeGetCurrent()
                        var counted = "n/a"
                        if #available(iOS 26.4, *) {
                            let promptTokens = try? await AskAIEngine.onDeviceModel.tokenCount(for: prompt)
                            let ruleTokens = try? await AskAIEngine.onDeviceModel.tokenCount(for: Instructions(instructions))
                            counted = "\(promptTokens ?? -1)+\(ruleTokens ?? -1)"
                        }
                        NSLog("SUMMARYPROBE request chars=%d tokens=%@ window=%d wait=%.2fs total=%.2fs wrote=%d counting=%.2fs", prompt.count,
                              counted, AskAIEngine.onDeviceModel.contextSize, (firstWord ?? now) - began, now - began, written,
                              CFAbsoluteTimeGetCurrent() - now)
                    }
                    #endif
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
