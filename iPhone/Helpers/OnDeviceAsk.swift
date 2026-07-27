import Foundation
import SwiftUI

// "Ask" - grounded question answering over the app's own retrieval, powered by Apple's ON-DEVICE
// foundation model (the ~3B-parameter LLM behind Apple Intelligence). Private, offline, free.
//
// The architecture is strict RAG: the model NEVER answers from its own knowledge - it receives only
// the passages the app's search already retrieved (ayahs / hadiths with references) and must answer
// from those, citing them, or say the passages don't contain the answer. Religious content is never
// generated, only summarized from what is on screen.
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

    /// The rules the session is created with. Firm on grounding and on never issuing rulings.
    private static let instructions = """
    You are a retrieval assistant inside a Quran and Hadith reading app. You will be given PASSAGES \
    (each with its reference) and a QUESTION.

    Rules, in order:
    1. Answer ONLY from the given passages. Never use outside knowledge, and never invent or complete \
    verses, hadiths, or interpretations.
    2. Cite EVERY passage that supports the answer, inline in parentheses exactly as its reference is \
    given, e.g. (2:153) or (Sahih al-Bukhari 6114). Most questions draw on several passages - cite all \
    that genuinely apply, not just the first one.
    3. Do NOT quote or reproduce the passages' text. Explain the answer briefly in your own words - the \
    app displays every passage you cite, in full, right beneath your answer.
    4. If the passages do not contain an answer, say exactly that in one sentence - do not guess.
    5. Never issue religious rulings, verdicts, or fatwas. For "is X halal/haram/allowed" questions, \
    describe only what the passages say and add that a qualified scholar should be consulted.
    6. Be concise: 2-5 sentences, plain respectful language.
    """

    /// Stream the grounded answer. Each yielded value is the FULL text so far (snapshots), so the UI
    /// just replaces its string. Throws when the model declines or errors; the caller shows nothing.
    @available(iOS 26.0, *)
    static func streamAnswer(question: String, sources: [Source]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // A passage block the small context window can always hold: at most 12 sources
                    // (every surface feeds semantic hits first, then string-match hits, deduped - both
                    // retrieval modes get a voice), each clipped at 500 characters. That is ~1.5k tokens
                    // worst case against the model's ~4k window - room to spare with the instructions,
                    // question, and answer - and 500 keeps whole hadiths intact far more often than the
                    // old 320, which could clip the very sentence that answered the question.
                    let passages = sources.prefix(12).map { source in
                        "[\(source.reference)] \(String(source.text.prefix(500)))"
                    }.joined(separator: "\n")

                    let prompt = """
                    PASSAGES:
                    \(passages)

                    QUESTION: \(question)
                    """

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
                Text("Reading the matching passages…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(answer)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            Text("From Apple Intelligence, on device • answers only from the passages shown below • not a religious ruling")
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
