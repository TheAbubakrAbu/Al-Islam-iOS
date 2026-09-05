import SwiftUI

/// The How-to Guides index. Rows come from `IslamArticleCatalog.guidesGroups`, the same list the
/// search reads, so a result can say which section a guide sits in - see PillarsView for the shape.
struct GuidesView: View {
    #if os(iOS)
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The index row a result asked to scroll to ("Scroll To Article"), consumed once the search clears.
    @State private var scrollTarget: String?
    @StateObject private var search = IslamArticleSearchModel()
    #endif

    var body: some View {
        #if os(iOS)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        ScrollViewReader { proxy in
            List {
                #if DEBUG
                DebugArticleLink(articles: IslamArticleCatalog.debugArticles(for: .guides), argument: "-guidesArticle")
                #endif

                Group {
                    if query.isEmpty {
                        IslamArticleIndexSections(groups: IslamArticleCatalog.guidesGroups)
                    } else {
                        AskAISearchSection(query: query)

                        IslamArticleSearchSections(
                            query: query,
                            homes: [.guides],
                            contentHits: search.contentHits,
                            isSearching: search.isSearching
                        ) { entry in
                            withAnimation { searchText = "" }
                            scrollTarget = entry.listID
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .islamArticleIndexSearch(searchText: $searchText, barsCollapsed: $barsCollapsed,
                                     scrollTarget: scrollTarget, proxy: proxy)
        }
        .navigationTitle("How-To Guides")
        .onAppear {
            IslamArticleSearchModel.prewarm()
            #if DEBUG
            if let seeded = IslamSearchDebug.launchQuery("-guidesSearch"), searchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { searchText = seeded }
            }
            #endif
        }
        .onChange(of: searchText) { text in
            search.update(query: text, homes: [.guides])
            if !text.isEmpty { scrollTarget = nil }
        }
        #else
        List {
            IslamArticleIndexSections(groups: IslamArticleCatalog.guidesGroups)
                .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How-To Guides")
        #endif
    }
}

// MARK: - How-to guides (practical, step-by-step)

/// Further practical reading for a guide - links that actually explain HOW to perform the act (IslamQA
/// answers and the like). Deliberately NOT a bibliography: the Quran verses and hadiths that ground a guide
/// are quoted inside the guide's own text, where the reader is, not stashed behind reference links.
struct GuideSourcesSection: View {
    @Environment(\.appearance) private var appearance

    let sources: [(title: String, subtitle: String, url: String)]

    var body: some View {
        Section {
            ForEach(sources, id: \.url) { source in
                if let url = URL(string: source.url) {
                    Link(destination: url) {
                        HStack(spacing: 10) {
                            Image(systemName: "book.closed")
                                .font(.footnote)
                                .foregroundColor(appearance.accent)

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
            Text(articleMarkdown: "SOURCES & FURTHER READING")
        } footer: {
            Text(verbatim: "Every ruling above traces back to the Quran and the authentic Sunnah. These links open the sources themselves. Read them, and ask a qualified scholar about anything specific to your situation.")
        }
    }
}

struct HowToPrayView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: prayer (**Salah, صَلَاة**) is performed facing the Qibla after purifying yourself, moving through standing, bowing, and prostrating while reciting the Quran and remembering Allah, praying as the Prophet (peace and blessings be upon him) prayed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("BEFORE YOU PRAY")) {
                    Text(articleMarkdown: "1. **Purity (Taharah, طَهَارَة)**: have valid **Wudhu (وُضُوء)**, or Ghusl if required, with a clean body, clothes, and place of prayer.").font(.body)
                    Text(articleMarkdown: "2. **Cover the Awrah (عَورَة)**: men from the navel to the knee at least; women cover everything except the face and hands (and, according to most scholars, the feet as well).").font(.body)
                    Text(articleMarkdown: "3. **Face the Qibla (قِبلَة)**: the direction of the Kaaba in Makkah.").font(.body)
                    Text(articleMarkdown: "4. **Correct time**: each prayer has its own window: Fajr, Dhuhr, Asr, Maghrib, and Isha.").font(.body)
                    Text(articleMarkdown: "5. **Intention (Niyyah, نِيَّة)**: intend the specific prayer in the heart; it is not spoken aloud.").font(.body)
                }

                Section(header: ArticleHeader("NUMBER OF UNITS (RAKAH)")) {
                    Text(articleMarkdown: "The obligatory **rak'ah (رَكعَة)** are: **Fajr** 2 · **Dhuhr** 4 · **Asr** 4 · **Maghrib** 3 · **Isha** 4.")
                        .font(.body)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", arabic: "وَصَلُّوا كَمَا رَأَيْتُمُونِي أُصَلِّي", dimmed: true)
                    Text(articleMarkdown: "1. **Takbir (تَكبِير)**: raise the hands and say “Allahu Akbar,” then place the right hand over the left upon the chest.").font(.body)
                    Text(articleMarkdown: "2. **Recitation**: say the opening supplication, then recite Surah **Al-Fatiha (الفَاتِحَة)**, required in every rak'ah, followed by another passage of the Quran in the first two rak'ah.").font(.body)
                    Text(articleMarkdown: "3. **Ruku (رُكُوع)**: bow with a straight back, hands on the knees, saying “Subhana Rabbi al-Adheem” three times.").font(.body)
                    Text(articleMarkdown: "4. **Rising (I'tidal)**: rise saying “Sami'a Allahu liman hamidah,” then, standing, “Rabbana wa laka al-hamd.”").font(.body)
                    Text(articleMarkdown: "5. **Sujud (سُجُود)**: prostrate on seven parts (the forehead and nose, both palms, both knees, and the toes), saying “Subhana Rabbi al-A'la” three times.").font(.body)
                    Text(articleMarkdown: "6. **Sit** and say “Rabbi ighfir li,” then make a second **Sujud** the same way. This completes one rak'ah; stand for the next.").font(.body)
                    Text(articleMarkdown: "7. **Tashahhud (تَشَهُّد)**: after every two rak'ah, sit and recite the tashahhud; in the final sitting add the prayers upon the Prophet (peace and blessings be upon him) and supplication.").font(.body)
                    Text(articleMarkdown: "8. **Taslim (تَسلِيم)**: end the prayer by turning the face to the right, then the left, saying each time “As-salamu alaykum wa rahmatullah.”").font(.body)
                }

                Section(header: ArticleHeader("THE COMMAND TO PRAY")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“And establish prayer and give zakah and bow with those who bow” (Quran 2:43).", arabic: "وَأَقِيمُواْ ٱلصَّلَوٰةَ وَءَاتُواْ ٱلزَّكَوٰةَ وَٱرۡكَعُواْ مَعَ ٱلرَّٰكِعِينَ")

                    ScriptureQuote(text: "“Indeed, prayer has been decreed upon the believers a decree of specified times” (Quran 4:103).", arabic: "إِنَّ ٱلصَّلَوٰةَ كَانَتۡ عَلَى ٱلۡمُؤۡمِنِينَ كِتَٰبٗا مَّوۡقُوتٗا")

                    ScriptureQuote(text: "“Maintain with care the [obligatory] prayers and [in particular] the middle prayer and stand before Allah, devoutly obedient” (Quran 2:238).", arabic: "حَٰفِظُواْ عَلَى ٱلصَّلَوَٰتِ وَٱلصَّلَوٰةِ ٱلۡوُسۡطَىٰ وَقُومُواْ لِلَّهِ قَٰنِتِينَ")

                    ScriptureQuote(text: "“Indeed, prayer prohibits immorality and wrongdoing, and the remembrance of Allah is greater” (Quran 29:45).", arabic: "إِنَّ ٱلصَّلَوٰةَ تَنۡهَىٰ عَنِ ٱلۡفَحۡشَآءِ وَٱلۡمُنكَرِۗ وَلَذِكۡرُ ٱللَّهِ أَكۡبَرُۗ")
                }

                Section(header: ArticleHeader("ITS PLACE AND ITS WEIGHT")) {
                    Text(verbatim: "The prayer is the first thing a person will be asked about. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed the first deed by which a servant will be called to account on the Day of Resurrection is his Salat. If it is complete, he is successful and saved, but if it is defective, he has failed and lost” (Sunan al-Tirmidhi 413; graded sahih by al-Albani).", arabic: "إِنَّ أَوَّلَ مَا يُحَاسَبُ بِهِ الْعَبْدُ يَوْمَ الْقِيَامَةِ مِنْ عَمَلِهِ صَلاَتُهُ فَإِنْ صَلُحَتْ فَقَدْ أَفْلَحَ وَأَنْجَحَ وَإِنْ فَسَدَتْ فَقَدْ خَابَ وَخَسِرَ", dimmed: true)

                    Text(verbatim: "It is the line between belief and disbelief:")
                        .font(.body)
                    ScriptureQuote(text: "“Verily between man and between polytheism and unbelief is the negligence of prayer” (Sahih Muslim 82).", arabic: "إِنَّ بَيْنَ الرَّجُلِ وَبَيْنَ الشِّرْكِ وَالْكُفْرِ تَرْكَ الصَّلاَةِ", dimmed: true)

                    Text(verbatim: "And it washes a person clean:")
                        .font(.body)
                    ScriptureQuote(text: "“If there was a river at the door of anyone of you and he took a bath in it five times a day would you notice any dirt on him?‘ They said, ’Not a trace of dirt would be left.‘ The Prophet (ﷺ) added, ’That is the example of the five prayers with which Allah blots out (annuls) evil deeds” (Sahih al-Bukhari 528, Sahih Muslim 667).", arabic: "أَرَأَيْتُمْ لَوْ أَنَّ نَهَرًا بِبَابِ أَحَدِكُمْ، يَغْتَسِلُ فِيهِ كُلَّ يَوْمٍ خَمْسًا، مَا تَقُولُ ذَلِكَ يُبْقِي مِنْ دَرَنِهِ. قَالُوا لاَ يُبْقِي مِنْ دَرَنِهِ شَيْئًا. قَالَ فَذَلِكَ مِثْلُ الصَّلَوَاتِ الْخَمْسِ، يَمْحُو اللَّهُ بِهَا الْخَطَايَا", dimmed: true)

                    Text(verbatim: "Praying in congregation multiplies it further:")
                        .font(.body)
                    ScriptureQuote(text: "“The prayer in congregation is twenty seven times superior to the prayer offered by person alone” (Sahih al-Bukhari 645, Sahih Muslim 650).", arabic: "صَلاَةُ الْجَمَاعَةِ تَفْضُلُ صَلاَةَ الْفَذِّ بِسَبْعٍ وَعِشْرِينَ دَرَجَةً", dimmed: true)

                    Text(verbatim: "And its calm is a mercy. The Prophet (peace and blessings be upon him) would say to Bilal:")
                        .font(.body)
                    ScriptureQuote(text: "“O Bilal, call iqamah for prayer: give us comfort by it” (Sunan Abi Dawud 4985; graded sahih by al-Albani).", arabic: "يَا بِلاَلُ أَقِمِ الصَّلاَةَ أَرِحْنَا بِهَا", dimmed: true)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Purify yourself, face the Qibla, and pray with presence of heart (Takbir, Fatiha, Ruku, Sujud, Tashahhud, and Taslim), exactly as the Prophet (peace and blessings be upon him) taught.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "HowToPrayView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray")
    }
}

struct HowToFastView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: to fast (**Sawm, صَوم**) is to abstain from food, drink, and intimacy from dawn (**Fajr**) to sunset (**Maghrib**) with the intention of seeking Allah's pleasure, especially in Ramadan.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. MAKE THE INTENTION")) {
                    Text(articleMarkdown: "Form the **Niyyah (نِيَّة)** to fast in the heart before **Fajr**. For an obligatory Ramadan fast, intend it the night before. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“He who does not determine to fast before dawn does not fast” (Sunan Abi Dawud 2454; graded sahih by al-Albani).", arabic: "مَنْ لَمْ يُجْمِعِ الصِّيَامَ قَبْلَ الْفَجْرِ فَلاَ صِيَامَ لَهُ", dimmed: true)
                }

                Section(header: ArticleHeader("2. EAT SUHOOR")) {
                    Text(articleMarkdown: "Take the pre-dawn meal, **Suhoor (سُحُور)**, which is a blessed Sunnah, and stop eating and drinking at the entry of **Fajr**.").font(.body)
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Take Suhur as there is a blessing in it” (Sahih al-Bukhari 1923).", arabic: "تَسَحَّرُوا فَإِنَّ فِي السَّحُورِ بَرَكَةً", dimmed: true)
                }

                Section(header: ArticleHeader("3. FAST THROUGH THE DAY")) {
                    Text(verbatim: "From Fajr to Maghrib, abstain from food, drink, and intimacy. The fast is also of the limbs and tongue: guard against lying, backbiting, and anger.").font(.body)
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Whoever does not give up forged speech and evil actions, Allah is not in need of his leaving his food and drink (i.e. Allah will not accept his fasting.)” (Sahih al-Bukhari 1903).", arabic: "مَنْ لَمْ يَدَعْ قَوْلَ الزُّورِ وَالْعَمَلَ بِهِ فَلَيْسَ لِلَّهِ حَاجَةٌ فِي أَنْ يَدَعَ طَعَامَهُ وَشَرَابَهُ", dimmed: true)
                }

                Section(header: ArticleHeader("4. BREAK THE FAST AT MAGHRIB")) {
                    Text(articleMarkdown: "Break the fast (**Iftar, إِفطَار**) as soon as the sun sets. Hastening it is the Sunnah:")
                        .font(.body)
                    ScriptureQuote(text: "“The people will remain on the right path as long as they hasten the breaking of the fast” (Sahih al-Bukhari 1957).", arabic: "لاَ يَزَالُ النَّاسُ بِخَيْرٍ مَا عَجَّلُوا الْفِطْرَ", dimmed: true)
                    Text(verbatim: "Anas (may Allah be pleased with him) described how the Prophet (peace and blessings be upon him) broke his fast:")
                        .font(.body)
                    ScriptureQuote(text: "“The Messenger of Allah (ﷺ) used to break his fast before praying with some fresh dates; but if there were no fresh dates, he had a few dry dates, and if there were no dry dates, he took some mouthfuls of water” (Sunan Abi Dawud 2356; graded hasan sahih by al-Albani).", arabic: "كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يُفْطِرُ عَلَى رُطَبَاتٍ قَبْلَ أَنْ يُصَلِّيَ فَإِنْ لَمْ تَكُنْ رُطَبَاتٌ فَعَلَى تَمَرَاتٍ فَإِنْ لَمْ تَكُنْ حَسَا حَسَوَاتٍ مِنْ مَاءٍ", dimmed: true)
                    Text(verbatim: "And he would say when he broke his fast:")
                        .font(.body)
                    ScriptureQuote(text: "“Thirst has gone, the arteries are moist, and the reward is sure, if Allah wills” (Sunan Abi Dawud 2357; graded hasan by al-Albani).", arabic: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ", dimmed: true)
                }

                Section(header: ArticleHeader("WHAT INVALIDATES THE FAST")) {
                    Text(verbatim: "Deliberately eating or drinking, intentional intimacy, and the onset of menstruation or postpartum bleeding break the fast. Eating or drinking by genuine forgetfulness does not; one simply continues fasting. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“If somebody eats or drinks forgetfully then he should complete his fast, for what he has eaten or drunk, has been given to him by Allah” (Sahih al-Bukhari 1933).", arabic: "إِذَا نَسِيَ فَأَكَلَ وَشَرِبَ فَلْيُتِمَّ صَوْمَهُ، فَإِنَّمَا أَطْعَمَهُ اللَّهُ وَسَقَاهُ", dimmed: true)
                }

                Section(header: ArticleHeader("WHO IS EXCUSED")) {
                    Text(articleMarkdown: "The sick, travelers, pregnant and nursing women, and the elderly who cannot fast are excused; missed fasts are made up later, or a **Fidyah (فِديَة)** (feeding a needy person per day) is given by those unable to fast at all. Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“So whoever among you is ill or on a journey [during them] - then an equal number of days [are to be made up]. And upon those who are able [to fast, but with hardship] - a ransom [as substitute] of feeding a poor person [each day]” (Quran 2:184).", arabic: "فَمَن كَانَ مِنكُم مَّرِيضًا أَوۡ عَلَىٰ سَفَرٖ فَعِدَّةٞ مِّنۡ أَيَّامٍ أُخَرَۚ وَعَلَى ٱلَّذِينَ يُطِيقُونَهُۥ فِدۡيَةٞ طَعَامُ مِسۡكِينٖۖ")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Intend the fast, take Suhoor, abstain from dawn to sunset while guarding your character, then hasten to break the fast at Maghrib, turning the whole day into worship and gratitude.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHY WE FAST")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, decreed upon you is fasting as it was decreed upon those before you, that you may become righteous” (Quran 2:183).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ كُتِبَ عَلَيۡكُمُ ٱلصِّيَامُ كَمَا كُتِبَ عَلَى ٱلَّذِينَ مِن قَبۡلِكُمۡ لَعَلَّكُمۡ تَتَّقُونَ")
                    ScriptureQuote(text: "“The month of Ramadhan [is that] in which was revealed the Qur'an, a guidance for the people and clear proofs of guidance and criterion” (Quran 2:185).", arabic: "شَهۡرُ رَمَضَانَ ٱلَّذِيٓ أُنزِلَ فِيهِ ٱلۡقُرۡءَانُ هُدٗى لِّلنَّاسِ وَبَيِّنَٰتٖ مِّنَ ٱلۡهُدَىٰ وَٱلۡفُرۡقَانِۚ")
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah said, 'All the deeds of Adam's sons (people) are for them, except fasting which is for Me, and I will give the reward for it.'” (Sahih al-Bukhari 1904, Sahih Muslim 1151).", arabic: "قَالَ اللَّهُ كُلُّ عَمَلِ ابْنِ آدَمَ لَهُ إِلاَّ الصِّيَامَ، فَإِنَّهُ لِي، وَأَنَا أَجْزِي بِهِ", dimmed: true)
                    ScriptureQuote(text: "“Whoever observes fasts during the month of Ramadan out of sincere faith, and hoping to attain Allah's rewards, then all his past sins will be forgiven” (Sahih al-Bukhari 38, Sahih Muslim 760).", arabic: "مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ", dimmed: true)
                    ScriptureQuote(text: "“There is a gate in Paradise called Ar-Raiyan, and those who observe fasts will enter through it on the Day of Resurrection and none except them will enter through it” (Sahih al-Bukhari 1896).", arabic: "إِنَّ فِي الْجَنَّةِ بَابًا يُقَالُ لَهُ الرَّيَّانُ، يَدْخُلُ مِنْهُ الصَّائِمُونَ يَوْمَ الْقِيَامَةِ، لاَ يَدْخُلُ مِنْهُ أَحَدٌ غَيْرُهُمْ يُقَالُ أَيْنَ الصَّائِمُونَ فَيَقُومُونَ، لاَ يَدْخُلُ مِنْهُ أَحَدٌ غَيْرُهُمْ، فَإِذَا دَخَلُوا أُغْلِقَ، فَلَمْ يَدْخُلْ مِنْهُ أَحَدٌ", dimmed: true)
                }

                ArticleSourcesSection(article: "HowToFastView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Fast")
    }
}

struct HowToZakahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Zakah (زَكَاة)** is the obligatory annual charity of **2.5%** on wealth that reaches the **Nisab (نِصَاب)** and is held for a full lunar year, given to those Allah named as its recipients.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. CHECK IF YOU MUST PAY")) {
                    Text(articleMarkdown: "Zakah is due on a Muslim whose zakatable wealth reaches the **Nisab (نِصَاب)**, the minimum threshold (equal to about **85 grams of gold** or **595 grams of silver**), and has been held for one full lunar (Hijri) year (**Hawl, حَول**).")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. TOTAL YOUR ZAKATABLE WEALTH")) {
                    Text(verbatim: "Include cash and savings, gold and silver, money owed to you that you expect back, business merchandise, and investments held for gain. Personal items (your home, car, and everyday belongings) are not counted.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. CALCULATE 2.5%")) {
                    Text(articleMarkdown: "If your total is at or above the Nisab after the year has passed, give **2.5%** (one fortieth) of it. It becomes due the moment the year completes and must not be delayed past that; it may be paid early, so many bring it forward to Ramadan for the extra reward.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. GIVE IT TO THOSE ENTITLED")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) named eight categories of recipients:").font(.body)
                    ScriptureQuote(text: "“Zakah expenditures are only for the poor and for the needy and for those employed to collect [zakah] and for bringing hearts together [for Islam] and for freeing captives [or slaves] and for those in debt and for the cause of Allah and for the [stranded] traveler” (Quran 9:60).", arabic: "إِنَّمَا ٱلصَّدَقَٰتُ لِلۡفُقَرَآءِ وَٱلۡمَسَٰكِينِ وَٱلۡعَٰمِلِينَ عَلَيۡهَا وَٱلۡمُؤَلَّفَةِ قُلُوبُهُمۡ وَفِي ٱلرِّقَابِ وَٱلۡغَٰرِمِينَ وَفِي سَبِيلِ ٱللَّهِ وَٱبۡنِ ٱلسَّبِيلِۖ")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Once your wealth reaches the Nisab and a lunar year passes, give 2.5% of it to the deserving, purifying your wealth, helping the needy, and fulfilling a pillar of Islam.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHY WE GIVE ZAKAH")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“Take, [O, Muhammad], from their wealth a charity by which you purify them and cause them increase, and invoke [Allah 's blessings] upon them” (Quran 9:103).", arabic: "خُذۡ مِنۡ أَمۡوَٰلِهِمۡ صَدَقَةٗ تُطَهِّرُهُمۡ وَتُزَكِّيهِم بِهَا وَصَلِّ عَلَيۡهِمۡۖ")
                    ScriptureQuote(text: "“And establish prayer and give zakah, and whatever good you put forward for yourselves - you will find it with Allah” (Quran 2:110).", arabic: "وَأَقِيمُواْ ٱلصَّلَوٰةَ وَءَاتُواْ ٱلزَّكَوٰةَۚ وَمَا تُقَدِّمُواْ لِأَنفُسِكُم مِّنۡ خَيۡرٖ تَجِدُوهُ عِندَ ٱللَّهِۗ")
                    Text(verbatim: "It is not a favour to the poor. It is their right in your wealth, and withholding it is a warning:")
                        .font(.body)
                    ScriptureQuote(text: "“And let not those who [greedily] withhold what Allah has given them of His bounty ever think that it is better for them. Rather, it is worse for them. Their necks will be encircled by what they withheld on the Day of Resurrection” (Quran 3:180).", arabic: "وَلَا يَحۡسَبَنَّ ٱلَّذِينَ يَبۡخَلُونَ بِمَآ ءَاتَىٰهُمُ ٱللَّهُ مِن فَضۡلِهِۦ هُوَ خَيۡرٗا لَّهُمۖ بَلۡ هُوَ شَرّٞ لَّهُمۡۖ سَيُطَوَّقُونَ مَا بَخِلُواْ بِهِۦ يَوۡمَ ٱلۡقِيَٰمَةِۗ")
                    Text(verbatim: "When the Prophet (peace and blessings be upon him) sent Mu'adh to Yemen, he told him:")
                        .font(.body)
                    ScriptureQuote(text: "“teach them that Allah has made it obligatory for them to pay the Zakat from their property and it is to be taken from the wealthy among them and given to the poor” (Sahih al-Bukhari 1395, Sahih Muslim 19).", arabic: "فَأَعْلِمْهُمْ أَنَّ اللَّهَ افْتَرَضَ عَلَيْهِمْ صَدَقَةً فِي أَمْوَالِهِمْ، تُؤْخَذُ مِنْ أَغْنِيَائِهِمْ وَتُرَدُّ عَلَى فُقَرَائِهِمْ", dimmed: true)
                }

                ArticleSourcesSection(article: "HowToZakahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Give Zakah")
    }
}

