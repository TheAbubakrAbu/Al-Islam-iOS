import SwiftUI

// The Tajweed Foundations pages (index: TajweedFoundations.swift), back on 2026-10-03 after ten days
// merged into the course. Their words are the 2026-09-23 pages', drawn with the article kit the way
// Pillars & Beliefs is: an opening card, checklists, word cards, key lines and a closing card in place
// of runs of plain rows. The word lists and the corrections are the course merge's
// (Scripts/tajweed_foundations.py), so neither copy carries a mistake the other fixed: شَيۡءٌ is madd
// leen in Hafs, not muttasil; ٱئۡتُواْ starts "iitu"; رَحۡمَةً stops on a ha; the 4 Sukoon video is
// the four-types short, not the Meem Sakinah one; the words are in the mushaf's own spelling.

// MARK: - Improving Your Recitation

struct TajweedImprovingRecitationView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("IMPROVING YOUR RECITATION")) {
                    ArticleLead("This guide on its own is not enough to fully develop strong tajweed and pronunciation. While it can introduce the rules and concepts, real improvement in Quranic recitation requires consistent practice, listening, and guidance from knowledgeable teachers.")

                    Text(verbatim: "Ideally, this guide should be used alongside a teacher who can listen to your recitation and correct your mistakes. Tajweed is refined through feedback and repetition, and many pronunciation errors are difficult to notice on your own. To truly benefit from this guide, approach the Quran with sincerity, humility, and love. Put your trust in Allah and be willing to learn.")
                        .font(.body)

                    Text(verbatim: "You must also set aside arrogance and ego. Even if you believe your tajweed, voice, or makharij are good, there is always room to improve. The greatest reciters spent years refining their recitation. Below are three consistent practices that will help maximize both this guide and your learning of tajweed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. PRACTICE RECITING ON YOUR OWN")) {
                    Text(verbatim: "Reading the Quran regularly on your own is essential. This type of practice helps with:")
                        .font(.body)

                    ArticleBullet(verbatim: "Increasing reading fluency and speed")
                    ArticleBullet(verbatim: "Improving familiarity with words and verses")
                    ArticleBullet(verbatim: "Experimenting with voice control and tone")
                    ArticleBullet(verbatim: "Applying corrections you have learned")

                    ArticleCallout("However, it is important to understand something: the phrase \"practice makes perfect\" is not true. Rather, perfect practice makes perfect. If someone repeatedly practices incorrect pronunciation or recites carelessly, they may reinforce mistakes instead of correcting them.",
                                   title: "Perfect Practice Makes Perfect", systemImage: "exclamationmark.triangle.fill")

                    ArticleChecklist(["Reading consistently",
                                      "Reciting carefully with proper tajweed",
                                      "Applying corrections learned from teachers or study"],
                                     title: "For this reason, solo practice should focus on:")

                    Text(verbatim: "Solo practice is essential, but it cannot fully replace proper guidance.")
                        .font(.body)

                    Text(verbatim: "This is similar to practicing a sport alone. Individual practice builds skill and stamina, but without proper technique, it will only take you so far. At the same time, even the best teacher cannot help you improve if you never put in the hours of practice yourself.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. LISTEN TO SKILLED RECITERS")) {
                    Text(verbatim: "Listening to skilled reciters is one of the most powerful ways to improve pronunciation and rhythm. Many students benefit from listening to classical Egyptian reciters such as Sheikh Muhammad Siddiq Al-Minshawi and Sheikh Mahmoud Khalil Al-Hussary.")
                        .font(.body)

                    Text(verbatim: "Both reciters are widely respected for their clarity, precision, and strong tajweed. Their recordings typically come in two styles:")
                        .font(.body)

                    ArticleTermCard("Murattal", arabic: "مُرَتَّل",
                                    meaning: "A steady, clear recitation ideal for learning.")

                    ArticleTermCard("Mujawwad", arabic: "مُجَوَّد",
                                    meaning: "A slower, melodic recitation that emphasizes precision and beauty.")

                    Text(verbatim: "Try to find a reciter whose voice you genuinely enjoy listening to. Developing a connection with a reciter often deepens your love for the Quran and increases your motivation to recite. However, do not listen passively.")
                        .font(.body)

                    ArticleChecklist(["Follow along in the mushaf while listening",
                                      "Read aloud with the reciter",
                                      "Attempt to mimic his tajweed and pronunciation",
                                      "Pay attention to letter articulation, elongation, and pauses"],
                                     title: "Instead, actively engage with the recitation:", systemImage: "ear")

                    Text(verbatim: "This is similar to studying expert athletes, learning from masters by carefully observing how they perform. You may also benefit from educational tajweed resources such as Learn Arabic 101 or other structured lessons.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. PRACTICE WITH A TEACHER OR PARTNER")) {
                    Text(verbatim: "Practicing with someone knowledgeable in tajweed is one of the most effective ways to improve your recitation. A teacher or experienced student can hear mistakes that you will not notice yourself, including:")
                        .font(.body)

                    ArticleBullet(verbatim: "Incorrect makharij (points of articulation)")
                    ArticleBullet(verbatim: "Subtle pronunciation errors")
                    ArticleBullet(verbatim: "Improper elongation (madd)")
                    ArticleBullet(verbatim: "Weak ghunnah or nasalization")
                    ArticleBullet(verbatim: "Mistakes in stopping or continuation")

                    Text(verbatim: "Corrections may sometimes feel repetitive or strict, but they are extremely valuable. Even small refinements can significantly improve your recitation. The best tajweed is the recitation that is correct and refined in all aspects, both major and subtle.")
                        .font(.body)

                    Text(verbatim: "Learning with a teacher is similar to training with a coach in sports. A coach observes your technique and gives personalized corrections that accelerate your improvement.")
                        .font(.body)

                    ArticleClosing("If a formal teacher is not available, try to practice with someone knowledgeable who has strong tajweed and is willing to listen to your recitation and offer corrections.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    TajweedVideoLink(title: "Why are you still struggling with Quran recitation?",
                                     url: "https://www.youtube.com/watch?v=_acpVGn0ys0")
                    TajweedVideoLink(title: "The best and fastest route to learn Arabic and the Quran",
                                     url: "https://www.youtube.com/watch?v=86qiFqqZSG0")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "improving-recitation", title: "Improving Your Recitation"),
                    TajweedCourseLesson(id: "levels-of-recitation", title: "Three Speeds, One Standard"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Improving Your Recitation")
    }
}

// MARK: - Lip Movement

struct TajweedLipMovementView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("NATURAL QURANIC RECITATION")) {
                    ArticleLead("One of the most common mistakes in Quranic recitation is overemphasis: exaggerating mouth movements, stretching the lips sideways, or forcing sounds in a way that is unnatural to Arabic speech. Correct tajweed is meant to preserve clarity and authenticity.")
                }

                Section(header: ArticleHeader("GENERAL MOUTH AND LIP RULE")) {
                    ArticleChecklist(["Lips move up and down only",
                                      "Avoid side stretching or exaggerated shaping",
                                      "The tongue and throat do most of the work"],
                                     title: "The General Rule")

                    Text(verbatim: "When recited correctly, Quranic Arabic should sound smooth, balanced, and natural, similar to careful classical Arabic speech.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. DAMMAH-RELATED SOUNDS (ـُ ـٌ و)")) {
                    Text(verbatim: "For all sounds related to dammah, the lips must round and project slightly forward to produce a true \"u\" sound.")
                        .font(.body)

                    TajweedKeyLine("This is the only time the lips clearly point outward.", systemImage: "exclamationmark.circle.fill")

                    ArticleChecklist(["Dammah (ـُ)", "Dammatayn (ـٌ)", "Waw sakinah preceded by dammah (ـُو)"],
                                     title: "Applies To")
                }

                Section(header: ArticleHeader("2. MIM (م): LIP CLOSURE")) {
                    Text(verbatim: "The letter mim (م) is a bilabial letter, meaning it is produced using both lips.")
                        .font(.body)

                    TajweedKeyLine("Think of the lips as folding together, not squeezing.", systemImage: "lightbulb.fill")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "lips-nasal-passage", title: "The Lips and the Nose"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Lip Movement")
    }
}

// MARK: - Tajweed Hints in the Mushaf

struct TajweedInMushafView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("TAJWEED IN THE MUSHAF")) {
                    ArticleLead("Even without a color-coded mushaf, tajweed rules are visible directly in the text. The Quran is written in a way that signals when a sound should be held, merged, hidden, or pronounced clearly, if you know what to look for.")

