#if os(iOS)
import SwiftUI

/// One credited source, as data: the line the Credits page prints, its link, and the words a searcher
/// types for it. Shared by the page's own search and by the Settings search (`SettingsSearchEntry.creditEntries`),
/// whose results open the page scrolled to the row.
struct CreditItem: Identifiable, Hashable {
    /// The section a credit belongs to. The page prints one section per group, in this order,
    /// and skips a group no credit in this app belongs to (Al-Adhan has no hadith books, so it
    /// prints no HADITH section at all).
    enum Group: String, CaseIterable {
        case adhan = "Prayer Times"
        case quran = "Quran"
        case hadith = "Hadith"
        /// The Islam tab's own libraries: the Names, Hisn al-Muslim, the Miracles articles,
        /// the hadith encyclopedia behind the topic pages, and the Journal.
        case islam = "Islam"
    }

    /// Stable slug: the row id on the page and the Settings search destination.
    let id: String
    /// The short name a Settings search result shows ("Arabic text and qiraat data: KFGQPC").
    let title: String
    /// The full credit line the page prints.
    let detail: String
    let url: String
    let group: Group
    /// Words the line does not carry but a searcher might type.
    var keywords: String = ""

    var rowID: String { "credit_\(id)" }

    static let all: [CreditItem] = [
        // Prayer times
        CreditItem(id: "adhan-calculations", title: "Adhan calculations: Batoul Apps",
                   detail: "Credit for the Adhan calculations, which does everything offline on the device, goes to Batoul Apps",
                   url: "https://github.com/batoulapps/adhan-swift", group: .adhan, keywords: "prayer times library swift"),
        CreditItem(id: "adhan-sounds", title: "Adhan sounds: Omar Al-Ejel",
                   detail: "Credit for the Adhan sounds goes to Omar Al-Ejel",
                   url: "https://github.com/oalejel/Athan-Utility", group: .adhan, keywords: "audio athan utility"),
        CreditItem(id: "serene-adhan", title: "Serene adhan: Adam-synagda (CC0)",
                   detail: "The Serene adhan is \"Beautiful adhan\" by Adam-synagda (CC0, via Wikimedia Commons), trimmed and loudness-normalized",
                   url: "https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg", group: .adhan, keywords: "audio sound license"),
        CreditItem(id: "aaqib-adhan", title: "Aaqib Azeez adhan (CC BY-SA 4.0)",
                   detail: "The Aaqib Azeez adhan is by Aaqib Azeez (CC BY-SA 4.0, via Wikimedia Commons), trimmed and loudness-normalized; the clips remain CC BY-SA 4.0",
                   url: "https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3", group: .adhan, keywords: "audio sound license"),
        CreditItem(id: "takbir-tone", title: "Takbir alert tone: Aaqib Azeez (CC BY-SA 4.0)",
                   detail: "The Takbir alert tone is the opening takbir pair of the Aaqib Azeez adhan (CC BY-SA 4.0, via Wikimedia Commons), trimmed and loudness-normalized; the clip remains CC BY-SA 4.0",
                   url: "https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3", group: .adhan, keywords: "notification sound reminder"),
        CreditItem(id: "chime-tone", title: "Chime alert tone: GabFitzgerald (CC0)",
                   detail: "The Chime alert tone is \"[UI Sound] Approval - High Pitched Bell Synth\" by GabFitzgerald (CC0, via Freesound), trimmed, repeated, and loudness-normalized",
                   url: "https://freesound.org/people/GabFitzgerald/sounds/625174/", group: .adhan, keywords: "notification sound reminder"),
        CreditItem(id: "ring-tone", title: "Ring alert tone: Vendarro (CC0)",
                   detail: "The Ring alert tone is \"Signal-Ring 1\" by Vendarro (CC0, via Freesound), trimmed, repeated, and loudness-normalized",
                   url: "https://freesound.org/people/Vendarro/sounds/399315/", group: .adhan, keywords: "notification sound reminder"),
        CreditItem(id: "alarm-tone", title: "Alarm alert tone: Kesu (CC0)",
                   detail: "The Alarm alert tone is \"Alarm clock beep\" by Kesu (CC0, via Freesound), trimmed, repeated, and loudness-normalized",
                   url: "https://freesound.org/people/Kesu/sounds/182351/", group: .adhan, keywords: "notification sound reminder"),
        CreditItem(id: "moon-phase", title: "Moon phase algorithm: SunCalc",
                   detail: "Credit for the moon phase algorithm behind the sky card and the Moon widgets goes to SunCalc by Vladimir Agafonkin, built on the lunar theory in Meeus' Astronomical Algorithms",
                   url: "https://github.com/mourner/suncalc", group: .adhan, keywords: "lunar hijri widget sky"),

        // Quran
        CreditItem(id: "kfgqpc-text", title: "Arabic text and qiraat data: KFGQPC",
                   detail: "Credit for all the Quranic Arabic text and all qiraat/riwayaat data goes to quran-data-kfgqpc (KFGQPC)",
                   url: "https://github.com/thetruetruth/quran-data-kfgqpc", group: .quran, keywords: "king fahd complex uthmani hafs warsh qaloon riwayah readings"),
        CreditItem(id: "islamweb", title: "Printed mushaf PDFs and beta qiraat text: Islamweb",
                   detail: "Credit for the printed mushaf PDFs (one per riwayah) and the beta qiraat text goes to Islamweb",
                   url: "https://www.islamweb.net", group: .quran, keywords: "mushaf pdf riwayah beta"),
        CreditItem(id: "quran-com-qiraat", title: "Readings of the Ten: Quran.com (Quran Foundation)",
                   detail: "Credit for the annotated variant readings under an ayah (who among the Ten reads which form, with its meaning and notes) goes to the qiraat reference of Quran.com by the Quran Foundation",
                   url: "https://quran.com/1:4/qiraat", group: .quran, keywords: "qiraat readings variants ten imams transmitters"),
        CreditItem(id: "qiraathub", title: "Qiraat companion reference: QiraatHub",
                   detail: "Credit for the qiraat guide's companion reference on the ten imams and twenty narrators goes to QiraatHub",
                   url: "https://qiraathub.com/", group: .quran, keywords: "imams narrators readings"),
        CreditItem(id: "tilawa-qiraat-explorer", title: "Qiraat Explorer and place index: Tilawa and Quran.com",
                   detail: "Credit for the Qiraat Explorer's idea (every place the riwayat differ, by ayah and by surah) and for the worked examples on each narrator's page (where he differs from Hafs, with a recording where one exists) goes to Tilawa, by my friend Jamil Hammoudeh; the place index is computed from this app's own riwayah texts, and the readings' meanings draw on Quran.com's qiraat reference",
                   url: "https://github.com/jamilhammoudeh/quran-app", group: .quran, keywords: "qiraat explorer riwayat differences tilawa"),
        CreditItem(id: "saheeh", title: "Saheeh International translation: Global Quran",
                   detail: "Credit for the English Saheeh International translation of the Quran data goes to Global Quran",
                   url: "https://globalquran.com/download/data/", group: .quran, keywords: "english translation"),
        CreditItem(id: "transliteration", title: "English transliteration: QUL (Tarteel) and Risan Bagja Pradana",
                   detail: "Credit for the ayah transliteration, written the way each ayah is recited, goes to the English Transliteration (Tajweed) dataset of the Quranic Universal Library by Tarteel; the app's original transliteration came from Risan Bagja Pradana's quran-json",
                   url: "https://qul.tarteel.ai/resources/transliteration", group: .quran, keywords: "quran json latin pronunciation tajweed"),
        CreditItem(id: "translation-api", title: "Translation comparison API: Al Quran Cloud",
                   detail: "Credit for the English Quran translation comparison API goes to Al Quran Cloud",
                   url: "https://alquran.cloud/api", group: .quran, keywords: "translations compare"),
        CreditItem(id: "uthmani-fonts", title: "Uthmani Quran fonts: KFGQPC",
                   detail: "Credit for the Uthmani Quran fonts (the Hafs face, and the Warsh face behind the Maghribi script style) goes to King Fahad Complex (KFGQPC)",
                   url: "https://qul.tarteel.ai/resources/font/245", group: .quran, keywords: "font typeface script hafs warsh maghribi"),
        CreditItem(id: "indopak-font", title: "Indopak Nastaleeq font: Ayman Siddiqui and R. Siddiqua",
                   detail: "Credit for the Indopak Nastaleeq Quran font goes to Ayman Siddiqui and R. Siddiqua",
                   url: "https://qul.tarteel.ai/resources/font/242", group: .quran, keywords: "font typeface script urdu"),
        CreditItem(id: "kufi-font", title: "Kufi Quran font: Noto Kufi Arabic",
                   detail: "Credit for the Kufi Quran font (Noto Kufi Arabic) goes to the Noto Project Authors at Google, used under the SIL Open Font License 1.1",
                   url: "https://fonts.google.com/noto/specimen/Noto+Kufi+Arabic", group: .quran, keywords: "font typeface script google"),
        CreditItem(id: "hijazi-font", title: "Hijazi Quran font: Khalid Alabdullah",
                   detail: "Credit for the Hijazi Quran font goes to Khalid Alabdullah, whose hijazifont models the hand of the earliest mushafs (CC BY-NC 4.0, used with the author's permission); the vowel marks, hamza, digits and mark positioning of Al-Islam Hijazi, in its light, bold and dot-vowel styles, were added by this app",
                   url: "https://github.com/khalidalabdullah/hijazifont", group: .quran, keywords: "font typeface script early mushaf"),
        CreditItem(id: "mp3quran", title: "Surah recitations: MP3 Quran",
                   detail: "Credit for the Surah Quran Recitations goes to MP3 Quran",
                   url: "https://mp3quran.net/eng", group: .quran, keywords: "audio reciters reciter listen"),
        CreditItem(id: "alquran-cloud-audio", title: "Ayah recitations: Al Quran Cloud",
                   detail: "Credit for the Ayah Quran Recitations goes to Al Quran",
                   url: "https://alquran.cloud/cdn", group: .quran, keywords: "audio reciters reciter listen verse"),
        CreditItem(id: "everyayah", title: "Additional ayah recitations: EveryAyah",
                   detail: "Credit for additional Ayah Quran Recitations goes to EveryAyah",
                   url: "https://everyayah.com/", group: .quran, keywords: "audio reciters reciter listen verse"),
        CreditItem(id: "qdc-timings", title: "Ayah audio timings: Quran.com (Quran Foundation)",
                   detail: "Credit for the ayah audio timings that power offline ayah playback goes to the QDC audio API by Quran.com (Quran Foundation)",
                   url: "https://api-docs.quran.foundation/", group: .quran, keywords: "audio offline playback segments"),
        CreditItem(id: "word-by-word-meanings", title: "Word-by-word meanings: Quran.com and the Quranic Arabic Corpus",
                   detail: "Credit for the word-by-word English meanings, shown when you tap a word while reading, goes to the QDC content API by Quran.com (Quran Foundation), whose per-word glosses come from the Quranic Arabic Corpus by Kais Dukes",
                   url: "https://corpus.quran.com/", group: .quran, keywords: "gloss word card translation"),
        CreditItem(id: "tilawa-word-by-word", title: "Word-by-word reader: Tilawa, by Jamil Hammoudeh",
                   detail: "Credit for the word-by-word reader itself (the idea, and the assembled gloss corpus this app's pack was built from) goes to Tilawa, by my friend Jamil Hammoudeh",
                   url: "https://github.com/jamilhammoudeh/quran-app", group: .quran, keywords: "gloss word card"),
        CreditItem(id: "qac-morphology", title: "Roots and dictionary forms: Quranic Arabic Corpus",
                   detail: "Credit for the root and dictionary form of every word, on the word card and behind the root search, goes to the Quranic Arabic Corpus morphology by Kais Dukes, via the Quranic Universal Library",
                   url: "https://corpus.quran.com/", group: .quran, keywords: "root lemma morphology grammar word"),
        CreditItem(id: "tilawa-word-of-day", title: "Word of the Day: Tilawa and Quran.com",
                   detail: "Credit for the Word of the Day curation (149 words, their themes interleaved) goes to my friend Jamil Hammoudeh, who chose them for Tilawa and gave his permission to bring them here; each word's gloss is Quran.com's word-by-word English, and every occurrence is located in this app's own Hafs text",
                   url: "https://github.com/jamilhammoudeh/quran-app", group: .quran, keywords: "vocabulary word of the day tilawa gloss"),
        CreditItem(id: "similar-ayahs", title: "Similar Ayahs: qurani.ai, Tilawa and QUL",
                   detail: "Credit for the verified Similar Ayahs matches goes to qurani.ai's similar-ayah corpus; the phrase-overlap matches come from Tilawa's generator, built on the Quranic Arabic Corpus morphology by Kais Dukes; the tinted shared words and further pairs come from the similar-ayah table of the Quranic Universal Library",
                   url: "https://qurani.ai/", group: .quran, keywords: "verses related shared words"),
        CreditItem(id: "qul-mutashabihat", title: "Repeated phrases (Mutashabihat): QUL (Tarteel)",
                   detail: "Credit for the repeated phrases of the Quran, every occurrence with its words marked, goes to the Mutashabihat ul Quran dataset of the Quranic Universal Library by Tarteel",
                   url: "https://qul.tarteel.ai/resources/mutashabihat", group: .quran, keywords: "mutashabihat phrases memorisation hifz"),
        CreditItem(id: "clear-quran-topics", title: "Thematic topics: The Clear Quran",
                   detail: "Credit for the Topics corpus of Browse by Theme (Doctrine, Stories, The Unseen) goes to the thematic index of The Clear Quran by Dr. Mustafa Khattab, via the Quranic Universal Library",
                   url: "https://theclearquran.org/", group: .quran, keywords: "topics themes doctrine stories unseen khattab"),
        CreditItem(id: "quran-ontology", title: "Quranic concepts: Quranic Arabic Corpus ontology",
                   detail: "Credit for the Concepts corpus of Browse by Theme goes to the Quranic Ontology of the Quranic Arabic Corpus by Kais Dukes, via the Quranic Universal Library",
                   url: "https://corpus.quran.com/ontology.jsp", group: .quran, keywords: "concepts ontology named entities"),
        CreditItem(id: "qul-index", title: "Topic index, passage themes and mushaf divisions: QUL (Tarteel)",
                   detail: "Credit for the general A-Z topic index, the passage themes (one line per run of ayahs) and the hizb, ruku and manzil boundaries goes to the Quranic Universal Library by Tarteel",
                   url: "https://qul.tarteel.ai/", group: .quran, keywords: "index passages themes hizb ruku manzil"),
        CreditItem(id: "qsac-themes", title: "Browse by Theme topics: QSAC by Ahmad Bilal",
                   detail: "Credit for the Browse by Theme topics goes to the Quran Semantic Annotation Corpus (QSAC) by Ahmad Bilal, used under CC BY 4.0",
                   url: "https://github.com/dev-ahmadbilal/quran-semantic-annotation-corpus", group: .quran, keywords: "topics themes subjects"),
        CreditItem(id: "surah-info", title: "Surah Info: Quran.com (Quran Foundation)",
                   detail: "Credit for the Surah Info goes to Quran.com (Quran Foundation)",
                   url: "https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/get-chapter-info/#get-chapter-info", group: .quran, keywords: "about this surah chapter"),

        CreditItem(id: "quranpedia-outlines", title: "Surah outlines: Quranpedia",
                   detail: "Credit for the surah outlines (the Outline source in About this Surah) goes to Quranpedia",
                   url: "https://quranpedia.net/", group: .quran, keywords: "surah info sections"),
        CreditItem(id: "tafsir-api", title: "English Tafsir API: Quran API Pages",
                   detail: "Credit for the English Tafsir API goes to Quran API Pages",
                   url: "https://quranapi.pages.dev/", group: .quran, keywords: "tafseer commentary"),
        CreditItem(id: "arabic-tafsir-api", title: "Arabic Tafsirs: Tafsir API by spa5k",
                   detail: "Credit for the Arabic Tafsirs (Ibn Kathir, al-Tabari, as-Sa'di) goes to the Tafsir API by spa5k, built from QUL (Tarteel) data",
                   url: "https://github.com/spa5k/tafsir_api", group: .quran, keywords: "tafseer commentary ibn kathir tabari saadi"),
        CreditItem(id: "tajweed-lessons", title: "Tajweed Lessons course: Jamil Hammoudeh (Tilawa)",
                   detail: "Credit for the Tajweed Lessons course (every chapter, lesson, drill, and example) goes to my friend Jamil Hammoudeh, who wrote it for Tilawa and gave his permission to bring it here",
                   url: "https://github.com/jamilhammoudeh/quran-app", group: .quran, keywords: "tajwid rules course"),
        CreditItem(id: "tilawa-theme-wash", title: "Theme wash and share backdrops: Tilawa",
                   detail: "Credit for lighting the ayahs of a theme in the reader (the theme wash) and for the four share backdrop designs goes to Tilawa, by my friend Jamil Hammoudeh, with his permission; the wash here is fainter than Tilawa's, like the bookmark highlighter",
                   url: "https://github.com/jamilhammoudeh/quran-app", group: .quran, keywords: "highlight theme wash share image backdrop tilawa"),
        CreditItem(id: "tilawa-ranked-search", title: "Ranked search lanes: Tilawa",
                   detail: "Credit for the ranked, forgiving search of the Quran and the hadith shelf (stems, spelling correction, consonant skeletons and the strict-then-relaxed passes) goes to Tilawa's search engines, by my friend Jamil Hammoudeh, ported with his permission onto this app's own indexes",
                   url: "https://github.com/jamilhammoudeh/quran-app", group: .quran, keywords: "search ranked typo correction skeleton tilawa"),
        CreditItem(id: "tilawa-daily", title: "Reminder of the Day, Names depth, hadith topics, qiraat clips: Tilawa",
                   detail: "Credit for the Reminder of the Day corpus, the themes, roots, explanations and living lines behind the 99 Names, the hadith topic library, the paired riwayah recordings table, and the reminder kinds goes to my friend Jamil Hammoudeh, who built them for Tilawa and gave his permission to bring them here; the Quran and hadith text in every one of them is this app's own",
                   url: "https://github.com/jamilhammoudeh/quran-app", group: .quran, keywords: "tilawa daily reminder names topics qiraat audio streak"),

        // Hadith
        CreditItem(id: "hadith-json", title: "Hadith collections: hadith-json by Ahmed Baset",
                   detail: "Credit for the Hadith collections goes to hadith-json by Ahmed Baset",
                   url: "https://github.com/AhmedBaset/hadith-json", group: .hadith, keywords: "bukhari muslim books"),
        CreditItem(id: "hadith-restored", title: "Restored English narrations: sunnah.com scrapes",
                   detail: "The English narrations that hadith-json truncated are restored from the clean scrapes of fawazahmed0/hadith-api and CheeseWithSauce/HadithsJSONFormat; all of them trace back to sunnah.com",
                   url: "https://sunnah.com", group: .hadith, keywords: "translation english text"),
        CreditItem(id: "hadith-gradings", title: "Hadith gradings and numbering: sunnah.com",
                   detail: "The scholar gradings (sahih, hasan, da'if) and the standard hadith numbering shown throughout the app also come from those two scrapes of sunnah.com, which quotes the published verdicts of Al-Albani, Zubair Ali Zai, Ahmad Muhammad Shakir, Shuaib Al Arnaut, the Darussalam editors, and others",
                   url: "https://sunnah.com", group: .hadith, keywords: "grade authentic weak albani"),

        // Islam
        CreditItem(id: "names-of-allah", title: "99 Names of Allah: MyIslam",
                   detail: "Credit for the 99 Names of Allah goes to MyIslam",
                   url: "https://myislam.org/99-names-of-allah/", group: .islam, keywords: "asma ul husna"),
        CreditItem(id: "hisn-al-muslim", title: "Hisn al-Muslim: islamic.app and hisnmuslim.com",
                   detail: "Credit for the Hisn al-Muslim texts, transliterations, translations and references goes to the Dhikr API of islamic.app; the recitations stream from hisnmuslim.com; the library came to the app from Tilawa, by my friend Jamil Hammoudeh, with his permission",
                   url: "https://www.hisnmuslim.com/", group: .islam, keywords: "fortress of the muslim dua dhikr audio tilawa"),
        CreditItem(id: "miracles-of-quran", title: "Miracles of the Quran: miracles-of-quran.com and Tilawa",
                   detail: "Credit for the two hundred Miracles of the Quran articles goes to miracles-of-quran.com, whose author waived rights on the site's own prose; the illustrations stream from Tilawa's copy, by my friend Jamil Hammoudeh, with his permission, and third-party excerpts are kept short and attributed to their sources",
                   url: "https://www.miracles-of-quran.com/", group: .islam, keywords: "science miracles articles tilawa"),
        CreditItem(id: "islamqa", title: "Islam articles further reading: IslamQA",
                   detail: "Credit for the further-reading answers the Islam articles link out to goes to IslamQA; the articles themselves are written for this app and cite the classical works by name",
                   url: "https://islamqa.info/en", group: .islam, keywords: "fatwa answers questions articles further reading"),
        CreditItem(id: "hadeeth-encyclopedia", title: "Hadith Encyclopedia: hadeethenc.com",
                   detail: "Credit for the Hadith Encyclopedia's 2,328 narrations with their explanations, lessons, gradings and sources goes to hadeethenc.com, prepared under the supervision of the Dawah and Guidance Association and the Association for Serving Islamic Content in Languages, reproduced without modification of the narrations; the pack was assembled from Tilawa's capture, by my friend Jamil Hammoudeh, with his permission",
                   url: "https://hadeethenc.com/", group: .islam, keywords: "encyclopedia explained hadeeth enc tilawa"),
        CreditItem(id: "tilawa-journal", title: "Islamic Journal: Tilawa",
                   detail: "Credit for the Islamic Journal (its kinds, prompts, tags, attachments and the margin notes drawn from bookmarks) goes to Tilawa, by my friend Jamil Hammoudeh, with his permission; every entry stays on this device",
                   url: "https://github.com/jamilhammoudeh/quran-app", group: .islam, keywords: "journal notes khutbah tilawa"),
    ]

