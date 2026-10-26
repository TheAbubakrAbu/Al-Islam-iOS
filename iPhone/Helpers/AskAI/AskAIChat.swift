import SwiftUI
import Foundation

// Ask AI - a conversation with Apple's model about the Quran, the hadith, and Islam, the way one
// would ask any assistant: type a question, read the answer, follow up. Private, offline by default
// (iOS 26 + Apple Intelligence; `OnDeviceAsk.isAvailable`), with Private Cloud Compute as a choice
// on iOS 27.
//
// The screen: a transcript of user bubbles and answer cards. An answer card carries the prose with
// its citation marks, then a numbered SOURCES list of quote cards (the app's own text, verbatim, with
// the Arabic where there is one and a footer saying where it comes from), the disclosures (a recalled
// citation removed, a quotation not verified), the standing caution, and follow-up chips. Every
// source card opens the real screen. The pieces themselves live in AskAISources.swift (sources),
// AskAIIntent.swift (what a question is), AskAIRetrieval.swift (the lanes), AskAIEngine.swift (the
// model and the prompt), AskAIText.swift (hygiene) and AskAIConversation.swift (the turns).
//
// Reached from the ASK AI row of the Quran and Hadith searches (which open it with the typed query
// as the first question), the other searching Islam screens, and the Islam tab's "Ask AI" resource.

#if os(iOS)

// MARK: - The chat screen