                    Text(verbatim: "This section teaches you how to recognize tajweed visually, before memorizing specific rules.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. LETTERS WITHOUT SUKUN (EXCLUDING MADD)")) {
                    ArticleChecklist(["It has no sukun", "And it is not a madd letter (ا و ي)"], title: "If a letter:")

                    TajweedKeyLine("Then that letter must be held, and some tajweed rule applies.", systemImage: "hand.raised.fill")

                    Text(verbatim: "This usually means: Ghunnah, Ikhfaa, Idghaam, Iqlaab, and similar rules.")
                        .font(.body)

                    TajweedWordCard("Sukoon or no sukoon", words: [
                        TajweedWord("مِنۡ", "min", note: "Nun has sukun: pronounce clearly"),
                        TajweedWord("مَن يَقُولُ", "may-yaqul", note: "No sukun on ن: merge (idghaam)"),
                        TajweedWord("عَلِيمٌ", "'alimun", note: "Tanwin and no visible sukun: apply the rule"),
                    ], size: 23)

                    Text(verbatim: "If there is no sukun, the sound does not pass quickly.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. TANWIN SHAPE")) {
                    Text(verbatim: "Tanwin always ends in a hidden nun sakinah, which is why its shape matters.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SPECIAL TANWIN MARKS IN THE MUSHAF")) {
                    Text(verbatim: "Some Uthmani tanwin marks are drawn differently to tell you whether the hidden noon sound needs a special rule.")
                        .font(.body)

                    TajweedWordCard("Version 1: special rule",
                                    note: "When the tanwin is written with the special mark, look at the next real letter and apply the noon sakinah/tanwin rule: ikhfaa, idghaam, iqlaab, or the correct ghunnah behavior.",
                                    words: [
                                        TajweedWord("رٞ", "special dammatayn", note: "Apply the next-letter rule"),
                                        TajweedWord("لٖ", "special kasratayn", note: "Apply the next-letter rule"),
                                        TajweedWord("رٗ", "special fathatayn", note: "Apply the next-letter rule"),
                                    ])

                    TajweedWordCard("Version 2: normal idhaar",
                                    note: "When the normal double vowel mark is used before an idhaar letter, pronounce the hidden noon clearly. There is no merge, concealment, or conversion.",
                                    words: [
                                        TajweedWord("نٌ", "normal dammatayn", note: "Clear idhaar"),
                                        TajweedWord("قٍ", "normal kasratayn", note: "Clear idhaar"),
                                        TajweedWord("بًا", "normal fathatayn", note: "Clear idhaar"),
                                    ])
                }

                Section(header: ArticleHeader("A. PARALLEL TANWIN → IDHAAR")) {
                    Text(verbatim: "When the two tanwin strokes are parallel, the nun is pronounced clearly.")
                        .font(.body)

                    TajweedWordCard("Stacked: the hidden noon is said clearly", words: [
                        TajweedWord("بًا", "ban"),
                        TajweedWord("بٌ", "bun"),
                        TajweedWord("بٍ", "bin"),
                        TajweedWord("قُرۡءَانًا عَرَبِيًّا", "quraanan arabiyyan"),
                    ])

                    Text(verbatim: "You hear a full, clear \"n\" sound.")
                        .font(.body)
                }

                Section(header: ArticleHeader("B. STAGGERED / CONNECTED TANWIN")) {
                    Text(verbatim: "When tanwin marks appear staggered, connected, or visually altered, this usually indicates Idghaam, Ikhfaa, or Iqlaab.")
                        .font(.body)

                    TajweedWordCard("Staggered: do not pronounce the noon normally", words: [
                        TajweedWord("أُمَّةٞ قَدۡ", "ummatun(g) qad", note: "Special dammatayn: hidden noon with ghunnah"),
                        TajweedWord("صِرَٰطٖ مُّسۡتَقِيمٖ", "siraatim-mustaqeem", note: "Special kasratayn: merged into the mim"),
                        TajweedWord("أُمَّةٗ وَسَطٗا", "ummataw-wasatan", note: "Special fathatayn: idghaam with ghunnah"),
                    ], stacked: true, size: 23)

                    TajweedKeyLine("The mushaf is telling you: do not pronounce the nun normally here.", systemImage: "exclamationmark.circle.fill")

                    Text(verbatim: "Important clarification: not every mushaf shows tanwin shapes identically, but the principle remains the same. If the tanwin does not look standard, slow down and apply a rule.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. THE LAAM OF \"AL-\" (ٱلـ)")) {
                    Text(verbatim: "The definite article \"al-\" also signals pronunciation through markings.")
                        .font(.body)

                    TajweedWordCard("A. Sukun on laam (qamariyyah)", words: [
                        TajweedWord("ٱلۡقَمَر", "al-qamar"),
                        TajweedWord("ٱلۡكِتَٰب", "al-kitab"),
                        TajweedWord("ٱلۡهُدَىٰ", "al-huda"),
                    ])

                    TajweedWordCard("B. No sukun on laam (shamsiyyah)", note: "The laam merges into the next letter.", words: [
                        TajweedWord("ٱلشَّمۡس", "ash-shams"),
                        TajweedWord("ٱلنَّاس", "an-nas"),
                        TajweedWord("ٱلرَّحۡمَٰن", "ar-rahman"),
                    ])

                    TajweedKeyLine("If you do not see a sukun, the laam is not read.", systemImage: "eye.fill")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "reading-the-script", title: "What the Script Tells You"),
                    TajweedCourseLesson(id: "tanween-shapes", title: "The Shape of the Tanween"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Tajweed Hints in the Mushaf")
    }
}

// MARK: - Makhaarij

