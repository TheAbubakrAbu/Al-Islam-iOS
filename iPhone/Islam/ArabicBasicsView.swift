import SwiftUI

/// Recognition-level Arabic grammar for someone who has just learned the letters: the feminine ة, the dual,
/// the three plural shapes, and the three case endings - a few worked examples each, not a grammar course.
/// Every row is the `ArabicExampleRow` shape the taa marbuuTah page uses: Arabic large in the app's Arabic
/// face, transliteration and a one-line English note beside it, tap to hear it.
///
/// Sun and moon letters (the definite article ال) are deliberately NOT here: the Tajweed screens already
/// teach Shamsiyyah and Qamariyyah in full.
struct ArabicBasicsView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        List {
            Group {
                genderSection
                dualSection
                pluralsSection
                casesSection
            }
            .themedListRowBackground()

        }
        .selectableArticleList()
        .navigationTitle("Basic Grammar")
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            // The size slider stays: watching the letters grow IS the control. The face picker moved to
            // Settings -> Islam Settings -> Arabic Text (Abu, 2026-09-19).
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                ArabicSizeSlider()
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HideEnglishToolbarButton()
            }
        }
        #endif
    }

    private var genderSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "مُسۡلِم",
                transliteration: "muslim",
                note: "A Muslim man: no ة"
            )
            ArabicExampleRow(
                arabic: "مُسۡلِمَة",
                transliteration: "muslimah",
                note: "A Muslim woman: the ة marks the feminine"
            )
            ArabicExampleRow(
                arabic: "مُعَلِّم \u{2190} مُعَلِّمَة",
                transliteration: "mu'allim \u{2192} mu'allimah",
                note: "A teacher, male \u{2192} female"
            )
        } header: {
            Text("GENDER: THE FEMININE ة")
        } footer: {
            Text("Adding taa marbuuTah (ة) to the end of a noun is the usual way Arabic marks it as feminine.")
        }
    }

    private var dualSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "كِتَاب",
                transliteration: "kitaab",
                note: "One book"
            )
            ArabicExampleRow(
                arabic: "كِتَابَانِ",
                transliteration: "kitaabaan(i)",
                note: "Two books, subject form (raf'): add ـَانِ"
            )
            ArabicExampleRow(
                arabic: "كِتَابَيۡنِ",
                transliteration: "kitaabayn(i)",
                note: "Two books, object or after-preposition form (nasb/jarr): add ـَيۡنِ"
            )
        } header: {
            Text("THE DUAL: EXACTLY TWO")
        } footer: {
            Text("Arabic has a special ending for exactly two of something, and it changes with the word's role in the sentence.")
        }
    }

    private var pluralsSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "مُسۡلِمُونَ",
                transliteration: "muslimuun(a)",
                note: "Sound masculine plural, subject form: add ـُونَ"
            )
            ArabicExampleRow(
                arabic: "مُسۡلِمِينَ",
                transliteration: "muslimiin(a)",
                note: "Sound masculine plural, object or after-preposition form: add ـِينَ"
            )
            ArabicExampleRow(
                arabic: "مُسۡلِمَات",
                transliteration: "muslimaat",
                note: "Sound feminine plural: the ة opens into ـَات"
            )
            ArabicExampleRow(
                arabic: "كِتَاب \u{2190} كُتُب",
                transliteration: "kitaab \u{2192} kutub",
                note: "Book \u{2192} books (broken plural)"
            )
            ArabicExampleRow(
                arabic: "رَجُل \u{2190} رِجَال",
                transliteration: "rajul \u{2192} rijaal",
                note: "Man \u{2192} men (broken plural)"
            )
            ArabicExampleRow(
                arabic: "بَيۡت \u{2190} بُيُوت",
                transliteration: "bayt \u{2192} buyuut",
                note: "House \u{2192} houses (broken plural)"
            )
        } header: {
            Text("PLURALS")
        } footer: {
            Text("Sound plurals add an ending and leave the word alone. Broken plurals reshape the inside of the word and follow no single rule; each one is memorized with its noun.")
        }
    }

    private var casesSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "جَآءَ ٱلرَّجُلُ",
                transliteration: "jaa'a r-rajulu",
                note: "Raf' (marfuu'): damma, the subject. \"The man came.\""
            )
            ArabicExampleRow(
                arabic: "رَأَيۡتُ ٱلرَّجُلَ",
                transliteration: "ra'aytu r-rajula",
                note: "Nasb (mansuub): fatha, the object. \"I saw the man.\""
            )
            ArabicExampleRow(
                arabic: "فِي ٱلۡبَيۡتِ",
                transliteration: "fi l-bayti",
                note: "Jarr (majruur): kasra, after a preposition or in idafah. \"In the house.\""
            )
        } header: {
            Text("THE THREE CASES (I'RAAB)")
        } footer: {
            Text("Recognition level only: the noun's final vowel changes with its job in the sentence. You will see these endings everywhere; you do not need to produce them yet.")
        }
    }
}