struct HowToHajjView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Hajj (حَجّ)** is the pilgrimage to Makkah performed once in a lifetime by those able, over the days of **Dhul-Hijjah**: entering Ihram, standing at Arafah, and completing the rites the Prophet (peace and blessings be upon him) taught.")
                        .font(.body)
                }

                Section(header: ArticleHeader("BEFORE YOU GO")) {
                    Text(articleMarkdown: "Hajj is obligatory once for every Muslim who is physically and financially able. Repent sincerely, settle debts, seek lawful provision, and learn the rites. Hajj takes place from the 8th to the 13th of **Dhul-Hijjah (ذُو الحِجَّة)**.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. ENTER IHRAM")) {
                    Text(articleMarkdown: "At the appointed boundary (**Miqat, مِيقَات**), bathe, wear the Ihram garments (two unstitched cloths for men; ordinary modest dress for women), make the intention for Hajj, and begin the **Talbiyah (تَلبِيَة)**. Ibn Umar (may Allah be pleased with him) reported the Talbiyah of the Messenger of Allah (peace and blessings be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“'Labbaika Allahumma labbaik, Labbaika la sharika Laka labbaik, Inna-l-hamda wan-ni'mata Laka walmulk, La sharika Laka'” (Sahih al-Bukhari 1549).", arabic: "لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لاَ شَرِيكَ لَكَ", dimmed: true)
                }

                Section(header: ArticleHeader("2. DAY 8: MINA")) {
                    Text(articleMarkdown: "Travel to **Mina (مِنَى)** and pray Dhuhr, Asr, Maghrib, Isha, and Fajr there, each at its time (the four-unit prayers shortened to two).")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. DAY 9: ARAFAH")) {
                    Text(articleMarkdown: "After sunrise proceed to **Arafah (عَرَفَة)** and stand there in supplication until sunset; this standing (**Wuquf**) is the essence of Hajj. Dhuhr and Asr are combined and shortened. The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“The Hajj is Arafah. Whoever came to Jam during the night, before the time of Fajr, then he has attended the Hajj. The days of Mina are three, so whoever hastens (leaving after) two days, then there is no sin upon him, and whoever delays, then there is no sin upon him” (Sunan al-Tirmidhi 889; graded sahih by al-Albani).", arabic: "الْحَجُّ عَرَفَةُ مَنْ جَاءَ لَيْلَةَ جَمْعٍ قَبْلَ طُلُوعِ الْفَجْرِ فَقَدْ أَدْرَكَ الْحَجَّ أَيَّامُ مِنًى ثَلاَثَةٌ فَمَنْ تَعَجَّلَ فِي يَوْمَيْنِ فَلاَ إِثْمَ عَلَيْهِ وَمَنْ تَأَخَّرَ فَلاَ إِثْمَ عَلَيْهِ", dimmed: true)
                    Text(articleMarkdown: "After sunset, move to **Muzdalifah (مُزدَلِفَة)**, combine Maghrib and Isha, rest for the night, and gather pebbles.").font(.body)
                }

                Section(header: ArticleHeader("4. DAY 10: EID (YAWM AN-NAHR)")) {
                    Text(articleMarkdown: "Stone the large pillar (**Jamrat al-Aqabah**) with seven pebbles, offer the sacrifice (**Hady/Qurbani, قُربَان**), shave or trim the hair, then perform **Tawaf al-Ifadah** around the Kaaba and **Sa'i (سَعي)** between Safa and Marwah. With this the pilgrim exits Ihram.")
                        .font(.body)
                }

                Section(header: ArticleHeader("5. DAYS 11–13: TASHREEQ")) {
                    Text(articleMarkdown: "Stay in Mina and stone the three pillars (**Jamarat**) each afternoon. A pilgrim may leave after the 12th if he departs before sunset, otherwise he completes the 13th.")
                        .font(.body)
                }

                Section(header: ArticleHeader("6. FAREWELL TAWAF")) {
                    Text(articleMarkdown: "Before leaving Makkah, perform the farewell circumambulation (**Tawaf al-Wada, طَوَاف الوَدَاع**) so the last act at the Sacred House is Tawaf.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Enter Ihram at the Miqat, stand at Arafah, spend the night at Muzdalifah, then on Eid stone, sacrifice, shave, and perform Tawaf and Sa'i, completing the days of Mina and a farewell Tawaf, returning cleansed of sin.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "HowToHajjView")

                ArticleSourcesSection(article: "HowToUmrahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Perform Hajj")
    }
}

struct HowToUmrahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Umrah (عُمرَة)**, the “lesser pilgrimage,” which may be done at any time of year, is Ihram, Tawaf around the Kaaba, Sa'i between Safa and Marwah, and shaving or trimming the hair.")
                        .font(.body)
                }

                Section(header: ArticleHeader("1. ENTER IHRAM")) {
                    Text(articleMarkdown: "At the **Miqat (مِيقَات)**, bathe, wear the Ihram (two unstitched cloths for men; modest dress for women), make the intention for Umrah with the words “Labbayk Allahumma umratan” (here I am, O Allah, for Umrah), then recite the **Talbiyah (تَلبِيَة)** of the Prophet (peace and blessings be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“'Labbaika Allahumma labbaik, Labbaika la sharika Laka labbaik, Inna-l-hamda wan-ni'mata Laka walmulk, La sharika Laka'” (Sahih al-Bukhari 1549).", arabic: "لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لاَ شَرِيكَ لَكَ", dimmed: true)
                    Text(verbatim: "In Ihram, avoid perfume, cutting hair or nails, and marital relations.")
                        .font(.body)
                }

                Section(header: ArticleHeader("2. TAWAF")) {
                    Text(articleMarkdown: "At the Sacred Mosque, circle the **Kaaba (الكَعبَة)** seven times (**Tawaf, طَوَاف**), beginning and ending at the Black Stone. Then pray two rak'ah behind the **Maqam Ibrahim (مَقَام إِبرَاهِيم)** if able, and drink **Zamzam (زَمزَم)**.")
                        .font(.body)
                }

                Section(header: ArticleHeader("3. SA'I")) {
                    Text(articleMarkdown: "Walk seven times between the hills of **Safa (الصَّفَا)** and **Marwah (المَروَة)** (**Sa'i, سَعي**), starting at Safa and ending at Marwah, remembering Allah and supplicating, as **Hajar** (may Allah be pleased with her) once searched there for water.")
                        .font(.body)
                }

                Section(header: ArticleHeader("4. SHAVE OR TRIM")) {
                    Text(articleMarkdown: "Men shave the head (**Halq, حَلق**) or trim it; women trim a fingertip's length (**Taqsir, تَقصِير**). With this the Umrah is complete and the pilgrim leaves the state of Ihram.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Enter Ihram at the Miqat, perform Tawaf around the Kaaba, make Sa'i between Safa and Marwah, and shave or trim, a complete Umrah that may be done any time of the year.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE VIRTUE OF UMRAH")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“And complete the Hajj and Umrah for Allah” (Quran 2:196).", arabic: "وَأَتِمُّواْ ٱلۡحَجَّ وَٱلۡعُمۡرَةَ لِلَّهِۚ")
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“(The performance of) `Umra is an expiation for the sins committed (between it and the previous one). And the reward of Hajj Mabrur (the one accepted by Allah) is nothing except Paradise” (Sahih al-Bukhari 1773, Sahih Muslim 1349).", arabic: "الْعُمْرَةُ إِلَى الْعُمْرَةِ كَفَّارَةٌ لِمَا بَيْنَهُمَا، وَالْحَجُّ الْمَبْرُورُ لَيْسَ لَهُ جَزَاءٌ إِلاَّ الْجَنَّةُ", dimmed: true)
                    ScriptureQuote(text: "“`Umra in Ramadan is equal to Hajj (in reward)” (Sahih al-Bukhari 1782, Sahih Muslim 1256).", arabic: "فَإِنَّ عُمْرَةً فِي رَمَضَانَ حَجَّةٌ", dimmed: true)
                    Text(verbatim: "And of the journey itself he said:")
                        .font(.body)
                    ScriptureQuote(text: "“Alternate between Hajj and Umrah; for those two remove poverty and sins just as the bellows removes filth from iron, gold, and silver - and there is no reward for Al-Hajj Al-Mabrur except for Paradise” (Sunan al-Tirmidhi 810; graded hasan sahih by al-Albani).", arabic: "تَابِعُوا بَيْنَ الْحَجِّ وَالْعُمْرَةِ فَإِنَّهُمَا يَنْفِيَانِ الْفَقْرَ وَالذُّنُوبَ كَمَا يَنْفِي الْكِيرُ خَبَثَ الْحَدِيدِ وَالذَّهَبِ وَالْفِضَّةِ وَلَيْسَ لِلْحَجَّةِ الْمَبْرُورَةِ ثَوَابٌ إِلاَّ الْجَنَّةُ", dimmed: true)
                }
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Perform Umrah")
    }
}

import SwiftUI

// MARK: - Purification

struct TayammumView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Tayammum (تَيَمُّم)** is the dry purification Allah allows when water cannot be found or cannot be used: make the intention, strike clean earth once with both palms, and wipe the face and then the hands. It stands in for wudhu and for ghusl alike, and it ends the moment water becomes usable.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHEN IT IS ALLOWED")) {
                    Text(verbatim: "Tayammum is permitted in two cases: when there is no water at all (or none to spare after drinking needs), and when water is there but using it would harm you, as with an illness, a wound, or severe cold with no way to warm it. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, when you rise to [perform] prayer, wash your faces and your forearms to the elbows and wipe over your heads and wash your feet to the ankles. And if you are in a state of janabah, then purify yourselves. But if you are ill or on a journey or one of you comes from the place of relieving himself or you have contacted women and do not find water, then seek clean earth and wipe over your faces and hands with it. Allah does not intend to make difficulty for you, but He intends to purify you and complete His favor upon you that you may be grateful” (Quran 5:6).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ إِذَا قُمۡتُمۡ إِلَى ٱلصَّلَوٰةِ فَٱغۡسِلُواْ وُجُوهَكُمۡ وَأَيۡدِيَكُمۡ إِلَى ٱلۡمَرَافِقِ وَٱمۡسَحُواْ بِرُءُوسِكُمۡ وَأَرۡجُلَكُمۡ إِلَى ٱلۡكَعۡبَيۡنِۚ وَإِن كُنتُمۡ جُنُبٗا فَٱطَّهَّرُواْۚ وَإِن كُنتُم مَّرۡضَىٰٓ أَوۡ عَلَىٰ سَفَرٍ أَوۡ جَآءَ أَحَدٞ مِّنكُم مِّنَ ٱلۡغَآئِطِ أَوۡ لَٰمَسۡتُمُ ٱلنِّسَآءَ فَلَمۡ تَجِدُواْ مَآءٗ فَتَيَمَّمُواْ صَعِيدٗا طَيِّبٗا فَٱمۡسَحُواْ بِوُجُوهِكُمۡ وَأَيۡدِيكُم مِّنۡهُۚ مَا يُرِيدُ ٱللَّهُ لِيَجۡعَلَ عَلَيۡكُم مِّنۡ حَرَجٖ وَلَٰكِن يُرِيدُ لِيُطَهِّرَكُمۡ وَلِيُتِمَّ نِعۡمَتَهُۥ عَلَيۡكُمۡ لَعَلَّكُمۡ تَشۡكُرُونَ")
                    Text(verbatim: "The Prophet (peace and blessings be upon him) counted this ease among the special gifts to his ummah:")
                        .font(.body)
                    ScriptureQuote(text: "“I have been given five things which were not given to any one else before me … The earth has been made for me (and for my followers) a place for praying and a thing to perform Tayammum, therefore anyone of my followers can pray wherever the time of a prayer is due” (Sahih al-Bukhari 335).", arabic: "أُعْطِيتُ خَمْسًا لَمْ يُعْطَهُنَّ أَحَدٌ قَبْلِي نُصِرْتُ بِالرُّعْبِ مَسِيرَةَ شَهْرٍ، وَجُعِلَتْ لِيَ الأَرْضُ مَسْجِدًا وَطَهُورًا، فَأَيُّمَا رَجُلٍ مِنْ أُمَّتِي أَدْرَكَتْهُ الصَّلاَةُ فَلْيُصَلِّ، وَأُحِلَّتْ لِيَ الْمَغَانِمُ وَلَمْ تَحِلَّ لأَحَدٍ قَبْلِي، وَأُعْطِيتُ الشَّفَاعَةَ، وَكَانَ النَّبِيُّ يُبْعَثُ إِلَى قَوْمِهِ خَاصَّةً، وَبُعِثْتُ إِلَى النَّاسِ عَامَّةً", dimmed: true)
                }

                Section(header: ArticleHeader("WHAT TO USE")) {
                    Text(articleMarkdown: "Anything that is of the earth's surface and is clean: soil, sand, dust, or a stone or dusty wall. Allah calls it **sa'id tayyib (صَعِيد طَيِّب)**, clean earth. It need not leave visible dust on the hands; a light strike is enough.")
                        .font(.body)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(articleMarkdown: "1. **Intention (Niyyah)**: intend in the heart to purify yourself for prayer. Say “Bismillah.”").font(.body)
                    Text(articleMarkdown: "2. **Strike the earth once** with both palms, lightly, then blow on them or shake off the excess dust.").font(.body)
                    Text(articleMarkdown: "3. **Wipe the face** with both hands, once.").font(.body)
                    Text(articleMarkdown: "4. **Wipe the hands**: the back of the right hand with the left palm and the back of the left hand with the right palm, up to the wrists.").font(.body)
                    Text(verbatim: "That is the whole of it. When Ammar ibn Yasir (may Allah be pleased with him) rolled in the dust to purify himself from janabah, the Prophet (peace and blessings be upon him) corrected him:")
                        .font(.body)
                    ScriptureQuote(text: "“It would have been sufficient for you to do like this.' The Prophet then stroked lightly the earth with his hands and then blew off the dust and passed his hands over his face and hands” (Sahih al-Bukhari 338).", arabic: "إِنَّمَا كَانَ يَكْفِيكَ هَكَذَا . فَضَرَبَ النَّبِيُّ صلى الله عليه وسلم بِكَفَّيْهِ الأَرْضَ، وَنَفَخَ فِيهِمَا ثُمَّ مَسَحَ بِهِمَا وَجْهَهُ وَكَفَّيْهِ", dimmed: true)
                    ScriptureQuote(text: "“He (the Holy Prophet) struck hands upon the earth, and then shook them and then wiped his face and palm” (Sahih Muslim 368).", arabic: "إِنَّمَا كَانَ يَكْفِيكَ أَنْ تَقُولَ هَكَذَا . وَضَرَبَ بِيَدَيْهِ إِلَى الأَرْضِ فَنَفَضَ يَدَيْهِ فَمَسَحَ وَجْهَهُ وَكَفَّيْهِ", dimmed: true)
                }

                Section(header: ArticleHeader("WHAT BREAKS IT")) {
                    Text(verbatim: "Everything that breaks wudhu breaks tayammum. In addition, tayammum ends when the excuse ends: when water is found, or when using it is no longer harmful. A prayer already completed with tayammum is valid and is not repeated.")
                        .font(.body)
                    Text(verbatim: "Tayammum done in place of ghusl is likewise a full substitute until water can be used; then a ghusl is made.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Can tayammum replace ghusl?** Yes. Ammar's case above was janabah, and the Prophet (peace and blessings be upon him) taught him tayammum for it. When water becomes available, make ghusl for what follows.").font(.body)
                    Text(articleMarkdown: "**Does one tayammum cover several prayers?** It remains valid, like wudhu, until it is broken or until water becomes usable. This is the stronger view among the scholars, since the Prophet named the earth a purification without limiting it to one prayer.").font(.body)
                    Text(articleMarkdown: "**A wound is bandaged. Do I still make tayammum?** Wash what you can, wipe over the bandage, and complete the wudhu. Tayammum is for the part that can take neither washing nor wiping, and some scholars regard the wipe over the bandage as sufficient on its own. Ask a scholar about a persistent condition.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "When water is missing or harmful, strike clean earth once, wipe the face and then the hands, and pray. It is Allah's ease for this ummah, and it lasts until water can be used again.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "TayammumView")

                ArticleSourcesSection(article: "RawatibView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Make Tayammum")
    }
}

// MARK: - Other prayers

struct RawatibView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: the **Sunnah Rawatib (السُّنَن الرَّوَاتِب)** are the twelve voluntary rak'ah the Prophet (peace and blessings be upon him) kept around the five prayers every day: four before Dhuhr and two after, two after Maghrib, two after Isha, and two before Fajr. Whoever keeps them is promised a house in Paradise.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE PROMISE")) {
                    ScriptureQuote(text: "“A house will be built in Paradise, for anyone who prays in a day and a night twelve rak'ahs” (Sahih Muslim 728).", arabic: "مَنْ صَلَّى اثْنَتَىْ عَشْرَةَ رَكْعَةً فِي يَوْمٍ وَلَيْلَةٍ بُنِيَ لَهُ بِهِنَّ بَيْتٌ فِي الْجَنَّةِ", dimmed: true)
                    Text(verbatim: "Aishah (may Allah be pleased with her) narrated the breakdown:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever is regular with twelve Rak'ah of Sunnah (prayer), Allah will build a house for him in Paradise: Four Rak'ah before Zuhr, two Rak'ah after it, two Rak'ah after Maghrib, two Rak'ah after Isha, and two Rak'ah before Fajr” (Sunan al-Tirmidhi 414).", arabic: "مَنْ ثَابَرَ عَلَى ثِنْتَىْ عَشْرَةَ رَكْعَةً مِنَ السُّنَّةِ بَنَى اللَّهُ لَهُ بَيْتًا فِي الْجَنَّةِ أَرْبَعِ رَكَعَاتٍ قَبْلَ الظُّهْرِ وَرَكْعَتَيْنِ بَعْدَهَا وَرَكْعَتَيْنِ بَعْدَ الْمَغْرِبِ وَرَكْعَتَيْنِ بَعْدَ الْعِشَاءِ وَرَكْعَتَيْنِ قَبْلَ الْفَجْرِ", dimmed: true)
                }

                Section(header: ArticleHeader("THE TWELVE")) {
                    Text(articleMarkdown: "• **Before Fajr**: 2 rak'ah, kept short.").font(.body)
                    Text(articleMarkdown: "• **Before Dhuhr**: 4 rak'ah (two by two), and **after Dhuhr**: 2 rak'ah.").font(.body)
                    Text(articleMarkdown: "• **After Maghrib**: 2 rak'ah.").font(.body)
                    Text(articleMarkdown: "• **After Isha**: 2 rak'ah.").font(.body)
                    Text(verbatim: "Ibn Umar (may Allah be pleased with him) recalled ten of them from the Prophet himself, and named where he prayed them:")
                        .font(.body)
                    ScriptureQuote(text: "“I remember ten Rakat of Nawafil from the Prophet, two Rakat before the Zuhr prayer and two after it; two Rakat after Maghrib prayer in his house, and two Rakat after 'Isha' prayer in his house, and two Rakat before the Fajr prayer” (Sahih al-Bukhari 1180).", arabic: "حَفِظْتُ مِنَ النَّبِيِّ صلى الله عليه وسلم عَشْرَ رَكَعَاتٍ رَكْعَتَيْنِ قَبْلَ الظُّهْرِ، وَرَكْعَتَيْنِ بَعْدَهَا، وَرَكْعَتَيْنِ بَعْدَ الْمَغْرِبِ فِي بَيْتِهِ، وَرَكْعَتَيْنِ بَعْدَ الْعِشَاءِ فِي بَيْتِهِ، وَرَكْعَتَيْنِ قَبْلَ صَلاَةِ الصُّبْحِ", dimmed: true)
                    ScriptureQuote(text: "“The Prophet (ﷺ) never missed four rak`at before the Zuhr prayer and two rak`at before the Fajr prayer” (Sahih al-Bukhari 1182).", arabic: "أَنَّ النَّبِيَّ صلى الله عليه وسلم كَانَ لاَ يَدَعُ أَرْبَعًا قَبْلَ الظُّهْرِ وَرَكْعَتَيْنِ قَبْلَ الْغَدَاةِ", dimmed: true)
                }

                Section(header: ArticleHeader("THE TWO BEFORE FAJR")) {
                    Text(verbatim: "Of all the rawatib, the two before Fajr were the ones the Prophet (peace and blessings be upon him) never left, at home or on a journey. He said:")
                        .font(.body)
                    ScriptureQuote(text: "“The two rak'ahs at dawn are better than this world and what it contains” (Sahih Muslim 725).", arabic: "رَكْعَتَا الْفَجْرِ خَيْرٌ مِنَ الدُّنْيَا وَمَا فِيهَا", dimmed: true)
                    Text(verbatim: "He prayed them light, with Surah al-Kafirun and Surah al-Ikhlas after al-Fatihah being his frequent choice (Sahih Muslim 726):")
                        .font(.body)
                    ScriptureQuote(text: "“The Prophet (p.b.u.h) used to make the two rak`at before the Fajr prayer so light that I would wonder whether he recited Al-Fatiha (or not)” (Sahih al-Bukhari 1165).", arabic: "كَانَ النَّبِيُّ صلى الله عليه وسلم يُخَفِّفُ الرَّكْعَتَيْنِ اللَّتَيْنِ قَبْلَ صَلاَةِ الصُّبْحِ حَتَّى إِنِّي لأَقُولُ هَلْ قَرَأَ بِأُمِّ الْكِتَابِ", dimmed: true)
                }

                Section(header: ArticleHeader("MORE THAT IS RECOMMENDED")) {
                    Text(verbatim: "Beyond the twelve, other voluntary prayers around the obligatory ones are established and rewarded:")
                        .font(.body)
                    ScriptureQuote(text: "“Whoever maintains four Rak'ah before Az-Zuhr and four after it, Allah makes him prohibited for the Fire” (Sunan al-Tirmidhi 428).", arabic: "مَنْ حَافَظَ عَلَى أَرْبَعِ رَكَعَاتٍ قَبْلَ الظُّهْرِ وَأَرْبَعٍ بَعْدَهَا حَرَّمَهُ اللَّهُ عَلَى النَّارِ", dimmed: true)
                    ScriptureQuote(text: "“May Allah have mercy upon a man who prays four before Al-Asr” (Sunan al-Tirmidhi 430; graded hasan by al-Albani).", arabic: "رَحِمَ اللَّهُ امْرَأً صَلَّى قَبْلَ الْعَصْرِ أَرْبَعًا", dimmed: true)
                    ScriptureQuote(text: "“When any one of you observes the Jumu'a prayer (two obligatory rak'ahs in congregation), he should observe four (rak'ahs) afterwards” (Sahih Muslim 881).", arabic: "إِذَا صَلَّى أَحَدُكُمُ الْجُمُعَةَ فَلْيُصَلِّ بَعْدَهَا أَرْبَعًا", dimmed: true)
                    ScriptureQuote(text: "“There is a prayer between the two Adhans (Adhan and Iqama), there is a prayer between the two Adhans … For the one who wants to (pray)” (Sahih al-Bukhari 627).", arabic: "بَيْنَ كُلِّ أَذَانَيْنِ صَلاَةٌ بَيْنَ كُلِّ أَذَانَيْنِ صَلاَةٌ ـ ثُمَّ قَالَ فِي الثَّالِثَةِ ـ لِمَنْ شَاءَ", dimmed: true)
                }

                Section(header: ArticleHeader("HOW TO PRAY THEM")) {
                    Text(verbatim: "1. Pray them two rak'ah at a time, each pair ending with the tashahhud and the taslim. Four before Dhuhr are two pairs.").font(.body)
                    Text(verbatim: "2. Intend the specific sunnah in the heart; nothing is spoken.").font(.body)
                    Text(verbatim: "3. Pray them at home when you can, as the Prophet (peace and blessings be upon him) did for the Maghrib and Isha rawatib: he said that the best of a man's prayer is in his house, except the obligatory prayer (Sahih Muslim 781).").font(.body)
                    Text(verbatim: "4. If you miss one, it may be made up: the Prophet made up the two after Dhuhr when he was kept busy (Sahih al-Bukhari 1233), and prayed the two of Fajr after the obligatory prayer when he slept through the time on a journey (Sahih Muslim 681).").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Twelve rak'ah a day, spread around the five prayers, earn a house in Paradise and mend what the obligatory prayer lacked. Guard the two of Fajr above all.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "WitrView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray the Sunnah Prayers")
    }
}

