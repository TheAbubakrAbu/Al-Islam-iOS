import SwiftUI

/// The How-to Guides index. Rows come from `IslamArticleCatalog.guidesGroups`, the same list the
/// search reads, so a result can say which section a guide sits in - see PillarsView for the shape.
struct GuidesView: View {
    /// An article to push on top of the index as it appears: a result on the Islam tab's root. Nil opens
    /// the plain index (a DEBUG build may still take one from `-guidesArticle`, see `ArticleAutoOpen`).
    var openArticle: IslamArticleOpenRequest?

    init(openArticle: IslamArticleOpenRequest? = nil) {
        self.openArticle = openArticle
    }

    #if os(iOS)
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The index row a result asked to scroll to ("Scroll To Article"), consumed once the search clears.
    @State private var scrollTarget: String?
    @StateObject private var search = IslamArticleSearchModel()
    /// The filter row over the results (`IslamSearchFilterBar`): Topics, Match, Words, Without, Best Match.
    @State private var searchFilters = IslamSearchFilters.remembered()
    /// The guide the hero's path opened (a catalog id).
    @State private var heroArticle: String?
    #endif

    var body: some View {
        #if os(iOS)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        ScrollViewReader { proxy in
            List {
                Group {
                    if query.isEmpty {
                        Section {
                            GuidesPathHero(open: $heroArticle)
                                .articleCardRow()
                        }

                        IslamArticleIndexSections(groups: IslamArticleCatalog.guidesGroups)
                    } else {
                        if searchFilters.shows(.askAI) {
                            AskAISearchSection(query: query)
                        }

                        IslamArticleSearchSections(
                            query: query,
                            homes: [.guides],
                            contentHits: search.contentHits,
                            isSearching: search.isSearching,
                            onScrollTo: { entry in
                                withAnimation { searchText = "" }
                                scrollTarget = entry.listID
                            },
                            filters: searchFilters,
                            reference: search.reference
                        )
                    }
                }
                .themedListRowBackground()
            }
            .englishArticle()
            .applyConditionalListStyle()
            .autoOpenArticle(openArticle, home: .guides)
            .pushDestination(isPresented: Binding(
                get: { heroArticle != nil },
                set: { if !$0 { heroArticle = nil } }
            )) {
                if let heroArticle { IslamArticleCatalog.destination(id: heroArticle) }
            }
            .islamSearchFilterChrome($searchFilters, isSearching: !query.isEmpty, homes: [.guides],
                                     kinds: [.scripture, .articles, .passages, .askAI])
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
            search.update(query: text, homes: [.guides], filters: searchFilters)
            if !text.isEmpty { scrollTarget = nil }
        }
        .onChange(of: searchFilters) { filters in
            search.update(query: searchText, homes: [.guides], filters: filters)
        }
        #else
        List {
            IslamArticleIndexSections(groups: IslamArticleCatalog.guidesGroups)
                .themedListRowBackground()
        }
        .englishArticle()
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
            // A source whose link does not parse has no row, and is left out before the ForEach: a
            // row that may be nothing is one the List has to build to count (see `OneRow`).
            ForEach(sources.paired { URL(string: $0.url) }, id: \.item.url) { pair in
                let source = pair.item
                let url = pair.found
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
        } header: {
            Text(articleMarkdown: "SOURCES & FURTHER READING")
        } footer: {
            Text(verbatim: "Every ruling above traces back to the Quran and the authentic Sunnah. These links open the sources themselves. Read them, and ask a qualified scholar about anything specific to your situation.")
        }
    }
}

/// A dua inside a guide, drawn as the Dua screen draws its rows (`AdhkarRow`: the Arabic, its
/// transliteration, the translation, the citation, Listen, and the copy menu). The words are the
/// shelf's, read by the same reference and token ranges a `DuaItem` on the Dua screen uses, never
/// a copy typed into the article; until the shelf answers (one off-main read the first time) the row
/// shows the transliteration alone, as the Dua screen's own rows do on a cold launch.
struct GuideDuaRow: View {
    let dua: DuaItem
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @State private var resolved: DuaItem?

    init(_ dua: DuaItem) {
        self.dua = dua
    }

    var body: some View {
        let shown = resolved ?? dua
        AdhkarRow(
            arabicText: shown.arabicText,
            transliteration: shown.transliteration,
            translation: shown.translation,
            useQuranicFont: quranDisplay.useFontArabic,
            alwaysTrailing: true,
            speechEnabled: true,
            source: shown.reference
        )
        .equatable()
        .spokenRowWash(shown.arabicText)
        .task(id: dua.id) {
            guard resolved == nil, dua.source != nil else { return }
            let unresolved = dua
            resolved = await Task.detached(priority: .userInitiated) { unresolved.resolved() }.value
        }
    }
}

struct HowToPrayView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: prayer (**Salaah, صَلَاة**) is performed facing the Qiblah after purifying yourself, moving through standing, bowing, and prostrating while reciting the Quran and remembering Allah, praying as the Prophet (peace and blessings be upon him) prayed.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("BEFORE YOU PRAY")) {
                        ArticleStep("1. **Purity (Tahaarah, طَهَارَة)**: have valid **Wudu (وُضُوء)**, or Ghusl if required, with a clean body, clothes, and place of prayer.")
                        ArticleStep("2. **Cover the Awrah (عَورَة)**: men from the navel to the knee at least; women cover the whole body except the face and hands; most scholars, Ibn Baaz among them, hold that the feet must be covered as well.")
                        ArticleStep("3. **Face the Qiblah (قِبلَة)**: the direction of the Ka‘bah in Makkah.")
                        ArticleStep("4. **Correct time**: each prayer has its own window: Fajr, Dhuhr, Asr, Maghrib, and Isha.")
                        ArticleStep("5. **Intention (Niyyah, نِيَّة)**: intend the specific prayer in the heart; it is not spoken aloud.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("BEFORE YOU PRAY")) {
                        ArticleStep("1. **Purity (Tahaarah, طَهَارَة)**: have **Wudu (وُضُوء)**, or Ghusl if required, with a clean body, clothes, and place.")
                        ArticleStep("2. **Cover the Awrah (عَورَة)**: a man from the navel to the knee at least; a woman her whole body except the face and hands, and her feet too in the view of most scholars.")
                        ArticleStep("3. **Face the Qiblah (قِبلَة)**, the direction of the Ka‘bah.")
                        ArticleStep("4. **Pray in its time**: each of the five prayers has its own window.")
                        ArticleStep("5. **Intend (Niyyah, نِيَّة)** the specific prayer in the heart, not aloud.")
                    }
                }

                Section(header: ArticleHeader("NUMBER OF UNITS (RAK‘AH)")) {
                    ArticleParagraph(articleMarkdown: "The obligatory **rak‘ah (رَكعَة)** are: **Fajr** 2 · **Dhuhr** 4 · **Asr** 4 · **Maghrib** 3 · **Isha** 4.")
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:631", cite: "Saheeh al-Bukhaari 631", arabic: 73...76, english: 98...104)
                    ArticleStep("1. **Takbeer (تَكبِير)**: raise the hands and say “Allahu Akbar,” then place the right hand over the left upon the chest.")
                    ArticleStep("2. **Recitation**: say the opening supplication, then recite Surah **Al-Faatihah (الفَاتِحَة)**, required in every rak‘ah, followed by another passage of the Quran in the first two rak‘ah.")
                    ArticleStep("3. **Ruku (رُكُوع)**: bow with a straight back, hands on the knees, saying “Subhaana Rabbi al-Azeem” three times.")
                    ArticleStep("4. **Rising (I‘tidaal)**: rise saying “Sami‘a Allahu liman hamidah,” then, standing, “Rabbana wa laka al-hamd.”")
                    ArticleStep("5. **Sujood (سُجُود)**: prostrate on seven parts (the forehead and nose, both palms, both knees, and the toes), saying “Subhaana Rabbi al-A‘la” three times.")
                    ArticleStep("6. **Sit** and say “Rabbi ighfir li,” then make a second **Sujood** the same way. This completes one rak‘ah; stand for the next.")
                    ArticleStep("7. **Tashahhud (تَشَهُّد)**: after every two rak‘ah, sit and recite the tashahhud; in the final sitting add the prayers upon the Prophet (peace and blessings be upon him) and supplication.")
                    ArticleStep("8. **Tasleem (تَسلِيم)**: end the prayer by turning the face to the right, then the left, saying each time “As-salaamu alaykum wa rahmatullah.”")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE COMMAND TO PRAY")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "2:43")

                        ScriptureQuote(quran: "4:103", words: 13...19)

                        ScriptureQuote(quran: "2:238")

                        ScriptureQuote(quran: "29:45", words: 8...16)
                    }

                    Section(header: ArticleHeader("ITS PLACE AND ITS WEIGHT")) {
                        ArticleParagraph(verbatim: "The prayer is the first thing a person will be asked about. The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "tirmidhi:413", cite: "Jaami‘ at-Tirmidhi 413; graded saheeh by al-Albaani", arabic: 71...91, english: 68...107)

                        ArticleParagraph(verbatim: "It is the line between belief and disbelief:")
                        ScriptureQuote(hadith: "muslim:82a", cite: "Saheeh Muslim 82a", arabic: 34...41, english: 21...33)

                        ArticleParagraph(verbatim: "And it washes a person clean:")
                        ScriptureQuote(hadith: "bukhari:528", cite: "Saheeh al-Bukhaari 528, Saheeh Muslim 667", arabic: 35...68, english: 6...65)

                        ArticleParagraph(verbatim: "Praying in congregation multiplies it further:")
                        ScriptureQuote(hadith: "bukhari:645", cite: "Saheeh al-Bukhaari 645, Saheeh Muslim 650", arabic: 25...32, english: 4...19)

                        ArticleParagraph(verbatim: "And its calm is a mercy. The Prophet (peace and blessings be upon him) would say to Bilaal:")
                        ScriptureQuote(hadith: "abudawud:4985", cite: "Sunan Abi Daawood 4985; graded saheeh by al-Albaani", arabic: 47...52, english: 45...55)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Purify yourself, face the Qiblah, and pray with presence of heart (Takbeer, Faatihah, Ruku, Sujood, Tashahhud, and Tasleem), exactly as the Prophet (peace and blessings be upon him) taught.")
                }

                ArticleSourcesSection(article: "HowToPrayView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "HowToPrayView")
        .navigationTitle("How to Pray")
    }
}

struct HowToFastView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: to fast (**Sawm, صَوم**) is to abstain from food, drink, and intimacy from dawn (**Fajr**) to sunset (**Maghrib**) with the intention of seeking Allah's pleasure, especially in Ramadan.")
                }

                Section(header: ArticleHeader("1. MAKE THE INTENTION")) {
                    ArticleParagraph(articleMarkdown: "Form the **Niyyah (نِيَّة)** to fast in the heart before **Fajr**. For an obligatory Ramadan fast, intend it the night before. The Prophet (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "abudawud:2454", cite: "Sunan Abi Daawood 2454; graded saheeh by al-Albaani", arabic: 51...59, english: 6...17)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("2. EAT SUHOOR")) {
                        ArticleParagraph(articleMarkdown: "Take the pre-dawn meal, **Suhoor (سُحُور)**, which is a blessed Sunnah, and stop eating and drinking at the entry of **Fajr**.")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1923", cite: "Saheeh al-Bukhaari 1923", arabic: 31...35, english: 4...12)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("2. EAT SUHOOR")) {
                        ArticleParagraph(articleMarkdown: "Take the pre-dawn meal, **Suhoor (سُحُور)**, which is a blessed Sunnah, and stop eating and drinking at the entry of **Fajr**.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("3. FAST THROUGH THE DAY")) {
                        ArticleParagraph(verbatim: "From Fajr to Maghrib, abstain from food, drink, and intimacy. The fast is also of the limbs and tongue: guard against lying, backbiting, and anger.")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1903", cite: "Saheeh al-Bukhaari 1903", arabic: 32...46, english: 4...32)
                    }

                    Section(header: ArticleHeader("4. BREAK THE FAST AT MAGHRIB")) {
                        ArticleParagraph(articleMarkdown: "Break the fast (**Iftaar, إِفطَار**) as soon as the sun sets. Hastening it is the Sunnah:")
                        ScriptureQuote(hadith: "bukhari:1957", cite: "Saheeh al-Bukhaari 1957", arabic: 24...30, english: 4...21)
                        ArticleParagraph(verbatim: "Anas (may Allah be pleased with him) described how the Prophet (peace and blessings be upon him) broke his fast:")
                        ScriptureQuote(hadith: "abudawud:2356", cite: "Sunan Abi Daawood 2356; graded hasan saheeh by al-Albaani", arabic: 20...45, english: 0...41)
                        ArticleParagraph(verbatim: "And he would say when he broke his fast:")
                        ScriptureQuote(hadith: "abudawud:2357", cite: "Sunan Abi Daawood 2357; graded hasan by al-Albaani", arabic: 51...59, english: 32...46)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("3. FAST THROUGH THE DAY")) {
                        ArticleParagraph(verbatim: "From Fajr to Maghrib, abstain from food, drink, and intimacy. The fast is also of the limbs and tongue: guard against lying, backbiting, and anger.")
                    }

                    Section(header: ArticleHeader("4. BREAK THE FAST AT MAGHRIB")) {
                        ArticleParagraph(articleMarkdown: "Break the fast (**Iftaar, إِفطَار**) as soon as the sun sets. Hastening it is the Sunnah:")
                        ScriptureQuote(hadith: "bukhari:1957", cite: "Saheeh al-Bukhaari 1957", arabic: 24...30, english: 4...21)
                    }
                }

                Section(header: ArticleHeader("WHAT INVALIDATES THE FAST")) {
                    ArticleParagraph(verbatim: "Deliberately eating or drinking, intentional intimacy, and the onset of menstruation or postpartum bleeding break the fast. Eating or drinking by genuine forgetfulness does not; one simply continues fasting. The Prophet (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:1933", cite: "Saheeh al-Bukhaari 1933", arabic: 28...37, english: 4...29)
                }

                Section(header: ArticleHeader("WHO IS EXCUSED")) {
                    ArticleParagraph(articleMarkdown: "The sick, travelers, pregnant and nursing women, and the elderly who cannot fast are excused; missed fasts are made up later, or a **Fidyah (فِديَة)** (feeding a needy person per day) is given by those unable to fast at all. Allah (Glorified and Exalted be He) says:")
                    ScriptureQuote(quran: "2:184", words: 2...18)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Intend the fast, take Suhoor, abstain from dawn to sunset while guarding your character, then hasten to break the fast at Maghrib, turning the whole day into worship and gratitude.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHY WE FAST")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "2:183")
                        ScriptureQuote(quran: "2:185", words: 0...11)
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1904", cite: "Saheeh al-Bukhaari 1904, Saheeh Muslim 1151", arabic: 37...50, english: 4...29)
                        ScriptureQuote(hadith: "bukhari:38", cite: "Saheeh al-Bukhaari 38, Saheeh Muslim 760", arabic: 29...39, english: 4...29)
                        ScriptureQuote(hadith: "bukhari:1896", cite: "Saheeh al-Bukhaari 1896", arabic: 28...60, english: 4...33)
                    }
                }

                ArticleSourcesSection(article: "HowToFastView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "HowToFastView")
        .navigationTitle("How to Fast")
    }
}

struct HowToZakahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Zakaah (زَكَاة)** is the obligatory annual charity of **2.5%** on wealth that reaches the **Nisaab (نِصَاب)** and is held for a full lunar year, given to those Allah named as its recipients.")
                }

                Section(header: ArticleHeader("1. CHECK IF YOU MUST PAY")) {
                    ArticleParagraph(articleMarkdown: "Zakaah is due on a Muslim whose zakaatable wealth reaches the **Nisaab (نِصَاب)**, the minimum threshold (equal to about **85 grams of gold** or **595 grams of silver**), and has been held for one full lunar (Hijri) year (**Hawl, حَول**).")
                }

                Section(header: ArticleHeader("2. TOTAL YOUR ZAKAATABLE WEALTH")) {
                    ArticleParagraph(verbatim: "Include cash and savings, gold and silver, money owed to you that you expect back, business merchandise, and investments held for gain. Personal items (your home, car, and everyday belongings) are not counted.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("3. CALCULATE 2.5%")) {
                        ArticleParagraph(articleMarkdown: "If your total is at or above the Nisaab after the year has passed, give **2.5%** (one fortieth) of it. It becomes due the moment the year completes and must not be delayed past that; it may be paid early, so many bring it forward to Ramadan for the extra reward.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("3. CALCULATE 2.5%")) {
                        ArticleParagraph(articleMarkdown: "If your total is at or above the Nisaab when the year completes, give **2.5%** (one fortieth) of it, without delay. It may be paid early, as many do in Ramadan.")
                    }
                }

                Section(header: ArticleHeader("4. GIVE IT TO THOSE ENTITLED")) {
                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) named eight categories of recipients:")
                    ScriptureQuote(quran: "9:60", words: 1...16)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Once your wealth reaches the Nisaab and a lunar year passes, give 2.5% of it to the deserving, purifying your wealth, helping the needy, and fulfilling a pillar of Islam.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHY WE GIVE ZAKAAH")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "9:103", words: 0...8)
                        ScriptureQuote(quran: "2:110", words: 0...11)
                        ArticleParagraph(verbatim: "It is not a favour to the poor. It is their right in your wealth, and withholding it is a warning:")
                        ScriptureQuote(quran: "3:180", words: 0...21)
                        ArticleParagraph(verbatim: "When the Prophet (peace and blessings be upon him) sent Mu‘aadh to Yemen, he told him:")
                        ScriptureQuote(hadith: "bukhari:1395", cite: "Saheeh al-Bukhaari 1395, Saheeh Muslim 19a", arabic: 77...90, english: 66...98)
                    }
                }

                ArticleSourcesSection(article: "HowToZakahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "HowToZakahView")
        .navigationTitle("How to Give Zakaah")
    }
}

struct HowToHajjView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Hajj (حَجّ)** is the pilgrimage to Makkah performed once in a lifetime by those able, over the days of **Dhul-Hijjah**: entering Ihraam, standing at Arafah, and completing the rites the Prophet (peace and blessings be upon him) taught.")
                }

                Section(header: ArticleHeader("BEFORE YOU GO")) {
                    ArticleParagraph(articleMarkdown: "Hajj is obligatory once for every Muslim who is physically and financially able. Repent sincerely, settle debts, seek lawful provision, and learn the rites. Hajj takes place from the 8th to the 13th of **Dhul-Hijjah (ذُو الحِجَّة)**.")
                }

                Section(header: ArticleHeader("1. ENTER IHRAAM")) {
                    ArticleParagraph(articleMarkdown: "At the appointed boundary (**Meeqaat, مِيقَات**), bathe, wear the Ihraam garments (two unstitched cloths for men; ordinary modest dress for women), make the intention for Hajj, and begin the **Talbiyah (تَلبِيَة)**. Ibn Umar (may Allah be pleased with him) reported the Talbiyah of the Messenger of Allah (peace and blessings be upon him):")
                    ScriptureQuote(hadith: "bukhari:1549", cite: "Saheeh al-Bukhaari 1549", arabic: 27...42, english: 7...21)
                }

                Section(header: ArticleHeader("2. DAY 8: MINA")) {
                    ArticleParagraph(articleMarkdown: "Travel to **Mina (مِنَى)** and pray Dhuhr, Asr, Maghrib, Isha, and Fajr there, each at its time (the four-unit prayers shortened to two).")
                }

                Section(header: ArticleHeader("3. DAY 9: ARAFAH")) {
                    ArticleParagraph(articleMarkdown: "After sunrise proceed to **Arafah (عَرَفَة)** and stand there in supplication until sunset; this standing (**Wuqoof**) is the essence of Hajj. Dhuhr and Asr are combined and shortened. The Prophet (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "tirmidhi:889", cite: "Jaami‘ at-Tirmidhi 889; graded saheeh by al-Albaani", arabic: 44...70, english: 29...80)
                    ArticleParagraph(articleMarkdown: "After sunset, move to **Muzdalifah (مُزدَلِفَة)**, combine Maghrib and Isha, rest for the night, and gather pebbles.")
                }

                Section(header: ArticleHeader("4. DAY 10: EID (YAWM AN-NAHR)")) {
                    ArticleParagraph(articleMarkdown: "Stone the large pillar (**Jamrat al-Aqabah**) with seven pebbles, offer the sacrifice (**Hady, هَدي**) if performing tamattu' or qiraan, shave or trim the hair, then perform **Tawaaf al-Ifaadah** around the Ka‘bah and **Sa‘i (سَعي)** between Safa and Marwah (a qaarin or mufrid who made Sa‘i after the arrival Tawaaf does not repeat it). After the stoning and the shaving, everything but marital relations becomes lawful; after the Tawaaf, all of it.")
                }

                Section(header: ArticleHeader("5. DAYS 11–13: TASHREEQ")) {
                    ArticleParagraph(articleMarkdown: "Stay in Mina and stone the three pillars (**Jamaraat**) each afternoon. A pilgrim may leave after the 12th if he departs before sunset, otherwise he completes the 13th.")
                }

                Section(header: ArticleHeader("6. FAREWELL TAWAAF")) {
                    ArticleParagraph(articleMarkdown: "Before leaving Makkah, perform the farewell circumambulation (**Tawaaf al-Wada, طَوَاف الوَدَاع**) so the last act at the Sacred House is Tawaaf.")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Enter Ihraam at the Meeqaat, stand at Arafah, spend the night at Muzdalifah, then on Eid stone, sacrifice, shave, and perform Tawaaf and Sa‘i, completing the days of Mina and a farewell Tawaaf, returning cleansed of sin.")
                }

                ArticleSourcesSection(article: "HowToHajjView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "HowToHajjView")
        .navigationTitle("How to Perform Hajj")
    }
}

struct HowToUmrahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Umrah (عُمرَة)**, the “lesser pilgrimage,” which may be done at any time of year, is Ihraam, Tawaaf around the Ka‘bah, Sa‘i between Safa and Marwah, and shaving or trimming the hair.")
                }

                Section(header: ArticleHeader("1. ENTER IHRAAM")) {
                    ArticleParagraph(articleMarkdown: "At the **Meeqaat (مِيقَات)**, bathe, wear the Ihraam (two unstitched cloths for men; modest dress for women), make the intention for Umrah with the words “Labbayk Allahumma umratan” (here I am, O Allah, for Umrah), then recite the **Talbiyah (تَلبِيَة)** of the Prophet (peace and blessings be upon him):")
                    ScriptureQuote(hadith: "bukhari:1549", cite: "Saheeh al-Bukhaari 1549", arabic: 27...42, english: 7...21)
                    ArticleParagraph(verbatim: "In Ihraam, avoid perfume, cutting hair or nails, and marital relations.")
                }

                Section(header: ArticleHeader("2. TAWAAF")) {
                    ArticleParagraph(articleMarkdown: "At the Sacred Mosque, circle the **Ka‘bah (الكَعبَة)** seven times (**Tawaaf, طَوَاف**), beginning and ending at the Black Stone. Then pray two rak‘ah behind the **Maqaam Ibraaheem (مَقَام إِبرَاهِيم)** if able, and drink **Zamzam (زَمزَم)**.")
                }

                Section(header: ArticleHeader("3. SA‘I")) {
                    ArticleParagraph(articleMarkdown: "Walk seven times between the hills of **Safa (الصَّفَا)** and **Marwah (المَروَة)** (**Sa‘i, سَعي**), starting at Safa and ending at Marwah, remembering Allah and supplicating, as **Haajar** (may Allah be pleased with her) once searched there for water.")
                }

                Section(header: ArticleHeader("4. SHAVE OR TRIM")) {
                    ArticleParagraph(articleMarkdown: "Men shave the head (**Halq, حَلق**) or trim it; women trim a fingertip's length (**Taqseer, تَقصِير**). With this the Umrah is complete and the pilgrim leaves the state of Ihraam.")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Enter Ihraam at the Meeqaat, perform Tawaaf around the Ka‘bah, make Sa‘i between Safa and Marwah, and shave or trim, a complete Umrah that may be done any time of the year.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE VIRTUE OF UMRAH")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "2:196", words: 0...3)
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1773", cite: "Saheeh al-Bukhaari 1773, Saheeh Muslim 1349", arabic: 37...49, english: 4...35)
                        ScriptureQuote(hadith: "bukhari:1782", cite: "Saheeh al-Bukhaari 1782, Saheeh Muslim 1256", arabic: 65...69, english: 71...79)
                        ArticleParagraph(verbatim: "And of the journey itself he said:")
                        ScriptureQuote(hadith: "tirmidhi:810", cite: "Jaami‘ at-Tirmidhi 810; graded hasan saheeh by al-Albaani", arabic: 35...55, english: 5...39)
                    }
                }

                ArticleSourcesSection(article: "HowToUmrahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "HowToUmrahView")
        .navigationTitle("How to Perform Umrah")
    }
}

import SwiftUI

// MARK: - Purification

struct TayammumView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Tayammum (تَيَمُّم)** is the dry purification Allah allows when water cannot be found or cannot be used: make the intention, strike clean earth once with both palms, and wipe the face and then the hands. It stands in for wudu and for ghusl alike, and it ends the moment water becomes usable.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHEN IT IS ALLOWED")) {
                        ArticleParagraph(verbatim: "Tayammum is permitted in two cases: when there is no water at all (or none to spare after drinking needs), and when water is there but using it would harm you, as with an illness, a wound, or severe cold with no way to warm it. Allah says:")
                        ScriptureQuote(quran: "5:6")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) counted this ease among the special gifts to his ummah:")
                        ScriptureQuote(hadith: "bukhari:335", cite: "Saheeh al-Bukhaari 335", arabic: 43...83, english: [4...19, 40...75])
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHEN IT IS ALLOWED")) {
                        ArticleParagraph(verbatim: "Tayammum is permitted in two cases: when there is no water at all (or none to spare after drinking needs), and when water is there but using it would harm you, as with an illness, a wound, or severe cold with no way to warm it.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHAT TO USE")) {
                        ArticleParagraph(articleMarkdown: "Anything that is of the earth's surface and is clean: soil, sand, dust, or a stone or dusty wall. Allah calls it **sa‘eed tayyib (صَعِيد طَيِّب)**, clean earth. It need not leave visible dust on the hands; a light strike is enough.")
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Intention (Niyyah)**: intend in the heart to purify yourself for prayer. Say “Bismillah.”")
                        ArticleStep("2. **Strike the earth once** with both palms, lightly, then blow on them or shake off the excess dust.")
                        ArticleStep("3. **Wipe the face** with both hands, once.")
                        ArticleStep("4. **Wipe the hands**: the back of the right hand with the left palm and the back of the left hand with the right palm, up to the wrists.")
                        ArticleParagraph(verbatim: "That is the whole of it. When Ammaar ibn Yaasir (may Allah be pleased with him) rolled in the dust to purify himself from janaabah, the Prophet (peace and blessings be upon him) corrected him:")
                        ScriptureQuote(hadith: "bukhari:338", cite: "Saheeh al-Bukhaari 338", arabic: 68...87, english: 64...99)
                        ScriptureQuote(hadith: "muslim:368b", cite: "Saheeh Muslim 368", arabic: 36...52, english: 0...19)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Intention (Niyyah)**: intend in the heart to purify yourself for prayer. Say “Bismillah.”")
                        ArticleStep("2. **Strike clean earth once** (soil, sand, dust, or a stone or dusty wall) with both palms, lightly, then blow on them or shake off the excess dust.")
                        ArticleStep("3. **Wipe the face** with both hands, once.")
                        ArticleStep("4. **Wipe the hands**: the back of the right hand with the left palm and the back of the left hand with the right palm, up to the wrists.")
                        ArticleParagraph(verbatim: "That is the whole of it. When Ammaar ibn Yaasir (may Allah be pleased with him) rolled in the dust to purify himself from janaabah, the Prophet (peace and blessings be upon him) corrected him:")
                        ScriptureQuote(hadith: "bukhari:338", cite: "Saheeh al-Bukhaari 338", arabic: 68...87, english: 64...99)
                    }
                }

                Section(header: ArticleHeader("WHAT BREAKS IT")) {
                    ArticleParagraph(verbatim: "Everything that breaks wudu breaks tayammum. In addition, tayammum ends when the excuse ends: when water is found, or when using it is no longer harmful. A prayer already completed with tayammum is valid and is not repeated.")
                    ArticleParagraph(verbatim: "Tayammum done in place of ghusl is likewise a full substitute until water can be used; then a ghusl is made.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Can tayammum replace ghusl?** Yes. Ammaar's case above was janaabah, and the Prophet (peace and blessings be upon him) taught him tayammum for it. When water becomes available, make ghusl for what follows.")
                        ArticleParagraph(articleMarkdown: "**Does one tayammum cover several prayers?** It remains valid, like wudu, until it is broken or until water becomes usable. This is the stronger view among the scholars, since the Prophet named the earth a purification without limiting it to one prayer.")
                        ArticleParagraph(articleMarkdown: "**A wound is bandaged. Do I still make tayammum?** Wash what you can, wipe over the bandage, and complete the wudu. Tayammum is for the part that can take neither washing nor wiping, and some scholars regard the wipe over the bandage as sufficient on its own. Ask a scholar about a persistent condition.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("When water is missing or harmful, strike clean earth once, wipe the face and then the hands, and pray. It is Allah's ease for this ummah, and it lasts until water can be used again.")
                }

                ArticleSourcesSection(article: "TayammumView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "TayammumView")
        .navigationTitle("How to Make Tayammum")
    }
}

