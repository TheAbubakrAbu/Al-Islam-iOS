import SwiftUI

/// Tawhid: the Oneness of Allah. The first subject of the religion, the message of every prophet,
/// and the meaning of the testimony. Placed at the head of the Salafiyyah section because everything
/// after it (shirk, kufr, bid'ah) is measured against it.
struct TawhidView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: tawheed is to single Allah out in everything that belongs to Him alone: in His lordship, in His worship, and in His names and attributes. It is why the messengers were sent and the meaning of “there is no deity except Allah.” Its opposite, shirk, is the one sin Allah has said He will never forgive for the one who dies upon it.")
                }

                Section(header: ArticleHeader("WHAT IS TAWHEED?")) {
                    ArticleParagraph(articleMarkdown: "**Tawheed (تَوحِيد)** is the verbal noun of **wahhada**, from the root **و-ح-د**, “to make one” or “to single out.” It does not mean believing that Allah exists, nor merely that He is one in number. It means to single Him out in everything that is His right alone, and to give none of it to anyone else.")

                    ArticleParagraph(verbatim: "The word is the Prophet’s own. When he sent Mu‘aadh ibn Jabal (may Allah be pleased with him) to Yemen, he named tawheed as the first thing to be called to, before prayer and before zakaah:")
                    ScriptureQuote(hadith: "bukhari:7372", cite: "Saheeh al-Bukhaari 7372", arabic: 49...102, english: 12...62)

                    ArticleParagraph(verbatim: "So tawheed is not one topic among many. It is the foundation that everything else is built on, and it is the first thing a person is asked about and the first thing he is taught.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHY THE MESSENGERS CAME")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) states the purpose of creation itself in one verse:")
                        ScriptureQuote(quran: "51:56")

                        ArticleParagraph(verbatim: "And He states that every messenger, without exception, came with this one message:")
                        ScriptureQuote(quran: "16:36", words: 0...10)
                        ScriptureQuote(quran: "21:25")

                        ArticleParagraph(verbatim: "Allah said it to Moosa (peace be upon him) at the first moment of his prophethood:")
                        ScriptureQuote(quran: "20:14")

                        ArticleParagraph(verbatim: "Every prophet from Nooh to Muhammad (peace be upon them all) opened with the same sentence, and every nation that rejected them rejected it. The messengers differed in law; they never differed in tawheed.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHY THE MESSENGERS CAME")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) states the purpose of creation itself in one verse:")
                        ScriptureQuote(quran: "51:56")

                        ArticleParagraph(verbatim: "And He states that every messenger, without exception, came with this one message:")
                        ScriptureQuote(quran: "16:36", words: 0...10)

                        ArticleParagraph(verbatim: "Every prophet from Nooh to Muhammad (peace be upon them all) opened with the same sentence, and every nation that rejected them rejected it. The messengers differed in law; they never differed in tawheed.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("1. TAWHEED AR-RUBOOBIYYAH")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed ar-ruboobiyyah (تَوحِيد الرُّبُوبِيَّة)**, from **ر-ب-ب**, the root of **Rabb**, Lord, owner, and nurturer: Allah alone creates, owns, provides, gives life and death, and controls all that happens. Nobody shares any of it with Him.")
                        ScriptureQuote(quran: "39:62")
                        ScriptureQuote(quran: "7:54")

                        ArticleParagraph(verbatim: "Here is the point most people miss: the pagans of Makkah already believed this. They were not atheists. Allah repeatedly puts the question to them and reports their own answer:")
                        ScriptureQuote(quran: "29:61")
                        ScriptureQuote(quran: "10:31")
                        ScriptureQuote(quran: "43:87")

                        ArticleParagraph(verbatim: "Yet Allah still called them disbelievers and fought them, and their blood and wealth were not protected by that belief. Affirming the Creator, on its own, saves nobody. Iblees affirms it. This is why a religion that only argues that God exists has not yet reached the subject.")
                        ArticleParagraph(verbatim: "It is the first of the three pillars of tawheed, and its proofs and what breaks it today have their own page:")
                        ArticleDoorRow(door: .article("RububiyyahView"))
                    }

                    Section(header: ArticleHeader("2. TAWHEED AL-ULOOHIYYAH")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed al-uloohiyyah (تَوحِيد الأُلُوهِيَّة)**, from **أ-ل-ه**, the root of **ilaah**, a deity, the one turned to in worship: Allah alone is worshipped. Every act of worship, outward or inward, belongs to Him and to no one else. It is also called **tawheed al-‘ibaadah (تَوحِيد العِبَادَة)**, the tawheed of worship, and it is where the dispute between the prophets and their peoples always lay.")
                        ScriptureQuote(quran: "1:5")
                        ScriptureQuote(quran: "2:21")
                        ScriptureQuote(quran: "4:36", words: 1...6)
                        ScriptureQuote(quran: "17:23", words: 1...6)
                        ScriptureQuote(quran: "72:18")

                        ArticleParagraph(verbatim: "Allah commands that the whole of a life be handed over, not only its rituals:")
                        ScriptureQuote(quran: "6:162-163")

                        ArticleParagraph(verbatim: "The excuse the pagans gave is the same excuse given today, and Allah answered it:")
                        ScriptureQuote(quran: "39:3", words: 4...32)

                        ArticleParagraph(verbatim: "They did not believe their idols created anything. They believed they carried their requests upward. That is the shirk the Quran came to destroy. And this is exactly what they refused when the word of tawheed was put to them:")
                        ScriptureQuote(quran: "37:35-36")
                        ScriptureQuote(quran: "38:5")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) put the whole matter to Mu‘aadh (may Allah be pleased with him) in a single sentence:")
                        ScriptureQuote(hadith: "bukhari:2856", cite: "Saheeh al-Bukhaari 2856, Saheeh Muslim 30a", arabic: 40...82, english: 50...85)

                        ArticleParagraph(verbatim: "The kinds of worship, the two conditions of every deed, and how the Sunnah guards this pillar are on its own page:")
                        ArticleDoorRow(door: .article("UluhiyyahView"))
                    }

                    Section(header: ArticleHeader("3. TAWHEED AL-ASMA WAS-SIFAAT")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed al-asmaa’ was-sifaat (تَوحِيد الأَسمَاء وَالصِّفَات)**, the tawheed of the names and attributes: Allah is described the way He described Himself and the way His Messenger (peace be upon him) described Him, without denying any of it, without twisting its meaning, without asking how, and without likening Him to His creation.")
                        ScriptureQuote(quran: "7:180", words: 0...9)
                        ScriptureQuote(quran: "42:11", words: 13...18)

                        ArticleParagraph(verbatim: "That one verse holds the whole rule: “There is nothing like unto Him” denies any resemblance, and “the Hearing, the Seeing” affirms real attributes. Whoever denies the attributes has contradicted the second half; whoever likens Him to creation has contradicted the first. Surah al-Ikhlaas states it in four verses, which is why the Prophet (peace be upon him) said it equals a third of the Quran:")
                        ScriptureQuote(quran: "112:1-4")
                        ScriptureQuote(hadith: "bukhari:5015", cite: "Saheeh al-Bukhaari 5015", arabic: 49...53, english: 50...72)

                        ArticleParagraph(verbatim: "A man used to end every rak‘ah with it, and when the Prophet (peace be upon him) asked why, he said it is the description of the Most Merciful and he loved to recite it:")
                        ScriptureQuote(hadith: "bukhari:7375", cite: "Saheeh al-Bukhaari 7375", arabic: 95...98, english: 94...99)

                        // Imam Malik's rule (Abu, 2026-11-24: "mention imam malik quote in bidah too and other
                        // salafiyyah stuff if it works").
                        ArticleParagraph(verbatim: "Imam Maalik (may Allah have mercy on him) gave the rule for every attribute when a man asked him how Allah rose over the Throne:")
                        ScriptureQuote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asmaa’ was-Sifaat 867; al-Laalakaa’i 664).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true)
                        ArticleParagraph(verbatim: "The meaning is known and the how is not: the Salaf affirmed what the word says and left its manner to Allah, in the rising and in every other attribute. The rules they walked by, the four errors, and Allah’s being above His creation are on this pillar’s own page:")
                        ArticleDoorRow(door: .article("AsmaSifatView"))
                    }

                    Section(header: ArticleHeader("WHERE THE THREE CATEGORIES COME FROM")) {
                        ArticleParagraph(verbatim: "The three headings are not a new creed and nobody claims they were revealed as a list. They are a description of what the Quran itself contains, arrived at by gathering its verses, exactly as “the five pillars” is a description of a hadith and “the sciences of hadith” is a description of the Sunnah. One verse carries all three at once:")
                        ScriptureQuote(quran: "19:65")

                        ArticleParagraph(verbatim: "“Lord of the heavens and the earth” is ruboobiyyah; “so worship Him” is uloohiyyah; “Do you know of any similarity to Him?” is the names and attributes. Surat al-Faatihah does the same: “Lord of the worlds” is the first, “It is You we worship” is the second, “the Entirely Merciful, the Especially Merciful” is the third.")

                        ArticleParagraph(verbatim: "The division is reported from the Salaf in meaning long before it was a heading: Ibn Abbaas, Mujaahid and others read the pagans’ own admission of the Creator against their refusal to worship Him alone, which is the whole point of the distinction. Ibn Jareer at-Tabari, Ibn Battah, Ibn Abd al-Barr and Ibn Taymiyyah all argue on exactly this basis, and Ibn al-Qayyim set it out in Madaarij as-Saalikeen. What matters is that the meaning is Quranic, however it is arranged.")
                    }

                    Section(header: ArticleHeader("THE WORD: LA ILAAHA ILLA ALLAH")) {
                        ArticleParagraph(articleMarkdown: "**La ilaaha illallah (لَا إِلَٰهَ إِلَّا اللَّه)** is not “there is no god but God.” **Ilaah** means the one who is worshipped, so the sentence is: there is nothing rightly worshipped except Allah. It has two halves: **nafy (نَفي)**, negation, “there is no deity,” which rejects everything worshipped besides Him; and **ithbaat (إِثبَات)**, affirmation, “except Allah,” which gives all of it back to Him alone.")

                        ArticleParagraph(verbatim: "Ibraaheem (peace be upon him) said it as both halves, and Allah called it the word he left behind him:")
                        ScriptureQuote(quran: "43:26-28")

                        ArticleParagraph(verbatim: "Allah made the rejection of false objects of worship part of the handhold itself:")
                        ScriptureQuote(quran: "2:256", words: 9...20)

                        ArticleParagraph(verbatim: "And He commanded knowledge of it before He commanded anything else of it:")
                        ScriptureQuote(quran: "47:19", words: 0...7)
                    }

                    Section(header: ArticleHeader("THE CONDITIONS OF THE TESTIMONY")) {
                        ArticleParagraph(verbatim: "The scholars gathered from the Quran and the Sunnah the conditions without which the word is only a sound on the tongue. They are not extra duties added to it; each one is a verse.")

                        ArticleParagraph(articleMarkdown: "**1. Knowledge (عِلم)** of what it negates and what it affirms, the opposite of ignorance:")
                        ScriptureQuote(quran: "47:19", words: 0...5)

                        ArticleParagraph(articleMarkdown: "**2. Certainty (يَقِين)**, the opposite of doubt:")
                        ScriptureQuote(quran: "49:15")

                        ArticleParagraph(articleMarkdown: "**3. Acceptance (قَبُول)**, the opposite of rejection. The pagans understood the word and refused it:")
                        ScriptureQuote(quran: "37:35")

                        ArticleParagraph(articleMarkdown: "**4. Submission (اِنقِيَاد)**, the opposite of leaving it unacted upon:")
                        ScriptureQuote(quran: "31:22", words: 1...11)

                        ArticleParagraph(articleMarkdown: "**5. Truthfulness (صِدق)**, the opposite of hypocrisy:")
                        ScriptureQuote(quran: "29:2-3")

                        ArticleParagraph(articleMarkdown: "**6. Sincerity (إِخلَاص)**, the opposite of showing off:")
                        ScriptureQuote(quran: "98:5")

                        ArticleParagraph(articleMarkdown: "**7. Love (مَحَبَّة)** of it and of its people, the opposite of hating what it requires:")
                        ScriptureQuote(quran: "2:165", words: 0...15)

                        ArticleParagraph(verbatim: "Wahb ibn Munabbih (may Allah have mercy on him) was asked whether the key to Paradise is not “there is no deity except Allah,” and he answered: “Yes, but every key has teeth. If you come with a key that has teeth, it will open for you; if not, it will not open” (mentioned by al-Bukhaari without a chain in the Book of Funerals of his Saheeh, in the chapter on the one whose last words are “there is no deity except Allah”). The conditions are those teeth.")
                    }

                    Section(header: ArticleHeader("WHAT TAWHEED EARNS")) {
                        ArticleParagraph(verbatim: "Allah promised safety and guidance to the one whose faith is unmixed with shirk:")
                        ScriptureQuote(quran: "6:82")

                        ArticleParagraph(verbatim: "Ibn Mas‘ood (may Allah be pleased with him) reports the promise in the plainest terms:")
                        ScriptureQuote(hadith: "bukhari:6683", cite: "Saheeh al-Bukhaari 6683", arabic: 32...49, english: 12...62)
                        ScriptureQuote(hadith: "muslim:26a", cite: "Saheeh Muslim 26a", arabic: 43...53, english: 15...29)

                        ArticleParagraph(verbatim: "And no one who carried it, however little he carried with it, remains in the Fire forever:")
                        ScriptureQuote(hadith: "bukhari:44", cite: "Saheeh al-Bukhaari 44", arabic: 20...64, english: 4...100)

                        ArticleParagraph(verbatim: "Ubaadah ibn as-Saamit (may Allah be pleased with him) narrates the fullest form of the promise:")
                        ScriptureQuote(hadith: "bukhari:3435", cite: "Saheeh al-Bukhaari 3435", arabic: 34...71, english: 4...81)

                        ArticleParagraph(verbatim: "But the Prophet (peace be upon him) forbade Mu‘aadh to announce this to the people so that they would not rely on it and abandon deeds (Saheeh al-Bukhaari 128). The promise is for the one who realises the word, not for the one who leans on it.")
                        ScriptureQuote(hadith: "bukhari:128", cite: "Saheeh al-Bukhaari 128, Saheeh Muslim 32", arabic: 56...90, english: 50...114)

                        ArticleParagraph(verbatim: "And the seventy thousand who enter Paradise without reckoning are described by their tawheed, not by the volume of their worship:")
                        ScriptureQuote(hadith: "muslim:220a", cite: "Saheeh Muslim 220", arabic: 220...230, english: 410...435)
                    }

                    Section(header: ArticleHeader("WHAT BREAKS IT: SHIRK")) {
                        ArticleParagraph(articleMarkdown: "**Shirk (شِرك)**, from **ش-ر-ك**, to share or make a partner, is to give any of Allah’s right to another. Major shirk takes a person out of Islam, and if he dies upon it there is no forgiveness:")
                        ScriptureQuote(quran: "4:48", words: 0...12)
                        ScriptureQuote(quran: "5:72", words: 18...32)

                        ArticleParagraph(verbatim: "It destroys the deeds that went before it, even those of a prophet had he fallen into it:")
                        ScriptureQuote(quran: "39:65", words: 7...10)
                        ScriptureQuote(quran: "6:88", words: 9...15)

                        ArticleParagraph(verbatim: "Luqmaan’s first counsel to his son was against it, and Allah called it the greatest injustice:")
                        ScriptureQuote(quran: "31:13", words: 6...13)

                        ArticleParagraph(verbatim: "Those called upon besides Allah own nothing and hear nothing:")
                        ScriptureQuote(quran: "35:13", words: 20...27)
                        ScriptureQuote(quran: "46:5-6")

                        ArticleParagraph(articleMarkdown: "**Minor shirk (الشِّرك الأَصغَر)** does not take a person out of Islam but is more serious than any major sin, and the Prophet (peace be upon him) feared it for his nation more than he feared the Dajjaal:")
                        ScriptureQuote(hadith: "ibnmajah:4204", cite: "Sunan Ibn Maajah 4204; graded hasan by al-Albaani", arabic: 44...74, english: 18...58)
                        ScriptureQuote(hadith: "muslim:2985", cite: "Saheeh Muslim 2985", arabic: 34...51, english: 0...36)

                        ArticleParagraph(verbatim: "It also includes swearing by other than Allah, and speech that puts a creature alongside the Creator:")
                        ScriptureQuote(hadith: "tirmidhi:1535", cite: "Jaami‘ at-Tirmidhi 1535; graded saheeh by al-Albaani", arabic: 41...48, english: 31...42)
                        ScriptureQuote(hadith: "ibnmajah:2117", cite: "Sunan Ibn Maajah 2117; graded hasan saheeh by al-Albaani", arabic: 30...46, english: 0...29)

                        ArticleParagraph(verbatim: "The full treatment of shirk, its forms today, and its cure is on the Shirk page.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("1. TAWHEED AR-RUBOOBIYYAH")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed ar-ruboobiyyah (تَوحِيد الرُّبُوبِيَّة)**, from **ر-ب-ب**, the root of **Rabb**, Lord, owner, and nurturer: Allah alone creates, owns, provides, gives life and death, and controls all that happens. Nobody shares any of it with Him.")
                        ScriptureQuote(quran: "39:62")

                        ArticleParagraph(verbatim: "Here is the point most people miss: the pagans of Makkah already believed this. They were not atheists. Allah repeatedly puts the question to them and reports their own answer:")
                        ScriptureQuote(quran: "29:61")

                        ArticleParagraph(verbatim: "Yet Allah still called them disbelievers and fought them, and their blood and wealth were not protected by that belief. Affirming the Creator, on its own, saves nobody. Iblees affirms it. This is why a religion that only argues that God exists has not yet reached the subject.")
                        ArticleParagraph(verbatim: "It is the first of the three pillars of tawheed, and its proofs and what breaks it today have their own page:")
                        ArticleDoorRow(door: .article("RububiyyahView"))
                    }

                    Section(header: ArticleHeader("2. TAWHEED AL-ULOOHIYYAH")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed al-uloohiyyah (تَوحِيد الأُلُوهِيَّة)**, from **أ-ل-ه**, the root of **ilaah**, a deity, the one turned to in worship: Allah alone is worshipped. Every act of worship, outward or inward, belongs to Him and to no one else. It is also called **tawheed al-‘ibaadah (تَوحِيد العِبَادَة)**, the tawheed of worship, and it is where the dispute between the prophets and their peoples always lay.")
                        ScriptureQuote(quran: "1:5")
                        ScriptureQuote(quran: "72:18")

                        ArticleParagraph(verbatim: "The excuse the pagans gave is the same excuse given today, and Allah answered it:")
                        ScriptureQuote(quran: "39:3", words: 4...32)

                        ArticleParagraph(verbatim: "They did not believe their idols created anything. They believed they carried their requests upward. That is the shirk the Quran came to destroy.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) put the whole matter to Mu‘aadh (may Allah be pleased with him) in a single sentence:")
                        ScriptureQuote(hadith: "bukhari:2856", cite: "Saheeh al-Bukhaari 2856, Saheeh Muslim 30a", arabic: 40...82, english: 50...85)

                        ArticleParagraph(verbatim: "The kinds of worship, the two conditions of every deed, and how the Sunnah guards this pillar are on its own page:")
                        ArticleDoorRow(door: .article("UluhiyyahView"))
                    }

                    Section(header: ArticleHeader("3. TAWHEED AL-ASMA WAS-SIFAAT")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed al-asmaa’ was-sifaat (تَوحِيد الأَسمَاء وَالصِّفَات)**, the tawheed of the names and attributes: Allah is described the way He described Himself and the way His Messenger (peace be upon him) described Him, without denying any of it, without twisting its meaning, without asking how, and without likening Him to His creation.")
                        ScriptureQuote(quran: "42:11", words: 13...18)

                        ArticleParagraph(verbatim: "That one verse holds the whole rule: “There is nothing like unto Him” denies any resemblance, and “the Hearing, the Seeing” affirms real attributes. Whoever denies the attributes has contradicted the second half; whoever likens Him to creation has contradicted the first.")

                        ArticleParagraph(verbatim: "Imam Maalik (may Allah have mercy on him) gave the rule for every attribute when a man asked him how Allah rose over the Throne:")
                        ScriptureQuote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asmaa’ was-Sifaat 867; al-Laalakaa’i 664).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true)
                        ArticleParagraph(verbatim: "The meaning is known and the how is not: the Salaf affirmed what the word says and left its manner to Allah, in the rising and in every other attribute. The rules they walked by, the four errors, and Allah’s being above His creation are on this pillar’s own page:")
                        ArticleDoorRow(door: .article("AsmaSifatView"))
                    }

                    Section(header: ArticleHeader("THE WORD: LA ILAAHA ILLA ALLAH")) {
                        ArticleParagraph(articleMarkdown: "**La ilaaha illallah (لَا إِلَٰهَ إِلَّا اللَّه)** is not “there is no god but God.” **Ilaah** means the one who is worshipped, so the sentence is: there is nothing rightly worshipped except Allah. It has two halves: **nafy (نَفي)**, negation, “there is no deity,” which rejects everything worshipped besides Him; and **ithbaat (إِثبَات)**, affirmation, “except Allah,” which gives all of it back to Him alone.")

                        ArticleParagraph(verbatim: "Ibraaheem (peace be upon him) said it as both halves, and Allah called it the word he left behind him:")
                        ScriptureQuote(quran: "43:26-28")
                    }

                    Section(header: ArticleHeader("THE CONDITIONS OF THE TESTIMONY")) {
                        ArticleParagraph(verbatim: "The scholars gathered from the Quran and the Sunnah the conditions without which the word is only a sound on the tongue. They are not extra duties added to it; each one is a verse.")
                        ArticleParagraph(articleMarkdown: "They are seven: **knowledge (عِلم)** of what it negates and what it affirms, the opposite of ignorance; **certainty (يَقِين)**, the opposite of doubt; **acceptance (قَبُول)**, the opposite of rejection; **submission (اِنقِيَاد)**, the opposite of leaving it unacted upon; **truthfulness (صِدق)**, the opposite of hypocrisy; **sincerity (إِخلَاص)**, the opposite of showing off; and **love (مَحَبَّة)** of it and of its people, the opposite of hating what it requires. Of certainty Allah says:")
                        ScriptureQuote(quran: "49:15")

                        ArticleParagraph(verbatim: "Wahb ibn Munabbih (may Allah have mercy on him) was asked whether the key to Paradise is not “there is no deity except Allah,” and he answered: “Yes, but every key has teeth. If you come with a key that has teeth, it will open for you; if not, it will not open” (mentioned by al-Bukhaari without a chain in the Book of Funerals of his Saheeh, in the chapter on the one whose last words are “there is no deity except Allah”). The conditions are those teeth.")
                    }

                    Section(header: ArticleHeader("WHAT TAWHEED EARNS")) {
                        ArticleParagraph(verbatim: "Allah promised safety and guidance to the one whose faith is unmixed with shirk:")
                        ScriptureQuote(quran: "6:82")

                        ArticleParagraph(verbatim: "And the Prophet (peace be upon him) gave the promise in the plainest terms:")
                        ScriptureQuote(hadith: "muslim:26a", cite: "Saheeh Muslim 26a", arabic: 43...53, english: 15...29)

                        ArticleParagraph(verbatim: "But the Prophet (peace be upon him) forbade Mu‘aadh to announce this to the people so that they would not rely on it and abandon deeds (Saheeh al-Bukhaari 128). The promise is for the one who realises the word, not for the one who leans on it.")
                        ScriptureQuote(hadith: "bukhari:128", cite: "Saheeh al-Bukhaari 128, Saheeh Muslim 32", arabic: 56...90, english: 50...114)
                    }

                    Section(header: ArticleHeader("WHAT BREAKS IT: SHIRK")) {
                        ArticleParagraph(articleMarkdown: "**Shirk (شِرك)**, from **ش-ر-ك**, to share or make a partner, is to give any of Allah’s right to another. Major shirk takes a person out of Islam, and if he dies upon it there is no forgiveness:")
                        ScriptureQuote(quran: "4:48", words: 0...12)

                        ArticleParagraph(verbatim: "Luqmaan’s first counsel to his son was against it, and Allah called it the greatest injustice:")
                        ScriptureQuote(quran: "31:13", words: 6...13)

                        ArticleParagraph(articleMarkdown: "**Minor shirk (الشِّرك الأَصغَر)** does not take a person out of Islam but is more serious than any major sin, and the Prophet (peace be upon him) feared it for his nation more than he feared the Dajjaal:")
                        ScriptureQuote(hadith: "ibnmajah:4204", cite: "Sunan Ibn Maajah 4204; graded hasan by al-Albaani", arabic: 44...74, english: 18...58)

                        ArticleParagraph(verbatim: "The full treatment of shirk, its forms today, and its cure is on the Shirk page.")
                    }
                }

                Section(header: ArticleHeader("HOW TO GUARD IT")) {
                    ArticleParagraph(verbatim: "Learn it, because a person cannot avoid what he cannot recognise; the Prophet (peace be upon him) made tawheed the heart of thirteen years of calling in Makkah before most of the detailed law came down in Madinah. Ask Allah for it, as Ibraaheem (peace be upon him) did after a lifetime upon it: “And keep me and my sons away from worshipping idols” (Quran 14:35). Guard the means, because shirk never begins as shirk; it begins as exaggeration in a righteous man. And say often the words the Prophet (peace be upon him) taught Abu Bakr for it, promising that the little and the much of it would leave the one who says them: “O Allah, I seek refuge in You from associating anything with You knowingly, and I seek Your forgiveness for what I do not know” (al-Adab al-Mufrad 716; graded saheeh by al-Albaani).")
                    ScriptureQuote(quran: "14:35")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is it enough to believe that God exists?**")
                        ArticleParagraph(verbatim: "No, and this is the point the Quran makes against the pagans again and again. They affirmed that Allah created, provided, and controlled, and Allah still called them disbelievers (Quran 29:61, 43:87, quoted above). Belief in a Creator is where tawheed begins, not where it ends. What is asked is that He alone be worshipped.")

                        ArticleParagraph(articleMarkdown: "**Why is shirk the one unforgivable sin?**")
                        ArticleParagraph(verbatim: "Because it is not a failure of obedience but a denial of who Allah is: it gives what belongs to the Creator to a creature. Every other sin admits Allah’s right and falls short of it. Allah does forgive it when a person repents in this life, however great it was, for He says of all sins that He “forgives all sins” to those who turn back (Quran 39:53); what is not forgiven is dying upon it (Quran 4:48).")
                        ScriptureQuote(quran: "39:53", words: 12...16)

                        ArticleParagraph(articleMarkdown: "**Are the three categories of tawheed an innovation?**")
                        ArticleParagraph(verbatim: "No. A bid‘ah is an invented act of worship, not a way of arranging what the Quran already says. The three are a summary, in the way that the five pillars, the six pillars of eemaan, and the categories of hadith are summaries. Every one of the three is in the texts, and one verse holds all three (Quran 19:65, quoted above). What is asked of anyone who objects to the arrangement is whether he affirms the content: that Allah alone creates, that Allah alone is worshipped, and that His names and attributes are His as He said them.")

                        ArticleParagraph(articleMarkdown: "**If someone says the shahaadah, is he a Muslim?**")
                        ArticleParagraph(verbatim: "Yes, he enters Islam by it and is treated as a Muslim, and his blood and property are protected. But saying it while doing what breaks it is like a key with no teeth: the hypocrites said it (Quran 63:1) and Allah placed them in the lowest depth of the Fire (Quran 4:145). So the word is the door, and living by it is the road.")
                        ScriptureQuote(quran: "63:1")
                        ScriptureQuote(quran: "4:145", words: 0...6)

                        ArticleParagraph(articleMarkdown: "**Is calling on a prophet or a saint really shirk? I am only asking them to ask Allah for me.**")
                        ArticleParagraph(verbatim: "That is exactly the excuse the pagans gave, in their own words as Allah reports them: “We only worship them that they may bring us nearer to Allah in position” (Quran 39:3, quoted above). They did not believe their idols created anything. Dua is worship, and the Prophet (peace be upon him) said so (Sunan Abi Daawood 1479; Jaami‘ at-Tirmidhi 2969; graded saheeh by al-Albaani), so directing it to anyone besides Allah gives an act of worship to other than Him. Asking a living person, present and able, to make dua for you is a different matter entirely and is a Sunnah.")
                        ScriptureQuote(hadith: "abudawud:1479", cite: "Sunan Abi Daawood 1479; graded saheeh by al-Albaani", arabic: 25...33, english: 0...23)
                        ScriptureQuote(hadith: "tirmidhi:2969", cite: "Jaami‘ at-Tirmidhi 2969; graded saheeh by al-Albaani", arabic: 33...35, english: 33...37)

                        ArticleParagraph(articleMarkdown: "**Does a person’s tawheed increase and decrease?**")
                        ArticleParagraph(verbatim: "Yes. Ahl as-Sunnah hold that faith increases with obedience and decreases with sin, and tawheed is its heart. Two people may say the same sentence and be worlds apart in their realisation of it. The seventy thousand who enter without reckoning are distinguished by the completeness of their reliance (Saheeh Muslim 220, quoted above), not by a different testimony.")

                        ArticleParagraph(articleMarkdown: "**What is the difference between tawheed and simply being a good person?**")
                        ArticleParagraph(verbatim: "Good character is commanded and rewarded, and it is part of the religion. But deeds are accepted on the condition of tawheed: Allah says that even a prophet’s works would be worthless with shirk (Quran 39:65, quoted above), and that He will turn to scattered dust the deeds of those who disbelieved (Quran 25:23). Tawheed is not one virtue among others; it is the condition on which the others are accepted.")
                        ScriptureQuote(quran: "25:23")

                        ArticleParagraph(articleMarkdown: "**Is asking Allah by His names the same as tawassul through a person?**")
                        ArticleParagraph(verbatim: "No. Allah commanded the first: “And to Allah belong the best names, so invoke Him by them” (Quran 7:180, quoted above). Asking Allah by His names, by one’s own faith and righteous deeds, or by the dua of a living righteous person are all established. Calling on the dead, or asking them to carry a request, is not established from anyone and is the substance of what the pagans did. The details are on the Shirk page.")

                        ArticleParagraph(articleMarkdown: "**Did the Companions need this subject explained?**")
                        ArticleParagraph(verbatim: "They were Arabs who knew what ilaah meant in their language, so when they heard “there is no deity except Allah” they knew at once that it demanded they leave their idols, which is why they fought it (Quran 38:5, quoted above). Later generations, further from the language and nearer to the graves of the righteous, needed it explained again. That is why the scholars wrote whole books on this one word.")

                        ArticleParagraph(articleMarkdown: "**Where do I start if I want to learn this properly?**")
                        ArticleParagraph(verbatim: "With al-Usool ath-Thalaathah of Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him): the three questions every person is asked, in a few pages. Then Kitaab at-Tawheed of the same author, which is sixty-six chapters of nothing but Quran, hadith, and the statements of the Salaf, and then al-Qawaa‘id al-Arba‘ and Kashf ash-Shubuhaat, and al-Aqeedah al-Waasitiyyah of Ibn Taymiyyah. Read them with the explanations of Ibn Baaz and Ibn al-Uthaymeen (may Allah have mercy on them), and with a teacher if you can find one.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is calling on a prophet or a saint really shirk? I am only asking them to ask Allah for me.**")
                        ArticleParagraph(verbatim: "That is exactly the excuse the pagans gave, in their own words as Allah reports them: “We only worship them that they may bring us nearer to Allah in position” (Quran 39:3, quoted above). They did not believe their idols created anything. Dua is worship, and the Prophet (peace be upon him) said so (Sunan Abi Daawood 1479; Jaami‘ at-Tirmidhi 2969; graded saheeh by al-Albaani), so directing it to anyone besides Allah gives an act of worship to other than Him. Asking a living person, present and able, to make dua for you is a different matter entirely and is a Sunnah.")
                        ScriptureQuote(hadith: "abudawud:1479", cite: "Sunan Abi Daawood 1479; graded saheeh by al-Albaani", arabic: 25...33, english: 0...23)
                        ScriptureQuote(hadith: "tirmidhi:2969", cite: "Jaami‘ at-Tirmidhi 2969; graded saheeh by al-Albaani", arabic: 33...35, english: 33...37)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Tawheed is to single Allah out in His lordship, His worship, and His names and attributes. Every messenger came with it, the pagans of Makkah accepted the first part and were fought over the second, and the whole of the religion is either a fulfilment of it or a protection of it. Say the word, learn what it negates and what it affirms, act on it, and guard it from everything that competes with Allah in the heart.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed (تَوحِيد)**: the verbal noun of **wahhada**, from **و-ح-د**, to make one, to single out. To single Allah out in everything that is His alone. Its opposite is **shirk**.")

                        ArticleParagraph(articleMarkdown: "**Rabb (رَبّ)**: from **ر-ب-ب**, to own, nurture, and bring to completion. It is not simply “lord”: it carries owner, sustainer, and the one who raises a thing stage by stage until it is complete. Hence **ruboobiyyah (رُبُوبِيَّة)**, Allah’s exclusive lordship over creating, owning, providing and disposing.")

                        ArticleParagraph(articleMarkdown: "**Ilaah (إِلَٰه)**: from **أ-ل-ه**, to turn to in longing and need, and from it **uloohiyyah (أُلُوهِيَّة)**. An ilaah is the one worshipped, not merely a powerful being, which is why “there is no deity except Allah” means there is nothing rightly worshipped except Him. Al-Ilaah with the article became **Allah (اللَّه)**, His proper name, which no created thing has ever borne (Quran 19:65).")

                        ArticleParagraph(articleMarkdown: "**Ibaadah (عِبَادَة)**: from **ع-ب-د**, to submit and humble oneself; a paved road is called **mu‘abbad** because it is made smooth underfoot. Ibn Taymiyyah’s definition in al-Uboodiyyah is the one the scholars use: “a comprehensive name for everything Allah loves and is pleased with, of statements and actions, inward and outward.” So dua, fear, hope, reliance, vowing, sacrifice, bowing and asking for rescue are all worship, and directing any of them to other than Allah is shirk.")

                        ArticleParagraph(articleMarkdown: "**Shirk (شِرك)**: from **ش-ر-ك**, to share or associate. **Major shirk (الشِّرك الأَكبَر)** takes a person out of Islam; **minor shirk (الشِّرك الأَصغَر)**, such as showing off and swearing by other than Allah, does not, but is greater than any major sin. **Hidden shirk (الشِّرك الخَفِي)** is the name the Prophet (peace be upon him) gave to riyaa’ in the hadith quoted above (Sunan Ibn Maajah 4204).")

                        ArticleParagraph(articleMarkdown: "**Taaghoot (طَاغُوت)**: from **ط-غ-ي**, to exceed all bounds. Umar ibn al-Khattaab (may Allah be pleased with him) said it is ash-shaytaan (Tafseer at-Tabari on 2:256), and Ibn al-Qayyim defined it as whatever a servant exceeds his limit with, whether worshipped, followed, or obeyed. Disbelief in it is half of the handhold (Quran 2:256, quoted above).")

                        ArticleParagraph(articleMarkdown: "**Nafy (نَفي)** and **ithbaat (إِثبَات)**: negation and affirmation, the two halves of the testimony. “There is no deity” clears the ground of everything falsely worshipped; “except Allah” gives all of it to Him alone. A word with only the first half is nihilism, and with only the second is the creed of the pagans, who affirmed Allah and worshipped others with Him.")

                        ArticleParagraph(articleMarkdown: "**Ikhlaas (إِخلَاص)**: from **خ-ل-ص**, for a thing to become pure and free of what is mixed with it. To intend Allah alone by an act. Its opposite is **riyaa’ (رِيَاء)**, from **ر-أ-ي**, to see: performing an act so that people will see it. Surat al-Ikhlaas is named for purifying the description of Allah, and the deed is named for purifying the intention.")

                        ArticleParagraph(articleMarkdown: "**Tawakkul (تَوَكُّل)**: from **و-ك-ل**, to entrust an affair to someone. To depend upon Allah with the heart while taking the means He legislated. It is not the abandonment of means: the Prophet (peace be upon him) told a man to tie his camel and then rely on Allah (Jaami‘ at-Tirmidhi 2517; graded hasan by al-Albaani), and he himself wore armour in battle. It is the tawheed of the heart, and it is the trait by which the seventy thousand were described (Saheeh Muslim 220, quoted above).")
                        ScriptureQuote(hadith: "tirmidhi:2517", cite: "Jaami‘ at-Tirmidhi 2517; graded hasan by al-Albaani", arabic: 23...37, english: 0...24)

                        ArticleParagraph(articleMarkdown: "**Fitrah (فِطرَة)**: from **ف-ط-ر**, to originate or split open something new. The original disposition Allah created every human upon, which knows its Creator before it is taught. The Prophet (peace be upon him) said every child is born upon the fitrah and it is his parents who make him otherwise (Saheeh al-Bukhaari 1385).")
                        ScriptureQuote(hadith: "bukhari:1385", cite: "Saheeh al-Bukhaari 1385, Saheeh Muslim 2658", arabic: 31...49, english: 4...44)

                        ArticleParagraph(articleMarkdown: "**Kitaab at-Tawheed (كِتَاب التَّوحِيد)**: the best known book on this subject, by Muhammad ibn Abd al-Wahhaab (d. 1206 AH). Sixty-six short chapters, each one a heading followed by verses, authentic hadith, and statements of the Salaf, with almost no words of the author’s own. **Al-Usool ath-Thalaathah (الأُصُول الثَّلَاثَة)**, the three fundamentals, is his shorter primer built on the three questions of the grave: who is your Lord, what is your religion, and who is your Prophet.")
                    }
                }

                ArticleSourcesSection(article: "TawhidView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tawheed: The Oneness of Allah")
        .englishArticle().selectableArticleList(article: "TawhidView")
    }
}

