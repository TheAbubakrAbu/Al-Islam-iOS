import SwiftUI

// "Summarize" - a faithful, on-device AI summary of whatever long text the reader currently has
// open (a tafsir passage, a surah's background prose, or a translation comparison), with follow-up
// chat grounded on that SAME text. Reuses the OnDeviceAsk machinery: the ~3B-parameter Apple
// Intelligence model, its availability gate, and its guardrails (no fabrication, no recreated
// quotations, never a religious ruling).
//
// Entry points pass a title plus the source text. One text of any length is read WHOLE: a short one
// in one request, a long one part by part to its end (`OnDeviceAsk.streamTextSummary`), with a bar
// that shows how far the reading has got, and a question afterwards is answered from the passages of
// the text that bear on it. Several texts at once ("all tafsirs") arrive already combined and fitted
// by the caller, and are sent as they are. What the model writes arrives a few words at a time, four
// times a second; `StreamReveal` lays it down word by word, straight into the text view.
//
// While the model writes it has the phone's graphics chip, so the sheet draws as little as it can:
// a redraw is the new words appended (never the whole text set again), the sheet's own body is not
// evaluated per snapshot, and nothing is redrawn while the reader's finger is scrolling.
//
// Availability mirrors OnDeviceAsk: iOS 26+ with Apple Intelligence enabled. Entry points hide the
// button entirely when unavailable (the OnDeviceAsk pattern); the sheet still carries a placeholder
// for the edge where availability flips while it is open.

#if os(iOS) && canImport(FoundationModels)