/// The 'awrah of men and women: in prayer, before others, and within the family (Abu, 2026-11-24: "Awrah of
/// men versus women", Sunni Salafi). The fatwas quoted are page-checked on Shamela and binbaz.org.sa; where
/// the scholars of the Sunnah differ (the face and hands, the feet in prayer, the shoulders) both views are
/// named with who holds them.
struct AwrahView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "AwrahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Awrah")
        .englishArticle().selectableArticleList(article: "AwrahView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a man’s ‘awrah is from the navel to the knee, in prayer and outside it, and in prayer he also covers his shoulders. A woman covers her whole body in prayer except her face, and before men who are not her mahram she covers her whole body; the scholars of the Sunnah differ only over the face and hands, which Ibn Baaz, Ibn al-Uthaymeen, and the Permanent Committee hold must be covered and al-Albaani holds are better covered. Before her mahrams and other women she shows only what usually shows at home, and between husband and wife there is no ‘awrah."),
        ]),
        ArticleSection("WHAT IS THE AWRAH?", [
            .markdown("**Awrah (عَورَة)** is what must be covered from others’ sight. Allah reminds the children of Aadam that clothing is His gift for exactly this, and that taqwa is the better garment:"),
            .ayah("7:26"),
            .longOnly(.text("And He commands that it be worn at its best for prayer:")),
            .longOnly(.ayah("7:31", words: 1...7)),
            .longOnly(.markdown("There are two different rulings that are easily confused. The **‘awrah in prayer** is what must be covered for the prayer to be valid, even if nobody sees. The **‘awrah of the gaze** is what may not be shown to others or looked at. They overlap but are not the same, as Ibn Taymiyyah (may Allah have mercy on him) said:")),
            .shortOnly(.markdown("There are two different rulings that are easily confused. The **‘awrah in prayer** is what must be covered for the prayer to be valid, even if nobody sees. The **‘awrah of the gaze** is what may not be shown to others or looked at. They overlap but are not the same.")),
            .longOnly(.quote(text: "“The ‘awrah in prayer is not tied to the ‘awrah of the gaze, in either direction” (Ibn Taymiyyah, Majmoo‘ al-Fataawa 22/115).", arabic: "فَلَيسَتِ العَورَةُ فِي الصَّلَاةِ مُرتَبِطَةً بِعَورَةِ النَّظَرِ، لَا طَردًا وَلَا عَكسًا", dimmed: true)),
            .longOnly(.text("So a man covers his shoulders in prayer though they are not ‘awrah before people, and a woman may uncover her face in prayer when no man who is not her mahram is present, though most of the scholars of the Sunnah hold that she covers it before such men. The sections below take each case in turn.")),
            .longOnly(.versus(ArticleVersus.Side("Men", caption: "**From the navel to the knee**, in prayer and outside it. In prayer, the **shoulders** too. Before his wife, nothing is ‘awrah."), ArticleVersus.Side("Women", caption: "**In prayer**: all but the face. **Before non-mahram men**: all, with the face and hands differed over. **Before mahrams and women**: all but what shows at home."), quranic: false)),
        ]),
        ArticleSection("THE MAN: FROM THE NAVEL TO THE KNEE", [
            .text("The Prophet (peace be upon him) passed by a Companion whose thigh was uncovered and told him:"),
            .hadith("tirmidhi:2798", cite: "Jaami‘ at-Tirmidhi 2798; graded saheeh by al-Albaani", arabic: 38...42, english: [24...31]),
            .longOnly(.hadith("abudawud:4014", cite: "Sunan Abi Daawood 4014; graded saheeh by al-Albaani", arabic: 42...46, english: [15...24])),
            .text("And he gave the boundary in a ruling about a servant: that her master must not look"),
            .hadith("abudawud:4114", cite: "Sunan Abi Daawood 4114; graded hasan by al-Albaani", arabic: 35...42, english: [28...42]),
            .longOnly(.markdown("Each chain on its own has some weakness, but al-Albaani (may Allah have mercy on him) held that together they rise to the grade of saheeh (Irwaa’ al-Ghaleel 1/297-302). Anas reports that at Khaybar the Prophet’s waist-wrap slipped from his thigh (Saheeh al-Bukhaari 371):")),
            .longOnly(.hadith("bukhari:371", cite: "Saheeh al-Bukhaari 371", arabic: 65...81, english: [60...74])),
            .longOnly(.text("Al-Bukhaari, setting the two side by side, gave the rule of caution:")),
            .longOnly(.quote(text: "“The hadith of Anas has the stronger chain, and the hadith of Jarhad is more cautious, so that one is clear of their disagreement” (al-Bukhaari, Saheeh, Book of Prayer, chapter on what is said about the thigh).", arabic: "وَحَدِيثُ أَنَسٍ أَسنَدُ، وَحَدِيثُ جَرهَدٍ أَحوَطُ حَتَّى يُخرَجَ مِنِ اختِلَافِهِم", dimmed: true)),
            .longOnly(.text("The Permanent Committee, under Ibn Baaz, gave the verdict:")),
            .longOnly(.quote(text: "“The correct view among the sayings of the scholars is that the ‘awrah of a man is what is between the navel and the knee … and these hadiths strengthen one another, so they rise to serve as proof” (al-Lajnah ad-Daa’imah, fatwa 5128, 6/166-167).", arabic: "وَالصَّحِيحُ مِن أَقوَالِ العُلَمَاءِ أَنَّ عَورَةَ الرَّجُلِ مَا بَينَ السُّرَّةِ وَالرُّكبَةِ … وَهَذِهِ الأَحَادِيثُ يَشُدُّ بَعضُهَا بَعضًا فَتَنهَضُ لِلِاحتِجَاجِ بِهَا", dimmed: true)),
            .shortOnly(.text("Al-Albaani held that these hadiths together rise to the grade of saheeh, and the Permanent Committee under Ibn Baaz gave the verdict: the ‘awrah of a man is what is between the navel and the knee.")),
            .longOnly(.markdown("**The navel and the knee themselves** are not ‘awrah according to Maalik, ash-Shaafi‘i, and the well-known position of the Hanbalis; the Hanafis count the knee in it. Ibn Baaz said the knee follows the shin, though covering it in prayer is better.")),
            .shortOnly(.markdown("**The navel and the knee themselves** are not ‘awrah in the view of Maalik, ash-Shaafi‘i, and the Hanbalis, though the Hanafis count the knee in it.")),
            .longOnly(.markdown("Ibn Baaz held this boundary in and out of prayer, and called the view that the thigh is not ‘awrah the weaker one. Ibn al-Uthaymeen held that the thighs must be covered in prayer, that outside it the upper thigh takes the ruling of the private parts, and that young men in particular should cover the whole thigh for fear of fitnah (ash-Sharh al-Mumti‘ 2/163). In practice the two meet: shorts that bare the thigh are not worn before others.")),
            .shortOnly(.text("So shorts that bare the thigh are not worn before others.")),
        ]),
        ArticleSection("THE MAN IN PRAYER", [
            .text("For prayer a man covers his ‘awrah and also his shoulders, because the Prophet (peace be upon him) said:"),
            .hadith("bukhari:359", cite: "Saheeh al-Bukhaari 359, Saheeh Muslim 516", arabic: 24...33, english: [4...19]),
            .longOnly(.markdown("The scholars differ over how binding this is. The Hanbali school, and Ibn Baaz, hold that covering the shoulders, or at least one of them, is **obligatory** in prayer for whoever is able. Most of the scholars, and Ibn al-Uthaymeen, hold that it is a **Sunnah**, because its purpose is to keep the garment secure (ash-Sharh al-Mumti‘ 2/168). Ibn Taymiyyah notes the shoulders are covered for the right of the prayer, not because they are ‘awrah. Either way, the believer does not pray with bare shoulders when he can cover them, and he prays in his best clothes, as the ayah of adornment commands.")),
            .shortOnly(.markdown("Covering the shoulders, or at least one of them, is **obligatory** in prayer for whoever is able in the view of the Hanbali school and Ibn Baaz, and a **Sunnah** in the view of most of the scholars and Ibn al-Uthaymeen. Either way, the believer does not pray with bare shoulders when he can cover them.")),
        ]),
        ArticleSection("THE WOMAN IN PRAYER", [
            .text("The Prophet (peace be upon him) said:"),
            .hadith("abudawud:641", cite: "Sunan Abi Daawood 641, Jaami‘ at-Tirmidhi 377; graded saheeh by al-Albaani", arabic: 32...38, english: [4...21]),
            .longOnly(.markdown("The **khimaar** is the head covering, so a woman’s hair, neck, and body are covered for prayer, even when she prays alone. Her **face** is uncovered in prayer by agreement when no man who is not her mahram is present:")),
            .shortOnly(.markdown("The **khimaar** is the head covering, so a woman’s hair, neck, and body are covered for prayer, even when she prays alone. Her **face** is uncovered in prayer, by agreement, when no man who is not her mahram is present.")),
            .longOnly(.quote(text: "“As for the face, they agree by consensus that there is no objection to uncovering it, and that the Sunnah is to uncover it in prayer when no non-mahram man is with her” (Ibn Baaz, fatwa 7028).", arabic: "وَأَمَّا الوَجهُ فَقَد أَجمَعُوا عَلَى أَنَّهُ لَا مَانِعَ مِن كَشفِهِ، وَأَنَّ السُّنَّةَ كَشفُهُ فِي الصَّلَاةِ إِذَا لَم يَكُن عِندَهَا أَجنَبِيٌّ", dimmed: true)),
            .longOnly(.markdown("Her **hands**: Ibn Baaz held that they need not be covered, though covering them is better, to be clear of the view that requires it. Her **feet**: Ibn Baaz held that covering them is obligatory, as most of the scholars hold; Abu Haneefah held they may show, and Ibn Taymiyyah judged that view stronger (Majmoo‘ al-Fataawa 22/114), with Ibn al-Uthaymeen following him. So the cautious course, and the safe one, is a garment long enough to cover the feet, or socks. The often-quoted report of Umm Salamah that a woman’s garment must cover the tops of her feet is weak, as al-Albaani showed (Irwaa’ al-Ghaleel 274), so the ruling rests on the general command and the scholars’ reasoning rather than on it.")),
            .shortOnly(.markdown("Her **hands** need not be covered, though covering them is better. Her **feet** must be covered in the view of Ibn Baaz and most of the scholars, while Abu Haneefah and Ibn Taymiyyah held they may show; the safe course is a garment long enough to cover them, or socks.")),
            .markdown("If a man who is not her mahram can see her while she prays, as in a mosque without a screen or a public place, she covers her face and hands as she would outside prayer."),
        ]),
        ArticleSection("THE WOMAN BEFORE MEN WHO ARE NOT HER MAHRAM", [
            .text("Allah commanded the believing women:"),
            .ayah("24:31", words: 7...17),
            .longOnly(.ayah("33:59")),
            .text("Everything of her body is covered before such men, by agreement of the scholars, apart from the face and the hands, over which Ahl as-Sunnah hold two views."),
            .longOnly(.markdown("**The first view: the face and hands must be covered.** This is the position of Ibn Baaz, Ibn al-Uthaymeen, and the Permanent Committee, and Ibn Taymiyyah reports it as the apparent position of Imam Ahmad. Ibn al-Uthaymeen opened his treatise on the hijab with it:")),
            .shortOnly(.markdown("**The first view: the face and hands must be covered.** This is the position of Ibn Baaz, Ibn al-Uthaymeen, and the Permanent Committee, and Ibn Taymiyyah reports it as the apparent position of Imam Ahmad. Among their proofs: when the ayah of the khimaar came down, the women of the Muhaajiroon did this:")),
            .longOnly(.quote(text: "“A woman’s screening herself from non-mahram men and covering her face is an obligation, proven by the Book of your Lord the Exalted, the Sunnah of your Prophet …, sound reasoning, and consistent analogy” (Ibn al-Uthaymeen, Risaalat al-Hijab, p. 9).", arabic: "احتِجَابُ المَرأَةِ عَنِ الرِّجَالِ الأَجَانِبِ وَتَغطِيَةُ وَجهِهَا أَمرٌ وَاجِبٌ، دَلَّ عَلَى وُجُوبِهِ كِتَابُ رَبِّكَ تَعَالَى، وَسُنَّةُ نَبِيِّكَ … وَالِاعتِبَارُ الصَّحِيحُ، وَالقِيَاسُ المُطَّرِدُ", dimmed: true)),
            .longOnly(.text("Among their proofs: when the ayah of the khimaar came down, the women of the Muhaajiroon did this:")),
            .hadith("bukhari:4759", cite: "Saheeh al-Bukhaari 4759", arabic: 32...39, english: [21...39]),
            .quote(text: "“‘So they covered themselves with them’ means: they covered their faces” (Ibn Hajar, Fath al-Baari 8/490).", arabic: "قَولُهُ: فَاختَمَرنَ، أَي غَطَّينَ وُجُوهَهُنَّ", dimmed: true),
            .longOnly(.text("Aa’ishah (may Allah be pleased with her) described what she did when a man came upon her after the ayah of the hijab had come down:")),
            .longOnly(.hadith("bukhari:4141", cite: "Saheeh al-Bukhaari 4141", arabic: 304...306, english: [451...458])),
            .longOnly(.text("And the Prophet (peace be upon him) forbade the face veil and gloves only to the woman in ihraam, which shows the women of his time wore them otherwise:")),
            .longOnly(.hadith("bukhari:1838", cite: "Saheeh al-Bukhaari 1838", arabic: 71...77, english: [71...87])),
            .longOnly(.text("They also cite the ayah that asks the believers to speak to the Prophet’s wives from behind a screen, “that is purer for your hearts and their hearts” (Quran 33:53), and the ayah that excuses elderly women past marriage from their outer garments (Quran 24:60), which means younger women are not excused.")),
            .longOnly(.ayah("33:53", words: 45...48)),
            .longOnly(.ayah("24:60")),
            .longOnly(.markdown("**The second view: the face and hands are not ‘awrah, but covering them is better.** This is the position of al-Albaani in Jilbaab al-Mar’ah al-Muslimah, who attributes it to most of the scholars, among them Abu Haneefah, Maalik, ash-Shaafi‘i, and a narration from Ahmad. His proofs include the woman of Khath‘am who asked the Prophet a question at the Farewell Hajj, whose beauty al-Fadl looked at until the Prophet turned his face away:")),
            .shortOnly(.markdown("**The second view: the face and hands are not ‘awrah, but covering them is better.** This is the position of al-Albaani in Jilbaab al-Mar’ah al-Muslimah, who attributes it to most of the scholars. Among his proofs is the woman of Khath‘am who asked the Prophet a question at the Farewell Hajj, whose beauty al-Fadl looked at until the Prophet turned his face away:")),
            .hadith("bukhari:6228", cite: "Saheeh al-Bukhaari 6228", arabic: 51...85, english: [48...103]),
            .longOnly(.markdown("and the woman at the Eid sermon whom Jaabir described as **“with dark-marked cheeks”** (Saheeh Muslim 885), which could only be said of a face that was seen; and Ibn Abbaas’s explanation of “except what appears thereof” as the face and the hands, which Ibn Katheer calls the well-known view of the majority. Ibn al-Uthaymeen answered that the woman of Khath‘am was apparently in ihraam, when the face is not veiled, and al-Albaani replied that she was not. Al-Albaani also held the hadith of Asmaa’ (Sunan Abi Daawood 4104) authentic by its routes, while Abu Daawood himself called it mursal, broken in its chain, and Ibn Baaz rejected it.")),
            .longOnly(.hadith("muslim:885b", cite: "Saheeh Muslim 885", arabic: 69...86, english: [95...126])),
            .longOnly(.quote(text: "“A woman’s covering her face with a burqu‘ or the like … is legislated and praiseworthy, even though it is not obligatory on her: whoever does it has done well, and whoever does not, there is no sin” (al-Albaani, Jilbaab al-Mar’ah al-Muslimah, p. 114).", arabic: "سَترُ المَرأَةِ لِوَجهِهَا بِبُرقُعٍ أَو نَحوِهِ … أَمرٌ مَشرُوعٌ مَحمُودٌ، وَإِن كَانَ لَا يَجِبُ ذَلِكَ عَلَيهَا، بَل مَن فَعَلَ فَقَد أَحسَنَ، وَمَن لَا فَلَا حَرَجَ", dimmed: true)),
            .longOnly(.callout("Both sides agree that the rest of the body must be covered; that covering the face is legislated and praiseworthy, and was the practice of the Mothers of the Believers; that a face bearing adornment beyond kohl and henna must be covered; and that the man must lower his gaze either way. They differ only over whether a plain face and hands must be covered. Al-Albaani added that she must cover her face if she fears harm from immoral men, but he rejected making “fear of fitnah” a general condition, since that rule governs the man’s looking.", title: "Where they agree", icon: "checkmark.seal.fill")),
            .shortOnly(.callout("Both sides agree that the rest of the body must be covered; that covering the face is legislated and praiseworthy, and was the practice of the Mothers of the Believers; that a face bearing adornment beyond kohl and henna must be covered; and that the man must lower his gaze either way. They differ only over whether a plain face and hands must be covered.", title: "Where they agree", icon: "checkmark.seal.fill")),
        ]),
        ArticleSection("THE WOMAN BEFORE HER MAHRAMS", [
            .longOnly(.markdown("A **mahram** is a man she may never marry: her father and grandfathers, her sons and grandsons, her brothers, her nephews, her uncles, her father-in-law, her stepsons, and the like. The same ayah names them:")),
            .shortOnly(.markdown("A **mahram** is a man she may never marry: her father and grandfathers, her sons and grandsons, her brothers, her nephews, her uncles, her father-in-law, her stepsons, and the like, as the ayah of the khimaar names them. Before them she shows only what usually shows of a woman at home and while she works: the head, the hands, the neck, and the feet, as the Permanent Committee explained.")),
            .longOnly(.ayah("24:31", words: 18...61)),
            .longOnly(.text("Before them she shows only what usually shows at home, as the Permanent Committee explained:")),
            .longOnly(.quote(text: "“What custom uncovers before those named in the noble ayah is what usually shows of a woman at home and while she works, and which is hard for her to guard: the head, the hands, the neck, and the feet” (al-Lajnah ad-Daa’imah, statement 21302, 17/290-294).", arabic: "وَمَا جَرَتِ العَادَةُ بِكَشفِهِ لِلمَذكُورِينَ فِي الآيَةِ الكَرِيمَةِ هُوَ مَا يَظهَرُ مِنَ المَرأَةِ غَالِبًا فِي البَيتِ، وَحَالَ المِهنَةِ، وَيَشُقُّ عَلَيهَا التَّحَرُّزُ مِنهُ؛ كَانكِشَافِ الرَّأسِ وَاليَدَينِ وَالعُنُقِ وَالقَدَمَينِ", dimmed: true)),
            .text("Ibn Baaz added that more modesty than this is better. And a man who is not on that list is not a mahram, however close the family: the husband’s brother and cousins above all, of whom the Prophet (peace be upon him) warned:"),
            .hadith("bukhari:5232", cite: "Saheeh al-Bukhaari 5232, Saheeh Muslim 2172", arabic: 27...44, english: [4...46]),
        ]),
        ArticleSection("BEFORE OTHER WOMEN, AND MEN BEFORE MEN", [
            .text("The Prophet (peace be upon him) forbade looking at the ‘awrah of one’s own sex:"),
            .hadith("muslim:338a", cite: "Saheeh Muslim 338", arabic: 38...48, english: [6...28]),
            .longOnly(.markdown("So a man before men covers from the navel to the knee. For a woman before women, the jurists give the same minimum, from the navel to the knee, and Ibn Baaz said so while adding that she should be modest. The Permanent Committee took the stricter line from the ayah itself, which lists “their women” among those before whom the same adornment may show as before mahrams:")),
            .shortOnly(.markdown("So a man before men covers from the navel to the knee. For a woman before women the jurists give the same minimum, and Ibn Baaz said so while adding that she should be modest; the Permanent Committee held that she shows another woman only what she shows her mahrams.")),
            .longOnly(.quote(text: "“The apparent meaning of the Quran shows that a woman shows another woman only what she shows her mahrams, of what custom uncovers at home and while she works” (al-Lajnah ad-Daa’imah, statement 21302, 17/291).", arabic: "وَقَد دَلَّ ظَاهِرُ القُرآنِ عَلَى أَنَّ المَرأَةَ لَا تُبدِي لِلمَرأَةِ إِلَّا مَا تُبدِيهِ لِمَحَارِمِهَا، مِمَّا جَرَتِ العَادَةُ بِكَشفِهِ فِي البَيتِ وَحَالَ المِهنَةِ", dimmed: true)),
            .longOnly(.markdown("**Non-Muslim women.** The Permanent Committee and Ibn Baaz held that “their women” in the ayah means all women, Muslim or not, so the same applies; Ibn Taymiyyah held that a non-Muslim woman should see only the outward adornment. Ibn al-Uthaymeen added that she covers more if the other woman would describe her to men.")),
        ]),
        ArticleSection("HUSBAND AND WIFE", [
            .text("Between spouses there is no ‘awrah. The Prophet (peace be upon him) was asked what must be covered and from whom:"),
            .hadith("tirmidhi:2769", cite: "Jaami‘ at-Tirmidhi 2769, Sunan Abi Daawood 4017; graded hasan by al-Albaani", arabic: 29...37, english: [34...46]),
            .longOnly(.ayah("23:5-6")),
            .text("The same hadith goes on: the man asked about being alone, and the Prophet answered, “Allah is most deserving of being shy from Him.” So modesty remains even in private."),
        ]),
        ArticleSection("CHILDREN", [
            .longOnly(.text("A young child’s ‘awrah carries little ruling; Ibn al-Uthaymeen said a child under seven has no ‘awrah in the legal sense (ash-Sharh al-Mumti‘ 5/268). Children are taught to cover as they grow, and before puberty they already ask permission at the three times of undress:")),
            .longOnly(.ayah("24:58", words: 0...29)),
            .longOnly(.text("A girl takes the full rulings of the woman at puberty, as the hadith of the khimaar says, and is trained in them before it, the way children are taught to pray from seven.")),
            .shortOnly(.text("A young child’s ‘awrah carries little ruling. Children are taught to cover as they grow, and a girl takes the full rulings of the woman at puberty, as the hadith of the khimaar says, trained in them before it, the way children are taught to pray from seven.")),
        ]),
        ArticleSection("THE CLOTHING ITSELF", [
            .text("Covering means the clothing actually conceals: it is not so thin that the skin shows through, nor so tight that it shows the body’s shape. The Prophet (peace be upon him) described a kind of women of the future:"),
            .hadith("muslim:2128", cite: "Saheeh Muslim 2128", arabic: 37...58, english: [32...93]),
            .longOnly(.text("And men and women each keep the dress of their own sex:")),
            .longOnly(.hadith("bukhari:5885", cite: "Saheeh al-Bukhaari 5885", arabic: 21...35, english: [0...28])),
            .longOnly(.text("And the eyes are guarded as the body is. Allah commands the believing men first:")),
            .longOnly(.ayah("24:30")),
            .longOnly(.hadith("muslim:2159a", cite: "Saheeh Muslim 2159", arabic: 51...57, english: [0...27])),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**May a man pray in a short-sleeved shirt?**"),
            .text("Yes. The arms are not ‘awrah, and a shirt with sleeves covers the shoulders. What he should not do is pray in a vest or a single sheet that leaves the shoulders bare when he has something to cover them, nor in trousers that leave the thigh or the area below the navel showing when he bows."),
            .longOnly(.markdown("**Must a woman cover her hair if she prays alone at home?**")),
            .longOnly(.text("Yes. The covering in prayer is for the prayer itself, not for onlookers, as the hadith of the khimaar says. She may uncover her face when no man who is not her mahram is present.")),
            .longOnly(.markdown("**Is my prayer valid if my feet showed?**")),
            .longOnly(.text("By the view of Abu Haneefah, Ibn Taymiyyah, and Ibn al-Uthaymeen it is valid. Ibn Baaz held covering the feet obligatory, but said a woman who prayed that way not knowing it is excused for the prayers already prayed. From now on, cover them, which is valid by every view.")),
            .longOnly(.markdown("**May my husband’s brother see me without hijab?**")),
            .longOnly(.text("No. He is not a mahram, and the Prophet called the in-law “death” because he is the one most likely to be alone with his brother’s wife. The same goes for cousins and brothers-in-law of every kind.")),
            .longOnly(.markdown("**Is covering the face extremism, or a bid‘ah?**")),
            .longOnly(.text("Neither. It is legislated and praiseworthy by agreement of both views above, it was the practice of the Mothers of the Believers and the women of the Companions, and the scholars who hold it obligatory are among the greatest scholars of the Sunnah in our time. Calling it extremism mocks a part of the religion.")),
            .longOnly(.markdown("**At what age does a girl have to cover?**")),
            .longOnly(.text("At puberty the obligation begins, as the hadith of the khimaar says, “a woman who has reached puberty.” Parents train her before then so that it is familiar by the time it is binding.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A man covers from the navel to the knee before everyone but his wife, and covers his shoulders for prayer. A woman covers all but her face in prayer, shows her mahrams and other women only what shows at home, and before other men covers her whole body, with the face and hands covered by the stronger view of the scholars of our time and covered as the better course by the other. Between husband and wife there is no ‘awrah, and modesty is kept even when alone."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Awrah (عَورَة)**: from **ع-و-ر**, a gap or weak point left exposed. The hypocrites said “our houses are ‘awrah,” exposed (Quran 33:13). In the Sharee‘ah it is the part of the body that must be covered."),
            .ayah("33:13", words: 15...17),
            .markdown("**Mahram (مَحرَم)**: from **ح-ر-م**, to make inviolable: a man whom a woman may never marry, by blood, marriage, or nursing, before whom she may show what usually shows at home and with whom she may travel."),
            .markdown("**Khimaar (خِمَار)**: from **خ-م-ر**, to cover (wine is khamr because it covers the mind): the head covering, drawn over the neck and chest (Quran 24:31)."),
            .markdown("**Jilbaab (جِلبَاب)**: the outer wrap worn over the clothes when going out (Quran 33:59)."),
            .markdown("**Niqab (نِقَاب)**: the face veil with an opening for the eyes, named in the hadith of the woman in ihraam (Saheeh al-Bukhaari 1838)."),
            .markdown("**Hijab (حِجَاب)**: from **ح-ج-ب**, to screen: in the Quran a screen between the Prophet’s wives and the men speaking to them (Quran 33:53), and in common use the whole of a woman’s covering."),
        ]),
    ]
}

// MARK: - Other prayers

struct RawatibView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: the **Sunnah Rawaatib (السُّنَن الرَّوَاتِب)** are the twelve voluntary rak‘ah the Prophet (peace and blessings be upon him) kept around the five prayers every day: four before Dhuhr and two after, two after Maghrib, two after Isha, and two before Fajr. Whoever keeps them is promised a house in Paradise.")
                }

                Section(header: ArticleHeader("THE PROMISE")) {
                    ScriptureQuote(hadith: "muslim:728a", cite: "Saheeh Muslim 728", arabic: 58...71, english: 0...18)
                    ArticleParagraph(verbatim: "Aa’ishah (may Allah be pleased with her) narrated the breakdown:")
                    ScriptureQuote(hadith: "tirmidhi:414", cite: "Jaami‘ at-Tirmidhi 414", arabic: 28...56, english: 0...38)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE TWELVE")) {
                        ArticleBullet("• **Before Fajr**: 2 rak‘ah, kept short.")
                        ArticleBullet("• **Before Dhuhr**: 4 rak‘ah (two by two), and **after Dhuhr**: 2 rak‘ah.")
                        ArticleBullet("• **After Maghrib**: 2 rak‘ah.")
                        ArticleBullet("• **After Isha**: 2 rak‘ah.")
                        ArticleParagraph(verbatim: "Ibn Umar (may Allah be pleased with him) recalled ten of them from the Prophet himself, and named where he prayed them:")
                        ScriptureQuote(hadith: "bukhari:1180", cite: "Saheeh al-Bukhaari 1180", arabic: 22...49, english: 0...42)
                        ScriptureQuote(hadith: "bukhari:1182", cite: "Saheeh al-Bukhaari 1182", arabic: 22...36, english: 0...17)
                    }

                    Section(header: ArticleHeader("THE TWO BEFORE FAJR")) {
                        ArticleParagraph(verbatim: "Of all the rawaatib, the two before Fajr were the ones the Prophet (peace and blessings be upon him) never left, at home or on a journey. He said:")
                        ScriptureQuote(hadith: "muslim:725a", cite: "Saheeh Muslim 725", arabic: 29...35, english: 0...13)
                        ArticleParagraph(verbatim: "He prayed them light, with Surah al-Kaafiroon and Surah al-Ikhlaas after al-Faatihah being his frequent choice (Saheeh Muslim 726):")
                        ScriptureQuote(hadith: "muslim:726", cite: "Saheeh Muslim 726", arabic: 32...46, english: 0...10)
                        ScriptureQuote(hadith: "bukhari:1165", cite: "Saheeh al-Bukhaari 1165", arabic: 62...80, english: 0...24)
                    }

                    Section(header: ArticleHeader("MORE THAT IS RECOMMENDED")) {
                        ArticleParagraph(verbatim: "Beyond the twelve, other voluntary prayers around the obligatory ones are established and rewarded:")
                        ScriptureQuote(hadith: "tirmidhi:428", cite: "Jaami‘ at-Tirmidhi 428; graded saheeh by al-Albaani", arabic: 55...67, english: 6...22)
                        ScriptureQuote(hadith: "tirmidhi:430", cite: "Jaami‘ at-Tirmidhi 430; graded hasan by al-Albaani", arabic: 38...44, english: 4...15)
                        ScriptureQuote(hadith: "muslim:881a", cite: "Saheeh Muslim 881", arabic: 26...32, english: 0...19)
                        ScriptureQuote(hadith: "bukhari:627", cite: "Saheeh al-Bukhaari 627", arabic: 29...44, english: [3...21, 32...38])
                    }

                    Section(header: ArticleHeader("HOW TO PRAY THEM")) {
                        ArticleStep(verbatim: "1. Pray them two rak‘ah at a time, each pair ending with the tashahhud and the tasleem. Four before Dhuhr are two pairs.")
                        ArticleStep(verbatim: "2. Intend the specific sunnah in the heart; nothing is spoken.")
                        ArticleStep(verbatim: "3. Pray them at home when you can, as the Prophet (peace and blessings be upon him) did for the Maghrib and Isha rawaatib: he said that the best of a man's prayer is in his house, except the obligatory prayer (Saheeh Muslim 781).")
                        ScriptureQuote(hadith: "muslim:781a", cite: "Saheeh Muslim 781", arabic: 113...125, english: 112...136)
                        ArticleStep(verbatim: "4. If you miss one, it may be made up: the Prophet made up the two after Dhuhr when he was kept busy (Saheeh al-Bukhaari 1233), and when he slept through Fajr on a journey he prayed its two sunnah rak‘ah and then the obligatory prayer (Saheeh Muslim 681); a man who had missed them before Fajr he allowed to pray them right after it (Jaami‘ at-Tirmidhi 422; Sunan Abi Daawood 1267; graded saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "bukhari:1233", cite: "Saheeh al-Bukhaari 1233", arabic: 177...199, english: 261...316)
                        ScriptureQuote(hadith: "muslim:681", cite: "Saheeh Muslim 681", arabic: 233...322, english: [300...321, 416...442])
                        ScriptureQuote(hadith: "tirmidhi:422", cite: "Jaami‘ at-Tirmidhi 422, Sunan Abi Daawood 1267; graded saheeh by al-Albaani", arabic: 24...68, english: 0...61)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE TWELVE")) {
                        ArticleBullet("• **Before Fajr**: 2 rak‘ah, kept short.")
                        ArticleBullet("• **Before Dhuhr**: 4 rak‘ah (two by two), and **after Dhuhr**: 2 rak‘ah.")
                        ArticleBullet("• **After Maghrib**: 2 rak‘ah.")
                        ArticleBullet("• **After Isha**: 2 rak‘ah.")
                    }

                    Section(header: ArticleHeader("THE TWO BEFORE FAJR")) {
                        ArticleParagraph(verbatim: "Of all the rawaatib, the two before Fajr were the ones the Prophet (peace and blessings be upon him) never left, at home or on a journey, and he prayed them light. He said:")
                        ScriptureQuote(hadith: "muslim:725a", cite: "Saheeh Muslim 725", arabic: 29...35, english: 0...13)
                    }

                    Section(header: ArticleHeader("HOW TO PRAY THEM")) {
                        ArticleStep(verbatim: "1. Pray them two rak‘ah at a time, each pair ending with the tashahhud and the tasleem. Four before Dhuhr are two pairs.")
                        ArticleStep(verbatim: "2. Intend the specific sunnah in the heart; nothing is spoken.")
                        ArticleStep(verbatim: "3. Pray them at home when you can, as the Prophet (peace and blessings be upon him) did for the Maghrib and Isha rawaatib: he said that the best of a man's prayer is in his house, except the obligatory prayer (Saheeh Muslim 781).")
                        ScriptureQuote(hadith: "muslim:781a", cite: "Saheeh Muslim 781", arabic: 113...125, english: 112...136)
                        ArticleStep(verbatim: "4. If you miss one, it may be made up: the Prophet made up the two after Dhuhr when he was kept busy (Saheeh al-Bukhaari 1233).")
                        ScriptureQuote(hadith: "bukhari:1233", cite: "Saheeh al-Bukhaari 1233", arabic: 177...199, english: 261...316)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Twelve rak‘ah a day, spread around the five prayers, earn a house in Paradise and mend what the obligatory prayer lacked. Guard the two of Fajr above all.")
                }

                ArticleSourcesSection(article: "RawatibView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "RawatibView")
        .navigationTitle("How to Pray the Sunnah Prayers")
    }
}

struct WitrView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Witr (وِتر)**, the odd-numbered prayer, closes the night's prayer. It is prayed after Isha and before Fajr, as one, three, five or more rak‘ah ending in one, and the Prophet (peace and blessings be upon him) never left it, at home or on a journey.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ITS STATUS")) {
                        ArticleParagraph(verbatim: "Witr is a strongly emphasized Sunnah, not one of the five obligations. Ali (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "nasai:1676", cite: "Sunan an-Nasaa’i 1676; graded saheeh by al-Albaani", arabic: 24...37, english: 0...17)
                        ArticleParagraph(verbatim: "Yet the Prophet (peace and blessings be upon him) urged it in the strongest terms and advised it to those he loved:")
                        ScriptureQuote(hadith: "abudawud:1422", cite: "Sunan Abi Daawood 1422; graded saheeh by al-Albaani", arabic: 35...57, english: 4...50)
                        ScriptureQuote(hadith: "bukhari:1178", cite: "Saheeh al-Bukhaari 1178", arabic: 25...42, english: 0...37)
                    }

                    Section(header: ArticleHeader("ITS TIME")) {
                        ArticleParagraph(verbatim: "From after the Isha prayer until the break of dawn. The best time is the last part of the night for whoever trusts himself to wake; whoever fears he will not should pray it before sleeping.")
                        ScriptureQuote(hadith: "bukhari:998", cite: "Saheeh al-Bukhaari 998", arabic: 24...28, english: 4...11)
                        ScriptureQuote(hadith: "bukhari:990", cite: "Saheeh al-Bukhaari 990", arabic: 38...53, english: 16...61)
                    }

                    Section(header: ArticleHeader("HOW MANY RAK‘AH")) {
                        ArticleBullet("• **One** rak‘ah on its own is valid Witr:")
                        ScriptureQuote(hadith: "muslim:752a", cite: "Saheeh Muslim 752", arabic: 27...31, english: 0...9)
                        ArticleBullet("• **Three**, either as two rak‘ah with tasleem then one, or three in one sitting with one tashahhud at the end (not like Maghrib, with a middle sitting).")
                        ArticleBullet("• **Five, seven or nine**, prayed in one sitting with a tashahhud only at the end (in nine, a tashahhud in the eighth and the ninth), as the Prophet (peace and blessings be upon him) prayed at times.")
                        ArticleBullet("• **Eleven or thirteen**: two by two, then one, which was his usual night prayer:")
                        ScriptureQuote(hadith: "muslim:736a", cite: "Saheeh Muslim 736", arabic: 15...43, english: 3...34)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ITS STATUS")) {
                        ArticleParagraph(verbatim: "Witr is a strongly emphasized Sunnah, not one of the five obligations. Ali (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "nasai:1676", cite: "Sunan an-Nasaa’i 1676; graded saheeh by al-Albaani", arabic: 24...37, english: 0...17)
                    }

                    Section(header: ArticleHeader("ITS TIME")) {
                        ArticleParagraph(verbatim: "From after the Isha prayer until the break of dawn. The best time is the last part of the night for whoever trusts himself to wake; whoever fears he will not should pray it before sleeping.")
                        ScriptureQuote(hadith: "bukhari:998", cite: "Saheeh al-Bukhaari 998", arabic: 24...28, english: 4...11)
                    }

                    Section(header: ArticleHeader("HOW MANY RAK‘AH")) {
                        ArticleBullet("• **One** rak‘ah on its own is valid Witr:")
                        ScriptureQuote(hadith: "muslim:752a", cite: "Saheeh Muslim 752", arabic: 27...31, english: 0...9)
                        ArticleBullet("• **Three**, either as two rak‘ah with tasleem then one, or three in one sitting with one tashahhud at the end (not like Maghrib, with a middle sitting).")
                        ArticleBullet("• **Five, seven or nine**, prayed in one sitting with a tashahhud only at the end (in nine, a tashahhud in the eighth and the ninth), as the Prophet (peace and blessings be upon him) prayed at times.")
                        ArticleBullet("• **Eleven or thirteen**: two by two, then one, which was his usual night prayer.")
                    }
                }

                Section(header: ArticleHeader("WHAT TO RECITE")) {
                    ArticleParagraph(verbatim: "In three rak‘ah of Witr, the Prophet (peace and blessings be upon him) recited al-A‘la in the first, al-Kaafiroon in the second and al-Ikhlaas in the third:")
                    ScriptureQuote(hadith: "abudawud:1423", cite: "Sunan Abi Daawood 1423", arabic: 41...64, english: 0...39)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE QUNOOT")) {
                        ArticleParagraph(articleMarkdown: "A supplication (**qunoot, قُنُوت**) in the last rak‘ah, before or after the ruku, is Sunnah. The Prophet (peace and blessings be upon him) taught al-Hasan ibn Ali these words:")
                        ScriptureQuote(hadith: "abudawud:1425", cite: "Sunan Abi Daawood 1425; graded saheeh by al-Albaani", arabic: 50...84, english: 32...103)
                        ArticleParagraph(verbatim: "After the tasleem he would say this three times, raising his voice on the third (Sunan an-Nasaa’i 1734, 1750; graded saheeh by al-Albaani):")
                        ScriptureQuote(hadith: "nasai:1734", cite: "Sunan an-Nasaa’i 1734; graded saheeh by al-Albaani", arabic: 51...65, english: 31...56)
                        ScriptureQuote(hadith: "abudawud:1430", cite: "Sunan Abi Daawood 1430; graded saheeh by al-Albaani", arabic: 47...49, english: 14...20)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I slept through Witr. Can I make it up?** Yes. The Prophet (peace and blessings be upon him) said that whoever sleeps through his Witr or forgets it should pray it when he wakes or remembers (Sunan Abi Daawood 1431; Jaami‘ at-Tirmidhi 465; graded saheeh by al-Albaani); it may be prayed in the day after Fajr, and some scholars say as an even number then.")
                        ScriptureQuote(hadith: "abudawud:1431", cite: "Sunan Abi Daawood 1431, Jaami‘ at-Tirmidhi 465; graded saheeh by al-Albaani", arabic: 36...44, english: 4...19)
                        ArticleParagraph(articleMarkdown: "**Can I pray Witr, then pray more at night?** Whoever prays Witr early and then wakes may pray as he wishes, two by two, without repeating Witr: “There are no two Witr in one night” (Jaami‘ at-Tirmidhi 470; Sunan Abi Daawood 1439; graded saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "tirmidhi:470", cite: "Jaami‘ at-Tirmidhi 470, Sunan Abi Daawood 1439; graded saheeh by al-Albaani", arabic: 29...32, english: 8...15)
                        ArticleParagraph(articleMarkdown: "**Is Witr the same as Tahajjud?** Witr is the closing rak‘ah; Tahajjud is the whole of the night prayer it closes. Praying only Witr is valid; praying Tahajjud without Witr leaves it incomplete.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE QUNOOT")) {
                        ArticleParagraph(articleMarkdown: "A supplication (**qunoot, قُنُوت**) in the last rak‘ah, before or after the ruku, is Sunnah. The Prophet (peace and blessings be upon him) taught al-Hasan ibn Ali these words:")
                        ScriptureQuote(hadith: "abudawud:1425", cite: "Sunan Abi Daawood 1425; graded saheeh by al-Albaani", arabic: 50...84, english: 32...103)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Close every night with Witr, an odd number ending in one, with a qunoot in the last rak‘ah. If you will not wake, pray it before you sleep; if you will, make it the last thing you pray before dawn.")
                }

                ArticleSourcesSection(article: "WitrView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "WitrView")
        .navigationTitle("How to Pray Witr")
    }
}