struct SalafiyyahView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "SalafiyyahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Salafiyyah")
        .englishArticle().selectableArticleList(article: "SalafiyyahView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Salafiyyah is following the Quran and the Sunnah upon the understanding of the Salaf, the first three generations. It is not a new sect or a party; it is the name for the original Islam, and its creed is the Athari creed."),
        ]),
        ArticleSection("WHO ARE THE SALAF?", [
            .markdown("**Salaf (سَلَف)** means “those who came before.” In the religion it means **as-Salaf as-Saalih (السَّلَف الصَّالِح)**, the Righteous Predecessors: the Companions (**Sahaabah**), their students (**Taabi‘oon**), and the students of those (**Atbaa‘ at-Taabi‘een**), the three generations the Prophet (peace be upon him) praised:"),
            .hadith("bukhari:2652", cite: "Saheeh al-Bukhaari 2652", arabic: 29...37, english: [4...23]),
            .markdown("A **Salafi (سَلَفِي)** is simply one who ascribes himself to the Salaf: who takes his creed, worship, and understanding from them rather than from later opinions. **Salafiyyah (السَّلَفِيَّة)** is that way. It is another name for **Ahl as-Sunnah wal-Jamaa‘ah (أَهل السُّنَّة وَالجَمَاعَة)**, the people of the Sunnah and of the united body; **Ahl al-Hadith (أَهل الحَدِيث)**, the people of hadith; and **Ahl al-Athar (أَهل الأَثَر)**, the people of narration, from the root أ-ث-ر, a track or trace left behind."),
        ]),
        ArticleSection("WHY THE SALAF?", [
            .text("Because Allah (Glorified and Exalted be He) made their way the standard, and made following anything else a way to the Fire:"),
            .ayah("4:115"),
            .text("“The way of the believers” when this verse came down was the way of the Companions. Allah then declared Himself pleased with them and with those who follow them:"),
            .ayah("9:100", words: 0...12),
            .text("The Prophet (peace be upon him) named the one saved group by exactly this standard:"),
            .hadith("tirmidhi:2641", cite: "Jaami‘ at-Tirmidhi 2641; graded hasan by al-Albaani", arabic: 91...94, english: [47...92]),
            .hadith("abudawud:4607", cite: "Sunan Abi Daawood 4607; graded saheeh by al-Albaani", arabic: 112...132, english: [159...192]),
            .text("The Companions received the Quran as it came down, heard the Sunnah from the mouth of the Prophet (peace be upon him), and watched him live it. Nobody who came later can understand revelation better than those it was revealed among. So whoever wants the religion as it was sent must take it through them."),
        ]),
        ArticleSection("WHAT THE SALAF SAID ABOUT THEIR WAY", [
            .text("Abdullah ibn Mas‘ood (may Allah be pleased with him) said:"),
            .hadith("darimi:207", cite: "Sunan ad-Daarimi 207; al-Haythami: its narrators are those of the Saheeh, Majma' az-Zawaa’id 1/181", arabic: 23...27, text: "“Follow, and do not innovate, for you have been sufficed”"),
            .longOnly(.text("Imam al-Awzaa‘i (may Allah have mercy on him), the imam of Syria (d. 157 AH), said:")),
            .longOnly(.quote(text: "“Hold to the narrations of those who came before, even if the people reject you, and beware of the opinions of men, even if they beautify them for you with speech” (al-Khateeb al-Baghdaadi, Sharaf Ashaab al-Hadith 6; al-Aajurri, ash-Sharee‘ah 127).", arabic: "عَلَيكَ بِآثَارِ مَن سَلَفَ وَإِن رَفَضَكَ النَّاسُ، وَإِيَّاكَ وَآرَاءَ الرِّجَالِ وَإِن زَخرَفُوهُ لَكَ بِالقَولِ", dimmed: true)),
            .longOnly(.text("Imam Abu Haneefah (may Allah have mercy on him) said:")),
            .longOnly(.quote(text: "“It is not permitted for anyone to take our saying as long as he does not know where we took it from” (Ibn Abd al-Barr, al-Intiqaa’ fi Fadaa’il al-A’immah ath-Thalaathah al-Fuqahaa’, p. 145; quoted by al-Albaani in the introduction to Sifaat Salaat an-Nabi).", arabic: "لَا يَحِلُّ لِأَحَدٍ أَن يَأخُذَ بِقَولِنَا مَا لَم يَعلَم مِن أَينَ أَخَذنَاهُ", dimmed: true)),
            .longOnly(.text("Imam al-Barbahaari (may Allah have mercy on him) (d. 329 AH) opened his creed with:")),
            .longOnly(.quote(text: "“Know that Islam is the Sunnah and the Sunnah is Islam, and neither of them stands without the other” (al-Barbahaari, Sharh as-Sunnah 1).", arabic: "اعلَمُوا أَنَّ الإِسلَامَ هُوَ السُّنَّةُ، وَالسُّنَّةُ هِيَ الإِسلَامُ، وَلَا يَقُومُ أَحَدُهُمَا إِلَّا بِالآخَرِ", dimmed: true)),
            .text("And Shaykh al-Islam Ibn Taymiyyah (may Allah have mercy on him) wrote:"),
            .quote(text: "“There is no blame on the one who manifests the way of the Salaf, ascribes himself to it, and takes pride in it; rather it is obligatory to accept that from him by agreement, for the way of the Salaf can be nothing but the truth” (Majmoo‘ al-Fataawa 4/149).", arabic: "لَا عَيبَ عَلَى مَن أَظهَرَ مَذهَبَ السَّلَفِ وَانتَسَبَ إِلَيهِ وَاعتَزَى إِلَيهِ، بَل يَجِبُ قَبُولُ ذَلِكَ مِنهُ بِالِاتِّفَاقِ، فَإِنَّ مَذهَبَ السَّلَفِ لَا يَكُونُ إِلَّا حَقًّا", dimmed: true),
        ]),
        ArticleSection("THE NAME “SALAFI” THROUGH THE CENTURIES", [
            .text("Is the name new? The honest answer has two halves. The ascription “Salafi” itself is not in the Quran, in any hadith, or in the words of the Companions, any more than “Hanbali,” “Ash‘ari,” or even the word “aqeedah” is: the Companions needed no name for following the Companions. What the Quran and the Sunnah do contain is the word salaf, the generations it came to name, and the command to follow them; and the ascription itself was in the scholars’ books centuries before anyone living today. Here is the record, layer by layer."),
            .longOnly(.markdown("**In the Quran.** The root **س-ل-ف** occurs eight times. Seven are verbs: “what has passed,” five times (as in Quran 8:38), and what a soul “sent ahead” of its deeds, twice (as in Quran 69:24).")),
            .longOnly(.ayah("8:38", words: 7...9)),
            .longOnly(.ayah("69:24", words: 3...4)),
            .longOnly(.markdown("The one noun, **salaf**, describes Pharaoh’s people as “a precedent and an example for the later peoples” (Quran 43:56, in the Key Terms), a warning and not a praise. So the Quran does not praise a group by the word “Salaf”; it praises the people the word later came to mean, those who went first in faith, and teaches those who come after them to pray for them:")),
            .longOnly(.ayah("59:10", words: 0...11)),
            .longOnly(.markdown("**In the Sunnah.** The Prophet (peace be upon him) used the word for himself in his last illness, comforting Faatimah (may Allah be pleased with her):")),
            .longOnly(.hadith("bukhari:6285", cite: "Saheeh al-Bukhaari 6285, Saheeh Muslim 2450", arabic: 168...175, english: [241...259])),
            .longOnly(.text("An-Nawawi explained that salaf here is the one who goes ahead: “I go before you, and you will come to me” (Sharh Saheeh Muslim 16/6–7). The generations the scholars later called the Salaf are the ones he named the best of people (Saheeh al-Bukhaari 2652, quoted above). The words often quoted from the burial of his daughter, “join our righteous salaf, Uthmaan ibn Maz‘oon,” are weak (Musnad Ahmad 2127; al-Albaani, Silsilat al-Ahaadeeth ad-Da‘eefah 1715), so they are not relied on here.")),
            .longOnly(.markdown("**From the Companions.** They did not call themselves the Salaf, because they were the Salaf. But they told the generation after them to hold to the path of those who went first. Hudhayfah (may Allah be pleased with him) said:")),
            .longOnly(.hadith("bukhari:7282", cite: "Saheeh al-Bukhaari 7282", arabic: 14...29, english: [2...37])),
            .longOnly(.text("Ibn Hajar explained that Hudhayfah was addressing those who had caught the beginning of Islam: if they held to the Book and the Sunnah they would lead in every good, and whoever came after them could not reach them (Fath al-Baari 13/257). Abdullah ibn Mas‘ood (may Allah be pleased with him) said:")),
            .longOnly(.quote(text: "“Let none of you follow a man blindly in his religion, so that if he believes he believes and if he disbelieves he disbelieves. If you must follow someone, then follow the one who has died, for the one who is living is not safe from trial” (at-Tabaraani, al-Mu‘jam al-Kabeer 8764; al-Haythami: its narrators are those of the Saheeh, Majma‘ az-Zawaa’id 1/180).", arabic: "لَا يُقَلِّدَنَّ أَحَدُكُم دِينَهُ رَجُلًا، فَإِن آمَنَ آمَنَ، وَإِن كَفَرَ كَفَرَ، وَإِن كُنتُم لَا بُدَّ مُقتَدِينَ فَاقتَدُوا بِالمَيِّتِ، فَإِنَّ الحَيَّ لَا يُؤمَنُ عَلَيهِ الفِتنَةُ", dimmed: true)),
            .longOnly(.text("Spoken by a Companion, “the one who has died” points to those who had already passed on upon the guidance before him.")),
            .longOnly(.markdown("**Among the Taabi‘oon and the imams,** “the Salaf” was already the name for the Companions and those who followed them. Raashid ibn Sa‘d of Syria (d. 113 AH), one of the Taabi‘oon, said:")),
            .longOnly(.quote(text: "“The Salaf used to prefer stallions, because they are faster and bolder” (related by al-Bukhaari in his Saheeh, Book of Jihad, chapter on riding a difficult mount and stallions).", arabic: "كَانَ السَّلَفُ يَستَحِبُّونَ الفُحُولَةَ لِأَنَّهَا أَجرَى وَأَجسَرُ", dimmed: true)),
            .longOnly(.text("Ibn Hajar explained “the Salaf” there as the Companions and those after them (Fath al-Baari 6/66). Al-Bukhaari himself titled a chapter of the Book of Foods “What the Salaf used to store in their houses and on their journeys of food, meat, and other things.” Abdullah ibn al-Mubaarak (d. 181 AH) said before a gathering, as Imam Muslim relates in the introduction to his Saheeh:")),
            .longOnly(.quote(text: "“Leave the hadith of Amr ibn Thaabit, for he used to revile the Salaf” (Muqaddimah of Saheeh Muslim).", arabic: "دَعُوا حَدِيثَ عَمرِو بنِ ثَابِتٍ فَإِنَّهُ كَانَ يَسُبُّ السَّلَفَ", dimmed: true)),
            .longOnly(.text("And al-Awzaa‘i (d. 157 AH), the imam of Syria, said:")),
            .longOnly(.quote(text: "“Keep yourself patient upon the Sunnah: stop where the people stopped, say what they said, refrain from what they refrained from, and tread the path of your righteous Salaf, for what was wide enough for them will be wide enough for you” (al-Laalakaa’i, Sharh Usool I‘tiqaad Ahl as-Sunnah 315; al-Aajurri, ash-Sharee‘ah 294).", arabic: "اصبِر نَفسَكَ عَلَى السُّنَّةِ، وَقِف حَيثُ وَقَفَ القَومُ، وَقُل بِمَا قَالُوا، وَكُفَّ عَمَّا كَفُّوا عَنهُ، وَاسلُك سَبِيلَ سَلَفِكَ الصَّالِحِ، فَإِنَّهُ يَسَعُكَ مَا وَسِعَهُم", dimmed: true)),
            .longOnly(.text("Why did a name appear at all? For the reason Muhammad ibn Seereen (d. 110 AH) gave for the isnaad:")),
            .longOnly(.quote(text: "“They did not use to ask about the isnaad. When the fitnah came, they said: name your men to us. Then the people of the Sunnah would be looked at and their hadith taken, and the people of innovation would be looked at and their hadith not taken” (Muqaddimah of Saheeh Muslim).", arabic: "لَم يَكُونُوا يَسأَلُونَ عَنِ الإِسنَادِ، فَلَمَّا وَقَعَتِ الفِتنَةُ قَالُوا: سَمُّوا لَنَا رِجَالَكُم، فَيُنظَرُ إِلَى أَهلِ السُّنَّةِ فَيُؤخَذُ حَدِيثُهُم، وَيُنظَرُ إِلَى أَهلِ البِدَعِ فَلَا يُؤخَذُ حَدِيثُهُم", dimmed: true)),
            .longOnly(.text("Before the sects, “Muslim” was enough. Once the sects appeared, every one of them still said “Muslim,” so the people of the original way came to be named by what set them apart: Ahl as-Sunnah, Ahl al-Hadith, Ahl al-Athar, and, once the schools of kalaam had spread, Salafi.")),
            .shortOnly(.text("In brief: the Quran uses the root for what has passed and for what a soul sent ahead, and it praises not a group called by the word but the people the word later came to mean, those who went first in faith. The Companions did not call themselves the Salaf, because they were the Salaf. Among the Taabi‘oon and the imams, “the Salaf” was already the name for the Companions and those who followed them. Before the sects, “Muslim” was enough. Once the sects appeared, every one of them still said “Muslim,” so the people of the original way came to be named by what set them apart: Ahl as-Sunnah, Ahl al-Hadith, Ahl al-Athar, and, once the schools of kalaam had spread, Salafi.")),
            .markdown("**The ascription “Salafi.”** Abu Sa‘d as-Sam‘aani (d. 562 AH), whose al-Ansaab is the standard dictionary of the ascriptions Muslims were known by, gave it an entry of its own:"),
            .quote(text: "“As-Salafi, with a fathah on the sin and the lam and a fa’ at the end: this ascription is to the Salaf and to adopting their way, according to what I have heard” (as-Sam‘aani, al-Ansaab 7/168).", arabic: "السَّلَفِيُّ: بِفَتحِ السِّينِ وَاللَّامِ وَفِي آخِرِهَا الفَاءُ، هَذِهِ النِّسبَةُ إِلَى السَّلَفِ وَانتِحَالِ مَذهَبِهِم عَلَى مَا سَمِعتُ", dimmed: true),
            .longOnly(.text("Ibn al-Atheer (d. 630 AH) repeated the entry and added that a group of people were known by it (al-Lubaab fi Tahdheeb al-Ansaab 2/126). The earliest man recorded under it, Abu Bakr Abd ar-Rahman ibn Abdullah as-Sarakhsi as-Salafi, heard hadith from Abu al-Fityaan ar-Rawwaasi (d. 503 AH) (Ibn Nuqtah, Takmilat al-Ikmaal 3/340, from as-Sam‘aani). Adh-Dhahabi (d. 748 AH) gave the definition in a line: the Salafi “is the one upon the madhhab of the Salaf” (Siyar A‘laam an-Nubalaa’ 21/6), and he used the word to praise the imams. Of the hadith master he wrote:")),
            .longOnly(.quote(text: "“What the hadith master needs is to be pious, intelligent, a grammarian, a linguist, pure, modest, and Salafi” (Siyar A‘laam an-Nubalaa’ 13/380, in the life of Uthmaan ibn Khurrazaadh).", arabic: "فَالَّذِي يَحتَاجُ إِلَيهِ الحَافِظُ أَن يَكُونَ تَقِيًّا ذَكِيًّا، نَحوِيًّا لُغَوِيًّا، زَكِيًّا، حَيِيًّا، سَلَفِيًّا", dimmed: true)),
            .longOnly(.text("Of ad-Daaraqutni (d. 385 AH), the great critic of hadith, he wrote:")),
            .shortOnly(.text("Adh-Dhahabi (d. 748 AH) gave the definition in a line: the Salafi “is the one upon the madhhab of the Salaf” (Siyar A‘laam an-Nubalaa’ 21/6), and he used the word to praise the imams. Of ad-Daaraqutni (d. 385 AH), the great critic of hadith, he wrote:")),
            .quote(text: "“The man never entered into the science of kalaam or disputation, and never plunged into it; rather, he was Salafi” (Siyar A‘laam an-Nubalaa’ 16/457).", arabic: "لَم يَدخُلِ الرَّجُلُ أَبَدًا فِي عِلمِ الكَلَامِ وَلَا الجِدَالِ، وَلَا خَاضَ فِي ذَلِكَ، بَل كَانَ سَلَفِيًّا", dimmed: true),
            .longOnly(.text("And of Ibn as-Salaah (d. 643 AH), the author of the Muqaddimah in the sciences of hadith:")),
            .longOnly(.quote(text: "“He was Salafi, sound in creed, holding back from the reinterpretation of the theologians, believing in what is established in the texts, neither plunging in nor delving deep” (adh-Dhahabi, Tadhkirat al-Huffaaz, in his life).", arabic: "وَكَانَ سَلَفِيًّا حَسَنَ الِاعتِقَادِ، كَافًّا عَن تَأوِيلِ المُتَكَلِّمِينَ، مُؤمِنًا بِمَا ثَبَتَ مِنَ النُّصُوصِ، غَيرَ خَائِضٍ وَلَا مُعَمِّقٍ", dimmed: true)),
            .longOnly(.text("He wrote the same of Ya‘qoob al-Fasawi, “I have only known him as a Salafi” (Siyar 13/183); of the vizier Ibn Hubayrah, “Salafi, Athari” (Siyar 20/426); and of Muhammad ibn Yahya az-Zabeedi, “a Hanafi, a Salafi” (Siyar 20/317): Hanafi in fiqh and Salafi in creed, the pairing explained in “The Madhaahib of Aqeedah.” Ibn Taymiyyah’s ruling on whoever takes the name is quoted above, and Ibn Rajab (d. 795 AH) wrote a treatise on the superiority of the Salaf’s knowledge, Fadl Ilm as-Salaf ‘ala Ilm al-Khalaf.")),
            .longOnly(.text("One name in the books is not what it looks like. The hadith master Abu Taahir as-Silafi of Isfahan and Alexandria (d. 576 AH) is “Silafi” with a kasrah, from Silafah, a Persian family nickname about a lip; the name has nothing to do with the Salaf, as adh-Dhahabi and Ibn Khallikaan both explain (Siyar 21/6; Wafayaat al-A‘yaan 1/107), and it proves nothing either way.")),
            .text("So the record is clear. The Companions were the Salaf; the Taabi‘oon called them by that name; the imams told their students to tread the path of their Salaf; and once the schools of kalaam had spread, the scholars called whoever held to the old way “Salafi.” It is a late word for an early thing, like “Ahl as-Sunnah” before it, and what gives it its worth is not its age but what it points to: the Companions, and “those who followed them with good conduct” (Quran 9:100, quoted above)."),
        ]),
        ArticleSection("WHY THE ATHARI CREED IS THE TRUTH", [
            .markdown("The creed of Salafiyyah is the **Athari** creed, the creed of narration (see “The Madhaahib of Aqeedah”). It is the truth for four reasons."),
            .markdown("**1. Creed can only come from revelation.** The existence and perfection of the Creator are known by the fitrah and by reason, but the detail of His names, His attributes, the unseen, and the Hereafter can only be told; it is revealed, or it is not known. So the only sound creed is the one taken from the texts as they are:"),
            .ayah("53:3-4"),
            .markdown("**2. The religion was completed in the Companions’ time.** Whatever belief they did not hold was not part of Islam then, and cannot be part of it now:"),
            .ayah("5:3", words: 39...49),
            .markdown("**3. It is the creed of every prophet.** Allah said the same thing to Nooh, Ibraaheem, Moosa, Eesa, and Muhammad (peace be upon them all): worship Allah alone, believe in what He revealed, without addition:"),
            .ayah("16:36", words: 0...10),
            .longOnly(.markdown("**4. It is what the four imams believed.** Abu Haneefah, Maalik, ash-Shaafi‘i, and Ahmad all affirmed the attributes as they came, said the Quran is Allah’s uncreated speech, and condemned kalaam. Imam ash-Shaafi‘i (may Allah have mercy on him) said:")),
            .longOnly(.quote(text: "“For a servant to be afflicted with everything Allah has forbidden, except shirk, is better for him than kalaam. I have come across things from the people of kalaam that I never thought a Muslim would say” (Ibn Abi Haatim, Adab ash-Shaafi‘i wa Manaaqibuh, from his student Yoonus ibn Abd al-A‘la).", arabic: "لَأَن يُبتَلَى العَبدُ بِكُلِّ مَا نَهَى اللَّهُ عَنهُ سِوَى الشِّركِ خَيرٌ لَهُ مِنَ الكَلَامِ، وَلَقَدِ اطَّلَعتُ مِن أَصحَابِ الكَلَامِ عَلَى شَيءٍ مَا ظَنَنتُ أَنَّ مُسلِمًا يَقُولُ ذَلِكَ", dimmed: true)),
            .longOnly(.text("The line often quoted from him, “I believe in Allah and in what came from Allah as Allah intended,” is given by Ibn Qudaamah in Lum‘at al-I‘tiqaad without a chain. Its meaning is true, as Ibn Taymiyyah said (Majmoo‘ al-Fataawa 6/354), but the words above are the ones that reach him through his students.")),
            .longOnly(.text("And when a man asked Imam Maalik (may Allah have mercy on him) how Allah rose over His Throne, he gave the rule all four imams followed in every attribute:")),
            .shortOnly(.markdown("**4. It is what the four imams believed.** Abu Haneefah, Maalik, ash-Shaafi‘i, and Ahmad all affirmed the attributes as they came, said the Quran is Allah’s uncreated speech, and condemned kalaam. When a man asked Imam Maalik (may Allah have mercy on him) how Allah rose over His Throne, he gave the rule all four imams followed in every attribute:")),
            .quote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asmaa’ was-Sifaat 867; al-Laalakaa’i 664).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true),
            .text("Every other creed appeared later, is named after a man or a movement, and changes the texts to fit an argument. The way of the Salaf changes nothing and adds nothing."),
        ]),
        ArticleSection("WHAT SALAFIYYAH IS NOT", [
            .text("It is not a political party, a modern movement, or a school named after a founder; nobody founded it. It is not harshness; the Salaf were the most merciful of people to the believers. It is not takfeer of Muslims; that is the way of the Khawaarij, whom the Salaf fought. And it is not a claim that a particular group of people are saved by their label; it is a standard that every person, including the one who calls himself Salafi, is measured against."),
            .ayah("12:108"),
        ]),
        ArticleSection("SHAYKH MUHAMMAD IBN ABD AL-WAHHAAB", [
            .text("No name is attached to Salafiyyah more often, or more unfairly, than his, so it is worth stating plainly who he was and what he actually said."),
            .longOnly(.text("Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him) was born in 1115 AH (1703 CE) in al-Uyaynah in Najd, in the centre of the Arabian Peninsula, into a house of Hanbali judges: his father was the judge of the town and his grandfather a jurist before him. He memorised the Quran young, studied in Makkah, Madinah, Basrah and al-Ahsa, and returned to a land where the religion had thinned to a shell. People sought children and cures at the tomb of Zayd ibn al-Khattaab (may Allah be pleased with him), women came to a tree called the tree of Abu Dujaanah to hang cloth on it for a husband, sacrifices were offered to the jinn at the caves, and soothsayers were consulted. He wrote later that the greater part of what he called people to was simply the meaning of “there is no deity except Allah.”")),
            .longOnly(.text("He founded no madhhab. His books are almost entirely other people’s words: Kitaab at-Tawheed is sixty-six chapters of verses, authentic hadith, and statements of the Salaf with barely a sentence of his own; al-Usool ath-Thalaathah is three questions and their evidences; al-Qawaa‘id al-Arba‘, Kashf ash-Shubuhaat, Nawaaqid al-Islam and Masaa’il al-Jaahiliyyah are the same in miniature. He set out his own position in his letter to the people of al-Qaasim, which begins by naming the creed of the Salaf and not a creed of his own:")),
            .shortOnly(.text("Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him) was born in 1115 AH (1703 CE) in al-Uyaynah in Najd, into a house of Hanbali judges. He studied in Makkah, Madinah, Basrah and al-Ahsa, and returned to a land where people sought children and cures at a tomb, hung cloth on a tree for a husband, offered sacrifices to the jinn, and consulted soothsayers. He wrote later that the greater part of what he called people to was simply the meaning of “there is no deity except Allah.” He founded no madhhab: Kitaab at-Tawheed is sixty-six chapters of verses, authentic hadith, and statements of the Salaf with barely a sentence of his own. He set out his own position in his letter to the people of al-Qaasim:")),
            .quote(text: "“I call Allah to witness, and the angels present with me, and I call you to witness, that I believe what the Saved Sect, Ahl as-Sunnah wal-Jamaa‘ah, believes” (ad-Durar as-Saniyyah 1/29, his letter of creed to the people of al-Qaasim).", arabic: "أُشهِدُ اللَّهَ وَمَن حَضَرَنِي مِنَ المَلَائِكَةِ وَأُشهِدُكُم أَنِّي أَعتَقِدُ مَا اعتَقَدَتهُ الفِرقَةُ النَّاجِيَةُ أَهلُ السُّنَّةِ وَالجَمَاعَةِ", dimmed: true),
            .longOnly(.text("In his letters he stated that he was, by Allah’s grace, a follower and not an innovator; that in the branches of fiqh he was upon the madhhab of Imam Ahmad; and that he did not censure anyone who followed one of the four imams (ad-Durar as-Saniyyah, vol. 1). The accusations circulated against him are answered by his own pen in the same collection: he denied claiming prophethood, denied denying the intercession of the Prophet (peace be upon him), denied burning books of praise for the Prophet, and denied making takfeer of the Muslims in general, writing that he did not declare a person a disbeliever except where the proof had been established against him, and calling such reports the invention of his enemies.")),
            .shortOnly(.text("In his letters he stated that he was a follower and not an innovator, upon the madhhab of Imam Ahmad in the branches of fiqh, and he denied the charges circulated against him, among them making takfeer of the Muslims in general, calling such reports the invention of his enemies (ad-Durar as-Saniyyah, vol. 1).")),
            .text("He is judged, as any scholar is, by his own books and letters, not by what later men did in his name, and not by what his opponents reported of him. That is the rule Allah gave for accepting any report:"),
            .ayah("49:6", words: 0...7),
            .ayah("17:36"),
            .longOnly(.text("And the rule for judging anyone, friend or opponent:")),
            .longOnly(.ayah("5:8", words: 0...18)),
            .longOnly(.text("A Salafi still does not accept the label “Wahhaabi,” for the two reasons given in the Key Terms: al-Wahhaab is a name of Allah, not of the Shaykh, and Salafiyyah is ascribed to the Salaf and to no later man however great. He was one of many revivers of the call, not its founder, and the same call was made before him by Ibn Taymiyyah, and before him by Ibn Battah and al-Barbahaari, and before them by Imam Ahmad.")),
            .shortOnly(.text("So a Salafi does not accept the label “Wahhaabi” that his opponents coined: al-Wahhaab is a name of Allah, not of the Shaykh, and Salafiyyah is ascribed to the Salaf and to no later man however great. He was one of many revivers of the call, not its founder, and the same call was made before him by Ibn Taymiyyah, and before him by Ibn Battah and al-Barbahaari, and before them by Imam Ahmad.")),
        ]),
        ArticleSection("“BUT THE HORN OF SATAN RISES FROM NAJD”", [
            .text("The commonest objection raised against him is a hadith. It is authentic, it is in Saheeh al-Bukhaari, and it says nothing of what is claimed for it."),
            .hadith("bukhari:1037", cite: "Saheeh al-Bukhaari 1037", arabic: 19...51, english: [3...59]),
            .longOnly(.markdown("**First: Najd is not a proper name in this hadith.** **Najd (نَجد)**, from **ن-ج-د**, is any raised ground; its opposite is **Ghawr (غَور)**, low ground, which is why Tihaamah and Makkah within it are called Ghawr. Every land has a Najd, and the word is relative to where the speaker stands. Ibn Hajar (may Allah have mercy on him) says exactly this in Fath al-Baari on this hadith, and quotes al-Khattaabi (d. 388 AH): Najd is in the direction of the east, and for the one in Madinah, its Najd is the desert of Iraq and its regions, for that is the east of the people of Madinah. The Prophet (peace be upon him) was speaking in Madinah.")),
            .shortOnly(.markdown("**First: Najd is not a proper name in this hadith.** **Najd (نَجد)**, from **ن-ج-د**, is any raised ground, and the word is relative to where the speaker stands. Ibn Hajar (may Allah have mercy on him) quotes al-Khattaabi in Fath al-Baari on this hadith: for the one in Madinah, its Najd is the desert of Iraq and its regions, for that is the east of the people of Madinah. The Prophet (peace be upon him) was speaking in Madinah.")),
            .markdown("**Second: he named the direction himself.** The same Companion, Ibn Umar (may Allah be pleased with them), narrates the other half of the hadith, and there is no guessing in it:"),
            .hadith("bukhari:7093", cite: "Saheeh al-Bukhaari 7093", arabic: 30...39, english: [0...26]),
            .longOnly(.hadith("bukhari:3511", cite: "Saheeh al-Bukhaari 3511", arabic: 36...50, english: [0...28])),
            .longOnly(.hadith("muslim:2905d", cite: "Saheeh Muslim 2905", arabic: 31...44, english: [0...23])),
            .longOnly(.text("In another wording he said it while standing at the door of Hafsah (may Allah be pleased with her), pointing his hand toward the east (Saheeh Muslim 2905). The rooms of the wives stood on the eastern side of the mosque, so the gesture, the direction and the words all agree.")),
            .longOnly(.markdown("**Third: the man who received the hadith applied it to Iraq.** Saalim ibn Abdullah ibn Umar (may Allah have mercy on him), the son of the narrator and one of the great jurists of Madinah, counted by some among its seven fuqaha, addressed the people of Iraq with it directly:")),
            .longOnly(.hadith("muslim:2905f", cite: "Saheeh Muslim 2905", arabic: 35...84, english: [0...66])),
            .longOnly(.text("If anyone knew what the hadith meant, it was the student of the Companion who narrated it.")),
            .longOnly(.markdown("**Fourth: the history matches.** The rebellion that ended in the killing of Uthmaan (may Allah be pleased with him) was raised from Egypt and Iraq. The Khawaarij first split off at Harooraa’ near Koofah and Ali (may Allah be pleased with him) fought them at Nahrawaan in Iraq. Al-Husayn (may Allah be pleased with him) was betrayed and killed at Karbala in Iraq by the very people who had written to him. The extremists who deified Ali appeared in Koofah. Ma‘bad al-Juhani began the denial of the decree in Basrah, Waasil ibn Ataa’ began the Mu‘tazilah there, Jahm ibn Safwan came out of Khuraasaan, and the Baatiniyyah and the Qaraamitah rose in Iraq. That is the fitnah the hadith describes, and it came from where he pointed.")),
            .longOnly(.markdown("**Fifth: a place is not a verdict on a man.** The hadith names no person and no century, so applying it to a named man a thousand years later is speaking about the unseen (Quran 17:36, quoted above). And it is not a curse on a people either: about the very tribes of that region the Prophet (peace be upon him) said:")),
            .longOnly(.hadith("bukhari:2543", cite: "Saheeh al-Bukhaari 2543", arabic: 74...78, english: [27...39])),
            .longOnly(.text("The same balance runs the other way. Iraq is where the fitnah began, and Iraq is also where Abu Haneefah, Sufyaan ath-Thawri, Ahmad ibn Hanbal and countless imams of the Sunnah lived and taught, and the east beyond it gave the ummah al-Bukhaari, Muslim, at-Tirmidhi and an-Nasaa’i. The hadith speaks of where trials emerge, not of the worth of a people; no land is condemned and no land is a proof.")),
            .longOnly(.markdown("**Sixth: the argument proves nothing either way.** Makkah held three hundred and sixty idols and produced Abu Jahl, and it produced the Messenger of Allah (peace be upon him). Geography settles nothing. A caller is judged by what he calls to, measured against the Book and the Sunnah, which is the whole method of this article. Read Kitaab at-Tawheed: if what is in it is the tawheed of the Quran, the objection is answered, and if it is not, no hadith about a region was needed to reject it.")),
            .shortOnly(.markdown("**Third: the history matches.** The rebellion that ended in the killing of Uthmaan (may Allah be pleased with him) was raised from Egypt and Iraq, the Khawaarij first split off near Koofah, al-Husayn (may Allah be pleased with him) was killed at Karbala, and the denial of the decree and the Mu‘tazilah began in Basrah. That is the fitnah the hadith describes, and it came from where he pointed.")),
            .shortOnly(.markdown("**Fourth: a place is not a verdict on a man.** The hadith names no person and no century, so applying it to a named man a thousand years later is speaking about the unseen (Quran 17:36, quoted above). Makkah held three hundred and sixty idols and produced Abu Jahl, and it produced the Messenger of Allah (peace be upon him). A caller is judged by what he calls to, measured against the Book and the Sunnah. Read Kitaab at-Tawheed: if what is in it is the tawheed of the Quran, the objection is answered, and if it is not, no hadith about a region was needed to reject it.")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Is Salafiyyah a new sect or group?**"),
            .text("No. A sect is something that split off from the original; Salafiyyah is the original that the sects split off from. Every sect is named after a man or an idea that appeared after the Companions: the Jahmiyyah after Jahm ibn Safwan (d. 128 AH); the Mu‘tazilah after the withdrawal (i‘tizaal) of Waasil ibn Ata from the circle of al-Hasan al-Basri, as ash-Shahrastaani relates in al-Milal wan-Nihal; the Ash‘ariyyah after Abu al-Hasan al-Ash‘ari (may Allah have mercy on him), who himself ended upon the creed of Imam Ahmad, as he declared in al-Ibaanah. Salafiyyah is named after nobody but the first generations, whom Allah praised in the verses quoted above (Quran 9:100, 4:115). The name is old, as its history above shows, and it is a description, not a membership, as Ibn Taymiyyah explained above. Allah forbade being like the sects:"),
            .ayah("3:105"),
            .ayah("6:159"),
            .text("Imam Maalik (may Allah have mercy on him) said that the last of this nation will not be rectified except by what rectified its first (related by al-Qaadi Iyaad in ash-Shifa)."),
            .longOnly(.markdown("**Is “Salafi” the same as “Wahhaabi”?**")),
            .longOnly(.text("“Wahhaabi” is not a name anyone chose for himself; it was coined by opponents for the followers of Shaykh Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him) (d. 1206 AH), whose call and whose own words are set out above. What the label points to is simply Salafiyyah: the tawheed of the Quran and the creed of Imam Ahmad. A Salafi still does not accept it, for two reasons. First, al-Wahhaab, “the Bestower,” is a name of Allah (Quran 38:9), and Abd al-Wahhaab was the Shaykh’s father, not the caller. Second, Salafiyyah is ascribed to the Salaf, not to any later scholar however great; a Salafi honours the Shaykh as one of many who revived the call, not as its founder.")),
            .longOnly(.markdown("**Doesn’t the hadith about Najd refer to him?**")),
            .longOnly(.text("No, and the hadith itself says so, as the section above sets out: the Prophet (peace be upon him) pointed east and named the east (Saheeh al-Bukhaari 3511, Saheeh al-Bukhaari 7093), Ibn Hajar and al-Khattaabi identify the Najd of a speaker in Madinah as the desert of Iraq, the son of the narrator addressed the hadith to the people of Iraq (Saheeh Muslim 2905), and the fitnah of the Khawaarij, Nahrawaan, Karbala, the Qadariyyah and the Mu‘tazilah all came from there. Beyond that, the hadith names no person and no century, and the Quran forbids speaking of what one has no knowledge of (Quran 17:36).")),
            .longOnly(.markdown("**Did Muhammad ibn Abd al-Wahhaab declare other Muslims disbelievers?**")),
            .longOnly(.text("He denied it in his own letters, writing that the charge was the invention of his enemies and that he did not declare a person a disbeliever except where the proof had been established against him (ad-Durar as-Saniyyah, vol. 1). Salafiyyah holds what the Salaf held: takfeer is a ruling of the Sharee‘ah, not a weapon; the ruling is on the deed, and the ruling on a particular person requires that its conditions be met and its impediments removed, which belongs to the scholars. Making it loose is the way of the Khawaarij, whom the Salaf fought; denying that any deed can break Islam is the opposite error of the Murji’ah. The details are on the Kufr page.")),
            .markdown("**Why not just say “Muslim”?**"),
            .text("“Muslim” is the name Allah gave us, and it comes first:"),
            .ayah("22:78", words: 17...23),
            .text("But every sect also says “Muslim.” The Khawaarij who fought Ali, the Jahmiyyah who denied the attributes of Allah, and the Raafidah who curse the Companions all call themselves Muslims. So when the Prophet (peace be upon him) foretold the splitting, he did not say “the saved ones are the Muslims”; he gave a description that separates the truth from the sects:"),
            .hadith("abudawud:4597", cite: "Sunan Abi Daawood 4597; graded hasan by al-Albaani", arabic: 56...83, english: [10...64]),
            .longOnly(.text("When Hudhayfah (may Allah be pleased with him) asked what to do if he lived to see callers at the gates of Hell who were “of our skin and speak our tongue,” the Prophet (peace be upon him) answered with the same word:")),
            .longOnly(.hadith("bukhari:3606", cite: "Saheeh al-Bukhaari 3606, Saheeh Muslim 1847", arabic: 137...140, english: [199...207])),
            .text("And in the narration quoted above he described that group as “what I and my Companions are upon.” “Salafi” is nothing but this description in one word. The Jamaa‘ah is not a matter of numbers. Abdullah ibn Mas‘ood (may Allah be pleased with him) said:"),
            .quote(text: "“The Jamaa‘ah is what agrees with the truth, even if you are alone” (al-Laalakaa’i, Sharh Usool I‘tiqaad Ahl as-Sunnah 160; Ibn al-Qayyim, Ighaathat al-Lahfaan 1/70).", arabic: "الجَمَاعَةُ مَا وَافَقَ الحَقَّ وَإِن كُنتَ وَحدَكَ", dimmed: true),
            .longOnly(.markdown("**Do Salafis reject the scholars or the madhhabs?**")),
            .longOnly(.text("No. Following the scholars is a command of Allah:")),
            .longOnly(.ayah("16:43", words: 8...14)),
            .longOnly(.ayah("4:59")),
            .longOnly(.text("The commentators explained “those in authority” as the scholars and the rulers; both are obeyed in what agrees with Allah and His Messenger, which is why the verse ends by returning every dispute to the two. And the Prophet (peace be upon him) tied the survival of knowledge to the scholars:")),
            .longOnly(.hadith("bukhari:100", cite: "Saheeh al-Bukhaari 100", arabic: 32...60, english: [6...71])),
            .longOnly(.text("The great Salafi scholars were themselves men of the madhhabs: Ibn Qudaamah, Ibn Taymiyyah, Ibn al-Qayyim, Ibn Rajab, Muhammad ibn Abd al-Wahhaab, Ibn Baaz, and Ibn al-Uthaymeen were Hanbalis; adh-Dhahabi and Ibn Katheer were Shaafi‘ees. Ibn Taymiyyah even wrote a treatise, Raf‘ al-Malaam ‘an al-A’immah al-A‘laam, excusing the imams whenever an authentic hadith seems to contradict one of their opinions. What a Salafi refuses is to put any man’s opinion above an authentic text, and that is exactly what the four imams commanded. Imam ash-Shaafi‘i (may Allah have mercy on him) said:")),
            .longOnly(.quote(text: "“If the hadith is authentic, then it is my madhhab” (an-Nawawi, al-Majmoo‘ 1/63).", arabic: "إِذَا صَحَّ الحَدِيثُ فَهُوَ مَذهَبِي", dimmed: true)),
            .longOnly(.text("And Imam Ahmad (may Allah have mercy on him) said:")),
            .longOnly(.quote(text: "“Do not blindly follow me, nor Maalik, nor ash-Shaafi‘i, nor al-Awzaa‘i, nor ath-Thawri; take from where they took” (Ibn al-Qayyim, I‘laam al-Muwaqqi‘een 2/302).", arabic: "لَا تُقَلِّدنِي وَلَا تُقَلِّد مَالِكًا وَلَا الشَّافِعِيَّ وَلَا الأَوزَاعِيَّ وَلَا الثَّورِيَّ، وَخُذ مِن حَيثُ أَخَذُوا", dimmed: true)),
            .longOnly(.text("So a Salafi studies fiqh through the madhhabs, respects their imams, and follows a scholar he trusts; but when the evidence is clear and an opinion contradicts it, the evidence wins, because that is what the imams themselves said.")),
            .longOnly(.markdown("**Is everyone who is not Salafi a disbeliever?**")),
            .longOnly(.text("No. Whoever testifies that none has the right to be worshipped but Allah and that Muhammad is His Messenger, prays our prayer, and faces our qiblah is a Muslim, and his errors and innovations, however serious, do not put him outside Islam unless they reach clear disbelief and the proof has been established against him. The Prophet (peace be upon him) said:")),
            .longOnly(.hadith("bukhari:391", cite: "Saheeh al-Bukhaari 391", arabic: 31...50, english: [4...40])),
            .longOnly(.hadith("bukhari:6103", cite: "Saheeh al-Bukhaari 6103, Saheeh Muslim 60a", arabic: 40...49, english: [4...23])),
            .longOnly(.text("Allah forbade denying the faith of one who shows Islam, and He named the people of the qiblah brothers even when they fight one another:")),
            .longOnly(.ayah("4:94", words: 9...16)),
            .longOnly(.ayah("49:10", words: 0...5)),
            .longOnly(.text("Shaykh al-Islam Ibn Taymiyyah (may Allah have mercy on him), who refuted every sect of his time, wrote:")),
            .longOnly(.quote(text: "“I am among the greatest of people in forbidding that a specific person be charged with disbelief, sin, or disobedience, unless it is known that the proof of the message has been established against him” (Majmoo‘ al-Fataawa 3/229).", arabic: "وَأَنَا مِن أَعظَمِ النَّاسِ نَهيًا عَن أَن يُنسَبَ مُعَيَّنٌ إِلَى تَكفِيرٍ وَتَفسِيقٍ وَمَعصِيَةٍ إِلَّا إِذَا عُلِمَ أَنَّهُ قَد قَامَت عَلَيهِ الحُجَّةُ الرِّسَالِيَّةُ", dimmed: true)),
            .longOnly(.text("A Salafi names the error an error and the innovation an innovation, and still calls its holder his brother, prays for him, and hopes for his guidance. Takfeer of Muslims for sins and errors is the mark of the Khawaarij, not of the Salaf.")),
            .longOnly(.markdown("**Is Salafiyyah about appearance: the beard, the thawb, the garment above the ankles?**")),
            .longOnly(.text("The Sunnah is followed in everything, and these are part of it. The Prophet (peace be upon him) said:")),
            .longOnly(.hadith("bukhari:5892", cite: "Saheeh al-Bukhaari 5892", arabic: 28...33, english: [7...22])),
            .longOnly(.hadith("bukhari:5787", cite: "Saheeh al-Bukhaari 5787", arabic: 27...34, english: [4...17])),
            .longOnly(.text("But they are branches, not the root. The first thing the Prophet (peace be upon him) told Mu‘aadh to call to was tawheed, not clothing (Saheeh al-Bukhaari 1395).")),
            .longOnly(.hadith("bukhari:1395", cite: "Saheeh al-Bukhaari 1395, Saheeh Muslim 19a", arabic: 34...90, english: [0...98])),
            .longOnly(.text("A man with a beard and an innovated creed is far from the Salaf, and a man who has just accepted Islam and knows nothing yet of these matters is nearer to them than he. The core of Salafiyyah is the tawheed of Allah and ittibaa‘ (اِتِّبَاع, from ت-ب-ع, to follow) of His Messenger; appearance follows from that and never replaces it:")),
            .longOnly(.ayah("49:13", words: 11...15)),
            .longOnly(.hadith("muslim:2564c", cite: "Saheeh Muslim 2564", arabic: 28...39, english: [0...20])),
            .longOnly(.markdown("**Is Salafiyyah the way of the Khawaarij or of extremists?**")),
            .longOnly(.text("It is their opposite. The Khawaarij declare Muslims disbelievers for sins and rebel against the rulers; Salafiyyah forbids both. The Prophet (peace be upon him) described the Khawaarij:")),
            .longOnly(.hadith("bukhari:6930", cite: "Saheeh al-Bukhaari 6930, Saheeh Muslim 1066", arabic: 63...88, english: [63...110])),
            .longOnly(.text("Ibn Umar (may Allah be pleased with them both) considered them the worst of Allah’s creation, and explained their method in words al-Bukhaari placed at the head of his chapter on them:")),
            .longOnly(.quote(text: "“They went to verses that were revealed about the disbelievers and applied them to the believers” (Saheeh al-Bukhaari, Kitaab Istitaabat al-Murtaddeen, chapter on killing the Khawaarij after the proof is established against them).", arabic: "إِنَّهُمُ انطَلَقُوا إِلَى آيَاتٍ نَزَلَت فِي الكُفَّارِ فَجَعَلُوهَا عَلَى المُؤمِنِينَ", dimmed: true)),
            .longOnly(.text("Salafiyyah takes the other road: patience with the rulers, advice without rebellion, and no takfeer without proof. The Prophet (peace be upon him) said:")),
            .longOnly(.hadith("bukhari:7053", cite: "Saheeh al-Bukhaari 7053, Saheeh Muslim 1849", arabic: 22...36, english: [4...44])),
            .longOnly(.hadith("muslim:1855a", cite: "Saheeh Muslim 1855", arabic: 56...69, english: [50...76])),
            .longOnly(.hadith("bukhari:7055", cite: "Saheeh al-Bukhaari 7055, Saheeh Muslim 1709", arabic: 65...79, english: [122...146])),
            .longOnly(.text("When the Khawaarij raised their slogan “no judgement but Allah’s” against Ali (may Allah be pleased with him), he said: a word of truth by which falsehood is intended (Saheeh Muslim 1066). That is the Salafi reading of every extremist who quotes the Quran: the verse is true, the application is false.")),
            .longOnly(.markdown("**How should a Salafi treat Muslims who differ with him?**")),
            .longOnly(.text("With justice, gentleness, and brotherhood, and with the truth stated plainly. Allah commanded:")),
            .longOnly(.ayah("5:8", words: 8...18)),
            .longOnly(.ayah("16:125", words: 0...10)),
            .longOnly(.ayah("49:11", words: 0...12)),
            .longOnly(.text("The verse before it, quoted above, calls the believers brothers (Quran 49:10), and the Prophet (peace be upon him) said:")),
            .longOnly(.hadith("muslim:2699a", cite: "Saheeh Muslim 2699", arabic: 78...87, english: [69...88])),
            .longOnly(.hadith("muslim:2586a", cite: "Saheeh Muslim 2586", arabic: 27...44, english: [0...30])),
            .longOnly(.text("Disagreement in a ruling of fiqh is not disagreement in the religion; the Companions differed in such matters and stayed brothers. Where a Muslim has fallen into an innovation, the Salafi way is to clarify the evidence, to hope for him, and never to lie about him or wrong him, because a man who wrongs his opponent has himself left the Sunnah.")),
            .longOnly(.markdown("**Does Salafiyyah reject reason?**")),
            .longOnly(.text("No. The Quran is full of commands to think, and it counts the people of understanding among the best of the believers:")),
            .longOnly(.ayah("3:190")),
            .longOnly(.ayah("3:191", words: 0...11)),
            .longOnly(.ayah("47:24")),
            .longOnly(.text("What Salafiyyah rejects is putting reason above revelation. Reason is the tool by which a person recognises that the Quran is from Allah and that Muhammad (peace be upon him) is His Messenger; once it has established that, it submits to what they say, because the One who revealed knows and it does not. Umar (may Allah be pleased with him) showed the balance at the Black Stone:")),
            .longOnly(.hadith("bukhari:1597", cite: "Saheeh al-Bukhaari 1597", arabic: 28...46, english: [11...42])),
            .longOnly(.text("His reason told him a stone does nothing; his reason also told him that the Prophet (peace be upon him) is followed. Ibn Taymiyyah devoted his book Daar’ Ta‘aarud al-Aql wan-Naql to one principle: sound reason never contradicts authentic revelation, so wherever the two seem to clash, either the report is not authentic or the reasoning is not sound.")),
            .longOnly(.markdown("**Why call to Salafiyyah at all? Why not leave people as they are?**")),
            .longOnly(.text("Because the Prophet (peace be upon him) commanded it precisely for a time of differing:")),
            .longOnly(.hadith("tirmidhi:2676", cite: "Jaami‘ at-Tirmidhi 2676; graded saheeh by al-Albaani", arabic: 61...80, english: [47...88])),
            .longOnly(.text("And then, in the narration quoted above, “hold fast to my Sunnah and the Sunnah of the rightly guided caliphs” (Sunan Abi Daawood 4607). Calling to Salafiyyah is calling to that: not to a group, but to the Quran and the Sunnah as the Companions carried them. Allah made the call an obligation on the nation and an honour for the caller:")),
            .longOnly(.ayah("3:104")),
            .longOnly(.ayah("41:33")),
            .longOnly(.text("And the Prophet (peace be upon him) said:")),
            .longOnly(.hadith("muslim:2674", cite: "Saheeh Muslim 2674", arabic: 34...51, english: [0...29])),
            .longOnly(.text("The Prophet (peace be upon him) called with insight, “I and those who follow me,” as the verse quoted above says (Quran 12:108). Whoever follows him carries the same call.")),
            .longOnly(.markdown("**Is it arrogance to say “I am Salafi”?**")),
            .longOnly(.text("Not when it is said as the Salaf said it: as a statement of whom one follows and a commitment to be held to. The Prophet (peace be upon him) was commanded to say “I and those who follow me” (Quran 12:108), and the caller to Allah says “Indeed, I am of the Muslims” (Quran 41:33); neither is a boast. Ibn Taymiyyah, quoted above, said it is obligatory to accept the ascription from whoever makes it. What is forbidden is claiming purity for oneself:")),
            .longOnly(.ayah("53:32", words: 24...30)),
            .longOnly(.text("So the name is a claim that deeds must match. Whoever takes pride in the label while opposing the way of the Salaf in creed, worship, or manners has the name without the thing; and whoever follows their way has the thing, whatever he is called.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Salafiyyah is the original Islam: the Quran and the Sunnah as the Companions understood them, the Athari creed, and nothing added. The articles that follow lay out its foundations and answer the paths that departed from it."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Salaf (سَلَف)**: from the root س-ل-ف, “salafa,” to go before, to precede. Whatever has passed is “salaf,” and a man’s forefathers are his “aslaaf.” The Quran uses the word for people who went ahead and became an example for those who came after them:"),
            .ayah("43:56"),
            .text("The Prophet (peace be upon him) used the same word for himself when he told Faatimah (may Allah be pleased with her) that his death was near (Saheeh al-Bukhaari 6285, quoted above under The Name “Salafi”). In the religion, “the Salaf” are the Righteous Predecessors named above: the Companions, the Taabi‘oon, and their followers, together with every scholar after them who kept to their path."),
            .markdown("**Salafi (سَلَفِي)** and **Salafiyyah (السَّلَفِيَّة)**: the ascription (نِسبَة) to the Salaf, exactly as “Madani” is the ascription to Madinah and “Hanbali” the ascription to Imam Ahmad ibn Hanbal. It names a methodology, not a party: taking the Quran and the Sunnah with the understanding of the first generations. Nobody founded it, nobody owns it, and nobody joins it by registering; a person is Salafi to the extent that he actually follows the Salaf. That is why Ibn Taymiyyah said there is no blame on one who manifests the way of the Salaf and ascribes himself to it, for their way can be nothing but the truth (Majmoo‘ al-Fataawa 4/149, quoted earlier in this article)."),
            .markdown("**Khalaf (خَلَف)**: from the root خ-ل-ف, to come after, to succeed. The Khalaf are the later generations, and in the books of creed the word usually means those later scholars who left the plain method of the Salaf for the methods of kalaam. The saying “the way of the Salaf is safer, but the way of the Khalaf is more knowledgeable and wiser” is the saying Shaykh al-Islam Ibn Taymiyyah (may Allah have mercy on him) refuted in al-Fatwa al-Hamawiyyah: whoever is safest is also the most knowing and the wisest, because safety in the religion comes only from knowledge. The Quran uses the related word “khalf” for successors who went astray:"),
            .ayah("19:59"),
            .markdown("**Ahl as-Sunnah wal-Jamaa‘ah (أَهل السُّنَّة وَالجَمَاعَة)**: “the People of the Sunnah and the Congregation.” Sunnah is the way of the Prophet (peace be upon him); Jamaa‘ah, from ج-م-ع, to gather, is the body of the Companions and whoever gathers upon what they were upon. The name is taken from the Prophet’s own description of the one group that is saved:"),
            .hadith("ibnmajah:3993", cite: "Sunan Ibn Maajah 3993; graded saheeh by al-Albaani", arabic: 29...50, english: [0...29]),
            .markdown("**Ahl al-Hadith (أَهل الحَدِيث)** and **Ahl al-Athar (أَهل الأَثَر)**: “the People of Hadith” and “the People of Narration.” Athar, from أ-ث-ر, is a trace or footprint, and so a transmitted report from the Prophet (peace be upon him) or from the Salaf. These are the names the early imams used for those who built their religion on transmitted reports rather than on opinion. When at-Tirmidhi recorded the hadith of the aided group, he related that his teacher Imam al-Bukhaari said, from his own teacher Ali ibn al-Madeeni (may Allah have mercy on them both):"),
            .quote(text: "“They are the people of hadith” (Jaami‘ at-Tirmidhi, the words of al-Bukhaari from Ali ibn al-Madeeni recorded after hadiths 2192 and 2229).", arabic: "هُم أَصحَابُ الحَدِيثِ", dimmed: true),
            .text("Imam Ahmad (may Allah have mercy on him) said the same: if the aided group is not the people of hadith, he did not know who they are (al-Haakim, Ma‘rifat Uloom al-Hadith; al-Khateeb al-Baghdaadi, Sharaf Ashaab al-Hadith)."),
            .markdown("**At-Taa’ifah al-Mansoorah (الطَّائِفَة المَنصُورَة)**: “the Aided Group,” from taa’ifah, a group, and nasr, help and victory. The Prophet (peace be upon him) said:"),
            .hadith("bukhari:3641", cite: "Saheeh al-Bukhaari 3641, Saheeh Muslim 1920", arabic: 26...47, english: [6...53]),
            .markdown("**Al-Firqah an-Naajiyah (الفِرقَة النَّاجِيَة)**: “the Saved Sect,” from faraqa, to split apart, and naja, to be saved. It is the one group of the seventy-three that the Prophet (peace be upon him) called the Jamaa‘ah in the narration quoted above. Abu Hurayrah (may Allah be pleased with him) narrated the prophecy of the splitting:"),
            .hadith("abudawud:4596", cite: "Sunan Abi Daawood 4596; graded hasan saheeh by al-Albaani", arabic: 26...47, english: [4...35]),
            .markdown("**Al-Ghurabaa’ (الغُرَبَاء)**: “the Strangers,” plural of ghareeb, one who is far from home and unfamiliar to those around him. The Prophet (peace be upon him) foretold that those who hold to the original Islam would one day look like strangers even among the Muslims:"),
            .hadith("muslim:145", cite: "Saheeh Muslim 145", arabic: 39...47, english: [0...21]),
            .markdown("**Manhaj (مَنهَج)**: from ن-ه-ج; a “nahj” is a clear, open road. In the religion the manhaj is the method by which a person receives, understands, and practises Islam: where he takes his creed from, how he reads the texts, how he treats rulers, scholars, and opponents. The Salafi manhaj is the Companions’ method. Allah used the word for the path He laid down:"),
            .ayah("5:48", words: 24...28),
            .markdown("**Ittibaa‘ (اتِّبَاع)**: following, from ت-ب-ع, to walk in someone’s footsteps: accepting a matter of religion because the Prophet (peace be upon him) said it or did it, together with its evidence. Its opposite is ibtidaa‘, inventing. Allah made ittibaa‘ the proof of love for Him:"),
            .ayah("3:31"),
            .markdown("**“Wahhaabi” (وَهَّابِي)**: a label coined by opponents for the followers of Shaykh Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him) (d. 1206 AH), the scholar of Najd who called the people back to the tawheed of the Quran and to the creed of Imam Ahmad. He founded no school and named nothing after himself, and the name is not even his own: Abd al-Wahhaab was his father, who was not the caller. Al-Wahhaab, “the Bestower,” is one of the names of Allah:"),
            .ayah("38:9"),
            .markdown("**Hizbiyyah (حِزبِيَّة)**: partisanship, from hizb, a party or faction: loyalty and enmity for the sake of a group, its leader, or its label instead of for the sake of the truth. Allah counted it among the marks of those who divided their religion:"),
            .ayah("30:32"),
            .ayah("23:53"),
            .text("The only party a Muslim belongs to is the one Allah named:"),
            .ayah("58:22", words: 37...50),
            .markdown("**Bid‘ah (بِدعَة)**: innovation, from ب-د-ع, to bring something into being with no prior example; Allah is al-Badee‘, “Originator of the heavens and the earth” (Quran 2:117)."),
            .ayah("2:117", words: 0...2),
            .markdown("In the religion, ash-Shaatibi (may Allah have mercy on him) defined it in al-I‘tisaam as an invented way in the religion that imitates the legislated way and is followed in order to draw near to Allah. The Prophet (peace be upon him) said:"),
            .hadith("bukhari:2697", cite: "Saheeh al-Bukhaari 2697, Saheeh Muslim 1718", arabic: 29...38, english: [4...22]),
            .markdown("**Sunnah (سُنَّة)**: from س-ن-ن; a way or established practice. In the language it can be good or bad, which is why the Prophet (peace be upon him) spoke of “whoever sets a good sunnah in Islam” and “whoever sets a bad sunnah” (Saheeh Muslim 1017)."),
            .hadith("muslim:1017a", cite: "Saheeh Muslim 1017", arabic: 179...220, english: [277...346]),
            .markdown("In the religion it is his way: his sayings, actions, and approvals, and, in the books of creed, the whole of Islam as he left it, the opposite of bid‘ah. He said of those who wanted a worship other than his:"),
            .hadith("bukhari:5063", cite: "Saheeh al-Bukhaari 5063", arabic: 119...124, english: [143...161]),
            .markdown("**Al-Quroon ath-Thalaathah (القُرُون الثَّلَاثَة)**: “the three generations.” A qarn is the people of one age. The three are the Companions, the Taabi‘oon, and the Atbaa‘ at-Taabi‘een, whom the Prophet (peace be upon him) called the best of people in the hadith quoted above (Saheeh al-Bukhaari 2652). Their era is the reference point of Salafiyyah: whatever was not religion then is not religion now."),
        ]),
    ]
}

struct QuranSunnahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Quran and the authentic Sunnah are the two sources of Islam; both are revelation, both are binding, and everything else is judged by them.")
                }

                Section(header: ArticleHeader("THE QURAN")) {
                    ArticleParagraph(articleMarkdown: "The **Quran (القُرآن)** is the speech of Allah, revealed to Muhammad (peace be upon him) through Jibreel, preserved letter by letter, and protected by Allah Himself:")
                    ScriptureQuote(quran: "15:9")

                    ScriptureQuote(quran: "4:82")

                    ArticleParagraph(verbatim: "It is the first source, the criterion, and the thing every Muslim is commanded to follow:")
                    ScriptureQuote(quran: "7:3")
                }

                Section(header: ArticleHeader("THE SUNNAH")) {
                    ArticleParagraph(articleMarkdown: "The **Sunnah (السُّنَّة)** is the way of the Prophet (peace be upon him): his sayings, actions, and approvals, transmitted in the hadith. It is revelation too, for he did not speak the religion from himself:")
                    ScriptureQuote(quran: "53:3-4")

                    ArticleParagraph(verbatim: "Obeying him is obeying Allah, and his rulings are binding exactly like the Quran’s:")
                    ScriptureQuote(quran: "4:80", words: 0...5)

                    ScriptureQuote(quran: "59:7", words: 23...36)

                    ScriptureQuote(quran: "4:65")

                    ScriptureQuote(quran: "33:36", words: 0...15)

                    ArticleParagraph(verbatim: "The Sunnah explains the Quran. The Quran commands prayer, zakaah, and Hajj; the Sunnah shows how to pray, how much to pay, and what to do at each station. Allah gave the Prophet (peace be upon him) that role:")
                    ScriptureQuote(quran: "16:44", words: 2...9)

                    ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:7280", cite: "Saheeh al-Bukhaari 7280", arabic: 26...49, english: 4...42)
                }

                Section(header: ArticleHeader("THE TWO ARE NEVER SEPARATED")) {
                    ArticleParagraph(verbatim: "Anyone who says “the Quran is enough” has rejected the Quran, because the Quran commands obedience to the Messenger in dozens of verses. And anyone who accepts hadith but reinterprets the Quran by opinion has left the Sunnah, because the Sunnah is the explanation of the Quran. The Prophet (peace be upon him) foretold both errors:")
                    ScriptureQuote(hadith: "bukhari:7288", cite: "Saheeh al-Bukhaari 7288, Saheeh Muslim 1337", arabic: 21...44, english: 4...58)

                    ArticleParagraph(verbatim: "Allah tied the answer to every dispute to the two together:")
                    ScriptureQuote(quran: "4:59", words: 0...17)

                    ArticleParagraph(verbatim: "Referring to Allah is referring to His Book, and referring to the Messenger after his passing is referring to his Sunnah. Whoever has these two, understood as the Companions understood them, has the whole religion.")
                }

                Section(header: ArticleHeader("HOW A HADITH IS TRUSTED")) {
                    ArticleParagraph(articleMarkdown: "The Sunnah was preserved through chains of narrators (**isnaad**) examined man by man. A hadith is **saheeh** (authentic) when every narrator is trustworthy and precise, the chain is connected, and the text has no hidden defect or contradiction of stronger reports; **hasan** (good) when slightly below that; **da‘eef** (weak) when a condition fails; and **mawdoo‘** (fabricated) when it is a lie. Only saheeh and hasan reports are evidence. Every hadith quoted in these pages is from those two grades, with the collection and number given so that it can be checked.")

                    ScriptureQuote(hadith: "bukhari:108", cite: "Saheeh al-Bukhaari 108", arabic: 27...34, english: 20...35)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is the Sunnah revelation?**")
                        ArticleParagraph(verbatim: "Yes. The verse quoted above says the Prophet (peace be upon him) does not speak from inclination (Quran 53:3-4), and he said so himself:")
                        ScriptureQuote(hadith: "abudawud:4604", cite: "Sunan Abi Daawood 4604; graded saheeh by al-Albaani", arabic: 37...42, english: 4...14)

                        ArticleParagraph(verbatim: "The Quran calls this second revelation “wisdom” and mentions it beside the Book:")
                        ScriptureQuote(quran: "4:113", words: 18...27)

                        ArticleParagraph(verbatim: "Imam ash-Shaafi‘i (may Allah have mercy on him) wrote in ar-Risaalah that the people of knowledge of the Quran whom he trusted said the “wisdom” here is the Sunnah of the Messenger of Allah; the same pairing of “the Book and wisdom” runs through the Quran (Quran 2:129, 33:34, 62:2). The difference between the two is in the wording, not in the authority: the Quran is the very words of Allah, recited and inimitable; the Sunnah is the meaning from Allah in the words of the Prophet (peace be upon him).")
                        ScriptureQuote(quran: "2:129", words: 8...10)
                        ScriptureQuote(quran: "33:34", words: 0...8)
                        ScriptureQuote(quran: "62:2", words: 11...13)

                        ArticleParagraph(articleMarkdown: "**Can a Muslim follow the Quran alone?**")
                        ArticleParagraph(verbatim: "No, because the Quran itself commands obedience to the Messenger, as the verses quoted above show (Quran 4:80, 59:7, 4:65, 16:44). Whoever drops the Sunnah has disobeyed the Quran. The Prophet (peace be upon him) foretold the very words such a person would use:")
                        ScriptureQuote(hadith: "abudawud:4604", cite: "Sunan Abi Daawood 4604; graded saheeh by al-Albaani", arabic: 44...64, english: 16...55)

                        ArticleParagraph(verbatim: "A woman from Banu Asad once told Abdullah ibn Mas‘ood (may Allah be pleased with him) that she had read the whole Quran and not found in it the curse he narrated. The exchange is the Companions’ answer to the whole idea:")
                        ScriptureQuote(hadith: "bukhari:4886", cite: "Saheeh al-Bukhaari 4886, Saheeh Muslim 2125", arabic: 45...88, english: 77...150)

                        ArticleParagraph(verbatim: "And in practice it cannot be done. The Quran commands prayer but does not give the number of its units, the words of its bowing and prostration, or its times in detail; it commands zakaah but not the amounts and thresholds; it commands Hajj but not its rites station by station. All of that is in the Sunnah, and the Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:631", cite: "Saheeh al-Bukhaari 631", arabic: 73...76, english: 98...104)
                        ScriptureQuote(hadith: "muslim:1297", cite: "Saheeh Muslim 1297", arabic: 43...53, english: 20...43)

                        ArticleParagraph(verbatim: "A “Quran-only” prayer does not exist.")

                        ArticleParagraph(articleMarkdown: "**How do we know a hadith is authentic?**")
                        ArticleParagraph(verbatim: "By the isnaad, the chain of narrators, examined man by man for honesty and precision, and by comparing the text with what the other reliable narrators transmitted. The Salaf treated this as part of the religion itself. Muhammad ibn Seereen (may Allah have mercy on him), the student of the Companions, said:")
                        ScriptureQuote(hadith: "muslim:26", cite: "Muqaddimah of Saheeh Muslim 26", arabic: 29...36, english: 62...75)

                        ArticleParagraph(verbatim: "And Abdullah ibn al-Mubaarak (may Allah have mercy on him) said:")
                        ScriptureQuote(hadith: "muslim:#7399", cite: "Muqaddimah of Saheeh Muslim 32", arabic: 24...33, english: 0...23)

                        ArticleParagraph(verbatim: "The result is the grading described above: saheeh, hasan, da‘eef, mawdoo‘. It is not guesswork; the biographies of many thousands of narrators, with their teachers, students, dates, and travels, were recorded and cross-checked, and a narrator found to lie in hadith was rejected.")

                        ArticleParagraph(articleMarkdown: "**Is a hadith narrated by a single chain (aahaad) accepted in creed?**")
                        ArticleParagraph(verbatim: "Yes, when it is authentic. The Prophet (peace be upon him) sent single Companions to teach entire peoples their creed, and the greatest matter of creed first of all:")
                        ScriptureQuote(hadith: "bukhari:1395", cite: "Saheeh al-Bukhaari 1395, Saheeh Muslim 19a", arabic: 28...56, english: 9...28)

                        ArticleParagraph(verbatim: "The Companions acted on a single man’s report in the middle of the prayer:")
                        ScriptureQuote(hadith: "bukhari:403", cite: "Saheeh al-Bukhaari 403", arabic: 21...55, english: 0...58)

                        ArticleParagraph(verbatim: "Al-Bukhaari gave this its own book in his Saheeh, Kitaab Akhbaar al-Aahaad, on accepting the report of a single truthful narrator in the adhan, the prayer, fasting, inheritance, and rulings. The Companions did not divide the Prophet’s words into what binds in action and what may be doubted in belief; whatever was established from him was believed and acted upon. That is the way of the Salaf, and the later distinction is an innovation of the people of kalaam.")

                        ArticleParagraph(articleMarkdown: "**Can reason or taste override an authentic hadith?**")
                        ArticleParagraph(verbatim: "No. The verses quoted above leave a believer no choice once Allah and His Messenger have decided (Quran 33:36, 4:65), and Allah warned:")
                        ScriptureQuote(quran: "24:63", words: 15...26)

                        ArticleParagraph(verbatim: "Imam ash-Shaafi‘i (may Allah have mercy on him) said:")
                        ScriptureQuote(text: "“The Muslims are agreed that whoever has a Sunnah of the Messenger of Allah (peace be upon him) made clear to him is not permitted to leave it for the saying of anyone” (ash-Shaafi‘i, as quoted by Ibn al-Qayyim, I‘laam al-Muwaqqi‘een 2/263).", arabic: "أَجمَعَ المُسلِمُونَ عَلَى أَنَّ مَنِ استَبَانَ لَهُ سُنَّةٌ عَن رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ لَم يَحِلَّ لَهُ أَن يَدَعَهَا لِقَولِ أَحَدٍ", dimmed: true)

                        ArticleParagraph(verbatim: "And Imam Ahmad (may Allah have mercy on him) said:")
                        ScriptureQuote(text: "“Whoever rejects a hadith of the Messenger of Allah (peace be upon him) is on the brink of destruction” (Ibn al-Jawzi, Manaaqib al-Imam Ahmad).", arabic: "مَن رَدَّ حَدِيثَ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ فَهُوَ عَلَى شَفَا هَلَكَةٍ", dimmed: true)

                        ArticleParagraph(verbatim: "A hadith may be examined for authenticity, and its meaning may be understood in the light of other texts; that is scholarship. But “it does not suit my reason” or “it does not suit my taste” is not an argument against revelation; it is a description of the speaker.")

                        ArticleParagraph(articleMarkdown: "**Is the Quran preserved letter by letter?**")
                        ArticleParagraph(verbatim: "Yes, as Allah promised in the verse quoted above (Quran 15:9). It was memorised by the Companions in the Prophet’s lifetime, written down as it came, and reviewed with Jibreel every year:")
                        ScriptureQuote(hadith: "bukhari:4998", cite: "Saheeh al-Bukhaari 4998", arabic: 17...35, english: 0...27)

                        ArticleParagraph(verbatim: "After the Prophet’s death, Abu Bakr had it collected from the written pieces and the memories of the huffaaz, with Zayd ibn Thaabit (may Allah be pleased with them) in charge:")
                        ScriptureQuote(hadith: "bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 184...191, english: 303...332)

                        ArticleParagraph(verbatim: "Uthmaan (may Allah be pleased with him) then had that text copied and sent a copy to every region (Saheeh al-Bukhaari 4987), and every Quran in the world today is that text.")
                        ScriptureQuote(hadith: "bukhari:4987", cite: "Saheeh al-Bukhaari 4987", arabic: 71...142, english: 109...217)
                        ArticleParagraph(verbatim: "The variant readings (qiraa’aat) are not corruption; they are readings drawn from the seven modes (ahruf) in which it was revealed, each carried by unbroken chains back to the Prophet (peace be upon him):")
                        ScriptureQuote(hadith: "bukhari:4991", cite: "Saheeh al-Bukhaari 4991", arabic: 39...52, english: 4...48)

                        ArticleParagraph(verbatim: "When Umar heard Hishaam ibn Hakeem (may Allah be pleased with them) recite Surat al-Furqaan differently from how he had learnt it, the Prophet (peace be upon him) heard both and said of each, “thus it was revealed,” and told them the Quran was revealed upon seven modes (Saheeh Muslim 818).")
                        ScriptureQuote(hadith: "muslim:818a", cite: "Saheeh Muslim 818, Saheeh al-Bukhaari 2419", arabic: 27...133, english: 0...171)

                        ArticleParagraph(articleMarkdown: "**What is abrogation (naskh)?**")
                        ArticleParagraph(verbatim: "Abrogation is Allah replacing one ruling with a later one, by His knowledge and wisdom, the way a physician changes the dose as the patient grows. He announced it in the Quran:")
                        ScriptureQuote(quran: "2:106")

                        ArticleParagraph(verbatim: "The qiblah was changed from Jerusalem to the Ka‘bah (Quran 2:144).")
                        ScriptureQuote(quran: "2:144", words: 9...13)
                        ArticleParagraph(verbatim: "And the Prophet (peace be upon him) abrogated some of his own earlier rulings:")
                        ScriptureQuote(hadith: "muslim:977a", cite: "Saheeh Muslim 977", arabic: 55...59, english: 0...11)

                        ArticleParagraph(verbatim: "Three rules keep it in its place. Only revelation abrogates revelation: no scholar, ruler, or age abrogates anything. Abrogation is known only by a text or by the report of the Companions, never by someone deciding that a ruling is out of date. And abrogation ended with the Prophet’s death, because revelation ended with it.")

                        ArticleParagraph(articleMarkdown: "**What is a hadith qudsi, and how does it differ from the Quran?**")
                        ArticleParagraph(articleMarkdown: "A **hadith qudsi (حَدِيث قُدسِي)** is a report in which the Prophet (peace be upon him) relates words from his Lord, such as:")
                        ScriptureQuote(hadith: "muslim:2577a", cite: "Saheeh Muslim 2577", arabic: 49...60, english: 0...21)

                        ArticleParagraph(verbatim: "Its meaning is from Allah and it is attributed to Him, but it is not Quran. The Quran is the very words of Allah, transmitted by mass narration with no doubt in a single letter, recited in prayer, a miracle in its wording, and, in the view of the four madhhabs, not to be touched without purification. A hadith qudsi is transmitted like any other hadith, through an isnaad that is graded saheeh, hasan, or weak; it is not recited in prayer and carries no claim of inimitable wording. So the Quran is in a class by itself, and a hadith qudsi is in the class of the Sunnah.")

                        ArticleParagraph(articleMarkdown: "**What is the punishment for fabricating hadith?**")
                        ArticleParagraph(verbatim: "A seat in the Fire. The threat quoted above, that whoever lies upon the Prophet (peace be upon him) intentionally should take his seat in the Fire (Saheeh al-Bukhaari 108), was narrated by so many Companions that the scholars count it mutawaatir. And he (peace be upon him) extended it to whoever passes a lie on:")
                        ScriptureQuote(hadith: "ibnmajah:38", cite: "Sunan Ibn Maajah 38; graded saheeh by al-Albaani", arabic: 35...45, english: 4...22)

                        ArticleParagraph(verbatim: "Lying about him is worse than lying about anyone else, because it is a lie about the religion of Allah that misleads everyone who hears it. This is why the scholars of hadith named the fabricators openly in the books of weak narrators, and why the Salaf considered exposing a liar in hadith an act of sincere advice to the Muslims, not backbiting.")

                        ArticleParagraph(articleMarkdown: "**Do the grades (saheeh, hasan, da‘eef, mawdoo‘) mean the Sunnah is uncertain?**")
                        ArticleParagraph(verbatim: "No; they mean the opposite. The grades exist because the Muslims refused to accept anything about their Prophet without proof. Allah commanded that very care:")
                        ScriptureQuote(quran: "49:6", words: 0...7)

                        ArticleParagraph(verbatim: "Muhammad ibn Seereen (may Allah have mercy on him) described how the isnaad became the standard:")
                        ScriptureQuote(hadith: "muslim:27", cite: "Muqaddimah of Saheeh Muslim 27", arabic: 17...41, english: 0...44)

                        ArticleParagraph(verbatim: "No other nation can trace the words of its prophet man by man back to his mouth; Ibn Hazm wrote that the transmission of a trustworthy narrator from a trustworthy narrator, connected all the way to the Prophet (peace be upon him), is something Allah gave to the Muslims alone among all the religions (al-Fisal), and as-Suyooti gathered such statements in Tadreeb ar-Raawi. A weak hadith is not “the Sunnah being uncertain”; it is the Sunnah being guarded, a report that failed the test and was set aside so that what passed could be trusted completely. The authentic Sunnah, preserved through this science, is as certain as the religion itself.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is the Sunnah revelation?**")
                        ArticleParagraph(verbatim: "Yes. The verse quoted above says the Prophet (peace be upon him) does not speak from inclination (Quran 53:3-4), and he said so himself:")
                        ScriptureQuote(hadith: "abudawud:4604", cite: "Sunan Abi Daawood 4604; graded saheeh by al-Albaani", arabic: 37...42, english: 4...14)

                        ArticleParagraph(articleMarkdown: "**Can a Muslim follow the Quran alone?**")
                        ArticleParagraph(verbatim: "No, because the Quran itself commands obedience to the Messenger, as the verses quoted above show (Quran 4:80, 59:7, 4:65, 16:44). Whoever drops the Sunnah has disobeyed the Quran. The Prophet (peace be upon him) foretold the very words such a person would use:")
                        ScriptureQuote(hadith: "abudawud:4604", cite: "Sunan Abi Daawood 4604; graded saheeh by al-Albaani", arabic: 44...64, english: 16...55)

                        ArticleParagraph(verbatim: "And in practice it cannot be done. The Quran commands prayer but does not give the number of its units, the words of its bowing and prostration, or its times in detail; it commands zakaah but not the amounts and thresholds; it commands Hajj but not its rites station by station. All of that is in the Sunnah, and the Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:631", cite: "Saheeh al-Bukhaari 631", arabic: 73...76, english: 98...104)
                        ScriptureQuote(hadith: "muslim:1297", cite: "Saheeh Muslim 1297", arabic: 43...53, english: 20...43)

                        ArticleParagraph(verbatim: "A “Quran-only” prayer does not exist.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Two sources, both revelation, both binding: the Book of Allah and the Sunnah of His Messenger. Whatever agrees with them is accepted, and whatever contradicts them is rejected, whoever said it.")
                }

                ArticleSourcesSection(article: "QuranSunnahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Quran and Sunnah")
        .englishArticle().selectableArticleList(article: "QuranSunnahView")
    }
}

