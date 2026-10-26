import SwiftUI

// The Reading Test's screens: the ladder of tiers, one tier's page, and the session that asks the
// questions. The model (tiers, the word bank, how wrong answers are made, progress) is in
// ArabicReadingTest.swift; the pieces shared with the Tajweed Test (buttons, headers, rows, the score
// card, the match board) are in StudyKit.swift. Phone only: a question wants a two-by-two grid and a
// row of letter tiles.

private extension ReadingTier {
    /// The tile's glyph in the sukoon the reader has chosen, like everything else the tier draws.
    var drawnSpecimen: String {
        ReadingTestText.display(specimen, mushafMarks: Settings.shared.quranicSukoonInLetterPractice || display == .mushaf)
    }

    /// The examples' glosses are English content (a word's meaning, a name's), except on the two tiers
    /// whose gloss the app writes itself in the interface's language.
    var glossIsEnglish: Bool { id != "harakat" && id != "openers" }
}

/// How a session draws its Arabic: which marks, which face, spaced or joined.
private struct ReadingTextStyle {
    let tier: ReadingTier
    /// `Settings.quranicSukoonInLetterPractice`, read once when the session opens.
    let mushafSukoon: Bool

    var plainFace: Bool { tier.display == .unmarked }

    var mushafMarks: Bool { mushafSukoon || tier.display == .mushaf }

    func draw(_ arabic: String, spaced: Bool) -> String {
        let shown = ReadingTestText.display(arabic, mushafMarks: mushafMarks)
        return spaced || tier.display == .spaced ? ReadingTestText.spaced(shown) : shown
    }
}

/// A word missed somewhere, with the tier it belongs to: what a review round is made of.
struct ReadingMissedEntry: Hashable {
    let tier: ReadingTier
    let item: ReadingItem
}

// MARK: - The ladder

struct ReadingTestView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = ReadingTestProgress.shared

    @State private var session: ReadingSessionView.Mode?
    @State private var showKey = false
    @State private var confirmReset = false

    #if DEBUG
    /// "-readingTier <id>": that tier's page, pushed as the ladder appears (once: coming back from it
    /// must not push it again).
    @State private var debugTierOpen = false
    @State private var debugRouteFired = false
    private static func debugArgument(_ name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
    #endif

    private var accent: Color { appearance.accent }

    var body: some View {
        List {
            Group {
                introSection
                letterQuizSection

                ForEach(ReadingStage.allCases) { stage in
                    Section(header: StudyStageHeader(systemImage: stage.systemImage, title: stage.title, arabic: stage.arabic, blurb: stage.blurb)) {
                        ForEach(ReadingTier.tiers(in: stage)) { tier in
                            NavigationLink(destination: LazyDestination { ReadingTierView(tier: tier) }) {
                                StudyTierRow(number: tier.number, specimen: tier.drawnSpecimen, specimenPlain: tier.display == .unmarked,
                                             title: tier.title, arabic: tier.arabic, summary: tier.summary,
                                             record: progress.record(for: tier), isNext: progress.nextTier == tier)
                            }
                        }
                    }
                }

                reviewSection
                moreSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Reading Test")
        .navigationBarTitleDisplayMode(.inline)
        .pushDestination(isPresented: sessionBinding) {
            if let session { ReadingSessionView(mode: session) }
        }
        .sheet(isPresented: $showKey) { ReadingKeySheet().smallMediumSheetPresentation() }
        .confirmationDialog("Reset your Reading Test progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                Settings.shared.hapticFeedback()
                withAnimation(.easeInOut) { progress.reset() }
            }
        } message: {
            Text("Every tier goes back to not passed, and the words kept for review are forgotten. This cannot be undone.")
        }
        #if DEBUG
        .debugPushDestination(isPresented: $debugTierOpen) {
            if let id = Self.debugArgument("-readingTier"), let tier = ReadingTier.tier(id: id) {
                ReadingTierView(tier: tier)
            }
        }
        .onAppear {
            guard !debugRouteFired else { return }
            debugRouteFired = true
            if let seed = Self.debugArgument("-readingTestSeed").flatMap(Int.init) { progress.debugSeed(passed: seed) }
            let arguments = ProcessInfo.processInfo.arguments
            if Self.debugArgument("-readingTier") != nil, !debugTierOpen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugTierOpen = true }
            } else if arguments.contains("-readingPlacement"), session == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { session = .placement }
            } else if arguments.contains("-readingSpeed"), session == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { session = .speed }
            } else if arguments.contains("-readingReview"), session == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { session = .review }
            } else if arguments.contains("-readingKey"), !showKey {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showKey = true }
            }
        }
        #endif
    }

    private var sessionBinding: Binding<Bool> {
        Binding(get: { session != nil }, set: { if !$0 { session = nil } })
    }

    // MARK: Sections

    /// The ladder's `ResourceHero` (2026-10-03): the figures, the progress and the two ways in as its
    /// footer. The footer holds buttons, so the card is a VoiceOver container and each one is reached
    /// on its own.
    private var introSection: some View {
        let total = ReadingTier.all.count
        let started = progress.passedCount > 0 || progress.placement != nil || !progress.records.isEmpty
        return ResourceHeroSection(ResourceHero(
            eyebrow: String(localized: "READING TEST"),
            systemImage: "text.book.closed.fill",
            headline: String(localized: "From one letter to a page with no tashkeel"),
            message: String(localized: "\(total) tiers, in the order a qaa'idah teaches reading before the Quran. Each one tests reading, spelling and listening, never meaning. Eight right out of ten passes a tier, and any tier can be opened at any time."),
            stats: started ? [
                ResourceHeroStat("\(progress.passedCount)", String(localized: "of \(total) passed")),
                ResourceHeroStat("\(progress.masteredCount)", String(localized: "mastered")),
                ResourceHeroStat("\(progress.missed.count)", String(localized: "to review")),
            ] : []
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if progress.passedCount > 0 {
                    ProgressView(value: Double(progress.passedCount), total: Double(total))
                        .tint(accent)
                }

                HStack(spacing: 8) {
                    if let next = progress.nextTier {
                        StudyHeroButton(title: progress.passedCount == 0 && progress.placement == nil ? String(localized: "Start: \(next.title)") : String(localized: "Continue: \(next.title)"),
                                        systemImage: "play.fill", filled: true) {
                            session = .test(next)
                        }
                    }

                    StudyHeroButton(title: String(localized: "Find My Level"), systemImage: "scope", filled: progress.nextTier == nil) {
                        session = .placement
                    }
                }
            }
        })
    }

    /// The Letter Quiz, on this page since 2026-09-22 (Abu: "merge reading test with letter quiz"):
    /// the alphabet's two ways of testing yourself, behind one Explore tile. One row to its chooser
    /// rather than its five modes as rows here: the ladder is this page's subject and should start
    /// within a screen of the top.
    private var letterQuizSection: some View {
        Section {
            NavigationLink(destination: LazyDestination { LetterQuizView() }) {
                ArabicTopicLinkLabel(
                    specimen: "\u{0628}",
                    title: String(localized: "Letter Quiz"),
                    caption: String(localized: "Name a letter, find it, read its joined form, place its family, or pick the one you hear. Ten questions a round.")
                )
            }
        } footer: {
            Text("One letter at a time. The ladder below asks you to read them joined into words.")
        }
    }

    /// Rounds that cut across the ladder: a mixed review, the clock, and the words that got away.
    private var reviewSection: some View {
        Section {
            StudyActionRow(title: String(localized: "Mixed Review"), systemImage: "shuffle",
                           caption: progress.passedCount > 0 ? String(localized: "Fifteen questions from the tiers you have passed") : String(localized: "Fifteen questions from every tier")) {
                session = .review
            }

            StudyActionRow(title: String(localized: "Speed Round"), systemImage: "timer",
                           caption: String(localized: "\(StudySpeed.seconds) seconds of reading and spelling. How many can you get?"),
                           detail: progress.speedBest > 0 ? String(localized: "best \(progress.speedBest)") : nil) {
                session = .speed
            }

            if !progress.missed.isEmpty {
                StudyActionRow(title: String(localized: "Practice Missed Words"), systemImage: "arrow.uturn.backward.circle",
                               caption: String(localized: "The words you missed in scored tests, until you get them right"),
                               detail: "\(progress.missed.count)") {
                    session = .missed(nil)
                }
            }
        } header: {
            StudySectionHeader(String(localized: "REVIEW"), systemImage: "arrow.triangle.2.circlepath")
        } footer: {
            if !progress.missed.isEmpty {
                Text("A word leaves the review list once you read it right in a review or a scored test.")
            }
        }
    }

    private var moreSection: some View {
        Section {
            StudyActionRow(title: String(localized: "Reading Key"), systemImage: "character.book.closed",
                           caption: String(localized: "How the readings are spelled: H, S, aa, and the rest"), trailingSymbol: "chevron.forward") {
                showKey = true
            }

            if !progress.records.isEmpty || progress.placement != nil || !progress.missed.isEmpty || progress.speedBest > 0 {
                StudyActionRow(title: String(localized: "Reset Progress"), systemImage: "arrow.counterclockwise",
                               caption: String(localized: "Start the ladder again from nothing"), tint: .red, trailingSymbol: nil) {
                    confirmReset = true
                }
            }
        } header: {
            StudySectionHeader(String(localized: "MORE"), systemImage: "ellipsis.circle")
        } footer: {
            Text("Every Quranic word here is cut from the app's own Hafs text, and its reading is checked against the word-by-word transliteration before it is allowed in. The unmarked words are spelled the way the hadith collections print them.")
        }
    }
}

