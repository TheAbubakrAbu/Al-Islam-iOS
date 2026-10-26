import SwiftUI

// The Tajweed Course: the course's home (TajweedCourse.swift).
//
// On 2026-09-23 Al-Islam's fourteen Tajweed Foundations pages and the course Jamil Hammoudeh wrote for
// Tilawa were merged lesson by lesson into one course, in the course's design (Scripts/
// tajweed_foundations.py maps every topic to its lessons), and for ten days this screen was called
// Tajweed Foundations. Abu, 2026-10-03, brought the reference back as its own resource
// (TajweedFoundations.swift) and kept this as the Tajweed Course, with everything the merge put in it.
// This screen is the course's index in Tilawa's layout: what the course is, the quick references,
// then the four stages, each holding its chapters, each holding its lessons, and the articles it
// points to at the end.
//
// The phone draws the full index and lessons (TajweedLessons.swift); the watch reads the same pack
// with a compact index and lesson page, below.

#if os(iOS)
struct TajweedCourseView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = TajweedLessonProgress.shared
    @ObservedObject private var testProgress = TajweedTestProgress.shared

    /// The course, parsed off the main thread in the task below (500 KB); a spinner stands in until
    /// it lands.
    @State private var course: TajweedLessonsStore.Course? = TajweedLessonsStore.shared.courseIfLoaded
    @State private var showTajweedLegend = false
    @State private var searchText = ""
    @State private var barsCollapsed = false

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Each lesson's folded search key (both titles, the transliteration, the summary, the key points
    /// and the rule code), by lesson id. The lessons come off a pack parsed after the screen appears,
    /// so there is no static index to build at launch: a key is folded the first time its lesson is
    /// searched and kept, so a keystroke pays for 58 dictionary lookups, never 58 folds. The store
    /// parses the course once and keeps it, so the keys never go stale. Locked the way
    /// `SettingsSearch.foldedByID` is.
    private static let searchKeysLock = NSLock()
    nonisolated(unsafe) private static var searchKeys: [String: String] = [:]

    private static func searchKey(for lesson: TajweedLesson) -> String {
        searchKeysLock.lock()
        if let key = searchKeys[lesson.id] { searchKeysLock.unlock(); return key }
        searchKeysLock.unlock()
        let english = [lesson.titleEn, lesson.titleAr, lesson.translit, lesson.summary, lesson.ruleCode ?? ""] + lesson.keyPoints
        // The title and summary as a translated interface shows them, after the English, where they differ.
        let shown = [lesson.titleEn.localizedDisplay, lesson.summary.localizedDisplay].filter { !english.contains($0) }
        let key = IslamArticles.fold((english + shown).joined(separator: " "))
        searchKeysLock.lock(); searchKeys[lesson.id] = key; searchKeysLock.unlock()
        return key
    }

    /// Every term has to hit, the rule the Prophecies and Miracles indexes search by.
    private func results(in lessons: [TajweedLesson]) -> [TajweedLesson] {
        let terms = IslamArticles.fold(query).split(separator: " ").map(String.init)
        guard !terms.isEmpty else { return [] }
        let matched = lessons.filter { lesson in
            let key = Self.searchKey(for: lesson)
            return terms.allSatisfy { key.contains($0) }
        }
        return SearchRank.sorted(matched, by: query) { lesson in
            [lesson.titleEn, lesson.titleAr, lesson.translit] + [lesson.titleEn.localizedDisplay].filter { $0 != lesson.titleEn }
        }
    }

    #if DEBUG
    /// `-openTajweedLesson <id>`: that lesson pushed as the course appears, for screenshots.
    @State private var debugOpenLesson = false
    /// `-tajweedTest`: the Tajweed Test ladder pushed as the course appears.
    @State private var debugOpenTest = false
    private static var debugLessonID: String? {
        guard let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-openTajweedLesson"),
              ProcessInfo.processInfo.arguments.indices.contains(idx + 1) else { return nil }
        return ProcessInfo.processInfo.arguments[idx + 1]
    }
    #endif

    private var accent: Color { appearance.accent }

    #if DEBUG
    /// `-tajweedIndexOnly <parts>`: only those parts of the index (overview, reference, stages,
    /// learnmore), so a screenshot reaches the chapter cards.
    private static let debugOnly: Set<String>? = {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-tajweedIndexOnly"), args.indices.contains(idx + 1) else { return nil }
        return Set(args[idx + 1].split(separator: ",").map(String.init))
    }()
    #endif

    private func shows(_ part: String) -> Bool {
        #if DEBUG
        return Self.debugOnly?.contains(part) ?? true
        #else
        return true
        #endif
    }

    var body: some View {
        let _ = RenderCounter.hit("TajweedCourseView")
        let lessons = course?.lessons ?? []
        let numbers = Dictionary(lessons.enumerated().map { ($1.id, $0 + 1) }, uniquingKeysWith: { first, _ in first })

        List {
            Group {
                if query.isEmpty {
                    if shows("overview") { overviewSection(lessons: lessons) }

                    if course != nil, shows("test") { testSection }

                    if course == nil, TajweedLessonsStore.isBundled { loadingSection }

                    if shows("reference") { referenceSection }

                    if let course, shows("stages") {
                        ForEach(Array(course.stages.enumerated()), id: \.element.id) { stageIndex, stage in
                            let chapters = course.chapters.filter { $0.stage == stage.id }
                            ForEach(Array(chapters.enumerated()), id: \.element.id) { chapterIndex, chapter in
                                chapterSection(chapter, numbers: numbers,
                                               stage: chapterIndex == 0 ? (stage: stage, number: stageIndex + 1) : nil)
                            }
                        }

                        // Chapters whose stage the pack does not name still list.
                        let known = Set(course.stages.map(\.id))
                        ForEach(course.chapters.filter { !known.contains($0.stage) }) { chapter in
                            chapterSection(chapter, numbers: numbers, stage: nil)
                        }
                    }

                    if shows("learnmore") { learnMoreSection }

                    Section(footer:
                        Text("Curriculum by Jamil Hammoudeh for Tilawa, used with permission, merged lesson by lesson with Al-Islam's Tajweed Foundations. Hafs an Asim, by the way of ash-Shatibiyyah. Example ayahs play in your chosen reciter.")
                            .font(.caption2)
                    ) { EmptyView() }
                } else if course == nil, TajweedLessonsStore.isBundled {
                    // Typed before the pack landed: the spinner, not "no lessons match".
                    loadingSection
                } else {
                    let matches = results(in: lessons)
                    if matches.isEmpty {
                        Section {
                            Text("No lessons match \"\(query)\".")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(header: SectionPillHeader(title: String(localized: "LESSONS"), count: matches.count)) {
                            ForEach(matches) { lessonLink($0, number: numbers[$0.id]) }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        // NO `article:` here: that adds the per-page "Search this article" bar, and this screen is an
        // INDEX with its own lesson search below (two stacked search bars).
        .selectableArticleList()
        .navigationTitle("Tajweed Course")
        .openScreen(.tajweedCourse)
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                      placeholder: String(localized: "Search lessons"))
                .minimizedBarStyle(barsCollapsed)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        // Same off-main parse the lessons do: parsing the pack in the body stalled first open.
        .task {
            guard course == nil, TajweedLessonsStore.isBundled else { return }
            course = await Task.detached(priority: .userInitiated) { TajweedLessonsStore.shared.course() }.value
        }
        .sheet(isPresented: $showTajweedLegend) {
            NavigationView {
                TajweedLegendView()
            }
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
        #if DEBUG
        // The hook sits on the List itself: a hook on a lesson row only fires once that lazy row
        // scrolls into view.
        .debugPushDestination(isPresented: $debugOpenLesson) {
            if let id = Self.debugLessonID {
                TajweedLessonScreen(lessonID: id)
            }
        }
        .debugPushDestination(isPresented: $debugOpenTest) {
            TajweedTestView()
        }
        .onAppear {
            if Self.debugLessonID != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugOpenLesson = true }
            } else if ProcessInfo.processInfo.arguments.contains("-tajweedTest") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugOpenTest = true }
            }
        }
        #endif
    }

    // MARK: What the course is

    /// The course's opening card (`ResourceHero`), then where to pick up once a lesson is done.
    @ViewBuilder
    private func overviewSection(lessons: [TajweedLesson]) -> some View {
        let doneCount = lessons.filter { progress.isDone($0.id) }.count
        let minutes = lessons.reduce(0) { $0 + $1.minutes }
        // Where to pick up: the first lesson in course order not yet marked done.
        let next = doneCount > 0 ? lessons.first(where: { !progress.isDone($0.id) }) : nil

        ResourceHeroSection(ResourceHero(
            eyebrow: String(localized: "LEARN TAJWEED"),
            systemImage: "graduationcap.fill",
            headline: String(localized: "Recite the Qur\u{2019}an with measured recitation."),
            source: String(localized: "Quran 73:4"),
            message: String(localized: "One course for all of tajweed, Hafs an Asim by the way of ash-Shatibiyyah, taught in the classical order: read the letters, shape them, apply the rules, then read the mushaf. Every lesson explains its rule, shows it in real ayahs you can play, gives you words and patterns to practise, and ends with a self-check."),
            stats: lessons.isEmpty ? [] : [
                ResourceHeroStat(lessons.count.formatted(), String(localized: "lessons")),
                ResourceHeroStat((course?.chapters.count ?? 0).formatted(), String(localized: "chapters")),
                ResourceHeroStat(Self.duration(minutes), String(localized: "in all")),
            ]
        ) {
            if doneCount > 0, !lessons.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: Double(doneCount), total: Double(max(1, lessons.count)))
                        .tint(accent)
                    Text("\(doneCount) of \(lessons.count) lessons done")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(accent)
                }
            }
        })

        if let next {
            Section {
                NavigationLink(destination: LazyDestination { TajweedLessonDetailView(lesson: next) }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CONTINUE")
                                .font(.caption2.weight(.heavy))
                                .tracking(0.7)
                                .foregroundStyle(.secondary)
                            Text(next.titleEn.localizedDisplay)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private static func duration(_ minutes: Int) -> String {
        guard minutes >= 90 else { return String(localized: "\(minutes) minutes") }
        let hours = (Double(minutes) / 60).rounded()
        return String(localized: "\(Int(hours)) hours")
    }

    // MARK: Test yourself

    /// The Tajweed Test (TajweedTestViews.swift): one scored test per chapter, built from the lessons.
    /// Its row shows the ladder's progress once there is some.
    @ViewBuilder
    private var testSection: some View {
        let tiers = course.map(TajweedTestLadder.tiers(in:)) ?? []
        let passed = testProgress.passedCount(in: tiers)
        Section(header: Text("TEST YOURSELF")) {
            NavigationLink(destination: LazyDestination { TajweedTestView() }) {
                HStack(spacing: 12) {
                    AccentIconChip(systemImage: "checkmark.seal.fill", size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tajweed Test")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(passed > 0 ? String(localized: "\(passed) of \(tiers.count) chapters passed")
                             : String(localized: "A scored test for every chapter, built from its lessons"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if passed > 0 {
                        Text("\(passed)/\(tiers.count)")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: Quick reference

    /// The tools that sit beside the course rather than inside a lesson: Tajweed Foundations (every
    /// rule on a page of its own, to look up), the reader's colour legend, and the alphabet's two
    /// indexes of the letters tajweed is about.
    private var referenceSection: some View {
        Section(header: Text("QUICK REFERENCE")) {
            // Foundations links back here, so the row greys out when it is already on the stack.
            OpenScreenLink(screen: .tajweedFoundations) {
                TajweedFoundationsView()
            } label: {
                HStack(spacing: 12) {
                    AccentIconChip(systemImage: "waveform", size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tajweed Foundations")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("Every rule on a page of its own, to look up")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                Settings.shared.hapticFeedback()
                showTajweedLegend = true
            } label: {
                HStack(spacing: 12) {
                    AccentIconChip(systemImage: "paintpalette.fill", size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tajweed Legend")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("Every rule the Quran reader colors, for Hafs an Asim")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Tajweed is about letters before it is about rules, so the alphabet's own index of them
            // is offered here too: where each is made, how it sounds, which rules it triggers.
            NavigationLink(destination: LazyDestination { LetterFamiliesView() }) {
                ArabicTopicLinkLabel(
                    specimen: "ص",
                    title: String(localized: "Letter Families"),
                    caption: String(localized: "Every letter by makhraj, sifaat and rule, in Arabic and English"),
                    preview: "الهَمس  الصَّفِير  القَلقَلَة  الغُنَّة"
                )
            }

            NavigationLink(destination: LazyDestination { SoundAlikeLettersView() }) {
                ArabicTopicLinkLabel(
                    specimen: "ذظ",
                    title: String(localized: "Sound-Alike Letters"),
                    caption: String(localized: "The pairs people mix up, side by side, with what separates them")
                )
            }
        }
    }

    // MARK: Stages and chapters

    /// One chapter as one card: its title, its lesson count and what it covers, then a numbered row
    /// per lesson. The first chapter of a stage carries the stage above it.
    private func chapterSection(_ chapter: TajweedLessonChapter, numbers: [String: Int],
                                stage: (stage: TajweedCourseStage, number: Int)?) -> some View {
        Section(header: stageHeader(stage)) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(chapter.title.localizedDisplay)
                        .font(.headline.weight(.heavy))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text(chapter.lessons.count == 1 ? String(localized: "1 lesson") : String(localized: "\(chapter.lessons.count) lessons"))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                if !chapter.subtitle.isEmpty {
                    Text(chapter.subtitle.localizedDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)

            ForEach(chapter.lessons) { lesson in
                lessonLink(lesson, number: numbers[lesson.id])
            }
        }
    }

    /// A lesson's row and its page: the chapter cards and the search results share it, so a result
    /// opens the lesson the way its chapter does.
    private func lessonLink(_ lesson: TajweedLesson, number: Int?) -> some View {
        NavigationLink(destination: LazyDestination { TajweedLessonDetailView(lesson: lesson) }) {
            lessonRow(lesson, number: number)
        }
    }

    /// The spinner that stands in for the course until the pack is parsed.
    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func stageHeader(_ stage: (stage: TajweedCourseStage, number: Int)?) -> some View {
        if let stage {
            VStack(alignment: .leading, spacing: 3) {
                Text("STAGE \(stage.number)")
                    .font(.caption2.weight(.heavy))
                    .tracking(0.7)
                    .foregroundColor(Color(.secondaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(stage.stage.titleEn.localizedDisplay)
                        .font(.title3.weight(.heavy))
                        .foregroundColor(.primary)
                    Spacer(minLength: 8)
                    Text(stage.stage.titleAr)
                        .font(Font.arabic(appearance.quranDisplayFace, size: 18))
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .foregroundColor(accent)
                }
                if !stage.stage.blurb.isEmpty {
                    Text(stage.stage.blurb.localizedDisplay)
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .textCase(nil)
            .padding(.top, 14)
            .padding(.bottom, 4)
        }
    }

    /// One lesson: its number in the course (a check once it is done), its title, and its Arabic name.
    private func lessonRow(_ lesson: TajweedLesson, number: Int?) -> some View {
        let done = progress.isDone(lesson.id)
        return HStack(spacing: 12) {
            Group {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(lesson.accent(fallback: accent))
                } else {
                    Text(number.map { String($0).localizedDigits } ?? "")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 26)

            // The English title is what the row is for: it takes the width first, and the Arabic name
            // shrinks beside it rather than pushing it onto a second line.
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
        .accessibilityElement(children: .combine)
        .accessibilityValue(done ? String(localized: "Done") : "")
    }

    // MARK: Learn more

    private var learnMoreSection: some View {
        Section(header: Text("LEARN MORE"),
                footer: Text("Also in Al-Islam, under Pillars & Beliefs.")) {
            ForEach([TajweedLessonDoor.tajweedArticle, .quranArticle, .ahrufArticle, .qiraatArticle]) { door in
                TajweedDoorRow(door: door, showLegend: $showTajweedLegend)
            }
        }
    }
}
#endif

#if os(watchOS)
/// The course on the watch: the stages as sections, a row per lesson.
struct TajweedCourseView: View {
    @ObservedObject private var progress = TajweedLessonProgress.shared
    @State private var course: TajweedLessonsStore.Course? = TajweedLessonsStore.shared.courseIfLoaded

    var body: some View {
        List {
            if let course {
                ForEach(course.stages) { stage in
                    let chapters = course.chapters.filter { $0.stage == stage.id }
                    if !chapters.isEmpty {
                        Section(header: Text(stage.titleEn.localizedDisplay)) {
                            ForEach(chapters) { chapter in
                                ForEach(chapter.lessons) { lesson in
                                    NavigationLink(destination: LazyDestination { TajweedLessonWatchView(lesson: lesson) }) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 4) {
                                                if progress.isDone(lesson.id) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(.accentColor)
                                                }
                                                Text(lesson.titleEn.localizedDisplay)
                                                    .font(.footnote.weight(.semibold))
                                            }
                                            Text(chapter.title.localizedDisplay)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if TajweedLessonsStore.isBundled {
                ProgressView()
            } else {
                Text("The tajweed course is not available on this watch.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Tajweed Course")
        .task {
            guard course == nil, TajweedLessonsStore.isBundled else { return }
            course = await Task.detached(priority: .userInitiated) { TajweedLessonsStore.shared.course() }.value
        }
    }
}

/// One lesson on the watch: the text of it, beat by beat. Examples and drills stay on the phone.
struct TajweedLessonWatchView: View {
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var progress = TajweedLessonProgress.shared
    let lesson: TajweedLesson

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.titleEn.localizedDisplay)
                        .font(.headline)
                    if !lesson.titleAr.isEmpty {
                        Text(lesson.titleAr)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    if !lesson.summary.isEmpty {
                        Text(lesson.summary.localizedDisplay)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let definition = lesson.definition {
                Section(header: Text("The Word Itself")) {
                    Text(definition.termAr)
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        // On the right, as Arabic sits, in either interface.
                        .environment(\.layoutDirection, .leftToRight)
                    if !definition.literal.isEmpty { Text("Literally: \(definition.literal.localizedDisplay)").font(.footnote) }
                    if !definition.technical.isEmpty { Text(definition.technical.localizedDisplay).font(.footnote) }
                }
            }

            if let card = lesson.ruleCard {
                Section(header: Text("The Rule")) {
                    if !card.trigger.isEmpty { Text("When: \(card.trigger.localizedDisplay)").font(.footnote) }
                    if !card.action.isEmpty { Text("Do: \(card.action.localizedDisplay)").font(.footnote) }
                    if !card.hold.isEmpty { Text("Hold: \(card.hold.localizedDisplay)").font(.footnote) }
                }
            }

            ForEach(lesson.letterSets) { set in
                Section(header: Text(set.label.localizedDisplay)) {
                    Text(set.letters.joined(separator: "  "))
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .leftToRight)
                    if !set.note.isEmpty {
                        Text(set.note.localizedDisplay)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Explanation")) {
                ForEach(Array(lesson.body.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph.localizedDisplay)
                        .font(.footnote)
                }
            }

            ForEach(lesson.words) { group in
                Section(header: Text(group.label.localizedDisplay)) {
                    ForEach(group.items) { word in
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(word.arabic(in: quranData))
                                .font(.title3)
                            Text(word.translit)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }

            if !lesson.keyPoints.isEmpty {
                Section(header: Text("Worth Remembering")) {
                    ForEach(Array(lesson.keyPoints.enumerated()), id: \.offset) { _, point in
                        Text(point.localizedDisplay)
                            .font(.footnote)
                    }
                }
            }

            if !lesson.mistakes.isEmpty {
                Section(header: Text("Common Mistakes")) {
                    ForEach(lesson.mistakes) { mistake in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(mistake.wrong.localizedDisplay)
                                .font(.footnote)
                                .foregroundColor(.red)
                            Text(mistake.right.localizedDisplay)
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.green)
                        }
                    }
                }
            }

            Section {
                Button {
                    progress.toggle(lesson.id)
                } label: {
                    Label(progress.isDone(lesson.id) ? String(localized: "Marked as Done") : String(localized: "Mark as Done"),
                          systemImage: progress.isDone(lesson.id) ? "checkmark.circle.fill" : "circle")
                }
            }
        }
        .navigationTitle(lesson.titleEn.localizedDisplay)
    }
}
#endif