struct ShirkView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ShirkView")
            }
            .themedListRowBackground()
        }
        .navigationTitle(AppLanguage.article("Shirk"))
        .englishArticle().selectableArticleList(article: "ShirkView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: shirk is giving any of Allah's rights to other than Him. It is the one sin Allah does not forgive if a person dies upon it, and the opposite of the tawheed every prophet called to."),
        ]),
        ArticleSection("WHAT IS SHIRK?", [
            .markdown("**Shirk (شِرك)** means “association”: making a partner (**shareek**) for Allah in what belongs only to Him. Its opposite is **tawheed (تَوحِيد)**, singling Allah out. Tawheed has three parts, and shirk can enter each:"),
            .markdown("• **In lordship (ruboobiyyah)**: believing that anyone besides Allah creates, provides, or controls the universe."),
            .markdown("• **In worship (uloohiyyah)**: directing any act of worship to other than Allah: supplication, sacrifice, vows, prostration, fear, hope, reliance, seeking help from the dead or absent in what only Allah can do."),
            .markdown("• **In names and attributes**: giving creation what belongs to Allah alone, such as knowledge of the unseen, or giving Allah the qualities of creation."),
            .text("The pagans of Makkah already believed Allah was the Creator; their shirk was in worship, praying to others so that they would bring them near to Him:"),
            .ayah("39:3", words: 4...32),
            .ayah("31:25"),
        ]),
        ArticleSection("THE GRAVEST OF ALL SINS", [
            .ayah("4:48"),
            .ayah("31:13"),
            .ayah("5:72", words: 18...32),
            .ayah("39:65"),
            .text("Ibn Mas‘ood (may Allah be pleased with him) asked the Prophet (peace be upon him) which sin is the greatest in the sight of Allah. He said:"),
            .hadith("bukhari:4477", cite: "Saheeh al-Bukhaari 4477", arabic: 33...38, english: [16...28]),
            .hadith("bukhari:4497", cite: "Saheeh al-Bukhaari 4497", arabic: 30...39, english: [14...31]),
            .text("And Jaabir (may Allah be pleased with him) narrated:"),
            .hadith("muslim:93a", cite: "Saheeh Muslim 93", arabic: 36...50, english: [12...37]),
        ]),
        ArticleSection("THE RIGHT OF ALLAH", [
            .text("Mu‘aadh ibn Jabal (may Allah be pleased with him) was riding behind the Prophet (peace be upon him) when he asked him:"),
            .hadith("bukhari:2856", cite: "Saheeh al-Bukhaari 2856", arabic: 40...82, english: [18...85]),
            .text("This is why every prophet began with tawheed before anything else, and why the Prophet (peace be upon him) told Mu‘aadh, when he sent him to Yemen, to make it the first thing he called to (Saheeh al-Bukhaari 7372)."),
            .hadith("bukhari:7372", cite: "Saheeh al-Bukhaari 7372, Saheeh Muslim 19a", arabic: 49...64, english: [0...39]),
        ]),
        ArticleSection("FORMS OF SHIRK TODAY", [
            .markdown("**Major shirk (الشِّرك الأَكبَر)** takes a person out of Islam. It includes: calling upon the dead, saints, or prophets for help, rescue, or children; sacrificing or vowing to other than Allah; prostrating to a grave or a shaykh; believing that anyone besides Allah knows the unseen or controls the universe; and giving anyone the right to make lawful and unlawful in place of Allah:"),
            .ayah("46:5"),
            .ayah("9:31"),
            .markdown("**Minor shirk (الشِّرك الأَصغَر)** does not take one out of Islam but is greater than every other sin: showing off in worship (**riyaa’ (رِيَاء)**, from ر-أ-ي, to see: doing an act so that people will see it), swearing by other than Allah, and saying “what Allah wills and you will.” The Prophet (peace be upon him) said:"),
            .hadith("ahmed:23630", cite: "Musnad Ahmad 23630; graded saheeh by al-Albaani, Saheeh al-Jaami‘ 1555", arabic: 23...38, text: "“The thing I fear most for you is minor shirk.” They said: And what is minor shirk, O Messenger of Allah? He said: “Showing off”"),
            .text("Amulets, charms, omens, and going to fortune-tellers also fall under shirk, because they attach the heart to other than Allah for benefit and protection."),
        ]),
        ArticleSection("THE CURE", [
            .text("The cure for shirk is knowing Allah: that He alone creates, provides, hears, answers, and is near, so that the heart has no reason to turn to anyone else:"),
            .ayah("2:186"),
            .ayah("72:18"),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Is calling upon the dead or the saints for help shirk?**"),
            .text("Yes, when it is for what only Allah can give: cure, provision, children, rescue from distress, forgiveness. This is the very shirk of the people of Makkah, who did not believe their idols created the world but called on them as intercessors and helpers (see 39:3 above). Allah described the dead and absent who are called upon:"),
            .ayah("35:13-14", words: 20...41),
            .ayah("46:6"),
            .ayah("27:62"),
            .longOnly(.text("Allah also commanded, in the ayah quoted above, that no one be invoked with Him (72:18), and the Prophet (peace be upon him) said that whoever dies calling on a rival to Allah enters the Fire (Saheeh al-Bukhaari 4497, above). It makes no difference whether the one called upon is an idol, a prophet, or a righteous wali (وَلِي, from و-ل-ي, nearness: one close to Allah): the righteous themselves seek nearness to Allah and hope for His mercy (17:57). A living person may be asked for what he is able to do; the dead, even if they heard, could not answer (Quran 35:14, above), and nothing gives them the power to grant it.")),
            .shortOnly(.text("Allah also commanded, in the ayah quoted above, that no one be invoked with Him (72:18), and the Prophet (peace be upon him) said that whoever dies calling on a rival to Allah enters the Fire (Saheeh al-Bukhaari 4497, above). It makes no difference whether the one called upon is an idol, a prophet, or a righteous wali (وَلِي, from و-ل-ي, nearness: one close to Allah). A living person may be asked for what he is able to do; the dead, even if they heard, could not answer (Quran 35:14, above), and nothing gives them the power to grant it.")),
            .markdown("**Which tawassul is allowed and which is shirk?**"),
            .longOnly(.markdown("**Tawassul (تَوَسُّل)**, from و-س-ل, to seek a means of drawing near, is seeking a means to Allah. Allowed, as the Key Terms explain: by Allah’s names and attributes, by one’s own faith and righteous deeds, and by asking a living righteous person to make dua (دُعَاء, from د-ع-و, to call upon) for you. Forbidden and shirk: calling on the dead or absent themselves, asking them for needs, or making them intermediaries who carry requests to Allah, for that is exactly what the pagans did. Between the two lies asking Allah “by the right” or “by the status” of the Prophet or a saint. The Companions did not do it after his death, the scholars differed over it, and Ibn Taymiyyah in Qaa‘idah Jaleelah and al-Albaani in at-Tawassul held it to be an innovation rather than shirk in itself, while warning that it is the door through which shirk enters. Allah answered those who took the righteous as a means:")),
            .shortOnly(.markdown("**Tawassul (تَوَسُّل)**, from و-س-ل, to seek a means of drawing near, is seeking a means to Allah. Allowed: by Allah’s names and attributes, by one’s own faith and righteous deeds, and by asking a living righteous person to make dua (دُعَاء, from د-ع-و, to call upon) for you. Forbidden and shirk: calling on the dead or absent themselves, asking them for needs, or making them intermediaries who carry requests to Allah, for that is exactly what the pagans did. Between the two lies asking Allah “by the right” or “by the status” of the Prophet or a saint. The Companions did not do it after his death, the scholars differed over it, and Ibn Taymiyyah in Qaa‘idah Jaleelah and al-Albaani in at-Tawassul held it to be an innovation rather than shirk in itself, while warning that it is the door through which shirk enters. Allah answered those who took the righteous as a means:")),
            .ayah("17:56-57"),
            .longOnly(.markdown("**Are amulets shirk?**")),
            .longOnly(.text("Yes. The Prophet (peace be upon him) said, as quoted in the Key Terms below, that whoever hangs an amulet has committed shirk (Musnad Ahmad 17422; graded saheeh by al-Albaani), and the Key Terms explain when that is major shirk and when it is minor. Amulets made from the Quran are not excepted: the companions of Ibn Mas‘ood disliked them all (reported by Ibn Abi Shaybah in al-Musannaf), and this is the view chosen by Ibn Baaz and Ibn al-Uthaymeen (may Allah have mercy on them), because it closes the door to the rest and because the Quran was revealed to be recited, not hung. Protection is sought through the ruqyah the Sunnah taught, the morning and evening remembrances, and reliance on Allah:")),
            .longOnly(.ayah("39:38", words: 8...35)),
            .markdown("**Is visiting graves shirk?**"),
            .text("No. Visiting graves to remember death and to make dua for the dead is Sunnah. The Prophet (peace be upon him) said:"),
            .hadith("muslim:977a", cite: "Saheeh Muslim 977", arabic: 55...59, english: [0...11]),
            .longOnly(.hadith("muslim:976b", cite: "Saheeh Muslim 976", arabic: 56...60, english: [55...65])),
            .longOnly(.text("He taught the visitor to say:")),
            .longOnly(.hadith("muslim:975", cite: "Saheeh Muslim 975", arabic: 59...75, english: [21...51])),
            .text("What is forbidden is what the earlier nations did with graves: building over them, plastering them, and turning them into places of worship:"),
            .hadith("muslim:970a", cite: "Saheeh Muslim 970", arabic: 19...34, english: [0...27]),
            .longOnly(.hadith("muslim:532", cite: "Saheeh Muslim 532", arabic: 91...110, english: [65...100])),
            .longOnly(.text("He said this five days before he died, and in his final illness he cursed the Jews and Christians for taking the graves of their prophets as places of worship, warning against what they did (Saheeh al-Bukhaari 435, Saheeh Muslim 531). Ali (may Allah be pleased with him) was sent by the Prophet to leave no raised grave without levelling it (Saheeh Muslim 969). The scholars therefore distinguish three visits: the visit of the Sunnah, to greet the dead and pray for them; the visit of innovation, to pray or recite at the grave seeking its blessing; and the visit of shirk, to call on the dead, seek their help, or vow or sacrifice to them. The first is worship; the last is what took the nations before us out of tawheed.")),
            .longOnly(.hadith("bukhari:435", cite: "Saheeh al-Bukhaari 435, Saheeh Muslim 531", arabic: 23...60, english: [0...67])),
            .longOnly(.hadith("muslim:969a", cite: "Saheeh Muslim 969", arabic: 40...62, english: [0...29])),
            .shortOnly(.text("The scholars therefore distinguish three visits: the visit of the Sunnah, to greet the dead and pray for them; the visit of innovation, to pray or recite at the grave seeking its blessing; and the visit of shirk, to call on the dead, seek their help, or vow or sacrifice to them. The first is worship; the last is what took the nations before us out of tawheed.")),
            .longOnly(.markdown("**Is the Prophet alive, and can we ask him for our needs?**")),
            .longOnly(.text("The Prophet (peace be upon him) died, as Allah told him he would, and he is alive in his grave the life of the barzakh, which is not the life of this world and whose nature only Allah knows:")),
            .longOnly(.ayah("39:30")),
            .longOnly(.hadith("nasai:1282", cite: "Sunan an-Nasaa’i 1282; graded saheeh by al-Albaani", arabic: 48...57, english: [6...22])),
            .longOnly(.hadith("abudawud:2041", cite: "Sunan Abi Daawood 2041; graded hasan by al-Albaani", arabic: 34...47, english: [4...22])),
            .longOnly(.text("So sending salaam upon him reaches him. But asking him, at his grave or from afar, for provision, cure, children, or forgiveness is the shirk of dua. Even in his lifetime he did not own that:")),
            .longOnly(.ayah("7:188", words: 0...10)),
            .longOnly(.ayah("72:21")),
            .longOnly(.text("The Companions knew him best and loved him most, and when drought came after his death Umar did not go to his grave to ask him for rain; he asked al-Abbaas, a living man, to make dua (Saheeh al-Bukhaari 1010, quoted in the Key Terms below). Had asking the Prophet after his death been lawful, they would have been the first to do it.")),
            .longOnly(.markdown("**Is it shirk to praise the Prophet?**")),
            .longOnly(.text("Loving the Prophet (peace be upon him) more than oneself, praising him with what Allah praised him, and sending salawaat upon him are worship of Allah and a sign of faith:")),
            .longOnly(.ayah("33:56")),
            .longOnly(.markdown("What is forbidden is exaggeration (**ghuluw**) that raises him above the station of servant and messenger: attributing to him knowledge of all the unseen, control over creation, or a share in what belongs to Allah. He himself forbade it:")),
            .longOnly(.hadith("bukhari:3445", cite: "Saheeh al-Bukhaari 3445", arabic: 36...49, english: [6...35])),
            .longOnly(.text("True love of him is following him:")),
            .longOnly(.ayah("3:31", words: 0...10)),
            .longOnly(.markdown("**Is swearing by other than Allah shirk?**")),
            .longOnly(.text("Yes, it is minor shirk, because an oath is a form of veneration that belongs to Allah alone. Ibn Umar (may Allah be pleased with him) heard a man say “No, by the Ka‘bah,” and said: Nothing is sworn by other than Allah, for I heard the Messenger of Allah (peace be upon him) say:")),
            .longOnly(.hadith("tirmidhi:1535", cite: "Jaami‘ at-Tirmidhi 1535; graded saheeh by al-Albaani", arabic: 41...48, english: [31...42])),
            .longOnly(.hadith("bukhari:6108", cite: "Saheeh al-Bukhaari 6108, Saheeh Muslim 1646", arabic: 32...45, english: [25...49])),
            .longOnly(.text("At-Tirmidhi reported that some of the people of knowledge explained “disbelief or shirk” here as a severe wording rather than apostasy, and the scholars add that it becomes major shirk only when the one swearing venerates what he swears by as Allah is venerated. The remedy is to say la ilaaha illallah:")),
            .longOnly(.hadith("bukhari:4860", cite: "Saheeh al-Bukhaari 4860", arabic: 35...46, english: [4...26])),
            .longOnly(.markdown("**Are fortune-tellers, astrology, and magic shirk?**")),
            .longOnly(.markdown("Claiming to know the unseen is a claim to what belongs to Allah alone, and seeking it from a fortune-teller (**kaahin**), an astrologer, or a magician attaches the heart to other than Him. The Prophet (peace be upon him) said:")),
            .longOnly(.hadith("muslim:2230", cite: "Saheeh Muslim 2230", arabic: 36...47, english: [0...20])),
            .longOnly(.hadith("ibnmajah:639", cite: "Sunan Ibn Maajah 639; graded saheeh by al-Albaani", arabic: 38...55, english: [5...39])),
            .longOnly(.hadith("abudawud:3905", cite: "Sunan Abi Daawood 3905; graded hasan by al-Albaani", arabic: 40...51, english: [4...29])),
            .longOnly(.text("Magic itself is counted with shirk among the seven destroyers:")),
            .longOnly(.hadith("bukhari:2766", cite: "Saheeh al-Bukhaari 2766", arabic: 35...68, english: [4...93])),
            .longOnly(.text("Even attributing rain to a star is a kind of kufr. After a night of rain at al-Hudaybiyah the Prophet (peace be upon him) said that Allah had said:")),
            .longOnly(.hadith("bukhari:846", cite: "Saheeh al-Bukhaari 846, Saheeh Muslim 71", arabic: 70...92, english: [64...109])),
            .longOnly(.text("Studying the positions of the stars for direction, the qiblah, and the seasons is permitted; claiming that they influence events or reveal the future is the astrology that is forbidden.")),
            .markdown("**Is shirk forgiven?**"),
            .text("If a person dies upon major shirk it is not forgiven, as 4:48 quoted above states, and Allah repeats the warning in 4:116."),
            .ayah("4:116", words: 0...12),
            .text("But before death, every sin including shirk is wiped out by repentance and entering Islam. After mentioning those who invoke another deity with Allah, Allah said:"),
            .ayah("25:70"),
            .ayah("39:53"),
            .text("When Amr ibn al-As (may Allah be pleased with him) came to give his pledge and held back his hand, wanting the condition that he be forgiven, the Prophet (peace be upon him) said:"),
            .hadith("muslim:121", cite: "Saheeh Muslim 121", arabic: 189...208, english: [244...276]),
            .text("So the door is open to whoever repents before death, whatever his shirk was; many of the Companions had worshipped idols before Islam."),
            .longOnly(.markdown("**Will shirk appear in this ummah?**")),
            .longOnly(.text("Yes. It is not enough to say “we are Muslims, so shirk does not concern us.” The Prophet (peace be upon him) foretold it plainly:")),
            .longOnly(.hadith("abudawud:4252", cite: "Sunan Abi Daawood 4252; graded saheeh by al-Albaani", arabic: 141...155, english: [206...229])),
            .longOnly(.hadith("bukhari:7116", cite: "Saheeh al-Bukhaari 7116", arabic: 30...40, english: [4...25])),
            .longOnly(.text("Dhul-Khalasah was the idol of Daws in the jaahiliyyah (جَاهِلِيَّة, from ج-ه-ل, ignorance: the age before Islam), and Daws had become Muslim. He also said:")),
            .longOnly(.hadith("muslim:2907a", cite: "Saheeh Muslim 2907", arabic: 44...51, english: [7...27])),
            .longOnly(.hadith("bukhari:3456", cite: "Saheeh al-Bukhaari 3456", arabic: 33...56, english: [4...50])),
            .longOnly(.text("The Jews and Christians fell into shirk through exaggeration about their prophets and righteous men and through their graves (Saheeh Muslim 532, above). That is why the Salaf treated shirk as a live danger to be learned and guarded against, not a closed chapter of history.")),
            .longOnly(.markdown("**Is fearing or hoping in other than Allah shirk?**")),
            .longOnly(.text("Fear and hope are worship of the heart, so each has a lawful and an unlawful form. Natural fear, such as fear of an enemy, a beast, or drowning, is not shirk; Moosa (peace be upon him) left Egypt in fear (28:21).")),
            .longOnly(.ayah("28:21", words: 0...3)),
            .longOnly(.text("Fear that stops a person from an obligation or leads him into sin is forbidden. But the fear of worship, fearing that the dead, the jinn, or a saint can harm by their own hidden power so that one dares not displease them, is major shirk, and Allah commanded that this fear be for Him alone:")),
            .longOnly(.ayah("3:175")),
            .longOnly(.ayah("5:44", words: 23...26)),
            .longOnly(.ayah("33:39")),
            .longOnly(.text("Hope is the same: hoping in a person for what he can do is natural, and hoping in other than Allah for what only He gives, such as Paradise, forgiveness, or provision from the unseen, is shirk:")),
            .longOnly(.ayah("18:110", words: 11...23)),
            .longOnly(.markdown("**Is a Muslim who falls into shirk out of ignorance excused?**")),
            .longOnly(.text("Two things must be kept apart. The act itself is shirk whoever does it, and it is called shirk, warned against, and refuted. The person who does it is judged a mushrik who has left Islam only after the proof of the revelation has reached him in a way he can understand and he persists. Allah does not punish before sending the message:")),
            .longOnly(.ayah("17:15", words: 15...20)),
            .longOnly(.ayah("9:6", words: 0...9)),
            .longOnly(.text("The ayah goes on: then deliver him to his place of safety, “That is because they are a people who do not know.” Ibn Taymiyyah (may Allah have mercy on him) wrote:")),
            .longOnly(.quote(text: "“I am among the people most forbidding of attributing disbelief, sin, or disobedience to a specific person, unless it is known that the proof of the message has been established against him” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 3/229).", arabic: "أَنَا مِن أَعظَمِ النَّاسِ نَهيًا عَن أَن يُنسَبَ مُعَيَّنٌ إِلَى تَكفِيرٍ وَتَفسِيقٍ وَمَعصِيَةٍ، إِلَّا إِذَا عُلِمَ أَنَّهُ قَد قَامَت عَلَيهِ الحُجَّةُ الرِّسَالِيَّةُ", dimmed: true)),
            .longOnly(.text("The scholars differ over the details: who counts as having received the proof, and whether a Muslim living among the Muslims, with the Quran in his hands, can claim ignorance of the tawheed that is its first message. Ibn Baaz (may Allah have mercy on him) held that one who lives among the Muslims, with the Quran and the Sunnah within his reach, is not excused by ignorance in calling on the dead and the like, because he neglected to ask and learn. Ibn al-Uthaymeen and al-Albaani (may Allah have mercy on them) gave more weight to the impediments (ignorance, mistake, coercion, misinterpretation) in judging a specific person. All three held that this judgement belongs to the people of knowledge. The duty of the ordinary Muslim is to hate the act, teach the truth gently, and leave the ruling on individuals to those qualified.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Shirk is the one sin that is not forgiven if a person dies upon it, and it is not only bowing to idols: it is every invocation, sacrifice, vow, and hope directed to other than Allah. Tawheed is its cure and the first message of every prophet."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Shirk (شِرك)**: from the root ش-ر-ك, sharika, “to share, to be a partner.” The one who does it is a **mushrik (مُشرِك)**, and what he sets up beside Allah is a **shareek (شَرِيك)**, a partner, or a **nidd (نِدّ)**, a rival. Allah forbade it immediately after the first command in the Quran, to worship Him alone (2:21):"),
            .ayah("2:21", words: 0...5),
            .ayah("2:22", words: 17...22),
            .markdown("**Tawheed (تَوحِيد)**: the verbal noun of wahhada, “to make one, to single out.” It was the message of every messenger before any other matter:"),
            .ayah("21:25"),
            .markdown("**Ilaah (إِلَه)**: “the one worshipped,” from aliha, “to turn to in devotion, love, and need.” An ilaah is whatever hearts take as an object of worship, rightly or wrongly. So the testimony **la ilaaha illallah** does not mean only “there is no creator but Allah” (the pagans admitted that) but “there is nothing rightly worshipped except Allah”:"),
            .ayah("2:163"),
            .markdown("**Ibaadah (عِبَادَة)**: worship, from the root ع-ب-د, which carries the meanings of lowliness and submission; an **‘abd** is a slave. In the religion it is submission to Allah with the utmost love and humility. Ibn Taymiyyah (may Allah have mercy on him) gave the definition the scholars have relied on since:"),
            .quote(text: "“Worship is a comprehensive term for everything Allah loves and is pleased with, of words and deeds, inward and outward” (Ibn Taymiyyah, al-Uboodiyyah).", arabic: "العِبَادَةُ هِيَ اسمٌ جَامِعٌ لِكُلِّ مَا يُحِبُّهُ اللَّهُ وَيَرضَاهُ مِنَ الأَقوَالِ وَالأَعمَالِ البَاطِنَةِ وَالظَّاهِرَةِ", dimmed: true),
            .text("So prayer, sacrifice, vows, supplication, fear, hope, reliance, love, and seeking help are all worship, and directing any of them to other than Allah is shirk."),
            .markdown("**Dua (دُعَاء)**: “calling”: asking Allah for what one needs, and calling upon Him in praise. It is the heart of worship. An-Nu‘maan ibn Basheer (may Allah be pleased with him) narrated that the Prophet (peace be upon him) said:"),
            .hadith("abudawud:1479", cite: "Sunan Abi Daawood 1479; graded saheeh by al-Albaani", arabic: 25...33, english: [4...23]),
            .ayah("40:60"),
            .text("Because dua is worship, calling upon other than Allah in what only He can do is the clearest form of shirk."),
            .markdown("**Tawassul (تَوَسُّل)**: from waseelah, “a means of nearness.” Allah commanded it:"),
            .ayah("5:35"),
            .text("The Salaf understood the means to be faith and righteous deeds. The Sunnah shows three permitted kinds. First, by Allah’s names and attributes:"),
            .ayah("7:180", words: 0...9),
            .text("Second, by one’s own righteous deeds, as the three men trapped in the cave did. They said to one another:"),
            .hadith("bukhari:2272", cite: "Saheeh al-Bukhaari 2272", arabic: 52...63, english: [42...72]),
            .text("Third, by the dua of a living righteous person. When drought struck, Umar (may Allah be pleased with him) did not go to the Prophet’s grave but asked his uncle al-Abbaas to pray:"),
            .hadith("bukhari:1010", cite: "Saheeh al-Bukhaari 1010", arabic: 45...59, english: [23...64]),
            .text("Ibn Taymiyyah set out these kinds in Qaa‘idah Jaleelah fi at-Tawassul wal-Waseelah, and al-Albaani in at-Tawassul: Anwaa‘uhu wa Ahkaamuhu. Tawassul by the person, status, or “right” of someone dead is not found in the practice of the Companions, and calling on the dead themselves is shirk."),
            .markdown("**Istighaathah (اِستِغَاثَة)**: seeking rescue (**ghawth**) from hardship. From Allah it is worship:"),
            .ayah("8:9", words: 0...4),
            .text("Asking a living, present person for help in what he is able to do is ordinary and permitted, as the man of Moosa’s people called to him for help (Quran 28:15)."),
            .ayah("28:15", words: 17...24),
            .text("But seeking rescue from the dead or the absent, in what only Allah has power over, is major shirk:"),
            .ayah("10:106"),
            .markdown("**Shafaa‘ah (شَفَاعَة)**: intercession, from shaf‘, “a pair”: joining one’s request to another’s. It belongs to Allah alone, and no one intercedes except by His permission and for whom He is pleased with:"),
            .ayah("39:44"),
            .ayah("2:255", words: 19...25),
            .text("The Prophet (peace be upon him) will intercede on the Day of Resurrection, and the way to his intercession is tawheed:"),
            .hadith("bukhari:99", cite: "Saheeh al-Bukhaari 99", arabic: 64...79, english: [51...85]),
            .text("So intercession is asked from Allah (“O Allah, grant me the intercession of Your Prophet”), not from the dead. The pagans of Makkah were condemned precisely for taking their idols as intercessors (Quran 10:18, 39:3)."),
            .ayah("10:18", words: 9...13),
            .markdown("**Tabarruk (تَبَرُّك)**: seeking blessing (**barakah**) from something. The Companions sought blessing from the Prophet’s body and its traces in his lifetime: his hair, his sweat, and the water left from his wudu (Saheeh al-Bukhaari 187, Saheeh Muslim 2331):"),
            .hadith("bukhari:171", cite: "Saheeh al-Bukhaari 171", arabic: 21...38, english: [0...18]),
            .hadith("bukhari:187", cite: "Saheeh al-Bukhaari 187", arabic: 22...32, english: [0...40]),
            .hadith("muslim:2331b", cite: "Saheeh Muslim 2331", arabic: 71...114, english: [16...81]),
            .text("This was specific to him (peace be upon him): the Companions did not do it with Abu Bakr, Umar, or any of the best of the ummah after him, as ash-Shaatibi pointed out in al-I‘tisaam. Blessing is also sought from what the texts made blessed, such as the Quran, Zamzam water, and the places and times Allah honoured, in the way the Sunnah shows. Seeking blessing from graves, stones, trees, or the persons of shaykhs has no basis and is the road to shirk."),
            .markdown("**Tameemah (تَمِيمَة)**: an amulet, from tamma, “to complete,” because the people of jaahiliyyah believed it completed their protection. Hanging it in the belief that it repels harm by itself is major shirk; hanging it as a supposed means is minor shirk. Uqbah ibn Aamir (may Allah be pleased with him) narrated that the Prophet (peace be upon him) said:"),
            .quote(text: "“Whoever hangs an amulet has committed shirk” (Musnad Ahmad 17422; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 492).", arabic: "مَن تَعَلَّقَ تَمِيمَةً فَقَد أَشرَكَ", dimmed: true),
            .markdown("**Ruqyah (رُقيَة)**: an incantation recited over the sick. It is permitted, and Sunnah, when it is with the Quran, the names of Allah, and the duas of the Prophet, and contains no shirk. Awf ibn Maalik (may Allah be pleased with him) said: We used to practise ruqyah in jaahiliyyah, so we asked the Messenger of Allah about it. He said:"),
            .hadith("muslim:2200", cite: "Saheeh Muslim 2200", arabic: 38...48, english: [10...32]),
            .markdown("**Taaghoot (طَاغُوت)**: from tagha, “to exceed the bounds.” Rejecting it is the negation in the shahaadah, la ilaaha, and belief in Allah is its affirmation, illallah:"),
            .ayah("2:256", words: 9...20),
            .text("Ibn al-Qayyim (may Allah have mercy on him) defined it in I‘laam al-Muwaqqi‘een:"),
            .quote(text: "“The taaghoot is everything by which the servant exceeds his limit, whether something worshipped, followed, or obeyed” (Ibn al-Qayyim, I‘laam al-Muwaqqi‘een 1/50).", arabic: "الطَّاغُوتُ كُلُّ مَا تَجَاوَزَ بِهِ العَبدُ حَدَّهُ مِن مَعبُودٍ أَو مَتبُوعٍ أَو مُطَاعٍ", dimmed: true),
            .text("He went on to say that the taaghoot of any people is whoever they take their disputes to instead of Allah and His Messenger, worship instead of Allah, follow without insight from Allah, or obey in what they do not know to be obedience to Allah. Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him) summarised its heads as five at the end of al-Usool ath-Thalaathah: Iblees; whoever is worshipped and is pleased with it; whoever calls people to worship him; whoever claims any knowledge of the unseen; and whoever judges by other than what Allah revealed."),
            .text("On the last of these the scholars draw a distinction that must be kept. Ibn Abbaas (may Allah be pleased with them) explained the disbelief mentioned in 5:44 as “disbelief less than disbelief” (reported by al-Haakim in al-Mustadrak): it is major kufr when a person holds his own judgement to be lawful in place of Allah’s or better than it, and a lesser kufr when he judges by desire while acknowledging that Allah’s ruling is the truth. Ibn Baaz and Ibn al-Uthaymeen (may Allah have mercy on them) explained it in this way, and the ruling on any particular person belongs to the people of knowledge, not to individuals."),
            .markdown("**Nadhr (نَذر)** is a vow, and **dhabh (ذَبح)** is slaughter. Both are worship, so both are for Allah alone:"),
            .hadith("bukhari:6696", cite: "Saheeh al-Bukhaari 6696", arabic: 28...39, english: [4...31]),
            .hadith("muslim:1978b", cite: "Saheeh Muslim 1978", arabic: 48...53, english: [38...46]),
            .text("When a man vowed to slaughter camels at a place called Buwaanah, the Prophet (peace be upon him) first asked:"),
            .hadith("abudawud:3313", cite: "Sunan Abi Daawood 3313; graded saheeh by al-Albaani", arabic: 63...115, english: [42...102]),
            .text("Vowing or slaughtering for a saint, a grave, or a jinn is major shirk, even if the name of Allah is pronounced over the animal."),
            .markdown("**Riyaa’ (رِيَاء)**: from ru’yah, “seeing”: doing an act of worship so that people see it. It is minor shirk that nullifies the deed it enters. In a hadith qudsi Allah says:"),
            .hadith("muslim:2985", cite: "Saheeh Muslim 2985", arabic: 38...51, english: [0...36]),
            .hadith("ibnmajah:4204", cite: "Sunan Ibn Maajah 4204; graded hasan by al-Albaani", arabic: 44...74, english: [18...58]),
            .markdown("**Jaahiliyyah (جَاهِلِيَّة)**: “the state of ignorance”: the condition of the Arabs before the Prophet (peace be upon him), and every state that resembles it in creed, judgement, or conduct. The Quran uses the word four times: the thought of jaahiliyyah (3:154), the judgement of jaahiliyyah (5:50), the display of jaahiliyyah (33:33), and the zealotry of jaahiliyyah (48:26):"),
            .ayah("3:154", words: 15...20),
            .ayah("5:50"),
            .ayah("33:33", words: 3...7),
            .ayah("48:26", words: 6...8),
            .markdown("**Wathan (وَثَن)** and **sanam (صَنَم)**: idols. A sanam is an image carved in a form; a wathan is anything set up to be worshipped, whether an image, a stone, or a grave. Ibraaheem (peace be upon him) feared idolatry for himself and his sons:"),
            .ayah("14:35"),
            .ayah("22:30", words: 17...23),
            .markdown("**Wali (وَلِيّ)**, plural **awliyaa’ (أَولِيَاء)**: from walaa’, closeness and support. The awliyaa’ of Allah are not a class of miracle-workers; Allah defined them Himself:"),
            .ayah("10:62-63"),
            .hadith("bukhari:6502", cite: "Saheeh al-Bukhaari 6502", arabic: 35...44, english: [4...20]),
            .text("So every pious believer is a wali of Allah, in proportion to his faith and piety, as Ibn Taymiyyah explained in al-Furqaan bayna Awliyaa’ ar-Rahman wa Awliyaa’ ash-Shaytaan. Loving them is faith; worshipping them, calling on them, or believing they control the universe is shirk, and they are the first to disown it (Quran 46:6)."),
            .markdown("**Shirk akbar (الشِّرك الأَكبَر)**, major shirk, takes a person out of Islam and is not forgiven if he dies upon it. **Shirk asghar (الشِّرك الأَصغَر)**, minor shirk, does not take one out of Islam, yet it is graver than the major sins. **Shirk khafi (الشِّرك الخَفِيّ)**, hidden shirk, is the name the Prophet (peace be upon him) gave to riyaa’ because it creeps into the heart unnoticed. The forms of each are set out below."),
        ]),
    ]
}

