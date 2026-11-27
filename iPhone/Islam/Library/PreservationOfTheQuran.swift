import SwiftUI

// Preservation of the Quran: how it was revealed, memorised, written, compiled and kept.
// Written 2026-11-24 (Abu: "Add these new Islamic resources"), Sunni upon the way of the Salaf, and held
// to the app's rules: every ayah a `.ayah(` reference into the bundled Quran, every hadith a `.hadith(`
// reference into the bundled shelf graded sahih or hasan, scholars' words quoted only with their source.
// The chapters are catalog articles (`IslamArticleCatalog`, home `.preservation`), drawn by
// IslamLibraryView, so search, the Ask AI corpus and each page's own search reach them.

// MARK: - preservation-1

struct PreservationStagesView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "PreservationStagesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Revealed in Stages")
        .englishArticle().selectableArticleList(article: "PreservationStagesView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran did not arrive as a finished book. Allah sent it down on a single blessed night in Ramadan, and then to the Prophet Muhammad (peace and blessings be upon him) a few aayaat at a time over about twenty-three years, beginning with five aayaat in the cave of Hira and ending in his final months. Much of it came in answer to events and questions, some of it before the Hijrah and some after, and its laws arrived step by step, as the ban on wine shows. Knowing how it came down explains why it reads as it does, and why the people who first heard it could carry it."),
        ]),
        ArticleSection("TWENTY-THREE YEARS", [
            .text("The revelation began when the Prophet Muhammad (peace and blessings be upon him) was forty years old and ended shortly before his death. Abdullah ibn Abbaas (may Allah be pleased with them both), who was born in Makkah a few years before the Hijrah and was a youth in Madinah when it ended, summed up the whole span in one sentence:"),
            .hadith("bukhari:3851", cite: "Saheeh al-Bukhaari 3851", arabic: 20...46, english: [0...38]),
            .stats([ArticleStat("40", "his age when it began"), ArticleStat("13", "years in Makkah"), ArticleStat("10", "years in Madinah"), ArticleStat("6,236", "aayaat in the Kufan count")]),
            .text("Thirteen years and ten make about twenty-three years from the first aayaat to the last, ending with his death in 11 AH (632 CE). The Quran itself describes this pace. It was divided, sent down in portions, and recited to people over a long stretch of time, so that they could take each part in before the next arrived:"),
            .ayah("17:106"),
            .text("His enemies thought the slowness was a weakness. A real book from God, they said, would come down all at once, as the earlier scriptures had come down. Allah answered the objection and named two of its reasons in the same breath: to make the Prophet’s heart firm, and to answer every argument they raised with the truth at the very moment they raised it:"),
            .ayah("25:32-33"),
            .longOnly(.markdown("The Arabic word for this way of sending down is **tanjeem (تَنجِيم)**, from **najm**, an instalment, the word the Arabs used for a debt paid off in portions. The Quran was paid out, so to speak, in instalments: sometimes a single ayah, sometimes ten, sometimes a whole surah at once.")),
        ]),
        ArticleSection("SENT DOWN ON A BLESSED NIGHT", [
            .text("Yet the Quran also says that it was sent down in a single night, and names the night and the month:"),
            .ayah("97:1"),
            .longOnly(.ayah("44:3")),
            .ayah("2:185", words: 0...5),
            .longOnly(.text("The scholars of tafseer explain that there were two descents. The first was all at once, from the Preserved Tablet to the lowest heaven, on Laylat al-Qadr. The second was in parts, to the Prophet (peace be upon him), as events required, over the years of his mission. Ibn Katheer (may Allah have mercy on him) reports it from Ibn Abbaas under the first ayah of Surah al-Qadr:")),
            .longOnly(.quote(text: "“Ibn Abbaas and others said: Allah sent the Quran down all at once from the Preserved Tablet to the House of Might in the lowest heaven, then it came down in parts, according to events, over twenty-three years to the Messenger of Allah.” (Ibn Katheer, Tafseer al-Quran al-Azeem, on 97:1)", arabic: "قَالَ ابنُ عَبَّاسٍ وَغَيرُهُ: أَنزَلَ اللَّهُ القُرآنَ جُملَةً وَاحِدَةً مِنَ اللَّوحِ المَحفُوظِ إِلَى بَيتِ العِزَّةِ مِنَ السَّمَاءِ الدُّنيَا، ثُمَّ نَزَلَ مُفَصَّلًا بِحَسَبِ الوَقَائِعِ فِي ثَلَاثٍ وَعِشرِينَ سَنَةً عَلَى رَسُولِ اللَّهِ", dimmed: true)),
            .longOnly(.text("The report from Ibn Abbaas is recorded with its chain by al-Haakim and by an-Nasaa’i in his larger Sunan, and al-Haakim graded it saheeh. Some of the Salaf, among them ash-Sha‘bi, read the aayaat a little differently: that the revelation began on Laylat al-Qadr. The two readings do not clash. On either one, the night of Ramadan is when the Quran first came down from on high, and the instalments that followed are what the Companions lived through.")),
            .shortOnly(.text("The scholars of tafseer explain that there were two descents. The first was all at once, from the Preserved Tablet to the lowest heaven, on Laylat al-Qadr, as Ibn Katheer (may Allah have mercy on him) reports from Ibn Abbaas. The second was in parts, to the Prophet (peace be upon him), as events required, over the years of his mission.")),
            .callout("The Quran was written in the Preserved Tablet before it came down, and it is still the speech of Allah. He spoke it in truth with letters and sound as He wills; Jibreel heard it from Him and brought it down; and it is His uncreated speech, not something created in the Tablet or composed by the angel. The Pure Spirit, Allah says, brought it down **from your Lord** (16:102).", title: "A Point of Creed", icon: "book.closed.fill"),
            .longOnly(.ayah("85:21-22")),
            .ayah("16:102"),
        ]),
        ArticleSection("THE FIRST WORDS", [
            .text("The revelation did not begin with an ayah. It began with dreams. Aa’ishah (may Allah be pleased with her) described the months before the angel came, as the Prophet (peace be upon him) told them to her:"),
            .hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3, Saheeh Muslim 160", arabic: 24...83, english: [0...102]),
            .text("Then the angel came to him in the cave and commanded him to read, and he answered that he could not read. After the angel had pressed him three times, he recited the first five aayaat ever revealed of the Quran:"),
            .ayah("96:1-5"),
            .text("The first word of the revelation was a command to read, and the first blessing it named after creation was the pen. The Book that began with those words would be kept both ways: recited from memory and written with the pen."),
            .longOnly(.markdown("After these aayaat the revelation paused for a time, the **fatrat al-wahy (فَترَة الوَحي)**, and the Prophet longed for it to return. It returned when he saw the same angel seated between the sky and the earth, hurried home asking to be wrapped, and Allah revealed the opening of Surah al-Muddaththir (Saheeh al-Bukhaari 4). From then on, he said, the revelation came warmly and in succession:")),
            .longOnly(.hadith("bukhari:4", cite: "Saheeh al-Bukhaari 4", arabic: 27...68, english: [0...99])),
            .longOnly(.ayah("74:1-5")),
            .longOnly(.text("Jaabir ibn Abdullah (may Allah be pleased with him) used to say that al-Muddaththir was the first surah revealed (Saheeh al-Bukhaari 4922), because the Prophet’s words to him began with that second meeting. The scholars, an-Nawawi (may Allah have mercy on him) among them, reconcile the two reports: the opening of al-Alaq is the first revelation without qualification, as Aa’ishah’s narration shows, and the opening of al-Muddaththir is the first after the pause, and the first command to rise and warn.")),
            .longOnly(.hadith("bukhari:4922", cite: "Saheeh al-Bukhaari 4922", arabic: 13...128, english: [0...172])),
        ]),
        ArticleSection("HOW IT CAME TO HIM", [
            .text("Allah names the ways in which He speaks to a human being:"),
            .ayah("42:51"),
            .longOnly(.text("Revelation can be an inspiration placed in the heart or a true dream; it can be speech from behind a veil, as Allah spoke to Moosa; or Allah can send an angel who conveys His words. The Quran came by the third way, every word of it through Jibreel (peace be upon him), with the Prophet awake and present. Jibreel came to him in different forms. Sometimes he came unseen, with a sound the Prophet likened to the ringing of a bell, which was the hardest form for him; sometimes he came as a man and spoke to him face to face (Saheeh al-Bukhaari 2). Once Umm Salamah (may Allah be pleased with her) saw the Prophet speaking with a man she took for the Companion Dihyah al-Kalbi, and learned later that it had been Jibreel (Saheeh al-Bukhaari 3634).")),
            .shortOnly(.text("Revelation can be an inspiration placed in the heart or a true dream; it can be speech from behind a veil, as Allah spoke to Moosa; or Allah can send an angel who conveys His words. The Quran came by the third way, every word of it through Jibreel (peace be upon him), with the Prophet awake and present.")),
            .longOnly(.hadith("bukhari:2", cite: "Saheeh al-Bukhaari 2", arabic: 23...80, english: [6...80])),
            .longOnly(.hadith("bukhari:3634", cite: "Saheeh al-Bukhaari 3634", arabic: 14...73, english: [0...84])),
            .longOnly(.text("Twice the Prophet saw him as Allah created him. Aa’ishah said that she was the first of this Ummah to ask the Prophet about the two sightings the Quran mentions (53:13, 81:23), and he told her:")),
            .longOnly(.hadith("muslim:177a", cite: "Saheeh Muslim 177", arabic: 97...121, english: [136...187])),
            .longOnly(.ayah("53:13")),
            .longOnly(.ayah("81:23")),
            .longOnly(.text("The Companions could see when revelation was coming down, because its weight showed in his body. Ya‘la ibn Umayyah (may Allah be pleased with him) once asked Umar to let him see the Prophet in that state. At al-Ji‘ranah a man came to ask about ‘umrah in perfumed clothes, and the Prophet fell silent and waited:")),
            .longOnly(.hadith("bukhari:1536", cite: "Saheeh al-Bukhaari 1536, Saheeh Muslim 1180", arabic: 76...101, english: [69...102])),
            .longOnly(.callout("What came down to him at al-Ji‘ranah was not an ayah of the Quran. It was a ruling, which he then gave in his own words: wash off the perfume and do in your ‘umrah what you do in your Hajj. The Sunnah is revelation in its meaning (53:3-4); the Quran is revelation in its words and its meaning together, recited in prayer as worship and set as a challenge no one can meet. Only the Quran was written down by the scribes as revelation.", title: "Not Every Revelation Is Quran", icon: "info.circle.fill")),
            .shortOnly(.text("Not every revelation is Quran. The Sunnah is revelation in its meaning (53:3-4); the Quran is revelation in its words and its meaning together, recited in prayer as worship and set as a challenge no one can meet. Only the Quran was written down by the scribes as revelation.")),
            .ayah("53:3-4"),
            .door(.article("QuranRevealedPillarView")),
        ]),
        ArticleSection("IN ANSWER TO EVENTS", [
            .longOnly(.markdown("Most of the Quran came down without any particular event behind it: the oneness of Allah, the stories of the prophets, the Hereafter. But many passages came in answer to something that had just happened or a question someone had just asked. The scholars call these **asbaab an-nuzool (أَسبَاب النُّزُول)**, the occasions of revelation. The words “they ask you” open an answer fifteen times in the Quran: about the new moons, about spending, about wine, about the spirit, about the Hour. The Companions knew these occasions as eyewitnesses. Abdullah ibn Mas‘ood (may Allah be pleased with him) could say:")),
            .shortOnly(.text("Most of the Quran came down without any particular event behind it: the oneness of Allah, the stories of the prophets, the Hereafter. But many passages came in answer to something that had just happened or a question someone had just asked. The scholars call these asbaab an-nuzool, the occasions of revelation, and the Companions knew them as eyewitnesses.")),
            .longOnly(.hadith("bukhari:5002", cite: "Saheeh al-Bukhaari 5002, Saheeh Muslim 2463", arabic: 21...58, english: [0...75])),
            .text("Some occasions are moving to read. Khawlah bint Tha‘labah (may Allah be pleased with her) came to the Prophet to complain of her husband, who had sworn the old Arab oath that made a wife unlawful to her husband without letting her go. Aa’ishah was in the same room and could not make out her words, yet Allah heard them:"),
            .hadith("ibnmajah:188", cite: "Sunan Ibn Maajah 188; graded saheeh by al-Albaani", arabic: 20...56, english: [0...62]),
            .ayah("58:1"),
            .longOnly(.text("Other occasions guard the meaning of an ayah. Read alone, 2:158 seems to say only that there is no harm in walking between as-Safa and al-Marwah, as though it were optional.")),
            .longOnly(.ayah("2:158")),
            .longOnly(.text("Urwah ibn az-Zubayr read it that way, and his aunt Aa’ishah corrected him from the occasion it came down for:")),
            .longOnly(.hadith("bukhari:1643", cite: "Saheeh al-Bukhaari 1643, Saheeh Muslim 1277", arabic: 49...126, english: [71...205])),
            .longOnly(.text("The Ansaar had felt that walking there was a relic of idolatry, and the ayah lifted their unease. It did not make the walk optional. Ibn Taymiyyah (may Allah have mercy on him) put the principle in one sentence:")),
            .longOnly(.quote(text: "“Knowing the occasion of revelation helps one to understand the ayah, because knowledge of the cause brings knowledge of what it caused.” (Ibn Taymiyyah, Muqaddimah fi Usool at-Tafseer)", arabic: "مَعرِفَةُ سَبَبِ النُّزُولِ يُعِينُ عَلَى فَهمِ الآيَةِ، فَإِنَّ العِلمَ بِالسَّبَبِ يُورِثُ العِلمَ بِالمُسَبَّبِ", dimmed: true)),
            .longOnly(.markdown("Two rules keep this knowledge in its place. The first: **the lesson is in the generality of the words, not the particular occasion**. The aayaat of li‘aan came down when Hilaal ibn Umayyah accused his wife (Saheeh al-Bukhaari 4747), and they apply to every husband after him. The second: an occasion is a report about the past, so it needs a sound chain like any other report, and the Companion’s phrase “this came down about such and such” sometimes means only that the ayah covers that case, as Ibn Taymiyyah explains in the same book.")),
            .longOnly(.hadith("bukhari:4747", cite: "Saheeh al-Bukhaari 4747", arabic: 17...99, english: [0...152])),
            .longOnly(.callout("The story that 9:75-77 came down about a Companion named Tha‘labah ibn Haatib, who begged the Prophet to pray for his wealth and then refused its zakaah, is widely told, but the hadith scholars judged it extremely weak or fabricated, and Tha‘labah ibn Haatib was a Companion who fought at Badr. It is not told here as the occasion of those aayaat.", title: "A Note", icon: "exclamationmark.triangle.fill")),
            .longOnly(.ayah("9:75-77")),
            .shortOnly(.text("Two rules keep this knowledge in its place. The first: the lesson is in the generality of the words, not the particular occasion, so the ayah about Khawlah’s complaint gave the ruling for every man who swears that oath after her husband. The second: an occasion is a report about the past, so it needs a sound chain like any other report.")),
        ]),
        ArticleSection("MAKKAN AND MADINAN", [
            .longOnly(.markdown("The scholars sort the Quran into **Makki (مَكِّيّ)** and **Madani (مَدَنِيّ)**, Makkan and Madinan. The soundest definition goes by time, not by place: whatever came down before the Hijrah is Makkan, even if it came on a journey, and whatever came down after it is Madinan, even if it came down in Makkah itself. So the ayah that completed the religion is Madinan although it came down at Arafah, near Makkah, as Umar ibn al-Khattaab (may Allah be pleased with him) told a Jewish man who said his people would have made that day a festival:")),
            .longOnly(.hadith("bukhari:45", cite: "Saheeh al-Bukhaari 45, Saheeh Muslim 3017", arabic: 60...80, english: [88...115])),
            .longOnly(.ayah("5:3", words: 39...49)),
            .shortOnly(.text("The scholars sort the Quran into Makki and Madani, Makkan and Madinan. The soundest definition goes by time, not by place: whatever came down before the Hijrah is Makkan, and whatever came down after it is Madinan, even if it came down in Makkah itself.")),
            .longOnly(.text("The difference shows in the text. The Makkan surahs, written to a people who worshipped idols, speak above all of the oneness of Allah, the Resurrection, the Paradise and the Fire, and the prophets who were rejected before; their aayaat are often short and strong, full of oaths and of the challenge to produce something like the Quran. The Madinan surahs, written to a community with a city to govern, lay down the laws of worship, marriage, inheritance, trade and war, speak of the hypocrites and of the Jewish tribes of Madinah, and address the believers as “O you who have believed”; their aayaat are often long. Aa’ishah, who was a child in Makkah and a wife in Madinah, remembered both:")),
            .longOnly(.hadith("bukhari:4993", cite: "Saheeh al-Bukhaari 4993", arabic: 105...130, english: [175...231])),
            .longOnly(.text("In the usual count 86 surahs are Makkan and 28 Madinan, the headings printed in most copies today, though the scholars differ over a handful. A heading names the surah by the bulk of its aayaat; a Makkan surah may hold a few Madinan aayaat, and the reverse. Knowing which came first matters most where a later ruling replaces an earlier one, which is the subject of its own chapter.")),
            .shortOnly(.text("The difference shows in the text. The Makkan surahs, written to a people who worshipped idols, speak above all of the oneness of Allah, the Resurrection and the prophets who were rejected before, often in short, strong aayaat. The Madinan surahs, written to a community with a city to govern, lay down the laws of worship, marriage, inheritance, trade and war, in aayaat that are often long. In the usual count 86 surahs are Makkan and 28 Madinan.")),
            .door(.article("PreservationNaskhView")),
        ]),
        ArticleSection("STEP BY STEP", [
            .text("Revelation in stages was also a way of teaching. Aa’ishah explained it to a man from Iraq who wanted to arrange his copy of the Quran by hers:"),
            .hadith("bukhari:4993", cite: "Saheeh al-Bukhaari 4993", arabic: 57...104, english: [79...174]),
            .longOnly(.text("Faith came first, and the laws followed once hearts were ready for them. Wine is the clearest example, because the Arabs loved it and their poetry praised it. A Makkan ayah only set intoxicants apart from “good provision” (16:67).")),
            .longOnly(.ayah("16:67")),
            .longOnly(.text("In Madinah came the first ruling, that its sin is greater than its benefit; then a command not to come to prayer drunk, which left only a few hours of the day free; and finally the command to avoid it altogether:")),
            .longOnly(.ayah("2:219", words: 1...14)),
            .longOnly(.ayah("4:43", words: 0...11)),
            .shortOnly(.text("Faith came first, and the laws followed once hearts were ready for them. Wine is the clearest example, because the Arabs loved it and their poetry praised it. In Madinah came the first ruling, that its sin is greater than its benefit; then a command not to come to prayer drunk; and finally the command to avoid it altogether:")),
            .ayah("5:90-91"),
            .longOnly(.text("Umar was among those who asked for each step. Each time an ayah came, he was called and it was recited to him, and each time he asked for more until the last one came:")),
            .longOnly(.hadith("abudawud:3670", cite: "Sunan Abi Daawood 3670; graded saheeh by al-Albaani", arabic: 24...121, english: [0...143])),
            .longOnly(.text("When the final ayah came, the city obeyed it at once. Anas ibn Maalik (may Allah be pleased with him) was pouring for the guests at Abu Talhah’s house when the announcement was made:")),
            .longOnly(.hadith("bukhari:2464", cite: "Saheeh al-Bukhaari 2464, Saheeh Muslim 1980", arabic: 22...61, english: [0...59])),
            .checklist([
                "**A firm heart.** The Prophet was answered, consoled and steadied as each trial came (25:32).",
                "**An answer in its moment.** Questions and objections were met while they were still alive.",
                "**A law people could carry.** Rulings came in the order a community could take them on.",
                "**A text people could keep.** A few aayaat at a time could be learned, written and recited before the next arrived.",
                "**A challenge renewed.** Every new passage, recited aloud as it came, was one more piece no one could match.",
            ], title: "Why It Came in Stages", icon: "list.bullet.rectangle.fill"),
        ]),
        ArticleSection("THE LAST TO COME DOWN", [
            .text("The revelation did not slow down as his life drew to its end. Anas said:"),
            .hadith("bukhari:4982", cite: "Saheeh al-Bukhaari 4982, Saheeh Muslim 3016", arabic: 27...53, english: [0...40]),
            .text("Which ayah was the very last, the Companions reported each from what he knew. Ibn Abbaas named the ayah of riba:"),
            .hadith("bukhari:4544", cite: "Saheeh al-Bukhaari 4544", arabic: 19...29, english: [0...18]),
            .longOnly(.ayah("2:278-281")),
            .longOnly(.text("In another report Ibn Abbaas named the ayah that closes this passage, “And fear a Day when you will be returned to Allah” (2:281), and since the two belong to one passage, many scholars, Ibn Hajar among them, take the passage as a whole to be the last of the Quran revealed. Al-Baraa’ ibn Aazib (may Allah be pleased with him) named a different pair:")),
            .longOnly(.hadith("bukhari:4605", cite: "Saheeh al-Bukhaari 4605, Saheeh Muslim 1618", arabic: 17...24, english: [0...36])),
            .longOnly(.text("And Ibn Abbaas tested a student on the last surah to come down complete:")),
            .longOnly(.hadith("muslim:3024a", cite: "Saheeh Muslim 3024", arabic: 49...66, english: [15...41, 43...50])),
            .longOnly(.text("The reports fit together once each “last” is read with its scope. The ayah on inheritance at the end of an-Nisaa’ (4:176) was the last on its subject. Surah at-Tawbah was the last of the long surahs to be completed. Surah an-Nasr was the last to come down whole at one time, and Ibn Abbaas understood it as the news that the Prophet’s work was done and his death was near (Saheeh al-Bukhaari 4970). And the passage on riba ending with 2:281 was among the very last aayaat of all. With his death the revelation ended, and nothing has been added to the Quran since.")),
            .longOnly(.ayah("4:176")),
            .longOnly(.hadith("bukhari:4970", cite: "Saheeh al-Bukhaari 4970", arabic: 57...130, english: [91...272])),
            .shortOnly(.text("The Companions reported the very last revelation each from what he knew, and the reports fit together once each “last” is read with its scope. The passage on riba, which closes with the command to fear a Day when all will be returned to Allah, was among the very last aayaat of all. With his death the revelation ended, and nothing has been added to the Quran since.")),
            .door(.article("PreservationOrderView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**If the Quran came down in pieces, how did each piece find its place?**"),
            .text("The Prophet told his scribes where each new passage belonged, and Jibreel reviewed the whole with him every Ramadan, twice in the last. So the Quran was arranged as it came, not sorted afterwards. The chapter on the order of the aayaat and surahs sets out the evidence."),
            .longOnly(.markdown("**Was any of it revealed outside Makkah and Madinah?**")),
            .longOnly(.text("Yes. The ayah that completed the religion came down at Arafah, and Surah al-Fath came down on the road home from al-Hudaybiyah, which Umar heard the Prophet call dearer to him than everything the sun rises upon (Saheeh al-Bukhaari 4177). Both are classed as Madinan, because the class goes by time, not by place.")),
            .longOnly(.hadith("bukhari:4177", cite: "Saheeh al-Bukhaari 4177", arabic: 105...134, english: [150...201])),
            .longOnly(.markdown("**Does knowing the occasion limit the ayah to the people it came down about?**")),
            .longOnly(.text("No. The occasion explains the ayah; it does not fence it in. The ayah about Khawlah’s complaint gave the ruling for every man who swears that oath after her husband, and the aayaat about wine bind every Muslim, not only the guests at Abu Talhah’s house.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran was sent down from the Preserved Tablet to the lowest heaven on Laylat al-Qadr, and then to the Prophet (peace be upon him) through Jibreel over about twenty-three years, thirteen in Makkah and ten in Madinah. It began with “Read” in the cave of Hira and ended with the aayaat on riba and the Day of return. Much of it answered events as they happened, its Makkan part built faith and its Madinan part built a community upon that faith, and its laws came in the order hearts could carry them. That slow, public descent, a few aayaat at a time before witnesses, is also what made it possible to memorise and write every part of it as it came."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Tanjeem", arabic: "تَنجِيم", meaning: "Sending down **in instalments**, from **najm**, a portion paid at an appointed time: the Quran came down in parts over twenty-three years (17:106)."),
            .term("Asbaab an-Nuzool", arabic: "أَسبَاب النُّزُول", meaning: "The **occasions of revelation**: the events and questions a passage came down in answer to, known only through sound reports from the Companions."),
            .term("Makki and Madani", arabic: "مَكِّيّ وَمَدَنِيّ", meaning: "**Makkan and Madinan**: what came down before the Hijrah and what came down after it, wherever the Prophet was at the time."),
            .term("Fatrat al-Wahy", arabic: "فَترَة الوَحي", meaning: "The **pause in revelation** after the first five aayaat of al-Alaq, which ended with the opening of al-Muddaththir (74:1-5)."),
            .term("Bayt al-Izzah", arabic: "بَيت العِزَّة", meaning: "The **House of Might** in the lowest heaven, to which, Ibn Abbaas said, the whole Quran was sent down on Laylat al-Qadr before it came down in parts."),
        ]),
    ]
}

struct PreservationMemoryView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "PreservationMemoryView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Preserved in the Hearts")
        .englishArticle().selectableArticleList(article: "PreservationMemoryView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran was kept first in memory, and it still is. Allah took upon Himself to gather it in the heart of the Prophet Muhammad (peace and blessings be upon him); Jibreel reviewed it with him every Ramadan, twice in his last; and the Companions learned it from his mouth, taught it to whole tribes, led the prayer by it and died for it in such numbers that no single loss could take any of it away. From them it passed from teacher to student, recited aloud and checked letter by letter, in chains that reach to the reciters of today."),
        ]),
        ArticleSection("MOVE NOT YOUR TONGUE WITH IT", [
            .text("The first heart in which the Quran was kept was the Prophet’s own. In the early days, as Jibreel recited, the Prophet (peace and blessings be upon him) would move his lips with him, hurrying to repeat each word for fear of losing it. Allah told him to stop, and promised to do the keeping Himself:"),
            .ayah("75:16-19"),
            .longOnly(.text("Abdullah ibn Abbaas (may Allah be pleased with them both), who used to move his own lips before his students to show them how the Prophet’s had moved, explained each promise in those aayaat:")),
            .longOnly(.hadith("bukhari:5", cite: "Saheeh al-Bukhaari 5, Saheeh Muslim 448", arabic: 84...134, english: [101...147, 171...177, 213...238])),
            .longOnly(.text("So the method of the Quran was fixed from the start: listen to the whole, then recite it as it was recited. Two more promises came with it. Allah would make him recite and he would not forget, except what Allah Himself willed to remove; and he was not to hasten the recitation before the revelation of a passage was complete:")),
            .shortOnly(.text("So the method of the Quran was fixed from the start: listen to the whole, then recite it as it was recited. And Allah promised that he would recite and not forget, except what Allah Himself willed to remove:")),
            .ayah("87:6-7"),
            .longOnly(.ayah("20:114", words: 4...16)),
        ]),
        ArticleSection("THE REVIEW EACH RAMADAN", [
            .text("Every year in Ramadan the angel who brought the Quran came back to go over it with the Prophet. Ibn Abbaas, describing the Prophet’s generosity in that month, explains when it happened:"),
            .hadith("bukhari:6", cite: "Saheeh al-Bukhaari 6, Saheeh Muslim 2308", arabic: 56...64, english: [29...42]),
            .longOnly(.markdown("The word in the Arabic is **yudaarisuhu (يُدَارِسُهُ)**: they studied it together, each reciting to the other. The Prophet’s own word for it gives the term **mu‘aaradah (مُعَارَضَة)**, presenting the Quran to one another, and in the last year of his life he read a meaning into its doubling that he told only his daughter. Aa’ishah (may Allah be pleased with her) asked Faatimah (may Allah be pleased with her) after his death what he had whispered to her, and she said:")),
            .longOnly(.hadith("bukhari:3623", cite: "Saheeh al-Bukhaari 3623, Saheeh Muslim 2450", arabic: 95...117, english: [115...152])),
            .longOnly(.text("Abu Hurayrah (may Allah be pleased with him) confirms that the review was doubled in that year, and adds that the Prophet’s i‘tikaaf was doubled too, twenty days instead of ten (Saheeh al-Bukhaari 4998). This final review, al-‘ardah al-aakhirah, settled the Quran as it stood at the end of the revelation: what remained, in what words, and in what order. It is said that Zayd ibn Thaabit (may Allah be pleased with him) was present at it, which is one of the reasons later given for his being chosen to gather the Quran after the Prophet’s death.")),
            .shortOnly(.text("Abu Hurayrah (may Allah be pleased with him) confirms that in the last year of the Prophet’s life the review was doubled:")),
            .hadith("bukhari:4998", cite: "Saheeh al-Bukhaari 4998", arabic: 17...46, english: [0...59]),
            .callout("The review came every Ramadan and covered what had come down so far. No passage of the Quran went more than a year without being recited by the Prophet to Jibreel and by Jibreel to the Prophet, and the last review covered the whole.", title: "A Yearly Check", icon: "moon.stars.fill"),
        ]),
        ArticleSection("FROM HIS MOUTH TO THEIRS", [
            .text("The Companions learned the Quran the way the Prophet had: by hearing it recited and reciting it back. Abdullah ibn Mas‘ood (may Allah be pleased with him), who had tended sheep in Makkah and became one of the four the Prophet named as teachers of the Quran, stood up to say how he had learned it:"),
            .hadith("bukhari:5000", cite: "Saheeh al-Bukhaari 5000, Saheeh Muslim 2462", arabic: 17...47, english: [11...56]),
            .longOnly(.text("The Prophet even recited to one Companion by name at Allah’s command. Anas ibn Maalik (may Allah be pleased with him) reports the moment Ubayy ibn Ka‘b (may Allah be pleased with him) learned of it:")),
            .longOnly(.hadith("bukhari:4959", cite: "Saheeh al-Bukhaari 4959, Saheeh Muslim 799", arabic: 27...44, english: [8...54])),
            .longOnly(.text("From the first, learning meant teaching. Before the Prophet reached Madinah, he sent teachers of the Quran ahead of him, and by the time he arrived some of its young people already knew whole surahs. Al-Baraa’ ibn Aazib (may Allah be pleased with him) was one of them:")),
            .longOnly(.hadith("bukhari:3925", cite: "Saheeh al-Bukhaari 3925", arabic: 22...97, english: [0...23, 87...113])),
            .longOnly(.text("The Quran even travelled ahead of the Muslims. Amr ibn Salimah (may Allah be pleased with him) grew up by a watering place on a caravan route, and as a small boy he memorised whatever the travellers repeated of the new revelation. When his tribe accepted Islam, the Prophet told them to let the one who knew most Quran lead them in prayer:")),
            .longOnly(.hadith("bukhari:4302", cite: "Saheeh al-Bukhaari 4302", arabic: 128...147, english: [223...274])),
            .longOnly(.markdown("That rule, that **the one who knows most of the Book of Allah leads the people** (Saheeh Muslim 673), made memorising the Quran a public matter in every mosque. Before the Prophet came to Madinah, Saalim, the freedman of Abu Hudhayfah, led the first emigrants in prayer at Qubaa’ because he knew the most Quran (Saheeh al-Bukhaari 692).")),
            .longOnly(.hadith("muslim:673a", cite: "Saheeh Muslim 673", arabic: 46...71, english: [0...60])),
            .longOnly(.hadith("bukhari:692", cite: "Saheeh al-Bukhaari 692", arabic: 18...43, english: [0...36])),
            .longOnly(.text("And some of the young had all of it. Abdullah ibn Amr (may Allah be pleased with him) said:")),
            .longOnly(.hadith("ibnmajah:1346", cite: "Sunan Ibn Maajah 1346; graded saheeh by al-Albaani", arabic: 29...55, english: [0...40])),
        ]),
        ArticleSection("WHO HAD ALL OF IT", [
            .text("Anas named, in two narrations, the Companions who had gathered the whole Quran in the Prophet’s lifetime:"),
            .hadith("bukhari:5003", cite: "Saheeh al-Bukhaari 5003, Saheeh Muslim 2465", arabic: 18...43, english: [5...37]),
            .longOnly(.hadith("bukhari:5004", cite: "Saheeh al-Bukhaari 5004", arabic: 17...40, english: [0...35])),
            .longOnly(.text("Read carelessly, the two lists look like a weakness: only four people, and not even the same four. The scholars of hadith read them with care. Anas was an Ansaari of the Khazraj, and the first narration says plainly that he was naming men “all of whom were from the Ansaar”; he was speaking of his own people, not counting the whole community. Al-Maazari and al-Qurtubi, as Ibn Hajar reports in his commentary, point out that Anas could only speak of what he knew, and that a report that four people had memorised something does not mean no one else had. Al-Qurtubi adds the decisive fact: seventy men known as “the reciters” were killed at Bi’r Ma‘oonah in the Prophet’s own lifetime.")),
            .shortOnly(.text("Read carelessly, the list looks like a weakness. But Anas was an Ansaari speaking of his own people, and a report that four people had memorised something does not mean no one else had: seventy men known as “the reciters” were killed at Bi’r Ma‘oonah in the Prophet’s own lifetime.")),
            .text("The sources name many others who had the whole Quran by heart before his death, among them Uthmaan, Ali, Ibn Mas‘ood, Saalim and Abdullah ibn Amr, while a far larger number had large parts of it. And every Companion had some of it, because every Companion prayed: the Faatihah in every unit of prayer, and other surahs aloud at dawn, sunset and night, five times a day, year after year."),
            .door(.article("CompileView")),
        ]),
        ArticleSection("THE RECITERS WHO WERE KILLED", [
            .longOnly(.text("The Companions who knew the most Quran were often the first to give their lives, which is itself a measure of how many there were. In 4 AH (625 CE) some Arab tribes asked the Prophet for men to teach them the Quran and the Sunnah (Saheeh Muslim 677), and he sent seventy:")),
            .longOnly(.hadith("bukhari:4090", cite: "Saheeh al-Bukhaari 4090, Saheeh Muslim 677", arabic: 37...57, english: [25...69])),
            .longOnly(.text("After Uhud, the Prophet buried the martyrs two to a grave and asked which of each pair had known more of the Quran, and placed that one first (Saheeh al-Bukhaari 1343).")),
            .longOnly(.hadith("bukhari:1343", cite: "Saheeh al-Bukhaari 1343", arabic: 29...67, english: [0...58])),
            .longOnly(.text("And at al-Yamaamah, in the war against the false prophet Musaylimah in the year after the Prophet’s death, so many reciters fell that Umar ibn al-Khattaab (may Allah be pleased with him) came to Abu Bakr (may Allah be pleased with him) with a fear:")),
            .shortOnly(.text("At al-Yamaamah, in the war against the false prophet Musaylimah in the year after the Prophet’s death, so many reciters fell that Umar ibn al-Khattaab (may Allah be pleased with him) came to Abu Bakr (may Allah be pleased with him) with a fear:")),
            .hadith("bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 49...73, english: [51...114]),
            .longOnly(.text("Umar’s fear was not that the Quran had been lost. Zayd ibn Thaabit went on to gather it, and he found every ayah. It was a fear about the future: that if the reciters kept dying in battle, a time might come when part of it was held by too few. So the Companions, who had memorised it and written it, now bound the written pieces into one volume, checked against the memories of the living. The story of that gathering, and of Uthmaan’s copies after it, has its own page.")),
            .shortOnly(.text("Umar’s fear was not that the Quran had been lost; Zayd ibn Thaabit went on to gather it, and he found every ayah. It was a fear about the future, so the Companions bound the written pieces into one volume, checked against the memories of the living. That story has its own page.")),
        ]),
        ArticleSection("MADE EASY TO REMEMBER", [
            .text("No other book of its length is carried word for word in the memories of so many people, many of whom do not speak its language. Allah says it was made so:"),
            .ayah("54:17"),
            .longOnly(.markdown("The ayah comes four times in Surah al-Qamar (54:17, 22, 32, 40), each time after the story of a nation destroyed for denying its messenger. Elsewhere Allah calls the Quran **clear aayaat in the breasts of those given knowledge**, describing a book whose first home is the memory:")),
            .longOnly(.ayah("29:49")),
            .longOnly(.text("In a sound hadith Allah describes it to His Prophet as a Book that water cannot wash away, which can be recited asleep or awake (Saheeh Muslim 2865).")),
            .longOnly(.hadith("muslim:2865a", cite: "Saheeh Muslim 2865", arabic: 109...123, english: [126...178])),
            .text("Ibn al-Jazari (may Allah have mercy on him), the master of the science of the readings, drew the lesson in the opening of his great book on the ten readings:"),
            .quote(text: "“Reliance in passing on the Quran has been on what is kept in hearts and breasts, not on what is kept in written copies and books, and this is the noblest distinction Allah has given this Ummah.” (Ibn al-Jazari, an-Nashr fi al-Qiraa’aat al-Ashr, 1/6)", arabic: "ثُمَّ إِنَّ الِاعتِمَادَ فِي نَقلِ القُرآنِ عَلَى حِفظِ القُلُوبِ وَالصُّدُورِ لَا عَلَى حِفظِ المَصَاحِفِ وَالكُتُبِ، وَهَذِهِ أَشرَفُ خَصِيصَةٍ مِنَ اللَّهِ تَعَالَى لِهَذِهِ الأُمَّةِ", dimmed: true),
            .longOnly(.text("Memory needs tending, and the Prophet said so in a picture every Arab understood:")),
            .longOnly(.hadith("bukhari:5033", cite: "Saheeh al-Bukhaari 5033, Saheeh Muslim 791", arabic: 24...35, english: [4...31])),
            .longOnly(.text("He also promised a reward to the one who struggles with it as well as to the one who has mastered it:")),
            .longOnly(.hadith("muslim:798a", cite: "Saheeh Muslim 798, Saheeh al-Bukhaari 4937", arabic: 42...57, english: [0...30])),
            .longOnly(.text("And he described the reward of the one who carried it, in words often recited when a student completes the memorisation of the whole:")),
            .longOnly(.hadith("abudawud:1464", cite: "Sunan Abi Daawood 1464; graded hasan saheeh by al-Albaani", arabic: 27...43, english: [6...46])),
            .longOnly(.text("Look at who narrated that hadith in its chain: Aasim ibn Bahdalah, from Zirr ibn Hubaysh. Aasim is the reader of Koofah whose reading, through his student Hafs, most of the world recites today, and Zirr was one of the teachers he read the Quran to.")),
        ]),
        ArticleSection("A CHAIN TO THIS DAY", [
            .longOnly(.text("The memory of the Companions did not stay with them. They taught it, and the teaching was formal: a student recited the Quran to a teacher from beginning to end, and the teacher listened and corrected him. Uthmaan ibn Affaan (may Allah be pleased with him) narrated the Prophet’s words that have become the motto of every Quran school:")),
            .longOnly(.hadith("bukhari:5027", cite: "Saheeh al-Bukhaari 5027", arabic: 36...40, english: [4...17])),
            .longOnly(.text("The man who narrated those words from Uthmaan was Abu Abd ar-Rahman as-Sulami, and in the same report al-Bukhaari records that he went on teaching the Quran from the caliphate of Uthmaan until the time of al-Hajjaaj, for decades, and that he said this hadith was what had seated him in his teaching place. Abu Abd ar-Rahman had read the Quran to Uthmaan, Ali, Zayd ibn Thaabit, Ubayy and Ibn Mas‘ood, and Aasim read it to him. That is the chain of the reading of Hafs from Aasim:")),
            .shortOnly(.text("The memory of the Companions did not stay with them. They taught it, and the teaching was formal: a student recited the Quran to a teacher from beginning to end, and the teacher listened and corrected him. That is how the reading of Hafs from Aasim reached us:")),
            .chain([
                ArticleChainLink("Allah", "who spoke the Quran"),
                ArticleChainLink("Jibreel", "who heard it from Him and brought it down"),
                ArticleChainLink("The Prophet Muhammad ﷺ", "who recited it to his Companions"),
                ArticleChainLink("Uthmaan, Ali, Ubayy, Zayd, Ibn Mas‘ood", "who read it to him and taught it"),
                ArticleChainLink("Abu Abd ar-Rahman as-Sulami and Zirr ibn Hubaysh", "who read it to them in Koofah"),
                ArticleChainLink("Aasim ibn Abi an-Najood (d. 127 AH)", "who read it to both"),
                ArticleChainLink("Hafs ibn Sulaymaan (d. 180 AH)", "who read it to Aasim"),
                ArticleChainLink("Teachers in every generation", "each reciting the whole to the one before"),
            ], caption: "One of the chains of the reading most of the world recites today. Each of the ten readings has chains like it."),
            .longOnly(.markdown("The same thing happens today. A student who has memorised the Quran sits with a teacher who holds a chain, and recites all of it by heart, sometimes over months, while the teacher listens for every letter: a vowel lengthened too much, a letter from the wrong place in the throat, a pause in the wrong place. When the recitation is complete and correct, the teacher grants an **ijaazah (إِجَازَة)**, a licence to recite and teach, naming every teacher back to the Prophet. A saying reported from Zayd ibn Thaabit sums up the rule the reciters follow: **the reading is a Sunnah that is followed**, received from those before and never improvised.")),
            .shortOnly(.text("The same thing happens today. A student who has memorised the Quran recites all of it by heart to a teacher who holds a chain, while the teacher listens for every letter, and when the recitation is complete and correct, the teacher grants an ijaazah, a licence to recite and teach, naming every teacher back to the Prophet.")),
            .longOnly(.text("Alongside the formal chains runs the check of the whole community. The Prophet himself once left out an ayah while leading the prayer, and when a man told him so afterwards, he asked him why he had not reminded him in the prayer (Sunan Abi Daawood 907). An imam who slips today is corrected from the rows behind him before the next ayah, in any mosque in the world, by people who have never met.")),
            .longOnly(.hadith("abudawud:907", cite: "Sunan Abi Daawood 907; graded hasan by al-Albaani", arabic: 35...70, english: [14...71])),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Could the Prophet himself forget an ayah?**"),
            .text("Allah promised that he would not forget except what He willed (87:6-7), and the Sunnah shows what that exception looked like. Aa’ishah reports:"),
            .hadith("bukhari:5038", cite: "Saheeh al-Bukhaari 5038, Saheeh Muslim 788", arabic: 32...44, english: [13...36]),
            .text("The scholars explain that this was a passing lapse of memory in aayaat he had already conveyed, which the Companions were reciting at that very moment, and that he was reminded at once. It shows the very thing this chapter describes: the Quran was never held by one memory alone, not even his. What Allah willed to remove from the Quran altogether, He removed by abrogation, which is the subject of its own chapter."),
            .door(.article("PreservationNaskhView")),
            .longOnly(.markdown("**Why memorise it when printed copies are everywhere?**")),
            .longOnly(.text("Because prayer is performed by reciting from memory, and because memory is what checks the print. A misprinted copy is caught by those who know the text by heart, not the other way round. The scholars count memorising the whole Quran a communal obligation: there must always be enough people who carry it that its transmission stays beyond doubt, while every Muslim must learn at least what his prayer needs.")),
            .longOnly(.markdown("**Do the huffaaz differ from each other?**")),
            .longOnly(.text("Only where the Prophet himself taught more than one way. A reciter of Hafs and a reciter of Warsh differ in the places where the canonical readings differ, and both readings are recorded letter by letter with their chains. Within one reading, two huffaaz in different continents recite the same letters in the same order.")),
            .longOnly(.door(.article("QiraatView"))),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran was kept in memory from its first day. Allah gathered it in the Prophet’s heart, Jibreel reviewed it with him each Ramadan and twice at the end, and the Companions took it from his mouth, taught it to their tribes, prayed with it and died for it in numbers that made its loss impossible. Their students read it back to them in full, and their students’ students, in named chains that run to the reciters of today, while every mosque checks every imam. The written copies matter, and the next chapter tells their story, but they have always been checked against the hearts, not the other way round."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Talaqqi", arabic: "تَلَقِّي", meaning: "**Receiving** the Quran from a teacher’s mouth, by hearing and reciting back, as the Prophet received it from Jibreel and the Companions from the Prophet."),
            .term("Mu‘aaradah", arabic: "مُعَارَضَة", meaning: "The **mutual review**: Jibreel and the Prophet presenting the Quran to one another each Ramadan, twice in his final year (Saheeh al-Bukhaari 3623)."),
            .term("Qurraa’", arabic: "قُرَّاء", meaning: "**The reciters**: in the Companions’ time, the name for those who knew much of the Quran by heart, like the seventy killed at Bi’r Ma‘oonah."),
            .term("Sanad", arabic: "سَنَد", meaning: "The **chain** of teachers through which a reciter received the Quran, each of whom heard the whole of it from the one before, back to the Prophet."),
        ]),
    ]
}