struct TajweedMakharijView: View {
    /// The letter a tile asked to open. The tiles share List rows, so the List owns the one destination.
    @State private var door: ArabicDoor?

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("MAKHAARIJ")) {
                    ArticleLead("Makharij are the physical points of articulation from which Arabic letters are pronounced. Correct makharij are the foundation of tajweed. If the letter does not come from its proper place, no amount of rules will fix the sound.")

                    Text(verbatim: "This section focuses on awareness, not memorization. The goal is to know where a sound comes from and what moves to produce it.")
                        .font(.body)

                    Image("Makharij1")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(24)
                        .focusableImage("Makharij1", title: "Makharij al-Huruf")

                    Image("Makharij2")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(24)
                        .focusableImage("Makharij2", title: "Makharij al-Huruf")

                    Text(verbatim: "Use these diagrams as references, not something to stare at while reciting. Over time, correct makharij become muscle memory.")
                        .font(.body)
                }

                Section(header: ArticleHeader("RECOMMENDED PLAYLIST")) {
                    ArticleChecklist(["Isolated letter sounds", "Minimal exaggeration", "Clear mouth positioning"],
                                     title: "Use a clear, slow pronunciation playlist such as Learn Arabic 101 (Makharij series). Focus on:",
                                     systemImage: "ear")

                    TajweedKeyLine("Listen → imitate → repeat aloud. Silent learning does not work for makharij.", systemImage: "speaker.wave.2.fill")

                    TajweedVideoLink(title: "Makharij and sifaat, the full playlist",
                                     url: "https://www.youtube.com/watch?v=-YrfRpwFMe8&list=PL6TlMIZ5ylgpmlnN3EpkOec0tJ8OJZ5re")
                }

                Section(header: ArticleHeader("PRIMARY AREAS OF ARTICULATION")) {
                    Text(verbatim: "For learning purposes, we group makharij into three main zones.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. THROAT LETTERS (الحُرُوفُ الحَلقِيَّةُ)")) {
                    Text(verbatim: "These letters originate from the throat, not the tongue.")
                        .font(.body)

                    TajweedLetterStrip("Letters", letters: LetterTraits.halq.letters, tint: LetterTraits.halq.legendColor) { door = .letter($0) }

                    ArticleChecklist(["Deep throat: ء هـ", "Middle throat: ع ح", "Upper throat: غ خ"],
                                     title: "Sub-Zones (for awareness)", systemImage: "mappin.circle.fill")

                    ArticleChecklist(["These letters are clear and open", "No nasalization", "Do not squeeze the throat"],
                                     title: "Key Notes")

                    TajweedWordCard("Throat letters in words", words: [
                        TajweedWord("أَحَد", "ahad"),
                        TajweedWord("نَعۡبُدُ", "na'-bu-du"),
                        TajweedWord("غَفُور", "ghafur"),
                        TajweedWord("خَالِد", "khalid"),
                    ])

                    TajweedFix(wrong: "Replacing ع with أ", right: "Clear throat engagement")
                }

                Section(header: ArticleHeader("2. TONGUE LETTERS (أَغلَبُ الحُرُوفِ)")) {
                    Text(verbatim: "Most Arabic letters come from the tongue, but different parts of the tongue.")
                        .font(.body)

                    ArticleChecklist(["Back of tongue: ق ك",
                                      "Middle of tongue: ج ش ي",
                                      "Sides of tongue: ض",
                                      "Tip of tongue: ت د ط ن ل ر س ز ص ث ذ ظ"],
                                     title: "Tongue Zones (Simplified)", systemImage: "mappin.circle.fill")

                    ArticleChecklist(["Small shifts in tongue position matter", "Do not force pressure", "Accuracy over strength"],
                                     title: "Key Notes")

                    TajweedWordCard("Tongue letters in words", words: [
                        TajweedWord("قُلۡ", "qul"),
                        TajweedWord("سَمِيع", "samee'"),
                        TajweedWord("نُور", "nur"),
                        TajweedWord("رَبِّ", "rabbi"),
                    ])

                    TajweedFix(wrong: "Collapsing multiple letters into one sound", right: "Distinct articulation for each letter")
                }

                Section(header: ArticleHeader("3. LIP LETTERS (الحُرُوفُ الشَّفَوِيَّةُ)")) {
                    Text(verbatim: "These letters are produced using the lips.")
                        .font(.body)

                    TajweedLetterStrip("Letters", letters: LetterTraits.shafatan.letters, tint: LetterTraits.shafatan.legendColor) { door = .letter($0) }

                    ArticleChecklist(["\u{200E}ب: full lip closure",
                                      "\u{200E}م: lip closure + nasal sound",
                                      "\u{200E}ف: upper teeth lightly touch lower lip",
                                      "\u{200E}و: both lips rounded and pushed forward, never closing (as a consonant; the long vowel waaw comes from the empty space of the mouth)"],
                                     title: "How They Work", systemImage: "mouth.fill")

                    TajweedWordCard("Lip letters in words", words: [
                        TajweedWord("بَصِير", "basir"),
                        TajweedWord("أَمۡر", "amr"),
                        TajweedWord("فِيهِ", "fihi"),
                    ])

                    TajweedFix(wrong: "Weak or lazy lip contact", right: "Gentle, controlled movement")
                }

                Section(header: ArticleHeader("IMPORTANT PRACTICE ADVICE")) {
                    Text(verbatim: "Makharij are learned by sound, not sight.")
                        .font(.body)

                    Text(verbatim: "If you cannot hear the difference, slow down and exaggerate slightly during practice, then return to natural recitation.")
                        .font(.body)

                    Text(verbatim: "Correct makharij preserve the Quran exactly as it was revealed.")
                        .font(.body)

                    ArticleClosing("Tajweed rules refine the sound. Makharij create it.")
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.jawf)
                    TajweedFamilyRow(LetterTraits.halq)
                    TajweedFamilyRow(LetterTraits.aqsaLisan)
                    TajweedFamilyRow(LetterTraits.wasatLisan)
                    TajweedFamilyRow(LetterTraits.haffatLisan)
                    TajweedFamilyRow(LetterTraits.tarafLisan)
                    TajweedFamilyRow(LetterTraits.shafatan)

                    GuardedScreenLink(screen: .letterFamilies, id: "makhraj") {
                        LetterFamiliesView(title: "Makharij", axes: [.makhraj])
                            .openScreen(.letterFamilies, id: "makhraj")
                    } label: {
                        TajweedLinkLabel(systemImage: "list.number", title: "The Seventeen Exits in Full",
                                         caption: "Every exit, with the letters made there")
                    }
                } header: {
                    ArticleHeader("ON THE ALPHABET")
                } footer: {
                    Text("The seven zones, deepest first. Every letter page names the exact point its letter is made at.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "makharij-overview", title: "The Seventeen Exits"),
                    TajweedCourseLesson(id: "throat-letters", title: "The Throat: Three Exits, Six Letters"),
                    TajweedCourseLesson(id: "tongue-regions", title: "The Tongue: Ten Exits"),
                    TajweedCourseLesson(id: "lips-nasal-passage", title: "The Lips and the Nose"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .arabicDoorDestination($door)
        .navigationTitle("Makhaarij")
    }
}

// MARK: - Heavy and Light

struct TajweedHeavyLightView: View {
    /// The letter a tile asked to open. The tiles share List rows, so the List owns the one destination.
    @State private var door: ArabicDoor?

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("HEAVY AND LIGHT")) {
                    ArticleLead("Arabic letters differ in weight (heavy tafkhim vs light tarqiq). Some letters are always heavy, some are always light, and some are conditional, meaning the weight changes based on context.")

                    Text(verbatim: "Correct letter weight is essential for accurate pronunciation and natural recitation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. HEAVY LETTERS (تَفخِيم)")) {
                    Text(verbatim: "These letters are always heavy, regardless of the vowel.")
                        .font(.body)

                    TajweedLetterStrip("Always Heavy Letters", letters: LetterTraits.heavy.letters, tint: LetterTraits.heavy.legendColor) { door = .letter($0) }

                    ArticleChecklist(["The back of the tongue raised", "A full, deep sound", "No thinning, even with kasrah"],
                                     title: "They are pronounced with:")

                    TajweedWordCard("Always heavy", words: [
                        TajweedWord("قَالَ", "qala"),
                        TajweedWord("صِرَٰط", "sirat"),
                        TajweedWord("طَبَعَ", "ta-ba-'a"),
                        TajweedWord("غَفُور", "ghafur"),
                        TajweedWord("خَالِد", "khalid"),
                    ])
                }

                Section(header: ArticleHeader("2. LIGHT LETTERS (تَرقِيق)")) {
                    Text(verbatim: "These letters are always light and never pronounced heavy.")
                        .font(.body)

                    TajweedLetterStrip("Always Light Letters", letters: LetterTraits.light.letters, tint: LetterTraits.light.legendColor) { door = .letter($0) }

                    ArticleChecklist(["A relaxed tongue", "No back-tongue elevation", "Clear, sharp articulation"],
                                     title: "They are pronounced with:")

                    TajweedWordCard("Always light", words: [
                        TajweedWord("بِسۡم", "bism"),
                        TajweedWord("نَعِيم", "na-'eem"),
                        TajweedWord("سَبِيل", "sabil"),
                        TajweedWord("يَوۡم", "yawm"),
                        TajweedWord("فِيهِ", "fihi"),
                    ])

                    TajweedKeyLine("Note: Laam (ل) and waw (و) are light by default, but laam becomes conditional in one specific case: Allah.", systemImage: "info.circle.fill")
                }

                Section(header: ArticleHeader("3. CONDITIONAL LETTERS")) {
                    Text(verbatim: "These letters change weight depending on vowels or surrounding letters.")
                        .font(.body)
                }

                Section(header: ArticleHeader("A. RAA (ر)")) {
                    Text(verbatim: "The weight of raa depends on the vowel on the raa itself.")
                        .font(.body)

                    TajweedWordCard("Heavy Raa", note: "With fathah (ـَ) or dammah (ـُ)", words: [
                        TajweedWord("رَبِّ", "rabbi"),
                        TajweedWord("رُزِقُوا", "ruziqu"),
                        TajweedWord("قَرَأَ", "qaraa"),
                    ])

                    TajweedWordCard("Light Raa", note: "Raa with kasrah (ـِ), or raa with sukoon preceded by an ORIGINAL kasrah, unless an isti'la letter with fatha/damma follows it in the same word (قِرۡطَاس, مِرۡصَاد), which makes it heavy again.", words: [
                        TajweedWord("فِرۡعَوۡن", "firawn"),
                        TajweedWord("رِجَال", "rijal"),
                        TajweedWord("شِرۡعَة", "shirah"),
                    ])

                    TajweedKeyLine("Rule of thumb: if the raa carries a vowel, look at that vowel. If the raa is sakin, look at the letter BEFORE it, and at what follows, for the isti'la exception.", systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader("B. LAAM (ل)")) {
                    Text(verbatim: "The letter laam is always light, except in the word Allah (ٱللَّه).")
                        .font(.body)

                    TajweedWordCard("Heavy Laam (Only in \"Allah\")", note: "When preceded by fathah or dammah:", words: [
                        TajweedWord("ٱللَّهُ", "Allahu"),
                        TajweedWord("قَالَ ٱللَّهُ", "qala Allahu"),
                        TajweedWord("نَصۡرُ ٱللَّهِ", "nasru Allahi"),
                    ])

                    TajweedWordCard("Light Laam (After Kasrah)", words: [
                        TajweedWord("بِٱللَّهِ", "billahi"),
                        TajweedWord("لِلَّهِ", "lillahi"),
                    ])
                }

                Section(header: ArticleHeader("C. ALIF (ا)")) {
                    Text(verbatim: "Alif itself has no sound; it inherits the weight of the letter before it.")
                        .font(.body)

                    ArticleBullet(verbatim: "After a heavy letter → alif sounds heavy")
                    ArticleBullet(verbatim: "After a light letter → alif sounds light")

                    TajweedWordCard("Alif follows the letter before it", words: [
                        TajweedWord("قَالَ", "qala", note: "Heavy letter (ق)"),
                        TajweedWord("صَادِق", "sadiq", note: "Heavy letter (ص)"),
                        TajweedWord("كَانَ", "kana", note: "Light letter (ك)"),
                        TajweedWord("نَاس", "nas", note: "Light letter (ن)"),
                    ])

                    TajweedFix(wrong: "Making alif heavy by itself", right: "Alif follows, never leads")
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.heavy)
                    TajweedFamilyRow(LetterTraits.light)
                    TajweedFamilyRow(LetterTraits.conditionalWeight)
                    TajweedFamilyRow(LetterTraits.followsPrevious)
                    TajweedFamilyRow(LetterTraits.istila)
                    TajweedFamilyRow(LetterTraits.itbaq)
                } header: {
                    ArticleHeader("ON THE ALPHABET")
                } footer: {
                    Text("Heaviness comes from two qualities: the tongue rising (isti\u{2019}la), and for the heaviest four, clamping as well (itbaq).")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "heavy-light-letters", title: "Heavy and Light"),
                    TajweedCourseLesson(id: "ra-tafkheem-tarqeeq", title: "The Ra, Case by Case"),
                    TajweedCourseLesson(id: "lafz-al-jalalah", title: "The Lam of the Name of Allah"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .arabicDoorDestination($door)
        .navigationTitle("Heavy and Light")
    }
}

// MARK: - Shams and Qamar

struct TajweedShamsQamarView: View {
    /// The letter a tile asked to open. The tiles share List rows, so the List owns the one destination.
    @State private var door: ArabicDoor?

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SHAMS AND QAMAR")) {
                    ArticleLead("When the definite article ٱلـ (al-) appears before a noun, the pronunciation of the laam (ل) depends on the first letter of the word that follows.")

                    Text(verbatim: "The mushaf clearly indicates this through shaddah or sukun.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. QAMARIYYAH (MOON LETTERS)")) {
                    Text(verbatim: "With qamariyyah letters, the laam is pronounced clearly.")
                        .font(.body)

                    ArticleChecklist(["The laam has a sukun (ٱلۡ)", "The sound is al-"], title: "Rule")

                    TajweedLetterStrip("Qamariyyah Letters",
                                       note: "The classic list opens with an alif. It is really the hamza, as in ٱلۡأَرۡض: no word begins with a bare alif.",
                                       letters: LetterTraits.moonLetters.letters, tint: LetterTraits.moonLetters.legendColor) { door = .letter($0) }

                    TajweedWordCard("Moon letters: the laam is read", words: [
                        TajweedWord("ٱلۡقَمَر", "al-qamar"),
                        TajweedWord("ٱلۡكِتَٰب", "al-kitab"),
                        TajweedWord("ٱلۡحَقّ", "al-haqq"),
                        TajweedWord("ٱلۡغَفُور", "al-ghafur"),
                        TajweedWord("ٱلۡيَوۡم", "al-yawm"),
                    ])

                    TajweedFix(wrong: "Dropping the laam", right: "Pronouncing al-")
                }

                Section(header: ArticleHeader("2. SHAMSIYYAH (SUN LETTERS)")) {
                    Text(verbatim: "With shamsiyyah letters, the laam is not pronounced. Instead, it merges into the following letter, which is doubled (shown by a shaddah).")
                        .font(.body)

                    ArticleChecklist(["No sukun on the laam",
                                      "The next letter has a shaddah",
                                      "Pronounce the word as if it begins with the doubled letter"],
                                     title: "Rule")

                    TajweedLetterStrip("Shamsiyyah Letters", letters: LetterTraits.sunLetters.letters, tint: LetterTraits.sunLetters.legendColor) { door = .letter($0) }

                    TajweedWordCard("Sun letters: the laam merges", words: [
                        TajweedWord("ٱلشَّمۡس", "ash-shams"),
                        TajweedWord("ٱلنَّاس", "an-nas"),
                        TajweedWord("ٱلرَّحۡمَٰن", "ar-rahman"),
                        TajweedWord("ٱلصِّرَٰط", "as-sirat"),
                        TajweedWord("ٱلتَّوۡبَة", "at-tawbah"),
                    ])

                    TajweedFix(wrong: "al-shams", right: "ash-shams")
                }

                Section(header: ArticleHeader("IMPORTANT NOTES")) {
                    ArticleBullet(verbatim: "This rule applies only to the definite article ٱلـ, not to every laam.")
                    ArticleBullet(verbatim: "The shaddah is your visual cue: if you see it, the laam is not read.")
                    ArticleBullet(verbatim: "This is idghaam of the laam, not deletion.")

                    ArticleClosing("If you see a shaddah, the laam is gone.")
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.sunLetters)
                    TajweedFamilyRow(LetterTraits.moonLetters)
                } header: {
                    ArticleHeader("ON THE ALPHABET")
                } footer: {
                    Text("Every letter page says which side it is on, with a word from the Quran.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "lam-shamsiyyah-qamariyyah", title: "The Lam of ال: Sun and Moon"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .arabicDoorDestination($door)
        .navigationTitle("Shams and Qamar")
    }
}

