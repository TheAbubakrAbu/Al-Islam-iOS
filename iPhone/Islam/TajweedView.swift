import SwiftUI

struct TajweedFoundationsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var showTajweedLegend = false

    private let topics: [String] = [
        "Improving Your Recitation",
        "Lip Movement",
        "Tajweed Hints in the Mushaf",
        "Makhaarij (Articulation)",
        "Heavy and Light",
        "Shams and Qamar: Al",
        "Madd (Elongation)",
        "Qalqalah",
        "Noon Sakinah and Tanween",
        "Meem Sakinah",
        "4 Sukoon",
        "Hamzatul Wasl",
        "Waqf (Stopping)"
    ]

    var body: some View {
        List {
            Group {
            Section("TAJWEED LEGEND") {
                #if os(iOS)
                Button {
                    settings.hapticFeedback()
                    showTajweedLegend = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quick Reference Guide")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)

                        Text("Simple way to view basic Hafs an Asim Tajweed rules with colors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                #endif
            }

            Section("OVERVIEW") {
                Text("Tajweed, Makharij, and Pronunciation")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("This guide applies specifically to riwayat Hafs an Asim, which is the most widely recited qiraah in the world today and the standard riwayah used in the majority of printed mushafs.")
                    .font(.body)

                Text("Tajweed (تجويد) refers to the science and practice of reciting the Quran correctly and beautifully, by giving each letter its proper articulation and characteristics. Linguistically, the word tajweed comes from the Arabic root ج-و-د (j-w-d), meaning \"to improve,\" \"to make excellent,\" or \"to perfect.\" In the context of the Quran, it means reciting the words of Allah as they were revealed precisely, clearly, and with care.")
                    .font(.body)

                Text("Recitation (قراءة qiraah or تلاوة tilawah) refers to the act of reading the Quran. While qiraah simply means \"reading,\" tilawah carries a deeper meaning of reciting with attentiveness, reflection, and adherence to proper method. Quranic recitation is not just reading text; it is the transmission of a preserved oral tradition passed down from the Prophet ﷺ through generations.")
                    .font(.body)

                Text("Pronunciation in Quranic recitation is governed by two key components: makharij (مخارج الحروف) and sifat (صفات الحروف). Makharij are the points of articulation, where each letter originates in the mouth or throat, while sifat are the characteristics of those letters, such as heaviness (tafkhim), lightness (tarqiq), or echoing (qalqalah). Together, they ensure that each letter is pronounced distinctly and correctly.")
                    .font(.body)

                Text("These elements are essential because even slight changes in pronunciation can alter meanings. Tajweed preserves not only the beauty of the Quran, but also its accuracy and integrity. The Quran was revealed to be recited, and Allah commands:")
                    .font(.body)

                VStack(alignment: .leading) {
                    Text("And recite the Quran with measured recitation (tartil).")
                        .font(.headline)
                        .foregroundColor(settings.accentColor.color)

                    Text("(73:4)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("For this reason, learning and applying tajweed is a means of preserving the exact words of the Quran as they were revealed and recited by the Prophet ﷺ, ensuring that its message remains unchanged across generations.")
                    .font(.body)
            }

            Section("WHY LEARN TAJWEED?") {
                Text("Honoring the Quran: The Quran is the final revelation from Allah. Reciting it with care and precision is a form of respect and reverence for the sacred text. By learning Tajweed, you follow the Prophet ﷺ who recited with the utmost clarity and eloquence.")
                    .font(.body)

                Text("Preventing Misunderstandings: By applying Tajweed rules, you avoid mistakes that may alter the meaning of verses. In some cases, even changing a single sound or stretching a vowel can result in an entirely different meaning.")
                    .font(.body)

                Text("Enhancing Spiritual Connection: Many Muslims find that reciting the Quran with Tajweed enhances their spiritual experience. The attention to detail required encourages mindfulness and deeper reflection on the meaning of the verses, making your recitation more immersive and meaningful.")
                    .font(.body)

                Text("Following the Sunnah: The Prophet Muhammad ﷺ encouraged reciting the Quran beautifully, saying: \"He is not one of us who does not recite the Quran melodiously\" (Sahih al-Bukhari 7527). By learning Tajweed, you honor his teachings and example.")
                    .font(.body)
            }

            Section("HOW TO START LEARNING") {
                Text("Learning Tajweed might seem challenging at first, but there are many resources available today to make the process easier. Traditionally, learning Tajweed was done with a teacher who could guide you through the articulation points and characteristics of each letter.")
                    .font(.body)

                Text("Now, in addition to teachers, there are online platforms, videos, and books that provide step-by-step lessons. For those starting out, focus on mastering the basic rules first and gradually build your skills over time. Practicing consistently is key; recording your recitation can help you catch mistakes and improve pronunciation.")
                    .font(.body)

                Text("Many learners find benefit in joining Tajweed classes or study groups, where they can receive feedback and support from others on the same journey.")
                    .font(.body)
            }

            Section("APPLICABILITY TO QIRAAT") {
                Text("Other riwayat, such as Warsh an Nafi, Khalaf an Hamzah, and others, may differ slightly in their application of tajweed rules, including elongations (madd), treatment of hamzah, and certain pronunciation details. These differences stem from authentic variations rooted in classical Arabic dialects and were transmitted through reliable chains of recitation.")
                    .font(.body)

                Text("As a result, some rules explained in this guide may not apply identically to other riwayat. These variations in tajweed application and pronunciation reflect the diversity of classical Arabic dialects that were all correctly recited and approved by the Prophet ﷺ, and have been preserved exactly through continuous transmission. They highlight the richness, flexibility, and authenticity of the Quranic recitation tradition.")
                    .font(.body)
            }

            Section("LEARN MORE") {
                Text("Learn More About Qiraat, Riwayat, and Ahruf")
                    .font(.subheadline.weight(.semibold))

                Text("See below and in Al-Islam View > Islamic Pillars and Basics.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                NavigationLink(destination: LazyDestination { QuranPillarView() }) {
                    Text("What is the Quran?")
                        .foregroundColor(settings.accentColor.color)
                }

                NavigationLink(destination: LazyDestination { TajweedView() }) {
                    Text("What is Tajweed?")
                        .foregroundColor(settings.accentColor.color)
                }

                NavigationLink(destination: LazyDestination { AhrufView() }) {
                    Text("What are the 7 Ahruf?")
                        .foregroundColor(settings.accentColor.color)
                }

                NavigationLink(destination: LazyDestination { QiraatView() }) {
                    Text("What are the 10 Qiraat?")
                        .foregroundColor(settings.accentColor.color)
                }
            }

            Section("TAJWEED TOPICS") {
                ForEach(topics, id: \.self) { topic in
                    NavigationLink(destination: LazyDestination { destinationView(for: topic) }) {
                        Text(topic)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .padding(.vertical, 4)
                }
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Tajweed Foundations")
        #if os(iOS)
        .sheet(isPresented: $showTajweedLegend) {
            NavigationView {
                TajweedLegendView()
            }
            .smallMediumSheetPresentation()
        }
        #endif
    }

    @ViewBuilder
    private func destinationView(for topic: String) -> some View {
        if topic == "Improving Your Recitation" {
            TajweedImprovingRecitationView()
        } else if topic == "Lip Movement" {
            TajweedFoundationsTopicView()
        } else if topic == "Tajweed Hints in the Mushaf" {
            TajweedInMushafView()
        } else if topic == "Makhaarij (Articulation)" {
            TajweedMakharijView()
        } else if topic == "Heavy and Light" {
            TajweedHeavyLightView()
        } else if topic == "Shams and Qamar: Al" {
            TajweedShamsQamarView()
        } else if topic == "Madd (Elongation)" {
            TajweedMaddView()
        } else if topic == "Qalqalah" {
            TajweedQalqalahView()
        } else if topic == "Noon Sakinah and Tanween" {
            TajweedIdghamIkhfaView()
        } else if topic == "Meem Sakinah" {
            TajweedMeemSakinahView()
        } else if topic == "4 Sukoon" {
            TajweedAaridLisSukoonView()
        } else if topic == "Hamzatul Wasl" {
            TajweedHamzatulWaslView()
        } else if topic == "Waqf (Stopping)" {
            TajweedWaqfView()
        } else {
            TajweedTopicPlaceholderView(title: topic)
        }
    }
}

private struct TajweedImprovingRecitationView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
            Section("VIDEO REFERENCES") {
                VStack(alignment: .leading, spacing: 6) {
                    Link("How to Improve Your Recitation 1", destination: URL(string: "https://www.youtube.com/watch?v=_acpVGn0ys0")!)
                    Link("How to Improve Your Recitation 2", destination: URL(string: "https://www.youtube.com/watch?v=86qiFqqZSG0")!)
                }
            }

            Section("IMPROVING YOUR RECITATION") {
                Text("This guide on its own is not enough to fully develop strong tajweed and pronunciation. While it can introduce the rules and concepts, real improvement in Quranic recitation requires consistent practice, listening, and guidance from knowledgeable teachers.")
                    .font(.body)

                Text("Ideally, this guide should be used alongside a teacher who can listen to your recitation and correct your mistakes. Tajweed is refined through feedback and repetition, and many pronunciation errors are difficult to notice on your own. To truly benefit from this guide, approach the Quran with sincerity, humility, and love. Put your trust in Allah and be willing to learn.")
                    .font(.body)

                Text("You must also set aside arrogance and ego. Even if you believe your tajweed, voice, or makharij are good, there is always room to improve. The greatest reciters spent years refining their recitation. Below are three consistent practices that will help maximize both this guide and your learning of tajweed.")
                    .font(.body)
            }

            Section("THREE PRACTICES FOR IMPROVING TAJWEED") {
                Text("Three Practices for Improving Tajweed")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("1. PRACTICE RECITING ON YOUR OWN") {
                Text("Reading the Quran regularly on your own is essential. This type of practice helps with:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Increasing reading fluency and speed")
                    Text("Improving familiarity with words and verses")
                    Text("Experimenting with voice control and tone")
                    Text("Applying corrections you have learned")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("However, it is important to understand something: the phrase \"practice makes perfect\" is not true. Rather, perfect practice makes perfect. If someone repeatedly practices incorrect pronunciation or recites carelessly, they may reinforce mistakes instead of correcting them.")
                    .font(.body)

                Text("For this reason, solo practice should focus on:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reading consistently")
                    Text("Reciting carefully with proper tajweed")
                    Text("Applying corrections learned from teachers or study")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("At the same time, even the best teacher cannot help you improve if you never put in the hours of practice yourself. But it cannot fully replace proper guidance.")
                    .font(.body)

                Text("This is similar to practicing a sport alone. Individual practice builds skill and stamina, but without proper technique, it will only take you so far. At the same time, even the best teacher cannot help you improve if you never put in the hours of practice yourself.")
                    .font(.body)
            }

            Section("2. LISTEN TO SKILLED RECITERS") {
                Text("Listening to skilled reciters is one of the most powerful ways to improve pronunciation and rhythm. Many students benefit from listening to classical Egyptian reciters such as Sheikh Muhammad Siddiq Al-Minshawi and Sheikh Mahmoud Khalil Al-Hussary.")
                    .font(.body)

                Text("Both reciters are widely respected for their clarity, precision, and strong tajweed.")
                    .font(.body)

                Text("Their recordings typically come in two styles:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Murattal: a steady, clear recitation ideal for learning")
                    Text("Mujawwad: a slower, melodic recitation that emphasizes precision and beauty")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Try to find a reciter whose voice you genuinely enjoy listening to. Developing a connection with a reciter often deepens your love for the Quran and increases your motivation to recite. However, do not listen passively. Instead, actively engage with the recitation:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Follow along in the mushaf while listening")
                    Text("Read aloud with the reciter")
                    Text("Attempt to mimic his tajweed and pronunciation")
                    Text("Pay attention to letter articulation, elongation, and pauses")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This is similar to studying expert athletes, learning from masters by carefully observing how they perform. You may also benefit from educational tajweed resources such as Learn Arabic 101 or other structured lessons.")
                    .font(.body)
            }

            Section("3. PRACTICE WITH A TEACHER OR PARTNER") {
                Text("Practicing with someone knowledgeable in tajweed is one of the most effective ways to improve your recitation. A teacher or experienced student can hear mistakes that you will not notice yourself, including:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Incorrect makharij (points of articulation)")
                    Text("Subtle pronunciation errors")
                    Text("Improper elongation (madd)")
                    Text("Weak ghunnah or nasalization")
                    Text("Mistakes in stopping or continuation")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Corrections may sometimes feel repetitive or strict, but they are extremely valuable.")
                    .font(.body)

                Text("Even small refinements can significantly improve your recitation. The best tajweed is the recitation that is correct and refined in all aspects, both major and subtle.")
                    .font(.body)

                Text("Learning with a teacher is similar to training with a coach in sports. A coach observes your technique and gives personalized corrections that accelerate your improvement.")
                    .font(.body)

                Text("If a formal teacher is not available, try to practice with someone knowledgeable who has strong tajweed and is willing to listen to your recitation and offer corrections.")
                    .font(.body)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Improving Your Recitation")
    }
}

private struct TajweedFoundationsTopicView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
            Section("NATURAL QURANIC RECITATION") {
                Text("Foundations of Natural Quranic Recitation")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Avoiding Overemphasis in Quranic Recitation | Correct Mouth and Lip Usage in Recitation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("One of the most common mistakes in Quranic recitation is overemphasis: exaggerating mouth movements, stretching the lips sideways, or forcing sounds in a way that is unnatural to Arabic speech. Correct tajweed is meant to preserve clarity and authenticity.")
                    .font(.body)
            }

            Section("GENERAL MOUTH AND LIP RULE") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lips move up and down only")
                    Text("Avoid side stretching or exaggerated shaping")
                    Text("The tongue and throat do most of the work")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("When recited correctly, Quranic Arabic should sound smooth, balanced, and natural, similar to careful classical Arabic speech.")
                    .font(.body)
            }

            Section("1. DAMMAH-RELATED SOUNDS (ُ ٌ و)") {
                Text("For all sounds related to dammah, the lips must round and project slightly forward to produce a true \"u\" sound.")
                    .font(.body)

                Text("This is the only time the lips clearly point outward.")
                    .font(.body)

                Text("Applies To: Dammah (ـُ), Dammatayn (ـٌ), Waw sakinah preceded by dammah (ـُو)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("2. MIM (م): LIP CLOSURE") {
                Text("The letter mim (م) is a bilabial letter, meaning it is produced using both lips.")
                    .font(.body)

                Text("Think of the lips as folding together, not squeezing.")
                    .font(.body)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Lip Movement")
    }
}

private struct TajweedInMushafView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    private var arabicFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("TAJWEED IN THE MUSHAF") {
                Text("Reading Tajweed Directly from the Mushaf")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Learning to See Tajweed in the Mushaf Itself")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Even without a color-coded mushaf, tajweed rules are visible directly in the text. The Quran is written in a way that signals when a sound should be held, merged, hidden, or pronounced clearly, if you know what to look for.")
                    .font(.body)

                Text("This section teaches you how to recognize tajweed visually, before memorizing specific rules.")
                    .font(.body)
            }

            Section("1. LETTERS WITHOUT SUKUN (EXCLUDING MADD)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If a letter:")
                    Text("has no sukun")
                    Text("and is not a madd letter (ا و ي)")
                    Text("then that letter must be held, and some tajweed rule applies.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This usually means:")
                    .font(.body)
                Text("Ghunnah, Ikhfaa, Idghaam, Iqlaab, and similar rules.")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedExampleRow(
                        arabic: "مِنْ",
                        middle: "Nun has sukun",
                        trailing: "Pronounce clearly",
                        arabicFont: arabicFont
                    )

                    TajweedExampleRow(
                        arabic: "مَن يَقُول",
                        middle: "No sukun on ن",
                        trailing: "Merge (idghaam)",
                        arabicFont: arabicFont
                    )

                    TajweedExampleRow(
                        arabic: "عَلِيمٌ",
                        middle: "Tanwin + no visible sukun",
                        trailing: "Apply rule",
                        arabicFont: arabicFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If there is no sukun, the sound does not pass quickly.")
                    .font(.body)
            }

            Section("2. TANWIN SHAPE") {
                Text("Tanwin always ends in a hidden nun sakinah, which is why its shape matters.")
                    .font(.body)
            }

            Section("SPECIAL TANWIN MARKS IN THE MUSHAF") {
                Text("Some Uthmani tanwin marks are drawn differently to tell you whether the hidden noon sound needs a special rule.")
                    .font(.body)

                Text("Version 1: special rule")
                    .font(.subheadline.weight(.semibold))

                Text("When the tanwin is written with the special mark, look at the next real letter and apply the noon sakinah/tanwin rule: ikhfaa, idghaam, iqlaab, or the correct ghunnah behavior.")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "رٞ",
                        pronunciation: "special dammatayn",
                        rule: "Version 1: apply the next-letter rule",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "لٖ",
                        pronunciation: "special kasratayn",
                        rule: "Version 1: apply the next-letter rule",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "رٗ",
                        pronunciation: "special fathatayn",
                        rule: "Version 1: apply the next-letter rule",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Version 2: normal idhaar")
                    .font(.subheadline.weight(.semibold))

                Text("When the normal double vowel mark is used before an idhaar letter, pronounce the hidden noon clearly. There is no merge, concealment, or conversion.")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "نٌ",
                        pronunciation: "normal dammatayn",
                        rule: "Version 2: clear idhaar",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "قٍ",
                        pronunciation: "normal kasratayn",
                        rule: "Version 2: clear idhaar",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "بًا",
                        pronunciation: "normal fathatayn",
                        rule: "Version 2: clear idhaar",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("A. PARALLEL TANWIN → IDHAAR") {
                Text("When the two tanwin strokes are parallel, the nun is pronounced clearly.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "بًا", english: "ban", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "بٌ", english: "bun", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "بٍ", english: "bin", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "قُرْءَانًا عَرَبِيًّا", english: "quraanan arabiyyan", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("You hear a full, clear \"n\" sound.")
                    .font(.body)
            }

            Section("B. STAGGERED / CONNECTED TANWIN") {
                Text("When tanwin marks appear staggered, connected, or visually altered, this usually indicates Idghaam, Ikhfaa, or Iqlaab.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "أُمَّةٞ قَدۡ",
                        pronunciation: "ummatun(g) qad (hidden noon with ghunnah)",
                        rule: "Special Dammatayn",
                        arabicFont: arabicFont
                    )

                    TajweedRuleRow(
                        arabic: "صِرَٰطٖ مُّسۡتَقِيمٖ",
                        pronunciation: "siraatim-mustaqeem",
                        rule: "Special Kasratayn",
                        arabicFont: arabicFont
                    )

                    TajweedRuleRow(
                        arabic: "أُمَّةٗ وَسَطٗا",
                        pronunciation: "ummataw-wasatan (idghaam with ghunnah)",
                        rule: "Special Fathatayn",
                        arabicFont: arabicFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("The mushaf is telling you: do not pronounce the nun normally here.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Important clarification: not every mushaf shows tanwin shapes identically, but the principle remains the same. If the tanwin does not look standard, slow down and apply a rule.")
                    .font(.body)
            }

            Section("3. THE LAAM OF \"AL-\" (ٱلـ)") {
                Text("The definite article \"al-\" also signals pronunciation through markings.")
                    .font(.body)
            }

            Section("A. SUKUN ON LAAM (QAMARIYYAH)") {
                VStack(alignment: .leading, spacing: 10) {
                    TajweedPairRow(arabic: "ٱلْقَمَر", english: "al-qamar", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْكِتَاب", english: "al-kitab", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْهُدَى", english: "al-huda", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("B. NO SUKUN ON LAAM (SHAMSIYYAH)") {
                Text("The laam merges into the next letter.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 10) {
                    TajweedPairRow(arabic: "ٱلشَّمْس", english: "ash-shams", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلنَّاس", english: "an-nas", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلرَّحْمَٰن", english: "ar-rahman", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If you do not see a sukun, the laam is not read.")
                    .font(.body)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Tajweed Hints in the Mushaf")
    }
}

private struct TajweedMakharijView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    private var arabicFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("VIDEO REFERENCES") {
                VStack(alignment: .leading, spacing: 6) {
                    if let url = URL(string: "https://www.youtube.com/watch?v=-YrfRpwFMe8&list=PL6TlMIZ5ylgpmlnN3EpkOec0tJ8OJZ5re") {
                        Link("Open Makhaarij Playlist", destination: url)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }
                }
            }

            Section("MAKHAARIJ") {
                Text("Makhaarij al-Huruf (Articulation of Letters)")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Makharij are the physical points of articulation from which Arabic letters are pronounced. Correct makharij are the foundation of tajweed. If the letter does not come from its proper place, no amount of rules will fix the sound.")
                    .font(.body)

                Text("This section focuses on awareness, not memorization. The goal is to know where a sound comes from and what moves to produce it.")
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

                Text("Use these diagrams as references, not something to stare at while reciting. Over time, correct makharij become muscle memory.")
                    .font(.body)
            }

            Section("RECOMMENDED PLAYLIST") {
                Text("Use a clear, slow pronunciation playlist such as Learn Arabic 101 (Makharij series). Focus on:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Isolated letter sounds")
                    Text("Minimal exaggeration")
                    Text("Clear mouth positioning")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Listen -> imitate -> repeat aloud. Silent learning does not work for makharij.")
                    .font(.body)

            }

            Section("PRIMARY AREAS OF ARTICULATION") {
                Text("For learning purposes, we group makharij into three main zones.")
                    .font(.body)
            }

            Section("1. THROAT LETTERS (الحروف الحلقية)") {
                Text("These letters originate from the throat, not the tongue.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ء هـ ع ح غ خ")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Sub-Zones (for awareness)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Deep throat: ء هـ")
                    Text("Middle throat: ع ح")
                    Text("Upper throat: غ خ")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Key Notes")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("These letters are clear and open")
                    Text("No nasalization")
                    Text("Do not squeeze the throat")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "أَحَد", english: "ahad", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نَعْبُدُ", english: "na'-bu-du", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "غَفُور", english: "ghafur", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "خَالِد", english: "khalid", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Common mistake: replacing ع with أ")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: clear throat engagement")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("2. TONGUE LETTERS (أغلب الحروف)") {
                Text("Most Arabic letters come from the tongue, but different parts of the tongue.")
                    .font(.body)

                Text("Tongue Zones (Simplified)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Back of tongue: ق ك")
                    Text("Middle of tongue: ج ش ي")
                    Text("Sides of tongue: ض")
                    Text("Tip of tongue: ت د ط ن ل ر س ز ص ث ذ ظ")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Key Notes")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Small shifts in tongue position matter")
                    Text("Do not force pressure")
                    Text("Accuracy > strength")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "قُلْ", english: "qul", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "سَمِيع", english: "samee'", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نُور", english: "nur", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "رَبِّ", english: "rabbi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Common mistake: collapsing multiple letters into one sound")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: distinct articulation for each letter")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("3. LIP LETTERS (الحروف الشفوية)") {
                Text("These letters are produced using the lips.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ب م ف")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("How They Work")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ب: full lip closure")
                    Text("م: lip closure + nasal sound")
                    Text("ف: upper teeth lightly touch lower lip")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "بَصِير", english: "basir", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "أَمْر", english: "amr", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "فِيهِ", english: "fihi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Common mistake: weak or lazy lip contact")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: gentle, controlled movement")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("IMPORTANT PRACTICE ADVICE") {
                Text("Makharij are learned by sound, not sight.")
                    .font(.body)

                Text("If you cannot hear the difference, slow down and exaggerate slightly during practice, then return to natural recitation.")
                    .font(.body)

                Text("Correct makharij preserve the Quran exactly as it was revealed.")
                    .font(.body)

                Text("Tajweed rules refine the sound. Makharij create it.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Makhaarij")
    }
}

private struct TajweedHeavyLightView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("HEAVY AND LIGHT") {
                Text("Heavy and Light Letters")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Arabic letters differ in weight (heavy tafkhim vs light tarqiq). Some letters are always heavy, some are always light, and some are conditional, meaning the weight changes based on context.")
                    .font(.body)

                Text("Correct letter weight is essential for accurate pronunciation and natural recitation.")
                    .font(.body)
            }

            Section("1. HEAVY LETTERS (تفخيم)") {
                Text("These letters are always heavy, regardless of the vowel.")
                    .font(.body)

                Text("Always Heavy Letters")
                    .font(.subheadline.weight(.semibold))

                Text("خ ص ض غ ط ق ظ")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("They are pronounced with:")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("The back of the tongue raised")
                    Text("A full, deep sound")
                    Text("No thinning, even with kasrah")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "قَالَ", english: "qala", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "صِرَاط", english: "sirat", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "طَبَعَ", english: "ta-ba-'a", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "غَفُور", english: "ghafur", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "خَالِد", english: "khalid", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("2. LIGHT LETTERS (ترقيق)") {
                Text("These letters are always light and never pronounced heavy.")
                    .font(.body)

                Text("Always Light Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ء ب ت ث ج ح د ذ ز س ش ف ك م ن هـ و ي")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("They are pronounced with:")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A relaxed tongue")
                    Text("No back-tongue elevation")
                    Text("Clear, sharp articulation")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "بِسْم", english: "bism", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نَعِيم", english: "na-'eem", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "سَبِيل", english: "sabil", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَوْم", english: "yawm", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "فِيهِ", english: "fihi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Note: Laam (ل) and waw (و) are light by default, but laam becomes conditional in one specific case: Allah.")
                    .font(.body)
            }

            Section("3. CONDITIONAL LETTERS") {
                Text("These letters change weight depending on vowels or surrounding letters.")
                    .font(.body)
            }

            Section("A. RAA (ر)") {
                Text("The weight of raa depends on the vowel on the raa itself.")
                    .font(.body)

                Text("Heavy Raa")
                    .font(.subheadline.weight(.semibold))

                Text("With fathah (ـَ) or dammah (ـُ)")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "رَبِّ", english: "rabbi", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "رُزِقُوا", english: "ruziqu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "قَرَأَ", english: "qaraa", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Light Raa")
                    .font(.subheadline.weight(.semibold))

                Text("Raa with kasrah (ـِ), or raa with sukoon preceded by an ORIGINAL kasrah, unless an isti'la letter with fatha/damma follows it in the same word (قِرْطَاس, مِرْصَاد), which makes it heavy again.")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "فِرْعَوْن", english: "firawn", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "رِجَال", english: "rijal", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "شِرْعَة", english: "shirah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Rule of thumb: if the raa carries a vowel, look at that vowel. If the raa is sakin, look at the letter BEFORE it, and at what follows, for the isti'la exception.")
                    .font(.body)
            }

            Section("B. LAAM (ل)") {
                Text("The letter laam is always light, except in the word Allah (ٱللَّه).")
                    .font(.body)

                Text("Heavy Laam (Only in \"Allah\")")
                    .font(.subheadline.weight(.semibold))

                Text("When preceded by fathah or dammah:")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱللَّهُ", english: "Allahu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "قَالَ ٱللَّهُ", english: "qala Allahu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نَصْرُ ٱللَّهِ", english: "nasru Allahi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Light Laam (After Kasrah)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "بِٱللَّهِ", english: "billahi", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "لِلَّهِ", english: "lillahi", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("C. ALIF (ا)") {
                Text("Alif itself has no sound; it inherits the weight of the letter before it.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("After a heavy letter -> alif sounds heavy")
                    Text("After a light letter -> alif sounds light")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedWhyRow(arabic: "قَالَ", english: "qala", why: "Heavy letter (ق)", arabicFont: arabicHeadlineFont)
                    TajweedWhyRow(arabic: "صَادِق", english: "sadiq", why: "Heavy letter (ص)", arabicFont: arabicHeadlineFont)
                    TajweedWhyRow(arabic: "كَانَ", english: "kana", why: "Light letter (ك)", arabicFont: arabicHeadlineFont)
                    TajweedWhyRow(arabic: "نَاس", english: "nas", why: "Light letter (ن)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Wrong: making alif heavy by itself")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: alif follows, never leads")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Heavy and Light")
    }
}

private struct TajweedShamsQamarView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("SHAMS AND QAMAR") {
                Text("Shamsiyyah and Qamariyyah Letters")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("The Definite Article \"Al-\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("When the definite article ٱلـ (al-) appears before a noun, the pronunciation of the laam (ل) depends on the first letter of the word that follows.")
                    .font(.body)

                Text("The mushaf clearly indicates this through shaddah or sukun.")
                    .font(.body)
            }

            Section("1. QAMARIYYAH (MOON LETTERS)") {
                Text("With qamariyyah letters, the laam is pronounced clearly.")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("The laam has a sukun (ٱلْ)")
                    Text("The sound is al-")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Qamariyyah Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ا ب ج ح خ ع غ ف ق ك م هـ و ي")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱلْقَمَر", english: "al-qamar", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْكِتَاب", english: "al-kitab", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْحَقّ", english: "al-haqq", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْغَفُور", english: "al-ghafur", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلْيَوْم", english: "al-yawm", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Incorrect: dropping the laam")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: pronouncing al-")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("2. SHAMSIYYAH (SUN LETTERS)") {
                Text("With shamsiyyah letters, the laam is not pronounced. Instead, it merges into the following letter, which is doubled (shown by a shaddah).")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("No sukun on the laam")
                    Text("The next letter has a shaddah")
                    Text("Pronounce the word as if it begins with the doubled letter")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Shamsiyyah Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ت ث د ذ ر ز س ش ص ض ط ظ ل ن")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱلشَّمْس", english: "ash-shams", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلنَّاس", english: "an-nas", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلرَّحْمَٰن", english: "ar-rahman", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلصِّرَاط", english: "as-sirat", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلتَّوْبَة", english: "at-tawbah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Incorrect: al-shams")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Correct: ash-shams")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("IMPORTANT NOTES") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This rule applies only to the definite article ٱلـ, not to every laam.")
                    Text("The shaddah is your visual cue: if you see it, the laam is not read.")
                    Text("This is idghaam of the laam, not deletion.")
                    Text("If you see a shaddah, the laam is gone.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Shams and Qamar")
    }
}
