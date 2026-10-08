import SwiftUI

// Hadith & Its Sciences (Abu, 2026-09-29: "add Hadith sciences ... make that its own link near the Quran
// stuff like tafsir and seerah ... have a refuting Hadith rejectors section"). Three data-backed articles in
// their own group of Pillars & Beliefs, right after Quran & Tafsir: how a narration is weighed, how the
// Sunnah was kept, and the answer to those who would keep the Quran without it.
//
// The rules every article keeps (Scripts/audit_islam_quotes.py, verify_islam_corpus.py): every ayah is a
// `.ayah(` reference and every hadith a `.hadith(` reference into the bundled shelf, sahih or hasan by the
// weight of its graders; the words of scholars that the shelf does not carry are `.quote(text:)` with
// their source; no em dash, and no spaced hyphen standing in for one.

/// The sciences of hadith (mustalah al-hadith): why reports are verified, the chain and the text, the
/// five conditions of a sahih hadith, the scale of grades, the weighing of narrators, hidden defects,
/// the classes of report by who is speaking, the classic books of the science, and how this app grades.
/// First of the HADITH & ITS SCIENCES group, beside How the Hadith Were Preserved.
struct HadithSciencesView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithSciencesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Sciences of Hadith")
        .selectableArticleList(article: "HadithSciencesView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the sciences of hadith (mustalah al-hadith) are the rules by which Muslims tell what the Prophet (peace and blessings be upon him) actually said from what was falsely put in his mouth. Every report is weighed by its chain of narrators and by its text, graded on a scale from sahih (authentic) down to mawdu‘ (fabricated), and only what passes is taken as religion."),
        ]),
        ArticleSection("WHY EVERY REPORT IS CHECKED", [
            .text("A Muslim who follows the Sunnah has to know which reports are really part of it, and the command to verify a report is in the Quran itself. Allah (Glorified and Exalted be He) says:"),
            .ayah("49:6", words: 0...7),
            .text("The verse holds the whole method in one line: news is weighed by the one who brings it. A report from a man known for disobedience is investigated before anyone acts on it, which implies that the report of a trustworthy man is accepted."),
            .text("The Prophet (peace and blessings be upon him) warned against lying about him, and the warning made his Companions careful rather than talkative. ‘Abdullah ibn az-Zubayr asked his father, az-Zubayr ibn al-‘Awwam (may Allah be pleased with them both), why he did not narrate as others did:"),
            .hadith("bukhari:107", cite: "Sahih al-Bukhari 107", arabic: 20...53, english: [0...56]),
            .text("He had never left the Prophet’s side; it was the warning, not a lack of knowledge, that made him hold back. The warning also reaches the one who passes on a report he suspects is false, in a hadith that Imam Muslim quotes in the introduction to his Sahih:"),
            .hadith("ibnmajah:39", cite: "Sunan Ibn Majah 39; graded sahih by al-Albani", arabic: 33...54, english: [0...22]),
            .text("Nor may a Muslim repeat everything he hears. The Prophet said:"),
            .hadith("abudawud:4992", cite: "Sunan Abi Dawud 4992; graded sahih by al-Albani", arabic: 37...53, english: [0...15]),
            .text("The Companions (may Allah be pleased with them) practised this from the start. When Abu Musa al-Ash‘ari reported to ‘Umar ibn al-Khattab (may Allah be pleased with them both) a hadith that ‘Umar had not heard, ‘Umar asked him for a second witness. Abu Sa‘id al-Khudri (may Allah be pleased with him), who went with him, tells the story:"),
            .hadith("bukhari:6245", cite: "Sahih al-Bukhari 6245", arabic: 26...108, english: [12...178]),
            .text("Abu Dawud preserves ‘Umar’s reason, in a chain from Abu Musa’s own son:"),
            .hadith("abudawud:5183", cite: "Sunan Abi Dawud 5183; its chain graded sahih by al-Albani", arabic: 26...42, english: [0...28]),
            .text("‘Umar did not doubt Abu Musa’s honesty; he was teaching the Muslims that a word attributed to the Prophet is a heavy thing. Asking for the chain of narrators became the rule once the civil strife (fitnah) had divided the Muslims into parties. Muhammad ibn Sirin (d. 110 AH), the great Successor of Basrah, described the turning point:"),
            .quote(text: "“They did not use to ask about the isnad. When the fitnah came, they said: name your men to us. Then the people of the Sunnah would be looked at and their hadith taken, and the people of innovation would be looked at and their hadith not taken.” (Muhammad ibn Sirin, in the Muqaddimah of Sahih Muslim)", arabic: "لَم يَكُونُوا يَسأَلُونَ عَنِ الإِسنَادِ، فَلَمَّا وَقَعَتِ الفِتنَةُ قَالُوا: سَمُّوا لَنَا رِجَالَكُم، فَيُنظَرُ إِلَى أَهلِ السُّنَّةِ فَيُؤخَذُ حَدِيثُهُم، وَيُنظَرُ إِلَى أَهلِ البِدَعِ فَلَا يُؤخَذُ حَدِيثُهُم", dimmed: true),
            .text("The same Ibn Sirin put the principle in words every student of hadith knows, and ‘Abdullah ibn al-Mubarak (d. 181 AH) gave its reason:"),
            .quote(text: "“This knowledge is religion, so look at whom you take your religion from.” (Muhammad ibn Sirin, in the Muqaddimah of Sahih Muslim)", arabic: "إِنَّ هَذَا العِلمَ دِينٌ، فَانظُرُوا عَمَّن تَأخُذُونَ دِينَكُم", dimmed: true),
            .quote(text: "“The isnad is part of the religion. Were it not for the isnad, whoever wished would say whatever he wished.” (‘Abdullah ibn al-Mubarak, in the Muqaddimah of Sahih Muslim)", arabic: "الإِسنَادُ مِنَ الدِّينِ، وَلَولَا الإِسنَادُ لَقَالَ مَن شَاءَ مَا شَاءَ", dimmed: true),
            .door(.article("HadithPillarView")),
        ]),
        ArticleSection("THE CHAIN AND THE TEXT", [
            .markdown("Every hadith has two parts. The **isnad (إِسنَاد)**, also called the **sanad (سَنَد)**, is the chain of narrators: who told whom, back to the Prophet (peace and blessings be upon him). The **matn (مَتن)** is what the chain carries, his words or a description of what he did. Here is the first hadith in Sahih al-Bukhari as it stands in the book, the chain first and then the words:"),
            .hadith("bukhari:1", cite: "Sahih al-Bukhari 1, Sahih Muslim 1907", arabic: 0...80, english: [0...46]),
            .chain([
                ArticleChainLink("al-Bukhari", "d. 256 AH, the collector"),
                ArticleChainLink("al-Humaydi, ‘Abdullah ibn az-Zubayr", "d. 219 AH in Makkah, the foremost student of Ibn ‘Uyaynah"),
                ArticleChainLink("Sufyan ibn ‘Uyaynah", "d. 198 AH, of Makkah"),
                ArticleChainLink("Yahya ibn Sa‘id al-Ansari", "d. 144 AH or after, of Madinah"),
                ArticleChainLink("Muhammad ibn Ibrahim at-Taymi", "d. 120 AH, of Madinah"),
                ArticleChainLink("‘Alqamah ibn Waqqas al-Laythi", "of Madinah, d. under the caliph ‘Abd al-Malik (65–86 AH)"),
                ArticleChainLink("‘Umar ibn al-Khattab", "d. 23 AH, speaking from the minbar"),
                ArticleChainLink("The Prophet ﷺ", ""),
            ], caption: "The chain of Sahih al-Bukhari 1, read from its Arabic, with death dates from Ibn Hajar’s Taqrib at-Tahdhib"),
            .text("Six men stand between al-Bukhari and the Prophet, and each has an entry in the books of narrators: his teachers, his students, his city, his death, and the critics’ verdict on him. The chain can also be checked from outside. Al-Humaydi, the first man in it, left a book of his own, his Musnad, which survives and records this same hadith through this same chain (Musnad al-Humaydi 28); and Muslim narrates it through Malik, al-Layth, Hammad ibn Zayd, Sufyan, Ibn al-Mubarak and others, all of them from Yahya ibn Sa‘id (Sahih Muslim 1907)."),
            .text("The critics examine the chain link by link and the text against every other report of it; the five conditions below cover both."),
            .door(.article("HadithPreservationView")),
        ]),
        ArticleSection("THE FIVE CONDITIONS OF A SAHIH HADITH", [
            .text("Ibn as-Salah (d. 643 AH), whose handbook became the reference for everyone after him, defined the authentic hadith in one sentence:"),
            .quote(text: "“The sahih hadith is the musnad hadith whose chain is connected by the transmission of an upright, precise narrator from an upright, precise narrator to its end, and which is neither shadh nor mu‘allal.” (Ibn as-Salah, ‘Ulum al-Hadith)", arabic: "أَمَّا الحَدِيثُ الصَّحِيحُ: فَهُوَ الحَدِيثُ المُسنَدُ الَّذِي يَتَّصِلُ إِسنَادُهُ بِنَقلِ العَدلِ الضَّابِطِ عَنِ العَدلِ الضَّابِطِ إِلَى مُنتَهَاهُ، وَلَا يَكُونُ شَاذًّا وَلَا مُعَلَّلًا", dimmed: true),
            .checklist([
                "**A connected chain (ittisal as-sanad):** every narrator heard the report from the one before him, all the way back to the Prophet ﷺ.",
                "**Uprightness (‘adalah):** every narrator is a Muslim of sound religion and decent conduct, known not to lie.",
                "**Precision (dabt):** every narrator kept what he heard exactly, in his memory or in a carefully guarded book.",
                "**No irregularity (shudhudh):** the narrator does not contradict narrators more reliable than himself.",
                "**No hidden defect (‘illah):** no concealed flaw, found only by comparing every route of the report, undoes a chain that looks sound.",
            ], title: "The Five Conditions of a Sahih Hadith", icon: "checkmark.seal.fill"),
            .text("Ibn as-Salah did not invent these conditions. More than four centuries earlier, before al-Bukhari compiled his Sahih, ash-Shafi‘i (d. 204 AH) had already set out their substance:"),
            .quote(text: "“A report from one person does not stand as proof until it combines several things: that the one who narrates it is trustworthy in his religion, known for truthfulness in what he narrates, understanding what he narrates … retaining it if he narrates from memory, guarding his book if he narrates from his book; that when he shares a hadith with the memorizers, his agrees with theirs; that he is free of concealing his sources … and that everyone above him, who narrated it to him, is the same, until the hadith reaches the Prophet connected.” (ash-Shafi‘i, ar-Risalah)", arabic: "وَلَا تَقُومُ الحُجَّةُ بِخَبَرِ الخَاصَّةِ حَتَّى يَجمَعَ أُمُورًا: مِنهَا أَن يَكُونَ مَن حَدَّثَ بِهِ ثِقَةً فِي دِينِهِ، مَعرُوفًا بِالصِّدقِ فِي حَدِيثِهِ، عَاقِلًا لِمَا يُحَدِّثُ بِهِ … حَافِظًا إِن حَدَّثَ بِهِ مِن حِفظِهِ، حَافِظًا لِكِتَابِهِ إِن حَدَّثَ مِن كِتَابِهِ، إِذَا شَرِكَ أَهلَ الحِفظِ فِي حَدِيثٍ وَافَقَ حَدِيثَهُم، بَرِيًّا مِن أَن يَكُونَ مُدَلِّسًا … وَيَكُونُ هَكَذَا مَن فَوقَهُ مِمَّن حَدَّثَهُ، حَتَّى يُنتَهَى بِالحَدِيثِ مَوصُولًا إِلَى النَّبِيِّ", dimmed: true),
            .text("A connected chain means no missing link. When Ibrahim ibn ‘Isa at-Taliqani quoted to ‘Abdullah ibn al-Mubarak a hadith about praying and fasting on behalf of one’s parents, Ibn al-Mubarak asked, “From whom?” He named Shihab ibn Khirash. “Trustworthy. From whom?” Al-Hajjaj ibn Dinar. “Trustworthy. From whom?” He said, “The Messenger of Allah said…” Ibn al-Mubarak replied:"),
            .quote(text: "“Between al-Hajjaj ibn Dinar and the Prophet (peace and blessings be upon him) there are deserts in which the necks of the riding camels would give out.” (‘Abdullah ibn al-Mubarak, in the Muqaddimah of Sahih Muslim)", arabic: "إِنَّ بَينَ الحَجَّاجِ بنِ دِينَارٍ وَبَينَ النَّبِيِّ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ مَفَاوِزَ تَنقَطِعُ فِيهَا أَعنَاقُ المَطِيِّ", dimmed: true),
            .text("Two trustworthy names were not enough when the men between al-Hajjaj and the Prophet were missing. Charity on the parents’ behalf, Ibn al-Mubarak added, needs no such report, since no one disputes it: the critics rejected a broken chain, not a good deed."),
            .markdown("**Uprightness** and **precision** are the two halves of a narrator. For Ibn as-Salah, the narrator whose report is accepted is a Muslim, adult and sane, free of open sin and of what breaks decency (**muru’ah**), and alert rather than careless. Ibn Hajar divides his precision into **dabt as-sadr (ضَبط الصَّدر)**, keeping what he heard in his chest so that he can bring it back at will, and **dabt al-kitab (ضَبط الكِتَاب)**, guarding his written copy from the day he heard and corrected it until the day he narrates from it. A pious man with a poor memory fails as surely as a sharp-minded liar."),
            .text("No irregularity means that a reliable narrator does not contradict those more reliable than him. Ash-Shafi‘i drew the line exactly:"),
            .quote(text: "“Shadh is not that a trustworthy narrator relates what no one else relates. Shadh is only that a trustworthy narrator relates a hadith that contradicts what the people have related.” (ash-Shafi‘i, related by Ibn as-Salah in ‘Ulum al-Hadith)", arabic: "لَيسَ الشَّاذُّ مِنَ الحَدِيثِ أَن يَروِيَ الثِّقَةُ مَا لَا يَروِي غَيرُهُ، إِنَّمَا الشَّاذُّ أَن يَروِيَ الثِّقَةُ حَدِيثًا يُخَالِفُ مَا رَوَى النَّاسُ", dimmed: true),
            .markdown("The hidden defect has its own section below. A hadith that meets all five conditions is **sahih**. When its only shortfall is that a narrator’s precision is a little lighter, though still sound, it is **hasan**; when any condition fails, it is **da‘if**. Ibn as-Salah adds a caution worth keeping: calling a hadith “not sahih” is not a verdict that it is a lie in reality, only that its chain did not meet the standard."),
        ]),
        ArticleSection("THE SCALE OF GRADES", [
            .gradeLadder,
            .markdown("Grades can also be strengthened. A hasan chain supported by others rises to **sahih li-ghayrihi (صَحِيح لِغَيرِه)**, sahih by virtue of others, and a slightly weak chain supported by others rises to **hasan li-ghayrihi (حَسَن لِغَيرِه)**. But Ibn as-Salah names weaknesses that no number of routes can cure: a narrator accused of lying, and a shadh report."),
            .markdown("The second scale counts the narrators. A **mutawatir (مُتَوَاتِر)** hadith is carried at every level by so many that a shared lie is impossible; everything short of that is **ahad (آحَاد)**. Ibn as-Salah’s classic example of mutawatir is the warning against lying about the Prophet (peace and blessings be upon him) quoted above, which by the counts he cites was narrated by forty to sixty-two Companions. At the other end, the hadith of intentions came, by the verdict of the hadith scholars, through a single narrator at each of its first four links: ‘Umar alone from the Prophet, then ‘Alqamah, then Muhammad ibn Ibrahim, then Yahya ibn Sa‘id, before it spread. It is still sahih by agreement, because each of the four was trustworthy and precise."),
            .stats([
                ArticleStat("About 40", "Companions who narrated the warning against lying about the Prophet ﷺ, by al-Bazzar’s count"),
                ArticleStat("62", "Companions by another hafiz’s count, the ten promised Paradise among them"),
                ArticleStat("4", "links of the hadith of intentions carried by a single narrator each"),
                ArticleStat("9", "students of Yahya ibn Sa‘id who relay it in Sahih Muslim alone"),
            ]),
            .markdown("So ahad is a count, not a weakness. Ibn Hajar records that the demand for two narrators at every level came from the Mu‘tazili Abu ‘Ali al-Jubba’i, and that the very first hadith in al-Bukhari’s book refutes anyone who claims al-Bukhari required it. The highest rank of all is **muttafaq ‘alayh (مُتَّفَق عَلَيه)**, “agreed upon,” a hadith narrated by both al-Bukhari and Muslim, as the hadith of intentions is. Ibn as-Salah explains that the phrase means the agreement of those two imams, and that the Ummah’s agreement follows from it, because the Ummah received their two books with acceptance."),
        ]),
        ArticleSection("WEIGHING THE NARRATORS", [
            .markdown("The study of the men in the chains is **‘ilm ar-rijal (عِلم الرِّجَال)**, the knowledge of the men, and its verdicts are **al-jarh wat-ta‘dil (الجَرح وَالتَّعدِيل)**: jarh, “wounding,” is criticism of a narrator, and ta‘dil, “declaring upright,” is his vindication. Ibn Hajar’s one-line entry on Muhammad ibn Ibrahim at-Taymi, the fourth man in the chain above, shows how much a single verdict holds:"),
            .quote(text: "“Muhammad ibn Ibrahim ibn al-Harith ibn Khalid at-Taymi, Abu ‘Abdillah, of Madinah: trustworthy, with reports that he alone narrates; of the fourth generation; died in the year twenty, on the correct view.” (Ibn Hajar, Taqrib at-Tahdhib)", arabic: "مُحَمَّدُ بنُ إِبرَاهِيمَ بنِ الحَارِثِ بنِ خَالِدٍ التَّيمِيُّ، أَبُو عَبدِ اللَّهِ المَدَنِيُّ، ثِقَةٌ لَهُ أَفرَادٌ، مِنَ الرَّابِعَةِ، مَاتَ سَنَةَ عِشرِينَ عَلَى الصَّحِيحِ", dimmed: true),
            .text("“The year twenty” means 120 AH: the Taqrib leaves out the hundreds, which the reader supplies from the narrator’s generation, as its introduction explains. And “reports that he alone narrates” is exactly the case of the hadith of intentions, which the critics accepted because the one man who carried it was trustworthy."),
            .text("The Taqrib sorts every narrator into one of twelve ranks, and its words became the common vocabulary of grading:"),
            .bullet("**Thiqah (ثِقَة)**, trustworthy, and above it “thiqah thiqah” or “thiqah hafiz”: the narrator of the sahih hadith."),
            .bullet("**Saduq (صَدُوق)**, truthful, or “no harm in him”: a little short of thiqah, the usual narrator of the hasan hadith."),
            .bullet("**Maqbul (مَقبُول)**, acceptable where another narrator supports him, and **majhul (مَجهُول)**, unknown: only one narrator took from him and no one vouched for him."),
            .bullet("**Da‘if (ضَعِيف)**, weak: his report is not established by itself."),
            .bullet("**Matruk (مَترُوك)**, abandoned: his report is set aside altogether."),
            .bullet("**Muttaham bil-kadhib (مُتَّهَم بِالكَذِب)**, accused of lying, and at the bottom **kadhdhab (كَذَّاب)** or **wadda‘ (وَضَّاع)**: liar or fabricator."),
            .markdown("The scholars counted this criticism a defence of the Sunnah, not backbiting, and did it openly: Ibn al-Mubarak told a gathering to abandon the hadith of a narrator who reviled the Salaf (Muqaddimah of Sahih Muslim). The great critics include **Shu‘bah ibn al-Hajjaj** (d. 160 AH), whom Sufyan ath-Thawri called the Commander of the Believers in hadith and who was the first in Iraq to search into the narrators; **Yahya ibn Sa‘id al-Qattan** and **‘Abd ar-Rahman ibn Mahdi** (both d. 198 AH); **Yahya ibn Ma‘in** (d. 233 AH), called the imam of al-jarh wat-ta‘dil; **‘Ali ibn al-Madini** (d. 234 AH), of whom al-Bukhari said he never felt small before anyone else; **Ahmad ibn Hanbal** (d. 241 AH); al-Bukhari himself; and **Abu Zur‘ah** (d. 264 AH) and **Abu Hatim** (d. 277 AH) of Rayy."),
            .markdown("Their verdicts fill great reference works: al-Bukhari’s **at-Tarikh al-Kabir**; **al-Jarh wat-Ta‘dil** of Ibn Abi Hatim (d. 327 AH); **Tahdhib al-Kamal** of al-Mizzi (d. 742 AH) on the narrators of the six books; **Mizan al-I‘tidal** of adh-Dhahabi (d. 748 AH) on the narrators who were criticized; and, from Ibn Hajar (d. 852 AH), **Tahdhib at-Tahdhib** with its one-line digest, the **Taqrib**."),
        ]),
        ArticleSection("HIDDEN DEFECTS AND THE TEXT", [
            .text("A chain can list only trustworthy men, each of whom met the next, and still be wrong. Ibn as-Salah ranked the finding of such flaws above everything else in the field:"),
            .quote(text: "“Knowing the hidden defects of hadith is among the greatest of the sciences of hadith, the subtlest, and the noblest.” (Ibn as-Salah, ‘Ulum al-Hadith)", arabic: "مَعرِفَةُ عِلَلِ الحَدِيثِ مِن أَجَلِّ عُلُومِ الحَدِيثِ وَأَدَقِّهَا وَأَشرَفِهَا", dimmed: true),
            .markdown("An **‘illah (عِلَّة)** is a concealed cause that damages a report which looks sound: a chain that was really broken, a Companion’s own words passed off as the words of the Prophet (peace and blessings be upon him), two hadiths run together, a slip of memory. The only way to find one is to collect every route of the report and compare them, as al-Khatib al-Baghdadi (d. 463 AH) explained:"),
            .quote(text: "“The way to know the hidden defect of a hadith is to gather its routes together, look at how its narrators differ, and weigh their standing in memory, mastery, and precision.” (al-Khatib al-Baghdadi, related by Ibn as-Salah in ‘Ulum al-Hadith)", arabic: "السَّبِيلُ إِلَى مَعرِفَةِ عِلَّةِ الحَدِيثِ أَن يُجمَعَ بَينَ طُرُقِهِ، وَيُنظَرَ فِي اختِلَافِ رُوَاتِهِ، وَيُعتَبَرَ بِمَكَانِهِم مِنَ الحِفظِ وَمَنزِلَتِهِم فِي الإِتقَانِ وَالضَّبطِ", dimmed: true),
            .text("Ibn as-Salah gives a clear example. The trustworthy Ya‘la ibn ‘Ubayd narrated the hadith of the buyer’s and seller’s option from Sufyan ath-Thawri, from ‘Amr ibn Dinar, from Ibn ‘Umar. Every man in it is trustworthy and every link is connected. But the leading students of Sufyan all narrated it from Sufyan, from ‘Abdullah ibn Dinar, from Ibn ‘Umar. Ya‘la had slipped from one Ibn Dinar to the other:"),
            .versus(ArticleVersus.Side("Ya‘la ibn ‘Ubayd", arabic: "عَمرُو بنُ دِينَارٍ", caption: "Sufyan → **‘Amr** ibn Dinar → Ibn ‘Umar: every narrator trustworthy, and the chain still wrong"), ArticleVersus.Side("Sufyan’s other students", arabic: "عَبدُ اللَّهِ بنُ دِينَارٍ", caption: "Sufyan → **‘Abdullah** ibn Dinar → Ibn ‘Umar: the chain as it really ran"), quranic: false),
            .text("Here the defect lay in the chain alone, and the text itself is sound through the right one: al-Bukhari records it through Sufyan from ‘Abdullah ibn Dinar (Sahih al-Bukhari 2113). The great books of hidden defects, among them the ‘Ilal of Ibn Abi Hatim and that of ad-Daraqutni (d. 385 AH), are made of thousands of such comparisons."),
            .text("A defect can also sit in the text, and a forged report often betrays itself. Ibn as-Salah says fabrication is known by the forger’s own confession or by signs in the narrator or in the report, for long reports have been forged whose poor wording and meaning testify against them. The forgers he calls the most harmful were men with a name for piety who invented reports, as they claimed, for the sake of reward. One of them, Nuh ibn Abi Maryam, admitted forging hadiths on the virtue of each surah of the Quran because he saw people turning away from it. Imam Ahmad, for his part, named sayings that circulated “in the markets” in the Prophet’s name with no basis at all."),
        ]),
        ArticleSection("WHO IS SPEAKING?", [
            .markdown("A report is also classed by whose words it ends with. **Marfu‘ (مَرفُوع)**, “raised,” reaches the Prophet (peace and blessings be upon him): his saying, his action, or his silent approval of what was done in front of him. **Mawquf (مَوقُوف)**, “stopped,” ends with a Companion, like ‘Umar’s words to Abu Musa above. **Maqtu‘ (مَقطُوع)**, “cut off,” ends with a Successor or someone later, like Ibn Sirin’s words above. The last two together are called **athar (أَثَر)**, traces."),
            .markdown("Some mawquf reports count as marfu‘: Ibn Hajar explains that when a Companion who did not take from the People of the Book speaks of the unseen, where opinion has no room, he can only have learned it from the Prophet. And a **hadith qudsi (حَدِيث قُدسِي)** is a marfu‘ hadith in which the Prophet relates from his Lord, like this one, whose Arabic opens “in what he narrated from Allah, Blessed and Exalted”:"),
            .hadith("muslim:2577a", cite: "Sahih Muslim 2577", arabic: 33...60, english: [0...21]),
            .text("A hadith qudsi is graded by the same rules as any other hadith and can be sahih, hasan, or weak. Its meaning is from Allah (Glorified and Exalted be He), but it is not the Quran and is not recited as Quran in the prayer."),
        ]),
        ArticleSection("THE BOOKS OF THE SCIENCE", [
            .text("The rules were practised before they became a subject of their own: ash-Shafi‘i set out the conditions in ar-Risalah, Muslim prefaced his Sahih with an introduction on method, and at-Tirmidhi closed his Jami‘ with a short treatise on hidden defects. Then came the handbooks, whose history Ibn Hajar traced at the start of Nuzhat an-Nazar:"),
            .bullet("**Ar-Ramahurmuzi** (d. 360 AH), **al-Muhaddith al-Fasil**: among the first, though it did not cover everything."),
            .bullet("**Al-Hakim an-Naysaburi** (d. 405 AH), **Ma‘rifat ‘Ulum al-Hadith**: fuller, but not refined or arranged."),
            .bullet("**Al-Khatib al-Baghdadi** (d. 463 AH), **al-Kifayah** on the rules of narration and **al-Jami‘** on its manners; Ibn Nuqtah said the hadith scholars after him all depend on his books."),
            .bullet("**Ibn as-Salah** (d. 643 AH), **‘Ulum al-Hadith**, the “Muqaddimah,” dictated while he taught hadith at the Ashrafiyyah school in Damascus; it gathered what was scattered, and countless scholars versified, abridged, and annotated it."),
            .bullet("**An-Nawawi** (d. 676 AH), **at-Taqrib wat-Taysir**, an abridgement of Ibn as-Salah, with the commentary of as-Suyuti (d. 911 AH), **Tadrib ar-Rawi**."),
            .bullet("**Ibn Hajar al-‘Asqalani** (d. 852 AH), **Nukhbat al-Fikar**, the whole science in a few pages, and his own commentary on it, **Nuzhat an-Nazar**, still among the first texts a student reads."),
        ]),
        ArticleSection("HOW THIS APP GRADES", [
            .text("Every hadith in the Hadith tab carries its grade line under the text, exactly as the graders gave it and with each grader’s name: al-Albani, Ahmad Shakir, Shu‘ayb al-Arna’ut, Zubair Ali Zai, the Darussalam editors, Bashshar ‘Awwad Ma‘ruf, and others. These are the published verdicts that sunnah.com quotes (see Credits in Settings). The line is part of the hadith, not a display option: it always shows, and it travels with every hadith you share."),
            .text("The two Sahihs carry no grade line, because the Ummah received the books of al-Bukhari and Muslim with acceptance. Where graders disagree, the app does not overrule them: a hadith graded sahih by one scholar and da‘if by another shows both verdicts, and the search filters list it under every grade it was given."),
            .text("The articles of this library are stricter. They quote only narrations from the two Sahihs, or narrations that most of the graders on the shelf call sahih or hasan, and every citation names its grader; when graders differ, the majority decides. Weak and fabricated reports are left out, however well known."),
            .callout("A grade is a scholar’s verdict on a chain and a text, reached by the rules on this page. The rules are shared; applying them to a particular narrator is expert judgment, which is why two careful scholars can grade the same report differently. What the rules never allow is accepting a report because it is popular, beautiful, or useful to an argument.", title: "What a Grade Is", icon: "scalemass.fill"),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Is the science of hadith a later invention?**"),
            .text("Its terms are later; its substance is not. The Quran commands verifying a report (Quran 49:6); the Prophet (peace and blessings be upon him) warned against lying about him; ‘Umar asked Abu Musa for a witness; Ibn Sirin’s generation demanded the chain; and ash-Shafi‘i set out their substance before al-Bukhari compiled his Sahih. The handbooks named and ordered a practice that was already there, as the grammarians named the rules of an Arabic the Arabs already spoke."),
            .markdown("**Is a weak hadith a lie?**"),
            .text("No. Da‘if means that the report is not established as the Prophet’s words, because a condition failed, such as a gap in the chain or a narrator with a weak memory; as Ibn as-Salah stresses, that does not declare it false in reality. Mawdu‘ is different: a report shown to be invented, which may not be narrated at all except to expose it. Scholars differed over citing mildly weak reports, with conditions, to encourage deeds already established by sound evidence; this app does not quote them."),
            .markdown("**Why do scholars sometimes grade the same hadith differently?**"),
            .text("Because grading applies shared rules to particular men, and the critics did not always agree about a particular man, or about whether other routes lift a report. Take this hadith:"),
            .hadith("tirmidhi:2260", cite: "Jami` at-Tirmidhi 2260; graded sahih by al-Albani and Ahmad Shakir", arabic: 27...37, english: [0...27]),
            .text("Its chain runs through ‘Umar ibn Shakir, of whom at-Tirmidhi says only that he was a shaykh of Basrah from whom more than one scholar narrated. Ahmad Shakir and al-Albani grade it sahih, the Darussalam editors hasan, and Zubair Ali Zai da‘if. Three of the four accept it, so this library may quote it, and the Hadith tab shows all four verdicts."),
            .markdown("**Did the critics check only the chains and never the text?**"),
            .text("No. Freedom from irregularity and from hidden defects is tested on the text as much as on the chain, and the forgeries above were caught through their texts as well as their narrators. What the critics refused was to reject an authentic report merely because it seemed strange to someone: a text was judged by evidence, not by taste."),
            .markdown("**Why do some people reject the hadith altogether, and what is the answer?**"),
            .text("Their arguments, and the answers of the scholars, have a page of their own:"),
            .door(.article("HadithRejectorsView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The sciences of hadith turn one command of the Quran, verify the report, into a discipline: know every narrator, demand a connected chain of upright and precise men, test each report against every other route of it, and grade it honestly from sahih down to mawdu‘. Because of that discipline, a Muslim today can still tell the words of the Prophet (peace and blessings be upon him) from words falsely put in his mouth."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Mustalah al-Hadith", arabic: "مُصطَلَح الحَدِيث", meaning: "“The terminology of hadith”: the technical terms of the field and, by extension, the whole science of grading reports, also called **‘ulum al-hadith**, the sciences of hadith."),
            .term("Isnad and Sanad", arabic: "إِسنَاد، سَنَد", meaning: "From the root **س-ن-د**, to lean on: the chain of narrators a report rests on. Sanad is the chain itself; isnad is also the act of tracing a report back through it."),
            .term("Matn", arabic: "مَتن", meaning: "The text that the chain carries: the saying, action, or approval reported. Literally the firm, raised back of the ground, the substance the chain delivers."),
            .term("Rawi", arabic: "رَاوٍ", meaning: "A narrator, one who relays a report (**riwayah**); plural **ruwat**. Every rawi in a chain is weighed on his own."),
            .term("‘Adalah", arabic: "عَدَالَة", meaning: "Uprightness: a Muslim, adult and sane, free of open sin and of what breaks decency. It is the moral half of a narrator’s reliability."),
            .term("Dabt", arabic: "ضَبط", meaning: "Precision: keeping exactly what was heard, in the memory (**dabt as-sadr**) or in a carefully guarded book (**dabt al-kitab**). It is the other half."),
            .term("Muttasil", arabic: "مُتَّصِل", meaning: "Connected: a chain in which every narrator heard from the one before him. A chain with a gap is **munqati‘**, broken."),
            .term("Shadh", arabic: "شَاذّ", meaning: "Irregular: a report in which a reliable narrator contradicts those more reliable than him, as ash-Shafi‘i defined it."),
            .term("‘Illah", arabic: "عِلَّة", meaning: "A hidden defect that damages a report which looks sound, found only by gathering and comparing all its routes. A report with one is **mu‘allal**."),
            .term("Marfu‘", arabic: "مَرفُوع", meaning: "“Raised”: a report that reaches the Prophet ﷺ, his words, his action, or his approval."),
            .term("Mawquf", arabic: "مَوقُوف", meaning: "“Stopped”: a report that ends with a Companion, his own words or deed."),
            .term("Maqtu‘", arabic: "مَقطُوع", meaning: "“Cut off”: a report that ends with a Successor or someone later. Not to be confused with **munqati‘**, a broken chain."),
            .term("Mutawatir", arabic: "مُتَوَاتِر", meaning: "Mass-transmitted: carried at every level by so many that a shared lie is impossible, so that it yields certain knowledge."),
            .term("Ahad", arabic: "آحَاد", meaning: "Every report short of mutawatir, from the singular (**gharib**) to the widely known (**mashhur**). A count of narrators, not a weakness."),
            .term("Al-Jarh wat-Ta‘dil", arabic: "الجَرح وَالتَّعدِيل", meaning: "“Wounding and declaring upright”: the critics’ verdicts on narrators, from **thiqah** down to **kadhdhab**."),
        ]),
    ]
}