// MARK: - Madd

struct TajweedMaddView: View {
    /// The letter a tile asked to open. The tiles share List rows, so the List owns the one destination.
    @State private var door: ArabicDoor?

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("MADD")) {
                    ArticleLead("Madd means to lengthen a sound. In Quranic recitation, this lengthening is measured, consistent, and rule-based, not stylistic.")

                    TajweedKeyLine("Madd is counted in harakat (counts).", systemImage: "timer")
                }

                Section(header: ArticleHeader("1. MADD TABII (NATURAL)")) {
                    Text(verbatim: "This is the default madd. If no special condition follows, this is what you apply.")
                        .font(.body)

                    ArticleChecklist(["Alif (ا) preceded by fathah",
                                      "Waw (و) preceded by dammah",
                                      "Yaa (ي) preceded by kasrah",
                                      "No hamzah or sukun after"],
                                     title: "When It Occurs")

                    TajweedKeyLine("Length: 2 counts", systemImage: "timer")

                    TajweedWordCard("Natural madd, two counts", words: [
                        TajweedWord("قَالَ", "qa-la"),
                        TajweedWord("يَقُولُ", "ya-qu-lu"),
                        TajweedWord("فِيهِ", "fi-hi"),
                        TajweedWord("نُور", "nur"),
                    ])

                    Text(verbatim: "If nothing special comes after, 2 counts, no more, no less.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. MADD WAJIB MUTTASIL")) {
                    ArticleChecklist(["A madd letter", "Followed by a hamzah", "In the same word"],
                                     title: "When It Occurs")

                    TajweedKeyLine("Length: 4 or 5 counts (be consistent)", systemImage: "timer")

                    TajweedWordCard("Madd letter, then a hamzah in the same word", words: [
                        TajweedWord("جَآءَ", "jaaa"),
                        TajweedWord("ٱلسَّمَآءِ", "as-samaaa"),
                        TajweedWord("سُوٓءَ", "suuu"),
                    ])

                    Text(verbatim: "It is called wajib because the lengthening is mandatory.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. MADD JAIZ MUNFASIL")) {
                    ArticleChecklist(["A madd letter at the end of a word", "Followed by a hamzah", "In the next word"],
                                     title: "When It Occurs")

                    TajweedKeyLine("Length: 2, 4, or 5 counts (be consistent)", systemImage: "timer")

                    Text(verbatim: "Choose one and stay consistent.")
                        .font(.body)

                    TajweedWordCard("Madd letter ending one word, hamzah beginning the next", words: [
                        TajweedWord("فِيٓ أَنفُسِكُمۡ", "fi an-fu-si-kum"),
                        TajweedWord("قَالُوٓاْ إِنَّا", "qalu in-na"),
                        TajweedWord("إِنَّآ أَعۡطَيۡنَٰكَ", "in-naa a'-tay-naa-ka"),
                    ])

                    Text(verbatim: "If you lengthen it, always lengthen it. If you keep it short, always keep it short.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3B. MADD MUNFASIL HUKMI (RULED SEPARATED)")) {
                    Text(verbatim: "A special, \u{201C}ruled\u{201D} (hukmi) form of Madd Munfasil. The madd letter and the hamzah are written inside one word, so it looks like Madd Muttasil, but it is recited as a separated madd.")
                        .font(.body)

                    ArticleCallout(paragraphs: ["The madd letter is actually the tail of a small joined particle, the vocative يَا (\u{201C}O \u{2026}\u{201D}) or the demonstrative هَا (\u{201C}here/these \u{2026}\u{201D}), and the hamzah begins the word it is attached to. So in meaning it is two words, even though the script joins them."],
                                   title: "Why It Is Separated", systemImage: "questionmark.circle.fill")

                    ArticleChecklist(["A superscript madd letter, dagger alif (\u{0640}\u{0670}), small waw (\u{0640}\u{06E5}), or small yaa (\u{0640}\u{06E6}), carrying a maddah (\u{0640}\u{0653})",
                                      "Immediately followed by a hamzah in the SAME written word",
                                      "The carrier is the tail of a joined يَا or هَا particle"],
                                     title: "How To Spot It", systemImage: "magnifyingglass.circle.fill")

                    TajweedKeyLine("Length: 2, 4, or 5 counts (treated exactly like Madd Munfasil; be consistent)", systemImage: "timer")

                    TajweedWordCard("Joined in writing, separated in ruling", words: [
                        TajweedWord("يَٰٓأَيُّهَا", "ya + ayyuha", note: "O you…"),
                        TajweedWord("هَٰٓأَنتُمۡ", "ha + antum", note: "here you are"),
                        TajweedWord("يَٰٓإِبۡرَٰهِيمُ", "ya + Ibrahim", note: "O Abraham"),
                        TajweedWord("يَٰٓـَٔادَمُ", "ya + Adam", note: "O Adam"),
                    ])

                    TajweedWordCard("One Word Can Hold Two Different Madds",
                                    note: "Do not assume every long madd in these words is hukmi. The word هَٰٓؤُلَآءِ contains BOTH:",
                                    words: [
                                        TajweedWord("هَٰٓؤُ", "Madd Munfasil Hukmi", note: "The joined هَا particle"),
                                        TajweedWord("لَآءِ", "A true Madd Muttasil", note: "A real alif + hamzah in one word"),
                                    ])

                    Text(verbatim: "Only the superscript-particle sequence is munfasil hukmi. Every other madd in the word follows the normal rules.")
                        .font(.body)

                    TajweedArabicLine("هَٰٓأَنتُمۡ · هَٰٓؤُلَآءِ · أَهَٰٓؤُلَآءِ · وَهَٰٓؤُلَآءِ · يَٰٓـَٔادَمُ · وَيَٰٓـَٔادَمُ · يَٰٓأَبَانَا · يَٰٓأَبَتِ · يَٰٓإِبۡرَٰهِيمُ · يَٰٓإِبۡلِيسُ · يَٰٓأُخۡتَ · يَٰٓأَرۡضُ · يَٰٓأَسَفَىٰ · يَٰٓأَهۡلَ · يَٰٓأُوْلِي · يَٰٓأَيَّتُهَا · يَٰٓأَيُّهَ · يَٰٓأَيُّهَا",
                                      title: "The Complete Set In The Qur\u{2019}an",
                                      caption: "Counting orthographic variants such as يَٰٓأَبَانَآ and the pause-mark forms, this is 21 written words in the Hafs muṣḥaf.",
                                      size: 21)
                }

                Section(header: ArticleHeader("3C. OTHER MADD TYPES & EXCEPTIONS")) {
                    Text(verbatim: "Several named madds and special cases sit alongside the main five. They matter for accurate recitation and for any rule engine.")
                        .font(.body)

                    TajweedWordCard("Madd Badal: hamzah BEFORE the madd",
                                    note: "A hamzah followed by a madd letter (the reverse of muttasil). Read 2 counts; it is not lengthened like muttasil.",
                                    words: [
                                        TajweedWord("ءَامَنُواْ", "aa-manu"),
                                        TajweedWord("ءَادَمَ", "aa-dama"),
                                    ])

                    TajweedWordCard("Madd \u{02BF}Iwad: tanwin fath at a stop",
                                    note: "When you stop on a word ending in tanwin fath (\u{0640}\u{064B}), the tanwin drops and the alif is stretched 2 counts. It is not aarid lis-sukoon.",
                                    words: [
                                        TajweedWord("عَلِيمًا", "stop: a-li-maa"),
                                        TajweedWord("غَفُورًا", "stop: gha-fu-raa"),
                                    ])

                    TajweedWordCard("Madd Tamkin: doubled yaa",
                                    note: "A kasrah + shaddah yaa meeting a madd yaa. Read 2 counts, taking care not to swallow either yaa.",
                                    words: [
                                        TajweedWord("ٱلنَّبِيِّـۧنَ", "an-nabiy-yiin"),
                                        TajweedWord("حُيِّيتُم", "huy-yi-tum"),
                                    ])

                    TajweedWordCard("Madd Silah: the pronoun haa",
                                    note: "The attached pronoun \u{0647} (\u{201C}his/its\u{201D}) between two voweled letters is given a hidden waw/yaa. Sughra (small) is 2 counts; Kubra (large) is 4\u{2013}5 counts when a hamzah follows; it then behaves like Madd Munfasil.",
                                    words: [
                                        TajweedWord("إِنَّهُۥ كَانَ", "sughra: in-na-hu"),
                                        TajweedWord("بِهِۦٓ أَحَدٗا", "kubra: bi-hii (before hamzah)"),
                                    ])

                    ArticleCallout(paragraphs: ["Superscript madd marks, dagger alif (\u{0640}\u{0670}), small waw (\u{0640}\u{06E5}), small yaa (\u{0640}\u{06E6}), are still a 2-count natural madd even though they are written tiny. When such a mark also carries a maddah (\u{0640}\u{0653}) and a hamzah follows, it becomes the munfasil-hukmi case above."],
                                   title: "Dagger Alif & Tiny Madd Marks", systemImage: "info.circle.fill")

                    TajweedWordCard("Genuine Muttasil Written With A Dagger Alif",
                                    note: "Not every dagger alif + hamzah is hukmi. When both sit inside one true word (no joined يَا/هَا particle), it is ordinary Madd Muttasil, for example أُوْلَٰٓئِكَ, مَلَٰٓئِكَة, and إِسۡرَٰٓءِيل.",
                                    words: [
                                        TajweedWord("أُوْلَٰٓئِكَ", "muttasil: ula-aa-ika"),
                                        TajweedWord("مَلَٰٓئِكَةِ", "muttasil: mala-aa-ikah"),
                                    ])
                }

                Section(header: ArticleHeader("4. ENDING MADD")) {
                    Text(verbatim: "Ending madd applies when you stop on a word and the ending sound changes because of waqf. It includes Madd Aarid lis-Sukoon and Madd Leen.")
                        .font(.body)

                    ArticleChecklist(["A sakin yaa or sakin waaw", "Preceded by fathah", "You stop on the word"],
                                     title: "Madd Leen")

                    TajweedWordCard("Leen letters, lengthened only at a stop", words: [
                        TajweedWord("خَوۡف", "khawf"),
                        TajweedWord("بَيۡت", "bayt"),
                        TajweedWord("قُرَيۡش", "quraysh"),
                        TajweedWord("شَيۡءٌ", "shay'"),
                    ])

                    // The correction the course merge made (2026-09-23): the old page listed شَيۡءٌ as a
                    // muttasil example, but in Hafs its ya is a leen letter.
                    TajweedFix(wrong: "Stretching the ya of شَيۡءٌ while reading on, as if it were a joined madd.",
                               right: "In Hafs it is a leen letter: no length while reading on, and 2, 4 or 6 counts only at a stop.")

                    TajweedWordCard("Madd Aarid lis-Sukoon", words: [
                        TajweedWord("ٱلۡعَٰلَمِينَ", "stop: a temporary sukoon on the ن"),
                        TajweedWord("ٱلرَّحِيمِ", "stop: ٱلرَّحِيمۡ"),
                        TajweedWord("نَسۡتَعِينُ", "stop: a temporary sukoon on the ن"),
                    ])

                    TajweedKeyLine("Length: 2, 4, or 6 counts. Madd Leen should follow the stopping style you choose for Madd Aarid lis-Sukoon, and should not be longer than it.", systemImage: "timer")
                }

                Section(header: ArticleHeader("5. MADD LAZIM")) {
                    Text(verbatim: "This is the strongest and longest madd.")
                        .font(.body)

                    ArticleChecklist(["A madd letter", "Followed by a permanent sukun", "Either in a word or a letter name"],
                                     title: "When It Occurs")

                    TajweedKeyLine("Length: 6 counts (always)", systemImage: "timer")

                    TajweedWordCard("A. Madd Lazim Harfi",
                                    note: "Occurs in the disconnected letters at the start of some surahs. If the letter name itself contains a madd followed by sukun, it is 6 counts.",
                                    words: [
                                        TajweedWord("الٓمٓ", "Alif (no madd) Laaaaaam (6) Miiiiiim (6)"),
                                        TajweedWord("كٓهيعٓصٓ", "Kaaaaaaf (6) Haa (2) Yaa (2) 'Ayyyn (4-6) Saaaaaad (6)"),
                                        TajweedWord("حمٓ", "Haa (2) Miiiiiim (6)"),
                                    ], stacked: true)

                    TajweedWordCard("B. Madd Lazim Kalimi", note: "Less common, but very important.", words: [
                        TajweedWord("ٱلضَّآلِّينَ", "ad-daaallin"),
                        TajweedWord("ٱلطَّآمَّةُ", "at-taaammah"),
                    ])
                }

                Section(header: ArticleHeader("OPENING LETTERS (MUQATTA’AT)")) {
                    Text(verbatim: "Some opening letters do not contain madd. Not every opening letter is lengthened. Read the letter name.")
                        .font(.body)

                    ArticleChecklist(["\u{200E}ألف (alone): no madd"], title: "Read Normally (No Madd)", systemImage: "minus.circle.fill")

                    ArticleChecklist(["6 counts: نقص عسلكم", "2 counts: حي طهر", "'Ayn (ع) is a leen letter: 4 or 6 counts."],
                                     title: "Have Madd", systemImage: "timer")

                    // Tiles, not a line of text: each letter opens its own page (Abu, 2026-09-20).
                    TajweedLetterStrip("6 counts", letters: LetterTraits.openersSix.letters, tint: LetterTraits.openersSix.legendColor) { door = .letter($0) }

                    TajweedLetterStrip("2 counts", letters: LetterTraits.openersTwo.letters, tint: LetterTraits.openersTwo.legendColor) { door = .letter($0) }
                }

                Section(header: ArticleHeader("KEY TEACHING RULES")) {
                    ArticleCallout(paragraphs: ["Madd is measured, not emotional. Do not stretch because it sounds nice.",
                                                "Consistency matters more than length. 4 everywhere is better than random 2-6.",
                                                "Never add a jump or break mid-madd. One smooth airflow from start to finish."],
                                   title: "Remember", systemImage: "lightbulb.fill")
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.maddLetters)
                    TajweedFamilyRow(LetterTraits.leen)
                    TajweedFamilyRow(LetterTraits.openersSix)
                    TajweedFamilyRow(LetterTraits.openersTwo)
                } header: {
                    ArticleHeader("ON THE ALPHABET")
                } footer: {
                    Text("Open a family for its letters and the phrase that gathers them.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "mudood-chart", title: "The Whole Map"),
                    TajweedCourseLesson(id: "madd-tabii", title: "Madd Tabi'i: The Natural Length"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .arabicDoorDestination($door)
        .navigationTitle("Madd")
    }
}

// MARK: - Qalqalah

struct TajweedQalqalahView: View {
    /// The letter a tile asked to open. The tiles share List rows, so the List owns the one destination.
    @State private var door: ArabicDoor?

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("QALQALAH")) {
                    ArticleLead("Qalqalah is a natural bouncing sound that occurs when certain letters are in a sukun state. It is not a vowel and not silence.")

                    Text(verbatim: "Its purpose is to prevent the sound from becoming cut off or broken.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE FIVE LETTERS")) {
                    // Tiles, not a line of text: each letter opens its own page (Abu, 2026-09-20).
                    TajweedLetterStrip("The qalqalah letters are:", letters: LetterTraits.qalqalah.letters,
                                       tint: LetterTraits.qalqalah.legendColor) { door = .letter($0) }
                }

                Section(header: ArticleHeader("WHAT QALQALAH IS (AND IS NOT)")) {
                    ArticleChecklist(["A slight echo", "Natural and effortless"], title: "It Is")

                    ArticleChecklist(["Not a fathah", "Not an added vowel", "Not exaggerated"],
                                     title: "It Is Not", systemImage: "xmark.circle.fill")

                    TajweedKeyLine("Think of it as releasing the letter, not opening the mouth.", systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader("WHEN QALQALAH OCCURS")) {
                    ArticleChecklist(["Has a sukun, or", "Is stopped on (waqf)"],
                                     title: "Qalqalah occurs when one of the five letters:")

                    TajweedWordCard("A sakin qalqalah letter, bounced", words: [
                        TajweedWord("أَحَدۡ", "aha(d)"),
                        TajweedWord("يَجۡعَل", "ya(j)-'al"),
                        TajweedWord("أَجۡر", "a(j)r"),
                        TajweedWord("يَقۡطَع", "ya(q)ta'"),
                        TajweedWord("يَبۡتَغُون", "ya(b)taghun"),
                    ])

                    TajweedKeyLine("Notice: the sound is heard, but no vowel is added.", systemImage: "ear")
                }

                Section(header: ArticleHeader("WHY QALQALAH EXISTS")) {
                    ArticleBullet(verbatim: "Without qalqalah, the letter would sound cut off.")
                    ArticleBullet(verbatim: "Without qalqalah, words would sound unnatural or unclear.")

                    ArticleChecklist(["Clarity", "Letter identity", "Flow of speech"], title: "Qalqalah preserves:")

                    Text(verbatim: "Qalqalah exists because Arabic does not allow these letters to die silently.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IMPORTANT REMINDER")) {
                    ArticleClosing("Qalqalah is a sound, not a vowel. If it sounds like \"a\", it is wrong. If it disappears, it is also wrong.")
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.qalqalah)
                    TajweedFamilyRow(LetterTraits.shiddah)
                    TajweedFamilyRow(LetterTraits.jahr)
                } header: {
                    ArticleHeader("ON THE ALPHABET")
                } footer: {
                    Text("Why these five: each stops the sound (shiddah) and holds back the breath (jahr), so only a bounce can make it heard.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "qalqalah", title: "Qalqalah: The Five That Bounce"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .arabicDoorDestination($door)
        .navigationTitle("Qalqalah")
    }
}

// MARK: - Noon Sakinah and Tanween

struct TajweedIdghamIkhfaView: View {
    /// The letter a tile asked to open. The tiles share List rows, so the List owns the one destination.
    @State private var door: ArabicDoor?

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("NOON SAKINAH AND TANWEEN")) {
                    ArticleLead("Tanween and noon saakinah are closely related, so this section groups the merge and hidden-sound rules together.")
                }

                Section(header: ArticleHeader("TANWEEN PRONUNCIATION")) {
                    Text(verbatim: "Although tanween appears as vowel marks, it is pronounced as a hidden noon sound (نْ) at the end of the word.")
                        .font(.body)

                    TajweedWordCard("Tanween is said as a noon", words: [
                        TajweedWord("بًا", "ban, said as بَنۡ"),
                        TajweedWord("بٌ", "bun, said as بُنۡ"),
                        TajweedWord("بٍ", "bin, said as بِنۡ"),
                    ])

                    Text(verbatim: "What happens to this hidden sound depends entirely on the letter that follows.")
                        .font(.body)
                }

                Section(header: ArticleHeader("MUSHAF TANWEEN HINTS")) {
                    Text(verbatim: "The Mushaf often hints whether tanween is normal idhaar or whether a special noon sakinah rule is coming.")
                        .font(.body)

                    TajweedWordCard("Two ways of writing tanween", words: [
                        TajweedWord("رٞ  لٖ  رٗ", "special tanween marks", note: "Apply ikhfaa, idghaam, iqlaab, or ghunnah by the next letter"),
                        TajweedWord("نٌ  قٍ  بً", "normal tanween marks", note: "Usually clear idhaar when followed by idhaar letters"),
                    ])
                }

                Section(header: ArticleHeader("1. IDHAAR (CLEAR)")) {
                    Text(verbatim: "The noon sound is pronounced clearly and fully, with no ghunnah merge.")
                        .font(.body)

                    // Tiles, not a line of text: each letter opens its own page (Abu, 2026-09-20).
                    TajweedLetterStrip("Letters", letters: LetterTraits.idhaar.letters, tint: LetterTraits.idhaar.legendColor) { door = .letter($0) }

                    TajweedWordCard("Example", words: [TajweedWord("مِنۡ هَادٍ", "min hadin")])

                    Text(verbatim: "The throat letters prevent merging, so the sound must remain clear.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. IDGHAAM (MERGING)")) {
                    Text(verbatim: "The noon sound merges into the following letter.")
                        .font(.body)

                    TajweedLetterStrip("Letters", letters: LetterTraits.idghamGhunnah.letters + LetterTraits.idghamBilaGhunnah.letters) { door = .letter($0) }

                    TajweedLetterStrip("With Ghunnah", letters: LetterTraits.idghamGhunnah.letters, tint: LetterTraits.idghamGhunnah.legendColor) { door = .letter($0) }

                    TajweedLetterStrip("Without Ghunnah", letters: LetterTraits.idghamBilaGhunnah.letters, tint: LetterTraits.idghamBilaGhunnah.legendColor) { door = .letter($0) }

                    TajweedWordCard("Examples", words: [
                        TajweedWord("مَن يَقُولُ", "may-yaqul", note: "Idghaam with ghunnah"),
                        TajweedWord("مِّن رَّبِّهِمۡ", "mir-rabbihim", note: "Idghaam without ghunnah"),
                    ])

                    Text(verbatim: "With ghunnah: nasal sound. Without ghunnah: clean merge, no nasalization.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. IQLAAB (CONVERSION)")) {
                    Text(verbatim: "The noon sound changes into a miim with ghunnah.")
                        .font(.body)

                    TajweedLetterStrip("Letter", letters: LetterTraits.iqlaab.letters, tint: LetterTraits.iqlaab.legendColor) { door = .letter($0) }

                    TajweedWordCard("Example", words: [TajweedWord("سَمِيعُۢ بَصِيرٌ", "sami'um-basir")])

                    Text(verbatim: "The noon is not pronounced. It becomes a hidden miim.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. IKHFAA (HIDDEN)")) {
                    Text(verbatim: "The noon is hidden, pronounced with ghunnah, without full clarity or full merging.")
                        .font(.body)

                    TajweedLetterStrip("Letters",
                                       note: "The remaining 15 letters: all except the idhaar, idghaam, and iqlaab letters.",
                                       letters: LetterTraits.ikhfaa.letters, tint: LetterTraits.ikhfaa.legendColor) { door = .letter($0) }

                    TajweedWordCard("Example", words: [TajweedWord("مِن شَرِّ", "min-sharri (nasal)")])

                    Text(verbatim: "The tongue does not fully touch the articulation point.")
                        .font(.body)
                }

                Section(header: ArticleHeader("GHUNNAH STRENGTH")) {
                    Text(verbatim: "Not all ghunnah is the same strength.")
                        .font(.body)

                    ArticleStep("1. **Strongest:** Noon or Miim with shaddah (نّ / مّ)")
                    ArticleStep("2. **Medium:** Idghaam with ghunnah, then Ikhfaa")
                    ArticleStep("3. **None:** Idghaam without ghunnah")
                }

                Section(header: ArticleHeader("KEY TEACHING LINE")) {
                    ArticleClosing("Tanween is not a vowel. It is a hidden noon sound in disguise. The rule is determined by the next letter, not the vowel mark.")
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.idhaar)
                    TajweedFamilyRow(LetterTraits.idghamGhunnah)
                    TajweedFamilyRow(LetterTraits.idghamBilaGhunnah)
                    TajweedFamilyRow(LetterTraits.iqlaab)
                    TajweedFamilyRow(LetterTraits.ikhfaa)
                } header: {
                    ArticleHeader("ON THE ALPHABET")
                } footer: {
                    Text("Every letter page shows which of these it triggers, with an example from the Quran.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "nun-sakin-overview", title: "The Four Rules at a Glance"),
                    TajweedCourseLesson(id: "tanween", title: "Tanween: The Noon You Cannot See"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .arabicDoorDestination($door)
        .navigationTitle("Noon Sakinah and Tanween")
    }
}

// MARK: - Meem Sakinah

struct TajweedMeemSakinahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("MEEM SAKINAH")) {
                    ArticleLead("Meem Sakinah means a meem with sukoon: مْ. In tajweed, Meem Sakinah has three rules, and all three are called Shafawi because they are pronounced from the lips. The word Shafawi comes from shafah, meaning \"lip.\"")

