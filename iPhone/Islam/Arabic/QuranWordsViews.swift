import SwiftUI

// Quran Words' screens: the five tiers, one tier's words, and the test that asks them. The model
// (the pack, the progress, the known marks, the quiz) is in QuranWords.swift; the pieces shared with
// the Reading Test and the Tajweed Test are in StudyKit.swift.

// MARK: - Formatting

enum QuranWordsFormat {
    /// "58.1%", in the reader's locale (its digits, its percent sign).
    static func percent(_ value: Double) -> String {
        (value / 100).formatted(.percent.precision(.fractionLength(1)))
    }

    /// The dictionary-word count to the nearest hundred ("about 4,800"): the exact figure depends on
    /// how a corpus draws the line between two words.
    static func roundedLemmas(_ count: Int) -> String {
        (Int((Double(count) / 100).rounded()) * 100).formatted()
    }
}

// MARK: - The tiers

struct QuranWordsView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = QuranWordsProgress.shared
    @ObservedObject private var known = QuranWordsKnown.shared

    @State private var vocabulary: QuranVocabulary? = QuranVocabularyStore.shared.ifLoaded
    @State private var session: QuranWordsSessionView.Mode?
    @State private var confirmReset = false

    #if DEBUG
    @State private var debugTier: QuranWordsTier?
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
                if let vocabulary {
                    heroSection(vocabulary)
                    tiersSection(vocabulary)
                    reviewSection(vocabulary)
                    numbersSection(vocabulary)
                    moreSection
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
        .navigationTitle("Quran Words")
        .navigationBarTitleDisplayMode(.inline)
        .openScreen(.quranWords)
        .task {
            guard let loaded = await QuranVocabularyStore.shared.loaded() else { return }
            if vocabulary == nil { vocabulary = loaded }
            if !progress.missed.isEmpty { progress.forgetUnlisted(in: loaded) }
            #if DEBUG
            fireDebugRoute(loaded)
            #endif
        }
        .pushDestination(isPresented: Binding(get: { session != nil }, set: { if !$0 { session = nil } })) {
            if let session, let vocabulary { QuranWordsSessionView(mode: session, vocabulary: vocabulary) }
        }
        .confirmationDialog("Reset your Quran Words progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                Settings.shared.hapticFeedback()
                withAnimation(.easeInOut) {
                    progress.reset()
                    if let vocabulary { known.unmark(vocabulary.words) }
                }
            }
        } message: {
            Text("Every tier goes back to not passed, every word loses its known mark, and the words kept for review are forgotten. This cannot be undone.")
        }
        #if DEBUG
        .debugPushDestination(isPresented: Binding(get: { debugTier != nil }, set: { if !$0 { debugTier = nil } })) {
            if let debugTier, let vocabulary { QuranWordsTierView(tier: debugTier, vocabulary: vocabulary) }
        }
        #endif
    }

    #if DEBUG
    /// `-quranWordsKnown <n>` marks the first n words known, `-quranWordsSeed <n>` passes the first n
    /// tiers, `-quranWordsTier <n>` pushes a tier, `-quranWordsTest <n>` starts its test: screenshots
    /// of a list in use, headlessly. Nothing is written for the seed; the known marks are real.
    private func fireDebugRoute(_ vocabulary: QuranVocabulary) {
        guard !debugRouteFired else { return }
        debugRouteFired = true
        if let count = Self.debugArgument("-quranWordsKnown").flatMap(Int.init) {
            known.mark(Array(vocabulary.words.prefix(count)))
        }
        if let seed = Self.debugArgument("-quranWordsSeed").flatMap(Int.init) {
            progress.debugSeed(passed: seed, in: vocabulary.tiers.map(\.id))
        }
        let tierNumber = { (name: String) in Self.debugArgument(name).flatMap(Int.init).flatMap { n in vocabulary.tiers.first { $0.number == n } } }
        if let tier = tierNumber("-quranWordsTier") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugTier = tier }
        } else if let tier = tierNumber("-quranWordsTest") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { session = .test(tier) }
        }
    }
    #endif

    // MARK: Sections

    private func heroSection(_ vocabulary: QuranVocabulary) -> some View {
        let totals = vocabulary.totals
        let knownCount = known.knownCount(in: vocabulary.words)
        let share = vocabulary.share(of: known.known)
        let hundred = vocabulary.milestones.first { $0.words == 100 }?.percent ?? vocabulary.share(of: vocabulary.words.prefix(100).map(\.key))
        let all = vocabulary.share(of: vocabulary.words.map(\.key))
        let passed = progress.passedCount(in: vocabulary.tiers)
        let next = progress.nextTier(in: vocabulary.tiers)
        let lemmas = QuranWordsFormat.roundedLemmas(totals.lemmas)
        return ResourceHeroSection(ResourceHero(
            eyebrow: String(localized: "QURAN WORDS"),
            systemImage: "character.book.closed.fill",
            headline: String(localized: "You do not need all \(lemmas) words"),
            message: String(localized: "The Quran's \(totals.words.formatted()) words come from about \(lemmas) dictionary words, and a few hundred of them carry most of it. The 100 most common make up \(QuranWordsFormat.percent(hundred)) of everything you recite; the \(vocabulary.words.count) here make up \(QuranWordsFormat.percent(all)). Learn them a hundred at a time."),
            stats: knownCount > 0 || passed > 0 ? [
                ResourceHeroStat("\(knownCount.formatted())", String(localized: "words known")),
                ResourceHeroStat(QuranWordsFormat.percent(share), String(localized: "of the Quran's words")),
                ResourceHeroStat("\(passed.formatted())", String(localized: "of \(vocabulary.tiers.count) tiers passed")),
            ] : []
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if knownCount > 0 {
                    // The bar runs to the whole Quran: what the known words cover of every word in it.
                    ProgressView(value: min(share, 100), total: 100)
                        .tint(accent)
                        .accessibilityLabel(Text("You know \(QuranWordsFormat.percent(share)) of the Quran's words"))
                }

                if let next {
                    StudyHeroButton(title: passed == 0 ? String(localized: "Start: \(next.title)") : String(localized: "Continue: \(next.title)"),
                                    systemImage: "play.fill", filled: true) {
                        session = .test(next)
                    }
                }
            }
        })
    }

    private func tiersSection(_ vocabulary: QuranVocabulary) -> some View {
        let next = progress.nextTier(in: vocabulary.tiers)
        return Section {
            ForEach(vocabulary.tiers) { tier in
                NavigationLink(destination: LazyDestination { QuranWordsTierView(tier: tier, vocabulary: vocabulary) }) {
                    StudyTierRow(number: tier.number, specimen: tier.words.first?.arabic,
                                 title: tier.title,
                                 summary: String(localized: "\(QuranWordsFormat.percent(vocabulary.share(of: tier))) of the Quran \u{00B7} \(known.knownCount(in: tier.words)) of \(tier.words.count) known"),
                                 record: progress.record(for: tier), isNext: next == tier)
                }
            }
        } header: {
            StudySectionHeader(String(localized: "THE WORDS"), systemImage: "list.number")
        } footer: {
            Text("Most common first. A tier's share counts each word of the Quran it stands for once: قَالَ stands for قَالُوا, يَقُولُ and قُلۡ too.")
        }
    }

    @ViewBuilder
    private func reviewSection(_ vocabulary: QuranVocabulary) -> some View {
        let missed = progress.missed.filter { vocabulary.word(key: $0.id) != nil }
        if !missed.isEmpty {
            Section {
                StudyActionRow(title: String(localized: "Practice Missed Words"), systemImage: "arrow.uturn.backward.circle",
                               caption: String(localized: "The words you missed in tier tests, until you get them right"),
                               detail: "\(missed.count)") {
                    session = .missed(nil)
                }
            } header: {
                StudySectionHeader(String(localized: "REVIEW"), systemImage: "arrow.triangle.2.circlepath")
            }
        }
    }

    private func numbersSection(_ vocabulary: QuranVocabulary) -> some View {
        Section {
            QuranWordsCoverageChart(vocabulary: vocabulary)
                .padding(.vertical, 6)

            QuranWordsFigures(totals: vocabulary.totals)
                .padding(.vertical, 4)

            ArticleDoorRow(door: .article("QuranWordsPillarView"))

            #if HAS_QURAN
            OpenScreenLink(screen: .tajweedRuleFrequency) {
                TajweedRuleFrequencyView()
            } label: {
                TajweedLinkLabel(systemImage: "chart.bar.fill", title: String(localized: "How Often Each Tajweed Rule Comes"),
                                 caption: String(localized: "The same pattern in tajweed: a few rules on every line"))
            }
            #endif
        } header: {
            StudySectionHeader(String(localized: "THE NUMBERS"), systemImage: "chart.bar")
        } footer: {
            Text("Counted with the Quranic Arabic Corpus, which lists every word of the Quran with its dictionary form and root. It counts \(vocabulary.totals.corpusWords.formatted()) words to this mushaf's \(vocabulary.totals.words.formatted()): it joins and splits a few words differently.")
        }
    }

    @ViewBuilder
    private var moreSection: some View {
        if !progress.records.isEmpty || !progress.missed.isEmpty || !known.known.isEmpty {
            Section {
                StudyActionRow(title: String(localized: "Reset Progress"), systemImage: "arrow.counterclockwise",
                               caption: String(localized: "Start the list again from nothing"), tint: .red, trailingSymbol: nil) {
                    confirmReset = true
                }
            } header: {
                StudySectionHeader(String(localized: "MORE"), systemImage: "ellipsis.circle")
            }
        }
    }
}

