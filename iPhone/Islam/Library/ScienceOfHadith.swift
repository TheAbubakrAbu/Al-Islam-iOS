import SwiftUI

// Science of Hadith: how every narration is checked, graded and preserved.
// Written 2026-11-24 (Abu: "Add these new Islamic resources"), Sunni upon the way of the Salaf, and held
// to the app's rules: every ayah a `.ayah(` reference into the bundled Quran, every hadith a `.hadith(`
// reference into the bundled shelf graded sahih or hasan, scholars' words quoted only with their source.
// The chapters are catalog articles (`IslamArticleCatalog`, home `.hadithScience`), drawn by
// IslamLibraryView, so search, the Ask AI corpus and each page's own search reach them.

// MARK: - hadith-1

struct HadithScienceTermsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithScienceTermsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Terms of Hadith")
        .englishArticle().selectableArticleList(article: "HadithScienceTermsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the hadith scholars describe every report with a small, exact vocabulary, and once a reader knows it, a grading note such as “mawqoof with a saheeh chain” or “hasan ghareeb” stops being code. This glossary sets the terms out in families: who is speaking at the end of a report, the shape of its chain, how many carried it, the grades, how a lone report is checked for support, the defects that hide in chains and texts, and the words narrators used to pass a report on. Each term is shown at work in a real narration, so that the word and the thing it names can be seen together."),
        ]),
        ArticleSection("WHO IS SPEAKING", [
            .text("The first question asked of any report is whose words it ends with. A chain can be flawless and the report still not be a hadith of the Prophet Muhammad (peace and blessings be upon him), because the last man in it was a Companion speaking for himself, or a Successor giving his own view."),
            .term("Marfoo‘", arabic: "مَرفُوع", meaning: "**Raised** to the Prophet ﷺ: his saying, his action, his approval, or a description of him. The word names the speaker, not the strength: a marfoo‘ report can be saheeh or fabricated."),
            .term("Mawqoof", arabic: "مَوقُوف", meaning: "**Stopped** at a Companion: his own saying or deed. A mawqoof report can have a flawless chain; it is then a saheeh report of a Companion’s words, not of the Prophet’s."),
            .term("Maqtoo‘", arabic: "مَقطُوع", meaning: "**Cut off** at a Successor (taabi‘i) or someone after him. It says where the report ends, not that its chain has a gap."),
            .term("Hadith Qudsi", arabic: "حَدِيث قُدسِي", meaning: "A marfoo‘ hadith in which the Prophet ﷺ relates from his Lord. It is graded like any other hadith, and it is not Quran."),
            .door(.article("HadithScienceQudsiView")),
            .longOnly(.text("A mawqoof report is not worthless for being a Companion’s. Al-Bukhaari heads a chapter of his Book of Knowledge with the words of Ali ibn Abi Taalib (may Allah be pleased with him), “Speak to people with what they know: do you want Allah and His Messenger to be denied?”, and then gives their chain, so that the saying stands as a connected mawqoof report (Saheeh al-Bukhaari 127).")),
            .longOnly(.hadith("bukhari:127", cite: "Saheeh al-Bukhaari 127", text: "“Speak to people with what they know: do you want Allah and His Messenger to be denied?”", arabicText: "حَدِّثُوا النَّاسَ بِمَا يَعْرِفُونَ، أَتُحِبُّونَ أَنْ يُكَذَّبَ اللَّهُ وَرَسُولُهُ")),
            .longOnly(.markdown("**Raised in ruling (marfoo‘ hukman).** Some reports are worded as a Companion’s and still count as the Prophet’s, because a Companion could only have meant him. When a Companion says “we were commanded” or “we were forbidden”, the one who commanded is the Messenger of Allah (peace be upon him). Umm Atiyyah (may Allah be pleased with her) said:")),
            .longOnly(.hadith("bukhari:1278", cite: "Saheeh al-Bukhaari 1278", arabic: 21...27, english: [0...9])),
            .longOnly(.text("The same holds when a Companion says “we used to do this in the time of the Prophet”. He is reporting something done under the Prophet’s eyes, and the Prophet’s silence then counts as his approval. Jaabir ibn Abdullah (may Allah be pleased with him) said it twice, the second time naming the Prophet’s lifetime outright:")),
            .longOnly(.hadith("bukhari:5208", cite: "Saheeh al-Bukhaari 5208", arabic: 28...38, english: [13...34])),
            .longOnly(.text("A Companion’s ruling about obedience works the same way. Abu Hurayrah (may Allah be pleased with him) said that whoever refuses a wedding invitation “has disobeyed Allah and His Messenger” (Saheeh al-Bukhaari 5177), and no Companion would call something disobedience to the Messenger unless he had received it from him.")),
            .longOnly(.hadith("bukhari:5177", cite: "Saheeh al-Bukhaari 5177, Saheeh Muslim 1432", arabic: 21...36, english: [0...35])),
        ]),
        ArticleSection("THE SHAPE OF THE CHAIN", [
            .text("A second family of terms describes the chain itself: whether it is whole, how long it is, and whether its narrators share something along the way."),
            .term("Muttasil", arabic: "مُتَّصِل", meaning: "**Connected**: every narrator heard from the one above him. It says nothing yet about where the chain ends; a connected chain can stop at a Companion as well as reach the Prophet ﷺ."),
            .term("Musnad", arabic: "مُسنَد", meaning: "A report whose chain is **connected and raised** to the Prophet ﷺ, in the definition Ibn Hajar preferred. Also a book arranged Companion by Companion, like the Musnad of Ahmad."),
            .term("Ali", arabic: "عَالٍ", meaning: "A **high** chain: few links between the collector and the Prophet ﷺ, or between him and a great imam. Fewer links leave fewer places for an error to enter."),
            .term("Naazil", arabic: "نَازِل", meaning: "A **descending** chain: more links for the same report. Not weaker in itself, but every extra man is one more to be checked."),
            .term("Musalsal", arabic: "مُسَلسَل", meaning: "A **linked** chain whose narrators all repeat the same words, gesture or circumstance as they hand the report on."),
            .longOnly(.text("The highest chains in al-Bukhaari’s book have only three men between him and the Prophet (peace be upon him). The scholars counted twenty-two of them and called them the thulaathiyyaat, the “threes”. The first in the book is a warning about this very subject: al-Bukhaari heard it from Makki ibn Ibraaheem, who heard it from Yazeed ibn Abi Ubayd, who heard Salamah ibn al-Akwa‘ (may Allah be pleased with him) say:")),
            .longOnly(.hadith("bukhari:109", cite: "Saheeh al-Bukhaari 109", arabic: 22...31, english: [6...24])),
            .longOnly(.text("Muslim has no chain that short. At-Tirmidhi has a single one, the hadith of the man who holds to his religion like one holding a burning coal (Jaami‘ at-Tirmidhi 2260). This is why students travelled: to hear a report from a teacher’s teacher while he still lived removed a link, and with it a possible error. But height is a merit, not a grade. A short chain with a weak man in it loses to a long chain of trustworthy men.")),
            .longOnly(.hadith("tirmidhi:2260", cite: "Jaami‘ at-Tirmidhi 2260; graded saheeh by al-Albaani", arabic: 27...37, english: [0...27])),
            .longOnly(.text("A musalsal chain keeps a gesture along with the words. When the Prophet (peace be upon him) taught Mu‘aadh ibn Jabal (may Allah be pleased with him) a supplication, he began by telling him that he loved him, and Abu Daawood’s chain records that Mu‘aadh passed the advice to his student, and his student to the next:")),
            .longOnly(.hadith("abudawud:1522", cite: "Sunan Abi Daawood 1522; graded saheeh by al-Albaani", arabic: 45...85, english: [0...50])),
            .longOnly(.text("In the books devoted to musalsal reports, each narrator in turn tells the one below him that he loves him before passing the supplication on, and teachers still hand this hadith on in that form.")),
            .longOnly(.markdown("Two signs in the chains are worth knowing. The letter **ح** (for tahweel, “turning”) marks the point where a collector leaves one chain and begins another for the same text. And **“with this chain”** (bi-haadha al-isnaad) means he is repeating a chain already given, so that only the new names need to be written out.")),
        ]),
        ArticleSection("HOW MANY CARRIED IT", [
            .text("The third family counts. The count is taken at the narrowest point of the chain, the generation where the fewest people carried the report. It measures how widely a report travelled, not how true it is."),
            .countLadder,
            .longOnly(.text("Ibn Hajar (may Allah have mercy on him) chose as his example of the ‘azeez the hadith of loving the Prophet (peace be upon him) more than anyone else. Two Companions narrate it, Anas and Abu Hurayrah (may Allah be pleased with them both). From Anas it comes through two students, Abd al-Azeez ibn Suhayb and Qataadah, and al-Bukhaari gives both routes in one entry, joining them with the letter ح:")),
            .longOnly(.hadith("bukhari:15", cite: "Saheeh al-Bukhaari 15", arabic: 8...51, english: [4...22])),
            .longOnly(.markdown("Abu Hurayrah’s version is the entry before it (Saheeh al-Bukhaari 14). Ibn Hajar traced the routes further: from Qataadah to Shu‘bah and Sa‘eed, from Abd al-Azeez to Ismaa‘eel ibn Ulayyah and Abd al-Waarith, and from each of them to many. The name shares its root with the verse about the messengers sent to the town, where Allah says He **strengthened** the two with a third (36:14): an ‘azeez report is one strengthened by a second route.")),
            .longOnly(.hadith("bukhari:14", cite: "Saheeh al-Bukhaari 14", arabic: 30...42, english: [4...28])),
            .longOnly(.ayah("36:14", words: 5...6)),
            .term("Mutawaatir lafzi and ma‘nawi", arabic: "مُتَوَاتِر لَفظِيّ وَمَعنَوِيّ", meaning: "Mass transmission of **the same words**, like “whoever lies about me deliberately”, or of **the same meaning** told in many separate incidents, like his raising his hands in supplication."),
            .term("Ghareeb mutlaq and nisbi", arabic: "غَرِيب مُطلَق وَنِسبِيّ", meaning: "**Absolutely** single, when one Companion or one Successor alone carries it, like the hadith of intentions; or single **relative** to a teacher, when only one student carries it from him though others carry it from elsewhere. At-Tirmidhi’s “ghareeb from this route” is usually the second kind."),
            .markdown("**Mashhoor** in this technical sense is not the same as famous. Many sayings that are famous on people’s tongues have no chain at all, and the scholars wrote whole books to sort them out; fame of that kind proves nothing."),
            .door(.article("HadithScienceFabricationView")),
        ]),
        ArticleSection("THE GRADES", [
            .text("The grades are the verdicts. Each is a judgement on the chain and the text together, and each has a precise meaning that the everyday word does not carry."),
            .term("Saheeh li-dhaatihi", arabic: "صَحِيح لِذَاتِهِ", meaning: "**Sound in itself**: a connected chain of upright, fully precise narrators, with no irregularity and no hidden defect."),
            .term("Hasan li-dhaatihi", arabic: "حَسَن لِذَاتِهِ", meaning: "**Good in itself**: the same conditions, except that a narrator’s precision is a little lighter, though still sound. Accepted and acted upon like the saheeh."),
            .term("Saheeh li-ghayrihi", arabic: "صَحِيح لِغَيرِهِ", meaning: "**Sound through another**: a hasan chain lifted to saheeh by a second route of the same standing or better."),
            .term("Hasan li-ghayrihi", arabic: "حَسَن لِغَيرِهِ", meaning: "**Good through another**: a chain with a mild weakness, such as a narrator of poor memory or a small gap, lifted to hasan because routes of the same kind support it."),
            .term("Da‘eef", arabic: "ضَعِيف", meaning: "**Weak**: a condition of the hasan is missing. Not established as the Prophet’s words, though not thereby declared a lie."),
            .term("Shaadh", arabic: "شَاذّ", meaning: "**Irregular**: a reliable narrator contradicts one more reliable, or several. The preferred version is called **mahfooz**, “preserved”."),
            .term("Munkar", arabic: "مُنكَر", meaning: "**Denounced**: a weak narrator contradicts reliable ones. Its opposite is **ma‘roof**, “known”. Earlier critics such as Ahmad also called a report munkar when a narrator carried it alone and could not bear that alone."),
            .term("Matrook", arabic: "مَترُوك", meaning: "**Abandoned**: in Ibn Hajar’s usage, a report carried by a narrator accused of lying. It is set aside, and no number of such routes lifts it."),
            .term("Mawdoo‘", arabic: "مَوضُوع", meaning: "**Fabricated**: invented and attributed to the Prophet ﷺ. It may not be narrated except to expose it."),
            .longOnly(.text("The pairs are the key to this vocabulary. Shaadh and mahfooz describe a disagreement between reliable men; munkar and ma‘roof describe a weak man disagreeing with reliable ones. In both cases the critic does not reject a version because its content surprises him. He rejects it because it has been weighed against the better attested version and found wanting. And “through another” is never a loophole: Ibn as-Salaah and those after him agree that support can cure a slip of memory or a small gap, but not the report of a man suspected of lying.")),
            .shortOnly(.text("The pairs are the key to this vocabulary. Shaadh and mahfooz describe a disagreement between reliable men; munkar and ma‘roof describe a weak man disagreeing with reliable ones. And “through another” is never a loophole: support can cure a slip of memory or a small gap, but not the report of a man suspected of lying.")),
            .door(.article("HadithScienceGradesView")),
        ]),
        ArticleSection("LOOKING FOR SUPPORT", [
            .text("Before a lone report is judged, the critic searches the books for anyone else who carried it. The search has a name, and so do the two kinds of thing it can find."),
            .term("I‘tibaar", arabic: "اعتِبَار", meaning: "**The search** through the collections and their chains for other routes of a report, to see whether its narrator stands alone."),
            .term("Mutaaba‘ah", arabic: "مُتَابَعَة", meaning: "**Following**: another narrator carries the report from the same Companion. **Full** (taammah) when he shares the narrator’s own teacher; **partial** (qaasirah) when the routes meet higher up."),
            .term("Shaheed", arabic: "شَاهِد", meaning: "**A witness**: the same meaning narrated from a different Companion."),
            .longOnly(.text("Ibn Hajar gives the clearest example in Nuzhat an-Nazar. Ash-Shaafi‘i narrated from Maalik, from Abdullah ibn Dinar, from Ibn Umar (may Allah be pleased with them both), that if the new moon is hidden by cloud the Muslims should complete the count, thirty days. Some thought ash-Shaafi‘i alone had those words from Maalik, because Maalik’s other students reported “estimate it”, as Yahya ibn Yahya did when he read the hadith to Maalik:")),
            .longOnly(.hadith("muslim:1080a", cite: "Saheeh Muslim 1080", arabic: 30...43, english: [0...26])),
            .longOnly(.text("The search then found the same words as ash-Shaafi‘i’s from another of Maalik’s students, Abdullah ibn Maslamah al-Qa‘nabi, in al-Bukhaari’s book. That is a full mutaaba‘ah, because it shares ash-Shaafi‘i’s own teacher:")),
            .longOnly(.hadith("bukhari:1907", cite: "Saheeh al-Bukhaari 1907", arabic: 32...45, english: [4...32])),
            .longOnly(.text("It found partial ones too, where the routes meet above Maalik, such as Ubaydullah ibn Umar from Naafi‘ from Ibn Umar, with “estimate thirty” (Saheeh Muslim 1080). And it found a witness from another Companion altogether, Abu Hurayrah (may Allah be pleased with him):")),
            .longOnly(.hadith("bukhari:1909", cite: "Saheeh al-Bukhaari 1909", arabic: 35...45, english: [6...39])),
            .longOnly(.text("Ash-Shaafi‘i was not alone after all, and a wording that looked like a lone report turned out to be well supported. The same search, run the other way, is how a narrator’s error is caught: when every other route says one thing and his says another, his is the shaadh or the munkar.")),
            .shortOnly(.text("When other routes agree with a narrator, a wording that looked like a lone report turns out to be well supported. When every other route says one thing and his says another, the same search shows his to be the shaadh or the munkar.")),
        ]),
        ArticleSection("DEFECTS IN THE CHAIN AND THE TEXT", [
            .text("The last grading terms name the ways a report goes wrong without anyone lying. Each kind of defect was found the same way, by laying the routes of a report side by side."),
            .term("Mu‘allal", arabic: "مُعَلَّل", meaning: "A report with a **hidden defect** (‘illah) under a chain that looks sound, found only by comparing its routes."),
            .term("Mudtarib", arabic: "مُضطَرِب", meaning: "**Shaken**: told in conflicting ways of equal strength, so that none can be preferred and they cannot be reconciled. If one version is stronger, it is taken and the report is not mudtarib."),
            .term("Maqloob", arabic: "مَقلُوب", meaning: "**Reversed**: a narrator swaps two things, words in the text or names in the chain."),
            .term("Mudraj", arabic: "مُدرَج", meaning: "**Inserted**: a narrator’s own words joined to the hadith so that they seem part of it."),
            .term("Musahhaf", arabic: "مُصَحَّف", meaning: "**Misread**: a word changed through misreading the letters or dots of a written copy."),
            .longOnly(.text("Ibn as-Salaah’s example of the mudtarib is the report that a man praying with nothing set in front of him should draw a line on the ground. Its chain is named in so many conflicting ways that none can be preferred, and so the report is weak.")),
            .longOnly(.markdown("**A reversed text.** The hadith of the seven whom Allah shades on the Day of Resurrection describes a man who gives charity so secretly that his left hand does not know what his right hand spends (Saheeh al-Bukhaari 660).")),
            .longOnly(.hadith("bukhari:660", cite: "Saheeh al-Bukhaari 660", arabic: 72...81, english: [110...130])),
            .longOnly(.text("In one chain in Saheeh Muslim, a narrator turned the hands around:")),
            .longOnly(.hadith("muslim:1031a", cite: "Saheeh Muslim 1031", arabic: 83...93, english: [98...121])),
            .longOnly(.text("Charity is given with the right hand, so the reversed wording is the slip, and Ibn Hajar discusses it in Fath al-Baari as a clear case of a reversed text. Nothing is lost, because the routes that keep the right order show which wording is correct.")),
            .longOnly(.markdown("**An inserted explanation.** In the account of Aa’ishah (may Allah be pleased with her) of how revelation began, the Prophet (peace be upon him) used to go to the cave of Hira and **yatahannath** there. The words that follow, “and that is worship”, explain an unusual verb, and Ibn Hajar notes that they are az-Zuhri’s explanation set into her narration:")),
            .longOnly(.hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 51...63, english: [33...54])),
            .longOnly(.text("The same can happen at the start of a report. Abu Hurayrah (may Allah be pleased with him) once called out to people making wudoo’, “Complete the wudoo’, for Abul-Qaasim said: Woe to the heels from the Fire.” Al-Bukhaari’s chain keeps the two sentences apart (Saheeh al-Bukhaari 165), but some narrators ran them together as though both were the Prophet’s, and al-Khateeb al-Baghdaadi used the case in his book on inserted words.")),
            .longOnly(.hadith("bukhari:165", cite: "Saheeh al-Bukhaari 165", arabic: 14...42, english: [0...36])),
            .longOnly(.text("Sometimes the text gives the insertion away by itself:")),
            .longOnly(.hadith("bukhari:2548", cite: "Saheeh al-Bukhaari 2548", arabic: 33...52, english: [4...44])),
            .longOnly(.text("The Prophet’s mother died when he was a small child, so the duty to serve “my mother” cannot be in his words. Muslim’s wording settles it, because the oath in it is Abu Hurayrah’s own: by Him in Whose hand is the soul of Abu Hurayrah (Saheeh Muslim 1665).")),
            .longOnly(.hadith("muslim:1665a", cite: "Saheeh Muslim 1665", arabic: 32...55, english: [0...42])),
            .longOnly(.markdown("**A misread word.** Zayd ibn Thaabit (may Allah be pleased with him) reported that the Prophet **ihtajara**, made himself a small room of matting in the mosque to pray in at night (Saheeh Muslim 781). Muslim pointed out in his book at-Tamyeez, and Ibn as-Salaah repeats, that Ibn Lahee‘ah, narrating from a written copy he had not heard, misread it as **ihtajama**, “he was cupped”: a single letter, and an entirely different event. The other routes, with their room of matting, show the right reading.")),
            .longOnly(.hadith("muslim:781a", cite: "Saheeh Muslim 781", arabic: 31...50, english: [0...30])),
        ]),
        ArticleSection("THE WORDS OF TRANSMISSION", [
            .longOnly(.text("Every link in a chain is joined by a word, and the word tells how the report was received. The scholars listed eight ways a student could receive a hadith, from the strongest down: hearing the teacher’s own words (sama‘); reading to the teacher while he listens (qiraa’ah, also called ‘ard); a licence to narrate (ijaazah); a book handed over by the teacher (munaawalah); a teacher’s letter (mukaatabah); the teacher’s statement that this is his material (i‘laam); a bequest of his books (wasiyyah); and finding a teacher’s writing (wijaadah).")),
            .shortOnly(.text("Every link in a chain is joined by a word, and the word tells how the report was received. The scholars listed eight ways a student could receive a hadith, the strongest being hearing the teacher’s own words (sama‘) and reading to the teacher while he listens (qiraa’ah), and the weakest finding a teacher’s writing (wijaadah).")),
            .term("Sami‘tu, haddathani, haddathana", arabic: "سَمِعتُ، حَدَّثَنِي، حَدَّثَنَا", meaning: "**I heard; he narrated to me; he narrated to us**: the teacher spoke and the student listened, alone (“me”) or with others (“us”). The clearest words of hearing."),
            .term("Akhbarani, akhbarana", arabic: "أَخبَرَنِي، أَخبَرَنَا", meaning: "**He informed me, he informed us**: in the settled usage, the student read the text to the teacher, who confirmed it."),
            .term("Anba’ana", arabic: "أَنبَأَنَا", meaning: "**He told us**: the same as akhbarana for the early scholars; later used for a licence to narrate."),
            .term("‘An and anna", arabic: "عَن، أَنَّ", meaning: "**From** and **that**: words that name the source without saying how the report was received. Read as hearing from a narrator who met his source and is not known for concealing his teachers."),
            .longOnly(.markdown("Muslim kept these words with great care, even where his own teachers differed. In one chain of the hadith of the new moon, four teachers gave him the same report, and he records exactly who said what: **قَالَ يَحيَى بنُ يَحيَى: أَخبَرَنَا، وَقَالَ الآخَرُونَ: حَدَّثَنَا**, “Yahya ibn Yahya said ‘informed us’, and the others said ‘narrated to us’” (Saheeh Muslim 1080). In Muslim’s usage, Yahya’s word means he had read the text to their teacher, and the others’ that they had heard it from him. In the first chain of the same chapter, quoted above, Yahya says plainly **قَرَأتُ عَلَى مَالِكٍ**, “I read to Maalik”.")),
            .text("‘An is the word that matters most for the next questions. From a trustworthy narrator who is known to have met his teacher, it is read as hearing. From a narrator known for concealing his sources, it is held back until he says “I heard” or “narrated to me”, in that report or another route of it."),
            .door(.article("HadithScienceBreaksView")),
        ]),
        ArticleSection("AT-TIRMIDHI'S HASAN SAHEEH", [
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) noted that at-Tirmidhi was the first known to divide hadith into three, saheeh, hasan and da‘eef; the word hasan was older, but not as a fixed grade. At-Tirmidhi (may Allah have mercy on him) explained what he meant by it at the end of his Jaami‘:")),
            .longOnly(.quote(text: "“Whenever we have said in this book ‘a hasan hadith’, we meant that its chain is good in our view: every hadith that is narrated with no one in its chain accused of lying, that is not shaadh, and that is narrated through more than one route in that sense; that, to us, is a hasan hadith.” (at-Tirmidhi, al-Ilal at the end of the Jaami‘).", arabic: "وَمَا ذَكَرنَا فِي هَذَا الكِتَابِ حَدِيثٌ حَسَنٌ فَإِنَّمَا أَرَدنَا بِهِ حُسنَ إِسنَادِهِ عِندَنَا: كُلُّ حَدِيثٍ يُروَى لَا يَكُونُ فِي إِسنَادِهِ مَن يُتَّهَمُ بِالكَذِبِ، وَلَا يَكُونُ الحَدِيثُ شَاذًّا، وَيُروَى مِن غَيرِ وَجهٍ نَحوَ ذَاكَ، فَهُوَ عِندَنَا حَدِيثٌ حَسَنٌ", dimmed: true)),
            .longOnly(.text("His hasan, then, is a report held up by its routes, close to what was later called hasan through another. Yet he often joins two grades in one phrase, hasan saheeh, and sometimes three, hasan saheeh ghareeb, and he uses it for hadiths at the very top of the scale. This one al-Bukhaari also narrates, through the same Successor (Saheeh al-Bukhaari 1197):")),
            .longOnly(.hadith("tirmidhi:326", cite: "Jaami‘ at-Tirmidhi 326; graded saheeh by al-Albaani", arabic: 29...50, english: [3...31])),
            .longOnly(.hadith("bukhari:1197", cite: "Saheeh al-Bukhaari 1197", arabic: 64...75, english: [83...103])),
            .longOnly(.text("The scholars offered several readings of the phrase. Ibn Hajar’s, in Nuzhat an-Nazar, is the most cited: where the hadith has two chains, it is hasan by one and saheeh by the other; where it has one, the critics hesitated between the two grades, and at-Tirmidhi gives both. Others held that hasan here means good in its plain sense, a fine text, beside the technical saheeh. Whichever is right, the practical rule is clear: in at-Tirmidhi’s own judgement, “hasan saheeh” is never below hasan, and “ghareeb” beside it means only that one route carries it. “Ghareeb” alone, or “hasan ghareeb”, is a prompt to look at the chain itself.")),
            .shortOnly(.text("At-Tirmidhi often joins two grades in one phrase, hasan saheeh, and uses it for hadiths at the very top of the scale. The most cited reading is Ibn Hajar’s, in Nuzhat an-Nazar: where the hadith has two chains, it is hasan by one and saheeh by the other; where it has one, the critics hesitated between the two grades, and at-Tirmidhi gives both. Whichever reading is right, in at-Tirmidhi’s own judgement “hasan saheeh” is never below hasan, and “ghareeb” beside it means only that one route carries it. “Ghareeb” alone, or “hasan ghareeb”, is a prompt to look at the chain itself.")),
            .door(.article("HadithScienceGradesView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Is a mawqoof report a weak hadith?**"),
            .text("No. Mawqoof names the speaker, not the strength. A Companion’s saying can reach us through a flawless chain, and it is then a saheeh mawqoof: a certain report of what that Companion said. It is not quoted as the Prophet’s word, but the scholars have always given the Companions’ words great weight in explaining the Quran and the Sunnah."),
            .markdown("**Does ghareeb mean weak?**"),
            .text("No. Ghareeb counts routes; it does not grade them. The hadith of intentions is ghareeb at its first four levels and is among the most certain hadiths there are. When at-Tirmidhi says “ghareeb” alone, though, he often means that he knows the report through one route only and that route is not strong, so the word is a reason to look closer."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The vocabulary of hadith answers a handful of questions about every report: whose words it ends with, whether its chain is whole and how long it is, how many carried it, what grade the critics gave it, whether anyone else carried it, what defect may hide in it, and how each narrator received it. Every term is a short answer to one of those questions. Once they are learned, a grading note in any book reads as plainly as a sentence."),
        ]),
    ]
}