@available(iOS 16.0, *)
struct AskAIChatView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var chat = AskAIConversation.shared
    @Environment(\.dismiss) private var dismiss

    /// Asked as soon as the screen appears (the search screens hand their query in), unless it is
    /// already the conversation's latest question - reopening the sheet must not ask twice.
    var initialQuestion: String? = nil
    var presentedAsSheet = false

    @State private var draft = ""
    @FocusState private var inputFocused: Bool
    /// The initial question is asked once per presentation: `onAppear` fires again every time a
    /// cited row's pushed reader pops, and that must not re-ask the search query.
    @State private var askedInitial = false
    /// Whether the transcript keeps pinning its bottom as text streams. A reader who scrolls up to
    /// re-read stops being dragged back down; reaching the bottom again (or a new turn) re-arms it.
    @State private var followsStream = true
    /// "New Conversation" clears the whole transcript, so it asks first.
    @State private var confirmReset = false
    #if DEBUG
    /// `-askAI "q1||q2||q3"`: the remaining questions, asked one at a time as each answer settles.
    @State private var debugQueue: [String] = []
    #endif

    #if HAS_QURAN
    private static let starterPool = [
        "What does the Quran say about patience in hardship?",
        "How do I make up a missed prayer?",
        "Why is Surah Al-Kahf read on Fridays?",
        "What did the Prophet say about kindness to parents?",
        "Explain Ayat al-Kursi",
        "What is the difference between zakat and sadaqah?",
        "Tell me the story of Prophet Yusuf",
        "Is there a dua for anxiety?",
        "What does Al-Wadud mean?",
        "How do I perform wudu?",
        "What are the signs of the Day of Judgment?",
        "How do I change the reciter in this app?",
    ]
    #else
    // Without the Quran reader (Al-Adhan): the same pool, with the four starters that lean on the
    // Quran's text or its reciters swapped for ones this app's own sources answer (its prayer times,
    // articles, duas, Names and tips).
    private static let starterPool = [
        "When does the time for Isha end tonight?",
        "How do I make up a missed prayer?",
        "What are the sunnahs of Friday?",
        "What did the Prophet say about kindness to parents?",
        "What should I say after the adhan?",
        "What is the difference between zakat and sadaqah?",
        "Tell me the story of Prophet Yusuf",
        "Is there a dua for anxiety?",
        "What does Al-Wadud mean?",
        "How do I perform wudu?",
        "What are the signs of the Day of Judgment?",
        "How do I change the adhan sound in this app?",
    ]
    #endif

    /// Four starters, rotated by the day so the empty screen does not read the same every time.
    private var starters: [String] {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let pool = Self.starterPool
        return (0..<4).map { pool[(day * 3 + $0 * 5) % pool.count] }
    }

    var body: some View {
        Group {
            if OnDeviceAsk.isAvailable {
                conversation
            } else {
                unavailable
            }
        }
        // The reading themes' ground (Sepia and Gray rendered this screen white): the app's plain
        // ScrollView screens all carry it explicitly.
        .accentWashedBackground()
        .navigationTitle("Ask AI")
        .navigationBarTitleDisplayMode(.inline)
        .sheetDismissToolbarIf(presentedAsSheet)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        settings.hapticFeedback()
                        confirmReset = true
                    } label: {
                        Label("New Conversation", systemImage: "square.and.pencil")
                    }
                    .disabled(chat.messages.isEmpty)

                    Button {
                        settings.hapticFeedback()
                        UIPasteboard.general.string = transcriptText
                    } label: {
                        Label("Copy Conversation", systemImage: "doc.on.doc")
                    }
                    .disabled(chat.messages.isEmpty)

                    #if canImport(FoundationModels)
                    if #available(iOS 26.0, *), AskAIEngine.cloudIsOffered {
                        Section("Answer with") {
                            Picker("Answer with", selection: $chat.engineKind) {
                                Text("On device, private").tag(AskAIEngineKind.onDevice)
                                Text("Private Cloud Compute, smarter").tag(AskAIEngineKind.privateCloud)
                            }
                            .pickerStyle(.inline)
                        }
                    }
                    #endif
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(settings.accentColor.accent1)
                .accessibilityLabel("Conversation options")
            }
        }
        .confirmationDialog("Start a new conversation?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("New Conversation", role: .destructive) {
                settings.hapticFeedback()
                // The transcript is cleared (an answer still streaming stops first); a
                // typed-but-unsent draft is the reader's, and stays.
                chat.reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This conversation and its sources will be cleared.")
        }
        #if DEBUG
        .onChange(of: chat.isAnswering) { answering in
            guard !answering, !debugQueue.isEmpty else { return }
            let next = debugQueue.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { chat.ask(next) }
        }
        #endif
        // The chat is the one screen that can hold three corpora (Quran, hadith, articles) at
        // once; leaving it keeps only the most recent instead of waiting for a memory warning.
        .onDisappear { SemanticSearchEngine.shared.releaseIdleCorpora() }
        .onAppear {
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) { AskAIEngine.prewarm() }
            #endif
            // The indexes only matter when a question can be asked.
            if OnDeviceAsk.isAvailable { AskAIRetriever.prewarm() }
            guard !askedInitial else { return }
            askedInitial = true
            var question = initialQuestion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            #if DEBUG
            // Headless verification: `-askAI "<question>"` asks it the moment the screen appears (pair
            // with `-launchTabIslam -islamDestination askAI`); "q1||q2" asks the rest one by one as
            // each answer settles, so follow-ups can be exercised too. DEBUG builds only.
            if question.isEmpty,
               let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-askAI"),
               ProcessInfo.processInfo.arguments.indices.contains(index + 1) {
                let parts = ProcessInfo.processInfo.arguments[index + 1]
                    .components(separatedBy: "||")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                question = parts.first ?? ""
                debugQueue = Array(parts.dropFirst())
            }
            #endif
            guard !question.isEmpty else { return }
            if chat.messages.last(where: { $0.role == .user })?.text != question {
                chat.ask(question)
            }
        }
    }

    /// The whole transcript as text, sources included, for the Copy Conversation action.
    private var transcriptText: String {
        chat.messages.map { message in
            switch message.role {
            case .user: return String(localized: "You: \(message.text)")
            case .assistant: return String(localized: "AI: \(AskAIText.shareText(answer: message.text, cited: message.citedSources, allSources: message.sources))")
            }
        }.joined(separator: "\n\n")
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if chat.messages.isEmpty {
                        welcome
                    }
                    ForEach(chat.messages) { message in
                        messageView(message)
                            .id(message.id)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                        .onAppear { followsStream = true }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            // A deliberate drag means the reader is reading: stop pinning the bottom until they
            // reach it again (the sentinel's onAppear) or a new turn starts.
            .simultaneousGesture(DragGesture(minimumDistance: 12).onChanged { _ in followsStream = false })
            .onChange(of: chat.messages.count) { _ in
                followsStream = true
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: chat.messages.last?.text) { _ in
                guard followsStream else { return }
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
        // The app's floating bottom-bar grammar (safeAreaBar under Liquid Glass, a plain inset before
        // it), not a flat `.bar` strip: the field and its send button read like every search bar.
        .adaptiveSafeArea(edge: .bottom) { inputBar }
    }

    // MARK: Welcome

    /// The empty transcript: a hero card, the starter questions, a three-row "how it works" card and
    /// the caution, set the way the rest of the app sets it - glass cards, section labels, glyph rows.
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            // The card every Islam resource opens on (`ResourceHero`).
            ResourceHero(
                eyebrow: String(localized: "ASK AI"),
                systemImage: "sparkles",
                headline: String(localized: "Ask anything about Islam."),
                message: AskAICopy.heroMessage
            )

            VStack(alignment: .leading, spacing: 8) {
                welcomeLabel(String(localized: "TRY ASKING"))

                ForEach(starters, id: \.self) { question in
                    Button {
                        settings.hapticFeedback()
                        chat.ask(question)
                    } label: {
                        HStack(spacing: 8) {
                            Text(question.localizedDisplay)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .conditionalGlassEffect(rectangle: true)
                    }
                    .buttonStyle(.plain)
                }
            }

            // How it works, in the app itself: a reader who knows where the quotes come from and
            // what the model is not allowed to do can judge what they are reading.
            VStack(alignment: .leading, spacing: 8) {
                welcomeLabel(String(localized: "HOW IT WORKS"))

                VStack(alignment: .leading, spacing: 12) {
                    howItWorksRow(icon: "magnifyingglass", text: AskAICopy.searchedAcross)
                    howItWorksRow(icon: cloudOffered ? "icloud" : "iphone", text: cloudOffered
                                  ? String(localized: "What it finds goes to Apple Intelligence on your device, or to Apple\u{2019}s Private Cloud Compute if you choose it in the menu, which answers in its own words and cites each source by number, saying where it comes from.")
                                  : String(localized: "What it finds goes to Apple Intelligence on your device, which answers in its own words and cites each source by number, saying where it comes from. Nothing leaves your phone."))
                    howItWorksRow(icon: "checkmark.shield", text: String(localized: "Every quote beneath an answer is this app\u{2019}s own text, never the model\u{2019}s memory. A citation it invents is removed, a quotation that matches nothing is marked \u{201C}wording not verified\u{201D}, and every source opens the real passage so you can check it yourself."))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .conditionalGlassEffect(rectangle: true, interactive: false)
            }

            Label("This is a machine, not a scholar. It is here for quick, simple, general questions, and it can be confidently wrong. It does not give rulings, it is never the final answer, and anything that actually matters belongs with a knowledgeable scholar of Ahl as-Sunnah wa al-Jama\u{2018}ah.", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var cloudOffered: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return AskAIEngine.cloudIsOffered }
        #endif
        return false
    }

    private func welcomeLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private func howItWorksRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(settings.accentColor.color)
                .frame(width: 22)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Messages

    @ViewBuilder
    private func messageView(_ message: AskAIConversation.Message) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 48)
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(settings.accentColor.color.opacity(0.2))
                    )
                    .textSelection(.enabled)
            }
        case .assistant:
            AskAIAnswerCard(message: message, isLast: message.id == chat.messages.last?.id) { suggestion in
                settings.hapticFeedback()
                chat.ask(suggestion)
            } onRetry: {
                settings.hapticFeedback()
                chat.retryLast()
            }
        }
    }

    // MARK: Composer

    /// The composer: the app's 50pt glass field with a sparkles glyph where the search bars carry
    /// their magnifier, and the circle-glass send (or stop) button beside it.
    private var inputBar: some View {
        let canSend = !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(alignment: .bottom, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.body)
                    .foregroundStyle(settings.accentColor.color)

                TextField(AskAICopy.composerPrompt, text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .textFieldStyle(.plain)
                    .onSubmit { send() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 50)
            .conditionalGlassEffect()

            if chat.isAnswering {
                Button {
                    settings.hapticFeedback()
                    chat.cancel()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .contentShape(Circle())
                        .conditionalGlassEffect(circle: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop answering")
            } else {
                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.bold))
                        .foregroundColor(canSend ? .white : .secondary)
                        .frame(width: 50, height: 50)
                        .contentShape(Circle())
                        .conditionalGlassEffect(circle: true, useColor: canSend ? 0.9 : nil)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel("Send")
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, BottomBarCushion.standard)
        .background(Color.white.opacity(0.00001))
        .animation(.easeInOut(duration: 0.2), value: canSend)
        .animation(.easeInOut(duration: 0.2), value: chat.isAnswering)
    }

    private func send() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        settings.hapticFeedback()
        draft = ""
        chat.ask(question)
    }

    private var unavailable: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(settings.accentColor.color)
            Text("Ask AI needs Apple Intelligence")
                .font(.headline)
            Text(String(localized: "Ask AI runs with Apple Intelligence, which needs iOS 26 on a supported iPhone with Apple Intelligence turned on in Settings.").localizedDigits)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The copy that names what Ask AI searches. Each app names only the libraries it ships: the hadith
