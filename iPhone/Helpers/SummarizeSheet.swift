import SwiftUI

// "Summarize" - a faithful, on-device AI summary of whatever long text the reader currently has
// open (a tafsir passage, a surah's background prose, or a translation comparison), with follow-up
// chat grounded on that SAME text. Reuses the OnDeviceAsk machinery: the ~3B-parameter Apple
// Intelligence model, its availability gate, and its guardrails (no fabrication, no recreated
// quotations, never a religious ruling).
//
// Entry points pass a title plus the source text; the sheet clips long sources to the model's
// sensible context (OnDeviceAsk.summarizeSourceLimit) and discloses the truncation. Every follow-up
// turn re-grounds on the same source text plus the running transcript.
//
// Availability mirrors OnDeviceAsk: iOS 26+ with Apple Intelligence enabled. Entry points hide the
// button entirely when unavailable (the OnDeviceAsk pattern); the sheet still carries a placeholder
// for the edge where availability flips while it is open.

#if os(iOS) && canImport(FoundationModels)

struct SummarizeSheet: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    /// What the source text IS, shown to the user and to the model (e.g. "Ibn Kathir on Al-Baqarah 2:153").
    let title: String
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

    private var writesArabic: Bool { language == .arabic }

    private struct Turn: Identifiable {
        let id = UUID()
        let question: String
        var answer: String
        var isStreaming: Bool
        var failed = false
    }

    @State private var summary = ""
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

    /// The grounded source: trimmed and clipped once, used for the summary and every follow-up.
    /// Multi-source callers pass text already combined and proportionally clipped
    /// (`OnDeviceAsk.combinedSource`), so it is taken as-is; a gatherer's result likewise.
    private var clippedSource: (text: String, truncated: Bool) {
        if let gathered { return gathered }
        if gatherSource != nil { return ("", false) }   // still gathering
        if multiSource { return (sourceText.trimmingCharacters(in: .whitespacesAndNewlines), sourceTruncated) }
        return OnDeviceAsk.clippedSource(sourceText)
    }

    private var isStreaming: Bool {
        isGathering || isSummarizing || turns.contains { $0.isStreaming }
    }

    var body: some View {
        NavigationView {
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
                        .onChange(of: turns.last?.answer) { _ in
                            withAnimation { proxy.scrollTo("summarize-bottom", anchor: .bottom) }
                        }
                        .safeAreaInset(edge: .bottom) {
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
        .navigationViewStyle(.stack)
        .task {
            // Gather first when the caller fetches sources on demand (the tafsir sheet loading the
            // editions it hasn't yet) - the note card shows a gathering state meanwhile.
            if let gatherSource, gathered == nil {
                guard OnDeviceAsk.isAvailable else { return }
                isGathering = true
                gathered = await gatherSource()
                isGathering = false
            }
            await startSummary()
        }
        .onDisappear {
            streamTask?.cancel()
            streamTask = nil
        }
    }

    // MARK: - Streaming

    private func startSummary() async {
        guard OnDeviceAsk.isAvailable, summary.isEmpty, !isSummarizing else { return }
        guard #available(iOS 26.0, *) else { return }

        // Capture plain values BEFORE the detachable work: the stream builder must never read
        // main-isolated view state from its own task.
        let title = self.title
        let multiSource = self.multiSource
        let language = self.language
        let focus = self.focus
        let source = clippedSource.text
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
            // One leaner retry on a context overflow: a dense text can still tip the 4,096-token
            // window at the character budgets, and two thirds of it summarized beats a failure.
            var attemptSource = source
            var retriedLeaner = false
            while true {
                do {
                    for try await snapshot in OnDeviceAsk.streamSummary(
                        title: title, source: attemptSource, multiSource: multiSource, language: language, focus: focus
                    ) {
                        summary = snapshot
                    }
                } catch {
                    if error is CancellationError { break }
                    #if DEBUG
                    NSLog("SUMMARIZE FAILED: %@", String(describing: error))
                    #endif
                    if !retriedLeaner, summary.isEmpty, OnDeviceAsk.isContextOverflow(error) {
                        retriedLeaner = true
                        attemptSource = String(attemptSource.prefix(attemptSource.count * 2 / 3)) + "…"
                        leanerSource = attemptSource
                        continue
                    }
                    summaryFailed = summary.isEmpty
                    summaryFailureMessage = OnDeviceAsk.failureMessage(for: error)
                }
                break
            }
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
        let source = leanerSource ?? clippedSource.text
        guard !source.isEmpty else { return }
        let transcript = turns
            .filter { !$0.answer.isEmpty && !$0.failed }
            .map { OnDeviceAsk.SummarizeTurn(question: $0.question, answer: $0.answer) }

        turns.append(Turn(question: question, answer: "", isStreaming: true))
        let turnID = turns[turns.count - 1].id

        streamTask?.cancel()
        streamTask = Task { @MainActor in
            do {
                for try await snapshot in OnDeviceAsk.streamFollowUp(
                    title: title, source: source, transcript: transcript, question: question,
                    multiSource: multiSource, language: language, focus: focus
                ) {
                    updateTurn(turnID) { $0.answer = snapshot }
                }
                updateTurn(turnID) { $0.isStreaming = false }
            } catch {
                if !(error is CancellationError) {
                    updateTurn(turnID) {
                        $0.isStreaming = false
                        if $0.answer.isEmpty { $0.failed = true }
                    }
                } else {
                    updateTurn(turnID) { $0.isStreaming = false }
                }
            }
        }
    }

    private func updateTurn(_ id: UUID, _ mutate: (inout Turn) -> Void) {
        guard let index = turns.firstIndex(where: { $0.id == id }) else { return }
        mutate(&turns[index])
    }

    /// The model is told "no markdown", and still headed a single-tafsir summary "### Summary:" with
    /// "**bold**" points (seen 2026-09-05). The sheet renders plain text, so the markers would show
    /// as-is: strip heading hashes, bold / italic asterisks and backticks, keeping the words.
    static func plainProse(_ text: String) -> String {
        var lines: [String] = []
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                line = String(trimmed.drop(while: { $0 == "#" })).trimmingCharacters(in: .whitespaces)
            }
            line = line.replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "`", with: "")
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
            return "Gathering every available text for this summary…"
        }
        if let focus {
            return "Summarizing \(focus) only" + (clippedSource.truncated ? " (shortened to fit the on-device model)" : "")
                + ". The ayah's English translations and an English commentary are given to the model just to help it read the Arabic; questions are answered from the focused text first."
        }
        if multiSource || gatherSource != nil {
            return clippedSource.truncated
                ? "Summarizing ALL the available texts together - longer ones were shortened proportionally to fit the on-device model."
                : "Summarizing ALL the available texts together, and answering questions about any of them."
        }
        let language = writesArabic ? " in Arabic" : ""
        return clippedSource.truncated
            ? "Summarizing the first \(OnDeviceAsk.summarizeSourceLimit.formatted()) characters of this text\(language) - it was shortened to fit the on-device model."
            : "Summarizing the text currently shown\(language), and answering questions about it."
    }

    private var sourceNoteCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "doc.plaintext")
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

            if summaryFailed {
                Text(summaryFailureMessage
                     ?? (gatherSource != nil
                         ? "Couldn't load the texts to summarize. Check your connection, close, and try again."
                         : "The on-device model couldn't summarize this text. Close and try again."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if summary.isEmpty {
                Text(isGathering ? "Gathering the texts…" : "Reading the text…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // A generated summary is read to be quoted from - the drag-selectable text view,
                // not the modifier that only yields a whole-block copy. An Arabic summary lays out
                // right-to-left, from the right edge.
                SelectableProse(text: Self.plainProse(summary), textStyle: .subheadline,
                                isArabic: writesArabic, alignment: writesArabic ? .right : nil)
            }

            Text(multiSource || gatherSource != nil
                 ? "From Apple Intelligence, on device • summarized only from the listed source texts • not a religious ruling"
                 : "From Apple Intelligence, on device • summarized only from the text shown • not a religious ruling")
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
                } else if turn.answer.isEmpty {
                    Text("Thinking…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    SelectableProse(text: Self.plainProse(turn.answer), textStyle: .subheadline,
                                    isArabic: writesArabic, alignment: writesArabic ? .right : nil)
                }
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

            Text("Summarize runs entirely on device and needs Apple Intelligence enabled on a supported device (iOS 26 or later).")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

/// The shared entry button: a sparkles toolbar icon, matching the Ask card's styling. Callers gate
/// it on `OnDeviceAsk.isAvailable` at render time (the OnDeviceAsk pattern - when Apple Intelligence
/// is off or unsupported the feature simply does not exist in the UI).
struct SummarizeToolbarButton: View {
    @ObservedObject var settings = Settings.shared

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