struct WitrView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Witr (وِتر)**, the odd-numbered prayer, closes the night's prayer. It is prayed after Isha and before Fajr, as one, three, five or more rak'ah ending in one, and the Prophet (peace and blessings be upon him) never left it, at home or on a journey.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ITS STATUS")) {
                    Text(verbatim: "Witr is a strongly emphasized Sunnah, not one of the five obligations. Ali (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Witr is not essential like the obligatory prayers, but it is the sunnah of the Messenger of Allah (ﷺ)” (Sunan an-Nasa'i 1676).", arabic: "الْوِتْرُ لَيْسَ بِحَتْمٍ كَهَيْئَةِ الْمَكْتُوبَةِ وَلَكِنَّهُ سُنَّةٌ سَنَّهَا رَسُولُ اللَّهِ صلى الله عليه وسلم", dimmed: true)
                    Text(verbatim: "Yet the Prophet (peace and blessings be upon him) urged it in the strongest terms and advised it to those he loved:")
                        .font(.body)
                    ScriptureQuote(text: "“The witr is a duty for every Muslim so if anyone wishes to observe it with five rak'ahs, he may do so; if anyone wishes to observe it with three, he may do so, and if anyone wishes to observe it with one, he may do so” (Sunan Abi Dawud 1422).", arabic: "الْوِتْرُ حَقٌّ عَلَى كُلِّ مُسْلِمٍ فَمَنْ أَحَبَّ أَنْ يُوتِرَ بِخَمْسٍ فَلْيَفْعَلْ وَمَنْ أَحَبَّ أَنْ يُوتِرَ بِثَلاَثٍ فَلْيَفْعَلْ وَمَنْ أَحَبَّ أَنْ يُوتِرَ بِوَاحِدَةٍ فَلْيَفْعَلْ", dimmed: true)
                    ScriptureQuote(text: "“My friend (the Prophet) advised me to do three things and I shall not leave them till I die, these are: To fast three days every month, to offer the Duha prayer, and to offer witr before sleeping” (Sahih al-Bukhari 1178).", arabic: "أَوْصَانِي خَلِيلِي بِثَلاَثٍ لاَ أَدَعُهُنَّ حَتَّى أَمُوتَ صَوْمِ ثَلاَثَةِ أَيَّامٍ مِنْ كُلِّ شَهْرٍ، وَصَلاَةِ الضُّحَى، وَنَوْمٍ عَلَى وِتْرٍ", dimmed: true)
                }

                Section(header: ArticleHeader("ITS TIME")) {
                    Text(verbatim: "From after the Isha prayer until the break of dawn. The best time is the last part of the night for whoever trusts himself to wake; whoever fears he will not should pray it before sleeping.")
                        .font(.body)
                    ScriptureQuote(text: "“Make witr as your last prayer at night” (Sahih al-Bukhari 998).", arabic: "اجْعَلُوا آخِرَ صَلاَتِكُمْ بِاللَّيْلِ وِتْرًا", dimmed: true)
                    ScriptureQuote(text: "“The night prayer is offered as two Rak`at followed by two Rak`at and so on and if anyone is afraid of the approaching dawn (Fajr prayer) he should pray one Rak`ah and this will be a Witr for all the Rak`at which he has prayed before” (Sahih al-Bukhari 990).", arabic: "صَلاَةُ اللَّيْلِ مَثْنَى مَثْنَى، فَإِذَا خَشِيَ أَحَدُكُمُ الصُّبْحَ صَلَّى رَكْعَةً وَاحِدَةً، تُوتِرُ لَهُ مَا قَدْ صَلَّى", dimmed: true)
                }

                Section(header: ArticleHeader("HOW MANY RAK'AH")) {
                    Text(articleMarkdown: "• **One** rak'ah on its own is valid Witr:").font(.body)
                    ScriptureQuote(text: "“Witr is a rak'ah at the end of the prayer” (Sahih Muslim 752).", arabic: "الْوِتْرُ رَكْعَةٌ مِنْ آخِرِ اللَّيْلِ", dimmed: true)
                    Text(articleMarkdown: "• **Three**, either as two rak'ah with taslim then one, or three in one sitting with one tashahhud at the end (not like Maghrib, with a middle sitting).").font(.body)
                    Text(articleMarkdown: "• **Five, seven or nine**, prayed in one sitting with a tashahhud only at the end (in nine, a tashahhud in the eighth and the ninth), as the Prophet (peace and blessings be upon him) prayed at times.").font(.body)
                    Text(articleMarkdown: "• **Eleven or thirteen**: two by two, then one, which was his usual night prayer:").font(.body)
                    ScriptureQuote(text: "“the Messenger of Allah (ﷺ) used to pray eleven rak'ahs at night, observing the Witr with a single rak'ah, and when he had finished them, he lay down on his right side” (Sahih Muslim 736).", arabic: "أَنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم كَانَ يُصَلِّي بِاللَّيْلِ إِحْدَى عَشْرَةَ رَكْعَةً يُوتِرُ مِنْهَا بِوَاحِدَةٍ فَإِذَا فَرَغَ مِنْهَا اضْطَجَعَ عَلَى شِقِّهِ الأَيْمَنِ حَتَّى يَأْتِيَهُ الْمُؤَذِّنُ فَيُصَلِّي رَكْعَتَيْنِ خَفِيفَتَيْنِ", dimmed: true)
                }

                Section(header: ArticleHeader("WHAT TO RECITE")) {
                    Text(verbatim: "In three rak'ah of Witr, the Prophet (peace and blessings be upon him) recited al-A'la in the first, al-Kafirun in the second and al-Ikhlas in the third:")
                        .font(.body)
                    ScriptureQuote(text: "“The Messenger of Allah (ﷺ) used to observe witr with (reciting) ‘Glorify the name of thy Lord, the most High’ (Surah 87), ‘Say O disbelievers’ (Surah 109), and ‘Say, He is Allah, the One, Allah, the eternally besought of all’” (Sunan Abi Dawud 1423).", arabic: "كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يُوتِرُ بِـ { سَبِّحِ اسْمَ رَبِّكَ الأَعْلَى } وَ { قُلْ لِلَّذِينَ كَفَرُوا } وَاللَّهُ الْوَاحِدُ الصَّمَدُ", dimmed: true)
                }

                Section(header: ArticleHeader("THE QUNUT")) {
                    Text(articleMarkdown: "A supplication (**qunut, قُنُوت**) in the last rak'ah, before or after the ruku, is Sunnah. The Prophet (peace and blessings be upon him) taught al-Hasan ibn Ali these words:")
                        .font(.body)
                    ScriptureQuote(text: "“O Allah, guide me among those Thou hast guided, grant me security among those Thou hast granted security, take me into Thy charge among those Thou hast taken into Thy charge, bless me in what Thou hast given, guard me from the evil of what Thou hast decreed, for Thou dost decree, and nothing is decreed for Thee. He whom Thou befriendest is not humbled. Blessed and Exalted art Thou, our Lord” (Sunan Abi Dawud 1425).", arabic: "اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ وَعَافِنِي فِيمَنْ عَافَيْتَ وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ وَبَارِكْ لِي فِيمَا أَعْطَيْتَ وَقِنِي شَرَّ مَا قَضَيْتَ إِنَّكَ تَقْضِي وَلاَ يُقْضَى عَلَيْكَ وَإِنَّهُ لاَ يَذِلُّ مَنْ وَالَيْتَ وَلاَ يَعِزُّ مَنْ عَادَيْتَ تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ", dimmed: true)
                    Text(verbatim: "After the taslim he would say, three times, raising his voice on the third:")
                        .font(.body)
                    ScriptureQuote(text: "“Glorify be to the king most holy” (Sunan Abi Dawud 1430).", arabic: "سُبْحَانَ الْمَلِكِ الْقُدُّوسِ", dimmed: true)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**I slept through Witr. Can I make it up?** Yes. The Prophet (peace and blessings be upon him) said that whoever sleeps through his Witr or forgets it should pray it when he wakes or remembers (Sunan Abi Dawud 1431; Sunan al-Tirmidhi 465; graded sahih by al-Albani); it may be prayed in the day after Fajr, and some scholars say as an even number then.").font(.body)
                    Text(articleMarkdown: "**Can I pray Witr, then pray more at night?** Whoever prays Witr early and then wakes may pray as he wishes, two by two, without repeating Witr: “There are no two Witr in one night” (Sunan al-Tirmidhi 470; Sunan Abi Dawud 1439; graded sahih by al-Albani).").font(.body)
                    Text(articleMarkdown: "**Is Witr the same as Tahajjud?** Witr is the closing rak'ah; Tahajjud is the whole of the night prayer it closes. Praying only Witr is valid; praying Tahajjud without Witr leaves it incomplete.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Close every night with Witr, an odd number ending in one, with a qunut in the last rak'ah. If you will not wake, pray it before you sleep; if you will, make it the last thing you pray before dawn.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "TahajjudView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray Witr")
    }
}

struct TahajjudView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Tahajjud (تَهَجُّد)**, or Qiyam al-Layl, is the voluntary prayer offered after sleeping some of the night, prayed two rak'ah at a time and closed with Witr. It is the best prayer after the obligatory ones, and the hour in which Allah asks who is calling on Him.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE COMMAND AND THE PRAISE")) {
                    ScriptureQuote(text: "“And from [part of] the night, pray with it as additional [worship] for you; it is expected that your Lord will resurrect you to a praised station” (Quran 17:79).", arabic: "وَمِنَ ٱلَّيۡلِ فَتَهَجَّدۡ بِهِۦ نَافِلَةٗ لَّكَ عَسَىٰٓ أَن يَبۡعَثَكَ رَبُّكَ مَقَامٗا مَّحۡمُودٗا")
                    ScriptureQuote(text: "“O you who wraps himself [in clothing], Arise [to pray] the night, except for a little - Half of it - or subtract from it a little Or add to it, and recite the Qur'an with measured recitation” (Quran 73:1-4).", arabic: "يَٰٓأَيُّهَا ٱلۡمُزَّمِّلُ ۝ قُمِ ٱلَّيۡلَ إِلَّا قَلِيلٗا ۝ نِّصۡفَهُۥٓ أَوِ ٱنقُصۡ مِنۡهُ قَلِيلًا ۝ أَوۡ زِدۡ عَلَيۡهِ وَرَتِّلِ ٱلۡقُرۡءَانَ تَرۡتِيلًا")
                    ScriptureQuote(text: "“They used to sleep but little of the night, And in the hours before dawn they would ask forgiveness,” (Quran 51:17-18).", arabic: "كَانُواْ قَلِيلٗا مِّنَ ٱلَّيۡلِ مَا يَهۡجَعُونَ ۝ وَبِٱلۡأَسۡحَارِ هُمۡ يَسۡتَغۡفِرُونَ")
                    ScriptureQuote(text: "“They arise from [their] beds; they supplicate their Lord in fear and aspiration, and from what We have provided them, they spend” (Quran 32:16).", arabic: "تَتَجَافَىٰ جُنُوبُهُمۡ عَنِ ٱلۡمَضَاجِعِ يَدۡعُونَ رَبَّهُمۡ خَوۡفٗا وَطَمَعٗا وَمِمَّا رَزَقۡنَٰهُمۡ يُنفِقُونَ")
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The most excellent fast after Ramadan is God's month. al-Muharram, and the most excellent prayer after what is prescribed is prayer during the night” (Sahih Muslim 1163).", arabic: "أَفْضَلُ الصِّيَامِ بَعْدَ رَمَضَانَ شَهْرُ اللَّهِ الْمُحَرَّمُ وَأَفْضَلُ الصَّلاَةِ بَعْدَ الْفَرِيضَةِ صَلاَةُ اللَّيْلِ", dimmed: true)
                }

                Section(header: ArticleHeader("THE HOUR OF ANSWER")) {
                    ScriptureQuote(text: "“Our Lord, the Blessed, the Superior, comes every night down on the nearest Heaven to us when the last third of the night remains, saying: ‘Is there anyone to invoke Me, so that I may respond to invocation? Is there anyone to ask Me, so that I may grant him his request? Is there anyone seeking My forgiveness, so that I may forgive him” (Sahih al-Bukhari 1145).", arabic: "يَنْزِلُ رَبُّنَا تَبَارَكَ وَتَعَالَى كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الآخِرُ يَقُولُ مَنْ يَدْعُونِي فَأَسْتَجِيبَ لَهُ مَنْ يَسْأَلُنِي فَأُعْطِيَهُ مَنْ يَسْتَغْفِرُنِي فَأَغْفِرَ لَهُ", dimmed: true)
                }

                Section(header: ArticleHeader("ITS TIME")) {
                    Text(verbatim: "Any time after Isha and before Fajr is night prayer; the last third is best. To sleep first and then rise is what the word tahajjud means, and it is what the Prophet (peace and blessings be upon him) did, and what he praised in Dawud (peace be upon him):")
                        .font(.body)
                    ScriptureQuote(text: "“The most beloved prayer to Allah is that of David and the most beloved fasts to Allah are those of David. He used to sleep for half of the night and then pray for one third of the night and again sleep for its sixth part” (Sahih al-Bukhari 1131).", arabic: "أَحَبُّ الصَّلاَةِ إِلَى اللَّهِ صَلاَةُ دَاوُدَ ـ عَلَيْهِ السَّلاَمُ ـ وَأَحَبُّ الصِّيَامِ إِلَى اللَّهِ صِيَامُ دَاوُدَ، وَكَانَ يَنَامُ نِصْفَ اللَّيْلِ وَيَقُومُ ثُلُثَهُ وَيَنَامُ سُدُسَهُ، وَيَصُومُ يَوْمًا وَيُفْطِرُ يَوْمًا", dimmed: true)
                }

                Section(header: ArticleHeader("HOW MANY RAK'AH")) {
                    Text(verbatim: "There is no fixed number; two rak'ah are night prayer. The Prophet's own habit was eleven, and at times thirteen:")
                        .font(.body)
                    ScriptureQuote(text: "“How is the prayer of Allah's Messenger (ﷺ) during the month of Ramadan.‘ She said, ’Allah's Messenger (ﷺ) never exceeded eleven rak`at in Ramadan or in other months; he used to offer four rak`at-- do not ask me about their beauty and length, then four rak`at, do not ask me about their beauty and length, and then three rak`at” (Sahih al-Bukhari 1147).", arabic: "مَا كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يَزِيدُ فِي رَمَضَانَ وَلاَ فِي غَيْرِهِ عَلَى إِحْدَى عَشْرَةَ رَكْعَةً، يُصَلِّي أَرْبَعًا فَلاَ تَسَلْ عَنْ حُسْنِهِنَّ وَطُولِهِنَّ، ثُمَّ يُصَلِّي أَرْبَعًا فَلاَ تَسَلْ عَنْ حُسْنِهِنَّ وَطُولِهِنَّ، ثُمَّ يُصَلِّي ثَلاَثًا", dimmed: true)
                    Text(verbatim: "Long rak'ah with few in number was his way, and he said of the night prayer that it is offered two by two, ending in one (Sahih al-Bukhari 990).")
                        .font(.body)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(articleMarkdown: "1. **Sleep with the intention** of rising. The intention itself is written for you even if sleep overcomes you (Sunan an-Nasa'i 1787; Sunan Ibn Majah 1344; graded sahih by al-Albani).").font(.body)
                    Text(articleMarkdown: "2. **On waking**, say the remembrance of waking, make wudhu, and begin. Satan ties three knots on the sleeper; remembering Allah undoes one, wudhu the second, and prayer the third (Sahih al-Bukhari 1142).").font(.body)
                    Text(articleMarkdown: "3. **Open with two short rak'ah**, as the Prophet (peace and blessings be upon him) did (Sahih Muslim 767), then lengthen what follows.").font(.body)
                    Text(articleMarkdown: "4. **Pray two by two**, reciting slowly, with long standing, bowing and prostration. Weeping and reflecting over the ayat is of its spirit.").font(.body)
                    Text(articleMarkdown: "5. **Make dua in prostration and before the end**, for it is the hour of answer.").font(.body)
                    Text(articleMarkdown: "6. **Close with Witr**: one rak'ah, or three, with the qunut.").font(.body)
                    Text(verbatim: "The Prophet (peace and blessings be upon him) would open his night prayer with this supplication:")
                        .font(.body)
                    ScriptureQuote(text: "“O Allah! All the praises are for you, You are the Holder of the Heavens and the Earth, And whatever is in them. All the praises are for You; You have the possession of the Heavens and the Earth And whatever is in them. All the praises are for You; You are the Light of the Heavens and the Earth And all the praises are for You; You are the King of the Heavens and the Earth; And all the praises are for You; You are the Truth and Your Promise is the truth, And to meet You is true, Your Word is the truth And Paradise is true And Hell is true And all the Prophets (Peace be upon them) are true; And Muhammad is true, And the Day of Resurrection is true. O Allah! I surrender (my will) to You; I believe in You and depend on You. And repent to You, And with Your help I argue (with my opponents, the non-believers) And I take You as a judge (to judge between us). Please forgive me my previous And future sins; And whatever I concealed or revealed And You are the One who make (some people) forward And (some) backward. There is none to be worshipped but you” (Sahih al-Bukhari 1120).", arabic: "اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ قَيِّمُ السَّمَوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ وَلَكَ الْحَمْدُ، لَكَ مُلْكُ السَّمَوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ، وَلَكَ الْحَمْدُ أَنْتَ نُورُ السَّمَوَاتِ وَالأَرْضِ، وَلَكَ الْحَمْدُ أَنْتَ الْحَقُّ، وَوَعْدُكَ الْحَقُّ، وَلِقَاؤُكَ حَقٌّ، وَقَوْلُكَ حَقٌّ، وَالْجَنَّةُ حَقٌّ، وَالنَّارُ حَقٌّ، وَالنَّبِيُّونَ حَقٌّ، وَمُحَمَّدٌ صلى الله عليه وسلم حَقٌّ، وَالسَّاعَةُ حَقٌّ، اللَّهُمَّ لَكَ أَسْلَمْتُ، وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ، وَإِلَيْكَ أَنَبْتُ، وَبِكَ خَاصَمْتُ، وَإِلَيْكَ حَاكَمْتُ، فَاغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ، وَمَا أَسْرَرْتُ وَمَا أَعْلَنْتُ، أَنْتَ الْمُقَدِّمُ وَأَنْتَ الْمُؤَخِّرُ، لاَ إِلَهَ إِلاَّ أَنْتَ ـ أَوْ لاَ إِلَهَ غَيْرُكَ ـ", dimmed: true)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**I cannot wake in the last third. Is my prayer still Tahajjud?** Pray what you can after Isha and before sleeping, with Witr. The Prophet advised those who fear they will not wake to pray Witr early. Regularity in a little beats an unkept ambition.").font(.body)
                    Text(articleMarkdown: "**Can I pray Tahajjud sitting?** Yes, and in his later years the Prophet (peace and blessings be upon him) prayed much of the night sitting. Standing is better where you are able.").font(.body)
                    Text(articleMarkdown: "**Should I recite aloud?** He recited sometimes aloud and sometimes softly. Recite so as to hear yourself, and lower it if it disturbs others who sleep or pray.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Rise for part of the night, pray two by two with slow recitation and long dua, and close with Witr. It is the honor of the believer and the hour Allah Himself invites you to ask.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "DuhaView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray Tahajjud")
    }
}

struct DuhaView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Salat ad-Duha (صَلَاة الضُّحَى)**, the forenoon prayer, is two or more rak'ah prayed after the sun has risen a spear's length until shortly before Dhuhr. Two rak'ah discharge the charity owed by every joint of the body each morning.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ITS VIRTUE")) {
                    ScriptureQuote(text: "“In the morning charity is due from every bone in the body of every one of you. Every utterance of Allah's glorification is an act of charity. Every utterance of praise of Him is an act of charity, every utterance of profession of His Oneness is an act of charity, every utterance of profession of His Greatness is an act of charity, enjoining good is an act of charity, forbidding what is distreputable is an act of charity, and two rak'ahs which one prays in the forenoon will suffice” (Sahih Muslim 720).", arabic: "يُصْبِحُ عَلَى كُلِّ سُلاَمَى مِنْ أَحَدِكُمْ صَدَقَةٌ فَكُلُّ تَسْبِيحَةٍ صَدَقَةٌ وَكُلُّ تَحْمِيدَةٍ صَدَقَةٌ وَكُلُّ تَهْلِيلَةٍ صَدَقَةٌ وَكُلُّ تَكْبِيرَةٍ صَدَقَةٌ وَأَمْرٌ بِالْمَعْرُوفِ صَدَقَةٌ وَنَهْىٌ عَنِ الْمُنْكَرِ صَدَقَةٌ وَيُجْزِئُ مِنْ ذَلِكَ رَكْعَتَانِ يَرْكَعُهُمَا مِنَ الضُّحَى", dimmed: true)
                    Text(verbatim: "It was among the three things the Prophet (peace and blessings be upon him) advised Abu Hurayrah never to leave (Sahih al-Bukhari 1178), and he called it the prayer of those who turn back to Allah:")
                        .font(.body)
                    ScriptureQuote(text: "“The prayer of the penitent should be observed when the young weaned camels feel heat of the sun” (Sahih Muslim 748).", arabic: "صَلاَةُ الأَوَّابِينَ إِذَا رَمِضَتِ الْفِصَالُ", dimmed: true)
                }

                Section(header: ArticleHeader("ITS TIME")) {
                    Text(verbatim: "It begins about fifteen to twenty minutes after sunrise, when the sun has risen the height of a spear, and ends a little before the sun reaches its zenith. Its best time is when the morning has grown hot, as the hadith of the young camels describes.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW MANY RAK'AH")) {
                    Text(verbatim: "The least is two. The Prophet (peace and blessings be upon him) prayed four and added as Allah willed, and prayed eight on the day Makkah was opened:")
                        .font(.body)
                    ScriptureQuote(text: "“The Messenger of Allah (ﷺ) used to observe four rak'ahs in the forenoon prayer and he sometimes observed more as Allah pleased” (Sahih Muslim 719).", arabic: "كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يُصَلِّي الضُّحَى أَرْبَعًا وَيَزِيدُ مَا شَاءَ اللَّهُ", dimmed: true)
                    ScriptureQuote(text: "“On the day of the conquest of Mecca, the Prophet (ﷺ) entered my house, took a bath and offered eight rak`at (of Duha prayers. I had never seen the Prophet (ﷺ)” (Sahih al-Bukhari 1176).", arabic: "إِنَّ النَّبِيَّ صلى الله عليه وسلم دَخَلَ بَيْتَهَا يَوْمَ فَتْحِ مَكَّةَ فَاغْتَسَلَ وَصَلَّى ثَمَانِيَ رَكَعَاتٍ فَلَمْ أَرَ صَلاَةً قَطُّ أَخَفَّ مِنْهَا، غَيْرَ أَنَّهُ يُتِمُّ الرُّكُوعَ وَالسُّجُودَ", dimmed: true)
                }

                Section(header: ArticleHeader("HOW TO PRAY IT")) {
                    Text(verbatim: "1. Intend Salat ad-Duha in the heart, at any point in its time.").font(.body)
                    Text(verbatim: "2. Pray two rak'ah at a time, each pair ending with the taslim, as any voluntary prayer.").font(.body)
                    Text(verbatim: "3. Recite what you wish after al-Fatihah; there is no fixed surah.").font(.body)
                    Text(verbatim: "4. Two rak'ah are complete; four, six or eight are more.").font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Did the Prophet pray it every day?** Aishah said he did not pray it regularly except on returning from a journey, while she herself prayed it (Sahih Muslim 717), and others among the Companions saw him pray it. The scholars reconcile this: he left it at times so it would not be taken as obligatory, and he advised his Companions to keep it. Keeping it daily is good, and leaving it some days is no sin.").font(.body)
                    Text(articleMarkdown: "**Is it the same as Salat al-Ishraq?** Ishraq is the name given to Duha prayed at its earliest, right after the sun has risen a spear's length. It is one prayer.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Two rak'ah in the forenoon pay the day's debt of gratitude for every joint in the body. Pray them when the morning is warm, and add to them as you are able.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "TaraweehView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray Duha")
    }
}

