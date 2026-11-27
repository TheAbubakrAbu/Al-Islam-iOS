import SwiftUI
import Foundation

// Ask AI - the running conversation, and the two before it.
//
// Every visit to the chat starts on an EMPTY conversation (Abu, 2026-11-22: "When I go to ask ai
// always make a new chat but maybe show the last 2 chats as history"): the one that was open is set
// aside as it stood, and the welcome screen lists the last two under HISTORY (the menu does too).
// Opening one makes it the conversation again, follow-ups and all. All of it is kept across launches.
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

/// What an answer may be built from, chosen above the composer (Abu, 2026-11-24: "add specific filters
/// like hey I want u to specifically look at Quran or Hadith or whatever"). Everything is the app's whole
/// library, as before; any other choice keeps only that library's sources (`admits`), searches it deeper,
/// and tells the model to answer from it alone (`promptLine`). Kept between visits.
enum AskAIScope: String, CaseIterable, Identifiable, Codable {
    case everything, quran, hadith, articles, duas, prayerTimes

    var id: String { rawValue }

    /// The choices this app can answer from: each library only where it ships.
    static var available: [AskAIScope] {
        allCases.filter { $0.ships }
    }

    private var ships: Bool {
        switch self {
        case .quran:
            #if HAS_QURAN
            return true
            #else
            return false
            #endif
        case .hadith:
            #if HAS_HADITH
            return true
            #else
            return false
            #endif
        case .prayerTimes:
            #if HAS_ADHAN
            return true
            #else
            return false
            #endif
        case .everything, .articles, .duas:
            return true
        }
    }

    var title: String {
        switch self {
        case .everything: return String(localized: "Everything")
        case .quran: return String(localized: "Quran")
        case .hadith: return String(localized: "Hadith")
        case .articles: return String(localized: "Articles")
        case .duas: return String(localized: "Duas & Dhikr")
        case .prayerTimes: return String(localized: "Prayer Times")
        }
    }

    /// What the choice searches, in a line.
    var detail: String {
        switch self {
        case .everything: return String(localized: "The whole library, in one answer")
        case .quran: return String(localized: "Verses, with their tafsir")
        case .hadith: return String(localized: "The collections, with explanations")
        case .articles: return String(localized: "Guides, beliefs and how-tos")
        case .duas: return String(localized: "Supplications and the 99 Names")
        case .prayerTimes: return String(localized: "Any city, any day")
        }
    }

    /// The tabs' own symbols for the two libraries (`OpenInTab`), so the choice reads as that tab.
    var systemImage: String {
        switch self {
        case .everything: return "sparkles"
        case .quran: return "character.book.closed.ar"
        case .hadith: return "books.vertical"
        case .articles: return "doc.text"
        case .duas: return "hands.and.sparkles"
        case .prayerTimes: return "clock"
        }
    }

    /// Whether a source of this kind may stand behind the answer.
    func admits(_ kind: AskAISource.Kind) -> Bool {
        switch (self, kind) {
        case (.everything, _): return true
        case (.quran, .ayah), (.quran, .tafsir), (.quran, .surah): return true
        case (.hadith, .hadith): return true
        case (.articles, .article): return true
        case (.duas, .dua), (.duas, .hisnDua), (.duas, .name): return true
        case (.prayerTimes, .prayer), (.prayerTimes, .cityPrayer): return true
        default: return false
        }
    }

    /// What the model is told about the choice, after its task.
    var promptLine: String? {
        switch self {
        case .everything, .prayerTimes: return nil
        case .quran: return "The reader chose to search the Quran only: answer from the Quran and tafsir sources alone. If they do not answer the question, say that the verses found do not address it; do not draw on anything else."
        case .hadith: return "The reader chose to search the hadith only: answer from the hadith sources alone. If they do not answer the question, say that the hadiths found do not address it; do not draw on anything else."
        case .articles: return "The reader chose to search this app\u{2019}s articles only: answer from the article sources alone. If they do not answer the question, say so; do not draw on anything else."
        case .duas: return "The reader chose to search the duas and the Names of Allah only: answer from those sources alone, giving the words of a dua as its source has them. If they do not answer the question, say so."
        }
    }