// MARK: - Alphabet topic links

/// The label of a topic link on the Arabic Alphabet list (Letters with Tashkeel, Default Tashkeel, the
/// stacked ٮحـ shape, Basic Grammar): an Arabic specimen in a tinted tile, the title and what the page
/// holds, and optionally a line of specimens showing what is inside.
///
/// These used to be a plain `Label` whose icon was a one-glyph `Text` in the system font, which left the
/// rows looking like settings rows beside a screen full of large letters (Abu, 2026-09-20).
struct ArabicTopicLinkLabel: View {
    @ObservedObject private var settings = Settings.shared

    let specimen: String
    let title: String
    let caption: String
    /// A line of Arabic shown under the caption, e.g. the marks the Tashkeel page covers.
    var preview: String? = nil
    /// Which face draws the Arabic. `.uthmani` is only for a page whose whole subject is a shape that
    /// face draws (the stacked ٮحـ); `.plain` is for unmarked text, where the mushaf faces would drop
    /// the dots of a final yaa and turn بي into the spelling of alif maqSoorah.
    enum Face { case reader, uthmani, plain }
    var face: Face = .reader

    #if os(watchOS)
    private static let tileSide: CGFloat = 34
    #else
    private static let tileSide: CGFloat = 46
    #endif

    private var usesArabicFace: Bool {
        switch face {
        case .reader: return settings.useFontArabic
        case .uthmani: return true
        case .plain: return false
        }
    }

    /// True when the text is in a bundled face and must opt out of the app's rounded design.
    private var usesCustomFace: Bool {
        switch face {
        case .reader: return settings.useFontArabic && settings.islamUsesCustomArabicFace
        case .uthmani: return true
        case .plain: return false
        }
    }