/// How the hadith were preserved: writing in the Prophet's lifetime and the early instruction not to
/// write, the Companions' memory and teaching, travel for a single hadith, the first official
/// collection under 'Umar ibn 'Abd al-'Aziz, the early books that survive (the Sahifah of Hammam), the
/// six books, al-Bukhari's method, and the answer to “written down two hundred years later”.
/// Second of the HADITH & ITS SCIENCES group, beside The Sciences of Hadith.
struct HadithPreservationView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithPreservationView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("How the Hadith Were Preserved")
        .selectableArticleList(article: "HadithPreservationView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the hadith were not first written down two centuries after the Prophet (peace and blessings be upon him). His Companions memorized them, and some wrote them down in his lifetime; their students kept written collections; a caliph ordered them gathered around the year 100 AH; and the great books of the third century drew on all of this, naming at every step the men who handed each report on."),
        ]),
        ArticleSection("WRITTEN IN HIS LIFETIME", [
            .text("Some of the Sunnah was written down in the lifetime of the Prophet (peace and blessings be upon him) himself. Abu Hurayrah (may Allah be pleased with him), the Companion with the most hadith in the collections, said:"),
            .hadith("bukhari:113", cite: "Sahih al-Bukhari 113", arabic: 19...48, english: [0...33]),
            .text("Ibn Hajar explains that far more of Abu Hurayrah’s hadith spread in the end, because he gave himself to teaching in Madinah. Al-Bukhari received these words through Wahb ibn Munabbih from his brother Hammam, who heard them from Abu Hurayrah: the same Hammam whose own written collection from Abu Hurayrah survives, as we will see. ‘Abdullah ibn ‘Amr ibn al-‘As (may Allah be pleased with them both) told how he came to keep writing:"),
            .hadith("abudawud:3646", cite: "Sunan Abi Dawud 3646; graded sahih by al-Albani", arabic: 33...91, english: [0...88]),
            .text("The Prophet had words written down for others too. When he gave a sermon at the conquest of Makkah, in 8 AH, a man from Yemen asked to have it in writing:"),
            .hadith("bukhari:2434", cite: "Sahih al-Bukhari 2434", arabic: 124...171, english: [142...195]),
            .markdown("‘Ali ibn Abi Talib (may Allah be pleased with him) kept a written **sahifah (صَحِيفَة)**, a sheet, of rulings from the Prophet; in another narration he says that, apart from the Quran, this sheet was all they had written down from the Prophet (Sahih al-Bukhari 3179):"),
            .hadith("bukhari:111", cite: "Sahih al-Bukhari 111", arabic: 17...50, english: [0...120]),
            .text("The state itself ran on the written word. The Prophet sent letters to kings, and al-Bukhari preserves the text of the one to Heraclius, the Byzantine emperor, as Heraclius read it with Abu Sufyan standing before him:"),
            .hadith("bukhari:7", cite: "Sahih al-Bukhari 7", arabic: 485...510, english: [919...970]),
            .text("And when Abu Bakr sent Anas ibn Malik (may Allah be pleased with them both) to collect the zakah of Bahrain, he gave him the Prophet’s schedule of zakah in writing. The document came down to al-Bukhari through Anas’s own family: his grandson Thumamah, then his great-grandson ‘Abdullah ibn al-Muthanna, then ‘Abdullah’s son Muhammad, al-Bukhari’s teacher."),
            .hadith("bukhari:1454", cite: "Sahih al-Bukhari 1454", arabic: 22...61, english: [0...52]),
        ]),
        ArticleSection("THE INSTRUCTION NOT TO WRITE", [
            .text("There is also an authentic instruction in the other direction. Abu Sa‘id al-Khudri (may Allah be pleased with him) narrated that the Prophet (peace and blessings be upon him) said:"),
            .hadith("muslim:3004", cite: "Sahih Muslim 3004", arabic: 29...55, english: [0...58]),
            .text("Two things stand out in the hadith itself. It forbids writing but in the same breath commands narrating, so it was never a ban on passing the Sunnah on. And one of its narrators, Hammam ibn Yahya (not the Hammam of the Sahifah below), marks his own doubt over a single word, “deliberately”: exactly the precision the critics demanded."),
            .markdown("In **Fath al-Bari**, Ibn Hajar sets out how the scholars reconciled the two sets of reports:"),
            .bullet("The ban belonged to the time when the Quran was being revealed, for fear that other words would be confused with it, and the permission came once that danger had passed. Ibn Hajar calls this the closest view; the permission for Abu Shah came late, at the conquest of Makkah."),
            .bullet("The ban was on writing hadith together with the Quran on the same sheet."),
            .bullet("The ban was for those who might come to rely on writing and neglect memory; the permission was for those safe from that."),
            .bullet("Some critics, al-Bukhari among them, held that these words are Abu Sa‘id’s own rather than the Prophet’s."),
            .text("Some Companions and Successors did prefer that hadith be memorized rather than written. Ibn as-Salah names ‘Umar, Ibn Mas‘ud, Zayd ibn Thabit, Abu Musa and Abu Sa‘id among those who disliked writing, and ‘Ali, his son al-Hasan, Anas, Ibn ‘Umar and ‘Abdullah ibn ‘Amr among those who wrote or allowed it. The question was settled long before the great books:"),
            .quote(text: "“Then that disagreement ended, and the Muslims agreed unanimously that writing it is allowed and permitted; had it not been recorded in books, it would have been effaced in later ages.” (Ibn as-Salah, ‘Ulum al-Hadith)", arabic: "ثُمَّ إِنَّهُ زَالَ ذَلِكَ الخِلَافُ، وَأَجمَعَ المُسلِمُونَ عَلَى تَسوِيغِ ذَلِكَ وَإِبَاحَتِهِ، وَلَولَا تَدوِينُهُ فِي الكُتُبِ لَدَرَسَ فِي الأَعصُرِ الآخِرَةِ", dimmed: true),
        ]),
        ArticleSection("MEMORY AND TEACHING", [
            .text("Writing was the smaller part of the story. The Companions came from a culture that carried its poetry and its genealogies by heart, and the Prophet (peace and blessings be upon him) spoke in a way meant to be remembered. ‘A’ishah (may Allah be pleased with her) said:"),
            .hadith("bukhari:3567", cite: "Sahih al-Bukhari 3567", arabic: 17...29, english: [0...22]),
            .text("Anas (may Allah be pleased with him) said:"),
            .hadith("bukhari:95", cite: "Sahih al-Bukhari 95", arabic: 28...37, english: [0...25]),
            .text("He made passing on what they heard a duty. On the Day of Sacrifice in his Farewell Pilgrimage, he said:"),
            .hadith("bukhari:67", cite: "Sahih al-Bukhari 67", arabic: 95...107, english: [118...147]),
            .text("And he prayed for the one who carries a hadith exactly as he heard it:"),
            .hadith("tirmidhi:2657", cite: "Jami` at-Tirmidhi 2657; graded sahih by al-Albani", arabic: 27...49, english: [13...54]),
            .text("At-Tirmidhi graded it hasan sahih in his own book, and in the row before it he records the same prayer from Zayd ibn Thabit and names Mu‘adh ibn Jabal, Jubayr ibn Mut‘im, Abu ad-Darda’ and Anas as narrating it too (Jami‘ at-Tirmidhi 2656). The Companions took the duty to heart. Abu Hurayrah, who came to the Prophet only in the year of Khaybar, said:"),
            .hadith("bukhari:3591", cite: "Sahih al-Bukhari 3591", arabic: 22...41, english: [0...35]),
            .text("When people said that he narrated too much, he answered:"),
            .hadith("bukhari:118", cite: "Sahih al-Bukhari 118", arabic: 44...81, english: [55...126]),
            .text("How the critics later tested every narrator’s memory, and his book, is the subject of its own page:"),
            .door(.article("HadithSciencesView")),
        ]),
        ArticleSection("TRAVELLING FOR ONE HADITH", [
            .text("A hadith heard in one city was worth a journey to hear it from its source in another. Al-Bukhari opens the chapter on going out in search of knowledge, in his Book of Knowledge, with this report:"),
            .quote(text: "“Jabir ibn ‘Abdullah travelled a month’s journey to ‘Abdullah ibn Unays for a single hadith.” (al-Bukhari, Sahih al-Bukhari, the Book of Knowledge, chapter on going out in search of knowledge)", arabic: "وَرَحَلَ جَابِرُ بنُ عَبدِ اللَّهِ مَسِيرَةَ شَهرٍ إِلَى عَبدِ اللَّهِ بنِ أُنَيسٍ فِي حَدِيثٍ وَاحِدٍ", dimmed: true),
            .markdown("A report cited like this at the head of a chapter, without its chain, is called a **ta‘liq (تَعلِيق)**. It is not one of al-Bukhari’s numbered, connected hadiths but a statement in his own voice. The connected hadith of that chapter is the story of Musa (peace be upon him) setting out to learn from al-Khidr (Sahih al-Bukhari 78), the journey the Quran tells:"),
            .ayah("18:66"),
            .text("Jabir (may Allah be pleased with him) had heard the Prophet (peace and blessings be upon him) himself, yet he travelled a month to hear one more hadith from the Companion who had heard it. The journey in search of hadith, the rihlah, became the mark of a serious scholar in the centuries that followed."),
        ]),
        ArticleSection("THE FIRST OFFICIAL COLLECTION", [
            .text("By the end of the first century most of the Companions had died. ‘Umar ibn ‘Abd al-‘Aziz, the caliph (d. 101 AH) whom the scholars counted with the rightly guided caliphs, and whose mother was a granddaughter of ‘Umar ibn al-Khattab (may Allah be pleased with him), wrote to Abu Bakr ibn Hazm, the judge of Madinah:"),
            .quote(text: "“Look for whatever there is of the hadith of the Messenger of Allah (peace and blessings be upon him) and write it down, for I fear that knowledge will fade away and the scholars will pass on. Accept nothing but the hadith of the Prophet. Let knowledge be spread, and let people sit together so that whoever does not know is taught, for knowledge does not perish until it becomes a secret.” (‘Umar ibn ‘Abd al-‘Aziz to Abu Bakr ibn Hazm, in Sahih al-Bukhari, the Book of Knowledge)", arabic: "انظُر مَا كَانَ مِن حَدِيثِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ فَاكتُبهُ، فَإِنِّي خِفتُ دُرُوسَ العِلمِ وَذَهَابَ العُلَمَاءِ، وَلَا تَقبَل إِلَّا حَدِيثَ النَّبِيِّ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، وَلتُفشُوا العِلمَ، وَلتَجلِسُوا حَتَّى يُعَلَّمَ مَن لَا يَعلَمُ، فَإِنَّ العِلمَ لَا يَهلِكُ حَتَّى يَكُونَ سِرًّا", dimmed: true),
            .text("Al-Bukhari places this letter at the head of the chapter “How Knowledge Is Taken Away” and gives his own chain for its first half, through ‘Abdullah ibn Dinar. The hadith he sets under it names the danger the caliph feared:"),
            .hadith("bukhari:100", cite: "Sahih al-Bukhari 100", arabic: 32...60, english: [6...71]),
            .text("Ibn Hajar sums up how the scholars describe the change:"),
            .quote(text: "“A group of the Companions and the Successors disliked writing hadith and preferred that it be taken from them by memory, as they had taken it by memory. But when resolve weakened and the imams feared that knowledge would be lost, they recorded it. The first to record hadith was Ibn Shihab az-Zuhri, at the turn of the first century, by order of ‘Umar ibn ‘Abd al-‘Aziz; then recording spread, then the writing of books, and much good came of it.” (Ibn Hajar, Fath al-Bari, on the chapter on writing down knowledge)", arabic: "كَرِهَ جَمَاعَةٌ مِنَ الصَّحَابَةِ وَالتَّابِعِينَ كِتَابَةَ الحَدِيثِ، وَاستَحَبُّوا أَن يُؤخَذَ عَنهُم حِفظًا كَمَا أَخَذُوا حِفظًا، لَكِن لَمَّا قَصُرَتِ الهِمَمُ وَخَشِيَ الأَئِمَّةُ ضَيَاعَ العِلمِ دَوَّنُوهُ، وَأَوَّلُ مَن دَوَّنَ الحَدِيثَ ابنُ شِهَابٍ الزُّهرِيُّ عَلَى رَأسِ المِائَةِ بِأَمرِ عُمَرَ بنِ عَبدِ العَزِيزِ، ثُمَّ كَثُرَ التَّدوِينُ ثُمَّ التَّصنِيفُ، وَحَصَلَ بِذَلِكَ خَيرٌ كَثِيرٌ", dimmed: true),
            .text("Az-Zuhri of Madinah (d. 124 AH) was the teacher of Malik, whose book is the next part of the story."),
        ]),
        ArticleSection("THE EARLY BOOKS THAT SURVIVE", [
            .markdown("Several collections from before the famous six still exist and can be set beside them. Among the oldest is the **Sahifah of Hammam ibn Munabbih (صَحِيفَة هَمَّام بن مُنَبِّه)**, 138 hadiths in Muhammad Hamidullah’s edition, which Hammam, a Successor of San‘a in Yemen, wrote down from Abu Hurayrah. Hamidullah published it in the 1950s from two manuscript copies, one in Damascus and one in Berlin. The same collection reached Imam Muslim through a line of teachers, and he quotes it under Hammam’s own heading, which introduces a written collection and then picks out one hadith from it:"),
            .hadith("muslim:225", cite: "Sahih Muslim 225", arabic: 13...55, english: [0...52]),
            .chain([
                ArticleChainLink("Muslim", "d. 261 AH, the collector"),
                ArticleChainLink("Muhammad ibn Rafi‘", "d. 245 AH, of Nishapur"),
                ArticleChainLink("‘Abd ar-Razzaq as-San‘ani", "d. 211 AH, author of the Musannaf"),
                ArticleChainLink("Ma‘mar ibn Rashid", "d. 154 AH, of Basrah, settled in Yemen"),
                ArticleChainLink("Hammam ibn Munabbih", "d. 132 AH, who wrote the Sahifah"),
                ArticleChainLink("Abu Hurayrah", "d. 57–59 AH, the Companion"),
                ArticleChainLink("The Prophet ﷺ", ""),
            ], caption: "How the Sahifah of Hammam reached Sahih Muslim 225, with death dates from Ibn Hajar’s Taqrib at-Tahdhib"),
            .text("On this app’s shelf alone, Hammam’s chain runs through 79 rows of Sahih Muslim and 22 of Sahih al-Bukhari, which receives it from Ma‘mar through more than one student, among them ‘Abd ar-Razzaq and ‘Abdullah ibn al-Mubarak (for example, Sahih al-Bukhari 2073 and 3124). A booklet written by a Companion’s student in the first century, copied as a book of its own, and quoted through the same chain by the great collectors of the third: that is not a two-century silence."),
            .markdown("The second century produced books that survive whole. **Al-Muwatta’ (المُوَطَّأ)** of Malik ibn Anas of Madinah (93–179 AH) gathered the hadith and the practice of Madinah; al-Bukhari called “Malik from Nafi‘ from Ibn ‘Umar” the soundest of all chains, and ash-Shafi‘i said of the Muwatta’, before the two Sahihs existed:"),
            .quote(text: "“I know of no book of knowledge on earth that is more often right than the book of Malik.” (ash-Shafi‘i, related by Ibn as-Salah, who notes he said it before the books of al-Bukhari and Muslim existed)", arabic: "مَا أَعلَمُ فِي الأَرضِ كِتَابًا فِي العِلمِ أَكثَرَ صَوَابًا مِن كِتَابِ مَالِكٍ", dimmed: true),
            .markdown("Then came the great collections of the early third century: the **Musannaf** of ‘Abd ar-Razzaq of San‘a (d. 211 AH), which also preserves the older **Jami‘** of his teacher Ma‘mar ibn Rashid; the **Musannaf** of Ibn Abi Shaybah (d. 235 AH); the **Musnad** of al-Humaydi (d. 219 AH), al-Bukhari’s teacher; and the vast **Musnad** of Ahmad ibn Hanbal (d. 241 AH). All of them are in print today, and the compilers of the six books narrate from these men or from their students."),
        ]),
        ArticleSection("THE SIX BOOKS", [
            .text("The third century produced the collections Muslims still turn to first. Their compilers gathered what the earlier books and their own teachers held, sifted it by the rules of the science, and arranged it for use. Six became the core of the shelf:"),
            .bullet("**Sahih al-Bukhari**, by Muhammad ibn Isma‘il al-Bukhari (d. 256 AH)"),
            .bullet("**Sahih Muslim**, by Muslim ibn al-Hajjaj of Nishapur (d. 261 AH)"),
            .bullet("**Sunan Abi Dawud**, by Sulayman ibn al-Ash‘ath as-Sijistani (d. 275 AH)"),
            .bullet("**Jami‘ at-Tirmidhi**, by Muhammad ibn ‘Isa at-Tirmidhi (d. 279 AH)"),
            .bullet("**Sunan an-Nasa’i**, by Ahmad ibn Shu‘ayb an-Nasa’i (d. 303 AH)"),
            .bullet("**Sunan Ibn Majah**, by Muhammad ibn Yazid ibn Majah of Qazwin (d. 273 AH)"),
            .text("Only the first two set out to include nothing but sahih hadith. The four Sunan gathered the hadith that jurists use, sound and weaker together, and their authors often said which was which; at-Tirmidhi, as we saw, graded most of his hadith himself. That is why the Sunan carry the graders’ verdicts on this app’s shelf and the two Sahihs do not. Counts of al-Bukhari’s book differ because they count different things:"),
            .stats([
                ArticleStat("7,563", "numbered narrations in Sahih al-Bukhari, in the numbering this app uses"),
                ArticleStat("9,082", "all its Prophetic reports, repeats and chapter-heading reports included, by Ibn Hajar’s count"),
                ArticleStat("7,397", "its connected hadiths counting repeats, by Ibn Hajar’s count"),
                ArticleStat("2,602", "its distinct connected hadiths without repeats, by Ibn Hajar’s count"),
            ]),
        ]),
        ArticleSection("AL-BUKHARI'S METHOD", [
            .markdown("Al-Bukhari named his book **al-Jami‘ al-Musnad as-Sahih al-Mukhtasar min Umur Rasul Allah wa Sunanihi wa Ayyamihi**, “the comprehensive, connected, authentic abridgement of the affairs of the Messenger of Allah (peace and blessings be upon him), his Sunnah, and his days.” Every word is a promise: comprehensive of every subject, connected in its chains, authentic, and abridged, because he never claimed to include every sahih hadith. Ibn as-Salah relates that he said:"),
            .quote(text: "“I included in my book al-Jami‘ only what was sahih, and I left out other sahih hadith to avoid tedious length.” (al-Bukhari, related by Ibn as-Salah in ‘Ulum al-Hadith)", arabic: "مَا أَدخَلتُ فِي كِتَابِي الجَامِعِ إِلَّا مَا صَحَّ، وَتَرَكتُ مِنَ الصِّحَاحِ لِمَلَالِ الطُّولِ", dimmed: true),
            .markdown("His condition for a connected chain was stricter than Muslim’s. Ibn Hajar explains that al-Bukhari required proof that each narrator had **met** the one he narrated from, at least once, while Muslim accepted two trustworthy narrators who lived at the same time and could have met, provided the narrator was not known to conceal his sources. Al-Bukhari studied under masters of the field such as ‘Ali ibn al-Madini and Ahmad ibn Hanbal, and he taught Muslim; ad-Daraqutni said that were it not for al-Bukhari, Muslim would neither have come nor gone."),
            .text("The limits are just as well known, because the scholars recorded them. Reports that al-Bukhari cites without a chain at the head of a chapter, like Jabir’s journey above, are not part of his condition, as Ibn as-Salah points out. And Ibn Hajar lists 110 of al-Bukhari’s connected hadiths that ad-Daraqutni and other critics questioned, answers them one by one, and notes that most of the objections do not touch the substance of the book, while conceding that a few answers are not convincing. The criticism is not hidden; it is part of the literature."),
        ]),
        ArticleSection("TWO HUNDRED YEARS LATER?", [
            .text("A common claim is that the hadith were first written down two hundred years after the Prophet (peace and blessings be upon him), so that no one can know what he really said. The claim confuses the date of the most famous books with the date the hadith were first recorded. Set out in order, the record looks like this:"),
            .step("1. **In his lifetime (to 11 AH):** ‘Abdullah ibn ‘Amr writes what he hears, with the Prophet’s permission; a sermon is written down for Abu Shah; ‘Ali keeps a written sheet; letters go out to kings."),
            .step("2. **The next half century (11–60 AH):** Abu Bakr puts the zakah schedule in writing for Anas; Hammam ibn Munabbih writes his Sahifah from Abu Hurayrah, who died around 58 AH."),
            .step("3. **Around 100 AH:** ‘Umar ibn ‘Abd al-‘Aziz orders the hadith gathered in writing, and az-Zuhri records them by his order."),
            .step("4. **The second century:** Ma‘mar ibn Rashid (d. 154 AH) compiles his Jami‘ and Malik (d. 179 AH) his Muwatta’, both still extant."),
            .step("5. **The early third century:** ‘Abd ar-Razzaq, Ibn Abi Shaybah, al-Humaydi and Ahmad compile their Musannafs and Musnads."),
            .step("6. **The later third century (compilers d. 256–303 AH):** the six books, drawing on these written sources and on living teachers, with the chain of every report written out."),
            .text("At no point is there a gap of two centuries: each generation wrote and taught from the one before it, and the great books name their sources. The Sahifah of Hammam shows a Companion’s student writing in the first century and Muslim quoting the same collection, through the same chain, in the third. Al-Humaydi’s Musnad shows al-Bukhari’s own teacher recording, through the same chain, the hadith that al-Bukhari placed first in his book (Musnad al-Humaydi 28)."),
            .callout("A hadith’s age is not measured from the book it appears in. It is measured from its chain, which names who heard it from whom at every step, and those names can be checked: their dates, their teachers, their students, and what others narrated from the same teachers. A late book with a sound chain is the record of an early report.", title: "The Key Idea", icon: "lightbulb.fill"),
            .text("Western scholarship has moved in the same direction. The German Islamicist Harald Motzki, studying the Musannaf of ‘Abd ar-Razzaq, argued that its material from Ibn Jurayj and his teacher ‘Ata’ ibn Abi Rabah is genuine and reaches back into the first century of Islam, in an article titled “The Musannaf of ‘Abd al-Razzaq al-San‘ani as a Source of Authentic Ahadith of the First Century A.H.” (Journal of Near Eastern Studies, 1991). The arguments of those who reject the hadith altogether, and the answers to them, have their own page:"),
            .door(.article("HadithRejectorsView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Were the hadith preserved the same way as the Quran?**"),
            .text("No, and the difference matters. The Quran was written down by scribes as it was revealed, gathered into one volume under Abu Bakr, copied into the official mushafs under ‘Uthman, and recited by mass transmission, word for word, ever since, as Allah (Glorified and Exalted be He) promised:"),
            .ayah("15:9"),
            .text("The hadith were preserved report by report, many of them through a few narrators and some in more than one wording, which is exactly why the Muslims needed a science to grade them. The Quran is kept word for word; the Sunnah is kept by the scholars’ sifting of every report, so that what is authentic is known from what is not. The parallel story of the Quran has its own page:"),
            .door(.article("CompileView")),
            .markdown("**Did narrators change the wording?**"),
            .text("Some conveyed the meaning in their own words, which the scholars allowed only to one who knew Arabic well and knew what alters a meaning; ash-Shafi‘i made that knowledge a condition of accepting a report. Others, like Muhammad ibn Sirin, would narrate only the exact words. The collectors did not hide the differences: Muslim notes, for example, which of two chains gives the fuller wording (Sahih Muslim 2577), and the critics compared wordings precisely in order to catch errors. That is why the variants are known at all."),
            .markdown("**How do we know the chains were not invented along with the hadith?**"),
            .text("Because chains can be checked against one another. A forger can invent one chain, but not the whole network: the same hadith reaching the collectors through different students in different cities, the students of one teacher agreeing on his wording, the early books agreeing with the later ones, and a written Sahifah surviving on its own beside the books that quote it. The critics built their science on these comparisons, which is how they exposed the forgers who did try."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The hadith came down along two roads at once, memory and writing. Companions wrote in the lifetime of the Prophet (peace and blessings be upon him), their students kept written collections, a caliph ordered the whole gathered around 100 AH, and the great books of the third century recorded every report with the names of the men who carried it. The two centuries before al-Bukhari were not a silence; they were two centuries of teaching, writing, and checking."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Sahifah", arabic: "صَحِيفَة", meaning: "A written sheet or booklet of hadith kept by a Companion or a Successor, like the sahifah of ‘Ali or the Sahifah of Hammam ibn Munabbih; plural **suhuf**."),
            .term("Kitabah and Tadwin", arabic: "كِتَابَة، تَدوِين", meaning: "**Kitabah** is writing hadith down, which began in the lifetime of the Prophet ﷺ; **tadwin** is recording it systematically in collections, which began by official order around 100 AH."),
            .term("Rihlah", arabic: "رِحلَة", meaning: "The journey in search of hadith, to hear a report from the one who heard it, as Jabir travelled a month to ‘Abdullah ibn Unays."),
            .term("Ta‘liq", arabic: "تَعلِيق", meaning: "A report cited with the start of its chain left out, as al-Bukhari does at the heads of his chapters. Such a report is called **mu‘allaq** and is not part of his condition."),
            .term("Musnad", arabic: "مُسنَد", meaning: "A collection arranged by Companion, each Companion’s hadiths together, like the Musnad of Ahmad; also a hadith whose chain is connected to the Prophet ﷺ."),
            .term("Musannaf", arabic: "مُصَنَّف", meaning: "A collection arranged by subject that sets the sayings of the Companions and Successors beside the Prophet’s hadith, like those of ‘Abd ar-Razzaq and Ibn Abi Shaybah."),
            .term("Sunan", arabic: "سُنَن", meaning: "A collection arranged by the chapters of law, concentrating on the Prophet’s own hadith, like the Sunan of Abu Dawud, an-Nasa’i, and Ibn Majah."),
            .term("Jami‘", arabic: "جَامِع", meaning: "A collection that covers every subject, from belief and law to manners, commentary on the Quran, and history, like the Jami‘ of al-Bukhari and of at-Tirmidhi."),
        ]),
    ]
}

