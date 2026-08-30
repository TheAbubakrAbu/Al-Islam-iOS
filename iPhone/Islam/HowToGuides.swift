import SwiftUI

struct GuidesView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            #if DEBUG
            DebugArticleLink(articles: [
                "pray": AnyView(HowToPrayView()), "fast": AnyView(HowToFastView()), "zakah": AnyView(HowToZakahView()),
                "hajj": AnyView(HowToHajjView()), "umrah": AnyView(HowToUmrahView()), "wudhu": AnyView(WudhuView()),
                "ghusl": AnyView(GhuslView()), "jumuah": AnyView(JumuahView()), "adhan": AnyView(AdhanOtherView()),
                "iqamah": AnyView(IqamahView()), "eid": AnyView(TakbiratView()),
            ], argument: "-guidesArticle")
            #endif

            Group {
                Section(header: Text("HOW TO WORSHIP")) {
                    guideLink("How to Pray (Salah)", destination: HowToPrayView())
                    guideLink("How to Fast (Sawm)", destination: HowToFastView())
                    guideLink("How to Give Zakah", destination: HowToZakahView())
                    guideLink("How to Perform Hajj", destination: HowToHajjView())
                    guideLink("How to Perform Umrah", destination: HowToUmrahView())
                }

                Section(header: Text("PURIFICATION & PRAYER")) {
                    guideLink("How to Make Wudhu", destination: WudhuView())
                    guideLink("How to Make Ghusl", destination: GhuslView())
                    guideLink("How to Pray Jumuah", destination: JumuahView())
                    guideLink("How to Give the Adhan", destination: AdhanOtherView())
                    guideLink("How to Give the Iqamah", destination: IqamahView())
                }

                Section(header: Text("EID")) {
                    guideLink("How to Pray Eid", destination: TakbiratView())
                }
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How-To Guides")
    }

    // @autoclosure so call sites keep reading naturally while the destination struct is only ever
    // constructed when the row is actually pushed (see LazyDestination).
    private func guideLink<Destination: View>(_ title: String, destination: @autoclosure @escaping () -> Destination) -> some View {
        NavigationLink(destination: LazyDestination(build: destination)) {
            Text(title)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - How-to guides (practical, step-by-step)

/// Further practical reading for a guide - links that actually explain HOW to perform the act (IslamQA
/// answers and the like). Deliberately NOT a bibliography: the Quran verses and hadiths that ground a guide
/// are quoted inside the guide's own text, where the reader is, not stashed behind reference links.
struct GuideSourcesSection: View {
    @ObservedObject private var settings = Settings.shared

    let sources: [(title: String, subtitle: String, url: String)]

    var body: some View {
        Section {
            ForEach(sources, id: \.url) { source in
                if let url = URL(string: source.url) {
                    Link(destination: url) {
                        HStack(spacing: 10) {
                            Image(systemName: "book.closed")
                                .font(.footnote)
                                .foregroundColor(settings.accentColor.color)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(source.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)

                                Text(source.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer(minLength: 4)

                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        } header: {
            Text("SOURCES & FURTHER READING")
        } footer: {
            Text("Every ruling above traces back to the Quran and the authentic Sunnah. These links open the sources themselves. Read them, and ask a qualified scholar about anything specific to your situation.")
        }
    }
}

struct HowToPrayView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: prayer (**Salah, صَلَاة**) is performed facing the Qibla after purifying yourself, moving through standing, bowing, and prostrating while reciting the Quran and remembering Allah, praying as the Prophet (peace and blessings be upon him) prayed.")
                        .font(.body)
                }

                Section(header: Text("BEFORE YOU PRAY")) {
                    Text("1. **Purity (Taharah, طَهَارَة)**: have valid **Wudhu (وُضُوء)**, or Ghusl if required, with a clean body, clothes, and place of prayer.").font(.body)
                    Text("2. **Cover the Awrah (عَورَة)**: men from the navel to the knee at least; women cover everything except the face and hands.").font(.body)
                    Text("3. **Face the Qibla (قِبلَة)**: the direction of the Kaaba in Makkah.").font(.body)
                    Text("4. **Correct time**: each prayer has its own window: Fajr, Dhuhr, Asr, Maghrib, and Isha.").font(.body)
                    Text("5. **Intention (Niyyah, نِيَّة)**: intend the specific prayer in the heart; it is not spoken aloud.").font(.body)
                }

                Section(header: Text("NUMBER OF UNITS (RAKAH)")) {
                    Text("The obligatory **rak'ah (رَكعَة)** are: **Fajr** 2 · **Dhuhr** 4 · **Asr** 4 · **Maghrib** 3 · **Isha** 4.")
                        .font(.body)
                }

                Section(header: Text("STEP BY STEP")) {
                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", arabic: "وَصَلُّوا كَمَا رَأَيْتُمُونِي أُصَلِّي", dimmed: true)
                    Text("1. **Takbir (تَكبِير)**: raise the hands and say “Allahu Akbar,” then place the right hand over the left upon the chest.").font(.body)
                    Text("2. **Recitation**: say the opening supplication, then recite Surah **Al-Fatiha (الفَاتِحَة)**, required in every rak'ah, followed by another passage of the Quran in the first two rak'ah.").font(.body)
                    Text("3. **Ruku (رُكُوع)**: bow with a straight back, hands on the knees, saying “Subhana Rabbi al-Adheem” three times.").font(.body)
                    Text("4. **Rising (I'tidal)**: rise saying “Sami'a Allahu liman hamidah,” then, standing, “Rabbana wa laka al-hamd.”").font(.body)
                    Text("5. **Sujud (سُجُود)**: prostrate on seven parts (the forehead and nose, both palms, both knees, and the toes), saying “Subhana Rabbi al-A'la” three times.").font(.body)
                    Text("6. **Sit** and say “Rabbi ighfir li,” then make a second **Sujud** the same way. This completes one rak'ah; stand for the next.").font(.body)
                    Text("7. **Tashahhud (تَشَهُّد)**: after every two rak'ah, sit and recite the tashahhud; in the final sitting add the prayers upon the Prophet (peace and blessings be upon him) and supplication.").font(.body)
                    Text("8. **Taslim (تَسلِيم)**: end the prayer by turning the face to the right, then the left, saying each time “As-salamu alaykum wa rahmatullah.”").font(.body)
                }

                Section(header: Text("THE COMMAND TO PRAY")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“And establish prayer and give zakah and bow with those who bow” (Quran 2:43).", arabic: "وَأَقِيمُواْ ٱلصَّلَوٰةَ وَءَاتُواْ ٱلزَّكَوٰةَ وَٱرۡكَعُواْ مَعَ ٱلرَّٰكِعِينَ")

                    ScriptureQuote(text: "“Indeed, prayer has been decreed upon the believers a decree of specified times” (Quran 4:103).", arabic: "إِنَّ ٱلصَّلَوٰةَ كَانَتۡ عَلَى ٱلۡمُؤۡمِنِينَ كِتَٰبٗا مَّوۡقُوتٗا")

                    ScriptureQuote(text: "“Maintain with care the [obligatory] prayers and [in particular] the middle prayer and stand before Allah, devoutly obedient” (Quran 2:238).", arabic: "حَٰفِظُواْ عَلَى ٱلصَّلَوَٰتِ وَٱلصَّلَوٰةِ ٱلۡوُسۡطَىٰ وَقُومُواْ لِلَّهِ قَٰنِتِينَ")

                    ScriptureQuote(text: "“Indeed, prayer prohibits immorality and wrongdoing, and the remembrance of Allah is greater” (Quran 29:45).", arabic: "إِنَّ ٱلصَّلَوٰةَ تَنۡهَىٰ عَنِ ٱلۡفَحۡشَآءِ وَٱلۡمُنكَرِۗ وَلَذِكۡرُ ٱللَّهِ أَكۡبَرُۗ")
                }

                Section(header: Text("ITS PLACE AND ITS WEIGHT")) {
                    Text("The prayer is the first thing a person will be asked about. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The first thing for which a person will be brought to account on the Day of Resurrection is his prayer. If it is sound, he will have prospered and succeeded; and if it is unsound, he will have failed and lost” (Sunan al-Tirmidhi 413; graded sahih by al-Albani).", arabic: "إِنَّ أَوَّلَ مَا يُحَاسَبُ بِهِ الْعَبْدُ يَوْمَ الْقِيَامَةِ مِنْ عَمَلِهِ صَلاَتُهُ فَإِنْ صَلُحَتْ فَقَدْ أَفْلَحَ وَأَنْجَحَ وَإِنْ فَسَدَتْ فَقَدْ خَابَ وَخَسِرَ", dimmed: true)

                    Text("It is the line between belief and disbelief:")
                        .font(.body)
                    ScriptureQuote(text: "“Between a man and shirk and kufr is the abandonment of prayer” (Sahih Muslim 82).", arabic: "إِنَّ بَيْنَ الرَّجُلِ وَبَيْنَ الشِّرْكِ وَالْكُفْرِ تَرْكَ الصَّلاَةِ", dimmed: true)

                    Text("And it washes a person clean:")
                        .font(.body)
                    ScriptureQuote(text: "“If there was a river at the door of any of you, and he bathed in it five times a day, would any dirt remain on him? They said: No dirt would remain on him. He said: That is the example of the five daily prayers; by them Allah wipes away sins” (Sahih al-Bukhari 528, Sahih Muslim 667).", arabic: "أَرَأَيْتُمْ لَوْ أَنَّ نَهَرًا بِبَابِ أَحَدِكُمْ، يَغْتَسِلُ فِيهِ كُلَّ يَوْمٍ خَمْسًا، مَا تَقُولُ ذَلِكَ يُبْقِي مِنْ دَرَنِهِ. قَالُوا لاَ يُبْقِي مِنْ دَرَنِهِ شَيْئًا. قَالَ فَذَلِكَ مِثْلُ الصَّلَوَاتِ الْخَمْسِ، يَمْحُو اللَّهُ بِهَا الْخَطَايَا", dimmed: true)

                    Text("Praying in congregation multiplies it further:")
                        .font(.body)
                    ScriptureQuote(text: "“Prayer in congregation is twenty-seven times superior to the prayer offered by a person alone” (Sahih al-Bukhari 645, Sahih Muslim 650).", arabic: "صَلاَةُ الْجَمَاعَةِ تَفْضُلُ صَلاَةَ الْفَذِّ بِسَبْعٍ وَعِشْرِينَ دَرَجَةً", dimmed: true)

                    Text("And its calm is a mercy. The Prophet (peace and blessings be upon him) would say to Bilal:")
                        .font(.body)
                    ScriptureQuote(text: "“O Bilal, call the iqamah for the prayer; give us comfort by it” (Sunan Abi Dawud 4985; graded sahih by al-Albani).", arabic: "يَا بِلاَلُ أَقِمِ الصَّلاَةَ أَرِحْنَا بِهَا", dimmed: true)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Purify yourself, face the Qibla, and pray with presence of heart (Takbir, Fatiha, Ruku, Sujud, Tashahhud, and Taslim), exactly as the Prophet (peace and blessings be upon him) taught.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Pray: Description of the Prophet's Prayer", subtitle: "Step-by-step guide, IslamQA", url: "https://islamqa.info/en/answers/13340"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray")
    }
}

struct HowToFastView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: to fast (**Sawm, صَوم**) is to abstain from food, drink, and intimacy from dawn (**Fajr**) to sunset (**Maghrib**) with the intention of seeking Allah's pleasure, especially in Ramadan.")
                        .font(.body)
                }

                Section(header: Text("1. MAKE THE INTENTION")) {
                    Text("Form the **Niyyah (نِيَّة)** to fast in the heart before **Fajr**. For an obligatory Ramadan fast, intend it the night before. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever does not resolve to fast before dawn, there is no fast for him” (Sunan Abi Dawud 2454; graded sahih by al-Albani).", arabic: "مَنْ لَمْ يُجْمِعِ الصِّيَامَ قَبْلَ الْفَجْرِ فَلاَ صِيَامَ لَهُ", dimmed: true)
                }

                Section(header: Text("2. EAT SUHOOR")) {
                    Text("Take the pre-dawn meal, **Suhoor (سُحُور)**, which is a blessed Sunnah, and stop eating and drinking at the entry of **Fajr**.").font(.body)
                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Take Suhoor, for in Suhoor there is a blessing” (Sahih al-Bukhari 1923).", arabic: "تَسَحَّرُوا فَإِنَّ فِي السَّحُورِ بَرَكَةً", dimmed: true)
                }

                Section(header: Text("3. FAST THROUGH THE DAY")) {
                    Text("From Fajr to Maghrib, abstain from food, drink, and intimacy. The fast is also of the limbs and tongue: guard against lying, backbiting, and anger.").font(.body)
                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Whoever does not give up false speech and acting upon it, Allah has no need of his giving up his food and drink” (Sahih al-Bukhari 1903).", arabic: "مَنْ لَمْ يَدَعْ قَوْلَ الزُّورِ وَالْعَمَلَ بِهِ فَلَيْسَ لِلَّهِ حَاجَةٌ فِي أَنْ يَدَعَ طَعَامَهُ وَشَرَابَهُ", dimmed: true)
                }

                Section(header: Text("4. BREAK THE FAST AT MAGHRIB")) {
                    Text("Break the fast (**Iftar, إِفطَار**) as soon as the sun sets. Hastening it is the Sunnah:")
                        .font(.body)
                    ScriptureQuote(text: "“The people will remain upon goodness as long as they hasten to break the fast” (Sahih al-Bukhari 1957).", arabic: "لاَ يَزَالُ النَّاسُ بِخَيْرٍ مَا عَجَّلُوا الْفِطْرَ", dimmed: true)
                    Text("Anas (may Allah be pleased with him) described how the Prophet (peace and blessings be upon him) broke his fast:")
                        .font(.body)
                    ScriptureQuote(text: "“The Messenger of Allah would break his fast with fresh dates before praying; if there were no fresh dates, then with dried dates; and if there were no dried dates, he would take a few sips of water” (Sunan Abi Dawud 2356; graded hasan sahih by al-Albani).", arabic: "كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يُفْطِرُ عَلَى رُطَبَاتٍ قَبْلَ أَنْ يُصَلِّيَ فَإِنْ لَمْ تَكُنْ رُطَبَاتٌ فَعَلَى تَمَرَاتٍ فَإِنْ لَمْ تَكُنْ حَسَا حَسَوَاتٍ مِنْ مَاءٍ", dimmed: true)
                    Text("And he would say when he broke his fast:")
                        .font(.body)
                    ScriptureQuote(text: "“Thirst has gone, the veins are moistened, and the reward is certain, if Allah wills” (Sunan Abi Dawud 2357; graded hasan by al-Albani).", arabic: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ", dimmed: true)
                }

                Section(header: Text("WHAT INVALIDATES THE FAST")) {
                    Text("Deliberately eating or drinking, intentional intimacy, and the onset of menstruation or postpartum bleeding break the fast. Eating or drinking by genuine forgetfulness does not; one simply continues fasting. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“If someone forgets and eats or drinks, let him complete his fast, for it is Allah who fed him and gave him drink” (Sahih al-Bukhari 1933).", arabic: "إِذَا نَسِيَ فَأَكَلَ وَشَرِبَ فَلْيُتِمَّ صَوْمَهُ، فَإِنَّمَا أَطْعَمَهُ اللَّهُ وَسَقَاهُ", dimmed: true)
                }

                Section(header: Text("WHO IS EXCUSED")) {
                    Text("The sick, travelers, pregnant and nursing women, and the elderly who cannot fast are excused; missed fasts are made up later, or a **Fidyah (فِديَة)** (feeding a needy person per day) is given by those unable to fast at all. Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“So whoever among you is ill or on a journey [during them] - then an equal number of days [are to be made up]. And upon those who are able [to fast, but with hardship] - a ransom [as substitute] of feeding a poor person [each day]” (Quran 2:184).", arabic: "فَمَن كَانَ مِنكُم مَّرِيضًا أَوۡ عَلَىٰ سَفَرٖ فَعِدَّةٞ مِّنۡ أَيَّامٍ أُخَرَۚ وَعَلَى ٱلَّذِينَ يُطِيقُونَهُۥ فِدۡيَةٞ طَعَامُ مِسۡكِينٖۖ")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Intend the fast, take Suhoor, abstain from dawn to sunset while guarding your character, then hasten to break the fast at Maghrib, turning the whole day into worship and gratitude.")
                        .font(.body)
                }

                Section(header: Text("WHY WE FAST")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, decreed upon you is fasting as it was decreed upon those before you, that you may become righteous” (Quran 2:183).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ كُتِبَ عَلَيۡكُمُ ٱلصِّيَامُ كَمَا كُتِبَ عَلَى ٱلَّذِينَ مِن قَبۡلِكُمۡ لَعَلَّكُمۡ تَتَّقُونَ")
                    ScriptureQuote(text: "“The month of Ramadan [is that] in which was revealed the Quran, a guidance for the people and clear proofs of guidance and criterion” (Quran 2:185).", arabic: "شَهۡرُ رَمَضَانَ ٱلَّذِيٓ أُنزِلَ فِيهِ ٱلۡقُرۡءَانُ هُدٗى لِّلنَّاسِ وَبَيِّنَٰتٖ مِّنَ ٱلۡهُدَىٰ وَٱلۡفُرۡقَانِۚ")
                    Text("The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah said: Every deed of the son of Adam is for him, except fasting; it is for Me, and I shall reward for it” (Sahih al-Bukhari 1904, Sahih Muslim 1151).", arabic: "قَالَ اللَّهُ كُلُّ عَمَلِ ابْنِ آدَمَ لَهُ إِلاَّ الصِّيَامَ، فَإِنَّهُ لِي، وَأَنَا أَجْزِي بِهِ", dimmed: true)
                    ScriptureQuote(text: "“Whoever fasts Ramadan out of faith and seeking reward, his previous sins will be forgiven” (Sahih al-Bukhari 38, Sahih Muslim 760).", arabic: "مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ", dimmed: true)
                    ScriptureQuote(text: "“There is a gate in Paradise called Ar-Rayyan, through which those who fast will enter on the Day of Resurrection, and no one but they will enter it” (Sahih al-Bukhari 1896).", arabic: "إِنَّ فِي الْجَنَّةِ بَابًا يُقَالُ لَهُ الرَّيَّانُ، يَدْخُلُ مِنْهُ الصَّائِمُونَ يَوْمَ الْقِيَامَةِ، لاَ يَدْخُلُ مِنْهُ أَحَدٌ غَيْرُهُمْ يُقَالُ أَيْنَ الصَّائِمُونَ فَيَقُومُونَ، لاَ يَدْخُلُ مِنْهُ أَحَدٌ غَيْرُهُمْ، فَإِذَا دَخَلُوا أُغْلِقَ، فَلَمْ يَدْخُلْ مِنْهُ أَحَدٌ", dimmed: true)
                }

                GuideSourcesSection(sources: [
                    (title: "Rulings on Fasting", subtitle: "How to fast, and what breaks it, IslamQA", url: "https://islamqa.info/en/categories/topics/78/fasting"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Fast")
    }
}

struct HowToZakahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: **Zakah (زَكَاة)** is the obligatory annual charity of **2.5%** on wealth that reaches the **Nisab (نِصَاب)** and is held for a full lunar year, given to those Allah named as its recipients.")
                        .font(.body)
                }

                Section(header: Text("1. CHECK IF YOU MUST PAY")) {
                    Text("Zakah is due on a Muslim whose zakatable wealth reaches the **Nisab (نِصَاب)**, the minimum threshold (equal to about **85 grams of gold** or **595 grams of silver**), and has been held for one full lunar (Hijri) year (**Hawl, حَول**).")
                        .font(.body)
                }

                Section(header: Text("2. TOTAL YOUR ZAKATABLE WEALTH")) {
                    Text("Include cash and savings, gold and silver, money owed to you that you expect back, business merchandise, and investments held for gain. Personal items (your home, car, and everyday belongings) are not counted.")
                        .font(.body)
                }

                Section(header: Text("3. CALCULATE 2.5%")) {
                    Text("If your total is at or above the Nisab after the year has passed, give **2.5%** (one fortieth) of it. Many choose to pay in Ramadan for the extra reward, though it may be paid whenever the year completes.")
                        .font(.body)
                }

                Section(header: Text("4. GIVE IT TO THOSE ENTITLED")) {
                    Text("Allah (Glorified and Exalted be He) named eight categories of recipients:").font(.body)
                    ScriptureQuote(text: "“Zakah expenditures are only for the poor and for the needy and for those employed to collect [it] and for bringing hearts together [for Islam] and for freeing captives [or slaves] and for those in debt and for the cause of Allah and for the [stranded] traveler” (Quran 9:60).", arabic: "إِنَّمَا ٱلصَّدَقَٰتُ لِلۡفُقَرَآءِ وَٱلۡمَسَٰكِينِ وَٱلۡعَٰمِلِينَ عَلَيۡهَا وَٱلۡمُؤَلَّفَةِ قُلُوبُهُمۡ وَفِي ٱلرِّقَابِ وَٱلۡغَٰرِمِينَ وَفِي سَبِيلِ ٱللَّهِ وَٱبۡنِ ٱلسَّبِيلِۖ")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Once your wealth reaches the Nisab and a lunar year passes, give 2.5% of it to the deserving, purifying your wealth, helping the needy, and fulfilling a pillar of Islam.")
                        .font(.body)
                }

                Section(header: Text("WHY WE GIVE ZAKAH")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“Take from their wealth a charity by which you purify them and cause them increase, and invoke [Allah's blessings] upon them” (Quran 9:103).", arabic: "خُذۡ مِنۡ أَمۡوَٰلِهِمۡ صَدَقَةٗ تُطَهِّرُهُمۡ وَتُزَكِّيهِم بِهَا وَصَلِّ عَلَيۡهِمۡۖ")
                    ScriptureQuote(text: "“And establish prayer and give zakah, and whatever good you put forward for yourselves, you will find it with Allah” (Quran 2:110).", arabic: "وَأَقِيمُواْ ٱلصَّلَوٰةَ وَءَاتُواْ ٱلزَّكَوٰةَۚ وَمَا تُقَدِّمُواْ لِأَنفُسِكُم مِّنۡ خَيۡرٖ تَجِدُوهُ عِندَ ٱللَّهِۗ")
                    Text("It is not a favour to the poor. It is their right in your wealth, and withholding it is a warning:")
                        .font(.body)
                    ScriptureQuote(text: "“And let not those who [greedily] withhold what Allah has given them of His bounty ever think that it is better for them. Rather, it is worse for them. Their necks will be encircled by what they withheld on the Day of Resurrection” (Quran 3:180).", arabic: "وَلَا يَحۡسَبَنَّ ٱلَّذِينَ يَبۡخَلُونَ بِمَآ ءَاتَىٰهُمُ ٱللَّهُ مِن فَضۡلِهِۦ هُوَ خَيۡرٗا لَّهُمۖ بَلۡ هُوَ شَرّٞ لَّهُمۡۖ سَيُطَوَّقُونَ مَا بَخِلُواْ بِهِۦ يَوۡمَ ٱلۡقِيَٰمَةِۗ")
                    Text("When the Prophet (peace and blessings be upon him) sent Mu'adh to Yemen, he told him:")
                        .font(.body)
                    ScriptureQuote(text: "“Teach them that Allah has enjoined upon them a charity in their wealth, to be taken from their rich and given to their poor” (Sahih al-Bukhari 1395, Sahih Muslim 19).", arabic: "فَأَعْلِمْهُمْ أَنَّ اللَّهَ افْتَرَضَ عَلَيْهِمْ صَدَقَةً فِي أَمْوَالِهِمْ، تُؤْخَذُ مِنْ أَغْنِيَائِهِمْ وَتُرَدُّ عَلَى فُقَرَائِهِمْ", dimmed: true)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Calculate and Give Zakah", subtitle: "Nisab, rates, and recipients, IslamQA", url: "https://islamqa.info/en/categories/topics/79/zakah"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Give Zakah")
    }
}

struct HowToHajjView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: **Hajj (حَجّ)** is the pilgrimage to Makkah performed once in a lifetime by those able, over the days of **Dhul-Hijjah**: entering Ihram, standing at Arafah, and completing the rites the Prophet (peace and blessings be upon him) taught.")
                        .font(.body)
                }

                Section(header: Text("BEFORE YOU GO")) {
                    Text("Hajj is obligatory once for every Muslim who is physically and financially able. Repent sincerely, settle debts, seek lawful provision, and learn the rites. Hajj takes place from the 8th to the 13th of **Dhul-Hijjah (ذُو الحِجَّة)**.")
                        .font(.body)
                }

                Section(header: Text("1. ENTER IHRAM")) {
                    Text("At the appointed boundary (**Miqat, مِيقَات**), bathe, wear the Ihram garments (two unstitched cloths for men; ordinary modest dress for women), make the intention for Hajj, and begin the **Talbiyah (تَلبِيَة)**. Ibn Umar (may Allah be pleased with him) reported the Talbiyah of the Messenger of Allah (peace and blessings be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“Labbayk Allahumma labbayk, labbayka la sharika laka labbayk, innal-hamda wan-ni'mata laka wal-mulk, la sharika lak: Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Indeed all praise, favour and sovereignty are Yours; You have no partner” (Sahih al-Bukhari 1549).", arabic: "لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لاَ شَرِيكَ لَكَ", dimmed: true)
                }

                Section(header: Text("2. DAY 8: MINA")) {
                    Text("Travel to **Mina (مِنَى)** and pray Dhuhr, Asr, Maghrib, Isha, and Fajr there, each at its time (the four-unit prayers shortened to two).")
                        .font(.body)
                }

                Section(header: Text("3. DAY 9: ARAFAH")) {
                    Text("After sunrise proceed to **Arafah (عَرَفَة)** and stand there in supplication until sunset; this standing (**Wuquf**) is the essence of Hajj. Dhuhr and Asr are combined and shortened. The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Hajj is Arafah. Whoever comes on the night of Muzdalifah before dawn breaks has caught the Hajj. The days of Mina are three; whoever hastens away after two days, there is no sin upon him, and whoever stays on, there is no sin upon him” (Sunan al-Tirmidhi 889; graded sahih by al-Albani).", arabic: "الْحَجُّ عَرَفَةُ مَنْ جَاءَ لَيْلَةَ جَمْعٍ قَبْلَ طُلُوعِ الْفَجْرِ فَقَدْ أَدْرَكَ الْحَجَّ أَيَّامُ مِنًى ثَلاَثَةٌ فَمَنْ تَعَجَّلَ فِي يَوْمَيْنِ فَلاَ إِثْمَ عَلَيْهِ وَمَنْ تَأَخَّرَ فَلاَ إِثْمَ عَلَيْهِ", dimmed: true)
                    Text("After sunset, move to **Muzdalifah (مُزدَلِفَة)**, combine Maghrib and Isha, rest for the night, and gather pebbles.").font(.body)
                }

                Section(header: Text("4. DAY 10: EID (YAWM AN-NAHR)")) {
                    Text("Stone the large pillar (**Jamrat al-Aqabah**) with seven pebbles, offer the sacrifice (**Hady/Qurbani, قُربَان**), shave or trim the hair, then perform **Tawaf al-Ifadah** around the Kaaba and **Sa'i (سَعي)** between Safa and Marwah. With this the pilgrim exits Ihram.")
                        .font(.body)
                }

                Section(header: Text("5. DAYS 11–13: TASHREEQ")) {
                    Text("Stay in Mina and stone the three pillars (**Jamarat**) each afternoon. A pilgrim may leave after the 12th if he departs before sunset, otherwise he completes the 13th.")
                        .font(.body)
                }

                Section(header: Text("6. FAREWELL TAWAF")) {
                    Text("Before leaving Makkah, perform the farewell circumambulation (**Tawaf al-Wada, طَوَاف الوَدَاع**) so the last act at the Sacred House is Tawaf.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Enter Ihram at the Miqat, stand at Arafah, spend the night at Muzdalifah, then on Eid stone, sacrifice, shave, and perform Tawaf and Sa'i, completing the days of Mina and a farewell Tawaf, returning cleansed of sin.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Perform Hajj: Description of Hajj", subtitle: "Every rite in order, IslamQA", url: "https://islamqa.info/en/answers/31822/description-of-hajj"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Perform Hajj")
    }
}

struct HowToUmrahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: **Umrah (عُمرَة)**, the “lesser pilgrimage,” which may be done at any time of year, is Ihram, Tawaf around the Kaaba, Sa'i between Safa and Marwah, and shaving or trimming the hair.")
                        .font(.body)
                }

                Section(header: Text("1. ENTER IHRAM")) {
                    Text("At the **Miqat (مِيقَات)**, bathe, wear the Ihram (two unstitched cloths for men; modest dress for women), make the intention for Umrah with the words “Labbayk Allahumma umratan” (here I am, O Allah, for Umrah), then recite the **Talbiyah (تَلبِيَة)** of the Prophet (peace and blessings be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“Labbayk Allahumma labbayk, labbayka la sharika laka labbayk, innal-hamda wan-ni'mata laka wal-mulk, la sharika lak: Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Indeed all praise, favour and sovereignty are Yours; You have no partner” (Sahih al-Bukhari 1549).", arabic: "لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لاَ شَرِيكَ لَكَ", dimmed: true)
                    Text("In Ihram, avoid perfume, cutting hair or nails, and marital relations.")
                        .font(.body)
                }

                Section(header: Text("2. TAWAF")) {
                    Text("At the Sacred Mosque, circle the **Kaaba (الكَعبَة)** seven times (**Tawaf, طَوَاف**), beginning and ending at the Black Stone. Then pray two rak'ah behind the **Maqam Ibrahim (مَقَام إِبرَاهِيم)** if able, and drink **Zamzam (زَمزَم)**.")
                        .font(.body)
                }

                Section(header: Text("3. SA'I")) {
                    Text("Walk seven times between the hills of **Safa (الصَّفَا)** and **Marwah (المَروَة)** (**Sa'i, سَعي**), starting at Safa and ending at Marwah, remembering Allah and supplicating, as **Hajar** (may Allah be pleased with her) once searched there for water.")
                        .font(.body)
                }

                Section(header: Text("4. SHAVE OR TRIM")) {
                    Text("Men shave the head (**Halq, حَلق**) or trim it; women trim a fingertip's length (**Taqsir, تَقصِير**). With this the Umrah is complete and the pilgrim leaves the state of Ihram.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Enter Ihram at the Miqat, perform Tawaf around the Kaaba, make Sa'i between Safa and Marwah, and shave or trim, a complete Umrah that may be done any time of the year.")
                        .font(.body)
                }

                Section(header: Text("THE VIRTUE OF UMRAH")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“And complete the Hajj and Umrah for Allah” (Quran 2:196).", arabic: "وَأَتِمُّواْ ٱلۡحَجَّ وَٱلۡعُمۡرَةَ لِلَّهِۚ")
                    Text("The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Umrah to Umrah is an expiation for whatever comes between them, and the accepted Hajj has no reward but Paradise” (Sahih al-Bukhari 1773, Sahih Muslim 1349).", arabic: "الْعُمْرَةُ إِلَى الْعُمْرَةِ كَفَّارَةٌ لِمَا بَيْنَهُمَا، وَالْحَجُّ الْمَبْرُورُ لَيْسَ لَهُ جَزَاءٌ إِلاَّ الْجَنَّةُ", dimmed: true)
                    ScriptureQuote(text: "“Umrah in Ramadan is equivalent to Hajj” (Sahih al-Bukhari 1782, Sahih Muslim 1256).", arabic: "فَإِنَّ عُمْرَةً فِي رَمَضَانَ حَجَّةٌ", dimmed: true)
                    Text("And of the journey itself he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Follow Hajj with Umrah and Umrah with Hajj, for the two of them remove poverty and sins as the bellows removes the dross of iron, gold and silver, and there is no reward for an accepted Hajj except Paradise” (Sunan al-Tirmidhi 810; graded hasan sahih by al-Albani).", arabic: "تَابِعُوا بَيْنَ الْحَجِّ وَالْعُمْرَةِ فَإِنَّهُمَا يَنْفِيَانِ الْفَقْرَ وَالذُّنُوبَ كَمَا يَنْفِي الْكِيرُ خَبَثَ الْحَدِيدِ وَالذَّهَبِ وَالْفِضَّةِ وَلَيْسَ لِلْحَجَّةِ الْمَبْرُورَةِ ثَوَابٌ إِلاَّ الْجَنَّةُ", dimmed: true)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Perform Umrah", subtitle: "Ihram, tawaf, sa'i, and cutting the hair, IslamQA", url: "https://islamqa.info/en/answers/154979"),
                ])
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Perform Umrah")
    }
}

import SwiftUI
