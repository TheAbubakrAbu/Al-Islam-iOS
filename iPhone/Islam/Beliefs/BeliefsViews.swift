import SwiftUI

struct HaramView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Masjid al-Haraam in Makkah is the holiest mosque in Islam. It surrounds the Ka‘bah, the House of Allah and the Qiblah toward which all Muslims pray.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "Masjid Al-Haraam (ٱلمَسجِدُ ٱلحَرَام), or “The Sacred Mosque,” is located in **Makkah (مَكَّة)**, Saudi Arabia. It is the largest mosque in the world and surrounds the **Ka‘bah** (ٱلكَعبَة), the holiest site in Islam. The Ka‘bah is also known as “The House of Allah” (بَيتُ ٱللَّه).")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "2:125", words: 0...5)

                    ArticleParagraph(articleMarkdown: "Masjid Al-Haraam is the destination for **Hajj (حَجّ)** and **Umrah (عُمرَة)**, two pivotal acts of worship in Islam. The Prophet Muhammad (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "ibnmajah:1406", cite: "Sunan Ibn Maajah 1406; graded saheeh by al-Albaani", arabic: 32...54, english: 0...30)
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("SIGNIFICANCE OF THE KA‘BAH")) {
                        ArticleParagraph(articleMarkdown: "The **Ka‘bah** (ٱلكَعبَة), meaning “The Cube,” is the symbolic House of Allah. It serves as the **Qiblah** (قِبلَةٌ) (direction of prayer) for Muslims worldwide. Every prayer offered by a Muslim is directed toward the Ka‘bah.")

                        ArticleParagraph(articleMarkdown: "The Ka‘bah was built by **Prophet Ibraaheem** (Abraham, peace be upon him) and his son **Prophet Ismaa‘eel** (Ishmael, peace be upon him) as a place of monotheistic worship. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:127")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("SIGNIFICANCE OF THE KA‘BAH")) {
                        ArticleParagraph(articleMarkdown: "The **Ka‘bah** (ٱلكَعبَة), meaning “The Cube,” is the symbolic House of Allah. It serves as the **Qiblah** (قِبلَةٌ) (direction of prayer) for Muslims worldwide. Every prayer offered by a Muslim is directed toward the Ka‘bah.")

                        ArticleParagraph(articleMarkdown: "The Ka‘bah was built by **Prophet Ibraaheem** (Abraham, peace be upon him) and his son **Prophet Ismaa‘eel** (Ishmael, peace be upon him) as a place of monotheistic worship. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:127")

                        ArticleParagraph(articleMarkdown: "The **Black Stone** (ٱلحَجَرُ ٱلأَسوَد, Hajar Al-Aswad), set in one corner of the Ka‘bah, came down from Paradise (Jaami‘ at-Tirmidhi 877; graded saheeh by al-Albaani). Touching or kissing it during **Tawaaf** is a Sunnah, but not obligatory, and it is done only to follow the Prophet (peace and blessings be upon him), not to seek benefit from the stone itself. Umar (may Allah be pleased with him) kissed it and said: “No doubt, I know that you are a stone and can neither benefit anyone nor harm anyone. Had I not seen Allah's Messenger (ﷺ) kissing you I would not have kissed you” (Saheeh al-Bukhaari 1597).")
                        ScriptureQuote(hadith: "tirmidhi:877", cite: "Jaami‘ at-Tirmidhi 877; graded saheeh by al-Albaani", arabic: 25...38, english: 5...30)
                        ScriptureQuote(hadith: "bukhari:1597", cite: "Saheeh al-Bukhaari 1597, Saheeh Muslim 1270", arabic: 21...46, english: 0...42)
                    }

                    Section(header: ArticleHeader("THE WELL OF ZAMZAM")) {
                        ArticleParagraph(articleMarkdown: "The **Well of Zamzam** (بِئرُ زَمزَم) is located within Masjid Al-Haraam. This miraculous water source was provided by Allah for **Haajar** (may Allah be pleased with her) and her son **Ismaa‘eel** (peace be upon him) when they were left in the barren desert. The well continues to flow abundantly to this day.")

                        ArticleParagraph(verbatim: "Zamzam water is blessed: the Prophet (peace and blessings be upon him) said of it, “It is blessed; it is food that satisfies” (Saheeh Muslim 2473).")
                        ScriptureQuote(hadith: "muslim:2473a", cite: "Saheeh Muslim 2473", arabic: 552...556, english: 934...945)
                    }

                    Section(header: ArticleHeader("SPIRITUAL REWARDS AND IMPORTANCE")) {
                        ArticleStep("1. **Multiplied Rewards**: Praying in Masjid Al-Haraam is rewarded 100,000 times more than praying elsewhere.")
                        ArticleStep("2. **Forgiveness of Sins**: Performing Hajj or Umrah with sincerity cleanses one’s sins. The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1521", cite: "Saheeh al-Bukhaari 1521", arabic: 31...41, english: 4...41)
                        ArticleStep("3. **Unity of the Ummah**: Millions of Muslims from diverse cultures and backgrounds gather in Masjid Al-Haraam, symbolizing the unity and equality of the Muslim Ummah under the worship of Allah.")
                    }

                    Section(header: ArticleHeader("QURANIC VERSES ABOUT MAKKAH")) {
                        ArticleParagraph(verbatim: "Allah mentions the sanctity of Makkah and Masjid Al-Haraam in several verses:")
                        ScriptureQuote(quran: "3:96")
                        ScriptureQuote(quran: "2:125", words: 0...5)
                    }
                }

                Section(header: ArticleHeader("MASJID AL-HARAAM")) {
                    Image("Al Haraam")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(24)
                            #if os(iOS)
                            .focusableImage("Al Haraam", title: "Masjid al-Haraam")
                            #endif
                            #if os(iOS)
                            .contextMenu {
                                Text(verbatim: "Image Actions")
                                    .foregroundStyle(.secondary)

                                Button {
                                    Settings.shared.hapticFeedback()
                                    UIPasteboard.general.image = UIImage(named: "Al Haram")
                                } label: {
                                    Text(verbatim: "Copy Image")
                                    Image(systemName: "photo")
                                }
                            }
                            #endif
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("A single prayer here equals a hundred thousand elsewhere. It is the heart of Hajj and Umrah, where the whole Ummah gathers as equals before Allah.")
                }

                ArticleSourcesSection(article: "HaramView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "HaramView")
        .navigationTitle("Masjid Al-Haraam")
    }
}

struct NabawiView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Masjid an-Nabawi in Madinah is the Prophet's own mosque and the second holiest in Islam, home to the Rawdah and his resting place.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "Masjid An-Nabawi (ٱلمَسجِد ٱلنَّبَوِي), or “The Prophet’s Mosque,” is located in Madinah, Saudi Arabia. Originally known as Yathrib, the city became known after the migration (Hijrah) of Prophet Muhammad (peace and blessings be upon him) as **Al-Madinah (ٱلمَدِينَة)**, “The City,” and as **Taabah (طَابَة)**, the name the Prophet said Allah gave it (Saheeh Muslim 1385); **Al-Madinah Al-Munawwarah (ٱلمَدِينَة ٱلمُنَوَّرَة)**, “The Illuminated City,” is a later honorific.")
                    ScriptureQuote(hadith: "muslim:1385", cite: "Saheeh Muslim 1385", arabic: 33...38, english: 0...4)

                    ArticleParagraph(verbatim: "This mosque, built by the Prophet (peace and blessings be upon him) in 622 CE, is the second holiest site in Islam after Masjid Al-Haraam. The Prophet (peace and blessings be upon him) made it a center of worship, governance, and community life.")

                    ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:1190", cite: "Saheeh Bukhaari 1190", arabic: 41...53, english: 4...20)
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("A WARNING AGAINST SHIRK")) {
                        ArticleParagraph(articleMarkdown: "This must be clear, because it is where people fall. You do **not** pray to the Prophet (peace and blessings be upon him). You do **not** pray facing his grave. You do not ask him for anything and you do not seek help or intercession from him: that is **shirk (شِرك)**, associating partners with Allah, the one sin Allah does not forgive if a person dies upon it. Praying toward the grave, circling it, or touching it seeking blessing is forbidden and a doorway to shirk: the Prophet (peace and blessings be upon him) said, “Do not sit on graves and do not pray toward them” (Saheeh Muslim 972).")
                        ScriptureQuote(hadith: "muslim:972a", cite: "Saheeh Muslim 972", arabic: 33...39, english: 0...12)

                        ArticleParagraph(verbatim: "Dua is worship, and worship belongs to Allah alone:")
                        ScriptureQuote(quran: "72:18")

                        ArticleParagraph(verbatim: "So love him, follow him, and send salaah and salaam upon him abundantly. But direct every act of worship to Allah alone. That is what he taught, and honouring him means obeying him.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("SIGNIFICANCE")) {
                        ArticleParagraph(articleMarkdown: "Masjid An-Nabawi is home to the **Rawdah (ٱلرَّوضَة)**, an area between the Prophet's pulpit and his house, which he described as a garden from the gardens of Paradise. The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1196", cite: "Saheeh al-Bukhaari 1196", arabic: 34...44, english: 4...18)

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) is buried in the room of Aa’ishah (may Allah be pleased with her), his own house beside the mosque, with his two companions Abu Bakr As-Siddeeq and Umar ibn Al-Khattaab (may Allah be pleased with them). That room was brought within the mosque's walls only in the expansion under the Umayyad caliph al-Waleed ibn Abd al-Malik, after most of the Companions had died; the mosque was not built over a grave. It is from the Sunnah for a visitor to send salaam upon him and upon his two companions.")
                    }

                    Section(header: ArticleHeader("A WARNING AGAINST SHIRK")) {
                        ArticleParagraph(articleMarkdown: "This must be clear, because it is where people fall. You do **not** pray to the Prophet (peace and blessings be upon him). You do **not** pray facing his grave. You do not ask him for anything and you do not seek help or intercession from him: that is **shirk (شِرك)**, associating partners with Allah, the one sin Allah does not forgive if a person dies upon it. Praying toward the grave, circling it, or touching it seeking blessing is forbidden and a doorway to shirk: the Prophet (peace and blessings be upon him) said, “Do not sit on graves and do not pray toward them” (Saheeh Muslim 972).")
                        ScriptureQuote(hadith: "muslim:972a", cite: "Saheeh Muslim 972", arabic: 33...39, english: 0...12)

                        ArticleParagraph(verbatim: "Dua is worship, and worship belongs to Allah alone:")
                        ScriptureQuote(quran: "72:18")

                        ArticleParagraph(verbatim: "When you pray in Masjid An-Nabawi, you face the Qiblah, towards the Ka‘bah in Makkah, exactly as you would anywhere else on earth. The grave happens to lie in that direction from parts of the mosque; that is a fact of geography, not a thing to be prayed towards.")

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) himself warned against precisely this, in his final illness:")
                        ScriptureQuote(hadith: "bukhari:435", cite: "Saheeh al-Bukhaari 435, Saheeh Muslim 531", arabic: 48...56, english: 37...67)

                        ArticleParagraph(verbatim: "He also said:")
                        ScriptureQuote(hadith: "abudawud:2042", cite: "Sunan Abi Daawood 2042; graded saheeh by al-Albaani", arabic: 30...44, english: 4...33)

                        ArticleParagraph(verbatim: "So love him, follow him, and send salaah and salaam upon him abundantly. But direct every act of worship to Allah alone. That is what he taught, and honouring him means obeying him.")
                    }

                    Section(header: ArticleHeader("SPIRITUAL BENEFITS")) {
                        ArticleStep("1. **Multiplied Rewards**: Prayers in Masjid An-Nabawi are rewarded 1,000 times more than prayers in other mosques (except Masjid Al-Haraam).")
                        ArticleStep("2. **Connection to the Prophet**: Standing in a place where the Prophet Muhammad (peace and blessings be upon him) worshipped and led his companions strengthens one’s faith and love for him.")
                        ArticleStep("3. **Rawdah Visit**: Visiting the Rawdah and praying there is considered highly virtuous.")
                    }

                    Section(header: ArticleHeader("QURANIC VERSES ABOUT THE MOSQUE")) {
                        ArticleParagraph(verbatim: "Allah emphasizes the sanctity of mosques, particularly those established on righteousness. He says in the Quran:")
                        ScriptureQuote(quran: "9:108", words: 4...14)
                    }
                }

                Section(header: ArticleHeader("MASJID AN-NABAWI")) {
                    Image("An Nabawi")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                        #if os(iOS)
                        .focusableImage("An Nabawi", title: "Masjid an-Nabawi")
                        #endif
                        #if os(iOS)
                        .contextMenu {
                            Text(verbatim: "Image Actions")
                                .foregroundStyle(.secondary)

                            Button {
                                Settings.shared.hapticFeedback()
                                UIPasteboard.general.image = UIImage(named: "An Nabawi")
                            } label: {
                                Text(verbatim: "Copy Image")
                                Image(systemName: "photo")
                            }
                        }
                        #endif
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("A prayer here equals a thousand elsewhere. It was the Prophet's center of worship and community, and visiting it deepens a believer's love for him.")
                }

                ArticleSourcesSection(article: "NabawiView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "NabawiView")
        .navigationTitle("Masjid An-Nabawi")
    }
}

struct AqsaView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Masjid al-Aqsa in Jerusalem is the third holiest mosque, the first Qiblah, and the destination of the Prophet's Night Journey (Isra and Mi‘raaj).")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(verbatim: "Masjid Al-Aqsa (ٱلمَسجِد ٱلأَقصَىٰ), meaning “The Farthest Mosque,” is located in Jerusalem, Palestine. It is the third holiest mosque in Islam after Masjid Al-Haraam in Makkah and Masjid An-Nabawi in Madinah.")

                        ArticleParagraph(verbatim: "Masjid Al-Aqsa holds immense historical and spiritual significance in Islam. Allah (Glorified and Exalted be He) mentions it in the Quran:")
                        ScriptureQuote(quran: "17:1")

                        ArticleParagraph(articleMarkdown: "It was the first Qiblah (direction of prayer) for Muslims before it was changed to the Ka‘bah in Makkah, and it was the destination of the Prophet Muhammad’s (peace and blessings be upon him) Night Journey, **Isra (الإِسرَاء)**, before his Ascension, **Mi‘raaj (المِعرَاج)**.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "Masjid Al-Aqsa (ٱلمَسجِد ٱلأَقصَىٰ), meaning “The Farthest Mosque,” is located in Jerusalem, Palestine, within a compound often called **Al-Haram Ash-Shareef (ٱلحَرَم ٱلشَّرِيف)**, or “The Noble Sanctuary.” That is a later, popular name: the scholars recognise a haram with sacred bounds only at Makkah and Madinah, with a difference over the valley of Wajj at at-Taa’if (Ibn Taymiyyah, Majmoo‘ al-Fataawa 27/14–15), and the whole compound is itself Masjid al-Aqsa. It is the third holiest mosque in Islam after Masjid Al-Haraam in Makkah and Masjid An-Nabawi in Madinah.")

                        ArticleParagraph(verbatim: "Masjid Al-Aqsa holds immense historical and spiritual significance in Islam. Allah (Glorified and Exalted be He) mentions it in the Quran:")
                        ScriptureQuote(quran: "17:1")

                        ArticleParagraph(articleMarkdown: "It was the first Qiblah (direction of prayer) for Muslims before it was changed to the Ka‘bah in Makkah, and it was the destination of the Prophet Muhammad’s (peace and blessings be upon him) Night Journey, **Isra (الإِسرَاء)**, before his Ascension, **Mi‘raaj (المِعرَاج)**.")
                    }
                }

                Section(header: ArticleHeader("SPIRITUAL SIGNIFICANCE")) {
                    ArticleStep("1. **First Qiblah**: Muslims initially faced Masjid Al-Aqsa during their prayers, highlighting its significance from the earliest days of Islam.")
                    ArticleStep("2. **Al-Isra wa al-Mi‘raaj (الإِسرَاء وَالمِعرَاج)**: It was the destination of the miraculous Night Journey of the Prophet Muhammad (peace and blessings be upon him), during which he led all prophets in prayer before ascending to the heavens.")
                    ArticleStep("3. **Land of Blessings**: The Quran describes the surroundings of Masjid Al-Aqsa as a blessed land. Allah says:")
                    ScriptureQuote(quran: "21:71")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HISTORICAL AND RELIGIOUS IMPORTANCE")) {
                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1189", cite: "Saheeh al-Bukhaari 1189", arabic: 25...41, english: 4...30)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HISTORICAL AND RELIGIOUS IMPORTANCE")) {
                        ArticleParagraph(verbatim: "Masjid Al-Aqsa is a place of worship for many prophets, including Ibraaheem (Abraham), Daawood (David), and Sulaymaan (Solomon) (peace be upon them). Prophet Muhammad (peace and blessings be upon him) led the prophets in prayer there during the Night Journey. He said:")
                        ScriptureQuote(hadith: "muslim:172", cite: "Saheeh Muslim 172", arabic: 77...131, english: 67...156)

                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1189", cite: "Saheeh al-Bukhaari 1189", arabic: 25...41, english: 4...30)
                    }

                    Section(header: ArticleHeader("REWARDS OF PRAYING IN MASJID AL-AQSA")) {
                        ArticleParagraph(verbatim: "Prayer in the three sacred mosques carries immense reward. What is established is the authentic narration in which the Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1190", cite: "Saheeh al-Bukhaari 1190", arabic: 41...53, english: 4...20)

                        ArticleParagraph(verbatim: "A report giving a specific figure for Masjid Al-Aqsa (fifty thousand prayers) is narrated in Sunan Ibn Maajah 1413, but its chain is weak (da‘eef), and its figure for Masjid An-Nabawi contradicts the authentic hadith above, so it is not relied upon.")
                    }

                    Section(header: ArticleHeader("STRUCTURE AND FEATURES")) {
                        ArticleParagraph(articleMarkdown: "Masjid Al-Aqsa is part of a larger compound that includes the **Dome of the Rock (قُبَّة ٱلصَّخرَة)**, the oldest Islamic architectural monument. The entire compound is considered sacred by Muslims, and the name Masjid Al-Aqsa often refers to the entire Noble Sanctuary.")

                        ArticleParagraph(verbatim: "The mosque’s architecture and location reflect centuries of Islamic devotion and heritage.")
                    }
                }

                Section(header: ArticleHeader("MASJID AL-AQSA")) {
                    Image("Al Aqsa")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                        #if os(iOS)
                        .focusableImage("Al Aqsa", title: "Masjid al-Aqsa")
                        #endif
                        #if os(iOS)
                        .contextMenu {
                            Text(verbatim: "Image Actions")
                                .foregroundStyle(.secondary)

                            Button {
                                Settings.shared.hapticFeedback()
                                UIPasteboard.general.image = UIImage(named: "Al Aqsa")
                            } label: {
                                Text(verbatim: "Copy Image")
                                Image(systemName: "photo")
                            }
                        }
                        #endif
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Blessed by Allah and honored by the prophets, Masjid al-Aqsa remains one of the three mosques to which travel for worship is specially encouraged.")
                }

                ArticleSourcesSection(article: "AqsaView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "AqsaView")
        .navigationTitle("Masjid Al-Aqsa")
    }
}

import SwiftUI

struct WudhuView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Wudu is the minor ablution. It is a condition for the validity of the prayer, and it wipes away sins as it is performed.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Wudu (وُضُوء)**, from the root **w-d-a (و ض أ)**, meaning cleanliness and radiance, is the purification performed before **Salaah (صَلَاة)**, before touching the Quran, and before **Tawaaf (طَوَاف)** around the Ka‘bah.")
                    ArticleParagraph(verbatim: "Without it, the prayer is not accepted. The Prophet (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:135", cite: "Saheeh al-Bukhaari 135, Saheeh Muslim 225", arabic: 30...36, english: 4...24)
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HOW TO MAKE WUDU")) {
                        ArticleStep("1. Make the **niyyah (نِيَّة)**, the intention, in the heart. It is not said aloud.")
                        ArticleStep("2. Say **“Bismillah” (بِسمِ اللهِ)**.")
                        ArticleStep("3. Wash both **hands** up to the wrists, three times.")
                        ArticleStep("4. **Rinse the mouth** and **sniff water into the nose** and blow it out, three times. Use the right hand to take the water and the left to blow the nose.")
                        ArticleStep("5. Wash the **face** three times, from the hairline to under the chin and from ear to ear. If you have a thick beard, run wet fingers through it.")
                        ArticleStep("6. Wash the **right arm** to and including the elbow, three times. Then the **left arm**, three times.")
                        ArticleStep("7. **Wipe the head once**, not three times: pass wet hands from the front of the head to the back and return them to the front. Then, with the same water, **wipe the ears**, index fingers inside and thumbs behind.")
                        ArticleStep("8. Wash the **right foot** to and including the ankle, three times, running the fingers between the toes. Then the **left foot**, three times.")
                        ArticleStep("9. Then say: **“Ash-hadu an la ilaaha illallah, wahdahu la shareeka lah, wa ash-hadu anna Muhammadan abduhu wa rasooluh.”**")

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said about that closing testimony:")
                        ScriptureQuote(hadith: "muslim:234a", cite: "Saheeh Muslim 234", arabic: 111...144, english: 116...171)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE COMMAND IN THE QURAN")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "5:6", words: 0...16)
                        ArticleParagraph(verbatim: "This one verse names the four obligatory parts: the face, the arms to the elbows, wiping the head, and the feet to the ankles. The mouth and nose belong to the face, so rinsing them is part of that obligation in the Hanbali school and in the fatwas of Ibn Baaz and Ibn Uthaymeen. The intention is a condition, and the order and continuity of the washing are required; everything else in the description below is Sunnah, following the way the Prophet (peace and blessings be upon him) actually did it.")
                    }

                    Section(header: ArticleHeader("HOW TO MAKE WUDU")) {
                        ArticleStep("1. Make the **niyyah (نِيَّة)**, the intention, in the heart. It is not said aloud.")
                        ArticleStep("2. Say **“Bismillah” (بِسمِ اللهِ)**.")
                        ArticleStep("3. Wash both **hands** up to the wrists, three times.")
                        ArticleStep("4. **Rinse the mouth** and **sniff water into the nose** and blow it out, three times. Use the right hand to take the water and the left to blow the nose.")
                        ArticleStep("5. Wash the **face** three times, from the hairline to under the chin and from ear to ear. If you have a thick beard, run wet fingers through it.")
                        ArticleStep("6. Wash the **right arm** to and including the elbow, three times. Then the **left arm**, three times.")
                        ArticleStep("7. **Wipe the head once**, not three times: pass wet hands from the front of the head to the back and return them to the front. Then, with the same water, **wipe the ears**, index fingers inside and thumbs behind.")
                        ArticleStep("8. Wash the **right foot** to and including the ankle, three times, running the fingers between the toes. Then the **left foot**, three times.")
                        ArticleStep("9. Then say: **“Ash-hadu an la ilaaha illallah, wahdahu la shareeka lah, wa ash-hadu anna Muhammadan abduhu wa rasooluh.”**")

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said about that closing testimony:")
                        ScriptureQuote(hadith: "muslim:234a", cite: "Saheeh Muslim 234", arabic: 111...144, english: 116...171)

                        ArticleParagraph(verbatim: "Do not be wasteful with water. Anas (may Allah be pleased with him) described how little the Prophet (peace and blessings be upon him) used:")
                        ScriptureQuote(hadith: "bukhari:201", cite: "Saheeh al-Bukhaari 201", arabic: 14...31, english: 0...30)
                        ArticleParagraph(verbatim: "A mudd is roughly what two cupped hands hold, about two thirds of a litre. The principle itself is explicit in the Quran:")
                        ScriptureQuote(quran: "7:31", words: 8...15)
                    }
                }

                Section(header: ArticleHeader("WHAT BREAKS WUDU")) {
                    ArticleBullet(verbatim: "• Anything that exits from the front or back passage: urine, stool, or wind.")
                    ArticleBullet(verbatim: "• Deep sleep, in which a person loses awareness.")
                    ArticleBullet(verbatim: "• Loss of consciousness, whether from fainting, intoxication, or illness.")
                    ArticleBullet(verbatim: "• Touching the private parts directly with the hand, without a barrier.")
                    ArticleBullet(verbatim: "• Eating camel meat. A man asked the Prophet (peace and blessings be upon him) whether he should make wudu after eating camel meat, and he said:")
                    ScriptureQuote(hadith: "muslim:360a", cite: "Saheeh Muslim 360", arabic: 57...61, english: 55...61)
                    ArticleParagraph(verbatim: "Doubt alone does not break it. If you are certain you had wudu and merely suspect you lost it, you still have it.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE REWARD")) {
                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:244", cite: "Saheeh Muslim 244", arabic: 45...113, english: 4...104)

                        ArticleParagraph(verbatim: "He also said:")
                        ScriptureQuote(hadith: "muslim:251a", cite: "Saheeh Muslim 251", arabic: 35...69, english: 6...62)

                        ArticleParagraph(verbatim: "And he said:")
                        ScriptureQuote(hadith: "bukhari:136", cite: "Saheeh al-Bukhaari 136", arabic: 37...53, english: 24...57)

                        ArticleParagraph(verbatim: "It is also from the Sunnah to make wudu before sleeping.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Purity is a condition of prayer and a means of erasing sins. Performed with intention and in the way the Prophet performed it, wudu is an act of worship in itself.")

                    NavigationLink(destination: LazyDestination { GhuslView() }) {
                        Label("Next: How to Make Ghusl", systemImage: "drop.fill")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                    }
                }

                ArticleSourcesSection(article: "WudhuView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "WudhuView")
        .navigationTitle("How to Make Wudu")
    }
}

struct GhuslView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Ghusl is the full-body wash that lifts major ritual impurity. Until it is performed, the prayer cannot be prayed.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Ghusl (غُسل)**, from the root **gh-s-l (غ س ل)**, to wash, is a complete washing of the body with the intention of lifting major ritual impurity, **Janaabah (جَنَابَة)**.")
                    ArticleParagraph(verbatim: "Where wudu washes specific limbs, ghusl reaches the whole body. Ghusl also removes the need for a separate wudu, so long as nothing has broken it during the wash.")
                }

                Section(header: ArticleHeader("WHEN GHUSL IS OBLIGATORY")) {
                    ArticleBullet(verbatim: "• After marital relations, whether or not there is emission.")
                    ArticleBullet(verbatim: "• After the emission of maniy (sexual fluid) with desire, whether awake or from a wet dream.")
                    ArticleBullet("• At the end of **menstruation (حَيض)**.")
                    ArticleBullet("• At the end of **postpartum bleeding (نِفَاس)**.")
                    ArticleBullet(verbatim: "• Upon accepting Islam.")
                    ArticleBullet(verbatim: "• Upon death, the deceased is washed by the living.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HOW TO MAKE GHUSL")) {
                        ArticleParagraph(verbatim: "This is the way described by Aa’ishah and Maymoonah (may Allah be pleased with them), who saw the Prophet (peace and blessings be upon him) perform it (Saheeh al-Bukhaari 248, 249, 257). Aa’ishah said:")
                        ScriptureQuote(hadith: "bukhari:248", cite: "Saheeh al-Bukhaari 248", arabic: 26...60, english: 0...59)

                        ArticleStep("1. Make the **niyyah (نِيَّة)** in the heart to lift the state of janaabah.")
                        ArticleStep("2. Say **“Bismillah”**, and wash both **hands** three times.")
                        ArticleStep("3. Wash the **private parts** and any impurity from the body with the left hand, then wash the hand.")
                        ArticleStep("4. Perform a **complete wudu**, as you would for prayer.")
                        ArticleStep("5. Pour water over the **head three times**, working the fingers through the hair so the water reaches the roots of every hair.")
                        ArticleStep("6. Pour water over the **right side** of the body, then the **left side**, ensuring the water reaches every part: under the arms, inside the navel, behind the ears, between the toes.")
                        ArticleStep("7. Move from your place and **wash the feet**, if you did not wash them during the wudu.")

                        ArticleParagraph(articleMarkdown: "**The obligation is only two things:** the intention, and that water reaches every part of the body including the mouth and nose. The order and the repetition above are Sunnah. If a person simply immerses fully in water with the intention, the ghusl is valid.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHEN GHUSL IS RECOMMENDED")) {
                        ArticleBullet("• Before the **Jumuah (جُمُعَة)** prayer.")
                        ArticleBullet("• Before the two **Eid** prayers.")
                        ArticleBullet("• Before entering **Ihraam (إِحرَام)** for Hajj or Umrah.")
                        ArticleBullet(verbatim: "• After washing a deceased person.")
                    }

                    Section(header: ArticleHeader("THE COMMAND IN THE QURAN")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "5:6", words: 17...20)
                        ArticleParagraph(verbatim: "And He says:")
                        ScriptureQuote(quran: "4:43", words: 0...18)
                    }

                    Section(header: ArticleHeader("HOW TO MAKE GHUSL")) {
                        ArticleParagraph(verbatim: "This is the way described by Aa’ishah and Maymoonah (may Allah be pleased with them), who saw the Prophet (peace and blessings be upon him) perform it (Saheeh al-Bukhaari 248, 249, 257). Aa’ishah said:")
                        ScriptureQuote(hadith: "bukhari:248", cite: "Saheeh al-Bukhaari 248", arabic: 26...60, english: 0...59)

                        ArticleStep("1. Make the **niyyah (نِيَّة)** in the heart to lift the state of janaabah.")
                        ArticleStep("2. Say **“Bismillah”**, and wash both **hands** three times.")
                        ArticleStep("3. Wash the **private parts** and any impurity from the body with the left hand, then wash the hand.")
                        ArticleStep("4. Perform a **complete wudu**, as you would for prayer.")
                        ArticleStep("5. Pour water over the **head three times**, working the fingers through the hair so the water reaches the roots of every hair.")
                        ArticleStep("6. Pour water over the **right side** of the body, then the **left side**, ensuring the water reaches every part: under the arms, inside the navel, behind the ears, between the toes.")
                        ArticleStep("7. Move from your place and **wash the feet**, if you did not wash them during the wudu.")

                        ArticleParagraph(articleMarkdown: "**The obligation is only two things:** the intention, and that water reaches every part of the body including the mouth and nose. The order and the repetition above are Sunnah. If a person simply immerses fully in water with the intention, the ghusl is valid.")

                        ArticleParagraph(articleMarkdown: "Women do **not** need to undo braided hair for the ghusl of janaabah, so long as the water reaches the roots. Umm Salamah (may Allah be pleased with her) asked about this, and the Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:330a", cite: "Saheeh Muslim 330", arabic: 59...72, english: 34...59)
                    }

                    Section(header: ArticleHeader("IF THERE IS NO WATER: TAYAMMUM")) {
                        ArticleParagraph(articleMarkdown: "If water cannot be found, or using it would cause harm or illness, then **Tayammum (تَيَمُّم)**, dry purification, takes its place for both wudu and ghusl. Allah says in the same verse:")
                        ScriptureQuote(quran: "5:6", words: 36...45)
                        ArticleParagraph(verbatim: "Strike clean earth once with both palms, then wipe the face, then wipe the hands. That is all.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Ghusl lifts major impurity and returns a person to the state in which they may pray. Its obligation is simple: intend it, and let the water reach all of you.")
                }

                ArticleSourcesSection(article: "GhuslView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "GhuslView")
        .navigationTitle("How to Make Ghusl")
    }
}

struct JumuahView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Jumuah is the Friday congregational prayer that takes the place of Dhuhr: two khutbahs, then two rak‘ah recited aloud. It is an obligation on every Muslim man who is adult, sane, resident and free of an excuse, and it is only Jumuah when it is prayed in its time, in congregation, in a settled community, after the khutbah.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "Jumuah (جُمُعَة) comes from the root **j-m-a (ج م ع)**, meaning to gather or congregate. It refers to the Friday congregational prayer that replaces Dhuhr.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                    ScriptureQuote(quran: "62:9")

                    ArticleParagraph(articleMarkdown: "Jumuah prayer consists of a sermon (**Khutbah, خُطبَة**) followed by a two-rak‘ah Salaah led by the Imam. It is obligatory for Muslim men who can attend, though it is not obligatory for women. The Prophet (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "abudawud:1067", cite: "Sunan Abi Daawood 1067; graded saheeh by al-Albaani", arabic: 34...51, english: 4...28)
                }

                Section(header: ArticleHeader("IMPORTANCE")) {
                    ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")

                    ScriptureQuote(hadith: "muslim:854a", cite: "Saheeh Muslim 854", arabic: 30...45, english: 0...30)

                    ArticleParagraph(verbatim: "Friday is considered the best day of the week in Islam. It unites the community, strengthens social bonds, and serves as a weekly reminder of our responsibilities toward Allah (Glorified and Exalted be He) and humanity.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHO MUST ATTEND")) {
                        ArticleParagraph(verbatim: "Jumuah is an obligation on every Muslim man who is:")
                        ArticleBullet("• **Adult and sane.**")
                        ArticleBullet("• **Resident**, not travelling. A traveller prays Dhuhr, shortened; if he attends Jumuah, it counts for him.")
                        ArticleBullet("• **Free of a real excuse**: an illness that makes going hard, fear for himself or his family, heavy rain or mud, or caring for a sick person who cannot be left.")
                        ArticleParagraph(verbatim: "Leaving it without an excuse is a major sin. The Prophet (peace and blessings be upon him) said from his minbar:")
                        ScriptureQuote(hadith: "muslim:865", cite: "Saheeh Muslim 865", arabic: 45...58, english: 0...21)
                    }

                    Section(header: ArticleHeader("WHAT MAKES IT VALID")) {
                        ArticleParagraph(verbatim: "Four conditions, on top of those of every prayer. If one is missing, what was prayed is not Jumuah, and Dhuhr is prayed instead:")
                        ArticleStep("1. **Its time.** Jumuah is prayed in the time of Dhuhr, once the sun has passed its height, the time every school accepts.")
                        ArticleStep("2. **A congregation.** Jumuah is never prayed alone.")
                        ArticleStep("3. **A settled community.** It is held in a town or village where people live, not by travellers camped on the road.")
                        ArticleStep("4. **The khutbah before it.** The Prophet never prayed Jumuah without a khutbah. A Jumuah prayed without one is not Jumuah.")
                        ArticleParagraph(verbatim: "Jumuah is not made up. Whoever misses it, with an excuse or without, prays Dhuhr.")
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Take a ghusl**, clean yourself, wear your best clean clothes, use the siwaak, and (for men) put on perfume. The Prophet said:")
                        ScriptureQuote(hadith: "bukhari:879", cite: "Saheeh al-Bukhaari 879", arabic: 35...41, english: 5...24)
                        ArticleParagraph(verbatim: "Most scholars took “compulsory” here as strongly emphasised; Ibn al-Uthaymeen held it to be obligatory on whoever attends, though the prayer is not void without it. Either way, do not leave it.")
                        ArticleStep("2. **Go early, walking if you can, and sit near the imam.** The earlier you arrive, the greater the reward.")
                        ArticleStep("3. **On entering, pray two rak‘ah before you sit**, even if the khutbah has begun; then keep them short. The Prophet stopped his khutbah for a man who sat down without them:")
                        ScriptureQuote(hadith: "muslim:875a", cite: "Saheeh Muslim 875", arabic: 26...57, english: 0...19)
                        ArticleStep("4. **Then pray what you can** until the imam comes out, or recite Quran and remember Allah. There is no fixed sunnah before Jumuah.")
                        ArticleStep("5. **Do not step over people, and do not move anyone from his place.** Fill the front rows as you arrive, and sit where there is room.")
                        ArticleStep("6. **Once the imam begins, listen in silence.** Do not talk, do not tell anyone else to be quiet, and leave your phone, your clothes and the carpet alone.")
                        ScriptureQuote(hadith: "bukhari:934", cite: "Saheeh al-Bukhaari 934", arabic: 31...40, english: 5...30)
                        ArticleStep("7. **Pray the two rak‘ah behind the imam**, then the sunnah after it, as below.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHO MUST ATTEND")) {
                        ArticleParagraph(verbatim: "Jumuah is an obligation on every Muslim man who is:")
                        ArticleBullet("• **Adult and sane.**")
                        ArticleBullet("• **Resident**, not travelling. A traveller prays Dhuhr, shortened; if he attends Jumuah, it counts for him.")
                        ArticleBullet("• **Free of a real excuse**: an illness that makes going hard, fear for himself or his family, heavy rain or mud, or caring for a sick person who cannot be left.")
                        ArticleParagraph(verbatim: "As the hadith above says, it is not an obligation on women, children or the sick. Nor is it on travellers: the Prophet did not pray Jumuah on his journeys, and at Arafah, on a Friday, he prayed Dhuhr and Asr (Saheeh Muslim 1218). A woman who attends and prays it with the imam has prayed it, and it takes the place of her Dhuhr.")
                        ScriptureQuote(hadith: "muslim:1218", cite: "Saheeh Muslim 1218", arabic: 922...935, english: 1567...1607)
                        ArticleParagraph(verbatim: "Leaving it without an excuse is a major sin. The Prophet (peace and blessings be upon him) said from his minbar:")
                        ScriptureQuote(hadith: "muslim:865", cite: "Saheeh Muslim 865", arabic: 45...58, english: 0...21)
                        ScriptureQuote(hadith: "abudawud:1052", cite: "Sunan Abi Daawood 1052; graded hasan saheeh by al-Albaani", arabic: 33...42, english: 4...25)
                    }

                    Section(header: ArticleHeader("WHAT MAKES IT VALID")) {
                        ArticleParagraph(verbatim: "Four conditions, on top of those of every prayer. If one is missing, what was prayed is not Jumuah, and Dhuhr is prayed instead:")
                        ArticleStep("1. **Its time.** Jumuah is prayed in the time of Dhuhr, once the sun has passed its height. The Hanbali school allows it earlier in the day as well, but praying it after the zawaal is the way every school accepts:")
                        ScriptureQuote(hadith: "bukhari:904", cite: "Saheeh al-Bukhaari 904", arabic: 30...35, english: 0...11)
                        ArticleStep("2. **A congregation.** Jumuah is never prayed alone. The scholars differ over the least number: forty in the Shaafi‘i and Hanbali schools, and three, one to give the khutbah and two to hear it, in the view Ibn Taymiyyah and Ibn al-Uthaymeen held strongest.")
                        ArticleStep("3. **A settled community.** It is held in a town or village where people live, not by travellers camped on the road; that is why the Prophet prayed Dhuhr at Arafah.")
                        ArticleStep("4. **The khutbah before it.** The Prophet never prayed Jumuah without a khutbah, and the ayah commands hastening to “the remembrance of Allah”, which the scholars explained as the khutbah. A Jumuah prayed without one is not Jumuah.")
                        ArticleParagraph(verbatim: "Jumuah is not made up. Whoever misses it, with an excuse or without, prays Dhuhr. And it cannot be prayed at home behind a screen: a khutbah followed over a broadcast does not make a congregation.")
                    }

                    Section(header: ArticleHeader("THE ADHAN OF JUMUAH")) {
                        ArticleParagraph(verbatim: "In the Prophet's time Jumuah had one Adhan, called as the imam sat on the minbar; Uthmaan (may Allah be pleased with him) added an earlier one when Madinah grew:")
                        ScriptureQuote(hadith: "bukhari:912", cite: "Saheeh al-Bukhaari 912", arabic: 14...53, english: 0...45)
                        ArticleParagraph(verbatim: "The second Adhan, the one called as the imam sits, is the call meant in the ayah: from it, buying and selling stop for those who must attend. How the two calls are given, and what the scholars said about Uthmaan's, is in the guide to the Adhan.")
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Take a ghusl**, clean yourself, wear your best clean clothes, use the siwaak, and (for men) put on perfume. The Prophet said:")
                        ScriptureQuote(hadith: "bukhari:879", cite: "Saheeh al-Bukhaari 879", arabic: 35...41, english: 5...24)
                        ArticleParagraph(verbatim: "Most scholars took “compulsory” here as strongly emphasised, because he also said that whoever makes wudu for Jumuah has done well, and the ghusl is better (Sunan Abi Daawood 354; graded hasan by al-Albaani). Ibn al-Uthaymeen held it to be obligatory on whoever attends, though the prayer is not void without it. Either way, do not leave it.")
                        ScriptureQuote(hadith: "abudawud:354", cite: "Sunan Abi Daawood 354; graded hasan by al-Albaani", arabic: 22...31, english: 0...23)
                        ArticleStep("2. **Go early, walking if you can, and sit near the imam.** The earlier you arrive, the greater the reward, and when the imam comes out the angels close their records and sit to listen (Saheeh al-Bukhaari 881):")
                        ScriptureQuote(hadith: "bukhari:881", cite: "Saheeh al-Bukhaari 881, Saheeh Muslim 850", arabic: 38...88, english: 5...129)
                        ScriptureQuote(hadith: "abudawud:345", cite: "Sunan Abi Daawood 345; graded saheeh by al-Albaani", arabic: 34...59, english: 8...67)
                        ArticleStep("3. **On entering, pray two rak‘ah before you sit**, even if the khutbah has begun; then keep them short. The Prophet stopped his khutbah for a man who sat down without them:")
                        ScriptureQuote(hadith: "muslim:875a", cite: "Saheeh Muslim 875", arabic: 26...57, english: 0...19)
                        ArticleStep("4. **Then pray what you can** until the imam comes out, or recite Quran and remember Allah. There is no fixed sunnah before Jumuah; the hadith says only that he “prayed what was fixed for him”:")
                        ScriptureQuote(hadith: "muslim:857a", cite: "Saheeh Muslim 857", arabic: 29...56, english: 0...51)
                        ArticleStep("5. **Do not step over people, and do not move anyone from his place.** Fill the front rows as you arrive, and sit where there is room:")
                        ScriptureQuote(hadith: "abudawud:1118", cite: "Sunan Abi Daawood 1118; graded saheeh by al-Albaani", arabic: 40...64, english: 32...60)
                        ArticleStep("6. **Once the imam begins, listen in silence.** Do not talk, do not tell anyone else to be quiet, and leave your phone, your clothes and the carpet alone; he said that whoever fiddles with the pebbles has engaged in idle talk (Saheeh Muslim 857).")
                        ScriptureQuote(hadith: "bukhari:934", cite: "Saheeh al-Bukhaari 934", arabic: 31...40, english: 5...30)
                        ArticleStep("7. **Pray the two rak‘ah behind the imam**, then the sunnah after it, as below.")
                    }

                    Section(header: ArticleHeader("THE KHUTBAH AND THE PRAYER")) {
                        ArticleParagraph(verbatim: "The imam climbs the minbar, greets the people and sits while the Adhan is called. He then stands for the first khutbah, sits briefly, and stands for the second:")
                        ScriptureQuote(hadith: "muslim:862a", cite: "Saheeh Muslim 862", arabic: 27...39, english: 0...18)
                        ArticleParagraph(verbatim: "When he comes down, the Iqaamah is given and he leads two rak‘ah, reciting aloud. In both Eids and in Jumuah the Prophet would recite al-A‘la and al-Ghaashiyah:")
                        ScriptureQuote(hadith: "muslim:878a", cite: "Saheeh Muslim 878", arabic: 40...76, english: 0...43)
                        ArticleParagraph(verbatim: "Or al-Jumuah in the first rak‘ah and al-Munaafiqoon in the second:")
                        ScriptureQuote(hadith: "muslim:877a", cite: "Saheeh Muslim 877", arabic: 73...84, english: 73...86)
                    }
                }

                Section(header: ArticleHeader("IF YOU ARRIVE LATE")) {
                    ArticleParagraph(verbatim: "If you reach the imam before he rises from the bowing of the second rak‘ah, you have caught Jumuah: after his tasleem, stand and pray one more rak‘ah.")
                    ScriptureQuote(hadith: "ibnmajah:1121", cite: "Sunan Ibn Maajah 1121; graded saheeh by al-Albaani", arabic: 34...41, english: 0...12)
                    ArticleParagraph(verbatim: "If you join after that bowing, in the prostrations or the tashahhud, you have missed Jumuah: join him with the intention of Dhuhr, and after his tasleem complete four rak‘ah. If you missed it altogether, pray Dhuhr, four rak‘ah.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("AFTER THE PRAYER")) {
                        ArticleParagraph(verbatim: "Pray four rak‘ah in the mosque, or two at home. Both are from him:")
                        ScriptureQuote(hadith: "muslim:881a", cite: "Saheeh Muslim 881", arabic: 26...32, english: 0...19)
                        ScriptureQuote(hadith: "bukhari:937", cite: "Saheeh al-Bukhaari 937", arabic: 37...45, english: 38...58)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("AFTER THE PRAYER")) {
                        ArticleParagraph(verbatim: "Pray four rak‘ah in the mosque, or two at home. Both are from him:")
                        ScriptureQuote(hadith: "muslim:881a", cite: "Saheeh Muslim 881", arabic: 26...32, english: 0...19)
                        ScriptureQuote(hadith: "bukhari:937", cite: "Saheeh al-Bukhaari 937", arabic: 37...45, english: 38...58)
                        ArticleParagraph(verbatim: "Ibn Taymiyyah and Ibn al-Qayyim joined the two: four when they are prayed in the mosque, two when they are prayed at home. Do not join the obligatory prayer straight onto the sunnah; speak, or move to another place first, as Mu‘aawiyah reported the Prophet commanded (Saheeh Muslim 883).")
                        ScriptureQuote(hadith: "muslim:883a", cite: "Saheeh Muslim 883", arabic: 61...87, english: 45...88)
                        ArticleParagraph(verbatim: "Then go out and seek Allah's bounty:")
                        ScriptureQuote(quran: "62:10")
                    }

                    Section(header: ArticleHeader("RECOMMENDED PRACTICES")) {
                        ArticleParagraph(verbatim: "Muslims are encouraged to engage in specific acts of worship on Jumuah:")

                        ArticleStep("1. **Reciting Surah Al-Kahf (سُورَة ٱلكَهف):** The Prophet Muhammad (peace and blessings be upon him) said:")

                        ScriptureQuote(text: "“Whoever reads Surah Al-Kahf on Friday, a light will shine for him between the two Fridays” (al-Haakim 2/368 and al-Bayhaqi; graded saheeh by al-Albaani, Saheeh al-Jaami‘ 6470).", arabic: "مَن قَرَأَ سُورَةَ الكَهفِ فِي يَومِ الجُمُعَةِ أَضَاءَ لَهُ مِنَ النُّورِ مَا بَينَ الجُمُعَتَينِ", dimmed: true)

                        ArticleStep("2. **Sending Salawaat on the Prophet (peace and blessings be upon him):**")

                        ScriptureQuote(hadith: "abudawud:1047", cite: "Sunan Abi Daawood 1047; graded saheeh by al-Albaani", arabic: 33...56, english: 4...53)

                        ScriptureQuote(hadith: "muslim:408", cite: "Saheeh Muslim 408", arabic: 32...39, english: 6...16)

                        ArticleStep("3. **Making Dua (Supplication)**: There is a special hour on Friday during which all supplications are accepted. The Prophet Muhammad (peace and blessings be upon him) said:")

                        ScriptureQuote(hadith: "nasai:1389", cite: "Sunan an-Nasaa’i 1389; graded saheeh by al-Albaani", arabic: 53...73, english: 6...38)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Eid falls on a Friday.** Whoever prayed the Eid prayer has a concession to leave Jumuah and pray Dhuhr instead; the imam still holds Jumuah for those who come, and attending is better. Zayd ibn Arqam was asked what the Prophet did:")
                        ScriptureQuote(hadith: "abudawud:1070", cite: "Sunan Abi Daawood 1070; graded saheeh by al-Albaani", arabic: 47...60, english: 45...68)
                        ArticleParagraph(articleMarkdown: "**I keep falling asleep in the khutbah.** Move to another place; the movement wakes you:")
                        ScriptureQuote(hadith: "tirmidhi:526", cite: "Jaami‘ at-Tirmidhi 526; graded saheeh by al-Albaani", arabic: 29...37, english: 3...21)
                        ArticleParagraph(articleMarkdown: "**May I say aameen or send blessings during the khutbah?** Under your breath, yes: send blessings on the Prophet when he is mentioned, and say aameen silently to the imam's dua. Do not answer a greeting or start a conversation.")
                        ArticleParagraph(articleMarkdown: "**Does my job excuse me?** Work alone is not an excuse; arrange to attend, even at the cost of an unpaid hour. The scholars excused only those whose work cannot be left without harm to others, such as a guard on duty or a doctor with a patient, and they pray Dhuhr.")
                        ArticleParagraph(articleMarkdown: "**Is there a sunnah before Jumuah?** No fixed one. Pray the two rak‘ah on entering, then whatever you can until the imam comes out.")
                        ArticleParagraph(articleMarkdown: "**Can more than one Jumuah be held in a town?** Where one mosque cannot hold everyone, yes. Without that need the scholars disliked dividing a town's Jumuah.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Friday is the best day of the week. Prepare for it with a ghusl, come early, pray what you can, listen in silence, and pray the two rak‘ah behind the imam, then the sunnah after it. Jumuah stands on four things: its time, a congregation, a settled community, and the khutbah before it.")

                    NavigationLink(destination: LazyDestination { KhutbahView() }) {
                        Label("Next: How to Give the Khutbah", systemImage: "building.columns")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                    }
                }

                ArticleSourcesSection(article: "JumuahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "JumuahView")
        .navigationTitle(AppLanguage.article("Jumuah"))
    }
}

struct AdhanOtherView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Adhan is the call that announces each of the five daily prayers, first given in Madinah by Bilaal ibn Rabaah. It counts when it is called after the prayer's time has entered, in its own Arabic words and order, without a break, aloud, by a Muslim man. On Friday it is called as the imam sits on the minbar.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HISTORY")) {
                        ArticleParagraph(articleMarkdown: "The Adhan (أَذَان) is the Islamic call to prayer, from the root **a-dh-n (أ ذ ن)** meaning to announce or proclaim.")

                        ArticleParagraph(verbatim: "The Companions had discussed how to announce the prayer, and some suggested a bell like the Christians or a horn like the Jews. The words of the Adhan were shown to Abdullah ibn Zayd (may Allah be pleased with him) in a dream, which the Prophet confirmed as a true vision, telling him to teach them to Bilaal ibn Rabaah (may Allah be pleased with him), whose voice was the louder (Sunan Abi Daawood 499; graded hasan saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "abudawud:499", cite: "Sunan Abi Daawood 499; graded hasan saheeh by al-Albaani", arabic: 192...223, english: 229...282)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HISTORY")) {
                        ArticleParagraph(articleMarkdown: "The Adhan (أَذَان) is the Islamic call to prayer, from the root **a-dh-n (أ ذ ن)** meaning to announce or proclaim.")

                        ArticleParagraph(verbatim: "It is recited in Arabic to announce the time for each of the five daily prayers.")

                        ArticleParagraph(verbatim: "The Adhan originated during the time of Prophet Muhammad (peace and blessings be upon him) in Madinah.")

                        ArticleParagraph(verbatim: "The Companions had discussed how to announce the prayer, and some suggested a bell like the Christians or a horn like the Jews. Umar (may Allah be pleased with him) proposed that a man call the people, and the Prophet (peace and blessings be upon him) ordered Bilaal to rise and give the call (Saheeh al-Bukhaari 604). The words of the Adhan were shown to Abdullah ibn Zayd (may Allah be pleased with him) in a dream, which the Prophet confirmed as a true vision, telling him to teach them to Bilaal ibn Rabaah (may Allah be pleased with him), whose voice was the louder (Sunan Abi Daawood 499; graded hasan saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "bukhari:604", cite: "Saheeh al-Bukhaari 604, Saheeh Muslim 377", arabic: 20...69, english: 0...99)
                        ScriptureQuote(hadith: "abudawud:499", cite: "Sunan Abi Daawood 499; graded hasan saheeh by al-Albaani", arabic: 192...223, english: 229...282)
                    }
                }

                Section(header: ArticleHeader("WORDS OF THE ADHAN")) {
                    ArticleArabic(verbatim: """
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ

                    أَشهَدُ أَن لَا إِلَٰهَ إِلَّا اللَّهُ
                    أَشهَدُ أَن لَا إِلَٰهَ إِلَّا اللَّهُ

                    أَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ
                    أَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ

                    حَيَّ عَلَى الصَّلَاةِ، حَيَّ عَلَى الصَّلَاةِ
                    حَيَّ عَلَى الفَلَاحِ، حَيَّ عَلَى الفَلَاحِ

                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ
                    لَا إِلَٰهَ إِلَّا اللَّهُ
                    """)

                    Text(verbatim: """
                    Allahu Akbar, Allahu Akbar
                    Allahu Akbar, Allahu Akbar

                    Ashhadu an la ilaaha illallah
                    Ashhadu an la ilaaha illallah

                    Ashhadu anna Muhammadan rasool Allah
                    Ashhadu anna Muhammadan rasool Allah

                    Hayya 'ala as-salaah, Hayya 'ala as-salaah
                    Hayya 'ala al-falaah, Hayya 'ala al-falaah

                    Allahu Akbar, Allahu Akbar
                    La ilaaha illallah
                    """)
                    .font(.body)

                    Text(verbatim: """
                    Allah is the greatest, Allah is the greatest
                    Allah is the greatest, Allah is the greatest

                    I bear witness that there is no deity but Allah
                    I bear witness that there is no deity but Allah

                    I bear witness that Muhammad is the Messenger of Allah
                    I bear witness that Muhammad is the Messenger of Allah

                    Come to prayer, Come to prayer
                    Come to success, Come to success

                    Allah is the greatest, Allah is the greatest
                    There is no deity but Allah
                    """)
                    .font(.body)

                    ArticleCallout("The noon of “an” melts into the laam after it (idghaam), so “an la ilaaha” is said “allaa ilaaha”, and “illa Allah” runs together as “illallah”: Ashhadu allaa ilaaha illallah. “Rasool Allah” joins the same way, rasoolullah, and so does the closing line, La ilaaha illallah.", title: "How it is said", systemImage: "waveform")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ONLY FOR FAJR")) {
                        ArticleParagraph(articleMarkdown: "**ONLY FOR FAJR:** the following line is added, and it is said in no other Adhan. It comes after “Hayya ala al-falaah” and before the closing takbeer.")

                        Text(articleMarkdown: "**ONLY FOR FAJR:**")
                            .font(.body)
                            .foregroundColor(appearance.accent)

                        ArticleArabic(verbatim: "الصَّلَاةُ خَيرٌ مِنَ النَّومِ")

                        ArticleParagraph(verbatim: "As-salaatu khayrun mina-nawm\n(Prayer is better than sleep)")

                        ArticleParagraph(verbatim: "This line is said twice, and only in the Adhan for Fajr. It is never said in the Adhan for Dhuhr, Asr, Maghrib, or Isha, and it is never said in the Iqaamah.")
                    }

                    Section(header: ArticleHeader("WHAT MAKES IT VALID")) {
                        ArticleParagraph(verbatim: "The Adhan is an act of worship with conditions of its own. A call that misses one of them is not the Adhan, and it is given again:")
                        ArticleStep("1. **The time has entered.** The Adhan announces a prayer whose time has come, so a call given before the time is repeated once it begins. The one exception is Fajr, which may have a first call in the last part of the night and a second at true dawn.")
                        ArticleStep("2. **Its own Arabic words, in their order.** The phrases are said as the Prophet (peace and blessings be upon him) taught them, none dropped and none moved. A translation is not the Adhan.")
                        ArticleStep("3. **One unbroken call, by one caller.** The phrases follow each other without a long pause, and one person says all of them.")
                        ArticleStep("4. **The caller is a Muslim man of sound mind.** A boy old enough to understand what he is doing may call it. The Adhan for men is not given by a woman.")
                        ArticleStep("5. **It is called aloud, by someone present.** It is meant to be heard, so it is raised as far as the voice will carry. A recording played at prayer time is not an Adhan.")
                    }

                    Section(header: ArticleHeader("THE ADHAN FOR JUMUAH")) {
                        ArticleParagraph(verbatim: "The Friday Adhan has the same words as the others, without the Fajr line. In the Prophet's time there was one, called when the imam sat on the minbar, and Uthmaan (may Allah be pleased with him) added an earlier call when Madinah grew. Both are followed among the people of the Sunnah, and neither is a reason to quarrel.")
                    }

                    Section(header: ArticleHeader("THE VIRTUE OF THE ADHAN")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:615", cite: "Saheeh al-Bukhaari 615", arabic: 29...44, english: 4...39)
                        ArticleParagraph(verbatim: "Answer the muadhin. He said:")
                        ScriptureQuote(hadith: "muslim:383", cite: "Saheeh Muslim 383", arabic: 30...37, english: 0...11)
                        ArticleParagraph(verbatim: "Except at “Hayya ala as-salaah” and “Hayya ala al-falaah,” where you say “La hawla wa la quwwata illa billah” (there is no might nor power except with Allah), as Umar (may Allah be pleased with him) reported from him (Saheeh Muslim 385).")
                        ScriptureQuote(hadith: "muslim:385", cite: "Saheeh Muslim 385", arabic: 97...123, english: 85...128)
                        ArticleParagraph(verbatim: "Then send blessings on the Prophet (peace and blessings be upon him), and say:")
                        ScriptureQuote(hadith: "bukhari:614", cite: "Saheeh al-Bukhaari 614", arabic: 29...54, english: 4...88)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ONLY FOR FAJR")) {
                        ArticleParagraph(articleMarkdown: "**ONLY FOR FAJR:** the following line is added, and it is said in no other Adhan. It comes after “Hayya ala al-falaah” and before the closing takbeer.")

                        Text(articleMarkdown: "**ONLY FOR FAJR:**")
                            .font(.body)
                            .foregroundColor(appearance.accent)

                        ArticleArabic(verbatim: "الصَّلَاةُ خَيرٌ مِنَ النَّومِ")

                        ArticleParagraph(verbatim: "As-salaatu khayrun mina-nawm\n(Prayer is better than sleep)")

                        ArticleParagraph(verbatim: "This line is said twice, and only in the Adhan for Fajr. It is never said in the Adhan for Dhuhr, Asr, Maghrib, or Isha, and it is never said in the Iqaamah. Abu Mahdhoorah (may Allah be pleased with him), whom the Prophet (peace and blessings be upon him) taught the Adhan, said:")
                        ScriptureQuote(hadith: "nasai:647", cite: "Sunan an-Nasaa’i 647; graded saheeh by al-Albaani", arabic: 20...52, english: 0...67)
                    }

                    Section(header: ArticleHeader("WHAT MAKES IT VALID")) {
                        ArticleParagraph(verbatim: "The Adhan is an act of worship with conditions of its own. A call that misses one of them is not the Adhan, and it is given again:")
                        ArticleStep("1. **The time has entered.** The Adhan announces a prayer whose time has come, so a call given before the time is repeated once it begins. The one exception is Fajr, which may have a first call in the last part of the night and a second at true dawn:")
                        ScriptureQuote(hadith: "bukhari:617", cite: "Saheeh al-Bukhaari 617", arabic: 27...50, english: 8...47)
                        ArticleStep("2. **Its own Arabic words, in their order.** The phrases are said as the Prophet (peace and blessings be upon him) taught them, none dropped and none moved. A translation is not the Adhan, and neither is a slip that changes the meaning, such as turning “Allahu” into a question, “Allahu”, or stretching “Akbar” into “Akbar”, which means drums.")
                        ArticleStep("3. **One unbroken call, by one caller.** The phrases follow each other without a long pause, and one person says all of them. Two callers who each say half have not given an Adhan.")
                        ArticleStep("4. **The caller is a Muslim man of sound mind.** A boy old enough to understand what he is doing may call it. The Adhan for men is not given by a woman.")
                        ArticleStep("5. **It is called aloud, by someone present.** It is meant to be heard, so it is raised as far as the voice will carry. A recording played at prayer time is not an Adhan, as the Standing Committee and Ibn al-Uthaymeen explained: the Adhan is worship a person performs, not a sound that is played.")
                        ArticleParagraph(verbatim: "In the Hanbali school, and in the fatwas of Ibn Baaz and Ibn al-Uthaymeen, calling it is a collective obligation (fard kifaayah) on the men of a town or a travelling group: once some call it, the rest are free of the duty. The Prophet told a group going home to their people:")
                        ScriptureQuote(hadith: "bukhari:628", cite: "Saheeh al-Bukhaari 628", arabic: 46...53, english: 50...79)
                    }

                    Section(header: ArticleHeader("HOW TO CALL IT")) {
                        ArticleStep("1. **Be in wudu** if you can. It is the better state for remembering Allah, though an Adhan called without wudu still counts.")
                        ArticleStep("2. **Stand, facing the qiblah**, somewhere the call will carry: a raised place, or a loudspeaker. When the Companions settled on calling people to prayer, the Prophet told Bilaal to get up and call it (Saheeh al-Bukhaari 604).")
                        ArticleStep("3. **Put your index fingers in your ears.** Bilaal did, and the scholars mention two benefits: the voice rises further, and someone too far away to hear can see that the Adhan is being called.")
                        ArticleStep("4. **Turn your face to the right at “Hayya ala as-salaah” and to the left at “Hayya ala al-falaah”**, keeping your feet and chest toward the qiblah:")
                        ScriptureQuote(hadith: "tirmidhi:197", cite: "Jaami‘ at-Tirmidhi 197; graded saheeh by al-Albaani", arabic: 18...30, english: 0...23)
                        ArticleStep("5. **Raise your voice**, clear and unhurried, pausing after each phrase. Make it beautiful without singing it; the scholars disliked stretching the words into a tune that changes them. Everything that hears it will testify for you:")
                        ScriptureQuote(hadith: "bukhari:609", cite: "Saheeh al-Bukhaari 609", arabic: 40...66, english: 14...65)
                        ArticleStep("6. **For Fajr**, add “As-salaatu khayrun mina-nawm” twice after “Hayya ala al-falaah”, as above.")
                        ArticleStep("7. **Add nothing to it.** No recitation or dhikr broadcast before it, no “sayyiduna” inside it, and no blessing on the Prophet chanted over the loudspeaker afterward as though it belonged to the call. After it the muadhin, like everyone who heard it, sends blessings on the Prophet quietly and asks Allah to grant him the Waseelah.")
                    }

                    Section(header: ArticleHeader("THE ADHAN FOR JUMUAH")) {
                        ArticleParagraph(verbatim: "The Friday Adhan has the same words as the others, without the Fajr line. In the Prophet's time there was one, called when the imam sat on the minbar, and Uthmaan (may Allah be pleased with him) added an earlier call when Madinah grew:")
                        ScriptureQuote(hadith: "bukhari:912", cite: "Saheeh al-Bukhaari 912", arabic: 14...53, english: 0...45)
                        ArticleParagraph(articleMarkdown: "The narration calls Uthmaan's call the **third** because it counts the Iqaamah as a call too. So a Friday runs:")
                        ArticleStep("1. **The first Adhan**, Uthmaan's, some time before the khutbah, to tell people that Jumuah is near. Ibn Baaz and Ibn al-Uthaymeen held it to be a Sunnah of a rightly guided caliph, whose way the Prophet told us to hold to (Sunan Abi Daawood 4607; graded saheeh by al-Albaani). Al-Albaani kept to the single Adhan of the Prophet's time, since the reason Uthmaan added it, people spread far through the markets, no longer applies where everyone keeps the time. Both are followed among the people of the Sunnah, and neither is a reason to quarrel.")
                        ScriptureQuote(hadith: "abudawud:4607", cite: "Sunan Abi Daawood 4607; graded saheeh by al-Albaani", arabic: 112...122, english: 159...178)
                        ArticleStep("2. **The second Adhan**, the one of the Prophet's time: the imam comes out, greets the people and sits on the minbar, and the muadhin calls. This is the call meant in Surat al-Jumuah, after which buying and selling stop for those who must attend.")
                        ArticleStep("3. **The khutbah**, then the **Iqaamah** as the imam comes down, then the two rak‘ah.")
                    }

                    Section(header: ArticleHeader("THE VIRTUE OF THE ADHAN")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "62:9", words: 0...14)
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:615", cite: "Saheeh al-Bukhaari 615", arabic: 29...44, english: 4...39)
                        ScriptureQuote(hadith: "bukhari:608", cite: "Saheeh al-Bukhaari 608", arabic: 26...36, english: 4...28)
                        ArticleParagraph(verbatim: "Answer the muadhin. He said:")
                        ScriptureQuote(hadith: "muslim:383", cite: "Saheeh Muslim 383", arabic: 30...37, english: 0...11)
                        ArticleParagraph(verbatim: "Except at “Hayya ala as-salaah” and “Hayya ala al-falaah,” where you say “La hawla wa la quwwata illa billah” (there is no might nor power except with Allah), as Umar (may Allah be pleased with him) reported from him (Saheeh Muslim 385).")
                        ScriptureQuote(hadith: "muslim:385", cite: "Saheeh Muslim 385", arabic: 97...123, english: 85...128)
                        ArticleParagraph(verbatim: "Then send blessings on the Prophet (peace and blessings be upon him), and say:")
                        ScriptureQuote(hadith: "bukhari:614", cite: "Saheeh al-Bukhaari 614", arabic: 29...54, english: 4...88)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I pray alone, at home or on a journey. Do I call the Adhan?** It is Sunnah to call the Adhan and the Iqaamah even alone, even where no one will hear but the land and what lives on it:")
                        ScriptureQuote(hadith: "abudawud:1203", cite: "Sunan Abi Daawood 1203; graded saheeh by al-Albaani", arabic: 31...60, english: 8...58)
                        ArticleParagraph(articleMarkdown: "**The mosque's Adhan reaches my home. Must I call again?** No. The town's Adhan covers whoever hears it. Giving the Iqaamah before you pray is still the Sunnah.")
                        ArticleParagraph(articleMarkdown: "**Do women call the Adhan?** It is not required of women. Women praying together may give the Iqaamah, and the scholars saw no harm in an Adhan among themselves, in a voice that does not reach men.")
                        ArticleParagraph(articleMarkdown: "**I am joining two prayers, or making up several.** Call one Adhan, then an Iqaamah before each prayer. At Arafah the Prophet had the Adhan called once, with an Iqaamah for Dhuhr and another for Asr (Saheeh Muslim 1218); and when they slept through Fajr on a journey, Bilaal called the Adhan once they woke, and they prayed (Saheeh Muslim 681).")
                        ScriptureQuote(hadith: "muslim:1218", cite: "Saheeh Muslim 1218", arabic: 922...935, english: 1567...1607)
                        ScriptureQuote(hadith: "muslim:681", cite: "Saheeh Muslim 681", arabic: 302...322, english: 416...442)
                        ArticleParagraph(articleMarkdown: "**Bilaal's Adhan or Abu Mahdhoorah's?** Both are Sunnah. The words above are Bilaal's. In Abu Mahdhoorah's, whom the Prophet taught in Makkah, the two testimonies are said in a low voice and then repeated aloud, the **tarjee‘** (Saheeh Muslim 379). A muadhin may call either.")
                        ScriptureQuote(hadith: "muslim:379", cite: "Saheeh Muslim 379", arabic: 46...113, english: 0...94)
                        ArticleParagraph(articleMarkdown: "**Can the Adhan be called in English?** No. Its words are fixed Arabic, the same in every land. Teach their meaning beside it, as this page does.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Its words proclaim the greatness and oneness of Allah and the messengership of Muhammad, calling the believers to prayer and to success. Call it in its time, in its own words, aloud and unbroken; on Friday, as the imam sits on the minbar.")
                }

                ArticleSourcesSection(article: "AdhanOtherView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "AdhanOtherView")
        .navigationTitle(AppLanguage.article("Adhan"))
    }
}

struct IqamahView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Iqaamah is the second, shorter call, given when the imam is ready and the prayer is about to begin. Like the Adhan, it counts only after the time has entered, in its Arabic words and order, without a break; it is joined to the prayer that follows it.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "The Iqaamah (إِقَامَة), from the root **q-w-m (ق و م)**, to stand or establish, is the second call to prayer, given right before the congregational Salaah begins.")

                    ArticleParagraph(verbatim: "It is generally shorter than the Adhan and serves as a prompt for the congregation to stand and line up for prayer.")

                    ArticleParagraph(articleMarkdown: "Often, the same **Mu’adhin (مُؤَذِّن)** (caller) who delivered the Adhan will also deliver the Iqaamah, but it can be done by someone else.")
                }

                Section(header: ArticleHeader("WORDS OF THE IQAAMAH")) {
                    ArticleArabic(verbatim: """
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ

                    أَشهَدُ أَن لَا إِلَٰهَ إِلَّا اللَّهُ

                    أَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ

                    حَيَّ عَلَى الصَّلَاةِ، حَيَّ عَلَى الفَلَاحِ

                    قَد قَامَتِ الصَّلَاةُ
                    قَد قَامَتِ الصَّلَاةُ

                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ

                    لَا إِلَٰهَ إِلَّا اللَّهُ
                    """)

                    Text(verbatim: """
                    Allahu Akbar, Allahu Akbar

                    Ashhadu an la ilaaha illallah

                    Ashhadu anna Muhammadan rasool Allah

                    Hayya 'ala as-salaah, Hayya 'ala al-falaah

                    Qad qaamatis-Salaah
                    Qad qaamatis-Salaah

                    Allahu Akbar, Allahu Akbar

                    La ilaaha illallah
                    """)
                    .font(.body)

                    Text(verbatim: """
                    Allah is the greatest, Allah is the greatest

                    I bear witness that there is no deity but Allah

                    I bear witness that Muhammad is the Messenger of Allah

                    Come to prayer, Come to success

                    Prayer has begun
                    Prayer has begun

                    Allah is the greatest, Allah is the greatest

                    There is no deity but Allah
                    """)
                    .font(.body)

                    ArticleCallout("The noon of “an” melts into the laam after it (idghaam), so “an la ilaaha” is said “allaa ilaaha”, and “illa Allah” runs together as “illallah”: Ashhadu allaa ilaaha illallah. “Rasool Allah” joins the same way, rasoolullah, and so does the closing line, La ilaaha illallah.", title: "How it is said", systemImage: "waveform")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHAT MAKES IT VALID")) {
                        ArticleParagraph(verbatim: "The Iqaamah keeps the Adhan's conditions and adds one of its own:")
                        ArticleStep("1. **The time has entered**, with no exception this time: even the Iqaamah of Fajr comes after true dawn.")
                        ArticleStep("2. **Its Arabic words, in their order**, said without a break by one person.")
                        ArticleStep("3. **A Muslim of sound mind gives it.** For men a man gives it; women praying together may give their own, quietly.")
                        ArticleStep("4. **It is joined to the prayer.** It announces that the prayer is starting now, so the prayer follows it.")
                    }

                    Section(header: ArticleHeader("WHEN IT IS GIVEN")) {
                        ArticleParagraph(verbatim: "The scholars put it this way: the muadhin decides the time of the Adhan, and the imam decides the time of the Iqaamah. Bilaal called the Adhan as soon as the time came in, then waited for the Prophet:")
                        ScriptureQuote(hadith: "muslim:606", cite: "Saheeh Muslim 606", arabic: 19...38, english: 0...28)
                        ArticleParagraph(verbatim: "So the Iqaamah is given when the imam is present and ready, or at the time the mosque has fixed with his consent.")
                    }

                    Section(header: ArticleHeader("AFTER THE IQAAMAH")) {
                        ArticleParagraph(verbatim: "Once the Iqaamah is called, no other prayer is begun. The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:710a", cite: "Saheeh Muslim 710", arabic: 32...38, english: 0...13)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHAT MAKES IT VALID")) {
                        ArticleParagraph(verbatim: "The Iqaamah keeps the Adhan's conditions and adds one of its own:")
                        ArticleStep("1. **The time has entered**, with no exception this time: even the Iqaamah of Fajr comes after true dawn.")
                        ArticleStep("2. **Its Arabic words, in their order**, said without a break by one person.")
                        ArticleStep("3. **A Muslim of sound mind gives it.** For men a man gives it; women praying together may give their own, quietly.")
                        ArticleStep("4. **It is joined to the prayer.** It announces that the prayer is starting now, so the prayer follows it. A short delay does not undo it:")
                        ScriptureQuote(hadith: "bukhari:642", cite: "Saheeh al-Bukhaari 642", arabic: 20...38, english: 0...42)
                        ArticleParagraph(verbatim: "If a long time passes, or the people leave and come back, the scholars said it is given again before the prayer.")
                        ArticleParagraph(verbatim: "Its ruling is that of the Adhan: a collective obligation on the men of a town in the Hanbali school and the fatwas of Ibn Baaz and Ibn al-Uthaymeen, and a confirmed Sunnah for someone praying alone. A prayer prayed without it is still valid.")
                    }

                    Section(header: ArticleHeader("WHEN IT IS GIVEN")) {
                        ArticleParagraph(verbatim: "The scholars put it this way: the muadhin decides the time of the Adhan, and the imam decides the time of the Iqaamah. Bilaal called the Adhan as soon as the time came in, then waited for the Prophet:")
                        ScriptureQuote(hadith: "muslim:606", cite: "Saheeh Muslim 606", arabic: 19...38, english: 0...28)
                        ArticleParagraph(verbatim: "So the Iqaamah is given when the imam is present and ready, or at the time the mosque has fixed with his consent. The time between the two calls is for a voluntary prayer and for dua, which is not turned back then (Sunan Abi Daawood 521; graded saheeh by al-Albaani):")
                        ScriptureQuote(hadith: "bukhari:624", cite: "Saheeh al-Bukhaari 624", arabic: 27...35, english: 5...24)
                        ScriptureQuote(hadith: "abudawud:521", cite: "Sunan Abi Daawood 521; graded saheeh by al-Albaani", arabic: 26...31, english: 0...11)
                        ArticleParagraph(verbatim: "When the imam is coming from elsewhere, the congregation waits to see him before standing:")
                        ScriptureQuote(hadith: "bukhari:637", cite: "Saheeh al-Bukhaari 637", arabic: 29...35, english: 7...26)
                        ArticleParagraph(articleMarkdown: "On **Friday** there is no waiting: the imam finishes the second khutbah and comes down from the minbar, and the Iqaamah is given at once.")
                    }

                    Section(header: ArticleHeader("AFTER THE IQAAMAH")) {
                        ArticleParagraph(verbatim: "The Iqaamah is said in single phrases, unlike the Adhan, which is said in pairs. Anas (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "bukhari:605", cite: "Saheeh al-Bukhaari 605, Saheeh Muslim 378", arabic: 21...30, english: 0...22)
                        ArticleParagraph(verbatim: "Once the Iqaamah is called, no other prayer is begun. The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:710a", cite: "Saheeh Muslim 710", arabic: 32...38, english: 0...13)
                        ArticleParagraph(verbatim: "And straighten the rows before the imam begins:")
                        ScriptureQuote(hadith: "bukhari:723", cite: "Saheeh al-Bukhaari 723, Saheeh Muslim 433", arabic: 19...26, english: 4...19)
                        ArticleParagraph(verbatim: "Walk to the prayer calmly. He said:")
                        ScriptureQuote(hadith: "bukhari:636", cite: "Saheeh al-Bukhaari 636, Saheeh Muslim 602", arabic: 40...56, english: 4...36)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is the Iqaamah said once or twice?** The words above are Bilaal's: each phrase once, with “Qad qaamatis-salaah” twice. The Prophet taught Abu Mahdhoorah an Iqaamah with its phrases doubled (Sunan Abi Daawood 502; graded hasan saheeh by al-Albaani). Both are Sunnah.")
                        ScriptureQuote(hadith: "abudawud:502", cite: "Sunan Abi Daawood 502; graded hasan saheeh by al-Albaani", arabic: 121...177, english: 23...114)
                        ArticleParagraph(articleMarkdown: "**Must the one who called the Adhan give the Iqaamah?** No, anyone suitable may give it. The narration “whoever calls the Adhan gives the Iqaamah” is weak (Jaami‘ at-Tirmidhi 199), though most scholars still prefer that the muadhin give it when he is there.")
                        ArticleParagraph(articleMarkdown: "**Do I answer the Iqaamah?** Many scholars said to repeat its words as you do the Adhan's, since it is a call too. Saying “Aqaamaha Allahu wa adaamaha” at “Qad qaamatis-salaah” comes in a weak narration (Sunan Abi Daawood 528), so it is not relied on.")
                        ArticleParagraph(articleMarkdown: "**I pray alone. Do I give the Iqaamah?** Yes, it is Sunnah, even when you heard the mosque's Adhan and did not call your own.")
                        ArticleParagraph(articleMarkdown: "**The Iqaamah was called while I was praying a sunnah.** Ibn al-Uthaymeen's guidance: if you are in the second rak‘ah, finish it lightly; if you are still in the first, break it off and join the imam. A new voluntary prayer is never started after the Iqaamah.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Where the Adhan calls the community to gather, the Iqaamah announces that the prayer has been established and the rows are to be formed. It comes after the time, at the imam's word, and the prayer follows it.")
                }

                ArticleSourcesSection(article: "IqamahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "IqamahView")
        .navigationTitle("Iqaamah")
    }
}

struct TakbiratView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Eid prayer is two rak‘ah with extra takbeers, prayed in congregation after sunrise with no Adhan and no Iqaamah, followed by the khutbah.")
                }

                Section(header: ArticleHeader("BEFORE YOU GO")) {
                    ArticleStep("1. Perform **ghusl (غُسل)**, wear your best clothes, and apply perfume (for men).")
                    ArticleStep("2. For **Eid al-Fitr**, eat an odd number of dates before leaving. For **Eid al-Adha**, do not eat until after the prayer, so that the first thing you eat is from the sacrifice.")
                    ArticleStep("3. Pay **Zakaat al-Fitr** before the prayer (Eid al-Fitr only). If it is paid after the prayer, it counts as ordinary charity, not as Zakaat al-Fitr.")
                    ArticleStep(verbatim: "4. Say the Takbeer on the way, out loud (see below).")
                    ArticleStep("5. Go out to the **musalla (مُصَلَّى)**, the open prayer ground, which is the Sunnah, and take the women and children with you. Go by one route and return by another. Jaabir (may Allah be pleased with him) said:")
                    ScriptureQuote(hadith: "bukhari:986", cite: "Saheeh al-Bukhaari 986", arabic: 20...31, english: 0...25)
                }

                Section(header: ArticleHeader("THE TIME OF THE PRAYER")) {
                    ArticleParagraph(verbatim: "The Eid prayer begins after the sun has fully risen, roughly 15 to 20 minutes after sunrise, and its time lasts until just before the sun reaches its zenith (before Dhuhr).")
                    ArticleParagraph(articleMarkdown: "**Eid al-Adha** is prayed early, so people can go and sacrifice. **Eid al-Fitr** is prayed a little later, so people have time to give Zakaat al-Fitr.")
                }

                Section(header: ArticleHeader("HOW TO PRAY EID")) {
                    ArticleParagraph(articleMarkdown: "There is **no Adhan and no Iqaamah** for the Eid prayer, and no call of any kind. It is simply begun.")

                    ArticleParagraph(articleMarkdown: "It is **two rak‘ah**, prayed in congregation behind the imam, and the recitation is out loud.")

                    ArticleParagraph(articleMarkdown: "**First rak‘ah:**")
                    ArticleStep("1. Make the intention in the heart, then the opening takbeer, **Takbeerat al-Ihraam (تَكبِيرَة الإِحرَام)**, raising the hands.")
                    ArticleStep("2. Say the opening supplication (**dua al-istiftaah**).")
                    ArticleStep("3. Say **seven takbeers** in total in this rak‘ah before the recitation, raising the hands with each. (Scholars differ over whether the opening takbeer is counted as one of the seven; both are practised and the prayer is valid either way. Do not argue over it.)")
                    ArticleStep("4. Then say the ta‘awwudh and recite **al-Faatihah**, followed by a surah. From the Sunnah: **Surah al-A‘la (87)** in the first rak‘ah and **al-Ghaashiyah (88)** in the second, or **Qaaf (50)** and **al-Qamar (54)**.")
                    ArticleStep(verbatim: "5. Then complete the rak‘ah as normal: rukoo', standing, and two prostrations.")

                    ArticleParagraph(articleMarkdown: "**Second rak‘ah:**")
                    ArticleStep("6. Stand, and before reciting, say **five takbeers**, raising the hands with each. These are apart from the takbeer you said when standing up from prostration.")
                    ArticleStep(verbatim: "7. Recite al-Faatihah and a surah, then complete the rak‘ah, sit for the tashahhud, and give the salaam.")

                    ArticleParagraph(articleMarkdown: "There is **no nafl prayer** before or after the Eid prayer at the musalla.")

                    ArticleParagraph(verbatim: "Aa’ishah (may Allah be pleased with her) said:")
                    ScriptureQuote(hadith: "abudawud:1149", cite: "Sunan Abi Daawood 1149-1150; graded saheeh by al-Albaani", english: 0...51, arabicText: "كَانَ يُكَبِّرُ فِي الفِطرِ وَالأَضحَى فِي الأُولَى سَبعَ تَكبِيرَاتٍ وَفِي الثَّانِيَةِ خَمسًا سِوَى تَكبِيرَتَىِ الرُّكُوعِ")

                    ArticleParagraph(verbatim: "If you miss a takbeer, or the imam has already begun, join him where he is and do not try to make up the extra takbeers. They are a Sunnah, not a pillar, and forgetting them does not invalidate the prayer or require the prostration of forgetfulness.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("AFTER THE PRAYER: THE KHUTBAH")) {
                        ArticleParagraph(articleMarkdown: "The khutbah comes **after** the Eid prayer, unlike Jumuah, where it comes before.")
                        ArticleParagraph(verbatim: "Staying for it is strongly recommended, though it is not obligatory, and one who leaves has not sinned.")
                        ArticleParagraph(verbatim: "If you missed the congregation entirely, you may pray two rak‘ah on your own.")
                    }

                    Section(header: ArticleHeader("TAKBEERAT AL-EID")) {
                        ArticleParagraph(verbatim: "The Takbeerat al-Eid is a special proclamation of Allah’s greatness, recited during the days of Eid.")

                        ArticleParagraph(verbatim: "For Eid al-Fitr, it begins after the new moon confirming the end of Ramadan and continues until the Eid prayer. For Eid al-Adha, the unrestricted takbeer runs from the start of Dhu al-Hijjah until sunset on the 13th, and the takbeer after the prayers runs from Fajr of Arafah Day (the 9th) for those not on Hajj until Asr of the 13th.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("AFTER THE PRAYER: THE KHUTBAH")) {
                        ArticleParagraph(articleMarkdown: "The khutbah comes **after** the Eid prayer, unlike Jumuah, where it comes before.")
                        ArticleParagraph(verbatim: "Staying for it is strongly recommended, though it is not obligatory, and one who leaves has not sinned.")
                        ArticleParagraph(verbatim: "If you missed the congregation entirely, you may pray two rak‘ah on your own.")
                        ArticleParagraph(verbatim: "Greet one another as the Companions did. Jubayr ibn Nufayr said: when the Companions of the Messenger of Allah (peace and blessings be upon him) met on the day of Eid, they would say to one another:")
                        ScriptureQuote(text: "“Taqabbal Allahu minna wa minka: May Allah accept it from us and from you” (reported by al-Mahaamili; Ibn Hajar said its chain is hasan, Fath al-Baari 2/446).", arabic: "تَقَبَّلَ اللَّهُ مِنَّا وَمِنكَ", dimmed: true)
                    }

                    Section(header: ArticleHeader("EID OCCASIONS")) {
                        ArticleParagraph(verbatim: "In Islam, there are two major annual celebrations known as Eid:")

                        ArticleStep("1. **Eid al-Fitr (عِيد الفِطر):** Celebrated at the end of Ramadan (the month of fasting). It is a time of joy, gratitude to Allah (Glorified and Exalted be He), and giving to the needy (Zakaat al-Fitr).")

                        ArticleStep("2. **Eid al-Adha (عِيد الأَضحَى):** Celebrated on the 10th day of Dhu al-Hijjah. It commemorates the willingness of Prophet Ibraaheem (peace be upon him) to sacrifice his son Ismaa‘eel (peace be upon him). Muslims who are able to do so perform the sacrifice (Qurbani) and distribute the meat to the poor. This Eid coincides with Hajj, the annual pilgrimage to Makkah.")
                    }

                    Section(header: ArticleHeader("TAKBEERAT AL-EID")) {
                        ArticleParagraph(verbatim: "The Takbeerat al-Eid is a special proclamation of Allah’s greatness, recited during the days of Eid.")

                        ArticleParagraph(verbatim: "For Eid al-Fitr, it begins after the new moon confirming the end of Ramadan and continues until the Eid prayer. For Eid al-Adha, the unrestricted takbeer runs from the start of Dhu al-Hijjah until sunset on the 13th. Ibn Abbaas explained that the “known days” of Quran 22:28 are the ten days and the “numbered days” of Quran 2:203 are the days of Tashreeq, and Ibn Umar and Abu Hurayrah would go out to the market in the ten days saying the takbeer, and the people said it with them (Saheeh al-Bukhaari, the chapter on the virtue of deeds in the days of Tashreeq). The takbeer after the prayers runs from Fajr of Arafah Day (the 9th) for those not on Hajj until Asr of the 13th; Ibn Hajar names the report of Ali and Ibn Mas‘ood as the soundest from the Companions on it (Fath al-Baari 2/462).")
                        ScriptureQuote(quran: "22:28", words: 3...8)
                        ScriptureQuote(quran: "2:203", words: 1...5)

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                        ScriptureQuote(quran: "2:185", words: 35...43)
                    }
                }

                Section(header: ArticleHeader("SHORT TAKBEERAT")) {
                    ArticleParagraph(verbatim: "This is the short version of the Takbeer:")

                    ArticleArabic(verbatim: "اللَّهُ أَكبَرُ اللَّهُ أَكبَرُ لَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكبَرُ اللَّهُ أَكبَرُ وَلِلَّهِ الحَمدُ")

                    ArticleParagraph(verbatim: "Allahu Akbar, Allahu Akbar, La Ilaaha Illa Allah, Allahu Akbar, Allahu Akbar, wa lillahil hamd")

                    ArticleParagraph(verbatim: "Allah is the Greatest, Allah is the Greatest. There is no deity but Allah. Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE TAKBEER OF THE COMPANIONS")) {
                        ArticleParagraph(verbatim: "No fixed wording of the Eid takbeer is narrated from the Prophet (peace and blessings be upon him) himself; what is established is the practice of his Companions, and their wording is what Ahl as-Sunnah keep to. Ibn Mas‘ood (may Allah be pleased with him) would say:")
                        ScriptureQuote(text: "“Allahu Akbar, Allahu Akbar, la ilaaha illallah, wallahu Akbar, Allahu Akbar, wa lillahil-hamd: Allah is the Greatest, Allah is the Greatest, there is no deity but Allah; and Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise” (Musannaf Ibn Abi Shaybah; graded saheeh by al-Albaani, Irwaa' al-Ghaleel 3/125).", arabic: "اللَّهُ أَكبَرُ اللَّهُ أَكبَرُ، لَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكبَرُ اللَّهُ أَكبَرُ وَلِلَّهِ الحَمدُ", dimmed: true)

                        ArticleParagraph(verbatim: "And from Ibn Abbaas (may Allah be pleased with him):")
                        ScriptureQuote(text: "“Allahu Akbar kabeera, Allahu Akbar kabeera, Allahu Akbar wa ajall, Allahu Akbar wa lillahil-hamd: Allah is the Greatest, truly great; Allah is the Greatest, truly great; Allah is the Greatest and most Majestic; Allah is the Greatest, and to Allah belongs all praise” (Ibn Abi Shaybah 2/168 and al-Mahaamili; graded saheeh by al-Albaani, Irwaa' al-Ghaleel 3/126).", arabic: "اللَّهُ أَكبَرُ كَبِيرًا، اللَّهُ أَكبَرُ كَبِيرًا، اللَّهُ أَكبَرُ وَأَجَلُّ، اللَّهُ أَكبَرُ وَلِلَّهِ الحَمدُ", dimmed: true)

                        ArticleParagraph(verbatim: "Saying it three times (Allahu Akbar, Allahu Akbar, Allahu Akbar) is also reported from the Salaf, and both are fine. Men raise their voices with it in the markets, the mosques and on the way to the prayer ground, as Ibn Umar and Abu Hurayrah used to (Saheeh al-Bukhaari, Book of the Two Eids, chapter heading).")
                    }

                    Section(header: ArticleHeader("OTHER WORDS OF REMEMBRANCE FROM THE SUNNAH")) {
                        ArticleParagraph(verbatim: "Longer chants heard on Eid morning gather phrases that are themselves authentic remembrances, and these may be said. A Companion said this in the prayer, and the Prophet (peace and blessings be upon him) said of it: “I marvelled at it; the gates of heaven were opened for it” (Saheeh Muslim 601):")
                        ScriptureQuote(hadith: "muslim:601", cite: "Saheeh Muslim 601", arabic: 42...51, english: 15...34)

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) would say on returning from Hajj, Umrah or a campaign:")
                        ScriptureQuote(hadith: "bukhari:1797", cite: "Saheeh al-Bukhaari 1797", arabic: 47...77, english: 27...90)

                        ArticleParagraph(verbatim: "And after every obligatory prayer he would say:")
                        ScriptureQuote(hadith: "muslim:594a", cite: "Saheeh Muslim 594", arabic: 27...74, english: 14...98)

                        ArticleParagraph(verbatim: "What has no basis is the composed formula that adds blessings on “our master Muhammad, his companions, his supporters, his wives and his offspring” inside the takbeer itself: it is not narrated from the Prophet (peace and blessings be upon him) or from any of his Companions. Sending blessings on him is beloved at all times (Quran 33:56), but the takbeer of Eid is kept to the transmitted wording.")
                        ScriptureQuote(quran: "33:56")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("By glorifying Allah on the days of Eid, Muslims complete their worship with gratitude: after Ramadan for Eid al-Fitr, and around the days of Hajj for Eid al-Adha.")
                }

                ArticleSourcesSection(article: "TakbiratView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("How to Pray Eid")
        .englishArticle().selectableArticleList(article: "TakbiratView")
    }
}

struct HijriCalendarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Hijri calendar is the Islamic lunar calendar of twelve months, dated from the Prophet's migration (Hijrah) to Madinah in 622 CE.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "The Hijri calendar, also known as the Islamic or Lunar Hijri calendar, consists of 12 lunar months in a year of 354 or 355 days.")

                    ArticleParagraph(verbatim: "It is used to determine key Islamic dates such as Ramadan, Hajj, and the two Eid festivals. The reference point (epoch) of the calendar is the Hijrah, the migration of Prophet Muhammad (peace and blessings be upon him) from Makkah to Madinah in 622 CE.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                    ScriptureQuote(quran: "9:36", words: 0...17)
                }

                Section(header: ArticleHeader("DETAILS")) {
                    Text(articleMarkdown: """
                         Each Hijri month begins with the sighting of the new moon. The 12 months are as follows:
                         1. **Muharram (مُحَرَّم)**: One of the sacred months
                         2. **Safar (صَفَر)** 
                         3. **Rabi al-Awwal (رَبِيع ٱلأَوَّل)**
                         4. **Rabi ath-Thaani (رَبِيع ٱلثَّانِي)** 
                         5. **Jumaada al-Oola (جُمَادَىٰ ٱلأُولَىٰ)** 
                         6. **Jumaada al-Aakhirah (جُمَادَىٰ ٱلآخِرَة)** 
                         7. **Rajab (رَجَب)**: A sacred month
                         8. **Sha‘baan (شَعبَان)**: The month preceding Ramadan
                         9. **Ramadan (رَمَضَان)**: The month of fasting
                         10. **Shawwaal (شَوَّال)**: The month following Ramadan
                         11. **Dhul-Qadah (ذُو ٱلقَعدَة)**: A sacred month
                         12. **Dhul-Hijjah (ذُو ٱلحِجَّة)**: A sacred month, the month of Hajj and Eid al-Adha
                         """)
                    .font(.body)

                    ArticleParagraph(verbatim: "A Hijri year is approximately 11 days shorter than a Gregorian year, causing Islamic events to shift earlier each Gregorian year. Muslims worldwide use this calendar for religious observances, including fasting in Ramadan, undertaking Hajj, and celebrating Eid al-Fitr and Eid al-Adha.")
                }

                Section(header: ArticleHeader("SACRED MONTHS")) {
                    ArticleParagraph(articleMarkdown: "Four of the Hijri months are considered sacred: **Muharram**, **Rajab**, **Dhul-Qadah**, and **Dhul-Hijjah**.")

                    ArticleParagraph(verbatim: "These months are distinguished by their sanctity and prohibition of warfare, emphasizing peace and reflection.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                    ScriptureQuote(quran: "9:36")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("About eleven days shorter than the solar year, it sets the timing of Ramadan, Hajj, and the two Eids, and marks the four sacred months.")
                }

                ArticleSourcesSection(article: "HijriCalendarView")
            }
            .themedListRowBackground()
        }
        .navigationTitle(AppLanguage.article("Hijri Calendar"))
        #if os(iOS)
        .openScreen(.hijriArticle)
        #endif
        .englishArticle().selectableArticleList(article: "HijriCalendarView")
    }
}

struct SacredMonthsView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: four of the twelve Hijri months are sacred (Dhul-Qadah, Dhul-Hijjah, Muharram, and Rajab), and Allah singled them out for honour, forbade fighting in them, and warned against wronging oneself in them.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "The Hijri year is twelve lunar months, and Allah set four of them apart from the day He created the heavens and the earth. They are not sacred because the Arabs treated them so; the Arabs inherited their sanctity from the religion of Ibraaheem (peace be upon him) and then tampered with it, and Islam restored them to their places.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                    ScriptureQuote(quran: "9:36", words: 0...24)
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHICH FOUR THEY ARE")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) named them in his sermon at the Farewell Pilgrimage: three that run together at the turn of the year, and one on its own in the middle.")

                        ScriptureQuote(hadith: "bukhari:3197", cite: "Saheeh al-Bukhaari 3197", arabic: 34...61, english: 4...63)
                    }

                    Section(header: ArticleHeader("WHAT THEIR SANCTITY MEANS")) {
                        ArticleParagraph(verbatim: "Two things are established. Fighting was forbidden in them so that pilgrims and traders could travel to Makkah and home again in safety: Dhul-Qadah to travel out, Dhul-Hijjah for the Hajj, Muharram to travel home, and Rajab in the middle of the year for those who came for Umrah (Tafseer Ibn Katheer, on Quran 9:36). And sin in them is graver than sin outside them.")
                    }

                    Section(header: ArticleHeader("MUHARRAM AND THE DAY OF AASHOORA")) {
                        ArticleParagraph(verbatim: "Within Muharram is Aashoora, the tenth of the month, the day Allah saved Moosa and the Children of Israel from their enemy. Prophet Muhammad (peace and blessings be upon him) fasted it and told the Muslims to fast it, and he named its reward:")

                        ScriptureQuote(hadith: "muslim:1162a", cite: "Saheeh Muslim 1162", arabic: 190...200, english: 247...267)

                        ArticleParagraph(verbatim: "What is not from the Sunnah is anything else built onto this day: no mourning, no celebration, no special dish, no gathering. The day is a fast, and that is all that was given.")
                    }

                    Section(header: ArticleHeader("DHUL-HIJJAH AND ITS FIRST TEN DAYS")) {
                        ArticleParagraph(verbatim: "Dhul-Hijjah opens with the ten days about which Prophet Muhammad (peace and blessings be upon him) said:")

                        ScriptureQuote(hadith: "bukhari:969", cite: "Saheeh al-Bukhaari 969", arabic: 28...37, english: 4...23)

                        ArticleParagraph(verbatim: "The ninth is the Day of Arafah, whose fast the Prophet (peace and blessings be upon him) said he hoped would atone for the year before it and the year after it (Saheeh Muslim 1162), for anyone not standing at Arafah.")
                    }

                    Section(header: ArticleHeader("WHAT IS NOT ESTABLISHED IN RAJAB")) {
                        ArticleParagraph(verbatim: "Rajab is a sacred month, and nothing beyond that is authentically reported about it. Ibn Hajar al-Asqalaani (may Allah have mercy on him) wrote a treatise on exactly this question, Tabyeen al-Ajab bima Warada fi Fadl Rajab, and concluded that no sound hadith fit to use as evidence exists on the virtue of Rajab, on fasting it specifically, or on praying a particular prayer in it.")

                        ArticleParagraph(verbatim: "That does not diminish the month. The honour Allah gave it is the honour it has, and adding to it is not devotion but innovation.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHICH FOUR THEY ARE")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) named them in his sermon at the Farewell Pilgrimage: three that run together at the turn of the year, and one on its own in the middle.")

                        ScriptureQuote(hadith: "bukhari:3197", cite: "Saheeh al-Bukhaari 3197", arabic: 34...61, english: 4...63)

                        Text(articleMarkdown: """
                             The four, in the order of the Hijri year:
                             1. **Muharram (مُحَرَّم)**: the first month, and the only one Allah's Messenger (peace and blessings be upon him) called “the month of Allah”
                             2. **Rajab (رَجَب)**: the seventh, alone between Jumaada ath-Thaaniyah and Sha‘baan
                             3. **Dhul-Qadah (ذُو ٱلقَعدَة)**: the eleventh, named for the “sitting” that came with laying down weapons
                             4. **Dhul-Hijjah (ذُو ٱلحِجَّة)**: the twelfth, the month of Hajj
                             """)
                        .font(.body)

                        ArticleParagraph(verbatim: "“Rajab of Mudar” settles which Rajab is meant. The tribe of Mudar kept it in its true place while other tribes shifted it, so the Prophet (peace and blessings be upon him) fixed it to the month Mudar honoured: the one between Jumaada ath-Thaaniyah and Sha‘baan.")
                    }

                    Section(header: ArticleHeader("WHAT THEIR SANCTITY MEANS")) {
                        ArticleParagraph(verbatim: "Two things are established. Fighting was forbidden in them so that pilgrims and traders could travel to Makkah and home again in safety: Dhul-Qadah to travel out, Dhul-Hijjah for the Hajj, Muharram to travel home, and Rajab in the middle of the year for those who came for Umrah (Tafseer Ibn Katheer, on Quran 9:36). And sin in them is graver than sin outside them.")

                        ArticleParagraph(verbatim: "Ibn Katheer (may Allah have mercy on him) explains “so do not wrong yourselves during them” to mean: in these months especially, for a sin in a sacred time is heavier, just as a good deed in a sacred time is greater. Qataadah said that wrongdoing in them is a greater burden and a greater sin than wrongdoing in any other month, though wrongdoing is grave in every case (both in Tafseer Ibn Katheer, on Quran 9:36).")

                        ArticleParagraph(verbatim: "This is a warning against sin, not a licence to invent worship. No prayer, no fast, and no gathering is prescribed for a month merely because it is sacred; what is prescribed in them is what the Quran and the Sunnah actually name, and that is set out below.")
                    }

                    Section(header: ArticleHeader("AN-NASI: MOVING THE MONTHS")) {
                        ArticleParagraph(verbatim: "Before Islam the Arabs would postpone a sacred month when it did not suit a war they wanted to fight, declaring Muharram ordinary that year and making Safar sacred instead, so that the count of four was kept while the months themselves were moved. Allah called this an increase in disbelief.")

                        ScriptureQuote(quran: "9:37", words: 0...21)

                        ArticleParagraph(verbatim: "This is why the Prophet (peace and blessings be upon him) opened his Farewell Sermon by saying that time had come back round to its original state as it was on the day Allah created the heavens and the earth: the months were back in their true places, and they have stayed there since.")
                    }

                    Section(header: ArticleHeader("MUHARRAM AND THE DAY OF AASHOORA")) {
                        ArticleParagraph(verbatim: "Muharram carries the one virtue the Sunnah states outright for a sacred month as a whole. Asked which fast is best after the month of Ramadan, Prophet Muhammad (peace and blessings be upon him) answered:")

                        ScriptureQuote(hadith: "ibnmajah:1742", cite: "Sunan Ibn Maajah 1742; graded saheeh by al-Albaani, and the same report is in Saheeh Muslim 1163", arabic: 51...55, english: 20...27)

                        ArticleParagraph(verbatim: "Within it is Aashoora, the tenth of Muharram. When Prophet Muhammad (peace and blessings be upon him) came to Madinah he found the Jews fasting it, because it was the day Allah saved Moosa and the Children of Israel from their enemy, and he said:")

                        ScriptureQuote(hadith: "bukhari:2004", cite: "Saheeh al-Bukhaari 2004", arabic: 59...62, english: 48...55)

                        ArticleParagraph(verbatim: "He fasted it and told the Muslims to fast it, and he named its reward:")

                        ScriptureQuote(hadith: "muslim:1162a", cite: "Saheeh Muslim 1162", arabic: 190...200, english: 247...267)

                        ArticleParagraph(verbatim: "In the last year of his life he intended to add the ninth, to differ from the People of the Book:")

                        ScriptureQuote(hadith: "ibnmajah:1736", cite: "Sunan Ibn Maajah 1736; graded saheeh by al-Albaani, and the same report is in Saheeh Muslim 1134", arabic: 37...43, english: 0...14)

                        ArticleParagraph(verbatim: "He died before that year came, so the scholars hold it recommended to fast the ninth with the tenth. What is not from the Sunnah is anything else built onto this day: no mourning, no celebration, no special dish, no gathering. The day is a fast, and that is all that was given.")
                    }

                    Section(header: ArticleHeader("DHUL-HIJJAH AND ITS FIRST TEN DAYS")) {
                        ArticleParagraph(verbatim: "Dhul-Hijjah opens with the ten days about which Prophet Muhammad (peace and blessings be upon him) said:")

                        ScriptureQuote(hadith: "bukhari:969", cite: "Saheeh al-Bukhaari 969", arabic: 28...37, english: 4...23)

                        ArticleParagraph(verbatim: "The ninth is the Day of Arafah, whose fast the Prophet (peace and blessings be upon him) said he hoped would atone for the year before it and the year after it (Saheeh Muslim 1162), for anyone not standing at Arafah. The tenth is the Day of Sacrifice, Eid al-Adha, and it is not fasted. Hajj itself falls in this month, which is why Dhul-Qadah before it and Muharram after it are sacred alongside it.")
                    }

                    Section(header: ArticleHeader("WHAT IS NOT ESTABLISHED IN RAJAB")) {
                        ArticleParagraph(verbatim: "Rajab is a sacred month, and nothing beyond that is authentically reported about it. Ibn Hajar al-Asqalaani (may Allah have mercy on him) wrote a treatise on exactly this question, Tabyeen al-Ajab bima Warada fi Fadl Rajab, and concluded that no sound hadith fit to use as evidence exists on the virtue of Rajab, on fasting it specifically, or on praying a particular prayer in it.")

                        Text(articleMarkdown: """
                             So the following have no authentic basis and are not from the Sunnah:
                             - **Salaat ar-Raghaa’ib** on the first Friday night of Rajab, which scholars including an-Nawawi and Ibn as-Salaah declared a rejected innovation
                             - Fasting Rajab in full, or singling out its days for fasting because it is Rajab
                             - The **Umrah of Rajab** as a special act; Aa’ishah (may Allah be pleased with her) denied that the Prophet (peace and blessings be upon him) ever performed Umrah in Rajab
                             - Celebrating the twenty-seventh night as the night of al-Isra wal-Mi‘raaj; the date itself is not established, and no worship was legislated for it
                             - The **Ateerah**, a sacrifice offered in Rajab in the days of ignorance, which Islam abolished
                             """)
                        .font(.body)

                        ArticleParagraph(verbatim: "None of this diminishes the month. It means the honour Allah gave it is the honour it has, and adding to it is not devotion but innovation. Whoever fasts Mondays and Thursdays, or the three white days, and those days fall in Rajab, is doing what the Sunnah already asks, and there is nothing wrong with that.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Four months of the twelve are sacred by Allah's decree: Dhul-Qadah, Dhul-Hijjah, Muharram, and Rajab. Fighting in them was forbidden, sin in them is heavier, and moving them, as the Arabs once did, was called an increase in disbelief. What is legislated in them is what the texts name: the fast of Aashoora in Muharram, and the ten days, Arafah, and Hajj in Dhul-Hijjah. What is not named, above all in Rajab, is left alone.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleParagraph(articleMarkdown: "**Al-Ashhur al-Hurum (ٱلأَشهُر ٱلحُرُم)**: “the sacred months,” the four Allah set apart in Quran 9:36. Hurum is the plural of haram, meaning inviolable: the same root as the Haram of Makkah and as ihraam, the sacred state of a pilgrim.")

                        ArticleParagraph(articleMarkdown: "**An-Nasi (ٱلنَّسِيء)**: “postponement,” the pre-Islamic practice of shifting a sacred month to a different month so that a war could be fought on time, condemned in Quran 9:37.")

                        ArticleParagraph(articleMarkdown: "**Aashoora (عَاشُورَاء)**: the tenth of Muharram, from ashr, ten. The day Allah saved Moosa (peace be upon him) and his people; its fast expiates the year before it.")

                        ArticleParagraph(articleMarkdown: "**Ateerah (عَتِيرَة)**: a sheep the Arabs slaughtered in Rajab for their idols or their customs. Islam abolished it.")

                        ArticleParagraph(articleMarkdown: "**Rajab of Mudar**: the Rajab kept in its true place by the tribe of Mudar, named by the Prophet (peace and blessings be upon him) so that no one could mistake which month was meant.")
                    }
                }

                ArticleSourcesSection(article: "SacredMonthsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Sacred Months")
        .englishArticle().selectableArticleList(article: "SacredMonthsView")
    }
}

struct MoonSightingView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: a Hijri month begins when the new crescent is sighted, and if it cannot be seen the month before is completed as thirty days. Sighting, not calculation, is what the Sunnah made the sign.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(verbatim: "A lunar month is the moon's full circuit, a little over twenty-nine and a half days, so a Hijri month is always either twenty-nine or thirty days and never a fixed number. Allah made the moon itself the clock:")

                        ScriptureQuote(quran: "10:5", words: 0...12)
                    }

                    Section(header: ArticleHeader("THE RULE")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) gave the whole rule in one sentence, and it is the rule for every Hijri month, not for Ramadan alone:")

                        ScriptureQuote(hadith: "bukhari:1909", cite: "Saheeh al-Bukhaari 1909", arabic: 35...45, english: 6...39)

                        ArticleParagraph(verbatim: "So there are two ways a month can begin and no third: the crescent is seen by a trustworthy witness, or the month in progress reaches thirty days and the next one starts by itself. Doubt never begins a month, which is why fasting the “day of doubt” before Ramadan is forbidden.")
                    }

                    Section(header: ArticleHeader("WHY SIGHTING AND NOT CALCULATION")) {
                        ArticleParagraph(verbatim: "Astronomers can compute the moon's conjunction to the second, and Muslim astronomers could do so early. The Sunnah still tied the month to the eye, and the Prophet (peace and blessings be upon him) said why:")

                        ScriptureQuote(hadith: "bukhari:1913", cite: "Saheeh al-Bukhaari 1913", arabic: 31...40, english: 4...31)

                        ArticleParagraph(verbatim: "Calculation may support a sighting, may show that a claimed sighting was impossible, and may tell an observer where to look, but it does not by itself begin or end a month.")
                    }

                    Section(header: ArticleHeader("ONE SIGHTING, OR EACH LAND ITS OWN?")) {
                        ArticleParagraph(verbatim: "The moon does not rise over the whole earth at once, so a crescent visible in one country may be below the horizon in another.")

                        Text(articleMarkdown: """
                             The scholars hold two positions on it:
                             - **Each region follows its own sighting** (ikhtilaaf al-mataali): the practice of Ibn Uthaymeen (may Allah have mercy on him)
                             - **One sighting binds all Muslims**: the view that “fast when you see it” addresses the whole ummah, held by Ibn Baaz and by the Permanent Committee
                             """)
                        .font(.body)

                        ArticleParagraph(verbatim: "Both are the ijtihaad of scholars on a question the texts leave open, and neither side declares the other astray. The practical guidance the scholars of both views give is the same: a Muslim fasts, breaks the fast and prays Eid with the Muslims of the land he is in.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(verbatim: "A lunar month is the moon's full circuit, a little over twenty-nine and a half days, so a Hijri month is always either twenty-nine or thirty days and never a fixed number. Allah made the moon itself the clock:")

                        ScriptureQuote(quran: "10:5", words: 0...12)

                        ArticleParagraph(verbatim: "And when the Companions asked about the crescents themselves, the answer named their purpose:")

                        ScriptureQuote(quran: "2:189", words: 1...8)
                    }

                    Section(header: ArticleHeader("THE RULE")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) gave the whole rule in one sentence, and it is the rule for every Hijri month, not for Ramadan alone:")

                        ScriptureQuote(hadith: "bukhari:1909", cite: "Saheeh al-Bukhaari 1909", arabic: 35...45, english: 6...39)

                        ArticleParagraph(verbatim: "The Quran ties the obligation to the same act of witnessing:")

                        ScriptureQuote(quran: "2:185", words: 12...16)

                        ArticleParagraph(verbatim: "So there are two ways a month can begin and no third: the crescent is seen by a trustworthy witness, or the month in progress reaches thirty days and the next one starts by itself. Doubt never begins a month, which is why fasting the “day of doubt” before Ramadan is forbidden.")
                    }

                    Section(header: ArticleHeader("WHY SIGHTING AND NOT CALCULATION")) {
                        ArticleParagraph(verbatim: "Astronomers can compute the moon's conjunction to the second, and Muslim astronomers could do so early. The Sunnah still tied the month to the eye, and the Prophet (peace and blessings be upon him) said why:")

                        ScriptureQuote(hadith: "bukhari:1913", cite: "Saheeh al-Bukhaari 1913", arabic: 31...40, english: 4...31)

                        ArticleParagraph(verbatim: "The point is not that arithmetic is blameworthy but that the sign Allah gave is one every believer can use, in every century and in every place, with no instrument and no expert. A conjunction is not the same thing as a visible crescent either: the moon can be astronomically new and still be invisible from the earth that evening.")

                        ArticleParagraph(verbatim: "This is the position of the great body of scholars, and of the Permanent Committee for Scholarly Research and Ifta and Ibn Baaz (may Allah have mercy on him) in our own time: calculation may support a sighting, may show that a claimed sighting was impossible, and may tell an observer where to look, but it does not by itself begin or end a month.")
                    }

                    Section(header: ArticleHeader("ONE SIGHTING, OR EACH LAND ITS OWN?")) {
                        ArticleParagraph(verbatim: "The moon does not rise over the whole earth at once, so a crescent visible in one country may be below the horizon in another. The Companions already faced this. Kurayb saw the crescent of Ramadan in Syria on a Friday night and told Ibn Abbaas (may Allah be pleased with them) in Madinah, who had seen it on Saturday night. Ibn Abbaas kept to the sighting of Madinah and said: this is how Allah's Messenger (peace and blessings be upon him) commanded us (Saheeh Muslim 1087).")
                        ScriptureQuote(hadith: "muslim:1087", cite: "Saheeh Muslim 1087", arabic: 77...125, english: 0...95)

                        Text(articleMarkdown: """
                             Two positions have stood since:
                             - **Each region follows its own sighting** (ikhtilaaf al-mataali): the view many scholars take from Ibn Abbaas's report, and the practice of Ibn Uthaymeen (may Allah have mercy on him)
                             - **One sighting binds all Muslims**: the view that “fast when you see it” addresses the whole ummah, held by Ibn Baaz and by the Permanent Committee
                             """)
                        .font(.body)

                        ArticleParagraph(verbatim: "Both are the ijtihaad of scholars on a question the texts leave open, and neither side declares the other astray. The practical guidance the scholars of both views give is the same: a Muslim fasts, breaks the fast and prays Eid with the Muslims of the land he is in. Unity in the matter is itself part of the worship, and the Prophet (peace and blessings be upon him) said: “The fast is the day the people fast, the breaking of the fast is the day the people break their fast, and the sacrifice is the day the people sacrifice” (Jaami‘ at-Tirmidhi 697; graded saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "tirmidhi:697", cite: "Jaami‘ at-Tirmidhi 697; graded saheeh by al-Albaani", arabic: 39...47, english: 3...32)
                    }

                    Section(header: ArticleHeader("WHAT DEPENDS ON IT")) {
                        ArticleParagraph(verbatim: "Almost every dated act of worship hangs on the crescent: the start and end of Ramadan and so the night of Laylat al-Qadr, Zakaat al-Fitr and the Eid prayer, the day of Arafah and the day of Sacrifice, the whole timing of Hajj, the day of Aashoora, and the hawl (the full lunar year) after which zakaah becomes due on wealth.")

                        ArticleParagraph(verbatim: "This is also why the Hijri date and the Gregorian date drift apart. A lunar year is about eleven days shorter than a solar one, so Ramadan moves back through the seasons and returns to the same season roughly once in every thirty-three years.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The month begins with the eye, not the calendar: the crescent is sighted, or thirty days are completed. Calculation serves the sighting and does not replace it. Whether one sighting binds the whole ummah or each land follows its own is a real difference among scholars, and in practice a Muslim keeps the fast and the Eid of the people among whom he lives.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleParagraph(articleMarkdown: "**Hilaal (هِلاَل)**: the new crescent, the thin arc visible shortly after sunset that begins a Hijri month. The plural, ahillah, is the word Quran 2:189 uses.")

                        ArticleParagraph(articleMarkdown: "**Ruyah (رُؤيَة)**: sighting with the eye. The phrase of the hadith, li-ruyatihi, means “on account of sighting it.”")

                        ArticleParagraph(articleMarkdown: "**Ikmaal (إِكمَال)**: “completing,” the fallback when the sky is overcast: finish the current month at thirty days.")

                        ArticleParagraph(articleMarkdown: "**Ikhtilaaf al-mataali (ٱختِلاَف ٱلمَطَالِع)**: the difference of the places of rising, the reality that a crescent visible in one land may not be visible in another, and the name of the position that each land follows its own sighting.")

                        ArticleParagraph(articleMarkdown: "**Yawm ash-shakk (يَوم ٱلشَّكّ)**: the day of doubt, the thirtieth of Sha‘baan when the crescent was not seen. It is not fasted as Ramadan.")
                    }
                }

                ArticleSourcesSection(article: "MoonSightingView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Sighting the New Month")
        .englishArticle().selectableArticleList(article: "MoonSightingView")
    }
}

struct CompileView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Quran was preserved from the start by mass memorization and careful writing, gathered into one volume under Abu Bakr, and standardized under Uthmaan.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    ArticleVideoLink(title: "How to prove the Quran has been preserved accurately", url: "https://www.youtube.com/watch?v=n281Zyywyn4&t=343s", channel: "OnePath Network")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "From the first revelation, the Quran was preserved by the Companions through precise memorization (hifdh) and careful writing on parchments, leather, bones, and leaves. Prophet Muhammad (peace and blessings be upon him) had official scribes (including Zayd ibn Thaabit) who wrote verses as they were revealed.")

                    ArticleParagraph(verbatim: "Every year in Ramadan, Jibreel (Gabriel) reviewed the Quran with Prophet Muhammad (peace and blessings be upon him); in the final year this review occurred twice (al-Ardah al-Aakhirah). Prophet Muhammad (peace and blessings be upon him) taught the Companions the exact wording, pronunciation, and the order in which the surahs and aayaat should be recited.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ALLAH’S PROMISE OF PRESERVATION")) {
                        ScriptureQuote(quran: "15:9")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ALLAH’S PROMISE OF PRESERVATION")) {
                        ScriptureQuote(quran: "15:9")

                        ScriptureQuote(quran: "75:16-19")

                        ScriptureQuote(quran: "73:4", words: 3...5)

                        ScriptureQuote(quran: "17:106")
                    }
                }

                Section(header: ArticleHeader("DURING THE PROPHET’S LIFETIME ﷺ")) {
                    ArticleBullet(verbatim: "• Memorization first: Many Companions memorized the Quran word-for-word and reviewed it with Prophet Muhammad (peace and blessings be upon him) in prayer and lessons.")
                    ArticleBullet(verbatim: "• Official scribes: Verses were dictated to scribes such as Zayd ibn Thaabit, Ubayy ibn Ka‘b, and others, and kept as written fragments verified by Prophet Muhammad (peace and blessings be upon him).")
                    ArticleBullet(verbatim: "• Annual review: Jibreel reviewed the entire Quran with Prophet Muhammad (peace and blessings be upon him) yearly in Ramadan; in the final year, the review occurred twice, confirming wording and order.")
                }

                Section(header: ArticleHeader("FIRST COMPILATION UNDER ABU BAKR")) {
                    ArticleParagraph(verbatim: "After the Battle of Yamaamah, many memorizers were martyred. About one year after the Prophet’s death (12 AH), at the counsel of Umar ibn al-Khattaab, Caliph Abu Bakr commissioned Zayd ibn Thaabit to collect the Quran into one compiled manuscript.")

                    ArticleParagraph(verbatim: "Zayd gathered the Quran from written materials and from those who had memorized it, accepting verses only when corroborated by multiple reliable witnesses and his own memorization, all according to what had been reviewed with Prophet Muhammad (peace and blessings be upon him).")

                    ArticleParagraph(verbatim: "This compiled mushaf was kept with Abu Bakr, then with Umar, and after Umar with Hafsah bint Umar (may Allah be pleased with them).")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("STANDARDIZATION UNDER UTHMAAN")) {
                        ArticleParagraph(verbatim: "As Islam spread, differences in regional reading threatened dispute. Caliph Uthmaan ibn Affaan formed a committee led by Zayd ibn Thaabit with senior Qurayshi scholars to copy the Abu Bakr compilation into standardized copies, writing in the dialect of Quraysh wherever the scribes differed (Saheeh al-Bukhaari 4987). This is the Uthmanic rasm (consonantal skeleton): written without dots or tashkeel (vowel marks), it carries every reading of the final review (al-Ardah al-Aakhirah) that fits it.")
                        ScriptureQuote(hadith: "bukhari:4987", cite: "Saheeh al-Bukhaari 4987", arabic: 71...111, english: 109...169)

                        ArticleParagraph(verbatim: "Uthmaan sent official copies to all the major cities (Makkah, Koofah, Basrah, Shaam, and others, with one kept in Madinah) and asked that non-verified personal materials be retired to prevent confusion between private notes/duas and the Quranic text. The Companions agreed with this measure, preserving unity upon the authenticated text.")

                        ArticleParagraph(verbatim: "This standardization lost nothing of the Quran; it unified the community upon the verified mushaf, which holds the whole of the final review, and ensured consistent public recitation.")
                    }

                    Section(header: ArticleHeader("CONSENSUS OF THE COMPANIONS")) {
                        ArticleParagraph(verbatim: "The Companions, foremost memorizers and teachers, accepted the compilation and the Uthmanic copies, and the Ummah has been united upon them ever since. Ali (may Allah be pleased with him) said that Uthmaan did nothing regarding the copies except in consultation with them (Ibn Abi Daawood, Kitaab al-Masaahif; Ibn Hajar graded its chain saheeh in Fath al-Baari).")
                    }

                    Section(header: ArticleHeader("MANUSCRIPT EVIDENCE (HISTORICAL NOTES)")) {
                        ArticleParagraph(verbatim: "Early Quranic manuscripts discovered in different regions (e.g., Hijaaz, Yemen, Syria, North Africa, Anatolia) reflect the early Uthmanic rasm and align with the text recited today.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("STANDARDIZATION UNDER UTHMAAN")) {
                        ArticleParagraph(verbatim: "As Islam spread, differences in regional reading threatened dispute. Caliph Uthmaan ibn Affaan formed a committee led by Zayd ibn Thaabit with senior Qurayshi scholars to copy the Abu Bakr compilation into standardized copies, writing in the dialect of Quraysh wherever the scribes differed (Saheeh al-Bukhaari 4987). This is the Uthmanic rasm (consonantal skeleton): written without dots or tashkeel (vowel marks), it carries every reading of the final review (al-Ardah al-Aakhirah) that fits it.")
                        ScriptureQuote(hadith: "bukhari:4987", cite: "Saheeh al-Bukhaari 4987", arabic: 71...111, english: 109...169)

                        ArticleParagraph(verbatim: "This was not a limitation of the copies. Dots (i‘jaam) were rare in the writing of the time and vowel signs had not yet been devised, and the Arabs, masters of their own language, read without them. Ibn al-Jazari explains that the Companions left the copies bare of dots and vowels on purpose, so that one written skeleton could carry every reading authentically received from the Prophet (peace and blessings be upon him) that fit it, since the reliance was on memorization rather than on the writing alone (an-Nashr fi al-Qiraa’aat al-Ashr, in its introduction). Other scholars hold that the letters were not dotted at all in the Companions' time and that the dots came later: the vowel dots with Abu al-Aswad ad-Du’ali, the letter dots with Nasr ibn Aasim and Yahya ibn Ya‘mar. On either view the copies were written bare, and the verified oral transmission determined how each word was recited.")

                        ArticleParagraph(verbatim: "Uthmaan sent official copies to all the major cities (Makkah, Koofah, Basrah, Shaam, and others, with one kept in Madinah) and asked that non-verified personal materials be retired to prevent confusion between private notes/duas and the Quranic text. The Companions agreed with this measure, preserving unity upon the authenticated text.")

                        ArticleParagraph(verbatim: "This standardization lost nothing of the Quran; it unified the community upon the verified mushaf, which holds the whole of the final review, and ensured consistent public recitation.")
                    }

                    Section(header: ArticleHeader("FROM THE PROPHET ﷺ TO THE CITIES")) {
                        ArticleParagraph(verbatim: "The whole road at a glance, from the revelation to the copies that reached each city and the readers who taught from them:")
                        ArticleIsnadCard("The Quran, the speech of Allah, brought down by Jibreel to the Prophet ﷺ, who taught it to his Companions, among them the four he named (Saheeh al-Bukhaari 4999) with Zayd ibn Thaabit and Ali; gathered into one volume by Zayd at Abu Bakr’s order in 12 AH and kept by Hafsah (Saheeh al-Bukhaari 4986); copied under Uthmaan by Zayd, Abdullah ibn az-Zubayr, Sa‘eed ibn al-As and Abd ar-Rahman ibn al-Haarith (Saheeh al-Bukhaari 4987); and sent to Madinah, Makkah, Shaam, Basrah and Koofah, where the ten readers taught.", isnad: .quranCompilation)
                    }

                    Section(header: ArticleHeader("CONSENSUS OF THE COMPANIONS")) {
                        ArticleParagraph(verbatim: "The Companions, foremost memorizers and teachers, accepted the compilation and the Uthmanic copies, and the Ummah has been united upon them ever since. Ali (may Allah be pleased with him) said that Uthmaan did nothing regarding the copies except in consultation with them (Ibn Abi Daawood, Kitaab al-Masaahif; Ibn Hajar graded its chain saheeh in Fath al-Baari). Abdullah ibn Mas‘ood (may Allah be pleased with him) at first disliked that Zayd ibn Thaabit was given the task over him and told the people of Iraq to keep their own copies, and az-Zuhri reports that the most virtuous of the Companions disliked that view of his (Jaami‘ at-Tirmidhi 3104; graded saheeh by al-Albaani); the scholars report that he later came back to the agreement of the rest.")
                        ScriptureQuote(hadith: "tirmidhi:3104", cite: "Jaami‘ at-Tirmidhi 3104; graded saheeh by al-Albaani", arabic: 228...311, english: 341...477)

                        ArticleParagraph(verbatim: "Zayd ibn Thaabit led the technical work in both Abu Bakr’s and Uthmaan’s projects, bringing rigorous verification. Senior scholars, including Quraysh experts, reviewed and approved the copies.")
                    }

                    Section(header: ArticleHeader("THE FOUR MASTERS & LEADING TRANSMITTERS")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:4999", cite: "Saheeh al-Bukhaari 4999", arabic: 34...47, english: 22...36)

                        ArticleParagraph(verbatim: "These masters, together with others like Zayd ibn Thaabit, were key references for wording, recitation, and teaching, anchoring transmission among the Companions and their students.")
                    }

                    Section(header: ArticleHeader("AHRUF, QIRAAT, AND THE UTHMANIC RASM")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) taught that the Quran was revealed in seven Ahruf (modes) for ease. The Quran was first compiled into one manuscript under Abu Bakr (may Allah be pleased with him), around one year after the Prophet’s death. Under Uthmaan (may Allah be pleased with him), official copies were sent to all the major cities, written as a skeletal script without dots or tashkeel. The majority of the Salaf and the imams hold that these copies are upon one of the seven Ahruf and contain the final review the Prophet (peace and blessings be upon him) went over with Jibreel (Ibn Taymiyyah, Majmoo‘ al-Fataawa 13/389–404); Ibn al-Jazari words it as the copies holding what their skeleton can carry of the seven Ahruf, leaving out nothing of the final review (an-Nashr). The canonical Qiraat, verified by chains, are all read within that skeleton. The 10 Qiraat (with their 20 Riwayaat) are mutawaatir and reflect how the prophetic recitation was preserved in writing and oral teaching.")

                        ArticleParagraph(verbatim: "Thus, standardization lost nothing of the Quran; it safeguarded it, preventing private notes and unverified materials from being mistaken for the Quran, while preserving the legitimate readings taught by Prophet Muhammad (peace and blessings be upon him).")
                    }

                    Section(header: ArticleHeader("KEY REPORTS (BRIEF)")) {
                        ScriptureQuote(hadith: "bukhari:4992", cite: "Saheeh al-Bukhaari 4992, Saheeh Muslim 818", arabic: 177...187, english: 204...237)
                        ArticleBullet(verbatim: "• Double review in final Ramadan (al-Ardah al-Aakhirah): reported in authentic narrations.")
                        ArticleBullet(verbatim: "• Abu Bakr’s compilation via Zayd after Yamaamah: authentic reports in Saheeh collections.")
                        ArticleBullet(verbatim: "• Uthmaan’s committee (with Zayd) and distribution of official copies: authentic reports in Saheeh collections.")
                    }

                    Section(header: ArticleHeader("MANUSCRIPT EVIDENCE (HISTORICAL NOTES)")) {
                        ArticleParagraph(verbatim: "Early Quranic manuscripts discovered in different regions (e.g., Hijaaz, Yemen, Syria, North Africa, Anatolia) reflect the early Uthmanic rasm and align with the text recited today.")

                        ArticleParagraph(verbatim: "Examples often cited by historians include: the Birmingham fragments (radiocarbon dated to the earliest period of Islam), folios from San‘a (whose upper text is Uthmanic; the erased lower text of one palimpsest is a non-Uthmanic, Companion-type codex, the kind of private copy that Uthmaan's measure retired), and early codices associated with major centers and later libraries (e.g., Topkapi).")

                        ArticleParagraph(verbatim: "While scholarly studies analyze paleography, orthography, and dating techniques, the consonantal text aligns with the standardized Uthmanic tradition, and the Quran remains read globally in the same wording preserved by the Ummah.")
                    }

                    Section(header: ArticleHeader("WHY WERE PRIVATE MATERIALS RETIRED?")) {
                        ArticleParagraph(verbatim: "Some Companions wrote personal notes (duas, explanations, or hadith) near Quranic passages. To prevent confusion between private annotations and the Quran, and to avoid unchecked variants, Uthmaan ordered that only the verified official copies be used for public recitation and that other materials be retired.")

                        ArticleParagraph(verbatim: "Apart from Ibn Mas‘ood's early reservation (described above), no Companion rejected the standardized mushaf. The community recited, taught, and transmitted the same Quran by memorization and writing through every generation.")
                    }
                }

                Section(header: ArticleHeader("CONTINUITY UNTIL TODAY")) {
                    ArticleParagraph(verbatim: "The Quran we hold today is the same revelation taught by Prophet Muhammad (peace and blessings be upon him), preserved through the consensus of the Companions, the Uthmanic rasm, the living tradition of memorization, and the mutawaatir Qiraat. Around the world, millions memorize the entire Quran, letter for letter, continuing an unbroken chain of transmission.")

                    ArticleParagraph(verbatim: "Public recitation, prayer, and education remain bound to the verified text. The Ummah’s practice fulfills Allah's (Glorified and Exalted be He) promise: its preservation is both textual and living.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("SELECT VERSES & REMINDERS")) {
                        ScriptureQuote(quran: "7:204")

                        ScriptureQuote(quran: "4:82")

                        ScriptureQuote(quran: "41:42")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Through unbroken memorization and a verified written text, the Quran remains today exactly as it was revealed, fulfilling Allah's promise to preserve it.")
                }

                ArticleSourcesSection(article: "CompileView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Compilation of the Quran")
        .englishArticle().selectableArticleList(article: "CompileView")
    }
}

struct TajweedView: View {
    @Environment(\.appearance) private var appearance
    @State private var showTajweedLegend = false

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Tajweed is the science of reciting the Quran correctly: giving each letter its proper articulation and every rule its due.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    ArticleVideoLink(title: "Tajweed lessons, letter by letter: the Learn Arabic 101 channel", url: "https://www.youtube.com/@Arabic101")
                }

                // The legend is the Quran reader's (TajweedLegendView.swift), so the door ships with it.
                #if HAS_QURAN
                Section(header: ArticleHeader("TAJWEED LEGEND")) {
                    #if os(iOS)
                    Button {
                        Settings.shared.hapticFeedback()
                        showTajweedLegend = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: "Quick Reference Guide")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(appearance.accent)

                            Text(verbatim: "Simple way to view basic Hafs an Aasim Tajweed rules with colors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    #endif
                }
                #endif

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "Tajweed (تَجوِيد) means “to make well, beautify, or improve,” from the root **j-w-d (ج و د)**. In the context of the Quran, it refers to the set of rules for proper pronunciation during Quran recitation, ensuring each letter is articulated with precision.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                    ScriptureQuote(quran: "73:4", words: 3...5)
                }

                Section(header: ArticleHeader("IMPORTANCE")) {
                    ArticleParagraph(verbatim: "Tajweed ensures the Quran is recited in the most accurate and beautiful way possible, exactly as it was revealed to the Prophet ﷺ. Reciting with Tajweed is not just about making recitation sound pleasant; it is about preserving the integrity of the Quran itself.")

                    ArticleParagraph(verbatim: "The Quran was revealed in Arabic, and every word, letter, and sound has a specific meaning and weight. A slight mispronunciation could change the meaning of a verse. Tajweed helps safeguard against these errors and honors the sacred text with the care and precision it deserves.")

                    ArticleParagraph(verbatim: "Many Muslims find that reciting the Quran with Tajweed enhances their spiritual experience. The attention to detail required for proper recitation encourages mindfulness and deeper reflection on the meaning of the verses, making the recitation feel more immersive and meaningful.")
                }

                Section(header: ArticleHeader("WHY LEARN TAJWEED?")) {
                    ArticleParagraph(verbatim: "Honoring the Quran: The Quran is the final revelation from Allah. Reciting it with care and precision is a form of respect and reverence for the sacred text.")

                    ArticleParagraph(verbatim: "Preventing Misunderstandings: By applying Tajweed rules, you avoid mistakes that may alter the meaning of verses. Even changing a single sound can result in an entirely different meaning.")

                    ArticleParagraph(verbatim: "Enhancing Spiritual Connection: Proper recitation encourages mindfulness and deeper reflection on the meaning of the verses, making your connection with the Quran more meaningful.")

                    ArticleParagraph(verbatim: "Following the Sunnah: The Prophet Muhammad ﷺ emphasized the importance of reciting the Quran correctly. By learning Tajweed, you follow his example and teachings.")
                }

                Section(header: ArticleHeader("GETTING STARTED")) {
                    ArticleParagraph(verbatim: "Learning Tajweed might seem intimidating at first, but understanding its importance can make the journey more meaningful. The best way to start is with a qualified teacher who can guide you through the articulation points and characteristics of each letter. Today, there are also online platforms, videos, and books that provide step-by-step lessons.")

                    ArticleParagraph(verbatim: "Focus on mastering the basic rules first, then gradually build your skills over time. Practicing consistently and recording your recitation can help you catch mistakes and improve pronunciation.")
                }

                Section(header: ArticleHeader("FOR MORE DETAILS")) {
                    // Both link straight back to this article, so each pair is a corridor.
                    // This file compiles for the Watch, where `OpenScreenLink` does not exist.
                    #if os(iOS)
                    OpenScreenLink(screen: .tajweedFoundations) {
                        TajweedFoundationsView()
                    } label: {
                        tajweedRowLabel("Tajweed Foundations", caption: "Every rule on a page of its own, with examples and the letters it applies to")
                    }

                    #if HAS_QURAN
                    if TajweedLessonsStore.isBundled {
                        OpenScreenLink(screen: .tajweedCourse) {
                            TajweedCourseView()
                        } label: {
                            tajweedRowLabel("Tajweed Course", caption: "The rules taught in order, lesson by lesson, with ayahs to play and a quiz in each")
                        }
                    }
                    #endif
                    #else
                    NavigationLink(destination: LazyDestination { TajweedFoundationsView() }) {
                        tajweedRowLabel("Tajweed Foundations", caption: "Every rule on a page of its own, with examples and the letters it applies to")
                    }

                    #if HAS_QURAN
                    if TajweedLessonsStore.isBundled {
                        NavigationLink(destination: LazyDestination { TajweedCourseView() }) {
                            tajweedRowLabel("Tajweed Course", caption: "The rules taught in order, lesson by lesson")
                        }
                    }
                    #endif
                    #endif
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Reciting with Tajweed preserves the Quran's pronunciation as it was received from the Prophet, and beautifies and safeguards its meaning.")
                }

                ArticleSourcesSection(article: "TajweedView")
            }
            .themedListRowBackground()
        }
        .navigationTitle(AppLanguage.article("Tajweed"))
        #if os(iOS)
        .openScreen(.tajweedArticle)
        #endif
        .englishArticle().selectableArticleList(article: "TajweedView")
        #if os(iOS) && HAS_QURAN
        .sheet(isPresented: $showTajweedLegend) {
            SheetNavigationContainer {
                TajweedLegendView()
            }
            .smallMediumSheetPresentation(startLarge: true)
        }
        #endif
    }

    /// A tajweed resource row's face, shared by the iOS `OpenScreenLink` and the Watch's plain link,
    /// so the two branches can never drift.
    private func tajweedRowLabel(_ title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(appearance.accent)
            Text(verbatim: caption)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct JuzView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Quran is divided into thirty roughly equal parts called Juz, making it easy to read over a month, especially in Ramadan.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "The Quran is divided into 114 Surahs (chapters), but it is also split into thirty roughly equal parts, called Juz (plural: Ajza).")

                    ArticleParagraph(verbatim: "This division helps Muslims complete the Quran’s recitation systematically, often one Juz per day, especially during Ramadan.")
                }

                Section(header: ArticleHeader("PURPOSE")) {
                    ArticleParagraph(verbatim: "The division into Juz is primarily for convenience rather than thematic arrangement. It enables systematic daily recitation.")

                    ArticleParagraph(verbatim: "Many Muslims strive to complete the Quran in Ramadan, reciting one Juz per night in Taraaweeh prayers. Each Juz is further divided into two Hizbs, making a total of 60 Hizbs.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                    ScriptureQuote(quran: "7:204")
                }

                Section(header: ArticleHeader("HISTORICAL NOTES")) {
                    ArticleParagraph(verbatim: "While the Quran's content remained unchanged since its revelation, the formal division into 30 Juz was standardized later to facilitate ease of recitation.")

                    ArticleParagraph(verbatim: "This structure fosters a daily relationship with the Quran and encourages reflection on its meanings.")

                    ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) emphasized balanced recitation, saying:")

                    ScriptureQuote(hadith: "abudawud:1394", cite: "Sunan Abi Daawood 1394; graded saheeh by al-Albaani", arabic: 39...47, english: 4...19)
                }

                // The juz names are the Quran model's table (`QuranData.juzList`), so the list ships with it.
                #if HAS_QURAN
                // Each Juz is named for the word it opens with, and that name is Arabic. Listing them by number
                // alone (which is all this screen used to do) leaves out the thing they are actually called.
                Section(header: ArticleHeader("THE THIRTY JUZ")) {
                    ForEach(QuranData.juzList) { juz in
                        HStack(spacing: 12) {
                            Text("\(juz.id)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundColor(appearance.accent)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle().fill(appearance.accent.opacity(0.15))
                                )

                            Text(juz.nameTransliteration)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Spacer(minLength: 8)

                            Text(juz.nameArabic)
                                .font(
                                    // The Islam face, matching the flag on the line below it - this read the
                                    // Quran picker's font, so "Basic" there rendered these names in a bundled
                                    // face the reader had switched away from (and vice versa).
                                    appearance.islamUsesCustomArabicFace
                                        ? Font.arabic(appearance.islamArabicFontName, size: 20, relativeTo: .subheadline)
                                        : .title3
                                )
                                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                                .foregroundColor(appearance.accent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .padding(.vertical, 2)
                    }
                }
                #endif

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The thirty Juz are a practical division for reading and memorization, not part of the revelation's meaning, helping Muslims complete the Quran regularly.")
                }

                ArticleSourcesSection(article: "JuzView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Thirty Juz")
        .englishArticle().selectableArticleList(article: "JuzView")
    }
}

struct AhrufView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Quran was revealed in seven ahruf (modes of recitation) as a mercy easing its recitation for the different Arab tribes.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    ArticleVideoLink(title: "The seven ahruf and the ten qiraat, explained", url: "https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "The Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحرُف), the plural of Harf (حَرف). The word Harf comes from the Arabic root H–r–f (ح ر ف), meaning “edge, border, side, or angle,” referring to a particular “way” or “mode.” Islamically and Quranically, Ahruf refers to the divinely revealed modes of recitation.")

                    ArticleParagraph(verbatim: "A Harf (حَرف), literally meaning “edge/side/aspect,” and in this context “a mode/way of reciting,” refers to a divinely revealed manner of recitation that includes slight differences in pronunciation, vowel patterns, pausing/connection, or permitted word-forms, and where the wordings differ, their meanings agree and complete one another, never contradicting in meaning or guidance.")

                    ArticleParagraph(verbatim: "All seven Ahruf are revelation from Allah (Glorified and Exalted be He). They are not scholarly opinions nor later inventions; they are part of the Quran that Allah (Glorified and Exalted be He) sent down to Prophet Muhammad (peace and blessings be upon him).")
                }

                Section(header: ArticleHeader("WHY SEVEN AHRUF?")) {
                    ArticleParagraph(verbatim: "The Arabs at the time of revelation had many dialects (Quraysh, Hudhayl, Tameem, Hawaazin, etc.). Allah (Glorified and Exalted be He), in His mercy, revealed the Quran in seven modes so that every tribe could recite the Quran easily without difficulty or burden.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) did not reveal seven different Qurans; rather, one Quran with divinely allowed flexibility, making memorization and recitation easier.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("PROPHETIC HADITH ON THE SEVEN AHRUF")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) said:")

                        ScriptureQuote(hadith: "bukhari:4992", cite: "Saheeh al-Bukhaari 4992, Saheeh Muslim 818", arabic: 177...187, english: 204...225)

                        ArticleParagraph(verbatim: "Another narration explains how the Prophet (peace and blessings be upon him) kept asking Jibreel for more ease for the Ummah:")

                        ScriptureQuote(hadith: "bukhari:4991", cite: "Saheeh al-Bukhaari 4991, Saheeh Muslim 819", arabic: 39...52, english: 4...48)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE WISDOM BEHIND THE VARIETY")) {
                        ArticleParagraph(verbatim: "Classical scholars draw out several wisdoms behind the revealed variety, beyond ease of recitation:")

                        ArticleParagraph(verbatim: "• Mercy and ease: a largely unlettered nation of many dialects could all recite the Quran as it was revealed, without hardship.\n• A sign of inimitability (i‘jaaz): the wordings vary, yet the meanings align and complete one another; no mode contradicts another in a single ruling or belief.\n• Proof of its divine origin: had the Quran been from other than Allah (Glorified and Exalted be He), such parallel wordings would inevitably clash. They never do.\n• Extra preservation: every reading was memorized and passed on through its own verified channels, multiplying the independent lines guarding the text.")

                        ArticleParagraph(verbatim: "Ibn Shihaab az-Zuhri, a narrator of these hadiths, added after one of them in Saheeh Muslim (819): “It has reached me that these seven styles are essentially one, not differing about what is permitted and what is forbidden.” The variation lies in how the words are recited, not in what the Quran commands: no harf permits what another forbids.")
                    }

                    Section(header: ArticleHeader("PROPHETIC HADITH ON THE SEVEN AHRUF")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) said:")

                        ScriptureQuote(hadith: "bukhari:4992", cite: "Saheeh al-Bukhaari 4992, Saheeh Muslim 818", arabic: 177...187, english: 204...225)

                        ArticleParagraph(verbatim: "Another narration explains how the Prophet (peace and blessings be upon him) kept asking Jibreel for more ease for the Ummah:")

                        ScriptureQuote(hadith: "bukhari:4991", cite: "Saheeh al-Bukhaari 4991, Saheeh Muslim 819", arabic: 39...52, english: 4...48)

                        Text(verbatim: "In the famous incident of Umar and Hishaam ibn Hakeem: both of them recited differently, and Prophet Muhammad (peace and blessings be upon him) said that both were revealed, proving that the variations are not mistakes but revelation (Saheeh al-Bukhaari 4992; Saheeh Muslim 818).")
                            .font(.title3)
                            .foregroundColor(appearance.accent.opacity(0.85))
                    }
                }

                // The two questions every reader of this page asks next, answered as the Salaf answered
                // them (Abu, 2026-11-02: "100% right ... according to Sunni salafi"). Ibn Taymiyyah's
                // answer on the seven ahruf (Majmu' al-Fatawa 13/389-404) reports the majority of the
                // Salaf: the Uthmanic mushaf is upon one harf and holds the final review; the "all seven"
                // view is that of some jurists, reciters and theologians (al-Baqillani). Ibn al-Jazari's
                // wording of the majority view (an-Nashr): what the rasm can carry of the seven.
                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ARE THE SEVEN AHRUF THE SEVEN QIRAAT?")) {
                        ArticleParagraph(verbatim: "No. Ibn Taymiyyah writes that there is no dispute among the scholars whose word counts that the seven Ahruf in which the Prophet (peace and blessings be upon him) said the Quran was revealed are not the readings of the seven famous reciters (Majmoo‘ al-Fataawa 13/389–404). The seven readings were gathered by Ibn Mujaahid more than three centuries after the Prophet (peace and blessings be upon him); the shared number led some people to confuse the two, and the scholars warned against it.")
                    }

                    Section(header: ArticleHeader("THE AHRUF IN THE UTHMANIC MUSHAF")) {
                        ArticleParagraph(verbatim: "During the caliphate of Uthmaan (may Allah be pleased with him), the Ummah was unified upon official copies written in the Uthmanic rasm, a bare skeletal script without dots or tashkeel, and sent to all the major cities.")

                        ArticleParagraph(verbatim: "The majority of the Salaf and the imams hold that the mushaf of Uthmaan is upon one of the seven Ahruf and contains the final review, the recitation the Prophet (peace and blessings be upon him) went over with Jibreel in his last Ramadan; some jurists, reciters and theologians held instead that it contains all seven (Ibn Taymiyyah, Majmoo‘ al-Fataawa 13/389–404).")

                        ArticleParagraph(verbatim: "Either way, nothing of the Quran was lost. Reciting by the seven Ahruf was a permission (rukhsah) and an ease, not an obligation, so when the Companions agreed together on the Uthmanic copies, they kept everything of the final review.")
                    }

                    Section(header: ArticleHeader("DO THE AHRUF AFFECT PRESERVATION?")) {
                        ArticleParagraph(verbatim: "No. The Quran remains perfectly preserved: letter for letter, word for word, as it stood in the final review. The Ahruf are part of that preservation, not a contradiction to it.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) promised:")

                        ScriptureQuote(quran: "15:9")
                    }

                    Section(header: ArticleHeader("WHAT ABOUT THE 10 QIRAAT?")) {
                        ArticleParagraph(verbatim: "The 10 Qiraat are the mass-transmitted (mutawaatir) readings of the Uthmanic mushaf, each within its written skeleton, preserved through the teaching tradition.")

                        Text(verbatim: "Learn more in the next section: 10 Qiraat (Canonical Recitations).")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ARE THE SEVEN AHRUF THE SEVEN QIRAAT?")) {
                        ArticleParagraph(verbatim: "No. Ibn Taymiyyah writes that there is no dispute among the scholars whose word counts that the seven Ahruf in which the Prophet (peace and blessings be upon him) said the Quran was revealed are not the readings of the seven famous reciters (Majmoo‘ al-Fataawa 13/389–404). The seven readings were gathered by Ibn Mujaahid more than three centuries after the Prophet (peace and blessings be upon him); the shared number led some people to confuse the two, and the scholars warned against it.")

                        ArticleParagraph(verbatim: "What the Ahruf are, exactly, the scholars discussed at length, and the best-known views are three: seven dialects of the Arabs spread through the Quran (Abu Ubayd al-Qaasim ibn Sallaam); different words for one meaning, as halumma, aqbil and ta‘aal all mean “come” (at-Tabari, and Ibn Abd al-Barr gives it as the view of most scholars); and seven kinds of difference in wording, such as number, verb form, vowel endings, word order and a letter added or dropped (Ibn Qutaybah, and after him Ibn al-Jazari). What they agree on is enough: each harf is revealed, the wordings may differ while the meaning agrees, and no harf contradicts another.")
                    }

                    Section(header: ArticleHeader("THE AHRUF IN THE UTHMANIC MUSHAF")) {
                        ArticleParagraph(verbatim: "The majority of the Salaf and the imams hold that the mushaf of Uthmaan (may Allah be pleased with him) is upon one of the seven Ahruf and contains the final review, the recitation the Prophet (peace and blessings be upon him) went over with Jibreel in his last Ramadan. Ibn Taymiyyah reports this, and reports that some jurists, reciters and theologians, among them al-Baaqillaani, held instead that the mushaf contains all seven (Majmoo‘ al-Fataawa 13/389–404). Ibn al-Jazari words the majority view as: the Uthmanic copies hold what their written skeleton can carry of the seven Ahruf, and the whole of the final review, leaving out none of it (an-Nashr, in its introduction).")

                        ArticleParagraph(verbatim: "Either way, nothing of the Quran was lost. Reciting by the seven Ahruf was a permission (rukhsah) and an ease, not an obligation: the Ummah was given the choice of which harf to recite, as Ibn Jareer at-Tabari explained and Ibn Taymiyyah relates in the same answer. So when the Companions agreed together on the Uthmanic copies, they kept everything of the final review, and every reading that fits their skeleton and reached us by mass transmission is still recited today.")
                    }

                    Section(header: ArticleHeader("DO THE AHRUF AFFECT PRESERVATION?")) {
                        ArticleParagraph(verbatim: "No. The Quran remains perfectly preserved: letter for letter, word for word, as it stood in the final review. The Ahruf are part of that preservation, not a contradiction to it.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) promised:")

                        ScriptureQuote(quran: "15:9")

                        ArticleParagraph(verbatim: "The variations in Ahruf never contradict one another in meaning, belief, or ruling; where the wordings differ, each adds a facet that agrees with the others. They highlight precision and perfection: the Ummah memorized and transmitted every letter exactly as revealed.")

                        ArticleParagraph(verbatim: "Each harf is revealed, preserved, and protected by Allah (Glorified and Exalted be He). Muslims do not choose or invent a harf; we only recite what Allah (Glorified and Exalted be He) revealed through His Messenger, Prophet Muhammad (peace and blessings be upon him).")
                    }

                    Section(header: ArticleHeader("HOW AHRUF WERE PRESERVED")) {
                        ArticleParagraph(verbatim: "• Prophet Muhammad (peace and blessings be upon him) taught the Companions each harf personally.\n• Jibreel reviewed the Quran with Prophet Muhammad (peace and blessings be upon him) every year in Ramadan.\n• In the year Prophet Muhammad (peace and blessings be upon him) passed away, Jibreel reviewed it twice (al-Ardah al-Aakhirah).")

                        ArticleParagraph(verbatim: "About one year after the Prophet’s passing, Abu Bakr (may Allah be pleased with him) commissioned the first complete compilation of the Quran into one manuscript. During the caliphate of Uthmaan (may Allah be pleased with him), the Ummah was then unified upon official copies from that preserved compilation, written in the Uthmanic rasm and sent to all the major cities. The rasm was a bare skeletal script, without dots or tashkeel (vowel marks), which the Arabs read without difficulty, and the Companions left it bare on purpose, so that one written skeleton could be read in every authentically received way that matched it (Ibn al-Jazari, an-Nashr). Other scholars hold that the letters were simply not dotted yet in their time; on either view, the bare skeleton carried the readings.")

                        ArticleParagraph(verbatim: "What the copies carry is preserved through oral transmission, ijaazahs, and chains of narration (isnaad).")
                    }

                    Section(header: ArticleHeader("AN ANALOGY: SEVEN NUMBERS, MANY PASSWORDS")) {
                        ArticleParagraph(verbatim: "Think of the seven Ahruf as seven numbers you are handed, and each Qiraah as a password formed from them. The numbers (Ahruf) are the revealed building blocks; a password (Qiraah) is one specific, fixed combination drawn from them, whether it uses one digit, a few, or all seven.")

                        ArticleParagraph(verbatim: "Seven numbers could form far more than ten passwords, and likewise more readings than ten were transmitted historically. The 10 Qiraat are the combinations preserved with mass transmission (mutawaatir): rigorously verified, widely taught, and famous across the Ummah. The picture follows Ibn al-Jazari's wording; the scholars who say the mushaf is upon one harf place every Qiraah within that harf, and both agree that each canonical Qiraah lies within the Uthmanic rasm and is fully Quran.")

                        Text(verbatim: "Since every harf is revealed by Allah (Glorified and Exalted be He), every canonical combination of them is fully Quran, and no combination was ever invented: each Qiraah was received from Prophet Muhammad (peace and blessings be upon him) through an unbroken chain and applies its rules with complete consistency, exactly as taught.")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                    }

                    Section(header: ArticleHeader("WHAT ABOUT THE 10 QIRAAT?")) {
                        ArticleParagraph(verbatim: "The 10 Qiraat are the mass-transmitted (mutawaatir) readings of the Uthmanic mushaf, each within its written skeleton, preserved through the teaching tradition.")

                        ArticleParagraph(verbatim: "Each Qiraah has an unbroken chain (isnaad) from the reciter to his teacher, and his teacher's teacher, back to Prophet Muhammad (peace and blessings be upon him). Here is the chain of the reading of Aasim, which divides into his two narrators, Hafs and Shu‘bah:")

                        ArticleIsnadCard("The reading of Aasim: from the Prophet ﷺ through Uthmaan, Ali, Ibn Mas‘ood, Ubayy and Zayd ibn Thaabit, and Aasim’s teachers Abu Abd ar-Rahman as-Sulami, Zirr ibn Hubaysh and Abu Amr ash-Shaybaani, to Aasim (d. 127 AH), where it divides into Hafs (d. 180 AH) and Shu‘bah (d. 193 AH).", isnad: .hafsReading)

                        Text(verbatim: "Learn more in the next section: 10 Qiraat (Canonical Recitations).")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The seven ahruf are all from Allah and are not the seven qiraat; the Uthmanic mushaf, written in a skeletal rasm without dots or tashkeel and sent to all the major cities, holds the whole of the final review, and the canonical recitations preserve it to this day.")
                }

                ArticleSourcesSection(article: "AhrufView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("7 Ahruf (Modes)")
        .englishArticle().selectableArticleList(article: "AhrufView")
    }
}

#if os(iOS)
/// A door out of the guide (the explorer, head-to-head, the chains): an accent chip, a title and a
/// one-line promise, the same shape the reader's sheets use for their explorer door.
struct QiraatDoorRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
    }
}
#endif

extension QiraatView {
    /// One reading's card in "The Companions behind each Qiraah", opening the imam's page. Spelled at
    /// the call site as `lineageRow("Nafi", companions: [...])` so `Scripts/build_islam_corpus.py`
    /// (`LINEAGE_RE`) keeps the Companions in the Ask AI corpus.
    @ViewBuilder
    func lineageRow(_ masterID: String, companions: [String], note: String? = nil) -> some View {
        if let master = QiraatProfiles.master(id: masterID) {
            NavigationLink(destination: LazyDestination { QiraahMasterDetailView(profile: master) }) {
                QiraahLineageRow(masterID: masterID, companions: companions, note: note)
            }
        }
    }
}

struct QiraatView: View {
    @Environment(\.appearance) private var appearance

    #if DEBUG && os(iOS)
    /// "-openQiraatExplorer": push the explorer as the article appears.
    @State private var debugOpenExplorer = false
    /// "-qiraatExplorerAt <surah:ayah>" with "-openQiraatExplorer": open there instead of at 1:4.
    private static var debugExplorerPlace: (surah: Int, ayah: Int)? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: "-qiraatExplorerAt"), arguments.indices.contains(idx + 1) else { return nil }
        let parts = arguments[idx + 1].split(separator: ":").compactMap { Int($0) }
        return parts.count == 2 ? (parts[0], parts[1]) : nil
    }
    /// "-openQiraatNarrator <tag>": push that narrator's page as the article appears.
    @State private var debugOpenNarrator = false
    private static var debugNarratorTag: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: "-openQiraatNarrator"), arguments.indices.contains(idx + 1) else { return nil }
        return arguments[idx + 1]
    }
    #endif

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the ten Qiraat are the authentic, mass-transmitted ways of reciting the Quran, each traced through a continuous chain to the Prophet.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    ArticleVideoLink(title: "The seven ahruf and the ten qiraat, explained", url: "https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                    ArticleVideoLink(title: "The anomalous (shaadhdh) qiraat", url: "https://www.youtube.com/watch?v=CeV6w0rCilQ&t=80s")
                }

                // The reading is one thing, seeing it another: the explorer walks the places where
                // the riwayat actually differ, ayah by ayah, with every reading side by side.
                #if os(iOS)
                Section(header: ArticleHeader("EXPLORE")) {
                    // The explorer reads every riwayah's text, so it comes with the Quran.
                    #if HAS_QURAN
                    OpenScreenLink(screen: .qiraatExplorer) {
                        QiraatExplorerView()
                    } label: {
                        QiraatDoorRow(systemImage: "arrow.left.and.right.text.vertical", title: "Qiraat Explorer",
                                      subtitle: "Every place the riwaayaat differ, ayah by ayah: what changes, what it means, and all twenty readings side by side")
                    }
                    OpenScreenLink(screen: .qiraatExplorer) {
                        QiraatExplorerView(mode: .duel)
                    } label: {
                        QiraatDoorRow(systemImage: "arrow.left.arrow.right", title: "Compare Two Riwaayaat",
                                      subtitle: "Pick any two riwaayaat and step through the places where they part ways")
                    }
                    #endif
                    OpenScreenLink(screen: .qiraatIsnadIndex) {
                        QiraatIsnadIndexView()
                    } label: {
                        QiraatDoorRow(systemImage: "point.3.connected.trianglepath.dotted", title: "Chains to the Prophet ﷺ",
                                      subtitle: "Every reading's isnaad as a diagram: narrator, imam, Successors, Companions, the Prophet ﷺ")
                    }
                }
                #endif

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "The 10 Qiraat (قِرَاءَات), from the root q–r–a (قَرَأَ) meaning “to read/recite,” literally means “readings/recitations.” Islamically and Quranically, a Qiraah (قِرَاءَة) is a specific, verified method of reciting the Quran. The 10 Qiraat are the preserved, mass-transmitted (mutawaatir, مُتَوَاتِر) recitations of the Quran, each a precise method taught by Prophet Muhammad (peace and blessings be upon him) and transmitted through authentic chains of narrators (isnaad إِسنَاد). They do not represent different Qurans, but different prophetic ways of reciting the same revelation.")

                    ArticleParagraph(verbatim: "As covered in the previous section, the Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحرُف), modes of recitation for ease. Jibreel (Gabriel) brought these modes to Prophet Muhammad (peace and blessings be upon him), who taught them to the Ummah. Around one year after the Prophet’s passing, Abu Bakr (may Allah be pleased with him) commissioned the first complete compilation of the Quran into one manuscript, and later Uthmaan (may Allah be pleased with him) unified public recitation upon official copies from that preserved text, sent to all the major cities. The Qiraat show how those Ahruf were preserved in practice through the Uthmanic rasm (الرَّسم العُثمَانِي), the consonantal skeleton of the mushaf (مُصحَف): written without dots or tashkeel, which the Arabs did not need, the one skeleton carries every authentically received reading that matches it. The seven Ahruf are not the seven or the ten Qiraat; every canonical Qiraah is read within the one Uthmanic rasm.")

                    // Every reading carries a city, and the article named them only in passing on the
                    // rows below (Abu, 2026-09-14: "qiraat view should also mention the city they were
                    // developed in"). Cities here are the ones the app's own profiles ship in
                    // `QiraatProfiles.masters`, so the prose and the rows can never disagree.
                    ArticleParagraph(verbatim: "This is also why every Qiraah carries a city with it. Uthmaan (may Allah be pleased with him) sent a mushaf to each major centre and a teacher to recite by it, and the recitation of that centre settled around them, passing from teacher to student until one imam became its recognised authority. A Qiraah is named after that imam, but what he transmitted is the established reading of his city: Madinah (Naafi and, before him, his own teacher Abu Ja‘far), Makkah (Ibn Katheer), Basrah (Abu Amr and, after him, Ya‘qoob), Damascus and greater Shaam (Ibn Aamir), and Koofah (Aasim, Hamzah and al-Kisaa’i, with Khalaf later carrying the Kufan tradition on from Baghdaad).")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHAT IS A QIRAAH?")) {
                        ArticleParagraph(verbatim: "A Qiraah (قِرَاءَة) is a canonical, authenticated way of reciting the Quran that meets three criteria: (1) agreement with the Uthmanic rasm (الرَّسم العُثمَانِي), (2) sound Arabic language, and (3) authentic, widespread transmission (tawaatur تَوَاتُر).")

                        Text(verbatim: "All 10 Qiraat return to Prophet Muhammad (peace and blessings be upon him). Every reciter has an unbroken chain of students → teachers → Companions → Prophet Muhammad (peace and blessings be upon him).")
                            .font(.body)
                            .foregroundColor(appearance.accent)

                        ArticleParagraph(verbatim: "Most differences are within established rules of tajweed (تَجوِيد), allowable word-forms and vowels, elongation (madd مَدّ), assimilation (idghaam إِدغَام), imaalah (إِمَالَة), and stopping/continuation, while preserving the same meanings and guidance.")

                        ArticleParagraph(verbatim: "Important: The Qiraat are not arbitrary. Each was received, not composed: it reads the Uthmanic rasm exactly as it was taught from Prophet Muhammad (peace and blessings be upon him), preserved through both writing and oral transmission in a rigorously taught, verifiable method of recitation.")
                    }

                    Section(header: ArticleHeader("HOW THE READINGS DIFFER")) {
                        ArticleParagraph(verbatim: "Imam Ibn al-Jazari (d. 833 AH), the foremost authority of this science, grouped the differences between the canonical readings into three kinds (an-Nashr fi al-Qiraa’aat al-Ashr, in its introduction):")

                        ArticleParagraph(verbatim: "• The same word, pronounced in more than one revealed way, with the meaning unchanged.\n• Different word-forms pointing to the same reality: in Surah al-Faatihah, “Maaliki yawmid-deen” (King of the Day of Judgment) and “Maaliki yawmid-deen” (Owner of the Day of Judgment) are both revealed, and both describe Allah (Glorified and Exalted be He).\n• Different words carrying complementary meanings: each reading adds a facet, and none contradicts another.")

                        Text(verbatim: "There is no fourth category of contradiction. Across all the canonical readings, not a single ayah makes lawful what another forbids or affirms what another denies; the differences enrich the meaning, never oppose it.")
                            .font(.body)
                            .foregroundColor(appearance.accent)

                        ArticleParagraph(verbatim: "The mushafs differ on the page too: which readings pronounce the hamzah and which ease or drop it, the Madani dot for hamzat al-wasl, and the dots of imaalah and taqleel under the letters.")
                        ArticleDoorRow(door: .article("RiwayatDifferencesView"))
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("AN ANALOGY: SEVEN NUMBERS, MANY PASSWORDS")) {
                        ArticleParagraph(verbatim: "Imagine being handed seven numbers and asked to form passwords from them. The seven numbers are like the seven Ahruf: every one of them revealed by Allah (Glorified and Exalted be He). A password formed from those numbers is like a Qiraah: one specific, fixed combination drawn from the revealed modes.")

                        ArticleParagraph(verbatim: "A password does not have to use all seven digits; it may draw on one, a few, or all of them. In the same way, a Qiraah may reflect one harf, several, or elements of many, and it is fully Quran either way, because every harf on its own is revealed Quran, and any single Qiraah on its own is sufficient, complete Quran.")

                        ArticleParagraph(verbatim: "Just as seven numbers can form far more than ten passwords, the revealed modes could combine into more readings than ten, and other readings were indeed transmitted historically. The 10 Qiraat are the combinations that reached us mutawaatir (mass-transmitted): rigorously verified, taught continuously from teacher to student, and famous across the Ummah. Together they carry what the Uthmanic rasm, a skeletal script with no dots or tashkeel, holds of the seven Ahruf. The picture follows Ibn al-Jazari's wording; the scholars who say the mushaf is upon one harf place every Qiraah within that harf, and both agree that each canonical Qiraah lies within the Uthmanic rasm and is fully Quran.")

                        Text(verbatim: "But no one sat down and invented these combinations. Each Qiraah was received, not designed: it descends through an unbroken chain (isnaad) from its reciters → their teachers → a Companion → Prophet Muhammad (peace and blessings be upon him), who taught it exactly this way.")
                            .font(.body)
                            .foregroundColor(appearance.accent)

                        ArticleParagraph(verbatim: "Because each Qiraah is Quran, reciting one ayah in one Qiraah and the next ayah in another is still reciting nothing but the Book of Allah (Glorified and Exalted be He); the Companions themselves recited in different revealed ways, and Prophet Muhammad (peace and blessings be upon him) approved them all.")

                        ArticleParagraph(verbatim: "And like a password that must be entered exactly, each Qiraah keeps its own rules from the Ahruf alive with complete internal consistency: its madd lengths, imaalah, assimilations, and word-forms are applied the same way every single time, exactly as transmitted.")
                    }

                    Section(header: ArticleHeader("WHAT IS A QIRAAH?")) {
                        ArticleParagraph(verbatim: "A Qiraah (قِرَاءَة) is a canonical, authenticated way of reciting the Quran that meets three criteria: (1) agreement with the Uthmanic rasm (الرَّسم العُثمَانِي), (2) sound Arabic language, and (3) authentic, widespread transmission (tawaatur تَوَاتُر).")

                        Text(verbatim: "All 10 Qiraat return to Prophet Muhammad (peace and blessings be upon him). Every reciter has an unbroken chain of students → teachers → Companions → Prophet Muhammad (peace and blessings be upon him).")
                            .font(.body)
                            .foregroundColor(appearance.accent)

                        ArticleParagraph(verbatim: "Most differences are within established rules of tajweed (تَجوِيد), allowable word-forms and vowels, elongation (madd مَدّ), assimilation (idghaam إِدغَام), imaalah (إِمَالَة), and stopping/continuation, while preserving the same meanings and guidance.")

                        ArticleParagraph(verbatim: "Important: The Qiraat are not arbitrary. Each was received, not composed: it reads the Uthmanic rasm exactly as it was taught from Prophet Muhammad (peace and blessings be upon him), preserved through both writing and oral transmission in a rigorously taught, verifiable method of recitation.")

                        ArticleParagraph(verbatim: "This precision goes back to how the Quran was taught from the very beginning: the Companions would take a portion of aayaat from Prophet Muhammad (peace and blessings be upon him) and not move past it until they had mastered both its recitation and what it contained (Musnad Ahmad 23482, from Abu Abd ar-Rahman as-Sulami; its chain graded hasan by Shu‘ayb al-Arnaa’oot). The Qiraat continue that discipline, teacher to student, to this day.")
                    }

                    Section(header: ArticleHeader("HOW THE READINGS DIFFER")) {
                        ArticleParagraph(verbatim: "Imam Ibn al-Jazari (d. 833 AH), the foremost authority of this science, grouped the differences between the canonical readings into three kinds (an-Nashr fi al-Qiraa’aat al-Ashr, in its introduction):")

                        ArticleParagraph(verbatim: "• The same word, pronounced in more than one revealed way, with the meaning unchanged.\n• Different word-forms pointing to the same reality: in Surah al-Faatihah, “Maaliki yawmid-deen” (King of the Day of Judgment) and “Maaliki yawmid-deen” (Owner of the Day of Judgment) are both revealed, and both describe Allah (Glorified and Exalted be He).\n• Different words carrying complementary meanings: each reading adds a facet, and none contradicts another.")

                        Text(verbatim: "There is no fourth category of contradiction. Across all the canonical readings, not a single ayah makes lawful what another forbids or affirms what another denies; the differences enrich the meaning, never oppose it.")
                            .font(.body)
                            .foregroundColor(appearance.accent)

                        // What a reader SEES when they switch riwayah (Abu, 2026-09-29: "mention which
                        // riwayahs have hamzas, which don't, which have Madani hamzat al-wasl and which
                        // have dots"), on a page of its own with counts from the app's texts.
                        ArticleParagraph(verbatim: "The mushafs differ on the page too: which readings pronounce the hamzah and which ease or drop it, the Madani dot for hamzat al-wasl, and the dots of imaalah and taqleel under the letters.")
                        ArticleParagraph(verbatim: "A printed mushaf is set in one riwaayah, and many editions note a second narrator’s differences in the margin: Khallaad beside Khalaf, Shu‘bah beside Hafs. The explorer above does that for all twenty at once.")
                        ArticleDoorRow(door: .article("RiwayatDifferencesView"))
                    }
                }

                Section(header: ArticleHeader("QIRAAH (قِرَاءَة) VS RIWAAYAH (رِوَايَة)")) {
                    ArticleBullet(verbatim: "• Qiraah: the recitation method attributed to an Imam of recitation (e.g., Naafi, Aasim).")
                    ArticleBullet(verbatim: "• Riwaayah: the narration/transmission of that Qiraah by a primary raawi (narrator). Each Qiraah has two principal riwayaat (plural of riwaayah).")

                    ArticleParagraph(verbatim: "Example: “Hafs an Aasim” means the riwaayah (narration) of Hafs (حَفص) from the Qiraah (recitation) of Aasim (عَاصِم). “Warsh an Naafi” means the riwaayah of Warsh (وَرش) from the Qiraah of Naafi (نَافِع).")

                    Text(verbatim: "Hafs an Aasim is the most widespread globally today; that does not mean it is the only right one. All 10 Qiraat (and their 20 Riwayaat) are valid, mutawaatir, and from Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON CLARIFICATIONS")) {
                        ArticleParagraph(verbatim: "Many people hear about 7 and 10 together. Both references are used by scholars: the famous seven canonical recitations (as-Sab‘ah) and the full ten canonical Qiraat (7 + 3), all preserved through reliable transmission.")

                        ArticleParagraph(verbatim: "The original seven were famously codified by Imam Abu Bakr Ibn Mujaahid. Their Imams are: Naafi (Madinah), Ibn Katheer (Makkah), Abu Amr (Basrah), Ibn Aamir (Damascus), Aasim (Koofah), Hamzah (Koofah), and al-Kisaa’i (Koofah).")

                        ArticleParagraph(verbatim: "The three that complete the ten, counted with the seven by scholars before him and confirmed by Imam Ibn al-Jazari, are: Abu Ja‘far (Madinah), Ya‘qoob al-Hadrami (Basrah), and Khalaf al-Bazzaar (Baghdaad, transmitting the Kufan tradition he received through Hamzah).")

                        ArticleParagraph(verbatim: "Hafs is a riwaayah from Aasim, and Warsh is a riwaayah from Naafi. So when people say Hafs or Warsh, they are naming a narration path within the canonical recitation tradition.")

                        Text(verbatim: "Today, Hafs an Aasim is the most widely recited globally (often estimated around 90%+), while other canonical recitations such as Warsh an Naafi remain authentic and practiced.")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                    }
                }

                Section(header: ArticleHeader("AUTHENTICITY & PRESERVATION")) {
                    ArticleParagraph(verbatim: "The 10 Qiraat are mutawaatir, mass attested by many independent chains. They are part of the precise preservation Allah (Glorified and Exalted be He) promised for His Book.")

                    ScriptureQuote(quran: "15:9")

                    ArticleParagraph(verbatim: "They do not affect preservation; rather, they manifest it: letter for letter, word for word, in all the ways Prophet Muhammad (peace and blessings be upon him) taught.")

                    Text(verbatim: "Every canonical reading is equally Quran. As classical scholars explain, each one is revelation received by Prophet Muhammad (peace and blessings be upon him) and taught by him; none is a scholar's preference or a later refinement. Whoever recites by any canonical riwaayah is reciting the Book of Allah (Glorified and Exalted be He) itself.")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE FOUR MASTERS OF THE QURAN")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:4999", cite: "Saheeh al-Bukhaari 4999", arabic: 34...47, english: 22...36)

                        ArticleParagraph(verbatim: "These four masters were among the foremost teachers of the Quran among the Companions, and their recitation and teaching shaped subsequent generations of transmitters.")
                    }
                }

                // The ten as scholars actually count them: the seven of Ibn Mujahid, then the three
                // Ibn al-Jazari completed them with (Abu, 2026-09-04: "split up the 10 qiraat into the
                // original 7 and then the added 3"). Every row also says where the reading is recited
                // today, and the profile pages carry the full sentence.
                Section(header: ArticleHeader("THE SEVEN QIRAAT (القِرَاءَاتُ السَّبعُ)")) {
                    ArticleParagraph(verbatim: "The seven readings Imam Abu Bakr Ibn Mujaahid (d. 324 AH) collected in his Kitaab as-Sab‘ah, one from each of the great centres of recitation: Madinah, Makkah, Basrah and Damascus, and three from Koofah. Each is named after its imam. Tap any of them to read about the imam, his two narrators, and where the reading is recited today.")

                    ForEach(QiraatProfiles.masters(in: QiraatProfiles.sevenIDs)) { master in
                        NavigationLink(destination: LazyDestination { QiraahMasterDetailView(profile: master) }) {
                            QiraatProfileRow(
                                title: master.id,
                                arabic: master.arabic,
                                detail: "\(master.city), died \(master.diedAH) AH",
                                note: QiraatProfiles.recitedTodayShort(master: master.id),
                                ordinal: QiraatProfiles.ordinal(ofMaster: master.id)
                            )
                        }
                    }
                }

                Section(header: ArticleHeader("THE THREE COMPLETING QIRAAT (القِرَاءَاتُ الثَّلَاثُ المُتَمِّمَةُ)")) {
                    ArticleParagraph(verbatim: "The three readings Imam Ibn al-Jazari (d. 833 AH) set out in ad-Durrah al-Mudiyyah, completing the ten, and whose mass transmission he defended in an-Nashr: Abu Ja‘far of Madinah, Ya‘qoob of Basrah and Khalaf of Baghdaad (the tenth reader, a different reading from his own narration of Hamzah). Scholars had counted them with the seven long before him. Together with the seven they are the ten Qiraat.")

                    ForEach(QiraatProfiles.masters(in: QiraatProfiles.threeIDs)) { master in
                        NavigationLink(destination: LazyDestination { QiraahMasterDetailView(profile: master) }) {
                            QiraatProfileRow(
                                title: master.id,
                                arabic: master.arabic,
                                detail: "\(master.city), died \(master.diedAH) AH",
                                note: QiraatProfiles.recitedTodayShort(master: master.id),
                                ordinal: QiraatProfiles.ordinal(ofMaster: master.id)
                            )
                        }
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("PRACTICAL STUDY & ADVICE")) {
                        ArticleBullet(verbatim: "• Learn with a qualified teacher who has ijaazah (إِجَازَة) and isnaad (إِسنَاد). Do not self-invent pronunciations or rely only on apps without verification.")
                        ArticleBullet(verbatim: "• Remember: the variety of the readings is a mercy and an ease from Allah, not a contradiction. They illuminate the Quran’s depth and precision.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE 14 RIWAYAAT OF THE SEVEN")) {
                        ArticleParagraph(verbatim: "Each Qiraah (recitation method) has two primary riwayaat (narrations). These are the fourteen transmissions of the seven readings, grouped under their imam in the same order as above, with where each is recited today. Tap any of them to read about the narrator.")

                        ForEach(QiraatProfiles.masters(in: QiraatProfiles.sevenIDs)) { master in
                            ForEach(QiraatProfiles.narrators(ofMaster: master.id)) { narrator in
                                NavigationLink(destination: LazyDestination { RiwayahNarratorDetailView(profile: narrator) }) {
                                    QiraatProfileRow(
                                        title: "\(narrator.name) an \(master.id)",
                                        arabic: narrator.arabic,
                                        detail: "\(narrator.city), died \(narrator.diedAH) AH",
                                        note: QiraatProfiles.recitedTodayShort(narrator: narrator.id),
                                        systemImage: "link"
                                    )
                                }
                            }
                        }
                    }

                    Section(header: ArticleHeader("THE 6 RIWAYAAT OF THE THREE")) {
                        ArticleParagraph(verbatim: "The six transmissions of the three completing readings. All twenty riwayaat together are the canonical transmissions used in teaching and ijaazah (chain certification).")

                        ForEach(QiraatProfiles.masters(in: QiraatProfiles.threeIDs)) { master in
                            ForEach(QiraatProfiles.narrators(ofMaster: master.id)) { narrator in
                                NavigationLink(destination: LazyDestination { RiwayahNarratorDetailView(profile: narrator) }) {
                                    QiraatProfileRow(
                                        title: "\(narrator.name) an \(master.id)",
                                        arabic: narrator.arabic,
                                        detail: "\(narrator.city), died \(narrator.diedAH) AH",
                                        note: QiraatProfiles.recitedTodayShort(narrator: narrator.id),
                                        systemImage: "link"
                                    )
                                }
                            }
                        }
                    }

                    Section(header: ArticleHeader("THE COMPANIONS BEHIND EACH QIRAAH")) {
                        ArticleParagraph(verbatim: "Every Qiraah traces back through its Imam and narrators to the Companions (may Allah be pleased with them) who learned the Quran directly from Prophet Muhammad (peace and blessings be upon him). The chains below show which Companions each reading is transmitted from.")

                        #if os(iOS)
                        OpenScreenLink(screen: .qiraatIsnadIndex) {
                            QiraatIsnadIndexView()
                        } label: {
                            Label("See every chain as a diagram, link by link", systemImage: "point.3.connected.trianglepath.dotted")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appearance.accent)
                        }
                        #endif

                        // One card per reading instead of ten paragraphs of run-on names (Abu, 2026-09-26:
                        // "listing all the qiraat like that looks terrible"), in the order of the lists above:
                        // the seven, then the three. The Companions are the article's own lists.
                        lineageRow("Naafi", companions: ["Umar ibn al-Khattaab", "Zayd ibn Thaabit", "Ubayy ibn Ka‘b", "Abdullah ibn Abbaas", "Abdullah ibn Ayyaash", "Abu Hurayrah"])
                        lineageRow("Ibn Katheer", companions: ["Umar ibn al-Khattaab", "Zayd ibn Thaabit", "Ubayy ibn Ka‘b", "Abdullah ibn Abbaas", "Abdullah ibn as-Saa’ib"])
                        lineageRow("Abu Amr", companions: ["Umar ibn al-Khattaab", "Uthmaan ibn Affaan", "Ali ibn Abi Taalib", "Abdullah ibn Mas‘ood", "Abu Moosa al-Ash‘ari", "Abdullah ibn Abbaas", "Abdullah ibn Ayyaash", "Abdullah ibn as-Saa’ib", "Ubayy ibn Ka‘b", "Zayd ibn Thaabit", "Abu Hurayrah"])
                        lineageRow("Ibn Aamir", companions: ["Uthmaan ibn Affaan", "Abu ad-Darda"])
                        lineageRow("Aasim", companions: ["Uthmaan ibn Affaan", "Ali ibn Abi Taalib", "Abdullah ibn Mas‘ood", "Zayd ibn Thaabit", "Ubayy ibn Ka‘b"], note: "Most Muslims today recite Hafs from Aasim")
                        lineageRow("Hamzah", companions: ["Uthmaan ibn Affaan", "Ali ibn Abi Taalib", "Ubayy ibn Ka‘b", "Zayd ibn Thaabit", "Abdullah ibn Mas‘ood", "Husayn ibn Ali"])
                        lineageRow("al-Kisaa’i", companions: ["Umar ibn al-Khattaab", "Uthmaan ibn Affaan", "Ali ibn Abi Taalib", "Ubayy ibn Ka‘b", "Zayd ibn Thaabit", "Abdullah ibn Mas‘ood", "Abdullah ibn Abbaas", "Abdullah ibn Ayyaash", "Abu Hurayrah", "Husayn ibn Ali"])
                        lineageRow("Abu Ja‘far", companions: ["Zayd ibn Thaabit", "Ubayy ibn Ka‘b", "Abdullah ibn Abbaas", "Abdullah ibn Ayyaash", "Abu Hurayrah"])
                        lineageRow("Ya‘qoob", companions: ["Umar ibn al-Khattaab", "Uthmaan ibn Affaan", "Ali ibn Abi Taalib", "Ubayy ibn Ka‘b", "Zayd ibn Thaabit", "Abdullah ibn Mas‘ood", "Abu Moosa al-Ash‘ari", "Abdullah ibn Abbaas", "Abdullah ibn Ayyaash", "Abdullah ibn as-Saa’ib", "Abu Hurayrah"])
                        lineageRow("Khalaf al-Aashir", companions: ["Uthmaan ibn Affaan", "Ali ibn Abi Taalib", "Abdullah ibn Mas‘ood", "Zayd ibn Thaabit", "Ubayy ibn Ka‘b", "Husayn ibn Ali"])
                    }

                    Section(header: ArticleHeader("WHAT THIS CHAIN SHOWS")) {
                        ArticleParagraph(verbatim: "We begin with what Prophet Muhammad (peace and blessings be upon him) began with: the Book of Allah (Glorified and Exalted be He). It is well established that the Quran has reached us by mass transmission (tawaatur) through the chains of Ahl as-Sunnah wal-Jamaa‘ah.")

                        ArticleParagraph(verbatim: "Every one of these narrators of the noble Quran received it, through the chains above, from the Messenger of Allah (peace and blessings be upon him) by way of his Companions (may Allah be pleased with them), the first to learn, gather, preserve, and transmit it.")

                        Text(verbatim: "The ten imams and their twenty narrators are all of Ahl as-Sunnah, and no reading rests on anyone who reviled the Companions. Each imam read on several teachers, so a reading never hangs on one man: Hamzah also read on Humraan ibn A‘yan, whom Abu Daawood called a Raafidi (adh-Dhahabi, Meezaan al-I‘tidaal), but he read as well on al-A‘mash and Ibn Abi Layla, and his reading reaches the Companions through them. The article linked below words it as: not a single Twelver (Ithna Ashari) Shia is among these transmitters. Humraan died before that sect took its final form, so the claim holds in that narrow sense; it is worded more carefully here because the Sunni critics already counted him among the Raafidah. This is part of the Quran’s preservation: Allah (Glorified and Exalted be He) kept the transmission of His Book in the hands of those who honoured the Companions of His Prophet (peace and blessings be upon him).")
                            .font(.body)
                            .foregroundColor(appearance.accent)

                        Link(destination: URL(string: "https://mahajjah.com/the-manner-in-which-the-ahlus-sunnah-and-shia-act-upon-this-hadith/")!) {
                            Label("Source: Mahajjah, on how Ahlus Sunnah and the Shia act upon this hadith", systemImage: "link")
                        }
                        .font(.caption)
                    }

                    Section(header: ArticleHeader("THE TEXTS STUDENTS MEMORISE")) {
                        ArticleParagraph(verbatim: "The ten are taught from three poems, memorised and recited to a teacher line by line. Ash-Shaatibiyyah (Hirz al-Amaani wa Wajh at-Tahaani), by al-Qaasim ibn Firruh ash-Shaatibi of Xativa in al-Andalus (d. 590 AH in Cairo), sets out the seven readings and their fourteen riwayaat in 1,173 lines rhyming in lam, which is why it is also called al-Laamiyyah. It opens with the names of the imams and the code letters that stand for them, then the usool (the rules that recur across the whole Quran: the hamzah, madd, idghaam, the ha of the pronoun), then the farsh (the word-by-word differences, surah by surah), and closes with notes on writing and pausing.")

                        ArticleParagraph(verbatim: "Ad-Durrah al-Mudiyyah, by Ibn al-Jazari (d. 833 AH), adds the three completing readings in about 240 lines. Together the two poems are the Ashara Sughra, the ten by the shorter route, where students of the ten begin. His Tayyibat an-Nashr (about 1,015 lines, drawn from his prose an-Nashr fi al-Qiraa’aat al-Ashr) is the Ashara Kubra: the same ten readings with many more turuq (routes of transmission) under each narrator, studied after the Sughra.")

                        ArticleParagraph(verbatim: "Ibn al-Jazari set three conditions for an accepted reading: a sound chain of transmission, well known among the masters of the craft; agreement with one of the Uthmaani mushafs, even if only by what its skeleton can carry; and agreement with Arabic, even in one of its ways. Most of the scholars of usool and fiqh word the first condition as mass transmission (tawaatur), as in the criteria near the top of this page; Abu Shaamah and Ibn al-Jazari held that a sound, well-known chain is enough when the other two are met. The ten meet the conditions on both views, and the twenty riwayaat in this app follow the Sughra: ash-Shaatibiyyah for the seven, ad-Durrah for the three.")
                    }

                    Section(header: ArticleHeader("OTHER REPORTED QIRAAT")) {
                        ArticleParagraph(verbatim: "There are other reported qiraat besides these Ten. Unlike the 10 Qiraat, which are mutawaatir and mass attested, those others do not reach mutawaatir status, and a reading that fails the conditions above is called shaadh (irregular). Some of them have a chain to Prophet Muhammad (peace and blessings be upon him), and the scholars use them to explain meanings and Arabic, but they are not recited as Quran, in prayer or outside it: an-Nawawi gives this as the position of his school and of others (al-Majmoo‘ 3/392), and it is the position of the great majority of the scholars. Ibn Taymiyyah records the other view as well. Of a reading outside the Uthmanic copies that is authentic from a Companion, such as Ibn Mas‘ood's, one narration each from Maalik and Ahmad permits reciting it in prayer, since the Companions and the Successors did; the other narration, the view of most scholars, forbids it, since it did not come by mass transmission. And a reading beyond the ten that fits the Uthmanic copies with a sound chain, such as al-A‘mash's, he says may be recited in prayer and outside it by whoever has it established, and is not shaadh in that case (Majmoo‘ al-Fataawa 13/389–404).")

                        ArticleParagraph(verbatim: "The best known are the four readings beyond the ten, called shaadh: those of al-Hasan al-Basri, Ibn Muhaysin, Yahya al-Yazidi and al-A‘mash. Students of the Kubra sometimes take them up after the ten; with the ten they are called the fourteen.")

                        ArticleParagraph(verbatim: "We recite what is known with certainty (yaqeen يَقِين) to be from Prophet Muhammad (peace and blessings be upon him): the 10 Qiraat and their 20 Riwayaat. This unites the Ummah upon what is rigorously established.")
                    }

                    Section(header: ArticleHeader("PRACTICAL STUDY & ADVICE")) {
                        ArticleBullet(verbatim: "• Learn with a qualified teacher who has ijaazah (إِجَازَة) and isnaad (إِسنَاد). Do not self-invent pronunciations or rely only on apps without verification.")
                        ArticleBullet(verbatim: "• The usual road: Hafs an Aasim with tajweed first; then a second riwaayah or the seven, memorising ash-Shaatibiyyah; then the ten by the Sughra, adding ad-Durrah; then the Kubra with Tayyibat an-Nashr. At every stage the Quran is read to a teacher who holds ijaazah, and books and apps are the supplement.")
                        ArticleBullet(verbatim: "• Remember: the variety of the readings is a mercy and an ease from Allah, not a contradiction. They illuminate the Quran’s depth and precision.")
                    }

                    Section(header: ArticleHeader("IN-APP AUDIO")) {
                        ArticleParagraph(verbatim: "In this app, every one of the 20 riwayaat has at least one complete full-surah reciter. Ayah-by-ayah playback remains Hafs-based, so availability varies by full-surah vs. ayah-by-ayah playback.")
                    }
                }

                Section(header: ArticleHeader("RECAP")) {
                    Text(verbatim: "“The 10 Qiraat are the preserved, mass-transmitted (mutawaatir) recitations taught by Prophet Muhammad (peace and blessings be upon him), passed down through authentic chains. Each Qiraah is a specific, verified method of reciting the Quran, not a different text. They reflect how the Ahruf were preserved in writing and oral transmission. All 10 Qiraat (and their 20 Riwayaat) return to Prophet Muhammad (peace and blessings be upon him).”")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("VISUAL GUIDE")) {
                    VStack(spacing: 12) {
                        Image("Qiraat1")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focusableImage("Qiraat1", title: "The Ten Qiraat")

                        Image("Qiraat2")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focusableImage("Qiraat2", title: "The Ten Qiraat")
                    }
                    .padding(.vertical, 4)

                    Link(destination: URL(string: "https://www.instagram.com/p/DZhwEM4Es0b/")!) {
                        Label("View the original post on Instagram", systemImage: "link")
                    }
                    .font(.caption)
                }

                Section(header: ArticleHeader("IMAGE CREDITS")) {
                    Text(verbatim: "The two infographics above are shared with credit to the original creators on Instagram. Please follow and support their work:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Group {
                        qiraatCreditLink(handle: "orthodox__muslim_badr_deen")
                        qiraatCreditLink(handle: "abdul_quddus_khan_")
                        qiraatCreditLink(handle: "lets.think.deeply")
                        qiraatCreditLink(handle: "khan_ayaan_2008")
                        qiraatCreditLink(handle: "imaanxlogy")
                        qiraatCreditLink(handle: "truth_seeker_of_god")
                    }
                    .font(.caption)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The differences among the Qiraat are all revelation and add richness of meaning; none contradicts another, and all are recited today.")

                    // The textual comparison: the output of a program that diffed the printed mushafs,
                    // word by word against Hafs. It hid behind seven taps on the closing line until
                    // 2026-09-04, when Abu could not find it; it is a plain row now, and the page itself
                    // still opens with its caveats before any number.
                    #if os(iOS)
                    Text(verbatim: "Every Qiraah is the Quran, complete.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    NavigationLink(destination: LazyDestination { QiraatTextAnalysisView() }) {
                        Label("Riwaayah Statistics: How Far Each Differs from Hafs", systemImage: "flask")
                    }
                    .foregroundColor(appearance.accent)
                    #endif
                }

                ArticleSourcesSection(article: "QiraatView")
            }
            .themedListRowBackground()
        }
        #if DEBUG && os(iOS)
        #if HAS_QURAN
        .debugPushDestination(isPresented: $debugOpenExplorer) {
            // "-qiraatExplorerMode duel" opens Compare Two instead of All Riwayat.
            if let place = Self.debugExplorerPlace {
                QiraatExplorerView(surah: place.surah, ayah: place.ayah)
            } else if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-qiraatExplorerMode"),
                      ProcessInfo.processInfo.arguments.indices.contains(idx + 1),
                      let mode = QiraatExplorerView.Mode(rawValue: ProcessInfo.processInfo.arguments[idx + 1]) {
                QiraatExplorerView(mode: mode)
            } else {
                QiraatExplorerView()
            }
        }
        #endif
        .debugPushDestination(isPresented: $debugOpenNarrator) {
            if let tag = Self.debugNarratorTag, let profile = QiraatProfiles.narrator(tag: tag) {
                RiwayahNarratorDetailView(profile: profile)
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-openQiraatExplorer") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenExplorer = true }
            } else if Self.debugNarratorTag != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { debugOpenNarrator = true }
            }
        }
        #endif
        .navigationTitle("10 Qiraat (Recitations)")
        #if os(iOS)
        .openScreen(.qiraatArticle)
        #endif
        .englishArticle().selectableArticleList(article: "QiraatView")
    }

    /// A tappable Instagram handle that opens the creator's profile, used for the infographic credits.
    private func qiraatCreditLink(handle: String) -> some View {
        Link(destination: URL(string: "https://www.instagram.com/\(handle)/")!) {
            Label("@\(handle)", systemImage: "at")
        }
    }
}

/// Whether the readings contradict one another, and how the scholars answer it (Abu, 2026-11-24:
/// "do the qiraat contradict?", Sunni Salafi). Every example names who reads what, checked against
/// QiraatVariants.json.xz (the readers of each reading); the explanations are the app's own words.
struct QiraatContradictView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "QiraatContradictView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Do the Qiraat Contradict?")
        .englishArticle().selectableArticleList(article: "QiraatContradictView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: no. The canonical readings differ the way two aayaat differ, never the way a truth differs from a lie. Some differ only in how a word is pronounced; some give two meanings that are both true of the same thing; and some give two meanings about two different things, both true. Not one reading makes lawful what another forbids, or affirms what another denies. The Prophet (peace be upon him) heard two Companions recite differently and said of each, “Thus it was revealed.”"),
        ]),
        ArticleSection("THE QUESTION", [
            .text("Allah made the absence of contradiction a proof that the Quran is from Him:"),
            .ayah("4:82"),
            .markdown("So the question is fair. Muslims today recite the Quran in ten canonical **qiraa’aat (قِرَاءَات)**, readings, each carried by two transmitters, and a Hafs mushaf and a Warsh mushaf differ here and there in a letter or a vowel. If the Quran has no contradiction, how can it be read in more than one way?"),
            .text("The answer begins with what the Prophet (peace be upon him) himself said when the question first arose, among his own Companions."),
        ]),
        ArticleSection("WHAT THE PROPHET SAID", [
            .text("Umar ibn al-Khattaab (may Allah be pleased with him) heard Hishaam ibn Hakeem recite Surah al-Furqaan differently from the way he had learned it from the Prophet, and dragged him to the Prophet by his cloak. The Prophet had each of them recite:"),
            .hadith("bukhari:4992", cite: "Saheeh al-Bukhaari 4992, Saheeh Muslim 818", arabic: 175...187, english: [198...237]),
            .markdown("He did not say one of them was right and the other mistaken. He said of both readings, **“Thus it was revealed.”** Abdullah ibn Mas‘ood (may Allah be pleased with him) had the same experience:"),
            .hadith("bukhari:3476", cite: "Saheeh al-Bukhaari 3476", arabic: 50...59, english: [54...71]),
            .longOnly(.text("Ubayy ibn Ka‘b (may Allah be pleased with him) once felt a doubt enter him on hearing two men recite differently, until the Prophet struck his chest and it left him (Saheeh Muslim 820).")),
            .longOnly(.hadith("muslim:820a", cite: "Saheeh Muslim 820", arabic: 32...122, english: [0...163])),
            .longOnly(.text("Ubayy also narrated how the readings were first given:")),
            .longOnly(.hadith("muslim:821a", cite: "Saheeh Muslim 821", arabic: 56...152, english: [0...160])),
            .text("Three things are settled by these narrations. The readings are from Allah, not from the reciters. They were given as an ease for the ummah. And the response to them is to accept every one, not to argue over which is the Quran; the Prophet warned that this kind of dispute is disbelief:"),
            .hadith("abudawud:4603", cite: "Sunan Abi Daawood 4603; graded hasan saheeh by al-Albaani", arabic: 30...33, english: [4...9]),
        ]),
        ArticleSection("VARIETY, NOT CONTRADICTION", [
            .markdown("The scholars name the two kinds of difference. **Ikhtilaaf at-tanawwu‘ (اختِلَاف التَّنَوُّع)** is a difference of variety: two things, both true, that sit together. **Ikhtilaaf at-tadaadd (اختِلَاف التَّضَادّ)** is a difference of contradiction: two claims where one must be false. Every difference between the canonical readings is of the first kind."),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him), in his fatwa on the seven ahruf, put the readings in the first kind:")),
            .longOnly(.quote(text: "“Sometimes the meaning of one is not the meaning of the other, but both meanings are true; and this is a difference of variety and diversity, not a difference of opposition and contradiction” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 13/391).", arabic: "وَقَد يَكُونُ مَعنَى أَحَدِهِمَا لَيسَ هُوَ مَعنَى الآخَرِ، لَكِن كِلَا المَعنَيَينِ حَقٌّ، وَهَذَا اختِلَافُ تَنَوُّعٍ وَتَغَايُرٍ، لَا اختِلَافُ تَضَادٍّ وَتَنَاقُضٍ", dimmed: true)),
            .longOnly(.text("And he gave the rule for how a Muslim treats them:")),
            .shortOnly(.text("Ibn Taymiyyah (may Allah have mercy on him), in his fatwa on the seven ahruf, gave the rule for how a Muslim treats them:")),
            .quote(text: "“These readings in which the meaning differs are all true, and each reading beside another is like an ayah beside an ayah: it is obligatory to believe in all of them and to follow the meaning each contains, in knowledge and in action. It is not permissible to leave what one of them requires for the sake of the other, thinking that to be a contradiction” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 13/391-392).", arabic: "فَهَذِهِ القِرَاءَاتُ الَّتِي يَتَغَايَرُ فِيهَا المَعنَى كُلُّهَا حَقٌّ، وَكُلُّ قِرَاءَةٍ مِنهَا مَعَ القِرَاءَةِ الأُخرَى بِمَنزِلَةِ الآيَةِ مَعَ الآيَةِ، يَجِبُ الإِيمَانُ بِهَا كُلِّهَا، وَاتِّبَاعُ مَا تَضَمَّنَتهُ مِنَ المَعنَى عِلمًا وَعَمَلًا، لَا يَجُوزُ تَركُ مُوجَبِ إِحدَاهُمَا لِأَجلِ الأُخرَى ظَنًّا أَنَّ ذَلِكَ تَعَارُضٌ", dimmed: true),
            .text("That is the rule the rest of this page applies: a second reading is treated the way a second ayah is treated. It is believed, and what it adds is acted on."),
        ]),
        ArticleSection("THE THREE KINDS OF DIFFERENCE", [
            .text("Imam Ibn al-Jazari (d. 833 AH), the authority of this science, went through every difference between the readings and found that each falls into one of three kinds:"),
            .quote(text: "“We have examined the differences between all the readings and found that they do not go beyond three cases: first, the wording differs and the meaning is one; second, both differ, and both can still be true of one thing; third, both differ, and they cannot both be true of one thing, but they agree from another angle that does not entail contradiction” (Ibn al-Jazari, an-Nashr fi al-Qiraa’aat al-Ashr 1/49-50).", arabic: "وَقَد تَدَبَّرنَا اختِلَافَ القِرَاءَاتِ كُلَّهَا فَوَجَدنَاهَا لَا تَخلُو مِن ثَلَاثَةِ أَحوَالٍ: أَحَدُهَا اختِلَافُ اللَّفظِ وَالمَعنَى وَاحِدٌ، الثَّانِي اختِلَافُهُمَا جَمِيعًا مَعَ جَوَازِ اجتِمَاعِهِمَا فِي شَيءٍ وَاحِدٍ، الثَّالِثُ اختِلَافُهُمَا جَمِيعًا مَعَ امتِنَاعِ جَوَازِ اجتِمَاعِهِمَا فِي شَيءٍ وَاحِدٍ، بَل يَتَّفِقَانِ مِن وَجهٍ آخَرَ لَا يَقتَضِي التَّضَادَّ", dimmed: true),
            .longOnly(.text("The three sections below take each kind in turn, using examples Ibn al-Jazari himself gives where they serve, and naming who reads what. He closes the discussion with the verdict:")),
            .longOnly(.quote(text: "“So there is no incompatibility, opposition, or contradiction in any of the readings” (Ibn al-Jazari, an-Nashr fi al-Qiraa’aat al-Ashr 1/51).", arabic: "فَلَيسَ فِي شَيءٍ مِنَ القِرَاءَاتِ تَنَافٍ وَلَا تَضَادٌّ وَلَا تَنَاقُضٌ", dimmed: true)),
        ]),
        ArticleSection("1. THE SAME WORD, SAID TWO WAYS", [
            .markdown("The word and its meaning are one; only its sound differs. In al-Faatihah most of the readers say **as-siraat** with a sad, while Qunbul from Ibn Katheer and Ruways from Ya‘qoob say **as-siraat** with a sin. Ibn Katheer reads **rooh al-quds** where the others say **rooh al-qudus**, and in “the ignorant would think them self-sufficient” some say **yahsabuhum** and others **yahsibuhum**. These are among the examples Ibn al-Jazari gives for this kind, which he says are simply dialects: nothing in the meaning moves at all."),
            .ayah("1:6"),
        ]),
        ArticleSection("2. TWO MEANINGS, BOTH TRUE OF ONE THING", [
            .text("Here the words differ and so does the sense, but both senses describe the same subject, so the second reading adds a meaning instead of opposing the first. It is as though two aayaat had been joined in one."),
            .ayah("1:4"),
            .markdown("Aasim, al-Kisaa’i, Ya‘qoob, and Khalaf read **maaliki**, “Owner of the Day of Judgement”; the rest read **maaliki**, “King of the Day of Judgement.” Allah is both: He owns that Day and everything in it, and He is its King, whose command alone is obeyed in it."),
            .longOnly(.ayah("2:10", words: 9...11)),
            .longOnly(.markdown("The readers of Koofah read **yakdhiboon**, “because they used to lie”; the others read **yukadhdhiboon**, “because they used to deny.” The hypocrites did both: they lied when they said “we believe,” and they denied the Messenger in their hearts.")),
            .longOnly(.ayah("2:259", words: 48...55)),
            .longOnly(.markdown("Ibn Aamir and the readers of Koofah read **nunshizuha**, “how We raise them up” and set them in place; the rest read **nunshiruha**, “how We bring them to life.” Allah did both to the same bones, and the ayah goes on to say He then clothed them with flesh.")),
            .longOnly(.ayah("49:6", words: 3...7)),
            .longOnly(.markdown("Most read **fa-tabayyanu**, “investigate”; Hamzah, al-Kisaa’i, and Khalaf read **fa-tathabbatu**, “hold firm and verify.” The one command needs both: do not act on a sinner’s report until you have checked it and are sure.")),
        ]),
        ArticleSection("3. TWO MEANINGS, BOTH TRUE OF TWO THINGS", [
            .text("Here the two readings speak of two different things, so they could not be said of one subject, but each is true of its own, and they meet without any clash."),
            .ayah("2:125", words: 6...10),
            .markdown("Most read **wa-ttakhidhu**, a command: “And take the standing place of Ibraaheem as a place of prayer.” Naafi‘ and Ibn Aamir read **wa-ttakhadhu**, a report: “and they took the standing place of Ibraaheem as a place of prayer.” One reading gives the command, the other records that it was carried out. Both are true."),
            .longOnly(.ayah("17:102", words: 0...10)),
            .longOnly(.markdown("This is one of Ibn al-Jazari’s own examples. Moosa (peace be upon him) is answering Pharaoh. Most read **la-qad ‘alimta**, “you have certainly known” that none but the Lord of the heavens and the earth sent these signs down; al-Kisaa’i reads **la-qad ‘alimtu**, “I have certainly known.” Pharaoh knew it in himself while denying it, as Allah says of his people that “they rejected them, while their souls were convinced thereof” (Quran 27:14), and Moosa knew it with certainty. Each reading is true of its own speaker.")),
            .longOnly(.ayah("27:14", words: 0...3)),
            .longOnly(.ayah("3:146", words: 0...6)),
            .longOnly(.markdown("Most read **qaatala**, “how many a prophet fought, with many devoted men beside him”; Naafi‘, Ibn Katheer, Abu Amr, and Ya‘qoob read **qutila**, “how many a prophet was killed, with many devoted men beside him.” Some prophets fought alongside their followers and some were killed among them, and in both cases the believers with them did not weaken, as the ayah goes on to say. The two readings together tell the whole history.")),
        ]),
        ArticleSection("ONE RASM CARRIES THEM ALL", [
            .markdown("The copies of the Quran that Uthmaan (may Allah be pleased with him) sent to the cities were written in the **rasm (رَسم)**, the bare skeleton of the letters, without the dots that tell ba’ from ta’ or ra’ from zaay, and without vowel marks. Ibn al-Jazari records that the Companions left the copies bare on purpose, so that one written form would hold the readings the Prophet had taught."),
            .longOnly(.markdown("Look at the examples above with the dots taken away. **ننشزها** and **ننشرها** are one skeleton, differing only by the dot on the zaay. **فتبينوا** and **فتثبتوا** are the same row of teeth. **ملك** is written without its alif, so it carries both **maaliki** and **maaliki**. The readings are not two texts that have to be reconciled; they are one text, read in the ways it was revealed to be read.")),
            .shortOnly(.markdown("Look at the example above in the bare skeleton: **ملك** is written without its alif, so it carries both **maaliki** and **maaliki**. The readings are not two texts that have to be reconciled; they are one text, read in the ways it was revealed to be read.")),
            .text("That is the opposite of what a corrupted book looks like. When copyists change a text, the result is two texts that disagree, and a later scholar has to decide which one is original. With the Quran the readings were received from the Prophet first, then written in one rasm the Companions agreed on, and every canonical reading fits inside it. A reading that does not fit the rasm is not counted as Quran at all."),
            .door(.article("CompileView")),
        ]),
        ArticleSection("WHEN THE READINGS TOUCH A RULING", only: .long, [
            .text("The hardest test is an ayah of law, because there a contradiction would show itself as two rulings. Take the ayah about approaching one’s wife after her menses:"),
            .ayah("2:222", words: 10...20),
            .markdown("Hafs and most of the readers read **hatta yathurna**, “until they are pure,” meaning the bleeding has stopped. Shu‘bah from Aasim, Hamzah, al-Kisaa’i, and Khalaf read **hatta yattahharna**, “until they have purified themselves,” meaning by the bath. The same ayah then says, in every reading, **“and when they have purified themselves (tatahharna), then come to them.”** So the two readings do not give two rulings; together they give the one ruling the majority of the scholars hold: the bleeding must stop, and she must take the ritual bath."),
            .text("Ibn Taymiyyah gives this very ayah, and the two readings of “touched” women in the ayah of wudu, as examples of readings that agree in one respect and differ in another, each adding to the ruling rather than overturning it."),
            .markdown("The case people raise most is the washing of the feet in wudu. In Surah al-Maa’idah, Hafs and others read **wa-arjulakum**, joining the feet to the washed limbs, while Ibn Katheer, Abu Amr, Hamzah, Abu Ja‘far, Khalaf, and Shu‘bah from Aasim read **wa-arjulikum**, beside the wiped head. The Prophet (peace be upon him) washed his feet in every description of his wudu, and warned those who only wiped them:"),
            .ayah("5:6", words: 12...16),
            .hadith("bukhari:60", cite: "Saheeh al-Bukhaari 60, Saheeh Muslim 241", arabic: 48...51, english: [53...58]),
            .text("Ibn Katheer (may Allah have mercy on him) records the scholars’ explanations of the second reading: that its ending follows the neighbouring word, as Arabic allows; that it refers to wiping over leather socks, which ash-Shaafi‘i held and which the Sunnah also established; or that it means a light washing. Then he settles the ruling:"),
            .quote(text: "“On every interpretation, washing the feet is an obligation that cannot be done without, because of the ayah and the hadiths” (Ibn Katheer, Tafseer al-Quran al-Azeem 3/53, on 5:6).", arabic: "وَعَلَى كُلِّ تَقدِيرٍ فَالوَاجِبُ غَسلُ الرِّجلَينِ فَرضًا، لَا بُدَّ مِنهُ لِلآيَةِ وَالأَحَادِيثِ", dimmed: true),
            .text("So the reading that some have used to drop the washing of the feet is, in the hands of Ahl as-Sunnah, either an extra ruling (the wiping over socks) or a matter of grammar, and never a second wudu that contradicts the first."),
        ]),
        ArticleSection("WHY MORE THAN ONE READING?", only: .long, [
            .markdown("**Ease.** The Prophet (peace be upon him) kept asking for ease for his ummah, as Ubayy’s narration above says, because the Arabs spoke many dialects and many of them were old, unlettered, or unused to the speech of Quraysh."),
            .markdown("**More meaning in fewer words.** A second reading is a second ayah in the space of one. Instead of “He is King of the Day and He is Owner of the Day,” one word, read two ways, says both."),
            .markdown("**A proof of preservation.** The readings were carried by different chains, in different cities, by teachers who never met, and they all fit the one rasm and agree in every meaning. A book that men had altered could not survive that test."),
            .markdown("**An honour for this ummah.** No other people kept their scripture with such care that they can say, for every letter, which reader recited it and from whom he took it, back to the Prophet."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Are the ten qiraa’aat ten different Qurans?**"),
            .text("No. There is one Quran, one rasm, and one meaning; the readings are the ways that one Quran was revealed to be recited. A Hafs mushaf and a Warsh mushaf are the same book, and a scholar of the readings recites all ten."),
            .markdown("**Is Hafs the “real” Quran and the others variants?**"),
            .text("No. Hafs is simply the most widespread riwaayah today. Warsh is read across North and West Africa, Qaaloon in Libya and Tunisia, and ad-Doori from Abu Amr in parts of Sudan, and each is as fully the Quran as Hafs. Preferring one in your own recitation is fine; treating the others as less than Quran is not."),
            .markdown("**Are the qiraa’aat the same as the seven ahruf?**"),
            .text("No. The seven ahruf are the modes in which the Quran was revealed; the qiraa’aat are the canonical ways of reading the Uthmanic mushaf, drawn from them. The two are explained on their own pages."),
            .door(.article("AhrufView")),
            .door(.article("QiraatView")),
            .longOnly(.markdown("**What about readings outside the ten?**")),
            .longOnly(.text("A reading that breaks the rasm, or lacks a mass-transmitted chain, is called shaadh, irregular. It may be cited in tafseer as an explanation, but it is not recited as Quran, in prayer or outside it (an-Nawawi, al-Majmoo‘ 3/392). So the differences that someone might point to in a shaadh report do not touch the Quran at all.")),
            .longOnly(.markdown("**May I reject a reading I was not taught?**")),
            .longOnly(.text("No. A reading you did not learn is still Quran, as much as the one you recite, provided it is one of the canonical readings. Denying it is denying part of what Allah revealed, which is why the Prophet called disputing over the Quran disbelief, as quoted above. What you may do is keep to the reading you were taught in your own recitation; no one is obliged to learn all ten.")),
            .longOnly(.markdown("**Why did Uthmaan unite the people on one mushaf, if the readings are all correct?**")),
            .longOnly(.text("Because people who did not know that every reading was revealed had begun to call each other wrong, which is exactly the dispute the Prophet forbade. Hudhayfah (may Allah be pleased with him) saw it among the armies:")),
            .longOnly(.hadith("bukhari:4987", cite: "Saheeh al-Bukhaari 4987", arabic: 41...51, english: [55...71])),
            .longOnly(.text("Uthmaan’s copies did not abolish the readings; they gave every city one agreed rasm that the readings fit inside, and the canonical qiraa’aat were taught from those copies ever after.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Prophet heard different readings and said of each, “Thus it was revealed.” The scholars found that every difference among the canonical readings is one of three kinds: one word said two ways, two true meanings of one thing, or two true meanings of two things. None is a contradiction; each reading stands beside the others as an ayah stands beside an ayah, all of them inside the one rasm the Companions agreed on, and the Quran remains what Allah said it is: a book with no contradiction in it."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Qiraa’ah (قِرَاءَة)**, plural **qiraa’aat**: from **ق-ر-أ**, to recite: one of the canonical ways of reciting the Quran, named after the imam who taught it, such as the qiraa’ah of Aasim."),
            .markdown("**Riwaayah (رِوَايَة)**: from **ر-و-ي**, to transmit: one transmitter’s line of a qiraa’ah, such as Hafs from Aasim or Warsh from Naafi‘."),
            .markdown("**Rasm (رَسم)**: the written skeleton of the Uthmanic mushaf, its letters without later dots and vowels, which every canonical reading must fit."),
            .markdown("**Ikhtilaaf at-tanawwu‘ (اختِلَاف التَّنَوُّع)**: a difference of variety, from **ن-و-ع**, kind: two sayings that are both true and sit together. Every difference between the canonical readings is of this kind."),
            .markdown("**Ikhtilaaf at-tadaadd (اختِلَاف التَّضَادّ)**: a difference of contradiction, from **ض-د-د**, opposite: two sayings of which one must be false. It is not found in the speech of Allah."),
            .markdown("**Mutawaatir (مُتَوَاتِر)**: from **و-ت-ر**, to follow one after another: transmitted by so many, at every stage, that error or collusion is ruled out. The canonical readings are carried this way."),
            .markdown("**Shaadh (شَاذّ)**: from **ش-ذ-ذ**, to stand apart: a reading that fails the conditions of the canonical ones and is not recited as Quran."),
        ]),
    ]
}

struct FarewellView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Farewell Sermon was the Prophet's final address to the Ummah at Arafaat, summarizing the core teachings of Islam for all time.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(verbatim: "The Farewell Sermon (خُطبَةُ ٱلوَدَاعِ), delivered by Prophet Muhammad (peace be upon him), took place on the 9th of Dhu al-Hijjah in the 10th year of Hijrah (632 CE) near Mount Arafaat.")

                        ArticleParagraph(verbatim: "During this momentous occasion, Allah (Glorified and Exalted be He) revealed:")
                        ScriptureQuote(quran: "5:3", words: 39...49)
                    }

                    Section(header: ArticleHeader("TEXT OF THE SERMON")) {
                        ArticleParagraph(verbatim: "The popular “full text” of the Farewell Sermon is a later composite; these are portions of it as they are actually narrated. He (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 783...796, english: 1277...1304)
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 842...874, english: 1389...1469)
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 875...886, english: 1470...1490)
                        ScriptureQuote(text: "“O people, your Lord is one and your father is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red (light-skinned) person over a black person, nor of a black person over a red person, except by taqwa” (Musnad Ahmad 23489; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 2700).", arabic: "يَا أَيُّهَا النَّاسُ، أَلَا إِنَّ رَبَّكُم وَاحِدٌ، وَإِنَّ أَبَاكُم وَاحِدٌ، أَلَا لَا فَضلَ لِعَرَبِيٍّ عَلَى عَجَمِيٍّ، وَلَا لِعَجَمِيٍّ عَلَى عَرَبِيٍّ، وَلَا أَحمَرَ عَلَى أَسوَدَ، وَلَا أَسوَدَ عَلَى أَحمَرَ، إِلَّا بِالتَّقوَى", dimmed: true)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        Text(verbatim: """
                             The Farewell Sermon (خُطبَةُ ٱلوَدَاعِ), delivered by Prophet Muhammad (peace be upon him), took place on the 9th of Dhu al-Hijjah in the 10th year of Hijrah (632 CE) in the Uranah Valley near Mount Arafaat. This sermon is one of the most significant moments in Islamic history, as it encapsulates key teachings and guidance for Muslims.
                             """)
                        .font(.body)

                        ArticleParagraph(verbatim: "During this momentous occasion, Allah (Glorified and Exalted be He) revealed:")
                        ScriptureQuote(quran: "5:3", words: 39...49)
                    }

                    Section(header: ArticleHeader("FINAL DAYS OF THE PROPHET")) {
                        ArticleParagraph(verbatim: "After delivering this sermon, the Prophet (peace be upon him) continued to guide the Muslim Ummah until his passing in Rabee‘ al-Awwal, 11 AH (632 CE); the 12th is the popular date, though the exact day is disputed. He passed away in the home of Aa’ishah (may Allah be pleased with her), his head resting on her lap, and his final words, expressing his longing to meet Allah, were:")
                        ScriptureQuote(hadith: "bukhari:4463", cite: "Saheeh al-Bukhaari 4463", arabic: 63...65, english: 111...116)
                    }

                    Section(header: ArticleHeader("TEXT OF THE SERMON")) {
                        ArticleParagraph(verbatim: "The popular “full text” of the Farewell Sermon is a later composite. Below are its portions as they are actually narrated, each with its source: from Jaabir ibn Abdullah’s account of the Hajj in Saheeh Muslim, from the sermon of the Day of Sacrifice in Saheeh al-Bukhaari, and from the remaining authentic reports. Every line here is saheeh or hasan; lines that circulate as part of the sermon without a chain are not included, even where the words are authentic elsewhere.")

                        ArticleParagraph(verbatim: "He (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 783...796, english: 1277...1304)
                        ScriptureQuote(hadith: "bukhari:1739", cite: "Saheeh al-Bukhaari 1739", arabic: 66...80, english: 67...98)
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 827...841, english: 1360...1388)
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 842...874, english: 1389...1469)
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 875...886, english: 1470...1490)
                        ScriptureQuote(hadith: "tirmidhi:616", cite: "Jaami‘ at-Tirmidhi 616; graded saheeh by al-Albaani", arabic: 38...53, english: 21...57)
                        ScriptureQuote(hadith: "tirmidhi:2159", cite: "Jaami‘ at-Tirmidhi 2159; graded saheeh by al-Albaani", arabic: 72...93, english: 80...112)
                        ScriptureQuote(text: "“O people, your Lord is one and your father is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red (light-skinned) person over a black person, nor of a black person over a red person, except by taqwa” (Musnad Ahmad 23489; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 2700).", arabic: "يَا أَيُّهَا النَّاسُ، أَلَا إِنَّ رَبَّكُم وَاحِدٌ، وَإِنَّ أَبَاكُم وَاحِدٌ، أَلَا لَا فَضلَ لِعَرَبِيٍّ عَلَى عَجَمِيٍّ، وَلَا لِعَجَمِيٍّ عَلَى عَرَبِيٍّ، وَلَا أَحمَرَ عَلَى أَسوَدَ، وَلَا أَسوَدَ عَلَى أَحمَرَ، إِلَّا بِالتَّقوَى", dimmed: true)
                        ScriptureQuote(hadith: "bukhari:1739", cite: "Saheeh al-Bukhaari 1739", arabic: 113...123, text: "“It is incumbent upon those who are present to convey this information to those who are absent Beware don't renegade (as) disbelievers (turn into infidels) after me, Striking the necks (cutting the throats) of one another”")

                        ArticleParagraph(verbatim: "Then he asked them:")
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 888...917, english: 1491...1563)
                        ScriptureQuote(hadith: "bukhari:1739", cite: "Saheeh al-Bukhaari 1739", arabic: 89...94, english: 116...130)
                    }

                    Section(header: ArticleHeader("KEY MESSAGES OF THE SERMON")) {
                        Text(verbatim: """
                             - Sanctity of life, property, and trust.
                             - Abolition of interest (Riba) and unfair practices.
                             - Rights and responsibilities within marriage.
                             - Unity and equality of all humans.
                             - Adherence to the Quran and Sunnah as guidance.
                             """)
                        .font(.body)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("In it the Prophet affirmed the sanctity of life and property, the equality of all people, the rights of women, and clinging to the Quran and Sunnah, delivered as his religion was perfected.")
                }

                ArticleSourcesSection(article: "FarewellView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Farewell Sermon")
        .englishArticle().selectableArticleList(article: "FarewellView")
    }
}

struct SahabahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Sahaabah are the Companions who accompanied the Prophet, believed in him, and carried Islam to the world, the best generation of this Ummah.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "The **Sahaabah (الصَّحَابَة)**, from the root **s-h-b (ص ح ب)**, companionship, are the companions of Prophet Muhammad (peace be upon him).")

                    ArticleParagraph(verbatim: "They supported him in his mission, witnessed the revelation of the Quran, and preserved the teachings of Islam through word and action.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) praised them in the Quran:")
                    ScriptureQuote(quran: "9:100", words: 0...12)

                    ArticleParagraph(verbatim: "And the Prophet (peace be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:2652", cite: "Saheeh al-Bukhaari 2652", arabic: 29...37, english: 4...23)
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ABU BAKR AS-SIDDEEQ")) {
                        ArticleParagraph(verbatim: "Abu Bakr (may Allah be pleased with him) was the Prophet’s (peace be upon him) closest friend and the first adult male to embrace Islam.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:3656", cite: "Saheeh al-Bukhaari 3656", arabic: 27...38, english: 4...26)

                        ArticleParagraph(verbatim: "He was known as As-Siddeeq (the Truthful) for immediately affirming the Prophet’s Night Journey (Israa’ and Mi‘raaj). He was chosen as the first Caliph after the Prophet’s death and led the Muslim Ummah with wisdom and justice.")
                    }

                    Section(header: ArticleHeader("UMAR IBN AL-KHATTAAB")) {
                        ArticleParagraph(verbatim: "Umar (may Allah be pleased with him) was known for his strength, justice, and piety. He was the second Caliph and expanded the Islamic state significantly.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "tirmidhi:3686", cite: "Jaami‘ at-Tirmidhi 3686; graded hasan by al-Albaani, as-Silsilah as-Saheehah 327", arabic: 33...40, english: 7...22)
                    }

                    Section(header: ArticleHeader("UTHMAAN IBN AFFAAN")) {
                        ArticleParagraph(verbatim: "Uthmaan (may Allah be pleased with him) was known for his generosity, modesty, and devotion. He unified the Ummah upon official copies of the already compiled Quran, based on the manuscript first compiled under Abu Bakr.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) climbed Mount Uhud with Abu Bakr, Umar, and Uthmaan, and when it shook beneath them he said:")
                        ScriptureQuote(hadith: "bukhari:3675", cite: "Saheeh al-Bukhaari 3675", arabic: 37...43, english: 27...45)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ABU BAKR AS-SIDDEEQ")) {
                        ArticleParagraph(verbatim: "Abu Bakr (may Allah be pleased with him) was the Prophet’s (peace be upon him) closest friend and the first adult male to embrace Islam.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:3656", cite: "Saheeh al-Bukhaari 3656", arabic: 27...38, english: 4...26)

                        ArticleParagraph(verbatim: "He was known as As-Siddeeq (the Truthful) for immediately affirming the Prophet’s Night Journey (Israa’ and Mi‘raaj). He was chosen as the first Caliph after the Prophet’s death and led the Muslim Ummah with wisdom and justice.")

                        ArticleParagraph(verbatim: "About one year after the Prophet’s passing, he commissioned Zayd ibn Thaabit to compile the Quran into a single manuscript, preserving the revelation in written form alongside mass memorization.")
                    }

                    Section(header: ArticleHeader("UMAR IBN AL-KHATTAAB")) {
                        ArticleParagraph(verbatim: "Umar (may Allah be pleased with him) was known for his strength, justice, and piety. He was the second Caliph and expanded the Islamic state significantly.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "tirmidhi:3686", cite: "Jaami‘ at-Tirmidhi 3686; graded hasan by al-Albaani, as-Silsilah as-Saheehah 327", arabic: 33...40, english: 7...22)

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) revealed verses agreeing with Umar’s opinions, including the veiling of the Prophet's wives (Saheeh al-Bukhaari 402) and the prohibition of alcohol (Sunan Abi Daawood 3670; graded saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "bukhari:402", cite: "Saheeh al-Bukhaari 402", arabic: 14...51, english: 0...111)
                        ScriptureQuote(hadith: "abudawud:3670", cite: "Sunan Abi Daawood 3670; graded saheeh by al-Albaani", arabic: 24...121, english: 0...143)
                    }

                    Section(header: ArticleHeader("UTHMAAN IBN AFFAAN")) {
                        ArticleParagraph(verbatim: "Uthmaan (may Allah be pleased with him) was known for his generosity, modesty, and devotion. He unified the Ummah upon official copies of the already compiled Quran, based on the manuscript first compiled under Abu Bakr.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) climbed Mount Uhud with Abu Bakr, Umar, and Uthmaan, and when it shook beneath them he said:")
                        ScriptureQuote(hadith: "bukhari:3675", cite: "Saheeh al-Bukhaari 3675", arabic: 37...43, english: 27...45)

                        ArticleParagraph(verbatim: "He bought the well of Roomah for the Muslims, funded the expansion of Al-Masjid an-Nabawi, and equipped the army of Tabook (Saheeh al-Bukhaari 2778 for the well and the army; Sunan an-Nasaa’i 3608 for the mosque, graded saheeh by al-Albaani). His contributions earned him repeated praise from the Prophet (peace be upon him).")
                        ScriptureQuote(hadith: "bukhari:2778", cite: "Saheeh al-Bukhaari 2778", arabic: 13...69, english: 0...84)
                        ScriptureQuote(hadith: "nasai:3608", cite: "Sunan an-Nasaa’i 3608; graded saheeh by al-Albaani", arabic: 115...156, english: 162...229)
                    }
                }

                Section(header: ArticleHeader("ALI IBN ABI TAALIB")) {
                    ArticleParagraph(verbatim: "Ali (may Allah be pleased with him) was the cousin and son-in-law of the Prophet (peace be upon him). He was a scholar, warrior, and deeply spiritual leader.")

                    ArticleParagraph(verbatim: "The Prophet (peace be upon him) said to him:")
                    ScriptureQuote(hadith: "muslim:2404a", cite: "Saheeh Muslim 2404", arabic: 58...68, english: 0...29)

                    ArticleParagraph(verbatim: "He was among the most learned of the Companions, and many later scholars traced their knowledge back to him. He was known for his eloquence, bravery, and deep understanding of Islam.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("MUHAAJIREEN & ANSAAR")) {
                        ArticleParagraph(verbatim: "The Muhaajireen were those who emigrated with the Prophet (peace be upon him) from Makkah to Madinah, leaving behind their wealth and homes for the sake of Allah.")

                        ArticleParagraph(verbatim: "The Ansaar were the residents of Madinah who welcomed the Prophet (peace be upon him) and his followers with open hearts and supported them in every way.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) praised them both:")
                        ScriptureQuote(quran: "59:9", words: 0...19)
                    }

                    Section(header: ArticleHeader("LEGACY")) {
                        ArticleParagraph(verbatim: "The Sahaabah preserved the Quran and Hadith, established justice and governance, and exemplified the moral and ethical teachings of Islam.")

                        ArticleParagraph(verbatim: "Their legacy continues to inspire faith, sacrifice, knowledge, and courage in Muslims to this day.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Allah praised the Companions and was pleased with them. Through them the Quran and Sunnah were preserved and conveyed, and honoring them is part of the faith.")
                }

                ArticleSourcesSection(article: "SahabahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Sahaabah")
        .englishArticle().selectableArticleList(article: "SahabahView")
    }
}

struct WivesView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the wives of the Prophet are the “Mothers of the Believers,” honored for their faith, and several became key teachers of Islam.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(verbatim: "The wives of Prophet Muhammad (peace be upon him) are honored in Islam as the “Mothers of the Believers” (أُمَّهَاتُ المُؤمِنِين).")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                        ScriptureQuote(quran: "33:6", words: 0...6)

                        ArticleParagraph(articleMarkdown: "Prophet Muhammad (peace be upon him) married a total of **11 women** throughout his lifetime. At one time, he was married to a maximum of **9 wives** simultaneously: the limit of four that Allah set for his Ummah did not bind him, a ruling particular to him within this Ummah.")
                    }

                    Section(header: ArticleHeader("SUPPORT & CONTRIBUTION")) {
                        ArticleParagraph(articleMarkdown: "Most of his wives were **widows or divorcees**. These marriages were not driven by desire but by **wisdom, compassion, and community building**.")

                        ArticleParagraph(articleMarkdown: "His marriage to **Khadeejah bint Khuwaylid** (may Allah be pleased with her) was monogamous and lasted about 25 years, until her death. She was about 15 years older than him, and he took no other wife during her lifetime.")
                    }

                    Section(header: ArticleHeader("KHADEEJAH")) {
                        ArticleParagraph(articleMarkdown: "Khadeejah bint Khuwaylid (may Allah be pleased with her) was the first person to believe in Prophet Muhammad (peace be upon him) and thus the **first Muslim**. After his first revelation in the cave of Hira, she comforted him, wrapped him in a cloak, and reassured him with her deep insight and love.")

                        ArticleParagraph(verbatim: "She said:")
                        ScriptureQuote(hadith: "bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 186...204, english: 314...346)
                    }

                    Section(header: ArticleHeader("AA’ISHAH")) {
                        ArticleParagraph(verbatim: "Aa’ishah bint Abi Bakr (may Allah be pleased with her) was the daughter of Abu Bakr as-Siddeeq (may Allah be pleased with him), the closest companion of the Prophet (peace be upon him). She was among the most knowledgeable of the Companions, especially in Hadith and Islamic jurisprudence, and the Companions would turn to her when a matter was difficult for them.")

                        Text(articleMarkdown: "She was falsely accused in the incident of al-Ifk, but Allah (Glorified and Exalted be He) revealed her innocence in **Surah An-Noor (24:11–26)**, establishing her purity and honor for all time.")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                        ScriptureQuote(quran: "24:26", words: 8...15)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(verbatim: "The wives of Prophet Muhammad (peace be upon him) are honored in Islam as the “Mothers of the Believers” (أُمَّهَاتُ المُؤمِنِين).")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")

                        ScriptureQuote(quran: "33:6", words: 0...6)

                        ArticleParagraph(articleMarkdown: "Prophet Muhammad (peace be upon him) married a total of **11 women** throughout his lifetime. At one time, he was married to a maximum of **9 wives** simultaneously: the limit of four that Allah set for his Ummah (Quran 4:3) did not bind him, a ruling particular to him within this Ummah. Earlier prophets also had more than four wives under the laws given to them: Prophet Solomon (peace be upon him) said he would go round to a hundred of his wives in one night (Saheeh al-Bukhaari 5242).")
                        ScriptureQuote(quran: "4:3", words: 6...14)
                        ScriptureQuote(hadith: "bukhari:5242", cite: "Saheeh al-Bukhaari 5242, Saheeh Muslim 1654", arabic: 17...55, english: 0...81)
                    }

                    Section(header: ArticleHeader("SUPPORT & CONTRIBUTION")) {
                        ArticleParagraph(verbatim: "These women supported the Prophet (peace be upon him) in his mission.")

                        ArticleParagraph(verbatim: "They played vital roles in educating the Muslim community, transmitting Hadith, and exemplifying piety and devotion.")

                        ArticleParagraph(articleMarkdown: "Most of his wives were **widows or divorcees**. These marriages were not driven by desire but by **wisdom, compassion, and community building**.")

                        ArticleParagraph(articleMarkdown: "His marriage to **Khadeejah bint Khuwaylid** (may Allah be pleased with her) was monogamous and lasted about 25 years, until her death. She was about 15 years older than him, and he took no other wife during her lifetime.")
                    }

                    Section(header: ArticleHeader("KHADEEJAH")) {
                        ArticleParagraph(articleMarkdown: "Khadeejah bint Khuwaylid (may Allah be pleased with her) was the first person to believe in Prophet Muhammad (peace be upon him) and thus the **first Muslim**. After his first revelation in the cave of Hira, she comforted him, wrapped him in a cloak, and reassured him with her deep insight and love.")

                        ArticleParagraph(verbatim: "She said:")
                        ScriptureQuote(hadith: "bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 186...204, english: 314...346)

                        Text(articleMarkdown: "Allah (Glorified and Exalted be He) affirmed the beginning of the Prophet’s (peace be upon him) mission in **Surah Al-Muzzammil (73:1)** and **Surah Al-Muddaththir (74:1)**, moments when Khadeejah (may Allah be pleased with her) lovingly wrapped and comforted him.")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                        ScriptureQuote(quran: "73:1")
                        ScriptureQuote(quran: "74:1")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said of her:")
                        ScriptureQuote(hadith: "bukhari:3818", cite: "Saheeh al-Bukhaari 3818", arabic: 71...77, english: 84...92)
                        ArticleParagraph(verbatim: "Aa’ishah (may Allah be pleased with her) reported that he said:")
                        ScriptureQuote(hadith: "muslim:2435b", cite: "Saheeh Muslim 2435", arabic: 66...69, english: 69...79)
                    }

                    Section(header: ArticleHeader("AA’ISHAH")) {
                        ArticleParagraph(verbatim: "Aa’ishah bint Abi Bakr (may Allah be pleased with her) was the daughter of Abu Bakr as-Siddeeq (may Allah be pleased with him), the closest companion of the Prophet (peace be upon him). She was among the most knowledgeable of the Companions, especially in Hadith and Islamic jurisprudence, and the Companions would turn to her when a matter was difficult for them.")

                        Text(articleMarkdown: "She was falsely accused in the incident of al-Ifk, but Allah (Glorified and Exalted be He) revealed her innocence in **Surah An-Noor (24:11–26)**, establishing her purity and honor for all time.")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                        ScriptureQuote(quran: "24:26", words: 8...15)

                        ArticleParagraph(verbatim: "Amr ibn al-As (may Allah be pleased with him) asked the Prophet (peace be upon him):")
                        ScriptureQuote(hadith: "bukhari:3662", cite: "Saheeh al-Bukhaari 3662", arabic: 39...52, english: 17...37)

                        ArticleParagraph(verbatim: "He also said:")
                        ScriptureQuote(hadith: "muslim:2446a", cite: "Saheeh Muslim 2446", arabic: 35...43, english: 0...15)

                        ArticleParagraph(verbatim: "After the Prophet’s (peace be upon him) death, she became one of the greatest scholars of Islam. She taught both men and women and was a source of religious rulings and interpretations.")

                        ArticleParagraph(articleMarkdown: "She narrated **2,210 hadiths**, making her the **fourth-highest hadith narrator** of all time. Most of these relate to the Prophet’s private life, which only she had access to. Without Aa’ishah (may Allah be pleased with her), much of the Prophet’s (peace be upon him) household life, worship, and character would not be known today.")
                    }

                    Section(header: ArticleHeader("HOW HE TREATED HIS WIVES")) {
                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) was the best example of kindness, patience, and love toward his wives. These hadiths reflect his character:")

                        ScriptureQuote(hadith: "tirmidhi:3895", cite: "Jaami‘ at-Tirmidhi 3895; graded saheeh by al-Albaani", arabic: 30...35, english: 7...34)

                        ArticleParagraph(verbatim: "Aa’ishah (may Allah be pleased with her) said:")
                        ScriptureQuote(hadith: "muslim:2328a", cite: "Saheeh Muslim 2328", arabic: 13...27, english: 3...17)

                        ArticleParagraph(verbatim: "He said:")
                        ScriptureQuote(hadith: "muslim:1468b", cite: "Saheeh Muslim 1468", arabic: 38...48, english: 0...21)

                        ArticleParagraph(verbatim: "And Aa’ishah (may Allah be pleased with her) said of his life at home:")
                        ScriptureQuote(hadith: "bukhari:6039", cite: "Saheeh al-Bukhaari 6039", arabic: 26...35, english: 15...37)
                    }

                    Section(header: ArticleHeader("THE ELEVEN WIVES")) {
                        Group {
                            ArticleBullet(verbatim: "• Khadeejah bint Khuwaylid (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Sawdah bint Zam‘ah (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Aa’ishah bint Abi Bakr (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Hafsah bint Umar (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Zaynab bint Khuzaymah (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Umm Salamah (Hind bint Abi Umayyah) (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Zaynab bint Jahsh (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Juwayriyah bint al-Haarith (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Umm Habeebah (Ramlah bint Abi Sufyaan) (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Safiyyah bint Huyayy (may Allah be pleased with her)")
                            ArticleBullet(verbatim: "• Maymoonah bint al-Haarith (may Allah be pleased with her)")
                        }
                        .font(.body)
                    }
                }

                Section(header: ArticleHeader("WHY SO MANY MARRIAGES?")) {
                    ArticleParagraph(verbatim: "These marriages fulfilled many noble purposes:")

                    ArticleBullet("• **Supporting widows** who lost husbands in early battles.")

                    ArticleBullet("• **Forming alliances** with key tribes to strengthen the Muslim community.")

                    ArticleBullet("• **Spreading Islamic knowledge**, as many of his wives became teachers and Hadith narrators.")

                    ArticleBullet("• **Setting legal and social precedents** for Muslim family law and ethics.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("LEGACY")) {
                        ArticleParagraph(verbatim: "The lives of the Prophet’s (peace be upon him) wives highlight the essential role of women in Islamic scholarship and community-building.")

                        ArticleParagraph(verbatim: "They are role models for Muslims, inspiring faith, resilience, and devotion.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Through the Prophet's wives, especially Aa’ishah, much of the Sunnah of the home and worship reached the Ummah; loving and respecting them is part of the religion.")
                }

                ArticleSourcesSection(article: "WivesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Wives")
        .englishArticle().selectableArticleList(article: "WivesView")
    }
}

struct CaliphatesView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Caliphate is the leadership that continued the Prophet's mission, beginning with the Rightly Guided Caliphs Abu Bakr, Umar, Uthmaan, and Ali.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "The **Caliphate (الخِلَافَة)**, from the root **kh-l-f (خ ل ف)**, meaning succession, refers to the divinely guided system of governance established after the death of Prophet Muhammad (peace be upon him). It aimed to continue his mission of upholding justice, spreading Islam, and preserving the unity of the Ummah.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "abudawud:4646", cite: "Sunan Abi Daawood 4646; graded hasan saheeh by al-Albaani", arabic: 26...39, english: 4...24)

                        ArticleParagraph(articleMarkdown: "These thirty years, known as the **Raashidoon Caliphate**, represented the ideal Islamic system. The caliphs were chosen by **consultation (شُورَىٰ)** and the pledge of allegiance (**bay‘ah, بَيعَة**) of the community. This model emphasized justice, humility, accountability, and service to the people.")
                    }

                    Section(header: ArticleHeader("ABU BAKR AS-SIDDEEQ (632–634 CE)")) {
                        ArticleParagraph(articleMarkdown: "Abu Bakr (may Allah be pleased with him), the Prophet’s closest companion and the first adult male to accept Islam, was chosen as the **first caliph** immediately after the Prophet’s passing. He was selected through consensus at Saqeefah.")

                        ArticleParagraph(articleMarkdown: "He led decisively during a time of crisis, launching the **Riddah Wars** to bring back apostate tribes and false prophets. About one year after the Prophet’s death (12 AH), he initiated the first complete compilation of the Quran into a single manuscript.")
                    }

                    Section(header: ArticleHeader("UMAR IBN AL-KHATTAAB (634–644 CE)")) {
                        ArticleParagraph(verbatim: "Umar (may Allah be pleased with him) was appointed by Abu Bakr before his death and accepted by the Muslims as the second caliph. He was renowned for justice, strength, and fear of Allah (Glorified and Exalted be He).")

                        ArticleParagraph(articleMarkdown: "His 10-year reign witnessed the rapid expansion of Islam into the **Byzantine and Persian Empires**, including Jerusalem and Egypt. He established **public registers**, **courts**, **salaries for soldiers**, and the **Islamic calendar**.")
                    }

                    Section(header: ArticleHeader("UTHMAAN IBN AFFAAN (644–656 CE)")) {
                        ArticleParagraph(articleMarkdown: "Uthmaan (may Allah be pleased with him) was chosen through a **council of six** appointed by Umar. Known for his generosity and modesty, he married two daughters of the Prophet Muhammad (peace be upon him) and was called **Dhu an-Noorayn** (ذُو ٱلنُّورَين, the Possessor of Two Lights).")

                        ArticleParagraph(articleMarkdown: "He **standardized official copies of the Quran** from the already compiled manuscript preserved from Abu Bakr’s time, unifying public recitation and preventing disputes over unverified personal materials. He sent official copies to major cities and retired non-verified personal codices used outside official transmission.")
                    }

                    Section(header: ArticleHeader("ALI IBN ABI TAALIB (656–661 CE)")) {
                        ArticleParagraph(verbatim: "Ali (may Allah be pleased with him), the cousin and son-in-law of the Prophet Muhammad (peace be upon him), was chosen as the fourth caliph after Uthmaan’s martyrdom.")

                        ArticleParagraph(articleMarkdown: "His caliphate was challenged by internal strife, including the **Battle of the Camel** and **Battle of Siffeen**. Despite the trials, he remained committed to justice and truth.")
                    }

                    Section(header: ArticleHeader("LEGACY OF THE RAASHIDOON")) {
                        ArticleParagraph(articleMarkdown: "Though later caliphates transitioned into **hereditary monarchy**, the Prophet Muhammad (peace be upon him) had foretold this change in the hadith quoted above: thirty years of the caliphate of prophethood, and then kingship given to whomever Allah wills (Sunan Abi Daawood 4646). Safeenah (may Allah be pleased with him), who narrated it, counted them: two years for Abu Bakr, ten for Umar, twelve for Uthmaan, and the remainder for Ali.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "The **Caliphate (الخِلَافَة)**, from the root **kh-l-f (خ ل ف)**, meaning succession, refers to the divinely guided system of governance established after the death of Prophet Muhammad (peace be upon him). It aimed to continue his mission of upholding justice, spreading Islam, and preserving the unity of the Ummah.")

                        ArticleParagraph(articleMarkdown: "The Caliph (خَلِيفَة), literally “successor,” was entrusted with political, military, judicial, and spiritual leadership, guided by the Quran and Sunnah. The first four caliphs, known as the **Rightly Guided Caliphs (ٱلخُلَفَاء ٱلرَّاشِدُون)**, are regarded as models of righteous rule.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "abudawud:4646", cite: "Sunan Abi Daawood 4646; graded hasan saheeh by al-Albaani", arabic: 26...39, english: 4...24)

                        ArticleParagraph(articleMarkdown: "These thirty years, known as the **Raashidoon Caliphate**, represented the ideal Islamic system. The caliphs were chosen by **consultation (شُورَىٰ)** and the pledge of allegiance (**bay‘ah, بَيعَة**) of the community: Abu Bakr at Saqeefah and then in the mosque, and Uthmaan after Abd ar-Rahman ibn Awf consulted the Muhaajiroon, the Ansaar, and the commanders for three nights (Saheeh al-Bukhaari 7207). This model emphasized justice, humility, accountability, and service to the people.")
                        ScriptureQuote(hadith: "bukhari:7207", cite: "Saheeh al-Bukhaari 7207", arabic: 160...231, english: 263...423)
                    }

                    Section(header: ArticleHeader("ABU BAKR AS-SIDDEEQ (632–634 CE)")) {
                        ArticleParagraph(articleMarkdown: "Abu Bakr (may Allah be pleased with him), the Prophet’s closest companion and the first adult male to accept Islam, was chosen as the **first caliph** immediately after the Prophet’s passing. He was selected through consensus at Saqeefah.")

                        ArticleParagraph(articleMarkdown: "He led decisively during a time of crisis, launching the **Riddah Wars** to bring back apostate tribes and false prophets. About one year after the Prophet’s death (12 AH), he initiated the first complete compilation of the Quran into a single manuscript.")

                        ArticleParagraph(verbatim: "When some of the Companions were harsh with him, the Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:3661", cite: "Saheeh al-Bukhaari 3661", arabic: 146...163, english: [174...209, 214...221])

                        ArticleParagraph(verbatim: "His caliphate lasted just over two years but laid the foundation for unity and stability in the Ummah.")
                    }

                    Section(header: ArticleHeader("UMAR IBN AL-KHATTAAB (634–644 CE)")) {
                        ArticleParagraph(verbatim: "Umar (may Allah be pleased with him) was appointed by Abu Bakr before his death and accepted by the Muslims as the second caliph. He was renowned for justice, strength, and fear of Allah (Glorified and Exalted be He).")

                        ArticleParagraph(articleMarkdown: "His 10-year reign witnessed the rapid expansion of Islam into the **Byzantine and Persian Empires**, including Jerusalem and Egypt. He established **public registers**, **courts**, **salaries for soldiers**, and the **Islamic calendar**.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "tirmidhi:3682", cite: "Jaami‘ at-Tirmidhi 3682; graded saheeh by al-Albaani", arabic: 30...37, english: 10...24)

                        ArticleParagraph(verbatim: "He was assassinated while praying in the masjid and is buried beside the Prophet Muhammad (peace be upon him).")
                    }

                    Section(header: ArticleHeader("UTHMAAN IBN AFFAAN (644–656 CE)")) {
                        ArticleParagraph(articleMarkdown: "Uthmaan (may Allah be pleased with him) was chosen through a **council of six** appointed by Umar. Known for his generosity and modesty, he married two daughters of the Prophet Muhammad (peace be upon him) and was called **Dhu an-Noorayn** (ذُو ٱلنُّورَين, the Possessor of Two Lights).")

                        ArticleParagraph(articleMarkdown: "He **standardized official copies of the Quran** from the already compiled manuscript preserved from Abu Bakr’s time, unifying public recitation and preventing disputes over unverified personal materials. He sent official copies to major cities and retired non-verified personal codices used outside official transmission.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said of him:")
                        ScriptureQuote(hadith: "muslim:2401", cite: "Saheeh Muslim 2401", arabic: 128...134, english: 155...167)

                        ArticleParagraph(verbatim: "Due to political unrest and false accusations, he was unjustly besieged and martyred while reciting the Quran.")
                    }

                    Section(header: ArticleHeader("ALI IBN ABI TAALIB (656–661 CE)")) {
                        ArticleParagraph(verbatim: "Ali (may Allah be pleased with him), the cousin and son-in-law of the Prophet Muhammad (peace be upon him), was chosen as the fourth caliph after Uthmaan’s martyrdom.")

                        ArticleParagraph(articleMarkdown: "His caliphate was challenged by internal strife, including the **Battle of the Camel** and **Battle of Siffeen**. Despite the trials, he remained committed to justice and truth.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said to him:")
                        ScriptureQuote(hadith: "muslim:2404a", cite: "Saheeh Muslim 2404", arabic: 58...68, english: 0...29)

                        ArticleParagraph(verbatim: "Ali was struck by Ibn Muljam in Koofah on his way to lead the Fajr prayer, in Ramadan 40 AH, and died of the wound. His legacy lives on in scholarship, courage, and moral leadership.")
                    }

                    Section(header: ArticleHeader("LEGACY OF THE RAASHIDOON")) {
                        ArticleParagraph(articleMarkdown: "The Raashidoon Caliphs (632–661 CE) ruled with unmatched integrity, transparency, and adherence to prophetic tradition. Their rule was guided by **shoora (شُورَىٰ)**, justice, and humility.")

                        ArticleParagraph(articleMarkdown: "Though later caliphates transitioned into **hereditary monarchy**, the Prophet Muhammad (peace be upon him) had foretold this change in the hadith quoted above: thirty years of the caliphate of prophethood, and then kingship given to whomever Allah wills (Sunan Abi Daawood 4646). Safeenah (may Allah be pleased with him), who narrated it, counted them: two years for Abu Bakr, ten for Umar, twelve for Uthmaan, and the remainder for Ali.")

                        ArticleParagraph(verbatim: "Despite this shift, many later caliphs still contributed greatly to Islamic knowledge, architecture, and global influence.")
                    }

                    Section(header: ArticleHeader("THE UMAYYAD CALIPHATE (661–750 CE)")) {
                        ArticleParagraph(articleMarkdown: "The Umayyads, beginning with Mu‘aawiyah ibn Abi Sufyaan (may Allah be pleased with him), transitioned the caliphate into a **dynastic monarchy**. Their capital was **Damascus (دِمَشق)**.")

                        ArticleParagraph(articleMarkdown: "They expanded Islam into **al-Andalus (Spain)**, **North Africa**, and **Central Asia**, and made **Arabic** the official administrative language.")

                        ArticleParagraph(verbatim: "Though less spiritually exemplary than the Raashidoon, the Umayyads left a profound legacy in governance, culture, and infrastructure.")
                    }

                    Section(header: ArticleHeader("THE ABBASID CALIPHATE (750–1258 CE)")) {
                        ArticleParagraph(articleMarkdown: "The Abbasids overthrew the Umayyads and moved the capital to **Baghdaad (بَغدَاد)**, initiating the **Golden Age of Islam**.")

                        ArticleParagraph(articleMarkdown: "They supported **translation**, **science**, **mathematics**, **medicine**, and **philosophy**, and established the renowned **Bayt al-Hikmah (بَيت ٱلحِكمَة, House of Wisdom)**. The same translations also carried Greek philosophy into Muslim thought, and under al-Ma’moon the Mu‘tazili doctrine built on it, that the Quran is created, was imposed by force in the Mihnah, against which Imam Ahmad stood firm; the scholars of the Sunnah warned against taking creed from philosophy.")

                        ArticleParagraph(verbatim: "Although internal divisions weakened the state, their intellectual contributions influenced both the Muslim world and Europe. The empire fell to the Mongols in 1258 CE.")
                    }

                    Section(header: ArticleHeader("THE OTTOMAN CALIPHATE (1517–1924 CE)")) {
                        ArticleParagraph(articleMarkdown: "The Ottomans, a Turkish dynasty, were the **first non-Arab dynasty** to hold the widely recognised caliphate. After the fall of the Abbasids in Egypt, the caliphate passed to the Ottomans, whose capital was **Istanbul (إِسطَنبُول)**.")

                        ArticleParagraph(articleMarkdown: "They ruled a vast empire across **Europe**, **Asia**, and **Africa**, preserved **Islamic law (ٱلشَّرِيعَة)**, and defended the **Two Holy Mosques** in **Makkah (مَكَّة)** and **Madinah (ٱلمَدِينَة)**.")

                        ArticleParagraph(articleMarkdown: "The Ottoman Caliphate was officially **abolished in 1924 CE** by Mustafa Kemal Atatürk, ending nearly 1,300 years of Islamic caliphal leadership.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The Rightly Guided Caliphs are the model of just Islamic governance: preserving the Quran, spreading the faith, and upholding the unity of the Ummah.")
                }

                ArticleSourcesSection(article: "CaliphatesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Caliphates")
        .englishArticle().selectableArticleList(article: "CaliphatesView")
    }
}

struct MadhabView: View {
    static let sections1: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the four madhaahib (Hanafi, Maaliki, Shaafi‘i, and Hanbali) are the accepted schools of fiqh, the practical rulings of Islam, where more than one opinion can be valid. They differ in fiqh and are one in aqeedah."),
        ]),
        ArticleSection("OVERVIEW", [
            .markdown("A **madhhab (مَذهَب)** is a school of Islamic jurisprudence that provides structured guidance on how to derive and apply rulings from the Quran and Sunnah. The plural is **madhaahib (مَذَاهِب)**."),
            .text("Madhaahib developed as scholars preserved and codified fiqh (فِقه), or Islamic legal reasoning/jurisprudence, to help Muslims navigate daily life, worship, transactions, and society with clarity and consistency."),
            .text("Following a madhhab ensures one is following a valid, peer-reviewed methodology developed by righteous scholars deeply rooted in the Quran, Sunnah, consensus (إِجمَاع), and analogy (قِيَاس). It is not blind following; it is trust in generations of qualified scholarship. Allah (Glorified and Exalted be He) commands the one who does not know to ask those who do:"),
            .ayah("16:43", words: 8...14),
            .text("And the Prophet Muhammad (peace be upon him) said:"),
            .hadith("bukhari:71", cite: "Saheeh al-Bukhaari 71, Saheeh Muslim 1037", arabic: 32...39, english: [6...20]),
        ]),
        ArticleSection("FIQH IS NOT AQEEDAH", [
            .markdown("**Fiqh (فِقه)** means “understanding”: the practical rulings of Islam, how to pray, fast, trade, marry, and inherit, derived from the Quran and Sunnah by qualified effort (**ijtihaad**). **Aqeedah (عَقِيدَة)**, from “to tie a knot,” is what the heart is bound to: belief about Allah, His angels, books, messengers, the Last Day, and the decree. The madhaahib are schools of **fiqh**. There are no “four schools” of aqeedah, because aqeedah is one (see “The Madhaahib of Aqeedah”)."),
            .text("In fiqh more than one answer can be valid, and the Companions (may Allah be pleased with them) themselves differed in it in the Prophet’s own presence. After the Battle of the Trench he said:"),
            .hadith("bukhari:946", cite: "Saheeh al-Bukhaari 946", arabic: 16...66, english: [16...93]),
            .text("One group held to the literal words and prayed late; the other understood the intent and prayed on time. Both reasoned sincerely from his command, and he approved both. This is the root of every difference between the madhaahib: the same texts, read by sincere scholars, sometimes yield more than one acceptable ruling."),
            .text("Aqeedah admits no such range. Abu Bakr, Umar, Uthmaan, Ali, the Ahlul Bayt, and every Companion believed exactly the same things about Allah, and so did every prophet before them; the Prophet (peace be upon him) said the prophets’ “religion is one” (Saheeh al-Bukhaari 3443). So a Muslim may be Hanafi or Maaliki in fiqh, but in creed there is only the creed of the Salaf."),
            .hadith("bukhari:3443", cite: "Saheeh al-Bukhaari 3443, Saheeh Muslim 2365", arabic: 31...46, english: [4...39]),
        ]),
        ArticleSection("WHY FOLLOW A MADHHAB?", [
            .text("Islamic rulings are not always black and white. Scholars developed principles to interpret revelation when texts appeared to conflict or were not explicit."),
            .text("For example, rulings on prayer times, purification, zakaah calculation, marriage, and contracts all require detailed interpretation. Madhaahib systematize this process based on authentic sources and established rules."),
            .markdown("Instead of picking rulings randomly or following desire, a madhhab offers **structured, principled, and scholarly guidance**. It helps prevent inconsistency and distortion in religious practice."),
        ]),
    ]

    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections1)
                Section(header: ArticleHeader("THE FOUR SUNNI MADHAAHIB")) {
                    imamEntry(
                        number: 1,
                        name: "Imam Abu Haneefah (may Allah have mercy on him)",
                        arabic: "أَبُو حَنِيفَة",
                        meta: "Hanafi (الحَنَفِي) · Koofah, Iraq (الكُوفَة، العِرَاق) · 80–150 AH / 699–767 CE",
                        description: "The Imam of Koofah and founder of the Hanafi school. Known for his mastery of fiqh, ijtihaad, and qiyaas (قِيَاس, from ق-ي-س, to measure one thing against another: analogical reasoning) and for his rigorous legal methodology. It is the most followed madhhab today, especially in South Asia, Turkey, Central Asia, and the Balkans."
                    )

                    imamEntry(
                        number: 2,
                        name: "Imam Maalik ibn Anas (may Allah have mercy on him)",
                        arabic: "مَالِكُ بنُ أَنَسٍ",
                        meta: "Maaliki (المَالِكِي) · Madinah (المَدِينَة) · 93–179 AH / 711–795 CE",
                        description: "The Imam of Madinah and compiler of Al-Muwatta (المُوَطَّأ), renowned for preserving the Sunnah and the practice of the people of Madinah (عَمَل أَهل المَدِينَة). His school is dominant across North and West Africa."
                    )

                    imamEntry(
                        number: 3,
                        name: "Imam Muhammad ibn Idrees ash-Shaafi‘i (may Allah have mercy on him)",
                        arabic: "الشَّافِعِي",
                        meta: "Shaafi‘i (الشَّافِعِي) · Egypt (مِصر) · 150–204 AH / 767–820 CE",
                        description: "The Imam who systematized the principles of Islamic jurisprudence, usool al-fiqh (أُصُول الفِقه). Born in Gaza, he studied in Makkah and Madinah and later in Iraq, and shaped his final madhhab in Egypt, where it took its lasting form. Popular in East Africa, Indonesia, Malaysia, and parts of Egypt and Yemen."
                    )

                    imamEntry(
                        number: 4,
                        name: "Imam Ahmad ibn Hanbal (may Allah have mercy on him)",
                        arabic: "أَحمَدُ بنُ حَنبَلٍ",
                        meta: "Hanbali (الحَنبَلِي) · Baghdaad (بَغدَاد) · 164–241 AH / 780–855 CE",
                        description: "The Imam of Ahl al-Hadith (أَهل الحَدِيث), renowned for his steadfastness during the Mihnah (المِحنَة, the Inquisition) and his firm adherence to the Quran and Sunnah, using analogy only when necessary. Mainly followed in Saudi Arabia and the Gulf."
                    )
                }

                ArticleSectionsView(sections: Self.sections2)

                ArticleSourcesSection(article: "MadhabView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Madhaahib of Fiqh")
        .englishArticle().selectableArticleList(article: "MadhabView")
    }

    /// One imam's entry: a bold name (with the Arabic name), a secondary line of school / region / dates, and a
    /// short description.
    private func imamEntry(number: Int, name: String, arabic: String, meta: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("**\(number). \(name)**, \(arabic)")
                .font(.body)

            Text(meta)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(description)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    static let sections2: [ArticleSection] = [
        ArticleSection("WHEN THE MADHAAHIB TOOK SHAPE", only: .long, [
            .text("None of the four imams formally founded an institution. Each taught a methodology that his students preserved and systematized into a school over the generations, so historians distinguish between the life of the imam and the emergence of the madhhab."),
            .text("The Hanafi school began in Koofah during Abu Haneefah’s lifetime and was firmly established by his students Abu Yoosuf (d. 182 AH) and Muhammad ash-Shaybaani (d. 189 AH). The Maaliki school developed in Madinah through Imam Maalik’s teaching circle and Al-Muwatta. The Shaafi‘i school crystallized in Egypt in Imam ash-Shaafi‘i’s final years (his “new” madhhab) and spread after him through students like al-Muzani and al-Buwayti. The Hanbali school was collected and systematized after Imam Ahmad’s death by his sons and students such as al-Khallaal."),
            .text("The four imams form an unbroken chain of teacher and student: Imam Maalik taught ash-Shaafi‘i, who in turn taught Ahmad ibn Hanbal. Imam Maalik was also a contemporary of Abu Haneefah, and ash-Shaafi‘i was born in the very year Abu Haneefah passed away (150 AH)."),
            .isnad("Where the four imams learned. In Koofah, from Abdullah ibn Mas‘ood through Alqamah ibn Qays, Ibraaheem an-Nakha‘i and Hammaad ibn Abi Sulaymaan to Abu Haneefah, and on to his students Abu Yoosuf and Muhammad ash-Shaybaani. In Madinah, from Abdullah ibn Umar through Naafi‘ to Maalik, his student ash-Shaafi‘i, and ash-Shaafi‘i’s student Ahmad ibn Hanbal. Each imam had many teachers; these are the best known roads, and they crossed: ash-Shaafi‘i also studied in Iraq with Muhammad ash-Shaybaani.", .madhhabImams),
        ]),
        ArticleSection("UNITY THROUGH DIVERSITY", [
            .text("All four madhaahib are valid and respected paths within Ahl as-Sunnah wa al-Jamaa‘ah (أَهل السُّنَّة وَالجَمَاعَة). Though they may differ in legal rulings, they are united in the same ‘aqeedah (عَقِيدَة), the core beliefs regarding Allah, His names and attributes, prophethood, the Quran, the unseen, and the Afterlife."),
            .text("This shared creed is why they are all considered part of Ahl as-Sunnah wa al-Jamaa‘ah. The differences among them are in jurisprudence (fiqh), not faith (‘aqeedah), and reflect the depth and mercy of Islamic legal tradition."),
            .text("No single school is “more Islamic”; each preserved knowledge and served the Ummah according to its time and place. Following any of them keeps one on the path of the Prophet (peace be upon him) and his companions."),
            .text("The imams themselves put their schools beneath the Quran and Sunnah. Mujaahid (may Allah have mercy on him), the student of Ibn Abbaas, said (a saying later made famous in the words of Imam Maalik at the grave of the Prophet, peace be upon him):"),
            .quote(text: "“There is no one after the Prophet (peace be upon him) except that his words may be taken or left” (Ibn Abd al-Barr, Jaami‘ Bayaan al-Ilm 2/926, with a saheeh chain).", arabic: "لَيسَ أَحَدٌ بَعدَ النَّبِيِّ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ إِلَّا يُؤخَذُ مِن قَولِهِ وَيُترَكُ", dimmed: true),
            .text("Imam ash-Shaafi‘i (may Allah have mercy on him) said, and the same is reported from Imam Abu Haneefah:"),
            .quote(text: "“If the hadith is authentic, then that is my madhhab” (an-Nawawi, al-Majmoo‘ 1/63; Ibn Aabideen, Haashiyah 1/63).", arabic: "إِذَا صَحَّ الحَدِيثُ فَهُوَ مَذهَبِي", dimmed: true),
            .text("And Imam Ahmad ibn Hanbal (may Allah have mercy on him) said:"),
            .quote(text: "“Do not blindly follow me, nor Maalik, nor ash-Shaafi‘i, nor al-Awzaa‘i, nor ath-Thawri; take from where they took” (Ibn al-Qayyim, I‘laam al-Muwaqqi‘een 2/302).", arabic: "لَا تُقَلِّدنِي وَلَا تُقَلِّد مَالِكًا وَلَا الشَّافِعِيَّ وَلَا الأَوزَاعِيَّ وَلَا الثَّورِيَّ، وَخُذ مِن حَيثُ أَخَذُوا", dimmed: true),
            .text("So the madhaahib are followed as a means to the Quran and Sunnah, never as a rival to them: where an authentic text is clear, it is the text that is followed, and this is what the four imams commanded."),
        ]),
        ArticleSection("CONCLUSION", [
            .text("Following a madhhab gives structure to religious life and connects Muslims to a legacy of knowledge, discipline, and unity. While it is not obligatory to follow one, it is highly encouraged, especially for those without deep training in Islamic law."),
            .text("If one is unsure which madhhab to follow, they may follow the trusted local scholars in their community, and Allah (Glorified and Exalted be He) will reward sincerity and effort."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Must every Muslim follow one madhhab?**"),
            .text("No. What Allah made obligatory is following His Messenger (peace be upon him) and asking the people of knowledge when one does not know (Quran 16:43, quoted above). Binding oneself to the opinions of one imam in every question is not something Allah or His Messenger commanded:"),
            .ayah("59:7", words: 23...30),
            .text("The best generations did not do it. The Prophet (peace be upon him) said:"),
            .hadith("bukhari:2652", cite: "Saheeh al-Bukhaari 2652", arabic: 29...37, english: [4...23]),
            .text("The Companions and their students asked whichever scholar was at hand: the people of Madinah asked Zayd ibn Thaabit and Ibn Umar, the people of Makkah asked Ibn Abbaas, the people of Koofah asked Ibn Mas‘ood and then Ali (may Allah be pleased with them), and none of them said, “I am on the madhhab of so-and-so.” The four imams belong to the generations after the Companions (the earliest of them, Abu Haneefah, saw the Companion Anas ibn Maalik as a boy but took his fiqh from the Taabi‘een), so the first generations obviously had no Hanafi or Maaliki school. Ibn Taymiyyah (may Allah have mercy on him) writes in Majmoo‘ al-Fataawa that following the madhhab of a specific person, because one cannot learn the Sharee‘ah (شَرِيعَة, from ش-ر-ع, the path leading down to water, and so the revealed law) except through him, is permitted for such a person but is not obligatory on everyone, and that no one is bound to follow one particular man in everything he says except the Messenger of Allah (peace be upon him). In practice: the scholar follows the evidence, the student learns through a school and checks it against the evidence as he grows, and the layman follows the trustworthy scholars available to him, whether they teach within a madhhab or not."),
            .longOnly(.markdown("**Can I take a ruling from another madhhab, or change my madhhab?**")),
            .longOnly(.text("Yes, when it is done for the evidence or on the word of a scholar one trusts more, and not to hunt for the easiest answer. The imams’ own students did it: Abu Yoosuf and Muhammad ash-Shaybaani differed from Abu Haneefah in many questions, al-Muzani differed from ash-Shaafi‘i, and ash-Shaafi‘i revised his own madhhab when he moved to Egypt. Every school’s later scholars weighed (tarjeeh) between the reports from their imam and sometimes preferred another school’s view. Ibn Taymiyyah (may Allah have mercy on him) says in Majmoo‘ al-Fataawa that whoever moves from one madhhab to another for a religious reason, because he finds the other closer to the Quran and Sunnah, has done well, and whoever does so for a worldly aim is blamed. What is condemned is tatabbu‘ ar-rukhas (تَتَبُّع الرُّخَص), collecting the most convenient opinion from each school out of desire. Sulaymaan at-Taymi (may Allah have mercy on him), one of the Taabi‘een, said that if you take the concession of every scholar, all evil gathers in you, and Ibn Abd al-Barr, who reports it in Jaami‘ Bayaan al-Ilm, adds that he knows of no disagreement on this. The touchstone is Quran 4:59 (quoted below): the dispute is referred to Allah and the Messenger, not to one’s ease.")),
            .markdown("**What if my madhhab contradicts an authentic hadith?**"),
            .text("Then the hadith is followed, because that is exactly what the four imams commanded. Ash-Shaafi‘i and Ahmad are quoted above in “Unity Through Diversity”, and Maalik below; Abu Haneefah (may Allah have mercy on him) said:"),
            .quote(text: "“It is not permitted for anyone to take our opinion without knowing where we took it from” (Ibn Abd al-Barr, al-Intiqaa’; Ibn al-Qayyim, I‘laam al-Muwaqqi‘een).", arabic: "لَا يَحِلُّ لِأَحَدٍ أَن يَأخُذَ بِقَولِنَا مَا لَم يَعلَم مِن أَينَ أَخَذنَاهُ", dimmed: true),
            .text("Al-Albaani (may Allah have mercy on him) gathered these statements of the imams in the introduction to Sifaat Salaat an-Nabi, and drew the conclusion the imams themselves drew: leaving an imam’s opinion for the authentic hadith is obedience to the imam, not disloyalty to him. Allah says:"),
            .ayah("24:63", words: 15...26),
            .longOnly(.text("Two cautions keep this honest. First, a hadith may be authentic yet abrogated, restricted by another text, or understood by the Companions differently from its first appearance, so the one who acts on it must be able to verify the chain, the abrogation, and the meaning; a layman who meets such a hadith asks a scholar rather than ruling alone. Second, no scholar may set aside an authentic, unabrogated hadith merely because his imam did not act on it, for the imam had an excuse (the next question) and he does not.")),
            .shortOnly(.text("Two cautions keep this honest. First, a hadith may be authentic yet abrogated, restricted by another text, or understood by the Companions differently from its first appearance, so the one who acts on it must be able to verify the chain, the abrogation, and the meaning; a layman who meets such a hadith asks a scholar rather than ruling alone. Second, no scholar may set aside an authentic, unabrogated hadith merely because his imam did not act on it, for the imam had an excuse and he does not.")),
            .longOnly(.markdown("**Why do the scholars differ, if the Quran and Sunnah are one?**")),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) answers this in Raf‘ al-Malaam ‘an al-A’immah al-A‘laam, beginning with a principle:")),
            .longOnly(.quote(text: "“There is not one of the imams accepted by the ummah with general acceptance who deliberately opposes the Messenger of Allah (peace be upon him) in anything of his Sunnah, small or great, for they are agreed with certainty upon the obligation of following the Messenger” (Ibn Taymiyyah, Raf‘ al-Malaam ‘an al-A’immah al-A‘laam).", arabic: "لَيسَ أَحَدٌ مِنَ الأَئِمَّةِ المَقبُولِينَ عِندَ الأُمَّةِ قَبُولًا عَامًّا يَتَعَمَّدُ مُخَالَفَةَ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ فِي شَيءٍ مِن سُنَّتِهِ دَقِيقٍ وَلَا جَلِيلٍ، فَإِنَّهُم مُتَّفِقُونَ اتِّفَاقًا يَقِينِيًّا عَلَى وُجُوبِ اتِّبَاعِ الرَّسُولِ", dimmed: true)),
            .longOnly(.text("He then gathers the excuses under three heads: the imam did not believe the Prophet said it (the hadith did not reach him, or reached him through a chain he did not trust), he did not believe the text meant that case (a word with more than one meaning, a general text he thought restricted, a report he understood differently), or he believed the ruling abrogated or outweighed by stronger evidence. Every one of these befell the Companions themselves. When Abu Moosa told Umar (may Allah be pleased with them) that the Prophet had commanded whoever asks permission three times without an answer to go back, Umar had never heard it and asked for a witness, then said:")),
            .longOnly(.hadith("bukhari:2062", cite: "Saheeh al-Bukhaari 2062", arabic: 88...100, english: [128...149])),
            .longOnly(.text("Umar likewise did not know the ruling on the Magians until the report reached him:")),
            .longOnly(.hadith("bukhari:3156", cite: "Saheeh al-Bukhaari 3156", arabic: 59...82, english: [100...127])),
            .longOnly(.text("Abrogation caused differences too: Ubayy ibn Ka‘b (may Allah be pleased with him) explained that the early fatwa (فَتوَى, from ف-ت-ي, a considered answer given to a questioner) that a bath is required only when there is emission was a concession from the beginning of Islam which the Prophet later replaced with the command to bathe (Sunan Abi Daawood 215; graded saheeh by al-Albaani), so whoever knew only the first ruling gave fatwa by it.")),
            .longOnly(.hadith("abudawud:215", cite: "Sunan Abi Daawood 215; graded saheeh by al-Albaani", arabic: 24...48, english: [0...47])),
            .longOnly(.text("And understanding differed: Ibn Umar reported that the dead are punished by their family’s weeping, while Aa’ishah (may Allah be pleased with them) held that the report had been misunderstood, for what the Prophet said was that the deceased is punished for his own sin while his family weeps over him (Saheeh al-Bukhaari 3978).")),
            .longOnly(.hadith("bukhari:3978", cite: "Saheeh al-Bukhaari 3978, Saheeh Muslim 932", arabic: 12...57, english: [0...58])),
            .longOnly(.text("If Umar could miss a hadith and Ibn Umar could misunderstand one, an imam in Koofah or Madinah two generations later could do so more easily. Allah Himself records two prophets judging one case differently, and praises both:")),
            .longOnly(.ayah("21:78-79", words: 0...19)),
            .longOnly(.text("Add that Arabic words can carry more than one meaning, that texts can appear to conflict, and that the Companions differed in fiqh in the Prophet’s presence and he approved both sides (the Banu Qurayzah report quoted above), and the differences of the madhaahib become what they are: sincere ijtihaad over probable evidences, rewarded whether it hits or misses.")),
            .longOnly(.markdown("**Is “the differing of my ummah is a mercy” a hadith?**")),
            .longOnly(.text("No. It has no chain of narration. Al-Albaani (may Allah have mercy on him) rules that it has no basis (Silsilat al-Ahaadeeth ad-Da‘eefah 57), citing the Shaafi‘i imam as-Subki, who could find for it no chain at all, sound, weak, or fabricated. Long before them Ibn Hazm (may Allah have mercy on him) rejected its very meaning:")),
            .longOnly(.quote(text: "“If differing were a mercy, then agreement would be a punishment” (Ibn Hazm, al-Ihkaam fi Usool al-Ahkaam).", arabic: "لَو كَانَ الِاختِلَافُ رَحمَةً لَكَانَ الِاتِّفَاقُ سَخَطًا", dimmed: true)),
            .longOnly(.text("The Quran describes those who are shown mercy as the ones who do not differ:")),
            .longOnly(.ayah("11:118-119")),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) explains in his Tafseer that those given mercy are the followers of the messengers, who hold to what Allah revealed and are not divided over it. The Prophet (peace be upon him) warned:")),
            .longOnly(.hadith("bukhari:7288", cite: "Saheeh al-Bukhaari 7288", arabic: 24...32, english: [11...28])),
            .longOnly(.text("Ibn Mas‘ood (may Allah be pleased with him) showed how the Companions handled a difference in fiqh: he disapproved of Uthmaan completing the prayer at Mina, yet prayed the full four behind him rather than split the congregation:")),
            .longOnly(.hadith("abudawud:1960", cite: "Sunan Abi Daawood 1960; graded saheeh by al-Albaani", arabic: 86...102, english: [95...114])),
            .longOnly(.text("What is true is narrower: sincere ijtihaad that misses the mark is excused and even rewarded (Saheeh al-Bukhaari 7352, quoted below), and the range of the Companions’ ijtihaad left the ummah room; it is reported from Umar ibn Abd al-Azeez that he would not have loved the Companions to have agreed on everything, since their differing left a concession (Ibn Abd al-Barr, Jaami‘ Bayaan al-Ilm). The mercy is in the excuse and the ease, not in the differing itself, and what Allah commands is unity (the next question).")),
            .longOnly(.markdown("**Is following a madhhab a bid‘ah?**")),
            .longOnly(.text("No. Bid‘ah is introducing into the religion an act of worship that has no basis in it. The Prophet (peace be upon him) said:")),
            .longOnly(.hadith("bukhari:2697", cite: "Saheeh al-Bukhaari 2697, Saheeh Muslim 1718", arabic: 29...38, english: [4...22])),
            .longOnly(.text("A madhhab introduces no worship; it is a method of understanding the texts, taught by imams whom the whole of Ahl as-Sunnah honours, and adh-Dhahabi (may Allah have mercy on him) praises each of the four at length in Siyar A‘laam an-Nubalaa’. What is blameworthy is ta‘assub (تَعَصُّب), fanatical partisanship: treating the imam as infallible, rejecting an authentic hadith for his sake, or making agreement with him the basis of love and enmity among the Muslims. When partisanship goes so far that a scholar’s word overrides the text of Allah and His Messenger, it approaches what the Quran condemned in the People of the Book:")),
            .longOnly(.ayah("9:31", words: 0...6)),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) explains in his Tafseer that they did not pray to them; they obeyed them in making lawful what Allah had forbidden and forbidding what He had allowed. Ibn Taymiyyah (may Allah have mercy on him) writes in Majmoo‘ al-Fataawa that whoever sets up any person other than the Messenger and gives loyalty and enmity on the basis of agreeing with him is among those who divided their religion into sects. The Prophet (peace be upon him) told us what to hold to when differences multiply:")),
            .longOnly(.hadith("tirmidhi:2676", cite: "Jaami‘ at-Tirmidhi 2676; graded saheeh by al-Albaani", arabic: 69...93, english: [68...114])),
            .longOnly(.text("And Allah says:")),
            .longOnly(.ayah("3:103", words: 0...5)),
            .longOnly(.ayah("6:159")),
            .longOnly(.markdown("**Did the Salafi scholars follow madhhabs?**")),
            .longOnly(.text("Yes. Ibn Taymiyyah, Ibn al-Qayyim, Ibn Qudaamah, and Ibn Rajab were Hanbalis; Ibn Katheer and adh-Dhahabi were Shaafi‘ees (as were an-Nawawi and Ibn Hajar, who were imams of the Sunnah in fiqh and hadith though they took Ash‘ari positions on some attributes); Ibn Abd al-Barr was a Maaliki; at-Tahaawi was a Hanafi. Ibn Baaz and Ibn al-Uthaymeen (may Allah have mercy on them) were trained in Hanbali fiqh and taught from its texts (Ibn al-Uthaymeen’s ash-Sharh al-Mumti‘ is a commentary on the Hanbali manual Zad al-Mustaqni‘), and al-Albaani (may Allah have mercy on him), raised in a Hanafi household, devoted himself to hadith and weighed the evidence without binding himself to a school. What unites them is the rule, not the label: the madhhab is a ladder to the evidence, never a veil over it. Ibn Taymiyyah left the Hanbali position where he found the evidence against it, Ibn al-Uthaymeen’s commentaries repeatedly prefer another school’s view over his own, and al-Albaani cited the imams’ own words as his warrant. At the same time, Ibn Rajab (may Allah have mercy on him) wrote a treatise defending adherence to the four schools by those who lack the tools of ijtihaad, because unqualified people claiming to derive rulings for themselves harm the religion. Both are the way of the Salaf: the qualified follow the evidence, the untrained follow the qualified, and all honour the imams. Allah praised:")),
            .longOnly(.ayah("9:100", words: 0...12)),
            .longOnly(.markdown("**Is the Hanbali madhhab “the Salafi madhhab”?**")),
            .longOnly(.text("No. Salafiyyah is a creed and a methodology (following the Quran and Sunnah as the Companions understood them), not a school of fiqh. All four imams were Salafi in creed, and a Salafi may be Hanafi, Maaliki, Shaafi‘i, or Hanbali in fiqh, or may follow the evidence across the schools if he is qualified. The Hanbali school is associated with Ahl al-Hadith because Imam Ahmad was their imam and because Ibn Taymiyyah and his students came from it, but the creed of the Salaf is the creed of Abu Haneefah, Maalik, and ash-Shaafi‘i just as much as it is the creed of Ahmad (see “Salafiyyah” and “The Madhaahib of Aqeedah”).")),
            .longOnly(.markdown("**Can a layman weigh the evidence himself?**")),
            .longOnly(.text("Not in the sense of deriving rulings, because that requires tools he does not have: Arabic, the grading of chains, knowledge of abrogation, of the general and the specific, and of what the Companions did. The Quran assigns derivation (istinbaat) to a particular group:")),
            .longOnly(.ayah("4:83", words: 9...20)),
            .longOnly(.ayah("21:7")),
            .longOnly(.ayah("39:9", words: 12...23)),
            .longOnly(.text("The Prophet (peace be upon him) warned of what happens when the untrained give rulings:")),
            .longOnly(.hadith("bukhari:100", cite: "Saheeh al-Bukhaari 100", arabic: 32...60, english: [6...71])),
            .longOnly(.text("Ibn al-Qayyim (may Allah have mercy on him) explains in I‘laam al-Muwaqqi‘een that the layman’s asking a mufti is the very thing Allah commanded, not the blameworthy taqleed (تَقلِيد, from ق-ل-د, to put a collar on an animal: following a man without knowing his evidence). What the layman can and must weigh is the mufti: he chooses the most knowledgeable and most God-fearing scholar he can reach, as he would choose a doctor, and when two trustworthy scholars differ he follows the one whose knowledge and piety he trusts more, or the one who shows him the evidence, without following his own desire. Learning the evidence for what one practises is praiseworthy, and a layman who sees a clear authentic hadith should ask about it rather than ignore it; but being unable to derive rulings is not a deficiency in him, it is the division of labour Allah set out in Quran 9:122 (quoted below), and Allah reminds every scholar that:")),
            .longOnly(.ayah("12:76", words: 28...32)),
            .longOnly(.markdown("**Did the four imams differ in creed?**")),
            .longOnly(.text("No. Their differences were in fiqh; in aqeedah they held one creed, the creed of the Salaf. Abu Haneefah and his two companions affirmed the attributes of Allah as revealed, and at-Tahaawi (d. 321 AH) wrote his famous creed as their creed. Maalik (may Allah have mercy on him), asked how Allah rose over the Throne, answered:")),
            .longOnly(.quote(text: "“The rising is not unknown, the how is not comprehended, belief in it is obligatory, and asking about it is an innovation” (al-Laalakaa’i, Sharh Usool I‘tiqaad Ahl as-Sunnah; al-Bayhaqi, al-Asmaa’ was-Sifaat).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true)),
            .longOnly(.text("Ash-Shaafi‘i (may Allah have mercy on him) is reported to have said:")),
            .longOnly(.quote(text: "“I believe in Allah and in what has come from Allah as Allah intended it, and I believe in the Messenger of Allah and in what has come from the Messenger of Allah as the Messenger of Allah intended it” (Ibn Qudaamah, Lum‘at al-I‘tiqaad, without a chain; Ibn Taymiyyah: “what ash-Shaafi‘i said is true,” Majmoo‘ al-Fataawa 6/354).", arabic: "آمَنتُ بِاللَّهِ وَبِمَا جَاءَ عَنِ اللَّهِ عَلَى مُرَادِ اللَّهِ، وَآمَنتُ بِرَسُولِ اللَّهِ وَبِمَا جَاءَ عَن رَسُولِ اللَّهِ عَلَى مُرَادِ رَسُولِ اللَّهِ", dimmed: true)),
            .longOnly(.text("And Ahmad (may Allah have mercy on him) opened his Usool as-Sunnah with the words:")),
            .longOnly(.quote(text: "“The foundations of the Sunnah with us are: holding fast to what the Companions of the Messenger of Allah (peace be upon him) were upon, taking them as the example, and abandoning innovations, for every innovation is misguidance” (Ahmad ibn Hanbal, Usool as-Sunnah, narrated by Abdoos ibn Maalik al-Attaar).", arabic: "أُصُولُ السُّنَّةِ عِندَنَا: التَّمَسُّكُ بِمَا كَانَ عَلَيهِ أَصحَابُ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، وَالِاقتِدَاءُ بِهِم، وَتَركُ البِدَعِ، وَكُلُّ بِدعَةٍ فَهِيَ ضَلَالَةٌ", dimmed: true)),
            .longOnly(.text("All four affirmed that the Quran is the speech of Allah, uncreated, that the believers will see their Lord in the Hereafter, that faith is speech and deed, and that the Companions are to be loved and honoured. See “The Madhaahib of Aqeedah” for the fuller picture. Allah commanded:")),
            .longOnly(.ayah("42:13", words: 1...23)),
            .markdown("**Which madhhab is the best?**"),
            .text("On any given question, the best opinion is the one with the strongest evidence, whichever school holds it. No imam is followed absolutely; only the Prophet (peace be upon him) is:"),
            .ayah("4:65"),
            .ayah("33:36", words: 0...15),
            .longOnly(.text("The hadith of the two rewards (Saheeh al-Bukhaari 7352, quoted below) proves that even the best mujtahid can err, so no school can be right in everything. Imam Maalik (may Allah have mercy on him) said of himself:")),
            .shortOnly(.text("Even the best mujtahid can err, so no school can be right in everything. Imam Maalik (may Allah have mercy on him) said of himself:")),
            .quote(text: "“I am only a man; I err and I am right. So look into my opinion: whatever agrees with the Book and the Sunnah, take it, and whatever does not agree with the Book and the Sunnah, leave it” (Ibn Abd al-Barr, Jaami‘ Bayaan al-Ilm).", arabic: "إِنَّمَا أَنَا بَشَرٌ أُخطِئُ وَأُصِيبُ، فَانظُرُوا فِي رَأيِي، فَكُلُّ مَا وَافَقَ الكِتَابَ وَالسُّنَّةَ فَخُذُوهُ، وَكُلُّ مَا لَم يُوَافِقِ الكِتَابَ وَالسُّنَّةَ فَاترُكُوهُ", dimmed: true),
            .text("The practical answer is to learn from the trustworthy scholars near you, in whichever of the four schools they teach, to learn the evidence for what you practise, and to put the authentic hadith first, as that school’s own imam commanded."),
            .longOnly(.markdown("**What is the ruling on ijmaa‘ (إِجمَاع, from ج-م-ع, to gather: the agreement of the scholars), and can the ummah agree on an error?**")),
            .longOnly(.text("Ijmaa‘ is a binding proof, and the ummah as a whole is protected from agreeing on misguidance. Allah says:")),
            .longOnly(.ayah("4:115")),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) records in his Tafseer that Imam ash-Shaafi‘i took this ayah as the proof that ijmaa‘ is binding and that opposing it is forbidden. Allah also says:")),
            .longOnly(.ayah("2:143", words: 0...11)),
            .longOnly(.text("A community whose testimony Allah accepts over the nations cannot unite on falsehood. The Prophet (peace be upon him) also promised that truth will never be without its bearers:")),
            .longOnly(.hadith("muslim:1920", cite: "Saheeh Muslim 1920; Saheeh al-Bukhaari 3641 similar", arabic: 37...54, english: [0...50])),
            .longOnly(.text("So the whole ummah can never unite on an error, because a group upon the truth always remains. The wording “my ummah will not unite upon misguidance” is reported through several chains that the hadith scholars grade individually; its meaning rests securely on the aayaat and reports above. Two limits keep ijmaa‘ sound: it must be real, which is why Imam Ahmad warned against loose claims of it (quoted below), and the ijmaa‘ known with certainty is that of the Companions and the Salaf; and, as Ibn Taymiyyah notes in Majmoo‘ al-Fataawa, every genuine ijmaa‘ rests on a text, so consensus never opposes the Quran and Sunnah but confirms them.")),
            .longOnly(.markdown("**Is the door of ijtihaad closed?**")),
            .longOnly(.text("No. Some later scholars claimed that no mujtahid could arise after the early centuries, but Ibn Taymiyyah, Ibn al-Qayyim, as-Suyooti, and ash-Shawkaani (may Allah have mercy on them) rejected the claim; as-Suyooti wrote a treatise arguing that ijtihaad is an obligation of the ummah in every age. Ibn Taymiyyah adds that ijtihaad is divisible: a scholar may be qualified to weigh the evidence in one field while following others elsewhere. What is closed is ijtihaad without its tools, which the Prophet (peace be upon him) described as ignorant heads giving verdicts without knowledge (Saheeh al-Bukhaari 100, quoted above). The reward of the qualified mujtahid (Saheeh al-Bukhaari 7352, quoted below) and the command that a group in every community obtain understanding in the religion (Quran 9:122, quoted below) both assume that the effort continues until the Hour.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Following a qualified school connects a Muslim to generations of disciplined scholarship; their differences are sincere ijtihaad that Allah rewards, all four imams held one creed, and all four schools are within Ahl as-Sunnah."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Fiqh (فِقه)**: “deep understanding,” from the root ف-ق-ه, to grasp the meaning of a thing beneath its surface; the Quran uses the verb when Moosa asks that the people “may understand my speech” (Quran 20:28)."),
            .ayah("20:28"),
            .markdown("In the Sharee‘ah, fiqh is the knowledge of the practical rulings of Islam (how to purify oneself, pray, fast, trade, marry, and inherit) drawn from their detailed evidences. The Prophet (peace be upon him) tied this understanding to Allah wanting good for a person (Saheeh al-Bukhaari 71, quoted above), and the Quran made it the purpose of setting out to seek knowledge:"),
            .ayah("9:122", words: 6...20),
            .markdown("**Faqeeh (فَقِيه)**, plural **fuqaha (فُقَهَاء)**: one who possesses fiqh, a jurist. The word is about understanding, not memory alone. The Prophet (peace be upon him) prayed for Ibn Abbaas (may Allah be pleased with them) with the verb of this very word, allahumma faqqihhu fid-deen:"),
            .hadith("bukhari:143", cite: "Saheeh al-Bukhaari 143", arabic: 42...45, english: [27...38]),
            .text("And he distinguished the one who carries knowledge from the one who understands it:"),
            .hadith("tirmidhi:2656", cite: "Jaami‘ at-Tirmidhi 2656; graded saheeh by al-Albaani", arabic: 75...97, english: [68...113]),
            .text("The Salaf added that fiqh without fear of Allah is not fiqh. When someone objected to al-Hasan al-Basri (may Allah have mercy on him), “The fuqaha do not say that,” he replied:"),
            .hadith("darimi:297", cite: "Sunan ad-Daarimi 297", arabic: 37...57, text: "“Woe to you! Have you ever seen a faqeeh? The faqeeh is only the one who renounces this world, desires the Hereafter, has insight into the affair of his religion, and is constant in the worship of his Lord”"),
            .markdown("**Madhhab (مَذهَب)**, plural **madhaahib (مَذَاهِب)**: from ذَهَبَ (dhahaba), “he went”; literally the way one goes, or the place one goes to. In fiqh it is the method an imam used to derive rulings, together with the body of rulings that his students preserved, refined, and passed on. A madhhab is a way to the Quran and Sunnah, not a source alongside them, and the imams themselves said so (see “Unity Through Diversity” above)."),
            .markdown("**Sharee‘ah (شَرِيعَة)**: from ش-ر-ع, the open path that leads down to water; the whole law that Allah revealed, which is why He says of the nations, “To each of you We prescribed a law and a method” (Quran 5:48)."),
            .ayah("5:48", words: 24...28),
            .markdown("The Sharee‘ah is one and infallible, because it is from Allah; fiqh is the scholars’ understanding of it, and a scholar can be right or mistaken. Keeping the two apart explains how the schools can differ while the religion stays one:"),
            .ayah("45:18"),
            .markdown("**Usool al-fiqh (أُصُول الفِقه)**: “the roots of fiqh,” usool being the plural of asl (أَصل), a root or foundation. It is the science of the sources of the law and of the rules for deriving rulings from them: the Quran, the Sunnah, consensus, and analogy, together with the study of commands and prohibitions, the general and the specific, and the abrogating and the abrogated. Imam ash-Shaafi‘i’s ar-Risaalah (الرِّسَالَة) is the earliest book on it that has reached us. Scholars of usool point to one ayah that gathers the sources in order: obedience to Allah (the Quran), obedience to the Messenger (the Sunnah), the people of authority (whose agreement is consensus), and the referring of new disputes back to the two revelations (analogy):"),
            .ayah("4:59", words: 0...9),
            .text("and then sends every dispute back to the two revelations:"),
            .ayah("4:59", words: 10...23),
            .text("The Sunnah is revelation alongside the Book, a source in its own right and not a mere commentary, and the Prophet (peace be upon him) foretold those who would try to set it aside:"),
            .hadith("abudawud:4604", cite: "Sunan Abi Daawood 4604; graded saheeh by al-Albaani", arabic: 37...64, english: [4...55]),
            .markdown("**Daleel (دَلِيل)**, plural **adillah (أَدِلَّة)**: from د-ل-ل, to guide or point the way; a proof, that which leads to a ruling. The Quran uses the word of the sun, which marks out the movement of the shadow:"),
            .ayah("25:45", words: 11...15),
            .text("A daleel may be textual (naqli: an ayah or a hadith) or rational (‘aqli), and definitive (qat‘i) or probable (zanni). Most differences in fiqh arise over probable evidences, which is why they are tolerated; no difference is tolerated over what is definitive."),
            .markdown("**Ijtihaad (اِجتِهَاد)** and **mujtahid (مُجتَهِد)**: from ج-ه-د, to exert oneself to the utmost. Ijtihaad is the qualified scholar’s utmost effort to reach the ruling of Allah on a question the texts do not settle explicitly, and the mujtahid is the one qualified to make it: he must know the Quran, the Sunnah and its chains, the Arabic language, the points of consensus, the abrogating and the abrogated, and the rules of usool. Allah rewards the sincere, qualified effort even when it misses the mark:"),
            .hadith("bukhari:7352", cite: "Saheeh al-Bukhaari 7352, Saheeh Muslim 1716", arabic: 46...60, english: [7...71]),
            .text("Ijtihaad reaches for the ruling of Allah but is not the same as it, which is why the Prophet (peace be upon him) instructed his commanders:"),
            .hadith("muslim:1731a", cite: "Saheeh Muslim 1731", arabic: 248...275, english: [304...361]),
            .markdown("**Taqleed (تَقلِيد)** and **ittibaa‘ (اِتِّبَاع)**: taqleed is from qilaadah (قِلَادَة), a collar or necklace; to make taqleed of someone is to hang your affair around his neck, accepting his statement without knowing its evidence. Ittibaa‘ is from ت-ب-ع, to follow; it is following a statement because its evidence has become clear to you. The Quran condemns the taqleed that turns away from revelation:"),
            .ayah("2:170"),
            .text("and it makes ittibaa‘ of the Messenger (peace be upon him) the proof of love for Allah:"),
            .ayah("3:31", words: 0...10),
            .text("Ibn Abd al-Barr (may Allah have mercy on him) records the scholars’ distinction in Jaami‘ Bayaan al-Ilm: taqleed is returning to a statement whose speaker has no proof for it, while ittibaa‘ is what a proof has established. Ibn al-Qayyim (may Allah have mercy on him) builds on it in I‘laam al-Muwaqqi‘een, separating the blameworthy taqleed (turning away from what Allah revealed in favour of one’s forefathers, following someone one does not know to be qualified, and clinging to an opinion after the evidence against it has appeared) from the permitted asking of the people of knowledge by the one who cannot derive rulings himself, which is what Allah commanded in Quran 16:43 (quoted above). The scholar practises ittibaa‘; the layman practises a permitted taqleed that should move toward ittibaa‘ as he learns."),
            .markdown("**Ijmaa‘ (إِجمَاع)**: from ج-م-ع, to gather or agree; the agreement of the qualified scholars of the ummah, after the Prophet (peace be upon him), on a ruling. It is the third source of the law, and its proof is that Allah threatened whoever follows other than the way of the believers (Quran 4:115, quoted above). Imam Ahmad (may Allah have mercy on him) warned against loose claims of it:"),
            .quote(text: "“Whoever claims consensus is lying” (Ibn al-Qayyim, I‘laam al-Muwaqqi‘een).", arabic: "مَنِ ادَّعَى الإِجمَاعَ فَهُوَ كَاذِبٌ", dimmed: true),
            .text("He meant that a scholar may simply not know of a dissenting opinion, so a claim of ijmaa‘ must be verified; the ijmaa‘ known with certainty is that of the Companions and the first generations."),
            .markdown("**Qiyaas (قِيَاس)**: from ق-ي-س, to measure one thing against another; extending the ruling of a case settled by a text to a new case that shares its effective cause (**‘illah, عِلَّة**). Wine is forbidden because it intoxicates, so every intoxicant is forbidden. The Prophet (peace be upon him) himself reasoned this way when a woman asked whether she could perform Hajj on behalf of her mother, who had vowed to perform it and died:"),
            .hadith("bukhari:1852", cite: "Saheeh al-Bukhaari 1852", arabic: 49...63, english: [39...70]),
            .text("Qiyaas is a source only where no text speaks directly. It is accepted by the four schools and rejected by the Zaahirees."),
            .markdown("**Fatwa (فَتوَى)** and **mufti (مُفتِي)**: from ف-ت-ي, to make a matter clear; a fatwa is an answer to a question about a ruling, and the mufti is the one qualified to give it. The Quran uses the very word of Allah answering His servants:"),
            .ayah("4:176", words: 0...5),
            .text("Giving fatwa without knowledge is a grave sin. The Prophet (peace be upon him) said:"),
            .hadith("ibnmajah:53", cite: "Sunan Ibn Maajah 53; graded hasan by al-Albaani", arabic: 44...53, english: [6...27]),
            .markdown("**The five rulings (الأَحكَام الخَمسَة)**: every act falls under one of five. **Fard (فَرض)** or **waajib (وَاجِب)**: obligatory. Fard is from ف-ر-ض, to cut or fix definitively (Allah calls the shares of inheritance “an obligation [imposed] by Allah,” Quran 4:11), and waajib is from و-ج-ب, to be binding."),
            .ayah("4:11", words: 63...65),
            .markdown("Most scholars use the two as synonyms; the Hanafis reserve fard for what is established by definitive proof and waajib for what is established by probable proof. One is rewarded for doing it and punished for leaving it. **Mustahabb (مُستَحَبّ)**, also called sunnah or **mandoob (مَندُوب)**: recommended, from ح-ب-ب, to love; rewarded if done, not punished if left. **Mubaah (مُبَاح)**: permitted, from ب-و-ح, to be open; neither reward nor punishment in itself. **Makrooh (مَكرُوه)**: disliked, from ك-ر-ه, to hate; rewarded for leaving it, not punished for doing it. **Haraam (حَرَام)**: forbidden, from ح-ر-م, to be inviolable; punished for doing it and rewarded for leaving it out of obedience. Only Allah assigns these categories:"),
            .ayah("16:116", words: 0...13),
            .markdown("**Halaal (حَلَال)** and **haraam (حَرَام)**: halaal is from ح-ل-ل, to untie or release, hence what is permitted; haraam is what is forbidden. Between the two lie doubtful matters, and piety is to keep clear of them. The Prophet (peace be upon him) said:"),
            .hadith("bukhari:52", cite: "Saheeh al-Bukhaari 52, Saheeh Muslim 1599", arabic: 23...39, english: [6...45]),
            .markdown("**Rukhsah (رُخصَة)** and **‘azeemah (عَزِيمَة)**: ‘azeemah, from ع-ز-م, resolve, is the original ruling; rukhsah, from ر-خ-ص, ease, is the concession Allah grants when there is hardship: shortening the prayer and breaking the fast on a journey, tayammum when water is absent, eating forbidden meat under necessity. Allah says of the fast:"),
            .ayah("2:185", words: 27...34),
            .text("When Umar (may Allah be pleased with him) asked the Prophet (peace be upon him) why the prayer is still shortened on journeys now that the Muslims are safe, he answered:"),
            .hadith("muslim:686a", cite: "Saheeh Muslim 686", arabic: 79...85, english: [63...78]),
            .text("And when Hamzah ibn Amr al-Aslami (may Allah be pleased with him) asked whether he sinned by fasting on a journey, since he had the strength for it, he answered:"),
            .hadith("muslim:1121e", cite: "Saheeh Muslim 1121", arabic: 64...78, english: [29...58]),
            .markdown("**The four schools**: the Hanafi school of Abu Haneefah an-Nu‘maan ibn Thaabit (d. 150 AH, Koofah), the Maaliki school of Maalik ibn Anas (d. 179 AH, Madinah), the Shaafi‘i school of Muhammad ibn Idrees ash-Shaafi‘i (d. 204 AH, Egypt, after Makkah, Madinah, and Iraq), and the Hanbali school of Ahmad ibn Hanbal (d. 241 AH, Baghdaad). Each is treated in “The Four Sunni Madhaahib” above. Other imams of the same rank had schools that did not survive as living traditions, among them al-Awzaa‘i (d. 157 AH) in Syria, Sufyaan ath-Thawri (d. 161 AH) in Koofah, al-Layth ibn Sa‘d (d. 175 AH) in Egypt, and Ibn Jareer at-Tabari (d. 310 AH) in Baghdaad."),
            .markdown("**The Zaahiri school (الظَّاهِرِيَّة)**: from zaahir (ظَاهِر), the apparent; the school of Daawood ibn Ali al-Asbahaani, known as az-Zaahiri (d. 270 AH, Baghdaad), a pupil of Ishaaq ibn Raahawayh and Abu Thawr, and developed most fully by Ibn Hazm al-Andalusi (d. 456 AH), author of al-Muhalla in fiqh and al-Ihkaam in usool. The Zaahirees hold to the apparent meaning of the texts and to consensus, and reject qiyaas as a source. Scholars valued its devotion to the texts (adh-Dhahabi records in Siyar A‘laam an-Nubalaa’ that al-Izz ibn Abd as-Salaam counted al-Muhalla, with Ibn Qudaamah’s al-Mughni, among the finest books of fiqh), while noting that in some questions of Allah’s attributes Ibn Hazm departed from the way of the Salaf. The school did not survive as a living tradition with its own continuous community."),
            .markdown("**Ahl ar-Ra’y (أَهل الرَّأي)** and **Ahl al-Hadith (أَهل الحَدِيث)**: “the people of considered opinion” and “the people of hadith,” the two tendencies of early fiqh. Ahl ar-Ra’y, centred in Koofah and represented by Abu Haneefah and his companions, made wide use of qiyaas and juristic preference (istihsaan), partly because fewer narrations were established in Iraq, where forgery was also more common, so its jurists were stricter in what they accepted. Ahl al-Hadith, centred in Madinah and Makkah and represented by Maalik, then by ash-Shaafi‘i and Ahmad, kept close to the narrated texts and used qiyaas sparingly. The labels describe an emphasis, not a rejection: the Hanafis accept authentic hadith, and the hadith scholars use analogy. Ash-Shaafi‘i studied the Iraqi fiqh under Muhammad ash-Shaybaani and the Madinan fiqh under Maalik, and his usool brought the two together."),
            .markdown("**The seven fuqaha of Madinah (الفُقَهَاء السَّبعَة)**: the seven jurists of the generation after the Companions who carried the fiqh of Madinah at the end of the first century AH: Sa‘eed ibn al-Musayyib, Urwah ibn az-Zubayr, al-Qaasim ibn Muhammad ibn Abi Bakr, Khaarijah ibn Zayd ibn Thaabit, Ubaydullah ibn Abdullah ibn Utbah, Sulaymaan ibn Yasaar, and a seventh whom the lists give as Abu Bakr ibn Abd ar-Rahman ibn al-Haarith, Saalim ibn Abdullah ibn Umar, or Abu Salamah ibn Abd ar-Rahman. Their students, above all Ibn Shihaab az-Zuhri, taught Maalik, so the Maaliki school stands on the fiqh of Madinah at one remove from the Companions."),
            .markdown("**The four Abdullahs (العَبَادِلَة الأَربَعَة)**: four Companions named Abdullah whose fataawa shaped early fiqh: Abdullah ibn Umar, Abdullah ibn Abbaas, Abdullah ibn az-Zubayr, and Abdullah ibn Amr ibn al-As (may Allah be pleased with them). When they agreed on a ruling it was called “the opinion of the Abaadilah.” Abdullah ibn Mas‘ood (may Allah be pleased with him) died earlier and, as Imam Ahmad noted (reported by Ibn as-Salaah in his Muqaddimah), is not counted among them, but he is the root of the fiqh of Koofah: his students Alqamah and al-Aswad taught Ibraaheem an-Nakha‘i, who taught Hammaad ibn Abi Sulaymaan, the teacher of Abu Haneefah. Ibn Abbaas’s circle in Makkah (Ataa’, Mujaahid, Taawoos, and Ikrimah) and Ibn Umar’s student Naafi‘, from whom Maalik narrated, show that every madhhab goes back through the Taabi‘een to the Companions, and through them to the Prophet (peace be upon him)."),
        ]),
    ]
}

struct AhlulBaytView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Ahlul Bayt are the family of the Prophet; loving, honoring, and upholding their rights is part of the religion.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "The **Ahlul Bayt (أَهلُ البَيت)**, literally “the People of the House,” are the family of Prophet Muhammad (peace be upon him). Loving them, honoring them, and upholding their rights is part of the religion, and hating them or belittling them is a grave sin.")

                    ArticleParagraph(verbatim: "The Quran uses the term directly when addressing the Prophet’s household:")

                    ScriptureQuote(quran: "33:33", words: 15...24)

                    ArticleParagraph(verbatim: "This is one continuous passage. It is essential to read the verses immediately before and after it to see who is being addressed.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE WIVES ARE PART OF THE AHLUL BAYT")) {
                        ArticleParagraph(verbatim: "The verse of purification (33:33) sits in the middle of a passage directed to the Prophet’s wives (may Allah be pleased with them). The address begins:")

                        ScriptureQuote(quran: "33:32", words: 0...10)

                        ArticleParagraph(articleMarkdown: "The phrase “O people of the household” is therefore addressed, first and foremost, to the wives of the Prophet (peace be upon him), the **Mothers of the Believers (أُمَّهَاتُ المُؤمِنِين)**.")
                    }

                    Section(header: ArticleHeader("THE FAMILY OF THE CLOAK")) {
                        ArticleParagraph(articleMarkdown: "The Ahlul Bayt also includes the Prophet’s daughter **Faatimah**, his cousin and son-in-law **Ali**, and their sons **al-Hasan** and **al-Husayn** (may Allah be pleased with them all).")

                        ArticleParagraph(verbatim: "Aa’ishah (may Allah be pleased with her) narrated:")
                        ScriptureQuote(hadith: "muslim:2424", cite: "Saheeh Muslim 2424", arabic: 35...78, english: 0...19)

                        ArticleParagraph(verbatim: "Including these four does not exclude the wives; the Prophet (peace be upon him) was gathering additional members of his household under the cloak, within a passage whose context is already addressing his wives. The two are complementary, not contradictory.")
                    }

                    Section(header: ArticleHeader("THE COMMAND TO LOVE THEM")) {
                        ArticleParagraph(verbatim: "At the pool of Khumm, between Makkah and Madinah, the Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "muslim:2408a", cite: "Saheeh Muslim 2408", english: [177...211, 226...245], arabicText: "وَأَنَا تَارِكٌ فِيكُم ثَقَلَينِ أَوَّلُهُمَا كِتَابُ اللَّهِ فِيهِ الهُدَى وَالنُّورُ فَخُذُوا بِكِتَابِ اللَّهِ وَاستَمسِكُوا بِهِ … وَأَهلُ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي")

                        ArticleParagraph(verbatim: "Loving the Ahlul Bayt is a sign of faith. It is never in tension with loving the Companions (may Allah be pleased with them): Ali, al-Hasan, al-Husayn, and the Prophet’s wives were themselves among the Companions.")
                    }

                    Section(header: ArticleHeader("THE BALANCED POSITION")) {
                        ArticleParagraph(articleMarkdown: "There are two errors regarding the Ahlul Bayt. Some **neglect their rights** and fail to honor them as Allah and His Messenger commanded. Others **exaggerate beyond bounds**, elevating them past the station Allah gave them, or using love of them as a pretext to curse and slander the Companions.")

                        ArticleParagraph(verbatim: "The straight path is between the two: love and honor them without exaggeration, and love all the Companions of the Prophet (peace be upon him) alongside them.")

                        ScriptureQuote(quran: "59:10")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE WIVES ARE PART OF THE AHLUL BAYT")) {
                        ArticleParagraph(verbatim: "The verse of purification (33:33) sits in the middle of a passage directed to the Prophet’s wives (may Allah be pleased with them). The address begins:")

                        ScriptureQuote(quran: "33:32", words: 0...10)

                        ScriptureQuote(quran: "33:33", words: 15...24)

                        ScriptureQuote(quran: "33:34")

                        ArticleParagraph(articleMarkdown: "The phrase “O people of the household” is therefore addressed, first and foremost, to the wives of the Prophet (peace be upon him), the **Mothers of the Believers (أُمَّهَاتُ المُؤمِنِين)**, whom Allah placed in the position of mothers to every believer (Quran 33:6).")
                        ScriptureQuote(quran: "33:6", words: 5...6)

                        ArticleParagraph(verbatim: "Allah also called the wife of Ibraaheem (peace be upon him) part of the “people of the house” using the very same expression:")

                        ScriptureQuote(quran: "11:73")

                        ArticleParagraph(verbatim: "So a prophet’s wives being included in “Ahl al-Bayt” is the established Quranic usage, not an exception.")
                    }

                    Section(header: ArticleHeader("THE FAMILY OF THE CLOAK")) {
                        ArticleParagraph(articleMarkdown: "The Ahlul Bayt also includes the Prophet’s daughter **Faatimah**, his cousin and son-in-law **Ali**, and their sons **al-Hasan** and **al-Husayn** (may Allah be pleased with them all).")

                        ArticleParagraph(verbatim: "Aa’ishah (may Allah be pleased with her) narrated:")
                        ScriptureQuote(hadith: "muslim:2424", cite: "Saheeh Muslim 2424", arabic: 35...78, english: 0...19)

                        ArticleParagraph(verbatim: "Including these four does not exclude the wives; the Prophet (peace be upon him) was gathering additional members of his household under the cloak, within a passage whose context is already addressing his wives. The two are complementary, not contradictory.")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said of his grandsons:")
                        ScriptureQuote(hadith: "tirmidhi:3768", cite: "Jaami‘ at-Tirmidhi 3768; graded saheeh by al-Albaani", arabic: 37...42, english: 7...17)

                        ArticleParagraph(verbatim: "And of Faatimah (may Allah be pleased with her) he said:")
                        ScriptureQuote(hadith: "bukhari:3714", cite: "Saheeh al-Bukhaari 3714", arabic: 28...33, english: 4...18)
                    }

                    Section(header: ArticleHeader("THE BANU HAASHIM AND THE PROPHET’S KIN")) {
                        ArticleParagraph(verbatim: "The Ahlul Bayt further includes the relatives of the Prophet (peace be upon him) upon whom charity (sadaqah) is forbidden: the family of Ali, the family of Ja‘far, the family of Aqeel, and the family of al-Abbaas (may Allah be pleased with them).")

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "muslim:1072b", cite: "Saheeh Muslim 1072", arabic: 105...118, english: 80...105)

                        ArticleParagraph(verbatim: "Zayd ibn Arqam (may Allah be pleased with him) was asked, “Who are the people of his household? Are not his wives among the people of his household?” He said:")
                        ScriptureQuote(hadith: "muslim:2408a", cite: "Saheeh Muslim 2408", arabic: 212...222, english: 269...292)
                    }

                    Section(header: ArticleHeader("THE COMMAND TO LOVE THEM")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")

                        ScriptureQuote(quran: "42:23", words: 9...17)

                        ArticleParagraph(verbatim: "Ibn Abbaas (may Allah be pleased with them) explained this ayah: there was no clan of Quraysh to which the Prophet (peace be upon him) was not related, so what he asked of them was to honour the kinship between him and them (Saheeh al-Bukhaari 4818). The ayah is therefore not itself the command to love his household; that command is in the hadith that follows.")
                        ScriptureQuote(hadith: "bukhari:4818", cite: "Saheeh al-Bukhaari 4818", arabic: 26...73, english: 0...87)

                        ArticleParagraph(verbatim: "At the pool of Khumm, between Makkah and Madinah, the Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "muslim:2408a", cite: "Saheeh Muslim 2408", english: [177...211, 226...245], arabicText: "وَأَنَا تَارِكٌ فِيكُم ثَقَلَينِ أَوَّلُهُمَا كِتَابُ اللَّهِ فِيهِ الهُدَى وَالنُّورُ فَخُذُوا بِكِتَابِ اللَّهِ وَاستَمسِكُوا بِهِ … وَأَهلُ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي")

                        ArticleParagraph(verbatim: "Every believer sends blessings upon them in each prayer, in the words the Prophet (peace be upon him) taught:")
                        ScriptureQuote(hadith: "bukhari:3370", cite: "Saheeh al-Bukhaari 3370", arabic: 79...113, english: 68...137)

                        ArticleParagraph(verbatim: "Loving the Ahlul Bayt is a sign of faith. It is never in tension with loving the Companions (may Allah be pleased with them): Ali, al-Hasan, al-Husayn, and the Prophet’s wives were themselves among the Companions.")
                    }

                    Section(header: ArticleHeader("THE BALANCED POSITION")) {
                        ArticleParagraph(articleMarkdown: "There are two errors regarding the Ahlul Bayt. Some **neglect their rights** and fail to honor them as Allah and His Messenger commanded. Others **exaggerate beyond bounds**, elevating them past the station Allah gave them, or using love of them as a pretext to curse and slander the Companions.")

                        ArticleParagraph(verbatim: "The straight path is between the two: love and honor them without exaggeration, and love all the Companions of the Prophet (peace be upon him) alongside them.")

                        ScriptureQuote(quran: "59:10")

                        ArticleParagraph(verbatim: "Ali, al-Hasan, and al-Husayn (may Allah be pleased with them) themselves loved, prayed behind, married into, and named their children after Abu Bakr, Umar, and Uthmaan (may Allah be pleased with them): Ali said that the best of this ummah after its Prophet is Abu Bakr, then Umar (Saheeh al-Bukhaari 3671), Umar married Ali’s daughter Umm Kulthoom (Saheeh al-Bukhaari 2881), and Ali named sons Abu Bakr, Umar, and Uthmaan (Ibn Sa‘d, at-Tabaqaat). Their example is the proof of this unity.")
                        ScriptureQuote(hadith: "bukhari:3671", cite: "Saheeh al-Bukhaari 3671", arabic: 19...53, english: 0...49)
                        ScriptureQuote(hadith: "bukhari:2881", cite: "Saheeh al-Bukhaari 2881", arabic: 15...57, english: 0...48)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Balanced love for the Prophet's household, without exaggeration or neglect, is the way of the believers, joined with love for all his Companions.")
                }

                ArticleSourcesSection(article: "AhlulBaytView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The People of the House")
        .englishArticle().selectableArticleList(article: "AhlulBaytView")
    }
}

struct AhlusSunnahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Ahl as-Sunnah wal-Jamaa‘ah are those who hold to the Sunnah of the Prophet upon the understanding of his Companions, united in creed.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Ahl as-Sunnah wal-Jamaa‘ah (أَهلُ السُّنَّةِ وَالجَمَاعَة)** means “the People of the Sunnah and the Community.” They are those who hold to the Sunnah of the Prophet Muhammad (peace be upon him) and remain united upon the understanding of his Companions (may Allah be pleased with them).")

                    ArticleParagraph(articleMarkdown: "**Sunnah** here means the Prophet’s way: his beliefs, statements, actions, and approvals. **Jamaa‘ah** means the united body of the believers, and specifically the way of the Companions and those who followed them in goodness.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")

                    ScriptureQuote(quran: "4:115")

                    ArticleParagraph(verbatim: "“The way of the believers” in this verse is the way of the first believers: the Companions.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE THREE FOUNDATIONS")) {
                        ArticleParagraph(articleMarkdown: "**1. The Quran**: taken as it is, without distortion, denial, or asking “how.”")

                        ArticleParagraph(articleMarkdown: "**2. The authentic Sunnah**: accepted as binding revelation alongside the Quran, whether the report is mutawaatir or an authentic single narration (aahaad).")

                        ArticleParagraph(articleMarkdown: "**3. The understanding of the Salaf**: the Quran and Sunnah are understood the way the first three generations understood them, not according to later opinions or personal reasoning that contradicts them.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE THREE FOUNDATIONS")) {
                        ArticleParagraph(articleMarkdown: "**1. The Quran**: taken as it is, without distortion, denial, or asking “how.”")

                        ArticleParagraph(articleMarkdown: "**2. The authentic Sunnah**: accepted as binding revelation alongside the Quran, whether the report is mutawaatir or an authentic single narration (aahaad).")

                        ArticleParagraph(articleMarkdown: "**3. The understanding of the Salaf**: the Quran and Sunnah are understood the way the first three generations understood them, not according to later opinions or personal reasoning that contradicts them.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "9:100", words: 0...12)

                        ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:2652", cite: "Saheeh al-Bukhaari 2652", arabic: 29...37, english: 4...23)
                    }

                    Section(header: ArticleHeader("THEIR CREED (AQEEDAH)")) {
                        ArticleBullet("• **Tawheed**: Allah alone is worshipped, and He alone is the Lord, and He is called by His beautiful Names and described by His perfect Attributes.")

                        ArticleBullet("• **Names and Attributes**: affirmed as Allah affirmed them for Himself, without likening Him to creation (tashbeeh) and without stripping the meanings away (ta‘teel).")

                        ScriptureQuote(quran: "42:11", words: 13...18)

                        ArticleBullet("• **Eemaan** consists of belief in the heart, statement of the tongue, and action of the limbs. It increases with obedience and decreases with disobedience.")

                        ArticleBullet("• **Qadar**: everything occurs by Allah’s knowledge, writing, will, and creation, while the servant has real choice and responsibility.")

                        ArticleBullet("• **No takfeer** of a Muslim for a major sin, so long as he does not deem it lawful. The sinner remains a believer, deficient in faith.")

                        ArticleBullet("• Love for **all the Companions** (may Allah be pleased with them) and the **Ahlul Bayt**, without exaggeration in either direction.")
                    }
                }

                Section(header: ArticleHeader("THE SAVED GROUP")) {
                    ArticleParagraph(verbatim: "The Prophet (peace be upon him) said:")
                    ScriptureQuote(hadith: "ibnmajah:3992", cite: "Sunan Ibn Maajah 3992; graded saheeh by al-Albaani", arabic: 38...90, english: 0...78)

                    ArticleParagraph(verbatim: "In another narration he described that one group as:")
                    ScriptureQuote(hadith: "tirmidhi:2641", cite: "Jaami‘ at-Tirmidhi 2641; graded hasan by al-Albaani", arabic: 91...94, english: 86...92)

                    ArticleParagraph(articleMarkdown: "The defining measure in this hadith is not a name or a label, but a **standard**: the Jamaa‘ah, what the Prophet (peace be upon him) and his Companions were upon. Ahl as-Sunnah wal-Jamaa‘ah is simply the name for those who hold to that standard.")

                    ArticleParagraph(verbatim: "He (peace be upon him) also said:")
                    ScriptureQuote(hadith: "abudawud:4607", cite: "Sunan Abi Daawood 4607; graded saheeh by al-Albaani", arabic: 112...132, english: 159...192)
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("UNITY, NOT SECTARIANISM")) {
                        ArticleParagraph(verbatim: "Ahl as-Sunnah wal-Jamaa‘ah is not a sect among sects. It is the original, undivided Islam of the Prophet (peace be upon him) and his Companions. Its adherents differ in fiqh across the four madhaahib, yet stand united in creed.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("UNITY, NOT SECTARIANISM")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) commands unity upon the truth:")

                        ScriptureQuote(quran: "3:103", words: 0...5)

                        ScriptureQuote(quran: "6:159", words: 0...9)

                        ArticleParagraph(verbatim: "Ahl as-Sunnah wal-Jamaa‘ah is therefore not a sect among sects. It is the original, undivided Islam of the Prophet (peace be upon him) and his Companions. Its adherents differ in fiqh across the four madhaahib, yet stand united in creed.")

                        ArticleParagraph(verbatim: "They are known for mercy toward the believers, honesty toward opponents, obedience to Muslim authority in what is good, and refusal to declare the general body of Muslims outside of Islam.")
                    }

                    Section(header: ArticleHeader("CONCLUSION")) {
                        ArticleParagraph(verbatim: "To be from Ahl as-Sunnah wal-Jamaa‘ah is to take the Quran and the authentic Sunnah as they came, to understand them as the Companions understood them, to love the Prophet’s family and his Companions together, and to hold to the community of the Muslims.")

                        ScriptureQuote(quran: "2:137", words: 0...7)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Not a sect but the original, undivided Islam: taking the Quran and Sunnah as the Companions did, and loving the Prophet's family and Companions together.")
                }

                ArticleSourcesSection(article: "AhlusSunnahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ahl As-Sunnah")
        .englishArticle().selectableArticleList(article: "AhlusSunnahView")
    }
}

struct SeerahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Seerah is the life story of Prophet Muhammad: his character, mission, and example, drawn from the Quran and authentic reports.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "The **Seerah (سِيرَة)** is the biography of the Prophet Muhammad (peace be upon him): the account of his life, character, and mission, drawn from the Quran and authentic reports.")

                    ArticleParagraph(verbatim: "Studying it is not merely history; it shows how revelation was lived, and it is a means of knowing, loving, and following him.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                    ScriptureQuote(quran: "33:21")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("BEFORE PROPHETHOOD")) {
                        ArticleParagraph(articleMarkdown: "He was born in 570 CE in **Makkah (مَكَّة)**, among the tribe of Quraysh, and even before revelation his people called him **Al-Ameen (الأَمِين)**, “the Trustworthy.”")
                    }

                    Section(header: ArticleHeader("THE FIRST REVELATION")) {
                        ArticleParagraph(articleMarkdown: "At forty, in the cave of **Hira (حِرَاء)**, the angel **Jibreel (جِبرِيل)** brought him the first revelation:")
                        ScriptureQuote(quran: "96:1")
                    }

                    Section(header: ArticleHeader("THE MAKKAN PERIOD")) {
                        ArticleParagraph(articleMarkdown: "For about thirteen years in Makkah he called people to **Tawheed (تَوحِيد)**, the worship of Allah alone, and bore persecution with patience.")
                    }

                    Section(header: ArticleHeader("THE HIJRAH")) {
                        ArticleParagraph(articleMarkdown: "In 622 CE he made the **Hijrah (هِجرَة)** to **Madinah (المَدِينَة)**, and the Hijri calendar begins from it.")
                    }

                    Section(header: ArticleHeader("THE MADINAN PERIOD")) {
                        ArticleParagraph(articleMarkdown: "In Madinah he built the first Muslim community, tested at **Badr (بَدر)** and **Uhud (أُحُد)**, and in 630 CE Makkah was entered peacefully.")
                    }

                    Section(header: ArticleHeader("THE FAREWELL AND HIS PASSING")) {
                        ArticleParagraph(verbatim: "After the Farewell Pilgrimage of 10 AH he passed away in Madinah in 11 AH / 632 CE, aged sixty-three, leaving the Quran and his Sunnah as guidance.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("BEFORE PROPHETHOOD")) {
                        ArticleParagraph(articleMarkdown: "He was born in the year 570 CE in **Makkah (مَكَّة)**, among the tribe of Quraysh. His father Abdullah died before his birth and his mother Aaminah when he was six, so he was raised by his grandfather Abd al-Muttalib and then his uncle Abu Taalib.")

                        ArticleParagraph(articleMarkdown: "Even before revelation his people called him **Al-Ameen (الأَمِين)**, “the Trustworthy,” for his honesty and noble character. At about twenty-five he married **Khadeejah (خَدِيجَة)** (may Allah be pleased with her).")
                    }

                    Section(header: ArticleHeader("THE FIRST REVELATION")) {
                        ArticleParagraph(articleMarkdown: "At the age of forty, while worshipping alone in the cave of **Hira (حِرَاء)** near Makkah, the angel **Jibreel (جِبرِيل)** brought him the first revelation, beginning with **Iqra (اِقرَأ)**:")
                        ScriptureQuote(quran: "96:1")

                        ArticleParagraph(verbatim: "This began twenty-three years of the revelation of the Quran, which continued until shortly before his death.")
                    }

                    Section(header: ArticleHeader("THE MAKKAN PERIOD")) {
                        ArticleParagraph(articleMarkdown: "For about thirteen years in Makkah he called people to **Tawheed (تَوحِيد)**, the worship of Allah alone, through his **Dawah (دَعوَة)**, his call to Islam. He and the early believers met mockery, boycott, and severe persecution, yet remained patient.")

                        ArticleParagraph(articleMarkdown: "In this period he was honoured with the **Isra and Mi‘raaj (الإِسرَاء وَالمِعرَاج)**, the night journey to Jerusalem and the ascension through the heavens, during which the five daily prayers were made obligatory.")
                    }

                    Section(header: ArticleHeader("THE HIJRAH")) {
                        ArticleParagraph(articleMarkdown: "In 622 CE, by Allah’s command, the Prophet (peace be upon him) made the **Hijrah (هِجرَة)**, the migration from Makkah to **Madinah (المَدِينَة)**. This event was so pivotal that the Islamic (Hijri) calendar begins from it.")
                    }

                    Section(header: ArticleHeader("THE MADINAN PERIOD")) {
                        ArticleParagraph(verbatim: "In Madinah he established the first Muslim community: building the mosque, joining the emigrants (Muhaajiroon) and the helpers (Ansaar) in brotherhood, and governing by revelation.")

                        ArticleParagraph(articleMarkdown: "The community was tested and defended in major events such as **Badr (بَدر)**, **Uhud (أُحُد)**, and the Battle of the Trench, **Al-Khandaq (الخَندَق)**. The **Treaty of Hudaybiyah (الحُدَيبِيَة)** opened the way for peace, and in 630 CE Makkah was entered peacefully and cleansed of idols.")
                    }

                    Section(header: ArticleHeader("THE FAREWELL AND HIS PASSING")) {
                        ArticleParagraph(articleMarkdown: "In 10 AH he performed the Farewell Pilgrimage, **Hajjat al-Wada (حَجَّة الوَدَاع)**, and delivered his Farewell Sermon before a great gathering of believers.")

                        ArticleParagraph(verbatim: "He passed away in Madinah in 11 AH / 632 CE, at the age of sixty-three, and is buried there. He left behind the Quran and his Sunnah as guidance for all who came after.")
                    }

                    Section(header: ArticleHeader("HIS CHARACTER")) {
                        ArticleParagraph(articleMarkdown: "He was sent as a mercy to all creation, **Rahmatan lil-Aalameen (رَحمَة لِلعَالَمِين)**.")

                        ScriptureQuote(quran: "21:107")

                        ArticleParagraph(verbatim: "When Aa’ishah (may Allah be pleased with her) was asked about his character, she said:")
                        ScriptureQuote(hadith: "muslim:746a", cite: "Saheeh Muslim 746", arabic: 232...241, english: 293...303)
                        ArticleParagraph(verbatim: "He embodied its teachings in the most complete way.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Studying the Seerah shows how revelation was lived and deepens a Muslim's love and following of the Prophet, the best example for all people.")
                }

                ArticleSourcesSection(article: "SeerahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Seerah")
        .englishArticle().selectableArticleList(article: "SeerahView")
    }
}

struct TafsirView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Tafseer is the explanation of the Quran's meanings, soundest when the Quran is explained by the Quran, the Sunnah, and the understanding of the early generations.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Tafseer (تَفسِير)** is the explanation and clarification of the meanings of the Quran: its words, rulings, and wisdoms. Its scholar is called a **Mufassir (مُفَسِّر)**.")

                    ArticleParagraph(articleMarkdown: "Its blameworthy counterpart is **Tafseer bir-Ra’y (تَفسِير بِالرَّأي)** in the censured sense: interpreting the Quran by mere opinion, away from its established meaning and the understanding of the Salaf.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                    ScriptureQuote(quran: "38:29", words: 0...5)
                }

                Section(header: ArticleHeader("HOW THE QURAN IS EXPLAINED")) {
                    ArticleParagraph(articleMarkdown: "The soundest tafseer is **bil-ma’thoor (بِالمَأثُور)**, by transmission, and it proceeds in order:")

                    ArticleParagraph(articleMarkdown: "**1. The Quran by the Quran**: a matter left general in one place is often clarified in another.")

                    ArticleParagraph(articleMarkdown: "**2. The Quran by the Sunnah**: the Prophet (peace be upon him) explained what was revealed to him.")
                    ScriptureQuote(quran: "16:44", words: 2...9)

                    ArticleParagraph(articleMarkdown: "**3. The statements of the Companions (Sahaabah)**: they witnessed the revelation and knew its context best.")

                    ArticleParagraph(articleMarkdown: "**4. The statements of the Successors (Taabi‘oon)**: the students of the Companions, followed by explanation through the Arabic language.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("CONDITIONS OF THE MUFASSIR")) {
                        ArticleParagraph(verbatim: "Explaining the Quran is not by desire or guesswork. It requires sound belief, knowledge of the Arabic language, the Sunnah, the sayings of the early scholars, and the sciences of the Quran.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) warned:")

                        ScriptureQuote(quran: "17:36")

                        ArticleParagraph(verbatim: "And He counted among what He has forbidden:")
                        ScriptureQuote(quran: "7:33", words: 22...28)

                        ArticleParagraph(verbatim: "Claiming that the Prophet (peace and blessings be upon him) explained an ayah in a way he did not is a lie against him, and he said:")
                        ScriptureQuote(hadith: "bukhari:108", cite: "Saheeh al-Bukhaari 108", arabic: 27...34, english: 20...35)
                    }

                    Section(header: ArticleHeader("WELL-KNOWN WORKS")) {
                        ArticleParagraph(articleMarkdown: "Among the most trusted classical works of tafseer are those of **at-Tabari (الطَّبَرِي)**, **Ibn Katheer (اِبن كَثِير)**, and **al-Baghawi (البَغَوِي)**, and among later concise works, that of **as-Sa‘di (السَّعدِي)**. They are prized for explaining the Quran by the Quran, the Sunnah, and the understanding of the early generations.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("True Tafseer rests on knowledge, not opinion; through it the guidance of the Quran becomes clear and livable for every generation.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleParagraph(articleMarkdown: "**Asbaab an-Nuzool (أَسبَاب النُّزُول)**: the reasons or occasions of revelation, i.e. the events a verse was revealed about.")

                        ArticleParagraph(articleMarkdown: "**Muhkam (مُحكَم)**: verses clear and decisive in meaning; **Mutashaabih (مُتَشَابِه)**: verses whose full meaning is not entirely apparent, referred back to the clear ones.")

                        ArticleParagraph(articleMarkdown: "**An-Naasikh wal-Mansookh (النَّاسِخ وَالمَنسُوخ)**: the abrogating and abrogated; a later ruling that replaces an earlier one within the revelation.")
                    }
                }

                ArticleSourcesSection(article: "TafsirView")
            }
            .themedListRowBackground()
        }
        .navigationTitle(AppLanguage.article("Tafseer"))
        .englishArticle().selectableArticleList(article: "TafsirView")
    }
}

struct FiqhAqeedahManhajView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: aqeedah is what you believe, fiqh is what you do, and manhaj is how you understand and derive both from revelation.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("AQEEDAH (BELIEF)")) {
                        ArticleParagraph(articleMarkdown: "**Aqeedah (عَقِيدَة)** is creed: the beliefs the heart is bound to with certainty. Its core is **Tawheed (تَوحِيد)**, singling out Allah alone in worship, lordship, and His names and attributes.")

                        ArticleParagraph(articleMarkdown: "It includes the six pillars of faith: belief in Allah, His angels, His books, His messengers, the Last Day, and **Al-Qadar (القَدَر)**, the divine decree. Aqeedah does not change with time or place and is one for all the believers.")
                    }

                    Section(header: ArticleHeader("FIQH (JURISPRUDENCE)")) {
                        ArticleParagraph(articleMarkdown: "**Fiqh (فِقه)** is the understanding of the practical rulings of Islam derived from the Quran and Sunnah: the “how” of worship, **Ibaadah (عِبَادَة)**, and of dealings, **Muaamalaat (مُعَامَلَات)**, such as prayer, fasting, trade, and marriage.")

                        ArticleParagraph(articleMarkdown: "Because deriving detailed rulings involves **Ijtihaad (اِجتِهَاد)**, qualified scholarly effort, sincere scholars sometimes differ, and such differences are excused; they are not division in the religion.")
                    }

                    Section(header: ArticleHeader("MANHAJ (METHODOLOGY)")) {
                        ArticleParagraph(articleMarkdown: "**Manhaj (مَنهَج)** is methodology: the path by which one understands, prioritizes, and applies the religion, and deals with knowledge and people.")

                        ArticleParagraph(articleMarkdown: "The sound manhaj is to take the Quran and the authentic Sunnah upon the understanding of the **Salaf (السَّلَف)**, the first righteous generations, rather than by later opinions that contradict them.")
                    }

                    Section(header: ArticleHeader("HOW THEY RELATE")) {
                        ArticleParagraph(verbatim: "Aqeedah is the foundation, fiqh is the practice built upon it, and manhaj is the method that keeps both tied to revelation as it was first understood.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "Three words describe how a Muslim believes, acts, and understands the religion: **Aqeedah (عَقِيدَة)**, **Fiqh (فِقه)**, and **Manhaj (مَنهَج)**.")

                        ArticleParagraph(verbatim: "In short: aqeedah is what you believe, fiqh is what you do, and manhaj is how you understand and derive both.")
                    }

                    Section(header: ArticleHeader("AQEEDAH (BELIEF)")) {
                        ArticleParagraph(articleMarkdown: "**Aqeedah (عَقِيدَة)** is creed: the beliefs the heart is bound to with certainty. Its core is **Tawheed (تَوحِيد)**, singling out Allah alone in worship, lordship, and His names and attributes.")

                        ArticleParagraph(articleMarkdown: "It includes the six pillars of faith: belief in Allah, His angels, His books, His messengers, the Last Day, and **Al-Qadar (القَدَر)**, the divine decree. Aqeedah does not change with time or place and is one for all the believers.")

                        ScriptureQuote(quran: "2:285", words: 0...13)
                    }

                    Section(header: ArticleHeader("FIQH (JURISPRUDENCE)")) {
                        ArticleParagraph(articleMarkdown: "**Fiqh (فِقه)** is the understanding of the practical rulings of Islam derived from the Quran and Sunnah: the “how” of worship, **Ibaadah (عِبَادَة)**, and of dealings, **Muaamalaat (مُعَامَلَات)**, such as prayer, fasting, trade, and marriage.")

                        ArticleParagraph(articleMarkdown: "Because deriving detailed rulings involves **Ijtihaad (اِجتِهَاد)**, qualified scholarly effort, sincere scholars sometimes differ. This is the source of the accepted schools of fiqh, and such differences are excused and even rewarded (Saheeh al-Bukhaari 7352); they are not division in the religion.")
                        ScriptureQuote(hadith: "bukhari:7352", cite: "Saheeh al-Bukhaari 7352, Saheeh Muslim 1716", arabic: 46...60, english: 7...71)
                    }

                    Section(header: ArticleHeader("MANHAJ (METHODOLOGY)")) {
                        ArticleParagraph(articleMarkdown: "**Manhaj (مَنهَج)** is methodology: the path by which one understands, prioritizes, and applies the religion, and deals with knowledge and people.")

                        ArticleParagraph(articleMarkdown: "The sound manhaj is to take the Quran and the authentic Sunnah upon the understanding of the **Salaf (السَّلَف)**, the first righteous generations, rather than by later opinions that contradict them.")

                        ScriptureQuote(quran: "9:100", words: 0...12)
                    }

                    Section(header: ArticleHeader("HOW THEY RELATE")) {
                        ArticleParagraph(verbatim: "Aqeedah is the foundation, fiqh is the practice built upon it, and manhaj is the method that keeps both tied to revelation as it was first understood.")

                        ArticleParagraph(verbatim: "The believers may differ in points of fiqh while remaining one in aqeedah and united upon a sound manhaj.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("United in creed, allowing valid differences in jurisprudence, and following the method of the first generations: this is the balance a Muslim strives for.")
                }

                ArticleSourcesSection(article: "FiqhAqeedahManhajView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Fiqh, Aqeedah, Manhaj")
        .englishArticle().selectableArticleList(article: "FiqhAqeedahManhajView")
    }
}

#Preview {
    AlIslamPreviewContainer {
        PillarsView()
    }
}

