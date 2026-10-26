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
                Section(header: ArticleHeader(String(localized: "IMPROVING YOUR RECITATION"))) {
                    ArticleLead(String(localized: "This guide on its own is not enough to fully develop strong tajweed and pronunciation. While it can introduce the rules and concepts, real improvement in Quranic recitation requires consistent practice, listening, and guidance from knowledgeable teachers."), eyebrow: String(localized: "IN SHORT"))

                    ArticleParagraph(verbatim: String(localized: "Ideally, this guide should be used alongside a teacher who can listen to your recitation and correct your mistakes. Tajweed is refined through feedback and repetition, and many pronunciation errors are difficult to notice on your own. To truly benefit from this guide, approach the Quran with sincerity, humility, and love. Put your trust in Allah and be willing to learn."))

                    ArticleParagraph(verbatim: String(localized: "You must also set aside arrogance and ego. Even if you believe your tajweed, voice, or makharij are good, there is always room to improve. The greatest reciters spent years refining their recitation. Below are three consistent practices that will help maximize both this guide and your learning of tajweed."))
                }

                Section(header: ArticleHeader(String(localized: "1. PRACTICE RECITING ON YOUR OWN"))) {
                    ArticleParagraph(verbatim: String(localized: "Reading the Quran regularly on your own is essential. This type of practice helps with:"))

                    ArticleBullet(verbatim: String(localized: "Increasing reading fluency and speed"))
                    ArticleBullet(verbatim: String(localized: "Improving familiarity with words and verses"))
                    ArticleBullet(verbatim: String(localized: "Experimenting with voice control and tone"))
                    ArticleBullet(verbatim: String(localized: "Applying corrections you have learned"))

                    ArticleCallout(String(localized: "However, it is important to understand something: the phrase \"practice makes perfect\" is not true. Rather, perfect practice makes perfect. If someone repeatedly practices incorrect pronunciation or recites carelessly, they may reinforce mistakes instead of correcting them."),
                                   title: String(localized: "Perfect Practice Makes Perfect"), systemImage: "exclamationmark.triangle.fill")

                    ArticleChecklist([String(localized: "Reading consistently"),
                                      String(localized: "Reciting carefully with proper tajweed"),
                                      String(localized: "Applying corrections learned from teachers or study")],
                                     title: String(localized: "For this reason, solo practice should focus on:"))

                    ArticleParagraph(verbatim: String(localized: "Solo practice is essential, but it cannot fully replace proper guidance."))

                    ArticleParagraph(verbatim: String(localized: "This is similar to practicing a sport alone. Individual practice builds skill and stamina, but without proper technique, it will only take you so far. At the same time, even the best teacher cannot help you improve if you never put in the hours of practice yourself."))
                }

                Section(header: ArticleHeader(String(localized: "2. LISTEN TO SKILLED RECITERS"))) {
                    ArticleParagraph(verbatim: String(localized: "Listening to skilled reciters is one of the most powerful ways to improve pronunciation and rhythm. Many students benefit from listening to classical Egyptian reciters such as Sheikh Muhammad Siddiq Al-Minshawi and Sheikh Mahmoud Khalil Al-Hussary."))

                    ArticleParagraph(verbatim: String(localized: "Both reciters are widely respected for their clarity, precision, and strong tajweed. Their recordings typically come in two styles:"))

                    ArticleTermCard(String(localized: "Murattal"), arabic: "مُرَتَّل",
                                    meaning: String(localized: "A steady, clear recitation ideal for learning."))

                    ArticleTermCard(String(localized: "Mujawwad"), arabic: "مُجَوَّد",
                                    meaning: String(localized: "A slower, melodic recitation that emphasizes precision and beauty."))

                    ArticleParagraph(verbatim: String(localized: "Try to find a reciter whose voice you genuinely enjoy listening to. Developing a connection with a reciter often deepens your love for the Quran and increases your motivation to recite. However, do not listen passively."))

                    ArticleChecklist([String(localized: "Follow along in the mushaf while listening"),
                                      String(localized: "Read aloud with the reciter"),
                                      String(localized: "Attempt to mimic his tajweed and pronunciation"),
                                      String(localized: "Pay attention to letter articulation, elongation, and pauses")],
                                     title: String(localized: "Instead, actively engage with the recitation:"), systemImage: "ear")

                    ArticleParagraph(verbatim: String(localized: "This is similar to studying expert athletes, learning from masters by carefully observing how they perform. You may also benefit from educational tajweed resources such as Learn Arabic 101 or other structured lessons."))
                }

                Section(header: ArticleHeader(String(localized: "3. PRACTICE WITH A TEACHER OR PARTNER"))) {
                    ArticleParagraph(verbatim: String(localized: "Practicing with someone knowledgeable in tajweed is one of the most effective ways to improve your recitation. A teacher or experienced student can hear mistakes that you will not notice yourself, including:"))

                    ArticleBullet(verbatim: String(localized: "Incorrect makharij (points of articulation)"))
                    ArticleBullet(verbatim: String(localized: "Subtle pronunciation errors"))
                    ArticleBullet(verbatim: String(localized: "Improper elongation (madd)"))
                    ArticleBullet(verbatim: String(localized: "Weak ghunnah or nasalization"))
                    ArticleBullet(verbatim: String(localized: "Mistakes in stopping or continuation"))

                    ArticleParagraph(verbatim: String(localized: "Corrections may sometimes feel repetitive or strict, but they are extremely valuable. Even small refinements can significantly improve your recitation. The best tajweed is the recitation that is correct and refined in all aspects, both major and subtle."))

                    ArticleParagraph(verbatim: String(localized: "Learning with a teacher is similar to training with a coach in sports. A coach observes your technique and gives personalized corrections that accelerate your improvement."))

                    ArticleClosing(String(localized: "If a formal teacher is not available, try to practice with someone knowledgeable who has strong tajweed and is willing to listen to your recitation and offer corrections."))
                }

                Section(header: ArticleHeader(String(localized: "WATCH"))) {
                    TajweedVideoLink(title: String(localized: "Why are you still struggling with Quran recitation?"),
                                     url: "https://www.youtube.com/watch?v=_acpVGn0ys0")
                    TajweedVideoLink(title: String(localized: "The best and fastest route to learn Arabic and the Quran"),
                                     url: "https://www.youtube.com/watch?v=86qiFqqZSG0")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "improving-recitation", title: String(localized: "Improving Your Recitation")),
                    TajweedCourseLesson(id: "levels-of-recitation", title: String(localized: "Three Speeds, One Standard")),
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
                Section(header: ArticleHeader(String(localized: "NATURAL QURANIC RECITATION"))) {
                    ArticleLead(String(localized: "One of the most common mistakes in Quranic recitation is overemphasis: exaggerating mouth movements, stretching the lips sideways, or forcing sounds in a way that is unnatural to Arabic speech. Correct tajweed is meant to preserve clarity and authenticity."), eyebrow: String(localized: "IN SHORT"))
                }

                Section(header: ArticleHeader(String(localized: "GENERAL MOUTH AND LIP RULE"))) {
                    ArticleChecklist([String(localized: "Lips move up and down only"),
                                      String(localized: "Avoid side stretching or exaggerated shaping"),
                                      String(localized: "The tongue and throat do most of the work")],
                                     title: String(localized: "The General Rule"))

                    ArticleParagraph(verbatim: String(localized: "When recited correctly, Quranic Arabic should sound smooth, balanced, and natural, similar to careful classical Arabic speech."))
                }

                Section(header: ArticleHeader(String(localized: "1. DAMMAH-RELATED SOUNDS (ـُ ـٌ و)"))) {
                    ArticleParagraph(verbatim: String(localized: "For all sounds related to dammah, the lips must round and project slightly forward to produce a true \"u\" sound."))

                    TajweedKeyLine(String(localized: "This is the only time the lips clearly point outward."), systemImage: "exclamationmark.circle.fill")

                    ArticleChecklist([String(localized: "Dammah (ـُ)"), String(localized: "Dammatayn (ـٌ)"), String(localized: "Waw sakinah preceded by dammah (ـُو)")],
                                     title: String(localized: "Applies To"))
                }

                Section(header: ArticleHeader(String(localized: "2. MIM (م): LIP CLOSURE"))) {
                    ArticleParagraph(verbatim: String(localized: "The letter mim (م) is a bilabial letter, meaning it is produced using both lips."))

                    TajweedKeyLine(String(localized: "Think of the lips as folding together, not squeezing."), systemImage: "lightbulb.fill")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "lips-nasal-passage", title: String(localized: "The Lips and the Nose")),
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
                Section(header: ArticleHeader(String(localized: "TAJWEED IN THE MUSHAF"))) {
                    ArticleLead(String(localized: "Even without a color-coded mushaf, tajweed rules are visible directly in the text. The Quran is written in a way that signals when a sound should be held, merged, hidden, or pronounced clearly, if you know what to look for."), eyebrow: String(localized: "IN SHORT"))

                    ArticleParagraph(verbatim: String(localized: "This section teaches you how to recognize tajweed visually, before memorizing specific rules."))
                }

                Section(header: ArticleHeader(String(localized: "1. LETTERS WITHOUT SUKUN (EXCLUDING MADD)"))) {
                    ArticleChecklist([String(localized: "It has no sukun"), String(localized: "And it is not a madd letter (ا و ي)")], title: String(localized: "If a letter:"))

                    TajweedKeyLine(String(localized: "Then that letter must be held, and some tajweed rule applies."), systemImage: "hand.raised.fill")

                    ArticleParagraph(verbatim: String(localized: "This usually means: Ghunnah, Ikhfaa, Idghaam, Iqlaab, and similar rules."))

                    TajweedWordCard(String(localized: "Sukoon or no sukoon"), words: [
                        TajweedWord("مِنۡ", "min", note: String(localized: "Nun has sukun: pronounce clearly")),
                        TajweedWord("مَن يَقُولُ", "may-yaqul", note: String(localized: "No sukun on ن: merge (idghaam)")),
                        TajweedWord("عَلِيمٌ", "'alimun", note: String(localized: "Tanwin and no visible sukun: apply the rule")),
                    ], size: 23)

                    ArticleParagraph(verbatim: String(localized: "If there is no sukun, the sound does not pass quickly."))
                }

                Section(header: ArticleHeader(String(localized: "2. TANWIN SHAPE"))) {
                    ArticleParagraph(verbatim: String(localized: "Tanwin always ends in a hidden nun sakinah, which is why its shape matters."))
                }

                Section(header: ArticleHeader(String(localized: "SPECIAL TANWIN MARKS IN THE MUSHAF"))) {
                    ArticleParagraph(verbatim: String(localized: "Some Uthmani tanwin marks are drawn differently to tell you whether the hidden noon sound needs a special rule."))

                    TajweedWordCard(String(localized: "Version 1: special rule"),
                                    note: String(localized: "When the tanwin is written with the special mark, look at the next real letter and apply the noon sakinah/tanwin rule: ikhfaa, idghaam, iqlaab, or the correct ghunnah behavior."),
                                    words: [
                                        TajweedWord("رٞ", String(localized: "special dammatayn"), note: String(localized: "Apply the next-letter rule")),
                                        TajweedWord("لٖ", String(localized: "special kasratayn"), note: String(localized: "Apply the next-letter rule")),
                                        TajweedWord("رٗ", String(localized: "special fathatayn"), note: String(localized: "Apply the next-letter rule")),
                                    ])

                    TajweedWordCard(String(localized: "Version 2: normal idhaar"),
                                    note: String(localized: "When the normal double vowel mark is used before an idhaar letter, pronounce the hidden noon clearly. There is no merge, concealment, or conversion."),
                                    words: [
                                        TajweedWord("نٌ", String(localized: "normal dammatayn"), note: String(localized: "Clear idhaar")),
                                        TajweedWord("قٍ", String(localized: "normal kasratayn"), note: String(localized: "Clear idhaar")),
                                        TajweedWord("بًا", String(localized: "normal fathatayn"), note: String(localized: "Clear idhaar")),
                                    ])
                }

                Section(header: ArticleHeader(String(localized: "A. PARALLEL TANWIN → IDHAAR"))) {
                    ArticleParagraph(verbatim: String(localized: "When the two tanwin strokes are parallel, the nun is pronounced clearly."))

                    TajweedWordCard(String(localized: "Stacked: the hidden noon is said clearly"), words: [
                        TajweedWord("بًا", "ban"),
                        TajweedWord("بٌ", "bun"),
                        TajweedWord("بٍ", "bin"),
                        TajweedWord("قُرۡءَانًا عَرَبِيًّا", "quraanan arabiyyan"),
                    ])

                    ArticleParagraph(verbatim: String(localized: "You hear a full, clear \"n\" sound."))
                }

                Section(header: ArticleHeader(String(localized: "B. STAGGERED / CONNECTED TANWIN"))) {
                    ArticleParagraph(verbatim: String(localized: "When tanwin marks appear staggered, connected, or visually altered, this usually indicates Idghaam, Ikhfaa, or Iqlaab."))

                    TajweedWordCard(String(localized: "Staggered: do not pronounce the noon normally"), words: [
                        TajweedWord("أُمَّةٞ قَدۡ", "ummatun(g) qad", note: String(localized: "Special dammatayn: hidden noon with ghunnah")),
                        TajweedWord("صِرَٰطٖ مُّسۡتَقِيمٖ", "siraatim-mustaqeem", note: String(localized: "Special kasratayn: merged into the mim")),
                        TajweedWord("أُمَّةٗ وَسَطٗا", "ummataw-wasatan", note: String(localized: "Special fathatayn: idghaam with ghunnah")),
                    ], stacked: true, size: 23)

                    TajweedKeyLine(String(localized: "The mushaf is telling you: do not pronounce the nun normally here."), systemImage: "exclamationmark.circle.fill")

                    ArticleParagraph(verbatim: String(localized: "Important clarification: not every mushaf shows tanwin shapes identically, but the principle remains the same. If the tanwin does not look standard, slow down and apply a rule."))
                }

                Section(header: ArticleHeader(String(localized: "3. THE LAAM OF \"AL-\" (ٱلـ)"))) {
                    ArticleParagraph(verbatim: String(localized: "The definite article \"al-\" also signals pronunciation through markings."))

                    TajweedWordCard(String(localized: "A. Sukun on laam (qamariyyah)"), words: [
                        TajweedWord("ٱلۡقَمَر", "al-qamar"),
                        TajweedWord("ٱلۡكِتَٰب", "al-kitab"),
                        TajweedWord("ٱلۡهُدَىٰ", "al-huda"),
                    ])

                    TajweedWordCard(String(localized: "B. No sukun on laam (shamsiyyah)"), note: String(localized: "The laam merges into the next letter."), words: [
                        TajweedWord("ٱلشَّمۡس", "ash-shams"),
                        TajweedWord("ٱلنَّاس", "an-nas"),
                        TajweedWord("ٱلرَّحۡمَٰن", "ar-rahman"),
                    ])

                    TajweedKeyLine(String(localized: "If you do not see a sukun, the laam is not read."), systemImage: "eye.fill")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "reading-the-script", title: String(localized: "What the Script Tells You")),
                    TajweedCourseLesson(id: "tanween-shapes", title: String(localized: "The Shape of the Tanween")),
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
                Section(header: ArticleHeader(String(localized: "MAKHAARIJ"))) {
                    ArticleLead(String(localized: "Makharij are the physical points of articulation from which Arabic letters are pronounced. Correct makharij are the foundation of tajweed. If the letter does not come from its proper place, no amount of rules will fix the sound."), eyebrow: String(localized: "IN SHORT"))

                    ArticleParagraph(verbatim: String(localized: "This section focuses on awareness, not memorization. The goal is to know where a sound comes from and what moves to produce it."))

                    Image("Makharij1")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(24)
                        .focusableImage("Makharij1", title: String(localized: "Makharij al-Huruf"))

                    Image("Makharij2")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(24)
                        .focusableImage("Makharij2", title: String(localized: "Makharij al-Huruf"))

                    ArticleParagraph(verbatim: String(localized: "Use these diagrams as references, not something to stare at while reciting. Over time, correct makharij become muscle memory."))
                }

                Section(header: ArticleHeader(String(localized: "RECOMMENDED PLAYLIST"))) {
                    ArticleChecklist([String(localized: "Isolated letter sounds"), String(localized: "Minimal exaggeration"), String(localized: "Clear mouth positioning")],
                                     title: String(localized: "Use a clear, slow pronunciation playlist such as Learn Arabic 101 (Makharij series). Focus on:"),
                                     systemImage: "ear")

                    TajweedKeyLine(String(localized: "Listen → imitate → repeat aloud. Silent learning does not work for makharij."), systemImage: "speaker.wave.2.fill")

                    TajweedVideoLink(title: String(localized: "Makharij and sifaat, the full playlist"),
                                     url: "https://www.youtube.com/watch?v=-YrfRpwFMe8&list=PL6TlMIZ5ylgpmlnN3EpkOec0tJ8OJZ5re")
                }

                Section(header: ArticleHeader(String(localized: "PRIMARY AREAS OF ARTICULATION"))) {
                    ArticleParagraph(verbatim: String(localized: "For learning purposes, we group makharij into three main zones."))
                }

                Section(header: ArticleHeader(String(localized: "1. THROAT LETTERS (الحُرُوفُ الحَلقِيَّةُ)"))) {
                    ArticleParagraph(verbatim: String(localized: "These letters originate from the throat, not the tongue."))

                    TajweedLetterStrip(String(localized: "Letters"), letters: LetterTraits.halq.letters, tint: LetterTraits.halq.legendColor) { door = .letter($0) }

                    ArticleChecklist([String(localized: "Deep throat: ء هـ"), String(localized: "Middle throat: ع ح"), String(localized: "Upper throat: غ خ")],
                                     title: String(localized: "Sub-Zones (for awareness)"), systemImage: "mappin.circle.fill")

                    ArticleChecklist([String(localized: "These letters are clear and open"), String(localized: "No nasalization"), String(localized: "Do not squeeze the throat")],
                                     title: String(localized: "Key Notes"))

                    TajweedWordCard(String(localized: "Throat letters in words"), words: [
                        TajweedWord("أَحَد", "ahad"),
                        TajweedWord("نَعۡبُدُ", "na'-bu-du"),
                        TajweedWord("غَفُور", "ghafur"),
                        TajweedWord("خَالِد", "khalid"),
                    ])

                    TajweedFix(wrong: String(localized: "Replacing ع with أ"), right: String(localized: "Clear throat engagement"))
                }

                Section(header: ArticleHeader(String(localized: "2. TONGUE LETTERS (أَغلَبُ الحُرُوفِ)"))) {
                    ArticleParagraph(verbatim: String(localized: "Most Arabic letters come from the tongue, but different parts of the tongue."))

                    ArticleChecklist([String(localized: "Back of tongue: ق ك"),
                                      String(localized: "Middle of tongue: ج ش ي"),
                                      String(localized: "Sides of tongue: ض"),
                                      String(localized: "Tip of tongue: ت د ط ن ل ر س ز ص ث ذ ظ")],
                                     title: String(localized: "Tongue Zones (Simplified)"), systemImage: "mappin.circle.fill")

                    ArticleChecklist([String(localized: "Small shifts in tongue position matter"), String(localized: "Do not force pressure"), String(localized: "Accuracy over strength")],
                                     title: String(localized: "Key Notes"))

                    TajweedWordCard(String(localized: "Tongue letters in words"), words: [
                        TajweedWord("قُلۡ", "qul"),
                        TajweedWord("سَمِيع", "samee'"),
                        TajweedWord("نُور", "nur"),
                        TajweedWord("رَبِّ", "rabbi"),
                    ])

                    TajweedFix(wrong: String(localized: "Collapsing multiple letters into one sound"), right: String(localized: "Distinct articulation for each letter"))
                }

                Section(header: ArticleHeader(String(localized: "3. LIP LETTERS (الحُرُوفُ الشَّفَوِيَّةُ)"))) {
                    ArticleParagraph(verbatim: String(localized: "These letters are produced using the lips."))

                    TajweedLetterStrip(String(localized: "Letters"), letters: LetterTraits.shafatan.letters, tint: LetterTraits.shafatan.legendColor) { door = .letter($0) }

                    ArticleChecklist([String(localized: "\u{200E}ب: full lip closure"),
                                      String(localized: "\u{200E}م: lip closure + nasal sound"),
                                      String(localized: "\u{200E}ف: upper teeth lightly touch lower lip"),
                                      String(localized: "\u{200E}و: both lips rounded and pushed forward, never closing (as a consonant; the long vowel waaw comes from the empty space of the mouth)")],
                                     title: String(localized: "How They Work"), systemImage: "mouth.fill")

                    TajweedWordCard(String(localized: "Lip letters in words"), words: [
                        TajweedWord("بَصِير", "basir"),
                        TajweedWord("أَمۡر", "amr"),
                        TajweedWord("فِيهِ", "fihi"),
                    ])

                    TajweedFix(wrong: String(localized: "Weak or lazy lip contact"), right: String(localized: "Gentle, controlled movement"))
                }

                Section(header: ArticleHeader(String(localized: "IMPORTANT PRACTICE ADVICE"))) {
                    ArticleParagraph(verbatim: String(localized: "Makharij are learned by sound, not sight."))

                    ArticleParagraph(verbatim: String(localized: "If you cannot hear the difference, slow down and exaggerate slightly during practice, then return to natural recitation."))

                    ArticleParagraph(verbatim: String(localized: "Correct makharij preserve the Quran exactly as it was revealed."))

                    ArticleClosing(String(localized: "Tajweed rules refine the sound. Makharij create it."))
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
                        LetterFamiliesView(title: String(localized: "Makharij"), axes: [.makhraj, .exit])
                            .openScreen(.letterFamilies, id: "makhraj")
                    } label: {
                        TajweedLinkLabel(systemImage: "list.number", title: String(localized: "The Seventeen Exits in Full"),
                                         caption: String(localized: "Every exit, with the letters made there"))
                    }
                } header: {
                    ArticleHeader(String(localized: "ON THE ALPHABET"))
                } footer: {
                    Text("The seven zones, deepest first. Every letter page names the exact point its letter is made at.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "makharij-overview", title: String(localized: "The Seventeen Exits")),
                    TajweedCourseLesson(id: "throat-letters", title: String(localized: "The Throat: Three Exits, Six Letters")),
                    TajweedCourseLesson(id: "tongue-regions", title: String(localized: "The Tongue: Ten Exits")),
                    TajweedCourseLesson(id: "lips-nasal-passage", title: String(localized: "The Lips and the Nose")),
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
                Section(header: ArticleHeader(String(localized: "HEAVY AND LIGHT"))) {
                    ArticleLead(String(localized: "Arabic letters differ in weight (heavy tafkhim vs light tarqiq). Some letters are always heavy, some are always light, and some are conditional, meaning the weight changes based on context."), eyebrow: String(localized: "IN SHORT"))

                    ArticleParagraph(verbatim: String(localized: "Correct letter weight is essential for accurate pronunciation and natural recitation."))
                }

                Section(header: ArticleHeader(String(localized: "1. HEAVY LETTERS (تَفخِيم)"))) {
                    ArticleParagraph(verbatim: String(localized: "These letters are always heavy, regardless of the vowel."))

                    TajweedLetterStrip(String(localized: "Always Heavy Letters"), letters: LetterTraits.heavy.letters, tint: LetterTraits.heavy.legendColor) { door = .letter($0) }

                    ArticleChecklist([String(localized: "The back of the tongue raised"), String(localized: "A full, deep sound"), String(localized: "No thinning, even with kasrah")],
                                     title: String(localized: "They are pronounced with:"))

                    TajweedWordCard(String(localized: "Always heavy"), words: [
                        TajweedWord("قَالَ", "qala"),
                        TajweedWord("صِرَٰط", "sirat"),
                        TajweedWord("طَبَعَ", "ta-ba-'a"),
                        TajweedWord("غَفُور", "ghafur"),
                        TajweedWord("خَالِد", "khalid"),
                    ])
                }

                Section(header: ArticleHeader(String(localized: "2. LIGHT LETTERS (تَرقِيق)"))) {
                    ArticleParagraph(verbatim: String(localized: "These letters are always light and never pronounced heavy."))

                    TajweedLetterStrip(String(localized: "Always Light Letters"), letters: LetterTraits.light.letters, tint: LetterTraits.light.legendColor) { door = .letter($0) }

                    ArticleChecklist([String(localized: "A relaxed tongue"), String(localized: "No back-tongue elevation"), String(localized: "Clear, sharp articulation")],
                                     title: String(localized: "They are pronounced with:"))

                    TajweedWordCard(String(localized: "Always light"), words: [
                        TajweedWord("بِسۡم", "bism"),
                        TajweedWord("نَعِيم", "na-'eem"),
                        TajweedWord("سَبِيل", "sabil"),
                        TajweedWord("يَوۡم", "yawm"),
                        TajweedWord("فِيهِ", "fihi"),
                    ])

                    TajweedKeyLine(String(localized: "Note: Laam (ل) and waw (و) are light by default, but laam becomes conditional in one specific case: Allah."), systemImage: "info.circle.fill")
                }

                Section(header: ArticleHeader(String(localized: "3. CONDITIONAL LETTERS"))) {
                    ArticleParagraph(verbatim: String(localized: "These letters change weight depending on vowels or surrounding letters."))
                }

                Section(header: ArticleHeader(String(localized: "A. RAA (ر)"))) {
                    ArticleParagraph(verbatim: String(localized: "The weight of raa depends on the vowel on the raa itself."))

                    TajweedWordCard(String(localized: "Heavy Raa"), note: String(localized: "With fathah (ـَ) or dammah (ـُ)"), words: [
                        TajweedWord("رَبِّ", "rabbi"),
                        TajweedWord("رُزِقُوا", "ruziqu"),
                        TajweedWord("قَرَأَ", "qaraa"),
                    ])

                    TajweedWordCard(String(localized: "Light Raa"), note: String(localized: "Raa with kasrah (ـِ), or raa with sukoon preceded by an ORIGINAL kasrah, unless an isti'la letter with fatha/damma follows it in the same word (قِرۡطَاس, مِرۡصَاد), which makes it heavy again."), words: [
                        TajweedWord("فِرۡعَوۡن", "firawn"),
                        TajweedWord("رِجَال", "rijal"),
                        TajweedWord("شِرۡعَة", "shirah"),
                    ])

                    TajweedKeyLine(String(localized: "Rule of thumb: if the raa carries a vowel, look at that vowel. If the raa is sakin, look at the letter BEFORE it, and at what follows, for the isti'la exception."), systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader(String(localized: "B. LAAM (ل)"))) {
                    ArticleParagraph(verbatim: String(localized: "The letter laam is always light, except in the word Allah (ٱللَّه)."))

                    TajweedWordCard(String(localized: "Heavy Laam (Only in \"Allah\")"), note: String(localized: "When preceded by fathah or dammah:"), words: [
                        TajweedWord("ٱللَّهُ", "Allahu"),
                        TajweedWord("قَالَ ٱللَّهُ", "qala Allahu"),
                        TajweedWord("نَصۡرُ ٱللَّهِ", "nasru Allahi"),
                    ])

                    TajweedWordCard(String(localized: "Light Laam (After Kasrah)"), words: [
                        TajweedWord("بِٱللَّهِ", "billahi"),
                        TajweedWord("لِلَّهِ", "lillahi"),
                    ])
                }

                Section(header: ArticleHeader(String(localized: "C. ALIF (ا)"))) {
                    ArticleParagraph(verbatim: String(localized: "Alif itself has no sound; it inherits the weight of the letter before it."))

                    ArticleBullet(verbatim: String(localized: "After a heavy letter → alif sounds heavy"))
                    ArticleBullet(verbatim: String(localized: "After a light letter → alif sounds light"))

                    TajweedWordCard(String(localized: "Alif follows the letter before it"), words: [
                        TajweedWord("قَالَ", "qala", note: String(localized: "Heavy letter (ق)")),
                        TajweedWord("صَادِق", "sadiq", note: String(localized: "Heavy letter (ص)")),
                        TajweedWord("كَانَ", "kana", note: String(localized: "Light letter (ك)")),
                        TajweedWord("نَاس", "nas", note: String(localized: "Light letter (ن)")),
                    ])

                    TajweedFix(wrong: String(localized: "Making alif heavy by itself"), right: String(localized: "Alif follows, never leads"))
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
                    ArticleHeader(String(localized: "ON THE ALPHABET"))
                } footer: {
                    Text("Heaviness comes from two qualities: the tongue rising (isti\u{2019}la), and for the heaviest four, clamping as well (itbaq).")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "heavy-light-letters", title: String(localized: "Heavy and Light")),
                    TajweedCourseLesson(id: "ra-tafkheem-tarqeeq", title: String(localized: "The Ra, Case by Case")),
                    TajweedCourseLesson(id: "lafz-al-jalalah", title: String(localized: "The Lam of the Name of Allah")),
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
                Section(header: ArticleHeader(String(localized: "SHAMS AND QAMAR"))) {
                    ArticleLead(String(localized: "When the definite article ٱلـ (al-) appears before a noun, the pronunciation of the laam (ل) depends on the first letter of the word that follows."), eyebrow: String(localized: "IN SHORT"))

                    ArticleParagraph(verbatim: String(localized: "The mushaf clearly indicates this through shaddah or sukun."))
                }

                Section(header: ArticleHeader(String(localized: "1. QAMARIYYAH (MOON LETTERS)"))) {
                    ArticleParagraph(verbatim: String(localized: "With qamariyyah letters, the laam is pronounced clearly."))

                    ArticleChecklist([String(localized: "The laam has a sukun (ٱلۡ)"), String(localized: "The sound is al-")], title: String(localized: "Rule"))

                    TajweedLetterStrip(String(localized: "Qamariyyah Letters"),
                                       note: String(localized: "The classic list opens with an alif. It is really the hamza, as in ٱلۡأَرۡض: no word begins with a bare alif."),
                                       letters: LetterTraits.moonLetters.letters, tint: LetterTraits.moonLetters.legendColor) { door = .letter($0) }

                    TajweedWordCard(String(localized: "Moon letters: the laam is read"), words: [
                        TajweedWord("ٱلۡقَمَر", "al-qamar"),
                        TajweedWord("ٱلۡكِتَٰب", "al-kitab"),
                        TajweedWord("ٱلۡحَقّ", "al-haqq"),
                        TajweedWord("ٱلۡغَفُور", "al-ghafur"),
                        TajweedWord("ٱلۡيَوۡم", "al-yawm"),
                    ])

                    TajweedFix(wrong: String(localized: "Dropping the laam"), right: String(localized: "Pronouncing al-"))
                }

                Section(header: ArticleHeader(String(localized: "2. SHAMSIYYAH (SUN LETTERS)"))) {
                    ArticleParagraph(verbatim: String(localized: "With shamsiyyah letters, the laam is not pronounced. Instead, it merges into the following letter, which is doubled (shown by a shaddah)."))

                    ArticleChecklist([String(localized: "No sukun on the laam"),
                                      String(localized: "The next letter has a shaddah"),
                                      String(localized: "Pronounce the word as if it begins with the doubled letter")],
                                     title: String(localized: "Rule"))

                    TajweedLetterStrip(String(localized: "Shamsiyyah Letters"), letters: LetterTraits.sunLetters.letters, tint: LetterTraits.sunLetters.legendColor) { door = .letter($0) }

                    TajweedWordCard(String(localized: "Sun letters: the laam merges"), words: [
                        TajweedWord("ٱلشَّمۡس", "ash-shams"),
                        TajweedWord("ٱلنَّاس", "an-nas"),
                        TajweedWord("ٱلرَّحۡمَٰن", "ar-rahman"),
                        TajweedWord("ٱلصِّرَٰط", "as-sirat"),
                        TajweedWord("ٱلتَّوۡبَة", "at-tawbah"),
                    ])

                    TajweedFix(wrong: "al-shams", right: "ash-shams")
                }

                Section(header: ArticleHeader(String(localized: "IMPORTANT NOTES"))) {
                    ArticleBullet(verbatim: String(localized: "This rule applies only to the definite article ٱلـ, not to every laam."))
                    ArticleBullet(verbatim: String(localized: "The shaddah is your visual cue: if you see it, the laam is not read."))
                    ArticleBullet(verbatim: String(localized: "This is idghaam of the laam, not deletion."))

                    ArticleClosing(String(localized: "If you see a shaddah, the laam is gone."))
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.sunLetters)
                    TajweedFamilyRow(LetterTraits.moonLetters)
                } header: {
                    ArticleHeader(String(localized: "ON THE ALPHABET"))
                } footer: {
                    Text("Every letter page says which side it is on, with a word from the Quran.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "lam-shamsiyyah-qamariyyah", title: String(localized: "The Lam of ال: Sun and Moon")),
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
                Section(header: ArticleHeader(String(localized: "MADD"))) {
                    ArticleLead(String(localized: "Madd means to lengthen a sound. In Quranic recitation, this lengthening is measured, consistent, and rule-based, not stylistic."), eyebrow: String(localized: "IN SHORT"))

                    TajweedKeyLine(String(localized: "Madd is counted in harakat (counts)."), systemImage: "timer")
                }

                Section(header: ArticleHeader(String(localized: "1. MADD TABII (NATURAL)"))) {
                    ArticleParagraph(verbatim: String(localized: "This is the default madd. If no special condition follows, this is what you apply."))

                    ArticleChecklist([String(localized: "Alif (ا) preceded by fathah"),
                                      String(localized: "Waw (و) preceded by dammah"),
                                      String(localized: "Yaa (ي) preceded by kasrah"),
                                      String(localized: "No hamzah or sukun after")],
                                     title: String(localized: "When It Occurs"))

                    TajweedKeyLine(String(localized: "Length: 2 counts"), systemImage: "timer")

                    TajweedWordCard(String(localized: "Natural madd, two counts"), words: [
                        TajweedWord("قَالَ", "qa-la"),
                        TajweedWord("يَقُولُ", "ya-qu-lu"),
                        TajweedWord("فِيهِ", "fi-hi"),
                        TajweedWord("نُور", "nur"),
                    ])

                    ArticleParagraph(verbatim: String(localized: "If nothing special comes after, 2 counts, no more, no less."))
                }

                Section(header: ArticleHeader(String(localized: "2. MADD WAJIB MUTTASIL"))) {
                    ArticleChecklist([String(localized: "A madd letter"), String(localized: "Followed by a hamzah"), String(localized: "In the same word")],
                                     title: String(localized: "When It Occurs"))

                    TajweedKeyLine(String(localized: "Length: 4 or 5 counts (be consistent)"), systemImage: "timer")

                    TajweedWordCard(String(localized: "Madd letter, then a hamzah in the same word"), words: [
                        TajweedWord("جَآءَ", "jaaa"),
                        TajweedWord("ٱلسَّمَآءِ", "as-samaaa"),
                        TajweedWord("سُوٓءَ", "suuu"),
                    ])

                    ArticleParagraph(verbatim: String(localized: "It is called wajib because the lengthening is mandatory."))
                }

                Section(header: ArticleHeader(String(localized: "3. MADD JAIZ MUNFASIL"))) {
                    ArticleChecklist([String(localized: "A madd letter at the end of a word"), String(localized: "Followed by a hamzah"), String(localized: "In the next word")],
                                     title: String(localized: "When It Occurs"))

                    TajweedKeyLine(String(localized: "Length: 2, 4, or 5 counts (be consistent)"), systemImage: "timer")

                    ArticleParagraph(verbatim: String(localized: "Choose one and stay consistent."))

                    TajweedWordCard(String(localized: "Madd letter ending one word, hamzah beginning the next"), words: [
                        TajweedWord("فِيٓ أَنفُسِكُمۡ", "fi an-fu-si-kum"),
                        TajweedWord("قَالُوٓاْ إِنَّا", "qalu in-na"),
                        TajweedWord("إِنَّآ أَعۡطَيۡنَٰكَ", "in-naa a'-tay-naa-ka"),
                    ])

                    ArticleParagraph(verbatim: String(localized: "If you lengthen it, always lengthen it. If you keep it short, always keep it short."))
                }

                Section(header: ArticleHeader(String(localized: "3B. MADD MUNFASIL HUKMI (RULED SEPARATED)"))) {
                    ArticleParagraph(verbatim: String(localized: "A special, \u{201C}ruled\u{201D} (hukmi) form of Madd Munfasil. The madd letter and the hamzah are written inside one word, so it looks like Madd Muttasil, but it is recited as a separated madd."))

                    ArticleCallout(paragraphs: [String(localized: "The madd letter is actually the tail of a small joined particle, the vocative يَا (\u{201C}O \u{2026}\u{201D}) or the demonstrative هَا (\u{201C}here/these \u{2026}\u{201D}), and the hamzah begins the word it is attached to. So in meaning it is two words, even though the script joins them.")],
                                   title: String(localized: "Why It Is Separated"), systemImage: "questionmark.circle.fill")

                    ArticleChecklist([String(localized: "A superscript madd letter, dagger alif (\u{0640}\u{0670}), small waw (\u{0640}\u{06E5}), or small yaa (\u{0640}\u{06E6}), carrying a maddah (\u{0640}\u{0653})"),
                                      String(localized: "Immediately followed by a hamzah in the SAME written word"),
                                      String(localized: "The carrier is the tail of a joined يَا or هَا particle")],
                                     title: String(localized: "How To Spot It"), systemImage: "magnifyingglass.circle.fill")

                    TajweedKeyLine(String(localized: "Length: 2, 4, or 5 counts (treated exactly like Madd Munfasil; be consistent)"), systemImage: "timer")

                    TajweedWordCard(String(localized: "Joined in writing, separated in ruling"), words: [
                        TajweedWord("يَٰٓأَيُّهَا", "ya + ayyuha", note: String(localized: "O you…")),
                        TajweedWord("هَٰٓأَنتُمۡ", "ha + antum", note: String(localized: "here you are")),
                        TajweedWord("يَٰٓإِبۡرَٰهِيمُ", "ya + Ibrahim", note: String(localized: "O Abraham")),
                        TajweedWord("يَٰٓـَٔادَمُ", "ya + Adam", note: String(localized: "O Adam")),
                    ])

                    TajweedWordCard(String(localized: "One Word Can Hold Two Different Madds"),
                                    note: String(localized: "Do not assume every long madd in these words is hukmi. The word هَٰٓؤُلَآءِ contains BOTH:"),
                                    words: [
                                        TajweedWord("هَٰٓؤُ", String(localized: "Madd Munfasil Hukmi"), note: String(localized: "The joined هَا particle")),
                                        TajweedWord("لَآءِ", String(localized: "A true Madd Muttasil"), note: String(localized: "A real alif + hamzah in one word")),
                                    ])

                    ArticleParagraph(verbatim: String(localized: "Only the superscript-particle sequence is munfasil hukmi. Every other madd in the word follows the normal rules."))

                    TajweedArabicLine("هَٰٓأَنتُمۡ · هَٰٓؤُلَآءِ · أَهَٰٓؤُلَآءِ · وَهَٰٓؤُلَآءِ · يَٰٓـَٔادَمُ · وَيَٰٓـَٔادَمُ · يَٰٓأَبَانَا · يَٰٓأَبَتِ · يَٰٓإِبۡرَٰهِيمُ · يَٰٓإِبۡلِيسُ · يَٰٓأُخۡتَ · يَٰٓأَرۡضُ · يَٰٓأَسَفَىٰ · يَٰٓأَهۡلَ · يَٰٓأُوْلِي · يَٰٓأَيَّتُهَا · يَٰٓأَيُّهَ · يَٰٓأَيُّهَا",
                                      title: String(localized: "The Complete Set In The Qur\u{2019}an"),
                                      caption: String(localized: "Counting orthographic variants such as يَٰٓأَبَانَآ and the pause-mark forms, this is 21 written words in the Hafs muṣḥaf."),
                                      size: 21)
                }

                Section(header: ArticleHeader(String(localized: "3C. OTHER MADD TYPES & EXCEPTIONS"))) {
                    ArticleParagraph(verbatim: String(localized: "Several named madds and special cases sit alongside the main five. They matter for accurate recitation and for any rule engine."))

                    TajweedWordCard(String(localized: "Madd Badal: hamzah BEFORE the madd"),
                                    note: String(localized: "A hamzah followed by a madd letter (the reverse of muttasil). Read 2 counts; it is not lengthened like muttasil."),
                                    words: [
                                        TajweedWord("ءَامَنُواْ", "aa-manu"),
                                        TajweedWord("ءَادَمَ", "aa-dama"),
                                    ])

                    TajweedWordCard(String(localized: "Madd \u{02BF}Iwad: tanwin fath at a stop"),
                                    note: String(localized: "When you stop on a word ending in tanwin fath (\u{0640}\u{064B}), the tanwin drops and the alif is stretched 2 counts. It is not aarid lis-sukoon."),
                                    words: [
                                        TajweedWord("عَلِيمًا", String(localized: "stop: a-li-maa")),
                                        TajweedWord("غَفُورًا", String(localized: "stop: gha-fu-raa")),
                                    ])

                    TajweedWordCard(String(localized: "Madd Tamkin: doubled yaa"),
                                    note: String(localized: "A kasrah + shaddah yaa meeting a madd yaa. Read 2 counts, taking care not to swallow either yaa."),
                                    words: [
                                        TajweedWord("ٱلنَّبِيِّـۧنَ", "an-nabiy-yiin"),
                                        TajweedWord("حُيِّيتُم", "huy-yi-tum"),
                                    ])

                    TajweedWordCard(String(localized: "Madd Silah: the pronoun haa"),
                                    note: String(localized: "The attached pronoun \u{0647} (\u{201C}his/its\u{201D}) between two voweled letters is given a hidden waw/yaa. Sughra (small) is 2 counts; Kubra (large) is 4\u{2013}5 counts when a hamzah follows; it then behaves like Madd Munfasil."),
                                    words: [
                                        TajweedWord("إِنَّهُۥ كَانَ", "sughra: in-na-hu"),
                                        TajweedWord("بِهِۦٓ أَحَدٗا", String(localized: "kubra: bi-hii (before hamzah)")),
                                    ])

                    ArticleCallout(paragraphs: [String(localized: "Superscript madd marks, dagger alif (\u{0640}\u{0670}), small waw (\u{0640}\u{06E5}), small yaa (\u{0640}\u{06E6}), are still a 2-count natural madd even though they are written tiny. When such a mark also carries a maddah (\u{0640}\u{0653}) and a hamzah follows, it becomes the munfasil-hukmi case above.")],
                                   title: String(localized: "Dagger Alif & Tiny Madd Marks"), systemImage: "info.circle.fill")

                    TajweedWordCard(String(localized: "Genuine Muttasil Written With A Dagger Alif"),
                                    note: String(localized: "Not every dagger alif + hamzah is hukmi. When both sit inside one true word (no joined يَا/هَا particle), it is ordinary Madd Muttasil, for example أُوْلَٰٓئِكَ, مَلَٰٓئِكَة, and إِسۡرَٰٓءِيل."),
                                    words: [
                                        TajweedWord("أُوْلَٰٓئِكَ", "muttasil: ula-aa-ika"),
                                        TajweedWord("مَلَٰٓئِكَةِ", "muttasil: mala-aa-ikah"),
                                    ])
                }

                Section(header: ArticleHeader(String(localized: "4. ENDING MADD"))) {
                    ArticleParagraph(verbatim: String(localized: "Ending madd applies when you stop on a word and the ending sound changes because of waqf. It includes Madd Aarid lis-Sukoon and Madd Leen."))

                    ArticleChecklist([String(localized: "A sakin yaa or sakin waaw"), String(localized: "Preceded by fathah"), String(localized: "You stop on the word")],
                                     title: String(localized: "Madd Leen"))

                    TajweedWordCard(String(localized: "Leen letters, lengthened only at a stop"), words: [
                        TajweedWord("خَوۡف", "khawf"),
                        TajweedWord("بَيۡت", "bayt"),
                        TajweedWord("قُرَيۡش", "quraysh"),
                        TajweedWord("شَيۡءٌ", "shay'"),
                    ])

                    // The correction the course merge made (2026-09-23): the old page listed شَيۡءٌ as a
                    // muttasil example, but in Hafs its ya is a leen letter.
                    TajweedFix(wrong: String(localized: "Stretching the ya of شَيۡءٌ while reading on, as if it were a joined madd."),
                               right: String(localized: "In Hafs it is a leen letter: no length while reading on, and 2, 4 or 6 counts only at a stop."))

                    TajweedWordCard(String(localized: "Madd Aarid lis-Sukoon"), words: [
                        TajweedWord("ٱلۡعَٰلَمِينَ", String(localized: "stop: a temporary sukoon on the ن")),
                        TajweedWord("ٱلرَّحِيمِ", String(localized: "stop: ٱلرَّحِيمۡ")),
                        TajweedWord("نَسۡتَعِينُ", String(localized: "stop: a temporary sukoon on the ن")),
                    ])

                    TajweedKeyLine(String(localized: "Length: 2, 4, or 6 counts. Madd Leen should follow the stopping style you choose for Madd Aarid lis-Sukoon, and should not be longer than it."), systemImage: "timer")
                }

                Section(header: ArticleHeader(String(localized: "5. MADD LAZIM"))) {
                    ArticleParagraph(verbatim: String(localized: "This is the strongest and longest madd."))

                    ArticleChecklist([String(localized: "A madd letter"), String(localized: "Followed by a permanent sukun"), String(localized: "Either in a word or a letter name")],
                                     title: String(localized: "When It Occurs"))

                    TajweedKeyLine(String(localized: "Length: 6 counts (always)"), systemImage: "timer")

                    TajweedWordCard(String(localized: "A. Madd Lazim Harfi"),
                                    note: String(localized: "Occurs in the disconnected letters at the start of some surahs. If the letter name itself contains a madd followed by sukun, it is 6 counts."),
                                    words: [
                                        TajweedWord("الٓمٓ", String(localized: "Alif (no madd) Laaaaaam (6) Miiiiiim (6)")),
                                        TajweedWord("كٓهيعٓصٓ", "Kaaaaaaf (6) Haa (2) Yaa (2) 'Ayyyn (4-6) Saaaaaad (6)"),
                                        TajweedWord("حمٓ", "Haa (2) Miiiiiim (6)"),
                                    ], stacked: true)

                    TajweedWordCard(String(localized: "B. Madd Lazim Kalimi"), note: String(localized: "Less common, but very important."), words: [
                        TajweedWord("ٱلضَّآلِّينَ", "ad-daaallin"),
                        TajweedWord("ٱلطَّآمَّةُ", "at-taaammah"),
                    ])
                }

                Section(header: ArticleHeader(String(localized: "OPENING LETTERS (MUQATTA’AT)"))) {
                    ArticleParagraph(verbatim: String(localized: "Some opening letters do not contain madd. Not every opening letter is lengthened. Read the letter name."))

                    ArticleChecklist([String(localized: "\u{200E}ألف (alone): no madd")], title: String(localized: "Read Normally (No Madd)"), systemImage: "minus.circle.fill")

                    ArticleChecklist([String(localized: "6 counts: نقص عسلكم"), String(localized: "2 counts: حي طهر"), String(localized: "'Ayn (ع) is a leen letter: 4 or 6 counts.")],
                                     title: String(localized: "Have Madd"), systemImage: "timer")

                    // Tiles, not a line of text: each letter opens its own page (Abu, 2026-09-20).
                    TajweedLetterStrip(String(localized: "6 counts"), letters: LetterTraits.openersSix.letters, tint: LetterTraits.openersSix.legendColor) { door = .letter($0) }

                    TajweedLetterStrip(String(localized: "2 counts"), letters: LetterTraits.openersTwo.letters, tint: LetterTraits.openersTwo.legendColor) { door = .letter($0) }
                }

                Section(header: ArticleHeader(String(localized: "KEY TEACHING RULES"))) {
                    ArticleCallout(paragraphs: [String(localized: "Madd is measured, not emotional. Do not stretch because it sounds nice."),
                                                String(localized: "Consistency matters more than length. 4 everywhere is better than random 2-6."),
                                                String(localized: "Never add a jump or break mid-madd. One smooth airflow from start to finish.")],
                                   title: String(localized: "Remember"), systemImage: "lightbulb.fill")
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.maddLetters)
                    TajweedFamilyRow(LetterTraits.leen)
                    TajweedFamilyRow(LetterTraits.openersSix)
                    TajweedFamilyRow(LetterTraits.openersTwo)
                } header: {
                    ArticleHeader(String(localized: "ON THE ALPHABET"))
                } footer: {
                    Text("Open a family for its letters and the phrase that gathers them.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "mudood-chart", title: String(localized: "The Whole Map")),
                    TajweedCourseLesson(id: "madd-tabii", title: String(localized: "Madd Tabi'i: The Natural Length")),
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
                Section(header: ArticleHeader(String(localized: "QALQALAH"))) {
                    ArticleLead(String(localized: "Qalqalah is a natural bouncing sound that occurs when certain letters are in a sukun state. It is not a vowel and not silence."), eyebrow: String(localized: "IN SHORT"))

                    ArticleParagraph(verbatim: String(localized: "Its purpose is to prevent the sound from becoming cut off or broken."))
                }

                Section(header: ArticleHeader(String(localized: "THE FIVE LETTERS"))) {
                    // Tiles, not a line of text: each letter opens its own page (Abu, 2026-09-20).
                    TajweedLetterStrip(String(localized: "The qalqalah letters are:"), letters: LetterTraits.qalqalah.letters,
                                       tint: LetterTraits.qalqalah.legendColor) { door = .letter($0) }
                }

                Section(header: ArticleHeader(String(localized: "WHAT QALQALAH IS (AND IS NOT)"))) {
                    ArticleChecklist([String(localized: "A slight echo"), String(localized: "Natural and effortless")], title: String(localized: "It Is"))

                    ArticleChecklist([String(localized: "Not a fathah"), String(localized: "Not an added vowel"), String(localized: "Not exaggerated")],
                                     title: String(localized: "It Is Not"), systemImage: "xmark.circle.fill")

                    TajweedKeyLine(String(localized: "Think of it as releasing the letter, not opening the mouth."), systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader(String(localized: "WHEN QALQALAH OCCURS"))) {
                    ArticleChecklist([String(localized: "Has a sukun, or"), String(localized: "Is stopped on (waqf)")],
                                     title: String(localized: "Qalqalah occurs when one of the five letters:"))

                    TajweedWordCard(String(localized: "A sakin qalqalah letter, bounced"), words: [
                        TajweedWord("أَحَدۡ", "aha(d)"),
                        TajweedWord("يَجۡعَل", "ya(j)-'al"),
                        TajweedWord("أَجۡر", "a(j)r"),
                        TajweedWord("يَقۡطَع", "ya(q)ta'"),
                        TajweedWord("يَبۡتَغُون", "ya(b)taghun"),
                    ])

                    TajweedKeyLine(String(localized: "Notice: the sound is heard, but no vowel is added."), systemImage: "ear")
                }

                Section(header: ArticleHeader(String(localized: "WHY QALQALAH EXISTS"))) {
                    ArticleBullet(verbatim: String(localized: "Without qalqalah, the letter would sound cut off."))
                    ArticleBullet(verbatim: String(localized: "Without qalqalah, words would sound unnatural or unclear."))

                    ArticleChecklist([String(localized: "Clarity"), String(localized: "Letter identity"), String(localized: "Flow of speech")], title: String(localized: "Qalqalah preserves:"))

                    ArticleParagraph(verbatim: String(localized: "Qalqalah exists because Arabic does not allow these letters to die silently."))
                }

                Section(header: ArticleHeader(String(localized: "IMPORTANT REMINDER"))) {
                    ArticleClosing(String(localized: "Qalqalah is a sound, not a vowel. If it sounds like \"a\", it is wrong. If it disappears, it is also wrong."))
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.qalqalah)
                    TajweedFamilyRow(LetterTraits.shiddah)
                    TajweedFamilyRow(LetterTraits.jahr)
                } header: {
                    ArticleHeader(String(localized: "ON THE ALPHABET"))
                } footer: {
                    Text("Why these five: each stops the sound (shiddah) and holds back the breath (jahr), so only a bounce can make it heard.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "qalqalah", title: String(localized: "Qalqalah: The Five That Bounce")),
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
                Section(header: ArticleHeader(String(localized: "NOON SAKINAH AND TANWEEN"))) {
                    ArticleLead(String(localized: "Tanween and noon saakinah are closely related, so this section groups the merge and hidden-sound rules together."), eyebrow: String(localized: "IN SHORT"))
                }

                Section(header: ArticleHeader(String(localized: "TANWEEN PRONUNCIATION"))) {
                    ArticleParagraph(verbatim: String(localized: "Although tanween appears as vowel marks, it is pronounced as a hidden noon sound (نْ) at the end of the word."))

                    TajweedWordCard(String(localized: "Tanween is said as a noon"), words: [
                        TajweedWord("بًا", String(localized: "ban, said as بَنۡ")),
                        TajweedWord("بٌ", String(localized: "bun, said as بُنۡ")),
                        TajweedWord("بٍ", String(localized: "bin, said as بِنۡ")),
                    ])

                    ArticleParagraph(verbatim: String(localized: "What happens to this hidden sound depends entirely on the letter that follows."))
                }

                Section(header: ArticleHeader(String(localized: "MUSHAF TANWEEN HINTS"))) {
                    ArticleParagraph(verbatim: String(localized: "The Mushaf often hints whether tanween is normal idhaar or whether a special noon sakinah rule is coming."))

                    TajweedWordCard(String(localized: "Two ways of writing tanween"), words: [
                        TajweedWord("رٞ  لٖ  رٗ", String(localized: "special tanween marks"), note: String(localized: "Apply ikhfaa, idghaam, iqlaab, or ghunnah by the next letter")),
                        TajweedWord("نٌ  قٍ  بً", String(localized: "normal tanween marks"), note: String(localized: "Usually clear idhaar when followed by idhaar letters")),
                    ])
                }

                Section(header: ArticleHeader(String(localized: "1. IDHAAR (CLEAR)"))) {
                    ArticleParagraph(verbatim: String(localized: "The noon sound is pronounced clearly and fully, with no ghunnah merge."))

                    // Tiles, not a line of text: each letter opens its own page (Abu, 2026-09-20).
                    TajweedLetterStrip(String(localized: "Letters"), letters: LetterTraits.idhaar.letters, tint: LetterTraits.idhaar.legendColor) { door = .letter($0) }

                    TajweedWordCard(String(localized: "Example"), words: [TajweedWord("مِنۡ هَادٍ", "min hadin")])

                    ArticleParagraph(verbatim: String(localized: "The throat letters prevent merging, so the sound must remain clear."))
                }

                Section(header: ArticleHeader(String(localized: "2. IDGHAAM (MERGING)"))) {
                    ArticleParagraph(verbatim: String(localized: "The noon sound merges into the following letter."))

                    TajweedLetterStrip(String(localized: "Letters"), letters: LetterTraits.idghamGhunnah.letters + LetterTraits.idghamBilaGhunnah.letters) { door = .letter($0) }

                    TajweedLetterStrip(String(localized: "With Ghunnah"), letters: LetterTraits.idghamGhunnah.letters, tint: LetterTraits.idghamGhunnah.legendColor) { door = .letter($0) }

                    TajweedLetterStrip(String(localized: "Without Ghunnah"), letters: LetterTraits.idghamBilaGhunnah.letters, tint: LetterTraits.idghamBilaGhunnah.legendColor) { door = .letter($0) }

                    TajweedWordCard(String(localized: "Examples"), words: [
                        TajweedWord("مَن يَقُولُ", "may-yaqul", note: String(localized: "Idghaam with ghunnah")),
                        TajweedWord("مِّن رَّبِّهِمۡ", "mir-rabbihim", note: String(localized: "Idghaam without ghunnah")),
                    ])

                    ArticleParagraph(verbatim: String(localized: "With ghunnah: nasal sound. Without ghunnah: clean merge, no nasalization."))
                }

                Section(header: ArticleHeader(String(localized: "3. IQLAAB (CONVERSION)"))) {
                    ArticleParagraph(verbatim: String(localized: "The noon sound changes into a miim with ghunnah."))

                    TajweedLetterStrip(String(localized: "Letter"), letters: LetterTraits.iqlaab.letters, tint: LetterTraits.iqlaab.legendColor) { door = .letter($0) }

                    TajweedWordCard(String(localized: "Example"), words: [TajweedWord("سَمِيعُۢ بَصِيرٌ", "sami'um-basir")])

                    ArticleParagraph(verbatim: String(localized: "The noon is not pronounced. It becomes a hidden miim."))
                }

                Section(header: ArticleHeader(String(localized: "4. IKHFAA (HIDDEN)"))) {
                    ArticleParagraph(verbatim: String(localized: "The noon is hidden, pronounced with ghunnah, without full clarity or full merging."))

                    TajweedLetterStrip(String(localized: "Letters"),
                                       note: String(localized: "The remaining 15 letters: all except the idhaar, idghaam, and iqlaab letters."),
                                       letters: LetterTraits.ikhfaa.letters, tint: LetterTraits.ikhfaa.legendColor) { door = .letter($0) }

                    TajweedWordCard(String(localized: "Example"), words: [TajweedWord("مِن شَرِّ", String(localized: "min-sharri (nasal)"))])

                    ArticleParagraph(verbatim: String(localized: "The tongue does not fully touch the articulation point."))
                }

                Section(header: ArticleHeader(String(localized: "GHUNNAH STRENGTH"))) {
                    ArticleParagraph(verbatim: String(localized: "Not all ghunnah is the same strength."))

                    ArticleStep(String(localized: "1. **Strongest:** Noon or Miim with shaddah (نّ / مّ)"))
                    ArticleStep(String(localized: "2. **Medium:** Idghaam with ghunnah, then Ikhfaa"))
                    ArticleStep(String(localized: "3. **None:** Idghaam without ghunnah"))
                }

                Section(header: ArticleHeader(String(localized: "KEY TEACHING LINE"))) {
                    ArticleClosing(String(localized: "Tanween is not a vowel. It is a hidden noon sound in disguise. The rule is determined by the next letter, not the vowel mark."))
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
                    ArticleHeader(String(localized: "ON THE ALPHABET"))
                } footer: {
                    Text("Every letter page shows which of these it triggers, with an example from the Quran.")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "nun-sakin-overview", title: String(localized: "The Four Rules at a Glance")),
                    TajweedCourseLesson(id: "tanween", title: String(localized: "Tanween: The Noon You Cannot See")),
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
                Section(header: ArticleHeader(String(localized: "MEEM SAKINAH"))) {
                    ArticleLead(String(localized: "Meem Sakinah means a meem with sukoon: مْ. In tajweed, Meem Sakinah has three rules, and all three are called Shafawi because they are pronounced from the lips. The word Shafawi comes from shafah, meaning \"lip.\""), eyebrow: String(localized: "IN SHORT"))

                    ArticleChecklist([String(localized: "Ikhfaa Shafawi"), String(localized: "Idgham Shafawi"), String(localized: "Idhaar Shafawi")], title: String(localized: "The three rules are:"))

                    ArticleParagraph(verbatim: String(localized: "These rules depend on the letter that comes after the Meem Sakinah."))
                }

                Section(header: ArticleHeader(String(localized: "1. IKHFAA SHAFAWI"))) {
                    ArticleParagraph(verbatim: String(localized: "Ikhfaa Shafawi occurs when Meem Sakinah (مْ) is followed by the letter Ba (ب)."))

                    ArticleParagraph(verbatim: String(localized: "When this happens, the meem is hidden lightly while keeping ghunnah for two counts. The lips come close together, but the meem is not pronounced with full clarity like normal Idhaar."))

                    TajweedKeyLine(String(localized: "\u{200E}مْ\u{200E} + ب = Ikhfaa Shafawi"), systemImage: "equal.circle.fill")

                    TajweedArabicLine("أَم بِهِۦ جِنَّةُۢ", title: String(localized: "Example"),
                                      caption: String(localized: "How to read it: am bihi, with ghunnah for two counts."))

                    ArticleParagraph(verbatim: String(localized: "In this example, the Meem Sakinah in أَم is followed by ب in بِهِۦ, so it is read with Ikhfaa Shafawi."))
                }

                Section(header: ArticleHeader(String(localized: "2. IDGHAM SHAFAWI"))) {
                    ArticleParagraph(verbatim: String(localized: "Idgham Shafawi occurs when Meem Sakinah (مْ) is followed by another Meem (م)."))

                    ArticleParagraph(verbatim: String(localized: "When this happens, the first meem merges into the second meem, and the result is read as a doubled meem with ghunnah for two counts."))

                    TajweedKeyLine(String(localized: "\u{200E}مْ\u{200E} + م = Idgham Shafawi"), systemImage: "equal.circle.fill")

                    TajweedArabicLine("وَلَهُم مَّا يَشۡتَهُونَ", title: String(localized: "Example"),
                                      caption: String(localized: "How to read it: lahum maa, with ghunnah for two counts."))

                    ArticleParagraph(verbatim: String(localized: "In this example, the Meem Sakinah at the end of لَهُم is followed by another meem in مَّا, so the two meems merge."))
                }

                Section(header: ArticleHeader(String(localized: "3. IDHAAR SHAFAWI"))) {
                    ArticleParagraph(verbatim: String(localized: "Idhaar Shafawi occurs when Meem Sakinah (مْ) is followed by any letter other than Ba (ب) or Meem (م)."))

                    ArticleParagraph(verbatim: String(localized: "When this happens, the meem is pronounced clearly with no extra ghunnah beyond its normal sound."))

                    TajweedKeyLine(String(localized: "\u{200E}مْ\u{200E} + any letter except ب or م = Idhaar Shafawi"), systemImage: "equal.circle.fill")

                    TajweedArabicLine("وَمَا بَلَغُواْ مِعۡشَارَ مَآ ءَاتَيۡنَٰهُمۡ فَكَذَّبُواْ رُسُلِي", title: String(localized: "Example"), size: 24)

                    ArticleParagraph(verbatim: String(localized: "In this example, the Meem Sakinah in ءَاتَيۡنَٰهُمۡ is followed by ف, so it is read with Idhaar Shafawi."))

                    TajweedWordCard(String(localized: "Clear before any other letter"), words: [
                        TajweedWord("لَكُمۡ فِيهَا", "lakum fiha"),
                        TajweedWord("عَلَيۡكُمۡ سَلَامٌ", "alaykum salamun"),
                    ])
                }

                Section(header: ArticleHeader(String(localized: "MEEM MUSHADDADAH"))) {
                    ArticleParagraph(verbatim: String(localized: "A related rule is Meem Mushaddadah, which is a meem with shaddah: مّ."))

                    TajweedKeyLine(String(localized: "Whenever you see مّ, it must be pronounced with a strong ghunnah for two counts."), systemImage: "speaker.wave.2.fill")

                    TajweedWordCard(String(localized: "Examples"), words: [
                        TajweedWord("ثُمَّ", "thumma"),
                        TajweedWord("لَمَّا", "lamma"),
                    ])

                    ArticleParagraph(verbatim: String(localized: "This is not one of the three Meem Sakinah rules, but it is closely related because it also involves ghunnah on meem."))
                }

                Section(header: ArticleHeader(String(localized: "QUICK SUMMARY"))) {
                    TajweedKeyLine(String(localized: "Meem Sakinah = مْ"), systemImage: "m.circle.fill")

                    ArticleStep(verbatim: String(localized: "1. Ikhfaa Shafawi: مۡ\u{200E} + ب, hide the meem with ghunnah. Example: أَم بِهِۦ"))
                    ArticleStep(verbatim: String(localized: "2. Idgham Shafawi: مۡ\u{200E} + م, merge the two meems with ghunnah. Example: لَهُم مَّا"))
                    ArticleStep(verbatim: String(localized: "3. Idhaar Shafawi: مۡ\u{200E} + any letter except ب or م, pronounce the meem clearly. Example: لَكُمۡ فِيهَا"))
                }

                Section(header: ArticleHeader(String(localized: "SHORT SUMMARY"))) {
                    ArticleClosing(String(localized: "Meem Sakinah has three rules. If it is followed by Ba, it is read with Ikhfaa Shafawi, meaning the meem is hidden with ghunnah. If it is followed by another Meem, it is read with Idgham Shafawi, meaning the two meems merge with ghunnah. If it is followed by any other letter, it is read with Idhaar Shafawi, meaning the meem is pronounced clearly."))
                }

                // The same families the Arabic Alphabet groups its letters by, named in both languages,
                // so the rule and the letters it belongs to are one tap apart in either direction.
                Section {
                    TajweedFamilyRow(LetterTraits.ikhfaaShafawi)
                    TajweedFamilyRow(LetterTraits.idghamShafawi)
                    TajweedFamilyRow(LetterTraits.idhaarShafawi)
                    TajweedFamilyRow(LetterTraits.ghunnah)
                } header: {
                    ArticleHeader(String(localized: "ON THE ALPHABET"))
                } footer: {
                    Text("Every letter page shows which of these it triggers, with an example from the Quran.")
                }

                Section(header: ArticleHeader(String(localized: "WATCH"))) {
                    TajweedVideoLink(title: String(localized: "How to pronounce meem sakinah properly"),
                                     url: "https://www.youtube.com/watch?v=MAvDrZgWRTs")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "mim-sakin-rules", title: String(localized: "The Three Rules of Mim Sakin")),
                    TajweedCourseLesson(id: "noon-mim-mushaddad", title: String(localized: "Nun and Mim with a Shaddah")),
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
                Section(header: ArticleHeader(String(localized: "The 4 Types of Sukoon Marks in the Qur’an"))) {
                    ArticleLead(String(localized: "In the Uthmani script of the Qur’an, letters may carry different kinds of sukoon-style markings. These marks tell the reciter whether a letter is pronounced, skipped, pronounced only when stopping, or affected by a special tajweed rule."), eyebrow: String(localized: "IN SHORT"))
                }

                Section(header: ArticleHeader(String(localized: "1. Normal Sukoon: Pronounce the Letter Without a Vowel"))) {
                    ArticleParagraph(verbatim: String(localized: "This is the common Qur’anic sukoon mark written like ـۡ above a consonant. It means the letter has no vowel, but the letter itself is still pronounced clearly."))

                    TajweedArabicLine("رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ", title: String(localized: "Example"))

                    TajweedKeyLine(String(localized: "Simple rule: Pronounce the letter, but do not add a vowel after it."), systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader(String(localized: "2. Permanent Silent Letter: Always Skip It"))) {
                    ArticleParagraph(verbatim: String(localized: "This mark shows that the letter is written in the Qur’an’s script but is not pronounced. You skip it whether you continue reciting or stop."))

                    TajweedArabicLine("بِأَيۡيْدٖ", title: String(localized: "Example"))

                    TajweedKeyLine(String(localized: "Simple rule: The letter is written, but never pronounced."), systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader(String(localized: "3. Stop-Only Letter: Pronounce It Only If You Stop"))) {
                    ArticleParagraph(verbatim: String(localized: "This mark means the letter is ignored when continuing, but pronounced if you stop on the word."))

                    TajweedWordCard(String(localized: "Examples"), words: [
                        TajweedWord("قَوَارِيرَا۠", String(localized: "stop: قَوَارِيرَا")),
                        TajweedWord("أَنَا۠", String(localized: "in context: قُلۡ إِنَّمَآ أَنَا۠ بَشَرٞ مِّثۡلُكُمۡ")),
                    ], stacked: true)

                    TajweedKeyLine(String(localized: "Simple rule: Pronounce it when stopping, skip it when continuing."), systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader(String(localized: "4. No Sukoon Mark: Madd Letter or Special Tajweed Rule"))) {
                    ArticleParagraph(verbatim: String(localized: "Sometimes a letter has no sukoon mark and no vowel mark. This usually means one of two things: either it is a madd letter (stretched for two counts), or a consonant affected by a special tajweed rule."))

                    TajweedWordCard(String(localized: "Examples"), words: [
                        TajweedWord("يُقِيمُونَ", String(localized: "madd letter example")),
                        TajweedWord("يُنفِقُونَ", String(localized: "special tajweed (ikhfāʾ) example")),
                    ])

                    TajweedKeyLine(String(localized: "Simple rule: No mark usually means either natural madd or a special recitation rule is happening."), systemImage: "lightbulb.fill")

                    Text(verbatim: String(localized: "Note about the example رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ: there is a qalqalah effect in the consonant, but there is no special visual marking for qalqalah in the Uthmani script; you must know it by rule or consult the tajweed colors in the app to see it highlighted."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(header: ArticleHeader(String(localized: "Super Simple Summary"))) {
                    ArticleStep(verbatim: String(localized: "1. ـۡ Normal sukoon: Pronounce the consonant with no vowel. Example: رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ"))
                    ArticleStep(verbatim: String(localized: "2. Silent written letter: Skip it always. Example: كَانُواْ"))
                    ArticleStep(verbatim: String(localized: "3. Stop-only letter: Pronounce it only when stopping. Example: أَنَا۠ / قَوَارِيرَا۠"))
                    ArticleStep(verbatim: String(localized: "4. No mark: Either a madd letter or a special tajweed rule. Example: يُقِيمُونَ / يُنفِقُونَ"))
                }

                Section(header: ArticleHeader(String(localized: "WATCH"))) {
                    TajweedVideoLink(title: String(localized: "The four types of sukoon in the Quran"),
                                     url: "https://www.youtube.com/shorts/ZlMsseUu7hU")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "sukoon", title: String(localized: "Sukoon: The Letter at Rest")),
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
                Section(header: ArticleHeader(String(localized: "Hamzatul-Wasl: The Connecting Hamzah"))) {
                    ArticleLead(String(localized: "Hamzatul-Wasl means “the hamzah of connection.” It is only pronounced when beginning recitation from that word; if you connect from the previous word, the Hamzatul-Wasl is dropped and not pronounced."), eyebrow: String(localized: "IN SHORT"))

                    ArticleParagraph(verbatim: String(localized: "In the Uthmani Qur’an script, Hamzatul-Wasl is usually written as an alif with a small ṣād-like sign above it: ٱ"))

                    TajweedWordCard(String(localized: "Common examples"), words: [
                        TajweedWord("ٱبۡنُواْ", "ibnu"),
                        TajweedWord("ٱمۡشُواْ", "imshu"),
                        TajweedWord("ٱقۡضُوٓاْ", "iqdu"),
                        TajweedWord("ٱئۡتُواْ", "iitu", note: String(localized: "The sakin hamzah becomes a long i")),
                        TajweedWord("ٱئۡتُونِي", "iituni", note: String(localized: "The same long i")),
                    ])

                    TajweedKeyLine(String(localized: "Key rule: If you start from the word, pronounce Hamzatul-Wasl. If you connect from the previous word, drop it."), systemImage: "key.fill")
                }

                Section(header: ArticleHeader(String(localized: "1. Hamzatul-Wasl Is Dropped When Connecting"))) {
                    ArticleParagraph(verbatim: String(localized: "When reciting continuously, Hamzatul-Wasl is not pronounced. The previous word connects directly into the next word."))

                    TajweedArabicLine("ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِۛ", title: String(localized: "Example"), size: 24)

                    ArticleParagraph(verbatim: String(localized: "When continuing: dhālika l-kitāb (you do not say al- as a separate hamzah). If you stop and then begin from the word, pronounce the Hamzatul-Wasl: al-kitāb."))
                }

                Section(header: ArticleHeader(String(localized: "2. Hamzatul-Wasl With “Al” Takes Fatḥah"))) {
                    ArticleParagraph(verbatim: String(localized: "When a word begins with the definite article ٱل, Hamzatul-Wasl is pronounced with fatḥah if you begin from that word (al-kitāb → al-kitāb; al-rahmān → ar-raḥmān)."))

                    TajweedWordCard(String(localized: "With the article: start with a fatha"), words: [
                        TajweedWord("ٱلۡكِتَٰبُ", "al-kitāb"),
                        TajweedWord("ٱلرَّحۡمَٰنُ", "ar-raḥmān"),
                        TajweedWord("ٱلصَّمَدُ", "aṣ-ṣamad"),
                        TajweedWord("ٱللَّهُ", "Allāh"),
                    ])

                    Text(verbatim: String(localized: "Note: alif itself is treated as a vowel/madd letter; the opening sound of ٱل is the Hamzatul-Wasl, realized as an initial “a”."))
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Section(header: ArticleHeader(String(localized: "3. Hamzatul-Wasl in Nouns Usually Takes Kasrah"))) {
                    ArticleParagraph(verbatim: String(localized: "In nouns that begin with Hamzatul-Wasl and do not begin with ٱل, the Hamzatul-Wasl is pronounced with kasrah when starting (e.g. ٱسۡمُهُۥ → ismuhu)."))

                    TajweedWordCard(String(localized: "The nouns: start with a kasra"), words: [
                        TajweedWord("ٱسۡم", "ism"),
                        TajweedWord("ٱبۡن", "ibn"),
                        TajweedWord("ٱبۡنَيۡ", "ibnay"),
                    ])
                }

                Section(header: ArticleHeader(String(localized: "4. Hamzatul-Wasl in Verbs Depends on the Third Letter"))) {
                    ArticleParagraph(verbatim: String(localized: "For verbs, examine the third letter: if it has ḍammah, begin with “u”; if it has fatḥah or kasrah, begin with “i”. Exception: when that ḍammah is incidental (ʿāriḍah), begin with kasrah instead: ٱمۡشُوا، ٱقۡضُوا، ٱبۡنُوا، ٱمۡضُوا، ٱئۡتُوا are read imshu, iqdu, ibnu, imdu, iitu, not umshu / uqdu / ubnu."))

                    TajweedWordCard(String(localized: "Example (third letter ḍammah → start with 'u')"), words: [
                        TajweedWord("ٱتۡلُ", String(localized: "utlu (when starting)"), note: String(localized: "When connected: watlu")),
                    ])

                    TajweedKeyLine(String(localized: "Simple rule: Third letter ḍammah → start with 'u'; otherwise start with 'i'."), systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader(String(localized: "5. Special Verb Exceptions"))) {
                    ArticleParagraph(verbatim: String(localized: "Some verbs are special cases (e.g. ٱئۡتُوا / ٱئۡتُونِي) and are learned individually; they may behave differently than the third-letter rule."))

                    TajweedWordCard(String(localized: "Example"), words: [
                        TajweedWord("ٱئۡتُونِي", String(localized: "iituni when starting"), note: String(localized: "The sakin hamzah becomes a long i")),
                    ])
                }

                Section(header: ArticleHeader(String(localized: "6. Hamzatul-Wasl After Tanwīn: Add a Connecting Nūn"))) {
                    ArticleParagraph(verbatim: String(localized: "When a word ending in tanwīn is followed by a word beginning with Hamzatul-Wasl, a connecting 'nِ' (kasrah nūn) is commonly inserted when continuing (e.g. بِغُلَٰمٍ ٱسۡمُهُۥ → bighulāmin ismuhu)."))

                    TajweedWordCard(String(localized: "Example"), words: [
                        TajweedWord("بِغُلَٰمٍ ٱسۡمُهُۥ ← بِغُلَٰمِنِ سۡمُهُۥ", "bighulāmin ismuhu"),
                    ], stacked: true, size: 23)
                }

                Section(header: ArticleHeader(String(localized: "Summary: How to Start Hamzatul-Wasl"))) {
                    ArticleStep(verbatim: String(localized: "1. If the word begins with ٱل → start with 'a' (fatḥah)."))
                    ArticleStep(verbatim: String(localized: "2. If a noun without ٱل → start with 'i' (kasrah)."))
                    ArticleStep(verbatim: String(localized: "3. If a verb → check the third letter (ḍammah → 'u', otherwise 'i')."))
                    ArticleStep(verbatim: String(localized: "4. Some words are exceptions and must be learned individually."))
                }

                Section(header: ArticleHeader(String(localized: "What Happens When Continuing"))) {
                    ArticleParagraph(verbatim: String(localized: "Hamzatul-Wasl is dropped when continuing from the previous word (e.g. ذَٰلِكَ ٱلۡكِتَٰبُ → dhālika l-kitāb; وَٱتۡلُ → watlu)."))
                }

                Section(header: ArticleHeader(String(localized: "SHORT SUMMARY"))) {
                    ArticleClosing(String(localized: "Hamzatul-Wasl is the connecting hamzah, pronounced only when starting from the word. Nouns usually take 'i', words with ٱل start with 'a', verbs depend on the third letter, and tanwīn before Hamzatul-Wasl connects with an 'nِ' sound."))
                }

                Section(header: ArticleHeader(String(localized: "WATCH"))) {
                    TajweedVideoLink(title: String(localized: "How to pronounce words with no tashkeel"),
                                     url: "https://www.youtube.com/shorts/SpA7EtX3jMA")
                    TajweedVideoLink(title: String(localized: "Hamzat al-wasl and hamzat al-qat'"),
                                     url: "https://www.youtube.com/shorts/xNn-pR4eoHM")
                    TajweedVideoLink(title: String(localized: "Alif and hamzah"),
                                     url: "https://www.youtube.com/shorts/79Ku0wSKf9Q")
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "hamzat-al-wasl", title: String(localized: "Hamzat al-Wasl: The Hamza That Comes and Goes")),
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
                Section(header: ArticleHeader(String(localized: "WAQF"))) {
                    ArticleLead(String(localized: "Waqf (وَقف) means to stop or pause while reciting the Quran, with the intention of resuming the recitation correctly afterward."), eyebrow: String(localized: "IN SHORT"))

                    ArticleParagraph(verbatim: String(localized: "The word comes from the Arabic root و ق ف, meaning to stop, stand, or halt. In tajweed, it refers specifically to stopping at the end of a word while preserving the meaning, pronunciation, and beauty of the Quran."))

                    ArticleParagraph(verbatim: String(localized: "Waqf is not random breathing. It is a deliberate, rule-based pause guided by the Mushaf and the meaning of the ayah."))
                }

                Section(header: ArticleHeader(String(localized: "WHY WAQF MATTERS"))) {
                    ArticleChecklist([String(localized: "Change the meaning of an ayah"),
                                      String(localized: "Create theological errors"),
                                      String(localized: "Break the grammatical structure"),
                                      String(localized: "Distort the listener's understanding")],
                                     title: String(localized: "Stopping incorrectly can:"), systemImage: "xmark.circle.fill")

                    ArticleChecklist([String(localized: "Preserves meaning"),
                                      String(localized: "Maintains clarity"),
                                      String(localized: "Reflects proper understanding"),
                                      String(localized: "Shows respect for the words of Allah")],
                                     title: String(localized: "Correct waqf:"))

                    ArticleParagraph(verbatim: String(localized: "A well-known definition attributed to Ali ibn Abi Talib (may Allah be pleased with him) calls tartil \"the tajweed of the letters and knowledge of the places of stopping.\" The tajweed books quote it without a chain (al-Hudhali, al-Waqf wa al-Ibtida', p. 377; Ibn al-Jazari, an-Nashr 1/225), so it is best held as the scholars' definition rather than a proven saying of his."))
                }

                Section(header: ArticleHeader(String(localized: "WAQF IN THE MUSHAF"))) {
                    ArticleParagraph(verbatim: String(localized: "Even without colors, the Mushaf signals where to stop or continue using:"))

                    ArticleBullet(verbatim: String(localized: "Special symbols"))
                    ArticleBullet(verbatim: String(localized: "Word endings"))
                    ArticleBullet(verbatim: String(localized: "Sentence structure"))
                    ArticleBullet(verbatim: String(localized: "Completion of meaning"))

                    ArticleParagraph(verbatim: String(localized: "A reader trained in waqf reads with understanding, not just sound."))
                }

                Section(header: ArticleHeader(String(localized: "LAST LETTER WHEN YOU STOP"))) {
                    ArticleParagraph(verbatim: String(localized: "When stopping, the ending of the word almost always changes."))

                    TajweedKeyLine(String(localized: "The Golden Rule of Waqf: every vowel at the end of a word becomes a sukun when stopping, except special cases."), systemImage: "star.fill")
                }

                Section(header: ArticleHeader(String(localized: "1. FINAL DAMMAH, FATHAH, OR KASRAH"))) {
                    ArticleParagraph(verbatim: String(localized: "When stopping, the vowel is dropped, and the letter becomes saakin."))

                    TajweedWordCard(String(localized: "Connected → Stopping"), words: [
                        TajweedWord("ٱلۡعَٰلَمِينَ ← ٱلۡعَٰلَمِينۡ", "al-'alamina → al-'alamin"),
                        TajweedWord("نَسۡتَعِينُ ← نَسۡتَعِينۡ", "nasta'inu → nasta'in"),
                        TajweedWord("ٱلۡكِتَٰبِ ← ٱلۡكِتَٰبۡ", "al-kitabi → al-kitab"),
                    ], stacked: true, size: 23)

                    ArticleParagraph(verbatim: String(localized: "The sound is cut cleanly, without adding extra vowels."))
                }

                Section(header: ArticleHeader(String(localized: "2. STOPPING ON TANWEEN"))) {
                    ArticleParagraph(verbatim: String(localized: "Tanween is never pronounced when stopping."))

                    TajweedWordCard(String(localized: "Tanween at a stop"), words: [
                        TajweedWord("بَصِيرٌ ← بَصِيرۡ", String(localized: "Dammatayn: dropped")),
                        TajweedWord("عَلِيمٍ ← عَلِيمۡ", String(localized: "Kasratayn: dropped")),
                        TajweedWord("رَحۡمَةً ← رَحۡمَهۡ", String(localized: "Fathatayn on ة: a sakin ha, no alif")),
                        TajweedWord("كِتَٰبًا ← كِتَٰبَا", String(localized: "Fathatayn + alif: the alif stays")),
                    ], stacked: true, size: 23)

                    ArticleParagraph(verbatim: String(localized: "Important: the tanween itself is dropped completely when stopping. There is no nuun sound and no vowel."))

                    ArticleParagraph(verbatim: String(localized: "Exception: when fathatayn is followed by an alif (ا), the tanween is dropped but the alif is still pronounced, producing a long a sound. This is because the alif is a written long vowel, not part of the tanween itself."))

                    TajweedKeyLine(String(localized: "Rule to remember: fathatayn disappears when stopping, but a written alif remains pronounced."), systemImage: "lightbulb.fill")
                }

                Section(header: ArticleHeader(String(localized: "3. TAA MARBUTAH (ة)"))) {
                    ArticleParagraph(verbatim: String(localized: "When stopping, taa marbutah is pronounced as haa saakinah (ـهۡ)."))

                    TajweedWordCard(String(localized: "Ta marbutah becomes a ha"), words: [
                        TajweedWord("رَحۡمَةٌ ← رَحۡمَهۡ", "rahmah"),
                        TajweedWord("جَنَّةٍ ← جَنَّهۡ", "jannah"),
                    ], stacked: true, size: 23)

                    ArticleParagraph(verbatim: String(localized: "This rule is consistent everywhere in the Quran."))
                }

                Section(header: ArticleHeader(String(localized: "4. LONG VOWELS (ا، و، ي)"))) {
                    ArticleParagraph(verbatim: String(localized: "Long vowels remain unchanged when stopping."))

                    TajweedWordCard(String(localized: "Long vowels stay"), words: [
                        TajweedWord("فِي ← فِي", String(localized: "Unchanged")),
                        TajweedWord("يَقُولُ ← يَقُولۡ", String(localized: "The final vowel drops, the long u stays")),
                    ], stacked: true, size: 23)

                    ArticleParagraph(verbatim: String(localized: "No shortening occurs."))
                }

                Section(header: ArticleHeader(String(localized: "THE FOUR KINDS OF STOP"))) {
                    ArticleStep(String(localized: "1. **Waqf Tam (Complete):** The meaning is complete and independent. Best place to stop."))
                    ArticleStep(String(localized: "2. **Waqf Kafi (Sufficient):** The meaning is complete, but connected to what follows. Permissible to stop."))
                    ArticleStep(String(localized: "3. **Waqf Hasan (Good):** The wording makes sense, but the meaning is incomplete. Allowed only for breath, not preferred."))
                    ArticleStep(String(localized: "4. **Waqf Qabih (Bad):** Stopping breaks the meaning or creates error. Not allowed."))
                }

                Section(header: ArticleHeader(String(localized: "DANGEROUS STOP EXAMPLE"))) {
                    TajweedArabicLine("لَا تَقۡرَبُواْ ٱلصَّلَوٰةَ", title: String(localized: "Example of a dangerous stop"),
                                      caption: String(localized: "Stopping here implies \"Do not approach prayer,\" which is incorrect."))

                    ArticleParagraph(verbatim: String(localized: "The ayah continues: وَأَنتُمۡ سُكَٰرَىٰ"))
                }

                Section(header: ArticleHeader(String(localized: "WAQF SYMBOLS"))) {
                    QuranSignsSectionContent(accentColor: appearance.accent)

                    ArticleParagraph(verbatim: String(localized: "These symbols guide meaning, not breathing convenience."))
                }

                Section(header: ArticleHeader(String(localized: "REMEMBER"))) {
                    ArticleClosing(String(localized: "Waqf is not about breath. It is about meaning. You stop where the meaning stops, not where the lungs give up."))
                }

                TajweedCourseLessons([
                    TajweedCourseLesson(id: "waqf-types", title: String(localized: "Where You May Stop")),
                    TajweedCourseLesson(id: "waqf-changes", title: String(localized: "What Changes When You Stop")),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Waqf")
    }
}