struct TaraweehView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Taraweeh (تَرَاوِيح)** is the night prayer of Ramadan, prayed after Isha two rak'ah at a time and closed with Witr, alone or in congregation. Whoever stands in it out of faith and hope of reward is forgiven his past sins.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ITS VIRTUE")) {
                    ScriptureQuote(text: "“Whoever establishes prayers during the nights of Ramadan faithfully out of sincere faith and hoping to attain Allah's rewards (not for showing off), all his past sins will be forgiven” (Sahih al-Bukhari 37).", arabic: "مَنْ قَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ", dimmed: true)
                    Text(verbatim: "The Prophet (peace and blessings be upon him) urged it without making it obligatory (Sahih Muslim 759).")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW IT BEGAN")) {
                    Text(verbatim: "The Prophet (peace and blessings be upon him) prayed it in the mosque for three nights and the people gathered behind him; then he stayed in his house, fearing it would be made obligatory upon them:")
                        .font(.body)
                    ScriptureQuote(text: "“I saw what you were doing and nothing but the fear that it (i.e. the prayer) might be enjoined on you, stopped me from coming to you” (Sahih al-Bukhari 1129).", arabic: "قَدْ رَأَيْتُ الَّذِي صَنَعْتُمْ وَلَمْ يَمْنَعْنِي مِنَ الْخُرُوجِ إِلَيْكُمْ إِلاَّ أَنِّي خَشِيتُ أَنْ تُفْرَضَ عَلَيْكُمْ", dimmed: true)
                    Text(verbatim: "After his death, Umar (may Allah be pleased with him) gathered the people behind one reciter, Ubayy ibn Ka'b, and said of it “what an excellent innovation this is” (Sahih al-Bukhari 2010), meaning the gathering behind one imam, a Sunnah the Prophet had begun and left only for fear of its becoming obligatory.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW MANY RAK'AH")) {
                    Text(verbatim: "The Prophet's own night prayer, in Ramadan and outside it, was eleven rak'ah:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah's Messenger (ﷺ) never exceeded eleven rak`at in Ramadan or in other months” (Sahih al-Bukhari 1147).", arabic: "مَا كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يَزِيدُ فِي رَمَضَانَ وَلاَ فِي غَيْرِهِ عَلَى إِحْدَى عَشْرَةَ رَكْعَةً، يُصَلِّي أَرْبَعًا فَلاَ تَسَلْ عَنْ حُسْنِهِنَّ وَطُولِهِنَّ، ثُمَّ يُصَلِّي أَرْبَعًا فَلاَ تَسَلْ عَنْ حُسْنِهِنَّ وَطُولِهِنَّ، ثُمَّ يُصَلِّي ثَلاَثًا", dimmed: true)
                    Text(verbatim: "The Companions in Umar's time prayed eleven, and later twenty and more with shorter recitation. There is no fixed limit; night prayer is two by two (Sahih al-Bukhari 990). Eleven or thirteen with long, unhurried recitation follows the Prophet most closely; more with shorter recitation is also good. The majority of the scholars, including Ibn Baz and Ibn al-Uthaymin, hold that there is no fixed limit, while some, such as al-Albani, held to eleven; it is a matter of legitimate difference, not of creed.")
                        .font(.body)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(verbatim: "1. Pray Isha and its two sunnah rak'ah.").font(.body)
                    Text(articleMarkdown: "2. Pray Taraweeh two rak'ah at a time, with a taslim after every two. Rest briefly after every four if you wish; this rest (**tarwihah**) is what gives the prayer its name.").font(.body)
                    Text(verbatim: "3. In congregation, follow the imam; alone, recite what you know well, slowly.").font(.body)
                    Text(verbatim: "4. Close with Witr, one or three rak'ah with the qunut. If you intend to pray more later in the night, delay Witr to the end.").font(.body)
                    Text(verbatim: "5. Attend to the end: whoever prays with the imam until he finishes is written as having prayed the whole night (Sunan al-Tirmidhi 806; Sunan Abi Dawud 1375; graded sahih by al-Albani).").font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Home or mosque?** Both are Sunnah. The congregation in the mosque is the way of the Companions after Umar, and the imam's recitation carries you through the Quran; at home you may pray at a slower pace. Women may attend the mosque or pray at home.").font(.body)
                    Text(articleMarkdown: "**Can I pray Taraweeh late at night instead of after Isha?** Yes. It is the night prayer; the last third is the best time. In the last ten nights the Prophet stayed up the whole night.").font(.body)
                    Text(articleMarkdown: "**Must the whole Quran be completed?** No. It is a good custom of the imams, not a condition. Praying a small portion with reflection is better than racing through a khatm.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Stand in prayer in the nights of Ramadan, two by two after Isha, closing with Witr, out of faith and hope of reward, and Allah forgives what has passed.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "JanazahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray Taraweeh")
    }
}

struct JanazahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Salat al-Janazah (صَلَاة الجَنَازَة)** is the funeral prayer, prayed standing with four takbirs and no bowing or prostration: al-Fatihah after the first, the prayers upon the Prophet after the second, supplication for the deceased after the third, and the taslim after the fourth. It is a collective obligation on the Muslims, and whoever attends until the burial is rewarded with two great mountains.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ITS REWARD")) {
                    ScriptureQuote(text: "“He who attends the funeral till the prayer is offered for (the dead), for him is the reward of one qirat, and he who attends (and stays) till he is buried, for him is the reward of two qirats. It was said: What are the qirats? He said: They are equivalent to two huge mountains” (Sahih Muslim 945).", arabic: "مَنْ شَهِدَ الْجَنَازَةَ حَتَّى يُصَلَّى عَلَيْهَا فَلَهُ قِيرَاطٌ وَمَنْ شَهِدَهَا حَتَّى تُدْفَنَ فَلَهُ قِيرَاطَانِ مِثْلُ الْجَبَلَيْنِ الْعَظِيمَيْنِ", dimmed: true)
                    ScriptureQuote(text: "“If any Muslim dies and forty men who associate nothing with Allah stand over his prayer (they offer prayer over him), Allah will accept them as intercessors for him” (Sahih Muslim 948).", arabic: "مَا مِنْ رَجُلٍ مُسْلِمٍ يَمُوتُ فَيَقُومُ عَلَى جَنَازَتِهِ أَرْبَعُونَ رَجُلاً لاَ يُشْرِكُونَ بِاللَّهِ شَيْئًا إِلاَّ شَفَّعَهُمُ اللَّهُ فِيهِ", dimmed: true)
                }

                Section(header: ArticleHeader("BEFORE THE PRAYER")) {
                    Text(verbatim: "The deceased is washed and shrouded first. The Prophet (peace and blessings be upon him) said of his daughter:")
                        .font(.body)
                    ScriptureQuote(text: "“Wash her thrice or five times or more, if you see it necessary, with water and Sidr and then apply camphor or some camphor at the end; and when you finish, notify me” (Sahih al-Bukhari 1253).", arabic: "اغْسِلْنَهَا ثَلاَثًا أَوْ خَمْسًا أَوْ أَكْثَرَ مَنْ ذَلِكَ إِنْ رَأَيْتُنَّ ذَلِكَ بِمَاءٍ وَسِدْرٍ، وَاجْعَلْنَ فِي الآخِرَةِ كَافُورًا أَوْ شَيْئًا مِنْ كَافُورٍ، فَإِذَا فَرَغْتُنَّ فَآذِنَّنِي", dimmed: true)
                    ScriptureQuote(text: "“Allah's Messenger (ﷺ) was shrouded in three Yemenite white Suhuliya (pieces of cloth) of cotton, and in them there was neither a shirt nor a turban” (Sahih al-Bukhari 1264).", arabic: "أَنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم كُفِّنَ فِي ثَلاَثَةِ أَثْوَابٍ يَمَانِيَةٍ بِيضٍ سَحُولِيَّةٍ مِنْ كُرْسُفٍ، لَيْسَ فِيهِنَّ قَمِيصٌ وَلاَ عِمَامَةٌ", dimmed: true)
                    Text(verbatim: "Men are shrouded in three cloths; women in three or, according to many scholars, five (the hadith of the five is weak, so al-Albani held that women are shrouded like men), and the funeral is not delayed:")
                        .font(.body)
                    ScriptureQuote(text: "“Make haste at a funeral; if the dead person was good, it is a good state to which you are sending him on; but if he was otherwise it is an evil of which you are ridding yourselves” (Sahih Muslim 944).", arabic: "أَسْرِعُوا بِالْجَنَازَةِ فَإِنْ تَكُ صَالِحَةً فَخَيْرٌ - لَعَلَّهُ قَالَ - تُقَدِّمُونَهَا عَلَيْهِ وَإِنْ تَكُنْ غَيْرَ ذَلِكَ فَشَرٌّ تَضَعُونَهُ عَنْ رِقَابِكُمْ", dimmed: true)
                }

                Section(header: ArticleHeader("WHERE TO STAND")) {
                    Text(verbatim: "The body is laid in front of the congregation, its right side toward the qiblah. The imam stands at the head of a man and at the middle of a woman, with the rows behind him.")
                        .font(.body)
                    ScriptureQuote(text: "“I offered the funeral prayer behind the Prophet (ﷺ) for a woman who had died during childbirth and he stood up by the middle of the coffin” (Sahih al-Bukhari 1332).", arabic: "صَلَّيْتُ وَرَاءَ النَّبِيِّ صلى الله عليه وسلم عَلَى امْرَأَةٍ مَاتَتْ فِي نِفَاسِهَا فَقَامَ عَلَيْهَا وَسَطَهَا", dimmed: true)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(verbatim: "There is no bowing, prostration or sitting. It is four takbirs, all standing:").font(.body)
                    Text(articleMarkdown: "1. **First takbir**: say “Allahu Akbar,” raising the hands, then recite Surah al-Fatihah quietly.").font(.body)
                    Text(articleMarkdown: "2. **Second takbir**: send prayers upon the Prophet (peace and blessings be upon him) with the salat al-Ibrahimiyyah of the tashahhud.").font(.body)
                    Text(articleMarkdown: "3. **Third takbir**: supplicate for the deceased, sincerely, using the Prophet's own words.").font(.body)
                    Text(articleMarkdown: "4. **Fourth takbir**: pause briefly, then give the taslim to the right (and to the left if you wish).").font(.body)
                    Text(verbatim: "Ibn Abbas (may Allah be pleased with him) recited al-Fatihah aloud in a funeral prayer and said:")
                        .font(.body)
                    ScriptureQuote(text: "“I offered the funeral prayer behind Ibn `Abbas and he recited Al-Fatiha and said, ‘You should know that it (i.e. recitation of Al-Fatiha) is the tradition of the Prophet (ﷺ) Muhammad” (Sahih al-Bukhari 1335).", arabic: "صَلَّيْتُ خَلْفَ ابْنِ عَبَّاسٍ ـ رضى الله عنهما ـ عَلَى جَنَازَةٍ فَقَرَأَ بِفَاتِحَةِ الْكِتَابِ قَالَ لِيَعْلَمُوا أَنَّهَا سُنَّةٌ", dimmed: true)
                    Text(verbatim: "And the Prophet (peace and blessings be upon him) prayed four takbirs over an-Najashi (Sahih al-Bukhari 1245).")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE SUPPLICATION")) {
                    Text(verbatim: "Awf ibn Malik (may Allah be pleased with him) heard the Prophet pray over a deceased man:")
                        .font(.body)
                    ScriptureQuote(text: "“O Allah! forgive him, have mercy upon him, give him peace and absolve him. Receive him with honour and make his grave spacious; wash him with water, snow and hail. Cleanse him from faults as Thou wouldst cleanse a white garment from impurity. Requite him with an abode more excellent than his abode, with a family better than his family, and with a mate better than his mate. Admit him to the Garden, and protect him from the torment of the grave and the torment of the Fire” (Sahih Muslim 963).", arabic: "اللَّهُمَّ اغْفِرْ لَهُ وَارْحَمْهُ وَعَافِهِ وَاعْفُ عَنْهُ وَأَكْرِمْ نُزُلَهُ وَوَسِّعْ مُدْخَلَهُ وَاغْسِلْهُ بِالْمَاءِ وَالثَّلْجِ وَالْبَرَدِ وَنَقِّهِ مِنَ الْخَطَايَا كَمَا نَقَّيْتَ الثَّوْبَ الأَبْيَضَ مِنَ الدَّنَسِ وَأَبْدِلْهُ دَارًا خَيْرًا مِنْ دَارِهِ وَأَهْلاً خَيْرًا مِنْ أَهْلِهِ وَزَوْجًا خَيْرًا مِنْ زَوْجِهِ وَأَدْخِلْهُ الْجَنَّةَ وَأَعِذْهُ مِنْ عَذَابِ الْقَبْرِ أَوْ مِنْ عَذَابِ النَّارِ", dimmed: true)
                    Text(verbatim: "And for the whole gathering, living and dead:")
                        .font(.body)
                    ScriptureQuote(text: "“O Allah, forgive those of us who are living and those of us who are dead, those of us who are present and those of us who are absent, our young and our old, our male and our female. O Allah, to whomsoever of us Thou givest life grant him life as a believer, and whomsoever of us Thou takest in death take him in death as a follower of Islam” (Sunan Abi Dawud 3201).", arabic: "اللَّهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا وَصَغِيرِنَا وَكَبِيرِنَا وَذَكَرِنَا وَأُنْثَانَا وَشَاهِدِنَا وَغَائِبِنَا اللَّهُمَّ مَنْ أَحْيَيْتَهُ مِنَّا فَأَحْيِهِ عَلَى الإِيمَانِ وَمَنْ تَوَفَّيْتَهُ مِنَّا فَتَوَفَّهُ عَلَى الإِسْلاَمِ اللَّهُمَّ لاَ تَحْرِمْنَا أَجْرَهُ وَلاَ تُضِلَّنَا بَعْدَهُ", dimmed: true)
                    Text(verbatim: "For a woman, change the pronouns to the feminine; for a child, ask that Allah make the child a forerunner and a stored reward for the parents.")
                        .font(.body)
                }

                Section(header: ArticleHeader("AFTER THE PRAYER")) {
                    Text(verbatim: "Follow the funeral to the grave in silence and reflection. The deceased is lowered on the right side facing the qiblah with “Bismillah wa ‘ala sunnati Rasulillah,” the grave is filled, and those present stand and ask forgiveness and steadfastness for him, for he is now being questioned.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Can the prayer be offered for someone absent?** Yes, when the deceased was not prayed over where he died; the Prophet prayed over an-Najashi in Madinah. The scholars differ on doing so for one already prayed over.").font(.body)
                    Text(articleMarkdown: "**I arrived late.** Join with a takbir and follow the imam; after his taslim, complete the takbirs you missed in order before the body is carried away.").font(.body)
                    Text(articleMarkdown: "**Can women pray it?** Yes, in the mosque or at home; Aishah and the wives of the Prophet prayed the funeral prayer for Sa'd ibn Abi Waqqas in the mosque. Following the procession to the grave is for the men.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Four takbirs standing: al-Fatihah, the prayers upon the Prophet, sincere dua for the deceased, and the taslim. Then follow to the grave, and ask steadfastness for a brother or sister who is now being asked.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "IstikharahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray the Funeral Prayer")
    }
}

struct IstikharahView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Istikharah (اِستِخَارَة)** is asking Allah to choose for you. When a permissible matter is before you and you are unsure, pray two voluntary rak'ah, then say the Prophet's supplication naming the matter, and go ahead with what your affairs open onto. It is not a dream to wait for; it is a decision entrusted to Allah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE HADITH")) {
                    Text(verbatim: "Jabir ibn Abdullah (may Allah be pleased with him) said the Prophet (peace and blessings be upon him) taught them Istikharah for every matter as he taught them a surah of the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“If anyone of you thinks of doing any job he should offer a two rak`at prayer other than the compulsory ones and say (after the prayer): -- 'Allahumma inni astakhiruka bi'ilmika, Wa astaqdiruka bi-qudratika, Wa as'alaka min fadlika Al-`azlm Fa-innaka taqdiru Wala aqdiru, Wa ta'lamu Wala a'lamu, Wa anta 'allamu l-ghuyub. Allahumma, in kunta ta'lam anna hadha-lamra Khairun li fi dini wa ma'ashi wa'aqibati `Amri (or 'ajili `Amri wa'ajilihi) Faqdirhu wa yas-sirhu li thumma barik li Fihi, Wa in kunta ta'lamu anna hadha-lamra shar-run li fi dini wa ma'ashi wa'aqibati `Amri (or fi'ajili `Amri wa ajilihi) Fasrifhu anni was-rifni anhu. Waqdir li al-khaira haithu kana Thumma ardini bihi.' (O Allah! I ask guidance from Your knowledge, And Power from Your Might and I ask for Your great blessings. You are capable and I am not. You know and I do not and You know the unseen. O Allah! If You know that this job is good for my religion and my subsistence and in my Hereafter--(or said: If it is better for my present and later needs)--Then You ordain it for me and make it easy for me to get, And then bless me in it, and if You know that this job is harmful to me In my religion and subsistence and in the Hereafter--(or said: If it is worse for my present and later needs)--Then keep it away from me and let me be away from it. And ordain for me whatever is good for me, And make me satisfied with it). The Prophet (ﷺ) added that then the person should name (mention) his need” (Sahih al-Bukhari 1166).", arabic: "إِذَا هَمَّ أَحَدُكُمْ بِالأَمْرِ فَلْيَرْكَعْ رَكْعَتَيْنِ مِنْ غَيْرِ الْفَرِيضَةِ ثُمَّ لِيَقُلِ اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلاَ أَقْدِرُ وَتَعْلَمُ وَلاَ أَعْلَمُ وَأَنْتَ عَلاَّمُ الْغُيُوبِ، اللَّهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الأَمْرَ خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي ـ أَوْ قَالَ عَاجِلِ أَمْرِي وَآجِلِهِ ـ فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي ـ أَوْ قَالَ فِي عَاجِلِ أَمْرِي وَآجِلِهِ ـ فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ، وَاقْدُرْ لِي الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ ـ قَالَ ـ وَيُسَمِّي حَاجَتَهُ", dimmed: true)
                }

                Section(header: ArticleHeader("WHEN TO PRAY IT")) {
                    Text(verbatim: "For any permissible matter whose outcome you cannot see: a marriage, a job, a journey, a purchase, a move. It is not prayed over obligations or prohibitions, for those are already decided, nor over trivial daily choices.")
                        .font(.body)
                    Text(articleMarkdown: "Consult trustworthy people first or alongside it: the Companions took counsel (**istisharah**) and sought Allah's choice (**istikharah**) together.")
                        .font(.body)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(articleMarkdown: "1. **Make wudhu** and pray two rak'ah of voluntary prayer with the intention of Istikharah, at any time prayer is permitted. Recite what you wish after al-Fatihah.").font(.body)
                    Text(articleMarkdown: "2. **After the taslim**, raise your hands and say the supplication above, in Arabic if you can, otherwise in your own language. Praise Allah and send prayers upon the Prophet before it.").font(.body)
                    Text(articleMarkdown: "3. **Name the matter** where the hadith says “this matter”: “if You know that marrying so-and-so...” or “this position at...”").font(.body)
                    Text(articleMarkdown: "4. **Then act.** Pursue the matter. If Allah eases it, that is His choice; if He turns it away, that is His choice too. Do not sit waiting for a sign.").font(.body)
                }

                Section(header: ArticleHeader("THE ARABIC")) {
                    Text(verbatim: "اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلاَ أَقْدِرُ، وَتَعْلَمُ وَلاَ أَعْلَمُ، وَأَنْتَ عَلاَّمُ الْغُيُوبِ. اللَّهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الأَمْرَ خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ، وَاقْدُرْ لِي الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ")
                        .font(appearance.islamArabicFont(base: 22, relativeTo: .title2))
                        .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                        .lineSpacing(6)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(appearance.accent)
                    Text(verbatim: "Allahumma inni astakhiruka bi-‘ilmika, wa astaqdiruka bi-qudratika, wa as'aluka min fadlika al-‘adhim, fa-innaka taqdiru wa la aqdiru, wa ta‘lamu wa la a‘lamu, wa anta ‘allamu al-ghuyub. Allahumma in kunta ta‘lamu anna hadha al-amra khayrun li fi dini wa ma‘ashi wa ‘aqibati amri, faqdurhu li wa yassirhu li thumma barik li fih. Wa in kunta ta‘lamu anna hadha al-amra sharrun li fi dini wa ma‘ashi wa ‘aqibati amri, fasrifhu ‘anni wasrifni ‘anhu, waqdur li al-khayra haythu kana thumma ardini bih.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Must I see a dream?** No. Nothing in the hadith mentions a dream or a feeling. The answer is in how the matter unfolds after you set out on it.").font(.body)
                    Text(articleMarkdown: "**Can I repeat it?** Yes, if you remain unsure; some of the Salaf repeated it several times. But do not make repetition a way of avoiding a decision.").font(.body)
                    Text(articleMarkdown: "**Can I pray it after a sunnah prayer instead of separate rak'ah?** The hadith says two rak'ah other than the obligatory ones; the scholars allow making the intention of Istikharah in a rawatib or Duha prayer. Two rak'ah prayed for it is the clearest way.").font(.body)
                    Text(articleMarkdown: "**Can someone pray it on my behalf?** The hadith addresses the one concerned with the matter. Ask others for their counsel and their dua, and pray Istikharah yourself.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Two rak'ah, the Prophet's supplication with your matter named, then action. Whatever Allah then opens or closes is the answer, and He decrees the good wherever it is.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "TravelPrayerView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray Istikharah")
    }
}

// MARK: - Prayer in special cases