struct TahajjudView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Tahajjud (تَهَجُّد)**, or Qiyaam al-Layl, is the voluntary prayer offered after sleeping some of the night, prayed two rak‘ah at a time and closed with Witr. It is the best prayer after the obligatory ones, and the hour in which Allah asks who is calling on Him.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE COMMAND AND THE PRAISE")) {
                        ScriptureQuote(quran: "17:79")
                        ScriptureQuote(quran: "73:1-4")
                        ScriptureQuote(quran: "51:17-18")
                        ScriptureQuote(quran: "32:16")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:1163a", cite: "Saheeh Muslim 1163", arabic: 34...46, english: 0...23)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE COMMAND AND THE PRAISE")) {
                        ScriptureQuote(quran: "17:79")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:1163a", cite: "Saheeh Muslim 1163", arabic: 34...46, english: 0...23)
                    }
                }

                Section(header: ArticleHeader("THE HOUR OF ANSWER")) {
                    ScriptureQuote(hadith: "bukhari:1145", cite: "Saheeh al-Bukhaari 1145", arabic: 35...60, english: 5...68)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ITS TIME")) {
                        ArticleParagraph(verbatim: "Any time after Isha and before Fajr is night prayer; the last third is best. To sleep first and then rise is what the word tahajjud means, and it is what the Prophet (peace and blessings be upon him) did, and what he praised in Daawood (peace be upon him):")
                        ScriptureQuote(hadith: "bukhari:1131", cite: "Saheeh al-Bukhaari 1131", arabic: 42...69, english: 5...50)
                    }

                    Section(header: ArticleHeader("HOW MANY RAK‘AH")) {
                        ArticleParagraph(verbatim: "There is no fixed number; two rak‘ah are night prayer. The Prophet's own habit was eleven, and at times thirteen:")
                        ScriptureQuote(hadith: "bukhari:1147", cite: "Saheeh al-Bukhaari 1147", arabic: 42...77, english: 3...61)
                        ArticleParagraph(verbatim: "Long rak‘ah with few in number was his way, and he said of the night prayer that it is offered two by two, ending in one (Saheeh al-Bukhaari 990).")
                        ScriptureQuote(hadith: "bukhari:990", cite: "Saheeh al-Bukhaari 990", arabic: 38...53, english: 16...61)
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Sleep with the intention** of rising. The intention itself is written for you even if sleep overcomes you (Sunan an-Nasaa’i 1787; Sunan Ibn Maajah 1344; graded saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "nasai:1787", cite: "Sunan an-Nasaa’i 1787, Sunan Ibn Maajah 1344; graded saheeh by al-Albaani", arabic: 41...66, english: 0...42)
                        ArticleStep("2. **On waking**, say the remembrance of waking, make wudu, and begin. Satan ties three knots on the sleeper; remembering Allah undoes one, wudu the second, and prayer the third (Saheeh al-Bukhaari 1142).")
                        ScriptureQuote(hadith: "bukhari:1142", cite: "Saheeh al-Bukhaari 1142", arabic: 31...71, english: 4...90)
                        ArticleStep("3. **Open with two short rak‘ah**, as the Prophet (peace and blessings be upon him) did (Saheeh Muslim 767), then lengthen what follows.")
                        ScriptureQuote(hadith: "muslim:767", cite: "Saheeh Muslim 767", arabic: 31...46, english: 0...22)
                        ArticleStep("4. **Pray two by two**, reciting slowly, with long standing, bowing and prostration. Weeping and reflecting over the aayaat is of its spirit.")
                        ArticleStep("5. **Make dua in prostration and before the end**, for it is the hour of answer.")
                        ArticleStep("6. **Close with Witr**: one rak‘ah, or three, with the qunoot.")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) would open his night prayer with this supplication:")
                        ScriptureQuote(hadith: "bukhari:1120", cite: "Saheeh al-Bukhaari 1120", arabic: 38...120, english: 99...309)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I cannot wake in the last third. Is my prayer still Tahajjud?** Pray what you can after Isha and before sleeping, with Witr. The Prophet advised those who fear they will not wake to pray Witr early. Regularity in a little beats an unkept ambition.")
                        ArticleParagraph(articleMarkdown: "**Can I pray Tahajjud sitting?** Yes, and in his later years the Prophet (peace and blessings be upon him) prayed much of the night sitting. Standing is better where you are able.")
                        ArticleParagraph(articleMarkdown: "**Should I recite aloud?** He recited sometimes aloud and sometimes softly. Recite so as to hear yourself, and lower it if it disturbs others who sleep or pray.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ITS TIME")) {
                        ArticleParagraph(verbatim: "Any time after Isha and before Fajr is night prayer; the last third is best. To sleep first and then rise is what the word tahajjud means, and it is what the Prophet (peace and blessings be upon him) did.")
                    }

                    Section(header: ArticleHeader("HOW MANY RAK‘AH")) {
                        ArticleParagraph(verbatim: "There is no fixed number; two rak‘ah are night prayer. The Prophet's own habit was eleven, and at times thirteen, long rak‘ah with few in number, and he said of the night prayer that it is offered two by two, ending in one (Saheeh al-Bukhaari 990).")
                        ScriptureQuote(hadith: "bukhari:990", cite: "Saheeh al-Bukhaari 990", arabic: 38...53, english: 16...61)
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Sleep with the intention** of rising.")
                        ArticleStep("2. **On waking**, say the remembrance of waking, make wudu, and begin.")
                        ArticleStep("3. **Open with two short rak‘ah**, as the Prophet (peace and blessings be upon him) did (Saheeh Muslim 767), then lengthen what follows.")
                        ScriptureQuote(hadith: "muslim:767", cite: "Saheeh Muslim 767", arabic: 31...46, english: 0...22)
                        ArticleStep("4. **Pray two by two**, reciting slowly, with long standing, bowing and prostration. Weeping and reflecting over the aayaat is of its spirit.")
                        ArticleStep("5. **Make dua in prostration and before the end**, for it is the hour of answer.")
                        ArticleStep("6. **Close with Witr**: one rak‘ah, or three, with the qunoot.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I cannot wake in the last third. Is my prayer still Tahajjud?** Pray what you can after Isha and before sleeping, with Witr. The Prophet advised those who fear they will not wake to pray Witr early. Regularity in a little beats an unkept ambition.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Rise for part of the night, pray two by two with slow recitation and long dua, and close with Witr. It is the honor of the believer and the hour Allah Himself invites you to ask.")
                }

                ArticleSourcesSection(article: "TahajjudView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "TahajjudView")
        .navigationTitle("How to Pray Tahajjud")
    }
}

struct DuhaView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Salaat ad-Duha (صَلَاة الضُّحَى)**, the forenoon prayer, is two or more rak‘ah prayed after the sun has risen a spear's length until shortly before Dhuhr. Two rak‘ah discharge the charity owed by every joint of the body each morning.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ITS VIRTUE")) {
                        ScriptureQuote(hadith: "muslim:720", cite: "Saheeh Muslim 720", arabic: 45...77, english: 0...88)
                        ArticleParagraph(verbatim: "It was among the three things the Prophet (peace and blessings be upon him) advised Abu Hurayrah never to leave (Saheeh al-Bukhaari 1178), and he called it the prayer of those who turn back to Allah:")
                        ScriptureQuote(hadith: "bukhari:1178", cite: "Saheeh al-Bukhaari 1178", arabic: 25...42, english: 0...37)
                        ScriptureQuote(hadith: "muslim:748b", cite: "Saheeh Muslim 748", arabic: 38...42, english: 0...17)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ITS VIRTUE")) {
                        ScriptureQuote(hadith: "muslim:720", cite: "Saheeh Muslim 720", arabic: 45...77, english: 0...88)
                        ArticleParagraph(verbatim: "He called it the prayer of those who turn back to Allah:")
                        ScriptureQuote(hadith: "muslim:748b", cite: "Saheeh Muslim 748", arabic: 38...42, english: 0...17)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ITS TIME")) {
                        ArticleParagraph(verbatim: "It begins about fifteen to twenty minutes after sunrise, when the sun has risen the height of a spear, and ends a little before the sun reaches its zenith. Its best time is when the morning has grown hot, as the hadith of the young camels describes.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ITS TIME")) {
                        ArticleParagraph(verbatim: "It begins about fifteen to twenty minutes after sunrise, when the sun has risen the height of a spear, and ends a little before the sun reaches its zenith. Its best time is when the morning has grown hot.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HOW MANY RAK‘AH")) {
                        ArticleParagraph(verbatim: "The least is two. The Prophet (peace and blessings be upon him) prayed four and added as Allah willed, and prayed eight on the day Makkah was opened:")
                        ScriptureQuote(hadith: "muslim:719c", cite: "Saheeh Muslim 719", arabic: 20...33, english: 0...21)
                        ScriptureQuote(hadith: "bukhari:1176", cite: "Saheeh al-Bukhaari 1176", arabic: 33...58, english: 19...48)
                    }
                }

                Section(header: ArticleHeader("HOW TO PRAY IT")) {
                    ArticleStep(verbatim: "1. Intend Salaat ad-Duha in the heart, at any point in its time.")
                    ArticleStep(verbatim: "2. Pray two rak‘ah at a time, each pair ending with the tasleem, as any voluntary prayer.")
                    ArticleStep(verbatim: "3. Recite what you wish after al-Faatihah; there is no fixed surah.")
                    ArticleStep(verbatim: "4. Two rak‘ah are complete; four, six or eight are more.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Did the Prophet pray it every day?** Aa’ishah said he did not pray it regularly except on returning from a journey, while she herself prayed it (Saheeh Muslim 717), and others among the Companions saw him pray it. The scholars reconcile this: he left it at times so it would not be taken as obligatory, and he advised his Companions to keep it. Keeping it daily is good, and leaving it some days is no sin.")
                        ScriptureQuote(hadith: "muslim:717a", cite: "Saheeh Muslim 717", arabic: 17...34, english: 0...25)
                        ArticleParagraph(articleMarkdown: "**Is it the same as Salaat al-Ishraaq?** Ishraaq is the name given to Duha prayed at its earliest, right after the sun has risen a spear's length. It is one prayer.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Two rak‘ah in the forenoon pay the day's debt of gratitude for every joint in the body. Pray them when the morning is warm, and add to them as you are able.")
                }

                ArticleSourcesSection(article: "DuhaView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "DuhaView")
        .navigationTitle("How to Pray Duha")
    }
}

struct TaraweehView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Taraaweeh (تَرَاوِيح)** is the night prayer of Ramadan, prayed after Isha two rak‘ah at a time and closed with Witr, alone or in congregation. Whoever stands in it out of faith and hope of reward is forgiven his past sins.")
                }

                Section(header: ArticleHeader("ITS VIRTUE")) {
                    ScriptureQuote(hadith: "bukhari:37", cite: "Saheeh al-Bukhaari 37", arabic: 26...36, english: 4...33)
                    ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) urged it without making it obligatory (Saheeh Muslim 759).")
                    ScriptureQuote(hadith: "muslim:759b", cite: "Saheeh Muslim 759", arabic: 18...48, english: 0...51)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HOW IT BEGAN")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) prayed it in the mosque for three nights and the people gathered behind him; then he stayed in his house, fearing it would be made obligatory upon them:")
                        ScriptureQuote(hadith: "bukhari:1129", cite: "Saheeh al-Bukhaari 1129", arabic: 65...79, english: 54...80)
                        ArticleParagraph(verbatim: "After his death, Umar (may Allah be pleased with him) gathered the people behind one reciter, Ubayy ibn Ka‘b, and said of it “what an excellent innovation this is” (Saheeh al-Bukhaari 2010), meaning the gathering behind one imam, a Sunnah the Prophet had begun and left only for fear of its becoming obligatory.")
                        ScriptureQuote(hadith: "bukhari:2010", cite: "Saheeh al-Bukhaari 2010", arabic: 42...81, english: 45...135)
                    }

                    Section(header: ArticleHeader("HOW MANY RAK‘AH")) {
                        ArticleParagraph(verbatim: "The Prophet's own night prayer, in Ramadan and outside it, was eleven rak‘ah:")
                        ScriptureQuote(hadith: "bukhari:1147", cite: "Saheeh al-Bukhaari 1147", arabic: 42...77, english: 18...30)
                        ArticleParagraph(verbatim: "The Companions in Umar's time prayed eleven, and later twenty and more with shorter recitation. There is no fixed limit; night prayer is two by two (Saheeh al-Bukhaari 990). Eleven or thirteen with long, unhurried recitation follows the Prophet most closely; more with shorter recitation is also good. The majority of the scholars, including Ibn Baaz and Ibn al-Uthaymeen, hold that there is no fixed limit, while some, such as al-Albaani, held to eleven; it is a matter of legitimate difference, not of creed.")
                        ScriptureQuote(hadith: "bukhari:990", cite: "Saheeh al-Bukhaari 990", arabic: 38...53, english: 16...61)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HOW MANY RAK‘AH")) {
                        ArticleParagraph(verbatim: "The Prophet's own night prayer, in Ramadan and outside it, was eleven rak‘ah:")
                        ScriptureQuote(hadith: "bukhari:1147", cite: "Saheeh al-Bukhaari 1147", arabic: 42...77, english: 18...30)
                        ArticleParagraph(verbatim: "Eleven or thirteen with long, unhurried recitation follows the Prophet most closely; more with shorter recitation is also good. The majority of the scholars, including Ibn Baaz and Ibn al-Uthaymeen, hold that there is no fixed limit, while some, such as al-Albaani, held to eleven.")
                    }
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    ArticleStep(verbatim: "1. Pray Isha and its two sunnah rak‘ah.")
                    ArticleStep("2. Pray Taraaweeh two rak‘ah at a time, with a tasleem after every two. Rest briefly after every four if you wish; this rest (**tarweehah**) is what gives the prayer its name.")
                    ArticleStep(verbatim: "3. In congregation, follow the imam; alone, recite what you know well, slowly.")
                    ArticleStep(verbatim: "4. Close with Witr, one or three rak‘ah with the qunoot. If you intend to pray more later in the night, delay Witr to the end.")
                    ArticleStep(verbatim: "5. Attend to the end: whoever prays with the imam until he finishes is written as having prayed the whole night (Jaami‘ at-Tirmidhi 806; Sunan Abi Daawood 1375; graded saheeh by al-Albaani).")
                    ScriptureQuote(hadith: "tirmidhi:806", cite: "Jaami‘ at-Tirmidhi 806, Sunan Abi Daawood 1375; graded saheeh by al-Albaani", arabic: 61...84, english: 64...107)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Home or mosque?** Both are Sunnah. The congregation in the mosque is the way of the Companions after Umar, and the imam's recitation carries you through the Quran; at home you may pray at a slower pace. Women may attend the mosque or pray at home.")
                        ArticleParagraph(articleMarkdown: "**Can I pray Taraaweeh late at night instead of after Isha?** Yes. It is the night prayer; the last third is the best time. In the last ten nights the Prophet stayed up the whole night.")
                        ArticleParagraph(articleMarkdown: "**Must the whole Quran be completed?** No. It is a good custom of the imams, not a condition. Praying a small portion with reflection is better than racing through a khatm.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Stand in prayer in the nights of Ramadan, two by two after Isha, closing with Witr, out of faith and hope of reward, and Allah forgives what has passed.")
                }

                ArticleSourcesSection(article: "TaraweehView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "TaraweehView")
        .navigationTitle("How to Pray Taraaweeh")
    }
}

struct JanazahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Salaat al-Janaazah (صَلَاة الجَنَازَة)** is the funeral prayer, prayed standing with four takbeers and no bowing or prostration: al-Faatihah after the first, the prayers upon the Prophet after the second, supplication for the deceased after the third, and the tasleem after the fourth. It is a collective obligation on the Muslims, and whoever attends until the burial is rewarded with two great mountains.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ITS REWARD")) {
                        ScriptureQuote(hadith: "muslim:945a", cite: "Saheeh Muslim 945", english: 0...54, arabicText: "مَن شَهِدَ الجَنَازَةَ حَتَّى يُصَلَّى عَلَيهَا فَلَهُ قِيرَاطٌ وَمَن شَهِدَهَا حَتَّى تُدفَنَ فَلَهُ قِيرَاطَانِ. قِيلَ: وَمَا القِيرَاطَانِ؟ قَالَ: مِثلُ الجَبَلَينِ العَظِيمَينِ")
                        ScriptureQuote(hadith: "muslim:948", cite: "Saheeh Muslim 948", arabic: 86...103, english: 50...78)
                    }

                    Section(header: ArticleHeader("BEFORE THE PRAYER")) {
                        ArticleParagraph(verbatim: "The deceased is washed and shrouded first. The Prophet (peace and blessings be upon him) said of his daughter:")
                        ScriptureQuote(hadith: "bukhari:1253", cite: "Saheeh al-Bukhaari 1253", arabic: 38...61, english: 12...44)
                        ScriptureQuote(hadith: "bukhari:1264", cite: "Saheeh al-Bukhaari 1264", arabic: 20...40, english: 0...25)
                        ArticleParagraph(verbatim: "Men are shrouded in three cloths; women in three or, according to many scholars, five (the hadith of the five is weak, so al-Albaani held that women are shrouded like men), and the funeral is not delayed:")
                        ScriptureQuote(hadith: "muslim:944a", cite: "Saheeh Muslim 944", arabic: 38...57, english: 0...37)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("BEFORE THE PRAYER")) {
                        ArticleParagraph(verbatim: "The deceased is washed and shrouded first, and the funeral is not delayed.")
                    }
                }

                Section(header: ArticleHeader("WHERE TO STAND")) {
                    ArticleParagraph(verbatim: "The body is laid in front of the congregation, its right side toward the qiblah. The imam stands at the head of a man and at the middle of a woman, with the rows behind him.")
                    ScriptureQuote(hadith: "bukhari:1332", cite: "Saheeh al-Bukhaari 1332", arabic: 22...36, english: 0...26)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleParagraph(verbatim: "There is no bowing, prostration or sitting. It is four takbeers, all standing:")
                        ArticleStep("1. **First takbeer**: say “Allahu Akbar,” raising the hands, then recite Surah al-Faatihah quietly.")
                        ArticleStep("2. **Second takbeer**: send prayers upon the Prophet (peace and blessings be upon him) with the salaat al-Ibraaheemiyyah of the tashahhud.")
                        ArticleStep("3. **Third takbeer**: supplicate for the deceased, sincerely, using the Prophet's own words.")
                        ArticleStep("4. **Fourth takbeer**: pause briefly, then give the tasleem to the right (and to the left if you wish).")
                        ArticleParagraph(verbatim: "Ibn Abbaas (may Allah be pleased with him) recited al-Faatihah aloud in a funeral prayer and said:")
                        ScriptureQuote(hadith: "bukhari:1335", cite: "Saheeh al-Bukhaari 1335", arabic: 40...57, english: 0...30)
                        ArticleParagraph(verbatim: "And the Prophet (peace and blessings be upon him) prayed four takbeers over an-Najaashi (Saheeh al-Bukhaari 1245).")
                        ScriptureQuote(hadith: "bukhari:1245", cite: "Saheeh al-Bukhaari 1245", arabic: 27...40, english: 0...40)
                    }

                    Section(header: ArticleHeader("THE SUPPLICATION")) {
                        ArticleParagraph(verbatim: "Awf ibn Maalik (may Allah be pleased with him) heard the Prophet pray over a deceased man:")
                        ScriptureQuote(hadith: "muslim:963a", cite: "Saheeh Muslim 963", arabic: 43...89, english: 22...109)
                        ArticleParagraph(verbatim: "And for the whole gathering, living and dead:")
                        ScriptureQuote(hadith: "abudawud:3201", cite: "Sunan Abi Daawood 3201; graded saheeh by al-Albaani", arabic: 38...67, english: 13...83)
                        ArticleParagraph(verbatim: "For a woman, change the pronouns to the feminine; for a child, ask that Allah make the child a forerunner and a stored reward for the parents.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleParagraph(verbatim: "There is no bowing, prostration or sitting. It is four takbeers, all standing:")
                        ArticleStep("1. **First takbeer**: say “Allahu Akbar,” raising the hands, then recite Surah al-Faatihah quietly.")
                        ArticleStep("2. **Second takbeer**: send prayers upon the Prophet (peace and blessings be upon him) with the salaat al-Ibraaheemiyyah of the tashahhud.")
                        ArticleStep("3. **Third takbeer**: supplicate for the deceased, sincerely, using the Prophet's own words.")
                        ArticleStep("4. **Fourth takbeer**: pause briefly, then give the tasleem to the right (and to the left if you wish).")
                    }

                    Section(header: ArticleHeader("THE SUPPLICATION")) {
                        ArticleParagraph(verbatim: "Awf ibn Maalik (may Allah be pleased with him) heard the Prophet pray over a deceased man:")
                        ScriptureQuote(hadith: "muslim:963a", cite: "Saheeh Muslim 963", arabic: 43...89, english: 22...109)
                        ArticleParagraph(verbatim: "For a woman, change the pronouns to the feminine; for a child, ask that Allah make the child a forerunner and a stored reward for the parents.")
                    }
                }

                Section(header: ArticleHeader("AFTER THE PRAYER")) {
                    ArticleParagraph(verbatim: "Follow the funeral to the grave in silence and reflection. The deceased is lowered on the right side facing the qiblah with “Bismillah wa ‘ala sunnati Rasoolillah,” the grave is filled, and those present stand and ask forgiveness and steadfastness for him, for he is now being questioned.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Can the prayer be offered for someone absent?** Yes, when the deceased was not prayed over where he died; the Prophet prayed over an-Najaashi in Madinah. The scholars differ on doing so for one already prayed over.")
                        ArticleParagraph(articleMarkdown: "**I arrived late.** Join with a takbeer and follow the imam; after his tasleem, complete the takbeers you missed in order before the body is carried away.")
                        ArticleParagraph(articleMarkdown: "**Can women pray it?** Yes, in the mosque or at home; Aa’ishah and the wives of the Prophet prayed the funeral prayer for Sa‘d ibn Abi Waqqaas in the mosque. Following the procession to the grave is for the men.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I arrived late.** Join with a takbeer and follow the imam; after his tasleem, complete the takbeers you missed in order before the body is carried away.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Four takbeers standing: al-Faatihah, the prayers upon the Prophet, sincere dua for the deceased, and the tasleem. Then follow to the grave, and ask steadfastness for a brother or sister who is now being asked.")
                }

                ArticleSourcesSection(article: "JanazahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "JanazahView")
        .navigationTitle("How to Pray the Funeral Prayer")
    }
}

/// Istikharah: the prayer and its dua on ONE page (Abu, 2026-10-25: "there's dua and prayer of
/// istikhara in how to guides, merge them into one"; the dua had been its own row, IstikharahDuaView,
/// since 2026-10-21). The dua is drawn as the Dua screen draws its rows (`GuideDuaRow`), the
/// narrator's "or he said" set in parentheses so the page reads as a script
/// (`WordRange.parenthesizingAsides`), and each of its phrases is explained under it.
struct IstikharahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Istikhaarah (اِستِخَارَة)** is asking Allah to choose for you. When a permissible matter is before you and you are unsure, pray two voluntary rak‘ah, then say the Prophet's supplication naming the matter, and go ahead with what your affairs open onto. It is not a dream to wait for; it is a decision entrusted to Allah.")
                }

                Section(header: ArticleHeader("THE HADITH")) {
                    ArticleParagraph(verbatim: "Jaabir ibn Abdullah (may Allah be pleased with him) said the Prophet (peace and blessings be upon him) taught them Istikhaarah for every matter as he taught them a surah of the Quran:")
                    ScriptureQuote(hadith: "bukhari:1166", cite: "Saheeh al-Bukhaari 1166", arabic: 43...53, english: [46...71, 300...312])
                }

                Section(header: ArticleHeader("THE DUA OF ISTIKHAARAH")) {
                    ArticleParagraph(verbatim: "Said after the tasleem of the two rak‘ah, in Arabic if you can. Where it says هَذَا الأَمْرَ, “this matter”, name what you are deciding. The words in parentheses are the narrator's, not yours to say: “or he said” introduces the Prophet's other wording of one phrase. Say either wording in its place, or both one after the other.")
                    // The dua as the Dua screen would carry it: the narration's own words from "Allahumma"
                    // to "ardini bih"; the narrator's asides, which the shelf sets between dashes, are
                    // drawn in parentheses (`WordRange.parenthesizingAsides`).
                    GuideDuaRow(DuaItem(
                        hadith: "bukhari:1166", cite: "Saheeh al-Bukhaari 1166", arabic: 54...135, english: 154...299,
                        transliteration: "Allahumma inni astakheeruka bi-‘ilmika, wa astaqdiruka bi-qudratika, wa as’aluka min fadlika al-‘azeem, fa-innaka taqdiru wa la aqdiru, wa ta‘lamu wa la a‘lamu, wa anta ‘allaamu al-ghuyoob. Allahumma in kunta ta‘lamu anna haadha al-amra khayrun li fi deeni wa ma‘aashi wa ‘aaqibati amri (aw qaala: ‘aajili amri wa aajilihi), faqdurhu li wa yassirhu li thumma baarik li feeh. Wa in kunta ta‘lamu anna haadha al-amra sharrun li fi deeni wa ma‘aashi wa ‘aaqibati amri (aw qaala: fi ‘aajili amri wa aajilihi), fasrifhu ‘anni wasrifni ‘anhu, waqdur li al-khayra haythu kaana thumma ardini bih.",
                        note: "After the two rak‘ah, naming the matter at hand"
                    ))
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHAT EACH PHRASE ASKS")) {
                        ArticleTermCard("I seek Your choice by Your knowledge", arabic: "أَسْتَخِيرُكَ بِعِلْمِكَ", meaning: "Istikhaarah is from **khayr**, good: you ask Allah to choose the good for you, because He knows how the matter ends and you do not.")
                        ArticleTermCard("I seek Your power by Your power", arabic: "وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ", meaning: "You ask Him to make you able and to bring the matter about, because the power to do either is His alone.")
                        ArticleTermCard("I ask You of Your great bounty", arabic: "وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ", meaning: "Whatever He then gives is a gift from His favour, not something you earned or were owed.")
                        ArticleTermCard("You are able and I am not, You know and I do not", arabic: "فَإِنَّكَ تَقْدِرُ وَلاَ أَقْدِرُ وَتَعْلَمُ وَلاَ أَعْلَمُ", meaning: "The reason for the asking, said plainly: all ability and all knowledge are His, and He is the Knower of the unseen (**‘allaam al-ghuyoob**).")
                        ArticleTermCard("If You know this matter is good for me", arabic: "إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الأَمْرَ خَيْرٌ لِي", meaning: "Here you name the matter. Good is measured in three things, in this order: **my religion**, **my livelihood** (ma‘aashi) and **the end of my affair** (‘aaqibati amri), the outcome in this world and the next.")
                        ArticleTermCard("Or he said: the near and the far of my affair", arabic: "(أَوْ قَالَ: عَاجِلِ أَمْرِي وَآجِلِهِ)", meaning: "The narrator's note, in parentheses on the page: the Prophet's other wording for the third thing, **‘aajili amri wa aajilihi**, this life and the next. Say either wording where it falls, or both one after the other. The words “or he said” are the narrator's and are not recited.")
                        ArticleTermCard("Decree it for me, ease it for me, then bless me in it", arabic: "فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ", meaning: "Three requests in order: that it comes to be, that it comes easily, and that once it has come it carries blessing. A thing can be given and still be without barakah, so the third is asked for on its own.")
                        ArticleTermCard("Turn it away from me and turn me away from it", arabic: "فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ", meaning: "If the matter is bad for you, both directions are asked for: that it leaves you, and that your heart leaves it, so you are not left longing for what was kept away.")
                        ArticleTermCard("Decree the good for me wherever it is, then make me content with it", arabic: "وَاقْدُرْ لِي الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ", meaning: "The closing: good from whatever direction Allah knows it to be, and a heart at peace with His choice. Contentment (**rida**) is the fruit of Istikhaarah.")
                    }
                }

                Section(header: ArticleHeader("WHEN TO PRAY IT")) {
                    ArticleParagraph(verbatim: "For any permissible matter whose outcome you cannot see: a marriage, a job, a journey, a purchase, a move. It is not prayed over obligations or prohibitions, for those are already decided, nor over trivial daily choices.")
                    ArticleParagraph(articleMarkdown: "Consult trustworthy people first or alongside it: the Companions took counsel (**istishaarah**) and sought Allah's choice (**istikhaarah**) together.")
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    ArticleStep("1. **Make wudu** and pray two rak‘ah of voluntary prayer with the intention of Istikhaarah, at any time prayer is permitted. Recite what you wish after al-Faatihah.")
                    ArticleStep("2. **After the tasleem**, praise Allah and send prayers upon the Prophet (peace and blessings be upon him), then raise your hands and say the dua above: in Arabic if you can, otherwise with its meaning in your own language.")
                    ArticleStep("3. **Name the matter** where the dua says “this matter”, in whatever words describe it: “if You know that marrying so-and-so...”, “this position at...”, the journey, the purchase.")
                    ArticleStep("4. **Then act.** Pursue the matter. If Allah eases it, that is His choice; if He turns it away, that is His choice too. Do not sit waiting for a sign.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Must I see a dream?** No. Nothing in the hadith mentions a dream or a feeling. The answer is in how the matter unfolds after you set out on it.")
                        ArticleParagraph(articleMarkdown: "**Can I repeat it?** Yes, if the matter is still unclear, the scholars allow repeating it (the report that names seven times is weak). But do not make repetition a way of avoiding a decision.")
                        ArticleParagraph(articleMarkdown: "**Can I pray it after a sunnah prayer instead of separate rak‘ah?** The hadith says two rak‘ah other than the obligatory ones; the scholars allow making the intention of Istikhaarah in a rawaatib or Duha prayer. Two rak‘ah prayed for it is the clearest way.")
                        ArticleParagraph(articleMarkdown: "**Inside the prayer or after it?** The hadith says to pray two rak‘ah and then say it, so after the tasleem is its apparent meaning and the clearest way. The scholars also allowed saying it before the tasleem, after the final tashahhud.")
                        ArticleParagraph(articleMarkdown: "**Must I say it in Arabic?** Say the Prophet's words if you can; they are the Sunnah. Someone who cannot may say their meaning in their own language, and Allah hears every tongue.")
                        ArticleParagraph(articleMarkdown: "**Can I say the dua without the two rak‘ah?** The Sunnah ties the dua to the prayer. Someone who cannot pray at the time, such as a woman during her period, may say the dua on its own in the view of some scholars.")
                        ArticleParagraph(articleMarkdown: "**Can someone pray it on my behalf?** The hadith addresses the one concerned with the matter. Ask others for their counsel and their dua, and pray Istikhaarah yourself.")
                        ArticleParagraph(articleMarkdown: "**Should I memorise the dua?** It helps, and the Companions learned it as they learned the Quran. Until then read it from the page: the row above can be heard aloud and copied.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Two rak‘ah, the Prophet's supplication with your matter named, then action. Ask by His knowledge, ask by His power, and ask for the good wherever it is and a heart content with it. Whatever Allah then opens or closes is the answer.")
                }

                ArticleSourcesSection(article: "IstikharahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "IstikharahView")
        .navigationTitle("How to Pray Istikhaarah")
    }
}

// MARK: - Jumuah: the khutbah