struct PreservationWritingView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "PreservationWritingView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Written in His Lifetime")
        .englishArticle().selectableArticleList(article: "PreservationWritingView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran was written down as it came, not gathered from memory after the fact. The Prophet Muhammad (peace and blessings be upon him) could not read or write, so he kept scribes, and when an ayah came down he called one of them with a board and ink and dictated it. They wrote on whatever would hold ink: palm stalks, flat stones, leather, shoulder blades. For a time he forbade writing anything from him but the Quran, so that nothing would mix with it. By his death all of it was written, spread over many pieces in many hands, and not yet bound into one volume, because revelation could come until his final days."),
        ]),
        ArticleSection("A BOOK FROM THE BEGINNING", [
            .markdown("The Quran calls itself a **kitaab (كِتَاب)**, a book, from the root **ك-ت-ب**, to write, from its earliest surahs. The first five aayaat ever revealed praised the Lord “who taught by the pen” (96:4), and one of the earliest surahs opens with an oath by the pen and what is written with it:"),
            .ayah("68:1"),
            .ayah("96:4"),
            .longOnly(.text("It describes itself as written in honoured sheets, and its Messenger as one who recites purified pages:")),
            .longOnly(.ayah("80:11-16")),
            .longOnly(.ayah("98:2-3")),
            .text("Yet the man who brought it could not write a line. Allah made that a proof: had he been a reader and writer of books, those who wanted to doubt him would have had their excuse:"),
            .ayah("29:48"),
            .longOnly(.text("So the writing of the Quran was done from the start by other hands, as he dictated. Even his enemies in Makkah spoke of writing: their slander was that he had old legends written down, dictated to him morning and evening (25:5). In Makkah the believers were few and those who could write fewer, so less is known of the writing there, but what came down was written, and in Madinah, where the Muslims were many and free, the record is full.")),
            .longOnly(.ayah("25:5")),
            .longOnly(.callout("The famous story that Umar ibn al-Khattaab accepted Islam after reading the opening of Surah Ta Ha on a sheet in his sister’s house is widely told, but its chains are weak, so it is not used here as evidence of writing in Makkah.", title: "A Note", icon: "exclamationmark.triangle.fill")),
            .shortOnly(.text("So the writing of the Quran was done from the start by other hands, as he dictated: in Makkah, where those who could write were few, and in Madinah, where the record is full.")),
        ]),
        ArticleSection("CALL ZAYD", [
            .text("The clearest picture of how an ayah was written comes from al-Baraa’ ibn Aazib (may Allah be pleased with him). When the ayah came down that those who stay at home are not equal to those who strive, the Prophet called for his scribe at once, and the writing was still under way when the revelation came again:"),
            .hadith("bukhari:4990", cite: "Saheeh al-Bukhaari 4990, Saheeh Muslim 1898", arabic: 31...85, english: [28...145]),
            .longOnly(.ayah("4:95", words: 0...7)),
            .longOnly(.text("Three words, “other than the disabled,” came down in answer to a blind man’s question while the scribe sat with the board in front of him, and they were written into their place in the ayah. That is how close the writing was to the revelation: the ink was still wet.")),
            .longOnly(.text("The scribe was Zayd ibn Thaabit (may Allah be pleased with him), an Ansaari who had been a boy when the Prophet reached Madinah. The Prophet trusted his hand so fully that he asked him to learn the script of the Jews of Madinah for the letters of state, and Zayd learned it in half a month:")),
            .longOnly(.hadith("abudawud:3645", cite: "Sunan Abi Daawood 3645; graded hasan saheeh by al-Albaani", arabic: 24...65, english: [0...73])),
            .longOnly(.text("Years later, when Abu Bakr (may Allah be pleased with him) chose the man to gather the Quran into one volume, this was the reason he gave:")),
            .longOnly(.hadith("bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 112...130, english: [175...218])),
            .shortOnly(.text("The scribe was Zayd ibn Thaabit (may Allah be pleased with him), an Ansaari who had been a boy when the Prophet reached Madinah, and whom Abu Bakr later chose to gather the Quran into one volume.")),
        ]),
        ArticleSection("THE SCRIBES OF REVELATION", [
            .longOnly(.markdown("Zayd was the best known of them, but he was not alone. The scholars call them **kuttab al-wahy (كُتَّاب الوَحي)**, the scribes of revelation, and the historians of the Seerah, Ibn Katheer among them, gave whole chapters to their names. Among those who wrote for the Prophet were Ubayy ibn Ka‘b, said to have been the first to write for him in Madinah, Uthmaan ibn Affaan and Ali ibn Abi Taalib (may Allah be pleased with them all). Hanzalah al-Usayyidi is introduced in Saheeh Muslim simply as “one of the scribes of the Messenger of Allah” (Saheeh Muslim 2750). Mu‘aawiyah ibn Abi Sufyaan (may Allah be pleased with him) was taken on as a scribe after the conquest of Makkah, at his father’s request (Saheeh Muslim 2501), and the Ahl as-Sunnah have honoured him ever since as one of the scribes of the revelation.")),
            .longOnly(.hadith("muslim:2750a", cite: "Saheeh Muslim 2750", arabic: 26...57, english: [0...29])),
            .longOnly(.hadith("muslim:2501", cite: "Saheeh Muslim 2501", arabic: 43...78, english: [0...51])),
            .longOnly(.text("Having many scribes meant that no one of them held the text. The Quran was in the memories of the Prophet and of hundreds of Companions before it was on any scribe’s board, and a scribe could only write what everyone was about to hear recited. One scribe learned this in the worst way. Anas ibn Maalik (may Allah be pleased with him) tells of him:")),
            .longOnly(.hadith("bukhari:3617", cite: "Saheeh al-Bukhaari 3617, Saheeh Muslim 2781", arabic: 17...98, english: [0...201])),
            .longOnly(.text("His boast, that Muhammad knew only what he had written for him, was the very slander the Quran had already answered. A scribe takes down what is dictated; he does not compose it. The man’s own people buried him three times and found him cast out each morning, until they knew it was not the work of men.")),
            .shortOnly(.text("Zayd was the best known of the scribes of revelation, the kuttab al-wahy, but he was not alone: among those who wrote for the Prophet were Ubayy ibn Ka‘b, Uthmaan ibn Affaan and Ali ibn Abi Taalib (may Allah be pleased with them all). Having many scribes meant that no one of them held the text. The Quran was in the memories of the Prophet and of hundreds of Companions before it was on any scribe’s board, and a scribe could only write what everyone was about to hear recited.")),
        ]),
        ArticleSection("WHAT THEY WROTE ON", [
            .text("Paper was not yet made in Arabia. The Companions wrote on what their land gave them, and when Zayd later gathered the written Quran he named the materials he collected it from:"),
            .hadith("bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 184...191, english: [303...332]),
            .longOnly(.text("Zayd also described the scene in the Prophet’s presence, with the pieces in front of them:")),
            .longOnly(.hadith("tirmidhi:3954", cite: "Jaami‘ at-Tirmidhi 3954; graded saheeh by al-Albaani", arabic: 33...44, english: [0...14])),
            .checklist([
                "**Usub (عُسُب).** Palm stalks: the broad, leafless base of the date-palm frond, scraped smooth.",
                "**Likhaaf (لِخَاف).** Thin, flat white stones.",
                "**Riqaa‘ (رِقَاع).** Pieces of leather, parchment or cloth.",
                "**Aktaaf (أَكتَاف).** The broad shoulder blades of camels, dried; the “scapula bone” Zayd was told to bring.",
                "**Lawh (لَوح).** A flat board, which Zayd was told to bring with the ink.",
            ], title: "The Materials", icon: "scroll.fill"),
            .longOnly(.markdown("The word Zayd used, **nu’allifu (نُؤَلِّفُ)**, means more than writing: it means putting together, arranging. Al-Bayhaqi and other scholars read it as the Companions composing the pieces into their surahs in the Prophet’s presence, each ayah set where he directed, which is the subject of the next chapter. And the list ends with something that is not a material at all: “the chests of men.” Even when Zayd gathered the written Quran, the writing was checked against memory.")),
            .shortOnly(.text("The Companions also put the pieces together into their surahs in the Prophet’s presence, each ayah set where he directed. And Zayd’s list ends with something that is not a material at all: “the chests of men.” Even when he gathered the written Quran, the writing was checked against memory.")),
        ]),
        ArticleSection("DO NOT WRITE FROM ME ANYTHING BUT THE QURAN", [
            .text("While the Quran was still coming down, the Prophet guarded the written page from anything else. Abu Sa‘eed al-Khudri (may Allah be pleased with him) reports:"),
            .hadith("muslim:3004", cite: "Saheeh Muslim 3004", arabic: 29...41, english: [0...32]),
            .longOnly(.text("He did not forbid narrating his words; he forbade writing them, for a time, beside the revelation. An-Nawawi (may Allah have mercy on him) gives the explanations of the scholars: that the prohibition was meant for the time when writing hadith on the same sheets as the Quran could mix the two; or for those whose memory could be trusted, lest they come to rely on writing; and that it was later lifted. The lifting is recorded. At the conquest of Makkah a man from Yemen asked for the Prophet’s sermon in writing, and he said, “Write it for Abu Shah” (Saheeh al-Bukhaari 2434).")),
            .longOnly(.hadith("bukhari:2434", cite: "Saheeh al-Bukhaari 2434", arabic: 124...149, english: [142...167])),
            .longOnly(.text("And Abdullah ibn Amr (may Allah be pleased with him), who wrote down what he heard, was told by Quraysh to stop:")),
            .longOnly(.hadith("abudawud:3646", cite: "Sunan Abi Daawood 3646; graded saheeh by al-Albaani", arabic: 33...91, english: [0...88])),
            .longOnly(.text("The order of events is the point. In the years when the written Quran was being formed, it was kept apart, so that no Companion would ever find a saying of the Prophet on a sheet and mistake it for an ayah. Once the Quran was known and distinct, the Sunnah could be written too, and it was.")),
            .shortOnly(.text("He did not forbid narrating his words; he forbade writing them, for a time, beside the revelation, so that no Companion would ever find a saying of the Prophet on a sheet and mistake it for an ayah. Once the Quran was known and distinct, the Sunnah could be written too, and it was.")),
        ]),
        ArticleSection("COPIES IN THEIR HANDS", [
            .longOnly(.text("Written Quran was not only kept in the Prophet’s house. The Companions had pages of their own, enough that the Prophet made a rule about carrying them:")),
            .longOnly(.hadith("muslim:1869b", cite: "Saheeh Muslim 1869, Saheeh al-Bukhaari 2990", arabic: 24...36, english: [12...44])),
            .longOnly(.text("A rule against taking the Quran into enemy land, lest it fall into their hands, assumes written copies light enough to carry on a campaign. Some Companions wrote out large parts for themselves. Abdullah ibn Mas‘ood, Ubayy ibn Ka‘b and others kept personal copies, written for their own use, sometimes with a word of explanation beside an ayah and with the surahs in their own order. Those private copies are why Uthmaan (may Allah be pleased with him) later sent out a single standard and retired the rest, a story told on its own page.")),
            .shortOnly(.text("The Companions also had pages of their own. Abdullah ibn Mas‘ood, Ubayy ibn Ka‘b and others kept personal copies for their own use, which is why Uthmaan (may Allah be pleased with him) later sent out a single standard and retired the rest, a story told on its own page.")),
            .door(.article("CompileView")),
            .longOnly(.text("What they left was the Quran and nothing hidden beside it. When two men asked Ibn Abbaas (may Allah be pleased with them both) whether the Prophet had left anything else, and then asked the same of Muhammad ibn al-Hanafiyyah, the son of Ali ibn Abi Taalib, both gave the same answer:")),
            .longOnly(.hadith("bukhari:5019", cite: "Saheeh al-Bukhaari 5019", arabic: 37...56, english: [25...39, 54...68])),
        ]),
        ArticleSection("ALL OF IT, BUT NOT IN ONE VOLUME", [
            .text("By the time the Prophet died, every ayah had been written. What did not yet exist was a single bound volume holding all of them in order, and Zayd’s first reaction when Abu Bakr asked him to make one shows the difference:"),
            .hadith("bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 147...158, english: [248...265]),
            .longOnly(.text("The Prophet had not done it, and the scholars explain why. As long as he lived, revelation could still come: a new passage to be placed inside a surah already written, or an ayah whose recitation Allah would lift. A bound volume would have had to be undone again and again. Al-Khattaabi (may Allah have mercy on him) put it this way:")),
            .longOnly(.quote(text: "“He did not gather the Quran into a single volume because he was waiting for what might come to abrogate some of its rulings or its recitation. When its revelation ended with his death, Allah inspired the rightly guided caliphs to do it, in fulfilment of His true promise to guarantee its preservation for this Ummah.” (al-Khattaabi, as quoted by as-Suyooti in al-Itqaan fi Uloom al-Quran)", arabic: "إِنَّمَا لَم يَجمَعِ القُرآنَ فِي المُصحَفِ لِمَا كَانَ يَتَرَقَّبُهُ مِن وُرُودِ نَاسِخٍ لِبَعضِ أَحكَامِهِ أَو تِلَاوَتِهِ، فَلَمَّا انقَضَى نُزُولُهُ بِوَفَاتِهِ أَلهَمَ اللَّهُ الخُلَفَاءَ الرَّاشِدِينَ ذَلِكَ وَفَاءً لِوَعدِهِ الصَّادِقِ بِضَمَانِ حِفظِهِ عَلَى هَذِهِ الأُمَّةِ", dimmed: true)),
            .shortOnly(.text("The Prophet had not done it, and the scholars explain why. As long as he lived, revelation could still come: a new passage to be placed inside a surah already written, or an ayah whose recitation Allah would lift. A bound volume would have had to be undone again and again.")),
            .longOnly(.text("The revelation came most heavily in his last months (Saheeh al-Bukhaari 4982), so the written Quran was complete only when he was gone. Within about a year of his death, after al-Yamaamah, Abu Bakr had the pages gathered into one volume, and under Uthmaan that volume was copied and sent to the cities. Neither project composed anything. Both copied what had been written in the Prophet’s presence and was known by heart by those who had heard it from him.")),
            .longOnly(.hadith("bukhari:4982", cite: "Saheeh al-Bukhaari 4982, Saheeh Muslim 3016", arabic: 27...53, english: [0...40])),
            .shortOnly(.text("Within about a year of his death Abu Bakr had the pages gathered into one volume, and under Uthmaan that volume was copied and sent to the cities. Neither project composed anything: both copied what had been written in the Prophet’s presence and was known by heart by those who had heard it from him.")),
            .door(.article("PreservationOrderView")),
            .door(.article("PreservationManuscriptsView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**If the Prophet could not read, how could he know the writing was right?**")),
            .longOnly(.text("Because the writing was never the only record. Every passage was recited by him aloud, memorised by many, recited back in prayer, and reviewed with Jibreel every Ramadan. A scribe who wrote a word wrongly would be corrected by the next person who read his page against what he knew by heart. When Zayd gathered the pages after the Prophet’s death, he accepted each written piece only alongside the memories of the living.")),
            .longOnly(.markdown("**Was any ayah known only from a single page?**")),
            .longOnly(.text("No ayah was known only from a page. What Zayd says he found with one man alone, the ending of at-Tawbah with Abu Khuzaymah and an ayah of al-Ahzaab with Khuzaymah ibn Thaabit, was a written piece; of the ayah of al-Ahzaab he says in the same report that he used to hear the Prophet recite it (Saheeh al-Bukhaari 4988). He was looking for the page that had been written, not for an ayah no one knew.")),
            .longOnly(.hadith("bukhari:4988", cite: "Saheeh al-Bukhaari 4988", arabic: 14...51, english: [0...14])),
            .markdown("**Why does it matter that it was written in his lifetime?**"),
            .text("Because a common claim against the Quran is that it was put together long after the Prophet from scattered memories, and the sources say the opposite. The pages Abu Bakr gathered were the pages written at the Prophet’s dictation, by scribes whose names are known, within a year of his death and among thousands who had heard the same words from him. A text written as it was revealed, held in memory at the same time, and gathered by those who wrote it leaves no gap in which a later hand could work. The claims of corruption, and the oldest manuscripts that answer them, have their own chapters."),
            .door(.article("PreservationClaimsView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran was written as it came down. An unlettered Prophet dictated each passage to scribes, Zayd ibn Thaabit foremost among them, who wrote on palm stalks, stones, leather and bone, and the Companions arranged the pieces in his presence. For a time nothing else of his was to be written, so that the written Quran stayed pure; later the Sunnah was written too. Companions carried pages of their own and kept personal copies. At his death the whole of it was written, in many pieces and many hands but not yet in one binding, because the revelation had only just ended. Then Abu Bakr had it gathered, checked against both the pages and the memories of the Companions, between two covers."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Kuttab al-Wahy", arabic: "كُتَّاب الوَحي", meaning: "**The scribes of revelation**: the Companions who wrote down the Quran at the Prophet’s dictation, Zayd ibn Thaabit and Ubayy ibn Ka‘b foremost among them."),
            .term("Suhuf", arabic: "صُحُف", meaning: "**Sheets** or pages, singular **saheefah**: the Quran’s word for the pages that hold it (80:13, 98:2), and the name given to the volume gathered under Abu Bakr."),
            .term("Riqaa‘", arabic: "رِقَاع", meaning: "**Pieces** of leather, parchment or cloth, among the materials the Quran was written on in the Prophet’s presence."),
            .term("Ad-Daffataan", arabic: "الدَّفَّتَان", meaning: "**The two covers** of a bound book. “What is between the two covers” became the Companions’ way of naming the whole written Quran (Saheeh al-Bukhaari 5019)."),
        ]),
    ]
}

struct PreservationOrderView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "PreservationOrderView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Order of the Aayaat and Surahs")
        .englishArticle().selectableArticleList(article: "PreservationOrderView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran is not arranged in the order it came down, and it was never meant to be. The order of the aayaat inside each surah was set by the Prophet Muhammad (peace and blessings be upon him) as revelation came, by the consensus of the scholars, and the Companions would not move a single ayah, not even one whose ruling had been lifted. The order of the surahs is the order the Companions agreed upon in Uthmaan’s copies: the scholars differ over how much of it came from the Prophet and how much from their judgment, and either way the Ummah has been united upon it ever since. This chapter explains both orders, the old groupings of the surahs, and why at-Tawbah alone begins without the basmalah."),
        ]),
        ArticleSection("THREE DIFFERENT ORDERS", [
            .text("Three different orders are easily confused. The first is the order of revelation: which passage came down when. The second is the order of the aayaat within each surah. The third is the order of the surahs in the written copy, from al-Faatihah to an-Naas. They are not the same, and a glance at any copy shows it."),
            .longOnly(.stats([ArticleStat("114", "surahs"), ArticleStat("6,236", "aayaat in the Kufan count"), ArticleStat("96", "where the first revelation sits"), ArticleStat("86 / 28", "Makkan and Madinan surahs")])),
            .longOnly(.text("The first aayaat ever revealed open the ninety-sixth surah. Al-Baqarah, the second surah, came down in Madinah over several years, and it holds both early Madinan aayaat and what may be the last ayah revealed of all (2:281). Many surahs came down in parts at different times, and their parts were joined as they came. So the order of revelation is history, while the other two orders are the shape of the Book itself, and the question is who gave it that shape.")),
            .longOnly(.ayah("2:281")),
            .shortOnly(.text("The first aayaat ever revealed open the ninety-sixth surah, and many surahs came down in parts at different times, their parts joined as they came. So the order of revelation is history, while the other two orders are the shape of the Book itself.")),
        ]),
        ArticleSection("THE AAYAAT: PLACED BY THE PROPHET", [
            .text("The scholars are agreed that the order of the aayaat within each surah is tawqeefi: fixed by the Prophet (peace be upon him) at Allah’s instruction through Jibreel, not chosen by anyone after him. Az-Zarkashi and as-Suyooti both record the consensus. The evidence is plain in the sound narrations. Zayd ibn Thaabit (may Allah be pleased with him) describes the Companions arranging the written pieces in the Prophet’s presence:"),
            .hadith("tirmidhi:3954", cite: "Jaami‘ at-Tirmidhi 3954; graded saheeh by al-Albaani", arabic: 33...44, english: [0...14]),
            .longOnly(.text("The Prophet referred to aayaat by their place in their surahs, which only makes sense if the places were known. He sent Umar ibn al-Khattaab (may Allah be pleased with him), who kept asking about inheritance where there is no parent or child, to an ayah by its position:")),
            .longOnly(.hadith("muslim:1617a", cite: "Saheeh Muslim 1617", arabic: 92...102, english: [100...116])),
            .longOnly(.text("In the same way he spoke of the last two aayaat of al-Baqarah, which suffice whoever recites them at night (Saheeh al-Bukhaari 5009), and the first ten aayaat of al-Kahf, which protect whoever learns them from the Dajjaal:")),
            .longOnly(.hadith("muslim:809a", cite: "Saheeh Muslim 809", arabic: 36...46, english: [0...19])),
            .longOnly(.hadith("bukhari:5009", cite: "Saheeh al-Bukhaari 5009", arabic: 31...40, english: [0...21])),
            .longOnly(.text("Above all, the Companions heard the surahs recited whole, in prayer, again and again. He recited as-Sajdah and al-Insaan in the dawn prayer of Friday (Saheeh al-Bukhaari 891), and Zayd ibn Thaabit once rebuked the governor of Madinah for reciting only short surahs at sunset:")),
            .longOnly(.hadith("bukhari:764", cite: "Saheeh al-Bukhaari 764", arabic: 24...39, english: [6...30])),
            .longOnly(.hadith("bukhari:891", cite: "Saheeh al-Bukhaari 891", arabic: 27...46, english: [0...25])),
            .longOnly(.text("The narrators explain “the longer of the two long ones” as al-A‘raaf. A surah that a whole congregation heard from beginning to end, in the same order, cannot quietly be rearranged.")),
            .shortOnly(.text("Above all, the Companions heard the surahs recited whole, in prayer, again and again, and a surah that a whole congregation heard from beginning to end, in the same order, cannot quietly be rearranged.")),
        ]),
        ArticleSection("THE AYAH THAT STAYED IN ITS PLACE", [
            .longOnly(.text("One exchange shows how strictly the Companions held to this. Al-Baqarah has two aayaat about widows. The first in the order of the copy sets their waiting period at four months and ten days; the second, which comes six aayaat later, speaks of a year’s maintenance:")),
            .longOnly(.ayah("2:234", words: 0...9)),
            .longOnly(.ayah("2:240", words: 0...11)),
            .longOnly(.text("In the view of most scholars, the year was the earlier ruling and the four months and ten days replaced it, so the ayah that came down later stands before the one it replaced. Abdullah ibn az-Zubayr (may Allah be pleased with him) raised exactly this with Uthmaan ibn Affaan (may Allah be pleased with him) while the copies were being written:")),
            .shortOnly(.text("One exchange shows how strictly the Companions held to this. Al-Baqarah has two aayaat about widows: the first in the order of the copy sets their waiting period at four months and ten days, and the second, six aayaat later, speaks of a year’s maintenance. In the view of most scholars the year was the earlier ruling and the later one replaced it, so the ayah that came down later stands first. Abdullah ibn az-Zubayr (may Allah be pleased with him) raised exactly this with Uthmaan ibn Affaan (may Allah be pleased with him) while the copies were being written:")),
            .hadith("bukhari:4530", cite: "Saheeh al-Bukhaari 4530", arabic: 17...44, english: [0...61]),
            .text("Uthmaan’s answer is the whole principle in one line. Had the order been the Companions’ own, the obvious move was to put the later ruling after the earlier, or to leave the replaced ayah out. He did neither, because the place of every ayah had been fixed by the Prophet, and the caliph had no authority to change it. Abrogation itself has its own chapter."),
            .door(.article("PreservationNaskhView")),
        ]),
        ArticleSection("THE ORDER OF THE SURAHS", [
            .text("On the order of the surahs the scholars hold three views. The first is that it too was fixed by the Prophet, as al-Kirmaani and Abu Ja‘far an-Nahhaas held. The second is that it was the Companions’ own judgment, the view attributed to Maalik and to many of the scholars. The third is that most of it came from the Prophet and some was left to them, the view of al-Bayhaqi and others. The evidence pulls both ways."),
            .longOnly(.text("On one side, the Companions’ personal copies did not all follow one order. Ibn Mas‘ood’s copy placed some surahs differently from Zayd’s, and one sound report mentions it in passing, describing twenty surahs he paired in prayer:")),
            .longOnly(.hadith("bukhari:4996", cite: "Saheeh al-Bukhaari 4996, Saheeh Muslim 822", arabic: 39...53, english: [41...81])),
            .longOnly(.text("In his arrangement Surah ad-Dukhaan stood among the first surahs of the mufassal, paired with Amma. And the Prophet himself, in a long night prayer, did not recite the surahs in the order of today’s copy. Hudhayfah ibn al-Yamaan (may Allah be pleased with him) prayed behind him:")),
            .longOnly(.hadith("muslim:772", cite: "Saheeh Muslim 772", arabic: 54...92, english: [0...73])),
            .longOnly(.text("On the other side, long runs of the order are plainly deliberate: the seven surahs that open with Ha Meem stand together, the surahs that open with Allah’s glorification cluster within a few parts of one another, and Ibn Mas‘ood himself named five early Makkan surahs in exactly the order they hold in our copy:")),
            .longOnly(.hadith("bukhari:4994", cite: "Saheeh al-Bukhaari 4994", arabic: 17...30, english: [0...26])),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) explains why the two orders were treated so differently:")),
            .longOnly(.quote(text: "“The order of the surahs was not something prescribed for them by a text; it was left to their judgment. That is why the order of Abdullah’s copy differed from the order of Zayd’s copy. As for the order of the aayaat of the surahs, it was sent down and stated in revelation, so they could not put one ayah before another in writing as they put one surah before another.” (Ibn Taymiyyah, Majmoo‘ al-Fataawa)", arabic: "تَرتِيبُ السُّوَرِ لَم يَكُن وَاجِبًا عَلَيهِم مَنصُوصًا، بَل مُفَوَّضًا إِلَى اجتِهَادِهِم، وَلِهَذَا كَانَ تَرتِيبُ مُصحَفِ عَبدِ اللَّهِ عَلَى غَيرِ تَرتِيبِ مُصحَفِ زَيدٍ. وَأَمَّا تَرتِيبُ آيَاتِ السُّوَرِ فَهُوَ مُنَزَّلٌ مَنصُوصٌ عَلَيهِ، فَلَم يَكُن لَهُم أَن يُقَدِّمُوا آيَةً عَلَى آيَةٍ فِي الرَّسمِ كَمَا قَدَّمُوا سُورَةً عَلَى سُورَةٍ", dimmed: true)),
            .shortOnly(.text("The Companions’ personal copies did not all follow one order, yet long runs of the order are plainly deliberate, such as the seven surahs that open with Ha Meem, which stand together.")),
            .callout("Whichever view is right, the order in Uthmaan’s copies was agreed by the Companions, and the Ummah has written the Quran in it ever since. Their agreement is itself a proof. No word of the Quran depends on this question: it is about the sequence of surahs, never their contents.", title: "Where the Views Meet", icon: "checkmark.seal.fill"),
        ]),
        ArticleSection("THE LONG, THE HUNDREDS, THE OFT-REPEATED AND THE MUFASSAL", [
            .longOnly(.text("The Companions and the scholars after them spoke of the surahs in four great groups, which follow their order in the copy and their length:")),
            .longOnly(.checklist([
                "**As-Sab‘ at-Tiwaal (السَّبع الطِّوَال).** The seven long surahs: al-Baqarah to al-A‘raaf, with the seventh counted as al-Anfaal and at-Tawbah together, or as Yoonus.",
                "**Al-Mi’oon (المِئُون).** The surahs of about a hundred aayaat or more that follow them.",
                "**Al-Mathaani (المَثَانِي).** The surahs of fewer than a hundred aayaat, recited and repeated more often than the long ones.",
                "**Al-Mufassal (المُفَصَّل).** The many short surahs at the end, counted by most from Qaaf and by others from al-Hujuraat, named for the many separations of the basmalah between them.",
            ], title: "The Four Groups", icon: "square.stack.3d.up.fill")),
            .longOnly(.markdown("The word **mathaani** has a wider use as well. The Quran calls itself “a consistent Book wherein is reiteration,” mathaaniya (39:23), and the Prophet named al-Faatihah **the seven oft-repeated** (15:87):")),
            .longOnly(.hadith("bukhari:4474", cite: "Saheeh al-Bukhaari 4474", arabic: 90...100, english: [114...145])),
            .longOnly(.ayah("39:23")),
            .longOnly(.ayah("15:87")),
            .longOnly(.text("The groups were living categories in worship. Ibn Mas‘ood rebuked a man who told him he had recited the whole mufassal in one unit of prayer, hurrying “like the recitation of poetry,” and named the pairs the Prophet used to recite together instead (Saheeh al-Bukhaari 775).")),
            .longOnly(.hadith("bukhari:775", cite: "Saheeh al-Bukhaari 775", arabic: 14...49, english: [0...76])),
            .longOnly(.text("And Abu Hurayrah (may Allah be pleased with him) described a prayer that most resembled the Prophet’s:")),
            .longOnly(.hadith("nasai:983", cite: "Sunan an-Nasaa’i 983; graded saheeh by al-Albaani", arabic: 45...75, english: [20...77])),
            .shortOnly(.text("The Companions and the scholars after them spoke of the surahs in four great groups, which follow their order in the copy and their length: the seven long surahs, the hundreds, the oft-repeated (al-mathaani), and the many short surahs at the end, the mufassal.")),
        ]),
        ArticleSection("WHY NOT IN THE ORDER OF REVELATION", [
            .text("A modern reader sometimes wishes the Quran had been printed in the order it came down, like a diary. The question assumes it is a record of events. It is not; it is guidance, addressed to every reader in every age, and its order serves that purpose."),
            .longOnly(.step("1. **It opens with a prayer and its answer.** Al-Faatihah, recited in every unit of every prayer, ends with the plea to be guided to the straight path. Al-Baqarah opens with “This is the Book about which there is no doubt, a guidance for those conscious of Allah” (2:2). Many scholars have seen the second as the answer to the first.")),
            .longOnly(.ayah("2:2")),
            .longOnly(.step("2. **It would break the surahs apart.** Many surahs came down in parts over years. A strictly chronological book would scatter al-Baqarah across the whole of the Madinan period and cut a single surah into dozens of pieces.")),
            .longOnly(.step("3. **The chronology is only partly known.** The occasions of revelation are known for some passages, not all, and the order of many surahs relative to one another is the scholars’ estimate, not a narration. An order built on estimates would be less certain than the one the Companions agreed on.")),
            .longOnly(.step("4. **Each surah stands whole.** Because the aayaat were placed by revelation, each surah is a unit with its own themes and its own coherence. The scholars of munaasabah, among them al-Biqaa‘i, wrote whole books on the links between each ayah and the next, and each surah and the next.")),
            .shortOnly(.text("A strictly chronological book would cut many surahs, revealed in parts over years, into dozens of pieces; the chronology itself is only partly known; and because the aayaat were placed by revelation, each surah stands whole, with its own themes and its own coherence.")),
            .text("The result is a Book a reader can open anywhere and find all of its great themes: Allah and His names, the prophets, the Hereafter, the law and the heart. The order of revelation explains the context of an ayah; the order of the copy is how Allah’s Book was given to be recited."),
        ]),
        ArticleSection("AT-TAWBAH WITHOUT THE BASMALAH", [
            .markdown("Every surah but one opens with **Bismillah ar-Rahman ar-Raheem**. Surah at-Tawbah, the ninth, does not. The count still comes to 114, because the basmalah appears inside Surah an-Naml in Sulaymaan’s letter (27:30)."),
            .ayah("27:30"),
            .longOnly(.text("Reciters begin at-Tawbah with the words of seeking refuge alone.")),
            .longOnly(.ayah("9:1")),
            .longOnly(.text("The reason the Companions wrote no basmalah there is the simplest one: none came down with it, and they wrote the Quran as it came down. Al-Qurtubi quotes al-Qushayri to that effect: the correct view is that it was not written because Jibreel did not bring it down in this surah. The scholars have suggested wisdoms. The surah opens with a declaration of disassociation from the idolaters who broke their treaties, and a saying often quoted from Ali (may Allah be pleased with him) calls the basmalah a word of safety, out of place at the head of such a declaration. Others note that at-Tawbah continues the subject of al-Anfaal. These are reflections on a fact, not the cause of it.")),
            .longOnly(.callout("A report in which Uthmaan explains that he joined al-Anfaal and at-Tawbah without a basmalah because their stories were alike and the Prophet died without saying whether they were one surah is widely quoted. It is recorded by Abu Daawood and at-Tirmidhi, but al-Albaani and others judged its chain weak, since it rests on a little-known narrator, Yazeed al-Faarisi, so it is not relied on here.", title: "A Note", icon: "exclamationmark.triangle.fill")),
            .shortOnly(.text("The reason the Companions wrote no basmalah there is the simplest one: none came down with it, and they wrote the Quran as it came down.")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Is it wrong to recite surahs out of their order?**")),
            .longOnly(.text("No. The Prophet recited an-Nisaa’ before Al Imraan in one night prayer (Saheeh Muslim 772), and Aa’ishah told the man from Iraq, “What does it matter which part of it you read first?” (Saheeh al-Bukhaari 4993). Following the order is better, but it is not required. Reversing the aayaat inside a surah is another matter: the scholars forbid it, because that order is revelation.")),
            .longOnly(.hadith("bukhari:4993", cite: "Saheeh al-Bukhaari 4993", arabic: 39...61, english: [36...89])),
            .longOnly(.markdown("**Who decided where each ayah ends?**")),
            .longOnly(.text("The Prophet recited ayah by ayah, pausing at the end of each. Umm Salamah (may Allah be pleased with her) described his recitation of al-Faatihah:")),
            .longOnly(.hadith("abudawud:4001", cite: "Sunan Abi Daawood 4001; graded saheeh by al-Albaani", arabic: 34...54, english: [0...37])),
            .longOnly(.text("The schools of counting in Madinah, Makkah, Koofah, Basrah and Shaam preserved where he paused, and they differ in a limited number of places, where one school counts a passage as one ayah and another as two. The Kufan count, attributed to Ali and handed down through Abu Abd ar-Rahman as-Sulami, gives the 6,236 aayaat printed in most copies. The words are the same in every count; only the numbering differs.")),
            .markdown("**Where do the thirty parts come from?**"),
            .text("The division into thirty juz and sixty hizb was made later, for reading the whole Quran in a month. It follows length, not meaning, and is not part of the revelation."),
            .door(.article("JuzView")),
            .door(.article("CompileView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran has three orders. The order of revelation is history, known in part. The order of the aayaat within each surah is revelation: the Prophet placed every ayah as it came, the Companions arranged the written pieces in his presence and heard the surahs recited whole, and Uthmaan would not move even an ayah whose ruling had been replaced. The order of the surahs is the Companions’ agreed order, from the Prophet in large part at least, which the Ummah has kept in every copy since. Within that order the surahs fall into the long, the hundreds, the oft-repeated and the mufassal, and at-Tawbah alone opens without the basmalah because none came down with it."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Tawqeefi", arabic: "تَوقِيفِيّ", meaning: "**Fixed by revelation**, taken from the Prophet and not open to anyone’s choice: the order of the aayaat in each surah, by consensus."),
            .term("Ijtihaadi", arabic: "اجتِهَادِيّ", meaning: "**Decided by scholarly judgment**: in the view of many scholars, the order of some or all of the surahs, agreed upon by the Companions."),
            .term("Al-Mufassal", arabic: "المُفَصَّل", meaning: "**The often-divided**: the short surahs at the end of the Quran, most often counted from Qaaf, recited in the prayers of the day and night."),
            .term("Munaasabah", arabic: "مُنَاسَبَة", meaning: "**Fitness, connection**: the study of how each ayah links to the next and each surah to its neighbours."),
        ]),
    ]
}

// MARK: - preservation-2

struct PreservationScriptView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "PreservationScriptView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Dots, Vowels and the Uthmaani Script")
        .englishArticle().selectableArticleList(article: "PreservationScriptView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the copies that Uthmaan (may Allah be pleased with him) sent to the cities were written in the Arabic script of their day: letter shapes with few dots and no vowel signs, a written reminder for people who had already learned the words from a teacher. Over the next century and a half, scholars added the vowel dots of Abu al-Aswad ad-Du’ali, the letter dots of his students and the vowel signs of al-Khaleel ibn Ahmad, and later copyists marked the aayaat, the parts and the pauses. None of them changed a letter of the Uthmaani writing, which the scholars ruled must be copied as it was first written, and which the printed mushaf of today still keeps."),
        ]),
        ArticleSection("A SCRIPT THAT ASSUMED A TEACHER", [
            .longOnly(.text("Arabic in the time of the Prophet Muhammad (peace and blessings be upon him) was written with far fewer marks than it is today. Several letters shared one shape. In the middle of a word, the small tooth that is now ba, ta, tha, noon or ya was a single stroke, and jeem, ha and kha looked alike, as did dal and dhal, ra and zaay, sin and shin. Dots that tell such letters apart were known, but scribes used them sparingly, and there were no signs at all for the short vowels. It was a script for letters, contracts and records, not yet for books.")),
            .longOnly(.markdown("The oldest dated Arabic document of Islam shows exactly this. **PERF 558**, a receipt in Greek and Arabic written in Egypt in Jumaada al-Oola of 22 AH (643 CE) for sheep supplied to a Muslim commander, dots some of its letters and leaves others bare. A reader of such writing did not decode it from nothing. He already knew the language, and usually the text, and the writing reminded him of what he knew.")),
            .longOnly(.text("Few people in Makkah could write at all, and the Prophet (peace be upon him) himself neither read nor wrote. The Quran makes this a point in its own favour, and he described his community the same way:")),
            .longOnly(.ayah("29:48")),
            .longOnly(.hadith("bukhari:1913", cite: "Saheeh al-Bukhaari 1913", arabic: 31...37, english: [4...14])),
            .shortOnly(.text("Arabic in the time of the Prophet Muhammad (peace and blessings be upon him) was written with far fewer marks than it is today. Several letters shared one shape, the dots that tell them apart were used sparingly, and there were no signs at all for the short vowels. A reader did not decode such writing from nothing: he already knew the language, and usually the text, and the writing reminded him of what he knew.")),
            .text("So the Quran did not come to the Arabs as a book to be read off a page. It came as speech, recited to them, and the writing that followed was in the service of that speech."),
        ]),
        ArticleSection("TAUGHT FROM MOUTH TO EAR", [
            .longOnly(.text("The Quran was received by hearing at every stage. Jibreel recited it and the Prophet (peace be upon him) repeated it after him; the Prophet recited it to his Companions, and they recited it back to him. Allah even commanded him to recite a surah in person to one Companion, Ubayy ibn Ka‘b (may Allah be pleased with him):")),
            .longOnly(.hadith("bukhari:4959", cite: "Saheeh al-Bukhaari 4959, Saheeh Muslim 799", arabic: 27...44, english: [8...54])),
            .longOnly(.markdown("The scholars call this way of learning **talaqqi (تَلَقِّي)**, receiving, and **mushaafahah (مُشَافَهَة)**, from lips to ears. It was not a substitute for writing. It carried what no writing of the time could, and much that no writing can carry even now: how long a vowel is held, where a letter merges into the next, where the nasal hum falls, how a hamzah is eased, where a reciter may stop and where he may not. A saying reported from Zayd ibn Thaabit (may Allah be pleased with him), the chief scribe of the revelation, and from others of the first generations, sums up the principle: **the recitation is a sunnah that is followed**, received from those who came before, not worked out from the letters.")),
            .shortOnly(.text("The Quran was received by hearing at every stage, from Jibreel to the Prophet (peace be upon him) and from the Prophet to his Companions. The scholars call this talaqqi, receiving, and it carried what no writing of the time could: how long a vowel is held, where a letter merges into the next, where a reciter may stop and where he may not. A saying reported from Zayd ibn Thaabit (may Allah be pleased with him) sums up the principle: the recitation is a sunnah that is followed.")),
            .text("That is why every reciter who teaches with an ijaazah today can name his teachers back to the Prophet (peace be upon him), and why a reading is accepted only when it has such a chain and also fits the written outline of Uthmaan’s copies. The writing keeps memory from drifting, and the teaching tells the reader what the writing means."),
            .door(.article("QiraatView")),
        ]),
        ArticleSection("WHAT UTHMAAN'S SCRIBES WROTE", [
            .text("When Uthmaan ibn Affaan (may Allah be pleased with him) had the collection made under Abu Bakr (may Allah be pleased with him) copied for the cities, around 25 AH (645 CE), he gave his four scribes one rule for any word on which they differed:"),
            .hadith("bukhari:3506", cite: "Saheeh al-Bukhaari 3506", arabic: 42...57, english: [43...71]),
            .longOnly(.text("Az-Zuhri, who narrated the account, names the one case on record. The committee differed over how to write taaboot, the chest or ark (2:248, 20:39): at-taaboot, ending in ta, as Quraysh said it, or at-taabooh, ending in ha, as Zayd ibn Thaabit (may Allah be pleased with him) of Madinah said it.")),
            .longOnly(.ayah("2:248", words: 8...8)),
            .longOnly(.ayah("20:39", words: 3...3)),
            .longOnly(.text("Uthmaan settled it by his rule:")),
            .longOnly(.hadith("tirmidhi:3104", cite: "Jaami‘ at-Tirmidhi 3104; graded saheeh by al-Albaani", arabic: 193...216, english: [294...331])),
            .longOnly(.markdown("The result is the **rasm (رَسم)**, the written outline of the mushaf, and it keeps habits that later Arabic spelling dropped. Salaah and zakaah are written with a waw, **الصلوة** and **الزكوة**. Rahmah, mercy, is written with an open ta, **رحمت**, in seven places and with the round ta everywhere else; ni‘mah, grace, has the open ta in eleven. Surah an-Naml writes an alif that is not pronounced in la-adhbahannahu (27:21), and Surah adh-Dhaariyaat writes two ya’s in bi-aydin (51:47). The scholars of the rasm recorded every such spelling, place by place.")),
            .longOnly(.ayah("27:21", words: 4...4)),
            .longOnly(.ayah("51:47", words: 2...2)),
            .shortOnly(.text("The result is the rasm, the written outline of the mushaf, and it keeps habits that later Arabic spelling dropped: salaah and zakaah, for example, are written with a waw. The scholars of the rasm recorded every such spelling, place by place.")),
            .longOnly(.text("Some spellings do more than keep an old habit: they hold two readings in one outline. In 2:219, the word that Hafs reads kabeer, great, is read katheer, much, by Hamzah and al-Kisaa’i; written without dots, the two words are one shape. In 3:146, an outline without vowel signs or a long alif can be read qaatala, fought, or qutila, was killed, and both are canonical readings.")),
            .longOnly(.ayah("2:219", words: 7...8)),
            .longOnly(.ayah("3:146", words: 3...3)),
            .longOnly(.text("Where the copies sent to different cities differed by a letter or a word, each city’s readers recited as its own copy was written. In 9:100 the copy sent to Makkah adds the word min, from, before tahtaha, beneath them, as the phrase appears elsewhere in the Quran, and Ibn Katheer of Makkah recites it so; the other copies and readers have it without. In 57:24 the copies of Madinah and Shaam lack the word huwa, and Naafi‘ and Ibn Aamir recite without it. The scholars explain that both wordings were taught from the Prophet (peace be upon him) and divided among the copies, and the books of the rasm list every such place.")),
            .longOnly(.ayah("9:100", words: 16...17)),
            .longOnly(.ayah("57:24", words: 9...9)),
            .longOnly(.markdown("The great books of this science drew on the copies themselves and on the reports of those who had seen them: **al-Muqni‘** of Abu Amr ad-Daani (d. 444 AH / 1053 CE, may Allah have mercy on him), the work of his student Abu Daawood Sulaymaan ibn Najaah (d. 496 AH / 1103 CE), and ash-Shaatibi’s poem on the rasm, **Aqeelat Atraab al-Qasaa’id**.")),
            .shortOnly(.text("Some spellings do more than keep an old habit: they hold two canonical readings in one outline. And where the copies sent to different cities differed by a letter or a word, each city’s readers recited as its own copy was written, because both wordings had been taught from the Prophet (peace be upon him).")),
        ]),
        ArticleSection("ABU AL-ASWAD'S RED DOTS", [
            .text("Within a generation of the Prophet (peace be upon him), Islam had spread among Persians, Copts, Aramaeans and Berbers who learned Arabic as a second language, and Arab children were growing up among them. Mistakes in the endings of words, which in Arabic can change who did what to whom, began to be heard in recitation. The scholars call such a mistake lahn."),
            .text("The best-known account, told in the histories of Arabic grammar, is that Abu al-Aswad ad-Du’ali (d. 69 AH / 688 CE, may Allah have mercy on him), a judge of Basrah and a student of Ali ibn Abi Taalib (may Allah be pleased with him), heard a man recite the third ayah of Surah at-Tawbah with the wrong vowel on the word for “His Messenger”, so that the Messenger was joined to the polytheists whom Allah disowns, instead of joining Allah in disowning them. One vowel had turned the verse into blasphemy:"),
            .ayah("9:3", words: 9...14),
            .longOnly(.markdown("Abu al-Aswad chose a scribe and gave him a method that ad-Daani records in his book on dotting, **al-Muhkam**: when you see me open my lips at a letter, put a dot above it; when I round them, put a dot beside it; when I lower them, put a dot beneath it; and when I follow the vowel with a nasal sound, put two dots. The dots were written in a colour different from the ink of the text, usually red, so that no one could mistake them for part of the writing. The scholars call this **naqt al-i‘raab**, the dotting of the vowels and endings.")),
            .shortOnly(.text("Abu al-Aswad chose a scribe and had him put a dot above a letter when he opened his lips, beside it when he rounded them, and beneath it when he lowered them, with two dots for a nasal ending. The dots were written in a colour different from the ink of the text, usually red, so that no one could mistake them for part of the writing.")),
            .text("It added nothing to the letters. It wrote down, for those who needed it, what every trained reciter already pronounced."),
        ]),
        ArticleSection("DOTS FOR LETTERS, THEN AL-KHALEEL'S SIGNS", [
            .longOnly(.markdown("The next step distinguished the letters themselves. The reports name two students of Abu al-Aswad in Basrah, **Nasr ibn Aasim al-Laythi** and **Yahya ibn Ya‘mur**, who in the time of al-Hajjaaj ibn Yoosuf, governor of Iraq for the caliph Abd al-Malik ibn Marwan, set out the system of **i‘jaam**: one, two or three dots, above or below, that tell ba from ta from tha and jeem from ha from kha. These were written in the ink of the letters, to keep them apart from the red vowel dots. Since dots of this kind already appear in writing of the Companions’ time, their work was to make the dotting complete and consistent, which is why the scholars differ over whether the first copies carried some dots. On either view the copies went out without the full dotting that a reader today expects.")),
            .longOnly(.text("A page now carried two kinds of dot in two colours, and it grew crowded. Al-Khaleel ibn Ahmad al-Faraaheedi of Basrah (d. 170 AH / 786 CE), the founder of Arabic prosody and the author of its first dictionary, replaced the vowel dots with small letters drawn from the sounds themselves: a small slanting alif above the letter for a, a small waw for u, and a small ya beneath for i, later reduced to a stroke; the sign written twice for the nunation of an indefinite ending; the head of a shin, from shadeed, for a doubled letter; and the head of an ‘ayn for the hamzah, which is pronounced close to it. With little change, these are the vowel signs every reader of Arabic uses today.")),
            .longOnly(.text("The scholars did not accept these additions without thought. Some of the early generations disliked putting into the mushaf anything that had not been in Uthmaan’s copies, and ad-Daani reports that Maalik (may Allah have mercy on him) allowed dots in the small copies from which children were taught but not in the master copies. Once it was clear that the marks guarded the text and could not be mistaken for it, the scholars agreed they were permitted. An-Nawawi (d. 676 AH / 1277 CE, may Allah have mercy on him) writes in at-Tibyaan that dotting and vowelling the mushaf is recommended, because it protects the text from error and distortion.")),
            .shortOnly(.text("Abu al-Aswad’s students in Basrah then made the dots that tell ba from ta from tha complete and consistent, written in the ink of the letters to keep them apart from the red vowel dots. When the page grew crowded, al-Khaleel ibn Ahmad (d. 170 AH / 786 CE) replaced the vowel dots with small signs drawn from the sounds themselves, which with little change are the vowel signs every reader of Arabic uses today. Once it was clear that the marks guarded the text and could not be mistaken for it, the scholars agreed they were permitted.")),
            .chain([
                ArticleChainLink("Uthmaan’s copies", "around 25 AH: the rasm, with few dots and no vowel signs"),
                ArticleChainLink("Abu al-Aswad ad-Du’ali", "d. 69 AH: red dots for the vowels"),
                ArticleChainLink("Nasr ibn Aasim and Yahya ibn Ya‘mur", "under al-Hajjaaj: dots that tell the letters apart"),
                ArticleChainLink("al-Khaleel ibn Ahmad", "d. 170 AH: the vowel signs used today"),
                ArticleChainLink("Abu Amr ad-Daani", "d. 444 AH: the rasm recorded place by place"),
                ArticleChainLink("Cairo, 1924", "the printed standard, in the reading of Hafs"),
                ArticleChainLink("Madinah, 1405 AH", "the mushaf of the King Fahd Complex"),
            ], caption: "From Uthmaan’s copies to the printed mushaf: the marks added around the rasm, century by century, while its letters stayed as they were first written."),
        ]),
        ArticleSection("MARKING THE AAYAAT, THE PARTS AND THE PAUSES", [
            .longOnly(.text("The earliest copies already mark where each ayah ends, with a small cluster of strokes or dots between the words, but they give no numbers. Later copyists added a sign after every fifth and every tenth ayah, then the name of each surah and its number of aayaat in a band of colour at its head, drawn so that it could never be read as text. The numbered circle at the end of each ayah in a printed mushaf is the last stage of the same practice.")),
            .longOnly(.markdown("Where each ayah ends was itself taught from the Prophet (peace be upon him), and the cities kept slightly different counts while reading the same words. The mushaf most of the world reads follows the **Kufan count of 6,236 aayaat**, which its closing note traces through Abu Abd ar-Rahman as-Sulami to Ali ibn Abi Taalib (may Allah be pleased with him).")),
            .longOnly(.text("The divisions into parts grew out of the Companions’ habit of reciting a fixed portion every day. The Prophet (peace be upon him) told Abdullah ibn Amr (may Allah be pleased with him), who had been reciting the whole Quran every night:")),
            .longOnly(.hadith("bukhari:5054", cite: "Saheeh al-Bukhaari 5054", arabic: 44...62, english: [6...48])),
            .longOnly(.text("Such a portion was called a hizb, and the Prophet spoke of it by that name:")),
            .longOnly(.hadith("muslim:747", cite: "Saheeh Muslim 747", arabic: 56...76, english: [0...44])),
            .longOnly(.markdown("Later copies divided the whole into thirty equal parts, each a **juz’**, so that it could be read in a month, and each juz’ into two **hizb** and each hizb into four quarters; the small ۞ sign at the head of an ayah in the printed mushaf marks a quarter. These parts were measured by length, not by meaning, and a reader should read across them. The fifth juz’ begins at 4:24, in the middle of a sentence that began in the ayah before it, listing the women a man may not marry:")),
            .longOnly(.ayah("4:24", words: 1...7)),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) preferred dividing the daily portions by whole surahs, which he held to be the Companions’ practice, over divisions by the count of letters, which came later and can cut a passage in two; the report he relied on for the Companions’ division is graded weak by al-Albaani. Either way, both are aids for the reader. So are the small pause signs above the line, added by later scholars of where to stop and where to begin. They guide the reciter’s breath, and they are not part of the Quran.")),
            .shortOnly(.text("The earliest copies already mark where each ayah ends, though without numbers. Later copyists added signs for every fifth and tenth ayah and the names of the surahs, and later still the whole was divided into thirty parts for reading in a month. These parts are measured by length, not by meaning, and like the pause signs above the line they are aids for the reader, not part of the Quran.")),
        ]),
        ArticleSection("KEEP THE FIRST WRITING", [
            .text("Every mark described so far was added around the letters. The letters themselves the scholars refused to touch. As Arabic spelling changed in later generations, an alif that had been left out came to be written and a waw that is not pronounced came to be dropped, and Maalik ibn Anas (d. 179 AH / 795 CE) was asked whether a mushaf should follow the new spelling. Ad-Daani records his answer from Maalik’s student Ashhab:"),
            .quote(text: "“Maalik was asked: ‘Do you think that whoever has a mushaf written today should have it written in the spelling people have newly devised?’ He said: ‘I do not think so. It should be written in the first writing.’” (Abu Amr ad-Daani, al-Muqni‘, reporting from Ashhab)", arabic: "سُئِلَ مَالِكٌ فَقِيلَ لَهُ: أَرَأَيتَ مَنِ استَكتَبَ مُصحَفًا اليَومَ، أَتَرَى أَن يُكتَبَ عَلَى مَا أَحدَثَ النَّاسُ مِنَ الهِجَاءِ اليَومَ؟ فَقَالَ: لَا أَرَى ذَلِكَ، وَلَكِن يُكتَبُ عَلَى الكِتبَةِ الأُولَى", dimmed: true),
            .longOnly(.text("Ad-Daani adds that no scholar of the ummah differed with him, and Imam Ahmad is reported to have said that departing from the writing of Uthmaan’s mushaf in a waw, a ya, an alif or anything else is forbidden. The reasons are not sentiment. The outline is what the canonical readings are measured against, so changing it would erase readings taught from the Prophet (peace be upon him). It is the writing the Companions agreed on together, and departing from it would set a later preference against their consensus. And it is a guard: when every copy must match spellings that ordinary Arabic no longer uses, a copyist’s change stands out at once.")),
            .longOnly(.text("The question returned in the twentieth century, when some proposed printing the mushaf in modern spelling to help learners. The councils of scholars that considered it, among them the Council of Senior Scholars in Saudi Arabia, kept the rule, and the standard printings of today follow it.")),
            .shortOnly(.text("Ad-Daani adds that no scholar of the ummah differed with him. The reasons are not sentiment: the outline is what the canonical readings are measured against, it is the writing the Companions agreed on together, and when every copy must match spellings that ordinary Arabic no longer uses, a copyist’s change stands out at once.")),
        ]),
        ArticleSection("FROM CAIRO TO MADINAH", [
            .longOnly(.text("The first printed Qurans were made in Europe, by people who did not recite them. An edition printed in Venice in 1537 or 1538 was so full of errors that it found no readers; its one known copy was rediscovered only in 1987. Gustav Flügel’s Leipzig edition of 1834, whose ayah numbers matched none of the Muslim counts, served Western scholars for a century. Muslims printed their own from the end of the eighteenth century, in Russia, Iran, India and the Ottoman lands, in good faith but with no common standard.")),
            .longOnly(.markdown("The turning point was the edition printed in **Cairo in 1924 (1342 AH)** under the supervision of scholars of al-Azhar. It took its spelling from what ad-Daani and Abu Daawood report of Uthmaan’s copies, its reading from Hafs from Aasim, and its count from the Kufan tradition, and it says so in a note at the end. Within a generation it had become the model for most printed mushafs, and Western scholars gave up Flügel’s numbering for its own.")),
            .longOnly(.markdown("In 1405 AH (1985 CE) the **King Fahd Complex for the Printing of the Holy Quran** in Madinah began printing the mushaf now found in mosques across the world. It is written by hand by the Syrian calligrapher **Uthmaan Taaha**, in 604 pages of fifteen lines, each page ending at the end of an ayah, and every edition is checked by a committee of scholars of the readings before it is released. Its closing pages state what it follows: the rasm as the scholars report it from Uthmaan’s copies, generally preferring Abu Daawood where he and ad-Daani differ; the reading of Hafs; the Kufan count; and the marks of al-Khaleel and the scholars of the East in place of those of al-Andalus and the Maghrib. The Complex also prints mushafs in the riwaayaat of Warsh, Qaaloon and ad-Doori, each with its own marks.")),
            .shortOnly(.text("The printed standard came with the edition made in Cairo in 1924 under the supervision of scholars of al-Azhar, which took its spelling from what ad-Daani and Abu Daawood report of Uthmaan’s copies, its reading from Hafs from Aasim, and its count from the Kufan tradition. Since 1405 AH (1985 CE) the King Fahd Complex in Madinah has printed the mushaf now found in mosques across the world, written by hand by Uthmaan Taaha and checked by a committee of scholars of the readings before each edition is released.")),
            .door(.article("RiwayatDifferencesView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**If the first copies had no vowels and few dots, how could anyone read them correctly?**"),
            .text("The way they were always meant to be read: with a teacher. No one ever learned the Quran from the bare outline alone. The outline was read by people who had memorised the text from those who memorised it before them, and it was written so that every reading they had received would fit it. A reader who guessed from the letters, without that chain, would not be reading the Quran as it was taught."),
            .longOnly(.markdown("**Are the dots and vowel signs part of the Quran?**")),
            .longOnly(.text("No. The Quran is the speech of Allah, recited; the letters of the rasm are the agreed way of writing it; the dots and signs are aids that record how it is recited. That is why a mushaf from Morocco and one from Pakistan can mark the same rasm differently and both be correct, and why the scholars wrote the marks in a different colour for centuries.")),
            .longOnly(.door(.article("AhrufView"))),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Uthmaani copies were written in the script of their age, an outline of consonants that assumed a reader who had learned the words by ear. As Islam spread, Abu al-Aswad ad-Du’ali added red dots for the vowels, his students added dots for the letters, and al-Khaleel ibn Ahmad devised the vowel signs used today, while later copyists marked the aayaat, the parts and the pauses. The scholars accepted these aids because they protected the recitation, and they refused any change to the letters, so the printed mushaf in a mosque today still keeps the spelling that Uthmaan’s scribes wrote and every reading that spelling was made to hold."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("I‘jaam", arabic: "إِعجَام", meaning: "The **dots that tell letters of one shape apart**, as ب, ت and ث: from **ع-ج-م**, in the sense of removing what is unclear. They are distinct from the dots or signs of the vowels."),
            .term("Naqt al-i‘raab", arabic: "نَقطُ الإِعرَابِ", meaning: "The **red vowel dots** of Abu al-Aswad ad-Du’ali: a dot above for a, beside the letter for u, beneath it for i, and two for nunation, written in a colour apart from the text."),
            .term("Shakl", arabic: "شَكل", meaning: "The **vowel signs** of al-Khaleel ibn Ahmad, fatha, damma, kasra, shaddah and the rest, which replaced the vowel dots. To write a text with them is tashkeel."),
            .term("Juz’ and hizb", arabic: "جُزء وَحِزب", meaning: "A **juz’** is one of the thirty equal parts of the mushaf, and a **hizb** is half of one. Hizb was first the word for a person’s daily portion of recitation, as the Prophet (peace be upon him) used it in Saheeh Muslim 747."),
        ]),
    ]
}