struct HadithScienceBreaksView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithScienceBreaksView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("When the Chain Breaks")
        .englishArticle().selectableArticleList(article: "HadithScienceBreaksView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a chain can fail at any link, and the hadith scholars named each gap by where it falls. A chain cut at the collector’s end is mu‘allaq; a Successor quoting the Prophet Muhammad (peace and blessings be upon him) with no Companion named is mursal; one man missing lower down is munqati‘, and two in a row mu‘dal. Harder to see are the hidden breaks: tadlees, where a narrator passes over the man he really heard from, and the hidden mursal, a report from a contemporary he never met. This chapter explains each, how the critics found them, and why the chains of the two Saheehs are known to be whole."),
        ]),
        ArticleSection("WHERE THE GAP FALLS", [
            .text("A connected chain is the first condition of a saheeh hadith, so the critics needed to know exactly where a chain could break and what each kind of break did to it. Ibn Hajar (may Allah have mercy on him) set the visible gaps out by position in Nukhbat al-Fikar, and their names follow the chain from the collector down to the Prophet (peace be upon him):"),
            .chain([
                ArticleChainLink("The collector", "Al-Bukhaari, Muslim, Abu Daawood and the rest"),
                ArticleChainLink("The top of the chain", "One or more men dropped at the collector’s end: mu‘allaq"),
                ArticleChainLink("The middle of the chain", "One man dropped: munqati‘. Two or more in a row: mu‘dal"),
                ArticleChainLink("The Successor", "Quotes the Prophet with the Companion dropped: mursal"),
                ArticleChainLink("The Companion", "Heard the Prophet ﷺ"),
                ArticleChainLink("The Prophet ﷺ"),
            ], caption: "Where each visible gap falls, from the collector down"),
            .text("These are the visible breaks, known from history: the narrator was born after his source died, or lived in another land and never travelled to him, or the critics state plainly that he did not hear from him. Then there are hidden breaks, where both men lived at the same time and the chain looks whole. Both kinds were found by checking lives and comparing chains."),
            .longOnly(.text("Checking lives was everyday work. A blind man, Abu Daawood al-A‘ma, came to Basrah claiming to narrate from Companions who had fought at Badr. Qataadah knew where he had really been:")),
            .longOnly(.hadith("muslim:64", cite: "Muqaddimah of Saheeh Muslim 64", arabic: 22...68, english: [0...90])),
            .longOnly(.text("Qataadah’s answer was a matter of dates. If the two greatest Successors of Basrah and Madinah had heard directly from only one veteran of Badr between them, a man who had been begging in the streets before the great plague could not have met eighteen.")),
        ]),
        ArticleSection("AL-BUKHAARI'S SUSPENDED REPORTS", [
            .markdown("A **mu‘allaq** (مُعَلَّق), “suspended”, report has its chain cut at the collector’s end: he quotes a teacher’s teacher, a Companion or the Prophet himself without the men in between, like a lamp hung from the ceiling with nothing beneath it. Al-Bukhaari uses such reports constantly in his chapter headings, to state a ruling, to explain a word, or to point to a hadith he gives in full elsewhere. They are not among his numbered, connected hadiths, and Ibn as-Salaah drew the rule for reading them from the verb al-Bukhaari chose:"),
            .step("1. **Stated firmly.** When he writes “so-and-so said”, “mentioned” or “narrated”, in the active voice, he vouches for the report as far as the man he names. What lies beyond that man still has to be examined."),
            .step("2. **Stated softly.** When he writes “it is mentioned”, “it is narrated” or “it is said”, in the passive, he does not vouch for it. Some of these are saheeh and many are not, and sometimes he says so himself."),
            .longOnly(.text("Both kinds appear in his book. Heading a chapter on bathing alone, he states firmly that Bahz ibn Hakeem narrated, from his father, from his grandfather, that the Prophet said Allah is more deserving of modesty than people. Bahz’s chain was not of al-Bukhaari’s highest standard, so he did not make it one of his connected hadiths, but stating it firmly vouches for it as far as Bahz. Abu Daawood gives it connected:")),
            .longOnly(.hadith("abudawud:4017", cite: "Sunan Abi Daawood 4017; graded hasan by al-Albaani", arabic: 74...86, english: [80...104])),
            .longOnly(.text("And heading a chapter on the imam staying in his place after the prayer, he writes softly that it is mentioned from Abu Hurayrah (may Allah be pleased with him) that the Prophet forbade the imam to pray his voluntary prayer in the same spot, and adds a judgement of his own: “and it is not authentic.”")),
            .longOnly(.text("Ibn Hajar counted 1,341 such reports in the Saheeh, nearly all of them given with full chains elsewhere in the book; only about 160 are not connected anywhere in it. He then searched the other collections for every one of them and published their chains in a book of its own, Taghleeq at-Ta‘leeq, “closing the suspension”.")),
            .longOnly(.markdown("One report that looks suspended became famous through an argument. Al-Bukhaari opens the hadith of the musical instruments with **“and Hishaam ibn Ammaar said”**, not “narrated to us”:")),
            .longOnly(.hadith("bukhari:5590", cite: "Saheeh al-Bukhaari 5590", arabic: 48...56, english: [7...38])),
            .longOnly(.text("Ibn Hazm (may Allah have mercy on him) declared it broken between al-Bukhaari and Hishaam and rejected it. The scholars of hadith did not accept that. Hishaam ibn Ammaar was one of al-Bukhaari’s own teachers, and Ibn as-Salaah explained that when a narrator says “so-and-so said” of a teacher he met, and he is not known for concealing his sources, it has the force of “from”, which is connected. Ibn Hajar gave the chains through which others heard it from Hishaam directly, and Abu Daawood narrates the same hadith, in a shorter wording, through a chain that meets al-Bukhaari’s above Hishaam (Sunan Abi Daawood 4039). Ibn al-Qayyim and, in our time, al-Albaani answered Ibn Hazm at length, and the hadith stands.")),
            .longOnly(.hadith("abudawud:4039", cite: "Sunan Abi Daawood 4039; graded saheeh by al-Albaani", arabic: 51...72, english: [27...53])),
            .shortOnly(.text("Ibn Hajar counted 1,341 such reports in the Saheeh, nearly all of them given with full chains elsewhere in the book; only about 160 are not connected anywhere in it.")),
        ]),
        ArticleSection("MURSAL: THE MISSING COMPANION", [
            .markdown("A **mursal** (مُرسَل), “let loose”, report is one in which a Successor says “the Messenger of Allah said” without naming the Companion he heard it from. If the missing man were certainly a Companion, nothing would be lost, since the Companions are all upright. The difficulty is that he may not be: Successors narrated from other Successors, some of them weak, and a single gap can hide more than one man."),
            .longOnly(.text("The early scholars did not treat it alike. Abu Daawood wrote in his letter to the people of Makkah that the scholars of the past, such as Sufyaan ath-Thawri, Maalik and al-Awzaa‘i, used the mursal as proof until ash-Shaafi‘i spoke against it, and Ahmad followed him. Abu Haneefah and Maalik and their schools accepted the mursal of a trustworthy Successor. Ahmad, in the account Ibn al-Qayyim gives of his principles, would act on a mursal or a lightly weak report when nothing stronger contradicted it, and put it before analogy.")),
            .longOnly(.text("Ash-Shaafi‘i (may Allah have mercy on him) set out in ar-Risaalah when he would accept one. The Successor had to be one of the senior Successors who met many Companions, and his report had to be supported by one of four things:")),
            .longOnly(.checklist(["A **connected chain** with the same meaning, by another route", "Another **mursal** from a Successor who learned from different teachers", "The **saying of a Companion** that agrees with it", "The **verdict of most scholars** in agreement with it"], title: "Ash-Shaafi‘i’s Supports for a Mursal", icon: "checkmark.seal.fill")),
            .longOnly(.text("He set conditions on the man himself as well: when he names his sources, he names no one unknown or disliked, and when he narrates alongside the memorizers, he does not contradict them. The view that settled among the critics was stricter still, and Muslim (may Allah have mercy on him) stated it in the introduction to his Saheeh:")),
            .shortOnly(.text("The early scholars did not treat it alike. Abu Haneefah and Maalik and their schools accepted the mursal of a trustworthy Successor, and ash-Shaafi‘i accepted it only from a senior Successor whose report was supported. The view that settled among the critics was stricter still, and Muslim (may Allah have mercy on him) stated it in the introduction to his Saheeh:")),
            .quote(text: "“The mursal report, in the foundation of our view and the view of those who know the reports, is not a proof.” (Muslim, the Muqaddimah of his Saheeh).", arabic: "وَالمُرسَلُ مِنَ الرِّوَايَاتِ فِي أَصلِ قَولِنَا وَقَولِ أَهلِ العِلمِ بِالأَخبَارِ لَيسَ بِحُجَّةٍ", dimmed: true),
            .longOnly(.text("Ibn as-Salaah records the same as the view of the great majority of the memorizers of hadith. Not all mursal reports are equal, though. Those of Sa‘eed ibn al-Musayyib (d. 94 AH) were searched and found connected elsewhere, and ash-Shaafi‘i spoke well of them. Those of al-Hasan al-Basri and Ataa’ were held among the weakest, because, as Ahmad is reported to have said, they took from everyone.")),
            .longOnly(.markdown("**The mursal of a Companion** is a different case, and the scholars accept it. A young Companion often narrated what happened before he was old enough to witness it, having heard it from the Prophet or from another Companion. Aa’ishah (may Allah be pleased with her) describes the first revelation in the cave of Hira, which came before she was born (Saheeh al-Bukhaari 3). The man she does not name is the Prophet himself or a Companion, and either way the chain loses nothing.")),
            .longOnly(.hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 20...68, english: [0...61])),
            .longOnly(.text("Two books were written on this question alone: al-Maraaseel of Abu Daawood, which gathers mursal reports, and al-Maraaseel of Ibn Abi Haatim, which records which narrators did and did not hear from which.")),
            .shortOnly(.markdown("**The mursal of a Companion** is a different case, and the scholars accept it. The man he does not name is the Prophet himself or another Companion, and either way the chain loses nothing.")),
        ]),
        ArticleSection("MUNQATI‘ AND MU‘DAL", [
            .markdown("When the gap lies lower in the chain, the names change. **Munqati‘** (مُنقَطِع), “broken”, is a chain with one man missing somewhere below the Companion, or at several points that are not next to each other. **Mu‘dal** (مُعضَل), “made difficult”, has two or more missing in a row, and the critics counted it worse than a single break: the more men are missing, the less can be known about them."),
            .longOnly(.text("A common munqati‘ is a son narrating from a father he did not hear from. Abu Ubaydah, the son of Abdullah ibn Mas‘ood (may Allah be pleased with him), narrated a great deal from his father, and at-Tirmidhi repeatedly notes after such reports that Abu Ubaydah did not hear from him; he was a small boy when his father died. The chain names every man, and still has a gap.")),
            .longOnly(.text("Maalik’s Muwatta’ has the classic mu‘dal. Maalik writes that it reached him that Abu Hurayrah (may Allah be pleased with him) said the Messenger of Allah said: the slave is owed his food and clothing, and is not burdened with more work than he can bear. Between Maalik and Abu Hurayrah two men are missing. Outside the Muwatta’ the chain is known: Maalik had it from Muhammad ibn Ajlaan, from his father al-Ajlaan, from Abu Hurayrah, and Muslim has it through another student of al-Ajlaan:")),
            .longOnly(.hadith("muslim:1662", cite: "Saheeh Muslim 1662", arabic: 38...47, english: [0...20])),
            .longOnly(.text("This is why a broken chain is not the end of the inquiry. The break makes that chain weak, and the critic then searches for the same report through a whole one. Ibn Abd al-Barr found connected chains for all of Maalik’s “it reached me” reports in the Muwatta’ except four, and Ibn as-Salaah later wrote a short work connecting those four as well.")),
            .shortOnly(.text("A broken chain is not the end of the inquiry. The break makes that chain weak, and the critic then searches for the same report through a whole one.")),
        ]),
        ArticleSection("TADLEES: CONCEALING THE MAN BETWEEN", [
            .markdown("**Tadlees** (تَدلِيس) comes from dalas, the dimness of dusk, and means obscuring a flaw, as a seller hides a defect in his goods. In a chain it means that a narrator conceals whom he really heard a report from. It is not a lie, because he never says “I heard” when he did not; he uses a word that could mean hearing and lets the listener assume. But it hides a gap, and the scholars described three main kinds:"),
            .step("1. **Tadlees al-isnaad.** A narrator reports from a teacher he did meet something he did not hear from him, with “from” or “said”, dropping the man in between. This is the common kind, and what the word usually means."),
            .step("2. **Tadlees at-taswiyah**, “levelling”. He drops not his own teacher but a weak man further up, between two trustworthy men who met each other, so that the whole chain looks sound. It is the worst kind, because it hides the defect from everyone after him. Al-Waleed ibn Muslim and Baqiyyah ibn al-Waleed were known for it."),
            .step("3. **Tadlees ash-shuyookh**, “of teachers”. He names his source, but by an unfamiliar name, kunyah or place, so that no one recognises a weak man."),
            .longOnly(.text("Abdullah ibn al-Mubaarak (may Allah have mercy on him) described the third kind exactly, speaking of Baqiyyah:")),
            .longOnly(.hadith("muslim:81", cite: "Muqaddimah of Saheeh Muslim 81", arabic: 15...36, english: [26...95])),
            .longOnly(.text("Abd al-Quddoos was a man Ibn al-Mubaarak called a liar to his face (Muqaddimah of Saheeh Muslim 82). Behind a harmless kunyah, Baqiyyah had been passing on a liar’s reports. Hence the advice Muslim records from Abu Ishaaq al-Fazaari: write from Baqiyyah what he narrates from well-known men, and not what he narrates from unknown ones (Muqaddimah of Saheeh Muslim 80).")),
            .longOnly(.text("Shu‘bah was the fiercest enemy of tadlees, and al-Khateeb al-Baghdaadi relates that he called it the brother of lying. A narrator who openly claimed to have heard what he had not was no mudallis but a liar, and Ayyoob as-Sakhtiyaani, who almost never spoke ill of anyone, dismissed a man for exactly that:")),
            .longOnly(.hadith("muslim:#7429", cite: "Muqaddimah of Saheeh Muslim 62", arabic: 14...44, english: [0...51])),
            .text("The rule for a mudallis followed from all this: his report is accepted where he clearly says he heard it, with “narrated to me” or “I heard”, and held back where he says only “from”."),
            .shortOnly(.text("Some of the greatest narrators did it now and then, so the critics did not reject every mudallis. They measured how often each did it and from whom, and Ibn Hajar sorted them into five ranks, from those who did it so rarely that their reports are treated as connected, to those weakened for another reason besides.")),
        ]),
        ArticleSection("THE KNOWN MUDALLISOON", only: .long, [
            .text("Tadlees was not rare, and some of the greatest narrators did it now and then, usually to shorten a chain or to pass over a contemporary. So the critics did not reject every mudallis. They measured how often each did it and from whom, and Ibn Hajar’s Tabaqaat al-Mudalliseen sorts them into five ranks:"),
            .step("1. **Those who did it very rarely**, like Yahya ibn Sa‘eed al-Ansaari. Their reports are treated as connected."),
            .step("2. **Those whose tadlees the imams bore**, because they were great imams who did it seldom beside all they narrated, like Sufyaan ath-Thawri, or did it only from trustworthy men, like Sufyaan ibn Uyaynah. The Saheehs narrate from them freely."),
            .step("3. **Those who did it often**, so that the imams took as proof only what they stated they had heard, like Abu az-Zubayr al-Makki."),
            .step("4. **Those agreed to be unusable unless they state their hearing**, because they concealed weak and unknown men, like Baqiyyah ibn al-Waleed."),
            .step("5. **Those weakened for another reason** besides tadlees, like Abdullah ibn Lahee‘ah, whose reports are weak even when he says “narrated to us”."),
            .text("Other names recur in every discussion of the subject: Qataadah, al-A‘mash, Abu Ishaaq as-Sabee‘i, Hushaym ibn Basheer, Ibn Jurayj, and Muhammad ibn Ishaaq, the author of the Seerah, whom Ibn Hajar sums up in Taqreeb at-Tahdheeb as “truthful, practises tadlees”. Ibn Ishaaq’s reports are taken as hasan where he says “narrated to me”, and examined where he says “from”."),
        ]),
        ArticleSection("AN‘ANAH AND THE HIDDEN BREAK", [
            .markdown("A chain linked by “from” is said to have **‘an‘anah** (عَنعَنَة). From a trustworthy narrator who is not a mudallis, the scholars agree that it is read as hearing, provided the two men could have met. How sure must we be that they met? Here al-Bukhaari and Muslim differed."),
            .longOnly(.text("Al-Bukhaari, following his teacher Ali ibn al-Madeeni, required evidence that the two had met at least once; after that, every “from” between them was read as hearing. Muslim, in the introduction to his Saheeh, argued at length against making this a condition. He held that the report of a trustworthy narrator from a contemporary he could have met is connected unless there is clear evidence that he did not hear from him, and that the Salaf had accepted such chains without asking for proof of a meeting. Most later scholars preferred al-Bukhaari’s stricter condition, and it is one reason his book is ranked first.")),
            .longOnly(.markdown("The question matters because of the **mursal khafi** (مُرسَل خَفِيّ), the hidden mursal: a narrator reports with “from” from a contemporary he never actually met. Unlike tadlees, there was no meeting at all; the two simply lived at the same time. It is found through a critic’s statement that one did not hear from the other, a route that shows a man between them, or the narrator’s own admission. Most of the critics held, for example, that al-Hasan al-Basri did not hear from Abu Hurayrah (may Allah be pleased with him), though the two were contemporaries.")),
            .longOnly(.text("The critics also confirmed hearing where it was doubted. Whether al-Hasan heard from Samurah ibn Jundub (may Allah be pleased with him) was debated, so when al-Bukhaari narrated the hadith of the ‘aqeeqah, he added a short report proving that this hadith, at least, al-Hasan had heard:")),
            .longOnly(.hadith("bukhari:5472", cite: "Saheeh al-Bukhaari 5472", arabic: 87...102, english: [32...57])),
            .shortOnly(.text("Al-Bukhaari required evidence that the two had met at least once; Muslim held that the report of a trustworthy narrator from a contemporary he could have met is connected unless there is clear evidence that he did not hear from him. Most later scholars preferred al-Bukhaari’s stricter condition, and it is one reason his book is ranked first.")),
            .shortOnly(.markdown("The question matters because of the **mursal khafi** (مُرسَل خَفِيّ), the hidden mursal: a narrator reports with “from” from a contemporary he never actually met. It is found through a critic’s statement that one did not hear from the other, a route that shows a man between them, or the narrator’s own admission.")),
        ]),
        ArticleSection("WHY THE SAHEEHAYN'S CHAINS ARE WHOLE", [
            .longOnly(.text("Both Saheehs contain reports from mudallisoon linked only by “from”, and the scholars did not leave this as an open question. Ibn as-Salaah and an-Nawawi state the rule: what the two Saheehs narrate from a mudallis with “from” is known, through other routes, to have been heard. The two collectors chose such reports knowing them to be connected, and later scholars showed it case by case:")),
            .longOnly(.bullet("**The careful student.** Shu‘bah is reported to have said that he had spared his students the tadlees of three men, al-A‘mash, Abu Ishaaq and Qataadah, because he took from them only what they had heard. Their reports through Shu‘bah are treated as heard.")),
            .longOnly(.bullet("**The marked pages.** Al-Layth ibn Sa‘d received two books from Abu az-Zubayr and asked whether he had heard all of it from Jaabir (may Allah be pleased with him). Abu az-Zubayr said he had heard some and been told the rest, and at al-Layth’s request he marked what he had heard. Al-Layth’s reports from Abu az-Zubayr from Jaabir are therefore heard.")),
            .longOnly(.bullet("**The parallel books.** Scholars such as Abu Awaanah, al-Ismaa‘eeli and Abu Nu‘aym compiled mustakhrajaat, narrating the hadiths of the Saheehayn again through their own chains. Again and again these chains show the mudallis saying “narrated to us” where the Saheeh has “from”.")),
            .longOnly(.text("Ibn Hajar and others traced this evidence report by report. Later scholars, al-Albaani among them, examined one by one a small number of Abu az-Zubayr’s reports in Muslim that come through students other than al-Layth, but the principle held, and it is one reason the scholars of the Sunnah receive the chains of the two Saheehs as connected.")),
            .shortOnly(.text("Both Saheehs contain reports from mudallisoon linked only by “from”. Ibn as-Salaah and an-Nawawi state the rule: what the two Saheehs narrate from a mudallis with “from” is known, through other routes, to have been heard. Later scholars showed it case by case, through careful students like Shu‘bah, who took from certain mudallisoon only what they had heard, and through the mustakhrajaat, which narrate the hadiths of the Saheehayn again through their own chains and show the mudallis saying “narrated to us” where the Saheeh has “from”.")),
            .door(.article("HadithPreservationView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A chain can break where anyone can see it, at the top, the bottom or the middle, or where only a specialist can, behind a word like “from”. The scholars named every kind of break and set a rule for each, and then did the slower work: searching for whole chains to replace broken ones, recording who heard from whom, and testing the mudallisoon report by report. A break weakens the chain it is found in; it does not end the search for the hadith."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Mu‘allaq", arabic: "مُعَلَّق", meaning: "**Suspended**: a chain with one or more men dropped at the collector’s end. In al-Bukhaari’s headings, a firm verb vouches for it as far as the man named; a passive verb does not."),
            .term("Mursal", arabic: "مُرسَل", meaning: "A Successor’s report from the Prophet ﷺ with the Companion **left out**. Weak in the view the critics settled on, unless supported; a Companion’s mursal is accepted."),
            .term("Mu‘dal", arabic: "مُعضَل", meaning: "A chain with **two or more men missing in a row**. A single missing man, or gaps that are not adjacent, make it munqati‘."),
            .term("Tadlees", arabic: "تَدلِيس", meaning: "**Concealing** a gap with a word that could mean hearing, such as “from”. Its narrator, the mudallis, is accepted only where he states that he heard."),
            .term("Mustakhraj", arabic: "مُستَخرَج", meaning: "A book that narrates the hadiths of another collection again **through its compiler’s own chains**, often showing hearing where the original has “from”."),
        ]),
    ]
}

