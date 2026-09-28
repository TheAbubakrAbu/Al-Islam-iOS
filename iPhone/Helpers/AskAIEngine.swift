import Foundation

// Ask AI - the model behind the chat, and the prompt it is asked with.
//
// Two engines: Apple's ON-DEVICE foundation model (the ~3B-parameter model behind Apple Intelligence,
// 4k tokens of context, iOS 26+) and, on iOS 27, Apple's larger model on PRIVATE CLOUD COMPUTE
// (32k tokens; the request leaves the phone to Apple's attested servers and is never stored). The
// on-device engine is the default and always the fallback: the cloud one is offered only where the
// system reports it available, and the reader chooses it in the chat's menu.
//
// Each turn's prompt is built to the engine's budget: numbered sources with their provenance, the
// recent conversation clipped to a character budget, the task line for the question's intent, then
// the question. The instructions are the same for both engines.

#if os(iOS) && canImport(FoundationModels)
import FoundationModels

enum AskAIEngineKind: String, Codable, CaseIterable {
    case onDevice, privateCloud

    var title: String {
        switch self {
        case .onDevice: return "On device"
        case .privateCloud: return "Private Cloud Compute"
        }
    }

    var badge: String {
        switch self {
        case .onDevice: return "On device"
        case .privateCloud: return "Private Cloud"
        }
    }
}

/// The budget one turn is built to: how many sources, how much of each, how much conversation.
struct AskAIProfile {
    let kind: AskAIEngineKind
    let contextTokens: Int
    let sourceLimit: Int
    let sourceCharacters: Int
    let subjectCharacters: Int
    let historyCharacters: Int
    /// The ceiling an intent's own token cap is clipped to.
    let responseTokenCap: Int

    /// 8 sources of 500 characters is ~1k tokens against the 4k window, leaving room for the
    /// instructions (~500), the recent conversation (~450), the question and a full answer.
    static let onDevice = AskAIProfile(kind: .onDevice, contextTokens: 4096, sourceLimit: 8, sourceCharacters: 500,
                                       subjectCharacters: 1_400, historyCharacters: 1_800, responseTokenCap: 900)

    static func privateCloud(contextTokens: Int) -> AskAIProfile {
        let scale = max(1.0, min(4.0, Double(contextTokens) / 8192))
        return AskAIProfile(kind: .privateCloud, contextTokens: contextTokens,
                            sourceLimit: min(18, Int(8 * scale)), sourceCharacters: min(1_000, Int(500 * scale)),
                            subjectCharacters: min(3_200, Int(1_400 * scale)), historyCharacters: min(9_000, Int(1_800 * scale)),
                            responseTokenCap: 1_400)
    }

    var retrievalBudget: AskAIRetriever.Budget {
        .init(limit: sourceLimit, sourceCharacters: sourceCharacters, subjectCharacters: subjectCharacters)
    }
}

@available(iOS 26.0, *)
enum AskAIEngine {
    /// What went wrong, in the terms the conversation acts on.
    enum Failure {
        case contextOverflow, guardrail, unsupportedLanguage, busy, refusal
        /// The cloud model could not serve this turn (no connection, quota, service down, or an
        /// error before any text): the turn falls back to the on-device model.
        case cloudUnavailable(String)
        case other(String?)
    }

    // MARK: Which engine

    static let preferenceKey = "askAIEngine"