    static let byID: [String: CreditItem] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    /// The credits of one group, in the order `all` lists them.
    static func inGroup(_ group: Group) -> [CreditItem] {
        all.filter { $0.group == group }
    }

    /// The groups this app actually credits, in `Group`'s own order. An app that ships no
    /// hadith books contributes no hadith credits, so that section never appears.
    static let groupsPresent: [Group] = Group.allCases.filter { !inGroup($0).isEmpty }

    /// Case- and diacritic-insensitive, the Settings search's folding.
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// True when every word of the query appears in the title, the line or the keywords.
    func matches(_ terms: [String]) -> Bool {
        let haystack = Self.fold("\(title) \(detail) \(keywords)")
        return terms.allSatisfy { haystack.contains($0) }
    }
}

struct CreditsView: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.presentationMode) private var presentationMode

    /// True as the sheet the Settings tab presents (its own NavigationView + dismiss X); false when
    /// PUSHED from a Settings search result, where the surrounding navigation provides the chrome.
    var presentedAsSheet: Bool = true
    /// A credit to land on (`CreditItem.id`): a Settings search result opens the page scrolled to it.
    var scrollTo: String? = nil

    /// The page's own search: credits, apps and bots whose text carries every word typed. Results
    /// replace the page while a query is typed, the Islam tab's grammar.
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The row a result asked to scroll to, consumed once the search has cleared.
    @State private var scrollTarget: String?
    /// The row tinted for a moment after a landing, so the reader sees which credit they searched for.
    @State private var highlighted: String?

    var body: some View {
        if presentedAsSheet {
            NavigationView {
                creditsList
                    // Dismisses through the same X every other sheet uses, instead of a full-width "Done"
                    // button pinned over the bottom of the content.
                    .sheetDismissToolbar()
            }
            .navigationViewStyle(.stack)
        } else {
            creditsList
        }
    }

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var creditsList: some View {
        ScrollViewReader { proxy in
            List {
                if query.isEmpty {
                    headerSection
                    storySection
                    versionSection
                    creditsLinksSection
                    appsSection
                    botsSection
                    intentSection
                } else {
                    searchResults
                }
            }
            .applyConditionalListStyle()
            .navigationTitle("Credits")
            // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
            .collapseBarsOnScroll($barsCollapsed)
            .adaptiveSafeArea(edge: .bottom) {
                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)),
                          placeholder: "Search credits")
                    .minimizedBarStyle(barsCollapsed)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
            }
            .onChange(of: searchText) { text in
                if !text.isEmpty { scrollTarget = nil }
            }
            .onChange(of: scrollTarget) { target in
                guard let target else { return }
                // The result rows are still animating out; scroll once the page is back.
                land(on: target, proxy: proxy, after: 0.2)
            }
            .onAppear {
                #if DEBUG
                // `-creditsSearch <query>`: seeds the page's search a moment after it appears.
                let arguments = ProcessInfo.processInfo.arguments
                if let idx = arguments.firstIndex(of: "-creditsSearch"), arguments.indices.contains(idx + 1), searchText.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { searchText = arguments[idx + 1] }
                }
                #endif
                guard let scrollTo, let item = CreditItem.byID[scrollTo] else { return }
                // The pushed page lays its rows out first; scrolling in the same frame lands on nothing.
                land(on: item.rowID, proxy: proxy, after: 0.45)
            }
        }
    }

    /// Jumps to a row three times a third of a second apart (the article pages' rule, `ArticleScroll`: an
    /// animated scroll measures rows on its way and overshoots a far row, a jump lands and the next jump
    /// corrects from the measured layout) and tints the row for a moment once it has settled.
    private func land(on rowID: String, proxy: ScrollViewProxy, after delay: Double) {
        for step in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(step) * 0.35) {
                proxy.scrollTo(rowID, anchor: .center)
                guard step == 2 else { return }
                withAnimation(.easeInOut(duration: 0.3)) { highlighted = rowID }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        if highlighted == rowID { highlighted = nil }
                    }
                }
            }
        }
    }

    /// The landing tint: the accent, faint, on the row a search asked for.
    private func landingBackground(_ rowID: String) -> Color? {
        highlighted == rowID ? settings.accentColor.color.opacity(0.16) : nil
    }

    // MARK: - Search

    /// Clears the search and scrolls the page to `rowID`, the Quran list's "Scroll To" grammar.
    private func scrollToRow(_ rowID: String) {
        settings.hapticFeedback()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation { searchText = "" }
        scrollTarget = rowID
    }

    private var terms: [String] {
        CreditItem.fold(query).split(separator: " ").map(String.init).filter { !$0.isEmpty }
    }

    @ViewBuilder
    private var searchResults: some View {
        let words = terms
        let credits = CreditItem.all.filter { $0.matches(words) }
        let apps = appsByAbubakr.filter { app in words.allSatisfy { CreditItem.fold(app.title).contains($0) } }
        let bots = botsByAbubakr.filter { bot in words.allSatisfy { CreditItem.fold(bot.title).contains($0) } }

        if credits.isEmpty, apps.isEmpty, bots.isEmpty {
            Section {
                Text("Nothing in the credits matches your search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }

        if !credits.isEmpty {
            Section(header: SectionPillHeader(title: "CREDITS", count: credits.count)) {
                ForEach(credits) { item in
                    creditResultRow(item)
                }
            }
        }

        if !apps.isEmpty {
            Section(header: SectionPillHeader(title: "APPS", count: apps.count)) {
                ForEach(apps) { app in
                    AppLinkRow(imageName: app.imageName, title: app.title, url: app.url, query: query)
                        .creditRowActions(label: "Scroll To App") { scrollToRow(Self.appRowID(app)) }
                }
            }
        }

        if !bots.isEmpty {
            Section(header: SectionPillHeader(title: "DISCORD BOTS", count: bots.count)) {
                ForEach(bots) { bot in
                    AppLinkRow(imageName: bot.imageName, title: bot.title, url: bot.url, query: query)
                        .creditRowActions(label: "Scroll To Bot") { scrollToRow(Self.botRowID(bot)) }
                }
            }
        }
    }

    /// A credit as a search result: the line with the match coloured. Tapping opens the link, as on the
    /// page; the menu and the trailing swipe scroll the page back to the credit's own row.
    @ViewBuilder
    private func creditResultRow(_ item: CreditItem) -> some View {
        if let destination = URL(string: item.url) {
            Link(destination: destination) {
                HighlightedSnippet(
                    source: item.detail,
                    term: query,
                    font: .body,
                    accent: settings.accentColor.color,
                    fg: .primary
                )
                .padding(.vertical, 2)
            }
            .creditRowActions(label: "Scroll To Credit", copyURL: item.url) { scrollToRow(item.rowID) }
        }
    }

    private static func appRowID(_ app: AppItem) -> String { "app_\(app.title)" }
    private static func botRowID(_ bot: AppItem) -> String { "bot_\(bot.title)" }

    // MARK: - The page

    private var headerSection: some View {
        VStack(alignment: .center, spacing: 10) {
            // The app icon as the hero, in the splash screen's card language.
            Image(AppIdentifiers.appName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(settings.accentColor.color.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: settings.accentColor.color.opacity(0.35), radius: 14, x: 0, y: 6)
                .padding(.top, 6)

            Text(AppIdentifiers.appName)
                .font(.title2.bold())

            Text("Created by Abubakr Elmallah (أَبُوبَكر المَلَّاح), a 17-year-old high school student when the app launched on July 26, 2023.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            if let url = URL(string: "https://abubakrelmallah.com/") {
                Link(destination: url) {
                    Text("abubakrelmallah.com")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .conditionalGlassEffect()
                .contextMenu {
                    Text("Copy")
                        .foregroundStyle(.secondary)

                    Button {
                        settings.hapticFeedback()
                        UIPasteboard.general.string = "https://abubakrelmallah.com/"
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Website")
                        }
                    }
                }
            }

            ornamentalDivider
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
    }

    /// The plain accent line, dressed up: gradient strands fading toward the edges around a small
    /// sparkle - the AI sections' motif, doubling as a signature.
    private var ornamentalDivider: some View {
        HStack(spacing: 10) {
            LinearGradient(
                colors: [.clear, settings.accentColor.color.opacity(0.55)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1.5)
            .clipShape(Capsule())

            Image(systemName: "sparkle")
                .font(.caption2)
                .foregroundColor(settings.accentColor.color)

            LinearGradient(
                colors: [settings.accentColor.color.opacity(0.55), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1.5)
            .clipShape(Capsule())
        }
        .accessibilityHidden(true)
    }

    private var storySection: some View {
        Section {
            ProseText(text: """
            This app was inspired by my desire to help new reverts and non-Muslims learn about Islam and easily access the Quran and prayer times. I’m deeply grateful to my parents for instilling in me a love for the faith (may Allah reward them).

            I also want to express my gratitude to my high school teacher, Mr. Joe Silvey, who, despite not being Muslim, stood with our Muslim Student Association and helped us organize weekly Jumuah prayers.
            """)

            let urlText = "https://github.com/TheAbubakrAbu/Al-Islam-iOS"
            if let url = URL(string: urlText) {
                Link(
                    "View the source code: \(urlText)",
                    destination: url
                )
                .font(.body)
                .foregroundColor(settings.accentColor.color)
                .contextMenu {
                    Text("Copy")
                        .foregroundStyle(.secondary)

                    Button {
                        settings.hapticFeedback()
                        UIPasteboard.general.string = urlText
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Website")
                        }
                    }
                }
            }
        }
    }

    private var versionSection: some View {
        Section {
            VersionNumber()
                .font(.caption)
                .padding(.vertical, 2)
        }
    }

    /// The credited sources, one section per `CreditItem.Group`: prayer times, then Quran, then
    /// hadith, then the Islam tab. It was a single flat list of every credit until 2026-09-16;
    /// fifty-one rows under one header gave a reader no way to find the one they were after.
    /// A group with no credits in this app is skipped rather than printed empty.
    @ViewBuilder
    private var creditsLinksSection: some View {
        ForEach(CreditItem.groupsPresent, id: \.self) { group in
            Section(header: Text(group.rawValue.uppercased())) {
                ForEach(CreditItem.inGroup(group)) { item in
                    creditLink(item)
                        .id(item.rowID)
                        .listRowBackground(landingBackground(item.rowID))
                }
                .foregroundColor(settings.accentColor.color)
                .font(.body)
            }
        }
    }

    private var appsSection: some View {
        Section(header: Text("APPS BY ABUBAKR ELMALLAH")) {
            ForEach(appsByAbubakr) { app in
                AppLinkRow(imageName: app.imageName, title: app.title, url: app.url)
                    .id(Self.appRowID(app))
                    .listRowBackground(landingBackground(Self.appRowID(app)))
            }
        }
    }

    private var botsSection: some View {
        Section(header: Text("DISCORD BOTS BY ABUBAKR ELMALLAH")) {
            ForEach(botsByAbubakr) { bot in
                AppLinkRow(imageName: bot.imageName, title: bot.title, url: bot.url)
                    .id(Self.botRowID(bot))
                    .listRowBackground(landingBackground(Self.botRowID(bot)))
            }
        }
    }

    private var intentSection: some View {
        Section(header: Text("A NOTE ON INTENT")) {
            ProseText(text: "This app is offered as *sadaqah jariyah*, a contribution for the benefit of the Muslim community and anyone building tools to read, learn, and listen to the Quran. If it helps you, please keep the chain of attribution intact and consider contributing improvements back.")
        }
    }

    @ViewBuilder
    private func creditLink(_ item: CreditItem) -> some View {
        if let destination = URL(string: item.url) {
            Link(item.detail, destination: destination)
                .contextMenu {
                    Text("Copy")
                        .foregroundStyle(.secondary)

                    Button {
                        settings.hapticFeedback()
                        UIPasteboard.general.string = item.url
                    } label: {
                        Label("Copy Link", systemImage: "doc.on.doc")
                    }
                }
        }
    }
}

/// The Quran list's row grammar on a Credits search result: a context menu (scroll to the row's place on
/// the page, copy the link) and a trailing swipe whose arrow does the same scroll.
private struct CreditRowActions: ViewModifier {
    let label: String
    let copyURL: String?
    let onScrollTo: () -> Void

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Text("Credit Actions")
                    .foregroundStyle(.secondary)

                Button {
                    onScrollTo()
                } label: {
                    Label(label, systemImage: "arrow.down.circle")
                }

                if let copyURL {
                    Divider()

                    Button {
                        Settings.shared.hapticFeedback()
                        UIPasteboard.general.string = copyURL
                    } label: {
                        Label("Copy Link", systemImage: "doc.on.doc")
                    }
                }
            }
            .swipeActions(edge: .trailing) {
                Button {
                    onScrollTo()
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
    }
}

private extension View {
    func creditRowActions(label: String, copyURL: String? = nil, onScrollTo: @escaping () -> Void) -> some View {
        modifier(CreditRowActions(label: label, copyURL: copyURL, onScrollTo: onScrollTo))
    }
}

let appsByAbubakr: [AppItem] = [
    AppItem(imageName: "Al-Adhan", title: "Al-Adhan | Prayer Times", url: "https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493?platform=iphone"),
    AppItem(imageName: "Al-Islam", title: "Al-Islam | Islamic Pillars", url: "https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655?platform=iphone"),
    AppItem(imageName: "Al-Quran", title: "Al-Quran | Beginner Quran", url: "https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373?platform=iphone"),
    AppItem(imageName: "Aurebesh", title: "Aurebesh Translator", url: "https://apps.apple.com/us/app/aurebesh-translator/id6670201513?platform=iphone"),
    AppItem(imageName: "Datapad", title: "Datapad | Aurebesh Translator", url: "https://apps.apple.com/us/app/datapad-aurebesh-translator/id6450498054?platform=iphone"),
]

let botsByAbubakr: [AppItem] = [
    AppItem(imageName: "SabaccDroid", title: "Sabacc Droid", url: "https://discordbotlist.com/bots/sabaac-droid"),
    AppItem(imageName: "AurebeshDroid", title: "Aurebesh Droid", url: "https://discordbotlist.com/bots/aurebesh-droid")
]

struct AppItem: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let url: String
}

struct AppLinkRow: View {
    @ObservedObject var settings = Settings.shared
    
    var imageName: String
    var title: String
    var url: String
    /// A search query to colour in the title (the Credits page's results); empty on the page itself.
    var query: String = ""

    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(12)
                .frame(width: 50, height: 50)
                .padding(.trailing, 8)

            if let destination = URL(string: url) {
                Link(destination: destination) {
                    HighlightedSnippet(
                        source: title,
                        term: query,
                        font: .subheadline,
                        accent: settings.accentColor.color,
                        // The page's rows read in the accent, a Link's own colour; a result row goes
                        // primary so the accent-coloured match stands out.
                        fg: query.isEmpty ? settings.accentColor.color : .primary
                    )
                }
            }
        }
        .contextMenu {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = url
            } label: {
                Label("Copy Website", systemImage: "doc.on.doc")
            }
        }
    }
}

extension SettingsSearchEntry {
    /// The Credits page's rows in the Settings search: the page itself, then one row per credited source,
    /// each opening the page scrolled to that credit - so "kfgqpc", "hijazi" or "sunnah.com" typed into
    /// the Settings search finds the credit that names it.
    static let creditEntries: [SettingsSearchEntry] =
        [.init(title: "Credits & Contact", path: "Credits",
               keywords: "about version website email review sources attribution licenses thanks", destination: .credits)]
        + CreditItem.all.map {
            .init(title: $0.title, path: "Credits \u{2192} \($0.group.rawValue)",
                  keywords: "\($0.detail) \($0.keywords)", destination: .credit($0.id))
        }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        CreditsView()
    }
}
#endif