/// The khatib's half of Jumuah (Abu, 2026-10-27: "how to give khutbah and jummuah and adhan for
/// jummuah"): what makes the khutbah valid, how the Prophet gave it, its opening, and what to avoid.
/// The congregation's half is JumuahView, which links here; the two Friday calls are in AdhanOtherView.
struct KhutbahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: the Jumuah **khutbah (خُطبَة)** is two addresses given standing on the minbar after the Adhan, with a short sitting between them, before the prayer. Open with the praise of Allah and the testimony, send blessings on the Prophet, counsel the people to fear Allah with the Quran and the authentic Sunnah, keep it short, then come down and lead two rak‘ah aloud.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ITS PLACE")) {
                        ArticleParagraph(verbatim: "The khutbah is part of Jumuah itself, a condition of it rather than an extra. The Prophet (peace and blessings be upon him) never prayed Jumuah without it, and the scholars explained “the remembrance of Allah” the believers are told to hasten to as the khutbah and the prayer. It was two khutbahs, with Quran and counsel in them:")
                        ScriptureQuote(hadith: "muslim:862a", cite: "Saheeh Muslim 862", arabic: 27...39, english: 0...18)
                        ArticleParagraph(verbatim: "He gave it standing, and the Quran mentions it, of the people who left in the middle of it for a caravan's trade:")
                        ScriptureQuote(quran: "62:11")
                    }

                    Section(header: ArticleHeader("WHAT MAKES IT VALID")) {
                        ArticleStep("1. **In the prayer's time, and before the prayer.** A khutbah given before the time of Jumuah, or after the prayer, does not count. Unlike Eid, Jumuah's khutbah comes first.")
                        ArticleStep("2. **Two khutbahs.** This is the Sunnah the Prophet kept without exception, and the Shaafi‘i and Hanbali schools make both a condition; the Hanafis held that one suffices. Give two and you are safe in every view.")
                        ArticleStep("3. **Aloud, to the congregation that will pray.** It is given so that the people hear it, by someone who is with them. A recording or a broadcast does not count.")
                        ArticleStep("4. **What it says.** The Hanbali school names four pillars for each khutbah: praising Allah, sending blessings on the Prophet, reciting at least one ayah, and counselling the people to fear Allah. Others, Ibn Taymiyyah among them, held that no fixed list binds it, only what truly makes it a khutbah: the praise of Allah, the testimony, and real counsel. Keep all of them and your khutbah is valid in every view.")
                        ArticleStep("5. **Joined to the prayer.** The two khutbahs follow each other, and the prayer follows them, without a long break.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ITS PLACE")) {
                        ArticleParagraph(verbatim: "The khutbah is part of Jumuah itself, a condition of it rather than an extra. The Prophet (peace and blessings be upon him) never prayed Jumuah without it, and the scholars explained “the remembrance of Allah” the believers are told to hasten to as the khutbah and the prayer. It was two khutbahs, with Quran and counsel in them:")
                        ScriptureQuote(hadith: "muslim:862a", cite: "Saheeh Muslim 862", arabic: 27...39, english: 0...18)
                    }

                    Section(header: ArticleHeader("WHAT MAKES IT VALID")) {
                        ArticleStep("1. **In the prayer's time, and before the prayer.** A khutbah given before the time of Jumuah, or after the prayer, does not count.")
                        ArticleStep("2. **Two khutbahs.** The Prophet kept them without exception; give two and you are safe in every view.")
                        ArticleStep("3. **Aloud, to the congregation that will pray.** It is given so that the people hear it, by someone who is with them. A recording or a broadcast does not count.")
                        ArticleStep("4. **What it says.** Praise Allah, send blessings on the Prophet, recite at least one ayah, and counsel the people to fear Allah. Keep all of them and your khutbah is valid in every view.")
                        ArticleStep("5. **Joined to the prayer.** The two khutbahs follow each other, and the prayer follows them, without a long break.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Prepare.** Take a ghusl, wear clean clothes, and be in wudu, since you will lead the prayer. Choose one subject the people need, and gather its aayaat and authentic hadith beforehand.")
                        ArticleStep("2. **Come out when it is time, climb the minbar and face the people.** Greet them with salaam; Jaabir reported that the Prophet did so when he climbed the minbar (Sunan Ibn Maajah 1109; graded hasan by al-Albaani, though Shu‘ayb al-Arnaa’oot and Zubayr Ali Za'i judged its chain weak).")
                        ArticleStep("3. **Sit while the muadhin calls the Adhan**, the Adhan of the Prophet's time (Saheeh al-Bukhaari 912).")
                        ScriptureQuote(hadith: "bukhari:912", cite: "Saheeh al-Bukhaari 912", arabic: 14...37, english: 0...26)
                        ArticleStep("4. **Stand and begin with the praise of Allah.** You may lean on a staff or a bow:")
                        ScriptureQuote(hadith: "abudawud:1096", cite: "Sunan Abi Daawood 1096; graded hasan by al-Albaani", arabic: 84...97, english: 103...123)
                        ArticleParagraph(verbatim: "The opening the Prophet taught, Khutbat al-Haajah, is below. After it, say “Amma ba‘d” and come to your subject.")
                        ArticleStep("5. **Speak as a warner, with feeling.** This is how Jaabir described him on the minbar:")
                        ScriptureQuote(hadith: "muslim:867a", cite: "Saheeh Muslim 867", arabic: 22...45, english: 0...49)
                        ArticleStep("6. **Recite Quran in it.** A woman of the Ansaar learned a whole surah from his khutbahs:")
                        ScriptureQuote(hadith: "muslim:873a", cite: "Saheeh Muslim 873", arabic: 25...41, english: 27...62)
                        ArticleStep("7. **Sit briefly, in silence**, then stand for the second khutbah:")
                        ScriptureQuote(hadith: "muslim:862b", cite: "Saheeh Muslim 862", arabic: 14...37, english: 0...48)
                        ArticleStep("8. **In the second khutbah**, praise Allah again, send blessings on the Prophet, add a brief reminder, and supplicate for the Muslims. Point with your forefinger as you supplicate; do not raise both hands:")
                        ScriptureQuote(hadith: "muslim:873c", cite: "Saheeh Muslim 874", arabic: 18...49, english: 0...23)
                        ArticleStep("9. **Come down.** The Iqaamah is given at once, and you lead two rak‘ah aloud: al-A‘la and al-Ghaashiyah, or al-Jumuah and al-Munaafiqoon.")
                    }

                    Section(header: ArticleHeader("THE OPENING: KHUTBAT AL-HAAJAH")) {
                        ArticleParagraph(verbatim: "The Prophet opened his addresses with this praise. When Dimaad, who treated the possessed with incantations, came offering to “cure” him, these words alone brought him to Islam:")
                        ScriptureQuote(hadith: "muslim:868", cite: "Saheeh Muslim 868", arabic: 98...129, english: 101...169)
                        ArticleParagraph(verbatim: "Its fuller form, which Ibn Mas‘ood reported (Sunan Abi Daawood 2118; graded saheeh by al-Albaani), adds that we seek His forgiveness and take refuge in Him from the evil within ourselves, and then recites three aayaat:")
                        ScriptureQuote(hadith: "abudawud:2118", cite: "Sunan Abi Daawood 2118; graded saheeh by al-Albaani", arabic: 58...89, english: 14...78)
                        ScriptureQuote(quran: "3:102")
                        ScriptureQuote(quran: "4:1")
                        ScriptureQuote(quran: "33:70-71")
                        ArticleParagraph(verbatim: "Then he would say “Amma ba‘d” and go on:")
                        ScriptureQuote(hadith: "muslim:867a", cite: "Saheeh Muslim 867", arabic: 62...78, english: 78...114)
                    }

                    Section(header: ArticleHeader("SHORT KHUTBAH, LONG PRAYER")) {
                        ArticleParagraph(verbatim: "Ammaar ibn Yaasir gave a short, eloquent khutbah. Asked why he had not gone on longer, he said:")
                        ScriptureQuote(hadith: "muslim:869", cite: "Saheeh Muslim 869", arabic: 51...67, english: 53...88)
                        ScriptureQuote(hadith: "muslim:866a", cite: "Saheeh Muslim 866", arabic: 20...33, english: 0...19)
                        ArticleParagraph(verbatim: "Short is measured against the prayer. A khutbah that runs past what the people can hold, followed by a prayer rushed to make up the time, turns the Sunnah around.")
                    }

                    Section(header: ArticleHeader("WHAT TO SAY")) {
                        ArticleBullet("• **One subject, built on revelation.** Tawheed and the danger of shirk, the prayer, the rights of parents, spouses and neighbours, honesty in trade, the Hereafter, and the rulings of a season that is near: Ramadan, Hajj, the sacred months.")
                        ArticleBullet("• **Only what is authentic.** Quote the Quran and the authentic Sunnah, and say where a hadith comes from. A weak or invented narration said from the minbar travels further than any correction.")
                        ArticleBullet("• **What the people in front of you need.** His khutbahs taught, warned and gave glad tidings; leave them with something to act on this week.")
                        ArticleBullet("• **A language they understand.** See the first question below.")
                    }

                    Section(header: ArticleHeader("WHAT TO AVOID")) {
                        ArticleBullet("• **Length**, until the people tire and the prayer is hurried.")
                        ArticleBullet("• **Raising both hands in the khutbah's dua**, and the congregation raising theirs with you. The Sunnah is the forefinger. The one exception is asking for rain, when he raised both hands on the minbar (Saheeh al-Bukhaari 1029).")
                        ScriptureQuote(hadith: "bukhari:1029", cite: "Saheeh al-Bukhaari 1029", arabic: 23...61, english: 0...50)
                        ArticleBullet("• **Stories with no source**, dreams, and narrations you have not checked.")
                        ArticleBullet("• **A fixed second khutbah** recited from memory every week, with no counsel in it.")
                        ArticleBullet("• **Turning the minbar into a platform** for insults, rumours, or matters you have no knowledge of. It is a place of reminder.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**May the khutbah be in English, or the people's own language?** The Prophet and the Companions gave it in Arabic, and some scholars require Arabic. Ibn Baaz and Ibn al-Uthaymeen allowed it in the people's language where they do not understand Arabic, since its purpose is to teach and remind. Say the opening praise, the testimony and the aayaat in Arabic, then explain in their language; giving it in Arabic and then translating it avoids the difference altogether.")
                        ArticleParagraph(articleMarkdown: "**May someone else lead the prayer?** The Sunnah is that the khateeb leads it. Another may lead when there is a need, such as the khateeb's wudu breaking.")
                        ArticleParagraph(articleMarkdown: "**May I read from paper or a screen?** Yes. What matters is that it is heard and understood, not that it is memorised.")
                        ArticleParagraph(articleMarkdown: "**May I speak to someone during it?** Yes. The Prophet stopped to tell a man who sat down without praying to stand and pray two rak‘ah (Saheeh Muslim 875), and the one addressed may answer. It is the congregation who may not talk among themselves.")
                        ScriptureQuote(hadith: "muslim:875a", cite: "Saheeh Muslim 875", arabic: 26...57, english: 0...19)
                        ArticleParagraph(articleMarkdown: "**Must the khateeb be in wudu?** It is not a condition of the khutbah in the stronger view, but he leads the prayer straight after it, so he needs it anyway.")
                        ArticleParagraph(articleMarkdown: "**Must it end with “Inna Allaha ya’muru bil-‘adl” (16:90)?** No. It is an ayah, so reciting it is good, but making it the fixed ending is a later custom, not something the Prophet did.")
                        ScriptureQuote(quran: "16:90")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Prepare.** Take a ghusl, wear clean clothes, and be in wudu, since you will lead the prayer. Choose one subject the people need, and gather its aayaat and authentic hadith beforehand.")
                        ArticleStep("2. **Come out when it is time, climb the minbar and face the people**, and greet them with salaam.")
                        ArticleStep("3. **Sit while the muadhin calls the Adhan.**")
                        ArticleStep("4. **Stand and begin with the praise of Allah**, in the opening the Prophet taught, Khutbat al-Haajah, below. After it, say “Amma ba‘d” and come to your subject.")
                        ArticleStep("5. **Speak as a warner, with feeling, and recite Quran in it.**")
                        ArticleStep("6. **Sit briefly, in silence**, then stand for the second khutbah.")
                        ArticleStep("7. **In the second khutbah**, praise Allah again, send blessings on the Prophet, add a brief reminder, and supplicate for the Muslims. Point with your forefinger as you supplicate; do not raise both hands:")
                        ScriptureQuote(hadith: "muslim:873c", cite: "Saheeh Muslim 874", arabic: 18...49, english: 0...23)
                        ArticleStep("8. **Come down.** The Iqaamah is given at once, and you lead two rak‘ah aloud: al-A‘la and al-Ghaashiyah, or al-Jumuah and al-Munaafiqoon.")
                    }

                    Section(header: ArticleHeader("THE OPENING: KHUTBAT AL-HAAJAH")) {
                        ArticleParagraph(verbatim: "The Prophet opened his addresses with this praise:")
                        ScriptureQuote(hadith: "muslim:868", cite: "Saheeh Muslim 868", arabic: 98...129, english: 101...169)
                        ArticleParagraph(verbatim: "Then he would say “Amma ba‘d” and go on to his subject.")
                    }

                    Section(header: ArticleHeader("SHORT KHUTBAH, LONG PRAYER")) {
                        ArticleParagraph(verbatim: "Ammaar ibn Yaasir gave a short, eloquent khutbah. Asked why he had not gone on longer, he said:")
                        ScriptureQuote(hadith: "muslim:869", cite: "Saheeh Muslim 869", arabic: 51...67, english: 53...88)
                        ArticleParagraph(verbatim: "Short is measured against the prayer. A khutbah that runs past what the people can hold, followed by a prayer rushed to make up the time, turns the Sunnah around.")
                    }

                    Section(header: ArticleHeader("WHAT TO AVOID")) {
                        ArticleBullet("• **Length**, until the people tire and the prayer is hurried.")
                        ArticleBullet("• **Raising both hands in the khutbah's dua**, and the congregation raising theirs with you. The Sunnah is the forefinger.")
                        ArticleBullet("• **Stories with no source**, dreams, and narrations you have not checked.")
                        ArticleBullet("• **A fixed second khutbah** recited from memory every week, with no counsel in it.")
                        ArticleBullet("• **Turning the minbar into a platform** for insults, rumours, or matters you have no knowledge of. It is a place of reminder.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**May the khutbah be in English, or the people's own language?** The Prophet and the Companions gave it in Arabic, and some scholars require Arabic. Ibn Baaz and Ibn al-Uthaymeen allowed it in the people's language where they do not understand Arabic, since its purpose is to teach and remind. Say the opening praise, the testimony and the aayaat in Arabic, then explain in their language; giving it in Arabic and then translating it avoids the difference altogether.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Climb the minbar, greet the people and sit for the Adhan. Stand, praise Allah, bear witness, send blessings on the Prophet, and counsel with the Quran and the authentic Sunnah. Sit briefly, give a shorter second khutbah with dua for the Muslims, then come down and lead two rak‘ah. Short words, a long prayer.")
                }

                ArticleSourcesSection(article: "KhutbahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "KhutbahView")
        .navigationTitle("How to Give the Khutbah")
    }
}

// MARK: - Prayer in special cases

struct TravelPrayerView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: a traveler shortens the four-rak‘ah prayers to two (**qasr, قَصر**) and may combine Dhuhr with Asr and Maghrib with Isha (**jam', جَمع**) when moving. Fajr and Maghrib are never shortened. Shortening is Allah's charity to His servants, and the Prophet (peace and blessings be upon him) never prayed four on a journey.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE PERMISSION")) {
                        ScriptureQuote(quran: "4:101")
                        ArticleParagraph(verbatim: "Umar (may Allah be pleased with him) was asked why the shortening remained when the fear had passed. He said he had wondered the same and asked the Prophet, who replied:")
                        ScriptureQuote(hadith: "muslim:686a", cite: "Saheeh Muslim 686", arabic: 79...85, english: 63...78)
                        ScriptureQuote(hadith: "bukhari:1102", cite: "Saheeh al-Bukhaari 1102", arabic: 19...41, english: 0...25)
                    }

                    Section(header: ArticleHeader("WHO IS A TRAVELER")) {
                        ArticleParagraph(verbatim: "Whoever leaves his town on a journey that is called travel in ordinary speech. Most scholars set a distance of about 80 km (some 48 miles), by the hadith of the Companions; others say any journey with provisions and a night away. Shortening begins once you have left the buildings of your town and ends when you return to them.")
                        ArticleParagraph(verbatim: "On arrival, if you intend to stay four days or fewer you remain a traveler. If you intend longer, most scholars say you pray in full, while others allow shortening as long as you have not settled, since the Prophet shortened through a stay of nineteen days (Saheeh al-Bukhaari 1080).")
                        ScriptureQuote(hadith: "bukhari:1080", cite: "Saheeh al-Bukhaari 1080", arabic: 22...39, english: 0...44)
                        ArticleParagraph(verbatim: "Anas said of the Farewell Hajj:")
                        ScriptureQuote(hadith: "bukhari:1081", cite: "Saheeh al-Bukhaari 1081", arabic: 17...43, english: 4...44)
                    }

                    Section(header: ArticleHeader("SHORTENING (QASR)")) {
                        ArticleBullet("• **Dhuhr, Asr and Isha**: two rak‘ah each.")
                        ArticleBullet("• **Fajr**: two, as always. **Maghrib**: three, as always.")
                        ArticleBullet(verbatim: "• The rawaatib are dropped on a journey except the two before Fajr and Witr, which the Prophet (peace and blessings be upon him) never left. Other voluntary prayers remain permitted.")
                        ArticleBullet(verbatim: "• Praying behind a resident imam, the traveler completes four with him: Ibn Abbaas called it the Sunnah of Abu al-Qaasim, the Prophet (Musnad Ahmad 1862; graded saheeh by al-Albaani). Shortening begins once you have left your town:")
                        ScriptureQuote(hadith: "bukhari:1089", cite: "Saheeh al-Bukhaari 1089", arabic: 21...33, english: 0...16)
                    }

                    Section(header: ArticleHeader("COMBINING (JAM')")) {
                        ArticleParagraph(verbatim: "Combining is a concession for hardship while actually on the move, not a fixed rule of travel. Dhuhr may be brought to Asr's time or Asr brought forward to Dhuhr's; Maghrib and Isha likewise. Each prayer is prayed complete in itself, one after the other, with one adhan and two iqaamahs.")
                        ScriptureQuote(hadith: "bukhari:1111", cite: "Saheeh al-Bukhaari 1111", arabic: 23...48, english: 0...54)
                        ScriptureQuote(hadith: "bukhari:1107", cite: "Saheeh al-Bukhaari 1107", arabic: 23...43, english: 0...24)
                        ArticleParagraph(verbatim: "Combining is also allowed for a resident in hard rain, illness, or a genuine hardship, by the report of Ibn Abbaas that the Prophet combined in Madinah without fear or travel so that his ummah not be put to difficulty (Saheeh Muslim 705).")
                        ScriptureQuote(hadith: "muslim:705b", cite: "Saheeh Muslim 705", arabic: 28...66, english: 0...72)
                        ArticleParagraph(verbatim: "How to join the two prayers step by step, and the questions that come with it, have their own guide:")
                        ArticleDoorRow(door: .article("CombinePrayersView"))
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE PERMISSION")) {
                        ScriptureQuote(quran: "4:101")
                        ArticleParagraph(verbatim: "Umar (may Allah be pleased with him) was asked why the shortening remained when the fear had passed. He said he had wondered the same and asked the Prophet, who replied:")
                        ScriptureQuote(hadith: "muslim:686a", cite: "Saheeh Muslim 686", arabic: 79...85, english: 63...78)
                    }

                    Section(header: ArticleHeader("WHO IS A TRAVELER")) {
                        ArticleParagraph(verbatim: "Whoever leaves his town on a journey that is called travel in ordinary speech. Most scholars set a distance of about 80 km (some 48 miles), by the hadith of the Companions; others say any journey with provisions and a night away. Shortening begins once you have left the buildings of your town and ends when you return to them.")
                        ArticleParagraph(verbatim: "On arrival, if you intend to stay four days or fewer you remain a traveler. If you intend longer, most scholars say you pray in full.")
                    }

                    Section(header: ArticleHeader("SHORTENING (QASR)")) {
                        ArticleBullet("• **Dhuhr, Asr and Isha**: two rak‘ah each.")
                        ArticleBullet("• **Fajr**: two, as always. **Maghrib**: three, as always.")
                        ArticleBullet(verbatim: "• The rawaatib are dropped on a journey except the two before Fajr and Witr, which the Prophet (peace and blessings be upon him) never left. Other voluntary prayers remain permitted.")
                        ArticleBullet(verbatim: "• Praying behind a resident imam, the traveler completes four with him.")
                    }

                    Section(header: ArticleHeader("COMBINING (JAM')")) {
                        ArticleParagraph(verbatim: "Combining is a concession for hardship while actually on the move, not a fixed rule of travel. Dhuhr may be brought to Asr's time or Asr brought forward to Dhuhr's; Maghrib and Isha likewise. Each prayer is prayed complete in itself, one after the other, with one adhan and two iqaamahs.")
                        ScriptureQuote(hadith: "bukhari:1107", cite: "Saheeh al-Bukhaari 1107", arabic: 23...43, english: 0...24)
                        ArticleParagraph(verbatim: "Combining is also allowed for a resident in hard rain, illness, or a genuine hardship.")
                        ArticleParagraph(verbatim: "How to join the two prayers step by step has its own guide:")
                        ArticleDoorRow(door: .article("CombinePrayersView"))
                    }
                }

                Section(header: ArticleHeader("PRAYING IN A VEHICLE")) {
                    ArticleParagraph(verbatim: "Obligatory prayers are prayed standing on the ground facing the qiblah wherever stopping is possible. When it is not (an aircraft or train, with the time about to pass), pray as you are able: standing if you can, otherwise seated, facing the qiblah throughout as far as you can, turning with the vehicle if it turns. Voluntary prayers may be offered seated facing the direction of travel, as the Prophet prayed on his mount:")
                    ScriptureQuote(hadith: "bukhari:1094", cite: "Saheeh al-Bukhaari 1094", arabic: 19...32, english: 0...18)
                    ArticleParagraph(verbatim: "Flying has its own guide: planning the prayers around a flight, reading the times in the air, and praying on board:")
                    ArticleDoorRow(door: .article("PlanePrayerView"))
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is shortening obligatory or optional?** The Prophet never prayed four on a journey and neither did his Companions, so shortening is the Sunnah and the safer course. Most scholars hold completing is valid but disliked; some hold shortening is required.")
                        ArticleParagraph(articleMarkdown: "**I am traveling but staying in one place for a week. Do I combine?** It is better not to: in a hotel or a relative's home pray each prayer in its time, shortened if you are still a traveler. Combining while stopped is permitted when there is a need, since the Prophet (peace and blessings be upon him) combined while encamped at Tabook (Saheeh Muslim 706).")
                        ScriptureQuote(hadith: "muslim:706a", cite: "Saheeh Muslim 706", arabic: 19...37, english: 0...28)
                        ArticleParagraph(articleMarkdown: "**What about fasting?** A traveler may break the fast and make it up; if fasting is easy, fasting is better. Allah says: whoever is ill or on a journey, then an equal number of other days (Quran 2:185).")
                        ScriptureQuote(quran: "2:185", words: 17...26)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("On a journey pray the four-rak‘ah prayers as two, combine when moving makes the times hard, keep the two of Fajr and Witr, and accept the charity Allah has given you.")
                }

                ArticleSourcesSection(article: "TravelPrayerView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "TravelPrayerView")
        .navigationTitle("How to Pray While Traveling")
    }
}

/// How the two prayers of a pair are joined, step by step (Abu, 2026-11-25: "a how to guide how to
/// combine prayers when traveling"). `TravelPrayerView` stays the overview and opens this page from
/// its COMBINING section; Traveling Mode's explainer opens it by id.
struct CombinePrayersView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: a traveler may join Dhuhr with Asr, and Maghrib with Isha (**jam', جَمع**), praying the pair one after the other in the time of either one. Fajr is never joined to anything, and Asr is never joined to Maghrib. Each prayer keeps its own rak‘ah and its own iqaamah: joining changes only the time.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHICH PRAYERS")) {
                        ArticleParagraph(verbatim: "Only two pairs are ever joined: Dhuhr with Asr, and Maghrib with Isha. Ibn Abbaas (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "bukhari:1107", cite: "Saheeh al-Bukhaari 1107", arabic: 23...43, english: 0...24)
                        ArticleParagraph(verbatim: "The pairs are fixed by what the Prophet (peace and blessings be upon him) did. No report joins Fajr to the Isha before it or to the Dhuhr after it, and none joins Asr to Maghrib, so each of those is prayed in its own time on every journey.")
                    }

                    Section(header: ArticleHeader("EARLY OR LATE")) {
                        ArticleParagraph(articleMarkdown: "The pair may be prayed in the time of the first (**jam' taqdeem**, early joining) or in the time of the second (**jam' ta’kheer**, late joining). The Prophet (peace and blessings be upon him) chose by where the journey found him. Anas (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "bukhari:1112", cite: "Saheeh al-Bukhaari 1112", arabic: 17...48, english: 0...55)
                        ArticleParagraph(verbatim: "That is late joining: on the move when Dhuhr came in, he prayed both at the next stop. Mu‘aadh ibn Jabal (may Allah be pleased with him) described the other form at Tabook, Asr brought forward to Dhuhr and Isha brought forward to Maghrib before setting off:")
                        ScriptureQuote(hadith: "tirmidhi:553", cite: "Jaami‘ at-Tirmidhi 553; graded saheeh by al-Albaani", arabic: 48...82, english: [31...51, 73...93])
                        ArticleParagraph(verbatim: "Early joining is also what every pilgrim does at Arafah, and late joining what he does at Muzdalifah, by agreement of the scholars. So do whichever is easier: if you are stopped when the first time comes in and will be moving through the second, join early; if you are moving through the first, delay it and join when you stop.")
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Know which form you are praying.** Joining early, the time of the first prayer must have come in. Joining late, decide to delay before the time of the first prayer runs out, so that it is delayed by intention and not by neglect.")
                        ArticleStep("2. **One adhan, and an iqaamah for each prayer.** That is how the Prophet (peace and blessings be upon him) joined Dhuhr and Asr at Arafah, as Jaabir (may Allah be pleased with him) described:")
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 922...935, english: 1567...1607)
                        ArticleStep("3. **Pray the first prayer and give the salaam.** Dhuhr is two rak‘ah when you are shortening. Maghrib is always three.")
                        ArticleStep("4. **Stand again without a long gap**, give the iqaamah, and pray the second: Asr as two rak‘ah, Isha as two.")
                        ArticleStep("5. **Keep the order** in both forms: Dhuhr before Asr, Maghrib before Isha, even when you are praying them in the time of the second. The Standing Committee ruled the order obligatory whichever time is used.")
                        ArticleStep("6. **Nothing voluntary between the two.** Ibn Umar (may Allah be pleased with him) said of the night at Muzdalifah:")
                        ScriptureQuote(hadith: "bukhari:1673", cite: "Saheeh al-Bukhaari 1673", arabic: 22...44, english: 0...36)
                        ArticleStep("7. **Witr may follow at once.** Once Isha has been prayed, the time of Witr has begun, even when Isha was joined in the time of Maghrib (the Standing Committee; Ibn al-Uthaymeen).")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHICH PRAYERS")) {
                        ArticleBullet("• **Dhuhr with Asr**, and **Maghrib with Isha**. Nothing else.")
                        ArticleBullet(verbatim: "• Fajr is never joined to anything, and Asr is never joined to Maghrib.")
                        ScriptureQuote(hadith: "bukhari:1107", cite: "Saheeh al-Bukhaari 1107", arabic: 23...43, english: 0...24)
                    }

                    Section(header: ArticleHeader("EARLY OR LATE")) {
                        ArticleParagraph(articleMarkdown: "Pray the pair in the time of the first (**jam' taqdeem**) or in the time of the second (**jam' ta’kheer**), whichever is easier: join early if you are stopped now and will be moving later, join late if you are moving now. Anas (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "muslim:704b", cite: "Saheeh Muslim 704", arabic: 21...44, english: 0...32)
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Know which form you are praying.** Early: the time of the first prayer has come in. Late: you decided to delay before the first prayer's time ran out.")
                        ArticleStep("2. **One adhan, and an iqaamah for each prayer**, as the Prophet (peace and blessings be upon him) joined Dhuhr and Asr at Arafah:")
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 922...935, english: 1567...1607)
                        ArticleStep("3. **Pray the first prayer and give the salaam.** Dhuhr is two rak‘ah when you are shortening. Maghrib is always three.")
                        ArticleStep("4. **Stand again without a long gap**, give the iqaamah, and pray the second: Asr as two rak‘ah, Isha as two.")
                        ArticleStep("5. **Keep the order** in both forms: Dhuhr before Asr, Maghrib before Isha.")
                        ArticleStep("6. **Nothing voluntary between the two.** Witr may be prayed as soon as Isha is done, even in the time of Maghrib.")
                    }
                }

                Section(header: ArticleHeader("HOW MANY RAK‘AH")) {
                    ArticleBullet("• **Dhuhr and Asr**: two and two.")
                    ArticleBullet("• **Maghrib and Isha**: three and two. Maghrib is never shortened.")
                    ArticleBullet("• **Fajr**: two, in its own time.")
                    ArticleBullet(verbatim: "• Joining without traveling, in illness or a resident's real hardship, leaves every prayer at its full length: four and four, three and four.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("SHORTENING IS NOT COMBINING")) {
                        ArticleParagraph(verbatim: "The two concessions are often taken for one. Shortening belongs to travel itself: a traveler shortens every four-rak‘ah prayer from the time he leaves his town until he returns to it, and most scholars hold that it is better for him than praying in full. Combining belongs to need: it is for whoever would find it hard to pray each prayer in its own time, traveler or not.")
                        ArticleParagraph(verbatim: "So on the road, join. Settled at your destination, in a hotel or a relative's home, it is better to pray each prayer in its time, shortened. Joining stays allowed there, and the reason Mu‘aadh gave for it at Tabook is ease:")
                        ScriptureQuote(hadith: "muslim:706b", cite: "Saheeh Muslim 706", arabic: 29...58, english: 0...56)
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) did not join on every journey. At Mina during the Farewell Hajj he shortened and, as the scholars point out, prayed each prayer in its own time. Abdullah ibn Umar (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "bukhari:1082", cite: "Saheeh al-Bukhaari 1082", arabic: 20...31, english: 0...18)
                        ArticleParagraph(verbatim: "Ibn al-Uthaymeen put it in one line: for the traveler on the road joining is better, in whichever time is easier; for the traveler who has stopped, not joining is better, unless he is tired, short of water, or otherwise in need of it.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I prayed Dhuhr at home and then set off. May I pray Asr early, on the road?** Pray Asr in its own time, shortened if you are a traveler by then. Early joining is the two prayers offered back to back, and the majority of scholars make that continuity a condition; Ibn Taymiyyah did not. With Dhuhr long finished, leave the difference alone and wait for Asr's time.")
                        ArticleParagraph(articleMarkdown: "**My journey leaves after Dhuhr and I will not be able to stop for Asr.** Join Asr to Dhuhr before you leave. Joining is open to a resident who would otherwise lose the second prayer's time, so this is allowed even at home. Whoever is still inside his town prays both in full, four and four, because shortening begins only once its buildings are behind him; at an airport outside the town he shortens as well (Ibn al-Uthaymeen).")
                        ArticleParagraph(articleMarkdown: "**Must I intend to join when I begin the first prayer?** The Shaafi‘i and Hanbali schools require the intention within the first prayer when joining early, the Hanbalis at its opening takbeer. Ibn Taymiyyah, Ibn Baaz and Ibn al-Uthaymeen held that it is not a condition: if the reason is there, you may decide after the first prayer is finished. Intend it from the start and you are clear of the difference.")
                        ArticleParagraph(articleMarkdown: "**How long a gap may come between the two?** When joining early, a short one: about the time of an iqaamah and a quick wudu, as the Hanbali jurists put it. The majority hold that a long gap breaks the joining; Ibn Taymiyyah held that it does not. When joining late there is more room, since the second prayer is in its own time either way, but praying them together is still the Sunnah.")
                        ArticleParagraph(articleMarkdown: "**May Asr be joined to Jumuah?** Ibn Baaz and Ibn al-Uthaymeen said no: Jumuah is a prayer of its own and no text joins Asr to it, so a traveler who prays Jumuah with the people prays Asr in its time. The Shaafi‘i school allows it. A traveler is not obliged to attend Jumuah, and if he prays Dhuhr instead he may join Asr to it as on any other day.")
                        ArticleParagraph(articleMarkdown: "**I delayed Dhuhr to join it with Asr, then reached home before Asr came in.** Pray Dhuhr now, and in full: you are a resident again and its time has not ended. Pray Asr in its own time, also in full. Had Asr already come in, you would pray Dhuhr and then Asr, both in full, since shortening ended when you arrived.")
                        ArticleParagraph(articleMarkdown: "**I joined Asr early and reached home before Asr came in.** The prayer stands and is not repeated: it was valid when you prayed it, and the excuse ending afterward does not undo it (Ibn Qudaamah in al-Mughni; an-Nawawi in al-Majmoo‘; the Standing Committee). Ibn al-Uthaymeen added that if you expect to arrive before Asr, it is better not to join in the first place.")
                        ArticleParagraph(articleMarkdown: "**I am praying behind an imam who is a resident.** Pray four with him, whichever of your prayers it is. That was the practice of Ibn Umar (may Allah be pleased with him):")
                        ScriptureQuote(hadith: "muslim:694c", cite: "Saheeh Muslim 694", arabic: 45...58, english: 34...54)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("SHORTENING IS NOT COMBINING")) {
                        ArticleParagraph(verbatim: "Shortening belongs to travel itself: every four-rak‘ah prayer is two from the time you leave your town until you return. Combining belongs to need. On the road, join; settled at your destination, it is better to pray each prayer in its own time, shortened, though joining stays allowed.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I prayed Dhuhr at home and then set off.** Pray Asr in its own time, shortened if you are a traveler by then. Early joining is the two prayers offered back to back.")
                        ArticleParagraph(articleMarkdown: "**My journey leaves after Dhuhr and I will not be able to stop for Asr.** Join Asr to Dhuhr before you leave. Inside your own town pray both in full; shortening begins once its buildings are behind you.")
                        ArticleParagraph(articleMarkdown: "**I joined Asr early and reached home before Asr came in.** The prayer stands and is not repeated.")
                        ArticleParagraph(articleMarkdown: "**I am praying behind an imam who is a resident.** Pray four with him, whichever of your prayers it is.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Dhuhr with Asr, Maghrib with Isha: one adhan, an iqaamah for each, the first and then the second with nothing between them, in the time of whichever is easier. Shorten because you are traveling; join because you need to.")
                    ArticleDoorRow(door: .article("TravelPrayerView"))
                    ArticleDoorRow(door: .article("PlanePrayerView"))
                }

                ArticleSourcesSection(article: "CombinePrayersView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "CombinePrayersView")
        .navigationTitle("How to Combine Prayers While Traveling")
    }
}