struct HadithScienceRijalView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithScienceRijalView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Narrators and Their Critics")
        .englishArticle().selectableArticleList(article: "HadithScienceRijalView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a chain is only as strong as its weakest man, so the hadith scholars built a science of the men themselves. Every narrator had to be upright in his religion and precise in what he carried. The critics tested both, spoke openly about what they found because the religion depended on it, ranked every narrator on a scale from the Companions down to the forgers, and wrote their verdicts into great dictionaries of narrators. They also bound themselves by rules, so that an unexplained remark, a rivalry or a difference of school could not decide a man’s standing."),
        ]),
        ArticleSection("TWO QUALITIES IN EVERY NARRATOR", [
            .text("The Quran gives the starting point: news is weighed by the one who brings it."),
            .ayah("49:6"),
            .markdown("From that command the critics drew two questions about every narrator. Is he **upright**, with ‘adaalah (عَدَالَة): a Muslim of sound religion and decent conduct who does not lie? And is he **precise**, with dabt (ضَبط): does he keep what he heard exactly, in his memory or in a guarded book? The first is a question of character, the second of skill, and a narrator could pass one and fail the other."),
            .longOnly(.text("Uprightness was judged by what could be seen, as Umar ibn al-Khattaab (may Allah be pleased with him) laid down once revelation had ended:")),
            .longOnly(.hadith("bukhari:2641", cite: "Saheeh al-Bukhaari 2641", arabic: 32...84, english: [0...101])),
            .text("Precision was a separate test, and the critics were blunt that piety did not pass it. Abu az-Zinaad, one of the jurists of Madinah, said:"),
            .hadith("muslim:30", cite: "Muqaddimah of Saheeh Muslim 30", arabic: 14...27, english: [0...28]),
            .longOnly(.text("Yahya ibn Sa‘eed al-Qattaan (may Allah have mercy on him) put it more sharply still, and Muslim explained what he meant:")),
            .longOnly(.hadith("muslim:#7407", cite: "Muqaddimah of Saheeh Muslim 40", arabic: 18...65, english: [0...14, 62...79])),
            .longOnly(.text("The pious men he meant were not liars. They were careless, repeating what they heard without checking it, and their mistakes travelled under the cover of their good name. A man could be a saint and still not be a narrator.")),
            .shortOnly(.text("A man could be a saint and still not be a narrator.")),
        ]),
        ArticleSection("SPEAKING ABOUT MEN IS A DUTY", [
            .text("The Prophet Muhammad (peace and blessings be upon him) said that passing on everything one hears is lie enough:"),
            .hadith("muslim:5", cite: "Muqaddimah of Saheeh Muslim 5", arabic: 40...47, english: [36...49]),
            .text("If no one may pass on everything he hears, someone has to say whose reports may be passed on, and the imams of the second century treated that as an obligation. Yahya al-Qattaan asked four of them what he should say when asked about an unreliable narrator:"),
            .hadith("muslim:35", cite: "Muqaddimah of Saheeh Muslim 35", arabic: 12...36, english: [0...38]),
            .longOnly(.text("When a listener once objected that such a verdict was backbiting, Ismaa‘eel ibn Ulayyah answered him:")),
            .longOnly(.hadith("muslim:84", cite: "Muqaddimah of Saheeh Muslim 84", arabic: 12...25, english: [0...44])),
            .longOnly(.text("The scholars found their warrant in the Sunnah. The Prophet (peace be upon him) warned Aa’ishah (may Allah be pleased with her) about a man’s character before receiving him courteously, and al-Bukhaari placed the hadith in a chapter on what is permitted of speaking about people of corruption and suspicion:")),
            .longOnly(.hadith("bukhari:6054", cite: "Saheeh al-Bukhaari 6054", arabic: 34...41, english: [14...28])),
            .longOnly(.text("Not even family was spared. Zayd ibn Abi Unaysah, a trustworthy narrator of al-Jazeerah, told students, “Do not take from my brother” (Muqaddimah of Saheeh Muslim 88), and another contemporary said plainly that the brother, Yahya, was a liar. Ali ibn al-Madeeni, asked about his own father, is reported to have answered that this was religion: his father was weak. And when Yahya al-Qattaan was asked whether he feared that the men he had abandoned would be his opponents before Allah, he is reported to have said he would rather have them as opponents than the Prophet, asking him why he had not defended his hadith from lies.")),
        ]),
        ArticleSection("HOW A NARRATOR WAS TESTED", [
            .text("Uprightness was established by testimony. A narrator became known as trustworthy when critics who knew him declared him so, or when his standing was so widely known that no one needed to ask; Imam Ahmad, asked about Ishaaq ibn Raahawayh, is reported to have replied that the like of Ishaaq is not asked about. Precision was established by evidence, and the main evidence was comparison."),
            .longOnly(.text("A critic gathered what a narrator reported and set it beside what his fellow students reported from the same teachers. Where he agreed with them, at least in meaning, he was precise; where he often stood alone or contradicted them, he was not. Maalik (may Allah have mercy on him) applied this so strictly that his own book became his verdict:")),
            .longOnly(.hadith("muslim:85", cite: "Muqaddimah of Saheeh Muslim 85", arabic: 78...98, english: [106...144])),
            .longOnly(.text("Sometimes a teacher was tested to his face. Al-Khateeb al-Baghdaadi relates that Yahya ibn Ma‘een, travelling with Ahmad ibn Hanbal, visited the Kufan scholar Abu Nu‘aym al-Fadl ibn Dukayn and slipped into a page of his own hadiths some that were not his. Abu Nu‘aym caught every one, guessed who had done it, and kicked Ibn Ma‘een off the bench. Ibn Ma‘een said the kick was dearer to him than his journey: he had learned that Abu Nu‘aym was precise.")),
            .longOnly(.text("Shu‘bah tested reports against their sources. He had asked al-Hakam ibn Utaybah whether the Prophet (peace be upon him) prayed over the martyrs of Uhud, and al-Hakam said he did not. When al-Hasan ibn Umaarah later narrated from al-Hakam that he did, Shu‘bah knew which of them was lying, and he sent word that no one should narrate from him (Muqaddimah of Saheeh Muslim 74).")),
            .longOnly(.markdown("Memory could also change with age. A narrator whose memory failed late in life is **mukhtalit** (مُختَلِط), “confused”, and the critics recorded who had heard from him before and who after. The early students of Ataa’ ibn as-Saa’ib, such as Sufyaan ath-Thawri and Shu‘bah, are accepted from him; those who came to him late are examined. Abdullah ibn Lahee‘ah of Egypt lost his books in a fire, and the verdict of Ibn Hajar (may Allah have mercy on him) in the Taqreeb records the result: truthful, confused after his books burned, and the reports of Ibn al-Mubaarak and Ibn Wahb from him sounder than others’.")),
            .shortOnly(.text("A critic gathered what a narrator reported and set it beside what his fellow students reported from the same teachers. Where he agreed with them, at least in meaning, he was precise; where he often stood alone or contradicted them, he was not.")),
        ]),
        ArticleSection("THE SCALE OF PRAISE AND CRITICISM", [
            .longOnly(.text("Once a critic had judged a man, he had to say so in words others would understand the same way. Ibn Abi Haatim (d. 327 AH) set out the first fixed scale in the introduction to al-Jarh wat-Ta‘deel, four ranks of praise and four of criticism, each with what it means for the narrator’s reports:")),
            .longOnly(.checklist(["**Thiqah**, or **mutqin thabt**: his hadith is used as proof", "**Sadooq**, “his place is truthfulness”, or “no harm in him”: written and examined", "**Shaykh**: written and examined, below the last", "**Saalih al-hadith**: written, to be considered alongside others"], title: "Ibn Abi Haatim’s Ranks of Praise", icon: "hand.thumbsup.fill")),
            .longOnly(.checklist(["**Layyin al-hadith**, soft: written and examined, for consideration", "**Laysa bi-qawi**, not strong: as the last, but lower", "**Da‘eef al-hadith**, weak: lower still, not thrown away but only considered", "**Matrook**, **dhaahib al-hadith** or **kadhdhaab**: thrown away and not written"], title: "Ibn Abi Haatim’s Ranks of Criticism", icon: "hand.thumbsdown.fill")),
            .longOnly(.text("Later critics refined the scale, and the form most readers meet today is Ibn Hajar’s in the introduction to Taqreeb at-Tahdheeb, which gives each narrator of the six books one of twelve ranks:")),
            .longOnly(.step("1. **The Companions**, named as a rank only to honour them.")),
            .longOnly(.step("2. **Praise doubled**: a superlative such as “the most trustworthy of people”, or a repeated or paired word, such as “thiqah thiqah” or “thiqah haafiz”.")),
            .longOnly(.step("3. **A single word of praise**: thiqah, mutqin, thabt or ‘adl.")),
            .longOnly(.step("4. **Just below**: sadooq, or “no harm in him”.")),
            .longOnly(.step("5. **Truthful with a weakness**: “truthful, poor memory”, “truthful, makes mistakes”, “changed at the end”; and here too the truthful accused of an innovation such as Shi‘ism, qadar or irjaa’.")),
            .longOnly(.step("6. **Few reports and nothing proven against him**: maqbool, acceptable where another supports him, and otherwise soft.")),
            .longOnly(.step("7. **More than one narrated from him, and no one declared him trustworthy**: mastoor, or unknown in his condition.")),
            .longOnly(.step("8. **No reliable praise, and some criticism**, even unexplained: da‘eef.")),
            .longOnly(.step("9. **Only one narrated from him, and no one declared him trustworthy**: majhool, unknown.")),
            .longOnly(.step("10. **Not trustworthy at all, and weakened for a defect**: matrook, waahi or saaqit.")),
            .longOnly(.step("11. **Accused of lying.**")),
            .longOnly(.step("12. **Named a liar or a forger.**")),
            .shortOnly(.text("Once a critic had judged a man, he had to say so in words others would understand the same way. The scale most readers meet today is Ibn Hajar’s, in the introduction to Taqreeb at-Tahdheeb, which gives each narrator of the six books one of twelve ranks. After the Companions come praise doubled, such as “thiqah thiqah” (rank two), a single word of praise such as thiqah (three), and sadooq, “truthful” (four); then the truthful with a weakness (five), the acceptable with few reports (six), and the narrator of unknown condition (seven); and below them the weak, the unknown, the abandoned, the accused and the named liar.")),
            .text("A one-line Taqreeb verdict is therefore a compressed judgement. Ranks two and three are the men of the saheeh, four usually the men of the hasan, and from seven down a narrator cannot stand alone. When a modern grader writes that a chain is hasan because one of its men is sadooq, this is the scale he is reading."),
        ]),
        ArticleSection("THE GREAT CRITICS", [
            .longOnly(.text("The science passed from teacher to student like the hadiths themselves, each generation of critics learning from the one before:")),
            .longOnly(.chain([
                ArticleChainLink("Shu‘bah ibn al-Hajjaaj (d. 160 AH) and Maalik ibn Anas (d. 179 AH)", "The first to search out narrators in Iraq, and the strict examiner of Madinah"),
                ArticleChainLink("Yahya ibn Sa‘eed al-Qattaan and Abd ar-Rahman ibn Mahdi (both d. 198 AH)", "Shu‘bah’s students, the two pillars of criticism in Basrah"),
                ArticleChainLink("Yahya ibn Ma‘een (d. 233), Ali ibn al-Madeeni (d. 234) and Ahmad ibn Hanbal (d. 241 AH)", "Their students, who set the verdicts down in words and books"),
                ArticleChainLink("Al-Bukhaari (d. 256), Abu Zur‘ah (d. 264) and Abu Haatim (d. 277 AH)", "The students of those three"),
                ArticleChainLink("Muslim, Abu Daawood, at-Tirmidhi and an-Nasaa’i (d. 303 AH)", "The great compilers, critics in their own right"),
                ArticleChainLink("Ad-Daaraqutni (d. 385 AH)", "The master of hidden defects in the fourth century"),
            ], caption: "The critics, generation by generation")),
            .longOnly(.text("They did not all weigh alike, and the later scholars said so openly. Adh-Dhahabi (may Allah have mercy on him) divided the critics into three: the strict, quick to criticise and slow to praise, such as Yahya ibn Ma‘een and Abu Haatim; the moderate and fair, such as al-Bukhaari, Ahmad, Abu Zur‘ah and Ibn Adi; and the lenient, such as at-Tirmidhi and al-Haakim. The rule that follows is practical. When a strict critic praises a man, his praise is worth holding on to; when he alone criticises a man others praise, his criticism is examined. When a lenient critic declares a man trustworthy or a hadith saheeh, the verdict needs support.")),
            .longOnly(.text("Ibn Hibbaan’s book of trustworthy narrators, ath-Thiqaat, is the best-known case of leniency. He counted a narrator trustworthy until something was known against him, and so included many men known to almost no one, and the critics after him did not follow him in that.")),
            .longOnly(.text("The strictness was not personal. Shu‘bah once wrote to a student about a judge of Waasit: write nothing from him, and tear up my letter (Muqaddimah of Saheeh Muslim 72). The verdict was meant to protect the hadith and to go no further than it needed to.")),
            .shortOnly(.text("The critics did not all weigh alike. Adh-Dhahabi (may Allah have mercy on him) divided them into the strict, such as Yahya ibn Ma‘een and Abu Haatim; the moderate, such as al-Bukhaari and Ahmad; and the lenient, such as at-Tirmidhi and al-Haakim. When a strict critic praises a man, his praise is worth holding on to; when a lenient critic declares a man trustworthy or a hadith saheeh, the verdict needs support.")),
        ]),
        ArticleSection("THE BOOKS OF THE NARRATORS", only: .long, [
            .text("The verdicts were collected into books of several kinds: histories of narrators by generation and city, such as al-Bukhaari’s at-Taareekh al-Kabeer and the Tabaqaat of Ibn Sa‘d; books of the trustworthy, such as those of al-Ijli and Ibn Hibbaan; books of the weak, such as those of al-Uqayli and Ibn Hibbaan’s al-Majrooheen; and the great works that set praise and criticism side by side, beginning with Ibn Abi Haatim’s al-Jarh wat-Ta‘deel, which gathers the verdicts of his father Abu Haatim, of Abu Zur‘ah and of those before them. Two families of books then grew, each built on the one before it:"),
            .chain([
                ArticleChainLink("Al-Kamaal fi Asmaa’ ar-Rijaal", "Abd al-Ghani al-Maqdisi (d. 600 AH): every narrator of the six books"),
                ArticleChainLink("Tahdheeb al-Kamaal", "Al-Mizzi (d. 742 AH): corrected and greatly expanded, with each man’s teachers and students"),
                ArticleChainLink("Tahdheeb at-Tahdheeb", "Ibn Hajar (d. 852 AH): abridged, with verdicts al-Mizzi left out"),
                ArticleChainLink("Taqreeb at-Tahdheeb", "Ibn Hajar: one line for each narrator, with his rank"),
            ], caption: "The narrators of the six books"),
            .chain([
                ArticleChainLink("Al-Kaamil fi Du‘afaa’ ar-Rijaal", "Ibn Adi (d. 365 AH): the criticised narrators, with the reports held against them"),
                ArticleChainLink("Meezaan al-I‘tidaal", "Adh-Dhahabi (d. 748 AH): everyone who was ever criticised, with a judgement on the criticism"),
                ArticleChainLink("Lisaan al-Meezaan", "Ibn Hajar: the Meezaan’s men outside the six books, with additions"),
            ], caption: "The criticised narrators"),
            .text("Ibn Adi’s method shows how the critics argued. Under each man he lists the reports he alone narrated or got wrong, so that the reader sees the evidence for the verdict and not only the verdict. A student today usually starts with a narrator’s single line in the Taqreeb, turns to Tahdheeb at-Tahdheeb or Tahdheeb al-Kamaal to see who said what about him, and to the Meezaan if he was ever criticised."),
        ]),
        ArticleSection("THE RULES THEY FOLLOWED", [
            .longOnly(.markdown("**Criticism must be explained.** Ibn as-Salaah set down the rule the critics practised: praise is accepted without its reasons, because they are many and hard to list, but criticism only with its reason stated, because people differ about what counts as a fault. Al-Khateeb al-Baghdaadi relates that Shu‘bah was asked why he had left a certain man’s hadith and answered that he had seen him galloping on a horse, a reason no one else would accept. Where explained criticism meets general praise, the explained criticism wins, since the critic saw something the praiser missed; where unexplained criticism meets established praise, the praise stands.")),
            .shortOnly(.markdown("**Criticism must be explained.** Praise is accepted without its reasons, but criticism only with its reason stated, because people differ about what counts as a fault. Where explained criticism meets general praise, the explained criticism wins; where unexplained criticism meets established praise, the praise stands.")),
            .markdown("**Rivals are not believed against each other.** Contemporaries in the same city and the same field sometimes spoke harshly of one another, and adh-Dhahabi gave the rule for such words:"),
            .quote(text: "“The words of contemporaries about one another are not to be weighed, especially when it is clear that they come from enmity, from a difference of school, or from envy.” (adh-Dhahabi, Meezaan al-I‘tidaal).", arabic: "كَلَامُ الأَقرَانِ بَعضِهِم فِي بَعضٍ لَا يُعبَأُ بِهِ، لَا سِيَّمَا إِذَا لَاحَ لَكَ أَنَّهُ لِعَدَاوَةٍ أَو لِمَذهَبٍ أَو لِحَسَدٍ", dimmed: true),
            .longOnly(.text("Maalik’s harsh words about Muhammad ibn Ishaaq are the best-known case. The critics recorded them, weighed them against everything else known of Ibn Ishaaq, and settled where Ibn Hajar’s Taqreeb places him: the imam of the Prophet’s campaigns, truthful, practising tadlees.")),
            .longOnly(.markdown("**Innovators are judged by their innovation and their honesty.** A narrator whose innovation amounts to disbelief is rejected outright. For lesser innovation, the view of most critics was that a truthful narrator is accepted if he does not call others to it, and Ibn Hajar added that the report must not support his innovation. Adh-Dhahabi, writing on the narrator Abaan ibn Taghlib, distinguished the lighter Shi‘ism of many early Kufans, who preferred Ali (may Allah be pleased with him) without reviling anyone and whose reports, if dropped, would take much of the Sunnah with them, from the full rafd of those who revile Abu Bakr and Umar (may Allah be pleased with them), whose reports are not taken. Belief and honesty went together, as Ayyoob as-Sakhtiyaani told a student who kept company with the Mu‘tazili Amr ibn Ubayd:")),
            .longOnly(.hadith("muslim:#7437", cite: "Muqaddimah of Saheeh Muslim 70", arabic: 22...31, english: [0...17])),
            .longOnly(.text("The early critics abandoned Jaabir al-Ju‘fi once he made public his belief in the raj‘ah, the return of Ali before the Hour, though they had narrated from him before (Muqaddimah of Saheeh Muslim 54). Ash-Shaafi‘i is reported to have said that he had seen no people more given to false testimony than the Raafidah, and the critics’ caution toward their reports follows from that.")),
            .shortOnly(.markdown("**Innovators are judged by their innovation and their honesty.** A narrator whose innovation amounts to disbelief is rejected outright. For lesser innovation, most critics accepted a truthful narrator who did not call others to it, provided the report did not support his innovation.")),
            .door(.article("BidahView")),
        ]),
        ArticleSection("THE COMPANIONS STAND ABOVE THE SCALE", [
            .text("One generation is not weighed at all. Ibn Hajar’s first rank is simply “the Companions”. Allah praised them and declared His pleasure with them:"),
            .ayah("9:100"),
            .longOnly(.text("And the Prophet (peace be upon him) called his own generation the best of people:")),
            .longOnly(.hadith("bukhari:2652", cite: "Saheeh al-Bukhaari 2652", arabic: 29...37, english: [4...23])),
            .longOnly(.text("Ibn as-Salaah and al-Khateeb al-Baghdaadi report the agreement of the scholars that every Companion is upright, including those caught up in the strife between them, whose disputes the Ahl as-Sunnah leave to Allah while holding that each acted on his own judgement. So the critic’s work begins below the Companions. When a Successor says “a man from the Companions of the Prophet told me”, the missing name does no harm, because whoever he was, he was upright. That is why the books of criticism are filled with Successors and later men, and why no grading note ever reads “weak because of the Companion”.")),
            .shortOnly(.text("The scholars agree that every Companion is upright, including those caught up in the strife between them, whose disputes the Ahl as-Sunnah leave to Allah. So the critic’s work begins below the Companions, and no grading note ever reads “weak because of the Companion”.")),
            .door(.article("SahabahView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The science of narrators asked two questions of every man in every chain: was he upright, and was he precise? The critics answered from his conduct, from comparing everything he narrated, and from tests of his memory and his books, and they spoke openly because a word about a narrator protects the words of the Prophet (peace be upon him). They fixed a scale so that a verdict meant the same thing in every city, wrote their verdicts into books still in print, and held themselves to rules about explanation, rivalry and innovation. Above the whole scale stand the Companions, whom Allah Himself declared upright."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Thiqah", arabic: "ثِقَة", meaning: "**Trustworthy**: upright and fully precise. The narrator of the saheeh hadith, and the third rank of Ibn Hajar’s scale."),
            .term("Sadooq", arabic: "صَدُوق", meaning: "**Truthful**: upright, with precision a little short of the thiqah. The usual narrator of the hasan hadith."),
            .term("Tazkiyah", arabic: "تَزكِيَة", meaning: "**Declaring a narrator upright**: the testimony of a critic who knew him, or the wide fame that makes testimony unnecessary."),
            .term("Jarh Mufassar", arabic: "جَرح مُفَسَّر", meaning: "**Explained criticism**: a verdict against a narrator that states its reason. It outweighs general praise; unexplained criticism does not outweigh established praise."),
            .term("Mukhtalit", arabic: "مُختَلِط", meaning: "A narrator whose memory **became confused** late in life. What students heard from him before the change is accepted; what they heard after is examined."),
        ]),
    ]
}