                    ArticleChecklist(["Ikhfaa Shafawi", "Idgham Shafawi", "Idhaar Shafawi"], title: "The three rules are:")

                    Text(verbatim: "These rules depend on the letter that comes after the Meem Sakinah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. IKHFAA SHAFAWI")) {
                    Text(verbatim: "Ikhfaa Shafawi occurs when Meem Sakinah (مْ) is followed by the letter Ba (ب).")
                        .font(.body)

                    Text(verbatim: "When this happens, the meem is hidden lightly while keeping ghunnah for two counts. The lips come close together, but the meem is not pronounced with full clarity like normal Idhaar.")
                        .font(.body)

                    TajweedKeyLine("\u{200E}مْ\u{200E} + ب = Ikhfaa Shafawi", systemImage: "equal.circle.fill")

                    TajweedArabicLine("أَم بِهِۦ جِنَّةُۢ", title: "Example",
                                      caption: "How to read it: am bihi, with ghunnah for two counts.")

                    Text(verbatim: "In this example, the Meem Sakinah in أَم is followed by ب in بِهِۦ, so it is read with Ikhfaa Shafawi.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. IDGHAM SHAFAWI")) {
                    Text(verbatim: "Idgham Shafawi occurs when Meem Sakinah (مْ) is followed by another Meem (م).")
                        .font(.body)

                    Text(verbatim: "When this happens, the first meem merges into the second meem, and the result is read as a doubled meem with ghunnah for two counts.")
                        .font(.body)

                    TajweedKeyLine("\u{200E}مْ\u{200E} + م = Idgham Shafawi", systemImage: "equal.circle.fill")

                    TajweedArabicLine("وَلَهُم مَّا يَشۡتَهُونَ", title: "Example",
                                      caption: "How to read it: lahum maa, with ghunnah for two counts.")

                    Text(verbatim: "In this example, the Meem Sakinah at the end of لَهُم is followed by another meem in مَّا, so the two meems merge.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. IDHAAR SHAFAWI")) {
                    Text(verbatim: "Idhaar Shafawi occurs when Meem Sakinah (مْ) is followed by any letter other than Ba (ب) or Meem (م).")
                        .font(.body)

                    Text(verbatim: "When this happens, the meem is pronounced clearly with no extra ghunnah beyond its normal sound.")
                        .font(.body)

                    TajweedKeyLine("\u{200E}مْ\u{200E} + any letter except ب or م = Idhaar Shafawi", systemImage: "equal.circle.fill")

                    TajweedArabicLine("وَمَا بَلَغُواْ مِعۡشَارَ مَآ ءَاتَيۡنَٰهُمۡ فَكَذَّبُواْ رُسُلِي", title: "Example", size: 24)

                    Text(verbatim: "In this example, the Meem Sakinah in ءَاتَيۡنَٰهُمۡ is followed by ف, so it is read with Idhaar Shafawi.")
                        .font(.body)

                    TajweedWordCard("Clear before any other letter", words: [
                        TajweedWord("لَكُمۡ فِيهَا", "lakum fiha"),
                        TajweedWord("عَلَيۡكُمۡ سَلَامٌ", "alaykum salamun"),
                    ])
                }

                Section(header: ArticleHeader("MEEM MUSHADDADAH")) {
                    Text(verbatim: "A related rule is Meem Mushaddadah, which is a meem with shaddah: مّ.")
                        .font(.body)

                    TajweedKeyLine("Whenever you see مّ, it must be pronounced with a strong ghunnah for two counts.", systemImage: "speaker.wave.2.fill")

                    TajweedWordCard(words: [
                        TajweedWord("ثُمَّ", "thumma"),
                        TajweedWord("لَمَّا", "lamma"),
                    ])

                    Text(verbatim: "This is not one of the three Meem Sakinah rules, but it is closely related because it also involves ghunnah on meem.")
                        .font(.body)
                }

                Section(header: ArticleHeader("QUICK SUMMARY")) {
                    TajweedKeyLine("Meem Sakinah = مْ", systemImage: "m.circle.fill")

                    ArticleStep(verbatim: "1. Ikhfaa Shafawi: مۡ\u{200E} + ب, hide the meem with ghunnah. Example: أَم بِهِۦ")
                    ArticleStep(verbatim: "2. Idgham Shafawi: مۡ\u{200E} + م, merge the two meems with ghunnah. Example: لَهُم مَّا")
                    ArticleStep(verbatim: "3. Idhaar Shafawi: مۡ\u{200E} + any letter except ب or م, pronounce the meem clearly. Example: لَكُمۡ فِيهَا")
                }

                Section(header: ArticleHeader("SHORT SUMMARY")) {
                    ArticleClosing("Meem Sakinah has three rules. If it is followed by Ba, it is read with Ikhfaa Shafawi, meaning the meem is hidden with ghunnah. If it is followed by another Meem, it is read with Idgham Shafawi, meaning the two meems merge with ghunnah. If it is followed by any other letter, it is read with Idhaar Shafawi, meaning the meem is pronounced clearly.")
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.ikhfaaShafawi)
                    TajweedFamilyRow(LetterTraits.idghamShafawi)
                    TajweedFamilyRow(LetterTraits.idhaarShafawi)
                    TajweedFamilyRow(LetterTraits.ghunnah)
                } header: {
                    ArticleHeader("ON THE ALPHABET")
                } footer: {
                    Text("Every letter page shows which of these it triggers, with an example from the Quran.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    TajweedVideoLink(title: "How to pronounce meem sakinah properly",
                                     url: "https://www.youtube.com/watch?v=MAvDrZgWRTs")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "mim-sakin-rules", title: "The Three Rules of Mim Sakin"),
                    TajweedCourseLesson(id: "noon-mim-mushaddad", title: "Nun and Mim with a Shaddah"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Meem Sakinah")
    }
}

