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
        "Shams and Qamar - Al",
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

                Text("Now, in addition to teachers, there are online platforms, videos, and books that provide step-by-step lessons. For those starting out, focus on mastering the basic rules first and gradually build your skills over time. Practicing consistently is key - recording your recitation can help you catch mistakes and improve pronunciation.")
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
        } else if topic == "Shams and Qamar - Al" {
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
                    Text("Murattal - a steady, clear recitation ideal for learning")
                    Text("Mujawwad - a slower, melodic recitation that emphasizes precision and beauty")
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

            Section("2. MIM (م) - LIP CLOSURE") {
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
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    private var arabicFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
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
                        pronunciation: "ummatun(g) qad - hidden noon with ghunnah",
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
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    private var arabicFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
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
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
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

                Text("Raa with kasrah (ـِ), or raa with sukoon preceded by an ORIGINAL kasrah - unless an isti'la letter with fatha/damma follows it in the same word (قِرْطَاس, مِرْصَاد), which makes it heavy again.")
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "فِرْعَوْن", english: "firawn", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "رِجَال", english: "rijal", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "شِرْعَة", english: "shirah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Rule of thumb: if the raa carries a vowel, look at that vowel. If the raa is sakin, look at the letter BEFORE it - and at what follows, for the isti'la exception.")
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
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
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

private struct TajweedMaddView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("MADD") {
                Text("Madd (Elongation) Rules")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Madd means to lengthen a sound. In Quranic recitation, this lengthening is measured, consistent, and rule-based, not stylistic.")
                    .font(.body)

                Text("Madd is counted in harakat (counts).")
                    .font(.body)
            }

            Section("1. MADD TABII (NATURAL)") {
                Text("This is the default madd. If no special condition follows, this is what you apply.")
                    .font(.body)

                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Alif (ا) preceded by fathah")
                    Text("Waw (و) preceded by dammah")
                    Text("Yaa (ي) preceded by kasrah")
                    Text("No hamzah or sukun after")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2 counts")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "قَالَ", english: "qa-la", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَقُولُ", english: "ya-qu-lu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "فِيهِ", english: "fi-hi", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نُور", english: "nur", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If nothing special comes after, 2 counts, no more, no less.")
                    .font(.body)
            }

            Section("2. MADD WAJIB MUTTASIL") {
                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter")
                    Text("Followed by a hamzah")
                    Text("In the same word")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 4 or 5 counts (be consistent)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "جَاءَ", english: "jaaa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "السَّمَاءِ", english: "as-samaaa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "سُوءَ", english: "suuu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "شَيْءٌ", english: "shay (with extended yaa sound)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("It is called wajib because the lengthening is mandatory.")
                    .font(.body)
            }

            Section("3. MADD JAIZ MUNFASIL") {
                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter at the end of a word")
                    Text("Followed by a hamzah")
                    Text("In the next word")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2, 4, or 5 counts (be consistent)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Choose one and stay consistent.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "فِي أَنفُسِكُمْ", english: "fi an-fu-si-kum", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "قَالُوا إِنَّا", english: "qalu in-na", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "إِنَّا أَعْطَيْنَاكَ", english: "in-naa a'-tay-naa-ka", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If you lengthen it, always lengthen it. If you keep it short, always keep it short.")
                    .font(.body)
            }

            Section("3B. MADD MUNFASIL HUKMI (RULED SEPARATED)") {
                Text("A special, \u{201C}ruled\u{201D} (hukmi) form of Madd Munfasil. The madd letter and the hamzah are written inside one word, so it looks like Madd Muttasil - but it is recited as a separated madd.")
                    .font(.body)

                Text("Why It Is Separated")
                    .font(.subheadline.weight(.semibold))

                Text("The madd letter is actually the tail of a small joined particle - the vocative يَا (\u{201C}O \u{2026}\u{201D}) or the demonstrative هَا (\u{201C}here/these \u{2026}\u{201D}) - and the hamzah begins the word it is attached to. So in meaning it is two words, even though the script joins them.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("How To Spot It")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A superscript madd letter - dagger alif (\u{0670}), small waw (\u{06E5}), or small yaa (\u{06E6}) - carrying a maddah (\u{0653})")
                    Text("Immediately followed by a hamzah in the SAME written word")
                    Text("The carrier is the tail of a joined يَا or هَا particle")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2, 4, or 5 counts (treated exactly like Madd Munfasil - be consistent)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "يَٰٓأَيُّهَا", english: "ya + ayyuha (O you…)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "هَٰٓأَنتُمۡ", english: "ha + antum (here you are)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَٰٓإِبۡرَٰهِيمُ", english: "ya + Ibrahim (O Abraham)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَٰٓـَٔادَمُ", english: "ya + Adam (O Adam)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("One Word Can Hold Two Different Madds")
                    .font(.subheadline.weight(.semibold))

                Text("Do not assume every long madd in these words is hukmi. The word هَٰٓؤُلَآءِ contains BOTH:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("هَٰٓؤُ → Madd Munfasil Hukmi (the joined هَا particle)")
                    Text("لَآءِ → a true Madd Muttasil (a real alif + hamzah in one word)")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Only the superscript-particle sequence is munfasil hukmi. Every other madd in the word follows the normal rules.")
                    .font(.body)

                Text("The Complete Set In The Qur\u{2019}an")
                    .font(.subheadline.weight(.semibold))

                Text("هَٰٓأَنتُمۡ · هَٰٓؤُلَآءِ · أَهَٰٓؤُلَآءِ · وَهَٰٓؤُلَآءِ · يَٰٓـَٔادَمُ · وَيَٰٓـَٔادَمُ · يَٰٓأَبَانَا · يَٰٓأَبَتِ · يَٰٓإِبۡرَٰهِيمُ · يَٰٓإِبۡلِيسُ · يَٰٓأُخۡتَ · يَٰٓأَرۡضُ · يَٰٓأَسَفَىٰ · يَٰٓأَهۡلَ · يَٰٓأُوْلِي · يَٰٓأَيَّتُهَا · يَٰٓأَيُّهَ · يَٰٓأَيُّهَا")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)

                Text("(Counting orthographic variants such as يَٰٓأَبَانَآ and the pause-mark forms, this is 21 written words in the Hafs muṣḥaf.)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("3C. OTHER MADD TYPES & EXCEPTIONS") {
                Text("Several named madds and special cases sit alongside the main five. They matter for accurate recitation and for any rule engine.")
                    .font(.body)

                Text("Madd Badal - hamzah BEFORE the madd")
                    .font(.subheadline.weight(.semibold))
                Text("A hamzah followed by a madd letter (the reverse of muttasil). Read 2 counts; it is not lengthened like muttasil.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ءَامَنُوا", english: "aa-manu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ءَادَمَ", english: "aa-dama", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Madd \u{02BF}Iwad - tanwin fath at a stop")
                    .font(.subheadline.weight(.semibold))
                Text("When you stop on a word ending in tanwin fath (\u{064B}), the tanwin drops and the alif is stretched 2 counts. It is not aarid lis-sukoon.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "عَلِيمًا", english: "stop: a-li-maa", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "غَفُورًا", english: "stop: gha-fu-raa", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Madd Tamkin - doubled yaa")
                    .font(.subheadline.weight(.semibold))
                Text("A kasrah + shaddah yaa meeting a madd yaa. Read 2 counts, taking care not to swallow either yaa.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱلنَّبِيِّـۧنَ", english: "an-nabiy-yiin", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "حُيِّيتُم", english: "huy-yi-tum", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Madd Silah - the pronoun haa")
                    .font(.subheadline.weight(.semibold))
                Text("The attached pronoun \u{0647} (\u{201C}his/its\u{201D}) between two voweled letters is given a hidden waw/yaa. Sughra (small) is 2 counts; Kubra (large) is 4\u{2013}5 counts when a hamzah follows - it then behaves like Madd Munfasil.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "إِنَّهُۥ كَانَ", english: "sughra: in-na-hu", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "بِهِۦٓ أَحَدَۢا", english: "kubra: bi-hii (before hamzah)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Dagger Alif & Tiny Madd Marks")
                    .font(.subheadline.weight(.semibold))
                Text("Superscript madd marks - dagger alif (\u{0670}), small waw (\u{06E5}), small yaa (\u{06E6}) - are still a 2-count natural madd even though they are written tiny. When such a mark also carries a maddah (\u{0653}) and a hamzah follows, it becomes the munfasil-hukmi case above.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Genuine Muttasil Written With A Dagger Alif")
                    .font(.subheadline.weight(.semibold))
                Text("Not every dagger alif + hamzah is hukmi. When both sit inside one true word (no joined يَا/هَا particle), it is ordinary Madd Muttasil - for example أُوْلَٰٓئِكَ, مَلَٰٓئِكَة, and إِسۡرَٰٓءِيل.")
                    .font(.body)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "أُوْلَٰٓئِكَ", english: "muttasil: ula-aa-ika", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "مَلَٰٓئِكَةِ", english: "muttasil: mala-aa-ikah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("4. ENDING MADD") {
                Text("Ending madd applies when you stop on a word and the ending sound changes because of waqf.")
                    .font(.body)

                Text("It includes Madd Aarid lis-Sukoon and Madd Leen.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Madd Leen")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A sakin yaa or sakin waaw")
                    Text("Preceded by fathah")
                    Text("You stop on the word")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 12) {
                    Text("خَوۡف")
                    Text("بَيۡت")
                    Text("قُرَيۡش")
                }
                .font(arabicHeadlineFont)
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Madd Aarid lis-Sukoon")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "ٱلۡعَٰلَمِينَ", english: "stop: temporary sukoon", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "ٱلرَّحِيمِ", english: "stop: ٱلرَّحِيمۡ", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "نَسۡتَعِينُ", english: "stop: temporary sukoon", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 2, 4, or 6 counts. Madd Leen should follow the stopping style you choose for Madd Aarid lis-Sukoon, and should not be longer than it.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("5. MADD LAZIM") {
                Text("This is the strongest and longest madd.")
                    .font(.body)

                Text("When It Occurs")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("A madd letter")
                    Text("Followed by a permanent sukun")
                    Text("Either in a word or a letter name")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Length: 6 counts (always)")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("A. MADD LAZIM HARFI") {
                Text("Occurs in the disconnected letters at the start of some surahs.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "الم", english: "Alif (no madd) Laaaaaam (6) Miiiiiim (6)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "كهيعص", english: "Kaaaaaaf (6) Haa (2) Yaa (2) 'Ayyyn (4-6) Saaaaaad (6)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "حم", english: "Haa (2) Miiiiiim (6)", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("If the letter name itself contains a madd followed by sukun, it is 6 counts.")
                    .font(.body)
            }

            Section("B. MADD LAZIM KALIMI") {
                Text("Less common, but very important.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "الضَّالِّينَ", english: "ad-daaallin", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "الطَّامَّة", english: "at-taaammah", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("OPENING LETTERS (MUQATTA’AT)") {
                Text("Some opening letters do not contain madd.")
                    .font(.body)

                Text("Read Normally (No Madd)")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ألف (alone) - no madd")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Have Madd")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("6 counts - نقص عسلكم")
                    Text("2 counts - حي طهر")
                    Text("'Ayn (ع) is a leen letter: 4 or 6 counts.")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("ن ق ص ع س ل ك م")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("ح ي ط ه ر")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Not every opening letter is lengthened. Read the letter name.")
                    .font(.body)
            }

            Section("KEY TEACHING RULES") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Madd is measured, not emotional. Do not stretch because it sounds nice.")
                    Text("Consistency matters more than length. 4 everywhere is better than random 2-6.")
                    Text("Never add a jump or break mid-madd. One smooth airflow from start to finish.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Madd")
    }
}

private struct TajweedQalqalahView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("QALQALAH") {
                Text("Qalqalah (Echo) Letters")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Qalqalah is a natural bouncing sound that occurs when certain letters are in a sukun state. It is not a vowel and not silence.")
                    .font(.body)

                Text("Its purpose is to prevent the sound from becoming cut off or broken.")
                    .font(.body)
            }

            Section("THE FIVE LETTERS") {
                Text("The qalqalah letters are:")
                    .font(.body)

                Text("ق ط ب ج د")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Section("WHAT QALQALAH IS (AND IS NOT)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A slight echo")
                    Text("Natural and effortless")
                    Text("Not a fathah")
                    Text("Not an added vowel")
                    Text("Not exaggerated")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Think of it as releasing the letter, not opening the mouth.")
                    .font(.body)
            }

            Section("WHEN QALQALAH OCCURS") {
                Text("Qalqalah occurs when one of the five letters:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Has a sukun, or")
                    Text("Is stopped on (waqf)")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedPairRow(arabic: "أَحَدْ", english: "aha(d)", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَجْعَل", english: "ya(j)-'al", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "أَجْر", english: "a(j)r", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَقْطَع", english: "ya(q)ta'", arabicFont: arabicHeadlineFont)
                    TajweedPairRow(arabic: "يَبْتَغُون", english: "ya(b)taghun", arabicFont: arabicHeadlineFont)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Notice: the sound is heard, but no vowel is added.")
                    .font(.body)
            }

            Section("WHY QALQALAH EXISTS") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Without qalqalah, the letter would sound cut off.")
                    Text("Without qalqalah, words would sound unnatural or unclear.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Qalqalah preserves:")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Clarity")
                    Text("Letter identity")
                    Text("Flow of speech")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Qalqalah exists because Arabic does not allow these letters to die silently.")
                    .font(.body)
            }

            Section("IMPORTANT REMINDER") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Qalqalah is a sound, not a vowel.")
                    Text("If it sounds like \"a\", it is wrong.")
                    Text("If it disappears, it is also wrong.")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Qalqalah")
    }
}

private struct TajweedIdghamIkhfaView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("NOON SAKINAH AND TANWEEN") {
                Text("Noon Sakinah and Tanween Rules")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Tanween and noon saakinah are closely related, so this section groups the merge and hidden-sound rules together.")
                    .font(.body)
            }

            Section("TANWEEN PRONUNCIATION") {
                Text("Although tanween appears as vowel marks, it is pronounced as a hidden noon sound (نْ) at the end of the word.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "بًا",
                        pronunciation: "بَنْ (ban)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "بٌ",
                        pronunciation: "بُنْ (bun)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "بٍ",
                        pronunciation: "بِنْ (bin)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("What happens to this hidden sound depends entirely on the letter that follows.")
                    .font(.body)
            }

            Section("MUSHAF TANWEEN HINTS") {
                Text("The Mushaf often hints whether tanween is normal idhaar or whether a special noon sakinah rule is coming.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "رٞ  لٖ  رٗ",
                        pronunciation: "special tanween marks",
                        rule: "Apply ikhfaa, idghaam, iqlaab, or ghunnah by the next letter",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "نٌ  قٍ  بً",
                        pronunciation: "normal tanween marks",
                        rule: "Usually clear idhaar when followed by idhaar letters",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("1. IDHAAR (CLEAR)") {
                Text("The noon sound is pronounced clearly and fully, with no ghunnah merge.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ء ه ع ح غ خ")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedPairRow(arabic: "مِنْ هَادٍ", english: "min hadin", arabicFont: arabicHeadlineFont)

                Text("The throat letters prevent merging, so the sound must remain clear.")
                    .font(.body)
            }

            Section("2. IDGHAAM (MERGING)") {
                Text("The noon sound merges into the following letter.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ي ر م ل و ن")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("With Ghunnah")
                    .font(.subheadline.weight(.semibold))

                Text("ي ن م و")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Without Ghunnah")
                    .font(.subheadline.weight(.semibold))

                Text("ل ر")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Examples")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "مَن يَقُول",
                        pronunciation: "may-yaqul",
                        rule: "Idghaam with ghunnah",
                        arabicFont: arabicHeadlineFont
                    )

                    TajweedRuleRow(
                        arabic: "مِن رَبِّهِم",
                        pronunciation: "mir-rabbihim",
                        rule: "Idghaam without ghunnah",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("With ghunnah: nasal sound. Without ghunnah: clean merge, no nasalization.")
                    .font(.body)
            }

            Section("3. IQLAAB (CONVERSION)") {
                Text("The noon sound changes into a miim with ghunnah.")
                    .font(.body)

                Text("Letter")
                    .font(.subheadline.weight(.semibold))

                Text("ب")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedRuleRow(
                    arabic: "سَمِيعٌۢ بَصِير",
                    pronunciation: "samium-basir",
                    rule: "",
                    arabicFont: arabicHeadlineFont
                )

                Text("The noon is not pronounced. It becomes a hidden miim.")
                    .font(.body)
            }

            Section("4. IKHFAA (HIDDEN)") {
                Text("The noon is hidden, pronounced with ghunnah, without full clarity or full merging.")
                    .font(.body)

                Text("Letters")
                    .font(.subheadline.weight(.semibold))

                Text("ت ث ج د ذ ز س ش ص ض ط ظ ف ق ك - the remaining 15 letters (all except the idhaar, idghaam, and iqlaab letters)")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                TajweedRuleRow(
                    arabic: "مِن شَرِّ",
                    pronunciation: "min-sharri (nasal)",
                    rule: "",
                    arabicFont: arabicHeadlineFont
                )

                Text("The tongue does not fully touch the articulation point.")
                    .font(.body)
            }

            Section("GHUNNAH STRENGTH") {
                Text("Not all ghunnah is the same strength.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Strongest")
                        .font(.subheadline.weight(.semibold))
                    Text("Noon or Miim with shaddah (نّ / مّ)")
                        .foregroundColor(.secondary)

                    Text("Medium")
                        .font(.subheadline.weight(.semibold))
                    Text("Idghaam with ghunnah, then Ikhfaa")
                        .foregroundColor(.secondary)

                    Text("None")
                        .font(.subheadline.weight(.semibold))
                    Text("Idghaam without ghunnah")
                        .foregroundColor(.secondary)
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("KEY TEACHING LINE") {
                Text("Tanween is not a vowel. It is a hidden noon sound in disguise. The rule is determined by the next letter, not the vowel mark.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Noon Sakinah and Tanween")
    }
}

private struct TajweedMeemSakinahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
            Section("VIDEO REFERENCES") {
                Link("Meem Sakinah Rules", destination: URL(string: "https://www.youtube.com/watch?v=MAvDrZgWRTs")!)
            }

            Section("MEEM SAKINAH") {
                Text("Meem Sakinah means a meem with sukoon: مْ. In tajweed, Meem Sakinah has three rules, and all three are called Shafawi because they are pronounced from the lips. The word Shafawi comes from shafah, meaning \"lip.\"")
                    .font(.body)

                Text("The three rules are:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ikhfaa Shafawi")
                    Text("Idgham Shafawi")
                    Text("Idhaar Shafawi")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("These rules depend on the letter that comes after the Meem Sakinah.")
                    .font(.body)
            }

            Section("1. IKHFAA SHAFAWI") {
                Text("Ikhfaa Shafawi occurs when Meem Sakinah (مْ) is followed by the letter Ba (ب).")
                    .font(.body)

                Text("When this happens, the meem is hidden lightly while keeping ghunnah for two counts. The lips come close together, but the meem is not pronounced with full clarity like normal Idhaar.")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                Text("مْ + ب = Ikhfaa Shafawi")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                Text("أَم بِهِۦ جِنَّةٌۢ")
                    .font(.custom(settings.fontArabic, size: 24))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("In this example, the Meem Sakinah in أَم is followed by ب in بِهِۦ, so it is read with Ikhfaa Shafawi.")
                    .font(.body)

                Text("How to read it: am bihi, with ghunnah for two counts.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("2. IDGHAM SHAFAWI") {
                Text("Idgham Shafawi occurs when Meem Sakinah (مْ) is followed by another Meem (م).")
                    .font(.body)

                Text("When this happens, the first meem merges into the second meem, and the result is read as a doubled meem with ghunnah for two counts.")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                Text("مْ + م = Idgham Shafawi")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                Text("وَلَهُم مَّا يَشْتَهُونَ")
                    .font(.custom(settings.fontArabic, size: 24))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("In this example, the Meem Sakinah at the end of لَهُم is followed by another meem in مَّا, so the two meems merge.")
                    .font(.body)

                Text("How to read it: lahum maa, with ghunnah for two counts.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("3. IDHAAR SHAFAWI") {
                Text("Idhaar Shafawi occurs when Meem Sakinah (مْ) is followed by any letter other than Ba (ب) or Meem (م).")
                    .font(.body)

                Text("When this happens, the meem is pronounced clearly with no extra ghunnah beyond its normal sound.")
                    .font(.body)

                Text("Rule")
                    .font(.subheadline.weight(.semibold))

                Text("مْ + any letter except ب or م = Idhaar Shafawi")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("Example")
                    .font(.subheadline.weight(.semibold))

                Text("وَمَا بَلَغُوا۟ مِعْشَارَ مَآ ءَاتَيْنَٰهُمْ فَكَذَّبُوا۟ رُسُلِى")
                    .font(.custom(settings.fontArabic, size: 24))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("In this example, the Meem Sakinah in ءَاتَيْنَٰهُمْ is followed by ف, so it is read with Idhaar Shafawi.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("لَكُمْ فِيهَا")
                    Text("عَلَيْكُمْ سَلَامٌ")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("MEEM MUSHADDADAH") {
                Text("A related rule is Meem Mushaddadah, which is a meem with shaddah: مّ.")
                    .font(.body)

                Text("Whenever you see مّ, it must be pronounced with a strong ghunnah for two counts.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ثُمَّ")
                    Text("لَمَّا")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This is not one of the three Meem Sakinah rules, but it is closely related because it also involves ghunnah on meem.")
                    .font(.body)
            }

            Section("QUICK SUMMARY") {
                Text("Meem Sakinah = مْ")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Ikhfaa Shafawi: مْ + ب, hide the meem with ghunnah. Example: أَم بِهِۦ")
                    Text("2. Idgham Shafawi: مْ + م, merge the two meems with ghunnah. Example: لَهُم مَّا")
                    Text("3. Idhaar Shafawi: مْ + any letter except ب or م, pronounce the meem clearly. Example: لَكُمْ فِيهَا")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }

            Section("SHORT SUMMARY") {
                Text("Meem Sakinah has three rules. If it is followed by Ba, it is read with Ikhfaa Shafawi, meaning the meem is hidden with ghunnah. If it is followed by another Meem, it is read with Idgham Shafawi, meaning the two meems merge with ghunnah. If it is followed by any other letter, it is read with Idhaar Shafawi, meaning the meem is pronounced clearly.")
                    .font(.body)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Meem Sakinah")
    }
}

private struct TajweedAaridLisSukoonView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
            Section("VIDEO REFERENCES") {
                Link("Tajweed Hints: 4 Types of Sukoon", destination: URL(string: "https://www.youtube.com/watch?v=MAvDrZgWRTs")!)
            }

            Section("The 4 Types of Sukoon Marks in the Qur’an") {
                Text("In the Uthmani script of the Qur’an, letters may carry different kinds of sukoon-style markings. These marks tell the reciter whether a letter is pronounced, skipped, pronounced only when stopping, or affected by a special tajweed rule.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("1. Normal Sukoon: Pronounce the Letter Without a Vowel") {
                Text("This is the common Qur’anic sukoon mark written like ـۡ above a consonant. It means the letter has no vowel, but the letter itself is still pronounced clearly.")
                    .font(.body)

                Text("Example:")
                    .font(.subheadline.weight(.semibold))

                Text("رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ")
                    .font(.custom(settings.fontArabic, size: 24))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Simple rule: Pronounce the letter, but do not add a vowel after it.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("2. Permanent Silent Letter: Always Skip It") {
                Text("This mark shows that the letter is written in the Qur’an’s script but is not pronounced. You skip it whether you continue reciting or stop.")
                    .font(.body)

                Text("Example:")
                    .font(.subheadline.weight(.semibold))

                Text("بِأَيۡيْدٖ")
                    .font(.custom(settings.fontArabic, size: 22))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Simple rule: The letter is written, but never pronounced.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("3. Stop-Only Letter: Pronounce It Only If You Stop") {
                Text("This mark means the letter is ignored when continuing, but pronounced if you stop on the word.")
                    .font(.body)

                Text("Examples:")
                    .font(.subheadline.weight(.semibold))

                Text("قَوَارِيرَا۠ - stop: قَوَارِيرَا")
                    .font(.body)

                Text("أَنَا۠ - in context: قُلۡ إِنَّمَآ أَنَا۠ بَشَرٞ مِّثۡلُكُمۡ")
                    .font(.body)

                Text("Simple rule: Pronounce it when stopping, skip it when continuing.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("4. No Sukoon Mark: Madd Letter or Special Tajweed Rule") {
                Text("Sometimes a letter has no sukoon mark and no vowel mark. This usually means one of two things: either it is a madd letter (stretched for two counts), or a consonant affected by a special tajweed rule.")
                    .font(.body)

                Text("Examples:")
                    .font(.subheadline.weight(.semibold))

                Text("يُقِيمُونَ - madd letter example")
                    .font(.body)

                Text("يُنفِقُونَ - special tajweed (ikhfāʾ) example")
                    .font(.body)

                Text("Simple rule: No mark usually means either natural madd or a special recitation rule is happening.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("Note about the example رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ: there is a qalqalah effect in the consonant, but there is no special visual marking for qalqalah in the Uthmani script - you must know it by rule or consult the tajweed colors in the app to see it highlighted.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Super Simple Summary") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1. ـۡ Normal sukoon - Pronounce the consonant with no vowel. Example: رَزَقۡنَٰهُمۡ بِٱلۡغَيۡبِ")
                    Text("2. Silent written letter - Skip it always. Example: كَانُواْ")
                    Text("3. Stop-only letter - Pronounce it only when stopping. Example: أَنَا۠ / قَوَارِيرَا۠")
                    Text("4. No mark - Either a madd letter or a special tajweed rule. Example: يُقِيمُونَ / يُنفِقُونَ")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("4 Sukoon")
    }
}

private struct TajweedHamzatulWaslView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
            Section("VIDEO REFERENCES") {
                VStack(alignment: .leading, spacing: 6) {
                    Link("Hamzatul-Wasl short 1", destination: URL(string: "https://www.youtube.com/shorts/SpA7EtX3jMA")!)
                    Link("Hamzatul-Wasl short 2", destination: URL(string: "https://www.youtube.com/shorts/xNn-pR4eoHM")!)
                    Link("Hamzatul-Wasl short 3", destination: URL(string: "https://www.youtube.com/shorts/79Ku0wSKf9Q")!)
                }
            }

            Section("Hamzatul-Wasl: The Connecting Hamzah") {
                Text("Hamzatul-Wasl means “the hamzah of connection.” It is only pronounced when beginning recitation from that word; if you connect from the previous word, the Hamzatul-Wasl is dropped and not pronounced.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("In the Uthmani Qur’an script, Hamzatul-Wasl is usually written as an alif with a small ṣād-like sign above it: ٱ")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Common examples:")
                    .font(.subheadline.weight(.semibold))

                VStack(spacing: 6) {
                    Text("ٱبۡنُوا")
                    Text("ٱمۡشُوا")
                    Text("ٱقۡضُوا")
                    Text("ٱئۡتُوا")
                    Text("ٱئۡتُونِي")
                }
                .font(.custom(settings.fontArabic, size: 22))
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .center)

                Text("Key rule: If you start from the word, pronounce Hamzatul-Wasl. If you connect from the previous word, drop it.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("1. Hamzatul-Wasl Is Dropped When Connecting") {
                Text("When reciting continuously, Hamzatul-Wasl is not pronounced. The previous word connects directly into the next word.")
                    .font(.body)

                Text("Example:")
                    .font(.subheadline.weight(.semibold))

                Text("ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِ")
                    .font(.custom(settings.fontArabic, size: 20))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("When continuing: dhālika l-kitāb (you do not say al- as a separate hamzah). If you stop and then begin from the word, pronounce the Hamzatul-Wasl: al-kitāb.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("2. Hamzatul-Wasl With “Al” Takes Fatḥah") {
                Text("When a word begins with the definite article ٱل, Hamzatul-Wasl is pronounced with fatḥah if you begin from that word (al-kitāb → al-kitāb; al-rahmān → ar-raḥmān).")
                    .font(.body)

                VStack(spacing:6) {
                    Text("ٱلۡكِتَٰبُ → al-kitāb")
                    Text("ٱلرَّحۡمَٰنُ → ar-raḥmān")
                    Text("ٱلصَّمَدُ → aṣ-ṣamad")
                    Text("ٱللَّهُ → Allāh")
                }
                .font(.custom(settings.fontArabic, size: 20))
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .center)

                Text("Note: alif itself is treated as a vowel/madd letter; the opening sound of ٱل is the Hamzatul-Wasl, realized as an initial “a”.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("3. Hamzatul-Wasl in Nouns Usually Takes Kasrah") {
                Text("In nouns that begin with Hamzatul-Wasl and do not begin with ٱل, the Hamzatul-Wasl is pronounced with kasrah when starting (e.g. ٱسۡمُهُۥ → ismuhu).")
                    .font(.body)

                VStack(spacing:6) {
                    Text("ٱسۡم → ism")
                    Text("ٱبۡن → ibn")
                    Text("ٱبۡنَيۡ → ibnay")
                }
                .font(.custom(settings.fontArabic, size: 20))
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Section("4. Hamzatul-Wasl in Verbs Depends on the Third Letter") {
                Text("For verbs, examine the third letter: if it has ḍammah, begin with “u”; if it has fatḥah or kasrah, begin with “i”. Exception: when that ḍammah is incidental (ʿāriḍah), begin with kasrah instead - ٱمْشُوا، ٱقْضُوا، ٱبْنُوا، ٱمْضُوا، ٱئْتُوا are read imshu, iqdu, ibnu, imdu, i’tu, not umshu / uqdu / ubnu.")
                    .font(.body)

                Text("Example (third letter ḍammah → start with 'u'):")
                    .font(.subheadline.weight(.semibold))

                Text("ٱتۡلُ → utlu (when starting); when connected: watlu")
                    .font(.custom(settings.fontArabic, size: 20))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Simple rule: Third letter ḍammah → start with 'u'; otherwise start with 'i'.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("5. Special Verb Exceptions") {
                Text("Some verbs are special cases (e.g. ٱئۡتُوا / ٱئۡتُونِي) and are learned individually; they may behave differently than the third-letter rule.")
                    .font(.body)

                Text("Example: ٱئۡتُونِي → iʾtūnī when starting.")
                    .font(.custom(settings.fontArabic, size: 20))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Section("6. Hamzatul-Wasl After Tanwīn: Add a Connecting Nūn") {
                Text("When a word ending in tanwīn is followed by a word beginning with Hamzatul-Wasl, a connecting 'nِ' (kasrah nūn) is commonly inserted when continuing (e.g. بِغُلَٰمٍ ٱسۡمُهُۥ → bighulāmin ismuhu).")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Example:")
                    .font(.subheadline.weight(.semibold))

                Text("بِغُلَٰمٍ ٱسۡمُهُۥ → بِغُلَٰمِنِ سۡمُهُۥ")
                    .font(.custom(settings.fontArabic, size: 20))
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Section("Summary: How to Start Hamzatul-Wasl") {
                Text("1. If the word begins with ٱل → start with 'a' (fatḥah). 2. If a noun without ٱل → start with 'i' (kasrah). 3. If a verb → check the third letter (ḍammah→'u', otherwise 'i'). 4. Some words are exceptions and must be learned individually.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("What Happens When Continuing") {
                Text("Hamzatul-Wasl is dropped when continuing from the previous word (e.g. ذَٰلِكَ ٱلۡكِتَٰبُ → dhālika l-kitāb; وَٱتۡلُ → watlu).")
                    .font(.body)
            }

            Section("SHORT SUMMARY") {
                Text("Hamzatul-Wasl is the connecting hamzah - pronounced only when starting from the word. Nouns usually take 'i', words with ٱل start with 'a', verbs depend on the third letter, and tanwīn before Hamzatul-Wasl connects with an 'nِ' sound.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Hamzatul-Wasl")
    }
}

private struct TajweedWaqfView: View {
    @ObservedObject var settings = Settings.shared

    private var arabicHeadlineFont: Font {
        .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }

    var body: some View {
        List {
            Group {
            Section("WAQF") {
                Text("Waqf (Stopping in the Quran)")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("What Is Waqf?")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)

                Text("Waqf (وَقْف) means to stop or pause while reciting the Quran, with the intention of resuming the recitation correctly afterward.")
                    .font(.body)

                Text("The word comes from the Arabic root و ق ف, meaning to stop, stand, or halt. In tajweed, it refers specifically to stopping at the end of a word while preserving the meaning, pronunciation, and beauty of the Quran.")
                    .font(.body)

                Text("Waqf is not random breathing. It is a deliberate, rule-based pause guided by the Mushaf and the meaning of the ayah.")
                    .font(.body)
            }

            Section("WHY WAQF MATTERS") {
                Text("Stopping incorrectly can:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Change the meaning of an ayah")
                    Text("Create theological errors")
                    Text("Break the grammatical structure")
                    Text("Distort the listener's understanding")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Correct waqf:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Preserves meaning")
                    Text("Maintains clarity")
                    Text("Reflects proper understanding")
                    Text("Shows respect for the words of Allah")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Ali ibn Abi Talib (may Allah be pleased with him) defined tartil as: \"the tajweed of the letters and knowledge of the places of stopping.\"")
                    .font(.body)
            }

            Section("WAQF IN THE MUSHAF") {
                Text("Even without colors, the Mushaf signals where to stop or continue using:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Special symbols")
                    Text("Word endings")
                    Text("Sentence structure")
                    Text("Completion of meaning")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("A reader trained in waqf reads with understanding, not just sound.")
                    .font(.body)
            }

            Section("LAST LETTER WHEN YOU STOP") {
                Text("When stopping, the ending of the word almost always changes.")
                    .font(.body)

                Text("The Golden Rule of Waqf")
                    .font(.subheadline.weight(.semibold))

                Text("Every vowel at the end of a word becomes a sukun when stopping, except special cases.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("1. FINAL DAMMAH, FATHAH, OR KASRAH") {
                Text("When stopping, the vowel is dropped, and the letter becomes saakin.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "الْعَالَمِينَ -> الْعَالَمِينْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "نَسْتَعِينُ -> نَسْتَعِينْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "الْكِتَابِ -> الْكِتَابْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("The sound is cut cleanly, without adding extra vowels.")
                    .font(.body)
            }

            Section("2. STOPPING ON TANWEEN") {
                Text("Tanween is never pronounced when stopping.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "بَصِيرٌ -> بَصِيرْ",
                        pronunciation: "Dammatayn",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "عَلِيمٍ -> عَلِيمْ",
                        pronunciation: "Kasratayn",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "رَحْمَةً -> رَحْمَةْ",
                        pronunciation: "Fathatayn (no alif)",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "كِتَابًا -> كِتَابَا",
                        pronunciation: "Fathatayn + alif",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Important: the tanween itself is dropped completely when stopping. There is no nuun sound and no vowel.")
                    .font(.body)

                Text("Exception: when fathatayn is followed by an alif (ا), the tanween is dropped but the alif is still pronounced, producing a long a sound.")
                    .font(.body)

                Text("This is because the alif is a written long vowel, not part of the tanween itself.")
                    .font(.body)

                Text("Rule to remember: fathatayn disappears when stopping, but a written alif remains pronounced.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("3. TAA MARBUTAH (ة)") {
                Text("When stopping, taa marbutah is pronounced as haa saakinah (ـهْ).")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "رَحْمَةٌ -> رَحْمَهْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "جَنَّةٍ -> جَنَّهْ",
                        pronunciation: "Connected -> Stopping",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("This rule is consistent everywhere in the Quran.")
                    .font(.body)
            }

            Section("4. LONG VOWELS (ا، و، ي)") {
                Text("Long vowels remain unchanged when stopping.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    TajweedRuleRow(
                        arabic: "هُدَى -> هُدَى",
                        pronunciation: "Unchanged",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "يَقُولُ -> يَقُولْ",
                        pronunciation: "Final vowel drops, long sound remains",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                    TajweedRuleRow(
                        arabic: "فِي -> فِي",
                        pronunciation: "Unchanged",
                        rule: "",
                        arabicFont: arabicHeadlineFont
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("No shortening occurs.")
                    .font(.body)
            }

            Section("WAQF TAM (COMPLETE)") {
                Text("The meaning is complete and independent.")
                    .font(.body)
                Text("Best place to stop.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF KAFI (SUFFICIENT)") {
                Text("The meaning is complete, but connected to what follows.")
                    .font(.body)
                Text("Permissible to stop.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF HASAN (GOOD)") {
                Text("The wording makes sense, but the meaning is incomplete.")
                    .font(.body)
                Text("Allowed only for breath, not preferred.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("WAQF QABIH (BAD)") {
                Text("Stopping breaks the meaning or creates error.")
                    .font(.body)
                Text("Not allowed.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            Section("DANGEROUS STOP EXAMPLE") {
                Text("Example of a dangerous stop:")
                    .font(.subheadline.weight(.semibold))

                Text("لَا تَقْرَبُوا الصَّلَاةَ")
                    .font(arabicHeadlineFont)
                    .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("Stopping here implies \"Do not approach prayer,\" which is incorrect.")
                    .font(.body)

                Text("The ayah continues: وَأَنتُمْ سُكَارَى")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Section("WAQF SYMBOLS") {
                QuranSignsSectionContent(accentColor: settings.accentColor.color)

                Text("These symbols guide meaning, not breathing convenience.")
                    .font(.body)
            }

            Section("REMEMBER") {
                Text("Waqf is not about breath. It is about meaning.")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)

                Text("You stop where the meaning stops, not where the lungs give up.")
                    .font(.body)
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Waqf")
    }
}

private struct TajweedExampleRow: View {
    let arabic: String
    let middle: String
    let trailing: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: Settings.shared.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(middle)
                .font(.subheadline)
            Text(trailing)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct TajweedPairRow: View {
    let arabic: String
    let english: String
    let arabicFont: Font

    var body: some View {
        HStack {
            Text(english)
                .font(.subheadline)

            Spacer()

            Text(arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: Settings.shared.quranUsesCustomArabicFace)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

private struct TajweedRuleRow: View {
    let arabic: String
    let pronunciation: String
    let rule: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: Settings.shared.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(pronunciation)
                .font(.subheadline)
            Text(rule)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct TajweedWhyRow: View {
    let arabic: String
    let english: String
    let why: String
    let arabicFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: Settings.shared.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(english)
                .font(.subheadline)
            Text(why)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct TajweedTopicPlaceholderView: View {
    @ObservedObject var settings = Settings.shared

    let title: String

    var body: some View {
        List { }
            .applyConditionalListStyle()
            .navigationTitle(title)
    }
}

#Preview {
    AlIslamPreviewContainer {
        TajweedFoundationsView()
    }
}