struct HadithScienceAhadView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithScienceAhadView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Mutawaatir, Ahad and Belief")
        .englishArticle().selectableArticleList(article: "HadithScienceAhadView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a mutawaatir report is carried at every stage by so many that a shared lie is impossible; every other report is aahaad, however sound. The Companions and the imams after them acted on a sound aahaad report in belief and in law alike: the Prophet Muhammad (peace and blessings be upon him) sent single men to teach tawheed, and whole congregations turned their qiblah on one man’s word. Later theologians of the kalaam schools held that such reports give only probability and kept them out of creed. The scholars of the Sunnah answered them from the Quran, the Sunnah and the practice of the Companions, and held that a sound report the Ummah has received, above all in the two Saheehs, yields knowledge."),
        ]),
        ArticleSection("TWO KINDS OF REPORT", [
            .text("Every report the Muslims hold from the Prophet (peace be upon him) reached them in one of two ways. Either it was carried by such numbers that its truth is beyond doubt for anyone who hears it, or it was carried by fewer, and its truth rests on the men who carried it."),
            .longOnly(.markdown("Ibn Hajar (may Allah have mercy on him) listed the conditions of the first kind, the **mutawaatir** (مُتَوَاتِر), in Nuzhat an-Nazar: a great number, so many that custom rules out their agreeing on a lie or falling into the same error by chance; that number at every level of the chain, first to last; a report resting on what they perceived, what they heard or saw, not on reasoning; and certainty produced in the one who hears it. No fixed number makes a report mutawaatir. Some named four, five, ten, forty or seventy, and Ibn Hajar rejected them all: the test is the certainty, not the count.")),
            .shortOnly(.markdown("The first kind is the **mutawaatir** (مُتَوَاتِر): a report carried at every level of its chain by so many that custom rules out their agreeing on a lie or falling into the same error by chance, resting on what they heard or saw. No fixed number makes a report mutawaatir; the test is the certainty, not the count.")),
            .markdown("Everything else is **aahaad** (آحَاد), “of ones”, even a report carried by several at every level. Aahaad is not a grade. A report is aahaad and saheeh, or ahad and da‘eef, and most of the Sunnah, including most of the two Saheehs, is aahaad and saheeh. The scrutiny of chains and narrators applies to the aahaad report; the mutawaatir needs none, because its certainty does not rest on any single narrator."),
            .longOnly(.text("A report can be mutawaatir in two ways. It is mutawaatir in wording when many carry the same words, as with “whoever lies about me deliberately, let him take his seat in the Fire”. It is mutawaatir in meaning when many separate reports, each aahaad in its own words, share a meaning that none of them could establish alone, as with the Prophet raising his hands in supplication, which as-Suyooti found in about a hundred reports.")),
            .door(.article("HadithScienceTermsView")),
        ]),
        ArticleSection("WHAT CAME BY TAWAATUR", [
            .longOnly(.text("Ibn as-Salaah thought examples of the mutawaatir were hard to find. Ibn Hajar disagreed: the famous collections of east and west contain many reports whose routes are so numerous and independent that their agreement on a lie is impossible. Later scholars gathered hundreds, as-Suyooti in al-Azhar al-Mutanaathirah and Muhammad ibn Ja‘far al-Kattaani in Nazm al-Mutanaathir, and several matters of creed are among them.")),
            .longOnly(.markdown("**Seeing Allah in the Hereafter.** Some thirty Companions narrate that the believers will see their Lord, as Ibn al-Qayyim lists them in Haadi al-Arwaah. Jareer ibn Abdullah (may Allah be pleased with him) reported it from a night of the full moon:")),
            .longOnly(.hadith("bukhari:554", cite: "Saheeh al-Bukhaari 554", arabic: 32...42, english: [15...34])),
            .longOnly(.markdown("**The Basin, the intercession and the descent of Eesa.** The Prophet’s Basin on the Day of Resurrection, his intercession for the sinners of his Ummah, and the return of Eesa son of Maryam (peace be upon him) before the Hour are each narrated by many Companions. Abu Hurayrah (may Allah be pleased with him) narrated the last:")),
            .longOnly(.hadith("bukhari:3448", cite: "Saheeh al-Bukhaari 3448", arabic: 37...50, english: [12...52])),
            .longOnly(.text("Anwar Shah al-Kashmeeri wrote a whole book, at-Tasreeh bima Tawaatara fi Nuzool al-Maseeh, to show that the descent of Eesa is mass-transmitted. Notice how such certainty is built. Each of these doctrines rests on many reports that are aahaad one by one; no single route is mutawaatir, and the certainty comes from their sum. A method that refused every aahaad report in belief would have no way to reach these beliefs at all.")),
            .longOnly(.markdown("**Wiping over leather socks.** So many Companions narrated that the Prophet wiped over his khuffs in wudoo’ that the scholars of creed wrote it into their creeds, as at-Tahaawi did, as a mark of the Sunnah against those who denied it.")),
            .shortOnly(.text("Many reports did come by tawaatur, and several matters of creed are among them: the believers seeing their Lord in the Hereafter, the Prophet’s Basin, his intercession, and the descent of Eesa (peace be upon him) before the Hour. Each rests on many reports that are aahaad one by one; no single route is mutawaatir, and the certainty comes from their sum. A method that refused every aahaad report in belief would have no way to reach these beliefs at all.")),
        ]),
        ArticleSection("THE QURAAN'S RULE FOR A REPORT", [
            .text("The Quran tells the believers to stop and verify when the bearer of news is a sinner:"),
            .ayah("49:6"),
            .longOnly(.text("The verse singles out the disobedient one. If every single report had to be held back, naming the sinner would serve no purpose; the command implies that the report of an upright man is accepted. Another verse makes a small party, which can be one man, the means by which the religion reaches a whole people:")),
            .longOnly(.ayah("9:122", words: 6...22)),
            .longOnly(.markdown("Al-Bukhaari placed both verses at the head of the **Book of Single Reports** (Akhbaar al-Aahaad) in his Saheeh, in a chapter on accepting the report of one truthful man in the call to prayer, the prayer, fasting, inheritance and rulings. He noted that the word **taa’ifah**, a party, can mean a single man, since Allah commands making peace when two taa’ifahs of the believers fight (49:9), and two men who fight fall under the verse. He added, in the same heading, that the Prophet sent his governors one after another, and that if one of them slipped, he was brought back to the Sunnah.")),
            .longOnly(.ayah("49:9", words: 0...6)),
            .longOnly(.text("The command to ask the people of knowledge if you do not know (16:43) assumes the same thing. A man who does not know asks one who does and acts on his answer; he does not wait for a crowd to repeat it.")),
            .longOnly(.ayah("16:43", words: 8...14)),
            .shortOnly(.text("The verse singles out the disobedient one. If every single report had to be held back, naming the sinner would serve no purpose; the command implies that the report of an upright man is accepted.")),
        ]),
        ArticleSection("ONE MAN, ONE MESSAGE", [
            .text("The Prophet (peace be upon him) carried Islam to the world largely through single men. When he sent Mu‘aadh ibn Jabal (may Allah be pleased with him) to Yemen as teacher and governor, he told him what to teach first:"),
            .hadith("bukhari:1395", cite: "Saheeh al-Bukhaari 1395", arabic: 46...90, english: [9...98]),
            .longOnly(.text("The first thing Mu‘aadh carried, alone, was the testimony of tawheed, which is belief before it is anything else. If one trustworthy man could not establish a matter of creed, the people of Yemen would have owed him no belief, and he would have been sent in vain. The same is true of the letters the Prophet sent to kings, each carried by one man (Saheeh al-Bukhaari 7, 7264), and of the young men he sent home to teach their people.")),
            .longOnly(.hadith("bukhari:7", cite: "Saheeh al-Bukhaari 7", arabic: 464...482, english: [884...910])),
            .longOnly(.hadith("bukhari:7264", cite: "Saheeh al-Bukhaari 7264", arabic: 28...52, english: [0...38])),
            .longOnly(.text("Maalik ibn al-Huwayrith (may Allah be pleased with him) and his companions had stayed with him for twenty nights when he told them:")),
            .longOnly(.hadith("bukhari:7246", cite: "Saheeh al-Bukhaari 7246", arabic: 53...79, english: [56...128])),
            .longOnly(.text("A handful of young men, nowhere near a mass transmission, were to teach their whole people how to believe and how to pray.")),
            .shortOnly(.text("The first thing Mu‘aadh carried, alone, was the testimony of tawheed, which is belief before it is anything else. If one trustworthy man could not establish a matter of creed, the people of Yemen would have owed him no belief, and he would have been sent in vain.")),
        ]),
        ArticleSection("THE COMPANIONS ACTED ON IT", [
            .text("The Companions understood this without being told. When the qiblah changed, the news reached the people of Qubaa’ through one man, in the middle of the dawn prayer:"),
            .hadith("bukhari:403", cite: "Saheeh al-Bukhaari 403", arabic: 21...55, english: [0...58]),
            .longOnly(.text("They did not finish the prayer facing Jerusalem and wait for confirmation. On one man’s word they turned, in the very act of worship, from a direction they knew had been commanded to a new one. When wine was forbidden, the same happened in the house of Abu Talhah (may Allah be pleased with him):")),
            .longOnly(.hadith("bukhari:7253", cite: "Saheeh al-Bukhaari 7253", arabic: 41...67, english: [22...70])),
            .longOnly(.text("Umar ibn al-Khattaab (may Allah be pleased with him), the most cautious of them, acted on single reports when they reached him. He did not take the jizyah from the Magians until one Companion bore witness to the Prophet’s practice:")),
            .longOnly(.hadith("bukhari:3156", cite: "Saheeh al-Bukhaari 3156", arabic: 59...82, english: [100...127])),
            .longOnly(.text("And when he was leading an army toward Syria and plague broke out there, he had consulted the Emigrants, the Ansaar and the elders of Quraysh and decided to turn back when Abd ar-Rahman ibn Awf (may Allah be pleased with him) arrived with a hadith that settled it:")),
            .longOnly(.hadith("bukhari:5729", cite: "Saheeh al-Bukhaari 5729", arabic: 234...271, english: [346...401])),
            .longOnly(.text("Umar’s request to Abu Moosa al-Ash‘ari (may Allah be pleased with him) for a second witness, in the matter of asking permission three times, is sometimes cited against all this. But Umar told Abu Moosa that he did not blame him, only that narrating from the Messenger of Allah was a serious matter (Sunan Abi Daawood 5183). A man who settled the jizyah and the plague on one Companion’s word did not hold that one Companion’s word was too little.")),
            .longOnly(.hadith("abudawud:5183", cite: "Sunan Abi Daawood 5183; its chain graded saheeh by al-Albaani", arabic: 26...42, english: [0...28])),
            .shortOnly(.text("They did not finish the prayer facing Jerusalem and wait for confirmation. On one man’s word they turned, in the very act of worship, from a direction they knew had been commanded to a new one.")),
        ]),
        ArticleSection("ASH-SHAAFI'I'S ARGUMENT", [
            .longOnly(.text("Ash-Shaafi‘i (may Allah have mercy on him) wrote the first systematic defence of the single report, in the chapter on khabar al-waahid in ar-Risaalah. He gathered the evidence above and more: the people of Qubaa’ turning in their prayer, Abu Talhah breaking his jars, the Prophet’s governors and envoys sent one at a time, Umar changing his ruling when a single report reached him. He argued from the Prophet’s prayer for the one who hears a hadith and conveys it as he heard it (Jaami‘ at-Tirmidhi 2657): the Prophet would not urge one listener to convey his words unless what that listener conveyed was a proof for those who heard it from him.")),
            .longOnly(.hadith("tirmidhi:2657", cite: "Jaami‘ at-Tirmidhi 2657; graded saheeh by al-Albaani", arabic: 36...49, english: [21...54])),
            .longOnly(.text("He pointed out that the Prophet sent one man at a time where he could easily have sent many, because the proof was established by one trustworthy messenger. And he concluded that he knew of no jurist of the Muslims, from the Companions to his own day, who had not accepted the single report, so that if anyone could claim the agreement of the specialists on any question, he could claim it on this one.")),
            .longOnly(.text("Ash-Shaafi‘i drew no line between belief and law: a sound report was a proof, whatever it was about. Neither did his contemporaries. The Salaf narrated the hadiths of Allah’s attributes, of His descent to the lowest heaven, His laughter and His Hand, through the same kind of chains as the hadiths of prayer and trade, and believed them as they narrated them, without asking how and without likening Him to His creation.")),
            .shortOnly(.text("Ash-Shaafi‘i (may Allah have mercy on him) wrote the first systematic defence of the single report, in ar-Risaalah. He gathered this evidence and more, and concluded that he knew of no jurist of the Muslims, from the Companions to his own day, who had not accepted the single report. He drew no line between belief and law: a sound report was a proof, whatever it was about. Neither did his contemporaries. The Salaf narrated the hadiths of Allah’s attributes through the same kind of chains as the hadiths of prayer and trade, and believed them as they narrated them, without asking how and without likening Him to His creation.")),
            .door(.article("AsmaSifatView")),
        ]),
        ArticleSection("THE KALAAM POSITION", [
            .text("The opposing view should be stated fairly, because those who held it were serious men. The Mu‘tazilah, and after them many theologians of the later kalaam schools, argued like this. Belief about Allah must rest on certainty. A single narrator, however honest, can make a mistake, so his report gives only probability, zann. And the Quran condemns following zann:"),
            .ayah("53:28"),
            .text("So, they said, aahaad reports may be used in law, where acting on the more probable is unavoidable, but not in creed, where only the plain texts of the Quran, mutawaatir reports and reason may decide. Some went further and held that when an aahaad report about Allah’s attributes seemed to conflict with what they took reason to require, it was to be rejected or explained away."),
            .text("The position sounds cautious, but its effect was not. In practice it was used to set aside, one after another, the sound hadiths on Allah’s attributes, on His descent and His being above His creation, on the punishment of the grave, the scales, the bridge and the intercession, wherever they did not fit a theology built first."),
            .door(.article("AqeedahMadhabView")),
        ]),
        ArticleSection("THE ANSWER OF THE SUNNAH", [
            .longOnly(.text("The scholars of the Sunnah answered on several grounds. Ibn al-Qayyim (may Allah have mercy on him) answered the claim at length in as-Sawaa‘iq al-Mursalah, his book against those who deny the attributes, as one of the principles by which they emptied the texts of their meaning. In the twentieth century al-Albaani summed up the case in two short treatises, al-Hadith Hujjah bi-Nafsihi and Wujoob al-Akhdh bi-Hadith al-Ahad fil-Aqeedah.")),
            .shortOnly(.text("The scholars of the Sunnah answered on several grounds:")),
            .step("1. **The Salaf drew no such line.** No Companion said “I accept this in law but not in belief”. The envoys taught tawheed first, and the Companions, the Successors and the imams narrated and believed the hadiths of the attributes through single chains. The division came later."),
            .longOnly(.step("2. **The zann the Quran condemns is something else.** The verse is about the idolaters, who named the angels as females without any knowledge (53:27-28): the zann of guesswork. The same Quran commands acting on the word of upright witnesses, two in a contract (2:282) and one bringing news (49:6), and no one calls that following guesswork.")),
            .longOnly(.ayah("2:282", words: 51...54)),
            .longOnly(.step("3. **The division defeats itself.** Every ruling of law is also a belief: that Allah made this prayer obligatory or that sale unlawful. Allah forbids saying about Him what one does not know (7:33). If an aahaad report were mere guesswork, it could not be used to say what Allah has made obligatory either; if it is enough for that, it is enough for belief.")),
            .longOnly(.ayah("7:33")),
            .shortOnly(.step("2. **The zann the Quran condemns is something else.** The verse is about the idolaters, who named the angels as females without any knowledge: the zann of guesswork. The same Quran commands acting on the word of upright witnesses, and no one calls that following guesswork.")),
            .shortOnly(.step("3. **The division defeats itself.** Every ruling of law is also a belief: that Allah made this prayer obligatory or that sale unlawful. If an aahaad report were mere guesswork, it could not be used to say what Allah has made obligatory either; if it is enough for that, it is enough for belief.")),
            .step("4. **Its result condemns it.** Applied consistently, the rule would strip from the creed much that every Muslim of the first centuries believed, and the creeds of the Salaf list exactly these matters, from the questioning in the grave to the intercession, as part of belief."),
            .text("Even many who held that ahad gives only probability agreed that it must be acted on. The Ahl as-Sunnah go further: a sound report from the Prophet (peace be upon him) is believed and acted on alike, because it is his word, and he does not speak from desire (53:3-4)."),
            .ayah("53:3-4"),
        ]),
        ArticleSection("WHEN A SINGLE REPORT YIELDS CERTAINTY", [
            .longOnly(.text("A further question divided even the scholars of hadith: does a sound aahaad report give certain knowledge, or a strong probability that must be acted on? Ibn as-Salaah held that what al-Bukhaari and Muslim narrated is known with certainty to be authentic, apart from the few hadiths the critics questioned, because the Ummah received the two books with acceptance, and the Ummah as a whole is protected from agreeing on an error. An-Nawawi disagreed, saying most scholars held that such reports give probability unless they are mutawaatir.")),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) sided with Ibn as-Salaah. A report the Ummah has received with acceptance, affirming it or acting on it, gives knowledge, he said, in the view of most scholars of the four schools, of the scholars of hadith, and of the Salaf; the dissent came mostly from a group of the kalaam theologians. Ibn Hajar named in Nuzhat an-Nazar the signs, qaraa’in, by which a single report comes to give knowledge:")),
            .longOnly(.checklist(["**Being in the two Saheehs**, given the standing of their authors and the Ummah’s acceptance of their books", "**Many routes**, each free of weakness, though short of mass transmission", "**A chain of imams**, such as Ahmad from ash-Shaafi‘i from Maalik, each a master who would have caught another’s error"], title: "When a Single Report Gives Knowledge", icon: "checkmark.seal.fill")),
            .shortOnly(.text("A further question divided even the scholars of hadith: does a sound aahaad report give certain knowledge, or a strong probability that must be acted on? Ibn as-Salaah held that what al-Bukhaari and Muslim narrated is known with certainty to be authentic, because the Ummah received the two books with acceptance; an-Nawawi held that such reports give probability. Ibn Taymiyyah (may Allah have mercy on him) sided with Ibn as-Salaah: a report the Ummah has received with acceptance gives knowledge, he said, in the view of most scholars of the four schools, of the scholars of hadith, and of the Salaf.")),
            .text("For the reader, the result is simple. A hadith of the two Saheehs, or any hadith the scholars have graded sound, is not a probability to be set aside when it is inconvenient. It is the Prophet’s word, to be believed and acted on. Whether a given report is sound is a question for the science of chains and narrators; once it has been answered, the question of whether to accept it is closed."),
            .door(.article("HadithRejectorsView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Did Umar not reject the report of Faatimah bint Qays?**"),
            .text("Umar (may Allah be pleased with him) did not accept the report of Faatimah bint Qays (may Allah be pleased with her) that a woman divorced irrevocably has no right to lodging and maintenance, and he gave his reason, which al-Aswad ibn Yazeed repeated when the report was narrated in front of him:"),
            .hadith("muslim:1480n", cite: "Saheeh Muslim 1480", arabic: 63...99, english: [74...139]),
            .text("His concern was whether she had remembered, and what looked to him like a conflict with the Quran; it was not that she was one person. That is a question of precision, the same question the critics asked of every narrator. Many scholars, Ahmad among them, later acted on her report, judging that it did not conflict with the verse."),
            .markdown("**Is it not safer to believe only what is certain?**"),
            .text("Safety lies in the way the Prophet (peace be upon him) and his Companions followed. They accepted the word of a single upright witness in belief and in practice, and a Muslim who does the same is doing what they did. Setting aside a sound hadith about Allah because it came through one chain is not caution; it is refusing the Prophet’s word on a condition he never set."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Mutawaatir and ahad name how many carried a report, not how true it is. The mutawaatir is certain in itself; the ahad is as strong as its chain, and when its chain is sound it binds. The Quran told the believers to verify the sinner’s news and so to accept the upright man’s, the Prophet sent single envoys with the testimony of tawheed, and the Companions turned their qiblah, broke their wine jars and settled questions of state on one man’s word. The later kalaam rule that keeps such reports out of belief has no root in that practice, and the scholars of the Sunnah, from ash-Shaafi‘i to Ibn al-Qayyim and al-Albaani, answered it."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Khabar al-Waahid", arabic: "خَبَر الوَاحِد", meaning: "**The single report**: any report short of mass transmission, the same as ahad. A proof in belief and in law when its chain is sound."),
            .term("Zann", arabic: "ظَنّ", meaning: "**Supposition**: in the Quran’s blame, the guesswork of those who speak without knowledge; in the theologians’ usage, any knowledge short of certainty."),
            .term("Talaqqi bil-Qabool", arabic: "تَلَقِّي بِالقَبُول", meaning: "**Reception with acceptance**: the Ummah receiving a report or a book, affirming it or acting on it. It is why the scholars hold that the two Saheehs yield knowledge."),
            .term("Qaraa’in", arabic: "قَرَائِن", meaning: "**Indications**: the circumstances, such as many sound routes or a chain of great imams, by which a single report comes to give knowledge."),
        ]),
    ]
}

