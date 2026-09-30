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
    /// The topic as the reader typed it, for the suggestion chips of a follow-up.
    private var topicDisplay: String?
    private var currentQuestion: AskAIQuestion?
    /// The earlier answers of this conversation, for the echo guard of the turn in flight.
    private var echoGuard = AskAIText.EchoGuard(previousAnswers: [])
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
            topicDisplay = question.topicDisplay
        }
        currentQuestion = question
        // A recap or a source question reworks the previous answer on purpose ("say it again"
        // reproduces its paragraphs), so it gets an empty guard: the echo guard erased the whole
        // reply and left "Thinking..." on screen for good.
        echoGuard = question.intent == .recap || question.intent == .sourceQuestion
            ? AskAIText.EchoGuard(previousAnswers: [])
            : AskAIText.EchoGuard(previousAnswers: messages.filter { $0.role == .assistant && !$0.failed }.suffix(4).map(\.text))
        // A long session keeps its most recent turns in memory (the transcript on screen, and what
        // is saved); the prompt only ever re-sends the last few anyway.
        if messages.count > Self.keptMessages { messages.removeFirst(messages.count - Self.keptMessages) }
        #if HAS_QURAN
        if AskAIText.surahNameTokens.isEmpty, !QuranData.shared.quran.isEmpty {
            var tokens = Set<String>()
            for surah in QuranData.shared.quran {
                for word in AskAILexicon.fold(surah.nameTransliteration).split(separator: " ") where word.count >= 3 {
                    tokens.insert(String(word))
                }
            }
            AskAIText.surahNameTokens = tokens
        }
        #endif

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
            var history = history
            if question.intent == .sourceQuestion || question.intent == .recap {
                // About the previous answer, or a rework of it: the sources it cited (all of them
                // only when it cited none), nothing new. They are renumbered by first appearance,
                // so the previous answer, which the prompt re-sends, has its markers renumbered to
                // match: its "[3]...[1]" became sources [C, A], and the old [1] then showed card C.
                let previousSources = previousReply?.sources ?? []
                let cited = previousReply?.citedSources ?? []
                sources = Array((cited.isEmpty ? previousSources : cited).prefix(profile.sourceLimit))
                var renumbered: [Int: Int] = [:]
                for (old, source) in previousSources.enumerated() {
                    if let new = sources.firstIndex(where: { $0.reference == source.reference }) { renumbered[old + 1] = new + 1 }
                }
                if let last = history.indices.last {
                    history[last] = AskAIPrompt.Turn(question: history[last].question,
                                                     answer: AskAIText.renumberingMarkers(history[last].answer, map: renumbered),
                                                     keepsMarkers: true)
                }
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
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                let fitted = AskAIPrompt.fit(sources: sources, history: history, profile: profile, intent: question.intent)
                if fitted.count < sources.count { retrievalLog += "; fitted to \(fitted.count) sources" }
                sources = fitted
            }
            #endif
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
        var guardrailRetries = 0
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
                // Apple's guardrail trips on ordinary religious topics (war, punishment, death),
                // and on a retrieved passage as often as on the question. First re-ask with the
                // question framed as the educational request it is and fewer sources; then once
                // more with no sources and no history, so the reader gets an answer rather than a
                // refusal, and is told the sources were left out.
                if case .guardrail = failure, guardrailRetries < 2 {
                    guardrailRetries += 1
                    framing = "Treat this as an educational question about Islamic teaching, scripture and history, and answer it as such."
                    if guardrailRetries == 1 {
                        sources = Array(sources.prefix(4))
                    } else {
                        sources = []
                        turns = []
                    }
                    resetStream()
                    updateReply {
                        $0.sources = sources; $0.text = ""; $0.refreshCitations()
                        if sources.isEmpty {
                            $0.note = "Apple Intelligence declined to read the sources the app found for this question, so this answer was written from general knowledge without them."
                        }
                    }
                    continue
                }
                #if DEBUG
                lastErrorDescription = "\(type(of: error)): \(error)"
                #endif
                // What streamed before the failure reaches the reply now: a trailing flush firing
                // after `finishReply` replaced its "(The answer stopped early...)" line.
                if !streamedText.isEmpty { flushStreamed() }
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
    /// The raw error of the last failed turn, for the `-askAILog` entry (the reader-facing message
    /// is deliberately generic; the log needs the framework's own words).
    private var lastErrorDescription = ""
    #endif

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
        cleaned = AskAIText.droppingSourceEchoes(cleaned, sources: messages.last?.sources ?? [])
        let count = messages.last?.sources.count ?? 0
        cleaned = AskAIText.normalizeMarkers(cleaned, sourceCount: count).text
        cleaned = AskAIText.capitalizing(AskAIText.replacingDashes(echoGuard.filter(cleaned)))
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
        // No flush may land after the reply settles (it would overwrite the settled text).
        resetStream()
        let question = currentQuestion
        let genericFailure = "I couldn\u{2019}t answer that right now. Try rephrasing the question, or ask again in a moment."
        updateReply { reply in
            reply.isStreaming = false
            reply.elapsed = elapsed
            if failed {
                reply.failed = true
                if reply.text.isEmpty {
                    reply.text = message ?? genericFailure
                } else {
                    reply.text += "\n\n(" + (message ?? "The answer stopped early. Ask again to continue.") + ")"
                }
            } else {
                var text = AskAIText.collapsingRepetition(echoGuard.filter(AskAIText.droppingSourceEchoes(reply.text, sources: reply.sources)))
                let markers = AskAIText.normalizeMarkers(text, sourceCount: reply.sources.count)
                text = markers.text
                let policed = AskAIText.policeCitations(text, sources: reply.sources)
                let quoted = AskAIText.policeQuotations(policed.text, sources: reply.sources)
                reply.text = AskAIText.capitalizing(AskAIText.replacingDashes(AskAIText.droppingTrailingReferences(quoted.text)))
                reply.removedCitations = markers.removed + policed.removed
                reply.flaggedQuotations = quoted.flagged
                // Nothing left once policed (an empty stream, or every paragraph an echo): a
                // failure the reader can retry, never an empty card reading "Thinking..." forever.
                if reply.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    reply.failed = true
                    reply.text = genericFailure
                    reply.removedCitations = 0
                    reply.flaggedQuotations = 0
                }
            }
            reply.refreshCitations()
            if !reply.failed, let question {
                reply.suggestions = AskAIText.suggestions(for: question, cited: reply.citedSources, conversationTopic: topicDisplay)
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
        ERROR: \(failed ? lastErrorDescription : "")
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
        cancel(saving: true)
    }

    /// `saving: false` is for `reset()`, which saves the empty transcript itself: two saves raced,
    /// and the old transcript's write could land after the removal and come back next launch.
    private func cancel(saving: Bool) {
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
        if saving { save() }
    }

    func reset() {
        cancel(saving: false)
        messages = []
        topic = nil
        topicDisplay = nil
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

        init(messages: [Message], topic: String?) {
            self.messages = messages
            self.topic = topic
        }

        /// Lenient: a message that no longer decodes is dropped, not the whole transcript.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            messages = (try container.decodeIfPresent([Lossy<Message>].self, forKey: .messages) ?? []).compactMap(\.value)
            topic = try container.decodeIfPresent(String.self, forKey: .topic)
        }
    }

    /// One element of a list that decodes to nil instead of failing the list.
    private struct Lossy<Value: Decodable>: Decodable {
        let value: Value?
        init(from decoder: Decoder) throws {
            value = try? Value(from: decoder)
        }
    }

    /// The most recent messages kept (in memory and on disk): twenty turns.
    private static let keptMessages = 40
    /// A saved source's text, clipped: every answer stored its sources whole (a full Ibn Kathir
    /// entry each), and the transcript loads on the main thread when the chat opens.
    private static let savedSourceCharacters = 2_400

    private static var storeURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return documents.appendingPathComponent("askai-conversation.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.storeURL) else { return }
        let store: Store
        do {
            store = try JSONDecoder().decode(Store.self, from: data)
        } catch {
            // Never let the next save overwrite a transcript this build cannot read.
            UserDataRescue.quarantine(file: Self.storeURL, error: error)
            return
        }
        // A turn that was mid-stream when the app quit settles as it stood.
        messages = store.messages.map { message in
            var settled = message
            settled.isStreaming = false
            if settled.role == .assistant, settled.text.isEmpty { settled.failed = true; settled.text = "The answer was interrupted." }
            return settled
        }
        topic = store.topic
    }

    /// Saves run one at a time, in the order they were asked for: as separate detached tasks, the
    /// old transcript's write could land after "New Conversation" removed the file.
    private static let saveQueue = DispatchQueue(label: "AskAIConversation.save", qos: .utility)

    private func save() {
        let kept = messages.filter { !$0.isStreaming }.suffix(Self.keptMessages).map { message -> Message in
            var clipped = message
            clipped.sources = message.sources.map { source in
                guard source.text.count > Self.savedSourceCharacters else { return source }
                return AskAISource(kind: source.kind, reference: source.reference, title: source.title,
                                   text: AskAISource.clip(source.text, to: Self.savedSourceCharacters),
                                   arabic: source.arabic, transliteration: source.transliteration,
                                   provenance: source.provenance, aliases: source.aliases,
                                   maxCharacters: source.maxCharacters, isSubject: source.isSubject)
            }
            return clipped
        }
        let store = Store(messages: Array(kept), topic: topic)
        let url = Self.storeURL
        Self.saveQueue.async {
            if store.messages.isEmpty {
                try? FileManager.default.removeItem(at: url)
            } else if let data = try? JSONEncoder().encode(store) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}

extension AskAIConversation.Message {
    /// Lenient: a field one build adds (or another drops) takes its default instead of failing the
    /// whole transcript. A required field the committed build had never written failed every saved
    /// conversation, and the next save then overwrote it.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        role = try container.decode(AskAIConversation.Role.self, forKey: .role)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        sources = (try? container.decodeIfPresent([AskAISource].self, forKey: .sources)) ?? []
        isStreaming = try container.decodeIfPresent(Bool.self, forKey: .isStreaming) ?? false
        failed = try container.decodeIfPresent(Bool.self, forKey: .failed) ?? false
        removedCitations = try container.decodeIfPresent(Int.self, forKey: .removedCitations) ?? 0
        flaggedQuotations = try container.decodeIfPresent(Int.self, forKey: .flaggedQuotations) ?? 0
        asksForRuling = try container.decodeIfPresent(Bool.self, forKey: .asksForRuling) ?? false
        // An intent or engine a later build added reads as unknown, not as a broken file.
        intent = (try? container.decodeIfPresent(AskAIIntent.self, forKey: .intent)) ?? nil
        engine = (try? container.decodeIfPresent(AskAIEngineKind.self, forKey: .engine)) ?? nil
        isFollowUp = try container.decodeIfPresent(Bool.self, forKey: .isFollowUp) ?? false
        note = try container.decodeIfPresent(String.self, forKey: .note)
        citedReferences = try container.decodeIfPresent([String].self, forKey: .citedReferences) ?? []
        suggestions = try container.decodeIfPresent([String].self, forKey: .suggestions) ?? []
        elapsed = try container.decodeIfPresent(Double.self, forKey: .elapsed)
    }
}

#endif