// MARK: - One tier

struct ReadingTierView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = ReadingTestProgress.shared
    @ObservedObject private var speech = ArabicSpeech.shared

    let tier: ReadingTier

    @State private var session: ReadingSessionView.Mode?
    @State private var examplesSpaced = false
    #if DEBUG
    @State private var debugStartFired = false
    #endif

    private var accent: Color { appearance.accent }

    private var style: ReadingTextStyle {
        ReadingTextStyle(tier: tier, mushafSukoon: Settings.shared.quranicSukoonInLetterPractice)
    }

    var body: some View {
        let record = progress.record(for: tier)

        List {
            Group {
                heroSection(record)
                teachesSection
                catchesSection
                examplesSection
                testSection(record)
                practiceSection(record)
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(tier.title)
        .navigationBarTitleDisplayMode(.inline)
        .pushDestination(isPresented: Binding(get: { session != nil }, set: { if !$0 { session = nil } })) {
            if let session { ReadingSessionView(mode: session) }
        }
        .onDisappear { ArabicSpeech.shared.stop() }
        #if DEBUG
        // "-readingStart test|read|spell|listen|build|stop|gap|match|odd|aloud...": open the session straight away.
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            guard !debugStartFired, session == nil,
                  let index = arguments.firstIndex(of: "-readingStart"), arguments.indices.contains(index + 1) else { return }
            debugStartFired = true
            let value = arguments[index + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                session = ReadingSkill(rawValue: value).map { .practice(tier, $0) } ?? .test(tier)
            }
        }
        #endif
    }

    /// The tier's `ResourceHero` (2026-10-03): its place on the ladder as the eyebrow, its name in both
    /// languages, then the specimen set large and where the learner stands, as the footer.
    private func heroSection(_ record: StudyRecord) -> some View {
        ResourceHeroSection(ResourceHero(
            eyebrow: String(localized: "Tier \(tier.number) of \(ReadingTier.all.count) \u{00B7} \(tier.stage.title)").uppercased(),
            systemImage: "text.book.closed.fill",
            headline: tier.title,
            arabic: tier.arabic,
            message: ""
        ) {
            VStack(spacing: 8) {
                StudyArabicText(text: tier.drawnSpecimen, base: 44, style: .largeTitle, plain: tier.display == .unmarked)
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: .infinity, minHeight: 64)

                if record.attempts > 0 {
                    StudyIconText(record.mastered ? String(localized: "Mastered: every answer right, no hints")
                          : record.passed ? String(localized: "Passed \u{00B7} best \(record.best)%")
                          : String(localized: "Best so far \(record.best)% \u{00B7} \(ReadingTestProgress.passMark)% passes"),
                          systemImage: record.mastered ? "checkmark.seal.fill" : record.passed ? "checkmark.circle.fill" : "chart.bar")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(record.passed ? accent : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
        })
    }

    /// The first paragraph is the tier's article lead; the rest stay prose under it.
    private var teachesSection: some View {
        Section {
            if let lead = tier.teaches.first {
                ArticleLead(lead, eyebrow: String(localized: "IN SHORT"))
            }

            if tier.teaches.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(tier.teaches.dropFirst()), id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            StudySectionHeader(String(localized: "WHAT THIS TIER TESTS"), systemImage: "text.book.closed")
        }
    }

    /// The slips the wrong answers are built from: a learner can see what the test is listening for.
    @ViewBuilder
    private var catchesSection: some View {
        let catches = tier.catches
        if !catches.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(catches, id: \.self) { slip in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.caption.weight(.bold))
                                .foregroundColor(accent)
                            Text(slip)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                StudySectionHeader(String(localized: "WHAT IT CATCHES"), systemImage: "ear.badge.waveform")
            } footer: {
                Text("Every wrong answer is one of these slips made on the right word, so a miss tells you which habit to watch.")
            }
        }
    }

    private var examplesSection: some View {
        Section {
            ForEach(ReadingTestBank.examples(for: tier), id: \.self) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.reading)
                            .font(.body.weight(.semibold))
                            .leftToRightContent()

                        if let caption = item.gloss, tier.id != "letters" {
                            Text(caption)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .leftToRightContent(tier.glossIsEnglish)
                        }
                    }

                    Spacer(minLength: 8)

                    StudyArabicText(text: style.draw(item.arabic, spaced: examplesSpaced), base: 26, style: .title2, plain: style.plainFace)
                        .foregroundColor(accent)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.5)
                        // Its lines right-aligned, as Arabic is, in either interface.
                        .environment(\.layoutDirection, .leftToRight)

                    if speech.isAvailable {
                        PracticeListenButton(text: item.spoken)
                    }
                }
                .padding(.vertical, 2)
            }

            if tier.hint != .none, tier.display != .spaced {
                Toggle("Letter by Letter", isOn: $examplesSpaced.animation(.easeInOut))
                    .font(.subheadline)
                    .tint(accent)
            }
        } header: {
            StudySectionHeader(String(localized: "EXAMPLES"), systemImage: "text.quote")
        } footer: {
            if tier.hint != .none, tier.display != .spaced {
                Text("That switch is the hint you get inside a test: Beginner Mode, every letter apart.")
            }
        }
    }

    private func testSection(_ record: StudyRecord) -> some View {
        Section {
            StudyResultButton(title: record.attempts == 0 ? String(localized: "Start the Test") : String(localized: "Take the Test Again"),
                              systemImage: "play.fill", prominent: true) {
                session = .test(tier)
            }
        } header: {
            StudySectionHeader(String(localized: "THE TEST"), systemImage: "checkmark.seal")
        } footer: {
            Text("Ten questions, the skills below mixed together. \(ReadingTestProgress.passMark)% passes. A hint never costs you the answer, but a tier is only mastered with every answer right and no hints.")
        }
    }

    private func practiceSection(_ record: StudyRecord) -> some View {
        let skills = tier.skills.filter { speech.isAvailable || !$0.needsVoice } + (tier.id == "forms" ? [] : [.aloud])
        return Section {
            ForEach(skills) { skill in
                StudyActionRow(title: skill.title, systemImage: skill.systemImage, caption: skill.caption,
                               detail: record.skillBest[skill.rawValue].map { "\($0)%" }) {
                    session = .practice(tier, skill)
                }
            }
        } header: {
            StudySectionHeader(String(localized: "PRACTICE ONE SKILL"), systemImage: "figure.walk")
        } footer: {
            Text("Practice rounds are not scored against the tier. The figure beside a skill is your best practice round of it.")
        }
    }
}