/// Praying around and during a flight (Abu, 2026-11-25: "a how to guide on how to pray on a plane").
/// `TravelPrayerView` opens it from PRAYING IN A VEHICLE; Traveling Mode's explainer opens it by id.
struct PlanePrayerView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: pray on the ground when the journey allows it, before boarding or after landing, joining Dhuhr with Asr or Maghrib with Isha if that is what makes it possible. If a prayer's time will end while you are in the air, pray it on the plane: standing and facing the qiblah if you can, seated in your place if you cannot. The time must not pass.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("PLAN BEFORE YOU FLY")) {
                        ArticleParagraph(verbatim: "A prayer belongs to its time, in the air as on the ground:")
                        ScriptureQuote(quran: "4:103", words: 13...19)
                        ArticleStep("1. **Set the prayer times beside the flight.** For each prayer between leaving home and arriving, ask where you will be when its time comes in and where you will be when it ends.")
                        ArticleStep("2. **Use the pairs.** Dhuhr and Asr can be prayed together before boarding or together after landing, and so can Maghrib and Isha, as long as you are on the ground inside the time of one of the two. A pair joined before you leave your own town is prayed in full; past its buildings, as at an airport outside the town, you shorten as well.")
                        ArticleStep("3. **Know what cannot be joined.** Fajr is joined to nothing, Asr is not joined to Maghrib, and Isha is not joined to Fajr. A flight that covers the whole of such a prayer's time means praying it in the air.")
                        ArticleStep("4. **Board in wudu, with your socks on.** Socks put on while in wudu may be wiped over in place of washing the feet, and the traveler's allowance is three days and nights. Ali (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "muslim:276a", cite: "Saheeh Muslim 276", arabic: 54...67, english: 37...63)
                        ArticleStep("5. **Find the qiblah before you need it.** Note the direction of travel and where Makkah lies from the route, so that in the air you only have to check the flight map.")
                    }

                    Section(header: ArticleHeader("THE TIME IN THE AIR")) {
                        ArticleParagraph(verbatim: "The times of prayer are signs in the sky, and they are read from where you are. In the air that means the sun as you see it from the plane, not the timetable of the city below and not the clock of the city you left. Maghrib comes in when the sun's disc has gone from your horizon:")
                        ScriptureQuote(hadith: "bukhari:561", cite: "Saheeh al-Bukhaari 561", arabic: 13...24, english: 0...17)
                        ArticleParagraph(verbatim: "Fajr comes in when the true dawn spreads along the horizon and ends when the sun's edge appears; Dhuhr comes in when the sun passes its highest point. Height changes what you see: at cruising altitude the sun sets later and rises earlier than it does for the people beneath you. Direction changes it more: flying west you follow the sun and the day stretches; flying east you meet the night early.")
                        ArticleParagraph(verbatim: "The scholars gave the same rule for the fast, which ends with the same sunset. Ibn Baaz and the Standing Committee ruled that a fasting passenger who can still see the sun does not break his fast, even when he knows the city below has broken theirs, and Ibn al-Uthaymeen said of a traveler heading west that he keeps fasting until the sun sets where he is, however long that takes. The Prophet (peace and blessings be upon him) tied it to the sun itself:")
                        ScriptureQuote(hadith: "bukhari:1954", cite: "Saheeh al-Bukhaari 1954", arabic: 35...50, english: 4...28)
                        ArticleParagraph(verbatim: "In practice: look out of the window, check the flight map for where you are and the local time there, and when the sign is in doubt wait until you are sure the time has come in. A prayer offered before its time does not count.")
                    }

                    Section(header: ArticleHeader("FLIGHT MODE IN THIS APP")) {
                        ArticleParagraph(verbatim: "Reading those signs from a seat is hard. The plane crosses a time zone an hour, the window may face away from the sun, and the timetable in your pocket is for a city you have left. Flight Mode does the working out, and needs nothing typed: turn it on, and it starts from where your phone last was. In the air the phone's GPS, which works in airplane mode, follows the plane, and Flight Mode finds the minute each prayer's sign reaches it.")
                        ArticleParagraph(verbatim: "GPS needs a view of the sky, so it reaches a phone beside a window and seldom one in an aisle seat. For that, and for a flight you want worked out before you board, add where you land, and the two times on your ticket if you have them: the whole route is then known in advance.")
                        ArticleBullet(verbatim: "• Each prayer is timed for where the plane will be when it comes in, not for the ground beneath you now. Once the route is known, a notification is set for each one, so it arrives in airplane mode.")
                        ArticleBullet(verbatim: "• The times allow for your height. From cruising altitude the horizon lies about three and a half degrees lower, so the sun sets about a quarter of an hour later than for the people beneath you and rises as much earlier, and the dawn and the end of the dusk move with them.")
                        ArticleBullet(verbatim: "• Beside each prayer that comes in on board it follows the plan above: whether it may be joined to the prayer before it on the ground before you board, whether its time lasts until after you land, alone or joined to the next, so that it can wait for the ground, or whether it ends in the air, so that it is prayed on board.")
                        ArticleBullet(verbatim: "• It shows the qiblah from your seat, as so many degrees to the right or left of the plane's nose. That comes from the route: a phone's compass cannot be trusted inside an aircraft.")
                        ArticleBullet(verbatim: "• After landing, the times and the notifications are the arrival city's.")
                        ArticleParagraph(verbatim: "The app also asks by itself, with a notification: when your phone settles at an airport, and again if its GPS shows a plane's speed and height. An iPhone does not wake an app in the air in airplane mode, so the question at the airport is the one that reaches you in time.")
                        ArticleParagraph(verbatim: "These times are a calculation, and a calculation serves the signs; it does not replace them. From a ticket alone they are good to about ten minutes, because a flight may leave late or fly around weather. Each GPS fix corrects them, and between fixes they rest on the course the plane was last seen to keep. Where the app and the sky disagree, the sky decides: do not pray Maghrib or break a fast while the sun is still in sight, and give a prayer a few minutes after its time before you begin.")
                        #if os(iOS) && HAS_ADHAN
                        FlightModeDoorRow()
                        #endif
                    }

                    Section(header: ArticleHeader("HOW TO PRAY ON BOARD")) {
                        ArticleStep("1. **Ask for a place to stand.** A galley or the space by a door is enough for one person. Ask the crew, choose a quiet stretch of the flight, and do not pray where you have been told it is unsafe.")
                        ArticleStep("2. **Stand, bow and prostrate if you can.** These are pillars of an obligatory prayer for whoever is able, and the Standing Committee ruled that shyness is no excuse for sitting. Allah says:")
                        ScriptureQuote(quran: "2:238", words: 5...7)
                        ArticleParagraph(verbatim: "And the Prophet (peace and blessings be upon him) said to Imraan ibn Husayn (may Allah be pleased with him):")
                        ScriptureQuote(hadith: "bukhari:1117", cite: "Saheeh al-Bukhaari 1117", arabic: 40...50, english: 13...35)
                        ArticleStep("3. **Face the qiblah.** Find it from the flight map, a compass, or the crew: Ibn al-Uthaymeen ruled that a passenger must ask when the direction is not shown, and that his prayer is not valid if he could have asked and did not. Begin facing it, and if the plane turns, turn with it as far as you are able.")
                        ArticleStep("4. **If you truly cannot stand or cannot face it**, because the seat-belt sign is on, the aisles are in use, or there is no space at all, pray in your seat. Bow by leaning forward and make the prostration lower than the bowing. What you cannot do falls away, and what you can do remains:")
                        ScriptureQuote(quran: "64:16", words: 0...3)
                        ScriptureQuote(hadith: "muslim:1337", cite: "Saheeh Muslim 1337", arabic: 82...88, english: 106...123)
                        ArticleStep("5. **Shorten.** You are a traveler: Dhuhr, Asr and Isha are two rak‘ah each, Maghrib three, Fajr two.")
                        ArticleStep("6. **Voluntary prayers are easier still.** They may be prayed seated, facing wherever the plane is heading, with a nod for the bowing and a lower one for the prostration. Aamir ibn Rabee‘ah (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "bukhari:1097", cite: "Saheeh al-Bukhaari 1097", arabic: 25...54, english: 0...30)
                    }

                    Section(header: ArticleHeader("WUDU ON BOARD")) {
                        ArticleBullet(verbatim: "• Use the basin in the lavatory, with little water, and dry what you splash. Wudu done with care takes very little.")
                        ArticleBullet(verbatim: "• Wipe over your socks instead of washing your feet, if you put them on while in wudu.")
                        ArticleBullet(verbatim: "• If the prayer can be joined to the next and you will land inside the second one's time, delay it with the intention of joining and pray both on the ground with wudu (Ibn al-Uthaymeen).")
                        ArticleBullet(verbatim: "• If water cannot be used at all (none left, frozen, or not permitted), make tayammum on a surface that carries dust; Ibn al-Uthaymeen mentioned the seats.")
                        ArticleBullet(verbatim: "• If there is neither water nor dust and the prayer cannot wait for the ground, pray as you are. Ibn al-Uthaymeen ruled so for the passenger, and Ibn Qudaamah and Ibn al-Qayyim held that such a prayer is not repeated, since its owner did what he was commanded as far as he could. The proof is the Companions who prayed with no water before tayammum was revealed and were not told to repeat:")
                        ScriptureQuote(hadith: "bukhari:336", cite: "Saheeh al-Bukhaari 336", arabic: 34...52, english: 27...57)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**May I wait and pray after landing?** If you will land with enough of the prayer's time left, yes; and if you could not have stood or faced the qiblah on board, you must, because those are dropped only when the time would otherwise be lost. The same holds when the prayer can be joined to the next and you will land inside the second one's time: delay it and pray the two together on the ground (Ibn al-Uthaymeen). If you are able to pray it whole on board, standing and facing the qiblah, the Standing Committee held with the majority that you may pray it there in its own time. What is never allowed is to let the time run out: Fajr is not left until after sunrise, nor Asr until after sunset, on the excuse of a flight.")
                        ArticleParagraph(articleMarkdown: "**I prayed seated when I could have stood.** Then the prayer has to be repeated. The Standing Committee was asked about a passenger who sat out of shyness and answered that sitting is not allowed in an obligatory prayer for one who is able to stand. If you sat, or faced another way, because you truly could not do otherwise, the prayer is valid.")
                        ArticleParagraph(articleMarkdown: "**The day, or the night, never seems to end.** It ends when the sun sets or rises for you, not when a clock says it should. Flying west, each prayer comes in later than it would have at home, and you pray it when its sign arrives for you; flying east the prayers come quickly, and you pray each as it comes in. A prayer you have already prayed in its time is not repeated because you land somewhere its time has only just begun.")
                        ArticleParagraph(articleMarkdown: "**I am fasting. When do I break my fast in the air?** When the sun sets for you. If you can still see it from the plane you are still fasting, even if the city below has broken its fast (Ibn Baaz; the Standing Committee). If you broke your fast on the ground at sunset and then took off and saw the sun again, your fast is complete and you do not resume it. A traveler may also use his concession, break the fast, and make the day up.")
                        ArticleParagraph(articleMarkdown: "**Is a prayer in the air valid at all?** Yes. The Standing Committee recorded the agreement of the scholars that when the time would otherwise pass, the prayer is obligatory on board and is prayed as far as one is able. Where there is still time to pray on the ground, the majority allow praying on board as well; a few later Maaliki jurists held that a prayer must be on the ground or on something resting on it, and the Committee judged the majority's view correct.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("PLAN BEFORE YOU FLY")) {
                        ArticleStep("1. **Set the prayer times beside the flight**: where will you be when each one comes in, and when it ends?")
                        ArticleStep("2. **Use the pairs.** Dhuhr and Asr can be prayed together before boarding or after landing, and so can Maghrib and Isha, as long as you are on the ground inside the time of one of the two.")
                        ArticleStep("3. **Know what cannot be joined.** Fajr is joined to nothing. A flight that covers all of its time means Fajr in the air.")
                        ArticleStep("4. **Board in wudu, with your socks on**, so that you can wipe over them instead of washing your feet. Ali (may Allah be pleased with him) gave the traveler's allowance:")
                        ScriptureQuote(hadith: "muslim:276a", cite: "Saheeh Muslim 276", arabic: 54...67, english: 37...63)
                    }

                    Section(header: ArticleHeader("THE TIME IN THE AIR")) {
                        ArticleParagraph(verbatim: "The times of prayer are read from the sky where you are: the sun as you see it from the plane, not the timetable of the city below or the clock of the city you left. Maghrib comes in when the sun's disc is gone from your horizon, and Fajr when the true dawn shows. Flying west stretches the day and flying east shortens it. When the sign is in doubt, wait until you are sure the time has come in.")
                        ScriptureQuote(hadith: "bukhari:561", cite: "Saheeh al-Bukhaari 561", arabic: 13...24, english: 0...17)
                    }

                    Section(header: ArticleHeader("FLIGHT MODE IN THIS APP")) {
                        ArticleParagraph(verbatim: "Flight Mode works those times out for you, with nothing to type: turn it on, and in the air your phone's GPS follows the plane and gives the minute each prayer comes in for it, allowing for its height. Add where you land and the whole flight is worked out before you board, with a notification at each prayer, even in airplane mode. It also says which prayers can be joined before you board or can wait for the ground, and shows the qiblah from your seat. Its times are a calculation: where they and the sky disagree, the sky decides.")
                        #if os(iOS) && HAS_ADHAN
                        FlightModeDoorRow()
                        #endif
                    }

                    Section(header: ArticleHeader("HOW TO PRAY ON BOARD")) {
                        ArticleStep("1. **Ask for a place to stand**: a galley or the space by a door, when the crew say it is safe.")
                        ArticleStep("2. **Stand, bow and prostrate if you can.** They are pillars of an obligatory prayer for whoever is able:")
                        ScriptureQuote(hadith: "bukhari:1117", cite: "Saheeh al-Bukhaari 1117", arabic: 40...50, english: 13...35)
                        ArticleStep("3. **Face the qiblah**, from the flight map or by asking the crew, and turn with the plane if you are able.")
                        ArticleStep("4. **If you truly cannot stand or cannot face it**, pray in your seat: bow by leaning forward and make the prostration lower. What you cannot do falls away:")
                        ScriptureQuote(quran: "64:16", words: 0...3)
                        ArticleStep("5. **Shorten**: Dhuhr, Asr and Isha are two rak‘ah each.")
                        ArticleStep("6. **Voluntary prayers** may be prayed seated, facing wherever the plane is heading.")
                    }

                    Section(header: ArticleHeader("WUDU ON BOARD")) {
                        ArticleBullet(verbatim: "• Use the basin, with little water, and wipe over your socks instead of washing your feet.")
                        ArticleBullet(verbatim: "• If water cannot be used at all, make tayammum on a surface that carries dust.")
                        ArticleBullet(verbatim: "• If there is neither, pray as you are before you let the time pass.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**May I wait and pray after landing?** Yes, if you will land with enough of the prayer's time left, or if it can be joined to the next prayer and you will land inside the second one's time. Never when the time would run out.")
                        ArticleParagraph(articleMarkdown: "**I prayed seated when I could have stood.** The prayer has to be repeated. If you truly could not stand or face the qiblah, it is valid.")
                        ArticleParagraph(articleMarkdown: "**I am fasting. When do I break my fast in the air?** When the sun sets for you: while you can still see it from the plane, you are still fasting.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Plan the prayers around the flight and pray on the ground whenever the pairs allow it. In the air, read the time from the sun where you are; stand and face the qiblah if you can, sit if you cannot; shorten, and never let a prayer's time pass.")
                    ArticleDoorRow(door: .article("TravelPrayerView"))
                    ArticleDoorRow(door: .article("CombinePrayersView"))
                }

                ArticleSourcesSection(article: "PlanePrayerView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "PlanePrayerView")
        .navigationTitle("How to Pray on a Plane")
    }
}

struct SickPrayerView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: illness never removes the prayer; it removes only what you cannot do. Pray standing if you can, sitting if you cannot, lying on your side if you cannot sit, and with the eyes and heart if you cannot move. Allah burdens no soul beyond its capacity.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE PRINCIPLE")) {
                        ScriptureQuote(quran: "2:286")
                        ScriptureQuote(quran: "64:16")
                        ArticleParagraph(verbatim: "Imraan ibn Husayn (may Allah be pleased with him), who suffered from piles, asked the Prophet (peace and blessings be upon him) about prayer. He said:")
                        ScriptureQuote(hadith: "bukhari:1117", cite: "Saheeh al-Bukhaari 1117", arabic: 40...50, english: 13...35)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE PRINCIPLE")) {
                        ScriptureQuote(quran: "64:16")
                        ArticleParagraph(verbatim: "Imraan ibn Husayn (may Allah be pleased with him), who suffered from piles, asked the Prophet (peace and blessings be upon him) about prayer. He said:")
                        ScriptureQuote(hadith: "bukhari:1117", cite: "Saheeh al-Bukhaari 1117", arabic: 40...50, english: 13...35)
                    }
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    ArticleStep("1. **Standing** is required in the obligatory prayer for whoever can. Lean on a wall or a stick if that lets you stand.")
                    ArticleStep("2. **If standing is impossible or harmful**, sit, cross-legged or as is comfortable, and bow by bending forward from the sitting position. Prostrate on the ground if you can.")
                    ArticleStep("3. **If sitting on the ground is impossible**, sit on a chair, and prostrate on the ground if possible; if not, bow and prostrate by bending forward, the prostration lower than the bow.")
                    ArticleStep("4. **If sitting is impossible**, lie on your right side facing the qiblah, and perform the bowing and prostration by tilting the head.")
                    ArticleStep("5. **If even that is impossible**, lie on your back with the feet toward the qiblah, and make the movements with the head; if even that is impossible, the heart intends each pillar (the Hanbali school has him gesture with the eyes first; other scholars hold that no authentic text mentions the eyes and the heart alone intends).")
                    ArticleStep(verbatim: "6. Recite as usual; if the tongue cannot, recite in the heart. The prayer is never dropped while the mind is present.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE REWARD OF THE SEATED")) {
                        ArticleParagraph(verbatim: "Sitting when standing is possible halves the reward of a voluntary prayer; sitting out of inability loses nothing:")
                        ScriptureQuote(hadith: "bukhari:1115", cite: "Saheeh al-Bukhaari 1115", arabic: 72...90, english: 18...55)
                        ArticleParagraph(verbatim: "The scholars explain that this halving is for the able who choose to sit in voluntary prayer. The one who is unable and does what he can has his full reward, by the hadith that the servant is written the reward of what he used to do in health when illness or travel prevents him (Saheeh al-Bukhaari 2996).")
                        ScriptureQuote(hadith: "bukhari:2996", cite: "Saheeh al-Bukhaari 2996", arabic: 50...62, english: 36...62)
                    }
                }

                Section(header: ArticleHeader("PURIFICATION WHEN ILL")) {
                    ArticleBullet(verbatim: "• If water harms you, make tayammum on clean earth, a dusty wall, or a container of earth kept by the bed.")
                    ArticleBullet(verbatim: "• If you cannot move, someone may help you make wudu or tayammum.")
                    ArticleBullet(verbatim: "• A wound or cast is wiped over; the rest is washed.")
                    ArticleBullet(verbatim: "• One with incontinence or continuous bleeding makes wudu for each prayer after its time begins and prays; what escapes afterward does not harm.")
                    ArticleBullet(verbatim: "• Impure clothes or bedding are changed or washed when possible; if not, pray as you are.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMBINING WHEN ILL")) {
                        ArticleParagraph(verbatim: "A sick person for whom praying each prayer in its time is a real hardship may combine Dhuhr with Asr and Maghrib with Isha, at either time, as the traveler does. The scholars draw this from the Prophet's combining in Madinah without fear or travel (Saheeh Muslim 705) and from his instruction to the woman with prolonged bleeding.")
                        ScriptureQuote(hadith: "muslim:705b", cite: "Saheeh Muslim 705", arabic: 28...66, english: 0...72)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I was unconscious for a day. Do I make up the prayers?** If unconsciousness lasted a short period, make them up; if it lasted more than three days, there is no make-up (the view Ibn Baaz took from the report of Ammaar; the schools differ here), as the pen is lifted from one without awareness. A person asleep makes up what he missed.")
                        ArticleParagraph(articleMarkdown: "**Can I pray on a hospital bed facing away from the qiblah?** Face it if you can, even by asking to be turned; if you cannot, pray as you are. The obligation is according to ability.")
                        ArticleParagraph(articleMarkdown: "**Chair or floor?** The floor, so that the prostration is on the ground, unless standing up from the floor or prostrating harms you. Use the chair for what you cannot do and the floor for what you can.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMBINING WHEN ILL")) {
                        ArticleParagraph(verbatim: "A sick person for whom praying each prayer in its time is a real hardship may combine Dhuhr with Asr and Maghrib with Isha, at either time, as the traveler does.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Standing, then sitting, then lying down, then the head and the eyes: the prayer follows your ability and never leaves you. Do what you can, and the reward of what you cannot is written for you.")
                }

                ArticleSourcesSection(article: "SickPrayerView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "SickPrayerView")
        .navigationTitle("How to Pray When Sick")
    }
}

struct MissedPrayerView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: a prayer missed through sleep or forgetting is prayed as soon as you remember, in order, and that is its only expiation. Prayers left deliberately are a grave matter to be repented from at once; the scholars differ on whether they can be made up, and all agree on repentance and on guarding what remains.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("SLEEP AND FORGETTING")) {
                        ScriptureQuote(hadith: "bukhari:597", cite: "Saheeh al-Bukhaari 597", arabic: 21...31, english: 4...26)
                        ArticleParagraph(verbatim: "And he recited: “And establish prayer for My remembrance” (Quran 20:14).")
                        ScriptureQuote(quran: "20:14", words: 8...10)
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) himself once slept through Fajr on a journey and prayed it when the Companions woke, after the sun had risen (Saheeh al-Bukhaari 595).")
                        ScriptureQuote(hadith: "bukhari:595", cite: "Saheeh al-Bukhaari 595", arabic: 50...109, english: 58...154)
                        ArticleParagraph(verbatim: "He said:")
                        ScriptureQuote(hadith: "muslim:681", cite: "Saheeh Muslim 681", arabic: 362...392, english: 495...519)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("SLEEP AND FORGETTING")) {
                        ScriptureQuote(hadith: "bukhari:597", cite: "Saheeh al-Bukhaari 597", arabic: 21...31, english: 4...26)
                        ArticleParagraph(verbatim: "And he recited: “And establish prayer for My remembrance” (Quran 20:14).")
                        ScriptureQuote(quran: "20:14", words: 8...10)
                    }
                }

                Section(header: ArticleHeader("STEP BY STEP")) {
                    ArticleStep("1. **Pray it at once** on waking or remembering, even if it is a forbidden time for voluntary prayer; a missed obligatory prayer has no forbidden time.")
                    ArticleStep("2. **Keep the order.** If you missed Dhuhr and remember at Asr, pray Dhuhr first and then Asr, as the Prophet prayed Asr before Maghrib on the day of the Trench:")
                    ScriptureQuote(hadith: "bukhari:945", cite: "Saheeh al-Bukhaari 945", arabic: 51...71, english: [34...43, 44...70])
                    ArticleStep("3. **Pray it as it would have been prayed**: the same number of rak‘ah, aloud or quietly as its time calls for. A traveler who missed a prayer while traveling makes it up shortened.")
                    ArticleStep("4. **Order is dropped** if the current prayer's time would run out, or if you did not remember the missed one until after it.")
                    ArticleStep("5. **Make wudu with care** and pray it with the presence of the one grateful to have remembered.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("PRAYERS LEFT ON PURPOSE")) {
                        ArticleParagraph(verbatim: "Leaving the prayer knowingly is among the gravest of sins. Ibn Baaz and Ibn Uthaymeen held that abandoning it altogether is disbelief; al-Albaani held it is not unless its obligation is denied. The Prophet (peace and blessings be upon him) placed it at the boundary of faith:")
                        ScriptureQuote(hadith: "muslim:82a", cite: "Saheeh Muslim 82a", arabic: 34...41, english: 21...33)
                        ArticleParagraph(verbatim: "The scholars hold two views on making up what was left deliberately. The majority say: make them up, as many as you can estimate, alongside repentance, and the debt to Allah is paid with the prayers themselves. Others, among them Ibn Taymiyyah and Ibn Hazm, say a prayer deliberately left has no valid make-up, for it was tied to its time, and the door is sincere repentance and abundant voluntary prayer. On both views, repent immediately, guard every remaining prayer, and fill your days with voluntary prayer, for the voluntary completes what the obligatory lacked.")
                    }

                    Section(header: ArticleHeader("PREVENTION")) {
                        ArticleBullet(verbatim: "• Set an alarm for Fajr and sleep early; the Prophet disliked talk after Isha (Saheeh al-Bukhaari 568).")
                        ScriptureQuote(hadith: "bukhari:568", cite: "Saheeh al-Bukhaari 568", arabic: 26...32, english: 0...14)
                        ArticleBullet(verbatim: "• Ask someone to wake you, as the Companions kept watch for one another.")
                        ArticleBullet(verbatim: "• Pray each prayer at the start of its time when you can; the best deed is prayer at its time.")
                        ArticleBullet(verbatim: "• Say the sleeping remembrances and make the intention to rise; if sleep still overcomes you, you are excused.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Do I make up the Sunnah prayers too?** The rawaatib may be made up, especially the two of Fajr: when the Prophet and the Companions slept through Fajr on a journey, he prayed its two sunnah rak‘ah before the obligatory prayer (Saheeh Muslim 681). Witr missed by sleep is prayed when you wake.")
                        ArticleParagraph(articleMarkdown: "**A woman missed prayers during menses.** They are not made up; the fast of Ramadan is. Prayers missed before the bleeding began, whose time had entered, are made up.")
                        ArticleParagraph(articleMarkdown: "**I do not know how many I missed.** Estimate generously and pray until you are confident you have covered them, one day's worth at a time, without a hardship that makes you abandon it.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("PRAYERS LEFT ON PURPOSE")) {
                        ArticleParagraph(verbatim: "Leaving the prayer knowingly is among the gravest of sins, and the Prophet (peace and blessings be upon him) placed it at the boundary of faith:")
                        ScriptureQuote(hadith: "muslim:82a", cite: "Saheeh Muslim 82a", arabic: 34...41, english: 21...33)
                        ArticleParagraph(verbatim: "The scholars hold two views on making up what was left deliberately. The majority say: make them up, as many as you can estimate, alongside repentance. Others, among them Ibn Taymiyyah and Ibn Hazm, say it has no valid make-up, and the door is sincere repentance and abundant voluntary prayer. On both views, repent immediately and guard every remaining prayer.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Missed by sleep or forgetting: pray it the moment you remember, in order. Left deliberately: repent now, guard what remains, and make up or fill in with voluntary prayer as the scholars you follow direct.")
                }

                ArticleSourcesSection(article: "MissedPrayerView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "MissedPrayerView")
        .navigationTitle("How to Make Up Missed Prayers")
    }
}

struct SujudSahwView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Sujood as-Sahw (سُجُود السَّهو)** is two prostrations that repair a slip in the prayer: something added, something omitted, or a doubt about the count. For a missed required act, or a doubt where neither side seems more likely, they are made before the tasleem; for an addition, an early tasleem, or a doubt settled on the more likely side, after it. The Prophet (peace and blessings be upon him) forgot in prayer and taught his ummah exactly what to do.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE PROPHET FORGOT TOO")) {
                        ScriptureQuote(hadith: "bukhari:401", cite: "Saheeh al-Bukhaari 401", arabic: 64...96, english: 102...169)
                        ArticleParagraph(verbatim: "He prayed five rak‘ah of Dhuhr once and, when told, turned his legs and prostrated twice (Saheeh al-Bukhaari 404).")
                        ScriptureQuote(hadith: "bukhari:404", cite: "Saheeh al-Bukhaari 404", arabic: 17...41, english: 0...45)
                    }

                    Section(header: ArticleHeader("THREE CASES")) {
                        ArticleParagraph(articleMarkdown: "**1. Something added** (an extra bow, prostration, standing or rak‘ah): complete the prayer, give the tasleem, then prostrate twice and give the tasleem again. If you realize during an extra rak‘ah, sit at once.")
                        ArticleParagraph(articleMarkdown: "**2. Something omitted**: a pillar (ruku, sujood, al-Faatihah) must be gone back to if you have not reached its place in the next rak‘ah; otherwise that rak‘ah is void and the next stands in for it, with prostration after the tasleem. A required act such as the first tashahhud is not returned to once you have stood upright; you continue and prostrate before the tasleem:")
                        ScriptureQuote(hadith: "bukhari:1224", cite: "Saheeh al-Bukhaari 1224", arabic: 28...60, english: 0...70)
                        ArticleParagraph(articleMarkdown: "**3. A doubt about the count**: if one side seems more likely, act on it and prostrate after the tasleem. If neither does, build on what you are certain of, the smaller number, and prostrate before the tasleem:")
                        ScriptureQuote(hadith: "muslim:571a", cite: "Saheeh Muslim 571", arabic: 37...75, english: 6...83)
                    }

                    Section(header: ArticleHeader("AN EARLY TASLEEM")) {
                        ArticleParagraph(verbatim: "Whoever gives the tasleem before the prayer is complete, then realizes, completes what remains and prostrates after the tasleem, as the Prophet did on the day of Dhul-Yadayn:")
                        ScriptureQuote(hadith: "bukhari:482", cite: "Saheeh al-Bukhaari 482", arabic: 16...159, english: [3...14, 27...37, 183...256])
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE PROPHET FORGOT TOO")) {
                        ScriptureQuote(hadith: "bukhari:401", cite: "Saheeh al-Bukhaari 401", arabic: 64...96, english: 102...169)
                    }

                    Section(header: ArticleHeader("THREE CASES")) {
                        ArticleParagraph(articleMarkdown: "**1. Something added** (an extra bow, prostration, standing or rak‘ah): complete the prayer, give the tasleem, then prostrate twice and give the tasleem again. If you realize during an extra rak‘ah, sit at once.")
                        ArticleParagraph(articleMarkdown: "**2. Something omitted**: a pillar (ruku, sujood, al-Faatihah) must be gone back to if you have not reached its place in the next rak‘ah; otherwise that rak‘ah is void and the next stands in for it, with prostration after the tasleem. A required act such as the first tashahhud is not returned to once you have stood upright; you continue and prostrate before the tasleem.")
                        ArticleParagraph(articleMarkdown: "**3. A doubt about the count**: if one side seems more likely, act on it and prostrate after the tasleem. If neither does, build on what you are certain of, the smaller number, and prostrate before the tasleem.")
                        ArticleParagraph(verbatim: "And whoever gives the tasleem before the prayer is complete, then realizes, completes what remains and prostrates after the tasleem.")
                    }
                }

                Section(header: ArticleHeader("HOW TO PERFORM IT")) {
                    ArticleStep(verbatim: "1. Say “Allahu Akbar” and prostrate as in the prayer, saying “Subhaana Rabbi al-A‘la.”")
                    ArticleStep(verbatim: "2. Sit up with “Allahu Akbar,” then prostrate a second time.")
                    ArticleStep(verbatim: "3. If they were before the tasleem, sit and give the tasleem. If after, give the tasleem again; a second tashahhud is not required, though some scholars allow it.")
                    ArticleParagraph(verbatim: "Behind an imam, follow him: you do not prostrate for your own slip while he leads, but you prostrate with him for his, and for a slip in what you pray alone after him.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**I remembered a missed sujood as-sahw only after leaving.** If a short time has passed, prostrate where you are; if long, the prayer stands and there is nothing owed.")
                        ArticleParagraph(articleMarkdown: "**Does reciting the wrong surah or a slip of the tongue call for it?** No. It is for the actions of the prayer, not the choice of recitation, and mispronunciation is corrected when noticed.")
                        ArticleParagraph(articleMarkdown: "**What if I doubt constantly?** Persistent doubt from whispers is ignored; build on the most likely and continue. Sujood as-sahw is for real doubt, not for a habit of doubting.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Added something: prostrate twice after the tasleem. Left something or unsure: build on what is certain and prostrate twice before it. Two prostrations mend the prayer and humble Satan.")
                }

                ArticleSourcesSection(article: "SujudSahwView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "SujudSahwView")
        .navigationTitle("How to Perform Sujood as-Sahw")
    }
}

// MARK: - Fasting and charity

struct VoluntaryFastsView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: beyond Ramadan, the Prophet (peace and blessings be upon him) fasted and recommended Mondays and Thursdays, three days a month, the six days of Shawwaal, the day of Arafah, Aashoora, and much of Sha‘baan and Muharram. Each fast is intended before dawn (or, for a voluntary fast, during the day if nothing has been eaten) and observed as Ramadan is.")
                }

                Section(header: ArticleHeader("MONDAYS AND THURSDAYS")) {
                    ScriptureQuote(hadith: "tirmidhi:747", cite: "Jaami‘ at-Tirmidhi 747", arabic: 31...41, english: 5...23)
                    ArticleParagraph(verbatim: "Of Monday in particular he said:")
                    ScriptureQuote(hadith: "muslim:1162e", cite: "Saheeh Muslim 1162", arabic: 41...45, english: 0...14)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THREE DAYS A MONTH")) {
                        ArticleParagraph(verbatim: "Three days every month equal a lifetime of fasting, since each good deed is tenfold. The Prophet (peace and blessings be upon him) named the white days, the 13th, 14th and 15th, whose nights are lit by the full moon:")
                        ScriptureQuote(hadith: "nasai:2420", cite: "Sunan an-Nasaa’i 2420; graded hasan by al-Albaani", arabic: 30...46, english: 0...21)
                        ScriptureQuote(hadith: "tirmidhi:761", cite: "Jaami‘ at-Tirmidhi 761; graded hasan saheeh by al-Albaani", arabic: 35...50, english: 5...23)
                        ArticleParagraph(verbatim: "Aa’ishah said he fasted three days of every month and did not mind which days they were (Saheeh Muslim 1160).")
                        ScriptureQuote(hadith: "muslim:1160", cite: "Saheeh Muslim 1160", arabic: 23...55, english: 0...34)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THREE DAYS A MONTH")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) named the white days, the 13th, 14th and 15th, whose nights are lit by the full moon:")
                        ScriptureQuote(hadith: "nasai:2420", cite: "Sunan an-Nasaa’i 2420; graded hasan by al-Albaani", arabic: 30...46, english: 0...21)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE SIX OF SHAWWAAL")) {
                        ScriptureQuote(hadith: "muslim:1164a", cite: "Saheeh Muslim 1164", arabic: 56...66, english: 0...23)
                        ArticleParagraph(verbatim: "They may be fasted consecutively or spread through the month, after Eid al-Fitr. Those with days of Ramadan to make up should make them up first, so the “Ramadan” in the hadith is complete.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE SIX OF SHAWWAAL")) {
                        ScriptureQuote(hadith: "muslim:1164a", cite: "Saheeh Muslim 1164", arabic: 56...66, english: 0...23)
                        ArticleParagraph(verbatim: "Fast them after Eid al-Fitr, together or apart, and make up any missed days of Ramadan first.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ARAFAH AND AASHOORA")) {
                        ArticleParagraph(verbatim: "Asked about the fast of the day of Arafah (9 Dhul-Hijjah), the Prophet (peace and blessings be upon him) said it expiates the year before and the year after; and of Aashoora (10 Muharram), that it expiates the year before (Saheeh Muslim 1162). The pilgrim at Arafah does not fast; everyone else is urged to. The first ten days of Dhul-Hijjah are the best days for good deeds:")
                        ScriptureQuote(hadith: "bukhari:969", cite: "Saheeh al-Bukhaari 969", english: 4...67, arabicText: "مَا العَمَلُ فِي أَيَّامِ العَشرِ أَفضَلَ مِنَ العَمَلِ فِي هَذِهِ. قَالُوا: وَلاَ الجِهَادُ؟ قَالَ: وَلاَ الجِهَادُ، إِلاَّ رَجُلٌ خَرَجَ يُخَاطِرُ بِنَفسِهِ وَمَالِهِ فَلَم يَرجِع بِشَىءٍ")
                        ArticleParagraph(verbatim: "When the Prophet (peace and blessings be upon him) came to Madinah he found the Jews fasting Aashoora in gratitude for the day Allah saved the Children of Israel from their enemy, the day Moosa fasted. He said:")
                        ScriptureQuote(hadith: "bukhari:2004", cite: "Saheeh al-Bukhaari 2004", arabic: 59...62, english: 48...55)
                        ArticleParagraph(verbatim: "So he fasted it and commanded that it be fasted (Saheeh al-Bukhaari 2004), and toward the end of his life he intended to add the ninth to it:")
                        ScriptureQuote(hadith: "muslim:1134b", cite: "Saheeh Muslim 1134", arabic: 47...52, english: 0...14)
                    }

                    Section(header: ArticleHeader("SHA‘BAAN AND MUHARRAM")) {
                        ScriptureQuote(hadith: "bukhari:1969", cite: "Saheeh al-Bukhaari 1969", arabic: 21...57, english: 30...61)
                        ArticleParagraph(verbatim: "And the best month to fast after Ramadan is Muharram (Saheeh Muslim 1163). The fast of Daawood, every other day, is the most beloved fast to Allah (Saheeh al-Bukhaari 1131).")
                        ScriptureQuote(hadith: "muslim:1163a", cite: "Saheeh Muslim 1163", arabic: 34...46, english: 0...23)
                        ScriptureQuote(hadith: "bukhari:1131", cite: "Saheeh al-Bukhaari 1131", arabic: 42...69, english: 5...57)
                    }

                    Section(header: ArticleHeader("HOW TO OBSERVE THEM")) {
                        ArticleStep("1. **Intend** the fast. A voluntary fast may be intended in the morning if you have not yet eaten or drunk since dawn; the Prophet would ask for food and, finding none, say “then I am fasting” (Saheeh Muslim 1154).")
                        ScriptureQuote(hadith: "muslim:1154a", cite: "Saheeh Muslim 1154", arabic: 43...62, english: 0...22)
                        ArticleStep("2. **Take suhoor** if you can and break the fast at sunset, as in Ramadan.")
                        ArticleStep("3. **Refrain** from what breaks the fast and from what spoils it: argument, foul speech, and idle talk.")
                        ArticleStep("4. **You may break a voluntary fast** if a need arises, without sin; making it up is recommended, not required.")
                        ArticleStep("5. **A wife** fasts voluntarily only with her husband's permission when he is present (Saheeh al-Bukhaari 5192).")
                        ScriptureQuote(hadith: "bukhari:5192", cite: "Saheeh al-Bukhaari 5192", arabic: 24...30, english: 4...23)
                    }

                    Section(header: ArticleHeader("DAYS NOT TO FAST")) {
                        ScriptureQuote(hadith: "bukhari:1985", cite: "Saheeh al-Bukhaari 1985", arabic: 31...40, english: 6...21)
                        ArticleParagraph(verbatim: "Fasting is forbidden on the two Eids (Saheeh al-Bukhaari 1991) and on the three days of Tashreeq after Eid al-Adha:")
                        ScriptureQuote(hadith: "bukhari:1991", cite: "Saheeh al-Bukhaari 1991", arabic: 21...39, english: 0...38)
                        ScriptureQuote(hadith: "muslim:1141a", cite: "Saheeh Muslim 1141", arabic: 24...28, english: 0...10)
                        ArticleParagraph(verbatim: "Nor should one fast perpetually or wear the body down; the Prophet (peace and blessings be upon him) said to Abdullah ibn Amr that whoever fasts every day has not fasted, and guided him to the fast of Daawood (Saheeh al-Bukhaari 1979).")
                        ScriptureQuote(hadith: "bukhari:1979", cite: "Saheeh al-Bukhaari 1979", arabic: 65...98, english: 45...116)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ARAFAH AND AASHOORA")) {
                        ArticleParagraph(verbatim: "Asked about the fast of the day of Arafah (9 Dhul-Hijjah), the Prophet (peace and blessings be upon him) said it expiates the year before and the year after; and of Aashoora (10 Muharram), that it expiates the year before (Saheeh Muslim 1162). The pilgrim at Arafah does not fast; everyone else is urged to.")
                    }

                    Section(header: ArticleHeader("SHA‘BAAN AND MUHARRAM")) {
                        ScriptureQuote(hadith: "bukhari:1969", cite: "Saheeh al-Bukhaari 1969", arabic: 21...57, english: 30...61)
                        ArticleParagraph(verbatim: "And the best month to fast after Ramadan is Muharram:")
                        ScriptureQuote(hadith: "muslim:1163a", cite: "Saheeh Muslim 1163", arabic: 34...46, english: 0...23)
                    }

                    Section(header: ArticleHeader("HOW TO OBSERVE THEM")) {
                        ArticleStep("1. **Intend** the fast. A voluntary fast may be intended in the morning if you have not yet eaten or drunk since dawn.")
                        ArticleStep("2. **Take suhoor** if you can and break the fast at sunset, as in Ramadan.")
                        ArticleStep("3. **Refrain** from what breaks the fast and from what spoils it: argument, foul speech, and idle talk.")
                        ArticleStep("4. **You may break a voluntary fast** if a need arises, without sin; making it up is recommended, not required.")
                        ArticleStep("5. **A wife** fasts voluntarily only with her husband's permission when he is present.")
                    }

                    Section(header: ArticleHeader("DAYS NOT TO FAST")) {
                        ScriptureQuote(hadith: "bukhari:1985", cite: "Saheeh al-Bukhaari 1985", arabic: 31...40, english: 6...21)
                        ArticleParagraph(verbatim: "Fasting is forbidden on the two Eids and on the three days of Tashreeq after Eid al-Adha:")
                        ScriptureQuote(hadith: "bukhari:1991", cite: "Saheeh al-Bukhaari 1991", arabic: 21...39, english: 0...38)
                        ArticleParagraph(verbatim: "Nor should one fast perpetually or wear the body down.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Mondays and Thursdays, three white days a month, six of Shawwaal, Arafah, Aashoora, and much of Sha‘baan: fasts the Prophet loved, each intended and kept as Ramadan is, and each a shield and an expiation.")
                }

                ArticleSourcesSection(article: "VoluntaryFastsView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "VoluntaryFastsView")
        .navigationTitle("How to Fast Voluntary Fasts")
    }
}