struct KufrView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: kufr is disbelief, the rejection or denial of what Allah revealed. Some actions and beliefs take a person out of Islam; knowing them is a protection, and judging a specific person by them is the work of the scholars, not of individuals.")
                }

                Section(header: ArticleHeader("WHAT IS KUFR?")) {
                    ArticleParagraph(articleMarkdown: "**Kufr (كُفر)** means “to cover”: the farmer who covers the seed is called a **kaafir** in the Arabic language. In the religion it is covering the truth: rejecting, denying, doubting, or turning away from what the Messenger (peace be upon him) brought. Its opposite is **eemaan (إِيمَان)**, faith.")

                    ScriptureQuote(quran: "4:136")

                    ScriptureQuote(quran: "3:85")
                }

                Section(header: ArticleHeader("MAJOR AND MINOR KUFR")) {
                    ArticleParagraph(articleMarkdown: "**Major kufr (الكُفر الأَكبَر)** takes a person out of Islam. **Minor kufr (الكُفر الأَصغَر)** is a grave sin the texts called “kufr” without meaning apostasy, such as ingratitude to a husband or fighting a fellow Muslim. Ahl as-Sunnah keep the two apart, unlike the Khawaarij, who made every major sin major kufr, and unlike the extreme Murji’ah, who said no sin harms one who believes.")
                }

                Section(header: ArticleHeader("WHAT BREAKS ISLAM")) {
                    ArticleParagraph(articleMarkdown: "The scholars gathered from the Quran and Sunnah the **nawaaqid al-Islam (نَوَاقِض الإِسلَام)**, the nullifiers of Islam. Among the most important:")

                    ArticleParagraph(articleMarkdown: "**1. Shirk in worship**: calling upon, sacrificing to, or prostrating to other than Allah.")
                    ScriptureQuote(quran: "4:116")

                    ArticleParagraph(articleMarkdown: "**2. Taking intermediaries** between oneself and Allah, calling on them and relying on them, as the pagans did (Quran 39:3, 10:18).")
                    ScriptureQuote(quran: "39:3", words: 4...15)
                    ScriptureQuote(quran: "10:18", words: 0...13)

                    ArticleParagraph(articleMarkdown: "**3. Denying the disbelief of the disbelievers**, or believing that a religion other than Islam is acceptable to Allah (Quran 3:85).")

                    ArticleParagraph(articleMarkdown: "**4. Believing that a guidance other than the Prophet’s is better**, or that the judgement of other than Allah is better than His.")
                    ScriptureQuote(quran: "12:40", words: 15...31)

                    ArticleParagraph(articleMarkdown: "**5. Hating any part of what the Messenger brought**, even while acting on it.")

                    ArticleParagraph(articleMarkdown: "**6. Mocking** any part of the religion, its reward, or its punishment.")
                    ScriptureQuote(quran: "9:65-66", words: 7...18)

                    ArticleParagraph(articleMarkdown: "**7. Magic** (sihr), practising it or being pleased with it.")

                    ArticleParagraph(articleMarkdown: "**8. Supporting the disbelievers against the Muslims** out of loyalty to their religion.")

                    ArticleParagraph(articleMarkdown: "**9. Believing that anyone may leave the Sharee‘ah of Muhammad** (peace be upon him), as some Sufis claimed of their “saints.”")

                    ArticleParagraph(articleMarkdown: "**10. Turning away from the religion entirely**, neither learning it nor acting on it.")

                    ArticleParagraph(verbatim: "Beside these stands abandoning the prayer, which the Companions counted as disbelief. The Prophet (peace be upon him) said:")
                    ScriptureQuote(hadith: "muslim:82a", cite: "Saheeh Muslim 82a", arabic: 34...41, english: 21...33)
                    ScriptureQuote(hadith: "tirmidhi:2621", cite: "Jaami‘ at-Tirmidhi 2621; graded saheeh by al-Albaani", arabic: 77...85, english: 7...23)

                    ArticleParagraph(verbatim: "Abdullah ibn Shaqeeq, a Successor, said: “The Companions of Muhammad did not consider the abandonment of any action to be disbelief except the prayer” (Jaami‘ at-Tirmidhi 2622). The strongest position, that of Imam Ahmad, is that leaving it entirely is major kufr.")
                    ScriptureQuote(hadith: "tirmidhi:2622", cite: "Jaami‘ at-Tirmidhi 2622; graded saheeh by al-Albaani", arabic: 15...30, english: 0...15)
                }

                Section(header: ArticleHeader("THE RULES OF TAKFEER")) {
                    ArticleParagraph(articleMarkdown: "Knowing what breaks Islam is one thing; declaring a specific person a disbeliever (**takfeer**, تَكفِير, from ك-ف-ر: to pronounce someone a kaafir) is another. The Salaf were the most careful of people in this. A ruling of kufr applies to a person only when the **conditions** are met and the **impediments** are absent: he must know the ruling, intend the act, and be free of coercion, mistake, or a legitimate misunderstanding.")

                    ScriptureQuote(quran: "16:106")

                    ScriptureQuote(quran: "4:94", words: 9...16)

                    ArticleParagraph(verbatim: "The Prophet (peace be upon him) warned:")
                    ScriptureQuote(hadith: "bukhari:6103", cite: "Saheeh al-Bukhaari 6103, Saheeh Muslim 60a", arabic: 40...49, english: 4...23)

                    ArticleParagraph(verbatim: "So a Muslim who commits a major sin is a sinful believer, not a disbeliever, unless he declares the sin lawful. And judging that a particular person has left Islam belongs to qualified scholars and the Muslim judge, never to individuals or groups on their own. This is the line between Ahl as-Sunnah and the Khawaarij.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Do we call a specific Muslim a kaafir?**")
                        ArticleParagraph(verbatim: "Not on our own. There is a difference between saying “whoever does such-and-such has disbelieved,” which states a ruling of the Sharee‘ah, and saying “this person is a kaafir,” which is a judgement on an individual. The second requires that the conditions be present, knowledge, intent, and free choice, and that the impediments be absent: ignorance, mistake, coercion, and a misinterpretation the person believes to be the truth. That is why Allah excused the one who is forced while his heart is secure in faith (16:106, quoted above), forbade saying “you are not a believer” to one who offers the greeting of peace (4:94, above), and why the Prophet (peace be upon him) warned that the word “kaafir” returns upon the one who says it wrongly (Saheeh al-Bukhaari 6103, above). He also told of a man who doubted Allah’s power over him and was still forgiven:")
                        ScriptureQuote(hadith: "bukhari:3481", cite: "Saheeh al-Bukhaari 3481, Saheeh Muslim 2756", arabic: 32...90, english: 4...115)
                        ArticleParagraph(verbatim: "Ibn Taymiyyah (may Allah have mercy on him) wrote:")
                        ScriptureQuote(text: "“No one has the right to declare any of the Muslims a disbeliever, even if he has erred and been mistaken, until the proof has been established against him and the matter made clear to him” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 12/466).", arabic: "لَيسَ لِأَحَدٍ أَن يُكَفِّرَ أَحَدًا مِنَ المُسلِمِينَ وَإِن أَخطَأَ وَغَلِطَ حَتَّى تُقَامَ عَلَيهِ الحُجَّةُ وَتُبَيَّنَ لَهُ المَحَجَّةُ", dimmed: true)
                        ArticleParagraph(verbatim: "So the ordinary Muslim hates the act of kufr, warns against it, and leaves the ruling on the person to the qualified scholars and the judge, who examine him, establish the proof, and call him to repent. Whoever makes takfeer of Muslims his habit has taken the road of the Khawaarij, whatever he calls himself; and whoever goes to the other extreme, treating the nullifiers as though no belief or deed could ever be kufr, has taken the road of the Murji’ah. The truth is between the two: the nullifiers are real, and the ruling on a named person is not the layman’s to give.")

                        ArticleParagraph(articleMarkdown: "**Is abandoning the prayer kufr?**")
                        ArticleParagraph(verbatim: "The texts quoted above are severe: the Prophet (peace be upon him) placed the abandonment of the prayer between a man and shirk and kufr (Saheeh Muslim 82), called the prayer the covenant whose abandoner has disbelieved (Jaami‘ at-Tirmidhi 2621), and his Companions saw no deed whose abandonment is disbelief except the prayer, as Abdullah ibn Shaqeeq reported (Jaami‘ at-Tirmidhi 2622). Umar (may Allah be pleased with him) said as he lay wounded: “There is no share in Islam for one who leaves the prayer” (reported by Maalik in al-Muwatta). On this basis Imam Ahmad held that whoever abandons the prayer entirely, even while admitting it is obligatory, commits major kufr, and Ibn Baaz and Ibn al-Uthaymeen (may Allah have mercy on them) held the same. Abu Haneefah, Maalik, and ash-Shaafi‘i held that he is a grave sinner who has not left Islam unless he denies that it is obligatory, understanding the kufr in these texts as minor kufr, and al-Albaani (may Allah have mercy on him) chose this view. Among their proofs is the hadith of Ubaadah ibn as-Saamit:")
                        ScriptureQuote(hadith: "abudawud:1420", cite: "Sunan Abi Daawood 1420; graded saheeh by al-Albaani", arabic: 58...96, english: 50...109)
                        ArticleParagraph(verbatim: "Ibn al-Qayyim set out both sides fairly in Kitaab as-Salaah. All agree that whoever denies the obligation of the five prayers is a disbeliever, that abandoning them is among the gravest of all sins, and that the one who leaves them stands in real danger of dying outside Islam; the difference concerns the one who never denies the obligation yet never prays. Whoever fears for his religion does not gamble it on the milder opinion. And even on the stronger view no one applies that ruling to a particular man he knows: that belongs to the scholars and the judge, as above. What is asked of a Muslim whose brother has left the prayer is that he call him back to it, gently and again.")

                        ArticleParagraph(articleMarkdown: "**Is ruling by other than what Allah revealed kufr?**")
                        ArticleParagraph(verbatim: "Allah said of those who do not judge by what He revealed, in three consecutive aayaat:")
                        ScriptureQuote(quran: "5:44", words: 32...40)
                        ScriptureQuote(quran: "5:45", words: 22...30)
                        ScriptureQuote(quran: "5:47", words: 7...15)
                        ArticleParagraph(verbatim: "Ibn Abbaas (may Allah be pleased with him), the interpreter of the Quran, said of the first ayah:")
                        ScriptureQuote(text: "“It is a kufr less than kufr” (reported by al-Haakim in al-Mustadrak, who graded it saheeh, with adh-Dhahabi agreeing, and al-Albaani).", arabic: "كُفرٌ دُونَ كُفرٍ", dimmed: true)
                        ArticleParagraph(verbatim: "And the Successor Ataa’ ibn Abi Rabaah said: a kufr less than kufr, a wrongdoing less than wrongdoing, and a disobedience less than disobedience (reported by Ibn Jareer at-Tabari in his Tafseer). So the scholars distinguish. Whoever rules by other than what Allah revealed believing that it is permissible, or that another law is equal or superior to the law of Allah, or rejecting Allah’s ruling, commits major kufr, for legislation belongs to Allah alone (12:40, quoted above). Whoever rules by other than it in some matter out of desire, bribery, fear, or favouritism, while believing that Allah’s law is the truth and that he is sinning, commits minor kufr and a grave sin. This is the detail given by Ibn Baaz, al-Albaani, and Ibn al-Uthaymeen (may Allah have mercy on them), following Ibn Abbaas, and it keeps the balance between the Khawaarij, who make every sin major kufr, and the Murji’ah, who empty the texts of their weight. Which of the two a particular case falls under is not settled from a page: it needs knowledge of the ruling given, of the man who gave it, and of what he believed when he gave it, and it belongs to the scholars. What is asked of the ordinary Muslim here is that he hold Allah’s law to be the truth and judge his own dealings by it.")

                        ArticleParagraph(articleMarkdown: "**Does ignorance excuse?**")
                        ArticleParagraph(verbatim: "Allah does not punish anyone before the message reaches him (17:15), and He sent the messengers so that no one would have an argument against Him:")
                        ScriptureQuote(quran: "17:15", words: 15...20)
                        ScriptureQuote(quran: "4:165", words: 0...10)
                        ArticleParagraph(verbatim: "The man who ordered his body burned (Saheeh al-Bukhaari 3481, quoted above) is the clearest example. Ibn Taymiyyah wrote of him:")
                        ScriptureQuote(text: "“This man doubted the power of Allah and His restoring him once he had been scattered; indeed he believed he would not be restored. That is kufr by the agreement of the Muslims, but he was ignorant and did not know it, and he was a believer who feared that Allah would punish him, so he was forgiven for that” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 3/231).", arabic: "فَهَذَا رَجُلٌ شَكَّ فِي قُدرَةِ اللَّهِ وَفِي إِعَادَتِهِ إِذَا ذُرِّيَ، بَلِ اعتَقَدَ أَنَّهُ لَا يُعَادُ، وَهَذَا كُفرٌ بِاتِّفَاقِ المُسلِمِينَ، لَكِن كَانَ جَاهِلًا لَا يَعلَمُ ذَلِكَ، وَكَانَ مُؤمِنًا يَخَافُ اللَّهَ أَن يُعَاقِبَهُ فَغُفِرَ لَهُ بِذَلِكَ", dimmed: true)
                        ArticleParagraph(verbatim: "So ignorance is an impediment to takfeer of a specific person. But it has limits: the one who is able to learn and turns away is not excused, for turning away is itself a kind of kufr; and what is excused in a new Muslim or one raised far from knowledge is not the same in one who grew up among the Muslims with the Quran in his hands. Weighing where a particular person stands is the work of the scholars, who look at what reached him and how.")

                        ArticleParagraph(articleMarkdown: "**Are the Jews and Christians disbelievers?**")
                        ArticleParagraph(verbatim: "Yes, in the ruling of Allah, because they did not believe in the Messenger He sent to all mankind, and because of what they said about Him:")
                        ScriptureQuote(quran: "5:73", words: 0...13)
                        ScriptureQuote(quran: "98:6", words: 0...11)
                        ScriptureQuote(hadith: "muslim:153", cite: "Saheeh Muslim 153", arabic: 29...54, english: 0...52)
                        ArticleParagraph(verbatim: "The scholars count denying the disbelief of those who rejected the Messenger among the nullifiers of Islam, the third listed above, because it is a denial of the message itself. That is a ruling on the belief; as always, whether a particular person falls under it is weighed by the scholars, after the matter has been made clear to him. As for 2:62, Ibn Katheer explains that it concerns those of each community who followed the messenger of their own time before the next was sent; after Muhammad (peace be upon him) no religion is accepted but his (3:85, above).")
                        ScriptureQuote(quran: "2:62")
                        ArticleParagraph(verbatim: "Their disbelief does not make them all alike in conduct, for the Quran says they are not all the same (3:113) and praises those among them who believed (3:199); nor does it cancel their rights:")
                        ScriptureQuote(quran: "3:113", words: 1...14)
                        ScriptureQuote(quran: "3:199", words: 0...14)
                        ScriptureQuote(quran: "3:75", words: 1...17)
                        ScriptureQuote(quran: "60:8")
                        ScriptureQuote(quran: "5:5", words: 4...22)
                        ArticleParagraph(verbatim: "So a Muslim judges their religion by the Quran while treating their persons with justice and kindness, keeps his word to them, may eat their slaughtered meat and marry their chaste women, and hopes for their guidance, as scholars among them found it, such as Abdullah ibn Salaam (may Allah be pleased with him).")

                        ArticleParagraph(articleMarkdown: "**Is one who mocks the religion a kaafir?**")
                        ArticleParagraph(verbatim: "Mocking Allah, His verses, or His Messenger is major kufr even when it is said in jest, because it is the opposite of the veneration that faith requires. The ayah quoted above (9:65-66) came down, as Ibn Katheer records in his Tafseer, about a man on the expedition of Tabook who mocked the reciters among the Companions; when he protested that he was only joking, Allah answered that they had disbelieved after their belief. Allah also forbade sitting with those who ridicule His verses:")
                        ScriptureQuote(quran: "4:140", words: 6...24)
                        ArticleParagraph(verbatim: "The scholars distinguish mocking the religion itself from mocking a religious person in some worldly matter, such as his manner or clothing, which is a sin of the tongue but not kufr. And as with every nullifier, applying the ruling to a specific person is left to those qualified to establish the proof.")

                        ArticleParagraph(articleMarkdown: "**Is a Muslim who commits kufr under compulsion a kaafir?**")
                        ArticleParagraph(verbatim: "No, if his heart is at rest with faith, as the ayah quoted above says (16:106). The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "ibnmajah:2045", cite: "Sunan Ibn Maajah 2045; graded saheeh by al-Albaani", arabic: 27...36, english: 0...15)
                        ArticleParagraph(verbatim: "The mufassiroon report that the ayah came down concerning Ammaar ibn Yaasir (may Allah be pleased with him), whom the pagans of Makkah tortured until he said what they wanted of him. He came to the Prophet (peace be upon him) weeping; the Prophet asked him how he found his heart, he answered that it was at rest with faith, and he was told that if they returned to it he could do the same (Ibn Katheer, Tafseer, under this ayah).")
                        ArticleParagraph(articleMarkdown: "Compulsion (**ikraah**) is real when a person is threatened with death or grievous harm by someone able to carry it out and he has no way out. Ibn Katheer notes that the scholars agreed that the one so compelled may utter the word of kufr to save his life while his heart holds to faith, and that refusing and bearing the harm, as Bilaal (may Allah be pleased with him) bore it, is higher. Mere fear for wealth, position, or reputation is not the compulsion the ayah means, and no compulsion ever makes it permissible to kill an innocent person.")

                        ArticleParagraph(articleMarkdown: "**Does a major sin make a Muslim a kaafir?**")
                        ArticleParagraph(verbatim: "No. A Muslim who commits a major sin without deeming it lawful is a sinner with deficient faith, not a disbeliever. Allah forgives everything less than shirk for whom He wills (4:48), He called two parties who fight one another believers, and in the law of retaliation He called the killer the brother of the one who may pardon him:")
                        ScriptureQuote(quran: "4:48", words: 0...12)
                        ScriptureQuote(quran: "49:9", words: 0...6)
                        ScriptureQuote(quran: "2:178", words: 14...24)
                        ArticleParagraph(verbatim: "Abu Dharr (may Allah be pleased with him) narrated that the Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:5827", cite: "Saheeh al-Bukhaari 5827", arabic: 50...76, english: 31...93)
                        ArticleParagraph(verbatim: "Abu Ja‘far at-Tahaawi (may Allah have mercy on him) recorded this as the creed of Ahl as-Sunnah:")
                        ScriptureQuote(text: "“We do not declare anyone of the people of the qiblah a disbeliever because of a sin, as long as he does not deem it lawful” (at-Tahaawi, al-Aqeedah at-Tahaawiyyah).", arabic: "وَلَا نُكَفِّرُ أَحَدًا مِن أَهلِ القِبلَةِ بِذَنبٍ مَا لَم يَستَحِلَّهُ", dimmed: true)
                        ArticleParagraph(verbatim: "This was the error of the Khawaarij, who made the sinner a disbeliever, and of the Mu‘tazilah, who placed him between the two stations in this world and in the Fire forever in the next. Ahl as-Sunnah say: he is under the will of Allah, forgiven if He wills, punished if He wills, and if he enters the Fire he does not remain in it forever, for the intercession and the mercy of Allah bring out whoever had faith in his heart.")

                        ArticleParagraph(articleMarkdown: "**Can a kaafir become Muslim by the shahaadah?**")
                        ArticleParagraph(verbatim: "Yes. Whoever testifies that none has the right to be worshipped but Allah and that Muhammad is the Messenger of Allah, understanding it and meaning it, has entered Islam, and everything before it is wiped away:")
                        ScriptureQuote(quran: "8:38", words: 0...9)
                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said that whoever testifies to it, establishes the prayer, and gives zakaah has made his life and property inviolable except by a right that Islam itself establishes, and his reckoning is with Allah (Saheeh al-Bukhaari 25, Saheeh Muslim 22).")
                        ScriptureQuote(hadith: "bukhari:25", cite: "Saheeh al-Bukhaari 25, Saheeh Muslim 22", arabic: 37...68, english: 4...72)
                        ArticleParagraph(verbatim: "And he rebuked Usaamah ibn Zayd (may Allah be pleased with him) for killing a man in battle who said it at the last moment:")
                        ScriptureQuote(hadith: "bukhari:4269", cite: "Saheeh al-Bukhaari 4269", arabic: 65...90, english: 70...112)
                        ArticleParagraph(verbatim: "No ceremony or official is needed for Islam to be valid, though declaring it among Muslims is good; then the new Muslim learns the prayer and takes on the religion step by step. Amr ibn al-As (may Allah be pleased with him) was told that Islam wipes out what came before it (Saheeh Muslim 121), so no past sin, however great, bars the door.")
                        ScriptureQuote(hadith: "muslim:121", cite: "Saheeh Muslim 121", arabic: 176...208, english: 223...276)

                        ArticleParagraph(articleMarkdown: "**Can a Muslim be a kaafir while praying?**")
                        ArticleParagraph(verbatim: "Prayer is the greatest outward mark of Islam, but it is not a guarantee against the nullifiers. The hypocrites of Madinah prayed behind the Prophet (peace be upon him) while Allah counted them among the disbelievers:")
                        ScriptureQuote(quran: "4:142")
                        ArticleParagraph(verbatim: "And another wording of the hadith of the three signs of hypocrisy, quoted in the Key Terms below, adds:")
                        ScriptureQuote(hadith: "muslim:59c", cite: "Saheeh Muslim 59c", arabic: 25...33, english: 0...20)
                        ArticleParagraph(verbatim: "Likewise, one who prays but calls upon the dead for what only Allah gives, or practises magic, or mocks the religion, has fallen into what breaks Islam, as the list above shows; shirk voids the deeds it enters (39:65).")
                        ScriptureQuote(quran: "39:65", words: 7...13)
                        ArticleParagraph(verbatim: "That is the ruling on the deed itself, and whether a particular person who does it has left Islam still turns on the conditions and impediments already explained, which only the people of knowledge weigh for a given man. In dealing with people the matter is reversed: whoever prays and shows Islam is treated as a Muslim with a Muslim’s full rights, and no one may search his heart:")
                        ScriptureQuote(hadith: "bukhari:391", cite: "Saheeh al-Bukhaari 391", arabic: 31...50, english: 4...40)
                        ArticleParagraph(verbatim: "So the believer worries about his own heart before the hearts of those praying beside him: he guards his prayer from riyaa’, his creed from shirk, and thinks well of his brothers.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is abandoning the prayer kufr?**")
                        ArticleParagraph(verbatim: "The texts quoted above are severe: the Prophet (peace be upon him) placed the abandonment of the prayer between a man and shirk and kufr (Saheeh Muslim 82), called the prayer the covenant whose abandoner has disbelieved (Jaami‘ at-Tirmidhi 2621), and his Companions saw no deed whose abandonment is disbelief except the prayer, as Abdullah ibn Shaqeeq reported (Jaami‘ at-Tirmidhi 2622). Umar (may Allah be pleased with him) said as he lay wounded: “There is no share in Islam for one who leaves the prayer” (reported by Maalik in al-Muwatta). On this basis Imam Ahmad held that whoever abandons the prayer entirely, even while admitting it is obligatory, commits major kufr, and Ibn Baaz and Ibn al-Uthaymeen (may Allah have mercy on them) held the same. Abu Haneefah, Maalik, and ash-Shaafi‘i held that he is a grave sinner who has not left Islam unless he denies that it is obligatory, understanding the kufr in these texts as minor kufr, and al-Albaani (may Allah have mercy on him) chose this view. Among their proofs is the hadith of Ubaadah ibn as-Saamit:")
                        ScriptureQuote(hadith: "abudawud:1420", cite: "Sunan Abi Daawood 1420; graded saheeh by al-Albaani", arabic: 58...96, english: 50...109)
                        ArticleParagraph(verbatim: "Ibn al-Qayyim set out both sides fairly in Kitaab as-Salaah. All agree that whoever denies the obligation of the five prayers is a disbeliever, that abandoning them is among the gravest of all sins, and that the one who leaves them stands in real danger of dying outside Islam; the difference concerns the one who never denies the obligation yet never prays. Whoever fears for his religion does not gamble it on the milder opinion. And even on the stronger view no one applies that ruling to a particular man he knows: that belongs to the scholars and the judge, as above. What is asked of a Muslim whose brother has left the prayer is that he call him back to it, gently and again.")

                        ArticleParagraph(articleMarkdown: "**Does a major sin make a Muslim a kaafir?**")
                        ArticleParagraph(verbatim: "No. A Muslim who commits a major sin without deeming it lawful is a sinner with deficient faith, not a disbeliever. Allah forgives everything less than shirk for whom He wills (4:48), He called two parties who fight one another believers, and in the law of retaliation He called the killer the brother of the one who may pardon him:")
                        ScriptureQuote(quran: "4:48", words: 0...12)
                        ScriptureQuote(quran: "49:9", words: 0...6)
                        ScriptureQuote(quran: "2:178", words: 14...24)
                        ArticleParagraph(verbatim: "Abu Dharr (may Allah be pleased with him) narrated that the Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:5827", cite: "Saheeh al-Bukhaari 5827", arabic: 50...76, english: 31...93)
                        ArticleParagraph(verbatim: "Abu Ja‘far at-Tahaawi (may Allah have mercy on him) recorded this as the creed of Ahl as-Sunnah:")
                        ScriptureQuote(text: "“We do not declare anyone of the people of the qiblah a disbeliever because of a sin, as long as he does not deem it lawful” (at-Tahaawi, al-Aqeedah at-Tahaawiyyah).", arabic: "وَلَا نُكَفِّرُ أَحَدًا مِن أَهلِ القِبلَةِ بِذَنبٍ مَا لَم يَستَحِلَّهُ", dimmed: true)
                        ArticleParagraph(verbatim: "This was the error of the Khawaarij, who made the sinner a disbeliever, and of the Mu‘tazilah, who placed him between the two stations in this world and in the Fire forever in the next. Ahl as-Sunnah say: he is under the will of Allah, forgiven if He wills, punished if He wills, and if he enters the Fire he does not remain in it forever, for the intercession and the mercy of Allah bring out whoever had faith in his heart.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Kufr is covering the truth after it has come. Its nullifiers are known so that they are avoided, not so that Muslims label one another; the door of takfeer is guarded by knowledge, conditions, and the scholars.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleParagraph(articleMarkdown: "**Kufr (كُفر)**: from the root ك-ف-ر, kafara, “to cover, to conceal.” The Arabs called the night kaafir because it covers everything, and the farmer kaafir because he covers the seed with soil; the Quran uses the word in that sense when it likens this world to rain whose growth pleases the **kuffaar**, the tillers:")
                        ScriptureQuote(quran: "57:20", words: 13...24)
                        ArticleParagraph(verbatim: "In the religion, kufr is covering the truth that the Messenger (peace be upon him) brought after it has reached one: by denying it, doubting it, refusing it out of pride, turning away from it, or hiding disbelief behind a show of faith. It is the opposite of eemaan. Its second meaning, ingratitude, is the opposite of shukr, for the ungrateful person covers the favour he has received.")

                        ArticleParagraph(articleMarkdown: "**Kaafir (كَافِر)**, plural **kuffaar (كُفَّار)** and **kaafiroon (كَافِرُون)**: one who covers the truth. In the Sharee‘ah it is whoever is not a Muslim: the one to whom the message came and who rejected it, the one born outside Islam who never entered it (**kaafir asli**), and the one who left it (**murtadd**). The word describes a person’s religious state; it is not an insult, and Allah commanded fairness and kindness toward disbelievers who do not fight the Muslims (Quran 60:8, quoted above).")

                        ArticleParagraph(articleMarkdown: "**Kufr akbar (الكُفر الأَكبَر)** and **kufr asghar (الكُفر الأَصغَر)**: major kufr, which removes a person from Islam, and minor kufr, which the texts call kufr because it resembles it, without removing one from the religion. Ahl as-Sunnah say that just as there are two shirks, two kinds of nifaaq, and two kinds of zulm, so there are two kinds of kufr; the next section explains them.")

                        ArticleParagraph(verbatim: "Ibn al-Qayyim (may Allah have mercy on him) divided major kufr into five kinds in Madaarij as-Saalikeen:")
                        ScriptureQuote(text: "“Major kufr is of five kinds: the kufr of denial, the kufr of arrogance and refusal despite acknowledgement, the kufr of turning away, the kufr of doubt, and the kufr of hypocrisy” (Ibn al-Qayyim, Madaarij as-Saalikeen).", arabic: "الكُفرُ الأَكبَرُ خَمسَةُ أَنوَاعٍ: كُفرُ تَكذِيبٍ، وَكُفرُ استِكبَارٍ وَإِبَاءٍ مَعَ التَّصدِيقِ، وَكُفرُ إِعرَاضٍ، وَكُفرُ شَكٍّ، وَكُفرُ نِفَاقٍ", dimmed: true)
                        ArticleParagraph(articleMarkdown: "**Takdheeb (تَكذِيب)** is calling the truth a lie (Quran 29:68).")
                        ScriptureQuote(quran: "29:68", words: 0...11)
                        ArticleParagraph(articleMarkdown: "**Istikbaar (اِستِكبَار)** is refusing to submit out of pride while knowing the truth, the kufr of Iblees, who did not deny that Allah had commanded him:")
                        ScriptureQuote(quran: "2:34", words: 5...12)
                        ArticleParagraph(articleMarkdown: "**Shakk (شَكّ)** is doubt about the truth of the message (Quran 14:9).")
                        ScriptureQuote(quran: "14:9", words: 24...36)
                        ArticleParagraph(articleMarkdown: "**I‘raad (إِعرَاض)** is turning away from it altogether, neither believing nor denying, neither learning nor acting:")
                        ScriptureQuote(quran: "32:22", words: 0...8)
                        ArticleParagraph(articleMarkdown: "**Nifaaq (نِفَاق)** is hiding disbelief while displaying Islam (Quran 63:1-3).")
                        ScriptureQuote(quran: "63:1-3")

                        ArticleParagraph(articleMarkdown: "**Riddah (رِدَّة)** and **murtadd (مُرتَدّ)**: from radda, “to turn back.” Apostasy is leaving Islam after having entered it, by a belief, a statement, or an action that nullifies it, and the apostate is the murtadd. Allah warned:")
                        ScriptureQuote(quran: "2:217", words: 37...50)
                        ArticleParagraph(verbatim: "Even after apostasy the door of repentance stays open until death:")
                        ScriptureQuote(quran: "3:89")

                        ArticleParagraph(articleMarkdown: "**Nifaaq akbar (النِّفَاق الأَكبَر)** and **nifaaq asghar (النِّفَاق الأَصغَر)**: hypocrisy. The scholars of language derive it from the naafiqaa’, the hidden second exit of the jerboa’s burrow, because the hypocrite enters the religion by one door and leaves by another. Major hypocrisy, in belief, is concealing kufr behind a show of Islam, and it is worse than open disbelief:")
                        ScriptureQuote(quran: "4:145")
                        ArticleParagraph(verbatim: "Minor hypocrisy, in action, is having the traits of the hypocrites while believing; it does not remove one from Islam but is a grave sin and a road to the greater:")
                        ScriptureQuote(hadith: "bukhari:33", cite: "Saheeh al-Bukhaari 33, Saheeh Muslim 59a", arabic: 33...44, text: "“The signs of a hypocrite are three: Whenever he speaks, he tells a lie. Whenever he promises, he always breaks it (his promise ). If you trust him, he proves to be dishonest”")

                        ArticleParagraph(articleMarkdown: "**Takfeer (تَكفِير)**: declaring someone a kaafir. It is a ruling of the Sharee‘ah, not a matter of opinion or anger: only Allah and His Messenger decide what is kufr and who is a kaafir, and applying that to a specific person has conditions and impediments that the section on the rules of takfeer sets out. It is the scholars and the Muslim judge who apply it to a named person, after examining him and establishing the proof; it is never the work of an individual acting on his own.")

                        ArticleParagraph(articleMarkdown: "**Istihlaal (اِستِحلَال)**: from halaal: treating as lawful what Allah made unlawful, or as unlawful what He made lawful, as a matter of belief. The sinner who knows he is sinning has not left Islam; the one who says that what Allah forbade is permitted has rejected Allah’s ruling. This is how the Salaf explained the Christians’ taking their monks as lords (Quran 9:31): they did not pray to them, but they made lawful what the monks made lawful and unlawful what they made unlawful (Ibn Katheer, Tafseer).")
                        ScriptureQuote(quran: "9:31", words: 0...6)

                        ArticleParagraph(articleMarkdown: "**Juhood (جُحُود)**: denial of what one knows in his heart to be true. Allah said of Pharaoh’s people:")
                        ScriptureQuote(quran: "27:14", words: 0...5)
                        ArticleParagraph(verbatim: "And of the Quraysh, that they did not really think the Prophet a liar; it was the verses of Allah that the wrongdoers rejected (Quran 6:33).")
                        ScriptureQuote(quran: "6:33", words: 6...13)

                        ArticleParagraph(articleMarkdown: "**Kufr an-ni‘mah (كُفر النِّعمَة)**: ingratitude for a favour, the kufr that is the opposite of shukr. It is not disbelief unless it is joined to denial of the Giver, but the Quran warns against it and the Prophet (peace be upon him) called it kufr:")
                        ScriptureQuote(quran: "14:7", words: 3...10)
                        ScriptureQuote(hadith: "bukhari:29", cite: "Saheeh al-Bukhaari 29", arabic: 26...42, english: 4...56)

                        ArticleParagraph(articleMarkdown: "**Zandaqah (زَندَقَة)** and **zindeeq (زِندِيق)**: a word of Persian origin which many of the jurists use for the one who conceals disbelief while displaying Islam. Ibn Taymiyyah wrote in as-Saarim al-Maslool that the zindeeq in the usage of many of the fuqaha is the munaafiq of the Quran: two words for one reality.")

                        ArticleParagraph(articleMarkdown: "**Ahl al-Kitaab (أَهل الكِتَاب)**: the People of the Scripture, the Jews and the Christians, to whom the Torah and the Injeel were given. The Quran calls them by this name, invites them to the common word of tawheed (Quran 3:64), permits their food and marriage to their chaste women (Quran 5:5), and commands the finest manner in argument with them:")
                        ScriptureQuote(quran: "3:64", words: 0...16)
                        ScriptureQuote(quran: "29:46", words: 1...12)

                        ArticleParagraph(articleMarkdown: "**Millah (مِلَّة)**: the religion and way a people follow. The millah of Ibraaheem is the tawheed Allah commanded the Prophet (peace be upon him) to follow:")
                        ScriptureQuote(quran: "16:123")
                        ArticleParagraph(verbatim: "When the scholars say that a kufr “removes one from the millah” they mean it takes him out of Islam, and “a kufr that does not remove one from the millah” is minor kufr.")

                        ArticleParagraph(articleMarkdown: "**Islam (إِسلَام)** and **eemaan (إِيمَان)**: submission and faith. When the two are mentioned together, Islam is the outward deeds of the limbs and eemaan the inward belief of the heart, as in the hadith of Jibreel (Saheeh al-Bukhaari 50, Saheeh Muslim 8).")
                        ScriptureQuote(hadith: "bukhari:50", cite: "Saheeh al-Bukhaari 50, Saheeh Muslim 8a", arabic: 18...62, english: 0...82)
                        ArticleParagraph(verbatim: "When either is mentioned alone it includes the other. So every believer is a Muslim, but not every Muslim has reached faith:")
                        ScriptureQuote(quran: "49:14", words: 1...14)
                        ArticleParagraph(verbatim: "Ibn Taymiyyah explains this in Kitaab al-Eemaan: the faith that the texts praise is belief, statement, and action, and it increases with obedience and decreases with sin.")

                        ArticleParagraph(articleMarkdown: "**The Khawaarij (الخَوَارِج)** and **the Murji’ah (المُرجِئَة)**: the two extremes between which Ahl as-Sunnah stand. The Khawaarij, “those who went out,” rebelled against Ali (may Allah be pleased with him) and held that a Muslim who commits a major sin becomes a kaafir who will abide in the Fire forever; the Prophet (peace be upon him) foretold them and described them as passing out of the religion as an arrow passes through its prey (Saheeh al-Bukhaari 6930). The Murji’ah, from irjaa’, “to defer,” put action outside faith; the extreme among them said that no sin harms one who believes, while the Murji’at al-fuqahaa’ of Koofah still held the sinner to account. Ahl as-Sunnah hold that faith is belief, statement, and action, and that a major sin diminishes it without ending it (al-Ash‘ari, Maqaalaat al-Islaamiyyeen; Ibn Taymiyyah, Kitaab al-Eemaan).")
                        ScriptureQuote(hadith: "bukhari:6930", cite: "Saheeh al-Bukhaari 6930, Saheeh Muslim 1066", arabic: 63...88, english: 63...110)
                    }
                }

                ArticleSourcesSection(article: "KufrView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Kufr")
        .englishArticle().selectableArticleList(article: "KufrView")
    }
}

