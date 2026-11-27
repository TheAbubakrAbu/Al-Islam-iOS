import SwiftUI

// Sahabah, Ahlul Bayt & Salaf: the Companions, the Prophet's household and the generations after them.
// Written 2026-11-24 (Abu: "Add these new Islamic resources"), Sunni upon the way of the Salaf, and held
// to the app's rules: every ayah a `.ayah(` reference into the bundled Quran, every hadith a `.hadith(`
// reference into the bundled shelf graded sahih or hasan, scholars' words quoted only with their source.
// The chapters are catalog articles (`IslamArticleCatalog`, home `.companions`), drawn by
// IslamLibraryView, so search, the Ask AI corpus and each page's own search reach them.

// MARK: - companions-1

struct CompanionsIntroView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionsIntroView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Who Are the Sahaabah?")
        .englishArticle().selectableArticleList(article: "CompanionsIntroView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a Companion (Sahaabi) is anyone who met the Prophet Muhammad (peace and blessings be upon him) believing in him and died a Muslim. Allah praised them in the Quran while they lived and declared Himself pleased with them, and the Prophet called his generation the best of people. They differ in rank, were not free of sin, and some fought one another; yet Ahl as-Sunnah hold all of them upright, withhold from their disputes, and take the religion as they understood it, because it reached the world through them."),
        ]),
        ArticleSection("WHO COUNTS AS A COMPANION", [
            .markdown("The word **Sahaabi (صَحَابِيّ)** comes from **suhbah**, keeping someone’s company. The scholars of hadith needed something exact, because a whole branch of their science depends on knowing who saw the Prophet (peace be upon him) and who only heard of him. The definition they settled on is the one Ibn Hajar al-Asqalaani (may Allah have mercy on him, d. 852 AH) gives at the opening of **al-Isaabah fi Tamyeez as-Sahaabah**, his encyclopaedia of the Companions:"),
            .quote(text: "“The soundest definition I have come across is that a Companion is one who met the Prophet (peace be upon him) believing in him, and died upon Islam.” (Ibn Hajar, al-Isaabah fi Tamyeez as-Sahaabah, introduction).", arabic: "وَأَصَحُّ مَا وَقَفتُ عَلَيهِ مِن ذَلِكَ أَنَّ الصَّحَابِيَّ مَن لَقِيَ النَّبِيَّ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ مُؤمِنًا بِهِ، وَمَاتَ عَلَى الإِسلَامِ", dimmed: true),
            .shortOnly(.text("It says met, not saw, so that the blind man of Surah Abasa is a Companion, and it says nothing about how long, so that a man who sat with him once and a man who lived beside him for twenty years both carry the name, though not the same rank. “Believing in him” excludes the man who met him as a disbeliever; “died upon Islam” excludes the one who left the religion for good.")),
            .longOnly(.text("It says met, not saw, so that Ibn Umm Maktoom (may Allah be pleased with him), the blind man of Surah Abasa (80:1-2), is a Companion. It says nothing about how long, so that a man who sat with him once and a man who lived beside him for twenty years both carry the name, though not the same rank. Mahmood ibn ar-Rabee‘ (may Allah be pleased with him) was a boy of five when the Prophet took water from a bucket in his mouth and playfully sprayed it on his face, and he remembered it all his life (Saheeh al-Bukhaari 77); he is counted among them.")),
            .longOnly(.ayah("80:1-2")),
            .longOnly(.hadith("bukhari:77", cite: "Saheeh al-Bukhaari 77", arabic: 22...38, english: [0...33])),
            .longOnly(.text("“Believing in him” excludes the man who met him as a disbeliever, even if he accepted Islam after the Prophet died. “Died upon Islam” excludes the one who left the religion for good: Ubaydullah ibn Jahsh emigrated to Abyssinia as a Muslim and died there a Christian. A man who turned back and then returned keeps the name; al-Ash‘ath ibn Qays (may Allah be pleased with him) apostatised after the Prophet’s death and came back to Islam under Abu Bakr, and Ibn Hajar gives him as the example.")),
            .longOnly(.text("A man is known to be a Companion by mass report, by fame among the early Muslims, by another Companion’s testimony, or by his own word if he is truthful and the claim is possible in time. The Prophet set that limit himself: near the end of his life he told those at the night prayer that no one then alive on earth would remain after a hundred years (Saheeh al-Bukhaari 116). The last was Abu at-Tufayl Aamir ibn Waathilah (may Allah be pleased with him), who said in old age that no one left on earth had seen the Prophet but him; Imam Muslim dates his death to 100 AH (Saheeh Muslim 2340). Any later claim was rejected outright.")),
            .longOnly(.hadith("bukhari:116", cite: "Saheeh al-Bukhaari 116", arabic: 48...63, english: [27...56])),
            .longOnly(.hadith("muslim:2340a", cite: "Saheeh Muslim 2340", arabic: 15...51, english: [0...39])),
        ]),
        ArticleSection("WHAT THE QURAN SAYS OF THEM", [
            .text("The Quran does not praise the Companions as a distant ideal. It names them in groups, describes what they did, and announces Allah’s pleasure with them while they lived, from the One who knew what each would do afterwards."),
            .ayah("9:100", words: 8...12),
            .text("Three groups are named: the forerunners of the Muhaajiroon, who emigrated from Makkah; the forerunners of the Ansaar, the people of Madinah who took them in; and those who follow them with excellence, the door left open to every Muslim after them."),
            .ayah("48:18"),
            .text("This is the Pledge of Ridwaan at al-Hudaybiyah in 6 AH, given under a tree when word came that Uthmaan (may Allah be pleased with him) had been killed in Makkah. About fourteen hundred men took it, and the Prophet (peace be upon him) told them that day, “You are the best people on the earth” (Saheeh al-Bukhaari 4154). A pleasure announced by the Knower of hearts cannot be cancelled by an event He already knew was coming."),
            .hadith("bukhari:4154", cite: "Saheeh al-Bukhaari 4154", arabic: 17...36, english: [0...22]),
            .longOnly(.ayah("48:29", words: 41...43)),
            .longOnly(.text("Here they are described as the Torah and the Gospel describe them: a crop that grows strong and delights the sower. Ibn Katheer (may Allah have mercy on him) records under this ayah that Imam Maalik (may Allah have mercy on him) drew a severe judgment from “so that Allah may enrage by them the disbelievers”: rage at the Companions is the feeling the ayah gives to the disbelievers, not to a believer.")),
            .longOnly(.ayah("59:8-10")),
            .longOnly(.text("These aayaat divide the whole ummah into three ranks. The Muhaajiroon are called the truthful, the Ansaar the successful, and everyone who comes after has a single description: he asks forgiveness for those who preceded him and asks Allah to keep his heart clean of resentment toward them. Ibn Katheer notes that Maalik drew from this that the one who reviles the Companions has no share in the fay’ the aayaat distribute, since he lacks the one quality given to those who came later. Aa’ishah (may Allah be pleased with her) saw the irony in her own lifetime:")),
            .longOnly(.hadith("muslim:3022a", cite: "Saheeh Muslim 3022", arabic: 17...29, english: [0...23])),
        ]),
        ArticleSection("THE BEST GENERATION", [
            .text("The Prophet (peace be upon him) ranked the generations of his ummah himself, and he put his own first:"),
            .hadith("bukhari:2652", cite: "Saheeh al-Bukhaari 2652", arabic: 29...37, english: [4...23]),
            .markdown("A **qarn (قَرن)** is a generation. His is the Companions; those who followed them are the **Taabi‘oon**, the Successors; and those who followed them are the **Atbaa‘ at-Taabi‘een**. These three generations are what the scholars mean by **the Salaf**, the predecessors whose understanding the later ummah follows."),
            .longOnly(.text("He also described what the Companions were for the ummah, in an image drawn from the night sky. Abu Moosa al-Ash‘ari (may Allah be pleased with him) narrates that the Prophet raised his head to the sky and said:")),
            .longOnly(.hadith("muslim:2531", cite: "Saheeh Muslim 2531", arabic: 109...137, english: [106...206])),
            .longOnly(.text("While the Prophet lived, his Companions were kept from the trials that followed him; while the Companions lived, the ummah was kept from the innovations that spread once they were gone, and the sects grew strong as the last of them died.")),
            .text("And he forbade reviling them in words that measure the distance between them and everyone after:"),
            .hadith("bukhari:3673", cite: "Saheeh al-Bukhaari 3673, Saheeh Muslim 2540", arabic: 31...46, english: [4...40]),
            .shortOnly(.text("A mudd is what two cupped hands can hold. The difference is the moment: they gave when Islam was weak, with the Prophet among them, and nothing given later catches up.")),
            .longOnly(.text("A mudd is what two cupped hands can hold. The difference is the moment: they gave when Islam was weak, with the Prophet among them, and nothing given later catches up. Saheeh Muslim preserves the occasion. Words had passed between Khaalid ibn al-Waleed and Abd ar-Rahman ibn Awf (may Allah be pleased with them), and Khaalid spoke harshly to him:")),
            .longOnly(.hadith("muslim:2541a", cite: "Saheeh Muslim 2541", arabic: 38...55, english: [0...35])),
            .longOnly(.text("Khaalid was himself a Companion, the Sword of Allah, but he had accepted Islam shortly before the conquest of Makkah; Abd ar-Rahman was among the first eight believers. If the earlier Companion’s honour was guarded from a later Companion’s tongue, it is guarded far more from someone born centuries later.")),
        ]),
        ArticleSection("NOT ALL OF EQUAL RANK", [
            .text("Loving them all does not mean ranking them all the same. The Quran itself draws the line:"),
            .ayah("57:10", words: 11...32),
            .text("The scholars of the Sunnah, Ibn Taymiyyah (may Allah have mercy on him) among them in al-Aqeedah al-Waasitiyyah, set out the ranks the evidence gives, roughly in this order:"),
            .shortOnly(.text("First the four caliphs in the order of their caliphate, Abu Bakr, Umar, Uthmaan and Ali; then the rest of the ten promised Paradise by name; then the people of Badr; then the people of the Pledge of Ridwaan under the tree; then those who spent and fought before the conquest, and after them those who came later. In general the Muhaajiroon come before the Ansaar, as Allah names them first.")),
            .longOnly(.step("1. **The four caliphs, in the order of their caliphate.** Ibn Umar (may Allah be pleased with him) said that in the Prophet’s lifetime they ranked Abu Bakr first, then Umar, then Uthmaan (Saheeh al-Bukhaari 3655), and Ali himself named Abu Bakr and then Umar as the best after the Prophet (Saheeh al-Bukhaari 3671).")),
            .longOnly(.hadith("bukhari:3655", cite: "Saheeh al-Bukhaari 3655", arabic: 23...44, english: [0...31])),
            .longOnly(.hadith("bukhari:3671", cite: "Saheeh al-Bukhaari 3671", arabic: 19...53, english: [0...49])),
            .longOnly(.step("2. **The rest of the ten promised Paradise by name** in a single hadith: Talhah, az-Zubayr, Abd ar-Rahman ibn Awf, Sa‘d ibn Abi Waqqaas, Sa‘eed ibn Zayd and Abu Ubaydah ibn al-Jarraah, may Allah be pleased with them all (Jaami‘ at-Tirmidhi 3747).")),
            .longOnly(.hadith("tirmidhi:3747", cite: "Jaami‘ at-Tirmidhi 3747; graded saheeh by al-Albaani", arabic: 30...66, english: [7...58])),
            .longOnly(.step("3. **The people of Badr**, a little over three hundred men. Jibreel asked the Prophet how they counted the people of Badr among them, and he said, “As the best of the Muslims” (Saheeh al-Bukhaari 3992).")),
            .longOnly(.hadith("bukhari:3992", cite: "Saheeh al-Bukhaari 3992", arabic: 27...50, english: [7...40])),
            .longOnly(.step("4. **The people of the Pledge of Ridwaan** under the tree, the fourteen hundred of 48:18.")),
            .longOnly(.step("5. **Those who spent and fought before the conquest**, then those after it (57:10). Some of the Salaf, ash-Sha‘bi among them, and Ibn Taymiyyah after them, took the conquest here to be the truce of al-Hudaybiyah, which the Quran calls a clear opening (48:1); others took it to be the conquest of Makkah. In general the Muhaajiroon come before the Ansaar, as Allah names them first (9:100, 9:117).")),
            .longOnly(.ayah("48:1")),
            .longOnly(.ayah("9:117", words: 0...8)),
            .door(.article("CompanionTenView")),
            .longOnly(.text("The rank of Badr shows in a story that could have ended in an execution. Before the conquest of Makkah, Haatib ibn Abi Balta‘ah (may Allah be pleased with him) secretly wrote to warn Quraysh that the Prophet was coming, hoping they would protect his family in return. The letter was intercepted; Haatib said he had acted from fear for his family, not from disbelief, and Umar asked to strike the neck of “this hypocrite.” The Prophet answered:")),
            .longOnly(.hadith("bukhari:3007", cite: "Saheeh al-Bukhaari 3007", arabic: 210...231, english: [261...290])),
            .longOnly(.text("Haatib’s act was a real wrong, and the opening of Surat al-Mumtahanah came down about it; but it was weighed against Badr, and no one was allowed to call a man of Badr a hypocrite. Of the people of the tree the Prophet said:")),
            .longOnly(.hadith("muslim:2496", cite: "Saheeh Muslim 2496", arabic: 37...50, english: [0...21])),
            .longOnly(.text("Ibn Hazm (may Allah have mercy on him) joined “to all Allah has promised the best” (57:10) to 21:101: those for whom the best has gone before are kept far from the Fire. Every Companion who spent and fought is inside that promise.")),
        ]),
        ArticleSection("UPRIGHT, NOT INFALLIBLE", [
            .longOnly(.markdown("**Adaalah (عَدَالَة)**, uprightness, is a term of the hadith scholars: an upright narrator is one whose religion and character can be trusted not to lie. For every narrator after the Companions it must be established name by name. For the Companions it is settled by the praise of Allah and His Messenger; al-Khateeb al-Baghdaadi (may Allah have mercy on him) gives a chapter of al-Kifaayah to it, and Ibn Hajar reports in al-Isaabah that Ahl as-Sunnah agree on it, with only innovators dissenting. So when a chain reaches “a man from the Companions of the Prophet” left unnamed, it is not weakened: whichever Companion it was, he is trusted.")),
            .shortOnly(.markdown("**Adaalah (عَدَالَة)**, uprightness, is a term of the hadith scholars: an upright narrator is one whose religion and character can be trusted not to lie. For every narrator after the Companions it must be established name by name; for the Companions it is settled by the praise of Allah and His Messenger, so a chain that reaches a Companion left unnamed is not weakened.")),
            .text("Uprightness is not infallibility; only the prophets are protected from sin. The Quran records the Companions’ slips: some left their posts at Uhud, a few joined in spreading the slander against Aa’ishah, and three stayed behind from Tabook with no excuse. Each time it records the forgiveness too. Of the three it says:"),
            .ayah("9:118"),
            .longOnly(.text("Ka‘b ibn Maalik (may Allah be pleased with him), one of the three, told the whole story himself without sparing himself, and it is in Saheeh al-Bukhaari. A community that preserved its own failures this honestly did not invent its virtues.")),
            .longOnly(.text("Ibn Taymiyyah states the creed precisely in al-Aqeedah al-Waasitiyyah: Ahl as-Sunnah do not believe every Companion was protected from sins, major or minor, but their precedence and merits bring them forgiveness that those after them would not receive. Whatever wrong a Companion did, he explains, was erased in one of several ways: he repented; or he had good deeds that wiped it out; or he was forgiven for his precedence; or through the intercession of Muhammad (peace be upon him), which they deserve more than anyone; or he was tried in this world with something that expiated it.")),
            .callout("Love for the Companions is not the claim that none of them ever erred. It is the refusal to make their errors the measure of them, when Allah and His Messenger have already given the measure.", title: "The Balance", icon: "scale.3d"),
        ]),
        ArticleSection("WHAT BROKE OUT BETWEEN THEM", [
            .longOnly(.text("The hardest part of their history began with a crime committed by others. In 35 AH rebels from Egypt, Koofah and Basrah besieged the caliph Uthmaan (may Allah be pleased with him) in his house and killed him, and Ali (may Allah be pleased with him) was given the pledge. Aa’ishah, Talhah and az-Zubayr (may Allah be pleased with them) went to Basrah to seek retribution for Uthmaan’s blood, and in 36 AH the two sides met at the Battle of the Camel, which by the historians’ accounts neither leadership intended. Mu‘aawiyah (may Allah be pleased with him) and the people of Syria withheld their pledge until Uthmaan’s killers were handed over, and in 37 AH they fought Ali’s army at Siffeen.")),
            .longOnly(.text("Neither side fought for the world, and neither fought to overturn the religion. Both claimed to be seeking what Allah commanded in the matter of Uthmaan’s blood, and the Quran had already given a name to believers who fight each other:")),
            .longOnly(.ayah("49:9", words: 0...4)),
            .longOnly(.text("The Prophet (peace be upon him) also foretold it, and in his words both sides are Muslims, with one of them nearer to the truth:")),
            .shortOnly(.text("The hardest part of their history began with a crime committed by others. In 35 AH rebels besieged the caliph Uthmaan (may Allah be pleased with him) in his house and killed him, and Ali (may Allah be pleased with him) was given the pledge. Aa’ishah, Talhah and az-Zubayr went to Basrah to seek retribution for Uthmaan’s blood, and in 36 AH the two sides met at the Battle of the Camel; Mu‘aawiyah and the people of Syria withheld their pledge until Uthmaan’s killers were handed over, and in 37 AH they fought Ali’s army at Siffeen. Neither side fought for the world: both claimed to be seeking what Allah commanded in the matter of Uthmaan’s blood.")),
            .shortOnly(.text("The Prophet (peace be upon him) foretold it, and in his words both sides are Muslims, with one of them nearer to the truth:")),
            .hadith("muslim:1065b", cite: "Saheeh Muslim 1065", arabic: 29...38, english: [0...29]),
            .text("The group that split off were the Khawaarij, and the army that fought them at an-Nahrawaan was Ali’s. So Ali was nearer to the truth, and those who opposed him were not outside it. Ali was the rightful caliph; those who fought him were mujtahids who erred; and the Prophet’s rule for the one who strives for the right judgment covers both:"),
            .hadith("bukhari:7352", cite: "Saheeh al-Bukhaari 7352", arabic: 46...60, english: [7...71]),
            .shortOnly(.text("Many of the senior Companions kept out of the fighting altogether. The stance of Ahl as-Sunnah, as Ibn Taymiyyah wrote it into their creed, is to withhold from what broke out between the Companions: some of the reports of their faults are lies, some have been changed from their true form, and in what is authentic they are excused, either mujtahids who were right or mujtahids who erred. Withholding is not pretending nothing happened; it means not digging into it to find someone to revile.")),
            .longOnly(.text("Many of the senior Companions kept out of the fighting altogether, among them Sa‘d ibn Abi Waqqaas, Abdullah ibn Umar, Muhammad ibn Maslamah and Usaamah ibn Zayd (may Allah be pleased with them). The stance of the later ummah is the one Ibn Taymiyyah wrote into its creed:")),
            .longOnly(.quote(text: "“They withhold from what broke out between the Companions, and they say that of the reports narrated about their faults, some are lies, some have been added to, cut short and changed from their true form, and in what is authentic of them they are excused: either mujtahids who were right, or mujtahids who erred.” (Ibn Taymiyyah, al-Aqeedah al-Waasitiyyah).", arabic: "وَيُمسِكُونَ عَمَّا شَجَرَ بَينَ الصَّحَابَةِ، وَيَقُولُونَ: إِنَّ هَذِهِ الآثَارَ المَروِيَّةَ فِي مَسَاوِيهِم مِنهَا مَا هُوَ كَذِبٌ، وَمِنهَا مَا قَد زِيدَ فِيهِ وَنُقِصَ وَغُيِّرَ عَن وَجهِهِ، وَالصَّحِيحُ مِنهُ هُم فِيهِ مَعذُورُونَ: إِمَّا مُجتَهِدُونَ مُصِيبُونَ، وَإِمَّا مُجتَهِدُونَ مُخطِئُونَ", dimmed: true)),
            .longOnly(.text("Withholding is not pretending nothing happened, and it does not stop the scholar from studying it. It means not digging into it to find someone to revile, and not letting a dispute settled before Allah long ago become the resentment that 59:10 asks Allah to remove. Many of the stories told about these years come through storytellers such as Abu Mikhnaf, whom the critics of hadith rejected: the first kind Ibn Taymiyyah names.")),
        ]),
        ArticleSection("THE CHARGE THAT THEY TURNED BACK", [
            .shortOnly(.text("The Twelver Shia hold that after the Prophet’s death nearly all the Companions turned back from the truth by giving their pledge to Abu Bakr instead of Ali. The Quran cannot be made false: Allah declared Himself pleased with the Muhaajiroon and the Ansaar and promised them gardens forever (9:100), knowing what they would do, and had they turned back as a body that promise would be untrue. And the claim destroys its own foundation: the Quran was gathered, written and taught by these very men, and the Sunnah narrated by them. Discredit the witnesses and nothing they carried can be trusted.")),
            .longOnly(.text("The Twelver Shia hold that after the Prophet’s death nearly all the Companions turned back from the truth by giving their pledge to Abu Bakr instead of Ali (may Allah be pleased with them both), and narrations in their classical books, al-Kulayni’s al-Kaafi among them, say that only three remained firm. Put at its strongest, the claim rests on a sound hadith that Ahl as-Sunnah narrate themselves:")),
            .longOnly(.hadith("bukhari:4625", cite: "Saheeh al-Bukhaari 4625", arabic: 73...118, english: [70...175])),
            .longOnly(.text("The hadith is sound, and it does not say what the claim needs it to say.")),
            .longOnly(.step("1. **Its own words limit it.** It speaks of “men from my ummah,” and in the Arabic the Prophet (peace be upon him) says **usayhaabi**, the diminutive, “my little companions,” which the commentators take as pointing to a few who had been around him, not the men of Badr and the tree.")),
            .longOnly(.step("2. **Its description fits a known group.** Right after the Prophet’s death whole tribes apostatised, followed false prophets or refused the zakaah, and the Companions under Abu Bakr fought them. Al-Khattaabi, an-Nawawi and Ibn Hajar explain the hadith as referring to them and to the hypocrites. It cannot describe the very men who fought those apostates.")),
            .longOnly(.step("3. **The Quran cannot be made false.** Allah declared Himself pleased with the Muhaajiroon and the Ansaar and promised them gardens forever (9:100), knowing what they would do. Had they turned back as a body, that promise would be untrue.")),
            .longOnly(.step("4. **The claim destroys its own foundation.** The Quran was gathered, written and taught by these very men, and the Sunnah narrated by them. Discredit the witnesses and nothing they carried can be trusted.")),
            .longOnly(.text("Abu Zur‘ah ar-Raazi (may Allah have mercy on him), one of the great critics of hadith, saw the last point clearly:")),
            .longOnly(.quote(text: "“If you see a man disparaging any one of the Companions of the Messenger of Allah (peace be upon him), know that he is a heretic. That is because the Messenger is true in our eyes and the Quran is true, and it was only the Companions of the Messenger of Allah who conveyed this Quran and the Sunnah to us. They want to discredit our witnesses in order to nullify the Book and the Sunnah, and they are the ones more deserving of being discredited.” (Abu Zur‘ah ar-Raazi, reported by al-Khateeb al-Baghdaadi in al-Kifaayah).", arabic: "إِذَا رَأَيتَ الرَّجُلَ يَنتَقِصُ أَحَدًا مِن أَصحَابِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ فَاعلَم أَنَّهُ زِندِيقٌ، وَذَلِكَ أَنَّ الرَّسُولَ عِندَنَا حَقٌّ، وَالقُرآنَ حَقٌّ، وَإِنَّمَا أَدَّى إِلَينَا هَذَا القُرآنَ وَالسُّنَنَ أَصحَابُ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، وَإِنَّمَا يُرِيدُونَ أَن يَجرَحُوا شُهُودَنَا لِيُبطِلُوا الكِتَابَ وَالسُّنَّةَ، وَالجَرحُ بِهِم أَولَى", dimmed: true)),
            .door(.article("ShiaAnswerView")),
        ]),
        ArticleSection("WHY THEY ARE THE MEASURE", [
            .longOnly(.text("When the Quran first told the believers how to judge whether others were guided, the believers it was speaking to were the Companions:")),
            .longOnly(.ayah("2:137", words: 0...7)),
            .longOnly(.text("And when it warned against leaving “the way of the believers,” the believers on the earth at that moment were the Companions:")),
            .longOnly(.ayah("4:115", words: 9...12)),
            .text("The Prophet (peace be upon him) tied his own Sunnah to that of his caliphs in a sermon that, al-Irbaad ibn Saariyah (may Allah be pleased with him) remembered, made the eyes weep and the hearts afraid:"),
            .hadith("abudawud:4607", cite: "Sunan Abi Daawood 4607; graded saheeh by al-Albaani", arabic: 104...132, english: [147...192]),
            .text("So Ahl as-Sunnah read the Quran and the Sunnah as the Companions read them. The reason is not that they were heroes; it is that they were there. They saw each ayah come down and knew what it came down about, spoke its Arabic as their mother tongue, and could ask the Prophet when something was unclear. They watched him pray, judge, trade, fight and forgive, and recorded what they saw. Every school of law, every chain of hadith and every early tafseer passes through one of them. A reading of the religion that none of them held did not come from them, and so did not come from him."),
            .door(.article("AhlusSunnahView")),
            .door(.article("SahabahView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Is Mu‘aawiyah a Companion?**"),
            .shortOnly(.text("Yes. Mu‘aawiyah ibn Abi Sufyaan (may Allah be pleased with him) accepted Islam, kept the Prophet’s company and was among those who wrote for him, and his sister Umm Habeebah was a Mother of the Believers. When someone complained about the way he prayed the witr, Ibn Abbaas (may Allah be pleased with him) answered:")),
            .longOnly(.text("Yes. Mu‘aawiyah ibn Abi Sufyaan (may Allah be pleased with him) accepted Islam, kept the Prophet’s company and was among those who wrote for him, and his sister Umm Habeebah was a Mother of the Believers. When someone complained to Ibn Abbaas (may Allah be pleased with him) about the way Mu‘aawiyah prayed the witr, Ibn Abbaas said, “Leave him, for he was in the company of Allah’s Messenger,” and, “He is a faqeeh” (Saheeh al-Bukhaari 3764, 3765). He governed Syria for Umar and Uthmaan, and al-Hasan ibn Ali made peace with him in 41 AH, fulfilling the Prophet’s words that through al-Hasan Allah would reconcile two great groups of Muslims (Saheeh al-Bukhaari 2704). He erred in fighting Ali, as a mujtahid errs; he is not cursed.")),
            .longOnly(.hadith("bukhari:3764", cite: "Saheeh al-Bukhaari 3764", arabic: 15...36, english: [0...53])),
            .hadith("bukhari:3765", cite: "Saheeh al-Bukhaari 3765", arabic: 12...28, english: [0...40]),
            .shortOnly(.text("He erred in fighting Ali, as a mujtahid errs; he is not cursed.")),
            .longOnly(.hadith("bukhari:2704", cite: "Saheeh al-Bukhaari 2704", arabic: 154...191, english: [240...294])),
            .longOnly(.markdown("**Were there not hypocrites around the Prophet too?**")),
            .longOnly(.text("There were, some unknown even to him (9:101). But a hypocrite is not a Companion: the definition requires belief. And those Allah praised by name or description, the Muhaajiroon, the Ansaar, the people of Badr and of the tree, cannot be among them, because Allah does not declare Himself pleased with a hypocrite.")),
            .longOnly(.ayah("9:101")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A Companion is one who met the Prophet believing in him and died a Muslim. Allah declared Himself pleased with them, and the Prophet called his generation the best and forbade anyone to revile them. They differ in rank, the four caliphs first; they were upright but not infallible; and their fighting is left to Allah, each side a mujtahid. Because the Quran and the Sunnah reached the world through them, their way is the measure of every later understanding of Islam."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Sahaabi", arabic: "صَحَابِيّ", meaning: "A **Companion**: one who met the Prophet (peace be upon him) believing in him and died upon Islam. The plural is **sahaabah** or **ashaab**."),
            .term("Adaalah", arabic: "عَدَالَة", meaning: "**Uprightness**: the quality of a narrator whose religion and character can be trusted. Every Companion is held upright (**‘udool**) by the testimony of the Quran and the Sunnah, so a chain is not weakened by a Companion left unnamed."),
            .term("Qarn", arabic: "قَرن", meaning: "A **generation**: the people of one span of time. The Prophet named three as the best: his own, the Taabi‘oon after it, and the generation after them, together called **the Salaf**."),
            .term("Ijtihaad", arabic: "اجتِهَاد", meaning: "**Striving to reach the right judgment** from the evidence. The one who strives and is right has two rewards and the one who strives and errs has one (Saheeh al-Bukhaari 7352); this is how Ahl as-Sunnah view the disputes between the Companions."),
        ]),
    ]
}

struct CompanionAbuBakrView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionAbuBakrView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Abu Bakr as-Siddeeq")
        .englishArticle().selectableArticleList(article: "CompanionAbuBakrView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Abu Bakr as-Siddeeq (may Allah be pleased with him) was the closest friend of the Prophet Muhammad (peace and blessings be upon him), the first free man to believe in him, his companion in the cave, and the first caliph of Islam. He spent his wealth freeing the persecuted, was chosen by the Prophet to lead the prayer in his last illness, steadied the Muslims on the day the Prophet died, held the Arabs to Islam when whole tribes turned back, and had the Quran gathered into one volume. He ruled a little over two years and died in 13 AH, at the same age as the Prophet, and lies buried beside him."),
        ]),
        ArticleSection("BEFORE ISLAM", [
            .shortOnly(.text("Abu Bakr (may Allah be pleased with him) was named Abdullah ibn Uthmaan, of the clan of Taym of Quraysh; his father was known as Abu Quhaafah. He was about two years younger than the Prophet (peace be upon him), a merchant by trade, and a man the people of Makkah liked: easy to approach, generous, and known for his knowledge of the Arabs’ lineages.")),
            .longOnly(.text("Abu Bakr (may Allah be pleased with him) was named Abdullah ibn Uthmaan, of the clan of Taym of Quraysh; his father was known as Abu Quhaafah. His line meets the Prophet’s (peace be upon him) at their common ancestor Murrah ibn Ka‘b. He was about two years younger than the Prophet, a merchant by trade, and a man the people of Makkah liked: easy to approach, generous, and known for his knowledge of the Arabs’ lineages. When the poet Hassaan ibn Thaabit (may Allah be pleased with him) wanted to answer the satires of Quraysh without striking at the Prophet’s own ancestry, the Prophet told him to learn the lineages from Abu Bakr first, “who has the best knowledge of the lineage of the Quraysh” (Saheeh Muslim 2490).")),
            .longOnly(.hadith("muslim:2490", cite: "Saheeh Muslim 2490", arabic: 115...132, english: [52...86])),
            .longOnly(.text("He was also called Ateeq. Aa’ishah (may Allah be pleased with her) narrates that the Prophet said to him one day, “You are Allah’s Ateeq from the Fire,” the one freed from it, and from then on the name stuck (Jaami‘ at-Tirmidhi 3679). Abu Bakr was his kunya, the name by which people addressed him with respect.")),
            .longOnly(.hadith("tirmidhi:3679", cite: "Jaami‘ at-Tirmidhi 3679; graded saheeh by al-Albaani", arabic: 19...42, english: [0...27])),
        ]),
        ArticleSection("HE HAS SPOKEN THE TRUTH", [
            .shortOnly(.text("When the Prophet (peace be upon him) began to call people to Islam, Abu Bakr believed at once. Years later, after a quarrel in which Abu Bakr had spoken harshly to Umar (may Allah be pleased with him) and Umar had at first refused his apology, the Prophet’s face showed his displeasure and he said to the gathering:")),
            .longOnly(.text("When the Prophet began to call people to Islam, Abu Bakr (may Allah be pleased with him) believed at once. How few the believers were then, Ammaar ibn Yaasir (may Allah be pleased with him) remembered:")),
            .longOnly(.hadith("bukhari:3660", cite: "Saheeh al-Bukhaari 3660", arabic: 24...38, english: [0...18])),
            .longOnly(.text("Years later, after a quarrel in which Abu Bakr had spoken harshly to Umar (may Allah be pleased with him) and Umar had at first refused his apology, the Prophet’s face showed his displeasure and he said to the gathering:")),
            .hadith("bukhari:3661", cite: "Saheeh al-Bukhaari 3661", arabic: 146...163, english: [174...221]),
            .shortOnly(.markdown("That readiness to believe is what the name **as-Siddeeq (الصِّدِّيق)** means: the one who confirms the truth completely.")),
            .longOnly(.markdown("That readiness to believe is what the name **as-Siddeeq (الصِّدِّيق)** means: the one who confirms the truth completely. The Prophet used it of him himself: when Mount Uhud shook beneath him, Abu Bakr, Umar and Uthmaan, he said, “Be firm, O Uhud! For on you there are no more than a Prophet, a Siddeeq and two martyrs” (Saheeh al-Bukhaari 3675). Al-Haakim also records, with a chain that al-Albaani (may Allah have mercy on him) graded saheeh, that on the morning after the Night Journey the idolaters ran to Abu Bakr expecting him to abandon his friend, and he said that if the Prophet had said it, then he had spoken the truth.")),
            .longOnly(.hadith("bukhari:3675", cite: "Saheeh al-Bukhaari 3675", arabic: 26...43, english: [0...45])),
            .text("His faith showed in his wealth. The weakest of the early Muslims were slaves whose masters tortured them for their Islam, and Abu Bakr bought them and set them free, Bilaal ibn Rabaah (may Allah be pleased with him) first among them. Umar would later say of it:"),
            .hadith("bukhari:3754", cite: "Saheeh al-Bukhaari 3754", arabic: 27...33, english: [4...15]),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) notes that many of the commentators say the closing aayaat of Surat al-Layl came down about Abu Bakr, some even reporting their agreement on it, while their meaning covers everyone who gives as he gave:")),
            .longOnly(.ayah("92:17-21")),
            .longOnly(.text("The idolaters pressed him so hard that he set out to emigrate to Abyssinia. On the road he met Ibn ad-Daghinah, a chief of the tribe of Qaarah, who stopped him with words that Aa’ishah preserved:")),
            .longOnly(.hadith("bukhari:3905", cite: "Saheeh al-Bukhaari 3905", arabic: 95...123, english: [118...180])),
            .longOnly(.text("They are almost word for word what Khadeejah had said to the Prophet on the day of the first revelation (Saheeh al-Bukhaari 3). Ibn ad-Daghinah took him under his protection, on the condition Quraysh demanded: that he worship only inside his house. But Abu Bakr built a small place of prayer in the open courtyard in front of his home and recited the Quran there, and he could not stop himself from weeping as he recited. The wives and children of the idolaters gathered to watch, and the leaders of Quraysh took fright. When Ibn ad-Daghinah asked him to keep the terms or give the protection back, Abu Bakr said he released him from it and was content with the protection of Allah.")),
            .longOnly(.hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 184...204, english: [312...346])),
        ]),
        ArticleSection("THE SECOND OF THE TWO", [
            .shortOnly(.text("When permission came to emigrate to Madinah, Abu Bakr’s first words were to ask whether he could go with the Prophet (peace be upon him), and the Prophet said yes. They hid for three nights in the cave of Thawr while Quraysh searched the hills, and at one point the searchers stood at the mouth of the cave:")),
            .longOnly(.text("When the Muslims began emigrating to Madinah, Abu Bakr prepared to go, but the Prophet (peace be upon him) asked him to wait, saying he hoped to be given permission himself. Abu Bakr waited, and for four months he fed two camels in readiness. Then one day at noon, at an hour he never usually came, the Prophet arrived at the house with his head covered and told him that permission had come. Abu Bakr’s first words were to ask whether he could come with him, and the Prophet said yes (Saheeh al-Bukhaari 3905).")),
            .longOnly(.text("They hid for three nights in the cave of Thawr while Quraysh searched the hills. Abu Bakr’s son Abdullah and his freedman Aamir ibn Fuhayrah (may Allah be pleased with them) served them: Abdullah brought the news of Makkah each night, and Aamir grazed sheep nearby and brought them milk. At one point the searchers stood at the mouth of the cave:")),
            .hadith("bukhari:3653", cite: "Saheeh al-Bukhaari 3653, Saheeh Muslim 2381", arabic: 28...45, english: [12...42]),
            .text("Allah kept that moment in the Quran, and gave Abu Bakr a title no one else holds, the second of two, the one the Prophet called his companion:"),
            .ayah("9:40", words: 9...22),
            .text("The scholars have long pointed out that this is a companionship named by Allah Himself. Whoever denies that Abu Bakr was a Companion denies the Quran, since there was no one else in the cave."),
        ]),
        ArticleSection("WITH HIS COMPANY AND HIS WEALTH", [
            .text("In Madinah he was at the Prophet’s side at every battle, from Badr to Tabook. Near the end of his life, the Prophet told the people from the pulpit that Allah had given a servant the choice between this world and what is with Him, and the servant had chosen what is with Allah. Only Abu Bakr understood, and he wept:"),
            .hadith("bukhari:3654", cite: "Saheeh al-Bukhaari 3654, Saheeh Muslim 2382", arabic: 56...115, english: [31...137]),
            .longOnly(.markdown("A **khaleel (خَلِيل)** is the friend whose love fills the heart so completely that no room is left for another; the Prophet (peace be upon him) reserved that place for his Lord alone. Short of it, there was no one closer to him than Abu Bakr. When Amr ibn al-As (may Allah be pleased with him) asked him who was the most beloved of people to him, he said Aa’ishah, and when Amr asked about the men, he said, “Her father” (Saheeh al-Bukhaari 3662).")),
            .longOnly(.hadith("bukhari:3662", cite: "Saheeh al-Bukhaari 3662", arabic: 37...62, english: [11...47])),
            .longOnly(.text("Umar ibn al-Khattaab (may Allah be pleased with him) once tried to outdo him:")),
            .longOnly(.hadith("tirmidhi:3675", cite: "Jaami‘ at-Tirmidhi 3675; graded hasan by al-Albaani", arabic: 29...96, english: [6...117])),
            .longOnly(.text("He combined that generosity with daily, ordinary acts of good, as the Prophet once discovered by asking a few questions:")),
            .longOnly(.hadith("muslim:1028", cite: "Saheeh Muslim 1028", arabic: 33...113, english: [0...99])),
            .longOnly(.text("His goodness did not depend on how people treated him. When Mistah ibn Uthaathah, a poor relative whom Abu Bakr supported, joined in the slander against Aa’ishah, Abu Bakr swore never to spend on him again. Allah revealed:")),
            .longOnly(.ayah("24:22", words: 17...22)),
            .longOnly(.text("Abu Bakr said, “Yes, by Allah, I wish that Allah should forgive me,” and he restored Mistah’s support, swearing never to withhold it (Saheeh al-Bukhaari 4750). And when the Prophet warned that Allah would not look at the man who lets his garment trail out of pride, Abu Bakr worried at once that one side of his own garment slipped down unless he watched it, and the Prophet reassured him that he was not one who did it out of pride (Saheeh al-Bukhaari 3665).")),
            .longOnly(.hadith("bukhari:4750", cite: "Saheeh al-Bukhaari 4750", arabic: 1391...1415, english: [2168...2206])),
            .longOnly(.hadith("bukhari:3665", cite: "Saheeh al-Bukhaari 3665", arabic: 35...71, english: [0...54])),
        ]),
        ArticleSection("THE DAY THE PROPHET DIED", [
            .text("In his final illness, when he could no longer go out to the mosque, the Prophet (peace be upon him) gave one instruction three times:"),
            .hadith("bukhari:678", cite: "Saheeh al-Bukhaari 678, Saheeh Muslim 420", arabic: 32...81, english: [13...98]),
            .longOnly(.text("Aa’ishah had tried to excuse her father because he wept so easily when reciting, and the Prophet would not hear of anyone else. He had already given other signs. A woman who came to him with a matter was told to come back; when she asked what she should do if she did not find him, meaning if he had died, he said, “If you should not find me, go to Abu Bakr” (Saheeh al-Bukhaari 3659). And in his illness he said to Aa’ishah:")),
            .longOnly(.hadith("bukhari:3659", cite: "Saheeh al-Bukhaari 3659", arabic: 22...52, english: [0...50])),
            .longOnly(.hadith("muslim:2387", cite: "Saheeh Muslim 2387", arabic: 36...59, english: [0...22])),
            .shortOnly(.text("He died on a Monday in Rabee‘ al-Awwal, 11 AH (632 CE), in Aa’ishah’s room. Umar (may Allah be pleased with him), overcome, stood in the mosque insisting that the Prophet had not died. Abu Bakr rode in from his house on the edge of Madinah, went to the body, uncovered the face and kissed it; then he went out to the people, told Umar to sit down, and spoke the words that held the ummah together:")),
            .longOnly(.text("He died on a Monday in Rabee‘ al-Awwal, 11 AH (632 CE), in Aa’ishah’s room. Abu Bakr was at his house in as-Sunh on the edge of Madinah. Umar (may Allah be pleased with him), overcome, stood in the mosque insisting that the Prophet had not died. Abu Bakr rode in, went to the body, uncovered the face and kissed it:")),
            .longOnly(.hadith("bukhari:3667", cite: "Saheeh al-Bukhaari 3667", arabic: 89...102, english: [79...115])),
            .longOnly(.text("Then he went out to the people, told Umar to sit down, and spoke the words that held the ummah together:")),
            .hadith("bukhari:3667", cite: "Saheeh al-Bukhaari 3667", arabic: 123...144, english: [144...162]),
            .text("And he recited the ayah that had been in their hands for eight years, revealed after Uhud, when the rumour had spread that the Prophet had been killed:"),
            .ayah("3:144"),
            .text("Aa’ishah narrates that the people wept aloud. A man who loved the Prophet more than anyone had looked at his body, and the first thing he told the ummah was to worship the One who does not die."),
        ]),
        ArticleSection("THE PLEDGE AT THE SAQEEFAH", [
            .text("That same day the Ansaar gathered with Sa‘d ibn Ubaadah in the hall of Banu Saa‘idah, and some proposed a leader from them and a leader from the Muhaajiroon. Abu Bakr, Umar and Abu Ubaydah (may Allah be pleased with them) went to them. Abu Bakr spoke, and offered them Umar or Abu Ubaydah; Umar refused:"),
            .hadith("bukhari:3667", cite: "Saheeh al-Bukhaari 3667", arabic: 284...303, english: [429...479]),
            .shortOnly(.text("The next day the people gave him the general pledge in the mosque, and he was called Khaleefat Rasool Allah, the successor of the Messenger of Allah. In his first address he told them he had been put in charge of them though he was not the best of them, and that they owed him obedience only as long as he obeyed Allah and His Messenger. Ali (may Allah be pleased with him) delayed his own pledge for six months, while Faatimah (may Allah be pleased with her) lived; after her death he praised Abu Bakr’s precedence and gave his pledge publicly in the mosque, and the Muslims rejoiced.")),
            .longOnly(.text("The next day the people gave him the general pledge in the mosque. He was called Khaleefat Rasool Allah, the successor of the Messenger of Allah. In the address the seerah records from his first day, he told them he had been put in charge of them though he was not the best of them, that they should help him if he did well and set him right if he did wrong, and that they owed him obedience only as long as he obeyed Allah and His Messenger.")),
            .longOnly(.text("He had lived by trade, and now he had no time for it. Aa’ishah narrates what he said:")),
            .longOnly(.hadith("bukhari:2070", cite: "Saheeh al-Bukhaari 2070", arabic: 33...56, english: [9...53])),
            .longOnly(.text("Ali (may Allah be pleased with him) delayed his own pledge for six months, while Faatimah (may Allah be pleased with her) lived. After her death he asked Abu Bakr to meet him, praised his precedence, said that he had held back from no envy of what Allah had given him, and gave his pledge publicly in the mosque, and the Muslims rejoiced (Saheeh al-Bukhaari 4240). The disagreement over the Prophet’s land at Fadak, which Abu Bakr settled by the Prophet’s own words that the prophets leave no inheritance, is answered in full elsewhere.")),
            .longOnly(.hadith("bukhari:4240", cite: "Saheeh al-Bukhaari 4240", arabic: 330...371, english: [548...645])),
            .door(.article("ShiaAnswerView")),
        ]),
        ArticleSection("THE YEAR OF THE APOSTASY", [
            .shortOnly(.text("Within weeks of the Prophet’s death much of Arabia was in revolt: some tribes followed men who claimed prophethood, Musaylimah in al-Yamaamah among them, and others kept the prayer but refused to pay the zakaah to Madinah. The question of those who withheld the zakaah divided the senior Companions, and when Umar objected, Abu Bakr answered:")),
            .longOnly(.text("Within weeks of the Prophet’s death much of Arabia was in revolt. Some tribes followed men who claimed prophethood: Musaylimah in al-Yamaamah, Tulayhah al-Asadi in the north, Sajaah of Banu Tameem. Others kept the prayer but refused to pay the zakaah to Madinah. Even before facing them, Abu Bakr (may Allah be pleased with him) sent out the army the Prophet had prepared under the young Usaamah ibn Zayd (may Allah be pleased with him), refusing to recall a force the Prophet himself had dispatched, though Madinah was left nearly undefended.")),
            .longOnly(.text("The question of those who withheld the zakaah divided the senior Companions. Umar objected that the Prophet had said whoever testifies that there is no god but Allah has protected his life and property:")),
            .hadith("bukhari:1399", cite: "Saheeh al-Bukhaari 1399, Saheeh Muslim 20", arabic: 96...148, english: [104...193]),
            .longOnly(.text("Abu Bakr’s argument was the hadith itself: it protects life and property “except by its right,” and zakaah is the right of wealth. Prayer and zakaah stand together in the Quran, and he would not let them be separated. The armies he sent under Khaalid ibn al-Waleed and others brought the tribes back within about a year; Musaylimah was killed at al-Yamaamah in 12 AH, and Tulayhah later returned to Islam and fought for it. Al-Hasan al-Basri (may Allah have mercy on him), as Ibn Katheer records, said that this ayah described Abu Bakr and those with him:")),
            .longOnly(.ayah("5:54", words: 3...27)),
            .longOnly(.text("With Arabia secured, he sent armies toward Iraq and Syria, the beginning of the conquests that Umar would complete.")),
            .shortOnly(.text("The armies he sent under Khaalid ibn al-Waleed and others brought the tribes back within about a year, and with Arabia secured he sent armies toward Iraq and Syria, the beginning of the conquests that Umar would complete.")),
            .door(.article("CaliphatesView")),
        ]),
        ArticleSection("THE QURAN IN ONE VOLUME", [
            .shortOnly(.text("At al-Yamaamah many of those who had memorised the Quran were killed, and Umar urged Abu Bakr to gather it, afraid that much of it would be lost. Abu Bakr first asked how he could do something the Messenger of Allah had not done, until Allah opened his chest to it. He gave the task to Zayd ibn Thaabit (may Allah be pleased with him), the young scribe of the revelation, who gathered it from what had been written in the Prophet’s presence and from the memories of the reciters. The sheets stayed with Abu Bakr, then with Umar, then with Hafsah, and they were the source of the copies Uthmaan would later send to the cities.")),
            .longOnly(.text("At al-Yamaamah many of those who had memorised the Quran were killed, and Umar (may Allah be pleased with him) came to Abu Bakr afraid that much of the Quran would be lost if this went on. Abu Bakr’s first answer showed the man: how could he do something the Messenger of Allah had not done? Umar kept urging until, in Abu Bakr’s words, Allah opened his chest to it. He then gave the task to Zayd ibn Thaabit (may Allah be pleased with him), the young scribe of the revelation, who said that moving a mountain would have been lighter. Zayd gathered it from what had been written in the Prophet’s presence and from the memories of the reciters, and the sheets stayed with Abu Bakr until he died, then with Umar, then with Hafsah (Saheeh al-Bukhaari 4986). These sheets were the source of the copies Uthmaan would later send to the cities.")),
            .longOnly(.hadith("bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 184...234, english: [303...421])),
            .door(.article("CompileView")),
        ]),
        ArticleSection("HIS DEATH", [
            .shortOnly(.text("He fell ill in Jumaada al-Aakhirah, 13 AH (634 CE), and before he died he consulted senior Companions and named Umar to succeed him. He was buried by night in Aa’ishah’s room beside the Prophet. He was sixty-three, the age at which the Prophet had died (Saheeh Muslim 2352), and his caliphate had lasted two years and about three months.")),
            .longOnly(.text("He fell ill in Jumaada al-Aakhirah, 13 AH (634 CE). Before he died he consulted senior Companions, among them Abd ar-Rahman ibn Awf and Uthmaan (may Allah be pleased with them), and named Umar to succeed him. His last concern was to follow the Prophet even in death:")),
            .longOnly(.hadith("bukhari:1387", cite: "Saheeh al-Bukhaari 1387", arabic: 28...108, english: [15...154])),
            .longOnly(.text("He died that night and was buried before morning, in Aa’ishah’s room beside the Prophet. He was sixty-three, the age at which the Prophet had died (Saheeh Muslim 2352). His caliphate had lasted two years and about three months.")),
            .hadith("muslim:2352a", cite: "Saheeh Muslim 2352", arabic: 51...74, english: [34...62]),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Did the Prophet appoint Abu Bakr as caliph?**"),
            .shortOnly(.text("He did not write a formal appointment, but he pointed to Abu Bakr so clearly that the Companions understood: in his last illness he put him in his own place at the prayer and would not hear of anyone else. The Companions then chose him by consultation and pledge.")),
            .longOnly(.text("He did not write a formal appointment, though he once intended to (Saheeh Muslim 2387), but he pointed to Abu Bakr so clearly that the Companions understood: he put him in his own place at the prayer, sent the woman to him, and called Allah and the believers to witness that they would accept no one else. The Companions then chose him by consultation and pledge, as he had foreseen.")),
            .longOnly(.markdown("**What about the spider’s web and the dove at the cave?**")),
            .longOnly(.text("The story that a spider spun its web over the mouth of the cave and a dove nested there is widely told, but its chain is weak, and so is the story that a snake bit Abu Bakr in the cave and the Prophet’s saliva cured him. They are not told here. The sound account is enough: two men in a cave, searchers at the entrance, and the words “What do you think of two, the third of whom is Allah?”")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Abu Bakr believed when others called the Prophet a liar, spent his wealth freeing the tortured, shared the cave and the Hijrah, and was the man the Prophet loved most among men. In his last illness the Prophet put him in his own place at the prayer, and on the day he died Abu Bakr reminded the ummah that Allah is alive and does not die. As caliph he held Arabia to Islam, refused to let prayer and zakaah be separated, and had the Quran gathered into one volume. Ali named him the best of people after the Prophet, and he lies beside him."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("As-Siddeeq", arabic: "الصِّدِّيق", meaning: "**The one who confirms the truth completely**, in word and deed. The Quran ranks the siddeeqoon directly after the prophets (4:69), and the Prophet called Abu Bakr a siddeeq (Saheeh al-Bukhaari 3675)."),
            .ayah("4:69", words: 10...14),
            .term("Khaleel", arabic: "خَلِيل", meaning: "**The intimate friend** whose love leaves no room for another. Allah took Ibraaheem as khaleel (4:125); the Prophet said that if he took anyone besides his Lord, it would be Abu Bakr."),
            .ayah("4:125", words: 13...16),
            .term("Riddah", arabic: "رِدَّة", meaning: "**Apostasy**, turning back from Islam. The wars of the Riddah (11–12 AH) were fought by Abu Bakr against the tribes that followed false prophets or refused the zakaah after the Prophet’s death."),
            .term("Khaleefah", arabic: "خَلِيفَة", meaning: "**Successor**. Abu Bakr was called Khaleefat Rasool Allah, the successor of the Messenger of Allah; the title Ameer al-Mu’mineen, Commander of the Believers, began with Umar."),
        ]),
    ]
}

struct CompanionUmarView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionUmarView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Umar ibn al-Khattaab")
        .englishArticle().selectableArticleList(article: "CompanionUmarView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Umar ibn al-Khattaab (may Allah be pleased with him) was a fierce opponent of Islam until the Prophet Muhammad (peace and blessings be upon him) prayed for him by name, and from the day he accepted it the Muslims prayed openly. The Quran came down more than once in agreement with his opinion, the Prophet called him inspired and said Satan avoided his path, and he was second only to Abu Bakr in rank. In ten years as caliph he brought Persia, Syria, Jerusalem and Egypt under Islam, founded the register of stipends and the Hijri calendar, and governed with a justice that became proverbial. He was stabbed at the dawn prayer in 23 AH and buried beside his two companions."),
        ]),
        ArticleSection("THE ENEMY OF THE EARLY MUSLIMS", [
            .shortOnly(.text("Umar (may Allah be pleased with him) was of Banu Adi, a small clan of Quraysh, known for his strength, his wrestling and his blunt speech, and when the call to Islam began he was among its harshest opponents.")),
            .longOnly(.text("Umar (may Allah be pleased with him) was of Banu Adi, a small clan of Quraysh, and his line meets that of the Prophet (peace be upon him) at Ka‘b ibn Lu’ayy. He was born about thirteen years after the Year of the Elephant, grew up herding his father’s camels, learned to read and write, which few in Makkah could, and was known for his strength, his wrestling and his blunt speech. Quraysh used him as their envoy when they needed someone to speak for them to other tribes.")),
            .longOnly(.text("When the call to Islam began, he was among its harshest opponents. Sa‘eed ibn Zayd (may Allah be pleased with him), who was married to Umar’s sister Faatimah, recalled decades later in the mosque of Koofah:")),
            .longOnly(.hadith("bukhari:3862", cite: "Saheeh al-Bukhaari 3862", arabic: 23...34, english: [15...33])),
        ]),
        ArticleSection("THE PRAYER THAT WAS ANSWERED", [
            .text("The Prophet (peace be upon him) asked Allah for him by name, in a prayer that named the two strongest enemies of Islam in Makkah:"),
            .hadith("tirmidhi:3681", cite: "Jaami‘ at-Tirmidhi 3681; graded saheeh by al-Albaani", arabic: 34...53, english: [7...40]),
            .longOnly(.text("He accepted Islam in about the sixth year of the mission, and the effect was immediate. The idolaters crowded around his house shouting that Umar (may Allah be pleased with him) had changed his religion, until al-As ibn Waa’il, a chief allied to his clan, came out in a silk cloak, declared himself Umar’s protector, and sent them away; Abdullah ibn Umar, then a boy, watched it from a rooftop (Saheeh al-Bukhaari 3865). Abdullah ibn Mas‘ood (may Allah be pleased with him) summed up what the Muslims felt:")),
            .longOnly(.hadith("bukhari:3865", cite: "Saheeh al-Bukhaari 3865", arabic: 23...64, english: [0...83])),
            .shortOnly(.text("He accepted Islam in about the sixth year of the mission, and the effect was immediate. Abdullah ibn Mas‘ood (may Allah be pleased with him) summed up what the Muslims felt:")),
            .hadith("bukhari:3684", cite: "Saheeh al-Bukhaari 3684", arabic: 14...19, english: [0...7]),
            .markdown("He came to be known as **al-Faarooq (الفَارُوق)**, the one who separates truth from falsehood. He emigrated to Madinah among the early emigrants and took part in every battle with the Prophet, Badr, Uhud and the Trench among them."),
        ]),
        ArticleSection("WHEN THE REVELATION AGREED WITH HIM", [
            .shortOnly(.text("Umar (may Allah be pleased with him) would say that his Lord had agreed with him:")),
            .longOnly(.text("Umar (may Allah be pleased with him) would say that his Lord had agreed with him, and he counted the occasions himself:")),
            .longOnly(.hadith("bukhari:402", cite: "Saheeh al-Bukhaari 402", arabic: 14...75, english: [0...168])),
            .longOnly(.text("He had wished that the station of Ibraaheem be taken as a place of prayer, and 2:125 came down; he had urged that the Prophet’s wives be screened from the men who came to the house, and the ayah of the hijab came down (33:53); and the words he spoke to the wives when they united against the Prophet came down nearly as he had said them (66:5). In Ibn Umar’s narration in Saheeh Muslim the third is different: the prisoners of Badr (Saheeh Muslim 2399).")),
            .longOnly(.ayah("2:125", words: 6...10)),
            .longOnly(.ayah("33:53", words: 38...48)),
            .longOnly(.ayah("66:5", words: 0...8)),
            .hadith("muslim:2399", cite: "Saheeh Muslim 2399", arabic: 22...33, english: [0...30]),
            .shortOnly(.text("Each time the Quran came down in line with what he had said. This was not because Umar outranked the Prophet in judgment. The Prophet chose mercy and the softer opinion, and revelation sometimes confirmed him and sometimes taught the ummah through Umar’s firmness.")),
            .longOnly(.text("After Badr the Prophet accepted Abu Bakr’s advice to ransom the captives, while Umar had advised killing the leaders of Quraysh among them (Saheeh Muslim 1763).")),
            .longOnly(.hadith("muslim:1763", cite: "Saheeh Muslim 1763", arabic: 266...377, english: [356...527])),
            .longOnly(.text("And the Quran then said:")),
            .longOnly(.ayah("8:67")),
            .longOnly(.text("When the chief hypocrite Abdullah ibn Ubayy died, Umar caught hold of the Prophet’s garment as he stood to pray over him, reminding him of what Ibn Ubayy had said and done. The Prophet prayed over him, and then Allah revealed the prohibition (Saheeh al-Bukhaari 4670):")),
            .longOnly(.ayah("9:84", words: 0...10)),
            .longOnly(.hadith("bukhari:4670", cite: "Saheeh al-Bukhaari 4670", arabic: 52...133, english: [52...188])),
            .longOnly(.text("Ibn Umar (may Allah be pleased with him) said that whenever a matter came up and people said one thing and Umar another, the Quran came down in line with what Umar had said (Jaami‘ at-Tirmidhi 3682). This was not because Umar outranked the Prophet in judgment. The Prophet chose mercy and the softer opinion, and revelation sometimes confirmed him and sometimes taught the ummah through Umar’s firmness.")),
            .longOnly(.hadith("tirmidhi:3682", cite: "Jaami‘ at-Tirmidhi 3682; graded saheeh by al-Albaani", arabic: 40...68, english: [27...80])),
        ]),
        ArticleSection("WHAT THE PROPHET SAW IN HIM", [
            .shortOnly(.text("Some of the Prophet’s (peace be upon him) descriptions of Umar (may Allah be pleased with him) are among the most remarkable things he said about any Companion. When some women of Quraysh hurried behind a screen at Umar’s approach, saying he was harsher and sterner than the Prophet, the Prophet laughed and said:")),
            .longOnly(.text("Some of the Prophet’s (peace be upon him) descriptions of Umar (may Allah be pleased with him) are among the most remarkable things he said about any Companion. Some women of Quraysh were once sitting with the Prophet, raising their voices as they asked him for more provision, and when Umar asked permission to enter they hurried behind the screen. The Prophet laughed, and Umar scolded them: did they fear him and not the Messenger of Allah? They said he was harsher and sterner. The Prophet said:")),
            .hadith("bukhari:3683", cite: "Saheeh al-Bukhaari 3683, Saheeh Muslim 2396", arabic: 179...196, english: [164...191]),
            .text("He also said:"),
            .hadith("bukhari:3689", cite: "Saheeh al-Bukhaari 3689", arabic: 30...43, english: [4...36]),
            .longOnly(.markdown("A **muhaddath (مُحَدَّث)** is one to whom the truth is cast into his heart, so that his judgment hits the mark though no revelation comes to him. “If there is any in my ummah” is not doubt; this ummah has the Quran and the Sunnah and needs no inspired men. Ibn Taymiyyah (may Allah have mercy on him) draws the lesson that even the muhaddath must weigh what comes to him against the Book and the Sunnah: Umar himself was corrected by Abu Bakr on the day the Prophet died, and he took the correction at once.")),
            .longOnly(.text("In dreams, which for a prophet are true, the Prophet saw himself drinking milk until he felt it running out through his nails and giving what was left to Umar; he interpreted it as knowledge (Saheeh al-Bukhaari 82). He saw people presented to him in shirts of different lengths, and Umar’s trailed on the ground; he interpreted it as religion (Saheeh al-Bukhaari 3691). He saw a palace in Paradise and was told it belonged to Umar, and he did not go in, remembering Umar’s protective jealousy; and Umar wept that he could ever feel such jealousy toward the Messenger of Allah (Saheeh al-Bukhaari 3680).")),
            .shortOnly(.markdown("A **muhaddath (مُحَدَّث)** is one to whom the truth is cast into his heart, so that his judgment hits the mark though no revelation comes to him; even he must weigh what comes to him against the Book and the Sunnah.")),
            .shortOnly(.text("In dreams, which for a prophet are true, the Prophet saw himself drinking milk and giving what was left to Umar, and he interpreted it as knowledge:")),
            .hadith("bukhari:82", cite: "Saheeh al-Bukhaari 82", arabic: 33...62, english: [4...71]),
            .longOnly(.hadith("bukhari:3691", cite: "Saheeh al-Bukhaari 3691", arabic: 38...71, english: [6...66])),
            .longOnly(.hadith("bukhari:3680", cite: "Saheeh al-Bukhaari 3680", arabic: 40...69, english: [9...71])),
            .longOnly(.text("And he saw himself drawing water from a well:")),
            .longOnly(.hadith("bukhari:3682", cite: "Saheeh al-Bukhaari 3682", arabic: 50...78, english: [18...79])),
            .longOnly(.text("The scholars read the dream as the two caliphates: Abu Bakr’s short and burdened with the apostasy, Umar’s long and wide, in which the people drank their fill. And the Prophet said that if there were to be a prophet after him, it would have been Umar (Jaami‘ at-Tirmidhi 3686), a sentence whose condition can never be met, since there is no prophet after him.")),
            .longOnly(.hadith("tirmidhi:3686", cite: "Jaami‘ at-Tirmidhi 3686; graded hasan by al-Albaani", arabic: 33...40, english: [7...22])),
        ]),
        ArticleSection("TEN YEARS AS CALIPH", [
            .shortOnly(.text("Abu Bakr (may Allah be pleased with him) named him before he died in 13 AH (634 CE), and he was the first to be called Ameer al-Mu’mineen, Commander of the Believers. In the ten years that followed, the two empires that had dominated the region for centuries gave way before his commanders: Sa‘d ibn Abi Waqqaas broke the Persian army at al-Qaadisiyyah, Abu Ubaydah and Khaalid ibn al-Waleed defeated the Byzantines at the Yarmook, and Amr ibn al-As took Egypt. The Prophet had said:")),
            .longOnly(.text("Abu Bakr (may Allah be pleased with him) named him before he died in 13 AH (634 CE), and the Muslims gave him the pledge. He was the first to be called Ameer al-Mu’mineen, Commander of the Believers. In the ten years that followed, the two empires that had dominated the region for centuries gave way before his commanders, Sa‘d ibn Abi Waqqaas, Abu Ubaydah, Khaalid ibn al-Waleed and Amr ibn al-As (may Allah be pleased with them). In Iraq, Sa‘d broke the Persian army at al-Qaadisiyyah and took the capital, al-Madaa’in; the victory at Nahaawand in 21 AH ended Sasanian Persia as a power. In Syria, Abu Ubaydah and Khaalid defeated the Byzantines at the Yarmook. Amr took Egypt. The Prophet had said:")),
            .hadith("bukhari:3618", cite: "Saheeh al-Bukhaari 3618", arabic: 29...49, english: [4...46]),
            .longOnly(.text("The treasures of Kisra were brought to Madinah and distributed in Umar’s time, as he had said. Jerusalem surrendered on the condition that the caliph come in person, and Umar travelled to Syria to receive it and gave its Christian inhabitants a covenant securing their lives, churches and property, which at-Tabari (may Allah have mercy on him) records.")),
            .longOnly(.text("He governed as a man who expected to be questioned about every subject. He set up the deewaan, the register by which every Muslim family drew a yearly stipend from the treasury, ranked by precedence in Islam and by nearness to the Prophet, beginning with the Prophet’s own family. With the Companions’ counsel he fixed the Islamic calendar, counting the years from the Hijrah, as Sahl ibn Sa‘d confirms they chose to do (Saheeh al-Bukhaari 3934).")),
            .longOnly(.hadith("bukhari:3934", cite: "Saheeh al-Bukhaari 3934", arabic: 15...32, english: [0...38])),
            .shortOnly(.text("Jerusalem surrendered on the condition that the caliph come in person, and Umar travelled to Syria to receive it. He governed as a man who expected to be questioned about every subject: he set up the deewaan, the register by which every Muslim family drew a yearly stipend from the treasury, and with the Companions’ counsel he fixed the Islamic calendar, counting the years from the Hijrah. He founded the garrison cities of Basrah and Koofah, appointed judges, and checked his governors’ wealth. A few days before his death he was still questioning his officials in Iraq whether they had taxed the land beyond what it could bear:")),
            .longOnly(.text("He founded the garrison cities of Basrah and Koofah, appointed judges, and checked his governors’ wealth. A few days before his death he was still questioning his officials in Iraq whether they had taxed the land beyond what it could bear:")),
            .hadith("bukhari:3700", cite: "Saheeh al-Bukhaari 3700", arabic: 72...84, english: [92...112]),
            .longOnly(.text("He gathered the people in Ramadan behind one reciter, Ubayy ibn Ka‘b (may Allah be pleased with him), for the night prayer, which the Prophet had led for a few nights and then left for fear it would be made obligatory, and seeing them he said, “What an excellent bid‘ah this is” (Saheeh al-Bukhaari 2010). The scholars explain that he meant it in the language’s sense, something renewed; it was the Prophet’s own practice revived, not a new act of worship.")),
            .longOnly(.hadith("bukhari:2010", cite: "Saheeh al-Bukhaari 2010", arabic: 15...81, english: [6...135])),
        ]),
        ArticleSection("HIS FAITH UNDER TRIAL", only: .long, [
            .text("In 18 AH Arabia suffered a famine so severe it was called the Year of Ashes, and Umar (may Allah be pleased with him) forbade himself meat and butter until the people had them again, so that the historians describe his complexion darkening. When drought came he did not pray at the Prophet’s grave. He took al-Abbaas (may Allah be pleased with him), the Prophet’s living uncle, out with the people and asked him to pray:"),
            .hadith("bukhari:1010", cite: "Saheeh al-Bukhaari 1010", arabic: 45...59, english: [23...64]),
            .text("The Companions turned from the Prophet to his uncle because the Prophet had died and al-Abbaas could still pray for them. Seeking the supplication of a living righteous man is what they understood by this; asking the dead was something they never did."),
            .text("The same year plague struck Syria. Umar was on his way there when the commanders met him at Sargh with the news. He consulted the Muhaajiroon, then the Ansaar, then the elders of Quraysh, and decided to turn back. Abu Ubaydah (may Allah be pleased with him) objected:"),
            .hadith("bukhari:5729", cite: "Saheeh al-Bukhaari 5729", arabic: 176...195, english: [241...277]),
            .text("Then Abd ar-Rahman ibn Awf (may Allah be pleased with him) arrived with a hadith he had heard from the Prophet: if plague breaks out in a land, do not go to it, and if it breaks out where you are, do not flee from it. Umar praised Allah, for his reasoning had matched the Sunnah, and went home. And at the Ka‘bah he kissed the Black Stone and said what every Muslim should say:"),
            .hadith("bukhari:1597", cite: "Saheeh al-Bukhaari 1597, Saheeh Muslim 1270", arabic: 28...46, english: [11...42]),
        ]),
        ArticleSection("THE DOOR THAT WAS BROKEN", [
            .longOnly(.text("Umar (may Allah be pleased with him) knew what he was holding back. Hudhayfah ibn al-Yamaan (may Allah be pleased with him) once told him about the trial that would surge like the waves of the sea, and that there was a closed door between Umar and it. Umar asked whether the door would be opened or broken:")),
            .longOnly(.hadith("bukhari:525", cite: "Saheeh al-Bukhaari 525, Saheeh Muslim 144", arabic: 89...125, english: [130...207])),
            .longOnly(.text("He used to pray, “O Allah! Grant me martyrdom in Your cause, and let my death be in the city of Your Apostle” (Saheeh al-Bukhaari 1890).")),
            .shortOnly(.text("Umar (may Allah be pleased with him) used to ask Allah for martyrdom in the city of His Messenger:")),
            .hadith("bukhari:1890", cite: "Saheeh al-Bukhaari 1890", arabic: 29...42, english: [0...20]),
            .text("In Dhul-Hijjah 23 AH (November 644 CE), as he began the dawn prayer, Abu Lu’lu’ah, a Persian slave of al-Mugheerah ibn Shu‘bah, stabbed him with a two-bladed dagger, then struck thirteen others as he fled, seven of whom died, and killed himself when he was caught. Umar pulled Abd ar-Rahman ibn Awf forward to finish the prayer. When he learned who had struck him, he said:"),
            .hadith("bukhari:3700", cite: "Saheeh al-Bukhaari 3700", arabic: 255...264, english: [416...441]),
            .text("He was carried home. A young man came in and praised him for his companionship of the Prophet, his precedence in Islam, his justice as caliph and now his martyrdom. Umar answered:"),
            .hadith("bukhari:3700", cite: "Saheeh al-Bukhaari 3700", arabic: 369...376, english: [668...686]),
            .longOnly(.text("Even then, seeing that the young man’s garment trailed on the ground, he called him back and told him to raise it. He had his debts counted, about eighty-six thousand, and ordered them paid from his own family’s property. He sent his son Abdullah to Aa’ishah to ask whether he might be buried beside his two companions, telling him not to call him Commander of the Believers, since today he was not their commander. She was weeping when Abdullah came in, and she said:")),
            .shortOnly(.text("He sent his son Abdullah to Aa’ishah to ask whether he might be buried beside his two companions. She was weeping when Abdullah came in, and she said:")),
            .hadith("bukhari:3700", cite: "Saheeh al-Bukhaari 3700", arabic: 495...502, english: [931...947]),
            .longOnly(.text("He named six men to choose his successor from among themselves, the men with whom the Prophet had been pleased when he died: Ali, Uthmaan, az-Zubayr, Talhah, Sa‘d and Abd ar-Rahman ibn Awf (may Allah be pleased with them). He left instructions for whoever came next: to know the rights of the Muhaajiroon, to be good to the Ansaar, and to keep faith with the non-Muslims under the protection of Allah and His Messenger, fighting for them and not burdening them beyond their means. He died a few days after he was struck, at sixty-three (Saheeh Muslim 2352), and was buried beside the Prophet and Abu Bakr.")),
            .longOnly(.hadith("muslim:2352a", cite: "Saheeh Muslim 2352", arabic: 51...74, english: [34...62])),
            .shortOnly(.text("He named six men to choose his successor from among themselves, the men with whom the Prophet had been pleased when he died: Ali, Uthmaan, az-Zubayr, Talhah, Sa‘d and Abd ar-Rahman ibn Awf (may Allah be pleased with them). He died a few days after he was struck, at sixty-three, and was buried beside the Prophet and Abu Bakr.")),
            .text("As his body lay on its bier, Ali ibn Abi Taalib (may Allah be pleased with him) came up behind Ibn Abbaas, took him by the shoulder, and said:"),
            .hadith("bukhari:3685", cite: "Saheeh al-Bukhaari 3685, Saheeh Muslim 2389", arabic: 43...89, english: [61...133]),
            .door(.article("CaliphatesView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Did Umar accept Islam after reading Surah Ta-Ha at his sister’s house?**"),
            .text("The story that he struck his sister, read a page of Ta-Ha in her hand and went straight to the Prophet is famous, but its chain is weak, so it is not told here. What is sound is enough: the Prophet’s prayer for him by name, the uproar at his door, and Ibn Mas‘ood’s words that the Muslims were strong from that day."),
            .longOnly(.markdown("**Did Umar bury a daughter alive before Islam?**")),
            .longOnly(.text("There is no chain for this at all, sound or weak, in the books of hadith or the early histories. His eldest daughter Hafsah (may Allah be pleased with her) was born before Islam, grew up in his house, and became a wife of the Prophet. The same caution applies to the story of a woman who corrected him in the mosque about the limit of the dowry: it is widely repeated, but its chain is broken.")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Umar was the answer to the Prophet’s own prayer: an enemy of Islam who became its strength. Revelation agreed with him, the Prophet called him inspired and saw him in his dreams with knowledge and religion, and Satan avoided his road. As caliph he took the treasures of Kisra and Caesar and spent them on the Muslims, founded the institutions of the state, and feared being asked about a single widow or a single stretch of land. He died a martyr at the dawn prayer, asked to be no more than even, and was buried beside the Prophet and Abu Bakr, as Ali had always expected."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Al-Faarooq", arabic: "الفَارُوق", meaning: "**The one who separates** truth from falsehood: the title Umar came to be known by, from the root **ف-ر-ق**, to separate."),
            .term("Muhaddath", arabic: "مُحَدَّث", meaning: "An **inspired** man, one to whom the right judgment is cast into his heart without revelation. The Prophet said that if there were one in his ummah, it was Umar (Saheeh al-Bukhaari 3689)."),
            .term("Deewaan", arabic: "دِيوَان", meaning: "The **register** Umar founded, listing the Muslims and their yearly stipends from the treasury, ranked by precedence in Islam."),
            .term("Ameer al-Mu’mineen", arabic: "أَمِيرُ المُؤمِنِين", meaning: "**Commander of the Believers**: the title of the caliph, first used for Umar."),
        ]),
    ]
}

struct CompanionUthmanView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionUthmanView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Uthmaan ibn Affaan")
        .englishArticle().selectableArticleList(article: "CompanionUthmanView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Uthmaan ibn Affaan (may Allah be pleased with him) was one of the first to accept Islam, married two daughters of the Prophet Muhammad (peace and blessings be upon him) one after the other and so was called Dhun-Noorayn, and emigrated twice for his religion. His wealth bought a well for the Muslims and equipped an army, and the Prophet promised him Paradise more than once, along with a trial that would come to him. As the third caliph he ruled for twelve years and united the ummah on one written mushaf. Rebels besieged him in his house in 35 AH, and he forbade the Companions to fight for him and was killed reading the Quran."),
        ]),
        ArticleSection("A MODEST MAN OF BANU UMAYYAH", [
            .shortOnly(.text("Uthmaan (may Allah be pleased with him) was the son of Affaan of Banu Umayyah, and through his mother the son of the Prophet’s cousin. He grew wealthy in trade, was known in Makkah for his gentleness and above all his modesty, and accepted Islam early, through Abu Bakr.")),
            .longOnly(.text("Uthmaan (may Allah be pleased with him) was the son of Affaan ibn Abi al-As of Banu Umayyah, the clan that would later lead Quraysh against Islam, and his line meets the Prophet’s (peace be upon him) at Abd Manaaf. His mother, Arwa bint Kurayz, was the daughter of the Prophet’s aunt Umm Hakeem bint Abd al-Muttalib, so he was the son of the Prophet’s cousin. He was born about six years after the Year of the Elephant, grew wealthy in trade, and was known in Makkah for his gentleness, his good looks and above all his modesty.")),
            .longOnly(.text("He accepted Islam early, through Abu Bakr, as the seerah records. Late in life, when a young man came to him with advice, he summed up his own story in words that are in Saheeh al-Bukhaari:")),
            .longOnly(.hadith("bukhari:3696", cite: "Saheeh al-Bukhaari 3696", arabic: 143...182, english: [205...278])),
        ]),
        ArticleSection("THE TWO LIGHTS AND THE TWO EMIGRATIONS", [
            .shortOnly(.markdown("He married Ruqayyah (may Allah be pleased with her), the Prophet’s daughter, and the two of them were among the first Muslims to emigrate to Abyssinia; later they emigrated again, to Madinah. When Ruqayyah died in 2 AH, the Prophet (peace be upon him) married him to his second daughter, Umm Kulthoom. That is why he was called **Dhun-Noorayn (ذُو النُّورَين)**, the possessor of the two lights.")),
            .longOnly(.markdown("He married Ruqayyah (may Allah be pleased with her), the Prophet’s daughter, and in the fifth year of the mission the two of them were among the first Muslims to emigrate to Abyssinia to escape the persecution in Makkah; later they emigrated again, to Madinah. In 2 AH, as the Muslims set out for Badr, Ruqayyah lay gravely ill, and the Prophet (peace be upon him) told Uthmaan to stay and nurse her, and counted him among the men of Badr in reward and share. She died while the army was away. The Prophet then married him to his second daughter, Umm Kulthoom, who lived with him until her death in 9 AH. That is why he was called **Dhun-Noorayn (ذُو النُّورَين)**, the possessor of the two lights.")),
            .longOnly(.text("Years after his death a man from Egypt came on pilgrimage, found Abdullah ibn Umar (may Allah be pleased with him) sitting with men of Quraysh, and tried to make him admit three charges against Uthmaan: that he had fled at Uhud, missed Badr, and missed the Pledge of Ridwaan. Ibn Umar agreed that all three had happened, the man cried “Allahu Akbar” in triumph, and Ibn Umar answered him:")),
            .longOnly(.hadith("bukhari:3698", cite: "Saheeh al-Bukhaari 3698", arabic: 86...196, english: [152...349])),
            .longOnly(.text("Of Uhud, Ibn Umar was pointing to the Quran’s own words about those who turned back when the archers left their posts and the army broke:")),
            .longOnly(.ayah("3:155", words: 13...16)),
            .longOnly(.text("And of the pledge: Uthmaan had been sent into Makkah as the Prophet’s envoy because he had kin there to protect him, and the pledge was given when the rumour came that he had been killed. The Prophet held up his own right hand and said, “This is Uthmaan’s hand,” and struck it on his other hand. No one else at al-Hudaybiyah had the Prophet’s hand pledge on his behalf.")),
        ]),
        ArticleSection("WHAT HIS WEALTH BOUGHT", [
            .shortOnly(.text("When the Muslims arrived in Madinah, the only sweet water was the well of Roomah, and Uthmaan (may Allah be pleased with him) bought it for the Muslims when the Prophet asked who would. In 9 AH, when the Prophet called for the equipping of the army of hardship to Tabook, Abd ar-Rahman ibn Samurah (may Allah be pleased with him) watched Uthmaan bring a thousand dinars and pour them into the Prophet’s lap:")),
            .longOnly(.text("When the Muslims arrived in Madinah, the only sweet water was the well of Roomah, owned by a man who sold its water. The Prophet asked who would buy it and put his bucket in it with the buckets of the Muslims, in exchange for better than it in Paradise. When the mosque grew too small, he asked who would buy the neighbouring plot and add it to the mosque. In 9 AH, with the Byzantines massing in the north, a drought on the land and the harvest not yet in, he called for the equipping of the expedition to Tabook, the army of hardship. Uthmaan (may Allah be pleased with him) answered each call. Abd ar-Rahman ibn Samurah (may Allah be pleased with him) watched him bring a thousand dinars and pour them into the Prophet’s lap:")),
            .hadith("tirmidhi:3701", cite: "Jaami‘ at-Tirmidhi 3701; graded hasan by al-Albaani", arabic: 72...90, english: [47...70]),
            .longOnly(.text("Decades later, besieged in his own house, Uthmaan would remind the men outside of these things one by one, and the Companions among them confirmed every one:")),
            .longOnly(.hadith("bukhari:2778", cite: "Saheeh al-Bukhaari 2778", arabic: 25...69, english: [20...84])),
        ]),
        ArticleSection("THE ONE THE ANGELS ARE SHY OF", [
            .shortOnly(.text("His modesty was a thing the Prophet himself honoured. Aa’ishah (may Allah be pleased with her) narrates that the Prophet, lying in her room with his thigh or shin uncovered, stayed as he was when Abu Bakr and then Umar came in, but sat up and arranged his clothes when Uthmaan (may Allah be pleased with him) asked permission. When she asked him why, he said:")),
            .longOnly(.text("His modesty was a thing the Prophet himself honoured. Aa’ishah (may Allah be pleased with her) narrates that the Prophet was once lying in her room with his thigh or shin uncovered. Abu Bakr asked to come in and talked with him as he was, then Umar, and the Prophet stayed as he was. Then Uthmaan (may Allah be pleased with him) asked permission, and the Prophet sat up and arranged his clothes. When Aa’ishah asked him why, he said:")),
            .hadith("muslim:2401", cite: "Saheeh Muslim 2401", arabic: 128...134, english: [155...167]),
            .text("The Prophet also told him what was coming. Abu Moosa al-Ash‘ari (may Allah be pleased with him) was guarding the gate of a walled garden where the Prophet sat, and three men asked to enter in turn:"),
            .hadith("bukhari:3695", cite: "Saheeh al-Bukhaari 3695, Saheeh Muslim 2403", arabic: 41...77, english: [36...113]),
            .longOnly(.text("Another day the Prophet climbed Uhud with Abu Bakr, Umar and Uthmaan, and when the mountain shook he told it to be firm, for on it stood a prophet, a siddeeq and two martyrs (Saheeh al-Bukhaari 3675). Both Umar and Uthmaan would die by the hands of murderers.")),
            .longOnly(.hadith("bukhari:3675", cite: "Saheeh al-Bukhaari 3675", arabic: 26...43, english: [0...45])),
        ]),
        ArticleSection("TWELVE YEARS AS CALIPH", [
            .shortOnly(.text("Umar, dying, left the choice of his successor to six men, and Abd ar-Rahman ibn Awf (may Allah be pleased with him) spent three nights consulting the Muhaajiroon, the Ansaar and the commanders before giving his pledge to Uthmaan, after which everyone pledged, Ali (may Allah be pleased with him) among them. Ahl as-Sunnah take their order of the caliphs from that choice. Uthmaan ruled from 24 to 35 AH (644–656 CE); the conquests went on, to North Africa, Armenia, Khuraasaan and Cyprus, and at home he enlarged the Prophet’s mosque and rebuilt it in stone.")),
            .longOnly(.text("Umar, dying, left the choice of his successor to six men, and Abd ar-Rahman ibn Awf (may Allah be pleased with him) spent three nights consulting the Muhaajiroon, the Ansaar and the commanders before giving his pledge to Uthmaan, after which everyone pledged (Saheeh al-Bukhaari 7207). Ali (may Allah be pleased with him) was among those who pledged to him. Ahl as-Sunnah take their order of the caliphs from that choice. Ibn Taymiyyah (may Allah have mercy on him) notes in al-Aqeedah al-Waasitiyyah that some early Sunni scholars, after agreeing that Abu Bakr and Umar came first, differed over whether Uthmaan or Ali was the more excellent, and that the position of Ahl as-Sunnah settled on Uthmaan, then Ali. He adds that this question of excellence is not one over which a dissenter is called misguided; the order of the caliphate is, and whoever disputes the caliphate of any of the four has gone astray.")),
            .longOnly(.hadith("bukhari:7207", cite: "Saheeh al-Bukhaari 7207", arabic: 187...231, english: [306...423])),
            .longOnly(.text("Uthmaan ruled from 24 to 35 AH (644–656 CE). The conquests went on: North Africa as far as Tunisia, Armenia, Khuraasaan, and Cyprus, reached by the first Muslim fleet, which Mu‘aawiyah built and sent with Uthmaan’s permission. At home he enlarged the Prophet’s mosque and rebuilt it in stone:")),
            .longOnly(.hadith("bukhari:446", cite: "Saheeh al-Bukhaari 446", arabic: 69...87, english: [64...95])),
            .longOnly(.text("And as Madinah grew, he added a call to prayer for Jumuah, given beforehand from az-Zawraa’ in the market, so the people would gather in time (Saheeh al-Bukhaari 912). Both were changes of a building and a timing, made for the needs of a city many times larger than the one the Prophet had left, and the Companions accepted them.")),
            .longOnly(.hadith("bukhari:912", cite: "Saheeh al-Bukhaari 912", arabic: 14...53, english: [0...57])),
            .longOnly(.text("He was gentle, and he was criticised for it, above all for appointing men of his own clan as governors. But when his own half-brother al-Waleed ibn Uqbah, governor of Koofah, was proved to have drunk wine, Uthmaan had him flogged, and he gave the task to Ali:")),
            .longOnly(.hadith("bukhari:3696", cite: "Saheeh al-Bukhaari 3696", arabic: 208...227, english: [317...356])),
            .shortOnly(.text("He was gentle, and he was criticised for it, above all for appointing men of his own clan as governors. But when his own half-brother al-Waleed ibn Uqbah, governor of Koofah, was proved to have drunk wine, Uthmaan had him flogged.")),
        ]),
        ArticleSection("ONE MUSHAF FOR THE UMMAH", [
            .text("The deed for which every Muslim since owes him most came in about 25 AH. Hudhayfah ibn al-Yamaan (may Allah be pleased with him) returned from campaigning in Armenia and Azerbaijan alarmed at how the soldiers from Syria and Iraq were disputing over the recitation of the Quran:"),
            .hadith("bukhari:4987", cite: "Saheeh al-Bukhaari 4987", arabic: 38...142, english: [50...217]),
            .shortOnly(.text("The sheets gathered under Abu Bakr were the source, Zayd ibn Thaabit (may Allah be pleased with him) led the work, and the copies went to the great cities with reciters to teach from them. The ummah has recited from that text ever since.")),
            .longOnly(.text("The sheets gathered under Abu Bakr were the source; Zayd ibn Thaabit (may Allah be pleased with him), who had written the revelation for the Prophet and had gathered those sheets, led the work; and the copies went to the great cities with reciters to teach from them. Burning the rest was a protection, not a loss: private copies held a Companion’s own notes and explanations beside the text, or aayaat whose recitation had later been lifted, and once the agreed copies existed, nothing could be confused with them. Ali (may Allah be pleased with him) later forbade people to speak of Uthmaan except with good, saying that he had done nothing about the copies except in consultation with the Companions; Ibn Abi Daawood (may Allah have mercy on him) records it in Kitaab al-Masaahif, and Ibn Hajar graded its chain saheeh. The ummah has recited from that text ever since. How these copies relate to the seven ahruf in which the Quran was revealed is explained in its own chapter.")),
            .door(.article("CompileView")),
            .door(.article("AhrufView")),
        ]),
        ArticleSection("THE DAY OF THE HOUSE", [
            .shortOnly(.text("In his last years complaint against his governors spread in the garrison cities, and in 35 AH bands of rebels from Egypt, Koofah and Basrah came to Madinah, surrounded his house and cut off his water. The Prophet had told him long before:")),
            .longOnly(.text("In his last years complaint against his governors spread in the garrison cities, fed by agitators the historians name, and in 35 AH bands of rebels from Egypt, Koofah and Basrah came to Madinah. He answered their grievances and they left, then returned and surrounded his house. They cut off his water; he reminded them from his roof that he had bought the well of Roomah for the Muslims and now could not drink from it (Jaami‘ at-Tirmidhi 3703).")),
            .longOnly(.hadith("tirmidhi:3703", cite: "Jaami‘ at-Tirmidhi 3703; graded hasan by al-Albaani", arabic: 65...124, english: [44...147])),
            .longOnly(.text("The Prophet had told him long before:")),
            .hadith("tirmidhi:3705", cite: "Jaami‘ at-Tirmidhi 3705; graded saheeh by al-Albaani", arabic: 42...55, english: [5...29]),
            .shortOnly(.text("The shirt was the caliphate. So he would not take it off at the rebels’ demand, and neither would he spill Muslim blood to keep it: men of the Muhaajiroon and the Ansaar and their sons came to defend him, and he sent them away and told them to put down their weapons. His freedman Abu Sahlah heard him say:")),
            .longOnly(.text("The shirt was the caliphate. So he would not take it off at the rebels’ demand, and neither would he spill Muslim blood to keep it. Men of the Muhaajiroon and the Ansaar and their sons, among them al-Hasan ibn Ali and Abdullah ibn az-Zubayr (may Allah be pleased with them), came to defend him, and he sent them away and told them to put down their weapons. He knew what was coming. In the Prophet’s last illness he had called Uthmaan (may Allah be pleased with him) to him alone and spoken to him at length while Uthmaan’s face changed, and on the Day of the House Uthmaan said that the Messenger of Allah had told him what would happen and that he would bear it with patience (Sunan Ibn Maajah 113).")),
            .longOnly(.hadith("ibnmajah:113", cite: "Sunan Ibn Maajah 113; graded saheeh by al-Albaani", arabic: 25...124, english: [0...145])),
            .longOnly(.text("His freedman Abu Sahlah heard him say:")),
            .hadith("tirmidhi:3711", cite: "Jaami‘ at-Tirmidhi 3711; graded saheeh by al-Albaani", arabic: 30...43, english: [11...27]),
            .text("On the eighteenth of Dhul-Hijjah, 35 AH (June 656 CE), the rebels broke in and killed him, an old man in his eighties, with the mushaf open before him. He was buried in al-Baqee‘. A Companion had heard the Prophet describe the trials to come and point to a man passing by, wrapped in his cloak:"),
            .hadith("tirmidhi:3704", cite: "Jaami‘ at-Tirmidhi 3704; graded saheeh by al-Albaani", arabic: 58...83, english: [66...110]),
            .longOnly(.text("Sa‘eed ibn Zayd (may Allah be pleased with him), one of the ten promised Paradise, said afterwards in the mosque of Koofah that if Mount Uhud were to crumble for what had been done to Uthmaan, it would have every right to crumble (Saheeh al-Bukhaari 3862). With Umar’s death the door Hudhayfah had described was broken; with Uthmaan’s murder the trial behind it poured through, and it was never closed again.")),
            .longOnly(.hadith("bukhari:3862", cite: "Saheeh al-Bukhaari 3862", arabic: 35...45, english: [34...65])),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Did Uthmaan favour his relatives?**")),
            .longOnly(.text("He appointed some men of his clan, as the Prophet had appointed Attaab ibn Aseed of Banu Umayyah over Makkah and Umar had kept Mu‘aawiyah over Syria; kinship does not make a capable man unfit. When one of them sinned, he did not shield him: he had his own brother flogged. The charges raised against him, about his governors, his gifts, his prayer at Mina and the rest, were answered one by one by Abu Bakr ibn al-Arabi in al-Awaasim min al-Qawaasim and by Ibn Taymiyyah in Minhaaj as-Sunnah (may Allah have mercy on them), and the Companions who knew him best, Ali among them, never counted any of them against him.")),
            .markdown("**Who killed Uthmaan?**"),
            .text("Rebels from the garrison cities, not the Companions. The senior Companions in Madinah sent their sons to guard his door, and it was Uthmaan who would not let them fight. Ahl as-Sunnah hold that he was killed unjustly, a martyr, as the Prophet foretold, and that he was upon guidance in the trial, as the Prophet said."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Uthmaan accepted Islam early, emigrated twice, and married two daughters of the Prophet. His wealth gave Madinah its water and equipped the army of hardship, and the Prophet said nothing he did afterwards would harm him. The angels were shy of him, and he was promised Paradise with a calamity. As caliph he enlarged the mosque, carried the conquests on, punished his own brother, and gave the ummah one written mushaf. Besieged by rebels, he kept the Prophet’s covenant, refused both to resign and to let Muslims die for him, and was killed with the Quran before him."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Dhun-Noorayn", arabic: "ذُو النُّورَين", meaning: "**The possessor of the two lights**: Uthmaan’s title, because he married two daughters of the Prophet, Ruqayyah and then Umm Kulthoom."),
            .term("Jaysh al-Usrah", arabic: "جَيشُ العُسرَة", meaning: "**The army of hardship**: the expedition to Tabook in 9 AH, raised in heat and drought, which Uthmaan equipped from his own wealth."),
            .term("Mushaf", arabic: "مُصحَف", meaning: "A **written copy of the Quran** bound between two covers. The copies Uthmaan sent to the cities are the source of every mushaf in the world today."),
            .term("Yawm ad-Daar", arabic: "يَومُ الدَّار", meaning: "**The Day of the House**: the siege of Uthmaan in his home in 35 AH and his killing there."),
        ]),
    ]
}

struct CompanionAliView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionAliView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ali ibn Abi Taalib")
        .englishArticle().selectableArticleList(article: "CompanionAliView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Ali ibn Abi Taalib (may Allah be pleased with him) was the cousin of the Prophet Muhammad (peace and blessings be upon him), raised in his house, the first boy to believe, the husband of Faatimah and the father of al-Hasan and al-Husayn. He fought at the front of every battle, was given the banner at Khaybar as a man who loves Allah and His Messenger and whom they love, and was to the Prophet as Haaroon was to Moosa, except that there is no prophet after him. Ahl as-Sunnah love him as the fourth rightly guided caliph and one of the Prophet’s household, read Ghadeer Khumm as a command to love and support him, not a text of succession, and take his own word that Abu Bakr and Umar were the best of the ummah. He was killed by a Kharijite in 40 AH."),
        ]),
        ArticleSection("RAISED IN THE PROPHET'S HOUSE", [
            .shortOnly(.text("Ali (may Allah be pleased with him) was the son of Abu Taalib, the uncle who raised the Prophet (peace be upon him), and of Faatimah bint Asad of Banu Haashim. When a hard year fell on Makkah, the Prophet took the young Ali into his own home, and he grew up there.")),
            .longOnly(.text("Ali (may Allah be pleased with him) was the son of Abu Taalib, the uncle who raised the Prophet (peace be upon him) after his grandfather died, and of Faatimah bint Asad (may Allah be pleased with her), also of Banu Haashim, who later accepted Islam and emigrated. When a hard year fell on Makkah and Abu Taalib, with many children, was struggling, the Prophet took the young Ali into his own home, as the seerah records, and he grew up there. Abu Taalib protected his nephew to the end of his life, but at his death he refused the testimony of faith and died upon the religion of Abd al-Muttalib, and the Prophet was forbidden to seek forgiveness for him (Saheeh al-Bukhaari 3884). Faith is not inherited, even in the noblest house.")),
            .longOnly(.hadith("bukhari:3884", cite: "Saheeh al-Bukhaari 3884", arabic: 14...109, english: [0...163])),
            .text("Ali was about ten when the revelation began, and he believed. The scholars reconcile the reports of who was first in this way: Khadeejah was the first of all, Abu Bakr the first free man, Zayd ibn Haarithah the first freed slave, and Ali the first boy."),
            .longOnly(.text("On the night of the Hijrah, when the men of Quraysh waited outside the Prophet’s house to kill him, Ali lay down in his bed under his green cloak so that the watchers would think he was still there, and he stayed behind in Makkah for some days to return to their owners the goods people had left in the Prophet’s keeping, as the seerah records. Then he followed him to Madinah.")),
            .shortOnly(.text("On the night of the Hijrah, when the men of Quraysh waited outside the Prophet’s house to kill him, Ali lay down in his bed under his green cloak so that the watchers would think he was still there, and later followed him to Madinah.")),
        ]),
        ArticleSection("FAATIMAH AND ABU TURAAB", [
            .shortOnly(.text("In 2 AH Ali married Faatimah (may Allah be pleased with her), the Prophet’s youngest daughter. He had almost nothing to give her but his armour; their house was poor, and they were happy in it. The Prophet once found him asleep in the mosque after a disagreement with Faatimah, wiped the dust from his back and called him Abu Turaab, “father of dust,” the name Ali loved best.")),
            .longOnly(.text("In 2 AH Ali (may Allah be pleased with him) married Faatimah (may Allah be pleased with her), the Prophet’s youngest daughter. He had almost nothing; the Prophet asked him what he could give her, and when he said he had nothing, the Prophet asked where his armour was, and told him to give her that (Sunan an-Nasaa’i 3375). Their house was poor, and they were happy in it.")),
            .longOnly(.hadith("nasai:3375", cite: "Sunan an-Nasaa’i 3375; graded hasan saheeh by al-Albaani", arabic: 23...61, english: [0...53])),
            .longOnly(.text("Years later, under the Umayyads, a man came to the Companion Sahl ibn Sa‘d (may Allah be pleased with him) to complain that the governor of Madinah was insulting Ali from the pulpit by calling him Abu Turaab, “father of dust.” Sahl laughed, and told him where the name came from:")),
            .longOnly(.hadith("bukhari:3703", cite: "Saheeh al-Bukhaari 3703", arabic: 41...111, english: [48...165])),
            .longOnly(.text("Ali had gone out after some disagreement with Faatimah and fallen asleep in the mosque, and the Prophet himself came to find him and wiped the dust from his back. The name the governor meant as a slur was the one Ali loved best.")),
            .longOnly(.text("Ali narrated his own failings too. One night the Prophet came to his door and Faatimah’s and asked whether they would not pray. Ali answered that their souls were in Allah’s hand, and if He willed to wake them He would:")),
            .longOnly(.hadith("bukhari:1127", cite: "Saheeh al-Bukhaari 1127, Saheeh Muslim 775", arabic: 57...77, english: [51...79])),
            .longOnly(.text("The Prophet did not scold him. He turned away striking his thigh, reciting the end of 18:54, that man is the most argumentative of things. And Ali told the story against himself, and his son al-Husayn passed it on.")),
            .longOnly(.ayah("18:54", words: 9...13)),
        ]),
        ArticleSection("THE BANNER AT KHAYBAR", [
            .shortOnly(.text("Ali fought at the front of every battle from Badr on, and in 7 AH, when the Muslims had besieged the fortresses of Khaybar for days, the Prophet said:")),
            .longOnly(.text("At Badr, the first battle, three men of Quraysh stepped out and demanded champions, and the Prophet (peace be upon him) sent out Hamzah, Ali and Ubaydah ibn al-Haarith (may Allah be pleased with them). Ali killed his man. He would say of that day that he would be the first to kneel before the Most Merciful to plead his case on the Day of Resurrection, and the ayah “These are two adversaries who have disputed over their Lord” came down about those six men (Saheeh al-Bukhaari 3965; 22:19). He fought at Uhud and at the Trench, and in 7 AH came Khaybar.")),
            .longOnly(.hadith("bukhari:3965", cite: "Saheeh al-Bukhaari 3965", arabic: 31...72, english: [9...90])),
            .longOnly(.ayah("22:19")),
            .longOnly(.text("The Muslims had besieged the fortresses of Khaybar for days. The Prophet said that the next day he would give the banner to a man through whose hands Allah would give victory, a man who loves Allah and His Messenger and whom Allah and His Messenger love (Saheeh al-Bukhaari 4210).")),
            .hadith("bukhari:4210", cite: "Saheeh al-Bukhaari 4210", arabic: 33...47, english: [9...40]),
            .text("Every man hoped it would be him. In the morning the Prophet asked for Ali, who was suffering with his eyes:"),
            .hadith("bukhari:2942", cite: "Saheeh al-Bukhaari 2942, Saheeh Muslim 2406", arabic: 63...104, english: [86...171]),
            .longOnly(.text("Red camels were the most prized wealth of the Arabs. The commander who was about to conquer a fortress was told that guiding one man was worth more than all of it, and that the first thing to offer Khaybar was Islam.")),
        ]),
        ArticleSection("AS HAAROON WAS TO MOOSA", [
            .shortOnly(.text("In 9 AH the Prophet (peace be upon him) marched to Tabook and left Ali in charge of his family and of Madinah, and Ali, hurt by what the hypocrites were saying, caught up with the army:")),
            .longOnly(.text("In 9 AH the Prophet (peace be upon him) marched to Tabook and left Ali (may Allah be pleased with him) behind in charge of his family and of Madinah. The hypocrites, as the seerah records, said he had been left behind as a burden, and Ali caught up with the army, hurt:")),
            .hadith("bukhari:4416", cite: "Saheeh al-Bukhaari 4416, Saheeh Muslim 2404", arabic: 27...47, english: [16...53]),
            .longOnly(.text("The comparison is exact. When Moosa went up to the appointment with his Lord, he left Haaroon in charge of his people for forty nights:")),
            .longOnly(.ayah("7:142", words: 12...18)),
            .longOnly(.text("It is a great honour: of all his Companions, Ali was the one the Prophet likened to a prophet’s brother and deputy. But it is the honour of a deputy in absence, not of a successor after death. Haaroon died before Moosa and never succeeded him. The Prophet also left others in charge of Madinah on other campaigns, Ibn Umm Maktoom among them (Sunan Abi Daawood 2931), and no one counted that as a caliphate. And the hadith closes the door it might seem to open: there is no prophet after me.")),
            .shortOnly(.text("It is a great honour, but the honour of a deputy in absence, not of a successor after death. Haaroon died before Moosa and never succeeded him. And the hadith closes the door it might seem to open: there is no prophet after me.")),
            .longOnly(.hadith("abudawud:2931", cite: "Sunan Abi Daawood 2931; graded saheeh by al-Albaani", arabic: 18...30, english: [0...15])),
            .longOnly(.text("Later that year Abu Bakr (may Allah be pleased with him) led the pilgrimage, and the Prophet sent Ali after him to proclaim the opening of Surat at-Tawbah at Mina; Abu Hurayrah (may Allah be pleased with him), one of Abu Bakr’s criers, says Ali proclaimed it along with them (Saheeh al-Bukhaari 369).")),
            .longOnly(.hadith("bukhari:369", cite: "Saheeh al-Bukhaari 369", arabic: 54...86, english: [70...123])),
            .longOnly(.text("He also sent Ali to Yemen as a judge:")),
            .longOnly(.hadith("ibnmajah:2310", cite: "Sunan Ibn Maajah 2310; graded saheeh by al-Albaani", arabic: 20...65, english: [0...69])),
        ]),
        ArticleSection("GHADEER KHUMM", [
            .shortOnly(.text("On the way back from the Farewell Pilgrimage in 10 AH, the Prophet (peace be upon him) stopped at a pool called Khumm and addressed the people. Some of the men who had served under Ali (may Allah be pleased with him) in Yemen had been complaining of his strictness over the spoils, and Buraydah admitted to the Prophet that he had come to dislike him:")),
            .longOnly(.text("On the way back from the Farewell Pilgrimage in 10 AH, the Prophet (peace be upon him) stopped at a pool called Khumm between Makkah and Madinah and addressed the people. Some of the men who had served under Ali (may Allah be pleased with him) in Yemen had been complaining of his strictness over the spoils; Buraydah admitted to the Prophet that he had come to dislike Ali, and the Prophet told him not to (Saheeh al-Bukhaari 4350).")),
            .hadith("bukhari:4350", cite: "Saheeh al-Bukhaari 4350", arabic: 49...79, text: "When we reached the Prophet (ﷺ) I mentioned that to him. He said, “O Buraydah, do you hate Ali?” I said, “Yes.” He said, “Do not hate him, for he has more than that in the khumus.”"),
            .longOnly(.text("Zayd ibn Arqam (may Allah be pleased with him) remembered the sermon:")),
            .longOnly(.hadith("muslim:2408a", cite: "Saheeh Muslim 2408", arabic: 153...195, english: [176...245])),
            .longOnly(.text("In another sound narration he said:")),
            .shortOnly(.text("The words for which the day is remembered are these:")),
            .hadith("tirmidhi:3713", cite: "Jaami‘ at-Tirmidhi 3713; graded saheeh by al-Albaani", arabic: 40...44, english: [4...14]),
            .longOnly(.markdown("**Mawla (مَولَى)** is one of the widest words in Arabic. It can mean master, freed slave, cousin, ally, helper, neighbour, beloved and more. Ibn al-Atheer (may Allah have mercy on him) lists its meanings in an-Nihaayah and relays that ash-Shaafi‘i understood this hadith as the bond of Islam itself, the walaa’ that Allah names when He says He is the mawla of those who believe (47:11). The Prophet was telling the ummah, at the moment some had turned against Ali, that loving and supporting him is part of loving and supporting the Prophet. Ali himself said that the Prophet had promised him that only a believer would love him and only a hypocrite would hate him (Saheeh Muslim 78).")),
            .longOnly(.ayah("47:11", words: 0...5)),
            .longOnly(.hadith("muslim:#146", cite: "Saheeh Muslim 78", arabic: 35...57, english: [2...44])),
            .longOnly(.text("What the hadith does not say is that Ali was appointed caliph. The Prophet said it to a crowd of thousands; if it had been an appointment to rule, it would have been raised at the Saqeefah less than three months later by the Ansaar, by Banu Haashim, by Ali himself. Instead Ali gave his pledge to Abu Bakr, counselled Umar, and served Uthmaan. Ahl as-Sunnah take the hadith exactly as its words carry it: love and alliance for Ali and honour for the Prophet’s household, which they repeat in every prayer when they send blessings on the family of Muhammad.")),
            .shortOnly(.markdown("**Mawla (مَولَى)** is one of the widest words in Arabic: it can mean master, freed slave, cousin, ally, helper, neighbour, beloved and more. The Prophet was telling the ummah, at the moment some had turned against Ali, that loving and supporting him is part of loving and supporting the Prophet.")),
            .shortOnly(.text("What the hadith does not say is that Ali was appointed caliph. The Prophet said it to a crowd of thousands; had it been an appointment to rule, it would have been raised at the Saqeefah less than three months later, by Ali himself. Instead Ali gave his pledge to Abu Bakr, counselled Umar, and served Uthmaan.")),
            .door(.article("ShiaAnswerView")),
        ]),
        ArticleSection("HIS KNOWLEDGE AND HIS JUDGMENT", [
            .text("Umar (may Allah be pleased with him), who consulted him constantly, said of him:"),
            .hadith("bukhari:4481", cite: "Saheeh al-Bukhaari 4481", arabic: 25...28, english: [2...13]),
            .text("Because of his closeness to the Prophet, some people came to believe that Ali had been given a secret knowledge withheld from the others. He was asked about it directly, and he denied it with an oath:"),
            .hadith("bukhari:3047", cite: "Saheeh al-Bukhaari 3047", arabic: 26...67, english: [3...102]),
            .longOnly(.text("Nothing but the Quran, the understanding Allah gives a man in it, and one sheet of rulings on blood money and captives. Whoever claims that Ali held a hidden revelation contradicts Ali. His method was the Companions’ method: the text before opinion. He put it in one sentence about wiping over leather socks in ablution:")),
            .shortOnly(.text("Nothing but the Quran, the understanding Allah gives a man in it, and one sheet of rulings on blood money and captives. Whoever claims that Ali held a hidden revelation contradicts Ali.")),
            .longOnly(.hadith("abudawud:162", cite: "Sunan Abi Daawood 162; graded saheeh by al-Albaani", arabic: 27...49, english: [0...39])),
            .longOnly(.text("And he was plain about his own rank. His son Muhammad ibn al-Hanafiyyah asked him who was the best of people after the Prophet. Ali said Abu Bakr, then Umar; and when his son, afraid he would say Uthmaan next, asked “Then you?”, Ali said he was only an ordinary man among the Muslims (Saheeh al-Bukhaari 3671). At Umar’s bier he said that there was no one whose deeds he would rather meet Allah with than Umar’s (Saheeh al-Bukhaari 3685). Ibn Taymiyyah notes that Ali’s preference of Abu Bakr and Umar is reported from him by so many routes that it reaches the level of certainty.")),
            .shortOnly(.text("And he was plain about his own rank. His son Muhammad ibn al-Hanafiyyah asked him who was the best of people after the Prophet:")),
            .hadith("bukhari:3671", cite: "Saheeh al-Bukhaari 3671", arabic: 19...53, english: [0...49]),
            .longOnly(.hadith("bukhari:3685", cite: "Saheeh al-Bukhaari 3685, Saheeh Muslim 2389", arabic: 37...53, english: [53...86])),
        ]),
        ArticleSection("THE CALIPHATE IN A TIME OF TRIAL", [
            .shortOnly(.text("After Uthmaan was murdered in 35 AH, the people of Madinah pledged to Ali (may Allah be pleased with him), and he became the fourth caliph, inheriting a crime he had not committed and an ummah divided over how to answer it. In 36 AH came the Battle of the Camel against Aa’ishah, Talhah and az-Zubayr, which the leaders on both sides had been working to avoid, and in 37 AH Siffeen against Mu‘aawiyah and the people of Syria, where the fighting ended in a call for arbitration.")),
            .longOnly(.text("After Uthmaan was murdered in Dhul-Hijjah 35 AH, the people of Madinah pledged to Ali (may Allah be pleased with him), and he became the fourth caliph. He inherited a crime he had not committed and an ummah divided over how to answer it. Aa’ishah, Talhah and az-Zubayr (may Allah be pleased with them) went to Basrah demanding that Uthmaan’s killers be punished, and in 36 AH the armies met at the Battle of the Camel, a battle the leaders on both sides had been working to avoid. Talhah and az-Zubayr were killed; Ali treated Aa’ishah with honour and sent her back to Madinah under escort. In 37 AH he faced Mu‘aawiyah and the people of Syria at Siffeen; the fighting ended in a call for arbitration by the Quran. He moved his capital to Koofah, and never ruled without war.")),
            .text("Ahl as-Sunnah hold that Ali was the rightful caliph and nearer to the truth, that those who fought him were mujtahids who erred, and that the blood shed between them is a matter they leave to Allah while loving all of them. That position, and the reasons for it, is set out in the chapter on who the Companions are."),
            .door(.article("CompanionsIntroView")),
        ]),
        ArticleSection("THE KHAWAARIJ", [
            .shortOnly(.text("The arbitration produced a third party. Thousands in Ali’s own army declared that by accepting human arbiters he had judged by other than Allah’s law, and they declared him and all who accepted the arbitration disbelievers. When they began killing Muslims on the roads, Ali (may Allah be pleased with him) fought them at an-Nahrawaan in 38 AH. He had heard the Prophet describe them:")),
            .longOnly(.text("The arbitration produced a third party. Thousands in Ali’s own army declared that by accepting human arbiters he had judged by other than Allah’s law, and they declared him, Mu‘aawiyah and all who accepted the arbitration disbelievers. They camped at Harooraa’ near Koofah, which is why they were also called the Harooriyyah. Ali (may Allah be pleased with him) answered their slogan in four words:")),
            .longOnly(.hadith("muslim:1066g", cite: "Saheeh Muslim 1066", arabic: 53...92, english: [22...87])),
            .longOnly(.text("He sent Ibn Abbaas (may Allah be pleased with him) to debate them first, and an-Nasaa’i (may Allah have mercy on him) records that Ibn Abbaas reminded them that he came from the Companions of the Prophet, the Muhaajiroon and the Ansaar, upon whom the Quran had come down and who knew its meaning best, and that not one of them was among the Khawaarij; a large number returned. When the rest began killing Muslims on the roads, Ali fought them at an-Nahrawaan in 38 AH. He had heard the Prophet describe them, and he narrated it with an oath that he would rather fall from the sky than attribute to the Prophet what he had not said:")),
            .hadith("muslim:1066a", cite: "Saheeh Muslim 1066, Saheeh al-Bukhaari 3611", arabic: 73...112, english: [75...163]),
            .longOnly(.text("After the battle Ali had the dead searched for the man the Prophet had described, with a deformed hand; when they could not find him he sent them back, swearing that he had neither lied nor been lied to, until they found him among the ruins (Saheeh Muslim 1066). The Khawaarij were the first sect to split from the ummah, and their mark has never changed: much worship, little understanding, and the readiness to call Muslims disbelievers and spill their blood.")),
            .shortOnly(.text("The Khawaarij were the first sect to split from the ummah, and their mark has never changed: much worship, little understanding, and the readiness to call Muslims disbelievers and spill their blood.")),
        ]),
        ArticleSection("HIS MARTYRDOM", [
            .shortOnly(.text("In Ramadan 40 AH (January 661 CE), a Kharijite named Abd ar-Rahman ibn Muljam struck Ali (may Allah be pleased with him) with a poisoned sword as he went out to lead the dawn prayer in Koofah, and he died of the wound two days later, at about sixty-three.")),
            .shortOnly(.text("Two errors gathered around his name after him: some exalted him beyond all bounds, and others, the Nawaasib, nursed hostility to him and cursed him. Ahl as-Sunnah stand between them: they love Ali as the fourth of the rightly guided caliphs, the Prophet’s cousin and son-in-law, the father of the two leaders of the youth of Paradise, and a man Allah and His Messenger love; and they will not raise him above those he himself put ahead of him.")),
            .longOnly(.text("In Ramadan 40 AH (January 661 CE), a Kharijite named Abd ar-Rahman ibn Muljam struck Ali (may Allah be pleased with him) with a poisoned sword as he went out to lead the dawn prayer in Koofah. He died of the wound two days later, at about sixty-three. The historians record that he told his family to hold the attacker and treat him well, and that if he died, they should take one life for his life and not mutilate him. Where exactly in Koofah he was buried the historians do not agree.")),
            .longOnly(.text("Two errors gathered around his name after him. Some exalted him beyond all bounds. Al-Bukhaari records that a group of heretics was brought to Ali and he had them burned, and that Ibn Abbaas said he would have executed them instead, since the Prophet forbade punishing with fire (Saheeh al-Bukhaari 6922); Ibn Hajar (may Allah have mercy on him) relates in Fath al-Baari reports that these were men who had made a god of him. Others, the Nawaasib, nursed hostility to him and cursed him, as the governor did who mocked him as Abu Turaab. Ahl as-Sunnah stand between them: they love Ali as the fourth of the rightly guided caliphs, the Prophet’s cousin and son-in-law, the father of the two leaders of the youth of Paradise, and a man Allah and His Messenger love; and they will not raise him above those he himself put ahead of him.")),
            .longOnly(.hadith("bukhari:6922", cite: "Saheeh al-Bukhaari 6922", arabic: 15...54, english: [0...69])),
            .door(.article("AhlulBaytView")),
            .door(.article("CompanionFatimahView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Did the Prophet say, “I am the city of knowledge and Ali is its gate”?**"),
            .text("This saying is famous, but the critics of hadith judged it weak, and several of them, Ibn al-Jawzi (may Allah have mercy on him) among them, counted it fabricated. Ali’s knowledge is established without it, by Umar’s testimony and by Ali’s own judgments. The same is true of the story that the sun turned back in the sky so that Ali could pray, which the scholars rejected as fabricated, and of the tale that he alone lifted the gate of Khaybar, whose chains are weak."),
            .markdown("**Why did Ali not claim the caliphate when the Prophet died?**"),
            .text("Because he did not believe he had been appointed. He delayed his pledge to Abu Bakr for six months, and then gave it publicly and explained that he had held back from no envy (Saheeh al-Bukhaari 4240). A man of his courage did not hide his belief for twenty-five years under three caliphs; he served them because he held them to be rightful."),
            .hadith("bukhari:4240", cite: "Saheeh al-Bukhaari 4240", arabic: 330...371, english: [548...645]),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Ali grew up in the Prophet’s house, believed as a boy, slept in his bed on the night of the Hijrah, married Faatimah, and fought at the front from Badr to Khaybar, where he received the banner as one who loves Allah and His Messenger and is loved by them. He was to the Prophet as Haaroon was to Moosa, without prophethood, and at Ghadeer Khumm the Prophet bound the ummah to love him. He disowned any hidden knowledge, ranked Abu Bakr and Umar above himself, and as caliph bore the trial of civil war and fought the Khawaarij the Prophet had described, until one of them killed him at the dawn prayer."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Abu Turaab", arabic: "أَبُو تُرَاب", meaning: "**The father of dust**: the name the Prophet gave Ali when he found him asleep in the mosque covered in dust, and the name Ali loved best (Saheeh al-Bukhaari 3703)."),
            .term("Mawla", arabic: "مَولَى", meaning: "A word of many meanings, among them **ally, helper and beloved**. In “whomever I am his mawla, Ali is his mawla” Ahl as-Sunnah read the bond of love and support that joins the believers (47:11)."),
            .term("Khawaarij", arabic: "الخَوَارِج", meaning: "**Those who went out**: the sect that left Ali’s army after the arbitration, declared Muslims disbelievers for their sins, and was fought at an-Nahrawaan. Also called the **Harooriyyah**, after Harooraa’."),
            .term("Nawaasib", arabic: "النَّوَاصِب", meaning: "**Those who set up enmity** toward Ali and the Prophet’s household, the opposite error to the Raafidah’s excess."),
        ]),
    ]
}

// MARK: - companions-2

struct CompanionTenView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionTenView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Ten Promised Paradise")
        .englishArticle().selectableArticleList(article: "CompanionTenView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: in a single saying the Prophet Muhammad (peace and blessings be upon him) named ten of his Companions as people of Paradise: Abu Bakr, Umar, Uthmaan, Ali, Talhah, az-Zubayr, Abd ar-Rahman ibn Awf, Sa‘d ibn Abi Waqqaas, Sa‘eed ibn Zayd and Abu Ubaydah ibn al-Jarraah. All ten were men of Quraysh who believed in the first years at Makkah and emigrated for Allah’s sake. This chapter gives the hadith, the life of each of the six who are not among the four caliphs, and the many others whom the Prophet promised Paradise by name. It ends with what the promise asks of a Muslim: to testify to Paradise for those he testified for and for no one else by name, to love all of them, and to keep silent about what passed between them."),
        ]),
        ArticleSection("ONE SAYING, TEN NAMES", [
            .markdown("The ten are known as **al-Asharah al-Mubashsharoon bil-Jannah (العَشَرَةُ المُبَشَّرُونَ بِالجَنَّةِ)**, “the ten given the glad tidings of Paradise.” They are not the only people the Prophet (peace be upon him) promised Paradise, but they are the ones he named together in one list, and so the books of creed mention them as a group. Abd ar-Rahman ibn Awf (may Allah be pleased with him), himself one of them, narrated it:"),
            .hadith("tirmidhi:3747", cite: "Jaami‘ at-Tirmidhi 3747; graded saheeh by al-Albaani", arabic: 30...66, english: [7...58]),
            .longOnly(.text("Sa‘eed ibn Zayd (may Allah be pleased with him) narrated the same list, and at-Tirmidhi records that al-Bukhaari judged Sa‘eed’s chain the sounder of the two (Jaami‘ at-Tirmidhi 3748). Where Sa‘eed told it matters. He was in the great mosque of Koofah when a man there began to abuse Ali, and Sa‘eed stood up and protested that the Companions of the Messenger of Allah were being reviled in front of the people, then gave the list of the ten (Sunan Abi Daawood 4650). The hadith that names Abu Bakr, Umar and Uthmaan as people of Paradise was told in that city in defence of Ali. That is the Sunni position in a single scene: no Companion is honoured by insulting another.")),
            .longOnly(.hadith("abudawud:4650", cite: "Sunan Abi Daawood 4650; graded saheeh by al-Albaani", arabic: 45...115, english: [42...144])),
            .shortOnly(.text("Sa‘eed ibn Zayd (may Allah be pleased with him) narrated the same list in the great mosque of Koofah, standing up to protest when a man there began to abuse Ali. The hadith that names Abu Bakr, Umar and Uthmaan as people of Paradise was told in that city in defence of Ali. That is the Sunni position in a single scene: no Companion is honoured by insulting another.")),
            .text("All ten were of Quraysh, all believed early at Makkah, and all emigrated to Madinah. Four became the rightly guided caliphs; Abd ar-Rahman and Sa‘d came from Banu Zuhrah, the clan of the Prophet’s mother."),
            .longOnly(.text("They were also the men the Companions themselves trusted most. When Umar ibn al-Khattaab (may Allah be pleased with him) lay dying in 23 AH (644 CE), he left the choice of the next caliph to six men, naming them as those with whom the Messenger of Allah (peace be upon him) was pleased when he died: Ali, Uthmaan, az-Zubayr, Talhah, Sa‘d and Abd ar-Rahman. His own son Abdullah, he said, would attend only as a witness with no share in the rule (Saheeh al-Bukhaari 3700). Abu Bakr and Abu Ubaydah had died by then, and Sa‘eed ibn Zayd, Umar’s cousin, was not named.")),
            .longOnly(.hadith("bukhari:3700", cite: "Saheeh al-Bukhaari 3700", arabic: 612...630, english: [1153...1184])),
        ]),
        ArticleSection("THE FOUR CALIPHS AMONG THEM", [
            .shortOnly(.text("The first four names are the four caliphs, in the order the Companions ranked them: Abu Bakr, Umar, Uthmaan and Ali. Each of the four has a chapter of his own.")),
            .longOnly(.text("The first four names are the four caliphs, in the order the Companions ranked them. Ibn Umar (may Allah be pleased with them) said that in the Prophet’s lifetime they counted Abu Bakr as the best of them, then Umar, then Uthmaan (Saheeh al-Bukhaari 3655), and Ali, asked by his own son who was best after the Prophet, answered: Abu Bakr, then Umar (Saheeh al-Bukhaari 3671).")),
            .longOnly(.hadith("bukhari:3655", cite: "Saheeh al-Bukhaari 3655", arabic: 23...44, english: [0...31])),
            .longOnly(.hadith("bukhari:3671", cite: "Saheeh al-Bukhaari 3671", arabic: 19...53, english: [0...49])),
            .longOnly(.text("Each of the four has a chapter of his own in this library. Here it is enough to see that the Prophet gave three of them the same glad tidings on another day, one by one, at a garden gate, with Abu Moosa al-Ash‘ari keeping the door:")),
            .longOnly(.hadith("bukhari:3695", cite: "Saheeh al-Bukhaari 3695", arabic: 25...77, english: [0...113])),
            .longOnly(.text("The pause before Uthmaan’s glad tidings, and the calamity attached to it, came true in 35 AH (656 CE), when rebels besieged him in his house in Madinah and killed him. The same three once climbed Uhud with the Prophet, and when the mountain shook beneath them he told it to be still, for on it stood a prophet, a siddeeq and two martyrs (Saheeh al-Bukhaari 3675). Umar and Uthmaan were both killed as martyrs, and Ali, the fourth, was struck down in 40 AH (661 CE).")),
            .longOnly(.hadith("bukhari:3675", cite: "Saheeh al-Bukhaari 3675", arabic: 26...43, english: [0...45])),
            .door(.article("CompanionAbuBakrView")),
            .door(.article("CompanionUmarView")),
            .door(.article("CompanionUthmanView")),
            .door(.article("CompanionAliView")),
            .door(.prophecy("uthman-calamity")),
        ]),
        ArticleSection("TALHAH AND AZ-ZUBAYR", [
            .markdown("**Talhah ibn Ubaydullah** (may Allah be pleased with him), of Banu Taym, Abu Bakr’s clan, was among the first handful of Makkans to believe. His day was Uhud, in 3 AH. When the archers left their post and the Muslim ranks broke, a few men stayed around the Prophet (peace be upon him), and Talhah put his own hand between him and the arrows. A Successor who met him years later saw what that day had left:"),
            .hadith("bukhari:3724", cite: "Saheeh al-Bukhaari 3724", arabic: 14...26, english: [0...14]),
            .longOnly(.text("Abu Uthmaan an-Nahdi reported, on the word of Talhah and Sa‘d themselves, that on one of those days of fighting no one was left beside the Messenger of Allah except the two of them (Saheeh al-Bukhaari 3722).")),
            .longOnly(.hadith("bukhari:3722", cite: "Saheeh al-Bukhaari 3722", arabic: 14...37, english: [0...21])),
            .longOnly(.markdown("**Az-Zubayr ibn al-Awwaam** (may Allah be pleased with him) was the Prophet’s cousin, the son of his aunt Safiyyah bint Abd al-Muttalib, and his wife was Asmaa’ bint Abi Bakr, Aa’ishah’s sister. He believed as a youth. During the siege of Madinah by the Confederates in 5 AH, the Prophet asked who would bring him news of the enemy, and az-Zubayr answered each time:")),
            .shortOnly(.markdown("**Az-Zubayr ibn al-Awwaam** (may Allah be pleased with him) was the Prophet’s cousin, the son of his aunt Safiyyah bint Abd al-Muttalib, and believed as a youth. During the siege of Madinah by the Confederates in 5 AH, the Prophet asked who would bring him news of the enemy, and az-Zubayr answered each time:")),
            .hadith("bukhari:2846", cite: "Saheeh al-Bukhaari 2846", arabic: 24...57, english: [4...59]),
            .longOnly(.markdown("A **hawaari (حَوَارِيّ)** is a sincere and devoted helper, the word the Quran uses for the disciples of Eesa (peace be upon him) (61:14). In the same campaign az-Zubayr rode to Banu Qurayzah and back to bring their news, and the Prophet named both his parents for him, saying that they would be his ransom (Saheeh al-Bukhaari 3720).")),
            .shortOnly(.markdown("A **hawaari (حَوَارِيّ)** is a sincere and devoted helper, the word the Quran uses for the disciples of Eesa (peace be upon him).")),
            .longOnly(.ayah("61:14", words: 6...20)),
            .longOnly(.hadith("bukhari:3720", cite: "Saheeh al-Bukhaari 3720", arabic: 19...90, english: [0...110])),
            .longOnly(.text("The two men are named side by side in history for a sadder reason as well. After Uthmaan was killed, they went to Basrah with Aa’ishah (may Allah be pleased with her) to demand justice against his killers, and in 36 AH (656 CE) the Battle of the Camel was fought between their camp and Ali’s. Talhah was struck by an arrow and died. Az-Zubayr left the field and was killed on his way by a man named Ibn Jurmooz. When the killer came to Ali expecting thanks, this is how he was received:")),
            .shortOnly(.text("After Uthmaan was killed, the two men went to Basrah with Aa’ishah (may Allah be pleased with her) to demand justice against his killers, and in 36 AH (656 CE) the Battle of the Camel was fought between their camp and Ali’s. Talhah was struck by an arrow and died; az-Zubayr left the field and was killed on his way. When the killer came to Ali expecting thanks, this is how he was received:")),
            .hadith("ahmed:681", cite: "Musnad Ahmad 681; its chain graded hasan by Darussalam", arabic: 28...52, english: [19...53]),
            .longOnly(.text("Ali’s army had faced az-Zubayr’s that very day, yet he promised the man who killed him the Fire and recalled the Prophet’s praise of him in the same breath. Ali is also reported to have said that he hoped he, Talhah and az-Zubayr would be among those of whom Allah says this; Ibn Katheer (may Allah have mercy on him) cites it in his commentary on the ayah:")),
            .longOnly(.ayah("15:47")),
            .shortOnly(.text("Ali’s army had faced az-Zubayr’s that very day, yet he promised the man who killed him the Fire and recalled the Prophet’s praise of him in the same breath.")),
        ]),
        ArticleSection("ABD AR-RAHMAN IBN AWF", [
            .longOnly(.text("Abd ar-Rahman ibn Awf (may Allah be pleased with him) believed in the earliest days at Makkah and reached Madinah with nothing. The Prophet (peace be upon him) paired each emigrant with a brother from the Ansaar, and the offer Abd ar-Rahman’s brother made him shows what that brotherhood meant, as does his answer:")),
            .longOnly(.hadith("bukhari:2048", cite: "Saheeh al-Bukhaari 2048", arabic: 25...92, english: [5...129])),
            .shortOnly(.text("Abd ar-Rahman ibn Awf (may Allah be pleased with him) believed in the earliest days at Makkah and reached Madinah with nothing. When the brother from the Ansaar the Prophet paired him with offered him half his wealth, he asked only to be shown the market, and within years he was among the wealthiest men of Madinah, spending as freely as he earned.")),
            .longOnly(.text("Within days he had married, and within years he was among the wealthiest men of Madinah, spending as freely as he earned. He was also trusted with the prayer. On the expedition to Tabook, when the Prophet was delayed and the time of Fajr was passing, the people put Abd ar-Rahman forward to lead them, and al-Mugheerah ibn Shu‘bah described what happened when the Prophet arrived:")),
            .longOnly(.hadith("muslim:274l", cite: "Saheeh Muslim 274l", arabic: 128...200, english: [6...126])),
            .text("Wealth did not settle his heart. Years later, when a meal was set before him at the end of a fast, he thought of the men who had died poor:"),
            .hadith("bukhari:1274", cite: "Saheeh al-Bukhaari 1274", arabic: 27...72, english: [16...88]),
            .longOnly(.text("When Umar’s council of six met in 23 AH, Abd ar-Rahman withdrew his own name so that the others would trust him to choose between them. For three nights he consulted the people and hardly slept, and then he gave his pledge to Uthmaan, and the people followed him (Saheeh al-Bukhaari 7207). He died in Madinah in about 32 AH.")),
            .longOnly(.hadith("bukhari:7207", cite: "Saheeh al-Bukhaari 7207", arabic: 74...113, english: [88...159])),
            .shortOnly(.text("When Umar’s council of six met in 23 AH, Abd ar-Rahman withdrew his own name so that the others would trust him to choose between them, and after three nights of consulting the people he gave his pledge to Uthmaan. He died in Madinah in about 32 AH.")),
        ]),
        ArticleSection("SA‘D IBN ABI WAQQAAS", [
            .text("Sa‘d ibn Abi Waqqaas (may Allah be pleased with him) was a young man of Banu Zuhrah when he believed, so early that for a week, as he put it, he was a third of Islam:"),
            .hadith("bukhari:3727", cite: "Saheeh al-Bukhaari 3727", arabic: 29...44, english: [0...27]),
            .longOnly(.text("His mother swore that she would neither eat nor drink until he left the new religion, and she kept it up until she fainted. Allah then revealed the ayah that settles every such conflict between a parent’s command and Allah’s right (Saheeh Muslim 1748c):")),
            .shortOnly(.text("His mother swore that she would neither eat nor drink until he left the new religion, and Allah revealed the ayah that settles every such conflict between a parent’s command and Allah’s right:")),
            .ayah("29:8"),
            .longOnly(.hadith("muslim:1748c", cite: "Saheeh Muslim 1748c", arabic: 35...100, english: [0...101])),
            .longOnly(.text("Kindness to her remained his duty; obeying her in shirk did not. Sa‘d was the first of the Arabs to shoot an arrow in Allah’s cause (Saheeh al-Bukhaari 3728).")),
            .longOnly(.hadith("bukhari:3728", cite: "Saheeh al-Bukhaari 3728", arabic: 22...29, english: [4...17])),
            .shortOnly(.text("Kindness to her remained his duty; obeying her in shirk did not.")),
            .longOnly(.text("At Uhud the Prophet (peace be upon him) handed him arrows and spoke words that Ali said he never heard him say to anyone else:")),
            .longOnly(.hadith("bukhari:4059", cite: "Saheeh al-Bukhaari 4059", arabic: 21...47, english: [0...40])),
            .longOnly(.text("Az-Zubayr reported the same words said to him at the Trench (Saheeh al-Bukhaari 3720); each man told what he himself had heard. Under Umar, Sa‘d led the army that broke the Persian forces at al-Qaadisiyyah in Iraq, around 15 AH, and he founded the garrison city of Koofah. When people of Koofah later complained to Umar that he did not even pray properly, Umar sent men to ask after him in every mosque of the city, and they heard him praised in all of them but one (Saheeh al-Bukhaari 755).")),
            .longOnly(.hadith("bukhari:755", cite: "Saheeh al-Bukhaari 755", arabic: 88...111, english: [109...159])),
            .shortOnly(.text("Under Umar, Sa‘d led the army that broke the Persian forces at al-Qaadisiyyah in Iraq, around 15 AH, and he founded the garrison city of Koofah. When the fighting between the Muslims began, he kept away from it. He went out to his camels in the open country, and when his own son rode out to urge him to claim a share of the rule, he answered with a hadith:")),
            .longOnly(.text("When the fighting between the Muslims began, Sa‘d kept away from it. He went out to his camels in the open country, and when his own son rode out to urge him to claim a share of the rule, he answered with a hadith:")),
            .hadith("muslim:2965", cite: "Saheeh Muslim 2965", arabic: 45...85, english: [0...76]),
            .longOnly(.text("In the year of the Farewell Hajj he had fallen so ill that he expected to die, and the Prophet told him that perhaps he would live long, so that some people would benefit from him and others be harmed by him (Saheeh al-Bukhaari 1295). The commentators read it in what followed: the Muslims gained through his conquests in Iraq, and the Persian empire lost to them. He outlived that illness by more than forty years and was the last of the ten to die, at al-Aqeeq outside Madinah, in about 55 AH.")),
            .longOnly(.hadith("bukhari:1295", cite: "Saheeh al-Bukhaari 1295", arabic: 107...137, english: [142...201])),
            .longOnly(.door(.prophecy("sad-lives"))),
            .shortOnly(.text("He was the last of the ten to die, at al-Aqeeq outside Madinah, in about 55 AH.")),
        ]),
        ArticleSection("SA‘EED IBN ZAYD", [
            .shortOnly(.text("Sa‘eed ibn Zayd (may Allah be pleased with him) inherited a search for the truth: his father, Zayd ibn Amr ibn Nufayl, died a few years before the revelation, having refused the idols and the meat sacrificed to them. Sa‘eed and his wife Faatimah bint al-Khattaab, Umar’s sister, believed before Umar did, and he lived quietly in Madinah and at al-Aqeeq and took no part in the fighting that followed.")),
            .longOnly(.text("Sa‘eed ibn Zayd (may Allah be pleased with him) inherited a search for the truth. His father, Zayd ibn Amr ibn Nufayl, died a few years before the revelation, having refused the idols and the meat sacrificed to them (Saheeh al-Bukhaari 3826).")),
            .longOnly(.hadith("bukhari:3826", cite: "Saheeh al-Bukhaari 3826", arabic: 24...109, english: [0...152])),
            .longOnly(.text("Asmaa’ bint Abi Bakr (may Allah be pleased with her) remembered him in Makkah:")),
            .longOnly(.hadith("bukhari:3828", cite: "Saheeh al-Bukhaari 3828", arabic: 18...54, english: [0...65])),
            .longOnly(.text("Sa‘eed and his wife Faatimah bint al-Khattaab, Umar’s sister, believed before Umar did, and Umar, then a fierce enemy of the new faith, tied his brother-in-law up for it. Sa‘eed recalled it decades later in the mosque of Koofah, with a sharp turn at the end:")),
            .longOnly(.hadith("bukhari:3862", cite: "Saheeh al-Bukhaari 3862", arabic: 23...45, english: [15...65])),
            .longOnly(.text("He was speaking after Uthmaan’s murder: his point was that a mountain would have had reason to fall apart at that crime. Sa‘eed lived quietly in Madinah and at al-Aqeeq and took no part in the fighting that followed. One story shows how much weight his word carried. A woman named Arwa claimed that he had taken part of her land, and he answered:")),
            .longOnly(.hadith("muslim:1610b", cite: "Saheeh Muslim 1610b", arabic: 29...93, english: [0...119])),
            .text("The same reserve shows in the way he told the hadith of the ten. He counted nine names and stopped:"),
            .hadith("tirmidhi:3748", cite: "Jaami‘ at-Tirmidhi 3748; graded saheeh by al-Albaani", arabic: 42...88, english: [23...52, 56...96]),
        ]),
        ArticleSection("ABU UBAYDAH IBN AL-JARRAAH", [
            .text("Abu Ubaydah Aamir ibn Abdullah ibn al-Jarraah (may Allah be pleased with him), of Banu al-Haarith ibn Fihr, was given a title that no one else shares:"),
            .hadith("bukhari:3744", cite: "Saheeh al-Bukhaari 3744", arabic: 27...38, english: [5...25]),
            .longOnly(.text("When the Christian leaders of Najraan chose to pay tribute rather than meet the Prophet (peace be upon him) in a mutual invocation of Allah’s curse on the liar, they asked him to send a trustworthy man back with them. Every Companion hoped to be the one, and he called Abu Ubaydah (Saheeh al-Bukhaari 4380). At the Saqeefah, after the Prophet’s death, Abu Bakr proposed Umar or Abu Ubaydah for the caliphate, and Umar said he would rather be beheaded than rule a people among whom Abu Bakr was (Saheeh al-Bukhaari 6830).")),
            .longOnly(.hadith("bukhari:4380", cite: "Saheeh al-Bukhaari 4380", arabic: 58...107, english: [70...147])),
            .longOnly(.hadith("bukhari:6830", cite: "Saheeh al-Bukhaari 6830", arabic: 730...774, english: [1263...1348])),
            .shortOnly(.text("When the Christian leaders of Najraan asked the Prophet (peace be upon him) to send a trustworthy man back with them, every Companion hoped to be the one, and he called Abu Ubaydah.")),
            .longOnly(.text("Under Umar he commanded the Muslim armies in Syria. When plague broke out there just as Umar was on his way to visit, Umar consulted the emigrants, then the Ansaar, then the elders of Quraysh, and decided to turn back. Abu Ubaydah objected, and the exchange that followed became the classic statement of how trust in Allah’s decree and taking precautions fit together:")),
            .shortOnly(.text("Under Umar he commanded the Muslim armies in Syria. When plague broke out there just as Umar was on his way to visit, Umar decided to turn back, and Abu Ubaydah objected:")),
            .hadith("bukhari:5729", cite: "Saheeh al-Bukhaari 5729", arabic: 171...264, english: [234...277, 346...393]),
            .text("Abu Ubaydah stayed with his army, as that hadith told him to. The plague of Amwaas killed him there in 18 AH (639 CE), together with thousands of the Muslims of Syria, Mu‘aadh ibn Jabal among them. The commander of the armies of Syria died at his post, among his soldiers."),
        ]),
        ArticleSection("NOT ONLY THE TEN", [
            .shortOnly(.text("The ten are a famous list, not a closed one. The Prophet (peace be upon him) promised Paradise to many others by name, Bilaal, Thaabit ibn Qays, Ukkaashah ibn Mihsan and Abdullah ibn Salaam among them, and to whole companies too. Of the fourteen hundred who pledged their lives to him under the tree at al-Hudaybiyah in 6 AH, he said:")),
            .longOnly(.text("The ten are a famous list, not a closed one. The Prophet (peace be upon him) promised Paradise to many others by name. Bilaal ibn Rabaah (may Allah be pleased with him), the freed slave who called the adhan, was asked one morning about a single habit:")),
            .longOnly(.hadith("bukhari:1149", cite: "Saheeh al-Bukhaari 1149", arabic: 34...74, english: [12...65])),
            .longOnly(.text("Thaabit ibn Qays ibn Shammaas, the orator of the Ansaar, had a naturally loud voice. When Allah forbade raising one’s voice above the Prophet’s (49:2), he shut himself in his house, sure that his deeds were lost:")),
            .longOnly(.hadith("bukhari:3613", cite: "Saheeh al-Bukhaari 3613", arabic: 32...105, english: [0...134])),
            .longOnly(.ayah("49:2")),
            .longOnly(.text("When the Prophet described the seventy thousand of his ummah who will enter Paradise without reckoning, those who do not ask for ruqyah, draw no omens and are not cauterised, but put their trust in their Lord, Ukkaashah ibn Mihsan stood up at once:")),
            .longOnly(.hadith("bukhari:5705", cite: "Saheeh al-Bukhaari 5705", arabic: 152...173, english: [236...275])),
            .longOnly(.text("Abdullah ibn Salaam, the rabbi of Madinah who believed, was pointed out in the mosque as one of the people of Paradise. A young man followed him out and asked why, and he would not claim more than he knew:")),
            .longOnly(.hadith("bukhari:3813", cite: "Saheeh al-Bukhaari 3813", arabic: 54...151, english: [66...82, 224...245])),
            .longOnly(.text("Whole companies were promised it too. Of the men of Badr, the Prophet said that perhaps Allah had looked at them and said, Do as you will, for I have forgiven you (Saheeh al-Bukhaari 3983).")),
            .longOnly(.hadith("bukhari:3983", cite: "Saheeh al-Bukhaari 3983", arabic: 219...243, english: [279...313])),
            .longOnly(.text("Of the fourteen hundred who pledged their lives to him under the tree at al-Hudaybiyah in 6 AH, he said:")),
            .hadith("muslim:2496", cite: "Saheeh Muslim 2496", arabic: 37...50, english: [0...21]),
            .longOnly(.ayah("48:18")),
            .longOnly(.text("Haarithah ibn Suraaqah, killed by a stray arrow at Badr, is in al-Firdaws, the highest garden (Saheeh al-Bukhaari 2809). Khadeejah, Faatimah, al-Hasan, al-Husayn and Ja‘far each have glad tidings of their own, told in the chapters on the Prophet’s household.")),
            .longOnly(.hadith("bukhari:2809", cite: "Saheeh al-Bukhaari 2809", arabic: 36...77, english: [16...84])),
        ]),
        ArticleSection("WHAT THE PROMISE ASKS OF US", [
            .longOnly(.text("From these texts Ahl as-Sunnah draw a rule of creed. A Muslim may say of a named person that he is in Paradise only when the Prophet (peace be upon him) said it, because only revelation knows a person’s end. Ibn Taymiyyah (may Allah have mercy on him) set it down in his short statement of the creed of the Salaf:")),
            .longOnly(.quote(text: "“They testify to Paradise for those to whom the Messenger of Allah (peace be upon him) testified it, such as the ten, Thaabit ibn Qays ibn Shammaas and others of the Companions.” (Ibn Taymiyyah, al-Aqeedah al-Waasitiyyah)", arabic: "وَيَشهَدُونَ بِالجَنَّةِ لِمَن شَهِدَ لَهُ رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ كَالعَشَرَةِ، وَكَثَابِتِ بنِ قَيسِ بنِ شَمَّاسٍ، وَغَيرِهِم مِنَ الصَّحَابَةِ", dimmed: true)),
            .longOnly(.text("For everyone else the believer hopes for the righteous and fears for the sinner, and does not name anyone’s final home. Abdullah ibn Salaam’s refusal to claim more than he knew is the same rule, from a man who had the glad tidings himself.")),
            .shortOnly(.text("From these texts Ahl as-Sunnah draw a rule of creed: a Muslim may say of a named person that he is in Paradise only when the Prophet (peace be upon him) said it, because only revelation knows a person’s end. For everyone else the believer hopes for the righteous and fears for the sinner, and does not name anyone’s final home.")),
            .callout("A promise of Paradise was never a licence. Abd ar-Rahman wept over his food because he feared his reward had come early; Sa‘d left a share of power alone; Abu Ubaydah stayed in a plague-stricken land rather than break the Prophet’s command. The glad tidings made them more careful, not less.", title: "What the Glad Tidings Did to Them", icon: "lightbulb.fill"),
            .text("The promise also settles how a Muslim speaks about them. Talhah and az-Zubayr stood on one side at the Camel and Ali on the other, and all three are on the same list. Whatever passed between them, the Prophet testified to their end, and so Ahl as-Sunnah love them all, ask forgiveness for them as Allah taught (59:10), and do not make their disputes a subject of blame."),
            .ayah("59:10", words: 4...18),
            .door(.article("SahabahView")),
            .door(.article("AhlusSunnahView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**If Talhah and az-Zubayr were promised Paradise, how could they fight Ali?**"),
            .text("They did not set out to fight him. They went to Basrah, with Aa’ishah, to demand that Uthmaan’s killers be punished, while Ali held that the state had first to be steadied before retribution could be taken. Each side acted on its own judgment in a question that was truly difficult, and the scholars of Ahl as-Sunnah, Ibn Taymiyyah among them, record that the battle itself broke out against the wishes of the leaders on both sides. A mujtahid who is right has two rewards and one who errs has one, and the Prophet gave his glad tidings knowing, by revelation, everything that would happen. The death of the two men moved Ali to grief, as his words to az-Zubayr’s killer show."),
            .markdown("**Why these ten, when others were promised Paradise too?**"),
            .text("Because they were named together in one saying, which made them a well-known group. Others, like Bilaal, Thaabit ibn Qays and Ukkaashah, were promised it in separate sayings, and the people of Badr and of the Tree as companies. Many scholars of the Sunnah rank the rest of the ten next after the four caliphs, then the people of Badr, then the people of the Tree."),
            .markdown("**Can we say that a righteous scholar of our time is in Paradise?**"),
            .text("Not by name. We may say that Allah has promised Paradise to the believers who do good, and hope it for every Muslim we knew to be upright. The Prophet taught that whoever praises his brother should say that he thinks him so, that Allah is his reckoner, and that he vouches for no one before Allah (Saheeh al-Bukhaari 2662). A definite testimony about one person belongs only to those named by revelation."),
            .hadith("bukhari:2662", cite: "Saheeh al-Bukhaari 2662", arabic: 40...64, english: [41...90]),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The ten promised Paradise are Abu Bakr, Umar, Uthmaan, Ali, Talhah, az-Zubayr, Abd ar-Rahman ibn Awf, Sa‘d ibn Abi Waqqaas, Sa‘eed ibn Zayd and Abu Ubaydah, named together by the Prophet (peace be upon him) and narrated by two of them. Their lives show why: Talhah’s hand at Uhud, az-Zubayr’s rides through the enemy lines, Abd ar-Rahman’s trade and tears, Sa‘d’s arrows and his refusal of power, Sa‘eed’s honesty, Abu Ubaydah’s trustworthiness to his last day. Many others were promised Paradise by name and as companies. Ahl as-Sunnah testify to Paradise for exactly those the texts name, love all of them together, and leave what passed between them to Allah."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Al-Asharah al-Mubashsharoon", arabic: "العَشَرَةُ المُبَشَّرُونَ", meaning: "**The ten given glad tidings**: the ten Companions named together as people of Paradise in the hadith of Abd ar-Rahman ibn Awf and Sa‘eed ibn Zayd."),
            .term("Hawaari", arabic: "حَوَارِيّ", meaning: "A **devoted helper** and disciple. The Quran uses it for the disciples of Eesa (61:14), and the Prophet used it for az-Zubayr: every prophet has a hawaari, and mine is az-Zubayr."),
            .term("Ameen", arabic: "أَمِين", meaning: "**Trustworthy**, one to whom a trust can be handed. The Prophet called Abu Ubaydah ibn al-Jarraah the aameen of this ummah."),
            .term("Shoora", arabic: "شُورَى", meaning: "**Consultation**. Umar left the choice of his successor to a council of six of the ten, and Abd ar-Rahman ibn Awf, after three nights of consulting the people, gave his pledge to Uthmaan."),
        ]),
    ]
}

struct CompanionKhadijahAishahView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionKhadijahAishahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Khadeejah and Aa’ishah")
        .englishArticle().selectableArticleList(article: "CompanionKhadijahAishahView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Khadeejah bint Khuwaylid and Aa’ishah bint Abi Bakr (may Allah be pleased with them) are the two wives of the Prophet Muhammad (peace and blessings be upon him) whom the sound texts praise most. Khadeejah was the first to believe, steadied him on the night the revelation began, gave him all his children but one, and received a greeting of peace from her Lord. Aa’ishah was the wife in whose room the revelation came and in whose arms he died, the woman whose innocence Allah declared in ten aayaat, and the most learned woman this ummah has known. This chapter tells both lives from the Quran and sound hadith, and ends with the Sunni position on the Battle of the Camel and on anyone who attacks a Mother of the Believers."),
        ]),
        ArticleSection("KHADEEJAH BINT KHUWAYLID", [
            .shortOnly(.text("Khadeejah bint Khuwaylid, of Banu Asad of Quraysh, was a widow of rank in Makkah who traded through hired agents. She proposed marriage to the young Muhammad, already known among his people as al-Ameen, the trustworthy; by the best-known account he was twenty-five and she about forty, and he took no other wife while she lived. She bore all of his children but one, and the Prophet’s line continued through her daughter Faatimah alone.")),
            .longOnly(.text("Khadeejah bint Khuwaylid, of Banu Asad of Quraysh, was a widow of rank in Makkah who traded through hired agents. The biographers relate that she sent the young Muhammad, already known among his people as al-Ameen, the trustworthy, with her goods to Syria, heard from her servant how he had conducted himself, and proposed marriage to him herself. By the best-known account he was twenty-five and she about forty. The marriage lasted about twenty-five years, until her death, and he took no other wife while she lived.")),
            .longOnly(.text("She bore all of his children but one: al-Qaasim and Abdullah, who died young, and four daughters, Zaynab, Ruqayyah, Umm Kulthoom and Faatimah. Only Ibraaheem, born in Madinah to Maariyah, had another mother, and he too died as an infant. The Prophet’s line continued through Faatimah alone, so every descendant of his is also a descendant of Khadeejah.")),
        ]),
        ArticleSection("THE NIGHT OF HIRA", [
            .text("When the angel came to him in the cave of Hira, pressed him three times and gave him the first aayaat of Surah al-Alaq, he came home with his heart pounding. Aa’ishah, who heard the account from him, described what Khadeejah did:"),
            .hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 156...204, english: [271...346]),
            .longOnly(.text("Her answer was an argument, not only a comfort: a man of such character is not one whom Allah would disgrace. Then she acted on it. She took him to her cousin Waraqah ibn Nawfal, an old man who had become a Christian and could read the earlier scripture, and Waraqah told him that this was the same angel who had come to Moosa (Saheeh al-Bukhaari 3). The scholars count her the first of all people to believe in him.")),
            .longOnly(.text("She stood by him for the next ten years: through the mockery, the torture of the weak believers, and the boycott that shut Banu Haashim in a valley outside Makkah. She died, by the reckoning of Urwah ibn az-Zubayr, three years before the Hijrah (Saheeh al-Bukhaari 3896), in the same season as Abu Taalib, the uncle who had protected him. The biographers call it the Year of Sorrow.")),
            .longOnly(.hadith("bukhari:3896", cite: "Saheeh al-Bukhaari 3896", arabic: 12...43, english: [0...44])),
            .shortOnly(.text("Her answer was an argument, not only a comfort: a man of such character is not one whom Allah would disgrace. The scholars count her the first of all people to believe in him. She stood by him for the next ten years, through the mockery, the torture of the weak believers and the boycott, and died three years before the Hijrah, in the same season as Abu Taalib, in the year the biographers call the Year of Sorrow.")),
        ]),
        ArticleSection("A HOUSE OF PEARL IN PARADISE", [
            .text("Ibn al-Qayyim (may Allah have mercy on him) counts this among her particular honours: no other woman is known to have received a greeting of peace from Allah Himself. Abu Hurayrah (may Allah be pleased with him) narrated:"),
            .hadith("bukhari:3820", cite: "Saheeh al-Bukhaari 3820, Saheeh Muslim 2432", arabic: 22...64, english: [0...69]),
            .longOnly(.markdown("The **qasab (قَصَب)** of the house, the commentators explain, is hollowed pearl. As-Suhayli, cited by Ibn Hajar, observed that the house matches her life: she answered his call to faith without making him raise his voice or argue, and eased every hardship for him, so her reward is a house with no clamour in it and no toil. Ali (may Allah be pleased with him) heard the Prophet name the best women of their times: Maryam, and Khadeejah (Saheeh al-Bukhaari 3815).")),
            .longOnly(.hadith("bukhari:3815", cite: "Saheeh al-Bukhaari 3815", arabic: 64...69, english: [14...36])),
            .longOnly(.text("The Prophet’s faithfulness to her outlived her by many years, and the witness to it is the wife who felt it most keenly:")),
            .longOnly(.hadith("bukhari:3818", cite: "Saheeh al-Bukhaari 3818", arabic: 22...77, english: [0...92])),
            .longOnly(.text("When her sister Haalah asked permission to enter, years later, the way she asked was so like Khadeejah’s that he was moved and said Haalah’s name aloud (Saheeh al-Bukhaari 3821). In Saheeh Muslim Aa’ishah reports his simplest explanation: her love had been given to him by Allah (Saheeh Muslim 2435b). The honesty of the narrator matters here. The one who preserved all of this for the ummah was the young wife who admitted that she was jealous of a woman she never met.")),
            .longOnly(.hadith("bukhari:3821", cite: "Saheeh al-Bukhaari 3821", arabic: 20...42, english: [0...36])),
            .longOnly(.hadith("muslim:2435b", cite: "Saheeh Muslim 2435", arabic: 54...69, english: [47...79])),
        ]),
        ArticleSection("AA’ISHAH BINT ABI BAKR", [
            .text("Aa’ishah, the daughter of Abu Bakr as-Siddeeq and Umm Ruman (may Allah be pleased with them), was born into a Muslim household and never knew the worship of idols. Before the marriage the Prophet (peace be upon him) was shown her in a dream:"),
            .hadith("bukhari:3895", cite: "Saheeh al-Bukhaari 3895", arabic: 27...52, english: [7...56]),
            .longOnly(.text("The marriage was contracted in Makkah after Khadeejah’s death, and she joined his household in Madinah after the Hijrah (Saheeh al-Bukhaari 3896). Her rank is stated in words that name her beside the greatest women of history:")),
            .shortOnly(.text("The marriage was contracted in Makkah after Khadeejah’s death, and she joined his household in Madinah after the Hijrah. Her rank is stated in words that name her beside the greatest women of history:")),
            .hadith("bukhari:3769", cite: "Saheeh al-Bukhaari 3769, Saheeh Muslim 2431", arabic: 34...57, english: [4...48]),
            .longOnly(.markdown("**Thareed (ثَرِيد)**, bread broken into broth with meat, was the finest everyday dish of the Arabs: nourishing, easy, and loved by all. The angel greeted her too, through the Prophet:")),
            .longOnly(.hadith("bukhari:3768", cite: "Saheeh al-Bukhaari 3768", arabic: 32...48, english: [9...33])),
            .longOnly(.text("When the other wives asked him, through Umm Salamah, to change how the people sent him gifts, he answered that the revelation had never come to him while he lay under the blanket of any of his wives except Aa’ishah (Saheeh al-Bukhaari 3775). Even a lost necklace of hers became a mercy: the army was held up searching for it at a place with no water, and the ayah of tayammum was revealed, so that Usayd ibn Hudayr told the family of Abu Bakr that this was not the first blessing to come through them (Saheeh al-Bukhaari 334).")),
            .longOnly(.hadith("bukhari:3775", cite: "Saheeh al-Bukhaari 3775", arabic: 93...111, english: [141...172])),
            .longOnly(.hadith("bukhari:334", cite: "Saheeh al-Bukhaari 334", arabic: 160...176, english: [186...216])),
        ]),
        ArticleSection("THE SLANDER AND ITS ANSWER", [
            .shortOnly(.text("On the way back from the campaign against Banu al-Mustaliq, Aa’ishah went back to look for a lost necklace, and the army marched off without noticing that her howdah was empty. Safwan ibn al-Mu‘attal, who came behind the army, found her waiting alone and led her on his camel until they reached the army, and the hypocrite Abdullah ibn Ubayy made a scandal of it, which a few believers repeated. For a month no revelation came, and Aa’ishah wept and waited.")),
            .longOnly(.text("On the way back from the campaign against Banu al-Mustaliq, Aa’ishah stepped away from the camp, lost her necklace and went back to look for it. The men who carried her howdah lifted it onto the camel without noticing that it was light, and the army marched off. Safwan ibn al-Mu‘attal, who came behind the army, found her waiting alone and led her on his camel until they reached the army. The hypocrite Abdullah ibn Ubayy made a scandal of it, and a few believers repeated what they heard.")),
            .longOnly(.text("For a month no revelation came. Aa’ishah fell ill without knowing what was said, then learned it and wept for two nights. The Prophet consulted Ali and Usaamah, questioned her maid Bareerah, who knew nothing against her, and finally came and spoke to her. Her reply is one of the most moving passages in the Sunnah:")),
            .longOnly(.hadith("bukhari:4750", cite: "Saheeh al-Bukhaari 4750, Saheeh Muslim 2770", arabic: 1151...1312, english: [1784...1819, 1846...1885, 2004...2038])),
            .text("Ten aayaat of Surat an-Noor came down, from the eleventh to the twentieth. They clear her, rebuke the believers who repeated the story, and give the ummah a rule for every rumour after it:"),
            .ayah("24:11-12"),
            .longOnly(.ayah("24:16-17")),
            .longOnly(.text("Her own father had to apply what came next. Abu Bakr had supported his poor relative Mistah, one of those who repeated the slander, and swore to stop. Allah revealed: let them pardon and overlook; would you not love for Allah to forgive you (24:22)? Abu Bakr said he would, and restored the support for good (Saheeh al-Bukhaari 4750). Ibn Katheer (may Allah have mercy on him), commenting on 24:23, records the agreement of the scholars that whoever accuses her after this, of what Allah cleared her of, is a disbeliever, because he is contradicting the Quran.")),
            .longOnly(.ayah("24:22", words: 15...22)),
            .longOnly(.ayah("24:23")),
            .shortOnly(.text("Ibn Katheer (may Allah have mercy on him) records the agreement of the scholars that whoever accuses her after this, of what Allah cleared her of, is a disbeliever, because he is contradicting the Quran.")),
        ]),
        ArticleSection("THE TEACHER OF THE UMMAH", [
            .text("Aa’ishah outlived the Prophet by nearly half a century, and those years made her a teacher of the Companions themselves. Abu Moosa al-Ash‘ari (may Allah be pleased with him) said:"),
            .hadith("tirmidhi:3883", cite: "Jaami‘ at-Tirmidhi 3883; graded saheeh by al-Albaani", arabic: 23...41, english: [0...29]),
            .text("More than two thousand narrations are reported from her, many of them about what only a wife could see: his night prayer, his fasting, his ghusl, his manners at home. Asked to describe his character, she asked the questioner whether he did not read the Quran, and answered that his character was the Quran (Saheeh Muslim 746a)."),
            .hadith("muslim:746a", cite: "Saheeh Muslim 746a", arabic: 210...241, english: [262...303]),
            .longOnly(.text("Her method was to test every claim against the Book. When Masrooq asked her whether the Prophet had seen his Lord, she named three claims that were lies and answered each from the Quran:")),
            .longOnly(.hadith("bukhari:4855", cite: "Saheeh al-Bukhaari 4855", arabic: 80...124, english: [104...181])),
            .longOnly(.text("The first of her three points, that he did not see his Lord, she argued from 6:103 and 42:51. Ibn Abbaas reported that he saw Him with his heart (Saheeh Muslim 176a), and Ibn Taymiyyah (may Allah have mercy on him) explains that the two do not conflict: what she denied was seeing with the eyes, and what Ibn Abbaas affirmed was seeing with the heart. Later scholars collected the points on which she corrected other Companions; Badr ad-Deen az-Zarkashi (d. 794 AH) gathered them in a book of their own.")),
            .longOnly(.ayah("6:103", words: 0...2)),
            .longOnly(.ayah("42:51")),
            .longOnly(.hadith("muslim:176a", cite: "Saheeh Muslim 176a", arabic: 16...18, english: [0...18])),
            .longOnly(.text("Her students carried her knowledge into the next generation. Her nephews Urwah ibn az-Zubayr and al-Qaasim ibn Muhammad ibn Abi Bakr, both among the seven great jurists of Madinah, learned from her directly, as did Amrah bint Abd ar-Rahman. Men asked her from behind a screen, as the Quran directs (33:53), and women sat with her.")),
            .longOnly(.ayah("33:53", words: 38...44)),
        ]),
        ArticleSection("HIS LAST DAYS IN HER ROOM", [
            .shortOnly(.text("In his final illness the Prophet (peace be upon him) kept asking whose day it would be, and his wives understood and let him stay in her room. He died there, resting against her, and was buried where he died; Abu Bakr and Umar were later buried beside him.")),
            .longOnly(.text("In his final illness the Prophet (peace be upon him) kept asking whose day it would be, and his wives understood:")),
            .longOnly(.hadith("bukhari:4450", cite: "Saheeh al-Bukhaari 4450", arabic: 37...128, english: [12...150])),
            .longOnly(.text("He was buried where he died, in her room beside the mosque. When Umar lay dying he sent his son to ask her permission to be buried beside his two companions, and she answered that she had wanted the place for herself, but that she preferred him to herself that day (Saheeh al-Bukhaari 1392). So the Prophet, Abu Bakr and Umar lie in the room of Aa’ishah.")),
            .longOnly(.hadith("bukhari:1392", cite: "Saheeh al-Bukhaari 1392", arabic: 33...63, english: [10...78])),
            .longOnly(.text("At the end of her own life, Ibn Abbaas (may Allah be pleased with them) asked to visit her, and her reply shows the woman behind all the praise:")),
            .longOnly(.hadith("bukhari:4753", cite: "Saheeh al-Bukhaari 4753", arabic: 29...92, english: [24...148])),
            .text("She died in Madinah in 57 or 58 AH (677 or 678 CE) and was buried in al-Baqee‘."),
        ]),
        ArticleSection("THE CAMEL AND THE SUNNI STANCE", [
            .shortOnly(.text("After Uthmaan was murdered, Aa’ishah went to Basrah with Talhah and az-Zubayr (may Allah be pleased with them) to demand justice against his killers, and in 36 AH their camp met Ali’s near Basrah, in the battle named after the camel on which her howdah stood. Before it, Ammaar ibn Yaasir, arguing against her side in Koofah, said this:")),
            .longOnly(.text("After Uthmaan was murdered in 35 AH, Aa’ishah went to Basrah with Talhah and az-Zubayr (may Allah be pleased with them) to demand justice against his killers and to set matters right among the Muslims. Ali (may Allah be pleased with him) held that the state had first to be steadied. In 36 AH the two camps met near Basrah and fighting broke out, and the battle took its name from the camel on which her howdah stood. Before it, Ali had sent Ammaar ibn Yaasir and al-Hasan to Koofah to rally the people, and even there, arguing against her side, Ammaar said this:")),
            .hadith("bukhari:7100", cite: "Saheeh al-Bukhaari 7100", arabic: 64...90, english: [51...86]),
            .longOnly(.text("That sentence is the Sunni position. The fighting did not remove anyone’s faith, for Allah calls two warring parties of Muslims “believers” and commands peace between them:")),
            .longOnly(.ayah("49:9-10")),
            .longOnly(.text("Ahl as-Sunnah hold that Ali was in the right, and that Aa’ishah, Talhah and az-Zubayr were mujtahids who erred in their judgment, rewarded for their intention; none of this touches their rank, and the leaders on both sides had wanted reconciliation, not battle. When the fighting ended, Ali sent her back to Madinah with honour and an escort. She regretted having set out, and it is reported that when she recited the command to the Prophet’s wives to remain in their houses (33:33) she would weep until her veil was wet.")),
            .longOnly(.ayah("33:33", words: 0...2)),
            .longOnly(.text("The Raafidah curse her and the Nawaasib curse Ali; Ahl as-Sunnah love both, as Ammaar loved both while standing on one side. They are the Mother of the Believers by the Quran’s own word (33:6), and her husband in this world and the next is the Messenger of Allah.")),
            .longOnly(.ayah("33:6", words: 5...6)),
            .shortOnly(.text("That sentence is the Sunni position. Ahl as-Sunnah hold that Ali was in the right, and that Aa’ishah, Talhah and az-Zubayr were mujtahids who erred in their judgment, rewarded for their intention; none of this touches their rank. When the fighting ended, Ali sent her back to Madinah with honour and an escort, and she regretted having set out.")),
            .shortOnly(.text("The Raafidah curse her and the Nawaasib curse Ali; Ahl as-Sunnah love both, as Ammaar loved both while standing on one side, and her husband in this world and the next is the Messenger of Allah.")),
            .door(.article("ShiaAnswerView")),
            .door(.article("WivesView")),
            .door(.article("AhlulBaytView")),
            .door(.article("CompanionTenView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Which of the two was better, Khadeejah or Aa’ishah?**")),
            .longOnly(.text("The scholars differed, and both sides have texts. Ibn Taymiyyah and Ibn al-Qayyim (may Allah have mercy on them) explain that each excelled in a way the other did not share: Khadeejah at the beginning of Islam, with the first faith, her comfort, her wealth and her support when no one else stood with him; Aa’ishah at its end, with the knowledge she carried to the ummah after him. A Muslim loves both and need not rank them.")),
            .markdown("**How old was Aa’ishah when she married?**"),
            .text("The Saheeh reports that the contract was made when she was six and that she joined his household at nine (Saheeh al-Bukhaari 5133), and Ahl as-Sunnah accept the report as it stands. Such marriages were the custom of that time and place, and the Prophet’s enemies, who searched for anything to hold against him, never raised it. She narrated it herself, spoke of her marriage with pride, asking which of his wives had been more favoured than she (Saheeh Muslim 1423a), and became the most learned woman of the ummah."),
            .hadith("bukhari:5133", cite: "Saheeh al-Bukhaari 5133", arabic: 17...35, english: [0...35]),
            .hadith("muslim:1423a", cite: "Saheeh Muslim 1423a", arabic: 32...56, english: [0...34]),
            .longOnly(.markdown("**Are the wives part of the Ahlul Bayt?**")),
            .longOnly(.text("Yes. The ayah of purification (33:33) is addressed to them in the middle of a passage that speaks to them from 33:28 to 33:34, and the Quran calls Ibraaheem’s wife one of the people of the house (11:73). The Prophet also gathered Ali, Faatimah, al-Hasan and al-Husayn under his cloak; that adds to the household and takes no one out of it.")),
            .longOnly(.ayah("33:28", words: 0...3)),
            .longOnly(.ayah("33:34", words: 0...4)),
            .longOnly(.ayah("11:73", words: 5...10)),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Khadeejah believed first, steadied the Prophet (peace be upon him) on the night of Hira, spent herself for the call through the hardest years at Makkah, and received peace from her Lord and a house of pearl in Paradise; he honoured her memory for the rest of his life. Aa’ishah, the daughter of as-Siddeeq, was shown to him in a dream, was cleared by ten aayaat of the Quran, taught the Companions for half a century, and held him as he died. Ahl as-Sunnah love them both, count anyone who repeats the slander Allah refuted as rejecting the Quran, and see the Battle of the Camel as Ammaar saw it: she is the wife of our Prophet in this world and the Hereafter."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Umm al-Mu’mineen", arabic: "أُمُّ المُؤمِنِينَ", meaning: "**Mother of the Believers**: the title of every wife of the Prophet, from 33:6. It forbids marrying them after him and obliges every believer to honour them as he honours his mother."),
            .term("Al-Ifk", arabic: "الإِفك", meaning: "**The great lie**: the slander against Aa’ishah on the return from the campaign against Banu al-Mustaliq, refuted in 24:11-20."),
            .term("Qasab", arabic: "قَصَب", meaning: "Literally **reed**; in the hadith of Khadeejah’s house in Paradise the commentators explain it as hollowed pearl."),
            .term("Thareed", arabic: "ثَرِيد", meaning: "**Bread soaked in broth** with meat, the best of everyday dishes; the Prophet likened Aa’ishah’s excellence over other women to its excellence over other food."),
        ]),
    ]
}

struct CompanionFatimahView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionFatimahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Faatimah, al-Hasan and al-Husayn")
        .englishArticle().selectableArticleList(article: "CompanionFatimahView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Faatimah (may Allah be pleased with her) was the youngest daughter of the Prophet Muhammad (peace and blessings be upon him) and Khadeejah, the wife of Ali, the mother of al-Hasan and al-Husayn, and the leader of the women of Paradise. She lived simply, was told a secret on her father’s deathbed, and followed him six months later. Her sons are the leaders of the youth of Paradise: al-Hasan gave up the caliphate in 41 AH to unite the Muslims, as his grandfather had foretold, and al-Husayn was killed unjustly at Karbala in 61 AH. This chapter tells their lives from sound reports, explains the hadith of the cloak and the ayah of purification, and sets out the Sunni position on Karbala: grief and patience, without wailing and without excess."),
        ]),
        ArticleSection("THE YOUNGEST DAUGHTER", [
            .shortOnly(.text("Faatimah grew up in the years of persecution at Makkah, and in Madinah she married Ali ibn Abi Taalib (may Allah be pleased with him), the Prophet’s cousin, who had nothing to give her as a dowry but his coat of mail. They had al-Hasan, al-Husayn, Zaynab and Umm Kulthoom.")),
            .longOnly(.text("Faatimah grew up in the years of persecution at Makkah. When the Prophet (peace be upon him) was praying at the Ka‘bah and one of the leaders of Quraysh laid the entrails of a slaughtered camel on his back as he prostrated, it was the girl Faatimah who ran to him and threw the filth off him while the men laughed (Saheeh al-Bukhaari 240).")),
            .longOnly(.hadith("bukhari:240", cite: "Saheeh al-Bukhaari 240", arabic: 118...139, english: [117...153])),
            .longOnly(.text("In Madinah she married Ali ibn Abi Taalib (may Allah be pleased with him), the Prophet’s cousin. When Ali said he had nothing to give her, the Prophet asked him where his coat of mail was, and that was her dowry (Sunan Abi Daawood 2125).")),
            .longOnly(.hadith("abudawud:2125", cite: "Sunan Abi Daawood 2125; graded saheeh by al-Albaani", arabic: 17...43, english: [0...28])),
            .longOnly(.text("They had al-Hasan, al-Husayn, Zaynab and Umm Kulthoom. Aa’ishah (may Allah be pleased with her) described how father and daughter treated each other:")),
            .longOnly(.hadith("tirmidhi:3872", cite: "Jaami‘ at-Tirmidhi 3872; graded saheeh by al-Albaani", arabic: 29...82, english: [0...83])),
        ]),
        ArticleSection("A PART OF ME", [
            .text("The Prophet (peace be upon him) said of her, in words that every Muslim should know:"),
            .hadith("bukhari:3714", cite: "Saheeh al-Bukhaari 3714", arabic: 28...33, english: [4...18]),
            .longOnly(.text("He said it from the pulpit when Ali asked for the hand of the daughter of Abu Jahl. The Prophet stated plainly that he did not forbid what Allah had made lawful, but that the daughter of the Messenger of Allah and the daughter of the enemy of Allah would never be wives of one man, and Ali withdrew the proposal (Saheeh al-Bukhaari 3110, 3729). The ruling was particular to her, out of protection for her faith and her heart, and Ali took no other wife while she lived.")),
            .longOnly(.hadith("bukhari:3110", cite: "Saheeh al-Bukhaari 3110", arabic: 158...179, english: [202...247])),
            .longOnly(.hadith("bukhari:3729", cite: "Saheeh al-Bukhaari 3729", arabic: 67...94, english: [101...142])),
            .longOnly(.text("Her station is stated in other sayings too. One night an angel came down who had never come to earth before, and asked his Lord’s permission to greet the Prophet with the glad tidings that Faatimah is the leader of the women of Paradise and that al-Hasan and al-Husayn are the leaders of its youth (Jaami‘ at-Tirmidhi 3781).")),
            .shortOnly(.text("He also spoke of her station:")),
            .hadith("tirmidhi:3781", cite: "Jaami‘ at-Tirmidhi 3781; graded saheeh by al-Albaani", arabic: 113...141, english: [123...180]),
        ]),
        ArticleSection("THE TASBEEH IN PLACE OF A SERVANT", [
            .shortOnly(.text("The house of the Prophet’s daughter was poor. When captives came to Madinah, Faatimah, her hands blistered from the hand mill, asked her father for a servant, and he gave her words instead, a dhikr to say before sleeping. The household of the Prophet lived as he lived.")),
            .longOnly(.text("The house of the Prophet’s daughter was poor. Ali narrated:")),
            .longOnly(.hadith("bukhari:3113", cite: "Saheeh al-Bukhaari 3113, Saheeh Muslim 2727", arabic: 22...99, english: [0...173])),
            .longOnly(.text("Captives had come, yet to his own daughter the Prophet gave words instead of a servant. Ali said that he never once left them after that night. Someone asked, even on the night of Siffeen? He said, even on the night of Siffeen (Saheeh al-Bukhaari 5362). The household of the Prophet lived as he lived: a daughter with blistered hands, and a father who gave her a dhikr instead of a servant.")),
            .longOnly(.hadith("bukhari:5362", cite: "Saheeh al-Bukhaari 5362", arabic: 71...81, english: [44...76])),
        ]),
        ArticleSection("THE PEOPLE OF THE CLOAK", [
            .text("Aa’ishah (may Allah be pleased with her) narrated a morning that the books of creed return to again and again. The Prophet went out wearing a striped cloak of black camel hair; al-Hasan came and he took him in under it, then al-Husayn, then Faatimah, then Ali, and then he recited:"),
            .hadith("muslim:2424", cite: "Saheeh Muslim 2424", arabic: 35...78, english: [0...19]),
            .shortOnly(.text("The words he recited are from an ayah addressed to his wives:")),
            .longOnly(.text("The words he recited are from an ayah addressed to his wives, in a passage that speaks to them from 33:28 to 33:34:")),
            .ayah("33:33"),
            .longOnly(.ayah("33:28", words: 0...3)),
            .longOnly(.markdown("So the **Ahlul Bayt (أَهلُ البَيت)** of the ayah are his wives first, by its context, and Ali, Faatimah and their two sons by the Prophet’s own act of gathering them in. Neither reading removes the other. When the ayah of mutual invocation (**mubaahalah**) came down, inviting the Christians of Najraan to call their sons and women and themselves, the Prophet called Ali, Faatimah, al-Hasan and al-Husayn and said to Allah that these were his family (Saheeh Muslim 2404d).")),
            .longOnly(.hadith("muslim:2404d", cite: "Saheeh Muslim 2404d", arabic: 160...183, english: [207...237])),
            .longOnly(.ayah("3:61")),
            .longOnly(.markdown("What the ayah of purification does not mean is **‘ismah (عِصمَة)**, protection from all error, the way the Twelvers claim it for their imams. Ibn Taymiyyah (may Allah have mercy on him) argues in Minhaaj as-Sunnah that Allah’s will to purify them is His love for them and His command to them, the same language He uses for all the believers when He gives them wudu and tayammum: Allah does not intend to make difficulty for you, but He intends to purify you (5:6). The wives were not made sinless by it, and neither were Ali and his sons; all of them are honoured by it.")),
            .longOnly(.ayah("5:6", words: 46...55)),
            .shortOnly(.markdown("So the **Ahlul Bayt (أَهلُ البَيت)** of the ayah are his wives first, by its context, and Ali, Faatimah and their two sons by the Prophet’s own act of gathering them in. Neither reading removes the other.")),
        ]),
        ArticleSection("THE SECRET AND THE SIX MONTHS", [
            .shortOnly(.text("In the Prophet’s last illness Faatimah came in, walking with his own gait. He told her a secret that made her weep, that his death was near and that she would be the first of his family to follow him, and then another that made her laugh, that she would be the leader of the women of Paradise. She lived six months after him, exactly as he had told her, and Ali buried her at night.")),
            .longOnly(.text("In the Prophet’s last illness Faatimah came in, walking with his own gait. Aa’ishah saw what followed:")),
            .longOnly(.hadith("bukhari:3623", cite: "Saheeh al-Bukhaari 3623", arabic: 19...136, english: [0...184])),
            .longOnly(.text("When he died she mourned him in words that grief permits: O father, who answered the call of his Lord; O father, whose home is the Garden of al-Firdaws. And when he was buried she asked Anas how they had brought themselves to pour earth over the Messenger of Allah (Saheeh al-Bukhaari 4462).")),
            .longOnly(.hadith("bukhari:4462", cite: "Saheeh al-Bukhaari 4462", arabic: 39...79, english: [32...92])),
            .longOnly(.text("She lived six months after him (Saheeh al-Bukhaari 4240), the first of his family to follow him, exactly as he had told her, and Ali buried her at night. The question of the Prophet’s land at Fadak, which Abu Bakr did not distribute because the Prophet had said that the prophets leave no inheritance, belongs to that period; it is answered in its own place, and Ali kept the same ruling when he became caliph.")),
            .longOnly(.hadith("bukhari:4240", cite: "Saheeh al-Bukhaari 4240", arabic: 139...153, english: [165...186])),
            .door(.prophecy("fatimah-first")),
            .door(.article("ShiaAnswerView")),
        ]),
        ArticleSection("AL-HASAN, THE PEACEMAKER", [
            .text("Al-Hasan ibn Ali (may Allah be pleased with them) was born in Madinah in 3 AH, and Anas said that no one resembled the Prophet more than he did (Saheeh al-Bukhaari 3752)."),
            .hadith("bukhari:3752", cite: "Saheeh al-Bukhaari 3752", arabic: 24...36, english: [0...10]),
            .longOnly(.text("One afternoon after Asr, Abu Bakr found the boy playing in the street:")),
            .longOnly(.hadith("bukhari:3542", cite: "Saheeh al-Bukhaari 3542", arabic: 31...47, english: [13...48])),
            .longOnly(.text("The Prophet carried him on his shoulder and asked Allah to love him, because he loved him (Saheeh al-Bukhaari 3749). Once, when the two brothers came stumbling into the mosque in red shirts during the sermon, he came down from the pulpit, picked them up, recited that wealth and children are a trial (64:15), and said he could not bear to watch them stumble (Jaami‘ at-Tirmidhi 3774).")),
            .longOnly(.hadith("bukhari:3749", cite: "Saheeh al-Bukhaari 3749", arabic: 18...33, english: [0...20])),
            .longOnly(.ayah("64:15", words: 0...3)),
            .longOnly(.hadith("tirmidhi:3774", cite: "Jaami‘ at-Tirmidhi 3774; graded saheeh by al-Albaani", arabic: 26...81, english: [0...89])),
            .longOnly(.text("After Ali was killed in 40 AH, the people of Iraq pledged allegiance to al-Hasan, and he led great armies toward Syria. Mu‘aawiyah ibn Abi Sufyaan (may Allah be pleased with him), the Companion and scribe of the revelation (Saheeh Muslim 2501), asked who would be left to care for the people’s women and children if the two armies destroyed each other, and sent envoys to make peace.")),
            .longOnly(.hadith("muslim:2501", cite: "Saheeh Muslim 2501", arabic: 70...78, english: [38...51])),
            .shortOnly(.text("After Ali was killed in 40 AH, the people of Iraq pledged allegiance to al-Hasan, and he led great armies toward Syria, until Mu‘aawiyah ibn Abi Sufyaan (may Allah be pleased with him) sent envoys to make peace.")),
            .text("Al-Hasan accepted, and in 41 AH he handed over the rule. The Muslims called it the Year of Unity, and Abu Bakrah (may Allah be pleased with him) had heard the Prophet foretell it from the pulpit, with the boy at his side:"),
            .hadith("bukhari:2704", cite: "Saheeh al-Bukhaari 2704", arabic: 154...191, english: [240...294]),
            .text("The prophecy calls both armies Muslims, and it praises the man who gave up power to stop the bloodshed. Al-Hasan lived the rest of his life in Madinah and died there in about 49 or 50 AH (670 CE); he was buried in al-Baqee‘."),
            .door(.prophecy("hasan-reconciles")),
        ]),
        ArticleSection("AL-HUSAYN, THE YOUNGER LEADER", [
            .text("Al-Husayn ibn Ali (may Allah be pleased with them) was born a year after his brother. The two are joined in the Prophet’s praise:"),
            .hadith("tirmidhi:3768", cite: "Jaami‘ at-Tirmidhi 3768; graded saheeh by al-Albaani", arabic: 37...42, english: [7...17]),
            .longOnly(.text("He also said that Husayn is from him and he is from Husayn, and that Allah loves whoever loves Husayn (Jaami‘ at-Tirmidhi 3775), and, of both brothers, that whoever loves them loves him and whoever hates them hates him (Sunan Ibn Maajah 143). Love of them is part of faith for Ahl as-Sunnah, not a slogan borrowed from another sect: these hadiths are narrated in their books, by their imams, and recited in their mosques.")),
            .longOnly(.hadith("tirmidhi:3775", cite: "Jaami‘ at-Tirmidhi 3775; graded hasan by al-Albaani", arabic: 34...47, english: [7...27])),
            .longOnly(.hadith("ibnmajah:143", cite: "Sunan Ibn Maajah 143; graded hasan by al-Albaani", arabic: 37...46, english: [5...17])),
            .shortOnly(.text("Love of them is part of faith for Ahl as-Sunnah, not a slogan borrowed from another sect: the hadiths of their virtues are narrated in their books, by their imams, and recited in their mosques.")),
        ]),
        ArticleSection("KARBALA, 61 AH", [
            .shortOnly(.text("When Mu‘aawiyah died in 60 AH and his son Yazeed took the pledge, al-Husayn refused to give it. The people of Koofah sent him letter after letter inviting him to lead them, and though senior Companions, Ibn Abbaas and Ibn Umar among them, begged him not to go, he set out with his family and a small band. At Karbala, near the Euphrates, an army sent by Ubaydullah ibn Ziyaad, the governor of Koofah, surrounded them, and on the tenth of Muharram, 61 AH (680 CE), he was killed with about seventy of his household and companions. His son Ali, later called Zayn al-Aabideen, survived, and through him the line of al-Husayn continued.")),
            .longOnly(.text("When Mu‘aawiyah died in 60 AH and his son Yazeed took the pledge, al-Husayn refused to give it and went to Makkah. The people of Koofah sent him letter after letter inviting him to come and lead them. He sent his cousin Muslim ibn Aqeel ahead, and the new governor of Koofah, Ubaydullah ibn Ziyaad, had Muslim killed. Senior Companions, Ibn Abbaas, Ibn Umar and Abu Sa‘eed al-Khudri among them, begged al-Husayn not to go, warning him that the Kufans who had betrayed his father and brother would betray him; Ibn Katheer (may Allah have mercy on him) records their counsel in al-Bidaayah wan-Nihaayah.")),
            .longOnly(.text("He set out with his family and a small band. At Karbala, near the Euphrates, an army sent by Ibn Ziyaad and commanded by Umar, the son of Sa‘d ibn Abi Waqqaas, surrounded them. The historians report that al-Husayn offered to go back, or to go to a frontier, or to go to Yazeed himself, and that all of it was refused unless he surrendered to Ibn Ziyaad. On the tenth of Muharram, 61 AH (680 CE), he was killed with about seventy of his household and companions, among them, as the historians list, brothers of his named Abu Bakr, Uthmaan and al-Abbaas, sons of Ali. His son Ali, later called Zayn al-Aabideen, was ill and survived, and through him the line of al-Husayn continued.")),
            .longOnly(.text("Anas ibn Maalik (may Allah be pleased with him) was present when the head was brought to the governor:")),
            .longOnly(.hadith("bukhari:3748", cite: "Saheeh al-Bukhaari 3748", arabic: 24...56, english: [4...76])),
            .text("And Abdullah ibn Umar (may Allah be pleased with them), asked by a man from Iraq whether a pilgrim in ihraam may kill a fly, answered with the bitterest sentence in this chapter:"),
            .hadith("bukhari:3753", cite: "Saheeh al-Bukhaari 3753", arabic: 31...57, english: [18...58]),
        ]),
        ArticleSection("THE SUNNI POSITION ON KARBALA", [
            .text("Ahl as-Sunnah hold that al-Husayn (may Allah be pleased with him) was killed unjustly and died a martyr, honoured by Allah with that death, and that his killing is among the greatest crimes committed in this ummah; whoever killed him, helped in it or was pleased with it deserves Allah’s anger. They grieve for him as Allah allows grief, with the heart and the eyes, and say what Allah taught for every calamity:"),
            .ayah("2:155-157"),
            .text("They do not strike their faces, tear their clothes or wail, because the Prophet disowned it:"),
            .hadith("bukhari:1294", cite: "Saheeh al-Bukhaari 1294, Saheeh Muslim 103", arabic: 29...38, english: [4...27]),
            .longOnly(.text("The death of the Prophet himself, and the murders of Umar, Uthmaan and Ali, were greater calamities, and no Companion or member of the household made an annual ritual of any of them. Ibn Taymiyyah (may Allah have mercy on him) describes two innovations that grew up around the tenth of Muharram: the lamentation, self-beating and cursing of the Raafidah, and, in reaction, the dressing up and festivity of some Nawaasib and ignorant people. Both have no basis. The Sunnah of the day is what the Prophet did, which was to fast it in thanks for Moosa’s deliverance (Saheeh al-Bukhaari 2004).")),
            .longOnly(.hadith("bukhari:2004", cite: "Saheeh al-Bukhaari 2004", arabic: 26...66, english: [0...71])),
            .shortOnly(.text("The death of the Prophet himself, and the murders of Umar, Uthmaan and Ali, were greater calamities, and no Companion or member of the household made an annual ritual of any of them. Ibn Taymiyyah (may Allah have mercy on him) describes two innovations that grew up around the tenth of Muharram, the lamentation of the Raafidah and, in reaction, the festivity of some Nawaasib, and both have no basis.")),
            .text("On Yazeed ibn Mu‘aawiyah, in whose reign it happened, Ahl as-Sunnah follow the position Ibn Taymiyyah records from Ahmad and the imams: he was one of the kings of the Muslims, not a Companion and not one of the righteous; he is neither loved nor cursed by name, and the crime of Karbala is not excused."),
            .longOnly(.callout("The Raafidah turn love of al-Husayn into hatred of the Companions and a calendar of mourning. The Nawaasib belittle the household to defend the Umayyads. Ahl as-Sunnah love al-Husayn, love his grandfather’s Companions, grieve with patience, and leave the judgment of his killers to Allah.", title: "Between Two Errors", icon: "scalemass.fill")),
            .door(.article("AhlulBaytView")),
            .door(.article("ShiaAnswerView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Why did al-Husayn go if the Companions advised him not to?**"),
            .text("He judged that the call of the Kufans was a duty he could answer, and he was a Companion and a man of knowledge acting on his ijtihaad. The Companions who advised him judged that the Kufans would betray him, and events proved them right. Ahl as-Sunnah say both: he was not a rebel to be blamed, and the counsel of those who warned him was sound."),
            .longOnly(.markdown("**Does descent from Faatimah bring any special status?**")),
            .longOnly(.text("It brings honour and rights: love, respect, the share of the Prophet’s kin, and the prohibition of zakaah for them (Saheeh Muslim 1072). It does not bring salvation by itself. When Allah commanded him to warn his nearest kin, the Prophet called his daughter by name and told her to ask him for whatever she wished of his wealth, for he could not avail her anything against Allah (Saheeh al-Bukhaari 2753). His descendants are judged by their faith and deeds like everyone else.")),
            .longOnly(.hadith("muslim:1072a", cite: "Saheeh Muslim 1072", arabic: 242...252, english: [367...384])),
            .longOnly(.hadith("bukhari:2753", cite: "Saheeh al-Bukhaari 2753", arabic: 92...106, english: [65...82])),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Faatimah, the Prophet’s youngest daughter and a part of him, lived poor and contented, received the tasbeeh in place of a servant, was gathered with Ali and her sons under the cloak, and followed her father six months after his death as he had foretold; she is the leader of the women of Paradise. Al-Hasan gave up power to unite the Muslims in 41 AH, fulfilling the prophecy that Allah would make peace through him. Al-Husayn was killed unjustly at Karbala in 61 AH. Ahl as-Sunnah love all three and their household together with the Companions, grieve for al-Husayn with patience, and reject both the wailing of the Raafidah and the coldness of the Nawaasib."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Ahl al-Kisaa’", arabic: "أَهلُ الكِسَاءِ", meaning: "**The people of the cloak**: Ali, Faatimah, al-Hasan and al-Husayn, whom the Prophet gathered under his cloak while reciting 33:33. The wives are the household by the ayah’s context, and these four by his act."),
            .term("Sayyidah", arabic: "سَيِّدَة", meaning: "**Leader** or mistress. Faatimah is sayyidat nisaa’ ahl al-jannah, the leader of the women of Paradise, and her sons are sayyida shabaab ahl al-jannah, the leaders of its youth."),
            .term("Mubaahalah", arabic: "مُبَاهَلَة", meaning: "**Mutual invocation**: two disputing parties call down Allah’s curse on whichever of them is lying (3:61). The Christians of Najraan declined it and agreed to terms instead."),
            .term("‘Am al-Jamaa‘ah", arabic: "عَامُ الجَمَاعَةِ", meaning: "**The Year of Unity**, 41 AH, when al-Hasan handed the rule to Mu‘aawiyah and the Muslims were united again under one ruler."),
        ]),
    ]
}

struct CompanionUnclesView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionUnclesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Hamzah, al-Abbaas and Ja‘far")
        .englishArticle().selectableArticleList(article: "CompanionUnclesView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: four of the paternal uncles of the Prophet Muhammad (peace and blessings be upon him) lived to hear his call. Two believed: Hamzah, who fell at Uhud, and al-Abbaas, through whose prayer the Companions asked Allah for rain after the Prophet’s death. Two did not: Abu Taalib, who protected him and died on the religion of his fathers, and Abu Lahab, whom a whole surah condemns. Beside them stands his cousin Ja‘far ibn Abi Taalib, who spoke for the Muslims before the Negus of Abyssinia and died at Mu’tah, and whom the Prophet called like himself in form and character. This chapter tells their stories from sound reports, and draws two lessons from them: that kinship with the Prophet saves no one without faith, and that seeking a righteous man’s prayer is not the same as calling on the dead."),
        ]),
        ArticleSection("FOUR UNCLES, TWO PATHS", [
            .shortOnly(.text("Abd al-Muttalib, the Prophet’s grandfather, had many sons, and four lived to hear the revelation: Abu Taalib, who raised and shielded him and refused to believe; Abu Lahab, his loudest enemy; Hamzah, his foster brother, who believed in Makkah and died a martyr; and al-Abbaas, who came to Islam late and lived long. The Quran’s command to warn his nearest kin was carried out on exactly these people. Abu Hurayrah (may Allah be pleased with him) narrated:")),
            .longOnly(.text("Abd al-Muttalib, the Prophet’s grandfather, had many sons, and most of them died before the revelation. Four lived to hear it. Abu Taalib, the full brother of the Prophet’s father, raised him and shielded him for more than forty years and refused to believe. Abu Lahab became his loudest enemy. Hamzah, close to him in age and his foster brother, believed in Makkah and died a martyr. Al-Abbaas, a few years older than him, came to Islam late and lived long. His aunt Safiyyah bint Abd al-Muttalib, the mother of az-Zubayr, also believed and emigrated.")),
            .longOnly(.text("The Quran’s command to warn his nearest kin was carried out on exactly these people. Abu Hurayrah (may Allah be pleased with him) narrated:")),
            .hadith("bukhari:2753", cite: "Saheeh al-Bukhaari 2753", arabic: 44...106, english: [16...82]),
            .longOnly(.text("The Arabic of this narration names al-Abbaas too, telling him in the same words that the Prophet could not avail him anything against Allah. The same words reached the uncles who believed and the uncles who refused. What divided them was not blood but faith.")),
            .shortOnly(.text("The same words reached the uncles who believed and the uncles who refused. What divided them was not blood but faith.")),
        ]),
        ArticleSection("HAMZAH IBN ABD AL-MUTTALIB", [
            .shortOnly(.text("Hamzah (may Allah be pleased with him) was the Prophet’s uncle and his foster brother, and the biographers agree that his Islam in Makkah made Quraysh more careful with the Prophet. At Badr, in 2 AH, he was one of the three Muslims who answered the challenge to single combat before the battle, and a year later, at Uhud, he was killed. The man who killed him told the story himself, years afterwards, in Hims:")),
            .longOnly(.text("Hamzah (may Allah be pleased with him) was the Prophet’s uncle and his foster brother, for the same woman had nursed them both; that is why the Prophet said of Hamzah’s daughter that she was not lawful for him to marry (Saheeh al-Bukhaari 2645). Ibn Ishaaq relates that he came home from hunting one day to hear that Abu Jahl had abused his nephew at as-Safa, went straight to the Ka‘bah, struck Abu Jahl with his bow and declared that he was of Muhammad’s religion. Whatever the exact details of that report, the biographers agree that his Islam in Makkah made Quraysh more careful with the Prophet.")),
            .longOnly(.hadith("bukhari:2645", cite: "Saheeh al-Bukhaari 2645", arabic: 27...46, english: [0...33])),
            .longOnly(.text("At Badr, in 2 AH, Hamzah was one of the three Muslims who answered the challenge to single combat before the battle, with Ali and Ubaydah ibn al-Haarith. Abu Dharr (may Allah be pleased with him) used to swear that an ayah came down about those six men:")),
            .longOnly(.hadith("bukhari:3969", cite: "Saheeh al-Bukhaari 3969", arabic: 20...46, english: [0...52])),
            .longOnly(.ayah("22:19")),
            .longOnly(.text("A year later, at Uhud, he was killed. The man who killed him told the story himself, years afterwards, in Hims:")),
            .hadith("bukhari:4072", cite: "Saheeh al-Bukhaari 4072", arabic: 158...362, english: [217...250, 461...500, 521...538]),
            .longOnly(.text("Wahshi was a slave promised his freedom if he killed Hamzah. He later accepted Islam, and the Prophet took his Islam and asked only that he keep out of his sight, a man’s grief for his uncle, not a refusal of his repentance. Wahshi went on to kill Musaylimah the Liar in the war against the false prophet, hoping to balance the life he had taken. Islam wipes out what came before it, as the Prophet told Amr ibn al-As (Saheeh Muslim 121), even this.")),
            .longOnly(.hadith("muslim:121", cite: "Saheeh Muslim 121", arabic: 176...196, english: [223...258])),
            .longOnly(.text("Hamzah’s body was mutilated on the field. His sister Safiyyah came with two cloths to shroud him, and az-Zubayr, finding an Ansaari lying unshrouded beside him, divided the cloths between the two men by lot (Musnad Ahmad 1418). Years later Abd ar-Rahman ibn Awf wept over his food remembering that Hamzah, who was better than he, had nothing but a single sheet to be shrouded in (Saheeh al-Bukhaari 1274). The scholars call him Sayyid ash-Shuhadaa’, the leader of the martyrs, from a hadith that al-Albaani graded hasan.")),
            .longOnly(.hadith("ahmed:1418", cite: "Musnad Ahmad 1418; its chain graded hasan by Darussalam", arabic: 110...162, english: [156...262])),
            .longOnly(.hadith("bukhari:1274", cite: "Saheeh al-Bukhaari 1274", arabic: 27...72, english: [16...88])),
            .shortOnly(.text("Hamzah’s body was mutilated on the field, and he was shrouded in a single sheet. The scholars call him Sayyid ash-Shuhadaa’, the leader of the martyrs.")),
        ]),
        ArticleSection("AL-ABBAAS IBN ABD AL-MUTTALIB", [
            .longOnly(.text("Al-Abbaas (may Allah be pleased with him) held the right of giving water to the pilgrims at Makkah, and he was a merchant of standing. Ibn Ishaaq relates that, while still on his people’s religion, he attended the second pledge of al-Aqabah to make sure that the men of Madinah meant to protect his nephew. At Badr he marched with Quraysh and was taken captive. The Ansaar, whose clan of Banu an-Najjaar was related to him through his grandmother, asked to let him go without ransom:")),
            .longOnly(.hadith("bukhari:3048", cite: "Saheeh al-Bukhaari 3048", arabic: 43...55, english: [14...36])),
            .longOnly(.text("The Prophet’s own uncle paid in full. His Islam was declared openly before the conquest of Makkah in 8 AH, and at Hunayn soon after, when the Muslim ranks broke and fled, he stood holding the bridle of the Prophet’s mule:")),
            .shortOnly(.text("Al-Abbaas (may Allah be pleased with him) held the right of giving water to the pilgrims at Makkah. He marched with Quraysh at Badr and was taken captive, and his Islam was declared openly before the conquest of Makkah in 8 AH. At Hunayn soon after, when the Muslim ranks broke and fled, he stood holding the bridle of the Prophet’s mule:")),
            .hadith("muslim:1775a", cite: "Saheeh Muslim 1775a", arabic: 124...152, english: [132...184]),
            .longOnly(.markdown("The **people of the Samurah** were those who had pledged under the acacia tree at al-Hudaybiyah. The Prophet honoured al-Abbaas as a father. When Umar was sent to collect the zakaah and it was reported that al-Abbaas had held his back, the Prophet said he would answer for it himself, and more:")),
            .longOnly(.hadith("muslim:983", cite: "Saheeh Muslim 983", arabic: 74...93, english: [37...71])),
            .longOnly(.text("He died in Madinah in about 32 AH. The Prophet had prayed that Allah give his son Abdullah understanding of the religion (Saheeh al-Bukhaari 143), and Abdullah ibn Abbaas became the great interpreter of the Quran among the Companions. Centuries later the Abbasid caliphs took their name from al-Abbaas.")),
            .longOnly(.hadith("bukhari:143", cite: "Saheeh al-Bukhaari 143", arabic: 22...45, english: [0...38])),
            .shortOnly(.text("He died in Madinah in about 32 AH, and his son Abdullah ibn Abbaas became the great interpreter of the Quran among the Companions.")),
            .door(.article("CaliphatesView")),
        ]),
        ArticleSection("THE RAIN PRAYER AND WHAT IT TEACHES", [
            .text("After the Prophet’s death, in a year of drought, Umar did something that has been discussed in every century since:"),
            .hadith("bukhari:1010", cite: "Saheeh al-Bukhaari 1010", arabic: 36...59, english: [0...64]),
            .longOnly(.markdown("The word Umar used is **tawassul (تَوَسُّل)**, seeking a means of approach to Allah. In the Prophet’s lifetime the Companions went to him and asked him to pray for rain, and he prayed. After his death Umar did not go to his grave, a few steps away, to ask him for anything. He brought the Prophet’s living uncle forward, asked Allah through his prayer, and the rain came.")),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) explains in his treatise on tawassul what this shows: the tawassul the Companions knew was through the Prophet’s prayer while he lived, and after his death through the prayer of living righteous men. Had asking by the Prophet’s person or rank after his death been lawful, the Companions would not have left the best of creation for his uncle. Asking a living Muslim to pray for you is a Sunnah; calling on the dead to answer is what Allah forbade.")),
            .shortOnly(.markdown("The word Umar used is **tawassul (تَوَسُّل)**, seeking a means of approach to Allah. In the Prophet’s lifetime the Companions asked him to pray for rain; after his death Umar did not go to his grave, a few steps away, but brought the Prophet’s living uncle forward and asked Allah through his prayer. Had asking by the Prophet’s person after his death been lawful, the Companions would not have left the best of creation for his uncle. Asking a living Muslim to pray for you is a Sunnah; calling on the dead to answer is what Allah forbade:")),
            .ayah("72:18"),
            .door(.article("UluhiyyahView")),
        ]),
        ArticleSection("JA‘FAR IBN ABI TAALIB", [
            .longOnly(.text("Ja‘far (may Allah be pleased with him), the son of Abu Taalib and Ali’s elder brother, believed early, and when the persecution in Makkah became unbearable he was among the Muslims who emigrated across the Red Sea to the Christian kingdom of Abyssinia, and he became their spokesman there. Ibn Ishaaq relates, from Umm Salamah, who was among the emigrants, that when Quraysh sent envoys to have them handed back, the Negus summoned the Muslims, and Ja‘far spoke for them: they had been a people who worshipped idols, ate carrion, cut off their kin and wronged their neighbours, until Allah sent them a messenger whose lineage, truthfulness and chastity they knew. He recited the opening of Surah Maryam, and the king wept. Asked what they said of Eesa, he answered that he is the servant of Allah, His messenger, His spirit and His word cast into Maryam.")),
            .longOnly(.text("Whatever the exact words of that audience, its outcome is in the Saheeh. The Negus protected them, and when he died the Prophet announced it the same day and led the Muslims in the funeral prayer for him in his absence, telling them it was for their brother (Saheeh al-Bukhaari 1245, 3877).")),
            .longOnly(.hadith("bukhari:1245", cite: "Saheeh al-Bukhaari 1245", arabic: 20...40, english: [0...40])),
            .longOnly(.hadith("bukhari:3877", cite: "Saheeh al-Bukhaari 3877", arabic: 18...37, english: [0...24])),
            .shortOnly(.text("Ja‘far (may Allah be pleased with him), the son of Abu Taalib and Ali’s elder brother, believed early, and when the persecution in Makkah became unbearable he emigrated with other Muslims to the Christian kingdom of Abyssinia and became their spokesman there. Ibn Ishaaq relates that when Quraysh sent envoys to have them handed back, Ja‘far told the Negus what Islam had made of them and recited the opening of Surah Maryam, and the king wept and protected them.")),
            .door(.prophecy("najashi")),
            .longOnly(.text("Ja‘far stayed in Abyssinia for years and reached Madinah only in 7 AH, as Khaybar fell. When Umar teased Asmaa’ bint Umays, Ja‘far’s wife, that those who had emigrated to Madinah had more right to the Prophet, she took the complaint to the Prophet himself:")),
            .longOnly(.hadith("muslim:2502", cite: "Saheeh Muslim 2502", arabic: 333...345, english: [479...509])),
            .longOnly(.text("He was generous to the point of emptiness. Abu Hurayrah said that Ja‘far was the best of people to the poor: he would take them home and feed them whatever he had, and if there was nothing, he would bring out a butter skin with nothing in it, and they would split it open and lick what clung inside (Saheeh al-Bukhaari 3708).")),
            .longOnly(.hadith("bukhari:3708", cite: "Saheeh al-Bukhaari 3708", arabic: 77...106, english: [94...146])),
            .longOnly(.text("In 7 AH, when the daughter of Hamzah ran after the Muslims leaving Makkah and Ali, Ja‘far and Zayd all claimed the right to raise her, the Prophet gave her to her maternal aunt, who was Ja‘far’s wife, and then spoke to each of the three:")),
            .longOnly(.hadith("bukhari:2699", cite: "Saheeh al-Bukhaari 2699", arabic: 205...239, english: [329...389])),
        ]),
        ArticleSection("MU’TAH AND THE TWO WINGS", [
            .text("In 8 AH the Prophet sent an army north toward the Byzantine frontier and named its commanders in order:"),
            .hadith("bukhari:4261", cite: "Saheeh al-Bukhaari 4261", arabic: 28...86, english: [0...90]),
            .longOnly(.text("Ibn Umar, who counted the wounds, said in another report that none of them was in his back (Saheeh al-Bukhaari 4260). In Madinah, six hundred miles away, the Prophet announced the deaths of the three commanders one after another with his eyes full of tears, and then told the people that Khaalid ibn al-Waleed had taken the banner and Allah had given victory (Saheeh al-Bukhaari 1246). He told the people to cook for Ja‘far’s family, because what had befallen them left them no room for it (Sunan Abi Daawood 3132), and after three days he came to the children, told them not to weep for his brother after that day, and had their heads shaved (Sunan Abi Daawood 4192).")),
            .longOnly(.hadith("bukhari:4260", cite: "Saheeh al-Bukhaari 4260", arabic: 19...38, english: [0...43])),
            .longOnly(.hadith("bukhari:1246", cite: "Saheeh al-Bukhaari 1246", arabic: 30...65, english: [4...68])),
            .longOnly(.hadith("abudawud:3132", cite: "Sunan Abi Daawood 3132; graded hasan by al-Albaani", arabic: 25...33, english: [6...23])),
            .longOnly(.hadith("abudawud:4192", cite: "Sunan Abi Daawood 4192; graded saheeh by al-Albaani", arabic: 35...75, english: [0...65])),
            .shortOnly(.text("In Madinah, six hundred miles away, the Prophet announced the deaths of the three commanders one after another with his eyes full of tears.")),
            .door(.prophecy("mutah-martyrs")),
            .text("He also told them where Ja‘far was:"),
            .hadith("tirmidhi:3763", cite: "Jaami‘ at-Tirmidhi 3763; graded saheeh by al-Albaani", arabic: 30...36, english: [7...15]),
            .longOnly(.text("So the Companions called him Dhul-Janaahayn, the one with two wings. Whenever Abdullah ibn Umar greeted Ja‘far’s son Abdullah, he gave him the salaam as the son of the one with two wings (Saheeh al-Bukhaari 3709).")),
            .longOnly(.hadith("bukhari:3709", cite: "Saheeh al-Bukhaari 3709", arabic: 15...35, english: [0...24])),
            .shortOnly(.text("So the Companions called him Dhul-Janaahayn, the one with two wings.")),
        ]),
        ArticleSection("THE TWO WHO DID NOT BELIEVE", [
            .text("Abu Taalib protected the Prophet for decades and endured the boycott of Banu Haashim for his sake, yet he would not say the testimony of faith. His nephew sat by his deathbed:"),
            .hadith("bukhari:3884", cite: "Saheeh al-Bukhaari 3884", arabic: 32...115, english: [25...164]),
            .ayah("28:56"),
            .longOnly(.text("Al-Abbaas asked the Prophet what all of Abu Taalib’s protection had availed him. He answered that Abu Taalib is in a shallow part of the Fire, and that but for him he would have been in its lowest depth (Saheeh al-Bukhaari 3883). His intercession lightens the punishment of one man and changes nothing of the rule: it was his own uncle, and Allah told him that guidance is not his to give.")),
            .longOnly(.hadith("bukhari:3883", cite: "Saheeh al-Bukhaari 3883", arabic: 24...54, english: [0...62])),
            .shortOnly(.text("Kinship with the Prophet could not save the man who had protected him: it was his own uncle, and Allah told him that guidance is not his to give.")),
            .longOnly(.text("Abu Lahab, whose name was Abd al-Uzza, was the first to answer the Prophet’s public call with a curse:")),
            .longOnly(.hadith("bukhari:4971", cite: "Saheeh al-Bukhaari 4971", arabic: 46...100, english: [27...119])),
            .shortOnly(.text("Abu Lahab, whose name was Abd al-Uzza, was the first to answer the Prophet’s public call with a curse, and a whole surah came down about him:")),
            .ayah("111:1-5"),
            .longOnly(.text("The surah declared, years before his death, that he would burn in the Fire. He could have tried to disprove it with a single false profession of faith, and he never did; he died soon after Badr still an enemy, as the surah foretold.")),
            .shortOnly(.text("The surah declared, years before his death, that he would burn in the Fire, and he died soon after Badr still an enemy, as the surah foretold.")),
            .door(.prophecy("abu-lahab")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Was Abu Taalib secretly a Muslim, as some claim?**"),
            .text("No. The Saheeh is explicit that his last words were that he died on the religion of Abd al-Muttalib, that the Prophet’s wish to keep asking forgiveness for him was answered by 9:113, and that 28:56 came down about him. One of the narrators of his state in the Hereafter is his own brother al-Abbaas. Ahl as-Sunnah honour his protection of the Prophet and do not make him a believer against the texts."),
            .ayah("9:113", words: 0...7),
            .door(.article("ShiaAnswerView")),
            .markdown("**Is it wrong to visit the graves of Hamzah and the martyrs of Uhud?**"),
            .text("Visiting them is a Sunnah for men: the visitor greets them, asks Allah to forgive them and have mercy on them, and remembers death. What is forbidden is to ask them for anything, to call on Hamzah for help, or to pray toward their graves. Umar’s choice at the rain prayer draws the line: ask the living to pray for you, and ask Allah alone for everything."),
            .markdown("**Does being from the Prophet’s family give any special rights?**"),
            .text("Yes: love and honour, the share of the Prophet’s kin, and the prohibition of zakaah for the families of Ali, Aqeel, Ja‘far and al-Abbaas (Saheeh Muslim 2408). But the same Prophet who honoured al-Abbaas as a father told him that he could not avail him anything against Allah. Rights come from kinship; salvation comes from faith."),
            .hadith("muslim:2408a", cite: "Saheeh Muslim 2408", arabic: 216...244, english: [279...339]),
            .door(.article("AhlulBaytView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Of the four uncles who heard the call, Hamzah believed and died at Uhud, the first among the martyrs, killed by a man who later repented; al-Abbaas believed late, paid his ransom in full, called the fleeing army back at Hunayn, and became the man through whose prayer the Companions asked Allah for rain. Abu Taalib protected the Prophet and died refusing the testimony of faith, and Abu Lahab died the enemy a surah had named him. Ja‘far, the cousin who resembled the Prophet in form and character, spoke for Islam before a Christian king and died at Mu’tah with more than ninety wounds, all in front; Allah gave him two wings in Paradise. Their stories teach that kinship honours but does not save, and that the Companions sought the prayers of the living, never the help of the dead."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Dhul-Janaahayn", arabic: "ذُو الجَنَاحَينِ", meaning: "**The one with two wings**: Ja‘far ibn Abi Taalib, whom the Prophet saw flying in Paradise with the angels after his death at Mu’tah."),
            .term("Siqaayah", arabic: "سِقَايَة", meaning: "The **office of giving water** to the pilgrims at Makkah, held before Islam by al-Abbaas. The Prophet let him spend the nights of Mina in Makkah for its sake (Saheeh al-Bukhaari 1634)."),
            .hadith("bukhari:1634", cite: "Saheeh al-Bukhaari 1634", arabic: 23...48, english: [0...37]),
            .term("Tawassul", arabic: "تَوَسُّل", meaning: "**Seeking a means** of approach to Allah. The lawful kinds are through His names and attributes, one’s own good deeds, and the prayer of a living righteous person, as Umar did with al-Abbaas; calling on the dead is not among them."),
            .term("Sayyid ash-Shuhadaa’", arabic: "سَيِّدُ الشُّهَدَاءِ", meaning: "**The leader of the martyrs**: the title of Hamzah ibn Abd al-Muttalib, killed at Uhud in 3 AH."),
        ]),
    ]
}

// MARK: - companions-3

struct CompanionFirstBelieversView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionFirstBelieversView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The First Believers and the First Martyrs")
        .englishArticle().selectableArticleList(article: "CompanionFirstBelieversView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the first Muslims of Makkah were few, and most of them had no tribe to shield them: slaves, freedmen, strangers and the young. Seven declared their Islam openly, and under torture all of them except Bilaal gave their persecutors the words they demanded; Allah excused them, and Sumayyah and her husband Yaasir, killed for their faith, are remembered as the first martyrs. Khabbaab was taught patience under the iron combs, Mus‘ab ibn Umayr carried the Quran to Madinah and was buried in a cloak too short to cover him, Abu Dharr shouted the testimony in the Sanctuary, and the first emigrants found refuge in Abyssinia. Their lives show what faith cost at the beginning, and why Allah ranked the forerunners above those who came after."),
        ]),
        ArticleSection("THE FEW AT THE BEGINNING", [
            .text("The Prophet Muhammad (peace and blessings be upon him) called people to Islam quietly for about three years, the biographers say, before he was commanded to call openly. The first to believe were those closest to him: his wife Khadeejah, his friend Abu Bakr, his young cousin Ali and his freed servant Zayd ibn Haarithah (may Allah be pleased with them); Khadeejah, Abu Bakr and Ali have chapters of their own. Beyond that household the believers were a handful. Ammaar ibn Yaasir (may Allah be pleased with him) remembered how few:"),
            .hadith("bukhari:3660", cite: "Saheeh al-Bukhaari 3660", arabic: 24...38, english: [0...18]),
            .longOnly(.text("Sa‘d ibn Abi Waqqaas (may Allah be pleased with him) said that for seven days after he accepted Islam he was one third of the Muslims he knew of (Saheeh al-Bukhaari 3727).")),
            .longOnly(.hadith("bukhari:3727", cite: "Saheeh al-Bukhaari 3727", arabic: 29...44, english: [0...27])),
            .longOnly(.text("The leaders of Quraysh noticed who these people were and made it an argument against the message: if the Prophet wanted the nobles to sit with him, let him send away the poor. Sa‘d named the men they meant:")),
            .longOnly(.hadith("muslim:2413b", cite: "Saheeh Muslim 2413", arabic: 23...86, english: [0...102])),
            .longOnly(.ayah("6:52", words: 0...8)),
            .longOnly(.text("Heraclius drew the same lesson from the other side. When he questioned Abu Sufyaan about the new prophet, he asked whether the nobles followed him or the weak, and on hearing that it was the weak he said that such are the followers of the messengers (Saheeh al-Bukhaari 7). A message that grows first among the powerless cannot be explained by the power it brings, because at the beginning it brought them nothing but suffering.")),
        ]),
        ArticleSection("SEVEN WHO DECLARED IT", [
            .text("Abdullah ibn Mas‘ood (may Allah be pleased with him), himself one of the earliest believers, named the first to make their Islam public, and told what it cost them:"),
            .hadith("ibnmajah:150", cite: "Sunan Ibn Maajah 150; graded hasan saheeh by al-Albaani", arabic: 29...115, english: [0...141]),
            .longOnly(.text("Ibn Mas‘ood’s account is plain about something storytellers sometimes soften. The Prophet (peace be upon him) and Abu Bakr were shielded by family, and the others had no one. Ammaar and his mother belonged to a family of outsiders living under the protection of the clan of Makhzoom; Suhayb, an Arab carried off as a boy and raised among the Byzantines, was a stranger in Makkah; Bilaal was a slave; and al-Miqdaad was an ally of a Qurashi house, not a son of it. Every one of them except Bilaal gave the persecutors the words they wanted, and Ibn Mas‘ood says it without reproach, because Allah Himself excused it, as the story of Ammaar below shows.")),
            .shortOnly(.text("The Prophet (peace be upon him) and Abu Bakr were shielded by family, and the others had no one. Every one of them except Bilaal gave the persecutors the words they wanted, and Ibn Mas‘ood says it without reproach, because Allah Himself excused it, as the story of Ammaar below shows.")),
            .longOnly(.text("Al-Miqdaad’s faith showed its weight later. At Badr, when the Muslims faced an army about three times their number, he came to the Prophet and spoke in a way Ibn Mas‘ood said he would have loved more than anything to have been the one to say:")),
            .longOnly(.hadith("bukhari:3952", cite: "Saheeh al-Bukhaari 3952", arabic: 41...68, english: [48...103])),
        ]),
        ArticleSection("BILAAL AND THE ONE WORD", [
            .longOnly(.markdown("**Bilaal ibn Rabaah (may Allah be pleased with him)** was born a slave in Makkah to Abyssinian parents and belonged to the clan of Jumah, whose chief, **Umayyah ibn Khalaf**, led his torment. In Ibn Mas‘ood’s report the persecutors handed him to boys who dragged him through the ravines of Makkah while he repeated one word: **Ahad (أَحَد)**, One. It was the whole message in a word, the oneness of Allah, said by a man whose body was not his own.")),
            .longOnly(.text("Abu Bakr (may Allah be pleased with him) bought him and set him free, and Umar (may Allah be pleased with him) later summed up what that meant:")),
            .shortOnly(.markdown("**Bilaal ibn Rabaah (may Allah be pleased with him)** was born a slave in Makkah to Abyssinian parents, and **Umayyah ibn Khalaf**, the chief of his clan of Jumah, led his torment. The one word he repeated, **Ahad (أَحَد)**, One, was the whole message in a word. Abu Bakr (may Allah be pleased with him) bought him and set him free, and Umar (may Allah be pleased with him) later summed up what that meant:")),
            .hadith("bukhari:3754", cite: "Saheeh al-Bukhaari 3754", arabic: 27...33, english: [4...15]),
            .longOnly(.text("Freedom did not end his part in the story. When the Muslims of Madinah needed a way to call to the prayer, Umar suggested a man’s voice, and the Prophet (peace be upon him) told Bilaal to stand and call (Saheeh al-Bukhaari 604).")),
            .longOnly(.hadith("bukhari:604", cite: "Saheeh al-Bukhaari 604", arabic: 20...69, english: [0...99])),
            .longOnly(.text("The slave who had been forced to the ground in the sun of Makkah became the first muezzin of Islam, calling “Allah is the Greatest” five times a day over the city that sheltered the believers. At Badr he met Umayyah ibn Khalaf again, a captive under the protection of Abd ar-Rahman ibn Awf, and Bilaal raised the Ansaar against him, saying he would not be saved if Umayyah were saved; Umayyah was killed that day (Saheeh al-Bukhaari 2301).")),
            .longOnly(.hadith("bukhari:2301", cite: "Saheeh al-Bukhaari 2301", arabic: 76...93, english: [95...119])),
            .shortOnly(.text("When the Muslims of Madinah needed a way to call to the prayer, the Prophet told Bilaal to stand and call, and the slave who had been forced to the ground in the sun of Makkah became the first muezzin of Islam.")),
            .text("Then came the hadith every Muslim remembers about him:"),
            .hadith("bukhari:1149", cite: "Saheeh al-Bukhaari 1149", arabic: 34...74, english: [12...65]),
            .text("The Prophet heard the steps of a former slave walking ahead of him in Paradise, and the deed behind them was small and constant: prayer after every purification. After the Prophet’s death Bilaal went north with the armies to Syria, and he died in Damascus around 20 AH (641 CE)."),
            .longOnly(.callout("A story is widely told that Bilaal refused to give the adhan after the Prophet died and then gave it once more in Madinah, bringing the whole city to tears. Its chain is weak, and adh-Dhahabi judged it unreliable, so it is not told here. The hadith of his footsteps is honour enough.", title: "A Note on a Famous Story", icon: "exclamationmark.triangle.fill")),
        ]),
        ArticleSection("THE FAMILY OF YAASIR", [
            .shortOnly(.text("Yaasir came to Makkah from Yemen and married Sumayyah (may Allah be pleased with her), a slave woman of the clan of Makhzoom. The family had no kin in Makkah to avenge them, and when they accepted Islam, men of Makhzoom, Abu Jahl among them, tortured them on the open ground in the heat of the day.")),
            .longOnly(.text("Yaasir came to Makkah from Yemen and settled under the protection of Abu Hudhayfah ibn al-Mugheerah of the clan of Makhzoom, who gave him his slave woman Sumayyah (may Allah be pleased with her) in marriage. Their son Ammaar was born free, but the family had no kin in Makkah to avenge them. When they accepted Islam, men of Makhzoom, Abu Jahl among them, took them out onto the open ground in the heat of the day and tortured them.")),
            .longOnly(.text("The biographers relate that the Prophet (peace be upon him) passed by them as they suffered and told them to be patient, for their appointed meeting was in Paradise; al-Albaani graded the narration hasan saheeh in his notes on Fiqh as-Seerah. He could not free them, and he did not tell them to give in. Sumayyah would not give in. Mujaahid, the student of Ibn Abbaas, said that the first martyr in Islam was Sumayyah, the mother of Ammaar, whom Abu Jahl killed with a spear (Ibn Sa‘d, at-Tabaqaat al-Kubra), and Yaasir died under the same torment. They were the first believers to die for saying that their Lord is Allah, years before there was an army or a battlefield. Of such people Allah says:")),
            .shortOnly(.text("The biographers relate that the Prophet (peace be upon him) passed by them as they suffered and told them to be patient, for their appointed meeting was in Paradise. Sumayyah would not give in: Abu Jahl killed her with a spear, and Yaasir died under the same torment, the first believers to die for saying that their Lord is Allah. Of such people Allah says:")),
            .ayah("3:169"),
            .text("Ammaar survived, and his survival raised a question that every persecuted believer since has asked. Under torture he said what his tormentors demanded, as Ibn Mas‘ood reported of all the seven except Bilaal. The scholars of tafseer relate that he came to the Prophet in distress; the Prophet asked how he found his heart, Ammaar said it was at rest in faith, and Allah revealed:"),
            .ayah("16:106", words: 6...11),
            .longOnly(.text("Ibn Katheer (may Allah have mercy on him) cites this occasion under the verse, through reports that stop short of a named Companion, and records the agreement of the scholars on the ruling it carries. A believer forced by a real threat of death or torture may say a word of disbelief with his tongue while his heart rejects it, and he has not left Islam. To refuse, as Bilaal refused, is the greater and the better course, even if it ends in death; but the concession is Allah’s gift, and no one may reproach the one who takes it. The verse places disbelief where it truly lives: in a chest that opens itself to it, not in a tongue that pain has forced.")),
            .shortOnly(.text("A believer forced by a real threat of death or torture may say a word of disbelief with his tongue while his heart rejects it, and he has not left Islam; the scholars agree on it. To refuse, as Bilaal refused, is the greater and the better course, but the concession is Allah’s gift, and no one may reproach the one who takes it.")),
        ]),
        ArticleSection("AMMAAR TO THE END", [
            .shortOnly(.text("Ammaar (may Allah be pleased with him) lived to become one of the great men of Islam. In 37 AH (657 CE), by then an old man, he fought on the side of Ali (may Allah be pleased with him) at Siffeen and was killed by the army of Syria. Umm Salamah (may Allah be pleased with her) had heard the Prophet foretell it:")),
            .longOnly(.text("Ammaar (may Allah be pleased with him) lived to become one of the great men of Islam. He emigrated to Madinah among the first, fought at Badr and in the battles after it, and when the Prophet’s mosque was being built he carried twice the load of the others:")),
            .longOnly(.hadith("bukhari:447", cite: "Saheeh al-Bukhaari 447", arabic: 45...82, english: [57...119])),
            .longOnly(.text("Abu ad-Dardaa’ (may Allah be pleased with him) called him the man whom Allah had protected from Satan by the tongue of His Prophet (Saheeh al-Bukhaari 3287), and the Prophet said that Ammaar was filled with faith (Sunan an-Nasaa’i 5007; graded saheeh by al-Albaani).")),
            .longOnly(.hadith("bukhari:3287", cite: "Saheeh al-Bukhaari 3287", arabic: 13...56, english: [0...54])),
            .longOnly(.hadith("nasai:5007", cite: "Sunan an-Nasaa’i 5007; graded saheeh by al-Albaani", arabic: 41...45, english: [10...20])),
            .longOnly(.text("In 37 AH (657 CE), by then an old man, he fought on the side of Ali (may Allah be pleased with him) at Siffeen and was killed by the army of Syria. Umm Salamah (may Allah be pleased with her) had heard the Prophet foretell it:")),
            .hadith("muslim:2916c", cite: "Saheeh Muslim 2916", arabic: 30...33, english: [0...6]),
            .shortOnly(.text("The hadith shows that Ali was in the right in that war. The scholars of the Sunnah add that Mu‘aawiyah (may Allah be pleased with him) and those with him erred in an ijtihaad for which they are not called sinners, and that a Muslim goes no further into the quarrels of the Companions than the texts take him.")),
            .longOnly(.text("Ahl as-Sunnah read this hadith as it stands and do not stretch it. It shows that Ali was in the right in that war, and that the party which fought him had transgressed against him. But the Prophet also described the two sides of that same conflict as two parties of his own nation:")),
            .longOnly(.hadith("muslim:1065c", cite: "Saheeh Muslim 1065", arabic: 31...42, english: [0...37])),
            .longOnly(.text("The Khawaarij broke away from Ali’s army and were fought by him, so Ali’s party was the one nearer to the truth, and the wording implies that the other was not far from it. The Quran calls two fighting parties believers in the same verse (49:9).")),
            .longOnly(.ayah("49:9", words: 0...4)),
            .longOnly(.text("So the scholars of the Sunnah, Ibn Taymiyyah and Ibn Katheer among them, held that Ali was right, that Mu‘aawiyah (may Allah be pleased with him) and those with him erred in an ijtihaad for which they are not called sinners, and that a Muslim goes no further into the quarrels of the Companions than the texts take him. Ammaar himself kept those manners. Sent by Ali to Koofah to rally people against the march of Aa’ishah (may Allah be pleased with her) to Basrah, he said from the pulpit:")),
            .longOnly(.hadith("bukhari:7100", cite: "Saheeh al-Bukhaari 7100", arabic: 64...90, english: [51...86])),
            .longOnly(.text("He opposed her in the field and defended her rank in public in the same breath. That is the balance Ahl as-Sunnah keep toward all of them.")),
            .door(.article("CompanionsIntroView")),
        ]),
        ArticleSection("KHABBAAB AND THE COMBS OF IRON", [
            .shortOnly(.text("Khabbaab ibn al-Aratt (may Allah be pleased with him) was a blacksmith in Makkah, a man without a tribe who had been brought there as a captive and sold. The persecution grew until the believers could bear no more, and Khabbaab came with others to the Prophet (peace be upon him) as he lay in the shade of the Ka‘bah:")),
            .longOnly(.text("Khabbaab ibn al-Aratt (may Allah be pleased with him) was a blacksmith in Makkah, a man without a tribe who had been brought there as a captive and sold. When he accepted Islam his customers found ways to hurt him. One of them, al-As ibn Waa’il, owed him for his work and refused to pay unless Khabbaab disbelieved in Muhammad. Khabbaab answered that he would not disbelieve until al-As died and was raised again, and al-As mocked him: when he was raised he would have wealth and children, and he would settle the debt then. Allah revealed about him (Saheeh al-Bukhaari 2091):")),
            .longOnly(.ayah("19:77-78")),
            .longOnly(.hadith("bukhari:2091", cite: "Saheeh al-Bukhaari 2091", arabic: 20...76, english: [0...119])),
            .longOnly(.text("The persecution grew until the believers could bear no more. Khabbaab came with others to the Prophet (peace be upon him) as he lay in the shade of the Ka‘bah:")),
            .hadith("bukhari:3612", cite: "Saheeh al-Bukhaari 3612", arabic: 15...99, english: [0...158]),
            .longOnly(.text("He did not promise that the pain would end soon, and he did not pray for them there and then. He gave them two things: the memory of believers before them who had suffered worse and held firm, like those Allah praises in Surat al-Burooj (85:4-8), and a promise so specific that it could be tested. Within Khabbaab’s own lifetime a rider could cross Yemen fearing no one but Allah. Khabbaab lived to see Islam carried from Yemen to Iraq, and he died in Koofah in 37 AH (657 CE). Wealth came to him at the end of his life, and it frightened him more than the iron had: those who died early, he said, left the world with their reward untouched, while he had more money than he knew what to do with, and had the Prophet not forbidden it he would have wished for death (Saheeh al-Bukhaari 5672).")),
            .longOnly(.ayah("85:4-8")),
            .longOnly(.hadith("bukhari:5672", cite: "Saheeh al-Bukhaari 5672", arabic: 24...53, english: [25...86])),
            .shortOnly(.text("He did not promise that the pain would end soon. He gave them the memory of believers before them who had suffered worse and held firm, and a promise so specific that it could be tested, and within Khabbaab’s own lifetime a rider could cross Yemen fearing no one but Allah. Khabbaab died in Koofah in 37 AH (657 CE).")),
        ]),
        ArticleSection("MUS‘AB IBN UMAYR, THE FIRST ENVOY", [
            .shortOnly(.text("Mus‘ab ibn Umayr (may Allah be pleased with him) came from the other end of Makkan society: a young man of Quraysh raised in comfort and remembered for his fine clothes and perfume. When twelve men of Madinah pledged themselves to the Prophet (peace be upon him) at al-Aqabah, he sent Mus‘ab home with them to teach, and through his teaching Islam entered most of the households of the Ansaar before the Prophet arrived. Mus‘ab carried the banner of the Muslims at Uhud in 3 AH (625 CE) and was killed there. Khabbaab described his burial:")),
            .longOnly(.text("Mus‘ab ibn Umayr (may Allah be pleased with him) came from the other end of Makkan society: a young man of the Quraysh clan of Abd ad-Daar, raised in comfort and remembered by the biographers for his fine clothes and perfume. He accepted Islam in secret, was confined by his family when they found out, and escaped to Abyssinia with the first emigrants. When twelve men of Madinah pledged themselves to the Prophet (peace be upon him) at al-Aqabah, he sent Mus‘ab home with them to teach. Al-Baraa’ ibn Aazib (may Allah be pleased with him), a boy in Madinah at the time, remembered:")),
            .longOnly(.hadith("bukhari:3925", cite: "Saheeh al-Bukhaari 3925", arabic: 22...34, english: [0...23])),
            .longOnly(.text("Through his teaching Islam entered most of the households of the Ansaar before the Prophet arrived, the chiefs Sa‘d ibn Mu‘aadh and Usayd ibn Hudayr among them, as Ibn Ishaaq relates. A year later he returned to Makkah with the seventy-three men and two women who gave the second pledge at al-Aqabah, and the way to the Hijrah was open. Mus‘ab carried the banner of the Muslims at Uhud in 3 AH (625 CE) and was killed there. Khabbaab described his burial:")),
            .hadith("bukhari:1276", cite: "Saheeh al-Bukhaari 1276", arabic: 20...87, english: [0...110]),
            .longOnly(.text("Khabbaab’s words divide the first Muslims into two groups: those who died before the world opened to them and took nothing of their reward in it, and those who lived to pick its fruit. Mus‘ab was of the first, and the men of the second envied him. Years later Abd ar-Rahman ibn Awf (may Allah be pleased with him), among the wealthiest of the Companions, was brought food while he was fasting. He remembered that Mus‘ab had been better than he and had been shrouded in a cloak too short for him, said he feared his own reward had been paid in this world, and wept until he left the food (Saheeh al-Bukhaari 1275).")),
            .longOnly(.hadith("bukhari:1275", cite: "Saheeh al-Bukhaari 1275", arabic: 26...88, english: [0...101])),
            .text("Allah describes men like Mus‘ab:"),
            .ayah("33:23"),
        ]),
        ArticleSection("ABU DHARR IN THE SANCTUARY", [
            .shortOnly(.text("Not every early believer was a Makkan. Abu Dharr (may Allah be pleased with him), of the tribe of Ghifaar on the trade road to Syria, came to Makkah to find the man who claimed to be a prophet, and lived in the Sanctuary for days on nothing but the water of Zamzam until Ali brought him to the Prophet (peace be upon him). The Prophet told him to go home and keep his Islam quiet, out of mercy for him, but Abu Dharr chose to proclaim the testimony aloud in the Sanctuary and paid for it with his blood, until al-Abbaas, the Prophet’s uncle, saved him with a merchant’s argument: Quraysh could not afford a feud with the tribe that sat on their caravan road. Abu Dharr went back to Ghifaar, and the tribe accepted Islam.")),
            .longOnly(.text("Not every early believer was a Makkan. Abu Dharr (may Allah be pleased with him) belonged to Ghifaar, a tribe that lived on the trade road from Makkah to Syria. Hearing that a man in Makkah claimed to be a prophet, he sent his brother to find out, was not satisfied with the report, and came himself. He would not ask anyone where the Prophet was, so he lived in the Sanctuary for days on nothing but the water of Zamzam, until Ali noticed the stranger, hosted him for three nights, and at last brought him to the Prophet (peace be upon him). Ibn Abbaas (may Allah be pleased with him) told what happened next:")),
            .longOnly(.hadith("bukhari:3861", cite: "Saheeh al-Bukhaari 3861", arabic: 253...320, english: [419...570])),
            .longOnly(.text("The Prophet had told him to go home and keep his Islam quiet, out of mercy for him, and Abu Dharr chose to pay for the testimony with his blood, twice. Al-Abbaas, the Prophet’s uncle, saved him with a merchant’s argument: Quraysh could not afford a feud with the tribe that sat on their caravan road. Abu Dharr went back to Ghifaar, and half of the tribe accepted Islam before the Hijrah and the other half after it, as he told in the longer account, where he also says that Zamzam had fed him for thirty days and nights (Saheeh Muslim 2473). The Prophet said that no one under the sky spoke more truthfully than Abu Dharr (Sunan Ibn Maajah 156; graded saheeh by al-Albaani).")),
            .longOnly(.hadith("muslim:2473", cite: "Saheeh Muslim 2473", arabic: 673...712, english: [1157...1224])),
            .longOnly(.hadith("ibnmajah:156", cite: "Sunan Ibn Maajah 156; graded saheeh by al-Albaani", arabic: 40...52, english: [7...23])),
        ]),
        ArticleSection("THE FIRST HIJRAH, TO ABYSSINIA", [
            .shortOnly(.text("When the persecution was at its worst, the Prophet (peace be upon him) allowed those who could to cross the Red Sea to Abyssinia, where a Christian king ruled who was known for wronging no one. In the fifth year of the prophethood a small group sailed, Uthmaan ibn Affaan and his wife Ruqayyah, the Prophet’s daughter, among them, and a larger group followed.")),
            .longOnly(.text("When the persecution was at its worst, the Prophet (peace be upon him) allowed those who could to cross the Red Sea to Abyssinia, where a Christian king ruled who was known for wronging no one. In the fifth year of the prophethood a small group sailed, Uthmaan ibn Affaan and his wife Ruqayyah, the Prophet’s daughter, among them, and a larger group followed. Uthmaan (may Allah be pleased with him) would be reminded years later that he had made both migrations, to Abyssinia and to Madinah (Saheeh al-Bukhaari 3872). Even Abu Bakr set out for Abyssinia, until a chief of the desert tribes turned him back and took him under his protection in Makkah (Saheeh al-Bukhaari 3905).")),
            .longOnly(.hadith("bukhari:3872", cite: "Saheeh al-Bukhaari 3872", arabic: 138...151, english: [189...223])),
            .longOnly(.hadith("bukhari:3905", cite: "Saheeh al-Bukhaari 3905", arabic: 54...128, english: [44...189])),
            .text("How Ja‘far ibn Abi Taalib answered for the emigrants before the king is told in his own chapter:"),
            .door(.article("CompanionUnclesView")),
            .longOnly(.text("Some of the emigrants stayed in Abyssinia for more than ten years and reached Madinah only in 7 AH (628 CE), after the conquest of Khaybar, together with believers from Yemen whose ship had carried them there. The Prophet told these “people of the ship” that they had the reward of two migrations (Saheeh al-Bukhaari 3876). The king who sheltered them, an-Najaashi, accepted Islam himself, and on the day he died the Prophet announced his death to the people and led them in the funeral prayer for him (Saheeh al-Bukhaari 1245).")),
            .longOnly(.hadith("bukhari:3876", cite: "Saheeh al-Bukhaari 3876", arabic: 23...70, english: [0...79])),
            .longOnly(.hadith("bukhari:1245", cite: "Saheeh al-Bukhaari 1245", arabic: 20...40, english: [0...40])),
            .text("Abyssinia was the first time Muslims left their homes for their religion, and it set the pattern for Madinah: a believer whose land will not let him worship Allah does not give up his faith to keep his land."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The forerunners of Islam were the people with the least to gain from it: slaves like Bilaal, outsiders like the family of Yaasir, a blacksmith like Khabbaab, a stranger from Ghifaar like Abu Dharr, and a rich young man like Mus‘ab who gave up everything he had. Sumayyah and Yaasir died for it before there was a Muslim army; Ammaar was forced into words his heart refused, and Allah excused him in His Book; Khabbaab was promised a victory he lived to see; Mus‘ab carried the Quran to Madinah and left the world in a borrowed shroud. Allah praised the first forerunners among the Muhaajiroon and the Ansaar (9:100) because they believed when belief brought nothing but loss, and every Muslim after them inherits what they paid for."),
            .ayah("9:100", words: 0...4),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("As-Saabiqoon al-Awwaloon", arabic: "السَّابِقُونَ الأَوَّلُونَ", meaning: "**The first forerunners**: the earliest believers, whom Allah names first among those He is pleased with (9:100). The scholars differ over where the line falls, at the two qiblahs, at Badr or at al-Hudaybiyah, but all agree that the believers of the Makkan years are at its head."),
            .term("Ikraah", arabic: "إِكرَاه", meaning: "**Coercion**: being forced by a real threat to one’s life or body. A word of disbelief said under ikraah, with the heart at rest in faith, does not take a person out of Islam (16:106), though holding firm is better."),
            .term("Mustad‘afoon", arabic: "المُستَضعَفُونَ", meaning: "**Those held weak**: believers kept down by others who have power over them. Allah reminds the early Muslims that they were once few and held weak in the land, fearing that people would snatch them away, and that He sheltered them (8:26)."),
            .ayah("8:26", words: 0...11),
            .term("Shaheed", arabic: "شَهِيد", meaning: "**A martyr**, from the root **ش-ه-د**, to witness: one killed for the sake of Allah. Those killed in His path are not dead but alive with their Lord, receiving provision (3:169)."),
        ]),
    ]
}

struct CompanionAbuHurayrahView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionAbuHurayrahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Abu Hurayrah and the Narrators")
        .englishArticle().selectableArticleList(article: "CompanionAbuHurayrahView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Abu Hurayrah came to Madinah from the tribe of Daws in 7 AH and had little more than three years with the Prophet, yet more hadith reach us through him than through any other Companion. He gave the reasons himself: he was poor, he stayed at the Prophet’s side while others worked, he feared concealing what Allah revealed, and the Prophet prayed that he would not forget. The Companions tested his reports and confirmed them, some eight hundred people of knowledge carried them, and the modern attacks on him, from orientalists and from the Raafidah, were answered from the same sources. Beside him stand six other Companions who narrated more than a thousand reports each, and together they show how the Sunnah was carried."),
        ]),
        ArticleSection("FROM DAWS TO KHAYBAR", [
            .shortOnly(.text("Abu Hurayrah (may Allah be pleased with him) came to Madinah in 7 AH (628 CE) with the men of Daws, a tribe of the highlands south of Taa’if, and followed the Prophet Muhammad (peace and blessings be upon him) to Khaybar, reaching him after the conquest. His nickname means “father of the kitten,” and it is the name the world remembers.")),
            .longOnly(.text("Daws was a tribe of the highlands south of Taa’if. One of its chiefs, at-Tufayl ibn Amr, accepted Islam in Makkah and went home to call his people, and they refused him. He came back to the Prophet Muhammad (peace and blessings be upon him) and asked him to curse them:")),
            .longOnly(.hadith("bukhari:2937", cite: "Saheeh al-Bukhaari 2937", arabic: 35...52, english: [0...62])),
            .longOnly(.text("The prayer was answered, and among the men of Daws who came to Madinah in 7 AH (628 CE) was a young man who had grazed his family’s sheep. Abu Hurayrah (may Allah be pleased with him) arrived to find that the Prophet had marched to Khaybar, followed him there, and reached him after the conquest (Saheeh al-Bukhaari 4238).")),
            .longOnly(.hadith("bukhari:4238", cite: "Saheeh al-Bukhaari 4238", arabic: 36...62, english: [15...62])),
            .longOnly(.text("The scholars differed over his own name more than over almost any other Companion’s; an-Nawawi and others preferred Abd ar-Rahman ibn Sakhr. His nickname, which means “father of the kitten,” is the name the world remembers, and he explained it himself:")),
            .longOnly(.hadith("tirmidhi:3840", cite: "Jaami‘ at-Tirmidhi 3840; its chain graded hasan by al-Albaani", arabic: 24...62, english: [5...76])),
            .longOnly(.text("The Prophet (peace be upon him) shortened it with affection and called him “Abu Hirr,” as the next narration shows.")),
        ]),
        ArticleSection("THE GUESTS OF ISLAM", [
            .markdown("At the back of the Prophet’s mosque was a covered platform, the **suffah (صُفَّة)**, where the poorest of the emigrants lived: men with no family in Madinah, no trade and no land. Abu Hurayrah was one of them, and he did not hide what that meant:"),
            .hadith("bukhari:6452", cite: "Saheeh al-Bukhaari 6452", arabic: 19...40, english: [0...40]),
            .longOnly(.text("In the rest of the narration he sits by the road the Companions used, asks Abu Bakr and then Umar about an ayah only so that they might take him home and feed him, and watches both walk on without understanding. Then the Prophet passes, smiles because he knows what is in his heart and on his face, and takes him home, where there is a single bowl of milk that someone has sent as a gift. The Prophet sends him to call all the people of the suffah, “the guests of Islam” who had no family and no wealth to turn to, and has him pour for each of them until all have drunk their fill. Only then does Abu Hurayrah drink, again and again at the Prophet’s urging, until he swears he can find no room for more, and the Prophet drinks what is left.")),
            .text("The story shows the school in which most of his hadith were learned. He was not a merchant, a farmer or a commander. He was a guest who lived at the door of the Prophet, followed him through the day, and had nothing else to do but listen."),
        ]),
        ArticleSection("WHY HE NARRATED SO MUCH", [
            .text("People noticed, even in his lifetime, that he narrated far more than men who had known the Prophet (peace be upon him) for twenty years, and he answered them:"),
            .hadith("bukhari:118", cite: "Saheeh al-Bukhaari 118", arabic: 18...81, english: [0...126]),
            .longOnly(.ayah("2:159", words: 0...7)),
            .longOnly(.text("His first reason is a fear, not a boast: Allah curses those who hide the guidance He sent down, and he held what he had heard as a trust he would answer for. His second is simple arithmetic of time. The Muhaajiroon were in the markets and the Ansaar in their orchards, while he was present at gatherings they missed. His third is a gift. He told the Prophet that he heard much and forgot it:")),
            .shortOnly(.text("His first reason is a fear, not a boast, and his second is time spent at the Prophet’s side while others worked. His third is a gift. He told the Prophet that he heard much and forgot it:")),
            .hadith("bukhari:119", cite: "Saheeh al-Bukhaari 119", arabic: 25...53, english: [0...66]),
            .longOnly(.text("The Prophet himself recognised how much he wanted this knowledge. When Abu Hurayrah asked who would be the happiest of people with his intercession, he said he had expected no one to ask him before Abu Hurayrah, because he knew his eagerness for hadith (Saheeh al-Bukhaari 99). And Abu Hurayrah was honest about his limits. He said that no Companion narrated more than he did except Abdullah ibn Amr, “for he used to write and I did not” (Saheeh al-Bukhaari 113), and Abdullah had written with the Prophet’s own permission (Sunan Abi Daawood 3646; graded saheeh by al-Albaani). Fewer of Abdullah’s reports reached later generations because, as Ibn Hajar explains, he lived mostly in Egypt and at Taa’if, away from the students who filled Madinah, and gave more of his time to worship than to teaching.")),
            .longOnly(.hadith("bukhari:99", cite: "Saheeh al-Bukhaari 99", arabic: 29...63, english: [6...50])),
            .longOnly(.hadith("bukhari:113", cite: "Saheeh al-Bukhaari 113", arabic: 23...48, english: [0...33])),
            .longOnly(.hadith("abudawud:3646", cite: "Sunan Abi Daawood 3646; graded saheeh by al-Albaani", arabic: 33...91, english: [0...88])),
        ]),
        ArticleSection("HIS MOTHER", only: .long, [
            .text("His mother was still a polytheist when he came to Madinah, and she would not hear of Islam. One day she said something about the Prophet (peace be upon him) that her son could not bear:"),
            .hadith("muslim:2491", cite: "Saheeh Muslim 2491", arabic: 23...241, english: [0...357]),
            .text("Two prayers were made in that narration and both were answered. His mother had accepted Islam by the time he reached her door, and the believers have loved Abu Hurayrah ever since, which is why an attack on him wounds Muslims as an attack on family does. A man who weeps because his mother insulted the Prophet, and weeps again from joy when she believes, is not the man his modern critics describe."),
        ]),
        ArticleSection("TESTED AND CONFIRMED", [
            .text("The Companions did not take his reports on trust because they liked him; they checked them, and the checking ended in his favour. When Abdullah ibn Umar (may Allah be pleased with him) heard that Abu Hurayrah narrated a great reward for following a funeral, he thought it too much and sent to Aa’ishah (may Allah be pleased with her) to ask:"),
            .hadith("bukhari:1323", cite: "Saheeh al-Bukhaari 1323, Saheeh Muslim 945", arabic: 23...61, english: [0...54]),
            .text("Ibn Umar, who had questioned him, later gave the verdict of a peer:"),
            .hadith("tirmidhi:3836", cite: "Jaami‘ at-Tirmidhi 3836; its chain graded saheeh by al-Albaani", arabic: 24...37, english: [7...33]),
            .longOnly(.text("Aa’ishah’s own criticism of him, recorded in both Saheehs, was about his manner, not his truth. He sat by her room narrating quickly while she was busy with her prayers, and she said that the Prophet did not reel off his words the way he did (Saheeh Muslim 2493), because the Prophet spoke so clearly that his words could be counted (Saheeh al-Bukhaari 3567). A teacher of hadith was being told to slow down; no one said he was inventing.")),
            .longOnly(.hadith("muslim:2493", cite: "Saheeh Muslim 2493", arabic: 21...61, english: [0...78])),
            .longOnly(.hadith("bukhari:3567", cite: "Saheeh al-Bukhaari 3567", arabic: 17...29, english: [0...22])),
            .longOnly(.text("Others tested his memory directly. Al-Haakim and adh-Dhahabi relate that Marwan ibn al-Hakam, as governor of Madinah, invited him to narrate while a scribe sat hidden behind a curtain writing down everything he said; a year later Marwan asked him about the same hadith, the scribe compared, and he had neither added nor dropped a letter. The Prophet himself had trusted him with the zakaah collected at the end of Ramadan (Saheeh al-Bukhaari 2311), and Umar (may Allah be pleased with him) appointed him governor of Bahrain. He died in Madinah in about 59 AH (679 CE), and al-Bukhaari said that some eight hundred people of knowledge, Companions and Successors among them, narrated from him.")),
            .shortOnly(.text("Aa’ishah’s own criticism of him was about his manner, not his truth: he narrated quickly by her room while she prayed, and she said that the Prophet did not reel off his words the way he did. A teacher of hadith was being told to slow down; no one said he was inventing.")),
            .shortOnly(.text("The Prophet himself had trusted him with the zakaah collected at the end of Ramadan:")),
            .hadith("bukhari:2311", cite: "Saheeh al-Bukhaari 2311", arabic: 21...30, english: [0...10]),
            .shortOnly(.text("Umar (may Allah be pleased with him) appointed him governor of Bahrain. He died in Madinah in about 59 AH (679 CE), and al-Bukhaari said that some eight hundred people of knowledge, Companions and Successors among them, narrated from him.")),
        ]),
        ArticleSection("THE SEVEN WHO NARRATED MOST", [
            .markdown("The hadith scholars call the Companions (may Allah be pleased with them) who narrated more than a thousand reports **al-mukthiroon (المُكثِرُونَ)**, “those who narrated much.” The figures usually given come from the great Musnad of Baqi ibn Makhlad of Cordoba, as Ibn al-Jawzi transmitted them:"),
            .stats([ArticleStat("5,374", "Abu Hurayrah"), ArticleStat("2,630", "Abdullah ibn Umar"), ArticleStat("2,286", "Anas ibn Maalik"), ArticleStat("2,210", "Aa’ishah, Mother of the Believers"), ArticleStat("1,660", "Abdullah ibn Abbaas"), ArticleStat("1,540", "Jaabir ibn Abdullah"), ArticleStat("1,170", "Abu Sa‘eed al-Khudri"), ArticleStat("800", "people of knowledge who narrated from Abu Hurayrah, by al-Bukhaari’s count")]),
            .shortOnly(.text("These numbers count chains, not separate sayings, so the distinct texts behind each figure are far fewer. What the list shows is who taught most: almost all of them were young when the Prophet died, lived long afterwards, and settled where students came to them.")),
            .longOnly(.text("These numbers count chains, not separate sayings. A single hadith that reached Baqi through ten students of Abu Hurayrah is counted ten times, so the distinct texts behind each figure are far fewer, and many of Abu Hurayrah’s texts are narrated by other Companions too. What the list shows is who taught most, and the answer has a pattern: almost all of them were young when the Prophet died, lived long afterwards, and settled where students came to them.")),
            .longOnly(.markdown("**Abdullah ibn Umar** followed the Prophet’s every step so closely that he would pray where he had prayed and halt where he had halted, and he lived in Madinah until 73 AH. **Anas ibn Maalik** was given to the Prophet as a servant as a boy by his mother, served him for ten years without once hearing a harsh word (Saheeh al-Bukhaari 6038), was blessed in wealth and children by his prayer (Saheeh al-Bukhaari 6334), and lived in Basrah until about 93 AH. **Aa’ishah** had the knowledge of the Prophet’s house, and the senior Companions brought their questions to her door. **Ibn Abbaas**, for whom the Prophet prayed that Allah teach him the Book (Saheeh al-Bukhaari 75), sought out the older Companions after the Prophet’s death and became the teacher of Makkah. **Jaabir ibn Abdullah** kept a teaching circle in the Prophet’s mosque and travelled a month’s journey to hear a single hadith from another Companion. **Abu Sa‘eed al-Khudri** was turned away from Uhud as too young to fight and lived to be one of the jurists of Madinah.")),
            .longOnly(.hadith("bukhari:6038", cite: "Saheeh al-Bukhaari 6038", arabic: 20...37, english: [0...37])),
            .longOnly(.hadith("bukhari:6334", cite: "Saheeh al-Bukhaari 6334", arabic: 12...32, english: [0...30])),
            .longOnly(.hadith("bukhari:75", cite: "Saheeh al-Bukhaari 75", arabic: 16...28, english: [0...18])),
            .door(.article("SahabahScholarsView")),
        ]),
        ArticleSection("ANSWERING THE ATTACKS", [
            .shortOnly(.text("In modern times Abu Hurayrah was attacked from two directions: by orientalists such as Ignaz Goldziher and the Egyptian writer Mahmood Abu Rayyah, who doubted the hadith as a whole, and by Shia writers, because he narrated a great part of the Sunnah, including many of the virtues of Abu Bakr, Umar and Uthmaan. The scholars answered at length, and their answers come down to a few plain points.")),
            .shortOnly(.text("Time spent at the Prophet’s side, not years since conversion, decides how much a man heard. He taught in Madinah for nearly half a century, long after Abu Bakr and Umar had died, to a generation that came looking for exactly what he carried. And his reports can be checked: the Saheefah that his student Hammaam ibn Munabbih wrote down from him in the first century survives in manuscript, and its hadith match the texts that Ahmad, al-Bukhaari and Muslim later recorded through Hammaam.")),
            .longOnly(.text("Abu Hurayrah was attacked in modern times from two directions. Orientalists such as Ignaz Goldziher, doubting the hadith as a whole, found it convenient to doubt its most prolific narrator, and in 1958 the Egyptian writer Mahmood Abu Rayyah made him the chief target of a book against the Sunnah, Adwaa’ ‘ala as-Sunnah al-Muhammadiyyah. Among the Shia, Abd al-Husayn Sharaf ad-Deen wrote a book with his name as its title, because the Raafidah reject most of the Companions and Abu Hurayrah narrated a great part of the Sunnah, including many of the virtues of Abu Bakr, Umar and Uthmaan.")),
            .longOnly(.text("The scholars answered at length: the Yemeni hadith master Abd ar-Rahman al-Mu‘allimi in al-Anwaar al-Kaashifah, Mustafa as-Sibaa‘i in as-Sunnah wa Makaanatuha fit-Tashree‘ al-Islaami, and Muhammad Ajjaaj al-Khateeb in a whole book on him. Their answers come down to a few plain points.")),
            .longOnly(.step("1. **He explained himself, and his reasons hold.** Time spent at the Prophet’s side, not years since conversion, decides how much a man heard, and Abu Hurayrah spent his days there while others worked.")),
            .longOnly(.step("2. **He lived and taught longest where it mattered.** Abu Bakr died two years after the Prophet and Umar ten years later, both while governing the state. Abu Hurayrah taught in Madinah for nearly half a century, to a generation that came looking for exactly what he carried.")),
            .longOnly(.step("3. **Some of what he narrated he heard from other Companions.** A Companion reporting from another Companion without naming him is accepted by the scholars, because every Companion is trustworthy; so his count is not a claim that he heard every word himself.")),
            .longOnly(.step("4. **His reports can be checked, and they check out.** The Saheefah that his student Hammaam ibn Munabbih wrote down from him in the first century survives in manuscript, and Muhammad Hameedullah published it in the 1950s. Its hadith match the same texts that Ahmad, al-Bukhaari and Muslim later recorded through Hammaam.")),
            .longOnly(.step("5. **The charges rest on what cannot bear them.** The worst of them depend on stories without chains, or on mockery of his hunger, which was the poverty of the people of the suffah, whom the Prophet himself fed and honoured.")),
            .text("Behind all of this is a principle Ahl as-Sunnah hold about every Companion: their uprightness is established by Allah’s praise of them, so a chain is examined up to the Companion and never at him. Al-Khateeb al-Baghdaadi gave a chapter of al-Kifaayah to this, and Ibn Hajar opens al-Isaabah by recording the agreement of Ahl as-Sunnah on it. An attack on Abu Hurayrah is in the end an attack on that principle, which is why the scholars of hadith defended him as they defended the Sunnah itself."),
            .door(.article("HadithRejectorsView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Why did Abu Bakr and Umar narrate so few hadith, if they were closer to the Prophet?**"),
            .text("Because narration follows teaching, and teaching follows time and place. The two caliphs died early, carried the burdens of state, and lived among Companions who already knew what they knew, so there were few who needed to ask them. Their knowledge reached the nation as much through their rulings and their sermons as through reports. Abu Hurayrah outlived most of the senior Companions and sat for decades in the city to which every student came."),
            .markdown("**Did Aa’ishah reject Abu Hurayrah’s hadith?**"),
            .text("No. She objected to his pace, as above, and in a few questions she held that he, like Umar, Ibn Umar and Ibn Abbaas, had missed part of a report or its meaning. The Shaafi‘i scholar az-Zarkashi gathered her corrections of the Companions in a book, al-Ijaabah, and Abu Hurayrah is one name among many in it. Scholars correcting one another’s understanding is how knowledge was refined among the Companions; it was never an accusation of lying, and she herself confirmed his hadith of the funeral when Ibn Umar doubted it."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Abu Hurayrah was a poor man of Daws who came to Madinah late, lived on the platform of the Prophet’s mosque, and spent his three years at the Prophet’s side listening. He narrated because Allah curses those who conceal His guidance, he remembered because the Prophet prayed over his cloak, and the Companions who tested him confirmed him. He taught in Madinah for half a century to hundreds of students, and he stands at the head of seven Companions, most of them young at the Prophet’s death, through whom much of the Sunnah was carried. The attacks on him were answered from the sources, and the principle behind his defence is the uprightness of every Companion."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Ahl as-Suffah", arabic: "أَهلُ الصُّفَّة", meaning: "**The people of the platform**: the poor emigrants who lived on the covered platform at the back of the Prophet’s mosque, with no family or wealth in Madinah. Abu Hurayrah called them “the guests of Islam” (Saheeh al-Bukhaari 6452)."),
            .term("Al-Mukthiroon", arabic: "المُكثِرُونَ", meaning: "**Those who narrated much**: the Companions from whom more than a thousand reports are recorded, Abu Hurayrah, Ibn Umar, Anas, Aa’ishah, Ibn Abbaas, Jaabir and Abu Sa‘eed al-Khudri."),
            .term("Adaalah", arabic: "عَدَالَة", meaning: "**Uprightness**: the quality of a narrator who is truthful and fears Allah. Ahl as-Sunnah hold that every Companion has it by Allah’s own praise of them, so none of them is questioned in his narration."),
            .term("Mursal as-Sahaabi", arabic: "مُرسَلُ الصَّحَابِيِّ", meaning: "A Companion’s report of what the Prophet said or did, heard from **another Companion** whom he does not name. The scholars accept it, since the unnamed link is himself a Companion."),
        ]),
    ]
}

struct CompanionWomenView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionWomenView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Women Companions")
        .englishArticle().selectableArticleList(article: "CompanionWomenView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the women among the Companions believed, emigrated, nursed the wounded, taught, questioned and gave counsel, and a share of the Sunnah reaches us through them. Sumayyah was the first martyr of Islam; Umm Salamah’s advice ended a crisis at al-Hudaybiyah; Asmaa’ bint Abi Bakr carried food to the Hijrah and, in old age, faced down al-Hajjaaj; Umm Sulaym asked for Islam as her dowry; Umm Haraam was promised a place among the first to sail in Allah’s cause and died on that voyage; ash-Shifaa’ taught writing; Umm Atiyyah nursed the wounded and taught the washing of the dead. They gave their pledge on the terms Allah revealed in Surat al-Mumtahanah, and the critics of hadith found no woman among the narrators who was accused of lying."),
        ]),
        ArticleSection("THE FIRST AMONG THEM", [
            .text("The first person on earth to believe in the Prophet Muhammad (peace and blessings be upon him) was a woman, his wife Khadeejah (may Allah be pleased with her), and the first believer to be killed for Islam was a woman too, Sumayyah, the mother of Ammaar, whom Abu Jahl killed in Makkah. Both have their stories elsewhere in this library:"),
            .door(.article("CompanionKhadijahAishahView")),
            .door(.article("CompanionFirstBelieversView")),
            .longOnly(.text("Among the earliest believers was also Umm Ayman, Barakah (may Allah be pleased with her), the Abyssinian woman who had cared for the Prophet as a child after his mother died. She believed, emigrated to Madinah, and was visited by him there as one visits family. After his death Abu Bakr and Umar (may Allah be pleased with them) kept up his habit:")),
            .longOnly(.hadith("muslim:2454", cite: "Saheeh Muslim 2454", arabic: 33...98, english: [0...108])),
            .longOnly(.text("She did not weep for herself or even for him, since she knew that what was with Allah was better for His Messenger. She wept because the heavens had gone quiet. The first generation of women understood what the revelation was, and grieved for it the way scholars grieve.")),
        ]),
        ArticleSection("WOMEN WHO EMIGRATED", [
            .shortOnly(.text("Women made both migrations, often at greater risk than men. After the treaty of al-Hudaybiyah, Quraysh could demand back any man who fled from Makkah to Madinah, and the Prophet (peace be upon him) kept that term. Then Umm Kulthoom bint Uqbah, the daughter of one of his bitterest enemies, came alone, a young woman, and her family came after her to take her back. Allah revealed that believing women were not to be returned:")),
            .longOnly(.text("Women made both migrations, often at greater risk than men. Asmaa’ bint Umays (may Allah be pleased with her) crossed to Abyssinia with her husband Ja‘far ibn Abi Taalib and spent more than ten years there. When she reached Madinah at last, in 7 AH, Umar told her that the Muslims who had emigrated to Madinah had the greater right to the Prophet. She answered that while they were with the Prophet in Madinah, she and her companions had been strangers in a far land, harmed and afraid, for the sake of Allah and His Messenger, and that she would take the matter to the Prophet himself:")),
            .longOnly(.hadith("bukhari:4231", cite: "Saheeh al-Bukhaari 4231", arabic: 0...74, text: "So when the Prophet (ﷺ) came, she said, “O Allah’s Prophet! Umar has said so-and-so.” He said, “What did you say to him?” She said, “I told him so-and-so.” The Prophet (ﷺ) said, “He has not got more right than you people over me, as he and his companions have only one migration, and you, the people of the boat, have two migrations.” Asmaa’ later said, “I saw Abu Moosa and the other people of the boat coming to me in successive groups, asking me about this narration, and to them nothing in the world was more cheerful and greater than what the Prophet (ﷺ) had said about them.”")),
            .longOnly(.text("After the treaty of al-Hudaybiyah, Quraysh could demand back any man who fled from Makkah to Madinah, and the Prophet (peace be upon him) kept that term. Then Umm Kulthoom bint Uqbah, the daughter of one of his bitterest enemies, came alone, a young woman, and her family came after her to take her back. Allah revealed that believing women were not to be returned (Saheeh al-Bukhaari 2711):")),
            .ayah("60:10", words: 0...17),
            .longOnly(.hadith("bukhari:2711", cite: "Saheeh al-Bukhaari 2711", arabic: 110...155, english: [113...194])),
            .text("The verse makes the women emigrants answerable for their own faith. They were to be examined, their belief was theirs, and once it was known, no treaty between men could send them back."),
        ]),
        ArticleSection("UMM SALAMAH'S COUNSEL", [
            .shortOnly(.text("Umm Salamah, Hind bint Abi Umayyah (may Allah be pleased with her), emigrated with her first husband, Abu Salamah, to Abyssinia and then to Madinah, and after his death the Prophet married her.")),
            .longOnly(.text("Umm Salamah, Hind bint Abi Umayyah (may Allah be pleased with her), emigrated with her first husband, Abu Salamah, to Abyssinia and then to Madinah. When he died of a wound from Uhud, she said the words the Prophet had taught for every calamity, asking Allah to reward her and replace what she had lost with something better, and wondered who could be better than Abu Salamah, “whose family was the first to emigrate to the Messenger of Allah.” Allah replaced him with the Messenger himself, who married her (Saheeh Muslim 918).")),
            .longOnly(.hadith("muslim:918a", cite: "Saheeh Muslim 918", arabic: 78...111, english: [51...90])),
            .text("Her best-known moment came at al-Hudaybiyah in 6 AH (628 CE). The Muslims had come to perform the ‘umrah, were turned back, and had to accept a treaty whose terms seemed to them a humiliation. When the Prophet told them to slaughter their sacrifices and shave their heads, no one moved, though he said it three times. He went in to Umm Salamah and told her what the people had done:"),
            .hadith("bukhari:2731", cite: "Saheeh al-Bukhaari 2731", arabic: 1371...1416, english: [2234...2337]),
            .longOnly(.text("The commentators explain that the Companions were not refusing him but hoping, against hope, that the command might still change, and that only his action would end the hope. The Prophet took her counsel without a word of hesitation, and it worked at once. The scholars cite this to show that a sound opinion is taken from whoever gives it, man or woman, and that consultation was the Prophet’s practice in his own home. Umm Salamah outlived the other Mothers of the Believers, and she narrated a large body of hadith.")),
            .shortOnly(.text("The Prophet took her counsel without a word of hesitation, and it worked at once. The scholars cite this to show that a sound opinion is taken from whoever gives it, man or woman.")),
        ]),
        ArticleSection("ASMAA’ BINT ABI BAKR", [
            .text("Asmaa’ (may Allah be pleased with her), the elder daughter of Abu Bakr and sister of Aa’ishah, helped prepare the Hijrah itself:"),
            .hadith("bukhari:2979", cite: "Saheeh al-Bukhaari 2979", arabic: 24...74, english: [0...92]),
            .longOnly(.text("She married az-Zubayr ibn al-Awwaam when he owned nothing but a water camel and a horse, and she fed the horse, drew the water, kneaded the dough and carried date stones on her head from his land two miles away, until Abu Bakr sent her a servant to look after the horse (Saheeh al-Bukhaari 5224). When her mother came to visit her in Madinah while still a polytheist, she asked the Prophet whether she should keep the tie, and he told her to keep good relations with her mother (Saheeh al-Bukhaari 2620).")),
            .longOnly(.hadith("bukhari:5224", cite: "Saheeh al-Bukhaari 5224", arabic: 21...173, english: [0...105, 291...312])),
            .longOnly(.hadith("bukhari:2620", cite: "Saheeh al-Bukhaari 2620", arabic: 22...55, english: [0...56])),
            .longOnly(.text("She lived to nearly a hundred, and her courage at the end of her life is the best known part of her story. In 73 AH (692 CE) al-Hajjaaj ibn Yoosuf, the governor sent by the Umayyads, besieged Makkah, killed her son Abdullah ibn az-Zubayr and hung his body on a stake. He summoned Asmaa’; she refused to come, and he had to go to her. He asked her what she thought of what he had done to “the enemy of Allah”:")),
            .longOnly(.hadith("muslim:2545", cite: "Saheeh Muslim 2545", arabic: 175...252, english: [333...485])),
            .longOnly(.text("An old woman who had lost her son told the most feared man in the empire, to his face, that the Prophet had foretold a destroyer from Thaqeef and that she took him to be the one. He stood up and left without a word. The liar, the commentators explain, was al-Mukhtaar ibn Abi Ubayd of Thaqeef, who had claimed that revelation came to him.")),
            .shortOnly(.text("She lived to nearly a hundred. In 73 AH (692 CE), when al-Hajjaaj ibn Yoosuf besieged Makkah, killed her son Abdullah ibn az-Zubayr and hung his body on a stake, the old woman refused to come when he summoned her, and when he came to her she told the most feared man in the empire the truth to his face.")),
        ]),
        ArticleSection("UMM SULAYM", [
            .text("Umm Sulaym bint Milhaan (may Allah be pleased with her), of the Ansaar, accepted Islam early in Madinah, and when her husband died she was courted by Abu Talhah, one of the wealthiest men of the city, who was still an idolater:"),
            .hadith("nasai:3341", cite: "Sunan an-Nasaa’i 3341; graded saheeh by al-Albaani", arabic: 22...70, english: [10...108]),
            .longOnly(.text("She also gave the Prophet (peace be upon him) her young son Anas as his servant, and asked him to pray for the boy (Saheeh al-Bukhaari 6334). Her patience became proverbial. When a son of hers and Abu Talhah’s died while his father was away, she washed and shrouded the child, received her husband calmly, gave him his meal and his night, and only in the morning told him that their son had gone. The Prophet prayed for blessing in that night, and one of the Ansaar later counted nine sons of the child born from it, all of whom knew the Quran by heart (Saheeh al-Bukhaari 1301). At Hunayn she carried a dagger at her belt, and told the smiling Prophet that it was for the belly of any polytheist who came near her (Saheeh Muslim 1809).")),
            .longOnly(.hadith("bukhari:6334", cite: "Saheeh al-Bukhaari 6334", arabic: 12...32, english: [0...30])),
            .longOnly(.hadith("bukhari:1301", cite: "Saheeh al-Bukhaari 1301", arabic: 110...131, english: [126...169])),
            .longOnly(.hadith("muslim:1809a", cite: "Saheeh Muslim 1809", arabic: 18...72, english: [0...57])),
            .shortOnly(.text("She gave the Prophet (peace be upon him) her young son Anas as his servant, and her patience became proverbial.")),
        ]),
        ArticleSection("UMM HARAAM AND THE SEA", [
            .shortOnly(.text("Umm Haraam bint Milhaan (may Allah be pleased with her), the sister of Umm Sulaym, heard the Prophet (peace be upon him) promise Paradise to the first army of his nation to campaign by sea, at a time when there was no Muslim navy and no Muslim had ever fought at sea:")),
            .longOnly(.text("Umm Haraam bint Milhaan (may Allah be pleased with her), the sister of Umm Sulaym, was the wife of Ubaadah ibn as-Saamit. The Prophet (peace be upon him) used to visit her at Qubaa’, and the scholars explain that she was one of the women who were his mahram, unmarriageable to him through kinship or nursing, which is why he would rest in her house. One day he slept there and woke smiling:")),
            .longOnly(.hadith("bukhari:2788", cite: "Saheeh al-Bukhaari 2788", arabic: 80...182, english: [68...237])),
            .longOnly(.text("When he told her this, there was no Muslim navy and no Muslim had ever fought at sea. Years later, in the caliphate of Uthmaan, Mu‘aawiyah ibn Abi Sufyaan (may Allah be pleased with him), then governor of Syria, led the first Muslim fleet against Cyprus in 28 AH (649 CE), and Umm Haraam sailed with it in her old age beside her husband. She fell from her mount after landing and died there, as he had said. In another narration from her the Prophet said that the first army of his nation to campaign by sea had earned Paradise, and she asked and was told that she was among them (Saheeh al-Bukhaari 2924). The scholars note that this is a virtue of that army and of the Companion who led it.")),
            .hadith("bukhari:2924", cite: "Saheeh al-Bukhaari 2924", arabic: 55...76, english: [44...79]),
            .shortOnly(.text("Years later, in the caliphate of Uthmaan, Mu‘aawiyah ibn Abi Sufyaan (may Allah be pleased with him) led the first Muslim fleet against Cyprus in 28 AH (649 CE), and Umm Haraam sailed with it in her old age beside her husband. She fell from her mount after landing and died there.")),
        ]),
        ArticleSection("NURSES, TEACHERS AND QUESTIONERS", [
            .text("Women went with the army to cook, carry water and treat the wounded. Ar-Rubayyi‘ bint Mu‘awwidh said that they gave the fighters water, treated them and carried the dead back to Madinah (Saheeh al-Bukhaari 2882)."),
            .hadith("bukhari:2882", cite: "Saheeh al-Bukhaari 2882", arabic: 18...31, english: [0...26]),
            .text("Umm Atiyyah al-Ansaariyyah (may Allah be pleased with her) described her service:"),
            .hadith("muslim:1812g", cite: "Saheeh Muslim 1812", arabic: 22...42, english: [0...30]),
            .longOnly(.text("Umm Atiyyah was also one of the women who washed the body of the Prophet’s daughter at his instruction, and her narration of how he told them to do it, three times, five times or more, with water and lote leaves and a little camphor at the end, became the foundation of the Muslims’ practice in washing their dead (Saheeh al-Bukhaari 1253).")),
            .longOnly(.hadith("bukhari:1253", cite: "Saheeh al-Bukhaari 1253", arabic: 25...61, english: [0...44])),
            .text("Some taught. Ash-Shifaa’ bint Abdullah (may Allah be pleased with her) was one of the few people in Makkah who could write, and she taught it to Hafsah, the Prophet’s wife:"),
            .hadith("abudawud:3887", cite: "Sunan Abi Daawood 3887; graded saheeh by al-Albaani", arabic: 50...57, english: [16...32]),
            .longOnly(.text("And many asked. The women told the Prophet that the men took all his time and asked for a day of their own, and he gave them one (Saheeh al-Bukhaari 101).")),
            .longOnly(.hadith("bukhari:101", cite: "Saheeh al-Bukhaari 101", arabic: 19...39, english: [0...31])),
            .text("Aa’ishah said that the women of the Ansaar were excellent because shyness did not stop them from learning their religion (Saheeh Muslim 332)."),
            .hadith("muslim:332c", cite: "Saheeh Muslim 332", arabic: 124...135, english: [175...192]),
            .longOnly(.text("Umm Umaarah al-Ansaariyyah complained that the Quran seemed to speak only of men, and Allah revealed the verse that names both together, quality by quality (Jaami‘ at-Tirmidhi 3211; graded hasan by Darussalam):")),
            .longOnly(.ayah("33:35")),
            .longOnly(.hadith("tirmidhi:3211", cite: "Jaami‘ at-Tirmidhi 3211; graded hasan by Darussalam", arabic: 20...47, english: [0...50])),
            .longOnly(.text("Khawlah bint Tha‘labah, as she is usually named, brought a complaint against her husband, and the answer came down in the opening of Surat al-Mujaadilah. Aa’ishah, sitting in a corner of the same room, could not hear what Khawlah said, and praised Allah whose hearing takes in every voice (Sunan Ibn Maajah 188; graded saheeh by al-Albaani):")),
            .longOnly(.ayah("58:1")),
            .longOnly(.hadith("ibnmajah:188", cite: "Sunan Ibn Maajah 188; graded saheeh by al-Albaani", arabic: 20...56, english: [0...62])),
        ]),
        ArticleSection("THE PLEDGE OF THE WOMEN", [
            .text("The women gave the Prophet (peace be upon him) their own pledge of allegiance, on terms that Allah set out word by word:"),
            .ayah("60:12"),
            .longOnly(.text("Aa’ishah (may Allah be pleased with her) described how the pledge was taken:")),
            .longOnly(.hadith("bukhari:4891", cite: "Saheeh al-Bukhaari 4891", arabic: 62...99, english: [50...115])),
            .longOnly(.text("Each woman pledged for herself, as a person addressed by Allah directly, and the pledge was taken in words. Umm Atiyyah added that among its terms was a promise not to wail over the dead, the loud lamenting of the days of ignorance, and that only five of the women with her kept that promise fully, Umm Sulaym among them (Saheeh al-Bukhaari 4892, 1306).")),
            .longOnly(.hadith("bukhari:4892", cite: "Saheeh al-Bukhaari 4892", arabic: 21...37, english: [0...30])),
            .longOnly(.hadith("bukhari:1306", cite: "Saheeh al-Bukhaari 1306", arabic: 23...59, english: [0...65])),
            .shortOnly(.text("Each woman pledged for herself, as a person addressed by Allah directly, and the pledge was taken in words.")),
        ]),
        ArticleSection("IN THE CHAINS OF THE SUNNAH", [
            .shortOnly(.text("The women Companions were narrators, not only subjects of narration. Aa’ishah alone stands among the seven Companions who narrated most, and Umm Salamah narrated a large body of hadith.")),
            .longOnly(.text("The women Companions were narrators, not only subjects of narration. Aa’ishah alone stands among the seven Companions who narrated most, Umm Salamah narrated a large body of hadith, and Hafsah kept the written sheets of the Quran gathered under Abu Bakr until Uthmaan sent for them to make the official copies (Saheeh al-Bukhaari 4986). After them came women of the Successors who learned from them, such as Amrah bint Abd ar-Rahman, who grew up in Aa’ishah’s house and became the reference of Madinah for her hadith.")),
            .longOnly(.hadith("bukhari:4986", cite: "Saheeh al-Bukhaari 4986", arabic: 218...234, english: [390...421])),
            .text("The biographers gave them their own place. Ibn Sa‘d devoted the last volume of at-Tabaqaat al-Kubra to the women, and Ibn Hajar closed al-Isaabah with a long book of women Companions. The hadith critics, who spared no one, judged them too. Adh-Dhahabi, after compiling his great register of narrators who had been criticised, wrote in Meezaan al-I‘tidaal that he knew of no woman who had been accused of lying in hadith or whose narration had been abandoned."),
            .callout("The women Companions show that the place Islam gave women was not in theory alone. Allah addressed them in His Book by name and quality, took their pledge separately, answered their complaints from above the heavens, and preserved part of the religion through their memory.", title: "The Lesson", icon: "lightbulb.fill"),
            .door(.article("WivesView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("From Khadeejah, the first to believe, and Sumayyah, the first to die for it, the women Companions were present at every stage of the message. They emigrated across the sea and across the desert, and Allah forbade that a believing woman be handed back to the disbelievers. Umm Salamah’s counsel ended the crisis at al-Hudaybiyah; Asmaa’ carried food to the cave and later told al-Hajjaaj the truth to his face; Umm Sulaym made Islam her dowry and patience her habit; Umm Haraam sailed with the first fleet as she had been promised; Umm Atiyyah and ar-Rubayyi‘ nursed the wounded; ash-Shifaa’ taught writing; and the women of the Ansaar asked about their religion without shyness. They pledged to the Prophet on terms revealed for them, and through Aa’ishah, Umm Salamah and many others a share of the Sunnah came down to us in their words."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Sahaabiyyah", arabic: "صَحَابِيَّة", meaning: "**A woman Companion**: a woman who met the Prophet believing in him and died upon Islam. The plural is **sahaabiyyaat (صَحَابِيَّات)**."),
            .term("Bay‘at an-Nisaa’", arabic: "بَيعَةُ النِّسَاءِ", meaning: "**The pledge of the women**: the oath of allegiance the believing women gave the Prophet on the terms of 60:12, taken by word, not by hand."),
            .term("Mahram", arabic: "مَحرَم", meaning: "A relative whom a person may **never marry**, by blood, by marriage or by nursing, and before whom the rules of covering and of being alone together are relaxed."),
            .term("Niyaahah", arabic: "نِيَاحَة", meaning: "**Wailing**: loud lamentation over the dead with screaming, tearing clothes or striking the face, a custom of the days of ignorance that the women pledged to give up. Tears and quiet grief are not niyaahah."),
        ]),
    ]
}

struct CompanionTabiunView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionTabiunView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Taabi‘oon")
        .englishArticle().selectableArticleList(article: "CompanionTabiunView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Taabi‘oon, the Successors, are the Muslims who met a Companion as believers and died upon Islam. They are the second of the three generations the Prophet called the best, and those who followed them with excellence in 9:100. They sat with the Companions in every city, asked them, were corrected by them, and handed the religion on with the names of those they took it from. The Prophet named one of them, Uways al-Qarani, the best of them; Sa‘eed ibn al-Musayyib led the jurists of Madinah, al-Hasan al-Basri preached in Basrah, Ibn Seereen guarded the isnaad, Mujaahid carried the tafseer of Ibn Abbaas, Sa‘eed ibn Jubayr was killed by al-Hajjaaj, and Umar ibn Abd al-Azeez renewed justice and ordered the hadith written down. Their students, among them Sufyaan ath-Thawri, al-Awzaa‘i, al-Layth and Ibn al-Mubaarak, completed the three generations of the Salaf."),
        ]),
        ArticleSection("THOSE WHO FOLLOWED WITH EXCELLENCE", [
            .text("When Allah declared His pleasure with the first believers, He did not close the door behind them:"),
            .ayah("9:100", words: 5...7),
            .longOnly(.markdown("A **Taabi‘i (تَابِعِيّ)** is one who met a Companion while believing and died a Muslim; Ibn Hajar gives this definition in Nukhbat al-Fikar, and al-Khateeb al-Baghdaadi added that he should have kept the Companion’s company. The Prophet Muhammad (peace and blessings be upon him) placed them second among the best of his nation:")),
            .shortOnly(.markdown("A **Taabi‘i (تَابِعِيّ)** is one who met a Companion while believing and died a Muslim, and the Prophet Muhammad (peace and blessings be upon him) placed them second among the best of his nation:")),
            .hadith("bukhari:3650", cite: "Saheeh al-Bukhaari 3650", arabic: 31...67, english: [0...83]),
            .longOnly(.text("Some of them had lived as adults in the Prophet’s lifetime and accepted Islam without ever seeing him; the scholars call such people mukhadramoon and count them among the most senior of the Taabi‘oon. At the other end, their generation ran deep into the second century. The last Companion to die, Abu at-Tufayl Aamir ibn Waathilah, passed away in about 100 AH, as Muslim notes after his narration (Saheeh Muslim 2340), and those who had met him or others like him were still teaching decades later.")),
            .longOnly(.hadith("muslim:2340a", cite: "Saheeh Muslim 2340", arabic: 31...51, english: [20...39])),
            .longOnly(.text("The Quran also gives them their manners toward those before them. Allah describes the believers who came after the Muhaajiroon and the Ansaar:")),
            .longOnly(.ayah("59:10")),
        ]),
        ArticleSection("UWAYS AL-QARANI, THE BEST OF THEM", [
            .text("The Prophet (peace be upon him) told Umar about a man of Yemen whom he would never meet, and named him as the best of the generation to come:"),
            .hadith("muslim:2542b", cite: "Saheeh Muslim 2542", arabic: 40...54, english: [7...45]),
            .longOnly(.text("Umar (may Allah be pleased with him) asked every reinforcement that came up from Yemen whether Uways ibn Aamir of Qaran was among them, until he found him and confirmed every sign: the cured leprosy with one spot left the size of a coin, the mother he served. He asked Uways to pray for his forgiveness, and Uways did. When Umar offered to write to the governor of Koofah for him, Uways said he preferred to live among the poor and unknown. A year later a noble of Koofah told Umar he had left Uways in poverty; Umar told him the hadith, the man went to ask for Uways’s prayer, people came to know who he was, and Uways left the town (Saheeh Muslim 2542).")),
            .shortOnly(.text("Umar (may Allah be pleased with him) asked every reinforcement that came up from Yemen whether Uways was among them, until he found him, confirmed every sign, and asked him to pray for his forgiveness. Uways preferred to live among the poor and unknown, and when people came to know who he was, he left the town.")),
            .shortOnly(.text("The best of the Successors, by the Prophet’s own word, was not a judge, a narrator or a commander. He was a man known to Allah for his kindness to his mother and his flight from fame.")),
            .longOnly(.text("The best of the Successors, by the Prophet’s own word, was not a judge, a narrator or a commander. He was a man known to Allah for his kindness to his mother and his flight from fame. Imam Ahmad and others said that the best of the Taabi‘oon was Sa‘eed ibn al-Musayyib, and an-Nawawi reconciles the two: Sa‘eed was the best of them in knowledge of the Sharee‘ah, while Uways was the best of them in standing with Allah, as the hadith says.")),
            .longOnly(.callout("Many stories are told about Uways beyond what Muslim records, among them that he broke out his own teeth on hearing that the Prophet’s tooth was broken at Uhud. They have no sound basis and are not told here. What the hadith says of him is enough.", title: "A Note on Uways", icon: "exclamationmark.triangle.fill")),
        ]),
        ArticleSection("THE SCHOOLS OF THE CITIES", [
            .text("The Companions spread with the conquests, and wherever they settled the young gathered around them. In Madinah the students of Zayd ibn Thaabit, Ibn Umar, Aa’ishah and Abu Hurayrah became the seven jurists of the city, Sa‘eed ibn al-Musayyib and Urwah ibn az-Zubayr among them. In Makkah the students of Ibn Abbaas, Mujaahid, Ataa’ and Ikrimah, carried his tafseer. In Koofah the students of Ibn Mas‘ood and Ali, Alqamah, al-Aswad and Masrooq, laid the ground for the fiqh of Iraq. Basrah had al-Hasan and Ibn Seereen, Syria had Abu Idrees al-Khawlaani, and Yemen had Taawoos."),
            .longOnly(.text("They learned by asking and by being corrected. Urwah ibn az-Zubayr asked his aunt Aa’ishah (may Allah be pleased with her) about a verse that seemed to him to make the walk between Safa and Marwah optional:")),
            .longOnly(.hadith("bukhari:1643", cite: "Saheeh al-Bukhaari 1643", arabic: 9...150, english: [0...230])),
            .longOnly(.text("The young man read the words alone; the Companion read them with the occasion on which they came down and with the Sunnah that explained them. That is the method the Taabi‘oon inherited: the Quran as the Companions understood it, with the Prophet’s practice beside it. And they inherited the Companions’ fear for their own souls along with their knowledge. Abdullah ibn Abi Mulaykah, a Taabi‘i of Makkah, said:")),
            .longOnly(.quote(text: "“I met thirty of the Companions of the Prophet (peace be upon him), and every one of them feared hypocrisy for himself; not one of them said that his faith was like the faith of Jibreel and Meekaa’eel” (al-Bukhaari, in his Saheeh, Book of Faith, the chapter on the believer’s fear that his deeds may come to nothing).", arabic: "أَدرَكتُ ثَلَاثِينَ مِن أَصحَابِ النَّبِيِّ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ كُلُّهُم يَخَافُ النِّفَاقَ عَلَى نَفسِهِ، مَا مِنهُم أَحَدٌ يَقُولُ إِنَّهُ عَلَى إِيمَانِ جِبرِيلَ وَمِيكَائِيلَ", dimmed: true)),
            .shortOnly(.text("The young learned by asking and by being corrected, and the method they inherited was the Quran as the Companions understood it, with the Prophet’s practice beside it. They inherited the Companions’ fear for their own souls along with their knowledge.")),
        ]),
        ArticleSection("SA‘EED IBN AL-MUSAYYIB", [
            .longOnly(.text("Sa‘eed ibn al-Musayyib (may Allah have mercy on him) was born in Madinah in 15 AH (636 CE), in the caliphate of Umar, of the clan of Makhzoom of Quraysh, and he died there in 94 AH (713 CE). He married the daughter of Abu Hurayrah and learned his hadith at home, and he was known above all others for his knowledge of the judgements of Umar. Ali ibn al-Madeeni, one of the great critics of narrators, said he knew of no one among the Taabi‘oon wider in knowledge.")),
            .longOnly(.text("He lived by trade rather than by the gifts of rulers, and he did not bend to them. When the caliph Abd al-Malik demanded that Madinah pledge allegiance to his two sons as heirs while he himself still lived, Sa‘eed refused, holding that two pledges could not be taken at once, and the governor of Madinah had him flogged and paraded through the city. The historians relate it, Ibn Sa‘d among them. He did not call anyone to revolt; he simply would not say what he did not believe. That combination, firmness in the truth without drawing the sword, is the pattern the scholars of the Sunnah kept with unjust rulers ever after.")),
            .shortOnly(.text("Sa‘eed ibn al-Musayyib (may Allah have mercy on him) married the daughter of Abu Hurayrah and was known above all others for his knowledge of the judgements of Umar; he died in Madinah in 94 AH (713 CE). When the caliph Abd al-Malik demanded a pledge to his two sons as heirs while he himself still lived, Sa‘eed refused and was flogged for it. He did not call anyone to revolt; he simply would not say what he did not believe, and that firmness in the truth without drawing the sword is the pattern the scholars of the Sunnah kept with unjust rulers ever after.")),
        ]),
        ArticleSection("AL-HASAN AL-BASRI AND IBN SEEREEN", [
            .longOnly(.text("Al-Hasan ibn Abi al-Hasan (may Allah have mercy on him) was born in Madinah in 21 AH (642 CE). His mother Khayrah was a freedwoman of Umm Salamah, the Mother of the Believers, and he grew up in and around her house before settling in Basrah, where for decades he was its preacher and its conscience. His sermons on sincerity, death and the Hereafter were repeated across the Muslim world, and al-Bukhaari records his words on hypocrisy:")),
            .longOnly(.quote(text: "“None fears it but a believer, and none feels safe from it but a hypocrite” (al-Hasan al-Basri, on hypocrisy; reported by al-Bukhaari in his Saheeh, Book of Faith, in the same chapter).", arabic: "مَا خَافَهُ إِلَّا مُؤمِنٌ، وَلَا أَمِنَهُ إِلَّا مُنَافِقٌ", dimmed: true)),
            .longOnly(.text("Two episodes show where he stood. When Waasil ibn Ata withdrew from his circle to teach that the Muslim who commits a major sin is neither a believer nor a disbeliever, the Mu‘tazilah were born, and al-Hasan stayed with the Sunnah. And when the reciters of Iraq rose with Ibn al-Ash‘ath against al-Hajjaaj, al-Hasan refused to join them; Ibn Sa‘d relates that he told them al-Hajjaaj was a punishment from Allah, to be met with repentance and humble prayer rather than with swords. He died in Basrah in 110 AH (728 CE).")),
            .longOnly(.text("Muhammad ibn Seereen (may Allah have mercy on him), whose father had been a captive freed by Anas ibn Maalik, died in the same city a few months after him. He was a cloth merchant of scrupulous honesty and a narrator who would repeat a hadith only in its exact words. His two sayings on the isnaad, that this knowledge is religion so look from whom you take your religion, and that the people began to ask for chains when the strife began, are recorded in Imam Muslim’s introduction to his Saheeh, and they are the seed of the whole science of judging narrators. He was famous for interpreting dreams, but the large dream book that carries his name was compiled long after him and is not his.")),
            .shortOnly(.text("Al-Hasan al-Basri (may Allah have mercy on him) grew up around the house of Umm Salamah and for decades was the preacher and the conscience of Basrah. When Waasil ibn Ata withdrew from his circle to found the Mu‘tazilah, al-Hasan stayed with the Sunnah, and when the reciters of Iraq rose against al-Hajjaaj he refused to join them; he died in 110 AH (728 CE). Muhammad ibn Seereen (may Allah have mercy on him), who died in the same city a few months later, taught that this knowledge is religion, so look from whom you take your religion: the seed of the whole science of judging narrators.")),
            .door(.article("SahabahScholarsView")),
        ]),
        ArticleSection("MUJAAHID, SA‘EED IBN JUBAYR AND THE TAFSEER OF IBN ABBAAS", [
            .longOnly(.text("Ibn Abbaas (may Allah be pleased with him) was the Companion for whom the Prophet prayed that Allah would teach him the Book, and his students made sure that teaching survived. Mujaahid ibn Jabr of Makkah (may Allah have mercy on him), who died in about 104 AH (722 CE), described how he learned it:")),
            .longOnly(.quote(text: "“I went through the mushaf with Ibn Abbaas three times, from its opening to its end, stopping him at every ayah and asking him about it” (Mujaahid, related by at-Tabari in the introduction to his Tafseer, and quoted by Ibn Taymiyyah in his Muqaddimah fi Usool at-Tafseer).", arabic: "عَرَضتُ المُصحَفَ عَلَى ابنِ عَبَّاسٍ ثَلَاثَ عَرَضَاتٍ، مِن فَاتِحَتِهِ إِلَى خَاتِمَتِهِ، أُوقِفُهُ عِندَ كُلِّ آيَةٍ مِنهُ وَأَسأَلُهُ عَنهَا", dimmed: true)),
            .longOnly(.text("Sufyaan ath-Thawri said that when a tafseer reached you from Mujaahid it was enough for you, and Ibn Taymiyyah, explaining the right method of tafseer, puts the explanations of such Taabi‘oon next after the Quran, the Sunnah and the words of the Companions.")),
            .longOnly(.text("Sa‘eed ibn Jubayr of Koofah, another student of Ibn Abbaas, shows the method in a single conversation that Muslim records. A man told him he had used an incantation after a scorpion sting, because of a hadith he had heard. Sa‘eed did not scold him. He said that whoever stops at what he has heard has done well, and then gave him a higher teaching from Ibn Abbaas: that among the seventy thousand of this nation who will enter Paradise without reckoning are those who do not ask others for incantations and who put their trust in their Lord (Saheeh Muslim 220). He honoured a man for following a text, and then led him to a better one.")),
            .longOnly(.hadith("muslim:220a", cite: "Saheeh Muslim 220", arabic: 75...230, english: [132...148, 277...300, 410...435])),
            .longOnly(.text("Sa‘eed’s life ended in the fitnah of his time. He joined the reciters who rose with Ibn al-Ash‘ath, hid for years after their defeat, and was taken and executed by al-Hajjaaj in 95 AH (714 CE); al-Hajjaaj died a few months later, and the scholars mourned Sa‘eed as one killed unjustly. They also drew a lesson from that revolt. Ibn Taymiyyah notes in Minhaaj as-Sunnah that the uprising of the reciters against al-Hajjaaj brought defeat and bloodshed and achieved none of what they sought, and that experiences like it are part of why Ahl as-Sunnah settled on patience with unjust rulers and sincere counsel to them.")),
            .shortOnly(.text("Ibn Abbaas (may Allah be pleased with him) was the Companion for whom the Prophet prayed that Allah would teach him the Book, and his students made sure that teaching survived. Mujaahid ibn Jabr of Makkah (may Allah have mercy on him) went through the mushaf with him three times, asking about every ayah. Sa‘eed ibn Jubayr of Koofah, another of his students, joined the revolt of the reciters against al-Hajjaaj and was executed by him in 95 AH (714 CE); the scholars mourned him as one killed unjustly, and that revolt, which brought only defeat and bloodshed, is part of why Ahl as-Sunnah settled on patience with unjust rulers and sincere counsel to them.")),
        ]),
        ArticleSection("UMAR IBN ABD AL-AZEEZ, THE RENEWER", [
            .text("The Prophet (peace be upon him) promised that the religion would not be left to decay:"),
            .hadith("abudawud:4291", cite: "Sunan Abi Daawood 4291; graded saheeh by al-Albaani", arabic: 36...49, english: [4...25]),
            .longOnly(.text("Imam Ahmad and others named Umar ibn Abd al-Azeez (may Allah have mercy on him) as the renewer at the head of the first hundred years, and ash-Shaafi‘i at the head of the second. His mother was a granddaughter of Umar ibn al-Khattaab, and he ruled for only about two and a half years, from 99 to 101 AH (717–720 CE). He began with his own family, returning to their owners lands and wealth that the house of Umayyah had taken, and he ended the practice of cursing Ali (may Allah be pleased with him) from the pulpits; the historians record that he had the preachers recite in its place the verse that is still heard at the close of Friday sermons:")),
            .longOnly(.ayah("16:90")),
            .longOnly(.text("He listened when he was corrected. Before his caliphate, as governor of Madinah, he once delayed the prayer, and Urwah ibn az-Zubayr came to him:")),
            .longOnly(.hadith("bukhari:521", cite: "Saheeh al-Bukhaari 521", arabic: 12...151, english: [0...187])),
            .longOnly(.text("A ruler asked a scholar for proof, and the scholar answered with a chain of names reaching the Prophet. As caliph he made that chain a public concern: he wrote to the judge of Madinah, Abu Bakr ibn Hazm, to seek out the hadith of the Prophet and write it down for fear that knowledge would vanish with its scholars, and Ibn Shihaab az-Zuhri (d. 124 AH), the teacher of Maalik, became the first to record it by his order. That story is told in full here:")),
            .shortOnly(.text("Imam Ahmad and others named Umar ibn Abd al-Azeez (may Allah have mercy on him) as the renewer at the head of the first hundred years. His mother was a granddaughter of Umar ibn al-Khattaab, and he ruled for only about two and a half years, from 99 to 101 AH (717–720 CE). He began with his own family, returning lands and wealth that the house of Umayyah had taken, and he ended the practice of cursing Ali from the pulpits. He also wrote to the judge of Madinah to seek out the hadith of the Prophet and write it down, for fear that knowledge would vanish with its scholars, and Ibn Shihaab az-Zuhri became the first to record it by his order.")),
            .door(.article("HadithPreservationView")),
        ]),
        ArticleSection("THE GENERATION AFTER THEM", [
            .markdown("The students of the Taabi‘oon, the **Atbaa‘ at-Taabi‘een (أَتبَاعُ التَّابِعِينَ)**, were the third of the best generations, and they gave the knowledge its lasting form. Maalik and Abu Haneefah belong to them and have their own chapter. Beside them stood imams whose schools did not survive as schools but whose knowledge fills every later book."),
            .longOnly(.markdown("**Sufyaan ath-Thawri** of Koofah (d. 161 AH), called the Commander of the Believers in hadith, refused the judgeship the Abbasid caliphs pressed on him and spent his last years in hiding to avoid it. **Al-Awzaa‘i** (d. 157 AH) was the imam of Syria, whose school was followed there and in al-Andalus for generations. **Al-Layth ibn Sa‘d** (d. 175 AH) of Egypt was so wealthy and so generous that the biographers relate he never owed zakaah, because he gave his wealth away before the year turned on it; his long, courteous letter to Maalik disputing the authority of the practice of Madinah is preserved by Ibn al-Qayyim, a model of how imams disagreed. **Abdullah ibn al-Mubaarak** (d. 181 AH) of Khuraasaan was a merchant who spent his profits on scholars, a fighter on the frontier and a master of hadith, and he died at Hit on the Euphrates on his way back from a campaign.")),
            .door(.article("CompanionFourImamsView")),
            .longOnly(.text("These three generations, the Companions, the Taabi‘oon and their students, are the Salaf. Their agreement in creed is the measure for every later school, because the Prophet vouched for their goodness and they received the religion closest to its source. A Muslim today who asks his Lord to forgive him and his brothers who preceded him in faith, and to keep resentment toward the believers out of his heart, is making the prayer that Allah taught to those who came after the Companions (59:10).")),
            .shortOnly(.text("These three generations, the Companions, the Taabi‘oon and their students, are the Salaf. Their agreement in creed is the measure for every later school, because the Prophet vouched for their goodness and they received the religion closest to its source.")),
            .door(.article("SalafScholarsView")),
            .door(.article("SalafiyyahView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Taabi‘oon are the generation that met the Companions and carried what they learned from them, the second of the three generations the Prophet praised and those who followed with excellence in 9:100. The Prophet named Uways, a man unknown but for his kindness to his mother, as the best of them. In Madinah, Makkah, Koofah, Basrah and Syria they formed the first schools: Sa‘eed ibn al-Musayyib in the judgements of Umar, Urwah in the knowledge of Aa’ishah, Mujaahid and Sa‘eed ibn Jubayr in the tafseer of Ibn Abbaas, al-Hasan in preaching and Ibn Seereen in the isnaad. They faced unjust rulers with firmness and patience, Umar ibn Abd al-Azeez showed what a just ruler of their generation could do, and az-Zuhri wrote the hadith down by his order. Their students completed the Salaf, whose understanding remains the measure of the religion."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Taabi‘i", arabic: "تَابِعِيّ", meaning: "**A Successor**, from the root **ت-ب-ع**, to follow: one who met a Companion as a believer and died a Muslim. The plural is **Taabi‘oon** or **Taabi‘een**."),
            .term("Mukhadram", arabic: "مُخَضرَم", meaning: "One who lived through **both eras**, the days of ignorance and the time of the Prophet, and accepted Islam without ever seeing him. The mukhadramoon are counted among the senior Taabi‘oon, and Uways al-Qarani is one of them."),
            .term("Atbaa‘ at-Taabi‘een", arabic: "أَتبَاعُ التَّابِعِينَ", meaning: "**The followers of the Successors**: those who met a Taabi‘i as believers, the third of the three best generations, among them Maalik, Abu Haneefah, Sufyaan ath-Thawri and al-Awzaa‘i."),
            .term("Tadween", arabic: "تَدوِين", meaning: "**Official recording**: the gathering of the hadith into written collections by order of the state, begun under Umar ibn Abd al-Azeez around 100 AH. Writing itself is older and goes back to the Companions."),
        ]),
    ]
}

struct CompanionFourImamsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "CompanionFourImamsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Four Imams")
        .englishArticle().selectableArticleList(article: "CompanionFourImamsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Abu Haneefah of Koofah (80–150 AH), Maalik of Madinah (93–179 AH), ash-Shaafi‘i (150–204 AH) and Ahmad ibn Hanbal of Baghdaad (164–241 AH) were imams of the generations nearest the Salaf, joined to one another as teachers and students, and their students turned their teaching into the four schools of fiqh. They differed in method and in many rulings, yet held one creed, the creed of the Salaf, and each told those who followed him to leave his word for an authentic hadith. Every one of them suffered at the hands of rulers, and Ahmad’s stand in the Mihnah, when the state tried to force the doctrine that the Quran is created, made him the imam of Ahl as-Sunnah. Some famous words attributed to them are weakly attested; this chapter relies on what is sound."),
        ]),
        ArticleSection("FOUR MEN AND ONE CHAIN", [
            .longOnly(.text("Allah did not ask every believer to become a scholar, but He did ask that some should:")),
            .longOnly(.ayah("9:122", words: 6...17)),
            .longOnly(.text("The four imams were such men, and they did not stand apart from one another. Abu Haneefah and Maalik were contemporaries. Ash-Shaafi‘i studied with Maalik in Madinah and with Muhammad ibn al-Hasan ash-Shaybaani, Abu Haneefah’s student, in Baghdaad. Ahmad studied with ash-Shaafi‘i in Baghdaad. So the four schools are, at their root, one conversation carried across three generations, each imam knowing what the one before him had said and why.")),
            .longOnly(.text("None of them founded a school in the sense of an institution. Each taught a method and a body of answers; his students wrote them down, argued with them and refined them, and over the following generations the schools took shape around their names. The page on the madhaahib tells that history, and this chapter tells the lives:")),
            .shortOnly(.text("The four imams did not stand apart from one another. Abu Haneefah and Maalik were contemporaries; ash-Shaafi‘i studied with Maalik in Madinah and with Abu Haneefah’s student Muhammad ibn al-Hasan ash-Shaybaani in Baghdaad; Ahmad studied with ash-Shaafi‘i. None of them founded a school in the sense of an institution: their students wrote down their teaching, and over the following generations the schools took shape around their names.")),
            .door(.article("MadhabView")),
        ]),
        ArticleSection("ABU HANEEFAH, THE JURIST OF KOOFAH", [
            .longOnly(.text("An-Nu‘maan ibn Thaabit (may Allah have mercy on him), known as Abu Haneefah, was born in Koofah in 80 AH (699 CE) to a family of Persian origin and earned his living as a cloth merchant all his life. As a boy he saw the Companion Anas ibn Maalik, but his knowledge came from the Taabi‘oon and their students. For about eighteen years, until his teacher’s death, he sat with Hammaad ibn Abi Sulaymaan, who carried the fiqh of Ibraaheem an-Nakha‘i and through him that of Alqamah and Abdullah ibn Mas‘ood, the Companion Umar had sent to teach Koofah.")),
            .longOnly(.text("His method, as his students reported it, was to take the Book of Allah first, then the Sunnah of the Prophet Muhammad (peace and blessings be upon him), then the sayings of the Companions, choosing among them when they differed but never stepping outside them; when a question reached only the opinions of Taabi‘oon such as an-Nakha‘i, ash-Sha‘bi and al-Hasan, he said that they were men who had reasoned and he would reason as they did. Iraq in his day was full of forged hadith, and he was strict in what he accepted and bold in reasoning by analogy, which is why his school became known for its careful reasoning. Ash-Shaafi‘i said that in fiqh all people depend on Abu Haneefah.")),
            .longOnly(.text("He would not serve the state. The biographers relate that he was beaten by the last Umayyad governor of Iraq for refusing a post, and that the Abbasid caliph al-Mansoor imprisoned him for refusing to become chief judge. He died in Baghdaad in 150 AH (767 CE). His students carried his school: Abu Yoosuf, who became chief judge of the Abbasids, Muhammad ibn al-Hasan ash-Shaybaani, who wrote down its books, and Zufar.")),
            .longOnly(.text("Ahl as-Sunnah honour him as an imam and are honest about where the others differed with him. Some early hadith critics found fault with his narration and his use of opinion, and he defined faith as belief and confession without including deeds, against the other imams. Ibn Taymiyyah explains in Kitaab al-Eemaan that much of that dispute was one of wording, since Abu Haneefah too held that the sinning believer is under the threat of punishment. The creed book al-Fiqh al-Akbar reaches him by a weak chain; his school’s creed is soundly recorded by at-Tahaawi.")),
            .shortOnly(.text("An-Nu‘maan ibn Thaabit (may Allah have mercy on him), known as Abu Haneefah, was born in Koofah in 80 AH (699 CE) and earned his living as a cloth merchant all his life. For about eighteen years he sat with Hammaad ibn Abi Sulaymaan, who carried the fiqh of Abdullah ibn Mas‘ood. His method was to take the Book of Allah first, then the Sunnah, then the sayings of the Companions, and to reason carefully by analogy where they were silent; ash-Shaafi‘i said that in fiqh all people depend on Abu Haneefah. He would not serve the state, and the caliph al-Mansoor imprisoned him for refusing to become chief judge. He died in Baghdaad in 150 AH (767 CE).")),
        ]),
        ArticleSection("MAALIK, THE IMAM OF MADINAH", [
            .longOnly(.text("Maalik ibn Anas (may Allah have mercy on him) was born in Madinah in 93 AH (711 CE) and, the biographers say, left it only for the Hajj. He learned from the Taabi‘oon of the city: Naafi‘, the freedman of Ibn Umar; Ibn Shihaab az-Zuhri; Rabee‘ah ibn Abi Abd ar-Rahman; and Ja‘far as-Saadiq of the Prophet’s household, from whom he narrates in his book. Al-Bukhaari called the chain “Maalik, from Naafi‘, from Ibn Umar” the soundest of all chains, and later scholars named it the golden chain.")),
            .longOnly(.text("His Muwatta’, “the well-trodden path,” gathered the hadith of the Prophet, the rulings of the Companions and the practice of Madinah, the city where the Prophet had lived and died and where his Sunnah was still the daily custom. That practice, the ‘amal of the people of Madinah, was a source of law in Maalik’s method beside the Quran and the Sunnah. Ash-Shaafi‘i said, before the two Saheehs were written, that there was no book on earth after the Book of Allah more correct than Maalik’s. When a caliph proposed to impose the Muwatta’ on every province, Maalik refused, saying that the Companions had spread through the lands and each people had taken what reached them.")),
            .longOnly(.text("He changed his ruling when a hadith reached him. Abdullah ibn Wahb, his Egyptian student, told how Maalik was asked about washing between the toes in ablution and said it was not required of people; Ibn Wahb waited until the crowd left and then gave him a hadith, with its chain, that the Prophet rubbed between his toes with his little finger. Maalik said it was a good hadith that he had never heard, and afterwards Ibn Wahb heard him command it (Ibn Abi Haatim, introduction to al-Jarh wat-Ta‘deel). In about 146 AH (763 CE) the governor of Madinah had him flogged for narrating that a divorce pronounced under coercion does not count, because the authorities feared people would apply it to the pledges they had been forced to give. He died in Madinah in 179 AH (795 CE).")),
            .longOnly(.callout("A narration is often applied to Maalik, that people will one day ride their camels hard in search of knowledge and find no one more learned than the scholar of Madinah. Its chain is weak, so it is not relied on here. Maalik’s rank does not need it.", title: "A Note on a Famous Narration", icon: "exclamationmark.triangle.fill")),
            .shortOnly(.text("Maalik ibn Anas (may Allah have mercy on him) was born in Madinah in 93 AH (711 CE) and, the biographers say, left it only for the Hajj. He learned from the Taabi‘oon of the city, and al-Bukhaari called the chain “Maalik, from Naafi‘, from Ibn Umar” the soundest of all chains. His Muwatta’ gathered the hadith of the Prophet, the rulings of the Companions and the practice of Madinah, and when a caliph proposed to impose it on every province, Maalik refused. He changed his ruling when a hadith reached him, and the governor of Madinah had him flogged for narrating that a divorce pronounced under coercion does not count. He died in Madinah in 179 AH (795 CE).")),
        ]),
        ArticleSection("ASH-SHAAFI‘I, DEFENDER OF THE SUNNAH", [
            .longOnly(.text("Muhammad ibn Idrees ash-Shaafi‘i (may Allah have mercy on him) was born in 150 AH (767 CE), the year Abu Haneefah died, most say in Gaza. He was of Quraysh, from the clan of al-Muttalib, which meets the Prophet’s line at Abd Manaaf. His widowed mother took him as a small child to Makkah, where he memorised the Quran, studied with its mufti Muslim ibn Khaalid az-Zanji and with Sufyaan ibn Uyaynah, and spent time among the Bedouin of Hudhayl perfecting his Arabic. As a young man he went to Madinah and studied with Maalik, on and off, until Maalik’s death.")),
            .longOnly(.text("Accused in Yemen of siding with an Alid uprising, he was brought in chains before Haaroon ar-Rasheed in 184 AH and cleared. In Baghdaad he then studied the books of Muhammad ibn al-Hasan ash-Shaybaani and so joined the fiqh of the Hijaaz to the fiqh of Iraq. His ar-Risaalah is the earliest surviving book on usool al-fiqh, the principles by which rulings are drawn from the texts. In it he argued that the Sunnah explains the Quran and is itself revelation to be obeyed, and that a hadith reported by a single trustworthy chain is binding proof, against those who wanted to set the Sunnah aside. The people of Baghdaad called him the Defender of the Hadith.")),
            .longOnly(.text("He moved to Egypt in 199 AH, revised many of his rulings there, which is why his school speaks of his old and new opinions, and died in Fustaat in 204 AH (820 CE). He was severe toward speculative theology, kalaam, and the scholars of the Sunnah often quote his harsh words against its people. He also knew the limits of his own hadith knowledge: Ibn Abi Haatim relates that he told Ahmad that Ahmad knew the hadith and its men better than he did, and asked him to tell him whenever a hadith was authentic, from whatever city it came, so that he could follow it.")),
            .shortOnly(.text("Muhammad ibn Idrees ash-Shaafi‘i (may Allah have mercy on him), of Quraysh, was born in 150 AH (767 CE), the year Abu Haneefah died. He memorised the Quran in Makkah, studied with Maalik in Madinah, and in Baghdaad joined the fiqh of the Hijaaz to the fiqh of Iraq. His ar-Risaalah is the earliest surviving book on usool al-fiqh, and in it he argued that the Sunnah explains the Quran and is itself revelation to be obeyed, so that the people of Baghdaad called him the Defender of the Hadith. He died in Egypt in 204 AH (820 CE).")),
        ]),
        ArticleSection("AHMAD IBN HANBAL AND THE MIHNAH", [
            .longOnly(.text("Ahmad ibn Muhammad ibn Hanbal (may Allah have mercy on him) was born in Baghdaad in 164 AH (780 CE), of the Arab tribe of Shayban, and lost his father as a child. He spent his youth travelling for hadith, to Koofah, Basrah, Makkah, Madinah, Syria and as far as San‘a in Yemen to hear Abd ar-Razzaaq, and learned from Hushaym, Sufyaan ibn Uyaynah, Wakee‘, Yahya ibn Sa‘eed al-Qattaan, Abd ar-Rahman ibn Mahdi and ash-Shaafi‘i. His Musnad, arranged by the Companion who narrates each report, is one of the largest collections ever made, and al-Bukhaari, Muslim and Abu Daawood were among those who learned from him.")),
            .longOnly(.text("In 218 AH (833 CE) the caliph al-Ma’moon, won over by the Mu‘tazilah, ordered that every judge and scholar be tested on whether the Quran was created. The inquisition, the Mihnah, lasted under three caliphs. Most scholars, under threat, gave the answer demanded of them. Ahmad would not. He was sent in chains toward the caliph with Muhammad ibn Nooh, al-Ma’moon died before they reached him, and Muhammad ibn Nooh died on the road back. Under al-Mu‘tasim, Ahmad was brought out for days of debate with the chief judge Ibn Abi Du’aad and his theologians. To every argument he answered with the same request, for something from the Book of Allah or the Sunnah of His Messenger that said what they wanted him to say. They had nothing, and he was flogged until he lost consciousness.")),
            .longOnly(.text("He was released, lived under restriction through the reign of al-Waathiq, and was freed to teach again when al-Mutawakkil ended the Mihnah. He later forgave the caliph who had him flogged, and he refused the gifts the new caliph sent him. Ali ibn al-Madeeni, as al-Khateeb al-Baghdaadi relates, said that Allah strengthened this religion through Abu Bakr on the day of the apostasy and through Ahmad on the day of the Mihnah. When he died in 241 AH (855 CE), Baghdaad turned out for his funeral in numbers the historians struggled to count. Allah describes such men:")),
            .longOnly(.ayah("32:24")),
            .shortOnly(.text("Ahmad ibn Hanbal (may Allah have mercy on him) was born in Baghdaad in 164 AH (780 CE), travelled as far as Yemen for hadith, studied with ash-Shaafi‘i, and compiled the Musnad, one of the largest collections ever made. In 218 AH (833 CE) the caliph al-Ma’moon, won over by the Mu‘tazilah, ordered that every judge and scholar be tested on whether the Quran was created, and the Mihnah lasted under three caliphs. Most scholars, under threat, gave the answer demanded of them. Ahmad would not: to every argument he answered with a request for something from the Book of Allah or the Sunnah of His Messenger that said what they wanted him to say, and he was flogged until he lost consciousness. He later forgave the caliph who had him flogged, and when he died in 241 AH (855 CE), Baghdaad turned out for his funeral in numbers the historians struggled to count.")),
            .text("The point at issue was not a technicality. If the Quran is created, it is a thing among things and not the speech of Allah, and the attribute of speech is denied to Him. Ahmad held to what the Companions and the Taabi‘oon had held, that the Quran is the speech of Allah, revealed and not created, and he would not say more than the texts said or less."),
            .door(.article("AqeedahMadhabView")),
        ]),
        ArticleSection("WHAT THEY SAID ABOUT FOLLOWING THEM", [
            .longOnly(.text("Each of the four told his followers in plain words that his opinion was beneath the Quran and the Sunnah. Al-Albaani (may Allah have mercy on him) gathered these statements, with their sources, in the introduction to Sifaat Salaat an-Nabi. Some of the best known, among them ash-Shaafi‘i’s “if the hadith is authentic, it is my madhhab,” are quoted on the page on the madhaahib. Here are four more, one from each imam:")),
            .longOnly(.quote(text: "“If I say something that contradicts the Book of Allah, the Exalted, and the report of the Messenger (peace be upon him), then leave my saying” (Abu Haneefah, related by al-Fulaani in Eeqaaz Himam Uli al-Absaar).", arabic: "إِذَا قُلتُ قَولًا يُخَالِفُ كِتَابَ اللَّهِ تَعَالَى وَخَبَرَ الرَّسُولِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ فَاترُكُوا قَولِي", dimmed: true)),
            .shortOnly(.text("Each of the four told his followers in plain words that his opinion was beneath the Quran and the Sunnah. Maalik said:")),
            .quote(text: "“I am only a man: I err and I am right. So look into my opinion: whatever agrees with the Book and the Sunnah, take it, and whatever does not agree with the Book and the Sunnah, leave it” (Maalik, related by Ibn Abd al-Barr in Jaami‘ Bayaan al-Ilm wa Fadlih).", arabic: "إِنَّمَا أَنَا بَشَرٌ أُخطِئُ وَأُصِيبُ، فَانظُرُوا فِي رَأيِي، فَكُلُّ مَا وَافَقَ الكِتَابَ وَالسُّنَّةَ فَخُذُوهُ، وَكُلُّ مَا لَم يُوَافِقِ الكِتَابَ وَالسُّنَّةَ فَاترُكُوهُ", dimmed: true),
            .longOnly(.quote(text: "“The Muslims are agreed that whoever has a Sunnah of the Messenger of Allah (peace be upon him) made clear to him may not leave it for the saying of anyone” (ash-Shaafi‘i, related by Ibn al-Qayyim in I‘laam al-Muwaqqi‘een).", arabic: "أَجمَعَ المُسلِمُونَ عَلَى أَنَّ مَنِ استَبَانَ لَهُ سُنَّةٌ عَن رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ لَم يَحِلَّ لَهُ أَن يَدَعَهَا لِقَولِ أَحَدٍ", dimmed: true)),
            .longOnly(.quote(text: "“The opinion of al-Awzaa‘i, the opinion of Maalik and the opinion of Abu Haneefah are all opinion, and to me they are equal; the proof is only in the narrations” (Ahmad, related by Ibn Abd al-Barr in Jaami‘ Bayaan al-Ilm wa Fadlih).", arabic: "رَأيُ الأَوزَاعِيِّ، وَرَأيُ مَالِكٍ، وَرَأيُ أَبِي حَنِيفَةَ، كُلُّهُ رَأيٌ، وَهُوَ عِندِي سَوَاءٌ، وَإِنَّمَا الحُجَّةُ فِي الآثَارِ", dimmed: true)),
            .longOnly(.text("This is not false modesty. It is the command of Allah to refer every dispute back to Him and His Messenger:")),
            .longOnly(.ayah("4:59", words: 10...17)),
            .longOnly(.text("And it does not make their effort worthless when they missed. The Prophet (peace be upon him) promised a reward even for the mistaken judgement of one who strives to find the truth:")),
            .longOnly(.hadith("bukhari:7352", cite: "Saheeh al-Bukhaari 7352", arabic: 46...60, english: [7...71])),
            .text("So the scholars of the Sunnah keep two things together. They follow the imams as guides to the texts and are grateful for every ruling the imams reached, and where an authentic text clearly says otherwise they follow the text, as the imams themselves commanded. Leaving an imam’s opinion for a hadith is obedience to the imam, not rebellion against him."),
        ]),
        ArticleSection("ONE CREED", [
            .longOnly(.text("In fiqh the four differed widely; in creed they did not. All four affirmed the names and attributes of Allah as they came, without distorting them, denying them, asking how or likening them to creation; held that the Quran is the speech of Allah and not created; held that the believers will see their Lord in the Hereafter; loved all the Companions; and put Abu Bakr and then Umar first. Maalik’s answer to the man who asked how Allah rose over the Throne, that the rising is known, its manner unknown, belief in it obligatory and the question an innovation, became the motto of that creed, and Ahmad’s Usool as-Sunnah set it down article by article.")),
            .longOnly(.text("Two famous creedal texts need care. Al-Fiqh al-Akbar is attributed to Abu Haneefah through a chain the critics graded weak, and the much-quoted saying of ash-Shaafi‘i, that he believed in Allah and in what came from Allah as Allah intended it, is recorded by Ibn Qudaamah without any chain. Both say nothing that contradicts the creed of the Salaf, and the scholars of the Sunnah have quoted them against those who claim these imams’ names for other creeds, but neither is cited here as their proven words. What is sound is enough: Maalik’s answer on the rising, Ahmad’s stand in the Mihnah, at-Tahaawi’s creed for the school of Abu Haneefah, and ash-Shaafi‘i’s defence of the Sunnah. The later schools of kalaam that attached themselves to some of these names came after them and differed from them.")),
            .shortOnly(.text("In fiqh the four differed widely; in creed they did not. All four affirmed the names and attributes of Allah as they came, without distorting them, denying them, asking how or likening them to creation; held that the Quran is the speech of Allah and not created; loved all the Companions; and put Abu Bakr and then Umar first. Maalik’s answer to the man who asked how Allah rose over the Throne, that the rising is known, its manner unknown, belief in it obligatory and the question an innovation, became the motto of that creed.")),
        ]),
        ArticleSection("SCHOOLS, NOT SECTS", [
            .longOnly(.text("The imams spoke of one another with respect, and the biographers preserve it. Ash-Shaafi‘i said that when the scholars are mentioned, Maalik is the star among them. Ahmad’s son Abdullah asked his father why he prayed for ash-Shaafi‘i so often, and Ahmad said that ash-Shaafi‘i had been like the sun to the world and like health to the body. Ash-Shaafi‘i said that when he left Baghdaad he left no one there more learned in fiqh or more scrupulous than Ahmad.")),
            .longOnly(.text("Their followers prayed behind one another despite their differences in the rules of prayer. Ibn Taymiyyah relates in Majmoo‘ al-Fataawa that Ahmad, who held that bleeding breaks ablution, was asked whether one should pray behind an imam who did not renew his ablution after being cupped, and answered: how could I not pray behind Maalik and Sa‘eed ibn al-Musayyib? That is the spirit of a school of fiqh: a method of understanding shared by teachers and students, not a separate religion with its own loyalty and enmity.")),
            .longOnly(.text("What the scholars condemned was partisanship, ta‘assub: treating an imam as infallible, setting aside an authentic hadith for his sake, or making agreement with him the basis of love and enmity among Muslims. That turns a school into a sect, and it is exactly what the four imams forbade in the words quoted above. The great Salafi scholars after them followed the schools in this spirit: Ibn Taymiyyah and Ibn al-Qayyim were Hanbalis, Ibn Katheer and adh-Dhahabi Shaafi‘ees, Ibn Abd al-Barr a Maaliki and at-Tahaawi a Hanafi, and each of them, where he found the evidence against his school, said so and followed the evidence.")),
            .shortOnly(.text("The imams spoke of one another with respect, and their followers prayed behind one another despite their differences in the rules of prayer. What the scholars condemned was partisanship, ta‘assub: treating an imam as infallible, setting aside an authentic hadith for his sake, or making agreement with him the basis of love and enmity among Muslims. That turns a school into a sect, and it is exactly what the four imams forbade.")),
            .door(.article("SalafScholarsView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The four imams were men of the generations nearest the Salaf who gave their lives to understanding the religion, linked by teaching from Koofah and Madinah to Makkah, Baghdaad and Egypt. Abu Haneefah reasoned carefully in a city of forgeries, Maalik preserved the Sunnah as Madinah lived it, ash-Shaafi‘i laid down the principles of law and defended the Sunnah as revelation, and Ahmad gathered the hadith and stood alone against the state for the uncreated Quran. Each suffered for refusing rulers, each told his followers to leave his word for the Sunnah, and all four held the one creed of the Salaf. Their schools are schools of fiqh, followed as ladders to the evidence and never as rivals to it."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Madhhab", arabic: "مَذهَب", meaning: "**A way taken**, from the root **ذ-ه-ب**, to go: a school of fiqh, the method and rulings of an imam as his students developed them. The plural is **madhaahib**."),
            .term("Usool al-Fiqh", arabic: "أُصُولُ الفِقهِ", meaning: "**The principles of jurisprudence**: the rules by which rulings are drawn from the Quran, the Sunnah, consensus and analogy. Ash-Shaafi‘i’s ar-Risaalah is the earliest surviving book on it."),
            .term("Amal Ahl al-Madinah", arabic: "عَمَلُ أَهلِ المَدِينَةِ", meaning: "**The practice of the people of Madinah**: the inherited custom of the Prophet’s city, which Maalik treated as evidence of the Sunnah, since it had been lived there continuously from the Prophet’s time."),
            .term("Mihnah", arabic: "مِحنَة", meaning: "**The trial**: the inquisition of 218 to about 234 AH in which three caliphs tried to force the scholars to say that the Quran is created. Imam Ahmad’s refusal to say it is its best-remembered chapter."),
        ]),
    ]
}
