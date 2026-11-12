import Foundation

// Ask AI - the model behind the chat, and the prompt it is asked with.
//
// Two engines: Apple's ON-DEVICE foundation model (the ~3B-parameter model behind Apple Intelligence,
// 4k tokens of context, iOS 26+) and, on iOS 27, Apple's larger model on PRIVATE CLOUD COMPUTE
// (32k tokens; the request leaves the phone to Apple's attested servers and is never stored). The
// on-device engine is the default and always the fallback: the cloud one is offered only where the
// system reports it available, and the reader chooses it in the chat's menu.
//
// PRIVATE CLOUD COMPUTE NEEDS A MANAGED ENTITLEMENT. Without `com.apple.developer.private-cloud-compute`
// the framework does not throw: it traps the process ("Fatal error: Missing entitlement", measured
// 2026-09-28 on the iOS 27 simulator). So every cloud path here sits behind the compile flag
// HAS_PRIVATE_CLOUD_COMPUTE, which is defined nowhere yet. To turn the cloud on: request the
// entitlement at https://developer.apple.com/contact/request/private-cloud-compute/, add it to the
// iPhone target's entitlements, and add HAS_PRIVATE_CLOUD_COMPUTE to SWIFT_ACTIVE_COMPILATION_CONDITIONS.
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
        case .onDevice: return String(localized: "On device")
        case .privateCloud: return String(localized: "Private Cloud Compute")
        }
    }

    var badge: String {
        switch self {
        case .onDevice: return String(localized: "On device")
        case .privateCloud: return String(localized: "Private Cloud")
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

    /// 8 sources of 500 characters is ~1.3k tokens against the 4k window, leaving room for the
    /// instructions (~850), the recent conversation (~400), the question and a full answer;
    /// `AskAIPrompt.fit` drops the lowest-ranked sources when a subject's longer text would not fit.
    static let onDevice = AskAIProfile(kind: .onDevice, contextTokens: 4096, sourceLimit: 8, sourceCharacters: 500,
                                       subjectCharacters: 1_400, historyCharacters: 1_200, responseTokenCap: 900)

    /// The on-device profile for the window the model reports (`SystemLanguageModel.contextSize`,
    /// 4,096 on today's devices; newer ones report more): a doubled window takes half again as many
    /// sources, each a little longer, and a longer answer.
    static func onDevice(contextTokens: Int) -> AskAIProfile {
        guard contextTokens >= 8192 else { return onDevice }
        return AskAIProfile(kind: .onDevice, contextTokens: contextTokens, sourceLimit: 12, sourceCharacters: 600,
                            subjectCharacters: 2_000, historyCharacters: 1_600, responseTokenCap: 1_000)
    }

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
        /// The model or its safety model could not be loaded (assets still downloading, or a
        /// runtime whose model assets do not match: the iOS 26.5 simulator under Xcode 27 fails
        /// every turn this way, SensitiveContentAnalysisML 15 over ModelManagerError 1001).
        case modelUnavailable
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
            #if DEBUG && HAS_PRIVATE_CLOUD_COMPUTE
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
        #if HAS_PRIVATE_CLOUD_COMPUTE
        guard !cloudFailedThisLaunch else { return false }
        if #available(iOS 27.0, *) {
            let now = CFAbsoluteTimeGetCurrent()
            if let cached = cloudOfferCache, now - cached.at < 20 { return cached.offered }
            let cloudReady = PrivateCloudComputeLanguageModel().isAvailable
            cloudOfferCache = (cloudReady, now)
            return cloudReady
        }
        #endif
        return false
    }
    nonisolated(unsafe) private static var cloudOfferCache: (offered: Bool, at: CFAbsoluteTime)?

    /// The cloud model's context size, fetched once (an async query); 32k until known.
    nonisolated(unsafe) private static var cloudContextTokens = 32_768

    /// The on-device model's window, read in `prewarm` (4,096 until then and on every device that
    /// reports nothing more), and what its tokenizer charges for the instructions (888 measured on
    /// the iOS 27 simulator, 2026-11-07; re-measured in `prewarm` where `tokenCount` exists).
    nonisolated(unsafe) private(set) static var onDeviceContextTokens = 4096
    nonisolated(unsafe) private(set) static var instructionTokens = 888

    /// Counts a prompt's tokens with the model's own tokenizer; nil where the API does not exist
    /// (iOS 26.0 to 26.3), so `AskAIPrompt.fit` keeps its estimate.
    static var tokenCounter: ((String) async -> Int?)? {
        guard #available(iOS 26.4, *) else { return nil }
        return { text in try? await onDeviceModel.tokenCount(for: text) }
    }

    static func profile(for kind: AskAIEngineKind) -> AskAIProfile {
        switch kind {
        case .onDevice: return .onDevice(contextTokens: onDeviceContextTokens)
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
                #if DEBUG
                // `-askAIForceDecline`: every turn fails the way a guardrail decline does, so the
                // decline card can be seen (the permissive model declined none of the questions tried).
                if ProcessInfo.processInfo.arguments.contains("-askAIForceDecline") {
                    continuation.finish(throwing: ForcedDecline())
                    return
                }
                #endif
                do {
                    let session = try makeSession(kind: kind, instructions: instructions)
                    let stream = session.streamResponse(to: prompt, options: options)
                    for try await snapshot in stream {
                        if Task.isCancelled { break }
                        if let cut = OnDeviceAsk.repetitionCutoff(in: snapshot.content) {
                            continuation.yield(String(snapshot.content[..<cut]).trimmingCharacters(in: .whitespacesAndNewlines))
                            break
                        }
                        continuation.yield(snapshot.content)
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
    #if DEBUG
    /// The error `-askAIForceDecline` throws; `classify` reads it as a guardrail decline.
    struct ForcedDecline: Error {}
    #endif

    /// The on-device model with the permissive guardrail setting: the default one declined 5 of 11
    /// ordinary religious questions (fighting, zina, hitting a wife, homosexuality, hell) on the
    /// retrieved passages as often as on the question; the permissive setting declined none of 16,
    /// and the app's instructions still govern what is written. A decline that does come through
    /// is shown as a decline, with the sources (no "educational" re-ask from general knowledge).
    static let onDeviceModel = SystemLanguageModel(guardrails: .permissiveContentTransformations)

    private static func makeSession(kind: AskAIEngineKind, instructions: String) throws -> LanguageModelSession {
        if kind == .privateCloud {
            #if HAS_PRIVATE_CLOUD_COMPUTE
            if #available(iOS 27.0, *) {
                let model = PrivateCloudComputeLanguageModel()
                guard model.isAvailable else { throw CloudUnavailable() }
                Task {
                    if let size = try? await model.contextSize, size > 0 { cloudContextTokens = size }
                }
                return LanguageModelSession(model: model, instructions: instructions)
            }
            #endif
            throw CloudUnavailable()
        }
        return LanguageModelSession(model: onDeviceModel, instructions: instructions)
    }

    /// Loads the on-device model ahead of the first question (the chat screen calls this on
    /// appear), so the first answer does not also pay the cold start. Once per process.
    nonisolated(unsafe) private static var didPrewarm = false
    static func prewarm() {
        guard !didPrewarm, OnDeviceAsk.isAvailable else { return }
        didPrewarm = true
        LanguageModelSession(model: onDeviceModel, instructions: AskAIPrompt.instructions).prewarm()
        // On the main actor: the statics it writes are read there (`profile(for:)`, `fit`).
        Task { @MainActor in
            let window = onDeviceModel.contextSize
            if window >= 1024 { onDeviceContextTokens = window }
            if #available(iOS 26.4, *), let count = try? await onDeviceModel.tokenCount(for: Instructions(AskAIPrompt.instructions)), count > 0 {
                instructionTokens = count
            }
        }
    }

    // MARK: Failures

    static func classify(_ error: Error) -> Failure {
        if error is CloudUnavailable { return .cloudUnavailable(String(localized: "Private Cloud Compute is not available right now")) }
        #if DEBUG
        if error is ForcedDecline { return .guardrail }
        #endif
        if let generation = error as? LanguageModelSession.GenerationError {
            switch generation {
            case .exceededContextWindowSize: return .contextOverflow
            case .guardrailViolation: return .guardrail
            case .unsupportedLanguageOrLocale: return .unsupportedLanguage
            case .rateLimited, .concurrentRequests: return .busy
            case .refusal: return .refusal
            case .assetsUnavailable: return .modelUnavailable
            default:
                let description = "\(generation)"
                if description.contains("ModelManagerError") || description.contains("SensitiveContentAnalysisML") {
                    return .modelUnavailable
                }
                return .other(nil)
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
                case .timeout: return .other(String(localized: "The model took too long to answer."))
                default: return .other(nil)
                }
            }
            if let cloud = error as? PrivateCloudComputeLanguageModel.Error {
                switch cloud {
                case .networkFailure: return .cloudUnavailable(String(localized: "no connection"))
                case .quotaLimitReached: return .cloudUnavailable(String(localized: "the daily Private Cloud Compute limit was reached"))
                case .serviceUnavailable: return .cloudUnavailable(String(localized: "Private Cloud Compute is unavailable right now"))
                @unknown default: return .cloudUnavailable(String(localized: "Private Cloud Compute could not answer"))
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
            return String(localized: "Apple Intelligence declined to write about this. The sources the app found are shown below so you can read them yourself.")
        case .refusal:
            return String(localized: "Apple Intelligence declined to answer this one. Try asking in a different way.")
        case .unsupportedLanguage:
            return String(localized: "Apple Intelligence can\u{2019}t work in that language yet. Try asking in English.")
        case .busy:
            return String(localized: "Apple Intelligence is busy right now. Try again in a moment.")
        case .contextOverflow:
            return String(localized: "This turn was longer than the model can read in one go. Try a shorter question, or start a new conversation.")
        case .modelUnavailable:
            return String(localized: "Apple Intelligence\u{2019}s model isn\u{2019}t ready on this device right now. If Apple Intelligence was just turned on, its model may still be downloading; try again in a little while.")
        case .cloudUnavailable(let reason):
            return String(localized: "Private Cloud Compute could not answer (\(reason)).")
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
    with the reader the way a warm, well-read friend would: naturally, directly, in plain English. A \
    greeting gets a friendly greeting back, thanks get a brief warm reply, and a real question gets a \
    complete answer written in your own words.

    STYLE. Begin with the answer itself: no filler such as "Sure" or "Great question", no repeating the \
    question, no labels such as "Q:" or "A:". Plain text only: no asterisks, pound signs, underscores or \
    other markdown. Short paragraphs; a numbered list only for real steps. No list of references at \
    the end: the app shows every source you cite beneath your answer.

    THE CONVERSATION. Earlier turns may be shown to you as context. Every reply answers only the newest \
    message: never repeat, restate or continue an earlier answer, and never copy its sentences. A \
    follow-up such as "why?" or "tell me more" gets NEW material about the same subject.

    SOURCES. For most questions the app searches its own library and gives you numbered SOURCES: \
    verses of the Quran, hadiths, tafsir excerpts, a surah's background, the app's own articles, duas, \
    Names of Allah, settings, app tips, or today's prayer times. Each says where it comes from. Rules:
    1. Build the answer on the sources that fit the question and ignore the ones that do not.
    2. When you use a source, say in words where it comes from and put its number in square brackets \
    right after the point, like [1] or [2][4]. A verse of the Quran is the word of Allah: introduce it \
    as the words of Allah in that surah, naming the surah written beside it, never as something the \
    Prophet said. A hadith is what the Prophet said or did: introduce it by the narrator and the \
    collection written beside that source, and only those (never a narrator or collection from \
    memory). A tafsir is its author's explanation; an article is the app's own; a dua's source says \
    which collection records it.
    3. Write in your own words. You may quote at most one short phrase or sentence per source, word for \
    word, in quotation marks; never copy a source's text wholesale and never reproduce a source's cut-off \
    ending. Never quote or cite anything that is not in the sources: no verse numbers, hadith numbers or \
    wording from memory. If none of the sources answers the question, say so plainly in one sentence of \
    your own and stop there: do not fill the gap from memory, and do not attribute a view to scholars \
    unless a source states it. When the sources do answer it, answer from them and add no remark about \
    what the library lacks.
    4. A source marked SUBJECT OF THE QUESTION is the verse, surah or hadith the question is about: \
    explain that one, not something else. A source marked as already quoted in your previous answer \
    is there for context: draw a NEW point from it or from another source, never the same quotation.
    5. Read a hadith as a whole before drawing a point from it: a phrase inside it may be someone \
    else's words (a Companion's objection, a questioner) that the Prophet then answered or corrected, \
    and the chapter title beside it says what the collector understood it to establish.
    6. Never state a prayer time or a time of day that is not written in a source.

    HONESTY. Say plainly when something is disputed among scholars or when you are not sure; do not \
    manufacture doubt where there is none. Never present your own words as what scholars say. Never give a fatwa or a personal ruling: for "is this \
    allowed" questions, explain what the evidence and the scholars say, note where they differ, and \
    point to a qualified scholar for a personal ruling. Answer in English even when asked in another \
    language, keeping key Arabic terms in transliteration.
    """

    /// One completed exchange, as the next turn's prompt carries it.
    struct Turn {
        let question: String
        let answer: String
        /// The answer's "[n]" markers were renumbered to THIS turn's sources (a recap or a source
        /// question); every other earlier answer is re-sent without markers, whose numbers point
        /// into another turn's sources.
        var keepsMarkers = false
    }

    /// The characters the instructions take, and a turn's overhead (headings, task line, question).
    private static let instructionCharacters = instructions.count
    private static let overheadCharacters = 700

    /// The sources that fit the engine's window beside the history and the answer, best first:
    /// the window is ~3 characters a token, so the sources, the history, the instructions and the
    /// answer's own tokens are summed and the lowest-ranked sources dropped until it fits. Cheaper
    /// and better than the overflow retry, which cut the list in half blind.
    /// English prose on the on-device model measures 3 to 4 characters a token (tafsir prose ~3):
    /// 3.4 keeps a subject's long text in without overflowing, where 3 trimmed a turn to four sources.
    private static let charactersPerToken = 3.4

    /// Whether the turn's prompt carries the earlier conversation. A standalone question gets none:
    /// the earlier answers leaked into unrelated turns (hell into a crisis, mahr into apostasy) and
    /// a small model continues what it is shown. A follow-up needs it; thanks, goodbyes and recaps
    /// refer to the last turn by nature.
    static func sendsHistory(for question: AskAIQuestion) -> Bool {
        switch question.intent {
        case .thanks, .farewell, .recap: return true
        case .greeting, .capabilities, .smallTalk, .crisis: return false
        default: return question.isFollowUp
        }
    }

    static func fit(question: AskAIQuestion, sources: [AskAISource], history: [Turn], profile: AskAIProfile) -> [AskAISource] {
        let intent = question.intent
        let responseCharacters = Int(Double(min(intent.maxResponseTokens, profile.responseTokenCap)) * charactersPerToken)
        let window = Int(Double(profile.contextTokens) * charactersPerToken)
        let historyCharacters = sendsHistory(for: question)
            ? min(profile.historyCharacters, clippedHistory(history, budget: profile.historyCharacters).count) : 0
        var budget = window - responseCharacters - instructionCharacters - overheadCharacters - historyCharacters
        budget = max(1_500, budget)
        func cost(_ source: AskAISource) -> Int {
            let text = min(source.maxCharacters, source.isSubject ? profile.subjectCharacters : profile.sourceCharacters)
            return text + 40 + source.reference.count + source.provenance.reduce(0) { $0 + $1.count + 2 }
        }
        var kept = sources
        var total = kept.reduce(0) { $0 + cost($1) }
        while total > budget, kept.count > 2 {
            total -= cost(kept.removeLast())
        }
        return kept
    }

    /// The estimate above, then the model's own count: the prompt is built and measured, and the
    /// lowest-ranked source dropped while the instructions, the prompt, the answer's ceiling and
    /// a margin exceed the window (never below two sources). `measure` nil, or returning nil, keeps
    /// the estimate (the API is iOS 26.4; the estimate stays conservative for the devices before it).
    static func fit(question: AskAIQuestion, sources: [AskAISource], history: [Turn], profile: AskAIProfile,
                    measure: ((String) async -> Int?)?) async -> [AskAISource] {
        var kept = fit(question: question, sources: sources, history: history, profile: profile)
        guard let measure else { return kept }
        let instructionTokens: Int
        if #available(iOS 26.0, *) { instructionTokens = AskAIEngine.instructionTokens } else { instructionTokens = 846 }
        let reserved = instructionTokens + min(question.intent.maxResponseTokens, profile.responseTokenCap) + 64
        while kept.count > 2 {
            let prompt = build(question: question, sources: kept, history: history, profile: profile)
            guard let promptTokens = await measure(prompt) else { return kept }
            guard reserved + promptTokens > profile.contextTokens else { break }
            kept.removeLast()
        }
        return kept
    }

    /// The prompt for a turn: the numbered sources with their origins, the recent conversation
    /// clipped to the profile's budget (the most recent turn fullest), the task line, the question.
    static func build(question: AskAIQuestion, sources: [AskAISource], history: [Turn],
                      profile: AskAIProfile) -> String {
        var prompt = ""
        if !sources.isEmpty {
            let lines = sources.enumerated().map { index, source in
                source.promptLine(number: index + 1, characters: source.isSubject ? profile.subjectCharacters : profile.sourceCharacters)
            }
            prompt += "SOURCES (cite by number in square brackets; the app shows each one beneath your answer):\n"
                + lines.joined(separator: "\n") + "\n\n"
        }
        // What the model is shown of the conversation depends on the turn: a greeting or a
        // "what can you do" needs none (and copied the last reply when given it); thanks and
        // goodbyes need only what was last asked; a question gets the recent turns, clipped, and
        // labelled as context so the small model does not continue them.
        switch question.intent {
        case .greeting, .capabilities, .smallTalk:
            break
        case .thanks, .farewell:
            if let last = history.last {
                prompt += "The reader's last question was: \(AskAISource.clip(last.question, to: 160))\n\n"
            }
        case .recap:
            if let last = history.last {
                prompt += "YOUR PREVIOUS ANSWER (the one to rework), to the question \u{201C}\(AskAISource.clip(last.question, to: 160))\u{201D}:\n"
                    + AskAISource.clip(last.answer, to: 1_600) + "\n\n"
            }
        default:
            if sendsHistory(for: question) {
                let recent = clippedHistory(history, budget: profile.historyCharacters)
                if !recent.isEmpty {
                    prompt += "EARLIER IN THIS CONVERSATION (context only; never repeat or continue it):\n" + recent + "\n\n"
                }
            }
        }
        var task = question.intent.taskLine
        if [.reference, .define].contains(question.intent), let subject = sources.first(where: \.isSubject) {
            task = referenceTask(for: subject)
        }
        if question.isFollowUp, !history.isEmpty {
            task += " This is a follow-up to the conversation above: \u{201C}that\u{201D}, \u{201C}it\u{201D} and \u{201C}he\u{201D} refer to what was just discussed. Add new material (the reasoning, a source not yet used, the context); do not repeat the earlier answer or its quotations."
        }
        prompt += "TASK: \(task)\n\n"
        prompt += "User: \(question.raw)"
        return prompt
    }

    /// The task line for a question that names its subject, by what the subject is.
    private static func referenceTask(for subject: AskAISource) -> String {
        switch subject.kind {
        case .hadith:
            return "The question names a hadith, marked SUBJECT OF THE QUESTION. Explain that hadith: who narrated it and where it is recorded (from the details beside it), what it says in your own words with at most one short quotation, its context and meaning, and what scholars draw from it. Cite by number."
        case .surah:
            return "The question names a surah, marked SUBJECT OF THE QUESTION. Say what that surah is about from its background source: its name and where it was revealed, its main themes and how it unfolds, and anything notable about it. Cite by number. Do not describe some other surah."
        case .name:
            return "The question names one of the Names of Allah, marked SUBJECT OF THE QUESTION. Explain that Name: its meaning, where it occurs in the Quran (from the details beside it), and what it teaches about Allah and how a believer relates to it. Cite by number."
        default:
            return "The question names a verse, marked SUBJECT OF THE QUESTION. Explain that verse: its surah and where it sits, what it says in your own words with at most one short quotation, its context and meaning drawing on the tafsir source when there is one, and say where each point comes from. Cite by number. Do not describe some other verse."
        }
    }

    /// The most recent turns that fit: the last answer up to 480 characters (cut at a sentence),
    /// earlier ones 220, questions 200, newest kept first when the budget runs out. Short on
    /// purpose: the sources carry the substance, and a small model copies a long transcript.
    private static func clippedHistory(_ history: [Turn], budget: Int) -> String {
        var remaining = budget
        var lines: [String] = []
        for (offset, turn) in history.reversed().enumerated() {
            let answerCap = offset == 0 ? 480 : 220
            let question = AskAISource.clip(turn.question, to: 200)
            let answer = AskAISource.clip(turn.keepsMarkers ? turn.answer : AskAIText.strippingMarkers(turn.answer), to: answerCap)
            let cost = question.count + answer.count + 40
            if cost > remaining { break }
            remaining -= cost
            lines.insert("The reader asked: \(question)\nYou answered, in brief: \(answer)", at: 0)
        }
        return lines.joined(separator: "\n")
    }
}

#else

enum AskAIEngineKind: String, Codable, CaseIterable {
    case onDevice, privateCloud
    var title: String { self == .onDevice ? String(localized: "On device") : String(localized: "Private Cloud Compute") }
    var badge: String { self == .onDevice ? String(localized: "On device") : String(localized: "Private Cloud") }
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
