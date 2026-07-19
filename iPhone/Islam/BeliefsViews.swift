import SwiftUI

struct MosquesView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("THE THREE HOLY MOSQUES")) {
            NavigationLink(destination: LazyDestination { HaramView() }) {
                Text("Masjid Al-Haram (The Holy Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { NabawiView() }) {
                Text("Masjid An-Nabawi (The Prophet’s Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AqsaView() }) {
                Text("Masjid Al-Aqsa (The Farthest Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct HaramView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Masjid al-Haram in Makkah is the holiest mosque in Islam. It surrounds the Kaaba - the House of Allah and the Qiblah toward which all Muslims pray.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Masjid Al-Haram (ٱلمَسجِدُ ٱلحَرَام), or “The Sacred Mosque,“ is located in **Makkah (مَكَّة)**, Saudi Arabia. It is the largest mosque in the world and surrounds the **Ka'bah** (ٱلكَعبَة), the holiest site in Islam. The Ka'bah is also known as “The House of Allah“ (بَيتُ ٱللَّه).")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And [mention] when We made the House (the Ka'bah) a place of return for the people and [a place of] security” (Quran 2:125).")

                    Text("Masjid Al-Haram is the destination for **Hajj (حَجّ)** and **Umrah (عُمرَة)**, two pivotal acts of worship in Islam. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“One prayer in the Sacred Mosque is better than one hundred thousand prayers elsewhere” (Sunan Ibn Majah 1406).", dimmed: true)
                }

                Section(header: Text("SIGNIFICANCE OF THE KA'BAH")) {
                    Text("The **Ka'bah** (ٱلكَعبَة), meaning “The Cube,“ is the symbolic House of Allah. It serves as the **Qiblah** (قِبلَةٌ) (direction of prayer) for Muslims worldwide. Every prayer offered by a Muslim is directed toward the Ka'bah.")
                        .font(.body)

                    Text("The Ka'bah was built by **Prophet Ibrahim** (Abraham, peace be upon him) and his son **Prophet Isma'il** (Ishmael, peace be upon him) as a place of monotheistic worship. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention] when Ibrahim was raising the foundations of the House and [with him] Isma'il, [saying], ‘Our Lord, accept [this] from us. Indeed, You are the Hearing, the Knowing.’” (Quran 2:127)")

                    Text("The **Black Stone** (ٱلحَجَرُ ٱلأَسوَد, Hajar Al-Aswad), embedded in one corner of the Ka'bah, is a sacred relic dating back to the time of Prophet Ibrahim (peace be upon him). Touching or kissing it during **Tawaf** is a Sunnah, but not obligatory.")
                        .font(.body)
                }

                Section(header: Text("THE WELL OF ZAMZAM")) {
                    Text("The **Well of Zamzam** (بِئرُ زَمزَم) is located within Masjid Al-Haram. This miraculous water source was provided by Allah for **Hajar** (may Allah be pleased with her) and her son **Isma'il** (peace be upon him) when they were left in the barren desert. The well continues to flow abundantly to this day.")
                        .font(.body)

                    Text("Drinking Zamzam water is an act of worship and holds immense spiritual blessings.").font(.body)
                }

                Section(header: Text("SPIRITUAL REWARDS AND IMPORTANCE")) {
                    Text("1. **Multiplied Rewards**: Praying in Masjid Al-Haram is rewarded 100,000 times more than praying elsewhere.")
                        .font(.body)
                    Text("2. **Forgiveness of Sins**: Performing Hajj or Umrah with sincerity cleanses one’s sins. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Whoever performs Hajj (pilgrimage) and does not have sexual relations (with his wife), nor commits sin, nor disputes unjustly (during Hajj), then he returns from Hajj as pure and free from sins as on the day on which his mother gave birth to him” (Riyad as-Salihin 1274).", dimmed: true)
                    Text("3. **Unity of the Ummah**: Millions of Muslims from diverse cultures and backgrounds gather in Masjid Al-Haram, symbolizing the unity and equality of the Muslim Ummah under the worship of Allah.")
                        .font(.body)
                }

                Section(header: Text("QURANIC VERSES ABOUT MAKKAH")) {
                    Text("Allah mentions the sanctity of Makkah and Masjid Al-Haram in several verses:").font(.body)
                    ScriptureQuote(text: "“Indeed, the first House [of worship] established for mankind was that at Makkah - blessed and a guidance for the worlds” (Quran 3:96).")
                    ScriptureQuote(text: "“And [mention] when We made the House (the Ka'bah) a place of return for the people and [a place of] security” (Quran 2:125).")
                }

                Section(header: Text("MASJID AL-HARAM")) {
                    Image("Al-Islam")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(24)
                            #if os(iOS)
                            .focusableImage("Al-Islam", title: "Masjid al-Haram")
                            #endif
                            #if os(iOS)
                            .contextMenu {
                                Text("Image Actions")
                                    .foregroundStyle(.secondary)

                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.image = UIImage(named: "Al Haram")
                                } label: {
                                    Text("Copy Image")
                                    Image(systemName: "photo")
                                }
                            }
                            #endif
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("A single prayer here equals a hundred thousand elsewhere. It is the heart of Hajj and Umrah, where the whole Ummah gathers as equals before Allah.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Masjid Al-Haram")
    }
}

struct NabawiView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Masjid an-Nabawi in Madinah is the Prophet's own mosque and the second holiest in Islam, home to the Rawdah and his resting place.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Masjid An-Nabawi (ٱلمَسجِد ٱلنَّبَوِي), or “The Prophet’s Mosque,“ is located in Madinah, Saudi Arabia. Originally known as Yathrib, the city was later renamed **Madinah Al-Nabi (مَدِينَة ٱلنَّبِي)**, meaning “The City of the Prophet,“ or **Madinah Al-Munawwara (ٱلمَدِينَة ٱلمُنَوَّرَة)**, “The Enlightened City,“ after the migration (Hijrah) of Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text("This mosque, built by the Prophet (peace and blessings be upon him) in 622 CE, is the second holiest site in Islam after Masjid Al-Haram. The Prophet (peace and blessings be upon him) made it a center of worship, governance, and community life.")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“One prayer in my mosque is better than a thousand prayers in any other mosque except Al-Masjid Al-Haram” (Sahih Bukhari 1190).", dimmed: true)
                }

                Section(header: Text("SIGNIFICANCE")) {
                    Text("Masjid An-Nabawi is home to the **Rawdah (ٱلرَّوضَة)**, an area between the Prophet's pulpit and his house, which he described as a garden from the gardens of Paradise. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Between my house and my pulpit there is a garden of the gardens of Paradise” (Sahih al-Bukhari 1196).", dimmed: true)

                    Text("The mosque also contains the grave of the Prophet Muhammad (peace and blessings be upon him) and his companions Abu Bakr As-Siddiq and Umar ibn Al-Khattab (may Allah be pleased with them). It is from the Sunnah to send salaam upon him when you are there.")
                        .font(.body)
                }

                Section(header: Text("A WARNING AGAINST SHIRK")) {
                    Text("This must be clear, because it is where people fall. You do **not** pray to the Prophet (peace and blessings be upon him). You do **not** pray facing his grave. You do not ask him for anything, you do not seek help or intercession from him, and you do not circle or touch the grave seeking blessing. All of that is **shirk (شِرك)**, associating partners with Allah, and it is the one sin Allah does not forgive if a person dies upon it.")
                        .font(.body)

                    Text("Duaa is worship, and worship belongs to Allah alone:")
                        .font(.body)
                    ScriptureQuote(text: "“And the mosques are for Allah, so do not invoke with Allah anyone” (Quran 72:18).")

                    Text("When you pray in Masjid An-Nabawi, you face the Qiblah, towards the Kaaba in Makkah, exactly as you would anywhere else on earth. The grave happens to lie in that direction from parts of the mosque; that is a fact of geography, not a thing to be prayed towards.")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) himself warned against precisely this, in his final illness:")
                        .font(.body)
                    ScriptureQuote(text: "“May Allah curse the Jews and the Christians, for they took the graves of their prophets as places of worship” (Sahih al-Bukhari 435, Sahih Muslim 531).", dimmed: true)

                    Text("He also said: “Do not make my grave a place of festivity, and send blessings upon me, for your blessings reach me wherever you are” (Sunan Abi Dawud 2042).")
                        .font(.body)

                    Text("So love him, follow him, and send salaah and salaam upon him abundantly. But direct every act of worship to Allah alone. That is what he taught, and honouring him means obeying him.")
                        .font(.body)
                }

                Section(header: Text("SPIRITUAL BENEFITS")) {
                    Text("1. **Multiplied Rewards**: Prayers in Masjid An-Nabawi are rewarded 1,000 times more than prayers in other mosques (except Masjid Al-Haram).")
                        .font(.body)
                    Text("2. **Connection to the Prophet**: Standing in a place where the Prophet Muhammad (peace and blessings be upon him) worshipped and led his companions strengthens one’s faith and love for him.")
                        .font(.body)
                    Text("3. **Rawdah Visit**: Visiting the Rawdah and praying there is considered highly virtuous.")
                        .font(.body)
                }

                Section(header: Text("QURANIC VERSES ABOUT THE MOSQUE")) {
                    Text("Allah emphasizes the sanctity of mosques, particularly those established on righteousness. He says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“A mosque founded on righteousness from the first day is more worthy for you to stand in” (Quran 9:108).")
                }

                Section(header: Text("MASJID AN-NABAWI")) {
                    Image("Al-Quran")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                        #if os(iOS)
                        .focusableImage("Al-Quran", title: "Masjid an-Nabawi")
                        #endif
                        #if os(iOS)
                        .contextMenu {
                            Text("Image Actions")
                                .foregroundStyle(.secondary)

                            Button {
                                settings.hapticFeedback()
                                UIPasteboard.general.image = UIImage(named: "An Nabawi")
                            } label: {
                                Text("Copy Image")
                                Image(systemName: "photo")
                            }
                        }
                        #endif
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("A prayer here equals a thousand elsewhere. It was the Prophet's center of worship and community, and visiting it deepens a believer's love for him.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Masjid An-Nabawi")
    }
}

struct AqsaView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Masjid al-Aqsa in Jerusalem is the third holiest mosque, the first Qiblah, and the destination of the Prophet's Night Journey (Isra and Mi'raj).")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Masjid Al-Aqsa (ٱلمَسجِد ٱلأَقصَىٰ), meaning “The Farthest Mosque,“ is located in Jerusalem, Palestine, within a compound known as **Al-Haram Ash-Sharif (ٱلحَرَم ٱلشَّرِيف)**, or “The Noble Sanctuary.“ It is the third holiest mosque in Islam after Masjid Al-Haram in Makkah and Masjid An-Nabawi in Madinah.")
                        .font(.body)

                    Text("Masjid Al-Aqsa holds immense historical and spiritual significance in Islam. Allah (Glorified and Exalted be He) mentions it in the Quran:").font(.body)
                    ScriptureQuote(text: "“Exalted is He who took His Servant by night from Al-Masjid Al-Haram to Al-Masjid Al-Aqsa, whose surroundings We have blessed, to show him of Our signs. Indeed, He is the Hearing, the Seeing” (Quran 17:1).")

                    Text("It was the first Qiblah (direction of prayer) for Muslims before it was changed to the Ka'bah in Makkah, and it was the destination of the Prophet Muhammad’s (peace and blessings be upon him) Night Journey, **Isra (الإِسرَاء)**, before his Ascension, **Mi'raj (المِعرَاج)**.")
                        .font(.body)
                }

                Section(header: Text("SPIRITUAL SIGNIFICANCE")) {
                    Text("1. **First Qiblah**: Muslims initially faced Masjid Al-Aqsa during their prayers, highlighting its significance from the earliest days of Islam.").font(.body)
                    Text("2. **Al-Isra wa al-Mi'raj (الإِسرَاء وَالمِعرَاج)**: It was the destination of the miraculous Night Journey of the Prophet Muhammad (peace and blessings be upon him), during which he led all prophets in prayer before ascending to the heavens.").font(.body)
                    Text("3. **Land of Blessings**: The Quran describes the surroundings of Masjid Al-Aqsa as a blessed land. Allah says:").font(.body)
                    ScriptureQuote(text: "“And We delivered him and Lot to the land which We had blessed for all people” (Quran 21:71).")
                }

                Section(header: Text("HISTORICAL AND RELIGIOUS IMPORTANCE")) {
                    Text("Masjid Al-Aqsa is a place of worship for many prophets, including Ibrahim (Abraham), Dawud (David), and Sulaiman (Solomon) (peace be upon them). It is believed that Prophet Muhammad (peace and blessings be upon him) led all the prophets in prayer here during the Night Journey.")
                        .font(.body)

                    Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Do not undertake a journey to visit any mosque but three: Al-Masjid Al-Haram, Al-Masjid An-Nabawi, and Al-Masjid Al-Aqsa” (Sahih al-Bukhari 1189).", dimmed: true)
                }

                Section(header: Text("REWARDS OF PRAYING IN MASJID AL-AQSA")) {
                    Text("Prayer in the three sacred mosques carries immense reward. What is established is the authentic narration in which the Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“A prayer in this mosque of mine is better than a thousand prayers elsewhere, except for Al-Masjid Al-Haram” (Sahih al-Bukhari 1190).", dimmed: true)

                    Text("A report giving a specific figure for Masjid Al-Aqsa (fifty thousand prayers) is narrated in Sunan Ibn Majah 1413, but its chain is weak (da'if) - and its figure for Masjid An-Nabawi contradicts the authentic hadith above - so it is not relied upon.").font(.body)
                }

                Section(header: Text("STRUCTURE AND FEATURES")) {
                    Text("Masjid Al-Aqsa is part of a larger compound that includes the **Dome of the Rock (قُبَّة ٱلصَّخرَة)**, the oldest Islamic architectural monument. The entire compound is considered sacred by Muslims, and the name Masjid Al-Aqsa often refers to the entire Noble Sanctuary.")
                        .font(.body)

                    Text("The mosque’s architecture and location reflect centuries of Islamic devotion and heritage.")
                        .font(.body)
                }

                Section(header: Text("MASJID AL-AQSA")) {
                    Image("Al-Adhan")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                        #if os(iOS)
                        .focusableImage("Al-Adhan", title: "Masjid al-Aqsa")
                        #endif
                        #if os(iOS)
                        .contextMenu {
                            Text("Image Actions")
                                .foregroundStyle(.secondary)

                            Button {
                                settings.hapticFeedback()
                                UIPasteboard.general.image = UIImage(named: "Al Aqsa")
                            } label: {
                                Text("Copy Image")
                                Image(systemName: "photo")
                            }
                        }
                        #endif
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Blessed by Allah and honored by the prophets, Masjid al-Aqsa remains one of the three mosques to which travel for worship is specially encouraged.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Masjid Al-Aqsa")
    }
}

import SwiftUI

