import SwiftUI

// Tajweed Foundations: Al-Islam's own tajweed reference, one rule to a page.
//
// From 2026-09-23 to 2026-10-03 these pages lived only inside the Tajweed Course, merged lesson by
// lesson (Scripts/tajweed_foundations.py). Abu, 2026-10-03: "bring back tajweed foundations and
// tajweed course ... keep it as Tajweed Course but bring back Tajweed Foundations (but make the
// overview it's own link rather than a huge section) and make it pretty like Pillars and Beliefs".
// So the two are two resources again: the course (TajweedView.swift) teaches in order, with ayahs to
// play and a quiz in each lesson; Foundations is the reference you look a rule up in. The course
// keeps everything that was merged into it, and each page here points at the lesson that practises it.
//
// This file is the index, the Overview (the old screen's long opening sections, now a page of their
// own), and the pieces every page draws with. The fourteen topic pages are TajweedTopics.swift. Both
// compile for the watch, where the index is a plain list and the hero is not drawn.

/// One page of Tajweed Foundations, in the order the index lists it.
enum TajweedTopic: String, CaseIterable, Identifiable {
    case overview
    case improving
    case lips
    case makharij
    case sifaat
    case heavyLight
    case shamsQamar
    case madd
    case qalqalah
    case noonSakinah
    case meemSakinah
    case mushafHints
    case sukoon
    case hamzatulWasl
    case waqf

    var id: String { rawValue }

    /// The index's sections, in this order.
    enum Group: CaseIterable {
        case start, letters, rules, mushaf

        var title: String {
            switch self {
            case .start: return "START HERE"
            case .letters: return "THE LETTERS"
            case .rules: return "THE RULES"
            case .mushaf: return "READING THE MUSHAF"
            }
        }

        var topics: [TajweedTopic] { TajweedTopic.allCases.filter { $0.group == self } }
    }

