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