    /// The engine the reader chose (defaults to on device). The cloud choice only takes effect
    /// while `cloudIsOffered`; a `-askAIEngine cloud|device` DEBUG launch argument overrides both.
    static var preferred: AskAIEngineKind {
        get {
            #if DEBUG
            if let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-askAIEngine"),
               ProcessInfo.processInfo.arguments.indices.contains(index + 1) {
                return ProcessInfo.processInfo.arguments[index + 1] == "cloud" ? .privateCloud : .onDevice
            }
            #endif
            return AskAIEngineKind(rawValue: UserDefaults.standard.string(forKey: preferenceKey) ?? "") ?? .onDevice
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: preferenceKey) }
    }

    /// The engine a turn actually runs on: the preference, unless the cloud is not on offer.
    static var effective: AskAIEngineKind {
        preferred == .privateCloud && cloudIsOffered ? .privateCloud : .onDevice
    }

    /// Set once a cloud turn fails before producing text this launch: the offer is withdrawn until
    /// the next launch, so a dead connection does not cost a fallback wait on every question.
    nonisolated(unsafe) static var cloudFailedThisLaunch = false

    /// Whether Private Cloud Compute can serve this device right now (iOS 27, eligible, ready).
    /// Cached briefly: it is read in view bodies.
    static var cloudIsOffered: Bool {
        guard !cloudFailedThisLaunch else { return false }
        if #available(iOS 27.0, *) {
            let now = CFAbsoluteTimeGetCurrent()
            if let cached = cloudOfferCache, now - cached.at < 20 { return cached.offered }
            let offered = PrivateCloudComputeLanguageModel().isAvailable
            cloudOfferCache = (offered, now)
            return offered
        }
        return false
    }
    nonisolated(unsafe) private static var cloudOfferCache: (offered: Bool, at: CFAbsoluteTime)?

    /// The cloud model's context size, fetched once (an async query); 32k until known.
    nonisolated(unsafe) private static var cloudContextTokens = 32_768

    static func profile(for kind: AskAIEngineKind) -> AskAIProfile {
        switch kind {
        case .onDevice: return .onDevice
        case .privateCloud: return .privateCloud(contextTokens: cloudContextTokens)
        }
    }

    // MARK: Generation

    /// Streams the answer: each yielded value is the full text so far. A repeated sentence ends
    /// the stream early (`OnDeviceAsk.repetitionCutoff`), keeping what came before the loop.
    static func stream(kind: AskAIEngineKind, instructions: String, prompt: String,
                       options: GenerationOptions) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let session = try makeSession(kind: kind, instructions: instructions)
                    let stream = session.streamResponse(to: prompt, options: options)
                    for try await partial in stream {
                        if Task.isCancelled { break }
                        if let cut = OnDeviceAsk.repetitionCutoff(in: partial.content) {
                            continuation.yield(String(partial.content[..<cut]).trimmingCharacters(in: .whitespacesAndNewlines))
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

    private struct CloudUnavailable: Error {}

    private static func makeSession(kind: AskAIEngineKind, instructions: String) throws -> LanguageModelSession {
        if kind == .privateCloud {
            if #available(iOS 27.0, *) {
                let model = PrivateCloudComputeLanguageModel()
                guard model.isAvailable else { throw CloudUnavailable() }
                Task {
                    if let size = try? await model.contextSize, size > 0 { cloudContextTokens = size }
                }
                return LanguageModelSession(model: model, instructions: instructions)
            }
            throw CloudUnavailable()
        }
        return LanguageModelSession(instructions: instructions)
    }

    /// Loads the on-device model ahead of the first question (the chat screen calls this on
    /// appear), so the first answer does not also pay the cold start. Once per process.
    nonisolated(unsafe) private static var didPrewarm = false
    static func prewarm() {
        guard !didPrewarm, OnDeviceAsk.isAvailable else { return }
        didPrewarm = true
        LanguageModelSession(instructions: AskAIPrompt.instructions).prewarm()
    }

    // MARK: Failures

    static func classify(_ error: Error) -> Failure {
        if error is CloudUnavailable { return .cloudUnavailable("Private Cloud Compute is not available right now") }
        if let generation = error as? LanguageModelSession.GenerationError {
            switch generation {
            case .exceededContextWindowSize: return .contextOverflow
            case .guardrailViolation: return .guardrail
            case .unsupportedLanguageOrLocale: return .unsupportedLanguage
            case .rateLimited, .concurrentRequests: return .busy
            case .refusal: return .refusal
            default: return .other(nil)
            }
        }
        if #available(iOS 27.0, *) {
            if let modelError = error as? LanguageModelError {
                switch modelError {
                case .contextSizeExceeded: return .contextOverflow
                case .guardrailViolation: return .guardrail
                case .unsupportedLanguageOrLocale: return .unsupportedLanguage
                case .rateLimited: return .busy
                case .refusal: return .refusal
                case .timeout: return .other("The model took too long to answer.")
                default: return .other(nil)
                }
            }
            if let cloud = error as? PrivateCloudComputeLanguageModel.Error {
                switch cloud {
                case .networkFailure: return .cloudUnavailable("no connection")
                case .quotaLimitReached: return .cloudUnavailable("the daily Private Cloud Compute limit was reached")
                case .serviceUnavailable: return .cloudUnavailable("Private Cloud Compute is unavailable right now")
                @unknown default: return .cloudUnavailable("Private Cloud Compute could not answer")
                }
            }
        }
        return .other(nil)
    }

    /// What to tell the reader when a generation fails for a reason they can act on. Nil for the
    /// generic case (the caller's own wording applies).
    static func message(for failure: Failure) -> String? {
        switch failure {
        case .guardrail:
            return "Apple Intelligence declined to answer this one. Try rephrasing the question, or asking about it in a different way."
        case .refusal:
            return "Apple Intelligence declined to answer this one. Try asking in a different way."
        case .unsupportedLanguage:
            return "Apple Intelligence can\u{2019}t work in that language yet. Try asking in English."
        case .busy:
            return "Apple Intelligence is busy right now. Try again in a moment."
        case .contextOverflow:
            return "This turn was longer than the model can read in one go. Try a shorter question, or start a new conversation."
        case .cloudUnavailable(let reason):
            return "Private Cloud Compute could not answer (\(reason))."
        case .other(let text):
            return text
        }
    }
}

// MARK: - The prompt