// MARK: - The session

struct ReadingSessionView: View {
    enum Mode: Equatable {
        case test(ReadingTier)
        case practice(ReadingTier, ReadingSkill)
        case placement
        case review
        /// Sixty seconds of quick questions.
        case speed
        /// The words missed before: these ones, or the whole review bank when nil.
        case missed([ReadingMissedEntry]?)
    }

    @Environment(\.appearance) private var appearance
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var speech = ArabicSpeech.shared
    @ObservedObject private var progress = ReadingTestProgress.shared

    @State private var mode: Mode
    @State private var questions: [ReadingQuestion] = []
    @State private var index = 0
    /// Multiple choice: the choice tapped. Build and match: set once the answer is checked.
    @State private var chosen: Int?
    @State private var placed: [ReadingTile] = []
    @State private var buildRight: Bool?
    /// Match Pairs: how many wrong pairs it took, once every pair is made.
    @State private var matchWrong: Int?
    /// Read aloud: the reading has been shown.
    @State private var revealed = false
    /// 0 none, 1 letter by letter, 2 the marks shown (the unmarked tiers).
    @State private var hintLevel = 0
    @State private var hintedThisQuestion = false
    @State private var right = 0
    @State private var hints = 0
    @State private var streak = 0
    @State private var missed: [ReadingMissedEntry] = []
    @State private var answeredRight: [ReadingMissedEntry] = []
    @State private var finished = false
    /// Find My Level: where on the ladder it is asking, and how the current pair is going.
    @State private var placementIndex = 0
    @State private var placementResult: ReadingTier?
    @State private var placementCleared = false
    /// Speed Round: the clock.
    @State private var secondsLeft = StudySpeed.seconds
    @State private var clock: Task<Void, Never>?
    private let mushafSukoon = Settings.shared.quranicSukoonInLetterPractice

    init(mode: Mode) {
        _mode = State(initialValue: mode)
    }

    private var accent: Color { appearance.accent }