struct BidahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: bid‘ah is a newly invented matter in the religion, in belief or in worship, that the Prophet and his Companions were not upon. Every bid‘ah is misguidance, however good it looks, because the religion was completed.")
                }

                Section(header: ArticleHeader("WHAT IS BID‘AH?")) {
                    ArticleParagraph(articleMarkdown: "**Bid‘ah (بِدعَة)** comes from **bada‘a**, to originate something without precedent; Allah is **al-Badee‘**, the Originator of the heavens and the earth. In the religion, a bid‘ah is a newly invented way in belief or in worship, intended to draw near to Allah, that has no basis in the Quran, the Sunnah, or the practice of the Companions. Imam ash-Shaatibi defined it as “an invented way in the religion, resembling the Sharee‘ah, by which drawing near to Allah is intended” (al-I‘tisaam 1/37).")

                    ArticleParagraph(articleMarkdown: "It is not about cars, phones, or medicine; those are worldly matters, and the default in worldly things is permission. Bid‘ah is about **worship**, where the default is prohibition until the text permits. Worship is what Allah legislated, not what people find beautiful:")
                    ScriptureQuote(quran: "5:3", words: 39...49)
                }

                Section(header: ArticleHeader("EVERY BID‘AH IS MISGUIDANCE")) {
                    ArticleParagraph(verbatim: "The Prophet (peace be upon him) used to say in his sermons:")
                    ScriptureQuote(hadith: "muslim:867a", cite: "Saheeh Muslim 867", arabic: 64...78, english: 78...114)

                    ScriptureQuote(hadith: "bukhari:2697", cite: "Saheeh al-Bukhaari 2697, Saheeh Muslim 1718", arabic: 29...38, english: 4...22)

                    ScriptureQuote(hadith: "abudawud:4607", cite: "Sunan Abi Daawood 4607; graded saheeh by al-Albaani", arabic: 112...132, english: 159...192)

                    ArticleParagraph(articleMarkdown: "Note the word **every**. The Prophet (peace be upon him) did not divide innovations in worship into good and bad; he said every one is misguidance. The Companions understood him that way. Ibn Umar (may Allah be pleased with them both) said:")
                    ScriptureQuote(text: "“Every innovation is misguidance, even if the people see it as good” (al-Laalakaa’i, Sharh Usool I‘tiqaad Ahl as-Sunnah 126; Ibn Battah, al-Ibaanah 205).", arabic: "كُلُّ بِدعَةٍ ضَلَالَةٌ وَإِن رَآهَا النَّاسُ حَسَنَةً", dimmed: true)

                    ArticleParagraph(verbatim: "Ibn Mas‘ood (may Allah be pleased with him) said:")
                    ScriptureQuote(hadith: "darimi:207", cite: "Sunan ad-Daarimi 207; al-Haythami: its narrators are those of the Saheeh, Majma' az-Zawaa’id 1/181", arabic: 23...27, text: "“Follow, and do not innovate, for you have been sufficed”")

                    ArticleParagraph(verbatim: "The Prophet (peace be upon him) said, in the wording of Saheeh Muslim:")
                    ScriptureQuote(hadith: "muslim:1718b", cite: "Saheeh Muslim 1718", arabic: 64...71, english: 51...69)
                }

                Section(header: ArticleHeader("THE COMPANIONS IN ACTION")) {
                    ArticleParagraph(verbatim: "Abu Moosa al-Ash‘ari (may Allah be pleased with him) came to Ibn Mas‘ood and told him he had seen, in the mosque of Koofah, circles of people sitting with pebbles in their hands while a man said, “Say Allahu Akbar a hundred times,” “Say la ilaaha illallah a hundred times,” “Say subhaanallah a hundred times.” Ibn Mas‘ood went to them and said:")
                    ScriptureQuote(hadith: "darimi:206", cite: "Sunan ad-Daarimi 206; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 2005", arabic: 196...266, text: "“Count your sins, and I guarantee that nothing of your good deeds will be lost. Woe to you, O nation of Muhammad, how quickly is your destruction! These are the Companions of your Prophet, plentiful; these are his garments not yet worn out and his vessels not yet broken. By the One in whose hand is my soul, either you are upon a religion more guided than the religion of Muhammad, or you are opening a door of misguidance.” They said: By Allah, O Abu Abd ar-Rahman, we intended nothing but good. He said: “How many intend good and never reach it”")

                    ArticleParagraph(articleMarkdown: "They were saying words of remembrance, in a mosque, intending good, and a Companion called it a door of misguidance, because the **manner** was invented. This is the measure: sincerity is not enough; the act must also be according to the Sunnah.")
                }

                Section(header: ArticleHeader("“BUT UMAR CALLED TARAAWEEH A GOOD BID‘AH”")) {
                    ArticleParagraph(verbatim: "When Umar (may Allah be pleased with him) gathered the people behind one reciter in Ramadan, he said, “What an excellent bid‘ah this is” (Saheeh al-Bukhaari 2010).")
                    ScriptureQuote(hadith: "bukhari:2010", cite: "Saheeh al-Bukhaari 2010", arabic: 15...81, english: 6...135)
                    ArticleParagraph(verbatim: "This is the usual argument for “good innovation,” and it fails, because the Prophet (peace be upon him) had himself led the people in Taraaweeh for three nights and then stopped only for fear it would be made obligatory:")
                    ScriptureQuote(hadith: "bukhari:1129", cite: "Saheeh al-Bukhaari 1129, Saheeh Muslim 761", arabic: 65...79, english: 54...80)

                    ArticleParagraph(articleMarkdown: "Once revelation ended, that fear was gone, so Umar revived a Sunnah the Prophet (peace be upon him) had established. He called it a bid‘ah in the **linguistic** sense, something not seen for a while, not in the religious sense. The Prophet’s words “every innovation is misguidance” are not contradicted by a Companion reviving the Prophet’s own practice.")
                }

                ArticleOnly(.long) {
                    // Ash-Shafi'i's two statements and what the four imams said (Abu, 2026-11-24: "Mention imam
                    // Shafii quote about Bid'ah and explain what that means and explain what the other 3 imams
                    // said", with bidah.com's series on it). Every quote checked against its printed source on
                    // Shamela; the weak attributions (Abu Hanifah's "hold to the athar" through Nuh al-Jami',
                    // "whoever approves has legislated") are left out or named as such.
                    Section(header: ArticleHeader("ASH-SHAAFI‘I AND THE “TWO KINDS” OF BID‘AH")) {
                        ArticleParagraph(verbatim: "The other saying quoted for “good innovation” is Imam ash-Shaafi‘i’s (may Allah have mercy on him). It comes from two of his students. Harmalah ibn Yahya heard him say:")
                        ScriptureQuote(text: "“Innovation is of two kinds: praiseworthy innovation and blameworthy innovation. What agrees with the Sunnah is praiseworthy, and what opposes the Sunnah is blameworthy.” And he cited as his proof the words of Umar ibn al-Khattaab about the night prayer of Ramadan: “What an excellent innovation it is” (Abu Nu‘aym, Hilyat al-Awliyaa’ 9/113).", arabic: "البِدعَةُ بِدعَتَانِ: بِدعَةٌ مَحمُودَةٌ، وَبِدعَةٌ مَذمُومَةٌ، فَمَا وَافَقَ السُّنَّةَ فَهُوَ مَحمُودٌ، وَمَا خَالَفَ السُّنَّةَ فَهُوَ مَذمُومٌ. وَاحتَجَّ بِقَولِ عُمَرَ بنِ الخَطَّابِ فِي قِيَامِ رَمَضَانَ: نِعمَتِ البِدعَةُ هِيَ", dimmed: true)

                        ArticleParagraph(verbatim: "And ar-Rabee‘ ibn Sulaymaan, the student who transmitted his books, reported the fuller wording, which explains the first:")
                        ScriptureQuote(text: "“Newly invented matters are of two kinds. The first is what is invented that opposes a Book, a Sunnah, a report of the Companions, or a consensus: this is the innovation of misguidance. The second is what is invented of good that opposes none of these: this is a new thing that is not blameworthy. Umar said of the night prayer of Ramadan, ‘What an excellent innovation this is,’ meaning that it was new and had not been done before, and even so, there is nothing in it that rejects what came before” (al-Bayhaqi, Manaaqib ash-Shaafi‘i 1/468-469 and al-Madkhal 253, from ar-Rabee‘; Ibn Taymiyyah called its chain saheeh, Majmoo‘ al-Fataawa 20/163).", arabic: "المُحدَثَاتُ مِنَ الأُمُورِ ضَربَانِ: أَحَدُهُمَا مَا أُحدِثَ يُخَالِفُ كِتَابًا أَو سُنَّةً أَو أَثَرًا أَو إِجمَاعًا، فَهَذِهِ البِدعَةُ الضَّلَالَةُ. وَالثَّانِيَةُ مَا أُحدِثَ مِنَ الخَيرِ لَا خِلَافَ فِيهِ لِوَاحِدٍ مِن هَذَا، وَهَذِهِ مُحدَثَةٌ غَيرُ مَذمُومَةٍ، وَقَد قَالَ عُمَرُ رَضِيَ اللَّهُ عَنهُ فِي قِيَامِ شَهرِ رَمَضَانَ: نِعمَتِ البِدعَةُ هَذِهِ، يَعنِي أَنَّهَا مُحدَثَةٌ لَم تَكُن، وَإِذَا كَانَت فَلَيسَ فِيهَا رَدٌّ لِمَا مَضَى", dimmed: true)

                        ArticleParagraph(articleMarkdown: "**What he meant.** Read the two together and his meaning is plain. His “praiseworthy” kind is defined by agreement with the Book, the Sunnah, the Companions, and consensus, and the one example he gives for it is Umar’s word about Taraaweeh, a prayer the Prophet (peace be upon him) had himself led in congregation, as the section above shows. So what he calls a praiseworthy innovation is something with a basis in the Sharee‘ah that is new only in the language, which the scholars call **bid‘ah lughawiyyah**. Anything invented in the religion against those sources he calls, in his own words, “the innovation of misguidance.” Nothing in either statement permits adding to worship what the Prophet did not legislate.")

                        ArticleParagraph(verbatim: "That is how the scholars of the Sunnah after him read him. Ibn Hajar (may Allah have mercy on him), himself a Shaafi‘i, defined the term in his commentary on al-Bukhaari:")
                        ScriptureQuote(text: "“What is meant is what was invented and has no basis in the Sharee‘ah, and in the usage of the Sharee‘ah it is called bid‘ah. Whatever has a basis in the Sharee‘ah that points to it is not bid‘ah. So bid‘ah in the usage of the Sharee‘ah is blameworthy, unlike its use in the language” (Ibn Hajar, Fath al-Baari 13/253).", arabic: "وَالمُرَادُ بِهَا مَا أُحدِثَ وَلَيسَ لَهُ أَصلٌ فِي الشَّرعِ، وَيُسَمَّى فِي عُرفِ الشَّرعِ بِدعَةً، وَمَا كَانَ لَهُ أَصلٌ يَدُلُّ عَلَيهِ الشَّرعُ فَلَيسَ بِبِدعَةٍ، فَالبِدعَةُ فِي عُرفِ الشَّرعِ مَذمُومَةٌ، بِخِلَافِ اللُّغَةِ", dimmed: true)

                        ArticleParagraph(verbatim: "And Ibn Rajab al-Hanbali (may Allah have mercy on him), explaining the hadith “every innovation is misguidance” in Jaami‘ al-Uloom wal-Hikam, said of it and of ash-Shaafi‘i’s kind of statement:")
                        ScriptureQuote(text: "“His saying ‘every innovation is misguidance’ is among his comprehensive words; nothing is excluded from it, and it is a great foundation among the foundations of the religion” (Ibn Rajab, Jaami‘ al-Uloom wal-Hikam 2/128, hadith 28).", arabic: "فَقَولُهُ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ: كُلُّ بِدعَةٍ ضَلَالَةٌ، مِن جَوَامِعِ الكَلِمِ لَا يَخرُجُ عَنهُ شَيءٌ، وَهُوَ أَصلٌ عَظِيمٌ مِن أُصُولِ الدِّينِ", dimmed: true)
                        ScriptureQuote(text: "“As for what occurs in the words of the Salaf of approving some innovations, that is only in the linguistic sense of innovation, not the religious sense” (Ibn Rajab, Jaami‘ al-Uloom wal-Hikam 2/128, hadith 28).", arabic: "وَأَمَّا مَا وَقَعَ فِي كَلَامِ السَّلَفِ مِنِ استِحسَانِ بَعضِ البِدَعِ، فَإِنَّمَا ذَلِكَ فِي البِدَعِ اللُّغَوِيَّةِ لَا الشَّرعِيَّةِ", dimmed: true)

                        ArticleParagraph(articleMarkdown: "**What he did.** Ash-Shaafi‘i’s own practice shows the same. Mu‘aawiyah used to touch all four corners of the Ka‘bah, and Ibn Abbaas objected that only two are touched:")
                        ScriptureQuote(hadith: "bukhari:1608", cite: "Saheeh al-Bukhaari 1608", arabic: 21...44, english: 12...47)
                        ArticleParagraph(verbatim: "Ash-Shaafi‘i took Ibn Abbaas’s side and answered Mu‘aawiyah’s argument in his book al-Umm:")
                        ScriptureQuote(text: "“No one has left touching a corner out of abandoning the House of Allah the Exalted; rather, he touched what the Messenger of Allah (peace be upon him) touched, and held back from what the Messenger of Allah (peace be upon him) held back from touching” (ash-Shaafi‘i, al-Umm, Book of Hajj).", arabic: "وَلَكِن لَم يَدَع أَحَدٌ استِلَامَ الرُّكنِ هِجرَةً لِبَيتِ اللَّهِ تَعَالَى، وَلَكِنَّهُ استَلَمَ مَا استَلَمَ رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، وَأَمسَكَ عَمَّا أَمسَكَ رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ عَنِ استِلَامِهِ", dimmed: true)
                        ArticleParagraph(verbatim: "Ibn Hajar summed up his answer in Fath al-Baari (3/474): we follow the Sunnah in what it did and in what it left. A scholar who would not touch two corners of the Ka‘bah, the most honoured building on earth, because the Prophet did not touch them, is the last person to approve of acts of worship the Prophet never did.")

                        ArticleParagraph(verbatim: "He also wrote a whole treatise, Ibtaal al-Istihsaan, “Refuting Istihsaan,” against declaring things right in the religion by one’s own sense of what is good, and said in ar-Risaalah:")
                        ScriptureQuote(text: "“Istihsaan is only self-indulgence” (ash-Shaafi‘i, ar-Risaalah, paragraph 1464).", arabic: "وَإِنَّمَا الِاستِحسَانُ تَلَذُّذٌ", dimmed: true)
                        ArticleParagraph(verbatim: "The famous line “whoever approves has legislated” is reported in his name by al-Ghazaali without a chain, as a summary of this position; his own words are the ones above.")

                        ArticleParagraph(articleMarkdown: "**The later division into five.** Some later scholars, among them al-Izz ibn Abd as-Salaam and an-Nawawi, divided innovations into five rulings, from obligatory to forbidden, and Ibn Hajar mentions their division. Their examples of “obligatory” and “recommended” innovations are things like writing books of grammar to understand the Quran, building schools, and compiling the hadith: means that serve what the Sharee‘ah commands, which the scholars of the Sunnah call **maslahah mursalah** (explained in the key terms below), not acts of worship. Ash-Shaatibi answered in al-I‘tisaam that the division itself has no proof from the Sharee‘ah, because if a proof of the Sharee‘ah points to a thing being obligatory or recommended, it is not an innovation at all, and if none does, it cannot be called good. So the dispute is largely over the word; on the substance, adding new acts of worship, the four imams and their schools are one.")
                    }

                    Section(header: ArticleHeader("WHAT THE FOUR IMAMS SAID")) {
                        ArticleParagraph(articleMarkdown: "**Abu Haneefah (d. 150 AH).** He named his sources and the limit he would not pass:")
                        ScriptureQuote(text: "“I take the Book of Allah; what I do not find there, I take from the Sunnah of the Messenger of Allah (peace be upon him); and what I find in neither the Book of Allah nor the Sunnah of the Messenger of Allah, I take the sayings of his Companions: I take the saying of whichever of them I choose and leave whichever I choose, but I do not leave their sayings for the saying of anyone else” (Ibn Abd al-Barr, al-Intiqaa' p. 142, and al-Khateeb, Taareekh Baghdaad 13/365, through Yahya ibn ad-Durays).", arabic: "آخُذُ بِكِتَابِ اللَّهِ، فَمَا لَم أَجِد فَبِسُنَّةِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، فَمَا لَم أَجِد فِي كِتَابِ اللَّهِ وَلَا فِي سُنَّةِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ أَخَذتُ بِقَولِ أَصحَابِهِ، آخُذُ بِقَولِ مَن شِئتُ مِنهُم وَأَدَعُ مَن شِئتُ مِنهُم، وَلَا أَخرُجُ مِن قَولِهِم إِلَى قَولِ غَيرِهِم", dimmed: true)
                        ArticleParagraph(verbatim: "Nothing in religion, for him, comes from outside the Book, the Sunnah, and the Companions. A saying often quoted from him, “hold to the athar and the way of the Salaf, and beware of every newly invented matter, for it is an innovation,” is reported through Nooh ibn Abi Maryam, whom the critics of hadith accused of lying, so it is not relied on here; the statement above carries the same meaning on a sounder chain.")

                        ArticleParagraph(articleMarkdown: "**Maalik (d. 179 AH).** He made the completion of the religion the measure of every addition to it:")
                        ScriptureQuote(text: "“Whoever innovates in Islam an innovation that he sees as good has claimed that Muhammad betrayed the message, for Allah says, ‘This day I have perfected for you your religion.’ So whatever was not religion that day is not religion today” (ash-Shaatibi, al-I‘tisaam 1/64, reporting Ibn al-Maajishoon from Maalik; the scholars cite it without a graded chain).", arabic: "مَنِ ابتَدَعَ فِي الإِسلَامِ بِدعَةً يَرَاهَا حَسَنَةً فَقَد زَعَمَ أَنَّ مُحَمَّدًا صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ خَانَ الرِّسَالَةَ، لِأَنَّ اللَّهَ يَقُولُ: ﴿اليَومَ أَكمَلتُ لَكُم دِينَكُم﴾ فَمَا لَم يَكُن يَومَئِذٍ دِينًا فَلَا يَكُونُ اليَومَ دِينًا", dimmed: true)
                        ArticleParagraph(verbatim: "And in his al-Mabsoot, as Qaadi Iyaad records:")
                        ScriptureQuote(text: "“Nothing will set right the last of this ummah except what set right its first” (Maalik, in al-Mabsoot, quoted by Qaadi Iyaad, ash-Shifa 2/88).", arabic: "وَلَا يُصلِحُ آخِرَ هَذِهِ الأُمَّةِ إِلَّا مَا أَصلَحَ أَوَّلَهَا", dimmed: true)
                        ArticleParagraph(verbatim: "His best-known ruling on bid‘ah is about belief: his answer to the man who asked how Allah rose over the Throne. It has its own section, next.")

                        ArticleParagraph(articleMarkdown: "**Ash-Shaafi‘i (d. 204 AH).** His two statements on bid‘ah, his treatise against istihsaan, and his following of the Sunnah in what it left are set out in the section above. He also said, as quoted in the questions below, “If the hadith is authentic, then it is my madhhab.”")

                        ArticleParagraph(articleMarkdown: "**Ahmad ibn Hanbal (d. 241 AH).** He opened his creed, Usool as-Sunnah, with these words:")
                        ScriptureQuote(text: "“The foundations of the Sunnah with us are: holding fast to what the Companions of the Messenger of Allah were upon, taking them as an example, abandoning innovations; and every innovation is misguidance” (Ahmad ibn Hanbal, Usool as-Sunnah; al-Laalakaa’i 317).", arabic: "أُصُولُ السُّنَّةِ عِندَنَا: التَّمَسُّكُ بِمَا كَانَ عَلَيهِ أَصحَابُ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، وَالِاقتِدَاءُ بِهِم، وَتَركُ البِدَعِ، وَكُلُّ بِدعَةٍ فَهِيَ ضَلَالَةٌ", dimmed: true)
                        ArticleParagraph(verbatim: "He said “every innovation,” as the Prophet did, and he held to it under the whip in the trial over the createdness of the Quran, refusing to say a word about Allah that the Companions had not said.")

                        ArticleParagraph(articleMarkdown: "**One position.** Four imams in four cities, and the same answer: the measure is the Book, the Sunnah, and what the Companions were upon, and what is added to the religion beyond it is rejected. Their schools differ in hundreds of rulings of fiqh, but none of them made room for inventing worship.")
                    }

                    // Bid'ah in belief, with Imam Malik's rule on the rising at its centre (Abu, 2026-11-24:
                    // "mention imam malik quote in bidah too"). His answer moved here from the four imams so it
                    // has a heading of its own.
                    Section(header: ArticleHeader("BID‘AH IN BELIEF: IMAM MAALIK AND THE RISING")) {
                        ArticleParagraph(verbatim: "Bid‘ah is not only in worship. The first innovations in Islam were in belief, and the Salaf counted them the most dangerous of all. Ibn Taymiyyah (may Allah have mercy on him) named both kinds in his definition:")
                        ScriptureQuote(text: "“Bid‘ah is whatever opposes the Book and the Sunnah, or the consensus of the Salaf of this Ummah, in beliefs and in acts of worship: like the sayings of the Khawaarij, the Raafidah, the Qadariyyah and the Jahmiyyah, and like those who worship by dancing and singing in the mosques” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 18/346).", arabic: "وَالبِدعَةُ: مَا خَالَفَتِ الكِتَابَ وَالسُّنَّةَ أَو إِجمَاعَ سَلَفِ الأُمَّةِ مِنَ الِاعتِقَادَاتِ وَالعِبَادَاتِ، كَأَقوَالِ الخَوَارِجِ، وَالرَّوَافِضِ، وَالقَدَرِيَّةِ، وَالجَهمِيَّةِ، وَكَالَّذِينَ يَتَعَبَّدُونَ بِالرَّقصِ وَالغِنَاءِ فِي المَسَاجِدِ", dimmed: true)

                        ArticleParagraph(verbatim: "The first of them appeared while Companions were still alive. When the Qadariyyah began denying the decree in Basrah, two men went to Abdullah ibn Umar (may Allah be pleased with them both) and told him. He answered:")
                        ScriptureQuote(hadith: "muslim:8a", cite: "Saheeh Muslim 8a", arabic: 132...162, english: 132...223)

                        ArticleParagraph(verbatim: "Imam Maalik (may Allah have mercy on him) gave the rule for the attributes of Allah in one sentence, and its last clause is about bid‘ah. A man came into his circle and asked him how Allah rose over the Throne. He answered:")
                        ScriptureQuote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asmaa’ was-Sifaat 867; al-Laalakaa’i 664).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true)
                        ArticleParagraph(verbatim: "He called a question an innovation because the Companions, who knew Allah and His Book best, never asked how Allah rises over His Throne; so the one who asks it has gone where they did not go. In the narration of Ibn Wahb, whose chain Ibn Hajar graded good (Fath al-Baari 13/406-407), Maalik said that the how “is lifted away from Him,” called the questioner a man of innovation, and had him sent out. The same rule that governs worship governs belief: what the Companions did not do, we do not do.")
                        ArticleParagraph(verbatim: "Each clause closes a door that a sect walked through. “The rising is not unknown” closes it on those who emptied the word of meaning or changed it to “conquered.” “The ‘how’ is not comprehensible” closes it on those who pictured it. “Believing in it is obligatory” closes it on those who denied it. And “asking about it is an innovation” closes the door of kalaam, arguing about Allah by philosophy, which the Companions never opened.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) himself warned against those who chase such questions. He recited the ayah on the clear and the unclear verses of the Quran (Quran 3:7), and said:")
                        ScriptureQuote(quran: "3:7", words: 13...25)
                        ScriptureQuote(hadith: "bukhari:4547", cite: "Saheeh al-Bukhaari 4547, Saheeh Muslim 2665", arabic: 74...85, text: "“When you see those who follow what is unclear in it, they are the ones Allah named, so beware of them.”")

                        ArticleParagraph(verbatim: "And he foretold that his nation would split over its beliefs as the nations before it had split, and named the one group that would be saved:")
                        ScriptureQuote(hadith: "abudawud:4597", cite: "Sunan Abi Daawood 4597; graded hasan by al-Albaani", arabic: 56...83, text: "“Those before you of the People of the Book split into seventy-two sects, and this nation will split into seventy-three: seventy-two in the Fire and one in Paradise, and it is the Jamaa‘ah.”")

                        ArticleParagraph(verbatim: "The Jamaa‘ah is those upon what the Prophet and his Companions were upon. The Khawaarij, the Qadariyyah, the Jahmiyyah, the Mu‘tazilah and those after them split off over belief before anything else, and every one of them began with a question the Companions had not asked. The schools of belief, and the Salaf’s answer to each, are on their own page:")
                        ArticleDoorRow(door: .article("AqeedahMadhabView"))
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ASH-SHAAFI‘I AND THE “TWO KINDS” OF BID‘AH")) {
                        ArticleParagraph(verbatim: "The other saying quoted for “good innovation” is Imam ash-Shaafi‘i’s (may Allah have mercy on him). His student Harmalah ibn Yahya heard him say:")
                        ScriptureQuote(text: "“Innovation is of two kinds: praiseworthy innovation and blameworthy innovation. What agrees with the Sunnah is praiseworthy, and what opposes the Sunnah is blameworthy.” And he cited as his proof the words of Umar ibn al-Khattaab about the night prayer of Ramadan: “What an excellent innovation it is” (Abu Nu‘aym, Hilyat al-Awliyaa’ 9/113).", arabic: "البِدعَةُ بِدعَتَانِ: بِدعَةٌ مَحمُودَةٌ، وَبِدعَةٌ مَذمُومَةٌ، فَمَا وَافَقَ السُّنَّةَ فَهُوَ مَحمُودٌ، وَمَا خَالَفَ السُّنَّةَ فَهُوَ مَذمُومٌ. وَاحتَجَّ بِقَولِ عُمَرَ بنِ الخَطَّابِ فِي قِيَامِ رَمَضَانَ: نِعمَتِ البِدعَةُ هِيَ", dimmed: true)

                        ArticleParagraph(articleMarkdown: "**What he meant.** His “praiseworthy” kind is defined by agreement with the Sunnah, and the one example he gives for it is Umar’s word about Taraaweeh, a prayer the Prophet (peace be upon him) had himself led in congregation, as the section above shows. So what he calls a praiseworthy innovation is something with a basis in the Sharee‘ah that is new only in the language, which the scholars call **bid‘ah lughawiyyah**. In the fuller wording reported by his student ar-Rabee‘ ibn Sulaymaan, anything invented against a Book, a Sunnah, a report of the Companions, or a consensus he calls “the innovation of misguidance.” Nothing in either statement permits adding to worship what the Prophet did not legislate.")

                        ArticleParagraph(verbatim: "That is how the scholars of the Sunnah after him read him. Ibn Hajar (may Allah have mercy on him), himself a Shaafi‘i, defined the term in his commentary on al-Bukhaari:")
                        ScriptureQuote(text: "“What is meant is what was invented and has no basis in the Sharee‘ah, and in the usage of the Sharee‘ah it is called bid‘ah. Whatever has a basis in the Sharee‘ah that points to it is not bid‘ah. So bid‘ah in the usage of the Sharee‘ah is blameworthy, unlike its use in the language” (Ibn Hajar, Fath al-Baari 13/253).", arabic: "وَالمُرَادُ بِهَا مَا أُحدِثَ وَلَيسَ لَهُ أَصلٌ فِي الشَّرعِ، وَيُسَمَّى فِي عُرفِ الشَّرعِ بِدعَةً، وَمَا كَانَ لَهُ أَصلٌ يَدُلُّ عَلَيهِ الشَّرعُ فَلَيسَ بِبِدعَةٍ، فَالبِدعَةُ فِي عُرفِ الشَّرعِ مَذمُومَةٌ، بِخِلَافِ اللُّغَةِ", dimmed: true)

                        ArticleParagraph(articleMarkdown: "**The later division into five.** Some later scholars, among them al-Izz ibn Abd as-Salaam and an-Nawawi, divided innovations into five rulings, from obligatory to forbidden. Their examples of “obligatory” and “recommended” innovations, such as writing books of grammar to understand the Quran and compiling the hadith, are means that serve what the Sharee‘ah commands, not acts of worship. So the dispute is largely over the word; on the substance, adding new acts of worship, the four imams and their schools are one.")
                    }

                    Section(header: ArticleHeader("WHAT THE FOUR IMAMS SAID")) {
                        ArticleParagraph(articleMarkdown: "**Abu Haneefah (d. 150 AH)** took his religion from the Book of Allah, then the Sunnah, then the sayings of the Companions, and would not leave their sayings for the saying of anyone else (Ibn Abd al-Barr, al-Intiqaa’ p. 142).")

                        ArticleParagraph(articleMarkdown: "**Maalik (d. 179 AH).** He made the completion of the religion the measure of every addition to it:")
                        ScriptureQuote(text: "“Whoever innovates in Islam an innovation that he sees as good has claimed that Muhammad betrayed the message, for Allah says, ‘This day I have perfected for you your religion.’ So whatever was not religion that day is not religion today” (ash-Shaatibi, al-I‘tisaam 1/64, reporting Ibn al-Maajishoon from Maalik; the scholars cite it without a graded chain).", arabic: "مَنِ ابتَدَعَ فِي الإِسلَامِ بِدعَةً يَرَاهَا حَسَنَةً فَقَد زَعَمَ أَنَّ مُحَمَّدًا صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ خَانَ الرِّسَالَةَ، لِأَنَّ اللَّهَ يَقُولُ: ﴿اليَومَ أَكمَلتُ لَكُم دِينَكُم﴾ فَمَا لَم يَكُن يَومَئِذٍ دِينًا فَلَا يَكُونُ اليَومَ دِينًا", dimmed: true)

                        ArticleParagraph(articleMarkdown: "**Ash-Shaafi‘i (d. 204 AH).** His two statements on bid‘ah are set out in the section above.")

                        ArticleParagraph(articleMarkdown: "**Ahmad ibn Hanbal (d. 241 AH).** He opened his creed, Usool as-Sunnah, with these words:")
                        ScriptureQuote(text: "“The foundations of the Sunnah with us are: holding fast to what the Companions of the Messenger of Allah were upon, taking them as an example, abandoning innovations; and every innovation is misguidance” (Ahmad ibn Hanbal, Usool as-Sunnah; al-Laalakaa’i 317).", arabic: "أُصُولُ السُّنَّةِ عِندَنَا: التَّمَسُّكُ بِمَا كَانَ عَلَيهِ أَصحَابُ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، وَالِاقتِدَاءُ بِهِم، وَتَركُ البِدَعِ، وَكُلُّ بِدعَةٍ فَهِيَ ضَلَالَةٌ", dimmed: true)

                        ArticleParagraph(articleMarkdown: "**One position.** Four imams in four cities, and the same answer: the measure is the Book, the Sunnah, and what the Companions were upon, and what is added to the religion beyond it is rejected. Their schools differ in hundreds of rulings of fiqh, but none of them made room for inventing worship.")
                    }

                    Section(header: ArticleHeader("BID‘AH IN BELIEF: IMAM MAALIK AND THE RISING")) {
                        ArticleParagraph(verbatim: "Bid‘ah is not only in worship. The first innovations in Islam were in belief, and the Salaf counted them the most dangerous of all. Ibn Taymiyyah (may Allah have mercy on him) named both kinds in his definition:")
                        ScriptureQuote(text: "“Bid‘ah is whatever opposes the Book and the Sunnah, or the consensus of the Salaf of this Ummah, in beliefs and in acts of worship: like the sayings of the Khawaarij, the Raafidah, the Qadariyyah and the Jahmiyyah, and like those who worship by dancing and singing in the mosques” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 18/346).", arabic: "وَالبِدعَةُ: مَا خَالَفَتِ الكِتَابَ وَالسُّنَّةَ أَو إِجمَاعَ سَلَفِ الأُمَّةِ مِنَ الِاعتِقَادَاتِ وَالعِبَادَاتِ، كَأَقوَالِ الخَوَارِجِ، وَالرَّوَافِضِ، وَالقَدَرِيَّةِ، وَالجَهمِيَّةِ، وَكَالَّذِينَ يَتَعَبَّدُونَ بِالرَّقصِ وَالغِنَاءِ فِي المَسَاجِدِ", dimmed: true)

                        ArticleParagraph(verbatim: "Imam Maalik (may Allah have mercy on him) gave the rule for the attributes of Allah in one sentence, and its last clause is about bid‘ah. A man came into his circle and asked him how Allah rose over the Throne. He answered:")
                        ScriptureQuote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asmaa’ was-Sifaat 867; al-Laalakaa’i 664).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true)
                        ArticleParagraph(verbatim: "He called a question an innovation because the Companions, who knew Allah and His Book best, never asked how Allah rises over His Throne; so the one who asks it has gone where they did not go. In the narration of Ibn Wahb, whose chain Ibn Hajar graded good (Fath al-Baari 13/406-407), Maalik said that the how “is lifted away from Him,” called the questioner a man of innovation, and had him sent out. The same rule that governs worship governs belief: what the Companions did not do, we do not do.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) foretold that his nation would split over its beliefs as the nations before it had split, and named the one group that would be saved:")
                        ScriptureQuote(hadith: "abudawud:4597", cite: "Sunan Abi Daawood 4597; graded hasan by al-Albaani", arabic: 56...83, text: "“Those before you of the People of the Book split into seventy-two sects, and this nation will split into seventy-three: seventy-two in the Fire and one in Paradise, and it is the Jamaa‘ah.”")

                        ArticleParagraph(verbatim: "The Jamaa‘ah is those upon what the Prophet and his Companions were upon. The Khawaarij, the Qadariyyah, the Jahmiyyah, the Mu‘tazilah and those after them split off over belief before anything else, and every one of them began with a question the Companions had not asked. The schools of belief, and the Salaf’s answer to each, are on their own page:")
                        ArticleDoorRow(door: .article("AqeedahMadhabView"))
                    }
                }

                Section(header: ArticleHeader("WHY IT IS SO SERIOUS")) {
                    ArticleParagraph(verbatim: "Imam Maalik’s words on this, that whoever sees an innovation as good has accused the Prophet of betraying the message, are quoted under the four imams above.")

                    ArticleParagraph(verbatim: "Sufyaan ath-Thawri (may Allah have mercy on him) said:")
                    ScriptureQuote(text: "“Innovation is more beloved to Iblees than sin, for sin is repented from, and innovation is not repented from” (Abu Nu‘aym, Hilyat al-Awliyaa’ 7/26; al-Laalakaa’i 238).", arabic: "البِدعَةُ أَحَبُّ إِلَى إِبلِيسَ مِنَ المَعصِيَةِ، المَعصِيَةُ يُتَابُ مِنهَا، وَالبِدعَةُ لَا يُتَابُ مِنهَا", dimmed: true)

                    ArticleParagraph(verbatim: "The sinner knows he is sinning and may repent; the innovator thinks he is worshipping, so he never repents. And an innovation always crowds out a Sunnah: the effort and love that should have gone to what the Prophet (peace be upon him) taught go to what he never taught.")
                }

                Section(header: ArticleHeader("EXAMPLES")) {
                    ArticleParagraph(verbatim: "Celebrating the Prophet’s birthday (see “The Mawlid”); set congregational dhikr chanted in unison or with movements; fixing acts of worship to times and numbers the Sunnah did not fix, such as special prayers for the night of the fifteenth of Sha‘baan; building over graves and travelling to them for blessing; reciting the intention aloud before prayer; and adding words to the adhan. Each was measured by the Salaf against the same question: did the Prophet and his Companions do it, when they could have?")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Are cars, phones, microphones, and printed Mushafs bid‘ah?**")
                        ArticleParagraph(verbatim: "No. Bid‘ah is in the religion, in what is done to draw near to Allah. Worldly means are judged by a different rule. When the Prophet (peace be upon him) gave the people of Madinah an opinion about pollinating their date palms and the crop failed, he said:")
                        ScriptureQuote(hadith: "muslim:2363", cite: "Saheeh Muslim 2363", arabic: 72...75, english: 54...67)
                        ArticleParagraph(articleMarkdown: "Ibn Taymiyyah (may Allah have mercy on him) set out the rule in Majmoo‘ al-Fataawa: in acts of worship the default is restriction, so nothing is legislated except what Allah legislated, while in customs and worldly dealings the default is permission, so nothing is forbidden except what Allah forbade. A microphone carries the adhan; it does not add to it. A printed Mushaf carries the Quran; it does not add to it. The test of bid‘ah is whether the **act of worship** itself has been changed, not whether the tools around it are new.")

                        ArticleParagraph(articleMarkdown: "**Was compiling the Quran into one book a bid‘ah?**")
                        ArticleParagraph(verbatim: "No, and the objection was raised by the Companions themselves, twice, and answered twice. After many reciters were killed at al-Yamaamah, Umar urged Abu Bakr to gather the Quran. Abu Bakr later told Zayd ibn Thaabit (may Allah be pleased with them all) what had passed between them:")
                        ScriptureQuote(hadith: "bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 74...106, english: 115...168)
                        ArticleParagraph(verbatim: "Then Abu Bakr charged Zayd, who had been one of the Prophet’s scribes of revelation, with the task, and Zayd raised the same objection:")
                        ScriptureQuote(hadith: "bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 147...191, english: 249...332)
                        ArticleParagraph(verbatim: "Three things make this a preservation and not an invention. First, the Prophet (peace be upon him) had the Quran written down in his own lifetime by his scribes, of whom Zayd was one, as the same hadith says (“you used to write the revelation for the Messenger of Allah”), and he forbade writing anything else so that the Quran would stand alone:")
                        ScriptureQuote(hadith: "muslim:3004", cite: "Saheeh Muslim 3004", arabic: 29...37, english: 0...21)
                        ArticleParagraph(articleMarkdown: "Second, what Abu Bakr did was gather those already written pieces into one place, checked against the memories of the Companions, so that an obligation, guarding the Quran, would be fulfilled. Third, the Mushaf is not itself an act of worship: no one prays to it, reads it on an appointed night, or believes the codex brings reward. It is a means, and a means takes the ruling of its aim. This is exactly the **maslahah mursalah (مَصلَحَة مُرسَلَة)**, the unrestricted benefit described in the key terms, and ash-Shaatibi uses it as the example that shows the difference between a means and a bid‘ah.")

                        ArticleParagraph(articleMarkdown: "**What about Umar and Taraaweeh?**")
                        ArticleParagraph(verbatim: "Umar (may Allah be pleased with him) gathered the people behind one reciter for a prayer the Prophet (peace be upon him) had himself led in congregation and left only for fear of its being made obligatory, so he called it a bid‘ah in the linguistic sense, as the section above explains.")

                        ArticleParagraph(articleMarkdown: "**What about “whoever starts a good sunnah”?**")
                        ArticleParagraph(verbatim: "The full hadith, with its context, is the answer. Some poor Bedouins came to the Prophet (peace be upon him); he urged the people to give charity and they were slow, until a man of the Ansaar brought a purse of silver, then another, then the rest followed and his face lit up. Then he said:")
                        ScriptureQuote(hadith: "muslim:1017e", cite: "Saheeh Muslim 1017", arabic: 93...134, english: 0...73)
                        ArticleParagraph(articleMarkdown: "The “good practice” was charity, which Allah had already legislated; the man was the first to act, and the others followed. So **sanna** here means to be the first to do, or to revive, a legislated deed. Three points confirm it. The hadith says “in Islam,” and an innovation is not from Islam. The same hadith speaks of an “evil practice,” so the Prophet (peace be upon him) is not authorising whatever people call good; the Sharee‘ah is what decides which is which. And the same Prophet said “every innovation is misguidance” in the same religion; his words do not contradict each other, so the one is understood in the light of the other. Ibn al-Uthaymeen (may Allah have mercy on him) explains the hadith this way in al-Ibdaa‘ fi Kamaal ash-Shar‘.")

                        ArticleParagraph(articleMarkdown: "**Is celebrating the Prophet’s birthday, the night of Israa’ and Mi‘raaj, or the middle of Sha‘baan a bid‘ah?**")
                        ArticleParagraph(verbatim: "Yes, as festivals and as gatherings of appointed worship, because no act of worship was legislated for those nights. The Mawlid has its own page. For the night of the Israa’, Ibn al-Qayyim writes in Zad al-Ma‘aad that no established report fixes its month, its ten-day period, or its night, and the Companions, who knew the event best, singled out no night for it with any worship. For the middle of Sha‘baan, Ibn Rajab records in Lataa’if al-Ma‘aarif that some of the Taabi‘oon of Syria revered the night with their own worship, while most of the scholars of the Hijaaz, among them Ataa’ and Ibn Abi Mulaykah, and the jurists of Madinah and the companions of Maalik, rejected gathering in the mosques for it and called all of that an innovation; and no particular prayer or gathering for it is established from the Prophet (peace be upon him) or his Companions. Whatever is said about the reports of Allah’s forgiveness on that night, none of them contains a command to gather, to pray a particular prayer, or to fast that day in particular. Fasting in Sha‘baan generally, and praying at night generally, are Sunnah on every night of the year.")

                        ArticleParagraph(articleMarkdown: "**Is group dhikr in unison, or dhikr with beads, bid‘ah?**")
                        ArticleParagraph(verbatim: "Dhikr chanted together at a set count is the very thing Ibn Mas‘ood condemned in the Koofah mosque, as related above, and he did not accept “we intended nothing but good” as an answer. What the Prophet (peace be upon him) taught was counting on the fingers:")
                        ScriptureQuote(hadith: "abudawud:1501", cite: "Sunan Abi Daawood 1501; graded hasan by al-Albaani", arabic: 18...35, english: 0...51)
                        ArticleParagraph(verbatim: "The report praising the rosary is not authentic; al-Albaani judged it fabricated (as-Silsilah ad-Da‘eefah 83). On counting with beads itself the scholars differed: al-Albaani counted it an innovation, while Ibn Baaz and Ibn al-Uthaymeen held it permissible and counting on the fingers better, and all agree the fingers are the Sunnah. The gatherings of remembrance that the Prophet (peace be upon him) praised are real, but they are gatherings of the Quran, of knowledge, and of each person remembering Allah as he taught, not invented chants:")
                        ScriptureQuote(hadith: "muslim:2700a", cite: "Saheeh Muslim 2700", arabic: 42...60, english: 25...62)
                        ArticleParagraph(verbatim: "The Companions sat in such gatherings, and none of them swayed, chanted a fixed number in one voice, or appointed a leader to call out the count. Remember Allah as much as you can, in your own voice, and you have the whole of that reward.")

                        ArticleParagraph(articleMarkdown: "**Is the one who innovates a disbeliever?**")
                        ArticleParagraph(verbatim: "No, unless the innovation is itself disbelief and the conditions of takfeer are met in his case. Ahl as-Sunnah are the most careful of people about this, because the Prophet (peace be upon him) warned:")
                        ScriptureQuote(hadith: "bukhari:6103", cite: "Saheeh al-Bukhaari 6103", arabic: 40...49, english: 4...23)
                        ArticleParagraph(verbatim: "Imam Ahmad, who was imprisoned and beaten by rulers calling to the innovation that the Quran is created, prayed for them, sought forgiveness for them, and did not declare them disbelievers as individuals, as Ibn Taymiyyah records in Majmoo‘ al-Fataawa. But not being a disbeliever is not the same as being safe. The Prophet (peace be upon him) described people driven away from his Pool on the Day of Judgement:")
                        ScriptureQuote(hadith: "bukhari:6584", cite: "Saheeh al-Bukhaari 6584, Saheeh Muslim 2290", arabic: 27...42, english: 38...82)
                        ArticleParagraph(verbatim: "So the innovator is a Muslim who has been warned, and we hope for his repentance and pray for him; we do not take his innovation, and we do not make him a disbeliever.")

                        ArticleParagraph(articleMarkdown: "**Is every voluntary act of worship the Prophet did not do a bid‘ah?**")
                        ArticleParagraph(verbatim: "No. The Sharee‘ah contains general commands: pray extra, fast extra, give charity, recite the Quran, remember Allah, and it left the amount open. The Prophet (peace be upon him) said to Rabee‘ah ibn Ka‘b, who asked to be his companion in Paradise:")
                        ScriptureQuote(hadith: "muslim:489", cite: "Saheeh Muslim 489", arabic: 64...68, english: 53...66)
                        ArticleParagraph(verbatim: "And when he heard Bilaal’s footsteps in Paradise and asked him about his most hopeful deed, Bilaal said:")
                        ScriptureQuote(hadith: "bukhari:1149", cite: "Saheeh al-Bukhaari 1149", arabic: 52...74, english: 36...65)
                        ArticleParagraph(articleMarkdown: "Bilaal chose to pray after every wudu, and the Prophet (peace be upon him) approved it, because voluntary prayer after wudu is legislated in general and Bilaal added no new form, number, or claim to it. Bid‘ah begins when a person **specifies** what the Sharee‘ah left open, or opens what the Sharee‘ah restricted: a prayer on a fixed night with a fixed number of rak‘ahs and a fixed recitation, a dhikr with a fixed count in a fixed gathering, a fast tied to a date the Sunnah never tied it to. Ibn al-Uthaymeen (may Allah have mercy on him) summarised the conditions of following in al-Ibdaa‘ fi Kamaal ash-Shar‘: the act must agree with the Sharee‘ah in its cause, kind, amount, manner, time, and place. Where all six are as the Sunnah left them, the act is Sunnah; where one is invented, the act is bid‘ah even if its origin is legislated.")

                        ArticleParagraph(articleMarkdown: "**Why is bid‘ah worse than an ordinary sin?**")
                        ArticleParagraph(verbatim: "Sufyaan ath-Thawri’s words above give the reason: the sinner knows he is disobeying and may repent, while the innovator thinks he is obeying and therefore never turns back. Allah described such people:")
                        ScriptureQuote(quran: "18:103-104")
                        ArticleParagraph(verbatim: "A bid‘ah also does what a sin does not: it changes the religion itself for those who come after.")

                        ArticleParagraph(articleMarkdown: "**Is following a madhhab or a scholar a bid‘ah?**")
                        ArticleParagraph(verbatim: "No. Learning the religion from those who know it is commanded:")
                        ScriptureQuote(quran: "16:43", words: 8...14)
                        ArticleParagraph(verbatim: "The Companions themselves followed the verdicts of the scholars among them, and the four imams are trusted inheritors of the Sunnah whose schools preserved the fiqh of the Salaf. What the imams forbade was clinging to a man’s opinion after the Prophet’s word is known to oppose it. Ash-Shaafi‘i (may Allah have mercy on him) said:")
                        ScriptureQuote(text: "“If the hadith is authentic, then it is my madhhab” (an-Nawawi, al-Majmoo‘, introduction).", arabic: "إِذَا صَحَّ الحَدِيثُ فَهُوَ مَذهَبِي", dimmed: true)
                        ArticleParagraph(verbatim: "Similar statements from Abu Haneefah, Maalik, and Ahmad are gathered by al-Albaani in the introduction to Sifaat Salaat an-Nabi. So follow a madhhab or a scholar as a way of reaching the Sunnah, and let the Sunnah, not the man, be the final word.")

                        ArticleParagraph(articleMarkdown: "**How do I avoid bid‘ah?**")
                        ArticleParagraph(verbatim: "Learn the Sunnah, for a person avoids what he can recognise. Take the Quran and the authentic hadith as the reference in every dispute:")
                        ScriptureQuote(quran: "4:59", words: 10...23)
                        ArticleParagraph(verbatim: "Ask of every act of worship one question: did the Prophet (peace be upon him) and his Companions do it, when they could have? If they did not, leave it. Remember that the religion was completed in the Prophet’s lifetime, as the verse quoted at the top of this page says, so nothing that came later can be part of it. Hold to the counsel of Sunan Abi Daawood 4607 quoted above, to beware of newly invented matters, and keep to one path:")
                        ScriptureQuote(quran: "6:153", words: 0...11)
                        ArticleParagraph(verbatim: "Keep the company of people of the Sunnah, take knowledge from scholars known for it, and ask Allah every day in al-Faatihah for the straight path of those He favoured, not the path of those who went astray.")

                        ArticleParagraph(articleMarkdown: "**Is Salaah in a new mosque, or using a printed calendar for prayer times, bid‘ah?**")
                        ArticleParagraph(verbatim: "No. Both are means, and a means takes the ruling of what it serves, as Ibn al-Qayyim explains in I‘laam al-Muwaqqi‘een. Umar and Uthmaan extended and rebuilt the Prophet’s own mosque, changing its pillars and roof (Saheeh al-Bukhaari 446), and no Companion called that a bid‘ah, because the prayer inside it was unchanged. A calendar calculates the times that the Sharee‘ah fixed by the sun; the Companions measured them by shadows, and calculation is a more precise tool for the same legislated times. Bid‘ah would be to move the prayer to a time or a form the Sharee‘ah did not set, not to use a better way of knowing the time it did set.")
                        ScriptureQuote(hadith: "bukhari:446", cite: "Saheeh al-Bukhaari 446", arabic: 26...87, english: 0...95)

                        ArticleParagraph(articleMarkdown: "**How should I speak to someone who does a bid‘ah?**")
                        ArticleParagraph(verbatim: "With knowledge, gentleness, and proof, remembering that most people do it out of love for Allah and His Messenger and simply have not been taught. Allah commanded:")
                        ScriptureQuote(quran: "16:125", words: 0...10)
                        ArticleParagraph(verbatim: "Ibn Mas‘ood rebuked the people of the circles firmly, but he first heard them out, and they were Muslims who intended good. Firmness against the innovation and kindness toward the person go together; harshness that drives a person away from the Sunnah defeats its own purpose.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Are cars, phones, microphones, and printed Mushafs bid‘ah?**")
                        ArticleParagraph(verbatim: "No. Bid‘ah is in the religion, in what is done to draw near to Allah. Worldly means are judged by a different rule. When the Prophet (peace be upon him) gave the people of Madinah an opinion about pollinating their date palms and the crop failed, he said:")
                        ScriptureQuote(hadith: "muslim:2363", cite: "Saheeh Muslim 2363", arabic: 72...75, english: 54...67)
                        ArticleParagraph(articleMarkdown: "Ibn Taymiyyah (may Allah have mercy on him) set out the rule in Majmoo‘ al-Fataawa: in acts of worship the default is restriction, so nothing is legislated except what Allah legislated, while in customs and worldly dealings the default is permission, so nothing is forbidden except what Allah forbade. A microphone carries the adhan; it does not add to it. A printed Mushaf carries the Quran; it does not add to it. The test of bid‘ah is whether the **act of worship** itself has been changed, not whether the tools around it are new.")

                        ArticleParagraph(articleMarkdown: "**What about “whoever starts a good sunnah”?**")
                        ArticleParagraph(verbatim: "The full hadith, with its context, is the answer. Some poor Bedouins came to the Prophet (peace be upon him); he urged the people to give charity and they were slow, until a man of the Ansaar brought a purse of silver, then another, then the rest followed and his face lit up. Then he said:")
                        ScriptureQuote(hadith: "muslim:1017e", cite: "Saheeh Muslim 1017", arabic: 93...134, english: 0...73)
                        ArticleParagraph(articleMarkdown: "The “good practice” was charity, which Allah had already legislated; the man was the first to act, and the others followed. So **sanna** here means to be the first to do, or to revive, a legislated deed. Three points confirm it. The hadith says “in Islam,” and an innovation is not from Islam. The same hadith speaks of an “evil practice,” so the Prophet (peace be upon him) is not authorising whatever people call good; the Sharee‘ah is what decides which is which. And the same Prophet said “every innovation is misguidance” in the same religion; his words do not contradict each other, so the one is understood in the light of the other. Ibn al-Uthaymeen (may Allah have mercy on him) explains the hadith this way in al-Ibdaa‘ fi Kamaal ash-Shar‘.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Worship is what Allah legislated. Anything added to it, however sincere, is a claim that the religion was incomplete, and the Prophet said every such addition is misguidance. The safe road is the one he and his Companions walked.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleParagraph(articleMarkdown: "**Bid‘ah (بِدعَة)**: from the root ب-د-ع, **bada‘a**, to originate a thing with no prior example. From the same root Allah is named **al-Badee‘ (البَدِيع)**, who brought the heavens and the earth into being with no model before Him:")
                        ScriptureQuote(quran: "2:117", words: 0...2)

                        ArticleParagraph(verbatim: "The Quran uses the same root for the Prophet (peace be upon him) only to deny it of him: he was not a novelty among the messengers, and he followed revelation alone:")
                        ScriptureQuote(quran: "46:9", words: 0...18)

                        ArticleParagraph(verbatim: "So the very word carries the idea: originating in the religion belongs to Allah, and the Messenger himself only followed. The religious definition of bid‘ah is the one given in the section above.")

                        ArticleParagraph(articleMarkdown: "**Sunnah (سُنَّة)**: from **sanna**, to lay down a way, and the **sunnah** of a people is their trodden path. In the Sharee‘ah it is the way of the Prophet (peace be upon him): his sayings, actions, and approvals. It is revelation, not opinion:")
                        ScriptureQuote(quran: "53:3-4")

                        ArticleParagraph(articleMarkdown: "When the Salaf said “Sunnah” as the opposite of “bid‘ah,” they meant the whole way of the Prophet and his Companions in belief and worship, which is why the people of that way are called **Ahl as-Sunnah**.")

                        ArticleParagraph(articleMarkdown: "**Muhdath (مُحدَث)** and **ahdatha (أَحدَثَ)**: from **hadatha**, to come into being anew. A **muhdath** is a newly brought thing, and **ahdatha** is to introduce it. This is the very verb of the hadith quoted above, “whoever introduces (ahdatha) into this matter of ours what is not from it, it is rejected” (Saheeh al-Bukhaari 2697, Saheeh Muslim 1718), and the Prophet (peace be upon him) called the worst of matters their **muhdathaat**, their newly invented things.")

                        ArticleParagraph(articleMarkdown: "**Bid‘ah lughawiyyah (بِدعَة لُغَوِيَّة)** and **bid‘ah shar‘iyyah (بِدعَة شَرعِيَّة)**: the linguistic and the religious senses of the word. Linguistically, anything not seen before is a bid‘ah, even a revived Sunnah; religiously, only what has no basis in the Sharee‘ah is a bid‘ah. This distinction is the key to two famous statements. The first is Umar’s “what an excellent bid‘ah this is” about Taraaweeh (Saheeh al-Bukhaari 2010), explained in its own section above. The second is the saying of Imam ash-Shaafi‘i (may Allah have mercy on him) that innovation is of two kinds, praiseworthy and blameworthy, set out with its explanation in the section “Ash-Shaafi‘i and the Two Kinds of Bid‘ah” above: every religious bid‘ah is misguidance, and what agrees with the Sunnah is not a religious bid‘ah at all.")

                        ArticleParagraph(articleMarkdown: "**Bid‘ah mukaffirah (بِدعَة مُكَفِّرَة)** and **bid‘ah mufassiqah (بِدعَة مُفَسِّقَة)**: an innovation whose content is itself disbelief, such as denying that Allah knew and decreed all things before they happen, and an innovation that is a sin short of disbelief, such as an invented form of dhikr. When the first deniers of the Decree appeared, Ibn Umar (may Allah be pleased with them both) said:")
                        ScriptureQuote(hadith: "muslim:8a", cite: "Saheeh Muslim 8a", arabic: 132...162, english: 132...223)

                        ArticleParagraph(verbatim: "Judging an innovation to be kufr is one thing; judging a particular person to have left Islam is another, and the second requires that the proof reach him and that no excuse of ignorance, misinterpretation, or compulsion stand in the way. Ahl as-Sunnah are careful here, as the questions above explain.")

                        ArticleParagraph(articleMarkdown: "**Bid‘ah haqeeqiyyah (بِدعَة حَقِيقِيَّة)** and **bid‘ah idaafiyyah (بِدعَة إِضَافِيَّة)**: ash-Shaatibi’s division in al-I‘tisaam. The **real** innovation has no basis in the Sharee‘ah at all, like the monasticism of the Christians:")
                        ScriptureQuote(quran: "57:27", words: 18...30)

                        ArticleParagraph(articleMarkdown: "The **relative** innovation is legislated in its origin but invented in its manner, time, number, or place: dhikr is legislated, but dhikr chanted in unison at a fixed count on a fixed night is not. Most innovations in the Muslim world are of this second kind, and ash-Shaatibi explains that they are still innovations, because the added specification is itself a claim about the religion that the Lawgiver never made.")

                        ArticleParagraph(articleMarkdown: "**Maslahah mursalah (مَصلَحَة مُرسَلَة)**: an unrestricted benefit, a means that the texts neither commanded nor forbade in particular, adopted to protect what the Sharee‘ah does demand. Ash-Shaatibi separates it from bid‘ah in al-I‘tisaam: it belongs to means, not to worship, and it serves an established objective. The clearest example is the gathering of the written Quran into one Mushaf under Abu Bakr and Uthmaan, explained in the questions above. Another is that when the people became many, Uthmaan (may Allah be pleased with him) added a call before the Friday prayer:")
                        ScriptureQuote(hadith: "bukhari:912", cite: "Saheeh al-Bukhaari 912", arabic: 14...53, english: 0...45)

                        ArticleParagraph(verbatim: "That was the act of a rightly guided caliph whose Sunnah we were commanded to hold to, done as a means of gathering people for a legislated prayer. It is not a licence to invent worship.")

                        ArticleParagraph(articleMarkdown: "**Sunnah hasanah (سُنَّة حَسَنَة)**: a good practice, from the hadith “whoever starts in Islam a good practice” (Saheeh Muslim 1017). Its context settles its meaning: a Companion of the Ansaar was the first to bring a purse of silver in charity after the Prophet (peace be upon him) had urged the people, and the rest followed him. So the good practice was the reviving of a legislated act, charity, not the invention of a new one. The hadith is quoted and explained in the questions above.")

                        ArticleParagraph(articleMarkdown: "**Ahl al-Bid‘ah (أَهل البِدعَة)**: the people of innovation, those whose way in belief or worship departs from the way of the Prophet and his Companions, in contrast to Ahl as-Sunnah wal-Jamaa‘ah. The Salaf used the term for groups like the Khawaarij, the Qadariyyah, and the Murji’ah, while still distinguishing between a caller to innovation and an ordinary Muslim who fell into something without knowing.")

                        ArticleParagraph(articleMarkdown: "**The three praised generations (القُرُون المُفَضَّلَة)**: the Companions, the Taabi‘oon, and those who followed them. The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:2652", cite: "Saheeh al-Bukhaari 2652", arabic: 29...37, english: 4...23)
                        ScriptureQuote(quran: "9:100", words: 0...12)

                        ArticleParagraph(verbatim: "Their practice is the measure of the Sunnah, and their leaving of a thing, when they could have done it, is itself a proof that leaving it is the Sunnah. This is the principle Ibn Taymiyyah built on in Iqtidaa’ as-Siraat al-Mustaqeem.")

                        ArticleParagraph(articleMarkdown: "**Ittibaa‘ (اتِّبَاع)**: following, from **tabi‘a**, to walk behind. It is the opposite of **ibtidaa‘**, innovating. Allah commanded:")
                        ScriptureQuote(quran: "7:3", words: 0...10)

                        ArticleParagraph(articleMarkdown: "**Istihsaan (استِحسَان)**: deeming a thing good. Among the jurists it is a technical term for preferring one ruling over an apparent analogy because of a stronger proof, and its scope is disputed. In the mouth of the innovator it means “I see this as good,” the very word Imam Maalik answered in the section “Why it is so serious” above. Ash-Shaafi‘i (may Allah have mercy on him) said, as al-Ghazaali reports in al-Mustasfa:")
                        ScriptureQuote(text: "“Whoever deems a thing good has legislated” (al-Ghazaali, al-Mustasfa, quoting ash-Shaafi‘i; ash-Shaafi‘i's own wording in ar-Risaalah is “whoever deems good has sought to be a legislator”).", arabic: "مَنِ استَحسَنَ فَقَد شَرَّعَ", dimmed: true)
                        ArticleParagraph(verbatim: "In worship, what is good is what Allah and His Messenger called good, and nothing else.")
                    }
                }

                ArticleSourcesSection(article: "BidahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Bid‘ah")
        .englishArticle().selectableArticleList(article: "BidahView")
    }
}

