import SwiftUI

// The Reading Test's screens: the ladder of tiers, one tier's page, and the session that asks the
// questions. The model (tiers, the word bank, how wrong answers are made, progress) is in
// ArabicReadingTest.swift. Phone only: a question wants a two-by-two grid and a row of letter tiles.

// MARK: - Arabic text

/// Arabic in the Islam tab's face, or in the plain system face for anything printed without marks
/// (a mushaf face draws a final yaa without its dots, and a bare, dotless yaa spells something else).
private struct ReadingArabic: View {
    @Environment(\.appearance) private var appearance

    let text: String
    let base: CGFloat
    let style: Font.TextStyle
    var plain = false

    var body: some View {
        let custom = appearance.useFontArabic && !plain
        Text(text)
            .font(custom ? appearance.islamArabicFont(base: base, relativeTo: style) : .system(size: base * 0.9))
            .arabicFontDesign(custom: custom && appearance.islamUsesCustomArabicFace)
    }
}

/// An icon and a title side by side. Not a `Label`: inside a List row a Label's icon is given a column
/// of its own (so that titles line up down the list), which opens a wide gap in a button or a capsule.
private struct ReadingIconText: View {
    let title: String
    let systemImage: String

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)

            Text(title)
        }
    }
}

private extension ReadingTier {
    /// The tile's glyph in the sukoon the reader has chosen, like everything else the tier draws.
    var drawnSpecimen: String {
        ReadingTestText.display(specimen, mushafMarks: Settings.shared.quranicSukoonInLetterPractice || display == .mushaf)
    }
}

/// How a session draws its Arabic: which marks, which face, spaced or joined.
private struct ReadingTextStyle {
    let tier: ReadingTier
    /// `Settings.quranicSukoonInLetterPractice`, read once when the session opens.
    let mushafSukoon: Bool

    var plainFace: Bool { tier.display == .unmarked }

    func draw(_ arabic: String, spaced: Bool) -> String {
        let shown = ReadingTestText.display(arabic, mushafMarks: mushafSukoon || tier.display == .mushaf)
        return spaced || tier.display == .spaced ? ReadingTestText.spaced(shown) : shown
    }
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