struct SummarizeSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.dismiss) private var dismiss

    /// What the source text IS, shown to the user and to the model (e.g. "Ibn Kathir on Al-Baqarah 2:153").
    let title: String
    /// `title` in the reader's language, for the sheet itself. `title` also goes to the model, which reads
    /// English, so a caller with an interface translation passes it here.
    var displayTitle: String? = nil
    /// The text to summarize - exactly what the sheet the user came from is showing.
    let sourceText: String
    /// Multi-source mode ("all tafsirs" / "all surah info"): `sourceText` (or the gathered text) is a
    /// set of "=== label ===" sections built by `OnDeviceAsk.combinedSource`; the model reads all of
    /// them - Arabic included - writes in English, and names sources in follow-ups.
    var multiSource: Bool = false
    /// Whether the caller's pre-combined multi-source text had sections shortened
    /// (`combinedSource`'s flag) - drives the note card's truncation disclosure.
    var sourceTruncated: Bool = false
    /// When set, the source is gathered asynchronously BEFORE summarizing (the tafsir sheet fetches
    /// the editions not yet loaded); the sheet shows a gathering state meanwhile. The closure returns
    /// the pre-combined, pre-clipped text plus its truncation flag - `sourceText` is ignored.
    var gatherSource: (() async -> (text: String, truncated: Bool))? = nil
    /// The language the summary and every follow-up answer are written in (Abu, 2026-09-05: the
    /// Arabic tafsirs get a "summarize in Arabic" button next to the English one).
    var language: OnDeviceAsk.SummaryLanguage = .english
    /// Multi-source mode focused on ONE section (its "=== label ==="): the rest is context the model
    /// reads but does not summarize. See `OnDeviceAsk.streamSummary(focus:)`.
    var focus: String? = nil
    /// What the caller left OUT of the source and why (the Arabic editions while the model has no
    /// Arabic) - appended to the note card so the reader knows the summary's reach.
    var excludedNote: String? = nil
    /// `sourceText` is a whole article page (every section under its heading): the note says "page".
    var isPage = false

    private var writesArabic: Bool { language == .arabic }

    private struct Turn: Identifiable {
        let id = UUID()
        let question: String
        /// The whole answer, set once it is written (`answerReveal` holds it until then).
        var answer: String
        var isStreaming: Bool
        /// The first words have arrived: the text takes the place of "Thinking…".
        var hasText = false
        var failed = false
    }

    /// The whole summary, set once it is written. While it is being written `summaryReveal` holds it:
    /// a `@State` set per snapshot would run this sheet's body four times a second for nothing.
    @State private var summary = ""
    /// The first words of the summary have arrived.
    @State private var summaryStarted = false
    @State private var summaryReveal = StreamReveal()
    /// The answer being written to the newest question, drawn the same way.
    @State private var answerReveal = StreamReveal()
    /// How much of a long text has been read (0 to 1), while it is being read in parts.
    @State private var readProgress: Double?
    /// The next part is being read: the paragraphs so far stand, with a line that says so.
    @State private var isReadingOn = false
    /// How far the summary read, when it ended before the text did (`OnDeviceAsk.summarizeReach`).
    @State private var stoppedAt: Int?
    /// A scroll by hand means the reader is reading: the newest answer stops pulling the scroll to itself.
    @State private var followsAnswer = true
    @State private var isSummarizing = false
    @State private var summaryFailed = false
    /// The model's own reason when it has one the reader can act on (`OnDeviceAsk.failureMessage`),
    /// else nil and the generic wording applies.
    @State private var summaryFailureMessage: String?
    /// The shortened source a context-overflow retry summarized - follow-ups ground on the same text.
    @State private var leanerSource: String?
    @State private var turns: [Turn] = []
    @State private var questionText = ""
    @State private var streamTask: Task<Void, Never>?
    @FocusState private var inputFocused: Bool
    /// The async-gathered source (nil until `gatherSource` returns; unused without a gatherer).
    @State private var gathered: (text: String, truncated: Bool)?
    @State private var isGathering = false

    /// Several texts the caller combined and fitted itself (`OnDeviceAsk.combinedSource`, a gatherer,
    /// a focused Arabic edition): sent to the model as they are. Everything else is ONE text, read whole.
    private var isPrefitted: Bool { multiSource || gatherSource != nil || focus != nil }

    /// The grounded source, used for the summary and every follow-up, and whether it is less than
    /// the whole: a combined text whose sections were shortened, or one text longer than a summary reads.
    private var groundedSource: (text: String, truncated: Bool) {
        if let gathered { return gathered }
        if gatherSource != nil { return ("", false) }   // still gathering
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if isPrefitted { return (trimmed, sourceTruncated) }
        return (trimmed, stoppedAt != nil || trimmed.count > OnDeviceAsk.summarizeReach)
    }

    /// How many characters of one long text the summary reads: what it did read once it has stopped,
    /// the most it can before then.
    private var reachedCharacters: Int { stoppedAt ?? OnDeviceAsk.summarizeReach }

    private var isStreaming: Bool {
        isGathering || isSummarizing || turns.contains { $0.isStreaming }
    }

    var body: some View {
        SheetNavigationContainer {
            Group {
                if OnDeviceAsk.isAvailable {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                sourceNoteCard
                                summaryCard

                                ForEach(turns) { turn in
                                    turnView(turn)
                                }

                                // Scroll anchor: the input bar scrolls here as answers grow.
                                Color.clear.frame(height: 1).id("summarize-bottom")
                            }
                            .padding()
                        }
                        .dismissKeyboardOnScroll()
                        // While the reader scrolls nothing is written into the text: the scroll gets
                        // the whole frame, and the words catch up when it rests. A scroll by hand also
                        // means they are reading, so the newest answer stops pulling the foot into view.
                        .modifier(ScrollingByHand { scrolling in
                            summaryReveal.isHeld = scrolling
                            answerReveal.isHeld = scrolling
                            if scrolling, followsAnswer { followsAnswer = false }
                        })
                        // A new question comes into view; its answer then keeps the foot in view as it
                        // takes each new line, until the reader scrolls or asks again.
                        .onChange(of: turns.count) { _ in
                            followsAnswer = true
                            withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("summarize-bottom", anchor: .bottom) }
                        }
                        .onReceive(answerReveal.$lines) { _ in
                            guard followsAnswer, turns.last?.isStreaming == true else { return }
                            proxy.scrollTo("summarize-bottom", anchor: .bottom)
                        }
                        // `adaptiveSafeArea`, as the Ask AI chat's composer: in a sheet it carries the
                        // Now Playing bar above the field, never under it.
                        .adaptiveSafeArea(edge: .bottom) {
                            inputBar
                        }
                    }
                } else {
                    unavailableView
                }
            }
            .navigationTitle("Summarize")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .accentWashedBackground()
        }
        // Sized here, not at each call site: the ayah, surah, tafsir, riwayah and hadith screens all
        // present this one type.
        .smallMediumSheetPresentation()
        .task {
            // The model comes into memory while the sheet rises and, for a gatherer, while the
            // texts are fetched.
            if #available(iOS 26.0, *) { OnDeviceAsk.prewarmSummaries() }
            // Gather first when the caller fetches sources on demand (the tafsir sheet loading the
            // editions it hasn't yet) - the note card shows a gathering state meanwhile.
            if let gatherSource, gathered == nil {
                guard OnDeviceAsk.isAvailable else { return }
                isGathering = true
                gathered = await gatherSource()
                isGathering = false
            }
            await startSummary()
            #if DEBUG
            // "-summaryAsk <question>": asked once the summary is written (the field cannot be typed
            // into headlessly); with `-summaryProbe` the answer lands in Documents/summary-answer.txt.
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "-summaryAsk"), arguments.indices.contains(index + 1),
               turns.isEmpty, !summary.isEmpty {
                questionText = arguments[index + 1]
                sendFollowUp()
            }
            #endif
        }
        .onDisappear {
            streamTask?.cancel()
            streamTask = nil
        }
    }

    // MARK: - Streaming

    private func startSummary() async {
        guard OnDeviceAsk.isAvailable, summary.isEmpty, !summaryStarted, !isSummarizing else { return }
        guard #available(iOS 26.0, *) else { return }

        // Capture plain values BEFORE the detachable work: the stream builder must never read
        // main-isolated view state from its own task.
        let title = self.title
        let multiSource = self.multiSource
        let language = self.language
        let focus = self.focus
        let prefitted = isPrefitted
        let source = groundedSource.text
        guard !source.isEmpty else {
            // A gatherer that came back with nothing (every fetch failed) is a real failure, not
            // the silent no-op an empty static source is.
            summaryFailed = gatherSource != nil
            return
        }

        isSummarizing = true
        summaryFailed = false

        streamTask?.cancel()
        streamTask = Task { @MainActor in
            // The summary so far. It reaches `summary` once, at the end.
            var latest = ""
            #if DEBUG
            let probe = SummaryProbe(label: prefitted ? "combined" : "text", sourceCharacters: source.count)
            var probeOutcome = "ok"
            defer {
                probe?.finish(characters: latest.count, paints: summaryReveal.paints, outcome: probeOutcome)
                // The summary itself, to read back from the app's container.
                if probe != nil, let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    try? latest.write(to: documents.appendingPathComponent("summary-probe.txt"), atomically: true, encoding: .utf8)
                }
            }
            #endif
            @MainActor func show(_ snapshot: String) {
                #if DEBUG
                probe?.token()
                #endif
                latest = Self.plainProse(snapshot)
                summaryReveal.receive(latest)
                if !summaryStarted, !latest.isEmpty { summaryStarted = true }
            }
            // One leaner retry on a context overflow, for a combined text: a dense one can still tip
            // the 4,096-token window at the character budgets, and two thirds of it summarized beats
            // a failure. (One text read in parts retries each part itself.)
            var attemptSource = source
            var retriedLeaner = false
            while true {
                do {
                    if prefitted {
                        for try await snapshot in OnDeviceAsk.streamSummary(
                            title: title, source: attemptSource, multiSource: multiSource, language: language, focus: focus
                        ) {
                            show(snapshot)
                        }
                    } else {
                        for try await progress in OnDeviceAsk.streamTextSummary(title: title, text: source, language: language) {
                            if !progress.text.isEmpty { show(progress.text) }
                            // Each of these is written only when it moved: a write is a redraw of the sheet.
                            if isReadingOn != progress.isReading { isReadingOn = progress.isReading }
                            if progress.isInParts {
                                let fraction = Double(progress.read) / Double(max(1, progress.total))
                                if readProgress != fraction {
                                    withAnimation(.easeOut(duration: 0.3)) { readProgress = fraction }
                                }
                            }
                            if progress.stoppedShort, stoppedAt != progress.read { stoppedAt = progress.read }
                        }
                    }
                } catch {
                    if error is CancellationError { break }
                    #if DEBUG
                    NSLog("SUMMARIZE FAILED: %@", String(describing: error))
                    probeOutcome = "failed"
                    #endif
                    if prefitted, !retriedLeaner, latest.isEmpty, OnDeviceAsk.isContextOverflow(error) {
                        retriedLeaner = true
                        attemptSource = String(attemptSource.prefix(attemptSource.count * 2 / 3)) + "…"
                        leanerSource = attemptSource
                        continue
                    }
                    summaryFailed = latest.isEmpty
                    summaryFailureMessage = OnDeviceAsk.failureMessage(for: error)
                }
                break
            }
            if isReadingOn { isReadingOn = false }
            // The spinner stops when the last words are on screen, not when the model sent them.
            await summaryReveal.settle()
            summary = latest
            withAnimation(.easeOut(duration: 0.3)) { readProgress = nil }
            isSummarizing = false
        }
        await streamTask?.value
    }

    private func sendFollowUp() {
        let question = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isStreaming else { return }
        guard #available(iOS 26.0, *), OnDeviceAsk.isAvailable else { return }

        questionText = ""

        // Snapshot everything the stream needs as plain values, before leaving the main actor.
        let title = self.title
        let multiSource = self.multiSource
        let language = self.language
        let focus = self.focus
        let prefitted = isPrefitted
        let source = prefitted ? (leanerSource ?? groundedSource.text) : groundedSource.text
        let summary = self.summary
        guard !source.isEmpty else { return }
        let transcript = turns
            .filter { !$0.answer.isEmpty && !$0.failed }
            .map { OnDeviceAsk.SummarizeTurn(question: $0.question, answer: $0.answer) }

        answerReveal.reset()
        turns.append(Turn(question: question, answer: "", isStreaming: true))
        let turnID = turns[turns.count - 1].id

        streamTask?.cancel()
        streamTask = Task { @MainActor in
            // A combined text is re-sent whole, as it was summarized; one text of any length is
            // answered from the passages of it that bear on the question. A combined text with a
            // long conversation behind it can overflow the window: once, without the conversation.
            var sentTranscript = transcript
            var retriedBare = false
            // The answer so far. It reaches the turn once, at the end: a write per snapshot would run
            // the sheet's body, and every turn's, four times a second.
            var latest = ""
            while true {
                do {
                    let stream = prefitted
                        ? OnDeviceAsk.streamFollowUp(title: title, source: source, transcript: sentTranscript, question: question,
                                                     multiSource: multiSource, language: language, focus: focus)
                        : OnDeviceAsk.streamTextFollowUp(title: title, text: source, summary: summary, transcript: sentTranscript,
                                                         question: question, language: language)
                    for try await snapshot in stream {
                        let wasEmpty = latest.isEmpty
                        latest = Self.plainProse(snapshot)
                        answerReveal.receive(latest)
                        if wasEmpty, !latest.isEmpty { updateTurn(turnID) { $0.hasText = true } }
                    }
                    await answerReveal.settle()
                    let answer = latest
                    updateTurn(turnID) {
                        $0.answer = answer
                        $0.isStreaming = false
                    }
                    #if DEBUG
                    if SummaryProbe.enabled, let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        try? "Q: \(question)\nA: \(answer)\n".write(to: documents.appendingPathComponent("summary-answer.txt"),
                                                                    atomically: true, encoding: .utf8)
                    }
                    #endif
                } catch {
                    if !(error is CancellationError), !retriedBare, !sentTranscript.isEmpty,
                       latest.isEmpty, OnDeviceAsk.isContextOverflow(error) {
                        retriedBare = true
                        sentTranscript = []
                        continue
                    }
                    await answerReveal.settle()
                    let answer = latest
                    updateTurn(turnID) {
                        $0.answer = answer
                        $0.isStreaming = false
                        if answer.isEmpty, !(error is CancellationError) { $0.failed = true }
                    }
                }
                break
            }
        }
    }


    private func updateTurn(_ id: UUID, _ mutate: (inout Turn) -> Void) {
        guard let index = turns.firstIndex(where: { $0.id == id }) else { return }
        mutate(&turns[index])
    }

    /// The model is told "no markdown", and still headed a single-tafsir summary "### Summary:" with
    /// "**bold**" points (seen 2026-09-05) and set an Arabic term in "*italics*" (2026-11-25). The
    /// sheet renders plain text, so the markers would show as-is: strip heading hashes, bold and
    /// italic asterisks and backticks, keeping the words; a "* " that opens a line is a bullet.
    static func plainProse(_ text: String) -> String {
        var lines: [String] = []
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                line = String(trimmed.drop(while: { $0 == "#" })).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("* ") {
                line = "• " + trimmed.dropFirst(2)
            }
            line = line.replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "`", with: "")
            if line.contains("*") {
                line = line.replacingOccurrences(of: #"\*(\S(?:[^*]*\S)?)\*"#, with: "$1", options: .regularExpression)
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Pieces

    private var sourceNoteText: String {
        let base = sourceNoteBase
        guard let excludedNote, !isGathering else { return base }
        return base + " " + excludedNote
    }

    private var sourceNoteBase: String {
        if isGathering {
            return String(localized: "Gathering every available text for this summary…")
        }
        if isPage, !groundedSource.truncated {
            return String(localized: "Summarizing this page, and answering questions about it.")
        }
        if let focus {
            return groundedSource.truncated
                ? String(localized: "Summarizing \(focus) only (shortened to fit the on-device model). The ayah's English translations and an English commentary are given to the model just to help it read the Arabic; questions are answered from the focused text first.")
                : String(localized: "Summarizing \(focus) only. The ayah's English translations and an English commentary are given to the model just to help it read the Arabic; questions are answered from the focused text first.")
        }
        if multiSource || gatherSource != nil {
            return groundedSource.truncated
                ? String(localized: "Summarizing ALL the available texts together. Longer ones were shortened proportionally to fit the on-device model.")
                : String(localized: "Summarizing ALL the available texts together, and answering questions about any of them.")
        }
        // One text is read whole, in parts when it is long. Only a text past what a summary reads
        // (`OnDeviceAsk.summarizeReach`, about 75,000 characters) says how far the reading went.
        if writesArabic {
            return groundedSource.truncated
                ? String(localized: "Summarizing the first \(reachedCharacters.formatted()) characters of this text in Arabic. It was shortened to fit the on-device model.")
                : String(localized: "Summarizing the text currently shown in Arabic, and answering questions about it.")
        }
        return groundedSource.truncated
            ? String(localized: "Summarizing the first \(reachedCharacters.formatted()) characters of this text. It was shortened to fit the on-device model.")
            : String(localized: "Summarizing the text currently shown, and answering questions about it.")
    }

    private var sourceNoteCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label((displayTitle ?? title).localizedDigits, systemImage: "doc.plaintext")
                .font(.subheadline.weight(.semibold))

            Text(sourceNoteText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    /// The Ask AI chat's reply-card language: sparkles header, streaming spinner, integrity footer.
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("AI Summary")
                    .font(.caption.weight(.semibold))

                if isSummarizing || isGathering {
                    ProgressView()
                        .controlSize(.mini)
                }

                Spacer()
            }
            .foregroundStyle(settings.accentColor.color)

            // A long text is read in parts: how far the reading has got.
            if let readProgress, isSummarizing {
                ProgressView(value: min(1, max(0, readProgress)))
                    .tint(settings.accentColor.color)
                    .accessibilityLabel("Reading the text…")
                    .transition(.opacity)
            }

            if summaryFailed {
                Text(summaryFailureMessage
                     ?? (gatherSource != nil
                         ? String(localized: "Couldn't load the texts to summarize. Check your connection, close, and try again.")
                         : String(localized: "The on-device model couldn't summarize this text. Close and try again.")))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if !summaryStarted {
                Text(isGathering ? "Gathering the texts…" : "Reading the text…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // The one text view the summary is written into; it stays once the summary is whole.
                SummaryProse(reveal: summaryReveal, isArabic: writesArabic)

                // Between two parts of a long text nothing new arrives for a moment: say why.
                if isReadingOn {
                    Text("Reading the text…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }

            Text(multiSource || gatherSource != nil
                 ? "From Apple Intelligence, on device • summarized only from the listed source texts • not a religious ruling"
                 : "From Apple Intelligence, on device • summarized only from the text shown • not a religious ruling")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentSurface(clear: true, rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(settings.accentColor.color.opacity(0.18), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func turnView(_ turn: Turn) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // The user's question, trailing - a chat bubble in the accent wash.
            Text(turn.question)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(settings.accentColor.color.opacity(0.15))
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("Answer")
                        .font(.caption.weight(.semibold))

                    if turn.isStreaming {
                        ProgressView()
                            .controlSize(.mini)
                    }

                    Spacer()
                }
                .foregroundStyle(settings.accentColor.color)

                if turn.failed {
                    Text("The on-device model couldn't answer that. Try rephrasing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if turn.answer.isEmpty, !turn.hasText {
                    Text("Thinking…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    // Written into while it streams, then the same view holding the whole answer.
                    SummaryProse(reveal: turn.isStreaming ? answerReveal : nil, text: turn.answer, isArabic: writesArabic)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentSurface(clear: true, rectangle: true)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(settings.accentColor.color.opacity(0.18), lineWidth: 1)
            )
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about this text…", text: $questionText)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { sendFollowUp() }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .conditionalGlassEffect(clear: true, rectangle: true)

            Button {
                settings.hapticFeedback()
                sendFollowUp()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isStreaming)
            .foregroundStyle(settings.accentColor.color)
            .accessibilityLabel("Send question")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    /// Availability flipped off while the sheet was open (the entry buttons are already hidden when
    /// unavailable) - the same story OnDeviceAsk tells: no Apple Intelligence, no feature.
    private var unavailableView: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Apple Intelligence Unavailable")
                .font(.headline)

            Text(String(localized: "Summarize runs entirely on device and needs Apple Intelligence enabled on a supported device (iOS 26 or later).").localizedDigits)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

/// Text that arrives in lumps, laid down word by word. The model hands over the answer so far about
/// four times a second, a dozen words at a time (measured 2026-11-25), and drawn as it came the text
/// jerked forward in steps. Each snapshot is the target here; twelve times a second a quarter of what
/// is still owed is written, to the end of a word, so the words run on evenly a third of a second
/// behind the model and catch up when it pauses.
///
/// It writes into the text view itself (`SummaryProse` hands it over): the new words are appended to
/// the view's storage, so TextKit typesets those words and no others, and SwiftUI is told only when
/// the text takes another line. The first version (the same day) published the text and let SwiftUI
/// redraw `SelectableProse` thirty times a second: 4.5 ms of main thread a redraw, 133 ms a second
/// against 29 for drawing the lumps as they came, and 42 passes of the run loop longer than one of the
/// phone's 120 frames a second while scrolled, against 4. Smooth on the 60-frame simulator, which is
/// why it shipped to Abu's desk; the count of long passes (`-summaryProbe`, `over8`) is the check now.
///
/// While the reader's finger scrolls (`isHeld`) nothing is written at all. Reduce Motion shows each
/// snapshot as it comes.
@MainActor
final class StreamReveal: NSObject, ObservableObject {
    /// How many lines the text has taken so far; the sheet follows an answer's foot by it. Nothing
    /// observes this object as a view does, so a publish runs that one closure and no body.
    @Published private(set) var lines = 0
    /// The reader is scrolling: the text waits (four seconds at most, in case a scroll never reports
    /// its end).
    var isHeld = false {
        didSet { if isHeld, !oldValue { heldSince = CACurrentMediaTime() } }
    }
    /// How many times the text was redrawn (`-summaryProbe`).
    private(set) var paints = 0

    /// The latest whole text from the model, and how many UTF-16 units of it are written.
    private var target: NSString = ""
    private var shown = 0
    private weak var view: UITextView?
    private var attributes: [NSAttributedString.Key: Any] = [:]
    private var height: CGFloat = 0
    private var heldSince = 0.0
    private var link: CADisplayLink?
    private var waiters: [CheckedContinuation<Void, Never>] = []

    /// The latest whole text from the model.
    func receive(_ snapshot: String) {
        let next = snapshot as NSString
        guard !next.isEqual(to: target as String) else { return }
        // Usually the old text with more after it. When what is written is no longer its opening (a
        // repeated sentence cut away, a markdown mark stripped), writing restarts where they part.
        let written = target.substring(to: min(shown, target.length))
        if !next.hasPrefix(written) {
            shown = (written as NSString).commonPrefix(with: snapshot, options: .literal).utf16.count
            if let storage = view?.textStorage, storage.length > shown {
                storage.deleteCharacters(in: NSRange(location: shown, length: storage.length - shown))
            }
        }
        target = next
        var whole = UIAccessibility.isReduceMotionEnabled
        #if DEBUG
        if SummaryProbe.drawsAsItComes { whole = true }
        #endif
        if whole { return write(upTo: target.length) }
        guard link == nil, shown < target.length else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 15, preferred: 12)
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    /// Returns once everything received is on screen.
    func settle() async {
        guard link != nil, shown < target.length else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    /// Back to empty, for the next answer. The view that showed the last one keeps its text.
    func reset() {
        stop()
        view = nil
        target = ""
        shown = 0
        height = 0
    }

    /// The text view this writes into, with the look of its text. Whatever is written so far is set
    /// on it whole (a view made again when the text size changes starts from there).
    func attach(_ view: UITextView, attributes: [NSAttributedString.Key: Any]) {
        guard self.view !== view else { return }
        self.view = view
        self.attributes = attributes
        height = 0
        view.textStorage.setAttributedString(
            NSAttributedString(string: target.substring(to: min(shown, target.length)), attributes: attributes))
        view.invalidateIntrinsicContentSize()
    }

    /// The view is done with this text (it holds a whole one now, or is going away).
    func detach(_ view: UITextView) {
        if self.view === view { self.view = nil }
    }

    @objc private func tick() {
        if isHeld, CACurrentMediaTime() - heldSince < 4 { return }
        let length = target.length
        let owed = length - shown
        guard owed > 0 else { return stop() }
        var end = shown + min(owed, max(6, owed / 4))
        // On to the end of the word, so words arrive whole, and never through the middle of a letter
        // with its marks or an emoji.
        while end < length, end - shown < 48, !Self.isBreak(target.character(at: end)) { end += 1 }
        if end < length {
            let letter = target.rangeOfComposedCharacterSequence(at: end)
            if letter.location < end { end = NSMaxRange(letter) }
        }
        write(upTo: end)
        if shown >= length { stop() }
    }

    private static func isBreak(_ unit: unichar) -> Bool {
        unit == 0x20 || unit == 0x0A || unit == 0x09 || unit == 0xA0
    }

    private func write(upTo count: Int) {
        let end = min(count, target.length)
        guard end > shown else { return }
        let from = shown
        shown = end
        paints += 1
        guard let view else { return }
        let storage = view.textStorage
        // The storage holds exactly what was written before, so this is an append.
        guard storage.length == from else {
            storage.setAttributedString(NSAttributedString(string: target.substring(to: end), attributes: attributes))
            return measure(view)
        }
        storage.append(NSAttributedString(string: target.substring(with: NSRange(location: from, length: end - from)),
                                          attributes: attributes))
        measure(view)
    }

    /// Whether the text took another line: only then does SwiftUI lay the sheet out again.
    private func measure(_ view: UITextView) {
        let container = view.textContainer
        guard container.size.width > 1 else { return view.invalidateIntrinsicContentSize() }
        view.layoutManager.ensureLayout(for: container)
        let used = ceil(view.layoutManager.usedRect(for: container).maxY)
        guard abs(used - height) > 0.5 else { return }
        height = used
        view.invalidateIntrinsicContentSize()
        lines += 1
    }

    private func stop() {
        link?.invalidate()
        link = nil
        let waiting = waiters
        waiters = []
        for waiter in waiting { waiter.resume() }
    }
}

/// The prose of a summary or an answer: drag-selectable (a summary is read to be quoted from), written
/// into by a `StreamReveal` while the model writes and holding the whole text after. An Arabic one lays
/// out right to left, from the right edge; an English one reads left to right in the Arabic interface too.
private struct SummaryProse: View {
    /// The text being written, or nil once it is whole.
    var reveal: StreamReveal?
    /// The whole text, drawn when nothing is writing it.
    var text = ""
    let isArabic: Bool

    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        StreamedTextView(reveal: reveal, text: text, isArabic: isArabic)
            // The font is fixed when the view is made: a new text size makes a new view.
            .id(sizeCategory)
            .frame(maxWidth: .infinity, alignment: .leading)
            .leftToRightContent(!isArabic)
    }
}

/// `SummaryProse`'s text view, on its own TextKit stack with a column only this view sizes
/// (`OwnedTextContainer`): a non-scrolling `UITextView` otherwise writes its frame and every size it
/// is measured at into its container and typesets the whole text again each time, which is what made
/// a redraw cost what it did. The height SwiftUI gets is the layout's own, read, never re-made.
private struct StreamedTextView: UIViewRepresentable {
    var reveal: StreamReveal?
    var text: String
    let isArabic: Bool

    final class Coordinator {
        /// `NSLayoutManager` does not retain its storage.
        var storage: NSTextStorage?
        weak var reveal: StreamReveal?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    private var attributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = isArabic ? .right : .natural
        paragraph.baseWritingDirection = isArabic ? .rightToLeft : .natural
        paragraph.lineSpacing = 2
        let size = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
        // Arabic keeps the system face; English follows the app's rounded design (as `SelectableProse`).
        let font: UIFont = isArabic ? .systemFont(ofSize: size) : .roundedSystemFont(ofSize: size, weight: .regular)
        return [.font: font, .foregroundColor: UIColor.label, .paragraphStyle: paragraph]
    }

    func makeUIView(context: Context) -> UITextView {
        let storage = NSTextStorage()
        let manager = NSLayoutManager()
        let container = OwnedTextContainer(ownedSize: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        context.coordinator.storage = storage
        let view = UITextView(frame: .zero, textContainer: container)
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.adjustsFontForContentSizeCategory = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if let reveal {
            reveal.attach(view, attributes: attributes)
        } else {
            context.coordinator.reveal?.detach(view)
            if view.textStorage.string != text {
                view.textStorage.setAttributedString(NSAttributedString(string: text, attributes: attributes))
                view.invalidateIntrinsicContentSize()
            }
        }
        context.coordinator.reveal = reveal
    }

    static func dismantleUIView(_ view: UITextView, coordinator: Coordinator) {
        coordinator.reveal?.detach(view)
    }

    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView view: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0,
              let container = view.textContainer as? OwnedTextContainer else { return nil }
        container.ownedSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        view.layoutManager.ensureLayout(for: container)
        return CGSize(width: width, height: ceil(view.layoutManager.usedRect(for: container).maxY))
    }
}

/// Tells `onChange` when the reader starts and stops scrolling by hand (a finger down, or the coast
/// after it). A scroll the sheet makes itself (following an answer) is not one.
private struct ScrollingByHand: ViewModifier {
    let onChange: (Bool) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollPhaseChange { _, phase in
                onChange(phase == .tracking || phase == .interacting || phase == .decelerating)
            }
        } else {
            content
        }
    }
}

#if DEBUG
/// The summary stopwatch (`-summaryProbe`, DEBUG): one `SUMMARYPROBE` line per generation, so "the
/// summary is slow" can be read as numbers. `wait` is the time from the request to the first word (the
/// model loading and reading the source), `total` the whole generation, `tokens` the snapshots the
/// model sent and `paints` the ones the sheet drew. The frame numbers cover the streaming only:
/// `hitch` is ms of late frames per second (under 5 is smooth, over 10 is felt), `worst` the longest
/// frame, `main` the main thread's CPU ms per second.
@MainActor
final class SummaryProbe: NSObject {
    static let enabled = ProcessInfo.processInfo.arguments.contains("-summaryProbe")
    /// "-summaryDrawAsItComes": each snapshot drawn whole the moment it arrives and the text set again
    /// from its first letter, the way the sheet drew before 2026-11-25, to compare the two.
    static let drawsAsItComes = ProcessInfo.processInfo.arguments.contains("-summaryDrawAsItComes")

    private let label: String
    private let sourceCharacters: Int
    private let started = CFAbsoluteTimeGetCurrent()
    private var firstToken: CFAbsoluteTime?
    private var tokens = 0
    private var link: CADisplayLink?
    private var lastStamp = 0.0
    private var hitchSeconds = 0.0
    private var worst = 0.0
    private var worstAt = 0.0
    private var over33 = 0
    private var streamCPU = 0.0
    /// "-summaryScroll": the sheet is scrolled up and down while the summary is written, the way a
    /// reader who starts reading before it ends does. A summary that is smooth standing still and
    /// drops frames under a finger is the case the stopwatch missed at first.
    private static let scrolls = ProcessInfo.processInfo.arguments.contains("-summaryScroll")
    private weak var scroller: UIScrollView?
    private var direction = 1.0
    private var scrolled = 0.0
    /// How long the main thread stayed busy in one pass of its run loop. The phone draws 120 frames a
    /// second, 8.3 ms each, and the simulator 60: a pass of 10 ms is a dropped frame on the phone that
    /// the frame counter here never sees. `over8` and `over16` count the passes past one and two frames.
    private var observer: CFRunLoopObserver?
    private var wokeAt = 0.0
    private var over8 = 0
    private var over16 = 0
    private var longest = 0.0
    private var passes = 0

    init?(label: String, sourceCharacters: Int) {
        guard Self.enabled else { return nil }
        self.label = label
        self.sourceCharacters = sourceCharacters
    }

    func token() {
        tokens += 1
        guard firstToken == nil else { return }
        firstToken = CFAbsoluteTimeGetCurrent()
        NSLog("SUMMARYPROBE first word")
        streamCPU = Self.mainThreadCPU()
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        let observer = CFRunLoopObserverCreateWithHandler(
            nil, CFRunLoopActivity.afterWaiting.rawValue | CFRunLoopActivity.beforeWaiting.rawValue, true, 0
        ) { [weak self] _, activity in
            MainActor.assumeIsolated {
                guard let self else { return }
                let now = CACurrentMediaTime()
                if activity == .afterWaiting { self.wokeAt = now; return }
                guard self.wokeAt > 0 else { return }
                let busy = now - self.wokeAt
                self.wokeAt = 0
                self.passes += 1
                if busy > 1.0 / 120 { self.over8 += 1 }
                if busy > 1.0 / 60 { self.over16 += 1 }
                self.longest = max(self.longest, busy)
            }
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        self.observer = observer
    }

    @objc private func tick(_ link: CADisplayLink) {
        defer { lastStamp = link.timestamp }
        guard lastStamp > 0 else { return }
        let gap = link.timestamp - lastStamp
        let frame = max(link.targetTimestamp - link.timestamp, 1.0 / 120)
        if gap > frame * 1.5 { hitchSeconds += gap - frame }
        if gap > 0.033 { over33 += 1 }
        if gap > worst {
            worst = gap
            worstAt = CFAbsoluteTimeGetCurrent() - (firstToken ?? started)
        }
        guard Self.scrolls else { return }
        if scroller == nil { scroller = Self.sheetScroller() }
        guard let scroller else { return }
        // Past the end of a short summary too (a finger rubber-bands there): 160 points at least.
        let top = -scroller.adjustedContentInset.top
        let bottom = max(top + 160, scroller.contentSize.height - scroller.bounds.height + scroller.adjustedContentInset.bottom)
        var y = scroller.contentOffset.y + direction * 700 * min(gap, 0.25)
        if y >= bottom { y = bottom; direction = -1 }
        if y <= top { y = top; direction = 1 }
        scrolled += abs(y - scroller.contentOffset.y)
        scroller.contentOffset = CGPoint(x: scroller.contentOffset.x, y: y)
    }

    /// The scroll view of the sheet on top (text views and pickers left out).
    private static func sheetScroller() -> UIScrollView? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first else { return nil }
        var top = window.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed { top = presented }
        func scrollers(in root: UIView?) -> [UIScrollView] {
            guard let root, !root.isHidden else { return [] }
            var out: [UIScrollView] = []
            if let scroller = root as? UIScrollView, !(scroller is UITextView), scroller.bounds.height > 200 { out.append(scroller) }
            for sub in root.subviews { out += scrollers(in: sub) }
            return out
        }
        return scrollers(in: top?.view).max { $0.bounds.height < $1.bounds.height }
    }

    func finish(characters: Int, paints: Int, outcome: String) {
        // "-summaryScrollTail": the scroll goes on for eight seconds after the model stops, so a
        // screen recording holds the same scroll with and without the model at work.
        if Self.scrolls, ProcessInfo.processInfo.arguments.contains("-summaryScrollTail") {
            NSLog("SUMMARYPROBE tail begins")
            let link = self.link
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                link?.invalidate()
                NSLog("SUMMARYPROBE tail ends")
            }
        } else {
            link?.invalidate()
        }
        link = nil
        if let observer { CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes) }
        observer = nil
        let now = CFAbsoluteTimeGetCurrent()
        let streamed = max(0.001, now - (firstToken ?? now))
        let cpu = firstToken == nil ? 0 : Self.mainThreadCPU() - streamCPU
        NSLog("SUMMARYPROBE %@ outcome=%@ source=%d wait=%.2fs total=%.2fs tokens=%d paints=%d chars=%d stream=%.2fs hitch=%.1fms/s worst=%.0fms@%.1fs over33=%d main=%.0fms/s scrolled=%.0f passes=%d over8=%d over16=%d longest=%.1fms",
              label, outcome, sourceCharacters, (firstToken ?? now) - started, now - started, tokens, paints, characters,
              streamed, hitchSeconds / streamed * 1000, worst * 1000, worstAt, over33, cpu / streamed * 1000, scrolled,
              passes, over8, over16, longest * 1000)
    }

    /// CPU seconds the calling thread has used (call it on the main thread).
    private static func mainThreadCPU() -> Double {
        var info = thread_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<thread_basic_info>.size / MemoryLayout<integer_t>.size)
        let thread = mach_thread_self()
        defer { mach_port_deallocate(mach_task_self_, thread) }
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                thread_info(thread, thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.user_time.seconds) + Double(info.user_time.microseconds) / 1_000_000
            + Double(info.system_time.seconds) + Double(info.system_time.microseconds) / 1_000_000
    }
}
#endif

/// The shared entry button: a sparkles toolbar icon, matching the Ask card's styling. Callers gate
/// it on `OnDeviceAsk.isAvailable` at render time (the OnDeviceAsk pattern - when Apple Intelligence
/// is off or unsupported the feature simply does not exist in the UI).
struct SummarizeToolbarButton: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    let action: () -> Void

    var body: some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Image(systemName: "sparkles")
                .font(.body.weight(.semibold))
        }
        .tint(settings.accentColor.color)
        .accessibilityLabel("Summarize with AI")
    }
}

#endif