struct MawlidView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Prophet, his Companions, the Successors, and the four imams never celebrated his birthday. The mawlid appeared centuries later, so it is an innovation, and love for the Prophet is shown by following him.")
                }

                Section(header: ArticleHeader("WHAT IS THE MAWLID?")) {
                    ArticleParagraph(articleMarkdown: "The **Mawlid (المَولِد)** is the celebration of the Prophet’s birthday (peace be upon him), usually on the twelfth of Rabee‘ al-Awwal (رَبِيع الأَوَّل, the third month of the Hijri year), with gatherings, poems in his praise, food, and sometimes standing when his birth is mentioned.")

                    ArticleParagraph(verbatim: "Loving him is an obligation and a condition of faith:")
                    ScriptureQuote(hadith: "bukhari:15", cite: "Saheeh al-Bukhaari 15, Saheeh Muslim 44a", arabic: 40...51, english: 4...22)

                    ArticleParagraph(verbatim: "The question is not whether to love him, but whether this celebration is part of the religion he brought.")
                }

                Section(header: ArticleHeader("THE HISTORY")) {
                    ArticleParagraph(articleMarkdown: "For more than three hundred years after the Prophet’s passing, no Muslim celebrated his birthday: not the Companions who loved him most, not the Taabi‘oon, not Abu Haneefah, Maalik, ash-Shaafi‘i, or Ahmad. The first to hold it were the **Fatimids (the Ubaydi Ismaa‘eeli Shia)** who ruled Egypt in the fourth century AH; the historian al-Maqreezi lists the mawlid of the Prophet among the festivals they instituted alongside mawlids for Ali, Faatimah, and their own ruler (al-Khitat 1/490). It reached the Sunni world when the ruler of Irbil, al-Muzaffar (d. 630 AH), began holding lavish yearly public celebrations early in the seventh century AH, which Ibn Katheer describes in al-Bidaayah wan-Nihaayah (13/137).")

                    ArticleParagraph(verbatim: "The Maaliki jurist Taj ad-Deen al-Faakihaani (d. 734 AH) wrote a treatise on it and said:")
                    ScriptureQuote(text: "“I know of no basis for this mawlid in the Book or the Sunnah, and its practice is not reported from any of the scholars of the nation who are the examples in the religion” (al-Faakihaani, al-Mawrid fi Amal al-Mawlid).", arabic: "لَا أَعلَمُ لِهَذَا المَولِدِ أَصلًا فِي كِتَابٍ وَلَا سُنَّةٍ، وَلَا يُنقَلُ عَمَلُهُ عَن أَحَدٍ مِن عُلَمَاءِ الأُمَّةِ الَّذِينَ هُمُ القُدوَةُ فِي الدِّينِ", dimmed: true)

                    ArticleParagraph(verbatim: "Shaykh al-Islam Ibn Taymiyyah made the decisive point: the Salaf had every reason and every ability to celebrate it, and did not, so leaving it must be the Sunnah (Iqtidaa’ as-Siraat al-Mustaqeem 2/123).")
                }

                Section(header: ArticleHeader("THE EVIDENCE")) {
                    ArticleParagraph(verbatim: "An act of worship needs a proof; the mawlid has none. And the Prophet (peace be upon him) closed the door to it in advance:")
                    ScriptureQuote(hadith: "bukhari:2697", cite: "Saheeh al-Bukhaari 2697, Saheeh Muslim 1718", arabic: 29...38, english: 4...22)

                    ScriptureQuote(hadith: "muslim:867a", cite: "Saheeh Muslim 867", arabic: 73...78, english: 102...114)

                    ArticleParagraph(verbatim: "The date itself is not even certain. What is established is the day of the week: Monday. And the Prophet (peace be upon him) told us what to do about it, and it was not a festival:")
                    ScriptureQuote(hadith: "muslim:1162e", cite: "Saheeh Muslim 1162", arabic: 41...45, english: 0...14)

                    ArticleParagraph(verbatim: "So the Sunnah of honouring his birth is to fast on Mondays, every week of the year. Whoever wants to mark his birth has been shown how.")

                    ArticleParagraph(verbatim: "The Muslims have two festivals only. When the Prophet (peace be upon him) came to Madinah and found the people celebrating two days from before Islam, he said:")
                    ScriptureQuote(hadith: "abudawud:1134", cite: "Sunan Abi Daawood 1134; graded saheeh by al-Albaani", arabic: 45...55, english: 50...71)
                }

                Section(header: ArticleHeader("HOW TO LOVE HIM")) {
                    ArticleParagraph(verbatim: "Allah told the one who claims to love Him how that love is proven, and the same measure applies to loving His Messenger:")
                    ScriptureQuote(quran: "3:31", words: 0...10)

                    ArticleParagraph(verbatim: "The Companions loved him more than anyone ever will, and they showed it by following him, learning his Sunnah, spreading his religion, and sending blessings upon him. Whoever does that every day has honoured his birth more than any gathering could. And the Prophet (peace be upon him) warned against the very exaggeration in praising him that the mawlid poems tend toward:")
                    ScriptureQuote(hadith: "bukhari:3445", cite: "Saheeh al-Bukhaari 3445", arabic: 36...49, english: 6...35)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is the Mawlid not simply love of the Prophet?**")
                        ArticleParagraph(verbatim: "Love of him is obligatory, and the measure of love is following, as the verse quoted above says: if you love Allah, follow the Messenger. The Prophet (peace be upon him) made his love the first of the three things that give faith its sweetness:")
                        ScriptureQuote(hadith: "bukhari:16", cite: "Saheeh al-Bukhaari 16", arabic: 26...59, text: "“Whoever possesses the following three qualities will have the sweetness (delight) of faith: The one to whom Allah and His Apostle becomes dearer than anything else. Who loves a person and he loves him only for Allah's sake. Who hates to revert to Atheism (disbelief) as he hates to be thrown into the fire”")
                        ArticleParagraph(verbatim: "Nobody loved him more than the Companions, who gave their wealth and blood for him and wept at his mention, and not one of them held a birthday for him in the decades they lived after his death. Their love went into obedience, learning, and spreading his religion. Ibn Taymiyyah was fair here: he wrote in Iqtidaa’ as-Siraat al-Mustaqeem that some who hold the Mawlid may be rewarded for their good intention and their veneration of the Messenger, but not for the innovation itself, and that the Salaf, who loved him more, did not do it though they could have. So the question is not whether you love him, but whether you love him in the way he asked to be loved.")

                        ArticleParagraph(articleMarkdown: "**Did the Prophet not mark his birthday by fasting on Monday?**")
                        ArticleParagraph(verbatim: "Yes, and that is the whole point: he marked it weekly, by fasting, as quoted above (Saheeh Muslim 1162). That is the Sunnah for the day of his birth, and it is available every week. The Mawlid replaces it with a yearly festival on which no fast is prescribed; it takes the day he honoured with worship and honours it with a feast he never held.")

                        ArticleParagraph(articleMarkdown: "**Did some scholars, like as-Suyooti and Ibn Hajar, not permit it?**")
                        ArticleParagraph(verbatim: "Yes, and honesty requires saying so. As-Suyooti wrote a treatise, Husn al-Maqsid fi Amal al-Mawlid, in which he counted it a good innovation if it is free of evils, and he quoted a verdict of Ibn Hajar to the same effect, reasoned from the Prophet’s fasting of Aashoora in gratitude for the saving of Moosa. Ahl as-Sunnah answer with respect for both men and with the proofs. There is no good innovation in worship, by the Prophet’s own words and by Ibn Umar’s. The three best generations, who had every reason to do it, did not. Imam Maalik’s words quoted on the Bid‘ah page apply exactly: what was not religion on the day the religion was completed is not religion today. The analogy with Aashoora fails, because the Aashoora fast is itself an act the Prophet legislated, while gratitude for his birth was expressed by him in the Monday fast, and we cannot legislate a second expression he did not. And this is not a new position: it is the verdict of al-Faakihaani quoted above, of Ibn al-Hajj in al-Madkhal, of ash-Shaatibi, and of Ibn Taymiyyah, and in our era of Ibn Baaz, al-Albaani, and Ibn al-Uthaymeen (may Allah have mercy on them all).")

                        ArticleParagraph(articleMarkdown: "**Is the date of his birth even known?**")
                        ArticleParagraph(verbatim: "It is not. Ibn Katheer gathers the reports in al-Bidaayah wan-Nihaayah: the second of Rabee‘ al-Awwal, the eighth, the tenth, the twelfth, and other dates were all said, while the year of the Elephant is the established view. What the most widespread report does place on the twelfth of Rabee‘ al-Awwal is his death, in the eleventh year after the Hijrah. So the Mawlid gathers people in celebration on a date that is uncertain for his birth and widely reported for his passing.")

                        ArticleParagraph(articleMarkdown: "**Is attending a Mawlid haraam, and is it shirk?**")
                        ArticleParagraph(verbatim: "Attending it as a religious celebration is taking part in an innovation, and that is forbidden, though it is not shirk in itself. It becomes shirk in what is often said and sung there: when the Prophet (peace be upon him) is called upon, asked for refuge, help, or forgiveness, as in the line of the Burdah (البُردَة, the Mantle Ode of al-Booseeri, d. around 695 AH) quoted in the key terms. Allah forbade invoking anyone alongside Him in the verse quoted there, and He said:")
                        ScriptureQuote(quran: "10:106")
                        ArticleParagraph(verbatim: "So there are degrees: a seerah (سِيرَة, from س-ي-ر, to travel a road: the account of the Prophet’s life) lesson held on that day with no rites is a lesser matter than a gathering built around the date, and both are far from the poems that call upon him. The Muslim avoids all of it and keeps the Prophet’s honour where he placed it.")

                        ArticleParagraph(articleMarkdown: "**Is it a bid‘ah to study the seerah, or to recite poetry praising him?**")
                        ArticleParagraph(verbatim: "No. Both are good at any time of the year, and both were done in his presence. Hassaan ibn Thaabit recited poetry in the Prophet’s mosque, and when Umar looked at him with disapproval, Hassaan said:")
                        ScriptureQuote(hadith: "bukhari:3212", cite: "Saheeh al-Bukhaari 3212, Saheeh Muslim 2485", arabic: 21...55, english: 19...83)
                        ArticleParagraph(verbatim: "The bid‘ah is not the seerah and not the poetry; it is the yearly festival, its fixed date, and its rites, and the exaggeration in the poems that turns praise into invocation.")

                        ArticleParagraph(articleMarkdown: "**Do we have festivals?**")
                        ArticleParagraph(verbatim: "Two, given by Allah in place of the festivals of the days of ignorance, as the hadith of Sunan Abi Daawood 1134 above says. When Abu Bakr objected to two girls singing in the Prophet’s house on the day of Eid, the Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:952", cite: "Saheeh al-Bukhaari 952", arabic: 65...73, english: 56...70)
                        ArticleParagraph(verbatim: "A festival is a mark of a people’s religion, and ours were fixed by revelation. Adding a third, whatever it is named after, is adding to the religion.")

                        ArticleParagraph(articleMarkdown: "**What about the dream of Abu Lahab being relieved for freeing Thuwaybah?**")
                        ArticleParagraph(verbatim: "Some cite a report in Saheeh al-Bukhaari: Urwah said that Thuwaybah was a slave of Abu Lahab whom he freed, and she suckled the Prophet (peace be upon him); after Abu Lahab died, one of his family saw him in a dream in a wretched state, and he said:")
                        ScriptureQuote(hadith: "bukhari:5101", cite: "Saheeh al-Bukhaari 5101", arabic: 143...152, english: 182...218)
                        ArticleParagraph(verbatim: "Ibn Hajar notes in Fath al-Baari that this is a mursal report from Urwah, and in any case it is a dream about a disbeliever, and a dream is not a proof of legislation. Allah says of the deeds of those who died in disbelief:")
                        ScriptureQuote(quran: "25:23")
                        ArticleParagraph(verbatim: "And even taken at face value, the report says nothing about a birthday or a yearly festival; Ibn Sa‘d records that Abu Lahab freed Thuwaybah long after, following the Hijrah (at-Tabaqaat 1/108, noted by Ibn Hajar in Fath al-Baari 9/145), and the first generations never drew that from it.")

                        ArticleParagraph(articleMarkdown: "**Is it not just a gathering with food and the seerah, not worship?**")
                        ArticleParagraph(verbatim: "If it were purely a custom, no one would tie it to that date, count it a religious occasion, hope for reward in it, or call the one who leaves it deficient in love. Those are the marks of worship, and worship needs a proof. Ibn Taymiyyah notes in Iqtidaa’ as-Siraat al-Mustaqeem that taking the Prophet’s birthday as a festival also resembles the Christians in what they made of the birth of Eesa (peace be upon him), and he explains there that a recurring gathering fixed to a date is an ‘id (عِيد, from ع-و-د, to return, because it comes back every year) in the Sharee‘ah whatever it is called. Food and seerah are good on any day; it is the appointment that makes the innovation.")

                        ArticleParagraph(articleMarkdown: "**What if my family or community holds it?**")
                        ArticleParagraph(verbatim: "Keep your ties and your kindness, and keep away from the rites. Allah commanded the child of parents who even call to shirk:")
                        ScriptureQuote(quran: "31:15", words: 13...16)
                        ArticleParagraph(verbatim: "Do not attend the gathering as a religious celebration and do not join its chants or its standing; but visit, help, and explain gently when the door opens. Show them the Sunnah in your own practice: fast on Mondays, send blessings upon him often, and study his life with them at other times, so that they see that leaving the Mawlid is not leaving his love.")

                        ArticleParagraph(articleMarkdown: "**How do we honour him correctly?**")
                        ArticleParagraph(verbatim: "By the four things Allah and His Messenger prescribed. Loving him above all people, as in the hadith quoted at the top of this page (Saheeh al-Bukhaari 15). Following him, as the verse quoted above commands (Quran 3:31). Sending blessings upon him, as Allah commanded in the verse quoted in the key terms (Quran 33:56), which carries a reward he described himself:")
                        ScriptureQuote(hadith: "muslim:384", cite: "Saheeh Muslim 384", arabic: 54...62, english: 16...28)
                        ArticleParagraph(verbatim: "And defending and spreading his Sunnah, so that people worship Allah as he taught. Whoever keeps these four has given him his right in the way he himself prescribed, and has stayed on the road his Companions walked.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is the Mawlid not simply love of the Prophet?**")
                        ArticleParagraph(verbatim: "Love of him is obligatory, and the measure of love is following, as the verse quoted above says: if you love Allah, follow the Messenger. The Prophet (peace be upon him) made his love the first of the three things that give faith its sweetness:")
                        ScriptureQuote(hadith: "bukhari:16", cite: "Saheeh al-Bukhaari 16", arabic: 26...59, text: "“Whoever possesses the following three qualities will have the sweetness (delight) of faith: The one to whom Allah and His Apostle becomes dearer than anything else. Who loves a person and he loves him only for Allah's sake. Who hates to revert to Atheism (disbelief) as he hates to be thrown into the fire”")
                        ArticleParagraph(verbatim: "Nobody loved him more than the Companions, who gave their wealth and blood for him and wept at his mention, and not one of them held a birthday for him in the decades they lived after his death. Their love went into obedience, learning, and spreading his religion. Ibn Taymiyyah was fair here: he wrote in Iqtidaa’ as-Siraat al-Mustaqeem that some who hold the Mawlid may be rewarded for their good intention and their veneration of the Messenger, but not for the innovation itself, and that the Salaf, who loved him more, did not do it though they could have. So the question is not whether you love him, but whether you love him in the way he asked to be loved.")

                        ArticleParagraph(articleMarkdown: "**Did some scholars, like as-Suyooti and Ibn Hajar, not permit it?**")
                        ArticleParagraph(verbatim: "Yes, and honesty requires saying so. As-Suyooti wrote a treatise, Husn al-Maqsid fi Amal al-Mawlid, in which he counted it a good innovation if it is free of evils, and he quoted a verdict of Ibn Hajar to the same effect, reasoned from the Prophet’s fasting of Aashoora in gratitude for the saving of Moosa. Ahl as-Sunnah answer with respect for both men and with the proofs. There is no good innovation in worship, by the Prophet’s own words and by Ibn Umar’s. The three best generations, who had every reason to do it, did not. Imam Maalik’s words quoted on the Bid‘ah page apply exactly: what was not religion on the day the religion was completed is not religion today. The analogy with Aashoora fails, because the Aashoora fast is itself an act the Prophet legislated, while gratitude for his birth was expressed by him in the Monday fast, and we cannot legislate a second expression he did not. And this is not a new position: it is the verdict of al-Faakihaani quoted above, of Ibn al-Hajj in al-Madkhal, of ash-Shaatibi, and of Ibn Taymiyyah, and in our era of Ibn Baaz, al-Albaani, and Ibn al-Uthaymeen (may Allah have mercy on them all).")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Not one of the first three generations celebrated the mawlid; it came from the Fatimids centuries later. Love of the Prophet is proven by following him, and he himself showed how to mark the day of his birth: by fasting on Mondays.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleParagraph(articleMarkdown: "**Mawlid (مَولِد)**: from **walada**, to give birth. The **mawlid** is the time or place of a birth, so the Prophet’s mawlid is simply his birth-day; the plural is **mawaalid (مَوَالِد)**. The word later came to mean the celebration held for it, and the poems and gatherings of that celebration.")

                        ArticleParagraph(articleMarkdown: "**Rabee‘ al-Awwal (رَبِيع الأَوَّل)**: the third month of the Hijri year, named in the old Arabian calendar for the first spring. The Prophet (peace be upon him) was born in it, arrived at Madinah in it after the Hijrah, and died in it in the eleventh year after the Hijrah.")

                        ArticleParagraph(articleMarkdown: "**Seerah (سِيرَة)**: from **saara**, to travel, so a person’s seerah is the course of his life. The Prophet’s seerah is his biography, preserved by Ibn Ishaaq (d. 150 AH) as edited by Ibn Hishaam, and studied by later imams such as Ibn Katheer in al-Bidaayah wan-Nihaayah and Ibn al-Qayyim in Zad al-Ma‘aad. Studying it is worship at any time of the year, because Allah made him the pattern to follow:")
                        ScriptureQuote(quran: "33:21")

                        ArticleParagraph(articleMarkdown: "**The Fatimids (الفَاطِمِيُّون)**, called by the scholars **the Ubaydiyyoon (العُبَيدِيُّون)** after their founder Ubaydullah: Ismaa‘eeli Shia rulers of Egypt from 358 to 567 AH, and the first to institute the Mawlid, as The History below sets out from al-Maqreezi. They claimed descent from Faatimah (may Allah be pleased with her), but the scholars of lineage denied it; in 402 AH the leading scholars and genealogists in Baghdaad, including the Alawi shareefs ar-Radi and al-Murtada, signed a written declaration that the claim was false, as Ibn Katheer records in al-Bidaayah wan-Nihaayah under the events of that year. So the yearly birthday celebration began neither among the Companions nor among the imams, but in a state whose rulers made festivals of their own, the caliph’s own birthday among them.")

                        ArticleParagraph(articleMarkdown: "**Irbil and al-Muzaffar (إِربِل)**: Irbil is a town in the north of Iraq. Its ruler, al-Malik al-Muzaffar Kokburi ibn Zayn ad-Deen Ali (d. 630 AH), brother-in-law of Salaah ad-Deen, was the first Sunni ruler known to hold a public Mawlid, with lavish feasts and gifts, as The History below records from Ibn Katheer and as Ibn Khallikaan, who was born in Irbil, describes at length in Wafayaat al-A‘yaan. The scholar Ibn Dihyah composed a book for him on the Prophet’s birth, at-Tanweer fi Mawlid as-Siraaj al-Muneer, and was rewarded with a thousand dinars, as Ibn Khallikaan records. So the celebration entered the Sunni world in the seventh century, by the choice of a king, six hundred years after the Prophet (peace be upon him).")

                        ArticleParagraph(articleMarkdown: "**Madeeh (مَدِيح)** and **qaseedah (قَصِيدَة)**: praise, and the ode in which it is sung. Praising the Prophet (peace be upon him) truthfully is permissible and was done in his presence by Hassaan ibn Thaabit (may Allah be pleased with him). The bound is the hadith quoted above forbidding the exaggeration the Christians fell into with the son of Maryam, and the Mawlid odes very often cross it.")

                        ArticleParagraph(articleMarkdown: "**The Burdah (البُردَة)**: the most famous Mawlid ode, by al-Booseeri (d. around 695 AH). It contains beautiful lines and it contains this: “O noblest of creation, I have none to seek refuge with but you at the coming of the all-encompassing calamity.” To seek refuge in a created being from the calamities of the Day of Judgement is a request that belongs to Allah alone, and the Quran forbids it in the plainest words:")
                        ScriptureQuote(quran: "72:18")

                        ArticleParagraph(articleMarkdown: "**Qiyaam (قِيَام)**: standing up when the moment of his birth is mentioned in the recitation of the Mawlid, often with a chant of greeting, as if he were entering the room. There is no basis for it in the Sunnah or in the practice of the Companions. Ibn al-Hajj (d. 737 AH), who wrote at length against the Mawlid in al-Madkhal, criticised the singing, the instruments, and the mixing of men and women in the gatherings of his time as evils added to the innovation.")

                        ArticleParagraph(articleMarkdown: "**Salawaat (صَلَوَات)**: sending blessings upon him, the honouring that Allah Himself legislated, for all times and places:")
                        ScriptureQuote(quran: "33:56")

                        ArticleParagraph(articleMarkdown: "**“Bid‘ah hasanah” (بِدعَة حَسَنَة)**: a “good innovation,” the justification usually given for the Mawlid: that it is new, but good. Ahl as-Sunnah answer that there is no good innovation in worship, because the Prophet (peace be upon him) said every innovation is misguidance, and Ibn Umar said the same even if the people see it as good (al-Laalakaa’i 126, quoted on the Bid‘ah page). The full discussion is on that page.")

                        ArticleParagraph(articleMarkdown: "**Eid (عِيد)**: a festival, from **‘aada**, to return, because it returns every year. Ibn Taymiyyah explains in Iqtidaa’ as-Siraat al-Mustaqeem that an ‘id in the Sharee‘ah is any recurring gathering fixed to a time, and that festivals are part of the religion, so no one may add one. That is why a yearly celebration tied to the twelfth of Rabee‘ al-Awwal is a religious matter even when it is called a custom.")

                        ArticleParagraph(articleMarkdown: "**Monday fasting (صَوم الاثنَين)**: the one act the Prophet (peace be upon him) connected to his birth, weekly and by fasting, in the hadith quoted above (Saheeh Muslim 1162). It is the Sunnah of honouring his birth, and it is what the Companions did.")
                    }
                }

                ArticleSourcesSection(article: "MawlidView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Mawlid")
        .englishArticle().selectableArticleList(article: "MawlidView")
    }
}