                ForEach(ReadingStage.allCases) { stage in
                    Section(header: stageHeader(stage)) {
                        ForEach(ReadingTier.tiers(in: stage)) { tier in
                            NavigationLink(destination: LazyDestination { ReadingTierView(tier: tier) }) {
                                ReadingTierRow(tier: tier, record: progress.record(for: tier),
                                               isNext: progress.nextTier == tier)
                            }
                        }
                    }
                }

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
        .sheet(isPresented: $showKey) { ReadingKeySheet() }
        .confirmationDialog("Reset your Reading Test progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                Settings.shared.hapticFeedback()
                withAnimation(.easeInOut) { progress.reset() }
            }
        } message: {
            Text("Every tier goes back to not passed. This cannot be undone.")
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
            if Self.debugArgument("-readingTier") != nil, !debugTierOpen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugTierOpen = true }
            } else if ProcessInfo.processInfo.arguments.contains("-readingPlacement"), session == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { session = .placement }
            } else if ProcessInfo.processInfo.arguments.contains("-readingKey"), !showKey {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showKey = true }
            }
        }
        #endif
    }

    private var sessionBinding: Binding<Bool> {
        Binding(get: { session != nil }, set: { if !$0 { session = nil } })
    }

    // MARK: Sections

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    AccentIconChip(systemImage: "text.book.closed.fill", size: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("From one letter to a page with no tashkeel")
                            .font(.subheadline.weight(.semibold))

                        Text("\(ReadingTier.all.count) tiers, in the order a qaa'idah teaches reading before the Quran. Each one tests reading, spelling and listening, never meaning. Eight right out of ten passes a tier, and any tier can be opened at any time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if progress.passedCount > 0 {
                    ProgressView(value: Double(progress.passedCount), total: Double(ReadingTier.all.count))
                        .tint(accent)

                    Text("\(progress.passedCount) of \(ReadingTier.all.count) tiers passed")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(accent)
                }

                HStack(spacing: 8) {
                    if let next = progress.nextTier {
                        introButton(progress.passedCount == 0 && progress.placement == nil ? "Start: \(next.title)" : "Continue: \(next.title)",
                                    systemImage: "play.fill", filled: true) {
                            session = .test(next)
                        }
                    }

                    introButton("Find My Level", systemImage: "scope", filled: progress.nextTier == nil) {
                        session = .placement
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func introButton(_ title: String, systemImage: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundColor(filled ? .white : accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(filled ? accent : accent.opacity(0.12))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func stageHeader(_ stage: ReadingStage) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(stage.title.uppercased())

                Spacer()

                Text(stage.arabic)
                    .textCase(nil)
                    .foregroundColor(accent)
            }

            Text(stage.blurb)
                .font(.caption2)
                .textCase(nil)
                .foregroundStyle(.secondary)
        }
    }

    private var moreSection: some View {
        Section {
            Button {
                Settings.shared.hapticFeedback()
                session = .review
            } label: {
                moreRow("Mixed Review", systemImage: "shuffle",
                        caption: progress.passedCount > 0 ? "Fifteen questions from the tiers you have passed" : "Fifteen questions from every tier")
            }
            .buttonStyle(.plain)

            Button {
                Settings.shared.hapticFeedback()
                showKey = true
            } label: {
                moreRow("Reading Key", systemImage: "character.book.closed", caption: "How the readings are spelled: H, S, aa, and the rest")
            }
            .buttonStyle(.plain)

            if !progress.records.isEmpty || progress.placement != nil {
                Button {
                    Settings.shared.hapticFeedback()
                    confirmReset = true
                } label: {
                    moreRow("Reset Progress", systemImage: "arrow.counterclockwise", caption: "Start the ladder again from nothing", tint: .red)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("MORE")
        } footer: {
            Text("Every Quranic word here is cut from the app's own Hafs text, and its reading is checked against the word-by-word transliteration before it is allowed in. The unmarked words are spelled the way the hadith collections print them.")
        }
    }

    private func moreRow(_ title: String, systemImage: String, caption: String, tint: Color? = nil) -> some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(tint ?? .primary)

                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

/// One tier on the ladder: its number, its name in both languages, and where the learner stands.
private struct ReadingTierRow: View {
    @Environment(\.appearance) private var appearance

    let tier: ReadingTier
    let record: ReadingTestProgress.Record
    let isNext: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ReadingArabic(text: tier.drawnSpecimen, base: 22, style: .title2, plain: tier.display == .unmarked)
                    .foregroundColor(appearance.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.35)
                    .padding(.horizontal, 3)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(appearance.accent.opacity(isNext ? 0.22 : 0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isNext ? appearance.accent : .clear, lineWidth: 1.5)
                    )

                Text("\(tier.number)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Circle().fill(appearance.accent))
                    .offset(x: 5, y: 5)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tier.title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)

                Text(tier.arabic)
                    .font(.caption)
                    .foregroundColor(appearance.accent.opacity(0.9))
                    .lineLimit(1)

                Text(tier.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            status
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tier \(tier.number), \(tier.title). \(tier.summary). \(statusLabel)")
    }

    private var statusLabel: String {
        if record.mastered { return "Mastered" }
        if record.passed { return "Passed, best \(record.best) percent" }
        if record.attempts > 0 { return "Best \(record.best) percent" }
        return isNext ? "Up next" : "Not started"
    }

    @ViewBuilder
    private var status: some View {
        if record.mastered {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundColor(appearance.accent)
        } else if record.passed {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(appearance.accent)
        } else if record.attempts > 0 {
            Text("\(record.best)%")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
        } else if isNext {
            Text("NEXT")
                .font(.caption2.weight(.bold))
                .foregroundColor(appearance.accent)
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
                examplesSection
                testSection(record)
                practiceSection
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
        // "-readingStart test|read|spell|listen|build|stop|aloud...": open the session straight away.
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

    private func heroSection(_ record: ReadingTestProgress.Record) -> some View {
        Section {
            VStack(spacing: 8) {
                ReadingArabic(text: tier.drawnSpecimen, base: 44, style: .largeTitle, plain: tier.display == .unmarked)
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: .infinity, minHeight: 64)

                Text(tier.arabic)
                    .font(.headline)
                    .foregroundColor(accent)

                Text("Tier \(tier.number) of \(ReadingTier.all.count) \u{00B7} \(tier.stage.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                if record.attempts > 0 {
                    ReadingIconText(record.mastered ? "Mastered: every answer right, no hints"
                          : record.passed ? "Passed \u{00B7} best \(record.best)%"
                          : "Best so far \(record.best)% \u{00B7} \(ReadingTestProgress.passMark)% passes",
                          systemImage: record.mastered ? "checkmark.seal.fill" : record.passed ? "checkmark.circle.fill" : "chart.bar")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(record.passed ? accent : .secondary)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private var teachesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tier.teaches, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("WHAT THIS TIER TESTS")
        }
    }

    private var examplesSection: some View {
        Section {
            ForEach(ReadingTestBank.examples(for: tier), id: \.self) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.reading)
                            .font(.body.weight(.semibold))

                        if let caption = item.gloss, tier.id != "letters" {
                            Text(caption)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 8)

                    ReadingArabic(text: style.draw(item.arabic, spaced: examplesSpaced), base: 26, style: .title2, plain: style.plainFace)
                        .foregroundColor(accent)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.5)

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
            Text("EXAMPLES")
        } footer: {
            if tier.hint != .none, tier.display != .spaced {
                Text("That switch is the hint you get inside a test: Beginner Mode, every letter apart.")
            }
        }
    }

    private func testSection(_ record: ReadingTestProgress.Record) -> some View {
        Section {
            Button {
                Settings.shared.hapticFeedback()
                session = .test(tier)
            } label: {
                ReadingIconText(record.attempts == 0 ? "Start the Test" : "Take the Test Again", systemImage: "play.fill")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(accent))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("THE TEST")
        } footer: {
            Text("Ten questions, the skills below mixed together. \(ReadingTestProgress.passMark)% passes. A hint never costs you the answer, but a tier is only mastered with every answer right and no hints.")
        }
    }

    private var practiceSection: some View {
        let skills = tier.skills.filter { speech.isAvailable || !$0.needsVoice } + (tier.id == "forms" ? [] : [.aloud])
        return Section {
            ForEach(skills) { skill in
                Button {
                    Settings.shared.hapticFeedback()
                    session = .practice(tier, skill)
                } label: {
                    HStack(spacing: 12) {
                        AccentIconChip(systemImage: skill.systemImage)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.title)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)

                            Text(skill.caption)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(accent)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("PRACTICE ONE SKILL")
        } footer: {
            Text("Practice rounds are not scored against the tier.")
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
    }

    @Environment(\.appearance) private var appearance
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var speech = ArabicSpeech.shared
    @ObservedObject private var progress = ReadingTestProgress.shared

    @State private var mode: Mode
    @State private var questions: [ReadingQuestion] = []
    @State private var index = 0
    /// Multiple choice: the choice tapped. Build: set once the word is checked.
    @State private var chosen: Int?
    @State private var placed: [ReadingTile] = []
    @State private var buildRight: Bool?
    /// Read aloud: the reading has been shown.
    @State private var revealed = false
    /// 0 none, 1 letter by letter, 2 the marks shown (the unmarked tiers).
    @State private var hintLevel = 0
    @State private var hintedThisQuestion = false
    @State private var right = 0
    @State private var hints = 0
    @State private var streak = 0
    @State private var missed: [ReadingItem] = []
    @State private var finished = false
    /// Find My Level: where on the ladder it is asking, and how the current pair is going.
    @State private var placementIndex = 0
    @State private var placementResult: ReadingTier?
    @State private var placementCleared = false
    private let mushafSukoon = Settings.shared.quranicSukoonInLetterPractice

    init(mode: Mode) {
        _mode = State(initialValue: mode)
    }

    private var accent: Color { appearance.accent }

    private var isPlacement: Bool { mode == .placement }

    private var title: String {
        switch mode {
        case .test(let tier): return tier.title
        case .practice(_, let skill): return skill.title
        case .placement: return "Find My Level"
        case .review: return "Mixed Review"
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
        .onDisappear { ArabicSpeech.shared.stop() }
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

                if !answered, !isPlacement {
                    hintRow(question)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .id(Self.promptID)
        } header: {
            HStack {
                Text(isPlacement ? "TIER \(question.tier.number): \(question.tier.title.uppercased())"
                     : "QUESTION \(index + 1) OF \(questions.count)")

                Spacer()

                if streak > 1, !isPlacement {
                    ReadingIconText("\(streak) in a row", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(accent)
                        .textCase(nil)
                }
            }
        }

        Section {
            switch question.skill {
            case .build: buildArea(question, style: style)
            case .aloud: aloudArea(question)
            default: choiceArea(question, style: style)
            }

            if answered {
                feedback(question, style: style)

                Button {
                    Settings.shared.hapticFeedback()
                    advance()
                } label: {
                    Text(isLast ? "See Results" : "Next")
                        .font(.body.weight(.semibold))
                        .foregroundColor(accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .conditionalGlassEffect(rectangle: true)
                }
                .buttonStyle(.plain)
                .id(Self.nextID)
            }
        }
    }

    private var isLast: Bool { !isPlacement && index + 1 == questions.count }

    private func isAnswered(_ question: ReadingQuestion) -> Bool {
        switch question.skill {
        case .build: return buildRight != nil
        default: return chosen != nil
        }
    }

    @ViewBuilder
    private func promptView(_ question: ReadingQuestion, style: ReadingTextStyle) -> some View {
        if question.skill == .listen {
            speakerButton(question.item.spoken, size: 96)
        } else if question.promptIsArabic {
            VStack(spacing: 6) {
                ReadingArabic(text: style.draw(question.prompt, spaced: hintLevel >= 1), base: promptSize(question), style: .largeTitle, plain: style.plainFace)
                    .foregroundColor(accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(question.prompt.contains(" ") ? 4 : 1)
                    .minimumScaleFactor(0.3)
                    .frame(maxWidth: .infinity, minHeight: 96)

                // The unmarked tiers' second hint: the same word with its marks on.
                if hintLevel >= 2, let marked = question.item.marked {
                    ReadingArabic(text: ReadingTestText.display(marked, mushafMarks: mushafSukoon), base: 30, style: .title)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
            }
        } else {
            VStack(spacing: 8) {
                Text(question.prompt)
                    .font(.system(size: question.prompt.count > 22 ? 22 : 34, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, minHeight: 72)

                // A reading is easier to hold in the ear than in the eye, so it can be heard as well.
                if speech.isAvailable {
                    speakerButton(question.item.spoken, size: 44)
                }
            }
        }
    }

    private func promptSize(_ question: ReadingQuestion) -> CGFloat {
        if question.prompt.contains(" ") { return question.prompt.count > 40 ? 30 : 36 }
        return question.prompt.count > 14 ? 44 : 60
    }

    private func speakerButton(_ text: String, size: CGFloat) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            speech.speak(text)
        } label: {
            Image(systemName: speech.currentText == text ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: size, height: size)
                .background(Circle().fill(accent.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hear it")
    }

    // MARK: Hints

    @ViewBuilder
    private func hintRow(_ question: ReadingQuestion) -> some View {
        if question.skill == .build {
            hintButton("Place the next one for me", systemImage: "lightbulb") {
                placeNext(question)
            }
        } else if question.allowsHint, question.tier.display != .spaced {
            HStack(spacing: 8) {
                hintButton(hintLevel >= 1 ? "Joined Again" : "Hint: Letter by Letter", systemImage: hintLevel >= 1 ? "arrow.uturn.backward" : "lightbulb") {
                    if hintLevel >= 1 { hintLevel = 0 } else { useHint(level: 1) }
                }

                if case .letterByLetterThenMarks = question.tier.hint, question.item.marked != nil, question.promptIsArabic, hintLevel == 1 {
                    hintButton("Show the Tashkeel", systemImage: "lightbulb.fill") {
                        useHint(level: 2)
                    }
                }
            }
        }
    }

    private func hintButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { action() }
        } label: {
            ReadingIconText(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundColor(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(accent.opacity(0.12)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: long ? 1 : 2), spacing: 10) {
            ForEach(question.choices) { choice in
                choiceButton(choice, in: question, style: style, long: long)
            }
        }
        .padding(.vertical, 4)
    }

    private func choiceButton(_ choice: ReadingChoice, in question: ReadingQuestion, style: ReadingTextStyle, long: Bool) -> some View {
        let answered = chosen != nil
        let isAnswer = choice.id == question.answer
        let isWrongPick = chosen == choice.id && !isAnswer
        let stroke: Color = !answered ? .clear : isAnswer ? .green : isWrongPick ? .red : .clear

        return Button {
            guard chosen == nil else { return }
            Settings.shared.hapticFeedback()
            choose(choice.id, in: question)
        } label: {
            Group {
                if choice.isArabic {
                    // The joined-shapes tier's spelled-out choices are already letter by letter.
                    ReadingArabic(text: question.skill == .takeApart ? choice.text : style.draw(choice.text, spaced: hintLevel >= 1),
                                  base: long ? 26 : 32, style: .title, plain: style.plainFace)
                        .foregroundColor(accent)
                } else {
                    Text(choice.text)
                        .font(long ? .body.weight(.semibold) : .title3.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }
            .multilineTextAlignment(.center)
            .lineLimit(long ? 3 : 1)
            .minimumScaleFactor(0.45)
            .frame(maxWidth: .infinity, minHeight: long ? 52 : 64)
            .padding(.horizontal, 8)
            .padding(.vertical, long ? 6 : 0)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(answered && isAnswer ? 0.18 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(stroke, lineWidth: 2)
            )
            .opacity(answered && !isAnswer && !isWrongPick ? 0.45 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                    Text(question.tilesAreWords ? "Tap the words below" : "Tap the letters below")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    ReadingArabic(text: ReadingTestText.display(built, mushafMarks: mushafSukoon || question.tier.display == .mushaf),
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
                        ReadingArabic(text: ReadingTestText.display(tile.text, mushafMarks: mushafSukoon || question.tier.display == .mushaf),
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
                    buildControl("Undo", systemImage: "delete.left", enabled: !placed.isEmpty) {
                        placed.removeLast()
                    }

                    buildControl("Clear", systemImage: "xmark", enabled: !placed.isEmpty) {
                        placed.removeAll()
                    }

                    buildControl("Check", systemImage: "checkmark", enabled: !placed.isEmpty, filled: true) {
                        check(question)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func buildControl(_ title: String, systemImage: String, enabled: Bool, filled: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.15)) { action() }
        } label: {
            ReadingIconText(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(filled ? .white : accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(filled ? accent : accent.opacity(0.12))
                )
                .opacity(enabled ? 1 : 0.4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    // MARK: Read aloud

    @ViewBuilder
    private func aloudArea(_ question: ReadingQuestion) -> some View {
        VStack(spacing: 10) {
            if revealed {
                Text(question.tier.id == "waqf" ? question.item.stopped : question.item.reading)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if speech.isAvailable {
                    speakerButton(question.item.spoken, size: 44)
                }

                if chosen == nil {
                    Text("Did you read it that way?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        buildControl("Not Yet", systemImage: "xmark", enabled: true) {
                            chosen = 1
                            tally(false, question)
                        }

                        buildControl("I Read It Right", systemImage: "checkmark", enabled: true, filled: true) {
                            chosen = 0
                            tally(true, question)
                        }
                    }
                }
            } else {
                buildControl("Show the Reading", systemImage: "eye", enabled: true, filled: true) {
                    revealed = true
                    if speech.isAvailable { speech.speak(question.item.spoken) }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Feedback

    @ViewBuilder
    private func feedback(_ question: ReadingQuestion, style: ReadingTextStyle) -> some View {
        let wasRight = question.skill == .build ? buildRight == true : question.skill == .aloud ? chosen == 0 : chosen == question.answer
        let item = question.item

        VStack(alignment: .leading, spacing: 8) {
            ReadingIconText(wasRight ? (hintedThisQuestion ? "Right, with a hint" : "Right") : "Not quite",
                  systemImage: wasRight ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(wasRight ? .green : .red)

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(question.skill == .stop ? item.stopped : item.reading)
                        .font(.body.weight(.semibold))

                    if question.skill == .stop {
                        Text("Read on, it is \(item.reading).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if question.tier.id != "forms" {
                    // Joined, even on the letter-by-letter tier: this is where its words close up.
                    ReadingArabic(text: ReadingTestText.display(item.marked ?? item.arabic, mushafMarks: mushafSukoon || question.tier.display == .mushaf),
                                  base: 26, style: .title2, plain: style.plainFace && item.marked == nil)
                        .foregroundColor(accent)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .minimumScaleFactor(0.4)
                }

                if speech.isAvailable, question.tier.id != "forms" {
                    PracticeListenButton(text: item.spoken)
                }
            }

            if !item.sounded.isEmpty {
                soundedOut(item, style: style)
            }

            if let note = explanation(question) {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    /// The word a syllable at a time, each group of letters over how it is read: the answer's own
    /// working, shown whether the answer was right or not.
    private func soundedOut(_ item: ReadingItem, style: ReadingTextStyle) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 6) {
                ForEach(Array(item.sounded.enumerated()), id: \.offset) { _, part in
                    VStack(spacing: 2) {
                        ReadingArabic(text: ReadingTestText.display(part.arabic, mushafMarks: mushafSukoon || style.tier.display == .mushaf),
                                      base: 22, style: .title3)
                            .foregroundColor(accent)
                            .lineLimit(1)

                        Text(part.reading)
                            .font(.caption2.weight(.semibold))
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
        .accessibilityLabel("Sounded out: " + item.sounded.map(\.reading).joined(separator: ", "))
    }

    private func explanation(_ question: ReadingQuestion) -> String? {
        let item = question.item
        switch question.tier.id {
        case "letters", "harakat", "openers", "names", "everyday":
            return item.gloss
        case "forms":
            return "\(item.arabic) is \(item.reading), joined."
        case "ayat":
            guard let reference = item.reference, let gloss = item.gloss else { return nil }
            return "\(reference): \u{201C}\(gloss)\u{201D} (Saheeh International)"
        default:
            guard let reference = item.reference, let gloss = item.gloss, !gloss.isEmpty else { return nil }
            return "In the Quran (\(reference)) it means \u{201C}\(gloss)\u{201D}."
        }
    }

    // MARK: Running

    private func start() {
        var factory = ReadingQuestionFactory()
        factory.voiceAvailable = speech.isAvailable
        switch mode {
        case .test(let tier): questions = factory.round(for: tier)
        case .practice(let tier, let skill): questions = factory.round(for: tier, only: skill)
        case .review:
            let passed = ReadingTier.all.filter { progress.record(for: $0).passed }
            questions = factory.review(of: passed.isEmpty ? ReadingTier.all : passed)
        case .placement:
            placementIndex = 0
            questions = factory.placementPair(for: ReadingTier.all[0])
        }
        index = 0
        right = 0
        hints = 0
        streak = 0
        missed = []
        finished = questions.isEmpty
        placementResult = nil
        placementCleared = false
        resetQuestionState()
        speakCurrent()
    }

    private func resetQuestionState() {
        chosen = nil
        placed = []
        buildRight = nil
        revealed = false
        hintLevel = 0
        hintedThisQuestion = false
    }

    private func choose(_ id: Int, in question: ReadingQuestion) {
        chosen = id
        tally(id == question.answer, question)
    }

    private func tally(_ wasRight: Bool, _ question: ReadingQuestion) {
        if wasRight {
            right += 1
            streak += 1
        } else {
            streak = 0
            if !missed.contains(question.item) { missed.append(question.item) }
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
        let wasRight = questions.indices.contains(index)
            && (questions[index].skill == .build ? buildRight == true : chosen == questions[index].answer)
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
        switch mode {
        case .test(let tier):
            progress.finish(tier, right: right, of: questions.count, hints: hints)
        case .placement:
            if let placementResult { progress.setPlacement(placementResult) }
        case .practice, .review:
            break
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
                ForEach(missed, id: \.self) { item in
                    HStack(spacing: 12) {
                        Text(item.reading)
                            .font(.body.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        ReadingArabic(text: ReadingTestText.display(item.marked ?? item.arabic, mushafMarks: mushafSukoon),
                                      base: 24, style: .title2, plain: item.marked == nil && !item.arabic.unicodeScalars.contains(where: ReadingTestText.isMark))
                            .foregroundColor(accent)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .minimumScaleFactor(0.4)

                        if speech.isAvailable {
                            PracticeListenButton(text: item.spoken)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("LOOK AT THESE AGAIN")
            }
        }
    }

    private var scoreSection: some View {
        let total = questions.count
        let percent = total == 0 ? 0 : Int((Double(right) / Double(total) * 100).rounded())
        let passed = percent >= ReadingTestProgress.passMark
        let tier: ReadingTier? = { if case .test(let tier) = mode { return tier } else { return nil } }()
        let mastered = tier != nil && right == total && hints == 0

        return Section {
            VStack(spacing: 8) {
                Text("\(right) of \(total)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(accent)

                if tier != nil {
                    ReadingIconText(mastered ? "Mastered" : passed ? "Passed" : "Not passed yet",
                          systemImage: mastered ? "checkmark.seal.fill" : passed ? "checkmark.circle.fill" : "arrow.clockwise.circle")
                        .font(.headline)
                        .foregroundColor(passed ? accent : .secondary)
                }

                Text(resultMessage(passed: passed, mastered: mastered, isTest: tier != nil))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if hints > 0 {
                    ReadingIconText(hints == 1 ? "1 answer used a hint" : "\(hints) answers used a hint", systemImage: "lightbulb")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .listRowSeparator(.hidden)
            .id(Self.promptID)

            if let tier, passed, let next = tier.next {
                resultButton("Next Tier: \(next.title)", systemImage: "arrow.right.circle.fill", prominent: true) {
                    mode = .test(next)
                    start()
                }
            }

            resultButton(tier != nil && !passed ? "Try Again" : "Go Again", systemImage: "arrow.clockwise", prominent: tier != nil && !passed) {
                start()
            }

            resultButton("Back", systemImage: "chevron.backward", prominent: false) {
                dismiss()
            }
        } header: {
            Text("RESULTS")
        }
    }

    private func resultMessage(passed: Bool, mastered: Bool, isTest: Bool) -> String {
        if mastered { return "Every answer right, and no hints. This tier is yours." }
        if right == questions.count { return isTest ? "Every answer right. Do it once more without a hint to master the tier." : "Every one right." }
        if passed { return "That is a pass. The ones you missed are below." }
        return isTest ? "\(ReadingTestProgress.passMark)% passes. Look at the ones you missed, practise that skill on its own, and take it again."
            : "Look at the ones you missed, then go again."
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

                    Text(tier.number == 1 ? "Begin at the beginning. It goes quickly."
                         : "You read everything below it. This is the first tier that caught you, so it is where the ladder now starts for you.")
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
                resultButton("Take the Tier \(tier.number) Test", systemImage: "play.fill", prominent: true) {
                    mode = .test(tier)
                    start()
                }
            }

            resultButton("Back", systemImage: "chevron.backward", prominent: false) {
                dismiss()
            }
        } header: {
            Text("YOUR LEVEL")
        }
    }

    private func resultButton(_ title: String, systemImage: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            ReadingIconText(title, systemImage: systemImage)
                .font(.body.weight(.semibold))
                .foregroundColor(prominent ? .white : accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(prominent ? accent : accent.opacity(0.12))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
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
                .foregroundColor(appearance.accent)
                .frame(minWidth: letter == nil ? 96 : 34, alignment: .leading)

            if let letter {
                ReadingArabic(text: letter, base: 24, style: .title2)
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

// MARK: - The way in

/// The Reading Test's row on the Arabic Alphabet screen: what it is, and how far the learner is.
struct ReadingTestEntryLabel: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = ReadingTestProgress.shared

    /// The whole ladder in one word, taken from the bank and not typed: letter by letter, then
    /// joined, then with nothing on it. Reads from the right, so the arrows point the way it goes.
    private static let preview: String? = {
        guard let item = (ReadingTestBank.words["vowels"] ?? []).first(where: { $0.reading == "kataba" }) else { return nil }
        let word = ReadingTestText.display(item.arabic, mushafMarks: false)
        return "\(ReadingTestText.spaced(word))  \u{2190}  \(word)  \u{2190}  \(ReadingTestText.bare(word))"
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "text.book.closed.fill")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [appearance.accent.opacity(0.95), appearance.accent.opacity(0.65)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Reading Test")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)

                Text("\(ReadingTier.all.count) tiers, from single letters to words with no tashkeel")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if progress.passedCount > 0 {
                    ProgressView(value: Double(progress.passedCount), total: Double(ReadingTier.all.count))
                        .tint(appearance.accent)
                        .padding(.top, 2)

                    Text("\(progress.passedCount) of \(ReadingTier.all.count) passed")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(appearance.accent)
                } else if let preview = Self.preview {
                    Text(preview)
                        .font(.callout)
                        .foregroundColor(appearance.accent.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color.secondary.opacity(0.6))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reading Test. \(ReadingTier.all.count) tiers, from single letters to words with no tashkeel.")
    }
}