    private func arabicFont(base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        switch face {
        case .uthmani: return Font.arabic(Settings.hafsUthmaniFontName, size: base, relativeTo: style)
        case .reader where settings.useFontArabic: return settings.scalableIslamArabicFont(base: base, relativeTo: style)
        case .reader, .plain: return .system(style)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(specimen)
                .font(arabicFont(base: 24, relativeTo: .title2))
                .arabicFontDesign(custom: usesCustomFace)
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(width: Self.tileSide, height: Self.tileSide)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(settings.accentColor.color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)

                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let preview {
                    Text(preview)
                        .font(arabicFont(base: 17, relativeTo: face == .plain ? .callout : .body))
                        .arabicFontDesign(custom: usesCustomFace)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.top, usesArabicFace ? 0 : 2)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(caption)")
    }
}

// MARK: - Default tashkeel

/// What "default tashkeel" is: the marks a reader can supply WITHOUT knowing the word, because the
/// letters themselves force them (Abu, 2026-09-20). Reached from the alphabet's TASHKEEL section and from
/// the WITH ALIF, YAA AND WAAW section of every letter page, which is where the idea first comes up.
///
/// Same article grammar as `ArabicBasicsView`: a few worked `ArabicExampleRow`s per section, each rule
/// stated once in the footer. Every example writes the bare spelling first and the marked one after it,
/// because that is the direction the reader actually travels.
struct DefaultTashkeelView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        List {
            Group {
                heroSection
                meaningSection
                vowelLetterSection
                exceptionsSection
                forcedMarksSection
                quranSection
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Default Tashkeel")
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                ArabicSizeSlider()
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HideEnglishToolbarButton()
            }
        }
        #endif
    }

    // MARK: Hero

    /// The three defaults at a glance: the bare pair as it is printed, and beneath it the pair as it
    /// is read. Baa is the carrier, as on the Tashkeel table's chips.
    private static let heroPairs: [(bare: String, marked: String, reading: String, mark: String)] = [
        ("\u{0628}\u{0627}", "\u{0628}\u{064E}\u{0627}", "baa", "fatha"),
        ("\u{0628}\u{064A}", "\u{0628}\u{0650}\u{064A}", "bee", "kasra"),
        ("\u{0628}\u{0648}", "\u{0628}\u{064F}\u{0648}", "boo", "damma"),
    ]

    private func arabicFont(base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        settings.useFontArabic ? settings.scalableIslamArabicFont(base: base, relativeTo: style) : .system(style)
    }

    /// The modifiers go on the Arabic alone: opting the whole tile out of the rounded design, or
    /// raising its type floor, would restyle the English captions under it too.
    private func heroArabic(_ text: String, base: CGFloat, relativeTo style: Font.TextStyle) -> some View {
        Text(text)
            .font(arabicFont(base: base, relativeTo: style))
            .arabicFontDesign(custom: settings.useFontArabic && settings.islamUsesCustomArabicFace)
            .arabicLetterTypeFloor(steps: settings.arabicLetterSizeIndex)
    }

    private var heroSection: some View {
        Section {
            HStack(alignment: .top, spacing: 8) {
                ForEach(Self.heroPairs, id: \.bare) { pair in
                    VStack(spacing: 4) {
                        // Plain print, as unmarked text is: the mushaf faces drop a final yaa's dots,
                        // and a bare, undotted بى is the spelling of alif maqSoorah ("baa", not "bee").
                        Text(pair.bare)
                            .font(.title)
                            .arabicLetterTypeFloor(steps: settings.arabicLetterSizeIndex)
                            .foregroundColor(.secondary)

                        Image(systemName: "arrow.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)

                        heroArabic(pair.marked, base: 34, relativeTo: .largeTitle)
                            .foregroundColor(settings.accentColor.color)

                        if !settings.hideEnglishInArabicLetters {
                            Text(pair.reading)
                                .font(.caption.weight(.semibold))

                            Text(pair.mark)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(settings.accentColor.color.opacity(0.08))
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(pair.reading), read with a \(pair.mark)")
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.vertical, 4)
        } footer: {
            Text("Printed bare on top, read as beneath: the vowel letter tells you the mark before it.")
        }
    }

    // MARK: Sections

    private var meaningSection: some View {
        Section {
            Text("Tashkeel is optional in written Arabic. The Quran, children's books and learner texts print every mark; almost everything else (books, news, signs, messages) prints none, and the reader supplies them from knowing the word.")
                .font(.body)

            Text("Default tashkeel is the small set of marks you can supply WITHOUT knowing the word, because the letters themselves force them. It is the first thing a reader leans on in unmarked text.")
                .font(.body)

            ArabicExampleRow(
                arabic: "كتب \u{2190} كَتَبَ",
                transliteration: "ktb \u{2192} kataba",
                note: "\"He wrote.\" Nothing here is forced: the same three letters also spell كُتُب (kutub, books). This is the part you learn word by word."
            )
        } header: {
            Text("WHAT IT MEANS")
        }
    }

    private var vowelLetterSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "كتاب \u{2190} كِتَاب",
                transliteration: "kitaab",
                note: "Book: the taa sits before an alif, so it takes a fatha and reads \"taa\""
            )
            ArabicExampleRow(
                arabic: "كبير \u{2190} كَبِير",
                transliteration: "kabeer",
                note: "Big: the baa sits before a yaa, so assume a kasra, \"bee\""
            )
            ArabicExampleRow(
                arabic: "نور \u{2190} نُور",
                transliteration: "noor",
                note: "Light: the noon sits before a waaw, so assume a damma, \"noo\""
            )
        } header: {
            Text("BEFORE A VOWEL LETTER")
        } footer: {
            Text("The mark that matches the vowel letter is the default: a fatha before alif, a kasra before yaa, a damma before waaw. Together the pair is a long vowel, held for 2 counts.")
        }
    }

    private var exceptionsSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "بيت \u{2190} بَيۡت",
                transliteration: "bayt",
                note: "House: a fatha before the yaa, so it glides (\"ay\") instead of stretching"
            )
            ArabicExampleRow(
                arabic: "يوم \u{2190} يَوۡم",
                transliteration: "yawm",
                note: "Day: a fatha before the waaw, so it glides (\"aw\")"
            )
            ArabicExampleRow(
                arabic: "ولد \u{2190} وَلَد",
                transliteration: "walad",
                note: "Boy: here the waaw is a consonant opening the word, not a vowel at all"
            )
        } header: {
            Text("WHEN THE DEFAULT IS WRONG")
        } footer: {
            Text("For yaa and waaw the default is a first guess, not a law: both can follow a fatha and glide, and both can be plain consonants. Alif has no exceptions. The letter before it carries a fatha every time.")
        }
    }

    private var forcedMarksSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "رحمة \u{2190} رَحۡمَة",
                transliteration: "rahmah",
                note: "Mercy: the letter before taa marbuuTah (ة) always carries a fatha"
            )
            ArabicExampleRow(
                arabic: "على \u{2190} عَلَى",
                transliteration: "'alaa",
                note: "Upon: the letter before alif maqSoorah (ى) always carries a fatha"
            )
            ArabicExampleRow(
                arabic: "القمر \u{2190} ٱلۡقَمَر",
                transliteration: "al-qamar",
                note: "The moon: the laam of ال takes a sukoon before a moon letter"
            )
            ArabicExampleRow(
                arabic: "الشمس \u{2190} ٱلشَّمۡس",
                transliteration: "ash-shams",
                note: "The sun: before a sun letter the laam goes silent and that letter takes a shaddah"
            )
        } header: {
            Text("OTHER MARKS THE LETTERS FORCE")
        } footer: {
            Text("None of these needs the word's meaning. The spelling alone decides the mark.")
        }
    }

    private var quranSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "قَالَ",
                transliteration: "qaala",
                note: "He said: the alif is bare, so it is the long \"aa\""
            )
            ArabicExampleRow(
                arabic: "قِيلَ",
                transliteration: "qeela",
                note: "It was said: a bare yaa after a kasra, the long \"ee\""
            )
            ArabicExampleRow(
                arabic: "يَقُولُ",
                transliteration: "yaqoolu",
                note: "He says: a bare waaw after a damma, the long \"oo\""
            )
            ArabicExampleRow(
                arabic: "خَوۡفٌ",
                transliteration: "khawfun",
                note: "Fear: this waaw CARRIES a sukoon, so it glides (\"aw\")"
            )
        } header: {
            Text("IN THE QURAN")
        } footer: {
            Text("The mushaf marks every letter, so nothing is left to a default. There the rule runs the other way: a vowel letter left bare, with no mark of its own, is the long vowel, and one that carries a sukoon glides.")
        }
    }
}