struct PreservationManuscriptsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "PreservationManuscriptsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Oldest Manuscripts")
        .englishArticle().selectableArticleList(article: "PreservationManuscriptsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a handful of Quran manuscripts survive from the first Islamic century, and radiocarbon places some of their parchment within a few decades of the Prophet Muhammad (peace and blessings be upon him). They show the Uthmaani text in use almost at once, with the same peculiar spellings in the same places, and only one copy from outside it, erased and written over in San‘a. They cannot show how the text was pronounced, they date parchment rather than ink, and the copies that legend ascribes to Uthmaan are later than the legend. Their value is as an independent witness to a text that was carried, first of all, in memory."),
        ]),
        ArticleSection("WHAT A MANUSCRIPT CAN PROVE", [
            .longOnly(.text("The Quran calls itself a recitation first, and the Muslims kept it first in memory. But it also speaks of itself as written, in honoured pages:")),
            .longOnly(.ayah("80:13-16")),
            .text("Manuscripts are not the foundation of the Muslim case for preservation. That rests on mass transmission: a text carried by whole generations at once, in every city, each generation from the one before. The value of the manuscripts is that anyone can examine them, Muslim or not, without trusting any chain of teachers, and that they could have told against the Muslims."),
            .longOnly(.text("In the 1970s some Western scholars, John Wansbrough in Quranic Studies (1977) the best known of them, argued that the Quran was not fixed until nearly two centuries after the Prophet (peace be upon him), and that the account of Uthmaan’s copies was a later story projected back. Such a theory makes a prediction: the oldest manuscripts should show a text still taking shape. Over the last few decades the oldest manuscripts have been dated, studied and published, and they show the opposite.")),
            .shortOnly(.text("Some Western scholars of the 1970s argued that the Quran was not fixed until nearly two centuries after the Prophet (peace be upon him). Such a theory predicts that the oldest manuscripts should show a text still taking shape. They show the opposite.")),
        ]),
        ArticleSection("THE BIRMINGHAM LEAVES", [
            .longOnly(.markdown("In 2015 the University of Birmingham announced the result of a test on two parchment leaves in its **Mingana Collection**, gathered in the Middle East in the 1920s by Alphonse Mingana with funds from Edward Cadbury. A doctoral researcher, Alba Fedeli, had noticed that the two leaves, catalogued with seven later ones, were in a different and much older hand. The Oxford Radiocarbon Accelerator Unit dated their parchment to between 568 and 645 CE, with a probability of 95.4 percent.")),
            .longOnly(.text("The leaves are written in the Hijaazi script, the slanting, unadorned hand of the earliest copies, and they hold parts of three surahs: 18:17–31, 19:91–98 and 20:1–40. On the second leaf the end of Surah Maryam runs straight into the beginning of Surah Ta Ha, as in the mushaf today. Their words follow the standard text, with differences only of spelling, such as an alif written or left out, and they belong to the same codex as leaves held in the national library of France.")),
            .longOnly(.text("Three honest limits apply. Radiocarbon dates the death of the animal whose skin became the parchment, not the writing, so the ink may be somewhat later. A range is a spread of probability, not a date: its earliest years fall before the Prophet’s mission began in 610 CE and cannot be when Quranic surahs were copied, so newspaper claims that the leaves might be older than Muhammad misread the science. And specialists have cautioned that radiocarbon results for manuscripts whose dates are known from other evidence have sometimes come out earlier than the writing. What the leaves show with confidence is a copy of the standard text written within a few decades of the Prophet’s death.")),
            .shortOnly(.text("In 2015 the University of Birmingham announced that the parchment of two leaves in its Mingana Collection had been radiocarbon dated to between 568 and 645 CE. Radiocarbon dates the parchment, not the ink, but the leaves, in the slanting Hijaazi hand of the earliest copies, show a copy of the standard text written within a few decades of the Prophet’s death.")),
        ]),
        ArticleSection("TÜBINGEN AND THE PARIS CODEX", [
            .longOnly(.markdown("A year earlier, in 2014, the University Library of Tübingen in Germany announced a similar result for a manuscript it had long held, **Ma VI 165**. Its 77 leaves run from 17:37 to 36:57, about a quarter of the Quran, in an early form of the angular script later called Kufic. The radiocarbon range, 649 to 675 CE at 95.4 percent probability, placed its parchment within roughly twenty to forty-five years of the Prophet’s death, earlier than many had assumed for a copy in this script.")),
            .longOnly(.markdown("The most studied early copy is one that no single library owns. François Déroche named it the **Codex Parisino-Petropolitanus** after the two cities that hold most of it, Paris and St Petersburg; a leaf is in the Vatican and another in the Khalili Collection in London, about a hundred leaves in all. In his study of it (2009), Déroche identified five copyists sharing the work in the Hijaazi script, and dated the codex on the evidence of its script and spelling to the second half of the seventh century CE. It is a large, planned copy of the standard text, with the ends of the aayaat marked, made by a team rather than by one man for himself.")),
            .longOnly(.text("Copies like these were not private notes. Parchment for a codex of this size meant the skins of many animals, and a team of scribes meant an institution behind them. Within a generation of Uthmaan (may Allah be pleased with him), someone was investing in large, careful copies of exactly the text the Muslim sources say he sent out.")),
            .shortOnly(.text("The Tübingen manuscript Ma VI 165, about a quarter of the Quran, has parchment dated to 649 to 675 CE, and the Codex Parisino-Petropolitanus in Paris and St Petersburg is a large, planned copy of the standard text made by a team of copyists in the same century. Within a generation of Uthmaan (may Allah be pleased with him), someone was investing in careful copies of exactly the text the sources say he sent out.")),
        ]),
        ArticleSection("SAN‘A AND ITS ERASED TEXT", [
            .longOnly(.text("In 1972 workers restoring the Great Mosque of San‘a in Yemen found, sealed between the roof and the ceiling, a great store of worn parchment and paper: thousands of fragments, most of them from old Qurans, put away rather than thrown out because they bore the words of Allah. Conservation began in the 1980s with German help, and one manuscript from the hoard, catalogued DAM 01-27.1 and now called San‘a 1, became the most discussed Quran manuscript in the world.")),
            .longOnly(.text("It is a palimpsest: its first text was washed off and the parchment written over. The upper text is the standard Quran. The lower text, recovered with ultraviolet photography and later imaging, follows a different line of copying, with words added, missing or in another order. Behnam Sadeghi and Mohsen Goudarzi, who published the lower text of the leaves kept in San‘a (Der Islam, 2012), concluded that it is a copy of the kind the Muslim sources describe for the Companions (may Allah be pleased with them) before Uthmaan, matching neither Ibn Mas‘ood’s nor Ubayy’s codex as reported, though of the same kind. Asma Hilali, who published her own edition of its leaves (2017), has argued that the lower text may have been written for study or teaching rather than as a finished copy. On any reading, it is the only manuscript known so far whose text is not Uthmaani.")),
            .longOnly(.text("For a Muslim, the striking thing about San‘a 1 is not only its lower text but what was done to it. A copy that differed from Uthmaan’s had its writing washed away, and the standard text was written over it. On a single parchment, it fits what the sources say happened across the Muslim lands: copies from before the agreement were set aside, and the text the Companions agreed on took their place.")),
            .shortOnly(.text("In 1972 workers restoring the Great Mosque of San‘a found thousands of fragments of old Qurans. One of them, San‘a 1, is a palimpsest whose lower text follows a different line of copying, of the kind the sources describe for the Companions before Uthmaan: the only manuscript known so far whose text is not Uthmaani. But that text was washed off and the standard one written over it, as the sources say copies from before the agreement were set aside.")),
            .door(.article("ProvingPreservationView")),
        ]),
        ArticleSection("THE COPIES ASCRIBED TO UTHMAAN", [
            .longOnly(.text("Several old manuscripts are honoured as the copies of Uthmaan (may Allah be pleased with him) himself, and two are the most famous. The large codex in the Topkapı Palace in Istanbul was published in facsimile in 2007 by IRCICA, the research centre of the Organisation of Islamic Cooperation, with a study by the Turkish scholar Tayyar Altıkulaç. He compared it word by word with what the books of the rasm report of Uthmaan’s copies and found it a faithful copy of the standard text, but concluded from its script and decoration that it was not written in Uthmaan’s time; it belongs to the Umayyad period, a generation or more after him.")),
            .longOnly(.text("The great Kufic codex kept in Tashkent, often called the Samarkand Quran, carries the legend that Uthmaan was reading it when he was killed and that its stains are his blood. It was taken to St Petersburg after the Russian conquest of Central Asia, published there in facsimile in 1905, and returned to Tashkent in the 1920s. Specialists date its large Kufic script to a century or more after Uthmaan.")),
            .longOnly(.text("This costs the Muslims nothing. Their scholars never claimed that the text depends on any surviving object, and the rule of the religion is to say only what is known. A legend that a manuscript was Uthmaan’s does not make it so, and a manuscript that is later than its legend still witnesses, as both of these do, to the same text.")),
            .shortOnly(.text("Several old manuscripts are honoured as the copies of Uthmaan himself, among them the codex in the Topkapı Palace in Istanbul and the Samarkand Quran in Tashkent, but specialists date both to a generation or more after him. This costs the Muslims nothing: the text never depended on any surviving object, and a later copy still witnesses to the same text.")),
        ]),
        ArticleSection("WHAT THE EARLY COPIES SHOW", [
            .text("Taken together, the early manuscripts make four points that a late or fluid text could not explain."),
            .step("1. **One text, early.** Copies made in different hands and places within the first Islamic century share the same consonantal text, apart from the lower layer in San‘a, which belongs to the line of copies from before the agreement."),
            .longOnly(.step("2. **The same odd spellings in the same places.** Marijn van Putten showed in 2019, in the Bulletin of the School of Oriental and African Studies, that the early manuscripts agree to a remarkable degree on idiosyncratic spellings, such as ni‘mat Allah, the grace of Allah, written with an open ta in the places where the mushaf has it today and with a round ta elsewhere. Scribes copying from memory would not agree on such quirks. They point to one written archetype behind the copies, early enough to stand behind manuscripts of the first century, as the account of Uthmaan’s copies says.")),
            .shortOnly(.step("2. **The same odd spellings in the same places.** The early manuscripts agree to a remarkable degree on idiosyncratic spellings, such as ni‘mat Allah written with an open ta in the places where the mushaf has it today. Scribes copying from memory would not agree on such quirks; they point to one written archetype behind the copies, as the account of Uthmaan’s copies says.")),
            .step("3. **The regional differences the scholars recorded.** The few places where Uthmaan’s copies for different cities differed by a letter or a word, listed by ad-Daani and others, form a family tree that fits copying from one original, as Michael Cook showed in 2004, and early manuscripts have been found to carry them."),
            .step("4. **No second Quran.** Apart from the erased text in San‘a, no early manuscript has been shown to carry a different text: no extra surah, no missing one, no rival version of a passage. The theory of a text still forming two centuries after the Prophet (peace be upon him) has not survived the dating of the manuscripts."),
            .longOnly(.text("None of this was news to the Muslim scholars. Ad-Daani described the regional copies and their differences nine centuries before Cook, and the scholars of the rasm had recorded the open ta of ni‘mat place by place. The manuscripts confirm what the tradition had said about itself.")),
        ]),
        ArticleSection("WHAT THEY DO NOT SHOW", [
            .text("Honesty about evidence is part of the case, and Muslims gain nothing by overstating it. The manuscripts have limits."),
            .bullet("**Not the recitation.** With few dots and no vowel signs, the early copies preserve the outline of the words, not how they were pronounced. The readings are known from the chains of teachers, not from parchment."),
            .bullet("**Not an exact date.** Radiocarbon gives a range with a probability, for the parchment and not the ink, and the study of scripts gives an estimate. No surviving leaf can be proven to come from the Prophet’s lifetime, and none has been proven to be one of Uthmaan’s own copies."),
            .longOnly(.bullet("**Not a flawless copy.** Early copyists made ordinary slips, a letter dropped, a word repeated, a line skipped, and many are corrected on the page. These are mistakes of a copy, not of the text, and they are visible as mistakes precisely because the text was known.")),
            .longOnly(.bullet("**Not the whole Quran in one hand.** Most early manuscripts are fragments, and the evidence is built up from many of them.")),
            .longOnly(.bullet("**Not, by themselves, a proof of revelation.** They show that the text was fixed early and has not changed. That it is the speech of Allah is shown by other evidence: its challenge, its prophecies, and the character of the man who brought it.")),
            .door(.article("PreservationScriptView")),
        ]),
        ArticleSection("AN OPEN ARCHIVE", [
            .longOnly(.text("Western scholarship once hoped to do for the Quran what it had done for the Bible: gather the manuscripts and the reported variants and produce a critical edition. In the 1920s and 1930s Gotthelf Bergsträsser in Munich began collecting photographs of early manuscripts for that purpose, and in 1937 Arthur Jeffery published the variants of the Companions’ copies that he had drawn from Ibn Abi Daawood’s Kitaab al-Masaahif. Bergsträsser died in 1933 and his successor Otto Pretzl in 1941, and the photographs were long said to have been destroyed in the war. In fact they had been kept, and in the 1990s they passed to the scholars who began, in 2007, the Corpus Coranicum project of the Berlin-Brandenburg Academy of Sciences.")),
            .longOnly(.text("Corpus Coranicum has put images and transcriptions of many early manuscripts online, with a database of the variant readings reported in the classical books, and the joint French and German project Coranica carried out radiocarbon tests on early copies, the Tübingen manuscript among them. Its scholars do not write as Muslims, and Muslims need not accept their interpretations. But the archive they built has shown in detail what the Muslim sources had said all along: a single text, standardised within a generation of the Prophet (peace be upon him), copied ever since. The Quran itself invites that kind of examination:")),
            .shortOnly(.text("Western projects such as Corpus Coranicum in Berlin have since put images of many early manuscripts online. Their scholars do not write as Muslims, but the archive they built shows in detail what the Muslim sources had said all along: a single text, standardised within a generation of the Prophet (peace be upon him), copied ever since. The Quran itself invites that kind of examination:")),
            .ayah("4:82"),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Why don’t Uthmaan’s own copies survive?**"),
            .text("Parchment wears out with use, and Muslims did not treat old copies as relics to be kept at any cost. A worn copy was replaced and the old one put away respectfully, buried, washed or stored, which is how the San‘a hoard came to exist. The text was never kept in one object, so the loss of an object never threatened it. What the scholars did preserve, carefully, was a record of how Uthmaan’s copies spelled each word and where they differed from one another."),
            .markdown("**Do the manuscripts show that the Quran once had different words?**"),
            .text("The standard text in the early manuscripts differs from today’s mushaf only in spelling, in ordinary copying slips, and in the few regional variants that the scholars themselves recorded for Uthmaan’s copies and that are still recited. The one manuscript with a different text, the lower layer in San‘a, belongs to the copies from before the agreement and was overwritten with the standard text."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The oldest Quran manuscripts, the Birmingham leaves, the Tübingen copy, the Codex Parisino-Petropolitanus and the upper text in San‘a, show the Uthmaani text in use within decades of the Prophet (peace be upon him), sharing the same quirks of spelling and the same regional differences that Muslim scholars had recorded. The one erased copy outside that text confirms the sources’ account of copies set aside, and the codices legend ascribes to Uthmaan are later but carry the same text. The manuscripts do not record pronunciation and cannot give exact dates, and the Quran never depended on them; what they offer is an independent witness that agrees with the living one."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Hijaazi", arabic: "الخَطُّ الحِجَازِيُّ", meaning: "The **script of the Hijaaz**: the slanting, unadorned hand of the earliest copies, as in the Birmingham leaves and the Paris codex, with tall strokes leaning to the right and few dots."),
            .term("Kufic", arabic: "الخَطُّ الكُوفِيُّ", meaning: "The **angular script** named after Koofah that replaced the Hijaazi hand in large copies of the Quran, with broad, level letters, as in the Tübingen manuscript and the Samarkand codex."),
            .term("Raqq", arabic: "رَقّ", meaning: "**Parchment**, prepared animal skin, the material of the early copies. The word appears in 52:3, in the oath by a Book inscribed in parchment spread open."),
            .ayah("52:3"),
            .term("Al-Mushaf al-Imam", arabic: "المُصحَفُ الإِمَامُ", meaning: "**The master copy**: the name the early scholars gave to the copy Uthmaan kept in Madinah, against which the copies of the cities were measured."),
        ]),
    ]
}