/// How much of the Quran the most common words make up, as bars: the 10, 50, 100 ... most common.
struct QuranWordsCoverageChart: View {
    @Environment(\.appearance) private var appearance

    let vocabulary: QuranVocabulary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The most common words, and how much of the Quran they make up")
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            ForEach(vocabulary.milestones, id: \.self) { milestone in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("The \(milestone.words) most common")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text(QuranWordsFormat.percent(milestone.percent))
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                            .foregroundColor(appearance.accent)
                    }
                    ProgressView(value: milestone.percent, total: 100)
                        .tint(appearance.accent)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// The counts behind the list, two to a row.
struct QuranWordsFigures: View {
    @Environment(\.appearance) private var appearance

    let totals: QuranVocabulary.Totals

    private struct Figure: Identifiable {
        let value: Int
        let label: String
        var id: String { label }
    }

    private var figures: [Figure] {
        [Figure(value: totals.words, label: String(localized: "words in the Quran")),
         Figure(value: totals.lemmas, label: String(localized: "dictionary words")),
         Figure(value: totals.roots, label: String(localized: "roots")),
         Figure(value: totals.usedOnce, label: String(localized: "dictionary words used only once"))]
    }

    var body: some View {
        SummaryTileGrid(columns: 2, spacing: 8) {
            ForEach(figures) { figure in
                VStack(alignment: .leading, spacing: 2) {
                    Text(figure.value.formatted())
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .foregroundColor(appearance.accent)
                    Text(figure.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(appearance.accent.opacity(0.08)))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - One tier

struct QuranWordsTierView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = QuranWordsProgress.shared
    @ObservedObject private var known = QuranWordsKnown.shared

    let tier: QuranWordsTier
    let vocabulary: QuranVocabulary

    @State private var studied: QuranWord?
    @State private var session: QuranWordsSessionView.Mode?

    var body: some View {
        let knownCount = known.knownCount(in: tier.words)
        let record = progress.record(for: tier)
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(QuranWordsFormat.percent(vocabulary.share(of: tier)))
                                .font(.largeTitle.weight(.bold))
                                .monospacedDigit()
                                .foregroundColor(appearance.accent)
                            Text("of the Quran's words")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text("These \(tier.words.count) words, with every form of each, make up this share of everything you recite. You know \(knownCount) of them.")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        ProgressView(value: Double(knownCount), total: Double(max(tier.words.count, 1)))
                            .tint(appearance.accent)
                    }
                    .padding(.vertical, 4)

                    StudyResultButton(title: record.passed ? String(localized: "Test This Tier Again") : String(localized: "Test This Tier"),
                                      systemImage: "play.fill", prominent: !record.passed) {
                        session = .test(tier)
                    }
                    .listRowSeparator(.hidden)

                    StudyResultButton(title: knownCount == tier.words.count ? String(localized: "Clear the Known Marks") : String(localized: "Mark All Known"),
                                      systemImage: knownCount == tier.words.count ? "circle" : "checkmark.circle") {
                        withAnimation(.easeInOut) {
                            if knownCount == tier.words.count { known.unmark(tier.words) } else { known.mark(tier.words) }
                        }
                    }
                    .listRowSeparator(.hidden)
                } header: {
                    HStack {
                        StudySectionHeader(tier.title.localizedUppercase, systemImage: "list.number")
                        Spacer()
                        StudyRecordBadge(record: record, isNext: false)
                    }
                } footer: {
                    Text("Passing the test (\(QuranWordsQuiz.size) questions, eight in ten right) marks every word you answered right as known.")
                }

                Section {
                    ForEach(tier.words) { word in
                        QuranWordRow(word: word, isKnown: known.contains(word)) {
                            studied = word
                        } toggleKnown: {
                            withAnimation(.easeInOut(duration: 0.2)) { known.toggle(word) }
                        }
                    }
                } header: {
                    StudySectionHeader(String(localized: "THE WORDS"), systemImage: "character.book.closed")
                } footer: {
                    Text("Tap a word to see it where it first comes in the Quran, with its root and every ayah it is in. The count is how many words of the Quran it appears in.")
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(tier.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $studied) { word in
            QuranWordStudySheet(word: word)
        }
        .pushDestination(isPresented: Binding(get: { session != nil }, set: { if !$0 { session = nil } })) {
            if let session { QuranWordsSessionView(mode: session, vocabulary: vocabulary) }
        }
        #if DEBUG
        // `-quranWordsStudy <rank>`: that word's Word Study card, as a tap on its row opens it.
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            guard let index = arguments.firstIndex(of: "-quranWordsStudy"), arguments.indices.contains(index + 1),
                  let rank = Int(arguments[index + 1]), let word = tier.words.first(where: { $0.rank == rank }) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { studied = word }
        }
        #endif
    }
}

/// One word of a tier: its rank, meaning, root and count, the Arabic, and the known mark. Two
/// borderless buttons, so a tap on the mark never opens the word.
struct QuranWordRow: View {
    @Environment(\.appearance) private var appearance

    let word: QuranWord
    let isKnown: Bool
    let open: () -> Void
    let toggleKnown: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                Settings.shared.hapticFeedback()
                open()
            } label: {
                HStack(spacing: 10) {
                    Text("\(word.rank)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 26, alignment: .leading)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(word.meaning)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            if !word.root.isEmpty {
                                Text(word.root)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(appearance.accent)
                                    .environment(\.layoutDirection, .rightToLeft)
                            } else if word.isPronoun {
                                Text("Pronoun")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(appearance.accent)
                            }
                            Text("\(word.uses) times")
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(word.arabic)
                        .font(Font.arabic(appearance.quranDisplayFace, size: 28))
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .foregroundColor(isKnown ? appearance.accent : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(word.arabic), \(word.meaning), \(word.uses) times"))
            .accessibilityHint(Text("Opens the word in the Quran"))

            Button {
                Settings.shared.hapticFeedback()
                toggleKnown()
            } label: {
                Image(systemName: isKnown ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isKnown ? appearance.accent : .secondary.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(isKnown ? "Known" : "Not marked known"))
            .accessibilityHint(Text(isKnown ? "Removes the known mark" : "Marks the word known"))
        }
        .padding(.vertical, 2)
    }
}

/// The Word Study card on a word's first occurrence, opened on its Root page (every ayah the root
/// is in). Hafs, whatever riwayah the reader shows: the list is counted on Hafs.
struct QuranWordStudySheet: View {
    let word: QuranWord

    var body: some View {
        if let surah = QuranData.shared.surah(word.surah),
           let ayah = QuranData.shared.ayah(surah: word.surah, ayah: word.ayah) {
            let tokens = WordTokens.tokens(in: ayah.rawArabicText(surahId: word.surah, qiraahOverride: ""))
            // `total` is the RAW token count, so the card reads `position` as a raw index (ornaments
            // counted), which is what the pack stores.
            WordMeaningSheet(surah: surah, ayah: ayah,
                             word: tokens.indices.contains(word.token) ? tokens[word.token] : word.arabic,
                             meaning: "", position: word.token + 1, total: tokens.count,
                             startTab: word.root.isEmpty ? .meaning : .root)
                .environmentObject(Settings.shared)
        } else {
            Text("The Quran is still loading. Try again in a moment.")
                .foregroundStyle(.secondary)
                .padding()
                .smallMediumSheetPresentation()
        }
    }
}

// MARK: - The test

struct QuranWordsSessionView: View {
    enum Mode: Equatable {
        case test(QuranWordsTier)
        /// These missed words, or the whole missed bank when nil.
        case missed([String]?)
    }

    @Environment(\.appearance) private var appearance
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var progress = QuranWordsProgress.shared
    @ObservedObject private var known = QuranWordsKnown.shared

    let vocabulary: QuranVocabulary

    @State private var mode: Mode
    @State private var questions: [QuranWordsQuestion] = []
    @State private var index = 0
    @State private var chosen: Int?
    @State private var right = 0
    @State private var streak = 0
    @State private var missed: [QuranWord] = []
    @State private var answeredRight: [QuranWord] = []
    @State private var finished = false
    @State private var newlyKnown = 0
    @State private var studied: QuranWord?

    init(mode: Mode, vocabulary: QuranVocabulary) {
        _mode = State(initialValue: mode)
        self.vocabulary = vocabulary
    }

    private var title: String {
        switch mode {
        case .test(let tier): return tier.title
        case .missed: return String(localized: "Practice Missed Words")
        }
    }

    private var tier: QuranWordsTier? {
        if case .test(let tier) = mode { return tier }
        return nil
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
            .onChange(of: scrollCue) { cue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(cue.hasSuffix("answered") ? Self.nextID : Self.promptID, anchor: cue.hasSuffix("answered") ? .bottom : .top)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if questions.isEmpty, !finished { start() } }
        .sheet(item: $studied) { word in
            QuranWordStudySheet(word: word)
        }
    }

    private static let promptID = "quranWordsPrompt"
    private static let nextID = "quranWordsNext"

    private var scrollCue: String {
        "\(index)-\(finished ? "finished" : chosen != nil ? "answered" : "asking")"
    }

    // MARK: Asking

    @ViewBuilder
    private func questionSections(_ question: QuranWordsQuestion) -> some View {
        let answered = chosen != nil
        Section {
            VStack(spacing: 8) {
                Text(question.word.arabic)
                    .font(Font.arabic(appearance.quranDisplayFace, size: 48))
                    .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                    .foregroundColor(appearance.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 4)

                Text(question.word.isPronoun ? "What does this pronoun mean?" : "What does this word mean?")
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .id(Self.promptID)
        } header: {
            StudyQuestionHeader(title: String(localized: "QUESTION \(index + 1) OF \(questions.count)"), streak: streak)
        }

        Section {
            let long = question.choices.contains { $0.count > 18 }
            SummaryTileGrid(columns: long ? 1 : 2) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { choiceIndex, choice in
                    StudyChoiceButton(state: StudyChoiceState(answered: answered, isAnswer: choiceIndex == question.answer, picked: chosen == choiceIndex),
                                      long: long) {
                        choose(choiceIndex, in: question)
                    } label: {
                        Text(choice)
                            .font(long ? .subheadline.weight(.semibold) : .headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityLabel(choice)
                }
            }
            .padding(.vertical, 4)

            if answered {
                feedback(question)

                StudyAdvanceButton(title: index + 1 == questions.count ? String(localized: "See Results") : String(localized: "Next")) {
                    advance()
                }
                .id(Self.nextID)
            }
        }
    }

    private func feedback(_ question: QuranWordsQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StudyVerdictLine(wasRight: chosen == question.answer)

            Text("\(question.word.arabic) means \u{201C}\(question.word.meaning)\u{201D}. It is in \(question.word.uses) words of the Quran.")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Settings.shared.hapticFeedback()
                studied = question.word
            } label: {
                StudyIconText(String(localized: "See It in the Quran"), systemImage: "book")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appearance.accent)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    // MARK: Running

    private func start() {
        index = 0
        right = 0
        streak = 0
        missed = []
        answeredRight = []
        newlyKnown = 0
        chosen = nil
        switch mode {
        case .test(let tier):
            questions = QuranWordsQuiz.round(for: tier, all: vocabulary.words)
        case .missed(let keys):
            let wanted = keys ?? progress.missed.map(\.id)
            let words = wanted.compactMap(vocabulary.word(key:))
            questions = QuranWordsQuiz.review(of: Array(words.prefix(20)), vocabulary: vocabulary)
        }
        finished = questions.isEmpty
    }

    private func choose(_ choice: Int, in question: QuranWordsQuestion) {
        guard chosen == nil else { return }
        chosen = choice
        if choice == question.answer {
            right += 1
            streak += 1
            if !answeredRight.contains(question.word) { answeredRight.append(question.word) }
        } else {
            streak = 0
            if !missed.contains(question.word) { missed.append(question.word) }
        }
    }

    private func advance() {
        if index + 1 >= questions.count {
            finish()
        } else {
            chosen = nil
            index += 1
        }
    }

    private func finish() {
        let total = questions.count
        switch mode {
        case .test(let tier):
            progress.finish(tier, right: right, of: total, missed: missed, answeredRight: answeredRight)
            if progress.record(for: tier).passed, total > 0,
               Int((Double(right) / Double(total) * 100).rounded()) >= QuranWordsProgress.passMark {
                let fresh = answeredRight.filter { !known.contains($0) }
                newlyKnown = fresh.count
                known.mark(fresh)
            }
        case .missed:
            let pairs = { (words: [QuranWord]) -> [(id: String, tier: String)] in
                words.compactMap { word in vocabulary.tier(of: word).map { (id: word.key, tier: $0.id) } }
            }
            progress.finishReview(missedIDs: pairs(missed), rightIDs: pairs(answeredRight))
        }
        withAnimation(.easeInOut) { finished = true }
        AppReviewManager.shared.noteFinishedRun(correct: right, attempts: total)
    }

    // MARK: Results

    @ViewBuilder
    private var resultsSections: some View {
        let total = questions.count
        let percent = total == 0 ? 0 : Int((Double(right) / Double(total) * 100).rounded())
        let passed = percent >= QuranWordsProgress.passMark
        let outcome: StudyOutcome? = tier == nil || total == 0 ? nil : right == total ? .mastered : passed ? .passed : .failed
        let nextTier = tier.flatMap { current in vocabulary.tiers.first { $0.number == current.number + 1 } }

        Section {
            StudyScoreCard(right: right, total: total, outcome: outcome,
                           message: total == 0 ? String(localized: "Nothing is waiting for review.")
                               : StudyScoreCard.message(right: right, total: total, outcome: outcome, passMark: QuranWordsProgress.passMark))
                .id(Self.promptID)

            if newlyKnown > 0 {
                StudyIconText(newlyKnown == 1 ? String(localized: "1 word marked known") : String(localized: "\(newlyKnown) words marked known"),
                              systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            }

            if tier != nil, passed, let nextTier {
                StudyResultButton(title: String(localized: "Next: \(nextTier.title)"), systemImage: "arrow.forward.circle.fill", prominent: true) {
                    mode = .test(nextTier)
                    start()
                }
            }

            if !missed.isEmpty {
                StudyResultButton(title: String(localized: "Practice What You Missed"), systemImage: "arrow.uturn.backward.circle",
                                  prominent: tier != nil && !passed) {
                    mode = .missed(missed.map(\.key))
                    start()
                }
            }

            if total > 0 {
                StudyResultButton(title: tier != nil && !passed ? String(localized: "Try Again") : String(localized: "Go Again"),
                                  systemImage: "arrow.clockwise", prominent: tier != nil && !passed && missed.isEmpty) {
                    start()
                }
            }

            StudyResultButton(title: String(localized: "Back"), systemImage: "chevron.backward") {
                dismiss()
            }
        } header: {
            StudySectionHeader(String(localized: "RESULTS"), systemImage: "chart.bar")
        }

        if !missed.isEmpty {
            Section {
                ForEach(missed) { word in
                    QuranWordRow(word: word, isKnown: known.contains(word)) {
                        studied = word
                    } toggleKnown: {
                        withAnimation(.easeInOut(duration: 0.2)) { known.toggle(word) }
                    }
                }
            } header: {
                StudySectionHeader(String(localized: "LOOK AT THESE AGAIN"), systemImage: "eye")
            } footer: {
                if tier != nil {
                    Text("These words are kept under Practice Missed Words until you answer them right.")
                }
            }
        }
    }
}