    var group: Group {
        switch self {
        case .overview, .improving: return .start
        case .lips, .makharij, .sifaat, .heavyLight: return .letters
        case .shamsQamar, .madd, .qalqalah, .noonSakinah, .meemSakinah: return .rules
        case .mushafHints, .sukoon, .hamzatulWasl, .waqf: return .mushaf
        }
    }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .improving: return "Improving Your Recitation"
        case .lips: return "Lip Movement"
        case .makharij: return "Makhaarij (Articulation)"
        case .sifaat: return "Sifaat (Letter Qualities)"
        case .heavyLight: return "Heavy and Light"
        case .shamsQamar: return "Shams and Qamar: Al"
        case .madd: return "Madd (Elongation)"
        case .qalqalah: return "Qalqalah"
        case .noonSakinah: return "Noon Sakinah and Tanween"
        case .meemSakinah: return "Meem Sakinah"
        case .mushafHints: return "Tajweed Hints in the Mushaf"
        case .sukoon: return "4 Sukoon"
        case .hamzatulWasl: return "Hamzatul Wasl"
        case .waqf: return "Waqf (Stopping)"
        }
    }

    var caption: String {
        switch self {
        case .overview: return "What tajweed is, why it matters, and how to begin"
        case .improving: return "Practising alone, listening, and reciting to a teacher"
        case .lips: return "Natural recitation, without overemphasis"
        case .makharij: return "Where each letter is made: the throat, the tongue, the lips"
        case .sifaat: return "The qualities that tell two letters apart"
        case .heavyLight: return "Tafkhim and tarqiq, and the letters that change"
        case .shamsQamar: return "When the laam of ٱلـ is read, and when it merges"
        case .madd: return "Every elongation, and how many counts it takes"
        case .qalqalah: return "The five letters that bounce"
        case .noonSakinah: return "Idhaar, idghaam, iqlaab and ikhfaa"
        case .meemSakinah: return "The three rules of the lips"
        case .mushafHints: return "Reading the rules straight from the script"
        case .sukoon: return "The four sukoon marks, and what each one asks"
        case .hamzatulWasl: return "The connecting hamzah, and how to start on it"
        case .waqf: return "Where to stop, and what changes when you do"
        }
    }

    /// The topic's name in Arabic: the term a teacher will use.
    var arabic: String {
        switch self {
        case .overview: return "التَّجوِيد"
        case .improving: return "تَحسِينُ التِّلَاوَة"
        case .lips: return "الشَّفَتَان"
        case .makharij: return "مَخَارِجُ الحُرُوف"
        case .sifaat: return "صِفَاتُ الحُرُوف"
        case .heavyLight: return "التَّفخِيمُ وَالتَّرقِيق"
        case .shamsQamar: return "الشَّمسِيَّةُ وَالقَمَرِيَّة"
        case .madd: return "المَدّ"
        case .qalqalah: return "القَلقَلَة"
        case .noonSakinah: return "النُّونُ السَّاكِنَة"
        case .meemSakinah: return "المِيمُ السَّاكِنَة"
        case .mushafHints: return "ضَبطُ المُصحَف"
        case .sukoon: return "السُّكُون"
        case .hamzatulWasl: return "هَمزَةُ الوَصل"
        case .waqf: return "الوَقف"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "doc.text.magnifyingglass"
        case .improving: return "chart.line.uptrend.xyaxis"
        case .lips: return "mouth"
        case .makharij: return "speaker.wave.2"
        case .sifaat: return "waveform"
        case .heavyLight: return "scalemass"
        case .shamsQamar: return "sun.max"
        case .madd: return "arrow.left.and.right"
        case .qalqalah: return "arrowshape.bounce.forward"
        case .noonSakinah: return "n.circle"
        case .meemSakinah: return "m.circle"
        case .mushafHints: return "text.magnifyingglass"
        case .sukoon: return "circle.dotted"
        case .hamzatulWasl: return "link"
        case .waqf: return "pause.circle"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .overview: TajweedOverviewView()
        case .improving: TajweedImprovingRecitationView()
        case .lips: TajweedLipMovementView()
        case .makharij: TajweedMakharijView()
        case .sifaat:
            // The qualities shelf of the alphabet's Letter Families: the five opposing pairs and the
            // qualities with no opposite, every one named in Arabic and English (Abu, 2026-09-20).
            LetterFamiliesView(title: "Sifaat", axes: LetterAxis.Shelf.qualities.axes)
                .openScreen(.letterFamilies, id: "sifaat")
        case .heavyLight: TajweedHeavyLightView()
        case .shamsQamar: TajweedShamsQamarView()
        case .madd: TajweedMaddView()
        case .qalqalah: TajweedQalqalahView()
        case .noonSakinah: TajweedIdghamIkhfaView()
        case .meemSakinah: TajweedMeemSakinahView()
        case .mushafHints: TajweedInMushafView()
        case .sukoon: TajweedSukoonView()
        case .hamzatulWasl: TajweedHamzatulWaslView()
        case .waqf: TajweedWaqfView()
        }
    }
}

// MARK: - The index

struct TajweedFoundationsView: View {
    @Environment(\.appearance) private var appearance

    #if os(iOS)
    @State private var showTajweedLegend = false
    /// The page a color in the hero opened. The chips are Buttons in ONE List row writing this, with
    /// one destination on the List (two NavigationLinks in one row both fire on any tap).
    @State private var heroTopic: TajweedTopic?
    #endif

