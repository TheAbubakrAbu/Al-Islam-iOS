import SwiftUI

struct HaramView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Masjid al-Haram in Makkah is the holiest mosque in Islam. It surrounds the Kaaba, the House of Allah and the Qiblah toward which all Muslims pray.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Masjid Al-Haram (ٱلمَسجِدُ ٱلحَرَام), or “The Sacred Mosque,“ is located in **Makkah (مَكَّة)**, Saudi Arabia. It is the largest mosque in the world and surrounds the **Ka'bah** (ٱلكَعبَة), the holiest site in Islam. The Ka'bah is also known as “The House of Allah“ (بَيتُ ٱللَّه).")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(quran: "2:125", words: 0...5)

                    Text(articleMarkdown: "Masjid Al-Haram is the destination for **Hajj (حَجّ)** and **Umrah (عُمرَة)**, two pivotal acts of worship in Islam. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(hadith: "ibnmajah:1406", cite: "Sunan Ibn Majah 1406; graded sahih by al-Albani", arabic: 32...54, english: 0...30)
                }

                Section(header: ArticleHeader("SIGNIFICANCE OF THE KA'BAH")) {
                    Text(articleMarkdown: "The **Ka'bah** (ٱلكَعبَة), meaning “The Cube,“ is the symbolic House of Allah. It serves as the **Qiblah** (قِبلَةٌ) (direction of prayer) for Muslims worldwide. Every prayer offered by a Muslim is directed toward the Ka'bah.")
                        .font(.body)

                    Text(articleMarkdown: "The Ka'bah was built by **Prophet Ibrahim** (Abraham, peace be upon him) and his son **Prophet Isma'il** (Ishmael, peace be upon him) as a place of monotheistic worship. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(quran: "2:127")

                    Text(articleMarkdown: "The **Black Stone** (ٱلحَجَرُ ٱلأَسوَد, Hajar Al-Aswad), embedded in one corner of the Ka'bah, is a sacred relic dating back to the time of Prophet Ibrahim (peace be upon him). Touching or kissing it during **Tawaf** is a Sunnah, but not obligatory.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE WELL OF ZAMZAM")) {
                    Text(articleMarkdown: "The **Well of Zamzam** (بِئرُ زَمزَم) is located within Masjid Al-Haram. This miraculous water source was provided by Allah for **Hajar** (may Allah be pleased with her) and her son **Isma'il** (peace be upon him) when they were left in the barren desert. The well continues to flow abundantly to this day.")
                        .font(.body)

                    Text(verbatim: "Zamzam water is blessed: the Prophet (peace and blessings be upon him) said of it, “It is blessed; it is food that satisfies” (Sahih Muslim 2473).").font(.body)
                }

                Section(header: ArticleHeader("SPIRITUAL REWARDS AND IMPORTANCE")) {
                    Text(articleMarkdown: "1. **Multiplied Rewards**: Praying in Masjid Al-Haram is rewarded 100,000 times more than praying elsewhere.")
                        .font(.body)
                    Text(articleMarkdown: "2. **Forgiveness of Sins**: Performing Hajj or Umrah with sincerity cleanses one’s sins. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(hadith: "bukhari:1521", cite: "Sahih al-Bukhari 1521", arabic: 31...41, english: 4...41)
                    Text(articleMarkdown: "3. **Unity of the Ummah**: Millions of Muslims from diverse cultures and backgrounds gather in Masjid Al-Haram, symbolizing the unity and equality of the Muslim Ummah under the worship of Allah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("QURANIC VERSES ABOUT MAKKAH")) {
                    Text(verbatim: "Allah mentions the sanctity of Makkah and Masjid Al-Haram in several verses:").font(.body)
                    ScriptureQuote(quran: "3:96")
                    ScriptureQuote(quran: "2:125", words: 0...5)
                }

                Section(header: ArticleHeader("MASJID AL-HARAM")) {
                    Image("Al Haram")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(24)
                            #if os(iOS)
                            .focusableImage("Al Haram", title: "Masjid al-Haram")
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
                    Text(verbatim: "A single prayer here equals a hundred thousand elsewhere. It is the heart of Hajj and Umrah, where the whole Ummah gathers as equals before Allah.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "HaramView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "HaramView")
        .navigationTitle("Masjid Al-Haram")
    }
}

struct NabawiView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Masjid an-Nabawi in Madinah is the Prophet's own mosque and the second holiest in Islam, home to the Rawdah and his resting place.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Masjid An-Nabawi (ٱلمَسجِد ٱلنَّبَوِي), or “The Prophet’s Mosque,“ is located in Madinah, Saudi Arabia. Originally known as Yathrib, the city became known after the migration (Hijrah) of Prophet Muhammad (peace and blessings be upon him) as **Al-Madinah (ٱلمَدِينَة)**, “The City,” and as **Tabah (طَابَة)**, the name the Prophet said Allah gave it (Sahih Muslim 1385); **Al-Madinah Al-Munawwarah (ٱلمَدِينَة ٱلمُنَوَّرَة)**, “The Illuminated City,” is a later honorific.")
                        .font(.body)

                    Text(verbatim: "This mosque, built by the Prophet (peace and blessings be upon him) in 622 CE, is the second holiest site in Islam after Masjid Al-Haram. The Prophet (peace and blessings be upon him) made it a center of worship, governance, and community life.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(hadith: "bukhari:1190", cite: "Sahih Bukhari 1190", arabic: 41...53, english: 4...20)
                }

                Section(header: ArticleHeader("SIGNIFICANCE")) {
                    Text(articleMarkdown: "Masjid An-Nabawi is home to the **Rawdah (ٱلرَّوضَة)**, an area between the Prophet's pulpit and his house, which he described as a garden from the gardens of Paradise. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1196", cite: "Sahih al-Bukhari 1196", arabic: 34...44, english: 4...18)

                    Text(verbatim: "The mosque also contains the grave of the Prophet Muhammad (peace and blessings be upon him) and his companions Abu Bakr As-Siddiq and Umar ibn Al-Khattab (may Allah be pleased with them). It is from the Sunnah to send salaam upon him when you are there.")
                        .font(.body)
                }

                Section(header: ArticleHeader("A WARNING AGAINST SHIRK")) {
                    Text(articleMarkdown: "This must be clear, because it is where people fall. You do **not** pray to the Prophet (peace and blessings be upon him). You do **not** pray facing his grave. You do not ask him for anything and you do not seek help or intercession from him: that is **shirk (شِرك)**, associating partners with Allah, the one sin Allah does not forgive if a person dies upon it. Praying toward the grave, circling it, or touching it seeking blessing is forbidden and a doorway to shirk: the Prophet (peace and blessings be upon him) said, “Do not sit on graves and do not pray toward them” (Sahih Muslim 972).")
                        .font(.body)

                    Text(verbatim: "Duaa is worship, and worship belongs to Allah alone:")
                        .font(.body)
                    ScriptureQuote(quran: "72:18")

                    Text(verbatim: "When you pray in Masjid An-Nabawi, you face the Qiblah, towards the Kaaba in Makkah, exactly as you would anywhere else on earth. The grave happens to lie in that direction from parts of the mosque; that is a fact of geography, not a thing to be prayed towards.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) himself warned against precisely this, in his final illness:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:435", cite: "Sahih al-Bukhari 435, Sahih Muslim 531", arabic: 48...56, english: 37...67)

                    Text(verbatim: "He also said:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:2042", cite: "Sunan Abi Dawud 2042; graded sahih by al-Albani", arabic: 30...44, english: 4...33)

                    Text(verbatim: "So love him, follow him, and send salaah and salaam upon him abundantly. But direct every act of worship to Allah alone. That is what he taught, and honouring him means obeying him.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SPIRITUAL BENEFITS")) {
                    Text(articleMarkdown: "1. **Multiplied Rewards**: Prayers in Masjid An-Nabawi are rewarded 1,000 times more than prayers in other mosques (except Masjid Al-Haram).")
                        .font(.body)
                    Text(articleMarkdown: "2. **Connection to the Prophet**: Standing in a place where the Prophet Muhammad (peace and blessings be upon him) worshipped and led his companions strengthens one’s faith and love for him.")
                        .font(.body)
                    Text(articleMarkdown: "3. **Rawdah Visit**: Visiting the Rawdah and praying there is considered highly virtuous.")
                        .font(.body)
                }

                Section(header: ArticleHeader("QURANIC VERSES ABOUT THE MOSQUE")) {
                    Text(verbatim: "Allah emphasizes the sanctity of mosques, particularly those established on righteousness. He says in the Quran:")
                        .font(.body)
                    ScriptureQuote(quran: "9:108", words: 4...14)
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
                    Text(verbatim: "A prayer here equals a thousand elsewhere. It was the Prophet's center of worship and community, and visiting it deepens a believer's love for him.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "NabawiView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "NabawiView")
        .navigationTitle("Masjid An-Nabawi")
    }
}

struct AqsaView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Masjid al-Aqsa in Jerusalem is the third holiest mosque, the first Qiblah, and the destination of the Prophet's Night Journey (Isra and Mi'raj).")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Masjid Al-Aqsa (ٱلمَسجِد ٱلأَقصَىٰ), meaning “The Farthest Mosque,“ is located in Jerusalem, Palestine, within a compound known as **Al-Haram Ash-Sharif (ٱلحَرَم ٱلشَّرِيف)**, or “The Noble Sanctuary.“ It is the third holiest mosque in Islam after Masjid Al-Haram in Makkah and Masjid An-Nabawi in Madinah.")
                        .font(.body)

                    Text(verbatim: "Masjid Al-Aqsa holds immense historical and spiritual significance in Islam. Allah (Glorified and Exalted be He) mentions it in the Quran:").font(.body)
                    ScriptureQuote(quran: "17:1")

                    Text(articleMarkdown: "It was the first Qiblah (direction of prayer) for Muslims before it was changed to the Ka'bah in Makkah, and it was the destination of the Prophet Muhammad’s (peace and blessings be upon him) Night Journey, **Isra (الإِسرَاء)**, before his Ascension, **Mi'raj (المِعرَاج)**.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SPIRITUAL SIGNIFICANCE")) {
                    Text(articleMarkdown: "1. **First Qiblah**: Muslims initially faced Masjid Al-Aqsa during their prayers, highlighting its significance from the earliest days of Islam.").font(.body)
                    Text(articleMarkdown: "2. **Al-Isra wa al-Mi'raj (الإِسرَاء وَالمِعرَاج)**: It was the destination of the miraculous Night Journey of the Prophet Muhammad (peace and blessings be upon him), during which he led all prophets in prayer before ascending to the heavens.").font(.body)
                    Text(articleMarkdown: "3. **Land of Blessings**: The Quran describes the surroundings of Masjid Al-Aqsa as a blessed land. Allah says:").font(.body)
                    ScriptureQuote(quran: "21:71")
                }

                Section(header: ArticleHeader("HISTORICAL AND RELIGIOUS IMPORTANCE")) {
                    Text(verbatim: "Masjid Al-Aqsa is a place of worship for many prophets, including Ibrahim (Abraham), Dawud (David), and Sulaiman (Solomon) (peace be upon them). Prophet Muhammad (peace and blessings be upon him) led the prophets in prayer there during the Night Journey. He said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:172", cite: "Sahih Muslim 172", arabic: 77...131, english: 67...156)

                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(hadith: "bukhari:1189", cite: "Sahih al-Bukhari 1189", arabic: 25...41, english: 4...31)
                }

                Section(header: ArticleHeader("REWARDS OF PRAYING IN MASJID AL-AQSA")) {
                    Text(verbatim: "Prayer in the three sacred mosques carries immense reward. What is established is the authentic narration in which the Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(hadith: "bukhari:1190", cite: "Sahih al-Bukhari 1190", arabic: 41...53, english: 4...20)

                    Text(verbatim: "A report giving a specific figure for Masjid Al-Aqsa (fifty thousand prayers) is narrated in Sunan Ibn Majah 1413, but its chain is weak (da'if), and its figure for Masjid An-Nabawi contradicts the authentic hadith above, so it is not relied upon.").font(.body)
                }

                Section(header: ArticleHeader("STRUCTURE AND FEATURES")) {
                    Text(articleMarkdown: "Masjid Al-Aqsa is part of a larger compound that includes the **Dome of the Rock (قُبَّة ٱلصَّخرَة)**, the oldest Islamic architectural monument. The entire compound is considered sacred by Muslims, and the name Masjid Al-Aqsa often refers to the entire Noble Sanctuary.")
                        .font(.body)

                    Text(verbatim: "The mosque’s architecture and location reflect centuries of Islamic devotion and heritage.")
                        .font(.body)
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
                    Text(verbatim: "Blessed by Allah and honored by the prophets, Masjid al-Aqsa remains one of the three mosques to which travel for worship is specially encouraged.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "AqsaView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "AqsaView")
        .navigationTitle("Masjid Al-Aqsa")
    }
}

import SwiftUI

struct WudhuView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Wudhu is the minor ablution. It is a condition for the validity of the prayer, and it wipes away sins as it is performed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Wudhu (وُضُوء)**, from the root **w-d-a (و ض أ)**, meaning cleanliness and radiance, is the purification performed before **Salah (صَلَاة)**, before touching the Quran, and before **Tawaf (طَوَاف)** around the Kaaba.")
                        .font(.body)
                    Text(verbatim: "Without it, the prayer is not accepted. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:135", cite: "Sahih al-Bukhari 135, Sahih Muslim 225", arabic: 30...36, english: 4...24)
                }

                Section(header: ArticleHeader("THE COMMAND IN THE QURAN")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(quran: "5:6", words: 0...16)
                    Text(verbatim: "This one verse names the four obligatory parts: the face, the arms to the elbows, wiping the head, and the feet to the ankles. The intention is a condition, and the order and continuity of the washing are required; everything else in the description below is Sunnah, following the way the Prophet (peace and blessings be upon him) actually did it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW TO MAKE WUDHU")) {
                    Text(articleMarkdown: "1. Make the **niyyah (نِيَّة)**, the intention, in the heart. It is not said aloud.")
                        .font(.body)
                    Text(articleMarkdown: "2. Say **“Bismillah“ (بِسمِ اللهِ)**.")
                        .font(.body)
                    Text(articleMarkdown: "3. Wash both **hands** up to the wrists, three times.")
                        .font(.body)
                    Text(articleMarkdown: "4. **Rinse the mouth** and **sniff water into the nose** and blow it out, three times. Use the right hand to take the water and the left to blow the nose.")
                        .font(.body)
                    Text(articleMarkdown: "5. Wash the **face** three times, from the hairline to under the chin and from ear to ear. If you have a thick beard, run wet fingers through it.")
                        .font(.body)
                    Text(articleMarkdown: "6. Wash the **right arm** to and including the elbow, three times. Then the **left arm**, three times.")
                        .font(.body)
                    Text(articleMarkdown: "7. **Wipe the head once**, not three times: pass wet hands from the front of the head to the back and return them to the front. Then, with the same water, **wipe the ears**, index fingers inside and thumbs behind.")
                        .font(.body)
                    Text(articleMarkdown: "8. Wash the **right foot** to and including the ankle, three times, running the fingers between the toes. Then the **left foot**, three times.")
                        .font(.body)
                    Text(articleMarkdown: "9. Then say: **“Ash-hadu an la ilaha illa Allah, wahdahu la sharika lah, wa ash-hadu anna Muhammadan abduhu wa rasuluh.“**")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) said about that closing testimony:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:234a", cite: "Sahih Muslim 234", arabic: 111...144, english: 116...171)

                    Text(verbatim: "Do not be wasteful with water. Anas (may Allah be pleased with him) described how little the Prophet (peace and blessings be upon him) used:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:201", cite: "Sahih al-Bukhari 201", arabic: 14...31, english: 0...30)
                    Text(verbatim: "A mudd is roughly what two cupped hands hold, about two thirds of a litre. The principle itself is explicit in the Quran:")
                        .font(.body)
                    ScriptureQuote(quran: "7:31", words: 8...15)
                }

                Section(header: ArticleHeader("WHAT BREAKS WUDHU")) {
                    Text(verbatim: "• Anything that exits from the front or back passage: urine, stool, or wind.")
                        .font(.body)
                    Text(verbatim: "• Deep sleep, in which a person loses awareness.")
                        .font(.body)
                    Text(verbatim: "• Loss of consciousness, whether from fainting, intoxication, or illness.")
                        .font(.body)
                    Text(verbatim: "• Touching the private parts directly with the hand, without a barrier.")
                        .font(.body)
                    Text(verbatim: "• Eating camel meat. A man asked the Prophet (peace and blessings be upon him) whether he should make wudhu after eating camel meat, and he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:360a", cite: "Sahih Muslim 360", arabic: 57...61, english: 55...61)
                    Text(verbatim: "Doubt alone does not break it. If you are certain you had wudhu and merely suspect you lost it, you still have it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE REWARD")) {
                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:244", cite: "Sahih Muslim 244", arabic: 45...113, english: 4...104)

                    Text(verbatim: "He also said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:251a", cite: "Sahih Muslim 251", arabic: 35...69, english: 6...62)

                    Text(verbatim: "And he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:136", cite: "Sahih al-Bukhari 136", arabic: 37...53, english: 24...57)

                    Text(verbatim: "It is also from the Sunnah to make wudhu before sleeping.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Purity is a condition of prayer and a means of erasing sins. Performed with intention and in the way the Prophet performed it, wudhu is an act of worship in itself.")
                        .font(.body)

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
        .selectableArticleList(article: "WudhuView")
        .navigationTitle("How to Make Wudhu")
    }
}

struct GhuslView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Ghusl is the full-body wash that lifts major ritual impurity. Until it is performed, the prayer cannot be prayed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Ghusl (غُسل)**, from the root **gh-s-l (غ س ل)**, to wash, is a complete washing of the body with the intention of lifting major ritual impurity, **Janabah (جَنَابَة)**.")
                        .font(.body)
                    Text(verbatim: "Where wudhu washes specific limbs, ghusl reaches the whole body. Ghusl also removes the need for a separate wudhu, so long as nothing has broken it during the wash.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHEN GHUSL IS OBLIGATORY")) {
                    Text(verbatim: "• After marital relations, whether or not there is emission.")
                        .font(.body)
                    Text(verbatim: "• After the emission of maniy (sexual fluid) with desire, whether awake or from a wet dream.")
                        .font(.body)
                    Text(articleMarkdown: "• At the end of **menstruation (حَيض)**.")
                        .font(.body)
                    Text(articleMarkdown: "• At the end of **postpartum bleeding (نِفَاس)**.")
                        .font(.body)
                    Text(verbatim: "• Upon accepting Islam.")
                        .font(.body)
                    Text(verbatim: "• Upon death, the deceased is washed by the living.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHEN GHUSL IS RECOMMENDED")) {
                    Text(articleMarkdown: "• Before the **Jumuah (جُمُعَة)** prayer.")
                        .font(.body)
                    Text(articleMarkdown: "• Before the two **Eid** prayers.")
                        .font(.body)
                    Text(articleMarkdown: "• Before entering **Ihram (إِحرَام)** for Hajj or Umrah.")
                        .font(.body)
                    Text(verbatim: "• After washing a deceased person.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE COMMAND IN THE QURAN")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(quran: "5:6", words: 17...20)
                    Text(verbatim: "And He says:")
                        .font(.body)
                    ScriptureQuote(quran: "4:43", words: 0...18)
                }

                Section(header: ArticleHeader("HOW TO MAKE GHUSL")) {
                    Text(verbatim: "This is the way described by Aisha and Maymunah (may Allah be pleased with them), who saw the Prophet (peace and blessings be upon him) perform it (Sahih al-Bukhari 248, 249, 257). Aisha said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:248", cite: "Sahih al-Bukhari 248", arabic: 26...60, english: 0...59)

                    Text(articleMarkdown: "1. Make the **niyyah (نِيَّة)** in the heart to lift the state of janabah.")
                        .font(.body)
                    Text(articleMarkdown: "2. Say **“Bismillah“**, and wash both **hands** three times.")
                        .font(.body)
                    Text(articleMarkdown: "3. Wash the **private parts** and any impurity from the body with the left hand, then wash the hand.")
                        .font(.body)
                    Text(articleMarkdown: "4. Perform a **complete wudhu**, as you would for prayer.")
                        .font(.body)
                    Text(articleMarkdown: "5. Pour water over the **head three times**, working the fingers through the hair so the water reaches the roots of every hair.")
                        .font(.body)
                    Text(articleMarkdown: "6. Pour water over the **right side** of the body, then the **left side**, ensuring the water reaches every part: under the arms, inside the navel, behind the ears, between the toes.")
                        .font(.body)
                    Text(articleMarkdown: "7. Move from your place and **wash the feet**, if you did not wash them during the wudhu.")
                        .font(.body)

                    Text(articleMarkdown: "**The obligation is only two things:** the intention, and that water reaches every part of the body including the mouth and nose. The order and the repetition above are Sunnah. If a person simply immerses fully in water with the intention, the ghusl is valid.")
                        .font(.body)

                    Text(articleMarkdown: "Women do **not** need to undo braided hair for the ghusl of janabah, so long as the water reaches the roots. Umm Salamah (may Allah be pleased with her) asked about this, and the Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:330a", cite: "Sahih Muslim 330", arabic: 59...72, english: 34...59)
                }

                Section(header: ArticleHeader("IF THERE IS NO WATER: TAYAMMUM")) {
                    Text(articleMarkdown: "If water cannot be found, or using it would cause harm or illness, then **Tayammum (تَيَمُّم)**, dry purification, takes its place for both wudhu and ghusl. Allah says in the same verse:")
                        .font(.body)
                    ScriptureQuote(quran: "5:6", words: 36...45)
                    Text(verbatim: "Strike clean earth once with both palms, then wipe the face, then wipe the hands. That is all.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Ghusl lifts major impurity and returns a person to the state in which they may pray. Its obligation is simple: intend it, and let the water reach all of you.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "GhuslView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "GhuslView")
        .navigationTitle("How to Make Ghusl")
    }
}