struct ItikafView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **I‘tikaaf (اِعتِكَاف)** is to withdraw into a mosque and remain there for worship, leaving only for what is necessary. The Prophet (peace and blessings be upon him) observed it every year in the last ten nights of Ramadan, seeking Laylat al-Qadr, until he died.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ITS BASIS")) {
                        ScriptureQuote(quran: "2:187")
                        ScriptureQuote(hadith: "bukhari:2026", cite: "Saheeh al-Bukhaari 2026", arabic: 29...48, english: 0...31)
                        ArticleParagraph(verbatim: "He said he sought the Night of Decree by it, and told the people:")
                        ScriptureQuote(hadith: "bukhari:2017", cite: "Saheeh al-Bukhaari 2017", arabic: 30...39, english: 4...20)
                    }

                    Section(header: ArticleHeader("WHERE AND WHEN")) {
                        ArticleBullet("• **Where**: a mosque in which the congregational prayers are held, so that i‘tikaaf does not make you miss them. The three sacred mosques are the most excellent for it.")
                        ArticleBullet("• **When**: the Sunnah is the last ten nights of Ramadan. Enter the mosque before sunset on the 20th, the eve of the 21st night, and leave after sunset on the last day (or, as some of the Salaf did and Maalik preferred, stay until going out to the Eid prayer; al-Muwatta, Book of I‘tikaaf). I‘tikaaf outside Ramadan and for a shorter time is also valid.")
                        ScriptureQuote(hadith: "bukhari:2041", cite: "Saheeh al-Bukhaari 2041", arabic: 25...43, english: 0...28)
                    }

                    Section(header: ArticleHeader("HOW TO OBSERVE IT")) {
                        ArticleStep("1. **Intend** i‘tikaaf for Allah; a vowed i‘tikaaf must be completed, a voluntary one may be left.")
                        ArticleStep("2. **Set your place**: a corner or a small tent within the mosque, as the Prophet had a tent pitched for him (Saheeh al-Bukhaari 2033).")
                        ScriptureQuote(hadith: "bukhari:2033", cite: "Saheeh al-Bukhaari 2033", arabic: 19...38, english: 0...36)
                        ArticleStep("3. **Fill the time** with prayer, recitation, dhikr, dua, seeking forgiveness, and learning. Speak little of the world; sleep only what you need.")
                        ArticleStep("4. **Leave only for need**: the toilet, a ghusl, food when it cannot be brought, and for Jumuah if the mosque does not hold it. Do not visit the sick or attend funerals during it unless you had stipulated so.")
                        ArticleStep("5. **Keep away from intimacy** with a spouse; this breaks the i‘tikaaf. Visits, speaking and being served are permitted:")
                        ScriptureQuote(hadith: "bukhari:2029", cite: "Saheeh al-Bukhaari 2029", arabic: 27...50, english: 0...43)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ITS BASIS")) {
                        ScriptureQuote(hadith: "bukhari:2026", cite: "Saheeh al-Bukhaari 2026", arabic: 29...48, english: 0...31)
                        ArticleParagraph(verbatim: "He said he sought the Night of Decree by it, and told the people:")
                        ScriptureQuote(hadith: "bukhari:2017", cite: "Saheeh al-Bukhaari 2017", arabic: 30...39, english: 4...20)
                    }

                    Section(header: ArticleHeader("WHERE AND WHEN")) {
                        ArticleBullet("• **Where**: a mosque in which the congregational prayers are held, so that i‘tikaaf does not make you miss them. The three sacred mosques are the most excellent for it.")
                        ArticleBullet("• **When**: the Sunnah is the last ten nights of Ramadan. Enter the mosque before sunset on the 20th, the eve of the 21st night, and leave after sunset on the last day. I‘tikaaf outside Ramadan and for a shorter time is also valid.")
                    }

                    Section(header: ArticleHeader("HOW TO OBSERVE IT")) {
                        ArticleStep("1. **Intend** i‘tikaaf for Allah; a vowed i‘tikaaf must be completed, a voluntary one may be left.")
                        ArticleStep("2. **Set your place**: a corner or a small tent within the mosque, as the Prophet had a tent pitched for him.")
                        ArticleStep("3. **Fill the time** with prayer, recitation, dhikr, dua, seeking forgiveness, and learning. Speak little of the world; sleep only what you need.")
                        ArticleStep("4. **Leave only for need**: the toilet, a ghusl, food when it cannot be brought, and for Jumuah if the mosque does not hold it. Do not visit the sick or attend funerals during it unless you had stipulated so.")
                        ArticleStep("5. **Keep away from intimacy** with a spouse; this breaks the i‘tikaaf. Visits, speaking and being served are permitted.")
                    }
                }

                Section(header: ArticleHeader("WHAT BREAKS IT")) {
                    ArticleParagraph(verbatim: "Leaving the mosque without need, intimacy, and losing one's mind or faith. Menses and post-natal bleeding require leaving. Illness may compel leaving, after which one returns when able.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Can women do i‘tikaaf?** Yes, in the mosque, with a screened place and their guardian's leave; the Prophet's wives did so after him. A woman does not observe i‘tikaaf at home, for the Quran ties it to the mosques.")
                        ArticleParagraph(articleMarkdown: "**Can I do i‘tikaaf for one night or one day?** Yes. Whoever cannot manage ten days may observe what he can, even the odd nights, or a single night.")
                        ArticleParagraph(articleMarkdown: "**Can I use my phone?** What draws you to Allah, yes: the Quran, the adhkaar, learning. What draws you back to the world defeats the purpose; put it away.")
                        ArticleParagraph(articleMarkdown: "**Is fasting a condition?** In Ramadan it is already fasting. Outside it, many scholars, including the Hanbalis and Ibn Baaz, do not make fasting a condition (the Hanafis and Maalikees require it), though observing it fasting is better.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Withdraw into the mosque in the last ten nights, leave only for need, and give the whole of yourself to Allah in search of a night better than a thousand months.")
                }

                ArticleSourcesSection(article: "ItikafView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "ItikafView")
        .navigationTitle("How to Perform I‘tikaaf")
    }
}

struct ZakatFitrView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Zakaat al-Fitr (زَكَاة الفِطر)** is one sa' of staple food, about 2 to 3 kg depending on the food, given for every Muslim in the household before the Eid al-Fitr prayer. It purifies the fasting person from idle talk and feeds the poor on the day of Eid.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE OBLIGATION")) {
                        ScriptureQuote(hadith: "bukhari:1503", cite: "Saheeh al-Bukhaari 1503", arabic: 29...62, english: 0...46)
                        ScriptureQuote(hadith: "abudawud:1609", cite: "Sunan Abi Daawood 1609; graded hasan by al-Albaani", arabic: 47...77, english: 0...63)
                    }

                    Section(header: ArticleHeader("WHO GIVES AND FOR WHOM")) {
                        ArticleParagraph(verbatim: "Every Muslim who has food beyond his need for the day and night of Eid gives it for himself and for those he supports: wife, children, and dependents. It is not conditioned on the nisaab of the annual zakaah. It is due for a child born before sunset on the last day of Ramadan, since the hadith names the young and the old alike (Saheeh al-Bukhaari 1503). Giving for the unborn is recommended, as is reported from Uthmaan, but not obligatory.")
                    }

                    Section(header: ArticleHeader("WHAT AND HOW MUCH")) {
                        ArticleParagraph(articleMarkdown: "One **sa' (صَاع)**, the Prophet's measure of about four double handfuls, of the staple food of the land: dates, barley, wheat, raisins, rice, or the like. Abu Sa‘eed (may Allah be pleased with him) said:")
                        ScriptureQuote(hadith: "bukhari:1506", cite: "Saheeh al-Bukhaari 1506", arabic: 33...55, english: 0...32)
                        ArticleParagraph(verbatim: "A sa' is a measure of volume, so its weight depends on the food: Ibn Uthaymeen weighed it at about 2.04 kg of good wheat, and Ibn Baaz put it at about 3 kg; giving 3 kg is safe. The Sunnah is to give food itself. Some scholars allow its value in money when that benefits the poor more; the majority hold to food, as the Prophet legislated it.")
                    }

                    Section(header: ArticleHeader("WHEN")) {
                        ArticleParagraph(verbatim: "Its time is from sunset on the last day of Ramadan until the Eid prayer; the best is the morning of Eid before the prayer. It may be given a day or two earlier, as the Companions did (Saheeh al-Bukhaari 1511).")
                        ScriptureQuote(hadith: "bukhari:1511", cite: "Saheeh al-Bukhaari 1511", arabic: 93...99, english: 102...114)
                        ArticleParagraph(verbatim: "The Prophet commanded that it be given before the Eid prayer:")
                        ScriptureQuote(hadith: "bukhari:1509", cite: "Saheeh al-Bukhaari 1509", arabic: 20...33, english: 0...14)
                        ArticleParagraph(verbatim: "Delaying it past the prayer without excuse is a sin; it must still be given.")
                    }

                    Section(header: ArticleHeader("TO WHOM")) {
                        ArticleParagraph(verbatim: "To the poor and needy Muslims of your town. It may be given directly or through a trusted person or mosque who delivers it in time; one sa' may be split among several, and several sa' may be given to one.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE OBLIGATION")) {
                        ScriptureQuote(hadith: "bukhari:1503", cite: "Saheeh al-Bukhaari 1503", arabic: 29...62, english: 0...46)
                    }

                    Section(header: ArticleHeader("WHO GIVES AND FOR WHOM")) {
                        ArticleParagraph(verbatim: "Every Muslim who has food beyond his need for the day and night of Eid gives it for himself and for those he supports: wife, children, and dependents. It is not conditioned on the nisaab of the annual zakaah.")
                    }

                    Section(header: ArticleHeader("WHAT AND HOW MUCH")) {
                        ArticleParagraph(articleMarkdown: "One **sa' (صَاع)** of the staple food of the land: dates, barley, wheat, raisins, rice, or the like. A sa' is a measure of volume, so its weight depends on the food; giving 3 kg is safe. The Sunnah is to give food itself.")
                    }

                    Section(header: ArticleHeader("WHEN")) {
                        ArticleParagraph(verbatim: "From sunset on the last day of Ramadan until the Eid prayer, best on the morning of Eid; it may be given a day or two earlier. Delaying it past the prayer without excuse is a sin, and it must still be given.")
                    }

                    Section(header: ArticleHeader("TO WHOM")) {
                        ArticleParagraph(verbatim: "To the poor and needy Muslims of your town, directly or through a trusted person or mosque who delivers it in time.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("A sa' of food for every member of the house, in the hands of the poor before the Eid prayer: it seals the fast and gives everyone a share in the joy of Eid.")
                }

                ArticleSourcesSection(article: "ZakatFitrView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "ZakatFitrView")
        .navigationTitle("How to Give Zakaat al-Fitr")
    }
}

// MARK: - Eid

struct UdhiyahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: the **Udhiyah (أُضحِيَة)** is the sacrifice of a sheep, goat, cow or camel on Eid al-Adha or the three days after it, in worship of Allah alone and in remembrance of Ibraaheem (peace be upon him). It is slaughtered after the Eid prayer with “Bismillah, Allahu Akbar,” and its meat is eaten, gifted and given to the poor.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ITS BASIS")) {
                        ScriptureQuote(quran: "108:2")
                        ScriptureQuote(quran: "22:37")
                        ScriptureQuote(hadith: "bukhari:5565", cite: "Saheeh al-Bukhaari 5565", arabic: 10...26, english: 0...36)
                        ArticleParagraph(verbatim: "It is a confirmed Sunnah for every household that can afford it; some scholars hold it obligatory on the able, so whoever can should not leave it.")
                    }

                    Section(header: ArticleHeader("THE ANIMAL")) {
                        ArticleBullet("• **Kind**: a sheep or goat (for one person and his household), or a cow or camel (which seven may share).")
                        ArticleBullet("• **Age**: a sheep of at least six months, a goat of one year, a cow of two, a camel of five.")
                        ScriptureQuote(hadith: "muslim:1963", cite: "Saheeh Muslim 1963", arabic: 21...32, english: 0...28)
                        ArticleBullet("• **Free of defects**: not one-eyed, not visibly sick, not lame, and not emaciated. Al-Baraa’ ibn Aazib narrated the four the Prophet excluded (Sunan Abi Daawood 2802). Choose the best you can; it is a gift to Allah.")
                        ScriptureQuote(hadith: "abudawud:2802", cite: "Sunan Abi Daawood 2802; graded saheeh by al-Albaani", arabic: 45...62, english: 44...87)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ITS BASIS")) {
                        ScriptureQuote(quran: "108:2")
                        ArticleParagraph(verbatim: "It is a confirmed Sunnah for every household that can afford it; some scholars hold it obligatory on the able, so whoever can should not leave it.")
                    }

                    Section(header: ArticleHeader("THE ANIMAL")) {
                        ArticleBullet("• **Kind**: a sheep or goat (for one person and his household), or a cow or camel (which seven may share).")
                        ArticleBullet("• **Age**: a sheep of at least six months, a goat of one year, a cow of two, a camel of five.")
                        ArticleBullet("• **Free of defects**: not one-eyed, not visibly sick, not lame, and not emaciated. Choose the best you can; it is a gift to Allah.")
                    }
                }

                Section(header: ArticleHeader("BEFORE EID")) {
                    ArticleParagraph(verbatim: "Whoever intends to sacrifice does not cut hair or nails from the first of Dhul-Hijjah until the sacrifice:")
                    ScriptureQuote(hadith: "muslim:1977c", cite: "Saheeh Muslim 1977", arabic: 34...46, english: 0...25)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHEN")) {
                        ArticleParagraph(verbatim: "After the Eid prayer on the 10th of Dhul-Hijjah, until sunset on the 13th. Slaughtering before the prayer is not a sacrifice:")
                        ScriptureQuote(hadith: "bukhari:5545", cite: "Saheeh al-Bukhaari 5545", arabic: 28...58, english: 9...70)
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Sharpen the knife** out of the animal's sight, and treat it gently; water it and lead it kindly.")
                        ArticleStep("2. **Lay it on its left side facing the qiblah**, foot on its flank, as the Prophet did. A camel is slaughtered standing with its left foreleg tied.")
                        ArticleStep("3. **Say “Bismillah, Allahu Akbar”**, and if you wish: “O Allah, this is from You and for You, from me (and my family).”")
                        ArticleStep("4. **Cut swiftly** across the throat, severing the windpipe, gullet and the two jugulars, without severing the head, and let the animal go still before skinning.")
                        ArticleStep(verbatim: "5. It is best to slaughter with your own hand; otherwise appoint someone and be present. A woman may slaughter.")
                        ScriptureQuote(hadith: "muslim:1967", cite: "Saheeh Muslim 1967", english: [0...4, 8...12, 48...71], arabicText: "يَا عَائِشَةُ هَلُمِّي المُديَةَ اشحَذِيهَا بِحَجَرٍ بِاسمِ اللَّهِ اللَّهُمَّ تَقَبَّل مِن مُحَمَّدٍ وَآلِ مُحَمَّدٍ وَمِن أُمَّةِ مُحَمَّدٍ")
                    }

                    Section(header: ArticleHeader("THE MEAT")) {
                        ArticleParagraph(verbatim: "Eat from it, give some as gifts, and give some to the poor; a third each is a fine division, not a fixed rule. Nothing of it is sold, not even the skin, and the butcher is not paid from it. Storing beyond three days was once forbidden and then permitted:")
                        ScriptureQuote(hadith: "bukhari:5569", cite: "Saheeh al-Bukhaari 5569", arabic: 47...59, english: 42...73)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Can one sheep suffice for the whole family?** Yes. The Prophet sacrificed one ram for himself and his household and another for his ummah. Separate sacrifices per person are not required.")
                        ArticleParagraph(articleMarkdown: "**Can I have it done abroad?** It is valid to appoint a trustworthy agency to slaughter and distribute on your behalf. Slaughtering where you are, with your own hand, and eating from it is the fuller Sunnah.")
                        ArticleParagraph(articleMarkdown: "**I cannot afford it.** There is no sin. Udhiyah is for the able; the poor share in its meat.")
                        ArticleParagraph(articleMarkdown: "**Is Udhiyah the same as the pilgrim's hady?** No. The hady is the pilgrim's offering in Makkah; the Udhiyah is for the Muslims at home.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHEN")) {
                        ArticleParagraph(verbatim: "After the Eid prayer on the 10th of Dhul-Hijjah, until sunset on the 13th. Slaughtering before the prayer is not a sacrifice.")
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Sharpen the knife** out of the animal's sight, and treat it gently; water it and lead it kindly.")
                        ArticleStep("2. **Lay it on its left side facing the qiblah**, foot on its flank, as the Prophet did. A camel is slaughtered standing with its left foreleg tied.")
                        ArticleStep("3. **Say “Bismillah, Allahu Akbar”**, and if you wish: “O Allah, this is from You and for You, from me (and my family).”")
                        ArticleStep("4. **Cut swiftly** across the throat, severing the windpipe, gullet and the two jugulars, without severing the head, and let the animal go still before skinning.")
                        ArticleStep(verbatim: "5. It is best to slaughter with your own hand; otherwise appoint someone and be present. A woman may slaughter.")
                    }

                    Section(header: ArticleHeader("THE MEAT")) {
                        ArticleParagraph(verbatim: "Eat from it, give some as gifts, and give some to the poor; a third each is a fine division, not a fixed rule. Nothing of it is sold, not even the skin, and the butcher is not paid from it. Storing beyond three days was once forbidden and then permitted.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("A sound animal, after the Eid prayer, with the Name of Allah and the takbeer, eaten and shared: the Udhiyah renews the surrender of Ibraaheem and turns Eid into a feast for the poor.")
                }

                ArticleSourcesSection(article: "UdhiyahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "UdhiyahView")
        .navigationTitle("How to Offer the Eid Sacrifice")
    }
}

// MARK: - Faith and the heart

struct BecomeMuslimView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: a person becomes a Muslim by believing in the heart and saying with the tongue: “I bear witness that there is no deity except Allah, and I bear witness that Muhammad is the Messenger of Allah.” No ceremony, witness or scholar is required. Then comes a bath, the prayer, and a life lived on the two testimonies.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHAT ISLAM IS")) {
                        ScriptureQuote(quran: "3:19")
                        ScriptureQuote(quran: "3:85")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:8", cite: "Saheeh al-Bukhaari 8", arabic: 33...53, text: "“Islam is based on (the following) five (principles): To testify that none has the right to be worshipped but Allah and Muhammad is Allah's Messenger (ﷺ). To offer the (compulsory congregational) prayers dutifully and perfectly. To pay Zakaat (i.e. obligatory charity). To perform Hajj. (i.e. Pilgrimage to Mecca) To observe fast during the month of Ramadan”")
                    }
                }

                Section(header: ArticleHeader("THE TESTIMONY")) {
                    ArticleParagraph(verbatim: "Say, understanding and meaning it:")
                    ArticleArabic(verbatim: "أَشهَدُ أَن لَا إِلَٰهَ إِلَّا اللَّهُ، وَأَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ")
                    Text(verbatim: "Ash-hadu an la ilaaha illa Allah, wa ash-hadu anna Muhammadan Rasoolullah.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    ArticleParagraph(verbatim: "“I bear witness that there is no deity except Allah, and I bear witness that Muhammad is the Messenger of Allah.”")
                    ArticleCallout("Said aloud, the noon of “an” melts into the laam after it (idghaam): “an la ilaaha” is “allaa ilaaha”, and “illa Allah” runs together as “illallah”. Ashhadu allaa ilaaha illallah, wa ashhadu anna Muhammadan rasoolullah.", title: "How it is said", systemImage: "waveform")
                    ArticleParagraph(verbatim: "Its first half denies every object of worship other than Allah and affirms Him alone; its second half binds you to follow His Messenger. Saying it sincerely, knowing what it means, with no reservation, is what makes a Muslim:")
                    ScriptureQuote(hadith: "muslim:23a", cite: "Saheeh Muslim 23a", arabic: 30...47, english: 8...41)
                    ScriptureQuote(hadith: "muslim:26a", cite: "Saheeh Muslim 26a", arabic: 43...53, english: 15...29)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Believe.** Know that Allah alone is the Creator and the only One worthy of worship, that Muhammad is His final Messenger, and that the Quran is His word. Certainty is a condition of the testimony: Allah describes the believers as those who believed and then doubted not (Quran 49:15). Unanswered questions about details are no barrier to beginning; sincerity and certainty in the testimony itself are what count.")
                        ScriptureQuote(quran: "49:15", words: 6...8)
                        ArticleStep("2. **Say the Shahaadah** aloud, in Arabic and in your language. Alone is valid; before witnesses is a joy and a help, but not a condition.")
                        ArticleStep("3. **Take a bath (ghusl)**: the Prophet (peace and blessings be upon him) told Qays ibn Aasim, on his embracing Islam, to bathe (Sunan Abi Daawood 355), and Thumaamah bathed before he came to declare his Islam (Saheeh al-Bukhaari 462).")
                        ScriptureQuote(hadith: "abudawud:355", cite: "Sunan Abi Daawood 355; graded saheeh by al-Albaani", arabic: 19...31, english: 0...27)
                        ScriptureQuote(hadith: "bukhari:462", cite: "Saheeh al-Bukhaari 462", arabic: 55...75, english: 41...78)
                        ArticleStep("4. **Learn to pray**, beginning at once. The prayer is the first thing Islam asks after the testimony; learn wudu, al-Faatihah, and the movements, and pray what you know while you learn the rest.")
                        ArticleStep("5. **Learn gradually**: the pillars of faith, the halaal and haraam, the Quran. Islam was revealed over twenty-three years; the Prophet taught Mu‘aadh to begin with the testimony, then the prayer, then the zakaah (Saheeh al-Bukhaari 1395).")
                        ScriptureQuote(hadith: "bukhari:1395", cite: "Saheeh al-Bukhaari 1395, Saheeh Muslim 19a", arabic: 46...90, english: 9...98)
                        ArticleStep("6. **Find company**: a mosque, a teacher, and believing friends. Keep your name unless it carries a meaning of shirk; changing it is not required.")
                    }

                    Section(header: ArticleHeader("WHAT IT EARNS YOU")) {
                        ArticleParagraph(verbatim: "Everything before it is wiped away. Amr ibn al-As (may Allah be pleased with him), on his deathbed, recalled that when he came to give his hand in Islam he asked for his past to be forgiven, and the Prophet said:")
                        ScriptureQuote(hadith: "muslim:121", cite: "Saheeh Muslim 121", arabic: 189...208, english: 244...276)
                        ScriptureQuote(quran: "39:53")
                        ScriptureQuote(quran: "2:256")
                    }

                    Section(header: ArticleHeader("STAYING FIRM")) {
                        ArticleParagraph(verbatim: "Sufyaan ibn Abdullah asked the Prophet (peace and blessings be upon him) for a word about Islam that would need no other. He said:")
                        ScriptureQuote(hadith: "muslim:#66", cite: "Saheeh Muslim 38", arabic: 68...71, english: 42...54)
                        ArticleParagraph(verbatim: "Pray on time, keep the company of the righteous, read the Quran daily, ask when you do not know, and never despair of Allah's mercy over a slip. Faith rises and falls; the Prophet said that the strongest handhold of faith is love for Allah's sake and hate for His sake (Musnad Ahmad 18524; graded hasan by al-Albaani, Saheeh at-Targheeb 3030).")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Do I need to go to a mosque or an imam?** No. The testimony between you and Allah is complete. A certificate is useful for Hajj visas and marriage in some countries, and the mosque is where you will learn, so go, but Islam did not wait for it.")
                        ArticleParagraph(articleMarkdown: "**Do I have to tell my family?** Not as a condition. Wisdom, kindness and good character are your best witness. Honor your parents whatever their faith; Allah commands it.")
                        ArticleParagraph(articleMarkdown: "**I still have questions and doubts.** Questions are no shame: ask, read, and pray, for knowledge removes doubt. Some Companions told the Prophet of whispers they found too grave to speak of, and he said: that is clear faith (Saheeh Muslim 132). Do not delay the testimony you already believe.")
                        ScriptureQuote(hadith: "muslim:132a", cite: "Saheeh Muslim 132", arabic: 24...48, english: 0...39)
                        ArticleParagraph(articleMarkdown: "**Must I be circumcised, change my name, or learn Arabic first?** No. Circumcision is prescribed for men (obligatory according to many scholars) but is not a condition of entering Islam and may be delayed; the name stays unless its meaning is un-Islamic; Arabic comes with time, beginning with al-Faatihah.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Believe.** Know that Allah alone is the Creator and the only One worthy of worship, that Muhammad is His final Messenger, and that the Quran is His word. Unanswered questions about details are no barrier to beginning; sincerity and certainty in the testimony itself are what count.")
                        ArticleStep("2. **Say the Shahaadah** aloud, in Arabic and in your language. Alone is valid; before witnesses is a joy and a help, but not a condition.")
                        ArticleStep("3. **Take a bath (ghusl)**: the Prophet (peace and blessings be upon him) told Qays ibn Aasim, on his embracing Islam, to bathe (Sunan Abi Daawood 355).")
                        ScriptureQuote(hadith: "abudawud:355", cite: "Sunan Abi Daawood 355; graded saheeh by al-Albaani", arabic: 19...31, english: 0...27)
                        ArticleStep("4. **Learn to pray**, beginning at once. The prayer is the first thing Islam asks after the testimony; learn wudu, al-Faatihah, and the movements, and pray what you know while you learn the rest.")
                        ArticleStep("5. **Learn gradually**: the pillars of faith, the halaal and haraam, the Quran. Islam was revealed over twenty-three years.")
                        ArticleStep("6. **Find company**: a mosque, a teacher, and believing friends. Keep your name unless it carries a meaning of shirk; changing it is not required.")
                    }

                    Section(header: ArticleHeader("WHAT IT EARNS YOU")) {
                        ArticleParagraph(verbatim: "Everything before it is wiped away. Amr ibn al-As (may Allah be pleased with him), on his deathbed, recalled that when he came to give his hand in Islam he asked for his past to be forgiven, and the Prophet said:")
                        ScriptureQuote(hadith: "muslim:121", cite: "Saheeh Muslim 121", arabic: 189...208, english: 244...276)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Believe, bear witness, bathe, pray, and learn. The testimony wipes away all that came before, and the rest of Islam is walked one step at a time.")
                }

                ArticleSourcesSection(article: "BecomeMuslimView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "BecomeMuslimView")
        .navigationTitle("How to Become a Muslim")
    }
}

struct TawbahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Tawbah (تَوبَة)** is turning back to Allah from sin: stopping it, regretting it, resolving never to return, and returning what was taken from others. It is accepted so long as the soul has not reached the throat and the sun has not risen from the west, and Allah rejoices more at His servant's repentance than a man who finds his lost camel in the desert.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE DOOR IS OPEN")) {
                        ScriptureQuote(quran: "39:53")
                        ScriptureQuote(quran: "4:110")
                        ScriptureQuote(quran: "25:70")
                        ScriptureQuote(hadith: "muslim:2703", cite: "Saheeh Muslim 2703", arabic: 71...81, english: 0...26)
                        ScriptureQuote(hadith: "bukhari:6309", cite: "Saheeh al-Bukhaari 6309", arabic: 41...54, english: 4...30)
                    }

                    Section(header: ArticleHeader("THE CONDITIONS")) {
                        ArticleStep("1. **Stop the sin** at once. Repentance while continuing is a claim, not a return.")
                        ArticleStep("2. **Regret** it in the heart; regret is the heart of repentance.")
                        ArticleStep("3. **Resolve firmly** never to return to it.")
                        ArticleStep("4. **Restore what belongs to others**: return wealth, seek the pardon of the one wronged, or make good the wrong. The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:2449", cite: "Saheeh al-Bukhaari 2449", arabic: 30...68, english: 4...77)
                        ArticleStep("5. **Sincerity**: repentance for Allah's sake, not for fear of people or loss of standing.")
                        ArticleStep("6. **Before it is too late**: while the soul is in the body and before the signs of the Hour. Allah accepts the repentance of His servant until the death rattle (Jaami‘ at-Tirmidhi 3537; graded hasan by al-Albaani).")
                        ScriptureQuote(hadith: "tirmidhi:3537", cite: "Jaami‘ at-Tirmidhi 3537; graded hasan by al-Albaani", arabic: 35...42, english: 0...17)
                    }

                    Section(header: ArticleHeader("HOW TO REPENT")) {
                        ArticleBullet("• **Make wudu and pray two rak‘ah**, then ask forgiveness with the tongue and the heart (Sunan Abi Daawood 1521; graded saheeh by al-Albaani). Any time is its time.")
                        ScriptureQuote(hadith: "abudawud:1521", cite: "Sunan Abi Daawood 1521; graded saheeh by al-Albaani", arabic: 81...98, english: 76...103)
                        ArticleBullet("• **Say “Astaghfirullah”** (I seek Allah's forgiveness), and the best of it, the master supplication of forgiveness:")
                        ScriptureQuote(hadith: "bukhari:6306", cite: "Saheeh al-Bukhaari 6306", arabic: 35...75, english: 0...84)
                        ArticleBullet("• **Follow the sin with a good deed**:")
                        ScriptureQuote(hadith: "tirmidhi:1987", cite: "Jaami‘ at-Tirmidhi 1987; graded hasan by al-Albaani", arabic: 35...46, english: 7...33)
                        ArticleBullet("• **Conceal it**: a sin between you and Allah is not to be told to people. Ask His forgiveness; do not seek theirs for what they never knew.")
                        ArticleBullet("• **Leave what leads to it**: the company, the place, the habit.")
                    }

                    Section(header: ArticleHeader("IF YOU FALL AGAIN")) {
                        ArticleParagraph(verbatim: "Repent again. Returning to a sin does not cancel the earlier repentance, and the door does not shut for repeating. Allah said of a servant who sinned, repented, and sinned again:")
                        ScriptureQuote(hadith: "bukhari:7507", cite: "Saheeh al-Bukhaari 7507", arabic: 35...142, english: 143...172)
                        ArticleParagraph(verbatim: "This is for the one whose repentance each time is sincere, not for one who repents in word intending to return. The Prophet (peace and blessings be upon him) himself said:")
                        ScriptureQuote(hadith: "bukhari:6307", cite: "Saheeh al-Bukhaari 6307", arabic: 28...39, english: 6...25)
                    }

                    Section(header: ArticleHeader("THE MERCY BEHIND IT")) {
                        ScriptureQuote(hadith: "muslim:2759a", cite: "Saheeh Muslim 2759", arabic: 31...51, english: 9...73)
                        ScriptureQuote(hadith: "muslim:2749", cite: "Saheeh Muslim 2749", arabic: 29...44, english: 0...44)
                        ScriptureQuote(hadith: "tirmidhi:3540", cite: "Jaami‘ at-Tirmidhi 3540; graded saheeh by al-Albaani", arabic: 41...89, english: 8...106)
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Do I have to confess to anyone?** No. Confession is to Allah alone. The only exception is a wrong done to a person, whose right must be restored or pardoned.")
                        ArticleParagraph(articleMarkdown: "**I cannot find the person I wronged.** Return the wealth to his heirs; if that is impossible, give it in charity on his behalf and ask Allah to forgive you. For a wrong to his honor, make dua for him and speak well of him where you spoke ill.")
                        ArticleParagraph(articleMarkdown: "**Can shirk be forgiven?** Yes, by repentance in this life. What is not forgiven is dying upon it. Whoever enters Islam or returns to tawheed before death has everything before it wiped away.")
                        ArticleParagraph(articleMarkdown: "**How do I know it was accepted?** By the sign the scholars name: you are better after it than before. Have good hope in Allah, for He is as His servant thinks Him to be.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE DOOR IS OPEN")) {
                        ScriptureQuote(quran: "39:53")
                        ScriptureQuote(hadith: "muslim:2703", cite: "Saheeh Muslim 2703", arabic: 71...81, english: 0...26)
                    }

                    Section(header: ArticleHeader("THE CONDITIONS")) {
                        ArticleStep("1. **Stop the sin** at once. Repentance while continuing is a claim, not a return.")
                        ArticleStep("2. **Regret** it in the heart; regret is the heart of repentance.")
                        ArticleStep("3. **Resolve firmly** never to return to it.")
                        ArticleStep("4. **Restore what belongs to others**: return wealth, seek the pardon of the one wronged, or make good the wrong.")
                        ArticleStep("5. **Sincerity**: repentance for Allah's sake, not for fear of people or loss of standing.")
                        ArticleStep("6. **Before it is too late**: while the soul is in the body and before the signs of the Hour. Allah accepts the repentance of His servant until the death rattle (Jaami‘ at-Tirmidhi 3537; graded hasan by al-Albaani).")
                        ScriptureQuote(hadith: "tirmidhi:3537", cite: "Jaami‘ at-Tirmidhi 3537; graded hasan by al-Albaani", arabic: 35...42, english: 0...17)
                    }

                    Section(header: ArticleHeader("HOW TO REPENT")) {
                        ArticleBullet("• **Make wudu and pray two rak‘ah**, then ask forgiveness with the tongue and the heart (Sunan Abi Daawood 1521; graded saheeh by al-Albaani). Any time is its time.")
                        ScriptureQuote(hadith: "abudawud:1521", cite: "Sunan Abi Daawood 1521; graded saheeh by al-Albaani", arabic: 81...98, english: 76...103)
                        ArticleBullet("• **Say “Astaghfirullah”** (I seek Allah's forgiveness), and the best of it, the master supplication of forgiveness:")
                        ScriptureQuote(hadith: "bukhari:6306", cite: "Saheeh al-Bukhaari 6306", arabic: 35...75, english: 0...84)
                        ArticleBullet("• **Follow the sin with a good deed.**")
                        ArticleBullet("• **Conceal it**: a sin between you and Allah is not to be told to people. Ask His forgiveness; do not seek theirs for what they never knew.")
                        ArticleBullet("• **Leave what leads to it**: the company, the place, the habit.")
                    }

                    Section(header: ArticleHeader("IF YOU FALL AGAIN")) {
                        ArticleParagraph(verbatim: "Repent again. Returning to a sin does not cancel the earlier repentance, and the door does not shut for repeating. This is for the one whose repentance each time is sincere, not for one who repents in word intending to return.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Stop, regret, resolve, restore, and ask. Allah stretches out His hand every night and every day for exactly this, and He rejoices in your return.")
                }

                ArticleSourcesSection(article: "TawbahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "TawbahView")
        .navigationTitle("How to Repent")
    }
}