    #if DEBUG
    /// `-tajweedTopic <rawValue>`: that page pushed as the index appears, for screenshots.
    @State private var debugOpenTopic = false
    private static var debugTopic: TajweedTopic? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: "-tajweedTopic"), arguments.indices.contains(idx + 1) else { return nil }
        return TajweedTopic(rawValue: arguments[idx + 1])
    }
    #endif

    var body: some View {
        List {
            Group {
                #if os(iOS)
                Section {
                    TajweedFoundationsHero(open: $heroTopic)
                        .articleCardRow()
                }
                #endif

                ForEach(TajweedTopic.Group.allCases, id: \.self) { group in
                    Section(header: Text(group.title)) {
                        ForEach(group.topics) { topic in
                            NavigationLink(destination: LazyDestination { topic.destination }) {
                                TajweedTopicRow(topic: topic)
                            }
                        }
                    }
                }

                referenceSection

                if TajweedLessonsStore.isBundled {
                    courseSection
                }

                learnMoreSection

                Section(footer:
                    Text("Every page is for Hafs an Asim, the riwayah of most printed mushafs. Other riwayat apply some of these rules differently.")
                        .font(.caption2)
                ) { EmptyView() }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Tajweed Foundations")
        .openScreen(.tajweedFoundations)
        #if os(iOS)
        .pushDestination(isPresented: Binding(
            get: { heroTopic != nil },
            set: { if !$0 { heroTopic = nil } }
        )) {
            if let heroTopic { heroTopic.destination }
        }
        .sheet(isPresented: $showTajweedLegend) {
            NavigationView {
                TajweedLegendView()
            }
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
        #endif
        #if DEBUG
        .debugPushDestination(isPresented: $debugOpenTopic) {
            if let topic = Self.debugTopic { topic.destination }
        }
        .onAppear {
            if Self.debugTopic != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugOpenTopic = true }
            }
        }
        #endif
    }

    // MARK: Quick reference

    /// The tools beside the pages rather than inside one: the reader's color legend, and the
    /// alphabet's two indexes of the letters tajweed is about.
    private var referenceSection: some View {
        Section(header: Text("QUICK REFERENCE")) {
            #if os(iOS)
            Button {
                Settings.shared.hapticFeedback()
                showTajweedLegend = true
            } label: {
                HStack(spacing: 12) {
                    TajweedLinkLabel(systemImage: "paintpalette.fill", title: "Tajweed Legend",
                                     caption: "Every rule the Quran reader colors, for Hafs an Asim")
                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            #endif

            NavigationLink(destination: LazyDestination { LetterFamiliesView() }) {
                TajweedLinkLabel(systemImage: "square.grid.3x3", title: "Letter Families",
                                 caption: "Every letter by makhraj, sifaat and rule, in Arabic and English")
            }

            NavigationLink(destination: LazyDestination { SoundAlikeLettersView() }) {
                TajweedLinkLabel(systemImage: "ear", title: "Sound-Alike Letters",
                                 caption: "The pairs people mix up, side by side, with what separates them")
            }
        }
    }

    // MARK: The course

    /// The other tajweed resource: the same rules taught in order. The course links back here, so the
    /// row greys out when the course is already on the stack.
    private var courseSection: some View {
        Section(header: Text("PRACTISE IT")) {
            #if os(iOS)
            OpenScreenLink(screen: .tajweedCourse) {
                TajweedCourseView()
            } label: {
                courseLabel
            }
            #else
            NavigationLink(destination: LazyDestination { TajweedCourseView() }) {
                courseLabel
            }
            #endif
        }
    }

    private var courseLabel: some View {
        TajweedLinkLabel(systemImage: "graduationcap.fill", title: "Tajweed Course",
                         caption: "The same rules taught in order, lesson by lesson, with ayahs to play and a quiz in each")
    }

    // MARK: Learn more

    private var learnMoreSection: some View {
        Section(header: Text("LEARN MORE"), footer: Text("Also in Al-Islam, under Pillars & Beliefs.")) {
            NavigationLink(destination: LazyDestination { QuranPillarView() }) {
                TajweedLinkLabel(systemImage: "book.closed", title: "What is the Quran?",
                                 caption: "Its revelation, preservation and names")
            }

            // The article links back here, so the pair is a corridor; `OpenScreenLink` greys the row
            // when the article is already open. It does not exist on the watch.
            #if os(iOS)
            OpenScreenLink(screen: .tajweedArticle) {
                TajweedView()
            } label: {
                tajweedArticleLabel
            }
            #else
            NavigationLink(destination: LazyDestination { TajweedView() }) {
                tajweedArticleLabel
            }
            #endif

            NavigationLink(destination: LazyDestination { AhrufView() }) {
                TajweedLinkLabel(systemImage: "7.circle", title: "What are the 7 Ahruf?",
                                 caption: "The seven modes the Quran was revealed in")
            }

            NavigationLink(destination: LazyDestination { QiraatView() }) {
                TajweedLinkLabel(systemImage: "10.circle", title: "What are the 10 Qiraat?",
                                 caption: "The ten readings and their riwayat")
            }
        }
    }

    private var tajweedArticleLabel: some View {
        TajweedLinkLabel(systemImage: "doc.text", title: "What is Tajweed?",
                         caption: "The article, with its sources")
    }
}

/// One page of the index: an accent chip, the title with the topic's Arabic name across from it, and
/// what the page covers under both. The Arabic is never cut: the title wraps first, and at the
/// accessibility sizes, where the row has no room, the Arabic is left out.
private struct TajweedTopicRow: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let topic: TajweedTopic

    var body: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: topic.systemImage, size: 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 8) {
                    Text(topic.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 4)

                    if !dynamicTypeSize.isAccessibilitySize {
                        Text(topic.arabic)
                            .font(appearance.islamArabicFont(base: 15, relativeTo: .subheadline))
                            .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                            .foregroundColor(appearance.accent)
                            .lineLimit(1)
                            .fixedSize()
                            .accessibilityHidden(true)
                    }
                }

                Text(topic.caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
    }
}