struct TravelPrayerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: a traveler shortens the four-rak'ah prayers to two (**qasr, قَصر**) and may combine Dhuhr with Asr and Maghrib with Isha (**jam', جَمع**) when moving. Fajr and Maghrib are never shortened. Shortening is Allah's charity to His servants, and the Prophet (peace and blessings be upon him) never prayed four on a journey.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE PERMISSION")) {
                    ScriptureQuote(text: "“And when you travel throughout the land, there is no blame upon you for shortening the prayer, [especially] if you fear that those who disbelieve may disrupt [or attack] you. Indeed, the disbelievers are ever to you a clear enemy” (Quran 4:101).", arabic: "وَإِذَا ضَرَبۡتُمۡ فِي ٱلۡأَرۡضِ فَلَيۡسَ عَلَيۡكُمۡ جُنَاحٌ أَن تَقۡصُرُواْ مِنَ ٱلصَّلَوٰةِ إِنۡ خِفۡتُمۡ أَن يَفۡتِنَكُمُ ٱلَّذِينَ كَفَرُوٓاْۚ إِنَّ ٱلۡكَٰفِرِينَ كَانُواْ لَكُمۡ عَدُوّٗا مُّبِينٗا")
                    Text(verbatim: "Umar (may Allah be pleased with him) was asked why the shortening remained when the fear had passed. He said he had wondered the same and asked the Prophet, who replied:")
                        .font(.body)
                    ScriptureQuote(text: "“It is an act of charity which Allah has done to you, so accept His charity” (Sahih Muslim 686).", arabic: "صَدَقَةٌ تَصَدَّقَ اللَّهُ بِهَا عَلَيْكُمْ فَاقْبَلُوا صَدَقَتَهُ", dimmed: true)
                    ScriptureQuote(text: "“I accompanied Allah's Messenger (ﷺ) and he never offered more than two rak`at during the journey. Abu Bakr, `Umar and `Uthman used to do the same” (Sahih al-Bukhari 1102).", arabic: "صَحِبْتُ رَسُولَ اللَّهِ صلى الله عليه وسلم فَكَانَ لاَ يَزِيدُ فِي السَّفَرِ عَلَى رَكْعَتَيْنِ، وَأَبَا بَكْرٍ وَعُمَرَ وَعُثْمَانَ كَذَلِكَ ـ رضى الله عنهم", dimmed: true)
                }

                Section(header: ArticleHeader("WHO IS A TRAVELER")) {
                    Text(verbatim: "Whoever leaves his town on a journey that is called travel in ordinary speech. Most scholars set a distance of about 80 km (some 48 miles), by the hadith of the Companions; others say any journey with provisions and a night away. Shortening begins once you have left the buildings of your town and ends when you return to them.")
                        .font(.body)
                    Text(verbatim: "On arrival, if you intend to stay four days or fewer you remain a traveler. If you intend longer, most scholars say you pray in full, while others allow shortening as long as you have not settled, since the Prophet shortened during his nineteen days at Makkah:")
                        .font(.body)
                    ScriptureQuote(text: "“We traveled with the Prophet (ﷺ) from Medina to Mecca and offered two rak`at (for every prayer) till we returned to Medina.‘ I said, ’Did you stay for a while in Mecca?‘ He replied, ’We stayed in Mecca for ten days” (Sahih al-Bukhari 1081).", arabic: "خَرَجْنَا مَعَ النَّبِيِّ صلى الله عليه وسلم مِنَ الْمَدِينَةِ إِلَى مَكَّةَ، فَكَانَ يُصَلِّي رَكْعَتَيْنِ رَكْعَتَيْنِ حَتَّى رَجَعْنَا إِلَى الْمَدِينَةِ. قُلْتُ أَقَمْتُمْ بِمَكَّةَ شَيْئًا قَالَ أَقَمْنَا بِهَا عَشْرًا", dimmed: true)
                }

                Section(header: ArticleHeader("SHORTENING (QASR)")) {
                    Text(articleMarkdown: "• **Dhuhr, Asr and Isha**: two rak'ah each.").font(.body)
                    Text(articleMarkdown: "• **Fajr**: two, as always. **Maghrib**: three, as always.").font(.body)
                    Text(verbatim: "• The rawatib are dropped on a journey except the two before Fajr and Witr, which the Prophet (peace and blessings be upon him) never left. Other voluntary prayers remain permitted.").font(.body)
                    Text(verbatim: "• Praying behind a resident imam, the traveler completes four with him.").font(.body)
                    ScriptureQuote(text: "“offered four rak`at of Zuhr prayer with the Prophet (p.b.u.h) at Medina and two rak`at at Dhul-Hulaifa” (Sahih al-Bukhari 1089).", arabic: "صَلَّيْتُ الظُّهْرَ مَعَ النَّبِيِّ صلى الله عليه وسلم بِالْمَدِينَةِ أَرْبَعًا، وَبِذِي الْحُلَيْفَةِ رَكْعَتَيْنِ", dimmed: true)
                }

                Section(header: ArticleHeader("COMBINING (JAM')")) {
                    Text(verbatim: "Combining is a concession for hardship while actually on the move, not a fixed rule of travel. Dhuhr may be brought to Asr's time or Asr brought forward to Dhuhr's; Maghrib and Isha likewise. Each prayer is prayed complete in itself, one after the other, with one adhan and two iqamahs.")
                        .font(.body)
                    ScriptureQuote(text: "“Whenever the Prophet (ﷺ) started the journey before noon, he used to delay the Zuhr prayer till the time for the `Asr prayer and then he would dismount and pray them together; and whenever the sun declined before he started the journey he used to offer the Zuhr prayer and then ride (for the journey)” (Sahih al-Bukhari 1111).", arabic: "كَانَ النَّبِيُّ صلى الله عليه وسلم إِذَا ارْتَحَلَ قَبْلَ أَنْ تَزِيغَ الشَّمْسُ أَخَّرَ الظُّهْرَ إِلَى وَقْتِ الْعَصْرِ، ثُمَّ يَجْمَعُ بَيْنَهُمَا، وَإِذَا زَاغَتْ صَلَّى الظُّهْرَ ثُمَّ رَكِبَ", dimmed: true)
                    ScriptureQuote(text: "“Allah's Messenger (ﷺ) used to offer the Zuhr and `Asr prayers together on journeys, and also used to offer the Maghrib and `Isha' prayers together” (Sahih al-Bukhari 1107).", arabic: "كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يَجْمَعُ بَيْنَ صَلاَةِ الظُّهْرِ وَالْعَصْرِ إِذَا كَانَ عَلَى ظَهْرِ سَيْرٍ، وَيَجْمَعُ بَيْنَ الْمَغْرِبِ وَالْعِشَاءِ", dimmed: true)
                    Text(verbatim: "Combining is also allowed for a resident in hard rain, illness, or a genuine hardship, by the report of Ibn Abbas that the Prophet combined in Madinah without fear or travel so that his ummah not be put to difficulty (Sahih Muslim 705).")
                        .font(.body)
                }

                Section(header: ArticleHeader("PRAYING IN A VEHICLE")) {
                    Text(verbatim: "Obligatory prayers are prayed standing on the ground facing the qiblah wherever stopping is possible. When it is not (an aircraft or train, with the time about to pass), pray as you are able: standing if you can, otherwise seated, facing the qiblah as best you can at the opening takbir. Voluntary prayers may be offered seated facing the direction of travel, as the Prophet prayed on his mount:")
                        .font(.body)
                    ScriptureQuote(text: "“The Prophet (ﷺ) used to offer the Nawafil, while riding, facing a direction other than that of the Qibla” (Sahih al-Bukhari 1094).", arabic: "أَنَّ النَّبِيَّ صلى الله عليه وسلم كَانَ يُصَلِّي التَّطَوُّعَ وَهْوَ رَاكِبٌ فِي غَيْرِ الْقِبْلَةِ", dimmed: true)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Is shortening obligatory or optional?** The Prophet never prayed four on a journey and neither did his Companions, so shortening is the Sunnah and the safer course. Most scholars hold completing is valid but disliked; some hold shortening is required.").font(.body)
                    Text(articleMarkdown: "**I am traveling but staying in one place for a week. Do I combine?** It is better not to: in a hotel or a relative's home pray each prayer in its time, shortened if you are still a traveler. Combining while stopped is permitted when there is a need, since the Prophet (peace and blessings be upon him) combined while encamped at Tabuk (Sahih Muslim 706).").font(.body)
                    Text(articleMarkdown: "**What about fasting?** A traveler may break the fast and make it up; if fasting is easy, fasting is better. Allah says: whoever is ill or on a journey, then an equal number of other days (Quran 2:185).").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "On a journey pray the four-rak'ah prayers as two, combine when moving makes the times hard, keep the two of Fajr and Witr, and accept the charity Allah has given you.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "SickPrayerView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray While Traveling")
    }
}

struct SickPrayerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: illness never removes the prayer; it removes only what you cannot do. Pray standing if you can, sitting if you cannot, lying on your side if you cannot sit, and with the eyes and heart if you cannot move. Allah burdens no soul beyond its capacity.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE PRINCIPLE")) {
                    ScriptureQuote(text: "“Allah does not charge a soul except [with that within] its capacity. It will have [the consequence of] what [good] it has gained, and it will bear [the consequence of] what [evil] it has earned. \"Our Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people.\"” (Quran 2:286).", arabic: "لَا يُكَلِّفُ ٱللَّهُ نَفۡسًا إِلَّا وُسۡعَهَاۚ لَهَا مَا كَسَبَتۡ وَعَلَيۡهَا مَا ٱكۡتَسَبَتۡۗ رَبَّنَا لَا تُؤَاخِذۡنَآ إِن نَّسِينَآ أَوۡ أَخۡطَأۡنَاۚ رَبَّنَا وَلَا تَحۡمِلۡ عَلَيۡنَآ إِصۡرٗا كَمَا حَمَلۡتَهُۥ عَلَى ٱلَّذِينَ مِن قَبۡلِنَاۚ رَبَّنَا وَلَا تُحَمِّلۡنَا مَا لَا طَاقَةَ لَنَا بِهِۦۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ")
                    ScriptureQuote(text: "“So fear Allah as much as you are able and listen and obey and spend [in the way of Allah]; it is better for your selves. And whoever is protected from the stinginess of his soul - it is those who will be the successful” (Quran 64:16).", arabic: "فَٱتَّقُواْ ٱللَّهَ مَا ٱسۡتَطَعۡتُمۡ وَٱسۡمَعُواْ وَأَطِيعُواْ وَأَنفِقُواْ خَيۡرٗا لِّأَنفُسِكُمۡۗ وَمَن يُوقَ شُحَّ نَفۡسِهِۦ فَأُوْلَٰٓئِكَ هُمُ ٱلۡمُفۡلِحُونَ")
                    Text(verbatim: "Imran ibn Husayn (may Allah be pleased with him), who suffered from piles, asked the Prophet (peace and blessings be upon him) about prayer. He said:")
                        .font(.body)
                    ScriptureQuote(text: "“Pray while standing and if you can't, pray while sitting and if you cannot do even that, then pray Lying on your side” (Sahih al-Bukhari 1117).", arabic: "صَلِّ قَائِمًا، فَإِنْ لَمْ تَسْتَطِعْ فَقَاعِدًا، فَإِنْ لَمْ تَسْتَطِعْ فَعَلَى جَنْبٍ", dimmed: true)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(articleMarkdown: "1. **Standing** is required in the obligatory prayer for whoever can. Lean on a wall or a stick if that lets you stand.").font(.body)
                    Text(articleMarkdown: "2. **If standing is impossible or harmful**, sit, cross-legged or as is comfortable, and bow by bending forward from the sitting position. Prostrate on the ground if you can.").font(.body)
                    Text(articleMarkdown: "3. **If sitting on the ground is impossible**, sit on a chair, and prostrate on the ground if possible; if not, bow and prostrate by bending forward, the prostration lower than the bow.").font(.body)
                    Text(articleMarkdown: "4. **If sitting is impossible**, lie on your right side facing the qiblah, and perform the bowing and prostration by tilting the head.").font(.body)
                    Text(articleMarkdown: "5. **If even that is impossible**, lie on your back with the feet toward the qiblah, and make the movements with the head; if even that is impossible, the heart intends each pillar (there is no authentic basis for gesturing with the eyes).").font(.body)
                    Text(verbatim: "6. Recite as usual; if the tongue cannot, recite in the heart. The prayer is never dropped while the mind is present.").font(.body)
                }

                Section(header: ArticleHeader("THE REWARD OF THE SEATED")) {
                    Text(verbatim: "Sitting when standing is possible halves the reward of a voluntary prayer; sitting out of inability loses nothing:")
                        .font(.body)
                    ScriptureQuote(text: "“If he prays while standing it is better and he who prays while sitting gets half the reward of that who prays standing; and whoever prays while Lying gets half the reward of that who prays while sitting” (Sahih al-Bukhari 1115).", arabic: "إِنْ صَلَّى قَائِمًا فَهْوَ أَفْضَلُ، وَمَنْ صَلَّى قَاعِدًا فَلَهُ نِصْفُ أَجْرِ الْقَائِمِ، وَمَنْ صَلَّى نَائِمًا فَلَهُ نِصْفُ أَجْرِ الْقَاعِدِ", dimmed: true)
                    Text(verbatim: "The scholars explain that this halving is for the able who choose to sit in voluntary prayer. The one who is unable and does what he can has his full reward, by the hadith that the servant is written the reward of what he used to do in health when illness or travel prevents him (Sahih al-Bukhari 2996).")
                        .font(.body)
                }

                Section(header: ArticleHeader("PURIFICATION WHEN ILL")) {
                    Text(verbatim: "• If water harms you, make tayammum on clean earth, a dusty wall, or a container of earth kept by the bed.").font(.body)
                    Text(verbatim: "• If you cannot move, someone may help you make wudhu or tayammum.").font(.body)
                    Text(verbatim: "• A wound or cast is wiped over; the rest is washed.").font(.body)
                    Text(verbatim: "• One with incontinence or continuous bleeding makes wudhu for each prayer after its time begins and prays; what escapes afterward does not harm.").font(.body)
                    Text(verbatim: "• Impure clothes or bedding are changed or washed when possible; if not, pray as you are.").font(.body)
                }

                Section(header: ArticleHeader("COMBINING WHEN ILL")) {
                    Text(verbatim: "A sick person for whom praying each prayer in its time is a real hardship may combine Dhuhr with Asr and Maghrib with Isha, at either time, as the traveler does. The scholars draw this from the Prophet's combining in Madinah without fear or travel (Sahih Muslim 705) and from his instruction to the woman with prolonged bleeding.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**I was unconscious for a day. Do I make up the prayers?** If unconsciousness lasted a short period, make them up; if it was prolonged (three days or more, by the view of many scholars), there is no make-up, as the pen is lifted from one without awareness. A person asleep makes up what he missed.").font(.body)
                    Text(articleMarkdown: "**Can I pray on a hospital bed facing away from the qiblah?** Face it if you can, even by asking to be turned; if you cannot, pray as you are. The obligation is according to ability.").font(.body)
                    Text(articleMarkdown: "**Chair or floor?** The floor, so that the prostration is on the ground, unless standing up from the floor or prostrating harms you. Use the chair for what you cannot do and the floor for what you can.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Standing, then sitting, then lying down, then the head and the eyes: the prayer follows your ability and never leaves you. Do what you can, and the reward of what you cannot is written for you.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "MissedPrayerView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Pray When Sick")
    }
}

struct MissedPrayerView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: a prayer missed through sleep or forgetting is prayed as soon as you remember, in order, and that is its only expiation. Prayers left deliberately are a grave matter to be repented from at once; the scholars differ on whether they can be made up, and all agree on repentance and on guarding what remains.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SLEEP AND FORGETTING")) {
                    ScriptureQuote(text: "“If anyone forgets a prayer he should pray that prayer when he remembers it. There is no expiation except to pray the same” (Sahih al-Bukhari 597).", arabic: "مَنْ نَسِيَ صَلاَةً فَلْيُصَلِّ إِذَا ذَكَرَهَا، لاَ كَفَّارَةَ لَهَا إِلاَّ ذَلِكَ", dimmed: true)
                    Text(verbatim: "And he recited: “And establish prayer for My remembrance” (Quran 20:14). The Prophet (peace and blessings be upon him) himself once slept through Fajr on a journey and prayed it when the Companions woke, after the sun had risen (Sahih al-Bukhari 595). He said:")
                        .font(.body)
                    ScriptureQuote(text: "“There is no omission in sleeping. The (cognizable) emission is that one should not say prayer (intentionally) till the time of the other prayer comes” (Sahih Muslim 681).", arabic: "أَمَا إِنَّهُ لَيْسَ فِي النَّوْمِ تَفْرِيطٌ إِنَّمَا التَّفْرِيطُ عَلَى مَنْ لَمْ يُصَلِّ الصَّلاَةَ حَتَّى يَجِيءَ وَقْتُ الصَّلاَةِ الأُخْرَى فَمَنْ فَعَلَ ذَلِكَ فَلْيُصَلِّهَا حِينَ يَنْتَبِهُ لَهَا فَإِذَا كَانَ الْغَدُ فَلْيُصَلِّهَا عِنْدَ وَقْتِهَا", dimmed: true)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(articleMarkdown: "1. **Pray it at once** on waking or remembering, even if it is a forbidden time for voluntary prayer; a missed obligatory prayer has no forbidden time.").font(.body)
                    Text(articleMarkdown: "2. **Keep the order.** If you missed Dhuhr and remember at Asr, pray Dhuhr first and then Asr, as the Prophet prayed Asr before Maghrib on the day of the Trench:").font(.body)
                    ScriptureQuote(text: "“By Allah! I too, have not offered the prayer yet … The Prophet (ﷺ) then went to Buthan, performed ablution and performed the `Asr prayer after the sun had set and then offered the Maghrib prayer after it” (Sahih al-Bukhari 945).", arabic: "وَأَنَا وَاللَّهِ مَا صَلَّيْتُهَا بَعْدُ . قَالَ فَنَزَلَ إِلَى بُطْحَانَ فَتَوَضَّأَ، وَصَلَّى الْعَصْرَ بَعْدَ مَا غَابَتِ الشَّمْسُ، ثُمَّ صَلَّى الْمَغْرِبَ بَعْدَهَا", dimmed: true)
                    Text(articleMarkdown: "3. **Pray it as it would have been prayed**: the same number of rak'ah, aloud or quietly as its time calls for. A traveler who missed a prayer while traveling makes it up shortened.").font(.body)
                    Text(articleMarkdown: "4. **Order is dropped** if the current prayer's time would run out, or if you did not remember the missed one until after it.").font(.body)
                    Text(articleMarkdown: "5. **Make wudhu with care** and pray it with the presence of the one grateful to have remembered.").font(.body)
                }

                Section(header: ArticleHeader("PRAYERS LEFT ON PURPOSE")) {
                    Text(verbatim: "Leaving the prayer knowingly is the gravest of sins after shirk, and the Prophet (peace and blessings be upon him) placed it at the boundary of faith:")
                        .font(.body)
                    ScriptureQuote(text: "“Verily between man and between polytheism and unbelief is the negligence of prayer” (Sahih Muslim 82).", arabic: "إِنَّ بَيْنَ الرَّجُلِ وَبَيْنَ الشِّرْكِ وَالْكُفْرِ تَرْكَ الصَّلاَةِ", dimmed: true)
                    Text(verbatim: "The scholars hold two views on making up what was left deliberately. The majority say: make them up, as many as you can estimate, alongside repentance, and the debt to Allah is paid with the prayers themselves. Others, among them Ibn Taymiyyah and Ibn Hazm, say a prayer deliberately left has no valid make-up, for it was tied to its time, and the door is sincere repentance and abundant voluntary prayer. On both views, repent immediately, guard every remaining prayer, and fill your days with voluntary prayer, for the voluntary completes what the obligatory lacked.")
                        .font(.body)
                }

                Section(header: ArticleHeader("PREVENTION")) {
                    Text(verbatim: "• Set an alarm for Fajr and sleep early; the Prophet disliked talk after Isha (Sahih al-Bukhari 568).").font(.body)
                    Text(verbatim: "• Ask someone to wake you, as the Companions kept watch for one another.").font(.body)
                    Text(verbatim: "• Pray each prayer at the start of its time when you can; the best deed is prayer at its time.").font(.body)
                    Text(verbatim: "• Say the sleeping remembrances and make the intention to rise; if sleep still overcomes you, you are excused.").font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Do I make up the Sunnah prayers too?** The rawatib may be made up, especially the two of Fajr, which the Prophet prayed after the obligatory Fajr when the Companions slept through. Witr missed by sleep is prayed when you wake.").font(.body)
                    Text(articleMarkdown: "**A woman missed prayers during menses.** They are not made up; the fast of Ramadan is. Prayers missed before the bleeding began, whose time had entered, are made up.").font(.body)
                    Text(articleMarkdown: "**I do not know how many I missed.** Estimate generously and pray until you are confident you have covered them, one day's worth at a time, without a hardship that makes you abandon it.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Missed by sleep or forgetting: pray it the moment you remember, in order. Left deliberately: repent now, guard what remains, and make up or fill in with voluntary prayer as the scholars you follow direct.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "SujudSahwView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Make Up Missed Prayers")
    }
}

