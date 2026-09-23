import SwiftUI

// Tajweed Foundations: the tajweed course's home (TajweedCourse.swift).
//
// This screen used to be two things: Al-Islam's fourteen Foundations topic pages, and a card leading
// to the course Jamil Hammoudeh wrote for Tilawa. Abu, 2026-09-23: merge them one by one into one
// thing, in the course's design. Every topic page now lives inside the lessons that teach the same
// rule (Scripts/tajweed_foundations.py maps each one), and this screen is the course's index in
// Tilawa's layout: what the course is, the quick references, then the four stages, each holding its
// chapters, each holding its lessons, and the articles it points to at the end.
//
// The phone draws the full index and lessons (TajweedLessons.swift); the watch reads the same pack
// with a compact index and lesson page, below.

#if os(iOS)
struct TajweedFoundationsView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var progress = TajweedLessonProgress.shared

    /// The course, parsed off the main thread in the task below (500 KB); a spinner stands in until
    /// it lands.
    @State private var course: TajweedLessonsStore.Course? = TajweedLessonsStore.shared.courseIfLoaded
    @State private var showTajweedLegend = false

    #if DEBUG
    /// `-openTajweedLesson <id>`: that lesson pushed as the course appears, for screenshots.
    @State private var debugOpenLesson = false
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
        let _ = RenderCounter.hit("TajweedFoundationsView")
        let lessons = course?.lessons ?? []
        let numbers = Dictionary(lessons.enumerated().map { ($1.id, $0 + 1) }, uniquingKeysWith: { first, _ in first })

        List {
            Group {
                if shows("overview") { overviewSection(lessons: lessons) }

                if course == nil, TajweedLessonsStore.isBundled {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }

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
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Tajweed Foundations")
        .openScreen(.tajweedFoundations)
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
        .onAppear {
            if Self.debugLessonID != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugOpenLesson = true }
            }
        }
        #endif
    }

    // MARK: What the course is

    private func overviewSection(lessons: [TajweedLesson]) -> some View {
        let doneCount = lessons.filter { progress.isDone($0.id) }.count
        let minutes = lessons.reduce(0) { $0 + $1.minutes }
        // Where to pick up: the first lesson in course order not yet marked done.
        let next = doneCount > 0 ? lessons.first(where: { !progress.isDone($0.id) }) : nil

        return Section {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    AccentIconChip(systemImage: "graduationcap.fill", size: 36)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Learn Tajweed")
                            .font(.title3.weight(.heavy))
                        Text("Hafs an Asim, by the way of ash-Shatibiyyah")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("One course for all of tajweed, taught in the classical order: read the letters, shape them, apply the rules, then read the mushaf. Every lesson explains its rule, shows it in real ayahs you can play, gives you words and patterns to practise, and ends with a self-check.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                if !lessons.isEmpty {
                    Text("\(lessons.count) lessons \u{00B7} \(course?.chapters.count ?? 0) chapters \u{00B7} about \(Self.duration(minutes))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)
                }

                if doneCount > 0, !lessons.isEmpty {
                    ProgressView(value: Double(doneCount), total: Double(max(1, lessons.count)))
                        .tint(accent)
                        .padding(.top, 12)
                    Text("\(doneCount) of \(lessons.count) lessons done")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(accent)
                        .padding(.top, 6)
                }
            }
            .padding(.vertical, 6)

            if let next {
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
                            Text(next.titleEn)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private static func duration(_ minutes: Int) -> String {
        guard minutes >= 90 else { return "\(minutes) minutes" }
        let hours = (Double(minutes) / 60).rounded()
        return "\(Int(hours)) hours"
    }

    // MARK: Quick reference

    /// The tools that sit beside the course rather than inside a lesson: the reader's colour legend,
    /// and the alphabet's two indexes of the letters tajweed is about.
    private var referenceSection: some View {
        Section(header: Text("QUICK REFERENCE")) {
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
                    title: "Letter Families",
                    caption: "Every letter by makhraj, sifaat and rule, in Arabic and English",
                    preview: "الهَمس  الصَّفِير  القَلقَلَة  الغُنَّة"
                )
            }

            NavigationLink(destination: LazyDestination { SoundAlikeLettersView() }) {
                ArabicTopicLinkLabel(
                    specimen: "ذظ",
                    title: "Sound-Alike Letters",
                    caption: "The pairs people mix up, side by side, with what separates them"
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
                    Text(chapter.title)
                        .font(.headline.weight(.heavy))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text(chapter.lessons.count == 1 ? "1 lesson" : "\(chapter.lessons.count) lessons")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                if !chapter.subtitle.isEmpty {
                    Text(chapter.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)

            ForEach(chapter.lessons) { lesson in
                NavigationLink(destination: LazyDestination { TajweedLessonDetailView(lesson: lesson) }) {
                    lessonRow(lesson, number: numbers[lesson.id])
                }
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
                    Text(stage.stage.titleEn)
                        .font(.title3.weight(.heavy))
                        .foregroundColor(.primary)
                    Spacer(minLength: 8)
                    Text(stage.stage.titleAr)
                        .font(Font.arabic(appearance.quranDisplayFace, size: 18))
                        .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                        .foregroundColor(accent)
                }
                if !stage.stage.blurb.isEmpty {
                    Text(stage.stage.blurb)
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
                    Text(number.map(String.init) ?? "")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 26)

            // The English title is what the row is for: it takes the width first, and the Arabic name
            // shrinks beside it rather than pushing it onto a second line.
            Text(lesson.titleEn)
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
        .accessibilityValue(done ? "Done" : "")
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
struct TajweedFoundationsView: View {
    @ObservedObject private var progress = TajweedLessonProgress.shared
    @State private var course: TajweedLessonsStore.Course? = TajweedLessonsStore.shared.courseIfLoaded

    var body: some View {
        List {
            if let course {
                ForEach(course.stages) { stage in
                    let chapters = course.chapters.filter { $0.stage == stage.id }
                    if !chapters.isEmpty {
                        Section(header: Text(stage.titleEn)) {
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
                                                Text(lesson.titleEn)
                                                    .font(.footnote.weight(.semibold))
                                            }
                                            Text(chapter.title)
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
        .navigationTitle("Tajweed")
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
                    Text(lesson.titleEn)
                        .font(.headline)
                    if !lesson.titleAr.isEmpty {
                        Text(lesson.titleAr)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    if !lesson.summary.isEmpty {
                        Text(lesson.summary)
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
                    if !definition.literal.isEmpty { Text("Literally: \(definition.literal)").font(.footnote) }
                    if !definition.technical.isEmpty { Text(definition.technical).font(.footnote) }
                }
            }

            if let card = lesson.ruleCard {
                Section(header: Text("The Rule")) {
                    if !card.trigger.isEmpty { Text("When: \(card.trigger)").font(.footnote) }
                    if !card.action.isEmpty { Text("Do: \(card.action)").font(.footnote) }
                    if !card.hold.isEmpty { Text("Hold: \(card.hold)").font(.footnote) }
                }
            }

            ForEach(lesson.letterSets) { set in
                Section(header: Text(set.label)) {
                    Text(set.letters.joined(separator: "  "))
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    if !set.note.isEmpty {
                        Text(set.note)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Explanation")) {
                ForEach(Array(lesson.body.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.footnote)
                }
            }

            ForEach(lesson.words) { group in
                Section(header: Text(group.label)) {
                    ForEach(group.items) { word in
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(word.arabic(in: quranData))
                                .font(.title3)
                            Text(word.translit)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }

            if !lesson.keyPoints.isEmpty {
                Section(header: Text("Worth Remembering")) {
                    ForEach(Array(lesson.keyPoints.enumerated()), id: \.offset) { _, point in
                        Text(point)
                            .font(.footnote)
                    }
                }
            }

            if !lesson.mistakes.isEmpty {
                Section(header: Text("Common Mistakes")) {
                    ForEach(lesson.mistakes) { mistake in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(mistake.wrong)
                                .font(.footnote)
                                .foregroundColor(.red)
                            Text(mistake.right)
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
                    Label(progress.isDone(lesson.id) ? "Marked as Done" : "Mark as Done",
                          systemImage: progress.isDone(lesson.id) ? "checkmark.circle.fill" : "circle")
                }
            }
        }
        .navigationTitle(lesson.titleEn)
    }
}
#endif