/// A row that opens a screen beside the pages: the chip, the title and one line.
struct TajweedLinkLabel: View {
    let systemImage: String
    let title: String
    let caption: String

    var body: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

#if os(iOS)
/// The index's opening card (`ResourceHero`), the way Pillars & Beliefs opens on its building: the
/// colors the tajweed mushaf paints, each one a door to the page that teaches the rule it marks. The
/// swatch is the reader's own color for that rule (a custom pick included), so what you learn here is
/// what you see on the page.
private struct TajweedFoundationsHero: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var open: TajweedTopic?

    private struct Mark: Identifiable {
        let topic: TajweedTopic
        let legend: TajweedLegendCategory
        let name: String
        let arabic: String

        var id: String { topic.rawValue }
    }

    private static let marks: [Mark] = [
        Mark(topic: .noonSakinah, legend: .ikhfaaLight, name: "Noon Sakinah", arabic: "النُّون"),
        Mark(topic: .meemSakinah, legend: .generalGhunnah, name: "Meem Sakinah", arabic: "المِيم"),
        Mark(topic: .madd, legend: .maddConnected, name: "Madd", arabic: "المَدّ"),
        Mark(topic: .qalqalah, legend: .qalqalah, name: "Qalqalah", arabic: "القَلقَلَة"),
        Mark(topic: .heavyLight, legend: .tafkhim, name: "Heavy Letters", arabic: "التَّفخِيم"),
        Mark(topic: .shamsQamar, legend: .lamShamsiyah, name: "Solar Laam", arabic: "الشَّمسِيَّة"),
        Mark(topic: .hamzatulWasl, legend: .hamzatWaslSilent, name: "Joining Hamzah", arabic: "الوَصل"),
        Mark(topic: .sukoon, legend: .droppedLetter, name: "Silent Letters", arabic: "السُّكُون"),
    ]

    var body: some View {
        ResourceHero(
            eyebrow: "EVERY RULE, ONE PAGE EACH",
            systemImage: "waveform",
            headline: "Those to whom We have given the Book recite it with its true recital.",
            source: "Quran 2:121",
            message: "The rules of Hafs an Asim, one topic to a page: where each letter is made and how it sounds, the rules that change it, and how to read them straight off the mushaf. Tap a color to open the rule it marks."
        ) {
            colors
        }
    }

    private var colors: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 8) {
            Text("WHAT THE TAJWEED COLORS MARK")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.4)
                .foregroundColor(accent)

            // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height on
            // each self-sizing pass, which iOS 26 traps on.
            SummaryTileGrid(columns: dynamicTypeSize.isAccessibilitySize ? 1 : 2, spacing: 6) {
                ForEach(Self.marks) { mark in
                    Button {
                        Settings.shared.hapticFeedback()
                        open = mark.topic
                    } label: {
                        chip(mark, accent: accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mark.name). Opens \(mark.topic.title).")
                }
            }
        }
        .padding(.top, 2)
    }

    private func chip(_ mark: Mark, accent: Color) -> some View {
        let color = mark.legend.color
        return HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 11, height: 11)
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5))

            Text(mark.name)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 4)

            Text(mark.arabic)
                .font(appearance.islamArabicFont(base: 14, relativeTo: .caption))
                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accent.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(color.opacity(0.45), lineWidth: 1))
        )
        .contentShape(Rectangle())
    }
}
#endif

// MARK: - Overview

/// The old index's opening sections (Overview, Why Learn Tajweed?, How to Start Learning, Applicability
/// to Qiraat), which filled the screen before the first topic. A page of their own since 2026-10-03.
struct TajweedOverviewView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("WHAT TAJWEED IS")) {
                    ArticleLead("Tajweed (تَجوِيد) refers to the science and practice of reciting the Quran correctly and beautifully, by giving each letter its proper articulation and characteristics.")