struct HadithRejectorsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HadithRejectorsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Answering the Hadith Rejectors")
        .selectableArticleList(article: "HadithRejectorsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran-only claim fails on the Quran’s own terms. The Quran commands obedience to the Messenger (peace and blessings be upon him) in its own right, calls his teaching the Wisdom, and names revelation to him that its text does not contain; its prayer cannot be prayed from its pages alone, and it reached us through the same transmission the Quranists reject."),
        ]),
        ArticleSection("WHO THE QURANISTS ARE", [
            .markdown("**Quranists (قُرآنِيُّون)**, who often call themselves **Ahl al-Quran (أَهل القُرآن)**, hold that the Quran is the only source of the religion. Some reject every hadith; some accept one only when it agrees with the Quran as they read it; some say the Prophet (peace and blessings be upon him) was obeyed in his lifetime but the records of his Sunnah cannot be trusted. What unites them is that his words and practice, as the Muslims handed them down, carry no authority of their own."),
            .text("Many come to it sincerely, out of love for the Quran and dismay at weak narrations passed around carelessly. But the cure for a false report is the science that exposes it, not the discarding of true ones, and the claim is best answered from the Quran, the ground its holders have chosen."),
            .text("The argument is old. Imam ash-Shafi‘i (d. 204 AH) recorded in Jima‘ al-‘Ilm his debate with a learned man who rejected every report from the Prophet, citing the verse that calls the Quran a clarification of all things (Quran 16:89). Ash-Shafi‘i answered him from the Quran until he admitted his error, and the man then told him where the view had led others: to holding that the least that can be called a prayer, even two rak‘ahs a day, fulfils the duty."),
            .text("In British India ‘Abdullah Chakralawi (d. 1916), who had begun among the Ahl al-Hadith, declared in Lahore in 1901 that the Quran alone binds. Challenged to show from it the number of prayers and rak‘ahs, he wrote a book of “Quranic prayer” that took the rak‘ahs from the verse on angels with wings, two, three and four (Quran 35:1), while another Quran-only writer held that the Quran commands two prayers a day of two rak‘ahs each."),
            .text("In Egypt Muhammad Tawfiq Sidqi argued in al-Manar in 1906 that Islam is the Quran alone, and later withdrew the claim. In Pakistan Ghulam Ahmed Parwez (1903–1985), of the Tolu-e-Islam movement, recast the prayer as a social order and zakah as a state levy at a variable rate. In the United States Rashad Khalifa (1935–1990) claimed a code of nineteen in the Quran, called the hadith satanic innovations, dropped at-Tawbah 9:128–129 from his translation because they spoiled his count, and in the late 1980s proclaimed himself God’s “Messenger of the Covenant”."),
        ]),
        ArticleSection("THE PROPHET FORETOLD IT", [
            .text("Abu Rafi‘ (may Allah be pleased with him) reported that the Prophet (peace and blessings be upon him) said:"),
            .hadith("abudawud:4605", cite: "Sunan Abi Dawud 4605; graded sahih by al-Albani", arabic: 34...58, english: [4...41]),
            .text("Al-Miqdam ibn Ma‘dikarib (may Allah be pleased with him) reported the same warning, adding that what the Messenger of Allah has forbidden is like what Allah (Glorified and Exalted be He) has forbidden (Jami‘ at-Tirmidhi 2664). The man described does not mock the Quran. He praises it, and uses the praise to turn away whatever reaches him from the Prophet."),
            .door(.prophecy("quran-only")),
        ]),
        ArticleSection("THE QURAN COMMANDS OBEYING THE MESSENGER", [
            .text("The first answer is the Quran itself. Allah (Glorified and Exalted be He) commands obedience to His Messenger (peace and blessings be upon him) again and again, and in the verse that settles disputes He gives the command twice:"),
            .ayah("4:59", words: 3...9),
            .text("Ibn al-Qayyim (may Allah have mercy on him) noted that the verb is repeated for the Messenger but not for those in authority, and explained why:"),
            .quote(text: "“He repeated the verb to make known that obedience to the Messenger is obligatory in its own right, without first measuring what he commands against the Book. When he commands, he is to be obeyed absolutely, whether what he commands is in the Book or not, for he was given the Book and its like with it.” (Ibn al-Qayyim, I‘lam al-Muwaqqi‘in)", arabic: "وأعاد الفعل إعلاما بأن طاعة الرسول تجب استقلالا من غير عرض ما أمر به على الكتاب بل إذا أمر وجبت طاعته مطلقا سواء كان ما أمر به في الكتاب أو لم يكن فيه فإنه أوتي الكتاب ومثله معه", dimmed: true),
            .text("The same Book makes following him the proof of loving Allah:"),
            .ayah("3:31-32", words: 0...5),
            .text("Obeying him is obeying Allah (Quran 4:80), and Allah sent no messenger except to be obeyed (Quran 4:64). Faith depends on accepting his judgment without resentment (Quran 4:65); once Allah and His Messenger have decided, a believer has no choice left (Quran 33:36); and the Quran speaks of what Allah and His Messenger have made unlawful (Quran 9:29). Some reply that his only duty was to deliver the message, but the verse they cite says more:"),
            .ayah("24:54", words: 0...16),
            .text("It commands obedience to him and promises guidance to those who obey: delivering was his duty, and obeying is ours. Nor did the duty end with his life. The verse that sends every dispute back to Allah and the Messenger binds every generation, and after his death that can only mean his Sunnah, as ash-Shafi‘i put it to the man who rejected all reports:"),
            .quote(text: "“Do you find any way for you, or for anyone before or after you who did not see the Messenger of Allah (peace and blessings be upon him), to carry out the obligation Allah laid down of following his commands, except through the report from the Messenger of Allah?” (ash-Shafi‘i, Jima‘ al-‘Ilm)", arabic: "فهل تجد السبيل إلى تأدية فرض الله عز وجل في اتباع أوامر رسول الله ﷺ أو أحد قبلك أو بعدك ممن لم يشاهد رسول الله ﷺ إلا بالخبر عن رسول الله ﷺ", dimmed: true),
        ]),
        ArticleSection("THE BOOK AND THE WISDOM", [
            .text("The Quran also names the work of the Prophet (peace and blessings be upon him). Allah (Glorified and Exalted be He) sent the Reminder down to him to make it clear:"),
            .ayah("16:44", words: 2...9),
            .text("The verse separates what was sent down to the people from his making it clear to them; if the text explained itself in every detail, the second would have nothing to do (see also Quran 16:64). And again and again the Quran says he teaches the Book and the Wisdom (Quran 2:129, 2:151, 3:164):"),
            .ayah("62:2", words: 7...13),
            .text("The Wisdom is taught beside the Book and was sent down beside it (Quran 4:113, 2:231), and the Prophet’s wives are told to remember both, recited in their homes:"),
            .ayah("33:34", words: 0...8),
            .text("Ash-Shafi‘i reported in ar-Risalah that the scholars of the Quran he trusted said the Wisdom is the Sunnah, since it is paired with the Book and Allah made obedience to His Messenger binding. When he recited this verse to the man who rejected reports, the man conceded that it showed the Wisdom to be something other than the Quran (Jima‘ al-‘Ilm). The Prophet said the same of himself: he was given the Quran and something like it along with it (Sunan Abi Dawud 4604)."),
            .text("The Sunnah is no rival to the Book. Imam Ahmad would not say that it rules over the Book; he said it explains the Book and makes it clear (Ibn ‘Abd al-Barr, Jami‘ Bayan al-‘Ilm)."),
        ]),
        ArticleSection("REVELATION OUTSIDE THE RECITED TEXT", [
            .text("The Quran goes further: it shows the Prophet (peace and blessings be upon him) acting on instructions from Allah (Glorified and Exalted be He) that appear nowhere in its text, and it calls them Allah’s."),
            .markdown("**The first qiblah.** For sixteen or seventeen months in Madinah the Muslims prayed toward Jerusalem (Sahih al-Bukhari 40), though no verse commands it. When the qiblah changed, Allah said:"),
            .ayah("2:143", words: 12...26),
            .text("Allah calls the old direction a qiblah He appointed; Ibn Kathir explains that Allah first legislated facing Bayt al-Maqdis, then turned the Muslims to the Ka‘bah. That first command came through no recited verse."),
            .markdown("**The secret that was passed on.** The Prophet confided something to one of his wives, and she told another:"),
            .ayah("66:3", words: 18...28),
            .text("Allah’s informing him was revelation, and its words are not in the Quran."),
            .markdown("**The promise at Badr.** Surat al-Anfal was revealed about Badr (Sahih al-Bukhari 4645), and it recalls a promise that no earlier verse contains:"),
            .ayah("8:7", words: 0...6),
            .text("On the day of the battle the Prophet begged his Lord to fulfil what He had promised him (Sahih Muslim 1763)."),
            .markdown("**The palm trees of Banu an-Nadir.** The Prophet ordered them cut and burned (Sahih al-Bukhari 4031), though no verse had permitted it, and Allah then revealed:"),
            .ayah("59:5", words: 0...10),
            .markdown("**The nights of Ramadan.** Allah revealed:"),
            .ayah("2:187", words: 0...22),
            .text("Made lawful means it had been unlawful, and Allah says He accepted their repentance for deceiving themselves over it, so the rule was His. Yet no verse states it; al-Bara’ ibn ‘Azib (may Allah be pleased with him) describes how the Companions kept it (Sahih al-Bukhari 1915, 4508)."),
            .text("Each time the Quran calls the instruction Allah’s own: His appointment, His informing, His promise, His permission, His prohibition. The Prophet does not speak from desire; it is revelation revealed to him (Quran 53:3-4)."),
        ]),
        ArticleSection("THE QURAN CANNOT BE PRACTISED ALONE", [
            .text("Allah (Glorified and Exalted be He) commands the prayer throughout the Quran but names its times only in broad strokes (Quran 11:114, 17:78, 2:238), and never says how many prayers there are, how many rak‘ahs, or what is said in them. The Prophet (peace and blessings be upon him) said:"),
            .hadith("abudawud:393", cite: "Sunan Abi Dawud 393; graded hasan sahih by al-Albani", arabic: 52...98, english: [6...105]),
            .text("The next day Jibril (peace be upon him) prayed them later, and said the time lies between the two. The times were taught by example, not by recitation."),
            .text("The Companions knew it. Told that the Quran mentions the prayer of the resident and the prayer of fear but not the prayer of the traveller, ‘Abdullah ibn ‘Umar (may Allah be pleased with him) replied:"),
            .hadith("ibnmajah:1066", cite: "Sunan Ibn Majah 1066; graded sahih by al-Albani", arabic: 49...74, english: [37...57]),
            .checklist([
                "**How many prayers** a day, and when each one begins and ends (Sunan Abi Dawud 393).",
                "**How many rak‘ahs** each has, which are recited aloud, and what is said in bowing and prostration.",
                "**Which is the middle prayer** of Quran 2:238: ‘Asr (Sahih Muslim 628).",
                "**Shortening in safe travel**, though Quran 4:101 mentions fear: a charity from Allah (Sahih Muslim 686).",
                "**Zakah:** on what wealth, at what rate, above what minimum (Sahih al-Bukhari 1405, 1454).",
                "**Hajj:** its circuits, the standing at ‘Arafah and the stoning, in order (Sahih Muslim 1218).",
                "**The thief’s hand** (Quran 5:38): for stealing what minimum value (Sahih al-Bukhari 6789).",
                "**The words of the adhan**, though the Quran mentions the call to prayer (Quran 62:9).",
            ], title: "What the Quran Alone Cannot Tell You", icon: "questionmark.circle.fill"),
            .text("So those who take the Quran alone have never agreed on the prayer: five for Chakralawi, two for his contemporary, three for some Quranist writers today, a social order for Parwez. Rashad Khalifa’s followers pray five, saying the form was preserved from Ibrahim (peace be upon him) because Muslims all over the world perform the same steps. That is the Sunnah under another name."),
            .versus(ArticleVersus.Side("The Quran alone", caption: "Prayer commanded at times named in general terms; readers who refuse the Sunnah have counted **two, three or five** prayers."), ArticleVersus.Side("The Quran with the Sunnah", caption: "**Five** prayers at times Jibril demonstrated, **seventeen** obligatory rak‘ahs a day, one form prayed from Morocco to Indonesia."), quranic: false),
            .text("Ibn Hazm (may Allah have mercy on him) drew the conclusion:"),
            .quote(text: "“Were a man to say, ‘We take only what we find in the Quran’, he would be a disbeliever by the consensus of the Ummah, and he would owe no more than one rak‘ah between the decline of the sun and the darkness of night, and another at dawn, since that is the least that can be called a prayer, with no limit set on anything more.” (Ibn Hazm, al-Ihkam fi Usul al-Ahkam)", arabic: "ولو أن امرأ قال: لا نأخذ إلا ما وجدنا في القرآن لكان كافراً بإجماع الأمة، ولكان لا يلزمه إلا ركعة ما بين دلوك الشمس إلى غسق الليل، وأخرى عند الفجر، لأن ذلك هو أقل ما يقع عليه اسم صلاة، ولا حد للأكثر في ذلك", dimmed: true),
        ]),
        ArticleSection("THE SAME CHAINS CARRIED THE QURAN", [
            .text("A Quranist knows that his mushaf came through Muhammad (peace and blessings be upon him), which verses belong to it, their order and their pronunciation, only because Muslims passed it on from teacher to student. The reading most of the world recites has a chain like any hadith:"),
            .chain([
                ArticleChainLink("Hafs ibn Sulayman", "d. 180 AH, Kufa, whose narration most Muslims recite"),
                ArticleChainLink("‘Asim ibn Abi an-Najud", "d. 127 AH, the imam of recitation in Kufa"),
                ArticleChainLink("Abu ‘Abd ar-Rahman as-Sulami", "taught the Quran in Kufa from the rule of ‘Uthman to al-Hajjaj"),
                ArticleChainLink("‘Uthman, ‘Ali, Ibn Mas‘ud, Ubayy and Zayd", "Companions who read to the Prophet"),
                ArticleChainLink("The Prophet ﷺ", ""),
            ], caption: "The chain of the reading of Hafs from ‘Asim"),
            .text("Its third link, Abu ‘Abd ar-Rahman as-Sulami, also narrates in Sahih al-Bukhari from ‘Uthman (may Allah be pleased with him) that the best of the Muslims are those who learn the Quran and teach it (Sahih al-Bukhari 5027). The Quranist recites on his authority and rejects his hadith. Whether al-Fatihah reads Maliki or Maaliki yawm ad-din, both of them Quran, is known only by chains, which Ibn al-Jazari gathered in an-Nashr."),
            .text("Where that trust is thrown away, the text gives way too: Rashad Khalifa removed two verses that every mushaf and all ten readings contain. And five prayers prayed in public every day since the Prophet’s own mosque are a transmission wider than any single report. Whoever accepts the Quran because multitudes handed it down cannot reject the prayer they handed down the same way."),
            .callout("Everything a Quranist knows about the Quran reached him through the same Muslims, and often the same men, who carried the Sunnah. A method that throws out their reports cannot keep their Quran: **rejecting reliable transmission saws off the branch the Quranist sits on.**", title: "The Branch They Sit On", icon: "exclamationmark.triangle.fill"),
            .door(.article("QiraatView")),
        ]),
        ArticleSection("WHAT THE COMPANIONS AND THE SALAF SAID", [
            .text("The Companions answered the argument from the Quran. A woman who had read it all told ‘Abdullah ibn Mas‘ud (may Allah be pleased with him) that she had not found in it the curse he reported from the Prophet (peace and blessings be upon him). He said that had she read it, she would have found it, and recited (Sahih al-Bukhari 4886):"),
            .ayah("59:7", words: 23...36),
            .text("Mutarrif ibn ‘Abdullah ibn ash-Shikhkhir, a Successor of Basra, heard a man say, “Narrate to us only the Quran,” and replied:"),
            .quote(text: "“By Allah, we want no substitute for the Quran. But we want the one who knew the Quran better than we do.” (Mutarrif ibn ‘Abdullah, reported by Ibn ‘Abd al-Barr in Jami‘ Bayan al-‘Ilm wa Fadlih)", arabic: "والله ما نريد بالقرآن بدلا ولكن نريد من هو أعلم بالقرآن منا", dimmed: true),
            .text("Ayyub as-Sakhtiyani, also of Basra, gave a sign by which to recognise the error:"),
            .quote(text: "“When you tell a man of a Sunnah and he says, ‘Leave us of this, and tell us about the Quran’, know that he is astray.” (Ayyub as-Sakhtiyani, reported by al-Bayhaqi and quoted by as-Suyuti in Miftah al-Jannah)", arabic: "إذا حدثت الرجل بسنة فقال دعنا من هذا وأنبئنا عن القرآن فاعلم أنه ضال", dimmed: true),
            .text("The scholars judged the doctrine severely. As-Suyuti (may Allah have mercy on him) wrote Miftah al-Jannah against a man of his time who denied that the Sunnah is a proof, and opened it with the ruling that whoever denies that the Prophet’s hadith, in word or deed and with its known conditions, is a proof has left Islam; Ibn Hazm, above, reported consensus. That is a verdict on the doctrine. Judging a particular person belongs to the scholars, once the evidence has reached him and his doubts are answered, as ash-Shafi‘i argued with his opponent until he returned."),
            .door(.article("KufrView")),
        ]),
        ArticleSection("OBJECTIONS AND ANSWERS", [
            .markdown("**“The hadith were written down two hundred years later.”**"),
            .text("The figure confuses the date of the famous collections with the date of the first writing. ‘Abdullah ibn ‘Amr (may Allah be pleased with him) wrote down what he heard from the Prophet (peace and blessings be upon him), with his permission (Sunan Abi Dawud 3646; Sahih al-Bukhari 113); the Prophet had a sermon written out for a man from Yemen (Sahih al-Bukhari 2434); and Abu Bakr (may Allah be pleased with him) gave Anas (may Allah be pleased with him) a written zakah schedule when he sent him to Bahrain:"),
            .hadith("bukhari:1454", cite: "Sahih al-Bukhari 1454", arabic: 44...61, english: [26...52]),
            .text("‘Umar ibn ‘Abd al-‘Aziz (caliph 99–101 AH) ordered the hadith written down lest knowledge vanish with the scholars, as al-Bukhari records, and Malik (d. 179 AH) compiled the Muwatta’ before al-Bukhari was born. Al-Bukhari (d. 256 AH) selected from written collections his teachers had received with their chains."),
            .door(.article("HadithPreservationView")),
            .markdown("**“Nothing was left out of the Book (Quran 6:38).”**"),
            .ayah("6:38", words: 12...17),
            .text("The verse is about creatures: beasts and birds are communities, and to their Lord they are gathered. Ibn Kathir explains the Book here as the record Allah (Glorified and Exalted be He) keeps of every creature, and Ibn Taymiyyah and Ibn al-Qayyim held it to be the Preserved Tablet, al-Lawh al-Mahfuz, as the context shows; the translation above calls it “the Register”. Those who read it as the Quran said the Quran omits nothing because it commands us to take what the Messenger gives, as Ibn Mas‘ud answered the woman, and the same answers the verse calling the Quran a clarification of all things (Quran 16:89)."),
            .markdown("**“In what hadith after this will they believe?” (Quran 45:6, 77:50)**"),
            .ayah("45:6", words: 6...11),
            .text("Hadith means speech or report: the Quran calls itself the best hadith (Quran 39:23), and calls the words the Prophet confided to his wife a hadith (Quran 66:3). These verses address those who reject the Quran: if they will not believe Allah’s verses, what speech will they believe? They say nothing against the Prophet’s explanation of those verses, which the Quran itself commands us to take. Likewise the Book is fully detailed (Quran 6:114), and part of its detail is that the Messenger explains and judges (Quran 16:44, 4:105); no reader has found in it the rak‘ahs of the noon prayer."),
            .markdown("**“The Prophet forbade writing hadith.”**"),
            .hadith("muslim:3004", cite: "Sahih Muslim 3004", arabic: 29...41, english: [0...32]),
            .text("The objection uses a hadith of Sahih Muslim to prove that hadith cannot be trusted, and the same sentence tells the Companions to narrate from him. Al-Bukhari and others judged these to be the words of Abu Sa‘id al-Khudri (may Allah be pleased with him) himself, as Ibn Hajar reports in Fath al-Bari. If they are the Prophet’s, they were an early caution against mixing his words with the Quran on the scraps it was written on; later he had his sermon written for Abu Shah (may Allah be pleased with him) and told ‘Abdullah ibn ‘Amr to write (Sahih al-Bukhari 2434, Sunan Abi Dawud 3646). Restricting writing never meant restricting transmission."),
            .markdown("**“The hadith contradict each other and the Quran.”**"),
            .text("Reports that seem to conflict are the subject of an old science, mukhtalif al-hadith, on which ash-Shafi‘i and Ibn Qutaybah wrote books. Ibn as-Salah gives its method: reconcile the two where possible; if one came later, it abrogates the other; otherwise prefer the stronger. Ibn Khuzaymah said he knew of no two sound hadith that truly contradicted each other, and asked anyone who had such a pair to bring it so that he could reconcile them. Nor does a hadith that adds a ruling contradict the Quran, Ibn Hazm noted, or a hand would be cut for stealing the smallest amount, since the verse on theft is general (Quran 5:38). The Quran’s critics allege contradictions in the Quran too, and Ibn Qutaybah answered them by the same method: a rule that discards the Sunnah for apparent tension would discard the Quran."),
            .callout("Some say every hadith must be tested against the Quran, citing a report that the Prophet ordered it. ‘Abd ar-Rahman ibn Mahdi said heretics and Kharijites invented that report. Ibn ‘Abd al-Barr and Ibn Hazm then weighed it on its own scale: tested against the Quran, it fails, for the Quran nowhere says to accept only what matches it, and everywhere commands obedience to the Messenger.", title: "Weighed on Its Own Scale", icon: "scalemass.fill"),
            .markdown("**“Al-Bukhari was only a man.”**"),
            .text("He was, and no Muslim claims otherwise. His book is trusted because its method can be checked: every narration stands on a named chain, and the narrators’ records are public. Ad-Daraqutni criticised some of its narrations and Ibn Hajar answered him point by point, which is a science at work, not blind trust; and many of its hadith appear through other chains in Malik, Ahmad, Muslim and others. The Quranist trusts men too: Chakralawi built his Quranic prayer with Lisan al-‘Arab, a dictionary compiled more than four centuries after al-Bukhari."),
            .door(.article("HadithSciencesView")),
        ]),
        ArticleSection("AN INVITATION", [
            .text("To a Muslim drawn to this view by love of the Quran: that love is right, and it is what answers the view. The Quran asks you to follow the one it was revealed to. Ask the people of knowledge, as Allah (Glorified and Exalted be He) commands (Quran 16:43), and learn how the scholars of hadith sifted the sound from the weak. Those who took the Quran alone never agreed on how to pray; those who took it with the Sunnah have prayed the same five prayers for fourteen centuries."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran commands obedience to the Messenger (peace and blessings be upon him) in its own right, calls his teaching the Wisdom, and shows him receiving revelation that it does not recite. Its prayer, zakah and Hajj cannot be performed from its pages alone, and its text reached us through the same chains the Quranists reject. Holding to the Quran means holding to the one who brought it."),
            .door(.article("QuranSunnahView")),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Sunnah", arabic: "سُنَّة", meaning: "From **س-ن-ن**, to lay down a course: a well-trodden way. The sayings, actions and approvals of the Prophet (peace and blessings be upon him), revelation that explains the Quran."),
            .term("Hadith", arabic: "حَدِيث", meaning: "From **ح-د-ث**, to happen or be new, hence news and speech: a report of the Prophet’s words, deeds or approval. The Quran also calls itself hadith (Quran 39:23)."),
            .term("Hikmah", arabic: "حِكمَة", meaning: "From **ح-ك-م**, to judge and restrain: the Wisdom the Messenger teaches beside the Book (Quran 62:2), which the scholars ash-Shafi‘i trusted explained as the Sunnah."),
            .term("Wahy", arabic: "وَحي", meaning: "From **و-ح-ي**, a swift and hidden communication: revelation, which Ibn Hazm divided into the recited, the Quran, and the transmitted but not recited, the Sunnah."),
            .term("Bayan", arabic: "بَيَان", meaning: "From **ب-ي-ن**, to be distinct: making plain, the Prophet’s task toward what was sent down (Quran 16:44)."),
            .term("Ta‘ah", arabic: "طَاعَة", meaning: "From **ط-و-ع**, to comply willingly: obedience, commanded toward the Messenger with a verb of its own (Quran 4:59)."),
            .term("Ittiba‘", arabic: "اتِّبَاع", meaning: "From **ت-ب-ع**, to walk behind: following another’s way, which the Quran makes the proof of loving Allah (Glorified and Exalted be He) (Quran 3:31)."),
            .term("Quraniyyun", arabic: "قُرآنِيُّون", meaning: "The modern name for those who take the Quran alone as the source of religion and set the Sunnah aside; many call themselves Ahl al-Quran."),
            .term("Mukhtalif al-hadith", arabic: "مُختَلِف الحَدِيث", meaning: "From **خ-ل-ف**, to differ: the science of reports that seem to conflict, resolved by reconciling them, by finding the later one, or by preferring the stronger."),
        ]),
    ]
}
