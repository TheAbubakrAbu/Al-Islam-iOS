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
//
// Every visit opens on a NEW conversation; the two before it are listed under HISTORY on the welcome
// and in the menu, and open again with a tap (`AskAIConversation.beginVisit`, `recentChats`).

#if os(iOS)

// MARK: - The chat screen

@available(iOS 16.0, *)
struct AskAIChatView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// "Show Riwayah / Qiraah": whether the welcome says the readings are read with a verse.
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var chat = AskAIConversation.shared
    @Environment(\.dismiss) private var dismiss

    /// Asked as soon as the screen appears (the search screens hand their query in), unless it is
    /// already the conversation's latest question - reopening the sheet must not ask twice.
    var initialQuestion: String? = nil
    var presentedAsSheet = false
    /// The article the chat was opened from (an article page's Ask AI button): the questions it
    /// offers are about that article, and every question asked here also reads its sections
    /// (`AskAIConversation.focusArticle`).
    var focusArticle: IslamArticle? = nil

    @State private var draft = ""
    /// Whether a question has been asked since this screen opened on an article: until one is, a
    /// conversation that was already going shows the article's questions under its last answer.
    @State private var askedAboutArticle = false
    @FocusState private var inputFocused: Bool
    /// The initial question is asked once per presentation: `onAppear` fires again every time a
    /// cited row's pushed reader pops, and that must not re-ask the search query.
    @State private var askedInitial = false
    /// Whether the transcript keeps pinning its bottom as text streams. A reader who scrolls up to
    /// re-read stops being dragged back down; reaching the bottom again (or a new turn) re-arms it.
    @State private var followsStream = true
    /// "Delete Conversation" clears the open transcript for good, so it asks first ("New
    /// Conversation" only sets it aside under History, and does not).
    @State private var confirmDelete = false
    /// HOW IT WORKS, folded until asked for: the welcome led with four paragraphs of it.
    @State private var showsHowItWorks = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if DEBUG
    /// `-askAI "q1||q2||q3"`: the remaining questions, asked one at a time as each answer settles.
    @State private var debugQueue: [String] = []
    #endif

    /// Four starters, rotated by the day so the empty screen does not read the same every time; on an
    /// article, that article's own questions.
    private var starters: [String] {
        if let focusArticle { return Self.articleQuestions(focusArticle) }
        return chat.scope.starters
    }

    /// The questions an article's Ask AI offers. English, like every question the model reads, and
    /// naming the article in full: a bare "summarize this" reads as a rework of the previous answer
    /// (`AskAIIntent.recap`), and a short opener as a follow-up that folds the last topic in.
    static func articleQuestions(_ article: IslamArticle) -> [String] {
        let title = "\u{201C}\(article.title)\u{201D}"
        return [
            "Give me a short summary of the article \(title).",
            "What are the main points of the article \(title)?",
            "What evidence from the Quran and Sunnah supports the article \(title)?",
        ]
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
        // Opened from an English article (its Ask AI button), the chat is still a translated screen:
        // its card must not say "Available in English only" (`englishArticle()`).
        .environment(\.isEnglishArticle, false)
        .navigationTitle("Ask AI")
        .navigationBarTitleDisplayMode(.inline)
        .sheetDismissToolbarIf(presentedAsSheet)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        settings.hapticFeedback()
                        // Set aside under History, not cleared: nothing to confirm.
                        withAnimation(.easeInOut(duration: 0.2)) { chat.startNewChat() }
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

                    // Abu, 2026-11-24: "allow me to share ... ask ai".
                    ShareLink(item: transcriptText) {
                        Label("Share Conversation", systemImage: "square.and.arrow.up")
                    }
                    .disabled(chat.messages.isEmpty)

                    if !chat.recentChats.isEmpty {
                        Section("History") {
                            ForEach(chat.recentChats) { recent in
                                Button {
                                    settings.hapticFeedback()
                                    askedAboutArticle = false
                                    withAnimation(.easeInOut(duration: 0.2)) { chat.openRecent(recent.id) }
                                } label: {
                                    Label(AskAISource.clip(recent.title, to: 44), systemImage: "clock.arrow.circlepath")
                                }
                            }
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        confirmDelete = true
                    } label: {
                        Label("Delete Conversation", systemImage: "trash")
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
        .confirmationDialog("Delete this conversation?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Conversation", role: .destructive) {
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
        .onDisappear {
            SemanticSearchEngine.shared.releaseIdleCorpora()
            if focusArticle != nil, chat.focusArticle?.id == focusArticle?.id { chat.focusArticle = nil }
        }
        .onAppear {
            // Set on every appearance (a cited source's pushed reader pops back to here), cleared
            // below: the Islam tab's own Ask AI asks unfocused.
            chat.focusArticle = focusArticle
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) { AskAIEngine.prewarm() }
            #endif
            // The indexes only matter when a question can be asked.
            if OnDeviceAsk.isAvailable { AskAIRetriever.prewarm() }
            guard !askedInitial else { return }
            askedInitial = true
            var question = initialQuestion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // A visit starts on a new conversation, the last one set aside under History (once per
            // presentation, like the question below: a popped reader is not a new visit).
            chat.beginVisit(asking: question)
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
                LazyVStack(alignment: .leading, spacing: 20) {
                    if chat.messages.isEmpty {
                        welcome
                    }
                    ForEach(chat.messages) { message in
                        messageView(message)
                            .id(message.id)
                    }
                    if let focusArticle, !chat.messages.isEmpty, !askedAboutArticle, !chat.isAnswering {
                        articleQuestionsBlock(focusArticle)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                        .onAppear { followsStream = true }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
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
        // In a sheet (or pushed inside one), the Now Playing bar rides above the field, on top of the
        // bottom stack as on every screen with controls at its foot.
        .sheetNowPlayingBar()
        // The app's floating bottom-bar grammar (safeAreaBar under Liquid Glass, a plain inset before
        // it), not a flat `.bar` strip: the field and its send button read like every search bar.
        .adaptiveSafeArea(edge: .bottom) { inputBar }
    }

    // MARK: Welcome

    /// The empty transcript (redesigned 2026-11-24, Abu: "revamp ask ai ... chopped horrible ui horrible
    /// experience and too cramped"): the hero, then WHAT TO ASK FROM as a grid of the libraries (the
    /// filter, in the open, where a reader sees it before typing), the questions to start with in the
    /// chosen library, the conversations before this one, how it works folded away, and the caution.
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 26) {
            // The card every Islam resource opens on (`ResourceHero`).
            if let focusArticle {
                ResourceHero(
                    eyebrow: String(localized: "ASK AI"),
                    systemImage: "sparkles",
                    headline: String(localized: "Ask about this article."),
                    message: String(localized: "Answers read \u{201C}\(focusArticle.title)\u{201D} first, then this app\u{2019}s Quran, hadith and other articles, with every source quoted beneath the reply.")
                )
            } else {
                ResourceHero(
                    eyebrow: String(localized: "ASK AI"),
                    systemImage: "sparkles",
                    headline: String(localized: "Ask anything about Islam."),
                    message: AskAICopy.heroMessage
                )
            }

            if focusArticle == nil, AskAIScope.available.count > 1 {
                VStack(alignment: .leading, spacing: 10) {
                    welcomeLabel(String(localized: "ANSWER FROM"))

                    // A Grid, not a lazy one: the two tiles of a row take the taller one's height (French
                    // and German names run to two lines).
                    let columns = dynamicTypeSize.isAccessibilitySize ? 1 : 2
                    let scopes = AskAIScope.available
                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                        ForEach(Array(stride(from: 0, to: scopes.count, by: columns)), id: \.self) { start in
                            GridRow {
                                ForEach(scopes[start..<min(start + columns, scopes.count)]) { scope in
                                    scopeTile(scope)
                                }
                                if columns == 2, start + 1 >= scopes.count {
                                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                welcomeLabel(focusArticle == nil && chat.scope != .everything
                             ? String(localized: "TRY ASKING \u{00B7} \(chat.scope.title.uppercased())")
                             : String(localized: "TRY ASKING"))

                ForEach(starters, id: \.self) { question in
                    starterButton(question)
                }
            }

            // The conversations before this one: a visit always opens a new one, and these are a
            // tap away.
            if !chat.recentChats.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    welcomeLabel(String(localized: "HISTORY"))

                    ForEach(chat.recentChats) { recent in
                        recentChatButton(recent)
                    }
                }
            }

            // How it works, in the app itself: a reader who knows where the quotes come from and
            // what the model is not allowed to do can judge what they are reading. Folded: it is
            // there for the reader who wants it, not in the way of the one who came to ask.
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.2)) { showsHowItWorks.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .frame(width: 22)
                        Text("How Ask AI works")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(showsHowItWorks ? 180 : 0))
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(showsHowItWorks ? .isSelected : [])

                if showsHowItWorks {
                    VStack(alignment: .leading, spacing: 14) {
                        howItWorksRow(icon: "magnifyingglass", text: AskAICopy.searchedAcross)
                        howItWorksRow(icon: "line.3.horizontal.decrease.circle", text: AskAICopy.scopes)
                        // The readings are named only while they are read: "Show Riwayah / Qiraah" on
                        // (`AskAIDepth.readsQiraat`).
                        if let readWith = quranDisplay.showOtherQiraatReciters ? AskAICopy.readWith : AskAICopy.readWithoutReadings {
                            howItWorksRow(icon: "books.vertical", text: readWith)
                        }
                        howItWorksRow(icon: cloudOffered ? "icloud" : "iphone", text: cloudOffered
                                      ? String(localized: "What it finds goes to Apple Intelligence on your device, or to Apple\u{2019}s Private Cloud Compute if you choose it in the menu, which answers in its own words and cites each source by number, saying where it comes from.")
                                      : String(localized: "What it finds goes to Apple Intelligence on your device, which answers in its own words and cites each source by number, saying where it comes from. Nothing leaves your phone."))
                        howItWorksRow(icon: "checkmark.shield", text: String(localized: "Every quote beneath an answer is this app\u{2019}s own text, never the model\u{2019}s memory. A citation it invents is removed, a quotation that matches nothing is marked \u{201C}wording not verified\u{201D}, and every source opens the real passage so you can check it yourself."))
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentSurface(rectangle: true, interactive: false)

            Label("This is a machine, not a scholar. It is here for quick, simple, general questions, and it can be confidently wrong. It does not give rulings, it is never the final answer, and anything that actually matters belongs with a knowledgeable scholar of Ahl as-Sunnah wa al-Jama\u{2018}ah.", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(.bottom, 8)
    }

    /// One library to answer from: its symbol in a disc, its name and what it holds. The chosen one
    /// is filled with the accent; a tap chooses it, and the questions under the grid follow.
    private func scopeTile(_ scope: AskAIScope) -> some View {
        let selected = chat.scope == scope
        let accent = settings.accentColor.color
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) { chat.scope = scope }
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: scope.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selected ? Color.white : accent)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(selected ? accent : accent.opacity(0.15)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(scope.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(scope.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 64, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .contentSurface(rectangle: true, useColor: selected ? 0.22 : nil, customTint: selected ? accent : nil)
            .overlay(
                RoundedRectangle(cornerRadius: GlassCorner.rectangle, style: .continuous)
                    .strokeBorder(selected ? accent.opacity(0.7) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// One question to tap: asks it at once.
    private func starterButton(_ question: String) -> some View {
        Button {
            settings.hapticFeedback()
            askedAboutArticle = true
            chat.ask(question)
        } label: {
            HStack(spacing: 12) {
                Text(question.localizedDisplay)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .contentSurface(rectangle: true)
        }
        .buttonStyle(.plain)
    }

    /// One earlier conversation: its first question and when it was last added to. A tap makes it
    /// the conversation again; a hold offers to delete it.
    private func recentChatButton(_ recent: AskAIConversation.SavedChat) -> some View {
        Button {
            settings.hapticFeedback()
            askedAboutArticle = false
            withAnimation(.easeInOut(duration: 0.2)) { chat.openRecent(recent.id) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recent.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(Self.relativeFormatter.localizedString(for: recent.updated, relativeTo: Date()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .contentSurface(rectangle: true)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut(duration: 0.2)) { chat.deleteRecent(recent.id) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    /// "5 minutes ago", "yesterday", in the interface's language.
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()

    /// Opened on an article over a conversation that was already going: the article's questions
    /// under the last answer, where the eye is, instead of the welcome's place at the top.
    private func articleQuestionsBlock(_ article: IslamArticle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            welcomeLabel(String(localized: "ABOUT THIS ARTICLE"))
            ForEach(Self.articleQuestions(article), id: \.self) { question in
                starterButton(question)
            }
        }
        .padding(.top, 4)
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
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Messages

    @ViewBuilder
    private func messageView(_ message: AskAIConversation.Message) -> some View {
        switch message.role {
        case .user:
            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    Spacer(minLength: 48)
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(settings.accentColor.color.opacity(0.2))
                        )
                        .textSelection(.enabled)
                }
                // The library it was asked of, when not everything.
                if let scope = message.scope {
                    AskAIScopeBadge(scope: scope)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        case .assistant:
            AskAIAnswerCard(message: message, isLast: message.id == chat.messages.last?.id) { suggestion in
                settings.hapticFeedback()
                askedAboutArticle = true
                chat.ask(suggestion)
            } onRetry: {
                settings.hapticFeedback()
                chat.retryLast()
            }
        }
    }

    // MARK: Composer

    /// The composer (2026-11-24): one glass card, the field across its whole width (the prompt was cut
    /// to "Ask about the Quran, hadith,..." beside a separate send circle), and under it the library
    /// the answer comes from, as a menu, with send (or stop) at the far end.
    private var inputBar: some View {
        let canSend = !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let accent = settings.accentColor.color
        return VStack(alignment: .leading, spacing: 6) {
            // The prompt drawn here, not as the field's placeholder: a placeholder is one line, and the
            // longer languages' prompts were cut ("Posez une question sur le Coran, les hadith...").
            ZStack(alignment: .topLeading) {
                if draft.isEmpty {
                    Text(AskAICopy.composerPrompt(for: chat.scope))
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                TextField("", text: $draft, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...6)
                    .focused($inputFocused)
                    .textFieldStyle(.plain)
                    .onSubmit { send() }
                    .accessibilityLabel(Text(AskAICopy.composerPrompt(for: chat.scope)))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            HStack(spacing: 8) {
                scopeMenu

                Spacer(minLength: 8)

                if chat.isAnswering {
                    Button {
                        settings.hapticFeedback()
                        chat.cancel()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.primary.opacity(0.12)))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stop answering")
                } else {
                    Button {
                        send()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(canSend ? .white : .secondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(canSend ? accent : Color.primary.opacity(0.1)))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                    .accessibilityLabel("Send")
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { inputFocused = true }
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.bottom, BottomBarCushion.standard)
        .background(Color.white.opacity(0.00001))
        .animation(.easeInOut(duration: 0.2), value: canSend)
        .animation(.easeInOut(duration: 0.2), value: chat.isAnswering)
    }

    /// The library menu under the field: the chosen one as a tinted capsule, every one inside.
    private var scopeMenu: some View {
        let accent = settings.accentColor.color
        return Menu {
            Picker(selection: $chat.scope) {
                ForEach(AskAIScope.available) { scope in
                    Label(scope.title, systemImage: scope.systemImage).tag(scope)
                }
            } label: {
                Text("Answer from")
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: chat.scope.systemImage)
                    .font(.caption.weight(.semibold))
                Text(chat.scope.title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .opacity(0.7)
            }
            .foregroundStyle(accent)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Capsule().fill(accent.opacity(chat.scope == .everything ? 0.1 : 0.2)))
            .contentShape(Capsule())
        }
        .accessibilityLabel(Text("Answer from \(chat.scope.title)"))
        .onChange(of: chat.scope) { _ in settings.hapticFeedback() }
    }

    private func send() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        settings.hapticFeedback()
        draft = ""
        askedAboutArticle = true
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
    static let scopes = String(localized: "Choose what to answer from, above your question or under ANSWER FROM: everything, or only the Quran, the hadith, the articles, the duas, or the prayer times of any city on any day.")
    static let lookingThrough = String(localized: "Looking through the Quran, hadith and articles\u{2026}")
    static let readWith: String? = String(localized: "The verses and hadiths that lead an answer are not read alone: each verse comes with its tafsir, the app\u{2019}s other translation and the readings (qiraat) that differ in it, and each hadith with its explanation and the other collections that record it. Each source beneath an answer lists what was read with it.")
    static let readWithoutReadings: String? = String(localized: "The verses and hadiths that lead an answer are not read alone: each verse comes with its tafsir and the app\u{2019}s other translation, and each hadith with its explanation and the other collections that record it. Each source beneath an answer lists what was read with it.")
    #elseif HAS_QURAN
    static let heroMessage = String(localized: "A question, a follow-up, a \u{201C}what does this mean\u{201D}: answered by Apple Intelligence from this app\u{2019}s own Quran, tafsir, articles and duas, with every source quoted beneath the reply and a line saying where it comes from.")
    static let searchedAcross = String(localized: "Your question is understood first (a greeting, a verse, a how-to, a question about the app), then searched across this app\u{2019}s own Quran, tafsir, articles, duas, Names of Allah and tips.")
    static let composerPrompt = String(localized: "Ask about the Quran or Islam")
    static let scopes = String(localized: "Choose what to answer from, above your question or under ANSWER FROM: everything, or only the Quran, the articles, or the duas.")
    static let lookingThrough = String(localized: "Looking through the Quran and articles\u{2026}")
    static let readWith: String? = String(localized: "The verses that lead an answer are not read alone: each comes with its tafsir, the app\u{2019}s other translation and the readings (qiraat) that differ in it. Each source beneath an answer lists what was read with it.")
    static let readWithoutReadings: String? = String(localized: "The verses that lead an answer are not read alone: each comes with its tafsir and the app\u{2019}s other translation. Each source beneath an answer lists what was read with it.")
    #else
    // No Quran and no hadith shelf (Al-Adhan): the prayer times, the articles, the duas, the Names
    // and the tips are what AskAIRetrieval.swift searches here.
    static let heroMessage = String(localized: "A question, a follow-up, a \u{201C}what does this mean\u{201D}: answered by Apple Intelligence from this app\u{2019}s own prayer times, articles, duas, Names of Allah and tips, with every source quoted beneath the reply and a line saying where it comes from.")
    static let searchedAcross = String(localized: "Your question is understood first (a greeting, a how-to, a question about the app), then searched across this app\u{2019}s own prayer times, articles, duas, Names of Allah and tips.")
    static let composerPrompt = String(localized: "Ask about prayer or Islam")
    static let scopes = String(localized: "Choose what to answer from, above your question or under ANSWER FROM: everything, or only the articles, the duas, or the prayer times of any city on any day.")
    static let lookingThrough = String(localized: "Looking through the app\u{2019}s articles\u{2026}")
    static let readWith: String? = nil
    static let readWithoutReadings: String? = nil
    #endif

    /// The field's prompt for the library chosen.
    static func composerPrompt(for scope: AskAIScope) -> String {
        switch scope {
        case .everything: return composerPrompt
        case .quran: return String(localized: "Ask what the Quran says")
        case .hadith: return String(localized: "Ask what the hadith say")
        case .articles: return String(localized: "Ask a how-to or a belief")
        case .duas: return String(localized: "Ask for a dua or a Name of Allah")
        case .prayerTimes: return String(localized: "Ask a prayer time, anywhere, any day")
        }
    }
}

/// The library a turn was asked of, as a small tinted capsule: under the question, and beside the
/// answer's AI label.
@available(iOS 16.0, *)
private struct AskAIScopeBadge: View {
    let scope: AskAIScope
    private let settings = Settings.shared

    var body: some View {
        Label {
            Text(scope.title)
        } icon: {
            Image(systemName: scope.systemImage)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(settings.accentColor.color)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(settings.accentColor.color.opacity(0.14)))
        .accessibilityLabel(Text("Answered from \(scope.title)"))
    }
}

/// The chat presented as a sheet (from the search screens), in its own navigation stack so the
/// source cards can push the reader.
@available(iOS 16.0, *)
struct AskAIChatSheet: View {
    var initialQuestion: String? = nil
    /// The article the sheet was opened from (`AskAIChatView.focusArticle`).
    var focusArticle: IslamArticle? = nil

    var body: some View {
        SheetNavigationContainer {
            AskAIChatView(initialQuestion: initialQuestion, presentedAsSheet: true, focusArticle: focusArticle)
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
        VStack(alignment: .leading, spacing: 14) {
            header

            if message.text.isEmpty {
                Text(statusLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if !message.hasAnswerProse {
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

            // The help line as a thing to tap: the number for the reader's region, or the finder.
            if message.offersHelpLine, !message.isStreaming,
               let action = AskAICrisis.helpLineAction(regionCode: Locale.current.region?.identifier) {
                Link(destination: action.url) {
                    Label(action.label, systemImage: action.url.scheme == "tel" ? "phone.fill" : "safari")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(settings.accentColor.color)
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

            // A decline lists what the app found in the open: its text says the sources are below.
            if !message.isStreaming, !uncited.isEmpty, message.declined {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SOURCES THE APP FOUND")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    ForEach(uncited) { source in
                        AskAISourceCard(number: number(of: source), source: source)
                    }
                }
            } else if !message.isStreaming, !uncited.isEmpty {
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
            // A failure that streamed prose before it ("...\n\n(Apple Intelligence declined...)")
            // is AI prose too, and keeps the caution.
            if !message.isStreaming, message.hasAnswerProse, !(message.intent?.isConversational ?? false), message.intent != .crisis {
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Regular glass, not clear: clear glass on a dark ground is invisible, and the answer
        // read as loose text floating in the transcript instead of a card.
        .contentSurface(rectangle: true, interactive: false)
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
            // The crisis reply is the app's own words, not the model's: no AI label, no engine badge.
            if message.intent == .crisis {
                Image(systemName: "heart.fill")
                    .font(.caption)
                Text(AppIdentifiers.displayName)
                    .font(.caption.weight(.semibold))
            } else {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("AI")
                    .font(.caption.weight(.semibold))
            }
            if let engine = message.engine {
                Text(engine.badge)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(settings.accentColor.color.opacity(0.14)))
            }
            if let scope = message.scope {
                AskAIScopeBadge(scope: scope)
            }
            if message.isStreaming {
                ProgressView()
                    .controlSize(.mini)
            }
            Spacer()
            // The answer to send on as it stands, its sources quoted under it (it was only in the
            // card's long-press menu: Abu, 2026-11-24, "allow me to share ... ask ai").
            if !message.isStreaming, message.hasAnswerProse, message.intent != .crisis {
                ShareLink(item: AskAIText.shareText(answer: message.text, cited: cited, allSources: message.sources)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share Answer")
            }
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

    /// The follow-ups, one to a line and whole (a sideways row of chips cut the last one off at the
    /// card's edge: "What are the sunnah p").
    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ASK NEXT")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(message.suggestions, id: \.self) { suggestion in
                Button {
                    onSuggestion(suggestion)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                        // As the question is sent: English, as the follow-ups always were.
                        Text(verbatim: suggestion)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .contentSurface(rectangle: true)
                }
                .buttonStyle(.plain)
            }
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
        // Body size (it was the subheadline): the answer is what the screen is for.
        let size = UIFont.preferredFont(forTextStyle: .body).pointSize
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

    /// `-askAIExpandSources` (DEBUG) opens every card, to see the notes headlessly.
    @State private var expanded: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-askAIExpandSources")
        #else
        return false
        #endif
    }()

    var body: some View {
        Group {
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
        // A tap reads the source here, inside the chat; the menu opens it in its own tab, to read
        // in full, bookmark or share (Abu, 2026-11-24: "Maybe update ask AI too?").
        .contextMenu {
            if let open = AskAISourceLink.openRow(for: source.kind) {
                Button {
                    settings.hapticFeedback()
                    if let link = AskAISourceLink.link(for: source.kind) { AppLinkRouter.open(link) }
                } label: {
                    Label(open.title, systemImage: open.systemImage)
                }

                Button {
                    if let link = AskAISourceLink.link(for: source.kind) {
                        AppLinkShare.share(link, title: displayTitle)
                    }
                } label: {
                    Label("Share Link", systemImage: "link")
                }
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = [displayTitle, source.arabic, source.text].compactMap { $0 }
                    .filter { !$0.isEmpty }.joined(separator: "\n\n")
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }

    private var accent: Color { settings.accentColor.color.opacity(dimmed ? 0.7 : 1) }

    private var showsArabic: Bool {
        switch source.kind {
        case .ayah, .dua, .hisnDua, .name: return source.arabic?.isEmpty == false
        default: return false
        }
    }

    /// A card with notes always opens: closed it only names what was read with the source.
    private var isLong: Bool { source.text.count > 280 || (source.arabic?.count ?? 0) > 120 || !source.notes.isEmpty }

    /// The title line in the interface's language: in Arabic an ayah or a surah is named in Arabic.
    /// `source.title` itself stays as written: the model read it and the transcript stores it.
    private var displayTitle: String {
        #if HAS_QURAN
        if AppLanguage.isArabicScript {
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
        case .cityPrayer:
            #if HAS_ADHAN
            return true
            #else
            return false
            #endif
        #if !HAS_QURAN
        case .ayah, .tafsir, .surah: return false
        #endif
        #if !HAS_HADITH
        case .hadith: return false
        #endif
        #if !HAS_TIPS
        case .tip: return false
        #endif
        // A page built for the AI on the spot (a lesson, a hadith's explanation) has no screen of
        // its own to push from here.
        case .article(let id, _): return IslamArticles.destination(for: id) != nil
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
                    Text(source.kindLabel.localizedUppercase)
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

                if !source.notes.isEmpty {
                    notesBlock
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

    /// What was read WITH the source (`AskAISource.notes`): closed, one line naming each note (the
    /// other translation, the tafsir, the readings, the explanation, the parallel narrations);
    /// open, each note under its name, exactly as the model was shown it.
    @ViewBuilder
    private var notesBlock: some View {
        if expanded {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(source.notes) { note in
                    VStack(alignment: .leading, spacing: 3) {
                        Label(note.displayLabel.localizedUppercase, systemImage: note.systemImage)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(accent)
                        Text(note.isQuotable ? "\u{201C}\(note.text)\u{201D}" : note.text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            // The notes are English (what the model read), left to right in every interface.
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .leftToRightContent(!note.text.isMostlyArabicScript)
                    }
                }
            }
            .padding(.top, 2)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(.caption2.weight(.semibold))
                Text(source.notes.map(\.displayLabel).joined(separator: " \u{2022} ").localizedUppercase)
                    .font(.caption2.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(accent)
            .padding(.top, 1)
        }
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

/// A source's place in the app as a shared link: what its card's "Open in Quran" / "Open in Hadith"
/// and "Share Link" use. The hadith's printed number is read from its book only when a row is tapped.
@MainActor
enum AskAISourceLink {
    static func openRow(for kind: AskAISource.Kind) -> (title: String, systemImage: String)? {
        switch kind {
        #if HAS_QURAN
        case .ayah, .tafsir, .surah: return (OpenInTab.quranTitle, OpenInTab.quranSymbol)
        #endif
        #if HAS_HADITH
        case .hadith: return (OpenInTab.hadithTitle, OpenInTab.hadithSymbol)
        #endif
        case .article(let id, _):
            return AppLink.articlePage(id: id) == nil ? nil : (String(localized: "Open Article"), "doc.text")
        case .name: return (String(localized: "Open in the 99 Names"), "sparkles")
        #if HAS_ADHAN
        case .cityPrayer: return (String(localized: "Open in City Prayer Times"), "map")
        #endif
        default: return nil
        }
    }

    static func link(for kind: AskAISource.Kind) -> AppLink? {
        switch kind {
        // No link to a tab the app lacks (Al-Adhan has no Quran tab): no Share Link either, as before.
        #if HAS_QURAN
        case .ayah(let surah, let ayah): return AppLink(key: "quran", value: "\(surah):\(ayah)")
        case .tafsir(let surah, let ayah, _): return .tafsir(surah: surah, ayah: ayah)
        case .surah(let surah): return AppLink(key: "quran", value: "\(surah)")
        #endif
        case .hadith(let slug, let idInBook):
            #if HAS_HADITH
            guard let book = HadithCatalogBook.bySlug[slug], let data = HadithStore.shared.book(book),
                  let row = data.hadith(numbered: idInBook) else { return nil }
            return AppLink.hadith(row, in: book, data: data)
            #else
            let _ = (slug, idInBook)
            return nil
            #endif
        case .article(let id, _): return AppLink.articlePage(id: id)?.link
        case .name(let number): return AppLink(key: "name", value: String(number))
        default: return nil
        }
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
        case .cityPrayer(let latitude, let longitude, let city, let day):
            #if HAS_ADHAN
            PrayerTimesMapView(initialLocation: Location(city: city, latitude: latitude, longitude: longitude),
                               initialDate: day, showsCloseButton: false)
            #else
            let _ = (latitude, longitude, city, day)
            EmptyView()
            #endif
        }
    }
}

#endif
