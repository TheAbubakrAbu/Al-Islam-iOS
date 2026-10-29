#if os(iOS)
import SwiftUI

// The Tajweed Test's screens: the ladder of chapters, one chapter's page, and the session that asks
// the questions. The model (tiers, skills, the question factory, progress) is in TajweedTest.swift;
// the pieces shared with the Reading Test are in StudyKit.swift. The ladder reads the course the way
// the course's own index does: parsed off the main thread, a spinner until it lands.

// MARK: - The ladder

struct TajweedTestView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = TajweedTestProgress.shared
    /// The reader's rule switches decide which missed Find It questions can be asked now
    /// (`reviewableMissed`): observed, so a rule turned back on puts its questions back in the count.
    @ObservedObject private var quranDisplay = QuranDisplay.shared

    @State private var course: TajweedLessonsStore.Course? = TajweedLessonsStore.shared.courseIfLoaded
    @State private var session: TajweedTestSessionView.Mode?
    @State private var confirmReset = false

    #if DEBUG
    @State private var debugTierOpen = false
    @State private var debugRouteFired = false
    private static func debugArgument(_ name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
    #endif

    private var accent: Color { appearance.accent }

    private var tiers: [TajweedTestTier] { course.map(TajweedTestLadder.tiers(in:)) ?? [] }

    /// A factory with the reader's rules as they are now, for what the missed bank can ask.
    private func readerFactory(_ tiers: [TajweedTestTier]) -> TajweedTestFactory {
        var factory = TajweedTestFactory(tiers: tiers, quran: QuranData.shared)
        factory.visibleCategories = Set(TajweedLegendCategory.allCases.filter(Settings.shared.isTajweedCategoryVisible))
        return factory
    }

    var body: some View {
        let tiers = self.tiers
        // Only what a Practice Missed round could ask now is counted or offered: a door to an empty
        // round otherwise (a missed Find It whose rule was switched off, 2026-10-28).
        let toReview = progress.missed.isEmpty || tiers.isEmpty ? 0 : progress.reviewableMissed(readerFactory(tiers)).count
        List {
            Group {
                introSection(tiers, toReview: toReview)

                if let course {
                    ForEach(Array(TajweedTestLadder.stages(in: course).enumerated()), id: \.offset) { index, group in
                        Section(header: StudyStageHeader(systemImage: TajweedTestLadder.systemImage(for: group.stage),
                                                         title: group.stage.map { String(localized: "Stage \(index + 1): \($0.titleEn.localizedDisplay)") } ?? String(localized: "More chapters"),
                                                         arabic: group.stage?.titleAr, blurb: group.stage?.blurb.localizedDisplay)) {
                            ForEach(group.tiers) { tier in
                                NavigationLink(destination: LazyDestination { TajweedTestTierView(tier: tier, tiers: tiers) }) {
                                    StudyTierRow(number: tier.number, systemImage: tier.legend == nil ? "graduationcap" : "paintpalette",
                                                 tint: tier.accent(fallback: accent),
                                                 title: tier.title, summary: tier.lessons.count == 1 ? String(localized: "1 lesson") : String(localized: "\(tier.lessons.count) lessons \u{00B7} \(tier.subtitle)"),
                                                 record: progress.record(for: tier), isNext: progress.nextTier(in: tiers) == tier)
                                }
                            }
                        }
                    }

                    reviewSection(tiers, toReview: toReview)
                    moreSection
                } else if TajweedLessonsStore.isBundled {
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
        .navigationTitle("Tajweed Test")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            var loaded = course
            if loaded == nil, TajweedLessonsStore.isBundled {
                loaded = await Task.detached(priority: .userInitiated) { TajweedLessonsStore.shared.course() }.value
                course = loaded
            }
            // A missed question whose lesson the pack no longer has could never be answered right.
            if let loaded, !progress.missed.isEmpty {
                progress.forgetUnrebuildableMissed(readerFactory(TajweedTestLadder.tiers(in: loaded)))
            }
        }
        .pushDestination(isPresented: Binding(get: { session != nil }, set: { if !$0 { session = nil } })) {
            if let session { TajweedTestSessionView(mode: session, tiers: tiers) }
        }
        .confirmationDialog("Reset your Tajweed Test progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                Settings.shared.hapticFeedback()
                withAnimation(.easeInOut) { progress.reset() }
            }
        } message: {
            Text("Every chapter goes back to not passed, and the questions kept for review are forgotten. The lessons you marked done stay done. This cannot be undone.")
        }
        #if DEBUG
        .debugPushDestination(isPresented: $debugTierOpen) {
            if let id = Self.debugArgument("-tajweedTestTier"), let tier = tiers.first(where: { $0.id == id }) {
                TajweedTestTierView(tier: tier, tiers: tiers)
            }
        }
        // The course is usually parsed already (the index loaded it), so the route runs on appear;
        // on a cold open it waits for the pack to land.
        .onAppear { fireDebugRoute() }
        .onChange(of: course == nil) { _ in fireDebugRoute() }
        #endif
    }

    #if DEBUG
    private func fireDebugRoute() {
        guard course != nil, !debugRouteFired else { return }
        debugRouteFired = true
        if let seed = Self.debugArgument("-tajweedTestSeed").flatMap(Int.init) { progress.debugSeed(passed: seed, tiers: tiers) }
        let arguments = ProcessInfo.processInfo.arguments
        if Self.debugArgument("-tajweedTestTier") != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugTierOpen = true }
        } else if arguments.contains("-tajweedTestPlacement") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { session = .placement }
        } else if arguments.contains("-tajweedTestReview") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { session = .review }
        }
    }
    #endif

    // MARK: Sections

    /// The ladder's `ResourceHero`: the figures, the progress and the two ways in as its footer.
    private func introSection(_ tiers: [TajweedTestTier], toReview: Int) -> some View {
        let total = tiers.count
        let passed = progress.passedCount(in: tiers)
        let started = passed > 0 || progress.placement != nil || !progress.records.isEmpty
        let next = progress.nextTier(in: tiers)
        return ResourceHeroSection(ResourceHero(
            eyebrow: String(localized: "TAJWEED TEST"),
            systemImage: "checkmark.seal.fill",
            headline: String(localized: "Ten chapters, tested the way they were taught"),
            message: String(localized: "One test for each chapter of the course, built from its lessons: their own questions, the rule in a word, the word in an ayah, the letters of a group, how long a hold is, and what to do instead of a common mistake. Eight right out of ten passes a chapter."),
            stats: started && total > 0 ? [
                ResourceHeroStat("\(passed)", String(localized: "of \(total) passed")),
                ResourceHeroStat("\(progress.masteredCount(in: tiers))", String(localized: "mastered")),
                ResourceHeroStat("\(toReview)", String(localized: "to review")),
            ] : []
        ) {
            if !tiers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    if passed > 0 {
                        ProgressView(value: Double(passed), total: Double(total))
                            .tint(accent)
                    }

                    HStack(spacing: 8) {
                        if let next {
                            StudyHeroButton(title: passed == 0 && progress.placement == nil ? String(localized: "Start: \(next.title)") : String(localized: "Continue: \(next.title)"),
                                            systemImage: "play.fill", filled: true) {
                                session = .test(next)
                            }
                        }

                        StudyHeroButton(title: String(localized: "Find My Level"), systemImage: "scope", filled: next == nil) {
                            session = .placement
                        }
                    }
                }
            }
        })
    }

    private func reviewSection(_ tiers: [TajweedTestTier], toReview: Int) -> some View {
        let passed = progress.passedCount(in: tiers)
        return Section {
            StudyActionRow(title: String(localized: "Final Review"), systemImage: "shuffle",
                           caption: passed > 0 ? String(localized: "Twenty questions from the chapters you have passed") : String(localized: "Twenty questions from every chapter")) {
                session = .review
            }

            if toReview > 0 {
                StudyActionRow(title: String(localized: "Practice Missed Questions"), systemImage: "arrow.uturn.backward.circle",
                               caption: String(localized: "The questions you missed in scored tests, until you get them right"),
                               detail: "\(toReview)") {
                    session = .missed(nil)
                }
            }
        } header: {
            StudySectionHeader(String(localized: "REVIEW"), systemImage: "arrow.triangle.2.circlepath")
        } footer: {
            if toReview > 0 {
                Text("A question leaves the review list once you answer it right in a review or a scored test.")
            }
        }
    }

    private var moreSection: some View {
        Section {
            if !progress.records.isEmpty || progress.placement != nil || !progress.missed.isEmpty {
                StudyActionRow(title: String(localized: "Reset Progress"), systemImage: "arrow.counterclockwise",
                               caption: String(localized: "Start the ladder again from nothing"), tint: .red, trailingSymbol: nil) {
                    confirmReset = true
                }
            }
        } header: {
            if !progress.records.isEmpty || progress.placement != nil || !progress.missed.isEmpty {
                StudySectionHeader(String(localized: "MORE"), systemImage: "ellipsis.circle")
            }
        } footer: {
            Text("Every question is built from the course's own lessons. A question about a real ayah is checked against the reader's tajweed colours, so a word the painter marks is accepted even when the lesson pointed at another.")
        }
    }
}