struct JumuahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Jumuah is the Friday congregational prayer that replaces Dhuhr: a sermon followed by two rak'ah, obligatory on Muslim men who are able.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Jumuah (جُمُعَة) comes from the root **j-m-a (ج م ع)**, meaning to gather or congregate. It refers to the Friday congregational prayer that replaces Dhuhr.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(quran: "62:9")

                    Text(articleMarkdown: "Jumuah prayer consists of a sermon (**Khutbah, خُطبَة**) followed by a two-rak’ah Salah led by the Imam. It is obligatory for Muslim men who can attend, though it is not obligatory for women. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:1067", cite: "Sunan Abi Dawud 1067; graded sahih by al-Albani", arabic: 34...51, english: 4...28)

                    Text(verbatim: "If Jumuah is missed at the mosque, one performs the full Dhuhr prayer (4 rak’ahs).")
                        .font(.body)
                }

                Section(header: ArticleHeader("IMPORTANCE")) {
                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(hadith: "muslim:854a", cite: "Sahih Muslim 854", arabic: 30...45, english: 0...30)

                    Text(verbatim: "Friday is considered the best day of the week in Islam. It unites the community, strengthens social bonds, and serves as a weekly reminder of our responsibilities toward Allah (Glorified and Exalted be He) and humanity.")
                        .font(.body)
                }

                Section(header: ArticleHeader("RECOMMENDED PRACTICES")) {
                    Text(verbatim: "Muslims are encouraged to engage in specific acts of worship on Jumuah:")
                        .font(.body)

                    Text(articleMarkdown: "1. **Reciting Surah Al-Kahf (سُورَة ٱلكَهف):** The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(text: "“Whoever reads Surah Al-Kahf on Friday, a light will shine for him between the two Fridays” (al-Hakim 2/368 and al-Bayhaqi; graded sahih by al-Albani, Sahih al-Jami' 6470).", arabic: "مَن قَرَأَ سُورَةَ الكَهفِ فِي يَومِ الجُمُعَةِ أَضَاءَ لَهُ مِنَ النُّورِ مَا بَينَ الجُمُعَتَينِ", dimmed: true)

                    Text(articleMarkdown: "2. **Sending Salawat on the Prophet (peace and blessings be upon him):**")
                        .font(.body)

                    ScriptureQuote(hadith: "abudawud:1047", cite: "Sunan Abi Dawud 1047; graded sahih by al-Albani", arabic: 33...56, english: 4...53)

                    ScriptureQuote(hadith: "muslim:408", cite: "Sahih Muslim 408", arabic: 32...39, english: 6...16)

                    Text(articleMarkdown: "3. **Making Dua (Supplication)**: There is a special hour on Friday during which all supplications are accepted. The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(hadith: "nasai:1389", cite: "Sunan an-Nasa'i 1389; graded sahih by al-Albani", arabic: 53...73, english: 6...38)
                }

                Section(header: ArticleHeader("ETIQUETTE")) {
                    Text(verbatim: "Observing proper etiquette during Jumuah is essential:")
                        .font(.body)

                    Text(verbatim: "1. Arrive early to the mosque and sit attentively during the Khutbah.")
                        .font(.body)

                    Text(verbatim: "2. Wear clean and modest clothing as Friday is a day of significance.")
                        .font(.body)

                    Text(verbatim: "3. Avoid distractions, such as using phones, during the sermon.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Friday is the best day of the week: a weekly gathering for remembrance, with special reward in reciting Surah al-Kahf and sending salawat upon the Prophet.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "JumuahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "JumuahView")
        .navigationTitle("Jumuah")
    }
}

struct AdhanOtherView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Adhan is the melodious call announcing each of the five daily prayers, first given in Madinah and famously called by Bilal ibn Rabah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HISTORY")) {
                    Text(articleMarkdown: "The Adhan (أَذَان) is the Islamic call to prayer, from the root **a-dh-n (أ ذ ن)** meaning to announce or proclaim.")
                        .font(.body)

                    Text(verbatim: "It is recited in Arabic to announce the time for each of the five daily prayers.")
                        .font(.body)

                    Text(verbatim: "The Adhan originated during the time of Prophet Muhammad (peace and blessings be upon him) in Madinah.")
                        .font(.body)

                    Text(verbatim: "The Companions had discussed how to announce the prayer, and some suggested a bell like the Christians or a horn like the Jews. Umar (may Allah be pleased with him) proposed that a man call the people, and the Prophet (peace and blessings be upon him) ordered Bilal to rise and give the call (Sahih al-Bukhari 604). The words of the Adhan were shown to Abdullah ibn Zayd (may Allah be pleased with him) in a dream, which the Prophet confirmed as a true vision, telling him to teach them to Bilal ibn Rabah (may Allah be pleased with him), whose voice was the louder (Sunan Abi Dawud 499; graded hasan sahih by al-Albani).")
                        .font(.body)
                }

                Section(header: ArticleHeader("WORDS OF THE ADHAN")) {
                    Text(verbatim: """
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
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(appearance.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(verbatim: """
                    Allahu Akbar, Allahu Akbar
                    Allahu Akbar, Allahu Akbar

                    Ashhadu an la ilaha illa Allah
                    Ashhadu an la ilaha illa Allah

                    Ashhadu anna Muhammadan rasool Allah
                    Ashhadu anna Muhammadan rasool Allah

                    Hayya 'ala as-salah, Hayya 'ala as-salah
                    Hayya 'ala al-falah, Hayya 'ala al-falah

                    Allahu Akbar, Allahu Akbar
                    La ilaha illa Allah
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
                }

                Section(header: ArticleHeader("ONLY FOR FAJR")) {
                    Text(articleMarkdown: "**ONLY FOR FAJR:** the following line is added, and it is said in no other Adhan. It comes after “Hayya ala al-falah“ and before the closing takbir.")
                        .font(.body)

                    Text(articleMarkdown: "**ONLY FOR FAJR:**")
                        .font(.body)
                        .foregroundColor(appearance.accent)

                    Text(verbatim: "الصَّلَاةُ خَيرٌ مِنَ النَّومِ")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(verbatim: "As-salatu khayrun mina-nawm\n(Prayer is better than sleep)")
                        .font(.body)

                    Text(verbatim: "This line is said twice, and only in the Adhan for Fajr. It is never said in the Adhan for Dhuhr, Asr, Maghrib, or Isha, and it is never said in the Iqamah. Abu Mahdhurah (may Allah be pleased with him), whom the Prophet (peace and blessings be upon him) taught the Adhan, said:")
                        .font(.body)
                    ScriptureQuote(hadith: "nasai:647", cite: "Sunan an-Nasa'i 647; graded sahih by al-Albani", arabic: 20...52, english: 0...67)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Its words proclaim the greatness and oneness of Allah and the messengership of Muhammad, calling the believers to prayer and to success.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE VIRTUE OF THE ADHAN")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(quran: "62:9", words: 0...14)
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:615", cite: "Sahih al-Bukhari 615", arabic: 29...44, english: 4...39)
                    ScriptureQuote(hadith: "bukhari:608", cite: "Sahih al-Bukhari 608", arabic: 26...36, english: 4...28)
                    Text(verbatim: "Answer the muadhin. He said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:383", cite: "Sahih Muslim 383", arabic: 30...37, english: 0...11)
                    Text(verbatim: "Except at “Hayya ala as-salah“ and “Hayya ala al-falah,“ where you say “La hawla wa la quwwata illa billah“ (there is no might nor power except with Allah), as Umar (may Allah be pleased with him) reported from him (Sahih Muslim 385).")
                        .font(.body)
                    Text(verbatim: "Then send blessings on the Prophet (peace and blessings be upon him), and say:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:614", cite: "Sahih al-Bukhari 614", arabic: 29...54, english: 4...88)
                }

                ArticleSourcesSection(article: "AdhanOtherView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "AdhanOtherView")
        .navigationTitle("Adhan")
    }
}

struct IqamahView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Iqamah is the second, shorter call given just before the congregation stands, signaling that the prayer is about to begin.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "The Iqamah (إِقَامَة), from the root **q-w-m (ق و م)**, to stand or establish, is the second call to prayer, given right before the congregational Salah begins.")
                        .font(.body)

                    Text(verbatim: "It is generally shorter than the Adhan and serves as a prompt for the congregation to stand and line up for prayer.")
                        .font(.body)

                    Text(articleMarkdown: "Often, the same **Mu'adhin (مُؤَذِّن)** (caller) who delivered the Adhan will also deliver the Iqamah, but it can be done by someone else.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WORDS OF THE IQAMAH")) {
                    Text(verbatim: """
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ

                    أَشهَدُ أَن لَا إِلَٰهَ إِلَّا اللَّهُ

                    أَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ

                    حَيَّ عَلَى الصَّلَاةِ، حَيَّ عَلَى الفَلَاحِ

                    قَد قَامَتِ الصَّلَاةُ
                    قَد قَامَتِ الصَّلَاةُ

                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ

                    لَا إِلَٰهَ إِلَّا اللَّهُ
                    """)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(appearance.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(verbatim: """
                    Allahu Akbar, Allahu Akbar

                    Ashhadu an la ilaha illa Allah

                    Ashhadu anna Muhammadan rasool Allah

                    Hayya 'ala as-salah, Hayya 'ala al-falah

                    Qad qamatis-Salah
                    Qad qamatis-Salah

                    Allahu Akbar, Allahu Akbar

                    La ilaha illa Allah
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
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Where the Adhan calls the community to gather, the Iqamah announces that the prayer has been established and the rows are to be formed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("AFTER THE IQAMAH")) {
                    Text(verbatim: "The Iqamah is said in single phrases, unlike the Adhan, which is said in pairs. Anas (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:605", cite: "Sahih al-Bukhari 605, Sahih Muslim 378", arabic: 21...30, english: 0...22)
                    Text(verbatim: "Once the Iqamah is called, no other prayer is begun. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:710a", cite: "Sahih Muslim 710", arabic: 32...38, english: 0...13)
                    Text(verbatim: "And straighten the rows before the imam begins:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:723", cite: "Sahih al-Bukhari 723, Sahih Muslim 433", arabic: 19...26, english: 4...19)
                    Text(verbatim: "Walk to the prayer calmly. He said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:636", cite: "Sahih al-Bukhari 636, Sahih Muslim 602", arabic: 40...56, english: 4...36)
                }

                ArticleSourcesSection(article: "IqamahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "IqamahView")
        .navigationTitle("Iqamah")
    }
}

struct TakbiratView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Eid prayer is two rak'ah with extra takbirs, prayed in congregation after sunrise with no Adhan and no Iqamah, followed by the khutbah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("BEFORE YOU GO")) {
                    Text(articleMarkdown: "1. Perform **ghusl (غُسل)**, wear your best clothes, and apply perfume (for men).")
                        .font(.body)
                    Text(articleMarkdown: "2. For **Eid al-Fitr**, eat an odd number of dates before leaving. For **Eid al-Adha**, do not eat until after the prayer, so that the first thing you eat is from the sacrifice.")
                        .font(.body)
                    Text(articleMarkdown: "3. Pay **Zakat al-Fitr** before the prayer (Eid al-Fitr only). If it is paid after the prayer, it counts as ordinary charity, not as Zakat al-Fitr.")
                        .font(.body)
                    Text(verbatim: "4. Say the Takbir on the way, out loud (see below).")
                        .font(.body)
                    Text(articleMarkdown: "5. Go out to the **musalla (مُصَلَّى)**, the open prayer ground, which is the Sunnah, and take the women and children with you. Go by one route and return by another. Jabir (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:986", cite: "Sahih al-Bukhari 986", arabic: 20...31, english: 0...25)
                }

                Section(header: ArticleHeader("THE TIME OF THE PRAYER")) {
                    Text(verbatim: "The Eid prayer begins after the sun has fully risen, roughly 15 to 20 minutes after sunrise, and its time lasts until just before the sun reaches its zenith (before Dhuhr).")
                        .font(.body)
                    Text(articleMarkdown: "**Eid al-Adha** is prayed early, so people can go and sacrifice. **Eid al-Fitr** is prayed a little later, so people have time to give Zakat al-Fitr.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW TO PRAY EID")) {
                    Text(articleMarkdown: "There is **no Adhan and no Iqamah** for the Eid prayer, and no call of any kind. It is simply begun.")
                        .font(.body)

                    Text(articleMarkdown: "It is **two rak'ah**, prayed in congregation behind the imam, and the recitation is out loud.")
                        .font(.body)

                    Text(articleMarkdown: "**First rak'ah:**")
                        .font(.body)
                    Text(articleMarkdown: "1. Make the intention in the heart, then the opening takbir, **Takbirat al-Ihram (تَكبِيرَة الإِحرَام)**, raising the hands.")
                        .font(.body)
                    Text(articleMarkdown: "2. Say the opening supplication (**du'a al-istiftah**).")
                        .font(.body)
                    Text(articleMarkdown: "3. Say **seven takbirs** in total in this rak'ah before the recitation, raising the hands with each. (Scholars differ over whether the opening takbir is counted as one of the seven; both are practised and the prayer is valid either way. Do not argue over it.)")
                        .font(.body)
                    Text(articleMarkdown: "4. Then say the ta'awwudh and recite **al-Fatihah**, followed by a surah. From the Sunnah: **Surah al-A'la (87)** in the first rak'ah and **al-Ghashiyah (88)** in the second, or **Qaf (50)** and **al-Qamar (54)**.")
                        .font(.body)
                    Text(verbatim: "5. Then complete the rak'ah as normal: ruku', standing, and two prostrations.")
                        .font(.body)

                    Text(articleMarkdown: "**Second rak'ah:**")
                        .font(.body)
                    Text(articleMarkdown: "6. Stand, and before reciting, say **five takbirs**, raising the hands with each. These are apart from the takbir you said when standing up from prostration.")
                        .font(.body)
                    Text(verbatim: "7. Recite al-Fatihah and a surah, then complete the rak'ah, sit for the tashahhud, and give the salaam.")
                        .font(.body)

                    Text(articleMarkdown: "There is **no nafl prayer** before or after the Eid prayer at the musalla.")
                        .font(.body)

                    Text(verbatim: "Aisha (may Allah be pleased with her) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:1149", cite: "Sunan Abi Dawud 1149-1150; graded sahih by al-Albani", english: 0...51, arabicText: "كَانَ يُكَبِّرُ فِي الفِطرِ وَالأَضحَى فِي الأُولَى سَبعَ تَكبِيرَاتٍ وَفِي الثَّانِيَةِ خَمسًا سِوَى تَكبِيرَتَىِ الرُّكُوعِ")

                    Text(verbatim: "If you miss a takbir, or the imam has already begun, join him where he is and do not try to make up the extra takbirs. They are a Sunnah, not a pillar, and forgetting them does not invalidate the prayer or require the prostration of forgetfulness.")
                        .font(.body)
                }

                Section(header: ArticleHeader("AFTER THE PRAYER: THE KHUTBAH")) {
                    Text(articleMarkdown: "The khutbah comes **after** the Eid prayer, unlike Jumuah, where it comes before.")
                        .font(.body)
                    Text(verbatim: "Staying for it is strongly recommended, though it is not obligatory, and one who leaves has not sinned.")
                        .font(.body)
                    Text(verbatim: "If you missed the congregation entirely, you may pray two rak'ah on your own.")
                        .font(.body)
                    Text(verbatim: "Greet one another as the Companions did. Jubayr ibn Nufayr said: when the Companions of the Messenger of Allah (peace and blessings be upon him) met on the day of Eid, they would say to one another:")
                        .font(.body)
                    ScriptureQuote(text: "“Taqabbal Allahu minna wa minka: May Allah accept it from us and from you” (reported by al-Mahamili; Ibn Hajar said its chain is hasan, Fath al-Bari 2/446).", arabic: "تَقَبَّلَ اللَّهُ مِنَّا وَمِنكَ", dimmed: true)
                }

                Section(header: ArticleHeader("EID OCCASIONS")) {
                    Text(verbatim: "In Islam, there are two major annual celebrations known as Eid:")
                        .font(.body)

                    Text(articleMarkdown: "1. **Eid al-Fitr (عِيد الفِطر):** Celebrated at the end of Ramadan (the month of fasting). It is a time of joy, gratitude to Allah (Glorified and Exalted be He), and giving to the needy (Zakat al-Fitr).")
                        .font(.body)

                    Text(articleMarkdown: "2. **Eid al-Adha (عِيد الأَضحَى):** Celebrated on the 10th day of Dhu al-Hijjah. It commemorates the willingness of Prophet Ibrahim (peace be upon him) to sacrifice his son Isma'il (peace be upon him). Muslims who are able to do so perform the sacrifice (Qurbani) and distribute the meat to the poor. This Eid coincides with Hajj, the annual pilgrimage to Makkah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("TAKBIRAT AL-EID")) {
                    Text(verbatim: "The Takbirat al-Eid is a special proclamation of Allah’s greatness, recited during the days of Eid.")
                        .font(.body)

                    Text(verbatim: "For Eid al-Fitr, it begins after the new moon confirming the end of Ramadan and continues until the Eid prayer. For Eid al-Adha, the unrestricted takbir runs from the start of Dhu al-Hijjah until sunset on the 13th (Quran 2:203, “remember Allah during numbered days”; Sahih al-Bukhari, the chapter on the virtue of deeds in the days of Tashriq), and the takbir after the prayers runs from Fajr of Arafah Day (the 9th) for those not on Hajj until Asr of the 13th, as Ibn Abbas and Ibn Umar did (Ibn Hajar, Fath al-Bari 2/462).")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(quran: "2:185", words: 35...43)
                }

                Section(header: ArticleHeader("SHORT TAKBIRAT")) {
                    Text(verbatim: "This is the short version of the Takbir:")
                        .font(.body)

                    Text(verbatim: "اللَّهُ أَكبَرُ اللَّهُ أَكبَرُ لَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكبَرُ اللَّهُ أَكبَرُ وَلِلَّهِ الحَمدُ")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(verbatim: "Allahu Akbar, Allahu Akbar, La Ilaha Illa Allah, Allahu Akbar, Allahu Akbar, wa lillahil hamd")
                        .font(.body)

                    Text(verbatim: "Allah is the Greatest, Allah is the Greatest. There is no deity but Allah. Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE TAKBIR OF THE COMPANIONS")) {
                    Text(verbatim: "No fixed wording of the Eid takbir is narrated from the Prophet (peace and blessings be upon him) himself; what is established is the practice of his Companions, and their wording is what Ahl as-Sunnah keep to. Ibn Mas’ud (may Allah be pleased with him) would say:")
                        .font(.body)
                    ScriptureQuote(text: "“Allahu Akbar, Allahu Akbar, la ilaha illallah, wallahu Akbar, Allahu Akbar, wa lillahil-hamd: Allah is the Greatest, Allah is the Greatest, there is no deity but Allah; and Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise” (Musannaf Ibn Abi Shaybah; graded sahih by al-Albani, Irwa' al-Ghalil 3/125).", arabic: "اللَّهُ أَكبَرُ اللَّهُ أَكبَرُ، لَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكبَرُ اللَّهُ أَكبَرُ وَلِلَّهِ الحَمدُ", dimmed: true)

                    Text(verbatim: "And from Ibn Abbas (may Allah be pleased with him):")
                        .font(.body)
                    ScriptureQuote(text: "“Allahu Akbar kabira, Allahu Akbar kabira, Allahu Akbar wa ajall, Allahu Akbar wa lillahil-hamd: Allah is the Greatest, truly great; Allah is the Greatest, truly great; Allah is the Greatest and most Majestic; Allah is the Greatest, and to Allah belongs all praise” (Ibn Abi Shaybah 2/168 and al-Mahamili; graded sahih by al-Albani, Irwa' al-Ghalil 3/126).", arabic: "اللَّهُ أَكبَرُ كَبِيرًا، اللَّهُ أَكبَرُ كَبِيرًا، اللَّهُ أَكبَرُ وَأَجَلُّ، اللَّهُ أَكبَرُ وَلِلَّهِ الحَمدُ", dimmed: true)

                    Text(verbatim: "Saying it three times (Allahu Akbar, Allahu Akbar, Allahu Akbar) is also reported from the Salaf, and both are fine. Men raise their voices with it in the markets, the mosques and on the way to the prayer ground, as Ibn Umar and Abu Hurayrah used to (Sahih al-Bukhari, Book of the Two Eids, chapter heading).")
                        .font(.body)
                }

                Section(header: ArticleHeader("OTHER WORDS OF REMEMBRANCE FROM THE SUNNAH")) {
                    Text(verbatim: "Longer chants heard on Eid morning gather phrases that are themselves authentic remembrances, and these may be said. A Companion said this in the prayer, and the Prophet (peace and blessings be upon him) said of it: “I marvelled at it; the gates of heaven were opened for it” (Sahih Muslim 601):")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:601", cite: "Sahih Muslim 601", arabic: 42...51, english: 15...34)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) would say on returning from Hajj, Umrah or a campaign:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:1797", cite: "Sahih al-Bukhari 1797", arabic: 47...77, english: 27...90)

                    Text(verbatim: "And after every obligatory prayer he would say:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:594a", cite: "Sahih Muslim 594", arabic: 27...74, english: 14...98)

                    Text(verbatim: "What has no basis is the composed formula that adds blessings on “our master Muhammad, his companions, his supporters, his wives and his offspring” inside the takbir itself: it is not narrated from the Prophet (peace and blessings be upon him) or from any of his Companions. Sending blessings on him is beloved at all times (Quran 33:56), but the takbir of Eid is kept to the transmitted wording.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "By glorifying Allah on the days of Eid, Muslims complete their worship with gratitude: after Ramadan for Eid al-Fitr, and around the days of Hajj for Eid al-Adha.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "TakbiratView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("How to Pray Eid")
        .selectableArticleList(article: "TakbiratView")
    }
}

struct HijriCalendarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Hijri calendar is the Islamic lunar calendar of twelve months, dated from the Prophet's migration (Hijrah) to Madinah in 622 CE.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "The Hijri calendar, also known as the Islamic or Lunar Hijri calendar, consists of 12 lunar months in a year of 354 or 355 days.")
                        .font(.body)

                    Text(verbatim: "It is used to determine key Islamic dates such as Ramadan, Hajj, and the two Eid festivals. The reference point (epoch) of the calendar is the Hijrah, the migration of Prophet Muhammad (peace and blessings be upon him) from Makkah to Madinah in 622 CE.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(quran: "9:36", words: 0...17)
                }

                Section(header: ArticleHeader("DETAILS")) {
                    Text(articleMarkdown: """
                         Each Hijri month begins with the sighting of the new moon. The 12 months are as follows:
                         1. **Muharram (مُحَرَّم)**: One of the sacred months
                         2. **Safar (صَفَر)** 
                         3. **Rabi al-Awwal (رَبِيع ٱلأَوَّل)**
                         4. **Rabi al-Thani (رَبِيع ٱلثَّانِي)** 
                         5. **Jumada al-Awwal (جُمَادَىٰ ٱلأَوَّل)** 
                         6. **Jumada al-Thani (جُمَادَىٰ ٱلثَّانِي)** 
                         7. **Rajab (رَجَب)**: A sacred month
                         8. **Shaaban (شَعبَان)**: The month preceding Ramadan
                         9. **Ramadan (رَمَضَان)**: The month of fasting
                         10. **Shawwal (شَوَّال)**: The month following Ramadan
                         11. **Dhul-Qadah (ذُو ٱلقَعدَة)**: A sacred month
                         12. **Dhul-Hijjah (ذُو ٱلحِجَّة)**: A sacred month, the month of Hajj and Eid al-Adha
                         """)
                    .font(.body)

                    Text(verbatim: "A Hijri year is approximately 11 days shorter than a Gregorian year, causing Islamic events to shift earlier each Gregorian year. Muslims worldwide use this calendar for religious observances, including fasting in Ramadan, undertaking Hajj, and celebrating Eid al-Fitr and Eid al-Adha.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SACRED MONTHS")) {
                    Text(articleMarkdown: "Four of the Hijri months are considered sacred: **Muharram**, **Rajab**, **Dhul-Qadah**, and **Dhul-Hijjah**.")
                        .font(.body)

                    Text(verbatim: "These months are distinguished by their sanctity and prohibition of warfare, emphasizing peace and reflection.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(quran: "9:36")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "About eleven days shorter than the solar year, it sets the timing of Ramadan, Hajj, and the two Eids, and marks the four sacred months.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "HijriCalendarView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Hijri Calendar")
        .selectableArticleList(article: "HijriCalendarView")
    }
}

struct SacredMonthsView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: four of the twelve Hijri months are sacred (Dhul-Qadah, Dhul-Hijjah, Muharram, and Rajab), and Allah singled them out for honour, forbade fighting in them, and warned against wronging oneself in them.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "The Hijri year is twelve lunar months, and Allah set four of them apart from the day He created the heavens and the earth. They are not sacred because the Arabs treated them so; the Arabs inherited their sanctity from the religion of Ibrahim (peace be upon him) and then tampered with it, and Islam restored them to their places.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(quran: "9:36", words: 0...24)
                }

                Section(header: ArticleHeader("WHICH FOUR THEY ARE")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) named them in his sermon at the Farewell Pilgrimage: three that run together at the turn of the year, and one on its own in the middle.")
                        .font(.body)

                    ScriptureQuote(hadith: "bukhari:3197", cite: "Sahih al-Bukhari 3197", arabic: 34...61, english: 4...63)

                    Text(articleMarkdown: """
                         The four, in the order of the Hijri year:
                         1. **Muharram (مُحَرَّم)**: the first month, and the only one Allah's Messenger (peace and blessings be upon him) called “the month of Allah”
                         2. **Rajab (رَجَب)**: the seventh, alone between Jumada al-Thaniyah and Shaaban
                         3. **Dhul-Qadah (ذُو ٱلقَعدَة)**: the eleventh, named for the “sitting” that came with laying down weapons
                         4. **Dhul-Hijjah (ذُو ٱلحِجَّة)**: the twelfth, the month of Hajj
                         """)
                    .font(.body)

                    Text(verbatim: "“Rajab of Mudar” settles which Rajab is meant. The tribe of Mudar kept it in its true place while other tribes shifted it, so the Prophet (peace and blessings be upon him) fixed it to the month Mudar honoured: the one between Jumada al-Thaniyah and Shaaban.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT THEIR SANCTITY MEANS")) {
                    Text(verbatim: "Two things are established. Fighting was forbidden in them, so that pilgrims and traders could travel in safety to Makkah and home again, and the two Hajj months plus the month before and the month after are exactly the window a journey needed. And sin in them is graver than sin outside them.")
                        .font(.body)

                    Text(verbatim: "Ibn Kathir (may Allah have mercy on him) explains “so do not wrong yourselves during them” to mean: in these months especially, for a sin in a sacred time is heavier, just as a good deed in a sacred time is greater. Qatadah said that wrongdoing in them is a greater burden and a greater sin than wrongdoing in any other month, though wrongdoing is grave in every case.")
                        .font(.body)

                    Text(verbatim: "This is a warning against sin, not a licence to invent worship. No prayer, no fast, and no gathering is prescribed for a month merely because it is sacred; what is prescribed in them is what the Quran and the Sunnah actually name, and that is set out below.")
                        .font(.body)
                }

                Section(header: ArticleHeader("AN-NASI: MOVING THE MONTHS")) {
                    Text(verbatim: "Before Islam the Arabs would postpone a sacred month when it did not suit a war they wanted to fight, declaring Muharram ordinary that year and making Safar sacred instead, so that the count of four was kept while the months themselves were moved. Allah called this an increase in disbelief.")
                        .font(.body)

                    ScriptureQuote(quran: "9:37", words: 0...21)

                    Text(verbatim: "This is why the Prophet (peace and blessings be upon him) opened his Farewell Sermon by saying that time had come back round to its original state as it was on the day Allah created the heavens and the earth: the months were back in their true places, and they have stayed there since.")
                        .font(.body)
                }

                Section(header: ArticleHeader("MUHARRAM AND THE DAY OF ASHURA")) {
                    Text(verbatim: "Muharram carries the one virtue the Sunnah states outright for a sacred month as a whole. Asked which fast is best after the month of Ramadan, Prophet Muhammad (peace and blessings be upon him) answered:")
                        .font(.body)

                    ScriptureQuote(hadith: "ibnmajah:1742", cite: "Sunan Ibn Majah 1742; graded sahih by al-Albani, and the same report is in Sahih Muslim 1163", arabic: 51...55, english: 20...27)

                    Text(verbatim: "Within it is Ashura, the tenth of Muharram. When Prophet Muhammad (peace and blessings be upon him) came to Madinah he found the Jews fasting it, because it was the day Allah saved Musa and the Children of Israel from their enemy, and he said:")
                        .font(.body)

                    ScriptureQuote(hadith: "bukhari:2004", cite: "Sahih al-Bukhari 2004", arabic: 59...62, english: 48...55)

                    Text(verbatim: "He fasted it and told the Muslims to fast it, and he named its reward:")
                        .font(.body)

                    ScriptureQuote(hadith: "muslim:1162a", cite: "Sahih Muslim 1162", arabic: 190...200, english: 247...267)

                    Text(verbatim: "In the last year of his life he intended to add the ninth, to differ from the People of the Book:")
                        .font(.body)

                    ScriptureQuote(hadith: "ibnmajah:1736", cite: "Sunan Ibn Majah 1736; graded sahih by al-Albani, and the same report is in Sahih Muslim 1134", arabic: 37...43, english: 0...14)

                    Text(verbatim: "He died before that year came, so the scholars hold it recommended to fast the ninth with the tenth. What is not from the Sunnah is anything else built onto this day: no mourning, no celebration, no special dish, no gathering. The day is a fast, and that is all that was given.")
                        .font(.body)
                }

                Section(header: ArticleHeader("DHUL-HIJJAH AND ITS FIRST TEN DAYS")) {
                    Text(verbatim: "Dhul-Hijjah opens with the ten days about which Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(hadith: "bukhari:969", cite: "Sahih al-Bukhari 969", arabic: 28...37, english: 4...23)

                    Text(verbatim: "The ninth is the Day of Arafah, whose fast the Prophet (peace and blessings be upon him) said he hoped would atone for the year before it and the year after it, for anyone not standing at Arafah. The tenth is the Day of Sacrifice, Eid al-Adha, and it is not fasted. Hajj itself falls in this month, which is why Dhul-Qadah before it and Muharram after it are sacred alongside it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT IS NOT ESTABLISHED IN RAJAB")) {
                    Text(verbatim: "Rajab is a sacred month, and nothing beyond that is authentically reported about it. Ibn Hajar al-Asqalani (may Allah have mercy on him) wrote a treatise on exactly this question, Tabyin al-Ajab bima Warada fi Fadl Rajab, and concluded that no sound hadith fit to use as evidence exists on the virtue of Rajab, on fasting it specifically, or on praying a particular prayer in it.")
                        .font(.body)

                    Text(articleMarkdown: """
                         So the following have no authentic basis and are not from the Sunnah:
                         - **Salat ar-Ragha’ib** on the first Friday night of Rajab, which scholars including an-Nawawi and Ibn as-Salah declared a rejected innovation
                         - Fasting Rajab in full, or singling out its days for fasting because it is Rajab
                         - The **Umrah of Rajab** as a special act; Aishah (may Allah be pleased with her) denied that the Prophet (peace and blessings be upon him) ever performed Umrah in Rajab
                         - Celebrating the twenty-seventh night as the night of al-Isra wal-Miraj; the date itself is not established, and no worship was legislated for it
                         - The **Atirah**, a sacrifice offered in Rajab in the days of ignorance, which Islam abolished
                         """)
                    .font(.body)

                    Text(verbatim: "None of this diminishes the month. It means the honour Allah gave it is the honour it has, and adding to it is not devotion but innovation. Whoever fasts Mondays and Thursdays, or the three white days, and those days fall in Rajab, is doing what the Sunnah already asks, and there is nothing wrong with that.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Four months of the twelve are sacred by Allah's decree: Dhul-Qadah, Dhul-Hijjah, Muharram, and Rajab. Fighting in them was forbidden, sin in them is heavier, and moving them, as the Arabs once did, was called an increase in disbelief. What is legislated in them is what the texts name: the fast of Ashura in Muharram, and the ten days, Arafah, and Hajj in Dhul-Hijjah. What is not named, above all in Rajab, is left alone.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Al-Ashhur al-Hurum (ٱلأَشهُر ٱلحُرُم)**: “the sacred months,” the four Allah set apart in Quran 9:36. Hurum is the plural of haram, meaning inviolable: the same root as the Haram of Makkah and as ihram, the sacred state of a pilgrim.")
                        .font(.body)

                    Text(articleMarkdown: "**An-Nasi (ٱلنَّسِيء)**: “postponement,” the pre-Islamic practice of shifting a sacred month to a different month so that a war could be fought on time, condemned in Quran 9:37.")
                        .font(.body)

                    Text(articleMarkdown: "**Ashura (عَاشُورَاء)**: the tenth of Muharram, from ashr, ten. The day Allah saved Musa (peace be upon him) and his people; its fast expiates the year before it.")
                        .font(.body)

                    Text(articleMarkdown: "**Atirah (عَتِيرَة)**: a sheep the Arabs slaughtered in Rajab for their idols or their customs. Islam abolished it.")
                        .font(.body)

                    Text(articleMarkdown: "**Rajab of Mudar**: the Rajab kept in its true place by the tribe of Mudar, named by the Prophet (peace and blessings be upon him) so that no one could mistake which month was meant.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "SacredMonthsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Sacred Months")
        .selectableArticleList(article: "SacredMonthsView")
    }
}

struct MoonSightingView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: a Hijri month begins when the new crescent is sighted, and if it cannot be seen the month before is completed as thirty days. Sighting, not calculation, is what the Sunnah made the sign.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "A lunar month is the moon's full circuit, a little over twenty-nine and a half days, so a Hijri month is always either twenty-nine or thirty days and never a fixed number. Allah made the moon itself the clock:")
                        .font(.body)

                    ScriptureQuote(quran: "10:5", words: 0...12)

                    Text(verbatim: "And when the Companions asked about the crescents themselves, the answer named their purpose:")
                        .font(.body)

                    ScriptureQuote(quran: "2:189", words: 1...8)
                }

                Section(header: ArticleHeader("THE RULE")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) gave the whole rule in one sentence, and it is the rule for every Hijri month, not for Ramadan alone:")
                        .font(.body)

                    ScriptureQuote(hadith: "bukhari:1909", cite: "Sahih al-Bukhari 1909", arabic: 35...45, english: 6...39)

                    Text(verbatim: "The Quran ties the obligation to the same act of witnessing:")
                        .font(.body)

                    ScriptureQuote(quran: "2:185", words: 12...16)

                    Text(verbatim: "So there are two ways a month can begin and no third: the crescent is seen by a trustworthy witness, or the month in progress reaches thirty days and the next one starts by itself. Doubt never begins a month, which is why fasting the “day of doubt” before Ramadan is forbidden.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHY SIGHTING AND NOT CALCULATION")) {
                    Text(verbatim: "Astronomers can compute the moon's conjunction to the second, and Muslim astronomers could do so early. The Sunnah still tied the month to the eye, and the Prophet (peace and blessings be upon him) said why:")
                        .font(.body)

                    ScriptureQuote(hadith: "bukhari:1913", cite: "Sahih al-Bukhari 1913", arabic: 31...40, english: 4...31)

                    Text(verbatim: "The point is not that arithmetic is blameworthy but that the sign Allah gave is one every believer can use, in every century and in every place, with no instrument and no expert. A conjunction is not the same thing as a visible crescent either: the moon can be astronomically new and still be invisible from the earth that evening.")
                        .font(.body)

                    Text(verbatim: "This is the position of the great body of scholars, and of the Permanent Committee for Scholarly Research and Ifta and Ibn Baz (may Allah have mercy on him) in our own time: calculation may support a sighting, may show that a claimed sighting was impossible, and may tell an observer where to look, but it does not by itself begin or end a month.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ONE SIGHTING, OR EACH LAND ITS OWN?")) {
                    Text(verbatim: "The moon does not rise over the whole earth at once, so a crescent visible in one country may be below the horizon in another. The Companions already faced this. Kurayb saw the crescent of Ramadan in Syria on a Friday night and told Ibn Abbas (may Allah be pleased with them) in Madinah, who had seen it on Saturday night. Ibn Abbas kept to the sighting of Madinah and said: this is how Allah's Messenger (peace and blessings be upon him) commanded us (Sahih Muslim 1087).")
                        .font(.body)

                    Text(articleMarkdown: """
                         Two positions have stood since:
                         - **Each region follows its own sighting** (ikhtilaf al-matali): the view many scholars take from Ibn Abbas's report, and the practice of Ibn Uthaymin (may Allah have mercy on him)
                         - **One sighting binds all Muslims**: the view that “fast when you see it” addresses the whole ummah, held by Ibn Baz and by the Permanent Committee
                         """)
                    .font(.body)

                    Text(verbatim: "Both are the ijtihad of scholars on a question the texts leave open, and neither side declares the other astray. The practical guidance the scholars of both views give is the same: a Muslim fasts, breaks the fast and prays Eid with the Muslims of the land he is in. Unity in the matter is itself part of the worship, and the Prophet (peace and blessings be upon him) said that the fast is the day the people fast and the breaking of the fast is the day the people break it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT DEPENDS ON IT")) {
                    Text(verbatim: "Almost every dated act of worship hangs on the crescent: the start and end of Ramadan and so the night of Laylat al-Qadr, Zakat al-Fitr and the Eid prayer, the day of Arafah and the day of Sacrifice, the whole timing of Hajj, the day of Ashura, and the hawl (the full lunar year) after which zakah becomes due on wealth.")
                        .font(.body)

                    Text(verbatim: "This is also why the Hijri date and the Gregorian date drift apart. A lunar year is about eleven days shorter than a solar one, so Ramadan moves back through the seasons and returns to the same season roughly once in every thirty-three years.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The month begins with the eye, not the calendar: the crescent is sighted, or thirty days are completed. Calculation serves the sighting and does not replace it. Whether one sighting binds the whole ummah or each land follows its own is a real difference among scholars, and in practice a Muslim keeps the fast and the Eid of the people among whom he lives.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Hilal (هِلاَل)**: the new crescent, the thin arc visible shortly after sunset that begins a Hijri month. The plural, ahillah, is the word Quran 2:189 uses.")
                        .font(.body)

                    Text(articleMarkdown: "**Ruyah (رُؤيَة)**: sighting with the eye. The phrase of the hadith, li-ruyatihi, means “on account of sighting it.”")
                        .font(.body)

                    Text(articleMarkdown: "**Ikmal (إِكمَال)**: “completing,” the fallback when the sky is overcast: finish the current month at thirty days.")
                        .font(.body)

                    Text(articleMarkdown: "**Ikhtilaf al-matali (ٱختِلاَف ٱلمَطَالِع)**: the difference of the places of rising, the reality that a crescent visible in one land may not be visible in another, and the name of the position that each land follows its own sighting.")
                        .font(.body)

                    Text(articleMarkdown: "**Yawm ash-shakk (يَوم ٱلشَّكّ)**: the day of doubt, the thirtieth of Shaaban when the crescent was not seen. It is not fasted as Ramadan.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "MoonSightingView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Sighting the New Month")
        .selectableArticleList(article: "MoonSightingView")
    }
}

struct CompileView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Quran was preserved from the start by mass memorization and careful writing, gathered into one volume under Abu Bakr, and standardized under Uthman.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "From the first revelation, the Quran was preserved by the Companions through precise memorization (hifdh) and careful writing on parchments, leather, bones, and leaves. Prophet Muhammad (peace and blessings be upon him) had official scribes (including Zayd ibn Thabit) who wrote verses as they were revealed.")
                        .font(.body)

                    Text(verbatim: "Every year in Ramadan, Jibril (Gabriel) reviewed the Quran with Prophet Muhammad (peace and blessings be upon him); in the final year this review occurred twice (al-Ardah al-Akhirah). Prophet Muhammad (peace and blessings be upon him) taught the Companions the exact wording, pronunciation, and the order in which the surahs and ayat should be recited.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ALLAH’S PROMISE OF PRESERVATION")) {
                    ScriptureQuote(quran: "15:9")

                    ScriptureQuote(quran: "75:16-19")

                    ScriptureQuote(quran: "73:4", words: 3...5)

                    ScriptureQuote(quran: "17:106")
                }

                Section(header: ArticleHeader("DURING THE PROPHET’S LIFETIME ﷺ")) {
                    Text(verbatim: "• Memorization first: Many Companions memorized the Quran word-for-word and reviewed it with Prophet Muhammad (peace and blessings be upon him) in prayer and lessons.")
                        .font(.body)
                    Text(verbatim: "• Official scribes: Verses were dictated to scribes such as Zayd ibn Thabit, Ubayy ibn Ka‘b, and others, and kept as written fragments verified by Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                    Text(verbatim: "• Annual review: Jibril reviewed the entire Quran with Prophet Muhammad (peace and blessings be upon him) yearly in Ramadan; in the final year, the review occurred twice, confirming wording and order.")
                        .font(.body)
                }

                Section(header: ArticleHeader("FIRST COMPILATION UNDER ABU BAKR")) {
                    Text(verbatim: "After the Battle of Yamamah, many memorizers were martyred. About one year after the Prophet’s death (12 AH), at the counsel of Umar ibn al-Khattab, Caliph Abu Bakr commissioned Zayd ibn Thabit to collect the Quran into one compiled manuscript.")
                        .font(.body)

                    Text(verbatim: "Zayd gathered the Quran from written materials and from those who had memorized it, accepting verses only when corroborated by multiple reliable witnesses and his own memorization, all according to what had been reviewed with Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text(verbatim: "This compiled mushaf was kept with Abu Bakr, then with Umar, and after Umar with Hafsah bint Umar (may Allah be pleased with them).")
                        .font(.body)
                }

                Section(header: ArticleHeader("STANDARDIZATION UNDER UTHMAN")) {
                    Text(verbatim: "As Islam spread, differences in regional reading threatened dispute. Caliph Uthman ibn Affan formed a committee led by Zayd ibn Thabit with senior Qurayshi scholars to produce standardized copies based on the Abu Bakr compilation and the established Uthmanic rasm (consonantal skeleton). Written without dots or tashkeel (vowel marks), this skeletal script could accommodate the seven revealed Ahruf.")
                        .font(.body)

                    Text(verbatim: "This was not a limitation of the copies; it was how Arabic was written. Dots (i'jam) and tashkeel simply did not exist in the script at that time, and the Arabs, masters of their own language, did not need them to read. Precisely BECAUSE the rasm was bare, one written skeleton could be read in every revealed way that matched it: the same letters carried all the Ahruf, and the verified oral transmission determined how each was recited.")
                        .font(.body)

                    Text(verbatim: "Uthman sent official copies to all the major cities (Makkah, Kufa, Basra, Sham, and others, with one kept in Madinah) and asked that non-verified personal materials be retired to prevent confusion between private notes/duas and the Quranic text. The Companions agreed with this measure, preserving unity upon the authenticated text.")
                        .font(.body)

                    Text(verbatim: "This standardization did not remove revelation; rather, it unified the community upon the verified mushaf, whose skeletal rasm supported the seven Ahruf, and ensured consistent public recitation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("CONSENSUS OF THE COMPANIONS")) {
                    Text(verbatim: "The Companions, foremost memorizers and teachers, were unanimous in accepting the compilation and the Uthmanic copies. It is widely reported that Abu Bakr, Umar, Uthman, and Ali were among the foremost memorizers and teachers of the Quran, and none objected to the standardized mushaf.")
                        .font(.body)

                    Text(verbatim: "Zayd ibn Thabit led the technical work in both Abu Bakr’s and Uthman’s projects, bringing rigorous verification. Senior scholars, including Quraysh experts, reviewed and approved the copies.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE FOUR MASTERS & LEADING TRANSMITTERS")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4999", cite: "Sahih al-Bukhari 4999", arabic: 34...47, english: 22...36)

                    Text(verbatim: "These masters, together with others like Zayd ibn Thabit, were key references for wording, recitation, and teaching, anchoring transmission among the Companions and their students.")
                        .font(.body)
                }

                Section(header: ArticleHeader("AHRUF, QIRAAT, AND THE UTHMANIC RASM")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) taught that the Quran was revealed in seven Ahruf (modes) for ease. The Quran was first compiled into one manuscript under Abu Bakr (may Allah be pleased with him), around one year after the Prophet’s death. Under Uthman (may Allah be pleased with him), official copies were sent to all the major cities; because the rasm was a skeletal script without dots or tashkeel, it supported the seven Ahruf, which continued to be read and transmitted through canonical Qiraat verified by chains. The 10 Qiraat (with their 20 Riwayaat) are mutawatir and reflect how the prophetic recitation was preserved in writing and oral teaching.")
                        .font(.body)

                    Text(verbatim: "Thus, standardization did not limit revelation; it safeguarded it, preventing private notes and unverified materials from being mistaken for the Quran, while preserving the legitimate readings taught by Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY REPORTS (BRIEF)")) {
                    ScriptureQuote(hadith: "bukhari:4992", cite: "Sahih al-Bukhari 4992, Sahih Muslim 818", arabic: 177...187, english: 204...237)
                    Text(verbatim: "• Double review in final Ramadan (al-Ardah al-Akhirah): reported in authentic narrations.")
                        .font(.body)
                    Text(verbatim: "• Abu Bakr’s compilation via Zayd after Yamamah: authentic reports in Sahih collections.")
                        .font(.body)
                    Text(verbatim: "• Uthman’s committee (with Zayd) and distribution of official copies: authentic reports in Sahih collections.")
                        .font(.body)
                }

                Section(header: ArticleHeader("MANUSCRIPT EVIDENCE (HISTORICAL NOTES)")) {
                    Text(verbatim: "Early Quranic manuscripts discovered in different regions (e.g., Hijaz, Yemen, Syria, North Africa, Anatolia) reflect the early Uthmanic rasm and align with the text recited today.")
                        .font(.body)

                    Text(verbatim: "Examples often cited by historians include: the Birmingham fragments (radiocarbon dated to the earliest period of Islam), folios from Sana’a (including palimpsests showing early layers of writing), and early codices associated with major centers and later libraries (e.g., Topkapi).")
                        .font(.body)

                    Text(verbatim: "While scholarly studies analyze paleography, orthography, and dating techniques, the consonantal text aligns with the standardized Uthmanic tradition, and the Quran remains read globally in the same wording preserved by the Ummah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHY WERE PRIVATE MATERIALS RETIRED?")) {
                    Text(verbatim: "Some Companions wrote personal notes (duas, explanations, or hadith) near Quranic passages. To prevent confusion between private annotations and the Quran, and to avoid unchecked variants, Uthman ordered that only the verified official copies be used for public recitation and that other materials be retired.")
                        .font(.body)

                    Text(verbatim: "No Companion rejected the standardized mushaf. The community recited, taught, and transmitted the same Quran by memorization and writing through every generation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("CONTINUITY UNTIL TODAY")) {
                    Text(verbatim: "The Quran we hold today is the same revelation taught by Prophet Muhammad (peace and blessings be upon him), preserved through the consensus of the Companions, the Uthmanic rasm, the living tradition of memorization, and the mutawatir Qiraat. Around the world, millions memorize the entire Quran, letter for letter, continuing an unbroken chain of transmission.")
                        .font(.body)

                    Text(verbatim: "Public recitation, prayer, and education remain bound to the verified text. The Ummah’s practice fulfills Allah's (Glorified and Exalted be He) promise: its preservation is both textual and living.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SELECT VERSES & REMINDERS")) {
                    ScriptureQuote(quran: "7:204")

                    ScriptureQuote(quran: "4:82")

                    ScriptureQuote(quran: "41:42")
                }

                Section(header: ArticleHeader("USEFUL LINKS")) {
                    Text(articleMarkdown: "Learn More about the Compilation of the Quran: https://www.youtube.com/watch?v=n281Zyywyn4&t=343s")
                        .font(.caption)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Through unbroken memorization and a verified written text, the Quran remains today exactly as it was revealed, fulfilling Allah's promise to preserve it.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "CompileView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Compilation of the Quran")
        .selectableArticleList(article: "CompileView")
    }
}

struct TajweedView: View {
    @Environment(\.appearance) private var appearance
    @State private var showTajweedLegend = false

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Tajweed is the science of reciting the Quran correctly: giving each letter its proper articulation and every rule its due.")
                        .font(.body)
                }

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

                            Text(verbatim: "Simple way to view basic Hafs an Asim Tajweed rules with colors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    #endif
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Tajweed (تَجوِيد) means “to make well, beautify, or improve,” from the root **j-w-d (ج و د)**. In the context of the Quran, it refers to the set of rules for proper pronunciation during Quran recitation, ensuring each letter is articulated with precision.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(quran: "73:4", words: 3...5)
                }

                Section(header: ArticleHeader("IMPORTANCE")) {
                    Text(verbatim: "Tajweed ensures the Quran is recited in the most accurate and beautiful way possible, exactly as it was revealed to the Prophet ﷺ. Reciting with Tajweed is not just about making recitation sound pleasant; it is about preserving the integrity of the Quran itself.")
                        .font(.body)

                    Text(verbatim: "The Quran was revealed in Arabic, and every word, letter, and sound has a specific meaning and weight. A slight mispronunciation could change the meaning of a verse. Tajweed helps safeguard against these errors and honors the sacred text with the care and precision it deserves.")
                        .font(.body)

                    Text(verbatim: "Many Muslims find that reciting the Quran with Tajweed enhances their spiritual experience. The attention to detail required for proper recitation encourages mindfulness and deeper reflection on the meaning of the verses, making the recitation feel more immersive and meaningful.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHY LEARN TAJWEED?")) {
                    Text(verbatim: "Honoring the Quran: The Quran is the final revelation from Allah. Reciting it with care and precision is a form of respect and reverence for the sacred text.")
                        .font(.body)

                    Text(verbatim: "Preventing Misunderstandings: By applying Tajweed rules, you avoid mistakes that may alter the meaning of verses. Even changing a single sound can result in an entirely different meaning.")
                        .font(.body)

                    Text(verbatim: "Enhancing Spiritual Connection: Proper recitation encourages mindfulness and deeper reflection on the meaning of the verses, making your connection with the Quran more meaningful.")
                        .font(.body)

                    Text(verbatim: "Following the Sunnah: The Prophet Muhammad ﷺ emphasized the importance of reciting the Quran correctly. By learning Tajweed, you follow his example and teachings.")
                        .font(.body)
                }

                Section(header: ArticleHeader("GETTING STARTED")) {
                    Text(verbatim: "Learning Tajweed might seem intimidating at first, but understanding its importance can make the journey more meaningful. The best way to start is with a qualified teacher who can guide you through the articulation points and characteristics of each letter. Today, there are also online platforms, videos, and books that provide step-by-step lessons.")
                        .font(.body)

                    Text(verbatim: "Focus on mastering the basic rules first, then gradually build your skills over time. Practicing consistently and recording your recitation can help you catch mistakes and improve pronunciation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("FOR MORE DETAILS")) {
                    NavigationLink(destination: LazyDestination { TajweedFoundationsView() }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: "Tajweed Foundations")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(appearance.accent)
                            Text(verbatim: "Comprehensive guide with rules, topics, and detailed explanations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: ArticleHeader("RESOURCES")) {
                    Text(verbatim: "Watch Learn Arabic 101: https://www.youtube.com/@Arabic101")
                        .font(.caption)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Reciting with Tajweed preserves the Quran's pronunciation as it was received from the Prophet, and beautifies and safeguards its meaning.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "TajweedView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tajweed")
        .selectableArticleList(article: "TajweedView")
        #if os(iOS)
        .sheet(isPresented: $showTajweedLegend) {
            NavigationView {
                TajweedLegendView()
            }
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
        #endif
    }
}

struct JuzView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Quran is divided into thirty roughly equal parts called Juz, making it easy to read over a month, especially in Ramadan.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "The Quran is divided into 114 Surahs (chapters), but it is also split into thirty roughly equal parts, called Juz (plural: Ajza).")
                        .font(.body)

                    Text(verbatim: "This division helps Muslims complete the Quran’s recitation systematically, often one Juz per day, especially during Ramadan.")
                        .font(.body)
                }

                Section(header: ArticleHeader("PURPOSE")) {
                    Text(verbatim: "The division into Juz is primarily for convenience rather than thematic arrangement. It enables systematic daily recitation.")
                        .font(.body)

                    Text(verbatim: "Many Muslims strive to complete the Quran in Ramadan, reciting one Juz per night in Taraweeh prayers. Each Juz is further divided into two Hizbs, making a total of 60 Hizbs.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(quran: "7:204")
                }

                Section(header: ArticleHeader("HISTORICAL NOTES")) {
                    Text(verbatim: "While the Quran's content remained unchanged since its revelation, the formal division into 30 Juz was standardized later to facilitate ease of recitation.")
                        .font(.body)

                    Text(verbatim: "This structure fosters a daily relationship with the Quran and encourages reflection on its meanings.")
                        .font(.body)

                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) emphasized balanced recitation, saying:")
                        .font(.body)

                    ScriptureQuote(hadith: "abudawud:1394", cite: "Sunan Abu Dawud 1394", arabic: 39...47, english: 4...19)
                }

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

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The thirty Juz are a practical division for reading and memorization, not part of the revelation's meaning, helping Muslims complete the Quran regularly.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "JuzView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Thirty Juz")
        .selectableArticleList(article: "JuzView")
    }
}

struct AhrufView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Quran was revealed in seven ahruf (modes of recitation) as a mercy easing its recitation for the different Arab tribes.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "The Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحرُف), the plural of Harf (حَرف). The word Harf comes from the Arabic root H–r–f (ح ر ف), meaning “edge, border, side, or angle,” referring to a particular “way” or “mode.” Islamically and Quranically, Ahruf refers to the divinely revealed modes of recitation.")
                        .font(.body)

                    Text(verbatim: "A Harf (حَرف), literally meaning “edge/side/aspect,” and in this context “a mode/way of reciting,” refers to a divinely revealed manner of recitation that includes slight differences in pronunciation, vowel patterns, pausing/connection, or permitted word-forms, while preserving the exact same meaning and guidance.")
                        .font(.body)

                    Text(verbatim: "All seven Ahruf are revelation from Allah (Glorified and Exalted be He). They are not scholarly opinions nor later inventions; they are part of the Quran that Allah (Glorified and Exalted be He) sent down to Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHY SEVEN AHRUF?")) {
                    Text(verbatim: "The Arabs at the time of revelation had many dialects (Quraysh, Hudhayl, Tamim, Hawazin, etc.). Allah (Glorified and Exalted be He), in His mercy, revealed the Quran in seven modes so that every tribe could recite the Quran easily without difficulty or burden.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) did not reveal seven different Qurans; rather, one Quran with divinely allowed flexibility, making memorization and recitation easier.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE WISDOM BEHIND THE VARIETY")) {
                    Text(verbatim: "Classical scholars draw out several wisdoms behind the revealed variety, beyond ease of recitation:")
                        .font(.body)

                    Text(verbatim: "• Mercy and ease: a largely unlettered nation of many dialects could all recite the Quran as it was revealed, without hardship.\n• A sign of inimitability (i'jaz): the wordings vary, yet the meanings align and complete one another; no mode contradicts another in a single ruling or belief.\n• Proof of its divine origin: had the Quran been from other than Allah (Glorified and Exalted be He), such parallel wordings would inevitably clash. They never do.\n• Extra preservation: each mode was memorized and passed on through its own verified channels, multiplying the independent lines guarding the text.")
                        .font(.body)

                    Text(verbatim: "As the narrations in Sahih Muslim make clear, the variation between the modes lies in how the words are recited, not in what the Quran commands: no harf permits what another forbids, and none changes the halal or the haram.")
                        .font(.body)
                }

                Section(header: ArticleHeader("PROPHETIC HADITH ON THE SEVEN AHRUF")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(text: "“The Quran was revealed in seven Ahruf, so recite whichever is easiest for you.”\n- Sahih al-Bukhari 4992 • Sahih Muslim 818", arabic: "إِنَّ هَذَا القُرآنَ أُنزِلَ عَلَى سَبعَةِ أَحرُفٍ فَاقرَءُوا مَا تَيَسَّرَ مِنهُ", dimmed: true)

                    Text(verbatim: "Another narration explains how Jibril kept requesting ease for the Ummah:")
                        .font(.body)

                    ScriptureQuote(text: "“Jibril recited to me in one harf. I asked him to increase it… until he ended with seven Ahruf.”\n- Sahih al-Bukhari 4991 • Sahih Muslim 819", arabic: "أَقرَأَنِي جِبرِيلُ عَلَى حَرفٍ فَرَاجَعتُهُ، فَلَم أَزَل أَستَزِيدُهُ وَيَزِيدُنِي حَتَّى انتَهَى إِلَى سَبعَةِ أَحرُفٍ", dimmed: true)

                    Text(verbatim: "In the famous incident of Umar and Hisham ibn Hakim: both of them recited differently, and Prophet Muhammad (peace and blessings be upon him) said that both were revealed, proving that the variations are not mistakes but revelation (Sahih al-Bukhari 4992; Sahih Muslim 818).")
                        .font(.title3)
                        .foregroundColor(appearance.accent.opacity(0.85))
                }

                Section(header: ArticleHeader("DO THE AHRUF AFFECT PRESERVATION?")) {
                    Text(verbatim: "No. The Quran remains perfectly preserved: letter for letter, word for word, in every revealed mode. The Ahruf are part of that preservation, not a contradiction to it.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) promised:")
                        .font(.body)

                    ScriptureQuote(quran: "15:9")

                    Text(verbatim: "The variations in Ahruf do not alter meanings, beliefs, or rulings. Rather, they highlight precision and perfection: the Ummah memorized and transmitted every letter exactly as revealed.")
                        .font(.body)

                    Text(verbatim: "Each harf is revealed, preserved, and protected by Allah (Glorified and Exalted be He). Muslims do not choose or invent a harf; we only recite what Allah (Glorified and Exalted be He) revealed through His Messenger, Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW AHRUF WERE PRESERVED")) {
                    Text(verbatim: "• Prophet Muhammad (peace and blessings be upon him) taught the Companions each harf personally.\n• Jibril reviewed the Quran with Prophet Muhammad (peace and blessings be upon him) every year in Ramadan.\n• In the year Prophet Muhammad (peace and blessings be upon him) passed away, Jibril reviewed it twice (al-Ardah al-Akhirah).")
                        .font(.body)

                    Text(verbatim: "About one year after the Prophet’s passing, Abu Bakr (may Allah be pleased with him) commissioned the first complete compilation of the Quran into one manuscript. During the caliphate of Uthman (may Allah be pleased with him), the Ummah was then unified upon official copies from that preserved compilation, written in the Uthmanic rasm and sent to all the major cities. Because the rasm was a bare skeletal script, without dots or tashkeel (vowel marks), it could carry the seven Ahruf, preserving what the Ummah recited. Dots and tashkeel did not even exist in Arabic writing yet; the Arabs did not need them, and it is precisely that bareness that let one written skeleton be read in every revealed way that matched it.")
                        .font(.body)

                    Text(verbatim: "The Ahruf are preserved through oral transmission, ijazahs, and chains of narration (isnad).")
                        .font(.body)
                }

                Section(header: ArticleHeader("AN ANALOGY: SEVEN NUMBERS, MANY PASSWORDS")) {
                    Text(verbatim: "Think of the seven Ahruf as seven numbers you are handed, and each Qiraah as a password formed from them. The numbers (Ahruf) are the revealed building blocks; a password (Qiraah) is one specific, fixed combination drawn from them, whether it uses one digit, a few, or all seven.")
                        .font(.body)

                    Text(verbatim: "Seven numbers could form far more than ten passwords, and likewise more readings than ten were transmitted historically. The 10 Qiraat are the combinations preserved with mass transmission (mutawatir): rigorously verified, widely taught, and famous across the Ummah.")
                        .font(.body)

                    Text(verbatim: "Since every harf is revealed by Allah (Glorified and Exalted be He), every canonical combination of them is fully Quran, and no combination was ever invented: each Qiraah was received from Prophet Muhammad (peace and blessings be upon him) through an unbroken chain and applies its rules with complete consistency, exactly as taught.")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("WHAT ABOUT THE 10 QIRAAT?")) {
                    Text(verbatim: "The 10 Qiraat are the mass-transmitted (mutawatir) methods that show how the Ahruf were preserved through the Uthmanic mushaf and teaching traditions.")
                        .font(.body)

                    Text(verbatim: "Each Qiraah has an unbroken chain (isnad) from the reciter → to his teacher → back to Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text(verbatim: "Learn more in the next section: 10 Qiraat (Canonical Recitations).")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("USEFUL LINKS")) {
                    Text(articleMarkdown: "Learn More about Ahruf and Qiraat: https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                        .font(.caption)
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The seven ahruf are all from Allah; the Uthmanic mushaf, written in a skeletal rasm without dots or tashkeel and sent to all the major cities, supported them, and the canonical recitations preserve them to this day.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "AhrufView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("7 Ahruf (Modes)")
        .selectableArticleList(article: "AhrufView")
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
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the ten Qiraat are the authentic, mass-transmitted ways of reciting the Quran, each traced through a continuous chain to the Prophet.")
                        .font(.body)
                }

                // The reading is one thing, seeing it another: the explorer walks the places where
                // the riwayat actually differ, ayah by ayah, with every reading side by side.
                #if os(iOS)
                Section(header: ArticleHeader("EXPLORE")) {
                    NavigationLink(destination: LazyDestination { QiraatExplorerView() }) {
                        QiraatDoorRow(systemImage: "arrow.left.and.right.text.vertical", title: "Qiraat Explorer",
                                      subtitle: "Every place the riwayat differ, ayah by ayah: what changes, what it means, and all twenty readings side by side")
                    }
                    NavigationLink(destination: LazyDestination { QiraatExplorerView(mode: .duel) }) {
                        QiraatDoorRow(systemImage: "arrow.left.arrow.right", title: "Head-to-Head",
                                      subtitle: "Pick any two riwayat and step through the places where they part ways")
                    }
                    NavigationLink(destination: LazyDestination { QiraatIsnadIndexView() }) {
                        QiraatDoorRow(systemImage: "point.3.connected.trianglepath.dotted", title: "Chains to the Prophet ﷺ",
                                      subtitle: "Every reading's isnad as a diagram: narrator, imam, Successors, Companions, the Prophet ﷺ")
                    }
                }
                #endif

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "The 10 Qiraat (قِرَاءَات), from the root q–r–a (قَرَأَ) meaning “to read/recite,” literally means “readings/recitations.” Islamically and Quranically, a Qiraah (قِرَاءَة) is a specific, verified method of reciting the Quran. The 10 Qiraat are the preserved, mass-transmitted (mutawatir, مُتَوَاتِر) recitations of the Quran, each a precise method taught by Prophet Muhammad (peace and blessings be upon him) and transmitted through authentic chains of narrators (isnad إِسنَاد). They do not represent different Qurans, but different prophetic ways of reciting the same revelation.")
                        .font(.body)

                    Text(verbatim: "As covered in the previous section, the Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحرُف), modes of recitation for ease. Jibril (Gabriel) brought these modes to Prophet Muhammad (peace and blessings be upon him), who taught them to the Ummah. Around one year after the Prophet’s passing, Abu Bakr (may Allah be pleased with him) commissioned the first complete compilation of the Quran into one manuscript, and later Uthman (may Allah be pleased with him) unified public recitation upon official copies from that preserved text, sent to all the major cities. The Qiraat show how those Ahruf were preserved in practice through the Uthmanic rasm (الرَّسم العُثمَانِي), the consonantal skeleton of the mushaf (مُصحَف): dots and tashkeel did not yet exist in Arabic writing (nor did the Arabs need them), so the bare skeleton naturally supported the seven Ahruf, readable in every revealed way that matched the rasm.")
                        .font(.body)

                    // Every reading carries a city, and the article named them only in passing on the
                    // rows below (Abu, 2026-09-14: "qiraat view should also mention the city they were
                    // developed in"). Cities here are the ones the app's own profiles ship in
                    // `QiraatProfiles.masters`, so the prose and the rows can never disagree.
                    Text(verbatim: "This is also why every Qiraah carries a city with it. Uthman (may Allah be pleased with him) sent a mushaf to each major centre and a teacher to recite by it, and the recitation of that centre settled around them, passing from teacher to student until one imam became its recognised authority. A Qiraah is named after that imam, but what he transmitted is the established reading of his city: Madinah (Nafi and, before him, his own teacher Abu Ja'far), Makkah (Ibn Kathir), Basrah (Abu Amr and, after him, Ya'qub), Damascus and greater Sham (Ibn Amir), and Kufah (Asim, Hamzah and al-Kisai, with Khalaf later carrying the Kufan tradition on from Baghdad).")
                        .font(.body)
                }

                Section(header: ArticleHeader("AN ANALOGY: SEVEN NUMBERS, MANY PASSWORDS")) {
                    Text(verbatim: "Imagine being handed seven numbers and asked to form passwords from them. The seven numbers are like the seven Ahruf: every one of them revealed by Allah (Glorified and Exalted be He). A password formed from those numbers is like a Qiraah: one specific, fixed combination drawn from the revealed modes.")
                        .font(.body)

                    Text(verbatim: "A password does not have to use all seven digits; it may draw on one, a few, or all of them. In the same way, a Qiraah may reflect one harf, several, or elements of many, and it is fully Quran either way, because every harf on its own is revealed Quran, and any single Qiraah on its own is sufficient, complete Quran.")
                        .font(.body)

                    Text(verbatim: "Just as seven numbers can form far more than ten passwords, the revealed modes could combine into more readings than ten, and other readings were indeed transmitted historically. The 10 Qiraat are the combinations that reached us mutawatir (mass-transmitted): rigorously verified, taught continuously from teacher to student, and famous across the Ummah. Together they keep the seven Ahruf alive, carried by the Uthmanic rasm, whose skeletal script (no dots or tashkeel) supported them all.")
                        .font(.body)

                    Text(verbatim: "But no one sat down and invented these combinations. Each Qiraah was received, not designed: it descends through an unbroken chain (isnad) from its reciters → their teachers → a Companion → Prophet Muhammad (peace and blessings be upon him), who taught it exactly this way.")
                        .font(.body)
                        .foregroundColor(appearance.accent)

                    Text(verbatim: "Because each Qiraah is Quran, reciting one ayah in one Qiraah and the next ayah in another is still reciting nothing but the Book of Allah (Glorified and Exalted be He); the Companions themselves recited in different revealed ways, and Prophet Muhammad (peace and blessings be upon him) approved them all.")
                        .font(.body)

                    Text(verbatim: "And like a password that must be entered exactly, each Qiraah keeps its own rules from the Ahruf alive with complete internal consistency: its madd lengths, imalah, assimilations, and word-forms are applied the same way every single time, exactly as transmitted.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT IS A QIRAAH?")) {
                    Text(verbatim: "A Qiraah (قِرَاءَة) is a canonical, authenticated way of reciting the Quran that meets three criteria: (1) agreement with the Uthmanic rasm (الرَّسم العُثمَانِي), (2) sound Arabic language, and (3) authentic, widespread transmission (tawatur تَوَاتُر).")
                        .font(.body)

                    Text(verbatim: "All 10 Qiraat return to Prophet Muhammad (peace and blessings be upon him). Every reciter has an unbroken chain of students → teachers → Companions → Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(appearance.accent)

                    Text(verbatim: "Most differences are within established rules of tajwid (تَجوِيد), allowable word-forms and vowels, elongation (madd مَدّ), assimilation (idgham إِدغَام), imalah (إِمَالَة), and stopping/continuation, while preserving the same meanings and guidance.")
                        .font(.body)

                    Text(verbatim: "Important: The Qiraat are not arbitrary. They reflect how the seven Ahruf were preserved through both writing and oral transmission, essentially a “mix and preserve” of the revealed modes into rigorously taught, verifiable recitational methods.")
                        .font(.body)

                    Text(verbatim: "This precision goes back to how the Quran was taught from the very beginning: the Companions would take a portion of ayat from Prophet Muhammad (peace and blessings be upon him) and not move past it until they had mastered both its recitation and what it contained. The Qiraat continue that discipline, teacher to student, to this day.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW THE READINGS DIFFER")) {
                    Text(verbatim: "Imam Ibn al-Jazari (d. 833 AH), the foremost authority of this science, grouped the differences between the canonical readings into three kinds:")
                        .font(.body)

                    Text(verbatim: "• The same word, pronounced in more than one revealed way, with the meaning unchanged.\n• Different word-forms pointing to the same reality: in Surah al-Fatihah, “Maliki yawmid-din” (King of the Day of Judgment) and “Maaliki yawmid-din” (Owner of the Day of Judgment) are both revealed, and both describe Allah (Glorified and Exalted be He).\n• Different words carrying complementary meanings: each reading adds a facet, and none contradicts another.")
                        .font(.body)

                    Text(verbatim: "There is no fourth category of contradiction. Across all the canonical readings, not a single ayah makes lawful what another forbids or affirms what another denies; the differences enrich the meaning, never oppose it.")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("QIRAAH (قِرَاءَة) VS RIWAYAH (رِوَايَة)")) {
                    Text(verbatim: "• Qiraah: the recitation method attributed to an Imam of recitation (e.g., Nafi, Asim).")
                        .font(.body)
                    Text(verbatim: "• Riwayah: the narration/transmission of that Qiraah by a primary rawi (narrator). Each Qiraah has two principal riwayaat (plural of riwayah).")
                        .font(.body)

                    Text(verbatim: "Example: “Hafs an Asim” means the riwayah (narration) of Hafs (حَفص) from the Qiraah (recitation) of Asim (عَاصِم). “Warsh an Nafi” means the riwayah of Warsh (وَرش) from the Qiraah of Nafi (نَافِع).")
                        .font(.body)

                    Text(verbatim: "Hafs an Asim is the most widespread globally today; that does not mean it is the only right one. All 10 Qiraat (and their 20 Riwayaat) are valid, mutawatir, and from Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("COMMON CLARIFICATIONS")) {
                    Text(verbatim: "Many people hear about 7 and 10 together. Both references are used by scholars: the famous seven canonical recitations (al-Sab'ah) and the full ten canonical Qiraat (7 + 3), all preserved through reliable transmission.")
                        .font(.body)

                    Text(verbatim: "The original seven were famously codified by Imam Abu Bakr Ibn Mujahid. Their Imams are: Nafi (Madinah), Ibn Kathir (Makkah), Abu Amr (Basra), Ibn Amir (Damascus), Asim (Kufa), Hamzah (Kufa), and al-Kisai (Kufa).")
                        .font(.body)

                    Text(verbatim: "The three that complete the ten, established by Imam Ibn al-Jazari, are: Abu Ja'far (Madinah), Ya'qub al-Hadrami (Basra), and Khalaf al-Bazzar (Baghdad, transmitting the Kufan tradition he received through Hamzah).")
                        .font(.body)

                    Text(verbatim: "Hafs is a riwayah from Asim, and Warsh is a riwayah from Nafi. So when people say Hafs or Warsh, they are naming a narration path within the canonical recitation tradition.")
                        .font(.body)

                    Text(verbatim: "Today, Hafs an Asim is the most widely recited globally (often estimated around 90%+), while other canonical recitations such as Warsh an Nafi remain authentic and practiced.")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("AUTHENTICITY & PRESERVATION")) {
                    Text(verbatim: "The 10 Qiraat are mutawatir, mass attested by many independent chains. They are part of the precise preservation Allah (Glorified and Exalted be He) promised for His Book.")
                        .font(.body)

                    ScriptureQuote(quran: "15:9")

                    Text(verbatim: "They do not affect preservation; rather, they manifest it: letter for letter, word for word, in all the ways Prophet Muhammad (peace and blessings be upon him) taught.")
                        .font(.body)

                    Text(verbatim: "Every canonical reading is equally Quran. As classical scholars explain, each one is revelation received by Prophet Muhammad (peace and blessings be upon him) and taught by him; none is a scholar's preference or a later refinement. Whoever recites by any canonical riwayah is reciting the Book of Allah (Glorified and Exalted be He) itself.")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("THE FOUR MASTERS OF THE QURAN")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4999", cite: "Sahih al-Bukhari 4999", arabic: 34...47, english: 22...36)

                    Text(verbatim: "These four masters were among the foremost teachers of the Quran among the Companions, and their recitation and teaching shaped subsequent generations of transmitters.")
                        .font(.body)
                }

                // The ten as scholars actually count them: the seven of Ibn Mujahid, then the three
                // Ibn al-Jazari completed them with (Abu, 2026-09-04: "split up the 10 qiraat into the
                // original 7 and then the added 3"). Every row also says where the reading is recited
                // today, and the profile pages carry the full sentence.
                Section(header: ArticleHeader("THE SEVEN QIRAAT (القِرَاءَاتُ السَّبعُ)")) {
                    Text(verbatim: "The seven readings Imam Abu Bakr Ibn Mujahid (d. 324 AH) collected in his Kitab al-Sab'ah, one from each of the great centres of recitation: Madinah, Makkah, Basra and Damascus, and three from Kufa. Each is named after its imam. Tap any of them to read about the imam, his two narrators, and where the reading is recited today.")
                        .font(.body)

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
                    Text(verbatim: "The three readings Imam Ibn al-Jazari (d. 833 AH) established as equally mutawatir in al-Durrah al-Mutammimah, completing the ten: Abu Ja'far of Madinah, Ya'qub of Basra and Khalaf of Kufa (the tenth reader, a different reading from his own narration of Hamzah). Together with the seven they are the ten Qiraat.")
                        .font(.body)

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

                Section(header: ArticleHeader("THE 14 RIWAYAAT OF THE SEVEN")) {
                    Text(verbatim: "Each Qiraah (recitation method) has two primary riwayaat (narrations). These are the fourteen transmissions of the seven readings, grouped under their imam in the same order as above, with where each is recited today. Tap any of them to read about the narrator.")
                        .font(.body)

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
                    Text(verbatim: "The six transmissions of the three completing readings. All twenty riwayaat together are the canonical transmissions used in teaching and ijazah (chain certification).")
                        .font(.body)

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
                    Text(verbatim: "Every Qiraah traces back through its Imam and narrators to the Companions (may Allah be pleased with them) who learned the Quran directly from Prophet Muhammad (peace and blessings be upon him). The chains below show which Companions each reading is transmitted from.")
                        .font(.body)

                    #if os(iOS)
                    NavigationLink(destination: LazyDestination { QiraatIsnadIndexView() }) {
                        Label("See every chain as a diagram, link by link", systemImage: "point.3.connected.trianglepath.dotted")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(appearance.accent)
                    }
                    #endif

                    Group {
                        Text(articleMarkdown: "**Nafi (Qari of Madinah)**: narrated by Warsh and Qalun. Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Ibn Kathir (Qari of Makkah)**: narrated by al-Bazzi and Qunbul. Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, and Abdullah ibn as-Sa’ib (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Abu Amr al-Basri (Qari of Basrah)**: narrated by ad-Duri and as-Susi. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Abu Musa al-Ash‘ari, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abdullah ibn as-Sa’ib, Ubayy ibn Ka‘b, Zayd ibn Thabit, and Abu Hurayrah (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Ibn Amir (Qari of Sham)**: narrated by Hisham and Ibn Dhakwan. Transmitted from Uthman ibn Affan and Abu ad-Darda (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Asim ibn Abi an-Najud (Qari of Kufah)**: narrated by Shu‘bah and Hafs. Most Muslims today recite via Hafs from Asim. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Zayd ibn Thabit, and Ubayy ibn Ka‘b (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Hamzah az-Zayyat (Qari of Kufah)**: narrated by Khalaf and Khallad. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Ali ibn Hamzah al-Kisai (Qari of Kufah)**: narrated by Abu al-Harith and ad-Duri. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abu Hurayrah, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Ya‘qub al-Hadrami (Qari of Basrah)**: narrated by Ruways and Rawh. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, Abu Musa al-Ash‘ari, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abdullah ibn as-Sa’ib, and Abu Hurayrah (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Khalaf al-Bazzar (Qari of Baghdad, in the Kufan tradition)**: narrated by Idris and Ishaq. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Zayd ibn Thabit, Ubayy ibn Ka‘b, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text(articleMarkdown: "**Abu Ja‘far al-Madani (Qari of Madinah)**: narrated by Ibn Wardan and Ibn Jammaz. Transmitted from Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them).")
                    }
                    .font(.body)
                }

                Section(header: ArticleHeader("WHAT THIS CHAIN SHOWS")) {
                    Text(verbatim: "We begin with what Prophet Muhammad (peace and blessings be upon him) began with: the Book of Allah (Glorified and Exalted be He). It is well established that the Quran has reached us by mass transmission (tawatur) through the chains of Ahl as-Sunnah wal-Jama‘ah.")
                        .font(.body)

                    Text(verbatim: "Every one of these narrators of the noble Quran received it, through the chains above, from the Messenger of Allah (peace and blessings be upon him) by way of his Companions (may Allah be pleased with them), the first to learn, gather, preserve, and transmit it.")
                        .font(.body)

                    Text(verbatim: "Not a single Ithna Ashari (Twelver) Shia is found among these transmitters. This is part of the Quran’s preservation: Allah (Glorified and Exalted be He) did not place in the transmission of His Book anyone who slanders the Companions of His Prophet (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(appearance.accent)

                    Link(destination: URL(string: "https://mahajjah.com/the-manner-in-which-the-ahlus-sunnah-and-shia-act-upon-this-hadith/")!) {
                        Label("Source: Mahajjah - Ahlus Sunnah and Shia on this hadith", systemImage: "link")
                    }
                    .font(.caption)
                }

                Section(header: ArticleHeader("OTHER REPORTED QIRAAT")) {
                    Text(verbatim: "There are other reported qiraat besides these Ten. Unlike the 10 Qiraat, which are mutawatir and mass attested, those others do not reach mutawatir status. That does not automatically make them inauthentic; some have isnad to Prophet Muhammad (peace and blessings be upon him), but because they are not mass attested, we avoid them in public recitation and worship.")
                        .font(.body)

                    Text(verbatim: "We recite what is known with certainty (yaqin يَقِين) to be from Prophet Muhammad (peace and blessings be upon him): the 10 Qiraat and their 20 Riwayaat. This unites the Ummah upon what is rigorously established.")
                        .font(.body)
                }

                Section(header: ArticleHeader("PRACTICAL STUDY & ADVICE")) {
                    Text(verbatim: "• Learn with a qualified teacher who has ijazah (إِجَازَة) and isnad (إِسنَاد). Do not self-invent pronunciations or rely only on apps without verification.")
                        .font(.body)
                    Text(verbatim: "• Begin with one riwayah (commonly Hafs an Asim), then explore others (e.g., Warsh an Nafi) as you progress.")
                        .font(.body)
                    Text(verbatim: "• Remember: differences are a mercy, not a contradiction. They illuminate the Quran’s depth and precision.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN-APP AUDIO")) {
                    Text(verbatim: "In this app, every one of the 20 riwayaat has at least one complete full-surah reciter. Ayah-by-ayah playback remains Hafs-based, so availability varies by full-surah vs. ayah-by-ayah playback.")
                        .font(.body)
                }

                Section(header: ArticleHeader("RECAP")) {
                    Text(verbatim: "“The 10 Qiraat are the preserved, mass-transmitted (mutawatir) recitations taught by Prophet Muhammad (peace and blessings be upon him), passed down through authentic chains. Each Qiraah is a specific, verified method of reciting the Quran, not a different text. They reflect how the Ahruf were preserved in writing and oral transmission. All 10 Qiraat (and their 20 Riwayaat) return to Prophet Muhammad (peace and blessings be upon him).”")
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

                Section(header: ArticleHeader("USEFUL LINKS")) {
                    Text(articleMarkdown: "Learn More about Ahruf and Qiraat: https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                        .font(.caption)

                    Text(articleMarkdown: "Learn about the other Qiraat: https://www.youtube.com/watch?v=CeV6w0rCilQ&t=80s")
                        .font(.caption)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The differences among the Qiraat are all revelation and add richness of meaning; none contradicts another, and all are recited today.")
                        .font(.body)

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
                        Label("Riwayah Statistics: How Far Each Differs from Hafs", systemImage: "flask")
                    }
                    .foregroundColor(appearance.accent)
                    #endif
                }

                ArticleSourcesSection(article: "QiraatView")
            }
            .themedListRowBackground()
        }
        #if DEBUG && os(iOS)
        .debugPushDestination(isPresented: $debugOpenExplorer) {
            // "-qiraatExplorerMode duel|surah" opens that mode instead of All Riwayat.
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
        .selectableArticleList(article: "QiraatView")
    }

    /// A tappable Instagram handle that opens the creator's profile, used for the infographic credits.
    private func qiraatCreditLink(handle: String) -> some View {
        Link(destination: URL(string: "https://www.instagram.com/\(handle)/")!) {
            Label("@\(handle)", systemImage: "at")
        }
    }
}

struct FarewellView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Farewell Sermon was the Prophet's final address to the Ummah at Arafat, summarizing the core teachings of Islam for all time.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: """
                         The Farewell Sermon (خُطبَةُ ٱلوَدَاعِ), delivered by Prophet Muhammad (peace be upon him), took place on the 9th of Dhu al-Hijjah in the 10th year of Hijrah (632 CE) in the Uranah Valley near Mount Arafat. This sermon is one of the most significant moments in Islamic history, as it encapsulates key teachings and guidance for Muslims.
                         """)
                    .font(.body)

                    Text(verbatim: "During this momentous occasion, Allah (Glorified and Exalted be He) revealed:")
                        .font(.body)
                    ScriptureQuote(quran: "5:3", words: 39...49)
                }

                Section(header: ArticleHeader("FINAL DAYS OF THE PROPHET")) {
                    Text(verbatim: "After delivering this sermon, the Prophet (peace be upon him) continued to guide the Muslim Ummah until his passing in Rabi’ al-Awwal, 11 AH (632 CE); the 12th is the popular date, though the exact day is disputed. He passed away in the home of Aisha (may Allah be pleased with her), his head resting on her lap, and his final words, expressing his longing to meet Allah, were:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:4463", cite: "Sahih al-Bukhari 4463", arabic: 63...65, english: 111...116)
                }

                Section(header: ArticleHeader("TEXT OF THE SERMON")) {
                    Text(verbatim: "The popular “full text” of the Farewell Sermon is a later composite. Below are its portions as they are actually narrated, each with its source: from Jabir ibn Abdullah’s account of the Hajj in Sahih Muslim, from the sermon of the Day of Sacrifice in Sahih al-Bukhari, and from the remaining authentic reports. Every line here is sahih or hasan; lines that circulate as part of the sermon without a chain are not included, even where the words are authentic elsewhere.")
                        .font(.body)

                    Text(verbatim: "He (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:1218a", cite: "Sahih Muslim 1218", arabic: 783...796, english: 1278...1305)
                    ScriptureQuote(hadith: "bukhari:1739", cite: "Sahih al-Bukhari 1739", arabic: 66...80, english: 67...98)
                    ScriptureQuote(hadith: "muslim:1218a", cite: "Sahih Muslim 1218", arabic: 827...841, english: 1361...1389)
                    ScriptureQuote(hadith: "muslim:1218a", cite: "Sahih Muslim 1218", arabic: 842...874, english: 1390...1470)
                    ScriptureQuote(hadith: "muslim:1218a", cite: "Sahih Muslim 1218", arabic: 875...886, english: 1471...1491)
                    ScriptureQuote(hadith: "tirmidhi:616", cite: "Sunan al-Tirmidhi 616; graded sahih by al-Albani", arabic: 38...53, english: 21...57)
                    ScriptureQuote(hadith: "tirmidhi:2159", cite: "Sunan al-Tirmidhi 2159; graded sahih by al-Albani", arabic: 72...93, english: 80...112)
                    ScriptureQuote(text: "“O people, your Lord is one and your father is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red (light-skinned) person over a black person, nor of a black person over a red person, except by taqwa” (Musnad Ahmad 23489; graded sahih by al-Albani, as-Silsilah as-Sahihah 2700).", arabic: "يَا أَيُّهَا النَّاسُ، أَلَا إِنَّ رَبَّكُم وَاحِدٌ، وَإِنَّ أَبَاكُم وَاحِدٌ، أَلَا لَا فَضلَ لِعَرَبِيٍّ عَلَى عَجَمِيٍّ، وَلَا لِعَجَمِيٍّ عَلَى عَرَبِيٍّ، وَلَا أَحمَرَ عَلَى أَسوَدَ، وَلَا أَسوَدَ عَلَى أَحمَرَ، إِلَّا بِالتَّقوَى", dimmed: true)
                    ScriptureQuote(hadith: "bukhari:1739", cite: "Sahih al-Bukhari 1739", arabic: 113...123, text: "“It is incumbent upon those who are present to convey this information to those who are absent Beware don't renegade (as) disbelievers (turn into infidels) after me, Striking the necks (cutting the throats) of one another”")

                    Text(verbatim: "Then he asked them:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:1218a", cite: "Sahih Muslim 1218", arabic: 888...917, english: 1492...1564)
                    ScriptureQuote(hadith: "bukhari:1739", cite: "Sahih al-Bukhari 1739", arabic: 89...94, english: 116...130)
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

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "In it the Prophet affirmed the sanctity of life and property, the equality of all people, the rights of women, and clinging to the Quran and Sunnah, delivered as his religion was perfected.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "FarewellView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Farewell Sermon")
        .selectableArticleList(article: "FarewellView")
    }
}

struct SahabahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Sahabah are the Companions who accompanied the Prophet, believed in him, and carried Islam to the world, the best generation of this Ummah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "The **Sahabah (الصَّحَابَة)**, from the root **s-h-b (ص ح ب)**, companionship, are the companions of Prophet Muhammad (peace be upon him).")
                        .font(.body)

                    Text(verbatim: "They supported him in his mission, witnessed the revelation of the Quran, and preserved the teachings of Islam through word and action.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) praised them in the Quran:")
                        .font(.body)
                    ScriptureQuote(quran: "9:100", words: 0...12)

                    Text(verbatim: "And the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:2652", cite: "Sahih al-Bukhari 2652", arabic: 29...37, english: 4...23)
                }

                Section(header: ArticleHeader("ABU BAKR AS-SIDDIQ")) {
                    Text(verbatim: "Abu Bakr (may Allah be pleased with him) was the Prophet’s (peace be upon him) closest friend and the first adult male to embrace Islam.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3656", cite: "Sahih al-Bukhari 3656", arabic: 27...38, english: 4...26)

                    Text(verbatim: "He was known as As-Siddiq (the Truthful) for immediately affirming the Prophet’s Night Journey (Isra’ and Mi’raj). He was chosen as the first Caliph after the Prophet’s death and led the Muslim Ummah with wisdom and justice.")
                        .font(.body)

                    Text(verbatim: "About one year after the Prophet’s passing, he commissioned Zayd ibn Thabit to compile the Quran into a single manuscript, preserving the revelation in written form alongside mass memorization.")
                        .font(.body)
                }

                Section(header: ArticleHeader("UMAR IBN AL-KHATTAB")) {
                    Text(verbatim: "Umar (may Allah be pleased with him) was known for his strength, justice, and piety. He was the second Caliph and expanded the Islamic state significantly.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:3686", cite: "Sunan al-Tirmidhi 3686; graded hasan by al-Albani, as-Silsilah as-Sahihah 327", arabic: 33...40, english: 7...22)

                    Text(verbatim: "Allah (Glorified and Exalted be He) revealed verses agreeing with Umar’s opinions, including the veiling of the Prophet's wives (Sahih al-Bukhari 402) and the prohibition of alcohol (Sunan Abi Dawud 3670; graded sahih by al-Albani).")
                        .font(.body)
                }

                Section(header: ArticleHeader("UTHMAN IBN AFFAN")) {
                    Text(verbatim: "Uthman (may Allah be pleased with him) was known for his generosity, modesty, and devotion. He unified the Ummah upon official copies of the already compiled Quran, based on the manuscript first compiled under Abu Bakr.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) climbed Mount Uhud with Abu Bakr, Umar, and Uthman, and when it shook beneath them he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3675", cite: "Sahih al-Bukhari 3675", arabic: 37...43, english: 27...45)

                    Text(verbatim: "He bought the well of Rumah for the Muslims, funded the expansion of Al-Masjid an-Nabawi, and equipped the army of Tabuk (Sahih al-Bukhari 2778). His contributions earned him repeated praise from the Prophet (peace be upon him).")
                        .font(.body)
                }

                Section(header: ArticleHeader("ALI IBN ABI TALIB")) {
                    Text(verbatim: "Ali (may Allah be pleased with him) was the cousin and son-in-law of the Prophet (peace be upon him). He was a scholar, warrior, and deeply spiritual leader.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said to him:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2404a", cite: "Sahih Muslim 2404", arabic: 58...68, english: 0...29)

                    Text(verbatim: "He was among the most learned of the Companions, and many later scholars traced their knowledge back to him. He was known for his eloquence, bravery, and deep understanding of Islam.")
                        .font(.body)
                }

                Section(header: ArticleHeader("MUHAJIREEN & ANSAR")) {
                    Text(verbatim: "The Muhajireen were those who emigrated with the Prophet (peace be upon him) from Makkah to Madinah, leaving behind their wealth and homes for the sake of Allah.")
                        .font(.body)

                    Text(verbatim: "The Ansar were the residents of Madinah who welcomed the Prophet (peace be upon him) and his followers with open hearts and supported them in every way.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) praised them both:")
                        .font(.body)
                    ScriptureQuote(quran: "59:9", words: 0...19)
                }

                Section(header: ArticleHeader("LEGACY")) {
                    Text(verbatim: "The Sahabah preserved the Quran and Hadith, established justice and governance, and exemplified the moral and ethical teachings of Islam.")
                        .font(.body)

                    Text(verbatim: "Their legacy continues to inspire faith, sacrifice, knowledge, and courage in Muslims to this day.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Allah praised the Companions and was pleased with them. Through them the Quran and Sunnah were preserved and conveyed, and honoring them is part of the faith.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "SahabahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Sahabah")
        .selectableArticleList(article: "SahabahView")
    }
}

struct WivesView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the wives of the Prophet are the “Mothers of the Believers,” honored for their faith, and several became key teachers of Islam.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "The wives of Prophet Muhammad (peace be upon him) are honored in Islam as the “Mothers of the Believers” (أُمَّهَاتُ المُؤمِنِين).")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(quran: "33:6", words: 0...6)

                    Text(articleMarkdown: "Prophet Muhammad (peace be upon him) married a total of **11 women** throughout his lifetime. At one time, he was married to a maximum of **9 wives** simultaneously, an exception granted to him as a Prophet. This exception was not unique to him; it was also granted to previous prophets due to their elevated responsibilities and status. For example, Prophet Solomon (peace be upon him) is known to have had a large number of wives, traditionally said to be 100 or more.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SUPPORT & CONTRIBUTION")) {
                    Text(verbatim: "These women supported the Prophet (peace be upon him) in his mission.")
                        .font(.body)

                    Text(verbatim: "They played vital roles in educating the Muslim community, transmitting Hadith, and exemplifying piety and devotion.")
                        .font(.body)

                    Text(articleMarkdown: "Most of his wives were **widows or divorcees**. These marriages were not driven by desire but by **wisdom, compassion, and community building**.")
                        .font(.body)

                    Text(articleMarkdown: "His marriage to **Khadijah bint Khuwaylid** (may Allah be pleased with her) was monogamous and lasted about 25 years, until her death. She was about 15 years older than him, and he took no other wife during her lifetime.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KHADIJAH")) {
                    Text(articleMarkdown: "Khadijah bint Khuwaylid (may Allah be pleased with her) was the first person to believe in Prophet Muhammad (peace be upon him) and thus the **first Muslim**. After his first revelation in the cave of Hira, she comforted him, wrapped him in a cloak, and reassured him with her deep insight and love.")
                        .font(.body)

                    Text(verbatim: "She said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3", cite: "Sahih al-Bukhari 3", arabic: 186...204, english: 314...346)

                    Text(articleMarkdown: "Allah (Glorified and Exalted be He) affirmed the beginning of the Prophet’s (peace be upon him) mission in **Surah Al-Muzzammil (73:1)** and **Surah Al-Muddaththir (74:1)**, moments when Khadijah (may Allah be pleased with her) lovingly wrapped and comforted him.")
                        .font(.body)
                        .foregroundColor(appearance.accent)

                    Text(verbatim: "The Prophet (peace be upon him) said of her:")
                        .font(.body)
                    ScriptureQuote(text: "“She believed in me when the people disbelieved in me, she affirmed my truthfulness when the people belied me, she supported me with her wealth when the people deprived me, and Allah granted me her children when He withheld from me the children of other women” (Musnad Ahmad 24864; its chain graded hasan by Ibn Hajar, Fath al-Bari 7/138, and by Shu'ayb al-Arna'ut).", arabic: "آمَنَت بِي إِذ كَفَرَ بِي النَّاسُ، وَصَدَّقَتنِي إِذ كَذَّبَنِي النَّاسُ، وَوَاسَتنِي بِمَالِهَا إِذ حَرَمَنِي النَّاسُ، وَرَزَقَنِي اللَّهُ عَزَّ وَجَلَّ وَلَدَهَا إِذ حَرَمَنِي أَولَادَ النِّسَاءِ", dimmed: true)
                    Text(verbatim: "Aisha (may Allah be pleased with her) reported that he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2435b", cite: "Sahih Muslim 2435", arabic: 66...69, english: 69...79)
                }

                Section(header: ArticleHeader("AISHA")) {
                    Text(verbatim: "Aisha bint Abi Bakr (may Allah be pleased with her) was the daughter of Abu Bakr as-Siddiq (may Allah be pleased with him), the closest companion of the Prophet (peace be upon him). She was among the most knowledgeable of the Companions, especially in Hadith and Islamic jurisprudence, and the Companions would turn to her when a matter was difficult for them.")
                        .font(.body)

                    Text(articleMarkdown: "She was falsely accused in the incident of al-Ifk, but Allah (Glorified and Exalted be He) revealed her innocence in **Surah An-Nur (24:11–26)**, establishing her purity and honor for all time.")
                        .font(.body)
                        .foregroundColor(appearance.accent)

                    Text(verbatim: "Amr ibn al-As (may Allah be pleased with him) asked the Prophet (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3662", cite: "Sahih al-Bukhari 3662", arabic: 39...52, english: 17...37)

                    Text(verbatim: "He also said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2446a", cite: "Sahih Muslim 2446", arabic: 35...43, english: 0...15)

                    Text(verbatim: "After the Prophet’s (peace be upon him) death, she became one of the greatest scholars of Islam. She taught both men and women and was a source of religious rulings and interpretations.")
                        .font(.body)

                    Text(articleMarkdown: "She narrated **2,210 hadiths**, making her the **fourth-highest hadith narrator** of all time. Most of these relate to the Prophet’s private life, which only she had access to. Without Aisha (may Allah be pleased with her), much of the Prophet’s (peace be upon him) household life, worship, and character would not be known today.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW HE TREATED HIS WIVES")) {
                    Text(verbatim: "The Prophet (peace be upon him) was the best example of kindness, patience, and love toward his wives. These hadiths reflect his character:")
                        .font(.body)

                    ScriptureQuote(hadith: "tirmidhi:3895", cite: "Sunan al-Tirmidhi 3895; graded sahih by al-Albani", arabic: 30...35, english: 7...34)

                    Text(verbatim: "Aisha (may Allah be pleased with her) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2328a", cite: "Sahih Muslim 2328", arabic: 13...27, english: 3...17)

                    Text(verbatim: "He said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:1468b", cite: "Sahih Muslim 1468", arabic: 38...48, english: 0...21)

                    Text(verbatim: "And Aisha (may Allah be pleased with her) said of his life at home:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:6039", cite: "Sahih al-Bukhari 6039", arabic: 26...35, english: 15...37)
                }

                Section(header: ArticleHeader("THE ELEVEN WIVES")) {
                    Group {
                        Text(verbatim: "• Khadijah bint Khuwaylid (may Allah be pleased with her)")
                        Text(verbatim: "• Sawdah bint Zam’ah (may Allah be pleased with her)")
                        Text(verbatim: "• Aisha bint Abi Bakr (may Allah be pleased with her)")
                        Text(verbatim: "• Hafsah bint Umar (may Allah be pleased with her)")
                        Text(verbatim: "• Zaynab bint Khuzaymah (may Allah be pleased with her)")
                        Text(verbatim: "• Umm Salamah (Hind bint Abi Umayyah) (may Allah be pleased with her)")
                        Text(verbatim: "• Zaynab bint Jahsh (may Allah be pleased with her)")
                        Text(verbatim: "• Juwayriyah bint al-Harith (may Allah be pleased with her)")
                        Text(verbatim: "• Umm Habibah (Ramlah bint Abi Sufyan) (may Allah be pleased with her)")
                        Text(verbatim: "• Safiyyah bint Huyayy (may Allah be pleased with her)")
                        Text(verbatim: "• Maymunah bint al-Harith (may Allah be pleased with her)")
                    }
                    .font(.body)
                }

                Section(header: ArticleHeader("WHY SO MANY MARRIAGES?")) {
                    Text(verbatim: "These marriages fulfilled many noble purposes:")
                        .font(.body)

                    Text(articleMarkdown: "• **Supporting widows** who lost husbands in early battles.")
                        .font(.body)

                    Text(articleMarkdown: "• **Forming alliances** with key tribes to strengthen the Muslim community.")
                        .font(.body)

                    Text(articleMarkdown: "• **Spreading Islamic knowledge**, as many of his wives became teachers and Hadith narrators.")
                        .font(.body)

                    Text(articleMarkdown: "• **Setting legal and social precedents** for Muslim family law and ethics.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LEGACY")) {
                    Text(verbatim: "The lives of the Prophet’s (peace be upon him) wives highlight the essential role of women in Islamic scholarship and community-building.")
                        .font(.body)

                    Text(verbatim: "They are role models for Muslims, inspiring faith, resilience, and devotion.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Through the Prophet's wives, especially Aisha, much of the Sunnah of the home and worship reached the Ummah; loving and respecting them is part of the religion.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "WivesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Wives")
        .selectableArticleList(article: "WivesView")
    }
}

struct CaliphatesView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Caliphate is the leadership that continued the Prophet's mission, beginning with the Rightly Guided Caliphs Abu Bakr, Umar, Uthman, and Ali.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "The **Caliphate (الخِلَافَة)**, from the root **kh-l-f (خ ل ف)**, meaning succession, refers to the divinely guided system of governance established after the death of Prophet Muhammad (peace be upon him). It aimed to continue his mission of upholding justice, spreading Islam, and preserving the unity of the Ummah.")
                        .font(.body)

                    Text(articleMarkdown: "The Caliph (خَلِيفَة), literally “successor,“ was entrusted with political, military, judicial, and spiritual leadership, guided by the Quran and Sunnah. The first four caliphs, known as the **Rightly Guided Caliphs (ٱلخُلَفَاء ٱلرَّاشِدُون)**, are regarded as models of righteous rule.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:4646", cite: "Sunan Abi Dawud 4646; graded hasan sahih by al-Albani", arabic: 26...39, english: 4...24)

                    Text(articleMarkdown: "These thirty years, known as the **Rashidun Caliphate**, represented the ideal Islamic system. The caliphs were chosen by **consultation (شُورَىٰ)** and the pledge of allegiance (**bay'ah, بَيعَة**) of the community: Abu Bakr at Saqifah and then in the mosque, and Uthman after Abd al-Rahman ibn Awf consulted the Muhajirun, the Ansar, and the commanders for three nights (Sahih al-Bukhari 7207). This model emphasized justice, humility, accountability, and service to the people.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ABU BAKR AS-SIDDIQ (632–634 CE)")) {
                    Text(articleMarkdown: "Abu Bakr (may Allah be pleased with him), the Prophet’s closest companion and the first adult male to accept Islam, was chosen as the **first caliph** immediately after the Prophet’s passing. He was selected through consensus at Saqifah.")
                        .font(.body)

                    Text(articleMarkdown: "He led decisively during a time of crisis, launching the **Riddah Wars** to bring back apostate tribes and false prophets. About one year after the Prophet’s death (12 AH), he initiated the first complete compilation of the Quran into a single manuscript.")
                        .font(.body)

                    Text(verbatim: "When some of the Companions were harsh with him, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3661", cite: "Sahih al-Bukhari 3661", arabic: 146...163, english: [175...210, 215...222])

                    Text(verbatim: "His caliphate lasted just over two years but laid the foundation for unity and stability in the Ummah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("UMAR IBN AL-KHATTAB (634–644 CE)")) {
                    Text(verbatim: "Umar (may Allah be pleased with him) was appointed by Abu Bakr before his death and accepted by the Muslims as the second caliph. He was renowned for justice, strength, and fear of Allah (Glorified and Exalted be He).")
                        .font(.body)

                    Text(articleMarkdown: "His 10-year reign witnessed the rapid expansion of Islam into the **Byzantine and Persian Empires**, including Jerusalem and Egypt. He established **public registers**, **courts**, **salaries for soldiers**, and the **Islamic calendar**.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:3682", cite: "Sunan al-Tirmidhi 3682; graded sahih by al-Albani", arabic: 30...37, english: 10...24)

                    Text(verbatim: "He was assassinated while praying in the masjid and is buried beside the Prophet Muhammad (peace be upon him).")
                        .font(.body)
                }

                Section(header: ArticleHeader("UTHMAN IBN AFFAN (644–656 CE)")) {
                    Text(articleMarkdown: "Uthman (may Allah be pleased with him) was chosen through a **council of six** appointed by Umar. Known for his generosity and modesty, he married two daughters of the Prophet Muhammad (peace be upon him) and was called **Dhu al-Nurayn** (ذُو ٱلنُّورَين, the Possessor of Two Lights).")
                        .font(.body)

                    Text(articleMarkdown: "He **standardized official copies of the Quran** from the already compiled manuscript preserved from Abu Bakr’s time, unifying public recitation and preventing disputes over unverified personal materials. He sent official copies to major cities and retired non-verified personal codices used outside official transmission.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said of him:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2401", cite: "Sahih Muslim 2401", arabic: 128...134, english: 155...167)

                    Text(verbatim: "Due to political unrest and false accusations, he was unjustly besieged and martyred while reciting the Quran.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ALI IBN ABI TALIB (656–661 CE)")) {
                    Text(verbatim: "Ali (may Allah be pleased with him), the cousin and son-in-law of the Prophet Muhammad (peace be upon him), was chosen as the fourth caliph after Uthman’s martyrdom.")
                        .font(.body)

                    Text(articleMarkdown: "His caliphate was challenged by internal strife, including the **Battle of the Camel** and **Battle of Siffin**. Despite the trials, he remained committed to justice and truth.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said to him:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2404a", cite: "Sahih Muslim 2404", arabic: 58...68, english: 0...29)

                    Text(verbatim: "Ali was struck by Ibn Muljam in Kufah on his way to lead the Fajr prayer, in Ramadan 40 AH, and died of the wound. His legacy lives on in scholarship, courage, and moral leadership.")
                        .font(.body)
                }

                Section(header: ArticleHeader("LEGACY OF THE RASHIDUN")) {
                    Text(articleMarkdown: "The Rashidun Caliphs (632–661 CE) ruled with unmatched integrity, transparency, and adherence to prophetic tradition. Their rule was guided by **shura (شُورَىٰ)**, justice, and humility.")
                        .font(.body)

                    Text(articleMarkdown: "Though later caliphates transitioned into **hereditary monarchy**, the Prophet Muhammad (peace be upon him) had foretold this change in the hadith quoted above: thirty years of the caliphate of prophethood, and then kingship given to whomever Allah wills (Sunan Abi Dawud 4646). Safinah (may Allah be pleased with him), who narrated it, counted them: two years for Abu Bakr, ten for Umar, twelve for Uthman, and the remainder for Ali.")
                        .font(.body)

                    Text(verbatim: "Despite this shift, many later caliphs still contributed greatly to Islamic knowledge, architecture, and global influence.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE UMAYYAD CALIPHATE (661–750 CE)")) {
                    Text(articleMarkdown: "The Umayyads, beginning with Mu'awiyah ibn Abi Sufyan (may Allah be pleased with him), transitioned the caliphate into a **dynastic monarchy**. Their capital was **Damascus (دِمَشق)**.")
                        .font(.body)

                    Text(articleMarkdown: "They expanded Islam into **al-Andalus (Spain)**, **North Africa**, and **Central Asia**, and made **Arabic** the official administrative language.")
                        .font(.body)

                    Text(verbatim: "Though less spiritually exemplary than the Rashidun, the Umayyads left a profound legacy in governance, culture, and infrastructure.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE ABBASID CALIPHATE (750–1258 CE)")) {
                    Text(articleMarkdown: "The Abbasids overthrew the Umayyads and moved the capital to **Baghdad (بَغدَاد)**, initiating the **Golden Age of Islam**.")
                        .font(.body)

                    Text(articleMarkdown: "They supported **translation**, **science**, **mathematics**, **medicine**, and **philosophy**, and established the renowned **Bayt al-Hikmah (بَيت ٱلحِكمَة, House of Wisdom)**.")
                        .font(.body)

                    Text(verbatim: "Although internal divisions weakened the state, their intellectual contributions influenced both the Muslim world and Europe. The empire fell to the Mongols in 1258 CE.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE OTTOMAN CALIPHATE (1517–1924 CE)")) {
                    Text(articleMarkdown: "The Ottomans, a Turkish dynasty, were the **first non-Arab dynasty** to hold the widely recognised caliphate. After the fall of the Abbasids in Egypt, the caliphate passed to the Ottomans, whose capital was **Istanbul (إِسطَنبُول)**.")
                        .font(.body)

                    Text(articleMarkdown: "They ruled a vast empire across **Europe**, **Asia**, and **Africa**, preserved **Islamic law (ٱلشَّرِيعَة)**, and defended the **Two Holy Mosques** in **Makkah (مَكَّة)** and **Madinah (ٱلمَدِينَة)**.")
                        .font(.body)

                    Text(articleMarkdown: "The Ottoman Caliphate was officially **abolished in 1924 CE** by Mustafa Kemal Atatürk, ending nearly 1,300 years of Islamic caliphal leadership.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The Rightly Guided Caliphs are the model of just Islamic governance: preserving the Quran, spreading the faith, and upholding the unity of the Ummah.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "CaliphatesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Caliphates")
        .selectableArticleList(article: "CaliphatesView")
    }
}

struct MadhabView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections1)
                Section(header: ArticleHeader("THE FOUR SUNNI MADHAHIB")) {
                    imamEntry(
                        number: 1,
                        name: "Imam Abu Hanifa (may Allah have mercy on him)",
                        arabic: "أَبُو حَنِيفَة",
                        meta: "Hanafi (الحَنَفِي) · Kufa, Iraq (الكُوفَة، العِرَاق) · 80–150 AH / 699–767 CE",
                        description: "The Imam of Kufa and founder of the Hanafi school. Known for his mastery of fiqh, ijtihad, and qiyas (قِيَاس, from ق-ي-س, to measure one thing against another: analogical reasoning) and for his rigorous legal methodology. It is the most followed madhhab today, especially in South Asia, Turkey, Central Asia, and the Balkans."
                    )

                    imamEntry(
                        number: 2,
                        name: "Imam Malik ibn Anas (may Allah have mercy on him)",
                        arabic: "مَالِكُ بنُ أَنَسٍ",
                        meta: "Maliki (المَالِكِي) · Madinah (المَدِينَة) · 93–179 AH / 711–795 CE",
                        description: "The Imam of Madinah and compiler of Al-Muwatta (المُوَطَّأ), renowned for preserving the Sunnah and the practice of the people of Madinah (عَمَل أَهل المَدِينَة). His school is dominant across North and West Africa."
                    )

                    imamEntry(
                        number: 3,
                        name: "Imam Muhammad ibn Idris al-Shafi‘i (may Allah have mercy on him)",
                        arabic: "الشَّافِعِي",
                        meta: "Shafi‘i (الشَّافِعِي) · Egypt (مِصر) · 150–204 AH / 767–820 CE",
                        description: "The Imam who systematized the principles of Islamic jurisprudence, usul al-fiqh (أُصُول الفِقه). Born in Gaza, he studied in Makkah and Madinah and later in Iraq, and shaped his final madhhab in Egypt, where it took its lasting form. Popular in East Africa, Indonesia, Malaysia, and parts of Egypt and Yemen."
                    )

                    imamEntry(
                        number: 4,
                        name: "Imam Ahmad ibn Hanbal (may Allah have mercy on him)",
                        arabic: "أَحمَدُ بنُ حَنبَلٍ",
                        meta: "Hanbali (الحَنبَلِي) · Baghdad (بَغدَاد) · 164–241 AH / 780–855 CE",
                        description: "The Imam of Ahl al-Hadith (أَهل الحَدِيث), renowned for his steadfastness during the Mihna (المِحنَة, the Inquisition) and his firm adherence to the Quran and Sunnah, using analogy only when necessary. Mainly followed in Saudi Arabia and the Gulf."
                    )
                }

                ArticleSectionsView(sections: Self.sections2)

                ArticleSourcesSection(article: "MadhabView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Madhahib of Fiqh")
        .selectableArticleList(article: "MadhabView")
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

    static let sections1: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the four madhahib (Hanafi, Maliki, Shafi'i, and Hanbali) are the accepted schools of fiqh, the practical rulings of Islam, where more than one opinion can be valid. They differ in fiqh and are one in aqeedah."),
        ]),
        ArticleSection("OVERVIEW", [
            .markdown("A **madhhab (مَذهَب)** is a school of Islamic jurisprudence that provides structured guidance on how to derive and apply rulings from the Quran and Sunnah. The plural is **madhahib (مَذَاهِب)**."),
            .text("Madhahib developed as scholars preserved and codified fiqh (فِقه), or Islamic legal reasoning/jurisprudence, to help Muslims navigate daily life, worship, transactions, and society with clarity and consistency."),
            .text("Following a madhhab ensures one is following a valid, peer-reviewed methodology developed by righteous scholars deeply rooted in the Quran, Sunnah, consensus (إِجمَاع), and analogy (قِيَاس). It is not blind following; it is trust in generations of qualified scholarship. Allah (Glorified and Exalted be He) commands the one who does not know to ask those who do:"),
            .ayah("16:43", words: 8...14),
            .text("And the Prophet Muhammad (peace be upon him) said:"),
            .hadith("bukhari:71", cite: "Sahih al-Bukhari 71, Sahih Muslim 1037", arabic: 32...39, english: [6...20]),
        ]),
        ArticleSection("FIQH IS NOT AQEEDAH", [
            .markdown("**Fiqh (فِقه)** means “understanding“: the practical rulings of Islam, how to pray, fast, trade, marry, and inherit, derived from the Quran and Sunnah by qualified effort (**ijtihad**). **Aqeedah (عَقِيدَة)**, from “to tie a knot,“ is what the heart is bound to: belief about Allah, His angels, books, messengers, the Last Day, and the decree. The madhahib are schools of **fiqh**. There are no “four schools“ of aqeedah, because aqeedah is one (see “The Madhahib of Aqeedah“)."),
            .text("In fiqh more than one answer can be valid, and the Companions (may Allah be pleased with them) themselves differed in it in the Prophet’s own presence. After the Battle of the Trench he said:"),
            .hadith("bukhari:946", cite: "Sahih al-Bukhari 946", arabic: 16...66, english: [16...93]),
            .text("One group held to the literal words and prayed late; the other understood the intent and prayed on time. Both reasoned sincerely from his command, and he approved both. This is the root of every difference between the madhahib: the same texts, read by sincere scholars, sometimes yield more than one acceptable ruling."),
            .text("Aqeedah admits no such range. Abu Bakr, Umar, Uthman, Ali, the Ahlul Bayt, and every Companion believed exactly the same things about Allah, and so did every prophet before them; the Prophet (peace be upon him) said the prophets’ “religion is one“ (Sahih al-Bukhari 3443). So a Muslim may be Hanafi or Maliki in fiqh, but in creed there is only the creed of the Salaf."),
        ]),
        ArticleSection("WHY FOLLOW A MADHHAB?", [
            .text("Islamic rulings are not always black and white. Scholars developed principles to interpret revelation when texts appeared to conflict or were not explicit."),
            .text("For example, rulings on prayer times, purification, zakah calculation, marriage, and contracts all require detailed interpretation. Madhahib systematize this process based on authentic sources and established rules."),
            .markdown("Instead of picking rulings randomly or following desire, a madhhab offers **structured, principled, and scholarly guidance**. It helps prevent inconsistency and distortion in religious practice."),
        ]),
    ]

    static let sections2: [ArticleSection] = [
        ArticleSection("WHEN THE MADHAHIB TOOK SHAPE", [
            .text("None of the four imams formally founded an institution. Each taught a methodology that his students preserved and systematized into a school over the generations, so historians distinguish between the life of the imam and the emergence of the madhhab."),
            .text("The Hanafi school began in Kufa during Abu Hanifa’s lifetime and was firmly established by his students Abu Yusuf (d. 182 AH) and Muhammad al-Shaybani (d. 189 AH). The Maliki school developed in Madinah through Imam Malik’s teaching circle and Al-Muwatta. The Shafi‘i school crystallized in Egypt in Imam al-Shafi‘i’s final years (his “new” madhhab) and spread after him through students like al-Muzani and al-Buwayti. The Hanbali school was collected and systematized after Imam Ahmad’s death by his sons and students such as al-Khallal."),
            .text("The four imams form an unbroken chain of teacher and student: Imam Malik taught al-Shafi‘i, who in turn taught Ahmad ibn Hanbal. Imam Malik was also a contemporary of Abu Hanifa, and al-Shafi‘i was born in the very year Abu Hanifa passed away (150 AH)."),
        ]),
        ArticleSection("UNITY THROUGH DIVERSITY", [
            .text("All four madhahib are valid and respected paths within Ahl al-Sunnah wa al-Jama‘ah (أَهل السُّنَّة وَالجَمَاعَة). Though they may differ in legal rulings, they are united in the same ‘aqeedah (عَقِيدَة), the core beliefs regarding Allah, His names and attributes, prophethood, the Quran, the unseen, and the Afterlife."),
            .text("This shared creed is why they are all considered part of Ahl al-Sunnah wa al-Jama‘ah. The differences among them are in jurisprudence (fiqh), not faith (‘aqeedah), and reflect the depth and mercy of Islamic legal tradition."),
            .text("No single school is “more Islamic“; each preserved knowledge and served the Ummah according to its time and place. Following any of them keeps one on the path of the Prophet (peace be upon him) and his companions."),
            .text("The imams themselves put their schools beneath the Quran and Sunnah. Mujahid (may Allah have mercy on him), the student of Ibn Abbas, said (a saying later made famous in the words of Imam Malik at the grave of the Prophet, peace be upon him):"),
            .quote(text: "“There is no one after the Prophet (peace be upon him) except that his words may be taken or left” (Ibn Abd al-Barr, Jami' Bayan al-Ilm 2/926, with a sahih chain).", arabic: "لَيسَ أَحَدٌ بَعدَ النَّبِيِّ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ إِلَّا يُؤخَذُ مِن قَولِهِ وَيُترَكُ", dimmed: true),
            .text("Imam al-Shafi‘i (may Allah have mercy on him) said, and the same is reported from Imam Abu Hanifah:"),
            .quote(text: "“If the hadith is authentic, then that is my madhhab” (al-Nawawi, al-Majmu' 1/63; Ibn Abidin, Hashiyah 1/63).", arabic: "إِذَا صَحَّ الحَدِيثُ فَهُوَ مَذهَبِي", dimmed: true),
            .text("And Imam Ahmad ibn Hanbal (may Allah have mercy on him) said:"),
            .quote(text: "“Do not blindly follow me, nor Malik, nor al-Shafi‘i, nor al-Awza‘i, nor al-Thawri; take from where they took” (Ibn al-Qayyim, I'lam al-Muwaqqi'in 2/302).", arabic: "لَا تُقَلِّدنِي وَلَا تُقَلِّد مَالِكًا وَلَا الشَّافِعِيَّ وَلَا الأَوزَاعِيَّ وَلَا الثَّورِيَّ، وَخُذ مِن حَيثُ أَخَذُوا", dimmed: true),
            .text("So the madhahib are followed as a means to the Quran and Sunnah, never as a rival to them: where an authentic text is clear, it is the text that is followed, and this is what the four imams commanded."),
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
            .hadith("bukhari:2652", cite: "Sahih al-Bukhari 2652", arabic: 29...37, english: [4...23]),
            .text("The Companions and their students asked whichever scholar was at hand: the people of Madinah asked Zayd ibn Thabit and Ibn Umar, the people of Makkah asked Ibn Abbas, the people of Kufa asked Ibn Mas‘ud and then Ali (may Allah be pleased with them), and none of them said, “I am on the madhhab of so-and-so.” The four imams belong to the generations after the Companions (the earliest of them, Abu Hanifah, saw the Companion Anas ibn Malik as a boy but took his fiqh from the Tabi‘in), so the first generations obviously had no Hanafi or Maliki school. Ibn Taymiyyah (may Allah have mercy on him) writes in Majmu‘ al-Fatawa that following the madhhab of a specific person, because one cannot learn the Shari‘ah (شَرِيعَة, from ش-ر-ع, the path leading down to water, and so the revealed law) except through him, is permitted for such a person but is not obligatory on everyone, and that no one is bound to follow one particular man in everything he says except the Messenger of Allah (peace be upon him). In practice: the scholar follows the evidence, the student learns through a school and checks it against the evidence as he grows, and the layman follows the trustworthy scholars available to him, whether they teach within a madhhab or not."),
            .markdown("**Can I take a ruling from another madhhab, or change my madhhab?**"),
            .text("Yes, when it is done for the evidence or on the word of a scholar one trusts more, and not to hunt for the easiest answer. The imams’ own students did it: Abu Yusuf and Muhammad ash-Shaybani differed from Abu Hanifah in many questions, al-Muzani differed from ash-Shafi‘i, and ash-Shafi‘i revised his own madhhab when he moved to Egypt. Every school’s later scholars weighed (tarjih) between the reports from their imam and sometimes preferred another school’s view. Ibn Taymiyyah (may Allah have mercy on him) says in Majmu‘ al-Fatawa that whoever moves from one madhhab to another for a religious reason, because he finds the other closer to the Quran and Sunnah, has done well, and whoever does so for a worldly aim is blamed. What is condemned is tatabbu‘ ar-rukhas (تَتَبُّع الرُّخَص), collecting the most convenient opinion from each school out of desire. Sulayman at-Taymi (may Allah have mercy on him), one of the Tabi‘in, said that if you take the concession of every scholar, all evil gathers in you, and Ibn Abd al-Barr, who reports it in Jami‘ Bayan al-‘Ilm, adds that he knows of no disagreement on this. The touchstone is Quran 4:59 (quoted below): the dispute is referred to Allah and the Messenger, not to one’s ease."),
            .markdown("**What if my madhhab contradicts an authentic hadith?**"),
            .text("Then the hadith is followed, because that is exactly what the four imams commanded. Malik, ash-Shafi‘i, and Ahmad are quoted above in “Unity Through Diversity”; Abu Hanifah (may Allah have mercy on him) said:"),
            .quote(text: "“It is not permitted for anyone to take our opinion without knowing where we took it from” (Ibn Abd al-Barr, al-Intiqa’; Ibn al-Qayyim, I‘lam al-Muwaqqi‘in).", arabic: "لَا يَحِلُّ لِأَحَدٍ أَن يَأخُذَ بِقَولِنَا مَا لَم يَعلَم مِن أَينَ أَخَذنَاهُ", dimmed: true),
            .text("Al-Albani (may Allah have mercy on him) gathered these statements of the imams in the introduction to Sifat Salat an-Nabi, and drew the conclusion the imams themselves drew: leaving an imam’s opinion for the authentic hadith is obedience to the imam, not disloyalty to him. Allah says:"),
            .ayah("24:63", words: 15...26),
            .text("Two cautions keep this honest. First, a hadith may be authentic yet abrogated, restricted by another text, or understood by the Companions differently from its first appearance, so the one who acts on it must be able to verify the chain, the abrogation, and the meaning; a layman who meets such a hadith asks a scholar rather than ruling alone. Second, no scholar may set aside an authentic, unabrogated hadith merely because his imam did not act on it, for the imam had an excuse (the next question) and he does not."),
            .markdown("**Why do the scholars differ, if the Quran and Sunnah are one?**"),
            .text("Ibn Taymiyyah (may Allah have mercy on him) answers this in Raf‘ al-Malam ‘an al-A’immah al-A‘lam, beginning with a principle:"),
            .quote(text: "“It is not for any of the imams who are accepted by the ummah with general acceptance to deliberately oppose the Messenger of Allah (peace be upon him) in anything of his Sunnah, small or great, for they are agreed with certainty upon the obligation of following the Messenger” (Ibn Taymiyyah, Raf‘ al-Malam ‘an al-A’immah al-A‘lam).", arabic: "لَيسَ لِأَحَدٍ مِنَ الأَئِمَّةِ المَقبُولِينَ عِندَ الأُمَّةِ قَبُولًا عَامًّا أَن يَتَعَمَّدَ مُخَالَفَةَ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ فِي شَيءٍ مِن سُنَّتِهِ دَقِيقٍ وَلَا جَلِيلٍ، فَإِنَّهُم مُتَّفِقُونَ اتِّفَاقًا يَقِينِيًّا عَلَى وُجُوبِ اتِّبَاعِ الرَّسُولِ", dimmed: true),
            .text("He then gathers the excuses under three heads: the imam did not believe the Prophet said it (the hadith did not reach him, or reached him through a chain he did not trust), he did not believe the text meant that case (a word with more than one meaning, a general text he thought restricted, a report he understood differently), or he believed the ruling abrogated or outweighed by stronger evidence. Every one of these befell the Companions themselves. When Abu Musa told Umar (may Allah be pleased with them) that the Prophet had commanded whoever asks permission three times without an answer to go back, Umar had never heard it and asked for a witness, then said:"),
            .hadith("bukhari:2062", cite: "Sahih al-Bukhari 2062", arabic: 88...100, english: [128...149]),
            .text("Umar likewise did not know the ruling on the Magians until the report reached him:"),
            .hadith("bukhari:3156", cite: "Sahih al-Bukhari 3156", arabic: 59...82, english: [100...127]),
            .text("Abrogation caused differences too: Ubayy ibn Ka‘b (may Allah be pleased with him) explained that the early fatwa (فَتوَى, from ف-ت-ي, a considered answer given to a questioner) that a bath is required only when there is emission was a concession from the beginning of Islam which the Prophet later replaced with the command to bathe (Sunan Abi Dawud 215; graded sahih by al-Albani), so whoever knew only the first ruling gave fatwa by it. And understanding differed: Ibn Umar reported that the dead are punished by their family’s weeping, while Aisha (may Allah be pleased with them) held that the report had been misunderstood, for what the Prophet said was that the deceased is punished for his own sin while his family weeps over him (Sahih al-Bukhari 3978). If Umar could miss a hadith and Ibn Umar could misunderstand one, an imam in Kufa or Madinah two generations later could do so more easily. Allah Himself records two prophets judging one case differently, and praises both:"),
            .ayah("21:78-79", words: 0...19),
            .text("Add that Arabic words can carry more than one meaning, that texts can appear to conflict, and that the Companions differed in fiqh in the Prophet’s presence and he approved both sides (the Banu Qurayzah report quoted above), and the differences of the madhahib become what they are: sincere ijtihad over probable evidences, rewarded whether it hits or misses."),
            .markdown("**Is “the differing of my ummah is a mercy” a hadith?**"),
            .text("No. It has no chain of narration. Al-Albani (may Allah have mercy on him) rules that it has no basis (Silsilat al-Ahadith ad-Da‘ifah 57), citing the Shafi‘i imam as-Subki, who could find for it no chain at all, sound, weak, or fabricated. Long before them Ibn Hazm (may Allah have mercy on him) rejected its very meaning:"),
            .quote(text: "“If differing were a mercy, then agreement would be a punishment” (Ibn Hazm, al-Ihkam fi Usul al-Ahkam).", arabic: "لَو كَانَ الِاختِلَافُ رَحمَةً لَكَانَ الِاتِّفَاقُ سَخَطًا", dimmed: true),
            .text("The Quran describes those who are shown mercy as the ones who do not differ:"),
            .ayah("11:118-119"),
            .text("Ibn Kathir (may Allah have mercy on him) explains in his Tafsir that those given mercy are the followers of the messengers, who hold to what Allah revealed and are not divided over it. The Prophet (peace be upon him) warned:"),
            .hadith("bukhari:7288", cite: "Sahih al-Bukhari 7288", arabic: 24...32, english: [11...28]),
            .text("Ibn Mas‘ud (may Allah be pleased with him) showed how the Companions handled a difference in fiqh: he disapproved of Uthman completing the prayer at Mina, yet prayed the full four behind him rather than split the congregation:"),
            .hadith("abudawud:1960", cite: "Sunan Abi Dawud 1960; graded sahih by al-Albani", arabic: 86...102, english: [95...115]),
            .text("What is true is narrower: sincere ijtihad that misses the mark is excused and even rewarded (Sahih al-Bukhari 7352, quoted below), and the range of the Companions’ ijtihad left the ummah room; it is reported from Umar ibn Abd al-Aziz that he would not have loved the Companions to have agreed on everything, since their differing left a concession (Ibn Abd al-Barr, Jami‘ Bayan al-‘Ilm). The mercy is in the excuse and the ease, not in the differing itself, and what Allah commands is unity (the next question)."),
            .markdown("**Is following a madhhab a bid‘ah?**"),
            .text("No. Bid‘ah is introducing into the religion an act of worship that has no basis in it. The Prophet (peace be upon him) said:"),
            .hadith("bukhari:2697", cite: "Sahih al-Bukhari 2697, Sahih Muslim 1718", arabic: 29...38, english: [4...22]),
            .text("A madhhab introduces no worship; it is a method of understanding the texts, taught by imams whom the whole of Ahl as-Sunnah honours, and adh-Dhahabi (may Allah have mercy on him) praises each of the four at length in Siyar A‘lam an-Nubala’. What is blameworthy is ta‘assub (تَعَصُّب), fanatical partisanship: treating the imam as infallible, rejecting an authentic hadith for his sake, or making agreement with him the basis of love and enmity among the Muslims. When partisanship goes so far that a scholar’s word overrides the text of Allah and His Messenger, it approaches what the Quran condemned in the People of the Book:"),
            .ayah("9:31", words: 0...6),
            .text("Ibn Kathir (may Allah have mercy on him) explains in his Tafsir that they did not pray to them; they obeyed them in making lawful what Allah had forbidden and forbidding what He had allowed. Ibn Taymiyyah (may Allah have mercy on him) writes in Majmu‘ al-Fatawa that whoever sets up any person other than the Messenger and gives loyalty and enmity on the basis of agreeing with him is among those who divided their religion into sects. The Prophet (peace be upon him) told us what to hold to when differences multiply:"),
            .hadith("tirmidhi:2676", cite: "Sunan al-Tirmidhi 2676; graded sahih by al-Albani", arabic: 69...93, english: [68...114]),
            .text("And Allah says:"),
            .ayah("3:103", words: 0...5),
            .ayah("6:159"),
            .markdown("**Did the Salafi scholars follow madhhabs?**"),
            .text("Yes. Ibn Taymiyyah, Ibn al-Qayyim, Ibn Qudamah, and Ibn Rajab were Hanbalis; Ibn Kathir and adh-Dhahabi were Shafi‘is (as were an-Nawawi and Ibn Hajar, who were imams of the Sunnah in fiqh and hadith though they took Ash‘ari positions on some attributes); Ibn Abd al-Barr was a Maliki; at-Tahawi was a Hanafi. Ibn Baz and Ibn al-Uthaymin (may Allah have mercy on them) were trained in Hanbali fiqh and taught from its texts (Ibn al-Uthaymin’s ash-Sharh al-Mumti‘ is a commentary on the Hanbali manual Zad al-Mustaqni‘), and al-Albani (may Allah have mercy on him), raised in a Hanafi household, devoted himself to hadith and weighed the evidence without binding himself to a school. What unites them is the rule, not the label: the madhhab is a ladder to the evidence, never a veil over it. Ibn Taymiyyah left the Hanbali position where he found the evidence against it, Ibn al-Uthaymin’s commentaries repeatedly prefer another school’s view over his own, and al-Albani cited the imams’ own words as his warrant. At the same time, Ibn Rajab (may Allah have mercy on him) wrote a treatise defending adherence to the four schools by those who lack the tools of ijtihad, because unqualified people claiming to derive rulings for themselves harm the religion. Both are the way of the Salaf: the qualified follow the evidence, the untrained follow the qualified, and all honour the imams. Allah praised:"),
            .ayah("9:100", words: 0...12),
            .markdown("**Is the Hanbali madhhab “the Salafi madhhab”?**"),
            .text("No. Salafiyyah is a creed and a methodology (following the Quran and Sunnah as the Companions understood them), not a school of fiqh. All four imams were Salafi in creed, and a Salafi may be Hanafi, Maliki, Shafi‘i, or Hanbali in fiqh, or may follow the evidence across the schools if he is qualified. The Hanbali school is associated with Ahl al-Hadith because Imam Ahmad was their imam and because Ibn Taymiyyah and his students came from it, but the creed of the Salaf is the creed of Abu Hanifah, Malik, and ash-Shafi‘i just as much as it is the creed of Ahmad (see “Salafiyyah” and “The Madhahib of Aqeedah”)."),
            .markdown("**Can a layman weigh the evidence himself?**"),
            .text("Not in the sense of deriving rulings, because that requires tools he does not have: Arabic, the grading of chains, knowledge of abrogation, of the general and the specific, and of what the Companions did. The Quran assigns derivation (istinbat) to a particular group:"),
            .ayah("4:83", words: 9...20),
            .ayah("21:7"),
            .ayah("39:9", words: 12...23),
            .text("The Prophet (peace be upon him) warned of what happens when the untrained give rulings:"),
            .hadith("bukhari:100", cite: "Sahih al-Bukhari 100", arabic: 32...60, english: [6...71]),
            .text("Ibn al-Qayyim (may Allah have mercy on him) explains in I‘lam al-Muwaqqi‘in that the layman’s asking a mufti is the very thing Allah commanded, not the blameworthy taqlid (تَقلِيد, from ق-ل-د, to put a collar on an animal: following a man without knowing his evidence). What the layman can and must weigh is the mufti: he chooses the most knowledgeable and most God-fearing scholar he can reach, as he would choose a doctor, and when two trustworthy scholars differ he follows the one whose knowledge and piety he trusts more, or the one who shows him the evidence, without following his own desire. Learning the evidence for what one practises is praiseworthy, and a layman who sees a clear authentic hadith should ask about it rather than ignore it; but being unable to derive rulings is not a deficiency in him, it is the division of labour Allah set out in Quran 9:122 (quoted below), and Allah reminds every scholar that:"),
            .ayah("12:76", words: 28...32),
            .markdown("**Did the four imams differ in creed?**"),
            .text("No. Their differences were in fiqh; in aqeedah they held one creed, the creed of the Salaf. Abu Hanifah and his two companions affirmed the attributes of Allah as revealed, and at-Tahawi (d. 321 AH) wrote his famous creed as their creed. Malik (may Allah have mercy on him), asked how Allah rose over the Throne, answered:"),
            .quote(text: "“The rising is not unknown, the how is not comprehended, belief in it is obligatory, and asking about it is an innovation” (al-Lalaka’i, Sharh Usul I‘tiqad Ahl as-Sunnah; al-Bayhaqi, al-Asma’ was-Sifat).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true),
            .text("Ash-Shafi‘i (may Allah have mercy on him) said:"),
            .quote(text: "“I believe in Allah and in what has come from Allah as Allah intended it, and I believe in the Messenger of Allah and in what has come from the Messenger of Allah as the Messenger of Allah intended it” (Ibn Qudamah, Lum‘at al-I‘tiqad).", arabic: "آمَنتُ بِاللَّهِ وَبِمَا جَاءَ عَنِ اللَّهِ عَلَى مُرَادِ اللَّهِ، وَآمَنتُ بِرَسُولِ اللَّهِ وَبِمَا جَاءَ عَن رَسُولِ اللَّهِ عَلَى مُرَادِ رَسُولِ اللَّهِ", dimmed: true),
            .text("And Ahmad (may Allah have mercy on him) opened his Usul as-Sunnah with the words:"),
            .quote(text: "“The foundations of the Sunnah with us are: holding fast to what the Companions of the Messenger of Allah (peace be upon him) were upon, taking them as the example, and abandoning innovations, for every innovation is misguidance” (Ahmad ibn Hanbal, Usul as-Sunnah, narrated by ‘Abdus ibn Malik al-‘Attar).", arabic: "أُصُولُ السُّنَّةِ عِندَنَا: التَّمَسُّكُ بِمَا كَانَ عَلَيهِ أَصحَابُ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، وَالِاقتِدَاءُ بِهِم، وَتَركُ البِدَعِ، وَكُلُّ بِدعَةٍ فَهِيَ ضَلَالَةٌ", dimmed: true),
            .text("All four affirmed that the Quran is the speech of Allah, uncreated, that the believers will see their Lord in the Hereafter, that faith is speech and deed, and that the Companions are to be loved and honoured. See “The Madhahib of Aqeedah” for the fuller picture. Allah commanded:"),
            .ayah("42:13", words: 1...23),
            .markdown("**Which madhhab is the best?**"),
            .text("On any given question, the best opinion is the one with the strongest evidence, whichever school holds it. No imam is followed absolutely; only the Prophet (peace be upon him) is:"),
            .ayah("4:65"),
            .ayah("33:36", words: 0...15),
            .text("The hadith of the two rewards (Sahih al-Bukhari 7352, quoted above) proves that even the best mujtahid can err, so no school can be right in everything. Imam Malik (may Allah have mercy on him) said of himself:"),
            .quote(text: "“I am only a man; I err and I am right. So look into my opinion: whatever agrees with the Book and the Sunnah, take it, and whatever does not agree with the Book and the Sunnah, leave it” (Ibn Abd al-Barr, Jami‘ Bayan al-‘Ilm).", arabic: "إِنَّمَا أَنَا بَشَرٌ أُخطِئُ وَأُصِيبُ، فَانظُرُوا فِي رَأيِي، فَكُلُّ مَا وَافَقَ الكِتَابَ وَالسُّنَّةَ فَخُذُوهُ، وَكُلُّ مَا لَم يُوَافِقِ الكِتَابَ وَالسُّنَّةَ فَاترُكُوهُ", dimmed: true),
            .text("The practical answer is to learn from the trustworthy scholars near you, in whichever of the four schools they teach, to learn the evidence for what you practise, and to put the authentic hadith first, as that school’s own imam commanded."),
            .markdown("**What is the ruling on ijma‘ (إِجمَاع, from ج-م-ع, to gather: the agreement of the scholars), and can the ummah agree on an error?**"),
            .text("Ijma‘ is a binding proof, and the ummah as a whole is protected from agreeing on misguidance. Allah says:"),
            .ayah("4:115"),
            .text("Ibn Kathir (may Allah have mercy on him) records in his Tafsir that Imam ash-Shafi‘i took this ayah as the proof that ijma‘ is binding and that opposing it is forbidden. Allah also says:"),
            .ayah("2:143", words: 0...11),
            .text("A community whose testimony Allah accepts over the nations cannot unite on falsehood. The Prophet (peace be upon him) also promised that truth will never be without its bearers:"),
            .hadith("muslim:1920", cite: "Sahih Muslim 1920; Sahih al-Bukhari 3641 similar", arabic: 37...54, english: [0...50]),
            .text("So the whole ummah can never unite on an error, because a group upon the truth always remains. The wording “my ummah will not unite upon misguidance” is reported through several chains that the hadith scholars grade individually; its meaning rests securely on the ayat and reports above. Two limits keep ijma‘ sound: it must be real, which is why Imam Ahmad warned against loose claims of it (quoted above), and the ijma‘ known with certainty is that of the Companions and the Salaf; and, as Ibn Taymiyyah notes in Majmu‘ al-Fatawa, every genuine ijma‘ rests on a text, so consensus never opposes the Quran and Sunnah but confirms them."),
            .markdown("**Is the door of ijtihad closed?**"),
            .text("No. Some later scholars claimed that no mujtahid could arise after the early centuries, but Ibn Taymiyyah, Ibn al-Qayyim, as-Suyuti, and ash-Shawkani (may Allah have mercy on them) rejected the claim; as-Suyuti wrote a treatise arguing that ijtihad is an obligation of the ummah in every age. Ibn Taymiyyah adds that ijtihad is divisible: a scholar may be qualified to weigh the evidence in one field while following others elsewhere. What is closed is ijtihad without its tools, which the Prophet (peace be upon him) described as ignorant heads giving verdicts without knowledge (Sahih al-Bukhari 100, quoted above). The reward of the qualified mujtahid (Sahih al-Bukhari 7352, quoted above) and the command that a group in every community obtain understanding in the religion (Quran 9:122, quoted above) both assume that the effort continues until the Hour."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Following a qualified school connects a Muslim to generations of disciplined scholarship; their differences are sincere ijtihad that Allah rewards, all four imams held one creed, and all four schools are within Ahl as-Sunnah."),
        ]),
        ArticleSection("KEY TERMS", [
            .markdown("**Fiqh (فِقه)**: “deep understanding,” from the root ف-ق-ه, to grasp the meaning of a thing beneath its surface; the Quran uses the verb when Musa asks that the people “may understand my speech” (Quran 20:28). In the Shari‘ah, fiqh is the knowledge of the practical rulings of Islam (how to purify oneself, pray, fast, trade, marry, and inherit) drawn from their detailed evidences. The Prophet (peace be upon him) tied this understanding to Allah wanting good for a person (Sahih al-Bukhari 71, quoted above), and the Quran made it the purpose of setting out to seek knowledge:"),
            .ayah("9:122", words: 6...20),
            .markdown("**Faqih (فَقِيه)**, plural **fuqaha (فُقَهَاء)**: one who possesses fiqh, a jurist. The word is about understanding, not memory alone. The Prophet (peace be upon him) prayed for Ibn Abbas (may Allah be pleased with them) with the verb of this very word, allahumma faqqihhu fid-din:"),
            .hadith("bukhari:143", cite: "Sahih al-Bukhari 143", arabic: 42...45, english: [27...38]),
            .text("And he distinguished the one who carries knowledge from the one who understands it:"),
            .hadith("tirmidhi:2656", cite: "Sunan al-Tirmidhi 2656; graded sahih by al-Albani", arabic: 75...97, english: [68...113]),
            .text("The Salaf added that fiqh without fear of Allah is not fiqh. When someone objected to al-Hasan al-Basri (may Allah have mercy on him), “The fuqaha do not say that,” he replied:"),
            .hadith("darimi:297", cite: "Sunan al-Darimi 297", arabic: 37...57, text: "“Woe to you! Have you ever seen a faqih? The faqih is only the one who renounces this world, desires the Hereafter, has insight into the affair of his religion, and is constant in the worship of his Lord”"),
            .markdown("**Madhhab (مَذهَب)**, plural **madhahib (مَذَاهِب)**: from ذَهَبَ (dhahaba), “he went”; literally the way one goes, or the place one goes to. In fiqh it is the method an imam used to derive rulings, together with the body of rulings that his students preserved, refined, and passed on. A madhhab is a way to the Quran and Sunnah, not a source alongside them, and the imams themselves said so (see “Unity Through Diversity” below)."),
            .markdown("**Shari‘ah (شَرِيعَة)**: from ش-ر-ع, the open path that leads down to water; the whole law that Allah revealed, which is why He says of the nations, “To each of you We prescribed a law and a method” (Quran 5:48). The Shari‘ah is one and infallible, because it is from Allah; fiqh is the scholars’ understanding of it, and a scholar can be right or mistaken. Keeping the two apart explains how the schools can differ while the religion stays one:"),
            .ayah("45:18"),
            .markdown("**Usul al-fiqh (أُصُول الفِقه)**: “the roots of fiqh,” usul being the plural of asl (أَصل), a root or foundation. It is the science of the sources of the law and of the rules for deriving rulings from them: the Quran, the Sunnah, consensus, and analogy, together with the study of commands and prohibitions, the general and the specific, and the abrogating and the abrogated. Imam ash-Shafi‘i’s ar-Risalah (الرِّسَالَة) is the earliest book on it that has reached us. Scholars of usul point to one ayah that gathers the sources in order: obedience to Allah (the Quran), obedience to the Messenger (the Sunnah), the people of authority (whose agreement is consensus), and the referring of new disputes back to the two revelations (analogy):"),
            .ayah("4:59", words: 0...9),
            .text("and then sends every dispute back to the two revelations:"),
            .ayah("4:59", words: 10...23),
            .text("The Sunnah is revelation alongside the Book, a source in its own right and not a mere commentary, and the Prophet (peace be upon him) foretold those who would try to set it aside:"),
            .hadith("abudawud:4604", cite: "Sunan Abi Dawud 4604; graded sahih by al-Albani", arabic: 37...64, english: [4...55]),
            .markdown("**Dalil (دَلِيل)**, plural **adillah (أَدِلَّة)**: from د-ل-ل, to guide or point the way; a proof, that which leads to a ruling. The Quran uses the word of the sun, which marks out the movement of the shadow:"),
            .ayah("25:45", words: 11...15),
            .text("A dalil may be textual (naqli: an ayah or a hadith) or rational (‘aqli), and definitive (qat‘i) or probable (zanni). Most differences in fiqh arise over probable evidences, which is why they are tolerated; no difference is tolerated over what is definitive."),
            .markdown("**Ijtihad (اِجتِهَاد)** and **mujtahid (مُجتَهِد)**: from ج-ه-د, to exert oneself to the utmost. Ijtihad is the qualified scholar’s utmost effort to reach the ruling of Allah on a question the texts do not settle explicitly, and the mujtahid is the one qualified to make it: he must know the Quran, the Sunnah and its chains, the Arabic language, the points of consensus, the abrogating and the abrogated, and the rules of usul. Allah rewards the sincere, qualified effort even when it misses the mark:"),
            .hadith("bukhari:7352", cite: "Sahih al-Bukhari 7352, Sahih Muslim 1716", arabic: 46...60, english: [7...71]),
            .text("Ijtihad reaches for the ruling of Allah but is not the same as it, which is why the Prophet (peace be upon him) instructed his commanders:"),
            .hadith("muslim:1731a", cite: "Sahih Muslim 1731", arabic: 248...275, english: [304...361]),
            .markdown("**Taqlid (تَقلِيد)** and **ittiba‘ (اِتِّبَاع)**: taqlid is from qiladah (قِلَادَة), a collar or necklace; to make taqlid of someone is to hang your affair around his neck, accepting his statement without knowing its evidence. Ittiba‘ is from ت-ب-ع, to follow; it is following a statement because its evidence has become clear to you. The Quran condemns the taqlid that turns away from revelation:"),
            .ayah("2:170"),
            .text("and it makes ittiba‘ of the Messenger (peace be upon him) the proof of love for Allah:"),
            .ayah("3:31", words: 0...10),
            .text("Ibn Abd al-Barr (may Allah have mercy on him) records the scholars’ distinction in Jami‘ Bayan al-‘Ilm: taqlid is returning to a statement whose speaker has no proof for it, while ittiba‘ is what a proof has established. Ibn al-Qayyim (may Allah have mercy on him) builds on it in I‘lam al-Muwaqqi‘in, separating the blameworthy taqlid (turning away from what Allah revealed in favour of one’s forefathers, following someone one does not know to be qualified, and clinging to an opinion after the evidence against it has appeared) from the permitted asking of the people of knowledge by the one who cannot derive rulings himself, which is what Allah commanded in Quran 16:43 (quoted above). The scholar practises ittiba‘; the layman practises a permitted taqlid that should move toward ittiba‘ as he learns."),
            .markdown("**Ijma‘ (إِجمَاع)**: from ج-م-ع, to gather or agree; the agreement of the qualified scholars of the ummah, after the Prophet (peace be upon him), on a ruling. It is the third source of the law, and its proof is that Allah threatened whoever follows other than the way of the believers (Quran 4:115, quoted above). Imam Ahmad (may Allah have mercy on him) warned against loose claims of it:"),
            .quote(text: "“Whoever claims consensus is lying” (Ibn al-Qayyim, I‘lam al-Muwaqqi‘in).", arabic: "مَنِ ادَّعَى الإِجمَاعَ فَهُوَ كَاذِبٌ", dimmed: true),
            .text("He meant that a scholar may simply not know of a dissenting opinion, so a claim of ijma‘ must be verified; the ijma‘ known with certainty is that of the Companions and the first generations."),
            .markdown("**Qiyas (قِيَاس)**: from ق-ي-س, to measure one thing against another; extending the ruling of a case settled by a text to a new case that shares its effective cause (**‘illah, عِلَّة**). Wine is forbidden because it intoxicates, so every intoxicant is forbidden. The Prophet (peace be upon him) himself reasoned this way when a woman asked whether she could perform Hajj on behalf of her mother, who had vowed to perform it and died:"),
            .hadith("bukhari:1852", cite: "Sahih al-Bukhari 1852", arabic: 49...63, english: [39...70]),
            .text("Qiyas is a source only where no text speaks directly. It is accepted by the four schools and rejected by the Zahiris."),
            .markdown("**Fatwa (فَتوَى)** and **mufti (مُفتِي)**: from ف-ت-ي, to make a matter clear; a fatwa is an answer to a question about a ruling, and the mufti is the one qualified to give it. The Quran uses the very word of Allah answering His servants:"),
            .ayah("4:176", words: 0...5),
            .text("Giving fatwa without knowledge is a grave sin. The Prophet (peace be upon him) said:"),
            .hadith("ibnmajah:53", cite: "Sunan Ibn Majah 53; graded hasan by al-Albani", arabic: 44...53, english: [6...27]),
            .markdown("**The five rulings (الأَحكَام الخَمسَة)**: every act falls under one of five. **Fard (فَرض)** or **wajib (وَاجِب)**: obligatory. Fard is from ف-ر-ض, to cut or fix definitively (Allah calls the shares of inheritance “an obligation [imposed] by Allah,” Quran 4:11), and wajib is from و-ج-ب, to be binding. Most scholars use the two as synonyms; the Hanafis reserve fard for what is established by definitive proof and wajib for what is established by probable proof. One is rewarded for doing it and punished for leaving it. **Mustahabb (مُستَحَبّ)**, also called sunnah or **mandub (مَندُوب)**: recommended, from ح-ب-ب, to love; rewarded if done, not punished if left. **Mubah (مُبَاح)**: permitted, from ب-و-ح, to be open; neither reward nor punishment in itself. **Makruh (مَكرُوه)**: disliked, from ك-ر-ه, to hate; rewarded for leaving it, not punished for doing it. **Haram (حَرَام)**: forbidden, from ح-ر-م, to be inviolable; punished for doing it and rewarded for leaving it out of obedience. Only Allah assigns these categories:"),
            .ayah("16:116", words: 0...13),
            .markdown("**Halal (حَلَال)** and **haram (حَرَام)**: halal is from ح-ل-ل, to untie or release, hence what is permitted; haram is what is forbidden. Between the two lie doubtful matters, and piety is to keep clear of them. The Prophet (peace be upon him) said:"),
            .hadith("bukhari:52", cite: "Sahih al-Bukhari 52, Sahih Muslim 1599", arabic: 23...39, english: [6...45]),
            .markdown("**Rukhsah (رُخصَة)** and **‘azimah (عَزِيمَة)**: ‘azimah, from ع-ز-م, resolve, is the original ruling; rukhsah, from ر-خ-ص, ease, is the concession Allah grants when there is hardship: shortening the prayer and breaking the fast on a journey, tayammum when water is absent, eating forbidden meat under necessity. Allah says of the fast:"),
            .ayah("2:185", words: 27...34),
            .text("When Umar (may Allah be pleased with him) asked the Prophet (peace be upon him) why the prayer is still shortened on journeys now that the Muslims are safe, he answered:"),
            .hadith("muslim:686a", cite: "Sahih Muslim 686", arabic: 79...85, english: [63...78]),
            .text("And when Hamzah ibn Amr al-Aslami (may Allah be pleased with him) asked whether he sinned by fasting on a journey, since he had the strength for it, he answered:"),
            .hadith("muslim:1121e", cite: "Sahih Muslim 1121", arabic: 64...78, english: [29...58]),
            .markdown("**The four schools**: the Hanafi school of Abu Hanifah an-Nu‘man ibn Thabit (d. 150 AH, Kufa), the Maliki school of Malik ibn Anas (d. 179 AH, Madinah), the Shafi‘i school of Muhammad ibn Idris ash-Shafi‘i (d. 204 AH, Egypt, after Makkah, Madinah, and Iraq), and the Hanbali school of Ahmad ibn Hanbal (d. 241 AH, Baghdad). Each is treated in “The Four Sunni Madhahib” below. Other imams of the same rank had schools that did not survive as living traditions, among them al-Awza‘i (d. 157 AH) in Syria, Sufyan ath-Thawri (d. 161 AH) in Kufa, al-Layth ibn Sa‘d (d. 175 AH) in Egypt, and Ibn Jarir at-Tabari (d. 310 AH) in Baghdad."),
            .markdown("**The Zahiri school (الظَّاهِرِيَّة)**: from zahir (ظَاهِر), the apparent; the school of Dawud ibn Ali al-Asbahani, known as az-Zahiri (d. 270 AH, Baghdad), a pupil of Ishaq ibn Rahawayh and Abu Thawr, and developed most fully by Ibn Hazm al-Andalusi (d. 456 AH), author of al-Muhalla in fiqh and al-Ihkam in usul. The Zahiris hold to the apparent meaning of the texts and to consensus, and reject qiyas as a source. Scholars valued its devotion to the texts (adh-Dhahabi records in Siyar A‘lam an-Nubala’ that al-‘Izz ibn Abd as-Salam counted al-Muhalla, with Ibn Qudamah’s al-Mughni, among the finest books of fiqh), while noting that in some questions of Allah’s attributes Ibn Hazm departed from the way of the Salaf. The school did not survive as a living tradition with its own continuous community."),
            .markdown("**Ahl ar-Ra’y (أَهل الرَّأي)** and **Ahl al-Hadith (أَهل الحَدِيث)**: “the people of considered opinion” and “the people of hadith,” the two tendencies of early fiqh. Ahl ar-Ra’y, centred in Kufa and represented by Abu Hanifah and his companions, made wide use of qiyas and juristic preference (istihsan), partly because fewer narrations were established in Iraq, where forgery was also more common, so its jurists were stricter in what they accepted. Ahl al-Hadith, centred in Madinah and Makkah and represented by Malik, then by ash-Shafi‘i and Ahmad, kept close to the narrated texts and used qiyas sparingly. The labels describe an emphasis, not a rejection: the Hanafis accept authentic hadith, and the hadith scholars use analogy. Ash-Shafi‘i studied the Iraqi fiqh under Muhammad ash-Shaybani and the Madinan fiqh under Malik, and his usul brought the two together."),
            .markdown("**The seven fuqaha of Madinah (الفُقَهَاء السَّبعَة)**: the seven jurists of the generation after the Companions who carried the fiqh of Madinah at the end of the first century AH: Sa‘id ibn al-Musayyib, ‘Urwah ibn az-Zubayr, al-Qasim ibn Muhammad ibn Abi Bakr, Kharijah ibn Zayd ibn Thabit, ‘Ubaydullah ibn Abdullah ibn ‘Utbah, Sulayman ibn Yasar, and a seventh whom the lists give as Abu Bakr ibn Abd ar-Rahman ibn al-Harith, Salim ibn Abdullah ibn Umar, or Abu Salamah ibn Abd ar-Rahman. Their students, above all Ibn Shihab az-Zuhri, taught Malik, so the Maliki school stands on the fiqh of Madinah at one remove from the Companions."),
            .markdown("**The four Abdullahs (العَبَادِلَة الأَربَعَة)**: four Companions named Abdullah whose fatawa shaped early fiqh: Abdullah ibn Umar, Abdullah ibn Abbas, Abdullah ibn az-Zubayr, and Abdullah ibn Amr ibn al-As (may Allah be pleased with them). When they agreed on a ruling it was called “the opinion of the Abadilah.” Abdullah ibn Mas‘ud (may Allah be pleased with him) died earlier and, as Imam Ahmad noted (reported by Ibn as-Salah in his Muqaddimah), is not counted among them, but he is the root of the fiqh of Kufa: his students Alqamah and al-Aswad taught Ibrahim an-Nakha‘i, who taught Hammad ibn Abi Sulayman, the teacher of Abu Hanifah. Ibn Abbas’s circle in Makkah (Ata’, Mujahid, Tawus, and Ikrimah) and Ibn Umar’s student Nafi‘, from whom Malik narrated, show that every madhhab goes back through the Tabi‘in to the Companions, and through them to the Prophet (peace be upon him)."),
        ]),
    ]
}

struct AhlulBaytView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Ahlul Bayt are the family of the Prophet; loving, honoring, and upholding their rights is part of the religion.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "The **Ahlul Bayt (أَهلُ البَيت)**, literally “the People of the House,“ are the family of Prophet Muhammad (peace be upon him). Loving them, honoring them, and upholding their rights is part of the religion, and hating them or belittling them is a grave sin.")
                        .font(.body)

                    Text(verbatim: "The Quran uses the term directly when addressing the Prophet’s household:")
                        .font(.body)

                    ScriptureQuote(quran: "33:33", words: 15...24)

                    Text(verbatim: "This is one continuous passage. It is essential to read the verses immediately before and after it to see who is being addressed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE WIVES ARE PART OF THE AHLUL BAYT")) {
                    Text(verbatim: "The verse of purification (33:33) sits in the middle of a passage directed to the Prophet’s wives (may Allah be pleased with them). The address begins:")
                        .font(.body)

                    ScriptureQuote(quran: "33:32", words: 0...10)

                    ScriptureQuote(quran: "33:33", words: 15...24)

                    ScriptureQuote(quran: "33:34")

                    Text(articleMarkdown: "The phrase “O people of the household“ is therefore addressed, first and foremost, to the wives of the Prophet (peace be upon him), the **Mothers of the Believers (أُمَّهَاتُ المُؤمِنِين)**, whom Allah placed in the position of mothers to every believer (Quran 33:6).")
                        .font(.body)

                    Text(verbatim: "Allah also called the wife of Ibrahim (peace be upon him) part of the “people of the house“ using the very same expression:")
                        .font(.body)

                    ScriptureQuote(quran: "11:73")

                    Text(verbatim: "So a prophet’s wives being included in “Ahl al-Bayt“ is the established Quranic usage, not an exception.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE FAMILY OF THE CLOAK")) {
                    Text(articleMarkdown: "The Ahlul Bayt also includes the Prophet’s daughter **Fatimah**, his cousin and son-in-law **Ali**, and their sons **al-Hasan** and **al-Husayn** (may Allah be pleased with them all).")
                        .font(.body)

                    Text(verbatim: "Aisha (may Allah be pleased with her) narrated:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2424", cite: "Sahih Muslim 2424", arabic: 35...78, english: 0...19)

                    Text(verbatim: "Including these four does not exclude the wives; the Prophet (peace be upon him) was gathering additional members of his household under the cloak, within a passage whose context is already addressing his wives. The two are complementary, not contradictory.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said of his grandsons:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:3768", cite: "Sunan al-Tirmidhi 3768; graded sahih by al-Albani", arabic: 37...42, english: 7...17)

                    Text(verbatim: "And of Fatimah (may Allah be pleased with her) he said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3714", cite: "Sahih al-Bukhari 3714", arabic: 28...33, english: 4...18)
                }

                Section(header: ArticleHeader("THE BANU HASHIM AND THE PROPHET’S KIN")) {
                    Text(verbatim: "The Ahlul Bayt further includes the relatives of the Prophet (peace be upon him) upon whom charity (sadaqah) is forbidden: the family of Ali, the family of Ja‘far, the family of Aqil, and the family of al-Abbas (may Allah be pleased with them).")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:1072b", cite: "Sahih Muslim 1072", arabic: 105...118, english: 80...105)

                    Text(verbatim: "Zayd ibn Arqam (may Allah be pleased with him) was asked, “Who are the people of his household? Are not his wives among the people of his household?” He said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2408a", cite: "Sahih Muslim 2408", arabic: 212...222, english: 269...292)
                }

                Section(header: ArticleHeader("THE COMMAND TO LOVE THEM")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)

                    ScriptureQuote(quran: "42:23", words: 9...17)

                    Text(verbatim: "At the pool of Khumm, between Makkah and Madinah, the Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:2408a", cite: "Sahih Muslim 2408", english: [177...211, 226...245], arabicText: "وَأَنَا تَارِكٌ فِيكُم ثَقَلَينِ أَوَّلُهُمَا كِتَابُ اللَّهِ فِيهِ الهُدَى وَالنُّورُ فَخُذُوا بِكِتَابِ اللَّهِ وَاستَمسِكُوا بِهِ … وَأَهلُ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي أُذَكِّرُكُمُ اللَّهَ فِي أَهلِ بَيتِي")

                    Text(verbatim: "Every believer sends blessings upon them in each prayer, in the words the Prophet (peace be upon him) taught:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:3370", cite: "Sahih al-Bukhari 3370", arabic: 79...113, english: 68...137)

                    Text(verbatim: "Loving the Ahlul Bayt is a sign of faith. It is never in tension with loving the Companions (may Allah be pleased with them): Ali, al-Hasan, al-Husayn, and the Prophet’s wives were themselves among the Companions.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE BALANCED POSITION")) {
                    Text(articleMarkdown: "There are two errors regarding the Ahlul Bayt. Some **neglect their rights** and fail to honor them as Allah and His Messenger commanded. Others **exaggerate beyond bounds**, elevating them past the station Allah gave them, or using love of them as a pretext to curse and slander the Companions.")
                        .font(.body)

                    Text(verbatim: "The straight path is between the two: love and honor them without exaggeration, and love all the Companions of the Prophet (peace be upon him) alongside them.")
                        .font(.body)

                    ScriptureQuote(quran: "59:10")

                    Text(verbatim: "Ali, al-Hasan, and al-Husayn (may Allah be pleased with them) themselves loved, prayed behind, married into, and named their children after Abu Bakr, Umar, and Uthman (may Allah be pleased with them): Ali said that the best of this ummah after its Prophet is Abu Bakr, then Umar (Sahih al-Bukhari 3671), Umar married Ali’s daughter Umm Kulthum (Sahih al-Bukhari 2881), and Ali named sons Abu Bakr, Umar, and Uthman (Ibn Sa‘d, at-Tabaqat). Their example is the proof of this unity.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Balanced love for the Prophet's household, without exaggeration or neglect, is the way of the believers, joined with love for all his Companions.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "AhlulBaytView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The People of the House")
        .selectableArticleList(article: "AhlulBaytView")
    }
}

struct AhlusSunnahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Ahl as-Sunnah wal-Jama'ah are those who hold to the Sunnah of the Prophet upon the understanding of his Companions, united in creed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Ahl as-Sunnah wal-Jama‘ah (أَهلُ السُّنَّةِ وَالجَمَاعَة)** means “the People of the Sunnah and the Community.“ They are those who hold to the Sunnah of the Prophet Muhammad (peace be upon him) and remain united upon the understanding of his Companions (may Allah be pleased with them).")
                        .font(.body)

                    Text(articleMarkdown: "**Sunnah** here means the Prophet’s way: his beliefs, statements, actions, and approvals. **Jama‘ah** means the united body of the believers, and specifically the way of the Companions and those who followed them in goodness.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)

                    ScriptureQuote(quran: "4:115")

                    Text(verbatim: "“The way of the believers“ in this verse is the way of the first believers: the Companions.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE THREE FOUNDATIONS")) {
                    Text(articleMarkdown: "**1. The Quran**: taken as it is, without distortion, denial, or asking “how.“")
                        .font(.body)

                    Text(articleMarkdown: "**2. The authentic Sunnah**: accepted as binding revelation alongside the Quran, whether the report is mutawatir or an authentic single narration (ahad).")
                        .font(.body)

                    Text(articleMarkdown: "**3. The understanding of the Salaf**: the Quran and Sunnah are understood the way the first three generations understood them, not according to later opinions or personal reasoning that contradicts them.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(quran: "9:100", words: 0...12)

                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:2652", cite: "Sahih al-Bukhari 2652", arabic: 29...37, english: 4...23)
                }

                Section(header: ArticleHeader("THEIR CREED (AQEEDAH)")) {
                    Text(articleMarkdown: "• **Tawhid**: Allah alone is worshipped, and He alone is the Lord, and He is called by His beautiful Names and described by His perfect Attributes.")
                        .font(.body)

                    Text(articleMarkdown: "• **Names and Attributes**: affirmed as Allah affirmed them for Himself, without likening Him to creation (tashbih) and without stripping the meanings away (ta‘til).")
                        .font(.body)

                    ScriptureQuote(quran: "42:11", words: 13...18)

                    Text(articleMarkdown: "• **Iman** consists of belief in the heart, statement of the tongue, and action of the limbs. It increases with obedience and decreases with disobedience.")
                        .font(.body)

                    Text(articleMarkdown: "• **Qadar**: everything occurs by Allah’s knowledge, writing, will, and creation, while the servant has real choice and responsibility.")
                        .font(.body)

                    Text(articleMarkdown: "• **No takfir** of a Muslim for a major sin, so long as he does not deem it lawful. The sinner remains a believer, deficient in faith.")
                        .font(.body)

                    Text(articleMarkdown: "• Love for **all the Companions** (may Allah be pleased with them) and the **Ahlul Bayt**, without exaggeration in either direction.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE SAVED GROUP")) {
                    Text(verbatim: "The Prophet (peace be upon him) said:")
                        .font(.body)
                    ScriptureQuote(hadith: "ibnmajah:3992", cite: "Sunan Ibn Majah 3992; graded sahih by al-Albani", arabic: 38...90, english: 0...78)

                    Text(verbatim: "In another narration he described that one group as:")
                        .font(.body)
                    ScriptureQuote(hadith: "tirmidhi:2641", cite: "Sunan al-Tirmidhi 2641; graded hasan by al-Albani", arabic: 91...94, english: 86...92)

                    Text(articleMarkdown: "The defining measure in this hadith is not a name or a label, but a **standard**: the Jama‘ah, what the Prophet (peace be upon him) and his Companions were upon. Ahl as-Sunnah wal-Jama‘ah is simply the name for those who hold to that standard.")
                        .font(.body)

                    Text(verbatim: "He (peace be upon him) also said:")
                        .font(.body)
                    ScriptureQuote(hadith: "abudawud:4607", cite: "Sunan Abi Dawud 4607; graded sahih by al-Albani", arabic: 112...132, english: 159...192)
                }

                Section(header: ArticleHeader("UNITY, NOT SECTARIANISM")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) commands unity upon the truth:")
                        .font(.body)

                    ScriptureQuote(quran: "3:103", words: 0...5)

                    ScriptureQuote(quran: "6:159", words: 0...9)

                    Text(verbatim: "Ahl as-Sunnah wal-Jama‘ah is therefore not a sect among sects. It is the original, undivided Islam of the Prophet (peace be upon him) and his Companions. Its adherents differ in fiqh across the four madhahib, yet stand united in creed.")
                        .font(.body)

                    Text(verbatim: "They are known for mercy toward the believers, honesty toward opponents, obedience to Muslim authority in what is good, and refusal to declare the general body of Muslims outside of Islam.")
                        .font(.body)
                }

                Section(header: ArticleHeader("CONCLUSION")) {
                    Text(verbatim: "To be from Ahl as-Sunnah wal-Jama‘ah is to take the Quran and the authentic Sunnah as they came, to understand them as the Companions understood them, to love the Prophet’s family and his Companions together, and to hold to the community of the Muslims.")
                        .font(.body)

                    ScriptureQuote(quran: "2:137", words: 0...7)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Not a sect but the original, undivided Islam: taking the Quran and Sunnah as the Companions did, and loving the Prophet's family and Companions together.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "AhlusSunnahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ahl As-Sunnah")
        .selectableArticleList(article: "AhlusSunnahView")
    }
}

struct SeerahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Seerah is the life story of Prophet Muhammad: his character, mission, and example, drawn from the Quran and authentic reports.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "The **Seerah (سِيرَة)** is the biography of the Prophet Muhammad (peace be upon him): the account of his life, character, and mission, drawn from the Quran and authentic reports.")
                        .font(.body)

                    Text(verbatim: "Studying it is not merely history; it shows how revelation was lived, and it is a means of knowing, loving, and following him.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(quran: "33:21")
                }

                Section(header: ArticleHeader("BEFORE PROPHETHOOD")) {
                    Text(articleMarkdown: "He was born in the year 570 CE in **Makkah (مَكَّة)**, among the tribe of Quraysh. His father Abdullah died before his birth and his mother Aminah when he was six, so he was raised by his grandfather Abd al-Muttalib and then his uncle Abu Talib.")
                        .font(.body)

                    Text(articleMarkdown: "Even before revelation his people called him **Al-Amin (الأَمِين)**, “the Trustworthy,” for his honesty and noble character. At about twenty-five he married **Khadijah (خَدِيجَة)** (may Allah be pleased with her).")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE FIRST REVELATION")) {
                    Text(articleMarkdown: "At the age of forty, while worshipping alone in the cave of **Hira (حِرَاء)** near Makkah, the angel **Jibril (جِبرِيل)** brought him the first revelation, beginning with **Iqra (اِقرَأ)**:")
                        .font(.body)
                    ScriptureQuote(quran: "96:1")

                    Text(verbatim: "This began twenty-three years of the revelation of the Quran, which continued until shortly before his death.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE MAKKAN PERIOD")) {
                    Text(articleMarkdown: "For about thirteen years in Makkah he called people to **Tawhid (تَوحِيد)**, the worship of Allah alone, through his **Dawah (دَعوَة)**, his call to Islam. He and the early believers met mockery, boycott, and severe persecution, yet remained patient.")
                        .font(.body)

                    Text(articleMarkdown: "In this period he was honoured with the **Isra and Mi'raj (الإِسرَاء وَالمِعرَاج)**, the night journey to Jerusalem and the ascension through the heavens, during which the five daily prayers were made obligatory.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE HIJRAH")) {
                    Text(articleMarkdown: "In 622 CE, by Allah’s command, the Prophet (peace be upon him) made the **Hijrah (هِجرَة)**, the migration from Makkah to **Madinah (المَدِينَة)**. This event was so pivotal that the Islamic (Hijri) calendar begins from it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE MADINAN PERIOD")) {
                    Text(verbatim: "In Madinah he established the first Muslim community: building the mosque, joining the emigrants (Muhajirun) and the helpers (Ansar) in brotherhood, and governing by revelation.")
                        .font(.body)

                    Text(articleMarkdown: "The community was tested and defended in major events such as **Badr (بَدر)**, **Uhud (أُحُد)**, and the Battle of the Trench, **Al-Khandaq (الخَندَق)**. The **Treaty of Hudaybiyyah (الحُدَيبِيَة)** opened the way for peace, and in 630 CE Makkah was entered peacefully and cleansed of idols.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE FAREWELL AND HIS PASSING")) {
                    Text(articleMarkdown: "In 10 AH he performed the Farewell Pilgrimage, **Hajjat al-Wada (حَجَّة الوَدَاع)**, and delivered his Farewell Sermon before a great gathering of believers.")
                        .font(.body)

                    Text(verbatim: "He passed away in Madinah in 11 AH / 632 CE, at the age of sixty-three, and is buried there. He left behind the Quran and his Sunnah as guidance for all who came after.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HIS CHARACTER")) {
                    Text(articleMarkdown: "He was sent as a mercy to all creation, **Rahmatan lil-Alamin (رَحمَة لِلعَالَمِين)**.")
                        .font(.body)

                    ScriptureQuote(quran: "21:107")

                    Text(verbatim: "When Aishah (may Allah be pleased with her) was asked about his character, she said:")
                        .font(.body)
                    ScriptureQuote(hadith: "muslim:746a", cite: "Sahih Muslim 746", arabic: 232...241, english: 293...303)
                    Text(verbatim: "He embodied its teachings in the most complete way.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Studying the Seerah shows how revelation was lived and deepens a Muslim's love and following of the Prophet, the best example for all people.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "SeerahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Seerah")
        .selectableArticleList(article: "SeerahView")
    }
}

struct TafsirView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Tafsir is the explanation of the Quran's meanings, soundest when the Quran is explained by the Quran, the Sunnah, and the understanding of the early generations.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Tafsir (تَفسِير)** is the explanation and clarification of the meanings of the Quran: its words, rulings, and wisdoms. Its scholar is called a **Mufassir (مُفَسِّر)**.")
                        .font(.body)

                    Text(articleMarkdown: "Its blameworthy counterpart is **Tafsir bir-Ra'y (تَفسِير بِالرَّأي)** in the censured sense: interpreting the Quran by mere opinion, away from its established meaning and the understanding of the Salaf.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(quran: "38:29", words: 0...5)
                }

                Section(header: ArticleHeader("HOW THE QURAN IS EXPLAINED")) {
                    Text(articleMarkdown: "The soundest tafsir is **bil-ma'thur (بِالمَأثُور)**, by transmission, and it proceeds in order:")
                        .font(.body)

                    Text(articleMarkdown: "**1. The Quran by the Quran**: a matter left general in one place is often clarified in another.")
                        .font(.body)

                    Text(articleMarkdown: "**2. The Quran by the Sunnah**: the Prophet (peace be upon him) explained what was revealed to him.")
                        .font(.body)
                    ScriptureQuote(quran: "16:44", words: 2...9)

                    Text(articleMarkdown: "**3. The statements of the Companions (Sahabah)**: they witnessed the revelation and knew its context best.")
                        .font(.body)

                    Text(articleMarkdown: "**4. The statements of the Successors (Tabi'un)**: the students of the Companions, followed by explanation through the Arabic language.")
                        .font(.body)
                }

                Section(header: ArticleHeader("CONDITIONS OF THE MUFASSIR")) {
                    Text(verbatim: "Explaining the Quran is not by desire or guesswork. It requires sound belief, knowledge of the Arabic language, the Sunnah, the sayings of the early scholars, and the sciences of the Quran.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) warned:")
                        .font(.body)

                    ScriptureQuote(quran: "17:36")

                    Text(verbatim: "And He counted among what He has forbidden:")
                        .font(.body)
                    ScriptureQuote(quran: "7:33", words: 22...28)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) also said:")
                        .font(.body)
                    ScriptureQuote(hadith: "bukhari:108", cite: "Sahih al-Bukhari 108", arabic: 27...34, english: 20...35)
                }

                Section(header: ArticleHeader("WELL-KNOWN WORKS")) {
                    Text(articleMarkdown: "Among the most trusted classical works of tafsir are those of **al-Tabari (الطَّبَرِي)**, **Ibn Kathir (اِبن كَثِير)**, and **al-Baghawi (البَغَوِي)**, and among later concise works, that of **al-Sa'di (السَّعدِي)**. They are prized for explaining the Quran by the Quran, the Sunnah, and the understanding of the early generations.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "True Tafsir rests on knowledge, not opinion; through it the guidance of the Quran becomes clear and livable for every generation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("KEY TERMS")) {
                    Text(articleMarkdown: "**Asbab al-Nuzul (أَسبَاب النُّزُول)**: the reasons or occasions of revelation, i.e. the events a verse was revealed about.")
                        .font(.body)

                    Text(articleMarkdown: "**Muhkam (مُحكَم)**: verses clear and decisive in meaning; **Mutashabih (مُتَشَابِه)**: verses whose full meaning is not entirely apparent, referred back to the clear ones.")
                        .font(.body)

                    Text(articleMarkdown: "**An-Nasikh wal-Mansukh (النَّاسِخ وَالمَنسُوخ)**: the abrogating and abrogated; a later ruling that replaces an earlier one within the revelation.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "TafsirView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tafsir")
        .selectableArticleList(article: "TafsirView")
    }
}

struct FiqhAqeedahManhajView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: aqeedah is what you believe, fiqh is what you do, and manhaj is how you understand and derive both from revelation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Three words describe how a Muslim believes, acts, and understands the religion: **Aqeedah (عَقِيدَة)**, **Fiqh (فِقه)**, and **Manhaj (مَنهَج)**.")
                        .font(.body)

                    Text(verbatim: "In short: aqeedah is what you believe, fiqh is what you do, and manhaj is how you understand and derive both.")
                        .font(.body)
                }

                Section(header: ArticleHeader("AQEEDAH (BELIEF)")) {
                    Text(articleMarkdown: "**Aqeedah (عَقِيدَة)** is creed: the beliefs the heart is bound to with certainty. Its core is **Tawhid (تَوحِيد)**, singling out Allah alone in worship, lordship, and His names and attributes.")
                        .font(.body)

                    Text(articleMarkdown: "It includes the six pillars of faith: belief in Allah, His angels, His books, His messengers, the Last Day, and **Al-Qadar (القَدَر)**, the divine decree. Aqeedah does not change with time or place and is one for all the believers.")
                        .font(.body)

                    ScriptureQuote(quran: "2:285", words: 0...13)
                }

                Section(header: ArticleHeader("FIQH (JURISPRUDENCE)")) {
                    Text(articleMarkdown: "**Fiqh (فِقه)** is the understanding of the practical rulings of Islam derived from the Quran and Sunnah: the “how“ of worship, **Ibadah (عِبَادَة)**, and of dealings, **Muamalat (مُعَامَلَات)**, such as prayer, fasting, trade, and marriage.")
                        .font(.body)

                    Text(articleMarkdown: "Because deriving detailed rulings involves **Ijtihad (اِجتِهَاد)**, qualified scholarly effort, sincere scholars sometimes differ. This is the source of the accepted schools of fiqh, and such differences are excused and even rewarded (Sahih al-Bukhari 7352); they are not division in the religion.")
                        .font(.body)
                }

                Section(header: ArticleHeader("MANHAJ (METHODOLOGY)")) {
                    Text(articleMarkdown: "**Manhaj (مَنهَج)** is methodology: the path by which one understands, prioritizes, and applies the religion, and deals with knowledge and people.")
                        .font(.body)

                    Text(articleMarkdown: "The sound manhaj is to take the Quran and the authentic Sunnah upon the understanding of the **Salaf (السَّلَف)**, the first righteous generations, rather than by later opinions that contradict them.")
                        .font(.body)

                    ScriptureQuote(quran: "9:100", words: 0...12)
                }

                Section(header: ArticleHeader("HOW THEY RELATE")) {
                    Text(verbatim: "Aqeedah is the foundation, fiqh is the practice built upon it, and manhaj is the method that keeps both tied to revelation as it was first understood.")
                        .font(.body)

                    Text(verbatim: "The believers may differ in points of fiqh while remaining one in aqeedah and united upon a sound manhaj.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "United in creed, allowing valid differences in jurisprudence, and following the method of the first generations: this is the balance a Muslim strives for.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "FiqhAqeedahManhajView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Fiqh, Aqeedah, Manhaj")
        .selectableArticleList(article: "FiqhAqeedahManhajView")
    }
}

#Preview {
    AlIslamPreviewContainer {
        PillarsView()
    }
}