struct SujudSahwView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Sujud as-Sahw (سُجُود السَّهو)** is two prostrations that repair a slip in the prayer: something added, something omitted, or a doubt about the count. For an omission or doubt they are made before the taslim; for an addition or an early taslim, after it. The Prophet (peace and blessings be upon him) forgot in prayer and taught his ummah exactly what to do.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE PROPHET FORGOT TOO")) {
                    ScriptureQuote(text: "“If there had been anything changed in the prayer, surely I would have informed you but I am a human being like you and liable to forget like you. So if I forget remind me and if anyone of you is doubtful about his prayer, he should follow what he thinks to be correct and complete his prayer accordingly and finish it and do two prostrations (of Sahu)” (Sahih al-Bukhari 401).", arabic: "إِنَّهُ لَوْ حَدَثَ فِي الصَّلاَةِ شَىْءٌ لَنَبَّأْتُكُمْ بِهِ، وَلَكِنْ إِنَّمَا أَنَا بَشَرٌ مِثْلُكُمْ، أَنْسَى كَمَا تَنْسَوْنَ، فَإِذَا نَسِيتُ فَذَكِّرُونِي، وَإِذَا شَكَّ أَحَدُكُمْ فِي صَلاَتِهِ فَلْيَتَحَرَّى الصَّوَابَ، فَلْيُتِمَّ عَلَيْهِ ثُمَّ يُسَلِّمْ، ثُمَّ يَسْجُدْ سَجْدَتَيْنِ", dimmed: true)
                    Text(verbatim: "He prayed five rak'ah of Dhuhr once and, when told, turned his legs and prostrated twice (Sahih al-Bukhari 404).")
                        .font(.body)
                }

                Section(header: ArticleHeader("THREE CASES")) {
                    Text(articleMarkdown: "**1. Something added** (an extra bow, prostration, standing or rak'ah): complete the prayer, give the taslim, then prostrate twice and give the taslim again. If you realize during an extra rak'ah, sit at once.").font(.body)
                    Text(articleMarkdown: "**2. Something omitted**: a pillar (ruku, sujud, al-Fatihah) must be gone back to if you have not reached its place in the next rak'ah; otherwise that rak'ah is void and the next stands in for it, with prostration after the taslim. A required act such as the first tashahhud is not returned to once you have stood upright; you continue and prostrate before the taslim:").font(.body)
                    ScriptureQuote(text: "“Allah's Messenger (ﷺ) once led us in a prayer and offered two rak`at and got up (for the third rak`a) without sitting (after the second rak`a). The people also got up with him, and when he was about to finish his prayer, we waited for him to finish the prayer with Taslim but he said Takbir before Taslim and performed two prostrations while sitting and then finished the prayer with Taslim” (Sahih al-Bukhari 1224).", arabic: "صَلَّى لَنَا رَسُولُ اللَّهِ صلى الله عليه وسلم رَكْعَتَيْنِ مِنْ بَعْضِ الصَّلَوَاتِ ثُمَّ قَامَ فَلَمْ يَجْلِسْ، فَقَامَ النَّاسُ مَعَهُ، فَلَمَّا قَضَى صَلاَتَهُ وَنَظَرْنَا تَسْلِيمَهُ كَبَّرَ قَبْلَ التَّسْلِيمِ فَسَجَدَ سَجْدَتَيْنِ وَهُوَ جَالِسٌ ثُمَّ سَلَّمَ", dimmed: true)
                    Text(articleMarkdown: "**3. A doubt about the count**: if one side seems more likely, act on it and prostrate after the taslim. If neither does, build on what you are certain of, the smaller number, and prostrate before the taslim:").font(.body)
                    ScriptureQuote(text: "“When any one of you is in doubt about his prayer and he does Dot know how much he has prayed, three or four (rak'ahs). he should cast aside his doubt and base his prayer on what he is sure of. then perform two prostrations before giving salutations. If he has prayed five rak'ahs, they will make his prayer an even number for him, and if he has prayed exactly four, they will be humiliation for the devil” (Sahih Muslim 571).", arabic: "إِذَا شَكَّ أَحَدُكُمْ فِي صَلاَتِهِ فَلَمْ يَدْرِ كَمْ صَلَّى ثَلاَثًا أَمْ أَرْبَعًا فَلْيَطْرَحِ الشَّكَّ وَلْيَبْنِ عَلَى مَا اسْتَيْقَنَ ثُمَّ يَسْجُدُ سَجْدَتَيْنِ قَبْلَ أَنْ يُسَلِّمَ فَإِنْ كَانَ صَلَّى خَمْسًا شَفَعْنَ لَهُ صَلاَتَهُ وَإِنْ كَانَ صَلَّى إِتْمَامًا لأَرْبَعٍ كَانَتَا تَرْغِيمًا لِلشَّيْطَانِ", dimmed: true)
                }

                Section(header: ArticleHeader("AN EARLY TASLIM")) {
                    Text(verbatim: "Whoever gives the taslim before the prayer is complete, then realizes, completes what remains and prostrates after the taslim, as the Prophet did on the day of Dhul-Yadayn:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah's Messenger (ﷺ) led us in one of the two `Isha' prayers … He prayed two rak`at and then finished the prayer with Taslim … The Prophet (ﷺ) stood up again and led the prayer, completing the remaining prayer, forgotten by him, and performed Taslim, and then said, 'Allahu Akbar.' And then he did a prostration as he used to prostrate or longer than that. He then raised his head saying, 'Allahu Akbar; he then again said, 'Allahu Akbar', and prostrated as he used to prostrate or longer than that. Then he raised his head and said, 'Allahu Akbar.'” (Sahih al-Bukhari 482).", arabic: "صَلَّى بِنَا رَسُولُ اللَّهِ صلى الله عليه وسلم إِحْدَى صَلاَتَىِ الْعَشِيِّ ـ قَالَ ابْنُ سِيرِينَ سَمَّاهَا أَبُو هُرَيْرَةَ وَلَكِنْ نَسِيتُ أَنَا ـ قَالَ فَصَلَّى بِنَا رَكْعَتَيْنِ ثُمَّ سَلَّمَ، فَقَامَ إِلَى خَشَبَةٍ مَعْرُوضَةٍ فِي الْمَسْجِدِ فَاتَّكَأَ عَلَيْهَا، كَأَنَّهُ غَضْبَانُ، وَوَضَعَ يَدَهُ الْيُمْنَى عَلَى الْيُسْرَى، وَشَبَّكَ بَيْنَ أَصَابِعِهِ، وَوَضَعَ خَدَّهُ الأَيْمَنَ عَلَى ظَهْرِ كَفِّهِ الْيُسْرَى، وَخَرَجَتِ السَّرَعَانُ مِنْ أَبْوَابِ الْمَسْجِدِ فَقَالُوا قَصُرَتِ الصَّلاَةُ. وَفِي الْقَوْمِ أَبُو بَكْرٍ وَعُمَرُ، فَهَابَا أَنْ يُكَلِّمَاهُ، وَفِي الْقَوْمِ رَجُلٌ فِي يَدَيْهِ طُولٌ يُقَالُ لَهُ ذُو الْيَدَيْنِ قَالَ يَا رَسُولَ اللَّهِ، أَنَسِيتَ أَمْ قَصُرَتِ الصَّلاَةُ قَالَ لَمْ أَنْسَ، وَلَمْ تُقْصَرْ . فَقَالَ أَكَمَا يَقُولُ ذُو الْيَدَيْنِ . فَقَالُوا نَعَمْ. فَتَقَدَّمَ فَصَلَّى مَا تَرَكَ، ثُمَّ سَلَّمَ، ثُمَّ كَبَّرَ وَسَجَدَ مِثْلَ سُجُودِهِ أَوْ أَطْوَلَ، ثُمَّ رَفَعَ رَأْسَهُ وَكَبَّرَ، ثُمَّ كَبَّرَ وَسَجَدَ مِثْلَ سُجُودِهِ أَوْ أَطْوَلَ، ثُمَّ رَفَعَ رَأْسَهُ وَكَبَّرَ. فَرُبَّمَا سَأَلُوهُ ثُمَّ سَلَّمَ فَيَقُولُ نُبِّئْتُ أَنَّ عِمْرَانَ بْنَ حُصَيْنٍ قَالَ ثُمَّ سَلَّمَ", dimmed: true)
                }

                Section(header: ArticleHeader("HOW TO PERFORM IT")) {
                    Text(verbatim: "1. Say “Allahu Akbar” and prostrate as in the prayer, saying “Subhana Rabbi al-A'la.”").font(.body)
                    Text(verbatim: "2. Sit up with “Allahu Akbar,” then prostrate a second time.").font(.body)
                    Text(verbatim: "3. If they were before the taslim, sit and give the taslim. If after, give the taslim again; a second tashahhud is not required, though some scholars allow it.").font(.body)
                    Text(verbatim: "Behind an imam, follow him: you do not prostrate for your own slip while he leads, but you prostrate with him for his, and for a slip in what you pray alone after him.").font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**I remembered a missed sujud as-sahw only after leaving.** If a short time has passed, prostrate where you are; if long, the prayer stands and there is nothing owed.").font(.body)
                    Text(articleMarkdown: "**Does reciting the wrong surah or a slip of the tongue call for it?** No. It is for the actions of the prayer, not the choice of recitation, and mispronunciation is corrected when noticed.").font(.body)
                    Text(articleMarkdown: "**What if I doubt constantly?** Persistent doubt from whispers is ignored; build on the most likely and continue. Sujud as-sahw is for real doubt, not for a habit of doubting.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Added something: prostrate twice after the taslim. Left something or unsure: build on what is certain and prostrate twice before it. Two prostrations mend the prayer and humble Satan.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "VoluntaryFastsView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Perform Sujud as-Sahw")
    }
}

// MARK: - Fasting and charity

struct VoluntaryFastsView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: beyond Ramadan, the Prophet (peace and blessings be upon him) fasted and recommended Mondays and Thursdays, three days a month, the six days of Shawwal, the day of Arafah, Ashura, and much of Sha'ban and Muharram. Each fast is intended before dawn (or, for a voluntary fast, during the day if nothing has been eaten) and observed as Ramadan is.")
                        .font(.body)
                }

                Section(header: ArticleHeader("MONDAYS AND THURSDAYS")) {
                    ScriptureQuote(text: "“Deeds are presented on Monday and Thursday, and I love that my deeds be presented while I am fasting” (Sunan al-Tirmidhi 747).", arabic: "تُعْرَضُ الأَعْمَالُ يَوْمَ الاِثْنَيْنِ وَالْخَمِيسِ فَأُحِبُّ أَنْ يُعْرَضَ عَمَلِي وَأَنَا صَائِمٌ", dimmed: true)
                    Text(verbatim: "Of Monday in particular he said:")
                        .font(.body)
                    ScriptureQuote(text: "“It is (the day) when I was born and revelation was sent down to me” (Sahih Muslim 1162).", arabic: "فِيهِ وُلِدْتُ وَفِيهِ أُنْزِلَ عَلَىَّ", dimmed: true)
                }

                Section(header: ArticleHeader("THREE DAYS A MONTH")) {
                    Text(verbatim: "Three days every month equal a lifetime of fasting, since each good deed is tenfold. The Prophet (peace and blessings be upon him) named the white days, the 13th, 14th and 15th, whose nights are lit by the full moon:")
                        .font(.body)
                    ScriptureQuote(text: "“Fasting three days of each month is fasting for a lifetime, and the shining days of Al-Bid, the thirteenth, fourteenth and fifteenth” (Sunan an-Nasa'i 2420; graded hasan by al-Albani).", arabic: "صِيَامُ ثَلاَثَةِ أَيَّامٍ مِنْ كُلِّ شَهْرٍ صِيَامُ الدَّهْرِ وَأَيَّامُ الْبِيضِ صَبِيحَةَ ثَلاَثَ عَشْرَةَ وَأَرْبَعَ عَشْرَةَ وَخَمْسَ عَشْرَةَ", dimmed: true)
                    ScriptureQuote(text: "“O Abu Dharr! When you fast three days out of a month, then fast the thirteenth, fourteenth, and fifteenth” (Sunan al-Tirmidhi 761; graded hasan sahih by al-Albani).", arabic: "يَا أَبَا ذَرٍّ إِذَا صُمْتَ مِنَ الشَّهْرِ ثَلاَثَةَ أَيَّامٍ فَصُمْ ثَلاَثَ عَشْرَةَ وَأَرْبَعَ عَشْرَةَ وَخَمْسَ عَشْرَةَ", dimmed: true)
                    Text(verbatim: "Aishah said he fasted three days of every month and did not mind which days they were (Sahih Muslim 1160).")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE SIX OF SHAWWAL")) {
                    ScriptureQuote(text: "“He who observed the fast of Ramadan and then followed it with six (fasts) of Shawwal. it would be as if he fasted perpetually” (Sahih Muslim 1164).", arabic: "مَنْ صَامَ رَمَضَانَ ثُمَّ أَتْبَعَهُ سِتًّا مِنْ شَوَّالٍ كَانَ كَصِيَامِ الدَّهْرِ", dimmed: true)
                    Text(verbatim: "They may be fasted consecutively or spread through the month, after Eid al-Fitr. Those with days of Ramadan to make up should make them up first, so the “Ramadan” in the hadith is complete.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ARAFAH AND ASHURA")) {
                    Text(verbatim: "Asked about the fast of the day of Arafah (9 Dhul-Hijjah), the Prophet (peace and blessings be upon him) said it expiates the year before and the year after; and of Ashura (10 Muharram), that it expiates the year before (Sahih Muslim 1162). The pilgrim at Arafah does not fast; everyone else is urged to. The nine days before Eid al-Adha are the best days for good deeds:")
                        .font(.body)
                    ScriptureQuote(text: "“No good deeds done on other days are superior to those done on these (first ten days of Dhul Hijja).‘ Then some companions of the Prophet (ﷺ) said, ’Not even Jihad?‘ He replied, ’Not even Jihad, except that of a man who does it by putting himself and his property in danger (for Allah's sake) and does not return with any of those things” (Sahih al-Bukhari 969).", arabic: "مَا الْعَمَلُ فِي أَيَّامِ الْعَشْرِ أَفْضَلَ مِنَ الْعَمَلِ فِي هَذِهِ وَلاَ الْجِهَادُ، إِلاَّ رَجُلٌ خَرَجَ يُخَاطِرُ بِنَفْسِهِ وَمَالِهِ فَلَمْ يَرْجِعْ بِشَىْءٍ", dimmed: true)
                    Text(verbatim: "When the Prophet (peace and blessings be upon him) came to Madinah he found the Jews fasting Ashura in gratitude for the day Allah saved the Children of Israel from their enemy, the day Musa fasted. He said:")
                        .font(.body)
                    ScriptureQuote(text: "“We have more claim over Moses than you” (Sahih al-Bukhari 2004).", arabic: "فَأَنَا أَحَقُّ بِمُوسَى مِنْكُمْ", dimmed: true)
                    Text(verbatim: "So he fasted it and commanded that it be fasted (Sahih al-Bukhari 2004), and toward the end of his life he intended to add the ninth to it:")
                        .font(.body)
                    ScriptureQuote(text: "“If I live till the next (year), I would definitely observe fast on the 9th” (Sahih Muslim 1134).", arabic: "لَئِنْ بَقِيتُ إِلَى قَابِلٍ لأَصُومَنَّ التَّاسِعَ", dimmed: true)
                }

                Section(header: ArticleHeader("SHA'BAN AND MUHARRAM")) {
                    ScriptureQuote(text: "“I never saw Allah's Messenger (ﷺ) fasting for a whole month except the month of Ramadan, and did not see him fasting in any month more than in the month of Sha'ban” (Sahih al-Bukhari 1969).", arabic: "كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يَصُومُ حَتَّى نَقُولَ لاَ يُفْطِرُ، وَيُفْطِرُ حَتَّى نَقُولَ لاَ يَصُومُ. فَمَا رَأَيْتُ رَسُولَ اللَّهِ صلى الله عليه وسلم اسْتَكْمَلَ صِيَامَ شَهْرٍ إِلاَّ رَمَضَانَ، وَمَا رَأَيْتُهُ أَكْثَرَ صِيَامًا مِنْهُ فِي شَعْبَانَ", dimmed: true)
                    Text(verbatim: "And the best month to fast after Ramadan is Muharram (Sahih Muslim 1163). The fast of Dawud, every other day, is the most beloved fast to Allah (Sahih al-Bukhari 1131).")
                        .font(.body)
                }

                Section(header: ArticleHeader("HOW TO OBSERVE THEM")) {
                    Text(articleMarkdown: "1. **Intend** the fast. A voluntary fast may be intended in the morning if you have not yet eaten or drunk since dawn; the Prophet would ask for food and, finding none, say “then I am fasting” (Sahih Muslim 1154).").font(.body)
                    Text(articleMarkdown: "2. **Take suhur** if you can and break the fast at sunset, as in Ramadan.").font(.body)
                    Text(articleMarkdown: "3. **Refrain** from what breaks the fast and from what spoils it: argument, foul speech, and idle talk.").font(.body)
                    Text(articleMarkdown: "4. **You may break a voluntary fast** if a need arises, without sin; making it up is recommended, not required.").font(.body)
                    Text(articleMarkdown: "5. **A wife** fasts voluntarily only with her husband's permission when he is present (Sahih al-Bukhari 5192).").font(.body)
                }

                Section(header: ArticleHeader("DAYS NOT TO FAST")) {
                    ScriptureQuote(text: "“None of you should fast on Friday unless he fasts a day before or after it” (Sahih al-Bukhari 1985).", arabic: "لاَ يَصُومَنَّ أَحَدُكُمْ يَوْمَ الْجُمُعَةِ، إِلاَّ يَوْمًا قَبْلَهُ أَوْ بَعْدَهُ", dimmed: true)
                    Text(verbatim: "Fasting is forbidden on the two Eids (Sahih al-Bukhari 1991) and on the three days of Tashriq after Eid al-Adha:")
                        .font(.body)
                    ScriptureQuote(text: "“The days of Tashriq are the days of eating and drinking” (Sahih Muslim 1141).", arabic: "أَيَّامُ التَّشْرِيقِ أَيَّامُ أَكْلٍ وَشُرْبٍ", dimmed: true)
                    Text(verbatim: "Nor should one fast perpetually or wear the body down; the Prophet (peace and blessings be upon him) said to Abdullah ibn Amr that whoever fasts every day has not fasted, and guided him to the fast of Dawud (Sahih al-Bukhari 1979).")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Mondays and Thursdays, three white days a month, six of Shawwal, Arafah, Ashura, and much of Sha'ban: fasts the Prophet loved, each intended and kept as Ramadan is, and each a shield and an expiation.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ItikafView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Fast Voluntary Fasts")
    }
}

struct ItikafView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **I'tikaf (اِعتِكَاف)** is to withdraw into a mosque and remain there for worship, leaving only for what is necessary. The Prophet (peace and blessings be upon him) observed it every year in the last ten nights of Ramadan, seeking Laylat al-Qadr, until he died.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ITS BASIS")) {
                    ScriptureQuote(text: "“It has been made permissible for you the night preceding fasting to go to your wives [for sexual relations]. They are clothing for you and you are clothing for them. Allah knows that you used to deceive yourselves, so He accepted your repentance and forgave you. So now, have relations with them and seek that which Allah has decreed for you. And eat and drink until the white thread of dawn becomes distinct to you from the black thread [of night]. Then complete the fast until the sunset. And do not have relations with them as long as you are staying for worship in the mosques. These are the limits [set by] Allah, so do not approach them. Thus does Allah make clear His ordinances to the people that they may become righteous” (Quran 2:187).", arabic: "أُحِلَّ لَكُمۡ لَيۡلَةَ ٱلصِّيَامِ ٱلرَّفَثُ إِلَىٰ نِسَآئِكُمۡۚ هُنَّ لِبَاسٞ لَّكُمۡ وَأَنتُمۡ لِبَاسٞ لَّهُنَّۗ عَلِمَ ٱللَّهُ أَنَّكُمۡ كُنتُمۡ تَخۡتَانُونَ أَنفُسَكُمۡ فَتَابَ عَلَيۡكُمۡ وَعَفَا عَنكُمۡۖ فَٱلۡـَٰٔنَ بَٰشِرُوهُنَّ وَٱبۡتَغُواْ مَا كَتَبَ ٱللَّهُ لَكُمۡۚ وَكُلُواْ وَٱشۡرَبُواْ حَتَّىٰ يَتَبَيَّنَ لَكُمُ ٱلۡخَيۡطُ ٱلۡأَبۡيَضُ مِنَ ٱلۡخَيۡطِ ٱلۡأَسۡوَدِ مِنَ ٱلۡفَجۡرِۖ ثُمَّ أَتِمُّواْ ٱلصِّيَامَ إِلَى ٱلَّيۡلِۚ وَلَا تُبَٰشِرُوهُنَّ وَأَنتُمۡ عَٰكِفُونَ فِي ٱلۡمَسَٰجِدِۗ تِلۡكَ حُدُودُ ٱللَّهِ فَلَا تَقۡرَبُوهَاۗ كَذَٰلِكَ يُبَيِّنُ ٱللَّهُ ءَايَٰتِهِۦ لِلنَّاسِ لَعَلَّهُمۡ يَتَّقُونَ")
                    ScriptureQuote(text: "“(the wife of the Prophet) The Prophet (ﷺ) used to practice I`tikaf in the last ten days of Ramadan till he died and then his wives used to practice I`tikaf after him” (Sahih al-Bukhari 2026).", arabic: "أَنَّ النَّبِيَّ صلى الله عليه وسلم كَانَ يَعْتَكِفُ الْعَشْرَ الأَوَاخِرَ مِنْ رَمَضَانَ حَتَّى تَوَفَّاهُ اللَّهُ، ثُمَّ اعْتَكَفَ أَزْوَاجُهُ مِنْ بَعْدِهِ", dimmed: true)
                    Text(verbatim: "He said he sought the Night of Decree by it, and told the people:")
                        .font(.body)
                    ScriptureQuote(text: "“Search for the Night of Qadr in the odd nights of the last ten days of Ramadan” (Sahih al-Bukhari 2017).", arabic: "تَحَرَّوْا لَيْلَةَ الْقَدْرِ فِي الْوِتْرِ مِنَ الْعَشْرِ الأَوَاخِرِ مِنْ رَمَضَانَ", dimmed: true)
                }

                Section(header: ArticleHeader("WHERE AND WHEN")) {
                    Text(articleMarkdown: "• **Where**: a mosque in which the congregational prayers are held, so that i'tikaf does not make you miss them. The three sacred mosques are the most excellent for it.").font(.body)
                    Text(articleMarkdown: "• **When**: the Sunnah is the last ten nights of Ramadan. Enter the mosque before sunset on the 20th, the eve of the 21st night, and leave after sunset on the last day (or, as the Prophet did, go from the mosque to the Eid prayer). I'tikaf outside Ramadan and for a shorter time is also valid.").font(.body)
                    ScriptureQuote(text: "“Allah's Messenger (ﷺ) used to practice I`tikaf every year in the month of Ramadan. And after offering the morning prayer, he used to enter the place of his I`tikaf” (Sahih al-Bukhari 2041).", arabic: "كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم يَعْتَكِفُ فِي كُلِّ رَمَضَانَ، وَإِذَا صَلَّى الْغَدَاةَ دَخَلَ مَكَانَهُ الَّذِي اعْتَكَفَ فِيهِ ـ", dimmed: true)
                }

                Section(header: ArticleHeader("HOW TO OBSERVE IT")) {
                    Text(articleMarkdown: "1. **Intend** i'tikaf for Allah; a vowed i'tikaf must be completed, a voluntary one may be left.").font(.body)
                    Text(articleMarkdown: "2. **Set your place**: a corner or a small tent within the mosque, as the Prophet had a tent pitched for him (Sahih al-Bukhari 2033).").font(.body)
                    Text(articleMarkdown: "3. **Fill the time** with prayer, recitation, dhikr, dua, seeking forgiveness, and learning. Speak little of the world; sleep only what you need.").font(.body)
                    Text(articleMarkdown: "4. **Leave only for need**: the toilet, a ghusl, food when it cannot be brought, and for Jumuah if the mosque does not hold it. Do not visit the sick or attend funerals during it unless you had stipulated so.").font(.body)
                    Text(articleMarkdown: "5. **Keep away from intimacy** with a spouse; this breaks the i'tikaf. Visits, speaking and being served are permitted:").font(.body)
                    ScriptureQuote(text: "“(the wife of the Prophet) Allah's Messenger (ﷺ) used to let his head in (the house) while he was in the mosque and I would comb and oil his hair. When in I`tikaf he used not to enter the house except for a need” (Sahih al-Bukhari 2029).", arabic: "وَإِنْ كَانَ رَسُولُ اللَّهِ صلى الله عليه وسلم لَيُدْخِلُ عَلَىَّ رَأْسَهُ وَهْوَ فِي الْمَسْجِدِ فَأُرَجِّلُهُ، وَكَانَ لاَ يَدْخُلُ الْبَيْتَ إِلاَّ لِحَاجَةٍ، إِذَا كَانَ مُعْتَكِفًا", dimmed: true)
                }

                Section(header: ArticleHeader("WHAT BREAKS IT")) {
                    Text(verbatim: "Leaving the mosque without need, intimacy, and losing one's mind or faith. Menses and post-natal bleeding require leaving. Illness may compel leaving, after which one returns when able.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Can women do i'tikaf?** Yes, in the mosque, with a screened place and their guardian's leave; the Prophet's wives did so after him. A woman does not observe i'tikaf at home, for the Quran ties it to the mosques.").font(.body)
                    Text(articleMarkdown: "**Can I do i'tikaf for one night or one day?** Yes. Whoever cannot manage ten days may observe what he can, even the odd nights, or a single night.").font(.body)
                    Text(articleMarkdown: "**Can I use my phone?** What draws you to Allah, yes: the Quran, the adhkar, learning. What draws you back to the world defeats the purpose; put it away.").font(.body)
                    Text(articleMarkdown: "**Is fasting a condition?** In Ramadan it is already fasting. Outside it, many scholars, including the Hanbalis and Ibn Baz, do not make fasting a condition (the Hanafis and Malikis require it), though observing it fasting is better.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Withdraw into the mosque in the last ten nights, leave only for need, and give the whole of yourself to Allah in search of a night better than a thousand months.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ZakatFitrView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Perform I'tikaf")
    }
}