/// collections are compiled in with HAS_HADITH, so an app without them never promises them.
private enum AskAICopy {
    #if HAS_HADITH
    static let heroMessage = String(localized: "A question, a follow-up, a \u{201C}what does this mean\u{201D}: answered by Apple Intelligence from this app\u{2019}s own Quran, hadith, tafsir, articles and duas, with every source quoted beneath the reply and a line saying where it comes from.")
    static let searchedAcross = String(localized: "Your question is understood first (a greeting, a verse, a how-to, a question about the app), then searched across this app\u{2019}s own Quran, hadith collections, tafsir, articles, duas, Names of Allah and tips.")
    static let composerPrompt = String(localized: "Ask about the Quran, hadith, or Islam")
    static let lookingThrough = String(localized: "Looking through the Quran, hadith and articles\u{2026}")
    #elseif HAS_QURAN
    static let heroMessage = String(localized: "A question, a follow-up, a \u{201C}what does this mean\u{201D}: answered by Apple Intelligence from this app\u{2019}s own Quran, tafsir, articles and duas, with every source quoted beneath the reply and a line saying where it comes from.")
    static let searchedAcross = String(localized: "Your question is understood first (a greeting, a verse, a how-to, a question about the app), then searched across this app\u{2019}s own Quran, tafsir, articles, duas, Names of Allah and tips.")
    static let composerPrompt = String(localized: "Ask about the Quran or Islam")
    static let lookingThrough = String(localized: "Looking through the Quran and articles\u{2026}")
    #else
    // No Quran and no hadith shelf (Al-Adhan): the prayer times, the articles, the duas, the Names
    // and the tips are what AskAIRetrieval.swift searches here.
    static let heroMessage = String(localized: "A question, a follow-up, a \u{201C}what does this mean\u{201D}: answered by Apple Intelligence from this app\u{2019}s own prayer times, articles, duas, Names of Allah and tips, with every source quoted beneath the reply and a line saying where it comes from.")
    static let searchedAcross = String(localized: "Your question is understood first (a greeting, a how-to, a question about the app), then searched across this app\u{2019}s own prayer times, articles, duas, Names of Allah and tips.")
    static let composerPrompt = String(localized: "Ask about prayer or Islam")
    static let lookingThrough = String(localized: "Looking through the app\u{2019}s articles\u{2026}")
    #endif
}