// MARK: - The stacked baa + haa shape

/// ٮحـ: a baa-shaped letter joined onto a haa-shaped letter, the opening shape of fifteen different
/// letter pairs (Abu, 2026-09-20).
///
/// In the mushaf's Naskh hand the first letter of these pairs does not sit beside the haa on the line:
/// it rides above it as a small hook. A learner who knows ب and ح as separate shapes does not recognize
/// the pair, and once the dots are stripped all fifteen are the SAME shape, so the dots are the only
/// thing telling them apart. The table is the point of the page: every pair, side by side.
///
/// The shapes are drawn in the Uthmani face whatever the reader's Arabic face is. The stack is that
/// face's drawing; another face may join the two side by side and the page would be showing nothing.
struct BaaHaaShapesView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @ObservedObject private var settings = Settings.shared

    /// The dotless pair: U+066E (dotless baa), haa, and a tatweel so the haa stays in its joining form.
    static let skeleton = "\u{066E}\u{062D}\u{0640}"

    private static let baaShaped: [(letter: String, name: String)] = [
        ("\u{0628}", "baa"), ("\u{062A}", "taa"), ("\u{062B}", "thaa"), ("\u{0646}", "noon"), ("\u{064A}", "yaa"),
    ]

    private static let haaShaped: [(letter: String, name: String)] = [
        ("\u{062C}", "jeem"), ("\u{062D}", "Haa"), ("\u{062E}", "khaa"),
    ]

    private static let tatweel = "\u{0640}"

    private func uthmani(_ base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Font.arabic(Settings.hafsUthmaniFontName, size: base, relativeTo: style)
    }

    var body: some View {
        List {
            Group {
                shapeSection
                tableSection
                quranSection
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle(Self.skeleton)
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                ArabicSizeSlider()
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HideEnglishToolbarButton()
            }
        }
        #endif
    }

    private var shapeSection: some View {
        Section {
            VStack(spacing: 4) {
                Text(Self.skeleton)
                    .font(uthmani(64, relativeTo: .largeTitle))
                    .arabicFontDesign(custom: true)
                    .arabicLetterTypeFloor(steps: settings.arabicLetterSizeIndex)
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Text("a baa shape joined onto a haa shape, with the dots removed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .rowSeparatorFromLeadingEdge()
            .accessibilityElement(children: .combine)

            Text("Five letters share the baa shape at the start of a word (ب ت ث ن ي), and three share the haa shape (ج ح خ). Join any of the first onto any of the second and you get this one outline, fifteen ways.")
                .font(.body)

            Text("In the mushaf's hand the first letter does not sit beside the haa on the line. It rides above it as a small hook, which is why the pair is hard to recognize from the two letters you learned separately. Only the dots tell the fifteen apart: the dots on the hook belong to the first letter, and the dot in or over the bowl belongs to the second.")
                .font(.body)
        } header: {
            Text("THE SHAPE")
        }
    }

    private var tableSection: some View {
        Section {
            VStack(spacing: 0) {
                // Column heads: the three haa-shaped letters.
                HStack(spacing: 0) {
                    tableCorner

                    ForEach(Self.haaShaped, id: \.letter) { haa in
                        tableHead(letter: haa.letter, name: haa.name)
                    }
                }

                ForEach(Self.baaShaped, id: \.letter) { baa in
                    Divider()

                    HStack(spacing: 0) {
                        // The opening form, not the isolated letter: noon and yaa only look like a
                        // baa when they open a word, which is the whole reason they are in this table.
                        tableHead(letter: baa.letter + Self.tatweel, name: baa.name)

                        ForEach(Self.haaShaped, id: \.letter) { haa in
                            Text(baa.letter + haa.letter + Self.tatweel)
                                .font(uthmani(34, relativeTo: .largeTitle))
                                .arabicFontDesign(custom: true)
                                .arabicLetterTypeFloor(steps: settings.arabicLetterSizeIndex)
                                .lineLimit(1)
                                .minimumScaleFactor(0.4)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .accessibilityLabel("\(baa.name) joined to \(haa.name)")
                        }
                    }
                }
            }
            // Right to left, like the script: the row's first letter on the right, jeem's column next.
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.vertical, 2)
        } header: {
            Text("ALL 15 COMBINATIONS")
        } footer: {
            Text("Each row is one opening letter, each column the letter it joins. The trailing line (ـ) only shows that the word carries on. Shown in the Uthmani hand the mushaf is printed in; the app's own Arabic faces write the two letters side by side.")
        }
    }

    private var tableCorner: some View {
        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
    }

    private func tableHead(letter: String, name: String) -> some View {
        VStack(spacing: 0) {
            Text(letter)
                .font(uthmani(22, relativeTo: .title2))
                .arabicFontDesign(custom: true)
                .foregroundColor(settings.accentColor.color)

            if !settings.hideEnglishInArabicLetters {
                Text(name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var quranSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "نَحۡنُ",
                transliteration: "nahnu",
                note: "We: noon on Haa",
                fontName: Settings.hafsUthmaniFontName
            )
            ArabicExampleRow(
                arabic: "تَحۡتِهَا",
                transliteration: "tahtihaa",
                note: "Beneath it: taa on Haa",
                fontName: Settings.hafsUthmaniFontName
            )
            ArabicExampleRow(
                arabic: "يُحِبُّ",
                transliteration: "yuhibbu",
                note: "He loves: yaa on Haa",
                fontName: Settings.hafsUthmaniFontName
            )
            ArabicExampleRow(
                arabic: "بِحَمۡدِ",
                transliteration: "bihamdi",
                note: "With the praise of: baa on Haa",
                fontName: Settings.hafsUthmaniFontName
            )
            ArabicExampleRow(
                arabic: "تَجۡرِي",
                transliteration: "tajree",
                note: "Flows: taa on jeem",
                fontName: Settings.hafsUthmaniFontName
            )
            ArabicExampleRow(
                arabic: "يَخۡرُجُ",
                transliteration: "yakhruju",
                note: "Comes out: yaa on khaa",
                fontName: Settings.hafsUthmaniFontName
            )
        } header: {
            Text("WORDS YOU MEET IN THE QURAN")
        } footer: {
            Text("Drawn in the mushaf's own Uthmani hand, the way the Quran reader prints them, whatever your Arabic face is. Everywhere else in the app the pair is written side by side, so these rows are where to learn the stacked form.")
        }
    }
}

// MARK: - Laam alif

/// The one joined shape that is compulsory, laam onto alif, and the marks it carries: the sibling of
/// `BaaHaaShapesView` (Abu, 2026-09-22: "make another thing similar to baa shape on a haa shape" for
/// laam alif, with the two AL + hamza shapes from the laam alif letter page, ٱلۡأَ and ٱلۡأٓ). The
/// shape, the forms it takes with each kind of alif, those two shapes, and the words it is met in.
/// The reader's own face throughout: every face joins the pair, so there is no hand to insist on.
struct LaamAlifShapesView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @ObservedObject private var settings = Settings.shared

    /// Laam and alif, which every face draws as the one shape.
    static let skeleton = "\u{0644}\u{0627}"

    /// The shape with each alif it can be joined to. The joined-from-before form is last: the same
    /// ligature, hanging off the letter before it.
    private static let forms: [(form: String, name: String)] = [
        ("\u{0644}\u{0627}", "plain"),
        ("\u{0644}\u{0623}", "hamza above"),
        ("\u{0644}\u{0625}", "hamza below"),
        ("\u{0644}\u{064E}\u{0627}\u{0653}", "madd sign"),
        ("\u{0640}\u{0644}\u{0627}", "joined from before"),
    ]

    private func arabicFont(base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        settings.useFontArabic ? settings.scalableIslamArabicFont(base: base, relativeTo: style) : .system(style)
    }

    private var usesCustomFace: Bool { settings.useFontArabic && settings.islamUsesCustomArabicFace }

    var body: some View {
        List {
            Group {
                shapeSection
                formsSection
                LaamAlifHamzaSections()
                quranSection
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Laam Alif")
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                ArabicSizeSlider()
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HideEnglishToolbarButton()
            }
        }
        #endif
    }

    private var shapeSection: some View {
        Section {
            VStack(spacing: 4) {
                Text(Self.skeleton)
                    .font(arabicFont(base: 64, relativeTo: .largeTitle))
                    .arabicFontDesign(custom: usesCustomFace)
                    .arabicLetterTypeFloor(steps: settings.arabicLetterSizeIndex)
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Text("laam joined onto alif, as one shape")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .rowSeparatorFromLeadingEdge()
            .accessibilityElement(children: .combine)

            Text("When laam (ل) is followed by alif (ا), the two must be written as one joined shape: لا. It is the only compulsory ligature in Arabic script (writing them side by side unjoined is considered incorrect), which is why it is taught alongside the alphabet.")
                .font(.body)

            Text("The sound does not change: read it as laam, then the long alif. Order matters, though: the definite article ٱل is alif then laam, so no ligature forms there. Only when the alif comes second does the laam fold over it.")
                .font(.body)
        } header: {
            Text("THE SHAPE")
        }
    }

    private var formsSection: some View {
        Section {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Self.forms, id: \.name) { item in
                    VStack(spacing: 2) {
                        Text(item.form)
                            .font(arabicFont(base: 34, relativeTo: .largeTitle))
                            .arabicFontDesign(custom: usesCustomFace)
                            .arabicLetterTypeFloor(steps: settings.arabicLetterSizeIndex)
                            .foregroundColor(settings.accentColor.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .frame(height: 48)

                        if !settings.hideEnglishInArabicLetters {
                            Text(item.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
            // Right to left, like the script: the plain shape first, on the right.
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.vertical, 4)
        } header: {
            Text("ONE SHAPE, WHATEVER THE ALIF CARRIES")
        } footer: {
            Text("A hamza above or below the alif, or the madd sign over it, rides on the same shape. After a letter that joins (فَلَا, إِلَّا) the shape hangs off that letter; after one that does not (وَلَا, أَلَا) it stands on its own. Alif maqSoorah is not an alif here: لَىٰ, as in عَلَىٰ, is laam then a dotless yaa, and the two stay apart.")
        }
    }

    private var quranSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "لَا",
                transliteration: "laa",
                note: "No, not (2:2): the shape on its own"
            )
            ArabicExampleRow(
                arabic: "لَآ إِلَٰهَ إِلَّا ٱللَّهُ",
                transliteration: "laaa ilaaha illallaah",
                note: "There is no god but Allah (37:35): the madd sign, then the shaddah, on the same shape"
            )
            ArabicExampleRow(
                arabic: "أَلَا",
                transliteration: "alaa",
                note: "Unquestionably (6:31): alif, then a laam alif"
            )
            ArabicExampleRow(
                arabic: "فَلَا",
                transliteration: "falaa",
                note: "So not (2:22): hanging off the faa before it"
            )
            ArabicExampleRow(
                arabic: "وَلَا",
                transliteration: "walaa",
                note: "And not (1:7): waaw does not join, so the shape stands alone"
            )
            ArabicExampleRow(
                arabic: "ٱلۡإِنسَٰنَ",
                transliteration: "al-insaana",
                note: "Man (10:12): AL on a hamza below the alif"
            )
            ArabicExampleRow(
                arabic: "لَأَنتُمۡ",
                transliteration: "la-antum",
                note: "You are indeed (59:13): the emphatic laam on a hamza above"
            )
        } header: {
            Text("WORDS YOU MEET IN THE QURAN")
        } footer: {
            Text("These rows follow your Arabic font setting. Whichever face you read in, the laam and the alif are one shape.")
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        ArabicBasicsView()
    }
}