struct ZakatFitrView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Zakat al-Fitr (زَكَاة الفِطر)** is one sa' of staple food, about 2.5 to 3 kg, given for every Muslim in the household before the Eid al-Fitr prayer. It purifies the fasting person from idle talk and feeds the poor on the day of Eid.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE OBLIGATION")) {
                    ScriptureQuote(text: "“Allah's Messenger (ﷺ) enjoined the payment of one Sa' of dates or one Sa' of barley as Zakat-ul-Fitr on every Muslim slave or free, male or female, young or old, and he ordered that it be paid before the people went out to offer the `Id prayer” (Sahih al-Bukhari 1503).", arabic: "فَرَضَ رَسُولُ اللَّهِ صلى الله عليه وسلم زَكَاةَ الْفِطْرِ صَاعًا مِنْ تَمْرٍ، أَوْ صَاعًا مِنْ شَعِيرٍ عَلَى الْعَبْدِ وَالْحُرِّ، وَالذَّكَرِ وَالأُنْثَى، وَالصَّغِيرِ وَالْكَبِيرِ مِنَ الْمُسْلِمِينَ، وَأَمَرَ بِهَا أَنْ تُؤَدَّى قَبْلَ خُرُوجِ النَّاسِ إِلَى الصَّلاَةِ", dimmed: true)
                    ScriptureQuote(text: "“The Messenger of Allah (ﷺ) prescribed the sadaqah (alms) relating to the breaking of the fast as a purification of the fasting from empty and obscene talk and as food for the poor. If anyone pays it before the prayer (of 'Id), it will be accepted as zakat. If anyone pays it after the prayer, that will be a sadaqah like other sadaqahs (alms)” (Sunan Abi Dawud 1609; graded hasan by al-Albani).", arabic: "فَرَضَ رَسُولُ اللَّهِ صلى الله عليه وسلم زَكَاةَ الْفِطْرِ طُهْرَةً لِلصَّائِمِ مِنَ اللَّغْوِ وَالرَّفَثِ وَطُعْمَةً لِلْمَسَاكِينِ مَنْ أَدَّاهَا قَبْلَ الصَّلاَةِ فَهِيَ زَكَاةٌ مَقْبُولَةٌ وَمَنْ أَدَّاهَا بَعْدَ الصَّلاَةِ فَهِيَ صَدَقَةٌ مِنَ الصَّدَقَاتِ", dimmed: true)
                }

                Section(header: ArticleHeader("WHO GIVES AND FOR WHOM")) {
                    Text(verbatim: "Every Muslim who has food beyond his need for the day and night of Eid gives it for himself and for those he supports: wife, children, and dependents. It is not conditioned on the nisab of the annual zakah. It is recommended, and in the view of many required, to give it for a child born before sunset on the last day of Ramadan, and a family may give for the unborn as Uthman did, though that is not obligatory.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT AND HOW MUCH")) {
                    Text(articleMarkdown: "One **sa' (صَاع)**, the Prophet's measure of about four double handfuls, of the staple food of the land: dates, barley, wheat, raisins, rice, or the like. Abu Sa'id (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“We used to give one Sa' of meal or one Sa' of barley or one Sa' of dates, or one Sa' of cottage cheese or one Sa' of Raisins (dried grapes) as Zakat-ul-Fitr” (Sahih al-Bukhari 1506).", arabic: "كُنَّا نُخْرِجُ زَكَاةَ الْفِطْرِ صَاعًا مِنْ طَعَامٍ، أَوْ صَاعًا مِنْ شَعِيرٍ، أَوْ صَاعًا مِنْ تَمْرٍ، أَوْ صَاعًا مِنْ أَقِطٍ، أَوْ صَاعًا مِنْ زَبِيبٍ", dimmed: true)
                    Text(verbatim: "By weight, one sa' is about 2.5 kg of wheat and closer to 3 kg of rice; giving 3 kg is safe. The Sunnah is to give food itself. Some scholars allow its value in money when that benefits the poor more; the majority hold to food, as the Prophet legislated it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHEN")) {
                    Text(verbatim: "Its time is from sunset on the last day of Ramadan until the Eid prayer; the best is the morning of Eid before the prayer. It may be given a day or two earlier, as the Companions did:")
                        .font(.body)
                    ScriptureQuote(text: "“The Prophet (ﷺ) ordered the people to pay Zakat-ul-Fitr before going to the `Id prayer” (Sahih al-Bukhari 1509).", arabic: "أَنَّ النَّبِيَّ صلى الله عليه وسلم أَمَرَ بِزَكَاةِ الْفِطْرِ قَبْلَ خُرُوجِ النَّاسِ إِلَى الصَّلاَةِ", dimmed: true)
                    Text(verbatim: "Delaying it past the prayer without excuse is a sin; it must still be given.")
                        .font(.body)
                }

                Section(header: ArticleHeader("TO WHOM")) {
                    Text(verbatim: "To the poor and needy Muslims of your town. It may be given directly or through a trusted person or mosque who delivers it in time; one sa' may be split among several, and several sa' may be given to one.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "A sa' of food for every member of the house, in the hands of the poor before the Eid prayer: it seals the fast and gives everyone a share in the joy of Eid.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "UdhiyahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Give Zakat al-Fitr")
    }
}

// MARK: - Eid

struct UdhiyahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: the **Udhiyah (أُضحِيَة)** is the sacrifice of a sheep, goat, cow or camel on Eid al-Adha or the three days after it, in worship of Allah alone and in remembrance of Ibrahim (peace be upon him). It is slaughtered after the Eid prayer with “Bismillah, Allahu Akbar,” and its meat is eaten, gifted and given to the poor.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ITS BASIS")) {
                    ScriptureQuote(text: "“So pray to your Lord and sacrifice [to Him alone]” (Quran 108:2).", arabic: "فَصَلِّ لِرَبِّكَ وَٱنۡحَرۡ")
                    ScriptureQuote(text: "“Their meat will not reach Allah, nor will their blood, but what reaches Him is piety from you. Thus have We subjected them to you that you may glorify Allah for that [to] which He has guided you; and give good tidings to the doers of good” (Quran 22:37).", arabic: "لَن يَنَالَ ٱللَّهَ لُحُومُهَا وَلَا دِمَآؤُهَا وَلَٰكِن يَنَالُهُ ٱلتَّقۡوَىٰ مِنكُمۡۚ كَذَٰلِكَ سَخَّرَهَا لَكُمۡ لِتُكَبِّرُواْ ٱللَّهَ عَلَىٰ مَا هَدَىٰكُمۡۗ وَبَشِّرِ ٱلۡمُحۡسِنِينَ")
                    ScriptureQuote(text: "“The Prophet (ﷺ) offered as sacrifices, two horned rams, black and white in color. He slaughtered them with his own hands and mentioned Allah's Name over them and said Takbir and put his foot on their sides” (Sahih al-Bukhari 5565).", arabic: "ضَحَّى النَّبِيُّ صلى الله عليه وسلم بِكَبْشَيْنِ أَمْلَحَيْنِ أَقْرَنَيْنِ، ذَبَحَهُمَا بِيَدِهِ، وَسَمَّى وَكَبَّرَ وَوَضَعَ رِجْلَهُ عَلَى صِفَاحِهِمَا", dimmed: true)
                    Text(verbatim: "It is a confirmed Sunnah for every household that can afford it; some scholars hold it obligatory on the able, so whoever can should not leave it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE ANIMAL")) {
                    Text(articleMarkdown: "• **Kind**: a sheep or goat (for one person and his household), or a cow or camel (which seven may share).").font(.body)
                    Text(articleMarkdown: "• **Age**: a sheep of at least six months, a goat of one year, a cow of two, a camel of five.").font(.body)
                    ScriptureQuote(text: "“Sacrifice only a grown-up animal, unless it is difficult for you, in which case sacrifice a ram (of even less than a year, but more than six months' age)” (Sahih Muslim 1963).", arabic: "لاَ تَذْبَحُوا إِلاَّ مُسِنَّةً إِلاَّ أَنْ يَعْسُرَ عَلَيْكُمْ فَتَذْبَحُوا جَذَعَةً مِنَ الضَّأْنِ", dimmed: true)
                    Text(articleMarkdown: "• **Free of defects**: not one-eyed, not visibly sick, not lame, and not emaciated. Al-Bara' ibn Azib narrated the four the Prophet excluded (Sunan Abi Dawud 2802). Choose the best you can; it is a gift to Allah.").font(.body)
                }

                Section(header: ArticleHeader("BEFORE EID")) {
                    Text(verbatim: "Whoever intends to sacrifice does not cut hair or nails from the first of Dhul-Hijjah until the sacrifice:")
                        .font(.body)
                    ScriptureQuote(text: "“When any one of you intending to sacrifice the animal enters in the month (of Dhu'l-Hijja) he should not get his hair or nails touched (cut)” (Sahih Muslim 1977).", arabic: "إِذَا دَخَلَتِ الْعَشْرُ وَأَرَادَ أَحَدُكُمْ أَنْ يُضَحِّيَ فَلاَ يَمَسَّ مِنْ شَعَرِهِ وَبَشَرِهِ شَيْئًا", dimmed: true)
                }

                Section(header: ArticleHeader("WHEN")) {
                    Text(verbatim: "After the Eid prayer on the 10th of Dhul-Hijjah, until sunset on the 13th. Slaughtering before the prayer is not a sacrifice:")
                        .font(.body)
                    ScriptureQuote(text: "“The first thing we will do on this day of ours, is to offer the (`Id) prayer and then return to slaughter the sacrifice. Whoever does so, he acted according to our Sunna (tradition), and whoever slaughtered (the sacrifice) before the prayer, what he offered was just meat he presented to his family, and that will not be considered as Nusak (sacrifice)” (Sahih al-Bukhari 5545).", arabic: "إِنَّ أَوَّلَ مَا نَبْدَأُ بِهِ فِي يَوْمِنَا هَذَا أَنْ نُصَلِّيَ ثُمَّ نَرْجِعَ فَنَنْحَرَ، مَنْ فَعَلَهُ فَقَدْ أَصَابَ سُنَّتَنَا، وَمَنْ ذَبَحَ قَبْلُ فَإِنَّمَا هُوَ لَحْمٌ قَدَّمَهُ لأَهْلِهِ، لَيْسَ مِنَ النُّسُكِ فِي شَىْءٍ", dimmed: true)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(articleMarkdown: "1. **Sharpen the knife** out of the animal's sight, and treat it gently; water it and lead it kindly.").font(.body)
                    Text(articleMarkdown: "2. **Lay it on its left side facing the qiblah**, foot on its flank, as the Prophet did. A camel is slaughtered standing with its left foreleg tied.").font(.body)
                    Text(articleMarkdown: "3. **Say “Bismillah, Allahu Akbar”**, and if you wish: “O Allah, this is from You and for You, from me (and my family).”").font(.body)
                    Text(articleMarkdown: "4. **Cut swiftly** across the throat, severing the windpipe, gullet and the two jugulars, without severing the head, and let the animal go still before skinning.").font(.body)
                    Text(verbatim: "5. It is best to slaughter with your own hand; otherwise appoint someone and be present. A woman may slaughter.").font(.body)
                    ScriptureQuote(text: "“Give me the large knife … Sharpen it on a stone … In the name of Allah,‘ O Allah, accept [this sacrifice] on behalf of Muhammad and the family of Muhammad and the Umma of Muhammad” (Sahih Muslim 1967).", arabic: "يَا عَائِشَةُ هَلُمِّي الْمُدْيَةَ اشْحَذِيهَا بِحَجَرٍ بِاسْمِ اللَّهِ اللَّهُمَّ تَقَبَّلْ مِنْ مُحَمَّدٍ وَآلِ مُحَمَّدٍ وَمِنْ أُمَّةِ مُحَمَّدٍ", dimmed: true)
                }

                Section(header: ArticleHeader("THE MEAT")) {
                    Text(verbatim: "Eat from it, give some as gifts, and give some to the poor; a third each is a fine division, not a fixed rule. Nothing of it is sold, not even the skin, and the butcher is not paid from it. Storing beyond three days was once forbidden and then permitted:")
                        .font(.body)
                    ScriptureQuote(text: "“Eat of it and feed of it to others and store of it for in that year the people were having a hard time and I wanted you to help (the needy)” (Sahih al-Bukhari 5569).", arabic: "كُلُوا وَأَطْعِمُوا وَادَّخِرُوا فَإِنَّ ذَلِكَ الْعَامَ كَانَ بِالنَّاسِ جَهْدٌ فَأَرَدْتُ أَنْ تُعِينُوا فِيهَا", dimmed: true)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Can one sheep suffice for the whole family?** Yes. The Prophet sacrificed one ram for himself and his household and another for his ummah. Separate sacrifices per person are not required.").font(.body)
                    Text(articleMarkdown: "**Can I have it done abroad?** It is valid to appoint a trustworthy agency to slaughter and distribute on your behalf. Slaughtering where you are, with your own hand, and eating from it is the fuller Sunnah.").font(.body)
                    Text(articleMarkdown: "**I cannot afford it.** There is no sin. Udhiyah is for the able; the poor share in its meat.").font(.body)
                    Text(articleMarkdown: "**Is Udhiyah the same as the pilgrim's hady?** No. The hady is the pilgrim's offering in Makkah; the Udhiyah is for the Muslims at home.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "A sound animal, after the Eid prayer, with the Name of Allah and the takbir, eaten and shared: the Udhiyah renews the surrender of Ibrahim and turns Eid into a feast for the poor.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "BecomeMuslimView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Offer the Eid Sacrifice")
    }
}

// MARK: - Faith and the heart

struct BecomeMuslimView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: a person becomes a Muslim by believing in the heart and saying with the tongue: “I bear witness that there is no deity except Allah, and I bear witness that Muhammad is the Messenger of Allah.” No ceremony, witness or scholar is required. Then comes a bath, the prayer, and a life lived on the two testimonies.")
                        .font(.body)
                }

                Section(header: ArticleHeader("WHAT ISLAM IS")) {
                    ScriptureQuote(text: "“Indeed, the religion in the sight of Allah is Islam. And those who were given the Scripture did not differ except after knowledge had come to them - out of jealous animosity between themselves. And whoever disbelieves in the verses of Allah, then indeed, Allah is swift in [taking] account” (Quran 3:19).", arabic: "إِنَّ ٱلدِّينَ عِندَ ٱللَّهِ ٱلۡإِسۡلَٰمُۗ وَمَا ٱخۡتَلَفَ ٱلَّذِينَ أُوتُواْ ٱلۡكِتَٰبَ إِلَّا مِنۢ بَعۡدِ مَا جَآءَهُمُ ٱلۡعِلۡمُ بَغۡيَۢا بَيۡنَهُمۡۗ وَمَن يَكۡفُرۡ بِـَٔايَٰتِ ٱللَّهِ فَإِنَّ ٱللَّهَ سَرِيعُ ٱلۡحِسَابِ")
                    ScriptureQuote(text: "“And whoever desires other than Islam as religion - never will it be accepted from him, and he, in the Hereafter, will be among the losers” (Quran 3:85).", arabic: "وَمَن يَبۡتَغِ غَيۡرَ ٱلۡإِسۡلَٰمِ دِينٗا فَلَن يُقۡبَلَ مِنۡهُ وَهُوَ فِي ٱلۡأٓخِرَةِ مِنَ ٱلۡخَٰسِرِينَ")
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Islam is based on (the following) five (principles): To testify that none has the right to be worshipped but Allah and Muhammad is Allah's Messenger (ﷺ). To offer the (compulsory congregational) prayers dutifully and perfectly. To pay Zakat (i.e. obligatory charity). To perform Hajj. (i.e. Pilgrimage to Mecca) To observe fast during the month of Ramadan” (Sahih al-Bukhari 8).", arabic: "بُنِيَ الإِسْلاَمُ عَلَى خَمْسٍ شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ وَأَنَّ مُحَمَّدًا رَسُولُ اللَّهِ، وَإِقَامِ الصَّلاَةِ، وَإِيتَاءِ الزَّكَاةِ، وَالْحَجِّ، وَصَوْمِ رَمَضَانَ", dimmed: true)
                }

                Section(header: ArticleHeader("THE TESTIMONY")) {
                    Text(verbatim: "Say, understanding and meaning it:")
                        .font(.body)
                    Text(verbatim: "أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ")
                        .font(appearance.islamArabicFont(base: 24, relativeTo: .title2))
                        .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(appearance.accent)
                    Text(verbatim: "Ash-hadu an la ilaha illa Allah, wa ash-hadu anna Muhammadan Rasulullah.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text(verbatim: "“I bear witness that there is no deity except Allah, and I bear witness that Muhammad is the Messenger of Allah.”")
                        .font(.body)
                    Text(verbatim: "Its first half denies every object of worship other than Allah and affirms Him alone; its second half binds you to follow His Messenger. Saying it sincerely, knowing what it means, with no reservation, is what makes a Muslim:")
                        .font(.body)
                    ScriptureQuote(text: "“He who professed that there is no god but Allah and made a denial of everything which the people worship beside Allah, his property and blood became inviolable, an their affairs rest with Allah” (Sahih Muslim 23).", arabic: "مَنْ قَالَ لاَ إِلَهَ إِلاَّ اللَّهُ وَكَفَرَ بِمَا يُعْبَدُ مِنْ دُونِ اللَّهِ حَرُمَ مَالُهُ وَدَمُهُ وَحِسَابُهُ عَلَى اللَّهِ", dimmed: true)
                    ScriptureQuote(text: "“He who died knowing (fully well) that there is no god but Allah entered Paradise” (Sahih Muslim 26).", arabic: "مَنْ مَاتَ وَهُوَ يَعْلَمُ أَنَّهُ لاَ إِلَهَ إِلاَّ اللَّهُ دَخَلَ الْجَنَّةَ", dimmed: true)
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    Text(articleMarkdown: "1. **Believe.** Know that Allah alone is the Creator and the only One worthy of worship, that Muhammad is His final Messenger, and that the Quran is His word. Doubt is not a barrier to beginning; sincerity is the condition.").font(.body)
                    Text(articleMarkdown: "2. **Say the Shahadah** aloud, in Arabic and in your language. Alone is valid; before witnesses is a joy and a help, but not a condition.").font(.body)
                    Text(articleMarkdown: "3. **Take a bath (ghusl)**: the Prophet (peace and blessings be upon him) told Qays ibn Asim, on his embracing Islam, to bathe (Sunan Abi Dawud 355), and Thumamah bathed before he came to declare his Islam (Sahih al-Bukhari 462).").font(.body)
                    Text(articleMarkdown: "4. **Learn to pray**, beginning at once. The prayer is the first thing Islam asks after the testimony; learn wudhu, al-Fatihah, and the movements, and pray what you know while you learn the rest.").font(.body)
                    Text(articleMarkdown: "5. **Learn gradually**: the pillars of faith, the halal and haram, the Quran. Islam was revealed over twenty-three years; the Prophet taught Mu'adh to begin with the testimony, then the prayer, then the zakah (Sahih al-Bukhari 1395).").font(.body)
                    Text(articleMarkdown: "6. **Find company**: a mosque, a teacher, and believing friends. Keep your name unless it carries a meaning of shirk; changing it is not required.").font(.body)
                }

                Section(header: ArticleHeader("WHAT IT EARNS YOU")) {
                    Text(verbatim: "Everything before it is wiped away. Amr ibn al-As (may Allah be pleased with him), on his deathbed, recalled that when he came to give his hand in Islam he asked for his past to be forgiven, and the Prophet said:")
                        .font(.body)
                    ScriptureQuote(text: "“Are you not aware of the fact that Islam wipes out all the previous (misdeeds)? Verily migration wipes out all the previous (misdeeds), and verily the pilgrimage wipes out all the (previous) misdeeds” (Sahih Muslim 121).", arabic: "أَمَا عَلِمْتَ أَنَّ الإِسْلاَمَ يَهْدِمُ مَا كَانَ قَبْلَهُ وَأَنَّ الْهِجْرَةَ تَهْدِمُ مَا كَانَ قَبْلَهَا وَأَنَّ الْحَجَّ يَهْدِمُ مَا كَانَ قَبْلَهُ", dimmed: true)
                    ScriptureQuote(text: "“Say, \"O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful.\"” (Quran 39:53).", arabic: "۞ قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ عَلَىٰٓ أَنفُسِهِمۡ لَا تَقۡنَطُواْ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ يَغۡفِرُ ٱلذُّنُوبَ جَمِيعًاۚ إِنَّهُۥ هُوَ ٱلۡغَفُورُ ٱلرَّحِيمُ")
                    ScriptureQuote(text: "“There shall be no compulsion in [acceptance of] the religion. The right course has become clear from the wrong. So whoever disbelieves in Taghut and believes in Allah has grasped the most trustworthy handhold with no break in it. And Allah is Hearing and Knowing” (Quran 2:256).", arabic: "لَآ إِكۡرَاهَ فِي ٱلدِّينِۖ قَد تَّبَيَّنَ ٱلرُّشۡدُ مِنَ ٱلۡغَيِّۚ فَمَن يَكۡفُرۡ بِٱلطَّٰغُوتِ وَيُؤۡمِنۢ بِٱللَّهِ فَقَدِ ٱسۡتَمۡسَكَ بِٱلۡعُرۡوَةِ ٱلۡوُثۡقَىٰ لَا ٱنفِصَامَ لَهَاۗ وَٱللَّهُ سَمِيعٌ عَلِيمٌ")
                }

                Section(header: ArticleHeader("STAYING FIRM")) {
                    Text(verbatim: "Sufyan ibn Abdullah asked the Prophet (peace and blessings be upon him) for a word about Islam that would need no other. He said:")
                        .font(.body)
                    ScriptureQuote(text: "“Say I affirm my faith in Allah and then remain steadfast to it” (Sahih Muslim 38).", arabic: "قُلْ آمَنْتُ بِاللَّهِ فَاسْتَقِمْ", dimmed: true)
                    Text(verbatim: "Pray on time, keep the company of the righteous, read the Quran daily, ask when you do not know, and never despair of Allah's mercy over a slip. Faith rises and falls; the Prophet said that the strongest handhold of faith is love for Allah's sake and hate for His sake (Musnad Ahmad 18524; graded hasan by al-Albani, Sahih al-Jami' 2539).")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Do I need to go to a mosque or an imam?** No. The testimony between you and Allah is complete. A certificate is useful for Hajj visas and marriage in some countries, and the mosque is where you will learn, so go, but Islam did not wait for it.").font(.body)
                    Text(articleMarkdown: "**Do I have to tell my family?** Not as a condition. Wisdom, kindness and good character are your best witness. Honor your parents whatever their faith; Allah commands it.").font(.body)
                    Text(articleMarkdown: "**I still have questions and doubts.** So did the Companions before certainty settled. Ask, read, and pray; knowledge removes doubt. Do not delay the testimony you already believe.").font(.body)
                    Text(articleMarkdown: "**Must I be circumcised, change my name, or learn Arabic first?** No. Circumcision is prescribed for men (obligatory according to many scholars) but is not a condition of entering Islam and may be delayed; the name stays unless its meaning is un-Islamic; Arabic comes with time, beginning with al-Fatihah.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Believe, bear witness, bathe, pray, and learn. The testimony wipes away all that came before, and the rest of Islam is walked one step at a time.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "TawbahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Become a Muslim")
    }
}

struct TawbahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Tawbah (تَوبَة)** is turning back to Allah from sin: stopping it, regretting it, resolving never to return, and returning what was taken from others. It is accepted so long as the soul has not reached the throat and the sun has not risen from the west, and Allah loves the one who repents more than a man loves finding his lost camel in the desert.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE DOOR IS OPEN")) {
                    ScriptureQuote(text: "“Say, \"O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful.\"” (Quran 39:53).", arabic: "۞ قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ عَلَىٰٓ أَنفُسِهِمۡ لَا تَقۡنَطُواْ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ يَغۡفِرُ ٱلذُّنُوبَ جَمِيعًاۚ إِنَّهُۥ هُوَ ٱلۡغَفُورُ ٱلرَّحِيمُ")
                    ScriptureQuote(text: "“And whoever does a wrong or wrongs himself but then seeks forgiveness of Allah will find Allah Forgiving and Merciful” (Quran 4:110).", arabic: "وَمَن يَعۡمَلۡ سُوٓءًا أَوۡ يَظۡلِمۡ نَفۡسَهُۥ ثُمَّ يَسۡتَغۡفِرِ ٱللَّهَ يَجِدِ ٱللَّهَ غَفُورٗا رَّحِيمٗا")
                    ScriptureQuote(text: "“Except for those who repent, believe and do righteous work. For them Allah will replace their evil deeds with good. And ever is Allah Forgiving and Merciful” (Quran 25:70).", arabic: "إِلَّا مَن تَابَ وَءَامَنَ وَعَمِلَ عَمَلٗا صَٰلِحٗا فَأُوْلَٰٓئِكَ يُبَدِّلُ ٱللَّهُ سَيِّـَٔاتِهِمۡ حَسَنَٰتٖۗ وَكَانَ ٱللَّهُ غَفُورٗا رَّحِيمٗا")
                    ScriptureQuote(text: "“He who seeks repentance (from the Lord) before the rising of the sun from the west (before the Day of Resurrection), Allah turns to him with Mercy” (Sahih Muslim 2703).", arabic: "مَنْ تَابَ قَبْلَ أَنْ تَطْلُعَ الشَّمْسُ مِنْ مَغْرِبِهَا تَابَ اللَّهُ عَلَيْهِ", dimmed: true)
                    ScriptureQuote(text: "“Allah is more pleased with the repentance of His slave than anyone of you is pleased with finding his camel which he had lost in the desert” (Sahih al-Bukhari 6309).", arabic: "اللَّهُ أَفْرَحُ بِتَوْبَةِ عَبْدِهِ مِنْ أَحَدِكُمْ سَقَطَ عَلَى بَعِيرِهِ، وَقَدْ أَضَلَّهُ فِي أَرْضِ فَلاَةٍ", dimmed: true)
                }

                Section(header: ArticleHeader("THE CONDITIONS")) {
                    Text(articleMarkdown: "1. **Stop the sin** at once. Repentance while continuing is a claim, not a return.").font(.body)
                    Text(articleMarkdown: "2. **Regret** it in the heart; regret is the heart of repentance.").font(.body)
                    Text(articleMarkdown: "3. **Resolve firmly** never to return to it.").font(.body)
                    Text(articleMarkdown: "4. **Restore what belongs to others**: return wealth, seek the pardon of the one wronged, or make good the wrong. The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Whoever has oppressed another person concerning his reputation or anything else, he should beg him to forgive him before the Day of Resurrection when there will be no money (to compensate for wrong deeds), but if he has good deeds, those good deeds will be taken from him according to his oppression which he has done, and if he has no good deeds, the sins of the oppressed person will be loaded on him” (Sahih al-Bukhari 2449).", arabic: "مَنْ كَانَتْ لَهُ مَظْلَمَةٌ لأَحَدٍ مِنْ عِرْضِهِ أَوْ شَىْءٍ فَلْيَتَحَلَّلْهُ مِنْهُ الْيَوْمَ، قَبْلَ أَنْ لاَ يَكُونَ دِينَارٌ وَلاَ دِرْهَمٌ، إِنْ كَانَ لَهُ عَمَلٌ صَالِحٌ أُخِذَ مِنْهُ بِقَدْرِ مَظْلَمَتِهِ، وَإِنْ لَمْ تَكُنْ لَهُ حَسَنَاتٌ أُخِذَ مِنْ سَيِّئَاتِ صَاحِبِهِ فَحُمِلَ عَلَيْهِ", dimmed: true)
                    Text(articleMarkdown: "5. **Sincerity**: repentance for Allah's sake, not for fear of people or loss of standing.").font(.body)
                    Text(articleMarkdown: "6. **Before it is too late**: while the soul is in the body and before the signs of the Hour. Allah accepts the repentance of His servant until the death rattle (Sunan al-Tirmidhi 3537; graded hasan by al-Albani).").font(.body)
                }

                Section(header: ArticleHeader("HOW TO REPENT")) {
                    Text(articleMarkdown: "• **Make wudhu and pray two rak'ah**, then ask forgiveness with the tongue and the heart (Sunan Abi Dawud 1521; graded sahih by al-Albani). Any time is its time.").font(.body)
                    Text(articleMarkdown: "• **Say “Astaghfirullah”** (I seek Allah's forgiveness), and the best of it, the master supplication of forgiveness:").font(.body)
                    ScriptureQuote(text: "“The Prophet (ﷺ) said ‘The most superior way of asking for forgiveness from Allah is: O Allah, You are my Lord, there is none worthy of worship except You. You have created me, and I am Your servant, and I am faithful to Your covenant and promise as much as I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessings upon me, and I admit my sins. So forgive me, for none forgives sins except You” (Sahih al-Bukhari 6306).", arabic: "سَيِّدُ الاِسْتِغْفَارِ أَنْ تَقُولَ اللَّهُمَّ أَنْتَ رَبِّي، لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَىَّ وَأَبُوءُ لَكَ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ", dimmed: true)
                    Text(articleMarkdown: "• **Follow the sin with a good deed**:").font(.body)
                    ScriptureQuote(text: "“'Have Taqwa of Allah wherever you are, and follow an evil deed with a good one to wipe it out, and treat the people with good behavior” (Sunan al-Tirmidhi 1987; graded hasan by al-Albani).", arabic: "اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ", dimmed: true)
                    Text(articleMarkdown: "• **Conceal it**: a sin between you and Allah is not to be told to people. Ask His forgiveness; do not seek theirs for what they never knew.").font(.body)
                    Text(articleMarkdown: "• **Leave what leads to it**: the company, the place, the habit.").font(.body)
                }

                Section(header: ArticleHeader("IF YOU FALL AGAIN")) {
                    Text(verbatim: "Repent again. Returning to a sin does not cancel the earlier repentance, and the door does not shut for repeating. Allah said of a servant who sinned, repented, and sinned again:")
                        .font(.body)
                    ScriptureQuote(text: "“My slave has known that he has a Lord Who forgives sins and punishes for it I therefore have forgiven My slave (his sin), he can do whatever he likes” (Sahih al-Bukhari 7507).", arabic: "إِنَّ عَبْدًا أَصَابَ ذَنْبًا ـ وَرُبَّمَا قَالَ أَذْنَبَ ذَنْبًا ـ فَقَالَ رَبِّ أَذْنَبْتُ ـ وَرُبَّمَا قَالَ أَصَبْتُ ـ فَاغْفِرْ لِي فَقَالَ رَبُّهُ أَعَلِمَ عَبْدِي أَنَّ لَهُ رَبًّا يَغْفِرُ الذَّنْبَ وَيَأْخُذُ بِهِ غَفَرْتُ لِعَبْدِي. ثُمَّ مَكَثَ مَا شَاءَ اللَّهُ، ثُمَّ أَصَابَ ذَنْبًا أَوْ أَذْنَبَ ذَنْبًا، فَقَالَ رَبِّ أَذْنَبْتُ ـ أَوْ أَصَبْتُ ـ آخَرَ فَاغْفِرْهُ. فَقَالَ أَعَلِمَ عَبْدِي أَنَّ لَهُ رَبًّا يَغْفِرُ الذَّنْبَ وَيَأْخُذُ بِهِ غَفَرْتُ لِعَبْدِي، ثُمَّ مَكَثَ مَا شَاءَ اللَّهُ ثُمَّ أَذْنَبَ ذَنْبًا ـ وَرُبَّمَا قَالَ أَصَابَ ذَنْبًا ـ قَالَ قَالَ رَبِّ أَصَبْتُ ـ أَوْ أَذْنَبْتُ ـ آخَرَ فَاغْفِرْهُ لِي. فَقَالَ أَعَلِمَ عَبْدِي أَنَّ لَهُ رَبًّا يَغْفِرُ الذَّنْبَ وَيَأْخُذُ بِهِ غَفَرْتُ لِعَبْدِي ـ ثَلاَثًا ـ فَلْيَعْمَلْ مَا شَاءَ", dimmed: true)
                    Text(verbatim: "This is for the one whose repentance each time is sincere, not for one who repents in word intending to return. The Prophet (peace and blessings be upon him) himself said:")
                        .font(.body)
                    ScriptureQuote(text: "“By Allah! I ask for forgiveness from Allah and turn to Him in repentance more than seventy times a day” (Sahih al-Bukhari 6307).", arabic: "وَاللَّهِ إِنِّي لأَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ فِي الْيَوْمِ أَكْثَرَ مِنْ سَبْعِينَ مَرَّةً", dimmed: true)
                }

                Section(header: ArticleHeader("THE MERCY BEHIND IT")) {
                    ScriptureQuote(text: "“Allah, the Exalted and Glorious, Stretches out His Hand during the night so that the people may repent for the fault committed from dawn till dusk and He stretches out His Hand during the day so that the people may repent for the fault committed from dusk to dawn. (He would accept repentance) before the sun rises in the west (before the Day of Resurrection)” (Sahih Muslim 2759).", arabic: "إِنَّ اللَّهَ عَزَّ وَجَلَّ يَبْسُطُ يَدَهُ بِاللَّيْلِ لِيَتُوبَ مُسِيءُ النَّهَارِ وَيَبْسُطُ يَدَهُ بِالنَّهَارِ لِيَتُوبَ مُسِيءُ اللَّيْلِ حَتَّى تَطْلُعَ الشَّمْسُ مِنْ مَغْرِبِهَا", dimmed: true)
                    ScriptureQuote(text: "“By Him in Whose Hand is my life, if you were not to commit sin, Allah would sweep you out of existence and He would replace (you by) those people who would commit sin and seek forgiveness from Allah, and He would have pardoned them” (Sahih Muslim 2749).", arabic: "وَالَّذِي نَفْسِي بِيَدِهِ لَوْ لَمْ تُذْنِبُوا لَذَهَبَ اللَّهُ بِكُمْ وَلَجَاءَ بِقَوْمٍ يُذْنِبُونَ فَيَسْتَغْفِرُونَ اللَّهَ فَيَغْفِرُ لَهُمْ", dimmed: true)
                    ScriptureQuote(text: "“‘O son of Adam! Verily as long as you called upon Me and hoped in Me, I forgave you, despite whatever may have occurred from you, and I did not mind. O son of Adam! Were your sins to reach the clouds of the sky, then you sought forgiveness from Me, I would forgive you, and I would not mind. So son of Adam! If you came to me with sins nearly as great as the earth, and then you met Me not associating anything with Me, I would come to you with forgiveness nearly as great as it” (Sunan al-Tirmidhi 3540; graded sahih by al-Albani).", arabic: "قَالَ اللَّهُ يَا ابْنَ آدَمَ إِنَّكَ مَا دَعَوْتَنِي وَرَجَوْتَنِي غَفَرْتُ لَكَ عَلَى مَا كَانَ فِيكَ وَلاَ أُبَالِي يَا ابْنَ آدَمَ لَوْ بَلَغَتْ ذُنُوبُكَ عَنَانَ السَّمَاءِ ثُمَّ اسْتَغْفَرْتَنِي غَفَرْتُ لَكَ وَلاَ أُبَالِي يَا ابْنَ آدَمَ إِنَّكَ لَوْ أَتَيْتَنِي بِقُرَابِ الأَرْضِ خَطَايَا ثُمَّ لَقِيتَنِي لاَ تُشْرِكُ بِي شَيْئًا لأَتَيْتُكَ بِقُرَابِهَا مَغْفِرَةً", dimmed: true)
                }

                Section(header: ArticleHeader("COMMON QUESTIONS")) {
                    Text(articleMarkdown: "**Do I have to confess to anyone?** No. Confession is to Allah alone. The only exception is a wrong done to a person, whose right must be restored or pardoned.").font(.body)
                    Text(articleMarkdown: "**I cannot find the person I wronged.** Return the wealth to his heirs; if that is impossible, give it in charity on his behalf and ask Allah to forgive you. For a wrong to his honor, make dua for him and speak well of him where you spoke ill.").font(.body)
                    Text(articleMarkdown: "**Can shirk be forgiven?** Yes, by repentance in this life. What is not forgiven is dying upon it. Whoever enters Islam or returns to tawhid before death has everything before it wiped away.").font(.body)
                    Text(articleMarkdown: "**How do I know it was accepted?** By the sign the scholars name: you are better after it than before. Have good hope in Allah, for He is as His servant thinks Him to be.").font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Stop, regret, resolve, restore, and ask. Allah stretches out His hand every night and every day for exactly this, and He rejoices in your return.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "MakeDuaView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Repent")
    }
}