struct PreservationNaskhView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "PreservationNaskhView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Abrogation (Naskh)")
        .englishArticle().selectableArticleList(article: "PreservationNaskhView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: naskh is Allah lifting a ruling He had revealed and putting another in its place, at a time He knew from the beginning. The Quran names it (2:106, 16:101), the Companions reported its cases, and the scholars found three kinds: a ruling lifted while its words are still recited, words lifted while the ruling remains, and both lifted together. It touches commands and prohibitions, never what Allah tells of Himself, the unseen or history; it is known only from the Prophet Muhammad (peace and blessings be upon him) and his Companions; and it ended with his death. It is not Allah changing His mind."),
        ]),
        ArticleSection("WHAT THE WORD MEANS", [
            .longOnly(.markdown("In Arabic, **naskh (نَسخ)** has two senses. It means to remove, as the Arabs said that the sun removed the shade, and it means to copy, as a scribe copies a book; the Quran uses the second sense for the record of deeds (45:29) and the writing on the tablets of Moosa (7:154). The scholars of law took the first. In their definition, naskh is **the lifting of a ruling established by revelation, by a later revelation**.")),
            .longOnly(.ayah("45:29", words: 5...10)),
            .longOnly(.ayah("7:154", words: 7...8)),
            .shortOnly(.text("In Arabic, naskh means to remove, as the sun removes the shade, and also to copy, as a scribe copies a book. The scholars of law took the first sense: naskh is the lifting of a ruling established by revelation, by a later revelation.")),
            .text("Each part of that definition does work. What is lifted is a ruling, not a fact. It was established by revelation, by the Quran or by the Sunnah, so a custom or a scholar’s opinion is not abrogated in this sense, and nothing but revelation can abrogate. The abrogating text came later, and the two cannot both be acted on; if they can be reconciled, there is no naskh. The earlier text is called mansookh, abrogated, and the later naasikh, abrogating."),
            .longOnly(.text("Much confusion comes from a change in how the word was used. Ibn al-Qayyim (may Allah have mercy on him) explains in I‘laam al-Muwaqqi‘een that the Salaf used naskh more widely than the later scholars: for lifting a ruling entirely, but also for narrowing a general statement, attaching a condition to an unrestricted one, or explaining what was unclear. So when a Companion or one of the Taabi‘oon says that a verse was abrogated, he sometimes means that another verse limited or explained it. Later writers who counted every such remark produced lists of hundreds of abrogated verses. The careful scholars cut them down: as-Suyooti in al-Itqaan kept about twenty, and Shah Wali Allah ad-Dihlawi (d. 1176 AH / 1762 CE) in al-Fawz al-Kabeer only five.")),
            .longOnly(.text("The subject has its own classical books, among them those of Abu Ubayd al-Qaasim ibn Sallaam (d. 224 AH / 838 CE), an-Nahhaas, Makki ibn Abi Taalib and Ibn al-Jawzi, and every scholar of tafseer and fiqh was expected to know it, because a verse acted on after its ruling was lifted is acted on wrongly.")),
            .shortOnly(.text("Much confusion comes from a change in how the word was used. The Salaf used naskh more widely than the later scholars, for narrowing or explaining a verse as well as for lifting its ruling, so the later lists of hundreds of abrogated verses were cut down by the careful scholars to about twenty, or even five.")),
        ]),
        ArticleSection("THE QURAN SPEAKS OF IT", [
            .text("Abrogation is not a theory the scholars devised to explain away difficulties. Allah announces it in His Book, with its reason:"),
            .ayah("2:106"),
            .ayah("16:101"),
            .longOnly(.text("The second verse records the objection it met in Makkah: when one verse took the place of another, the Prophet’s enemies called him a forger, and Allah answers that He knows best what He sends down. Many of the early commentators read a third verse as including the same truth, that Allah erases and confirms what He wills of what He commands, while the Mother of the Book, the original record with Him, does not change:")),
            .longOnly(.ayah("13:39")),
            .text("The plainest abrogation in the Prophet’s life was public, and it reached one mosque in the middle of a prayer. For sixteen or seventeen months in Madinah the Muslims prayed towards Jerusalem; then the command came to face the Ka‘bah:"),
            .hadith("bukhari:4486", cite: "Saheeh al-Bukhaari 4486", arabic: 20...78, english: [0...24, 46...106]),
            .longOnly(.text("Allah had foretold that the foolish would ask what turned the Muslims from their qiblah, and gave the answer before the question was asked (2:142). A community that turned its whole body in the middle of a prayer, on the word of one man who had prayed with the Prophet, understood naskh perfectly: the command is Allah’s, and when He changes it, the believer turns.")),
            .longOnly(.ayah("2:142")),
            .shortOnly(.text("A community that turned its whole body in the middle of a prayer, on the word of one man who had prayed with the Prophet, understood naskh perfectly: the command is Allah’s, and when He changes it, the believer turns.")),
        ]),
        ArticleSection("A RULING LIFTED, ITS WORDS RECITED", [
            .longOnly(.text("In the first kind, the verse stays in the mushaf and is recited in prayer, but its ruling no longer applies. Surah al-Baqarah has the clearest example. One verse gives a widow a year’s maintenance and residence by bequest; another, placed before it in the surah, sets her waiting period at four months and ten days:")),
            .longOnly(.ayah("2:240", words: 5...11)),
            .longOnly(.ayah("2:234", words: 5...9)),
            .longOnly(.text("The verse of the year came first and was abrogated by the verse of four months and ten days, and the bequest itself gave way to the widow’s share in inheritance. Abdullah ibn az-Zubayr (may Allah be pleased with him) asked Uthmaan (may Allah be pleased with him) why, then, the abrogated verse was still written in the copies, and received an answer that shows how the Companions treated the text:")),
            .shortOnly(.text("In the first kind, the verse stays in the mushaf and is recited in prayer, but its ruling no longer applies. In Surah al-Baqarah, the verse that gives a widow a year’s maintenance came first and was abrogated by the verse that sets her waiting period at four months and ten days, though the abrogated verse stands after it in the surah. Abdullah ibn az-Zubayr (may Allah be pleased with him) asked Uthmaan (may Allah be pleased with him) why the abrogated verse was still written in the copies:")),
            .hadith("bukhari:4530", cite: "Saheeh al-Bukhaari 4530", arabic: 17...44, english: [0...61]),
            .shortOnly(.text("The ruling had changed, but the words were Quran, placed by the Prophet (peace be upon him), and no one would move a letter of them.")),
            .longOnly(.text("The ruling had changed, but the words were Quran, placed by the Prophet (peace be upon him), and no one would move a letter of them. A second example is in Surah al-Anfaal, where the lightening is announced in the verse itself:")),
            .longOnly(.ayah("8:65-66", words: 26...40)),
            .longOnly(.hadith("bukhari:4653", cite: "Saheeh al-Bukhaari 4653", arabic: 40...84, english: [17...104])),
            .longOnly(.text("A third is the fast of Ramadan. At first a person able to fast could choose to feed a poor person for each day instead; then the command to fast the month made fasting itself the duty (2:184-185):")),
            .longOnly(.hadith("bukhari:4507", cite: "Saheeh al-Bukhaari 4507, Saheeh Muslim 1145", arabic: 24...43, english: [0...47])),
            .longOnly(.ayah("2:184-185")),
            .longOnly(.text("Ibn Abbaas (may Allah be pleased with him) held that the same verse still applies to the very old who cannot fast, who feed a poor person for each day instead (Saheeh al-Bukhaari 4505). The two Companions illustrate Ibn al-Qayyim’s point rather than contradict each other: for one the choice was lifted, for the other the verse remained, narrowed to those who truly cannot fast, and on the ruling itself they agree.")),
            .longOnly(.hadith("bukhari:4505", cite: "Saheeh al-Bukhaari 4505", arabic: 14...43, english: [0...67])),
            .text("Why keep a verse whose ruling is gone? It remains the speech of Allah, recited and rewarded. It records His mercy, since most such changes moved from a heavier duty to a lighter one. And it shows how the law was built, step by step, for a community that was learning."),
        ]),
        ArticleSection("WORDS LIFTED", [
            .text("In the second kind, the words were revealed and recited for a time and then lifted from the recitation, while the ruling remained. The verse of stoning is the example the Companions themselves gave. Umar ibn al-Khattaab (may Allah be pleased with him) said from the Prophet’s pulpit, before the Companions:"),
            .hadith("muslim:1691a", cite: "Saheeh Muslim 1691, Saheeh al-Bukhaari 6830", arabic: 45...116, english: [0...135]),
            .longOnly(.text("Umar did not claim that anything had been lost. He said that the verse had been sent down and recited, that the Prophet (peace be upon him) had applied it and the caliphs after him, and he feared only that a later generation, not finding it in the mushaf, would drop a duty Allah had laid down. The ruling stands by the Prophet’s practice and the consensus of the Companions; the words were lifted by Allah in the Prophet’s lifetime, and so they were not written in the copies.")),
            .shortOnly(.text("Umar did not claim that anything had been lost. The ruling stands by the Prophet’s practice and the consensus of the Companions; the words were lifted by Allah in the Prophet’s lifetime, and so they were not written in the copies.")),
            .longOnly(.text("Why lift the words and keep the ruling? Ibn al-Jawzi, as az-Zarkashi relates in al-Burhaan, saw in it a test of this ummah’s readiness to obey without demanding that every ruling stand in the recited text, as Ibraaheem (peace be upon him) hastened to sacrifice his son on the strength of a dream.")),
            .longOnly(.text("Verses that carried no ruling could be lifted in the same way. Anas (may Allah be pleased with him) reports a verse revealed about the seventy reciters killed by treachery at Bi’r Ma‘oonah, recited for a time and then lifted:")),
            .longOnly(.hadith("bukhari:2814", cite: "Saheeh al-Bukhaari 2814", arabic: 50...70, english: [36...81])),
            .markdown("In the third kind, **both the words and the ruling** were lifted. Aa’ishah (may Allah be pleased with her) reports it of the number of sucklings that make a foster relationship:"),
            .hadith("muslim:1452a", cite: "Saheeh Muslim 1452", arabic: 20...45, english: [8...53]),
            .longOnly(.text("The ten were abrogated in words and ruling alike. The five were abrogated in their words, and their ruling remained in the view of ash-Shaafi‘i and the better-known position of Ahmad. Aa’ishah’s last phrase, that the five were among what was recited when the Prophet (peace be upon him) died, is explained by an-Nawawi: the lifting of their recitation came so late that some had not yet heard of it and were still reciting them when he died; when they learned of it, they stopped, and all agreed that they are not recited.")),
            .shortOnly(.text("The ten were abrogated in words and ruling alike, and the five in their words. As an-Nawawi explains, the lifting of the recitation of the five came so late that some had not yet heard of it when the Prophet (peace be upon him) died; when they learned of it, they stopped, and all agreed that they are not recited.")),
            .longOnly(.text("And some passages Allah caused to be forgotten, as 2:106 names beside abrogation and 87:6-7 confirms: the Prophet would not forget except what Allah willed. Abu Moosa al-Ash‘ari (may Allah be pleased with him) told the three hundred reciters of Basrah of two surahs that they had recited and that he had since forgotten, except for a line of each (Saheeh Muslim 1050).")),
            .longOnly(.ayah("87:6-7")),
            .longOnly(.hadith("muslim:1050", cite: "Saheeh Muslim 1050", arabic: 53...116, english: [46...178])),
            .text("Every case of this kind was reported by the Companions themselves, with chains, in the most rigorous books of hadith. These are not admissions that something slipped away. They are reports of what Allah lifted, in the Prophet’s lifetime and by His own decision, before the final review of the Quran with Jibreel and long before it was gathered into one volume."),
            .door(.article("PreservationClaimsView")),
        ]),
        ArticleSection("NOT A CHANGE OF MIND", [
            .markdown("The commonest objection to abrogation, raised first by some of the Jews of Madinah, is that it would mean Allah changed His mind. The Arabic for that is **badaa’ (بَدَاء)**: something becoming apparent that was not known before. It is impossible for Allah, whose knowledge has no beginning and no gap. When He revealed the first ruling, He knew that He would lift it, when He would lift it and what He would put in its place. What changes is what He commands at each time, by a decree written before any of it happened."),
            .text("A good teacher plans a whole course before the first lesson and moves the class to the next exercise when it is ready, and no one says he changed his mind on the day the class moved on. The comparison falls short, as every comparison with Allah does, because a teacher’s plan can fail and Allah’s cannot; but it shows why a later instruction does not imply ignorance earlier."),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) answers the objection under 2:106 from the earlier scripture itself. The children of Aadam married brother to sister, which was later forbidden; Nooh was permitted every animal after the ark, and later laws forbade some; Ya‘qoob was married to two sisters at once, which the Torah later prohibited. A law that moves with the stages of a people is no contradiction in its Lawgiver.")),
            .longOnly(.text("Badaa’ has a chapter of its own in al-Kulayni’s al-Kaafi, the main hadith collection of the Twelver Shia, who apply it among other things to the succession of their imams. Ahl as-Sunnah reject attributing badaa’ to Allah in any form. What He commands changes by His wisdom; what He knows never changes.")),
        ]),
        ArticleSection("KNOWN ONLY BY REPORT", [
            .longOnly(.text("Because naskh lifts a ruling of revelation, only revelation can establish it. The scholars recognise a few ways in which it is known:")),
            .longOnly(.step("1. **The Prophet says so.** He told his Companions, for example, that he had forbidden them to visit graves and that they could now visit them (Saheeh Muslim 977).")),
            .longOnly(.hadith("muslim:977a", cite: "Saheeh Muslim 977", arabic: 55...82, english: [0...61])),
            .longOnly(.step("2. **A Companion reports which came last.** Jaabir ibn Abdullah (may Allah be pleased with him) reported the order of two practices in ablution:")),
            .longOnly(.hadith("abudawud:192", cite: "Sunan Abi Daawood 192; graded saheeh by al-Albaani", arabic: 23...37, english: [0...26])),
            .longOnly(.step("3. **The ummah agrees** that a ruling is no longer in force, which shows that an abrogating text reached them even where it is not quoted.")),
            .longOnly(.step("4. **The dates are known and the texts truly conflict**, so that the later must replace the earlier.")),
            .longOnly(.text("What does not establish abrogation matters as much: that a ruling feels hard, that times have changed, that a later scholar prefers another view, or that two texts look different at first sight. The rule is to reconcile first. A verse that commands patience and a verse that commands fighting can each apply in its own situation, and az-Zarkashi called such commands deferred rather than abrogated: they return whenever their situation returns. The claim that a single verse of fighting abrogated more than a hundred verses of patience and forgiveness comes from that later habit of counting, and the careful scholars did not accept it.")),
            .longOnly(.text("Abrogation also ended with the Prophet’s death, because revelation ended with it. Nothing he left in force can be lifted by anyone after him.")),
            .shortOnly(.text("Because naskh lifts a ruling of revelation, only revelation can establish it: the Prophet’s own word, a Companion’s report of which came last, or the agreement of the ummah. That a ruling feels hard, that times have changed, or that two texts look different at first sight does not establish it; the rule is to reconcile first. And abrogation ended with the Prophet’s death, because revelation ended with it.")),
        ]),
        ArticleSection("NO ABROGATION IN NEWS OR BELIEF", [
            .longOnly(.markdown("Abrogation touches **commands and prohibitions**. It does not touch **reports**: what Allah tells of Himself, His names and attributes, the angels, the prophets, the past, the Hereafter and what is to come. A report that is true cannot become false, and one that was false could never have come from Allah. So the beliefs of Islam and its basic morals, truthfulness, justice, honouring parents, the prohibition of shirk, were never abrogated, and they are the same in every message Allah sent:")),
            .longOnly(.ayah("42:13", words: 1...23)),
            .shortOnly(.text("Abrogation touches commands and prohibitions. It does not touch reports: what Allah tells of Himself, the unseen, the past and what is to come, since a true report cannot become false. So the beliefs of Islam and its basic morals were never abrogated, and they are the same in every message Allah sent.")),
            .longOnly(.text("The laws, by contrast, differed from one messenger to another, for each community a law and a way (5:48). Naskh within the Quran is the same principle on a smaller scale: the religion is one, and its laws were given in stages.")),
            .longOnly(.ayah("5:48", words: 24...28)),
            .longOnly(.text("One case seems to test the rule. When 2:284 was revealed, saying that Allah will call people to account for what is within themselves whether they show it or hide it, the Companions came to the Prophet (peace be upon him) on their knees, saying that this was beyond their power. He told them to say, we hear and we obey, and they said it until it flowed on their tongues. Then:")),
            .longOnly(.hadith("muslim:125", cite: "Saheeh Muslim 125", arabic: 189...218, english: [280...328])),
            .longOnly(.ayah("2:284")),
            .longOnly(.text("Abu Hurayrah calls it abrogation, and Ibn Umar (may Allah be pleased with them) said the same (Saheeh al-Bukhaari 4545).")),
            .longOnly(.hadith("bukhari:4545", cite: "Saheeh al-Bukhaari 4545", arabic: 23...35, english: [0...14])),
            .longOnly(.text("But 2:284 is a statement, not a command, and a true statement cannot be lifted. The scholars, Ibn Taymiyyah and Ibn al-Qayyim among them, explain it as naskh in the Salaf’s wider sense: what was lifted was the burden the Companions had understood, that every passing thought would be held against them, and the verses after it made clear that Allah charges no soul beyond its capacity. The Prophet (peace be upon him) put the same truth in plain words:")),
            .longOnly(.hadith("bukhari:5269", cite: "Saheeh al-Bukhaari 5269, Saheeh Muslim 127", arabic: 29...42, english: [4...28])),
            .longOnly(.text("The verse of Bi’r Ma‘oonah above is the same. Its recitation was lifted; what it reported, that the martyrs had met their Lord and He was pleased with them, did not become untrue.")),
        ]),
        ArticleSection("THE WISDOM IN IT", [
            .text("The Quran gives the reason in the verse that announces abrogation: Allah brings something better or similar. The scholars have drawn out what that means in practice."),
            .bullet("**Gradual training.** A community taken from idolatry to the whole law in a day would have broken under it. The prohibition of wine came in stages for that reason, as the chapter on the stages of revelation shows."),
            .longOnly(.bullet("**Ease and mercy.** Most abrogations moved from heavier to lighter: one against ten became one against two, and the nights of Ramadan, at first kept apart from husband and wife, were opened to them (2:187).")),
            .longOnly(.ayah("2:187", words: 0...6)),
            .shortOnly(.bullet("**Ease and mercy.** Most abrogations moved from a heavier duty to a lighter one.")),
            .longOnly(.bullet("**A test of obedience.** Allah says of the first qiblah that He appointed it to make evident who would follow the Messenger and who would turn back on his heels.")),
            .longOnly(.ayah("2:143", words: 12...26)),
            .bullet("**A greater reward.** Sometimes the later ruling was heavier, as when the choice between fasting and feeding became the duty to fast, and its reward grew with it."),
            .text("In every case the change came from the One who knew both rulings from the start, through the Messenger who conveyed both, and was recorded by the Companions who lived through both."),
            .door(.article("PreservationStagesView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Does abrogation mean that part of the Quran was lost?**"),
            .text("No. What Allah lifted, He lifted Himself, in the Prophet’s lifetime, and the Companions reported it. What He did not lift was recited, memorised, written, and reviewed with Jibreel twice in the Prophet’s last Ramadan. Lost would mean that something Allah meant to remain was not kept, and He promised that would never happen (15:9)."),
            .ayah("15:9"),
            .longOnly(.markdown("**Can a ruling be abrogated today because circumstances have changed?**")),
            .longOnly(.text("No. Abrogation needs a revelation, and revelation ended with the Prophet (peace be upon him). Some rulings were tied by the Lawgiver to a condition and apply only where it exists, which the scholars discuss under their own headings. That is not abrogation, and it gives no one the right to set a ruling aside.")),
            .longOnly(.door(.article("QuranSunnahView"))),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Naskh is the lifting of a revealed ruling by a later revelation, announced in the Quran and reported case by case by the Companions. Some verses are recited though their ruling is lifted, some rulings stand though their words were lifted, and some passages were lifted entirely, all in the Prophet’s lifetime and by Allah’s decision. It never touches what Allah reports or the beliefs He revealed, it is known only by a report from the Prophet and his Companions, it ended when revelation ended, and it is the unfolding of a plan Allah knew from the start, not a change of mind."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Naskh", arabic: "نَسخ", meaning: "From **ن-س-خ**, to remove and to copy: in law, the **lifting of a ruling established by revelation, by a later revelation**."),
            .term("Naasikh and mansookh", arabic: "النَّاسِخُ وَالمَنسُوخُ", meaning: "The **abrogating** text and the **abrogated** one. Knowing which is which was counted among the first requirements for anyone who explains the Quran or gives a ruling."),
            .term("Badaa’", arabic: "بَدَاء", meaning: "From **ب-د-و**, to appear: **new knowledge appearing after ignorance**. Ahl as-Sunnah deny it of Allah, and abrogation does not imply it."),
            .term("Takhsees", arabic: "تَخصِيص", meaning: "**Specification**: narrowing a general text to some of what it covers. The Salaf sometimes called it naskh, which is why some early remarks about abrogated verses mean only this."),
        ]),
    ]
}

