#if os(iOS)
import SwiftUI

// One lesson of the tajweed course (TajweedCourse.swift), drawn in Tilawa's design (Abu, 2026-09-23:
// "I like his design style more"): a hero card, then one card per beat in the order a teacher gives
// them, each headed by an icon in the lesson's colour. The colour is the reader's own colour for the
// rule the lesson teaches (ikhfa green, qalqalah blue), and the app's accent where there is none.
//
//   what it is  ->  when it fires  ->  what it looks like  ->  the letters  ->  why  ->  in words  ->
//   what to remember  ->  what goes wrong  ->  drill it  ->  hear it  ->  watch it  ->  test yourself
//   ->  where it sits on the alphabet  ->  what to read next
//
// Every block is optional except the explanation, so a lesson with no rule card or no drills simply
// renders fewer cards. The Al-Islam blocks merged in from Tajweed Foundations (word lists, videos,
// diagrams, letter families, article doors, stop signs) sit among Tilawa's where they teach.
//
// Previous and Next replace the lesson in place rather than pushing (Tilawa's rule: the back button
// goes to the course, not back through every lesson stepped through), and the list scrolls to the top.

// MARK: - Lesson

struct TajweedLessonDetailView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var progress = TajweedLessonProgress.shared

    @State private var lesson: TajweedLesson
    /// The letter a tile asked to open. Tiles share List rows, so the List owns the one destination.
    @State private var door: ArabicDoor?
    @State private var showLegend = false

    private static let topID = "lesson-top"

    init(lesson: TajweedLesson) {
        _lesson = State(initialValue: lesson)
    }

    private var accent: Color { lesson.accent(fallback: appearance.accent) }

    private var arabicFont: Font {
        Font.arabic(appearance.quranDisplayFace, size: CGFloat(appearance.fontArabicSize))
    }

    var body: some View {
        let _ = RenderCounter.hit("TajweedLessonDetailView")
        ScrollViewReader { proxy in
            List {
                Group {
                    if shows("hero") { heroSection }
                    if shows("rule") { ruleSection }
                    if shows("definition") { definitionSection }
                    if shows("images") { imagesSection }
                    if shows("letters") { lettersSection }
                    if shows("explanation") { explanationSection }
                    if shows("words") { wordsSection }
                    if shows("keypoints") { keyPointsSection }
                    if shows("table") { tableSection }
                    if shows("extras") { extrasSection }
                    if shows("mistakes") { mistakesSection }
                    if shows("drills") { drillsSection }
                    if shows("examples") { examplesSection }
                    if shows("videos") { videosSection }
                    if shows("quiz") { quizSection }
                    if shows("families") { familiesSection }
                    if shows("next") { readNextSection }
                    if shows("step") { stepSection }
                }
                .themedListRowBackground()
            }
            .selectableArticleList(disableNowPlayingInset: true)
            .onChange(of: lesson.id) { _ in
                withAnimation(appearance.reduceAnimations ? nil : .easeInOut(duration: 0.25)) {
                    proxy.scrollTo(Self.topID, anchor: .top)
                }
            }
        }
        .arabicDoorDestination($door)
        .openScreen(.tajweedLesson, id: lesson.id)
        .navigationTitle(lesson.titleEn.localizedDisplay)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let position = TajweedLessonsStore.shared.position(of: lesson.id) {
                    Text("Lesson \(position.number) of \(position.total)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                let neighbors = TajweedLessonsStore.shared.neighbors(of: lesson.id)
                Button {
                    step(to: neighbors.previous)
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .disabled(neighbors.previous == nil)
                .accessibilityLabel("Previous lesson")

                Button {
                    step(to: neighbors.next)
                } label: {
                    Image(systemName: "chevron.forward")
                }
                .disabled(neighbors.next == nil)
                .accessibilityLabel("Next lesson")
            }
        }
        .sheet(isPresented: $showLegend) {
            NavigationView {
                TajweedLegendView()
            }
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
    }

    #if DEBUG
    /// `-tajweedLessonOnly <cards>`: only those cards (comma-separated: hero, rule, definition, images,
    /// letters, explanation, words, keypoints, table, extras, mistakes, drills, examples, videos, quiz,
    /// families, next, step), so a screenshot reaches the lower ones: nothing here can scroll the
    /// simulator.
    private static let debugOnly: Set<String>? = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-tajweedLessonOnly"), args.indices.contains(idx + 1) else { return nil }
        return Set(args[idx + 1].split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) })
    }()
    #endif

    private func shows(_ card: String) -> Bool {
        #if DEBUG
        return Self.debugOnly?.contains(card) ?? true
        #else
        return true
        #endif
    }

    private func step(to other: TajweedLesson?) {
        guard let other else { return }
        Settings.shared.hapticFeedback()
        lesson = other
    }

    // MARK: Hero

    /// The lesson's `ResourceHero` (Abu, 2026-10-03: overviews "pretty like pillars and beliefs"): the
    /// chapter as the eyebrow, the title with its Arabic beside it, the transliteration under the title
    /// (the hero's small accent line), the summary, and Done and the reading time as the footer. Worn in
    /// the lesson's colour like every other card on the page.
    private var heroSection: some View {
        let tint = accent
        let done = progress.isDone(lesson.id)
        return Section {
            ResourceHero(
                eyebrow: (TajweedLessonsStore.shared.chapter(of: lesson.id)?.title.localizedDisplay ?? String(localized: "Tajweed")).uppercased(),
                systemImage: "graduationcap.fill",
                headline: lesson.titleEn.localizedDisplay,
                arabic: lesson.titleAr.isEmpty ? nil : lesson.titleAr,
                source: lesson.translit.isEmpty ? nil : lesson.translit,
                message: lesson.summary.localizedDisplay
            ) {
                if done || lesson.minutes > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        if done {
                            Label("Done", systemImage: "checkmark.circle.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(tint)
                        }

                        Spacer(minLength: 8)

                        if lesson.minutes > 0 {
                            Text("\(lesson.minutes) min")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .transformEnvironment(\.appearance) { $0.accent = tint }
            .id(Self.topID)
            .articleCardRow()
        }
    }

    // MARK: The rule

    @ViewBuilder
    private var ruleSection: some View {
        if let card = lesson.ruleCard {
            Section(header: TajweedLessonHeader(systemImage: "arrow.triangle.branch", title: String(localized: "The Rule"),
                                                subtitle: String(localized: "What sets it off, what you do, how long you hold it."),
                                                accent: accent)) {
                VStack(alignment: .leading, spacing: 13) {
                    if !card.countEn.isEmpty {
                        Text(card.countEn.localizedDisplay)
                            .font(.caption.weight(.heavy))
                            .foregroundColor(accent)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(accent.opacity(0.13)))
                    }
                    if !card.trigger.isEmpty { ruleLine(String(localized: "When"), card.trigger.localizedDisplay, systemImage: "arrow.triangle.branch") }
                    if !card.action.isEmpty { ruleLine(String(localized: "Do"), card.action.localizedDisplay, systemImage: "ear") }
                    if !card.hold.isEmpty { ruleLine(String(localized: "Hold"), card.hold.localizedDisplay, systemImage: "timer") }
                    if !card.mnemonicArabic.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            TajweedCapsLabel(String(localized: "Memorize it with"))
                            Text(card.mnemonicArabic)
                                .font(arabicFont)
                                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                .foregroundColor(accent)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                // On the right, as Arabic sits, in either interface.
                                .environment(\.layoutDirection, .leftToRight)
                            if !card.mnemonicGloss.isEmpty {
                                Text(card.mnemonicGloss.localizedDisplay)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.secondary.opacity(0.08)))
                    }
                }
                .padding(.vertical, 6)

                if !card.fragments.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(card.fragments) { fragment in
                            HStack(alignment: .center, spacing: 12) {
                                if !fragment.caption.isEmpty {
                                    Text(fragment.caption.localizedDisplay)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                // A Quran fragment shows the ayah's words from the app's own text.
                                Text(fragment.arabic(in: quranData))
                                    .font(Font.arabic(appearance.quranDisplayFace, size: 22))
                                    .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                    .foregroundColor(accent)
                                    .multilineTextAlignment(.trailing)
                                    .environment(\.layoutDirection, .leftToRight)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.secondary.opacity(0.08)))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func ruleLine(_ label: String, _ text: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundColor(accent)
                .frame(width: 26, height: 26)
                .background(Circle().fill(accent.opacity(0.12)))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                TajweedCapsLabel(label)
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: The word itself

    @ViewBuilder
    private var definitionSection: some View {
        if let definition = lesson.definition {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    TajweedCapsLabel(String(localized: "The word itself"))
                    Text(definition.termAr)
                        .font(Font.arabic(appearance.quranDisplayFace, size: 32))
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .foregroundColor(accent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .leftToRight)
                        // The mushaf faces' tall line box left the term floating under a band of air.
                        .padding(.vertical, appearance.quranUsesCustomArabicFace ? -10 : 0)
                    if !definition.literal.isEmpty {
                        labeled(String(localized: "Literally"), definition.literal.localizedDisplay)
                        Divider()
                    }
                    if !definition.technical.isEmpty {
                        labeled(String(localized: "In tajweed"), definition.technical.localizedDisplay)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func labeled(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            TajweedCapsLabel(label)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: How it looks (the Foundations diagrams)

    @ViewBuilder
    private var imagesSection: some View {
        if !lesson.images.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "square.stack.3d.up", title: String(localized: "How It Looks"),
                                                subtitle: String(localized: "Tap a diagram to see it full screen."), accent: accent)) {
                ForEach(lesson.images) { image in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(image.name)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focusableImage(image.name, title: (image.caption.isEmpty ? lesson.titleEn : image.caption).localizedDisplay)
                        if !image.caption.isEmpty {
                            Text(image.caption.localizedDisplay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: The letters

    @ViewBuilder
    private var lettersSection: some View {
        if !lesson.letterSets.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "character.book.closed.ar",
                                                title: lesson.letterSets.allSatisfy(\.isWords) ? String(localized: "The Words") : String(localized: "The Letters"),
                                                subtitle: lesson.letterSets.contains(where: { !$0.isWords })
                                                    ? String(localized: "Tap a letter to open its page.") : nil,
                                                accent: accent)) {
                ForEach(lesson.letterSets) { set in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(set.label.localizedDisplay)
                                .font(.subheadline.weight(.bold))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("\(set.letters.count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .hiddenInSimple(.sectionCounts)
                        }
                        if !set.note.isEmpty {
                            TajweedNoteText(text: set.note)
                        }
                        TajweedLetterTiles(set: set, accent: accent) { door = .letter($0) }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: Explanation

    private var explanationSection: some View {
        Section(header: TajweedLessonHeader(systemImage: "book", title: String(localized: "Explanation"), accent: accent)) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(lesson.body.enumerated()), id: \.offset) { _, paragraph in
                    SelectableProse(text: paragraph.localizedDisplay)
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: In words (the Foundations word lists)

    @ViewBuilder
    private var wordsSection: some View {
        if !lesson.words.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "character.textbox.ar", title: String(localized: "In Words"),
                                                subtitle: String(localized: "Read each one aloud, then check it against its reading."),
                                                accent: accent)) {
                ForEach(lesson.words) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        TajweedCapsLabel(group.label.localizedDisplay)
                        if !group.note.isEmpty {
                            Text(group.note.localizedDisplay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, word in
                            if index > 0 { Divider() }
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(word.translit)
                                        .font(.subheadline)
                                        .leftToRightContent()
                                        .fixedSize(horizontal: false, vertical: true)
                                    if !word.note.isEmpty {
                                        Text(word.note.localizedDisplay)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                Spacer(minLength: 12)
                                Text(word.arabic(in: quranData))
                                    .font(Font.arabic(appearance.quranDisplayFace, size: 23))
                                    .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                    .multilineTextAlignment(.trailing)
                                    .environment(\.layoutDirection, .leftToRight)
                                    .layoutPriority(1)
                                    // The mushaf faces carry a very tall line box; trim it so a list of
                                    // words reads as a list rather than a column of islands.
                                    .padding(.vertical, appearance.quranUsesCustomArabicFace ? -5 : 0)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: Worth remembering

    @ViewBuilder
    private var keyPointsSection: some View {
        if !lesson.keyPoints.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    TajweedCapsLabel(String(localized: "Worth remembering"))
                    ForEach(Array(lesson.keyPoints.enumerated()), id: \.offset) { _, point in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(accent)
                            Text(point.localizedDisplay)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Table

    @ViewBuilder
    private var tableSection: some View {
        if let table = lesson.table {
            Section {
                TajweedLessonTableView(table: table, accent: accent)
                    .padding(.vertical, 4)
            }
        }
    }

    // MARK: Extras

    @ViewBuilder
    private var extrasSection: some View {
        if lesson.extras.contains(.waqfSigns) {
            Section(header: TajweedLessonHeader(systemImage: "hand.raised", title: String(localized: "Stop Signs"),
                                                subtitle: String(localized: "What each sign above the line asks of you."), accent: accent),
                    footer: Text("These signs guide the meaning, not your breathing.")) {
                QuranSignsSectionContent(accentColor: accent)
                    .padding(.vertical, 4)
            }
        }
    }

    // MARK: Common mistakes

    @ViewBuilder
    private var mistakesSection: some View {
        if !lesson.mistakes.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "exclamationmark.circle", title: String(localized: "Common Mistakes"), accent: accent)) {
                ForEach(lesson.mistakes) { mistake in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            TajweedPill(text: String(localized: "Instead of"), color: .red)
                            Text(mistake.wrong.localizedDisplay)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            TajweedPill(text: String(localized: "Do this"), color: .green)
                            Text(mistake.right.localizedDisplay)
                                .font(.subheadline.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !mistake.why.isEmpty {
                            Text(mistake.why.localizedDisplay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    // MARK: Practice patterns

    @ViewBuilder
    private var drillsSection: some View {
        if !lesson.drills.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "checklist", title: String(localized: "Practice Patterns"),
                                                subtitle: String(localized: "Build the movement before you meet it inside an ayah."),
                                                accent: accent)) {
                ForEach(Array(lesson.drills.enumerated()), id: \.element.id) { index, drill in
                    VStack(alignment: .leading, spacing: 10) {
                        if !drill.caption.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                TajweedNumberBadge(number: index + 1, accent: accent)
                                Text(drill.caption.localizedDisplay)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        // A Quran drill shows the ayah's words from the app's own text (empty until the
                        // Quran loads, like the example rows).
                        let arabic = drill.arabic(in: quranData)
                        VStack(spacing: 4) {
                            if !arabic.isEmpty {
                                Text(arabic)
                                    .font(Font.arabic(appearance.quranDisplayFace, size: 26))
                                    .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                                    .multilineTextAlignment(.center)
                            }
                            if !drill.translit.isEmpty {
                                Text(drill.translit)
                                    .font(.caption)
                                    .leftToRightContent()
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.secondary.opacity(0.08)))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: In the mushaf

    @ViewBuilder
    private var examplesSection: some View {
        if !lesson.examples.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "headphones", title: String(localized: "In the Mushaf"),
                                                subtitle: String(localized: "Real ayahs, recited by your reciter. Tap play and listen for the words in the box."),
                                                accent: accent)) {
                if let count = lesson.ruleCode.flatMap({ TajweedLessonsStore.shared.courseIfLoaded?.ruleCounts[$0] }),
                   count.ayahs > 0 {
                    Label("This rule occurs in \(count.ayahs.formatted()) ayahs of the mushaf.", systemImage: "text.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(lesson.examples) { example in
                    TajweedExampleCard(example: example, accent: accent)
                }
            }
        }
    }

    // MARK: Watch

    @ViewBuilder
    private var videosSection: some View {
        if !lesson.videos.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "play.rectangle", title: String(localized: "Watch"), accent: accent)) {
                ForEach(lesson.videos) { video in
                    Link(destination: video.url) {
                        HStack(spacing: 12) {
                            AccentIconChip(systemImage: "play.fill", tint: .red, size: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(video.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                // Explicit greys: inside a Link the hierarchical styles take the link's tint.
                                Text(video.channel.isEmpty ? "YouTube" : String(localized: "\(video.channel), on YouTube"))
                                    .font(.caption)
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: Check yourself

    @ViewBuilder
    private var quizSection: some View {
        let chapterTest = chapterTest
        if !lesson.quiz.isEmpty || chapterTest != nil {
            Section(header: TajweedLessonHeader(systemImage: "target", title: String(localized: "Check Yourself"),
                                                subtitle: lesson.quiz.isEmpty ? nil : String(localized: "Answer from the lesson, not from a guess."), accent: accent)) {
                if !lesson.quiz.isEmpty {
                    TajweedQuizCards(questions: lesson.quiz, accent: accent)
                        // A new lesson starts with a clean sheet.
                        .id(lesson.id)
                }

                // The chapter's scored test (TajweedTestViews.swift): ten questions built from every
                // lesson of the chapter, this one among them.
                if let chapterTest {
                    NavigationLink(destination: LazyDestination { TajweedTestTierView(tier: chapterTest.tier, tiers: chapterTest.tiers) }) {
                        SettingsRowLabel(
                            title: String(localized: "Test This Chapter"),
                            systemImage: "checkmark.seal.fill",
                            subtitle: chapterTest.tier.lessons.count == 1 ? String(localized: "A scored test on \(chapterTest.tier.title)")
                                : String(localized: "A scored test on \(chapterTest.tier.title): \(chapterTest.tier.lessons.count) lessons"),
                            tint: accent,
                            subtitleLineLimit: 2
                        )
                    }
                }
            }
        }
    }

    /// The chapter this lesson sits in, as a tier of the Tajweed Test, once the course is parsed (it is,
    /// by the time a lesson is on screen).
    private var chapterTest: (tier: TajweedTestTier, tiers: [TajweedTestTier])? {
        guard let course = TajweedLessonsStore.shared.courseIfLoaded,
              let chapter = TajweedLessonsStore.shared.chapter(of: lesson.id) else { return nil }
        let tiers = TajweedTestLadder.tiers(in: course)
        guard let tier = tiers.first(where: { $0.id == chapter.id }) else { return nil }
        return (tier, tiers)
    }

    // MARK: On the alphabet

    @ViewBuilder
    private var familiesSection: some View {
        let families = lesson.families
        if !families.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "textformat.size.ar", title: String(localized: "On the Alphabet"), accent: accent),
                    footer: Text("Each family opens its letters, the phrase that gathers them, and every letter's own page.")) {
                ForEach(families) { family in
                    LetterFamilyLink(family: family) {
                        LetterTraitRow(
                            systemImage: family.systemImage,
                            tint: family.legendColor,
                            title: family.title,
                            arabic: family.arabic,
                            caption: family.summary,
                            letters: family.letters
                        )
                    }
                }
            }
        }
    }

    // MARK: Read next

    @ViewBuilder
    private var readNextSection: some View {
        let related = lesson.related.compactMap { TajweedLessonsStore.shared.lesson(id: $0) }
        if !related.isEmpty || !lesson.doors.isEmpty {
            Section(header: TajweedLessonHeader(systemImage: "arrow.turn.down.right", title: String(localized: "Read Next"), accent: accent)) {
                ForEach(related) { other in
                    Button {
                        step(to: other)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(other.titleEn.localizedDisplay)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(TajweedLessonsStore.shared.chapter(of: other.id)?.title.localizedDisplay ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            if progress.isDone(other.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(accent)
                            }
                            Image(systemName: "chevron.forward")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                ForEach(lesson.doors) { door in
                    TajweedDoorRow(door: door, showLegend: $showLegend)
                }
            }
        }
    }

    // MARK: Previous, next, done

    private var stepSection: some View {
        let neighbors = TajweedLessonsStore.shared.neighbors(of: lesson.id)
        return Section {
            HStack(spacing: 10) {
                neighborButton(neighbors.previous, label: String(localized: "Previous"), systemImage: "chevron.backward", leading: true)
                neighborButton(neighbors.next, label: String(localized: "Next"), systemImage: "chevron.forward", leading: false)
            }
            .padding(.vertical, 4)

            Button {
                Settings.shared.hapticFeedback()
                progress.toggle(lesson.id)
            } label: {
                HStack {
                    Spacer()
                    Label(progress.isDone(lesson.id) ? String(localized: "Marked as Done") : String(localized: "Mark as Done"),
                          systemImage: progress.isDone(lesson.id) ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
            }
            .foregroundColor(accent)
        }
    }

    private func neighborButton(_ other: TajweedLesson?, label: String, systemImage: String, leading: Bool) -> some View {
        Button {
            step(to: other)
        } label: {
            VStack(alignment: leading ? .leading : .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    if leading { Image(systemName: systemImage) }
                    Text(label.uppercased())
                        .tracking(0.6)
                    if !leading { Image(systemName: systemImage) }
                }
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.secondary)

                Text(other?.titleEn.localizedDisplay ?? " ")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(leading ? .leading : .trailing)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: leading ? .leading : .trailing)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.secondary.opacity(0.08)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(other == nil)
        .opacity(other == nil ? 0.4 : 1)
    }
}

// MARK: - Pieces

/// A section's heading in the lesson: an icon in the lesson's colour, the title, and a line under it.
/// A lesson's stage header: the study kit's `StudyStageHeader` (the Reading Test and the Tajweed
/// Test draw theirs with it) in the lesson's own colour. One header for every learning page, so a
/// lesson and the test that follows it read as one course (2026-10-26).
struct TajweedLessonHeader: View {
    let systemImage: String
    let title: String
    var subtitle: String? = nil
    let accent: Color

    var body: some View {
        StudyStageHeader(systemImage: systemImage, title: title, blurb: subtitle, tint: accent)
    }
}

/// The small tracked capitals the cards label their parts with ("WHEN", "LITERALLY").
struct TajweedCapsLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.heavy))
            .tracking(0.8)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// "INSTEAD OF" / "DO THIS".
private struct TajweedPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .heavy))
            .tracking(0.5)
            .foregroundColor(color)
            .fixedSize()
            .frame(minWidth: 70)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}

private struct TajweedNumberBadge: View {
    let number: Int
    let accent: Color

    var body: some View {
        Text("\(number)")
            .font(.caption2.weight(.heavy))
            .monospacedDigit()
            .foregroundColor(accent)
            .frame(width: 20, height: 20)
            .background(Circle().fill(accent.opacity(0.13)))
    }
}

/// A letter set's note: Arabic ones (a mnemonic like خُصَّ ضَغۡطٍ قِظۡ) in the Quran face, English ones
/// as a caption.
private struct TajweedNoteText: View {
    @Environment(\.appearance) private var appearance
    let text: String

    private var isArabicOnly: Bool {
        text.containsArabicScript && !text.contains(where: { $0.isASCII && $0.isLetter })
    }

    var body: some View {
        if isArabicOnly {
            Text(text)
                .font(Font.arabic(appearance.quranDisplayFace, size: 20))
                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .leftToRight)
        } else {
            Text(text.localizedDisplay)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A letter set's tiles. Letters of the alphabet are the alphabet's own tiles, each opening its letter's
/// page (the Foundations pages' rule: Abu, 2026-09-20); marks and whole words are plain tiles.
private struct TajweedLetterTiles: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.openScreenInstances) private var openInstances

    let set: TajweedLessonLetterSet
    let accent: Color
    let onOpen: (LetterData) -> Void

    var body: some View {
        if set.isWords {
            FlowLayoutView(spacing: 7) {
                ForEach(Array(set.letters.enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .font(Font.arabic(appearance.quranDisplayFace, size: 18))
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .foregroundColor(set.emphasis ? accent : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(accent.opacity(set.emphasis ? 0.12 : 0.06)))
                }
            }
            .padding(.vertical, 2)
        } else {
            // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height on
            // each self-sizing pass, which iOS 26 traps on.
            SummaryTileGrid(adaptiveMinimum: 58, spacing: 8) {
                ForEach(Array(set.letters.enumerated()), id: \.offset) { _, glyph in
                    if let letter = LetterTraits.letterData(for: glyph) {
                        let open = openInstances.contains(OpenScreenInstance(screen: .arabicLetter, id: glyph))
                        Button {
                            guard !open else { return }
                            Settings.shared.hapticFeedback()
                            onOpen(letter)
                        } label: {
                            LetterGlyphTile(letter: letter, isDimmed: open, tint: set.emphasis ? accent : nil)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(open ? String(localized: "You are already on this letter's page") : String(localized: "Opens the letter"))
                    } else {
                        // A mark (a sukoon, a tanween shape) or a sign: drawn on a tatweel so a lone
                        // combining mark has a stroke to sit on.
                        Text(Self.displayable(glyph))
                            .font(Font.arabic(appearance.quranDisplayFace, size: 26))
                            .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                            .foregroundColor(set.emphasis ? accent : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(accent.opacity(set.emphasis ? 0.12 : 0.06)))
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    /// A mark on its own leans on a tatweel.
    static func displayable(_ glyph: String) -> String {
        guard let first = glyph.unicodeScalars.first,
              first.properties.generalCategory == .nonspacingMark else { return glyph }
        return "\u{0640}" + glyph
    }
}

/// A comparison table: title, column heads, rows; the first column in the lesson's colour.
private struct TajweedLessonTableView: View {
    @Environment(\.appearance) private var appearance
    let table: TajweedLessonTable
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(table.title.isEmpty ? String(localized: "At a glance") : table.title.localizedDisplay)
                .font(.subheadline.weight(.heavy))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)

            HStack(alignment: .top, spacing: 10) {
                ForEach(Array(table.columns.enumerated()), id: \.offset) { _, column in
                    Text(column.localizedDisplay.uppercased())
                        .font(.system(size: 9.5, weight: .heavy))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, 8)

            ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                Divider()
                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(row.enumerated()), id: \.offset) { index, cell in
                        cellView(cell, first: index == 0)
                    }
                }
                .padding(.vertical, 9)
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: String, first: Bool) -> some View {
        let arabicOnly = cell.containsArabicScript && !cell.contains(where: { $0.isASCII && $0.isLetter })
        if arabicOnly {
            Text(TajweedLetterTiles.displayable(cell))
                .font(Font.arabic(appearance.quranDisplayFace, size: 19))
                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                .foregroundColor(first ? accent : .primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(cell.localizedDisplay)
                .font(first ? .caption.weight(.bold) : .caption)
                .foregroundColor(first ? accent : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One of the app's screens a lesson points to ("What are the 10 Qiraat?").
struct TajweedDoorRow: View {
    @Environment(\.appearance) private var appearance
    let door: TajweedLessonDoor
    @Binding var showLegend: Bool

    private var label: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: door.systemImage, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(door.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(door.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    var body: some View {
        switch door {
        case .tajweedLegend:
            Button {
                Settings.shared.hapticFeedback()
                showLegend = true
            } label: {
                HStack {
                    label
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .tajweedArticle:
            // The article links back to the Tajweed Course: the pair is a corridor.
            OpenScreenLink(screen: .tajweedArticle) {
                TajweedView()
            } label: {
                label
            }
        case .quranArticle:
            NavigationLink(destination: LazyDestination { QuranPillarView() }) { label }
        case .ahrufArticle:
            NavigationLink(destination: LazyDestination { AhrufView() }) { label }
        case .qiraatArticle:
            NavigationLink(destination: LazyDestination { QiraatView() }) { label }
        case .letterFamilies:
            OpenScreenLink(screen: .letterFamilies) {
                LetterFamiliesView()
            } label: {
                label
            }
        case .soundAlikes:
            NavigationLink(destination: LazyDestination { SoundAlikeLettersView() }) { label }
        case .makharijShelf:
            GuardedScreenLink(screen: .letterFamilies, id: "makhraj") {
                LetterFamiliesView(title: String(localized: "Makharij"), axes: [.makhraj, .exit])
                    .openScreen(.letterFamilies, id: "makhraj")
            } label: {
                label
            }
        case .sifaatShelf:
            GuardedScreenLink(screen: .letterFamilies, id: "sifaat") {
                LetterFamiliesView(title: String(localized: "Sifaat"), axes: LetterAxis.Shelf.qualities.axes)
                    .openScreen(.letterFamilies, id: "sifaat")
            } label: {
                label
            }
        }
    }
}

// MARK: - Examples

/// One example ayah: its reference and a play button, the words to listen at lifted out of it, the
/// ayah itself in the reader's tajweed colours, its translation, what to listen for, and a way into
/// the Quran at that ayah.
private struct TajweedExampleCard: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var nowPlaying = QuranPlayer.shared.nowPlaying

    let example: TajweedLessonExample
    let accent: Color

    private var isThisAyah: Bool {
        nowPlaying.currentSurahNumber == example.surahId && nowPlaying.currentAyahNumber == example.ayahNumber
    }

    private var isPlayingThis: Bool { isThisAyah && nowPlaying.isPlaying && !nowPlaying.isPaused }

    var body: some View {
        if let surah = quranData.surah(example.surahId),
           let ayah = surah.ayahs.first(where: { $0.id == example.ayahNumber }) {
            let text = ayah.rawArabicText(surahId: surah.id, qiraahOverride: "")
            let word = example.words(in: text)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(isPlayingThis ? accent : .secondary)
                            TajweedCapsLabel(String(localized: "Example"))
                        }
                        .font(.caption2)
                        Text("\(surah.nameTransliteration) \u{00B7} \(example.surahId):\(example.ayahNumber)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        togglePlayback()
                    } label: {
                        Image(systemName: isPlayingThis ? "pause.fill" : "play.fill")
                            .font(.body.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(accent))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPlayingThis ? String(localized: "Pause example") : String(localized: "Play example"))
                }

                // The words the lesson points at, lifted out of the ayah by the pack's span, so a
                // learner can find them by eye before pressing play.
                if !word.isEmpty {
                    Text(word)
                        .font(Font.arabic(appearance.quranDisplayFace, size: 26))
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .foregroundColor(accent)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(accent.opacity(0.12)))
                }

                // The rule's colours are the whole point here, so the example paints its tajweed
                // regardless of the reader's own toggle: off the main thread, plain for a frame.
                TajweedExampleText(surah: example.surahId, ayah: example.ayahNumber, text: text,
                                   fontName: appearance.quranDisplayFace, size: CGFloat(appearance.fontArabicSize))

                if let translation = translation(of: ayah) {
                    Text(translation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .leftToRightContent()
                }

                if !example.focus.isEmpty {
                    Divider()
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "ear")
                            .font(.caption.weight(.bold))
                            .foregroundColor(accent)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(accent.opacity(0.12)))
                        VStack(alignment: .leading, spacing: 3) {
                            TajweedCapsLabel(String(localized: "Listen for"))
                            Text(example.focus.localizedDisplay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Divider()
                Button {
                    Settings.shared.hapticFeedback()
                    AppNavigation.shared.open(.ayah(example.surahId, example.ayahNumber))
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "book")
                        Text("Open in the Quran")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundColor(appearance.accent)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
        }
    }

    private func togglePlayback() {
        Settings.shared.hapticFeedback()
        let player = QuranPlayer.shared
        if isPlayingThis {
            player.pause()
        } else if isThisAyah && nowPlaying.isPaused {
            player.resume()
        } else {
            player.playAyah(surahNumber: example.surahId, ayahNumber: example.ayahNumber)
        }
    }

    /// The reader's English translation (Hafs text, whatever the reader shows).
    private func translation(of ayah: Ayah) -> String? {
        let settings = Settings.shared
        let text = (settings.showEnglishSaheeh || !settings.showEnglishMustafa) ? ayah.textEnglishSaheeh : ayah.textEnglishMustafa
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// One example ayah, its tajweed painted on a detached task (the paint is pure and its caches are
/// `NSCache`s, the readers' `paintOffMain` rule): the row renders plain for a frame and coloured on the
/// next, instead of running the cluster analysis in its body on the main thread.
private struct TajweedExampleText: View {
    let surah: Int
    let ayah: Int
    let text: String
    let fontName: String
    let size: CGFloat

    @State private var styled: AttributedString?

    var body: some View {
        Group {
            if let styled {
                Text(styled)
            } else {
                Text(text)
            }
        }
        .font(.custom(fontName, size: size))
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
    }
}

// MARK: - Quiz

/// The lesson's self-check, every question at once (Tilawa's design): pick an answer and the right
/// one is shown either way, with the reason. Once every question is answered, the score and a way to
/// try again. Nothing is stored: the questions exist to tell you whether the lesson landed.
struct TajweedQuizCards: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.layoutDirection) private var layoutDirection
    /// A question about a real ayah shows its words from the app's own text.
    @ObservedObject private var quranData = QuranData.shared

    let questions: [TajweedQuizQuestion]
    let accent: Color

    @State private var answers: [Int: Int] = [:]

    private var correct: Int {
        questions.indices.filter { answers[$0] == questions[$0].answer }.count
    }

    var body: some View {
        ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
            questionCard(question, index: index)
        }
        if answers.count == questions.count {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(correct) of \(questions.count) right")
                    .font(.title3.weight(.heavy))
                    .foregroundColor(accent)
                Text(correct == questions.count ? String(localized: "Every one. On to the next lesson.")
                     : correct * 2 >= questions.count ? String(localized: "Most of it is there. Read the rule once more, then try again.")
                     : String(localized: "Worth another pass through the lesson before moving on."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Settings.shared.hapticFeedback()
                    withAnimation(appearance.reduceAnimations ? nil : .easeInOut) { answers = [:] }
                } label: {
                    Label("Try Again", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }

    private func questionCard(_ question: TajweedQuizQuestion, index: Int) -> some View {
        let chosen = answers[index]
        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                TajweedNumberBadge(number: index + 1, accent: accent)
                Text(question.prompt.localizedDisplay)
                    .font(.subheadline.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            let arabic = question.arabic(in: quranData)
            if !arabic.isEmpty {
                Text(arabic)
                    .font(Font.arabic(appearance.quranDisplayFace, size: 25))
                    .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.secondary.opacity(0.08)))
            }
            VStack(spacing: 7) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { choiceIndex, choice in
                    choiceButton(choice, index: choiceIndex, question: question, questionIndex: index, chosen: chosen)
                }
            }
            if let chosen {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text(chosen == question.answer ? String(localized: "CORRECT") : String(localized: "NOT QUITE"))
                        .font(.caption2.weight(.heavy))
                        .tracking(0.7)
                        .foregroundColor(chosen == question.answer ? .green : .red)
                    Text(question.explain.localizedDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func choiceButton(_ choice: String, index: Int, question: TajweedQuizQuestion, questionIndex: Int, chosen: Int?) -> some View {
        let answered = chosen != nil
        let isAnswer = index == question.answer
        let wrongPick = answered && chosen == index && !isAnswer
        let reveal = answered && isAnswer
        let tint: Color? = reveal ? .green : (wrongPick ? .red : nil)
        // A choice that is Arabic ("Which of these has a moon lam?") is read in the mushaf face, from
        // the right, at the size the lesson's other Arabic is.
        let isArabic = choice.containsArabicScript && !choice.contains(where: { $0.isASCII && $0.isLetter })
        return Button {
            guard answers[questionIndex] == nil else { return }
            Settings.shared.hapticFeedback()
            withAnimation(appearance.reduceAnimations ? nil : .easeOut(duration: 0.18)) {
                answers[questionIndex] = index
            }
        } label: {
            HStack(spacing: 10) {
                if isArabic {
                    // On the right, as Arabic sits: that is the leading side in a right-to-left interface.
                    let rightToLeft = layoutDirection == .rightToLeft
                    if !rightToLeft { Spacer(minLength: 0) }
                    Text(choice)
                        .font(Font.arabic(appearance.quranDisplayFace, size: 23))
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .foregroundColor(tint ?? .primary)
                        .multilineTextAlignment(rightToLeft ? .leading : .trailing)
                        .padding(.vertical, appearance.quranUsesCustomArabicFace ? -5 : 0)
                    if rightToLeft { Spacer(minLength: 0) }
                } else {
                    Text(choice.localizedDisplay)
                        .font(.subheadline.weight(tint == nil ? .regular : .bold))
                        .foregroundColor(tint ?? .primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                if reveal {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.heavy))
                        .foregroundColor(.green)
                } else if wrongPick {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.heavy))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill((tint ?? accent).opacity(tint == nil ? 0.07 : 0.14)))
            .opacity(answered && !reveal && !wrongPick ? 0.55 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(answered)
        .accessibilityHint(answered ? (isAnswer ? String(localized: "The correct answer") : "") : String(localized: "Choose this answer"))
    }
}
#endif