struct MakeDuaView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **Dua (دُعَاء)** is worship itself: calling on Allah alone, with certainty, humility, praise and persistence, at the times and in the states He loves. Every sincere dua is answered: granted, deferred to the Hereafter, or exchanged for a harm turned away.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE COMMAND AND THE PROMISE")) {
                        ScriptureQuote(quran: "2:186")
                        ScriptureQuote(quran: "40:60")
                        ScriptureQuote(hadith: "abudawud:1479", cite: "Sunan Abi Daawood 1479; graded saheeh by al-Albaani", arabic: 25...33, english: 4...9)
                        ScriptureQuote(hadith: "muslim:2735c", cite: "Saheeh Muslim 2735", english: 0...70, arabicText: "لاَ يَزَالُ يُستَجَابُ لِلعَبدِ مَا لَم يَدعُ بِإِثمٍ أَو قَطِيعَةِ رَحِمٍ مَا لَم يَستَعجِل. قِيلَ: يَا رَسُولَ اللَّهِ، مَا الاستِعجَالُ؟ قَالَ: يَقُولُ قَد دَعَوتُ وَقَد دَعَوتُ فَلَم أَرَ يَستَجِيبُ لِي فَيَستَحسِرُ عِندَ ذَلِكَ وَيَدَعُ الدُّعَاءَ")
                    }

                    Section(header: ArticleHeader("THE MANNERS OF DUA")) {
                        ArticleStep("1. **Sincerity**: ask Allah alone, with no intermediary, calling on none but Him.")
                        ArticleStep("2. **Begin with praise** of Allah and prayers upon the Prophet (peace and blessings be upon him), and end with them.")
                        ArticleStep("3. **Face the qiblah and raise the hands**, palms up, as he did at Badr and at Arafah.")
                        ScriptureQuote(hadith: "abudawud:1488", cite: "Sunan Abi Daawood 1488; graded saheeh by al-Albaani", arabic: 36...51, english: 4...27)
                        ArticleStep("4. **Ask with certainty**, resolutely, and lower your voice:")
                        ScriptureQuote(hadith: "bukhari:6339", cite: "Saheeh al-Bukhaari 6339", arabic: 30...45, english: 4...44)
                        ArticleStep("5. **Repeat** your request, three times as the Prophet did, and be persistent over the days.")
                        ArticleStep("6. **Ask for everything**, the great and the small, for yourself, your parents and the believers, and for the Hereafter above the world.")
                        ArticleStep("7. **Use the Names of Allah** suited to your need, and the Prophet's own words where you know them.")
                        ArticleStep("8. **Keep your earnings and food lawful**; a body fed on the unlawful is slow to be answered:")
                        ScriptureQuote(hadith: "muslim:1015", cite: "Saheeh Muslim 1015", arabic: 32...101, english: [0...13, 65...124])
                    }

                    Section(header: ArticleHeader("THE TIMES OF ANSWER")) {
                        ArticleBullet("• **The last third of the night**, when Allah descends and asks who is calling on Him (Saheeh al-Bukhaari 1145).")
                        ScriptureQuote(hadith: "bukhari:1145", cite: "Saheeh al-Bukhaari 1145", arabic: 35...60, english: 5...68)
                        ArticleBullet("• **In prostration**:")
                        ScriptureQuote(hadith: "muslim:482", cite: "Saheeh Muslim 482", arabic: 45...54, english: 6...25)
                        ArticleBullet("• **Between the adhan and the iqaamah**:")
                        ScriptureQuote(hadith: "abudawud:521", cite: "Sunan Abi Daawood 521; graded saheeh by al-Albaani", arabic: 26...31, english: 0...11)
                        ArticleBullet("• **After the tashahhud before the tasleem**, and after the obligatory prayers.")
                        ArticleBullet("• **An hour on Friday**, which the scholars place at the end of the day before Maghrib or between the khutbah and the prayer (Saheeh al-Bukhaari 935).")
                        ScriptureQuote(hadith: "bukhari:935", cite: "Saheeh al-Bukhaari 935", arabic: 28...43, english: 9...36)
                        ArticleBullet("• **When traveling, when oppressed, and a father for his child**:")
                        ScriptureQuote(hadith: "tirmidhi:1905", cite: "Jaami‘ at-Tirmidhi 1905; graded hasan by al-Albaani", arabic: 32...45, english: 0...32)
                        ArticleBullet("• **On the day of Arafah, in Ramadan, and in Laylat al-Qadr**, and at Zamzam for the pilgrim.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE COMMAND AND THE PROMISE")) {
                        ScriptureQuote(quran: "2:186")
                        ScriptureQuote(hadith: "abudawud:1479", cite: "Sunan Abi Daawood 1479; graded saheeh by al-Albaani", arabic: 25...33, english: 4...9)
                    }

                    Section(header: ArticleHeader("THE MANNERS OF DUA")) {
                        ArticleStep("1. **Sincerity**: ask Allah alone, with no intermediary, calling on none but Him.")
                        ArticleStep("2. **Begin with praise** of Allah and prayers upon the Prophet (peace and blessings be upon him), and end with them.")
                        ArticleStep("3. **Face the qiblah and raise the hands**, palms up, as he did at Badr and at Arafah.")
                        ArticleStep("4. **Ask with certainty**, resolutely, and lower your voice.")
                        ArticleStep("5. **Repeat** your request, three times as the Prophet did, and be persistent over the days.")
                        ArticleStep("6. **Ask for everything**, the great and the small, for yourself, your parents and the believers, and for the Hereafter above the world.")
                        ArticleStep("7. **Use the Names of Allah** suited to your need, and the Prophet's own words where you know them.")
                        ArticleStep("8. **Keep your earnings and food lawful**; a body fed on the unlawful is slow to be answered.")
                    }

                    Section(header: ArticleHeader("THE TIMES OF ANSWER")) {
                        ArticleBullet("• **The last third of the night.**")
                        ArticleBullet("• **In prostration**:")
                        ScriptureQuote(hadith: "muslim:482", cite: "Saheeh Muslim 482", arabic: 45...54, english: 6...25)
                        ArticleBullet("• **Between the adhan and the iqaamah.**")
                        ArticleBullet("• **After the tashahhud before the tasleem**, and after the obligatory prayers.")
                        ArticleBullet("• **An hour on Friday**, which the scholars place at the end of the day before Maghrib or between the khutbah and the prayer.")
                        ArticleBullet("• **When traveling, when oppressed, and a father for his child.**")
                        ArticleBullet("• **On the day of Arafah, in Ramadan, and in Laylat al-Qadr**, and at Zamzam for the pilgrim.")
                    }
                }

                Section(header: ArticleHeader("WHAT TO AVOID")) {
                    ArticleBullet(verbatim: "• Asking for a sin, or against family ties.")
                    ArticleBullet(verbatim: "• Giving up: “I asked and was not answered.”")
                    ArticleBullet(verbatim: "• Asking through the dead or the absent; dua is directed to Allah alone, and the living may be asked to pray for you.")
                    ArticleBullet(verbatim: "• Hurried, distracted asking with a heedless heart; gather the heart before the tongue speaks.")
                    ArticleBullet(verbatim: "• Rhyming and affectation in wording, and raising the voice unduly; Allah is near.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE THREE ANSWERS")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) taught that no Muslim makes a dua free of sin and the cutting of ties except that Allah gives him one of three: his request soon, or its storing for the Hereafter, or the turning away of an equal harm (Musnad Ahmad 11133; al-Adab al-Mufrad 710; graded saheeh by al-Albaani, Saheeh al-Adab al-Mufrad 547). Whoever understands this never counts a dua unanswered.")
                        ScriptureQuote(hadith: "bukhari:7405", cite: "Saheeh al-Bukhaari 7405", arabic: 28...74, english: 4...39)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Praise Him, send prayers on His Prophet, raise your hands, ask with certainty and persistence at the hours He loves, and know that no sincere call to Allah is ever lost.")
                }

                ArticleSourcesSection(article: "MakeDuaView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "MakeDuaView")
        .navigationTitle("How to Make Dua")
    }
}

// MARK: - Ruqyah

/// Ruqyah as the Sunnah teaches it (Abu, 2026-10-27: "Add how to do ruqya. Make sure salafi Sunni
/// based"): the Quran and the authentic supplications recited over oneself or another, by anyone,
/// with the heart on Allah alone; the evil eye and magic; and what the scholars of the Sunnah (Ibn
/// Baz, Ibn al-Uthaymin, the Standing Committee, al-Albani) warned against: amulets, fortune-tellers,
/// jinn talk, harm and seclusion. The supplications are `GuideDuaRow`s, so each one can be heard and
/// copied as on the Dua screen.
struct RuqyahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: **ruqyah (رُقيَة)** is reciting the Quran and the Prophet's supplications over someone who is ill or afflicted, yourself first of all, and asking Allah alone for the cure. It is Sunnah when its words are Allah's words, His names or the authentic supplications, understood, and free of shirk, with the heart certain that only Allah cures. It needs no specialist, no amulet and no conversation with the jinn, and it goes hand in hand with medicine.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHAT IT IS")) {
                        ArticleParagraph(verbatim: "The Quran was sent down as a healing:")
                        ScriptureQuote(quran: "17:82")
                        ScriptureQuote(quran: "10:57")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) recited ruqyah over himself and his family, Jibreel recited it over him, and he approved the ruqyah of others once he had heard it:")
                        ScriptureQuote(hadith: "muslim:2200", cite: "Saheeh Muslim 2200", arabic: 23...48, english: 0...32)
                        ArticleParagraph(verbatim: "The one who cures is Allah. Ibraaheem (peace be upon him) said it plainly:")
                        ScriptureQuote(quran: "26:80")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHAT IT IS")) {
                        ArticleParagraph(verbatim: "The Quran was sent down as a healing:")
                        ScriptureQuote(quran: "17:82")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) recited ruqyah over himself and his family, Jibreel recited it over him, and he approved the ruqyah of others once he had heard it:")
                        ScriptureQuote(hadith: "muslim:2200", cite: "Saheeh Muslim 2200", arabic: 23...48, english: 0...32)
                        ArticleParagraph(verbatim: "The one who cures is Allah. Ibraaheem (peace be upon him) said it plainly:")
                        ScriptureQuote(quran: "26:80")
                    }
                }

                Section(header: ArticleHeader("ITS CONDITIONS")) {
                    ArticleParagraph(verbatim: "Ibn Hajar reported that the scholars agree ruqyah is permitted when three conditions are met (Fath al-Baari):")
                    ArticleStep("1. **Its words are Allah's words, or His names and attributes**, or the supplications the Prophet taught.")
                    ArticleStep("2. **It is in Arabic, or in words whose meaning is understood.** Mumbled syllables, unknown names and secret letters are not ruqyah: what cannot be understood cannot be trusted to be free of shirk.")
                    ArticleStep("3. **The heart holds that the ruqyah does nothing by itself.** It is a means, and the cure comes by Allah's decree alone.")
                    ArticleParagraph(verbatim: "So the heart leans on Allah, not on the words, the water or the person reciting.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("DO YOUR OWN FIRST")) {
                        ArticleParagraph(verbatim: "Anyone can recite ruqyah: over yourself, your children, your parents, your spouse. You do not need a specialist, and the best ruqyah is the one you recite yourself. Among those who enter Paradise without reckoning are those who do not ask others for it:")
                        ScriptureQuote(hadith: "bukhari:6472", cite: "Saheeh al-Bukhaari 6472", arabic: 35...51, english: 4...39)
                        ArticleParagraph(verbatim: "Ibn Taymiyyah explained that what they leave is the asking, not the ruqyah. Reciting over yourself and over others was the Prophet's own practice and is a kindness, and asking a righteous person to recite over you is permitted; leaving the asking and reciting yourself is the higher station.")
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Turn to Allah.** Renew your trust in Him, make wudu if you can (it is better, not required), and sit somewhere calm.")
                        ArticleStep("2. **Put your hand on the place of pain**, say “Bismillah” three times, and then seven times “A‘oodhu billahi wa qudratihi min sharri ma ajidu wa uhaadhir”:")
                        ScriptureQuote(hadith: "muslim:2202", cite: "Saheeh Muslim 2202", arabic: 53...76, english: 0...54)
                        ArticleStep("3. **Recite al-Faatihah**, then blow lightly: a breath with a trace of moisture. A Companion recited it over a chief stung by a scorpion:")
                        ScriptureQuote(hadith: "bukhari:5749", cite: "Saheeh al-Bukhaari 5749", arabic: 112...129, english: 191...224)
                        ScriptureQuote(hadith: "bukhari:5749", cite: "Saheeh al-Bukhaari 5749", arabic: 159...175, english: 280...310)
                        ArticleStep("4. **Recite Aayat al-Kursi** (2:255) and **the last two aayaat of al-Baqarah** (2:285-286), and any other aayaat you wish; all of the Quran is healing.")
                        ScriptureQuote(quran: "2:255")
                        ScriptureQuote(quran: "2:285-286")
                        ArticleStep("5. **Recite al-Ikhlaas, al-Falaq and an-Naas**, blow into your cupped hands, and wipe them over as much of your body as you can reach, beginning with the head and face. Do it three times. The Prophet did this every night (Saheeh al-Bukhaari 5017), and in his last illness:")
                        ScriptureQuote(hadith: "bukhari:5017", cite: "Saheeh al-Bukhaari 5017", arabic: 21...66, english: 0...61)
                        ScriptureQuote(hadith: "bukhari:5735", cite: "Saheeh al-Bukhaari 5735", arabic: 25...44, english: 0...55)
                        ArticleStep("6. **Say the Prophet's supplications for healing**, below, with your right hand on the place of pain.")
                        ArticleStep("7. **Repeat it** as long as the need lasts, morning and evening or whenever the pain returns, without counts or schedules the Sunnah did not set. Take your medicine too, and leave the outcome with Allah.")
                        ArticleParagraph(verbatim: "Over someone else it is the same: your hand on the place of pain, the recitation, and a light breath. A man recites over a woman only if she is his mahram, or with her mahram present and without touching her.")
                    }

                    Section(header: ArticleHeader("THE PROPHET'S SUPPLICATIONS FOR HEALING")) {
                        GuideDuaRow(DuaItem(
                            hadith: "bukhari:5743", cite: "Saheeh al-Bukhaari 5743", arabic: 37...52, english: 24...57,
                            transliteration: "Allahumma Rabban-naas, adhhibil-baa’s, ishfihi wa antash-Shaafi, la shifaa’a illa shifaa’uk, shifaa’an la yughaadiru saqama.",
                            note: "With the right hand over the place of pain"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2186", cite: "Saheeh Muslim 2186", arabic: 38...56, english: 12...52,
                            transliteration: "Bismillahi arqeek, min kulli shay’in yu’dheek, min sharri kulli nafsin aw ‘ayni haasid, Allahu yashfeek, bismillahi arqeek.",
                            note: "Jibreel's ruqyah over the Prophet"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "abudawud:3106", cite: "Sunan Abi Daawood 3106; graded saheeh by al-Albaani", arabic: 40...47, english: 22...35,
                            transliteration: "As’alullahal-‘Azeem, Rabbal-‘Arshil-‘Azeem, an yashfiyak.",
                            note: "Seven times, beside someone who is ill"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "bukhari:5745", cite: "Saheeh al-Bukhaari 5745", arabic: 33...42, english: 9...28,
                            transliteration: "Bismillah, turbatu ardina, bi-reeqati ba‘dina, yushfa saqeemuna, bi-idhni Rabbina.",
                            note: "For a wound or sore: a little saliva on the forefinger, touched to the earth, then to the place"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "bukhari:3371", cite: "Saheeh al-Bukhaari 3371", arabic: 43...54, english: 33...55,
                            transliteration: "A‘oodhu bi-kalimaatillahit-taammah, min kulli shaytaanin wa haammah, wa min kulli ‘aynin lammah.",
                            note: "Said over children, as he said it over al-Hasan and al-Husayn"
                        ))
                        ArticleParagraph(verbatim: "Over yourself, the scholars allowed “ishfini” (heal me) in place of “ishfihi” (heal him) in the first; Anas's wording of it, “ishfi”, names no one at all (Saheeh al-Bukhaari 5742). Aa’ishah described the finger and the earth of the fourth in Saheeh Muslim 2194.")
                        ScriptureQuote(hadith: "bukhari:5742", cite: "Saheeh al-Bukhaari 5742", arabic: 38...53, english: 36...70)
                        ScriptureQuote(hadith: "muslim:2194", cite: "Saheeh Muslim 2194", arabic: 37...74, english: 0...28)
                    }

                    Section(header: ArticleHeader("THE EVIL EYE")) {
                        ArticleParagraph(verbatim: "The eye is real: harm that comes, by Allah's leave, from a look of envy, or of admiration that forgets Allah. Ibn Katheer took this ayah as evidence for it:")
                        ScriptureQuote(quran: "68:51", words: 0...5)
                        ScriptureQuote(hadith: "muslim:2188", cite: "Saheeh Muslim 2188", arabic: 43...54, english: 0...45)
                        ArticleParagraph(verbatim: "Its cure is ruqyah, which he commanded for it:")
                        ScriptureQuote(hadith: "bukhari:5739", cite: "Saheeh al-Bukhaari 5739", arabic: 55...59, english: 18...32)
                        ArticleParagraph(verbatim: "When the one who gave the eye is known, he is asked to wash, and the water is poured over the one he struck:")
                        ScriptureQuote(hadith: "ibnmajah:3509", cite: "Sunan Ibn Maajah 3509; graded saheeh by al-Albaani", arabic: 16...101, english: 0...126)
                        ArticleParagraph(verbatim: "Prevent it with a blessing. When something of yours or someone else's pleases you, say “Baarakallahu feeh” (may Allah bless it), or “Ma sha' Allah, la quwwata illa billah”, as the believer told his companion in the garden:")
                        ScriptureQuote(quran: "18:39", words: 0...11)
                        ArticleParagraph(verbatim: "And do not accuse people. Suspicion without proof breaks ties that no ruqyah repairs; if you suspect someone, you may ask them kindly to wash, and say nothing more.")
                        ArticleParagraph(verbatim: "Guarding against the eye, what to say when something pleases you, and the washing step by step have their own guide:")
                        ArticleDoorRow(door: .article("EvilEyeGuideView"))
                    }

                    Section(header: ArticleHeader("MAGIC (SIHR)")) {
                        ArticleParagraph(verbatim: "Magic is real, and practising it is kufr, yet it harms no one except by Allah's permission:")
                        ScriptureQuote(quran: "2:102", words: 42...50)
                        ArticleParagraph(verbatim: "The Prophet himself was affected by magic, and Allah cured him and showed him where it had been hidden; the well was then filled in (Saheeh al-Bukhaari 5763).")
                        ScriptureQuote(hadith: "bukhari:5763", cite: "Saheeh al-Bukhaari 5763", arabic: 155...168, english: 243...268)
                        ArticleParagraph(verbatim: "Its treatment is the same ruqyah, with patience and trust:")
                        ArticleStep("1. **Recite the ruqyah above**, with al-Faatihah, Aayat al-Kursi, al-Falaq and an-Naas, often.")
                        ArticleStep("2. **Recite the aayaat in which Allah undoes the magicians' work**: al-A‘raaf 7:117-119, Yoonus 10:79-82 and Ta Ha 20:65-69. Ibn Baaz described reciting them, with Aayat al-Kursi and the surahs of refuge, into water with crushed lote-tree (sidr) leaves, then drinking some of it and washing with the rest.")
                        ScriptureQuote(quran: "7:117-119")
                        ScriptureQuote(quran: "10:81-82")
                        ScriptureQuote(quran: "20:68-69")
                        ArticleStep("3. **If the object of the magic is found**, destroy it, reciting as you do.")
                        ArticleStep("4. **Never undo magic with magic.** Going to a magician to lift it is forbidden, whatever is promised:")
                        ScriptureQuote(hadith: "abudawud:3868", cite: "Sunan Abi Daawood 3868; graded saheeh by al-Albaani", arabic: 23...38, english: 0...25)
                        ArticleParagraph(verbatim: "And for protection, the Prophet named seven ‘ajwah dates in the morning:")
                        ScriptureQuote(hadith: "bukhari:5445", cite: "Saheeh al-Bukhaari 5445", arabic: 27...41, english: 4...25)
                    }

                    Section(header: ArticleHeader("WATER, OIL AND HONEY")) {
                        ArticleParagraph(verbatim: "Reciting into water or olive oil, then drinking it or wiping with it, was permitted by Ibn Baaz and the Standing Committee and done by some of the Salaf. Reciting directly over the person and blowing is better, as the Sunnah shows. Blowing into water to take the reciter's own blessing, rather than the Quran's, is forbidden.")
                        ArticleParagraph(verbatim: "Take the cures the Sunnah names as well. Honey:")
                        ScriptureQuote(quran: "16:69", words: 9...17)
                        ArticleParagraph(verbatim: "And the black seed:")
                        ScriptureQuote(hadith: "bukhari:5688", cite: "Saheeh al-Bukhaari 5688", arabic: 33...41, english: 6...16)
                    }

                    Section(header: ArticleHeader("PROTECTION BEFORE AFFLICTION")) {
                        ArticleParagraph(verbatim: "The strongest ruqyah is the one recited before anything happens: the morning and evening remembrances.")
                        ScriptureQuote(hadith: "abudawud:5082", cite: "Sunan Abi Daawood 5082; graded hasan by al-Albaani", arabic: 84...99, english: 72...93)
                        GuideDuaRow(DuaItem(
                            hadith: "abudawud:5088", cite: "Sunan Abi Daawood 5088; graded saheeh by al-Albaani", arabic: 34...49, english: 25...50,
                            transliteration: "Bismillahil-ladhi la yadurru ma‘a ismihi shay’un fil-ardi wa la fis-samaa’i wa huwas-Samee‘ul-‘Aleem",
                            note: "Three times, morning and evening"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2708a", cite: "Saheeh Muslim 2708", arabic: 63...70, english: 16...32,
                            transliteration: "A‘oodhu bikalimaatillahit-taammaati min sharri ma khalaq",
                            note: "When stopping at a place; nothing will harm you until you move on"
                        ))
                        ArticleParagraph(verbatim: "Recite Aayat al-Kursi when you lie down to sleep: a guardian from Allah stays with you until morning (Saheeh al-Bukhaari 2311).")
                        ScriptureQuote(hadith: "bukhari:2311", cite: "Saheeh al-Bukhaari 2311", arabic: 271...321, english: [419...471, 489...503])
                        ArticleParagraph(verbatim: "And the last two aayaat of al-Baqarah at night:")
                        ScriptureQuote(hadith: "bukhari:5009", cite: "Saheeh al-Bukhaari 5009", arabic: 31...40, english: 4...21)
                    }

                    Section(header: ArticleHeader("WHAT TO AVOID")) {
                        ArticleBullet("• **Amulets and charms**, whatever is written in them. The Prophet said that whoever hangs an amulet has committed shirk (Musnad Ahmad 17422; graded saheeh by al-Albaani), and:")
                        ScriptureQuote(hadith: "abudawud:3883", cite: "Sunan Abi Daawood 3883; graded saheeh by al-Albaani", arabic: 42...46, english: 19...24)
                        ArticleParagraph(verbatim: "The ruqyah meant there is the kind with shirk in it; the same narration ends with Ibn Mas‘ood teaching his wife the Prophet's own ruqyah instead. Amulets of Quran are left too. The Salaf differed over them: some allowed them, and Ibn Mas‘ood and his companions disliked them all. Ibn Baaz and the Standing Committee held that view correct, because the hadiths that forbid amulets are general and to close the door to the rest, and Ibn al-Uthaymeen said they are not to be hung. The Quran was sent down to be recited.")
                        ArticleBullet("• **Fortune-tellers and “healers”** who ask for your mother's name, write numbers and squares, tell you who did it, read cups or palms, or ask for an animal slaughtered in a certain way. Going to them is a sin, and believing them is worse:")
                        ScriptureQuote(hadith: "muslim:2230", cite: "Saheeh Muslim 2230", arabic: 36...47, english: 0...20)
                        ArticleBullet("• **Talking with the jinn**, taking their word, or accusing a relative because a jinn named them. The jinn lie, and the Sunnah never made them witnesses.")
                        ArticleBullet("• **Harming the patient**: beating, choking, shouting into the ear, electric shocks. None of it is from the Sunnah.")
                        ArticleBullet("• **Seclusion with a woman, or touching her**, in the name of treatment:")
                        ScriptureQuote(hadith: "bukhari:5233", cite: "Saheeh al-Bukhaari 5233", arabic: 23...30, english: 4...20)
                        ArticleBullet("• **Leaving medicine.** Treatment does not contradict trust in Allah; the Prophet commanded it:")
                        ScriptureQuote(hadith: "abudawud:3855", cite: "Sunan Abi Daawood 3855; graded saheeh by al-Albaani", arabic: 38...60, english: 33...73)
                        ArticleBullet("• **Blaming everything on the eye, magic or the jinn.** Illness, sadness, anxiety and failure have ordinary causes too, and doctors and counsellors treat them. Recite ruqyah, and see the doctor.")
                        ArticleBullet("• **Invented counts and schedules**: a surah forty-one times at a set hour, ruqyah “programs”, rituals the Sunnah never taught. What is fixed is fixed by revelation, and adding to it is innovation.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Do I need a raaqi?** No. Your own ruqyah is the Sunnah and the best of it. If you ask someone, choose a person of sound belief and practice who recites the Quran and the authentic supplications, and stays away from everything above.")
                        ArticleParagraph(articleMarkdown: "**Can a woman recite ruqyah?** Yes: over herself, her children, other women and her mahrams. Aa’ishah recited it over the Prophet in his last illness, as above.")
                        ArticleParagraph(articleMarkdown: "**And during her period?** The supplications are always open to her. Reciting the aayaat from memory during her period is permitted in the view of Ibn Taymiyyah and Ibn al-Uthaymeen, above all for a need like this.")
                        ArticleParagraph(articleMarkdown: "**Can I recite over a non-Muslim?** Yes. The chief the Companions recited al-Faatihah over was not a Muslim.")
                        ArticleParagraph(articleMarkdown: "**May the one who recites take payment?** Yes, the Prophet allowed it, though the scholars warned against making it a trade with fixed prices and promises of cure:")
                        ScriptureQuote(hadith: "bukhari:5737", cite: "Saheeh al-Bukhaari 5737", arabic: 111...118, english: 142...155)
                        ArticleParagraph(articleMarkdown: "**Does playing a recording count?** Listening to the Quran brings calm and reward, but a recording is not ruqyah, which is recited with intention and breath by someone present. Ibn al-Uthaymeen said the same of a recording of al-Baqarah played in a home.")
                        ArticleParagraph(articleMarkdown: "**How do I know whether it is the eye, magic or the jinn?** You do not need to. The treatment is the same: ruqyah, the morning and evening remembrances, the prayer, medicine and patience. Chasing a diagnosis is how people end up at the fortune-teller's door.")
                    }

                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleTermCard("Ruqyah", arabic: "رُقْيَة", meaning: "Recitation over the sick or afflicted, seeking cure from Allah. With the Quran and the authentic supplications it is Sunnah; with shirk or unknown words it is forbidden.")
                        ArticleTermCard("Nafth", arabic: "نَفْث", meaning: "Light blowing with a trace of moisture after reciting, over the person or into the hands: more than a breath, less than spitting.")
                        ArticleTermCard("Al-'ayn", arabic: "العَيْن", meaning: "The evil eye: harm that strikes, by Allah's leave, from a look of envy, or of admiration that does not remember Allah.")
                        ArticleTermCard("Sihr", arabic: "السِّحْر", meaning: "Magic: real, learned from the devils, and kufr to practise. It harms no one except by Allah's permission.")
                        ArticleTermCard("Tameemah", arabic: "تَمِيمَة", meaning: "An amulet or charm hung or worn for protection. Shirk when it is relied on. The Salaf differed over one made only of Quran; the sounder view is that it is not hung either.")
                        ArticleTermCard("Nushrah", arabic: "نُشْرَة", meaning: "Undoing magic. With ruqyah and lawful medicine it is allowed; with magic it is the work of the devil.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("DO YOUR OWN FIRST")) {
                        ArticleParagraph(verbatim: "Anyone can recite ruqyah: over yourself, your children, your parents, your spouse. You do not need a specialist, and the best ruqyah is the one you recite yourself.")
                    }

                    Section(header: ArticleHeader("STEP BY STEP")) {
                        ArticleStep("1. **Turn to Allah.** Renew your trust in Him, make wudu if you can (it is better, not required), and sit somewhere calm.")
                        ArticleStep("2. **Put your hand on the place of pain**, say “Bismillah” three times, and then seven times “A‘oodhu billahi wa qudratihi min sharri ma ajidu wa uhaadhir”:")
                        ScriptureQuote(hadith: "muslim:2202", cite: "Saheeh Muslim 2202", arabic: 53...76, english: 0...54)
                        ArticleStep("3. **Recite al-Faatihah**, then blow lightly: a breath with a trace of moisture. A Companion recited it over a chief stung by a scorpion:")
                        ScriptureQuote(hadith: "bukhari:5749", cite: "Saheeh al-Bukhaari 5749", arabic: 112...129, english: 191...224)
                        ArticleStep("4. **Recite Aayat al-Kursi** and **the last two aayaat of al-Baqarah**, and any other aayaat you wish; all of the Quran is healing.")
                        ArticleStep("5. **Recite al-Ikhlaas, al-Falaq and an-Naas**, blow into your cupped hands, and wipe them over as much of your body as you can reach, beginning with the head and face. Do it three times. The Prophet did this every night (Saheeh al-Bukhaari 5017):")
                        ScriptureQuote(hadith: "bukhari:5017", cite: "Saheeh al-Bukhaari 5017", arabic: 21...66, english: 0...61)
                        ArticleStep("6. **Say the Prophet's supplications for healing**, below, with your right hand on the place of pain.")
                        ArticleStep("7. **Repeat it** as long as the need lasts, morning and evening or whenever the pain returns, without counts or schedules the Sunnah did not set. Take your medicine too, and leave the outcome with Allah.")
                        ArticleParagraph(verbatim: "Over someone else it is the same: your hand on the place of pain, the recitation, and a light breath. A man recites over a woman only if she is his mahram, or with her mahram present and without touching her.")
                    }

                    Section(header: ArticleHeader("THE PROPHET'S SUPPLICATIONS FOR HEALING")) {
                        GuideDuaRow(DuaItem(
                            hadith: "bukhari:5743", cite: "Saheeh al-Bukhaari 5743", arabic: 37...52, english: 24...57,
                            transliteration: "Allahumma Rabban-naas, adhhibil-baa’s, ishfihi wa antash-Shaafi, la shifaa’a illa shifaa’uk, shifaa’an la yughaadiru saqama.",
                            note: "With the right hand over the place of pain"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2186", cite: "Saheeh Muslim 2186", arabic: 38...56, english: 12...52,
                            transliteration: "Bismillahi arqeek, min kulli shay’in yu’dheek, min sharri kulli nafsin aw ‘ayni haasid, Allahu yashfeek, bismillahi arqeek.",
                            note: "Jibreel's ruqyah over the Prophet"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "abudawud:3106", cite: "Sunan Abi Daawood 3106; graded saheeh by al-Albaani", arabic: 40...47, english: 22...35,
                            transliteration: "As’alullahal-‘Azeem, Rabbal-‘Arshil-‘Azeem, an yashfiyak.",
                            note: "Seven times, beside someone who is ill"
                        ))
                    }

                    Section(header: ArticleHeader("THE EVIL EYE")) {
                        ArticleParagraph(verbatim: "The eye is real: harm that comes, by Allah's leave, from a look of envy, or of admiration that forgets Allah.")
                        ScriptureQuote(hadith: "muslim:2188", cite: "Saheeh Muslim 2188", arabic: 43...54, english: 0...45)
                        ArticleParagraph(verbatim: "Its cure is ruqyah, which he commanded for it:")
                        ScriptureQuote(hadith: "bukhari:5739", cite: "Saheeh al-Bukhaari 5739", arabic: 55...59, english: 18...32)
                        ArticleParagraph(verbatim: "When the one who gave the eye is known, he is asked to wash, and the water is poured over the one he struck. Prevent it with a blessing: when something of yours or someone else's pleases you, say “Baarakallahu feeh” (may Allah bless it). And do not accuse people.")
                        ArticleParagraph(verbatim: "Guarding against the eye, what to say when something pleases you, and the washing step by step have their own guide:")
                        ArticleDoorRow(door: .article("EvilEyeGuideView"))
                    }

                    Section(header: ArticleHeader("MAGIC (SIHR)")) {
                        ArticleParagraph(verbatim: "Magic is real, and practising it is kufr, yet it harms no one except by Allah's permission. Its treatment is the same ruqyah, with patience and trust:")
                        ArticleStep("1. **Recite the ruqyah above**, with al-Faatihah, Aayat al-Kursi, al-Falaq and an-Naas, often.")
                        ArticleStep("2. **Recite the aayaat in which Allah undoes the magicians' work**: al-A‘raaf 7:117-119, and their like in Yoonus and Ta Ha.")
                        ScriptureQuote(quran: "7:117-119")
                        ArticleStep("3. **If the object of the magic is found**, destroy it, reciting as you do.")
                        ArticleStep("4. **Never undo magic with magic.** Going to a magician to lift it is forbidden, whatever is promised:")
                        ScriptureQuote(hadith: "abudawud:3868", cite: "Sunan Abi Daawood 3868; graded saheeh by al-Albaani", arabic: 23...38, english: 0...25)
                    }

                    Section(header: ArticleHeader("PROTECTION BEFORE AFFLICTION")) {
                        ArticleParagraph(verbatim: "The strongest ruqyah is the one recited before anything happens: the morning and evening remembrances.")
                        ScriptureQuote(hadith: "abudawud:5082", cite: "Sunan Abi Daawood 5082; graded hasan by al-Albaani", arabic: 84...99, english: 72...93)
                        GuideDuaRow(DuaItem(
                            hadith: "abudawud:5088", cite: "Sunan Abi Daawood 5088; graded saheeh by al-Albaani", arabic: 34...49, english: 25...50,
                            transliteration: "Bismillahil-ladhi la yadurru ma‘a ismihi shay’un fil-ardi wa la fis-samaa’i wa huwas-Samee‘ul-‘Aleem",
                            note: "Three times, morning and evening"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2708a", cite: "Saheeh Muslim 2708", arabic: 63...70, english: 16...32,
                            transliteration: "A‘oodhu bikalimaatillahit-taammaati min sharri ma khalaq",
                            note: "When stopping at a place; nothing will harm you until you move on"
                        ))
                        ArticleParagraph(verbatim: "And recite Aayat al-Kursi when you lie down to sleep, and the last two aayaat of al-Baqarah at night.")
                    }

                    Section(header: ArticleHeader("WHAT TO AVOID")) {
                        ArticleBullet("• **Amulets and charms**, whatever is written in them. The Prophet said:")
                        ScriptureQuote(hadith: "abudawud:3883", cite: "Sunan Abi Daawood 3883; graded saheeh by al-Albaani", arabic: 42...46, english: 19...24)
                        ArticleParagraph(verbatim: "The ruqyah meant there is the kind with shirk in it. Amulets of Quran are left too: the Salaf differed over them, and Ibn Baaz and the Standing Committee held that they are not hung, because the hadiths that forbid amulets are general and to close the door to the rest. The Quran was sent down to be recited.")
                        ArticleBullet("• **Fortune-tellers and “healers”** who ask for your mother's name, write numbers and squares, tell you who did it, read cups or palms, or ask for an animal slaughtered in a certain way. Going to them is a sin, and believing them is worse:")
                        ScriptureQuote(hadith: "muslim:2230", cite: "Saheeh Muslim 2230", arabic: 36...47, english: 0...20)
                        ArticleBullet("• **Talking with the jinn**, taking their word, or accusing a relative because a jinn named them. The jinn lie, and the Sunnah never made them witnesses.")
                        ArticleBullet("• **Harming the patient**: beating, choking, shouting into the ear, electric shocks. None of it is from the Sunnah.")
                        ArticleBullet("• **Seclusion with a woman, or touching her**, in the name of treatment.")
                        ArticleBullet("• **Leaving medicine, or blaming everything on the eye, magic or the jinn.** Illness, sadness, anxiety and failure have ordinary causes too, and doctors and counsellors treat them. Recite ruqyah, and see the doctor.")
                        ArticleBullet("• **Invented counts and schedules**: a surah forty-one times at a set hour, ruqyah “programs”, rituals the Sunnah never taught.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Ruqyah is the Quran and the Prophet's supplications, recited by you over yourself and those you love, with the heart on Allah alone. Recite al-Faatihah, Aayat al-Kursi and the surahs of refuge, blow lightly, say his words for healing, keep the morning and evening remembrances, take your medicine, and stay far from amulets, fortune-tellers and anyone who mixes the Quran with what Allah did not send down.")
                }

                ArticleSourcesSection(article: "RuqyahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "RuqyahView")
        .navigationTitle("How to Do Ruqyah")
    }
}

// MARK: - The evil eye