struct PreservationClaimsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "PreservationClaimsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering the Claims of Corruption")
        .englishArticle().selectableArticleList(article: "PreservationClaimsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: every claim that the Quran was altered rests on a handful of reports, most of them about the Companions (may Allah be pleased with them), that the Muslims themselves recorded and examined: Ibn Mas‘ood’s copy without the two surahs of refuge, Ubayy’s copy with two prayers of qunoot, Uthmaan’s burning of the other copies, a sheet eaten by an animal, al-Ahzaab once longer, the Shia narrations of tahreef, and al-Hajjaaj’s supposed changes. Read in full, each is a recitation Allah lifted in the lifetime of the Prophet Muhammad (peace and blessings be upon him), a private note in a private copy, one Companion’s view that the others corrected, or a report too weak to carry any claim. Against them stands a text carried by whole generations at once, which no single report can add to or take from."),
        ]),
        ArticleSection("WHO MUST BRING THE PROOF", [
            .text("Every claim that the Quran was changed is, in the end, a claim about evidence, and the Prophet (peace be upon him) laid down the rule for claims:"),
            .hadith("muslim:1711a", cite: "Saheeh Muslim 1711, Saheeh al-Bukhaari 4552", arabic: 30...43, english: [0...27]),
            .markdown("The Quran is established by **tawaatur (تَوَاتُر)**: whole generations reciting the same text at once, in every city, each generation from the one before. No single report can make a verse Quran; that is why a reading carried by one chain, however sound, is not recited as Quran. For the same reason, no single report can unmake one. Whoever says that a surah was dropped or a verse added must bring evidence of the same weight as the text he challenges, and none has ever been brought."),
            .longOnly(.text("A second fact changes the whole discussion. Almost every report the critics cite comes from the Muslims’ own books: Ibn Abi Daawood’s Kitaab al-Masaahif, Abu Ubayd’s Fadaa’il al-Quran, the collections of hadith, as-Suyooti’s al-Itqaan. The scholars recorded these reports with their chains, graded them and explained them, openly, for centuries. When Arthur Jeffery set out in 1937 to collect the variants of the Companions’ copies, his main source was a Muslim book. A community hiding a corruption does not publish the evidence for it.")),
            .longOnly(.text("Some claims rest on misreading even sound reports. Zayd ibn Thaabit (may Allah be pleased with him) said that while copying the mushaf for Uthmaan he found a verse of al-Ahzaab only with Khuzaymah ibn Thaabit:")),
            .longOnly(.hadith("tirmidhi:3104", cite: "Jaami‘ at-Tirmidhi 3104; graded saheeh by al-Albaani; also Saheeh al-Bukhaari 4988", arabic: 149...189, english: [224...291])),
            .longOnly(.text("Zayd says in the same breath that he used to hear the Prophet (peace be upon him) recite it. He knew it by heart, as others did; what he was looking for was its written record from the Prophet’s scribes, because the copies were made from writing and memory together, each checking the other. Ibn Hajar explains the report in exactly this way.")),
            .shortOnly(.text("A second fact changes the whole discussion. Almost every report the critics cite comes from the Muslims’ own books, whose scholars recorded these reports with their chains, graded them and explained them, openly, for centuries. A community hiding a corruption does not publish the evidence for it.")),
        ]),
        ArticleSection("IBN MAS‘OOD AND THE TWO SURAHS OF REFUGE", [
            .text("The most serious report concerns Abdullah ibn Mas‘ood (may Allah be pleased with him), one of the four from whom the Prophet (peace be upon him) told his Companions to learn the Quran. His student Zirr ibn Hubaysh took a question about him to Ubayy ibn Ka‘b (may Allah be pleased with him):"),
            .hadith("bukhari:4977", cite: "Saheeh al-Bukhaari 4977", arabic: 26...60, english: [5...64]),
            .longOnly(.text("A fuller report in the Musnad of Imam Ahmad says what “so-and-so” was: Ibn Mas‘ood would rub al-Falaq and an-Naas out of his copies, saying that they were not of the Book of Allah. Some scholars, an-Nawawi and Ibn Hazm among them, rejected the report as a lie told about him. Ibn Hajar (may Allah have mercy on him), the great commentator on al-Bukhaari, would not dismiss a sound chain:")),
            .longOnly(.quote(text: "“Rejecting sound narrations without a basis is not accepted. Rather, the narration is sound, and it can be interpreted.” (Ibn Hajar, Fath al-Baari, commentary on the tafseer of al-Mu‘awwidhatayn)", arabic: "الطَّعنُ فِي الرِّوَايَاتِ الصَّحِيحَةِ بِغَيرِ مُستَنَدٍ لَا يُقبَلُ، بَلِ الرِّوَايَةُ صَحِيحَةٌ وَالتَّأوِيلُ مُحتَمَلٌ", dimmed: true)),
            .longOnly(.text("The interpretations all begin from what the report does not say. Ibn Mas‘ood never denied that the two surahs came from Allah; the Prophet recited them, and he knew it. Ibn Qutaybah explained that he had seen the Prophet (peace be upon him) recite them over al-Hasan and al-Husayn as words of protection, as he recited other words of refuge over them, and concluded that they were prayers of protection rather than part of what was to be written in the mushaf:")),
            .longOnly(.hadith("bukhari:3371", cite: "Saheeh al-Bukhaari 3371", arabic: 24...54, english: [0...55])),
            .longOnly(.text("Others said that he would write in his copy only what he knew the Prophet had ordered written, and had not heard that order for these two; it is also reported in the books on the masaahif that he left al-Faatihah out of his copy, though no one, he least of all, doubted that it was Quran. Either way, his was one man’s view, held before the evidence reached him, and the Companions as a whole held the opposite. Uqbah ibn Aamir (may Allah be pleased with him) heard the Prophet say of the two surahs:")),
            .longOnly(.hadith("muslim:814a", cite: "Saheeh Muslim 814", arabic: 26...45, english: [0...37])),
            .longOnly(.text("He also reports that the Prophet led the dawn prayer with them (Sunan Abi Daawood 1462; graded saheeh by al-Albaani). The decisive answer is in the readings themselves. Aasim’s reading as Shu‘bah carried it comes from Zirr ibn Hubaysh from Ibn Mas‘ood, and the readings of Hamzah, al-Kisaa’i and Khalaf also go back through Ibn Mas‘ood’s students. Every one of them contains al-Falaq and an-Naas. The very man who carried the question to Ubayy passed the two surahs on, in Ibn Mas‘ood’s own line of recitation.")),
            .longOnly(.hadith("abudawud:1462", cite: "Sunan Abi Daawood 1462; graded saheeh by al-Albaani", arabic: 24...75, english: [0...81])),
            .shortOnly(.text("A fuller report in the Musnad of Imam Ahmad says that Ibn Mas‘ood would rub al-Falaq and an-Naas out of his copies. He never denied that the two surahs came from Allah; Ibn Qutaybah explained that he took them for prayers of protection rather than part of what was to be written in the mushaf. It was one man’s view, held before the evidence reached him, and the readings that come down through his own students, Aasim’s among them, all contain al-Falaq and an-Naas.")),
            .text("Today the matter is closed. The two surahs are mass-transmitted and agreed upon, and the scholars state, as an-Nawawi does in al-Majmoo‘, that whoever now denies al-Faatihah or either of them has disbelieved. Ibn Mas‘ood is excused, because the agreement had not yet reached him; no one after it is."),
        ]),
        ArticleSection("UBAYY'S COPY AND THE QUNOOT", [
            .longOnly(.text("The opposite claim is made about Ubayy ibn Ka‘b (may Allah be pleased with him): that his copy had two surahs more than ours. Reports collected by Abu Ubayd in Fadaa’il al-Quran, and later by as-Suyooti, say that after the last surah it contained two short prayers, which they call al-Khal‘ and al-Hafd. Their words are familiar to Muslims, because they are a supplication of qunoot: O Allah, we seek Your help and Your forgiveness, we praise You and do not deny You; O Allah, You alone we worship, to You we pray and prostrate, and to You we hasten.")),
            .longOnly(.text("Three facts answer the claim. First, a private copy belonged to its owner, and the Companions wrote in theirs what they wished to keep: a prayer, an explanation, a note. Ubayy’s writing a prayer after the Quran no more made it Quran than a Muslim today makes a dua Quran by writing it inside the cover of his mushaf. Second, the Companions knew that Ubayy kept recitations that had been lifted. Umar (may Allah be pleased with him) said of him:")),
            .longOnly(.hadith("bukhari:5005", cite: "Saheeh al-Bukhaari 5005", arabic: 23...57, english: [2...66])),
            .longOnly(.text("Third, Ubayy’s own recitation reached us, and it does not contain these prayers. The readings of Naafi‘ of Madinah, Ibn Katheer of Makkah and Abu Amr of Basrah all run through his students, and every one of them has 114 surahs ending with an-Naas. Nor were the prayers lost. Muslims still say them in qunoot, as a supplication, which is all they ever were.")),
            .shortOnly(.text("The opposite claim is made about Ubayy ibn Ka‘b (may Allah be pleased with him): that his copy had two short prayers after the last surah, which are in fact a supplication of qunoot. But a private copy belonged to its owner, and writing a prayer in it no more made it Quran than a Muslim today makes a dua Quran by writing it inside the cover of his mushaf. And Ubayy’s own recitation, which reached us through the readings of Naafi‘, Ibn Katheer and Abu Amr, has 114 surahs ending with an-Naas.")),
        ]),
        ArticleSection("WHY UTHMAAN BURNED THE OTHER COPIES", [
            .text("Critics often ask why Uthmaan (may Allah be pleased with him) would burn copies of the Quran if he had nothing to hide. The answer is in the report of why he acted at all. Hudhayfah ibn al-Yamaan (may Allah be pleased with him) came back from the campaign in Armenia and Azerbaijan alarmed at how the soldiers of Shaam and Iraq were quarrelling over their recitations:"),
            .hadith("bukhari:4987", cite: "Saheeh al-Bukhaari 4987", arabic: 38...51, english: [50...71]),
            .longOnly(.text("Uthmaan did not compose a text. He had the sheets gathered under Abu Bakr (may Allah be pleased with him), which Hafsah kept, copied by a committee under Zayd ibn Thaabit (may Allah be pleased with them both), sent the copies to the cities, and ordered the other written materials burned. Those materials were private copies and pages that mixed the Quran with explanations, prayers and recitations that had been lifted, in differing orders and wordings. Left in circulation, they would have kept alive the very quarrel Hudhayfah feared. Burning was a respectful way to dispose of written pages that would no longer be used, so that nothing bearing Allah’s words would be trampled.")),
            .longOnly(.text("The Companions agreed. Ali ibn Abi Taalib (may Allah be pleased with him), who would have had every reason to object if anything had been lost, is reported by Ibn Abi Daawood, with a chain Ibn Hajar graded sound, to have said that Uthmaan did nothing with the copies except in consultation with them. The one objection on record came from Ibn Mas‘ood (may Allah be pleased with him), and it was not about the text:")),
            .longOnly(.hadith("nasai:5064", cite: "Sunan an-Nasaa’i 5064; graded saheeh by al-Albaani", arabic: 24...51, english: [6...44])),
            .longOnly(.text("He felt passed over for a younger man, and he told his students in Iraq to keep their copies; az-Zuhri adds that the leading Companions disliked his position (Jaami‘ at-Tirmidhi 3104; graded saheeh by al-Albaani). He never said that Zayd’s copy was wrong, and the readings of Koofah that come down from him are recited today within Uthmaan’s writing.")),
            .shortOnly(.text("Uthmaan did not compose a text. He had the sheets gathered under Abu Bakr copied by a committee under Zayd ibn Thaabit, sent the copies to the cities, and ordered the other written materials burned: private copies and pages that mixed the Quran with explanations, prayers and lifted recitations, which would have kept alive the very quarrel Hudhayfah feared. Burning was a respectful way to dispose of them, and the Companions, Ali among them, agreed.")),
            .door(.article("CompileView")),
        ]),
        ArticleSection("A SHEET, AN ANIMAL AND THE LENGTH OF AL-AHZAAB", [
            .longOnly(.text("Two more reports are often put together. In one, in Sunan Ibn Maajah 1944, Aa’ishah (may Allah be pleased with her) says that the verse of stoning and a verse on suckling were revealed, that the sheet holding them was with her, and that when the Prophet (peace be upon him) died and they were occupied with his death, a domestic animal came in and ate it.")),
            .longOnly(.text("Its chain is disputed. Darussalam’s edition grades it hasan, but the same report comes through Maalik from the same teacher, Abdullah ibn Abi Bakr, from Amrah, from Aa’ishah, with no sheet and no animal (Saheeh Muslim 1452), and critics have judged that detail an addition by Muhammad ibn Ishaaq that the more precise narrators did not carry. And even if it were accepted, what it describes had already been lifted. The words of the verse of stoning were lifted in the Prophet’s lifetime while its ruling stayed, as Umar (may Allah be pleased with him) declared from the pulpit; the verse of ten sucklings was abrogated by five, and the words of the five were lifted too. A page of abrogated verses, eaten or not, takes nothing from the Quran, which was never kept on a single sheet in anyone’s room. It was in the memories of hundreds of Companions and in the hands of many scribes.")),
            .longOnly(.hadith("muslim:1452a", cite: "Saheeh Muslim 1452", arabic: 20...45, english: [0...53])),
            .longOnly(.text("In the second, Ubayy ibn Ka‘b (may Allah be pleased with him) asked Zirr ibn Hubaysh how many aayaat he counted in Surah al-Ahzaab and, on hearing seventy-three, said that he had known it equal in length to al-Baqarah, and that the verse of stoning had been in it. The report is in the Musnad of Imam Ahmad. Ibn Katheer, opening his tafseer of al-Ahzaab, judged its chain hasan and explained it as Quran that was revealed in the surah and then lifted, in words and ruling. That is how Ubayy understood it himself. He was not accusing anyone of dropping aayaat; had anyone done so, he, the best reciter among them, would have recited what was dropped, and his students would have carried it.")),
            .shortOnly(.text("Two more reports are often put together: that a sheet holding the verse of stoning and a verse on suckling was eaten by an animal after the Prophet’s death, and that Ubayy knew Surah al-Ahzaab once as long as al-Baqarah. The first has a disputed chain, and both describe verses Allah had already lifted in the Prophet’s lifetime. A page of abrogated verses, eaten or not, takes nothing from the Quran, which was never kept on a single sheet in anyone’s room.")),
            .door(.article("PreservationNaskhView")),
        ]),
        ArticleSection("THE SHIA CLAIM OF TAHREEF", [
            .longOnly(.markdown("**Tahreef (تَحرِيف)** means distorting a text. The claim that the Quran was distorted after the Prophet (peace be upon him), by Companions said to have suppressed verses about Ali and his descendants, appears in the classical hadith books of the Twelver Shia. Al-Kulayni’s al-Kaafi (2/634) carries a narration that the Quran Jibreel brought had seventeen thousand aayaat, against the 6,236 that are recited; in the nineteenth century Husayn an-Noori at-Tabarsi gathered such narrations into a whole book, Fasl al-Khitaab fi Tahreef Kitaab Rabb al-Arbaab. Later centuries also produced two so-called surahs, an-Noorayn and al-Wilaayah, stitched together from phrases of real aayaat, which no chain supports.")),
            .longOnly(.text("Fairness requires saying what Shia scholars themselves have held. Ibn Baabawayh as-Sadooq (d. 381 AH / 991 CE) wrote in his statement of Twelver belief that the Quran is what lies between the two covers in the hands of the people, no more, and that whoever attributes to them a belief in more than that is lying. Ash-Shareef al-Murtada and at-Toosi also rejected the claim, and most Shia today recite the same mushaf as every other Muslim and say that they reject it. Ahl as-Sunnah judge the claim, from whoever it comes, by what Allah said of His Book:")),
            .shortOnly(.text("The claim that the Quran was distorted after the Prophet (peace be upon him), by Companions said to have suppressed verses about Ali and his descendants, appears in the classical hadith books of the Twelver Shia, though Shia scholars such as Ibn Baabawayh as-Sadooq rejected it and most Shia today recite the same mushaf as every other Muslim. Ahl as-Sunnah judge the claim, from whoever it comes, by what Allah said of His Book:")),
            .ayah("41:41-42", words: 6...21),
            .longOnly(.text("The claim also fails by its own history. Ali (may Allah be pleased with him) ruled as caliph for nearly five years, with every power to bring out a complete Quran if one had been hidden, and he led the prayer and taught from the copies of Uthmaan, whose work he defended. The reading most of the world recites, Hafs from Aasim, comes through Abu Abd ar-Rahman as-Sulami from Ali himself, and the chains of Hamzah and al-Kisaa’i include al-Husayn ibn Ali. The household of the Prophet recited the Quran that every Muslim recites. To claim that they knew of a fuller one and hid it is to accuse them, not the Companions, of betraying the trust.")),
            .longOnly(.text("The scholars of Ahl as-Sunnah state the ruling plainly: whoever believes that the Quran in the hands of the Muslims is incomplete, that verses were dropped or hidden, has disbelieved, because he denies Allah’s promise to guard it. Al-Qaadi Iyaad records this as agreed in ash-Shifa, and Ibn Taymiyyah says the same in as-Saarim al-Maslool. The ruling concerns the belief. Judging a particular person is left to the scholars, with care, once its conditions are met.")),
            .shortOnly(.text("The claim also fails by its own history. Ali (may Allah be pleased with him) ruled as caliph for nearly five years, with every power to bring out a complete Quran if one had been hidden, and he led the prayer and taught from the copies of Uthmaan. Whoever believes that the Quran in the hands of the Muslims is incomplete has disbelieved, because he denies Allah’s promise to guard it.")),
            .door(.article("ShiaAnswerView")),
        ]),
        ArticleSection("AL-HAJJAAJ AND HIS CHANGES", [
            .text("The last claim concerns al-Hajjaaj ibn Yoosuf (d. 95 AH / 714 CE), the harsh Umayyad governor of Iraq. Ibn Abi Daawood’s Kitaab al-Masaahif contains a report that al-Hajjaaj changed eleven letters in Uthmaan’s copy. Its chain runs through Abbaad ibn Suhayb, whom the hadith critics abandoned as a narrator, and a report resting on an abandoned narrator cannot establish anything, least of all a change to the Quran."),
            .longOnly(.text("Other reports describe al-Hajjaaj’s real interest in the mushaf: in his time the students of Abu al-Aswad completed the dots that tell letters apart, and he is said to have had the letters of the mushaf counted. Neither changes a letter. And the history makes the claim impossible in any case. Al-Hajjaaj governed Iraq, not Makkah, Madinah, Shaam or Egypt, each with its own copy from Uthmaan and its own reciters. His own provinces were full of memorisers who hated him; he put one of the greatest of them, Sa‘eed ibn Jubayr, to death. Aasim, whose reading most Muslims recite, was teaching in Koofah under his rule. A governor who altered the Quran would have been denounced in every city he did not rule, and his alteration would have stopped at his border.")),
            .longOnly(.text("The manuscripts settle it. The Tübingen copy, its parchment dated to 649–675 CE, and the Birmingham leaves were almost certainly written before al-Hajjaaj came to Iraq in 75 AH (694 CE), and their text is the text recited today.")),
            .shortOnly(.text("The history makes the claim impossible in any case. Al-Hajjaaj governed Iraq, not Makkah, Madinah, Shaam or Egypt, each with its own copy from Uthmaan and its own reciters, and the Tübingen copy and the Birmingham leaves, almost certainly written before he came to Iraq, carry the text recited today.")),
            .door(.article("PreservationManuscriptsView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Don’t the different readings show that the text changed?**")),
            .longOnly(.text("No. The canonical readings were taught by the Prophet (peace be upon him) himself, fit the one written outline the Companions agreed on, and never contradict one another. They are part of what was preserved, recorded letter by letter, not evidence of drift.")),
            .longOnly(.door(.article("QiraatContradictView"))),
            .longOnly(.markdown("**Doesn’t the San‘a palimpsest prove there was another Quran?**")),
            .longOnly(.text("It shows that before Uthmaan’s copies, some Companions’ copies differed in wording, which the Muslim sources always said. The upper text of the same parchment is the standard Quran, written over the older one.")),
            .longOnly(.door(.article("ProvingPreservationView"))),
            .markdown("**If Muslims admit that some verses were lifted, how can they say nothing is missing?**"),
            .text("Because lifted is not missing. Allah lifted what He willed in the Prophet’s lifetime, and the Companions reported it openly. Missing would mean that something Allah meant to remain in the Quran failed to reach us. That has never been shown of a single verse, and Allah promised that it never would be."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The claims of corruption come from the Muslims’ own records, and those records answer them. Ibn Mas‘ood’s hesitation over the two surahs of refuge was one man’s view before the evidence reached him, and his own students recite both. Ubayy’s prayers of qunoot were a note in a private copy, and his students recite 114 surahs. Uthmaan burned private copies to end a quarrel, with the agreement of the Companions and of Ali. The eaten sheet and the longer al-Ahzaab describe verses Allah had already lifted. The Shia narrations of tahreef are rejected by the Quran, by Ali’s own conduct and by many Shia scholars, and al-Hajjaaj’s supposed changes rest on an abandoned narrator and are refuted by manuscripts older than his rule. No claim has ever met the burden it carries: evidence as strong as a text recited by whole generations at once."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Tahreef", arabic: "تَحرِيف", meaning: "From **ح-ر-ف**, an edge: **distorting a text**, by changing its words or bending its meaning. The Quran uses it of those who altered the earlier scripture (4:46)."),
            .ayah("4:46", words: 3...6),
            .term("Tawaatur", arabic: "تَوَاتُر", meaning: "**Mass transmission**: a text or report carried by so many at every stage that their agreeing on an error is impossible. The Quran is established by it, and no single report can add to it or take from it."),
            .term("Al-Mu‘awwidhataan", arabic: "المُعَوِّذَتَانِ", meaning: "**The two surahs of refuge**, al-Falaq and an-Naas, each opening with the command to seek refuge with Allah. The Prophet (peace be upon him) recited them in prayer, and over himself when he was ill."),
            .term("Qunoot", arabic: "قُنُوت", meaning: "**Supplication standing in prayer**, in the witr or in times of calamity. The prayer that some reports place in Ubayy’s copy is one of its well-known forms."),
        ]),
    ]
}