/// Quran sciences and the Islamic calendar - knowledge sections shown under "Pillars & Beliefs".
struct BeliefsQuranView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("QURAN & TAFSIR")) {
            NavigationLink(destination: LazyDestination { CompileView() }) {
                Text("Compilation of the Quran")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { TafsirView() }) {
                Text("Tafsir (Exegesis)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { TajweedView() }) {
                Text("Tajweed")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { MuqattaatPillarView() }) {
                Text("Muqatta'at Letters")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { JuzView() }) {
                Text("The 30 Juz (Parts)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AhrufView() }) {
                Text("The 7 Ahruf (Modes)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { QiraatView() }) {
                Text("The 10 Qiraat (Recitations)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }

        Section(header: Text("THE ISLAMIC CALENDAR")) {
            NavigationLink(destination: LazyDestination { HijriCalendarView() }) {
                Text("Hijri Calendar")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

/// The history & creed section, shown under "Pillars & Beliefs".
struct BeliefsHistoricalView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("HISTORICAL & BIOGRAPHICAL")) {
            NavigationLink(destination: LazyDestination { SeerahView() }) {
                Text("The Seerah (Biography)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { FarewellView() }) {
                Text("The Farewell (Final) Sermon")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AhlulBaytView() }) {
                Text("The Ahlul Bayt (People of the House)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { WivesView() }) {
                Text("The Wives of the Prophet")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { SahabahView() }) {
                Text("The Sahabah (Companions)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { CaliphatesView() }) {
                Text("The Caliphates")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { MadhabView() }) {
                Text("The 4 Madhaahib (Schools of Thought)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AhlusSunnahView() }) {
                Text("Ahl As-Sunnah Wal Jama'ah")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { FiqhAqeedahManhajView() }) {
                Text("Fiqh, Aqeedah, and Manhaj")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct WudhuView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Wudhu is the minor ablution. It is a condition for the validity of the prayer, and it wipes away sins as it is performed.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Wudhu (وُضُوء)**, from the root **w-d-a (و ض أ)**, meaning cleanliness and radiance, is the purification performed before **Salah (صَلَاة)**, before touching the Quran, and before **Tawaf (طَوَاف)** around the Kaaba.")
                        .font(.body)
                    Text("Without it, the prayer is not accepted. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah does not accept the prayer of any of you if he breaks his wudhu until he performs wudhu again” (Sahih al-Bukhari 135, Sahih Muslim 225).", dimmed: true)
                }

                Section(header: Text("THE COMMAND IN THE QURAN")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, when you rise to [perform] prayer, wash your faces and your forearms to the elbows and wipe over your heads and [wash] your feet to the ankles” (Quran 5:6).")
                    Text("This one verse names the four obligatory parts: the face, the arms to the elbows, wiping the head, and the feet to the ankles. Everything else in the description below is Sunnah, following the way the Prophet (peace and blessings be upon him) actually did it.")
                        .font(.body)
                }

                Section(header: Text("HOW TO MAKE WUDHU")) {
                    Text("1. Make the **niyyah (نِيَّة)**, the intention, in the heart. It is not said aloud.")
                        .font(.body)
                    Text("2. Say **“Bismillah“ (بِسمِ اللهِ)**.")
                        .font(.body)
                    Text("3. Wash both **hands** up to the wrists, three times.")
                        .font(.body)
                    Text("4. **Rinse the mouth** and **sniff water into the nose** and blow it out, three times. Use the right hand to take the water and the left to blow the nose.")
                        .font(.body)
                    Text("5. Wash the **face** three times, from the hairline to under the chin and from ear to ear. If you have a thick beard, run wet fingers through it.")
                        .font(.body)
                    Text("6. Wash the **right arm** to and including the elbow, three times. Then the **left arm**, three times.")
                        .font(.body)
                    Text("7. **Wipe the head once**, not three times: pass wet hands from the front of the head to the back and return them to the front. Then, with the same water, **wipe the ears**, index fingers inside and thumbs behind.")
                        .font(.body)
                    Text("8. Wash the **right foot** to and including the ankle, three times, running the fingers between the toes. Then the **left foot**, three times.")
                        .font(.body)
                    Text("9. Then say: **“Ash-hadu an la ilaha illa Allah, wahdahu la sharika lah, wa ash-hadu anna Muhammadan abduhu wa rasuluh.“**")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) said about that closing testimony:")
                        .font(.body)
                    ScriptureQuote(text: "“There is no one among you who performs wudhu and does it well, then says: I bear witness that there is no god but Allah alone with no partner, and that Muhammad is His slave and Messenger, but the eight gates of Paradise will be opened for him, and he may enter through whichever of them he wishes” (Sahih Muslim 234).", dimmed: true)

                    Text("Do not be wasteful with water, even at a flowing river. That was the Prophet's instruction (Sunan Ibn Majah 425).")
                        .font(.body)
                }

                Section(header: Text("WHAT BREAKS WUDHU")) {
                    Text("• Anything that exits from the front or back passage: urine, stool, or wind.")
                        .font(.body)
                    Text("• Deep sleep, in which a person loses awareness.")
                        .font(.body)
                    Text("• Loss of consciousness, whether from fainting, intoxication, or illness.")
                        .font(.body)
                    Text("• Touching the private parts directly with the hand, without a barrier.")
                        .font(.body)
                    Text("• Eating camel meat.")
                        .font(.body)
                    Text("Doubt alone does not break it. If you are certain you had wudhu and merely suspect you lost it, you still have it.")
                        .font(.body)
                }

                Section(header: Text("THE REWARD")) {
                    Text("The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“When a Muslim or a believer washes his face (in wudhu), every sin he contemplated with his eyes will be washed away from his face along with the water, or with the last drop of water; when he washes his hands, every sin they wrought will be effaced from his hands with the water, or with the last drop of water; and when he washes his feet, every sin towards which his feet have walked will be washed away with the water or with the last drop of water, with the result that he comes out pure from all sins” (Sahih Muslim 244).", dimmed: true)

                    Text("He also said:")
                        .font(.body)
                    ScriptureQuote(text: "“Shall I not tell you of that by which Allah erases sins and raises ranks? Performing wudhu properly even when it is difficult, taking many steps to the mosque, and waiting for the next prayer after the previous one” (Sahih Muslim 251).", dimmed: true)

                    Text("And he said that his nation will be called on the Day of Resurrection with radiant faces, hands, and feet, from the traces of wudhu (Sahih al-Bukhari 136).")
                        .font(.body)

                    Text("It is also from the Sunnah to make wudhu before sleeping.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Purity is a condition of prayer and a means of erasing sins. Performed with intention and in the way the Prophet performed it, wudhu is an act of worship in itself.")
                        .font(.body)

                    NavigationLink(destination: LazyDestination { GhuslView() }) {
                        Label("Next: How to Make Ghusl", systemImage: "drop.fill")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                    }
                }

                GuideSourcesSection(sources: [
                    (title: "How to Perform Wudhu", subtitle: "Step-by-step guide, IslamQA", url: "https://islamqa.info/en/categories/topics/13/wudoo"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Make Wudhu")
    }
}

struct GhuslView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Ghusl is the full-body wash that lifts major ritual impurity. Until it is performed, the prayer cannot be prayed.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Ghusl (غُسل)**, from the root **gh-s-l (غ س ل)**, to wash, is a complete washing of the body with the intention of lifting major ritual impurity, **Janabah (جَنَابَة)**.")
                        .font(.body)
                    Text("Where wudhu washes specific limbs, ghusl reaches the whole body. Ghusl also removes the need for a separate wudhu, so long as nothing has broken it during the wash.")
                        .font(.body)
                }

                Section(header: Text("WHEN GHUSL IS OBLIGATORY")) {
                    Text("• After marital relations, whether or not there is emission.")
                        .font(.body)
                    Text("• After the emission of maniy (sexual fluid) with desire, whether awake or from a wet dream.")
                        .font(.body)
                    Text("• At the end of **menstruation (حَيض)**.")
                        .font(.body)
                    Text("• At the end of **postpartum bleeding (نِفَاس)**.")
                        .font(.body)
                    Text("• Upon accepting Islam.")
                        .font(.body)
                    Text("• Upon death, the deceased is washed by the living.")
                        .font(.body)
                }

                Section(header: Text("WHEN GHUSL IS RECOMMENDED")) {
                    Text("• Before the **Jumuah (جُمُعَة)** prayer.")
                        .font(.body)
                    Text("• Before the two **Eid** prayers.")
                        .font(.body)
                    Text("• Before entering **Ihram (إِحرَام)** for Hajj or Umrah.")
                        .font(.body)
                    Text("• After washing a deceased person.")
                        .font(.body)
                }

                Section(header: Text("THE COMMAND IN THE QURAN")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you are in a state of janabah, then purify yourselves” (Quran 5:6).")
                    Text("And He says:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not approach prayer while you are intoxicated until you know what you are saying, or in a state of janabah, except those passing through [a place of prayer], until you have washed [your whole body]” (Quran 4:43).")
                }

                Section(header: Text("HOW TO MAKE GHUSL")) {
                    Text("This is the way described by Aisha and Maymunah (may Allah be pleased with them), who saw the Prophet (peace and blessings be upon him) perform it (Sahih al-Bukhari 248, 249, 257).")
                        .font(.body)

                    Text("1. Make the **niyyah (نِيَّة)** in the heart to lift the state of janabah.")
                        .font(.body)
                    Text("2. Say **“Bismillah“**, and wash both **hands** three times.")
                        .font(.body)
                    Text("3. Wash the **private parts** and any impurity from the body with the left hand, then wash the hand.")
                        .font(.body)
                    Text("4. Perform a **complete wudhu**, as you would for prayer.")
                        .font(.body)
                    Text("5. Pour water over the **head three times**, working the fingers through the hair so the water reaches the roots of every hair.")
                        .font(.body)
                    Text("6. Pour water over the **right side** of the body, then the **left side**, ensuring the water reaches every part: under the arms, inside the navel, behind the ears, between the toes.")
                        .font(.body)
                    Text("7. Move from your place and **wash the feet**, if you did not wash them during the wudhu.")
                        .font(.body)

                    Text("**The obligation is only two things:** the intention, and that water reaches every part of the body including the mouth and nose. The order and the repetition above are Sunnah. If a person simply immerses fully in water with the intention, the ghusl is valid.")
                        .font(.body)

                    Text("Women do **not** need to undo braided hair for the ghusl of janabah, so long as the water reaches the roots. Umm Salamah (may Allah be pleased with her) asked about this, and the Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“No, it is enough for you to pour three handfuls of water over your head, then pour water over yourself, and you will be purified” (Sahih Muslim 330).", dimmed: true)
                }

                Section(header: Text("IF THERE IS NO WATER: TAYAMMUM")) {
                    Text("If water cannot be found, or using it would cause harm or illness, then **Tayammum (تَيَمُّم)**, dry purification, takes its place for both wudhu and ghusl. Allah says in the same verse:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you do not find water, then seek clean earth and wipe over your faces and your hands [with it]” (Quran 5:6).")
                    Text("Strike clean earth once with both palms, then wipe the face, then wipe the hands. That is all.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Ghusl lifts major impurity and returns a person to the state in which they may pray. Its obligation is simple: intend it, and let the water reach all of you.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Perform Ghusl", subtitle: "Step-by-step guide, IslamQA", url: "https://islamqa.info/en/answers/83057"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Make Ghusl")
    }
}

struct JumuahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Jumuah is the Friday congregational prayer that replaces Dhuhr - a sermon followed by two rak'ah, obligatory on Muslim men who are able.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Jumuah (جُمُعَة) comes from the root **j-m-a (ج م ع)**, meaning to gather or congregate. It refers to the Friday congregational prayer that replaces Dhuhr.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“O you who have believed, when [the adhan] is called for the prayer on the day of Jumu’ah [Friday], then proceed to the remembrance of Allah and leave trade. That is better for you, if you only knew” (Quran 62:9).")

                    Text("Jumuah prayer consists of a sermon (**Khutbah - خُطبَة**) followed by a two-rak’ah Salah led by the Imam. It is obligatory for Muslim men who can attend, though it is not obligatory for women.")
                        .font(.body)

                    Text("If Jumuah is missed at the mosque, one performs the full Dhuhr prayer (4 rak’ahs).")
                        .font(.body)
                }

                Section(header: Text("IMPORTANCE")) {
                    Text("The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(text: "“The best day on which the sun has risen is Friday; on it Adam was created, on it he was admitted to Paradise, and on it he was expelled therefrom” (Sahih Muslim 854).", dimmed: true)

                    Text("Friday is considered the best day of the week in Islam. It unites the community, strengthens social bonds, and serves as a weekly reminder of our responsibilities toward Allah (Glorified and Exalted be He) and humanity.")
                        .font(.body)
                }

                Section(header: Text("RECOMMENDED PRACTICES")) {
                    Text("Muslims are encouraged to engage in specific acts of worship on Jumuah:")
                        .font(.body)

                    Text("1. **Reciting Surah Al-Kahf (سُورَة ٱلكَهف):** The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    Text("“Whoever reads Surah Al-Kahf on Friday will have a light between this Friday and the next” (Mishkat al-Masabih 2175).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("2. **Sending Salawat on the Prophet (peace and blessings be upon him):**")
                        .font(.body)

                    ScriptureQuote(text: "“Increase your supplications for me on the day and night of Friday. Whoever blesses me once, Allah will bless him ten times” (al-Sunan al-Kubra lil-Bayhaqi 5994).", dimmed: true)

                    Text("3. **Making Dua (Supplication)**: There is a special hour on Friday during which all supplications are accepted. The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(text: "“Friday is twelve hours in which there is no Muslim slave who asks Allah for something but He will give it to him, so seek it in the last hour after Asr” (Sunan an-Nasa'i 1389).", dimmed: true)
                }

                Section(header: Text("ETIQUETTE")) {
                    Text("Observing proper etiquette during Jumuah is essential:")
                        .font(.body)

                    Text("1. Arrive early to the mosque and sit attentively during the Khutbah.")
                        .font(.body)

                    Text("2. Wear clean and modest clothing as Friday is a day of significance.")
                        .font(.body)

                    Text("3. Avoid distractions, such as using phones, during the sermon.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Friday is the best day of the week: a weekly gathering for remembrance, with special reward in reciting Surah al-Kahf and sending salawat upon the Prophet.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Pray Jumuah", subtitle: "The Friday prayer and its khutbah, IslamQA", url: "https://islamqa.info/en/categories/topics/85/jumuah-prayer"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Jumuah")
    }
}

struct AdhanOtherView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Adhan is the melodious call announcing each of the five daily prayers, first given in Madinah and famously called by Bilal ibn Rabah.")
                        .font(.body)
                }

                Section(header: Text("HISTORY")) {
                    Text("The Adhan (أَذَان) is the Islamic call to prayer, from the root **a-dh-n (أ ذ ن)** meaning to announce or proclaim.")
                        .font(.body)

                    Text("It is recited in Arabic to announce the time for each of the five daily prayers.")
                        .font(.body)

                    Text("The Adhan originated during the time of Prophet Muhammad (peace and blessings be upon him) in Madinah.")
                        .font(.body)

                    Text("The method of calling to prayer was revealed through the dream of Abdullah ibn Zaid (may Allah be pleased with him), and the Prophet (peace and blessings be upon him) chose Bilal ibn Rabah (may Allah be pleased with him) to deliver it because of his melodious and powerful voice.")
                        .font(.body)
                }

                Section(header: Text("WORDS OF THE ADHAN")) {
                    Text("""
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
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("""
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

                    Text("""
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

                Section(header: Text("ONLY FOR FAJR")) {
                    Text("**ONLY FOR FAJR:** the following line is added, and it is said in no other Adhan. It comes after “Hayya ala al-falah“ and before the closing takbir.")
                        .font(.body)

                    Text("**ONLY FOR FAJR:**")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("الصَّلَاةُ خَيرٌ مِنَ النَّومِ")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("As-salatu khayrun mina-nawm\n(Prayer is better than sleep)")
                        .font(.body)

                    Text("This line is said twice, and only in the Adhan for Fajr. It is never said in the Adhan for Dhuhr, Asr, Maghrib, or Isha, and it is never said in the Iqamah.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Its words proclaim the greatness and oneness of Allah and the messengership of Muhammad, calling the believers to prayer and to success.")
                        .font(.body)
                }

                Section(header: Text("THE VIRTUE OF THE ADHAN")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, when [the adhan] is called for the prayer on the day of Jumuah, then proceed to the remembrance of Allah and leave trade” (Quran 62:9).")
                    Text("The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“If the people knew what there is in the call to prayer and the first row, and they could find no other way than to draw lots, they would draw lots for it” (Sahih al-Bukhari 615).", dimmed: true)
                    ScriptureQuote(text: "“When the call to prayer is made, Satan takes to his heels and passes wind with noise so as not to hear the call” (Sahih al-Bukhari 608).", dimmed: true)
                    Text("Answer the muadhin. He said: “When you hear the muadhin, say the like of what he says” (Sahih Muslim 383). Except at “Hayya ala as-salah“ and “Hayya ala al-falah,“ where you say “La hawla wa la quwwata illa billah“ (Sahih Muslim 385).")
                        .font(.body)
                    Text("Then send blessings on the Prophet (peace and blessings be upon him), and say:")
                        .font(.body)
                    ScriptureQuote(text: "“Allahumma Rabba hadhihi ad-dawati at-tammah, was-salatil-qa'imah, ati Muhammadan al-wasilata wal-fadilah, wab'ath-hu maqaman mahmudan alladhi wa'adtah“ - whoever says this after the adhan, my intercession will be permitted for him on the Day of Resurrection (Sahih al-Bukhari 614).", dimmed: true)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Give the Adhan and Iqamah", subtitle: "The wording and its rulings, IslamQA", url: "https://islamqa.info/en/categories/topics/70/adhan-and-iqamah"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Adhan")
    }
}

struct IqamahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Iqamah is the second, shorter call given just before the congregation stands, signaling that the prayer is about to begin.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The Iqamah (إِقَامَة) - from the root **q-w-m (ق و م)**, to stand or establish - is the second call to prayer, given right before the congregational Salah begins.")
                        .font(.body)

                    Text("It is generally shorter than the Adhan and serves as a prompt for the congregation to stand and line up for prayer.")
                        .font(.body)

                    Text("Often, the same **Mu'adhin (مُؤَذِّن)** (caller) who delivered the Adhan will also deliver the Iqamah, but it can be done by someone else.")
                        .font(.body)
                }

                Section(header: Text("WORDS OF THE IQAMAH")) {
                    Text("""
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
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("""
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

                    Text("""
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

                Section(header: Text("IN SUMMARY")) {
                    Text("Where the Adhan calls the community to gather, the Iqamah announces that the prayer has been established and the rows are to be formed.")
                        .font(.body)
                }

                Section(header: Text("AFTER THE IQAMAH")) {
                    Text("The Iqamah is said in single phrases, unlike the Adhan, which is said in pairs. Anas (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Bilal was ordered to say the words of the adhan twice and the words of the iqamah once” (Sahih al-Bukhari 605, Sahih Muslim 378).", dimmed: true)
                    Text("Once the Iqamah is called, no other prayer is begun. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“When the iqamah for the prayer has been called, then there is no prayer except the obligatory one” (Sahih Muslim 710).", dimmed: true)
                    Text("And straighten the rows before the imam begins:")
                        .font(.body)
                    ScriptureQuote(text: "“Straighten your rows, for straightening the rows is part of the perfection of the prayer” (Sahih al-Bukhari 723, Sahih Muslim 433).", dimmed: true)
                    Text("Walk to the prayer calmly. He said: “When the iqamah is called, do not come to it running. Come to it walking, with tranquillity. Whatever you catch, pray, and whatever you miss, complete it” (Sahih al-Bukhari 636, Sahih Muslim 602).")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Give the Iqamah", subtitle: "Its wording and its rulings, IslamQA", url: "https://islamqa.info/en/categories/topics/70/adhan-and-iqamah"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Iqamah")
    }
}

struct TakbiratView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Eid prayer is two rak'ah with extra takbirs, prayed in congregation after sunrise with no Adhan and no Iqamah, followed by the khutbah.")
                        .font(.body)
                }

                Section(header: Text("BEFORE YOU GO")) {
                    Text("1. Perform **ghusl (غُسل)**, wear your best clothes, and apply perfume (for men).")
                        .font(.body)
                    Text("2. For **Eid al-Fitr**, eat an odd number of dates before leaving. For **Eid al-Adha**, do not eat until after the prayer, so that the first thing you eat is from the sacrifice.")
                        .font(.body)
                    Text("3. Pay **Zakat al-Fitr** before the prayer (Eid al-Fitr only). If it is paid after the prayer, it counts as ordinary charity, not as Zakat al-Fitr.")
                        .font(.body)
                    Text("4. Say the Takbir on the way, out loud (see below).")
                        .font(.body)
                    Text("5. Go out to the **musalla (مُصَلَّى)**, the open prayer ground, which is the Sunnah, and take the women and children with you. Go by one route and return by another, as the Prophet (peace and blessings be upon him) did (Sahih al-Bukhari 986).")
                        .font(.body)
                }

                Section(header: Text("THE TIME OF THE PRAYER")) {
                    Text("The Eid prayer begins after the sun has fully risen, roughly 15 to 20 minutes after sunrise, and its time lasts until just before the sun reaches its zenith (before Dhuhr).")
                        .font(.body)
                    Text("**Eid al-Adha** is prayed early, so people can go and sacrifice. **Eid al-Fitr** is prayed a little later, so people have time to give Zakat al-Fitr.")
                        .font(.body)
                }

                Section(header: Text("HOW TO PRAY EID")) {
                    Text("There is **no Adhan and no Iqamah** for the Eid prayer, and no call of any kind. It is simply begun.")
                        .font(.body)

                    Text("It is **two rak'ah**, prayed in congregation behind the imam, and the recitation is out loud.")
                        .font(.body)

                    Text("**First rak'ah:**")
                        .font(.body)
                    Text("1. Make the intention in the heart, then the opening takbir, **Takbirat al-Ihram (تَكبِيرَة الإِحرَام)**, raising the hands.")
                        .font(.body)
                    Text("2. Say the opening supplication (**du'a al-istiftah**).")
                        .font(.body)
                    Text("3. Say **seven takbirs** in total in this rak'ah before the recitation, raising the hands with each. (Scholars differ over whether the opening takbir is counted as one of the seven; both are practised and the prayer is valid either way. Do not argue over it.)")
                        .font(.body)
                    Text("4. Then say the ta'awwudh and recite **al-Fatihah**, followed by a surah. From the Sunnah: **Surah al-A'la (87)** in the first rak'ah and **al-Ghashiyah (88)** in the second, or **Qaf (50)** and **al-Qamar (54)**.")
                        .font(.body)
                    Text("5. Then complete the rak'ah as normal: ruku', standing, and two prostrations.")
                        .font(.body)

                    Text("**Second rak'ah:**")
                        .font(.body)
                    Text("6. Stand, and before reciting, say **five takbirs**, raising the hands with each. These are apart from the takbir you said when standing up from prostration.")
                        .font(.body)
                    Text("7. Recite al-Fatihah and a surah, then complete the rak'ah, sit for the tashahhud, and give the salaam.")
                        .font(.body)

                    Text("There is **no nafl prayer** before or after the Eid prayer at the musalla.")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) is reported to have said:")
                        .font(.body)
                    ScriptureQuote(text: "“The takbir in Fitr and Adha is seven in the first rak'ah and five in the second, apart from the two takbirs of ruku'” (Sunan Abi Dawud 1151).", dimmed: true)

                    Text("If you miss a takbir, or the imam has already begun, join him where he is and do not try to make up the extra takbirs. They are a Sunnah, not a pillar, and forgetting them does not invalidate the prayer or require the prostration of forgetfulness.")
                        .font(.body)
                }

                Section(header: Text("AFTER THE PRAYER: THE KHUTBAH")) {
                    Text("The khutbah comes **after** the Eid prayer, unlike Jumuah, where it comes before.")
                        .font(.body)
                    Text("Staying for it is strongly recommended, though it is not obligatory, and one who leaves has not sinned.")
                        .font(.body)
                    Text("If you missed the congregation entirely, you may pray two rak'ah on your own.")
                        .font(.body)
                    Text("Greet one another with **“Taqabbal Allahu minna wa minkum“ (تَقَبَّلَ اللهُ مِنَّا وَمِنكُم)**, “May Allah accept it from us and from you.“ This was the greeting of the Companions.")
                        .font(.body)
                }

                Section(header: Text("EID OCCASIONS")) {
                    Text("In Islam, there are two major annual celebrations known as Eid:")
                        .font(.body)

                    Text("1. **Eid al-Fitr (عيد الفطر):** Celebrated at the end of Ramadan (the month of fasting). It is a time of joy, gratitude to Allah (Glorified and Exalted be He), and giving to the needy (Zakat al-Fitr).")
                        .font(.body)

                    Text("2. **Eid al-Adha (عيد الأضحى):** Celebrated on the 10th day of Dhu al-Hijjah. It commemorates the willingness of Prophet Ibrahim (peace be upon him) to sacrifice his son Isma'il (peace be upon him). Muslims who are able to do so perform the sacrifice (Qurbani) and distribute the meat to the poor. This Eid coincides with Hajj, the annual pilgrimage to Makkah.")
                        .font(.body)
                }

                Section(header: Text("TAKBIRAT AL-EID")) {
                    Text("The Takbirat al-Eid is a special proclamation of Allah’s greatness, recited during the days of Eid.")
                        .font(.body)

                    Text("For Eid al-Fitr, it begins after the new moon confirming the end of Ramadan and continues until the Eid prayer. For Eid al-Adha, it begins after Arafah Day (9th of Dhu al-Hijjah) and continues until the Eid prayer.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“And [He wants] for you to complete the period and to glorify Allah for that [to] which He has guided you; and perhaps you will be grateful” (Quran 2:185).")
                }

                Section(header: Text("SHORT TAKBIRAT")) {
                    Text("This is the short version of the Takbir:")
                        .font(.body)

                    Text("الله أكبر الله أكبر لا إله إلا الله، والله أكبر الله أكبر ولله الحمد")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("Allahu Akbar, Allahu Akbar, La Ilaha Illa Allah, Allahu Akbar, Allahu Akbar, wa lillahil hamd")
                        .font(.body)

                    Text("Allah is the Greatest, Allah is the Greatest. There is no deity but Allah. Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.")
                        .font(.body)
                }

                Section(header: Text("LONGER TAKBIRAT")) {
                    Text("""
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ، لَا إِلَهَ إِلَّا اللَّهُ

                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ، وَلِلَّهِ الحَمدُ

                    اللَّهُ أَكبَرُ كَبِيرًا، وَالحَمدُ لِلَّهِ كَثِيرًا، وَسُبحَانَ اللَّهِ بُكرَةً وَأَصِيلًا

                    لَا إِلَهَ إِلَّا اللَّهُ وَحدَهُ، صَدَقَ وَعدَهُ، وَنَصَرَ عَبدَهُ، وَأَعَزَّ جُندَهُ، وَهَزَمَ الأَحزَابَ وَحدَهُ

                    لَا إِلَهَ إِلَّا اللَّهُ، وَلَا نَعبُدُ إِلَّا إِيَّاهُ، مُخلِصِينَ لَهُ الدِّينَ وَلَو كَرِهَ الكَافِرُونَ

                    اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ، وَعَلَى آلِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَصحَابِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَنصَارِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَزوَاجِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى ذُرِّيَّةِ سَيِّدِنَا مُحَمَّدٍ، وَسَلِّم تَسلِيمًا كَثِيرًا
                    """)
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("""
                    Allahu Akbar, Allahu Akbar, Allahu Akbar, La ilaha illa Allah

                    Allahu Akbar, Allahu Akbar, wa Lillahil Hamd

                    Allahu Akbar Kabira, wal Hamdu Lillahi Kathira, wa Subhan Allahi bukratan wa asila

                    La ilaha illa Allahu Wahdah, sadaqa wa’dah, wa nasara abdah, wa a’azza jundahu wa hazama al-Ahzaba wahdah

                    La ilaha illa Allah, wa la na’budu illa iyyah, mukhliseena lahud-deen, walaw karihal kafirun

                    Allahumma salli ‘ala Sayyidina Muhammad, wa ‘ala ali Sayyidina Muhammad, wa ‘ala ashabi Sayyidina Muhammad, wa ‘ala ansari Sayyidina Muhammad, wa ‘ala azwaji Sayyidina Muhammad, wa ‘ala dhurriyyati Sayyidina Muhammad, wa sallim tasliman kathira
                    """)
                    .font(.body)

                    Text("""
                    “Allah is the Greatest, Allah is the Greatest, Allah is the Greatest; There is no deity but Allah.
                    Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.

                    Allah is the Greatest in greatness; much praise be to Allah; and Glory be to Allah in the morning and evening.
                    There is no deity but Allah alone. He fulfilled His promise, granted victory to His servant, and honored His army, and He alone defeated the confederates.

                    There is no deity but Allah; we do not worship anyone but Him, being sincere in faith and devotion to Him, even if the disbelievers dislike it.
                    O Allah, send Your blessings on our master Muhammad, and on the family of our master Muhammad, on the companions of our master Muhammad, on the supporters of our master Muhammad, on the wives of our master Muhammad, and on the descendants of our master Muhammad, and bestow upon them abundant peace.”
                    """)
                    .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("By glorifying Allah on the days of Eid, Muslims complete their worship with gratitude - after Ramadan for Eid al-Fitr, and around the days of Hajj for Eid al-Adha.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Pray Eid", subtitle: "The Eid prayer and its takbirs, IslamQA", url: "https://islamqa.info/en/answers/48983"),
                    (title: "The Eid Takbir", subtitle: "Its wording and when it is said, IslamQA", url: "https://islamqa.info/en/answers/36491"),
                ])
            }
            .themedListRowBackground()
        }
        .navigationTitle("How to Pray Eid")
        .applyConditionalListStyle()
    }
}

struct HijriCalendarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Hijri calendar is the Islamic lunar calendar of twelve months, dated from the Prophet's migration (Hijrah) to Madinah in 622 CE.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The Hijri calendar, also known as the Islamic or Lunar Hijri calendar, consists of 12 lunar months in a year of 354 or 355 days.")
                        .font(.body)

                    Text("It is used to determine key Islamic dates such as Ramadan, Hajj, and the two Eid festivals. The reference point (epoch) of the calendar is the Hijrah - the migration of Prophet Muhammad (peace and blessings be upon him) from Makkah to Madinah in 622 CE.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“Indeed, the number of months with Allah is twelve [lunar] months in the register of Allah [from] the day He created the heavens and the earth; of these, four are sacred” (Quran 9:36).")
                }

                Section(header: Text("DETAILS")) {
                    Text("""
                         Each Hijri month begins with the sighting of the new moon. The 12 months are as follows:
                         1. **Muharram (مُحَرَّم)** – One of the sacred months
                         2. **Safar (صَفَر)** 
                         3. **Rabi al-Awwal (رَبِيع ٱلأَوَّل)**
                         4. **Rabi al-Thani (رَبِيع ٱلثَّانِي)** 
                         5. **Jumada al-Awwal (جُمَادَىٰ ٱلأَوَّل)** 
                         6. **Jumada al-Thani (جُمَادَىٰ ٱلثَّانِي)** 
                         7. **Rajab (رَجَب)** – A sacred month
                         8. **Shaaban (شَعبَان)** – The month preceding Ramadan
                         9. **Ramadan (رَمَضَان)** – The month of fasting
                         10. **Shawwal (شَوَّال)** – The month following Ramadan
                         11. **Dhul-Qadah (ذُو ٱلقَعدَة)** – A sacred month
                         12. **Dhul-Hijjah (ذُو ٱلحِجَّة)** – A sacred month, the month of Hajj and Eid al-Adha
                         """)
                    .font(.body)

                    Text("A Hijri year is approximately 11 days shorter than a Gregorian year, causing Islamic events to shift earlier each Gregorian year. Muslims worldwide use this calendar for religious observances, including fasting in Ramadan, undertaking Hajj, and celebrating Eid al-Fitr and Eid al-Adha.")
                        .font(.body)
                }

                Section(header: Text("SACRED MONTHS")) {
                    Text("Four of the Hijri months are considered sacred: **Muharram**, **Rajab**, **Dhul-Qadah**, and **Dhul-Hijjah**.")
                        .font(.body)

                    Text("These months are distinguished by their sanctity and prohibition of warfare, emphasizing peace and reflection.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“Indeed, the number of months with Allah is twelve... of these, four are sacred. That is the correct religion, so do not wrong yourselves during them” (Quran 9:36).")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("About eleven days shorter than the solar year, it sets the timing of Ramadan, Hajj, and the two Eids, and marks the four sacred months.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Hijri Calendar")
        .applyConditionalListStyle()
    }
}

struct CompileView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Quran was preserved from the start by mass memorization and careful writing, gathered into one volume under Abu Bakr, and standardized under Uthman.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("From the first revelation, the Quran was preserved by the Companions through precise memorization (hifdh) and careful writing on parchments, leather, bones, and leaves. Prophet Muhammad (peace and blessings be upon him) had official scribes (including Zayd ibn Thabit) who wrote verses as they were revealed.")
                        .font(.body)

                    Text("Every year in Ramadan, Jibril (Gabriel) reviewed the Quran with Prophet Muhammad (peace and blessings be upon him); in the final year this review occurred twice (al-Ardah al-Akhirah). Prophet Muhammad (peace and blessings be upon him) taught the Companions the exact wording, pronunciation, and the order in which the surahs and ayat should be recited.")
                        .font(.body)
                }

                Section(header: Text("ALLAH’S PROMISE OF PRESERVATION")) {
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian.” (Quran 15:9)")

                    ScriptureQuote(text: "“Move not your tongue with it to hasten it. Indeed, upon Us is its collection and its recitation. So when We have recited it, then follow its recitation. Then upon Us is its clarification.” (Quran 75:16–19)")

                    ScriptureQuote(text: "“And recite the Quran with measured recitation.” (Quran 73:4)")

                    ScriptureQuote(text: "“And [it is] a Qur'an which We have separated [by intervals] that you might recite it to the people over a prolonged period. And We have sent it down progressively.” (Quran 17:106)")
                }

                Section(header: Text("DURING THE PROPHET’S LIFETIME ﷺ")) {
                    Text("• Memorization first: Many Companions memorized the Quran word-for-word and reviewed it with Prophet Muhammad (peace and blessings be upon him) in prayer and lessons.")
                        .font(.body)
                    Text("• Official scribes: Verses were dictated to scribes such as Zayd ibn Thabit, Ubayy ibn Ka‘b, and others, and kept as written fragments verified by Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                    Text("• Annual review: Jibril reviewed the entire Quran with Prophet Muhammad (peace and blessings be upon him) yearly in Ramadan; in the final year, the review occurred twice, confirming wording and order.")
                        .font(.body)
                }

                Section(header: Text("FIRST COMPILATION UNDER ABU BAKR")) {
                    Text("After the Battle of Yamamah, many memorizers were martyred. About one year after the Prophet’s death (12 AH), at the counsel of Umar ibn al-Khattab, Caliph Abu Bakr commissioned Zayd ibn Thabit to collect the Quran into one compiled manuscript.")
                        .font(.body)

                    Text("Zayd gathered the Quran from written materials and from those who had memorized it, accepting verses only when corroborated by multiple reliable witnesses and his own memorization, all according to what had been reviewed with Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text("This compiled mushaf was kept with Abu Bakr, then with Umar, and after Umar with Hafsah bint Umar (may Allah be pleased with them).")
                        .font(.body)
                }

                Section(header: Text("STANDARDIZATION UNDER UTHMAN")) {
                    Text("As Islam spread, differences in regional reading threatened dispute. Caliph Uthman ibn Affan formed a committee led by Zayd ibn Thabit with senior Qurayshi scholars to produce standardized copies based on the Abu Bakr compilation and the established Uthmanic rasm (consonantal skeleton) that could accommodate the revealed modes.")
                        .font(.body)

                    Text("Uthman sent official copies to major centers (e.g., Kufa, Basra, Sham) and asked that non-verified personal materials be retired to prevent confusion between private notes/duas and the Quranic text. The Companions agreed with this measure, preserving unity upon the authenticated text.")
                        .font(.body)

                    Text("This standardization did not remove revelation; rather, it unified the community upon the verified mushaf that preserved what remained from the seven Ahruf in the Uthmanic rasm and ensured consistent public recitation.")
                        .font(.body)
                }

                Section(header: Text("CONSENSUS OF THE COMPANIONS")) {
                    Text("The Companions - foremost memorizers and teachers - were unanimous in accepting the compilation and the Uthmanic copies. It is widely reported that Abu Bakr, Umar, Uthman, and Ali were among the foremost memorizers and teachers of the Quran, and none objected to the standardized mushaf.")
                        .font(.body)

                    Text("Zayd ibn Thabit led the technical work in both Abu Bakr’s and Uthman’s projects, bringing rigorous verification. Senior scholars, including Quraysh experts, reviewed and approved the copies.")
                        .font(.body)
                }

                Section(header: Text("THE FOUR MASTERS & LEADING TRANSMITTERS")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) said: “Take the Quran from four: Abdullah ibn Masud, Salim (the freed slave of Abu Hudhayfah), Ubayy ibn Ka‘b, and Mu‘adh ibn Jabal.” (Sahih al-Bukhari)")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("These masters, together with others like Zayd ibn Thabit, were key references for wording, recitation, and teaching, anchoring transmission among the Companions and their students.")
                        .font(.body)
                }

                Section(header: Text("AHRUF, QIRAAT, AND THE UTHMANIC RASM")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) taught that the Quran was revealed in seven Ahruf (modes) for ease. The Quran was first compiled into one manuscript under Abu Bakr (may Allah be pleased with him), around one year after the Prophet’s death. Later, the Uthmanic rasm allowed what remained of those modes to be read and transmitted through canonical Qiraat verified by chains. The 10 Qiraat (with their 20 Riwayaat) are mutawatir and reflect how the prophetic recitation was preserved in writing and oral teaching.")
                        .font(.body)

                    Text("Thus, standardization did not limit revelation; it safeguarded it - preventing private notes and unverified materials from being mistaken for the Quran - while preserving the legitimate readings taught by Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: Text("KEY REPORTS (BRIEF)")) {
                    Text("• 7 Ahruf: “The Quran was revealed in seven Ahruf, so recite whichever is easiest for you.” (Sahih al-Bukhari; Sahih Muslim)")
                        .font(.body)
                    Text("• Double review in final Ramadan (al-Ardah al-Akhirah): reported in authentic narrations.")
                        .font(.body)
                    Text("• Abu Bakr’s compilation via Zayd after Yamamah: authentic reports in Sahih collections.")
                        .font(.body)
                    Text("• Uthman’s committee (with Zayd) and distribution of official copies: authentic reports in Sahih collections.")
                        .font(.body)
                }

                Section(header: Text("MANUSCRIPT EVIDENCE (HISTORICAL NOTES)")) {
                    Text("Early Quranic manuscripts discovered in different regions (e.g., Hijaz, Yemen, Syria, North Africa, Anatolia) reflect the early Uthmanic rasm and align with the text recited today.")
                        .font(.body)

                    Text("Examples often cited by historians include: the Birmingham fragments (radiocarbon dated to the earliest period of Islam), folios from Sana’a (including palimpsests showing early layers of writing), and early codices associated with major centers and later libraries (e.g., Topkapi).")
                        .font(.body)

                    Text("While scholarly studies analyze paleography, orthography, and dating techniques, the consonantal text aligns with the standardized Uthmanic tradition, and the Quran remains read globally in the same wording preserved by the Ummah.")
                        .font(.body)
                }

                Section(header: Text("WHY WERE PRIVATE MATERIALS RETIRED?")) {
                    Text("Some Companions wrote personal notes - duas, explanations, or hadith - near Quranic passages. To prevent confusion between private annotations and the Quran, and to avoid unchecked variants, Uthman ordered that only the verified official copies be used for public recitation and that other materials be retired.")
                        .font(.body)

                    Text("No Companion rejected the standardized mushaf. The community recited, taught, and transmitted the same Quran by memorization and writing through every generation.")
                        .font(.body)
                }

                Section(header: Text("CONTINUITY UNTIL TODAY")) {
                    Text("The Quran we hold today is the same revelation taught by Prophet Muhammad (peace and blessings be upon him), preserved through the consensus of the Companions, the Uthmanic rasm, the living tradition of memorization, and the mutawatir Qiraat. Around the world, millions memorize the entire Quran - letter for letter - continuing an unbroken chain of transmission.")
                        .font(.body)

                    Text("Public recitation, prayer, and education remain bound to the verified text. The Ummah’s practice fulfills Allah's (Glorified and Exalted be He) promise: its preservation is both textual and living.")
                        .font(.body)
                }

                Section(header: Text("SELECT VERSES & REMINDERS")) {
                    ScriptureQuote(text: "“And when the Quran is recited, then listen to it and pay attention that you may receive mercy.” (Quran 7:204)")

                    ScriptureQuote(text: "“Do they not reflect upon the Quran? If it had been from other than Allah (Glorified and Exalted be He), they would have found within it much contradiction.” (Quran 4:82)")

                    ScriptureQuote(text: "“Falsehood cannot approach it from before it or from behind it; [it is] a revelation from One All-Wise, Praiseworthy.” (Quran 41:42)")
                }

                Section(header: Text("USEFUL LINKS")) {
                    Text("Learn More about the Compilation of the Quran: https://www.youtube.com/watch?v=n281Zyywyn4&t=343s")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Through unbroken memorization and a verified written text, the Quran remains today exactly as it was revealed - fulfilling Allah's promise to preserve it.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Compilation of the Quran")
        .applyConditionalListStyle()
    }
}

struct TajweedView: View {
    @ObservedObject var settings = Settings.shared
    @State private var showTajweedLegend = false

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Tajweed is the science of reciting the Quran correctly - giving each letter its proper articulation and every rule its due.")
                        .font(.body)
                }

                Section(header: Text("TAJWEED LEGEND")) {
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

                Section(header: Text("OVERVIEW")) {
                    Text("Tajweed (تَجوِيد) means “to make well, beautify, or improve,” from the root **j-w-d (ج و د)**. In the context of the Quran, it refers to the set of rules for proper pronunciation during Quran recitation, ensuring each letter is articulated with precision.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“And recite the Quran with measured recitation” (Quran 73:4).")
                }

                Section(header: Text("IMPORTANCE")) {
                    Text("Tajweed ensures the Quran is recited in the most accurate and beautiful way possible, exactly as it was revealed to the Prophet ﷺ. Reciting with Tajweed is not just about making recitation sound pleasant - it is about preserving the integrity of the Quran itself.")
                        .font(.body)

                    Text("The Quran was revealed in Arabic, and every word, letter, and sound has a specific meaning and weight. A slight mispronunciation could change the meaning of a verse. Tajweed helps safeguard against these errors and honors the sacred text with the care and precision it deserves.")
                        .font(.body)

                    Text("Many Muslims find that reciting the Quran with Tajweed enhances their spiritual experience. The attention to detail required for proper recitation encourages mindfulness and deeper reflection on the meaning of the verses, making the recitation feel more immersive and meaningful.")
                        .font(.body)
                }

                Section(header: Text("WHY LEARN TAJWEED?")) {
                    Text("Honoring the Quran: The Quran is the final revelation from Allah. Reciting it with care and precision is a form of respect and reverence for the sacred text.")
                        .font(.body)

                    Text("Preventing Misunderstandings: By applying Tajweed rules, you avoid mistakes that may alter the meaning of verses. Even changing a single sound can result in an entirely different meaning.")
                        .font(.body)

                    Text("Enhancing Spiritual Connection: Proper recitation encourages mindfulness and deeper reflection on the meaning of the verses, making your connection with the Quran more meaningful.")
                        .font(.body)

                    Text("Following the Sunnah: The Prophet Muhammad ﷺ emphasized the importance of reciting the Quran correctly. By learning Tajweed, you follow his example and teachings.")
                        .font(.body)
                }

                Section(header: Text("GETTING STARTED")) {
                    Text("Learning Tajweed might seem intimidating at first, but understanding its importance can make the journey more meaningful. The best way to start is with a qualified teacher who can guide you through the articulation points and characteristics of each letter. Today, there are also online platforms, videos, and books that provide step-by-step lessons.")
                        .font(.body)

                    Text("Focus on mastering the basic rules first, then gradually build your skills over time. Practicing consistently and recording your recitation can help you catch mistakes and improve pronunciation.")
                        .font(.body)
                }

                Section(header: Text("FOR MORE DETAILS")) {
                    NavigationLink(destination: LazyDestination { TajweedFoundationsView() }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tajweed Foundations")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(settings.accentColor.color)
                            Text("Comprehensive guide with rules, topics, and detailed explanations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("RESOURCES")) {
                    Text("Watch Learn Arabic 101: https://www.youtube.com/@Arabic101")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Reciting with Tajweed preserves the Quran's pronunciation as it was received from the Prophet, and beautifies and safeguards its meaning.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tajweed")
        .applyConditionalListStyle()
        #if os(iOS)
        .sheet(isPresented: $showTajweedLegend) {
            NavigationView {
                TajweedLegendView()
            }
            .smallMediumSheetPresentation()
        }
        #endif
    }
}

struct JuzView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Quran is divided into thirty roughly equal parts called Juz, making it easy to read over a month - especially in Ramadan.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The Quran is divided into 114 Surahs (chapters), but it is also split into thirty roughly equal parts, called Juz (plural: Ajza).")
                        .font(.body)

                    Text("This division helps Muslims complete the Quran’s recitation systematically, often one Juz per day, especially during Ramadan.")
                        .font(.body)
                }

                Section(header: Text("PURPOSE")) {
                    Text("The division into Juz is primarily for convenience rather than thematic arrangement. It enables systematic daily recitation.")
                        .font(.body)

                    Text("Many Muslims strive to complete the Quran in Ramadan, reciting one Juz per night in Taraweeh prayers. Each Juz is further divided into two Hizbs, making a total of 60 Hizbs.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“So when the Quran is recited, then listen to it and pay attention that you may receive mercy” (Quran 7:204).")
                }

                Section(header: Text("HISTORICAL NOTES")) {
                    Text("While the Quran's content remained unchanged since its revelation, the formal division into 30 Juz was standardized later to facilitate ease of recitation.")
                        .font(.body)

                    Text("This structure fosters a daily relationship with the Quran and encourages reflection on its meanings.")
                        .font(.body)

                    Text("Prophet Muhammad (peace and blessings be upon him) emphasized balanced recitation, saying:")
                        .font(.body)

                    ScriptureQuote(text: "“He who recites the Quran in less than three days does not grasp its meaning” (Sunan Abu Dawud 1394).", dimmed: true)
                }

                // Each Juz is named for the word it opens with, and that name is Arabic. Listing them by number
                // alone (which is all this screen used to do) leaves out the thing they are actually called.
                Section(header: Text("THE THIRTY JUZ")) {
                    ForEach(QuranData.juzList) { juz in
                        HStack(spacing: 12) {
                            Text("\(juz.id)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundColor(settings.accentColor.color)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle().fill(settings.accentColor.color.opacity(0.15))
                                )

                            Text(juz.nameTransliteration)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Spacer(minLength: 8)

                            Text(juz.nameArabic)
                                .font(
                                    settings.islamUsesCustomArabicFace
                                        ? Font.arabic(settings.fontArabic, size: 20, relativeTo: .subheadline)
                                        : .title3
                                )
                                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                .foregroundColor(settings.accentColor.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The thirty Juz are a practical division for reading and memorization, not part of the revelation's meaning, helping Muslims complete the Quran regularly.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Thirty Juz")
        .applyConditionalListStyle()
    }
}

struct AhrufView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Quran was revealed in seven ahruf - modes of recitation - as a mercy easing its recitation for the different Arab tribes.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحرُف) - the plural of Harf (حَرف). The word Harf comes from the Arabic root H–r–f (ح ر ف), meaning “edge, border, side, or angle,” referring to a particular “way” or “mode.” Islamically and Quranically, Ahruf refers to the divinely revealed modes of recitation.")
                        .font(.body)

                    Text("A Harf (حَرف) - literally meaning “edge/side/aspect,” and in this context “a mode/way of reciting” - refers to a divinely revealed manner of recitation that includes slight differences in pronunciation, vowel patterns, pausing/connection, or permitted word-forms, while preserving the exact same meaning and guidance.")
                        .font(.body)

                    Text("All seven Ahruf are revelation from Allah (Glorified and Exalted be He). They are not scholarly opinions nor later inventions - they are part of the Quran that Allah (Glorified and Exalted be He) sent down to Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: Text("WHY SEVEN AHRUF?")) {
                    Text("The Arabs at the time of revelation had many dialects (Quraysh, Hudhayl, Tamim, Hawazin, etc.). Allah (Glorified and Exalted be He), in His mercy, revealed the Quran in seven modes so that every tribe could recite the Quran easily without difficulty or burden.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) did not reveal seven different Qurans - rather, one Quran with divinely allowed flexibility, making memorization and recitation easier.")
                        .font(.body)
                }

                Section(header: Text("PROPHETIC HADITH ON THE SEVEN AHRUF")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(text: "“The Quran was revealed in seven Ahruf, so recite whichever is easiest for you.”\n- Sahih al-Bukhari • Sahih Muslim", dimmed: true)

                    Text("Another narration explains how Jibril kept requesting ease for the Ummah:")
                        .font(.body)

                    ScriptureQuote(text: "“Jibril recited to me in one harf. I asked him to increase it… until he ended with seven Ahruf.”\n- Sahih Muslim", dimmed: true)

                    Text("In the famous incident of Umar and Hisham ibn Hakim - both of them recited differently, and Prophet Muhammad (peace and blessings be upon him) said that both were revealed, proving that the variations are not mistakes but revelation.")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("DO THE AHRUF AFFECT PRESERVATION?")) {
                    Text("No. The Quran remains perfectly preserved - letter for letter, word for word, in every revealed mode. The Ahruf are part of that preservation, not a contradiction to it.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) promised:")
                        .font(.body)

                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian.” (Quran 15:9)")

                    Text("The variations in Ahruf do not alter meanings, beliefs, or rulings. Rather, they highlight precision and perfection - the Ummah memorized and transmitted every letter exactly as revealed.")
                        .font(.body)

                    Text("Each harf is revealed, preserved, and protected by Allah (Glorified and Exalted be He). Muslims do not choose or invent a harf - we only recite what Allah (Glorified and Exalted be He) revealed through His Messenger, Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: Text("HOW AHRUF WERE PRESERVED")) {
                    Text("• Prophet Muhammad (peace and blessings be upon him) taught the Companions each harf personally.\n• Jibril reviewed the Quran with Prophet Muhammad (peace and blessings be upon him) every year in Ramadan.\n• In the year Prophet Muhammad (peace and blessings be upon him) passed away, Jibril reviewed it twice (al-Ardah al-Akhirah).")
                        .font(.body)

                    Text("About one year after the Prophet’s passing, Abu Bakr (may Allah be pleased with him) commissioned the first complete compilation of the Quran into one manuscript. During the caliphate of Uthman (may Allah be pleased with him), the Ummah was then unified upon official copies from that preserved compilation, written in the Uthmanic rasm, which preserved what the Ummah recited - containing what remained from the seven Ahruf in the rasm.")
                        .font(.body)

                    Text("The Ahruf are preserved through oral transmission, ijazahs, and chains of narration (isnad).")
                        .font(.body)
                }

                Section(header: Text("WHAT ABOUT THE 10 QIRAAT?")) {
                    Text("The 10 Qiraat are the mass-transmitted (mutawatir) methods that show how the Ahruf were preserved through the Uthmanic mushaf and teaching traditions.")
                        .font(.body)

                    Text("Each Qiraah has an unbroken chain (isnad) from the reciter → to his teacher → back to Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text("Learn more in the next section: 10 Qiraat (Canonical Recitations).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("USEFUL LINKS")) {
                    Text("Learn More about Ahruf and Qiraat: https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                        .font(.caption)
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("The seven ahruf are all from Allah; the surviving canonical recitations preserve what remained after the Uthmanic standardization of the text.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("7 Ahruf (Modes)")
        .applyConditionalListStyle()
    }
}

struct QiraatView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the ten Qiraat are the authentic, mass-transmitted ways of reciting the Quran, each traced through a continuous chain to the Prophet.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The 10 Qiraat (قِرَاءَات) - from the root q–r–a (قرأ) meaning “to read/recite” - literally means “readings/recitations.” Islamically and Quranically, a Qiraah (قِرَاءَة) is a specific, verified method of reciting the Quran. The 10 Qiraat are the preserved, mass-transmitted (mutawatir - مُتَوَاتِر) recitations of the Quran - each a precise method taught by Prophet Muhammad (peace and blessings be upon him) and transmitted through authentic chains of narrators (isnad إِسنَاد). They do not represent different Qurans, but different prophetic ways of reciting the same revelation.")
                        .font(.body)

                    Text("As covered in the previous section, the Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحرُف) - modes of recitation for ease. Jibril (Gabriel) brought these modes to Prophet Muhammad (peace and blessings be upon him), who taught them to the Ummah. Around one year after the Prophet’s passing, Abu Bakr (may Allah be pleased with him) commissioned the first complete compilation of the Quran into one manuscript, and later Uthman (may Allah be pleased with him) unified public recitation upon official copies from that preserved text. The Qiraat show how those Ahruf were preserved in practice through the Uthmanic rasm (الرَّسم العُثمَانِي) - the consonantal skeleton of the mushaf (مُصحَف).")
                        .font(.body)
                }

                Section(header: Text("WHAT IS A QIRAAH?")) {
                    Text("A Qiraah (قراءة) is a canonical, authenticated way of reciting the Quran that meets three criteria: (1) agreement with the Uthmanic rasm (الرسم العثماني), (2) sound Arabic language, and (3) authentic, widespread transmission (tawatur تواتر).")
                        .font(.body)

                    Text("All 10 Qiraat return to Prophet Muhammad (peace and blessings be upon him). Every reciter has an unbroken chain of students → teachers → Companions → Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("Most differences are within established rules of tajwid (تجويد), allowable word-forms and vowels, elongation (madd مد), assimilation (idgham إدغام), imalah (إمالة), and stopping/continuation - while preserving the same meanings and guidance.")
                        .font(.body)

                    Text("Important: The Qiraat are not arbitrary. They reflect how the seven Ahruf were preserved through both writing and oral transmission - essentially a “mix and preserve” of the revealed modes into rigorously taught, verifiable recitational methods.")
                        .font(.body)
                }

                Section(header: Text("QIRAAH (قراءة) VS RIWAYAH (رواية)")) {
                    Text("• Qiraah: the recitation method attributed to an Imam of recitation (e.g., Nafi, Asim).")
                        .font(.body)
                    Text("• Riwayah: the narration/transmission of that Qiraah by a primary rawi (narrator). Each Qiraah has two principal riwayaat (plural of riwayah).")
                        .font(.body)

                    Text("Example: “Hafs an Asim” means the riwayah (narration) of Hafs (حفص) from the Qiraah (recitation) of Asim (عاصم). “Warsh an Nafi” means the riwayah of Warsh (ورش) from the Qiraah of Nafi (نافع).")
                        .font(.body)

                    Text("Hafs an Asim is the most widespread globally today; that does not mean it is the only right one. All 10 Qiraat (and their 20 Riwayaat) are valid, mutawatir, and from Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("COMMON CLARIFICATIONS")) {
                    Text("Many people hear about 7 and 10 together. Both references are used by scholars: the famous seven canonical recitations (al-Sab'ah) and the full ten canonical Qiraat (7 + 3), all preserved through reliable transmission.")
                        .font(.body)

                    Text("The original seven were famously codified by Imam Abu Bakr Ibn Mujahid. Their Imams are: Nafi (Madinah), Ibn Kathir (Makkah), Abu Amr (Basra), Ibn Amir (Damascus), Asim (Kufa), Hamzah (Kufa), and al-Kisai (Kufa).")
                        .font(.body)

                    Text("Hafs is a riwayah from Asim, and Warsh is a riwayah from Nafi. So when people say Hafs or Warsh, they are naming a narration path within the canonical recitation tradition.")
                        .font(.body)

                    Text("Today, Hafs an Asim is the most widely recited globally (often estimated around 90%+), while other canonical recitations such as Warsh an Nafi remain authentic and practiced.")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("AUTHENTICITY & PRESERVATION")) {
                    Text("The 10 Qiraat are mutawatir - mass attested by many independent chains. They are part of the precise preservation Allah (Glorified and Exalted be He) promised for His Book.")
                        .font(.body)

                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian.” (Quran 15:9)")

                    Text("They do not affect preservation; rather, they manifest it: letter for letter, word for word - in all the ways Prophet Muhammad (peace and blessings be upon him) taught.")
                        .font(.body)
                }

                Section(header: Text("THE FOUR MASTERS OF THE QURAN")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) said: “Take the Quran from four: Abdullah ibn Masud, Salim (the freed slave of Abu Hudhayfah), Ubayy ibn Ka‘b, and Mu‘adh ibn Jabal.” (Sahih al-Bukhari)")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("These four masters were among the foremost teachers of the Quran among the Companions, and their recitation and teaching shaped subsequent generations of transmitters.")
                        .font(.body)
                }

                Section(header: Text("THE 10 QIRAAT (القراءات)")) {
                    Text("The 10 Qiraat are the canonical recitation methods of the Quran. Each is named after its primary teacher (the Imam of that recitation).")
                        .font(.body)

                    Group {
                        Text("• Abu Jafar (أَبُو جَعفَر)")
                        Text("• Abu Amr (أَبُو عَمرٍو)")
                        Text("• al-Kisai (الكِسَائِي)")
                        Text("• Asim (عَاصِم)")
                        Text("• Hamzah (حَمزَة)")
                        Text("• Ibn Amir (ابنُ عَامِر)")
                        Text("• Ibn Kathir (ابنِ كَثِير)")
                        Text("• Khalaf al-Ashir (خَلَف العَاشِر)")
                        Text("• Nafi (نَافِع)")
                        Text("• Yaqoub (يَعقُوب)")
                    }
                    .font(.body)
                }

                Section(header: Text("THE 20 RIWAYAAT (روايات)")) {
                    Text("Each Qiraah (recitation method) has two primary riwayaat (narrations). These are the 20 canonical transmissions used in teaching and ijazah (chain certification).")
                        .font(.body)

                    Group {
                        // Abu Jafar
                        Text("• Ibn Wardan an Abi Jafar (ابنُ وَردَان عَن أَبِي جَعفَر)")
                        Text("• Ibn Jammaz an Abi Jafar (ابنُ جَمَّاز عَن أَبِي جَعفَر)")

                        // Abu Amr
                        Text("• ad-Duri an Abi Amr (الدُّورِي عَن أَبِي عَمرٍو)")
                        Text("• as-Susi an Abi Amr (السُّوسِي عَن أَبِي عَمرٍو)")

                        // al-Kisai
                        Text("• Abu al-Harith an al-Kisai (أَبُو الحَارِث عَن الكِسَائِي)")
                        Text("• ad-Duri an al-Kisai (الدُّورِي عَن الكِسَائِي)")

                        // Asim
                        Text("• Shubah an Asim (شُعبَة عَن عَاصِم)")
                        Text("• Hafs an Asim (حَفص عَن عَاصِم)")

                        // Hamzah
                        Text("• Khalaf an Hamzah (خَلَف عَن حَمزَة)")
                        Text("• Khallad an Hamzah (خَلَّاد عَن حَمزَة)")

                        // Ibn Amir
                        Text("• Hisham an Ibn Amir (هِشَام عَن ابنِ عَامِر)")
                        Text("• Ibn Dhakwan an Ibn Amir (ابنُ ذَكوَان عَن ابنِ عَامِر)")

                        // Ibn Kathir
                        Text("• al-Bazzi an Ibn Kathir (البَزِّي عَن ابنِ كَثِير)")
                        Text("• Qunbul an Ibn Kathir (قُنبُل عَن ابنِ كَثِير)")

                        // Khalaf al-Ashir
                        Text("• Ishaq an Khalaf al-Ashir (إِسحَاق عَن خَلَف العَاشِر)")
                        Text("• Idris an Khalaf al-Ashir (إِدرِيس عَن خَلَف العَاشِر)")

                        // Nafi
                        Text("• Warsh an Nafi (وَرش عَن نَافِع)")
                        Text("• Qalun an Nafi (قَالُون عَن نَافِع)")

                        // Yaqoub
                        Text("• Ruways an Yaqoub (رُوَيس عَن يَعقُوب)")
                        Text("• Rawh an Yaqoub (رَوح عَن يَعقُوب)")
                    }
                    .font(.body)
                }

                Section(header: Text("THE COMPANIONS BEHIND EACH QIRAAH")) {
                    Text("Every Qiraah traces back through its Imam and narrators to the Companions (may Allah be pleased with them) who learned the Quran directly from Prophet Muhammad (peace and blessings be upon him). The chains below show which Companions each reading is transmitted from.")
                        .font(.body)

                    Group {
                        Text("**Nafi (Qari of Madinah)** - narrated by Warsh and Qalun. Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them).")

                        Text("**Ibn Kathir (Qari of Makkah)** - narrated by al-Bazzi and Qunbul. Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, and Abdullah ibn as-Sa’ib (may Allah be pleased with them).")

                        Text("**Abu Amr al-Basri (Qari of Basrah)** - narrated by ad-Duri and as-Susi. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Abu Musa al-Ash‘ari, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abdullah ibn as-Sa’ib, Ubayy ibn Ka‘b, Zayd ibn Thabit, and Abu Hurayrah (may Allah be pleased with them).")

                        Text("**Ibn Amir (Qari of Sham)** - narrated by Hisham and Ibn Dhakwan. Transmitted from Uthman ibn Affan and Abu ad-Darda (may Allah be pleased with them).")

                        Text("**Asim ibn Abi an-Najud (Qari of Kufah)** - narrated by Shu‘bah and Hafs. Most Muslims today recite via Hafs from Asim. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Zayd ibn Thabit, and Ubayy ibn Ka‘b (may Allah be pleased with them).")

                        Text("**Hamzah az-Zayyat** - narrated by Khalaf and Khallad. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text("**Ali ibn Hamzah al-Kisai** - narrated by Abu al-Harith and ad-Duri. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abu Hurayrah, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text("**Ya‘qub al-Hadrami** - narrated by Ruways and Rawh. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, Abu Musa al-Ash‘ari, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abdullah ibn as-Sa’ib, and Abu Hurayrah (may Allah be pleased with them).")

                        Text("**Khalaf al-Bazzar** - narrated by Idris and Ishaq. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Zayd ibn Thabit, Ubayy ibn Ka‘b, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text("**Abu Ja‘far al-Madani** - narrated by Ibn Wardan and Ibn Jammaz. Transmitted from Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them).")
                    }
                    .font(.body)
                }

                Section(header: Text("WHAT THIS CHAIN SHOWS")) {
                    Text("We begin with what Prophet Muhammad (peace and blessings be upon him) began with: the Book of Allah (Glorified and Exalted be He). It is well established that the Quran has reached us by mass transmission (tawatur) through the chains of Ahl as-Sunnah wal-Jama‘ah.")
                        .font(.body)

                    Text("Every one of these narrators of the noble Quran received it, through the chains above, from the Messenger of Allah (peace and blessings be upon him) by way of his Companions (may Allah be pleased with them) - the first to learn, gather, preserve, and transmit it.")
                        .font(.body)

                    Text("Not a single Ithna Ashari (Twelver) Shia is found among these transmitters. This is part of the Quran’s preservation: Allah (Glorified and Exalted be He) did not place in the transmission of His Book anyone who slanders the Companions of His Prophet (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Link(destination: URL(string: "https://mahajjah.com/the-manner-in-which-the-ahlus-sunnah-and-shia-act-upon-this-hadith/")!) {
                        Label("Source: Mahajjah - Ahlus Sunnah and Shia on this hadith", systemImage: "link")
                    }
                    .font(.caption)
                }

                Section(header: Text("OTHER REPORTED QIRAAT")) {
                    Text("There are other reported qiraat besides these Ten. Unlike the 10 Qiraat, which are mutawatir and mass attested, those others do not reach mutawatir status. That does not automatically make them inauthentic - some have isnad to Prophet Muhammad (peace and blessings be upon him) - but because they are not mass attested, we avoid them in public recitation and worship.")
                        .font(.body)

                    Text("We recite what is known with certainty (yaqin يقين) to be from Prophet Muhammad (peace and blessings be upon him) - the 10 Qiraat and their 20 Riwayaat. This unites the Ummah upon what is rigorously established.")
                        .font(.body)
                }

                Section(header: Text("PRACTICAL STUDY & ADVICE")) {
                    Text("• Learn with a qualified teacher who has ijazah (إجازة) and isnad (إسناد). Do not self-invent pronunciations or rely only on apps without verification.")
                        .font(.body)
                    Text("• Begin with one riwayah (commonly Hafs an Asim), then explore others (e.g., Warsh an Nafi) as you progress.")
                        .font(.body)
                    Text("• Remember: differences are a mercy, not a contradiction. They illuminate the Quran’s depth and precision.")
                        .font(.body)
                }

                Section(header: Text("IN-APP AUDIO")) {
                    Text("In this app, you can listen to multiple Qiraat/riwayaat (not all twenty are available). Availability varies by full-surah vs. ayah-by-ayah playback.")
                        .font(.body)
                }

                Section(header: Text("RECAP")) {
                    Text("“The 10 Qiraat are the preserved, mass-transmitted (mutawatir) recitations taught by Prophet Muhammad (peace and blessings be upon him), passed down through authentic chains. Each Qiraah is a specific, verified method of reciting the Quran - not a different text. They reflect how the Ahruf were preserved in writing and oral transmission. All 10 Qiraat (and their 20 Riwayaat) return to Prophet Muhammad (peace and blessings be upon him).”")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("VISUAL GUIDE")) {
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

                Section(header: Text("IMAGE CREDITS")) {
                    Text("The two infographics above are shared with credit to the original creators on Instagram. Please follow and support their work:")
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

                Section(header: Text("USEFUL LINKS")) {
                    Text("Learn More about Ahruf and Qiraat: https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                        .font(.caption)

                    Text("Learn about the other Qiraat: https://www.youtube.com/watch?v=CeV6w0rCilQ&t=80s")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The differences among the Qiraat are all revelation and add richness of meaning - none contradicts another, and all are recited today.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("10 Qiraat (Recitations)")
        .applyConditionalListStyle()
    }

    /// A tappable Instagram handle that opens the creator's profile, used for the infographic credits.
    private func qiraatCreditLink(handle: String) -> some View {
        Link(destination: URL(string: "https://www.instagram.com/\(handle)/")!) {
            Label("@\(handle)", systemImage: "at")
        }
    }
}

struct FarewellView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Farewell Sermon was the Prophet's final address to the Ummah at Arafat, summarizing the core teachings of Islam for all time.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("""
                         The Farewell Sermon (خُطبَةُ ٱلوَدَاعِ), delivered by Prophet Muhammad (peace be upon him), took place on the 9th of Dhu al-Hijjah in the 10th year of Hijrah (632 CE) in the Uranah Valley near Mount Arafat. This sermon is one of the most significant moments in Islamic history, as it encapsulates key teachings and guidance for Muslims.
                         """)
                    .font(.body)

                    Text("""
                         During this momentous occasion, Allah (Glorified and Exalted be He) revealed:
                         “This day I have perfected for you your religion and completed My favor upon you and have approved for you Islam as religion” (Quran 5:3).
                         """)
                    .font(.title3)
                    .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("FINAL DAYS OF THE PROPHET")) {
                    Text("""
                         After delivering this sermon, the Prophet (peace be upon him) continued to guide the Muslim Ummah until his passing on 12th Rabi’ al-Awwal, 11 AH (632 CE). His final words were, “O Allah, with the highest companions,” expressing his longing to meet Allah. He passed away in the home of Aisha (may Allah be pleased with her), leaving behind a legacy of faith and compassion.
                         """)
                    .font(.body)
                }

                Section(header: Text("TEXT OF THE SERMON")) {
                    Text("""
                         O People,

                         Listen attentively, for I do not know whether I will be with you again after this year. Convey my words to those who are absent. Just as you regard this day, this month, and this city as sacred, so regard the life and property of every Muslim as a sacred trust. Return goods entrusted to you to their rightful owners. Do not harm one another, for you will meet your Lord, and He will hold you accountable.

                         Allah has forbidden interest; all interest obligations are canceled, starting with those owed to my uncle, Abbas ibn Abd al-Muttalib. Beware of Satan, for he has lost hope of leading you astray in big matters but will try in small ones.

                         O People,

                         You have rights over your women, and they have rights over you. Treat them with kindness, for they are your partners. Provide for them with goodness. Worship Allah, pray your five daily prayers, fast during Ramadan, give Zakat, and perform Hajj if able. 

                         All mankind is from Adam and Eve. No Arab is superior to a non-Arab, nor is a non-Arab superior to an Arab; no white is superior to a black, nor is a black superior to a white - except in piety and good deeds. Every Muslim is a brother to every other Muslim. Do not commit injustices.

                         After me, no prophet will come, and no new religion will be born. I leave behind the Quran and the Sunnah; if you adhere to them, you will never go astray. Be my witness, O Allah, that I have conveyed Your message.
                         """)
                    .font(.body)
                }

                Section(header: Text("KEY MESSAGES OF THE SERMON")) {
                    Text("""
                         - Sanctity of life, property, and trust.
                         - Abolition of interest (Riba) and unfair practices.
                         - Rights and responsibilities within marriage.
                         - Unity and equality of all humans.
                         - Adherence to the Quran and Sunnah as guidance.
                         """)
                    .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("In it the Prophet affirmed the sanctity of life and property, the equality of all people, the rights of women, and clinging to the Quran and Sunnah - delivered as his religion was perfected.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Farewell Sermon")
        .applyConditionalListStyle()
    }
}

struct SahabahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Sahabah are the Companions who accompanied the Prophet, believed in him, and carried Islam to the world - the best generation of this Ummah.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Sahabah (الصَّحَابَة)** - from the root **s-h-b (ص ح ب)**, companionship - are the companions of Prophet Muhammad (peace be upon him).")
                        .font(.body)

                    Text("They supported him in his mission, witnessed the revelation of the Quran, and preserved the teachings of Islam through word and action.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) praised them in the Quran: “And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct – Allah is pleased with them and they are pleased with Him” (Quran 9:100).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("ABU BAKR AS-SIDDIQ")) {
                    Text("Abu Bakr (may Allah be pleased with him) was the Prophet’s (peace be upon him) closest friend and the first adult male to embrace Islam.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “If I were to take a Khalil (close friend) other than my Lord, I would take Abu Bakr” (Sahih al-Bukhari 3656).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("He was known as As-Siddiq (the Truthful) for immediately affirming the Prophet’s Night Journey (Isra’ and Mi’raj). He was chosen as the first Caliph after the Prophet’s death and led the Muslim Ummah with wisdom and justice.")
                        .font(.body)

                    Text("About one year after the Prophet’s passing, he commissioned Zayd ibn Thabit to compile the Quran into a single manuscript, preserving the revelation in written form alongside mass memorization.")
                        .font(.body)
                }

                Section(header: Text("UMAR IBN AL-KHATTAB")) {
                    Text("Umar (may Allah be pleased with him) was known for his strength, justice, and piety. He was the second Caliph and expanded the Islamic state significantly.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “If there were to be a Prophet after me, it would be Umar ibn Al-Khattab” (Sunan al-Tirmidhi 3686).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("Allah (Glorified and Exalted be He) revealed verses confirming Umar’s opinions, including the ruling of hijab and the prohibition of alcohol.")
                        .font(.body)
                }

                Section(header: Text("UTHMAN IBN AFFAN")) {
                    Text("Uthman (may Allah be pleased with him) was known for his generosity, modesty, and devotion. He unified the Ummah upon official copies of the already compiled Quran, based on the manuscript first compiled under Abu Bakr.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) climbed Mount Uhud with Abu Bakr, Umar, and Uthman and said: “Be firm, O Uhud! For on you there is none but a Prophet, a Siddiq, and two martyrs” (Sahih al-Bukhari 3675).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("He funded the expansion of Al-Masjid an-Nabawi and financed the army during the Battle of Tabuk. His contributions earned him repeated praise from the Prophet (peace be upon him).")
                        .font(.body)
                }

                Section(header: Text("ALI IBN ABI TALIB")) {
                    Text("Ali (may Allah be pleased with him) was the cousin and son-in-law of the Prophet (peace be upon him). He was a scholar, warrior, and deeply spiritual leader.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “You are to me what Harun was to Musa, except there is no prophet after me” (Sahih Muslim 2404).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("He was among the most learned of the Companions, and many later scholars traced their knowledge back to him. He was known for his eloquence, bravery, and deep understanding of Islam.")
                        .font(.body)
                }

                Section(header: Text("MUHAJIREEN & ANSAR")) {
                    Text("The Muhajireen were those who emigrated with the Prophet (peace be upon him) from Makkah to Madinah, leaving behind their wealth and homes for the sake of Allah.")
                        .font(.body)

                    Text("The Ansar were the residents of Madinah who welcomed the Prophet (peace be upon him) and his followers with open hearts and supported them in every way.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) praised them both: “And [also for] those who were settled in al-Madinah and [adopted] the faith before them. They love those who emigrated to them and find not any want in their breasts of what the emigrants were given but give [them] preference over themselves...” (Quran 59:9).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("LEGACY")) {
                    Text("The Sahabah preserved the Quran and Hadith, established justice and governance, and exemplified the moral and ethical teachings of Islam.")
                        .font(.body)

                    Text("Their legacy continues to inspire faith, sacrifice, knowledge, and courage in Muslims to this day.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Allah praised the Companions and was pleased with them. Through them the Quran and Sunnah were preserved and conveyed, and honoring them is part of the faith.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Sahabah")
        .applyConditionalListStyle()
    }
}

struct WivesView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the wives of the Prophet are the “Mothers of the Believers,” honored for their faith, and several became key teachers of Islam.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The wives of Prophet Muhammad (peace be upon him) are honored in Islam as the “Mothers of the Believers” (أُمَّهَاتُ المُؤمِنِين).")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“The Prophet is more worthy of the believers than themselves, and his wives are [in the position of] their mothers” (Quran 33:6).")

                    Text("Prophet Muhammad (peace be upon him) married a total of **11 women** throughout his lifetime. At one time, he was married to a maximum of **9 wives** simultaneously - an exception granted to him as a Prophet. This exception was not unique to him; it was also granted to previous prophets due to their elevated responsibilities and status. For example, Prophet Solomon (peace be upon him) is known to have had a large number of wives, traditionally said to be 100 or more.")
                        .font(.body)
                }

                Section(header: Text("SUPPORT & CONTRIBUTION")) {
                    Text("These women supported the Prophet (peace be upon him) in his mission.")
                        .font(.body)

                    Text("They played vital roles in educating the Muslim community, transmitting Hadith, and exemplifying piety and devotion.")
                        .font(.body)

                    Text("Most of his wives were **widows or divorcees**, many of whom were around his age or older. These marriages were not driven by desire but by **wisdom, compassion, and community building**.")
                        .font(.body)

                    Text("His marriage to **Khadijah bint Khuwaylid** (may Allah be pleased with her) was monogamous and lasted about 25 years, until her death. She was about 15 years older than him, and he took no other wife during her lifetime.")
                        .font(.body)
                }

                Section(header: Text("KHADIJAH")) {
                    Text("Khadijah bint Khuwaylid (may Allah be pleased with her) was the first person to believe in Prophet Muhammad (peace be upon him) and thus the **first Muslim**. After his first revelation in the cave of Hira, she comforted him, wrapped him in a cloak, and reassured him with her deep insight and love.")
                        .font(.body)

                    Text("She said: “Never! By Allah, Allah will never disgrace you. You maintain family ties, speak the truth, support the needy, host guests, and assist those afflicted by calamity” (Sahih al-Bukhari 3).")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) affirmed the beginning of the Prophet’s (peace be upon him) mission in **Surah Al-Muzzammil (73:1)** and **Surah Al-Muddaththir (74:1)** - moments when Khadijah (may Allah be pleased with her) lovingly wrapped and comforted him.")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("The Prophet (peace be upon him) said of her: “She believed in me when the people disbelieved, she affirmed my truthfulness when the people belied me, she supported me with her wealth when the people deprived me, and Allah granted me children by her and not by any other woman” (Musnad Ahmad 24864). Aisha (may Allah be pleased with her) reported that he said, “I was given her love” (Sahih Muslim 2435).")
                        .font(.body)
                }

                Section(header: Text("AISHA")) {
                    Text("Aisha bint Abi Bakr (may Allah be pleased with her) was the daughter of Abu Bakr as-Siddiq (may Allah be pleased with him), the closest companion of the Prophet (peace be upon him). She was the most knowledgeable among the people, especially in Hadith and Islamic jurisprudence.")
                        .font(.body)

                    Text("She was falsely accused in the incident of al-Ifk, but Allah (Glorified and Exalted be He) revealed her innocence in **Surah An-Nur (24:11–26)**, establishing her purity and honor for all time.")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("The Prophet (peace be upon him) was once asked, “Who do you love the most?” He replied, “Aisha.” They asked, “And among men?” He answered, “Her father” (Sahih al-Bukhari 3662).")
                        .font(.body)

                    Text("He also said, “The superiority of Aisha to other women is like the superiority of Tharid to other foods” (Sahih Muslim 2446).")
                        .font(.body)

                    Text("After the Prophet’s (peace be upon him) death, she became one of the greatest scholars of Islam. She taught both men and women and was a source of religious rulings and interpretations.")
                        .font(.body)

                    Text("She narrated **2,210 hadiths**, making her the **fourth-highest hadith narrator** of all time. Most of these relate to the Prophet’s private life, which only she had access to. Without Aisha (may Allah be pleased with her), much of the Prophet’s (peace be upon him) household life, worship, and character would not be known today.")
                        .font(.body)
                }

                Section(header: Text("HOW HE TREATED HIS WIVES")) {
                    Text("The Prophet (peace be upon him) was the best example of kindness, patience, and love toward his wives. These hadiths reflect his character:")
                        .font(.body)

                    Text("• “The best of you are those who are best to their wives, and I am the best of you to my wives” (Sunan al-Tirmidhi 3895).")
                        .font(.body)

                    Text("• Aisha (may Allah be pleased with her) said: “The Messenger of Allah (peace be upon him) never struck anything with his hand, not a woman nor a servant” (Sahih Muslim 2328).")
                        .font(.body)

                    Text("• “A believing man should not hate a believing woman. If he dislikes one of her characteristics, he will be pleased with another” (Sahih Muslim 1469).")
                        .font(.body)

                    Text("• Aisha (may Allah be pleased with her) said: “He used to serve his family, and when the time for prayer came, he would go out to pray” (Sahih al-Bukhari 6039).")
                        .font(.body)
                }

                Section(header: Text("THE ELEVEN WIVES")) {
                    Group {
                        Text("• Khadijah bint Khuwaylid (may Allah be pleased with her)")
                        Text("• Sawdah bint Zam’ah (may Allah be pleased with her)")
                        Text("• Aisha bint Abi Bakr (may Allah be pleased with her)")
                        Text("• Hafsah bint Umar (may Allah be pleased with her)")
                        Text("• Zaynab bint Khuzaymah (may Allah be pleased with her)")
                        Text("• Umm Salamah (Hind bint Abi Umayyah) (may Allah be pleased with her)")
                        Text("• Zaynab bint Jahsh (may Allah be pleased with her)")
                        Text("• Juwayriyah bint al-Harith (may Allah be pleased with her)")
                        Text("• Umm Habibah (Ramlah bint Abi Sufyan) (may Allah be pleased with her)")
                        Text("• Safiyyah bint Huyayy (may Allah be pleased with her)")
                        Text("• Maymunah bint al-Harith (may Allah be pleased with her)")
                    }
                    .font(.body)
                }

                Section(header: Text("WHY SO MANY MARRIAGES?")) {
                    Text("These marriages fulfilled many noble purposes:")
                        .font(.body)

                    Text("• **Supporting widows** who lost husbands in early battles.")
                        .font(.body)

                    Text("• **Forming alliances** with key tribes to strengthen the Muslim community.")
                        .font(.body)

                    Text("• **Spreading Islamic knowledge**, as many of his wives became teachers and Hadith narrators.")
                        .font(.body)

                    Text("• **Setting legal and social precedents** for Muslim family law and ethics.")
                        .font(.body)
                }

                Section(header: Text("LEGACY")) {
                    Text("The lives of the Prophet’s (peace be upon him) wives highlight the essential role of women in Islamic scholarship and community-building.")
                        .font(.body)

                    Text("They are role models for Muslims, inspiring faith, resilience, and devotion.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Through the Prophet's wives - especially Aisha - much of the Sunnah of the home and worship reached the Ummah; loving and respecting them is part of the religion.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Wives")
        .applyConditionalListStyle()
    }
}

struct CaliphatesView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Caliphate is the leadership that continued the Prophet's mission, beginning with the Rightly Guided Caliphs Abu Bakr, Umar, Uthman, and Ali.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Caliphate (الخِلَافَة)** - from the root **kh-l-f (خ ل ف)**, meaning succession - refers to the divinely guided system of governance established after the death of Prophet Muhammad (peace be upon him). It aimed to continue his mission of upholding justice, spreading Islam, and preserving the unity of the Ummah.")
                        .font(.body)

                    Text("The Caliph (خَلِيفَة), literally “successor“ - was entrusted with political, military, judicial, and spiritual leadership, guided by the Quran and Sunnah. The first four caliphs, known as the **Rightly Guided Caliphs (ٱلخُلَفَاء ٱلرَّاشِدُون)**, are regarded as models of righteous rule.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “The Caliphate will remain among you for thirty years, then Allah will give the kingdom to whomever He wills” (Sunan Abi Dawud 4646).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("These thirty years - known as the **Rashidun Caliphate** - represented the ideal Islamic system. The caliphs were chosen by **consultation (شُورَىٰ)** and the pledge of allegiance (**bay'ah, بَيعَة**) of the community: Abu Bakr at Saqifah and then in the mosque, and Uthman after Abd al-Rahman ibn Awf canvassed the people of Madinah house by house - men and women alike - for three nights (Sahih al-Bukhari 7207). This model emphasized justice, humility, accountability, and service to the people.")
                        .font(.body)
                }

                Section(header: Text("ABU BAKR AS-SIDDIQ (632–634 CE)")) {
                    Text("Abu Bakr (may Allah be pleased with him), the Prophet’s closest companion and the first adult male to accept Islam, was chosen as the **first caliph** immediately after the Prophet’s passing. He was selected through consensus at Saqifah.")
                        .font(.body)

                    Text("He led decisively during a time of crisis, launching the **Riddah Wars** to bring back apostate tribes and false prophets. About one year after the Prophet’s death (12 AH), he initiated the first complete compilation of the Quran into a single manuscript.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “There is no one who has helped me more with his wealth and companionship than Abu Bakr” (Sahih al-Bukhari 3661).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)

                    Text("His caliphate lasted just over two years but laid the foundation for unity and stability in the Ummah.")
                        .font(.body)
                }

                Section(header: Text("UMAR IBN AL-KHATTAB (634–644 CE)")) {
                    Text("Umar (may Allah be pleased with him) was appointed by Abu Bakr before his death and accepted by the Muslims as the second caliph. He was renowned for justice, strength, and fear of Allah (Glorified and Exalted be He).")
                        .font(.body)

                    Text("His 10-year reign witnessed the rapid expansion of Islam into the **Byzantine and Persian Empires**, including Jerusalem and Egypt. He established **public registers**, **courts**, **salaries for soldiers**, and the **Islamic calendar**.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “Indeed, Allah has placed the truth upon Umar’s tongue and heart” (Sunan al-Tirmidhi 3682).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)

                    Text("He was assassinated while praying in the masjid and is buried beside the Prophet Muhammad (peace be upon him).")
                        .font(.body)
                }

                Section(header: Text("UTHMAN IBN AFFAN (644–656 CE)")) {
                    Text("Uthman (may Allah be pleased with him) was chosen through a **council of six** appointed by Umar. Known for his generosity and modesty, he married two daughters of the Prophet Muhammad (peace be upon him) and was called **Dhu al-Nurayn** (ذُو ٱلنُّورَين – the Possessor of Two Lights).")
                        .font(.body)

                    Text("He **standardized official copies of the Quran** from the already compiled manuscript preserved from Abu Bakr’s time, unifying public recitation and preventing disputes over unverified personal materials. He sent official copies to major cities and retired non-verified personal codices used outside official transmission.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “Should I not feel shy of the one whom the angels are shy of?” (Sahih Muslim 2401).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)

                    Text("Due to political unrest and false accusations, he was unjustly besieged and martyred while reciting the Quran.")
                        .font(.body)
                }

                Section(header: Text("ALI IBN ABI TALIB (656–661 CE)")) {
                    Text("Ali (may Allah be pleased with him), the cousin and son-in-law of the Prophet Muhammad (peace be upon him), was chosen as the fourth caliph after Uthman’s martyrdom.")
                        .font(.body)

                    Text("His caliphate was challenged by internal strife, including the **Battle of the Camel** and **Battle of Siffin**. Despite the trials, he remained committed to justice and truth.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said to him: “You are to me like Harun was to Musa, except that there is no prophet after me” (Sahih Muslim 2404).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)

                    Text("Ali was assassinated in Kufah while leading the Fajr prayer. His legacy lives on in scholarship, courage, and moral leadership.")
                        .font(.body)
                }

                Section(header: Text("LEGACY OF THE RASHIDUN")) {
                    Text("The Rashidun Caliphs (632–661 CE) ruled with unmatched integrity, transparency, and adherence to prophetic tradition. Their rule was guided by **shura (شُورَىٰ)**, justice, and humility.")
                        .font(.body)

                    Text("Though later caliphates transitioned into **hereditary monarchy**, the Prophet Muhammad (peace be upon him) had foretold this change.")
                        .font(.body)

                    Text("He said: “The Caliphate after me will last thirty years; then there will be kingship” (Sunan Abi Dawud 4646).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("Despite this shift, many later caliphs still contributed greatly to Islamic knowledge, architecture, and global influence.")
                        .font(.body)
                }

                Section(header: Text("THE UMAYYAD CALIPHATE (661–750 CE)")) {
                    Text("The Umayyads, beginning with Mu'awiyah ibn Abi Sufyan (may Allah be pleased with him), transitioned the caliphate into a **dynastic monarchy**. Their capital was **Damascus (دِمَشق)**.")
                        .font(.body)

                    Text("They expanded Islam into **al-Andalus (Spain)**, **North Africa**, and **Central Asia**, and made **Arabic** the official administrative language.")
                        .font(.body)

                    Text("Though less spiritually exemplary than the Rashidun, the Umayyads left a profound legacy in governance, culture, and infrastructure.")
                        .font(.body)
                }

                Section(header: Text("THE ABBASID CALIPHATE (750–1258 CE)")) {
                    Text("The Abbasids overthrew the Umayyads and moved the capital to **Baghdad (بَغدَاد)**, initiating the **Golden Age of Islam**.")
                        .font(.body)

                    Text("They supported **translation**, **science**, **mathematics**, **medicine**, and **philosophy**, and established the renowned **Bayt al-Hikmah (بَيت ٱلحِكمَة – House of Wisdom)**.")
                        .font(.body)

                    Text("Although internal divisions weakened the state, their intellectual contributions influenced both the Muslim world and Europe. The empire fell to the Mongols in 1258 CE.")
                        .font(.body)
                }

                Section(header: Text("THE OTTOMAN CALIPHATE (1517–1924 CE)")) {
                    Text("The Ottomans, a Turkish dynasty, were the **first non-Arabs** to assume the Islamic Caliphate. After the fall of the Abbasids in Egypt, the caliphate passed to the Ottomans, whose capital was **Istanbul (إِسطَنبُول)**.")
                        .font(.body)

                    Text("They ruled a vast empire across **Europe**, **Asia**, and **Africa**, preserved **Islamic law (ٱلشَّرِيعَة)**, and defended the **Two Holy Mosques** in **Makkah (مَكَّة)** and **Madinah (ٱلمَدِينَة)**.")
                        .font(.body)

                    Text("The Ottoman Caliphate was officially **abolished in 1924 CE** by Mustafa Kemal Atatürk, ending more than 1,300 years of continuous Islamic political leadership.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The Rightly Guided Caliphs are the model of just Islamic governance - preserving the Quran, spreading the faith, and upholding the unity of the Ummah.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Caliphates")
        .applyConditionalListStyle()
    }
}

struct MadhabView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the four madhahib - Hanafi, Maliki, Shafi'i, and Hanbali - are the accepted schools of Islamic jurisprudence, differing in fiqh but united in creed.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("A **madhhab (مَذهَب)** is a school of Islamic jurisprudence that provides structured guidance on how to derive and apply rulings from the Quran and Sunnah. The plural is **madhahib (مَذَاهِب)**.")
                        .font(.body)

                    Text("Madhahib developed as scholars preserved and codified fiqh (فِقه), or Islamic legal reasoning/jurisprudence, to help Muslims navigate daily life, worship, transactions, and society with clarity and consistency.")
                        .font(.body)

                    Text("Following a madhhab ensures one is following a valid, peer-reviewed methodology developed by righteous scholars deeply rooted in the Quran, Sunnah, consensus (إِجمَاع), and analogy (قِيَاس). It is not blind following - it is trust in generations of qualified scholarship.")
                        .font(.body)

                    Text("The Prophet Muhammad (peace be upon him) said: “Scholars are the inheritors of the prophets” (Sunan Abi Dawud 3641).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("WHY FOLLOW A MADHHAB?")) {
                    Text("Islamic rulings are not always black and white. Scholars developed principles to interpret revelation when texts appeared to conflict or were not explicit.")
                        .font(.body)

                    Text("For example, rulings on prayer times, purification, zakah calculation, marriage, and contracts all require detailed interpretation. Madhahib systematize this process based on authentic sources and established rules.")
                        .font(.body)

                    Text("Instead of picking rulings randomly or following desire, a madhhab offers **structured, principled, and scholarly guidance**. It helps prevent inconsistency and distortion in religious practice.")
                        .font(.body)
                }

                Section(header: Text("THE FOUR SUNNI MADHAHIB")) {
                    imamEntry(
                        number: 1,
                        name: "Imam Abu Hanifa (may Allah have mercy on him)",
                        arabic: "أَبُو حَنِيفَة",
                        meta: "Hanafi (الحَنَفِي) · Kufa, Iraq (الكُوفَة، العِرَاق) · 80–150 AH / 699–767 CE",
                        description: "The Imam of Kufa and founder of the Hanafi school. Known for his mastery of fiqh, ijtihad, and qiyas (analogical reasoning) and for his rigorous legal methodology. It is the most followed madhhab today, especially in South Asia, Turkey, Central Asia, and the Balkans."
                    )

                    imamEntry(
                        number: 2,
                        name: "Imam Malik ibn Anas (may Allah have mercy on him)",
                        arabic: "مَالِك بن أَنَس",
                        meta: "Maliki (المَالِكِي) · Madinah (المَدِينَة) · 93–179 AH / 715–795 CE",
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
                        arabic: "أَحمَد بن حَنبَل",
                        meta: "Hanbali (الحَنبَلِي) · Baghdad (بَغدَاد) · 164–241 AH / 780–855 CE",
                        description: "The Imam of Ahl al-Hadith (أَهل الحَدِيث), renowned for his steadfastness during the Mihna (المِحنَة, the Inquisition) and his firm adherence to the Quran and Sunnah, using analogy only when necessary. Mainly followed in Saudi Arabia and the Gulf."
                    )
                }

                Section(header: Text("WHEN THE MADHAHIB TOOK SHAPE")) {
                    Text("None of the four imams formally founded an institution. Each taught a methodology that his students preserved and systematized into a school over the generations, so historians distinguish between the life of the imam and the emergence of the madhhab.")
                        .font(.body)

                    Text("The Hanafi school began in Kufa during Abu Hanifa’s lifetime and was firmly established by his students Abu Yusuf (d. 182 AH) and Muhammad al-Shaybani (d. 189 AH). The Maliki school developed in Madinah through Imam Malik’s teaching circle and Al-Muwatta. The Shafi‘i school crystallized in Egypt in Imam al-Shafi‘i’s final years - his “new” madhhab - and spread after him through students like al-Muzani and al-Buwayti. The Hanbali school was collected and systematized after Imam Ahmad’s death by his sons and students such as al-Khallal.")
                        .font(.body)

                    Text("The four imams form an unbroken chain of teacher and student: Imam Malik taught al-Shafi‘i, who in turn taught Ahmad ibn Hanbal. Imam Malik was also a contemporary of Abu Hanifa, and al-Shafi‘i was born in the very year Abu Hanifa passed away (150 AH).")
                        .font(.body)
                }

                Section(header: Text("UNITY THROUGH DIVERSITY")) {
                    Text("All four madhahib are valid and respected paths within Ahl al-Sunnah wa al-Jama‘ah (أَهل السُّنَّة وَالجَمَاعَة). Though they may differ in legal rulings, they are united in the same ‘aqeedah (عَقِيدَة) - the core beliefs regarding Allah, His names and attributes, prophethood, the Quran, the unseen, and the Afterlife.")
                        .font(.body)

                    Text("This shared creed is why they are all considered part of Ahl al-Sunnah wa al-Jama‘ah. The differences among them are in jurisprudence (fiqh), not faith (‘aqeedah), and reflect the depth and mercy of Islamic legal tradition.")
                        .font(.body)

                    Text("No single school is “more Islamic“ - each preserved knowledge and served the Ummah according to its time and place. Following any of them keeps one on the path of the Prophet (peace be upon him) and his companions.")
                        .font(.body)

                    Text("Imam Malik ibn Anas (may Allah have mercy on him) said: “Everyone's statement may be taken from or rejected, except the one in this grave” - pointing to the grave of the Prophet (peace be upon him).")
                        .font(.body)
                }

                Section(header: Text("CONCLUSION")) {
                    Text("Following a madhhab gives structure to religious life and connects Muslims to a legacy of knowledge, discipline, and unity. While it is not obligatory to follow one, it is highly encouraged, especially for those without deep training in Islamic law.")
                        .font(.body)

                    Text("If one is unsure which madhhab to follow, they may follow the trusted local scholars in their community, and Allah (Glorified and Exalted be He) will reward sincerity and effort.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Following a qualified school connects a Muslim to generations of disciplined scholarship; their differences are a mercy, and all are within Ahl as-Sunnah.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The 4 Madhahib")
        .applyConditionalListStyle()
    }

    /// One imam's entry: a bold name (with the Arabic name), a secondary line of school / region / dates, and a
    /// short description.
    private func imamEntry(number: Int, name: String, arabic: String, meta: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("**\(number). \(name)** - \(arabic)")
                .font(.body)

            Text(meta)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(description)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AhlulBaytView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Ahlul Bayt are the family of the Prophet - loving, honoring, and upholding their rights is part of the religion.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Ahlul Bayt (أَهلُ البَيت)** - literally “the People of the House“ - are the family of Prophet Muhammad (peace be upon him). Loving them, honoring them, and upholding their rights is part of the religion, and hating them or belittling them is a grave sin.")
                        .font(.body)

                    Text("The Quran uses the term directly when addressing the Prophet’s household:")
                        .font(.body)

                    ScriptureQuote(text: "“Allah only intends to remove from you the impurity [of sin], O people of the household, and to purify you with [extensive] purification” (Quran 33:33).")

                    Text("This is one continuous passage. It is essential to read the verses immediately before and after it to see who is being addressed.")
                        .font(.body)
                }

                Section(header: Text("THE WIVES ARE PART OF THE AHLUL BAYT")) {
                    Text("The verse of purification (33:33) sits in the middle of a passage directed to the Prophet’s wives (may Allah be pleased with them). The address begins:")
                        .font(.body)

                    ScriptureQuote(text: "“O wives of the Prophet, you are not like anyone among women. If you fear Allah, then do not be soft in speech…” (Quran 33:32).")

                    ScriptureQuote(text: "“And abide in your houses and do not display yourselves as [was] the display of the former times of ignorance. And establish prayer and give zakah and obey Allah and His Messenger. Allah only intends to remove from you the impurity, O people of the household, and to purify you with [extensive] purification” (Quran 33:33).")

                    ScriptureQuote(text: "“And remember what is recited in your houses of the verses of Allah and wisdom. Indeed, Allah is ever Subtle and Acquainted [with all things]” (Quran 33:34).")

                    Text("The phrase “O people of the household“ is therefore addressed, first and foremost, to the wives of the Prophet (peace be upon him) - the **Mothers of the Believers (أُمَّهَاتُ المُؤمِنِين)**, whom Allah placed in the position of mothers to every believer (Quran 33:6).")
                        .font(.body)

                    Text("Allah also called the wife of Ibrahim (peace be upon him) part of the “people of the house“ using the very same expression:")
                        .font(.body)

                    ScriptureQuote(text: "“They said, ‘Are you amazed at the decree of Allah? May the mercy of Allah and His blessings be upon you, people of the house. Indeed, He is Praiseworthy and Honorable’” (Quran 11:73).")

                    Text("So a prophet’s wives being included in “Ahl al-Bayt“ is the established Quranic usage, not an exception.")
                        .font(.body)
                }

                Section(header: Text("THE FAMILY OF THE CLOAK")) {
                    Text("The Ahlul Bayt also includes the Prophet’s daughter **Fatimah**, his cousin and son-in-law **Ali**, and their sons **al-Hasan** and **al-Husayn** (may Allah be pleased with them all).")
                        .font(.body)

                    Text("Aisha (may Allah be pleased with her) narrated: “The Prophet (peace be upon him) went out one morning wearing a cloak of black camel hair. Al-Hasan ibn Ali came and he took him in, then al-Husayn came in with him, then Fatimah, then Ali. Then he said: ‘Allah only intends to remove from you the impurity, O people of the household, and to purify you with [extensive] purification’” (Sahih Muslim 2424).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("Including these four does not exclude the wives - the Prophet (peace be upon him) was gathering additional members of his household under the cloak, within a passage whose context is already addressing his wives. The two are complementary, not contradictory.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said of his grandsons: “Al-Hasan and al-Husayn are the two masters of the youth of Paradise” (Sunan al-Tirmidhi 3768).")
                        .font(.body)

                    Text("And of Fatimah (may Allah be pleased with her) he said: “Fatimah is a part of me. Whoever angers her angers me” (Sahih al-Bukhari 3714).")
                        .font(.body)
                }

                Section(header: Text("THE BANU HASHIM AND THE PROPHET’S KIN")) {
                    Text("The Ahlul Bayt further includes the relatives of the Prophet (peace be upon him) upon whom charity (sadaqah) is forbidden: the family of Ali, the family of Ja‘far, the family of Aqil, and the family of al-Abbas (may Allah be pleased with them).")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “Charity is not permissible for Muhammad or the family of Muhammad; it is only the people’s impurities” (Sahih Muslim 1072).")
                        .font(.body)

                    Text("Zayd ibn Arqam (may Allah be pleased with him) was asked, “Who are the people of his household? Are not his wives among the people of his household?” He said: “His wives are among the people of his household, but the people of his household are those for whom charity is forbidden after him” (Sahih Muslim 2408).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("THE COMMAND TO LOVE THEM")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)

                    ScriptureQuote(text: "“Say, [O Muhammad], ‘I do not ask you for it any payment [but] only good will through kinship’” (Quran 42:23).")

                    Text("In his farewell address the Prophet (peace be upon him) said: “I am leaving among you two weighty things: the first is the Book of Allah, in which there is guidance and light… hold fast to the Book of Allah.” Then he said: “And the people of my household. I remind you of Allah concerning the people of my household. I remind you of Allah concerning the people of my household” (Sahih Muslim 2408).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("Every believer sends blessings upon them in each prayer: “O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and upon the family of Ibrahim” (Sahih al-Bukhari 3370).")
                        .font(.body)

                    Text("Loving the Ahlul Bayt is a sign of faith. It is never in tension with loving the Companions (may Allah be pleased with them) - Ali, al-Hasan, al-Husayn, and the Prophet’s wives were themselves among the Companions.")
                        .font(.body)
                }

                Section(header: Text("THE BALANCED POSITION")) {
                    Text("There are two errors regarding the Ahlul Bayt. Some **neglect their rights** and fail to honor them as Allah and His Messenger commanded. Others **exaggerate beyond bounds**, elevating them past the station Allah gave them, or using love of them as a pretext to curse and slander the Companions.")
                        .font(.body)

                    Text("The straight path is between the two: love and honor them without exaggeration, and love all the Companions of the Prophet (peace be upon him) alongside them.")
                        .font(.body)

                    ScriptureQuote(text: "“And [there is a share for] those who came after them, saying, ‘Our Lord, forgive us and our brothers who preceded us in faith and put not in our hearts [any] resentment toward those who have believed. Our Lord, indeed You are Kind and Merciful’” (Quran 59:10).")

                    Text("Ali, al-Hasan, and al-Husayn (may Allah be pleased with them) themselves loved, prayed behind, married into, and named their children after Abu Bakr, Umar, and Uthman (may Allah be pleased with them). Their example is the proof of this unity.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Balanced love for the Prophet's household, without exaggeration or neglect, is the way of the believers - joined with love for all his Companions.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The People of the House")
        .applyConditionalListStyle()
    }
}

struct AhlusSunnahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Ahl as-Sunnah wal-Jama'ah are those who hold to the Sunnah of the Prophet upon the understanding of his Companions, united in creed.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Ahl as-Sunnah wal-Jama‘ah (أَهلُ السُّنَّةِ وَالجَمَاعَة)** means “the People of the Sunnah and the Community.“ They are those who hold to the Sunnah of the Prophet Muhammad (peace be upon him) and remain united upon the understanding of his Companions (may Allah be pleased with them).")
                        .font(.body)

                    Text("**Sunnah** here means the Prophet’s way - his beliefs, statements, actions, and approvals. **Jama‘ah** means the united body of the believers, and specifically the way of the Companions and those who followed them in goodness.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)

                    ScriptureQuote(text: "“And whoever opposes the Messenger after guidance has become clear to him and follows other than the way of the believers - We will give him what he has taken and drive him into Hell, and evil it is as a destination” (Quran 4:115).")

                    Text("“The way of the believers“ in this verse is the way of the first believers: the Companions.")
                        .font(.body)
                }

                Section(header: Text("THE THREE FOUNDATIONS")) {
                    Text("**1. The Quran** - taken as it is, without distortion, denial, or asking “how.“")
                        .font(.body)

                    Text("**2. The authentic Sunnah** - accepted as binding revelation alongside the Quran, whether the report is mutawatir or an authentic single narration (ahad).")
                        .font(.body)

                    Text("**3. The understanding of the Salaf** - the Quran and Sunnah are understood the way the first three generations understood them, not according to later opinions or personal reasoning that contradicts them.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says: “And the first forerunners among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)

                    Text("The Prophet (peace be upon him) said: “The best of people are my generation, then those who follow them, then those who follow them” (Sahih al-Bukhari 2652).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("THEIR CREED (AQEEDAH)")) {
                    Text("• **Tawhid**: Allah alone is worshipped, and He alone is the Lord, and He is called by His beautiful Names and described by His perfect Attributes.")
                        .font(.body)

                    Text("• **Names and Attributes**: affirmed as Allah affirmed them for Himself, without likening Him to creation (tashbih) and without stripping the meanings away (ta‘til).")
                        .font(.body)

                    ScriptureQuote(text: "“There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).")

                    Text("• **Iman** consists of belief in the heart, statement of the tongue, and action of the limbs. It increases with obedience and decreases with disobedience.")
                        .font(.body)

                    Text("• **Qadar**: everything occurs by Allah’s knowledge, writing, will, and creation, while the servant has real choice and responsibility.")
                        .font(.body)

                    Text("• **No takfir** of a Muslim for a major sin, so long as he does not deem it lawful. The sinner remains a believer, deficient in faith.")
                        .font(.body)

                    Text("• Love for **all the Companions** (may Allah be pleased with them) and the **Ahlul Bayt**, without exaggeration in either direction.")
                        .font(.body)
                }

                Section(header: Text("THE SAVED GROUP")) {
                    Text("The Prophet (peace be upon him) said: “The Jews split into seventy-one sects, the Christians into seventy-two, and my nation will split into seventy-three sects, all of them in the Fire except one.“ They asked, “Who are they, O Messenger of Allah?“ He said: “Those who are upon what I and my Companions are upon today” (Sunan al-Tirmidhi 2641).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("The defining measure in this hadith is not a name or a label, but a **standard**: what the Prophet (peace be upon him) and his Companions were upon. Ahl as-Sunnah wal-Jama‘ah is simply the name for those who hold to that standard.")
                        .font(.body)

                    Text("He (peace be upon him) also said: “Hold fast to my Sunnah and the Sunnah of the rightly guided caliphs after me. Cling to it with your molar teeth, and beware of newly invented matters, for every innovation is misguidance” (Sunan Abi Dawud 4607).")
                        .font(.body)
                }

                Section(header: Text("UNITY, NOT SECTARIANISM")) {
                    Text("Allah (Glorified and Exalted be He) commands unity upon the truth:")
                        .font(.body)

                    ScriptureQuote(text: "“And hold firmly to the rope of Allah all together and do not become divided” (Quran 3:103).")

                    ScriptureQuote(text: "“Indeed, those who have divided their religion and become sects - you are not associated with them in anything” (Quran 6:159).")

                    Text("Ahl as-Sunnah wal-Jama‘ah is therefore not a sect among sects. It is the original, undivided Islam of the Prophet (peace be upon him) and his Companions. Its adherents differ in fiqh across the four madhahib, yet stand united in creed.")
                        .font(.body)

                    Text("They are known for mercy toward the believers, honesty toward opponents, obedience to Muslim authority in what is good, and refusal to declare the general body of Muslims outside of Islam.")
                        .font(.body)
                }

                Section(header: Text("CONCLUSION")) {
                    Text("To be from Ahl as-Sunnah wal-Jama‘ah is to take the Quran and the authentic Sunnah as they came, to understand them as the Companions understood them, to love the Prophet’s family and his Companions together, and to hold to the community of the Muslims.")
                        .font(.body)

                    ScriptureQuote(text: "“So if they believe in the same as you believe in, then they have been rightly guided” (Quran 2:137).")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Not a sect but the original, undivided Islam - taking the Quran and Sunnah as the Companions did, and loving the Prophet's family and Companions together.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ahl As-Sunnah")
        .applyConditionalListStyle()
    }
}

struct SeerahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Seerah is the life story of Prophet Muhammad - his character, mission, and example - drawn from the Quran and authentic reports.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Seerah (سِيرَة)** is the biography of the Prophet Muhammad (peace be upon him): the account of his life, character, and mission, drawn from the Quran and authentic reports.")
                        .font(.body)

                    Text("Studying it is not merely history - it shows how revelation was lived, and it is a means of knowing, loving, and following him.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says: “There has certainly been for you in the Messenger of Allah an excellent pattern for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("BEFORE PROPHETHOOD")) {
                    Text("He was born in the year 570 CE in **Makkah (مَكَّة)**, among the tribe of Quraysh. His father Abdullah died before his birth and his mother Aminah when he was six, so he was raised by his grandfather Abd al-Muttalib and then his uncle Abu Talib.")
                        .font(.body)

                    Text("Even before revelation his people called him **Al-Amin (الأَمِين)**, “the Trustworthy,” for his honesty and noble character. At about twenty-five he married **Khadijah (خَدِيجَة)** (may Allah be pleased with her).")
                        .font(.body)
                }

                Section(header: Text("THE FIRST REVELATION")) {
                    Text("At the age of forty, while worshipping alone in the cave of **Hira (حِرَاء)** near Makkah, the angel **Jibril (جِبرِيل)** brought him the first revelation: “**Iqra (اِقرَأ)**” - “Read in the name of your Lord who created” (Quran 96:1).")
                        .font(.body)

                    Text("This began twenty-three years of the revelation of the Quran, which continued until shortly before his death.")
                        .font(.body)
                }

                Section(header: Text("THE MAKKAN PERIOD")) {
                    Text("For about thirteen years in Makkah he called people to **Tawhid (تَوحِيد)** - the worship of Allah alone - through his **Dawah (دَعوَة)**, his call to Islam. He and the early believers met mockery, boycott, and severe persecution, yet remained patient.")
                        .font(.body)

                    Text("In this period he was honoured with the **Isra and Mi'raj (الإِسرَاء وَالمِعرَاج)**, the night journey to Jerusalem and the ascension through the heavens, during which the five daily prayers were made obligatory.")
                        .font(.body)
                }

                Section(header: Text("THE HIJRAH")) {
                    Text("In 622 CE, by Allah’s command, the Prophet (peace be upon him) made the **Hijrah (هِجرَة)** - the migration from Makkah to **Madinah (المَدِينَة)**. This event was so pivotal that the Islamic (Hijri) calendar begins from it.")
                        .font(.body)
                }

                Section(header: Text("THE MADINAN PERIOD")) {
                    Text("In Madinah he established the first Muslim community: building the mosque, joining the emigrants (Muhajirun) and the helpers (Ansar) in brotherhood, and governing by revelation.")
                        .font(.body)

                    Text("The community was tested and defended in major events such as **Badr (بَدر)**, **Uhud (أُحُد)**, and the Battle of the Trench, **Al-Khandaq (الخَندَق)**. The **Treaty of Hudaybiyyah (الحُدَيبِيَة)** opened the way for peace, and in 630 CE Makkah was entered peacefully and cleansed of idols.")
                        .font(.body)
                }

                Section(header: Text("THE FAREWELL AND HIS PASSING")) {
                    Text("In 10 AH he performed the Farewell Pilgrimage, **Hajjat al-Wada (حَجَّة الوَدَاع)**, and delivered his Farewell Sermon before a great gathering of believers.")
                        .font(.body)

                    Text("He passed away in Madinah in 11 AH / 632 CE, at the age of sixty-three, and is buried there. He left behind the Quran and his Sunnah as guidance for all who came after.")
                        .font(.body)
                }

                Section(header: Text("HIS CHARACTER")) {
                    Text("He was sent as a mercy to all creation, **Rahmatan lil-Alamin (رَحمَة لِلعَالَمِين)**.")
                        .font(.body)

                    ScriptureQuote(text: "“And We have not sent you except as a mercy to the worlds” (Quran 21:107).")

                    Text("When Aishah (may Allah be pleased with her) was asked about his character, she said that his character was the Quran - he embodied its teachings in the most complete way.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Studying the Seerah shows how revelation was lived and deepens a Muslim's love and following of the Prophet, the best example for all people.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Seerah")
        .applyConditionalListStyle()
    }
}

struct TafsirView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Tafsir is the explanation of the Quran's meanings - soundest when the Quran is explained by the Quran, the Sunnah, and the understanding of the early generations.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Tafsir (تَفسِير)** is the explanation and clarification of the meanings of the Quran: its words, rulings, and wisdoms. Its scholar is called a **Mufassir (مُفَسِّر)**.")
                        .font(.body)

                    Text("Its blameworthy counterpart is **Tafsir bir-Ra'y (تَفسِير بِالرَّأي)** in the censured sense - interpreting the Quran by mere opinion, away from its established meaning and the understanding of the Salaf.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says: “This is a blessed Book which We have revealed to you that they might reflect upon its verses” (Quran 38:29).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("HOW THE QURAN IS EXPLAINED")) {
                    Text("The soundest tafsir is **bil-ma'thur (بِالمَأثُور)**, by transmission, and it proceeds in order:")
                        .font(.body)

                    Text("**1. The Quran by the Quran** - a matter left general in one place is often clarified in another.")
                        .font(.body)

                    Text("**2. The Quran by the Sunnah** - the Prophet (peace be upon him) explained what was revealed to him. “And We revealed to you the message that you may make clear to the people what was sent down to them” (Quran 16:44).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)

                    Text("**3. The statements of the Companions (Sahabah)** - they witnessed the revelation and knew its context best.")
                        .font(.body)

                    Text("**4. The statements of the Successors (Tabi'un)** - the students of the Companions, followed by explanation through the Arabic language.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Asbab al-Nuzul (أَسبَاب النُّزُول)** - the reasons or occasions of revelation, i.e. the events a verse was revealed about.")
                        .font(.body)

                    Text("**Muhkam (مُحكَم)** - verses clear and decisive in meaning; **Mutashabih (مُتَشَابِه)** - verses whose full meaning is not entirely apparent, referred back to the clear ones.")
                        .font(.body)

                    Text("**An-Nasikh wal-Mansukh (النَّاسِخ وَالمَنسُوخ)** - the abrogating and abrogated; a later ruling that replaces an earlier one within the revelation.")
                        .font(.body)
                }

                Section(header: Text("CONDITIONS OF THE MUFASSIR")) {
                    Text("Explaining the Quran is not by desire or guesswork. It requires sound belief, knowledge of the Arabic language, the Sunnah, the sayings of the early scholars, and the sciences of the Quran.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) warned: “Whoever speaks about the Quran without knowledge, let him take his seat in the Fire” (Sunan al-Tirmidhi 2950).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("WELL-KNOWN WORKS")) {
                    Text("Among the most trusted classical works of tafsir are those of **al-Tabari (الطَّبَرِي)**, **Ibn Kathir (اِبن كَثِير)**, and **al-Baghawi (البَغَوِي)**, and among later concise works, that of **al-Sa'di (السَّعدِي)**. They are prized for explaining the Quran by the Quran, the Sunnah, and the understanding of the early generations.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("True Tafsir rests on knowledge, not opinion; through it the guidance of the Quran becomes clear and livable for every generation.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tafsir")
        .applyConditionalListStyle()
    }
}

struct FiqhAqeedahManhajView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: aqeedah is what you believe, fiqh is what you do, and manhaj is how you understand and derive both from revelation.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Three words describe how a Muslim believes, acts, and understands the religion: **Aqeedah (عَقِيدَة)**, **Fiqh (فِقه)**, and **Manhaj (مَنهَج)**.")
                        .font(.body)

                    Text("In short: aqeedah is what you believe, fiqh is what you do, and manhaj is how you understand and derive both.")
                        .font(.body)
                }

                Section(header: Text("AQEEDAH (BELIEF)")) {
                    Text("**Aqeedah (عَقِيدَة)** is creed - the beliefs the heart is bound to with certainty. Its core is **Tawhid (تَوحِيد)**, singling out Allah alone in worship, lordship, and His names and attributes.")
                        .font(.body)

                    Text("It includes the six pillars of faith: belief in Allah, His angels, His books, His messengers, the Last Day, and **Al-Qadar (القَدَر)**, the divine decree. Aqeedah does not change with time or place and is one for all the believers.")
                        .font(.body)

                    ScriptureQuote(text: "“The Messenger has believed in what was revealed to him from his Lord, and so have the believers. All of them have believed in Allah and His angels and His books and His messengers” (Quran 2:285).")
                }

                Section(header: Text("FIQH (JURISPRUDENCE)")) {
                    Text("**Fiqh (فِقه)** is the understanding of the practical rulings of Islam derived from the Quran and Sunnah - the “how“ of worship, **Ibadah (عِبَادَة)**, and of dealings, **Muamalat (مُعَامَلَات)**, such as prayer, fasting, trade, and marriage.")
                        .font(.body)

                    Text("Because deriving detailed rulings involves **Ijtihad (اِجتِهَاد)**, qualified scholarly effort, sincere scholars sometimes differ. This is the source of the accepted schools of fiqh, and such differences are a mercy, not division in the religion.")
                        .font(.body)
                }

                Section(header: Text("MANHAJ (METHODOLOGY)")) {
                    Text("**Manhaj (مَنهَج)** is methodology - the path by which one understands, prioritizes, and applies the religion, and deals with knowledge and people.")
                        .font(.body)

                    Text("The sound manhaj is to take the Quran and the authentic Sunnah upon the understanding of the **Salaf (السَّلَف)**, the first righteous generations, rather than by later opinions that contradict them.")
                        .font(.body)

                    ScriptureQuote(text: "“And the first forerunners among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).")
                }

                Section(header: Text("HOW THEY RELATE")) {
                    Text("Aqeedah is the foundation, fiqh is the practice built upon it, and manhaj is the method that keeps both tied to revelation as it was first understood.")
                        .font(.body)

                    Text("The believers may differ in points of fiqh while remaining one in aqeedah and united upon a sound manhaj.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("United in creed, allowing valid differences in jurisprudence, and following the method of the first generations - this is the balance a Muslim strives for.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Fiqh, Aqeedah, Manhaj")
        .applyConditionalListStyle()
    }
}

#Preview {
    AlIslamPreviewContainer {
        PillarsView()
    }
}