    /// Four questions to start with, in the choice's own library (English keys, shown through the catalog).
    var starters: [String] {
        switch self {
        case .everything: return AskAIStarters.today()
        case .quran: return ["What does the Quran say about patience in hardship?", "Explain Ayat al-Kursi",
                             "Why is Surah Al-Kahf read on Fridays?", "What does the Quran say about parents?"]
        case .hadith: return ["What did the Prophet say about kindness to parents?", "What is the hadith of Jibril about?",
                              "What did the Prophet say about anger?", "What are the virtues of Friday in the hadith?"]
        case .articles: return ["How do I perform wudu?", "What is the difference between zakat and sadaqah?",
                                "What are the six pillars of iman?", "How do I make up a missed prayer?"]
        case .duas: return ["Is there a dua for anxiety?", "What should I say before sleeping?",
                            "What is the dua for leaving home?", "What does Al-Wadud mean?"]
        case .prayerTimes:
            // Eight, four a day: two about the day's times and two about what else the app works
            // out (the calendar, the qibla, the night), a different pair of each every day.
            let times = ["What time is Fajr tomorrow?", "When is Maghrib in Makkah today?",
                         "What are the prayer times in London on Friday?", "How long until Asr?"]
            let more = ["When is Ramadan?", "Which way is the qiblah?", "What is the Hijri date today?",
                        "When does the last third of the night begin?"]
            let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            return [times[day % 4], more[day % 4], times[(day + 1) % 4], more[(day + 1) % 4]]
        }
    }
}

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
        /// Apple Intelligence declined to write the answer: a failure whose sources stay on show,
        /// since the reader can still read them.
        var declined = false
        /// Citation markers and recalled references removed at the end of the turn, disclosed
        /// beneath the answer.
        var removedCitations = 0
        /// Quotations that matched no source's wording and were marked "(wording not verified)".
        var flaggedQuotations = 0
        /// The question asked for a ruling: the reply carries the sterner caution.
        var asksForRuling = false
        /// What the turn was asked to answer from (`AskAIScope`); nil for everything.
        var scope: AskAIScope? = nil
        var intent: AskAIIntent? = nil
        var engine: AskAIEngineKind? = nil
        var isFollowUp = false
        /// A note the turn earned ("Private Cloud Compute was unavailable, so..."), shown under it.
        var note: String? = nil
        /// The turn is a crisis reply, or a question about suicide or self-harm: the help line is
        /// offered as a thing to tap (`AskAICrisis.helpLineAction`), not only read.
        var offersHelpLine = false
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

        /// The card shows the model's prose: an answer, or a failure that streamed prose before its
        /// failure line (the sources are there to cite). A bare failure message is not prose, and
        /// gets no AI caution.
        var hasAnswerProse: Bool {
            !failed || (!sources.isEmpty && text.contains("\n\n("))
        }

        mutating func refreshCitations() {
            citedReferences = AskAIText.citedSources(in: text, sources: sources).map(\.reference)
        }
    }

    /// A conversation set aside when a new one began: one row of the chat's History.
    struct SavedChat: Identifiable, Codable {
        var id = UUID()
        var messages: [Message]
        /// The subject a bare follow-up would search with, kept so the conversation can go on.
        var topic: String?
        /// When it was last added to.
        var updated: Date

        /// What History calls it: its first question.
        var title: String { messages.first(where: { $0.role == .user })?.text ?? "" }

        init(id: UUID = UUID(), messages: [Message], topic: String?, updated: Date) {
            self.id = id
            self.messages = messages
            self.topic = topic
            self.updated = updated
        }

        /// Lenient, like the transcript itself: a message that no longer decodes is dropped alone.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            messages = (try container.decodeIfPresent([Lossy<Message>].self, forKey: .messages) ?? []).compactMap(\.value)
            topic = try container.decodeIfPresent(String.self, forKey: .topic)
            updated = try container.decodeIfPresent(Date.self, forKey: .updated) ?? Date()
        }
    }

    /// How many earlier conversations History keeps.
    nonisolated static let recentChatLimit = 2

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isAnswering = false
    /// The conversations before this one, newest first, at most `recentChatLimit`.
    @Published private(set) var recentChats: [SavedChat] = []
    /// The open conversation's identity (a conversation reopened from History keeps the one it had)
    /// and when it was last added to.
    private var chatID = UUID()
    private var lastActivity = Date()
    /// The engine the reader chose. Mirrors `AskAIEngine.preferred`; a cloud choice only takes
    /// effect while the cloud model is on offer.
    @Published var engineKind: AskAIEngineKind {
        didSet { UserDefaults.standard.set(engineKind.rawValue, forKey: "askAIEngine") }
    }
    /// What the next question is answered from (`AskAIScope`), kept between visits.
    @Published var scope: AskAIScope {
        didSet { UserDefaults.standard.set(scope.rawValue, forKey: "askAIScope") }
    }
    /// The scope of the turn in flight, for its prompt.
    private var turnScope: AskAIScope = .everything

    /// The conversation's current subject (the last standalone question's content words): what a
    /// bare follow-up searches with.
    private(set) var topic: String?
    /// The topic as the reader typed it, for the suggestion chips of a follow-up.
    private var topicDisplay: String?
    private var currentQuestion: AskAIQuestion?
    /// The article the chat was opened from (an article page's Ask AI button): every question asked
    /// while it is set also reads that article's sections (`AskAIRetriever.retrieve(focus:)`). Set by
    /// the chat screen as it appears and cleared as it goes, so the Islam tab's Ask AI asks unfocused.
    var focusArticle: IslamArticle?
    /// The earlier answers of this conversation, for the echo guard of the turn in flight.
    private var echoGuard = AskAIText.EchoGuard(previousAnswers: [])
    private var task: Task<Void, Never>?

    private init() {
        engineKind = AskAIEngineKind(rawValue: UserDefaults.standard.string(forKey: "askAIEngine") ?? "") ?? .onDevice
        let savedScope = AskAIScope(rawValue: UserDefaults.standard.string(forKey: "askAIScope") ?? "") ?? .everything
        scope = AskAIScope.available.contains(savedScope) ? savedScope : .everything
        #if DEBUG
        // "-askAIReset": start from an empty transcript (the headless batches must not inherit an
        // earlier run's conversation as history).
        if ProcessInfo.processInfo.arguments.contains("-askAIReset") {
            try? FileManager.default.removeItem(at: Self.storeURL)
        }
        #endif
        load()
        // "Erase Everything" deletes the saved transcript (`Settings.deviceOnlyDocumentFiles`); the
        // one in memory goes with it, or the next answer would write the erased conversation back.
        NotificationCenter.default.addObserver(
            forName: Settings.contentErasedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.eraseEverything() }
        }
    }

    // MARK: - History

    /// `recents` with `chat` set aside at its head: the newest first, at most `limit`, a
    /// conversation never listed twice, and one with no question in it not listed at all.
    nonisolated static func filing(_ chat: SavedChat, into recents: [SavedChat], limit: Int = recentChatLimit) -> [SavedChat] {
        guard chat.messages.contains(where: { $0.role == .user }) else { return recents }
        return Array(([chat] + recents.filter { $0.id != chat.id }).prefix(limit))
    }

    /// The chat screen is opening: the visit starts on an empty conversation, and the one that was
    /// open goes to History. Two visits carry on instead: one that finds an answer still being
    /// written (the reader came back to it), and a search screen's sheet reopened on the query it
    /// already asked (`question`), which shows that conversation rather than asking it twice.
    func beginVisit(asking question: String? = nil) {
        guard !isAnswering else { return }
        if let question, !question.isEmpty, messages.last(where: { $0.role == .user })?.text == question { return }
        startNewChat()
    }

    /// Sets the open conversation aside under History and opens an empty one. Nothing is lost but
    /// the oldest of the kept conversations.
    func startNewChat() {
        cancel(saving: false)
        setAsideOpenChat()
        save()
    }

    /// Makes a conversation from History the open one again (the open one takes its place there).
    func openRecent(_ id: UUID) {
        guard let chosen = recentChats.first(where: { $0.id == id }) else { return }
        cancel(saving: false)
        recentChats.removeAll { $0.id == id }
        setAsideOpenChat()
        chatID = chosen.id
        messages = chosen.messages
        topic = chosen.topic
        topicDisplay = chosen.topic
        lastActivity = chosen.updated
        save()
    }

    func deleteRecent(_ id: UUID) {
        guard recentChats.contains(where: { $0.id == id }) else { return }
        recentChats.removeAll { $0.id == id }
        save()
    }

    /// The open conversation into `recentChats`, and a fresh one in its place (not saved here).
    private func setAsideOpenChat() {
        recentChats = Self.filing(SavedChat(id: chatID, messages: messages, topic: topic, updated: lastActivity), into: recentChats)
        messages = []
        topic = nil
        topicDisplay = nil
        currentQuestion = nil
        chatID = UUID()
        lastActivity = Date()
    }

    /// "Erase Everything": the open conversation and History both.
    private func eraseEverything() {
        cancel(saving: false)
        recentChats = []
        messages = []
        topic = nil
        topicDisplay = nil
        currentQuestion = nil
        chatID = UUID()
        save()
    }

    // MARK: - Turns

    /// The completed question/answer pairs so far, oldest first: what a new turn is re-grounded on.
    /// A crisis turn (the app's own reply, `AskAICrisis`) ends the thread: nothing before it or of
    /// it is history, so a "why?" after it cannot continue the earlier subject, and the model never
    /// sees the app's words as something it said.
    func completedTurns() -> [AskAIPrompt.Turn] { Self.completedTurns(in: messages) }

    nonisolated static func completedTurns(in messages: [Message]) -> [AskAIPrompt.Turn] {
        var turns: [AskAIPrompt.Turn] = []
        var pendingQuestion: String?
        for message in messages.suffix(from: threadStart(of: messages)) {
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

    /// The last finished answer the next turn may carry sources from; none across a crisis turn.
    nonisolated static func previousReply(in messages: [Message]) -> Message? {
        messages.suffix(from: threadStart(of: messages))
            .last(where: { $0.role == .assistant && !$0.failed && !$0.text.isEmpty && $0.intent != .crisis })
    }

    /// The index after the last crisis reply (the start of the live thread), or 0.
    nonisolated private static func threadStart(of messages: [Message]) -> Int {
        guard let last = messages.lastIndex(where: { $0.role == .assistant && $0.intent == .crisis }) else { return 0 }
        return last + 1
    }

    func ask(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // A first-person crisis needs no model and no library: the app replies itself, before the
        // availability guard (a device without Apple Intelligence still gets the help line).
        if AskAICrisis.isCrisis(trimmed) {
            answerCrisis(trimmed)
            return
        }
        guard OnDeviceAsk.isAvailable else { return }
        cancel()
        lastActivity = Date()
        helpLineForCurrentTurn = AskAICrisis.mentionsSelfHarm(trimmed)
            ? AskAICrisis.helpLine(regionCode: Locale.current.region?.identifier) : nil
        let history = completedTurns()
        let focus = focusArticle
        let previousReply = Self.previousReply(in: messages)
        var question = AskAIQuestion.analyze(trimmed, previousTopic: topic, hasHistory: !history.isEmpty)
        let scope = AskAIScope.available.contains(self.scope) ? self.scope : .everything
        turnScope = scope
        // Prayer Times chosen: every question that searches is a question about the times ("and in
        // Paris?" included), answered from the timetable alone.
        if scope == .prayerTimes, question.intent.retrieves, question.intent != .appHelp {
            question = question.with(intent: .prayerTimes)
        }
        #if HAS_ADHAN
        // A follow-up to a prayer-times answer that names a place, a day or a prayer is about the
        // times too. Read as a general question, "And in Cairo?" searched the library, found no
        // timetable, and the model made a time up (2026-11-25).
        let afterPrayerTimes = previousReply?.intent == .prayerTimes && question.isFollowUp
        if afterPrayerTimes, question.intent != .prayerTimes, question.intent.retrieves, question.intent != .appHelp,
           AskAIPrayerRequest.parse(trimmed).continuesPrayerTalk {
            question = question.with(intent: .prayerTimes)
        }
        let previousPrayer = afterPrayerTimes ? lastPrayerRequest : nil
        #endif
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

        var asked = Message(role: .user, text: trimmed)
        asked.scope = scope == .everything ? nil : scope
        messages.append(asked)
        var reply = Message(role: .assistant, text: "", isStreaming: true)
        reply.scope = asked.scope
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
            var passageSources = 0
            var closeSecond = false
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
                #if HAS_ADHAN
                let outcome = await AskAIRetriever.retrieve(question, budget: profile.retrievalBudget,
                                                            carried: previousReply?.sources ?? [],
                                                            carriedCited: previousReply?.citedSources ?? [],
                                                            focus: focus, scope: scope, previousPrayer: previousPrayer)
                if let asked = outcome.prayerRequest { lastPrayerRequest = asked }
                #else
                let outcome = await AskAIRetriever.retrieve(question, budget: profile.retrievalBudget,
                                                            carried: previousReply?.sources ?? [],
                                                            carriedCited: previousReply?.citedSources ?? [],
                                                            focus: focus, scope: scope)
                #endif
                sources = outcome.sources
                passageSources = outcome.passageSources
                closeSecond = outcome.hasCloseSecond
                retrievalLog = String(format: "%.0f ms; lanes ", outcome.elapsed * 1000)
                    + outcome.laneCounts.map { "\($0.key.rawValue)=\($0.value)" }.sorted().joined(separator: " ")
                    + "; ranking " + outcome.ranking.prefix(16).map { String(format: "%@ %.2f", $0.reference, $0.score) }.joined(separator: " | ")
                if !outcome.described.isEmpty { retrievalLog += "; described " + outcome.described.joined(separator: " | ") }
            }
            guard !Task.isCancelled else { return }
            #if DEBUG
            // "-askAIRetrieveOnly": the turn ends once its sources are found, so a list of questions
            // can be scored on what the search brings back in seconds (no model, no answer).
            if ProcessInfo.processInfo.arguments.contains("-askAIRetrieveOnly") {
                updateReply { $0.sources = sources; $0.refreshCitations() }
                lastRetrievalLog = retrievalLog
                resetStream()
                streamedText = "(retrieval only)"
                flushStreamed()
                finishReply(failed: false, elapsed: 0, firstToken: nil)
                return
            }
            #endif
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                let fitted = await AskAIPrompt.fit(question: question, sources: sources, history: history, profile: profile,
                                                   measure: AskAIEngine.tokenCounter)
                if fitted.count < sources.count { retrievalLog += "; fitted to \(fitted.count) sources" }
                retrievalLog += "; window=\(AskAIEngine.onDeviceContextTokens) instructions=\(AskAIEngine.instructionTokens)"
                sources = fitted
            }
            #endif
            updateReply { $0.sources = sources; $0.refreshCitations() }
            lastRetrievalLog = retrievalLog
            #if HAS_ADHAN
            // A run of days is a table, and the app has it exact: it is set down as it stands. Asked
            // to write a week out, the model gave the first day's times and called it the week
            // (2026-11-25).
            // Two or three places compared: one timetable each, and the answer is the line of each
            // that was asked for, side by side. (Two timetables in one prompt is two places and two
            // days for the model to keep apart; the app has every time exact.)
            if question.intent == .prayerTimes, sources.count >= 2,
               sources.allSatisfy({ if case .cityPrayer = $0.kind { return true } else { return false } }) {
                let wanted = lastPrayerRequest?.prayers ?? []
                let lines = sources.enumerated().map { index, source -> String in
                    let times = source.text.components(separatedBy: "\n").dropFirst().filter { line in
                        line.range(of: #"^[A-Z][A-Za-z\u{2019}' ]+ \d{1,2}:\d{2}"#, options: .regularExpression) != nil
                    }
                    let asked = wanted.isEmpty ? times : times.filter { line in wanted.contains { line.hasPrefix($0 + " ") } }
                    return "\(source.reference) [\(index + 1)]: " + (asked.isEmpty ? times : asked).joined(separator: ", ")
                }
                resetStream()
                streamedText = lines.joined(separator: "\n\n") + "\n\nEach is in that place\u{2019}s own local time."
                flushStreamed()
                finishReply(failed: false, elapsed: 0, firstToken: nil)
                return
            }
            // The reader's own Prayer Tracker, and where a prayer's time stands: the app's facts, in
            // the app's words (`AskAISource.appAnswer`).
            if question.intent == .prayerTimes, sources.count == 1, let written = sources.first?.appAnswer, !written.isEmpty {
                resetStream()
                streamedText = written + " [1]"
                flushStreamed()
                finishReply(failed: false, elapsed: 0, firstToken: nil)
                return
            }
            if question.intent == .prayerTimes, lastPrayerRequest?.topics.contains(.week) == true, sources.count == 1,
               let table = sources.first, case .cityPrayer = table.kind, let firstBreak = table.text.firstIndex(of: "\n") {
                resetStream()
                streamedText = "\(table.reference) [1]:\n" + table.text[table.text.index(after: firstBreak)...]
                flushStreamed()
                finishReply(failed: false, elapsed: 0, firstToken: nil)
                return
            }
            #endif
            // A passage the reader described: found, the app sets down where it is and its words
            // itself and the model explains it; not found, the model is told to say so.
            var passage: PassageAnswer?
            if question.findsPassage {
                // Fitting may have trimmed the list; the passage is its head or it is nothing.
                let found = passageSources > 0 && sources.count >= passageSources
                passage = found ? PassageAnswer(sources: sources, count: passageSources, quotesSecond: closeSecond)
                    : PassageAnswer(missed: ())
                lastRetrievalLog += found ? "; passage found (\(passageSources))" : "; passage not found"
                // Its words are quoted on purpose, whatever an earlier answer quoted.
                if found { echoGuard = AskAIText.EchoGuard(previousAnswers: []) }
            }
            await answer(question: question, sources: sources, history: history, kind: kind, profile: profile, passage: passage)
        }
    }

    /// What the app itself writes of an answer to "the verse about ...": the passage it found, by
    /// reference and in its own words, above the model's explanation, and the next matches beneath
    /// it. See `AskAIPrompt.foundTask` for why the model writes neither.
    struct PassageAnswer {
        /// "Surah At-Takwir 81:8 [1]: “...”", one paragraph per source of the passage.
        let lead: String
        /// "Also close: An-Nahl 16:58 [3], Al-An'am 6:151 [4]."
        let tail: String
        /// How many of the turn's leading sources the model is handed: the passage alone. 0 when
        /// nothing was found (the model then reads every source and says so).
        let promptSources: Int

        var finding: AskAIPrompt.Finding { promptSources > 0 ? .found : .missed }

        init(missed: Void) {
            lead = ""
            tail = ""
            promptSources = 0
        }

        /// `quotesSecond`: the source after the passage is a match the search could not tell from
        /// it, and is quoted beneath it instead of only being named.
        init(sources: [AskAISource], count: Int, quotesSecond: Bool = false) {
            func name(_ source: AskAISource) -> String {
                if case .ayah = source.kind { return "Surah " + source.title }
                return source.reference
            }
            func quoted(_ index: Int, limit: Int) -> String {
                "\(name(sources[index])) [\(index + 1)]: \u{201C}\(AskAISource.clip(sources[index].text, to: limit))\u{201D}"
            }
            lead = (0..<count).map { quoted($0, limit: 900) }.joined(separator: "\n\n") + "\n\n"
            var closing = ""
            var next = count
            if quotesSecond, sources.indices.contains(next) {
                closing += "\n\nAlso close: " + quoted(next, limit: 500)
                next += 1
            }
            let others = sources.indices.dropFirst(next).prefix(quotesSecond ? 2 : 3).map { index in
                "\(sources[index].kind.isAyah ? sources[index].title : sources[index].reference) [\(index + 1)]"
            }
            if !others.isEmpty {
                closing += "\n\n" + (quotesSecond ? "Other places to look: " : "Also close: ") + others.joined(separator: ", ") + "."
            }
            tail = closing
            promptSources = count
        }
    }

    private var lastRetrievalLog = ""
    #if DEBUG
    /// The answer as the model sent it, before the app's cleaning (`-askAILog` prints it when the two differ).
    private var lastRawAnswer = ""
    #endif

    #if HAS_ADHAN
    /// What the last prayer-times turn asked for; a follow-up straight after it inherits its place and day.
    private var lastPrayerRequest: AskAIPrayerRequest?
    #endif

    /// The help line a question ABOUT suicide or self-harm earns beneath its normal answer.
    private var helpLineForCurrentTurn: String?

    /// The crisis reply: the app's own words, finished in one hop. `isAnswering` still flips on and
    /// off, so the chat (and the headless `-askAI` queue, which advances on that flip) sees a turn.
    private func answerCrisis(_ trimmed: String) {
        cancel()
        lastActivity = Date()
        helpLineForCurrentTurn = nil
        currentQuestion = nil
        // The earlier thread is over: a "why?" after this must not continue it.
        topic = nil
        topicDisplay = nil
        messages.append(Message(role: .user, text: trimmed))
        isAnswering = true
        task = Task { @MainActor in
            guard !Task.isCancelled else { return }
            let sources = AskAICrisis.sources()
            var citesEase = false
            if case .ayah? = sources.first?.kind { citesEase = true }
            var reply = Message(role: .assistant, text: AskAICrisis.reply(citingEase: citesEase))
            reply.intent = .crisis
            reply.sources = sources
            reply.offersHelpLine = true
            reply.suggestions = AskAICrisis.suggestions
            reply.elapsed = 0
            reply.refreshCitations()
            messages.append(reply)
            lastRetrievalLog = "crisis reply, no model"
            #if DEBUG
            debugLogLastTurn(failed: false, firstToken: nil)
            #endif
            isAnswering = false
            save()
        }
    }

    #if canImport(FoundationModels)
    private func answer(question: AskAIQuestion, sources initialSources: [AskAISource], history: [AskAIPrompt.Turn],
                        kind initialKind: AskAIEngineKind, profile initialProfile: AskAIProfile,
                        passage: PassageAnswer? = nil) async {
        guard #available(iOS 26.0, *) else { finishReply(failed: true); return }
        var kind = initialKind
        var profile = initialProfile
        // A found passage is all the model reads; the reply keeps every source (the cards, and the
        // "also close" line's markers).
        let lead = passage?.lead ?? ""
        var sources = initialSources
        if let passage, passage.promptSources > 0 { sources = Array(initialSources.prefix(passage.promptSources)) }
        var turns = history
        var retriedForContext = false
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
                let found = passage?.finding == .found
                let prompt = found
                    ? AskAIPrompt.passagePrompt(sources, profile: profile)
                    : AskAIPrompt.build(question: question, sources: sources, history: turns, profile: profile,
                                        scope: turnScope, finding: passage?.finding ?? .none)
                let instructions = found ? AskAIPrompt.passageInstructions
                    : AskAIPrompt.instructions(readsQiraat: AskAIDepth.readsQiraat)
                lastPrompt = prompt
                // The passage is on screen before the model has read a word.
                if !lead.isEmpty {
                    _ = receiveStreamed(lead)
                    flushStreamed()
                }
                let options = GenerationOptions(temperature: question.intent.temperature,
                                                maximumResponseTokens: min(question.intent.maxResponseTokens, profile.responseTokenCap))
                for try await text in AskAIEngine.stream(kind: kind, instructions: instructions, prompt: prompt, options: options) {
                    guard !Task.isCancelled else { resetStream(); return }
                    if firstToken == nil { firstToken = CFAbsoluteTimeGetCurrent() - started }
                    // A small model can fall into repeating itself until the token ceiling: the
                    // moment a paragraph comes back (checked per flush), the answer is over.
                    if receiveStreamed(lead + text) { break }
                }
                guard !Task.isCancelled else { resetStream(); return }
                if let passage, !passage.tail.isEmpty { streamedText += passage.tail }
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
                        // Fitted again: the notes were sized for the cloud's window.
                        sources = AskAIPrompt.fit(question: question, sources: Array(sources.prefix(profile.sourceLimit)),
                                                  history: turns, profile: profile)
                        let reason = AskAIEngine.message(for: failure) ?? String(localized: "Private Cloud Compute could not answer.")
                        updateReply { $0.sources = sources; $0.text = ""; $0.refreshCitations()
                            $0.note = String(localized: "\(reason) This answer was written on your device instead.") }
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
                    sources = sources.prefix(max(3, sources.count / 2)).map { source in
                        var bare = source
                        bare.notes = []
                        return bare
                    }
                    turns = []
                    resetStream()
                    updateReply { $0.sources = sources; $0.text = ""; $0.refreshCitations() }
                    continue
                }
                // A guardrail decline (rare with the permissive model) is shown as one: the
                // reader sees the decline and the sources the app found, and can retry. No re-ask
                // from general knowledge: that path wrote unsourced answers to the hardest questions.
                if case .guardrail = failure {
                    updateReply { $0.declined = true }
                }
                #if DEBUG
                lastErrorDescription = "\(type(of: error)): \(error)"
                #endif
                // What streamed before the failure reaches the reply now: a trailing flush firing
                // after `finishReply` replaced its "(The answer stopped early...)" line.
                if !streamedText.isEmpty { flushStreamed() }
                var message = AskAIEngine.message(for: failure)
                if case .guardrail = failure, sources.isEmpty {
                    message = String(localized: "Apple Intelligence declined to write about this. Try asking in a different way.")
                }
                finishReply(failed: true, message: message,
                            elapsed: CFAbsoluteTimeGetCurrent() - started, firstToken: firstToken)
                return
            }
        }
    }
    #else
    private func answer(question: AskAIQuestion, sources: [AskAISource], history: [AskAIPrompt.Turn],
                        kind: AskAIEngineKind, profile: AskAIProfile, passage: PassageAnswer? = nil) async {
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
        cleaned = AskAIText.normalizeMarkers(cleaned, sourceCount: count, sources: messages.last?.sources ?? []).text
        // Same rule as `finishReply`: a stream the guard would blank entirely is shown as it is.
        let unechoed = echoGuard.filter(cleaned)
        cleaned = AskAIText.capitalizing(AskAIText.replacingDashes(
            unechoed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? cleaned : unechoed))
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
        #if DEBUG
        lastRawAnswer = streamedText
        #endif
        // No flush may land after the reply settles (it would overwrite the settled text).
        resetStream()
        let question = currentQuestion
        let genericFailure = String(localized: "I couldn\u{2019}t answer that right now. Try rephrasing the question, or ask again in a moment.")
        updateReply { reply in
            reply.isStreaming = false
            reply.elapsed = elapsed
            if failed {
                reply.failed = true
                if reply.text.isEmpty {
                    reply.text = message ?? genericFailure
                } else {
                    reply.text += "\n\n(" + (message ?? String(localized: "The answer stopped early. Ask again to continue.")) + ")"
                }
            } else {
                let unechoed = AskAIText.droppingSourceEchoes(reply.text, sources: reply.sources)
                // An answer the guard would erase WHOLE is a repeated answer (the same question asked
                // again, or rephrased), not an echo inside a new one: it stays. Emptying it turned a
                // repeat into the failure card under the sources it had retrieved.
                let policedEcho = echoGuard.filter(unechoed)
                var text = AskAIText.collapsingRepetition(
                    policedEcho.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? unechoed : policedEcho)
                let markers = AskAIText.normalizeMarkers(text, sourceCount: reply.sources.count, sources: reply.sources)
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
                reply.suggestions = AskAIText.suggestions(for: question, cited: reply.citedSources,
                                                          duaTopics: AskAIRetriever.duaTopicWords(), starters: AskAIStarters.today())
            }
            // The help line stays whether or not the answer came: a declined suicide question is
            // exactly where it matters.
            if let helpLine = helpLineForCurrentTurn { reply.note = helpLine; reply.offersHelpLine = true }
        }
        helpLineForCurrentTurn = nil
        isAnswering = false
        save()
        // An answer that did not come is no moment for the review prompt (AppReview.swift): it keeps
        // quiet for a few minutes. An answer that did come is not counted as a win, since only the
        // reader knows whether it was a good one.
        if messages.last?.failed == true { AppReviewManager.shared.noteSetback(.minor) }
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
        NOTES: \(reply.sources.enumerated().filter { !$0.element.notes.isEmpty }.map { entry in "[\(entry.offset + 1)] " + entry.element.notes.map { "\($0.kind.rawValue)\($0.title.isEmpty ? "" : " " + $0.title) \($0.text.count)" }.joined(separator: ", ") }.joined(separator: " | ")) (\(reply.sources.reduce(0) { $0 + $1.notesCost }) characters)
        CITED: \(reply.citedReferences.joined(separator: " | "))
        REMOVED: \(reply.removedCitations) FLAGGED: \(reply.flaggedQuotations) FAILED: \(failed)
        NOTE: \(reply.note ?? "")
        ERROR: \(failed ? lastErrorDescription : "")
        SUGGESTIONS: \(reply.suggestions.joined(separator: " | "))
        A: \(reply.text)
        RAW: \(lastRawAnswer == reply.text ? "(as shown)" : lastRawAnswer)

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

    #if DEBUG
    /// Tests: a conversation whose thread already has a subject.
    func seedTopicForTesting(_ topic: String) {
        self.topic = topic
        topicDisplay = topic
    }
    #endif

    /// Deletes the open conversation (History keeps its own).
    func reset() {
        cancel(saving: false)
        messages = []
        topic = nil
        topicDisplay = nil
        currentQuestion = nil
        chatID = UUID()
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
        /// The open conversation's identity and last activity, and the conversations before it
        /// (absent from a transcript saved before History existed).
        var id: UUID?
        var updated: Date?
        var recent: [SavedChat]

        init(messages: [Message], topic: String?, id: UUID?, updated: Date?, recent: [SavedChat]) {
            self.messages = messages
            self.topic = topic
            self.id = id
            self.updated = updated
            self.recent = recent
        }

        /// Lenient: a message that no longer decodes is dropped, not the whole transcript.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            messages = (try container.decodeIfPresent([Lossy<Message>].self, forKey: .messages) ?? []).compactMap(\.value)
            topic = try container.decodeIfPresent(String.self, forKey: .topic)
            id = try? container.decodeIfPresent(UUID.self, forKey: .id)
            updated = try? container.decodeIfPresent(Date.self, forKey: .updated)
            recent = ((try? container.decodeIfPresent([Lossy<SavedChat>].self, forKey: .recent)) ?? []).compactMap(\.value)
        }
    }

    /// One element of a list that decodes to nil instead of failing the list.
    struct Lossy<Value: Decodable>: Decodable {
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
        func settled(_ messages: [Message]) -> [Message] {
            messages.map { message in
                var settled = message
                settled.isStreaming = false
                if settled.role == .assistant, settled.text.isEmpty { settled.failed = true; settled.text = String(localized: "The answer was interrupted.") }
                return settled
            }
        }
        messages = settled(store.messages)
        topic = store.topic
        chatID = store.id ?? UUID()
        lastActivity = store.updated ?? Date()
        recentChats = store.recent.prefix(Self.recentChatLimit).compactMap { chat in
            var kept = chat
            kept.messages = settled(chat.messages)
            return kept.messages.isEmpty ? nil : kept
        }
    }

    /// Saves run one at a time, in the order they were asked for: as separate detached tasks, the
    /// old transcript's write could land after "New Conversation" removed the file.
    private static let saveQueue = DispatchQueue(label: "AskAIConversation.save", qos: .utility)

    private func save() {
        /// The most recent settled messages, their sources' text clipped.
        func kept(_ messages: [Message]) -> [Message] {
            messages.filter { !$0.isStreaming }.suffix(Self.keptMessages).map { message -> Message in
                var clipped = message
                clipped.sources = message.sources.map { $0.clippingText(to: Self.savedSourceCharacters) }
                return clipped
            }
        }
        let recent = recentChats.map { chat -> SavedChat in
            var saved = chat
            saved.messages = kept(chat.messages)
            return saved
        }
        let store = Store(messages: kept(messages), topic: topic, id: chatID, updated: lastActivity, recent: recent)
        let url = Self.storeURL
        Self.saveQueue.async {
            if store.messages.isEmpty, store.recent.isEmpty {
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
        declined = try container.decodeIfPresent(Bool.self, forKey: .declined) ?? false
        removedCitations = try container.decodeIfPresent(Int.self, forKey: .removedCitations) ?? 0
        flaggedQuotations = try container.decodeIfPresent(Int.self, forKey: .flaggedQuotations) ?? 0
        asksForRuling = try container.decodeIfPresent(Bool.self, forKey: .asksForRuling) ?? false
        // An intent or engine a later build added reads as unknown, not as a broken file.
        intent = (try? container.decodeIfPresent(AskAIIntent.self, forKey: .intent)) ?? nil
        engine = (try? container.decodeIfPresent(AskAIEngineKind.self, forKey: .engine)) ?? nil
        isFollowUp = try container.decodeIfPresent(Bool.self, forKey: .isFollowUp) ?? false
        note = try container.decodeIfPresent(String.self, forKey: .note)
        offersHelpLine = try container.decodeIfPresent(Bool.self, forKey: .offersHelpLine) ?? false
        citedReferences = try container.decodeIfPresent([String].self, forKey: .citedReferences) ?? []
        suggestions = try container.decodeIfPresent([String].self, forKey: .suggestions) ?? []
        elapsed = try container.decodeIfPresent(Double.self, forKey: .elapsed)
    }
}

#endif
