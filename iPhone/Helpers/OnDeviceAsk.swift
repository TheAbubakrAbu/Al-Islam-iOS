import Foundation
import SwiftUI

// "Ask" - question answering over the app's own retrieval, powered by Apple's ON-DEVICE
// foundation model (the ~3B-parameter LLM behind Apple Intelligence). Private, offline, free.
//
// The architecture is RAG-first: when the app's search retrieved passages (ayahs / hadiths with
// references), the model answers grounded in them, citing each one, and never inventing verse or
// hadith text. When retrieval found NOTHING, the ask still runs in an open mode: a general-knowledge
// answer under strict integrity rules (no recreated quotations, honest uncertainty, no rulings) so
// the button never dead-ends - the user asked to be answered like an assistant, not gated on search.
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
    }

    /// Whether the on-device model can run right now (device eligible + Apple Intelligence enabled +
    /// model assets ready). Checked at render time so enabling Apple Intelligence lights this up
    /// without an app restart.
    static var isAvailable: Bool {
        guard #available(iOS 26.0, *) else { return false }
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// True for queries that read as QUESTIONS - the trigger for the Ask card. Keyword/reference/topic
    /// queries never invoke the model; only something a person would actually ask.
    static func looksLikeQuestion(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count >= 8 else { return false }
        if trimmed.hasSuffix("?") { return true }
        guard trimmed.split(separator: " ").count >= 4 else { return false }
        let starters = [
            "what ", "why ", "how ", "when ", "where ", "who ", "which ",
            "does ", "do ", "did ", "is ", "are ", "can ", "could ", "should ", "will ", "am i", "tell me"
        ]
        return starters.contains { trimmed.hasPrefix($0) }
    }

    /// The rules a GROUNDED session is created with: cite everything, invent nothing, no rulings -
    /// but answer fully, not in a two-sentence crouch.
    private static let groundedInstructions = """
    You are a knowledgeable, careful assistant inside a Quran and Hadith reading app. You will be \
    given PASSAGES (each with its reference) and a QUESTION.

    Rules, in order:
    1. Ground the answer in the given passages. Cite EVERY passage that supports a point, inline in \
    parentheses exactly as its reference is given, e.g. (2:153) or (Sahih al-Bukhari 6114). Most \
    questions draw on several passages - cite all that genuinely apply, not just the first one.
    2. Never invent, complete, or misattribute verses, hadiths, or interpretations. Do not reproduce \
    a passage's full text - the app displays every passage you cite right beneath your answer - but \
    you may briefly paraphrase what a cited passage says.
    3. You may add short connecting explanation from general knowledge (historical context, what a \
    term means), but keep every religious claim tied to the cited passages. If the passages only \
    partly answer the question, answer what they support and say plainly what they do not cover.
    4. Never issue religious rulings, verdicts, or fatwas. For "is X halal/haram/allowed" questions, \
    describe only what the passages say and add that a qualified scholar should be consulted.
    5. Write a clear, complete answer: usually one or two short paragraphs, plain respectful \
    language, no markdown formatting.
    """

    /// The rules an OPEN session is created with, used when retrieval found nothing: answer like an
    /// assistant from general knowledge, under integrity rules that forbid recreated quotations.
    private static let openInstructions = """
    You are a knowledgeable, careful assistant inside a Quran and Hadith reading app. The app's \
    search found no passages for this question, so you are answering from general knowledge.

    Rules, in order:
    1. Answer the QUESTION helpfully from well-established general knowledge about Islam, its \
    history, practices, and texts.
    2. NEVER write out the text of a verse or hadith from memory, and never present wording as a \
    quotation - describe content in your own words. You may name well-known references (a surah, a \
    famous collection) when you are confident they are right.
    3. Be honest about uncertainty: when you are not sure, say so rather than guessing, and \
    encourage the reader to verify in the app's Quran and Hadith tabs.
    4. Never issue religious rulings, verdicts, or fatwas. For "is X halal/haram/allowed" questions, \
    describe the considerations involved and refer the reader to a qualified scholar.
    5. Write a clear, complete answer: usually one or two short paragraphs, plain respectful \
    language, no markdown formatting.
    """

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
    /// pre-combined via `combinedSource` with `multiSource: true`). Snapshots, like `streamAnswer`:
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
    private static func streamSummarizeTask(instructions: String, prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let session = LanguageModelSession(instructions: instructions)
                    let stream = session.streamResponse(to: prompt)
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

    /// Stream the answer. Each yielded value is the FULL text so far (snapshots), so the UI just
    /// replaces its string. Throws when the model declines or errors; the caller shows nothing.
    /// Empty `sources` = open mode: the general-knowledge instructions with just the question.
    @available(iOS 26.0, *)
    static func streamAnswer(question: String, sources: [Source]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let instructions: String
                    let prompt: String
                    if sources.isEmpty {
                        instructions = openInstructions
                        prompt = "QUESTION: \(question)"
                    } else {
                        // A passage block the small context window can always hold: at most 12
                        // sources (every surface feeds semantic hits first, then string-match hits,
                        // deduped - both retrieval modes get a voice), each clipped at 600
                        // characters. That is ~1.8k tokens worst case against the model's ~4k
                        // window - room to spare with the instructions, question, and answer - and
                        // 600 keeps whole hadiths intact even more often than the old 500.
                        let passages = sources.prefix(12).map { source in
                            "[\(source.reference)] \(String(source.text.prefix(600)))"
                        }.joined(separator: "\n")

                        instructions = groundedInstructions
                        prompt = """
                        PASSAGES:
                        \(passages)

                        QUESTION: \(question)
                        """
                    }

                    let session = LanguageModelSession(instructions: instructions)
                    let stream = session.streamResponse(to: prompt)
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

// MARK: - The Ask answer card (shared by the Quran and Hadith search surfaces)

/// The streaming answer card shown above the search results: question echo, the growing answer, the
/// grounding note. One component so both surfaces read identically.
struct AskAnswerCard: View {
    @ObservedObject var settings = Settings.shared

    let answer: String
    let isStreaming: Bool
    /// False when the ask ran in open mode (no retrieved passages): the placeholder and the footer
    /// must not claim the answer comes from passages shown below.
    var grounded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Asked AI")
                    .font(.caption.weight(.semibold))

                if isStreaming {
                    ProgressView()
                        .controlSize(.mini)
                }

                Spacer()
            }
            .foregroundStyle(settings.accentColor.color)

            if answer.isEmpty {
                Text(grounded ? "Reading the matching passages…" : "Thinking…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(answer)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            Text(grounded
                 ? "From Apple Intelligence, on device • answers from the passages shown below • not a religious ruling"
                 : "From Apple Intelligence, on device • a general answer, no passages were retrieved • verify important matters, not a religious ruling")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .conditionalGlassEffect(clear: true, rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(settings.accentColor.color.opacity(0.18), lineWidth: 1)
        )
    }
}

#else

/// Non-iOS or SDK-without-FoundationModels: the feature does not exist; call sites are `#if os(iOS)`
/// gated, so nothing references this stub in practice.
enum OnDeviceAsk {
    struct Source {
        let reference: String
        let text: String
    }

    static var isAvailable: Bool { false }
    static func looksLikeQuestion(_ query: String) -> Bool { false }
}

#endif