enum AskAIPrompt {
    /// The rules every chat session is created with: who the assistant is, how it talks, how it
    /// uses and cites the sources, what it never does.
    static let instructions = """
    You are the assistant inside Al-Islam, an app for the Quran, the hadith and prayer times. You talk \
    with the reader the way a warm, well-read friend would: naturally, directly, in plain English, \
    remembering what was said earlier in the conversation. A greeting gets a friendly greeting back, \
    thanks get a brief warm reply, and a real question gets a complete answer.

    STYLE. Begin with the answer itself: no filler such as "Sure" or "Great question", no repeating the \
    question, no labels such as "Q:" or "A:". Plain text only: no asterisks, pound signs, underscores or \
    other markdown. Short paragraphs; a numbered list only for real steps. Do not add a list of \
    references at the end: the app shows every source you cite beneath your answer.

    SOURCES. For most questions the app searches its own library and gives you numbered SOURCES: \
    verses of the Quran, hadiths, tafsir excerpts, a surah's background, the app's own articles, duas, \
    Names of Allah, app tips, or today's prayer times. Each says where it comes from. Rules:
    1. Build the answer on the sources that fit the question and ignore the ones that do not.
    2. When you use a source, say in words where it comes from (the surah; the collection and its \
    narrator; the tafsir's author; the app's article) and put its number in square brackets right \
    after the point, like [1] or [2][4]. Cite by number only, never by a number you invent.
    3. You may quote a short phrase from a source word for word, in quotation marks. Never quote or \
    cite anything that is not in the sources: no verse numbers, hadith numbers or wording from memory. \
    Where the sources fall short, answer from general knowledge and say so in words ("scholars \
    generally explain", "it is reported that") without a number.
    4. A source marked SUBJECT OF THE QUESTION is the verse, surah or hadith the question is about: \
    explain that one, not something else.
    5. Use the "Prayer times today" source only for questions about today's schedule, and give its \
    times exactly as written.

    HONESTY. Say when something is uncertain or disputed among scholars, and say "I don't know" rather \
    than guess. Never give a fatwa or a personal ruling: for "is this allowed" questions, explain what \
    the evidence and the scholars say, note where they differ, and point to a qualified scholar for a \
    personal ruling. Answer in English even when asked in another language, keeping key Arabic terms \
    in transliteration.
    """

    /// One completed exchange, as the next turn's prompt carries it.
    struct Turn {
        let question: String
        let answer: String
    }

    /// The prompt for a turn: the numbered sources with their origins, the recent conversation
    /// clipped to the profile's budget (the most recent turn fullest), the task line, the question.
    static func build(question: AskAIQuestion, sources: [AskAISource], history: [Turn],
                      profile: AskAIProfile, framing: String? = nil) -> String {
        var prompt = ""
        if !sources.isEmpty {
            let lines = sources.enumerated().map { index, source in
                source.promptLine(number: index + 1, characters: source.isSubject ? profile.subjectCharacters : profile.sourceCharacters)
            }
            prompt += "SOURCES (cite by number in square brackets; the app shows each one beneath your answer):\n"
                + lines.joined(separator: "\n") + "\n\n"
        }
        let recent = clippedHistory(history, budget: profile.historyCharacters)
        if !recent.isEmpty {
            prompt += "CONVERSATION SO FAR (oldest first):\n" + recent + "\n\n"
        }
        var task = question.intent.taskLine
        if question.isFollowUp, !history.isEmpty {
            task += " This is a follow-up to the conversation above: \u{201C}that\u{201D}, \u{201C}it\u{201D} and \u{201C}he\u{201D} refer to what was just discussed."
        }
        if let framing { task += " " + framing }
        prompt += "TASK: \(task)\n\n"
        prompt += "User: \(question.raw)"
        return prompt
    }

    /// The most recent turns that fit: the last answer up to 900 characters, earlier ones 320,
    /// questions 240, newest kept first when the budget runs out.
    private static func clippedHistory(_ history: [Turn], budget: Int) -> String {
        var remaining = budget
        var lines: [String] = []
        for (offset, turn) in history.reversed().enumerated() {
            let answerCap = offset == 0 ? 900 : 320
            let question = AskAISource.clip(turn.question, to: 240)
            let answer = AskAISource.clip(turn.answer, to: answerCap)
            let cost = question.count + answer.count + 24
            if cost > remaining { break }
            remaining -= cost
            lines.insert("User: \(question)\nAssistant: \(answer)", at: 0)
        }
        return lines.joined(separator: "\n")
    }
}

#else

enum AskAIEngineKind: String, Codable, CaseIterable {
    case onDevice, privateCloud
    var title: String { self == .onDevice ? "On device" : "Private Cloud Compute" }
    var badge: String { self == .onDevice ? "On device" : "Private Cloud" }
}

struct AskAIProfile {
    let kind: AskAIEngineKind
    let sourceLimit: Int
    let sourceCharacters: Int
    let subjectCharacters: Int
    static let onDevice = AskAIProfile(kind: .onDevice, sourceLimit: 8, sourceCharacters: 500, subjectCharacters: 1_400)
    var retrievalBudget: AskAIRetriever.Budget {
        .init(limit: sourceLimit, sourceCharacters: sourceCharacters, subjectCharacters: subjectCharacters)
    }
}

#endif