// MARK: - 4 Sukoon

struct TajweedSukoonView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("The 4 Types of Sukoon Marks in the Qur’an")) {
                    ArticleLead("In the Uthmani script of the Qur’an, letters may carry different kinds of sukoon-style markings. These marks tell the reciter whether a letter is pronounced, skipped, pronounced only when stopping, or affected by a special tajweed rule.")
                }

                Section(header: ArticleHeader("1. Normal Sukoon: Pronounce the Letter Without a Vowel")) {
                    Text(verbatim: "This is the common Qur’anic sukoon mark written like ـۡ above a consonant. It means the letter has no vowel, but the letter itself is still pronounced clearly.")
                        .font(.body)

                    TajweedArabicLine("رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ", title: "Example")

                    TajweedKeyLine("Simple rule: Pronounce the letter, but do not add a vowel after it.", systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader("2. Permanent Silent Letter: Always Skip It")) {
                    Text(verbatim: "This mark shows that the letter is written in the Qur’an’s script but is not pronounced. You skip it whether you continue reciting or stop.")
                        .font(.body)

                    TajweedArabicLine("بِأَيۡيْدٖ", title: "Example")

                    TajweedKeyLine("Simple rule: The letter is written, but never pronounced.", systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader("3. Stop-Only Letter: Pronounce It Only If You Stop")) {
                    Text(verbatim: "This mark means the letter is ignored when continuing, but pronounced if you stop on the word.")
                        .font(.body)

                    TajweedWordCard("Examples", words: [
                        TajweedWord("قَوَارِيرَا۠", "stop: قَوَارِيرَا"),
                        TajweedWord("أَنَا۠", "in context: قُلۡ إِنَّمَآ أَنَا۠ بَشَرٞ مِّثۡلُكُمۡ"),
                    ], stacked: true)

                    TajweedKeyLine("Simple rule: Pronounce it when stopping, skip it when continuing.", systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader("4. No Sukoon Mark: Madd Letter or Special Tajweed Rule")) {
                    Text(verbatim: "Sometimes a letter has no sukoon mark and no vowel mark. This usually means one of two things: either it is a madd letter (stretched for two counts), or a consonant affected by a special tajweed rule.")
                        .font(.body)

                    TajweedWordCard("Examples", words: [
                        TajweedWord("يُقِيمُونَ", "madd letter example"),
                        TajweedWord("يُنفِقُونَ", "special tajweed (ikhfāʾ) example"),
                    ])

                    TajweedKeyLine("Simple rule: No mark usually means either natural madd or a special recitation rule is happening.", systemImage: "lightbulb.fill")

                    Text(verbatim: "Note about the example رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ: there is a qalqalah effect in the consonant, but there is no special visual marking for qalqalah in the Uthmani script; you must know it by rule or consult the tajweed colors in the app to see it highlighted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(header: ArticleHeader("Super Simple Summary")) {
                    ArticleStep(verbatim: "1. ـۡ Normal sukoon: Pronounce the consonant with no vowel. Example: رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ")
                    ArticleStep(verbatim: "2. Silent written letter: Skip it always. Example: كَانُواْ")
                    ArticleStep(verbatim: "3. Stop-only letter: Pronounce it only when stopping. Example: أَنَا۠ / قَوَارِيرَا۠")
                    ArticleStep(verbatim: "4. No mark: Either a madd letter or a special tajweed rule. Example: يُقِيمُونَ / يُنفِقُونَ")
                }

                Section(header: ArticleHeader("WATCH")) {
                    TajweedVideoLink(title: "The four types of sukoon in the Quran",
                                     url: "https://www.youtube.com/shorts/ZlMsseUu7hU")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "sukoon", title: "Sukoon: The Letter at Rest"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("4 Sukoon")
    }
}

// MARK: - Hamzatul Wasl

struct TajweedHamzatulWaslView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("Hamzatul-Wasl: The Connecting Hamzah")) {
                    ArticleLead("Hamzatul-Wasl means “the hamzah of connection.” It is only pronounced when beginning recitation from that word; if you connect from the previous word, the Hamzatul-Wasl is dropped and not pronounced.")

                    Text(verbatim: "In the Uthmani Qur’an script, Hamzatul-Wasl is usually written as an alif with a small ṣād-like sign above it: ٱ")
                        .font(.body)

                    TajweedWordCard("Common examples", words: [
                        TajweedWord("ٱبۡنُواْ", "ibnu"),
                        TajweedWord("ٱمۡشُواْ", "imshu"),
                        TajweedWord("ٱقۡضُوٓاْ", "iqdu"),
                        TajweedWord("ٱئۡتُواْ", "iitu", note: "The sakin hamzah becomes a long i"),
                        TajweedWord("ٱئۡتُونِي", "iituni", note: "The same long i"),
                    ])

                    TajweedKeyLine("Key rule: If you start from the word, pronounce Hamzatul-Wasl. If you connect from the previous word, drop it.", systemImage: "key.fill")
                }

                Section(header: ArticleHeader("1. Hamzatul-Wasl Is Dropped When Connecting")) {
                    Text(verbatim: "When reciting continuously, Hamzatul-Wasl is not pronounced. The previous word connects directly into the next word.")
                        .font(.body)

                    TajweedArabicLine("ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِۛ", title: "Example", size: 24)

                    Text(verbatim: "When continuing: dhālika l-kitāb (you do not say al- as a separate hamzah). If you stop and then begin from the word, pronounce the Hamzatul-Wasl: al-kitāb.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. Hamzatul-Wasl With “Al” Takes Fatḥah")) {
                    Text(verbatim: "When a word begins with the definite article ٱل, Hamzatul-Wasl is pronounced with fatḥah if you begin from that word (al-kitāb → al-kitāb; al-rahmān → ar-raḥmān).")
                        .font(.body)

                    TajweedWordCard("With the article: start with a fatha", words: [
                        TajweedWord("ٱلۡكِتَٰبُ", "al-kitāb"),
                        TajweedWord("ٱلرَّحۡمَٰنُ", "ar-raḥmān"),
                        TajweedWord("ٱلصَّمَدُ", "aṣ-ṣamad"),
                        TajweedWord("ٱللَّهُ", "Allāh"),
                    ])

                    Text(verbatim: "Note: alif itself is treated as a vowel/madd letter; the opening sound of ٱل is the Hamzatul-Wasl, realized as an initial “a”.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Section(header: ArticleHeader("3. Hamzatul-Wasl in Nouns Usually Takes Kasrah")) {
                    Text(verbatim: "In nouns that begin with Hamzatul-Wasl and do not begin with ٱل, the Hamzatul-Wasl is pronounced with kasrah when starting (e.g. ٱسۡمُهُۥ → ismuhu).")
                        .font(.body)

                    TajweedWordCard("The nouns: start with a kasra", words: [
                        TajweedWord("ٱسۡم", "ism"),
                        TajweedWord("ٱبۡن", "ibn"),
                        TajweedWord("ٱبۡنَيۡ", "ibnay"),
                    ])
                }

                Section(header: ArticleHeader("4. Hamzatul-Wasl in Verbs Depends on the Third Letter")) {
                    Text(verbatim: "For verbs, examine the third letter: if it has ḍammah, begin with “u”; if it has fatḥah or kasrah, begin with “i”. Exception: when that ḍammah is incidental (ʿāriḍah), begin with kasrah instead: ٱمۡشُوا، ٱقۡضُوا، ٱبۡنُوا، ٱمۡضُوا، ٱئۡتُوا are read imshu, iqdu, ibnu, imdu, iitu, not umshu / uqdu / ubnu.")
                        .font(.body)

                    TajweedWordCard("Example (third letter ḍammah → start with 'u')", words: [
                        TajweedWord("ٱتۡلُ", "utlu (when starting)", note: "When connected: watlu"),
                    ])

                    TajweedKeyLine("Simple rule: Third letter ḍammah → start with 'u'; otherwise start with 'i'.", systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader("5. Special Verb Exceptions")) {
                    Text(verbatim: "Some verbs are special cases (e.g. ٱئۡتُوا / ٱئۡتُونِي) and are learned individually; they may behave differently than the third-letter rule.")
                        .font(.body)

                    TajweedWordCard("Example", words: [
                        TajweedWord("ٱئۡتُونِي", "iituni when starting", note: "The sakin hamzah becomes a long i"),
                    ])
                }

                Section(header: ArticleHeader("6. Hamzatul-Wasl After Tanwīn: Add a Connecting Nūn")) {
                    Text(verbatim: "When a word ending in tanwīn is followed by a word beginning with Hamzatul-Wasl, a connecting 'nِ' (kasrah nūn) is commonly inserted when continuing (e.g. بِغُلَٰمٍ ٱسۡمُهُۥ → bighulāmin ismuhu).")
                        .font(.body)

                    TajweedWordCard("Example", words: [
                        TajweedWord("بِغُلَٰمٍ ٱسۡمُهُۥ ← بِغُلَٰمِنِ سۡمُهُۥ", "bighulāmin ismuhu"),
                    ], stacked: true, size: 23)
                }

                Section(header: ArticleHeader("Summary: How to Start Hamzatul-Wasl")) {
                    ArticleStep(verbatim: "1. If the word begins with ٱل → start with 'a' (fatḥah).")
                    ArticleStep(verbatim: "2. If a noun without ٱل → start with 'i' (kasrah).")
                    ArticleStep(verbatim: "3. If a verb → check the third letter (ḍammah → 'u', otherwise 'i').")
                    ArticleStep(verbatim: "4. Some words are exceptions and must be learned individually.")
                }

                Section(header: ArticleHeader("What Happens When Continuing")) {
                    Text(verbatim: "Hamzatul-Wasl is dropped when continuing from the previous word (e.g. ذَٰلِكَ ٱلۡكِتَٰبُ → dhālika l-kitāb; وَٱتۡلُ → watlu).")
                        .font(.body)
                }

                Section(header: ArticleHeader("SHORT SUMMARY")) {
                    ArticleClosing("Hamzatul-Wasl is the connecting hamzah, pronounced only when starting from the word. Nouns usually take 'i', words with ٱل start with 'a', verbs depend on the third letter, and tanwīn before Hamzatul-Wasl connects with an 'nِ' sound.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    TajweedVideoLink(title: "How to pronounce words with no tashkeel",
                                     url: "https://www.youtube.com/shorts/SpA7EtX3jMA")
                    TajweedVideoLink(title: "Hamzat al-wasl and hamzat al-qat'",
                                     url: "https://www.youtube.com/shorts/xNn-pR4eoHM")
                    TajweedVideoLink(title: "Alif and hamzah",
                                     url: "https://www.youtube.com/shorts/79Ku0wSKf9Q")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "hamzat-al-wasl", title: "Hamzat al-Wasl: The Hamza That Comes and Goes"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Hamzatul-Wasl")
    }
}

// MARK: - Waqf

struct TajweedWaqfView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("WAQF")) {
                    ArticleLead("Waqf (وَقف) means to stop or pause while reciting the Quran, with the intention of resuming the recitation correctly afterward.")

                    Text(verbatim: "The word comes from the Arabic root و ق ف, meaning to stop, stand, or halt. In tajweed, it refers specifically to stopping at the end of a word while preserving the meaning, pronunciation, and beauty of the Quran.")
                        .font(.body)

                    Text(verbatim: "Waqf is not random breathing. It is a deliberate, rule-based pause guided by the Mushaf and the meaning of the ayah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHY WAQF MATTERS")) {
                    ArticleChecklist(["Change the meaning of an ayah",
                                      "Create theological errors",
                                      "Break the grammatical structure",
                                      "Distort the listener's understanding"],
                                     title: "Stopping incorrectly can:", systemImage: "xmark.circle.fill")

                    ArticleChecklist(["Preserves meaning",
                                      "Maintains clarity",
                                      "Reflects proper understanding",
                                      "Shows respect for the words of Allah"],
                                     title: "Correct waqf:")

                    Text(verbatim: "Ali ibn Abi Talib (may Allah be pleased with him) defined tartil as: \"the tajweed of the letters and knowledge of the places of stopping.\"")
                        .font(.body)
                }

                Section(header: ArticleHeader("WAQF IN THE MUSHAF")) {
                    Text(verbatim: "Even without colors, the Mushaf signals where to stop or continue using:")
                        .font(.body)

                    ArticleBullet(verbatim: "Special symbols")
                    ArticleBullet(verbatim: "Word endings")
                    ArticleBullet(verbatim: "Sentence structure")
                    ArticleBullet(verbatim: "Completion of meaning")

                    Text(verbatim: "A reader trained in waqf reads with understanding, not just sound.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LAST LETTER WHEN YOU STOP")) {
                    Text(verbatim: "When stopping, the ending of the word almost always changes.")
                        .font(.body)

                    TajweedKeyLine("The Golden Rule of Waqf: every vowel at the end of a word becomes a sukun when stopping, except special cases.", systemImage: "star.fill")
                }

                Section(header: ArticleHeader("1. FINAL DAMMAH, FATHAH, OR KASRAH")) {
                    Text(verbatim: "When stopping, the vowel is dropped, and the letter becomes saakin.")
                        .font(.body)

                    TajweedWordCard("Connected → Stopping", words: [
                        TajweedWord("ٱلۡعَٰلَمِينَ ← ٱلۡعَٰلَمِينۡ", "al-'alamina → al-'alamin"),
                        TajweedWord("نَسۡتَعِينُ ← نَسۡتَعِينۡ", "nasta'inu → nasta'in"),
                        TajweedWord("ٱلۡكِتَٰبِ ← ٱلۡكِتَٰبۡ", "al-kitabi → al-kitab"),
                    ], stacked: true, size: 23)

                    Text(verbatim: "The sound is cut cleanly, without adding extra vowels.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. STOPPING ON TANWEEN")) {
                    Text(verbatim: "Tanween is never pronounced when stopping.")
                        .font(.body)

                    TajweedWordCard("Tanween at a stop", words: [
                        TajweedWord("بَصِيرٌ ← بَصِيرۡ", "Dammatayn: dropped"),
                        TajweedWord("عَلِيمٍ ← عَلِيمۡ", "Kasratayn: dropped"),
                        TajweedWord("رَحۡمَةً ← رَحۡمَهۡ", "Fathatayn on ة: a sakin ha, no alif"),
                        TajweedWord("كِتَٰبًا ← كِتَٰبَا", "Fathatayn + alif: the alif stays"),
                    ], stacked: true, size: 23)

                    Text(verbatim: "Important: the tanween itself is dropped completely when stopping. There is no nuun sound and no vowel.")
                        .font(.body)

                    Text(verbatim: "Exception: when fathatayn is followed by an alif (ا), the tanween is dropped but the alif is still pronounced, producing a long a sound. This is because the alif is a written long vowel, not part of the tanween itself.")
                        .font(.body)

                    TajweedKeyLine("Rule to remember: fathatayn disappears when stopping, but a written alif remains pronounced.", systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader("3. TAA MARBUTAH (ة)")) {
                    Text(verbatim: "When stopping, taa marbutah is pronounced as haa saakinah (ـهۡ).")
                        .font(.body)

                    TajweedWordCard("Ta marbutah becomes a ha", words: [
                        TajweedWord("رَحۡمَةٌ ← رَحۡمَهۡ", "rahmah"),
                        TajweedWord("جَنَّةٍ ← جَنَّهۡ", "jannah"),
                    ], stacked: true, size: 23)

                    Text(verbatim: "This rule is consistent everywhere in the Quran.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. LONG VOWELS (ا، و، ي)")) {
                    Text(verbatim: "Long vowels remain unchanged when stopping.")
                        .font(.body)

                    TajweedWordCard("Long vowels stay", words: [
                        TajweedWord("فِي ← فِي", "Unchanged"),
                        TajweedWord("يَقُولُ ← يَقُولۡ", "The final vowel drops, the long u stays"),
                    ], stacked: true, size: 23)

                    Text(verbatim: "No shortening occurs.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE FOUR KINDS OF STOP")) {
                    ArticleStep("1. **Waqf Tam (Complete):** The meaning is complete and independent. Best place to stop.")
                    ArticleStep("2. **Waqf Kafi (Sufficient):** The meaning is complete, but connected to what follows. Permissible to stop.")
                    ArticleStep("3. **Waqf Hasan (Good):** The wording makes sense, but the meaning is incomplete. Allowed only for breath, not preferred.")
                    ArticleStep("4. **Waqf Qabih (Bad):** Stopping breaks the meaning or creates error. Not allowed.")
                }

                Section(header: ArticleHeader("DANGEROUS STOP EXAMPLE")) {
                    TajweedArabicLine("لَا تَقۡرَبُواْ ٱلصَّلَوٰةَ", title: "Example of a dangerous stop",
                                      caption: "Stopping here implies \"Do not approach prayer,\" which is incorrect.")

                    Text(verbatim: "The ayah continues: وَأَنتُمۡ سُكَٰرَىٰ")
                        .font(.body)
                }

                Section(header: ArticleHeader("WAQF SYMBOLS")) {
                    QuranSignsSectionContent(accentColor: appearance.accent)

                    Text(verbatim: "These symbols guide meaning, not breathing convenience.")
                        .font(.body)
                }

                Section(header: ArticleHeader("REMEMBER")) {
                    ArticleClosing("Waqf is not about breath. It is about meaning. You stop where the meaning stops, not where the lungs give up.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "waqf-types", title: "Where You May Stop"),
                    TajweedCourseLesson(id: "waqf-changes", title: "What Changes When You Stop"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Waqf")
    }
}