struct MakeDuaView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(articleMarkdown: "In short: **Dua (دُعَاء)** is worship itself: calling on Allah alone, with certainty, humility, praise and persistence, at the times and in the states He loves. Every sincere dua is answered: granted, deferred to the Hereafter, or exchanged for a harm turned away.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE COMMAND AND THE PROMISE")) {
                    ScriptureQuote(text: "“And when My servants ask you, [O Muhammad], concerning Me - indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. So let them respond to Me [by obedience] and believe in Me that they may be [rightly] guided” (Quran 2:186).", arabic: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌۖ أُجِيبُ دَعۡوَةَ ٱلدَّاعِ إِذَا دَعَانِۖ فَلۡيَسۡتَجِيبُواْ لِي وَلۡيُؤۡمِنُواْ بِي لَعَلَّهُمۡ يَرۡشُدُونَ")
                    ScriptureQuote(text: "“And your Lord says, \"Call upon Me; I will respond to you.\" Indeed, those who disdain My worship will enter Hell [rendered] contemptible” (Quran 40:60).", arabic: "وَقَالَ رَبُّكُمُ ٱدۡعُونِيٓ أَسۡتَجِبۡ لَكُمۡۚ إِنَّ ٱلَّذِينَ يَسۡتَكۡبِرُونَ عَنۡ عِبَادَتِي سَيَدۡخُلُونَ جَهَنَّمَ دَاخِرِينَ")
                    ScriptureQuote(text: "“Supplication (du'a') is itself the worship” (Sunan Abi Dawud 1479).", arabic: "الدُّعَاءُ هُوَ الْعِبَادَةُ { قَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ }", dimmed: true)
                    ScriptureQuote(text: "“The supplication of the servant is granted in case he does not supplicate for sin or for severing the ties of blood, or he does not become impatient. It was said: Allah's Messenger, what does:‘ If he does not grow impatient’ imply? He said: That he should say like this: I supplicated and I supplicated but I did not find it being responded. and theu he becomes frustrated and abandons supplication” (Sahih Muslim 2735).", arabic: "لاَ يَزَالُ يُسْتَجَابُ لِلْعَبْدِ مَا لَمْ يَدْعُ بِإِثْمٍ أَوْ قَطِيعَةِ رَحِمٍ مَا لَمْ يَسْتَعْجِلْ يَقُولُ قَدْ دَعَوْتُ وَقَدْ دَعَوْتُ فَلَمْ أَرَ يَسْتَجِيبُ لِي فَيَسْتَحْسِرُ عِنْدَ ذَلِكَ وَيَدَعُ الدُّعَاءَ", dimmed: true)
                }

                Section(header: ArticleHeader("THE MANNERS OF DUA")) {
                    Text(articleMarkdown: "1. **Sincerity**: ask Allah alone, with no intermediary, calling on none but Him.").font(.body)
                    Text(articleMarkdown: "2. **Begin with praise** of Allah and prayers upon the Prophet (peace and blessings be upon him), and end with them.").font(.body)
                    Text(articleMarkdown: "3. **Face the qiblah and raise the hands**, palms up, as he did at Badr and at Arafah.").font(.body)
                    ScriptureQuote(text: "“Your Lord is munificent and generous, and is ashamed to turn away empty the hands of His servant when he raises them to Him” (Sunan Abi Dawud 1488).", arabic: "إِنَّ رَبَّكُمْ تَبَارَكَ وَتَعَالَى حَيِيٌّ كَرِيمٌ يَسْتَحْيِي مِنْ عَبْدِهِ إِذَا رَفَعَ يَدَيْهِ إِلَيْهِ أَنْ يَرُدَّهُمَا صِفْرًا", dimmed: true)
                    Text(articleMarkdown: "4. **Ask with certainty**, resolutely, and lower your voice:").font(.body)
                    ScriptureQuote(text: "“None of you should say: 'O Allah, forgive me if You wish; O Allah, be merciful to me if You wish,' but he should always appeal to Allah with determination, for nobody can force Allah to do something against His Will” (Sahih al-Bukhari 6339).", arabic: "لاَ يَقُولَنَّ أَحَدُكُمُ اللَّهُمَّ اغْفِرْ لِي، اللَّهُمَّ ارْحَمْنِي، إِنْ شِئْتَ. لِيَعْزِمِ الْمَسْأَلَةَ، فَإِنَّهُ لاَ مُكْرِهَ لَهُ", dimmed: true)
                    Text(articleMarkdown: "5. **Repeat** your request, three times as the Prophet did, and be persistent over the days.").font(.body)
                    Text(articleMarkdown: "6. **Ask for everything**, the great and the small, for yourself, your parents and the believers, and for the Hereafter above the world.").font(.body)
                    Text(articleMarkdown: "7. **Use the Names of Allah** suited to your need, and the Prophet's own words where you know them.").font(.body)
                    Text(articleMarkdown: "8. **Keep your earnings and food lawful**; a body fed on the unlawful is slow to be answered:").font(.body)
                    ScriptureQuote(text: "“O people, Allah is Good and He therefore, accepts only that which is good … He then made a mention of a person who travels widely, his hair disheveled and covered with dust. He lifts his hand towards the sky (and thus makes the supplication): ‘O Lord, O Lord,’ whereas his diet is unlawful, his drink is unlawful, and his clothes are unlawful and his nourishment is unlawful. How can then his supplication be accepted?” (Sahih Muslim 1015).", arabic: "أَيُّهَا النَّاسُ إِنَّ اللَّهَ طَيِّبٌ لاَ يَقْبَلُ إِلاَّ طَيِّبًا وَإِنَّ اللَّهَ أَمَرَ الْمُؤْمِنِينَ بِمَا أَمَرَ بِهِ الْمُرْسَلِينَ فَقَالَ { يَا أَيُّهَا الرُّسُلُ كُلُوا مِنَ الطَّيِّبَاتِ وَاعْمَلُوا صَالِحًا إِنِّي بِمَا تَعْمَلُونَ عَلِيمٌ} وَقَالَ { يَا أَيُّهَا الَّذِينَ آمَنُوا كُلُوا مِنْ طَيِّبَاتِ مَا رَزَقْنَاكُمْ} . ثُمَّ ذَكَرَ الرَّجُلَ يُطِيلُ السَّفَرَ أَشْعَثَ أَغْبَرَ يَمُدُّ يَدَيْهِ إِلَى السَّمَاءِ يَا رَبِّ يَا رَبِّ وَمَطْعَمُهُ حَرَامٌ وَمَشْرَبُهُ حَرَامٌ وَمَلْبَسُهُ حَرَامٌ وَغُذِيَ بِالْحَرَامِ فَأَنَّى يُسْتَجَابُ لِذَلِكَ", dimmed: true)
                }

                Section(header: ArticleHeader("THE TIMES OF ANSWER")) {
                    Text(articleMarkdown: "• **The last third of the night**, when Allah descends and asks who is calling on Him (Sahih al-Bukhari 1145).").font(.body)
                    Text(articleMarkdown: "• **In prostration**:").font(.body)
                    ScriptureQuote(text: "“The nearest a servant comes to his Lord is when he is prostrating himself, so make supplication (in this state)” (Sahih Muslim 482).", arabic: "أَقْرَبُ مَا يَكُونُ الْعَبْدُ مِنْ رَبِّهِ وَهُوَ سَاجِدٌ فَأَكْثِرُوا الدُّعَاءَ", dimmed: true)
                    Text(articleMarkdown: "• **Between the adhan and the iqamah**:").font(.body)
                    ScriptureQuote(text: "“The supplication made between the adhan and the iqamah is not rejected” (Sunan Abi Dawud 521).", arabic: "لاَ يُرَدُّ الدُّعَاءُ بَيْنَ الأَذَانِ وَالإِقَامَةِ", dimmed: true)
                    Text(articleMarkdown: "• **After the tashahhud before the taslim**, and after the obligatory prayers.").font(.body)
                    Text(articleMarkdown: "• **An hour on Friday**, which the scholars place at the end of the day before Maghrib or between the khutbah and the prayer (Sahih al-Bukhari 935).").font(.body)
                    Text(articleMarkdown: "• **When rain falls, when traveling, and when oppressed**:").font(.body)
                    ScriptureQuote(text: "“Three supplications are accepted, there is no doubt in them (about them being accepted): The supplication of the oppressed, the supplication of the traveler, and the supplication of his father against his son” (Sunan al-Tirmidhi 1905; graded hasan by al-Albani).", arabic: "ثَلاَثُ دَعَوَاتٍ مُسْتَجَابَاتٌ لاَ شَكَّ فِيهِنَّ دَعْوَةُ الْمَظْلُومِ وَدَعْوَةُ الْمُسَافِرِ وَدَعْوَةُ الْوَالِدِ عَلَى وَلَدِهِ", dimmed: true)
                    Text(articleMarkdown: "• **On the day of Arafah, in Ramadan, and in Laylat al-Qadr**, and at Zamzam for the pilgrim.").font(.body)
                }

                Section(header: ArticleHeader("WHAT TO AVOID")) {
                    Text(verbatim: "• Asking for a sin, or against family ties.").font(.body)
                    Text(verbatim: "• Giving up: “I asked and was not answered.”").font(.body)
                    Text(verbatim: "• Asking through the dead or the absent; dua is directed to Allah alone, and the living may be asked to pray for you.").font(.body)
                    Text(verbatim: "• Hurried, distracted asking with a heedless heart; gather the heart before the tongue speaks.").font(.body)
                    Text(verbatim: "• Rhyming and affectation in wording, and raising the voice unduly; Allah is near.").font(.body)
                }

                Section(header: ArticleHeader("THE THREE ANSWERS")) {
                    Text(verbatim: "The Prophet (peace and blessings be upon him) taught that no Muslim makes a dua free of sin and the cutting of ties except that Allah gives him one of three: his request soon, or its storing for the Hereafter, or the turning away of an equal harm (Musnad Ahmad 11133; graded hasan). Whoever understands this never counts a dua unanswered.")
                        .font(.body)
                    ScriptureQuote(text: "“Allah says: 'I am just as My slave thinks I am, (i.e. I am able to do for him what he thinks I can do for him) and I am with him if He remembers Me” (Sahih al-Bukhari 7405).", arabic: "يَقُولُ اللَّهُ تَعَالَى أَنَا عِنْدَ ظَنِّ عَبْدِي بِي، وَأَنَا مَعَهُ إِذَا ذَكَرَنِي، فَإِنْ ذَكَرَنِي فِي نَفْسِهِ ذَكَرْتُهُ فِي نَفْسِي، وَإِنْ ذَكَرَنِي فِي مَلأٍ ذَكَرْتُهُ فِي مَلأٍ خَيْرٍ مِنْهُمْ، وَإِنْ تَقَرَّبَ إِلَىَّ بِشِبْرٍ تَقَرَّبْتُ إِلَيْهِ ذِرَاعًا، وَإِنْ تَقَرَّبَ إِلَىَّ ذِرَاعًا تَقَرَّبْتُ إِلَيْهِ بَاعًا، وَإِنْ أَتَانِي يَمْشِي أَتَيْتُهُ هَرْوَلَةً", dimmed: true)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Praise Him, send prayers on His Prophet, raise your hands, ask with certainty and persistence at the hours He loves, and know that no sincere call to Allah is ever lost.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("How to Make Dua")
    }
}

// MARK: - Article sources

/// One row of an article's SOURCES section: a printed work (no URL) or a verified fatwa page.
struct ArticleSource: Hashable {
    let title: String
    let subtitle: String
    var url: String? = nil
}

/// The SOURCES section every Pillars & Beliefs and How-to article ends with. The ayat above it are
/// the app's own Hafs text with the Saheeh International translation and the hadith are quoted from
/// the app's hadith packs with their grades; this section names the printed works and the fatwa
/// pages of the scholars of the Sunnah that the article's explanations rest on. Rows with a URL open
/// it; rows without one name a book.
struct ArticleSourcesSection: View {
    @Environment(\.appearance) private var appearance

    /// The article view's type name, the key into `ArticleSources.table`.
    let article: String

    var body: some View {
        if let sources = ArticleSources.table[article], !sources.isEmpty {
            Section {
                ForEach(sources, id: \.self) { source in
                    if let raw = source.url, let url = URL(string: raw) {
                        Link(destination: url) { row(source, linked: true) }
                    } else {
                        row(source, linked: false)
                    }
                }
            } header: {
                ArticleHeader("SOURCES")
            } footer: {
                Text(verbatim: "Every ayah above is quoted from the app's own Quran text (Hafs, Saheeh International translation) and every hadith from the app's hadith collections with its grading. The works and fatwa pages listed here are where the explanations and rulings come from. Ask a qualified scholar about anything specific to your situation.")
            }
        }
    }

    private func row(_ source: ArticleSource, linked: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: linked ? "link" : "book.closed")
                .font(.footnote)
                .foregroundColor(appearance.accent)

            VStack(alignment: .leading, spacing: 1) {
                Text(source.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(source.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 4)

            if linked {
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