                    ArticleTermCard("Tajweed", arabic: "تَجوِيد",
                                    meaning: "Linguistically, the word tajweed comes from the Arabic root ج-و-د (j-w-d), meaning \"to improve,\" \"to make excellent,\" or \"to perfect.\" In the context of the Quran, it means reciting the words of Allah as they were revealed precisely, clearly, and with care.")

                    ArticleCallout("This guide applies specifically to riwayat Hafs an Asim, which is the most widely recited qiraah in the world today and the standard riwayah used in the majority of printed mushafs.",
                                   title: "Hafs an Asim", systemImage: "book.closed.fill")
                }

                Section(header: ArticleHeader("RECITATION AND PRONUNCIATION")) {
                    Text(verbatim: "Recitation (قِرَاءَة qiraah or تِلَاوَة tilawah) refers to the act of reading the Quran. While qiraah simply means \"reading,\" tilawah carries a deeper meaning of reciting with attentiveness, reflection, and adherence to proper method. Quranic recitation is not just reading text; it is the transmission of a preserved oral tradition passed down from the Prophet ﷺ through generations.")
                        .font(.body)

                    Text(verbatim: "Pronunciation in Quranic recitation is governed by two key components:")
                        .font(.body)

                    ArticleVersus(
                        .init("Makharij", arabic: "مَخَارِجُ الحُرُوفِ",
                              caption: "The points of articulation: where each letter originates in the mouth or throat."),
                        .init("Sifat", arabic: "صِفَاتُ الحُرُوفِ",
                              caption: "The characteristics of those letters, such as heaviness (tafkhim), lightness (tarqiq), or echoing (qalqalah)."),
                        quranic: false
                    )

                    Text(verbatim: "Together, they ensure that each letter is pronounced distinctly and correctly.")
                        .font(.body)

                    Text(verbatim: "These elements are essential because even slight changes in pronunciation can alter meanings. Tajweed preserves not only the beauty of the Quran, but also its accuracy and integrity. The Quran was revealed to be recited, and Allah commands:")
                        .font(.body)

                    ScriptureQuote(quran: "73:4", words: 3...5)
                }

                Section(header: ArticleHeader("WHY LEARN TAJWEED?")) {
                    ArticleStep("1. **Honoring the Quran:** The Quran is the final revelation from Allah. Reciting it with care and precision is a form of respect and reverence for the sacred text. By learning Tajweed, you follow the Prophet ﷺ who recited with the utmost clarity and eloquence.")

                    ArticleStep("2. **Preventing Misunderstandings:** By applying Tajweed rules, you avoid mistakes that may alter the meaning of verses. In some cases, even changing a single sound or stretching a vowel can result in an entirely different meaning.")

                    ArticleStep("3. **Enhancing Spiritual Connection:** Many Muslims find that reciting the Quran with Tajweed enhances their spiritual experience. The attention to detail required encourages mindfulness and deeper reflection on the meaning of the verses, making your recitation more immersive and meaningful.")

                    ArticleStep("4. **Following the Sunnah:** The Prophet Muhammad ﷺ encouraged reciting the Quran beautifully. By learning Tajweed, you honor his teachings and example.")

                    ScriptureQuote(text: "“Whoever does not recite Qur'an in a nice voice is not from us.” (Sahih al-Bukhari 7527)",
                                   arabic: "لَيْسَ مِنَّا مَنْ لَمْ يَتَغَنَّ بِالْقُرْآنِ", dimmed: true)
                }

                Section(header: ArticleHeader("HOW TO START LEARNING")) {
                    Text(verbatim: "Learning Tajweed might seem challenging at first, but there are many resources available today to make the process easier. Traditionally, learning Tajweed was done with a teacher who could guide you through the articulation points and characteristics of each letter.")
                        .font(.body)

                    Text(verbatim: "Now, in addition to teachers, there are online platforms, videos, and books that provide step-by-step lessons. For those starting out, focus on mastering the basic rules first and gradually build your skills over time. Practicing consistently is key; recording your recitation can help you catch mistakes and improve pronunciation.")
                        .font(.body)

                    Text(verbatim: "Many learners find benefit in joining Tajweed classes or study groups, where they can receive feedback and support from others on the same journey.")
                        .font(.body)
                }

                Section(header: ArticleHeader("APPLICABILITY TO QIRAAT")) {
                    ArticleCallout(paragraphs: [
                        "Other riwayat, such as Warsh an Nafi, Khalaf an Hamzah, and others, may differ slightly in their application of tajweed rules, including elongations (madd), treatment of hamzah, and certain pronunciation details. These differences stem from authentic variations rooted in classical Arabic dialects and were transmitted through reliable chains of recitation.",
                        "As a result, some rules explained in this guide may not apply identically to other riwayat. These variations in tajweed application and pronunciation reflect the diversity of classical Arabic dialects that were all correctly recited and approved by the Prophet ﷺ, and have been preserved exactly through continuous transmission. They highlight the richness, flexibility, and authenticity of the Quranic recitation tradition.",
                    ], title: "Other Riwayat", systemImage: "books.vertical.fill")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("For this reason, learning and applying tajweed is a means of preserving the exact words of the Quran as they were revealed and recited by the Prophet ﷺ, ensuring that its message remains unchanged across generations.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "what-is-tajweed", title: "What Tajweed Is"),
                    TajweedCourseLesson(id: "tajweed-principles-errors", title: "Every Letter's Two Dues"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Overview")
    }
}

// MARK: - The pages' pieces

/// A word and how it reads: the Foundations pages' examples. `note` is the line under the reading
/// ("Version 1: apply the next-letter rule").
struct TajweedWord: Hashable {
    let arabic: String
    let reading: String
    var note: String = ""

    init(_ arabic: String, _ reading: String, note: String = "") {
        self.arabic = arabic
        self.reading = reading
        self.note = note
    }
}

/// A card of example words under a small label. Side by side (the reading leading, the Arabic
/// trailing) for single words; `stacked` sets the Arabic on its own line above the reading, for the
/// before-and-after pairs that are too long to share a line.
struct TajweedWordCard: View {
    @Environment(\.appearance) private var appearance

    let title: String
    /// A line under the label saying when these words apply ("With fathah or dammah").
    var note: String? = nil
    let words: [TajweedWord]
    var stacked: Bool = false
    var size: CGFloat = 26

    init(_ title: String = "Examples", note: String? = nil, words: [TajweedWord], stacked: Bool = false,
         size: CGFloat = 26) {
        self.title = title
        self.note = note
        self.words = words
        self.stacked = stacked
        self.size = size
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                TajweedCardTitle(title)
                if let note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                if index > 0 {
                    Divider().opacity(0.6)
                }
                if stacked {
                    VStack(alignment: .leading, spacing: 4) {
                        arabic(word.arabic)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        reading(word)
                    }
                } else {
                    HStack(alignment: .center, spacing: 12) {
                        reading(word)
                        Spacer(minLength: 12)
                        arabic(word.arabic)
                            .layoutPriority(1)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArticleCardGround(accent: accent, strength: 0.45, radius: 14))
        .padding(.vertical, 3)
    }

    private func arabic(_ text: String) -> some View {
        Text(text.decomposingAlefMadda)
            .font(appearance.quranArabicFont(size: size, relativeTo: .title2))
            .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
            .foregroundColor(.primary)
            .multilineTextAlignment(.trailing)
            // The mushaf faces carry a very tall line box; trim it so a list of words reads as a list.
            .padding(.vertical, appearance.quranUsesCustomArabicFace ? -5 : 0)
    }

    private func reading(_ word: TajweedWord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(word.reading)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            if !word.note.isEmpty {
                Text(word.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A line of the Quran set on its own card, centered, under an optional label and with how it reads
/// under it.
struct TajweedArabicLine: View {
    @Environment(\.appearance) private var appearance

    let arabic: String
    var title: String? = nil
    var caption: String? = nil
    var size: CGFloat = 26

    init(_ arabic: String, title: String? = nil, caption: String? = nil, size: CGFloat = 26) {
        self.arabic = arabic
        self.title = title
        self.caption = caption
        self.size = size
    }

    var body: some View {
        VStack(spacing: 8) {
            if let title, !title.isEmpty {
                TajweedCardTitle(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(arabic.decomposingAlefMadda)
                .font(appearance.quranArabicFont(size: size, relativeTo: .title2))
                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if let caption, !caption.isEmpty {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(ArticleCardGround(accent: appearance.accent, strength: 0.45, radius: 14))
        .padding(.vertical, 3)
    }
}

/// The one line of a rule worth seeing at a glance ("Length: 2 counts", "مْ + ب = Ikhfaa Shafawi"),
/// set in the accent with its icon.
struct TajweedKeyLine: View {
    @Environment(\.appearance) private var appearance

    let text: String
    var systemImage: String = "key.fill"

    init(_ text: String, systemImage: String = "key.fill") {
        self.text = text
        self.systemImage = systemImage
    }

    var body: some View {
        let accent = appearance.accent
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundColor(accent)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.opacity(0.13))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(accent.opacity(0.25), lineWidth: 1))
        )
        .padding(.vertical, 2)
    }
}

/// A common mistake and its correction, the way the course sets them: INSTEAD OF in red, DO THIS in
/// green.
struct TajweedFix: View {
    let wrong: String
    let right: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            line("Instead of", wrong, color: .red, weight: .regular)
            line("Do this", right, color: .green, weight: .semibold)
        }
        .padding(.vertical, 4)
    }

    private func line(_ label: String, _ text: String, color: Color, weight: Font.Weight) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 9.5, weight: .heavy))
                .tracking(0.5)
                .foregroundColor(color)
                .fixedSize()
                .frame(minWidth: 70)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(color.opacity(0.14)))
            Text(text)
                .font(.subheadline.weight(weight))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The label a card or a strip of letter tiles carries, set the way `ArticleChecklist` sets its title
/// so the pieces on a page read as one family.
struct TajweedCardTitle: View {
    @Environment(\.appearance) private var appearance
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.bold))
            .foregroundColor(appearance.accent)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A strip of the alphabet's letter tiles under its label; each tile opens that letter's page
/// (Abu, 2026-09-20: tiles, not a line of text).
struct TajweedLetterStrip: View {
    let title: String?
    var note: String? = nil
    let letters: [String]
    var tint: Color? = nil
    let onOpen: (LetterData) -> Void

    init(_ title: String? = nil, note: String? = nil, letters: [String], tint: Color? = nil,
         onOpen: @escaping (LetterData) -> Void) {
        self.title = title
        self.note = note
        self.letters = letters
        self.tint = tint
        self.onOpen = onOpen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                TajweedCardTitle(title)
            }
            if let note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            LetterTileStrip(letters: letters, tint: tint, onOpen: onOpen)
        }
        .padding(.vertical, 2)
    }
}