/// The chat presented as a sheet (from the search screens), in its own navigation stack so the
/// source cards can push the reader.
@available(iOS 16.0, *)
struct AskAIChatSheet: View {
    var initialQuestion: String? = nil

    var body: some View {
        NavigationStack {
            AskAIChatView(initialQuestion: initialQuestion, presentedAsSheet: true)
        }
        // Sized here, not at the six call sites: every screen that offers Ask AI presents this one
        // type, so the half-height opening belongs with the sheet itself.
        .smallMediumSheetPresentation()
    }
}

// MARK: - The answer card

@available(iOS 16.0, *)
private struct AskAIAnswerCard: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.appearance) private var appearance

    let message: AskAIConversation.Message
    let isLast: Bool
    let onSuggestion: (String) -> Void
    let onRetry: () -> Void

    @State private var showAllSources = false

    private var cited: [AskAISource] { message.citedSources }
    private var uncited: [AskAISource] { message.uncitedSources }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if message.text.isEmpty {
                Text(statusLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if message.failed, message.sources.isEmpty || !message.text.contains("\n\n(") {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                AskAIAnswerProse(text: message.text)
            }

            if let note = message.note {
                Label(note, systemImage: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !cited.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SOURCES")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    ForEach(Array(cited.enumerated()), id: \.element.id) { _, source in
                        AskAISourceCard(number: number(of: source), source: source)
                    }
                }
            }

            if !message.isStreaming, !uncited.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut(duration: 0.2)) { showAllSources.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showAllSources ? "chevron.down" : "chevron.forward")
                                .font(.caption2.weight(.semibold))
                            Text(showAllSources
                                 ? "Hide the other \(uncited.count) the app found"
                                 : (cited.isEmpty
                                    ? (uncited.count == 1 ? "1 source the app found but the answer did not cite" : "\(uncited.count) sources the app found but the answer did not cite")
                                    : (uncited.count == 1 ? "1 more source the app found" : "\(uncited.count) more sources the app found")))
                                .font(.caption)
                        }
                        .foregroundStyle(settings.accentColor.color)
                    }
                    .buttonStyle(.plain)

                    if showAllSources {
                        ForEach(uncited) { source in
                            AskAISourceCard(number: number(of: source), source: source, dimmed: true)
                        }
                    }
                }
            }

            if message.removedCitations > 0 {
                Text(message.removedCitations == 1
                     ? "1 reference the AI recalled from memory was removed because it is not among the sources it was given."
                     : "\(message.removedCitations) references the AI recalled from memory were removed because they are not among the sources it was given.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if message.flaggedQuotations > 0 {
                Text(message.flaggedQuotations == 1
                     ? "1 quotation does not match any source the AI was given and is marked \u{201C}wording not verified\u{201D}: treat it as a paraphrase at best."
                     : "\(message.flaggedQuotations) quotations do not match any source the AI was given and are marked \u{201C}wording not verified\u{201D}: treat them as paraphrases at best.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // On EVERY finished answer, not only the ruling-shaped ones. A caution that appears
            // selectively teaches the reader that its absence means "this one is reliable",
            // which is the opposite of true.
            if !message.isStreaming, !message.failed, !(message.intent?.isConversational ?? false) {
                Label(message.asksForRuling
                      ? "Not a ruling, and scholars differ on questions like this. This is AI: useful for quick, simple, general questions, never the final word. For your own situation ask a knowledgeable scholar of Ahl as-Sunnah."
                      : "This is AI: useful for quick, simple, general questions, never the final word. For anything that matters, ask a knowledgeable scholar of Ahl as-Sunnah.",
                      systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !message.isStreaming, isLast, !message.suggestions.isEmpty {
                suggestionChips
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Regular glass, not clear: clear glass on a dark ground is invisible, and the answer
        // read as loose text floating in the transcript instead of a card.
        .conditionalGlassEffect(rectangle: true, interactive: false)
        .contextMenu {
            if !message.isStreaming, !message.text.isEmpty {
                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = AskAIText.shareText(answer: message.text, cited: cited, allSources: message.sources)
                } label: {
                    Label("Copy Answer", systemImage: "doc.on.doc")
                }
                ShareLink(item: AskAIText.shareText(answer: message.text, cited: cited, allSources: message.sources)) {
                    Label("Share Answer", systemImage: "square.and.arrow.up")
                }
                if isLast {
                    Button(action: onRetry) {
                        Label("Ask Again", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private func number(of source: AskAISource) -> Int {
        (message.sources.firstIndex(where: { $0.reference == source.reference }) ?? 0) + 1
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption)
            Text("AI")
                .font(.caption.weight(.semibold))
            if let engine = message.engine {
                Text(engine.badge)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(settings.accentColor.color.opacity(0.14)))
            }
            if message.isStreaming {
                ProgressView()
                    .controlSize(.mini)
            }
            Spacer()
            if message.failed, isLast {
                Button(action: onRetry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ask again")
            }
        }
        .foregroundStyle(settings.accentColor.color)
    }

    private var statusLine: String {
        if let intent = message.intent, !intent.retrieves { return String(localized: "Thinking\u{2026}") }
        if message.sources.isEmpty {
            switch message.intent {
            case .appHelp: return String(localized: "Looking through the app\u{2019}s tips\u{2026}")
            case .dua: return String(localized: "Looking through the duas\u{2026}")
            #if HAS_HADITH
            case .hadith: return String(localized: "Looking through the hadith collections\u{2026}")
            #endif
            default: return AskAICopy.lookingThrough
            }
        }
        return message.engine == .privateCloud ? String(localized: "Thinking on Private Cloud Compute\u{2026}") : String(localized: "Thinking\u{2026}")
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(message.suggestions, id: \.self) { suggestion in
                    Button {
                        onSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .conditionalGlassEffect()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .padding(.top, 2)
    }
}

/// The answer's prose: drag-selectable, in the app's rounded face, with each citation mark set as a
/// small raised accent numeral (see `AskAIText.attributedAnswer`).
private struct AskAIAnswerProse: View {
    let text: String
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.appearance) private var appearance

    var body: some View {
        let size = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
        SelectableTextView(attributed: AskAIText.attributedAnswer(
            text, font: .roundedSystemFont(ofSize: size, weight: .regular), color: .label, accent: UIColor(appearance.accent)))
            // The text view opts out of automatic content-size tracking, so the font is rebuilt from
            // this instead (the `SelectableProse` rule).
            .id(sizeCategory)
            .frame(maxWidth: .infinity, alignment: .leading)
            // The model is told to answer in English, which then reads left to right in the Arabic
            // interface too; an answer that came back in Arabic keeps the interface's direction.
            .leftToRightContent(!text.isMostlyArabicScript)
    }
}

// MARK: - A source card

/// One source beneath an answer: its number, its kind, its title, the app's own text quoted, the
/// Arabic where there is one, and a footer saying where it comes from. A tap opens the real screen.
@available(iOS 16.0, *)
private struct AskAISourceCard: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.appearance) private var appearance

    let number: Int
    let source: AskAISource
    var dimmed = false

    @State private var expanded = false

    var body: some View {
        if !opensAScreen {
            label
        } else {
            NavigationLink {
                LazyDestination {
                    AskAISourceDestination.view(for: source)
                }
            } label: {
                label
            }
            .buttonStyle(.plain)
        }
    }

    private var accent: Color { settings.accentColor.color.opacity(dimmed ? 0.7 : 1) }

    private var showsArabic: Bool {
        switch source.kind {
        case .ayah, .dua, .hisnDua, .name: return source.arabic?.isEmpty == false
        default: return false
        }
    }

    private var isLong: Bool { source.text.count > 280 || (source.arabic?.count ?? 0) > 120 }

    /// The title line in the interface's language: in Arabic an ayah or a surah is named in Arabic.
    /// `source.title` itself stays as written: the model read it and the transcript stores it.
    private var displayTitle: String {
        #if HAS_QURAN
        if AppLanguage.isArabic {
            switch source.kind {
            case .ayah(let surahID, let ayahID):
                if let surah = QuranData.shared.surah(surahID) { return "\(surah.displayName) \(surahID):\(ayahID)".localizedDigits }
            case .surah(let surahID):
                if let surah = QuranData.shared.surah(surahID) { return String(localized: "Surah \(surahID): \(surah.displayName)") }
            default:
                break
            }
        }
        #endif
        #if HAS_HADITH
        // In Arabic a hadith is named by the book's Arabic title, its number in the interface's
        // digits; English gets the stored line back unchanged.
        if case .hadith(let slug, _) = source.kind {
            return HadithCatalogBook.displayReference(stored: source.title, slug: slug)
        }
        #endif
        // A tip or a setting is stored in English (what the model read): the card shows the title the
        // screens show, in the interface language. In English that is the stored line itself.
        if !AppLanguage.code.hasPrefix("en") {
            switch source.kind {
            case .tip(let id):
                #if HAS_TIPS
                if let tip = TipCatalog.all.first(where: { $0.id == id }) { return tip.title }
                #else
                let _ = id
                #endif
            case .setting(let id):
                if let entry = SettingsSearchEntry.entry(withID: id) { return entry.title }
            default:
                break
            }
        }
        return source.title
    }

    private var arabicFont: Font {
        switch source.kind {
        case .ayah: return appearance.quranArabicFont(size: 21, relativeTo: .title3)
        default: return appearance.islamArabicFont(base: 21, relativeTo: .title3)
        }
    }

    private var arabicUsesCustomFace: Bool {
        if case .ayah = source.kind { return appearance.quranUsesCustomArabicFace }
        return appearance.islamUsesCustomArabicFace
    }

    /// A card that opens nothing in this app (a kind it does not ship, or the timetable) stays a
    /// plain card: the link would push an empty screen.
    private var opensAScreen: Bool {
        switch source.kind {
        case .prayer: return false
        #if !HAS_QURAN
        case .ayah, .tafsir, .surah: return false
        #endif
        #if !HAS_HADITH
        case .hadith: return false
        #endif
        #if !HAS_TIPS
        case .tip: return false
        #endif
        default: return true
        }
    }

    private var label: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(accent))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: source.systemImage)
                        .font(.caption2.weight(.semibold))
                    Text(source.kindLabel.uppercased())
                        .font(.caption2.weight(.semibold))
                    if source.isSubject {
                        Text("SUBJECT")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(accent.opacity(0.14)))
                    }
                    Spacer(minLength: 0)
                    if opensAScreen {
                        Image(systemName: "chevron.forward")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(accent)

                Text(displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if showsArabic, let arabic = source.arabic {
                    Text(arabic)
                        .font(arabicFont)
                        .arabicFontDesign(custom: arabicUsesCustomFace)
                        .foregroundColor(accent)
                        .lineSpacing(5)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .lineLimit(expanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                        // The right edge in the Arabic interface too (`.trailing` is right only left
                        // to right).
                        .environment(\.layoutDirection, .leftToRight)
                }

                Text(source.isQuotable ? "\u{201C}\(source.text)\u{201D}" : source.text)
                    .font(.footnote)
                    .foregroundColor(dimmed ? .secondary : .primary)
                    .lineLimit(expanded ? nil : 4)
                    .fixedSize(horizontal: false, vertical: true)
                    // The source's English excerpt (a translation, a narration, a tafsir) and its
                    // transliteration keep the left edge in the Arabic interface; an Arabic excerpt
                    // follows the interface.
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .leftToRightContent(!source.text.isMostlyArabicScript)

                if let transliteration = source.transliteration {
                    Text(transliteration)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(expanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent()
                }

                if isLong {
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                    } label: {
                        Text(expanded ? "Show less" : "Show the whole text")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }

                if !source.provenance.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(source.provenanceLine)
                            .font(.caption2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .contentShape(Rectangle())
    }

    /// The scripture card's ground (the article libraries' `ScriptureQuoteBody`), lighter: the
    /// accent falling away corner to corner, a hairline, and the bar down the leading edge.
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [accent.opacity(dimmed ? 0.06 : 0.12), accent.opacity(0.03)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Rectangle().fill(accent.opacity(0.85)).frame(width: 3), alignment: .leading)
            .clipShape(shape)
            .overlay(shape.strokeBorder(accent.opacity(0.18), lineWidth: 1))
    }
}

/// Where a source card opens: the reader at the ayah, the hadith in its chapter, the article, the
/// Names screen scrolled to the Name, the dua's collection, the tip's setting.
@available(iOS 16.0, *)
@MainActor
enum AskAISourceDestination {
    @ViewBuilder
    static func view(for source: AskAISource) -> some View {
        switch source.kind {
        case .ayah(let surahID, let ayahID), .tafsir(let surahID, let ayahID, _):
            #if HAS_QURAN
            if let surah = QuranData.shared.surah(surahID) {
                SurahView(surah: surah, ayah: ayahID)
            }
            #else
            let _ = (surahID, ayahID)
            EmptyView()
            #endif
        case .surah(let surahID):
            #if HAS_QURAN
            if let surah = QuranData.shared.surah(surahID) {
                SurahView(surah: surah)
            }
            #else
            let _ = surahID
            EmptyView()
            #endif
        case .hadith(let slug, let idInBook):
            #if HAS_HADITH
            if let book = HadithCatalogBook.bySlug[slug],
               let data = HadithStore.shared.book(book),
               let hadith = data.hadiths.first(where: { $0.idInBook == idInBook }) {
                if let chapter = data.chapters.first(where: { $0.id == hadith.chapterId }) {
                    HadithChapterView(book: book, bookData: data, chapter: chapter, scrollToHadithId: hadith.idInBook)
                } else {
                    HadithReferenceView(book: book, resolved: hadith)
                }
            }
            #else
            let _ = (slug, idInBook)
            EmptyView()
            #endif
        case .article(let id, _):
            if let destination = IslamArticles.destination(for: id) {
                destination
            }
        case .name(let number):
            NamesView()
                .onAppear { NamesViewModel.shared.pendingNameNumber = number }
        case .dua(let collectionTitle, _):
            if let collection = DuaLibrary.shared.collections.first(where: { $0.title == collectionTitle }) {
                DuaCollectionView(collection: collection)
            } else {
                DuaView()
            }
        case .hisnDua:
            HisnDuaLibraryView()
        case .tip(let id):
            #if HAS_TIPS
            if let tip = TipCatalog.all.first(where: { $0.id == id }), let destination = tip.destination {
                SettingsSearchDestinationView.view(for: destination)
            } else {
                TipsHubView()
            }
            #else
            let _ = id
            EmptyView()
            #endif
        case .setting(let id):
            if let entry = SettingsSearchEntry.entry(withID: id) {
                SettingsSearchDestinationView.view(for: entry.destination)
            }
        case .prayer:
            EmptyView()
        }
    }
}

#endif