    private var isPlacement: Bool { mode == .placement }

    private var isSpeed: Bool { mode == .speed }

    private var title: String {
        switch mode {
        case .test(let tier): return tier.title
        case .practice(_, let skill): return skill.title
        case .placement: return String(localized: "Find My Level")
        case .review: return String(localized: "Mixed Review")
        case .speed: return String(localized: "Speed Round")
        case .missed: return String(localized: "Practice Missed Words")
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Group {
                    if finished {
                        resultsSections
                    } else if questions.indices.contains(index) {
                        questionSections(questions[index])
                    } else {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            // An answer adds its working and the Next button below the choices, often past the
            // bottom of the screen: bring Next into view, and come back to the top for the next word.
            .onChange(of: scrollCue) { cue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut) { proxy.scrollTo(cue.hasSuffix("answered") ? Self.nextID : Self.promptID, anchor: cue.hasSuffix("answered") ? .bottom : .top) }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if questions.isEmpty, !finished { start() } }
        .onDisappear {
            ArabicSpeech.shared.stop()
            clock?.cancel()
        }
    }

    private static let promptID = "readingPrompt"
    private static let nextID = "readingNext"

    /// Changes when a question is answered and again when the next one arrives.
    private var scrollCue: String {
        let answered = questions.indices.contains(index) && isAnswered(questions[index])
        return "\(index)-\(finished ? "finished" : answered ? "answered" : "asking")"
    }

    // MARK: Asking

    @ViewBuilder
    private func questionSections(_ question: ReadingQuestion) -> some View {
        let style = ReadingTextStyle(tier: question.tier, mushafSukoon: mushafSukoon)
        let answered = isAnswered(question)

        Section {
            VStack(spacing: 10) {
                promptView(question, style: style)

                Text(question.ask)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if !answered, !isPlacement, !isSpeed {
                    hintRow(question)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .id(Self.promptID)
        } header: {
            StudyQuestionHeader(
                title: isPlacement ? String(localized: "TIER \(question.tier.number): \(question.tier.title.uppercased())")
                    : isSpeed ? String(localized: "QUESTION \(index + 1)")
                    : String(localized: "QUESTION \(index + 1) OF \(questions.count)"),
                streak: isPlacement ? 0 : streak,
                secondsLeft: isSpeed ? secondsLeft : nil)
        }

        Section {
            switch question.skill {
            case .build: buildArea(question, style: style)
            case .match: matchArea(question, style: style)
            case .aloud: aloudArea(question)
            default: choiceArea(question, style: style)
            }

            if answered {
                feedback(question, style: style)

                if !isSpeed {
                    StudyAdvanceButton(title: isLast ? String(localized: "See Results") : String(localized: "Next")) {
                        advance()
                    }
                    .id(Self.nextID)
                }
            }
        }
    }

    private var isLast: Bool { !isPlacement && !isSpeed && index + 1 == questions.count }

    private func isAnswered(_ question: ReadingQuestion) -> Bool {
        switch question.skill {
        case .build: return buildRight != nil
        case .match: return matchWrong != nil
        default: return chosen != nil
        }
    }

    @ViewBuilder
    private func promptView(_ question: ReadingQuestion, style: ReadingTextStyle) -> some View {
        if question.skill == .listen {
            StudySpeakerButton(text: question.item.spoken, size: 96)
        } else if question.skill == .gap {
            VStack(spacing: 8) {
                // The word with its gap, then the reading: the gap is what the question is about.
                ReadingGapWord(question: question, style: style, size: promptSize(question))
                    .foregroundColor(accent)
                    .frame(maxWidth: .infinity, minHeight: 84)

                Text(question.prompt)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .leftToRightContent()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)

                if speech.isAvailable {
                    StudySpeakerButton(text: question.item.spoken, size: 40)
                }
            }
        } else if question.skill == .match || question.skill == .odd {
            // Nothing above the board or the four words: the question is the choices.
            EmptyView()
        } else if question.promptIsArabic {
            VStack(spacing: 6) {
                StudyArabicText(text: style.draw(question.prompt, spaced: hintLevel >= 1), base: promptSize(question), style: .largeTitle, plain: style.plainFace)
                    .foregroundColor(accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(question.prompt.contains(" ") ? 4 : 1)
                    .minimumScaleFactor(0.3)
                    .frame(maxWidth: .infinity, minHeight: 96)

                // The unmarked tiers' second hint: the same word with its marks on.
                if hintLevel >= 2, let marked = question.item.marked {
                    StudyArabicText(text: ReadingTestText.display(marked, mushafMarks: mushafSukoon), base: 30, style: .title)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
            }
        } else {
            VStack(spacing: 8) {
                Text(question.prompt)
                    .font(.system(size: question.prompt.count > 22 ? 22 : 34, weight: .bold, design: .rounded))
                    // A reading is Latin content: its apostrophes and hyphens stay where they are written.
                    .leftToRightContent()
                    .foregroundColor(accent)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, minHeight: 72)

                // A reading is easier to hold in the ear than in the eye, so it can be heard as well.
                if speech.isAvailable {
                    StudySpeakerButton(text: question.item.spoken, size: 44)
                }
            }
        }
    }

    private func promptSize(_ question: ReadingQuestion) -> CGFloat {
        let text = question.skill == .gap ? question.item.arabic : question.prompt
        if text.contains(" ") { return text.count > 40 ? 30 : 36 }
        return text.count > 14 ? 44 : 60
    }

    // MARK: Hints

    @ViewBuilder
    private func hintRow(_ question: ReadingQuestion) -> some View {
        if question.skill == .build {
            StudyHintChip(title: String(localized: "Place the next one for me"), systemImage: "lightbulb") {
                placeNext(question)
            }
        } else if question.allowsHint, question.tier.display != .spaced {
            HStack(spacing: 8) {
                StudyHintChip(title: hintLevel >= 1 ? String(localized: "Joined Again") : String(localized: "Hint: Letter by Letter"), systemImage: hintLevel >= 1 ? "arrow.uturn.backward" : "lightbulb") {
                    if hintLevel >= 1 { hintLevel = 0 } else { useHint(level: 1) }
                }

                if case .letterByLetterThenMarks = question.tier.hint, question.item.marked != nil, question.promptIsArabic, hintLevel == 1 {
                    StudyHintChip(title: String(localized: "Show the Tashkeel"), systemImage: "lightbulb.fill") {
                        useHint(level: 2)
                    }
                }
            }
        }
    }

    private func useHint(level: Int) {
        hintLevel = level
        if !hintedThisQuestion {
            hintedThisQuestion = true
            hints += 1
        }
    }

    // MARK: Multiple choice

    @ViewBuilder
    private func choiceArea(_ question: ReadingQuestion, style: ReadingTextStyle) -> some View {
        // Two by two while every choice fits a half-width button; one column for an ayah or a long word.
        let long = question.choices.contains { $0.text.count > ($0.isArabic ? 12 : 15) }
        // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height on
        // each self-sizing pass, which iOS 26 traps on.
        SummaryTileGrid(columns: long ? 1 : 2) {
            ForEach(question.choices) { choice in
                choiceButton(choice, in: question, style: style, long: long)
            }
        }
        .padding(.vertical, 4)
    }

    private func choiceButton(_ choice: ReadingChoice, in question: ReadingQuestion, style: ReadingTextStyle, long: Bool) -> some View {
        let state = StudyChoiceState(answered: chosen != nil, isAnswer: choice.id == question.answer, picked: chosen == choice.id)
        return StudyChoiceButton(state: state, long: long) {
            choose(choice.id, in: question)
        } label: {
            if choice.isArabic {
                // The joined-shapes tier's spelled-out choices are already letter by letter; a gap's
                // choices are single letters; the odd one out's words are never spaced.
                let spaced = hintLevel >= 1 && question.skill != .takeApart && question.skill != .gap && question.skill != .odd
                StudyArabicText(text: question.skill == .takeApart ? choice.text : style.draw(choice.text, spaced: spaced),
                                base: long ? 26 : 32, style: .title, plain: style.plainFace)
                    .foregroundColor(accent)
            } else {
                Text(choice.text)
                    .font(long ? .body.weight(.semibold) : .title3.weight(.semibold))
                    .leftToRightContent()
                    .foregroundColor(.primary)
            }
        }
        .accessibilityLabel(choice.text)
    }

    // MARK: Build

    @ViewBuilder
    private func buildArea(_ question: ReadingQuestion, style: ReadingTextStyle) -> some View {
        let separator = question.tilesAreWords ? " " : ""
        let built = placed.map(\.text).joined(separator: separator)
        let checked = buildRight != nil

        VStack(spacing: 12) {
            // What has been built so far, joined the way it will be read.
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(buildRight == true ? Color.green : buildRight == false ? Color.red : accent.opacity(0.35),
                            style: StrokeStyle(lineWidth: checked ? 2 : 1.5, dash: checked ? [] : [6, 4]))

                if built.isEmpty {
                    Text(question.tilesAreWords ? String(localized: "Tap the words below") : String(localized: "Tap the letters below"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    StudyArabicText(text: ReadingTestText.display(built, mushafMarks: style.mushafMarks),
                                    base: question.tilesAreWords ? 28 : 40, style: .title, plain: style.plainFace)
                        .foregroundColor(accent)
                        .multilineTextAlignment(.center)
                        .lineLimit(question.tilesAreWords ? 3 : 1)
                        .minimumScaleFactor(0.35)
                        .padding(.horizontal, 10)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76)

            FlowLayoutView(spacing: 8) {
                ForEach(question.tiles) { tile in
                    let used = placed.contains(tile)
                    Button {
                        guard !checked, !used else { return }
                        Settings.shared.hapticFeedback()
                        withAnimation(.easeInOut(duration: 0.15)) { placed.append(tile) }
                    } label: {
                        StudyArabicText(text: ReadingTestText.display(tile.text, mushafMarks: style.mushafMarks),
                                        base: question.tilesAreWords ? 22 : 28, style: .title2, plain: style.plainFace)
                            .foregroundColor(accent)
                            .lineLimit(1)
                            .padding(.horizontal, question.tilesAreWords ? 12 : 10)
                            .frame(minWidth: 46, minHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(accent.opacity(0.10))
                            )
                            .opacity(used ? 0.25 : 1)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tile.text)
                }
            }
            .frame(maxWidth: .infinity)

            if !checked {
                HStack(spacing: 8) {
                    StudyControlButton(title: String(localized: "Undo"), systemImage: "delete.left", enabled: !placed.isEmpty) {
                        // `enabled` is from the last render: a second fast tap can find nothing left.
                        if !placed.isEmpty { placed.removeLast() }
                    }

                    StudyControlButton(title: String(localized: "Clear"), systemImage: "xmark", enabled: !placed.isEmpty) {
                        placed.removeAll()
                    }

                    StudyControlButton(title: String(localized: "Check"), systemImage: "checkmark", enabled: !placed.isEmpty, filled: true) {
                        check(question)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func placeNext(_ question: ReadingQuestion) {
        // Anything wrong so far is cleared first, so the helped letter lands in the right place.
        var kept: [ReadingTile] = []
        for (position, tile) in placed.enumerated() {
            guard position < question.target.count, tile.text == question.target[position] else { break }
            kept.append(tile)
        }
        placed = kept
        guard placed.count < question.target.count,
              let next = question.tiles.first(where: { $0.text == question.target[placed.count] && !placed.contains($0) }) else { return }
        placed.append(next)
        if !hintedThisQuestion {
            hintedThisQuestion = true
            hints += 1
        }
    }

    private func check(_ question: ReadingQuestion) {
        let isRight = placed.map(\.text) == question.target
        buildRight = isRight
        chosen = 0
        tally(isRight, question)
    }

    // MARK: Match pairs

    private func matchArea(_ question: ReadingQuestion, style: ReadingTextStyle) -> some View {
        let pairs = question.pairs.map { StudyMatchBoard<AnyView, AnyView>.Pair(id: $0.id, leftSlot: $0.leftSlot, rightSlot: $0.rightSlot) }
        return StudyMatchBoard(pairs: pairs, finished: matchWrong != nil, onFinish: { wrong in
            matchWrong = wrong
            chosen = 0
            tally(wrong == 0, question)
        }, left: { slot in
            AnyView(
                Group {
                    if let pair = question.pairs.first(where: { $0.leftSlot == slot }) {
                        StudyArabicText(text: style.draw(pair.item.arabic, spaced: false), base: 28, style: .title2, plain: style.plainFace)
                            .foregroundColor(accent)
                    }
                }
            )
        }, right: { slot in
            AnyView(
                Group {
                    if let pair = question.pairs.first(where: { $0.rightSlot == slot }) {
                        Text(pair.item.reading)
                            .font(.body.weight(.semibold))
                            .leftToRightContent()
                            .foregroundColor(.primary)
                    }
                }
            )
        })
    }

    // MARK: Read aloud

    @ViewBuilder
    private func aloudArea(_ question: ReadingQuestion) -> some View {
        VStack(spacing: 10) {
            if revealed {
                Text(question.tier.id == "waqf" ? question.item.stopped : question.item.reading)
                    .font(.title2.weight(.bold))
                    .leftToRightContent()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if speech.isAvailable {
                    StudySpeakerButton(text: question.item.spoken, size: 44)
                }

                if chosen == nil {
                    Text("Did you read it that way?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        StudyControlButton(title: String(localized: "Not Yet"), systemImage: "xmark") {
                            chosen = 1
                            tally(false, question)
                        }

                        StudyControlButton(title: String(localized: "I Read It Right"), systemImage: "checkmark", filled: true) {
                            chosen = 0
                            tally(true, question)
                        }
                    }
                }
            } else {
                StudyControlButton(title: String(localized: "Show the Reading"), systemImage: "eye", filled: true) {
                    revealed = true
                    if speech.isAvailable { speech.speak(question.item.spoken) }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Feedback

    private func wasRight(_ question: ReadingQuestion) -> Bool {
        switch question.skill {
        case .build: return buildRight == true
        case .match: return matchWrong == 0
        case .aloud: return chosen == 0
        default: return chosen == question.answer
        }
    }

    @ViewBuilder
    private func feedback(_ question: ReadingQuestion, style: ReadingTextStyle) -> some View {
        let wasRight = wasRight(question)
        let item = question.item

        VStack(alignment: .leading, spacing: 8) {
            if question.skill == .match, let matchWrong, matchWrong > 0 {
                StudyIconText(matchWrong == 1 ? String(localized: "One wrong pair on the way") : String(localized: "\(matchWrong) wrong pairs on the way"),
                              systemImage: "xmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.red)
            } else {
                StudyVerdictLine(wasRight: wasRight, hinted: hintedThisQuestion)
            }

            if question.skill == .match {
                // Every pair, settled: the word and its reading side by side.
                ForEach(question.pairs) { pair in
                    pairRow(pair.item, style: style)
                }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(question.skill == .stop ? item.stopped : item.reading)
                            .font(.body.weight(.semibold))
                            .leftToRightContent()

                        if question.skill == .stop {
                            Text("Read on, it is \(item.reading).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    if question.tier.id != "forms" {
                        // Joined, even on the letter-by-letter tier: this is where its words close up.
                        StudyArabicText(text: ReadingTestText.display(item.marked ?? item.arabic, mushafMarks: style.mushafMarks),
                                        base: 26, style: .title2, plain: style.plainFace && item.marked == nil)
                            .foregroundColor(accent)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .minimumScaleFactor(0.4)
                            .environment(\.layoutDirection, .leftToRight)
                    }

                    if speech.isAvailable, question.tier.id != "forms" {
                        PracticeListenButton(text: item.spoken)
                    }
                }

                if !item.sounded.isEmpty {
                    soundedOut(item, style: style)
                }

                if question.skill == .odd, let feature = question.tier.feature {
                    Text("The other three all have \(feature): \(question.others.map(\.reading).joined(separator: ", ")).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let note = explanation(question) {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        // A name's meaning and a phrase's are English content, shown as they are.
                        .leftToRightContent(["names", "everyday"].contains(question.tier.id))
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func pairRow(_ item: ReadingItem, style: ReadingTextStyle) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(item.reading)
                .font(.subheadline.weight(.semibold))
                .leftToRightContent()

            Spacer(minLength: 8)

            StudyArabicText(text: ReadingTestText.display(item.marked ?? item.arabic, mushafMarks: style.mushafMarks),
                            base: 22, style: .title3, plain: style.plainFace && item.marked == nil)
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if speech.isAvailable {
                PracticeListenButton(text: item.spoken)
            }
        }
    }

    /// The word a syllable at a time, each group of letters over how it is read: the answer's own
    /// working, shown whether the answer was right or not.
    private func soundedOut(_ item: ReadingItem, style: ReadingTextStyle) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 6) {
                ForEach(Array(item.sounded.enumerated()), id: \.offset) { _, part in
                    VStack(spacing: 2) {
                        StudyArabicText(text: ReadingTestText.display(part.arabic, mushafMarks: style.mushafMarks),
                                        base: 22, style: .title3)
                            .foregroundColor(accent)
                            .lineLimit(1)

                        Text(part.reading)
                            .font(.caption2.weight(.semibold))
                            .leftToRightContent()
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accent.opacity(0.08))
                    )
                }
            }
            // Read from the right, as the word is.
            .environment(\.layoutDirection, .rightToLeft)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Sounded out: \(item.sounded.map(\.reading).joined(separator: ", "))"))
    }

    private func explanation(_ question: ReadingQuestion) -> String? {
        let item = question.item
        switch question.tier.id {
        case "letters", "harakat", "openers", "names", "everyday":
            return item.gloss
        case "forms":
            return String(localized: "\(item.arabic) is \(item.reading), joined.")
        case "ayat":
            guard let reference = item.reference, let gloss = item.gloss else { return nil }
            return String(localized: "\(reference.localizedDigits): \u{201C}\(gloss)\u{201D} (Saheeh International)")
        default:
            guard let reference = item.reference, let gloss = item.gloss, !gloss.isEmpty else { return nil }
            return String(localized: "In the Quran (\(reference.localizedDigits)) it means \u{201C}\(gloss)\u{201D}.")
        }
    }

    // MARK: Running

    private func start() {
        var factory = ReadingQuestionFactory()
        factory.voiceAvailable = speech.isAvailable
        clock?.cancel()
        let passed = ReadingTier.all.filter { progress.record(for: $0).passed }
        switch mode {
        case .test(let tier): questions = factory.round(for: tier)
        case .practice(let tier, let skill): questions = factory.round(for: tier, only: skill)
        case .review:
            questions = factory.review(of: passed.isEmpty ? ReadingTier.all : passed)
        case .speed:
            questions = factory.speedRound(from: passed.count >= 3 ? passed : ReadingTier.all)
            secondsLeft = StudySpeed.seconds
        case .missed(let entries):
            let pool = entries ?? progress.missedItems.map { ReadingMissedEntry(tier: $0.tier, item: $0.item) }
            questions = factory.review(ofMissed: pool.map { ($0.tier, $0.item) })
        case .placement:
            placementIndex = 0
            questions = factory.placementPair(for: ReadingTier.all[0])
        }
        index = 0
        right = 0
        hints = 0
        streak = 0
        missed = []
        answeredRight = []
        finished = questions.isEmpty
        placementResult = nil
        placementCleared = false
        resetQuestionState()
        speakCurrent()
        if isSpeed, !finished { startClock() }
    }

    /// The Speed Round's clock: one tick a second, and the round ends when it runs out.
    private func startClock() {
        clock = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, !finished else { return }
                secondsLeft -= 1
                if secondsLeft <= 0 {
                    finish()
                    return
                }
            }
        }
    }

    private func resetQuestionState() {
        chosen = nil
        placed = []
        buildRight = nil
        matchWrong = nil
        revealed = false
        hintLevel = 0
        hintedThisQuestion = false
    }

    private func choose(_ id: Int, in question: ReadingQuestion) {
        chosen = id
        tally(id == question.answer, question)
    }

    private func tally(_ wasRight: Bool, _ question: ReadingQuestion) {
        let entry = ReadingMissedEntry(tier: question.tier, item: question.item)
        if wasRight {
            right += 1
            streak += 1
            if !answeredRight.contains(entry) { answeredRight.append(entry) }
        } else {
            streak = 0
            if !missed.contains(entry) { missed.append(entry) }
        }
        // A Speed Round moves on by itself once the answer has shown.
        if isSpeed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                guard !finished, questions.indices.contains(index), isAnswered(questions[index]) else { return }
                advance()
            }
        }
    }

    private func advance() {
        ArabicSpeech.shared.stop()
        if isPlacement {
            advancePlacement()
            return
        }
        if index + 1 >= questions.count {
            finish()
        } else {
            resetQuestionState()
            index += 1
            speakCurrent()
        }
    }

    /// Two questions a tier: both right moves up the ladder, a miss stops it there.
    private func advancePlacement() {
        let wasRight = questions.indices.contains(index) && wasRight(questions[index])
        guard wasRight else {
            placementResult = ReadingTier.all[placementIndex]
            finish()
            return
        }
        if index + 1 < questions.count {
            resetQuestionState()
            index += 1
            speakCurrent()
            return
        }
        placementIndex += 1
        guard placementIndex < ReadingTier.all.count else {
            placementCleared = true
            finish()
            return
        }
        var factory = ReadingQuestionFactory()
        factory.voiceAvailable = speech.isAvailable
        questions = factory.placementPair(for: ReadingTier.all[placementIndex])
        index = 0
        resetQuestionState()
        if questions.isEmpty { placementCleared = true; finish() }
    }

    private func finish() {
        clock?.cancel()
        switch mode {
        case .test(let tier):
            progress.finish(tier, right: right, of: questions.count, hints: hints,
                            missed: missed.map(\.item), answeredRight: answeredRight.map(\.item))
        case .practice(let tier, let skill):
            progress.recordPractice(tier, skill: skill, right: right, of: questions.count)
        case .placement:
            if let placementResult { progress.setPlacement(placementResult) }
        case .speed:
            progress.recordSpeed(right: right)
        case .review, .missed:
            progress.finishReview(missedIDs: missed.map { ($0.item.arabic, $0.tier.id) },
                                  rightIDs: answeredRight.map { ($0.item.arabic, $0.tier.id) })
        }
        withAnimation(.easeInOut) { finished = true }
    }

    /// A listening question says its word as it arrives.
    private func speakCurrent() {
        guard questions.indices.contains(index), questions[index].skill == .listen else { return }
        let text = questions[index].item.spoken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { speech.speak(text) }
    }

    // MARK: Results

    @ViewBuilder
    private var resultsSections: some View {
        if isPlacement {
            placementResults
        } else {
            scoreSection
        }

        if !missed.isEmpty {
            Section {
                ForEach(missed, id: \.self) { entry in
                    let item = entry.item
                    HStack(spacing: 12) {
                        Text(item.reading)
                            .font(.body.weight(.semibold))
                            .leftToRightContent()
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        StudyArabicText(text: ReadingTestText.display(item.marked ?? item.arabic, mushafMarks: mushafSukoon),
                                        base: 24, style: .title2, plain: item.marked == nil && !item.arabic.unicodeScalars.contains(where: ReadingTestText.isMark))
                            .foregroundColor(accent)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .minimumScaleFactor(0.4)
                            .environment(\.layoutDirection, .leftToRight)

                        if speech.isAvailable {
                            PracticeListenButton(text: item.spoken)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                StudySectionHeader(String(localized: "LOOK AT THESE AGAIN"), systemImage: "eye")
            } footer: {
                if case .test = mode {
                    Text("These words are kept under Practice Missed Words on the ladder until you read them right.")
                }
            }
        }
    }

    private var scoreSection: some View {
        let total = isSpeed ? max(index + (questions.indices.contains(index) && isAnswered(questions[index]) ? 1 : 0), right) : questions.count
        let percent = total == 0 ? 0 : Int((Double(right) / Double(total) * 100).rounded())
        let passed = percent >= ReadingTestProgress.passMark
        let tier: ReadingTier? = { if case .test(let tier) = mode { return tier } else { return nil } }()
        let outcome: StudyOutcome? = tier == nil ? nil : (right == total && hints == 0) ? .mastered : passed ? .passed : .failed

        return Section {
            StudyScoreCard(right: right, total: total, outcome: outcome,
                           message: isSpeed ? speedMessage : StudyScoreCard.message(right: right, total: total, outcome: outcome, passMark: ReadingTestProgress.passMark),
                           hints: hints, speedBest: isSpeed ? progress.speedBest : nil)
                .id(Self.promptID)

            if let tier, passed, let next = tier.next {
                StudyResultButton(title: String(localized: "Next Tier: \(next.title)"), systemImage: "arrow.forward.circle.fill", prominent: true) {
                    mode = .test(next)
                    start()
                }
            }

            if !missed.isEmpty, !isSpeed || missed.count >= 3 {
                StudyResultButton(title: String(localized: "Practice What You Missed"), systemImage: "arrow.uturn.backward.circle", prominent: tier != nil && !passed) {
                    mode = .missed(missed)
                    start()
                }
            }

            StudyResultButton(title: tier != nil && !passed ? String(localized: "Try Again") : String(localized: "Go Again"), systemImage: "arrow.clockwise",
                              prominent: tier != nil && !passed && missed.isEmpty) {
                if case .missed = mode, missed.isEmpty { mode = .missed(nil) }
                start()
            }

            StudyResultButton(title: String(localized: "Back"), systemImage: "chevron.backward") {
                dismiss()
            }
        } header: {
            StudySectionHeader(String(localized: "RESULTS"), systemImage: "chart.bar")
        }
    }

    private var speedMessage: String {
        if right == 0 { return String(localized: "The clock ran out. Read and spell questions only: one look, one tap.") }
        if right >= progress.speedBest, right > 0 { return String(localized: "Your best yet. The clock only counts right answers, so slow down for the hard ones.") }
        return String(localized: "The clock counts right answers only. Faster next time, or steadier.")
    }

    private var placementResults: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: placementCleared ? "checkmark.seal.fill" : "scope")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(accent)

                if let tier = placementResult {
                    Text("Start at Tier \(tier.number)")
                        .font(.title2.weight(.bold))

                    Text(tier.title)
                        .font(.headline)
                        .foregroundColor(accent)

                    Text(tier.number == 1 ? String(localized: "Begin at the beginning. It goes quickly.")
                         : String(localized: "You read everything below it. This is the first tier that caught you, so it is where the ladder now starts for you."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("You read every tier")
                        .font(.title2.weight(.bold))

                    Text("Nothing on the ladder caught you. Take any tier's test to put a pass against it.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .listRowSeparator(.hidden)
            .id(Self.promptID)

            if let tier = placementResult {
                StudyResultButton(title: String(localized: "Take the Tier \(tier.number) Test"), systemImage: "play.fill", prominent: true) {
                    mode = .test(tier)
                    start()
                }
            }

            StudyResultButton(title: String(localized: "Back"), systemImage: "chevron.backward") {
                dismiss()
            }
        } header: {
            StudySectionHeader(String(localized: "YOUR LEVEL"), systemImage: "scope")
        }
    }
}

// MARK: - The gapped word

/// A word with one letter taken out: the letters before, a dashed stroke where the letter was, the
/// letters after, drawn as one run so the joining is right on both sides of the gap.
private struct ReadingGapWord: View {
    @Environment(\.appearance) private var appearance

    let question: ReadingQuestion
    let style: ReadingTextStyle
    let size: CGFloat

    var body: some View {
        if let parts = question.gapParts {
            let custom = appearance.useFontArabic && !style.plainFace
            let font: Font = custom ? appearance.islamArabicFont(base: size, relativeTo: .largeTitle) : .system(size: size * 0.9)
            let before = ReadingTestText.display(parts.before, mushafMarks: style.mushafMarks)
            let after = ReadingTestText.display(parts.after, mushafMarks: style.mushafMarks)
            // Two tatweels keep the pen on the line through the gap; the colour says "missing".
            (Text(before) + Text("\u{0640}\u{0640}").foregroundColor(.secondary) + Text(after))
                .font(font)
                .arabicFontDesign(custom: custom && appearance.islamUsesCustomArabicFace)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .accessibilityLabel(String(localized: "The word with one letter missing"))
        }
    }
}

// MARK: - The reading key

/// How the readings are spelled. One sheet, reachable from the ladder.
private struct ReadingKeySheet: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        NavigationView {
            List {
                Group {
                    Section {
                        Text("The readings spell each letter the way the alphabet pages do. A capital letter is the heavy or deep twin of the small one, and two signs tell the hamza from the 'ayn, because a spelling test cannot ask which is which when they share one.")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Section {
                        ForEach(ReadingScheme.vowelKey, id: \.sign) { row in
                            keyRow(sign: row.sign, letter: nil, note: row.note)
                        }
                    } header: {
                        Text("VOWELS AND MARKS")
                    }

                    Section {
                        ForEach(ReadingScheme.key, id: \.letter) { row in
                            keyRow(sign: row.sign, letter: row.letter, note: row.note)
                        }
                    } header: {
                        Text("LETTERS")
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("Reading Key")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
    }

    private func keyRow(sign: String, letter: String?, note: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(sign)
                .font(.system(.body, design: .monospaced).weight(.bold))
                .leftToRightContent()
                .foregroundColor(appearance.accent)
                .frame(minWidth: letter == nil ? 96 : 34, alignment: .leading)

            if let letter {
                StudyArabicText(text: letter, base: 24, style: .title2)
                    .foregroundColor(.primary)
                    .frame(width: 30)
            }

            Text(note)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 1)
    }
}