/// What to do about the evil eye (Abu, 2026-11-14: "Add how to guides evil eye"): what to say so that
/// you do not give it, the daily refuges for yourself and your children, what to do when struck, and
/// the washing of the one it came from, step by step, with what the scholars of the Sunnah warned
/// against (charms, smoke, fortune-tellers, accusation, dread). What the eye is and is not, with its
/// proofs, is the Pillars & Beliefs page `EvilEyeView`, which this guide opens instead of repeating.
struct EvilEyeGuideView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead(articleMarkdown: "In short: the **evil eye (العَين)** is real, and the Prophet (peace and blessings be upon him) taught everything it needs. So that you do not give it, ask Allah to bless whatever pleases you. To guard against it, keep the morning and evening words of refuge and say them over your children. If it strikes, recite ruqyah, and when the person it came from is known, ask them kindly to wash and pour the water over the one struck. Hang nothing, burn nothing, accuse no one, and trust Allah.")
                }

                Section(header: ArticleHeader("WHAT YOU ARE DEALING WITH")) {
                    ArticleParagraph(verbatim: "The eye is harm that reaches a person, by Allah's leave, from a look or a word of envy, or of admiration that does not remember Allah. It can come from anyone, someone who loves you included, and it never outruns what Allah has decreed:")
                    ScriptureQuote(hadith: "muslim:2188", cite: "Saheeh Muslim 2188", arabic: 43...54, english: 0...45)
                    ArticleParagraph(verbatim: "That one hadith holds the whole subject: the eye is real, the decree is above it, and its cure is a washing. What the eye is and what it is not, with the proofs, is in Pillars & Beliefs:")
                    ArticleDoorRow(door: .article("EvilEyeView"))
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHEN SOMETHING PLEASES YOU")) {
                        ArticleParagraph(verbatim: "The eye most often leaves a person who admires something and says nothing to Allah. When Aamir ibn Rabee‘ah praised the skin of Sahl ibn Hunayf and Sahl collapsed on the spot, the Prophet (peace and blessings be upon him) said to him:")
                        ScriptureQuote(hadith: "ibnmajah:3509", cite: "Sunan Ibn Maajah 3509; graded saheeh by al-Albaani", arabic: 67...80, english: 63...85)
                        ArticleStep("1. **Ask Allah to bless it, aloud**, whenever a person, a child, a home, a skill or anything else pleases you: “Allahumma baarik ‘alayh” (O Allah, send blessing upon him), “Allahumma baarik ‘alayha” (upon her), “Allahumma baarik feeh” (bless it), or to the person directly, “Baarakallahu feek” (may Allah bless you). Ibn al-Qayyim explained the Prophet's words to Aamir as exactly this: say “Allahumma baarik ‘alayh” (Zad al-Ma‘aad 4/155-157).")
                        ArticleStep("2. **Do the same for what is yours.** Your own child, your own home, your own reflection: Ibn al-Qayyim said that a man may give the eye to himself (Zad al-Ma‘aad 4/154), and one narration of the story of Sahl names a person's own self and wealth beside his brother (Musnad Ahmad 15700; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 2572).")
                        ArticleStep("3. **Join “Ma sha' Allah, la quwwata illa billah” to it** (what Allah willed; there is no power except in Allah), as Ibn Baaz and the Standing Committee advised. They are the words the believer told the owner of the garden he should have said on entering it:")
                        ScriptureQuote(quran: "18:39", words: 5...11)
                        ArticleStep("4. **Guard the heart behind the eye.** If you feel envy, do not speak from it or act on it. Ask Allah for the like of what you saw, and pray for its owner:")
                        ScriptureQuote(hadith: "bukhari:13", cite: "Saheeh al-Bukhaari 13", arabic: 39...47, english: 4...21)
                        ArticleStep("5. **If you know your eye is quick**, be stricter with yourself: ask blessing every time, without exception, and look away from what stirs it.")
                    }

                    Section(header: ArticleHeader("GUARD YOURSELF EVERY DAY")) {
                        ArticleParagraph(verbatim: "The strongest protection is in place before anything happens. None of it is a charm: each is a request to Allah, renewed every day.")
                        ArticleStep("1. **Recite al-Ikhlaas, al-Falaq and an-Naas three times each, morning and evening.** Al-Falaq ends with the refuge from the envier, and the Prophet said of the two surahs of refuge that nothing like them had ever been seen (Saheeh Muslim 814).")
                        ScriptureQuote(hadith: "muslim:814a", cite: "Saheeh Muslim 814", arabic: 26...45, english: 0...37)
                        ScriptureQuote(hadith: "abudawud:5082", cite: "Sunan Abi Daawood 5082; graded hasan by al-Albaani", arabic: 84...99, english: 72...93)
                        ArticleStep("2. **Recite the three again when you lie down**, blow into your cupped hands, and wipe them over as much of your body as you can reach, three times (Saheeh al-Bukhaari 5017).")
                        ScriptureQuote(hadith: "bukhari:5017", cite: "Saheeh al-Bukhaari 5017", arabic: 21...66, english: 0...61)
                        ArticleStep("3. **Recite Aayat al-Kursi when you lie down** (Saheeh al-Bukhaari 2311), and the last two aayaat of al-Baqarah at night (Saheeh al-Bukhaari 5009).")
                        ScriptureQuote(hadith: "bukhari:2311", cite: "Saheeh al-Bukhaari 2311", arabic: 271...321, english: [419...471, 489...503])
                        ScriptureQuote(hadith: "bukhari:5009", cite: "Saheeh al-Bukhaari 5009", arabic: 31...40, english: 4...21)
                        ArticleStep("4. **Say these two refuges**, the first three times each morning and evening, the second whenever you stop somewhere:")
                        GuideDuaRow(DuaItem(
                            hadith: "abudawud:5088", cite: "Sunan Abi Daawood 5088; graded saheeh by al-Albaani", arabic: 34...49, english: 25...50,
                            transliteration: "Bismillahil-ladhi la yadurru ma‘a ismihi shay’un fil-ardi wa la fis-samaa’i wa huwas-Samee‘ul-‘Aleem",
                            note: "Three times, morning and evening"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2708a", cite: "Saheeh Muslim 2708", arabic: 63...70, english: 16...32,
                            transliteration: "A‘oodhu bikalimaatillahit-taammaati min sharri ma khalaq",
                            note: "When stopping at a place; nothing will harm you until you move on"
                        ))
                        ArticleStep("5. **Keep the five prayers and stay away from sin.** The heart that remembers Allah is the best guarded, and whoever relies on Him has enough:")
                        ScriptureQuote(quran: "65:3", words: 5...10)
                        ArticleParagraph(verbatim: "In his commentary on Surah al-Falaq, Ibn al-Qayyim counted ten things by which the harm of the envier is turned away from the one envied (Badaa’i‘ al-Fawaa’id):")
                        ArticleChecklist([
                            "**Seeking refuge in Allah** from his evil.",
                            "**Taqwa**: keeping to Allah's commands and prohibitions.",
                            "**Patience** with the envier: not fighting him, not complaining of him, not planning to harm him.",
                            "**Reliance on Allah.**",
                            "**Emptying the heart** of thinking about him.",
                            "**Turning to Allah** with sincerity.",
                            "**Repenting** from the sins that gave an enemy power over you.",
                            "**Charity and doing good**, as much as you can.",
                            "**Doing good to the envier himself**, which puts out his fire.",
                            "**Pure tawheed**: looking past the causes to the One who causes.",
                        ], title: "Ten Things That Turn Away the Envier's Harm")
                    }

                    Section(header: ArticleHeader("GUARD YOUR CHILDREN")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) sought refuge for his grandsons al-Hasan and al-Husayn with the words Ibraaheem used for Ismaa‘eel and Ishaaq (peace be upon them):")
                        GuideDuaRow(DuaItem(
                            hadith: "bukhari:3371", cite: "Saheeh al-Bukhaari 3371", arabic: 43...54, english: 33...55,
                            transliteration: "A‘oodhu bi-kalimaatillahit-taammah, min kulli shaytaanin wa haammah, wa min kulli ‘aynin lammah.",
                            note: "Said over children, as he said it over al-Hasan and al-Husayn"
                        ))
                        ArticleParagraph(verbatim: "Over two children the wording in Abu Daawood's narration of the same hadith is “U‘eedhukuma” (I place you both in the refuge of) in place of “A‘oodhu” (Sunan Abi Daawood 4737; graded saheeh by al-Albaani). Over one boy that becomes “U‘eedhuka”, and over one girl “U‘eedhuki”.")
                        ScriptureQuote(hadith: "abudawud:4737", cite: "Sunan Abi Daawood 4737; graded saheeh by al-Albaani", arabic: 22...44, english: 0...44)
                        ArticleBullet("• **At bedtime**, recite al-Ikhlaas, al-Falaq and an-Naas, blow into your hands, and wipe them over the child.")
                        ArticleBullet("• **Ask blessing when you praise them**, and say it yourself when a visitor praises them and forgets: “Allahumma baarik ‘alayh.” No one is embarrassed by a dua.")
                        ArticleBullet("• **Teach them the words** as soon as they can repeat them, so that their protection becomes their own.")
                        ArticleBullet("• **Hang nothing on them.** No thread, bead, pin or pendant, and no mark made as a charm. A child is guarded by Allah through the words of refuge, and through nothing worn.")
                        ArticleBullet("• **Plain precaution is allowed.** Dressing a child simply, or not showing off what draws eyes, is a different thing from a charm: Ibn al-Qayyim counted covering the beauty of one for whom the eye is feared among the precautions (Zad al-Ma‘aad 4/159), and Ibn al-Uthaymeen saw no harm in it, since it is leaving adornment and not doing anything (al-Qawl al-Mufeed 1/180).")
                    }

                    Section(header: ArticleHeader("IF YOU THINK YOU HAVE BEEN STRUCK")) {
                        ArticleStep("1. **Stay calm, and do not presume.** Tiredness, illness, low mood and a bad season in business have ordinary causes, and a doctor treats many of them. You do not need to know that it is the eye to do everything below, and all of it is good for you either way.")
                        ArticleStep("2. **Turn to Allah first.** Ask Him directly for the cure, repent from what is between you and Him, and hold on to the prayers. He is the One who removes harm:")
                        ScriptureQuote(quran: "10:107", words: 0...8)
                        ArticleStep("3. **Recite ruqyah over yourself**: al-Faatihah, Aayat al-Kursi, the last two aayaat of al-Baqarah, then al-Ikhlaas, al-Falaq and an-Naas, blowing into your hands and wiping over your body. The Prophet commanded ruqyah for the eye by name:")
                        ScriptureQuote(hadith: "bukhari:5739", cite: "Saheeh al-Bukhaari 5739, Saheeh Muslim 2197", arabic: 55...59, english: 18...32)
                        ArticleStep("4. **Use the two ruqyahs of Jibreel**, both of which name the eye. They are the words of one person reciting over another, so say them over whoever is ill in your home, and let them be said over you. Asking someone to recite over you is permitted when there is need, and the Prophet commanded seeking ruqyah for the eye (Saheeh al-Bukhaari 5738); what you recite over yourself, and what is recited over you unasked, is better still:")
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2186", cite: "Saheeh Muslim 2186", arabic: 38...56, english: 12...52,
                            transliteration: "Bismillahi arqeek, min kulli shay’in yu’dheek, min sharri kulli nafsin aw ‘ayni haasid, Allahu yashfeek, bismillahi arqeek.",
                            note: "Jibreel's ruqyah over the Prophet"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2185", cite: "Saheeh Muslim 2185", arabic: 54...69, english: 11...45,
                            transliteration: "Bismillahi yubreek, wa min kulli daa’in yashfeek, wa min sharri haasidin idha hasad, wa sharri kulli dhi ‘ayn.",
                            note: "Jibreel's ruqyah whenever the Prophet fell ill"
                        ))
                        ArticleStep("5. **Put your hand where it hurts**, say “Bismillah” three times, then seven times “A‘oodhu billahi wa qudratihi min sharri ma ajidu wa uhaadhir” (Saheeh Muslim 2202).")
                        ScriptureQuote(hadith: "muslim:2202", cite: "Saheeh Muslim 2202", arabic: 53...76, english: 0...54)
                        ArticleStep("6. **If you know who it came from, ask them to wash**, as in the next section.")
                        ArticleStep("7. **Repeat it for as long as the need lasts**, keep taking your medicine, and be patient. The cure comes when Allah wills it, and the waiting is rewarded.")
                        ArticleParagraph(verbatim: "The full method of ruqyah, with its conditions and what to avoid, has its own guide:")
                        ArticleDoorRow(door: .article("RuqyahView"))
                    }

                    Section(header: ArticleHeader("THE WASHING")) {
                        ArticleParagraph(verbatim: "When the person the eye came from is known, the Prophet (peace and blessings be upon him) had him wash, and the water was poured over the one struck:")
                    ScriptureQuote(hadith: "ahmed:15980", cite: "Musnad Ahmad 15980; graded saheeh by Shu‘ayb al-Arnaa’oot", arabic: 130...165, text: "“So he washed his face, his hands, his elbows, his knees, the ends of his feet and the inside of his lower garment in a vessel. Then that water was poured over him: a man poured it over his head and his back from behind him, tipping the vessel over behind him. That was done to him, and Sahl went on with the people with nothing wrong with him”")
                        ScriptureQuote(hadith: "abudawud:3880", cite: "Sunan Abi Daawood 3880; its chain graded saheeh by al-Albaani", arabic: 19...26, english: 0...18)
                        ArticleStep("1. **Ask kindly, and in private**, when you have a strong reason to think it came from this person. Ibn Baaz gave the words: “May Allah reward you with good; wash for me.” It is a request for help, not an accusation: Aamir was a Companion who had fought at Badr, and he meant no harm.")
                        ArticleStep("2. **If you are the one asked, do it at once**, without offence and without argument. The Prophet commanded it in the hadith above: when you are asked to wash, wash (Saheeh Muslim 2188). Al-Maaziri held it an obligation, all the more when the one struck is in danger (an-Nawawi, Sharh Saheeh Muslim 14/172). Ibn al-Uthaymeen called refusing, or taking offence, a mistake: help your brother, for if the eye was from you, you are rid of it, and if it was not, the washing does you no harm.")
                        ArticleStep("3. **Wash into a vessel**: the face, the hands, the elbows, the knees, the ends of the feet, and the inside of the lower garment, so that the water is caught in a bowl. That is how Aamir washed, in the narration above and in Maalik's in al-Muwatta; Ibn Maajah's has “his hands to the elbows” (Sunan Ibn Maajah 3509). The inside of the lower garment is the part of the waist-wrap that lies against the body, as al-Qaadi Iyaad explained it; al-Maaziri described it as the hanging edge next to the right hip, and said most of the scholars held so (Sharh Saheeh Muslim 14/172-173).")
                        ArticleStep("4. **Pour the water over the one struck**, over the head and back, from behind, in one pour, tipping the vessel out behind him.")
                        ArticleStep("5. **Wudu water serves as well**: the person makes wudu over a bowl and the one struck washes with that water, as Aa’ishah described. Ibn al-Uthaymeen gave it so: he is asked to make wudu, what falls from his wudu is collected, and it is poured over the head and back of the one struck (Majmoo‘ Fataawa Ibn al-Uthaymeen 2/119). Ibn Baaz said that, in his experience, washing the face, rinsing the mouth and washing the hands is enough by Allah's permission.")
                        ArticleParagraph(verbatim: "A fuller order is reported from az-Zuhri, who said he found the scholars describing it so, and an-Nawawi and the Standing Committee give it: the vessel is brought and is not set down on the ground; the person rinses his mouth into it and washes his face into it; then, dipping one hand and pouring over the other side each time, he washes his right palm and his left, his right elbow and his left, his right foot and his left, his right knee and his left, and then the inside of his lower garment; and it is poured over the head of the one struck, from behind, in a single pour (al-Bayhaqi, as-Sunan al-Kubra 9/351-352; Sharh Saheeh Muslim 14/172). Whoever does what the hadith itself names has done what was commanded.")
                        ArticleParagraph(verbatim: "Ibn al-Uthaymeen said that taking the person's urine or stool has no basis; what is reported is the washing of his limbs and of the inside of his garment (Majmoo‘ Fataawa Ibn al-Uthaymeen 2/117-118).")
                    }

                    Section(header: ArticleHeader("IF YOU DO NOT KNOW WHO IT WAS")) {
                        ArticleParagraph(verbatim: "Then you do not need to know. Ruqyah is a complete treatment, and the Prophet (peace and blessings be upon him) commanded it for the eye without making it depend on finding anyone (Saheeh al-Bukhaari 5738). Do not go through your guests in your mind, do not ask everyone who visited to wash, and never ask a fortune-teller, a “reader” or a jinn. The Standing Committee ruled that trying to picture the person during the recitation, or asking a jinn who it was, is the work of the devils and sows enmity between people.")
                        ScriptureQuote(hadith: "bukhari:5738", cite: "Saheeh al-Bukhaari 5738", arabic: 25...37, english: 0...18)
                        ScriptureQuote(hadith: "muslim:2230", cite: "Saheeh Muslim 2230", arabic: 36...47, english: 0...20)
                    }

                    Section(header: ArticleHeader("WHAT TO AVOID")) {
                        ArticleBullet("• **Charms of every kind**: the blue bead and the glass “eye”, the open hand, a black thread or a pin on a baby, a horseshoe, shells, and pendants hung for protection. The Prophet said:")
                        ScriptureQuote(hadith: "abudawud:36", cite: "Sunan Abi Daawood 36; graded saheeh by al-Albaani", arabic: 119...138, english: 125...157)
                        ArticleBullet("• **Smoke and kitchen cures**: burning wild rue, incense, alum or salt, circling them over a person's head, passing an egg over the body, pouring molten lead. The Standing Committee ruled that fumigating with alum, herbs or leaves for the eye is not permitted, since these are not ordinary causes of its cure and the smoke may be meant to appease the devils (Fataawa al-Lajnah ad-Daa’imah 1/275), and Ibn Baaz said the pouring of lead has no basis and is the practice of soothsayers.")
                        ArticleBullet("• **Charms of the tongue and hand**: knocking on wood, crossed fingers, “five in your eye”, spitting when someone is praised. Ibn Baaz called knocking on wood for fear of the envier's eye a wrong and a false belief (Majmoo‘ Fataawa Ibn Baaz 8/424). The Sunnah put one thing in their place: asking Allah to bless.")
                        ArticleBullet("• **Accusing people.** Baseless suspicion is a sin, and it cuts ties that no ruqyah mends. If you have a real reason, ask the person kindly to wash, and say nothing more to anyone.")
                        ArticleBullet("• **Dread.** Hiding your children, refusing visitors, reading every headache as an attack: this is a harm of its own. Guarding against the eye is part of relying on Allah; being ruled by the fear of it is not. Ibn al-Uthaymeen warned that delusions and whisperings have multiplied, so that people call every ordinary illness the jinn, the eye or magic. Say your words of refuge and live.")
                        ArticleBullet("• **Invented programs**: a surah a fixed number of times at a fixed hour, “evil eye removal” schedules, water blown on by someone for his own blessing. What is fixed is fixed by revelation.")
                        ArticleBullet("• **Leaving medicine.** Ruqyah and treatment go together, and the Prophet commanded both.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**“Ma sha' Allah” or “Baarakallah”?** What the Prophet commanded for the eye is asking blessing, so that is the part never to leave out. Ibn Baaz and the Standing Committee advised saying “Ma sha' Allah, la quwwata illa billah” together with it; Ibn al-Uthaymeen kept that phrase for your own blessings and for another's said “Tabaarak Allahu ‘alayk”. Asked about “Ma sha' Allah, tabaarak Allah”, Ibn Baaz answered that nothing is reported for “Tabaarak Allah”: what is reported is the dua, “Allahumma baarik feeh” or “Baarakallahu feeh”, said with “Ma sha' Allah, la quwwata illa billah”. The hadith that “Ma sha' Allah, la quwwata illa billah” by itself stops the eye from harming is weak (al-Albaani, Da‘eef al-Jaami‘ 5588).")
                        ArticleParagraph(articleMarkdown: "**What if the person refuses to wash, lives far away, or has died?** Then recite ruqyah, which is enough without it. The washing is one means of cure, not a condition of it.")
                        ArticleParagraph(articleMarkdown: "**Should I ask everyone who visited to wash?** No. The Prophet asked whom they suspected because the cause was plain: one man, one remark, and Sahl collapsed. Asking a whole gathering to wash spreads suspicion over the innocent.")
                        ArticleParagraph(articleMarkdown: "**May I keep good news to myself?** Yes. Ya‘qoob told Yoosuf not to tell his dream to his brothers (Quran 12:5), and there is wisdom in not showing everything to everyone. Allah also told His Prophet to speak of his Lord's favor (Quran 93:11), so thank Him for the blessing and enjoy it openly among people you trust.")
                        ScriptureQuote(quran: "12:5", words: 2...6)
                        ScriptureQuote(quran: "93:11")
                        ArticleParagraph(articleMarkdown: "**Should I stop sharing photos of my children?** Whether photographs of living beings may be taken and kept at all is a separate question, on which Ibn Baaz was strict. As far as the eye goes, nothing in the texts ties it to seeing someone in the flesh, so good sense about what you show, and to whom, is wise. No screen has a power the decree does not give it. Say their refuge over them and choose with a calm heart.")
                        ArticleParagraph(articleMarkdown: "**Can I hang an ayah or “Ma sha' Allah” in the car or on the baby?** Hung or worn for protection it is an amulet. Where only Quran is written in it the Salaf differed, and the sounder view, which Ibn Baaz and the Standing Committee held correct, is that it is not hung either. Protection is in saying the words, not in displaying them.")
                        ArticleParagraph(articleMarkdown: "**May I recite into water and wash with it or drink it?** Ibn Baaz and the Standing Committee permitted reciting the Quran into water for the sick. Reciting directly over the person is better, as the Sunnah shows.")
                        ArticleParagraph(articleMarkdown: "**How will I know it has gone?** By feeling better. There is no sign in the Sunnah to look for, and no one who can “see” it leave. Keep to the remembrances either way.")
                    }

                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleTermCard("Al-'ayn", arabic: "العَيْن", meaning: "The evil eye: harm that strikes, by Allah's leave, from a look of envy, or of admiration that does not remember Allah.")
                        ArticleTermCard("Aa’in", arabic: "العَائِن", meaning: "The one the eye comes from, whether he meant it or not.")
                        ArticleTermCard("Ma‘een", arabic: "المَعِين", meaning: "The one struck by the eye.")
                        ArticleTermCard("Tabreek", arabic: "التَّبْرِيك", meaning: "Asking Allah to bless: “Allahumma baarik ‘alayh”, “Baarakallahu feek”. What the one who admires says.")
                        ArticleTermCard("Isti‘aadhah", arabic: "الاسْتِعَاذَة", meaning: "Seeking refuge in Allah: the surahs and words of refuge said morning, evening and over children.")
                        ArticleTermCard("Ruqyah", arabic: "الرُّقْيَة", meaning: "Reciting the Quran and the Prophet's supplications over the one afflicted, asking Allah alone for the cure.")
                        ArticleTermCard("Tameemah", arabic: "التَّمِيمَة", meaning: "An amulet or charm hung or worn for protection. Forbidden, and shirk when the heart relies on it. One made only of Quran is not hung either, on the sounder view.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("WHEN SOMETHING PLEASES YOU")) {
                        ArticleParagraph(verbatim: "The eye most often leaves a person who admires something and says nothing to Allah. When Aamir ibn Rabee‘ah praised the skin of Sahl ibn Hunayf and Sahl collapsed on the spot, the Prophet (peace and blessings be upon him) said to him:")
                        ScriptureQuote(hadith: "ibnmajah:3509", cite: "Sunan Ibn Maajah 3509; graded saheeh by al-Albaani", arabic: 67...80, english: 63...85)
                        ArticleStep("1. **Ask Allah to bless it, aloud**, whenever a person, a child, a home, a skill or anything else pleases you: “Allahumma baarik ‘alayh” (O Allah, send blessing upon him), “Allahumma baarik ‘alayha” (upon her), “Allahumma baarik feeh” (bless it), or to the person directly, “Baarakallahu feek” (may Allah bless you).")
                        ArticleStep("2. **Do the same for what is yours.** Your own child, your own home, your own reflection: Ibn al-Qayyim said that a man may give the eye to himself.")
                        ArticleStep("3. **Join “Ma sha' Allah, la quwwata illa billah” to it** (what Allah willed; there is no power except in Allah), as Ibn Baaz and the Standing Committee advised.")
                        ArticleStep("4. **Guard the heart behind the eye.** If you feel envy, do not speak from it or act on it. Ask Allah for the like of what you saw, and pray for its owner.")
                    }

                    Section(header: ArticleHeader("GUARD YOURSELF EVERY DAY")) {
                        ArticleParagraph(verbatim: "The strongest protection is in place before anything happens. None of it is a charm: each is a request to Allah, renewed every day.")
                        ArticleStep("1. **Recite al-Ikhlaas, al-Falaq and an-Naas three times each, morning and evening.**")
                        ScriptureQuote(hadith: "abudawud:5082", cite: "Sunan Abi Daawood 5082; graded hasan by al-Albaani", arabic: 84...99, english: 72...93)
                        ArticleStep("2. **Recite the three again when you lie down**, blow into your cupped hands, and wipe them over as much of your body as you can reach, three times.")
                        ArticleStep("3. **Recite Aayat al-Kursi when you lie down**, and the last two aayaat of al-Baqarah at night.")
                        ArticleStep("4. **Say these two refuges**, the first three times each morning and evening, the second whenever you stop somewhere:")
                        GuideDuaRow(DuaItem(
                            hadith: "abudawud:5088", cite: "Sunan Abi Daawood 5088; graded saheeh by al-Albaani", arabic: 34...49, english: 25...50,
                            transliteration: "Bismillahil-ladhi la yadurru ma‘a ismihi shay’un fil-ardi wa la fis-samaa’i wa huwas-Samee‘ul-‘Aleem",
                            note: "Three times, morning and evening"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2708a", cite: "Saheeh Muslim 2708", arabic: 63...70, english: 16...32,
                            transliteration: "A‘oodhu bikalimaatillahit-taammaati min sharri ma khalaq",
                            note: "When stopping at a place; nothing will harm you until you move on"
                        ))
                        ArticleStep("5. **Keep the five prayers and stay away from sin.** The heart that remembers Allah is the best guarded.")
                    }

                    Section(header: ArticleHeader("GUARD YOUR CHILDREN")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) sought refuge for his grandsons al-Hasan and al-Husayn with the words Ibraaheem used for Ismaa‘eel and Ishaaq (peace be upon them):")
                        GuideDuaRow(DuaItem(
                            hadith: "bukhari:3371", cite: "Saheeh al-Bukhaari 3371", arabic: 43...54, english: 33...55,
                            transliteration: "A‘oodhu bi-kalimaatillahit-taammah, min kulli shaytaanin wa haammah, wa min kulli ‘aynin lammah.",
                            note: "Said over children, as he said it over al-Hasan and al-Husayn"
                        ))
                        ArticleParagraph(verbatim: "Over one boy “A‘oodhu” becomes “U‘eedhuka” (I place you in the refuge of), over one girl “U‘eedhuki”, and over two children “U‘eedhukuma”.")
                        ArticleBullet("• **At bedtime**, recite al-Ikhlaas, al-Falaq and an-Naas, blow into your hands, and wipe them over the child.")
                        ArticleBullet("• **Ask blessing when you praise them**, and say it yourself when a visitor praises them and forgets: “Allahumma baarik ‘alayh.” No one is embarrassed by a dua.")
                        ArticleBullet("• **Hang nothing on them.** No thread, bead, pin or pendant, and no mark made as a charm. A child is guarded by Allah through the words of refuge, and through nothing worn.")
                    }

                    Section(header: ArticleHeader("IF YOU THINK YOU HAVE BEEN STRUCK")) {
                        ArticleStep("1. **Stay calm, and do not presume.** Tiredness, illness, low mood and a bad season in business have ordinary causes, and a doctor treats many of them. You do not need to know that it is the eye to do everything below, and all of it is good for you either way.")
                        ArticleStep("2. **Turn to Allah first.** Ask Him directly for the cure, repent from what is between you and Him, and hold on to the prayers. He is the One who removes harm.")
                        ArticleStep("3. **Recite ruqyah over yourself**: al-Faatihah, Aayat al-Kursi, the last two aayaat of al-Baqarah, then al-Ikhlaas, al-Falaq and an-Naas, blowing into your hands and wiping over your body. The Prophet commanded ruqyah for the eye by name:")
                        ScriptureQuote(hadith: "bukhari:5739", cite: "Saheeh al-Bukhaari 5739, Saheeh Muslim 2197", arabic: 55...59, english: 18...32)
                        ArticleStep("4. **Use the two ruqyahs of Jibreel**, both of which name the eye. Say them over whoever is ill in your home, and let them be said over you:")
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2186", cite: "Saheeh Muslim 2186", arabic: 38...56, english: 12...52,
                            transliteration: "Bismillahi arqeek, min kulli shay’in yu’dheek, min sharri kulli nafsin aw ‘ayni haasid, Allahu yashfeek, bismillahi arqeek.",
                            note: "Jibreel's ruqyah over the Prophet"
                        ))
                        GuideDuaRow(DuaItem(
                            hadith: "muslim:2185", cite: "Saheeh Muslim 2185", arabic: 54...69, english: 11...45,
                            transliteration: "Bismillahi yubreek, wa min kulli daa’in yashfeek, wa min sharri haasidin idha hasad, wa sharri kulli dhi ‘ayn.",
                            note: "Jibreel's ruqyah whenever the Prophet fell ill"
                        ))
                        ArticleStep("5. **If you know who it came from, ask them to wash**, as in the next section.")
                        ArticleStep("6. **Repeat it for as long as the need lasts**, keep taking your medicine, and be patient. The cure comes when Allah wills it, and the waiting is rewarded.")
                        ArticleParagraph(verbatim: "The full method of ruqyah, with its conditions and what to avoid, has its own guide:")
                        ArticleDoorRow(door: .article("RuqyahView"))
                    }

                    Section(header: ArticleHeader("THE WASHING")) {
                        ArticleParagraph(verbatim: "When the person the eye came from is known, the Prophet (peace and blessings be upon him) had him wash, and the water was poured over the one struck:")
                        ScriptureQuote(hadith: "abudawud:3880", cite: "Sunan Abi Daawood 3880; its chain graded saheeh by al-Albaani", arabic: 19...26, english: 0...18)
                        ArticleStep("1. **Ask kindly, and in private**, when you have a strong reason to think it came from this person. Ibn Baaz gave the words: “May Allah reward you with good; wash for me.” It is a request for help, not an accusation.")
                        ArticleStep("2. **If you are the one asked, do it at once**, without offence and without argument. As Ibn al-Uthaymeen said: help your brother, for if the eye was from you, you are rid of it, and if it was not, the washing does you no harm.")
                        ArticleStep("3. **Wash into a vessel**: the face, the hands, the elbows, the knees, the ends of the feet, and the inside of the lower garment (the part of the waist-wrap that lies against the body), so that the water is caught in a bowl.")
                        ArticleStep("4. **Pour the water over the one struck**, over the head and back, from behind, in one pour, tipping the vessel out behind him.")
                        ArticleStep("5. **Wudu water serves as well**: the person makes wudu over a bowl and the one struck washes with that water, as Aa’ishah described.")
                    }

                    Section(header: ArticleHeader("IF YOU DO NOT KNOW WHO IT WAS")) {
                        ArticleParagraph(verbatim: "Then you do not need to know: ruqyah is a complete treatment. Do not go through your guests in your mind, do not ask everyone who visited to wash, and never ask a fortune-teller, a “reader” or a jinn.")
                    }

                    Section(header: ArticleHeader("WHAT TO AVOID")) {
                        ArticleBullet("• **Charms of every kind**: the blue bead and the glass “eye”, the open hand, a black thread or a pin on a baby, a horseshoe, shells, and pendants hung for protection. The Prophet said:")
                        ScriptureQuote(hadith: "abudawud:36", cite: "Sunan Abi Daawood 36; graded saheeh by al-Albaani", arabic: 119...138, english: 125...157)
                        ArticleBullet("• **Smoke and kitchen cures**: burning wild rue, incense, alum or salt, circling them over a person's head, passing an egg over the body, pouring molten lead.")
                        ArticleBullet("• **Charms of the tongue and hand**: knocking on wood, crossed fingers, “five in your eye”, spitting when someone is praised. The Sunnah put one thing in their place: asking Allah to bless.")
                        ArticleBullet("• **Accusing people.** Baseless suspicion is a sin, and it cuts ties that no ruqyah mends. If you have a real reason, ask the person kindly to wash, and say nothing more to anyone.")
                        ArticleBullet("• **Dread.** Hiding your children, refusing visitors, reading every headache as an attack: this is a harm of its own. Say your words of refuge and live.")
                        ArticleBullet("• **Leaving medicine.** Ruqyah and treatment go together, and the Prophet commanded both.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("When something pleases you, ask Allah to bless it. Morning and evening, say the surahs and words of refuge, and say them over your children. If the eye strikes, recite ruqyah, and if you know who it came from, ask them gently to wash and pour the water over the one struck. Hang nothing, burn nothing, accuse no one, and leave the outcome with Allah, without whose leave nothing harms.")
                }

                ArticleSourcesSection(article: "EvilEyeGuideView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "EvilEyeGuideView")
        .navigationTitle("How to Deal With the Evil Eye")
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
        sources

        // The page's Previous | Next, last of all (`ArticlePager`). Here because this section closes
        // every catalog article, so every one of them gets the pair without a line of its own.
        ArticlePagerSection(article: article)
    }

    @ViewBuilder
    private var sources: some View {
        if let sources = ArticleSources.table[article], !sources.isEmpty {
            Section {
                ForEach(sources, id: \.self) { source in
                    // One view by its type, as a List row must be (see `OneRow`).
                    OneRow {
                        if let raw = source.url, let url = URL(string: raw) {
                            Link(destination: url) { row(source, linked: true) }
                        } else {
                            row(source, linked: false)
                        }
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

#if os(iOS)
/// The How-to Guides index's opening card: the acts every Muslim needs first, as a numbered path in the
/// order they are learned. Each step opens its guide; Buttons writing one binding, since the card is
/// one List row.
struct GuidesPathHero: View {
    @Environment(\.appearance) private var appearance
    @Binding var open: String?

    private static let steps: [(id: String, name: String, systemImage: String)] = [
        ("WudhuView", "Wudu", "drop"),
        ("HowToPrayView", "Pray", "sun.max"),
        ("HowToFastView", "Fast", "moon.stars"),
        ("HowToZakahView", "Zakaah", "heart.circle"),
        ("HowToHajjView", "Hajj", "house"),
    ]

    /// The resource's card (`ResourceHero`), with the five steps on their path as its picture.
    var body: some View {
        ResourceHero(
            eyebrow: "THE ESSENTIALS, IN ORDER",
            systemImage: "point.topleft.down.to.point.bottomright.curvepath",
            headline: "And I did not create the jinn and mankind except to worship Me.",
            source: "Quran 51:56",
            message: "Purify, pray, fast, give and make the pilgrimage: tap a step for its guide, each with the Quran and the Sunnah behind it."
        ) {
            path
                .padding(.top, 2)
        }
    }

    private var path: some View {
        let accent = appearance.accent
        return ZStack(alignment: .top) {
            // The path the steps sit on.
            Rectangle()
                .fill(accent.opacity(0.3))
                .frame(height: 2)
                .padding(.horizontal, 30)
                .padding(.top, 17)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                    Button {
                        Settings.shared.hapticFeedback()
                        open = step.id
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.7)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 36, height: 36)
                                Image(systemName: step.systemImage)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Text("\(index + 1). \(step.name)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Step \(index + 1): how to \(step.name)")
                }
            }
        }
    }
}
#endif