// MARK: - The Evil Eye

/// The evil eye as Ahl as-Sunnah hold it (Abu, 2026-11-14: "Add evil eye pillars Salafi Sunni what it is
/// what it isn't"): real by the Quran and the Sunnah, a cause that harms only by Allah's decree, and
/// neither a superstition nor something a bead, a hand, or a thread turns away. The practical side
/// (what to say, the daily refuges, the washing) is the How-to guide `EvilEyeGuideView`, which this
/// page opens instead of repeating.
struct EvilEyeView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "EvilEyeView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Evil Eye")
        .englishArticle().selectableArticleList(article: "EvilEyeView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the evil eye is real. The Prophet (peace be upon him) said so in those words, and Ahl as-Sunnah have always affirmed it. It is harm that reaches a person, by Allah’s permission and decree, from a look of envy, or of admiration in which Allah is not remembered. It is not a power of its own, not a reason to fear people or hide every blessing, and not something a bead, a hand, a thread, or smoke can turn away. What protects from it and cures it is what the Prophet taught: asking Allah to bless what you admire, the words of refuge, ruqyah, the washing of the one who gave it, and trust in Allah."),
        ]),
        ArticleSection("WHAT IS THE EVIL EYE?", [
            .markdown("**Al-‘ayn (العَين)** is the Arabic word for the eye, and the name the Prophet (peace be upon him) gave to the harm that comes through it. The one it comes from is the **aa’in (عَائِن)**; the one it strikes is the **ma‘een (مَعِين)**, also called the **ma‘yoon (مَعيُون)**."),
            .text("Ibn Hajar (may Allah have mercy on him) defined it in Fath al-Baari:"),
            .quote(text: "“The eye is a look of admiration mixed with envy, from one of foul nature, by which harm comes to the one looked at” (Ibn Hajar, Fath al-Baari 10/200).", arabic: "وَالعَينُ نَظَرٌ بِاستِحسَانٍ مَشُوبٌ بِحَسَدٍ مِن خَبِيثِ الطَّبعِ يَحصُلُ لِلمَنظُورِ مِنهُ ضَرَرٌ", dimmed: true),
            .text("That is its usual form. As the sections below show, it can also come from plain admiration with no envy in it, from a person who loves the one he looks at, and from a person upon himself. And it harms only when Allah permits it to."),
        ]),
        ArticleSection("IT IS REAL: THE QURAN", [
            .text("Allah said of the disbelievers of Quraysh and His Prophet (peace be upon him):"),
            .ayah("68:51", words: 0...5),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) reports from Ibn Abbaas, Mujaahid, and others that it means they would pierce him with their looks, that is, strike him with the eye, envying him out of their hatred, were it not for Allah’s protection of him. He then said:")),
            .longOnly(.quote(text: "“In this ayah is evidence that the eye strikes and that its effect is real, by the command of Allah, as the hadiths narrated through many routes have stated” (Ibn Katheer, Tafseer al-Quran al-Azeem 8/201, on 68:51).", arabic: "وَفِي هَذِهِ الآيَةِ دَلِيلٌ عَلَى أَنَّ العَينَ إِصَابَتُهَا وَتَأثِيرُهَا حَقٌّ، بِأَمرِ اللَّهِ عَزَّ وَجَلَّ، كَمَا وَرَدَت بِذَلِكَ الأَحَادِيثُ المَروِيَّةُ مِن طُرُقٍ مُتَعَدِّدَةٍ كَثِيرَةٍ", dimmed: true)),
            .shortOnly(.text("Ibn Katheer (may Allah have mercy on him) reports from Ibn Abbaas, Mujaahid, and others that it means they would pierce him with their looks, that is, strike him with the eye, envying him out of their hatred, were it not for Allah’s protection of him.")),
            .longOnly(.text("Ya‘qoob (peace be upon him) sent his sons back to Egypt with this instruction:")),
            .longOnly(.ayah("12:67", words: 1...10)),
            .longOnly(.text("Ibn Abbaas, Muhammad ibn Ka‘b, Mujaahid, ad-Dahhaak, Qataadah, and as-Suddi said that he feared the eye for them, because they were handsome and of fine appearance (Ibn Katheer, Tafseer al-Quran al-Azeem 4/400). Notice what he said in the same breath: that he could not avail them against Allah at all, and that the decision is only for Allah. Ibn Katheer explained: this precaution does not turn back the decree of Allah. Ya‘qoob took the means and placed his trust in Allah, and Allah praised him for it. The precaution changed nothing of what He had decreed; it answered a need in Ya‘qoob’s soul, which the scholars of tafseer said was to ward the eye off his sons; and he was a man of knowledge because of what Allah had taught him:")),
            .longOnly(.ayah("12:68", words: 6...24)),
            .text("And Allah commanded His Prophet, and every believer after him, to seek refuge in Him from the envier:"),
            .ayah("113:1-5", words: 18...22),
        ]),
        ArticleSection("IT IS REAL: THE SUNNAH", [
            .markdown("The Prophet (peace be upon him) stated it in two words, **al-‘aynu haqq**:"),
            .hadith("bukhari:5740", cite: "Saheeh al-Bukhaari 5740, Saheeh Muslim 2187", arabic: 28...29, english: [4...12]),
            .hadith("muslim:2188", cite: "Saheeh Muslim 2188", arabic: 43...54, english: [0...45]),
            .longOnly(.text("He saw its mark on the face of a girl in the house of Umm Salamah (may Allah be pleased with her) and said:")),
            .longOnly(.hadith("bukhari:5739", cite: "Saheeh al-Bukhaari 5739, Saheeh Muslim 2197", arabic: 55...59, english: [18...32])),
            .longOnly(.text("When he himself fell ill, Jibreel (peace be upon him) recited over him and named the eye of the envier:")),
            .longOnly(.hadith("muslim:2186", cite: "Saheeh Muslim 2186", arabic: 38...56, english: [12...52])),
            .text("And it happened in front of the Companions. Sahl ibn Hunayf (may Allah be pleased with him) was bathing when Aamir ibn Rabee‘ah, a Companion who had fought at Badr, saw him and said that he had never seen skin like it. Sahl fell to the ground on the spot. The Prophet (peace be upon him) was told, asked whom they suspected, and when Aamir was named, said:"),
            .hadith("ibnmajah:3509", cite: "Sunan Ibn Maajah 3509; graded saheeh by al-Albaani", arabic: 67...80, english: [63...85]),
            .text("Then he had Aamir wash, the water was poured over Sahl, and Sahl went on his way with nothing wrong with him, as Maalik narrates in al-Muwatta."),
            .longOnly(.text("An-Nawawi opens his commentary on these hadiths with the words of al-Maaziri:")),
            .longOnly(.quote(text: "“The great body of the scholars took this hadith at its apparent meaning and said: the eye is real. Groups of the innovators denied it” (al-Maaziri, in an-Nawawi’s Sharh Saheeh Muslim 14/171).", arabic: "أَخَذَ جَمَاهِيرُ العُلَمَاءِ بِظَاهِرِ هَذَا الحَدِيثِ وَقَالُوا: العَينُ حَقٌّ، وَأَنكَرَهُ طَوَائِفُ مِنَ المُبتَدِعَةِ", dimmed: true)),
            .longOnly(.callout("Ibn al-Qayyim said of those who dismiss the eye as imagination that they have little share of revelation or of reason, and that the thinking people of every nation, whatever their religion, do not deny it, though they differ over how it works (Zad al-Ma‘aad 4/152). What the Prophet (peace be upon him) reported is believed, whether or not the mind can trace its workings.", title: "The Creed of Ahl as-Sunnah", icon: "checkmark.seal.fill")),
        ]),
        ArticleSection("WHAT IT IS", [
            .checklist([
                "**Real.** Affirmed by the Quran, by the Prophet’s own words, and by Ahl as-Sunnah in every generation.",
                "**A cause, not a creator.** Allah made it a cause of harm, as He made fire a cause of burning, and it does nothing except by His permission.",
                "**Born of envy or of admiration.** A look, or a word of praise, with no remembrance of Allah behind it.",
                "**Possible from anyone.** An enemy or someone who loves you, a stranger or a relative, a righteous person, even you yourself.",
                "**Preventable and curable.** By the means the Prophet (peace be upon him) taught, not by charms or rituals.",
            ], title: "What the Evil Eye Is", icon: "checkmark.circle.fill"),
            .markdown("**It comes with admiration, even without envy.** Aamir ibn Rabee‘ah did not hate Sahl or wish him harm. He admired what he saw and did not ask Allah to bless it. Ibn Hajar drew the rule from that story:"),
            .quote(text: "“The eye can come with admiration even without envy, even from a man who loves, and from a righteous man; and whoever is pleased by a thing should hasten to pray for blessing for what pleased him, and that is a ruqyah from him” (Ibn Hajar, Fath al-Baari 10/205).", arabic: "وَأَنَّ العَينَ تَكُونُ مَعَ الإِعجَابِ وَلَو بِغَيرِ حَسَدٍ، وَلَو مِنَ الرَّجُلِ المُحِبِّ، وَمِنَ الرَّجُلِ الصَّالِحِ، وَأَنَّ الَّذِي يُعجِبُهُ الشَّيءُ يَنبَغِي أَن يُبَادِرَ إِلَى الدُّعَاءِ لِلَّذِي يُعجِبُهُ بِالبَرَكَةِ، وَيَكُونُ ذَلِكَ رُقيَةً مِنهُ", dimmed: true),
            .longOnly(.markdown("**A person can strike himself, and what is his own.** Ibn al-Qayyim said that a man may give the eye to himself (Zad al-Ma‘aad 4/154). One narration of the story of Sahl ends with the Prophet (peace be upon him) saying that when one of you sees in his brother, in himself, or in his wealth something that pleases him, he should ask blessing for it, for the eye is real (Musnad Ahmad 15700; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 2572).")),
            .longOnly(.markdown("**It does not need a glance, or an intention.** Ibn al-Qayyim wrote:")),
            .longOnly(.quote(text: "“The effect of the soul of the one who gives the eye does not depend on seeing. He may be blind, and a thing is described to him, and his soul affects it though he has not seen it” (Ibn al-Qayyim, Zad al-Ma‘aad 4/153).", arabic: "وَنَفسُ العَائِنِ لَا يَتَوَقَّفُ تَأثِيرُهَا عَلَى الرُّؤيَةِ، بَل قَد يَكُونُ أَعمَى، فَيُوصَفُ لَهُ الشَّيءُ فَتُؤَثِّرُ نَفسُهُ فِيهِ وَإِن لَم يَرَهُ", dimmed: true)),
            .longOnly(.text("He went on to say that a man may give it without meaning to, by his nature (Zad al-Ma‘aad 4/154).")),
            .longOnly(.markdown("**It comes from the jinn as well as from people.** Ibn al-Qayyim said the eye is of two kinds, a human eye and a jinn eye, and he cited al-Baghawi’s explanation that “the look” on the girl in Umm Salamah’s house was a look from the jinn (Zad al-Ma‘aad 4/151). Ibn Hajar set that view beside the view that it was from people, and held that the wording takes in both (Fath al-Baari 10/202). Abu Sa‘eed al-Khudri (may Allah be pleased with him) said that the Prophet (peace be upon him) used to seek refuge from the jinn and from the eye of man, until the two surahs of refuge came down and he held to them (Jaami‘ at-Tirmidhi 2058; graded hasan by at-Tirmidhi and saheeh by al-Albaani, while others weakened its chain). An-Nasaa’i’s wording, by the same chain, is “from the eye of the jinn and the eye of mankind” (Sunan an-Nasaa’i 5494; graded saheeh by al-Albaani, and weakened by others).")),
            .longOnly(.markdown("**How it travels is unseen.** The texts tell us that it happens and what to do about it. They do not describe the mechanism, the believer does not need it, and no one may speak about it without knowledge.")),
        ]),
        ArticleSection("WHAT IT IS NOT", [
            .checklist([
                "**Not a power beside Allah.** It cannot outrun, change, or add to what He has decreed.",
                "**Not a superstition.** It rests on revelation, not folklore, and it is not denied because the mind cannot trace it.",
                "**Not the same as envy.** Envy is a disease of the heart. The eye is a harm that may follow it, or come without it.",
                "**Not turned away by charms.** No bead, glass eye, hand, thread, horseshoe, or smoke protects from it.",
                "**Not an omen.** Reading bad luck into a day, a number, a bird, or a chance sight has no place in Islam.",
                "**Not the cause of every hardship.** Illness, loss, and failure have ordinary causes, and all of them are tests from Allah.",
                "**Not a licence to accuse.** Baseless suspicion is a sin of its own.",
                "**Not a reason to live in fear.** The believer takes the Prophet’s means and trusts Allah.",
            ], title: "What the Evil Eye Is Not", icon: "xmark.circle.fill"),
            .text("The four sections that follow take these up with their proofs."),
        ]),
        ArticleSection("NOT A POWER BESIDE ALLAH’S DECREE", [
            .markdown("The strongest thing the Prophet (peace be upon him) said about the eye is itself a statement about **al-qadar (القَدَر)**, the decree: “if anything would precede the destiny it would be the influence of an evil eye” (Saheeh Muslim 2188, above). If anything would: so nothing does. Asmaa’ bint Umays (may Allah be pleased with her) asked him whether she should seek ruqyah for the sons of Ja‘far, whom the eye struck quickly, and he answered in the same words:"),
            .hadith("ibnmajah:3510", cite: "Sunan Ibn Maajah 3510; graded saheeh by al-Albaani", arabic: 39...46, english: [25...40]),
            .longOnly(.text("An-Nawawi said of these words:")),
            .longOnly(.quote(text: "“It affirms the decree … Its meaning is that all things are by the decree of Allah, and occur only as Allah decreed them and as His knowledge of them preceded. So the harm of the eye does not occur, nor anything else of good or evil, except by the decree of Allah” (an-Nawawi, Sharh Saheeh Muslim 14/174).", arabic: "فِيهِ إِثبَاتُ القَدَرِ … وَمَعنَاهُ أَنَّ الأَشيَاءَ كُلَّهَا بِقَدَرِ اللَّهِ تَعَالَى، وَلَا تَقَعُ إِلَّا عَلَى حَسَبِ مَا قَدَّرَهَا اللَّهُ تَعَالَى وَسَبَقَ بِهَا عِلمُهُ، فَلَا يَقَعُ ضَرَرُ العَينِ وَلَا غَيرُهُ مِنَ الخَيرِ وَالشَّرِّ إِلَّا بِقَدَرِ اللَّهِ تَعَالَى", dimmed: true)),
            .longOnly(.text("Ibn Hajar, following al-Qurtubi, put it more sharply: the wording stresses how real the eye is, not that anything could turn back the decree; had anything the strength to outrun it, it would be the eye, and the eye does not, so how could anything else? (Fath al-Baari 10/203-204). Allah said:")),
            .shortOnly(.text("Allah said:")),
            .ayah("9:51"),
            .longOnly(.ayah("64:11", words: 0...6)),
            .longOnly(.text("He said the same of magic, the other unseen harm people fear:")),
            .longOnly(.ayah("2:102", words: 42...50)),
            .longOnly(.text("And the Prophet (peace be upon him) taught the young Ibn Abbaas (may Allah be pleased with them both):")),
            .longOnly(.hadith("tirmidhi:2516", cite: "Jaami‘ at-Tirmidhi 2516; graded saheeh by al-Albaani", arabic: 80...110, english: [51...103])),
            .text("So the eye is guarded against as fire and illness are guarded against: as a cause that Allah may allow to take effect, and from which He alone protects. To believe that it acts by itself, apart from His will, is to give creation what belongs only to the Creator."),
        ]),
        ArticleSection("NOT THE SAME AS ENVY", [
            .markdown("**Hasad (حَسَد)**, from ح-س-د, is envy: resenting a blessing Allah gave to another and wishing it gone. Ibn Taymiyyah defined it:"),
            .quote(text: "“Envy is hatred and dislike of what one sees of the good state of the one envied” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 10/111).", arabic: "الحَسَدُ هُوَ البُغضُ وَالكَرَاهَةُ لِمَا يَرَاهُ مِن حُسنِ حَالِ المَحسُودِ", dimmed: true),
            .text("It is a disease of the heart, and wishing a blessing gone from its owner is forbidden by consensus, whether or not any harm follows from it (an-Nawawi, Sharh Saheeh Muslim 6/97):"),
            .ayah("4:54", words: 0...8),
            .longOnly(.hadith("bukhari:6065", cite: "Saheeh al-Bukhaari 6065", arabic: 27...36, english: [4...28])),
            .longOnly(.markdown("The eye is the harm itself. In his commentary on Surah al-Falaq in Badaa’i‘ al-Fawaa’id, Ibn al-Qayyim wrote that the one who gives the eye and the envier share one thing and differ in another. They share that each one’s soul turns toward the one it would harm. They differ in that the eye can strike what its owner does not envy at all, a thing, an animal, a crop, or wealth, though it is seldom free of envy toward the owner; and it can strike its own owner. He counted the one who gives the eye a particular kind of envier, and the more harmful kind, which is why the surah names the envier, the wider of the two: seeking refuge from envy takes in the eye. Jibreel’s ruqyah names both. Ibn Hajar, quoted above, worded it differently: the eye can come with admiration and no envy at all. The remedy is the same either way.")),
            .shortOnly(.markdown("The eye is the harm itself. Ibn al-Qayyim wrote in Badaa’i‘ al-Fawaa’id that the eye can strike what its owner does not envy at all, and can strike its own owner, and that seeking refuge from envy, as Surah al-Falaq teaches, takes in the eye. The remedy is the same either way.")),
            .longOnly(.markdown("**Ghibtah (غِبطَة)** is neither. An-Nawawi relayed from the scholars that it is wishing for the like of a blessing another has, without its leaving its owner: permitted in worldly matters and recommended in acts of obedience, and it is what “no envy except in two” means (Sharh Saheeh Muslim 6/97; Saheeh al-Bukhaari 73). Ibn Taymiyyah was more guarded. Where it carries a dislike of being surpassed, he held it forbidden except in what brings a person nearer to Allah, and he said that the heart which does not look at what others have at all is better (Majmoo‘ al-Fataawa 10/113, 10/120-121).")),
            .longOnly(.hadith("bukhari:73", cite: "Saheeh al-Bukhaari 73, Saheeh Muslim 816", arabic: 37...58, english: [4...53])),
            .longOnly(.text("Ibn Taymiyyah called envy a disease of the soul from which only a few people are free, and relayed the saying that no body is empty of envy, but the base man shows it and the noble man hides it. Whoever finds it in himself, he said, must meet it with taqwa and patience and hate it in himself, and must still give the one he envies his due; whoever acts on it, by word or deed, is a wrongdoer who deserves punishment unless he repents (Majmoo‘ al-Fataawa 10/121, 10/124-125). So he treats it by asking Allah for His bounty rather than resenting it in another, by praying for the one he envies, and by loving for him what he loves for himself:")),
            .longOnly(.ayah("4:32", words: 17...20)),
            .longOnly(.hadith("bukhari:13", cite: "Saheeh al-Bukhaari 13", arabic: 39...47, english: [4...21])),
        ]),
        ArticleSection("NOT TURNED AWAY BY CHARMS", [
            .text("People in every age have hung things to keep the eye away. The Arabs before Islam hung bowstrings and beads on their camels, their children, and themselves. The Prophet (peace be upon him) sent a man through the camp with this order:"),
            .hadith("bukhari:3005", cite: "Saheeh al-Bukhaari 3005, Saheeh Muslim 2115", arabic: 59...71, english: [40...63]),
            .longOnly(.hadith("muslim:2115", cite: "Saheeh Muslim 2115", arabic: 76...81, english: [32...67])),
            .longOnly(.text("He said to Ruwayfi‘ ibn Thaabit (may Allah be pleased with him):")),
            .longOnly(.hadith("abudawud:36", cite: "Sunan Abi Daawood 36; graded saheeh by al-Albaani", arabic: 109...138, english: [109...157])),
            .longOnly(.text("The Arabic says “wears a bowstring”. The translator’s “to ward off the evil eye” is the scholars’ explanation of it: al-Khattaabi said they tied their charms and amulets with such strings, believing that they kept harm away, and the Prophet (peace be upon him) abolished it (Ma‘aalim as-Sunan 1/26-27).")),
            .markdown("An amulet is a **tameemah (تَمِيمَة)**, which Ibn al-Uthaymeen defined as something hung on children, of beads or anything else, to guard them against the eye (al-Qawl al-Mufeed 1/170). A group of men came to give the Prophet (peace be upon him) their pledge; he accepted it from nine and held back from one, because of an amulet the man was wearing. Once it was cut off he took his pledge, and said:"),
            .hadith("ahmed:17422", cite: "Musnad Ahmad 17422; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 492", arabic: 56...60, text: "“Whoever hangs an amulet has committed shirk”"),
            .longOnly(.markdown("**The rule.** Ibn al-Uthaymeen set it out in al-Qawl al-Mufeed (1/164-165): whoever affirms a cause that Allah made a cause neither in His law nor in His decree has made himself a partner with Allah. If the wearer believes the thing acts by itself apart from Allah, that is major shirk, for he has believed in a creator beside Him. If he believes it is only a cause, that is minor shirk, for he has shared with Allah in ruling it a cause when Allah did not make it one. A real cause is known from revelation, or from experience when its effect is plain and direct, as with medicine.")),
            .text("So the blue bead and the glass “eye”, the open hand, the black thread on a newborn’s wrist, the horseshoe over the door, shells, and the rest are all forbidden, whatever the wearer intends. Ibn Baaz said of beads, shells, and threads hung on children against the eye that they are amulets and minor shirk, and major shirk when the one who hangs them believes they repel harm by themselves."),
            .longOnly(.text("Smoke and household rituals are no different. The Standing Committee was asked about fumigating with alum, herbs, or leaves for someone struck by the eye, and answered that it is not permitted: these are not ordinary causes of its cure, the fumigation may be meant to appease the devils among the jinn, and the eye is treated with the lawful ruqyah established in the authentic hadiths (Fataawa al-Lajnah ad-Daa’imah 1/275). Ibn Baaz said that pouring molten lead has no basis and is the practice of soothsayers. The same holds for burning wild rue or salt, passing an egg over the body, and whatever else has no basis in revelation or in plain, direct experience.")),
            .longOnly(.text("Hanging aayaat or the words “Ma sha’ Allah” for protection is left as well. The Salaf differed over an amulet made only of Quran: some allowed it, and Ibn Mas‘ood and his companions disliked every amulet, as Muhammad ibn Abd al-Wahhaab records in Kitaab at-Tawheed. The Standing Committee called the prohibition the sounder of the two views, stronger in proof and safer for the creed (Fataawa al-Lajnah ad-Daa’imah 1/300-302, 1/312). Ibn Baaz held it correct for three reasons: the hadiths that forbid amulets are general, the door to shirk is to be closed, and what is hung may be carried into unclean places (Majmoo‘ Fataawa Ibn Baaz 1/51). Ibn al-Uthaymeen said that it is not to be done, since it is not established from the Prophet (peace be upon him) as a means (Majmoo‘ Fataawa Ibn al-Uthaymeen 1/106-107). Ibn Baaz and the Committee added that an amulet from other than the Quran is the graver of the two.")),
            .shortOnly(.text("Hanging aayaat or the words “Ma sha’ Allah” for protection is left as well. The Salaf differed over an amulet made only of Quran, and the Standing Committee called the prohibition the sounder of the two views, stronger in proof and safer for the creed (Fataawa al-Lajnah ad-Daa’imah 1/300-302).")),
            .longOnly(.ayah("10:107", words: 0...8)),
            .longOnly(.markdown("The same holds for omens. **Tiyarah (طِيَرَة)**, from ط-ي-ر, the birds the Arabs read their luck from, is taking anything as a sign of misfortune. Calling a day, a month, a number, or a passing bird unlucky belongs to it, and it has nothing to do with the eye:")),
            .longOnly(.hadith("abudawud:3910", cite: "Sunan Abi Daawood 3910; graded saheeh by al-Albaani", arabic: 32...35, english: [4...11])),
        ]),
        ArticleSection("NOT A REASON TO ACCUSE OR TO FEAR", [
            .longOnly(.markdown("**Not every hardship is the eye.** People fall ill, lose money, fail, and quarrel for ordinary reasons, and every one of those is a test Allah wrote. Blaming the eye for all of it leaves the real cause untreated, and it teaches the heart to see an enemy in every guest. Take the illness to a doctor and the sin to repentance, and recite ruqyah alongside both. Ibn al-Uthaymeen said that delusions and whisperings have multiplied among people, so that whenever something ordinary befalls them they say: this is the jinn, or the eye, or magic (Fataawa Noor ‘ala ad-Darb); and Ibn Baaz said that not everything is the eye, for it may be an illness of the body.")),
            .shortOnly(.markdown("**Not every hardship is the eye.** People fall ill, lose money, fail, and quarrel for ordinary reasons, and every one of those is a test Allah wrote. Blaming the eye for all of it leaves the real cause untreated. Take the illness to a doctor and the sin to repentance, and recite ruqyah alongside both.")),
            .longOnly(.ayah("57:22")),
            .markdown("**Suspicion is not proof.** The Prophet (peace be upon him) asked “Whom do you suspect?” when the cause was plain: a man praised Sahl, and Sahl collapsed where he stood. Naming a relative or a neighbour because something went wrong weeks after her visit is a guess, and Allah said:"),
            .ayah("49:12", words: 3...10),
            .longOnly(.markdown("**No one learns who it was from a fortune-teller, a “reader”, or a jinn.** Asking them costs a person the acceptance of forty nights of prayer (Saheeh Muslim 2230), and whoever believes what they say has nothing to do with what was sent down to Muhammad (peace be upon him) (Sunan Abi Daawood 3904; graded saheeh by al-Albaani). A woman struck by the eye went to such a man, and Ibn Baaz answered her that he is a soothsayer, and that going to soothsayers, astrologers, and those who use the jinn is never permitted, for the eye or for anything else.")),
            .longOnly(.hadith("muslim:2230", cite: "Saheeh Muslim 2230", arabic: 36...47, english: [0...20])),
            .longOnly(.hadith("abudawud:3904", cite: "Sunan Abi Daawood 3904; graded saheeh by al-Albaani", arabic: 33...78, english: [4...58])),
            .markdown("**Blessings are not hidden out of dread.** Allah said:"),
            .ayah("93:11"),
            .longOnly(.text("The believer uses what Allah gave him and thanks Him for it openly. There is wisdom in not parading every blessing before everyone, as Ya‘qoob told Yoosuf (peace be upon them both) to keep his dream from his brothers:")),
            .longOnly(.ayah("12:5", words: 2...9)),
            .longOnly(.text("That is lawful precaution, as was Ya‘qoob’s at the gates of Egypt, and Ibn al-Uthaymeen said that guarding against the eye beforehand does not contradict reliance on Allah; it is reliance (Majmoo‘ Fataawa Ibn al-Uthaymeen 2/117-118). It is not a life spent hiding children from visitors, refusing invitations, and reading every headache as an attack. Whoever keeps the morning and evening remembrances and relies on Allah has taken the strongest means there is:")),
            .shortOnly(.text("The believer uses what Allah gave him and thanks Him for it openly. It is not a life spent hiding children from visitors, refusing invitations, and reading every headache as an attack. Whoever keeps the morning and evening remembrances and relies on Allah has taken the strongest means there is:")),
            .ayah("65:3", words: 5...10),
        ]),
        ArticleSection("WHAT THE SUNNAH TEACHES INSTEAD", [
            .text("The Prophet (peace be upon him) left a complete answer to the eye, and there is nothing in it but words addressed to Allah, and water:"),
            .step("1. **Ask blessing for what you admire.** “Allahumma baarik ‘alayh”: O Allah, send blessing upon him. The Prophet (peace be upon him) asked Aamir why he had not asked blessing, and Ibn al-Qayyim gave these as the words by which the one who fears his own eye turns its harm away (Zad al-Ma‘aad 4/155-157)."),
            .longOnly(.step("2. **Seek refuge every day.** Al-Ikhlaas, al-Falaq, and an-Naas, three times each morning and evening (Sunan Abi Daawood 5082; graded hasan by al-Albaani), and the refuge he said over al-Hasan and al-Husayn:")),
            .shortOnly(.step("2. **Seek refuge every day.** Al-Ikhlaas, al-Falaq, and an-Naas, three times each morning and evening (Sunan Abi Daawood 5082; graded hasan by al-Albaani):")),
            .hadith("abudawud:5082", cite: "Sunan Abi Daawood 5082; graded hasan by al-Albaani", arabic: 84...99, english: [70...93]),
            .longOnly(.hadith("abudawud:4737", cite: "Sunan Abi Daawood 4737; graded saheeh by al-Albaani", arabic: 33...44, english: [18...44])),
            .step("3. **Recite ruqyah when it strikes.** He commanded it for the eye by name:"),
            .hadith("bukhari:5738", cite: "Saheeh al-Bukhaari 5738, Saheeh Muslim 2195", arabic: 25...37, english: [0...18]),
            .step("4. **Have the one it came from wash**, when he is known, and pour the water over the one struck, as he commanded in the hadith above: when you are asked to wash, wash (Saheeh Muslim 2188)."),
            .step("5. **Trust Allah.** The means are taken with the hands and the tongue, and the heart rests on Him alone."),
            .text("Each step, with its words and how to do it, is in the How-To Guides:"),
            .door(.article("EvilEyeGuideView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Is it disbelief to deny the evil eye?**")),
            .longOnly(.text("Whoever denies it has denied what the Prophet (peace be upon him) affirmed in the two Saheehs, and the scholars counted that denial among the positions of the innovators, as al-Maaziri said above. A Muslim who doubts it because he has never been shown the texts is taught them. Ruling on a particular person belongs to the scholars.")),
            .markdown("**Do I say “Ma sha’ Allah” or “Baarakallah”?**"),
            .text("What the Prophet (peace be upon him) commanded for the eye is asking blessing: he asked Aamir why he had not asked blessing for Sahl, as Maalik narrates in al-Muwatta, and said that whoever sees in his brother something that pleases him should pray for blessing for him (Sunan Ibn Maajah 3509, above). So say “Allahumma baarik ‘alayh” or “Baarakallahu feek”. “Ma sha’ Allah, la quwwata illa billah” comes from the story of the two gardens, where the believer tells the owner what he should have said on entering his own garden:"),
            .ayah("18:39", words: 5...11),
            .longOnly(.text("The Standing Committee and Ibn Baaz advised saying it together with the request for blessing; Ibn al-Uthaymeen kept it for a person’s own blessings, as in the ayah, and for another’s said “Tabaarak Allahu ‘alayk”. Asked about “Ma sha’ Allah, tabaarak Allah”, Ibn Baaz answered that nothing is reported for “Tabaarak Allah”, and that what is reported is the dua for blessing, “Allahumma baarik feeh” or “Baarakallahu feeh”, said with “Ma sha’ Allah, la quwwata illa billah”. The dua for blessing is what they all agree on, so that is the part never to leave out. The hadith that whoever says “Ma sha’ Allah, la quwwata illa billah” will not be harmed by the eye is weak (al-Albaani, Da‘eef al-Jaami‘ 5588).")),
            .shortOnly(.text("The Standing Committee and Ibn Baaz advised saying it together with the request for blessing, and Ibn al-Uthaymeen kept it for a person’s own blessings, as in the ayah. The dua for blessing is what they all agree on, so that is the part never to leave out.")),
            .longOnly(.markdown("**Can someone who loves me give me the eye?**")),
            .longOnly(.text("Yes. Aamir was Sahl’s brother in faith and a man of Badr, and a mother can strike her own child with a look of delight. This is why the remedy is a dua and not suspicion: asking blessing costs nothing and accuses no one.")),
            .longOnly(.markdown("**Is the one who gave it sinful?**")),
            .longOnly(.text("Ibn Baaz said that the eye can leave a person, by Allah’s permission, without his choosing or intending it, and then there is no sin on him for it, while the one who does it deliberately deserves to be punished. Even so, the one who admired and said nothing has left what he was commanded, which is why the Prophet (peace be upon him) rebuked Aamir. He must wash when asked. Whoever knows his eye is quick must guard it and ask blessing every time. As for a person known for harming people with it, Ibn Battaal relayed from some of the scholars that the ruler keeps him from mixing with people, and provides for him if he is poor; an-Nawawi called that view correct, and Ibn al-Qayyim said the same (Fath al-Baari 10/205; Zad al-Ma‘aad 4/154).")),
            .longOnly(.markdown("**Can it come through a photograph, a screen, or a description?**")),
            .longOnly(.text("Nothing in the texts ties it to seeing a person in the flesh, and Ibn al-Qayyim said it can follow a description alone, as quoted above. So it is possible. That is a reason for good sense about what is shown and to whom, and for keeping the words of refuge. It is not a reason for dread, because the screen has no power the decree does not give it.")),
            .longOnly(.markdown("**Does it strike only people?**")),
            .longOnly(.text("No. Ibn al-Qayyim noted that the eye can strike a thing, an animal, a crop, or wealth, and the charms the Prophet (peace be upon him) ordered cut were hanging on camels. Animals, crops, cars, and businesses are asked blessing for as people are.")),
            .longOnly(.markdown("**Can a non-Muslim give the eye, or be struck by it?**")),
            .longOnly(.text("Yes to both. The ayah in Surah al-Qalam is about the eyes of disbelievers, and nothing in the texts ties the eye to the religion of the one it comes from or the one it strikes.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The evil eye is real because Allah and His Messenger said so, and it harms only by Allah’s decree. Take it seriously, and do not let the fear of it rule you. Ask Allah to bless whatever pleases you, guard yourself and your children with the words of refuge, treat it with ruqyah and the washing the Prophet taught, hang nothing, accuse no one, and place your trust in the One in whose hand all harm and all benefit lie."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Al-‘ayn", arabic: "العَيْن", meaning: "The eye: harm that reaches a person, by Allah’s permission, from a look of envy or of admiration in which Allah is not remembered."),
            .term("Aa’in", arabic: "العَائِن", meaning: "The one the eye comes from, whether he intends it or not."),
            .term("Ma‘een", arabic: "المَعِين", meaning: "The one struck by the eye; also called the **ma‘yoon**."),
            .term("Hasad", arabic: "الحَسَد", meaning: "Envy: resenting a blessing given to another and wishing it gone. A disease of the heart, forbidden by consensus, and the usual root of the eye."),
            .term("Ghibtah", arabic: "الغِبْطَة", meaning: "Wishing for the like of a blessing without wishing it removed from its owner. Permitted, and praised in matters of the religion."),
            .term("Tabreek", arabic: "التَّبْرِيك", meaning: "Asking Allah to bless something, from ب-ر-ك: “Allahumma baarik ‘alayh”, “Baarakallahu feek”. The Prophet’s remedy for the one who admires."),
            .term("Ruqyah", arabic: "الرُّقْيَة", meaning: "Reciting the Quran and the Prophet’s supplications over the one afflicted, asking Allah alone for the cure."),
            .term("Tameemah", arabic: "التَّمِيمَة", meaning: "An amulet or charm hung or worn for protection. Major shirk when it is believed to protect by itself, minor shirk when it is taken as a means. The Salaf differed over one made only of Quran; the sounder view is that it is not hung either."),
            .term("Tiyarah", arabic: "الطِّيَرَة", meaning: "Taking omens: seeing misfortune in a day, a number, a bird, or a chance sight. The Prophet called it shirk."),
            .term("Qadar", arabic: "القَدَر", meaning: "The decree of Allah, which nothing precedes or escapes, the eye included."),
            .term("Tawakkul", arabic: "التَّوَكُّل", meaning: "Relying on Allah with the heart while taking the lawful means with the limbs."),
        ]),
    ]
}