// MARK: - One chapter

struct TajweedTestTierView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = TajweedTestProgress.shared
    @ObservedObject private var lessonProgress = TajweedLessonProgress.shared
    /// The reader's tajweed rule switches decide which skills `skills` offers. Observed, so turning a
    /// rule on or off in Settings redraws the practice list instead of leaving it as it was when the
    /// page opened (2026-10-28). A session reads the switches itself when its round starts.
    @ObservedObject private var quranDisplay = QuranDisplay.shared

    let tier: TajweedTestTier
    let tiers: [TajweedTestTier]

    @State private var session: TajweedTestSessionView.Mode?
    #if DEBUG
    @State private var debugStartFired = false
    #endif

    private var accent: Color { tier.accent(fallback: appearance.accent) }

    /// The skills this chapter's lessons can ask, as the factory sees them with the reader's rules on.
    private var skills: [TajweedTestSkill] {
        var factory = TajweedTestFactory(tiers: tiers, quran: QuranData.shared)
        factory.visibleCategories = Set(TajweedLegendCategory.allCases.filter(Settings.shared.isTajweedCategoryVisible))
        return factory.skills(for: tier)
    }

    var body: some View {
        let record = progress.record(for: tier)
        let skills = self.skills
        List {
            Group {
                heroSection(record)
                lessonsSection
                testSection(record)
                practiceSection(record, skills: skills)
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(tier.title)
        .navigationBarTitleDisplayMode(.inline)
        .pushDestination(isPresented: Binding(get: { session != nil }, set: { if !$0 { session = nil } })) {
            if let session { TajweedTestSessionView(mode: session, tiers: tiers) }
        }
        #if DEBUG
        // "-tajweedTestStart test|recall|name|spot|letters|count|fix|term": open the session straight away.
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            guard !debugStartFired, session == nil,
                  let index = arguments.firstIndex(of: "-tajweedTestStart"), arguments.indices.contains(index + 1) else { return }
            debugStartFired = true
            let value = arguments[index + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                session = TajweedTestSkill(rawValue: value).map { .practice(tier, $0) } ?? .test(tier)
            }
        }
        #endif
    }

    private func heroSection(_ record: StudyRecord) -> some View {
        let tint = accent
        return Section {
            ResourceHero(
                eyebrow: String(localized: "Chapter \(tier.number) of \(tier.count)\(tier.stage.map { " \u{00B7} " + $0.titleEn.localizedDisplay } ?? "")").uppercased(),
                systemImage: "checkmark.seal.fill",
                headline: tier.title,
                message: tier.subtitle
            ) {
                if record.attempts > 0 {
                    StudyIconText(record.mastered ? String(localized: "Mastered: every answer right, no hints")
                          : record.passed ? String(localized: "Passed \u{00B7} best \(record.best)%")
                          : String(localized: "Best so far \(record.best)% \u{00B7} \(TajweedTestProgress.passMark)% passes"),
                          systemImage: record.mastered ? "checkmark.seal.fill" : record.passed ? "checkmark.circle.fill" : "chart.bar")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(record.passed ? tint : .secondary)
                }
            }
            .transformEnvironment(\.appearance) { $0.accent = tint }
            .articleCardRow()
        }
    }

    /// The lessons the test draws on, each a door into the course.
    private var lessonsSection: some View {
        Section {
            ForEach(tier.lessons) { lesson in
                TajweedLessonLink(lessonID: lesson.id) {
                    HStack(spacing: 12) {
                        Group {
                            if lessonProgress.isDone(lesson.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(lesson.accent(fallback: appearance.accent))
                            } else {
                                Image(systemName: "book")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 26)

                        Text(lesson.titleEn.localizedDisplay)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)

                        Spacer(minLength: 6)

                        if !lesson.titleAr.isEmpty {
                            Text(lesson.titleAr)
                                .font(Font.arabic(appearance.quranDisplayFace, size: 16))
                                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                                .frame(maxWidth: 110, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        } header: {
            StudySectionHeader(String(localized: "WHAT THIS CHAPTER TESTS"), systemImage: "text.book.closed")
        } footer: {
            Text("Every question comes from one of these lessons. A miss offers the lesson it came from.")
        }
    }

    private func testSection(_ record: StudyRecord) -> some View {
        Section {
            StudyResultButton(title: record.attempts == 0 ? String(localized: "Start the Test") : String(localized: "Take the Test Again"),
                              systemImage: "play.fill", prominent: true) {
                session = .test(tier)
            }
            .transformEnvironment(\.appearance) { $0.accent = accent }
        } header: {
            StudySectionHeader(String(localized: "THE TEST"), systemImage: "checkmark.seal")
        } footer: {
            Text("Ten questions, the skills below mixed together. \(TajweedTestProgress.passMark)% passes. A hint never costs you the answer, but a chapter is only mastered with every answer right and no hints.")
        }
    }

    private func practiceSection(_ record: StudyRecord, skills: [TajweedTestSkill]) -> some View {
        Section {
            ForEach(skills) { skill in
                StudyActionRow(title: skill.title, systemImage: skill.systemImage, caption: skill.caption,
                               detail: record.skillBest[skill.rawValue].map { "\($0)%" }) {
                    session = .practice(tier, skill)
                }
            }
        } header: {
            StudySectionHeader(String(localized: "PRACTICE ONE SKILL"), systemImage: "figure.walk")
        } footer: {
            if skills.contains(.spot) {
                Text("Practice rounds are not scored against the chapter. Find It in the Ayah is graded against the reader's tajweed colours, so it is only offered while the chapter's rules are switched on in the Quran settings.")
            } else {
                Text("Practice rounds are not scored against the chapter. The figure beside a skill is your best practice round of it.")
            }
        }
    }
}

// MARK: - The session

struct TajweedTestSessionView: View {
    enum Mode: Equatable {
        case test(TajweedTestTier)
        case practice(TajweedTestTier, TajweedTestSkill)
        case placement
        case review
        /// The questions missed before: these ones (as source keys with their chapters), or the whole
        /// review bank when nil.
        case missed([StudyMissedItem]?)
    }

    @Environment(\.appearance) private var appearance
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var progress = TajweedTestProgress.shared

    let tiers: [TajweedTestTier]

    @State private var mode: Mode
    @State private var questions: [TajweedTestQuestion] = []
    @State private var loading = false
    @State private var index = 0
    @State private var chosen: Int?
    @State private var hintShown = false
    @State private var hintedThisQuestion = false
    @State private var right = 0
    @State private var hints = 0
    @State private var streak = 0
    @State private var missed: [TajweedTestQuestion] = []
    @State private var answeredRight: [TajweedTestQuestion] = []
    @State private var finished = false
    @State private var placementIndex = 0
    @State private var placementResult: TajweedTestTier?
    @State private var placementCleared = false

    init(mode: Mode, tiers: [TajweedTestTier]) {
        _mode = State(initialValue: mode)
        self.tiers = tiers
    }

    private var isPlacement: Bool { mode == .placement }

    private var title: String {
        switch mode {
        case .test(let tier): return tier.title
        case .practice(_, let skill): return skill.title
        case .placement: return String(localized: "Find My Level")
        case .review: return String(localized: "Final Review")
        case .missed: return String(localized: "Practice Missed Questions")
        }
    }

    /// The colour the current question wears: its lesson's, where the reader paints that rule.
    private var accent: Color {
        guard questions.indices.contains(index), !finished else {
            if case .test(let tier) = mode { return tier.accent(fallback: appearance.accent) }
            if case .practice(let tier, _) = mode { return tier.accent(fallback: appearance.accent) }
            return appearance.accent
        }
        return questions[index].lesson.accent(fallback: appearance.accent)
    }

    var body: some View {
        let accent = self.accent
        ScrollViewReader { proxy in
            List {
                Group {
                    if finished {
                        resultsSections
                    } else if questions.indices.contains(index) {
                        questionSections(questions[index])
                    } else if loading || questions.isEmpty {
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
            .onChange(of: scrollCue) { cue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut) { proxy.scrollTo(cue.hasSuffix("answered") ? Self.nextID : Self.promptID, anchor: cue.hasSuffix("answered") ? .bottom : .top) }
                }
            }
        }
        .transformEnvironment(\.appearance) { $0.accent = accent }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if questions.isEmpty, !finished, !loading { start() } }
    }

    private static let promptID = "tajweedPrompt"
    private static let nextID = "tajweedNext"

    private var scrollCue: String {
        "\(index)-\(finished ? "finished" : chosen != nil ? "answered" : "asking")"
    }

    // MARK: Asking

    @ViewBuilder
    private func questionSections(_ question: TajweedTestQuestion) -> some View {
        let answered = chosen != nil

        Section {
            VStack(spacing: 10) {
                promptView(question)

                Text(question.ask)
                    .font(.subheadline.weight(question.skill == .recall ? .semibold : .regular))
                    .foregroundColor(question.skill == .recall ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if hintShown, let hint = question.hint {
                    Text(hint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.secondary.opacity(0.08)))
                } else if !answered, !isPlacement, question.hint != nil {
                    StudyHintChip(title: String(localized: "Hint: Show the Rule"), systemImage: "lightbulb") {
                        hintShown = true
                        if !hintedThisQuestion {
                            hintedThisQuestion = true
                            hints += 1
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .id(Self.promptID)
        } header: {
            StudyQuestionHeader(
                title: isPlacement ? String(localized: "CHAPTER \(question.tier.number): \(question.tier.title.uppercased())")
                    : String(localized: "QUESTION \(index + 1) OF \(questions.count)"),
                streak: isPlacement ? 0 : streak)
        }

        Section {
            if question.skill == .spot {
                StudyWordTapLine(words: question.words, rightWords: question.rightWords, picked: chosen,
                                 fontName: appearance.quranDisplayFace, size: 26) { picked in
                    choose(picked, in: question)
                }
                .padding(.vertical, 6)
            } else {
                choiceArea(question)
            }

            if answered {
                feedback(question)

                StudyAdvanceButton(title: isLast ? String(localized: "See Results") : String(localized: "Next")) {
                    advance()
                }
                .id(Self.nextID)
            }
        }
    }

    private var isLast: Bool { !isPlacement && index + 1 == questions.count }

    @ViewBuilder
    private func promptView(_ question: TajweedTestQuestion) -> some View {
        if question.prompt.isEmpty {
            EmptyView()
        } else if question.promptIsArabic {
            Text(question.prompt)
                .font(Font.arabic(appearance.quranDisplayFace, size: question.prompt.count > 24 ? 30 : 40))
                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                .foregroundColor(accent)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, minHeight: 84)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(accent.opacity(0.10)))
        } else if question.skill == .spot {
            // The reference, small: the ayah itself is the row of words below.
            Text(question.prompt)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        } else {
            // A mistake described in prose: a paragraph in a box, not a headline.
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.red)
                    .padding(.top, 1)
                Text(question.prompt)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.red.opacity(0.08)))
        }
    }

    // MARK: Choices

    @ViewBuilder
    private func choiceArea(_ question: TajweedTestQuestion) -> some View {
        let long = question.choices.contains { $0.text.count > ($0.isArabic ? 12 : 15) }
        SummaryTileGrid(columns: long ? 1 : 2) {
            ForEach(question.choices) { choice in
                let state = StudyChoiceState(answered: chosen != nil, isAnswer: choice.id == question.answer, picked: chosen == choice.id)
                StudyChoiceButton(state: state, long: long) {
                    choose(choice.id, in: question)
                } label: {
                    if choice.isArabic {
                        Text(choice.text)
                            .font(Font.arabic(appearance.quranDisplayFace, size: long ? 24 : 30))
                            .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                            .foregroundColor(accent)
                    } else {
                        Text(choice.text)
                            .font(long ? .subheadline.weight(.semibold) : .title3.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                }
                .accessibilityLabel(choice.text)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Feedback

    private func wasRight(_ question: TajweedTestQuestion) -> Bool {
        guard let chosen else { return false }
        return question.skill == .spot ? question.rightWords.contains(chosen) : chosen == question.answer
    }

    @ViewBuilder
    private func feedback(_ question: TajweedTestQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            StudyVerdictLine(wasRight: wasRight(question), hinted: hintedThisQuestion)

            if question.skill == .spot, question.rightWords.count > 1 {
                Text(String(localized: "Every word marked green carries the rule."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !question.explain.isEmpty {
                Text(question.explain)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // A question about a real ayah shows it painted, so the colours confirm the answer.
            if let reference = question.reference {
                TajweedTestPaintedAyah(surah: reference.surah, ayah: reference.ayah)
            }

            TajweedLessonLink(lessonID: question.lesson.id) {
                HStack(spacing: 10) {
                    AccentIconChip(systemImage: "graduationcap.fill", tint: accent, size: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("From the lesson")
                            .font(.caption2.weight(.heavy))
                            .tracking(0.7)
                            .foregroundStyle(.secondary)
                        Text(question.lesson.titleEn.localizedDisplay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    Spacer(minLength: 8)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: Running

    private func start() {
        loading = true
        questions = []
        index = 0
        right = 0
        hints = 0
        streak = 0
        missed = []
        answeredRight = []
        finished = false
        placementResult = nil
        placementCleared = false
        placementIndex = 0
        resetQuestionState()
        let mode = mode
        let tiers = tiers
        let visible = Set(TajweedLegendCategory.allCases.filter(Settings.shared.isTajweedCategoryVisible))
        let passed = tiers.filter { progress.record(for: $0).passed }
        let bank = progress.missed
        // The round is built off the main thread: a Find It question paints its ayah word by word.
        Task { @MainActor in
            let built = await Task.detached(priority: .userInitiated) { () -> [TajweedTestQuestion] in
                var factory = TajweedTestFactory(tiers: tiers, quran: QuranData.shared)
                factory.visibleCategories = visible
                switch mode {
                case .test(let tier): return factory.round(for: tier)
                case .practice(let tier, let skill): return factory.round(for: tier, only: skill)
                case .review: return factory.review(of: passed.isEmpty ? tiers : passed)
                case .missed(let items):
                    let pool = (items ?? bank).map { (key: $0.id, tier: $0.tier) }
                    return factory.review(ofMissed: pool)
                case .placement: return tiers.first.map { factory.placementPair(for: $0) } ?? []
                }
            }.value
            guard self.mode == mode else { return }
            questions = built
            loading = false
            finished = built.isEmpty
        }
    }

    private func resetQuestionState() {
        chosen = nil
        hintShown = false
        hintedThisQuestion = false
    }

    private func choose(_ id: Int, in question: TajweedTestQuestion) {
        guard chosen == nil else { return }
        chosen = id
        if wasRight(question) {
            right += 1
            streak += 1
            if !answeredRight.contains(where: { $0.sourceKey == question.sourceKey }) { answeredRight.append(question) }
        } else {
            streak = 0
            if !missed.contains(where: { $0.sourceKey == question.sourceKey }) { missed.append(question) }
        }
    }

    private func advance() {
        if isPlacement {
            advancePlacement()
            return
        }
        if index + 1 >= questions.count {
            finish()
        } else {
            resetQuestionState()
            index += 1
        }
    }

    /// Two questions a chapter: both right moves up the ladder, a miss stops it there.
    private func advancePlacement() {
        guard questions.indices.contains(index), wasRight(questions[index]) else {
            placementResult = tiers.indices.contains(placementIndex) ? tiers[placementIndex] : nil
            finish()
            return
        }
        if index + 1 < questions.count {
            resetQuestionState()
            index += 1
            return
        }
        placementIndex += 1
        guard placementIndex < tiers.count else {
            placementCleared = true
            finish()
            return
        }
        let tier = tiers[placementIndex]
        let tiers = tiers
        let visible = Set(TajweedLegendCategory.allCases.filter(Settings.shared.isTajweedCategoryVisible))
        loading = true
        questions = []
        resetQuestionState()
        Task { @MainActor in
            let pair = await Task.detached(priority: .userInitiated) { () -> [TajweedTestQuestion] in
                var factory = TajweedTestFactory(tiers: tiers, quran: QuranData.shared)
                factory.visibleCategories = visible
                return factory.placementPair(for: tier)
            }.value
            questions = pair
            index = 0
            loading = false
            if pair.isEmpty {
                placementCleared = true
                finish()
            }
        }
    }

    private func finish() {
        switch mode {
        case .test(let tier):
            progress.finish(tier, right: right, of: questions.count, hints: hints, missed: missed, answeredRight: answeredRight)
        case .practice(let tier, let skill):
            progress.recordPractice(tier, skill: skill, right: right, of: questions.count)
        case .placement:
            if let placementResult { progress.setPlacement(placementResult) }
        case .review, .missed:
            progress.finishReview(missedIDs: missed.map { ($0.sourceKey, $0.tier.id) },
                                  rightIDs: answeredRight.map { ($0.sourceKey, $0.tier.id) })
        }
        withAnimation(.easeInOut) { finished = true }
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
                ForEach(missed) { question in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(question.ask)
                                .font(.subheadline.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            if question.promptIsArabic, !question.prompt.isEmpty {
                                Text(question.prompt)
                                    .font(Font.arabic(appearance.quranDisplayFace, size: 20))
                                    .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                    .foregroundColor(question.lesson.accent(fallback: appearance.accent))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                        Text(question.skill == .spot ? question.rightWords.sorted().map { question.words[$0] }.joined(separator: " ")
                             : question.choices.indices.contains(question.answer) ? question.choices[question.answer].text : "")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.green)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(question.lesson.titleEn.localizedDisplay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                StudySectionHeader(String(localized: "LOOK AT THESE AGAIN"), systemImage: "eye")
            } footer: {
                if case .test = mode {
                    Text("These questions are kept under Practice Missed Questions on the ladder until you answer them right.")
                }
            }
        }
    }

    private var scoreSection: some View {
        let total = questions.count
        let percent = total == 0 ? 0 : Int((Double(right) / Double(total) * 100).rounded())
        let passed = percent >= TajweedTestProgress.passMark
        let tier: TajweedTestTier? = { if case .test(let tier) = mode { return tier } else { return nil } }()
        // A round that built no questions scored nothing: 0 of 0 is never Mastered (nor recorded).
        let outcome: StudyOutcome? = tier == nil || total == 0 ? nil : (right == total && hints == 0) ? .mastered : passed ? .passed : .failed
        let next = tier.flatMap { current in tiers.firstIndex(of: current).flatMap { tiers.indices.contains($0 + 1) ? tiers[$0 + 1] : nil } }
        // A missed round with nothing missed goes again over the whole bank, which may have nothing
        // left to ask now: no door to an empty round.
        let againIsEmpty: Bool = {
            guard case .missed = mode, missed.isEmpty else { return false }
            var factory = TajweedTestFactory(tiers: tiers, quran: QuranData.shared)
            factory.visibleCategories = Set(TajweedLegendCategory.allCases.filter(Settings.shared.isTajweedCategoryVisible))
            return progress.reviewableMissed(factory).isEmpty
        }()

        return Section {
            StudyScoreCard(right: right, total: total, outcome: outcome,
                           message: StudyScoreCard.message(right: right, total: total, outcome: outcome, passMark: TajweedTestProgress.passMark),
                           hints: hints)
                .id(Self.promptID)

            if tier != nil, passed, let next {
                StudyResultButton(title: String(localized: "Next Chapter: \(next.title)"), systemImage: "arrow.forward.circle.fill", prominent: true) {
                    mode = .test(next)
                    start()
                }
            }

            if !missed.isEmpty {
                StudyResultButton(title: String(localized: "Practice What You Missed"), systemImage: "arrow.uturn.backward.circle", prominent: tier != nil && !passed) {
                    mode = .missed(missed.map { StudyMissedItem(id: $0.sourceKey, tier: $0.tier.id, count: 1, last: Date()) })
                    start()
                }
            }

            if !againIsEmpty {
                StudyResultButton(title: tier != nil && !passed ? String(localized: "Try Again") : String(localized: "Go Again"), systemImage: "arrow.clockwise",
                                  prominent: tier != nil && !passed && missed.isEmpty) {
                    if case .missed = mode, missed.isEmpty { mode = .missed(nil) }
                    start()
                }
            }

            StudyResultButton(title: String(localized: "Back"), systemImage: "chevron.backward") {
                dismiss()
            }
        } header: {
            StudySectionHeader(String(localized: "RESULTS"), systemImage: "chart.bar")
        }
    }

    private var placementResults: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: placementCleared ? "checkmark.seal.fill" : "scope")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(accent)

                if let tier = placementResult {
                    Text("Start at Chapter \(tier.number)")
                        .font(.title2.weight(.bold))

                    Text(tier.title)
                        .font(.headline)
                        .foregroundColor(accent)

                    Text(tier.number == 1 ? String(localized: "Begin at the beginning. The first chapters go quickly.")
                         : String(localized: "You answered everything below it. This is the first chapter that caught you, so it is where the ladder now starts for you."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("You know every chapter")
                        .font(.title2.weight(.bold))

                    Text("Nothing on the ladder caught you. Take any chapter's test to put a pass against it.")
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
                StudyResultButton(title: String(localized: "Take the Chapter \(tier.number) Test"), systemImage: "play.fill", prominent: true) {
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

// MARK: - The painted ayah

/// An ayah in the reader's tajweed colours, under a question about it: painted on a detached task (the
/// paint is pure and its caches are thread-safe), plain for a frame.
private struct TajweedTestPaintedAyah: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var quranData = QuranData.shared

    let surah: Int
    let ayah: Int

    @State private var styled: AttributedString?

    private var text: String? {
        guard let surah = quranData.surah(surah), let ayah = surah.ayahs.first(where: { $0.id == ayah }) else { return nil }
        return ayah.rawArabicText(surahId: surah.id, qiraahOverride: "")
    }

    var body: some View {
        if let text {
            VStack(alignment: .leading, spacing: 6) {
                Group {
                    if let styled {
                        Text(styled)
                    } else {
                        Text(text)
                    }
                }
                .font(.custom(appearance.quranDisplayFace, size: CGFloat(appearance.fontArabicSize)))
                .arabicFontDesign(custom: true)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                // The ayah's lines on the right, as the reader sets them, in either interface.
                .environment(\.layoutDirection, .leftToRight)
                .task(id: "\(surah):\(ayah)") {
                    let surah = surah, ayah = ayah, text = text
                    styled = await Task.detached(priority: .userInitiated) {
                        TajweedStore.shared.attributedText(surah: surah, ayah: ayah, text: text)
                    }.value
                }

                Button {
                    Settings.shared.hapticFeedback()
                    AppNavigation.shared.open(.ayah(surah, ayah))
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book")
                        Text("Open in the Quran")
                            .font(.caption.weight(.semibold))
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(appearance.accent)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.secondary.opacity(0.08)))
        }
    }
}
#endif