// MARK: - hadith-2

struct HadithScienceFabricationView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithScienceFabricationView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Fabrication, and How It Was Caught")
        .englishArticle().selectableArticleList(article: "HadithScienceFabricationView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a fabricated hadith (mawdoo‘) is a saying falsely put in the mouth of the Prophet Muhammad (peace and blessings be upon him). He warned against it in the gravest terms and foretold that liars would come, and when they came, after the civil strife of the first century, they were sectarians, heretics, storytellers, misguided worshippers and flatterers of the powerful. The critics caught them by dates, by chains, and by texts that the Quran, the known Sunnah and the plain evidence of the senses contradict, and they listed the forgeries in books so that no Muslim need be deceived. Many sayings that circulate today are among them, and the duty on every Muslim is to check before he passes a saying on."),
        ]),
        ArticleSection("A WARNING CARRIED BY MULTITUDES", [
            .text("Few sayings of the Prophet (peace be upon him) were carried by as many Companions as his warning against lying about him. In his Book of Knowledge al-Bukhaari gives it a chapter of its own and narrates it from Ali, az-Zubayr, Anas, Salamah ibn al-Akwa‘ and Abu Hurayrah (may Allah be pleased with them), one after another (Saheeh al-Bukhaari 106 to 110)."),
            .hadith("bukhari:106", cite: "Saheeh al-Bukhaari 106", arabic: 27...35, english: [4...25]),
            .longOnly(.text("Abu Hurayrah’s version sets it beside two other things a liar might claim, a name and a dream:")),
            .longOnly(.hadith("bukhari:110", cite: "Saheeh al-Bukhaari 110", arabic: 24...48, english: [4...58])),
            .longOnly(.markdown("The scholars count it **mutawaatir (مُتَوَاتِر)**: carried at every level by so many that a shared lie is impossible. Al-Mugheerah ibn Shu‘bah (may Allah be pleased with him), governor of Koofah, explained in the mosque there why this lie is graver than others:")),
            .longOnly(.hadith("muslim:4a", cite: "Muqaddimah of Saheeh Muslim 4, Saheeh al-Bukhaari 1291", arabic: 36...50, english: [26...53])),
            .longOnly(.text("A lie about an ordinary man wrongs one man. A lie about the Messenger of Allah becomes, for everyone who believes it, a command or a prohibition from Allah that Allah never gave. In another hadith he named it among the greatest of all falsehoods, beside claiming a false father and claiming a dream one never saw:")),
            .longOnly(.hadith("bukhari:3509", cite: "Saheeh al-Bukhaari 3509", arabic: 29...56, english: [4...46])),
            .longOnly(.text("The dream in both hadiths matters today, when a new practice is sometimes defended with “I saw the Prophet in a dream and he told me.” Seeing him in a true dream is a real thing, as the hadith says, but the scholars, an-Nawawi (may Allah have mercy on him) among them, explain that a dream establishes no ruling of the religion: the Sunnah was completed in his waking life, and it is known by what was transmitted.")),
            .longOnly(.text("The same warning came with a command to teach. He told his Companions to convey from him even a single ayah, and in the same breath to keep the lie out of it (Saheeh al-Bukhaari 3461). Conveying and guarding were one duty from the start.")),
            .longOnly(.hadith("bukhari:3461", cite: "Saheeh al-Bukhaari 3461", arabic: 29...46, english: [4...55])),
            .shortOnly(.text("The scholars count it mutawaatir. A lie about an ordinary man wrongs one man; a lie about the Messenger of Allah becomes, for everyone who believes it, a command or a prohibition from Allah that Allah never gave.")),
        ]),
        ArticleSection("FORETOLD, THEN FULFILLED", [
            .text("The Prophet (peace be upon him) knew that liars would come, and said so:"),
            .hadith("muslim:7", cite: "Muqaddimah of Saheeh Muslim 7", arabic: 44...64, english: [0...32]),
            .longOnly(.text("Abdullah ibn Mas‘ood (may Allah be pleased with him) described one of their methods: a report with a face but no name, the kind that spreads because someone vaguely respectable seemed to say it.")),
            .longOnly(.hadith("muslim:17", cite: "Muqaddimah of Saheeh Muslim 17", arabic: 20...44, english: [0...52])),
            .longOnly(.text("The change came within the lifetime of the Companions. Imam Muslim records a scene from the middle of the first century: Bushayr al-Adawi, a Successor, sat with Abdullah ibn Abbaas (may Allah be pleased with him) reciting “the Messenger of Allah said, the Messenger of Allah said,” and Ibn Abbaas would not even look at him:")),
            .longOnly(.hadith("muslim:21", cite: "Muqaddimah of Saheeh Muslim 21", arabic: 80...110, english: [85...142])),
            .longOnly(.markdown("Riding **the difficult and the docile (الصَّعبَ وَالذَّلُولَ)** is an Arab image for a man who mounts any camel at all, tame or wild: people had begun to pass on whatever reached them. The turning point was the **fitnah**, the civil strife that began with the murder of Uthmaan (may Allah be pleased with him) in 35 AH (656 CE), after which, in Muhammad ibn Seereen’s famous words, the scholars began to say: name your men. From then on a report was weighed by the men who carried it.")),
            .shortOnly(.text("The change came within the lifetime of the Companions, when people began to pass on whatever reached them. The turning point was the fitnah, the civil strife that began with the murder of Uthmaan (may Allah be pleased with him) in 35 AH (656 CE), after which, in Muhammad ibn Seereen’s famous words, the scholars began to say: name your men. From then on a report was weighed by the men who carried it.")),
        ]),
        ArticleSection("WHY MEN FORGED", [
            .text("The books of the critics name the forgers and, often, their reasons. Knowing the reasons is half of catching them."),
            .longOnly(.step("1. **Sects.** Those who needed proofs for a doctrine invented them. Ibn al-Qayyim (may Allah have mercy on him) calls the Raafidah, the extreme Shia, the most given to lying of all people, and quotes the haafiz al-Khaleeli (d. 446 AH) that they forged hundreds of thousands of reports on the virtues of Ali (may Allah be pleased with him) and the Prophet’s household (al-Manaar al-Muneef). They need none of it: their authentic virtues fill whole chapters of the two Saheehs.")),
            .longOnly(.step("2. **Partisans of the other side, and of schools, cities and dynasties.** The people of the Sunnah did not spare their own. Ibn al-Qayyim lists forgeries that ignorant men “who claim the Sunnah” made in praise of Abu Bakr (may Allah be pleased with him), reports praising Abu Haneefah or ash-Shaafi‘i by name and others condemning them, praise of Baghdaad, Basrah and Koofah, and praise of the Abbasid caliphs, and he says the same of every hadith condemning Mu‘aawiyah or Amr ibn al-As (may Allah be pleased with them): all of it is lies.")),
            .longOnly(.step("3. **The zanaadiqah.** A **zindeeq (زِندِيق)** was a hidden unbeliever who wore Islam as a disguise, and some of them set out to make the religion look absurd. Abd al-Kareem ibn Abi al-Awjaa’, executed for heresy in the second century, is reported to have confessed that he had forged four thousand hadiths making the lawful unlawful and the unlawful lawful. Ibn al-Qayyim says of the grotesque reports that whoever made them was either extremely ignorant or a zindeeq who meant to belittle the Messenger.")),
            .longOnly(.step("4. **Storytellers.** The **qussaas (قُصَّاص)**, popular preachers in the mosques, wanted crowds, and wonder drew crowds: seventy thousand cities in Paradise for a small deed, birds with seventy thousand tongues. The critics despised these tales because the crowds loved them.")),
            .longOnly(.step("5. **Worshippers who meant well.** This kind did the most damage, because the forgers were pious. Ad-Daaraqutni names Maysarah ibn Abd Rabbih as the first of four men who made up a whole book of hadiths in praise of the intellect, each later forger copying it under new chains of his own; and of the reports promising a reward for reciting each surah, Ibn al-Qayyim says their forger confessed that he wanted to turn people back to the Quran.")),
            .longOnly(.step("6. **The powerful and their pleasures.** Some flattered a ruler. Ibn al-Qayyim names Wahb ibn Wahb, Abu al-Bakhtari, a judge who found the caliph al-Mahdi playing with pigeons and recited to him the hadith on lawful prize contests with one word added, “or a wing.” When the judge left, the caliph said that he bore witness his nape was the nape of a liar against the Messenger of Allah, and he got rid of the pigeons that had brought the lie about.")),
            .longOnly(.step("7. **Trade and appetite.** Praise of a food often served someone who sold it. The report that Jibreel brought the Prophet hareesah from Paradise, giving him the strength of forty men, was forged by Muhammad ibn al-Hajjaaj al-Lakhmi, whom Yahya ibn Ma‘een remembered as a hareesah seller and a wicked liar. Lentils, aubergines, rice and carnelian rings all had their forged praises too.")),
            .longOnly(.text("The authentic hadith that Abu al-Bakhtari corrupted is short, and its wording has no wing in it:")),
            .longOnly(.hadith("abudawud:2574", cite: "Sunan Abi Daawood 2574; graded saheeh by al-Albaani", arabic: 26...35, english: [4...15])),
            .shortOnly(.text("Sects invented proofs for their doctrines, and Ibn al-Qayyim (may Allah have mercy on him) calls the Raafidah the most given to lying of all people. Partisans of schools, cities and dynasties forged praise and blame, and the people of the Sunnah did not spare their own: forged praise of Abu Bakr (may Allah be pleased with him) was exposed as a lie too. The zanaadiqah, hidden unbelievers, set out to make the religion look absurd; storytellers in the mosques wanted crowds; worshippers who meant well forged rewards for deeds; others flattered rulers, or praised the goods they sold.")),
            .text("The excuse of the well-meaning forger deserves its own answer, and Ibn al-Qayyim gave it:"),
            .quote(text: "“One of the ignorant forgers said of this kind: ‘We lie for the Messenger of Allah, not against him.’ This ignorant man did not know that whoever says of him what he did not say has lied against him and earned the severe threat.” (Ibn al-Qayyim, al-Manaar al-Muneef)", arabic: "وَقَالَ بَعضُ جُهَلَاءِ الوَضَّاعِينَ فِي هَذَا النَّوعِ: نَحنُ نَكذِبُ لِرَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ وَلَا نَكذِبُ عَلَيهِ. وَلَم يَعلَم هَذَا الجَاهِلُ أَنَّهُ مَن قَالَ عَلَيهِ مَا لَم يَقُل فَقَد كَذَبَ عَلَيهِ وَاستَحَقَّ الوَعِيدَ الشَّدِيدَ", dimmed: true),
        ]),
        ArticleSection("HOW THEY WERE CAUGHT", [
            .text("A forger could invent a sentence, but not the world around it, and that is where the critics looked."),
            .quote(text: "“When the narrators used lies, we used history against them.” (Sufyaan ath-Thawri, related by Ibn as-Salaah in Uloom al-Hadith)", arabic: "لَمَّا استَعمَلَ الرُّوَاةُ الكَذِبَ استَعمَلنَا لَهُمُ التَّارِيخَ", dimmed: true),
            .longOnly(.markdown("**By dates.** Every narrator had a year of birth, a year of death, cities he visited and teachers he met, and the critics recorded them. A man who claimed to have heard a teacher who had died before he was born, or in a city the teacher never entered, convicted himself. The most famous case is a document the Jews of Khaybar produced in later centuries, claiming that the Prophet (peace be upon him) had freed them from the jizyah, the tax on non-Muslims under Muslim rule. It bore the witness of Sa‘d ibn Mu‘aadh and the hand of Mu‘aawiyah (may Allah be pleased with them both). But Sa‘d died after the Battle of the Trench, before Khaybar was taken; Mu‘aawiyah became Muslim only at the conquest of Makkah, after it; and the jizyah was not revealed until after Tabook. Al-Khateeb al-Baghdaadi exposed it in his time, and Ibn al-Qayyim, who gives ten reasons it is a lie, relates that his teacher Ibn Taymiyyah did the same when it was brought before him.")),
            .longOnly(.markdown("**By chains.** The critics knew which students sat with which teacher, and what each teacher’s hadiths were. A text that suddenly appeared with a new and better chain was a sign of **stealing hadith (سَرِقَةُ الحَدِيثِ)**: a forger had taken a known report and fitted it to a famous route. The book on the intellect mentioned above was exposed this way, passing from forger to forger with a fresh chain each time.")),
            .shortOnly(.markdown("**By dates.** Every narrator had a year of birth, a year of death, cities he visited and teachers he met, and the critics recorded them. A man who claimed to have heard a teacher who had died before he was born, or in a city the teacher never entered, convicted himself.")),
            .shortOnly(.markdown("**By chains.** The critics knew which students sat with which teacher, and what each teacher’s hadiths were. A text that suddenly appeared with a new and better chain was a sign of **stealing hadith (سَرِقَةُ الحَدِيثِ)**: a forger had taken a known report and fitted it to a famous route.")),
            .markdown("**By the text.** Some reports condemn themselves by what they say: they contradict the Quran, the known Sunnah, the senses or plain reason, or they simply do not sound like a prophet. Ibn al-Qayyim gathered these signs, as the next section shows."),
            .markdown("**By confession.** Many forgers admitted it, in repentance, in boasting, or on the way to execution, and the critics recorded the confessions with their names."),
            .longOnly(.text("When Abdullah ibn al-Mubaarak (may Allah have mercy on him) was asked about the forged hadiths in circulation, he answered that the master critics live for them, and recited:")),
            .longOnly(.ayah("15:9")),
            .longOnly(.text("A story told of the caliph Haaroon ar-Rasheed makes the same point: when a heretic awaiting execution boasted of the hadiths he had forged, the caliph replied that Abu Ishaaq al-Fazaari and Ibn al-Mubaarak would sift them out letter by letter.")),
        ]),
        ArticleSection("IBN AL-QAYYIM'S SIGNS", [
            .longOnly(.text("Ibn al-Qayyim (d. 751 AH) was asked whether a fabricated hadith could be known by a rule, without examining its chain. His answer, al-Manaar al-Muneef fi as-Saheeh wad-Da‘eef, begins with a condition before it gives any rule:")),
            .longOnly(.quote(text: "“This is a question of great weight. It is known only by one who has drunk deep of the knowledge of the authentic Sunnah, until it has mixed with his flesh and blood and become a settled skill in him.” (Ibn al-Qayyim, al-Manaar al-Muneef)", arabic: "فَهَذَا سُؤَالٌ عَظِيمُ القَدرِ، وَإِنَّمَا يَعلَمُ ذَلِكَ مَن تَضَلَّعَ فِي مَعرِفَةِ السُّنَنِ الصَّحِيحَةِ، وَاختَلَطَت بِلَحمِهِ وَدَمِهِ، وَصَارَ لَهُ فِيهَا مَلَكَةٌ", dimmed: true)),
            .longOnly(.text("He likens such a scholar to a Companion who lived beside the Prophet (peace be upon him) and knew what he would and would not say. Then he lists the signs. Among them:")),
            .longOnly(.step("1. **Wild exaggeration.** A bird with seventy thousand tongues, each with seventy thousand languages, created from one saying of la ilaaha illallah to seek forgiveness for the one who said it.")),
            .longOnly(.step("2. **The senses deny it.** “Aubergine is for whatever it is eaten for,” or “a sneeze while a hadith is told proves it true.” Of the second he says that even if someone declared its chain sound, the senses witness that it is forged: people sneeze while lying every day.")),
            .longOnly(.step("3. **It is ridiculous.** “If rice were a man, he would be forbearing”: speech that the words of sensible men are kept from, let alone the words of the master of the prophets.")),
            .longOnly(.step("4. **It contradicts the clear Sunnah.** Reports that whoever is named Muhammad or Ahmad will not enter the Fire, when the Sunnah makes salvation depend on faith and deeds, not on names.")),
            .longOnly(.step("5. **It claims a public event that everyone hid.** The claim that the Prophet named Ali (may Allah be pleased with him) his successor before all the Companions on the way back from the Farewell Pilgrimage, and that every one of them then agreed to conceal it.")),
            .longOnly(.step("6. **It sounds like a physician or a quack.** “Hareesah (a meat porridge) strengthens the back.”")),
            .longOnly(.step("7. **It gives dates.** “When such a year comes, such and such will happen.” Every hadith of this kind, he says, is a lie.")),
            .longOnly(.step("8. **It contradicts the plain Quran.** The report that the world lasts seven thousand years and we are in the last thousand would let anyone count the years left to the Hour, which Allah keeps to Himself:")),
            .longOnly(.ayah("7:187", words: 0...14)),
            .longOnly(.text("He adds whole classes that are false without exception: every hadith that al-Khidr is still alive, every hadith on the intellect, the prayers assigned to each night of the week, and the long reports about the giant Ooj ibn Anaaq, which, he says, were invented to make the reports of the prophets look ridiculous.")),
            .shortOnly(.text("Ibn al-Qayyim (d. 751 AH) was asked whether a fabricated hadith could be known by a rule, without examining its chain. In al-Manaar al-Muneef he answers that only one steeped in the authentic Sunnah can know it, and then lists the signs: wild exaggeration, such as a bird with seventy thousand tongues; what the senses deny; what is ridiculous; what contradicts the clear Sunnah or the plain Quran; a public event that everyone supposedly hid; speech that sounds like a physician or a quack; and dates: “when such a year comes, such and such will happen.”")),
            .callout("These signs are a scholar’s tools, not a licence for anyone to reject a hadith that surprises him. Ibn al-Qayyim made mastery of the authentic Sunnah the condition for using them, and the same critics accepted many sound reports that seemed strange to others. A text is judged by evidence, not by taste.", title: "Who May Use Them", icon: "exclamationmark.shield.fill"),
            .door(.article("HadithRejectorsView")),
        ]),
        ArticleSection("THE BOOKS THAT GUARD THE GATE", [
            .longOnly(.text("Because the forgeries were recorded, a Muslim today can look up almost any saying. The main works, in order:")),
            .longOnly(.bullet("**Ibn al-Jawzi (d. 597 AH), al-Mawdoo‘aat.** The great early collection, criticised for strictness: Ibn Hajar found in it one hadith of Saheeh Muslim, on people carrying whips like the tails of cattle, and wrote al-Qawl al-Musaddad to defend narrations of Ahmad’s Musnad that had been put among the forgeries.")),
            .longOnly(.bullet("**As-Suyooti (d. 911 AH), al-La’aali’ al-Masnoo‘ah,** which reviews Ibn al-Jawzi report by report.")),
            .longOnly(.bullet("**Ibn al-Qayyim (d. 751 AH), al-Manaar al-Muneef,** the book of signs quoted above.")),
            .longOnly(.bullet("**As-Sakhaawi (d. 902 AH), al-Maqaasid al-Hasanah,** on sayings “widespread on the tongues”: the place to look when a phrase is famous but no one knows its source. Al-Ajlooni’s Kashf al-Khafaa’ extends it.")),
            .longOnly(.bullet("**Ash-Shawkaani (d. 1250 AH, 1834 CE), al-Fawaa’id al-Majmoo‘ah,** edited with careful notes by Abd ar-Rahman al-Mu‘allimi al-Yamaani.")),
            .longOnly(.bullet("**Al-Albaani (d. 1420 AH, 1999 CE), Silsilat al-Ahaadeeth ad-Da‘eefah wal-Mawdoo‘ah wa Aathaaruha as-Sayyi’ fil-Ummah,** “the series of weak and fabricated hadiths and their evil effect on the Ummah,” which examines thousands of reports one by one across more than a dozen volumes.")),
            .longOnly(.text("The critics also weighed one another: Ibn al-Jawzi was known to be severe and al-Haakim, in his Mustadrak, lenient, and the scholars after them corrected both. No single verdict was beyond review.")),
            .shortOnly(.text("Because the forgeries were recorded, a Muslim today can look up almost any saying: in Ibn al-Jawzi’s al-Mawdoo‘aat and as-Suyooti’s review of it, in as-Sakhaawi’s al-Maqaasid al-Hasanah on sayings “widespread on the tongues”, and in al-Albaani’s Silsilat al-Ahaadeeth ad-Da‘eefah wal-Mawdoo‘ah, which examines thousands of reports one by one. No single verdict was beyond review: the scholars corrected Ibn al-Jawzi’s severity and al-Haakim’s leniency alike.")),
        ]),
        ArticleSection("SAYINGS THAT ARE NOT HIS", [
            .text("Some baseless sayings are repeated so often that Muslims are surprised to learn they are not hadith. Often a true teaching stands close by, and it is better."),
            .markdown("**“Seek knowledge even in China.”** Ibn Hibbaan said it has no basis, Ibn al-Jawzi listed it among the forgeries, and al-Albaani judged it false (as-Silsilah ad-Da‘eefah 416). The virtue of seeking knowledge needs no forgery; the Prophet (peace be upon him) said:"),
            .hadith("muslim:2699a", cite: "Saheeh Muslim 2699", arabic: 88...100, english: [90...109]),
            .longOnly(.markdown("**“Love of the homeland is part of faith.”** As-Saghaani judged it fabricated, as-Sakhaawi said he had not come across it, and al-Albaani judged it fabricated (as-Silsilah ad-Da‘eefah 36). Love of one’s land is natural and not blamed; the Prophet himself prayed for it when the Emigrants fell ill in their new home:")),
            .longOnly(.hadith("bukhari:1889", cite: "Saheeh al-Bukhaari 1889", arabic: 107...114, english: [133...147])),
            .longOnly(.text("But faith is not measured by a border, and the forged wording turns a natural feeling into a pillar of religion.")),
            .longOnly(.markdown("**“The ink of the scholar is holier than the blood of the martyr.”** Al-Khateeb al-Baghdaadi called it fabricated, and adh-Dhahabi said its text is fabricated. The rank of knowledge is in the Quran itself, without any need to lower the martyrs:")),
            .longOnly(.ayah("58:11", words: 17...25)),
            .markdown("**“The differing of my Ummah is a mercy.”** No chain for it is known at all, sound, weak or forged; al-Albaani ruled that it has no basis (as-Silsilah ad-Da‘eefah 57). Its meaning, too, cuts against the Quran, which praises those who do not divide."),
            .door(.article("MadhabView")),
            .markdown("**“If not for you, I would not have created the heavens.”** As-Saghaani judged it fabricated, and so did al-Albaani (as-Silsilah ad-Da‘eefah 282). The Quran states why creation was made:"),
            .ayah("51:56"),
            .longOnly(.text("The Prophet’s rank needs no invented words. He said of himself what is true:")),
            .longOnly(.hadith("muslim:2278", cite: "Saheeh Muslim 2278", arabic: 36...50, english: [0...30])),
        ]),
        ArticleSection("CHECK BEFORE YOU PASS IT ON", [
            .text("The Quran describes how the slander against Aa’ishah (may Allah be pleased with her) spread: not by one liar alone, but by believers who repeated what they heard without knowing it:"),
            .ayah("24:15"),
            .text("A forwarded message that begins “the Prophet said” is a report about the Messenger of Allah, and he counted whoever narrates from him what he thinks is a lie as one of the liars, a hadith Imam Muslim places at the very start of his Saheeh. Before sharing a saying, a Muslim can ask a few plain questions:"),
            .checklist([
                "**Which book, and which number?** “A hadith says” is not a source. A real hadith has a collection and a place in it.",
                "**What is its grade, and who graded it?** Outside al-Bukhaari and Muslim, look for the verdict of a known scholar.",
                "**Is it a famous saying with no known source?** Then look it up in the books of sayings that circulate, or in al-Albaani’s two Silsilahs.",
                "**Is it too wonderful?** Huge rewards for tiny deeds, exact dates, foods that cure everything: these are the forger’s fingerprints.",
                "**Is a good meaning doing the work of a chain?** A true meaning does not make a saying the Prophet’s.",
            ], title: "Before You Share", icon: "checkmark.shield.fill"),
            .text("Ibn as-Salaah adds a rule of speech: a report that is not established should not be told with the words “the Messenger of Allah said,” but, if it is told at all, with words like “it is reported.” A fabricated report may not be told even that way, except to warn against it."),
            .door(.article("HadithScienceGradesView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**If a saying has a good meaning, what is the harm in attributing it to the Prophet?**"),
            .longOnly(.text("The harm is the lie itself. The Prophet (peace be upon him) counted attributing to him what he did not say among the greatest falsehoods (Saheeh al-Bukhaari 3509), and the meaning of a forged saying is rarely as harmless as it looks: a reward invented for a deed changes how Muslims weigh their deeds, and a virtue invented for a person or a place changes what they love. Good meanings have their own words in the Quran and the authentic Sunnah, and those are enough.")),
            .shortOnly(.text("The harm is the lie itself, and the meaning of a forged saying is rarely as harmless as it looks: a reward invented for a deed changes how Muslims weigh their deeds, and a virtue invented for a person or a place changes what they love. Good meanings have their own words in the Quran and the authentic Sunnah, and those are enough.")),
            .longOnly(.markdown("**Did fabrication corrupt the Sunnah?**")),
            .longOnly(.text("No. The forgers were named, their forgeries were listed, and the lists are in print. A forged report that is known as forged deceives no one who checks. What the forgers achieved, in the end, was the opposite of what they wanted: they forced the Muslims to build the most careful science of reports any civilisation has produced.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Prophet (peace and blessings be upon him) warned that lying about him is not like lying about anyone else, and foretold that liars would come. They came, for sects, for schools and dynasties, out of heresy, for crowds, for piety misplaced, for rulers and for trade. The critics answered them with dates, with the knowledge of every chain, with the Quran and the known Sunnah, and with books that list the forgeries one by one. The same duty now falls on every Muslim who forwards a saying: ask for its source and its grade, and let only what is established be spoken in his name."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Mawdoo‘", arabic: "مَوضُوع", meaning: "**Fabricated**: literally “laid down” or “put in place,” a report invented and attributed to the Prophet ﷺ. It may not be narrated except to expose it."),
            .term("Waddaa‘", arabic: "وَضَّاع", meaning: "A **forger** of hadith, the lowest rank in the critics’ scale of narrators, below the narrator merely accused of lying."),
            .term("Zindeeq", arabic: "زِندِيق", meaning: "A hidden **unbeliever** who outwardly professes Islam. Several of the most notorious forgers were zanaadiqah who meant to corrupt the religion from within."),
            .term("La Asla Lahu", arabic: "لَا أَصلَ لَهُ", meaning: "“**It has no basis**”: the critics’ verdict on a saying for which no chain at all is known, as with “the differing of my Ummah is a mercy.”"),
        ]),
    ]
}

struct HadithScienceQudsiView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithScienceQudsiView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Hadith Qudsi")
        .englishArticle().selectableArticleList(article: "HadithScienceQudsiView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a hadith qudsi is a saying in which the Prophet Muhammad (peace and blessings be upon him) relates words from his Lord, with Allah speaking in the first person: “O My servants.” It is revelation, but it is not the Quran. It is not recited in the prayer, carries no challenge, may be narrated by its meaning, and reaches us through chains graded like any other hadith, so a report presented as qudsi can be saheeh, hasan, weak or even forged. The scholars of the Sunnah differ over whether its wording is from Allah as well as its meaning. Its authentic texts hold some of the most beloved words in the religion, on mercy, justice, sincerity and drawing near to Allah."),
        ]),
        ArticleSection("WHAT MAKES A HADITH QUDSI", [
            .markdown("**Qudsi (قُدسِي)** means “holy,” from **al-quds**, purity: the hadith is attributed to **al-Quddoos**, the Most Pure, Allah Himself. The scholars also call it **al-hadith al-ilaahi** (the divine hadith) or **ar-rabbaani** (the hadith of the Lord). Its mark is the speaker. In an ordinary hadith the Prophet (peace be upon him) speaks in his own voice; in a hadith qudsi he reports Allah speaking, and Allah says “I,” “Me,” “My servant.”"),
            .markdown("The narrators announce it with a fixed set of phrases: “Allah said,” “Allah says,” or the formula Abu Dharr (may Allah be pleased with him) uses at the head of the hadith on injustice, **feema rawa ‘an Allah (فِيمَا رَوَى عَنِ اللَّهِ)**, “in what he narrated from Allah, Blessed and Exalted.” Here is a typical one, in which Allah instructs the recording angels:"),
            .hadith("bukhari:7501", cite: "Saheeh al-Bukhaari 7501", arabic: 27...68, english: [4...101]),
            .longOnly(.text("Everything in it is about the unseen: what the angels write, and how Allah multiplies a good deed and pardons an evil intention. No one could know it by reasoning, and the Prophet does not present it as his own judgment. He reports it from his Lord.")),
        ]),
        ArticleSection("NOT THE QURAN", [
            .text("Because Allah speaks in both, the hadith qudsi is sometimes confused with the Quran. The scholars kept them apart on every point that matters:"),
            .versus(ArticleVersus.Side("The Quran", caption: "Allah’s speech in **wording and meaning**, carried by **mass transmission** in every letter, **recited in the prayer**, worship in its very recitation, and a **challenge** no one has met."), ArticleVersus.Side("A hadith qudsi", caption: "Revelation **attributed to Allah**, carried like any hadith by **chains that are graded**, not recited as Quran in the prayer, **may be narrated by meaning**, and challenges no one."), quranic: false),
            .longOnly(.bullet("**Transmission.** Every letter of the Quran is mutawaatir. Most qudsi reports are aahaad, carried by one or a few narrators at some level, and their chains must be examined.")),
            .longOnly(.bullet("**The challenge.** The Quran dares mankind and jinn to produce its like (17:88). No such challenge is made for any hadith qudsi.")),
            .longOnly(.bullet("**The prayer.** The prayer is valid only with Quran recited in it, and a hadith qudsi recited in its place would not count. Ibn Baaz (may Allah have mercy on him) put it plainly: in the prayer only the Quran is recited.")),
            .longOnly(.bullet("**Reward and rulings.** Reciting the Quran is worship letter by letter, and the rulings of the mushaf, such as touching it only in a state of purity on the view of the four schools, belong to the Quran alone.")),
            .longOnly(.bullet("**Wording.** The Quran may only be recited in the words that came down. A hadith qudsi, like other hadith, may be conveyed by its meaning by a narrator who knows Arabic and what changes a meaning.")),
            .longOnly(.ayah("17:88")),
            .longOnly(.text("The two meet in one famous hadith qudsi. The worshipper recites al-Faatihah, which is Quran, and Allah answers each verse, and that answer is the hadith:")),
            .longOnly(.hadith("muslim:395a", cite: "Saheeh Muslim 395", arabic: 64...159, english: [58...249])),
            .longOnly(.text("The verses of al-Faatihah within it are the Quran, recited in every unit of every prayer. The words around them are Allah’s reply, reported by the Prophet (peace be upon him) and never recited as Quran. One text holds both kinds of revelation, side by side, and no Muslim has ever confused them.")),
        ]),
        ArticleSection("NOT AN ORDINARY HADITH EITHER", [
            .text("Every word of the Prophet (peace be upon him) in matters of religion rests on revelation, as the Quran says of him:"),
            .ayah("53:3-4"),
            .markdown("So the difference between a hadith qudsi and a **hadith nabawi (حَدِيث نَبَوِي)**, a prophetic hadith, is not that one is revealed and the other is not. It is in how each is attributed. In a prophetic hadith the meaning is from revelation and the words are the Prophet’s, and he speaks as himself: “I command you,” “do not do this.” In a hadith qudsi he attributes the words to Allah, and Allah is the one who speaks."),
            .longOnly(.text("The distinction shows even inside a single narration. In the hadith of fasting, the Prophet first reports what Allah said: every deed of the son of Aadam is for him except fasting, which is for Me, and I reward it. Then he continues in his own voice about the fasting person’s shield and his two joys (Saheeh al-Bukhaari 1904). The listener can hear where the words of the Lord end and the words of the Messenger begin.")),
            .longOnly(.hadith("bukhari:1904", cite: "Saheeh al-Bukhaari 1904, Saheeh Muslim 1151", arabic: 37...94, english: [4...142])),
        ]),
        ArticleSection("WHOSE WORDING?", [
            .text("Scholars on both sides agree that a hadith qudsi is revelation and that it is rightly introduced with “Allah said.” They differ over its wording."),
            .longOnly(.markdown("**The first view: its wording and its meaning are from Allah.** Az-Zarqaani called this the well-known view, and Ibn Baaz (may Allah have mercy on him) held it: the hadith qudsi is speech attributed to Allah, attributed to Him by the Prophet, and it is counted as Allah’s speech in wording and meaning, though it does not carry the rulings of the Quran. The Prophet said “Allah said,” and Allah speaks with real speech when He wills, as He spoke to Moosa (peace be upon him):")),
            .longOnly(.ayah("4:164", words: 10...13)),
            .longOnly(.markdown("**The second view: its meaning is from Allah and its wording is the Prophet’s.** Al-Jurjaani defined it this way in at-Ta‘reefaat, saying that Allah conveyed the meaning by inspiration or in a dream and the Prophet expressed it in his own words, and among the scholars of our time Ibn al-Uthaymeen (may Allah have mercy on him) preferred it (Majmoo‘ Fataawa wa Rasaa’il Ibn al-Uthaymeen 9/59-62), while adding that the safest course is not to delve too far into the question.")),
            .longOnly(.text("The practical difference is small, and the facts on the ground are agreed. Narrators conveyed qudsi reports as they conveyed other hadith, so their wording often differs slightly from one chain to another. And on either view the hadith qudsi stands below the Quran, which alone is guarded letter by letter and recited as worship.")),
            .shortOnly(.markdown("**The first view: its wording and its meaning are from Allah.** Az-Zarqaani called this the well-known view, and Ibn Baaz (may Allah have mercy on him) held it.")),
            .shortOnly(.markdown("**The second view: its meaning is from Allah and its wording is the Prophet’s.** Al-Jurjaani defined it this way, and Ibn al-Uthaymeen (may Allah have mercy on him) preferred it, while adding that the safest course is not to delve too far into the question.")),
            .callout("Neither view denies that Allah speaks. The Ahl as-Sunnah affirm that Allah speaks with real speech, heard by whom He wills, and that the Quran is His uncreated speech. The difference over the hadith qudsi is only about how its words reached us, and both views are held within the Sunnah.", title: "A Difference Within the Sunnah", icon: "scalemass.fill"),
        ]),
        ArticleSection("HOW IT REACHED HIM", only: .long, [
            .text("The Quran names the ways Allah speaks to a human being:"),
            .ayah("42:51"),
            .text("Ibn Hajar notes that a hadith qudsi may have come to the Prophet (peace be upon him) directly or through the angel. Some came in a dream, and the dreams of prophets are revelation. Mu‘aadh ibn Jabal (may Allah be pleased with him) reports that the Prophet was late for the dawn prayer one morning, prayed it briefly, and then explained:"),
            .hadith("tirmidhi:3235", cite: "Jaami‘ at-Tirmidhi 3235; graded saheeh by al-Albaani", arabic: 140...177, english: [104...179]),
            .text("The hadith goes on to teach the deeds that expiate sins and a supplication the Prophet told his Companions to study and learn. At-Tirmidhi records that he asked al-Bukhaari about it and al-Bukhaari called it hasan saheeh, and the Hanbali haafiz Ibn Rajab (d. 795 AH) wrote a whole book on it. Its own words place the vision in sleep, and the Ahl as-Sunnah affirm what it says of Allah as it came, without likening Him to His creation."),
        ]),
        ArticleSection("GRADED LIKE ANY HADITH", [
            .longOnly(.text("A hadith qudsi has no protection that other hadiths lack. The most famous are in al-Bukhaari and Muslim, but many are in the Sunan, and there the graders weigh them chain by chain. This one closes an-Nawawi’s Forty Hadith:")),
            .longOnly(.hadith("tirmidhi:3540", cite: "Jaami‘ at-Tirmidhi 3540; graded saheeh by al-Albaani and Ahmad Shaakir", arabic: 41...89, english: [0...106])),
            .longOnly(.text("At-Tirmidhi himself notes that he knows it through this one route only, and its chain contains Katheer ibn Faa’id, of whom little is known. Yet Ahmad Shaakir and al-Albaani grade it saheeh and others hasan, and its meaning is carried by other sound reports, among them Abu Dharr’s hadith in Saheeh Muslim: whoever meets Allah with an earth full of sins, associating nothing with Him, Allah meets with as much forgiveness (Saheeh Muslim 2687). That is the science at work on a qudsi text exactly as on any other.")),
            .longOnly(.hadith("muslim:2687a", cite: "Saheeh Muslim 2687", arabic: 65...76, english: [99...130])),
            .shortOnly(.text("A hadith qudsi has no protection that other hadiths lack. The most famous are in al-Bukhaari and Muslim, but many are in the Sunan, and there the graders weigh them chain by chain.")),
            .text("The same science rejects qudsi sayings that have no chain at all. Two are widely quoted, especially in Sufi writing:"),
            .markdown("**“I was a hidden treasure, and I wished to be known, so I created creation.”** Ibn Taymiyyah (may Allah have mercy on him) said it is not the speech of the Prophet, and that he knew no chain for it, sound or weak."),
            .markdown("**“My heavens and My earth do not contain Me, but the heart of My believing servant contains Me.”** Ibn Taymiyyah said it is found among the reports of the People of the Book and has no known chain from the Prophet."),
            .text("A saying does not become revelation because it begins with “Allah says.” If anything, that opening calls for more care, because whoever forges it lies about Allah as well as His Messenger."),
            .door(.article("HadithScienceFabricationView")),
        ]),
        ArticleSection("WORDS THAT SHAPE A LIFE", [
            .text("The authentic qudsi hadiths are few compared with the whole Sunnah, but they reach the centre of a believer’s life. A few, with what the scholars drew from them:"),
            .markdown("**Sincerity.** Allah does not share a deed with a partner:"),
            .hadith("muslim:2985", cite: "Saheeh Muslim 2985", arabic: 34...51, english: [0...36]),
            .markdown("**Need.** The long hadith of Abu Dharr reminds every servant that he is astray until guided, hungry until fed, and answerable only for what he did:"),
            .hadith("muslim:2577a", cite: "Saheeh Muslim 2577", arabic: 182...204, english: [296...334]),
            .longOnly(.markdown("**Drawing near.** The friend of Allah (wali) is the one who does the obligations first and then keeps adding voluntary deeds:")),
            .longOnly(.hadith("bukhari:6502", cite: "Saheeh al-Bukhaari 6502", arabic: 35...102, english: [4...152])),
            .longOnly(.text("“I become his hearing” does not mean that Allah dwells in the servant, as the pantheists claim. The same hadith keeps the two apart: the servant asks and Allah gives, the servant seeks refuge and Allah protects. Ibn al-Uthaymeen explains that the meaning is that Allah guides his hearing, sight, hand and foot, so that he hears, sees, acts and walks only in what pleases Allah.")),
            .longOnly(.markdown("**Mercy toward people.** On the Day of Resurrection Allah will say, “I was sick and you did not visit Me”:")),
            .longOnly(.hadith("muslim:2569", cite: "Saheeh Muslim 2569", arabic: 30...68, english: [0...86])),
            .longOnly(.text("The hadith explains itself: the one who was sick was a servant, and Allah is never sick. This is not a reading forced onto the text from outside, which is why the scholars of the Sunnah who refuse to twist the attributes accept it: the words of the hadith give the meaning.")),
            .markdown("**The last third of the night.** The Prophet (peace be upon him) reports Allah’s call in the hour before dawn:"),
            .hadith("bukhari:1145", cite: "Saheeh al-Bukhaari 1145", arabic: 35...60, english: [5...68]),
            .text("The Salaf passed this hadith on as it came, affirming a real descent that befits Allah’s majesty, without asking how and without likening it to the movement of creatures; Ibn Taymiyyah devoted a whole treatise to it. Its lesson is an invitation: the night has an hour when the door is open."),
        ]),
        ArticleSection("THE COLLECTIONS", only: .long, [
            .text("The great collections do not set the qudsi hadiths apart: they sit in the Saheehs, the Sunan and the Musnads under their subjects, and some are among the oldest written hadith we have: the hadith that Allah has prepared for His righteous servants what no eye has seen is in the first-century Saheefah of Hammaam ibn Munabbih (Saheeh al-Bukhaari 7498)."),
            .hadith("bukhari:7498", cite: "Saheeh al-Bukhaari 7498", arabic: 30...46, english: [4...35]),
            .text("Later scholars gathered them:"),
            .bullet("**Al-Ithaafaat as-Saniyyah,** the title of two collections, one by Abd ar-Ra’oof al-Munaawi (d. 1031 AH) and one by Muhammad al-Madani (d. 1200 AH). They gathered generously, and their contents still need checking."),
            .bullet("**As-Saheeh al-Musnad min al-Ahaadeeth al-Qudsiyyah,** by the Egyptian scholar Mustafa al-Adawi, which keeps only the authentic."),
            .bullet("**Forty Hadith Qudsi,** a selection by Ezzeddin Ibraaheem and Denys Johnson-Davies, each hadith given with its source, most from al-Bukhaari and Muslim. It is the collection most English readers meet first."),
            .text("An-Nawawi’s Forty Hadith includes three: the hadith of injustice (its 24th), of the friend of Allah (its 38th) and of forgiveness (its 42nd and last). A reader who knows those three already holds much of what the qudsi hadiths teach."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Is a hadith qudsi greater than the Quran, since Allah is speaking?**"),
            .text("No. The Quran is the highest of all speech: preserved in every letter, inimitable, recited in the prayer and in worship. Allah speaks in the Quran on every page, and the hadith qudsi stands below it on either view of its wording."),
            .longOnly(.markdown("**Can I recite a hadith qudsi in my prayer?**")),
            .longOnly(.text("Not in place of the Quran: the recitation of the prayer is Quran only, and al-Faatihah is required. A Muslim may of course remember a hadith qudsi and act on it, and a supplication taught in one may be used like any authentic supplication.")),
            .longOnly(.markdown("**Is every “Allah says” in a book a hadith qudsi?**")),
            .longOnly(.text("No. Some are verses of the Quran, some are authentic qudsi hadiths, and some are sayings of the People of the Book or of preachers with no chain at all. The test is the same as for any hadith: which book, which chain, and what grade.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A hadith qudsi is the Prophet (peace and blessings be upon him) relating what his Lord said. It is revelation, but it is not the Quran: it is not recited in the prayer, poses no challenge, may be narrated by meaning, and is graded through its chains like every other hadith. Scholars of the Sunnah differ over whether its wording is Allah’s or the Prophet’s, while agreeing that its meaning is from Allah. Its authentic texts, on sincerity, need, nearness and mercy, are among the most precious words a Muslim can carry."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Hadith Qudsi", arabic: "حَدِيث قُدسِي", meaning: "A hadith in which the Prophet ﷺ relates words from **Allah**, who speaks in the first person. Also called the divine (ilaahi) or lordly (rabbaani) hadith."),
            .term("Hadith Nabawi", arabic: "حَدِيث نَبَوِي", meaning: "A **prophetic** hadith: the Prophet’s own words, deeds or approval. Revelation in meaning, attributed to him rather than to Allah."),
            .term("Tahaddi", arabic: "تَحَدِّي", meaning: "The **challenge** to produce the like of the Quran (17:88). It belongs to the Quran alone and marks one of the clearest differences from the hadith qudsi."),
            .term("Ar-Riwaayah bil-Ma‘na", arabic: "الرِّوَايَةُ بِالمَعنَى", meaning: "**Narrating by meaning**: conveying a report in one’s own words while keeping its sense exactly. Allowed for hadith, including the qudsi, and never for the Quran."),
        ]),
    ]
}

struct HadithScienceGradesView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithScienceGradesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("How to Read a Hadith’s Grade")
        .englishArticle().selectableArticleList(article: "HadithScienceGradesView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a line like “Sunan Abi Daawood 4607; graded saheeh by al-Albaani” says which book holds a report, where in it, and which scholar judged it. Reading it well means knowing what the words of the verdict mean (saheeh and hasan in themselves or by support, a sound chain as against a sound hadith, at-Tirmidhi’s “hasan saheeh”), why careful graders sometimes disagree, where the two Saheehs and the Sunan stand, what the scholars said about weak hadith in matters of virtue, and what a Muslim who is not a specialist should do with all of it."),
            .hadith("abudawud:4607", cite: "Sunan Abi Daawood 4607; graded saheeh by al-Albaani", arabic: 112...132, english: [159...192]),
        ]),
        ArticleSection("READING THE LINE", [
            .text("A citation has three parts. The book: Saheeh al-Bukhaari, Sunan Abi Daawood, Jaami‘ at-Tirmidhi, and so on. The number: its place in that book. And, outside the two Saheehs, the verdict with the name of the one who gave it."),
            .longOnly(.text("The number belongs to an edition, not to the author. Al-Bukhaari and Muslim did not number their hadiths; the numbers most people use for Saheeh Muslim and Sunan Ibn Maajah, for example, were given by the Egyptian editor Muhammad Fu’aad Abd al-Baaqi in the twentieth century. Other editions count differently, which is why the same hadith can carry two numbers in two books, and why a citation should say which numbering it follows when it matters.")),
            .longOnly(.text("The verdict is the part that needs the most care. Here is a hadith from at-Tirmidhi with his own grading still attached at the end of the Arabic, where he gives it after nearly every report:")),
            .longOnly(.hadith("tirmidhi:3926", cite: "Jaami‘ at-Tirmidhi 3926; graded saheeh by al-Albaani and Ahmad Shaakir", arabic: 38...64, english: [9...43])),
            .longOnly(.markdown("The Prophet Muhammad (peace and blessings be upon him) said it to Makkah as he left it. At-Tirmidhi’s own words follow: **haadha hadeethun hasanun saheehun ghareebun min haadha al-wajh (هَذَا حَدِيثٌ حَسَنٌ صَحِيحٌ غَرِيبٌ مِن هَذَا الوَجهِ)**, “this hadith is hasan saheeh, ghareeb from this route.” Five modern graders have also weighed it: Ahmad Shaakir and al-Albaani (may Allah have mercy on them) call it saheeh, Bashshaar Awwaad Ma‘roof hasan saheeh, and the Darussalam editors and Zubayr Ali Zai hasan. Every one of them accepts it. What they differ over is the degree, and the rest of this page explains why.")),
            .shortOnly(.text("The number belongs to an edition, not to the author, which is why the same hadith can carry two numbers in two books.")),
            .shortOnly(.text("The verdict is the part that needs the most care. When several graders weigh the same report, they often all accept it and differ only over its degree, and the rest of this page explains why.")),
        ]),
        ArticleSection("THE WORDS OF THE VERDICT", [
            .text("The grades run from saheeh at the top to mawdoo‘ at the bottom:"),
            .gradeLadder,
            .longOnly(.text("Each of the two accepted grades has two kinds. A report that meets the conditions through its own chain is saheeh or hasan li-dhaatihi, “in itself.” A report whose own chain falls a little short, but which is lifted by other routes or supporting reports, is saheeh or hasan li-ghayrihi, “by virtue of others.” Below them the weak grades also have degrees: da‘eef (weak), da‘eef jiddan (very weak), munkar (a weak narrator contradicting stronger ones), and mawdoo‘ (forged). Only the mild kind of weakness can ever be lifted by support; a liar’s report stays a lie however many times it is copied.")),
            .longOnly(.text("One short hadith shows the whole vocabulary at work:")),
            .longOnly(.hadith("abudawud:2", cite: "Sunan Abi Daawood 2; graded saheeh by al-Albaani", arabic: 27...35, english: [0...19])),
            .longOnly(.text("Four graders give four verdicts on it. Muhammad Muhyi ad-Deen Abd al-Hameed and al-Albaani say saheeh. Shu‘ayb al-Arnaa’oot says saheeh li-ghayrihi. Zubayr Ali Zai says da‘eef. They are not disagreeing about the facts. Its chain runs through Ismaa‘eel ibn Abd al-Malik, whom Ibn Hajar describes as truthful but given to many mistakes, and through Abu az-Zubayr, who sometimes concealed whom he heard from, and here says only “from Jaabir.” Taken alone, that chain is weak, which is Zubayr Ali Zai’s verdict on it. But the hadith just before it in the same book reports the same practice from al-Mugheerah ibn Shu‘bah (may Allah be pleased with him) through a better chain (Sunan Abi Daawood 1), and with that support the meaning is established, which is what “saheeh li-ghayrihi” says outright and what al-Albaani’s “saheeh” means as a verdict on the hadith rather than on one chain.")),
            .longOnly(.hadith("abudawud:1", cite: "Sunan Abi Daawood 1; graded hasan saheeh by al-Albaani", arabic: 30...40, english: [0...14])),
            .longOnly(.callout("A grade of da‘eef on one chain is not always a verdict that the Prophet never said it. Sometimes it means only: this chain alone does not prove it. Read the other graders, and look for the supporting reports before concluding anything.", title: "One Chain or the Whole Hadith?", icon: "magnifyingglass")),
            .shortOnly(.text("Each of the two accepted grades has two kinds: saheeh or hasan li-dhaatihi, “in itself,” when its own chain meets the conditions, and li-ghayrihi, “by virtue of others,” when a chain a little short is lifted by other routes or supporting reports. Only the mild kind of weakness can ever be lifted by support; a liar’s report stays a lie however many times it is copied.")),
        ]),
        ArticleSection("A SOUND CHAIN IS NOT YET A SOUND HADITH", [
            .markdown("Some verdicts speak only about the chain. **Isnaaduhu saheeh (إِسنَادُهُ صَحِيحٌ)**, “its chain is sound,” is a step short of **saheeh**. Ibn as-Salaah explains why: a chain of trustworthy men can still carry a report that is shaadh, contradicting stronger narrators, or that has a hidden defect, so a critic who says only that the chain is sound has not yet vouched for the hadith. He adds that when a reliable haafiz says it and mentions no defect, the apparent meaning is that he judges the hadith sound as well."),
            .longOnly(.markdown("A related phrase is easier to misread. In Majma‘ az-Zawaa’id, al-Haythami often writes **rijaaluhu rijaal as-saheeh (رِجَالُهُ رِجَالُ الصَّحِيحِ)**, “its men are the men of the Saheeh”: every narrator is one al-Bukhaari or Muslim used. That says nothing about whether each heard from the next, whether a mudallis concealed a link, or whether the report has a hidden defect. It is a description of the narrators, not a grade.")),
            .longOnly(.markdown("The same caution applies to al-Haakim’s **saheeh ‘ala shart ash-shaykhayn**, “sound on the condition of the two shaykhs,” in his Mustadrak. It means he judged that its narrators meet the standard of al-Bukhaari and Muslim, not that either of them narrated it, and adh-Dhahabi’s summary of the Mustadrak often agrees with him and often does not. In modern editions, Zubayr Ali Zai’s “isnaad hasan” and Shu‘ayb al-Arnaa’oot’s “its chain is weak, and the hadith is hasan by its supports” draw the same line between the chain and the hadith in a single sentence.")),
            .shortOnly(.text("In the same way, al-Haythami’s “its men are the men of the Saheeh” describes the narrators, not the grade: it says nothing about whether each heard from the next. And al-Haakim’s “sound on the condition of the two shaykhs” means only that he judged its narrators to meet the standard of al-Bukhaari and Muslim, not that either of them narrated it.")),
        ]),
        ArticleSection("AT-TIRMIDHI'S HASAN SAHEEH", [
            .longOnly(.text("At-Tirmidhi (d. 279 AH) made hasan a common grade, and he defined what he meant by it at the end of his book:")),
            .longOnly(.quote(text: "“Every hadith that is narrated with no one in its chain accused of lying, that is not shaadh, and that is narrated by more than one route in the like of it: that is, with us, a hasan hadith.” (at-Tirmidhi, al-Ilal as-Sagheer at the end of his Jaami‘)", arabic: "كُلُّ حَدِيثٍ يُروَى لَا يَكُونُ فِي إِسنَادِهِ مَن يُتَّهَمُ بِالكَذِبِ، وَلَا يَكُونُ الحَدِيثُ شَاذًّا، وَيُروَى مِن غَيرِ وَجهٍ نَحوَ ذَاكَ، فَهُوَ عِندَنَا حَدِيثٌ حَسَنٌ", dimmed: true)),
            .longOnly(.text("His hasan, in other words, is close to what later scholars call hasan li-ghayrihi: a chain free of liars and supported by other routes. But he also often joins two grades, “hasan saheeh,” which puzzled later scholars, since a hadith cannot be both a little below saheeh and saheeh at once. Ibn Hajar gave the answer most have followed:")),
            .longOnly(.quote(text: "“If the two are joined, it is because of hesitation over the narrator where he is alone in it; otherwise it is with regard to two chains.” (Ibn Hajar, Nukhbat al-Fikar)", arabic: "فَإِن جُمِعَا فَلِلتَّرَدُّدِ فِي النَّاقِلِ حَيثُ التَّفَرُّدُ، وَإِلَّا فَبِاعتِبَارِ إِسنَادَينِ", dimmed: true)),
            .longOnly(.text("So when a hadith has one chain, “hasan saheeh” means: saheeh on one critic’s view of its narrator and hasan on another’s, and at-Tirmidhi leaves both in place. When it has two chains, one is hasan and the other saheeh. Either way, “hasan saheeh” is stronger than hasan alone. The phrase was not his invention: he records that he asked al-Bukhaari about a hadith and al-Bukhaari answered that it is hasan saheeh (Jaami‘ at-Tirmidhi 3235). And when he adds “ghareeb,” as he did above, he is saying that the report comes through a single line at some point, which does not by itself weaken it.")),
            .longOnly(.hadith("tirmidhi:3235", cite: "Jaami‘ at-Tirmidhi 3235; graded saheeh by al-Albaani", arabic: 302...313, text: "“I asked Muhammad ibn Ismaa‘eel about this hadith, and he said: This hadith is hasan saheeh.”")),
            .longOnly(.text("Later critics such as adh-Dhahabi observed that at-Tirmidhi was at times generous in his gradings, so his verdict is weighed beside the others rather than taken alone, as the modern graders do.")),
            .shortOnly(.text("At-Tirmidhi (d. 279 AH) made hasan a common grade, and by it he meant a chain with no one accused of lying, a report that is not shaadh, narrated by more than one route. He also often joins two grades, “hasan saheeh,” and Ibn Hajar gave the answer most have followed: when a hadith has one chain, the phrase means saheeh on one critic’s view of its narrator and hasan on another’s; when it has two, one is hasan and the other saheeh. Either way, “hasan saheeh” is stronger than hasan alone, and “ghareeb” beside it says only that the report comes through a single line at some point.")),
        ]),
        ArticleSection("WHY GRADERS DIFFER", [
            .longOnly(.text("The rules are shared; applying them to particular men and routes is expert judgment. Careful scholars part ways for a few recurring reasons:")),
            .longOnly(.step("1. **A narrator is judged differently.** One early critic calls a man trustworthy and another weak, and a later grader must decide whose words carry more weight, especially when the criticism is explained.")),
            .longOnly(.step("2. **Support is counted differently.** Whether several weak routes lift one another depends on how weak each is and whether they are truly independent. Al-Albaani was readier than some to lift a report by its routes; Zubayr Ali Zai often graded the chain before him on its own.")),
            .longOnly(.step("3. **A hidden defect is seen or not seen.** One grader finds that a trusted narrator erred in this particular report; another does not.")),
            .longOnly(.step("4. **Scholars revise.** Al-Albaani changed a number of his own verdicts over the decades as he found new routes, and his revisions have been gathered in a book. A grade should be checked against a scholar’s later works where it can be.")),
            .longOnly(.text("The graders whose names appear most often beside the Sunan today:")),
            .longOnly(.bullet("**Ahmad Muhammad Shaakir (1892–1958),** the Egyptian judge and haafiz who edited part of at-Tirmidhi and a large part of the Musnad of Ahmad.")),
            .longOnly(.bullet("**Muhammad Naasir ad-Deen al-Albaani (1914–1999),** whose Saheeh and Da‘eef editions of the four Sunan, Irwaa’ al-Ghaleel and two Silsilahs grade tens of thousands of reports.")),
            .longOnly(.bullet("**Shu‘ayb al-Arnaa’oot (1928–2016),** who led the editing of the Musnad of Ahmad and of the Sunan with full notes on every chain.")),
            .longOnly(.bullet("**Bashshaar Awwaad Ma‘roof,** the Iraqi editor of at-Tirmidhi, Ibn Maajah and Tahdheeb al-Kamaal.")),
            .longOnly(.bullet("**Zubayr Ali Zai (1957–2013),** the Pakistani hadith scholar whose gradings accompany several Urdu and English editions.")),
            .longOnly(.bullet("**The Darussalam editors,** whose verdicts are printed with the publisher’s English translations of the Sunan.")),
            .shortOnly(.text("The rules are shared; applying them to particular men and routes is expert judgment, and careful scholars part ways for a few recurring reasons. A narrator is judged differently by the early critics. Support is counted differently, al-Albaani being readier than some to lift a report by its routes. A hidden defect is seen by one grader and not by another. And scholars revise: al-Albaani changed a number of his own verdicts over the decades as he found new routes.")),
            .text("When they agree, a reader can be at ease. When they differ, the difference is itself information: it tells him the report is debated, and that a scholar who gives reasons deserves more attention than one who gives only a word."),
        ]),
        ArticleSection("THE TWO SAHEEHS AND THE SUNAN", [
            .longOnly(.text("Not every book stands at the same height, and a citation’s book already says something about its grade.")),
            .longOnly(.markdown("**Saheeh al-Bukhaari and Saheeh Muslim.** Both authors set out to include only sound hadith, and the Ummah received their books with acceptance, which is why their hadiths are cited without a grade. A small number of their reports were questioned by critics such as ad-Daaraqutni, and those discussions are known and answered in detail; they do not touch the standing of the books.")),
            .longOnly(.markdown("**Sunan Abi Daawood.** In his letter to the people of Makkah, Abu Daawood wrote that he gathered the saheeh and what resembles and approaches it, that he pointed out any report with serious weakness, and that what he left without comment is fit (saalih), some sounder than others. The later graders read that silence carefully: “fit” includes reports that are only good enough to support others.")),
            .longOnly(.markdown("**Jaami‘ at-Tirmidhi.** At-Tirmidhi grades as he goes, names the Companions who narrate the same meaning, and records the practice of the jurists, so his book teaches the science while it narrates.")),
            .longOnly(.markdown("**Sunan an-Nasaa’i.** The smaller Sunan, al-Mujtaba, is counted among the most careful of the four in its choice of narrators.")),
            .longOnly(.markdown("**Sunan Ibn Maajah.** It holds the most weak reports of the six, and a few forged ones, among them a hadith praising the author’s own city of Qazween. Ibn Taahir al-Maqdisi (d. 507 AH) was among the first to count it the sixth book, and some scholars preferred the Muwatta’ of Maalik or the Sunan of ad-Daarimi in its place.")),
            .longOnly(.text("Outside the six, the Musnad of Ahmad is vast and mostly sound, the Mustadrak of al-Haakim is lenient, and every report in them is graded on its own.")),
            .shortOnly(.text("Not every book stands at the same height. The hadiths of al-Bukhaari and Muslim are cited without a grade, because both authors set out to include only sound hadith and the Ummah received their books with acceptance. In the Sunan of Abu Daawood, at-Tirmidhi, an-Nasaa’i and Ibn Maajah, every report is graded on its own, and the Sunan of Ibn Maajah holds the most weak reports of the six, and a few forged ones.")),
            .door(.article("HadithPreservationView")),
        ]),
        ArticleSection("WEAK HADITH AND DEEDS OF VIRTUE", [
            .longOnly(.text("Some early imams spoke of being stricter with reports on the lawful and the unlawful than with reports on virtues. Imam Ahmad and Abd ar-Rahman ibn Mahdi are reported, by al-Khateeb al-Baghdaadi in al-Kifaayah, to have said that when they narrated on the lawful and unlawful they were strict about the chains, and when they narrated on virtues and the like they were lenient. Later scholars turned that leniency into conditions, and Ibn Hajar’s three, recorded by his student as-Sakhaawi, became the best known:")),
            .longOnly(.step("1. **The weakness is not severe.** No report from a liar, from one accused of lying, or from one whose mistakes are gross.")),
            .longOnly(.step("2. **The deed falls under a principle already established** by sound evidence, so the report adds encouragement, not a new practice.")),
            .longOnly(.step("3. **The one who acts on it does not believe it is established** from the Prophet (peace be upon him), but acts out of caution.")),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) explained what the early imams had meant. A weak hadith cannot make anything recommended, because declaring a deed recommended is a ruling of the Sharee‘ah and needs sound proof. What they allowed was narrating a report not known to be a lie about the reward of a deed whose worth was already proven, in hope of that reward. He also pointed out that the “weak” of the early imams included much of what later scholars call hasan.")),
            .longOnly(.text("Other scholars did not act on weak hadith even in virtues. Ahmad Shaakir wrote in al-Baa‘ith al-Hatheeth that rulings and virtues are alike in this, and that the only proof is what is saheeh or hasan; al-Albaani argued the same at length in the introduction to his Saheeh at-Targheeb wat-Tarheeb. Their reasons were practical as well as principled: the sound Sunnah already holds more virtue than a lifetime can exhaust; the conditions are seldom kept, so weak reports end up quoted as if they were established; and a weak report yields only a faint presumption, while the Quran warns that conjecture avails nothing against the truth (53:28).")),
            .longOnly(.ayah("53:28")),
            .shortOnly(.text("Some early imams, Ahmad and Abd ar-Rahman ibn Mahdi among them, are reported to have been strict about the chains of reports on the lawful and the unlawful and lenient with reports on virtues. Later scholars turned that leniency into conditions: the weakness is not severe, the deed falls under a principle already established by sound evidence, and the one who acts on it does not believe it is established from the Prophet (peace be upon him). Other scholars, Ahmad Shaakir and al-Albaani among them, did not act on weak hadith even in virtues: the sound Sunnah already holds more virtue than a lifetime can exhaust.")),
            .callout("Every scholar who allowed it forbade presenting a weak report as the Prophet’s established word, forbade using what is severely weak, and forbade building a new act of worship on it. The safest course is al-Albaani’s: what the sound Sunnah gives is enough.", title: "Where Both Sides Agree", icon: "checkmark.seal.fill"),
        ]),
        ArticleSection("WHAT THE NON-SPECIALIST SHOULD DO", [
            .text("Grading is a craft that takes a lifetime, and the Quran does not ask every Muslim to master every craft. It asks him to turn to those who know:"),
            .ayah("16:43", words: 8...14),
            .longOnly(.text("For hadith, that means relying on the verdicts of trustworthy graders and not on one’s own taste. Ibn as-Salaah held that in later centuries a scholar should rely on the gradings of the earlier imams rather than grade anew; an-Nawawi held that a qualified scholar may still grade, and the later scholars followed an-Nawawi, but no one held that an unqualified reader may. In practice:")),
            .shortOnly(.text("For hadith, that means relying on the verdicts of trustworthy graders and not on one’s own taste. In practice:")),
            .step("1. **In al-Bukhaari or Muslim?** Then it is established. Read it in context and with the explanation of the scholars."),
            .step("2. **Outside them?** Look for the grade and the grader. Prefer a verdict that gives its reasons."),
            .step("3. **Graders differ?** Follow the one whose knowledge and method you trust most, and say honestly that the report is disputed. Do not pick whichever verdict suits what you already wanted."),
            .step("4. **No source at all?** Do not attribute it to the Prophet (peace be upon him). Ask someone who knows, or leave it."),
            .longOnly(.text("Reliable places to look include the grade lines that sunnah.com prints with each grader’s name, the hadith encyclopedia of ad-Durar as-Saniyyah, which gathers the classical and modern verdicts on a report, al-Albaani’s editions of the Sunan, and the answers of scholars at IslamQA.")),
            .door(.link("https://sunnah.com", title: "Sunnah.com", subtitle: "The collections in Arabic and English, with graders’ verdicts")),
            .door(.link("https://dorar.net/hadith", title: "Ad-Durar as-Saniyyah", subtitle: "Hadith encyclopedia: search in Arabic, read the verdicts")),
            .door(.article("HadithScienceTermsView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Does “graded saheeh by al-Albaani” mean only al-Albaani thinks so?**"),
            .text("No. It names the grader the citation relies on, usually because his verdict is the most widely available. Others may agree, as Ahmad Shaakir does on many reports, and some may differ. A citation that names its grader is being honest about where the verdict came from."),
            .markdown("**If scholars disagree, can I use the hadith at all?**"),
            .text("A Muslim who follows a trustworthy scholar’s grading in good faith is excused, even where others disagree, just as in questions of law. What he should not do is hide the disagreement, or treat a disputed report as if it were as certain as a hadith of al-Bukhaari."),
            .markdown("**Why are hadiths of al-Bukhaari and Muslim cited without a grade?**"),
            .text("Because the books themselves are the grade. Their authors applied the strictest conditions, generations of critics examined their chains, and the Ummah accepted them. Adding “graded saheeh by” to a hadith of al-Bukhaari would add nothing."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A hadith’s citation names its book, its place in a particular edition, and, outside the two Saheehs, the scholar whose verdict it relies on. Saheeh and hasan come in themselves or by support; a sound chain is not yet a sound hadith; at-Tirmidhi’s hasan saheeh is a mark of strength, not confusion. Graders differ over narrators, supports and hidden defects, and the difference is itself worth knowing. Weak reports were never the foundation of anything in the religion, and the safest course is the one al-Albaani took: to leave them aside. For the Muslim who is not a specialist, the Quran’s instruction is enough: ask those who know, and follow the verdicts they give with their reasons."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Saheeh li-Ghayrihi", arabic: "صَحِيح لِغَيرِه", meaning: "“**Sound by virtue of others**”: a report whose own chain is hasan, lifted to saheeh by other routes or supporting reports."),
            .term("Hasan li-Ghayrihi", arabic: "حَسَن لِغَيرِه", meaning: "“**Good by virtue of others**”: a report whose own chain is mildly weak, lifted to hasan by support. Severe weakness, such as a liar in the chain, cannot be lifted."),
            .term("Isnaaduhu Saheeh", arabic: "إِسنَادُهُ صَحِيحٌ", meaning: "“**Its chain is sound**”: a verdict on the chain alone, one step short of declaring the hadith itself saheeh, since the text may still be shaadh or defective."),
            .term("Tasheeh and Tad‘eef", arabic: "تَصحِيح وَتَضعِيف", meaning: "**Grading as sound** and **grading as weak**: the critic’s two verdicts. Tasheeh is a judgment on evidence, not a compliment."),
        ]),
    ]
}

