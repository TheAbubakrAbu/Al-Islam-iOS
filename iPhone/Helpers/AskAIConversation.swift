import SwiftUI
import Foundation

// Ask AI - the running conversation: one for the app, kept across launches, so reopening the chat
// from any entry point continues where it left off (until "New conversation").
//
// A turn: the question is analysed (AskAIIntent.swift), the app's library is searched for it
// (AskAIRetrieval.swift) unless it is conversation, the prompt is built to the engine's budget
// (AskAIEngine.swift) with the recent turns re-sent, the answer streams in, and what streamed is
// policed before it settles (AskAIText.swift). A cloud turn that fails before its first word falls
// back to the on-device model; a turn that overflows the window retries leaner; a guardrail trip
// retries once with the question framed as the educational request it is.

#if os(iOS)
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class AskAIConversation: ObservableObject {
    static let shared = AskAIConversation()

    enum Role: String, Codable { case user, assistant }

    struct Message: Identifiable, Codable {
        var id = UUID()
        let role: Role
        var text: String
        /// The sources retrieved for this turn (assistant only): the pool citations resolve from,
        /// so a cited card can never point at something the model was not shown.
        var sources: [AskAISource] = []
        var isStreaming = false
        var failed = false
        /// Citation markers and recalled references removed at the end of the turn, disclosed
        /// beneath the answer.
        var removedCitations = 0
        /// Quotations that matched no source's wording and were marked "(wording not verified)".
        var flaggedQuotations = 0
        /// The question asked for a ruling: the reply carries the sterner caution.
        var asksForRuling = false
        var intent: AskAIIntent? = nil
        var engine: AskAIEngineKind? = nil
        var isFollowUp = false
        /// A note the turn earned ("Private Cloud Compute was unavailable, so..."), shown under it.
        var note: String? = nil
        /// The references the answer cites, in the order they first appear. Parsed off the live
        /// text at every flush and when the reply settles (stored, not computed: the transcript
        /// read it per message per render).
        var citedReferences: [String] = []
        var suggestions: [String] = []
        var elapsed: Double? = nil

        var citedSources: [AskAISource] {
            citedReferences.compactMap { reference in sources.first { $0.reference == reference } }
        }

        var uncitedSources: [AskAISource] {
            sources.filter { !citedReferences.contains($0.reference) }
        }

        mutating func refreshCitations() {
            citedReferences = AskAIText.citedSources(in: text, sources: sources).map(\.reference)
        }
    }

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isAnswering = false
    /// The engine the reader chose. Mirrors `AskAIEngine.preferred`; a cloud choice only takes
    /// effect while the cloud model is on offer.
    @Published var engineKind: AskAIEngineKind {
        didSet { UserDefaults.standard.set(engineKind.rawValue, forKey: "askAIEngine") }
    }

    /// The conversation's current subject (the last standalone question's content words): what a
    /// bare follow-up searches with.
    private var topic: String?
    private var currentQuestion: AskAIQuestion?
    private var task: Task<Void, Never>?

    private init() {
        engineKind = AskAIEngineKind(rawValue: UserDefaults.standard.string(forKey: "askAIEngine") ?? "") ?? .onDevice
        #if DEBUG
        // "-askAIReset": start from an empty transcript (the headless batches must not inherit an
        // earlier run's conversation as history).
        if ProcessInfo.processInfo.arguments.contains("-askAIReset") {
            try? FileManager.default.removeItem(at: Self.storeURL)
        }
        #endif
        load()
    }

    // MARK: - Turns

    /// The completed question/answer pairs so far, oldest first: what a new turn is re-grounded on.
    private func completedTurns() -> [AskAIPrompt.Turn] {
        var turns: [AskAIPrompt.Turn] = []
        var pendingQuestion: String?
        for message in messages {
            switch message.role {
            case .user:
                pendingQuestion = message.text
            case .assistant:
                if let question = pendingQuestion, !message.failed, !message.isStreaming, !message.text.isEmpty {
                    turns.append(.init(question: question, answer: message.text))
                }
                pendingQuestion = nil
            }
        }
        return turns
    }

    func ask(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, OnDeviceAsk.isAvailable else { return }
        cancel()
        let history = completedTurns()
        let previousReply = messages.last(where: { $0.role == .assistant && !$0.failed && !$0.text.isEmpty })
        let question = AskAIQuestion.analyze(trimmed, previousTopic: topic, hasHistory: !history.isEmpty)
        if !question.isFollowUp, question.intent.retrieves, !question.contentWords.isEmpty {
            topic = question.topic
        }
        currentQuestion = question

        messages.append(Message(role: .user, text: trimmed))
        var reply = Message(role: .assistant, text: "", isStreaming: true)
        reply.asksForRuling = question.asksForRuling
        reply.intent = question.intent
        reply.isFollowUp = question.isFollowUp
        messages.append(reply)
        isAnswering = true

        task = Task { @MainActor in
            #if canImport(FoundationModels)
            let kind: AskAIEngineKind
            if #available(iOS 26.0, *) { kind = AskAIEngine.effective } else { kind = .onDevice }
            let profile: AskAIProfile
            if #available(iOS 26.0, *) { profile = AskAIEngine.profile(for: kind) } else { profile = .onDevice }
            #else
            let kind = AskAIEngineKind.onDevice
            let profile = AskAIProfile.onDevice
            #endif
            var sources: [AskAISource] = []
            var retrievalLog = ""
            if question.intent == .sourceQuestion {
                // About the previous answer's sources: those, cited ones first, nothing new.
                let cited = previousReply?.citedSources ?? []
                sources = cited + (previousReply?.uncitedSources ?? [])
                sources = Array(sources.prefix(profile.sourceLimit))
                retrievalLog = "previous turn's sources"
            } else if question.intent.retrieves {
                let outcome = await AskAIRetriever.retrieve(question, budget: profile.retrievalBudget,
                                                            carried: previousReply?.sources ?? [],
                                                            carriedCited: previousReply?.citedSources ?? [])
                sources = outcome.sources
                retrievalLog = String(format: "%.0f ms; lanes ", outcome.elapsed * 1000)
                    + outcome.laneCounts.map { "\($0.key.rawValue)=\($0.value)" }.sorted().joined(separator: " ")
                    + "; ranking " + outcome.ranking.prefix(12).map { String(format: "%@ %.2f", $0.reference, $0.score) }.joined(separator: " | ")
            }
            guard !Task.isCancelled else { return }
            updateReply { $0.sources = sources; $0.refreshCitations() }
            lastRetrievalLog = retrievalLog
            await answer(question: question, sources: sources, history: history, kind: kind, profile: profile)
        }
    }

    private var lastRetrievalLog = ""

    #if canImport(FoundationModels)
    private func answer(question: AskAIQuestion, sources initialSources: [AskAISource], history: [AskAIPrompt.Turn],
                        kind initialKind: AskAIEngineKind, profile initialProfile: AskAIProfile) async {
        guard #available(iOS 26.0, *) else { finishReply(failed: true); return }
        var kind = initialKind
        var profile = initialProfile
        var sources = initialSources
        var turns = history
        var framing: String?
        var retriedForContext = false
        var retriedForGuardrail = false
        var fellBack = false
        let started = CFAbsoluteTimeGetCurrent()
        var firstToken: Double?
        #if DEBUG
        // `-askAISyntheticStream`: a 600-word answer pushed through the same coalescing path at
        // ~200 tokens a second, to read the token-vs-flush counters under `-renderCounter`.
        if ProcessInfo.processInfo.arguments.contains("-askAISyntheticStream") {
            resetStream()
            for await text in Self.syntheticStream() {
                guard !Task.isCancelled else { resetStream(); return }
                if receiveStreamed(text) { break }
            }
            flushStreamed()
            finishReply(failed: false, elapsed: CFAbsoluteTimeGetCurrent() - started, firstToken: nil)
            return
        }
        #endif
        while true {
            do {
                resetStream()
                updateReply { $0.engine = kind }
                let prompt = AskAIPrompt.build(question: question, sources: sources, history: turns, profile: profile, framing: framing)
                lastPrompt = prompt
                let options = GenerationOptions(temperature: question.intent.temperature,
                                                maximumResponseTokens: min(question.intent.maxResponseTokens, profile.responseTokenCap))
                for try await text in AskAIEngine.stream(kind: kind, instructions: AskAIPrompt.instructions, prompt: prompt, options: options) {
                    guard !Task.isCancelled else { resetStream(); return }
                    if firstToken == nil { firstToken = CFAbsoluteTimeGetCurrent() - started }
                    // A small model can fall into repeating itself until the token ceiling: the
                    // moment a paragraph comes back (checked per flush), the answer is over.
                    if receiveStreamed(text) { break }
                }
                guard !Task.isCancelled else { resetStream(); return }
                flushStreamed()
                finishReply(failed: false, elapsed: CFAbsoluteTimeGetCurrent() - started, firstToken: firstToken)
                return
            } catch {
                guard !Task.isCancelled else { return }
                let failure = AskAIEngine.classify(error)
                let streamedSoFar = streamedText
                // The cloud model failed before a word arrived: this turn, and every later one this
                // launch, runs on the device instead.
                if kind == .privateCloud, !fellBack, streamedSoFar.isEmpty {
                    switch failure {
                    case .cloudUnavailable, .other, .busy:
                        fellBack = true
                        AskAIEngine.cloudFailedThisLaunch = true
                        kind = .onDevice
                        profile = .onDevice
                        sources = Array(sources.prefix(profile.sourceLimit))
                        let reason = AskAIEngine.message(for: failure) ?? "Private Cloud Compute could not answer."
                        updateReply { $0.sources = sources; $0.text = ""; $0.refreshCitations()
                            $0.note = "\(reason) This answer was written on your device instead." }
                        resetStream()
                        continue
                    default:
                        break
                    }
                }
                // The window overflowed (a long transcript on top of long sources): once, retry
                // lean - the question with fewer sources and no history - rather than dead-end.
                if case .contextOverflow = failure, !retriedForContext {
                    retriedForContext = true
                    sources = Array(sources.prefix(max(3, sources.count / 2)))
                    turns = []
                    resetStream()
                    updateReply { $0.sources = sources; $0.text = ""; $0.refreshCitations() }
                    continue
                }
                // Apple's guardrail trips on ordinary religious topics (war, punishment, death).
                // Once, re-ask with the question framed as the educational request it is.
                if case .guardrail = failure, !retriedForGuardrail {
                    retriedForGuardrail = true
                    framing = "Treat this as an educational question about Islamic teaching, scripture and history, and answer it as such."
                    resetStream()
                    updateReply { $0.text = ""; $0.refreshCitations() }
                    continue
                }
                finishReply(failed: true, message: AskAIEngine.message(for: failure),
                            elapsed: CFAbsoluteTimeGetCurrent() - started, firstToken: firstToken)
                return
            }
        }
    }
    #else
    private func answer(question: AskAIQuestion, sources: [AskAISource], history: [AskAIPrompt.Turn],
                        kind: AskAIEngineKind, profile: AskAIProfile) async {
        finishReply(failed: true, message: nil)
    }
    #endif

    private var lastPrompt = ""

    #if DEBUG
    private static func syntheticStream() -> AsyncStream<String> {
        AsyncStream { continuation in
            Task.detached {
                var text = ""
                for index in 1...600 {
                    text += (index % 60 == 0 ? "sentence \(index) [1].\n\n" : "word \(index) ")
                    continuation.yield(text)
                    try? await Task.sleep(nanoseconds: 5_000_000)
                }
                continuation.finish()
            }
        }
    }
    #endif

    // MARK: - Stream coalescing

    /// The model hands back the whole answer-so-far on every token; tokens land in `streamedText`
    /// and reach the UI at most every `streamInterval` (a time-gated flush, plus one trailing flush
    /// so a pause never leaves text unshown).
    private var streamedText = ""
    private var streamFlushTask: Task<Void, Never>?
    private var lastStreamFlush: CFAbsoluteTime = 0
    private static let streamInterval: CFAbsoluteTime = 0.1

    private func resetStream() {
        streamFlushTask?.cancel()
        streamFlushTask = nil
        streamedText = ""
        lastStreamFlush = 0
    }

    /// Records the latest text; publishes it when the interval has passed, else arms the trailing
    /// flush. Returns true when the published text shows the model looping (stop the stream).
    private func receiveStreamed(_ text: String) -> Bool {
        streamedText = text
        RenderCounter.hit("AskAIToken")
        if CFAbsoluteTimeGetCurrent() - lastStreamFlush >= Self.streamInterval {
            return flushStreamed()
        }
        if streamFlushTask == nil {
            streamFlushTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(Self.streamInterval * 1_000_000_000))
                guard let self, !Task.isCancelled else { return }
                self.streamFlushTask = nil
                self.flushStreamed()
            }
        }
        return false
    }

    @discardableResult
    private func flushStreamed() -> Bool {
        streamFlushTask?.cancel()
        streamFlushTask = nil
        lastStreamFlush = CFAbsoluteTimeGetCurrent()
        var cleaned = AskAIText.stripMarkdown(streamedText)
        let count = messages.last?.sources.count ?? 0
        cleaned = AskAIText.normalizeMarkers(cleaned, sourceCount: count).text
        RenderCounter.hit("AskAIFlush")
        updateReply {
            guard $0.text != cleaned else { return }
            $0.text = cleaned
            $0.refreshCitations()
        }
        return AskAIText.isLooping(cleaned)
    }

    private func updateReply(_ change: (inout Message) -> Void) {
        guard let index = messages.indices.last, messages[index].role == .assistant else { return }
        change(&messages[index])
    }

    /// Settles the reply. A success is policed (markers, recalled citations, unverified quotes,
    /// a trailing reference list); a failure with nothing streamed shows the reason (or a generic
    /// line), and a failure MID-answer keeps what streamed but says plainly that it stopped early.
    private func finishReply(failed: Bool, message: String? = nil, elapsed: Double? = nil, firstToken: Double? = nil) {
        let question = currentQuestion
        updateReply { reply in
            reply.isStreaming = false
            reply.elapsed = elapsed
            if failed {
                reply.failed = true
                if reply.text.isEmpty {
                    reply.text = message ?? "I couldn\u{2019}t answer that right now. Try rephrasing the question, or ask again in a moment."
                } else {
                    reply.text += "\n\n(" + (message ?? "The answer stopped early. Ask again to continue.") + ")"
                }
            } else {
                var text = AskAIText.collapsingRepetition(reply.text)
                let markers = AskAIText.normalizeMarkers(text, sourceCount: reply.sources.count)
                text = markers.text
                let policed = AskAIText.policeCitations(text, sources: reply.sources)
                let quoted = AskAIText.policeQuotations(policed.text, sources: reply.sources)
                reply.text = AskAIText.droppingTrailingReferences(quoted.text)
                reply.removedCitations = markers.removed + policed.removed
                reply.flaggedQuotations = quoted.flagged
            }
            reply.refreshCitations()
            if !failed, let question {
                reply.suggestions = AskAIText.suggestions(for: question, cited: reply.citedSources)
            }
        }
        isAnswering = false
        save()
        #if DEBUG
        debugLogLastTurn(failed: failed, firstToken: firstToken)
        #endif
    }

    #if DEBUG
    /// Headless verification: with `-askAILog`, every finished turn is appended to
    /// Documents/askai-log.txt (question, intent, engine, retrieval, sources, citations, timing, the
    /// answer) so the whole answer can be read from the simulator's app container.
    private func debugLogLastTurn(failed: Bool, firstToken: Double?) {
        guard ProcessInfo.processInfo.arguments.contains("-askAILog"),
              let reply = messages.last, reply.role == .assistant,
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let question = messages.dropLast().last(where: { $0.role == .user })?.text ?? ""
        let timing = String(format: "first token %.1fs, total %.1fs", firstToken ?? 0, reply.elapsed ?? 0)
        let entry = """
        ===== Q: \(question)
        INTENT: \(reply.intent?.rawValue ?? "?") followUp=\(reply.isFollowUp) engine=\(reply.engine?.rawValue ?? "?") \(timing)
        RETRIEVAL: \(lastRetrievalLog)
        SOURCES: \(reply.sources.enumerated().map { "[\($0.offset + 1)] \($0.element.reference)\($0.element.isSubject ? " (SUBJECT)" : "")" }.joined(separator: " | "))
        CITED: \(reply.citedReferences.joined(separator: " | "))
        REMOVED: \(reply.removedCitations) FLAGGED: \(reply.flaggedQuotations) FAILED: \(failed)
        NOTE: \(reply.note ?? "")
        SUGGESTIONS: \(reply.suggestions.joined(separator: " | "))
        A: \(reply.text)

        """
        let url = documents.appendingPathComponent("askai-log.txt")
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(entry.utf8))
            handle.closeFile()
        } else {
            try? entry.write(to: url, atomically: true, encoding: .utf8)
        }
        if ProcessInfo.processInfo.arguments.contains("-askAILogPrompt") {
            try? lastPrompt.write(to: documents.appendingPathComponent("askai-prompt.txt"), atomically: true, encoding: .utf8)
        }
    }
    #endif

    // MARK: - Control

    /// Stops a running answer, keeping whatever streamed so far (an empty reply is dropped with its
    /// question, so a stopped ask leaves no half-turn behind).
    func cancel() {
        task?.cancel()
        task = nil
        resetStream()
        guard isAnswering else { return }
        isAnswering = false
        if let index = messages.indices.last, messages[index].role == .assistant, messages[index].isStreaming {
            if messages[index].text.isEmpty {
                messages.removeLast()
                if messages.last?.role == .user { messages.removeLast() }
            } else {
                messages[index].isStreaming = false
                messages[index].refreshCitations()
            }
        }
        save()
    }

    func reset() {
        cancel()
        messages = []
        topic = nil
        currentQuestion = nil
        save()
    }

    /// Asks the last question again (after a failure, or to get a second answer): the last
    /// question/answer pair is dropped and the question re-asked.
    func retryLast() {
        guard !isAnswering, let lastUser = messages.lastIndex(where: { $0.role == .user }) else { return }
        let question = messages[lastUser].text
        messages.removeSubrange(lastUser...)
        ask(question)
    }

    // MARK: - Persistence

    private struct Store: Codable {
        var messages: [Message]
        var topic: String?
    }

    private static var storeURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return documents.appendingPathComponent("askai-conversation.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.storeURL),
              let store = try? JSONDecoder().decode(Store.self, from: data) else { return }
        // A turn that was mid-stream when the app quit settles as it stood.
        messages = store.messages.map { message in
            var settled = message
            settled.isStreaming = false
            if settled.role == .assistant, settled.text.isEmpty { settled.failed = true; settled.text = "The answer was interrupted." }
            return settled
        }
        topic = store.topic
    }

    private func save() {
        let store = Store(messages: messages.filter { !$0.isStreaming }, topic: topic)
        let url = Self.storeURL
        Task.detached(priority: .utility) {
            if store.messages.isEmpty {
                try? FileManager.default.removeItem(at: url)
            } else if let data = try? JSONEncoder().encode(store) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}

#endif