/// One of the alphabet's letter families, as the row that opens its page.
struct TajweedFamilyRow: View {
    let family: LetterFamily

    init(_ family: LetterFamily) { self.family = family }

    var body: some View {
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

/// A video lesson, opened in YouTube.
struct TajweedVideoLink: View {
    let title: String
    let url: String
    var channel: String = "Arabic 101"

    var body: some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    AccentIconChip(systemImage: "play.fill", tint: .red, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        // Explicit greys: inside a Link the hierarchical styles take the link's tint.
                        Text("\(channel), on YouTube")
                            .font(.caption)
                            .foregroundColor(Self.secondaryInk)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Self.secondaryInk)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private static var secondaryInk: Color {
        #if os(iOS)
        Color(UIColor.secondaryLabel)
        #else
        Color.gray
        #endif
    }
}

/// A lesson of the Tajweed Course, as a page names it.
struct TajweedCourseLesson: Hashable {
    let id: String
    let title: String
}

/// The foot of a Foundations page: the course lessons that practise its rule. The two tajweed
/// resources cover one subject, so each reference page points at its practice. Each row greys out
/// when that lesson is already open further up the stack (`TajweedLessonLink`).
struct TajweedCourseLessons: View {
    let lessons: [TajweedCourseLesson]

    init(_ lessons: [TajweedCourseLesson]) { self.lessons = lessons }

    var body: some View {
        if TajweedLessonsStore.isBundled, !lessons.isEmpty {
            Section(header: ArticleHeader("IN THE TAJWEED COURSE")) {
                ForEach(lessons, id: \.self) { lesson in
                    TajweedLessonLink(lessonID: lesson.id) {
                        TajweedLinkLabel(systemImage: "graduationcap.fill", title: lesson.title,
                                         caption: "Practise it lesson by lesson")
                    }
                }
            }
        }
    }
}