struct HadithScienceOrientalistsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithScienceOrientalistsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Goldziher, Schacht and the Western Critics")
        .englishArticle().selectableArticleList(article: "HadithScienceOrientalistsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: from the late nineteenth century, European scholars argued that most hadith were not the words of the Prophet Muhammad (peace and blessings be upon him) but the products of later disputes, projected back onto him with invented chains. Ignaz Goldziher made the case in 1890; Joseph Schacht sharpened it for legal hadith in 1950 with his theories of chains that grew backwards, the “common link” and the argument from silence; G. H. A. Juynboll carried it further. They were answered from the sources by Mustafa as-Sibaa‘i and Muhammad Mustafa al-A‘zami, from the early documents by Fuat Sezgin and Nabia Abbott, and from within Western method itself by Harald Motzki and Gregor Schoeler, whose work traced reports back into the first century. The documents, above all the Saheefah of Hammaam ibn Munabbih, now stand against the sceptics’ central claim."),
        ]),
        ArticleSection("THE QUESTION THEY ASKED", [
            .longOnly(.markdown("The **orientalists (المُستَشرِقُون)** were European scholars of the languages and history of the East. The best of them read the Arabic sources with great learning, and their work on hadith deserves to be stated fairly before it is answered. They approached the hadith as historians who do not accept prophethood, using the methods of source criticism developed for the Bible and the classics, and their question was a historian’s question: when can a given report first be shown to exist, and who put it into circulation?")),
            .shortOnly(.markdown("The **orientalists (المُستَشرِقُون)** were European scholars of the languages and history of the East. They approached the hadith as historians who do not accept prophethood, and their question was a historian’s question: when can a given report first be shown to exist, and who put it into circulation?")),
            .text("Their answers matter to Muslims for a simple reason. Most modern doubts about the Sunnah, including those of the Quran-only movements, repeat their arguments in simpler form: the hadith were written two centuries later, the chains were invented, the reports reflect the politics of the Umayyads and Abbasids. Knowing where these claims came from, and how they fared, is the best protection against them."),
            .door(.article("HadithRejectorsView")),
        ]),
        ArticleSection("GOLDZIHER: HADITH AS A MIRROR", [
            .longOnly(.text("Ignaz Goldziher (1850–1921) was a Hungarian Jewish scholar who had studied in Cairo, including at al-Azhar, as a young man in 1873–74. The second volume of his Muhammedanische Studien (Halle, 1890), translated into English as Muslim Studies (1967–71), contains his study of the development of hadith. His thesis was that the great mass of hadith does not record the Prophet’s time but mirrors the religious, political and legal struggles of the first two centuries of Islam: each party, he argued, put its views in the Prophet’s mouth, and pious men forged in good conscience for causes they thought right.")),
            .shortOnly(.text("Ignaz Goldziher (1850–1921), a Hungarian Jewish scholar who had studied at al-Azhar as a young man, argued in his Muhammedanische Studien (1890) that the great mass of hadith does not record the Prophet’s time but mirrors the religious, political and legal struggles of the first two centuries of Islam, each party putting its views in the Prophet’s mouth.")),
            .text("Goldziher used the Muslim critics’ own lists of forgers as evidence. But that evidence cuts both ways: the critics could expose forgeries only because they had standards that forgeries failed, and the forgeries they exposed are exactly the reports the Sunnah never relied on."),
            .longOnly(.text("His best-known example concerns Ibn Shihaab az-Zuhri (may Allah have mercy on him), the great Madinan scholar who died in 124 AH. Goldziher claimed that the Umayyad caliph Abd al-Malik, while Abdullah ibn az-Zubayr (may Allah be pleased with him) held Makkah, had az-Zuhri spread the hadith on the three mosques so that pilgrims would go to Jerusalem instead. Mustafa as-Sibaa‘i (1915–1964) answered him in as-Sunnah wa Makaanatuha fit-Tashree‘ al-Islaami, and al-A‘zami, Nabia Abbott and Harald Motzki also rejected the story. The answers are checkable:")),
            .longOnly(.step("1. **The source.** The story comes from al-Ya‘qoobi, a Shia historian of the third century hostile to the Umayyads, not from the hadith literature.")),
            .longOnly(.step("2. **The dates.** Az-Zuhri was then a young man without standing, and his own association with Abd al-Malik is reported from around 82 AH, years after Ibn az-Zubayr was killed in 73 AH.")),
            .longOnly(.step("3. **The other routes.** The hadith does not depend on az-Zuhri. Al-Bukhaari and Muslim both have it from Abu Sa‘eed al-Khudri (may Allah be pleased with him) through Qaza‘ah, and Muslim from Abu Hurayrah (may Allah be pleased with him) through Salmaan al-Agharr (Saheeh Muslim 1397), none of them through az-Zuhri.")),
            .longOnly(.hadith("muslim:1397c", cite: "Saheeh Muslim 1397", arabic: 38...47, english: [0...20])),
            .longOnly(.text("In Qaza‘ah’s version the Successor even asks the Companion whether he heard it himself:")),
            .longOnly(.hadith("muslim:827d", cite: "Saheeh Muslim 827, Saheeh al-Bukhaari 1197", arabic: 30...81, english: [0...88])),
            .longOnly(.step("4. **The text.** It names the Sacred Mosque among the three and says nothing about replacing the Hajj, which the Quran ties to the House in Makkah (3:97).")),
            .longOnly(.ayah("3:97", words: 9...17)),
            .longOnly(.text("Goldziher also read a saying of az-Zuhri, that the rulers had compelled the scholars, as a confession of forgery. The report as Ibn Sa‘d and al-Khateeb al-Baghdaadi give it says that the scholars had disliked writing knowledge down until the rulers pressed them to, and that they then resolved not to withhold it from any Muslim. It is a statement about writing hadith down, which is exactly what the caliph Umar ibn Abd al-Azeez (may Allah have mercy on him) had ordered.")),
            .door(.article("HadithPreservationView")),
        ]),
        ArticleSection("SCHACHT: THE LAWYER'S CASE", [
            .longOnly(.text("Joseph Schacht (1902–1969), a German scholar of Islamic law who later taught at Oxford, Leiden and Columbia, published The Origins of Muhammadan Jurisprudence (Oxford, 1950). He studied the legal works of the second century, the Muwatta’ of Maalik and the writings of ash-Shaafi‘i above all, and drew four conclusions:")),
            .longOnly(.step("1. **Late origin.** Legal hadith from the Prophet mostly came into circulation in the second century, in the generation before ash-Shaafi‘i, as the schools of law projected their own “living tradition” back onto him. Every such tradition, he wrote, should be taken, until the contrary is proved, as “the fictitious expression of a legal doctrine formulated at a later date” (p. 149).")),
            .longOnly(.step("2. **Chains that grew backwards.** A doctrine was first attributed to a Successor, then to a Companion, and finally to the Prophet, the chain growing longer and more impressive over time.")),
            .longOnly(.step("3. **The common link.** Where the chains of one hadith converge on a single narrator of the second century, that narrator is the likely point at which the report was put into circulation.")),
            .longOnly(.step("4. **The argument from silence.** In his words, the best way of proving that a tradition did not exist at a certain time is to show that it was not used in a discussion that would have made reference to it imperative (p. 140).")),
            .shortOnly(.text("Joseph Schacht (1902–1969), in The Origins of Muhammadan Jurisprudence (Oxford, 1950), argued from the legal works of the second century that legal hadith were mostly put into circulation then, their chains growing backwards from a Successor to a Companion to the Prophet; that the narrator on whom a hadith’s chains converge, its “common link,” was where it began; and that a report not cited where an argument needed it did not yet exist.")),
            .text("Schacht’s book shaped Western study of Islamic law for half a century. His critics found its weakness in its foundations: it drew mostly on works of law, not on the hadith collections, and it treated the absence of a report from an argument as proof that the report did not exist."),
        ]),
        ArticleSection("JUYNBOLL AND THE COMMON LINK", [
            .longOnly(.text("The Dutch scholar G. H. A. Juynboll (1935–2010) built Schacht’s common link into a method. In Muslim Tradition (Cambridge, 1983) and later in his Encyclopedia of Canonical Hadith (Leiden, 2007), he drew the chains of each hadith as a bundle and identified the narrator where they converge as its probable originator. Single strands that reached past the common link to earlier authorities he treated as later inventions.")),
            .longOnly(.text("Pushed to its end, the method doubted even figures every biographer of the period knows. In an article in Der Islam (1993), Juynboll questioned whether Naafi‘, the freedman of Abdullah ibn Umar and teacher of Maalik, had been a historical person at all. Harald Motzki replied at length in the same journal (1996), defending Naafi‘ as a real teacher and criticising the method that had led to the doubt.")),
            .longOnly(.markdown("The muhaddithoon knew the phenomenon long before Schacht. They called the narrator on whom the routes of a report converge its **madaar (مَدَار)**, its pivot, and said “this hadith turns on so-and-so.” They knew too that a report could be singular at one level, and that a Companion’s own words could be mistakenly raised to the Prophet; whole books of hidden defects decide, case by case, whether the raised or the stopped version is right. The difference lies in the question. The critic asks whether the man at the pivot was trustworthy and precise. The sceptic assumes that the man at the pivot made it up.")),
            .shortOnly(.text("The Dutch scholar G. H. A. Juynboll (1935–2010) built Schacht’s common link into a method, treating the narrator where a hadith’s chains converge as its probable originator.")),
            .shortOnly(.markdown("The muhaddithoon knew the phenomenon long before Schacht. They called the narrator on whom the routes of a report converge its **madaar (مَدَار)**, its pivot, and said “this hadith turns on so-and-so.” The difference lies in the question. The critic asks whether the man at the pivot was trustworthy and precise. The sceptic assumes that the man at the pivot made it up.")),
        ]),
        ArticleSection("THE ANSWER FROM THE SOURCES", [
            .longOnly(.text("Muhammad Mustafa al-A‘zami (1930–2017), born in India and trained at al-Azhar and Cambridge, wrote the most thorough replies. His Cambridge thesis, published as Studies in Early Hadith Literature (1968), gathered the evidence for written collections kept by Companions and Successors, and he received the King Faisal International Prize for Islamic Studies in 1980. In On Schacht’s Origins of Muhammadan Jurisprudence (Riyadh, 1985) he went through Schacht’s own examples. His main points:")),
            .shortOnly(.text("Muhammad Mustafa al-A‘zami (1930–2017), trained at al-Azhar and Cambridge, wrote the most thorough replies: he gathered the evidence for written collections kept by Companions and Successors, and went through Schacht’s own examples. His main points:")),
            .bullet("**The wrong books.** Works of law cite only what an argument needs. Ash-Shaafi‘i himself wrote in ar-Risaalah that no single scholar knows the whole Sunnah, though the scholars together do, so a jurist’s silence about a hadith proves nothing about its existence."),
            .bullet("**The common link explained.** In the second century the number of students multiplied, and a teacher with many students is exactly where the routes of his hadiths will meet. The pivot is the natural shape of teaching, not a sign of forgery."),
            .longOnly(.bullet("**Chains read in full.** Followed through all their routes, many of the chains Schacht cited spread across cities and generations in ways that no single forger could have arranged.")),
            .longOnly(.bullet("**Wording that agrees.** In a study of the notebook of hadith that Suhayl ibn Abi Saalih (d. 138 AH) received from his father from Abu Hurayrah, he traced its reports through students in distant cities whose versions largely agree, which a forger in one place could not have produced.")),
            .longOnly(.text("Others answered in Arabic for a Muslim readership. As-Sibaa‘i’s book, written as his al-Azhar doctorate, took up Goldziher point by point, and the Yemeni scholar Abd ar-Rahman al-Mu‘allimi (d. 1386 AH) wrote al-Anwaar al-Kaashifah against Mahmood Abu Rayyah, an Egyptian writer who had brought the orientalists’ doubts, and their attack on Abu Hurayrah (may Allah be pleased with him), into Arabic in 1958.")),
            .door(.article("CompanionAbuHurayrahView")),
        ]),
        ArticleSection("THE ANSWER FROM THE DOCUMENTS", [
            .text("The second answer came from manuscripts and papyri, which can be dated independently of any chain."),
            .longOnly(.markdown("**Fuat Sezgin (1924–2018),** the Turkish historian of Arabic science and letters, argued in his study of al-Bukhaari’s sources (Istanbul, 1956) that al-Bukhaari drew on written books whose authors appear in his chains, and that the terms of transmission often refer to the use of such books. The first volume of his Geschichte des arabischen Schrifttums (1967) catalogued the surviving early works.")),
            .longOnly(.markdown("**Nabia Abbott (1897–1981),** a papyrologist at the Oriental Institute of the University of Chicago, published early hadith papyri in Studies in Arabic Literary Papyri II: Quranic Commentary and Tradition (1967). She concluded that hadith were transmitted in writing continuously from the earliest period, and that the vast growth in the number of hadiths in the later collections was mostly a growth in the number of chains, as each generation of students multiplied the routes of the same texts, not a growth in the texts themselves.")),
            .shortOnly(.text("Fuat Sezgin showed that al-Bukhaari drew on written books whose authors appear in his chains, and Nabia Abbott, from early papyri, that hadith were written down continuously from the earliest period.")),
            .markdown("**The Saheefah of Hammaam ibn Munabbih** is the plainest witness. Hammaam wrote it from Abu Hurayrah (may Allah be pleased with him), who died around 58 AH, so the collection was in writing within the first half century after the Prophet. Its hadiths reached al-Bukhaari and Muslim through Ma‘mar and his students, and they match the surviving manuscripts of the Saheefah. One of them is a hadith qudsi:"),
            .hadith("bukhari:7498", cite: "Saheeh al-Bukhaari 7498", arabic: 30...46, english: [4...35]),
            .text("Its chain in al-Bukhaari runs through Abdullah ibn al-Mubaarak from Ma‘mar from Hammaam from Abu Hurayrah. A text written in the first century, quoted word for word in the third, is the opposite of a chain that grew backwards."),
        ]),
        ArticleSection("THE ANSWER FROM THEIR OWN METHOD", [
            .longOnly(.text("The most telling replies came from Western scholars who accepted the historian’s rules and applied them more carefully.")),
            .longOnly(.markdown("**Harald Motzki (1948–2019)** studied the Musannaf of Abd ar-Razzaaq of San‘a (d. 211 AH) in Die Anfänge der islamischen Jurisprudenz (1991), translated as The Origins of Islamic Jurisprudence: Meccan Fiqh before the Classical Schools (2002). He found that the material Abd ar-Razzaaq received from Ibn Jurayj (d. 150 AH) has a profile no forger had reason to create: Ibn Jurayj separates what he heard from his teacher Ataa’ ibn Abi Rabaah from his own opinions, records Ata’s hesitations and changes of mind, and draws on his various sources in proportions that look like real transmission, not invention. Motzki concluded that this material genuinely reaches back to Ataa’, who taught in Makkah in the late first century.")),
            .longOnly(.markdown("Motzki also refined a method called **isnaad-cum-matn analysis**: comparing all the versions of a report together with their chains. If the small differences in wording follow the branches of the chain, so that the students of one teacher share his variants, then the report really passed down those branches, and the common link is at least the man who taught it, not a forger who invented it.")),
            .longOnly(.markdown("**Gregor Schoeler (b. 1944),** of the University of Basel, showed in The Oral and the Written in Early Islam and The Genesis of Literature in Islam that the supposed choice between memory and writing is false: early scholars kept written notes for teaching and taught from them aloud, long before books were published in the later sense. Applying the same comparative method to the account of the beginning of revelation (Saheeh al-Bukhaari 3), he traced it back to Urwah ibn az-Zubayr (d. 94 AH), the nephew of Aa’ishah (may Allah be pleased with her), from whom it is narrated.")),
            .longOnly(.hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 20...68, english: [0...61])),
            .longOnly(.text("These scholars did not become advocates of the Muslim view, and they were cautious about what history alone can prove. But their findings dismantled the central claim of Schacht’s school: that the chains as a whole are a late fiction and that nothing can be traced into the first century.")),
            .shortOnly(.text("The most telling replies came from Western scholars who applied the historians’ rules more carefully. Harald Motzki (1948–2019) showed that the material Abd ar-Razzaaq received from Ibn Jurayj has a profile no forger had reason to create, and traced it to Ataa’ ibn Abi Rabaah, who taught in Makkah in the late first century. Gregor Schoeler traced the account of the beginning of revelation in the same way to Urwah ibn az-Zubayr (d. 94 AH). These scholars did not become advocates of the Muslim view, but their findings dismantled the claim that nothing can be traced into the first century.")),
        ]),
        ArticleSection("WHAT THE DEBATE SHOWS", [
            .text("A century of argument leaves a few clear lessons."),
            .step("1. **The critics were there first.** Forgery, singular reports, the pivot of a chain, a Companion’s words raised to the Prophet: every phenomenon the sceptics built a theory on had been named, studied and judged by the muhaddithoon, report by report."),
            .step("2. **Assumptions decide much.** If prophethood is ruled out and every chain presumed false until proven true, very little can ever be proven. Schacht’s rule that each legal tradition is fictitious “until the contrary is proved” is a starting assumption, not a finding."),
            .step("3. **The evidence moved one way.** Each new document and each more careful method pushed the dates earlier: to Hammaam’s Saheefah, to Ataa’ in Makkah, to Urwah in Madinah."),
            .step("4. **The Sunnah does not wait on Western approval.** Muslims accept a sound report because of the science that tested it, which the Salaf held to be proof in belief and in law, not because a historian has dated it."),
            .door(.article("HadithScienceAhadView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Were the orientalists simply enemies of Islam?**"),
            .text("Some wrote with hostility and some with real respect, and many were superb philologists whose editions Muslims still use. The fairest judgment is on their arguments, not their motives, and their arguments rested on assumptions a Muslim does not share and on evidence that later research has overturned. Islam asks for justice even toward those one disagrees with (5:8)."),
            .ayah("5:8", words: 8...18),
            .markdown("**Do Western scholars now accept the hadith as authentic?**"),
            .text("There is no consensus. Some still follow Schacht closely; others, following Motzki and Schoeler, date a great deal of material to the first century and treat the chains as real evidence. Few hold Goldziher’s view in its old form. But the Muslim’s confidence never rested on their verdict: it rests on the Quran’s command to obey the Messenger and on the science that kept his words."),
            .markdown("**Does any of this touch the Quran?**"),
            .text("The Quran was transmitted differently: by mass recitation and in writing from the start, and its preservation has its own library. Some revisionist writers have made parallel claims about it, and they are answered there."),
            .door(.article("PreservationClaimsView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Goldziher saw in the hadith a mirror of later struggles, Schacht a projection of second-century law, and Juynboll the work of the men at the pivot of each chain. Their case rested on legal books that cite only what they need, on silence read as absence, and on the assumption that a chain is false until proven true. Al-A‘zami and as-Sibaa‘i answered from the sources, Sezgin and Abbott from the documents, and Motzki and Schoeler from a stricter use of the historians’ own method, and the Saheefah of Hammaam ibn Munabbih stands as written proof from the first century. The muhaddithoon had already named and weighed every phenomenon the sceptics relied on, and their science stands."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Mustashriq", arabic: "مُستَشرِق", meaning: "An **orientalist**: a Western scholar of the languages, religions and history of the East, plural mustashriqoon. Used of the European tradition of Islamic studies from the eighteenth century on."),
            .term("Madaar", arabic: "مَدَار", meaning: "The **pivot** of a hadith: the narrator on whom its routes converge, as the critics said, “this hadith turns on so-and-so.” Schacht called the same point the common link."),
            .term("Raf‘ and Waqf", arabic: "الرَّفع وَالوَقف", meaning: "**Raising** a report to the Prophet ﷺ and **stopping** it at a Companion. When narrators differ on this, the critics decide which is correct, case by case: the phenomenon Schacht called backward growth."),
            .term("Isnaad-cum-Matn", arabic: "الإِسنَاد وَالمَتن", meaning: "A modern **comparative method**: studying a report’s chains and its wording together, so that the variants of the text can show whether the transmission along each branch was real."),
        ]),
    ]
}
